from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.subject import Subject
from pydantic import BaseModel
from typing import Optional
import uuid

router = APIRouter()

class SubjectRequest(BaseModel):
    title: str
    description: Optional[str] = None
    user_id: str

@router.post("/")
def create_subject(data: SubjectRequest, db: Session = Depends(get_db)):
    subject = Subject(title=data.title, description=data.description, user_id=data.user_id)
    db.add(subject)
    db.commit()
    db.refresh(subject)
    return subject

@router.get("/")
def get_subjects(user_id: str, db: Session = Depends(get_db)):
    return db.query(Subject).filter(Subject.user_id == user_id).all()

@router.get("/{subject_id}")
def get_subject(subject_id: str, db: Session = Depends(get_db)):
    subject = db.query(Subject).filter(Subject.id == subject_id).first()
    if not subject:
        raise HTTPException(status_code=404, detail="Subject not found")
    return subject

@router.delete("/{subject_id}")
def delete_subject(subject_id: str, db: Session = Depends(get_db)):
    subject = db.query(Subject).filter(Subject.id == subject_id).first()
    if not subject:
        raise HTTPException(status_code=404, detail="Not found")
    db.delete(subject)
    db.commit()
    return {"message": "Deleted"}