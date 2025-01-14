/*
	Function:
	RSTF_fnc_spawnBoughtVehicle

	Description:
	Spawns vehicle bought through vehicle menu or bought by AI.

	Parameter(s):
	_unit - unit that bought the vehicle [Object]
	_side - side index that the unit is on [Number]
	_vehicleClass - classname of vehicle to be spawned [String]

	Returns:
	Spawned vehicle [Object]
*/

private _unit = param [0];
private _side = param [1];
private _vehicleClass = param [2];

private _parents = [configFile >> "cfgVehicles" >> _vehicleClass, true] call BIS_fnc_returnParents;
private _plane = "Plane" in _parents;
private _air = "Air" in _parents;

private _distance = (RSTF_SPAWN_DISTANCE_MIN + random(RSTF_SPAWN_DISTANCE_MAX - RSTF_SPAWN_DISTANCE_MIN)) + 500;
private _height = 0;

if (_air) then {
	_distance = 1000;
	_height = 500;
};

if (_plane) then {
	_distance = 3000;
	_height = 500;
};

// Spawn vehicle
private _radius = 0;
private _position = [];
private _direction = RSTF_DIRECTION;

if (_side == SIDE_ENEMY) then {
	_direction = _direction + 180;
};

while { true } do {
	private _center = (RSTF_SPAWNS select _side) vectorAdd [
		sin(_direction + 180) * _distance,
		cos(_direction + 180) * _distance,
		_height
	];
	_position = [_side, _center, _direction, 300, 60, _air] call RSTF_fnc_randomSpawn;

	if (!_air) then {
		private _roads = _position nearRoads 100;
		if (count(_roads) == 0) then {
			_roads = _position nearRoads 200;
		};
		if (count(_roads) == 0) then {
			_roads = _position nearRoads 300;
		};

		if (count(_roads) > 0) then {
			_position = getPos(selectRandom(_roads));
		} else {
			_position = _position findEmptyPosition [0, 100, _vehicleClass];
		};
	} else {
		_position set [2, _height];
	};

	if (count(_position) > 0 && { _air || !(surfaceIsWater _position) }) exitWith {};

	_distance = _distance - 100;
};

/*
private _direction = (RSTF_SPAWNS select _side) getDir RSTF_POINT;
private _position = (RSTF_SPAWNS select _side) vectorAdd [
	sin(_direction + 180) * _distance,
	cos(_direction + 180) * _distance,
	_height
];
private _radius = 100;
*/

// _position = _position findEmptyPosition [0, 100, _vehicleClass];
// if (count(_position) == 0) then { _radius = 100; _position = (RSTF_SPAWNS select _side); };

private _vehicle = createVehicle [_vehicleClass, _position, [], _radius, "FLY"];

// Add to GC with 30 seconds to despawn
if (RSTF_CLEAN) then {
	[_vehicle, RSTF_CLEAN_INTERVAL_VEHICLES, true] call RSTFGC_fnc_attach;
};

// Spawn vehicle crew
createVehicleCrew _vehicle;

_vehicle setDir _direction;

if (_plane) then {
	_vehicle setPos _position;
	_vehicle setVelocity [100 * (sin _direction), 100 * (cos _direction), 0];
};


// DEBUG - Track unit position
if (RSTF_DEBUG) then {
	private _marker = createMarkerLocal [str(_vehicle), getPos(_vehicle)];
	_marker setMarkerShape "ICON";
	_marker setMarkerType "c_car";
	_marker setMarkerColor (RSTF_SIDES_COLORS select _side);
};

// Create group on correct side and assign crew to it
private _group = createGroup (RSTF_SIDES_SIDES select _side);
units(group(effectiveCommander(_vehicle))) joinSilent _group;

if (!isNull(_unit)) then {
	// Remove effective commander
	deleteVehicle effectiveCommander(_vehicle);
};

// Make sure crew works same as other soldiers
{
	// TODO: What about name? It's important for money tracking
	_x setVariable ["SPAWNED_SIDE", side(_group), true];
	_x setVariable ["SPAWNED_SIDE_INDEX", _side, true];
	_x addEventHandler ["Killed", RSTF_fnc_unitKilled];
	[_x, RSTF_CLEAN_INTERVAL] call RSTFGC_fnc_attach;
} foreach units(_group);

if (!isNull(_unit)) then {
	// Move player into vacant slot and make him leader
	[_unit] joinSilent _group;
	_unit moveInAny _vehicle;
	_group selectLeader _unit;
} else {
	if (!RSTF_SPAWN_VEHICLES_UNLOCKED) then {
		// Stop player from entering friendly AI vehicles
		_vehicle setVehicleLock "LOCKEDPLAYER";
	};
};

_vehicle setVariable ["SPAWNED_SIDE", side(_group), true];
_vehicle addEventHandler ["Killed", RSTF_fnc_vehicleKilled];

_vehicle;