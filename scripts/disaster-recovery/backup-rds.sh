#!/usr/bin/env bash
set -euo pipefail

DB_INSTANCE_IDENTIFIER="${1:-medflow-dev}"
SNAPSHOT_IDENTIFIER="${DB_INSTANCE_IDENTIFIER}-manual-$(date +%Y%m%d%H%M%S)"

aws rds create-db-snapshot \
  --db-instance-identifier "${DB_INSTANCE_IDENTIFIER}" \
  --db-snapshot-identifier "${SNAPSHOT_IDENTIFIER}"

