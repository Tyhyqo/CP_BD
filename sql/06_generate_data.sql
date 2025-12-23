-- ================================================
-- ГЕНЕРАЦИЯ БОЛЬШОГО КОЛИЧЕСТВА СЛУЧАЙНЫХ ДАННЫХ
-- ================================================

-- Для работы нужно установить расширение
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Генерируем 100 пользователей
INSERT INTO users (username, email, full_name, role, rating, country) 
SELECT 
    'user_' || generate_series(1, 100),
    'user' || generate_series(1, 100) || '@example.com',
    'User ' || generate_series(1, 100),
    (ARRAY['participant', 'participant', 'participant', 'jury', 'admin'])
        [floor(random() * 5) + 1],
    floor(random() * 5000)::integer,
    (ARRAY['Russia', 'USA', 'China', 'India', 'Japan', 'Germany', 'UK', 'France', 'Canada', 'Australia'])
        [floor(random() * 10) + 1]
ON CONFLICT (username) DO NOTHING;

-- Генерируем 20 контестов
INSERT INTO contests (title, description, contest_type, status, start_time, duration_minutes, created_by)
SELECT 
    'Contest ' || generate_series(1, 20),
    'Description for contest ' || generate_series(1, 20),
    (ARRAY['ACM_ICPC', 'Codeforces', 'IOI'])
        [floor(random() * 3) + 1],
    (ARRAY['upcoming', 'running', 'finished'])
        [floor(random() * 3) + 1],
    CURRENT_TIMESTAMP + (floor(random() * 60) || ' days')::interval,
    (ARRAY[120, 180, 240, 300, 360])[floor(random() * 5) + 1],
    floor(random() * 10)::integer + 1
WHERE EXISTS (SELECT 1 FROM users);

-- Генерируем 50 задач
INSERT INTO problems (title, description, difficulty, time_limit_ms, memory_limit_mb, author_id)
SELECT 
    'Problem ' || generate_series(1, 50),
    'Problem description ' || generate_series(1, 50),
    (ARRAY['easy', 'medium', 'hard'])[floor(random() * 3) + 1],
    (ARRAY[1000, 2000, 3000, 5000])[floor(random() * 4) + 1],
    (ARRAY[256, 512, 1024])[floor(random() * 3) + 1],
    floor(random() * 10)::integer + 1
WHERE EXISTS (SELECT 1 FROM users);

-- Генерируем связи между контестами и задачами
INSERT INTO contest_problems (contest_id, problem_id, problem_order, max_score)
SELECT 
    c.contest_id,
    p.problem_id,
    row_number() OVER (PARTITION BY c.contest_id ORDER BY RANDOM()),
    (ARRAY[100, 150, 200, 250, 300])[floor(random() * 5) + 1]
FROM contests c
CROSS JOIN problems p
WHERE random() < 0.3
ON CONFLICT DO NOTHING;

-- Генерируем тестовые данные для задач
INSERT INTO testcases (problem_id, input_data, expected_output, is_sample, test_order)
SELECT 
    p.problem_id,
    'input_' || generate_series(1, 5),
    'expected_output_' || generate_series(1, 5),
    generate_series(1, 5) <= 2,
    generate_series(1, 5)
FROM problems p
WHERE EXISTS (SELECT 1 FROM problems);

-- Генерируем 1000 посылок решений
INSERT INTO submissions (contest_id, problem_id, user_id, source_code, language, verdict, execution_time_ms, memory_used_mb, score, submitted_at)
SELECT 
    (SELECT contest_id FROM contests ORDER BY RANDOM() LIMIT 1),
    (SELECT problem_id FROM problems ORDER BY RANDOM() LIMIT 1),
    (SELECT user_id FROM users WHERE role = 'participant' ORDER BY RANDOM() LIMIT 1),
    'source_code_' || generate_series(1, 1000),
    (ARRAY['C++', 'Python', 'Java', 'C'])[floor(random() * 4) + 1],
    (ARRAY['pending', 'accepted', 'wrong_answer', 'time_limit', 'memory_limit', 'runtime_error'])
        [floor(random() * 6) + 1],
    floor(random() * 5000)::integer,
    (random() * 500)::numeric(10,2),
    CASE 
        WHEN random() < 0.3 THEN (ARRAY[100, 150, 200, 250])[floor(random() * 4) + 1]
        ELSE 0 
    END,
    CURRENT_TIMESTAMP - (floor(random() * 90) || ' days')::interval
WHERE EXISTS (SELECT 1 FROM contests);

-- Генерируем записи турнирной таблицы
INSERT INTO standings (contest_id, user_id, total_score, problems_solved, penalty_time)
SELECT DISTINCT
    c.contest_id,
    u.user_id,
    floor(random() * 1000)::integer,
    floor(random() * 10)::integer,
    floor(random() * 500)::integer
FROM contests c
CROSS JOIN users u
WHERE u.role = 'participant' AND random() < 0.7
ON CONFLICT (contest_id, user_id) DO NOTHING;

-- Генерируем теги
INSERT INTO tags (tag_name, description)
VALUES 
    ('dynamic-programming', 'Dynamic Programming'),
    ('graphs', 'Graph Theory'),
    ('greedy', 'Greedy Algorithms'),
    ('trees', 'Tree Data Structures'),
    ('sorting', 'Sorting Algorithms'),
    ('binary-search', 'Binary Search'),
    ('arrays', 'Array Manipulation'),
    ('strings', 'String Processing'),
    ('math', 'Mathematical Problems'),
    ('number-theory', 'Number Theory')
ON CONFLICT (tag_name) DO NOTHING;

-- Связываем задачи с тегами
INSERT INTO problem_tags (problem_id, tag_id)
SELECT 
    p.problem_id,
    (SELECT tag_id FROM tags ORDER BY RANDOM() LIMIT 1)
FROM problems p
WHERE random() < 0.6
ON CONFLICT DO NOTHING;