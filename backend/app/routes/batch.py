"""
Batch import operations with error logging
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError, DataError
from typing import List, Dict, Any
from app.database import get_db
from app.models import User, Contest, Problem, Submission
from app.schemas import BatchImportRequest, BatchImportResponse
import logging

router = APIRouter(prefix="/batch", tags=["batch-operations"])

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def import_users(data: List[Dict[Any, Any]], db: Session) -> tuple:
    """Import multiple users"""
    success_count = 0
    errors = []
    
    for idx, item in enumerate(data):
        try:
            user = User(**item)
            db.add(user)
            db.flush()
            success_count += 1
            logger.info(f"Successfully imported user: {item.get('username')}")
        except IntegrityError as e:
            db.rollback()
            error_msg = f"Row {idx + 1}: Integrity error - {str(e.orig)}"
            errors.append({"row": idx + 1, "error": error_msg, "data": item})
            logger.error(error_msg)
        except DataError as e:
            db.rollback()
            error_msg = f"Row {idx + 1}: Data error - {str(e.orig)}"
            errors.append({"row": idx + 1, "error": error_msg, "data": item})
            logger.error(error_msg)
        except Exception as e:
            db.rollback()
            error_msg = f"Row {idx + 1}: Unexpected error - {str(e)}"
            errors.append({"row": idx + 1, "error": error_msg, "data": item})
            logger.error(error_msg)
    
    try:
        db.commit()
    except Exception as e:
        db.rollback()
        logger.error(f"Commit failed: {str(e)}")
        raise
    
    return success_count, errors


def import_contests(data: List[Dict[Any, Any]], db: Session) -> tuple:
    """Import multiple contests"""
    success_count = 0
    errors = []
    
    for idx, item in enumerate(data):
        try:
            contest = Contest(**item)
            db.add(contest)
            db.flush()
            success_count += 1
            logger.info(f"Successfully imported contest: {item.get('title')}")
        except IntegrityError as e:
            db.rollback()
            error_msg = f"Row {idx + 1}: Integrity error - {str(e.orig)}"
            errors.append({"row": idx + 1, "error": error_msg, "data": item})
            logger.error(error_msg)
        except DataError as e:
            db.rollback()
            error_msg = f"Row {idx + 1}: Data error - {str(e.orig)}"
            errors.append({"row": idx + 1, "error": error_msg, "data": item})
            logger.error(error_msg)
        except Exception as e:
            db.rollback()
            error_msg = f"Row {idx + 1}: Unexpected error - {str(e)}"
            errors.append({"row": idx + 1, "error": error_msg, "data": item})
            logger.error(error_msg)
    
    try:
        db.commit()
    except Exception as e:
        db.rollback()
        logger.error(f"Commit failed: {str(e)}")
        raise
    
    return success_count, errors


def import_problems(data: List[Dict[Any, Any]], db: Session) -> tuple:
    """Import multiple problems"""
    success_count = 0
    errors = []
    
    for idx, item in enumerate(data):
        try:
            problem = Problem(**item)
            db.add(problem)
            db.flush()
            success_count += 1
            logger.info(f"Successfully imported problem: {item.get('title')}")
        except IntegrityError as e:
            db.rollback()
            error_msg = f"Row {idx + 1}: Integrity error - {str(e.orig)}"
            errors.append({"row": idx + 1, "error": error_msg, "data": item})
            logger.error(error_msg)
        except DataError as e:
            db.rollback()
            error_msg = f"Row {idx + 1}: Data error - {str(e.orig)}"
            errors.append({"row": idx + 1, "error": error_msg, "data": item})
            logger.error(error_msg)
        except Exception as e:
            db.rollback()
            error_msg = f"Row {idx + 1}: Unexpected error - {str(e)}"
            errors.append({"row": idx + 1, "error": error_msg, "data": item})
            logger.error(error_msg)
    
    try:
        db.commit()
    except Exception as e:
        db.rollback()
        logger.error(f"Commit failed: {str(e)}")
        raise
    
    return success_count, errors


def import_submissions(data: List[Dict[Any, Any]], db: Session) -> tuple:
    """Import multiple submissions"""
    success_count = 0
    errors = []
    
    for idx, item in enumerate(data):
        try:
            submission = Submission(**item)
            db.add(submission)
            db.flush()
            success_count += 1
            logger.info(f"Successfully imported submission from user {item.get('user_id')}")
        except IntegrityError as e:
            db.rollback()
            error_msg = f"Row {idx + 1}: Integrity error - {str(e.orig)}"
            errors.append({"row": idx + 1, "error": error_msg, "data": item})
            logger.error(error_msg)
        except DataError as e:
            db.rollback()
            error_msg = f"Row {idx + 1}: Data error - {str(e.orig)}"
            errors.append({"row": idx + 1, "error": error_msg, "data": item})
            logger.error(error_msg)
        except Exception as e:
            db.rollback()
            error_msg = f"Row {idx + 1}: Unexpected error - {str(e)}"
            errors.append({"row": idx + 1, "error": error_msg, "data": item})
            logger.error(error_msg)
    
    try:
        db.commit()
    except Exception as e:
        db.rollback()
        logger.error(f"Commit failed: {str(e)}")
        raise
    
    return success_count, errors


@router.post("/import", response_model=BatchImportResponse)
def batch_import(request: BatchImportRequest, db: Session = Depends(get_db)):
    """
    Batch import data with error logging
    
    Supports: users, contests, problems, submissions
    
    Example request:
    {
        "entity_type": "users",
        "data": [
            {"username": "test1", "email": "test1@example.com", "full_name": "Test User", "role": "participant"},
            {"username": "test2", "email": "test2@example.com", "full_name": "Test User 2", "role": "participant"}
        ]
    }
    """
    logger.info(f"Starting batch import for {request.entity_type}, {len(request.data)} records")
    
    importers = {
        "users": import_users,
        "contests": import_contests,
        "problems": import_problems,
        "submissions": import_submissions,
    }
    
    if request.entity_type not in importers:
        raise HTTPException(status_code=400, detail=f"Unsupported entity type: {request.entity_type}")
    
    success_count, errors = importers[request.entity_type](request.data, db)
    
    logger.info(f"Batch import completed: {success_count} success, {len(errors)} failed")
    
    return BatchImportResponse(
        total=len(request.data),
        success=success_count,
        failed=len(errors),
        errors=errors
    )
