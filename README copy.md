Test Red-Teaming using our CI/CD

Usage notes for callbacks:

- Preferred: set `RECEIVER_WEBHOOK_URLS` (secret) to a comma-separated list of public HTTPS webhook endpoints (e.g., your receiver + any extra sinks). The push workflow will pass these via `callback_urls`.
- Backward-compatible: if `RECEIVER_WEBHOOK_URLS` is not set, set `RECEIVER_WEBHOOK_URL` (single URL). The workflow will use that instead.
- Manual workflow: you can provide `callback_urls` (comma-separated) or `callback_url` (single) as inputs; `callback_urls` takes precedence.

Required repo configuration:

- Secrets: `TESTSAVANT_API_KEY`, and either `RECEIVER_WEBHOOK_URLS` or `RECEIVER_WEBHOOK_URL`. If your receiver forwards to GitHub, also set `TS_GITHUB_TOKEN` in the receiver environment (not here).
- Variables: `REDTEAMING_ID` (UUID of the configuration).

Listener workflow:

- `.github/workflows/on-dispatch.yml` reacts to `repository_dispatch` events sent by your webhook receiver on final run events.

## Test-Plan gate (v2)

`.github/workflows/test-plan-gate.yml` triggers a **v2 test plan**, polls until it
finishes, and decides whether to continue based on the run **summary** — totals,
policy-level failure percentages, per-category percentages, and the high/medium/low
risk distribution.

- Secrets: `TESTSAVANT_API_KEY` (and `TS_GITHUB_TOKEN` to install the SDK from the private repo).
- Variables: `TEST_PLAN_ID` (or `TEST_PLAN_GROUP_ID`).
- Optional decision levers (repo variables or workflow inputs): `MAX_VULN_RATE`,
  `MAX_VULN_COUNT`, `MIN_PASS_RATE`, `MAX_POLICY_FAILURE_RATE`, `PER_POLICY_THRESHOLDS`,
  `MAX_CATEGORY_VULN_RATE`.

The `gate` job exposes `proceed` (`true`/`false`) and `run_id` outputs; the `on-pass`
job runs only when `proceed == 'true'`, and `on-fail` halts the pipeline otherwise.
The gating logic lives in `scripts/start_and_gate_test_plan.sh`.

Trigger an update