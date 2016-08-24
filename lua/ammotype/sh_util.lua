include("sh_ammoconfig.lua")

local function getammoname(weapon)
	if (IsValid(weapon)) then
		return weapon:GetPrimaryAmmoType();
	else
		return 0;
	end;
end;

local function totalammo(player, weapon)
	return player:GetAmmoCount(getammoname(weapon)) + weapon:Clip1();
end;

local function spareammo(player, weapon)
	return player:GetAmmoCount(weapon:IsScripted() and weapon.Primary.Ammo or getammoname(weapon));
end;

function LerpColor(frac, from, to)
	local col = Color(Lerp(frac, from.r, to.r), Lerp(frac, from.g, to.g), Lerp(frac, from.b, to.b), Lerp(frac, from.a, to.a));

	return col;
end;


if (SERVER) then
	local meta = FindMetaTable("Player")

	local function SetColour(entity, color)
		entity.GetPlayerColor = function() return color; end;
		net.Start("recolor");
		net.WriteTable({entity, color});
		net.Broadcast();
	end

	meta = FindMetaTable("Entity");

	function meta:Dissolve(typ, bNoSound)
		if (!bNoSound) then
			sound.Play("props/material_emancipation_01.wav", self:GetPos(), 80, math.random(95, 110), 0.4);
		end;

		local dissolver = ents.Create("env_entity_dissolver");
		dissolver:SetPos(self:LocalToWorld(self:OBBCenter()));
		dissolver:SetKeyValue("dissolvetype", typ or 0);
		dissolver:Spawn();
		dissolver:Activate();
		local name = "Dissolving_" .. math.random();

		if (self:IsPlayer()) then
			self:Kill();
			local rag = self:GetRagdollEntity();
			local ragvel = rag:GetVelocity();
			rag:SetName(name);
			rag:SetVelocity(ragvel / 2.5);
		else
			self:SetName(name);

			if (IsValid(self:GetPhysicsObject())) then
				local disvel = self:GetPhysicsObject():GetVelocity();
				self:GetPhysicsObject():SetVelocity(disvel / 2.5);
				self:GetPhysicsObject():EnableGravity(false);
			end;
		end;

		dissolver:Fire("Dissolve", name, 0);
		dissolver:Fire("Kill", self, 0.10);
	end;

	function meta:HasAmmoType(ammotype)
		if (!game.GetAmmoID(ammotype) and (ammotype != "default" or ammotype != 1)) then return false; end;
		if (type(ammotype) == "number" and !GAM.types[ammotype]) then return false; end;
		local extra = 0;
		local wep = self:GetActiveWeapon();

		if (type(ammotype) == "string") then
			if ammotype == "default" then return true; end

			if (GAM.types[wep.ammotype] == ammotype) then
				extra = wep:Clip1();
			end;

			return self:GetAmmoCount(ammotype) + extra > 0;
		elseif (type(ammotype) == "number") then
			if (ammotype == 1) then return true; end

			if (wep.ammotype == ammotype) then
				extra = wep:Clip1();
			end;

			return self:GetAmmoCount(GAM.types[ammotype]) + extra > 0;
		end;
	end;

	function meta:GiveAmmoType(ammotype, amount)
		self:GiveAmmo(amount, ammotype);
	end;

	function meta:SelectAmmo(ammotype, force)
		local wep = self:GetActiveWeapon();
		if (!IsValid(wep)) then return; end;

		if (ammotype == 1 and (wep.ammotype or 1) != 1) then
			if (wep:IsScripted()) then
				self:SetAmmo(self:GetAmmoCount(wep.oldammotype), wep.oldammotype or wep:GetPrimaryAmmoType());
			else
				self:SetAmmo(wep.ammoCount, wep.oldammotype or getammoname(wep));
			end;
		else
			self:SetAmmo(self:GetAmmoCount(GAM.types[ammotype]), GAM.types[ammotype]);
		end;

		if (wep.ammotype or 1) != ammotype then
			net.Start("ammohandshake");
			net.WriteString(GAM.types[ammotype]);
			net.Send(self);
			self:EmitSound("items/itempickup.wav", 70);
		end;

		if (wep:IsScripted()) then
			wep.Primary.Ammo = GAM.types[ammotype] == "default" and wep.oldammotype or GAM.types[ammotype];
			net.Start("updateammotype");
			net.WriteEntity(wep);
			net.WriteString(wep.Primary.Ammo);
			net.Broadcast();
		end;

		wep.ammotype = ammotype;
	end;

	function meta:CycleAmmo()
		if ((self.nextammocycle or 0) >= CurTime()) then return; end;
		self.nextammocycle = CurTime() + 1;

		local wep = self:GetActiveWeapon();
		local oldtype = (wep.ammotype or 1);
		local curtype = (wep.ammotype or 1);
		curtype = curtype + 1;

		while (!self:HasAmmoType(curtype)) do
			curtype = curtype + 1;

			if (curtype > #GAM.types) then
				curtype = 1;
			end
		end

		if (curtype != oldtype and oldtype == 1) then
			if (!wep:IsScripted()) then
				wep.ammoCount = totalammo(self, wep);
			else
				self:SetAmmo(self:GetAmmoCount(wep:GetPrimaryAmmoType()) + wep:Clip1(), wep:GetPrimaryAmmoType());
			end;
		else
			self:SetAmmo(self:GetAmmoCount(GAM.types[oldtype]) + wep:Clip1(), GAM.types[oldtype]);
		end;

		if (wep:IsScripted()) then
			wep.Primary.Ammo = (GAM.types[curtype] == "default" and wep.oldammotype or GAM.types[curtype]);
			net.Start("updateammotype");
			net.WriteEntity(wep);
			net.WriteString(wep.Primary.Ammo or wep.oldammotype);
			net.Send(self);
		else
			wep.Primary = wep.Primary or {};
			wep.Primary.Ammo = (GAM.types[curtype] == "default" and wep.oldammotype or GAM.types[curtype]);
			net.Start("updateammotype");
			net.WriteEntity(wep);
			net.WriteString(wep.Primary.Ammo or wep.oldammotype);
			net.Send(self);
		end;

		if (curtype != (wep.ammotype or 1)) then
			if (curtype == 1) then
				if (wep:IsScripted()) then
					self:SetAmmo(self:GetAmmoCount(wep.oldammotype or wep:GetPrimaryAmmoType()) + wep:Clip1(), wep.oldammotype or wep:GetPrimaryAmmoType());
				else
					self:SetAmmo(wep.ammoCount, wep.oldammotype or wep:GetPrimaryAmmoType());
				end;

				wep:SetClip1(0);
			else
				self:SetAmmo(self:GetAmmoCount(GAM.types[curtype]), GAM.types[curtype]);
				wep:SetClip1(0);
			end;
		end;

		self:SelectAmmo(curtype);
	end;

	concommand.Add("cycleammo", function(client)
		if (IsValid(client)) then
			client:CycleAmmo();
		end;
	end);

	hook.Add("DoAnimationEvent", "GAM_ReloadTimer", function(client, event, data)
		if event == PLAYERANIMEVENT_RELOAD then
			client.nextammocycle = CurTime() + client:SequenceDuration(PLAYERANIMEVENT_RELOAD);
		end;
	end);

	function meta:Cripple(time, nonote)
		self.lastknownpos = self:GetPos();
		self.ragdoll = ents.Create("prop_ragdoll");
		self.ragdoll:SetModel(self:GetModel());
		self.ragdoll:SetPos(self:GetPos());
		self.ragdoll:SetAngles(self:GetAngles());
		self.ragdoll:SetSkin(self:GetSkin());

		SetColour(self.ragdoll, self:GetPlayerColor());

		self.ragdoll:Spawn();
		self.ragdoll:Activate();
		self.ragdoll:SetCollisionGroup(COLLISION_GROUP_WEAPON);
		self.ragdoll.player = self;
		self.ragdoll:SetNWEntity("player", self);

		self.ragdoll:CallOnRemove("restore", function()
			if (IsValid(self)) then
				self:StandUp();
			end;
		end);

		self.ragdoll.grace = CurTime() + 0.5;

		for i = 0, self.ragdoll:GetPhysicsObjectCount() do
			local physicsObject = self.ragdoll:GetPhysicsObjectNum(i);

			if (IsValid(physicsObject)) then
				physicsObject:SetVelocity(self:GetVelocity() * 1.25);
			end;
		end;

		local weapons = {};

		for k, v in pairs(self:GetWeapons()) do
			weapons[#weapons + 1] = v:GetClass();
		end;

		self.ragweps = weapons;
		self:StripWeapons();
		self:Freeze(true);
		self:SetMoveType(MOVETYPE_NOCLIP);
		self:SetNWInt("ragdoll", self.ragdoll:EntIndex());
		self:SetNoDraw(true);
		self:SetNotSolid(true);
		local uniqueID = "ragpos" .. self:EntIndex();

		timer.Create(uniqueID, 0.2, 0, function()
			if (!IsValid(self) or !IsValid(self.ragdoll)) then
				if (IsValid(self.ragdoll)) then
					self.ragdoll:Remove();
				end;

				timer.Remove(uniqueID);

				return;
			end;

			local position = self:GetPos();

			if ((self.lastknownpos) != position and !self.ragdoll:GetPhysicsObject():IsPenetrating() and self:IsInWorld()) then
				self.lastknownpos = position;
			end;

			self:SetPos(self.ragdoll:GetPos());
		end);

		if (!nonote) then
			net.Start("cripplerequest");
			net.Send(self);
		end

		if ((time or 0) > 0) then
			timer.Create("standup" .. self:Name(), time, 1, function()
				self:StandUp();
			end);
		end;
	end;

	function meta:StandUp()
		if (!IsValid(self.ragdoll)) then return; end
		local isValid = IsValid(self.ragdoll);

		if (isValid) then
			self:SetPos(self.ragdoll:GetPos());
		else
			self:SetPos(self.lastknownpos);
		end;

		self:SetMoveType(MOVETYPE_WALK);
		self:SetCollisionGroup(COLLISION_GROUP_PLAYER);
		self:Freeze(false);
		self:SetNoDraw(false);
		self:SetNWInt("ragdoll", -1);
		self:DropToFloor();
		self:SetNotSolid(false);
		self.lastknownpos = nil;

		if (isValid) then
			local physicsObject = self.ragdoll:GetPhysicsObject();

			if (IsValid(physicsObject)) then
				self:SetVelocity(physicsObject:GetVelocity());
			end;
		end;

		for k, v in pairs(self.ragweps) do
			self:Give(v);
		end;

		timer.Simple(0.5, function()
			self.ragweps = nil;
		end);

		if (isValid) then
			self.ragdoll:Remove();
		end;

		timer.Remove("ragpos" .. self:EntIndex());
	end;

	function meta:DropCurwep()
		self:DropWeapon(self:GetActiveWeapon());
		net.Start("dropweprequest");
		net.Send(self);
	end;

	function meta:FadeScreen(inspeed, holdtime, outspeed, color)
		self:ScreenFade(SCREENFADE.OUT, color or color_black, inspeed, holdtime)

		timer.Simple((inspeed + holdtime) - 0.1, function()
			self:ScreenFade(SCREENFADE.IN, color or color_black, outspeed, 0.2)
		end);
	end;

	meta = FindMetaTable("Entity")

	function meta:Corrode(attacker, bIsChain)
		local ind = self:EntIndex();

		if (bIsChain and (self:IsPlayer() and !self:HasGodMode() or self:IsNPC())) then
			local d = DamageInfo();
			d:SetAttacker(attacker);
			d:SetInflictor(attacker:GetActiveWeapon());
			d:SetDamage(GAM("CorrosiveExplosionBonusDmg"));
			d:SetDamageType(DMG_ACID);
			self:TakeDamageInfo(d);

			if (self:IsNPC() and self:Health() <= GAM("CorrosiveExplosionBonusDmg") + 5) then
				local pos = self:LocalToWorld(self:OBBCenter());

				for i = 0, 10 do
					ParticleEffect("antlion_spit", pos + Vector(math.random(-20, 20), math.random(-20, 20), 0), Angle(0, 0, 0));
				end;

				sound.Play("props/dissolve/object_dissolve_in_goo_0" .. math.random(1, 5) .. ".wav", pos, 75, 100, 0.5);
				self.attk = nil;
				SafeRemoveEntity(self);
			end;
		end;

		timer.Create("corrode" .. ind, GAM("CorrosiveDelay"), GAM("CorrosiveDuration"), function()
			if (self:IsPlayer() and self:HasGodMode()) then
				timer.Remove("corrode" .. ind);

				return;
			end;

			if (IsValid(self) and (self:IsPlayer() or self:IsNPC())) then
				local dmag = DamageInfo();
				dmag:SetDamageType(DMG_ACID);
				dmag:SetAttacker(attacker);
				dmag:SetInflictor(attacker:GetActiveWeapon());
				self:EmitSound("player/pl_burnpain3_no_vo.wav", 75, math.random(90, 120), 0.6);
				self.attk = attacker;

				if (self:IsPlayer() and !self:HasGodMode()) then
					self:ViewPunch(Angle(math.random(-2, 0), math.random(-2, 2), math.random(-2, 2)));
					self:ScreenFade(SCREENFADE.IN, Color(225, 225, 130, 100), 0.3, 0);
				end

				if (self:IsPlayer() and self:Armor() > 0 and !self:HasGodMode()) then
					self:SetArmor(math.Clamp(self:Armor() - math.random(5, 23), 0, self:Armor()));
					dmag:SetDamage(GAM("CorrosiveArmorDmg"));
				else
					dmag:SetDamage(GAM("CorrosiveNoArmorDmg"));
				end

				if (self:IsPlayer() and !self:HasGodMode()) then
					self:TakeDamageInfo(dmag);
				elseif (!self:IsPlayer()) then
					self:TakeDamageInfo(dmag);
				end;

				if (self:IsNPC() and self:Health() < dmag:GetDamage() + 20) then
					local pos = self:LocalToWorld(self:OBBCenter());

					for i = 0, 10 do
						ParticleEffect("antlion_spit", pos + Vector(math.random(-20, 20), math.random(-20, 20), 0), Angle(0, 0, 0));
					end

					sound.Play("props/dissolve/object_dissolve_in_goo_0" .. math.random(1, 5) .. ".wav", pos, 75, 100, 0.5);
					timer.Remove("corrode" .. ind);

					for k, v in pairs(ents.FindInSphere(pos, GAM("CorrosiveExplosionRange"))) do
						if (IsValid(v) and (v:IsPlayer() or v:IsNPC()) and (v != self)) then
							v:Corrode(attacker, true);
						end;
					end;

					self.attk = nil;
					SafeRemoveEntity(self);
				end;
			else
				timer.Remove("corrode" .. ind);
			end;
		end);
	end;

	function meta:Arc(attacker, bOnlyWater, dmg)
		if (self:GetNWBool("electrocuted", false)) then return; end

		if (dmg) then
			dmg = math.floor(dmg);
		end;

		if (type(dmg) == "number" and dmg <= 0) then return; end;

		self:SetNWBool("electrocuted", true);
		local info = DamageInfo();
		info:SetDamage((dmg or GAM("ShockArcDamage")) * (self:WaterLevel() > 0 and GAM("ShockWaterMult") or 1));
		info:SetDamageType(DMG_SHOCK);
		info:SetAttacker(attacker);
		info:SetInflictor(attacker:GetActiveWeapon());
		self:TakeDamageInfo(info);
		self:EmitSound("quick_zap.wav", 75, 100, 0.8);
		net.Start("shock");
		net.WriteVector(self:GetPos());
		net.WriteInt(self:EntIndex(), 16);
		net.Broadcast();

		timer.Simple(2, function()
			self:SetNWBool("electrocuted", false);
		end);

		for k, v in pairs(ents.FindInSphere(self:GetPos(), GAM("ShockArcRadius"))) do
			if ((v:IsPlayer() or v:IsNPC()) and !v:GetNWBool("electrocuted", false) and v != self) then
				if (bOnlyWater and v:WaterLevel() == 0) then continue; end;

				info:SetDamage((GAM("ShockArcDamage") * (v:WaterLevel() > 0 and GAM("ShockWaterMult") or 1)) * (frac or 1));
				v:TakeDamageInfo(info);
				v:EmitSound("world/laser_cut.wav", 75, math.random(120, 150), 0.5);
				v:Arc(attacker, v:WaterLevel() > 0, (dmg or 1) * GAM("ShockArcDecay"));
				v:SetNWBool("electrocuted", true);

				timer.Simple(2, function()
					v:SetNWBool("electrocuted", false);
				end);
			end;
		end;
	end;

	hook.Add("PlayerDeath", "GAM_Die", function(client)
		client:StandUp();
		client.GAM = nil;
		client:SelectAmmo(1);
	end);

	hook.Add("EntityTakeDamage", "GAM_Cripple", function(entity, damageInfo)
		if (IsValid(entity.player)) then
			if (entity:IsPlayerHolding()) then return true; end;
		end;

		if (IsValid(entity.player) and (entity.grace or 0) < CurTime()) then
			damageInfo:ScaleDamage(1);

			if (entity.player) then
				if (entity:IsPlayerHolding()) then return true; end;
			end;

			if (damageInfo:IsDamageType(DMG_CRUSH)) then
				entity.grace = CurTime() + 0.5;

				if (damageInfo:GetDamage() <= 5) then
					damageInfo:SetDamage(0);
				end;
			end;

			entity.player:TakeDamageInfo(damageInfo);
		end;
	end);

	hook.Add("PlayerSwitchWeapon", "GAM_WeaponSwitcher", function(client, oldwep, new)
		if (IsValid(client) and IsValid(new)) then
			if (IsValid(oldwep)) then
				oldwep.ammoCount = spareammo(client, oldwep);
			end;

			if ((new.ammotype or 1) == 1) then
				client:SetAmmo((new.GAM or spareammo(client, new)), (new.oldammotype or new:GetPrimaryAmmoType()));
			else
				client:SetAmmo(client:GetAmmoCount(GAM.types[new.ammotype]), GAM.types[new.ammotype]);
			end;

			if (new:IsScripted()) then
				if ((new.ammotype or 1) == 1 and !new.oldammotype) then
					new.oldammotype = new.Primary.Ammo;
				end;
			end;
		end;
	end);

	hook.Add("PlayerDeath", "GAM_Acid", function(client)
		local rag = client:GetRagdollEntity();

		if (timer.Exists("corrode" .. client:EntIndex())) then
			timer.Simple(1, function()
				local pos = rag:GetPos();
				sound.Play("props/dissolve/object_dissolve_in_goo_0" .. math.random(1, 5) .. ".wav", pos, 75, 100, 0.5);

				for i = 0, 10 do
					ParticleEffect("antlion_spit", pos + Vector(math.random(-20, 20), math.random(-20, 20), 0), Angle(0, 0, 0));
				end;

				for k, v in pairs(ents.FindInSphere(pos, GAM("CorrosiveExplosionRange"))) do
					if (IsValid(v) and (v:IsPlayer() or v:IsNPC()) and (v != client)) then
						v:Corrode(v.attk, true);
					end;
				end;

				client.attk = nil;

				if (IsValid(rag)) then
					rag:Remove();
				end;

				timer.Remove("corrode" .. client:EntIndex());
			end);
		end;

		if (client:GetNWBool("electrocuted", false)) then
			client:GetRagdollEntity():Dissolve();
			client:SetNWBool("electrocuted", false);
		end;
	end);
else
	hook.Add("CalcView", "GAM_RagdollView", function(client, origin, angles, fov)
		local ragdolled, entity = client:GetNWInt("ragdoll", -1) != -1, Entity(client:GetNWInt("ragdoll", -1));

		if (ragdolled and IsValid(entity)) then
			local index = entity:LookupAttachment("eyes");
			local attachment = entity:GetAttachment(index);
			local view = {};
			view.origin = attachment.Pos;
			view.angles = attachment.Ang;

			return view;
		end;
	end);
end;

hook.Add("Move", "GAM_Electrocuted", function(client, move)
	if (client:GetNWBool("electrocuted", false)) then
		move:SetMaxClientSpeed(client:GetWalkSpeed() / 2);
	end;
end);