#!/usr/bin/env bash
set -euo pipefail

# Minimal alternative start-and-gate script
# - Required env: TESTSAVANT_API_KEY, REDTEAMING_ID
# - Optional env: RT_TIMEOUT, RT_STRICT, RT_MAX_VULN_RATE, RT_MAX_VULN_COUNT,
#                 CALLBACK_URLS (comma), CALLBACK_URL (single)
# - Behavior: runs `run-and-wait`, writes `result.json`, prints it,
#   sets `run_id` and `proceed` to $GITHUB_OUTPUT (when available),
#   and exits with the CLI exit code (0 = gate passed).

: "${TESTSAVANT_API_KEY:?TESTSAVANT_API_KEY is required}"
: "${REDTEAMING_ID:?REDTEAMING_ID is required}"

RT_TIMEOUT="${RT_TIMEOUT:-3600}"

ARGS=( run-and-wait --redteaming-id "$REDTEAMING_ID" )
[[ "${RT_STRICT:-1}" != "0" ]] && ARGS+=( --strict )
[[ -n "${RT_MAX_VULN_RATE:-}" ]] && ARGS+=( --max-vulnerability-rate "${RT_MAX_VULN_RATE}" )
[[ -n "${RT_MAX_VULN_COUNT:-}" ]] && ARGS+=( --max-vulnerable-count "${RT_MAX_VULN_COUNT}" )
[[ -n "${CALLBACK_URLS:-}" ]] && ARGS+=( --callback-urls "${CALLBACK_URLS}" )
[[ -z "${CALLBACK_URLS:-}" && -n "${CALLBACK_URL:-}" ]] && ARGS+=( --callback-url "${CALLBACK_URL}" )

RESULT_FILE="result.json"

# Run the CLI and capture exit code (non-zero means gate failed)
set +e
python -m testsavant_redteaming.cli --api-key "$TESTSAVANT_API_KEY" --timeout "$RT_TIMEOUT" "${ARGS[@]}" > "$RESULT_FILE"
CODE=$?
set -e

# Print the result for logs
cat "$RESULT_FILE" || true

# Extract run id
RUN_ID=$(python - <<'PY'
import json
try:
    print(json.load(open('result.json')).get('id',''))
except Exception:
    print('')
PY
)

# If running in GitHub Actions, export outputs
if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  [[ -n "$RUN_ID" ]] && echo "run_id=$RUN_ID" >> "$GITHUB_OUTPUT"
  echo "proceed=$([ $CODE -eq 0 ] && echo true || echo false)" >> "$GITHUB_OUTPUT"
fi

# Exit with the CLI's exit code so CI gating is straightforward
exit $CODE
