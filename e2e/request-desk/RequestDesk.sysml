package RequestDesk {
    private import ScalarValues::*;

    attribute def Submit;
    attribute def Retry;
    attribute def Respond;

    part def Desk {
        attribute phase : String = "idle";

        exhibit state Journey {
            entry; then idle;
            state idle;
            state pending { entry assign phase := "pending"; }
            state responded { entry assign phase := "responded"; }

            transition first idle accept Respond then idle;
            transition first idle accept Submit then pending;
            transition first pending accept Retry then pending;
            transition first pending accept Respond then responded;
        }
    }

    part desk : Desk;
}
