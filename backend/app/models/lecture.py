from sqlalchemy import Column, String, Integer, ForeignKey
from app.database import Base
import uuid

class Lecture(Base):
    __tablename__ = "lectures"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    subject_id = Column(String, ForeignKey("subjects.id"), nullable=False)
    title = Column(String, nullable=False)
    order_index = Column(Integer, default=0)