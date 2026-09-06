import {
  IsBoolean,
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  Max,
  Min,
} from 'class-validator';
import { UserRole } from '../../../generated/prisma/enums';

export class CompleteRegistrationDto {
  @IsString()
  registrationToken!: string;

  @IsEnum(UserRole)
  role!: UserRole;

  @IsString()
  name!: string;

  @IsInt()
  @Min(1)
  @Max(120)
  age!: number;

  @IsBoolean()
  isFemale!: boolean;

  @IsInt()
  @Min(0)
  avatarIndex!: number;

  @IsOptional()
  @IsString()
  phone?: string;
}
