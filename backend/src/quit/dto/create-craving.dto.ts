import { IsInt, IsOptional, IsString, Max, MaxLength, Min } from 'class-validator';

export class CreateCravingDto {
  @IsInt()
  @Min(1)
  @Max(5)
  intensity!: number;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  note?: string;
}
