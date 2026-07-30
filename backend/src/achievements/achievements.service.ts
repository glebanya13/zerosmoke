import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import type { User } from '../../generated/prisma/client';

@Injectable()
export class AchievementsService {
  constructor(private readonly prisma: PrismaService) {}

  private longestStreak(dates: Date[]): number {
    const days = Array.from(
      new Set(dates.map((d) => d.toISOString().slice(0, 10))),
    ).sort();
    let longest = days.length ? 1 : 0;
    let current = longest;
    for (let i = 1; i < days.length; i++) {
      const prev = new Date(days[i - 1]);
      const curr = new Date(days[i]);
      const diffDays = Math.round(
        (curr.getTime() - prev.getTime()) / 86_400_000,
      );
      current = diffDays === 1 ? current + 1 : 1;
      longest = Math.max(longest, current);
    }
    return longest;
  }

  async forUser(user: User) {
    const [definitions, attempts, unlocked] = await Promise.all([
      this.prisma.achievementDefinition.findMany({
        orderBy: { position: 'asc' },
      }),
      this.prisma.testAttempt.findMany({
        where: { userId: user.id, completedAt: { not: null } },
      }),
      this.prisma.userAchievement.findMany({ where: { userId: user.id } }),
    ]);

    const unlockedCodes = new Set(unlocked.map((u) => u.achievementCode));
    const totalCorrect = attempts.reduce((sum, a) => sum + a.correctCount, 0);
    const completedTestsCount = new Set(attempts.map((a) => a.testId)).size;
    const perfectTestsCount = attempts.filter(
      (a) => a.totalCount > 0 && a.correctCount === a.totalCount,
    ).length;
    const streakDays = this.longestStreak(
      attempts.map((a) => a.completedAt!).filter(Boolean),
    );

    let distinctSectionsCompleted = 0;
    if (attempts.length) {
      const questions = await this.prisma.testQuestion.findMany({
        where: {
          testId: { in: attempts.map((a) => a.testId) },
          sectionId: { not: null },
        },
        select: { sectionId: true },
      });
      distinctSectionsCompleted = new Set(
        questions.map((q) => q.sectionId),
      ).size;
    }

    const progressByType: Record<string, number> = {
      FIRST_TEST_COMPLETED: completedTestsCount > 0 ? 1 : 0,
      STREAK_DAYS: streakDays,
      PERFECT_TESTS_COUNT: perfectTestsCount,
      CORRECT_ANSWERS_COUNT: totalCorrect,
      DISTINCT_SECTIONS_COMPLETED: distinctSectionsCompleted,
    };

    return definitions.map((def) => {
      const progress = Math.min(
        progressByType[def.thresholdType] ?? 0,
        def.thresholdValue,
      );
      const met = progress >= def.thresholdValue;
      return {
        code: def.code,
        title: def.title,
        subtitle: def.subtitle,
        unlocked: met || unlockedCodes.has(def.code),
        progress,
        total: def.thresholdValue,
      };
    });
  }
}
