import { plainToInstance } from 'class-transformer';
import { IsInt, IsOptional, IsString, Min, validateSync } from 'class-validator';

class EnvironmentVariables {
  @IsString()
  DATABASE_URL!: string;

  @IsInt()
  @Min(0)
  PORT!: number;

  @IsString()
  JWT_ACCESS_SECRET!: string;

  @IsString()
  JWT_ACCESS_TTL!: string;

  @IsString()
  JWT_REFRESH_SECRET!: string;

  @IsString()
  JWT_REFRESH_TTL!: string;

  @IsString()
  REGISTRATION_TOKEN_SECRET!: string;

  @IsString()
  REGISTRATION_TOKEN_TTL!: string;

  @IsInt()
  @Min(1)
  OTP_TTL_MINUTES!: number;

  @IsInt()
  @Min(0)
  OTP_REQUEST_COOLDOWN_SECONDS!: number;

  @IsOptional()
  @IsString()
  ADMIN_API_KEY?: string;

  @IsOptional()
  @IsString()
  SUBSCRIPTION_WEB_URL?: string;

  @IsOptional()
  @IsString()
  FCM_SERVER_KEY?: string;

  @IsOptional()
  @IsString()
  UNISENDER_API_KEY?: string;

  @IsOptional()
  @IsString()
  UNISENDER_FROM_EMAIL?: string;

  @IsOptional()
  @IsString()
  UNISENDER_FROM_NAME?: string;

  @IsOptional()
  @IsString()
  UNISENDER_API_URL?: string;
}

export function validate(config: Record<string, unknown>) {
  const validated = plainToInstance(EnvironmentVariables, config, {
    enableImplicitConversion: true,
  });
  const errors = validateSync(validated, { skipMissingProperties: false });

  if (errors.length > 0) {
    throw new Error(`Environment validation failed: ${errors.toString()}`);
  }

  return validated;
}
