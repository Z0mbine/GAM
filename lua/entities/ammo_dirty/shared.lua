AddCSLuaFile()
include("ammotype/sh_util.lua")
ENT.Type = "anim"
ENT.Base = "base_entity"
ENT.AdminOnly = true
ENT.Spawnable = true
ENT.Amount = 200
ENT.Category = "Ammo Mods"
ENT.PrintName = "Dirty Rounds"
ENT.RenderGroup = RENDERGROUP_OPAQUE

if SERVER then


	function ENT:SpawnFunction( client, trace, class )

		if ( !trace.Hit ) then return end

		local SpawnPos = trace.HitPos + trace.HitNormal * 1

		local ent = ents.Create( class )
		ent:SetPos( SpawnPos )
		ent:Spawn()
		ent:Activate()

		return ent

	end


	function ENT:Initialize()

		self:SetModel("models/items/boxmrounds.mdl")
		self:SetSolid(SOLID_VPHYSICS)
		self:PhysicsInit(SOLID_VPHYSICS)
		local phys = self:GetPhysicsObject()

		if phys and phys:IsValid() then
			phys:Wake()
		end

	end



	function ENT:Use( act, call, type, value )
		if act:IsPlayer() then
			self:Remove()
			act:GiveAmmoType( string.sub(self.ClassName, 6), self.Amount )
			--act:ChatPrint("+"..self.Amount.." "..self.PrintName)
			act:EmitSound("items/ammopickup.wav", 65)
		end
	end

else

	function ENT:Draw()
		self:DrawModel()
	end

end