import { Length } from 'class-validator';

export class ApplyReferralDto {
  @Length(6, 8)
  code!: string;
}
