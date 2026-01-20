local Lighting          = game:GetService("Lighting")
local camera			= workspace.CurrentCamera

local BLUR_SIZE         = Vector2.new(10, 10)
local PART_SIZE         = 0.01
local PART_TRANSPARENCY = 1 - 1e-7
local START_INTENSITY	= 0.25

local BLUR_OBJ          = Instance.new("DepthOfFieldEffect")
BLUR_OBJ.FarIntensity   = 0
BLUR_OBJ.NearIntensity  = START_INTENSITY
BLUR_OBJ.FocusDistance  = 0.25
BLUR_OBJ.InFocusRadius  = 0
BLUR_OBJ.Parent         = Lighting

local PartsList         = {}
local BlursList         = {}
local BlurObjects       = {}
local BlurredGui        = {}

BlurredGui.__index      = BlurredGui

function rayPlaneIntersect(planePos, planeNormal, rayOrigin, rayDirection)
	local n = planeNormal
	local d = rayDirection
	local v = rayOrigin - planePos

	local num = n.x*v.x + n.y*v.y + n.z*v.z
	local den = n.x*d.x + n.y*d.y + n.z*d.z
	local a = -num / den

	return rayOrigin + a * rayDirection, a
end

function rebuildPartsList()
	PartsList = {}
	BlursList = {}
	for blurObj, part in pairs(BlurObjects) do
		if part and part.Parent then
			table.insert(PartsList, part)
			table.insert(BlursList, blurObj)
		end
	end
end

function BlurredGui.new(frame, shape)
	local blurPart        = Instance.new("Part")
	blurPart.Size         = Vector3.new(1, 1, 1) * 0.01
	blurPart.Anchored     = true
	blurPart.CanCollide   = false
	blurPart.CanTouch     = false
	blurPart.Material     = Enum.Material.Glass
	blurPart.Transparency = PART_TRANSPARENCY
	blurPart.Parent       = workspace.CurrentCamera

	local mesh
	if (shape == "Rectangle") then
		mesh        = Instance.new("BlockMesh")
		mesh.Parent = blurPart
	elseif (shape == "Oval") then
		mesh          = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent   = blurPart
	end
	
	local ignoreInset = false
	local currentObj  = frame
	
	while true do
		currentObj = currentObj.Parent

		if (currentObj and currentObj:IsA("ScreenGui")) then
			ignoreInset = currentObj.IgnoreGuiInset
			break
		elseif (currentObj == nil) then
			break
		end
	end

	local new = setmetatable({
		Frame          = frame;
		Part           = blurPart;
		Mesh           = mesh;
		IgnoreGuiInset = ignoreInset;
	}, BlurredGui)

	BlurObjects[new] = blurPart
	rebuildPartsList()

	return new
end

function updateGui(blurObj)
	if not blurObj.Part or not blurObj.Part.Parent or not blurObj.Frame then
		return
	end
	
	if (not blurObj.Frame.Visible) then
		blurObj.Part.Transparency = 1
		return
	end
	
	local camera = workspace.CurrentCamera
	local frame  = blurObj.Frame
	local part   = blurObj.Part
	local mesh   = blurObj.Mesh
	
	part.Transparency = PART_TRANSPARENCY
	
	local corner0 = frame.AbsolutePosition + BLUR_SIZE
	local corner1 = corner0 + frame.AbsoluteSize - BLUR_SIZE*2
	local ray0, ray1

	if (blurObj.IgnoreGuiInset) then
		ray0 = camera:ViewportPointToRay(corner0.X, corner0.Y, 1)
		ray1 = camera:ViewportPointToRay(corner1.X, corner1.Y, 1)
	else
		ray0 = camera:ScreenPointToRay(corner0.X, corner0.Y, 1)
		ray1 = camera:ScreenPointToRay(corner1.X, corner1.Y, 1)
	end

	local planeOrigin = camera.CFrame.Position + camera.CFrame.LookVector * (0.05 - camera.NearPlaneZ)
	local planeNormal = camera.CFrame.LookVector
	local pos0 = rayPlaneIntersect(planeOrigin, planeNormal, ray0.Origin, ray0.Direction)
	local pos1 = rayPlaneIntersect(planeOrigin, planeNormal, ray1.Origin, ray1.Direction)

	local pos0 = camera.CFrame:PointToObjectSpace(pos0)
	local pos1 = camera.CFrame:PointToObjectSpace(pos1)

	local size   = pos1 - pos0
	local center = (pos0 + pos1)/2

	mesh.Offset = center
	mesh.Scale  = size / PART_SIZE
end

function BlurredGui.updateAll()
	rebuildPartsList()
	
	if #BlursList == 0 then
		return
	end
	
	BLUR_OBJ.NearIntensity = START_INTENSITY
	
	for i = 1, #BlursList do
		updateGui(BlursList[i])
	end

	if #PartsList > 0 then
		local cframes = table.create(#PartsList, workspace.CurrentCamera.CFrame)
		workspace:BulkMoveTo(PartsList, cframes, Enum.BulkMoveMode.FireCFrameChanged)
	end

	BLUR_OBJ.FocusDistance = 0.25 - workspace.CurrentCamera.NearPlaneZ
end

function BlurredGui:Destroy()
	if self.Part then
		self.Part:Destroy()
	end
	BlurObjects[self] = nil
	rebuildPartsList()
end

game:GetService("RunService"):BindToRenderStep("BlurredGuiUpdate", Enum.RenderPriority.Camera.Value + 1, function()
	BlurredGui.updateAll()
end)
