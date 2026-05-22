from sqlalchemy import Column, String, Integer, JSON, DateTime
from sqlalchemy.dialects.sqlite import TEXT
from app.database import Base
from datetime import datetime
import uuid

class User(Base):
    __tablename__ = "users"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    name = Column(String, nullable=False)
    email = Column(String, unique=True, nullable=False)
    password_hash = Column(String, nullable=False)
    age = Column(Integer, nullable=True)
    interests = Column(JSON, default=[])
    student_level = Column(String, default="beginner")
    created_at = Column(DateTime, default=datetime.utcnow)