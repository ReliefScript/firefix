local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

getgenv().fireclickdetector = function(CD)
	local Part = CD.Parent
	if not Part or not Part:IsA("BasePart") then return end

	local Welds = {}
	for _, Weld in Part:GetChildren() do
		if Weld:IsA("Weld") then
			Welds[Weld] = Weld.Enabled
			Weld.Enabled = false
		end
	end

	local Old = Part.CFrame
	local OldDistance = CD.MaxActivationDistance
	local OldT = Part.Transparency
	Part.Transparency = 1
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
		CD.MaxActivationDistance = OldDistance
		for Weld, Enabled in Welds do
			Weld.Enabled = Enabled
		end
	end)
end

getgenv().firetouchinterest = function(Transmitter)
	local Part = Transmitter.Parent
	if not Part or not Part:IsA("BasePart") then return end

	local Char = LocalPlayer.Character
	if not Char then return end

	local Welds = {}
	for _, Weld in Part:GetChildren() do
		if Weld:IsA("Weld") then
			Welds[Weld] = Weld.Enabled
			Weld.Enabled = false
		end
	end

	local Old = Part.CFrame
	local OldCollision = Part.CanCollide
	Part.CanCollide = false
	Part.CFrame = Char:GetPivot()

	task.spawn(function()
		task.wait()

		Part.CanCollide = OldCollision
		Part.CFrame = Old
		for Weld, Enabled in Welds do
			Weld.Enabled = Enabled
		end
	end)
end
