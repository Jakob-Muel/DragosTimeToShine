#!/usr/bin/env bash
# Headless test runner for Drago's Time to Shine. Used by CI, agents and developers.
#
#   tests/run_tests.sh                   run every headless suite
#   tests/run_tests.sh smoke domain      run selected suites (name without _test.gd)
#   tests/run_tests.sh --graphics        also run suites marked "## requires-graphics"
#   tests/run_tests.sh --list            list discovered suites
#
# Options (env): GODOT=<binary>  PROJECT=<dir>  SUITE_TIMEOUT=<seconds, default 90>
#
# Why a runner: a failed GDScript assert does NOT exit Godot. It prints
# "SCRIPT ERROR: Assertion failed" and the SceneTree keeps running forever. The runner
# watches the output, kills the suite on the first SCRIPT ERROR or engine ERROR, enforces a
# timeout, and requires the suite's final "...: valid" line and exit code 0.
# A suite may opt out of the engine-ERROR rule with a "## allow-engine-errors" line.
# Compatible with macOS bash 3.2.
set -u

ROOT="${PROJECT:-$(cd "$(dirname "$0")/.." && pwd)}"
TIMEOUT="${SUITE_TIMEOUT:-90}"
INCLUDE_GRAPHICS=0
LIST_ONLY=0
SELECTED=()
for arg in "$@"; do
  case "$arg" in
    --graphics) INCLUDE_GRAPHICS=1 ;;
    --list) LIST_ONLY=1 ;;
    -h|--help) sed -n '2,16p' "$0"; exit 0 ;;
    *) SELECTED+=("${arg%_test.gd}") ;;
  esac
done

if [[ -z "${GODOT:-}" ]]; then
  for candidate in godot godot4 /Applications/Godot.app/Contents/MacOS/Godot; do
    if command -v "$candidate" >/dev/null 2>&1; then GODOT="$(command -v "$candidate")"; break; fi
  done
fi
if [[ -z "${GODOT:-}" && $LIST_ONLY -eq 0 ]]; then
  echo "No Godot binary found. Set GODOT=/path/to/godot (or use tools/agent_test.sh)." >&2
  exit 2
fi

# Discover suites.
SUITES=()
for file in "$ROOT"/tests/*_test.gd; do
  name="$(basename "$file" _test.gd)"
  if [[ ${#SELECTED[@]} -gt 0 ]]; then
    wanted=0
    for s in "${SELECTED[@]}"; do [[ "$s" == "$name" ]] && wanted=1; done
    [[ $wanted -eq 1 ]] || continue
  elif grep -q '^## requires-graphics' "$file" && [[ $INCLUDE_GRAPHICS -eq 0 ]]; then
    continue
  fi
  SUITES+=("$name")
done
if [[ ${#SELECTED[@]} -gt 0 && ${#SUITES[@]} -ne ${#SELECTED[@]} ]]; then
  echo "Unknown suite in: ${SELECTED[*]}" >&2
  exit 2
fi
if [[ $LIST_ONLY -eq 1 ]]; then printf '%s\n' "${SUITES[@]}"; exit 0; fi
if [[ ${#SUITES[@]} -eq 0 ]]; then echo "No suites found." >&2; exit 2; fi

TMP="$(mktemp -d "${TMPDIR:-/tmp}/dragos-tests.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

headless=(--headless)
passed=0; failed=0; summary=""
echo "Godot: $("$GODOT" --version 2>/dev/null | head -1)  |  suites: ${#SUITES[@]}  |  timeout: ${TIMEOUT}s"

for suite in "${SUITES[@]}"; do
  file="$ROOT/tests/${suite}_test.gd"
  out="$TMP/$suite.out"
  args=("${headless[@]}")
  if grep -q '^## requires-graphics' "$file"; then args=(); fi
  allow_engine_errors=0
  grep -q '^## allow-engine-errors' "$file" && allow_engine_errors=1

  start=$(date +%s)
  "$GODOT" ${args[@]+"${args[@]}"} --log-file "$TMP/$suite.log" --path "$ROOT" \
    --script "tests/${suite}_test.gd" >"$out" 2>&1 &
  pid=$!
  reason=""
  while kill -0 "$pid" 2>/dev/null; do
    if grep -q 'SCRIPT ERROR' "$out"; then reason="script error"; break; fi
    if [[ $allow_engine_errors -eq 0 ]] && grep -q '^ERROR:' "$out"; then reason="engine error"; break; fi
    if (( $(date +%s) - start >= TIMEOUT )); then reason="timeout after ${TIMEOUT}s"; break; fi
    sleep 0.2
  done
  if [[ -n "$reason" ]]; then
    kill "$pid" 2>/dev/null; sleep 0.5; kill -9 "$pid" 2>/dev/null
    wait "$pid" 2>/dev/null
  else
    wait "$pid"; rc=$?
    if grep -q 'SCRIPT ERROR' "$out"; then reason="script error"
    elif [[ $allow_engine_errors -eq 0 ]] && grep -q '^ERROR:' "$out"; then reason="engine error"
    elif [[ $rc -ne 0 ]]; then reason="exit code $rc"
    elif ! grep -q ': valid' "$out"; then reason="no ': valid' line"
    fi
  fi
  secs=$(( $(date +%s) - start ))

  if [[ -z "$reason" ]]; then
    passed=$((passed + 1))
    printf 'PASS  %-24s %3ss\n' "$suite" "$secs"
    summary+="| $suite | ✅ pass | ${secs}s |"$'\n'
  else
    failed=$((failed + 1))
    printf 'FAIL  %-24s %3ss  (%s)\n' "$suite" "$secs" "$reason"
    grep -E -A2 'SCRIPT ERROR|^ERROR:' "$out" | head -12 | sed 's/^/      /'
    [[ "$reason" == timeout* || "$reason" == "no ': valid' line" ]] && tail -5 "$out" | sed 's/^/      /'
    summary+="| $suite | ❌ $reason | ${secs}s |"$'\n'
  fi
done

echo "----"
echo "$passed passed, $failed failed"
if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  {
    echo "### Godot test suites: $passed passed, $failed failed"
    echo "| Suite | Result | Time |"
    echo "| --- | --- | --- |"
    printf '%s' "$summary"
  } >> "$GITHUB_STEP_SUMMARY"
fi
[[ $failed -eq 0 ]]
