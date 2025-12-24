# ТЕСТОВЫЕ ДАННЫЕ ДЛЯ SWAGGER UI

Скопируйте эти JSON-блоки в Swagger UI (http://localhost:8000/docs) для тестирования.

---

## ✅ ПОЗИТИВНЫЕ ТЕСТЫ (должны работать)

### 1. Создание пользователя

`POST /users/`

```json
{
  "username": "new_participant_1",
  "email": "participant1@example.com",
  "full_name": "Ivan Petrov",
  "role": "participant",
  "rating": 1500,
  "country": "Russia"
}
```

### 2. Создание соревнования

`POST /contests/`

```json
{
  "title": "Winter Championship 2025",
  "description": "Annual winter programming contest",
  "contest_type": "ACM_ICPC",
  "status": "upcoming",
  "start_time": "2025-12-30T14:00:00",
  "duration_minutes": 300,
  "created_by": 1
}
```

### 3. Создание задачи

`POST /problems/`

```json
{
  "title": "Two Sum Problem",
  "description": "Given an array of integers, return indices of the two numbers such that they add up to a specific target.",
  "difficulty": "easy",
  "time_limit_ms": 1000,
  "memory_limit_mb": 256,
  "author_id": 1
}
```

### 4. Создание посылки

`POST /submissions/`

```json
{
  "user_id": 3,
  "contest_id": 1,
  "problem_id": 1,
  "language": "Python",
  "source_code": "def two_sum(nums, target):\n    for i in range(len(nums)):\n        for j in range(i+1, len(nums)):\n            if nums[i] + nums[j] == target:\n                return [i, j]"
}
```

**Примечание:** verdict устанавливается автоматически в 'pending', не передавайте его при создании.

### 5. Обновление вердикта посылки

`PUT /submissions/{submission_id}`

```json
{
  "verdict": "accepted",
  "execution_time_ms": 150,
  "memory_used_mb": 2.048
}
```

**Важно:**

- `verdict` должен быть **lowercase**: `"accepted"`, `"wrong_answer"`, `"time_limit"` и т.д.
- `memory_used_mb` — это **Decimal** (мегабайты), не kilобайты
- Допустимые вердикты: `pending`, `accepted`, `wrong_answer`, `time_limit`, `memory_limit`, `runtime_error`, `compilation_error`

`PUT /submissions/{submission_id}`

---

## ❌ НЕГАТИВНЫЕ ТЕСТЫ (должны вернуть 400/409, НЕ 500)

### 1. Дубликат username

`POST /users/` (повторите с тем же username)

```json
{
  "username": "new_participant_1",
  "email": "different_email@example.com",
  "full_name": "Another User",
  "role": "participant"
}
```

**Ожидаемый результат:** `409 Conflict` с сообщением про дубликат

### 2. Дубликат email

`POST /users/`

```json
{
  "username": "different_username",
  "email": "participant1@example.com",
  "full_name": "Another User",
  "role": "participant"
}
```

**Ожидаемый результат:** `409 Conflict`

### 3. Несуществующий created_by

`POST /contests/`

```json
{
  "title": "Invalid Contest",
  "description": "Test",
  "contest_type": "Codeforces",
  "status": "upcoming",
  "start_time": "2025-12-30T14:00:00",
  "duration_minutes": 120,
  "created_by": 999999
}
```

**Ожидаемый результат:** `400 Bad Request` с сообщением про FK

### 4. Несуществующий author_id

`POST /problems/`

```json
{
  "title": "Invalid Problem",
  "description": "Test",
  "difficulty": "easy",
  "time_limit_ms": 1000,
  "memory_limit_mb": 256,
  "author_id": 999999
}
```

**Ожидаемый результат:** `400 Bad Request`

### 5. Несуществующий user_id в посылке

`POST /submissions/`

```json
{
  "user_id": 999999,
  "contest_id": 1,
  "problem_id": 1,
  "language": "C++",
  "source_code": "int main() { return 0; }",
  "verdict": "Pending",
  "execution_time_ms": 0,
  "memory_used_kb": 0
}
```

**Ожидаемый результат:** `400 Bad Request`

### 6. Невалидная роль

`POST /users/`

```json
{
  "username": "invalid_role_user",
  "email": "invalid@example.com",
  "full_name": "Test User",
  "role": "super_admin"
}
```

**Ожидаемый результат:** `422 Unprocessable Entity` (валидация Pydantic)

### 7. Невалидный contest_type

`POST /contests/`

```json
{
  "title": "Test Contest",
  "description": "Test",
  "contest_type": "InvalidType",
  "status": "upcoming",
  "start_time": "2025-12-30T14:00:00",
  "duration_minutes": 120,
  "created_by": 1
}
```

**Ожидаемый результат:** `422 Unprocessable Entity`

---

## 📦 BATCH IMPORT ТЕСТЫ

### 1. Успешный batch import

`POST /batch/import`

```json
{
  "entity_type": "users",
  "data": [
    {
      "username": "batch_user_1",
      "email": "batch1@example.com",
      "full_name": "Batch User 1",
      "role": "participant",
      "rating": 1400,
      "country": "Russia"
    },
    {
      "username": "batch_user_2",
      "email": "batch2@example.com",
      "full_name": "Batch User 2",
      "role": "participant",
      "rating": 1600,
      "country": "USA"
    }
  ]
}
```

**Ожидаемый результат:** `200 OK` с `success_count: 2, errors: []`

### 2. Batch import с частичными ошибками

`POST /batch/import`

```json
{
  "entity_type": "users",
  "data": [
    {
      "username": "batch_valid_1",
      "email": "valid1@example.com",
      "full_name": "Valid User 1",
      "role": "participant"
    },
    {
      "username": "batch_user_1",
      "email": "batch1@example.com",
      "full_name": "Duplicate",
      "role": "participant"
    },
    {
      "username": "batch_valid_2",
      "email": "valid2@example.com",
      "full_name": "Valid User 2",
      "role": "participant"
    }
  ]
}
```

**Ожидаемый результат:** `200/207` с `success_count: 2, errors: [...]` (один дубликат)

### 3. Batch import соревнований

`POST /batch/import`

```json
{
  "entity_type": "contests",
  "data": [
    {
      "title": "Batch Contest 1",
      "description": "Test batch contest",
      "contest_type": "Codeforces",
      "status": "upcoming",
      "start_time": "2025-12-28T10:00:00",
      "duration_minutes": 120,
      "created_by": 1
    },
    {
      "title": "Batch Contest 2",
      "description": "Another test",
      "contest_type": "ACM_ICPC",
      "status": "upcoming",
      "start_time": "2025-12-29T10:00:00",
      "duration_minutes": 180,
      "created_by": 1
    }
  ]
}
```

---

## 📊 ANALYTICS ТЕСТЫ

Просто выполните GET-запросы (без тела запроса):

1. `GET /analytics/top-participants` - топ 10 участников по рейтингу
2. `GET /analytics/verdict-stats` - статистика по вердиктам
3. `GET /analytics/user-activity` - активность пользователей
4. `GET /analytics/problem-difficulty` - распределение задач по сложности
5. `GET /analytics/contest-summary?contest_id=1` - сводка по соревнованию
