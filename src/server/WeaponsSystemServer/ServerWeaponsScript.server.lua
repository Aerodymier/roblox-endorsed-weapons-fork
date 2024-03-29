local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local curWeaponsSystemFolder = script.Parent
local weaponsSystemFolder = ReplicatedStorage:FindFirstChild("WeaponsSystem")
local weaponsSystemInitialized = false

local function initializeWeaponsSystemAssets()
	if not weaponsSystemInitialized then
		-- Enable/make visible all necessary assets
		local effectsFolder = weaponsSystemFolder.Assets.Effects
		local partNonZeroTransparencyValues = {
			["BulletHole"] = 1, ["Explosion"] = 1, ["Pellet"] = 1, ["Scorch"] = 1,
			["Bullet"] = 1, ["Plasma"] = 1, ["Railgun"] = 1,
		}
		local decalNonZeroTransparencyValues = { ["ScorchMark"] = 0.25 }
		local particleEmittersToDisable = { ["Smoke"] = true }
		local imageLabelNonZeroTransparencyValues = { ["Impact"] = 0.25 }
		for _, descendant in pairs(effectsFolder:GetDescendants()) do
			if descendant:IsA("BasePart") then
				if partNonZeroTransparencyValues[descendant.Name] ~= nil then
					descendant.Transparency = partNonZeroTransparencyValues[descendant.Name]
				else
					descendant.Transparency = 0
				end
			elseif descendant:IsA("Decal") then
				descendant.Transparency = 0
				if decalNonZeroTransparencyValues[descendant.Name] ~= nil then
					descendant.Transparency = decalNonZeroTransparencyValues[descendant.Name]
				else
					descendant.Transparency = 0
				end
			elseif descendant:IsA("ParticleEmitter") then
				descendant.Enabled = true
				if particleEmittersToDisable[descendant.Name] ~= nil then
					descendant.Enabled = false
				else
					descendant.Enabled = true
				end
			elseif descendant:IsA("ImageLabel") then
				if imageLabelNonZeroTransparencyValues[descendant.Name] ~= nil then
					descendant.ImageTransparency = imageLabelNonZeroTransparencyValues[descendant.Name]
				else
					descendant.ImageTransparency = 0
				end
			end
		end
		
		weaponsSystemInitialized = true
	end
end

if weaponsSystemFolder == nil then
	weaponsSystemFolder = curWeaponsSystemFolder:Clone()
	initializeWeaponsSystemAssets()
	weaponsSystemFolder.Parent = ReplicatedStorage
end

--selene: allow(incorrect_standard_library_use) -- TODO
script.Parent = ServerScriptService
initializeWeaponsSystemAssets()
local WeaponsSystem = require(weaponsSystemFolder.WeaponsSystem)
if not WeaponsSystem.doingSetup and not WeaponsSystem.didSetup then
	WeaponsSystem.setup()
end

local function setupClientWeaponsScript(player)
	local clientWeaponsScript = player.PlayerGui:FindFirstChild("ClientWeaponsScript")
	if clientWeaponsScript == nil then
		clientWeaponsScript = weaponsSystemFolder.ClientWeaponsScript:Clone()
		clientWeaponsScript.Parent = player.PlayerGui
	end

	local clientDefaultValuesFolder: Folder = weaponsSystemFolder.Assets.ClientDefaultValues:Clone()
	clientDefaultValuesFolder.Parent = player
end

Players.PlayerAdded:Connect(function(player)
	setupClientWeaponsScript(player)
end)

for _, player in ipairs(Players:GetPlayers()) do
	setupClientWeaponsScript(player)
end


if curWeaponsSystemFolder.Name == "WeaponsSystem" then
	curWeaponsSystemFolder:Destroy()
end