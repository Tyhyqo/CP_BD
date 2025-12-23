"""
Analytics and complex queries using raw SQL
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import text
from typing import List, Dict, Any
from app.database import get_db

router = APIRouter(prefix="/analytics", tags=["analytics"])


@router.get("/top-participants")
def get_top_participants(limit: int = 10, db: Session = Depends(get_db)):
    """Get top participants by rating"""
    query = text("""
        SELECT user_id, username, full_name, country, rating, 
               registration_date, is_active
        FROM users 
        WHERE role = 'participant' 
        ORDER BY rating DESC 
        LIMIT :limit
    """)
    result = db.execute(query, {"limit": limit})
    return [dict(row._mapping) for row in result]


@router.get("/verdict-stats")
def get_verdict_statistics(db: Session = Depends(get_db)):
    """Get statistics by verdict type"""
    query = text("""
        SELECT verdict, COUNT(*) as count 
        FROM submissions 
        GROUP BY verdict 
        ORDER BY count DESC
    """)
    result = db.execute(query)
    return [dict(row._mapping) for row in result]


@router.get("/user-activity")
def get_user_activity(limit: int = 20, db: Session = Depends(get_db)):
    """Get user activity statistics"""
    query = text("""
        SELECT u.user_id, u.username, 
               COUNT(s.submission_id) as total_submissions,
               COUNT(DISTINCT s.contest_id) as contests_participated,
               SUM(CASE WHEN s.verdict = 'accepted' THEN 1 ELSE 0 END) as accepted_count
        FROM users u
        LEFT JOIN submissions s ON u.user_id = s.user_id
        WHERE u.role = 'participant'
        GROUP BY u.user_id, u.username
        ORDER BY total_submissions DESC
        LIMIT :limit
    """)
    result = db.execute(query, {"limit": limit})
    return [dict(row._mapping) for row in result]


@router.get("/problem-difficulty")
def get_problem_difficulty_stats(db: Session = Depends(get_db)):
    """Get problem distribution by difficulty"""
    query = text("""
        SELECT difficulty, COUNT(*) as count 
        FROM problems 
        GROUP BY difficulty 
        ORDER BY 
            CASE difficulty 
                WHEN 'easy' THEN 1 
                WHEN 'medium' THEN 2 
                WHEN 'hard' THEN 3 
            END
    """)
    result = db.execute(query)
    return [dict(row._mapping) for row in result]


@router.get("/contest-summary")
def get_contest_summary(contest_id: int, db: Session = Depends(get_db)):
    """Get summary statistics for a contest"""
    query = text("""
        SELECT 
            c.contest_id,
            c.title,
            c.status,
            COUNT(DISTINCT s.user_id) as participants_count,
            COUNT(s.submission_id) as total_submissions,
            COUNT(DISTINCT s.problem_id) as problems_count,
            AVG(CASE WHEN s.verdict = 'accepted' THEN s.execution_time_ms END) as avg_execution_time
        FROM contests c
        LEFT JOIN submissions s ON c.contest_id = s.contest_id
        WHERE c.contest_id = :contest_id
        GROUP BY c.contest_id, c.title, c.status
    """)
    result = db.execute(query, {"contest_id": contest_id})
    row = result.first()
    if not row:
        raise HTTPException(status_code=404, detail="Contest not found")
    return dict(row._mapping)


@router.get("/standings/{contest_id}")
def get_contest_standings(contest_id: int, db: Session = Depends(get_db)):
    """Get contest standings using VIEW"""
    query = text("""
        SELECT * FROM v_contest_standings 
        WHERE contest_id = :contest_id 
        ORDER BY rank
    """)
    result = db.execute(query, {"contest_id": contest_id})
    return [dict(row._mapping) for row in result]


@router.get("/users/statistics/all")
def get_user_statistics(db: Session = Depends(get_db)):
    """Get user statistics using VIEW"""
    query = text("""
        SELECT * FROM v_user_statistics 
        ORDER BY rating DESC 
        LIMIT 50
    """)
    result = db.execute(query)
    return [dict(row._mapping) for row in result]


@router.get("/problems/statistics/all")
def get_problem_statistics(db: Session = Depends(get_db)):
    """Get problem statistics using VIEW"""
    query = text("SELECT * FROM v_problem_statistics ORDER BY problem_id")
    result = db.execute(query)
    return [dict(row._mapping) for row in result]


@router.get("/languages/statistics")
def get_language_statistics(db: Session = Depends(get_db)):
    """Get language statistics using VIEW"""
    query = text("SELECT * FROM v_language_statistics")
    result = db.execute(query)
    return [dict(row._mapping) for row in result]


@router.get("/verdicts/distribution")
def get_verdict_distribution(db: Session = Depends(get_db)):
    """Get verdict distribution using VIEW"""
    query = text("SELECT * FROM v_verdict_distribution")
    result = db.execute(query)
    return [dict(row._mapping) for row in result]


@router.get("/users/{user_id}/success-rate")
def get_user_success_rate(user_id: int, db: Session = Depends(get_db)):
    """Get user success rate using scalar function"""
    query = text("SELECT get_user_success_rate(:user_id) as success_rate")
    result = db.execute(query, {"user_id": user_id}).fetchone()
    if result is None:
        raise HTTPException(status_code=404, detail="User not found")
    return {"user_id": user_id, "success_rate": float(result[0])}


@router.get("/users/{user_id}/solved-count")
def get_user_solved_count(user_id: int, db: Session = Depends(get_db)):
    """Get count of unique solved problems using scalar function"""
    query = text("SELECT count_unique_solved_problems(:user_id) as solved_count")
    result = db.execute(query, {"user_id": user_id}).fetchone()
    return {"user_id": user_id, "unique_problems_solved": result[0]}


@router.get("/users/{user_id}/contest/{contest_id}/rank")
def get_user_contest_rank(user_id: int, contest_id: int, db: Session = Depends(get_db)):
    """Get user rank in contest using scalar function"""
    query = text("SELECT get_user_contest_rank(:user_id, :contest_id) as rank")
    result = db.execute(query, {"user_id": user_id, "contest_id": contest_id}).fetchone()
    return {"user_id": user_id, "contest_id": contest_id, "rank": result[0]}


@router.get("/problems/{problem_id}/calculated-difficulty")
def get_calculated_difficulty(problem_id: int, db: Session = Depends(get_db)):
    """Calculate problem difficulty based on statistics"""
    query = text("SELECT calculate_problem_difficulty(:problem_id) as difficulty")
    result = db.execute(query, {"problem_id": problem_id}).fetchone()
    return {"problem_id": problem_id, "calculated_difficulty": result[0]}


@router.get("/users/top")
def get_top_users(limit: int = 10, db: Session = Depends(get_db)):
    """Get top users using table-valued function"""
    query = text("SELECT * FROM get_top_users(:limit)")
    result = db.execute(query, {"limit": limit})
    return [dict(row._mapping) for row in result]


@router.get("/contests/{contest_id}/statistics")
def get_contest_statistics(contest_id: int, db: Session = Depends(get_db)):
    """Get contest statistics using table-valued function"""
    query = text("SELECT * FROM get_contest_statistics(:contest_id)")
    result = db.execute(query, {"contest_id": contest_id}).fetchone()
    if result is None:
        raise HTTPException(status_code=404, detail="Contest not found")
    return dict(result._mapping)


@router.get("/users/{user_id}/contest/{contest_id}/report")
def get_user_contest_report(user_id: int, contest_id: int, db: Session = Depends(get_db)):
    """Get detailed user contest report using table-valued function"""
    query = text("SELECT * FROM get_user_contest_report(:user_id, :contest_id)")
    result = db.execute(query, {"user_id": user_id, "contest_id": contest_id})
    return [dict(row._mapping) for row in result]


@router.get("/problems/statistics/detailed")
def get_detailed_problem_statistics(db: Session = Depends(get_db)):
    """Get detailed problem statistics using table-valued function"""
    query = text("SELECT * FROM get_problem_statistics()")
    result = db.execute(query)
    return [dict(row._mapping) for row in result]


@router.get("/audit-log")
def get_audit_log(table_name: str = None, limit: int = 100, db: Session = Depends(get_db)):
    """Get audit log with optional filtering"""
    if table_name:
        query = text("""
            SELECT log_id, table_name, operation, record_id, 
                   old_values, new_values, changed_by, changed_at
            FROM audit_log 
            WHERE table_name = :table_name
            ORDER BY changed_at DESC 
            LIMIT :limit
        """)
        result = db.execute(query, {"table_name": table_name, "limit": limit})
    else:
        query = text("""
            SELECT log_id, table_name, operation, record_id, 
                   old_values, new_values, changed_by, changed_at
            FROM audit_log 
            ORDER BY changed_at DESC 
            LIMIT :limit
        """)
        result = db.execute(query, {"limit": limit})
    
    return [dict(row._mapping) for row in result]


@router.get("/contests/{contest_id}/leaderboard")
def get_contest_leaderboard(contest_id: int, db: Session = Depends(get_db)):
    """
    Complex query: Get contest leaderboard with user details
    Uses JOIN, aggregation, and subqueries
    """
    query = text("""
        WITH user_scores AS (
            SELECT 
                s.user_id,
                COUNT(DISTINCT CASE WHEN s.verdict = 'accepted' THEN s.problem_id END) as solved,
                COALESCE(SUM(DISTINCT CASE WHEN s.verdict = 'accepted' THEN s.score END), 0) as total_score,
                MIN(s.submitted_at) as first_solve
            FROM submissions s
            WHERE s.contest_id = :contest_id
            GROUP BY s.user_id
        )
        SELECT 
            ROW_NUMBER() OVER (ORDER BY us.total_score DESC, us.solved DESC, us.first_solve ASC) as rank,
            u.user_id,
            u.username,
            u.full_name,
            u.country,
            u.rating,
            COALESCE(us.solved, 0) as problems_solved,
            COALESCE(us.total_score, 0) as total_score
        FROM users u
        LEFT JOIN user_scores us ON u.user_id = us.user_id
        WHERE u.role = 'participant' AND us.user_id IS NOT NULL
        ORDER BY rank
    """)
    result = db.execute(query, {"contest_id": contest_id})
    return [dict(row._mapping) for row in result]
