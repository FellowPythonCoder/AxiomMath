from flask import Flask, jsonify, request
from flask_cors import CORS
from werkzeug.security import generate_password_hash, check_password_hash
import sqlite3
import ctypes
import random
import re
import os

import lesson_generator

app = Flask(__name__)
CORS(app)

DB_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'axiom.db')
EMAIL_PATTERN = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")

try:
    lib = ctypes.CDLL('./libmathengine.dylib')
    lib.get_fast_math.argtypes = [ctypes.c_int, ctypes.c_char_p, ctypes.c_int, ctypes.c_char_p, ctypes.c_int]
    lib.get_fast_math.restype = None
except Exception:
    lib = None

def get_db():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    conn = get_db()
    with open('schema.sql', 'r') as f:
        conn.executescript(f.read())
    conn.commit()
    conn.close()

def user_to_dict(row):
    return {
        "user_id": row["id"],
        "full_name": row["full_name"],
        "email": row["email"],
        "grade": row["grade"],
        "has_selected_grade": bool(row["has_selected_grade"]),
        "xp": row["xp"],
        "coins": row["coins"],
        "points": row["points"],
        "challenge_streak": row["challenge_streak"],
        "last_challenge_date": row["last_challenge_date"],
    }

def c_generate_question(grade, qid):
    if not lib:
        return None
    q_buf = ctypes.create_string_buffer(100)
    a_buf = ctypes.create_string_buffer(100)
    lib.get_fast_math(grade, q_buf, 100, a_buf, 100)
    q_str = q_buf.value.decode('utf-8')
    a_str = a_buf.value.decode('utf-8')
    correct_int = int(a_str)
    options = [str(correct_int + 2), str(abs(correct_int - 1)), a_str]
    random.shuffle(options)
    return {
        "id": qid,
        "title": "Fast Math Challenge",
        "question": q_str,
        "options": options,
        "correct_answer": a_str,
        "source": "c"
    }

def python_generate_question(grade, qid):
    lesson = lesson_generator.generate_single_lesson(grade, qid)
    lesson["source"] = "python"
    return lesson

def generate_mixed_batch(grade, count, start_id=0):
    batch = []
    for i in range(count):
        qid = start_id + i
        if i % 2 == 0:
            q = c_generate_question(grade, qid) or python_generate_question(grade, qid)
        else:
            q = python_generate_question(grade, qid)
        batch.append(q)
    return batch

@app.route('/signup', methods=['POST'])
def signup():
    data = request.get_json(force=True, silent=True) or {}
    full_name = (data.get('full_name') or '').strip()
    email = (data.get('email') or '').strip().lower()
    password = data.get('password') or ''

    if len(full_name) < 2:
        return jsonify({"error": "Enter your full name."}), 400
    if not EMAIL_PATTERN.match(email):
        return jsonify({"error": "Enter a valid email address."}), 400
    if len(password) < 6:
        return jsonify({"error": "Password must be at least 6 characters."}), 400

    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT id FROM users WHERE email = ?", (email,))
    if cursor.fetchone():
        conn.close()
        return jsonify({"error": "An account with that email already exists."}), 409

    password_hash = generate_password_hash(password, method="pbkdf2:sha256")
    cursor.execute(
        "INSERT INTO users (full_name, email, password_hash) VALUES (?, ?, ?)",
        (full_name, email, password_hash)
    )
    conn.commit()
    user_id = cursor.lastrowid
    cursor.execute("SELECT * FROM users WHERE id = ?", (user_id,))
    row = cursor.fetchone()
    conn.close()
    return jsonify(user_to_dict(row)), 201

@app.route('/login', methods=['POST'])
def login():
    data = request.get_json(force=True, silent=True) or {}
    email = (data.get('email') or '').strip().lower()
    password = data.get('password') or ''

    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM users WHERE email = ?", (email,))
    row = cursor.fetchone()
    conn.close()

    if not row or not check_password_hash(row["password_hash"], password):
        return jsonify({"error": "Incorrect email or password."}), 401

    return jsonify(user_to_dict(row))

@app.route('/get_profile/<int:user_id>', methods=['GET'])
def get_profile(user_id):
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM users WHERE id = ?", (user_id,))
    row = cursor.fetchone()
    conn.close()
    if not row:
        return jsonify({"error": "User not found."}), 404
    return jsonify(user_to_dict(row))

@app.route('/update_grade', methods=['POST'])
def update_grade():
    data = request.get_json(force=True, silent=True) or {}
    user_id = data.get('user_id')
    grade = int(data.get('grade', 1))
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute(
        "UPDATE users SET grade = ?, has_selected_grade = 1 WHERE id = ?",
        (grade, user_id)
    )
    conn.commit()
    cursor.execute("SELECT * FROM users WHERE id = ?", (user_id,))
    row = cursor.fetchone()
    conn.close()
    if not row:
        return jsonify({"error": "User not found."}), 404
    return jsonify(user_to_dict(row))

@app.route('/submit_answer', methods=['POST'])
def submit_answer():
    data = request.get_json(force=True, silent=True) or {}
    user_id = data.get('user_id')
    correct = bool(data.get('correct', False))
    coins_delta = 10 if correct else 0
    xp_delta = 5 if correct else 0
    points_delta = 1 if correct else 0

    conn = get_db()
    cursor = conn.cursor()
    cursor.execute(
        "UPDATE users SET xp = xp + ?, coins = coins + ?, points = points + ? WHERE id = ?",
        (xp_delta, coins_delta, points_delta, user_id)
    )
    conn.commit()
    cursor.execute("SELECT * FROM users WHERE id = ?", (user_id,))
    row = cursor.fetchone()
    conn.close()
    if not row:
        return jsonify({"error": "User not found."}), 404
    return jsonify(user_to_dict(row))

@app.route('/purchase_item', methods=['POST'])
def purchase_item():
    data = request.get_json(force=True, silent=True) or {}
    user_id = data.get('user_id')
    item_id = data.get('item_id')
    price = int(data.get('price', 0))

    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT coins FROM users WHERE id = ?", (user_id,))
    row = cursor.fetchone()
    if not row:
        conn.close()
        return jsonify({"error": "User not found."}), 404
    if row["coins"] < price:
        conn.close()
        return jsonify({"error": "Not enough coins."}), 400

    cursor.execute(
        "INSERT OR IGNORE INTO owned_items (user_id, item_id) VALUES (?, ?)",
        (user_id, item_id)
    )
    cursor.execute("UPDATE users SET coins = coins - ? WHERE id = ?", (price, user_id))
    conn.commit()
    cursor.execute("SELECT * FROM users WHERE id = ?", (user_id,))
    row = cursor.fetchone()
    cursor.execute("SELECT item_id FROM owned_items WHERE user_id = ?", (user_id,))
    owned = [r["item_id"] for r in cursor.fetchall()]
    conn.close()
    result = user_to_dict(row)
    result["owned_items"] = owned
    return jsonify(result)

@app.route('/get_owned_items/<int:user_id>', methods=['GET'])
def get_owned_items(user_id):
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT item_id FROM owned_items WHERE user_id = ?", (user_id,))
    owned = [r["item_id"] for r in cursor.fetchall()]
    conn.close()
    return jsonify({"owned_items": owned})

@app.route('/get_lessons/<int:grade>', methods=['GET'])
def get_lessons(grade):
    lessons = generate_mixed_batch(grade, count=5)
    return jsonify(lessons)

@app.route('/get_daily_challenge/<int:grade>', methods=['GET'])
def get_daily_challenge(grade):
    lessons = []
    for i in range(5):
        step_grade = min(10, grade + i)
        if i % 2 == 0:
            q = c_generate_question(step_grade, i) or python_generate_question(step_grade, i)
        else:
            q = python_generate_question(step_grade, i)
        q["difficulty_step"] = i + 1
        lessons.append(q)
    return jsonify({
        "questions": lessons,
        "time_per_question": 30,
        "coin_reward": 500
    })

@app.route('/submit_challenge_result', methods=['POST'])
def submit_challenge_result():
    data = request.get_json(force=True, silent=True) or {}
    user_id = data.get('user_id')
    correct_count = int(data.get('correct_count', 0))
    coins_earned = correct_count * 100
    xp_earned = correct_count * 50

    conn = get_db()
    cursor = conn.cursor()
    cursor.execute(
        "UPDATE users SET xp = xp + ?, coins = coins + ?, points = points + ? WHERE id = ?",
        (xp_earned, coins_earned, xp_earned, user_id)
    )
    conn.commit()
    cursor.execute("SELECT xp, coins FROM users WHERE id = ?", (user_id,))
    row = cursor.fetchone()
    conn.close()

    return jsonify({
        "coins_earned": coins_earned,
        "xp_earned": xp_earned,
        "total_xp": row["xp"] if row else None,
        "total_coins": row["coins"] if row else None
    })

@app.route('/get_leaderboard', methods=['GET'])
def get_leaderboard():
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT full_name, xp FROM users ORDER BY xp DESC LIMIT 10")
    rows = cursor.fetchall()
    conn.close()

    leaderboard = []
    for rank, row in enumerate(rows, 1):
        leaderboard.append({"name": row["full_name"], "xp": row["xp"], "rank": rank})
    return jsonify(leaderboard)

if __name__ == '__main__':
    init_db()
    app.run(host='0.0.0.0', port=5000, debug=True)