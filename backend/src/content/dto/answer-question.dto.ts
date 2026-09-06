import { IsInt, IsString, Min } from 'class-validator';

export class AnswerQuestionDto {
  @IsString()
  questionId!: string;

  @IsInt()
  @Min(0)
  selectedOption!: number;
}
