import { IsEmail, IsEnum, Length } from 'class-validator';
import { Transform } from 'class-transformer';
import { OtpPurpose } from '../../../generated/prisma/enums';
import { normalizeEmail } from '../auth.util';

export class VerifyOtpDto {
  @Transform(({ value }) => (typeof value === 'string' ? normalizeEmail(value) : value))
  @IsEmail()
  email!: string;

  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @Length(4, 4)
  code!: string;

  @IsEnum(OtpPurpose)
  purpose!: OtpPurpose;
}
