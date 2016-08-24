if (SERVER) then
	util.AddNetworkString("cripplerequest");
	util.AddNetworkString("dropweprequest");
	util.AddNetworkString("recolor");
	util.AddNetworkString("ammohandshake");
	util.AddNetworkString("pickedupammo");
	util.AddNetworkString("updateammotype");
	util.AddNetworkString("goboom");
	util.AddNetworkString("burnprop");
	util.AddNetworkString("tranqed");
	util.AddNetworkString("spit");
	util.AddNetworkString("shock");

	AddCSLuaFile("sh_ammoconfig.lua");
	AddCSLuaFile("ammotype/sh_util.lua");
	AddCSLuaFile("ammotype/sh_bulletprocessor.lua");
	AddCSLuaFile("ammotype/cl_headsup.lua");

	include("sh_ammoconfig.lua");
	include("ammotype/sh_util.lua");
	include("ammotype/sh_bulletprocessor.lua");
	include("ammotype/sv_bulletfunc.lua");

	resource.AddFile("materials/exclaim.png");
	resource.AddFile("sound/beepclear.wav");
else
	include("sh_ammoconfig.lua");
	include("ammotype/sh_util.lua");
	include("ammotype/sh_bulletprocessor.lua");
	include("ammotype/cl_headsup.lua");
end;

local function AddAmmo(name, text, dmg)
	game.AddAmmoType({name = name,
	dmgtype = dmg or DMG_BULLET})

	if (CLIENT) then
		language.Add(name .. "_ammo", text)
	end;
end;

AddAmmo("armorpierce", "Armor Piercing Rounds");
AddAmmo("concussion", "Concussion Rounds");
AddAmmo("corrosive", "Corrosive Rounds", DMG_ACID);
AddAmmo("dirty", "Dirty Rounds");
AddAmmo("he", "HE Rounds");
AddAmmo("hollowpoint", "Hollow-Point Rounds");
AddAmmo("incendiary", "Incendiary Rounds");
AddAmmo("plasma", "Plasma Rounds", DMG_PLASMA);
AddAmmo("shock", "Shock Rounds", DMG_SHOCK);
AddAmmo("tracker", "Tracker Darts");
AddAmmo("tranquilizer", "Tranquilizer Darts");