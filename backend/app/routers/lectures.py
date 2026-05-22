from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.lecture import Lecture
from pydantic import BaseModel
from typing import Optional

router = APIRouter()

class LectureRequest(BaseModel):
    subject_id: str
    title: str
    order_index: Optional[int] = 0

@router.post("/")
def create_lecture(data: LectureRequest, db: Session = Depends(get_db)):
    lecture = Lecture(subject_id=data.subject_id, title=data.title, order_index=data.order_index)
    db.add(lecture)
    db.commit()
    db.refresh(lecture)
    return lecture

@router.get("/")
def get_lectures(subject_id: str, db: Session = Depends(get_db)):
    return db.query(Lecture).filter(Lecture.subject_id == subject_id).order_by(Lecture.order_index).all()

@router.get("/{lecture_id}")
def get_lecture(lecture_id: str, db: Session = Depends(get_db)):
    lecture = db.query(Lecture).filter(Lecture.id == lecture_id).first()
    if not lecture:
        raise HTTPException(status_code=404, detail="Lecture not found")
    return lecture

@router.delete("/{lecture_id}")
def delete_lecture(lecture_id: str, db: Session = Depends(get_db)):
    lecture = db.query(Lecture).filter(Lecture.id == lecture_id).first()
    if not lecture:
        raise HTTPException(status_code=404, detail="Not found")
    db.delete(lecture)
    db.commit()
    return {"message": "Deleted"}