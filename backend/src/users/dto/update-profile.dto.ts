import { IsBoolean, IsInt, IsOptional, IsString, Max, Min } from 'class-validator';

export class UpdateProfileDto {
  @IsOptional()
  @IsString()
  name?: string;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(120)
  age?: number;

  @IsOptional()
  @IsBoolean()
  isFemale?: boolean;

  @IsOptional()
  @IsInt()
  @Min(0)
  avatarIndex?: number;

  @IsOptional()
  @IsString()
  phone?: string;
}
