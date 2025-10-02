# GA-02 Delete Playbook Attachment

This appendix extends the primary runbook with a rehearsal plan for deletion requests. It blends human validation with the automated acceptance script so the team can produce evidence on demand.

## Preparation Checklist
- [ ] Confirm the bootstrap checklist in [`RUNBOOK.md`](../RUNBOOK.md) is complete and TLS assets are current.
- [ ] Ensure the host provides `curl`, `jq`, and `openssl` as referenced in the repository prerequisites.
- [ ] Populate `.env.local` with:
    - [ ] `SHS_DELETE_TARGET_URL` – HTTPS endpoint that accepts DELETE requests for the resource under test.
    - [ ] `SHS_DELETE_VALIDATION_URL` – companion endpoint that lists resources so the deletion can be verified.
    - [ ] `SHS_DELETE_RECORD_ID` – identifier of the record reserved for rehearsal.
    - [ ] `SHS_DELETE_BEARER_TOKEN` – optional token for Authorization headers.
- [ ] Create an evidence folder (for example `evidence/ga-02-<date>/`) before running the test so raw logs, fingerprints, and screenshots can be stored atomically.

## Manual Guard Rails
- [ ] Announce the rehearsal window in the ops channel and obtain sign-off from the data owner.
- [ ] Export the current TLS fingerprint (`secrets/tls/leaf.sha256`) into the evidence folder.
- [ ] Capture a baseline list of the resource targeted for deletion via `curl "$SHS_DELETE_VALIDATION_URL"` and store the response.
- [ ] If the rehearsal uses production-like data, clone the relevant database table into the `backups/` hierarchy for rollback.

## Automated Delete Test (`tests/acceptance/delete_retention_test.sh`)
- [ ] Run the script in dry-run mode first: `SHS_DELETE_DRY_RUN=true tests/acceptance/delete_retention_test.sh`.
- [ ] Inspect the generated log entry in `logs/shs.jsonl` to confirm the trace metadata and checklist items align with expectations.
- [ ] When ready, execute the destructive path: `SHS_DELETE_DRY_RUN=false tests/acceptance/delete_retention_test.sh`.
- [ ] Monitor the console output for the explicit "delete-confirmed" event before proceeding.

## Evidence Collection
- [ ] Append the script output (stdout/stderr) and the relevant `logs/shs.jsonl` entry to the evidence folder.
- [ ] Export `docker compose logs proxy --since 10m` to capture gateway audit details.
- [ ] Record the post-delete TLS fingerprint and verify that it matches the archived baseline; document any rotation events triggered by the rehearsal.
- [ ] Store the results of a subsequent `curl "$SHS_DELETE_VALIDATION_URL"` call showing the record is absent.

## Post-Rehearsal Actions
- [ ] Notify stakeholders that the rehearsal concluded and whether the record was restored.
- [ ] If the record remains deleted, document the approval chain and reconcile inventory systems referenced in [`docs/audit-matrix.md`](audit-matrix.md).
- [ ] File the evidence bundle location in the incident ledger noted in [`SECURITY.md`](../SECURITY.md).
- [ ] Schedule the next GA-02 rehearsal in the operations calendar and update this appendix with any lessons learned.
