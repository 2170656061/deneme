from contextlib import asynccontextmanager
from fastapi import FastAPI, Depends, HTTPException, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from sqlmodel import Session, SQLModel, select
from sqlalchemy import text
from database import engine, get_session
from models import RaceResult, Course, Checkpoint, User
from kml_parser import parse_kml_content, extract_kmz
from auth import create_access_token, get_current_user, get_current_admin_user
from typing import List
from datetime import datetime
import os
from pathlib import Path
from uuid import uuid4


def _column_exists(table_name: str, column_name: str) -> bool:
    query = text(
        """
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = :table_name
          AND column_name = :column_name
        LIMIT 1
        """
    )
    with engine.begin() as connection:
        row = connection.execute(
            query,
            {"table_name": table_name, "column_name": column_name},
        ).first()
    return row is not None


def migrate_legacy_schema() -> None:
    legacy_user_columns = {
        "password_hash": 'ALTER TABLE "user" ADD COLUMN password_hash VARCHAR NOT NULL DEFAULT \'\'',
        "is_active": 'ALTER TABLE "user" ADD COLUMN is_active BOOLEAN NOT NULL DEFAULT TRUE',
        "last_login": 'ALTER TABLE "user" ADD COLUMN last_login TIMESTAMP NULL',
    }

    for column_name, ddl in legacy_user_columns.items():
        if not _column_exists("user", column_name):
            with engine.begin() as connection:
                connection.execute(text(ddl))


@asynccontextmanager
async def lifespan(app: FastAPI):
    migrate_legacy_schema()
    SQLModel.metadata.create_all(engine)
    yield


app = FastAPI(lifespan=lifespan)


def _parse_cors_origins() -> List[str]:
    raw_origins = os.getenv("CORS_ORIGINS", "http://localhost:3000,http://127.0.0.1:3000")
    return [origin.strip() for origin in raw_origins.split(",") if origin.strip()]

app.add_middleware(
    CORSMiddleware,
    allow_origins=_parse_cors_origins(),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ============ HEALTH CHECK ============
@app.get("/")
def root():
    return {"status": "ok", "message": "Orienteering API is running"}


# ============ COURSES CRUD ============
@app.get("/courses", response_model=List[Course])
def get_courses(session: Session = Depends(get_session)):
    return session.exec(select(Course)).all()

@app.get("/courses/{course_id}", response_model=Course)
def get_course(course_id: int, session: Session = Depends(get_session)):
    course = session.get(Course, course_id)
    if not course:
        raise HTTPException(status_code=404, detail="Course not found")
    return course

@app.post("/courses", response_model=Course)
def create_course(
    course: Course,
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_admin_user),
):
    session.add(course)
    session.commit()
    session.refresh(course)
    return course

@app.put("/courses/{course_id}", response_model=Course)
def update_course(
    course_id: int,
    course: Course,
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_admin_user),
):
    db_course = session.get(Course, course_id)
    if not db_course:
        raise HTTPException(status_code=404, detail="Course not found")
    db_course.name = course.name
    db_course.description = course.description
    db_course.distance_km = course.distance_km
    session.commit()
    session.refresh(db_course)
    return db_course

@app.delete("/courses/{course_id}")
def delete_course(
    course_id: int,
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_admin_user),
):
    course = session.get(Course, course_id)
    if not course:
        raise HTTPException(status_code=404, detail="Course not found")
    checkpoints = session.exec(
        select(Checkpoint).where(Checkpoint.course_id == course_id)
    ).all()
    for cp in checkpoints:
        session.delete(cp)
    session.delete(course)
    session.commit()
    return {"status": "deleted", "course_id": course_id}


# ============ CHECKPOINTS CRUD ============
@app.get("/courses/{course_id}/checkpoints", response_model=List[Checkpoint])
def get_checkpoints(course_id: int, session: Session = Depends(get_session)):
    return session.exec(
        select(Checkpoint)
        .where(Checkpoint.course_id == course_id)
        .order_by(Checkpoint.order)
    ).all()

@app.post("/checkpoints", response_model=Checkpoint)
def create_checkpoint(
    checkpoint: Checkpoint,
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_admin_user),
):
    session.add(checkpoint)
    session.commit()
    session.refresh(checkpoint)
    return checkpoint

@app.delete("/checkpoints/{checkpoint_id}")
def delete_checkpoint(
    checkpoint_id: int,
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_admin_user),
):
    checkpoint = session.get(Checkpoint, checkpoint_id)
    if not checkpoint:
        raise HTTPException(status_code=404, detail="Checkpoint not found")
    session.delete(checkpoint)
    session.commit()
    return {"status": "deleted", "checkpoint_id": checkpoint_id}


# ============ RESULTS ============
@app.get("/results", response_model=List[RaceResult])
def get_results(session: Session = Depends(get_session)):
    return session.exec(
        select(RaceResult).order_by(RaceResult.completed_at.desc())
    ).all()

@app.post("/sync-result", response_model=RaceResult)
def sync_result(
    result: RaceResult,
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user),
):
    result.user_id = current_user.id
    session.add(result)
    session.commit()
    session.refresh(result)
    return result


# ============ AUTH ENDPOINTS ============
class UserRegister(SQLModel):
    username: str
    email: str
    password: str
    # NOTE: role is intentionally NOT accepted from client.
    # Every registered user automatically becomes admin.

class UserLogin(SQLModel):
    username: str
    password: str

class Token(SQLModel):
    access_token: str
    token_type: str
    user: dict


class UserPublic(SQLModel):
    id: int
    username: str
    email: str
    role: str
    is_active: bool
    created_at: datetime
    last_login: datetime | None = None


class UserCreate(SQLModel):
    username: str
    email: str
    password: str
    role: str = "runner"
    is_active: bool = True

@app.post("/auth/register", response_model=Token)
def register(user_data: UserRegister, session: Session = Depends(get_session)):
    # Check username uniqueness
    existing_user = session.exec(
        select(User).where(User.username == user_data.username)
    ).first()
    if existing_user:
        raise HTTPException(status_code=400, detail="Bu kullanıcı adı zaten kayıtlı")

    # Check email uniqueness
    existing_email = session.exec(
        select(User).where(User.email == user_data.email)
    ).first()
    if existing_email:
        raise HTTPException(status_code=400, detail="Bu e-posta zaten kayıtlı")

    # All registered users are automatically admin by app design.
    user = User(
        username=user_data.username,
        email=user_data.email,
        password_hash=User.hash_password(user_data.password),
        role="admin",          # <-- Always admin
        is_active=True,
        created_at=datetime.utcnow()
    )
    session.add(user)
    session.commit()
    session.refresh(user)

    access_token = create_access_token(data={"sub": user.username})

    return Token(
        access_token=access_token,
        token_type="bearer",
        user={
            "id": user.id,
            "username": user.username,
            "email": user.email,
            "role": user.role
        }
    )

@app.post("/auth/login", response_model=Token)
def login(user_data: UserLogin, session: Session = Depends(get_session)):
    user = session.exec(
        select(User).where(User.username == user_data.username)
    ).first()

    if not user or not user.verify_password(user_data.password):
        raise HTTPException(
            status_code=401,
            detail="Kullanıcı adı veya şifre hatalı",
            headers={"WWW-Authenticate": "Bearer"},
        )

    if not user.is_active:
        raise HTTPException(status_code=400, detail="Hesap devre dışı")

    user.last_login = datetime.utcnow()
    session.commit()

    access_token = create_access_token(data={"sub": user.username})

    return Token(
        access_token=access_token,
        token_type="bearer",
        user={
            "id": user.id,
            "username": user.username,
            "email": user.email,
            "role": user.role
        }
    )

@app.get("/auth/me")
def get_me(current_user: User = Depends(get_current_user)):
    return {
        "id": current_user.id,
        "username": current_user.username,
        "email": current_user.email,
        "role": current_user.role,
        "is_active": current_user.is_active,
        "created_at": current_user.created_at,
        "last_login": current_user.last_login
    }

# ============ USERS (admin-only) ============
@app.get("/users", response_model=List[UserPublic])
def get_users(
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_admin_user)
):
    return session.exec(select(User)).all()

@app.post("/users", response_model=UserPublic)
def create_user(
    user_data: UserCreate,
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_admin_user)
):
    existing_user = session.exec(
        select(User).where(User.username == user_data.username)
    ).first()
    if existing_user:
        raise HTTPException(status_code=400, detail="Bu kullanıcı adı zaten kayıtlı")

    existing_email = session.exec(
        select(User).where(User.email == user_data.email)
    ).first()
    if existing_email:
        raise HTTPException(status_code=400, detail="Bu e-posta zaten kayıtlı")

    user = User(
        username=user_data.username,
        email=user_data.email,
        password_hash=User.hash_password(user_data.password),
        role=user_data.role,
        is_active=user_data.is_active,
    )
    session.add(user)
    session.commit()
    session.refresh(user)
    return user


# ============ FILE UPLOAD (KML/KMZ) ============
UPLOAD_DIR = "uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)


def _build_safe_upload_path(filename: str) -> tuple[str, str]:
    original_filename = Path(filename).name
    extension = Path(original_filename.lower()).suffix
    if extension not in {".kml", ".kmz"}:
        raise HTTPException(status_code=400, detail="Only KML/KMZ files allowed")

    safe_filename = f"{uuid4().hex}{extension}"
    return original_filename, os.path.join(UPLOAD_DIR, safe_filename)

@app.post("/upload-kml")
async def upload_kml(
    file: UploadFile = File(...),
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_admin_user),
):
    if not file.filename:
        raise HTTPException(status_code=400, detail="Filename is missing")

    original_filename, filepath = _build_safe_upload_path(file.filename)

    try:
        content = await file.read()
        if original_filename.lower().endswith('.kmz'):
            content = extract_kmz(content)

        course_name, coordinates = parse_kml_content(content)

        course = Course(
            name=course_name,
            description=f"Imported from {original_filename}",
            distance_km=None,
        )
        session.add(course)
        session.commit()
        session.refresh(course)

        for index, (lat, lon) in enumerate(coordinates):
            checkpoint = Checkpoint(
                order=index + 1,
                latitude=lat,
                longitude=lon,
                course_id=course.id,
            )
            session.add(checkpoint)

        session.commit()

        with open(filepath, "wb") as f:
            f.write(content)

        return {
            "filename": original_filename,
            "path": filepath,
            "status": "uploaded",
            "course_id": course.id,
            "course_name": course_name,
            "checkpoints_count": len(coordinates),
        }

    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error processing file: {str(e)}")
