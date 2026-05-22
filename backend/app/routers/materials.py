from fastapi import APIRouter, Depends, UploadFile, File, Form, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.material import Material
import fitz
import os
import uuid
from PIL import Image
import pytesseract
import io

router = APIRouter()
UPLOAD_DIR = "uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)

def extract_text_from_pdf(file_path: str) -> str:
    doc = fitz.open(file_path)
    text = ""
    for page in doc:
        # Сначала пробуем обычный текст
        page_text = page.get_text()
        if page_text.strip():
            text += page_text
        else:
            # Если текста нет — это рукописный/сканированный PDF, используем OCR
            pix = page.get_pixmap(matrix=fitz.Matrix(2, 2))
            img_data = pix.tobytes("png")
            img = Image.open(io.BytesIO(img_data))
            ocr_text = pytesseract.image_to_string(img, lang='rus+eng')
            text += ocr_text
    return text

@router.post("/upload")
async def upload_material(
    lecture_id: str = Form(...),
    source_label: str = Form(...),
    type: str = Form(...),
    file: UploadFile = File(...),
    db: Session = Depends(get_db)
):
    file_ext = file.filename.split(".")[-1]
    file_name = f"{uuid.uuid4()}.{file_ext}"
    file_path = os.path.join(UPLOAD_DIR, file_name)

    with open(file_path, "wb") as f:
        f.write(await file.read())

    extracted_text = ""
    if file_ext.lower() == "pdf":
        extracted_text = extract_text_from_pdf(file_path)
    elif file_ext.lower() in ["txt", "md"]:
        with open(file_path, "r", encoding="utf-8") as f:
            extracted_text = f.read()

    if not extracted_text.strip():
        extracted_text = "Text could not be extracted from this file."

    material = Material(
        lecture_id=lecture_id,
        type=type,
        file_path=file_path,
        extracted_text=extracted_text,
        source_label=source_label
    )
    db.add(material)
    db.commit()
    db.refresh(material)
    return material

@router.get("/")
def get_materials(lecture_id: str, db: Session = Depends(get_db)):
    return db.query(Material).filter(Material.lecture_id == lecture_id).all()