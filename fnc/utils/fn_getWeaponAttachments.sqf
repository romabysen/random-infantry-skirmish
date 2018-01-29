/*
	Author:
	Jan Zípek

	Description:
	Returns list of possible attachments for each weapon slot.

	Parameters:
		0: STRING - weapon classname

	Returns:
	ARRAY - [ SLOT NAME, [SLOT ITEMS] ]
*/

private _weapon = param [0];

private _attachments = [];
private _slots = "true" configClasses (configFile >> "cfgWeapons" >> _weapon >> "WeaponSlotsInfo");
{
	private _items = configProperties [_x >> "compatibleItems", "getNumber(_x) == 1"];
	private _slot = [];
	{
		_slot pushBackUnique configName(_x);
	} foreach _items;

	_attachments pushBack [configName(_x), _slot];
} foreach _slots;

_attachments;