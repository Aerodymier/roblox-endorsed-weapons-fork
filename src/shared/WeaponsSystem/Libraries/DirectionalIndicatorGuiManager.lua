local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local DirectionalIndicatorGuiManager = {}
DirectionalIndicatorGuiManager.__index = DirectionalIndicatorGuiManager

local function GetConfigValue(config, propertyName, default)
	if config then
		local property = config:FindFirstChild(propertyName)
		if property then
			return property.Value
		end
	end
	return default
end

function DirectionalIndicatorGuiManager.new(weaponsGui)
	local self = setmetatable({}, DirectionalIndicatorGuiManager)
	self.weaponsGui = weaponsGui
	self.connections = {}
	self.enabled = false

	-- Note DI is an abbreviation for DirectionalIndicator
	self.DIFolder = self.weaponsGui.scalingElementsFolder:WaitForChild("DirectionalIndicators")
	self.DIInfo = {}

	for _, DIFrame in ipairs(self.DIFolder:GetChildren()) do
		if DIFrame:IsA("Frame") and DIFrame:FindFirstChildOfClass("ImageLabel") then
			local config = DIFrame:FindFirstChildOfClass("Configuration")
			local name = GetConfigValue(config, "Name", DIFrame.Name)
			self.DIInfo[name] = self:GetDIInfoFromFrame(DIFrame)

			DIFrame.Visible = true
			self.DIInfo[name].image.ImageTransparency = 1
		end
	end

	return self
end

function DirectionalIndicatorGuiManager:GetDIInfoFromFrame(frame)
	local diInfo = {}
	diInfo.frame = frame
	diInfo.image = frame:FindFirstChildOfClass("ImageLabel")
	diInfo.config = frame:FindFirstChildOfClass("Configuration")
	diInfo.active = false
	diInfo.dieOnFade = false -- will only be true for copies of original DIs
	return diInfo
end

function DirectionalIndicatorGuiManager:ActivateDirectionalIndicator(DIName, otherPosition)
	-- Use original DI, or make a copy if it's already active
	local diInfo = self.DIInfo[DIName]
	if not diInfo then
		warn("Warning: invalid name given to ActivateDirectionalIndicator")
		return
	end

	if diInfo.active then
		local newFrame = diInfo.frame:Clone()
		newFrame.Parent = diInfo.frame.Parent
		diInfo = self:GetDIInfoFromFrame(newFrame)
		diInfo.dieOnFade = true
	end
	diInfo.active = true

	-- Update distance from center
	local distanceLevel = GetConfigValue(diInfo.config, "DistanceLevelFromCenter", 6)
	local widthLevel = GetConfigValue(diInfo.config, "WidthLevel", distanceLevel)
	local levelMultiplier = 0.03
	self.weaponsGui.originalScaleAmounts[diInfo.frame] = Vector2.new(widthLevel * levelMultiplier, distanceLevel * levelMultiplier * 2)
	self.weaponsGui:updateScale(diInfo.frame, workspace.CurrentCamera.ViewportSize)

	-- Set initial indicator rotation and transparency
	diInfo.frame.Rotation = self:CalculateDIRotation(otherPosition)
	diInfo.image.ImageTransparency = GetConfigValue(diInfo.config, "TransparencyBeforeFade", 0)

	-- Update rotation of indicator as player rotates
	coroutine.wrap(function()
		while diInfo.image.ImageTransparency < 1 do
			diInfo.frame.Rotation = self:CalculateDIRotation(otherPosition)
			RunService.RenderStepped:Wait()
		end

		diInfo.active = false
		if diInfo.dieOnFade then
			diInfo.frame:Destroy()
			diInfo = nil
		end
	end)()

	-- Show indicator for a bit, then fade out
	coroutine.wrap(function()
		wait(GetConfigValue(diInfo.config, "TimeBeforeFade", 1))
		local tweenInfo = TweenInfo.new(GetConfigValue(diInfo.config, "FadeTime", 1))
		local goal = {}
		goal.ImageTransparency = 1
		local tween = TweenService:Create(diInfo.image, tweenInfo, goal)
		tween:Play()
	end)()
end

function DirectionalIndicatorGuiManager:CalculateDIRotation(otherPosition)
	local camera = self.weaponsGui.weaponsSystem.camera
	local localPlayerOffsetPositionXZ = Vector3.new(camera.currentCamera.Focus.X, 0, camera.currentCamera.Focus.Z)
	local otherPlayerPositionXZ = Vector3.new(otherPosition.X, 0, otherPosition.Z)
	local toOtherPlayer = (localPlayerOffsetPositionXZ - otherPlayerPositionXZ).Unit
	local forward = (Vector3.new(camera.currentCFrame.LookVector.X, 0, camera.currentCFrame.LookVector.Z)).Unit
	if toOtherPlayer == Vector3.new() then
		toOtherPlayer = forward
	end
	local dotProduct = forward:Dot(toOtherPlayer)
	local crossProduct = forward:Cross(toOtherPlayer)
	local acosAngle = math.deg(math.acos(dotProduct))
	local asinAngle = math.deg(math.asin(crossProduct.Y))
	if asinAngle >= 0 then
		acosAngle = 360 - acosAngle
	end
	return acosAngle
end

return DirectionalIndicatorGuiManager