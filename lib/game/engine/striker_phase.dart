/// The striker's turn FSM. PLACING = position the striker; AIMING = pull-back
/// aiming; SIMULATING = physics running, input locked.
enum StrikerPhase { placing, aiming, simulating }
