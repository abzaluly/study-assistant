from sqlalchemy import Column, String, Float, Integer, JSON, ForeignKey, DateTime
from app.database import Base
from datetime import datetime
import uuid

class Quiz(Base):
    __tablename__ = "quizzes"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    lecture_id = Column(String, ForeignKey("lectures.id"), nullable=False)
    title = Column(String, nullable=False)
    generated_from = Column(String, nullable=True)

class QuizQuestion(Base):
    __tablename__ = "quiz_questions"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    quiz_id = Column(String, ForeignKey("quizzes.id"), nullable=False)
    question = Column(String, nullable=False)
    options = Column(JSON, nullable=False)
    correct_answer = Column(String, nullable=False)
    explanation = Column(String, nullable=True)
    topic = Column(String, nullable=True)

class QuizAttempt(Base):
    __tablename__ = "quiz_attempts"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    quiz_id = Column(String, ForeignKey("quizzes.id"), nullable=False)
    user_id = Column(String, ForeignKey("users.id"), nullable=False)
    score = Column(Float, default=0)
    total = Column(Integer, default=0)
    answers = Column(JSON, default=[])
    created_at = Column(DateTime, default=datetime.utcnow)

class Progress(Base):
    __tablename__ = "progress"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, ForeignKey("users.id"), nullable=False)
    lecture_id = Column(String, ForeignKey("lectures.id"), nullable=False)
    status = Column(String, default="not_started")
    understanding_score = Column(Float, default=0)
    weak_topics = Column(JSON, default=[])