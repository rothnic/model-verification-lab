import Base

type State is Data:
  Idle{}
  Pending{}
  Responded{}

type Command is Data:
  Accept{}
  Retry{}
  Respond{}

type Decision is Data:
  Denied{}
  Next{state: State}

def step(state: State, command: Command) -> Decision:
  match state:
    case Idle{}:
      match command:
        case Accept{}:
          Next{Pending{}}
        case Retry{}:
          Denied{}
        case Respond{}:
          Denied{}
    case Pending{}:
      match command:
        case Accept{}:
          Denied{}
        case Retry{}:
          Next{Pending{}}
        case Respond{}:
          Next{Responded{}}
    case Responded{}:
      Denied{}

def reached_response(decision: Decision) -> Bool:
  match decision:
    case Denied{}:
      False{}
    case Next{state}:
      match state:
        case Idle{}:
          False{}
        case Pending{}:
          False{}
        case Responded{}:
          True{}

def state_after(state: State, decision: Decision) -> State:
  match decision:
    case Denied{}:
      state
    case Next{next}:
      next

def run(commands: List<Command>, +state: State) -> State:
  match commands:
    case Nil{}:
      state
    case Con{command, rest}:
      run(rest, state_after(state, step(state, command)))

def main() -> List<State>:
  Con{run(Respond{} <> Nil{}, Idle{}),
  Con{run(Accept{} <> Retry{} <> Respond{} <> Nil{}, Idle{}), Nil{}}}
