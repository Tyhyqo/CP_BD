-- ================================================
-- ТРИГГЕРЫ ДЛЯ АУДИТА ИЗМЕНЕНИЙ
-- ================================================

-- Функция для логирования изменений в Users
CREATE OR REPLACE FUNCTION log_users_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'DELETE') THEN
        INSERT INTO audit_log (table_name, operation, record_id, old_values)
        VALUES ('users', 'DELETE', OLD.user_id, row_to_json(OLD)::jsonb);
        RETURN OLD;
    ELSIF (TG_OP = 'UPDATE') THEN
        INSERT INTO audit_log (table_name, operation, record_id, old_values, new_values)
        VALUES ('users', 'UPDATE', NEW.user_id, row_to_json(OLD)::jsonb, row_to_json(NEW)::jsonb);
        RETURN NEW;
    ELSIF (TG_OP = 'INSERT') THEN
        INSERT INTO audit_log (table_name, operation, record_id, new_values)
        VALUES ('users', 'INSERT', NEW.user_id, row_to_json(NEW)::jsonb);
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER users_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON users
FOR EACH ROW EXECUTE FUNCTION log_users_changes();

-- Функция для логирования изменений в Contests
CREATE OR REPLACE FUNCTION log_contests_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'DELETE') THEN
        INSERT INTO audit_log (table_name, operation, record_id, old_values)
        VALUES ('contests', 'DELETE', OLD.contest_id, row_to_json(OLD)::jsonb);
        RETURN OLD;
    ELSIF (TG_OP = 'UPDATE') THEN
        INSERT INTO audit_log (table_name, operation, record_id, old_values, new_values)
        VALUES ('contests', 'UPDATE', NEW.contest_id, row_to_json(OLD)::jsonb, row_to_json(NEW)::jsonb);
        RETURN NEW;
    ELSIF (TG_OP = 'INSERT') THEN
        INSERT INTO audit_log (table_name, operation, record_id, new_values)
        VALUES ('contests', 'INSERT', NEW.contest_id, row_to_json(NEW)::jsonb);
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER contests_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON contests
FOR EACH ROW EXECUTE FUNCTION log_contests_changes();

-- Функция для логирования изменений в Submissions
CREATE OR REPLACE FUNCTION log_submissions_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'DELETE') THEN
        INSERT INTO audit_log (table_name, operation, record_id, old_values)
        VALUES ('submissions', 'DELETE', OLD.submission_id, row_to_json(OLD)::jsonb);
        RETURN OLD;
    ELSIF (TG_OP = 'UPDATE') THEN
        INSERT INTO audit_log (table_name, operation, record_id, old_values, new_values)
        VALUES ('submissions', 'UPDATE', NEW.submission_id, row_to_json(OLD)::jsonb, row_to_json(NEW)::jsonb);
        RETURN NEW;
    ELSIF (TG_OP = 'INSERT') THEN
        INSERT INTO audit_log (table_name, operation, record_id, new_values)
        VALUES ('submissions', 'INSERT', NEW.submission_id, row_to_json(NEW)::jsonb);
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER submissions_audit_trigger
AFTER INSERT OR UPDATE OR DELETE ON submissions
FOR EACH ROW EXECUTE FUNCTION log_submissions_changes();

-- ================================================
-- ТРИГГЕР ДЛЯ АВТООБНОВЛЕНИЯ ТУРНИРНОЙ ТАБЛИЦЫ
-- ================================================

-- Функция для обновления standings при изменении submission
CREATE OR REPLACE FUNCTION update_standings()
RETURNS TRIGGER AS $$
DECLARE
    v_total_score INTEGER;
    v_problems_solved INTEGER;
    v_penalty INTEGER;
    v_rank INTEGER;
BEGIN
    -- Обновляем standings при INSERT или UPDATE submission с вердиктом 'accepted'
    IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') AND NEW.verdict = 'accepted' THEN
        -- Вычисляем total_score для пользователя в контесте
        SELECT COALESCE(SUM(DISTINCT s.score), 0)
        INTO v_total_score
        FROM submissions s
        WHERE s.contest_id = NEW.contest_id 
          AND s.user_id = NEW.user_id 
          AND s.verdict = 'accepted';

        -- Вычисляем количество решенных задач
        SELECT COUNT(DISTINCT s.problem_id)
        INTO v_problems_solved
        FROM submissions s
        WHERE s.contest_id = NEW.contest_id 
          AND s.user_id = NEW.user_id 
          AND s.verdict = 'accepted';

        -- Вычисляем penalty time (сумма времени до первого accepted для каждой задачи)
        SELECT COALESCE(SUM(EXTRACT(EPOCH FROM (
            SELECT MIN(s2.submitted_at) 
            FROM submissions s2 
            WHERE s2.contest_id = NEW.contest_id 
              AND s2.user_id = NEW.user_id 
              AND s2.problem_id = s1.problem_id 
              AND s2.verdict = 'accepted'
        )) / 60), 0)::INTEGER
        INTO v_penalty
        FROM (
            SELECT DISTINCT problem_id 
            FROM submissions 
            WHERE contest_id = NEW.contest_id 
              AND user_id = NEW.user_id 
              AND verdict = 'accepted'
        ) s1;

        -- Обновляем или создаем запись в standings
        INSERT INTO standings (contest_id, user_id, total_score, problems_solved, penalty_time)
        VALUES (NEW.contest_id, NEW.user_id, v_total_score, v_problems_solved, v_penalty)
        ON CONFLICT (contest_id, user_id) 
        DO UPDATE SET 
            total_score = v_total_score,
            problems_solved = v_problems_solved,
            penalty_time = v_penalty,
            last_updated = CURRENT_TIMESTAMP;

        -- Обновляем ранги для всех участников этого контеста
        WITH ranked AS (
            SELECT 
                standing_id,
                ROW_NUMBER() OVER (
                    ORDER BY total_score DESC, penalty_time ASC
                ) as new_rank
            FROM standings
            WHERE contest_id = NEW.contest_id
        )
        UPDATE standings s
        SET rank = r.new_rank
        FROM ranked r
        WHERE s.standing_id = r.standing_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_standings_trigger
AFTER INSERT OR UPDATE ON submissions
FOR EACH ROW EXECUTE FUNCTION update_standings();

-- ================================================
-- ТРИГГЕР ДЛЯ ОБНОВЛЕНИЯ РЕЙТИНГА ПОЛЬЗОВАТЕЛЯ
-- ================================================

-- Функция для обновления рейтинга пользователя после завершения контеста
CREATE OR REPLACE FUNCTION update_user_rating()
RETURNS TRIGGER AS $$
BEGIN
    -- Когда контест завершается, обновляем рейтинги всех участников
    IF (TG_OP = 'UPDATE') AND (OLD.status != 'finished' AND NEW.status = 'finished') THEN
        UPDATE users u
        SET rating = u.rating + COALESCE(s.total_score / 10, 0)
        FROM standings s
        WHERE s.contest_id = NEW.contest_id 
          AND s.user_id = u.user_id
          AND s.total_score > 0;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_user_rating_trigger
AFTER UPDATE ON contests
FOR EACH ROW EXECUTE FUNCTION update_user_rating();
