# server/server.py
import asyncio
import websockets
import base64
import cv2
import numpy as np
import json
import hashlib
import os

# Путь к файлу с данными пользователей
USER_DATA_FILE = 'users.json'

# Инициализация MediaPipe Hands
import mediapipe as mp
mp_hands = mp.solutions.hands
mp_drawing = mp.solutions.drawing_utils
hands = mp_hands.Hands(static_image_mode=False, max_num_hands=1, min_detection_confidence=0.7)

def load_users():
    if os.path.exists(USER_DATA_FILE):
        with open(USER_DATA_FILE, 'r', encoding='utf-8') as f:
            return json.load(f)
    return {}

def save_users(users):
    with open(USER_DATA_FILE, 'w', encoding='utf-8') as f:
        json.dump(users, f, indent=4, ensure_ascii=False)

# Функция для хеширования пароля (для безопасности)
def hash_password(password):
    return hashlib.sha256(password.encode()).hexdigest()

def recognize_gesture(landmarks):
    def is_finger_up(start_idx, mid_idx, end_idx):
        return landmarks[end_idx].y < landmarks[mid_idx].y < landmarks[start_idx].y

    finger_states = {
        "thumb": landmarks[4].x < landmarks[3].x,
        "index": is_finger_up(5, 6, 8),
        "middle": is_finger_up(9, 10, 12),
        "ring": is_finger_up(13, 14, 16),
        "pinky": is_finger_up(17, 18, 20),
    }

    if all(finger_states.values()):
        return "Open Palm"
    elif not any(finger_states.values()):
        return "Fist"
    elif finger_states["thumb"] and not any([finger_states["index"], finger_states["middle"], finger_states["ring"], finger_states["pinky"]]):
        return "Thumbs Up"
    elif finger_states["index"] and finger_states["middle"] and not any([finger_states["thumb"], finger_states["ring"], finger_states["pinky"]]):
        return "Victory"
    elif finger_states["index"] and not any([finger_states["thumb"], finger_states["middle"], finger_states["ring"], finger_states["pinky"]]):
        return "Pointing"
    elif finger_states["index"] and finger_states["pinky"] and not any([finger_states["thumb"], finger_states["middle"], finger_states["ring"]]):
        return "Rock"
    else:
        return "Unknown"

def process_frame(frame):
    image_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    results = hands.process(image_rgb)
    if results.multi_hand_landmarks:
        for hand_landmarks in results.multi_hand_landmarks:
            gesture = recognize_gesture(hand_landmarks.landmark)
            return gesture
    return "No Hand"

# Функции для обработки различных типов запросов

# Обработка запросов на аутентификацию
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
                        "role": users[email].get("role", "user"),
                        "profileImage": users[email].get("photo", ""),
                        "completedTests": users[email].get("completedTests", [])
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
            "name": email.split('@')[0],
            "photo": "",
            "role": role,
            "completedTests": []
        }
        save_users(users)
        print(f"User registered: {email}")

        return {"status": "success", "message": "User registered successfully"}

    return {"status": "error", "message": "Invalid action"}

# Обработка запросов на обновление данных пользователя
def handle_user_request(request, users):
    action = request.get('action')

    if action == 'update_tests':
        username = request.get('username') or request.get('email')
        completed_tests = request.get('completedTests', [])

        if username in users:
            users[username]["completedTests"] = completed_tests
            save_users(users)
            print(f"Updated tests for {username}: {len(completed_tests)} tests")
            return {"status": "success", "message": "Tests updated successfully"}
        else:
            return {"status": "error", "message": "User not found"}

    elif action == 'update_profile':
        username = request.get('username') or request.get('email')
        data = request.get('data', {})

        if username in users:
            user_data = users[username]

            # Обновляем имя пользователя (если оно изменилось)
            new_username = data.get('username')
            if new_username and new_username != username:
                users[new_username] = user_data
                del users[username]
                username = new_username

            # Обновляем фото профиля, если оно предоставлено
            if 'profileImage' in data:
                users[username]['photo'] = data['profileImage']

            save_users(users)
            print(f"Profile updated for {username}")

            return {
                "status": "success",
                "message": "Profile updated successfully",
                "user": {
                    "username": username,
                    "password": users[username]["password"],
                    "role": users[username].get("role", "user"),
                    "profileImage": users[username].get("photo", ""),
                    "completedTests": users[username].get("completedTests", [])
                }
            }
        else:
            return {"status": "error", "message": "User not found"}

    elif action == 'reset_tests':
        username = request.get('username') or request.get('email')

        if username in users:
            users[username]["completedTests"] = []
            save_users(users)
            print(f"Tests reset for {username}")
            return {"status": "success", "message": "Tests reset successfully"}
        else:
            return {"status": "error", "message": "User not found"}

    return {"status": "error", "message": "Invalid action"}

# Обработчик входящих соединений
async def handle_connection(websocket):
    print(f"Client connected from {websocket.remote_address}")
    users = load_users()

    try:
        async for message in websocket:
            try:
                request = json.loads(message)
                request_type = request.get('type')

                print(f"Received request type: {request_type}")

                if request_type == 'auth':
                    response = handle_auth_request(request, users)
                    await websocket.send(json.dumps(response))

                elif request_type == 'user':
                    response = handle_user_request(request, users)
                    await websocket.send(json.dumps(response))

                elif request_type == 'gesture':
                    if request.get('action'):
                        # Это запрос на управление контентом жестов от админа
                        response = {"status": "success", "message": "Gesture action processed"}
                        await websocket.send(json.dumps(response))
                    else:
                        # Обрабатываем запрос на обработку фреймов с камеры
                        try:
                            img_data = base64.b64decode(request.get('image'))
                            np_arr = np.frombuffer(img_data, np.uint8)
                            frame = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)

                            if frame is not None:
                                gesture = process_frame(frame)
                                await websocket.send(json.dumps({"gesture": gesture}))
                            else:
                                await websocket.send(json.dumps({"gesture": "Error decoding frame"}))
                        except Exception as e:
                            print(f"Error processing gesture: {e}")
                            await websocket.send(json.dumps({"gesture": "Error processing image"}))

                elif request_type == 'alphabet':
                    response = {"status": "success", "message": "Alphabet action processed"}
                    await websocket.send(json.dumps(response))

                elif request_type == 'test':
                    response = {"status": "success", "message": "Test action processed"}
                    await websocket.send(json.dumps(response))

                else:
                    print(f"Invalid request type: {request_type}")
                    await websocket.send(json.dumps({"status": "error", "message": "Invalid request type"}))

            except json.JSONDecodeError as e:
                print(f"JSON decode error: {e}")
                await websocket.send(json.dumps({"status": "error", "message": "Invalid JSON"}))
            except Exception as e:
                print(f"Error processing message: {e}")
                await websocket.send(json.dumps({"status": "error", "message": "Error processing request"}))

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

    # Проверяем наличие файла с пользователями, создаем если его нет
    if not os.path.exists(USER_DATA_FILE):
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
        save_users(default_users)
        print(f"Created default users file: {USER_DATA_FILE}")

    print("Starting WebSocket server on ws://0.0.0.0:8765")
    async with websockets.serve(handle_connection, "0.0.0.0", 8765):
        print("Server started successfully!")
        await asyncio.Future()  # Run forever

if __name__ == "__main__":
    asyncio.run(main())