# Model Verification Lab

What can you check before you write the software? What can you check again once it exists? These small, runnable experiments compare tools that answer different parts of those questions. They use synthetic systems so the examples can be read and run on their own.

## One example, two different kinds of evidence

Take a request that starts idle, is accepted, and then gets a response. We want two different guarantees:

- **Safety:** Don't respond before accepting the request.
- **Progress:** An accepted request shouldn't stay pending forever, even if it can be retried.

| Tool | What you write | What you learn |
| --- | --- | --- |
| [TLA+ and TLC](tla/) | A model of the initial states, allowed steps, and rules that should hold. This is separate from the code you ship. | TLC explores the reachable states in the selected finite model. It can give you an execution that breaks safety, or a loop that breaks progress. If you add a fairness assumption, the result applies only when that assumption holds. |
| [Bend 2](bend2/) | Executable functions plus a law and a proof about those functions. | In this example, Bend's ordinary proof checker accepts proofs of two laws about the executable code and rejects the same proof after an early-response change. We didn't run Bend's separate Lean-backed `--verdict` here. The checks don't cover scheduling, foreign code, or whether a service will run a step. |
| [OpenSysML](https://github.com/Open-MBEE/OpenSysML/issues/2501) | Structure and executable behavior in the same SysML model. | OpenSysML already checks reachable design states and replays failures. The linked proposals improve replay, add one narrow progress check, and check whether an external recording fits one possible model run. |

**Results you can reproduce:** [The TLC run](tla/evidence.txt) checks all five reachable states of the fair request model, finds a progress violation without fairness, and catches the early-response mutation. Its recording check accepts one history and rejects another with the same final state. [The Bend run](bend2/evidence.txt) executes the good and mutated code, and the proof checker rejects the mutation. The Bend law covers every command from idle and the response step from pending, not all sequences or eventual response.

The OpenSysML proposals have their own runnable tests and examples: [replay a design failure](https://github.com/Open-MBEE/OpenSysML/pull/2502), [detect a pending request that can loop forever](https://github.com/Open-MBEE/OpenSysML/pull/2503), and [compare a charger recording with its model](https://github.com/Open-MBEE/OpenSysML/pull/2504). They are separate proposals, not a claim that both checkers accept the same model language or all the same properties.

These aren't three specifications I'd maintain for one product. I want one model of what the system should do. A separate reference example is useful here because it lets us compare exactly what each tool checks.

## From the model to a real test

The [request desk example](e2e/request-desk/) runs the full path locally: Playwright clicks through a real browser, a Node server calls compiled Bend 2 code, and OpenSysML checks the recorded screen states. A one-line display defect changes the middle of the journey, not the final screen.

A model check tells you what is possible in the model, not which behaviors your implementation actually has. A test can send real inputs and record the resulting outputs. The trace checker then asks whether one allowed model run explains that recording.

A reusable runner can handle recording, formatting, and reporting. A small Playwright or API adapter should only know how to apply an input, tell when the implementation has settled, and read the actual result. The adapter shouldn't copy the model's expected answers. That way a rewrite can keep the same journey and expectations while changing only the bindings that need to change.

See [the OpenSysML tracking issue](https://github.com/Open-MBEE/OpenSysML/issues/2501) for its proposed workflow, including what isn't implemented yet.

## Other tools looked at

- **Everystate:** Used to cross-check a small TLA+ model against TLC and to accept or reject synthetic recordings. It runs TLA+ models; it isn't a separate system specification.
- **GraphWalker:** Exercised graph validation and path generation. Those checks don't by themselves prove a safety rule or tell you whether the application matched the expected behavior.
- **Stateright:** Evaluated as a Rust-native model-checking option. This repository doesn't yet contain a runnable Stateright comparison.

References: [TLC's command-line tools](https://github.com/tlaplus/tlaplus/blob/master/USE.md), [TLA+ implementation trace validation](https://github.com/tlaplus/vscode-tlaplus/blob/master/resources/knowledgebase/tlc-trace-validation.md), and [Bend 2's language and proofs](https://github.com/bendlang/bend).
