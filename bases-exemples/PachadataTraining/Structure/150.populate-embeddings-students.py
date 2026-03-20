import os
import json
import time
import hashlib
from datetime import datetime, timezone

os.environ.setdefault("HF_HUB_DISABLE_SYMLINKS_WARNING", "1")

# Ensure CUDA DLLs are discoverable before importing ctranslate2
_cuda_bin = os.getenv("CUDA_PATH_BIN", r"C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.8\bin")
if _cuda_bin not in os.environ.get("PATH", ""):
    os.environ["PATH"] = _cuda_bin + os.pathsep + os.environ.get("PATH", "")

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

def build_contact_text(title: str, description: str, embed_type: str) -> str:
    title = (title or "").strip()
    description = (description or "").strip()

    match embed_type:
        case "Title":  return title
        case "Description": return description
        case "Title+Description": return f"{title}\n\n{description}" if description else title
        case _: raise ValueError(f"Unsupported embedding_type: {embed_type}")

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

def fetch_contacts_to_embed(conn, limit: int | None = None):
    """
    Fetch contacts where we don't yet have an embedding for (EmbeddingType, ModelName, ModelVersion).
    If you want to regenerate, remove the NOT EXISTS filter.
    """
    top_clause = f"TOP ({limit})" if limit else ""
    sql = f"""
    SELECT {top_clause}
        e.ContactId,
        STRING_AGG(CAST(c.Title as NVARCHAR(MAX)), ' - ') as Titles,
        STRING_AGG(CAST(c.Description as NVARCHAR(MAX)), ' - ') as Descriptions
    FROM Course.Course c
    JOIN Course.Session s ON c.CourseId = s.CourseId
    JOIN Enrollment.Enrollment e ON e.SessionId = s.SessionId
    WHERE e.IsPresent = 1
    AND e.CancellationDate IS NULL
    AND s.StartDate < CURRENT_TIMESTAMP
    AND NOT EXISTS
    (
        SELECT 1
        FROM Contact.PreviousCoursesEmbeddings AS e
        WHERE e.ContactId = e.ContactId
          AND e.ModelName = ?
          AND e.ModelVersion = ?
    )
    GROUP BY e.ContactId
    ORDER BY e.ContactId;
    """
    cur = conn.cursor()
    cur.execute(sql, (EMBEDDING_MODEL, EMBEDDING_MODEL))
    return cur.fetchall()

def upsert_embeddings(conn, rows):
    """
    rows: list of tuples:
      (ContactId, EmbeddingType, EmbeddingJson, ModelName, ModelVersion, GeneratedAt, SourceHash)
    Uses MERGE to be idempotent.
    """
    merge_sql = """
    MERGE Contact.PreviousCoursesEmbeddings AS tgt
    USING (SELECT ? AS ContactId,
                  ? AS EmbeddingType,
                  ? AS Embedding,
                  ? AS ModelName,
                  ? AS ModelVersion,
                  ? AS GeneratedAt,
                  ? AS SourceHash) AS src
       ON tgt.ContactId = src.ContactId
      AND tgt.EmbeddingType = src.EmbeddingType
      AND tgt.ModelName = src.ModelName
      AND tgt.ModelVersion = src.ModelVersion
    WHEN MATCHED THEN
        UPDATE SET
            tgt.Embedding   = src.Embedding,
            tgt.GeneratedAt = src.GeneratedAt,
            tgt.SourceHash  = src.SourceHash
    WHEN NOT MATCHED THEN
        INSERT (ContactId, EmbeddingType, Embedding, ModelName, ModelVersion, GeneratedAt, SourceHash)
        VALUES (src.ContactId, src.EmbeddingType, src.Embedding, src.ModelName, src.ModelVersion, src.GeneratedAt, src.SourceHash);
    """

    cur = conn.cursor()
    cur.fast_executemany = True
    cur.executemany(merge_sql, rows)
    conn.commit()

# -----------------------------------------------------------------------------
# Local embeddings (Transformers + CTranslate2)
# -----------------------------------------------------------------------------
def get_embeddings(tokenizer, encoder: ctranslate2.Encoder, text: str) -> list[float]:

    encoded = tokenizer(
        [text] if isinstance(text, str) else text,
        padding=True,
        truncation=True,
        max_length=512,
        return_attention_mask=True,
    )

    batch_tokens = [tokenizer.convert_ids_to_tokens(ids) for ids in encoded["input_ids"]]
    output = encoder.forward_batch(batch_tokens)

    lhs = output.last_hidden_state

    # ctranslate2 CUDA StorageViews can't be numpy-ified directly; move to CPU first.
    if hasattr(lhs, "device") and lhs.device != "cpu":
        lhs = lhs.to_device(ctranslate2._ext.Device.cpu)

    # Try DLPack (modern ctranslate2), fall back to buffer protocol (CPU StorageView)
    try:
        last_hidden_state = np.from_dlpack(lhs).astype(np.float32)
    except Exception:
        try:
            last_hidden_state = np.asarray(lhs, dtype=np.float32)
        except Exception:
            available = [m for m in dir(lhs) if not m.startswith("__")]
            raise RuntimeError(
                f"Cannot convert ctranslate2 StorageView to numpy.\n"
                f"  device={getattr(lhs, 'device', '?')}, dtype={getattr(lhs, 'dtype', '?')}, shape={getattr(lhs, 'shape', '?')}\n"
                f"  Available methods: {available}"
            )

    attention_mask = np.array(encoded["attention_mask"], dtype=np.float32)
    mask = np.expand_dims(attention_mask, axis=-1)
    summed = np.sum(last_hidden_state * mask, axis=1)
    counts = np.clip(np.sum(mask, axis=1), 1e-9, None)
    pooled = summed / counts

    norms = np.linalg.norm(pooled, axis=1, keepdims=True)
    normalized = pooled / np.clip(norms, 1e-9, None)
    vectors = normalized.tolist()

    if len(vectors[0]) != EXPECTED_DIMS:
        raise RuntimeError(f"Unexpected embedding dimension: got {len(vectors[0])}, expected {EXPECTED_DIMS}")

    return vectors

def insert_embeddings(conn, contacts, embed_type: str, total: int):
    tokenizer = AutoTokenizer.from_pretrained(TOKENIZER_MODEL)
    ct2_model_dir = resolve_ct2_model_dir(EMBEDDING_MODEL)
    encoder, active_device = create_encoder_with_fallback(ct2_model_dir)

    # Process in API batches, then SQL batches
    buffer_sql_rows = []
    processed = 0

    for i in range(0, total, API_BATCH_SIZE):
        chunk = contacts[i:i + API_BATCH_SIZE]

        texts = []
        meta = []  # (ContactId, source_text)
        for row in chunk:
            contact_id, title, description = row.ContactId, row.Titles, row.Descriptions
            source_text = build_contact_text(title, description, embed_type)
            # Ensure non-empty input; fallback to title marker if truly empty
            if not source_text:
                source_text = f"ContactId={contact_id}"
            texts.append(source_text)
            meta.append((contact_id, source_text))

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
        for (contact_id, source_text), vec in zip(meta, vectors):
            embedding_json = json.dumps(vec)  # SQL Server VECTOR accepts JSON array representation
            src_hash = sha256_bytes(source_text)

            buffer_sql_rows.append((
                contact_id,
                embed_type,
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

    if not all([server, database, username, password]):
        raise RuntimeError("Missing SQL env vars: SQLSERVER_SERVER/SQLSERVER_DATABASE/SQLSERVER_USERNAME/SQLSERVER_PASSWORD")

    conn = sql_connect(server, database, username, password)
    try:
        # ensure_embeddings_table(conn)

        contacts = fetch_contacts_to_embed(conn, limit=None)
        total = len(contacts)
        print(f"Contacts to embed: {total}")

        if total == 0:
            return

        start = time.time()

        # You can change this to: "Title", "Description", "Title+Description", etc.
        insert_embeddings(conn, contacts, "Title", total)
        insert_embeddings(conn, contacts, "Description", total)
        insert_embeddings(conn, contacts, "Title+Description", total)

        elapsed = time.time() - start
        print(f"Done. {processed} embeddings generated in {elapsed:.2f}s ({processed/elapsed:.2f}/s)")

    finally:
        conn.close()

if __name__ == "__main__":
    main()
