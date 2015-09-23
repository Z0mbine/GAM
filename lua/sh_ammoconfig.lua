--[[

	This is the config file. Change the values as you please, and take care to read the notes next to each setting to see what it does.
	Default values are quite balanced and tuned to be optimal, so don't change them unless you really want to.

--]]

------
-- Armor Piercing Rounds
------


ArmorPierceDamageMult = 0.9 -- 0.5 is half, 1 is normal, 2 is 2x damage, etc.
ArmorPierceChance = 45 -- Percent chance that AP rounds will pierce armor of a target with 50 armor or more. Range: 0-100


------
-- Concussion Rounds
------


ConcussionDamageMult = 1.6 -- Same as AP round.
ConcussionCrippleChance = 45 -- Percent chance that being shot in the leg with a concussion round will make the victim fall over.
ConcussionDropWeaponChance = 75 -- Percent chance that being shot in the arm will force the victim to relinquish its weapon.


------
-- Corrosive Rounds
------


CorrosiveArmorDmg = 2 -- Damage over time against armored targets.
CorrosiveNoArmorDmg = 4 -- Damage over time against unarmored targets.
CorrosiveDelay = 1 -- Delay between each damage-over-time event for targets affected by acid.
CorrosiveDuration = 10 -- How many times will the subject be damaged?
CorrosiveExplosionRange = 150 -- Maximum range at which a deceased subject's body explosion will chain to nearby subjects.
CorrosiveExplosionBonusDmg = 15 -- Damage to apply to targets who were in range of the acid explosion.


------
-- Dirty Rounds
------


DirtyDamageMult = 1.35
DirtyBackfireChance = 3 -- Percent chance that a dirty round will backfire and damage the user.


------
-- High Explosive Rounds
------


HEDamageMult = 1.4
HEExplosionChance = 80 -- Percent chance that an HE round is packed tighter and causes a visible explosion.
HEExplosionBonusDamage = 80
HEExplosionRadius = 100


------
-- Hollow Point Rounds
------


HollowPointDamageMult = 1.95 -- Damage multiplier against unarmored foes.
HollowPointDamageReduction = 0.3 -- Damage multiplier against armored foes.


------
-- Incendiary Rounds
------


IncenDamageMult = 0.85 -- Same as AP round.
IncenIgniteChance = 75 -- Percent chance that an incendiary round will ignite its target. Range: 0-100


------
-- Plasma Rounds
------


PlasmaDamageMult = 1.25 -- Same as AP round.
PlasmaDissolveThreshold = 50 -- Percent the target's health must be under before dissolve chance is factored in.
PlasmaDissolveChance = 35 -- Percent chance that, while health is under the above percentage, the target will be instantly turned to ash.


------
-- Shock Rounds
------


ShockDamageMult = 1.11
ShockSlowChance = 35 -- Percent chance a player will be slowed down from being electrocuted
ShockSlowTime = 4 -- Duration of slow
ShockWaterMult = 5
ShockArcChance = 65
ShockArcRadius = 80
ShockArcDecay = 0.7
ShockArcDamage = 10


------
-- Tracker Darts
------


TrackerColor = Color(0, 210, 15) -- Color of the tracker dart light.
TrackerLifetime = 30 -- Lifetime in seconds of the tracker.


------
-- Tranq Darts
------

TranqDartDuration = 20 -- Time in seconds a victim will remain paralyzed (ragdolled) by tranq darts.