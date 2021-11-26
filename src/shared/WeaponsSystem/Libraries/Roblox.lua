local TweenService 		= game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local RunService 		= game:GetService("RunService")
local UserInputService	= game:GetService("UserInputService")

local Roblox = {}

Roblox.Random = Random.new()
Roblox.zeroVector2 = Vector2.new()
Roblox.zeroVector3 = Vector3.new()
Roblox.identityCFrame = CFrame.new()
Roblox.upVector2 = Vector2.new(0, 1)
Roblox.upVector3 = Vector3.new(0, 1, 0)

local guidCharsText = "1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz!@#$%^&*()_+./"
local guidChars = {}
for i = 1, #guidCharsText do
	guidChars[i] = guidCharsText:sub(i, i)
end
local guidRandom = Random.new()

function Roblox.newGuid()
	local guid = ""
	for _ = 1, 10 do
		local char = guidRandom:NextInteger(1,#guidChars)
		guid = guid .. guidChars[char]
	end
	return guid
end

function Roblox.isPlaySolo()
	return RunService:IsClient() and RunService:IsServer() and RunService:IsStudio()
end

function Roblox.waitForDescendant(instance, descendantName, timeout)
	timeout = timeout or 60
	local found = instance:FindFirstChild(descendantName, true)
	if found then
		return found
	end

	if timeout < 1e6 and timeout > 0 then
		coroutine.wrap(function()
			wait(timeout)
			if not found then
				warn("Roblox.waitForDescendant(%s, %s) is taking too long")
			end
		end)()
	end

	while not found do
		local newDescendant = instance.DescendantAdded:Wait()
		if newDescendant.Name == descendantName then
			found = newDescendant
			return newDescendant
		end
	end
end

function Roblox.create(className)
	return function(props)
		local instance = Instance.new(className)
		for key, val in pairs(props) do
			if key ~= "Parent" then
				instance[key] = val
			end
		end
		instance.Parent = props.Parent
		return instance
	end
end

function Roblox.weldModel(model)
	local rootPart = model.PrimaryPart
	for _, part in pairs(model:GetDescendants()) do
		if part:IsA("BasePart") and part ~= rootPart then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = rootPart
			weld.Part1 = part
			weld.Parent = part
		end
	end
end

function Roblox.setNetworkOwner(model, owner)
	if not model then warn("Cannot setNetworkOwner on nil model") return end
	for _, part in pairs(model:GetDescendants()) do
		if part:IsA("BasePart") and not part.Anchored then
			part:SetNetworkOwner(owner)
		end
	end
end

function Roblox.createMotor6D(root, child)
	local motor = Instance.new("Motor6D")
	motor.Part0 = root
	motor.Part1 = child

	motor.C0 = root.CFrame:toObjectSpace(child.CFrame)
	motor.C1 = CFrame.new()

	motor.Parent = root
	return motor
end

function Roblox.getTotalMass(part)
	local allConnected = part:GetConnectedParts(true)
	local total = 0
	for _, v in pairs(allConnected) do
		total = total + v:GetMass()
	end
	return total
end

function Roblox.waitForTween(tweenInstance, tweenInfo, tweenProps)
	local tween = TweenService:Create(tweenInstance, tweenInfo, tweenProps)
	tween:Play()
	tween.Completed:wait()
end

function Roblox.tween(tweenInstance, tweenInfo, tweenProps)
	local tween = TweenService:Create(tweenInstance, tweenInfo, tweenProps)
	tween:Play()
end

function Roblox.fadeAway(gui, duration, level)
	duration = duration or 0.5
	level = level or 0

	local tweenInfo = TweenInfo.new(duration)
	local tweenProps = { BackgroundTransparency = 1 }

	if gui:IsA("TextButton") or gui:IsA("TextLabel") or gui:IsA("TextBox") then
		tweenProps.TextTransparency = 1
		tweenProps.TextStrokeTransparency = 1
	elseif gui:IsA("ImageLabel") or gui:IsA("ImageButton") then
		tweenProps.ImageTransparency = 1
	else
		return
	end

	for _, v in pairs(gui:GetChildren()) do
		Roblox.fadeAway(v, duration, level + 1)
	end


	if level == 0 then
		coroutine.wrap(function()
			Roblox.waitForTween(gui, tweenInfo, tweenProps)
			gui:Destroy()
		end)()
	else
		Roblox.tween(gui, tweenInfo, tweenProps)
	end
end

function Roblox.setModelAnchored(model, anchored)
	for _, part in pairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = anchored
		end
	end
end

function Roblox.setModelLocalVisible(model, visible)
	for _, part in pairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.LocalTransparencyModifier = visible and 0 or 1
		elseif part:IsA("SurfaceGui") then
			part.Enabled = visible
		elseif part:IsA("Decal") then
			part.Transparency = visible and 0 or 1
		end
	end
end

function Roblox.forAllTagged(tagName, enterFunc, exitFunc)
	for _, obj in pairs(CollectionService:GetTagged(tagName)) do
		if enterFunc then
			enterFunc(obj, tagName)
		end
	end
	if enterFunc then
		CollectionService:GetInstanceAddedSignal(tagName):Connect(function(obj) enterFunc(obj, tagName) end)
	end
	if exitFunc then
		CollectionService:GetInstanceRemovedSignal(tagName):Connect(function(obj) exitFunc(obj, tagName) end)
	end
end

function Roblox.getHumanoidFromCharacterPart(part)
	local currentNode = part
	while currentNode do
		local humanoid = currentNode:FindFirstChildOfClass("Humanoid")
		if humanoid then return humanoid end
		currentNode = currentNode.Parent
	end
	return nil
end

local addEsEndings = {
	s = true,
	sh = true,
	ch = true,
	x = true,
	z = true
}
local vowels = {
	a = true,
	e = true,
	i = true,
	o = true,
	u = true
}
function Roblox.formatPlural(num, name, wordOnly)
	if num ~= 1 then
		local lastTwo = name:sub(-2):lower()
		local lastOne = name:sub(-1):lower()

		local suffix = "s"
		if addEsEndings[lastTwo] or addEsEndings[lastOne] then
			suffix = "es"
		elseif lastOne == "o" and #lastTwo == 2 then
			local secondToLast = lastTwo:sub(1, 1)
			if not vowels[secondToLast] then
				suffix = "es"
			end
		end
		name = name .. suffix
	end
	if not wordOnly then
		return ("%s %s"):format(Roblox.formatInteger(num), name)
	else
		return name
	end
end

function Roblox.formatNumberTight(number)
	local order = math.log10(number)
	if order >= 3 and order < 6 then
		return ("%.1fK"):format(number / (10^3))
	end
	if order >= 6 and order < 9 then
		return ("%.1fM"):format(number / (10^6))
	end
	if order >= 9 then
		return ("%.1fB"):format(number / (10^9))
	end

	return tostring(math.floor(number + 0.5))
end

function Roblox.formatInteger(amount)
	amount = math.floor(amount + 0.5)
	local formatted = amount
	local numMatches
	repeat
		formatted, numMatches = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
	until numMatches == 0
	return formatted
end

function Roblox.round(val, decimal)
	if decimal then
		return math.floor((val * 10 ^ decimal) + 0.5) / (10 ^ decimal)
	else
		return math.floor(val + 0.5)
	end
end

function Roblox.formatNumber(number)
	local result, integral, fractional

	integral, fractional = math.modf(number)
	result = Roblox.formatInteger(integral)

	if fractional ~= 0 then
		result = result .. "." .. string.sub(tostring(math.abs(fractional)),3)
	end
	if number < 0 then
		result = "-" .. result
	end

	return result
end

function Roblox.isPointInsidePart(point, part)
	local localPos = part.CFrame:pointToObjectSpace(point)
	return math.abs(localPos.X) <= part.Size.X * 0.5 and math.abs(localPos.Y) <= part.Size.Y * 0.5 and math.abs(localPos.Z) <= part.Size.Z * 0.5
end

function Roblox.rayPlaneIntersect(ray, pointOnPlane, planeNormal)
	local Vd = planeNormal:Dot(ray.Direction)
	if Vd == 0 then -- parallel, no intersection
		return nil
	end

	local V0 = planeNormal:Dot(pointOnPlane - ray.Origin)
	local t = V0 / Vd
	if t < 0 then --plane is behind ray origin, and thus there is no intersection
		return nil
	end

	return ray.Origin + ray.Direction * t
end

function Roblox.debugPrint(t, level)
	level = level or 0
	local tabs = string.rep("\t", level)
	if typeof(t) == "table" then
		for key, val in pairs(t) do
			print(tabs, key, "=", val)
			if typeof(val) == "table" then
				Roblox.debugPrint(val, level + 1)
			end
		end
	end
end

local function findInstanceImpl(root, path, getChildFunc)
	local currentInstance = root

	while true do
		local nextChildName
		local nextSeparator = path:find("%.")
		if not nextSeparator then
			nextChildName = path
		else
			nextChildName = path:sub(1, nextSeparator - 1)
			path = path:sub(nextSeparator + 1)
		end

		local child = getChildFunc(currentInstance, nextChildName)
		if child then
			currentInstance = child
		else
			return nil
		end
	end
end

local function findFirstChildImpl(parent, childName)
	return parent:FindFirstChild(childName)
end
local function waitForChildImpl(parent, childName)
	return parent:WaitForChild(childName)
end

function Roblox.findInstance(root, path)
	return findInstanceImpl(root, path, findFirstChildImpl)
end

function Roblox.waitForInstance(root, path)
	return findInstanceImpl(root, path, waitForChildImpl)
end

function Roblox.penetrateCast(ray, ignoreList)
	debug.profilebegin("penetrateCast")
	local tries = 0
	local hitPart, hitPoint, hitNormal, hitMaterial = nil, ray.Origin + ray.Direction, Vector3.new(0, 1, 0), Enum.Material.Air
	while tries < 50 do
		tries = tries + 1
		hitPart, hitPoint, hitNormal, hitMaterial = workspace:FindPartOnRayWithIgnoreList(ray, ignoreList, false, true)
		if hitPart and (not hitPart.CanCollide or CollectionService:HasTag(hitPart, "DroppedItemPart") or CollectionService:HasTag(hitPart, "Hidden")) and hitPart.Parent:FindFirstChildOfClass("Humanoid") == nil then
			table.insert(ignoreList, hitPart)
		else
			break
		end
	end
	debug.profileend()
	return hitPart, hitPoint, hitNormal, hitMaterial
end

function Roblox.posInGuiObject(pos, guiObject)
	local guiMin = guiObject.AbsolutePosition
	local guiMax = guiMin + guiObject.AbsoluteSize
	return pos.X >= guiMin.X and pos.X <= guiMax.X and pos.Y >= guiMin.Y and pos.Y <= guiMax.Y
end

function Roblox.getUTCTime()
	local dateInfo = os.date("!*t")
	return string.format("%04d-%02d-%02d %02d:%02d:%02d", dateInfo.year, dateInfo.month, dateInfo.day, dateInfo.hour, dateInfo.min, dateInfo.sec)
end

function Roblox.getUTCTimestamp()
	return os.time(os.date("!*t"))
end

local DURATION_TOKENS = {
	{ "years",   "y",  31536000 },
	{ "months",  "mo", 2592000 },
	{ "weeks",   "w",  604800 },
	{ "days",    "d",  86400 },
	{ "hours",   "h",  3600 },
	{ "minutes", "m",  60 },
	{ "seconds", "s",  1 },
}
function Roblox.parseDurationInSeconds(inputStr)
	local tokensFound = {}
	local totalDurationSeconds = 0
	for _, tokenInfo in pairs(DURATION_TOKENS) do
		local numFound = string.match(inputStr, "(%d+)" .. tokenInfo[2])
		if numFound then
			local num = tonumber(numFound) or 0
			if num > 0 then
				table.insert(tokensFound, string.format("%d %s", num, tokenInfo[1]))
			end
			totalDurationSeconds = totalDurationSeconds + (num * tokenInfo[3])
		end
	end

	local outputStr = table.concat(tokensFound, ", ")
	return totalDurationSeconds, outputStr
end

local random = Random.new()
function Roblox.chooseWeighted(choiceTable)
    local sum = 0
    for _, weight in pairs(choiceTable) do
        sum = sum + weight
    end

    local roll = random:NextNumber(0, 1)
    local choiceSum = 0
    for choiceName, weight in pairs(choiceTable) do
        local chance = weight / sum
        if roll >= choiceSum and roll < choiceSum + chance then
            return choiceName
        else
            choiceSum = choiceSum + chance
        end
    end

    return nil
end

function Roblox.hasMatchingTag(instance, tagPattern)
	for _, tagName in pairs(CollectionService:GetTags(instance)) do
		if tagName:match(tagPattern) ~= nil then
			return true
		end
	end
	return false
end

local highlightTweens = setmetatable({}, { __mode = 'k' })
function Roblox.showHighlight(instance, show)
	local highlightInstance = instance:FindFirstChild("Highlight")
	if not highlightInstance or not highlightInstance:IsA("ImageLabel") then
		return
	end

	local existingTween = highlightTweens[instance]
	if existingTween then
		if show then
			return
		else
			existingTween:Cancel()
			highlightTweens[instance] = nil
			highlightInstance.ImageTransparency = 1
		end
	else
		if not show then
			return
		else
			coroutine.wrap(function()
				highlightInstance.ImageTransparency = 1
				local newTween = TweenService:Create(highlightInstance, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut, 0, true), { ImageTransparency = 0 })
				highlightTweens[instance] = newTween
				while highlightTweens[instance] == newTween do
					newTween:Play()
					newTween.Completed:Wait()
				end
			end)()
		end
	end
end

function Roblox.getClickVerb(capitalize)
	local verb = "Click"
	if UserInputService.TouchEnabled then
		verb = "Tap"
	end

	if not capitalize then
		verb = verb:lower()
	end
	return verb
end

function Roblox.computeLaunchAngle(relativePoint, launchVelocity)
	local dx, dy = -relativePoint.Z, relativePoint.Y

	local g = workspace.Gravity
	local invRoot = (launchVelocity ^ 4) - (g * ((g * dx * dx) + (2 * dy * launchVelocity * launchVelocity)))
	if invRoot <= 0 then
		return math.pi / 4
	end

	local root = math.sqrt(invRoot)
	local angle1 = math.atan(((launchVelocity * launchVelocity) + root) / (g * dx))
	local angle2 = math.atan(((launchVelocity * launchVelocity) - root) / (g * dx))

	local chosenAngle = math.min(angle1, angle2)

	return chosenAngle
end

function Roblox.getClosestPointOnLine(line0, line1, point, doClamp)
	local lineVec = line1 - line0
	local pointFromLine0 = point - line0

	local dotProduct = lineVec:Dot(pointFromLine0)
	local t = dotProduct / (lineVec.Magnitude ^ 2)
	if doClamp ~= false then
		t = math.clamp(t, 0, 1)
	end
	local pointOnLine = line0:Lerp(line1, t)
	return pointOnLine, t, (point - pointOnLine).Magnitude
end

function Roblox.getClosestPointOnLines(referencePoint, lines)
	local closestPoint, closestDist, closestLine, closestT = nil, math.huge, nil, 0
	for i = 1, #lines do
		local lineA, lineB = lines[i][1], lines[i][2]

		local point, t, dist = Roblox.getClosestPointOnLine(lineA, lineB, referencePoint)
		if dist < closestDist then
			closestPoint = point
			closestDist = dist
			closestLine = i
			closestT = t
		end
	end

	return closestPoint, closestDist, closestLine, closestT
end

function Roblox.getPointInFrontOnLines(referencePoint, forwardOffset, lines)
	local closestPoint, _, closestLine, closestT = Roblox.getClosestPointOnLines(referencePoint, lines)
	if closestPoint then
		local pointOffset = closestPoint
		local offsetBudget = forwardOffset

		if closestLine == 1 and closestT == 0 then
			local beforeDist = (lines[1][1] - Roblox.getClosestPointOnLine(lines[1][1], lines[1][2], referencePoint, false)).Magnitude
			offsetBudget = offsetBudget - beforeDist
		end

		local lineDir = Vector3.new(0, 0, 0)
		while offsetBudget > 0 and closestLine <= #lines do
			local lineA, lineB = lines[closestLine][1], lines[closestLine][2]
			local lineVec = lineB - lineA
			local lineLength = lineVec.Magnitude
			local pointDistAlongLine = (pointOffset - lineA).Magnitude
			local distLeftOnLine = lineLength - pointDistAlongLine
			lineDir = lineVec.Unit

			if offsetBudget > distLeftOnLine then
				offsetBudget = offsetBudget - distLeftOnLine
				pointOffset = lineB
				closestLine = closestLine + 1
			else
				break
			end
		end
		pointOffset = pointOffset + lineDir * offsetBudget

		return pointOffset
	end
	return closestPoint
end

function Roblox.applySpread(unspreadDir, randomGenerator, minSpread, maxSpread)
	local spreadRotation = randomGenerator:NextNumber(-math.pi, math.pi)
	local spreadOffset = randomGenerator:NextNumber(minSpread, maxSpread)
	local spreadTransform = CFrame.fromAxisAngle(Vector3.new(math.cos(spreadRotation), math.sin(spreadRotation), 0), spreadOffset)
	local unspreadCFrame = CFrame.new(Vector3.new(), unspreadDir)
	return (unspreadCFrame * spreadTransform).LookVector
end

return Roblox
