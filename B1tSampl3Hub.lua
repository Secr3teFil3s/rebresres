--========================================================--
-- B1tSampl3 HUB
-- Modern UI + HitBox + Player ESP + GunDrop ESP + AimLock + Troll Fling
-- Desenvolvido pelo Studio B1tSampl3
--========================================================--

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera

--========================================================--
-- LIMPAR INSTÂNCIA ANTERIOR
--========================================================--

if _G.__B1tSampl3HubCleanup then
	pcall(_G.__B1tSampl3HubCleanup)
end

--========================================================--
-- CONFIGURAÇÕES
--========================================================--

local HITBOX_SIZE = 11
local HITBOX_TRANSPARENCY = 0.8
local HITBOX_MIN_SIZE = 2
local HITBOX_MAX_SIZE = 50
local HITBOX_SIZE_STEP = 1
local HITBOX_TRANSPARENCY_STEP = 0.1

local AIM_MAX_DISTANCE = 150
local AIM_MIN_DISTANCE = 25
local AIM_MAX_LIMIT = 1000
local AIM_DISTANCE_STEP = 25

local AIM_TOGGLE_KEY = Enum.KeyCode.Q
local HUB_TOGGLE_KEY = Enum.KeyCode.K

local PLAYER_ESP_UPDATE_INTERVAL = 0.15
local HITBOX_UPDATE_INTERVAL = 0.15
local GUNDROP_DISTANCE_UPDATE_INTERVAL = 0.15

local GUNDROP_COLOR = Color3.fromRGB(255, 154, 55)
local GUN_COLOR = Color3.fromRGB(70, 155, 255)
local KNIFE_COLOR = Color3.fromRGB(255, 78, 78)
local SAFE_COLOR = Color3.fromRGB(79, 230, 130)

--========================================================--
-- TEMA
--========================================================--

local Theme = {
	Background = Color3.fromRGB(14, 16, 22),
	Surface = Color3.fromRGB(21, 24, 33),
	Surface2 = Color3.fromRGB(27, 31, 42),
	Surface3 = Color3.fromRGB(34, 39, 52),
	Border = Color3.fromRGB(58, 66, 88),
	Text = Color3.fromRGB(238, 241, 248),
	Muted = Color3.fromRGB(151, 160, 180),
	Accent = Color3.fromRGB(94, 118, 255),
	Accent2 = Color3.fromRGB(126, 82, 230),
	Success = Color3.fromRGB(73, 213, 127),
	Danger = Color3.fromRGB(230, 76, 88),
	Warning = Color3.fromRGB(245, 166, 68),
}

--========================================================--
-- ESTADOS
--========================================================--

local destroyed = false
local hitboxEnabled = false
local espNameEnabled = false
local espDistanceEnabled = false
local gunDropESPEnabled = false
local aimlockEnabled = false
local rightMouseHeld = false
local selectedTarget = nil

local flingActive = false
local selectedFlingTarget = nil
local flingGeneration = 0
local flingBodyVelocity = nil
local flingReturnCFrame = nil
local ORIGINAL_FALLEN_PARTS_DESTROY_HEIGHT = workspace.FallenPartsDestroyHeight

local waitingAimKeybind = false
local waitingHubKeybind = false
local currentTab = "ESP"

local OriginalProperties = {}
local Connections = {}
local GunDropEntries = {}
local updateInterface

--========================================================--
-- CONEXÕES
--========================================================--

local function trackConnection(connection)
	table.insert(Connections, connection)
	return connection
end

--========================================================--
-- UTILITÁRIOS
--========================================================--

local function addCorner(object, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 10)
	corner.Parent = object
	return corner
end

local function addStroke(object, color, thickness, transparency)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or Theme.Border
	stroke.Thickness = thickness or 1
	stroke.Transparency = transparency or 0
	stroke.Parent = object
	return stroke
end

local function addGradient(object, color1, color2, rotation)
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, color1),
		ColorSequenceKeypoint.new(1, color2),
	})
	gradient.Rotation = rotation or 0
	gradient.Parent = object
	return gradient
end

local function tween(object, duration, properties)
	local info = TweenInfo.new(duration or 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local animation = TweenService:Create(object, info, properties)
	animation:Play()
	return animation
end

local function countGunDrops()
	local count = 0
	for _ in pairs(GunDropEntries) do
		count = count + 1
	end
	return count
end

--========================================================--
-- HITBOX
--========================================================--

local function saveOriginalProperties(rootPart)
	if OriginalProperties[rootPart] then
		return
	end

	OriginalProperties[rootPart] = {
		Size = rootPart.Size,
		Transparency = rootPart.Transparency,
		BrickColor = rootPart.BrickColor,
		Material = rootPart.Material,
		CanCollide = rootPart.CanCollide,
	}
end

local function applyHitbox(player)
	if player == LocalPlayer then
		return
	end

	local character = player.Character
	if not character then
		return
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return
	end

	saveOriginalProperties(rootPart)

	rootPart.Size = Vector3.new(HITBOX_SIZE, HITBOX_SIZE, HITBOX_SIZE)
	rootPart.Transparency = HITBOX_TRANSPARENCY
	rootPart.BrickColor = BrickColor.new("Really blue")
	rootPart.Material = Enum.Material.Neon
	rootPart.CanCollide = false
end

local function restoreAllHitboxes()
	for rootPart, original in pairs(OriginalProperties) do
		if rootPart and rootPart.Parent and original then
			pcall(function()
				rootPart.Size = original.Size
				rootPart.Transparency = original.Transparency
				rootPart.BrickColor = original.BrickColor
				rootPart.Material = original.Material
				rootPart.CanCollide = original.CanCollide
			end)
		end
		OriginalProperties[rootPart] = nil
	end
end

--========================================================--
-- ESP DE JOGADORES
--========================================================--

local function getPlayerWeaponColor(player)
	local backpack = player:FindFirstChild("Backpack")
	local character = player.Character or workspace:FindFirstChild(player.Name)

	local hasKnife = false
	local hasGun = false

	if backpack then
		hasKnife = backpack:FindFirstChild("Knife") ~= nil
		hasGun = backpack:FindFirstChild("Gun") ~= nil
	end

	if character then
		hasKnife = hasKnife or character:FindFirstChild("Knife") ~= nil
		hasGun = hasGun or character:FindFirstChild("Gun") ~= nil
	end

	if hasKnife then
		return KNIFE_COLOR
	end

	if hasGun then
		return GUN_COLOR
	end

	return SAFE_COLOR
end

local function getPlayerESP(player)
	local character = player.Character
	if not character then
		return nil
	end

	local head = character:FindFirstChild("Head")
	if not head then
		return nil
	end

	return head:FindFirstChild("B1tSampl3_ESP")
end

local function createPlayerESP(player)
	if player == LocalPlayer then
		return nil
	end

	local character = player.Character
	if not character then
		return nil
	end

	local head = character:FindFirstChild("Head")
	if not head then
		return nil
	end

	local existing = head:FindFirstChild("B1tSampl3_ESP")
	if existing then
		return existing
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "B1tSampl3_ESP"
	billboard.Adornee = head
	billboard.Size = UDim2.new(0, 240, 0, 62)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 5000
	billboard.Parent = head

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, 0, 0, 30)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = player.DisplayName .. " [@" .. player.Name .. "]"
	nameLabel.TextColor3 = getPlayerWeaponColor(player)
	nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	nameLabel.TextStrokeTransparency = 0
	nameLabel.TextSize = 16
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Visible = espNameEnabled
	nameLabel.Parent = billboard

	local distanceLabel = Instance.new("TextLabel")
	distanceLabel.Name = "DistanceLabel"
	distanceLabel.Size = UDim2.new(1, 0, 0, 25)
	distanceLabel.Position = UDim2.new(0, 0, 0, 28)
	distanceLabel.BackgroundTransparency = 1
	distanceLabel.Text = "[ ? studs ]"
	distanceLabel.TextColor3 = Color3.fromRGB(235, 238, 245)
	distanceLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	distanceLabel.TextStrokeTransparency = 0
	distanceLabel.TextSize = 14
	distanceLabel.Font = Enum.Font.GothamBold
	distanceLabel.Visible = espDistanceEnabled
	distanceLabel.Parent = billboard

	return billboard
end

local function updatePlayerESP(player)
	if player == LocalPlayer then
		return
	end

	local character = player.Character
	if not character then
		return
	end

	local targetRoot = character:FindFirstChild("HumanoidRootPart")
	local head = character:FindFirstChild("Head")
	if not targetRoot or not head then
		return
	end

	local billboard = getPlayerESP(player)
	if not billboard and (espNameEnabled or espDistanceEnabled) then
		billboard = createPlayerESP(player)
	end

	if not billboard then
		return
	end

	local nameLabel = billboard:FindFirstChild("NameLabel")
	local distanceLabel = billboard:FindFirstChild("DistanceLabel")

	if nameLabel then
		nameLabel.Visible = espNameEnabled
		nameLabel.Text = player.DisplayName .. " [@" .. player.Name .. "]"
		nameLabel.TextColor3 = getPlayerWeaponColor(player)
	end

	if distanceLabel then
		distanceLabel.Visible = espDistanceEnabled

		if espDistanceEnabled then
			local localCharacter = LocalPlayer.Character
			local localRoot = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")

			if localRoot then
				local distance = (localRoot.Position - targetRoot.Position).Magnitude
				distanceLabel.Text = "[ " .. tostring(math.floor(distance + 0.5)) .. " studs ]"
			else
				distanceLabel.Text = "[ ? studs ]"
			end
		end
	end
end

local function removePlayerESP(player)
	local esp = getPlayerESP(player)
	if esp then
		esp:Destroy()
	end
end

local function removeAllPlayerESP()
	for _, player in ipairs(Players:GetPlayers()) do
		removePlayerESP(player)
	end
end

--========================================================--
-- GUN DROP ESP - SISTEMA OTIMIZADO E ORIENTADO A EVENTOS
--========================================================--

local function isInsidePlayerCharacter(instance)
	if not instance then
		return false
	end

	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		if character and instance:IsDescendantOf(character) then
			return true
		end
	end

	return false
end

local function isValidGunDrop(gunDrop)
	if not gunDrop or not gunDrop.Parent then
		return false
	end

	if gunDrop.Name ~= "GunDrop" then
		return false
	end

	if not gunDrop:IsDescendantOf(workspace) then
		return false
	end

	if isInsidePlayerCharacter(gunDrop) then
		return false
	end

	local toolAncestor = gunDrop:FindFirstAncestorOfClass("Tool")
	if toolAncestor and isInsidePlayerCharacter(toolAncestor) then
		return false
	end

	return true
end

local function getGunDropAdornee(gunDrop)
	if not gunDrop then
		return nil
	end

	if gunDrop:IsA("BasePart") then
		return gunDrop
	end

	if gunDrop:IsA("Tool") then
		local handle = gunDrop:FindFirstChild("Handle")
		if handle and handle:IsA("BasePart") then
			return handle
		end
	end

	if gunDrop:IsA("Model") and gunDrop.PrimaryPart then
		return gunDrop.PrimaryPart
	end

	return gunDrop:FindFirstChildWhichIsA("BasePart", true)
end

local unregisterGunDrop
local registerGunDrop
local findReplacementGunDrop

unregisterGunDrop = function(gunDrop)
	local entry = GunDropEntries[gunDrop]
	if not entry then
		return
	end

	if entry.AncestryConnection then
		pcall(function()
			entry.AncestryConnection:Disconnect()
		end)
	end

	if entry.Billboard then
		pcall(function()
			entry.Billboard:Destroy()
		end)
	end

	if entry.Highlight then
		pcall(function()
			entry.Highlight:Destroy()
		end)
	end

	GunDropEntries[gunDrop] = nil
end

registerGunDrop = function(gunDrop)
	if not gunDropESPEnabled then
		return
	end

	if GunDropEntries[gunDrop] then
		return
	end

	if not isValidGunDrop(gunDrop) then
		return
	end

	local adornee = getGunDropAdornee(gunDrop)
	if not adornee or not adornee.Parent or isInsidePlayerCharacter(adornee) then
		return
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "B1tSampl3_GunDropESP"
	billboard.Adornee = adornee
	billboard.Size = UDim2.new(0, 230, 0, 62)
	billboard.StudsOffset = Vector3.new(0, 2.8, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 5000
	billboard.Parent = PlayerGui

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "DropNameLabel"
	nameLabel.Size = UDim2.new(1, 0, 0, 30)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = "GUN DROP"
	nameLabel.TextColor3 = GUNDROP_COLOR
	nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	nameLabel.TextStrokeTransparency = 0
	nameLabel.TextSize = 17
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Parent = billboard

	local distanceLabel = Instance.new("TextLabel")
	distanceLabel.Name = "DropDistanceLabel"
	distanceLabel.Size = UDim2.new(1, 0, 0, 25)
	distanceLabel.Position = UDim2.new(0, 0, 0, 28)
	distanceLabel.BackgroundTransparency = 1
	distanceLabel.Text = "[ ? studs ]"
	distanceLabel.TextColor3 = GUNDROP_COLOR
	distanceLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	distanceLabel.TextStrokeTransparency = 0
	distanceLabel.TextSize = 14
	distanceLabel.Font = Enum.Font.GothamBold
	distanceLabel.Parent = billboard

	local highlight = Instance.new("Highlight")
	highlight.Name = "B1tSampl3_GunDropHighlight"
	highlight.Adornee = gunDrop
	highlight.FillColor = GUNDROP_COLOR
	highlight.FillTransparency = 0.78
	highlight.OutlineColor = GUNDROP_COLOR
	highlight.OutlineTransparency = 0.05
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = gunDrop

	local entry = {
		Object = gunDrop,
		Adornee = adornee,
		Billboard = billboard,
		DistanceLabel = distanceLabel,
		Highlight = highlight,
		AncestryConnection = nil,
	}

	GunDropEntries[gunDrop] = entry

	entry.AncestryConnection = gunDrop.AncestryChanged:Connect(function()
		if destroyed then
			return
		end

		-- Remove imediatamente quando o GunDrop é coletado, equipado,
		-- movido para o Backpack ou deixa de ser um drop válido.
		if not gunDropESPEnabled or not isValidGunDrop(gunDrop) then
			unregisterGunDrop(gunDrop)

			if gunDropESPEnabled and findReplacementGunDrop then
				task.defer(findReplacementGunDrop)
			end
		end
	end)
end

local function clearAllGunDrops()
	local list = {}
	for gunDrop in pairs(GunDropEntries) do
		table.insert(list, gunDrop)
	end

	for _, gunDrop in ipairs(list) do
		unregisterGunDrop(gunDrop)
	end
end

findReplacementGunDrop = function()
	if not gunDropESPEnabled or destroyed then
		return
	end

	-- Busca recursiva apenas quando necessário. Não roda em loop.
	local first = workspace:FindFirstChild("GunDrop", true)
	if first and isValidGunDrop(first) then
		registerGunDrop(first)
		return
	end

	-- Fallback raro: só é usado quando o primeiro GunDrop encontrado está
	-- dentro de um Character ou não é um drop válido.
	if first then
		for _, object in ipairs(workspace:GetDescendants()) do
			if object.Name == "GunDrop" and isValidGunDrop(object) then
				registerGunDrop(object)
				return
			end
		end
	end
end

local function enableGunDropESP()
	gunDropESPEnabled = true
	findReplacementGunDrop()
end

local function disableGunDropESP()
	gunDropESPEnabled = false
	clearAllGunDrops()
end

local function updateGunDropDistances()
	if not gunDropESPEnabled then
		return
	end

	local localCharacter = LocalPlayer.Character
	local localRoot = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")

	local invalid = {}

	for gunDrop, entry in pairs(GunDropEntries) do
		if not isValidGunDrop(gunDrop)
			or not entry.Adornee
			or not entry.Adornee.Parent
			or isInsidePlayerCharacter(entry.Adornee)
		then
			table.insert(invalid, gunDrop)
		elseif localRoot and entry.DistanceLabel then
			local distance = (localRoot.Position - entry.Adornee.Position).Magnitude
			entry.DistanceLabel.Text = "[ " .. tostring(math.floor(distance + 0.5)) .. " studs ]"
		elseif entry.DistanceLabel then
			entry.DistanceLabel.Text = "[ ? studs ]"
		end
	end

	for _, gunDrop in ipairs(invalid) do
		unregisterGunDrop(gunDrop)
	end

	if #invalid > 0 and countGunDrops() == 0 then
		findReplacementGunDrop()
	end
end

--========================================================--
-- TROLL / FLING - ALVO ÚNICO E CONTÍNUO
--========================================================--

local function getLocalFlingParts()
	local character = LocalPlayer.Character
	if not character then
		return nil, nil, nil
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
		or (humanoid and humanoid.RootPart)

	return character, humanoid, rootPart
end

local function getTargetFlingPart(targetPlayer)
	if not targetPlayer or not targetPlayer.Parent then
		return nil, nil, nil
	end

	local character = targetPlayer.Character
	if not character then
		return nil, nil, nil
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
		or (humanoid and humanoid.RootPart)
	local head = character:FindFirstChild("Head")

	local targetPart = rootPart or head

	if not targetPart then
		local accessory = character:FindFirstChildOfClass("Accessory")
		local handle = accessory and accessory:FindFirstChild("Handle")
		if handle and handle:IsA("BasePart") then
			targetPart = handle
		end
	end

	return humanoid, targetPart, character
end

local function destroyFlingBodyVelocity()
	if flingBodyVelocity then
		pcall(function()
			flingBodyVelocity:Destroy()
		end)
		flingBodyVelocity = nil
	end
end

local function restoreFlingState(returnToSavedPosition)
	destroyFlingBodyVelocity()

	pcall(function()
		workspace.FallenPartsDestroyHeight = ORIGINAL_FALLEN_PARTS_DESTROY_HEIGHT
	end)

	local character, humanoid, rootPart = getLocalFlingParts()

	if humanoid then
		pcall(function()
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
		end)
	end

	if returnToSavedPosition and character and rootPart and flingReturnCFrame then
		pcall(function()
			character:PivotTo(flingReturnCFrame * CFrame.new(0, 0.5, 0))
			rootPart.AssemblyLinearVelocity = Vector3.zero
			rootPart.AssemblyAngularVelocity = Vector3.zero
		end)
	end

	Camera = workspace.CurrentCamera
	if Camera and humanoid then
		pcall(function()
			Camera.CameraSubject = humanoid
		end)
	end

	flingReturnCFrame = nil
end

local function stopFling(returnToSavedPosition)
	flingActive = false
	flingGeneration = flingGeneration + 1
	restoreFlingState(returnToSavedPosition ~= false)

	if updateInterface then
		updateInterface()
	end
end

local function flingTargetOnce(targetPlayer, generation)
	local character, humanoid, rootPart = getLocalFlingParts()
	local targetHumanoid, targetPart = getTargetFlingPart(targetPlayer)

	if not character or not humanoid or not rootPart or not targetPart then
		return false
	end

	if targetHumanoid and targetHumanoid.Health <= 0 then
		return false
	end

	if targetHumanoid and targetHumanoid.Sit then
		return false
	end

	if not flingReturnCFrame then
		flingReturnCFrame = rootPart.CFrame
	end

	pcall(function()
		workspace.FallenPartsDestroyHeight = -50000
	end)

	pcall(function()
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
	end)

	destroyFlingBodyVelocity()

	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Name = "B1tSampl3_FlingVelocity"
	bodyVelocity.Velocity = Vector3.zero
	bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
	bodyVelocity.Parent = rootPart
	flingBodyVelocity = bodyVelocity

	local startedAt = os.clock()
	local angle = 0
	local direction = 1

	while flingActive
		and not destroyed
		and generation == flingGeneration
		and targetPlayer == selectedFlingTarget
		and targetPlayer.Parent
		and os.clock() - startedAt < 1.75
	do
		local currentTargetHumanoid, currentTargetPart = getTargetFlingPart(targetPlayer)
		if not currentTargetPart then
			break
		end

		if currentTargetHumanoid and currentTargetHumanoid.Health <= 0 then
			break
		end

		angle = angle + 125
		direction = -direction

		local targetVelocity = currentTargetPart.AssemblyLinearVelocity.Magnitude
		local moveDirection = currentTargetHumanoid and currentTargetHumanoid.MoveDirection or Vector3.zero

		local verticalOffset = 1.5 * direction
		local forwardOffset = 0

		if targetVelocity >= 50 and currentTargetHumanoid then
			forwardOffset = currentTargetHumanoid.WalkSpeed * direction
		end

		local desiredCFrame =
			CFrame.new(currentTargetPart.Position)
			* CFrame.new(
				moveDirection.X * math.min(targetVelocity, 40) / 1.25,
				verticalOffset,
				forwardOffset + moveDirection.Z * math.min(targetVelocity, 40) / 1.25
			)
			* CFrame.Angles(math.rad(angle), 0, 0)

		pcall(function()
			character:PivotTo(desiredCFrame)
			rootPart.AssemblyLinearVelocity = Vector3.new(9e7, 9e8, 9e7)
			rootPart.AssemblyAngularVelocity = Vector3.new(9e8, 9e8, 9e8)
		end)

		RunService.Heartbeat:Wait()
	end

	destroyFlingBodyVelocity()

	if flingActive
		and generation == flingGeneration
		and targetPlayer == selectedFlingTarget
	then
		restoreFlingState(true)
	end

	return true
end

local function startFling()
	if flingActive then
		return
	end

	if not selectedFlingTarget or not selectedFlingTarget.Parent then
		selectedFlingTarget = nil
		if updateInterface then
			updateInterface()
		end
		return
	end

	flingActive = true
	flingGeneration = flingGeneration + 1
	local generation = flingGeneration

	if updateInterface then
		updateInterface()
	end

	task.spawn(function()
		while flingActive
			and not destroyed
			and generation == flingGeneration
		do
			local target = selectedFlingTarget

			if not target or not target.Parent then
				break
			end

			local success, didFling = pcall(function()
				return flingTargetOnce(target, generation)
			end)

			if not success or not didFling then
				break
			end

			if flingActive and generation == flingGeneration then
				task.wait(0.15)
			end
		end

		if flingActive and generation == flingGeneration then
			stopFling(true)
		end
	end)
end

--========================================================--
-- GUI BASE
--========================================================--

local oldGUI = PlayerGui:FindFirstChild("B1tSampl3HubController")
if oldGUI then
	oldGUI:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "B1tSampl3HubController"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 800, 0, 560)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.BackgroundColor3 = Theme.Background
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui
addCorner(MainFrame, 16)
addStroke(MainFrame, Theme.Border, 1, 0.15)

local Scale = Instance.new("UIScale")
Scale.Scale = 1
Scale.Parent = MainFrame

local function updateScale()
	Camera = workspace.CurrentCamera
	if not Camera then
		return
	end

	local viewport = Camera.ViewportSize
	local scaleX = (viewport.X - 40) / 800
	local scaleY = (viewport.Y - 40) / 560
	Scale.Scale = math.min(1, math.max(0.58, math.min(scaleX, scaleY)))
end

updateScale()
if Camera then
	trackConnection(Camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale))
end

local AccentLine = Instance.new("Frame")
AccentLine.Name = "AccentLine"
AccentLine.Size = UDim2.new(1, 0, 0, 3)
AccentLine.BackgroundColor3 = Theme.Accent
AccentLine.BorderSizePixel = 0
AccentLine.Parent = MainFrame
addGradient(AccentLine, Theme.Accent, Theme.Accent2, 0)

local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 62)
TopBar.Position = UDim2.new(0, 0, 0, 3)
TopBar.BackgroundColor3 = Theme.Surface
TopBar.BorderSizePixel = 0
TopBar.Active = true
TopBar.Parent = MainFrame

local BrandIcon = Instance.new("Frame")
BrandIcon.Size = UDim2.new(0, 38, 0, 38)
BrandIcon.Position = UDim2.new(0, 18, 0, 12)
BrandIcon.BackgroundColor3 = Theme.Accent
BrandIcon.BorderSizePixel = 0
BrandIcon.Parent = TopBar
addCorner(BrandIcon, 11)
addGradient(BrandIcon, Theme.Accent, Theme.Accent2, 45)

local BrandLetter = Instance.new("TextLabel")
BrandLetter.Size = UDim2.new(1, 0, 1, 0)
BrandLetter.BackgroundTransparency = 1
BrandLetter.Text = "B"
BrandLetter.TextColor3 = Color3.fromRGB(255, 255, 255)
BrandLetter.TextSize = 20
BrandLetter.Font = Enum.Font.GothamBold
BrandLetter.Parent = BrandIcon

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0, 300, 0, 26)
Title.Position = UDim2.new(0, 68, 0, 9)
Title.BackgroundTransparency = 1
Title.Text = "B1tSampl3 HUB"
Title.TextColor3 = Theme.Text
Title.TextSize = 20
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

local Subtitle = Instance.new("TextLabel")
Subtitle.Size = UDim2.new(0, 330, 0, 20)
Subtitle.Position = UDim2.new(0, 68, 0, 34)
Subtitle.BackgroundTransparency = 1
Subtitle.Text = "Painel de utilidades • interface moderna"
Subtitle.TextColor3 = Theme.Muted
Subtitle.TextSize = 12
Subtitle.Font = Enum.Font.Gotham
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.Parent = TopBar

local OnlineDot = Instance.new("Frame")
OnlineDot.Size = UDim2.new(0, 8, 0, 8)
OnlineDot.Position = UDim2.new(1, -178, 0, 27)
OnlineDot.BackgroundColor3 = Theme.Success
OnlineDot.BorderSizePixel = 0
OnlineDot.Parent = TopBar
addCorner(OnlineDot, 8)

local OnlineLabel = Instance.new("TextLabel")
OnlineLabel.Size = UDim2.new(0, 85, 0, 24)
OnlineLabel.Position = UDim2.new(1, -164, 0, 19)
OnlineLabel.BackgroundTransparency = 1
OnlineLabel.Text = "HUB ATIVO"
OnlineLabel.TextColor3 = Theme.Muted
OnlineLabel.TextSize = 11
OnlineLabel.Font = Enum.Font.GothamBold
OnlineLabel.TextXAlignment = Enum.TextXAlignment.Left
OnlineLabel.Parent = TopBar

local HideTopButton = Instance.new("TextButton")
HideTopButton.Size = UDim2.new(0, 38, 0, 32)
HideTopButton.Position = UDim2.new(1, -54, 0, 15)
HideTopButton.BackgroundColor3 = Theme.Surface3
HideTopButton.BorderSizePixel = 0
HideTopButton.Text = "—"
HideTopButton.TextColor3 = Theme.Text
HideTopButton.TextSize = 17
HideTopButton.Font = Enum.Font.GothamBold
HideTopButton.AutoButtonColor = false
HideTopButton.Parent = TopBar
addCorner(HideTopButton, 9)
addStroke(HideTopButton, Theme.Border, 1, 0.25)

local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 176, 1, -65)
Sidebar.Position = UDim2.new(0, 0, 0, 65)
Sidebar.BackgroundColor3 = Color3.fromRGB(17, 20, 28)
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame

local SidebarGradient = addGradient(Sidebar, Color3.fromRGB(20, 23, 33), Color3.fromRGB(14, 16, 23), 90)
SidebarGradient.Offset = Vector2.new(0, 0)

local SidebarDivider = Instance.new("Frame")
SidebarDivider.Size = UDim2.new(0, 1, 1, 0)
SidebarDivider.Position = UDim2.new(1, -1, 0, 0)
SidebarDivider.BackgroundColor3 = Theme.Border
SidebarDivider.BackgroundTransparency = 0.45
SidebarDivider.BorderSizePixel = 0
SidebarDivider.Parent = Sidebar

local NavigationTitle = Instance.new("TextLabel")
NavigationTitle.Size = UDim2.new(1, -28, 0, 22)
NavigationTitle.Position = UDim2.new(0, 14, 0, 18)
NavigationTitle.BackgroundTransparency = 1
NavigationTitle.Text = "NAVEGAÇÃO"
NavigationTitle.TextColor3 = Theme.Muted
NavigationTitle.TextSize = 10
NavigationTitle.Font = Enum.Font.GothamBold
NavigationTitle.TextXAlignment = Enum.TextXAlignment.Left
NavigationTitle.Parent = Sidebar

local PageContainer = Instance.new("Frame")
PageContainer.Name = "PageContainer"
PageContainer.Size = UDim2.new(1, -176, 1, -65)
PageContainer.Position = UDim2.new(0, 176, 0, 65)
PageContainer.BackgroundTransparency = 1
PageContainer.Parent = MainFrame

local Pages = {}
local TabButtons = {}

local function createPage(name, titleText, subtitleText)
	local page = Instance.new("ScrollingFrame")
	page.Name = name .. "Page"
	page.Size = UDim2.new(1, 0, 1, 0)
	page.BackgroundTransparency = 1
	page.BorderSizePixel = 0
	page.ScrollBarThickness = 4
	page.ScrollBarImageColor3 = Theme.Accent
	page.AutomaticCanvasSize = Enum.AutomaticSize.Y
	page.CanvasSize = UDim2.new(0, 0, 0, 0)
	page.Visible = false
	page.Parent = PageContainer

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 22)
	padding.PaddingBottom = UDim.new(0, 22)
	padding.PaddingLeft = UDim.new(0, 24)
	padding.PaddingRight = UDim.new(0, 24)
	padding.Parent = page

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 14)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = page

	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 54)
	header.BackgroundTransparency = 1
	header.LayoutOrder = 0
	header.Parent = page

	local heading = Instance.new("TextLabel")
	heading.Size = UDim2.new(1, 0, 0, 28)
	heading.BackgroundTransparency = 1
	heading.Text = titleText
	heading.TextColor3 = Theme.Text
	heading.TextSize = 23
	heading.Font = Enum.Font.GothamBold
	heading.TextXAlignment = Enum.TextXAlignment.Left
	heading.Parent = header

	local subheading = Instance.new("TextLabel")
	subheading.Size = UDim2.new(1, 0, 0, 20)
	subheading.Position = UDim2.new(0, 0, 0, 31)
	subheading.BackgroundTransparency = 1
	subheading.Text = subtitleText
	subheading.TextColor3 = Theme.Muted
	subheading.TextSize = 12
	subheading.Font = Enum.Font.Gotham
	subheading.TextXAlignment = Enum.TextXAlignment.Left
	subheading.Parent = header

	Pages[name] = page
	return page
end

local function createCard(parent, titleText, descriptionText, height, order)
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, 0, 0, height)
	card.BackgroundColor3 = Theme.Surface
	card.BorderSizePixel = 0
	card.LayoutOrder = order or 1
	card.Parent = parent
	addCorner(card, 13)
	addStroke(card, Theme.Border, 1, 0.35)

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -28, 0, 24)
	titleLabel.Position = UDim2.new(0, 14, 0, 12)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = titleText
	titleLabel.TextColor3 = Theme.Text
	titleLabel.TextSize = 15
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = card

	local descriptionLabel = Instance.new("TextLabel")
	descriptionLabel.Size = UDim2.new(1, -28, 0, 34)
	descriptionLabel.Position = UDim2.new(0, 14, 0, 38)
	descriptionLabel.BackgroundTransparency = 1
	descriptionLabel.Text = descriptionText
	descriptionLabel.TextColor3 = Theme.Muted
	descriptionLabel.TextSize = 11
	descriptionLabel.Font = Enum.Font.Gotham
	descriptionLabel.TextWrapped = true
	descriptionLabel.TextXAlignment = Enum.TextXAlignment.Left
	descriptionLabel.TextYAlignment = Enum.TextYAlignment.Top
	descriptionLabel.Parent = card

	return card
end

local function createActionButton(parent, text, width, xScale, xOffset, y, accent, danger)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(0, width, 0, 36)
	button.Position = UDim2.new(xScale or 0, xOffset or 0, 0, y)
	button.BackgroundColor3 = danger and Theme.Danger or (accent and Theme.Accent or Theme.Surface3)
	button.BorderSizePixel = 0
	button.Text = text
	button.TextColor3 = Theme.Text
	button.TextSize = 12
	button.Font = Enum.Font.GothamBold
	button.AutoButtonColor = false
	button.Parent = parent
	addCorner(button, 9)
	addStroke(button, danger and Theme.Danger or (accent and Theme.Accent or Theme.Border), 1, 0.35)

	if accent and not danger then
		addGradient(button, Theme.Accent, Theme.Accent2, 0)
	end

	trackConnection(button.MouseEnter:Connect(function()
		tween(button, 0.15, {BackgroundTransparency = 0.08})
	end))

	trackConnection(button.MouseLeave:Connect(function()
		tween(button, 0.15, {BackgroundTransparency = 0})
	end))

	return button
end

local function createStatusPill(parent, text, x, y, width)
	local pill = Instance.new("TextLabel")
	pill.Size = UDim2.new(0, width or 120, 0, 28)
	pill.Position = UDim2.new(0, x, 0, y)
	pill.BackgroundColor3 = Theme.Surface3
	pill.BorderSizePixel = 0
	pill.Text = text
	pill.TextColor3 = Theme.Muted
	pill.TextSize = 11
	pill.Font = Enum.Font.GothamBold
	pill.Parent = parent
	addCorner(pill, 14)
	addStroke(pill, Theme.Border, 1, 0.45)
	return pill
end

local function createTab(name, text, order)
	local button = Instance.new("TextButton")
	button.Name = name .. "TabButton"
	button.Size = UDim2.new(1, -20, 0, 42)
	button.Position = UDim2.new(0, 10, 0, 48 + ((order - 1) * 48))
	button.BackgroundColor3 = Theme.Surface2
	button.BackgroundTransparency = 1
	button.BorderSizePixel = 0
	button.Text = text
	button.TextColor3 = Theme.Muted
	button.TextSize = 13
	button.Font = Enum.Font.GothamBold
	button.TextXAlignment = Enum.TextXAlignment.Left
	button.AutoButtonColor = false
	button.Parent = Sidebar
	addCorner(button, 10)

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 14)
	padding.Parent = button

	local indicator = Instance.new("Frame")
	indicator.Name = "Indicator"
	indicator.Size = UDim2.new(0, 3, 0, 22)
	indicator.Position = UDim2.new(0, 0, 0.5, -11)
	indicator.BackgroundColor3 = Theme.Accent
	indicator.BorderSizePixel = 0
	indicator.Visible = false
	indicator.Parent = button
	addCorner(indicator, 3)
	addGradient(indicator, Theme.Accent, Theme.Accent2, 90)

	TabButtons[name] = button
	return button
end

local HitBoxPage = createPage("HitBox", "HitBox", "Ajuste o tamanho e a transparência da hitbox dos outros jogadores.")
local ESPPage = createPage("ESP", "ESP", "Visualização de jogadores, armas e GunDrop com atualização otimizada.")
local AimPage = createPage("AimLock", "AimLock", "Selecione um alvo, configure a distância e use uma tecla de atalho.")
local TrollPage = createPage("Troll", "Troll", "Selecione um jogador e controle a função Fling diretamente pelo HUB.")
local SettingsPage = createPage("Settings", "Configurações", "Personalize o HUB, o atalho de visibilidade e as opções gerais.")
local CreditsPage = createPage("Credits", "Créditos", "Informações sobre o desenvolvimento do B1tSampl3 HUB.")

createTab("HitBox", "HitBox", 1)
createTab("ESP", "ESP", 2)
createTab("AimLock", "AimLock", 3)
createTab("Troll", "Troll", 4)
createTab("Settings", "Configurações", 5)
createTab("Credits", "Créditos", 6)

local function showTab(name)
	currentTab = name

	for pageName, page in pairs(Pages) do
		page.Visible = pageName == name
	end

	for tabName, button in pairs(TabButtons) do
		local selected = tabName == name
		button.BackgroundTransparency = selected and 0 or 1
		button.TextColor3 = selected and Theme.Text or Theme.Muted

		local indicator = button:FindFirstChild("Indicator")
		if indicator then
			indicator.Visible = selected
		end
	end
end

for name, button in pairs(TabButtons) do
	local tabName = name
	trackConnection(button.MouseButton1Click:Connect(function()
		showTab(tabName)
	end))
end

--========================================================--
-- HITBOX PAGE
--========================================================--

local HitboxMainCard = createCard(HitBoxPage, "HitBox dos jogadores", "Ative ou desative a expansão visual da HumanoidRootPart dos outros jogadores.", 122, 1)
local HitboxStatus = createStatusPill(HitboxMainCard, "DESATIVADA", 14, 80, 118)
local ToggleHitbox = createActionButton(HitboxMainCard, "ATIVAR HITBOX", 160, 1, -174, 76, true, false)

local HitboxSizeCard = createCard(HitBoxPage, "Tamanho da HitBox", "Ajuste o tamanho aplicado à HumanoidRootPart.", 116, 2)
local SizeMinus = createActionButton(HitboxSizeCard, "−", 42, 0, 14, 65, false, false)
local SizeValue = createStatusPill(HitboxSizeCard, tostring(HITBOX_SIZE), 66, 69, 86)
local SizePlus = createActionButton(HitboxSizeCard, "+", 42, 0, 162, 65, false, false)

local HitboxTransparencyCard = createCard(HitBoxPage, "Transparência", "Controle a transparência da hitbox expandida.", 116, 3)
local TransparencyMinus = createActionButton(HitboxTransparencyCard, "−", 42, 0, 14, 65, false, false)
local TransparencyValue = createStatusPill(HitboxTransparencyCard, string.format("%.1f", HITBOX_TRANSPARENCY), 66, 69, 86)
local TransparencyPlus = createActionButton(HitboxTransparencyCard, "+", 42, 0, 162, 65, false, false)

--========================================================--
-- ESP PAGE
--========================================================--

local PlayerESPCard = createCard(ESPPage, "ESP de jogadores", "Nome e distância dos jogadores. A cor do nome muda conforme a arma carregada.", 168, 1)
local ESPNameStatus = createStatusPill(PlayerESPCard, "NOME: OFF", 14, 78, 112)
local ToggleESPName = createActionButton(PlayerESPCard, "ALTERNAR NOME", 150, 0, 138, 74, true, false)
local ESPDistanceStatus = createStatusPill(PlayerESPCard, "DISTÂNCIA: OFF", 14, 122, 112)
local ToggleESPDistance = createActionButton(PlayerESPCard, "ALTERNAR DISTÂNCIA", 150, 0, 138, 118, true, false)

local WeaponLegend = Instance.new("TextLabel")
WeaponLegend.Size = UDim2.new(1, -316, 0, 72)
WeaponLegend.Position = UDim2.new(0, 306, 0, 78)
WeaponLegend.BackgroundTransparency = 1
WeaponLegend.Text = "● Knife: vermelho\n● Gun: azul\n● Sem arma: verde"
WeaponLegend.TextColor3 = Theme.Muted
WeaponLegend.TextSize = 11
WeaponLegend.Font = Enum.Font.Gotham
WeaponLegend.TextXAlignment = Enum.TextXAlignment.Left
WeaponLegend.TextYAlignment = Enum.TextYAlignment.Top
WeaponLegend.Parent = PlayerESPCard

local GunDropCard = createCard(ESPPage, "ESP GunDrop", "Detecta GunDrop no mapa sem varrer a Workspace continuamente. O ESP some assim que a arma é coletada.", 138, 2)
local GunDropStatus = createStatusPill(GunDropCard, "DESATIVADO", 14, 84, 150)
local ToggleGunDropESP = createActionButton(GunDropCard, "ATIVAR GUNDROP", 170, 1, -184, 80, true, false)

local PerformanceCard = createCard(ESPPage, "Desempenho", "O GunDrop agora usa eventos DescendantAdded/Removing e AncestryChanged. A busca recursiva só acontece quando necessário, eliminando o scan completo a cada atualização.", 108, 3)

--========================================================--
-- AIMLOCK PAGE
--========================================================--

local AimMainCard = createCard(AimPage, "AimLock", "Ative o AimLock e segure o botão direito do mouse para travar a câmera no alvo selecionado.", 124, 1)
local AimStatus = createStatusPill(AimMainCard, "DESATIVADO", 14, 82, 120)
local ToggleAim = createActionButton(AimMainCard, "ATIVAR AIMLOCK", 170, 1, -184, 78, true, false)

local TargetCard = createCard(AimPage, "Selecionar alvo", "Clique no botão para atualizar a lista de jogadores disponíveis.", 214, 2)
local TargetButton = createActionButton(TargetCard, "Alvo: NENHUM", 260, 0, 14, 72, false, false)

local PlayerList = Instance.new("ScrollingFrame")
PlayerList.Size = UDim2.new(1, -28, 0, 92)
PlayerList.Position = UDim2.new(0, 14, 0, 112)
PlayerList.BackgroundColor3 = Theme.Surface2
PlayerList.BorderSizePixel = 0
PlayerList.ScrollBarThickness = 4
PlayerList.ScrollBarImageColor3 = Theme.Accent
PlayerList.AutomaticCanvasSize = Enum.AutomaticSize.Y
PlayerList.CanvasSize = UDim2.new(0, 0, 0, 0)
PlayerList.Visible = false
PlayerList.Parent = TargetCard
addCorner(PlayerList, 9)
addStroke(PlayerList, Theme.Border, 1, 0.4)

local PlayerListLayout = Instance.new("UIListLayout")
PlayerListLayout.Padding = UDim.new(0, 5)
PlayerListLayout.SortOrder = Enum.SortOrder.LayoutOrder
PlayerListLayout.Parent = PlayerList

local PlayerListPadding = Instance.new("UIPadding")
PlayerListPadding.PaddingTop = UDim.new(0, 6)
PlayerListPadding.PaddingBottom = UDim.new(0, 6)
PlayerListPadding.PaddingLeft = UDim.new(0, 6)
PlayerListPadding.PaddingRight = UDim.new(0, 6)
PlayerListPadding.Parent = PlayerList

local AimDistanceCard = createCard(AimPage, "Distância máxima", "Limite de distância para o AimLock continuar acompanhando o alvo.", 116, 3)
local AimDistanceMinus = createActionButton(AimDistanceCard, "−", 42, 0, 14, 65, false, false)
local AimDistanceValue = createStatusPill(AimDistanceCard, tostring(AIM_MAX_DISTANCE) .. " studs", 66, 69, 118)
local AimDistancePlus = createActionButton(AimDistanceCard, "+", 42, 0, 194, 65, false, false)

local AimKeyCard = createCard(AimPage, "Tecla do AimLock", "Use uma tecla para ativar ou desativar o AimLock sem voltar ao painel.", 126, 4)
local AimKeyLabel = createStatusPill(AimKeyCard, "TECLA: " .. AIM_TOGGLE_KEY.Name, 14, 84, 130)
local AimKeyButton = createActionButton(AimKeyCard, "DEFINIR TECLA", 170, 1, -184, 80, true, false)

--========================================================--
-- TROLL PAGE
--========================================================--

local FlingMainCard = createCard(TrollPage, "Fling", "Executa o Fling continuamente contra o jogador selecionado até você desativar a função.", 128, 1)
local FlingStatus = createStatusPill(FlingMainCard, "DESATIVADO", 14, 84, 135)
local ToggleFling = createActionButton(FlingMainCard, "ATIVAR FLING", 170, 1, -184, 80, true, false)

local FlingTargetCard = createCard(TrollPage, "Selecionar alvo", "Escolha um único jogador como alvo do Fling. A lista é atualizada sempre que for aberta.", 214, 2)
local FlingTargetButton = createActionButton(FlingTargetCard, "Alvo: NENHUM", 260, 0, 14, 72, false, false)

local FlingPlayerList = Instance.new("ScrollingFrame")
FlingPlayerList.Size = UDim2.new(1, -28, 0, 92)
FlingPlayerList.Position = UDim2.new(0, 14, 0, 112)
FlingPlayerList.BackgroundColor3 = Theme.Surface2
FlingPlayerList.BorderSizePixel = 0
FlingPlayerList.ScrollBarThickness = 4
FlingPlayerList.ScrollBarImageColor3 = Theme.Accent
FlingPlayerList.AutomaticCanvasSize = Enum.AutomaticSize.Y
FlingPlayerList.CanvasSize = UDim2.new(0, 0, 0, 0)
FlingPlayerList.Visible = false
FlingPlayerList.Parent = FlingTargetCard
addCorner(FlingPlayerList, 9)
addStroke(FlingPlayerList, Theme.Border, 1, 0.4)

local FlingPlayerListLayout = Instance.new("UIListLayout")
FlingPlayerListLayout.Padding = UDim.new(0, 5)
FlingPlayerListLayout.SortOrder = Enum.SortOrder.LayoutOrder
FlingPlayerListLayout.Parent = FlingPlayerList

local FlingPlayerListPadding = Instance.new("UIPadding")
FlingPlayerListPadding.PaddingTop = UDim.new(0, 6)
FlingPlayerListPadding.PaddingBottom = UDim.new(0, 6)
FlingPlayerListPadding.PaddingLeft = UDim.new(0, 6)
FlingPlayerListPadding.PaddingRight = UDim.new(0, 6)
FlingPlayerListPadding.Parent = FlingPlayerList

local FlingInfoCard = createCard(TrollPage, "Como usar", "1. Selecione o jogador alvo.  2. Clique em ATIVAR FLING.  3. Use DESATIVAR FLING para interromper e restaurar seu personagem.", 108, 3)

--========================================================--
-- SETTINGS PAGE
--========================================================--

local VisibilityCard = createCard(SettingsPage, "Visibilidade do HUB", "A tecla configurada esconde e mostra a interface. O HUB continua funcionando enquanto estiver oculto.", 146, 1)
local HubKeyLabel = createStatusPill(VisibilityCard, "TECLA: " .. HUB_TOGGLE_KEY.Name, 14, 84, 130)
local HubKeyButton = createActionButton(VisibilityCard, "DEFINIR TECLA", 170, 1, -184, 80, true, false)
local HideHubButton = createActionButton(VisibilityCard, "OCULTAR AGORA", 170, 1, -184, 122, false, false)
HideHubButton.Position = UDim2.new(1, -184, 0, 122)

-- Ajuste de altura porque há dois botões na área inferior.
VisibilityCard.Size = UDim2.new(1, 0, 0, 174)

local DestroyCard = createCard(SettingsPage, "Remover HUB", "Destrói a interface, desconecta eventos e desativa todas as funções do HUB nesta execução.", 128, 2)
local DestroyHubButton = createActionButton(DestroyCard, "DESTRUIR HUB", 190, 0, 14, 78, false, true)

--========================================================--
-- CREDITS PAGE
--========================================================--

local CreditsCard = createCard(CreditsPage, "Studio B1tSampl3", "Projeto desenvolvido para reunir as funções do HUB em uma interface organizada, leve e apresentável.", 250, 1)

local CreditsIcon = Instance.new("Frame")
CreditsIcon.Size = UDim2.new(0, 64, 0, 64)
CreditsIcon.Position = UDim2.new(0, 14, 0, 82)
CreditsIcon.BackgroundColor3 = Theme.Accent
CreditsIcon.BorderSizePixel = 0
CreditsIcon.Parent = CreditsCard
addCorner(CreditsIcon, 18)
addGradient(CreditsIcon, Theme.Accent, Theme.Accent2, 45)

local CreditsLetter = Instance.new("TextLabel")
CreditsLetter.Size = UDim2.new(1, 0, 1, 0)
CreditsLetter.BackgroundTransparency = 1
CreditsLetter.Text = "B"
CreditsLetter.TextColor3 = Color3.fromRGB(255, 255, 255)
CreditsLetter.TextSize = 30
CreditsLetter.Font = Enum.Font.GothamBold
CreditsLetter.Parent = CreditsIcon

local CreditsInfo = Instance.new("TextLabel")
CreditsInfo.Size = UDim2.new(1, -106, 0, 126)
CreditsInfo.Position = UDim2.new(0, 94, 0, 82)
CreditsInfo.BackgroundTransparency = 1
CreditsInfo.Text = "Desenvolvido pelo Studio B1tSampl3\n\nDesenvolvedor Script\nFOXSTYLISH_YT\n\nUI Designer\nFOXSTYLISH_YT"
CreditsInfo.TextColor3 = Theme.Text
CreditsInfo.TextSize = 13
CreditsInfo.Font = Enum.Font.Gotham
CreditsInfo.TextXAlignment = Enum.TextXAlignment.Left
CreditsInfo.TextYAlignment = Enum.TextYAlignment.Top
CreditsInfo.Parent = CreditsCard

local CreditsFooter = Instance.new("TextLabel")
CreditsFooter.Size = UDim2.new(1, -28, 0, 24)
CreditsFooter.Position = UDim2.new(0, 14, 1, -38)
CreditsFooter.BackgroundTransparency = 1
CreditsFooter.Text = "B1tSampl3 HUB • Feito com cuidado por FOXSTYLISH_YT"
CreditsFooter.TextColor3 = Theme.Muted
CreditsFooter.TextSize = 11
CreditsFooter.Font = Enum.Font.Gotham
CreditsFooter.TextXAlignment = Enum.TextXAlignment.Left
CreditsFooter.Parent = CreditsCard

--========================================================--
-- ATUALIZAR INTERFACE
--========================================================--

updateInterface = function()
	SizeValue.Text = tostring(HITBOX_SIZE)
	TransparencyValue.Text = string.format("%.1f", HITBOX_TRANSPARENCY)
	AimDistanceValue.Text = tostring(AIM_MAX_DISTANCE) .. " studs"

	if hitboxEnabled then
		HitboxStatus.Text = "ATIVADA"
		HitboxStatus.TextColor3 = Theme.Success
		ToggleHitbox.Text = "DESATIVAR HITBOX"
	else
		HitboxStatus.Text = "DESATIVADA"
		HitboxStatus.TextColor3 = Theme.Muted
		ToggleHitbox.Text = "ATIVAR HITBOX"
	end

	ESPNameStatus.Text = espNameEnabled and "NOME: ON" or "NOME: OFF"
	ESPNameStatus.TextColor3 = espNameEnabled and Theme.Success or Theme.Muted

	ESPDistanceStatus.Text = espDistanceEnabled and "DISTÂNCIA: ON" or "DISTÂNCIA: OFF"
	ESPDistanceStatus.TextColor3 = espDistanceEnabled and Theme.Success or Theme.Muted

	if gunDropESPEnabled then
		local total = countGunDrops()
		if total > 0 then
			GunDropStatus.Text = total == 1 and "1 ARMA ENCONTRADA" or (tostring(total) .. " ARMAS ENCONTRADAS")
			GunDropStatus.TextColor3 = Theme.Warning
		else
			GunDropStatus.Text = "PROCURANDO..."
			GunDropStatus.TextColor3 = Theme.Warning
		end
		ToggleGunDropESP.Text = "DESATIVAR GUNDROP"
	else
		GunDropStatus.Text = "DESATIVADO"
		GunDropStatus.TextColor3 = Theme.Muted
		ToggleGunDropESP.Text = "ATIVAR GUNDROP"
	end

	if aimlockEnabled then
		AimStatus.Text = "ATIVADO"
		AimStatus.TextColor3 = Theme.Success
		ToggleAim.Text = "DESATIVAR AIMLOCK"
	else
		AimStatus.Text = "DESATIVADO"
		AimStatus.TextColor3 = Theme.Muted
		ToggleAim.Text = "ATIVAR AIMLOCK"
	end

	if selectedTarget and selectedTarget.Parent then
		TargetButton.Text = "Alvo: " .. selectedTarget.DisplayName
	else
		selectedTarget = nil
		TargetButton.Text = "Alvo: NENHUM"
	end

	if flingActive then
		FlingStatus.Text = "ATIVADO"
		FlingStatus.TextColor3 = Theme.Danger
		ToggleFling.Text = "DESATIVAR FLING"
	else
		FlingStatus.Text = selectedFlingTarget and "PRONTO" or "DESATIVADO"
		FlingStatus.TextColor3 = selectedFlingTarget and Theme.Warning or Theme.Muted
		ToggleFling.Text = "ATIVAR FLING"
	end

	if selectedFlingTarget and selectedFlingTarget.Parent then
		FlingTargetButton.Text = "Alvo: " .. selectedFlingTarget.DisplayName
	else
		selectedFlingTarget = nil
		FlingTargetButton.Text = "Alvo: NENHUM"
	end

	if waitingAimKeybind then
		AimKeyLabel.Text = "PRESSIONE UMA TECLA..."
		AimKeyLabel.TextColor3 = Theme.Warning
		AimKeyButton.Text = "CANCELAR"
	else
		AimKeyLabel.Text = "TECLA: " .. AIM_TOGGLE_KEY.Name
		AimKeyLabel.TextColor3 = Theme.Text
		AimKeyButton.Text = "DEFINIR TECLA"
	end

	if waitingHubKeybind then
		HubKeyLabel.Text = "PRESSIONE UMA TECLA..."
		HubKeyLabel.TextColor3 = Theme.Warning
		HubKeyButton.Text = "CANCELAR"
	else
		HubKeyLabel.Text = "TECLA: " .. HUB_TOGGLE_KEY.Name
		HubKeyLabel.TextColor3 = Theme.Text
		HubKeyButton.Text = "DEFINIR TECLA"
	end
end

--========================================================--
-- LISTA DE JOGADORES
--========================================================--

local function refreshPlayerList()
	for _, object in ipairs(PlayerList:GetChildren()) do
		if object:IsA("TextButton") then
			object:Destroy()
		end
	end

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			local playerButton = Instance.new("TextButton")
			playerButton.Size = UDim2.new(1, -4, 0, 32)
			playerButton.BackgroundColor3 = Theme.Surface3
			playerButton.BorderSizePixel = 0
			playerButton.Text = player.DisplayName .. " [@" .. player.Name .. "]"
			playerButton.TextColor3 = Theme.Text
			playerButton.TextSize = 11
			playerButton.Font = Enum.Font.Gotham
			playerButton.AutoButtonColor = false
			playerButton.Parent = PlayerList
			addCorner(playerButton, 7)

			local targetPlayer = player
			trackConnection(playerButton.MouseButton1Click:Connect(function()
				selectedTarget = targetPlayer
				PlayerList.Visible = false
				updateInterface()
			end))
		end
	end
end

local function refreshFlingPlayerList()
	for _, object in ipairs(FlingPlayerList:GetChildren()) do
		if object:IsA("TextButton") then
			object:Destroy()
		end
	end

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			local playerButton = Instance.new("TextButton")
			playerButton.Size = UDim2.new(1, -4, 0, 32)
			playerButton.BackgroundColor3 = Theme.Surface3
			playerButton.BorderSizePixel = 0
			playerButton.Text = player.DisplayName .. " [@" .. player.Name .. "]"
			playerButton.TextColor3 = Theme.Text
			playerButton.TextSize = 11
			playerButton.Font = Enum.Font.Gotham
			playerButton.AutoButtonColor = false
			playerButton.Parent = FlingPlayerList
			addCorner(playerButton, 7)

			local targetPlayer = player
			trackConnection(playerButton.MouseButton1Click:Connect(function()
				if flingActive then
					stopFling(true)
				end

				selectedFlingTarget = targetPlayer
				FlingPlayerList.Visible = false
				updateInterface()
			end))
		end
	end
end

--========================================================--
-- CONTROLES HITBOX
--========================================================--

trackConnection(ToggleHitbox.MouseButton1Click:Connect(function()
	hitboxEnabled = not hitboxEnabled
	if not hitboxEnabled then
		restoreAllHitboxes()
	end
	updateInterface()
end))

trackConnection(SizeMinus.MouseButton1Click:Connect(function()
	HITBOX_SIZE = math.max(HITBOX_MIN_SIZE, HITBOX_SIZE - HITBOX_SIZE_STEP)
	updateInterface()
end))

trackConnection(SizePlus.MouseButton1Click:Connect(function()
	HITBOX_SIZE = math.min(HITBOX_MAX_SIZE, HITBOX_SIZE + HITBOX_SIZE_STEP)
	updateInterface()
end))

trackConnection(TransparencyMinus.MouseButton1Click:Connect(function()
	HITBOX_TRANSPARENCY = math.max(0, HITBOX_TRANSPARENCY - HITBOX_TRANSPARENCY_STEP)
	HITBOX_TRANSPARENCY = math.floor(HITBOX_TRANSPARENCY * 10 + 0.5) / 10
	updateInterface()
end))

trackConnection(TransparencyPlus.MouseButton1Click:Connect(function()
	HITBOX_TRANSPARENCY = math.min(1, HITBOX_TRANSPARENCY + HITBOX_TRANSPARENCY_STEP)
	HITBOX_TRANSPARENCY = math.floor(HITBOX_TRANSPARENCY * 10 + 0.5) / 10
	updateInterface()
end))

--========================================================--
-- CONTROLES ESP
--========================================================--

trackConnection(ToggleESPName.MouseButton1Click:Connect(function()
	espNameEnabled = not espNameEnabled
	if not espNameEnabled and not espDistanceEnabled then
		removeAllPlayerESP()
	end
	updateInterface()
end))

trackConnection(ToggleESPDistance.MouseButton1Click:Connect(function()
	espDistanceEnabled = not espDistanceEnabled
	if not espNameEnabled and not espDistanceEnabled then
		removeAllPlayerESP()
	end
	updateInterface()
end))

trackConnection(ToggleGunDropESP.MouseButton1Click:Connect(function()
	if gunDropESPEnabled then
		disableGunDropESP()
	else
		enableGunDropESP()
	end
	updateInterface()
end))

--========================================================--
-- CONTROLES AIMLOCK
--========================================================--

local function toggleAimLock()
	aimlockEnabled = not aimlockEnabled

	if not aimlockEnabled then
		rightMouseHeld = false
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end

	updateInterface()
end

trackConnection(ToggleAim.MouseButton1Click:Connect(toggleAimLock))

trackConnection(TargetButton.MouseButton1Click:Connect(function()
	refreshPlayerList()
	PlayerList.Visible = not PlayerList.Visible
end))

trackConnection(AimDistanceMinus.MouseButton1Click:Connect(function()
	AIM_MAX_DISTANCE = math.max(AIM_MIN_DISTANCE, AIM_MAX_DISTANCE - AIM_DISTANCE_STEP)
	updateInterface()
end))

trackConnection(AimDistancePlus.MouseButton1Click:Connect(function()
	AIM_MAX_DISTANCE = math.min(AIM_MAX_LIMIT, AIM_MAX_DISTANCE + AIM_DISTANCE_STEP)
	updateInterface()
end))

trackConnection(AimKeyButton.MouseButton1Click:Connect(function()
	waitingHubKeybind = false
	waitingAimKeybind = not waitingAimKeybind
	updateInterface()
end))

--========================================================--
-- CONTROLES TROLL / FLING
--========================================================--

trackConnection(ToggleFling.MouseButton1Click:Connect(function()
	if flingActive then
		stopFling(true)
	else
		startFling()
	end

	updateInterface()
end))

trackConnection(FlingTargetButton.MouseButton1Click:Connect(function()
	refreshFlingPlayerList()
	FlingPlayerList.Visible = not FlingPlayerList.Visible
end))

--========================================================--
-- CONFIGURAÇÕES
--========================================================--

local function setHubVisible(visible)
	MainFrame.Visible = visible
end

local function toggleHubVisible()
	setHubVisible(not MainFrame.Visible)
end

trackConnection(HubKeyButton.MouseButton1Click:Connect(function()
	waitingAimKeybind = false
	waitingHubKeybind = not waitingHubKeybind
	updateInterface()
end))

trackConnection(HideHubButton.MouseButton1Click:Connect(function()
	setHubVisible(false)
end))

trackConnection(HideTopButton.MouseButton1Click:Connect(function()
	setHubVisible(false)
end))

--========================================================--
-- ARRASTAR JANELA
--========================================================--

local dragging = false
local dragInput = nil
local dragStart = nil
local startPosition = nil

trackConnection(TopBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
	then
		dragging = true
		dragStart = input.Position
		startPosition = MainFrame.Position
	end
end))

trackConnection(TopBar.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch
	then
		dragInput = input
	end
end))

trackConnection(UserInputService.InputChanged:Connect(function(input)
	if dragging and input == dragInput then
		local delta = input.Position - dragStart
		MainFrame.Position = UDim2.new(
			startPosition.X.Scale,
			startPosition.X.Offset + delta.X,
			startPosition.Y.Scale,
			startPosition.Y.Offset + delta.Y
		)
	end
end))

trackConnection(UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
	then
		dragging = false
	end

	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		rightMouseHeld = false
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end
end))

--========================================================--
-- INPUT GLOBAL / KEYBINDS
--========================================================--

trackConnection(UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if destroyed then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		if not gameProcessed then
			rightMouseHeld = true
		end
		return
	end

	if input.UserInputType ~= Enum.UserInputType.Keyboard then
		return
	end

	local keyCode = input.KeyCode

	if waitingAimKeybind then
		if keyCode == Enum.KeyCode.Escape then
			waitingAimKeybind = false
		else
			AIM_TOGGLE_KEY = keyCode
			waitingAimKeybind = false
		end
		updateInterface()
		return
	end

	if waitingHubKeybind then
		if keyCode == Enum.KeyCode.Escape then
			waitingHubKeybind = false
		else
			HUB_TOGGLE_KEY = keyCode
			waitingHubKeybind = false
		end
		updateInterface()
		return
	end

	if gameProcessed or UserInputService:GetFocusedTextBox() then
		return
	end

	-- O atalho de visibilidade tem prioridade caso as duas teclas sejam iguais.
	if keyCode == HUB_TOGGLE_KEY then
		toggleHubVisible()
		return
	end

	if keyCode == AIM_TOGGLE_KEY then
		toggleAimLock()
	end
end))

--========================================================--
-- MONITORAMENTO GUNDROP POR EVENTOS
--========================================================--

trackConnection(workspace.DescendantAdded:Connect(function(object)
	if destroyed or not gunDropESPEnabled then
		return
	end

	if object.Name == "GunDrop" then
		task.defer(function()
			if gunDropESPEnabled and isValidGunDrop(object) then
				registerGunDrop(object)
				updateInterface()
			end
		end)
	end
end))

trackConnection(workspace.DescendantRemoving:Connect(function(object)
	if GunDropEntries[object] then
		unregisterGunDrop(object)
		task.defer(function()
			if gunDropESPEnabled then
				findReplacementGunDrop()
				updateInterface()
			end
		end)
	end
end))

--========================================================--
-- LOOPS LEVES
--========================================================--

local hitboxTimer = 0
local playerESPTimer = 0
local gunDropTimer = 0

trackConnection(RunService.Heartbeat:Connect(function(deltaTime)
	if destroyed then
		return
	end

	hitboxTimer = hitboxTimer + deltaTime
	playerESPTimer = playerESPTimer + deltaTime
	gunDropTimer = gunDropTimer + deltaTime

	if hitboxEnabled and hitboxTimer >= HITBOX_UPDATE_INTERVAL then
		hitboxTimer = 0
		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer then
				pcall(function()
					applyHitbox(player)
				end)
			end
		end
	end

	if (espNameEnabled or espDistanceEnabled) and playerESPTimer >= PLAYER_ESP_UPDATE_INTERVAL then
		playerESPTimer = 0
		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer then
				pcall(function()
					updatePlayerESP(player)
				end)
			end
		end
	end

	if gunDropESPEnabled and gunDropTimer >= GUNDROP_DISTANCE_UPDATE_INTERVAL then
		gunDropTimer = 0
		updateGunDropDistances()
	end
end))

--========================================================--
-- AIMLOCK RENDER
--========================================================--

local AIM_RENDER_NAME = "B1tSampl3_AimLock"

RunService:BindToRenderStep(
	AIM_RENDER_NAME,
	Enum.RenderPriority.Camera.Value + 1,
	function()
		if destroyed or not aimlockEnabled or not rightMouseHeld then
			return
		end

		if not selectedTarget or not selectedTarget.Parent then
			selectedTarget = nil
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
			updateInterface()
			return
		end

		local localCharacter = LocalPlayer.Character
		local targetCharacter = selectedTarget.Character
		if not localCharacter or not targetCharacter then
			return
		end

		local localRoot = localCharacter:FindFirstChild("HumanoidRootPart")
		local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
		local targetHead = targetCharacter:FindFirstChild("Head")
		local humanoid = targetCharacter:FindFirstChildOfClass("Humanoid")

		if not localRoot or not targetRoot or not targetHead or not humanoid then
			return
		end

		if humanoid.Health <= 0 then
			return
		end

		local distance = (localRoot.Position - targetRoot.Position).Magnitude
		if distance > AIM_MAX_DISTANCE then
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
			return
		end

		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		Camera = workspace.CurrentCamera

		if Camera then
			local cameraPosition = Camera.CFrame.Position
			Camera.CFrame = CFrame.lookAt(cameraPosition, targetHead.Position)
		end
	end
)

--========================================================--
-- PLAYERS ENTRANDO / SAINDO
--========================================================--

trackConnection(Players.PlayerAdded:Connect(function()
	if PlayerList.Visible then
		task.defer(refreshPlayerList)
	end

	if FlingPlayerList.Visible then
		task.defer(refreshFlingPlayerList)
	end
end))

trackConnection(Players.PlayerRemoving:Connect(function(player)
	removePlayerESP(player)

	if selectedTarget == player then
		selectedTarget = nil
		rightMouseHeld = false
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		updateInterface()
	end

	if selectedFlingTarget == player then
		stopFling(true)
		selectedFlingTarget = nil
		updateInterface()
	end

	if PlayerList.Visible then
		task.defer(refreshPlayerList)
	end

	if FlingPlayerList.Visible then
		task.defer(refreshFlingPlayerList)
	end
end))

--========================================================--
-- LIMPEZA COMPLETA / DESTROY HUB
--========================================================--

local function cleanup()
	if destroyed then
		return
	end

	stopFling(true)

	destroyed = true
	hitboxEnabled = false
	espNameEnabled = false
	espDistanceEnabled = false
	gunDropESPEnabled = false
	aimlockEnabled = false
	flingActive = false
	selectedFlingTarget = nil
	rightMouseHeld = false
	waitingAimKeybind = false
	waitingHubKeybind = false

	pcall(function()
		RunService:UnbindFromRenderStep(AIM_RENDER_NAME)
	end)

	UserInputService.MouseBehavior = Enum.MouseBehavior.Default

	restoreAllHitboxes()
	removeAllPlayerESP()
	clearAllGunDrops()

	for _, connection in ipairs(Connections) do
		pcall(function()
			connection:Disconnect()
		end)
	end

	Connections = {}

	if ScreenGui and ScreenGui.Parent then
		ScreenGui:Destroy()
	end

	_G.__B1tSampl3HubCleanup = nil
end

_G.__B1tSampl3HubCleanup = cleanup

trackConnection(DestroyHubButton.MouseButton1Click:Connect(function()
	cleanup()
end))

--========================================================--
-- INICIALIZAÇÃO
--========================================================--

showTab("ESP")
updateInterface()
