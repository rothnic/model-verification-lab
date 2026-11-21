# Browser recordings

These two synthetic recordings were captured from the actual app with Playwright. The action sequence is the same in both: respond too early, submit, retry, then respond. Only the status shown after Submit differs. Both recordings end in `responded`.

You can use these recordings to try just the model checker without installing Playwright, Bend, or Chromium. From the enclosing request-desk directory, with a [trace-enabled OpenSysML build](../README.md#run-locally):

```sh
machine='RequestDesk::Desk::Journey RequestDesk::desk'
"$SYSML_BIN" -state "$machine" -check-trace sysml-fixtures/healthy.jsonl RequestDesk.sysml
"$SYSML_BIN" -state "$machine" -check-trace sysml-fixtures/early-response.jsonl RequestDesk.sysml
```

The normal recording matches through row 5 (exit 0). The broken display is rejected at row 3 (exit 1). Add `-check-depth 1` to the first command to see the checker report an inconclusive result rather than a false mismatch (exit 2). Run the full example to record new traces from the browser.
