# ZeroSmoke

Мобильное приложение (Flutter) + API (NestJS) + admin. Продакшен-стек — `deploy/compose.yml`.

## Структура

- `app/` — Flutter-клиент
- `backend/` — NestJS API
- `admin/` — админка
- `deploy/compose.yml` — продакшен (Postgres, API, admin, Caddy)
- `deploy/docker-compose.yml` — упрощённый локальный стек для отладки

## Мобилка

```bash
cd app
flutter pub get
flutter run --dart-define=API_BASE_URL=https://zerosmoker.ru/api
```

## Backend на сервере

1. Скопируйте `backend/.env.example` в `.env` на сервере и заполните секреты.
2. Запустите стек:

```bash
cd deploy
docker compose --env-file ../.env up -d --build
```

Первый импорт контента (опционально):

```bash
docker compose --profile tools run --rm content-import
```

Подписка оплачивается на сайте (`SUBSCRIPTION_WEB_URL`); сайт активирует её через `POST /subscription/activate` с `x-admin-key`.

## OTP по e-mail

В проде задайте переменные `UNISENDER_API_KEY` и `UNISENDER_FROM_EMAIL` (Unisender Go). Без них коды пишутся в лог контейнера `zerosmoke-api`.
