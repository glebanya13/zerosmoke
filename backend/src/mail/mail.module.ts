import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { ConsoleMailService, MAIL_SERVICE } from './mail.service';
import { UnisenderMailService } from './unisender-mail.service';

@Module({
  imports: [ConfigModule],
  providers: [
    {
      provide: MAIL_SERVICE,
      useFactory: (config: ConfigService) => {
        if (config.get<string>('UNISENDER_API_KEY')) {
          return new UnisenderMailService(config);
        }
        return new ConsoleMailService();
      },
      inject: [ConfigService],
    },
  ],
  exports: [MAIL_SERVICE],
})
export class MailModule {}
