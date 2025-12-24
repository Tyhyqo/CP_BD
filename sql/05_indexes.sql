-- ================================================
-- ИНДЕКСЫ ДЛЯ ОПТИМИЗАЦИИ ЗАПРОСОВ
-- ================================================

-- Индексы для таблицы Users
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_rating ON users(rating DESC);
CREATE INDEX idx_users_country ON users(country);

-- Индексы для таблицы Contests
CREATE INDEX idx_contests_status ON contests(status);
CREATE INDEX idx_contests_start_time ON contests(start_time);
CREATE INDEX idx_contests_type ON contests(contest_type);
CREATE INDEX idx_contests_created_by ON contests(created_by);

-- Индексы для таблицы Problems
CREATE INDEX idx_problems_difficulty ON problems(difficulty);
CREATE INDEX idx_problems_author ON problems(author_id);

-- Индексы для таблицы Submissions
CREATE INDEX idx_submissions_user ON submissions(user_id);
CREATE INDEX idx_submissions_contest ON submissions(contest_id);
CREATE INDEX idx_submissions_problem ON submissions(problem_id);
CREATE INDEX idx_submissions_verdict ON submissions(verdict);
CREATE INDEX idx_submissions_submitted_at ON submissions(submitted_at DESC);
-- Композитный индекс для частых JOIN'ов
CREATE INDEX idx_submissions_contest_user ON submissions(contest_id, user_id);
CREATE INDEX idx_submissions_problem_verdict ON submissions(problem_id, verdict);

-- Индексы для таблицы Standings
CREATE INDEX idx_standings_contest ON standings(contest_id);
CREATE INDEX idx_standings_user ON standings(user_id);
CREATE INDEX idx_standings_rank ON standings(contest_id, rank);
CREATE INDEX idx_standings_score ON standings(total_score DESC);

-- Индексы для таблицы Testcases
CREATE INDEX idx_testcases_problem ON testcases(problem_id);

-- Индексы для таблицы Contest_Problems
CREATE INDEX idx_contest_problems_contest ON contest_problems(contest_id);
CREATE INDEX idx_contest_problems_problem ON contest_problems(problem_id);

-- Индексы для таблицы Tags
CREATE INDEX idx_tags_name ON tags(tag_name);

-- Индексы для таблицы Audit_Log
CREATE INDEX idx_audit_table ON audit_log(table_name);
CREATE INDEX idx_audit_operation ON audit_log(operation);
CREATE INDEX idx_audit_changed_at ON audit_log(changed_at DESC);
CREATE INDEX idx_audit_record ON audit_log(table_name, record_id);
