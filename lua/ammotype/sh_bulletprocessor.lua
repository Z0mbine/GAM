if (SERVER) then
	hook.Add("EntityFireBullets", "BulletSanitizer", function(client, bullet)
		if IsValid(client) and client:IsPlayer() then
			local wep = client:GetActiveWeapon();

			if (wep.ammotype or 1) ~= 1 then
				GAM[GAM.types[wep.ammotype]](bullet);

				if not wep:IsScripted() then
					client:RemoveAmmo(1, GAM.types[wep.ammotype]);
				end

				if (client:GetAmmoCount(wep:GetPrimaryAmmoType()) + wep:Clip1()) <= 1 then
					client:SetAmmo(0, GAM.types[wep.ammotype]);
					client:SelectAmmo(1);
				end

				if wep.ammotype == 5 then
					local chance = math.random(1, 100);

					if chance >= (100 - DirtyBackfireChance) and not client:HasGodMode() then
						client:TakeDamage(bullet.Damage / 3, client, wep);
						client:ScreenFade(SCREENFADE.IN, Color(255, 0, 0, 120), 0.3, 0);
						client:ViewPunch(Angle(-5, 4, 0));
					end
				end

				if wep.ammotype == 10 then
					local t = {};
					t.start = client:GetShootPos();
					t.endpos = t.start + client:GetAimVector() * 16384;
					t.mask = CONTENTS_WATER;
					local tr = util.TraceLine(t);

					if tr.Hit then
						for k, v in pairs(ents.FindInSphere(tr.HitPos, ShockArcRadius)) do
							if v:WaterLevel() > 0 and (v:IsNPC() or v:IsPlayer()) then
								v:Arc(client, true, bullet.Damage);
							end
						end

						sound.Play("quick_zap.wav", tr.HitPos, 75, 100);
						sound.Play("shock_cont.wav", tr.HitPos, 75, math.random(120, 150), 0.3);
					end
				end

				return true;
			end
		end
	end);
end