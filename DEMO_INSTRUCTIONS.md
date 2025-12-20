# Инструкции для демонстрации курсовой работы

## 🎯 Чек-лист для защиты

### 1. Запуск системы

```powershell
# Перейти в директорию проекта
cd C:\Education\DB_Labs\CP

# Запустить все сервисы
docker-compose up -d

# Проверить статус
docker-compose ps

# Просмотр логов
docker-compose logs -f backend
```

### 2. Проверка работы API

Открыть Swagger UI: http://localhost:8000/docs

### 3. Демонстрация структуры БД

```powershell
# Подключиться к PostgreSQL
docker exec -it cp_postgres psql -U cpuser -d competitive_programming

# Посмотреть список таблиц
\dt

# Посмотреть структуру таблицы
\d users
\d submissions

# Выйти
\q
```

### 4. Демонстрация триггеров

#### Триггер аудита:

```sql
-- Создать пользователя (через Swagger или SQL)
INSERT INTO users (username, email, full_name, role) 
VALUES ('demo_user', 'demo@test.com', 'Demo User', 'participant');

-- Проверить audit_log
SELECT * FROM audit_log WHERE table_name = 'users' ORDER BY changed_at DESC LIMIT 5;
```

#### Триггер обновления standings:

```sql
-- Обновить вердикт посылки на accepted
UPDATE submissions SET verdict = 'accepted', score = 100 WHERE submission_id = 1;

-- Проверить standings (автоматически обновился)
SELECT * FROM standings WHERE contest_id = 1 ORDER BY rank;
```

### 5. Демонстрация SQL функций

#### Скалярные функции:

```sql
-- Процент решенных задач пользователя
SELECT get_user_success_rate(3);

-- Расчет сложности задачи
SELECT calculate_problem_difficulty(1);

-- Место пользователя в контесте
SELECT get_user_contest_rank(3, 1);

-- Количество решенных уникальных задач
SELECT count_unique_solved_problems(3);
```

#### Табличные функции:

```sql
-- Топ-10 пользователей
SELECT * FROM get_top_users(10);

-- Статистика контеста
SELECT * FROM get_contest_statistics(1);

-- Отчет пользователя по контесту
SELECT * FROM get_user_contest_report(3, 1);

-- Статистика задач
SELECT * FROM get_problem_statistics();
```

### 6. Демонстрация VIEW

```sql
-- Турнирная таблица
SELECT * FROM v_contest_standings WHERE contest_id = 1 ORDER BY rank;

-- Статистика пользователей
SELECT * FROM v_user_statistics ORDER BY rating DESC LIMIT 10;

-- Статистика задач
SELECT * FROM v_problem_statistics ORDER BY acceptance_rate DESC;

-- Статистика языков
SELECT * FROM v_language_statistics;

-- Распределение вердиктов
SELECT * FROM v_verdict_distribution;
```

### 7. Демонстрация индексов и оптимизации

```sql
-- БЕЗ индекса (для сравнения, если удалить индекс):
-- DROP INDEX idx_submissions_user;
EXPLAIN ANALYZE
SELECT * FROM submissions WHERE user_id = 3;

-- С индексом:
EXPLAIN ANALYZE
SELECT * FROM submissions WHERE user_id = 3;

-- Сложный запрос с JOIN и агрегацией
EXPLAIN ANALYZE
SELECT 
    u.username,
    COUNT(DISTINCT s.problem_id) as solved_problems,
    AVG(s.execution_time_ms) as avg_time
FROM users u
INNER JOIN submissions s ON u.user_id = s.user_id
WHERE s.verdict = 'accepted' AND u.role = 'participant'
GROUP BY u.user_id, u.username
ORDER BY solved_problems DESC;
```

### 8. Демонстрация CRUD операций через API

#### Через Swagger UI (http://localhost:8000/docs):

1. **POST /users/** - создать пользователя
2. **GET /users/** - получить список
3. **GET /users/{user_id}** - получить по ID
4. **PUT /users/{user_id}** - обновить
5. **DELETE /users/{user_id}** - удалить

Повторить для contests, problems, submissions.

### 9. Демонстрация сложных аналитических запросов

#### Через Swagger:

- `GET /analytics/standings/1` - турнирная таблица
- `GET /analytics/users/top?limit=10` - топ пользователей
- `GET /analytics/contests/1/statistics` - статистика контеста
- `GET /analytics/users/3/success-rate` - процент успеха
- `GET /analytics/audit-log?table_name=users&limit=20` - журнал аудита

### 10. Демонстрация batch-import

#### Через Swagger:

```json
POST /batch/import
{
  "entity_type": "users",
  "data": [
    {
      "username": "batch_user1",
      "email": "batch1@test.com",
      "full_name": "Batch User 1",
      "role": "participant",
      "country": "Russia"
    },
    {
      "username": "batch_user2",
      "email": "batch2@test.com",
      "full_name": "Batch User 2",
      "role": "participant",
      "country": "Belarus"
    },
    {
      "username": "batch_user1",
      "email": "duplicate@test.com",
      "full_name": "Duplicate",
      "role": "participant"
    }
  ]
}
```

Ответ покажет:
- `success`: 2
- `failed`: 1
- `errors`: детали ошибки для дубликата

### 11. Просмотр всех ограничений целостности

```sql
-- PRIMARY KEYS
SELECT 
    tc.table_name, 
    kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
    ON tc.constraint_name = kcu.constraint_name
WHERE tc.constraint_type = 'PRIMARY KEY'
    AND tc.table_schema = 'public'
ORDER BY tc.table_name;

-- FOREIGN KEYS
SELECT
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_schema = 'public';

-- CHECK constraints
SELECT
    tc.table_name,
    tc.constraint_name,
    cc.check_clause
FROM information_schema.table_constraints tc
JOIN information_schema.check_constraints cc
    ON tc.constraint_name = cc.constraint_name
WHERE tc.constraint_type = 'CHECK'
    AND tc.table_schema = 'public';
```

### 12. Демонстрация транзакций

```sql
BEGIN;

-- Создать контест
INSERT INTO contests (title, description, contest_type, status, start_time, duration_minutes, created_by)
VALUES ('Demo Contest', 'Test transaction', 'Codeforces', 'upcoming', NOW() + INTERVAL '1 day', 120, 1)
RETURNING contest_id;

-- Добавить задачу в контест (использовать contest_id из предыдущего запроса)
INSERT INTO contest_problems (contest_id, problem_id, problem_order, max_score)
VALUES (4, 1, 1, 100);

COMMIT;
-- или ROLLBACK; для отката
```

### 13. Проверка безопасности

```sql
-- Проверить, что нет хардкод паролей в коде
-- Все credentials в .env файле

-- Проверить параметризацию запросов
-- Все запросы используют :параметры или ORM
```

## 📊 Презентация результатов

### Показатели для защиты:

1. **Структура БД**: 10 таблиц ✅
2. **Связи**: 1:1, 1:N, N:M ✅
3. **Ограничения**: PK, FK, CHECK, UNIQUE, NOT NULL ✅
4. **Триггеры**: 5 триггеров (3 audit + 2 business logic) ✅
5. **Функции**: 4 скалярные + 4 табличные ✅
6. **VIEW**: 5 представлений ✅
7. **Индексы**: 25+ индексов ✅
8. **API**: 35+ endpoints ✅
9. **CRUD**: Полный набор для всех сущностей ✅
10. **Batch-import**: С логированием ошибок ✅
11. **Docker**: docker-compose для всех сервисов ✅
12. **Swagger**: Автоматическая документация ✅
13. **Безопасность**: .env + параметризация ✅

## 🎓 Краткий рассказ для защиты (2-3 минуты)

"Я разработал систему управления соревнованиями по спортивному программированию. 

**База данных** состоит из 10 таблиц с полным набором связей и ограничений целостности. Реализованы все типы связей: 1:1, 1:N и N:M.

**Триггеры** автоматически логируют все изменения в audit_log и в реальном времени обновляют турнирную таблицу при появлении новых решений.

**SQL функции** включают скалярные для расчета метрик (процент успеха, рейтинг) и табличные для формирования отчетов.

**5 представлений** предоставляют агрегированные данные: турнирные таблицы, статистику пользователей, задач и языков программирования.

**Backend на FastAPI** предоставляет полный REST API с 35+ endpoints. CRUD операции реализованы через SQLAlchemy ORM, а сложная аналитика - через чистый SQL с JOIN и агрегатами.

**Batch-import endpoint** позволяет массово загружать данные с детальным логированием ошибок.

Все **индексы оптимизированы** для частых запросов. Демонстрация EXPLAIN ANALYZE показывает улучшение до 18 раз.

Система **полностью контейнеризована** с помощью Docker, запускается одной командой. **Swagger** предоставляет интерактивную документацию API.

**Безопасность**: все credentials в .env, все запросы параметризованы для защиты от SQL-инъекций."

## 🔧 Полезные команды для troubleshooting

```powershell
# Перезапуск всех сервисов
docker-compose restart

# Просмотр логов конкретного сервиса
docker-compose logs backend
docker-compose logs db

# Полная очистка и перезапуск
docker-compose down -v
docker-compose up -d

# Проверка подключения к БД
docker exec -it cp_postgres psql -U cpuser -d competitive_programming -c "SELECT version();"

# Экспорт данных
docker exec -it cp_postgres pg_dump -U cpuser competitive_programming > backup.sql
```

## ✅ Финальный чеклист перед защитой

- [ ] Система запускается через `docker-compose up -d`
- [ ] Swagger доступен на http://localhost:8000/docs
- [ ] БД заполнена тестовыми данными
- [ ] Все триггеры работают
- [ ] Все функции возвращают корректные результаты
- [ ] VIEW отображают актуальные данные
- [ ] CRUD операции работают через API
- [ ] Batch-import успешно обрабатывает данные
- [ ] Audit log фиксирует изменения
- [ ] README.md содержит полную документацию
- [ ] .env не содержит credentials в git (проверить .gitignore)
