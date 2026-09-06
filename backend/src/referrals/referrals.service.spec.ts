import { BadRequestException, NotFoundException } from '@nestjs/common';
import { ReferralsService, REFERRAL_REWARD_COINS } from './referrals.service';
import type { PrismaService } from '../prisma/prisma.service';

describe('ReferralsService.applyCode', () => {
  const userId = 'user-1';
  const referrerId = 'user-2';

  function buildService(overrides: {
    referral?: unknown;
    referrer?: { id: string; name: string } | null;
  }) {
    const prisma = {
      referral: {
        findUnique: jest.fn().mockResolvedValue(overrides.referral ?? null),
        create: jest.fn(),
      },
      user: {
        findUnique: jest.fn().mockResolvedValue(overrides.referrer ?? null),
      },
      userWallet: {
        upsert: jest.fn(),
      },
      $transaction: jest.fn().mockResolvedValue([]),
    } as unknown as PrismaService;
    return new ReferralsService(prisma);
  }

  it('rejects a code that does not exist', async () => {
    const service = buildService({ referrer: null });
    await expect(service.applyCode(userId, 'BADCODE1')).rejects.toBeInstanceOf(NotFoundException);
  });

  it('rejects using your own code', async () => {
    const service = buildService({ referrer: { id: userId, name: 'Me' } });
    await expect(service.applyCode(userId, 'MYCODE12')).rejects.toBeInstanceOf(
      BadRequestException,
    );
  });

  it('rejects applying a second code', async () => {
    const service = buildService({
      referral: { id: 'existing' },
      referrer: { id: referrerId, name: 'Friend' },
    });
    await expect(service.applyCode(userId, 'CODE1234')).rejects.toBeInstanceOf(
      BadRequestException,
    );
  });

  it('rewards both sides with REFERRAL_REWARD_COINS on a valid code', async () => {
    const service = buildService({ referrer: { id: referrerId, name: 'Friend' } });
    const result = await service.applyCode(userId, 'code1234');
    expect(result).toEqual({ rewardCoins: REFERRAL_REWARD_COINS, referrerName: 'Friend' });
  });
});
