"""
Автоматическое тестирование API endpoints
Запуск: python test_api.py
"""
import requests
import json
from datetime import datetime, timedelta

BASE_URL = "http://localhost:8000"

class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    END = '\033[0m'

def print_test(name, status, details=""):
    symbol = "✓" if status else "✗"
    color = Colors.GREEN if status else Colors.RED
    print(f"{color}{symbol} {name}{Colors.END}")
    if details:
        print(f"  {details}")

def test_users():
    print(f"\n{Colors.BLUE}=== Тестирование Users ==={Colors.END}")
    
    # Тест 1: Создание нового пользователя
    user_data = {
        "username": f"testuser_{datetime.now().timestamp()}",
        "email": f"test_{datetime.now().timestamp()}@example.com",
        "full_name": "Test User",
        "role": "participant",
        "rating": 1500,
        "country": "Russia"
    }
    response = requests.post(f"{BASE_URL}/users/", json=user_data)
    print_test("Создание пользователя", response.status_code == 201, f"Status: {response.status_code}")
    
    if response.status_code == 201:
        user_id = response.json()["user_id"]
        
        # Тест 2: Попытка создать дубликат username
        dup_user = user_data.copy()
        response = requests.post(f"{BASE_URL}/users/", json=dup_user)
        print_test("Дубликат username (должен быть 409)", 
                   response.status_code == 409, 
                   f"Status: {response.status_code}, Detail: {response.json().get('detail', 'N/A')[:100]}")
        
        # Тест 3: Получение пользователя по ID
        response = requests.get(f"{BASE_URL}/users/{user_id}")
        print_test("Получение пользователя по ID", response.status_code == 200, f"Status: {response.status_code}")
        
        # Тест 4: Обновление пользователя
        update_data = {"rating": 1600}
        response = requests.put(f"{BASE_URL}/users/{user_id}", json=update_data)
        print_test("Обновление пользователя", response.status_code == 200, f"Status: {response.status_code}")
        
        # Тест 5: Попытка обновить на существующий email
        another_user = {
            "username": f"another_{datetime.now().timestamp()}",
            "email": f"another_{datetime.now().timestamp()}@example.com",
            "full_name": "Another User",
            "role": "participant"
        }
        response2 = requests.post(f"{BASE_URL}/users/", json=another_user)
        if response2.status_code == 201:
            user_id2 = response2.json()["user_id"]
            # Пытаемся установить тот же email, что у первого пользователя
            conflict_update = {"email": user_data["email"]}
            response = requests.put(f"{BASE_URL}/users/{user_id2}", json=conflict_update)
            print_test("Обновление на существующий email (должен быть 409)", 
                       response.status_code == 409, 
                       f"Status: {response.status_code}")
    
    # Тест 6: Получение списка пользователей
    response = requests.get(f"{BASE_URL}/users/")
    print_test("Получение списка пользователей", response.status_code == 200, f"Status: {response.status_code}, Count: {len(response.json())}")
    
    # Тест 7: Несуществующий пользователь
    response = requests.get(f"{BASE_URL}/users/999999")
    print_test("Несуществующий пользователь (должен быть 404)", response.status_code == 404, f"Status: {response.status_code}")


def test_contests():
    print(f"\n{Colors.BLUE}=== Тестирование Contests ==={Colors.END}")
    
    # Получаем существующего пользователя для created_by
    users = requests.get(f"{BASE_URL}/users/").json()
    if not users:
        print_test("Пропуск - нет пользователей", False, "Создайте пользователей сначала")
        return
    
    creator_id = users[0]["user_id"]
    
    # Тест 1: Создание соревнования
    contest_data = {
        "title": f"Test Contest {datetime.now().timestamp()}",
        "description": "Test description",
        "contest_type": "Codeforces",
        "status": "upcoming",
        "start_time": (datetime.now() + timedelta(days=1)).isoformat(),
        "duration_minutes": 120,
        "created_by": creator_id
    }
    response = requests.post(f"{BASE_URL}/contests/", json=contest_data)
    print_test("Создание соревнования", response.status_code == 201, f"Status: {response.status_code}")
    
    if response.status_code == 201:
        contest_id = response.json()["contest_id"]
        
        # Тест 2: Получение соревнования
        response = requests.get(f"{BASE_URL}/contests/{contest_id}")
        print_test("Получение соревнования", response.status_code == 200, f"Status: {response.status_code}")
        
        # Тест 3: Обновление соревнования
        response = requests.put(f"{BASE_URL}/contests/{contest_id}", json={"status": "running"})
        print_test("Обновление соревнования", response.status_code == 200, f"Status: {response.status_code}")
    
    # Тест 4: Создание с несуществующим created_by
    invalid_contest = contest_data.copy()
    invalid_contest["created_by"] = 999999
    response = requests.post(f"{BASE_URL}/contests/", json=invalid_contest)
    print_test("Соревнование с несуществующим created_by (должен быть 400)", 
               response.status_code == 400, 
               f"Status: {response.status_code}")
    
    # Тест 5: Получение списка
    response = requests.get(f"{BASE_URL}/contests/")
    print_test("Получение списка соревнований", response.status_code == 200, f"Status: {response.status_code}, Count: {len(response.json())}")


def test_problems():
    print(f"\n{Colors.BLUE}=== Тестирование Problems ==={Colors.END}")
    
    # Получаем автора (jury или admin)
    users = requests.get(f"{BASE_URL}/users/").json()
    author = next((u for u in users if u.get("role") in ["jury", "admin"]), users[0] if users else None)
    
    if not author:
        print_test("Пропуск - нет пользователей", False, "Создайте пользователей сначала")
        return
    
    # Тест 1: Создание задачи
    problem_data = {
        "title": f"Test Problem {datetime.now().timestamp()}",
        "description": "Test problem description",
        "difficulty": "medium",
        "time_limit_ms": 1000,
        "memory_limit_mb": 256,
        "author_id": author["user_id"]
    }
    response = requests.post(f"{BASE_URL}/problems/", json=problem_data)
    print_test("Создание задачи", response.status_code == 201, f"Status: {response.status_code}")
    
    if response.status_code == 201:
        problem_id = response.json()["problem_id"]
        
        # Тест 2: Получение задачи
        response = requests.get(f"{BASE_URL}/problems/{problem_id}")
        print_test("Получение задачи", response.status_code == 200, f"Status: {response.status_code}")
    
    # Тест 3: Создание с несуществующим author_id
    invalid_problem = problem_data.copy()
    invalid_problem["author_id"] = 999999
    response = requests.post(f"{BASE_URL}/problems/", json=invalid_problem)
    print_test("Задача с несуществующим author_id (должен быть 400)", 
               response.status_code == 400, 
               f"Status: {response.status_code}")
    
    # Тест 4: Получение списка
    response = requests.get(f"{BASE_URL}/problems/")
    print_test("Получение списка задач", response.status_code == 200, f"Status: {response.status_code}, Count: {len(response.json())}")


def test_submissions():
    print(f"\n{Colors.BLUE}=== Тестирование Submissions ==={Colors.END}")
    
    # Получаем данные для создания посылки
    users = requests.get(f"{BASE_URL}/users/").json()
    contests = requests.get(f"{BASE_URL}/contests/").json()
    problems = requests.get(f"{BASE_URL}/problems/").json()
    
    if not (users and contests and problems):
        print_test("Пропуск - недостаточно данных", False, "Создайте пользователей, соревнования и задачи")
        return
    
    # Тест 1: Создание посылки
    submission_data = {
        "user_id": users[0]["user_id"],
        "contest_id": contests[0]["contest_id"],
        "problem_id": problems[0]["problem_id"],
        "language": "Python",
        "source_code": "print('Hello World')"
    }
    response = requests.post(f"{BASE_URL}/submissions/", json=submission_data)
    print_test("Создание посылки", response.status_code == 201, f"Status: {response.status_code}")
    
    if response.status_code == 201:
        submission_id = response.json()["submission_id"]
        
        # Тест 2: Обновление вердикта
        update_data = {"verdict": "accepted", "execution_time_ms": 150, "memory_used_mb": 2.048}
        response = requests.put(f"{BASE_URL}/submissions/{submission_id}", json=update_data)
        print_test("Обновление вердикта", response.status_code == 200, f"Status: {response.status_code}")
    
    # Тест 3: Посылка с несуществующими ID
    invalid_submission = submission_data.copy()
    invalid_submission["user_id"] = 999999
    response = requests.post(f"{BASE_URL}/submissions/", json=invalid_submission)
    print_test("Посылка с несуществующим user_id (должен быть 400)", 
               response.status_code == 400, 
               f"Status: {response.status_code}")
    
    # Тест 4: Получение списка
    response = requests.get(f"{BASE_URL}/submissions/")
    print_test("Получение списка посылок", response.status_code == 200, f"Status: {response.status_code}, Count: {len(response.json())}")


def test_batch():
    print(f"\n{Colors.BLUE}=== Тестирование Batch Import ==={Colors.END}")
    
    # Тест 1: Batch import пользователей с ошибками
    batch_data = {
        "entity_type": "users",
        "data": [
            {
                "username": f"batch_user_1_{datetime.now().timestamp()}",
                "email": f"batch1_{datetime.now().timestamp()}@example.com",
                "full_name": "Batch User 1",
                "role": "participant"
            },
            {
                "username": f"batch_user_2_{datetime.now().timestamp()}",
                "email": "INVALID_EMAIL",  # Невалидный email
                "full_name": "Batch User 2",
                "role": "participant"
            },
            {
                "username": f"batch_user_3_{datetime.now().timestamp()}",
                "email": f"batch3_{datetime.now().timestamp()}@example.com",
                "full_name": "Batch User 3",
                "role": "invalid_role"  # Невалидная роль
            }
        ]
    }
    response = requests.post(f"{BASE_URL}/batch/import", json=batch_data)
    print_test("Batch import с частичными ошибками", 
               response.status_code in [200, 207], 
               f"Status: {response.status_code}")
    
    if response.status_code in [200, 207]:
        result = response.json()
        print(f"  Успешно: {result.get('success_count', 0)}, Ошибок: {len(result.get('errors', []))}")
        if result.get('errors'):
            print(f"  Первая ошибка: {result['errors'][0].get('error', 'N/A')[:100]}")


def test_analytics():
    print(f"\n{Colors.BLUE}=== Тестирование Analytics ==={Colors.END}")
    
    # Тест 1: Топ участников
    response = requests.get(f"{BASE_URL}/analytics/top-participants")
    print_test("Получение топ участников", response.status_code == 200, f"Status: {response.status_code}, Count: {len(response.json())}")
    
    # Тест 2: Статистика вердиктов
    response = requests.get(f"{BASE_URL}/analytics/verdict-stats")
    print_test("Статистика вердиктов", response.status_code == 200, f"Status: {response.status_code}")
    
    # Тест 3: Активность пользователей
    response = requests.get(f"{BASE_URL}/analytics/user-activity")
    print_test("Активность пользователей", response.status_code == 200, f"Status: {response.status_code}")


def main():
    print(f"\n{Colors.YELLOW}{'='*60}")
    print(f"  АВТОМАТИЧЕСКОЕ ТЕСТИРОВАНИЕ API")
    print(f"  Base URL: {BASE_URL}")
    print(f"{'='*60}{Colors.END}\n")
    
    try:
        # Проверка доступности API
        response = requests.get(f"{BASE_URL}/docs")
        if response.status_code != 200:
            print(f"{Colors.RED}Ошибка: API недоступен на {BASE_URL}{Colors.END}")
            print("Убедитесь, что Docker контейнеры запущены: docker-compose up -d")
            return
        
        test_users()
        test_contests()
        test_problems()
        test_submissions()
        test_batch()
        test_analytics()
        
        print(f"\n{Colors.YELLOW}{'='*60}")
        print(f"  ТЕСТИРОВАНИЕ ЗАВЕРШЕНО")
        print(f"{'='*60}{Colors.END}\n")
        
    except requests.exceptions.ConnectionError:
        print(f"{Colors.RED}Ошибка подключения к {BASE_URL}{Colors.END}")
        print("Убедитесь, что Docker контейнеры запущены: docker-compose up -d")
    except Exception as e:
        print(f"{Colors.RED}Неожиданная ошибка: {e}{Colors.END}")


if __name__ == "__main__":
    main()
