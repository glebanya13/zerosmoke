import 'dotenv/config';
import { readFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from '../generated/prisma/client';

type Audience = 'AGE_6' | 'AGE_16' | 'AGE_18';
type Question = {
  position: number;
  sectionPosition?: number;
  material: string | null;
  text: string;
  options: string[];
  correctOption: number;
};
type ContentPayload = {
  sections: Array<{
    audience: Audience;
    position: number;
    title: string;
    sourceFile: string;
    questions: Question[];
  }>;
  tests: Array<{
    audience: Audience;
    position: number;
    title: string;
    description: string;
    sourceFile: string;
    isPublished: boolean;
    questions: Question[];
  }>;
  guide: {
    slug: string;
    title: string;
    sourceFile: string;
    pageCount: number;
    content: unknown;
  };
};

async function main() {
  const input = resolve(process.argv[2] ?? 'data/antismoke-content.json');
  const payload = JSON.parse(await readFile(input, 'utf8')) as ContentPayload;
  const prisma = new PrismaClient({
    adapter: new PrismaPg({ connectionString: process.env.DATABASE_URL }),
  });

  try {
    await prisma.$transaction(
      async (tx) => {
        await tx.testQuestion.deleteMany();
        await tx.sectionQuestion.deleteMany();
        await tx.test.deleteMany();
        await tx.contentSection.deleteMany();
        await tx.guide.deleteMany();

        const sectionIds = new Map<string, string>();
        for (const section of payload.sections) {
          const created = await tx.contentSection.create({
            data: {
              title: section.title,
              audience: section.audience,
              position: section.position,
              sourceFile: section.sourceFile,
              isPublished: true,
              questions: {
                create: section.questions.map((question) => ({
                  position: question.position,
                  material: question.material,
                  text: question.text,
                  options: question.options,
                  correctOption: question.correctOption,
                })),
              },
            },
          });
          sectionIds.set(`${section.audience}:${section.position}`, created.id);
        }

        for (const test of payload.tests) {
          await tx.test.create({
            data: {
              title: test.title,
              description: test.description,
              audience: test.audience,
              position: test.position,
              sourceFile: test.sourceFile,
              questionCount: test.questions.length,
              isPublished: test.isPublished,
              questions: {
                create: test.questions.map((question) => ({
                  position: question.position,
                  sectionId: question.sectionPosition
                    ? sectionIds.get(
                        `${test.audience}:${question.sectionPosition}`,
                      )
                    : undefined,
                  material: question.material,
                  text: question.text,
                  options: question.options,
                  correctOption: question.correctOption,
                })),
              },
            },
          });
        }

        await tx.guide.create({ data: payload.guide as never });
      },
      { maxWait: 10_000, timeout: 120_000 },
    );

    const [sections, sectionQuestions, tests, testQuestions, guides] =
      await Promise.all([
        prisma.contentSection.count(),
        prisma.sectionQuestion.count(),
        prisma.test.count(),
        prisma.testQuestion.count(),
        prisma.guide.count(),
      ]);
    console.log({ sections, sectionQuestions, tests, testQuestions, guides });
  } finally {
    await prisma.$disconnect();
  }
}

void main();
