@echo off
REM Скрипт для полной пересборки Docker окружения
REM Запуск: rebuild.bat

echo ================================================
echo   ПОЛНАЯ ПЕРЕСБОРКА DOCKER ОКРУЖЕНИЯ
echo ================================================
echo.

echo [1/5] Останавливаем контейнеры...
docker-compose down

echo.
echo [2/5] Удаляем volumes (БД будет удалена!)...
docker volume rm cp_postgres_data 2>nul
if %errorlevel% neq 0 (
    echo Volume не найден или уже удален
)

echo.
echo [3/5] Пересобираем образы...
docker-compose build --no-cache

echo.
echo [4/5] Запускаем контейнеры...
docker-compose up -d

echo.
echo [5/5] Ожидание инициализации БД (30 секунд)...
timeout /t 30 /nobreak

echo.
echo ================================================
echo   ПЕРЕСБОРКА ЗАВЕРШЕНА
echo ================================================
echo.
echo Проверьте логи:
echo   docker-compose logs backend
echo   docker-compose logs db
echo.
echo Откройте Swagger UI:
echo   start http://localhost:8000/docs
echo.
echo Запустите автотесты:
echo   python test_api.py
echo.
pause
