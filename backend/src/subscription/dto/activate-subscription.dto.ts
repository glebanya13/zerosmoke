import { IsOptional, IsString, IsUUID, IsDateString } from 'class-validator';

export class ActivateSubscriptionDto {
  @IsUUID()
  userId!: string;

  @IsString()
  planId!: string;

  @IsOptional()
  @IsDateString()
  expiresAt?: string;

  @IsOptional()
  @IsString()
  paymentRef?: string;
}
