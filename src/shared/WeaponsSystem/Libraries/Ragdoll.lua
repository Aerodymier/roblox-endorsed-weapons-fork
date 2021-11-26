local RunService = game:GetService("RunService")

local JOINT_INFO = {
	LeftShoulder = {
		Limits = { Cone = 70, Twist = 30 },
		Offset = Vector3.new(0, -0.25, 0),
		Rotation = CFrame.Angles(0, 0, math.rad(45))
	},
	LeftElbow = {
		Limits = { Lower = 0, Upper = 160 }
	},
	LeftWrist = {
		Limits = { Cone = 90, Twist = 90 }
	},
	RightShoulder = {
		Limits = { Cone = 70, Twist = 30 },
		Offset = Vector3.new(0, -0.25, 0),
		Rotation = CFrame.Angles(0, 0, math.rad(-45))
	},
	RightElbow = {
		Limits = { Lower = 0, Upper = 160 }
	},
	RightWrist = {
		Limits = { Cone = 90, Twist = 90 }
	},

	Waist = {
		Limits = { Lower = -45, Upper = 30 }
	},
	Neck = {
		Limits = { Cone = 20, Twist = 20 }
	},

	LeftHip = {
		Limits = { Cone = 40, Twist = 2.5 },
		Rotation = CFrame.Angles(math.rad(-40), 0, math.rad(35)),
	},
	LeftKnee = {
		Limits = { Lower = 0, Upper = 120 }
	},
	LeftAnkle = {
		Limits = { Cone = 10, Twist = 0.5 }
	},
	RightHip = {
		Limits = { Cone = 40, Twist = 2.5 },
		Rotation = CFrame.Angles(math.rad(-40), 0, math.rad(-35))
	},
	RightKnee = {
		Limits = { Lower = 0, Upper = 120 }
	},
	RightAnkle = {
		Limits = { Cone = 10, Twist = 0.5 }
	}
}

local GROUPS = {
	UpperBody = {
		"Waist",
		"Neck",
		"LeftShoulder",
		"RightShoulder",
		"LeftElbow",
		"RightElbow",
		"LeftWrist",
		"RightWrist"
	},
	LowerBody = {
		"LeftHip",
		"RightHip",
		"LeftKnee",
		"RightKnee",
		"LeftAnkle",
		"RightAnkle"
	},
	LeftArm = {
		"LeftShoulder",
		"LeftElbow",
		"LeftWrist",
	},
	RightArm = {
		"RightShoulder",
		"RightElbow",
		"RightWrist"
	},
	LeftLeg = {
		"LeftHip",
		"LeftKnee",
		"LeftAnkle"
	},
	RightLeg = {
		"RightHip",
		"RightKnee",
		"RightAnkle"
	},
}

local Ragdoll = {}
Ragdoll.__index = Ragdoll

function Ragdoll.new(character)
	local self = setmetatable({}, Ragdoll)
	self.character = character
	self.humanoid = character:WaitForChild("Humanoid")

	self.joints = {}
	for jointName, info in pairs(JOINT_INFO) do
		self.joints[jointName] = self:setupJoint(jointName, info)
	end

	return self
end

function Ragdoll:setupJoint(jointName, info)
	if self.joints[jointName] then
		return self.joints[jointName]
	end

	local constraintName = jointName .. "Constraint"
	local rigAttachmentName = jointName .. "RigAttachment"
	local existingConstraint = self.character:FindFirstChild(constraintName, true)
	local existingMotor = self.character:FindFirstChild(jointName, true)
	if not existingMotor then
		return nil
	end

	if existingConstraint or RunService:IsClient() then
		existingConstraint = self.character:WaitForChild(constraintName)
		return {
			constraint = existingConstraint,
			motor = existingMotor,
			ragdolled = existingMotor.Part1 ~= nil
		}
	else
		local constraintType = "HingeConstraint"
		if info.Limits and info.Limits.Cone and info.Limits.Twist then
			constraintType = "BallSocketConstraint"
		end

		local constraint = Instance.new(constraintType)
		constraint.Name = constraintName
		constraint.Enabled = false
		constraint.Attachment0 = existingMotor.Part0:FindFirstChild(rigAttachmentName)
		constraint.Attachment1 = existingMotor.Part1:FindFirstChild(rigAttachmentName)
		constraint.LimitsEnabled = info.Limits ~= nil

		if info.Limits and info.Limits.Cone and info.Limits.Twist then
			constraint.UpperAngle = info.Limits.Cone
			constraint.TwistLimitsEnabled = true
			constraint.TwistLowerAngle = -info.Limits.Twist
			constraint.TwistUpperAngle = info.Limits.Twist
		elseif info.Limits and info.Limits.Lower and info.Limits.Upper then
			constraint.LowerAngle = info.Limits.Lower
			constraint.UpperAngle = info.Limits.Upper
		end

		constraint.Parent = existingMotor.Parent

		return {
			constraint = constraint,
			motor = existingMotor,
			ragdolled = false
		}
	end
end

function Ragdoll:setJointRagdolled(jointName, ragdolled)
	local joint = self.joints[jointName]
	if not joint then return end

	joint.constraint.Enabled = ragdolled
	if joint.motor and joint.motor:IsA("Motor6D") then
		if ragdolled then
			joint.motor.Part1 = nil
		else
			joint.motor.Part1 = joint.motor.Parent
		end
	end
end

function Ragdoll:setGroupRagdolled(groupName, ragdolled)
	local groupJoints = GROUPS[groupName]
	assert(groupJoints, string.format("%s is not a valid ragdoll group", tostring(groupName)))

	for _, jointName in pairs(groupJoints) do
		self:setJointRagdolled(jointName, ragdolled)
	end
end

function Ragdoll:setRagdolled(ragdolled, whitelist)
	for jointName in pairs(self.joints) do
		if not whitelist or whitelist[jointName] then
			self:setJointRagdolled(jointName, ragdolled)
		end
	end
end

function Ragdoll:destroy()
	self:setRagdolled(false)
	for _, joint in pairs(self.joints) do
		if joint.constraint then
			joint.constraint:Destroy()
		end
	end
	self.joints = {}
end

return Ragdoll
