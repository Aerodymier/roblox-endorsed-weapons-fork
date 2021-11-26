local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local IsServer = RunService:IsServer()

local WeaponsSystemFolder = script.Parent.Parent
local AnimationsFolder = WeaponsSystemFolder:WaitForChild("Assets"):WaitForChild("Animations")

local localRandom = Random.new()

local BaseWeapon = {}
BaseWeapon.__index = BaseWeapon

BaseWeapon.CanAimDownSights = false
BaseWeapon.CanBeReloaded = false
BaseWeapon.CanBeFired = false
BaseWeapon.CanHit = false

function BaseWeapon.new(weaponsSystem, instance)
	assert(instance, "BaseWeapon.new() requires a valid Instance to be attached to.")

	local self = setmetatable({}, BaseWeapon)
	self.connections = {}
	self.descendants = {}
	self.descendantsRegistered = false
	self.optionalDescendantNames = {}
	self.weaponsSystem = weaponsSystem
	self.instance = instance
	self.animController = nil
	self.player = nil
	self.enabled = false
	self.equipped = false
	self.activated = false
	self.nextShotId = 1
	self.activeRenderStepName = nil
	self.curReloadSound = nil

	self.animTracks = {}
	self.sounds = {}
	self.configValues = {}
	self.trackedConfigurations = {}

	self.ammoInWeaponValue = nil

	self.reloading = false
	self.canReload = true

	self:registerDescendants()
	self.connections.descendantAdded = self.instance.DescendantAdded:Connect(function(descendant)
		self:onDescendantAdded(descendant)
	end)

	return self
end

function BaseWeapon:doInitialSetup()
	local selfClass = getmetatable(self)
	self.instanceIsTool = self.instance:IsA("Tool")

	-- Set up child added/removed
	self.connections.childAdded = self.instance.ChildAdded:Connect(function(child)
		self:onChildAdded(child)
	end)
	self.connections.childRemoved = self.instance.ChildRemoved:Connect(function(child)
		self:onChildRemoved(child)
	end)
	for _, child in pairs(self.instance:GetChildren()) do
		self:onChildAdded(child)
	end

	-- Initialize self.ammoInWeaponValue
	if selfClass.CanBeReloaded then
		if IsServer then
			self.ammoInWeaponValue = self.instance:FindFirstChild("CurrentAmmo")
			if not self.ammoInWeaponValue then
				self.ammoInWeaponValue = Instance.new("IntValue")
				self.ammoInWeaponValue.Name = "CurrentAmmo"
				self.ammoInWeaponValue.Value = 0
				self.ammoInWeaponValue.Parent = self.instance
			end
			self.ammoInWeaponValue.Value = self:getConfigValue("AmmoCapacity", 30)
		else
			self.ammoInWeaponValue = self.instance:WaitForChild("CurrentAmmo")
		end
	end

	self.connections.ancestryChanged = self.instance.AncestryChanged:Connect(function() self:onAncestryChanged() end)
	self:onAncestryChanged()

	-- Set up equipped/unequipped and activated/deactivated
	if self.instanceIsTool then
		self.connections.equipped = self.instance.Equipped:Connect(function()
			if IsServer or (Players.LocalPlayer and (self.instance:IsDescendantOf(Players.LocalPlayer.Backpack) or self.instance:IsDescendantOf(Players.LocalPlayer.Character))) then
				self:setEquipped(true)
				if self:getAmmoInWeapon() <= 0 then
					-- Have to wait a frame, otherwise the reload animation will not play
					coroutine.wrap(function()
						wait()
						self:reload()
					end)()
				end
			end
		end)
		self.connections.unequipped = self.instance.Unequipped:Connect(function()
			if IsServer or (Players.LocalPlayer and (self.instance:IsDescendantOf(Players.LocalPlayer.Backpack) or self.instance:IsDescendantOf(Players.LocalPlayer.Character))) then
				self:setEquipped(false)
				if self.reloading then
					self:cancelReload()
				end
			end
		end)
		if self.instance:IsDescendantOf(workspace) and self.player then
			self:setEquipped(true)
		end

		self.connections.activated = self.instance.Activated:Connect(function()
			self:setActivated(true)
		end)
		self.connections.deactivated = self.instance.Deactivated:Connect(function()
			self:setActivated(false)
		end)

		-- Weld handle to weapon primary part
		if IsServer then
			self.handle = self.instance:FindFirstChild("Handle")

			local model = self.instance:FindFirstChildOfClass("Model")
			local handleAttachment = model:FindFirstChild("HandleAttachment", true)

			if self.handle and handleAttachment then
				local handleOffset = model.PrimaryPart.CFrame:toObjectSpace(handleAttachment.WorldCFrame)

				local weld = Instance.new("Weld")
				weld.Name = "HandleWeld"
				weld.Part0 = self.handle
				weld.Part1 = model.PrimaryPart
				weld.C0 = CFrame.new()
				weld.C1 = handleOffset
				weld.Parent = self.handle

				self.handle.Anchored = false
				model.PrimaryPart.Anchored = false
			end
		end
	end
end

function BaseWeapon:registerDescendants()
	if not self.instance then
		error("No instance set yet!")
	end

	if self.descendantsRegistered then
		warn("Descendants already registered!")
		return
	end

	for _, descendant in ipairs(self.instance:GetDescendants()) do
		if self.descendants[descendant.Name] == nil then
			self.descendants[descendant.Name] = descendant
		else
			self.descendants[descendant.Name] = "Multiple"
		end
	end
	self.descendantsRegistered = true
end

function BaseWeapon:addOptionalDescendant(key, descendantName)
	if self.instance == nil then
		error("No instance set yet!")
	end

	if not self.descendantsRegistered then
		error("Descendants not registered!")
	end

	if self.descendants[descendantName] == "Multiple" then
		error("Weapon \""..self.instance.Name.."\" has multiple descendants named \""..descendantName.."\", so you cannot addOptionalDescendant with that descendant name.")
	end

	local found = self.descendants[descendantName]
	if found then
		self[key] = found
		return
	else
		self.optionalDescendantNames[descendantName] = key
	end
end

function BaseWeapon:onDescendantAdded(descendant)
	if self.descendants[descendant.Name] == nil then
		self.descendants[descendant.Name] = descendant
	else
		self.descendants[descendant.Name] = "Multiple"
	end

	local desiredKey = self.optionalDescendantNames[descendant.Name]
	if desiredKey then
		if self.descendants[descendant.Name] == "Multiple" then
			error("Weapon \""..self.instance.Name.."\" has multiple descendants named \""..descendant.Name.."\", so you cannot addOptionalDependency with that descendant name.")
		end
		self[desiredKey] = descendant
		self.optionalDescendantNames[descendant.Name] = nil
	end
end

function BaseWeapon:cleanupConnection(...)
	local args = { ... }
	for _, name in pairs(args) do
		if typeof(name) == "string" and self.connections[name] then
			self.connections[name]:Disconnect()
			self.connections[name] = nil
		end
	end
end

function BaseWeapon:onAncestryChanged()
	if self.instanceIsTool then
		local player = nil
		if self.instance:IsDescendantOf(Players) then
			local parentPlayer = self.instance.Parent.Parent
			if parentPlayer and parentPlayer:IsA("Player") then
				player = parentPlayer
			end
		elseif self.instance:IsDescendantOf(workspace) then
			local parentPlayer = Players:GetPlayerFromCharacter(self.instance.Parent)
			if parentPlayer and parentPlayer:IsA("Player") then
				player = parentPlayer
			end
		end

		self:setPlayer(player)
	end
end

function BaseWeapon:setPlayer(player)
	if self.player == player then
		return
	end

	self.player = player
end

function BaseWeapon:setEquipped(equipped)
	if self.equipped == equipped then
		return
	end

	self.equipped = equipped
	self:onEquippedChanged()

	if not self.equipped then
		self:stopAnimations()
	end
end

function BaseWeapon:onEquippedChanged()
	if self.activeRenderStepName then
		RunService:UnbindFromRenderStep(self.activeRenderStepName)
		self.activeRenderStepName = nil
	end
	self:cleanupConnection("localStepped")

	if not IsServer and self.weaponsSystem then
		self.weaponsSystem.setWeaponEquipped(self, self.equipped)
		if self.equipped then
			if self.player == Players.LocalPlayer then
				RunService:BindToRenderStep(self.instance:GetFullName(), Enum.RenderPriority.Input.Value, function(dt)
					self:onRenderStepped(dt)
				end)
				self.activeRenderStepName = self.instance:GetFullName()
			end
			self.connections.localStepped = RunService.Heartbeat:Connect(function(dt)
				self:onStepped(dt)
			end)
		end
	end

	if self.instanceIsTool then
		for _, part in pairs(self.instance:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = part ~= self.handle and not self.equipped
			end
		end
	end

	self:setActivated(false)
end

function BaseWeapon:setActivated(activated, fromNetwork)
	if not IsServer and fromNetwork and self.player == Players.LocalPlayer then
		return
	end

	if self.activated == activated then
		return
	end

	self.activated = activated
	if IsServer and not fromNetwork then
		self.weaponsSystem.getRemoteEvent("WeaponActivated"):FireAllClients(self.player, self.instance, self.activated)
	end

	self:onActivatedChanged()
end

function BaseWeapon:onActivatedChanged()

end

function BaseWeapon:renderFire(fireInfo)

end

function BaseWeapon:simulateFire(fireInfo)

end

function BaseWeapon:isOwnerAlive()
	if self.instance:IsA("Tool") then
		local humanoid = self.instance.Parent:FindFirstChildOfClass("Humanoid")
		if humanoid then
			return humanoid:GetState() ~= Enum.HumanoidStateType.Dead
		end
	end

	return true
end

function BaseWeapon:fire(origin, dir, charge)
	if not self:isOwnerAlive() or self.reloading then
		return
	end

	if self:useAmmo(1) <= 0 then
		self:reload()
		return
	end

	local fireInfo = {}
	fireInfo.origin = origin
	fireInfo.dir = dir
	fireInfo.charge = math.clamp(charge or 1, 0, 1)
	fireInfo.id = self.nextShotId
	self.nextShotId = self.nextShotId + 1

	if not IsServer then
		self:onFired(self.player, fireInfo, false)
		self.weaponsSystem.getRemoteEvent("WeaponFired"):FireServer(self.instance, fireInfo)
	else
		self:onFired(self.player, fireInfo, false)
	end
end

function BaseWeapon:onFired(firingPlayer, fireInfo, fromNetwork)
	if not IsServer then
		if firingPlayer == Players.LocalPlayer and fromNetwork then
			return
		end

		self:simulateFire(firingPlayer, fireInfo)
	else
		if self:useAmmo(1) <= 0 then
			return
		end

		self.weaponsSystem.getRemoteEvent("WeaponFired"):FireAllClients(firingPlayer, self.instance, fireInfo)
	end
end

function BaseWeapon:getConfigValue(valueName, defaultValue)
	if self.configValues[valueName] ~= nil then
		return self.configValues[valueName]
	else
		return defaultValue
	end
end

function BaseWeapon:tryPlaySound(soundName, playbackSpeedRange)
	playbackSpeedRange = playbackSpeedRange or 0

	local soundTemplate = self.sounds[soundName]
	if not soundTemplate then
		soundTemplate = self.instance:FindFirstChild(soundName, true)
		self.sounds[soundName] = soundTemplate
	end

	if not soundTemplate then
		return
	end

	local sound = soundTemplate:Clone()
	sound.PlaybackSpeed = sound.PlaybackSpeed + localRandom:NextNumber(-playbackSpeedRange * 0.5, playbackSpeedRange * 0.5)
	sound.Parent = soundTemplate.Parent
	sound:Play()
	coroutine.wrap(function()
		wait(sound.TimeLength / sound.PlaybackSpeed)
		sound:Destroy()
	end)()

	return sound
end

function BaseWeapon:getSound(soundName)
	local soundTemplate = self.sounds[soundName]
	if not soundTemplate then
		soundTemplate = self.instance:FindFirstChild(soundName, true)
		self.sounds[soundName] = soundTemplate
	end

	return soundTemplate
end

function BaseWeapon:onDestroyed()

end

function BaseWeapon:onConfigValueAdded(valueObj)
	local valueName = valueObj.Name
	local newValue = valueObj.Value
	self.configValues[valueName] = newValue
	self:onConfigValueChanged(valueName, newValue, nil)

	self.connections["valueChanged:" .. valueName] = valueObj.Changed:Connect(function(changedValue)
		local oldValue = self.configValues[valueName]
		self.configValues[valueName] = changedValue

		self:onConfigValueChanged(valueName, changedValue, oldValue)
	end)
	self.connections["valueRenamed:" .. valueName] = valueObj:GetPropertyChangedSignal("Name"):Connect(function()
		self.configValues[valueName] = nil
		self:cleanupConnection("valueChanged:" .. valueName)
		self:cleanupConnection("valueRenamed:" .. valueName)
		self:onConfigValueAdded(valueObj)
	end)
end

function BaseWeapon:onConfigValueRemoved(valueObj)
	local valueName = valueObj.Name
	self.configValues[valueName] = nil

	self:cleanupConnection("valueChanged:" .. valueName)
	self:cleanupConnection("valueRenamed:" .. valueName)
end

-- This function is used to set configuration values from outside configuration objects/folders
function BaseWeapon:importConfiguration(config)
	if not config or not config:IsA("Configuration") then
		for _, child in pairs(config:GetChildren()) do
			if child:IsA("ValueBase") then
				local valueName = child.Name
				local newValue = child.Value
				local oldValue = self.configValues[valueName]
				self.configValues[valueName] = newValue
				self:onConfigValueChanged(valueName, newValue, oldValue)
			end
		end
	end
end

function BaseWeapon:setConfiguration(config)
	self:cleanupConnection("configChildAdded", "configChildRemoved")
	if not config or not config:IsA("Configuration") then
		return
	end

	for _, child in pairs(config:GetChildren()) do
		if child:IsA("ValueBase") then
			self:onConfigValueAdded(child)
		end
	end
	self.connections.configChildAdded = config.ChildAdded:Connect(function(child)
		if child:IsA("ValueBase") then
			self:onConfigValueAdded(child)
		end
	end)
	self.connections.configChildRemoved = config.ChildRemoved:Connect(function(child)
		if child:IsA("ValueBase") then
			self:onConfigValueRemoved(child)
		end
	end)
end

function BaseWeapon:onChildAdded(child)
	if child:IsA("Configuration") then
		self:setConfiguration(child)
	end
end

function BaseWeapon:onChildRemoved(child)
	if child:IsA("Configuration") then
		self:setConfiguration(nil)
	end
end

function BaseWeapon:onConfigValueChanged(valueName, newValue, oldValue)

end

function BaseWeapon:onRenderStepped(dt)

end

function BaseWeapon:onStepped(dt)

end

function BaseWeapon:getAnimationController()
	if self.animController then
		if not self.instanceIsTool or (self.animController.Parent and self.animController.Parent:IsAncestorOf(self.instance)) then
			return self.animController
		end
	end

	self:setAnimationController(nil)

	if self.instanceIsTool then
		local humanoid = IsServer and self.instance.Parent:FindFirstChildOfClass("Humanoid") or self.instance.Parent:WaitForChild("Humanoid", math.huge)
		local animController = nil
		if not humanoid then
			animController = self.instance.Parent:FindFirstChildOfClass("AnimationController")
		end

		self:setAnimationController(humanoid or animController)
		return self.animController
	end
end

function BaseWeapon:setAnimationController(animController)
	if animController == self.animController then
		return
	end
	self:stopAnimations()
	self.animController = animController
end

function BaseWeapon:stopAnimations()
	for _, track in pairs(self.animTracks) do
		if track.IsPlaying then
			track:Stop()
		end
	end
	self.animTracks = {}
end

function BaseWeapon:getAnimTrack(key)
	local track = self.animTracks[key]
	if not track then
		local animController = self:getAnimationController()
		if not animController then
			warn("No animation controller when trying to play ", key)
			return nil
		end

		local animation = AnimationsFolder:FindFirstChild(key)
		if not animation then
			error(string.format("No such animation \"%s\" ", tostring(key)))
		end

		track = animController:LoadAnimation(animation)
		self.animTracks[key] = track
	end

	return track
end

function BaseWeapon:reload(player, fromNetwork)
	if
		not self.equipped or
		self.reloading or
		not self.canReload or
		self:getAmmoInWeapon() == self:getConfigValue("AmmoCapacity", 30)
	then
		return false
	end

	if not IsServer then
		if self.player ~= nil and self.player ~= Players.LocalPlayer then
			return
		end
		self.weaponsSystem.getRemoteEvent("WeaponReloadRequest"):FireServer(self.instance)
		self:onReloaded(self.player)
	else
		self:onReloaded(player, fromNetwork)
		self.weaponsSystem.getRemoteEvent("WeaponReloaded"):FireAllClients(player, self.instance)
	end
end

function BaseWeapon:onReloaded(player, fromNetwork)
	if fromNetwork and player == Players.LocalPlayer then -- make sure localplayer doesn't reload twice
		return
	end

	self.reloading = true
	self.canReload = false

	-- Play reload animation and sound
	if not IsServer then
		local reloadTrackKey = self:getConfigValue("ReloadAnimation", "RifleReload")
		if reloadTrackKey then
			self.reloadTrack = self:getAnimTrack(reloadTrackKey)
			if self.reloadTrack then
				self.reloadTrack:Play()
			end
		end

		self.curReloadSound = self:tryPlaySound("Reload", nil)
		if self.curReloadSound then
			self.curReloadSound.Ended:Connect(function()
				self.curReloadSound = nil
			end)
		end
	end

	local reloadTime = self:getConfigValue("ReloadTime", 2)
	local startTime = tick()

	if self.connections.reload ~= nil then -- this prevents an endless ammo bug
		return
	end
	self.connections.reload = RunService.Heartbeat:Connect(function()
		-- Stop trying to reload if the player unequipped this weapon or reloading was canceled some other way
		if not self.reloading then
			if self.connections.reload then
				self.connections.reload:Disconnect()
				self.connections.reload = nil
			end
		end

		-- Wait until gun finishes reloading
		if tick() < startTime + reloadTime then
			return
		end

		-- Add ammo to weapon
		if self.ammoInWeaponValue then
			self.ammoInWeaponValue.Value = self:getConfigValue("AmmoCapacity", 30)
		end

		if self.connections.reload then
			self.connections.reload:Disconnect()
			self.connections.reload = nil
		end

		self.reloading = false
		self.canReload = false
	end)
end

function BaseWeapon:cancelReload(player, fromNetwork)
	if not self.reloading then
		return
	end
	if fromNetwork and player == Players.LocalPlayer then
		return
	end

	if not IsServer and not fromNetwork and player == Players.LocalPlayer then
		self.weaponsSystem.getRemoteEvent("WeaponReloadCanceled"):FireServer(self.instance)
	elseif IsServer and fromNetwork then
		self.weaponsSystem.getRemoteEvent("WeaponReloadCanceled"):FireAllClients(player, self.instance)
	end

	self.reloading = false
	self.canReload = true

	if not IsServer and self.reloadTrack and self.reloadTrack.IsPlaying then
		warn("Stopping reloadTrack")
		self.reloadTrack:Stop()
	end
	if self.curReloadSound then
		self.curReloadSound:Stop()
		self.curReloadSound:Destroy()
		self.curReloadSound = nil
	end
end

function BaseWeapon:getAmmoInWeapon()
	if self.ammoInWeaponValue then
		return self.ammoInWeaponValue.Value
	end
	return 0
end

function BaseWeapon:useAmmo(amount)
	if self.ammoInWeaponValue then
		local ammoUsed = math.min(amount, self.ammoInWeaponValue.Value)
		self.ammoInWeaponValue.Value = self.ammoInWeaponValue.Value - ammoUsed
		self.canReload = true
		return ammoUsed
	else
		return 0
	end
end

function BaseWeapon:renderCharge()

end

return BaseWeapon
