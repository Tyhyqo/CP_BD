"""
Contest CRUD operations
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from app.database import get_db
from app.models import Contest
from app.schemas import ContestCreate, ContestUpdate, ContestResponse

router = APIRouter(prefix="/contests", tags=["contests"])


@router.post("/", response_model=ContestResponse, status_code=status.HTTP_201_CREATED)
def create_contest(contest: ContestCreate, db: Session = Depends(get_db)):
    """Create a new contest"""
    db_contest = Contest(**contest.model_dump())
    db.add(db_contest)
    db.commit()
    db.refresh(db_contest)
    return db_contest


@router.get("/", response_model=List[ContestResponse])
def get_contests(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """Get all contests with pagination"""
    contests = db.query(Contest).offset(skip).limit(limit).all()
    return contests


@router.get("/{contest_id}", response_model=ContestResponse)
def get_contest(contest_id: int, db: Session = Depends(get_db)):
    """Get contest by ID"""
    contest = db.query(Contest).filter(Contest.contest_id == contest_id).first()
    if not contest:
        raise HTTPException(status_code=404, detail="Contest not found")
    return contest


@router.put("/{contest_id}", response_model=ContestResponse)
def update_contest(contest_id: int, contest_update: ContestUpdate, db: Session = Depends(get_db)):
    """Update contest"""
    contest = db.query(Contest).filter(Contest.contest_id == contest_id).first()
    if not contest:
        raise HTTPException(status_code=404, detail="Contest not found")
    
    update_data = contest_update.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(contest, field, value)
    
    db.commit()
    db.refresh(contest)
    return contest


@router.delete("/{contest_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_contest(contest_id: int, db: Session = Depends(get_db)):
    """Delete contest"""
    contest = db.query(Contest).filter(Contest.contest_id == contest_id).first()
    if not contest:
        raise HTTPException(status_code=404, detail="Contest not found")
    
    db.delete(contest)
    db.commit()
    return None
