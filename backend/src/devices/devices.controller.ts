import { Body, Controller, Delete, Post, UseGuards } from '@nestjs/common';
import { DevicesService } from './devices.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { RegisterDeviceDto } from './dto/register-device.dto';
import type { User } from '../../generated/prisma/client';

@Controller('devices')
@UseGuards(JwtAuthGuard)
export class DevicesController {
  constructor(private readonly devices: DevicesService) {}

  @Post('push-token')
  register(@CurrentUser() user: User, @Body() dto: RegisterDeviceDto) {
    return this.devices.register(user.id, dto);
  }

  @Delete('push-token')
  unregister(
    @CurrentUser() user: User,
    @Body() body: { token: string },
  ) {
    return this.devices.unregister(user.id, body.token);
  }
}
