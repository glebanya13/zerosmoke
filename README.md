# ZeroSmoke

Мобильное приложение (Flutter) + API (NestJS) + admin. База и контейнеры живут на сервере (`deploy/`), локально Docker/Postgres не поднимаем.

## Структура

- `app/` — Flutter-клиент
- `backend/` — NestJS API
- `admin/` — админка
- `deploy/docker-compose.yml` — серверный стек (`zerosmoke-*` контейнеры)

## Мобилка

```bash
cd app
flutter pub get
flutter run --dart-define=API_BASE_URL=https://api.your-server.example
```

По умолчанию `API_BASE_URL` = `http://localhost:3000` только если API проброшен с сервера на машину разработчика.

## Backend на сервере

```bash
cd deploy
docker compose up -d --build
docker compose exec zerosmoke-api npx prisma migrate deploy
```

Подписка оплачивается на сайте (`SUBSCRIPTION_WEB_URL`); сайт активирует её через `POST /subscription/activate` с `x-admin-key`.
