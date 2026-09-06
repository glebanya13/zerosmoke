import { PrismaService } from '../prisma/prisma.service';
import { SubscriptionStatus } from '../../generated/prisma/enums';

/** Returns true when the user has a non-expired ACTIVE subscription. */
export async function hasActiveSubscription(
  prisma: PrismaService,
  userId: string,
): Promise<boolean> {
  const sub = await prisma.subscription.findFirst({
    where: { userId, status: SubscriptionStatus.ACTIVE },
    orderBy: { createdAt: 'desc' },
  });
  if (!sub) return false;
  if (sub.expiresAt && sub.expiresAt.getTime() < Date.now()) {
    await prisma.subscription.update({
      where: { id: sub.id },
      data: { status: SubscriptionStatus.EXPIRED },
    });
    return false;
  }
  return true;
}
