import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import type { MailService } from './mail.service';

@Injectable()
export class UnisenderMailService implements MailService {
  private readonly logger = new Logger(UnisenderMailService.name);

  constructor(private readonly config: ConfigService) {}

  async sendOtpCode(email: string, code: string): Promise<void> {
    const apiKey = this.config.getOrThrow<string>('UNISENDER_API_KEY');
    const fromEmail = this.config.getOrThrow<string>('UNISENDER_FROM_EMAIL');
    const fromName =
      this.config.get<string>('UNISENDER_FROM_NAME') ?? 'ZeroSmoke';
    const apiUrl =
      this.config.get<string>('UNISENDER_API_URL') ??
      'https://goapi.unisender.ru/ru/transactional/api/v1/email/send.json';

    const response = await fetch(apiUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-API-KEY': apiKey,
      },
      body: JSON.stringify({
        message: {
          recipients: [{ email }],
          from_email: fromEmail,
          from_name: fromName,
          subject: 'Код подтверждения ZeroSmoke',
          body: {
            html: `<p>Ваш код подтверждения: <strong>${code}</strong></p><p>Код действует ${this.config.get<number>('OTP_TTL_MINUTES') ?? 10} мин.</p>`,
            plaintext: `Ваш код подтверждения: ${code}`,
          },
        },
      }),
    });

    if (!response.ok) {
      const body = await response.text();
      this.logger.error(`Unisender send failed (${response.status}): ${body}`);
      throw new Error('Failed to send OTP email');
    }

    const payload = (await response.json()) as { status?: string; message?: string };
    if (payload.status && payload.status !== 'success') {
      this.logger.error(`Unisender error: ${payload.message ?? JSON.stringify(payload)}`);
      throw new Error('Failed to send OTP email');
    }
  }
}
