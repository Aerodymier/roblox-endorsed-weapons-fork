local contextAction = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local weaponsSystemFolder: Folder = ReplicatedStorage:WaitForChild("WeaponsSystem")
local UseCamOnlyWhenEquipped: BoolValue = weaponsSystemFolder:WaitForChild("Configuration"):WaitForChild("UseCamOnlyWhenEquipped")

local camModule = require(weaponsSystemFolder:WaitForChild("WeaponsSystem"))

local plr = Players.LocalPlayer

local enabled = true
local keyDown = false

local function disableCamera()
	if UseCamOnlyWhenEquipped.Value then return end
	
	local char = plr.Character or plr.CharacterAdded:Wait()
	
	if keyDown == false then
		keyDown = true
		enabled = not enabled
		camModule.camera:setEnabled(enabled)
		camModule.gui:setEnabled(enabled)
		camModule.camera.mouseLocked = enabled
		if not enabled then workspace.CurrentCamera.CameraSubject = char.Humanoid end
	else
		keyDown = false
	end
end

local function contextActionBind()
	contextAction:BindAction("DisableCamera", disableCamera, true, Enum.KeyCode.F, Enum.KeyCode.ButtonB)
	repeat task.wait() until contextAction:GetButton("DisableCamera")
	contextAction:SetPosition("DisableCamera",  UDim2.new(0.4, 0, 0, 30))
	contextAction:SetImage("DisableCamera", "http://www.roblox.com/asset/?id=6734359065")
end

if not UseCamOnlyWhenEquipped.Value then
	contextActionBind()
end

UseCamOnlyWhenEquipped:GetPropertyChangedSignal("Value"):Connect(function()
	if UseCamOnlyWhenEquipped.Value then
		contextAction:UnbindAction("DisableCamera")
	else
		contextActionBind()
	end
end)