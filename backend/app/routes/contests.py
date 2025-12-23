"""
Contest CRUD operations
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from typing import List
from app.database import get_db
from app.models import Contest
from app.schemas import ContestCreate, ContestUpdate, ContestResponse

router = APIRouter(prefix="/contests", tags=["contests"])


@router.post("/", response_model=ContestResponse, status_code=status.HTTP_201_CREATED)
def create_contest(contest: ContestCreate, db: Session = Depends(get_db)):
    """Create a new contest"""
    try:
        db_contest = Contest(**contest.model_dump())
        db.add(db_contest)
        db.commit()
        db.refresh(db_contest)
        return db_contest
    except IntegrityError as e:
        db.rollback()
        error_msg = str(e.orig)
        if "foreign key" in error_msg.lower():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid reference (user_id not found): {error_msg}"
            )
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Database constraint violation: {error_msg}"
        )


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
    
    try:
        update_data = contest_update.model_dump(exclude_unset=True)
        for field, value in update_data.items():
            setattr(contest, field, value)
        
        db.commit()
        db.refresh(contest)
        return contest
    except IntegrityError as e:
        db.rollback()
        error_msg = str(e.orig)
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Database constraint violation: {error_msg}"
        )


@router.delete("/{contest_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_contest(contest_id: int, db: Session = Depends(get_db)):
    """Delete contest"""
    contest = db.query(Contest).filter(Contest.contest_id == contest_id).first()
    if not contest:
        raise HTTPException(status_code=404, detail="Contest not found")
    
    db.delete(contest)
    db.commit()
    return None
