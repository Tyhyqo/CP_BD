# API Quick Reference

## 🚀 Базовый URL

```
http://localhost:8000
```

## 📚 Swagger Documentation

```
http://localhost:8000/docs
```

---

## 👥 Users API

### Создать пользователя
```http
POST /users/
Content-Type: application/json

{
  "username": "john_doe",
  "email": "john@example.com",
  "full_name": "John Doe",
  "role": "participant",
  "country": "USA",
  "rating": 1500
}
```

### Получить всех пользователей
```http
GET /users/?skip=0&limit=100
```

### Получить пользователя по ID
```http
GET /users/1
```

### Обновить пользователя
```http
PUT /users/1
Content-Type: application/json

{
  "rating": 1600,
  "country": "Canada"
}
```

### Удалить пользователя
```http
DELETE /users/1
```

---

## 🏆 Contests API

### Создать контест
```http
POST /contests/
Content-Type: application/json

{
  "title": "Spring Contest 2025",
  "description": "Annual spring programming competition",
  "contest_type": "Codeforces",
  "start_time": "2025-03-15T10:00:00",
  "duration_minutes": 180,
  "created_by": 1
}
```

### Получить все контесты
```http
GET /contests/?skip=0&limit=100
```

### Получить контест по ID
```http
GET /contests/1
```

### Обновить статус контеста
```http
PUT /contests/1
Content-Type: application/json

{
  "status": "running"
}
```

---

## 📝 Problems API

### Создать задачу
```http
POST /problems/
Content-Type: application/json

{
  "title": "Two Sum",
  "description": "Find two numbers that add up to target",
  "difficulty": "easy",
  "time_limit_ms": 1000,
  "memory_limit_mb": 256,
  "author_id": 2
}
```

### Получить все задачи
```http
GET /problems/?skip=0&limit=100
```

### Получить задачу по ID
```http
GET /problems/1
```

---

## 💻 Submissions API

### Отправить решение
```http
POST /submissions/
Content-Type: application/json

{
  "contest_id": 1,
  "problem_id": 1,
  "user_id": 3,
  "source_code": "def solve():\n    return [0, 1]",
  "language": "Python"
}
```

### Получить все посылки
```http
GET /submissions/?skip=0&limit=100
```

### Обновить вердикт (для жюри)
```http
PUT /submissions/1
Content-Type: application/json

{
  "verdict": "accepted",
  "execution_time_ms": 45,
  "memory_used_mb": 12.5,
  "score": 100
}
```

---

## 📊 Analytics API

### Турнирная таблица (VIEW)
```http
GET /analytics/standings/1
```

**Ответ:**
```json
[
  {
    "standing_id": 1,
    "contest_id": 1,
    "contest_title": "Spring Contest 2025",
    "user_id": 3,
    "username": "tourist",
    "full_name": "Gennady Korotkevich",
    "country": "Belarus",
    "total_score": 400,
    "problems_solved": 4,
    "penalty_time": 60,
    "rank": 1,
    "last_updated": "2025-03-15T12:00:00"
  }
]
```

### Статистика пользователей (VIEW)
```http
GET /analytics/users/statistics/all
```

### Статистика задач (VIEW)
```http
GET /analytics/problems/statistics/all
```

### Статистика языков (VIEW)
```http
GET /analytics/languages/statistics
```

**Ответ:**
```json
[
  {
    "language": "Python",
    "total_submissions": 150,
    "unique_users": 45,
    "accepted_count": 85,
    "acceptance_rate": 56.67,
    "avg_execution_time_ms": 120,
    "avg_memory_mb": 15.8
  },
  {
    "language": "C++",
    "total_submissions": 200,
    "unique_users": 60,
    "accepted_count": 140,
    "acceptance_rate": 70.00,
    "avg_execution_time_ms": 45,
    "avg_memory_mb": 8.5
  }
]
```

### Распределение вердиктов (VIEW)
```http
GET /analytics/verdicts/distribution
```

### Процент решенных задач (Scalar Function)
```http
GET /analytics/users/3/success-rate
```

**Ответ:**
```json
{
  "user_id": 3,
  "success_rate": 85.5
}
```

### Количество решенных задач (Scalar Function)
```http
GET /analytics/users/3/solved-count
```

### Место в контесте (Scalar Function)
```http
GET /analytics/users/3/contest/1/rank
```

**Ответ:**
```json
{
  "user_id": 3,
  "contest_id": 1,
  "rank": 1
}
```

### Расчетная сложность задачи (Scalar Function)
```http
GET /analytics/problems/1/calculated-difficulty
```

### Топ пользователей (Table Function)
```http
GET /analytics/users/top?limit=10
```

**Ответ:**
```json
[
  {
    "user_id": 3,
    "username": "tourist",
    "rating": 3800,
    "problems_solved": 250,
    "success_rate": 85.5
  },
  {
    "user_id": 4,
    "username": "petr",
    "rating": 3600,
    "problems_solved": 230,
    "success_rate": 82.3
  }
]
```

### Статистика контеста (Table Function)
```http
GET /analytics/contests/1/statistics
```

**Ответ:**
```json
{
  "total_participants": 45,
  "total_submissions": 280,
  "avg_score": 245.5,
  "problems_count": 4
}
```

### Отчет пользователя по контесту (Table Function)
```http
GET /analytics/users/3/contest/1/report
```

**Ответ:**
```json
[
  {
    "problem_title": "Two Sum",
    "attempts": 1,
    "accepted": true,
    "best_time_ms": 45,
    "score": 100
  },
  {
    "problem_title": "Binary Search",
    "attempts": 2,
    "accepted": true,
    "best_time_ms": 38,
    "score": 100
  }
]
```

### Детальная статистика задач (Table Function)
```http
GET /analytics/problems/statistics/detailed
```

### Турнирная таблица с деталями (Complex Query)
```http
GET /analytics/contests/1/leaderboard
```

**Ответ:**
```json
[
  {
    "rank": 1,
    "user_id": 3,
    "username": "tourist",
    "full_name": "Gennady Korotkevich",
    "country": "Belarus",
    "rating": 3800,
    "problems_solved": 4,
    "total_score": 400
  }
]
```

### Журнал аудита
```http
GET /analytics/audit-log?table_name=users&limit=50
```

**Ответ:**
```json
[
  {
    "log_id": 123,
    "table_name": "users",
    "operation": "INSERT",
    "record_id": 10,
    "old_values": null,
    "new_values": {
      "user_id": 10,
      "username": "newuser",
      "email": "new@example.com",
      "role": "participant"
    },
    "changed_by": 1,
    "changed_at": "2025-12-21T15:30:00"
  }
]
```

---

## 📦 Batch Operations API

### Массовая загрузка пользователей
```http
POST /batch/import
Content-Type: application/json

{
  "entity_type": "users",
  "data": [
    {
      "username": "user1",
      "email": "user1@test.com",
      "full_name": "User One",
      "role": "participant",
      "country": "Russia"
    },
    {
      "username": "user2",
      "email": "user2@test.com",
      "full_name": "User Two",
      "role": "participant",
      "country": "USA"
    },
    {
      "username": "user1",
      "email": "duplicate@test.com",
      "full_name": "Duplicate",
      "role": "participant"
    }
  ]
}
```

**Ответ:**
```json
{
  "total": 3,
  "success": 2,
  "failed": 1,
  "errors": [
    {
      "row": 3,
      "error": "Row 3: Integrity error - duplicate key value violates unique constraint \"users_username_key\"",
      "data": {
        "username": "user1",
        "email": "duplicate@test.com",
        "full_name": "Duplicate",
        "role": "participant"
      }
    }
  ]
}
```

### Массовая загрузка контестов
```http
POST /batch/import
Content-Type: application/json

{
  "entity_type": "contests",
  "data": [
    {
      "title": "Contest 1",
      "description": "First contest",
      "contest_type": "Codeforces",
      "start_time": "2025-12-25T10:00:00",
      "duration_minutes": 120,
      "created_by": 1
    }
  ]
}
```

### Массовая загрузка задач
```http
POST /batch/import
Content-Type: application/json

{
  "entity_type": "problems",
  "data": [
    {
      "title": "Problem A",
      "description": "Solve problem A",
      "difficulty": "easy",
      "time_limit_ms": 1000,
      "memory_limit_mb": 256,
      "author_id": 2
    }
  ]
}
```

---

## 🔍 Примеры использования с curl

### Linux/Mac/Git Bash:

```bash
# Создать пользователя
curl -X POST "http://localhost:8000/users/" \
  -H "Content-Type: application/json" \
  -d '{"username":"test","email":"test@test.com","full_name":"Test User","role":"participant"}'

# Получить топ-10
curl "http://localhost:8000/analytics/users/top?limit=10"

# Турнирная таблица
curl "http://localhost:8000/analytics/standings/1"
```

### PowerShell:

```powershell
# Создать пользователя
Invoke-RestMethod -Uri "http://localhost:8000/users/" `
  -Method POST `
  -ContentType "application/json" `
  -Body '{"username":"test","email":"test@test.com","full_name":"Test User","role":"participant"}'

# Получить топ-10
Invoke-RestMethod -Uri "http://localhost:8000/analytics/users/top?limit=10"

# Турнирная таблица
Invoke-RestMethod -Uri "http://localhost:8000/analytics/standings/1"
```

---

## 📋 Допустимые значения для полей

### role (пользователь)
- `participant` - участник
- `jury` - жюри
- `admin` - администратор

### contest_type (тип контеста)
- `ACM_ICPC`
- `Codeforces`
- `IOI`

### status (статус контеста)
- `upcoming` - предстоящий
- `running` - идет
- `finished` - завершен

### difficulty (сложность задачи)
- `easy` - легкая
- `medium` - средняя
- `hard` - сложная

### language (язык программирования)
- `C++`
- `Python`
- `Java`
- `C`

### verdict (вердикт)
- `pending` - ожидает проверки
- `accepted` - принято
- `wrong_answer` - неправильный ответ
- `time_limit` - превышено время
- `memory_limit` - превышена память
- `runtime_error` - ошибка выполнения
- `compilation_error` - ошибка компиляции

### entity_type (для batch-import)
- `users`
- `contests`
- `problems`
- `submissions`

---

## ❌ Примеры ошибок

### 404 Not Found
```json
{
  "detail": "User not found"
}
```

### 422 Validation Error
```json
{
  "detail": [
    {
      "loc": ["body", "email"],
      "msg": "value is not a valid email address",
      "type": "value_error.email"
    }
  ]
}
```

### 500 Internal Server Error
```json
{
  "detail": "Internal server error"
}
```

---

## 🎯 Health Check

```http
GET /health
```

**Ответ:**
```json
{
  "status": "healthy",
  "service": "cp-contest-api"
}
```

---

## 📖 Полная документация

Для интерактивного тестирования всех endpoints используйте Swagger UI:

**http://localhost:8000/docs**

Или ReDoc для более читаемой документации:

**http://localhost:8000/redoc**
