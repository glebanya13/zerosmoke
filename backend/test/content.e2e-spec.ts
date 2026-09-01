import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from '../src/app.module';
import { PrismaService } from '../src/prisma/prisma.service';

describe('Content + attempt lifecycle (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaService;
  let jwt: JwtService;
  let config: ConfigService;

  let userId: string;
  let accessToken: string;
  let sectionId: string;
  let publishedTestId: string;
  let unpublishedTestId: string;
  let otherAudienceTestId: string;
  let questionIds: string[];

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    app.useGlobalPipes(
      new ValidationPipe({ whitelist: true, transform: true }),
    );
    await app.init();

    prisma = app.get(PrismaService);
    jwt = app.get(JwtService);
    config = app.get(ConfigService);

    const user = await prisma.user.create({
      data: {
        email: `content-e2e-${Date.now()}@example.com`,
        role: 'CHILD',
        name: 'E2E Test',
        age: 10,
        isFemale: false,
        avatarIndex: 0,
        referralCode: `E2E${Date.now()}`,
      },
    });
    userId = user.id;
    accessToken = jwt.sign(
      { sub: user.id, email: user.email, role: user.role },
      {
        secret: config.getOrThrow<string>('JWT_ACCESS_SECRET'),
        expiresIn: '1h',
      },
    );

    const section = await prisma.contentSection.create({
      data: {
        title: 'E2E Section',
        audience: 'AGE_6',
        position: 100_001,
        sourceFile: 'e2e.docx',
        isPublished: true,
      },
    });
    sectionId = section.id;

    const publishedTest = await prisma.test.create({
      data: {
        title: 'E2E Published Test',
        audience: 'AGE_6',
        position: 100_001,
        isPublished: true,
      },
    });
    publishedTestId = publishedTest.id;

    const questions = await Promise.all(
      [0, 1].map((i) =>
        prisma.testQuestion.create({
          data: {
            testId: publishedTest.id,
            sectionId: section.id,
            position: i + 1,
            text: `Question ${i + 1}`,
            options: ['A', 'B'],
            correctOption: 0,
          },
        }),
      ),
    );
    questionIds = questions.map((q) => q.id);
    await prisma.test.update({
      where: { id: publishedTest.id },
      data: { questionCount: questions.length },
    });

    const unpublishedTest = await prisma.test.create({
      data: {
        title: 'E2E Unpublished Test',
        audience: 'AGE_6',
        position: 100_002,
        isPublished: false,
      },
    });
    unpublishedTestId = unpublishedTest.id;

    const otherAudienceTest = await prisma.test.create({
      data: {
        title: 'E2E Adult Test',
        audience: 'AGE_18',
        position: 100_001,
        isPublished: true,
      },
    });
    otherAudienceTestId = otherAudienceTest.id;
  });

  afterAll(async () => {
    await prisma.testAttempt.deleteMany({ where: { userId } });
    await prisma.testAssignment.deleteMany({
      where: { OR: [{ assignedToId: userId }, { assignedById: userId }] },
    });
    await prisma.userAchievement.deleteMany({ where: { userId } });
    await prisma.userWallet.deleteMany({ where: { userId } });
    await prisma.cravingLog.deleteMany({ where: { userId } });
    await prisma.quitProfile.deleteMany({ where: { userId } });
    await prisma.testQuestion.deleteMany({
      where: { testId: publishedTestId },
    });
    await prisma.test.deleteMany({
      where: { id: { in: [publishedTestId, unpublishedTestId, otherAudienceTestId] } },
    });
    await prisma.contentSection.delete({ where: { id: sectionId } });
    await prisma.refreshToken.deleteMany({ where: { userId } });
    await prisma.userSettings.deleteMany({ where: { userId } });
    await prisma.subscription.deleteMany({ where: { userId } });
    await prisma.user.delete({ where: { id: userId } });
    await app.close();
  });

  const auth = () => ({ Authorization: `Bearer ${accessToken}` });

  it('rejects unauthenticated requests', () => {
    return request(app.getHttpServer()).get('/content/tests').expect(401);
  });

  it('lists only published tests for the user audience', async () => {
    const res = await request(app.getHttpServer())
      .get('/content/tests')
      .set(auth())
      .expect(200);

    const ids = (res.body as Array<{ id: string }>).map((t) => t.id);
    expect(ids).toContain(publishedTestId);
    expect(ids).not.toContain(unpublishedTestId);
    expect(ids).not.toContain(otherAudienceTestId);
  });

  it('attaches the topic section to listed tests', async () => {
    const res = await request(app.getHttpServer())
      .get('/content/tests')
      .set(auth())
      .expect(200);

    const row = (
      res.body as Array<{ id: string; section: { id: string } | null }>
    ).find((test) => test.id === publishedTestId);
    expect(row?.section?.id).toBe(sectionId);
  });

  it('lets a parent list every age group and open a child test', async () => {
    const parent = await prisma.user.create({
      data: {
        email: `content-parent-e2e-${Date.now()}@example.com`,
        role: 'PARENT',
        name: 'E2E Parent',
        age: 40,
        isFemale: false,
        avatarIndex: 0,
        referralCode: `E2EP${Date.now()}`,
      },
    });
    const parentToken = jwt.sign(
      { sub: parent.id, email: parent.email, role: parent.role },
      {
        secret: config.getOrThrow<string>('JWT_ACCESS_SECRET'),
        expiresIn: '1h',
      },
    );
    const parentAuth = { Authorization: `Bearer ${parentToken}` };

    try {
      const res = await request(app.getHttpServer())
        .get('/content/tests')
        .set(parentAuth)
        .expect(200);
      const ids = (res.body as Array<{ id: string }>).map((t) => t.id);
      expect(ids).toContain(publishedTestId);
      expect(ids).toContain(otherAudienceTestId);
      expect(ids).not.toContain(unpublishedTestId);

      await request(app.getHttpServer())
        .get(`/content/tests/${publishedTestId}`)
        .set(parentAuth)
        .expect(200);
    } finally {
      await prisma.user.delete({ where: { id: parent.id } });
    }
  });

  it('lists only published sections for the user audience', async () => {
    const res = await request(app.getHttpServer())
      .get('/content/sections')
      .set(auth())
      .expect(200);

    const ids = (res.body as Array<{ id: string }>).map((s) => s.id);
    expect(ids).toContain(sectionId);
  });

  it('404s for a test outside the user audience', () => {
    return request(app.getHttpServer())
      .get(`/content/tests/${otherAudienceTestId}`)
      .set(auth())
      .expect(404);
  });

  it('runs the full attempt lifecycle and computes correctCount', async () => {
    const start = await request(app.getHttpServer())
      .post(`/content/tests/${publishedTestId}/attempt`)
      .set(auth())
      .expect(201);

    const attemptId = start.body.id as string;
    expect(start.body.totalCount).toBe(2);
    expect(start.body.completedAt).toBeNull();

    const resume = await request(app.getHttpServer())
      .post(`/content/tests/${publishedTestId}/attempt`)
      .set(auth())
      .expect(201);
    expect(resume.body.id).toBe(attemptId);

    await request(app.getHttpServer())
      .post(`/content/attempts/${attemptId}/answer`)
      .set(auth())
      .send({ questionId: questionIds[0], selectedOption: 0 })
      .expect(201);

    const secondAnswer = await request(app.getHttpServer())
      .post(`/content/attempts/${attemptId}/answer`)
      .set(auth())
      .send({ questionId: questionIds[1], selectedOption: 1 })
      .expect(201);

    expect(secondAnswer.body.attempt.answeredCount).toBe(2);
    expect(secondAnswer.body.attempt.correctCount).toBe(1);
    expect(secondAnswer.body.isCorrect).toBe(false);
    expect(secondAnswer.body.correctOption).toBe(0);

    const detail = await request(app.getHttpServer())
      .get(`/content/tests/${publishedTestId}`)
      .set(auth())
      .expect(200);
    for (const q of detail.body.questions as Array<Record<string, unknown>>) {
      expect(q.correctOption).toBeUndefined();
    }

    const completed = await request(app.getHttpServer())
      .post(`/content/attempts/${attemptId}/complete`)
      .set(auth())
      .expect(201);

    expect(completed.body.completedAt).not.toBeNull();
    expect(completed.body.correctCount).toBe(1);
    expect(completed.body.totalCount).toBe(2);
    expect(completed.body.coinsEarned).toBe(1);
  });
});
