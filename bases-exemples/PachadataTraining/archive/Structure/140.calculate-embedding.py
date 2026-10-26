import os
import argparse

os.environ.setdefault("HF_HUB_DISABLE_SYMLINKS_WARNING", "1")

# Ensure CUDA DLLs are discoverable before importing ctranslate2
_cuda_bin = os.getenv("CUDA_PATH_BIN", r"C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.8\bin")
if _cuda_bin not in os.environ.get("PATH", ""):
    os.environ["PATH"] = _cuda_bin + os.pathsep + os.environ.get("PATH", "")

import ctranslate2
import numpy as np
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

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------
def resolve_ct2_model_dir(model_ref: str) -> str:
    if os.path.isdir(model_ref) and os.path.isfile(os.path.join(model_ref, "model.bin")):
        return model_ref

    local_dir = snapshot_download(repo_id=model_ref, token=HF_TOKEN)

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
    return "cublas" in msg or "cudnn" in msg or "cuda" in msg or "cannot be loaded" in msg

def create_encoder_with_fallback(model_dir: str) -> tuple[ctranslate2.Encoder, str]:
    preferred_device = EMBEDDING_DEVICE.lower().strip()

    if preferred_device in ("auto", "cuda"):
        candidates = [
            ("cuda", EMBEDDING_COMPUTE_TYPE),
            ("cpu", EMBEDDING_CPU_COMPUTE_TYPE),
        ]
    else:
        candidates = [(preferred_device, EMBEDDING_CPU_COMPUTE_TYPE)]

    last_error = None
    for device, compute_type in candidates:
        try:
            encoder = ctranslate2.Encoder(model_dir, device=device, compute_type=compute_type)
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
# Embeddings
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
    vector = normalized[0].tolist()

    if len(vector) != EXPECTED_DIMS:
        raise RuntimeError(f"Unexpected embedding dimension: got {len(vector)}, expected {EXPECTED_DIMS}")

    return vector

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
def main():
    parser = argparse.ArgumentParser(description="Compute a text embedding using CTranslate2.")
    parser.add_argument("text", help="Text to embed")
    args = parser.parse_args()

    load_dotenv(os.path.join(os.path.dirname(__file__), "..", ".env"))

    tokenizer = AutoTokenizer.from_pretrained(TOKENIZER_MODEL)
    ct2_model_dir = resolve_ct2_model_dir(EMBEDDING_MODEL)
    encoder, active_device = create_encoder_with_fallback(ct2_model_dir)

    try:
        vector = get_embeddings(tokenizer, encoder, text=args.text)
    except RuntimeError as exc:
        if active_device == "cuda" and is_cuda_loader_issue(exc):
            print("CUDA execution failed during inference, retrying on CPU.")
            encoder = ctranslate2.Encoder(
                ct2_model_dir, device="cpu", compute_type=EMBEDDING_CPU_COMPUTE_TYPE
            )
            active_device = "cpu"
            print(f"Embedding device: cpu ({EMBEDDING_CPU_COMPUTE_TYPE})")
            vector = get_embeddings(tokenizer, encoder, text=args.text)
        else:
            raise

    print(f"Embedding vector (device: {active_device}): {vector}")

if __name__ == "__main__":
    main()
