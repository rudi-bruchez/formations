import os
import json
import time
import hashlib
from datetime import datetime, timezone

import pyodbc
from dotenv import load_dotenv
from openai import OpenAI

# -----------------------------------------------------------------------------
# Config
# -----------------------------------------------------------------------------
EMBEDDING_MODEL = "text-embedding-3-small"  # 1536 dims by default :contentReference[oaicite:2]{index=2}
EXPECTED_DIMS = 1536

# You can change this to: "Title", "Description", "Title+Description", etc.
EMBEDDING_TYPE = "Title+Description"

# Batch sizes (tune based on your network + API limits)
SQL_BATCH_SIZE = 200
API_BATCH_SIZE = 100  # OpenAI embeddings API supports batching inputs

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------
def sha256_bytes(text: str) -> bytes:
    return hashlib.sha256(text.encode("utf-8")).digest()

def utc_now_dt2() -> str:
    # SQL datetime2(3) friendly ISO string
    return datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S.%f")[:-3]

def build_course_text(title: str, description: str) -> str:
    title = (title or "").strip()
    description = (description or "").strip()
    if title and description:
        return f"{title}\n\n{description}"
    return title or description or ""

# -----------------------------------------------------------------------------
# SQL
# -----------------------------------------------------------------------------
def sql_connect(server: str, database: str, username: str, password: str):
    conn_str = (
        "DRIVER={ODBC Driver 18 for SQL Server};"
        f"SERVER={server};DATABASE={database};UID={username};PWD={password};"
        "TrustServerCertificate=yes;"
        "LongAsMax=yes;"
    )
    conn = pyodbc.connect(conn_str)
    conn.autocommit = False
    return conn

def ensure_embeddings_table(conn):
    # Adjust schema if your table already exists; this is "safe create" style.
    # NOTE: this includes ModelName + SourceHash; if your table does not have them,
    # either add columns, or remove from the INSERT below.
    ddl = """
    IF OBJECT_ID('Course.CourseEmbeddings', 'U') IS NULL
    BEGIN
        CREATE TABLE Course.CourseEmbeddings
        (
            CourseEmbeddingId bigint IDENTITY(1,1) NOT NULL
                CONSTRAINT PK_CourseEmbeddings PRIMARY KEY,
            CourseId          int NOT NULL,
            EmbeddingType     nvarchar(50) NOT NULL,
            Embedding         vector(1536) NOT NULL,
            ModelName         nvarchar(100) NOT NULL,
            ModelVersion      nvarchar(50) NOT NULL,
            GeneratedAt       datetime2(3) NOT NULL
                CONSTRAINT DF_CourseEmbeddings_GeneratedAt DEFAULT sysutcdatetime(),
            SourceHash        varbinary(32) NULL,
            CONSTRAINT FK_CourseEmbeddings_Course
                FOREIGN KEY (CourseId) REFERENCES Course.Course(CourseId)
                ON DELETE CASCADE
        );

        CREATE UNIQUE INDEX UX_CourseEmbeddings_Unique
        ON Course.CourseEmbeddings (CourseId, EmbeddingType, ModelName, ModelVersion);

        CREATE INDEX IX_CourseEmbeddings_Course_Type
        ON Course.CourseEmbeddings (CourseId, EmbeddingType);
    END
    """
    cur = conn.cursor()
    cur.execute(ddl)
    conn.commit()

def fetch_courses_to_embed(conn, limit: int | None = None):
    """
    Fetch courses where we don't yet have an embedding for (EmbeddingType, ModelName, ModelVersion).
    If you want to regenerate, remove the NOT EXISTS filter.
    """
    top_clause = f"TOP ({limit})" if limit else ""
    sql = f"""
    SELECT {top_clause}
           c.CourseId,
           c.Title,
           c.Description
    FROM Course.Course AS c
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM Course.CourseEmbeddings AS e
        WHERE e.CourseId = c.CourseId
          AND e.EmbeddingType = ?
          AND e.ModelName = ?
          AND e.ModelVersion = ?
    )
    ORDER BY c.CourseId;
    """
    cur = conn.cursor()
    cur.execute(sql, (EMBEDDING_TYPE, EMBEDDING_MODEL, EMBEDDING_MODEL))
    return cur.fetchall()

def upsert_embeddings(conn, rows):
    """
    rows: list of tuples:
      (CourseId, EmbeddingType, EmbeddingJson, ModelName, ModelVersion, GeneratedAt, SourceHash)
    Uses MERGE to be idempotent.
    """
    merge_sql = """
    MERGE Course.CourseEmbeddings AS tgt
    USING (SELECT ? AS CourseId,
                  ? AS EmbeddingType,
                  ? AS Embedding,
                  ? AS ModelName,
                  ? AS ModelVersion,
                  ? AS GeneratedAt,
                  ? AS SourceHash) AS src
       ON tgt.CourseId = src.CourseId
      AND tgt.EmbeddingType = src.EmbeddingType
      AND tgt.ModelName = src.ModelName
      AND tgt.ModelVersion = src.ModelVersion
    WHEN MATCHED THEN
        UPDATE SET
            tgt.Embedding   = src.Embedding,
            tgt.GeneratedAt = src.GeneratedAt,
            tgt.SourceHash  = src.SourceHash
    WHEN NOT MATCHED THEN
        INSERT (CourseId, EmbeddingType, Embedding, ModelName, ModelVersion, GeneratedAt, SourceHash)
        VALUES (src.CourseId, src.EmbeddingType, src.Embedding, src.ModelName, src.ModelVersion, src.GeneratedAt, src.SourceHash);
    """

    cur = conn.cursor()
    cur.fast_executemany = True
    cur.executemany(merge_sql, rows)
    conn.commit()

# -----------------------------------------------------------------------------
# OpenAI embeddings
# -----------------------------------------------------------------------------
def get_embeddings(client: OpenAI, texts: list[str]) -> list[list[float]]:
    resp = client.embeddings.create(
        model=EMBEDDING_MODEL,
        input=texts,
        # dimensions parameter NOT needed here; default is 1536 for text-embedding-3-small :contentReference[oaicite:3]{index=3}
    )
    vectors = [item.embedding for item in resp.data]
    # quick sanity check
    for v in vectors:
        if len(v) != EXPECTED_DIMS:
            raise RuntimeError(f"Unexpected embedding dimension: got {len(v)}, expected {EXPECTED_DIMS}")
    return vectors

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
def main():
    # Load .env (same style as your template) :contentReference[oaicite:4]{index=4}
    load_dotenv(os.path.join(os.path.dirname(__file__), "..", ".env"))

    server = os.getenv("SQLSERVER_SERVER")
    database = os.getenv("SQLSERVER_DATABASE")
    username = os.getenv("SQLSERVER_USERNAME")
    password = os.getenv("SQLSERVER_PASSWORD")

    # OpenAI
    # Expect OPENAI_API_KEY in your environment / .env
    client = OpenAI()

    if not all([server, database, username, password]):
        raise RuntimeError("Missing SQL env vars: SQLSERVER_SERVER/SQLSERVER_DATABASE/SQLSERVER_USERNAME/SQLSERVER_PASSWORD")

    conn = sql_connect(server, database, username, password)
    try:
        ensure_embeddings_table(conn)

        courses = fetch_courses_to_embed(conn, limit=None)
        total = len(courses)
        print(f"Courses to embed: {total}")

        if total == 0:
            return

        start = time.time()

        # Process in API batches, then SQL batches
        buffer_sql_rows = []
        processed = 0

        for i in range(0, total, API_BATCH_SIZE):
            chunk = courses[i:i + API_BATCH_SIZE]

            texts = []
            meta = []  # (CourseId, source_text)
            for row in chunk:
                course_id, title, description = row.CourseId, row.Title, row.Description
                source_text = build_course_text(title, description)
                # Ensure non-empty input; fallback to title marker if truly empty
                if not source_text:
                    source_text = f"CourseId={course_id}"
                texts.append(source_text)
                meta.append((course_id, source_text))

            vectors = get_embeddings(client, texts)

            now_str = utc_now_dt2()
            for (course_id, source_text), vec in zip(meta, vectors):
                embedding_json = json.dumps(vec)  # SQL Server VECTOR accepts JSON array representation
                src_hash = sha256_bytes(source_text)

                buffer_sql_rows.append((
                    course_id,
                    EMBEDDING_TYPE,
                    embedding_json,
                    EMBEDDING_MODEL,          # ModelName
                    EMBEDDING_MODEL,          # ModelVersion (set differently if you version yourself)
                    now_str,
                    src_hash
                ))

                if len(buffer_sql_rows) >= SQL_BATCH_SIZE:
                    upsert_embeddings(conn, buffer_sql_rows)
                    processed += len(buffer_sql_rows)
                    buffer_sql_rows.clear()
                    print(f"Upserted: {processed}/{total}")

        # flush remainder
        if buffer_sql_rows:
            upsert_embeddings(conn, buffer_sql_rows)
            processed += len(buffer_sql_rows)
            print(f"Upserted: {processed}/{total}")

        elapsed = time.time() - start
        print(f"Done. {processed} embeddings generated in {elapsed:.2f}s ({processed/elapsed:.2f}/s)")

    finally:
        conn.close()

if __name__ == "__main__":
    main()
