
call RSTF_fnc_profileLoad;

if (RSTF_SKIP_MODE_SELECT) exitWith {
	0 spawn RSTF_fnc_showConfig
};

if (isNull(RSTF_CAM)) then {
	call RSTF_fnc_createCam;
};

RSTF_CAM camSetTarget RSTF_CAM_TARGET;
RSTF_CAM camSetRelPos [3, 3, 2];
RSTF_CAM camCommit 0;

RSTF_MODE_SELECTOR_layout = [missionConfigFile >> "ModeSelectorDialog"] call ZUI_fnc_createDisplay;
private _itemsContainer = [RSTF_MODE_SELECTOR_layout, "items"] call ZUI_fnc_getComponentById;

private _display = [RSTF_MODE_SELECTOR_layout] call ZUI_fnc_display;
_display displayAddEventHandler ["Unload", {
	if (_this select 1 != 0) then {
		0 spawn {
			"Display closed. It will be reopened in 5 seconds." call BIS_fnc_titleText;
			sleep 5;
			0 spawn RSTF_fnc_showModeSelector;
		};
	};
}];

// Sort modes using their "order" string
/*
private _modes = [];
{
	_modes pushBack [_x, _foreachIndex, getNumber(_x >> "order")];
} forEach RSTF_MODES;
*/
_modes = [RSTF_MODES, [], { getNumber(_x >> "order") }] call BIS_fnc_sortBy;

{
	private _mode = _x;
	private _title = getText(_mode >> "title");
	private _description = getText(_mode >> "description");

	private _cat = [_itemsContainer, missionConfigFile >> "ModeSelectorComponents" >> "Mode", false] call ZUI_fnc_createChild;
	private _titleCtrl = [_cat, 'title'] call ZUI_fnc_getControlById;
	private _descriptionCtrl = [_cat, 'description'] call ZUI_fnc_getControlById;

	_titleCtrl ctrlSetText _title;
	_titleCtrl ctrlAddEventHandler ["ButtonClick", format["
		[RSTF_MODE_SELECTOR_layout] call ZUI_fnc_closeDisplay;
		RSTF_MODE_SELECTED = ""%1"";
		RSTF_SKIP_MODE_SELECT = cbChecked ( [RSTF_MODE_SELECTOR_layout, ""skipNextTime""] call ZUI_fnc_getControlById);
		0 spawn RSTF_fnc_profileSave;

		0 spawn RSTF_fnc_showConfig;
	", configName(_mode)]];
	_descriptionCtrl ctrlSetStructuredText parseText(_description);
} forEach _modes;

[_itemsContainer] call ZUI_fnc_refresh;
