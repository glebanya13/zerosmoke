import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { PrismaModule } from './prisma/prisma.module';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { LinksModule } from './links/links.module';
import { ReferralsModule } from './referrals/referrals.module';
import { validate } from './config/env.validation';
import { AdminModule } from './admin/admin.module';
import { ContentModule } from './content/content.module';
import { RatingModule } from './rating/rating.module';
import { AchievementsModule } from './achievements/achievements.module';
import { SettingsModule } from './settings/settings.module';
import { SubscriptionModule } from './subscription/subscription.module';
import { QuitModule } from './quit/quit.module';
import { DevicesModule } from './devices/devices.module';
import { NotificationsModule } from './notifications/notifications.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true, validate }),
    PrismaModule,
    AuthModule,
    UsersModule,
    LinksModule,
    ReferralsModule,
    AdminModule,
    ContentModule,
    RatingModule,
    AchievementsModule,
    SettingsModule,
    SubscriptionModule,
    QuitModule,
    DevicesModule,
    NotificationsModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
