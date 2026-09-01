import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { LinkStatus } from '../../generated/prisma/enums';
import type { User } from '../../generated/prisma/client';
import { audienceForAge } from '../common/audience.util';

@Injectable()
export class RatingService {
  constructor(private readonly prisma: PrismaService) {}

  private async householdMemberIds(user: User): Promise<string[]> {
    if (user.role === 'PARENT') {
      const links = await this.prisma.parentChildLink.findMany({
        where: { ownerId: user.id, status: LinkStatus.ACTIVE },
        select: { counterpartId: true },
      });
      return links
        .map((link) => link.counterpartId)
        .filter((id): id is string => Boolean(id));
    }
    const link = await this.prisma.parentChildLink.findFirst({
      where: { counterpartId: user.id, status: LinkStatus.ACTIVE },
    });
    if (!link) return [user.id];
    const siblings = await this.prisma.parentChildLink.findMany({
      where: { ownerId: link.ownerId, status: LinkStatus.ACTIVE },
      select: { counterpartId: true },
    });
    return siblings
      .map((row) => row.counterpartId)
      .filter((id): id is string => Boolean(id));
  }

  private async statsForUser(user: User) {
    const audience = audienceForAge(user.age);
    const [totalTests, attempts, wallet, rewardsCount] = await Promise.all([
      this.prisma.test.count({ where: { audience, isPublished: true } }),
      this.prisma.testAttempt.findMany({
        where: { userId: user.id, completedAt: { not: null } },
      }),
      this.prisma.userWallet.findUnique({ where: { userId: user.id } }),
      this.prisma.userAchievement.count({ where: { userId: user.id } }),
    ]);
    const points = attempts.reduce((sum, a) => sum + a.correctCount, 0);
    const total = attempts.reduce((sum, a) => sum + a.totalCount, 0);
    const completedTests = new Set(attempts.map((a) => a.testId)).size;
    const percent =
      totalTests === 0 ? 0 : Math.round((completedTests / totalTests) * 100);
    const stars = Math.min(5, Math.round(percent / 20));
    return {
      userId: user.id,
      name: user.name,
      avatarIndex: user.avatarIndex,
      percent,
      stars,
      points,
      total,
      coins: wallet?.coins ?? points,
      rewardsCount,
    };
  }

  async leaderboard(user: User) {
    const memberIds = await this.householdMemberIds(user);
    const ids = memberIds.length ? memberIds : [user.id];
    const users = await this.prisma.user.findMany({ where: { id: { in: ids } } });
    const stats = await Promise.all(users.map((u) => this.statsForUser(u)));
    stats.sort((a, b) => b.points - a.points);
    return stats.map((row, index) => ({ ...row, place: index + 1 }));
  }

  async me(user: User) {
    const audience = audienceForAge(user.age);
    const [stats, sections, attempts] = await Promise.all([
      this.statsForUser(user),
      this.prisma.contentSection.findMany({
        where: { audience, isPublished: true },
        include: {
          testQuestions: {
            where: { test: { isPublished: true } },
            orderBy: [{ test: { position: 'asc' } }, { position: 'asc' }],
            select: {
              id: true,
              text: true,
              correctOption: true,
              test: { select: { id: true, title: true } },
            },
          },
        },
        orderBy: { position: 'asc' },
      }),
      this.prisma.testAttempt.findMany({
        where: { userId: user.id, completedAt: { not: null } },
        orderBy: { createdAt: 'desc' },
      }),
    ]);
    const leaderboard = await this.leaderboard(user);
    const place = leaderboard.find((row) => row.userId === user.id)?.place ?? 1;

    // Latest completed attempt per test → questionId → selectedOption (0-indexed).
    const latestAnswersByQuestion = new Map<string, number>();
    const seenTests = new Set<string>();
    for (const attempt of attempts) {
      if (seenTests.has(attempt.testId)) continue;
      seenTests.add(attempt.testId);
      const answers = (attempt.answers as Record<string, number>) ?? {};
      for (const [questionId, selected] of Object.entries(answers)) {
        latestAnswersByQuestion.set(questionId, selected);
      }
    }

    return {
      ...stats,
      place,
      sections: sections.map((section) => {
        const questions = section.testQuestions.map((q) => {
          const selected = latestAnswersByQuestion.get(q.id);
          const answered = selected !== undefined;
          const correct =
            answered && selected + 1 === q.correctOption ? true : answered ? false : null;
          return {
            id: q.id,
            text: q.text,
            testId: q.test.id,
            testTitle: q.test.title,
            answered,
            correct,
          };
        });
        const progress = questions.filter((q) => q.correct === true).length;
        return {
          id: section.id,
          title: section.title,
          progress,
          total: questions.length,
          questions,
        };
      }),
    };
  }
}
