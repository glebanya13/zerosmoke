import { Controller, Get, UseGuards } from '@nestjs/common';
import { RatingService } from './rating.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import type { User } from '../../generated/prisma/client';

@Controller('rating')
@UseGuards(JwtAuthGuard)
export class RatingController {
  constructor(private readonly rating: RatingService) {}

  @Get('leaderboard')
  leaderboard(@CurrentUser() user: User) {
    return this.rating.leaderboard(user);
  }

  @Get('me')
  me(@CurrentUser() user: User) {
    return this.rating.me(user);
  }
}
