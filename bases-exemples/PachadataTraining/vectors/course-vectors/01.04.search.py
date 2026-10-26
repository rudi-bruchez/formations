import argparse
import hashlib
import json
import os
import time
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


# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------
def resolve_ct2_model_dir(model_ref: str) -> str:
    if os.path.isdir(model_ref) and os.path.isfile(
        os.path.join(model_ref, "model.bin")
    ):
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
        "cublas" in msg or "cudnn" in msg or "cuda" in msg or "cannot be loaded" in msg
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


def search_embed(conn, query_vector: list[float], limit: int | None = None):
    """
    Search vector
    """
    top_clause = f"TOP ({limit})" if limit else ""
    query_vector_literal = json.dumps(query_vector)
    sql = f"""
     SELECT {top_clause}
            c.CourseId,
            c.Title,
            c.Description,
           VECTOR_DISTANCE('cosine', CAST(? AS VECTOR({EXPECTED_DIMS})), ce.Embedding) AS distance
     FROM Course.Course c
     JOIN Course.CourseEmbeddings ce ON ce.CourseId = c.CourseId
     ORDER BY Distance;
     """
    cur = conn.cursor()
    cur.execute(sql, (query_vector_literal,))
    return cur.fetchall()


# -----------------------------------------------------------------------------
# Local embeddings (Transformers + CTranslate2)
# -----------------------------------------------------------------------------
def get_embedding(
    tokenizer,
    encoder: ctranslate2.Encoder,
    text: str,
    prefix: str = "passage",
) -> list[float]:
    prefixed_texts = [f"{prefix}: {text}"]

    encoded = tokenizer(
        prefixed_texts,
        padding=True,
        truncation=True,
        max_length=512,
        return_attention_mask=True,
    )

    batch_tokens = [
        tokenizer.convert_ids_to_tokens(ids) for ids in encoded["input_ids"]
    ]
    output = encoder.forward_batch(batch_tokens)

    last_hidden_state = np.asarray(output.last_hidden_state, dtype=np.float32)
    attention_mask = np.array(encoded["attention_mask"], dtype=np.float32)

    mask = np.expand_dims(attention_mask, axis=-1)
    summed = np.sum(last_hidden_state * mask, axis=1)
    counts = np.clip(np.sum(mask, axis=1), 1e-9, None)
    pooled = summed / counts

    norms = np.linalg.norm(pooled, axis=1, keepdims=True)
    normalized = pooled / np.clip(norms, 1e-9, None)
    vector = normalized[0].tolist()

    if len(vector) != EXPECTED_DIMS:
        raise RuntimeError(
            f"Unexpected embedding dimension: got {len(vector)}, expected {EXPECTED_DIMS}"
        )

    return vector


# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
def main(search_text: str | None = None):
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
        raise RuntimeError(
            "Missing SQL env vars: SQLSERVER_SERVER/SQLSERVER_DATABASE/SQLSERVER_USERNAME/SQLSERVER_PASSWORD"
        )

    conn = sql_connect(server, database, username, password)
    try:
        # ensure_embeddings_table(conn)

        query = search_text.strip()
        if not query:
            raise ValueError("search_text must be non-empty")
        query_vector = get_embedding(
            tokenizer,
            encoder,
            query,
            prefix="query",
        )
        results = search_embed(conn, query_vector, limit=10)
        for row in results:
            print(f"{row.CourseId} | {row.Title} | {row.distance:.4f}")
        return

    finally:
        conn.close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Course embedding pipeline")
    parser.add_argument(
        "--search",
        dest="search_text",
        required=True,
        help="Search string to drive query behavior",
    )
    args = parser.parse_args()
    main(search_text=args.search_text)
