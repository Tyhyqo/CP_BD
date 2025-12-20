"""
SQLAlchemy models for all database tables
"""
from sqlalchemy import Column, Integer, String, Boolean, Text, TIMESTAMP, ForeignKey, CheckConstraint, UniqueConstraint, DECIMAL
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base


class User(Base):
    __tablename__ = "users"

    user_id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50), unique=True, nullable=False, index=True)
    email = Column(String(100), unique=True, nullable=False, index=True)
    full_name = Column(String(100), nullable=False)
    role = Column(String(20), nullable=False)
    rating = Column(Integer, default=0)
    country = Column(String(50))
    registration_date = Column(TIMESTAMP, server_default=func.current_timestamp())
    is_active = Column(Boolean, default=True)

    __table_args__ = (
        CheckConstraint("role IN ('participant', 'jury', 'admin')", name='check_user_role'),
        CheckConstraint('rating >= 0', name='check_user_rating'),
    )


class Contest(Base):
    __tablename__ = "contests"

    contest_id = Column(Integer, primary_key=True, index=True)
    title = Column(String(200), nullable=False)
    description = Column(Text)
    contest_type = Column(String(20), nullable=False)
    status = Column(String(20), nullable=False, default='upcoming')
    start_time = Column(TIMESTAMP, nullable=False)
    duration_minutes = Column(Integer, nullable=False)
    created_by = Column(Integer, ForeignKey('users.user_id', ondelete='CASCADE'))
    created_at = Column(TIMESTAMP, server_default=func.current_timestamp())

    __table_args__ = (
        CheckConstraint("contest_type IN ('ACM_ICPC', 'Codeforces', 'IOI')", name='check_contest_type'),
        CheckConstraint("status IN ('upcoming', 'running', 'finished')", name='check_contest_status'),
        CheckConstraint('duration_minutes > 0', name='check_duration'),
    )


class Problem(Base):
    __tablename__ = "problems"

    problem_id = Column(Integer, primary_key=True, index=True)
    title = Column(String(200), nullable=False)
    description = Column(Text, nullable=False)
    difficulty = Column(String(20))
    time_limit_ms = Column(Integer, nullable=False, default=1000)
    memory_limit_mb = Column(Integer, nullable=False, default=256)
    author_id = Column(Integer, ForeignKey('users.user_id', ondelete='CASCADE'))
    created_at = Column(TIMESTAMP, server_default=func.current_timestamp())

    __table_args__ = (
        CheckConstraint("difficulty IN ('easy', 'medium', 'hard')", name='check_difficulty'),
        CheckConstraint('time_limit_ms > 0', name='check_time_limit'),
        CheckConstraint('memory_limit_mb > 0', name='check_memory_limit'),
    )


class ContestProblem(Base):
    __tablename__ = "contest_problems"

    contest_id = Column(Integer, ForeignKey('contests.contest_id', ondelete='CASCADE'), primary_key=True)
    problem_id = Column(Integer, ForeignKey('problems.problem_id', ondelete='CASCADE'), primary_key=True)
    problem_order = Column(Integer, nullable=False)
    max_score = Column(Integer, nullable=False, default=100)

    __table_args__ = (
        UniqueConstraint('contest_id', 'problem_order', name='unique_contest_problem_order'),
        CheckConstraint('problem_order > 0', name='check_problem_order'),
        CheckConstraint('max_score > 0', name='check_max_score'),
    )


class Testcase(Base):
    __tablename__ = "testcases"

    testcase_id = Column(Integer, primary_key=True, index=True)
    problem_id = Column(Integer, ForeignKey('problems.problem_id', ondelete='CASCADE'))
    input_data = Column(Text, nullable=False)
    expected_output = Column(Text, nullable=False)
    is_sample = Column(Boolean, nullable=False, default=False)
    test_order = Column(Integer, nullable=False)
    created_at = Column(TIMESTAMP, server_default=func.current_timestamp())

    __table_args__ = (
        UniqueConstraint('problem_id', 'test_order', name='unique_problem_test_order'),
        CheckConstraint('test_order > 0', name='check_test_order'),
    )


class Submission(Base):
    __tablename__ = "submissions"

    submission_id = Column(Integer, primary_key=True, index=True)
    contest_id = Column(Integer, ForeignKey('contests.contest_id', ondelete='CASCADE'))
    problem_id = Column(Integer, ForeignKey('problems.problem_id', ondelete='CASCADE'))
    user_id = Column(Integer, ForeignKey('users.user_id', ondelete='CASCADE'))
    source_code = Column(Text, nullable=False)
    language = Column(String(20), nullable=False)
    verdict = Column(String(30), default='pending')
    execution_time_ms = Column(Integer)
    memory_used_mb = Column(DECIMAL(10, 2))
    score = Column(Integer, default=0)
    submitted_at = Column(TIMESTAMP, server_default=func.current_timestamp())

    __table_args__ = (
        CheckConstraint("language IN ('C++', 'Python', 'Java', 'C')", name='check_language'),
        CheckConstraint("verdict IN ('pending', 'accepted', 'wrong_answer', 'time_limit', 'memory_limit', 'runtime_error', 'compilation_error')", name='check_verdict'),
        CheckConstraint('execution_time_ms >= 0', name='check_execution_time'),
        CheckConstraint('memory_used_mb >= 0', name='check_memory_used'),
        CheckConstraint('score >= 0', name='check_score'),
    )


class Standing(Base):
    __tablename__ = "standings"

    standing_id = Column(Integer, primary_key=True, index=True)
    contest_id = Column(Integer, ForeignKey('contests.contest_id', ondelete='CASCADE'))
    user_id = Column(Integer, ForeignKey('users.user_id', ondelete='CASCADE'))
    total_score = Column(Integer, nullable=False, default=0)
    problems_solved = Column(Integer, nullable=False, default=0)
    penalty_time = Column(Integer, nullable=False, default=0)
    rank = Column(Integer)
    last_updated = Column(TIMESTAMP, server_default=func.current_timestamp())

    __table_args__ = (
        UniqueConstraint('contest_id', 'user_id', name='unique_contest_user'),
        CheckConstraint('total_score >= 0', name='check_total_score'),
        CheckConstraint('problems_solved >= 0', name='check_problems_solved'),
        CheckConstraint('penalty_time >= 0', name='check_penalty_time'),
        CheckConstraint('rank > 0', name='check_rank'),
    )


class Tag(Base):
    __tablename__ = "tags"

    tag_id = Column(Integer, primary_key=True, index=True)
    tag_name = Column(String(50), unique=True, nullable=False)
    description = Column(Text)
    created_at = Column(TIMESTAMP, server_default=func.current_timestamp())


class ProblemTag(Base):
    __tablename__ = "problem_tags"

    problem_id = Column(Integer, ForeignKey('problems.problem_id', ondelete='CASCADE'), primary_key=True)
    tag_id = Column(Integer, ForeignKey('tags.tag_id', ondelete='CASCADE'), primary_key=True)


class AuditLog(Base):
    __tablename__ = "audit_log"

    log_id = Column(Integer, primary_key=True, index=True)
    table_name = Column(String(50), nullable=False)
    operation = Column(String(10), nullable=False)
    record_id = Column(Integer, nullable=False)
    old_values = Column(JSONB)
    new_values = Column(JSONB)
    changed_by = Column(Integer, ForeignKey('users.user_id', ondelete='SET NULL'))
    changed_at = Column(TIMESTAMP, server_default=func.current_timestamp())

    __table_args__ = (
        CheckConstraint("operation IN ('INSERT', 'UPDATE', 'DELETE')", name='check_operation'),
    )
