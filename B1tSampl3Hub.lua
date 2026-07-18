--========================================================--
-- B1tSampl3 HUB
-- HitBox + ESP Name + ESP Distance + GunDrop ESP + AimLock
--========================================================--

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

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

local MIN_SIZE = 2
local MAX_SIZE = 50
local SIZE_STEP = 1

local MIN_TRANSPARENCY = 0
local MAX_TRANSPARENCY = 1
local TRANSPARENCY_STEP = 0.1

local AIM_MAX_DISTANCE = 150
local AIM_MIN_DISTANCE = 25
local AIM_MAX_LIMIT = 1000
local AIM_DISTANCE_STEP = 25

-- Tecla padrão para ativar/desativar o AimLock.
-- Pode ser alterada pelo próprio painel.
local AIM_TOGGLE_KEY = Enum.KeyCode.Q

--========================================================--
-- ESTADOS
--========================================================--

local hitboxEnabled = false

local espNameEnabled = false
local espDistanceEnabled = false
local gunDropESPEnabled = false
local gunDropFound = false

local aimlockEnabled = false
local rightMouseHeld = false
local selectedTarget = nil
local waitingAimKeybind = false

local minimized = false
local destroyed = false

local OriginalProperties = {}

local Connections = {}

local CurrentGunDrop = nil
local GunDropBillboard = nil

--========================================================--
-- CONEXÕES
--========================================================--

local function trackConnection(connection)
	table.insert(Connections, connection)
	return connection
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
		CanCollide = rootPart.CanCollide
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

	local rootPart =
		character:FindFirstChild(
			"HumanoidRootPart"
		)

	if not rootPart then
		return
	end

	saveOriginalProperties(rootPart)

	rootPart.Size =
		Vector3.new(
			HITBOX_SIZE,
			HITBOX_SIZE,
			HITBOX_SIZE
		)

	rootPart.Transparency =
		HITBOX_TRANSPARENCY

	rootPart.BrickColor =
		BrickColor.new(
			"Really blue"
		)

	rootPart.Material =
		Enum.Material.Neon

	rootPart.CanCollide =
		false

end


local function restoreAllHitboxes()

	local restoreList = {}

	for rootPart in pairs(
		OriginalProperties
	) do

		table.insert(
			restoreList,
			rootPart
		)

	end

	for _, rootPart in ipairs(
		restoreList
	) do

		local original =
			OriginalProperties[rootPart]

		if original
			and rootPart
			and rootPart.Parent
		then

			pcall(
				function()

					rootPart.Size =
						original.Size

					rootPart.Transparency =
						original.Transparency

					rootPart.BrickColor =
						original.BrickColor

					rootPart.Material =
						original.Material

					rootPart.CanCollide =
						original.CanCollide

				end
			)

		end

		OriginalProperties[rootPart] =
			nil

	end

end

--========================================================--
-- ESP
--========================================================--

-- Detecta Gun/Knife exatamente onde o jogo coloca as Tools:
-- 1) Guardada: Player.Backpack.Gun / Player.Backpack.Knife
-- 2) Equipada: Workspace.NomeDoPlayer.Gun / Workspace.NomeDoPlayer.Knife
-- Knife tem prioridade (vermelho), depois Gun (azul), sem arma fica verde.
local function getPlayerWeaponColor(player)

	-- Backpack fica dentro do objeto Player.
	local backpack =
		player:FindFirstChild("Backpack")

	-- Quando equipada, a Tool vira filha direta do Character/Model na Workspace.
	local character =
		workspace:FindFirstChild(
			player.Name
		)
		or player.Character

	local hasGun = false
	local hasKnife = false

	--------------------------------------------------
	-- PROCURAR NO BACKPACK (GUARDADA)
	--------------------------------------------------

	if backpack then

		if backpack:FindFirstChild("Knife") then
			hasKnife = true
		end

		if backpack:FindFirstChild("Gun") then
			hasGun = true
		end

	end

	--------------------------------------------------
	-- PROCURAR NO MODEL DA WORKSPACE (EQUIPADA)
	--------------------------------------------------

	if character then

		if character:FindFirstChild("Knife") then
			hasKnife = true
		end

		if character:FindFirstChild("Gun") then
			hasGun = true
		end

	end

	--------------------------------------------------
	-- CORES DO ESP
	--------------------------------------------------

	-- Knife = vermelho
	if hasKnife then

		return Color3.fromRGB(
			255,
			50,
			50
		)

	end

	-- Gun = azul
	if hasGun then

		return Color3.fromRGB(
			0,
			140,
			255
		)

	end

	-- Sem arma = verde
	return Color3.fromRGB(
		0,
		255,
		100
	)

end

local function getESP(player)

	local character =
		player.Character

	if not character then
		return nil
	end

	local head =
		character:FindFirstChild(
			"Head"
		)

	if not head then
		return nil
	end

	return head:FindFirstChild(
		"B1tSampl3_ESP"
	)

end


local function createESP(player)

	if player == LocalPlayer then
		return nil
	end

	local character =
		player.Character

	if not character then
		return nil
	end

	local head =
		character:FindFirstChild(
			"Head"
		)

	if not head then
		return nil
	end

	local existing =
		head:FindFirstChild(
			"B1tSampl3_ESP"
		)

	if existing then
		return existing
	end

	--------------------------------------------------
	-- BILLBOARD
	--------------------------------------------------

	local Billboard =
		Instance.new(
			"BillboardGui"
		)

	Billboard.Name =
		"B1tSampl3_ESP"

	Billboard.Adornee =
		head

	Billboard.Size =
		UDim2.new(
			0,
			240,
			0,
			65
		)

	Billboard.StudsOffset =
		Vector3.new(
			0,
			3,
			0
		)

	Billboard.AlwaysOnTop =
		true

	Billboard.MaxDistance =
		5000

	Billboard.Parent =
		head

	--------------------------------------------------
	-- NOME
	--------------------------------------------------

	local NameLabel =
		Instance.new(
			"TextLabel"
		)

	NameLabel.Name =
		"NameLabel"

	NameLabel.Size =
		UDim2.new(
			1,
			0,
			0,
			30
		)

	NameLabel.Position =
		UDim2.new(
			0,
			0,
			0,
			0
		)

	NameLabel.BackgroundTransparency =
		1

	NameLabel.Text =
		player.DisplayName
		..
		" [@"
		..
		player.Name
		..
		"]"

	NameLabel.TextColor3 =
		getPlayerWeaponColor(
			player
		)

	NameLabel.TextStrokeColor3 =
		Color3.fromRGB(
			0,
			0,
			0
		)

	NameLabel.TextStrokeTransparency =
		0

	NameLabel.TextSize =
		16

	NameLabel.Font =
		Enum.Font.GothamBold

	NameLabel.Visible =
		espNameEnabled

	NameLabel.Parent =
		Billboard

	--------------------------------------------------
	-- DISTÂNCIA
	--------------------------------------------------

	local DistanceLabel =
		Instance.new(
			"TextLabel"
		)

	DistanceLabel.Name =
		"DistanceLabel"

	DistanceLabel.Size =
		UDim2.new(
			1,
			0,
			0,
			25
		)

	DistanceLabel.Position =
		UDim2.new(
			0,
			0,
			0,
			28
		)

	DistanceLabel.BackgroundTransparency =
		1

	DistanceLabel.Text =
		"[ ? studs ]"

	DistanceLabel.TextColor3 =
		Color3.fromRGB(
			255,
			255,
			255
		)

	DistanceLabel.TextStrokeColor3 =
		Color3.fromRGB(
			0,
			0,
			0
		)

	DistanceLabel.TextStrokeTransparency =
		0

	DistanceLabel.TextSize =
		14

	DistanceLabel.Font =
		Enum.Font.GothamBold

	DistanceLabel.Visible =
		espDistanceEnabled

	DistanceLabel.Parent =
		Billboard

	return Billboard

end

--========================================================--
-- ATUALIZAR ESP
--========================================================--

local function updateESP(player)

	if player == LocalPlayer then
		return
	end

	local character =
		player.Character

	if not character then
		return
	end

	local targetRoot =
		character:FindFirstChild(
			"HumanoidRootPart"
		)

	local head =
		character:FindFirstChild(
			"Head"
		)

	if not targetRoot
		or not head
	then
		return
	end

	local Billboard =
		getESP(player)

	if not Billboard
		and (
			espNameEnabled
			or
			espDistanceEnabled
		)
	then

		Billboard =
			createESP(player)

	end

	if not Billboard then
		return
	end

	local NameLabel =
		Billboard:FindFirstChild(
			"NameLabel"
		)

	local DistanceLabel =
		Billboard:FindFirstChild(
			"DistanceLabel"
		)

	if NameLabel then

		NameLabel.Visible =
			espNameEnabled

		NameLabel.Text =
			player.DisplayName
			..
			" [@"
			..
			player.Name
			..
			"]"

		-- Atualiza a cor do nome em tempo real conforme a Tool detectada.
		NameLabel.TextColor3 =
			getPlayerWeaponColor(
				player
			)

	end

	if DistanceLabel then

		DistanceLabel.Visible =
			espDistanceEnabled

		if espDistanceEnabled then

			local localCharacter =
				LocalPlayer.Character

			local localRoot =
				localCharacter
				and
				localCharacter:
				FindFirstChild(
					"HumanoidRootPart"
				)

			if localRoot then

				local distance =
					(
						localRoot.Position
						-
						targetRoot.Position
					).Magnitude

				distance =
					math.floor(
						distance + 0.5
					)

				DistanceLabel.Text =
					"[ "
					..
					tostring(distance)
					..
					" studs ]"

			else

				DistanceLabel.Text =
					"[ ? studs ]"

			end

		end

	end

end

--========================================================--
-- REMOVER ESP
--========================================================--

local function removeESP(player)

	local ESP =
		getESP(player)

	if ESP then
		ESP:Destroy()
	end

end


local function removeAllESP()

	for _, player
		in ipairs(
			Players:GetPlayers()
		)
	do

		removeESP(player)

	end

end

--========================================================--
-- ESP GUNDROP
--========================================================--

local GUNDROP_COLOR =
	Color3.fromRGB(
		255,
		140,
		0
	)


-- Verifica se um objeto está dentro do Character de algum jogador.
-- Isso é importante porque, quando a arma é pega/equipada, ela pode
-- continuar existindo dentro da Workspace, mas passa a ficar dentro
-- do Model do jogador. Nesse caso ela NÃO deve mais ser tratada como drop.
local function isInsidePlayerCharacter(instance)

	if not instance then
		return false
	end

	for _, player
		in ipairs(
			Players:GetPlayers()
		)
	do

		local character =
			player.Character

		if character
			and instance:IsDescendantOf(character)
		then

			return true

		end

	end

	return false

end


local function isValidGunDrop(gunDrop)

	if not gunDrop
		or not gunDrop.Parent
	then

		return false

	end

	-- Precisa continuar realmente dentro da Workspace.
	if not gunDrop:IsDescendantOf(workspace) then
		return false
	end

	-- Se foi equipado por algum jogador, deixa de ser um drop válido.
	if isInsidePlayerCharacter(gunDrop) then
		return false
	end

	-- Proteção extra caso GunDrop seja um filho de uma Tool equipada.
	local toolAncestor =
		gunDrop:FindFirstAncestorOfClass(
			"Tool"
		)

	if toolAncestor
		and isInsidePlayerCharacter(toolAncestor)
	then

		return false

	end

	return true

end


local function findGunDrop()

	-- Procura em qualquer lugar da Workspace, mas ignora GunDrop
	-- que já tenha sido pego e esteja dentro do Character de alguém.
	for _, object
		in ipairs(
			workspace:GetDescendants()
		)
	do

		if object.Name == "GunDrop"
			and isValidGunDrop(object)
		then

			return object

		end

	end

	return nil

end


local function getGunDropAdornee(gunDrop)

	if not gunDrop then
		return nil
	end

	-- Caso o próprio GunDrop seja uma Part/MeshPart/etc.
	if gunDrop:IsA("BasePart") then
		return gunDrop
	end

	-- Caso seja Tool, tenta primeiro o Handle.
	if gunDrop:IsA("Tool") then

		local handle =
			gunDrop:FindFirstChild(
				"Handle"
			)

		if handle
			and handle:IsA("BasePart")
		then
			return handle
		end

	end

	-- Caso seja Model, usa PrimaryPart quando existir.
	if gunDrop:IsA("Model")
		and gunDrop.PrimaryPart
	then
		return gunDrop.PrimaryPart
	end

	-- Fallback para qualquer BasePart dentro do GunDrop.
	return gunDrop:FindFirstChildWhichIsA(
		"BasePart",
		true
	)

end


-- Remove qualquer ESP antigo que tenha ficado órfão na Workspace.
-- Isso resolve casos em que a arma foi coletada/reparentada e a referência
-- local do Billboard ficou desatualizada.
local function removeStaleGunDropBillboards()

	for _, object
		in ipairs(
			workspace:GetDescendants()
		)
	do

		if object:IsA("BillboardGui")
			and object.Name == "B1tSampl3_GunDropESP"
		then

			pcall(
				function()
					object:Destroy()
				end
			)

		end

	end

end


local function removeGunDropESP()

	if GunDropBillboard then

		pcall(
			function()
				GunDropBillboard:Destroy()
			end
		)

	end

	-- Limpa também qualquer Billboard órfão que tenha sobrado.
	removeStaleGunDropBillboards()

	GunDropBillboard = nil
	CurrentGunDrop = nil
	gunDropFound = false

end


local function createGunDropESP(gunDrop)

	if not isValidGunDrop(gunDrop) then
		return nil
	end

	local adornee =
		getGunDropAdornee(
			gunDrop
		)

	if not adornee
		or not adornee.Parent
	then
		return nil
	end

	removeGunDropESP()

	CurrentGunDrop =
		gunDrop

	gunDropFound =
		true

	local Billboard =
		Instance.new(
			"BillboardGui"
		)

	Billboard.Name =
		"B1tSampl3_GunDropESP"

	Billboard.Adornee =
		adornee

	Billboard.Size =
		UDim2.new(
			0,
			220,
			0,
			60
		)

	Billboard.StudsOffset =
		Vector3.new(
			0,
			2.5,
			0
		)

	Billboard.AlwaysOnTop =
		true

	Billboard.MaxDistance =
		5000

	Billboard.Parent =
		adornee

	local NameLabel =
		Instance.new(
			"TextLabel"
		)

	NameLabel.Name =
		"DropNameLabel"

	NameLabel.Size =
		UDim2.new(
			1,
			0,
			0,
			30
		)

	NameLabel.BackgroundTransparency =
		1

	NameLabel.Text =
		"GUN DROP"

	NameLabel.TextColor3 =
		GUNDROP_COLOR

	NameLabel.TextStrokeColor3 =
		Color3.fromRGB(
			0,
			0,
			0
		)

	NameLabel.TextStrokeTransparency =
		0

	NameLabel.TextSize =
		17

	NameLabel.Font =
		Enum.Font.GothamBold

	NameLabel.Parent =
		Billboard

	local DistanceLabel =
		Instance.new(
			"TextLabel"
		)

	DistanceLabel.Name =
		"DropDistanceLabel"

	DistanceLabel.Size =
		UDim2.new(
			1,
			0,
			0,
			25
		)

	DistanceLabel.Position =
		UDim2.new(
			0,
			0,
			0,
			28
		)

	DistanceLabel.BackgroundTransparency =
		1

	DistanceLabel.Text =
		"[ ? studs ]"

	DistanceLabel.TextColor3 =
		GUNDROP_COLOR

	DistanceLabel.TextStrokeColor3 =
		Color3.fromRGB(
			0,
			0,
			0
		)

	DistanceLabel.TextStrokeTransparency =
		0

	DistanceLabel.TextSize =
		14

	DistanceLabel.Font =
		Enum.Font.GothamBold

	DistanceLabel.Parent =
		Billboard

	GunDropBillboard =
		Billboard

	return Billboard

end


local function updateGunDropESP()

	if not gunDropESPEnabled then

		removeGunDropESP()
		return

	end

	local gunDrop =
		findGunDrop()

	-- Nenhum drop válido existe mais: remove o ESP imediatamente.
	if not gunDrop then

		removeGunDropESP()
		return

	end

	-- Se a referência anterior foi pega/equipada, ela deixa de ser válida.
	if CurrentGunDrop
		and not isValidGunDrop(CurrentGunDrop)
	then

		removeGunDropESP()

	end

	local adornee =
		getGunDropAdornee(
			gunDrop
		)

	if not adornee
		or not adornee.Parent
		or not adornee:IsDescendantOf(workspace)
		or isInsidePlayerCharacter(adornee)
	then

		removeGunDropESP()
		return

	end

	-- Se apareceu outra GunDrop, o Billboard sumiu, ou o Billboard ficou
	-- preso em uma peça antiga, recria do zero.
	if CurrentGunDrop ~= gunDrop
		or not GunDropBillboard
		or not GunDropBillboard.Parent
		or GunDropBillboard.Adornee ~= adornee
	then

		createGunDropESP(
			gunDrop
		)

	end

	if not GunDropBillboard
		or not GunDropBillboard.Parent
	then
		return
	end

	-- Validação final a cada atualização para evitar ESP fantasma.
	if not isValidGunDrop(gunDrop)
		or isInsidePlayerCharacter(gunDrop)
	then

		removeGunDropESP()
		return

	end

	gunDropFound =
		true

	local DistanceLabel =
		GunDropBillboard:FindFirstChild(
			"DropDistanceLabel"
		)

	local localCharacter =
		LocalPlayer.Character

	local localRoot =
		localCharacter
		and localCharacter:FindFirstChild(
			"HumanoidRootPart"
		)

	if DistanceLabel
		and localRoot
	then

		local distance =
			(
				localRoot.Position
				-
				adornee.Position
			).Magnitude

		distance =
			math.floor(
				distance + 0.5
			)

		DistanceLabel.Text =
			"[ "
			..
			tostring(distance)
			..
			" studs ]"

	elseif DistanceLabel then

		DistanceLabel.Text =
			"[ ? studs ]"

	end

end

--========================================================--
-- GUI
--========================================================--

local oldGUI =
	PlayerGui:FindFirstChild(
		"B1tSampl3HubController"
	)

if oldGUI then
	oldGUI:Destroy()
end


local ScreenGui =
	Instance.new(
		"ScreenGui"
	)

ScreenGui.Name =
	"B1tSampl3HubController"

ScreenGui.ResetOnSpawn =
	false

ScreenGui.ZIndexBehavior =
	Enum.ZIndexBehavior.Sibling

ScreenGui.Parent =
	PlayerGui

--========================================================--
-- JANELA
--========================================================--

local NORMAL_SIZE =
	UDim2.new(
		0,
		370,
		0,
		920
	)

local MINIMIZED_SIZE =
	UDim2.new(
		0,
		370,
		0,
		45
	)


local MainFrame =
	Instance.new(
		"Frame"
	)

MainFrame.Size =
	NORMAL_SIZE

MainFrame.Position =
	UDim2.new(
		0,
		30,
		0,
		80
	)

MainFrame.BackgroundColor3 =
	Color3.fromRGB(
		25,
		25,
		25
	)

MainFrame.BorderSizePixel =
	0

MainFrame.ClipsDescendants =
	true

MainFrame.Parent =
	ScreenGui


local MainCorner =
	Instance.new(
		"UICorner"
	)

MainCorner.CornerRadius =
	UDim.new(
		0,
		12
	)

MainCorner.Parent =
	MainFrame

--========================================================--
-- TOP BAR
--========================================================--

local TopBar =
	Instance.new(
		"Frame"
	)

TopBar.Size =
	UDim2.new(
		1,
		0,
		0,
		45
	)

TopBar.BackgroundColor3 =
	Color3.fromRGB(
		18,
		18,
		18
	)

TopBar.BorderSizePixel =
	0

TopBar.Active =
	true

TopBar.Parent =
	MainFrame


local Title =
	Instance.new(
		"TextLabel"
	)

Title.Size =
	UDim2.new(
		1,
		-110,
		1,
		0
	)

Title.Position =
	UDim2.new(
		0,
		15,
		0,
		0
	)

Title.BackgroundTransparency =
	1

Title.Text =
	"B1tSampl3 HUB"

Title.TextColor3 =
	Color3.fromRGB(
		0,
		255,
		100
	)

Title.TextSize =
	19

Title.Font =
	Enum.Font.GothamBold

Title.TextXAlignment =
	Enum.TextXAlignment.Left

Title.Parent =
	TopBar

--========================================================--
-- MINIMIZAR
--========================================================--

local MinimizeButton =
	Instance.new(
		"TextButton"
	)

MinimizeButton.Size =
	UDim2.new(
		0,
		30,
		0,
		30
	)

MinimizeButton.Position =
	UDim2.new(
		1,
		-76,
		0,
		7
	)

MinimizeButton.BackgroundColor3 =
	Color3.fromRGB(
		70,
		70,
		70
	)

MinimizeButton.Text =
	"—"

MinimizeButton.TextColor3 =
	Color3.new(
		1,
		1,
		1
	)

MinimizeButton.TextSize =
	18

MinimizeButton.Font =
	Enum.Font.GothamBold

MinimizeButton.Parent =
	TopBar


local MinimizeCorner =
	Instance.new(
		"UICorner"
	)

MinimizeCorner.CornerRadius =
	UDim.new(
		1,
		0
	)

MinimizeCorner.Parent =
	MinimizeButton

--========================================================--
-- FECHAR
--========================================================--

local CloseButton =
	Instance.new(
		"TextButton"
	)

CloseButton.Size =
	UDim2.new(
		0,
		30,
		0,
		30
	)

CloseButton.Position =
	UDim2.new(
		1,
		-38,
		0,
		7
	)

CloseButton.BackgroundColor3 =
	Color3.fromRGB(
		220,
		50,
		50
	)

CloseButton.Text =
	"X"

CloseButton.TextColor3 =
	Color3.new(
		1,
		1,
		1
	)

CloseButton.TextSize =
	15

CloseButton.Font =
	Enum.Font.GothamBold

CloseButton.Parent =
	TopBar


local CloseCorner =
	Instance.new(
		"UICorner"
	)

CloseCorner.CornerRadius =
	UDim.new(
		1,
		0
	)

CloseCorner.Parent =
	CloseButton

--========================================================--
-- ÁREA DE CONTEÚDO
--========================================================--

local Content =
	Instance.new(
		"Frame"
	)

Content.Size =
	UDim2.new(
		1,
		0,
		1,
		-45
	)

Content.Position =
	UDim2.new(
		0,
		0,
		0,
		45
	)

Content.BackgroundTransparency =
	1

Content.Parent =
	MainFrame

--========================================================--
-- FUNÇÕES DE UI
--========================================================--

local function addCorner(object, radius)

	local corner =
		Instance.new(
			"UICorner"
		)

	corner.CornerRadius =
		UDim.new(
			0,
			radius or 8
		)

	corner.Parent =
		object

	return corner

end


local function newLabel(
	text,
	y
)

	local label =
		Instance.new(
			"TextLabel"
		)

	label.Size =
		UDim2.new(
			1,
			-30,
			0,
			30
		)

	label.Position =
		UDim2.new(
			0,
			15,
			0,
			y
		)

	label.BackgroundTransparency =
		1

	label.Text =
		text

	label.TextColor3 =
		Color3.new(
			1,
			1,
			1
		)

	label.TextSize =
		15

	label.Font =
		Enum.Font.GothamBold

	label.Parent =
		Content

	return label

end


local function newButton(
	text,
	y
)

	local button =
		Instance.new(
			"TextButton"
		)

	button.Size =
		UDim2.new(
			0.82,
			0,
			0,
			40
		)

	button.Position =
		UDim2.new(
			0.09,
			0,
			0,
			y
		)

	button.BackgroundColor3 =
		Color3.fromRGB(
			45,
			100,
			190
		)

	button.Text =
		text

	button.TextColor3 =
		Color3.new(
			1,
			1,
			1
		)

	button.TextSize =
		15

	button.Font =
		Enum.Font.GothamBold

	button.Parent =
		Content

	addCorner(
		button,
		8
	)

	return button

end


local function newSmallButton(
	text,
	x,
	y
)

	local button =
		Instance.new(
			"TextButton"
		)

	button.Size =
		UDim2.new(
			0,
			55,
			0,
			34
		)

	button.Position =
		UDim2.new(
			0,
			x,
			0,
			y
		)

	button.BackgroundColor3 =
		Color3.fromRGB(
			65,
			65,
			65
		)

	button.Text =
		text

	button.TextColor3 =
		Color3.new(
			1,
			1,
			1
		)

	button.TextSize =
		20

	button.Font =
		Enum.Font.GothamBold

	button.Parent =
		Content

	addCorner(
		button,
		7
	)

	return button

end

--========================================================--
-- HITBOX UI
--========================================================--

local HitboxStatus =
	newLabel(
		"HitBox: DESATIVADA",
		8
	)


local ToggleHitbox =
	newButton(
		"ATIVAR HITBOX",
		38
	)


local SizeLabel =
	newLabel(
		"Tamanho: 11",
		88
	)


local SizeMinus =
	newSmallButton(
		"-",
		120,
		118
	)


local SizePlus =
	newSmallButton(
		"+",
		195,
		118
	)


local TransparencyLabel =
	newLabel(
		"Transparência: 0.8",
		160
	)


local TransparencyMinus =
	newSmallButton(
		"-",
		120,
		190
	)


local TransparencyPlus =
	newSmallButton(
		"+",
		195,
		190
	)

--========================================================--
-- ESP NAME
--========================================================--

local ESPNameStatus =
	newLabel(
		"ESP Name: DESATIVADO",
		235
	)


local ToggleESPName =
	newButton(
		"ATIVAR ESP NAME",
		265
	)

--========================================================--
-- ESP DISTÂNCIA
--========================================================--

local ESPDistanceStatus =
	newLabel(
		"ESP Distância: DESATIVADO",
		315
	)


local ToggleESPDistance =
	newButton(
		"ATIVAR ESP DISTÂNCIA",
		345
	)

--========================================================--
-- ESP GUNDROP
--========================================================--

local GunDropStatus =
	newLabel(
		"GunDrop ESP: DESATIVADO",
		395
	)


local ToggleGunDropESP =
	newButton(
		"ATIVAR ESP GUN DROP",
		425
	)

ToggleGunDropESP.BackgroundColor3 =
	Color3.fromRGB(
		210,
		120,
		20
	)

--========================================================--
-- AIMLOCK
--========================================================--

local AimStatus =
	newLabel(
		"AimLock: DESATIVADO",
		475
	)


local ToggleAim =
	newButton(
		"ATIVAR AIMLOCK",
		505
	)


local TargetButton =
	newButton(
		"Alvo: NENHUM",
		555
	)


local AimDistanceLabel =
	newLabel(
		"Distância Aim: "
		..
		AIM_MAX_DISTANCE
		..
		" studs",
		605
	)


local AimDistanceMinus =
	newSmallButton(
		"-",
		120,
		635
	)


local AimDistancePlus =
	newSmallButton(
		"+",
		195,
		635
	)

--========================================================--
-- TECLA DO AIMLOCK
--========================================================--

local AimKeybindLabel =
	newLabel(
		"Tecla AimLock: Q",
		680
	)


local AimKeybindButton =
	newButton(
		"DEFINIR TECLA",
		710
	)

--========================================================--
-- LISTA DE JOGADORES
--========================================================--

local PlayerList =
	Instance.new(
		"ScrollingFrame"
	)

PlayerList.Size =
	UDim2.new(
		0.82,
		0,
		0,
		145
	)

PlayerList.Position =
	UDim2.new(
		0.09,
		0,
		0,
		595
	)

PlayerList.BackgroundColor3 =
	Color3.fromRGB(
		15,
		15,
		15
	)

PlayerList.BorderSizePixel =
	0

PlayerList.ScrollBarThickness =
	5

PlayerList.AutomaticCanvasSize =
	Enum.AutomaticSize.Y

PlayerList.CanvasSize =
	UDim2.new()

PlayerList.Visible =
	false

PlayerList.ZIndex =
	20

PlayerList.Parent =
	Content

addCorner(
	PlayerList,
	8
)


local PlayerListLayout =
	Instance.new(
		"UIListLayout"
	)

PlayerListLayout.Padding =
	UDim.new(
		0,
		5
	)

PlayerListLayout.Parent =
	PlayerList


local PlayerListPadding =
	Instance.new(
		"UIPadding"
	)

PlayerListPadding.PaddingTop =
	UDim.new(
		0,
		5
	)

PlayerListPadding.PaddingBottom =
	UDim.new(
		0,
		5
	)

PlayerListPadding.PaddingLeft =
	UDim.new(
		0,
		5
	)

PlayerListPadding.PaddingRight =
	UDim.new(
		0,
		5
	)

PlayerListPadding.Parent =
	PlayerList

--========================================================--
-- INFORMAÇÃO AIMLOCK
--========================================================--

local AimInfo =
	newLabel(
		"Segure botão direito para travar no alvo",
		765
	)

AimInfo.TextColor3 =
	Color3.fromRGB(
		160,
		160,
		160
	)

AimInfo.TextSize =
	12

--========================================================--
-- ATUALIZAR INTERFACE
--========================================================--

local function updateInterface()

	SizeLabel.Text =
		"Tamanho: "
		..
		tostring(
			HITBOX_SIZE
		)

	TransparencyLabel.Text =
		"Transparência: "
		..
		string.format(
			"%.1f",
			HITBOX_TRANSPARENCY
		)

	AimDistanceLabel.Text =
		"Distância Aim: "
		..
		tostring(
			AIM_MAX_DISTANCE
		)
		..
		" studs"

	--------------------------------------------------
	-- HITBOX
	--------------------------------------------------

	if hitboxEnabled then

		HitboxStatus.Text =
			"HitBox: ATIVADA"

		HitboxStatus.TextColor3 =
			Color3.fromRGB(
				80,
				255,
				100
			)

		ToggleHitbox.Text =
			"DESATIVAR HITBOX"

		ToggleHitbox.BackgroundColor3 =
			Color3.fromRGB(
				190,
				55,
				55
			)

	else

		HitboxStatus.Text =
			"HitBox: DESATIVADA"

		HitboxStatus.TextColor3 =
			Color3.fromRGB(
				255,
				80,
				80
			)

		ToggleHitbox.Text =
			"ATIVAR HITBOX"

		ToggleHitbox.BackgroundColor3 =
			Color3.fromRGB(
				30,
				160,
				70
			)

	end

	--------------------------------------------------
	-- ESP NAME
	--------------------------------------------------

	if espNameEnabled then

		ESPNameStatus.Text =
			"ESP Name: ATIVADO"

		ESPNameStatus.TextColor3 =
			Color3.fromRGB(
				80,
				255,
				100
			)

		ToggleESPName.Text =
			"DESATIVAR ESP NAME"

		ToggleESPName.BackgroundColor3 =
			Color3.fromRGB(
				190,
				55,
				55
			)

	else

		ESPNameStatus.Text =
			"ESP Name: DESATIVADO"

		ESPNameStatus.TextColor3 =
			Color3.fromRGB(
				255,
				80,
				80
			)

		ToggleESPName.Text =
			"ATIVAR ESP NAME"

		ToggleESPName.BackgroundColor3 =
			Color3.fromRGB(
				45,
				100,
				190
			)

	end

	--------------------------------------------------
	-- ESP DISTÂNCIA
	--------------------------------------------------

	if espDistanceEnabled then

		ESPDistanceStatus.Text =
			"ESP Distância: ATIVADO"

		ESPDistanceStatus.TextColor3 =
			Color3.fromRGB(
				80,
				255,
				100
			)

		ToggleESPDistance.Text =
			"DESATIVAR ESP DISTÂNCIA"

		ToggleESPDistance.BackgroundColor3 =
			Color3.fromRGB(
				190,
				55,
				55
			)

	else

		ESPDistanceStatus.Text =
			"ESP Distância: DESATIVADO"

		ESPDistanceStatus.TextColor3 =
			Color3.fromRGB(
				255,
				80,
				80
			)

		ToggleESPDistance.Text =
			"ATIVAR ESP DISTÂNCIA"

		ToggleESPDistance.BackgroundColor3 =
			Color3.fromRGB(
				45,
				100,
				190
			)

	end

	--------------------------------------------------
	-- ESP GUNDROP
	--------------------------------------------------

	if gunDropESPEnabled then

		if gunDropFound then

			GunDropStatus.Text =
				"GunDrop ESP: ARMA ENCONTRADA"

			GunDropStatus.TextColor3 =
				Color3.fromRGB(
					255,
					160,
					30
				)

		else

			GunDropStatus.Text =
				"GunDrop ESP: PROCURANDO..."

			GunDropStatus.TextColor3 =
				Color3.fromRGB(
					255,
					190,
					80
				)

		end

		ToggleGunDropESP.Text =
			"DESATIVAR ESP GUN DROP"

		ToggleGunDropESP.BackgroundColor3 =
			Color3.fromRGB(
				190,
				55,
				55
			)

	else

		GunDropStatus.Text =
			"GunDrop ESP: DESATIVADO"

		GunDropStatus.TextColor3 =
			Color3.fromRGB(
				255,
				80,
				80
			)

		ToggleGunDropESP.Text =
			"ATIVAR ESP GUN DROP"

		ToggleGunDropESP.BackgroundColor3 =
			Color3.fromRGB(
				210,
				120,
				20
			)

	end

	--------------------------------------------------
	-- TECLA DO AIMLOCK
	--------------------------------------------------

	if waitingAimKeybind then

		AimKeybindLabel.Text =
			"Tecla AimLock: aguardando..."

		AimKeybindLabel.TextColor3 =
			Color3.fromRGB(
				255,
				200,
				70
			)

		AimKeybindButton.Text =
			"PRESSIONE UMA TECLA..."

		AimKeybindButton.BackgroundColor3 =
			Color3.fromRGB(
				190,
				130,
				30
			)

	else

		AimKeybindLabel.Text =
			"Tecla AimLock: "
			..
			AIM_TOGGLE_KEY.Name

		AimKeybindLabel.TextColor3 =
			Color3.fromRGB(
				255,
				255,
				255
			)

		AimKeybindButton.Text =
			"DEFINIR TECLA"

		AimKeybindButton.BackgroundColor3 =
			Color3.fromRGB(
				80,
				80,
				160
			)

	end

	--------------------------------------------------
	-- AIMLOCK
	--------------------------------------------------

	if aimlockEnabled then

		AimStatus.Text =
			"AimLock: ATIVADO"

		AimStatus.TextColor3 =
			Color3.fromRGB(
				80,
				255,
				100
			)

		ToggleAim.Text =
			"DESATIVAR AIMLOCK"

		ToggleAim.BackgroundColor3 =
			Color3.fromRGB(
				190,
				55,
				55
			)

	else

		AimStatus.Text =
			"AimLock: DESATIVADO"

		AimStatus.TextColor3 =
			Color3.fromRGB(
				255,
				80,
				80
			)

		ToggleAim.Text =
			"ATIVAR AIMLOCK"

		ToggleAim.BackgroundColor3 =
			Color3.fromRGB(
				45,
				100,
				190
			)

	end

	if selectedTarget
		and selectedTarget.Parent
	then

		TargetButton.Text =
			"Alvo: "
			..
			selectedTarget.DisplayName

	else

		selectedTarget =
			nil

		TargetButton.Text =
			"Alvo: NENHUM"

	end

end

--========================================================--
-- LISTA DE JOGADORES
--========================================================--

local function refreshPlayerList()

	for _, object
		in ipairs(
			PlayerList:GetChildren()
		)
	do

		if object:IsA(
			"TextButton"
		) then

			object:Destroy()

		end

	end

	for _, player
		in ipairs(
			Players:GetPlayers()
		)
	do

		if player ~= LocalPlayer then

			local PlayerButton =
				Instance.new(
					"TextButton"
				)

			PlayerButton.Size =
				UDim2.new(
					1,
					-10,
					0,
					35
				)

			PlayerButton.BackgroundColor3 =
				Color3.fromRGB(
					45,
					45,
					45
				)

			PlayerButton.Text =
				player.DisplayName
				..
				" [@"
				..
				player.Name
				..
				"]"

			PlayerButton.TextColor3 =
				Color3.new(
					1,
					1,
					1
				)

			PlayerButton.TextSize =
				13

			PlayerButton.Font =
				Enum.Font.Gotham

			PlayerButton.ZIndex =
				21

			PlayerButton.Parent =
				PlayerList

			addCorner(
				PlayerButton,
				6
			)

			trackConnection(
				PlayerButton
				.MouseButton1Click:
				Connect(
					function()

						selectedTarget =
							player

						PlayerList.Visible =
							false

						updateInterface()

					end
				)
			)

		end

	end

end

--========================================================--
-- HITBOX CONTROLES
--========================================================--

trackConnection(
	ToggleHitbox
		.MouseButton1Click:
		Connect(
			function()

				hitboxEnabled =
					not hitboxEnabled

				if not hitboxEnabled then

					restoreAllHitboxes()

				end

				updateInterface()

			end
		)
)


trackConnection(
	SizeMinus
		.MouseButton1Click:
		Connect(
			function()

				HITBOX_SIZE =
					math.max(
						MIN_SIZE,
						HITBOX_SIZE
						-
						SIZE_STEP
					)

				updateInterface()

			end
		)
)


trackConnection(
	SizePlus
		.MouseButton1Click:
		Connect(
			function()

				HITBOX_SIZE =
					math.min(
						MAX_SIZE,
						HITBOX_SIZE
						+
						SIZE_STEP
					)

				updateInterface()

			end
		)
)


trackConnection(
	TransparencyMinus
		.MouseButton1Click:
		Connect(
			function()

				HITBOX_TRANSPARENCY =
					math.max(

						MIN_TRANSPARENCY,

						HITBOX_TRANSPARENCY
						-
						TRANSPARENCY_STEP

					)

				HITBOX_TRANSPARENCY =
					math.round(
						HITBOX_TRANSPARENCY
						*
						10
					)
					/
					10

				updateInterface()

			end
		)
)


trackConnection(
	TransparencyPlus
		.MouseButton1Click:
		Connect(
			function()

				HITBOX_TRANSPARENCY =
					math.min(

						MAX_TRANSPARENCY,

						HITBOX_TRANSPARENCY
						+
						TRANSPARENCY_STEP

					)

				HITBOX_TRANSPARENCY =
					math.round(
						HITBOX_TRANSPARENCY
						*
						10
					)
					/
					10

				updateInterface()

			end
		)
)

--========================================================--
-- ESP CONTROLES
--========================================================--

trackConnection(
	ToggleESPName
		.MouseButton1Click:
		Connect(
			function()

				espNameEnabled =
					not espNameEnabled

				if not espNameEnabled
					and not espDistanceEnabled
				then

					removeAllESP()

				end

				updateInterface()

			end
		)
)


trackConnection(
	ToggleESPDistance
		.MouseButton1Click:
		Connect(
			function()

				espDistanceEnabled =
					not espDistanceEnabled

				if not espNameEnabled
					and not espDistanceEnabled
				then

					removeAllESP()

				end

				updateInterface()

			end
		)
)

trackConnection(
	ToggleGunDropESP
		.MouseButton1Click:
		Connect(
			function()

				gunDropESPEnabled =
					not gunDropESPEnabled

				if gunDropESPEnabled then

					updateGunDropESP()

				else

					removeGunDropESP()

				end

				updateInterface()

			end
		)
)

--========================================================--
-- AIMLOCK CONTROLES
--========================================================--

local function toggleAimlock()

	aimlockEnabled =
		not aimlockEnabled

	if not aimlockEnabled then

		rightMouseHeld =
			false

		UserInputService.MouseBehavior =
			Enum.MouseBehavior.Default

	end

	updateInterface()

end


trackConnection(
	ToggleAim
		.MouseButton1Click:
		Connect(
			function()

				toggleAimlock()

			end
		)
)


trackConnection(
	AimKeybindButton
		.MouseButton1Click:
		Connect(
			function()

				waitingAimKeybind =
					not waitingAimKeybind

				updateInterface()

			end
		)
)


trackConnection(
	TargetButton
		.MouseButton1Click:
		Connect(
			function()

				refreshPlayerList()

				PlayerList.Visible =
					not PlayerList.Visible

			end
		)
)


trackConnection(
	AimDistanceMinus
		.MouseButton1Click:
		Connect(
			function()

				AIM_MAX_DISTANCE =
					math.max(

						AIM_MIN_DISTANCE,

						AIM_MAX_DISTANCE
						-
						AIM_DISTANCE_STEP

					)

				updateInterface()

			end
		)
)


trackConnection(
	AimDistancePlus
		.MouseButton1Click:
		Connect(
			function()

				AIM_MAX_DISTANCE =
					math.min(

						AIM_MAX_LIMIT,

						AIM_MAX_DISTANCE
						+
						AIM_DISTANCE_STEP

					)

				updateInterface()

			end
		)
)

--========================================================--
-- MINIMIZAR
--========================================================--

trackConnection(
	MinimizeButton
		.MouseButton1Click:
		Connect(
			function()

				minimized =
					not minimized

				Content.Visible =
					not minimized

				if minimized then

					MainFrame.Size =
						MINIMIZED_SIZE

					MinimizeButton.Text =
						"+"

				else

					MainFrame.Size =
						NORMAL_SIZE

					MinimizeButton.Text =
						"—"

				end

			end
		)
)

--========================================================--
-- ARRASTAR JANELA
--========================================================--

local dragging = false
local dragInput = nil
local dragStart = nil
local startPosition = nil


trackConnection(
	TopBar.InputBegan:
		Connect(
			function(input)

				if input.UserInputType
						==
						Enum.UserInputType.MouseButton1

					or

					input.UserInputType
						==
						Enum.UserInputType.Touch
				then

					dragging =
						true

					dragStart =
						input.Position

					startPosition =
						MainFrame.Position

				end

			end
		)
)


trackConnection(
	TopBar.InputChanged:
		Connect(
			function(input)

				if input.UserInputType
						==
						Enum.UserInputType.MouseMovement

					or

					input.UserInputType
						==
						Enum.UserInputType.Touch
				then

					dragInput =
						input

				end

			end
		)
)


trackConnection(
	UserInputService.InputChanged:
		Connect(
			function(input)

				if dragging
					and input
						==
						dragInput
				then

					local delta =
						input.Position
						-
						dragStart

					MainFrame.Position =
						UDim2.new(

							startPosition.X.Scale,

							startPosition.X.Offset
								+
								delta.X,

							startPosition.Y.Scale,

							startPosition.Y.Offset
								+
								delta.Y

						)

				end

			end
		)
)


trackConnection(
	UserInputService.InputEnded:
		Connect(
			function(input)

				if input.UserInputType
						==
						Enum.UserInputType.MouseButton1

					or

					input.UserInputType
						==
						Enum.UserInputType.Touch
				then

					dragging =
						false

				end

			end
		)
)

--========================================================--
-- BOTÃO DIREITO DO MOUSE
--========================================================--

trackConnection(
	UserInputService.InputBegan:
		Connect(
			function(
				input,
				gameProcessed
			)

				--------------------------------------------------
				-- DEFINIR NOVA TECLA DO AIMLOCK
				--------------------------------------------------

				if waitingAimKeybind then

					if input.UserInputType
						==
						Enum.UserInputType.Keyboard
					then

						if input.KeyCode
							==
							Enum.KeyCode.Escape
						then

							-- ESC apenas cancela a troca de tecla.
							waitingAimKeybind =
								false

						else

							AIM_TOGGLE_KEY =
								input.KeyCode

							waitingAimKeybind =
								false

						end

						updateInterface()

						return

					end

				end

				if gameProcessed then
					return
				end

				--------------------------------------------------
				-- ATIVAR / DESATIVAR AIMLOCK PELA TECLA
				--------------------------------------------------

				if input.UserInputType
					==
					Enum.UserInputType.Keyboard
					and input.KeyCode
						==
						AIM_TOGGLE_KEY
				then

					toggleAimlock()

					return

				end

				--------------------------------------------------
				-- BOTÃO DIREITO PARA TRAVAR NO ALVO
				--------------------------------------------------

				if input.UserInputType
					==
					Enum.UserInputType.MouseButton2
				then

					rightMouseHeld =
						true

				end

			end
		)
)


trackConnection(
	UserInputService.InputEnded:
		Connect(
			function(input)

				if input.UserInputType
					==
					Enum.UserInputType.MouseButton2
				then

					rightMouseHeld =
						false

					UserInputService.MouseBehavior =
						Enum.MouseBehavior.Default

				end

			end
		)
)

--========================================================--
-- LOOP HITBOX
--========================================================--

trackConnection(
	RunService.RenderStepped:
		Connect(
			function()

				if destroyed
					or not hitboxEnabled
				then
					return
				end

				for _, player
					in ipairs(
						Players:GetPlayers()
					)
				do

					if player ~= LocalPlayer then

						pcall(
							function()

								applyHitbox(
									player
								)

							end
						)

					end

				end

			end
		)
)

--========================================================--
-- LOOP ESP
--========================================================--

local espTimer = 0


trackConnection(
	RunService.Heartbeat:
		Connect(
			function(deltaTime)

				if destroyed then
					return
				end

				espTimer =
					espTimer
					+
					deltaTime

				if espTimer < 0.1 then
					return
				end

				espTimer = 0

				if gunDropESPEnabled then

					updateGunDropESP()
					updateInterface()

				end

				if not espNameEnabled
					and not espDistanceEnabled
				then
					return
				end

				for _, player
					in ipairs(
						Players:GetPlayers()
					)
				do

					if player ~= LocalPlayer then

						pcall(
							function()

								updateESP(
									player
								)

							end
						)

					end

				end

			end
		)
)

--========================================================--
-- AIMLOCK
--========================================================--

local AIM_RENDER_NAME =
	"B1tSampl3_AimLock"


RunService:BindToRenderStep(

	AIM_RENDER_NAME,

	Enum.RenderPriority.Camera.Value + 1,

	function()

		if destroyed then
			return
		end

		if not aimlockEnabled
			or not rightMouseHeld
		then
			return
		end

		if not selectedTarget
			or not selectedTarget.Parent
		then

			selectedTarget =
				nil

			UserInputService.MouseBehavior =
				Enum.MouseBehavior.Default

			updateInterface()

			return

		end

		local localCharacter =
			LocalPlayer.Character

		local targetCharacter =
			selectedTarget.Character

		if not localCharacter
			or not targetCharacter
		then
			return
		end

		local localRoot =
			localCharacter:
			FindFirstChild(
				"HumanoidRootPart"
			)

		local targetRoot =
			targetCharacter:
			FindFirstChild(
				"HumanoidRootPart"
			)

		local targetHead =
			targetCharacter:
			FindFirstChild(
				"Head"
			)

		local humanoid =
			targetCharacter:
			FindFirstChildOfClass(
				"Humanoid"
			)

		if not localRoot
			or not targetRoot
			or not targetHead
			or not humanoid
		then
			return
		end

		if humanoid.Health <= 0 then
			return
		end

		local distance =
			(
				localRoot.Position
				-
				targetRoot.Position
			).Magnitude

		if distance >
			AIM_MAX_DISTANCE
		then

			UserInputService.MouseBehavior =
				Enum.MouseBehavior.Default

			return

		end

		UserInputService.MouseBehavior =
			Enum.MouseBehavior.LockCenter

		Camera =
			workspace.CurrentCamera

		if Camera then

			local cameraPosition =
				Camera.CFrame.Position

			Camera.CFrame =
				CFrame.lookAt(

					cameraPosition,

					targetHead.Position

				)

		end

	end

)

--========================================================--
-- PLAYERS ENTRANDO / SAINDO
--========================================================--

trackConnection(
	Players.PlayerAdded:
		Connect(
			function()

				if PlayerList.Visible then

					task.defer(
						refreshPlayerList
					)

				end

			end
		)
)


trackConnection(
	Players.PlayerRemoving:
		Connect(
			function(player)

				if selectedTarget
					==
					player
				then

					selectedTarget =
						nil

					rightMouseHeld =
						false

					UserInputService.MouseBehavior =
						Enum.MouseBehavior.Default

					updateInterface()

				end

				if PlayerList.Visible then

					task.defer(
						refreshPlayerList
					)

				end

			end
		)
)

--========================================================--
-- LIMPEZA
--========================================================--

local function cleanup()

	if destroyed then
		return
	end

	destroyed =
		true

	hitboxEnabled =
		false

	espNameEnabled =
		false

	espDistanceEnabled =
		false

	gunDropESPEnabled =
		false

	aimlockEnabled =
		false

	waitingAimKeybind =
		false

	rightMouseHeld =
		false

	pcall(
		function()

			RunService:
				UnbindFromRenderStep(
					AIM_RENDER_NAME
				)

		end
	)

	UserInputService.MouseBehavior =
		Enum.MouseBehavior.Default

	restoreAllHitboxes()

	removeAllESP()

	removeGunDropESP()

	for _, connection
		in ipairs(
			Connections
		)
	do

		pcall(
			function()

				connection:
					Disconnect()

			end
		)

	end

	table.clear(
		Connections
	)

	if ScreenGui
		and ScreenGui.Parent
	then

		ScreenGui:
			Destroy()

	end

end


_G.__B1tSampl3HubCleanup =
	cleanup

--========================================================--
-- FECHAR
--========================================================--

trackConnection(
	CloseButton
		.MouseButton1Click:
		Connect(
			function()

				cleanup()

			end
		)
)

--========================================================--
-- INICIALIZAÇÃO
--========================================================--

updateInterface()
