import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { randomInt } from 'node:crypto';
import { PrismaService } from '../prisma/prisma.service';
import { LinkStatus } from '../../generated/prisma/enums';

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

  async createInviteCode(ownerId: string) {
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
    const link = await this.prisma.parentChildLink.findFirst({
      where: {
        inviteCode: code.toUpperCase(),
        status: LinkStatus.PENDING,
        expiresAt: { gt: new Date() },
      },
    });

    if (!link) {
      throw new NotFoundException('Invalid or expired invite code');
    }
    if (link.ownerId === userId) {
      throw new BadRequestException('Cannot redeem your own invite code');
    }

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
      throw new NotFoundException('Link not found');
    }
    if (link.ownerId !== userId && link.counterpartId !== userId) {
      throw new ForbiddenException('Not part of this link');
    }
    await this.prisma.parentChildLink.delete({ where: { id: linkId } });
    return { message: 'Unlinked' };
  }
}
