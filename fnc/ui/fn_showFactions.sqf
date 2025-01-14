disableSerialization;

waitUntil { time > 0 };

showCinemaBorder false;

_ok = createDialog "RSTF_RscDialogFactions";
if (!_ok) exitWith {
	systemChat "Fatal error. Couldn't create factions dialog.";
};

_list = _this select 0;
_event = _this select 1;

RSTF_FACTIONS_LIST = _list;
RSTF_FACTIONS_EVENT = _event;
RSTF_FACTIONS_SOLDIER = objNull;
RSTF_FACTIONS_GROUP = creategroup civilian;
RSTF_FACTIONS_WEAPON = objNull;
RSTF_FACTIONS_WEAPON_HOLDER = createVehicle ["Land_Can_V3_F", RSTF_CAM_SPAWN,[],0, "CAN_COLLIDE"];
RSTF_FACTIONS_WEAPON_HOLDER setPos RSTF_CAM_SPAWN;
RSTF_FACTIONS_WEAPON_HOLDER setVectorDirAndUp [[0,0,1],[0,-1,0]];
RSTF_FACTIONS_WEAPON_HOLDER hideObject true;
RSTF_FACTIONS_WEAPON_HOLDER enableSimulation false;
RSTF_FACTIONS_VEHICLES = [];
RSTF_FACTIONS_SOLDIERS = [];

RSTF_EXPANDED = createHashMap;

_display = "RSTF_RscDialogFactions" call RSTF_fnc_getDisplay;
_display displayAddEventHandler ["unload", {
	if (!isNull(RSTF_FACTIONS_SOLDIER)) then {
		deleteVehicle RSTF_FACTIONS_SOLDIER;
		RSTF_FACTIONS_SOLDIER = objNull;
	};

	if (!isNull(RSTF_FACTIONS_WEAPON)) then {
		deleteVehicle RSTF_FACTIONS_WEAPON;
		RSTF_FACTIONS_WEAPON = objNull;
	};

	if (!isNull(RSTF_FACTIONS_WEAPON_HOLDER)) then {
		deleteVehicle RSTF_FACTIONS_WEAPON_HOLDER;
		RSTF_FACTIONS_WEAPON_HOLDER = objNull;
	};

	RSTF_FACTIONS_LIST call RSTF_FACTIONS_EVENT;
}];

_ctrl = ["RSTF_RscDialogFactions", "selectRandom"] call RSTF_fnc_getCtrl;
_ctrl ctrlAddEventHandler ["ButtonClick", {
	// Build list of already used factions
	private _used = [];
	{
		{
			_used pushBack _x;
		} foreach _x;
	} foreach [FRIENDLY_FACTIONS, NEUTRAL_FACTIONS, ENEMY_FACTIONS];

	// Load list of unused factions
	private _unused = [];
	{
		if (!(_x in _used)) then {
			_unused pushBack _x;
		};
	} foreach RSTF_FACTIONS;

	if (count(_unused) > 0) then {
		private _selected = selectRandom _unused;
		RSTF_FACTIONS_LIST pushBack _selected;
		call RSTF_fnc_factionsUpdate;
	};
}];

_ctrl = ["RSTF_RscDialogFactions", "clear"] call RSTF_fnc_getCtrl;
_ctrl ctrlAddEventHandler ["ButtonClick", {
	RSTF_FACTIONS_LIST = [];
	call RSTF_fnc_factionsUpdate;
}];

_ctrl = ["RSTF_RscDialogFactions", "close"] call RSTF_fnc_getCtrl;
_ctrl ctrlAddEventHandler ["ButtonClick", {
	call RSTF_fnc_profileSave;
	closeDialog 0;
}];

_template_list = '_ctrl = ["RSTF_RscDialogFactions", "%1"] call RSTF_fnc_getCtrl;
_row = lnbCurSelRow _ctrl;
if (_row >= 0) then {
	_class = _ctrl lnbData [_row, 0];
	_index = %2 find _class;
	if (_index >= 0) then {
		%2 = [%2, _index] call BIS_fnc_removeIndex;
	} else {
		%2 set [count(%2), _class];
	};

	call RSTF_fnc_factionsUpdate;
};';

RSTF_fnc_factionsIsFactionBanned = {
	params ["_faction"];

	if (count(RSTF_FACTIONS_SOLDIERS#0) == 0) exitWith {
		false;
	};

	private _banned = true;

	{
		private _f = getText(configFile >> "cfgVehicles" >> _x >> "faction");
		if (_f isEqualTo _faction && { !(_x in RSTF_SOLDIERS_BANNED) }) exitWith {
			_banned = false;
		};
	} foreach RSTF_FACTIONS_SOLDIERS#0;

	_banned;
};

RSTF_fnc_factionsGetVehicleClass = {
	private _cfg = configFile >> "cfgVehicles" >> param [0, "", [""]];
	private _class = getText(_cfg >> "vehicleClass");
	if (isText(_cfg >> "editorSubcategory")) then {
		_class = getText(_cfg >> "editorSubcategory");
	};
	_class;
};

RSTF_fnc_factionsIsFactionClassBanned = {
	params ["_faction", "_class"];

	if (count(RSTF_FACTIONS_SOLDIERS#0) == 0) exitWith {
		false;
	};

	private _banned = true;

	{
		private _f = getText(configFile >> "cfgVehicles" >> _x >> "faction");
		private _c = [_x] call RSTF_fnc_factionsGetVehicleClass;

		if (_f isEqualTo _faction && _c isEqualTo _class && { !(_x in RSTF_SOLDIERS_BANNED) }) exitWith {
			_banned = false;
		};
	} foreach RSTF_FACTIONS_SOLDIERS#0;

	_banned;
};

RSTF_fnc_factionsIsVehicleClassBanned = {
	params ["_classIndex"];

	if (count(RSTF_FACTIONS_VEHICLES#_classIndex) == 0) exitWith {
		false;
	};

	private _banned = true;

	{
		if (!(_x in RSTF_SOLDIERS_BANNED)) exitWith {
			_banned = false;
		};
	} foreach RSTF_FACTIONS_VEHICLES#_classIndex;

	_banned;
};


_template_tree = '_ctrl = ["RSTF_RscDialogFactions", "%1"] call RSTF_fnc_getCtrl;
_path = tvCurSel _ctrl;
_class = _ctrl tvData _path;
_prefix = if (count(_class) > 2) then { _class select [0, 2] } else { "" };

if (_prefix isEqualTo "V#") exitWith {
	private _index = parseNumber(_class select [2]);
	private _inverted = [_index] call RSTF_fnc_factionsIsVehicleClassBanned;
	{
		if (_inverted) then {
			%2 deleteAt (%2 find _x);
		} else {
			%2 pushBack _x;
		};
	} foreach RSTF_FACTIONS_VEHICLES#_index;
	call RSTF_fnc_factionsUpdate;
};

if (_prefix isEqualTo "F#") exitWith {
	private _faction = _class select [2];
	private _inverted = [_faction] call RSTF_fnc_factionsIsFactionBanned;
	{
		private _f = getText(configFile >> "cfgVehicles" >> _x >> "faction");
		if (_f isEqualTo _faction && { (!_inverted && !(_x in %2)) || (_inverted && _x in %2) }) then {
			if (_inverted) then {
				%2 deleteAt (%2 find _x);
			} else {
				%2 pushBack _x;
			};
		};
	} foreach RSTF_FACTIONS_SOLDIERS#0;
	call RSTF_fnc_factionsUpdate;
};

if (_prefix isEqualTo "C#") exitWith {
	private _data = (_class select [2]) splitString "/";
	private _faction = _data#0;
	private _class = _data#1;
	private _inverted = [_faction, _class] call RSTF_fnc_factionsIsFactionClassBanned;

	{
		private _f = getText(configFile >> "cfgVehicles" >> _x >> "faction");
		private _c = [_x] call RSTF_fnc_factionsGetVehicleClass;
		if (_f isEqualTo _faction && _c isEqualTo _class && { (!_inverted && !(_x in %2)) || (_inverted && _x in %2) }) then {
			if (_inverted) then {
				%2 deleteAt (%2 find _x);
			} else {
				%2 pushBack _x;
			};
		};
	} foreach RSTF_FACTIONS_SOLDIERS#0;
	call RSTF_fnc_factionsUpdate;
};

if (_class != "") then {
	_index = %2 find _class;
	_text = ((_ctrl tvText _path) splitString "\[BANNED\] ") joinString "";

	if (_index >= 0) then {
		%2 = [%2, _index] call BIS_fnc_removeIndex;
		_ctrl tvSetText [_path, _text];
		_ctrl tvSetPictureColor [_path, [1,1,1,1]];
	} else {
		%2 set [count(%2), _class];
		_ctrl tvSetText [_path, "[BANNED] " + _text];
		_ctrl tvSetPictureColor [_path, [0,0,0,1]];
	};
};';

_method = compile(format [_template_list, "factions", "RSTF_FACTIONS_LIST"]);
_ctrl = ["RSTF_RscDialogFactions", "toggleFaction"] call RSTF_fnc_getCtrl;
_ctrl ctrlAddEventHandler ["ButtonClick", _method];
_ctrl = ["RSTF_RscDialogFactions", "factions"] call RSTF_fnc_getCtrl;
_ctrl ctrlAddEventHandler ["LBDblClick", _method];

_expand = {
	_ctrl = _this select 0;
	_path = (_this select 1) call RSTF_fnc_pathString;

	_list = RSTF_EXPANDED get (ctrlIdc _ctrl);
	_list pushBackUnique _path;
};

_collapse = {
	_ctrl = _this select 0;
	_path = (_this select 1) call RSTF_fnc_pathString;

	_list = RSTF_EXPANDED get (ctrlIdc _ctrl);
	_index = _list find _path;
	if (_index != -1) then {
		RSTF_EXPANDED set [ctrlIdc _ctrl, [_list, _index] call BIS_fnc_removeIndex];
	};
};

_method = compile(format [_template_tree, "avaibleSoldiers", "RSTF_SOLDIERS_BANNED", 3]);
_ctrl = ["RSTF_RscDialogFactions", "banSoldier"] call RSTF_fnc_getCtrl;
_ctrl ctrlAddEventHandler ["ButtonClick", _method];
_ctrl = ["RSTF_RscDialogFactions", "avaibleSoldiers"] call RSTF_fnc_getCtrl;

RSTF_EXPANDED set [ctrlIdc _ctrl, []];
_ctrl ctrlAddEventHandler ["TreeExpanded", _expand];
_ctrl ctrlAddEventHandler ["TreeCollapsed", _collapse];

_ctrl ctrlAddEventHandler ["TreeDblClick", _method];
_ctrl ctrlAddEventHandler ["TreeSelChanged", {
	if (!isNull(RSTF_FACTIONS_SOLDIER)) then {
		deleteVehicle RSTF_FACTIONS_SOLDIER;
		RSTF_FACTIONS_SOLDIER = objNull;
	};

	if (!isNull(RSTF_FACTIONS_WEAPON)) then {
		deleteVehicle RSTF_FACTIONS_WEAPON;
		RSTF_FACTIONS_WEAPON = objNull;
	};

	_ctrl = ["RSTF_RscDialogFactions", "avaibleSoldiers"] call RSTF_fnc_getCtrl;
	_path = tvCurSel _ctrl;
	if (count(_path) == 3 || count(_path) == 2) then {
		_class = _ctrl tvData _path;
		if (_class != "") then {
			_position = RSTF_CAM_SPAWN;
			_isMan = getNumber(configFile >> "cfgVehicles" >> _class >> "isMan");

			if (_isMan != 0) then {
				RSTF_FACTIONS_SOLDIER = RSTF_FACTIONS_GROUP createUnit [_class, _position, [], 0, "CAN_COLLIDE"];
				RSTF_FACTIONS_SOLDIER setpos _position;
				RSTF_FACTIONS_SOLDIER enableSimulation false;
				RSTF_CAM camSetRelPos [0, 3, 1.5];
				RSTF_CAM camCommit 0.1;
			} else {
				RSTF_FACTIONS_SOLDIER = createVehicle [_class, _position, [], 0, "CAN_COLLIDE"];
				RSTF_FACTIONS_SOLDIER setDir 45;
				RSTF_FACTIONS_SOLDIER setpos _position;
				RSTF_FACTIONS_SOLDIER enableSimulation false;
				RSTF_CAM camSetRelPos [0, 10, 5];
				RSTF_CAM camCommit 0.1;
			};
		};
	};
}];

_method = compile(format [_template_tree, "avaibleWeapons", "RSTF_WEAPONS_BANNED", 2]);
_ctrl = ["RSTF_RscDialogFactions", "banWeapon"] call RSTF_fnc_getCtrl;
_ctrl ctrlAddEventHandler ["ButtonClick", _method];
_ctrl = ["RSTF_RscDialogFactions", "avaibleWeapons"] call RSTF_fnc_getCtrl;

RSTF_EXPANDED set [ctrlIdc _ctrl, []];
_ctrl ctrlAddEventHandler ["TreeExpanded", _expand];
_ctrl ctrlAddEventHandler ["TreeCollapsed", _collapse];

_ctrl ctrlAddEventHandler ["TreeDblClick", _method];
_ctrl ctrlAddEventHandler ["TreeSelChanged", {
	if (!isNull(RSTF_FACTIONS_SOLDIER)) then {
		deleteVehicle RSTF_FACTIONS_SOLDIER;
		RSTF_FACTIONS_SOLDIER = objNull;
	};

	if (!isNull(RSTF_FACTIONS_WEAPON)) then {
		deleteVehicle RSTF_FACTIONS_WEAPON;
		RSTF_FACTIONS_WEAPON = objNull;
	};

	_ctrl = ["RSTF_RscDialogFactions", "avaibleWeapons"] call RSTF_fnc_getCtrl;
	_path = tvCurSel _ctrl;
	if (count(_path) == 2) then {
		_class = _ctrl tvData _path;
		_position = RSTF_CAM_SPAWN;
		RSTF_FACTIONS_WEAPON = "WeaponHolderSimulated" createVehicle _position;
		RSTF_FACTIONS_WEAPON addweaponcargo  [_class, 1];
		//RSTF_FACTIONS_WEAPON setpos _position;
		RSTF_FACTIONS_WEAPON enableSimulation false;
		RSTF_FACTIONS_WEAPON attachTo [RSTF_FACTIONS_WEAPON_HOLDER, [0,0.8,1.5]];

		RSTF_CAM camSetRelPos [0, 1, 0.5];
		RSTF_CAM camCommit 0.1;
	};
}];

call RSTF_fnc_factionsUpdate;