import { Body, Controller, Get, Post, Query, UseGuards } from '@nestjs/common';
import { SubscriptionService } from './subscription.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { ActivateSubscriptionDto } from './dto/activate-subscription.dto';
import { AdminKeyGuard } from '../admin/admin-key.guard';
import type { User } from '../../generated/prisma/client';

@Controller('subscription')
export class SubscriptionController {
  constructor(private readonly subscription: SubscriptionService) {}

  @Get('plans')
  @UseGuards(JwtAuthGuard)
  plans(@Query('tier') tier?: 'child1' | 'child2') {
    return this.subscription.plans(tier);
  }

  @Get('me')
  @UseGuards(JwtAuthGuard)
  me(@CurrentUser() user: User) {
    return this.subscription.me(user.id);
  }

  @Get('active')
  @UseGuards(JwtAuthGuard)
  async active(@CurrentUser() user: User) {
    return { active: await this.subscription.isActive(user.id) };
  }

  /** Mobile opens this URL in the browser to pay on the website. */
  @Get('checkout-url')
  @UseGuards(JwtAuthGuard)
  checkoutUrl(
    @CurrentUser() user: User,
    @Query('planId') planId: string,
  ) {
    return this.subscription.checkoutUrl(planId, user.id);
  }

  /** Website payment backend activates the subscription after successful payment. */
  @Post('activate')
  @UseGuards(AdminKeyGuard)
  activate(@Body() dto: ActivateSubscriptionDto) {
    return this.subscription.activateFromWebsite(dto);
  }
}
