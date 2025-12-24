-- ================================================
-- ГЕНЕРАЦИЯ ЛОГИЧНЫХ ТЕСТОВЫХ ДАННЫХ
-- ================================================

-- Для работы нужно установить расширение
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Генерируем 100 пользователей
INSERT INTO users (username, email, full_name, role, rating, country) 
SELECT 
    'user_' || i,
    'user' || i || '@example.com',
    'User ' || i,
    CASE 
        WHEN i <= 80 THEN 'participant'
        WHEN i <= 95 THEN 'jury'
        ELSE 'admin'
    END,
    floor(random() * 3000)::integer + 500,
    (ARRAY['Russia', 'USA', 'China', 'India', 'Japan', 'Germany', 'UK', 'France', 'Canada', 'Australia'])
        [1 + floor(random() * 10)]
FROM generate_series(1, 100) i
ON CONFLICT (username) DO NOTHING;

-- Генерируем 50 задач
INSERT INTO problems (title, description, difficulty, time_limit_ms, memory_limit_mb, author_id)
SELECT 
    'Problem ' || i,
    'Problem description for task ' || i || '. Solve this algorithmic challenge.',
    (ARRAY['easy', 'medium', 'hard'])[1 + floor(random() * 3)],
    (ARRAY[1000, 2000, 3000, 5000])[1 + floor(random() * 4)],
    (ARRAY[256, 512, 1024])[1 + floor(random() * 3)],
    81 + floor(random() * 15)::integer  -- jury/admin users
FROM generate_series(1, 50) i;

-- Генерируем тестовые данные для задач (уникальные для каждой задачи)
INSERT INTO testcases (problem_id, input_data, expected_output, is_sample, test_order)
SELECT 
    p.problem_id,
    'Test input for problem ' || p.problem_id || ', case ' || i,
    'Expected output for problem ' || p.problem_id || ', case ' || i,
    i <= 2,
    i
FROM problems p
CROSS JOIN generate_series(1, 5) i;

-- Генерируем контесты с логичными статусами и временем
INSERT INTO contests (title, description, contest_type, status, start_time, duration_minutes, created_by)
SELECT 
    'Contest ' || i,
    'Description for contest ' || i || '. Competitive programming competition.',
    (ARRAY['ACM_ICPC', 'Codeforces', 'IOI'])[1 + floor(random() * 3)],
    CASE 
        WHEN i <= 12 THEN 'finished'
        WHEN i <= 15 THEN 'running'
        ELSE 'upcoming'
    END,
    CASE 
        WHEN i <= 12 THEN CURRENT_TIMESTAMP - (floor(random() * 60 + 10) || ' days')::interval
        WHEN i <= 15 THEN CURRENT_TIMESTAMP - '1 hour'::interval
        ELSE CURRENT_TIMESTAMP + (floor(random() * 30 + 1) || ' days')::interval
    END,
    (ARRAY[120, 180, 240, 300])[1 + floor(random() * 4)],
    81 + floor(random() * 15)::integer  -- jury/admin users
FROM generate_series(1, 20) i;

-- Генерируем связи между контестами и задачами (4-8 задач на контест)
INSERT INTO contest_problems (contest_id, problem_id, problem_order, max_score)
SELECT 
    c.contest_id,
    p.problem_id,
    row_number() OVER (PARTITION BY c.contest_id ORDER BY p.problem_id),
    CASE 
        WHEN random() < 0.3 THEN 100
        WHEN random() < 0.7 THEN 200
        ELSE 300
    END
FROM contests c
CROSS JOIN problems p
WHERE p.problem_id BETWEEN 
    (c.contest_id - 1) * 2 + 1 AND 
    (c.contest_id - 1) * 2 + 8
ON CONFLICT DO NOTHING;

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

-- Связываем задачи с тегами (1-3 тега на задачу)
INSERT INTO problem_tags (problem_id, tag_id)
SELECT DISTINCT
    p.problem_id,
    t.tag_id
FROM problems p
CROSS JOIN tags t
WHERE random() < 0.3
ON CONFLICT DO NOTHING;

-- Генерируем реалистичные посылки
DO $$
DECLARE
    rec RECORD;
    participant_rec RECORD;
    verdict TEXT;
    exec_time INTEGER;
    score_val INTEGER;
    submissions_per_user INTEGER;
    contest_end TIMESTAMP;
BEGIN
    -- Для каждого завершенного и текущего контеста
    FOR rec IN 
        SELECT c.contest_id, c.start_time, c.duration_minutes, c.status
        FROM contests c
        WHERE c.status IN ('finished', 'running')
    LOOP
        contest_end := rec.start_time + (rec.duration_minutes || ' minutes')::interval;
        
        -- Выбираем участников (30-70% от всех)
        FOR participant_rec IN 
            SELECT user_id 
            FROM users 
            WHERE role = 'participant' 
            AND random() < 0.5
            ORDER BY random()
            LIMIT 40
        LOOP
            submissions_per_user := 3 + floor(random() * 15)::INTEGER;
            
            -- Генерируем посылки для каждого участника
            FOR i IN 1..submissions_per_user LOOP
                -- Выбираем случайную задачу из контеста
                WITH contest_problem AS (
                    SELECT problem_id, max_score 
                    FROM contest_problems 
                    WHERE contest_id = rec.contest_id 
                    ORDER BY random() 
                    LIMIT 1
                )
                SELECT 
                    CASE 
                        WHEN random() < 0.25 THEN 'accepted'
                        WHEN random() < 0.65 THEN 'wrong_answer'
                        WHEN random() < 0.85 THEN 'time_limit'
                        WHEN random() < 0.95 THEN 'runtime_error'
                        ELSE 'memory_limit'
                    END,
                    floor(random() * 4000 + 100)::INTEGER,
                    cp.max_score
                INTO verdict, exec_time, score_val
                FROM contest_problem cp;
                
                -- Score зависит от вердикта
                IF verdict != 'accepted' THEN
                    score_val := 0;
                END IF;
                
                INSERT INTO submissions (
                    contest_id, problem_id, user_id, source_code, 
                    language, verdict, execution_time_ms, memory_used_mb, 
                    score, submitted_at
                )
                SELECT 
                    rec.contest_id,
                    cp.problem_id,
                    participant_rec.user_id,
                    'source_code_' || gen_random_uuid(),
                    (ARRAY['C++', 'Python', 'Java', 'C'])[1 + floor(random() * 4)],
                    verdict,
                    exec_time,
                    (random() * 400 + 50)::numeric(10,2),
                    score_val,
                    rec.start_time + (floor(random() * rec.duration_minutes) || ' minutes')::interval
                FROM contest_problems cp
                WHERE cp.contest_id = rec.contest_id
                ORDER BY random()
                LIMIT 1;
            END LOOP;
        END LOOP;
    END LOOP;
END $$;

-- Генерируем standings на основе реальных посылок
INSERT INTO standings (contest_id, user_id, total_score, problems_solved, penalty_time)
SELECT 
    s.contest_id,
    s.user_id,
    COALESCE(SUM(DISTINCT 
        CASE 
            WHEN s.verdict = 'accepted' 
            THEN (SELECT MAX(score) FROM submissions s2 
                  WHERE s2.contest_id = s.contest_id 
                  AND s2.user_id = s.user_id 
                  AND s2.problem_id = s.problem_id)
            ELSE 0 
        END
    ), 0)::INTEGER as total_score,
    COUNT(DISTINCT CASE WHEN s.verdict = 'accepted' THEN s.problem_id END)::INTEGER as problems_solved,
    COALESCE(SUM(EXTRACT(EPOCH FROM (s.submitted_at - c.start_time))::INTEGER / 60), 0)::INTEGER as penalty_time
FROM submissions s
JOIN contests c ON s.contest_id = c.contest_id
WHERE c.status IN ('finished', 'running')
GROUP BY s.contest_id, s.user_id
ON CONFLICT (contest_id, user_id) DO NOTHING;