import Base
import ./main.bend as Machine

law no_response_from_idle:
  for command: Machine.Command
  {Machine.reached_response(Machine.step(Machine.Idle{}, command)) == False{} : Bool}

law pending_responds:
  {Machine.step(Machine.Pending{}, Machine.Respond{}) == Machine.Next{Machine.Responded{}} : Machine.Decision}
