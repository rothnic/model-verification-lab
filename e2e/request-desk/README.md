# A browser journey checked against a model

This local app is a tiny request desk. You can submit a request, ask it to retry, or respond. A response before submission should do nothing. Once submitted, the request stays pending through a retry and moves to responded when you choose Respond.

## Follow one request through the stack

1. **Playwright drives the page.** It clicks Respond too early, then Submit, Retry, and Respond. The adapter waits for each request to finish and records whatever the page actually shows. It doesn't decide what the right answer is.
2. **The server runs Bend 2 code.** The host sends each command to the compiled [Bend state transition function](../../bend2/main.bend). The JavaScript bridge converts inputs and outputs; it does not implement the state rules. The ordinary Bend proof check runs before compiling.
3. **OpenSysML checks the recording.** The [SysML model](RequestDesk.sysml) says which actions and user-visible statuses can go together. It checks the JSON Lines recording from the browser, not values supplied by the model or the server.

The runner repeats the same journey with one deliberately broken display: after a valid Submit, the page says “responded” even though the server is still pending. Both journeys still end at “responded.” The Bend rules haven't changed, so its checks still pass; OpenSysML rejects the browser recording at line 3. Checking only the final screen would miss it.

## Run locally

You'll need:

- Node.js and npm.
- An installed Chromium executable. Set `CHROMIUM_BIN` if it isn't at `/usr/bin/chromium`. There is no Playwright-managed browser download.
- [Bend 2.0.40](https://github.com/bendlang/bend/releases/tag/v2.0.40); set `BEND` to its path if it isn't on your PATH.
- A `sysml` binary with `-check-trace`. This example was built for [OpenSysML PR #2504](https://github.com/Open-MBEE/OpenSysML/pull/2504), exact [head d2dcdf96](https://github.com/rothnic/OpenSysML/tree/d2dcdf9688d14179a02856857fb90a890ddbcc49). From that checkout, build it with `make build-sysml` and use the absolute path to `bin/sysml`.

From this directory:

```sh
npm ci --ignore-scripts --no-audit --no-fund
BEND=/absolute/path/to/bend \
SYSML_BIN=/absolute/path/to/sysml \
CHROMIUM_BIN=/usr/bin/chromium \
./run.sh
```

Expected result: the normal recording matches all five rows; the early-display mutation is rejected at row 3; both final screens read “responded.” The negative case is part of the pass criteria, not a test failure to ignore.

## When I'd use which tool

- **Bend 2 for a small, pure rule you can run in production.** Here that's the rule that a command from idle can't produce a response. The [standalone Bend runner](../../bend2/) changes that rule's implementation and confirms that the unchanged proof no longer passes. This example uses the ordinary proof check, not the separate Lean-backed verdict. It doesn't say what the page rendered or tell you that a scheduler will eventually respond.
- **TLC for design questions before choosing an implementation.** The [companion TLA+ experiment](../../tla/) asks what happens if a pending request can retry forever, and shows exactly what changes when response is assumed to be fairly scheduled. A finite browser recording can't establish that progress property. That TLA+ experiment is a comparator, not an extra specification for this browser test.
- **OpenSysML and the small adapter for the behavior people actually see.** This run checks the observed sequence against the model, including the incorrectly rendered intermediate state. For a rewrite, keep the modeled journey and expected behavior; adapt only the page controls and observed status. The recording covers the selected journey, not every possible interaction.

This is a single in-memory request in a local demo. It doesn't verify storage, concurrency, timing, other user journeys, the compiler, or the runtime.
