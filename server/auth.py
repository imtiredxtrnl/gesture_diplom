import json
import os
import hashlib

USERS_FILE = "user_data.json"

# Создаём JSON-файл, если его нет
if not os.path.exists(USERS_FILE):
    with open(USERS_FILE, "w") as f:
        json.dump([], f)

def hash_password(password):
    return hashlib.sha256(password.encode()).hexdigest()

def load_users():
    with open(USERS_FILE, "r") as f:
        return json.load(f)

def save_users(users):
    with open(USERS_FILE, "w") as f:
        json.dump(users, f, indent=2)

def register_user(username, password, profile_image=None):
    users = load_users()
    if any(u["username"] == username for u in users):
        return {"status": "error", "message": "Username already exists."}
    users.append({
        "username": username,
        "password": hash_password(password),
        "profile_image": profile_image
    })
    save_users(users)
    return {"status": "success", "message": "User registered successfully."}

def login_user(username, password):
    users = load_users()
    hashed = hash_password(password)
    for user in users:
        if user["username"] == username and user["password"] == hashed:
            return {"status": "success", "user": user}
    return {"status": "error", "message": "Invalid username or password."}
