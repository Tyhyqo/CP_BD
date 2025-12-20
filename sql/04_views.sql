-- ================================================
-- ПРЕДСТАВЛЕНИЯ (VIEWS)
-- ================================================

-- VIEW 1: Турнирная таблица с детальной информацией
CREATE OR REPLACE VIEW v_contest_standings AS
SELECT 
    s.standing_id,
    c.contest_id,
    c.title as contest_title,
    u.user_id,
    u.username,
    u.full_name,
    u.country,
    s.total_score,
    s.problems_solved,
    s.penalty_time,
    s.rank,
    s.last_updated
FROM standings s
INNER JOIN contests c ON s.contest_id = c.contest_id
INNER JOIN users u ON s.user_id = u.user_id
ORDER BY c.contest_id, s.rank;

COMMENT ON VIEW v_contest_standings IS 'Детальная турнирная таблица со всеми контестами';

-- VIEW 2: Статистика пользователей
CREATE OR REPLACE VIEW v_user_statistics AS
SELECT 
    u.user_id,
    u.username,
    u.full_name,
    u.email,
    u.role,
    u.rating,
    u.country,
    COUNT(DISTINCT s.submission_id) as total_submissions,
    COUNT(DISTINCT CASE WHEN s.verdict = 'accepted' THEN s.problem_id END) as unique_problems_solved,
    COUNT(CASE WHEN s.verdict = 'accepted' THEN 1 END) as accepted_count,
    CASE 
        WHEN COUNT(s.submission_id) > 0 
        THEN ROUND((COUNT(CASE WHEN s.verdict = 'accepted' THEN 1 END)::DECIMAL / COUNT(s.submission_id) * 100), 2)
        ELSE 0 
    END as success_rate,
    COUNT(DISTINCT s.contest_id) as contests_participated,
    AVG(CASE WHEN s.verdict = 'accepted' THEN s.execution_time_ms END)::INTEGER as avg_execution_time_ms,
    u.registration_date
FROM users u
LEFT JOIN submissions s ON u.user_id = s.user_id
WHERE u.role = 'participant'
GROUP BY u.user_id, u.username, u.full_name, u.email, u.role, u.rating, u.country, u.registration_date
ORDER BY u.rating DESC;

COMMENT ON VIEW v_user_statistics IS 'Агрегированная статистика по пользователям-участникам';

-- VIEW 3: Статистика по задачам
CREATE OR REPLACE VIEW v_problem_statistics AS
SELECT 
    p.problem_id,
    p.title,
    p.difficulty,
    p.time_limit_ms,
    p.memory_limit_mb,
    u.username as author_name,
    COUNT(DISTINCT s.submission_id) as total_submissions,
    COUNT(DISTINCT s.user_id) as unique_users_attempted,
    COUNT(DISTINCT CASE WHEN s.verdict = 'accepted' THEN s.user_id END) as unique_users_solved,
    COUNT(CASE WHEN s.verdict = 'accepted' THEN 1 END) as accepted_count,
    CASE 
        WHEN COUNT(s.submission_id) > 0 
        THEN ROUND((COUNT(CASE WHEN s.verdict = 'accepted' THEN 1 END)::DECIMAL / COUNT(s.submission_id) * 100), 2)
        ELSE 0 
    END as acceptance_rate,
    AVG(CASE WHEN s.verdict = 'accepted' THEN s.execution_time_ms END)::INTEGER as avg_execution_time_ms,
    MIN(CASE WHEN s.verdict = 'accepted' THEN s.execution_time_ms END) as best_execution_time_ms,
    STRING_AGG(DISTINCT t.tag_name, ', ' ORDER BY t.tag_name) as tags,
    p.created_at
FROM problems p
INNER JOIN users u ON p.author_id = u.user_id
LEFT JOIN submissions s ON p.problem_id = s.problem_id
LEFT JOIN problem_tags pt ON p.problem_id = pt.problem_id
LEFT JOIN tags t ON pt.tag_id = t.tag_id
GROUP BY p.problem_id, p.title, p.difficulty, p.time_limit_ms, p.memory_limit_mb, u.username, p.created_at
ORDER BY p.problem_id;

COMMENT ON VIEW v_problem_statistics IS 'Детальная статистика по задачам с тегами и метриками';

-- VIEW 4: Активность по языкам программирования
CREATE OR REPLACE VIEW v_language_statistics AS
SELECT 
    s.language,
    COUNT(s.submission_id) as total_submissions,
    COUNT(DISTINCT s.user_id) as unique_users,
    COUNT(CASE WHEN s.verdict = 'accepted' THEN 1 END) as accepted_count,
    ROUND((COUNT(CASE WHEN s.verdict = 'accepted' THEN 1 END)::DECIMAL / COUNT(s.submission_id) * 100), 2) as acceptance_rate,
    AVG(CASE WHEN s.verdict = 'accepted' THEN s.execution_time_ms END)::INTEGER as avg_execution_time_ms,
    AVG(CASE WHEN s.verdict = 'accepted' THEN s.memory_used_mb END)::DECIMAL(10,2) as avg_memory_mb
FROM submissions s
GROUP BY s.language
ORDER BY total_submissions DESC;

COMMENT ON VIEW v_language_statistics IS 'Статистика использования языков программирования';

-- VIEW 5: История вердиктов
CREATE OR REPLACE VIEW v_verdict_distribution AS
SELECT 
    s.verdict,
    COUNT(s.submission_id) as count,
    ROUND((COUNT(s.submission_id)::DECIMAL / (SELECT COUNT(*) FROM submissions) * 100), 2) as percentage
FROM submissions s
GROUP BY s.verdict
ORDER BY count DESC;

COMMENT ON VIEW v_verdict_distribution IS 'Распределение вердиктов по посылкам';
