from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.user import User
from passlib.context import CryptContext
from jose import jwt
from app.config import settings
from datetime import datetime, timedelta
from pydantic import BaseModel
from typing import Optional, List

router = APIRouter()
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

class RegisterRequest(BaseModel):
    name: str
    email: str
    password: str
    age: Optional[int] = None
    interests: Optional[List[str]] = []
    student_level: Optional[str] = "beginner"

class LoginRequest(BaseModel):
    email: str
    password: str

class UpdateProfileRequest(BaseModel):
    name: Optional[str] = None
    age: Optional[int] = None
    interests: Optional[List[str]] = None
    student_level: Optional[str] = None

def _user_dict(user):
    return {
        "id": user.id,
        "name": user.name,
        "email": user.email,
        "age": user.age,
        "interests": user.interests or [],
        "student_level": user.student_level or "beginner",
    }

def create_token(user_id: str):
    expire = datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    return jwt.encode({"sub": user_id, "exp": expire}, settings.SECRET_KEY, algorithm=settings.ALGORITHM)

def get_current_user(token: str = Depends(lambda: None), db: Session = Depends(get_db)):
    from fastapi.security import OAuth2PasswordBearer
    raise HTTPException(status_code=401, detail="Not implemented here")

@router.post("/register")
def register(data: RegisterRequest, db: Session = Depends(get_db)):
    existing = db.query(User).filter(User.email == data.email).first()
    if existing:
        raise HTTPException(status_code=400, detail="Email already registered")
    user = User(
        name=data.name,
        email=data.email,
        password_hash=pwd_context.hash(data.password),
        age=data.age,
        interests=data.interests,
        student_level=getattr(data, "student_level", "beginner") or "beginner",
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    token = create_token(user.id)
    return {"token": token, "user": _user_dict(user)}

@router.post("/login")
def login(data: LoginRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == data.email).first()
    if not user or not pwd_context.verify(data.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    token = create_token(user.id)
    return {"token": token, "user": _user_dict(user)}

@router.put("/profile/{user_id}")
def update_profile(user_id: str, data: UpdateProfileRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    if data.name is not None:
        user.name = data.name
    if data.age is not None:
        user.age = data.age
    if data.interests is not None:
        user.interests = data.interests
    if data.student_level is not None:
        user.student_level = data.student_level
    db.commit()
    db.refresh(user)
    return _user_dict(user)

@router.get("/me")
def get_me(db: Session = Depends(get_db), token: str = Depends(lambda: "")):
    raise HTTPException(status_code=401, detail="Use Authorization header")