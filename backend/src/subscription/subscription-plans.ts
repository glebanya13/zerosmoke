export interface SubscriptionPlan {
  id: string;
  title: string;
  price: string;
  discountLabel?: string;
  perMonth?: string;
}

// Starting price list, carried over verbatim from the pre-launch design mocks
// until product supplies real App Store/Play Store pricing.
export const SUBSCRIPTION_PLANS: Record<'child1' | 'child2', SubscriptionPlan[]> = {
  child1: [
    { id: '1m', title: '1 месяц', price: '199 ₽' },
    {
      id: '3m',
      title: '3 месяца',
      price: '549 ₽',
      discountLabel: 'Экономия 8%',
      perMonth: '183 ₽/мес',
    },
    {
      id: '6m',
      title: '6 месяцев',
      price: '1 049 ₽',
      discountLabel: 'Экономия 13%',
      perMonth: '174,83 ₽/мес',
    },
    {
      id: '12m',
      title: '12 месяцев',
      price: '1 799 ₽',
      discountLabel: 'Экономия 24%',
      perMonth: '150 ₽/мес',
    },
  ],
  child2: [
    { id: '1m', title: '1 месяц', price: '99 ₽' },
    { id: '3m', title: '3 месяца', price: '275 ₽' },
    { id: '6m', title: '6 месяцев', price: '525 ₽' },
    { id: '12m', title: '12 месяцев', price: '899 ₽' },
  ],
};

export const PLAN_DURATIONS_MS: Record<string, number> = {
  '1m': 30 * 86_400_000,
  '3m': 90 * 86_400_000,
  '6m': 180 * 86_400_000,
  '12m': 365 * 86_400_000,
};
