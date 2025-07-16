local CollectionService = game:GetService("CollectionService")
local PathfindingService = game:GetService("PathfindingService")

local waypointsOrder = {
	"GasShelf",      -- tag for shelves
	"GasCheckout",   -- tag for checkout
	"GasExit"        -- tag for exit
}

local function getTagged(name)
	return CollectionService:GetTagged(name)
end

return {
	hook = "pathing",
	priority = 0,
	execute = function(npcModel)
		local currentStep = npcModel:GetAttribute("ShoppingStep") or 1

		if currentStep > #waypointsOrder then
			currentStep = 1
		end

		local tagName = waypointsOrder[currentStep]
		local areas = getTagged(tagName)
		if #areas == 0 then return false end

		-- Pick a random destination part
		local destinationPart = areas[math.random(1, #areas)]
		local destination = destinationPart.Position

		-- Store the target part using an ObjectValue, not attribute!
		local prevTarget = npcModel:FindFirstChild("TargetPart")
		if prevTarget and prevTarget:IsA("ObjectValue") then
			prevTarget:Destroy()
		end
		local objVal = Instance.new("ObjectValue")
		objVal.Name = "TargetPart"
		objVal.Value = destinationPart
		objVal.Parent = npcModel

		-- Pathfind to this destination
		local path = PathfindingService:CreatePath({ AgentCanJump = false, AgentRadius = 2 })
		local success = pcall(function()
			path:ComputeAsync(npcModel:GetPivot().Position, destination)
		end)
		if not success or path.Status ~= Enum.PathStatus.Success then
			return false
		end

		-- Store the next step for this NPC
		npcModel:SetAttribute("ShoppingStep", currentStep + 1)

		return true, path:GetWaypoints()
	end,
}
