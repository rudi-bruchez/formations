import pyodbc
import ollama

# MODEL_NAME = "qwen3:8b"
# MODEL_NAME = "qwen2.5:7b-instruct"  # or "phi4:mini", "llama3.2:3b-instruct"
# MODEL_NAME = "phi4-mini"
MODEL_NAME = "gemma3:4b"
# MODEL_NAME = "llama3.2"


SYSTEM_PROMPT = """You are a professional course catalog copywriter.
Your ONLY job is to write one improved course description at a time, based on a single course title and some metadata.
You NEVER talk about tools, SQL, databases, or IDs.
You ALWAYS answer with only the final description text, nothing else.
"""

def build_user_prompt(title, level):
    return f"""Write a professional and engaging catalog description for the following course.

Title: "{title}"
Level: {level}
Target audience: IT professionals and developers.

Requirements for the description:
- Length: between 40 and 80 words.
- Style: clear, confident, slightly marketing but not hype.
- Must obviously match this exact title and level.
- Mention 2–4 concrete skills, topics, or outcomes the learner will gain.
- Do NOT restate the title verbatim as the first sentence.

Output:
- Return only the description paragraph.
- Do NOT include Title, bullets, quotes, or any extra commentary.
"""

def generate_description(title, level):
    messages = [
        {"role": "system", "content": SYSTEM_PROMPT},
        {"role": "user", "content": build_user_prompt(title, level)},
    ]
    response = ollama.chat(model=MODEL_NAME, messages=messages)
    return response["message"]["content"].strip()

def main():
    # 1. Connect to SQL Server
    cnxn = pyodbc.connect(
        "Driver={ODBC Driver 18 for SQL Server};"
        "Server=localhost,3000;"
        "Database=PachadataTraining;"
        "UID=sa;PWD=Admin1234!;"
        "Encrypt=yes;TrustServerCertificate=yes;"
    )
    cnxn.autocommit = True
    cursor = cnxn.cursor()

    # 2. Read courses (example: all rows; add WHERE if needed)
    cursor.execute("""
        SELECT CourseId, Title, DifficultyLevel
        FROM Course.Course
        ORDER BY CourseId ASC;
    """)

    rows = cursor.fetchall()
    print(f"Loaded {len(rows)} courses from database.")

    updated = 0

    for row in rows:
        course_id = row.CourseId
        title = row.Title
        level = row.DifficultyLevel

        print(f"Generating description for CourseId={course_id}: {title!r}")

        try:
            description = generate_description(title, level)
        except Exception as e:
            print(f"Error calling model for CourseId={course_id}: {e}")
            continue

        # 3. Update description in SQL Server
        try:
            cursor.execute(
                """
                UPDATE Course.Course
                SET Description = ?
                WHERE CourseId = ?;
                """,
                (description, course_id),
            )
            updated += 1
            print(f"Updated CourseId={course_id}")
            cnxn.commit()
        except Exception as e:
            print(f"Error updating CourseId={course_id}: {e}")
            cnxn.rollback()
            continue

    cursor.close()
    cnxn.close()

    print(f"Done. Updated {updated} courses.")

if __name__ == "__main__":
    main()

