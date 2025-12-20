-- ================================================
-- Курсовая работа: Система управления соревнованиями 
-- по спортивному программированию
-- ================================================

-- Очистка БД
DROP TABLE IF EXISTS audit_log CASCADE;
DROP TABLE IF EXISTS problem_tags CASCADE;
DROP TABLE IF EXISTS tags CASCADE;
DROP TABLE IF EXISTS standings CASCADE;
DROP TABLE IF EXISTS submissions CASCADE;
DROP TABLE IF EXISTS testcases CASCADE;
DROP TABLE IF EXISTS contest_problems CASCADE;
DROP TABLE IF EXISTS problems CASCADE;
DROP TABLE IF EXISTS contests CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- ================================================
-- ТАБЛИЦА 1: Users (Пользователи)
-- ================================================
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    full_name VARCHAR(100) NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('participant', 'jury', 'admin')),
    rating INTEGER DEFAULT 0 CHECK (rating >= 0),
    country VARCHAR(50),
    registration_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

-- ================================================
-- ТАБЛИЦА 2: Contests (Соревнования)
-- ================================================
CREATE TABLE contests (
    contest_id SERIAL PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    contest_type VARCHAR(20) NOT NULL CHECK (contest_type IN ('ACM_ICPC', 'Codeforces', 'IOI')),
    status VARCHAR(20) NOT NULL DEFAULT 'upcoming' CHECK (status IN ('upcoming', 'running', 'finished')),
    start_time TIMESTAMP NOT NULL,
    duration_minutes INTEGER NOT NULL CHECK (duration_minutes > 0),
    created_by INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ================================================
-- ТАБЛИЦА 3: Problems (Задачи)
-- ================================================
CREATE TABLE problems (
    problem_id SERIAL PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    description TEXT NOT NULL,
    difficulty VARCHAR(20) CHECK (difficulty IN ('easy', 'medium', 'hard')),
    time_limit_ms INTEGER NOT NULL DEFAULT 1000 CHECK (time_limit_ms > 0),
    memory_limit_mb INTEGER NOT NULL DEFAULT 256 CHECK (memory_limit_mb > 0),
    author_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ================================================
-- ТАБЛИЦА 4: Contest_Problems (Связь N:M между Contests и Problems)
-- ================================================
CREATE TABLE contest_problems (
    contest_id INTEGER NOT NULL REFERENCES contests(contest_id) ON DELETE CASCADE,
    problem_id INTEGER NOT NULL REFERENCES problems(problem_id) ON DELETE CASCADE,
    problem_order INTEGER NOT NULL CHECK (problem_order > 0),
    max_score INTEGER NOT NULL DEFAULT 100 CHECK (max_score > 0),
    PRIMARY KEY (contest_id, problem_id),
    UNIQUE (contest_id, problem_order)
);

-- ================================================
-- ТАБЛИЦА 5: Testcases (Тестовые данные для задач)
-- ================================================
CREATE TABLE testcases (
    testcase_id SERIAL PRIMARY KEY,
    problem_id INTEGER NOT NULL REFERENCES problems(problem_id) ON DELETE CASCADE,
    input_data TEXT NOT NULL,
    expected_output TEXT NOT NULL,
    is_sample BOOLEAN NOT NULL DEFAULT FALSE,
    test_order INTEGER NOT NULL CHECK (test_order > 0),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (problem_id, test_order)
);

-- ================================================
-- ТАБЛИЦА 6: Submissions (Посылки решений)
-- ================================================
CREATE TABLE submissions (
    submission_id SERIAL PRIMARY KEY,
    contest_id INTEGER NOT NULL REFERENCES contests(contest_id) ON DELETE CASCADE,
    problem_id INTEGER NOT NULL REFERENCES problems(problem_id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    source_code TEXT NOT NULL,
    language VARCHAR(20) NOT NULL CHECK (language IN ('C++', 'Python', 'Java', 'C')),
    verdict VARCHAR(30) DEFAULT 'pending' CHECK (verdict IN 
        ('pending', 'accepted', 'wrong_answer', 'time_limit', 'memory_limit', 
         'runtime_error', 'compilation_error')),
    execution_time_ms INTEGER CHECK (execution_time_ms >= 0),
    memory_used_mb DECIMAL(10,2) CHECK (memory_used_mb >= 0),
    score INTEGER DEFAULT 0 CHECK (score >= 0),
    submitted_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ================================================
-- ТАБЛИЦА 7: Standings (Турнирная таблица)
-- ================================================
CREATE TABLE standings (
    standing_id SERIAL PRIMARY KEY,
    contest_id INTEGER NOT NULL REFERENCES contests(contest_id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    total_score INTEGER NOT NULL DEFAULT 0 CHECK (total_score >= 0),
    problems_solved INTEGER NOT NULL DEFAULT 0 CHECK (problems_solved >= 0),
    penalty_time INTEGER NOT NULL DEFAULT 0 CHECK (penalty_time >= 0),
    rank INTEGER CHECK (rank > 0),
    last_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (contest_id, user_id)
);

-- ================================================
-- ТАБЛИЦА 8: Tags (Теги для задач)
-- ================================================
CREATE TABLE tags (
    tag_id SERIAL PRIMARY KEY,
    tag_name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ================================================
-- ТАБЛИЦА 9: Problem_Tags (Связь N:M между Problems и Tags)
-- ================================================
CREATE TABLE problem_tags (
    problem_id INTEGER NOT NULL REFERENCES problems(problem_id) ON DELETE CASCADE,
    tag_id INTEGER NOT NULL REFERENCES tags(tag_id) ON DELETE CASCADE,
    PRIMARY KEY (problem_id, tag_id)
);

-- ================================================
-- ТАБЛИЦА 10: Audit_Log (Журнал аудита)
-- ================================================
CREATE TABLE audit_log (
    log_id SERIAL PRIMARY KEY,
    table_name VARCHAR(50) NOT NULL,
    operation VARCHAR(10) NOT NULL CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE')),
    record_id INTEGER NOT NULL,
    old_values JSONB,
    new_values JSONB,
    changed_by INTEGER REFERENCES users(user_id) ON DELETE SET NULL,
    changed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Комментарии к таблицам
COMMENT ON TABLE users IS 'Пользователи системы: участники, жюри, администраторы';
COMMENT ON TABLE contests IS 'Соревнования по программированию';
COMMENT ON TABLE problems IS 'Задачи для соревнований';
COMMENT ON TABLE contest_problems IS 'Связь задач с соревнованиями (N:M)';
COMMENT ON TABLE testcases IS 'Тестовые данные для проверки решений';
COMMENT ON TABLE submissions IS 'Посылки решений от участников';
COMMENT ON TABLE standings IS 'Турнирная таблица соревнований';
COMMENT ON TABLE tags IS 'Теги для категоризации задач';
COMMENT ON TABLE problem_tags IS 'Связь задач с тегами (N:M)';
COMMENT ON TABLE audit_log IS 'Журнал всех изменений в БД';
