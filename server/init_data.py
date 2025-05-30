# server/init_data.py
import json
import os
from datetime import datetime

def create_default_data():
    """Создает файлы с данными по умолчанию"""

    # Создаем директории если их нет
    os.makedirs('data/gestures', exist_ok=True)
    os.makedirs('data/alphabet/uk', exist_ok=True)
    os.makedirs('data/alphabet/en', exist_ok=True)
    os.makedirs('data/tests', exist_ok=True)

    # Данные пользователей по умолчанию
    default_users = {
        "user@example.com": {
            "password": "user123",
            "name": "User",
            "photo": "",
            "role": "user",
            "completedTests": []
        },
        "admin@example.com": {
            "password": "admin123",
            "name": "Admin",
            "photo": "",
            "role": "admin",
            "completedTests": []
        }
    }

    # Жесты по умолчанию
    default_gestures = {
        "gesture_1": {
            "id": "gesture_1",
            "name": "Привет",
            "description": "Жест приветствия. Поднимите руку с раскрытой ладонью и помашите ей из стороны в сторону.",
            "category": "greetings",
            "imagePath": "assets/gestures/hello.png",
            "created_at": datetime.now().isoformat()
        },
        "gesture_2": {
            "id": "gesture_2",
            "name": "Спасибо",
            "description": "Жест благодарности. Прикоснитесь кончиками пальцев к губам, затем опустите руку вперед.",
            "category": "basic",
            "imagePath": "assets/gestures/thank_you.png",
            "created_at": datetime.now().isoformat()
        },
        "gesture_3": {
            "id": "gesture_3",
            "name": "Пожалуйста",
            "description": "Жест вежливой просьбы. Положите открытую ладонь на грудь и сделайте круговое движение.",
            "category": "basic",
            "imagePath": "assets/gestures/please.png",
            "created_at": datetime.now().isoformat()
        },
        "gesture_4": {
            "id": "gesture_4",
            "name": "Да",
            "description": "Жест согласия. Покажите большой палец вверх или кивните головой вверх-вниз.",
            "category": "basic",
            "imagePath": "assets/gestures/yes.png",
            "created_at": datetime.now().isoformat()
        },
        "gesture_5": {
            "id": "gesture_5",
            "name": "Нет",
            "description": "Жест отрицания. Покачайте головой из стороны в сторону или покажите указательным пальцем.",
            "category": "basic",
            "imagePath": "assets/gestures/no.png",
            "created_at": datetime.now().isoformat()
        },
        "gesture_6": {
            "id": "gesture_6",
            "name": "Хорошо",
            "description": "Жест одобрения. Сформируйте кольцо из большого и указательного пальца (знак ОК).",
            "category": "emotions",
            "imagePath": "assets/gestures/ok.png",
            "created_at": datetime.now().isoformat()
        }
    }

    # Тесты по умолчанию
    default_tests = {
        "test_1": {
            "id": "test_1",
            "question": "Какой жест используется для приветствия?",
            "options": [
                "Поднятая рука с раскрытой ладонью",
                "Сжатый кулак",
                "Указательный палец вверх",
                "Две руки скрещены на груди"
            ],
            "correctOptionIndex": 0,
            "category": "greetings",
            "imagePath": "assets/tests/test1.png",
            "created_at": datetime.now().isoformat()
        },
        "test_2": {
            "id": "test_2",
            "question": "Как показать жест 'Спасибо'?",
            "options": [
                "Сжатый кулак",
                "Рука прикладывается к губам и опускается вперед",
                "Руки скрещены над головой",
                "Большой палец вверх"
            ],
            "correctOptionIndex": 1,
            "category": "basic",
            "imagePath": "assets/tests/test2.png",
            "created_at": datetime.now().isoformat()
        },
        "test_3": {
            "id": "test_3",
            "question": "Какой жест означает 'Да'?",
            "options": [
                "Качание головой влево-вправо",
                "Кивание головой вверх-вниз",
                "Поднятие плеч",
                "Указание пальцем"
            ],
            "correctOptionIndex": 1,
            "category": "basic",
            "imagePath": "assets/tests/test3.png",
            "created_at": datetime.now().isoformat()
        },
        "test_4": {
            "id": "test_4",
            "question": "Как правильно показать жест 'Хорошо'?",
            "options": [
                "Большой палец вниз",
                "Сжатый кулак",
                "Кольцо из большого и указательного пальца",
                "Открытая ладонь"
            ],
            "correctOptionIndex": 2,
            "category": "emotions",
            "imagePath": "assets/tests/test4.png",
            "created_at": datetime.now().isoformat()
        }
    }

    # Украинский алфавит по умолчанию
    ukrainian_letters = ['А', 'Б', 'В', 'Г', 'Д', 'Е', 'Є', 'Ж', 'З', 'И', 'І', 'Ї', 'Й', 'К', 'Л']
    default_alphabet = {}

    for i, letter in enumerate(ukrainian_letters):
        letter_id = f"uk_{letter.lower()}"
        default_alphabet[letter_id] = {
            "id": letter_id,
            "letter": letter,
            "language": "uk",
            "imagePath": f"assets/alphabet/uk/{letter.lower()}.png",
            "created_at": datetime.now().isoformat()
        }

    # Английский алфавит (первые несколько букв)
    english_letters = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M']

    for i, letter in enumerate(english_letters):
        letter_id = f"en_{letter.lower()}"
        default_alphabet[letter_id] = {
            "id": letter_id,
            "letter": letter,
            "language": "en",
            "imagePath": f"assets/alphabet/en/{letter.lower()}.png",
            "created_at": datetime.now().isoformat()
        }

    # Сохраняем файлы
    with open('users.json', 'w', encoding='utf-8') as f:
        json.dump(default_users, f, indent=4, ensure_ascii=False)

    with open('gestures.json', 'w', encoding='utf-8') as f:
        json.dump(default_gestures, f, indent=4, ensure_ascii=False)

    with open('tests.json', 'w', encoding='utf-8') as f:
        json.dump(default_tests, f, indent=4, ensure_ascii=False)

    with open('alphabet.json', 'w', encoding='utf-8') as f:
        json.dump(default_alphabet, f, indent=4, ensure_ascii=False)

    print("✅ Файлы данных по умолчанию созданы:")
    print("   - users.json")
    print("   - gestures.json")
    print("   - tests.json")
    print("   - alphabet.json")
    print("\n🔑 Данные для входа:")
    print("   Админ: admin@example.com / admin123")
    print("   Пользователь: user@example.com / user123")

if __name__ == "__main__":
    create_default_data()