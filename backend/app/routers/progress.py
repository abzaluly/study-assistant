from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.quiz import Progress, QuizAttempt
from pydantic import BaseModel
from typing import Optional, List

router = APIRouter()

class ProgressUpdate(BaseModel):
    user_id: str
    lecture_id: str
    status: Optional[str] = "in_progress"
    understanding_score: Optional[float] = 0
    weak_topics: Optional[List[str]] = []

@router.post("/")
def update_progress(data: ProgressUpdate, db: Session = Depends(get_db)):
    progress = db.query(Progress).filter(
        Progress.user_id == data.user_id,
        Progress.lecture_id == data.lecture_id
    ).first()

    if not progress:
        progress = Progress(
            user_id=data.user_id,
            lecture_id=data.lecture_id,
            status=data.status,
            understanding_score=data.understanding_score,
            weak_topics=data.weak_topics
        )
        db.add(progress)
    else:
        progress.status = data.status
        progress.understanding_score = data.understanding_score
        progress.weak_topics = data.weak_topics

    db.commit()
    db.refresh(progress)
    return progress

@router.get("/")
def get_progress(user_id: str, db: Session = Depends(get_db)):
    return db.query(Progress).filter(Progress.user_id == user_id).all()

@router.get("/lecture/{lecture_id}")
def get_lecture_progress(lecture_id: str, user_id: str, db: Session = Depends(get_db)):
    return db.query(Progress).filter(
        Progress.lecture_id == lecture_id,
        Progress.user_id == user_id
    ).first()