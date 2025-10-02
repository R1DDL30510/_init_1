#!/usr/bin/env bash
set -euo pipefail

TRACE_ID="${TRACE_ID:-ga-02-$(date -u +"%Y%m%dT%H%M%SZ")}"
LOG_FILE="${LOG_FILE:-logs/shs.jsonl}"
DRY_RUN="${SHS_DELETE_DRY_RUN:-true}"
TARGET_URL="${SHS_DELETE_TARGET_URL:-}"
VALIDATION_URL="${SHS_DELETE_VALIDATION_URL:-}"
RECORD_ID="${SHS_DELETE_RECORD_ID:-}"
BEARER_TOKEN="${SHS_DELETE_BEARER_TOKEN:-}"
POST_DELETE_DELAY="${SHS_DELETE_POST_DELETE_DELAY:-2}"

for cmd in jq curl date; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "missing dependency: $cmd" >&2
    exit 1
  fi
done

if [[ -z "$TARGET_URL" || -z "$VALIDATION_URL" || -z "$RECORD_ID" ]]; then
  echo "missing SHS_DELETE_TARGET_URL, SHS_DELETE_VALIDATION_URL, or SHS_DELETE_RECORD_ID" >&2
  exit 1
fi

mkdir -p "$(dirname "$LOG_FILE")"

log_event() {
  local level="$1"
  local event="$2"
  local context_json="${3:-}"
  local timestamp
  timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

  if [[ -n "$context_json" ]]; then
    jq -n \
      --arg timestamp "$timestamp" \
      --arg trace_id "$TRACE_ID" \
      --arg level "$level" \
      --arg event "$event" \
      --arg context "$context_json" \
      '{timestamp: $timestamp, trace_id: $trace_id, level: $level, event: $event, phase: "ga-02-delete", context: ($context | try fromjson catch $context)}' \
      >>"$LOG_FILE"
  else
    jq -n \
      --arg timestamp "$timestamp" \
      --arg trace_id "$TRACE_ID" \
      --arg level "$level" \
      --arg event "$event" \
      '{timestamp: $timestamp, trace_id: $trace_id, level: $level, event: $event, phase: "ga-02-delete"}' \
      >>"$LOG_FILE"
  fi
}

perform_request() {
  local method="$1"
  local url="$2"
  local tmp
  tmp="$(mktemp)"
  local args=(-sS -w '%{http_code}' -o "$tmp" -X "$method" "$url")
  if [[ -n "$BEARER_TOKEN" ]]; then
    args=(-sS -w '%{http_code}' -o "$tmp" -X "$method" -H "Authorization: Bearer $BEARER_TOKEN" "$url")
  fi
  local status
  if ! status="$(curl "${args[@]}")"; then
    rm -f "$tmp"
    echo "request failed: $method $url" >&2
    exit 1
  fi
  RESPONSE_BODY="$(cat "$tmp")"
  RESPONSE_STATUS="$status"
  rm -f "$tmp"
}

DELETE_URL="${TARGET_URL%/}/${RECORD_ID}"
VALIDATE_URL="${VALIDATION_URL%/}/${RECORD_ID}"

config_context=$(jq -n \
  --arg delete_url "$DELETE_URL" \
  --arg validate_url "$VALIDATE_URL" \
  --arg dry_run "$DRY_RUN" \
  '{delete_url: $delete_url, validate_url: $validate_url, dry_run: $dry_run}')
log_event "INFO" "delete-test-start" "$config_context"

echo "[GA-02] Trace: $TRACE_ID" >&2
if [[ "$DRY_RUN" != "false" ]]; then
  log_event "INFO" "delete-dry-run" "$config_context"
  echo "[GA-02] Dry run complete. No DELETE request was issued." >&2
  exit 0
fi

perform_request "GET" "$VALIDATE_URL"
validation_context=$(jq -n \
  --arg status "$RESPONSE_STATUS" \
  --arg body "$RESPONSE_BODY" \
  '{status: $status, body: $body}')
log_event "INFO" "baseline-state" "$validation_context"

echo "[GA-02] Baseline status: $RESPONSE_STATUS" >&2

perform_request "DELETE" "$DELETE_URL"
delete_context=$(jq -n \
  --arg status "$RESPONSE_STATUS" \
  --arg body "$RESPONSE_BODY" \
  '{status: $status, body: $body}')
log_event "INFO" "delete-issued" "$delete_context"

echo "[GA-02] DELETE responded with status: $RESPONSE_STATUS" >&2
sleep "$POST_DELETE_DELAY"

perform_request "GET" "$VALIDATE_URL"
post_context=$(jq -n \
  --arg status "$RESPONSE_STATUS" \
  --arg body "$RESPONSE_BODY" \
  '{status: $status, body: $body}')
log_event "INFO" "post-delete-state" "$post_context"

echo "[GA-02] Post-delete status: $RESPONSE_STATUS" >&2

if [[ "$RESPONSE_STATUS" == "404" || -z "$RESPONSE_BODY" ]]; then
  log_event "INFO" "delete-confirmed" "$post_context"
  echo "[GA-02] Delete confirmed." >&2
  exit 0
fi

log_event "ERROR" "delete-validation-failed" "$post_context"
echo "[GA-02] Delete validation failed. Inspect logs for details." >&2
exit 1
