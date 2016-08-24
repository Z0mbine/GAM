GAM = GAM or {};
GAM.Config = GAM.Config or {};

function GAM:__call(...)
	if (self.Config[...]) then
		return self.Config[...];
	else
		return 0;
	end;
end;

GAM.__index = GAM;

setmetatable(GAM, GAM);

--[[

	This is the config file. Change the values as you please, and take care to read the notes next to each setting to see what it does.
	Default values are quite balanced and tuned to be optimal, so don't change them unless you really want to.

--]]

------
-- Armor Piercing Rounds
------


GAM.Config.ArmorPierceDamageMult = 0.9 -- 0.5 is half, 1 is normal, 2 is 2x damage, etc.
GAM.Config.ArmorPierceChance = 45 -- Percent chance that AP rounds will pierce armor of a target with 50 armor or more. Range: 0-100


------
-- Concussion Rounds
------


GAM.Config.ConcussionDamageMult = 1.6 -- Same as AP round.
GAM.Config.ConcussionCrippleChance = 45 -- Percent chance that being shot in the leg with a concussion round will make the victim fall over.
GAM.Config.ConcussionDropWeaponChance = 75 -- Percent chance that being shot in the arm will force the victim to relinquish its weapon.


------
-- Corrosive Rounds
------


GAM.Config.CorrosiveArmorDmg = 2 -- Damage over time against armored targets.
GAM.Config.CorrosiveNoArmorDmg = 4 -- Damage over time against unarmored targets.
GAM.Config.CorrosiveDelay = 1 -- Delay between each damage-over-time event for targets affected by acid.
GAM.Config.CorrosiveDuration = 10 -- How many times will the subject be damaged?
GAM.Config.CorrosiveExplosionRange = 150 -- Maximum range at which a deceased subject's body explosion will chain to nearby subjects.
GAM.Config.CorrosiveExplosionBonusDmg = 15 -- Damage to apply to targets who were in range of the acid explosion.


------
-- Dirty Rounds
------


GAM.Config.DirtyDamageMult = 1.35
GAM.Config.DirtyBackfireChance = 3 -- Percent chance that a dirty round will backfire and damage the user.


------
-- High Explosive Rounds
------


GAM.Config.HEDamageMult = 1.4
GAM.Config.HEExplosionChance = 80 -- Percent chance that an HE round is packed tighter and causes a visible explosion.
GAM.Config.HEExplosionBonusDamage = 80
GAM.Config.HEExplosionRadius = 100


------
-- Hollow Point Rounds
------


GAM.Config.HollowPointDamageMult = 1.95 -- Damage multiplier against unarmored foes.
GAM.Config.HollowPointDamageReduction = 0.3 -- Damage multiplier against armored foes.


------
-- Incendiary Rounds
------


GAM.Config.IncenDamageMult = 0.85 -- Same as AP round.
GAM.Config.IncenIgniteChance = 75 -- Percent chance that an incendiary round will ignite its target. Range: 0-100


------
-- Plasma Rounds
------


GAM.Config.PlasmaDamageMult = 1.25 -- Same as AP round.
GAM.Config.PlasmaDissolveThreshold = 50 -- Percent the target's health must be under before dissolve chance is factored in.
GAM.Config.PlasmaDissolveChance = 35 -- Percent chance that, while health is under the above percentage, the target will be instantly turned to ash.


------
-- Shock Rounds
------


GAM.Config.ShockDamageMult = 1.11
GAM.Config.ShockSlowChance = 35 -- Percent chance a player will be slowed down from being electrocuted
GAM.Config.ShockSlowTime = 4 -- Duration of slow
GAM.Config.ShockWaterMult = 5
GAM.Config.ShockArcChance = 65
GAM.Config.ShockArcRadius = 80
GAM.Config.ShockArcDecay = 0.7
GAM.Config.ShockArcDamage = 10


------
-- Tracker Darts
------


GAM.Config.TrackerColor = Color(0, 210, 15) -- Color of the tracker dart light.
GAM.Config.TrackerLifetime = 30 -- Lifetime in seconds of the tracker.


------
-- Tranq Darts
------

GAM.Config.TranqDartDuration = 20 -- Time in seconds a victim will remain paralyzed (ragdolled) by tranq darts.