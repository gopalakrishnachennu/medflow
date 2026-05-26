#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../../src/services/auth-service"

export ENVIRONMENT="${ENVIRONMENT:-local}"
export DATABASE_URL="${DATABASE_URL:-sqlite+pysqlite:///:memory:}"
export JWT_SECRET_KEY="${JWT_SECRET_KEY:-local-dev-only}"
export JWT_ALGORITHM="${JWT_ALGORITHM:-HS256}"
export ACCESS_TOKEN_EXPIRE_MINUTES="${ACCESS_TOKEN_EXPIRE_MINUTES:-30}"

python3 -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8001

