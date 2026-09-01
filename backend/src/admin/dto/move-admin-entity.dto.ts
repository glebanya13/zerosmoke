import { IsIn } from 'class-validator';

export class MoveAdminEntityDto {
  @IsIn(['UP', 'DOWN'])
  direction!: 'UP' | 'DOWN';
}
