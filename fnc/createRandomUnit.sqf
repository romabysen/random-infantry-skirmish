private ["_group", "_index", "_unit"];
	
_group = _this select 0;
_index = _this select 1;

_unit = _group createUnit [_index call RSTF_getRandomSoldier, RSTF_SPAWNS select _index, [], 100, "NONE"];
if (isNull(_unit)) then {
	systemChat "FAILED TO SPAWN AI!";
};

_unit setSkill random(1);

[_unit] joinSilent _group;
[_unit, _index] call RSTF_equipSoldier;

if (side(_unit) == side(player)) then {
	setPlayable _unit;
	if (!PLAYER_SPAWNED) then {
		PLAYER_SPAWNED = true;
		PLAYER_SIDE = side(player);
		_unit call RSTF_assignPlayer;
	};
};

_unit setVariable ["SPAWNED_SIDE", side(_group)];
_unit addEventHandler ["Killed", RSTF_unitKilled];

_unit;