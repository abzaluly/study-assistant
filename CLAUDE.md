# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AI-powered study assistant for Kazakh/Russian-speaking students. Students upload lecture materials and personal notes; the app uses OpenAI (gpt-4o-mini) to analyze gaps, answer questions, generate SVG visualizations, and create targeted quizzes.

## Commands

### Frontend (`frontend/`)
```bash
npm run dev      # Dev server on http://localhost:5173
npm run build    # Production bundle
npm run lint     # ESLint check
npm run preview  # Preview production build
```

### Backend (repo root or `backend/`)
```bash
# Activate venv first
source backend/venv/bin/activate

uvicorn main:app --reload          # Dev server on http://localhost:8000
uvicorn main:app --reload --port 8000  # Explicit port
```

No test runner is configured — there are no test files in the project.

## Architecture

### Frontend (React + Vite, no TypeScript)
- **Routing**: React Router v7 with a `PrivateRoute` wrapper that checks `localStorage` for a JWT token
- **API layer**: Single Axios instance in `src/api/index.js` — base URL `http://localhost:8000/api`, JWT injected via request interceptor
- **State**: Local `useState`/`useEffect` only — no Redux or Context
- **Main feature page**: `src/pages/LectureDetail.jsx` (873 lines) — handles material upload, AI analysis, chat Q&A, SVG visualization, quiz generation, and Chart.js progress charts

### Backend (FastAPI + SQLAlchemy + SQLite)
- `main.py` — app factory, CORS configured for `localhost:5173`, mounts all routers under `/api`
- `app/database.py` — SQLAlchemy engine + `SessionLocal`; tables created via `Base.metadata.create_all` on startup
- `app/config.py` — Pydantic `Settings` reads from `backend/.env`
- Routers in `app/routers/`: `auth`, `subjects`, `lectures`, `materials`, `ai`, `quizzes`, `progress`

### Database schema (SQLite, file: `backend/study_assistant.db`)
```
users → subjects → lectures → materials
                           → quizzes → quiz_questions
                                    → quiz_attempts
                           → progress
```
- `materials.source_label`: `"lecture"` or `"note"` (distinguishes uploaded lecture PDFs from student notes)
- `materials.extracted_text`: full text stored for AI consumption
- `progress.weak_topics`: JSON array used by quiz generation to focus on gaps

### AI integration (`app/routers/ai.py`, `app/routers/quizzes.py`)
- Model: `gpt-4o-mini` via OpenAI SDK
- **analyze-notes**: compares lecture text vs. student note text, returns gap analysis in Russian
- **explain**: Q&A with optional student interest context (personalized analogies)
- **quiz-svg**: generates raw SVG markup to visually illustrate a concept
- **quizzes/generate**: creates multiple-choice questions focused on `weak_topics`, avoids repeating past questions

### File processing (`app/routers/materials.py`)
- PDF text extraction via PyMuPDF (`fitz`); falls back to pytesseract OCR for scanned/handwritten docs
- Uploaded files stored in `backend/uploads/`

## Key conventions

- UI text and AI prompts are in **Russian** (target audience: Kazakh students)
- Inline styles dominate the frontend — no separate CSS files or CSS-in-JS library
- The Anthropic SDK is installed (`anthropic==0.86.0`) but all active AI calls go through OpenAI
- CORS is hardcoded to `http://localhost:5173` — update `main.py` for any other frontend origin
- JWT expiry is 1 week (`ACCESS_TOKEN_EXPIRE_MINUTES=10080`)
