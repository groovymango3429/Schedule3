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

local EVENT_TIMEOUT = newproxy()
local function runCogs(hook: string, ...)
	if not Cogs[hook] then return false end
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
	local connection
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

-- Ragdoll utility: Convert Motor6Ds to BallSocketConstraints, disable Humanoid, and stop animations
local function ragdollNPC(model)
	-- Disable Humanoid physics
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.PlatformStand = true
		humanoid.AutoRotate = false
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, true)
		humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	end
	-- Remove Animator/AnimationControllers
	for _, child in ipairs(model:GetDescendants()) do
		if child:IsA("Animator") or child:IsA("AnimationController") then
			child:Destroy()
		elseif child:IsA("Animation") then
			child.Disabled = true
		end
	end
	-- Convert Motor6Ds to BallSocketConstraints for ragdoll effect
	for _, motor in ipairs(model:GetDescendants()) do
		if motor:IsA("Motor6D") then
			local part0 = motor.Part0
			local part1 = motor.Part1
			local att0 = Instance.new("Attachment")
			local att1 = Instance.new("Attachment")
			att0.CFrame = motor.C0
			att1.CFrame = motor.C1
			att0.Parent = part0
			att1.Parent = part1
			local ballSocket = Instance.new("BallSocketConstraint")
			ballSocket.Attachment0 = att0
			ballSocket.Attachment1 = att1
			ballSocket.Parent = part0

			-- Restrict neck rotation for realism
			if motor.Name == "Neck" then
				ballSocket.LimitsEnabled = true
				ballSocket.UpperAngle = 45 -- Limit side-to-side tilt
				ballSocket.TwistLimitsEnabled = true
				ballSocket.TwistLowerAngle = -45
				ballSocket.TwistUpperAngle = 45 -- Limit head twisting
			end

			motor:Destroy()
		end
	end
	-- Enable collisions and assign CollisionGroup on all body parts, add damping to prevent endless rotation
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = true
			part.CollisionGroup = "Justice:NPC"
			pcall(function()
				part.AngularDamping = 3 -- prevents endless spinning
				part.LinearDamping = 0.5 -- helps limbs settle and not slide forever
			end)
		end
	end
end

local function startStateMachine(model)
	local brain = StateMachine.new({
		states = { "Idling", "Routing", "Wandering", "Dead" },
		transitions = {
			{ name = "CalculateRoute", from = { "Idling", "Wandering" }, to = "Routing" },
			{ name = "ExecuteRoute", from = "Routing", to = "Wandering" },
			{ name = "Idle", from = { "Wandering", "Routing" }, to = "Idling" },
			{ name = "Dead", from = { "Idling", "Routing", "Wandering" }, to = "Dead" }
		},
		initialState = "Idling"
	})

	local npcModel = model
	local markerColor = BrickColor.Random()
	local currentPath = nil
	local isDead = false

	if DEBUG then
		brain:Hook("__all", function(_old, new)
			npcModel.Head.Debugger.State.Text = `State: {new}`
			npcModel.Head.Debugger.Timeout.Visible = new == "Idling"
		end)
	end

	local function start()
		if isDead then return end -- PATCH: Prevent routing if dead
		local timeout = math.random(0, Configuration.MaxDawdlingTime)
		if DEBUG then
			npcModel.Head.Debugger.Timeout.Text = `Timed out for {timeout}`
		end
		task.delay(timeout, function()
			if isDead then return end -- PATCH: Prevent transition if dead
			brain:Transition("Routing")
		end)
	end

	brain:Hook("__start", start)
	brain:Hook("Idle", start)

	brain:Hook("CalculateRoute", function()
		if isDead then return end -- PATCH: Prevent transition if dead
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
		if isDead then return end -- PATCH: Prevent transition if dead
		task.defer(function()
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
				if isDead then break end -- PATCH: Stop moving if dead
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

			if not isDead then
				brain:Transition("Idling")
			end
		end)
	end)

	-- Ragdoll on death
	local humanoid = npcModel:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Died:Connect(function()
			if not isDead then
				isDead = true
				ragdollNPC(npcModel)
				brain:Transition("Dead")
			end
		end)
	end

	brain:Start()
end

local function getAsset(tbl, discriminator)
	local assetTable = tbl[discriminator]
	local all = tbl["all"]
	if assetTable and #assetTable > 0 then
		local t = {}
		for _, v in assetTable do table.insert(t, v) end
		for _, v in all do table.insert(t, v) end
		assetTable = t
	else
		assetTable = all
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
