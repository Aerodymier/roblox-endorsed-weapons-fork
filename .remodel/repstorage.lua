local game = remodel.readPlaceFile("../PlaceBuild/output.rbxlx")

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
        for _, v in ipairs(object:GetChildren()) do
            handleLoops(v, dir)
        end
    else
        local dir = "../src/" .. folderName .. "/" .. object.Name

        if object.ClassName ~= "LocalScript" and object.ClassName ~= "Script" and object.ClassName ~= "ModuleScript" then
            remodel.writeModelFile(object, dir .. ".rbxmx")
        end
    end
end

for _, object in ipairs(ReplicatedStorage:GetChildren()) do
    handleLoops(object, "shared")
end