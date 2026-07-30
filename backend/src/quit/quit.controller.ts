import { Body, Controller, Get, Post, Put, UseGuards } from '@nestjs/common';
import { QuitService } from './quit.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { UpdateQuitProfileDto } from './dto/update-quit-profile.dto';
import { CreateCravingDto } from './dto/create-craving.dto';
import type { User } from '../../generated/prisma/client';

@Controller('quit')
@UseGuards(JwtAuthGuard)
export class QuitController {
  constructor(private readonly quit: QuitService) {}

  @Get('me')
  me(@CurrentUser() user: User) {
    return this.quit.getProfile(user.id);
  }

  @Put('me')
  update(@CurrentUser() user: User, @Body() dto: UpdateQuitProfileDto) {
    return this.quit.updateProfile(user.id, dto);
  }

  @Get('cravings')
  cravings(@CurrentUser() user: User) {
    return this.quit.recentCravings(user.id);
  }

  @Post('cravings')
  logCraving(@CurrentUser() user: User, @Body() dto: CreateCravingDto) {
    return this.quit.logCraving(user.id, dto);
  }
}
