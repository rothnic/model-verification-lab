--------------------------- MODULE RequestResponse ---------------------------
EXTENDS TLC

CONSTANT AllowEarlyResponse
VARIABLE state

Initial == [phase |-> "idle", accepted |-> FALSE, retryParity |-> FALSE]
States == [phase : {"idle", "pending", "responded"},
           accepted : BOOLEAN, retryParity : BOOLEAN]

Accept(s, t) == s.phase = "idle" /\
    t = [s EXCEPT !.phase = "pending", !.accepted = TRUE]
Respond(s, t) == s.phase = "pending" /\
    t = [s EXCEPT !.phase = "responded"]
Retry(s, t) == s.phase = "pending" /\
    t = [s EXCEPT !.retryParity = ~s.retryParity]
EarlyResponse(s, t) == AllowEarlyResponse /\ s.phase = "idle" /\
    t = [s EXCEPT !.phase = "responded"]

Allowed(s, t) == Accept(s, t) \/ Respond(s, t) \/ Retry(s, t) \/ EarlyResponse(s, t)

Init == state = Initial
Next == \E t \in States : Allowed(state, t) /\ state' = t
ResponseStep == \E t \in States : Respond(state, t) /\ state' = t

Spec == Init /\ [][Next]_state
FairSpec == Spec /\ WF_state(ResponseStep)

TypeOK == state \in States
RespondedOnlyAfterAccept == state.phase = "responded" => state.accepted
PendingEventuallyResponds == (state.phase = "pending") ~> (state.phase = "responded")
=============================================================================
