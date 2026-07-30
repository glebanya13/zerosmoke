import {
  IsBoolean,
  IsIn,
  IsOptional,
  IsString,
  MaxLength,
} from 'class-validator';

export class UpdateAdminTestDto {
  @IsOptional()
  @IsString()
  @MaxLength(120)
  title?: string;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  description?: string;

  @IsOptional()
  @IsIn(['AGE_6', 'AGE_16', 'AGE_18'])
  audience?: 'AGE_6' | 'AGE_16' | 'AGE_18';

  @IsOptional()
  @IsBoolean()
  isPublished?: boolean;
}
