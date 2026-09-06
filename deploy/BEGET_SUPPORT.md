# Доступ к серверу без панели (Beget)

Сервер: **85.198.67.162** (Beget LLC), домен **zerosmoker.ru**.

SSH сейчас принимает **только ключ**. Пароль и веб-консоль недоступны — нужна **одна** просьба в поддержку Beget.

## 1. Написать в поддержку Beget

Каналы: [support.beget.com](https://support.beget.com), чат/тикет в личном кабинете (если вход в аккаунт есть, даже без VPS-панели), **support@beget.com**.

Текст заявки:

```
Здравствуйте!

VPS 85.198.67.162 (zerosmoker.ru), пользователь root.
Прошу добавить SSH-ключ в /root/.ssh/authorized_keys:

ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAD8GR8S+X2iUfCYHdmPEUO/LqGKhl924YEsL8ZRHF+q antismoke-prod-2026

Нужен для автоматического деплоя через GitHub Actions.
Спасибо!
```

После ответа «готово» деплой запускается из GitHub (см. ниже), локальный SSH не обязателен.

## 2. Секреты GitHub (уже можно настроить)

В репозитории **Settings → Secrets and variables → Actions**:

| Secret | Значение |
|--------|----------|
| `DEPLOY_HOST` | `85.198.67.162` |
| `DEPLOY_USER` | `root` |
| `DEPLOY_PATH` | `/opt/antismoke` |
| `DEPLOY_SSH_KEY` | содержимое файла `~/.ssh/antismoke_prod_ed25519` (приватный ключ целиком) |

Или из терминала на Mac (если установлен `gh`):

```bash
gh secret set DEPLOY_HOST -b'85.198.67.162' -R glebanya13/zerosmoke
gh secret set DEPLOY_USER -b'root' -R glebanya13/zerosmoke
gh secret set DEPLOY_PATH -b'/opt/antismoke' -R glebanya13/zerosmoke
gh secret set DEPLOY_SSH_KEY < ~/.ssh/antismoke_prod_ed25519 -R glebanya13/zerosmoke
```

## 3. Запуск деплоя

GitHub → **Actions** → **Deploy production** → **Run workflow**

Или push в `main` (деплой сам, если изменились `backend/`, `admin/`, `deploy/`).

## 4. Если Beget не может добавить ключ

Вариант B — **новый VPS** у Beget/другого провайдера:

1. При создании сразу указать SSH-ключ `antismoke-prod-2026`.
2. Установить Docker, клонировать репо, скопировать `deploy/.env` со старого сервера (из бэкапа).
3. Переключить A-запись `zerosmoker.ru` на новый IP.

Бэкап БД на старом сервере (если когда-нибудь появится доступ): см. `deploy/backup.sh`.
