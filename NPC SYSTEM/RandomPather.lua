-- RandomPather, both an example of a cog and the standard functionality.

local CollectionService = game:GetService("CollectionService")
local PathfindingService = game:GetService("PathfindingService")

local Areas = CollectionService:GetTagged("Justice:Pathfindable")

-- We expose this bindable here in the cog so that other scripts can modify the map and we can
-- recalculate valid zones, without constantly refetching them every time we want to path
local RecalculateArea = script.RecalculateArea do
	RecalculateArea.OnInvoke = function()
		Areas = CollectionService:GetTagged("Justice:Pathfindable")
	end
end

-- For performance reasons, we cache every path created for each NPC
local Paths = {}

local function getRandomLocation()
	local part = Areas[math.random(1, #Areas)] :: BasePart
	
	return (part.CFrame * CFrame.new(
		math.random(-part.Size.X / 2, part.Size.X / 2),
		math.random(-part.Size.Y / 2, part.Size.Y / 2),
		math.random(-part.Size.Z / 2, part.Size.Z / 2)
	)).Position
end

return {
	hook = "pathing",
	priority = 0, -- higher priorities run first
	execute = function(npcModel: Model)
		if not Paths[npcModel] then
			Paths[npcModel] = PathfindingService:CreatePath({ AgentCanJump = false, AgentRadius = 5, Costs = { ["Justice:Deadzone"] = math.huge } })
		end
		
		local path = Paths[npcModel]
		
		local ok = pcall(function()
			path:ComputeAsync(npcModel:GetPivot().Position, getRandomLocation())
		end)
		
		if not ok or path.Status ~= Enum.PathStatus.Success then
			warn(`Could not compute random path: {path.Status}`)
			return false
		end
		
		return true, path:GetWaypoints()
	end,
}