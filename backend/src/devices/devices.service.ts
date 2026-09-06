import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { RegisterDeviceDto } from './dto/register-device.dto';

@Injectable()
export class DevicesService {
  constructor(private readonly prisma: PrismaService) {}

  register(userId: string, dto: RegisterDeviceDto) {
    return this.prisma.devicePushToken.upsert({
      where: { userId_token: { userId, token: dto.token } },
      create: { userId, token: dto.token, platform: dto.platform },
      update: { platform: dto.platform },
    });
  }

  async unregister(userId: string, token: string) {
    await this.prisma.devicePushToken.deleteMany({ where: { userId, token } });
    return { ok: true };
  }
}
