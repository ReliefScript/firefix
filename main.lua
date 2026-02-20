local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

getgenv().fireclickdetector = function(CD)
	local Part = CD.Parent
	if not Part or not Part:IsA("BasePart") then return end

	local Archive = {}
	for _, Inst in Part:GetDescendants() do
		if Inst:IsA("Weld") then
			Archive[Inst] = Inst.Enabled
			Inst.Enabled = false
		end
		if Inst:IsA("BasePart") then
			Archive[Inst] = Inst.CanCollide
			Inst.CanCollide = false
		end
	end

	local Old = Part.CFrame
	local OldDistance = CD.MaxActivationDistance
	local OldT = Part.Transparency
	local OldTouch = Part.CanTouch
	Part.Transparency = 1
	Part.CanTouch = true
	Part.CFrame = Camera.CFrame * CFrame.new(0, 0, -1)
	CD.MaxActivationDistance = math.huge

	task.spawn(function()
		local ScreenPos, OnScreen = Camera:WorldToViewportPoint(Part.Position)
		if OnScreen then
			VirtualInputManager:SendMouseMoveEvent(ScreenPos.X, ScreenPos.Y, game)
			task.wait()
			VirtualInputManager:SendMouseButtonEvent(ScreenPos.X, ScreenPos.Y, 0, true, game, 0)
			VirtualInputManager:SendMouseButtonEvent(ScreenPos.X, ScreenPos.Y, 0, false, game, 0)
		end

		task.wait()

		Part.Transparency = OldT
		Part.CFrame = Old
		Part.CanTouch = OldTouch
		CD.MaxActivationDistance = OldDistance
		for Inst, Enabled in Archive do
			if Inst:IsA("Weld") then
				Inst.Enabled = false
			end
			if Inst:IsA("BasePart") then
				Inst.CanCollide = false
			end
		end
	end)
end

getgenv().firetouchinterest = function(Transmitter)
	local Part = Transmitter.Parent
	if not Part or not Part:IsA("BasePart") then return end

	local Char = LocalPlayer.Character
	if not Char then return end

	local Archive = {}
	for _, Inst in Part:GetDescendants() do
		if Inst:IsA("Weld") then
			Archive[Inst] = Inst.Enabled
			Inst.Enabled = false
		end
		if Inst:IsA("BasePart") then
			Archive[Inst] = Inst.CanCollide
			Inst.CanCollide = false
		end
	end

	local Old = Part.CFrame
	local OldCollision = Part.CanCollide
	Part.CanCollide = false
	Part.CFrame = Char:GetPivot()

	task.spawn(function()
		task.wait()

		Part.CFrame = Old
		Part.CanCollide = OldCollision
		for Inst, Enabled in Archive do
			if Inst:IsA("Weld") then
				Inst.Enabled = false
			end
			if Inst:IsA("BasePart") then
				Inst.CanCollide = false
			end
		end
	end)
end

getgenv().fireproximityprompt = function(Proximity)
	local Part = Proximity.Parent
	if not Part or not Part:IsA("BasePart") then return end

	local Archive = {}
	for _, Inst in Part:GetDescendants() do
		if Inst:IsA("Weld") then
			Archive[Inst] = Inst.Enabled
			Inst.Enabled = false
		end
		if Inst:IsA("BasePart") then
			Archive[Inst] = Inst.CanCollide
			Inst.CanCollide = false
		end
	end

	local OldProps = {
		CFrame = Part.CFrame,
		Distance = Proximity.MaxActivationDistance,
		Trans = Part.Transparency,
		Enabled = Proximity.Enabled,
		LOS = Proximity.RequiresLineOfSight,
		Duration = Proximity.HoldDuration
	}

	Part.Transparency = 1
	Part.CFrame = Camera.CFrame * CFrame.new(0, 0, -1)
	Proximity.MaxActivationDistance = math.huge
	Proximity.Enabled = true
	Proximity.RequiresLineOfSight = false
	Proximity.HoldDuration = 0

	Proximity:InputHoldBegin()
	task.wait()
	Proximity:InputHoldEnd()
	
	Part.CFrame = OldProps.CFrame
	Part.Transparency = OldProps.Trans
	Proximity.MaxActivationDistance = OldProps.Distance
	Proximity.Enabled = OldProps.Enabled
	Proximity.RequiresLineOfSight = OldProps.LOS
	Proximity.HoldDuration = OldProps.Duration

	for Inst, Enabled in Archive do
		if Inst:IsA("Weld") then
			Inst.Enabled = false
		end
		if Inst:IsA("BasePart") then
			Inst.CanCollide = false
		end
	end
end
