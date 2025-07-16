local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local camera = game.Workspace.CurrentCamera
local dof = game.Lighting.DepthOfField
local aimCF = CFrame.new()
local mouse = player:GetMouse()
local playerGui = player.PlayerGui
local gui = playerGui:WaitForChild("Inventory")
local invF = gui:WaitForChild("Inventory")
local isAiming = false
local isShooting = false
local isReloading = false
local isSprinting = false
local canShoot = true
local canInspect = true
local bobOffset = CFrame.new()
local debounce = false
local currentSwayAMT = -.3
local swayAMT = -.3
local aimSwayAMT = .2
local swayCF = CFrame.new()
local lastCameraCF = CFrame.new()
local fireAnim, equipAnim, deequipAnim, emptyfireAnim, reloadAnim, emptyReloadAnim, InspectAnim, idleAnim = nil, nil, nil, nil, nil, nil, nil, nil

local framework = {
	inventory = {
		"TROY DEFENSE AR";
		"G19 ROLAND SPECIAL";
	},
	module = nil,
	viewmodel = nil,
	currentSlot = 1,
}

local equippedTool = nil

function PlayLocalFireSound()
	if not framework.module then return end
	local fireSound = Instance.new("Sound")
	fireSound.SoundId = framework.module.fireSound.SoundId
	fireSound.Volume = framework.module.fireSound.Volume
	fireSound.Parent = camera
	fireSound:Play()
	game:GetService("Debris"):AddItem(fireSound, 2)
end

function loadSlot(Item)
	local viewmodelFolder = game.ReplicatedStorage.Viewmodels
	local moduleFolder = game.ReplicatedStorage.Modules

	canShoot = false
	canInspect = false

	for i, v in pairs(camera:GetChildren()) do
		if v:IsA("Model") then
			if deequipAnim then deequipAnim:Play() end
			repeat task.wait() until deequipAnim == nil or deequipAnim.IsPlaying == false
			v:Destroy()
		end
	end

	if moduleFolder:FindFirstChild(Item) then
		framework.module = require(moduleFolder:FindFirstChild(Item))

		if viewmodelFolder:FindFirstChild(Item) then
			framework.viewmodel = viewmodelFolder:FindFirstChild(Item):Clone()
			framework.viewmodel.Parent = camera

			if framework.viewmodel and framework.module and character then
				fireAnim = Instance.new("Animation")
				fireAnim.Parent = framework.viewmodel
				fireAnim.Name = "Fire"
				fireAnim.AnimationId = framework.module.fireAnim
				fireAnim = framework.viewmodel.AnimationController.Animator:LoadAnimation(fireAnim)

				emptyfireAnim = Instance.new("Animation")
				emptyfireAnim.Parent = framework.viewmodel
				emptyfireAnim.Name = "Fire"
				emptyfireAnim.AnimationId = framework.module.emptyfireAnim
				emptyfireAnim = framework.viewmodel.AnimationController.Animator:LoadAnimation(emptyfireAnim)

				equipAnim = Instance.new("Animation")
				equipAnim.Parent = framework.viewmodel
				equipAnim.Name = "Equip"
				equipAnim.AnimationId = framework.module.equipAnim
				equipAnim = framework.viewmodel.AnimationController.Animator:LoadAnimation(equipAnim)

				deequipAnim = Instance.new("Animation")
				deequipAnim.Parent = framework.viewmodel
				deequipAnim.Name = "Deequip"
				deequipAnim.AnimationId = framework.module.deequipAnim
				deequipAnim = framework.viewmodel.AnimationController.Animator:LoadAnimation(deequipAnim)

				reloadAnim = Instance.new("Animation")
				reloadAnim.Parent = framework.viewmodel
				reloadAnim.Name = "Reload"
				reloadAnim.AnimationId = framework.module.reloadAnim
				reloadAnim = framework.viewmodel.AnimationController.Animator:LoadAnimation(reloadAnim)

				emptyReloadAnim = Instance.new("Animation")
				emptyReloadAnim.Parent = framework.viewmodel
				emptyReloadAnim.Name = "EmptyReload"
				emptyReloadAnim.AnimationId = framework.module.emptyReloadAnim
				emptyReloadAnim = framework.viewmodel.AnimationController.Animator:LoadAnimation(emptyReloadAnim)

				InspectAnim = Instance.new("Animation")
				InspectAnim.Parent = framework.viewmodel
				InspectAnim.Name = "Inspect"
				InspectAnim.AnimationId = framework.module.InspectAnim
				InspectAnim = framework.viewmodel.AnimationController.Animator:LoadAnimation(InspectAnim)

				idleAnim = Instance.new("Animation")
				idleAnim.Parent = framework.viewmodel
				idleAnim.Name = "Idle"
				idleAnim.AnimationId = framework.module.idleAnim
				idleAnim = framework.viewmodel.AnimationController.Animator:LoadAnimation(idleAnim)

				game.ReplicatedStorage.Events.LoadSlot:FireServer(framework.module.fireSound.SoundId, framework.module.fireSound.Volume)

				for i, v in pairs(framework.viewmodel:GetDescendants()) do
					if v:IsA("Part") or v:IsA("MeshPart") or v:IsA("BasePart") then
						v.Transparency = 1
					end
				end

				equipAnim:Play()
				task.wait(.1)

				for i, v in pairs(framework.viewmodel:GetDescendants()) do
					if v:IsA("Part") or v:IsA("MeshPart") or v:IsA("BasePart") then
						if v.Name ~= "Main" and v.Name ~= "Muzzle" and v.Name ~= "FakeCamera" and v.Name ~= "AimPart" and v.Name ~= "HumanoidRootPart" then
							v.Transparency = 0
						end
					end
				end

				canShoot = true
				canInspect = true
			end
		end
	end
end

local function updateViewmodel()
	if equippedTool and equippedTool:IsA("Tool") and equippedTool:GetAttribute("ItemType") == "Weapon" then
		loadSlot(equippedTool.Name)
	else
		for _, v in pairs(camera:GetChildren()) do
			if v:IsA("Model") then
				v:Destroy()
			end
		end
		framework.viewmodel = nil
		framework.module = nil
	end
end

local function onCharacterAdded(char)
	char.ChildAdded:Connect(function(child)
		if child:IsA("Tool") and child:GetAttribute("ItemType") == "Weapon" then
			equippedTool = child
			updateViewmodel()
		end
	end)
	char.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") and child:GetAttribute("ItemType") == "Weapon" then
			equippedTool = nil
			updateViewmodel()
		end
	end)
	for _, child in ipairs(char:GetChildren()) do
		if child:IsA("Tool") and child:GetAttribute("ItemType") == "Weapon" then
			equippedTool = child
			updateViewmodel()
			break
		end
	end
end

onCharacterAdded(character)
player.CharacterAdded:Connect(function(char)
	character = char
	humanoid = character:WaitForChild("Humanoid")
	onCharacterAdded(char)
end)

function CanShootServer()
	return game.ReplicatedStorage.Events.CanShoot:InvokeServer()
end

-- Returns true if the part is a body part of an NPC (checks for a Model with a Humanoid)
local function IsNPCBodyPart(part)
	if not part or not part:IsA("BasePart") then return false end
	local model = part:FindFirstAncestorOfClass("Model")
	if not model then return false end
	if model:FindFirstChildOfClass("Humanoid") then
		local bodyParts = {
			Head = true,
			Torso = true,
			HumanoidRootPart = true,
			LeftArm = true,
			RightArm = true,
			LeftLeg = true,
			RightLeg = true,
			UpperTorso = true,
			LowerTorso = true,
			LeftHand = true,
			RightHand = true,
			LeftFoot = true,
			RightFoot = true,
			-- Add any others for your rig
		}
		return bodyParts[part.Name] ~= nil
	end
	return false
end

function ShowHitOutline(part)
	if not IsNPCBodyPart(part) then return end
	if part:FindFirstChild("ClientHitHighlight") then
		part.ClientHitHighlight:Destroy()
	end
	local highlight = Instance.new("Highlight")
	highlight.Name = "ClientHitHighlight"
	highlight.Adornee = part
	highlight.FillTransparency = 1
	highlight.OutlineTransparency = 0
	highlight.OutlineColor = Color3.new(1,0,0)
	highlight.Parent = part

	local tween = TweenService:Create(highlight, TweenInfo.new(1), {OutlineTransparency = 1})
	task.delay(1, function()
		tween:Play()
		tween.Completed:Wait()
		highlight:Destroy()
	end)
end

function Shoot()
	if not framework.module then return end
	if not CanShootServer() then return end
	if debounce then return end
	debounce = true

	equipAnim:Stop()
	reloadAnim:Stop()
	emptyReloadAnim:Stop()
	InspectAnim:Stop()
	idleAnim:Stop()

	if framework.module.ammo == 1 then
		fireAnim:Stop()
		emptyfireAnim:Play()
	else
		emptyfireAnim:Stop()
		fireAnim:Play()
	end

	framework.module.ammo -= 1
	PlayLocalFireSound()

	-- Local Raycast for hit detection (only highlights body parts of NPCs)
	local origin = framework.viewmodel and framework.viewmodel:FindFirstChild("Muzzle") and framework.viewmodel.Muzzle.Position or camera.CFrame.Position
	local direction = (mouse.Hit.p - origin).Unit * 100
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Blacklist
	rayParams.FilterDescendantsInstances = {player.Character, framework.viewmodel}

	local result = workspace:Raycast(origin, direction, rayParams)
	if result and result.Instance and result.Instance:IsA("BasePart") then
		ShowHitOutline(result.Instance)
	end

	game.ReplicatedStorage.Events.Shoot:FireServer(origin, mouse.Hit.p)

	if framework.module.ammo == 0 then
		task.wait(.5)
		Reload()
		repeat task.wait() until emptyReloadAnim.IsPlaying == false
		debounce = false
	else
		wait(framework.module.fireRate)
		debounce = false
	end
end

function Inspect()
	if canInspect then
		idleAnim:Stop()
		dof.FarIntensity = 1
		dof.FocusDistance = 10.44
		dof.InFocusRadius = 25.215
		dof.NearIntensity = 0.183
		InspectAnim:Play()
		repeat task.wait() until InspectAnim.IsPlaying == false
		dof.FarIntensity = 0.1
		dof.FocusDistance = 0.05
		dof.InFocusRadius = 30
		dof.NearIntensity = 0
	end
end

function Reload()
	if isReloading == false and framework.module then
		canShoot = false
		canInspect = false
		isReloading = true
		fireAnim:Stop()
		emptyfireAnim:Stop()
		equipAnim:Stop()
		InspectAnim:Stop()
		idleAnim:Stop()
		game.ReplicatedStorage.Events.Reload:FireServer()
		if framework.module.ammo > 0 then
			reloadAnim:Play()
		else
			emptyReloadAnim:Play()
		end
		wait(framework.module.reloadTime)
		canShoot = true
		canInspect = true
		isReloading = false
		framework.module.ammo = framework.module.maxAmmo
	end
end

local oldCamCF = CFrame.new()
function updateCameraShake()
	if not framework.viewmodel then return end
	local newCamCF = framework.viewmodel.FakeCamera.CFrame:ToObjectSpace(framework.viewmodel.PrimaryPart.CFrame)
	camera.CFrame = camera.CFrame * newCamCF:ToObjectSpace(oldCamCF)
	oldCamCF = newCamCF
end

local hud = player.PlayerGui:WaitForChild("HUD")

RunService.RenderStepped:Connect(function()
	if framework.viewmodel then
		mouse.TargetFilter = framework.viewmodel
	end

	if humanoid then
		local rot = camera.CFrame:ToObjectSpace(lastCameraCF)
		local X, Y, Z = rot:ToOrientation()
		swayCF = swayCF:Lerp(CFrame.Angles(math.sin(X) * currentSwayAMT, math.sin(Y) * currentSwayAMT, 0), .1)
		lastCameraCF = camera.CFrame

		if hud and humanoid then
			if framework.viewmodel and framework.module then
				hud.GunName.Text = framework.inventory[framework.currentSlot]
				hud.Ammo.Text = framework.module.ammo
				hud.Ammo.MaxAmmo.Text = framework.module.maxAmmo
			end
		end

		if framework.viewmodel ~= nil and framework.module ~= nil then
			if humanoid.MoveDirection.Magnitude > 0 then
				if humanoid.WalkSpeed == 17 then
					bobOffset = bobOffset:Lerp(CFrame.new(math.cos(tick() * 4) * .05, -humanoid.CameraOffset.Y/3, -humanoid.CameraOffset.Z/3) * CFrame.Angles(0, math.sin(tick() * -4) * -.05, math.cos(tick() * 4) * .05), .1)
					isSprinting = false
				elseif humanoid.WalkSpeed == 30 then
					bobOffset = bobOffset:Lerp(CFrame.new(math.cos(tick() * 8) * .1, -humanoid.CameraOffset.Y/3, -humanoid.CameraOffset.Z/3) * CFrame.Angles(0, math.sin(tick() * -8) * -.1, math.cos(tick() * 8) * .1), .1)
					isSprinting = true
				end
			else
				bobOffset = bobOffset:Lerp(CFrame.new(0, -humanoid.CameraOffset.Y/3, 0), .1)
				isSprinting = false
			end
		end

		for i, v in pairs(camera:GetChildren()) do
			if v:IsA("Model") then
				v:SetPrimaryPartCFrame(camera.CFrame * swayCF * aimCF * bobOffset)
				updateCameraShake()

				if not fireAnim.IsPlaying and not emptyfireAnim.IsPlaying and not emptyReloadAnim.IsPlaying and not reloadAnim.IsPlaying and not InspectAnim.IsPlaying and not equipAnim.IsPlaying and not deequipAnim.IsPlaying then
					if idleAnim.IsPlaying == false then
						idleAnim:Play()
					end
				else
					idleAnim:Stop()
				end
			end
		end

		if framework.viewmodel ~= nil then
			if isAiming and framework.module and framework.module.canAim and isSprinting == false then
				local offset = framework.viewmodel.AimPart.CFrame:ToObjectSpace(framework.viewmodel.PrimaryPart.CFrame)
				aimCF = aimCF:Lerp(offset, framework.module.aimSmooth)
				currentSwayAMT = aimSwayAMT
			else
				local offset = CFrame.new()
				aimCF = aimCF:Lerp(offset, framework.module.aimSmooth)
				currentSwayAMT = swayAMT
			end
		end
	end
end)

mouse.Button1Down:Connect(function()
	if character and framework.viewmodel and framework.module and framework.module.ammo > 0 and debounce == false and isReloading ~= true and canShoot == true and invF.Visible == false then
		if framework.module.fireMode == "Full Auto" then
			isShooting = true
		else
			Shoot()
		end
	end
end)

mouse.Button1Up:Connect(function()
	isShooting = false
end)

UserInputService.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		isAiming = true
	end

	if input.KeyCode == Enum.KeyCode.R then
		Reload()
	end

	if input.KeyCode == Enum.KeyCode.F then
		Inspect()
	end

	if input.KeyCode == Enum.KeyCode.LeftShift then
		isSprinting = true
		if humanoid then
			humanoid.WalkSpeed = 30
		end
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		isAiming = false
	end

	if input.KeyCode == Enum.KeyCode.LeftShift then
		isSprinting = false
		if humanoid then
			humanoid.WalkSpeed = 17
		end
	end
end)

spawn(function()
	while true do
		wait()
		if isShooting and framework.module and framework.module.fireMode == "Full Auto"
			and framework.module.ammo > 0 and not isReloading and canShoot and not debounce then
			Shoot()
		end
	end
end)

game.ReplicatedStorage.Events.PlayGunSound.OnClientEvent:Connect(function(weaponName, pos)
	local moduleFolder = game.ReplicatedStorage.Modules
	local weaponModule = moduleFolder:FindFirstChild(weaponName)
	if not weaponModule then return end
	local m = require(weaponModule)
	local fireSound = Instance.new("Sound")
	fireSound.SoundId = m.fireSound.SoundId
	fireSound.Volume = m.fireSound.Volume
	fireSound.Position = pos
	fireSound.Parent = workspace
	fireSound.EmitterSize = 10
	fireSound.RollOffMode = Enum.RollOffMode.Inverse
	fireSound:Play()
	game:GetService("Debris"):AddItem(fireSound, 2)
end)
