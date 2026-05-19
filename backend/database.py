from sqlmodel import create_engine, Session, SQLModel
import os


def _env_bool(name: str, default: bool = False) -> bool:
    value = os.getenv(name)
    if value is None:
        return default
    return value.strip().lower() in {"1", "true", "yes", "on"}

DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://user:password@localhost:5433/orienteering"
)
SQL_ECHO = _env_bool("SQL_ECHO", default=False)
engine = create_engine(DATABASE_URL, echo=SQL_ECHO)

def create_db_and_tables():
    SQLModel.metadata.create_all(engine)

def get_session():
    with Session(engine) as session:
        yield session

def init_db():
    SQLModel.metadata.create_all(engine)
