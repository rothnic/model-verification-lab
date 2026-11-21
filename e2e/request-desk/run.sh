#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"
: "${SYSML_BIN:?Set SYSML_BIN to the absolute path to a sysml binary with -check-trace (see README).}"
BEND="${BEND:-bend}"
work="$(mktemp -d)"
trap 'rm -rf -- "$work"' EXIT
machine='RequestDesk::Desk::Journey RequestDesk::desk'

BEND="$BEND" bash ./build-bend.sh "$work/compiled.mjs"
node capture.mjs "$work/compiled.mjs" "$work/normal.jsonl"
node capture.mjs "$work/compiled.mjs" "$work/early-ui.jsonl" early-ui

check_trace() {
    local name=$1 expected_exit=$2 expected_status=$3 expected_row=$4 exit_code=0
    "$SYSML_BIN" -no-record-cache -json -state "$machine" \
        -check-trace "$work/$name.jsonl" RequestDesk.sysml >"$work/$name.json" || exit_code=$?
    if [[ $exit_code -ne $expected_exit ]]; then
        cat "$work/$name.json" >&2
        printf '%s: expected OpenSysML exit %s, got %s\n' "$name" "$expected_exit" "$exit_code" >&2
        return 1
    fi
    node --input-type=module - "$work/$name.json" "$name" "$expected_status" "$expected_row" <<'JS'
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
const [path, name, status, row] = process.argv.slice(2);
const result = JSON.parse(readFileSync(path, "utf8"));
assert.equal(result.status, status, name);
assert.equal(result.row, Number(row), name);
console.log(`${name}: ${result.status} at row ${result.row}`);
JS
}

check_trace normal 0 matched 5
check_trace early-ui 1 no_match 3

node --input-type=module - "$work/normal.jsonl" "$work/early-ui.jsonl" <<'JS'
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
for (const path of process.argv.slice(2)) {
    const rows = readFileSync(path, "utf8").trimEnd().split("\n").map(JSON.parse);
    assert.equal(rows.length, 5);
    assert.equal(rows.at(-1).observe.phase, "responded");
}
console.log("Both browser recordings end in responded.");
JS
