# server/server.py
import asyncio
import websockets
import base64
import cv2
import numpy as np
import json
import hashlib
import os
import uuid
from datetime import datetime
from deep_translator import GoogleTranslator

# Путь к файлам данных
USER_DATA_FILE = 'users.json'
GESTURES_DATA_FILE = 'gestures.json'
TESTS_DATA_FILE = 'tests.json'
ALPHABET_DATA_FILE = 'alphabet.json'
NOTES_DATA_FILE = 'notes.json'

# Инициализация MediaPipe Hands
import mediapipe as mp
mp_hands = mp.solutions.hands
mp_drawing = mp.solutions.drawing_utils
hands = mp_hands.Hands(static_image_mode=False, max_num_hands=1, min_detection_confidence=0.7)

def load_json_file(file_path):
    if os.path.exists(file_path):
        with open(file_path, 'r', encoding='utf-8') as f:
            return json.load(f)
    return {}

def save_json_file(file_path, data):
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=4, ensure_ascii=False)

def hash_password(password):
    return hashlib.sha256(password.encode()).hexdigest()

def recognize_gesture(landmarks, language='uk'):
    def is_finger_up(start_idx, mid_idx, end_idx):
        return landmarks[end_idx].y < landmarks[mid_idx].y < landmarks[start_idx].y

    finger_states = {
        "thumb": landmarks[4].x < landmarks[3].x,
        "index": is_finger_up(5, 6, 8),
        "middle": is_finger_up(9, 10, 12),
        "ring": is_finger_up(13, 14, 16),
        "pinky": is_finger_up(17, 18, 20),
    }

    # Локализация жестів
    gestures_uk = {
        "open_palm": "Привіт",
        "fist": "Так",
        "thumbs_up": "Добре",
        "victory": "Молодець",
        "pointing": "Вказівний",
        "rock": "Рок",
        "unknown": "Невідомо"
    }
    gestures_en = {
        "open_palm": "Hello",
        "fist": "Yes",
        "thumbs_up": "Good",
        "victory": "Well done",
        "pointing": "Pointing",
        "rock": "Rock",
        "unknown": "Unknown"
    }
    g = gestures_uk if language == 'uk' else gestures_en

    if all(finger_states.values()):
        return g["open_palm"]
    elif not any(finger_states.values()):
        return g["fist"]
    elif finger_states["thumb"] and not any([finger_states["index"], finger_states["middle"], finger_states["ring"], finger_states["pinky"]]):
        return g["thumbs_up"]
    elif finger_states["index"] and finger_states["middle"] and not any([finger_states["thumb"], finger_states["ring"], finger_states["pinky"]]):
        return g["victory"]
    elif finger_states["index"] and not any([finger_states["thumb"], finger_states["middle"], finger_states["ring"], finger_states["pinky"]]):
        return g["pointing"]
    elif finger_states["index"] and finger_states["pinky"] and not any([finger_states["thumb"], finger_states["middle"], finger_states["ring"]]):
        return g["rock"]
    else:
        return g["unknown"]

def process_frame(frame, language='uk'):
    image_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    results = hands.process(image_rgb)
    if results.multi_hand_landmarks:
        for hand_landmarks in results.multi_hand_landmarks:
            gesture = recognize_gesture(hand_landmarks.landmark, language)
            return gesture
    return "No Hand"

def translate_note_text(text, src_lang, dest_lang):
    import re
    # Найти все [img:N] и заменить на плейсхолдеры
    img_pattern = re.compile(r'\[img:(\d+)\]')
    placeholders = []
    def repl(match):
        placeholders.append(match.group(0))
        return f'__IMG_{len(placeholders)-1}__'
    temp_text = img_pattern.sub(repl, text)
    # Перевести текст
    translated = GoogleTranslator(source=src_lang, target=dest_lang).translate(temp_text)
    # Вернуть плейсхолдеры обратно
    for idx, ph in enumerate(placeholders):
        translated = translated.replace(f'__IMG_{idx}__', ph)
    return translated

# ============== AUTH HANDLERS ==============
def handle_auth_request(request, users):
    action = request.get('action', 'login')

    if action == 'login':
        email = request.get('email') or request.get('username')
        password = request.get('password')

        print(f"Login attempt for: {email}")

        if email in users:
            if users[email]["password"] == password:
                response = {
                    "status": "Login successful",
                    "user": {
                        "username": email,
                        "password": password,
                        "name": users[email].get("name", ""),
                        "role": users[email].get("role", "user"),
                        "profileImage": users[email].get("photo", ""),
                        "completedTests": users[email].get("completedTests", []),
                        "completedNotes": users[email].get("completedNotes", []),
                        "completedGestures": users[email].get("completedGestures", [])
                    }
                }
                print(f"Login successful for {email} (role: {users[email].get('role', 'user')})")
                return response
            else:
                print(f"Invalid password for {email}")
                return {"status": "Invalid password"}
        else:
            print(f"User not found: {email}")
            return {"status": "User not found"}

    elif action == 'register':
        email = request.get('email') or request.get('username')
        password = request.get('password')
        role = request.get('role', 'user')

        if email in users:
            return {"status": "error", "message": "User already exists"}

        users[email] = {
            "password": password,
            "name": request.get("name", email.split('@')[0]),
            "photo": "",
            "role": role,
            "completedTests": [],
            "completedNotes": request.get("completedNotes", []),
            "completedGestures": request.get("completedGestures", [])
        }
        save_json_file(USER_DATA_FILE, users)
        print(f"User registered: {email}")

        return {"status": "success", "message": "User registered successfully"}

    return {"status": "error", "message": "Invalid action"}

# ============== USER HANDLERS ==============
def handle_user_request(request, users):
    action = request.get('action')

    if action == 'update_tests':
        username = request.get('username') or request.get('email')
        completed_tests = request.get('completedTests', [])

        if username in users:
            users[username]["completedTests"] = completed_tests
            save_json_file(USER_DATA_FILE, users)
            print(f"Updated tests for {username}: {len(completed_tests)} tests")
            return {"status": "success", "message": "Tests updated successfully"}
        else:
            return {"status": "error", "message": "User not found"}

    elif action == 'update_profile':
        username = request.get('username') or request.get('email')
        data = request.get('data', {})

        if username in users:
            user_data = users[username]

            new_username = data.get('username')
            if new_username and new_username != username:
                users[new_username] = user_data
                del users[username]
                username = new_username

            if 'profileImage' in data:
                users[username]['photo'] = data['profileImage']

            if 'name' in data:
                users[username]['name'] = data['name']

            # Обновляем completedNotes, completedGestures, completedTests только если они пришли в data
            for field in ['completedNotes', 'completedGestures', 'completedTests']:
                if field in data:
                    users[username][field] = data[field]
                elif field not in users[username]:
                    users[username][field] = []

            save_json_file(USER_DATA_FILE, users)
            print(f"Profile updated for {username}")

            return {
                "status": "success",
                "message": "Profile updated successfully",
                "user": {
                    "username": username,
                    "password": users[username]["password"],
                    "name": users[username].get("name", ""),
                    "role": users[username].get("role", "user"),
                    "profileImage": users[username].get("photo", ""),
                    "completedTests": users[username].get("completedTests", []),
                    "completedNotes": users[username].get("completedNotes", []),
                    "completedGestures": users[username].get("completedGestures", [])
                }
            }
        else:
            return {"status": "error", "message": "User not found"}

    elif action == 'reset_tests':
        username = request.get('username') or request.get('email')

        if username in users:
            users[username]["completedTests"] = []
            save_json_file(USER_DATA_FILE, users)
            print(f"Tests reset for {username}")
            return {"status": "success", "message": "Tests reset successfully"}
        else:
            return {"status": "error", "message": "User not found"}

    return {"status": "error", "message": "Invalid action"}

# ============== GESTURE HANDLERS ==============
def handle_gesture_request(request):
    action = request.get('action')
    language = request.get('language', 'uk')

    if action == 'get_all':
        gestures = load_json_file(GESTURES_DATA_FILE)
        return {
            "status": "success",
            "gestures": list(gestures.values()) if isinstance(gestures, dict) else gestures
        }

    elif action == 'create':
        gestures = load_json_file(GESTURES_DATA_FILE)
        if not isinstance(gestures, dict):
            gestures = {}

        gesture_id = str(uuid.uuid4())
        gesture_data = {
            "id": gesture_id,
            "name": request.get('name', ''),
            "description": request.get('description', ''),
            "category": request.get('category', 'basic'),
            "imagePath": request.get('imagePath', ''),
            "created_at": datetime.now().isoformat()
        }

        gestures[gesture_id] = gesture_data
        save_json_file(GESTURES_DATA_FILE, gestures)

        return {
            "status": "success",
            "message": "Gesture created successfully",
            "gesture": gesture_data
        }

    elif action == 'update':
        gestures = load_json_file(GESTURES_DATA_FILE)
        gesture_id = request.get('id')

        if gesture_id in gestures:
            gesture_data = gestures[gesture_id]
            gesture_data.update({
                "name": request.get('name', gesture_data.get('name')),
                "description": request.get('description', gesture_data.get('description')),
                "category": request.get('category', gesture_data.get('category')),
                "imagePath": request.get('imagePath', gesture_data.get('imagePath')),
                "updated_at": datetime.now().isoformat()
            })

            gestures[gesture_id] = gesture_data
            save_json_file(GESTURES_DATA_FILE, gestures)

            return {
                "status": "success",
                "message": "Gesture updated successfully",
                "gesture": gesture_data
            }
        else:
            return {"status": "error", "message": "Gesture not found"}

    elif action == 'delete':
        gestures = load_json_file(GESTURES_DATA_FILE)
        gesture_id = request.get('id')

        if gesture_id in gestures:
            deleted_gesture = gestures.pop(gesture_id)
            save_json_file(GESTURES_DATA_FILE, gestures)

            return {
                "status": "success",
                "message": "Gesture deleted successfully",
                "gesture": deleted_gesture
            }
        else:
            return {"status": "error", "message": "Gesture not found"}

    # Обработка распознавания жестов (существующий код)
    elif 'image' in request:
        try:
            img_data = base64.b64decode(request.get('image'))
            np_arr = np.frombuffer(img_data, np.uint8)
            frame = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)

            if frame is not None:
                gesture = process_frame(frame, language)
                return {"gesture": gesture}
            else:
                return {"gesture": "Error decoding frame"}
        except Exception as e:
            print(f"Error processing gesture: {e}")
            return {"gesture": "Error processing image"}

    return {"status": "error", "message": "Invalid gesture action"}

# ============== TEST HANDLERS ==============
def handle_test_request(request):
    action = request.get('action')

    if action == 'get_all':
        tests = load_json_file(TESTS_DATA_FILE)
        return {
            "status": "success",
            "tests": list(tests.values()) if isinstance(tests, dict) else tests
        }

    elif action == 'create':
        tests = load_json_file(TESTS_DATA_FILE)
        if not isinstance(tests, dict):
            tests = {}

        test_id = str(uuid.uuid4())
        test_data = {
            "id": test_id,
            "question": request.get('question', ''),
            "options": request.get('options', []),
            "correctOptionIndex": request.get('correctOptionIndex', 0),
            "category": request.get('category', 'basic'),
            "imagePath": request.get('imagePath', ''),
            "created_at": datetime.now().isoformat()
        }

        tests[test_id] = test_data
        save_json_file(TESTS_DATA_FILE, tests)

        return {
            "status": "success",
            "message": "Test created successfully",
            "test": test_data
        }

    elif action == 'update':
        tests = load_json_file(TESTS_DATA_FILE)
        test_id = request.get('id')

        if test_id in tests:
            test_data = tests[test_id]
            test_data.update({
                "question": request.get('question', test_data.get('question')),
                "options": request.get('options', test_data.get('options')),
                "correctOptionIndex": request.get('correctOptionIndex', test_data.get('correctOptionIndex')),
                "category": request.get('category', test_data.get('category')),
                "imagePath": request.get('imagePath', test_data.get('imagePath')),
                "updated_at": datetime.now().isoformat()
            })

            tests[test_id] = test_data
            save_json_file(TESTS_DATA_FILE, tests)

            return {
                "status": "success",
                "message": "Test updated successfully",
                "test": test_data
            }
        else:
            return {"status": "error", "message": "Test not found"}

    elif action == 'delete':
        tests = load_json_file(TESTS_DATA_FILE)
        test_id = request.get('id')

        if test_id in tests:
            deleted_test = tests.pop(test_id)
            save_json_file(TESTS_DATA_FILE, tests)

            return {
                "status": "success",
                "message": "Test deleted successfully",
                "test": deleted_test
            }
        else:
            return {"status": "error", "message": "Test not found"}

    return {"status": "error", "message": "Invalid test action"}

# ============== ALPHABET HANDLERS ==============
def handle_alphabet_request(request):
    action = request.get('action')

    if action == 'get_all':
        alphabet = load_json_file(ALPHABET_DATA_FILE)
        language = request.get('language', 'all')

        if language != 'all' and isinstance(alphabet, dict):
            filtered_alphabet = {k: v for k, v in alphabet.items() if v.get('language') == language}
            return {
                "status": "success",
                "letters": list(filtered_alphabet.values())
            }

        return {
            "status": "success",
            "letters": list(alphabet.values()) if isinstance(alphabet, dict) else alphabet
        }

    elif action == 'create':
        alphabet = load_json_file(ALPHABET_DATA_FILE)
        if not isinstance(alphabet, dict):
            alphabet = {}

        letter_id = str(uuid.uuid4())
        letter_data = {
            "id": letter_id,
            "letter": request.get('letter', ''),
            "language": request.get('language', 'uk'),
            "imagePath": request.get('imagePath', ''),
            "created_at": datetime.now().isoformat()
        }

        alphabet[letter_id] = letter_data
        save_json_file(ALPHABET_DATA_FILE, alphabet)

        return {
            "status": "success",
            "message": "Letter created successfully",
            "letter": letter_data
        }

    elif action == 'update':
        alphabet = load_json_file(ALPHABET_DATA_FILE)
        letter_id = request.get('id')

        if letter_id in alphabet:
            letter_data = alphabet[letter_id]
            letter_data.update({
                "letter": request.get('letter', letter_data.get('letter')),
                "language": request.get('language', letter_data.get('language')),
                "imagePath": request.get('imagePath', letter_data.get('imagePath')),
                "updated_at": datetime.now().isoformat()
            })

            alphabet[letter_id] = letter_data
            save_json_file(ALPHABET_DATA_FILE, alphabet)

            return {
                "status": "success",
                "message": "Letter updated successfully",
                "letter": letter_data
            }
        else:
            return {"status": "error", "message": "Letter not found"}

    elif action == 'delete':
        alphabet = load_json_file(ALPHABET_DATA_FILE)
        letter_id = request.get('id')

        if letter_id in alphabet:
            deleted_letter = alphabet.pop(letter_id)
            save_json_file(ALPHABET_DATA_FILE, alphabet)

            return {
                "status": "success",
                "message": "Letter deleted successfully",
                "letter": deleted_letter
            }
        else:
            return {"status": "error", "message": "Letter not found"}

    return {"status": "error", "message": "Invalid alphabet action"}

# ============== NOTE HANDLERS ==============
def handle_note_request(request):
    action = request.get('action')

    if action == 'get_all':
        notes = load_json_file(NOTES_DATA_FILE)
        language = request.get('language', 'all')
        if language != 'all' and isinstance(notes, dict):
            filtered_notes = {k: v for k, v in notes.items() if v.get('language') == language}
            return {
                "status": "success",
                "notes": list(filtered_notes.values())
            }
        return {
            "status": "success",
            "notes": list(notes.values()) if isinstance(notes, dict) else notes
        }

    elif action == 'get':
        notes = load_json_file(NOTES_DATA_FILE)
        note_id = request.get('id')
        if note_id in notes:
            note = notes[note_id]
            # Обработка markup [img:N]
            content = note.get('content', '')
            image_paths = note.get('imagePaths', [])
            images_base64 = []
            for path in image_paths:
                try:
                    with open(path, 'rb') as img_file:
                        images_base64.append(base64.b64encode(img_file.read()).decode('utf-8'))
                except Exception:
                    images_base64.append('')
            return {
                "status": "success",
                "note": note,
                "images": images_base64
            }
        else:
            return {"status": "error", "message": "Note not found"}

    elif action == 'create':
        notes = load_json_file(NOTES_DATA_FILE)
        if not isinstance(notes, dict):
            notes = {}
        # Автоинкремент id
        existing_ids = [int(k) for k in notes.keys() if k.isdigit()]
        new_id = str(max(existing_ids) + 1) if existing_ids else '1'
        # Автоинкремент groupId
        if 'groupId' in request and request['groupId']:
            group_id = request['groupId']
        else:
            existing_group_ids = [int(v['groupId'].replace('group_', '')) for v in notes.values() if 'groupId' in v and v['groupId'].startswith('group_') and v['groupId'][6:].isdigit()]
            new_group_id_num = max(existing_group_ids) + 1 if existing_group_ids else 1
            group_id = f'group_{new_group_id_num}'
        note_data = {
            "id": new_id,
            "groupId": group_id,
            "title": request.get('title', ''),
            "content": request.get('content', ''),
            "imagePaths": request.get('imagePaths', []),
            "language": request.get('language', 'uk'),
            "created_at": datetime.now().isoformat(),
            "updated_at": datetime.now().isoformat()
        }
        notes[new_id] = note_data
        save_json_file(NOTES_DATA_FILE, notes)
        return {
            "status": "success",
            "message": "Note created successfully",
            "note": note_data
        }

    elif action == 'update':
        notes = load_json_file(NOTES_DATA_FILE)
        note_id = request.get('id')
        if note_id in notes:
            note_data = notes[note_id]
            note_data.update({
                "title": request.get('title', note_data.get('title')),
                "content": request.get('content', note_data.get('content')),
                "imagePaths": request.get('imagePaths', note_data.get('imagePaths')),
                "language": request.get('language', note_data.get('language')),
                "updated_at": datetime.now().isoformat()
            })
            notes[note_id] = note_data
            save_json_file(NOTES_DATA_FILE, notes)
            return {
                "status": "success",
                "message": "Note updated successfully",
                "note": note_data
            }
        else:
            return {"status": "error", "message": "Note not found"}

    elif action == 'delete':
        notes = load_json_file(NOTES_DATA_FILE)
        note_id = request.get('id')
        if note_id in notes:
            deleted_note = notes.pop(note_id)
            save_json_file(NOTES_DATA_FILE, notes)
            return {
                "status": "success",
                "message": "Note deleted successfully",
                "note": deleted_note
            }
        else:
            return {"status": "error", "message": "Note not found"}

    elif action == 'upload_image':
        # Для drag-n-drop PNG загрузки
        image_data = request.get('image')  # base64
        filename = request.get('filename', f"note_{uuid.uuid4()}.png")
        save_dir = os.path.join('data', 'notes')
        os.makedirs(save_dir, exist_ok=True)
        file_path = os.path.join(save_dir, filename)
        try:
            with open(file_path, 'wb') as f:
                f.write(base64.b64decode(image_data))
            return {"status": "success", "path": file_path}
        except Exception as e:
            return {"status": "error", "message": str(e)}

    return {"status": "error", "message": "Invalid note action"}

# ============== MAIN HANDLER ==============
async def handle_connection(websocket):
    print(f"Client connected from {websocket.remote_address}")
    users = load_json_file(USER_DATA_FILE)

    try:
        async for message in websocket:
            try:
                print(f"Received raw message: {message}")  # Выводим тело запроса
                request = json.loads(message)
                request_type = request.get('type')

                print(f"Received request type: {request_type}")

                if request_type == 'auth':
                    response = handle_auth_request(request, users)
                    print(f"Sending response: {json.dumps(response, ensure_ascii=False)}")
                    await websocket.send(json.dumps(response))

                elif request_type == 'user':
                    response = handle_user_request(request, users)
                    print(f"Sending response: {json.dumps(response, ensure_ascii=False)}")
                    await websocket.send(json.dumps(response))

                elif request_type == 'gesture':
                    response = handle_gesture_request(request)
                    print(f"Sending response: {json.dumps(response, ensure_ascii=False)}")
                    await websocket.send(json.dumps(response))

                elif request_type == 'gestures':
                    gestures = load_json_file(GESTURES_DATA_FILE)
                    gesture_list = []
                    for gesture in (gestures.values() if isinstance(gestures, dict) else gestures):
                        gesture_copy = dict(gesture)
                        image_path = gesture_copy.get('imagePath', '')
                        try:
                            with open(image_path, 'rb') as img_file:
                                gesture_copy['imageBase64'] = base64.b64encode(img_file.read()).decode('utf-8')
                        except Exception as e:
                            gesture_copy['imageBase64'] = ''
                        gesture_list.append(gesture_copy)
                    response = {
                        "status": "success",
                        "gestures": gesture_list
                    }
                    print(f"Sending response: {json.dumps(response, ensure_ascii=False)[:500]} ...")
                    await websocket.send(json.dumps(response))

                elif request_type == 'test':
                    response = handle_test_request(request)
                    print(f"Sending response: {json.dumps(response, ensure_ascii=False)}")
                    await websocket.send(json.dumps(response))

                elif request_type == 'alphabet':
                    response = handle_alphabet_request(request)
                    print(f"Sending response: {json.dumps(response, ensure_ascii=False)}")
                    await websocket.send(json.dumps(response))

                elif request_type == 'note':
                    response = handle_note_request(request)
                    print(f"Sending response: {json.dumps(response, ensure_ascii=False)[:500]} ...")
                    await websocket.send(json.dumps(response))

                elif request_type == 'note_translate':
                    text = request.get('text', '')
                    src_lang = request.get('src_lang', 'uk')
                    dest_lang = request.get('dest_lang', 'en')
                    try:
                        translated = translate_note_text(text, src_lang, dest_lang)
                        response = {"status": "success", "translated": translated}
                    except Exception as e:
                        response = {"status": "error", "message": str(e)}
                    await websocket.send(json.dumps(response))

                elif request_type == 'stats':
                    users = load_json_file(USER_DATA_FILE)
                    # Подсчёт уникальных пройденных конспектов всеми пользователями
                    completed_notes = set()
                    for u in users.values():
                        for note_id in u.get('completedNotes', []):
                            completed_notes.add(note_id)
                    response = {
                        "status": "success",
                        "users_count": len(users),
                        "completed_notes_count": len(completed_notes)
                    }
                    print(f"Sending response: {json.dumps(response, ensure_ascii=False)}")
                    await websocket.send(json.dumps(response))

                else:
                    print(f"Invalid request type: {request_type}")
                    error_resp = {"status": "error", "message": "Invalid request type"}
                    print(f"Sending response: {json.dumps(error_resp, ensure_ascii=False)}")
                    await websocket.send(json.dumps(error_resp))

            except json.JSONDecodeError as e:
                print(f"JSON decode error: {e}")
                error_resp = {"status": "error", "message": "Invalid JSON"}
                print(f"Sending response: {json.dumps(error_resp, ensure_ascii=False)}")
                await websocket.send(json.dumps(error_resp))
            except Exception as e:
                print(f"Error processing message: {e}")
                error_resp = {"status": "error", "message": "Error processing request"}
                print(f"Sending response: {json.dumps(error_resp, ensure_ascii=False)}")
                await websocket.send(json.dumps(error_resp))

    except websockets.exceptions.ConnectionClosed:
        print(f"Client {websocket.remote_address} disconnected")
    except Exception as e:
        print(f"Connection error: {e}")

async def main():
    # Создаем каталоги для хранения данных, если их нет
    os.makedirs('data/gestures', exist_ok=True)
    os.makedirs('data/alphabet/uk', exist_ok=True)
    os.makedirs('data/alphabet/en', exist_ok=True)
    os.makedirs('data/tests', exist_ok=True)

    # Проверяем наличие файлов данных, создаем если их нет
    if not os.path.exists(USER_DATA_FILE):
        default_users = {
            "user@example.com": {
                "password": "user123",
                "name": "User",
                "photo": "",
                "role": "user",
                "completedTests": [],
                "completedNotes": [],
                "completedGestures": []
            },
            "admin@example.com": {
                "password": "admin123",
                "name": "Admin",
                "photo": "",
                "role": "admin",
                "completedTests": [],
                "completedNotes": [],
                "completedGestures": []
            }
        }
        save_json_file(USER_DATA_FILE, default_users)
        print(f"Created default users file: {USER_DATA_FILE}")

    # Создаем файлы для жестов, тестов и алфавита, если их нет
    if not os.path.exists(GESTURES_DATA_FILE):
        default_gestures = {}
        save_json_file(GESTURES_DATA_FILE, default_gestures)
        print(f"Created gestures file: {GESTURES_DATA_FILE}")

    if not os.path.exists(TESTS_DATA_FILE):
        default_tests = {}
        save_json_file(TESTS_DATA_FILE, default_tests)
        print(f"Created tests file: {TESTS_DATA_FILE}")

    if not os.path.exists(ALPHABET_DATA_FILE):
        default_alphabet = {}
        save_json_file(ALPHABET_DATA_FILE, default_alphabet)
        print(f"Created alphabet file: {ALPHABET_DATA_FILE}")

    if not os.path.exists(NOTES_DATA_FILE):
        default_notes = {}
        save_json_file(NOTES_DATA_FILE, default_notes)
        print(f"Created notes file: {NOTES_DATA_FILE}")

    # В структуре пользователя добавляем completedNotes если его нет
    users = load_json_file(USER_DATA_FILE)
    for user in users.values():
        if 'completedNotes' not in user:
            user['completedNotes'] = []
    save_json_file(USER_DATA_FILE, users)

    print("Starting WebSocket server on ws://0.0.0.0:8765")
    async with websockets.serve(handle_connection, "0.0.0.0", 8765):
        print("Server started successfully!")
        await asyncio.Future()  # Run forever

if __name__ == "__main__":
    asyncio.run(main())