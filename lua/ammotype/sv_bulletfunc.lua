GAM = GAM or {};
local blacklist = {};
include("ammotype/sh_util.lua");

GAM.types = {};
GAM.types[1] = "default";
GAM.types[2] = "armorpierce";
GAM.types[3] = "concussion";
GAM.types[4] = "corrosive";
GAM.types[5] = "dirty";
GAM.types[6] = "he";
GAM.types[7] = "hollowpoint";
GAM.types[8] = "incendiary";
GAM.types[9] = "plasma";
GAM.types[10] = "shock";
GAM.types[11] = "tracker";
GAM.types[12] = "tranquilizer";

PrecacheParticleSystem("fire_small_flameouts");
PrecacheParticleSystem("antlion_spit");
PrecacheParticleSystem("antlion_spit_player_splat");

function GAM.incendiary(bullet)
	bullet.Damage = bullet.Damage * GAM("IncenDamageMult");
	bullet.Force = bullet.Force * 0.85;

	bullet.Callback = function(client, trace, dmg)
		if (IsValid(client) and client:IsPlayer()) then
			if (trace.Hit and !trace.HitSky and !IsValid(trace.Entity)) then
				local chance = math.random(1, 100);

				if (chance >= 60) then
					local emitter = ents.Create("prop_physics");
					emitter:SetModel("models/hunter/plates/plate.mdl");
					emitter:SetPos(trace.HitPos + (trace.HitNormal * 1));
					emitter:SetAngles(Angle(0, 0, 0));
					emitter:Spawn();
					emitter:Activate();
					emitter:GetPhysicsObject():EnableMotion(false);
					emitter:SetNotSolid(true);
					emitter:SetRenderMode(1);
					emitter:SetColor(Color(0, 0, 0, 0));
					net.Start("burnprop");
					net.WriteEntity(emitter);
					net.Broadcast();
					SafeRemoveEntityDelayed(emitter, 6);
				end
			elseif (trace.Hit and IsValid(trace.Entity) and !trace.HitWorld) then
				local chance = math.random(1, 100);

				if (chance >= (100 - GAM("IncenIgniteChance"))) then
					trace.Entity:Ignite(math.random(5, 12));
				end;
			end;
		end;
	end;
end;

function GAM.armorpierce(bullet)
	bullet.Damage = bullet.Damage * GAM("ArmorPierceDamageMult");

	bullet.Callback = function(client, trace, dmg)
		if (IsValid(client) and client:IsPlayer()) then
			local ent = trace.Entity;

			if (IsValid(ent) and ent:IsPlayer()) then
				local armor = ent:Armor();

				if (armor >= 50) then
					local chance = math.random(1, 100);

					if (chance >= (100 - GAM("ArmorPierceChance"))) then
						dmg:SetDamageType(DMG_RADIATION);
					end;
				else
					dmg:SetDamageType(DMG_RADIATION);
				end;
			end;
		end;
	end;
end;

function GAM.plasma(bullet)
	bullet.Damage = bullet.Damage * GAM("PlasmaDamageMult");
	bullet.TracerName = "AR2Tracer";

	bullet.Callback = function(client, trace, dmg)
		if (IsValid(client) and client:IsPlayer()) then
			local ent = trace.Entity;

			if (IsValid(ent) and (ent:IsPlayer() or ent:IsNPC())) then
				if (ent:Health() <= (ent:GetMaxHealth() * ((ent:IsPlayer() and GAM("PlasmaDissolveThreshold") or 75) / 100))) then
					local chance = math.random(1, 100);
					dmg:SetDamage(ent:Health() + 500);

					if (chance >= (100 - GAM("PlasmaDissolveChance"))) then
						if (ent:IsPlayer() and IsValid(ent:GetRagdollEntity()) and !ent:GetRagdollEntity().dust) then
							local ragdoll = ent:GetRagdollEntity();
							ragdoll.dust = true;
							ragdoll:EmitSound("weapons/physcannon/energy_disintegrate" .. math.random(4, 5) .. ".wav", 80, math.random(190, 250));
							ragdoll:SetMaterial("phoenix_storms/concrete0");

							for i = 0, ragdoll:GetBoneCount() - 1 do
								local phys = ragdoll:GetPhysicsObjectNum(i);

								if (IsValid(phys)) then
									phys:EnableMotion(false);
								end;
							end;

							local frac = 0;

							timer.Create("dustify" .. ragdoll, 0.001, 1000, function()
								if (IsValid(ragdoll)) then
									ragdoll:SetColor(LerpColor(frac, color_white, color_black));
									frac = frac + 0.03;

									if (frac >= 1) then
										timer.Destroy("dustify" .. ragdoll:EntIndex());
										ragdoll:Remove();

										for i = 0, ragdoll:GetBoneCount() - 1 do
											local ef = EffectData();
											ef:SetOrigin(ragdoll:GetBonePosition(i));
											util.Effect("GlassImpact", ef);
											ragdoll:Remove();
										end;
									end;
								end;
							end);
						elseif (IsValid(ent) and ent:IsNPC() and !ent.dust and !blacklist[ent:GetClass()]) then
							ent.dust = true;
							ent:SetNPCState(NPC_STATE_INVALID);
							ent:SetMaterial("phoenix_storms/concrete0");
							ent:SetNotSolid(true);
							ent:StopMoving();
							ent:EmitSound("weapons/physcannon/energy_disintegrate" .. math.random(4, 5) .. ".wav", 80, math.random(190, 250));
							local frac = 0;

							timer.Create("dustify" .. ent:EntIndex(), 0.001, 1000, function()
								if (IsValid(ent)) then
									ent:SetColor(LerpColor(frac, color_white, Color(180, 180, 180)));
									frac = frac + 0.03;

									if (frac >= 1) then
										timer.Destroy("dustify" .. ent:EntIndex());
										ent:Remove();

										for i = 0, ent:GetBoneCount() - 1 do
											local ef = EffectData();
											ef:SetOrigin(ent:GetBonePosition(i));
											util.Effect("GlassImpact", ef);
										end;

										ent:Remove();
									end;
								end;
							end);
						end;
					end;
				end;
			end;

			if (trace.Hit and !trace.HitSky and trace.HitWorld) then
				local chance = math.random(1, 100);

				if (chance >= 50) then
					local emitter = ents.Create("prop_physics");
					emitter:SetModel("models/hunter/plates/plate.mdl");
					emitter:SetPos(trace.HitPos + (trace.HitNormal * 1));
					emitter:SetAngles(Angle(0, 0, 0));
					emitter:Spawn();
					emitter:Activate();
					emitter:GetPhysicsObject():EnableMotion(false);
					emitter:SetNotSolid(true);
					emitter:SetNoDraw(true);
					emitter:Dissolve();
					SafeRemoveEntityDelayed(emitter, 6);
				end;
			end;
		end;
	end;
end;

function GAM.hollowpoint(bullet)
	bullet.Callback = function(client, trace, dmg)
		if (IsValid(client) and client:IsPlayer()) then
			local ent = trace.Entity;
			local dmgMult = GAM("HollowPointDamageMult");

			if (IsValid(ent)) then
				if (ent:IsPlayer() and ent:Armor() > 0) then
					dmg:SetDamage(dmg:GetDamage() * GAM("HollowPointDamageReduction"));
				elseif ent:IsPlayer() and ent:Armor() <= 0 then
					dmg:SetDamage(dmg:GetDamage() * dmgMult);
				elseif ent:IsNPC() then
					dmg:SetDamage(dmg:GetDamage() * dmgMult);
				end;
			end;
		end;
	end;
end;

function GAM.concussion(bullet)
	bullet.Damage = bullet.Damage * GAM("ConcussionDamageMult");

	bullet.Callback = function(client, trace, dmg)
		if (IsValid(client) and client:IsPlayer()) then
			local player = trace.Entity;

			if (IsValid(player) and player:IsPlayer()) then
				if (trace.HitGroup == HITGROUP_LEFTARM or trace.HitGroup == HITGROUP_RIGHTARM) then
					local chance = (math.random(1, 100) >= (100 - GAM("ConcussionDropWeaponChance")));

					if (chance) then
						player:DropCurwep();
					end;
				elseif trace.HitGroup == HITGROUP_LEFTLEG or trace.HitGroup == HITGROUP_RIGHTLEG then
					local chance = (math.random(1, 100) >= (100 - GAM("ConcussionCrippleChance")));

					if (chance) then
						player:Cripple();

						timer.Simple(3, function()
							player:StandUp();
						end);
					end;
				end;
			end;
		end;
	end;
end;

function GAM.he(bullet)
	bullet.Damage = bullet.Damage * GAM("HEDamageMult");

	bullet.Callback = function(client, trace, dmg)
		if (IsValid(client) and client:IsPlayer()) then
			local chance = math.random(1, 100);

			if (chance >= (100 - GAM("HEExplosionChance")) and !trace.HitSky) then
				net.Start("goboom");
				net.WriteVector(trace.HitPos);
				net.Broadcast();
				util.BlastDamage(client:GetActiveWeapon(), client, trace.HitPos, GAM("HEExplosionRadius"), GAM("HEExplosionBonusDamage"));
			end;
		end;
	end;
end;

function GAM.dirty(bullet)
	bullet.Damage = bullet.Damage * GAM("DirtyDamageMult");
end;

function GAM.tracker(bullet)
	bullet.Damage = 0;
	bullet.Force = 0;
	bullet.TracerName = "AR2Tracer";

	bullet.Callback = function(client, trace, dmg)
		if (IsValid(client) and client:IsPlayer()) then
			local ent = trace.Entity;
			local trackerCol = GAM("TrackerColor");

			if (IsValid(ent)) then
				if (!IsValid(ent.dlight)) then
					ent.dlight = ents.Create("light_dynamic");
					ent.dlight:SetPos(trace.HitPos - trace.Normal * 5);
					ent.dlight:SetParent(ent);
					ent.dlight:SetKeyValue("_light", string.format("%s %s %s 255", trackerCol.r, trackerCol.g, trackerCol.b));
					ent.dlight:SetKeyValue("distance", 250);
					ent.dlight:SetKeyValue("brightness", 3.5);
					ent.dlight:Spawn();
					ent.dlight:Activate();

					timer.Create("dlightdie" .. ent:EntIndex(), GAM("TrackerLifetime"), 1, function()
						SafeRemoveEntity(ent.dlight);
					end);
				else
					timer.Create("dlightdie" .. ent:EntIndex(), GAM("TrackerLifetime"), 1, function()
						SafeRemoveEntity(ent.dlight);
					end);
				end;
			end;
		end;
	end;
end;

function GAM.tranquilizer(bullet)
	bullet.Damage = 0;
	bullet.Force = 0;

	bullet.Callback = function(client, trace, dmg)
		if (IsValid(client) and client:IsPlayer()) then
			local ent = trace.Entity;
			local duration = GAM("TranqDartDuration");

			if (IsValid(ent) and ent:IsPlayer() and !ent:GetNWBool("tranqed", false) and !ent:HasGodMode()) then
				ent:SetNWBool("tranqed", true);
				ent:SetDSP(132);
				ent:FadeScreen(5, duration, 10);
				ent:ConCommand("soundfade 100 " .. duration .. " 7 5");

				timer.Simple(2, function()
					ent:Cripple(10 + duration, true);
					net.Start("tranqed");
					net.Send(ent);
				end);

				timer.Simple(13 + duration, function()
					ent:StandUp();
					ent:SetDSP(0);
					ent:SetNWBool("tranqed", false);
				end);
			end;
		end;
	end;
end;

function GAM.corrosive(bullet)
	bullet.Damage = bullet.Damage * 1.12;

	bullet.Callback = function(client, trace, dmg)
		if (IsValid(client) and client:IsPlayer()) then
			local ent = trace.Entity;
			dmg:SetDamageType(DMG_ACID);

			if (IsValid(ent) and ent:IsPlayer() or ent:IsNPC()) then
				local chance = math.random(1, 100);
				local ind = ent:EntIndex();

				if (chance >= 20) then
					ent:EmitSound("props/dissolve/object_dissolve_in_goo_0" .. math.random(1, 5) .. ".wav", 75, 100, 0.3);
					ent:SetNWBool("corroding", true);
					net.Start("spit");
					net.WriteVector(trace.HitPos + trace.HitNormal * 3);
					net.Broadcast();

					if (!timer.Exists("corrode" .. ind)) then
						ent:Corrode(client);
					end;
				end;
			elseif (trace.Hit and trace.HitWorld) then
				local chance = math.random(1, 100);

				if (chance >= 20) then
					sound.Play("props/dissolve/object_dissolve_in_goo_0" .. math.random(1, 5) .. ".wav", trace.HitPos, 75, 100, 0.15);
					net.Start("spit");
					net.WriteVector(trace.HitPos + trace.HitNormal * 3);
					net.Broadcast();
				end;
			end;
		end;
	end;
end;

function GAM.shock(bullet)
	bullet.Damage = bullet.Damage * GAM("ShockDamageMult");

	bullet.Callback = function(client, trace, dmg)
		if (IsValid(client) and client:IsPlayer()) then
			dmg:SetDamageType(DMG_SHOCK);
			local ent = trace.Entity;

			if (IsValid(ent)) then
				local index = ent:EntIndex();
				local chance = math.random(1, 100);

				if (chance >= (100 - GAM("ShockArcChance")) and (ent:IsNPC() or ent:IsPlayer())) then
					ent:Arc(client, nil, dmg:GetDamage());
					ent:EmitSound("quick_zap.wav", 75, math.random(120, 150), 0.3);
				end;

				if (ent:WaterLevel() > 0 and ent:IsPlayer() or ent:IsNPC()) then
					ent:Arc(client, true, dmg:GetDamage());
					ent:SetNWBool("electrocuted", true);
					ent:EmitSound("quick_zap", 75, math.random(120, 150), 0.3);

					timer.Create("delshock" .. index, GAM("ShockSlowTime"), 1, function()
						ent:SetNWBool("electrocuted", false);
					end);
				end;

				net.Start("shock");
				net.WriteVector(trace.HitPos);
				net.WriteInt(ent:EntIndex(), 16);
				net.Broadcast();
				sound.Play("world/laser_cut.wav", trace.HitPos, 75, math.random(90, 120), 0.6);
			elseif (trace.Hit and !trace.HitSky) then
				local emitter = ents.Create("prop_physics");
				emitter:SetModel("models/hunter/plates/plate.mdl");
				emitter:SetPos(trace.HitPos + (trace.HitNormal * 5.5));
				emitter:SetAngles(Angle(0, 0, 0));
				emitter:Spawn();
				emitter:Activate();
				emitter:GetPhysicsObject():EnableMotion(false);
				emitter:SetNotSolid(true);
				emitter:SetRenderMode(1);
				emitter:SetColor(Color(0, 0, 0, 0));
				net.Start("shock");
				net.WriteVector(emitter:GetPos());
				net.WriteInt(emitter:EntIndex(), 16);
				net.Broadcast();
				SafeRemoveEntityDelayed(emitter, 0.8);
				sound.Play("world/laser_cut.wav", trace.HitPos, 75, math.random(90, 120), 0.6);
			end;
		end;
	end;
end;