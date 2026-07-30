import { IsEmail, IsEnum } from 'class-validator';
import { OtpPurpose } from '../../../generated/prisma/enums';

export class RequestOtpDto {
  @IsEmail()
  email!: string;

  @IsEnum(OtpPurpose)
  purpose!: OtpPurpose;
}
