#!/usr/bin/env bash
set -euo pipefail

if [[ $# != 1 || $1 != *.mjs ]]; then
  echo "usage: $0 OUTPUT.mjs" >&2
  exit 2
fi
out=$1
if [[ $out != /* ]]; then out="$PWD/$out"; fi
here="$(cd "$(dirname "$0")" && pwd)"
bend="${BEND:-bend}"
test "$("$bend" version)" = 'bend 2.0.40'
"$bend" "$here/../../bend2/PROOF.bend" --check-only >&2
"$bend" "$here/../../bend2/main.bend" -o "$out"

node --input-type=module - "$here/bend-engine.mjs" "$out" <<'JS'
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
const [bridge, compiled] = process.argv.slice(2);
const {createEngine} = await import(pathToFileURL(bridge).href);
const engine = await createEngine(compiled);
assert.equal(engine.step('idle', 'respond'), 'idle');
let state = 'idle';
for (const [command, expected] of [
  ['submit', 'pending'], ['retry', 'pending'], ['respond', 'responded'],
]) {
  state = engine.step(state, command);
  assert.equal(state, expected);
}
console.error('Compiled Bend engine smoke: early response denied; submit, retry, respond passed.');
JS
printf '%s\n' "$out"
