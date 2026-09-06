import { Length } from 'class-validator';

export class RedeemCodeDto {
  @Length(6, 6)
  code!: string;
}
