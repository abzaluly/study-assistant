from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text
from app.database import Base, engine
from app.routers import auth, subjects, lectures, materials, ai, quizzes, progress

Base.metadata.create_all(bind=engine)

# Safe migrations for new columns (SQLite doesn't support ADD COLUMN IF NOT EXISTS)
_migrations = [
    "ALTER TABLE users ADD COLUMN student_level TEXT DEFAULT 'beginner'",
    "ALTER TABLE quiz_questions ADD COLUMN topic TEXT",
]
with engine.connect() as _conn:
    for _sql in _migrations:
        try:
            _conn.execute(text(_sql))
            _conn.commit()
        except Exception:
            pass

app = FastAPI(title="Study Assistant API")

from app.config import settings as _settings

_origins = list({
    "http://localhost:5173",
    "http://localhost:8000",
    _settings.FRONTEND_URL,
})

app.add_middleware(
    CORSMiddleware,
    allow_origins=_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix="/api/auth", tags=["auth"])
app.include_router(subjects.router, prefix="/api/subjects", tags=["subjects"])
app.include_router(lectures.router, prefix="/api/lectures", tags=["lectures"])
app.include_router(materials.router, prefix="/api/materials", tags=["materials"])
app.include_router(ai.router, prefix="/api/ai", tags=["ai"])
app.include_router(quizzes.router, prefix="/api/quizzes", tags=["quizzes"])
app.include_router(progress.router, prefix="/api/progress", tags=["progress"])

@app.get("/")
def root():
    return {"message": "Study Assistant API is running"}