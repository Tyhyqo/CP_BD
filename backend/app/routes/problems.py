"""
Problem CRUD operations
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from app.database import get_db
from app.models import Problem
from app.schemas import ProblemCreate, ProblemUpdate, ProblemResponse

router = APIRouter(prefix="/problems", tags=["problems"])


@router.post("/", response_model=ProblemResponse, status_code=status.HTTP_201_CREATED)
def create_problem(problem: ProblemCreate, db: Session = Depends(get_db)):
    """Create a new problem"""
    db_problem = Problem(**problem.model_dump())
    db.add(db_problem)
    db.commit()
    db.refresh(db_problem)
    return db_problem


@router.get("/", response_model=List[ProblemResponse])
def get_problems(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """Get all problems with pagination"""
    problems = db.query(Problem).offset(skip).limit(limit).all()
    return problems


@router.get("/{problem_id}", response_model=ProblemResponse)
def get_problem(problem_id: int, db: Session = Depends(get_db)):
    """Get problem by ID"""
    problem = db.query(Problem).filter(Problem.problem_id == problem_id).first()
    if not problem:
        raise HTTPException(status_code=404, detail="Problem not found")
    return problem


@router.put("/{problem_id}", response_model=ProblemResponse)
def update_problem(problem_id: int, problem_update: ProblemUpdate, db: Session = Depends(get_db)):
    """Update problem"""
    problem = db.query(Problem).filter(Problem.problem_id == problem_id).first()
    if not problem:
        raise HTTPException(status_code=404, detail="Problem not found")
    
    update_data = problem_update.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(problem, field, value)
    
    db.commit()
    db.refresh(problem)
    return problem


@router.delete("/{problem_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_problem(problem_id: int, db: Session = Depends(get_db)):
    """Delete problem"""
    problem = db.query(Problem).filter(Problem.problem_id == problem_id).first()
    if not problem:
        raise HTTPException(status_code=404, detail="Problem not found")
    
    db.delete(problem)
    db.commit()
    return None
