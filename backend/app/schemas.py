"""
Pydantic schemas for request/response validation
"""
from pydantic import BaseModel, EmailStr, Field
from datetime import datetime
from typing import Optional, List
from decimal import Decimal


# User Schemas
class UserBase(BaseModel):
    username: str = Field(..., max_length=50)
    email: EmailStr
    full_name: str = Field(..., max_length=100)
    role: str = Field(..., pattern="^(participant|jury|admin)$")
    country: Optional[str] = Field(None, max_length=50)

class UserCreate(UserBase):
    rating: int = Field(default=0, ge=0)

class UserUpdate(BaseModel):
    full_name: Optional[str] = None
    country: Optional[str] = None
    rating: Optional[int] = Field(None, ge=0)
    is_active: Optional[bool] = None

class UserResponse(UserBase):
    user_id: int
    rating: int
    registration_date: datetime
    is_active: bool

    class Config:
        from_attributes = True


# Contest Schemas
class ContestBase(BaseModel):
    title: str = Field(..., max_length=200)
    description: Optional[str] = None
    contest_type: str = Field(..., pattern="^(ACM_ICPC|Codeforces|IOI)$")
    start_time: datetime
    duration_minutes: int = Field(..., gt=0)

class ContestCreate(ContestBase):
    created_by: int

class ContestUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    status: Optional[str] = Field(None, pattern="^(upcoming|running|finished)$")
    start_time: Optional[datetime] = None
    duration_minutes: Optional[int] = Field(None, gt=0)

class ContestResponse(ContestBase):
    contest_id: int
    status: str
    created_by: int
    created_at: datetime

    class Config:
        from_attributes = True


# Problem Schemas
class ProblemBase(BaseModel):
    title: str = Field(..., max_length=200)
    description: str
    difficulty: Optional[str] = Field(None, pattern="^(easy|medium|hard)$")
    time_limit_ms: int = Field(default=1000, gt=0)
    memory_limit_mb: int = Field(default=256, gt=0)

class ProblemCreate(ProblemBase):
    author_id: int

class ProblemUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    difficulty: Optional[str] = Field(None, pattern="^(easy|medium|hard)$")
    time_limit_ms: Optional[int] = Field(None, gt=0)
    memory_limit_mb: Optional[int] = Field(None, gt=0)

class ProblemResponse(ProblemBase):
    problem_id: int
    author_id: int
    created_at: datetime

    class Config:
        from_attributes = True


# Submission Schemas
class SubmissionBase(BaseModel):
    contest_id: int
    problem_id: int
    user_id: int
    source_code: str
    language: str = Field(..., pattern="^(C\\+\\+|Python|Java|C)$")

class SubmissionCreate(SubmissionBase):
    pass

class SubmissionUpdate(BaseModel):
    verdict: Optional[str] = Field(None, pattern="^(pending|accepted|wrong_answer|time_limit|memory_limit|runtime_error|compilation_error)$")
    execution_time_ms: Optional[int] = Field(None, ge=0)
    memory_used_mb: Optional[Decimal] = Field(None, ge=0)
    score: Optional[int] = Field(None, ge=0)

class SubmissionResponse(SubmissionBase):
    submission_id: int
    verdict: str
    execution_time_ms: Optional[int]
    memory_used_mb: Optional[Decimal]
    score: int
    submitted_at: datetime

    class Config:
        from_attributes = True


# Tag Schemas
class TagBase(BaseModel):
    tag_name: str = Field(..., max_length=50)
    description: Optional[str] = None

class TagCreate(TagBase):
    pass

class TagResponse(TagBase):
    tag_id: int
    created_at: datetime

    class Config:
        from_attributes = True


# Testcase Schemas
class TestcaseBase(BaseModel):
    problem_id: int
    input_data: str
    expected_output: str
    is_sample: bool = False
    test_order: int = Field(..., gt=0)

class TestcaseCreate(TestcaseBase):
    pass

class TestcaseResponse(TestcaseBase):
    testcase_id: int
    created_at: datetime

    class Config:
        from_attributes = True


# Standing Schemas
class StandingResponse(BaseModel):
    standing_id: int
    contest_id: int
    user_id: int
    total_score: int
    problems_solved: int
    penalty_time: int
    rank: Optional[int]
    last_updated: datetime

    class Config:
        from_attributes = True


# Batch Import Schema
class BatchImportRequest(BaseModel):
    entity_type: str = Field(..., pattern="^(users|contests|problems|submissions)$")
    data: List[dict]

class BatchImportResponse(BaseModel):
    total: int
    success: int
    failed: int
    errors: List[dict]
