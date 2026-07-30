import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
  ) {}

  async notifyUser(
    userId: string,
    payload: { title: string; body: string; type: 'tests' | 'rank' },
  ) {
    const settings = await this.prisma.userSettings.findUnique({
      where: { userId },
    });
    if (payload.type === 'tests' && settings && !settings.notifyTests) {
      return { sent: 0, skipped: true };
    }
    if (payload.type === 'rank' && settings && !settings.notifyRankChanges) {
      return { sent: 0, skipped: true };
    }

    const tokens = await this.prisma.devicePushToken.findMany({
      where: { userId },
    });
    if (!tokens.length) {
      this.logger.debug(`No push tokens for user ${userId}`);
      return { sent: 0, skipped: false };
    }

    const fcmKey = this.config.get<string>('FCM_SERVER_KEY');
    let sent = 0;
    for (const row of tokens) {
      if (fcmKey) {
        try {
          const ok = await this.sendFcm(fcmKey, row.token, payload);
          if (ok) sent += 1;
        } catch (e) {
          this.logger.warn(`FCM send failed for ${row.token}: ${e}`);
        }
      } else {
        this.logger.log(
          `[push:${payload.type}] user=${userId} token=${row.token.slice(0, 8)}… ${payload.title}: ${payload.body}`,
        );
        sent += 1;
      }
    }
    return { sent, skipped: false };
  }

  private async sendFcm(
    serverKey: string,
    token: string,
    payload: { title: string; body: string; type: string },
  ): Promise<boolean> {
    const res = await fetch('https://fcm.googleapis.com/fcm/send', {
      method: 'POST',
      headers: {
        Authorization: `key=${serverKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        to: token,
        notification: { title: payload.title, body: payload.body },
        data: { type: payload.type },
      }),
    });
    return res.ok;
  }
}
