params ['_group', '_side'];

_side != SIDE_NEUTRAL &&
(!RSTF_MODE_DEFEND_ENABLED || _side == SIDE_ENEMY) &&
RSTF_MONEY_ENABLED &&
RSTF_MONEY_VEHICLES_ENABLED &&
count(RSTF_AI_VEHICLES select _side) < RSTF_MONEY_VEHICLES_AI_LIMIT