local CollectionService = game:GetService("CollectionService")

local function ancestorHasTag(instance, tag)
	local currentInstance = instance
	while currentInstance do
		if CollectionService:HasTag(currentInstance, tag) then
			return true
		else
			currentInstance = currentInstance.Parent
		end
	end

	return false
end

return ancestorHasTag