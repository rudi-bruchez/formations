# Repository Guidelines

## Project Structure & Module Organization
This repository is a SQL Server training dataset and schema baseline.

- `00.structure.sql`: main database structure script (schemas, functions, tables, indexes).
- `2025.json-restaurants.sql`: JSON-specific exercise script (`Travel.Restaurant`, JSON index).
- `Vectors/010.structure.sql`: placeholder for vector-related structure work.
- `.vs/`: local IDE artifacts; do not rely on this for source of truth.

Keep new SQL exercises as separate, clearly named `.sql` files at the root or inside a focused folder (for example, `Vectors/`).

## Build, Test, and Development Commands
Use SQL Server tools (`sqlcmd`) to apply scripts locally.

- `sqlcmd -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -i 00.structure.sql`
  Creates or updates the main training database structure.
- `sqlcmd -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -i 2025.json-restaurants.sql`
  Runs the JSON exercise script.
- `sqlcmd -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -b -i <script.sql>`
  Executes a script and returns a failing exit code on SQL errors (`-b`).

For `2025.json-restaurants.sql`, ensure `restaurants.json` exists at `/var/opt/mssql/backups/restaurants.json` in the SQL Server host/container.

For the embeddings population script (`Structure/130.populate-embeddings.py`), run with `uv`:

- `uv sync`
- `uv run .\Structure\130.populate-embeddings.py`

Embeddings environment variables (see `.env.example`):

- `EMBEDDING_DEVICE`: `auto` (default), `cuda`, or `cpu`.
- `EMBEDDING_COMPUTE_TYPE`: compute type for CUDA (default: `int8_float16`).
- `EMBEDDING_CPU_COMPUTE_TYPE`: compute type for CPU fallback (default: `int8`).
- `HF_TOKEN`: optional Hugging Face token for higher rate limits.
- `HF_HUB_DISABLE_SYMLINKS_WARNING`: set to `1` to silence Windows symlink cache warnings.

On Windows machines without CUDA runtime (`cublas64_12.dll`), keep `EMBEDDING_DEVICE=auto` (automatic CPU fallback) or set `EMBEDDING_DEVICE=cpu` directly.

Troubleshooting (`Structure/130.populate-embeddings.py`):

- `RuntimeError: Unable to open file 'model.bin'`: set `EMBEDDING_MODEL` to a valid CTranslate2 model repo/directory that contains `model.bin`.
- `Library cublas64_12.dll is not found`: set `EMBEDDING_DEVICE=cpu` (or keep `auto` for CPU fallback).
- HF warning about unauthenticated requests: set `HF_TOKEN` to improve rate limits and download reliability.
- SQL connection/env errors: verify `SQLSERVER_SERVER`, `SQLSERVER_DATABASE`, `SQLSERVER_USERNAME`, and `SQLSERVER_PASSWORD` in `.env`.

## Coding Style & Naming Conventions
- Use T-SQL with uppercase keywords (`CREATE TABLE`, `SELECT`, `GO`).
- Indent with 4 spaces in DDL blocks and align column definitions for readability.
- Use schema-qualified object names (`Travel.Restaurant`, `Enrollment.fGet...`).
- Naming pattern:
  - PK constraints: `pk_<TableName>`
  - Indexes: `IX_<Table>_<Column>` or `IXJ_<Table>_<JsonColumn>_<PathHint>`
  - Script files: numeric/topic prefix when ordered execution matters (example: `010.structure.sql`).

## Testing Guidelines
There is no automated test suite in this repo. Validate changes by:

1. Running the modified script with `sqlcmd -b`.
2. Verifying created objects with quick checks (`SELECT TOP 1 ...`, `sys.tables`, `sys.indexes`).
3. Testing idempotency where relevant (`DROP ... IF EXISTS` before `CREATE`).

## Commit & Pull Request Guidelines
Current history uses short, lower-case commit subjects (often in French), for example `nouveaux exercices` and `compression collation`.

- Keep commit messages concise and action-oriented (`add json index exercise`).
- One logical change per commit.
- PRs should include: purpose, affected script(s), execution order, and sample validation queries/results.
- Link related issue/training ticket when available.
