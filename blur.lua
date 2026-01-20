-- recoded cuz it was buns (x2)

local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local GuiService = game:GetService("GuiService")

local Camera = workspace.CurrentCamera

local PART_THICKNESS = 0.01
local PART_TRANSPARENCY = 1 - 1e-7
local BLUR_PADDING = Vector2.zero
local BLUR_INTENSITY = 0.25
local PLANE_OFFSET = 0.05

local DoF = Instance.new("DepthOfFieldEffect")
DoF.NearIntensity = 0
DoF.FarIntensity = BLUR_INTENSITY
DoF.InFocusRadius = 0
DoF.Parent = Lighting

local Objects = {}
local Parts = {}

local Library = {}
Library.__index = Library

local function rayPlaneIntersect(planePos, planeNormal, rayOrigin, rayDir)
	local denom = planeNormal:Dot(rayDir)
	if math.abs(denom) < 1e-6 then
		return nil
	end

	local t = (planePos - rayOrigin):Dot(planeNormal) / denom
	return rayOrigin + rayDir * t
end

local function getGuiInset(frame)
	local gui = frame:FindFirstAncestorOfClass("ScreenGui")
	if gui and gui.IgnoreGuiInset then
		return Vector2.zero
	end
	return GuiService:GetGuiInset()
end

local function updateBlur(obj)
	local frame = obj.Frame
	local part = obj.Part
	local mesh = obj.Mesh

	if not frame.Visible then
		part.Transparency = 1
		return
	end

	part.Transparency = PART_TRANSPARENCY

	local inset = getGuiInset(frame)
	local absPos = frame.AbsolutePosition + inset + BLUR_PADDING
	local absSize = frame.AbsoluteSize - BLUR_PADDING * 2

	local p0 = absPos
	local p1 = absPos + absSize

	local ray0 = Camera:ViewportPointToRay(p0.X, p0.Y)
	local ray1 = Camera:ViewportPointToRay(p1.X, p1.Y)

	local planeDist = PLANE_OFFSET - Camera.NearPlaneZ
	local planePos = Camera.CFrame.Position + Camera.CFrame.LookVector * planeDist
	local planeNormal = Camera.CFrame.LookVector

	local w0 = rayPlaneIntersect(planePos, planeNormal, ray0.Origin, ray0.Direction)
	local w1 = rayPlaneIntersect(planePos, planeNormal, ray1.Origin, ray1.Direction)

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
	"BlurGuiUpdate",
	Enum.RenderPriority.Camera.Value + 1,
	function()
		if #Objects == 0 then return end

		local planeDist = PLANE_OFFSET - Camera.NearPlaneZ
		DoF.FocusDistance = planeDist

		for i = 1, #Objects do
			updateBlur(Objects[i])
		end

		local camCF = Camera.CFrame
		for i = 1, #Parts do
			Parts[i].CFrame = camCF
		end
	end
)

function Library.new(frame: GuiObject)
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
