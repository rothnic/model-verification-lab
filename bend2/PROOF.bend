import Base
import ./main.bend as Machine
import ./LAWS.bend as Laws

def Laws.no_response_from_idle(command):
  match command:
    case Machine.Accept{}:
      {==}
    case Machine.Retry{}:
      {==}
    case Machine.Respond{}:
      {==}

def Laws.pending_responds():
  {==}
