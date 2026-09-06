import 'dotenv/config';
import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from '../generated/prisma/client';

const ACHIEVEMENTS = [
  {
    code: 'first_test_completed',
    title: 'Чистые лёгкие',
    subtitle: 'За прохождение первого теста',
    thresholdType: 'FIRST_TEST_COMPLETED' as const,
    thresholdValue: 1,
    position: 1,
  },
  {
    code: 'streak_7_days',
    title: 'Постоянство',
    subtitle: 'Занимался 7 дней подряд',
    thresholdType: 'STREAK_DAYS' as const,
    thresholdValue: 7,
    position: 2,
  },
  {
    code: 'perfect_5_tests',
    title: 'Огонь знаний',
    subtitle: 'Прошёл 5 тестов без ошибок',
    thresholdType: 'PERFECT_TESTS_COUNT' as const,
    thresholdValue: 5,
    position: 3,
  },
  {
    code: 'correct_answers_50',
    title: 'Знаток',
    subtitle: '50 правильных ответов',
    thresholdType: 'CORRECT_ANSWERS_COUNT' as const,
    thresholdValue: 50,
    position: 4,
  },
  {
    code: 'distinct_sections_10',
    title: 'Исследователь',
    subtitle: 'Пройди 10 разных разделов',
    thresholdType: 'DISTINCT_SECTIONS_COMPLETED' as const,
    thresholdValue: 10,
    position: 5,
  },
  {
    code: 'correct_answers_100',
    title: 'Мастер знаний',
    subtitle: 'Ответь правильно на 100 вопросов',
    thresholdType: 'CORRECT_ANSWERS_COUNT' as const,
    thresholdValue: 100,
    position: 6,
  },
];

async function main() {
  const prisma = new PrismaClient({
    adapter: new PrismaPg({ connectionString: process.env.DATABASE_URL }),
  });
  try {
    for (const achievement of ACHIEVEMENTS) {
      await prisma.achievementDefinition.upsert({
        where: { code: achievement.code },
        create: achievement,
        update: achievement,
      });
    }
    console.log(`Seeded ${ACHIEVEMENTS.length} achievement definitions`);
  } finally {
    await prisma.$disconnect();
  }
}

void main();
