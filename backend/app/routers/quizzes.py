from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.material import Material
from app.models.quiz import Quiz, QuizQuestion, QuizAttempt, Progress
from app.services.interest_expander import expand_interests_to_context
from app.config import settings
from pydantic import BaseModel
from typing import Optional, List
from openai import OpenAI
import json

router = APIRouter()
client = OpenAI(api_key=settings.OPENAI_API_KEY)

class GenerateQuizRequest(BaseModel):
    lecture_id: str
    weak_areas: Optional[List[str]] = []
    num_questions: Optional[int] = 10
    interests: Optional[List[str]] = []

class SubmitAttemptRequest(BaseModel):
    quiz_id: str
    user_id: str
    answers: List[str]

@router.post("/generate")
def generate_quiz(data: GenerateQuizRequest, db: Session = Depends(get_db)):
    materials = db.query(Material).filter(Material.lecture_id == data.lecture_id).all()
    lecture_text = " ".join([m.extracted_text or "" for m in materials])

    if not lecture_text.strip():
        raise HTTPException(status_code=400, detail="No materials found")

    existing_quizzes = db.query(Quiz).filter(Quiz.lecture_id == data.lecture_id).all()
    existing_questions = []
    for q in existing_quizzes:
        questions = db.query(QuizQuestion).filter(QuizQuestion.quiz_id == q.id).all()
        existing_questions.extend([qq.question for qq in questions])

    existing_str = "\n".join(existing_questions[-20:]) if existing_questions else "Нет"
    expanded = expand_interests_to_context(data.interests or [])
    interests_str = ", ".join(data.interests) if data.interests else "спорт"
    entities_str = expanded["entities_str"]

    prompt = f"""Ты — адаптивный академический ИИ для студентов Казахстана. Создай {data.num_questions} уникальных вопросов.

МАТЕРИАЛ ЛЕКЦИИ:
{lecture_text[:3000]}

СЛАБЫЕ МЕСТА СТУДЕНТА (ФОКУС на них): {data.weak_areas}
ИНТЕРЕСЫ: {interests_str}
КОНКРЕТНЫЕ ПЕРСОНАЖИ/ЛИЧНОСТИ для примеров в вопросах: {entities_str}

УЖЕ СУЩЕСТВУЮЩИЕ ВОПРОСЫ (НЕ ПОВТОРЯЙ):
{existing_str}

ТРЕБОВАНИЯ:
- Проверяй понимание, а не просто память
- В вопросах ИСПОЛЬЗУЙ конкретных персонажей: {entities_str}
- НЕ используй LaTeX — пиши математику обычным текстом
- Вопросы разного уровня сложности
- Объяснения учат: почему ответ правильный + пример через {entities_str}

Верни ТОЛЬКО валидный JSON:
{{
  "title": "Название теста",
  "questions": [
    {{
      "question": "Вопрос на понимание?",
      "options": ["A. вариант", "B. вариант", "C. вариант", "D. вариант"],
      "correct_answer": "A",
      "explanation": "Подробное объяснение почему этот ответ правильный. Покажи пример. Объясни почему другие варианты неправильные.",
      "difficulty": "easy/medium/hard",
      "topic": "название темы вопроса"
    }}
  ]
}}"""

    response = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[{"role": "user", "content": prompt}],
        max_tokens=4000,
        temperature=0.5
    )

    try:
        text = response.choices[0].message.content.strip()
        if text.startswith("```"):
            text = text.split("\n", 1)[1]
            text = text.rsplit("```", 1)[0]
        result = json.loads(text)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to parse quiz: {str(e)}")

    quiz = Quiz(
        lecture_id=data.lecture_id,
        title=result.get("title", "Тест по лекции"),
        generated_from="ai"
    )
    db.add(quiz)
    db.commit()
    db.refresh(quiz)

    for q in result.get("questions", []):
        question = QuizQuestion(
            quiz_id=quiz.id,
            question=q["question"],
            options=q["options"],
            correct_answer=q["correct_answer"],
            explanation=q.get("explanation", ""),
            topic=q.get("topic", ""),
        )
        db.add(question)
    db.commit()

    questions = db.query(QuizQuestion).filter(QuizQuestion.quiz_id == quiz.id).all()
    return {"quiz_id": quiz.id, "title": quiz.title, "questions": questions}

@router.post("/attempt")
def submit_attempt(data: SubmitAttemptRequest, db: Session = Depends(get_db)):
    questions = db.query(QuizQuestion).filter(QuizQuestion.quiz_id == data.quiz_id).all()
    if not questions:
        raise HTTPException(status_code=404, detail="Quiz not found")

    correct = sum(1 for q, a in zip(questions, data.answers) if q.correct_answer == a)
    score = correct / len(questions) if questions else 0

    attempt = QuizAttempt(
        quiz_id=data.quiz_id,
        user_id=data.user_id,
        score=score,
        total=len(questions),
        answers=data.answers
    )
    db.add(attempt)
    db.commit()

    results = []
    wrong_topics = []
    for q, a in zip(questions, data.answers):
        is_correct = q.correct_answer == a
        results.append({
            "question": q.question,
            "your_answer": a,
            "correct_answer": q.correct_answer,
            "is_correct": is_correct,
            "explanation": q.explanation,
            "options": q.options,
            "topic": q.topic or "",
        })
        if not is_correct and q.topic:
            wrong_topics.append(q.topic)

    # Feedback loop: update Progress.weak_topics with wrong answer topics
    if wrong_topics and data.user_id:
        quiz = db.query(Quiz).filter(Quiz.id == data.quiz_id).first()
        if quiz and quiz.lecture_id:
            progress = db.query(Progress).filter(
                Progress.user_id == data.user_id,
                Progress.lecture_id == quiz.lecture_id
            ).first()
            if progress:
                existing = set(progress.weak_topics or [])
                existing.update(wrong_topics)
                # Topics answered correctly can be removed from weak list
                correct_topics = {q.topic for q, a in zip(questions, data.answers)
                                  if q.correct_answer == a and q.topic}
                existing -= correct_topics
                progress.weak_topics = list(existing)
                progress.understanding_score = score
            else:
                progress = Progress(
                    user_id=data.user_id,
                    lecture_id=quiz.lecture_id,
                    weak_topics=wrong_topics,
                    understanding_score=score,
                    status="in_progress",
                )
                db.add(progress)
            db.commit()

    return {
        "score": score,
        "correct": correct,
        "total": len(questions),
        "percentage": round(score * 100),
        "results": results,
        "new_weak_topics": wrong_topics,
    }

@router.get("/")
def get_quizzes(lecture_id: str, db: Session = Depends(get_db)):
    quizzes = db.query(Quiz).filter(Quiz.lecture_id == lecture_id).all()
    result = []
    for quiz in quizzes:
        attempts = db.query(QuizAttempt).filter(QuizAttempt.quiz_id == quiz.id).all()
        best_score = max([a.score for a in attempts], default=0) if attempts else 0
        result.append({
            "id": quiz.id,
            "title": quiz.title,
            "attempts_count": len(attempts),
            "best_score": round(best_score * 100),
        })
    return result

@router.get("/{quiz_id}/questions")
def get_quiz_questions(quiz_id: str, db: Session = Depends(get_db)):
    questions = db.query(QuizQuestion).filter(QuizQuestion.quiz_id == quiz_id).all()
    quiz = db.query(Quiz).filter(Quiz.id == quiz_id).first()
    return {"quiz_id": quiz_id, "title": quiz.title if quiz else "", "questions": questions}

@router.get("/{quiz_id}/attempts")
def get_attempts(quiz_id: str, db: Session = Depends(get_db)):
    attempts = db.query(QuizAttempt).filter(QuizAttempt.quiz_id == quiz_id).order_by(QuizAttempt.created_at.desc()).all()
    return attempts