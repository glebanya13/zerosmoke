import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { audienceForAge } from '../common/audience.util';
import { AnswerQuestionDto } from './dto/answer-question.dto';
import { AssignTestDto } from './dto/assign-test.dto';
import { AssignmentStatus, LinkStatus } from '../../generated/prisma/enums';
import type { User } from '../../generated/prisma/client';
import { NotificationsService } from '../notifications/notifications.service';

@Injectable()
export class ContentService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly notifications: NotificationsService,
  ) {}

  async sections(age: number) {
    const audience = audienceForAge(age);
    return this.prisma.contentSection.findMany({
      where: { audience, isPublished: true },
      include: { _count: { select: { questions: true } } },
      orderBy: { position: 'asc' },
    });
  }

  async section(id: string, age: number) {
    const audience = audienceForAge(age);
    const section = await this.prisma.contentSection.findFirst({
      where: { id, audience, isPublished: true },
      include: { questions: { orderBy: { position: 'asc' } } },
    });
    if (!section) throw new NotFoundException('Section not found');
    // Strip correct answers from section quiz materials.
    return {
      ...section,
      questions: section.questions.map(({ correctOption: _, ...q }) => q),
    };
  }

  async tests(age: number, userId: string) {
    const audience = audienceForAge(age);
    const tests = await this.prisma.test.findMany({
      where: { audience, isPublished: true },
      include: { _count: { select: { questions: true } } },
      orderBy: { position: 'asc' },
    });
    const attempts = await this.prisma.testAttempt.findMany({
      where: { userId, testId: { in: tests.map((test) => test.id) } },
      orderBy: { createdAt: 'desc' },
    });
    const latestByTest = new Map<string, (typeof attempts)[number]>();
    for (const attempt of attempts) {
      if (!latestByTest.has(attempt.testId)) {
        latestByTest.set(attempt.testId, attempt);
      }
    }
    return tests.map(({ _count, ...test }) => {
      const attempt = latestByTest.get(test.id);
      return {
        ...test,
        questionCount: _count.questions,
        progress: {
          answeredCount: attempt?.answeredCount ?? 0,
          totalCount: attempt?.totalCount ?? _count.questions,
          completed: Boolean(attempt?.completedAt),
        },
      };
    });
  }

  /** Returns test with questions but WITHOUT correctOption (anti-cheat). */
  async test(id: string, age: number) {
    const audience = audienceForAge(age);
    const test = await this.prisma.test.findFirst({
      where: { id, audience, isPublished: true },
      include: { questions: { orderBy: { position: 'asc' } } },
    });
    if (!test) throw new NotFoundException('Test not found');
    return {
      ...test,
      questions: test.questions.map(({ correctOption: _, ...q }) => q),
    };
  }

  async guide() {
    const guide = await this.prisma.guide.findFirst({
      orderBy: { createdAt: 'asc' },
    });
    if (!guide) throw new NotFoundException('Guide not found');
    return guide;
  }

  async startAttempt(testId: string, userId: string, age: number) {
    const audience = audienceForAge(age);
    const test = await this.prisma.test.findFirst({
      where: { id: testId, audience, isPublished: true },
      include: { _count: { select: { questions: true } } },
    });
    if (!test) throw new NotFoundException('Test not found');
    const existing = await this.prisma.testAttempt.findFirst({
      where: { userId, testId, completedAt: null },
      orderBy: { createdAt: 'desc' },
    });
    if (existing) return existing;
    return this.prisma.testAttempt.create({
      data: {
        userId,
        testId,
        totalCount: test._count.questions,
      },
    });
  }

  async answer(attemptId: string, userId: string, dto: AnswerQuestionDto) {
    const attempt = await this.prisma.testAttempt.findUnique({
      where: { id: attemptId },
    });
    if (!attempt) throw new NotFoundException('Attempt not found');
    if (attempt.userId !== userId) throw new ForbiddenException();
    if (attempt.completedAt) {
      throw new BadRequestException('Attempt already completed');
    }
    const question = await this.prisma.testQuestion.findFirst({
      where: { id: dto.questionId, testId: attempt.testId },
    });
    if (!question) throw new NotFoundException('Question not found');

    const answers = {
      ...((attempt.answers as Record<string, number>) ?? {}),
      [dto.questionId]: dto.selectedOption,
    };
    const questions = await this.prisma.testQuestion.findMany({
      where: { testId: attempt.testId },
      select: { id: true, correctOption: true },
    });
    const answeredCount = Object.keys(answers).length;
    // correctOption is stored 1-indexed (admin DTO enforces @Min(1)); the
    // client submits/expects a 0-indexed option, hence the +1/-1 below.
    const correctCount = questions.filter(
      (q) => answers[q.id] + 1 === q.correctOption,
    ).length;

    const updated = await this.prisma.testAttempt.update({
      where: { id: attemptId },
      data: { answers, answeredCount, correctCount },
    });

    const isCorrect = dto.selectedOption + 1 === question.correctOption;

    return {
      attempt: updated,
      isCorrect,
      // Reveal correct option only after the answer is submitted.
      correctOption: question.correctOption - 1,
    };
  }

  async complete(attemptId: string, userId: string) {
    const attempt = await this.prisma.testAttempt.findUnique({
      where: { id: attemptId },
    });
    if (!attempt) throw new NotFoundException('Attempt not found');
    if (attempt.userId !== userId) throw new ForbiddenException();

    const wasAlreadyCompleted = Boolean(attempt.completedAt);
    const updated = await this.prisma.testAttempt.update({
      where: { id: attemptId },
      data: { completedAt: attempt.completedAt ?? new Date() },
    });

    let coinsEarned = 0;
    if (!wasAlreadyCompleted) {
      coinsEarned = updated.correctCount;
      await this.prisma.userWallet.upsert({
        where: { userId },
        create: { userId, coins: coinsEarned },
        update: { coins: { increment: coinsEarned } },
      });
      await this.prisma.testAssignment.updateMany({
        where: {
          assignedToId: userId,
          testId: attempt.testId,
          status: { in: [AssignmentStatus.PENDING, AssignmentStatus.SEEN] },
        },
        data: { status: AssignmentStatus.COMPLETED, completedAt: new Date() },
      });
      await this.syncAchievements(userId);
    }

    const wallet = await this.prisma.userWallet.findUnique({ where: { userId } });
    return { ...updated, coinsEarned, coinsTotal: wallet?.coins ?? 0 };
  }

  private async syncAchievements(userId: string) {
    const [definitions, attempts] = await Promise.all([
      this.prisma.achievementDefinition.findMany(),
      this.prisma.testAttempt.findMany({
        where: { userId, completedAt: { not: null } },
      }),
    ]);
    const totalCorrect = attempts.reduce((sum, a) => sum + a.correctCount, 0);
    const completedTestsCount = new Set(attempts.map((a) => a.testId)).size;
    const perfectTestsCount = attempts.filter(
      (a) => a.totalCount > 0 && a.correctCount === a.totalCount,
    ).length;
    const progressByType: Record<string, number> = {
      FIRST_TEST_COMPLETED: completedTestsCount > 0 ? 1 : 0,
      STREAK_DAYS: 1,
      PERFECT_TESTS_COUNT: perfectTestsCount,
      CORRECT_ANSWERS_COUNT: totalCorrect,
      DISTINCT_SECTIONS_COMPLETED: completedTestsCount,
    };
    for (const def of definitions) {
      const progress = progressByType[def.thresholdType] ?? 0;
      if (progress >= def.thresholdValue) {
        await this.prisma.userAchievement.upsert({
          where: {
            userId_achievementCode: {
              userId,
              achievementCode: def.code,
            },
          },
          create: { userId, achievementCode: def.code },
          update: {},
        });
      }
    }
  }

  async assignTest(user: User, dto: AssignTestDto) {
    if (user.role !== 'PARENT') {
      throw new ForbiddenException('Only parents can assign tests');
    }
    const link = await this.prisma.parentChildLink.findFirst({
      where: {
        ownerId: user.id,
        counterpartId: dto.assignedToId,
        status: LinkStatus.ACTIVE,
      },
    });
    if (!link) {
      throw new BadRequestException('Child is not linked to this parent');
    }
    const test = await this.prisma.test.findFirst({
      where: { id: dto.testId, isPublished: true },
    });
    if (!test) throw new NotFoundException('Test not found');

    const created = await this.prisma.testAssignment.create({
      data: {
        testId: dto.testId,
        assignedById: user.id,
        assignedToId: dto.assignedToId,
        message: dto.message,
      },
      include: {
        test: { select: { id: true, title: true, description: true, questionCount: true } },
        assignedTo: {
          select: { id: true, name: true, avatarIndex: true },
        },
      },
    });

    void this.notifications.notifyUser(dto.assignedToId, {
      title: 'Новый тест',
      body: dto.message?.trim() || `Вам назначен тест «${created.test.title}»`,
      type: 'tests',
    });

    return created;
  }

  async myAssignments(user: User) {
    if (user.role === 'PARENT') {
      return this.prisma.testAssignment.findMany({
        where: { assignedById: user.id },
        include: {
          test: { select: { id: true, title: true, description: true, questionCount: true } },
          assignedTo: { select: { id: true, name: true, avatarIndex: true } },
        },
        orderBy: { createdAt: 'desc' },
        take: 50,
      });
    }
    const rows = await this.prisma.testAssignment.findMany({
      where: {
        assignedToId: user.id,
        status: { in: [AssignmentStatus.PENDING, AssignmentStatus.SEEN] },
      },
      include: {
        test: { select: { id: true, title: true, description: true, questionCount: true } },
        assignedBy: { select: { id: true, name: true, avatarIndex: true } },
      },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });
    await this.prisma.testAssignment.updateMany({
      where: {
        assignedToId: user.id,
        status: AssignmentStatus.PENDING,
      },
      data: { status: AssignmentStatus.SEEN },
    });
    return rows;
  }
}
