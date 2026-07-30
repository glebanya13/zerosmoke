import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma } from '../../generated/prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { CreateAdminTestDto } from './dto/create-admin-test.dto';
import { UpdateAdminTestDto } from './dto/update-admin-test.dto';
import { UpdateAdminGuideDto } from './dto/update-admin-guide.dto';
import {
  CreateAdminQuestionDto,
  UpdateAdminQuestionDto,
} from './dto/admin-question.dto';

@Injectable()
export class AdminService {
  constructor(private readonly prisma: PrismaService) {}

  async dashboard() {
    const [
      users,
      links,
      usersByRole,
      subscriptionsByStatus,
      attempts,
      completedAttempts,
      avgScore,
      signupsLast7Days,
    ] = await Promise.all([
      this.prisma.user.count(),
      this.prisma.parentChildLink.count({ where: { status: 'ACTIVE' } }),
      this.prisma.user.groupBy({ by: ['role'], _count: { _all: true } }),
      this.prisma.subscription.groupBy({
        by: ['status'],
        _count: { _all: true },
      }),
      this.prisma.testAttempt.count(),
      this.prisma.testAttempt.count({
        where: { completedAt: { not: null } },
      }),
      this.prisma.testAttempt.aggregate({
        where: { completedAt: { not: null } },
        _avg: { correctCount: true, totalCount: true },
      }),
      this.prisma.user.count({
        where: {
          createdAt: { gte: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000) },
        },
      }),
    ]);
    const activeSubscriptions =
      subscriptionsByStatus.find((row) => row.status === 'ACTIVE')?._count
        ._all ?? 0;
    const averageScore =
      avgScore._avg.correctCount != null && avgScore._avg.totalCount
        ? Math.round(
            (avgScore._avg.correctCount / avgScore._avg.totalCount) * 100,
          )
        : null;
    return {
      users,
      activeLinks: links,
      usersByRole,
      signupsLast7Days,
      subscriptions: {
        active: activeSubscriptions,
        byStatus: subscriptionsByStatus,
      },
      testAttempts: {
        total: attempts,
        completed: completedAttempts,
        averageScorePercent: averageScore,
      },
    };
  }

  users(search?: string, role?: 'PARENT' | 'CHILD' | 'ADULT') {
    return this.prisma.user.findMany({
      where: {
        ...(role ? { role } : {}),
        ...(search
          ? {
              OR: [
                { name: { contains: search, mode: 'insensitive' } },
                { email: { contains: search, mode: 'insensitive' } },
              ],
            }
          : {}),
      },
      include: {
        ownedLinks: { include: { counterpart: { select: { name: true } } } },
        joinedLinks: { include: { owner: { select: { name: true } } } },
      },
      orderBy: { createdAt: 'desc' },
      take: 100,
    });
  }

  links() {
    return this.prisma.parentChildLink.findMany({
      include: {
        owner: {
          select: { id: true, name: true, email: true, avatarIndex: true },
        },
        counterpart: {
          select: { id: true, name: true, email: true, avatarIndex: true },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async tests() {
    const tests = await this.prisma.test.findMany({
      include: { _count: { select: { questions: true } } },
      orderBy: [{ audience: 'asc' }, { position: 'asc' }],
    });
    return tests.map(({ _count, ...test }) => ({
      ...test,
      questionCount: _count.questions,
    }));
  }

  async test(id: string) {
    const test = await this.prisma.test.findUniqueOrThrow({
      where: { id },
      include: {
        questions: {
          include: {
            section: { select: { id: true, title: true, position: true } },
          },
          orderBy: { position: 'asc' },
        },
      },
    });
    return { ...test, questionCount: test.questions.length };
  }

  async contentSummary() {
    const [sections, tests, guideCount] = await Promise.all([
      this.prisma.contentSection.findMany({
        select: { audience: true, _count: { select: { questions: true } } },
      }),
      this.prisma.test.findMany({
        select: {
          audience: true,
          isPublished: true,
          _count: { select: { questions: true } },
        },
      }),
      this.prisma.guide.count(),
    ]);
    const audiences = ['AGE_6', 'AGE_16', 'AGE_18'] as const;
    return {
      byAudience: audiences.map((audience) => ({
        audience,
        sections: sections.filter((row) => row.audience === audience).length,
        sectionQuestions: sections
          .filter((row) => row.audience === audience)
          .reduce((sum, row) => sum + row._count.questions, 0),
        tests: tests.filter((row) => row.audience === audience).length,
        testQuestions: tests
          .filter((row) => row.audience === audience)
          .reduce((sum, row) => sum + row._count.questions, 0),
        publishedTests: tests.filter(
          (row) => row.audience === audience && row.isPublished,
        ).length,
      })),
      guideCount,
    };
  }

  sections() {
    return this.prisma.contentSection.findMany({
      include: { _count: { select: { questions: true } } },
      orderBy: [{ audience: 'asc' }, { position: 'asc' }],
    });
  }

  guides() {
    return this.prisma.guide.findMany({
      select: {
        id: true,
        slug: true,
        title: true,
        sourceFile: true,
        pageCount: true,
        updatedAt: true,
      },
      orderBy: { title: 'asc' },
    });
  }

  guide(slug: string) {
    return this.prisma.guide.findUniqueOrThrow({ where: { slug } });
  }

  async updateGuide(slug: string, dto: UpdateAdminGuideDto) {
    const current = await this.prisma.guide.findUniqueOrThrow({
      where: { slug },
    });
    const content: Prisma.InputJsonValue = dto.content
      ? (JSON.parse(
          JSON.stringify({
            ...dto.content,
            sections: [...dto.content.sections].sort(
              (a, b) => a.position - b.position,
            ),
          }),
        ) as Prisma.InputJsonValue)
      : (current.content as Prisma.InputJsonValue);
    return this.prisma.guide.update({
      where: { slug },
      data: {
        title: dto.title ?? current.title,
        content,
      },
    });
  }

  async createTest(dto: CreateAdminTestDto) {
    const last = await this.prisma.test.aggregate({
      where: { audience: dto.audience },
      _max: { position: true },
    });
    return this.prisma.test.create({
      data: { ...dto, position: (last._max.position ?? 0) + 1 },
    });
  }

  updateTest(id: string, dto: UpdateAdminTestDto) {
    return this.prisma.test.update({ where: { id }, data: dto });
  }

  deleteTest(id: string) {
    return this.prisma.test.delete({ where: { id } });
  }

  async createQuestion(testId: string, dto: CreateAdminQuestionDto) {
    this.validateQuestion(dto.options, dto.correctOption);
    const test = await this.prisma.test.findUnique({ where: { id: testId } });
    if (!test) throw new NotFoundException('Test not found');
    const last = await this.prisma.testQuestion.aggregate({
      where: { testId },
      _max: { position: true },
    });
    return this.prisma.$transaction(async (tx) => {
      const question = await tx.testQuestion.create({
        data: {
          testId,
          position: (last._max.position ?? 0) + 1,
          material: dto.material || null,
          text: dto.text,
          options: dto.options,
          correctOption: dto.correctOption,
        },
      });
      await tx.test.update({
        where: { id: testId },
        data: { questionCount: { increment: 1 } },
      });
      return question;
    });
  }

  async updateQuestion(
    testId: string,
    questionId: string,
    dto: UpdateAdminQuestionDto,
  ) {
    const current = await this.prisma.testQuestion.findFirst({
      where: { id: questionId, testId },
    });
    if (!current) throw new NotFoundException('Question not found');
    const options = (dto.options ?? current.options) as string[];
    const correctOption = dto.correctOption ?? current.correctOption;
    this.validateQuestion(options, correctOption);
    return this.prisma.testQuestion.update({
      where: { id: questionId },
      data: {
        ...dto,
        material: dto.material === undefined ? undefined : dto.material || null,
      },
    });
  }

  async deleteQuestion(testId: string, questionId: string) {
    const question = await this.prisma.testQuestion.findFirst({
      where: { id: questionId, testId },
    });
    if (!question) throw new NotFoundException('Question not found');
    return this.prisma.$transaction(async (tx) => {
      await tx.testQuestion.delete({ where: { id: questionId } });
      const remaining = await tx.testQuestion.findMany({
        where: { testId },
        orderBy: { position: 'asc' },
        select: { id: true },
      });
      for (const [index, row] of remaining.entries()) {
        await tx.testQuestion.update({
          where: { id: row.id },
          data: { position: -(index + 1) },
        });
      }
      for (const [index, row] of remaining.entries()) {
        await tx.testQuestion.update({
          where: { id: row.id },
          data: { position: index + 1 },
        });
      }
      await tx.test.update({
        where: { id: testId },
        data: { questionCount: remaining.length },
      });
      return { deleted: true };
    });
  }

  async moveQuestion(
    testId: string,
    questionId: string,
    direction: 'UP' | 'DOWN',
  ) {
    const current = await this.prisma.testQuestion.findFirst({
      where: { id: questionId, testId },
    });
    if (!current) throw new NotFoundException('Question not found');
    const neighbor = await this.prisma.testQuestion.findFirst({
      where: {
        testId,
        position:
          direction === 'UP'
            ? { lt: current.position }
            : { gt: current.position },
      },
      orderBy: { position: direction === 'UP' ? 'desc' : 'asc' },
    });
    if (!neighbor) return current;
    await this.prisma.$transaction([
      this.prisma.testQuestion.update({
        where: { id: current.id },
        data: { position: -1 },
      }),
      this.prisma.testQuestion.update({
        where: { id: neighbor.id },
        data: { position: current.position },
      }),
      this.prisma.testQuestion.update({
        where: { id: current.id },
        data: { position: neighbor.position },
      }),
    ]);
    return { moved: true };
  }

  private validateQuestion(options: string[], correctOption: number) {
    if (options.some((option) => !option.trim())) {
      throw new BadRequestException('Question options cannot be empty');
    }
    if (correctOption > options.length) {
      throw new BadRequestException('Correct option is outside options list');
    }
  }
}
