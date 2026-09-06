import { Controller, Delete, Get, Param, Post, Body, UseGuards } from '@nestjs/common';
import { LinksService } from './links.service';
import { RedeemCodeDto } from './dto/redeem-code.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import type { User } from '../../generated/prisma/client';

@Controller('links')
@UseGuards(JwtAuthGuard)
export class LinksController {
  constructor(private readonly linksService: LinksService) {}

  @Post('invite-code')
  createInviteCode(@CurrentUser() user: User) {
    return this.linksService.createInviteCode(user.id);
  }

  @Post('redeem')
  redeem(@CurrentUser() user: User, @Body() dto: RedeemCodeDto) {
    return this.linksService.redeemCode(user.id, dto.code);
  }

  @Get('me')
  getMyLink(@CurrentUser() user: User) {
    return this.linksService.getMyLink(user.id);
  }

  @Get('children')
  getChildren(@CurrentUser() user: User) {
    return this.linksService.getChildren(user.id);
  }

  @Delete(':id')
  unlink(@CurrentUser() user: User, @Param('id') id: string) {
    return this.linksService.unlink(user.id, id);
  }
}
