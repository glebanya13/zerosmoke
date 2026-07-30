import { IsEmail, IsEnum, Length } from 'class-validator';
import { OtpPurpose } from '../../../generated/prisma/enums';

export class VerifyOtpDto {
  @IsEmail()
  email!: string;

  @Length(4, 4)
  code!: string;

  @IsEnum(OtpPurpose)
  purpose!: OtpPurpose;
}
