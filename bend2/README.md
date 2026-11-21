# Bend 2: verify the executable request rules

This comparison uses **Bend 2**, not Bend 1 or the old HVM runtime. The
[original Bend2 repository](https://github.com/HigherOrderCO/Bend2) points to
[the current official repository](https://github.com/bendlang/bend), the same
URL that was shared. Tested release: [v2.0.40](https://github.com/bendlang/bend/releases/tag/v2.0.40),
tag `624dd9f4607cd29b0871a9b96d413bfb11e92f52`. See the
[official pinned guide](https://github.com/bendlang/bend/blob/v2.0.40/guide/GUIDE.md)
for laws, proofs, and the optional kernel verification.

- `main.bend` implements `step`: Accept moves Idle to Pending, Retry leaves
  Pending unchanged, and Respond moves Pending to Responded. An invalid
  command is denied and the runner retains the current state.
- `LAWS.bend` states that **for every Command** a step from Idle cannot
  produce a response, and that Respond from Pending does produce one.
- `PROOF.bend` proves the first law by splitting on all three command
  constructors and the second by evaluating the named step.
- `run.sh` executes a lawful case and a forbidden early response, checks the
  proofs, mutates only the executable rule in a disposable copy, and checks
  that the identical law/proof rejects it. The mutant executes but wrongly
  responds to the first command; proof checking, not type checking alone,
  catches it.

## Run

Use Bend 2.0.40 and Python 3. The published release archive can be retrieved
from the linked release and extracted without running an installer. The
Linux x64 archive SHA-256 is
`c9ff8d67bd903fb6ad9a26b43d8a62c01021de82a44d55ce4a3dcd4732113d6b`.

```sh
BEND=/path/to/bend/bin/bend ./run.sh
# Optional, requires Lean 4.34.0 or a built BendTT kernel:
BEND=/path/to/bend/bin/bend ./run.sh --verdict
```

The actual Linux x64 run is in [evidence.txt](evidence.txt). The bundled
Bend checker accepted the proof and rejected the mutation. Its positive
output says `ALL PROOFS CHECK` and then `Use --verdict for mathematical validity.`
We did **not**
complete the optional `--verdict` recheck with BendTT: the release reported
that it needs Lean 4.34.0 or a built kernel, and the full pinned Lean archive
was too large to extract within the scratch budget. Treat the verified
result as an ordinary compiler proof check, not a second kernel verdict.
The optional runner mode has not been validated here; the tested path is
`--check-only`.

## What this verifies

The checked statements are about the **specified executable step function**,
not just the two sample runs. They do not establish a general property for
every finite or infinite trace, all possible integrations, or eventual
response: repeating Retry forever is consistent with the step function.
A temporal checker is needed here if the question is whether all modeled
schedules progress, and under what fairness assumptions. The proof also
does not establish correctness of a separate implementation, or equivalence
of compiled backends in general.
