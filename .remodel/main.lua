local game = remodel.readPlaceFile("../StudioPlace/place.rbxl")

local Workspace = game.Workspace
local ReplicatedStorage = game.ReplicatedStorage
local ServerScriptService = game.ServerScriptService
local ServerStorage = game.ServerStorage
local StarterPack = game.StarterPack
local StarterPlayer = game.StarterPlayer
local StarterPlayerScripts = StarterPlayer.StarterPlayerScripts

local function handleLoops(object, folderName)
    if object.ClassName == "Folder" then
        local dir = "../src/" .. folderName .. "/" .. object.Name
        remodel.createDirAll(dir)
        for _, v in pairs(object:GetChildren()) do
            handleLoops(v, dir)
        end
    else
        local dir = "../src/" .. folderName .. "/" .. object.Parent.Name

        if object.ClassName == "LocalScript" then
            remodel.writeFile(object, dir .. object.Name .. ".client.lua", object)
        elseif object.ClassName == "Script" then
            remodel.writeFile(dir .. object.Name .. ".server.lua", object)
        elseif object.ClassName == "ModuleScript" then
            remodel.writeFile(dir .. object.Name .. ".lua", object)
        else
            remodel.writeModelFile(object, dir .. object.Name .. ".rbxmx")
        end
    end
end

for _, model in ipairs(Workspace:GetChildren()) do
    remodel.writeModelFile(model, "../src/workspace/" .. model.Name .. ".rbxmx")
end

for _, object in ipairs(ReplicatedStorage:GetChildren()) do
    handleLoops(object, "shared")
end

for _, object in ipairs(ServerScriptService:GetDescendants()) do
    handleLoops(object, "server")
end

for _, object in ipairs(ServerStorage:GetDescendants()) do
    handleLoops(object, "storage")
end

for _, object in ipairs(StarterPack:GetDescendants()) do
    handleLoops(object, "starterpack")
end

for _, object in ipairs(StarterPlayerScripts:GetDescendants()) do
    handleLoops(object, "client")
end