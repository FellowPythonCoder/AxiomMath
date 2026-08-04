import random

def generate_lesson_batch(grade, count=5):
    """Generates a batch of quiz questions based on grade level."""
    lessons = []
    for i in range(count):
        lesson = generate_single_lesson(grade, i)
        lessons.append(lesson)
    return lessons

def generate_single_lesson(grade, lesson_id):
    """Creates a multiple-choice math question."""
    if grade <= 3:
        a, b = random.randint(1, 10), random.randint(1, 10)
        question_text = f"{a} + {b}"
        correct = str(a + b)
        options = [str(a + b + random.randint(1, 3)), str(abs(a + b - random.randint(1, 3))), correct]
        random.shuffle(options)
        return {"id": lesson_id, "title": "Basic Addition", "question": question_text, "options": options, "correct_answer": correct}
        
    elif grade <= 6:
        a, b = random.randint(2, 12), random.randint(2, 12)
        question_text = f"{a} * {b}"
        correct = str(a * b)
        options = [str(a * b + random.randint(2, 5)), str(abs(a * b - random.randint(2, 5))), correct]
        random.shuffle(options)
        return {"id": lesson_id, "title": "Multiplication", "question": question_text, "options": options, "correct_answer": correct}
        
    else:
        x = random.randint(2, 10)
        result = x * random.randint(2, 10)
        question_text = f"Solve for x: {x}x = {result}"
        correct = str(result // x)
        options = [str((result // x) + random.randint(1, 3)), str(abs((result // x) - random.randint(1, 3))), correct]
        random.shuffle(options)
        return {"id": lesson_id, "title": "Algebra", "question": question_text, "options": options, "correct_answer": correct}
