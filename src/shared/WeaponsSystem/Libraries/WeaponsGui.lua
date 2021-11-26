local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

local WeaponsSystemFolder = script.Parent.Parent
local WeaponData = WeaponsSystemFolder:WaitForChild("WeaponData")
local Libraries = WeaponsSystemFolder:WaitForChild("Libraries")
local SpringService = require(Libraries:WaitForChild("SpringService"))

local DirectionalIndicatorGuiManager = require(Libraries:WaitForChild("DirectionalIndicatorGuiManager"))
local DamageBillboardHandler = require(Libraries:WaitForChild("DamageBillboardHandler"))

local WeaponsSystemGuiTemplate = WeaponsSystemFolder:WaitForChild("Assets"):WaitForChild("WeaponsSystemGui")

local AIM_ON_NORMAL = "rbxassetid://2804583948"
local AIM_OFF_NORMAL = "rbxassetid://2804597178"
local AIM_ON_PRESSED = "rbxassetid://2804598866"
local AIM_OFF_PRESSED = "rbxassetid://2804599869"

local FIRE_NORMAL = "rbxassetid://2804818047"
local FIRE_PRESSED = "rbxassetid://2804818076"

local WeaponsGui = {}
WeaponsGui.__index = WeaponsGui

function WeaponsGui.new(weaponsSystem)
	local self = setmetatable({}, WeaponsGui)
	self.weaponsSystem = weaponsSystem
	self.connections = {}
	self.enabled = false

	self.referenceViewportSize = Vector2.new(1000, 1000) -- viewport size that ui elements in scalingElementsFolder were designed on
	self.scaleWeight = 0.75 -- determines weight of scaling (a higher value increases the degree to which elements are scaled)
	self.originalScaleAmounts = {}

	self.crosshairDampingRatio = 0.9
	self.crosshairFrequency = 3
	self.crosshairScaleTarget = 1
	self.crosshairScale = 1
	self.crosshairWeaponScale = 1
	self.crosshairEnabled = true

	self.scopeEnabled = false
	self.isZoomed = false

	self.gui = WeaponsSystemGuiTemplate:Clone()
	self.gui.Enabled = false

	coroutine.wrap(function()
		self.scalingElementsFolder = self.gui:WaitForChild("ScalingElements")

		self.DirectionalIndicatorGuiManager = DirectionalIndicatorGuiManager.new(self)

		self.crosshairFrame = self.scalingElementsFolder:WaitForChild("Crosshair")
		self.crosshairBottom = self.crosshairFrame:WaitForChild("Bottom")
		self.crosshairLeft = self.crosshairFrame:WaitForChild("Left")
		self.crosshairRight = self.crosshairFrame:WaitForChild("Right")
		self.crosshairTop = self.crosshairFrame:WaitForChild("Top")
		self.origCrosshairScales = {} -- these will be used to size crosshair pieces when screen size changes
		self.origCrosshairScales[self.crosshairBottom] = Vector2.new(self.crosshairBottom.Size.X.Scale, self.crosshairBottom.Size.Y.Scale)
		self.origCrosshairScales[self.crosshairLeft] = Vector2.new(self.crosshairLeft.Size.X.Scale, self.crosshairLeft.Size.Y.Scale)
		self.origCrosshairScales[self.crosshairRight] = Vector2.new(self.crosshairRight.Size.X.Scale, self.crosshairRight.Size.Y.Scale)
		self.origCrosshairScales[self.crosshairTop] = Vector2.new(self.crosshairTop.Size.X.Scale, self.crosshairTop.Size.Y.Scale)
		self.crosshairNormalSize = self.crosshairFrame.AbsoluteSize

		self.hitMarker = self.scalingElementsFolder:WaitForChild("HitMarker"):WaitForChild("HitMarkerImage")

		self.scopeFrame = self.gui:WaitForChild("Scope")
		local scopeImage = self.scopeFrame:WaitForChild("ScopeImage")

		self.smallTouchscreen = self.gui:WaitForChild("SmallTouchscreen")
		self.largeTouchscreen = self.gui:WaitForChild("LargeTouchscreen")

		self.smallAimButton = self.smallTouchscreen:WaitForChild("AimButton")
		self.smallAimButton.Activated:Connect(function() self:onTouchAimButtonActivated() end)
		self.largeAimButton = self.largeTouchscreen:WaitForChild("AimButton")
		self.largeAimButton.Activated:Connect(function() self:onTouchAimButtonActivated() end)
		self.smallFireButton = self.smallTouchscreen:WaitForChild("FireButton")
		self.smallFireButton.InputBegan:Connect(function(inputObj) self:onTouchFireButton(inputObj, Enum.UserInputState.Begin) end)
		self.smallFireButton.InputEnded:Connect(function(inputObj) self:onTouchFireButton(inputObj, Enum.UserInputState.End) end)
		self.largeFireButton = self.largeTouchscreen:WaitForChild("FireButton")
		self.largeFireButton.InputBegan:Connect(function(inputObj) self:onTouchFireButton(inputObj, Enum.UserInputState.Begin) end)
		self.largeFireButton.InputEnded:Connect(function(inputObj) self:onTouchFireButton(inputObj, Enum.UserInputState.End) end)

		self.smallFireButton.Visible = false
		self.largeFireButton.Visible = false

		self.gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
		self.gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() self:onScreenSizeChanged() end)
		self:onScreenSizeChanged()

		WeaponData.OnClientEvent:Connect(function(cmd, otherPlayerPosition)
			if cmd == "HitByOtherPlayer" then
				self.DirectionalIndicatorGuiManager:ActivateDirectionalIndicator("DamageIndicator", otherPlayerPosition)
			end
		end)

		ContentProvider:PreloadAsync({
			self.crosshairBottom,
			self.crosshairLeft,
			self.crosshairRight,
			self.crosshairTop,
			scopeImage,
			self.smallAimButton,
			self.largeAimButton,
			self.smallFireButton,
			self.largeFireButton,
		})
	end)()

	return self
end

local function getJumpButton()
	if UserInputService.TouchEnabled then
		local touchGui = LocalPlayer.PlayerGui:WaitForChild("TouchGui")
		return touchGui.TouchControlFrame:FindFirstChild("JumpButton")
	end

	return nil
end

function WeaponsGui:onScreenSizeChanged()
	if self.smallTouchscreen and self.largeTouchscreen then
		if UserInputService.TouchEnabled then
			local isSmallScreen
			local jumpButton = getJumpButton()
			if jumpButton then
				isSmallScreen = jumpButton.Size.X.Offset <= 70
			else
				isSmallScreen = self.gui.AbsoluteSize.Y < 600
			end
			self.smallTouchscreen.Visible = isSmallScreen
			self.largeTouchscreen.Visible = not isSmallScreen
		else
			self.smallTouchscreen.Visible = false
			self.largeTouchscreen.Visible = false
		end
	end

	-- Scales all ui elements in scalingElementsFolder based on current screen size relative to self.referenceViewportSize
	local viewportSize = workspace.CurrentCamera.ViewportSize
	for _, child in pairs(self.scalingElementsFolder:GetChildren()) do
		self:updateScale(child, viewportSize)
	end

	self.crosshairNormalSize = self.crosshairFrame.AbsoluteSize

	-- Update crosshair sizes...they must use offset because crosshairFrame changes size frequently
	self.crosshairBottom.Size = UDim2.new(0, self.origCrosshairScales[self.crosshairBottom].X * self.crosshairNormalSize.X, 0, self.origCrosshairScales[self.crosshairBottom].Y * self.crosshairNormalSize.Y)
	self.crosshairLeft.Size = UDim2.new(0, self.origCrosshairScales[self.crosshairLeft].X * self.crosshairNormalSize.X, 0, self.origCrosshairScales[self.crosshairLeft].Y * self.crosshairNormalSize.Y)
	self.crosshairRight.Size = UDim2.new(0, self.origCrosshairScales[self.crosshairRight].X * self.crosshairNormalSize.X, 0, self.origCrosshairScales[self.crosshairRight].Y * self.crosshairNormalSize.Y)
	self.crosshairTop.Size = UDim2.new(0, self.origCrosshairScales[self.crosshairTop].X * self.crosshairNormalSize.X, 0, self.origCrosshairScales[self.crosshairTop].Y * self.crosshairNormalSize.Y)
end

-- This scales the scale amount non-linearly according to scaleWeight
function WeaponsGui:getWeightedScaleAmount(originalScaleAmount, newScreenDim, referenceScreenDim)
	return (1 - self.scaleWeight) * originalScaleAmount * referenceScreenDim / newScreenDim + self.scaleWeight * originalScaleAmount
end

function WeaponsGui:updateScale(guiObject, viewportSize)
	if guiObject:IsA("GuiObject") then
		local xScale = guiObject.Size.X.Scale
		local yScale = guiObject.Size.Y.Scale
		if xScale ~= 0 or yScale ~= 0 or self.originalScaleAmounts[guiObject] ~= nil then
			if self.originalScaleAmounts[guiObject] == nil then
				self.originalScaleAmounts[guiObject] = Vector2.new(xScale, yScale)
			end

			xScale = self:getWeightedScaleAmount(self.originalScaleAmounts[guiObject].X, viewportSize.X, self.referenceViewportSize.X)
			yScale = self:getWeightedScaleAmount(self.originalScaleAmounts[guiObject].Y, viewportSize.Y, self.referenceViewportSize.Y)
			guiObject.Size = UDim2.new(xScale, 0, yScale, 0)
		end
		return -- makes it so only the most outer container will be scaled
	end

	for _, child in ipairs(guiObject:GetChildren()) do
		self:updateScale(child, viewportSize)
	end
end

function WeaponsGui:setEnabled(enabled)
	if self.enabled == enabled then
		return
	end

	self.enabled = enabled
	if self.enabled then
		self.connections.renderStepped = RunService.RenderStepped:Connect(function(dt) self:onRenderStepped(dt) end)
	else
		self:setZoomed(false)

		for _, v in pairs(self.connections) do
			v:Disconnect()
		end
		self.connections = {}
	end

	if self.gui then
		self.gui.Enabled = self.enabled
	end
end

function WeaponsGui:setCrosshairEnabled(crosshairEnabled)
	if self.crosshairEnabled == crosshairEnabled then
		return
	end

	self.crosshairEnabled = crosshairEnabled
	if self.crosshairFrame then
		self.crosshairFrame.Visible = self.crosshairEnabled
	end
	if self.hitMarker then
		self.hitMarker.ImageTransparency = 1
		self.hitMarker.Visible = self.crosshairEnabled
	end
end

function WeaponsGui:setScopeEnabled(scopeEnabled)
	if self.scopeEnabled == scopeEnabled then
		return
	end

	self.scopeEnabled = scopeEnabled
	if self.scopeFrame then
		self.scopeFrame.Visible = self.scopeEnabled
	end

	local jumpButton = getJumpButton()

	if self.scopeEnabled then
		self.smallFireButton.Visible = true
		self.largeFireButton.Visible = true

		if jumpButton then
			jumpButton.Visible = false
		end
	else
		self.smallFireButton.Visible = false
		self.largeFireButton.Visible = false

		if jumpButton then
			jumpButton.Visible = true
		end
	end
end

function WeaponsGui:setCrosshairWeaponScale(scale)
	if self.crosshairWeaponScale == scale then
		return
	end

	self.crosshairWeaponScale = scale
end

function WeaponsGui:setCrosshairScaleTarget(target, dampingRatio, frequency)
	if typeof(dampingRatio) == "number" then
		self.crosshairDampingRatio = dampingRatio
	end
	if typeof(frequency) == "number" then
		self.crosshairFrequency = frequency
	end
	if self.crosshairScaleTarget == target then
		return
	end

	self.crosshairScaleTarget = target
	SpringService:Target(self, self.crosshairDampingRatio, self.crosshairFrequency, { crosshairScale = self.crosshairScaleTarget })
end

function WeaponsGui:setCrosshairScale(scale)
	if self.crosshairScale == scale then
		return
	end

	self.crosshairScale = scale
	SpringService:Target(self, self.crosshairDampingRatio, self.crosshairFrequency, { crosshairScale = self.crosshairScaleTarget })
end

function WeaponsGui:OnHitOtherPlayer(damage, humanoidHit) -- show hit indicator, then fade
	self.hitMarker.ImageTransparency = 0
	local tweenInfo = TweenInfo.new(0.8)
	local goal = {}
	goal.ImageTransparency = 1
	local tween = TweenService:Create(self.hitMarker, tweenInfo, goal)
	tween:Play()

	DamageBillboardHandler:ShowDamageBillboard(damage, humanoidHit.Parent:FindFirstChild("Head"))
end

function WeaponsGui:onRenderStepped(dt)
	if not self.enabled then
		return
	end
	if not self.gui then
		return
	end

	if self.crosshairFrame and self.crosshairEnabled then
		local crosshairSize = self.crosshairNormalSize * self.crosshairScale * self.crosshairWeaponScale
		self.crosshairFrame.Size = UDim2.new(0, crosshairSize.X, 0, crosshairSize.Y)
	end
end

function WeaponsGui:setZoomed(zoomed)
	if zoomed == self.isZoomed then
		return
	end

	self.isZoomed = zoomed
	local normalImage = self.isZoomed and AIM_OFF_NORMAL or AIM_ON_NORMAL
	local pressedImage = self.isZoomed and AIM_OFF_PRESSED or AIM_ON_PRESSED

	if self.smallAimButton then
		self.smallAimButton.Image = normalImage
		self.smallAimButton.PressedImage = pressedImage
	end
	if self.largeAimButton then
		self.largeAimButton.Image = normalImage
		self.largeAimButton.PressedImage = pressedImage
	end

	if self.weaponsSystem.camera then
		self.weaponsSystem.camera:setForceZoomed(self.isZoomed)
	end
end

function WeaponsGui:onTouchAimButtonActivated()
	self:setZoomed(not self.isZoomed)
end

function WeaponsGui:onTouchFireButton(inputObj, inputState)
	local currentWeapon = self.weaponsSystem.currentWeapon
	if currentWeapon and currentWeapon.instance and currentWeapon.instance:IsA("Tool") then
		if inputObj.UserInputState == Enum.UserInputState.Begin then
			currentWeapon.instance:Activate()
			if self.smallFireButton then
				self.smallFireButton.Image = FIRE_PRESSED
			end
			if self.largeFireButton then
				self.largeFireButton.Image = FIRE_PRESSED
			end

			inputObj:GetPropertyChangedSignal("UserInputState"):Connect(function()
				if inputObj.UserInputState == Enum.UserInputState.End then
					currentWeapon.instance:Deactivate()
					if self.smallFireButton then
						self.smallFireButton.Image = FIRE_NORMAL
					end
					if self.largeFireButton then
						self.largeFireButton.Image = FIRE_NORMAL
					end
				end
			end)
		end
	end
end

return WeaponsGui