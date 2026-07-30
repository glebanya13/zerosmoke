import { ContentService } from './content.service';
import type { PrismaService } from '../prisma/prisma.service';
import type { NotificationsService } from '../notifications/notifications.service';

/**
 * Regression test for the correctOption indexing bug: correctOption is
 * stored 1-indexed (admin DTO enforces @Min(1)), but the client submits
 * a 0-indexed selectedOption. answer() must bridge the two correctly.
 */
describe('ContentService.answer', () => {
  const attemptId = 'attempt-1';
  const userId = 'user-1';
  const testId = 'test-1';

  function buildService(question: { id: string; correctOption: number }) {
    const prisma = {
      testAttempt: {
        findUnique: jest.fn().mockResolvedValue({
          id: attemptId,
          userId,
          testId,
          completedAt: null,
          answers: {},
        }),
        update: jest.fn().mockImplementation(({ data }) => Promise.resolve({ id: attemptId, ...data })),
      },
      testQuestion: {
        findFirst: jest.fn().mockResolvedValue(question),
        findMany: jest.fn().mockResolvedValue([question]),
      },
    } as unknown as PrismaService;
    const notifications = {} as NotificationsService;
    return new ContentService(prisma, notifications);
  }

  it('marks the first option correct when correctOption is 1 (first option, 1-indexed)', async () => {
    const service = buildService({ id: 'q-1', correctOption: 1 });
    const result = await service.answer(attemptId, userId, {
      questionId: 'q-1',
      selectedOption: 0,
    });

    expect(result.isCorrect).toBe(true);
    expect(result.correctOption).toBe(0);
  });

  it('marks a later option correct when correctOption points past the first (1-indexed)', async () => {
    const service = buildService({ id: 'q-2', correctOption: 2 });
    const result = await service.answer(attemptId, userId, {
      questionId: 'q-2',
      selectedOption: 0,
    });

    expect(result.isCorrect).toBe(false);
    expect(result.correctOption).toBe(1);

    const serviceAgain = buildService({ id: 'q-2', correctOption: 2 });
    const correctPick = await serviceAgain.answer(attemptId, userId, {
      questionId: 'q-2',
      selectedOption: 1,
    });
    expect(correctPick.isCorrect).toBe(true);
  });
});
