#!/usr/bin/env bash
set -euo pipefail

# Trigger a TestSavant v2 test-plan run, wait, and gate on the run summary.
#
# Inputs via env:
# - TESTSAVANT_API_KEY (required)
# - TEST_PLAN_ID (required)  OR  TEST_PLAN_GROUP_ID
# - Decision levers (optional): MAX_VULN_RATE, MAX_VULN_COUNT, MIN_PASS_RATE,
#     MAX_POLICY_FAILURE_RATE, PER_POLICY_THRESHOLDS, MAX_CATEGORY_VULN_RATE
# - TS_POLL_TIMEOUT (default 3600)
#
# Always exits 0. Downstream steps branch on the `proceed` output (true/false).

echo "[ts] Starting & gating test-plan run..." >&2

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
