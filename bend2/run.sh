#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
bend="${BEND:-bend}"
proof_mode="${1:---check-only}"
case "$proof_mode" in
  --check-only|--verdict) ;;
  *) echo "usage: $0 [--check-only|--verdict]" >&2; exit 2 ;;
esac
test "$("$bend" version)" = 'bend 2.0.40'
temp="$(mktemp -d)"
trap 'rm -rf "$temp"' EXIT

echo "$("$bend" version); proof mode: $proof_mode"
out="$("$bend" main.bend)"
echo "safe execution: $out"
test "$out" = '[Idle{}, Responded{}]'
"$bend" PROOF.bend "$proof_mode"

cp main.bend LAWS.bend PROOF.bend "$temp/"
python3 - "$temp/main.bend" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
source = p.read_text()
old = "        case Respond{}:\n          Denied{}"
if source.count(old) != 1:
    raise SystemExit("expected exactly one mutation site")
p.write_text(source.replace(old, "        case Respond{}:\n          Next{Responded{}}"))
PY

out="$("$bend" "$temp/main.bend")"
echo "mutant execution: $out"
test "$out" = '[Responded{}, Responded{}]'
set +e
"$bend" "$temp/PROOF.bend" "$proof_mode" >"$temp/mutant.log" 2>&1
status=$?
set -e
cat "$temp/mutant.log"
test "$status" -eq 1
grep -q 'SOME PROOFS FAIL' "$temp/mutant.log"
grep -q 'Laws.no_response_from_idle' "$temp/mutant.log"
echo "mutant proof rejected as expected (exit $status)"
