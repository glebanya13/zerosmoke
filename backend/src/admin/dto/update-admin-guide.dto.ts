import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsInt,
  IsOptional,
  IsString,
  MaxLength,
  Min,
  ValidateNested,
} from 'class-validator';

class GuideContentSectionDto {
  @IsInt()
  @Min(1)
  position!: number;

  @IsString()
  @MaxLength(200)
  title!: string;

  @IsString()
  @MaxLength(10000)
  text!: string;
}

class GuideContentDto {
  @IsString()
  @MaxLength(2000)
  intro!: string;

  @IsArray()
  @ArrayMaxSize(50)
  @ValidateNested({ each: true })
  @Type(() => GuideContentSectionDto)
  sections!: GuideContentSectionDto[];

  @IsString()
  @MaxLength(50000)
  fullText!: string;
}

export class UpdateAdminGuideDto {
  @IsOptional()
  @IsString()
  @MaxLength(200)
  title?: string;

  @IsOptional()
  @ValidateNested()
  @Type(() => GuideContentDto)
  content?: GuideContentDto;
}
