"""
Submission CRUD operations
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from typing import List
from app.database import get_db
from app.models import Submission
from app.schemas import SubmissionCreate, SubmissionUpdate, SubmissionResponse

router = APIRouter(prefix="/submissions", tags=["submissions"])


@router.post("/", response_model=SubmissionResponse, status_code=status.HTTP_201_CREATED)
def create_submission(submission: SubmissionCreate, db: Session = Depends(get_db)):
    """Create a new submission"""
    try:
        db_submission = Submission(**submission.model_dump())
        db.add(db_submission)
        db.commit()
        db.refresh(db_submission)
        return db_submission
    except IntegrityError as e:
        db.rollback()
        error_msg = str(e.orig)
        if "foreign key" in error_msg.lower():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid reference (user_id, contest_id, or problem_id not found): {error_msg}"
            )
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Database constraint violation: {error_msg}"
        )


@router.get("/", response_model=List[SubmissionResponse])
def get_submissions(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """Get all submissions with pagination"""
    submissions = db.query(Submission).offset(skip).limit(limit).all()
    return submissions


@router.get("/{submission_id}", response_model=SubmissionResponse)
def get_submission(submission_id: int, db: Session = Depends(get_db)):
    """Get submission by ID"""
    submission = db.query(Submission).filter(Submission.submission_id == submission_id).first()
    if not submission:
        raise HTTPException(status_code=404, detail="Submission not found")
    return submission


@router.put("/{submission_id}", response_model=SubmissionResponse)
def update_submission(submission_id: int, submission_update: SubmissionUpdate, db: Session = Depends(get_db)):
    """Update submission (usually for judging results)"""
    submission = db.query(Submission).filter(Submission.submission_id == submission_id).first()
    if not submission:
        raise HTTPException(status_code=404, detail="Submission not found")
    
    try:
        update_data = submission_update.model_dump(exclude_unset=True)
        for field, value in update_data.items():
            setattr(submission, field, value)
        
        db.commit()
        db.refresh(submission)
        return submission
    except IntegrityError as e:
        db.rollback()
        error_msg = str(e.orig)
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Database constraint violation: {error_msg}"
        )


@router.delete("/{submission_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_submission(submission_id: int, db: Session = Depends(get_db)):
    """Delete submission"""
    submission = db.query(Submission).filter(Submission.submission_id == submission_id).first()
    if not submission:
        raise HTTPException(status_code=404, detail="Submission not found")
    
    db.delete(submission)
    db.commit()
    return None
