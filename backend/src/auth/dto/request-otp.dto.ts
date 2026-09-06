import { IsEmail, IsEnum } from 'class-validator';
import { Transform } from 'class-transformer';
import { OtpPurpose } from '../../../generated/prisma/enums';
import { normalizeEmail } from '../auth.util';

export class RequestOtpDto {
  @Transform(({ value }) => (typeof value === 'string' ? normalizeEmail(value) : value))
  @IsEmail()
  email!: string;

  @IsEnum(OtpPurpose)
  purpose!: OtpPurpose;
}
