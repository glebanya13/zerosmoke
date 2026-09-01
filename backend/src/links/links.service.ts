import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { randomInt } from 'node:crypto';
import { PrismaService } from '../prisma/prisma.service';
import { LinkStatus, UserRole } from '../../generated/prisma/enums';

const INVITE_CODE_TTL_MS = 10 * 60_000;
const INVITE_CODE_ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

@Injectable()
export class LinksService {
  constructor(private readonly prisma: PrismaService) {}

  private generateInviteCode(): string {
    let code = '';
    for (let i = 0; i < 6; i++) {
      code += INVITE_CODE_ALPHABET[randomInt(0, INVITE_CODE_ALPHABET.length)];
    }
    return code;
  }

  private async assertCanLink(userId: string) {
    const active = await this.prisma.parentChildLink.findFirst({
      where: {
        status: LinkStatus.ACTIVE,
        OR: [{ ownerId: userId }, { counterpartId: userId }],
      },
    });
    if (active) {
      throw new ConflictException('У вас уже есть активная связка аккаунтов');
    }
  }

  private validateLinkRoles(ownerRole: UserRole, redeemerRole: UserRole) {
    const valid =
      (ownerRole === UserRole.PARENT && redeemerRole === UserRole.CHILD) ||
      (ownerRole === UserRole.CHILD && redeemerRole === UserRole.PARENT);
    if (!valid) {
      throw new BadRequestException(
        'Связка возможна только между аккаунтом родителя и ребёнка',
      );
    }
  }

  async createInviteCode(ownerId: string) {
    const owner = await this.prisma.user.findUniqueOrThrow({ where: { id: ownerId } });
    if (owner.role !== UserRole.PARENT && owner.role !== UserRole.CHILD) {
      throw new ForbiddenException('Связка доступна только родителям и детям');
    }
    await this.assertCanLink(ownerId);

    await this.prisma.parentChildLink.deleteMany({
      where: { ownerId, status: LinkStatus.PENDING },
    });

    const link = await this.prisma.parentChildLink.create({
      data: {
        ownerId,
        inviteCode: this.generateInviteCode(),
        status: LinkStatus.PENDING,
        expiresAt: new Date(Date.now() + INVITE_CODE_TTL_MS),
      },
    });
    return { inviteCode: link.inviteCode, expiresAt: link.expiresAt };
  }

  async redeemCode(userId: string, code: string) {
    const redeemer = await this.prisma.user.findUniqueOrThrow({ where: { id: userId } });
    await this.assertCanLink(userId);

    const link = await this.prisma.parentChildLink.findFirst({
      where: {
        inviteCode: code.toUpperCase(),
        status: LinkStatus.PENDING,
        expiresAt: { gt: new Date() },
      },
      include: { owner: true },
    });

    if (!link) {
      throw new NotFoundException('Неверный или просроченный код приглашения');
    }
    if (link.ownerId === userId) {
      throw new BadRequestException('Нельзя использовать свой код приглашения');
    }
    this.validateLinkRoles(link.owner.role, redeemer.role);

    return this.prisma.parentChildLink.update({
      where: { id: link.id },
      data: { counterpartId: userId, status: LinkStatus.ACTIVE, linkedAt: new Date() },
      include: { owner: true, counterpart: true },
    });
  }

  async getMyLink(userId: string) {
    const link = await this.prisma.parentChildLink.findFirst({
      where: {
        status: LinkStatus.ACTIVE,
        OR: [{ ownerId: userId }, { counterpartId: userId }],
      },
      include: { owner: true, counterpart: true },
    });

    if (!link) {
      return null;
    }

    const counterpart = link.ownerId === userId ? link.counterpart : link.owner;
    return { linkId: link.id, status: link.status, linkedAt: link.linkedAt, counterpart };
  }

  /** Active linked children for a parent (empty for non-parents / no links). */
  async getChildren(ownerId: string) {
    const links = await this.prisma.parentChildLink.findMany({
      where: { ownerId, status: LinkStatus.ACTIVE, counterpartId: { not: null } },
      include: { counterpart: true },
      orderBy: { linkedAt: 'desc' },
    });
    return links
      .map((link) => link.counterpart)
      .filter((user): user is NonNullable<typeof user> => Boolean(user));
  }

  async unlink(userId: string, linkId: string) {
    const link = await this.prisma.parentChildLink.findUnique({ where: { id: linkId } });
    if (!link) {
      throw new NotFoundException('Связка не найдена');
    }
    if (link.ownerId !== userId && link.counterpartId !== userId) {
      throw new ForbiddenException('Вы не участник этой связки');
    }
    await this.prisma.parentChildLink.delete({ where: { id: linkId } });
    return { message: 'Связка удалена' };
  }
}
