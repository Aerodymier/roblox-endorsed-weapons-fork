local contextAction = game:GetService("ContextActionService")
local camModule = require(game:GetService("ReplicatedStorage"):WaitForChild("WeaponsSystem"):WaitForChild("WeaponsSystem"))

local enabled = true
local keyDown = false

function disableCamera()
	local plr = game:GetService("Players").LocalPlayer
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

contextAction:BindAction("DisableCamera", disableCamera, true, Enum.KeyCode.F, Enum.KeyCode.ButtonB)
repeat wait() until contextAction:GetButton("DisableCamera")
contextAction:SetPosition("DisableCamera",  UDim2.new(0.4, 0, 0, 30))
contextAction:SetImage("DisableCamera", "http://www.roblox.com/asset/?id=6734359065")