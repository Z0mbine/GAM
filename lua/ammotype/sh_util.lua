include("sh_ammoconfig.lua")

local function getammoname(weapon)
	if IsValid(weapon) then
		return weapon:GetPrimaryAmmoType()
	else
		return 0
	end
end

local function totalammo(player, weapon)
	return player:GetAmmoCount( getammoname(weapon) ) + weapon:Clip1()
end

local function spareammo(player, weapon)
	return player:GetAmmoCount( weapon:IsScripted() and weapon.Primary.Ammo or getammoname(weapon) )
end

function LerpColor(frac,from,to)
	local col = Color(
		Lerp(frac,from.r,to.r),
		Lerp(frac,from.g,to.g),
		Lerp(frac,from.b,to.b),
		Lerp(frac,from.a,to.a)
		)
	return col
end


if SERVER then


	local meta = FindMetaTable("Player")

	local function SetColour( entity, color )
		entity.GetPlayerColor = function() return color end
		net.Start("recolor")
		net.WriteTable({entity, color})
		net.Broadcast()
	end

	meta = FindMetaTable( "Entity" )

	function meta:Dissolve(typ, nosound)
		if not nosound then
			sound.Play("props/material_emancipation_01.wav", self:GetPos(), 80, math.random(95, 110), 0.4)
		end

		local dissolver = ents.Create("env_entity_dissolver")
		dissolver:SetPos(self:LocalToWorld(self:OBBCenter()))
		dissolver:SetKeyValue("dissolvetype", typ or 0)
		dissolver:Spawn()
		dissolver:Activate()
		local name = "Dissolving_" .. math.random()

		if self:IsPlayer() then
			self:Kill()
			local rag = self:GetRagdollEntity()
			local ragvel = rag:GetVelocity()
			rag:SetName(name)
			rag:SetVelocity(ragvel / 2.5)
		else
			self:SetName(name)
			if IsValid(self:GetPhysicsObject()) then
				local disvel = self:GetPhysicsObject():GetVelocity()
				self:GetPhysicsObject():SetVelocity(disvel / 2.5)
				self:GetPhysicsObject():EnableGravity(false)
			end
		end

		dissolver:Fire("Dissolve", name, 0)
		dissolver:Fire("Kill", self, 0.10)
	end


	-- net.Receive("pickedupammo", function(length, client)
	-- 	local amount = net.ReadInt(16)
	-- 	local name = net.ReadString()


	-- 	if (client:GetActiveWeapon().ammotype or 1) ~= 1 and getammoname(client:GetActiveWeapon()) == game.GetAmmoID(name) then
	-- 		client:RemoveAmmo(amount, getammoname(client:GetActiveWeapon()))
	-- 		for k,v in pairs(client:GetWeapons()) do
	-- 			if getammoname(v) == game.GetAmmoID(name) then
	-- 				v.ammo = (v.ammo or spareammo(client, v)) + amount
	-- 			end
	-- 		end
	-- 	elseif name == ammo.types[client:GetActiveWeapon().ammotype] then
	-- 		client:GiveAmmo(amount, getammoname(client:GetActiveWeapon()), true)
	-- 	end


	-- end)


	function meta:HasAmmoType(ammotype)
		if not game.GetAmmoID(ammotype) and (ammotype != "default" or ammotype != 1) then return false end
		if type(ammotype) == "number" and not ammo.types[ammotype] then return false end
		local extra = 0
		local wep = self:GetActiveWeapon()

		--self.ammo = self.ammo or {}
		if type(ammotype) == "string" then
			if ammotype == "default" then return true end
			--return (self.ammo[ammotype] or 0) > 0
			--print(ammotype)
			if ammo.types[wep.ammotype] == ammotype then
				extra = wep:Clip1()
			end
			return self:GetAmmoCount(ammotype)+extra > 0
		elseif type(ammotype) == "number" then
			if ammotype == 1 then return true end
			--return (self.ammo[ammo.types[ammotype]] or 0) > 0
			--print(ammotype)
			if wep.ammotype == ammotype then
				extra = wep:Clip1()
			end
			return self:GetAmmoCount(ammo.types[ammotype])+extra > 0
		end
	end

	function meta:GiveAmmoType(ammotype, amount)
		-- self.ammo = self.ammo or {}

		-- self.ammo[ammotype] = (self.ammo[ammotype] or 0) + amount
		-- if ammotype == ammo.types[self:GetActiveWeapon().ammotype] then
		-- 	local ammoname = self:GetActiveWeapon():GetPrimaryAmmoType()
		-- 	self:GiveAmmo( amount, ammoname, true )
		-- end
		self:GiveAmmo( amount, ammotype )
	end


	function meta:SelectAmmo(ammotype, force)
		local wep = self:GetActiveWeapon()
		if !IsValid(wep) then return end

		if ammotype == 1 and (wep.ammotype or 1) ~= 1 then
			-- local ammoname = self:GetActiveWeapon():GetPrimaryAmmoType()
			-- self:RemoveAmmo( self:GetAmmoCount( self:GetActiveWeapon():GetPrimaryAmmoType() ), ammoname )
			if wep:IsScripted() then
				self:SetAmmo( self:GetAmmoCount(wep.oldammotype), wep.oldammotype or wep:GetPrimaryAmmoType() )
			else
				self:SetAmmo( wep.ammo, wep.oldammotype or getammoname(wep) )
			end

		else

			self:SetAmmo( self:GetAmmoCount(ammo.types[ammotype]) , ammo.types[ammotype] )

		end

		if (wep.ammotype or 1) ~= ammotype then
			net.Start("ammohandshake")
				net.WriteString(ammo.types[ammotype])
			net.Send(self)
			self:EmitSound("items/itempickup.wav", 70)
		end

		if wep:IsScripted() then
			wep.Primary.Ammo = ammo.types[ammotype] == "default" and wep.oldammotype or ammo.types[ammotype]
			net.Start("updateammotype")
				net.WriteEntity(wep)
				net.WriteString(wep.Primary.Ammo)
			net.Broadcast()
		end

		wep.ammotype = ammotype
	end



	function meta:CycleAmmo()
		if (self.nextammocycle or 0) >= CurTime() then return end
		self.nextammocycle = CurTime() + 1
		--self.ammo = self.ammo or {}
		local wep = self:GetActiveWeapon()
		local oldtype = (wep.ammotype or 1)
		local curtype = (wep.ammotype or 1)
		curtype = curtype+1

		while not self:HasAmmoType( curtype ) do
			curtype = curtype+1
			if curtype > #ammo.types then curtype = 1 end
		end

		if curtype != oldtype and oldtype == 1 then
			if not wep:IsScripted() then
				wep.ammo = totalammo(self, wep)
			else
				self:SetAmmo(self:GetAmmoCount(wep:GetPrimaryAmmoType())+wep:Clip1(), wep:GetPrimaryAmmoType())
			end
		else
			self:SetAmmo( self:GetAmmoCount(ammo.types[oldtype])+wep:Clip1(), ammo.types[oldtype] )
		end

		if wep:IsScripted() then
			wep.Primary.Ammo = (ammo.types[curtype] == "default" and wep.oldammotype or ammo.types[curtype])
			net.Start("updateammotype")
				net.WriteEntity(wep)
				net.WriteString(wep.Primary.Ammo or wep.oldammotype)
			net.Send(self)
		else
			wep.Primary = wep.Primary or {}
			wep.Primary.Ammo = (ammo.types[curtype] == "default" and wep.oldammotype or ammo.types[curtype])
			net.Start("updateammotype")
				net.WriteEntity(wep)
				net.WriteString(wep.Primary.Ammo or wep.oldammotype)
			net.Send(self)
		end


		if curtype ~= (wep.ammotype or 1) then
			--local ammoname = self:GetActiveWeapon():GetPrimaryAmmoType()
			--self:RemoveAmmo( spareammo(self, wep), ammo.types[wep.ammotype] == "default" and wep.oldammotype or (wep.Primary.Ammo or getammoname(wep)) )

			if curtype == 1 then
				if wep:IsScripted() then
					self:SetAmmo( self:GetAmmoCount(wep.oldammotype or wep:GetPrimaryAmmoType())+wep:Clip1(), wep.oldammotype or wep:GetPrimaryAmmoType() )
				else
					self:SetAmmo( wep.ammo, wep.oldammotype or wep:GetPrimaryAmmoType() )
				end
				wep:SetClip1(0)
			else
				self:SetAmmo( self:GetAmmoCount(ammo.types[curtype]), ammo.types[curtype] )
				wep:SetClip1(0)
			end
		end

		self:SelectAmmo(curtype)

	end

	concommand.Add("cycleammo", function(client)
		if IsValid(client) then
			client:CycleAmmo()
		end
	end)

	hook.Add("DoAnimationEvent", "CheckPlayerReload", function(client, event, data)
		if event == PLAYERANIMEVENT_RELOAD then
			client.nextammocycle = CurTime() + client:SequenceDuration(PLAYERANIMEVENT_RELOAD)
		end
	end)



	function meta:Cripple(time, nonote)
		self.lastknownpos = self:GetPos()
		self.ragdoll = ents.Create("prop_ragdoll")
		self.ragdoll:SetModel(self:GetModel())
		self.ragdoll:SetPos(self:GetPos())
		self.ragdoll:SetAngles(self:GetAngles())
		self.ragdoll:SetSkin(self:GetSkin())
		
		SetColour( self.ragdoll, self:GetPlayerColor() )

		self.ragdoll:Spawn()
		self.ragdoll:Activate()
		self.ragdoll:SetCollisionGroup(COLLISION_GROUP_WEAPON)
		self.ragdoll.player = self
		self.ragdoll:SetNWEntity("player", self)
		self.ragdoll:CallOnRemove("restore", function()
			if (IsValid(self)) then
				self:StandUp()
			end
		end)
		self.ragdoll.grace = CurTime() + 0.5

		for i = 0, self.ragdoll:GetPhysicsObjectCount() do
			local physicsObject = self.ragdoll:GetPhysicsObjectNum(i)

			if (IsValid(physicsObject)) then
				physicsObject:SetVelocity(self:GetVelocity() * 1.25)
			end
		end

		local weapons = {}

		for k, v in pairs(self:GetWeapons()) do
			weapons[#weapons + 1] = v:GetClass()
		end

		self.ragweps = weapons
		self:StripWeapons()
		self:Freeze(true)
		self:SetMoveType(MOVETYPE_NOCLIP)
		self:SetNWInt("ragdoll", self.ragdoll:EntIndex())
		self:SetNoDraw(true)
		self:SetNotSolid(true)

		local uniqueID = "ragpos"..self:EntIndex()

		timer.Create(uniqueID, 0.2, 0, function()
			if (!IsValid(self) or !IsValid(self.ragdoll)) then
				if (IsValid(self.ragdoll)) then
					self.ragdoll:Remove()
				end

				timer.Remove(uniqueID)

				return
			end

			local position = self:GetPos()

			if (self.lastknownpos) != position and !self.ragdoll:GetPhysicsObject():IsPenetrating() and self:IsInWorld() then
				self.lastknownpos = position
			end

			self:SetPos(self.ragdoll:GetPos())
		end)

		if not nonote then
			net.Start("cripplerequest")
			net.Send(self)
		end

		if (time or 0) > 0 then
			timer.Create("standup"..self:Name(), time, 1, function() self:StandUp() end)
		end
	end

	function meta:StandUp()
		if !IsValid(self.ragdoll) then
			return
		end
		
		local isValid = IsValid(self.ragdoll)

		if (isValid) then
			self:SetPos(self.ragdoll:GetPos())
		else
			self:SetPos(self.lastknownpos)
		end

		self:SetMoveType(MOVETYPE_WALK)
		self:SetCollisionGroup(COLLISION_GROUP_PLAYER)
		self:Freeze(false)
		self:SetNoDraw(false)
		self:SetNWInt("ragdoll", -1)
		self:DropToFloor()
		self:SetNotSolid(false)
		self.lastknownpos = nil

		if (isValid) then
			local physicsObject = self.ragdoll:GetPhysicsObject()

			if (IsValid(physicsObject)) then
				self:SetVelocity(physicsObject:GetVelocity())
			end
		end

		for k, v in pairs(self.ragweps) do
			self:Give(v)
		end

		timer.Simple(0.5, function() self.ragweps = nil end)

		if (isValid) then
			self.ragdoll:Remove()
		end

		timer.Destroy("ragpos", self:EntIndex())

	end



	function meta:DropCurwep()
		self:DropWeapon(self:GetActiveWeapon())
		net.Start("dropweprequest")
		net.Send(self)
	end

	function meta:FadeScreen(inspeed, holdtime, outspeed, color)
		self:ScreenFade(SCREENFADE.OUT, color or color_black, inspeed, holdtime)

		timer.Simple((inspeed + holdtime) - 0.1, function()
			self:ScreenFade(SCREENFADE.IN, color or color_black, outspeed, 0.2)
		end)
	end

	meta = FindMetaTable("Entity")

	function meta:Corrode(attacker, ischain)
		local ind = self:EntIndex()
		if ischain and (self:IsPlayer() and not self:HasGodMode() or self:IsNPC()) then
			local d = DamageInfo()
			d:SetAttacker(attacker)
			d:SetInflictor(attacker:GetActiveWeapon())
			d:SetDamage(CorrosiveExplosionBonusDmg)
			d:SetDamageType(DMG_ACID)
			self:TakeDamageInfo(d)
			if self:IsNPC() and self:Health() <= CorrosiveExplosionBonusDmg + 5 then
				local pos = self:LocalToWorld(self:OBBCenter())

				for i = 0, 10 do
					ParticleEffect("antlion_spit", pos + Vector(math.random(-20, 20), math.random(-20, 20), 0), Angle(0, 0, 0))
				end
				sound.Play("props/dissolve/object_dissolve_in_goo_0" .. math.random(1, 5) .. ".wav", pos, 75, 100, 0.5)
				self.attk = nil
				SafeRemoveEntity(self)
			end
		end
		timer.Create("corrode" .. ind, CorrosiveDelay, CorrosiveDuration, function()
			if self:IsPlayer() and self:HasGodMode() then timer.Remove("corrode" .. ind) return end

			if IsValid(self) and (self:IsPlayer() or self:IsNPC()) then
				local dmag = DamageInfo()
				dmag:SetDamageType(DMG_ACID)
				dmag:SetAttacker(attacker)
				dmag:SetInflictor(attacker:GetActiveWeapon())
				self:EmitSound("player/pl_burnpain3_no_vo.wav", 75, math.random(90, 120), 0.6)
				self.attk = attacker

				if self:IsPlayer() and not self:HasGodMode() then
					self:ViewPunch(Angle(math.random(-2, 0), math.random(-2, 2), math.random(-2, 2)))
					self:ScreenFade(SCREENFADE.IN, Color(225, 225, 130, 100), 0.3, 0)
				end

				if self:IsPlayer() and self:Armor() > 0 and not self:HasGodMode() then
					self:SetArmor(math.Clamp(self:Armor() - math.random(5, 23), 0, self:Armor()))
					dmag:SetDamage(CorrosiveArmorDmg)
				else
					dmag:SetDamage(CorrosiveNoArmorDmg)
				end

				if self:IsPlayer() and not self:HasGodMode() then
					self:TakeDamageInfo(dmag)
				elseif not self:IsPlayer() then
					self:TakeDamageInfo(dmag)
				end

				if self:IsNPC() and self:Health() < dmag:GetDamage() + 20 then
					local pos = self:LocalToWorld(self:OBBCenter())

					for i = 0, 10 do
						ParticleEffect("antlion_spit", pos + Vector(math.random(-20, 20), math.random(-20, 20), 0), Angle(0, 0, 0))
					end
					sound.Play("props/dissolve/object_dissolve_in_goo_0" .. math.random(1, 5) .. ".wav", pos, 75, 100, 0.5)

					timer.Remove("corrode" .. ind)
					for k,v in pairs(ents.FindInSphere(pos, CorrosiveExplosionRange)) do
						if IsValid(v) and (v:IsPlayer() or v:IsNPC()) and (v != self) then
							v:Corrode(attacker, true)
						end
					end
					self.attk = nil
					SafeRemoveEntity(self)
				end
			else
				timer.Remove("corrode" .. ind)
			end
		end)
	end

	function meta:Arc(attacker, onlywater, dmg)
		if self:GetNWBool("electrocuted", false) then return end
		if dmg then
			dmg = math.floor(dmg)
		end
		if type(dmg) == "number" and dmg <= 0 then return end
		self:SetNWBool("electrocuted", true)

		local info = DamageInfo()
		info:SetDamage((dmg or ShockArcDamage) * (self:WaterLevel() > 0 and ShockWaterMult or 1))
		info:SetDamageType(DMG_SHOCK)
		info:SetAttacker(attacker)
		info:SetInflictor(attacker:GetActiveWeapon())
		self:TakeDamageInfo(info)
		self:EmitSound("quick_zap.wav", 75, 100, 0.8)

		net.Start("shock")
		net.WriteVector(self:GetPos())
		net.WriteInt(self:EntIndex(), 16)
		net.Broadcast()


		timer.Simple(2, function() self:SetNWBool("electrocuted", false) end)

		for k,v in pairs(ents.FindInSphere(self:GetPos(), ShockArcRadius)) do
			if (v:IsPlayer() or v:IsNPC()) and not v:GetNWBool("electrocuted", false) and v != self then
				if onlywater and v:WaterLevel() == 0 then continue end

				info:SetDamage((ShockArcDamage * (v:WaterLevel() > 0 and ShockWaterMult or 1)) * (frac or 1))
				v:TakeDamageInfo(info)
				v:EmitSound("world/laser_cut.wav", 75, math.random(120, 150), 0.5)

				v:Arc(attacker, v:WaterLevel() > 0, (dmg or 1) * ShockArcDecay)

				v:SetNWBool("electrocuted", true)

				timer.Simple(2, function()
					v:SetNWBool("electrocuted", false)
				end)
			end
		end
	end



	hook.Add("PlayerDeath", "spawnfuncsforbullets", function(client)
		client:StandUp()
		client.ammo = nil
		client:SelectAmmo(1)
	end)


	hook.Add("EntityTakeDamage", "Cripple", function(entity, damageInfo)
			if IsValid(entity.player) then
				if entity:IsPlayerHolding() then
					return true
				end
			end
		if (IsValid(entity.player) and (entity.grace or 0) < CurTime()) then
			damageInfo:ScaleDamage(1)
			if entity.player then
				if entity:IsPlayerHolding() then
					return true
				end
			end

			if (damageInfo:IsDamageType(DMG_CRUSH)) then
				entity.grace = CurTime() + 0.5

				if (damageInfo:GetDamage() <= 5) then
					damageInfo:SetDamage(0)
				end
			end
			entity.player:TakeDamageInfo(damageInfo)
		end
	end)

	hook.Add("PlayerSwitchWeapon", "bulletlistener", function(client, oldwep, new)
		if IsValid(client) and IsValid(new) then
			if IsValid(oldwep) then
				oldwep.ammo = spareammo(client, oldwep)
			end
			if (new.ammotype or 1) == 1 then
				client:SetAmmo((new.ammo or spareammo(client, new)), (new.oldammotype or new:GetPrimaryAmmoType()))
			else
				client:SetAmmo(client:GetAmmoCount(ammo.types[new.ammotype]), ammo.types[new.ammotype])
			end

			if new:IsScripted() then
				if (new.ammotype or 1) == 1 and !new.oldammotype then
					new.oldammotype = new.Primary.Ammo
				end
			end

		end
	end)

	hook.Add("PlayerDeath", "aciddissolve", function(client)
		local rag = client:GetRagdollEntity()
		if timer.Exists("corrode" .. client:EntIndex()) then
			timer.Simple(1, function()
				local pos = rag:GetPos()
				sound.Play("props/dissolve/object_dissolve_in_goo_0" .. math.random(1, 5) .. ".wav", pos, 75, 100, 0.5)

				for i = 0, 10 do
					ParticleEffect("antlion_spit", pos + Vector(math.random(-20, 20), math.random(-20, 20), 0), Angle(0, 0, 0))
				end

				for k, v in pairs(ents.FindInSphere(pos, CorrosiveExplosionRange)) do
					if IsValid(v) and (v:IsPlayer() or v:IsNPC()) and (v != client) then
						v:Corrode(v.attk, true)
					end
				end
				client.attk = nil

				if IsValid(rag) then
					rag:Remove()
				end

				timer.Remove("corrode" .. client:EntIndex())
			end)
		end

		if client:GetNWBool("electrocuted", false) then
			client:GetRagdollEntity():Dissolve()
			client:SetNWBool("electrocuted", false)
		end
	end)


else




	hook.Add("CalcView", "nut_RagdollView", function(client, origin, angles, fov)
		local ragdolled, entity = client:GetNWInt("ragdoll", -1) != -1, Entity(client:GetNWInt("ragdoll", -1))

		if (ragdolled and IsValid(entity)) then
			local index = entity:LookupAttachment("eyes")
			local attachment = entity:GetAttachment(index)

			local view = {}
				view.origin = attachment.Pos
				view.angles = attachment.Ang
			return view
		end
	end)

end

hook.Add("Move", "fixmove", function(client, move)
	if client:GetNWBool("electrocuted", false) then
		move:SetMaxClientSpeed( client:GetWalkSpeed()/2 )
	end
end)