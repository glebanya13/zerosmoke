import { Body, Controller, Get, Post, UseGuards } from '@nestjs/common';
import { ReferralsService } from './referrals.service';
import { ApplyReferralDto } from './dto/apply-referral.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import type { User } from '../../generated/prisma/client';

@Controller('referrals')
@UseGuards(JwtAuthGuard)
export class ReferralsController {
  constructor(private readonly referralsService: ReferralsService) {}

  @Get('me')
  getMe(@CurrentUser() user: User) {
    return this.referralsService.getMe(user.id);
  }

  @Post('apply')
  apply(@CurrentUser() user: User, @Body() dto: ApplyReferralDto) {
    return this.referralsService.applyCode(user.id, dto.code);
  }
}
