#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"
: "${TLA2TOOLS_JAR:?Set TLA2TOOLS_JAR to the absolute path of tla2tools.jar.}"

metadata=$(mktemp -d)
trap 'rm -rf -- "$metadata"' EXIT

check() {
    local cfg=$1 module=$2 expected=$3 marker=$4 code=0 log
    log="$metadata/$cfg.log"
    java -XX:+UseParallelGC -cp "$TLA2TOOLS_JAR" tlc2.TLC \
        -noGenerateSpecTE -workers 1 -metadir "$metadata/$cfg" \
        -config "$cfg.cfg" "$module.tla" > "$log" 2>&1 || code=$?
    if [[ $code != "$expected" ]] || ! grep -Fq "$marker" "$log"; then
        cat "$log" >&2
        printf '%s: expected TLC exit %s and message %s, got exit %s\n' "$cfg" "$expected" "$marker" "$code" >&2
        return 1
    fi
    printf '%s: TLC exit %s; ' "$cfg" "$code"
    grep -Fm1 "$marker" "$log"
}

check fair RequestResponse 0 'Model checking completed. No error has been found.'
check unfair RequestResponse 13 'Temporal property PendingEventuallyResponds was violated.'
check mutant RequestResponse 12 'Invariant RespondedOnlyAfterAccept is violated.'
check trace-good RecordedTrace 0 'Model checking completed. No error has been found.'
check trace-bad RecordedTrace 12 'Invariant TraceSupported is violated'
