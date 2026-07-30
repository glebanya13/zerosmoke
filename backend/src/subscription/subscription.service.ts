import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma/prisma.service';
import {
  PLAN_DURATIONS_MS,
  SUBSCRIPTION_PLANS,
  SubscriptionPlan,
} from './subscription-plans';
import { hasActiveSubscription } from './subscription-access';
import { SubscriptionStatus } from '../../generated/prisma/enums';
import { ActivateSubscriptionDto } from './dto/activate-subscription.dto';

@Injectable()
export class SubscriptionService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
  ) {}

  plans(tier: 'child1' | 'child2' = 'child1'): SubscriptionPlan[] {
    return SUBSCRIPTION_PLANS[tier] ?? SUBSCRIPTION_PLANS.child1;
  }

  checkoutUrl(planId: string, userId: string): { url: string } {
    if (!PLAN_DURATIONS_MS[planId]) {
      throw new BadRequestException('Unknown planId');
    }
    const base =
      this.config.get<string>('SUBSCRIPTION_WEB_URL') ??
      'https://zerosmoke.ru/subscribe';
    const url = new URL(base);
    url.searchParams.set('planId', planId);
    url.searchParams.set('userId', userId);
    return { url: url.toString() };
  }

  async me(userId: string) {
    await hasActiveSubscription(this.prisma, userId);
    return this.prisma.subscription.findFirst({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async isActive(userId: string) {
    return hasActiveSubscription(this.prisma, userId);
  }

  /**
   * Called by the website payment backend after a successful checkout.
   * Protected by admin API key — never from the mobile client.
   */
  async activateFromWebsite(dto: ActivateSubscriptionDto) {
    const durationMs = PLAN_DURATIONS_MS[dto.planId];
    if (!durationMs) {
      throw new BadRequestException('Unknown planId');
    }
    const user = await this.prisma.user.findUnique({ where: { id: dto.userId } });
    if (!user) throw new NotFoundException('User not found');

    const now = new Date();
    const expiresAt = dto.expiresAt
      ? new Date(dto.expiresAt)
      : new Date(now.getTime() + durationMs);

    await this.prisma.subscription.updateMany({
      where: { userId: dto.userId, status: SubscriptionStatus.ACTIVE },
      data: { status: SubscriptionStatus.CANCELLED },
    });

    return this.prisma.subscription.create({
      data: {
        userId: dto.userId,
        provider: 'WEB',
        planId: dto.planId,
        status: 'ACTIVE',
        startedAt: now,
        expiresAt,
        receiptData: dto.paymentRef,
      },
    });
  }
}
