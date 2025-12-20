-- ================================================
-- SQL ФУНКЦИИ
-- ================================================

-- ================================================
-- СКАЛЯРНЫЕ ФУНКЦИИ
-- ================================================

-- Функция: Расчет процента решенных задач пользователем
CREATE OR REPLACE FUNCTION get_user_success_rate(p_user_id INTEGER)
RETURNS DECIMAL(5,2) AS $$
DECLARE
    total_submissions INTEGER;
    accepted_submissions INTEGER;
BEGIN
    SELECT COUNT(*) INTO total_submissions
    FROM submissions
    WHERE user_id = p_user_id;

    IF total_submissions = 0 THEN
        RETURN 0;
    END IF;

    SELECT COUNT(*) INTO accepted_submissions
    FROM submissions
    WHERE user_id = p_user_id AND verdict = 'accepted';

    RETURN (accepted_submissions::DECIMAL / total_submissions * 100);
END;
$$ LANGUAGE plpgsql;

-- Функция: Расчет сложности задачи по статистике решений
CREATE OR REPLACE FUNCTION calculate_problem_difficulty(p_problem_id INTEGER)
RETURNS VARCHAR(20) AS $$
DECLARE
    acceptance_rate DECIMAL(5,2);
    total_attempts INTEGER;
    accepted_attempts INTEGER;
BEGIN
    SELECT COUNT(*) INTO total_attempts
    FROM submissions
    WHERE problem_id = p_problem_id;

    IF total_attempts < 10 THEN
        RETURN 'not_enough_data';
    END IF;

    SELECT COUNT(*) INTO accepted_attempts
    FROM submissions
    WHERE problem_id = p_problem_id AND verdict = 'accepted';

    acceptance_rate := (accepted_attempts::DECIMAL / total_attempts * 100);

    IF acceptance_rate >= 70 THEN
        RETURN 'easy';
    ELSIF acceptance_rate >= 30 THEN
        RETURN 'medium';
    ELSE
        RETURN 'hard';
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Функция: Получить место пользователя в контесте
CREATE OR REPLACE FUNCTION get_user_contest_rank(p_user_id INTEGER, p_contest_id INTEGER)
RETURNS INTEGER AS $$
DECLARE
    user_rank INTEGER;
BEGIN
    SELECT rank INTO user_rank
    FROM standings
    WHERE user_id = p_user_id AND contest_id = p_contest_id;

    RETURN COALESCE(user_rank, 0);
END;
$$ LANGUAGE plpgsql;

-- Функция: Подсчет общего количества решенных уникальных задач пользователем
CREATE OR REPLACE FUNCTION count_unique_solved_problems(p_user_id INTEGER)
RETURNS INTEGER AS $$
BEGIN
    RETURN (
        SELECT COUNT(DISTINCT problem_id)
        FROM submissions
        WHERE user_id = p_user_id AND verdict = 'accepted'
    );
END;
$$ LANGUAGE plpgsql;

-- ================================================
-- ТАБЛИЧНЫЕ ФУНКЦИИ
-- ================================================

-- Функция: Получить топ пользователей по рейтингу
CREATE OR REPLACE FUNCTION get_top_users(p_limit INTEGER DEFAULT 10)
RETURNS TABLE (
    user_id INTEGER,
    username VARCHAR(50),
    rating INTEGER,
    problems_solved BIGINT,
    success_rate DECIMAL(5,2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        u.user_id,
        u.username,
        u.rating,
        COUNT(DISTINCT CASE WHEN s.verdict = 'accepted' THEN s.problem_id END) as problems_solved,
        CASE 
            WHEN COUNT(s.submission_id) > 0 
            THEN (COUNT(CASE WHEN s.verdict = 'accepted' THEN 1 END)::DECIMAL / COUNT(s.submission_id) * 100)
            ELSE 0 
        END as success_rate
    FROM users u
    LEFT JOIN submissions s ON u.user_id = s.user_id
    WHERE u.role = 'participant'
    GROUP BY u.user_id, u.username, u.rating
    ORDER BY u.rating DESC, problems_solved DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- Функция: Получить статистику по контесту
CREATE OR REPLACE FUNCTION get_contest_statistics(p_contest_id INTEGER)
RETURNS TABLE (
    total_participants BIGINT,
    total_submissions BIGINT,
    avg_score DECIMAL(10,2),
    problems_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(DISTINCT s.user_id) as total_participants,
        COUNT(s.submission_id) as total_submissions,
        AVG(st.total_score) as avg_score,
        COUNT(DISTINCT cp.problem_id) as problems_count
    FROM contests c
    LEFT JOIN submissions s ON c.contest_id = s.contest_id
    LEFT JOIN standings st ON c.contest_id = st.contest_id
    LEFT JOIN contest_problems cp ON c.contest_id = cp.contest_id
    WHERE c.contest_id = p_contest_id
    GROUP BY c.contest_id;
END;
$$ LANGUAGE plpgsql;

-- Функция: Получить детальный отчет по посылкам пользователя в контесте
CREATE OR REPLACE FUNCTION get_user_contest_report(p_user_id INTEGER, p_contest_id INTEGER)
RETURNS TABLE (
    problem_title VARCHAR(200),
    attempts BIGINT,
    accepted BOOLEAN,
    best_time_ms INTEGER,
    score INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.title as problem_title,
        COUNT(s.submission_id) as attempts,
        BOOL_OR(s.verdict = 'accepted') as accepted,
        MIN(s.execution_time_ms) as best_time_ms,
        MAX(s.score) as score
    FROM contest_problems cp
    INNER JOIN problems p ON cp.problem_id = p.problem_id
    LEFT JOIN submissions s ON cp.problem_id = s.problem_id 
        AND s.contest_id = p_contest_id 
        AND s.user_id = p_user_id
    WHERE cp.contest_id = p_contest_id
    GROUP BY p.problem_id, p.title
    ORDER BY cp.problem_order;
END;
$$ LANGUAGE plpgsql;

-- Функция: Получить статистику по задачам
CREATE OR REPLACE FUNCTION get_problem_statistics()
RETURNS TABLE (
    problem_id INTEGER,
    title VARCHAR(200),
    total_submissions BIGINT,
    accepted_submissions BIGINT,
    acceptance_rate DECIMAL(5,2),
    avg_execution_time_ms INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.problem_id,
        p.title,
        COUNT(s.submission_id) as total_submissions,
        COUNT(CASE WHEN s.verdict = 'accepted' THEN 1 END) as accepted_submissions,
        CASE 
            WHEN COUNT(s.submission_id) > 0 
            THEN (COUNT(CASE WHEN s.verdict = 'accepted' THEN 1 END)::DECIMAL / COUNT(s.submission_id) * 100)
            ELSE 0 
        END as acceptance_rate,
        AVG(s.execution_time_ms)::INTEGER as avg_execution_time_ms
    FROM problems p
    LEFT JOIN submissions s ON p.problem_id = s.problem_id
    GROUP BY p.problem_id, p.title
    ORDER BY p.problem_id;
END;
$$ LANGUAGE plpgsql;
