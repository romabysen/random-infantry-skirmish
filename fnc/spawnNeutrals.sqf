//Load usable houses in area, only use bigger houses
_houses = nearestObjects [RSTF_POINT, ["House"], RSTF_NEUTRALS_RADIUS];
_usable = [];
{
	_positions = []; _i = 0;
	while{ (_x buildingPos _i) distance [0,0,0] > 0 } do
	{
		_positions set [count(_positions), [_i,_x buildingPos _i]];
		_i = _i + 1;
	};
	if (count(_positions) >= 4 && !(typeOf(_x) in RSTF_BANNED_BUILDINGS)) then
	{
		_usable set [count(_usable), [_x, _positions]];
	};
} foreach _houses;

//Can't have more groups then houses
if (count(_usable) < RSTF_NEUTRALS_GROUPS) then {
	RSTF_NEUTRALS_GROUPS = count(_usable);
};

//Shuffle buildings, so accessing it by incerasing index will access them randomly
//This will ensure every building will be used once
_usable = _usable call BIS_fnc_arrayShuffle;

//Now create neutral groups
for[{_i = 0},{_i < RSTF_NEUTRALS_GROUPS},{_i = _i + 1}] do {
	//Decide count of units inside building
	_units = RSTF_NEUTRALS_UNITS_MIN + round(random(RSTF_NEUTRALS_UNITS_MAX - RSTF_NEUTRALS_UNITS_MIN));
	
	_house = (_usable select _i) select 0;
	_positions = (_usable select _i) select 1;
	
	//Create helper
	/*_marker = createMarker ["HOUSE " + str(_i), getPos(_house)];
	_marker setMarkerShape "ICON";
	_marker setMarkerType "MIL_DOT";
	_marker setMarkerText ("House " + str(_i));*/
	
	//Shuffle positions, then access them by linear index, ensuring no position is used twice
	_positions = _positions call BIS_fnc_arrayShuffle;
	_units = _units max count(_positions);
	
	_spawned = [];
	for[{_u = 0},{_u < _units && _u < count(_positions)},{_u = _u + 1}] do {
		_position = (_positions select _u) select 1;
	
		//Every unit has its own group, this way they wont run off their position
		//@TODO: Is there better way?
		_group = creategroup resistance;
		
		//Create equipped unit
		_unit = [_group, SIDE_NEUTRAL] call RSTF_createRandomUnit;
		_dir = [getPos(_house), _position] call BIS_fnc_dirTo;
		_group setFormDir _dir;
		_unit setDir _dir;
		
		//Set his task
		_wp = _group addWaypoint [_position, 0];
		_wp waypointAttachObject _house;
		_wp setWaypointHousePosition ((_positions select _u) select 0);
		_wp setWaypointType "MOVE";
		_wp setWaypointSpeed "LIMITED";
		
		//Ensure unit is on right side
		[_unit] joinSilent _group;
		
		//Make sure he's right in specified position
		_unit setPos _position; 
		
		//Units tend to prone and do nothing
		_unit setUnitPos "UP";
		
		_spawned set [count(_spawned), _unit];
		//Units tend to move outside
		//_unit disableAI "MOVE";
		//Look suprised!
		//_unit setBehaviour "SAFE";
	};
	
	RSRF_NEUTRAL_HOUSES set [count(RSRF_NEUTRAL_HOUSES), [_house, _spawned]];
};

RSRF_NEUTRAL_HOUSES = [RSRF_NEUTRAL_HOUSES, [], { (_x select 0) distance (RSTF_SPAWNS select SIDE_FRIENDLY) }, "ASCEND"] call BIS_fnc_sortBy;