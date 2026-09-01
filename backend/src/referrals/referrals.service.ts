import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { randomInt } from 'node:crypto';
import { PrismaService } from '../prisma/prisma.service';

/** Coins granted to both the referrer and the referee when a code is applied. */
export const REFERRAL_REWARD_COINS = 20;

const REFERRAL_CODE_ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

@Injectable()
export class ReferralsService {
  constructor(private readonly prisma: PrismaService) {}

  generateReferralCode(): string {
    let code = '';
    for (let i = 0; i < 8; i++) {
      code += REFERRAL_CODE_ALPHABET[randomInt(0, REFERRAL_CODE_ALPHABET.length)];
    }
    return code;
  }

  async getMe(userId: string) {
    const user = await this.prisma.user.findUniqueOrThrow({
      where: { id: userId },
      select: {
        referralCode: true,
        referredBy: { select: { id: true } },
        _count: { select: { referralsMade: true } },
      },
    });

    return {
      code: user.referralCode,
      invitedCount: user._count.referralsMade,
      coinsEarned: user._count.referralsMade * REFERRAL_REWARD_COINS,
      hasUsedFriendCode: user.referredBy !== null,
    };
  }

  async applyCode(userId: string, rawCode: string) {
    const code = rawCode.trim().toUpperCase();

    const alreadyUsed = await this.prisma.referral.findUnique({
      where: { refereeId: userId },
    });
    if (alreadyUsed) {
      throw new BadRequestException('You have already used a friend invite code');
    }

    const referrer = await this.prisma.user.findUnique({ where: { referralCode: code } });
    if (!referrer) {
      throw new NotFoundException('Invalid invite code');
    }
    if (referrer.id === userId) {
      throw new BadRequestException('Cannot use your own invite code');
    }

    await this.prisma.$transaction([
      this.prisma.referral.create({
        data: { referrerId: referrer.id, refereeId: userId, rewardCoins: REFERRAL_REWARD_COINS },
      }),
      this.prisma.userWallet.upsert({
        where: { userId: referrer.id },
        create: { userId: referrer.id, coins: REFERRAL_REWARD_COINS },
        update: { coins: { increment: REFERRAL_REWARD_COINS } },
      }),
      this.prisma.userWallet.upsert({
        where: { userId },
        create: { userId, coins: REFERRAL_REWARD_COINS },
        update: { coins: { increment: REFERRAL_REWARD_COINS } },
      }),
    ]);

    return { rewardCoins: REFERRAL_REWARD_COINS, referrerName: referrer.name };
  }
}
