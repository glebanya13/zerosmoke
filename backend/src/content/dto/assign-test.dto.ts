import { IsOptional, IsString, IsUUID, MaxLength } from 'class-validator';

export class AssignTestDto {
  @IsUUID()
  testId!: string;

  @IsUUID()
  assignedToId!: string;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  message?: string;
}
