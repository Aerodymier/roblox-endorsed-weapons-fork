local game = remodel.readPlaceFile("../StudioPlace/place.rbxl")

local Workspace = game.Workspace
local ReplicatedStorage = game.ReplicatedStorage
local ServerScriptService = game.ServerScriptService
local ServerStorage = game.ServerStorage
local StarterPack = game.StarterPack
local StarterPlayer = game.StarterPlayer
local StarterPlayerScripts = StarterPlayer.StarterPlayerScripts

for _, model in ipairs(Workspace:GetChildren()) do
    remodel.writeModelFile(model, "../src/workspace/" .. model.Name .. ".rbxmx")
end

for _, model in ipairs(ReplicatedStorage:GetChildren()) do
    remodel.writeModelFile(model, "../src/shared/" .. model.Name .. ".rbxmx")
end

for _, model in ipairs(ServerScriptService:GetChildren()) do
    remodel.writeModelFile(model, "../src/server/" .. model.Name .. ".rbxmx")
end

for _, model in ipairs(ServerStorage:GetChildren()) do
    remodel.writeModelFile(model, "../src/storage/" .. model.Name .. ".rbxmx")
end

for _, model in ipairs(StarterPack:GetChildren()) do
    remodel.writeModelFile(model, "../src/starterpack/" .. model.Name .. ".rbxmx")
end

for _, model in ipairs(StarterPlayerScripts:GetChildren()) do
    remodel.writeModelFile(model, "../src/client/" .. model.Name .. ".rbxmx")
end