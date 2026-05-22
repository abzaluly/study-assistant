from sqlalchemy import Column, String, Text, ForeignKey
from app.database import Base
import uuid

class Material(Base):
    __tablename__ = "materials"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    lecture_id = Column(String, ForeignKey("lectures.id"), nullable=False)
    type = Column(String, nullable=False)
    file_path = Column(String, nullable=True)
    extracted_text = Column(Text, nullable=True)
    source_label = Column(String, nullable=True)