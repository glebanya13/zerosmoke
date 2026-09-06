import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { UpdateQuitProfileDto } from './dto/update-quit-profile.dto';
import { CreateCravingDto } from './dto/create-craving.dto';

@Injectable()
export class QuitService {
  constructor(private readonly prisma: PrismaService) {}

  private computeStats(profile: {
    quitDate: Date | null;
    cigarettesPerDay: number;
    packPriceCents: number;
    cigarettesPerPack: number;
  }) {
    if (!profile.quitDate) {
      return {
        daysSmokeFree: 0,
        cigarettesAvoided: 0,
        moneySavedCents: 0,
      };
    }
    const ms = Date.now() - profile.quitDate.getTime();
    const daysSmokeFree = Math.max(0, Math.floor(ms / 86_400_000));
    const cigarettesAvoided = daysSmokeFree * profile.cigarettesPerDay;
    const packsAvoided =
      profile.cigarettesPerPack > 0
        ? cigarettesAvoided / profile.cigarettesPerPack
        : 0;
    const moneySavedCents = Math.round(packsAvoided * profile.packPriceCents);
    return { daysSmokeFree, cigarettesAvoided, moneySavedCents };
  }

  async getProfile(userId: string) {
    const profile = await this.prisma.quitProfile.upsert({
      where: { userId },
      create: { userId },
      update: {},
    });
    return { ...profile, ...this.computeStats(profile) };
  }

  async updateProfile(userId: string, dto: UpdateQuitProfileDto) {
    const data: {
      quitDate?: Date | null;
      cigarettesPerDay?: number;
      packPriceCents?: number;
      cigarettesPerPack?: number;
    } = {};
    if (dto.quitDate !== undefined) {
      data.quitDate = dto.quitDate ? new Date(dto.quitDate) : null;
    }
    if (dto.cigarettesPerDay !== undefined) {
      data.cigarettesPerDay = dto.cigarettesPerDay;
    }
    if (dto.packPriceCents !== undefined) {
      data.packPriceCents = dto.packPriceCents;
    }
    if (dto.cigarettesPerPack !== undefined) {
      data.cigarettesPerPack = dto.cigarettesPerPack;
    }
    const profile = await this.prisma.quitProfile.upsert({
      where: { userId },
      create: { userId, ...data },
      update: data,
    });
    return { ...profile, ...this.computeStats(profile) };
  }

  async logCraving(userId: string, dto: CreateCravingDto) {
    return this.prisma.cravingLog.create({
      data: {
        userId,
        intensity: dto.intensity,
        note: dto.note,
      },
    });
  }

  async recentCravings(userId: string) {
    return this.prisma.cravingLog.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      take: 20,
    });
  }
}
