---------------------------- MODULE RecordedTrace ----------------------------
EXTENDS RequestResponse, Naturals, Sequences

CONSTANT Recording

GoodRecording == <<"idle", "pending", "pending", "responded">>
BadRecording == <<"idle", "responded", "pending", "responded">>

RECURSIVE Frontier(_, _)
Frontier(trace, i) ==
    IF i = 1 THEN
        {s \in {Initial} : s.phase = trace[1]}
    ELSE
        LET previous == Frontier(trace, i - 1) IN
        { t \in States :
            t.phase = trace[i] /\
            \E s \in previous : Allowed(s, t) \/ s = t }

TraceSupported == (state = Initial) /\ (Frontier(Recording, Len(Recording)) /= {})
Stay == UNCHANGED state
=============================================================================
