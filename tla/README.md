# TLA+ request/response example

One request starts idle, can be accepted, and then gets a response. A retry
keeps it pending but toggles a hidden bit, so that it is a genuine state
transition rather than just waiting. This deliberately omits queues, time,
multiple requests and real implementation code.

## Run it

Requires Java and the official [TLC release JAR](https://github.com/tlaplus/tlaplus/releases/tag/v1.8.0).
The runner does not install or download anything.

```sh
TLA2TOOLS_JAR=/absolute/path/to/tla2tools.jar ./run.sh
```

| Configuration | Expected TLC result |
| --- | --- |
| `fair.cfg` | Safety and eventual response pass for all behaviors under weak fairness of response |
| `unfair.cfg` | Eventual response fails; an accepted request can remain pending |
| `mutant.cfg` | Safety fails; the model can respond before acceptance |
| `trace-good.cfg` | The recorded phase sequence fits a model execution |
| `trace-bad.cfg` | The recorded phase sequence does not fit, though its final phase is the same |

The runner expects the negative cases to fail for the named reasons. The
runner itself exits zero only if all five outcomes agree. To see an entire
counterexample, run TLC directly, for example:

```sh
java -cp "$TLA2TOOLS_JAR" tlc2.TLC -noGenerateSpecTE -workers 1 -config unfair.cfg RequestResponse.tla
```

`RespondedOnlyAfterAccept` is an invariant, not an eventuality.
`PendingEventuallyResponds` says that once accepted, the request eventually
gets a response. Weak fairness is an explicit assumption: while the response
stays continuously enabled, it must eventually occur. The model without fairness
permits both stalling and infinite retry; TLC can report either violating run.
The fair model does not guarantee that an idle request will ever be accepted,
or that any response occurs within a specific time.

## Check a recording without another model

`RecordedTrace.tla` uses `Allowed` from the same authored model. It reads a
short, synthetic sequence of observed phases. At each observation it retains
every compatible hidden state reachable from a previously retained one.
Each pair of adjacent observations represents one modeled transition or an
unchanged state. The checker does not see acceptance or retry parity directly,
does not invent implementation events, and does not require a given fair
completion for a finite prefix. A match is existential: some model history
fits this recording, not every history or every implementation execution.

Both fixture recordings end in `responded`. The bad one places an earlier
`responded` before acceptance could occur, which empties the compatible
frontier. These are phase snapshots only, not timestamps or tagged input
events. No external JSON import, compilation, or adapter is implied.
