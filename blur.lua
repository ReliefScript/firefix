-- recoded cuz it was buns

local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local GuiService = game:GetService("GuiService")

local Camera = workspace.CurrentCamera

local PART_THICKNESS = 0.01
local BLUR_MARGIN = Vector2.zero
local START_INTENSITY = 0.25

local DoF = Instance.new("DepthOfFieldEffect")
DoF.NearIntensity = START_INTENSITY
DoF.FarIntensity = 0
DoF.InFocusRadius = 0
DoF.FocusDistance = 0
DoF.Parent = Lighting

local Objects = {}
local Parts = {}

local Library = {}
Library.__index = Library

local function intersectPlane(rayOrigin, rayDir, planePos, planeNormal)
	local denom = planeNormal:Dot(rayDir)
	if math.abs(denom) < 1e-6 then
		return nil
	end
	local t = (planePos - rayOrigin):Dot(planeNormal) / denom
	return rayOrigin + rayDir * t
end

local function getInset(frame)
	local screenGui = frame:FindFirstAncestorOfClass("ScreenGui")
	if screenGui and screenGui.IgnoreGuiInset then
		return Vector2.zero
	end
	return GuiService:GetGuiInset()
end

local function updateObject(obj)
	local frame = obj.Frame
	local part = obj.Part
	local mesh = obj.Mesh

	if not frame.Visible then
		part.Transparency = 1
		return
	end

	part.Transparency = 1 - 1e-7

	local inset = getInset(frame)
	local absPos = frame.AbsolutePosition + inset + BLUR_MARGIN
	local absSize = frame.AbsoluteSize - BLUR_MARGIN * 2

	local p0 = absPos
	local p1 = absPos + absSize

	local ray0 = Camera:ViewportPointToRay(p0.X, p0.Y)
	local ray1 = Camera:ViewportPointToRay(p1.X, p1.Y)

	local planeDist = 0.05 - Camera.NearPlaneZ
	local planePos = Camera.CFrame.Position + Camera.CFrame.LookVector * planeDist
	local planeNormal = Camera.CFrame.LookVector

	local w0 = intersectPlane(ray0.Origin, ray0.Direction, planePos, planeNormal)
	local w1 = intersectPlane(ray1.Origin, ray1.Direction, planePos, planeNormal)

	if not w0 or not w1 then
		part.Transparency = 1
		return
	end

	local o0 = Camera.CFrame:PointToObjectSpace(w0)
	local o1 = Camera.CFrame:PointToObjectSpace(w1)

	local size = o1 - o0
	local center = (o0 + o1) * 0.5

	mesh.Offset = center
	mesh.Scale = size / PART_THICKNESS
end

RunService:BindToRenderStep(
	"BlurredGuiUpdate",
	Enum.RenderPriority.Camera.Value + 1,
	function()
		if #Objects == 0 then return end

		DoF.NearIntensity = START_INTENSITY
		DoF.FocusDistance = 0.25 - Camera.NearPlaneZ

		for i = 1, #Objects do
			updateObject(Objects[i])
		end

		local cf = Camera.CFrame
		for i = 1, #Parts do
			Parts[i].CFrame = cf
		end
	end
)

function Library.new(frame: Frame)
	assert(frame and frame:IsA("GuiObject"), "Expected GuiObject")

	local part = Instance.new("Part")
	part.Size = Vector3.new(1, 1, PART_THICKNESS)
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Material = Enum.Material.Glass
	part.Transparency = 1
	part.Parent = Camera

	local mesh = Instance.new("BlockMesh")
	mesh.Parent = part

	local self = setmetatable({
		Frame = frame,
		Part = part,
		Mesh = mesh,
	}, Library)

	table.insert(Objects, self)
	table.insert(Parts, part)

	return self
end

function Library:Destroy()
	for i = #Objects, 1, -1 do
		if Objects[i] == self then
			table.remove(Objects, i)
			table.remove(Parts, i)
			break
		end
	end

	if self.Part then
		self.Part:Destroy()
	end
end

return Library
