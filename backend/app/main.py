"""
Main FastAPI application
Competitive Programming Contest Management System
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routes import users, contests, problems, submissions, analytics, batch

app = FastAPI(
    title="Competitive Programming Contest Management System",
    description="""
    Система управления соревнованиями по спортивному программированию
    
    Основные возможности:
    - Users: Управление пользователями (участники, жюри, администраторы)
    - Contests: Создание и управление соревнованиями
    - Problems: Управление задачами с ограничениями
    - Submissions: Прием и оценка решений
    - Analytics: Аналитика и отчеты (использует VIEW и SQL функции)
    - Batch Import: Массовая загрузка данных с логированием ошибок
    
    Технологический стек:
    - Python 3.11
    - FastAPI
    - PostgreSQL 15
    - SQLAlchemy
    - Docker & docker-compose
    
    Особенности БД:
    - 10 таблиц со связями 1:1, 1:N, N:M
    - Триггеры для аудита и автообновления агрегатов
    - Скалярные и табличные SQL функции
    - 5 представлений для аналитики
    - Индексы для оптимизации запросов
    """,
    version="1.0.0",
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(users.router)
app.include_router(contests.router)
app.include_router(problems.router)
app.include_router(submissions.router)
app.include_router(analytics.router)
app.include_router(batch.router)


@app.get("/", tags=["root"])
def read_root():
    """Root endpoint with API information"""
    return {
        "message": "Competitive Programming Contest Management System API",
        "version": "1.0.0",
        "docs": "/docs",
        "health": "/health"
    }


@app.get("/health", tags=["root"])
def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "service": "cp-contest-api"}
