#!/usr/bin/env bash
set -euo pipefail

echo "Starting & gating test-plan run..." >&2

: "${TESTSAVANT_API_KEY:?TESTSAVANT_API_KEY is required}"
if [[ -z "${TEST_PLAN_ID:-}" && -z "${TEST_PLAN_GROUP_ID:-}" ]]; then
  echo "TEST_PLAN_ID or TEST_PLAN_GROUP_ID is required" >&2
  exit 1
fi

ARGS=( run-test-plan-and-wait )
[[ -n "${TEST_PLAN_ID:-}" ]] && ARGS+=( --test-plan-id "$TEST_PLAN_ID" )
[[ -n "${TEST_PLAN_GROUP_ID:-}" ]] && ARGS+=( --test-plan-group-id "$TEST_PLAN_GROUP_ID" )
ARGS+=( --timeout "${TS_POLL_TIMEOUT:-3600}" --summary )

[[ -n "${MAX_VULN_RATE:-}" ]]            && ARGS+=( --max-vulnerability-rate "$MAX_VULN_RATE" )
[[ -n "${MAX_VULN_COUNT:-}" ]]           && ARGS+=( --max-vulnerable-count "$MAX_VULN_COUNT" )
[[ -n "${MIN_PASS_RATE:-}" ]]            && ARGS+=( --min-pass-rate "$MIN_PASS_RATE" )
[[ -n "${MAX_POLICY_FAILURE_RATE:-}" ]]  && ARGS+=( --max-policy-failure-rate "$MAX_POLICY_FAILURE_RATE" )
[[ -n "${PER_POLICY_THRESHOLDS:-}" ]]    && ARGS+=( --per-policy-thresholds "$PER_POLICY_THRESHOLDS" )
[[ -n "${MAX_CATEGORY_VULN_RATE:-}" ]]   && ARGS+=( --max-category-vulnerability-rate "$MAX_CATEGORY_VULN_RATE" )

RESULT_FILE="result.json"

set +e
python -m testsavant_redteaming.cli --api-key "$TESTSAVANT_API_KEY" "${ARGS[@]}" > "$RESULT_FILE"
code=$?
set -e

cat "$RESULT_FILE"

# The CLI already wrote proceed/run_id/state to $GITHUB_OUTPUT. Mirror as a fallback.
PROCEED="false"
[[ $code -eq 0 ]] && PROCEED="true"
if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  grep -q '^proceed=' "$GITHUB_OUTPUT" 2>/dev/null || echo "proceed=$PROCEED" >> "$GITHUB_OUTPUT"
fi

echo "[ts] Done. proceed=$PROCEED" >&2
exit 0
