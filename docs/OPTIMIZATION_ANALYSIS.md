# Анализ и оптимизация запросов

## 📊 Демонстрация EXPLAIN ANALYZE

### Запрос 1: Получение посылок пользователя

#### ДО добавления индекса

```sql
DROP INDEX IF EXISTS idx_submissions_user;

EXPLAIN ANALYZE
SELECT * FROM submissions WHERE user_id = 3;
```

#### ПОСЛЕ добавления индекса

```sql
CREATE INDEX idx_submissions_user ON submissions(user_id);

EXPLAIN ANALYZE
SELECT * FROM submissions WHERE user_id = 3;
```

---

### Запрос 2: Турнирная таблица с сортировкой

#### ДО добавления индекса

```sql
DROP INDEX IF EXISTS idx_standings_rank;

EXPLAIN ANALYZE
SELECT * FROM standings 
WHERE contest_id = 1 
ORDER BY rank;
```

#### ПОСЛЕ добавления композитного индекса

```sql
CREATE INDEX idx_standings_rank ON standings(contest_id, rank);

EXPLAIN ANALYZE
SELECT * FROM standings 
WHERE contest_id = 1 
ORDER BY rank;
```

---

### Запрос 3: Статистика по задачам

#### ДО добавления индексов

```sql
DROP INDEX IF EXISTS idx_submissions_problem;
DROP INDEX IF EXISTS idx_submissions_problem_verdict;

EXPLAIN ANALYZE
SELECT 
    p.problem_id,
    p.title,
    COUNT(s.submission_id) as total_submissions,
    COUNT(CASE WHEN s.verdict = 'accepted' THEN 1 END) as accepted
FROM problems p
LEFT JOIN submissions s ON p.problem_id = s.problem_id
GROUP BY p.problem_id, p.title
ORDER BY p.problem_id;
```

#### ПОСЛЕ добавления индексов

```sql
CREATE INDEX idx_submissions_problem ON submissions(problem_id);
CREATE INDEX idx_submissions_problem_verdict ON submissions(problem_id, verdict);

EXPLAIN ANALYZE
SELECT 
    p.problem_id,
    p.title,
    COUNT(s.submission_id) as total_submissions,
    COUNT(CASE WHEN s.verdict = 'accepted' THEN 1 END) as accepted
FROM problems p
LEFT JOIN submissions s ON p.problem_id = s.problem_id
GROUP BY p.problem_id, p.title
ORDER BY p.problem_id;
```

---

### Запрос 4: Поиск по вердиктам

#### ДО добавления индекса

```sql
DROP INDEX IF EXISTS idx_submissions_verdict;

EXPLAIN ANALYZE
SELECT * FROM submissions 
WHERE verdict = 'accepted' 
ORDER BY submitted_at DESC 
LIMIT 10;
```

#### ПОСЛЕ добавления индексов

```sql
CREATE INDEX idx_submissions_verdict ON submissions(verdict);
CREATE INDEX idx_submissions_submitted_at ON submissions(submitted_at DESC);

EXPLAIN ANALYZE
SELECT * FROM submissions 
WHERE verdict = 'accepted' 
ORDER BY submitted_at DESC 
LIMIT 10;
```

---

## 📝 Скрипт для тестирования производительности

```sql
-- Создать большую таблицу для тестов
CREATE TABLE test_submissions AS 
SELECT 
    generate_series(1, 100000) as submission_id,
    (random() * 1000)::int as user_id,
    (random() * 500)::int as problem_id,
    (ARRAY['pending','accepted','wrong_answer','time_limit'])[floor(random() * 4 + 1)] as verdict
FROM generate_series(1, 100000);

-- БЕЗ индекса
EXPLAIN ANALYZE
SELECT * FROM test_submissions WHERE user_id = 500;

-- С индексом
CREATE INDEX idx_test_user ON test_submissions(user_id);

EXPLAIN ANALYZE
SELECT * FROM test_submissions WHERE user_id = 500;

-- Очистка
DROP TABLE test_submissions;
```
