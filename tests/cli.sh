#!/usr/bin/env bash
set -uo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
CLI="$ROOT/found-footage"
FAILURES=0

run_bounded() {
  if command -v timeout >/dev/null 2>&1; then
    timeout 2s "$@"
    return
  fi
  if command -v gtimeout >/dev/null 2>&1; then
    gtimeout 2s "$@"
    return
  fi

  "$@" &
  local command_pid=$!
  (
    sleep 2
    kill -TERM "$command_pid" 2>/dev/null
  ) &
  local guard_pid=$!
  wait "$command_pid"
  local status=$?
  kill -TERM "$guard_pid" 2>/dev/null
  wait "$guard_pid" 2>/dev/null
  return "$status"
}

check() {
  local name="$1" expected_status="$2" expected_text="$3"
  shift 3

  local output status
  output=$(run_bounded bash "$CLI" "$@" 2>&1)
  status=$?
  if [ "$status" -ne "$expected_status" ] || [[ "$output" != *"$expected_text"* ]]; then
    printf 'not ok - %s (exit %s, output %q)\n' "$name" "$status" "$output"
    FAILURES=$((FAILURES + 1))
  else
    printf 'ok - %s\n' "$name"
  fi
}

check "missing --to operand" 2 "--to requires DIR" --to
check "empty --to operand" 2 "--to requires DIR" --to ""
check "next option is not a directory" 2 "--to requires DIR" --to --quiet
check "leading-hyphen name explains escape" 2 "use ./-name" --to -archive
check "quoted directory with spaces" 0 "found-footage 0.1.0" --to "Recovered Footage" --version
check "explicit leading-hyphen path" 0 "found-footage 0.1.0" --to ./-archive --version
check "help remains available" 0 "USAGE" --help
check "version remains available" 0 "found-footage 0.1.0" --version

if [ "$FAILURES" -ne 0 ]; then
  printf '%s CLI regression(s) failed\n' "$FAILURES" >&2
  exit 1
fi
