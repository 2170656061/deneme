from typing import List, Optional
from datetime import datetime
from sqlmodel import Field, Relationship, SQLModel
from passlib.context import CryptContext

# Password hashing context
pwd_context = CryptContext(schemes=["pbkdf2_sha256"], deprecated="auto")


# 0. User (Admin and Runners)
class User(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    username: str = Field(index=True, unique=True)
    email: str = Field(index=True, unique=True)
    password_hash: str
    role: str = "runner"  # "admin" or "runner"
    is_active: bool = True
    created_at: datetime = Field(default_factory=datetime.utcnow)
    last_login: Optional[datetime] = None

    def verify_password(self, password: str) -> bool:
        """Verify a plain password against the hash"""
        if not self.password_hash:
            return False
        try:
            return pwd_context.verify(password, self.password_hash)
        except Exception:
            return False

    @staticmethod
    def hash_password(password: str) -> str:
        """Hash a plain password"""
        return pwd_context.hash(password)


# 1. The Course (e.g., "Park Run 5K")
class Course(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    name: str
    description: Optional[str] = None
    distance_km: Optional[float] = None
    checkpoints: List["Checkpoint"] = Relationship(back_populates="course")


# 2. The Checkpoints (The targets the runner must find)
class Checkpoint(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    order: int
    latitude: float
    longitude: float
    course_id: int = Field(foreign_key="course.id")
    course: Optional[Course] = Relationship(back_populates="checkpoints")


# 3. The Result (What Flutter sends back at the end)
class RaceResult(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    user_id: int = Field(foreign_key="user.id")
    course_id: int = Field(foreign_key="course.id")
    total_time_seconds: float
    completed_at: datetime = Field(default_factory=datetime.utcnow)
