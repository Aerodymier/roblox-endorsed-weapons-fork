local ReplicatedStorage = game:GetService("ReplicatedStorage")

local playerChildAddedConnection
local replicatedStorageChildAddedConnection
local clientWeaponsScript
local weaponsSystemFolder

local function setupWeaponsSystem()
	local WeaponsSystem = require(weaponsSystemFolder.WeaponsSystem)
	if not WeaponsSystem.doingSetup and not WeaponsSystem.didSetup then
		WeaponsSystem.setup()
	end
end

local function onReplicatedStorageChildAdded(child)
	if child.Name == "WeaponsSystem" then
		setupWeaponsSystem()
		replicatedStorageChildAddedConnection:Disconnect()
	end
end

local function onPlayerChildAdded(child)
	if child.Name == "PlayerScripts" then
		clientWeaponsScript.Parent = child
		playerChildAddedConnection:Disconnect()
	end
end

if script.Parent.Name ~= "PlayerScripts" then
	clientWeaponsScript = script:Clone()
	local PlayerScripts = script.Parent.Parent:FindFirstChild("PlayerScripts")
	
	if PlayerScripts ~= nil then
		clientWeaponsScript.Parent = PlayerScripts
	else
		playerChildAddedConnection = script.Parent.Parent.ChildAdded:Connect(onPlayerChildAdded)
	end
else
	weaponsSystemFolder = ReplicatedStorage:FindFirstChild("WeaponsSystem")
	if weaponsSystemFolder ~= nil then
		setupWeaponsSystem()
	else
		replicatedStorageChildAddedConnection = ReplicatedStorage.ChildAdded:Connect(onReplicatedStorageChildAdded)
	end
end