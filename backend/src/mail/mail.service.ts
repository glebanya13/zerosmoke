import { Injectable, Logger } from '@nestjs/common';

export interface MailService {
  sendOtpCode(email: string, code: string): Promise<void>;
}

export const MAIL_SERVICE = Symbol('MAIL_SERVICE');

@Injectable()
export class ConsoleMailService implements MailService {
  private readonly logger = new Logger(ConsoleMailService.name);

  async sendOtpCode(email: string, code: string): Promise<void> {
    this.logger.log(`OTP code for ${email}: ${code}`);
  }
}
