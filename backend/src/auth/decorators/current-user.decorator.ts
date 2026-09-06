import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import type { User } from '../../../generated/prisma/client';

export const CurrentUser = createParamDecorator((_: unknown, ctx: ExecutionContext): User => {
  const request = ctx.switchToHttp().getRequest();
  return request.user;
});
