import { IsBoolean, IsOptional } from 'class-validator';

export class UpdateSettingsDto {
  @IsOptional()
  @IsBoolean()
  soundEnabled?: boolean;

  @IsOptional()
  @IsBoolean()
  vibrationEnabled?: boolean;

  @IsOptional()
  @IsBoolean()
  hintsEnabled?: boolean;

  @IsOptional()
  @IsBoolean()
  notifyTests?: boolean;

  @IsOptional()
  @IsBoolean()
  notifyRankChanges?: boolean;

  @IsOptional()
  @IsBoolean()
  dataCollection?: boolean;

  @IsOptional()
  @IsBoolean()
  showActivity?: boolean;
}
