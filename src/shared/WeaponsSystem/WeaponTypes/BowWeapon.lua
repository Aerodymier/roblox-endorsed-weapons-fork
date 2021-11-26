local RunService = game:GetService("RunService")

local IsServer = RunService:IsServer()

local WeaponsSystemFolder = script.Parent.Parent

local WeaponTypes = WeaponsSystemFolder:WaitForChild("WeaponTypes")
local BulletWeapon = require(WeaponTypes:WaitForChild("BulletWeapon"))

local BowWeapon = {}
BowWeapon.__index = BowWeapon
setmetatable(BowWeapon, BulletWeapon)

BowWeapon.CanAimDownSights = true
BowWeapon.CanBeFired = true
BowWeapon.CanBeReloaded = true
BowWeapon.CanHit = true

function BowWeapon.new(weaponsSystem, instance)
	local self = BulletWeapon.new(weaponsSystem, instance)
	setmetatable(self, BowWeapon)

	self.hasArrow = true

	self.arrowPart = self.instance:FindFirstChild("Arrow", true)
	self.armsPart = self.instance:FindFirstChild("Arms", true)
	if self.armsPart then
		self.armsMesh = self.armsPart:FindFirstChildOfClass("SpecialMesh")

		self.tightOffsetValue = self.armsPart:FindFirstChild("TightOffset")
		self.tightScaleValue = self.armsPart:FindFirstChild("TightScale")

		self.looseOffsetValue = self.armsPart:FindFirstChild("LooseOffset")
		self.looseScaleValue = self.armsPart:FindFirstChild("LooseScale")

		self.leftLooseAttach = self.armsPart:FindFirstChild("LeftLoose")
		self.rightLooseAttach = self.armsPart:FindFirstChild("RightLoose")

		self.leftTightAttach = self.armsPart:FindFirstChild("LeftTight")
		self.rightTightAttach = self.armsPart:FindFirstChild("RightTight")

		self.leftString0 = self.armsPart:FindFirstChild("LeftString0")
		self.rightString0 = self.armsPart:FindFirstChild("RightString0")
	end

	self.string1 = self.instance:FindFirstChild("String1", true)
	self.stringLooseAttach = self.instance:FindFirstChild("StringLoose", true)
	self.stringTightAttach = self.instance:FindFirstChild("StringTight", true)

	self:setHasArrow(false)

	return self
end

function BowWeapon:renderCharge()
	if self.armsMesh and self.looseOffsetValue and self.looseScaleValue and self.tightOffsetValue and self.tightScaleValue then
		local looseOffset, tightOffset = self.looseOffsetValue.Value, self.tightOffsetValue.Value
		local looseScale, tightScale = self.looseScaleValue.Value, self.tightScaleValue.Value

		self.armsMesh.Offset = looseOffset:Lerp(tightOffset, self.charge)
		self.armsMesh.Scale = looseScale:Lerp(tightScale, self.charge)
	end

	if self.leftString0 and self.leftLooseAttach and self.leftTightAttach then
		self.leftString0.CFrame = self.leftLooseAttach.CFrame:lerp(self.leftTightAttach.CFrame, self.charge)
	end
	if self.rightString0 and self.rightLooseAttach and self.rightTightAttach then
		self.rightString0.CFrame = self.rightLooseAttach.CFrame:lerp(self.rightTightAttach.CFrame, self.charge)
	end

	if self.string1 and self.stringLooseAttach and self.stringTightAttach then
		self.string1.CFrame = self.stringLooseAttach.CFrame:lerp(self.stringTightAttach.CFrame, self.charge)
	end
end

function BowWeapon:handleCharging(dt)
	if self.hasArrow then return end
	BulletWeapon.handleCharging(self, dt)

	if self.charge >= 1 then
		self:setHasArrow(true)
	end
end

function BowWeapon:onActivatedChanged()
	if not IsServer then
		if not self.activated then
			if self.didFire then
				self.didFire = false
			end
		end
	end
	BulletWeapon.onActivatedChanged(self)
end

function BowWeapon:isCharged()
	return self.hasArrow and self.charge >= 1
end

function BowWeapon:doLocalFire()
	BulletWeapon.doLocalFire(self)
	self:setHasArrow(false)
	self.didFire = true
end

function BowWeapon:setHasArrow(hasArrow)
	if self.hasArrow == hasArrow then
		return
	end

	self.hasArrow = hasArrow
	if self.arrowPart then
		self.arrowPart.Transparency = self.hasArrow and 0 or 1
	end
end

return BowWeapon