import { CanActivate, ExecutionContext, Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import type { Request } from 'express';

@Injectable()
export class AdminKeyGuard implements CanActivate {
  constructor(private readonly config: ConfigService) {}

  canActivate(context: ExecutionContext) {
    const configuredKey = this.config.get<string>('ADMIN_API_KEY');
    const suppliedKey = context.switchToHttp().getRequest<Request>().header('x-admin-key');
    if (!configuredKey || suppliedKey !== configuredKey) throw new UnauthorizedException('Invalid admin credentials');
    return true;
  }
}
