import { IsDateString, IsInt, IsOptional, Max, Min } from 'class-validator';

export class UpdateQuitProfileDto {
  @IsOptional()
  @IsDateString()
  quitDate?: string | null;

  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(100)
  cigarettesPerDay?: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  packPriceCents?: number;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(40)
  cigarettesPerPack?: number;
}
