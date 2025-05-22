import mediapipe as mp
import cv2
import numpy as np

mp_hands = mp.solutions.hands
hands = mp_hands.Hands(static_image_mode=False, max_num_hands=1, min_detection_confidence=0.7)
mp_drawing = mp.solutions.drawing_utils

def recognize_gesture(image_bytes):
    # Преобразуем байты в изображение
    nparr = np.frombuffer(image_bytes, np.uint8)
    frame = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)

    results = hands.process(frame_rgb)
    if not results.multi_hand_landmarks:
        return "no_hand"

    landmarks = results.multi_hand_landmarks[0].landmark
    fingers = []

    # Примитивная логика определения жестов
    tips = [8, 12, 16, 20]  # пальцы, кроме большого
    for tip in tips:
        if landmarks[tip].y < landmarks[tip - 2].y:
            fingers.append(1)
        else:
            fingers.append(0)

    thumb = landmarks[4].x > landmarks[3].x

    # Простые условия
    if fingers == [0, 0, 0, 0] and not thumb:
        return "fist"
    elif fingers == [1, 1, 0, 0]:
        return "v"
    elif fingers == [1, 1, 1, 1] and thumb:
        return "open"
    elif fingers == [0, 0, 0, 0] and thumb:
        return "like"
    else:
        return "unknown"
