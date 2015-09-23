include("ammotype/sh_util.lua")

net.Receive("recolor", function(length)
	local t = net.ReadTable()

	t[1].GetPlayerColor = function() return t[2] end
end)

surface.CreateFont("amdisplay", {font = "Trebuchet24", size = ScreenScale(10), weight = 500, outline = true, antialias = true})

surface.CreateFont("test", {font = "Arial", size = 30, weight = 500, outline = false, antialias = true})

local blur = Material("pp/blurscreen")
	function util.drawBlur(panel, amount, passes)
		-- Intensity of the blur.
		amount = amount or 5
		
			surface.SetMaterial(blur)
			surface.SetDrawColor(255, 255, 255)

			local x, y = panel:LocalToScreen(0, 0)
			
			for i = -(passes or 0.2), 1, 0.2 do
				-- Do things to the blur material to make it blurry.
				blur:SetFloat("$blur", i * amount)
				blur:Recompute()

				-- Draw the blur material over the screen.
				render.UpdateScreenEffectTexture()
				surface.DrawTexturedRect(x * -1, y * -1, ScrW(), ScrH())
		end
	end

local PANEL = {}

local extrawidth = 40
local extraheight = 20
local cursorpadding = 300

function PANEL:Init()
	self.panel = self:Add("DPanel")
	self.panel:SetWidth(0)
	self.panel:SetHeight(0)
	self.panel.Paint = function(p, w, h)
	util.drawBlur(self.panel, 5, 0.3)
		surface.SetDrawColor(0,0,0)
		--surface.DrawRect(0,0,w,h)
		draw.RoundedBox( 8, 0, 0, w, h, Color(0,0,0) )
	end

	self.panel:SetAlpha(0)
	
	self.text = self.panel:Add("DLabel")
	self.text:SetTextColor(color_white)
	self.text:SetFont("test")
	self.text:SetExpensiveShadow(2, Color(0,0,0,180))
	self.text:SetAlpha(0)
	self.text:SetPos(20,10)

	local w,h = ScrW()/2, ScrH()/2
	self:SetPos(ScrW()/2,h+cursorpadding)
end

function PANEL:SetText(text)
	self.text:SetText(text)
	self.text:SizeToContents()
end

function PANEL:GetRealWide()
	surface.SetFont("test")
	local w,h = surface.GetTextSize(self.text:GetText())
	return w+extrawidth
end

function PANEL:GetRealTall()
	surface.SetFont("test")
	local w,h = surface.GetTextSize(self.text:GetText())
	return h+extraheight
end

function PANEL:Show(time, force)
	if IsValid(self) and force and self.showing then
		timer.Create("panelshit", time, 1, function() if IsValid(self) and self.showing then self:Hide(true) end end)
	end

	if not self.showing then
		self.panel:SetAlpha(0)
		self.showing = true
		self.moving = true
		
	
		surface.SetFont("test")
		local w,h = surface.GetTextSize(self.text:GetText())
		self.panel:SetHeight(h+extraheight)
		
		self.panel:AlphaTo(200, 0.2, 0)
		
		self.panel:SizeTo(w+extrawidth, h+extraheight, 0.2, 0, 1, function()
			self.text:AlphaTo(240, 0.2, 0)
			self.moving = false
			if time then
				timer.Create("panelshit", time, 1, function() self:Hide(true) end)
			end
		end)
		
		self:MoveTo(ScrW()/2-self:GetRealWide()/2, ScrH()/2+cursorpadding, 0.2, 0, 1)
		self:SetSize(self:GetRealWide(), self:GetRealTall())
		
	end
end

function PANEL:Hide(bremove)
	if self.showing then
	self.moving = true
		self.text:AlphaTo(0, 0.2, 0, function()
			self.panel:SizeTo(0, -1, 0.2, 0, 1, function()
				if bremove then
					self.moving = false
					self:Remove()
				end
			end)
			self:MoveTo(ScrW()/2, ScrH()/2+cursorpadding, 0.2, 0, 1)
			self.showing = false
			self.panel:AlphaTo(0, 0.2, 0)
		end)
		
	end
end
	
vgui.Register("3DPNL", PANEL)


ammotext = ""
ammoalpha = 0
panel = nil
net.Receive("ammohandshake", function(length)
	ammotext = string.upper(net.ReadString())
	if not IsValid(panel) then
		panel = vgui.Create("3DPNL")
		panel:SetText("Switched to "..ammotext.." rounds")
		panel:Show(2)
	elseif IsValid(panel) then
		panel:SetText("Switched to "..ammotext.." rounds")
		panel:Show(2, true)
		panel:SetSize(panel:GetRealWide(), panel:GetRealTall())
		surface.SetFont("test")
		local w,h = surface.GetTextSize(panel.text:GetText())
		panel.panel:SizeTo(w+extrawidth, h+extraheight, 0.2, 0, 1)
	end

	-- timer.Destroy("ammoalpha2")

	-- timer.Create("ammoalpha", 0.001, 255, function()
	-- 	ammoalpha = ammoalpha + 5
	-- 	if ammoalpha > 500 then
	-- 		timer.Destroy("ammoalpha")
	-- 		timer.Create("ammoalpha2", 0.001, 255, function()
	-- 			ammoalpha = ammoalpha - 5
	-- 			if ammoalpha <= 0 then timer.Destroy("ammoalpha2") ammotext = "" end
	-- 		end)
	-- 	end
	-- end)
end)

net.Receive("tranqed", function(length)
	local panel = vgui.Create("3DPNL")
	panel:SetText("You have been tranquilized!")
	panel:Show(3)
end)


net.Receive("spit", function(length)
	local pos = net.ReadVector()
	ParticleEffect("antlion_spit_player_splat", pos, Angle(0,0,0))
end)


net.Receive("shock", function(length)
	local pos = net.ReadVector()
	local ent = Entity(net.ReadInt(16))

	local e = EffectData()
	e:SetOrigin(pos)
	e:SetStart(pos)
	if IsValid(ent) then
		e:SetEntity(ent)
	end
	e:SetScale(1)
	e:SetMagnitude(1)
	e:SetRadius(1)
	for i = 0, 10 do
		timer.Simple(1/i, function()
			util.Effect("TeslaHitBoxes", e, true, true)
		end)
	end
end)
-- hook.Add("HUDPaint", "drawammotype", function()
-- 	if ammotext != "" then

-- 		surface.SetFont("amdisplay")
-- 		local w,h = surface.GetTextSize(ammotext)
-- 		surface.SetTextColor(ColorAlpha(color_white, ammoalpha))
-- 		surface.SetTextPos(ScrW()/2 - w/2, ScrH()/1.7)
-- 		surface.DrawText(ammotext)

-- 	end
-- end)

hook.Add("HUDShouldDraw", "TranqHud", function(el)
	if LocalPlayer():GetNWBool("tranqed", false) then return false end
end)

local col = Color(100,100,255)

hook.Add("HUDPaint", "ElectroEffects", function()
	if LocalPlayer():GetNWBool("electrocuted", false) then
		surface.SetDrawColor( ColorAlpha(LerpColor(math.Rand(0,1), color_white, col), math.random(30,50)) )
		surface.DrawRect(0, 0, ScrW(), ScrH())
	end
end)

net.Receive("updateammotype", function(length)
	local wep = net.ReadEntity()
	local type = net.ReadString()

	if IsValid(wep) and wep:IsScripted() then
		wep.Primary.Ammo = type
	end
end)

hook.Add("EntityFireBullets", "altertracers", function(client, bullet)
	if IsValid(client) and client:IsPlayer() and client:GetActiveWeapon():IsScripted() then
		if client:GetActiveWeapon().Primary.Ammo == "plasma" or client:GetActiveWeapon().Primary.Ammo == "tracker" then
			bullet.TracerName = "AR2Tracer"
			return true
		end
	end
end)

net.Receive("dropweprequest", function(length)
	Warning("Your gun was shot out of your hand!", 4)
end)

net.Receive("cripplerequest", function(length)
	Warning("You were shot in the leg, you'll be up in a sec!", 4)
end)

net.Receive("goboom", function(length)
	local pos = net.ReadVector()
	local ef = EffectData()
	ef:SetOrigin(pos)
	util.Effect("Explosion", ef)
end)

net.Receive("burnprop", function(length)
	local ent = net.ReadEntity()

	ParticleEffectAttach( "fire_small_flameouts", PATTACH_ABSORIGIN_FOLLOW, ent, 0 )
end)


local warnings = {}
surface.CreateFont("warningfont", {font = "Arial", size = ScreenScale(8), weight = 800, outline = false, antialias = true})


function Warning(message, time)
	surface.SetFont("warningfont")
	local width,height = surface.GetTextSize(message)
	local notice = vgui.Create("l4dwarning")
	notice:SetText(message)
	notice.duration = time
	notice:SetAlpha(0)
	notice:SetPos(ScrW()/2 - width/2, ScrH()/2)
	notice:SetWide(ScrW()/2)
	notice:SetTall(100)
	notice:MoveTo(ScrW()/2 - width/2, ScrH() / 1.3-(#warnings+1)*30, 0.7, 0.1, 4)
	notice:AlphaTo(255, 0.2, 0)
	notice:SizeToContents()
	notice:CallOnRemove(function()
		for k,v in pairs(warnings) do
			if v == notice then
				table.remove(warnings, k)
			end
		end
		for k,v in pairs(warnings) do
			v:MoveTo(ScrW()/2 - width/2, ScrH() / 1.3-(k*30), 0.7, 0.1, 4)
		end
	end)
	table.insert(warnings, notice)

end





local PANEL = {}
local img = Material("exclaim.png")
function PANEL:Init()
	self.start = CurTime()
	self.finish = self.start + (self.duration or 5)
	LocalPlayer():EmitSound("beepclear.wav", 40)

	self:ParentToHUD()

	self:SetWidth(ScrW()/2)
	self:SetContentAlignment(5)

	self:SetTextColor(color_white)
	self:SetFont("warningfont")
	self:SetExpensiveShadow(2, Color(0,0,0,100))
	self:SizeToContents()

	local x,y = self:GetPos()

	self.img = vgui.Create("DImage")
	self.img:SetPos(x - 20, y)
	self.img:SetImage("exclaim.png")
	self.img:SetSize(32,32)

end



function PANEL:CallOnRemove(callback)
	self.callback = callback
end

function PANEL:Think()
  local x,y = self:GetPos()
  self.img:SetPos(x-50, y-3)
	if (self.start and self.finish and CurTime() > self.finish) then
		self:MoveTo(ScrW(), ScrH()/5, 0.7, 0.1, 1)
		self:AlphaTo(0, 0.35, 0)

		timer.Simple(0.25, function()
			if (IsValid(self)) then
				if (self.callback) then
					self.callback()
				end

				self:Remove()
				self.img:Remove()
			end
		end)
	end
end

vgui.Register("l4dwarning", PANEL, "DLabel")




