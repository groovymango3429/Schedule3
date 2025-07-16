-- Justice Build 6
-- Rewritten from the ground up with modern APIs.
-- Back to being awesome as heck.

local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local InsertService = game:GetService("InsertService")
local PhysicsService = game:GetService("PhysicsService")
local RunService = game:GetService("RunService")

local RbxScriptSignal = require(script.Packages.RbxScriptSignal)
local StateMachine = require(script.Packages.StateMachine)

local Assets = require(script.Assets)

local Configuration = script.Configuration:GetAttributes()
local Templates = script.Templates

local Cogs = {} do
	for _, scr in script.Cogs:GetChildren() do
		local cog = require(scr)
		
		if not Cogs[cog.hook] then
			Cogs[cog.hook] = {}
		end
		
		table.insert(Cogs[cog.hook], cog)
	end
	
	for _, hooks in Cogs do
		table.sort(hooks, function(a, b)
			return a.priority < b.priority
		end)
	end
end

local DEBUG = RunService:IsStudio() and Configuration.Debug

-- symbol to represent an event timing out
local EVENT_TIMEOUT = newproxy()

local function runCogs(hook: string, ...): (boolean, nil)
	if not Cogs[hook] then return false end
	
	-- we want priority correctness here so ipairs it is
	for _, h in ipairs(Cogs[hook]) do
		local ok, successOrError, result = pcall(h.execute, ...)
		if ok and successOrError then
			return true, result
		elseif not ok then
			warn(`Cog for {hook} failed: {successOrError}`)
		end
	end
	
	return false
end

local function waitUntilTimeout(event: RBXScriptSignal, timeout: number)
	local signal = RbxScriptSignal.CreateSignal()
	
	local connection: RBXScriptConnection
	connection = event:Connect(function(...)
		connection:Disconnect()
		signal:Fire(...)
	end)
	
	task.delay(timeout, function()
		if connection ~= nil then
			connection:Disconnect()
			signal:Fire(EVENT_TIMEOUT)
		end
	end)
	
	return signal:Wait()
end

local function startStateMachine(model: Model)
	local brain = StateMachine.new({
		states = { "Idling", "Routing", "Wandering" },
		transitions = {
			-- when the NPC should start routing or it gets stuck
			{
				name = "CalculateRoute",
				from = { "Idling", "Wandering" },
				to = "Routing"
			},
			-- when a route has been calculated
			{
				name = "ExecuteRoute",
				from = "Routing",
				to = "Wandering"
			},
			-- when the NPC should return to idling
			{
				name = "Idle",
				from = { "Wandering", "Routing" },
				to = "Idling"
			}
		},
		initialState = "Idling"
	})
	
	local npcModel = model -- removes the typing to reduce warnings :3
	local markerColor = BrickColor.Random()
	
	local currentPath = nil
	
	if DEBUG then
		brain:Hook("__all", function(_old, new)
			npcModel.Head.Debugger.State.Text = `State: {new}`
			npcModel.Head.Debugger.Timeout.Visible = new == "Idling"
		end)
	end
	
	local function start()
		local timeout = math.random(0, Configuration.MaxDawdlingTime)
		
		if DEBUG then
			npcModel.Head.Debugger.Timeout.Text = `Timed out for {timeout}`
		end
		
		task.delay(timeout, function()
			brain:Transition("Routing")
		end)
	end
	
	brain:Hook("__start", start)
	brain:Hook("Idle", start)
	
	brain:Hook("CalculateRoute", function()
		-- these hooks are for during the state transition, so we spawn a thread as to
		-- not interrupt said transition.
		task.defer(function()
			local success, path = runCogs("pathing", npcModel)
			
			if not success then
				warn("Failed to calculate a path for NPC, returning to idle state")
				brain:Transition("Idling")
				return
			end
			
			currentPath = path
			
			brain:Transition("Wandering")
		end)
	end)
	
	brain:Hook("ExecuteRoute", function()
		-- same reason as above
		task.defer(function()
			-- ironically the state machine has no state so we have to use an object from
			-- outside the transition, but that's okay.
			
			local markers = {}
			
			if DEBUG then
				for _, waypoint in currentPath do
					local marker = Instance.new("Part")
					marker.Shape = "Ball"
					marker.Material = "Neon"
					marker.BrickColor = markerColor
					marker.Size = Vector3.new(0.6, 0.6, 0.6)
					marker.Position = waypoint.Position
					marker.Anchored = true
					marker.CanCollide = false
					marker.Parent = game.Workspace
					table.insert(markers, marker)
				end
			end
			
			for i, waypoint in currentPath do
				npcModel.Humanoid:MoveTo(waypoint.Position)
				
				if waitUntilTimeout(npcModel.Humanoid.MoveToFinished, Configuration.StuckTimeout) == EVENT_TIMEOUT then
					warn("Timed out trying to reach waypoint, stopping")
					
					for _, marker in markers do
						marker:Destroy()
					end
					
					brain:Transition("Idling")
					break
				end
				
				Debris:AddItem(markers[i], 0)
			end
			
			brain:Transition("Idling")
		end)
	end)
	
	brain:Start()
end

local function getAsset<D>(tbl: { [D | "all"]: any }, discriminator: D): any
	local assetTable = tbl[discriminator]
	local all = tbl["all" :: "all"] -- luau is such a funny language
	
	if assetTable and #assetTable > 0 then
		local t = {}
		
		for _, v in assetTable do table.insert(t, v) end
		for _, v in all do table.insert(t, v) end
		
		assetTable = t
	else
		assetTable =  all
	end
	
	return assetTable[math.random(1, #assetTable)]
end

PhysicsService:RegisterCollisionGroup("Justice:NPC")
PhysicsService:RegisterCollisionGroup(Configuration.PlayerCollisionGroup)

if not Configuration.NPCsCollideWithNPCs then
	PhysicsService:CollisionGroupSetCollidable("Justice:NPC", "Justice:NPC", false)
end

if not Configuration.NPCsCollideWithPlayers then
	PhysicsService:CollisionGroupSetCollidable("Justice:NPC", Configuration.PlayerCollisionGroup, false)
end

for i = 1, Configuration.NPCCount do
	local model = Templates[Configuration.Rig]:Clone()
	
	if DEBUG then
		local debugger = Templates.Debugger:Clone()
		debugger.Parent = model.Head
	end
	
	local discriminator = Assets.discriminators[math.random(1, #Assets.discriminators)]	
	
	local function asset(tbl)
		return getAsset(tbl, discriminator)
	end
	
	local face = asset(Assets.faces)
	if type(face) == "table" then
		for _, faceComponent in face do
			local decal = Instance.new("Decal")
			decal.Texture = `rbxassetid://{faceComponent}`
			decal.Face = Enum.NormalId.Front
			decal.Parent = model.Head
		end
	else
		local decal = Instance.new("Decal")
		decal.Texture = `rbxassetid://{face}`
		decal.Face = Enum.NormalId.Front
		decal.Parent = model.Head
	end
	
	local clothes = asset(Assets.clothes)
	model.Shirt.ShirtTemplate = `rbxassetid://{clothes[1]}`
	model.Pants.PantsTemplate = `rbxassetid://{clothes[2]}`
	
	local hair = asset(Assets.hair)
	if hair ~= -1 then
		model.Humanoid:AddAccessory(InsertService:LoadAsset(hair):GetChildren()[1])
	end
	
	local accessory = asset(Assets.accessories)
	if accessory ~= -1 then
		model.Humanoid:AddAccessory(InsertService:LoadAsset(accessory):GetChildren()[1])
	end
	
	local skinTone = asset(Assets.skin)
	model["Body Colors"].HeadColor = skinTone
	model["Body Colors"].LeftArmColor = skinTone
	model["Body Colors"].LeftLegColor = skinTone
	model["Body Colors"].RightArmColor = skinTone
	model["Body Colors"].RightLegColor = skinTone
	model["Body Colors"].TorsoColor = skinTone
	
	model.Name = asset(Assets.names)
	
	for _, v in model:GetChildren() do
		if v:IsA("BasePart") then
			v.CollisionGroup = "Justice:NPC"
		end
	end
	
	model:PivotTo(Configuration.NPCOrigin)
	model.Animation.Disabled = false
	model.Parent = workspace

	model.PrimaryPart:SetNetworkOwner(nil)
	
	startStateMachine(model)
end
