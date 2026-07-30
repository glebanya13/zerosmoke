import { Body, Controller, Get, Put, UseGuards } from '@nestjs/common';
import { SettingsService } from './settings.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { UpdateSettingsDto } from './dto/update-settings.dto';
import type { User } from '../../generated/prisma/client';

@Controller('settings')
@UseGuards(JwtAuthGuard)
export class SettingsController {
  constructor(private readonly settings: SettingsService) {}

  @Get('me')
  getMine(@CurrentUser() user: User) {
    return this.settings.getMine(user.id);
  }

  @Put('me')
  updateMine(@CurrentUser() user: User, @Body() dto: UpdateSettingsDto) {
    return this.settings.updateMine(user.id, dto);
  }
}
