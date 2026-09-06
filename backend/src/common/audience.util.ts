import type { TestAudience } from '../../generated/prisma/client';

export function audienceForAge(age: number): TestAudience {
  if (age < 16) return 'AGE_6';
  if (age < 18) return 'AGE_16';
  return 'AGE_18';
}
