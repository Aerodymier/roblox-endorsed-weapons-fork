local RunService = game:GetService("RunService")

local MIN_HORZ_SPEED = 0.01 --The minimum X and Z velocity for a physical-launch parabola to be considered vertical, helps avoid numerical instability
local DEFAULT_NUM_SAMPLES = RunService:IsServer() and 32 or 32
local DEFAULT_NORMAL = Vector3.new(0, 1, 0)
local ROT_OFFSET = {
	[0] = CFrame.Angles(0, math.rad(90), 0) * CFrame.Angles(math.rad(90), 0, 0),
	[1] = CFrame.Angles(0, math.rad(-90), 0) * CFrame.Angles(math.rad(90), 0, 0)
}
local UP_VECTOR = Vector3.new(0, 1, 0)
local ONE_THIRD, TWO_THIRDS = 1/3, 2/3

local Parabola = {}
Parabola.__index = Parabola

function Parabola.new(a, b, c, x0, x1)
	local self = setmetatable({}, Parabola)

	self.referenceFrame = CFrame.new()

	self.a = a or 1
	self.b = b or 1
	self.c = c or 0

	self.x0 = x0 or 0
	self.x1 = x1 or 10

	self.velocity = Vector2.new()
	self.gravity = 0

	self.numSamples = DEFAULT_NUM_SAMPLES

	return self
end

function Parabola:setPhysicsLaunch(startPoint, velocity, endpointY, gravity)
	gravity = gravity or -workspace.Gravity

	local flatVelocity = velocity * Vector3.new(1, 0, 1)
	if flatVelocity.Magnitude > MIN_HORZ_SPEED then
		self.referenceFrame = CFrame.new(startPoint, startPoint + flatVelocity)
	else
		self.referenceFrame = CFrame.new(startPoint)
	end
	local relativeVelocity = self.referenceFrame:vectorToObjectSpace(velocity)
	local xVelocity, yVelocity = math.max(MIN_HORZ_SPEED, -relativeVelocity.Z), relativeVelocity.Y
	self.a = (0.5 * gravity) * (1 / (xVelocity ^ 2))
	self.b = yVelocity / xVelocity
	self.c = 0

	self.velocity = Vector2.new(xVelocity, yVelocity)
	self.gravity = gravity

	if math.abs(gravity) > 1e-3 then
		self.x0 = 0

		if endpointY and startPoint.Y - endpointY > 0 then
			--y = ax^2 + bx + c
			--0 = ax^2 + bx - y
			--x = (-b +- sqrt(b^2 - 4ac)) / 2a

			local a, b, c = self.a, self.b, startPoint.Y - endpointY
			local det = math.sqrt(b^2 - 4 * a * c)
			local s1, s2 = (-b + det) / (2 * a), (-b - det) / (2 * a)

			self.x1 = math.max(s1, s2)
		else
			self.x1 = math.abs(2 * xVelocity * yVelocity) / math.abs(gravity)
		end
	else
		self.x0 = 0
		self.x1 = 100
	end
end

function Parabola:setNumSamples(numSamples)
	self.numSamples = numSamples
end

function Parabola:setDomain(x0, x1)
	self.x0 = x0
	self.x1 = x1
end

function Parabola:samplePoint(t)
	local a, b, c = self.a, self.b, self.c
	local x0, x1 = self.x0, self.x1
	local x = x0 + (t * (x1 - x0))
	local y = (a * x * x) + (b * x) + c
	return self.referenceFrame:pointToWorldSpace(Vector3.new(0, y, -x))
end

function Parabola:sampleSlope(t)
	local a, b = self.a, self.b
	local x0, x1 = self.x0, self.x1
	local x = x0 + (t * (x1 - x0))
	local y = (2 * a * x) + b
	return y
end

function Parabola:sampleVelocity(t)
	local x0, x1 = self.x0, self.x1
	local x = x0 + (t * (x1 - x0))
	local xVelocity = self.velocity.X
	local xT = x / xVelocity
	local yVelocity = self.velocity.Y + (self.gravity * xT)
	return self.referenceFrame:vectorToWorldSpace(Vector3.new(0, yVelocity, -xVelocity))
end

function Parabola:_penetrateCast(ray, ignoreList)
	debug.profilebegin("penetrateCast")
	local tries = 0
	local hitPart, hitPoint, hitNormal, hitMaterial = nil, ray.Origin + ray.Direction, UP_VECTOR, Enum.Material.Air
	while tries < 50 do
		tries = tries + 1
		hitPart, hitPoint, hitNormal, hitMaterial = workspace:FindPartOnRayWithIgnoreList(ray, ignoreList, false, true)
		if hitPart and not hitPart.CanCollide and hitPart.Parent:FindFirstChildOfClass("Humanoid") == nil then
			table.insert(ignoreList, hitPart)
		else
			break
		end
	end
	debug.profileend()
	return hitPart, hitPoint, hitNormal, hitMaterial
end

function Parabola:_findPart(funcName, list)
	list = list or {}

	local numSamples = self.numSamples
	local hitPart, hitPoint, hitNormal, hitMaterial, hitT = nil, self.referenceFrame.p, DEFAULT_NORMAL, Enum.Material.Air, 0

	local func = funcName ~= "penetrateCast" and workspace[funcName] or Parabola._penetrateCast

	for i = 1, numSamples do
		local t0 = (i - 1) / numSamples
		local t1 = i / numSamples

		local p0 = self:samplePoint(t0)
		local p1 = self:samplePoint(t1)
		local ray = Ray.new(p0, p1 - p0)

		hitPart, hitPoint, hitNormal, hitMaterial = func(workspace, ray, list)
		if hitPart then
			local hitX = -self.referenceFrame:pointToObjectSpace(hitPoint).Z

			hitT = ((hitX - self.x0) / (self.x1 - self.x0))
			break
		end
	end
	if not hitPart then
		hitT = 1
	end
	return hitPart, hitPoint, hitNormal, hitMaterial, hitT
end

function Parabola:findPart(ignoreList)
	return self:_findPart("penetrateCast", ignoreList)
end
function Parabola:findPartWithWhitelist(whitelist)
	return self:_findPart("FindPartOnRayWithWhitelist", whitelist)
end

function Parabola:findSpheresHit(sphereTable, radius)

end

function Parabola:_setBeamControlPoint(beam, attachment, idx, pos, refFrame)
	local attachmentPos = attachment.WorldPosition
	local vecFromAttachment = pos - attachmentPos
	local curveSize = vecFromAttachment.Magnitude

	attachment.CFrame = refFrame:toObjectSpace(CFrame.new(attachmentPos, pos) * ROT_OFFSET[idx])
	if idx == 0 then
		beam.CurveSize0 = curveSize
	else
		beam.CurveSize1 = curveSize
	end
end

function Parabola:renderToBeam(beam)
	local att0, att1 = beam.Attachment0, beam.Attachment1
	--assert(att0 and att1 and att0.Parent and att0.Parent:IsA("BasePart") and att1.Parent and att1.Parent:IsA("BasePart"), "Beam must have valid attachments that are in a BasePart")

	if not att0.Parent or not att1.Parent then
		return
	end

	local root0, root1 = att0.Parent.CFrame, att1.Parent.CFrame

	local referenceFrame = self.referenceFrame

	local x0, x1 = self.x0, self.x1
	local domain = x1 - x0
	local halfDomain = domain * 0.5
	local p0 = self:samplePoint(0)
	local p1 = self:samplePoint(1)
	local a, b, c = self.a, self.b, self.c
	local x = x0 + (0 * (x1 - x0))
	local cY = ((a * x * x) + (b * x) + c) + self:sampleSlope(0) * halfDomain
	c = referenceFrame:pointToWorldSpace(Vector3.new(0, cY, -(x0 + x1) / 2))
	local c0 = TWO_THIRDS * c + ONE_THIRD * p0
	local c1 = TWO_THIRDS * c + ONE_THIRD * p1

	att0.Position = root0:pointToObjectSpace(p0)
	att1.Position = root1:pointToObjectSpace(p1)

	self:_setBeamControlPoint(beam, att0, 0, c0, root0)
	self:_setBeamControlPoint(beam, att1, 1, c1, root1)
end

return Parabola
