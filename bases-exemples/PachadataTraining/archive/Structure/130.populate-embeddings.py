import os
import json
import time
import hashlib
from datetime import datetime, timezone

os.environ.setdefault("HF_HUB_DISABLE_SYMLINKS_WARNING", "1")

import ctranslate2
import numpy as np
import pyodbc
from dotenv import load_dotenv
from huggingface_hub import snapshot_download
from transformers import AutoTokenizer

# -----------------------------------------------------------------------------
# Config
# -----------------------------------------------------------------------------
EMBEDDING_MODEL = "michaelfeil/ct2fast-e5-large-v2"
TOKENIZER_MODEL = "intfloat/e5-large-v2"
EXPECTED_DIMS = 1024
EMBEDDING_DEVICE = os.getenv("EMBEDDING_DEVICE", "auto")
EMBEDDING_COMPUTE_TYPE = os.getenv("EMBEDDING_COMPUTE_TYPE", "int8_float16")
EMBEDDING_CPU_COMPUTE_TYPE = os.getenv("EMBEDDING_CPU_COMPUTE_TYPE", "int8")
HF_TOKEN = os.getenv("HF_TOKEN")
HF_HUB_DISABLE_SYMLINKS_WARNING = os.getenv("HF_HUB_DISABLE_SYMLINKS_WARNING", "1")

# You can change this to: "Title", "Description", "Title+Description", etc.
EMBEDDING_TYPE = "Description"

# Batch sizes (tune based on your network + API limits)
SQL_BATCH_SIZE = 200
API_BATCH_SIZE = 100

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

    match EMBEDDING_TYPE:
        case "Title":  return title
        case "Description": return description
        case "Title+Description": return f"{title}\n\n{description}" if description else title
        case _: raise ValueError(f"Unsupported EMBEDDING_TYPE: {EMBEDDING_TYPE}")

    return ""

def resolve_ct2_model_dir(model_ref: str) -> str:
    if os.path.isdir(model_ref) and os.path.isfile(os.path.join(model_ref, "model.bin")):
        return model_ref

    local_dir = snapshot_download(
        repo_id=model_ref,
        token=HF_TOKEN,
    )

    if os.path.isfile(os.path.join(local_dir, "model.bin")):
        return local_dir

    for root, _, files in os.walk(local_dir):
        if "model.bin" in files:
            return root

    raise RuntimeError(
        f"No CTranslate2 model.bin found in '{model_ref}' (downloaded to '{local_dir}'). "
        "Set EMBEDDING_MODEL to a local CT2 model directory or a HF repo containing model.bin."
    )

def is_cuda_loader_issue(exc: RuntimeError) -> bool:
    msg = str(exc).lower()
    return (
        "cublas" in msg
        or "cudnn" in msg
        or "cuda" in msg
        or "cannot be loaded" in msg
    )

def create_encoder_with_fallback(model_dir: str) -> tuple[ctranslate2.Encoder, str]:
    preferred_device = EMBEDDING_DEVICE.lower().strip()

    if preferred_device == "auto":
        candidates = [
            ("cuda", EMBEDDING_COMPUTE_TYPE),
            ("cpu", EMBEDDING_CPU_COMPUTE_TYPE),
        ]
    elif preferred_device == "cuda":
        candidates = [
            ("cuda", EMBEDDING_COMPUTE_TYPE),
            ("cpu", EMBEDDING_CPU_COMPUTE_TYPE),
        ]
    else:
        candidates = [(preferred_device, EMBEDDING_CPU_COMPUTE_TYPE)]

    last_error = None
    for device, compute_type in candidates:
        try:
            encoder = ctranslate2.Encoder(
                model_dir,
                device=device,
                compute_type=compute_type,
            )
            print(f"Embedding device: {device} ({compute_type})")
            return encoder, device
        except RuntimeError as exc:
            last_error = exc
            if device == "cuda" and is_cuda_loader_issue(exc):
                print("CUDA runtime not available, falling back to CPU for embeddings.")
                continue
            raise

    raise RuntimeError(f"Unable to initialize embedding encoder: {last_error}")

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
# Local embeddings (Transformers + CTranslate2)
# -----------------------------------------------------------------------------
def get_embeddings(tokenizer, encoder: ctranslate2.Encoder, texts: list[str]) -> list[list[float]]:
    prefixed_texts = [f"passage: {text}" for text in texts]

    encoded = tokenizer(
        prefixed_texts,
        padding=True,
        truncation=True,
        max_length=512,
        return_attention_mask=True,
    )

    batch_tokens = [tokenizer.convert_ids_to_tokens(ids) for ids in encoded["input_ids"]]
    output = encoder.forward_batch(batch_tokens)

    last_hidden_state = np.asarray(output.last_hidden_state, dtype=np.float32)
    attention_mask = np.array(encoded["attention_mask"], dtype=np.float32)

    mask = np.expand_dims(attention_mask, axis=-1)
    summed = np.sum(last_hidden_state * mask, axis=1)
    counts = np.clip(np.sum(mask, axis=1), 1e-9, None)
    pooled = summed / counts

    norms = np.linalg.norm(pooled, axis=1, keepdims=True)
    normalized = pooled / np.clip(norms, 1e-9, None)
    vectors = normalized.tolist()

    for v in vectors:
        if len(v) != EXPECTED_DIMS:
            raise RuntimeError(f"Unexpected embedding dimension: got {len(v)}, expected {EXPECTED_DIMS}")

    return vectors

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
def main():
    # Load .env
    load_dotenv(os.path.join(os.path.dirname(__file__), "..", ".env"))
    os.environ["HF_HUB_DISABLE_SYMLINKS_WARNING"] = HF_HUB_DISABLE_SYMLINKS_WARNING

    server = os.getenv("SQLSERVER_SERVER")
    database = os.getenv("SQLSERVER_DATABASE")
    username = os.getenv("SQLSERVER_USERNAME")
    password = os.getenv("SQLSERVER_PASSWORD")

    tokenizer = AutoTokenizer.from_pretrained(TOKENIZER_MODEL)
    ct2_model_dir = resolve_ct2_model_dir(EMBEDDING_MODEL)
    encoder, active_device = create_encoder_with_fallback(ct2_model_dir)

    if not all([server, database, username, password]):
        raise RuntimeError("Missing SQL env vars: SQLSERVER_SERVER/SQLSERVER_DATABASE/SQLSERVER_USERNAME/SQLSERVER_PASSWORD")

    conn = sql_connect(server, database, username, password)
    try:
        # ensure_embeddings_table(conn)

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

            try:
                vectors = get_embeddings(tokenizer, encoder, texts)
            except RuntimeError as exc:
                if active_device == "cuda" and is_cuda_loader_issue(exc):
                    print("CUDA execution failed during inference, retrying on CPU.")
                    encoder = ctranslate2.Encoder(
                        ct2_model_dir,
                        device="cpu",
                        compute_type=EMBEDDING_CPU_COMPUTE_TYPE,
                    )
                    active_device = "cpu"
                    print(f"Embedding device: cpu ({EMBEDDING_CPU_COMPUTE_TYPE})")
                    vectors = get_embeddings(tokenizer, encoder, texts)
                else:
                    raise

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
