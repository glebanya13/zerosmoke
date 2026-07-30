import {
  ArrayMaxSize,
  ArrayMinSize,
  IsArray,
  IsIn,
  IsInt,
  IsOptional,
  IsString,
  MaxLength,
  Min,
} from 'class-validator';

export class CreateAdminQuestionDto {
  @IsOptional()
  @IsString()
  @MaxLength(5000)
  material?: string;

  @IsString()
  @MaxLength(1000)
  text!: string;

  @IsArray()
  @ArrayMinSize(2)
  @ArrayMaxSize(10)
  @IsString({ each: true })
  @MaxLength(500, { each: true })
  options!: string[];

  @IsInt()
  @Min(1)
  correctOption!: number;
}

export class UpdateAdminQuestionDto {
  @IsOptional()
  @IsString()
  @MaxLength(5000)
  material?: string;

  @IsOptional()
  @IsString()
  @MaxLength(1000)
  text?: string;

  @IsOptional()
  @IsArray()
  @ArrayMinSize(2)
  @ArrayMaxSize(10)
  @IsString({ each: true })
  @MaxLength(500, { each: true })
  options?: string[];

  @IsOptional()
  @IsInt()
  @Min(1)
  correctOption?: number;
}

export class MoveAdminQuestionDto {
  @IsIn(['UP', 'DOWN'])
  direction!: 'UP' | 'DOWN';
}
