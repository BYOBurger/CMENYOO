--// Team Chams + Grouped Object Search Chams + Noclip + Fly + Teleport Menu
--// SAFE CAMERA VERSION: does NOT touch CameraMode, CameraType, CameraSubject, or MouseBehavior
--// Put this LocalScript in StarterPlayer > StarterPlayerScripts
--// For your own Roblox game

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Settings = {
	MenuKey = Enum.KeyCode.K,

	ChamsEnabled = true,
	ObjectChamsEnabled = true,
	NoclipEnabled = false,
	FlyEnabled = false,

	NoclipKey = Enum.KeyCode.H,
	FlyKey = Enum.KeyCode.J,

	FlySpeed = 55,
	TeleportOffset = Vector3.new(0, 3, 4),

	FillTransparency = 0.45,
	OutlineTransparency = 0,
	DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,

	ObjectFillTransparency = 0.35,
	ObjectOutlineTransparency = 0,
	ObjectColor = Color3.fromRGB(255, 220, 80),
}

local playerChams = {}
local objectChams = {}
local selectedObjects = {}
local expandedGroups = {}

local pages = {}
local tabButtons = {}
local toggleButtons = {}

local menuOpen = true
local unloaded = false
local waitingForBind = nil

local originalCollision = {}

local flyVelocity = nil
local flyGyro = nil
local flyActive = false

local objectSearchBox = nil
local objectListFrame = nil
local objectListLayout = nil
local objectResultButtons = {}

local teleportDropdownOpen = false
local teleportDropdownButton = nil
local teleportListFrame = nil
local teleportListLayout = nil
local teleportPlayerButtons = {}

local oldGui = PlayerGui:FindFirstChild("ClientHVHMenu")
if oldGui then
	oldGui:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ClientHVHMenu"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = PlayerGui

local mouseUnlockButton = Instance.new("TextButton")
mouseUnlockButton.Name = "MouseUnlockModal"
mouseUnlockButton.Size = UDim2.new(1, 0, 1, 0)
mouseUnlockButton.Position = UDim2.new(0, 0, 0, 0)
mouseUnlockButton.BackgroundTransparency = 1
mouseUnlockButton.Text = ""
mouseUnlockButton.Visible = menuOpen
mouseUnlockButton.Modal = menuOpen
mouseUnlockButton.Active = false
mouseUnlockButton.ZIndex = 0
mouseUnlockButton.Parent = screenGui

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 580, 0, 410)
mainFrame.Position = UDim2.new(0.5, -290, 0.5, -205)
mainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
mainFrame.BorderSizePixel = 0
mainFrame.Visible = menuOpen
mainFrame.Active = true
mainFrame.ZIndex = 2
mainFrame.Parent = screenGui

local function makeCorner(object, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 8)
	corner.Parent = object
end

makeCorner(mainFrame, 12)

local mainStroke = Instance.new("UIStroke")
mainStroke.Thickness = 2
mainStroke.Color = Color3.fromRGB(70, 70, 80)
mainStroke.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -100, 0, 42)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 18
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Active = true
title.ZIndex = 3
title.Parent = mainFrame

local unloadButton = Instance.new("TextButton")
unloadButton.Name = "UnloadButton"
unloadButton.Size = UDim2.new(0, 72, 0, 32)
unloadButton.Position = UDim2.new(1, -82, 0, 5)
unloadButton.BackgroundColor3 = Color3.fromRGB(120, 45, 45)
unloadButton.BorderSizePixel = 0
unloadButton.Text = "Unload"
unloadButton.TextColor3 = Color3.fromRGB(255, 255, 255)
unloadButton.TextSize = 14
unloadButton.Font = Enum.Font.GothamBold
unloadButton.ZIndex = 3
unloadButton.Parent = mainFrame
makeCorner(unloadButton, 8)

local tabFrame = Instance.new("Frame")
tabFrame.Size = UDim2.new(0, 135, 1, -52)
tabFrame.Position = UDim2.new(0, 10, 0, 45)
tabFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
tabFrame.BorderSizePixel = 0
tabFrame.ZIndex = 3
tabFrame.Parent = mainFrame
makeCorner(tabFrame, 10)

local contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(1, -165, 1, -52)
contentFrame.Position = UDim2.new(0, 155, 0, 45)
contentFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
contentFrame.BorderSizePixel = 0
contentFrame.ZIndex = 3
contentFrame.Parent = mainFrame
makeCorner(contentFrame, 10)

local function updateMouseState()
	if unloaded then
		return
	end

	if menuOpen then
		mouseUnlockButton.Visible = true
		mouseUnlockButton.Modal = true
	else
		mouseUnlockButton.Modal = false
		mouseUnlockButton.Visible = false
	end
end

local dragging = false
local dragStart = nil
local startPosition = nil

local function beginDrag(input)
	if unloaded then
		return
	end

	dragging = true
	dragStart = input.Position
	startPosition = mainFrame.Position
end

local function endDrag()
	dragging = false
	dragStart = nil
	startPosition = nil
end

title.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		beginDrag(input)
	end
end)

mainFrame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		local mousePos = input.Position
		local framePos = mainFrame.AbsolutePosition
		local relativeY = mousePos.Y - framePos.Y

		if relativeY >= 0 and relativeY <= 42 then
			beginDrag(input)
		end
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if not dragging then
		return
	end

	if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end

	local delta = input.Position - dragStart

	mainFrame.Position = UDim2.new(
		startPosition.X.Scale,
		startPosition.X.Offset + delta.X,
		startPosition.Y.Scale,
		startPosition.Y.Offset + delta.Y
	)
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		endDrag()
	end
end)

local function makeButton(parent, text, size, position)
	local button = Instance.new("TextButton")
	button.Size = size
	button.Position = position
	button.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
	button.BorderSizePixel = 0
	button.Text = text
	button.TextColor3 = Color3.fromRGB(240, 240, 240)
	button.TextSize = 14
	button.Font = Enum.Font.GothamBold
	button.AutoButtonColor = true
	button.ZIndex = 4
	button.Parent = parent
	makeCorner(button, 8)
	return button
end

local function makeLabel(parent, text, position)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -20, 0, 24)
	label.Position = position
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(235, 235, 235)
	label.TextSize = 14
	label.Font = Enum.Font.Gotham
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.ZIndex = 4
	label.Parent = parent
	return label
end

local function makeSlider(parent, text, position, minValue, maxValue, startValue, onChange)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, -20, 0, 55)
	frame.Position = position
	frame.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
	frame.BorderSizePixel = 0
	frame.ZIndex = 4
	frame.Parent = parent
	makeCorner(frame, 8)

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -20, 0, 22)
	label.Position = UDim2.new(0, 10, 0, 3)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(240, 240, 240)
	label.TextSize = 14
	label.Font = Enum.Font.GothamBold
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.ZIndex = 5
	label.Parent = frame

	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(1, -20, 0, 8)
	bar.Position = UDim2.new(0, 10, 0, 34)
	bar.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
	bar.BorderSizePixel = 0
	bar.ZIndex = 5
	bar.Parent = frame
	makeCorner(bar, 99)

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(0, 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(70, 130, 220)
	fill.BorderSizePixel = 0
	fill.ZIndex = 6
	fill.Parent = bar
	makeCorner(fill, 99)

	local knob = Instance.new("TextButton")
	knob.Size = UDim2.new(0, 16, 0, 16)
	knob.Position = UDim2.new(0, -8, 0.5, -8)
	knob.BackgroundColor3 = Color3.fromRGB(235, 235, 235)
	knob.BorderSizePixel = 0
	knob.Text = ""
	knob.ZIndex = 7
	knob.Parent = bar
	makeCorner(knob, 99)

	local draggingSlider = false
	local value = math.clamp(startValue, minValue, maxValue)

	local function setValue(newValue)
		value = math.clamp(newValue, minValue, maxValue)

		local percent = (value - minValue) / (maxValue - minValue)

		fill.Size = UDim2.new(percent, 0, 1, 0)
		knob.Position = UDim2.new(percent, -8, 0.5, -8)

		label.Text = text .. ": " .. tostring(math.floor(value))
		onChange(value)
	end

	local function updateFromMouse()
		local mouseX = UserInputService:GetMouseLocation().X
		local barX = bar.AbsolutePosition.X
		local barWidth = bar.AbsoluteSize.X

		local percent = math.clamp((mouseX - barX) / barWidth, 0, 1)
		local newValue = minValue + ((maxValue - minValue) * percent)

		setValue(newValue)
	end

	bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			draggingSlider = true
			updateFromMouse()
		end
	end)

	knob.MouseButton1Down:Connect(function()
		draggingSlider = true
	end)

	UserInputService.InputChanged:Connect(function(input)
		if draggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
			updateFromMouse()
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			draggingSlider = false
		end
	end)

	setValue(value)

	return frame
end

local function makePage(name)
	local page = Instance.new("Frame")
	page.Name = name .. "Page"
	page.Size = UDim2.new(1, 0, 1, 0)
	page.BackgroundTransparency = 1
	page.Visible = false
	page.ZIndex = 3
	page.Parent = contentFrame

	pages[name] = page
	return page
end

local function switchTab(name)
	for tabName, page in pairs(pages) do
		page.Visible = tabName == name
	end

	for tabName, button in pairs(tabButtons) do
		if tabName == name then
			button.BackgroundColor3 = Color3.fromRGB(70, 90, 130)
		else
			button.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
		end
	end
end

local function makeTab(name, order)
	local button = makeButton(
		tabFrame,
		name,
		UDim2.new(1, -20, 0, 40),
		UDim2.new(0, 10, 0, 10 + ((order - 1) * 48))
	)

	tabButtons[name] = button

	button.MouseButton1Click:Connect(function()
		if unloaded then
			return
		end

		switchTab(name)
	end)
end

local function getTeamColor(player)
	if player.Team then
		return player.Team.TeamColor.Color
	end

	return Color3.fromRGB(255, 255, 255)
end

local function removePlayerCham(player)
	if playerChams[player] then
		playerChams[player]:Destroy()
		playerChams[player] = nil
	end
end

local function removeAllPlayerChams()
	for player, highlight in pairs(playerChams) do
		if highlight then
			highlight:Destroy()
		end

		playerChams[player] = nil
	end
end

local function applyPlayerCham(player)
	if unloaded then
		return
	end

	if not Settings.ChamsEnabled then
		removePlayerCham(player)
		return
	end

	if player == LocalPlayer then
		removePlayerCham(player)
		return
	end

	if not player.Character then
		return
	end

	removePlayerCham(player)

	local color = getTeamColor(player)

	local highlight = Instance.new("Highlight")
	highlight.Name = "TeamCham"
	highlight.Adornee = player.Character
	highlight.FillColor = color
	highlight.OutlineColor = color
	highlight.FillTransparency = Settings.FillTransparency
	highlight.OutlineTransparency = Settings.OutlineTransparency
	highlight.DepthMode = Settings.DepthMode
	highlight.Parent = player.Character

	playerChams[player] = highlight
end

local function updatePlayerCham(player)
	if unloaded then
		return
	end

	if not Settings.ChamsEnabled then
		removePlayerCham(player)
		return
	end

	if player == LocalPlayer then
		removePlayerCham(player)
		return
	end

	if not player.Character then
		return
	end

	local highlight = playerChams[player]

	if not highlight or not highlight.Parent then
		applyPlayerCham(player)
		return
	end

	local color = getTeamColor(player)

	highlight.FillColor = color
	highlight.OutlineColor = color
	highlight.FillTransparency = Settings.FillTransparency
	highlight.OutlineTransparency = Settings.OutlineTransparency
	highlight.DepthMode = Settings.DepthMode
end

local function updateAllPlayerChams()
	if unloaded then
		return
	end

	if not Settings.ChamsEnabled then
		removeAllPlayerChams()
		return
	end

	for _, player in ipairs(Players:GetPlayers()) do
		updatePlayerCham(player)
	end
end

local function setupPlayer(player)
	player.CharacterAdded:Connect(function()
		if unloaded then
			return
		end

		task.wait(0.4)
		applyPlayerCham(player)
	end)

	player:GetPropertyChangedSignal("Team"):Connect(function()
		if unloaded then
			return
		end

		task.wait(0.1)
		updatePlayerCham(player)
	end)

	if player.Character then
		task.wait(0.4)
		applyPlayerCham(player)
	end
end

local function getObjectLabel(instance)
	return instance.Name .. "  [" .. instance.ClassName .. "]"
end

local function getObjectGroupKey(instance)
	return instance.Name .. "||" .. instance.ClassName
end

local function getObjectGroupTitle(instance)
	return instance.Name .. "  [" .. instance.ClassName .. "]"
end

local function isSearchableObject(instance)
	if instance == Workspace then
		return false
	end

	if LocalPlayer.Character and instance:IsDescendantOf(LocalPlayer.Character) then
		return false
	end

	if instance:IsA("Model") then
		return instance:FindFirstChildWhichIsA("BasePart", true) ~= nil
	end

	if instance:IsA("BasePart") then
		return true
	end

	return false
end

local function getObjectAdornee(instance)
	if not instance or not instance.Parent then
		return nil
	end

	if instance:IsA("Model") then
		if instance:FindFirstChildWhichIsA("BasePart", true) then
			return instance
		end
	elseif instance:IsA("BasePart") then
		return instance
	end

	return nil
end

local function removeObjectCham(instance)
	if objectChams[instance] then
		objectChams[instance]:Destroy()
		objectChams[instance] = nil
	end
end

local function removeAllObjectChams()
	for instance, highlight in pairs(objectChams) do
		if highlight then
			highlight:Destroy()
		end

		objectChams[instance] = nil
	end
end

local function applyObjectCham(instance)
	if unloaded then
		return
	end

	if not Settings.ObjectChamsEnabled then
		removeObjectCham(instance)
		return
	end

	if not selectedObjects[instance] then
		removeObjectCham(instance)
		return
	end

	local adornee = getObjectAdornee(instance)
	if not adornee then
		removeObjectCham(instance)
		selectedObjects[instance] = nil
		return
	end

	local highlight = objectChams[instance]

	if not highlight or not highlight.Parent then
		removeObjectCham(instance)

		highlight = Instance.new("Highlight")
		highlight.Name = "ObjectSearchCham"
		highlight.Adornee = adornee
		highlight.Parent = screenGui

		objectChams[instance] = highlight
	end

	highlight.FillColor = Settings.ObjectColor
	highlight.OutlineColor = Settings.ObjectColor
	highlight.FillTransparency = Settings.ObjectFillTransparency
	highlight.OutlineTransparency = Settings.ObjectOutlineTransparency
	highlight.DepthMode = Settings.DepthMode
end

local function updateAllObjectChams()
	if unloaded then
		return
	end

	if not Settings.ObjectChamsEnabled then
		removeAllObjectChams()
		return
	end

	for instance, enabled in pairs(selectedObjects) do
		if enabled then
			applyObjectCham(instance)
		end
	end
end

local function toggleObjectSelected(instance)
	if not instance or not instance.Parent then
		return
	end

	if selectedObjects[instance] then
		selectedObjects[instance] = nil
		removeObjectCham(instance)
	else
		selectedObjects[instance] = true
		applyObjectCham(instance)
	end
end

local function getGroupState(objects)
	local selectedCount = 0

	for _, instance in ipairs(objects) do
		if selectedObjects[instance] then
			selectedCount += 1
		end
	end

	if selectedCount == 0 then
		return "OFF", selectedCount
	elseif selectedCount == #objects then
		return "ON", selectedCount
	else
		return "MIX", selectedCount
	end
end

local function setGroupSelected(objects, state)
	for _, instance in ipairs(objects) do
		if instance and instance.Parent then
			if state then
				selectedObjects[instance] = true
				applyObjectCham(instance)
			else
				selectedObjects[instance] = nil
				removeObjectCham(instance)
			end
		end
	end
end

local function toggleGroupSelected(objects)
	local groupState = getGroupState(objects)

	if groupState == "ON" then
		setGroupSelected(objects, false)
	else
		setGroupSelected(objects, true)
	end
end

local function clearObjectResultButtons()
	for _, button in ipairs(objectResultButtons) do
		if button then
			button:Destroy()
		end
	end

	table.clear(objectResultButtons)
end

local function getSearchResults(query)
	query = tostring(query or ""):lower()

	local results = {}
	local count = 0
	local maxResults = 175

	for _, instance in ipairs(Workspace:GetDescendants()) do
		if count >= maxResults then
			break
		end

		if isSearchableObject(instance) then
			local lowerName = instance.Name:lower()
			local lowerClass = instance.ClassName:lower()

			if query == "" or lowerName:find(query, 1, true) or lowerClass:find(query, 1, true) then
				count += 1
				table.insert(results, instance)
			end
		end
	end

	table.sort(results, function(a, b)
		local aKey = getObjectGroupTitle(a):lower()
		local bKey = getObjectGroupTitle(b):lower()

		if aKey == bKey then
			return a:GetFullName():lower() < b:GetFullName():lower()
		end

		return aKey < bKey
	end)

	return results
end

local function makeObjectRow(instance, indent)
	local isSelected = selectedObjects[instance] == true

	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, -8 - indent, 0, 32)
	button.Position = UDim2.new(0, indent, 0, 0)
	button.BackgroundColor3 = isSelected and Color3.fromRGB(45, 110, 65) or Color3.fromRGB(35, 35, 42)
	button.BorderSizePixel = 0
	button.Text = (isSelected and "[ON]  " or "[OFF] ") .. getObjectLabel(instance)
	button.TextColor3 = Color3.fromRGB(240, 240, 240)
	button.TextSize = 12
	button.Font = Enum.Font.GothamBold
	button.TextXAlignment = Enum.TextXAlignment.Left
	button.ZIndex = 5
	button.Parent = objectListFrame
	makeCorner(button, 6)

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 8)
	padding.Parent = button

	button.MouseButton1Click:Connect(function()
		if unloaded then
			return
		end

		toggleObjectSelected(instance)
		refreshObjectSearch()
	end)

	table.insert(objectResultButtons, button)
end

function refreshObjectSearch()
	if not objectListFrame or not objectSearchBox then
		return
	end

	clearObjectResultButtons()

	local query = objectSearchBox.Text
	local results = getSearchResults(query)

	local groups = {}
	local order = {}

	for _, instance in ipairs(results) do
		local key = getObjectGroupKey(instance)

		if not groups[key] then
			groups[key] = {
				Key = key,
				Title = getObjectGroupTitle(instance),
				Objects = {},
			}

			table.insert(order, key)
		end

		table.insert(groups[key].Objects, instance)
	end

	table.sort(order, function(a, b)
		return groups[a].Title:lower() < groups[b].Title:lower()
	end)

	for _, key in ipairs(order) do
		local group = groups[key]
		local objects = group.Objects

		if #objects > 1 then
			local groupState, selectedCount = getGroupState(objects)
			local expanded = expandedGroups[key] == true
			local arrow = expanded and "▼" or "▶"

			local groupButton = Instance.new("TextButton")
			groupButton.Size = UDim2.new(1, -8, 0, 36)

			if groupState == "ON" then
				groupButton.BackgroundColor3 = Color3.fromRGB(45, 110, 65)
			elseif groupState == "MIX" then
				groupButton.BackgroundColor3 = Color3.fromRGB(120, 90, 45)
			else
				groupButton.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
			end

			groupButton.BorderSizePixel = 0
			groupButton.Text = arrow .. "  [" .. groupState .. "]  " .. group.Title .. "  x" .. tostring(#objects) .. "  (" .. tostring(selectedCount) .. "/" .. tostring(#objects) .. ")"
			groupButton.TextColor3 = Color3.fromRGB(240, 240, 240)
			groupButton.TextSize = 12
			groupButton.Font = Enum.Font.GothamBold
			groupButton.TextXAlignment = Enum.TextXAlignment.Left
			groupButton.ZIndex = 5
			groupButton.Parent = objectListFrame
			makeCorner(groupButton, 6)

			local padding = Instance.new("UIPadding")
			padding.PaddingLeft = UDim.new(0, 8)
			padding.Parent = groupButton

			groupButton.MouseButton1Click:Connect(function()
				if unloaded then
					return
				end

				expandedGroups[key] = not expandedGroups[key]
				refreshObjectSearch()
			end)

			groupButton.MouseButton2Click:Connect(function()
				if unloaded then
					return
				end

				toggleGroupSelected(objects)
				refreshObjectSearch()
			end)

			table.insert(objectResultButtons, groupButton)

			if expanded then
				for _, instance in ipairs(objects) do
					makeObjectRow(instance, 18)
				end
			end
		else
			makeObjectRow(objects[1], 0)
		end
	end

	task.defer(function()
		if objectListFrame and objectListLayout then
			objectListFrame.CanvasSize = UDim2.new(0, 0, 0, objectListLayout.AbsoluteContentSize.Y + 8)
		end
	end)
end

local function setCharacterNoclip(character, enabled)
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			if enabled then
				if originalCollision[part] == nil then
					originalCollision[part] = part.CanCollide
				end

				part.CanCollide = false
			else
				if originalCollision[part] ~= nil then
					part.CanCollide = originalCollision[part]
					originalCollision[part] = nil
				end
			end
		end
	end
end

local function updateNoclip()
	local character = LocalPlayer.Character

	if not character then
		return
	end

	if unloaded then
		setCharacterNoclip(character, false)
		return
	end

	if Settings.NoclipEnabled then
		setCharacterNoclip(character, true)
	else
		setCharacterNoclip(character, false)
	end
end

local function getCharacterParts()
	local character = LocalPlayer.Character
	if not character then
		return nil, nil, nil
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")

	return character, humanoid, root
end

local function stopFly()
	local _, humanoid, root = getCharacterParts()

	if flyVelocity then
		flyVelocity:Destroy()
		flyVelocity = nil
	end

	if flyGyro then
		flyGyro:Destroy()
		flyGyro = nil
	end

	if humanoid then
		humanoid.PlatformStand = false
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end

	if root and flyActive then
		root.AssemblyLinearVelocity = Vector3.zero
	end

	flyActive = false
end

local function startFly()
	local _, humanoid, root = getCharacterParts()

	if not humanoid or not root then
		return
	end

	if flyActive and flyVelocity and flyVelocity.Parent == root then
		return
	end

	if flyVelocity then
		flyVelocity:Destroy()
		flyVelocity = nil
	end

	if flyGyro then
		flyGyro:Destroy()
		flyGyro = nil
	end

	flyActive = true
	humanoid.PlatformStand = true

	flyVelocity = Instance.new("BodyVelocity")
	flyVelocity.Name = "ClientFlyVelocity"
	flyVelocity.MaxForce = Vector3.new(100000, 100000, 100000)
	flyVelocity.Velocity = Vector3.zero
	flyVelocity.Parent = root

	flyGyro = Instance.new("BodyGyro")
	flyGyro.Name = "ClientFlyGyro"
	flyGyro.MaxTorque = Vector3.new(100000, 100000, 100000)
	flyGyro.P = 9000
	flyGyro.CFrame = root.CFrame
	flyGyro.Parent = root
end

local function updateFly()
	if unloaded then
		if flyActive then
			stopFly()
		end

		return
	end

	if not Settings.FlyEnabled then
		if flyActive then
			stopFly()
		end

		return
	end

	local _, humanoid, root = getCharacterParts()

	if not humanoid or not root then
		if flyActive then
			stopFly()
		end

		return
	end

	if not flyActive or not flyVelocity or flyVelocity.Parent ~= root or not flyGyro or flyGyro.Parent ~= root then
		startFly()
	end

	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end

	local moveDirection = Vector3.zero

	if UserInputService:IsKeyDown(Enum.KeyCode.W) then
		moveDirection += camera.CFrame.LookVector
	end

	if UserInputService:IsKeyDown(Enum.KeyCode.S) then
		moveDirection -= camera.CFrame.LookVector
	end

	if UserInputService:IsKeyDown(Enum.KeyCode.A) then
		moveDirection -= camera.CFrame.RightVector
	end

	if UserInputService:IsKeyDown(Enum.KeyCode.D) then
		moveDirection += camera.CFrame.RightVector
	end

	if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
		moveDirection += Vector3.new(0, 1, 0)
	end

	if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
		moveDirection -= Vector3.new(0, 1, 0)
	end

	if moveDirection.Magnitude > 0 then
		moveDirection = moveDirection.Unit * Settings.FlySpeed
	end

	flyVelocity.Velocity = moveDirection
	flyGyro.CFrame = camera.CFrame
	humanoid.PlatformStand = true
end

LocalPlayer.CharacterAdded:Connect(function(character)
	originalCollision = {}
	stopFly()

	task.wait(0.5)

	if unloaded then
		return
	end

	if Settings.NoclipEnabled then
		setCharacterNoclip(character, true)
	end

	if Settings.FlyEnabled then
		startFly()
	end
end)

local function clearTeleportButtons()
	for _, button in ipairs(teleportPlayerButtons) do
		if button then
			button:Destroy()
		end
	end

	table.clear(teleportPlayerButtons)
end

local function getPlayerDisplayText(player)
	local teamName = "No Team"

	if player.Team then
		teamName = player.Team.Name
	end

	return player.Name .. "  |  " .. teamName
end

local function getPlayerTextColor(player)
	if player.Team then
		return player.Team.TeamColor.Color
	end

	return Color3.fromRGB(255, 255, 255)
end

local function teleportToPlayer(targetPlayer)
	local myCharacter = LocalPlayer.Character
	local targetCharacter = targetPlayer.Character

	if not myCharacter or not targetCharacter then
		return
	end

	local myRoot = myCharacter:FindFirstChild("HumanoidRootPart")
	local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")

	if not myRoot or not targetRoot then
		return
	end

	local behindPosition = targetRoot.CFrame * CFrame.new(Settings.TeleportOffset)
	myRoot.CFrame = behindPosition
end

local function refreshTeleportDropdown()
	if not teleportListFrame or not teleportListLayout then
		return
	end

	clearTeleportButtons()

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			local button = Instance.new("TextButton")
			button.Size = UDim2.new(1, -8, 0, 34)
			button.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
			button.BorderSizePixel = 0
			button.Text = getPlayerDisplayText(player)
			button.TextColor3 = getPlayerTextColor(player)
			button.TextSize = 13
			button.Font = Enum.Font.GothamBold
			button.TextXAlignment = Enum.TextXAlignment.Left
			button.ZIndex = 5
			button.Parent = teleportListFrame
			makeCorner(button, 6)

			local padding = Instance.new("UIPadding")
			padding.PaddingLeft = UDim.new(0, 8)
			padding.Parent = button

			button.MouseButton1Click:Connect(function()
				if unloaded then
					return
				end

				teleportDropdownOpen = false
				if teleportDropdownButton then
					teleportDropdownButton.Text = "Select Player: " .. player.Name
				end

				teleportToPlayer(player)
			end)

			table.insert(teleportPlayerButtons, button)
		end
	end

	task.defer(function()
		if teleportListFrame and teleportListLayout then
			teleportListFrame.CanvasSize = UDim2.new(0, 0, 0, teleportListLayout.AbsoluteContentSize.Y + 8)
		end
	end)
end

local function setTeleportDropdownOpen(state)
	teleportDropdownOpen = state

	if teleportListFrame then
		teleportListFrame.Visible = teleportDropdownOpen
	end

	if teleportDropdownButton then
		teleportDropdownButton.Text = teleportDropdownOpen and "Select Player: Open ▼" or "Select Player: Closed ▶"
	end

	if teleportDropdownOpen then
		refreshTeleportDropdown()
	end
end

local function unloadScript()
	if unloaded then
		return
	end

	unloaded = true
	dragging = false

	Settings.ChamsEnabled = false
	Settings.ObjectChamsEnabled = false
	Settings.NoclipEnabled = false
	Settings.FlyEnabled = false

	removeAllPlayerChams()
	removeAllObjectChams()
	updateNoclip()
	stopFly()

	mouseUnlockButton.Modal = false
	mouseUnlockButton.Visible = false

	if screenGui then
		screenGui:Destroy()
	end
end

unloadButton.MouseButton1Click:Connect(function()
	unloadScript()
end)

local menuBindButton

local function updateTitle()
	title.Text = "CMENYOO  |  Press " .. Settings.MenuKey.Name .. " to Open/Close"
end

local function makeToggle(parent, text, position, getValue, setValue, defaultKey)
	local button = makeButton(parent, "", UDim2.new(1, -20, 0, 42), position)

	local toggleData = {
		Name = text,
		Button = button,
		KeyCode = defaultKey,
		WaitingForBind = false,
	}

	function toggleData.GetBindText()
		if toggleData.WaitingForBind then
			return "press key..."
		end

		if toggleData.KeyCode then
			return toggleData.KeyCode.Name
		end

		return "-"
	end

	function toggleData.Refresh()
		local value = getValue()
		local bindText = toggleData.GetBindText()

		button.Text = text .. ": " .. (value and "ON" or "OFF") .. "  |  Bind: " .. bindText

		if toggleData.WaitingForBind then
			button.BackgroundColor3 = Color3.fromRGB(120, 90, 45)
		elseif value then
			button.BackgroundColor3 = Color3.fromRGB(45, 110, 65)
		else
			button.BackgroundColor3 = Color3.fromRGB(110, 45, 45)
		end
	end

	function toggleData.Set(value)
		if unloaded then
			return
		end

		setValue(value)
		toggleData.Refresh()
	end

	function toggleData.Toggle()
		if unloaded then
			return
		end

		setValue(not getValue())
		toggleData.Refresh()
	end

	function toggleData.StartBind()
		if unloaded then
			return
		end

		for _, otherToggle in pairs(toggleButtons) do
			otherToggle.WaitingForBind = false
			otherToggle.Refresh()
		end

		waitingForBind = {
			Type = "Toggle",
			Toggle = toggleData,
		}

		toggleData.WaitingForBind = true
		toggleData.Refresh()
	end

	button.MouseButton1Click:Connect(function()
		toggleData.Toggle()
	end)

	button.MouseButton2Click:Connect(function()
		toggleData.StartBind()
	end)

	toggleButtons[text] = toggleData
	toggleData.Refresh()

	return toggleData
end

local function updateMenuBindButton()
	if not menuBindButton then
		return
	end

	if waitingForBind and waitingForBind.Type == "Menu" then
		menuBindButton.Text = "Menu Bind: press key..."
		menuBindButton.BackgroundColor3 = Color3.fromRGB(120, 90, 45)
	else
		menuBindButton.Text = "Menu Bind: " .. Settings.MenuKey.Name .. "  |  Right-click to rebind"
		menuBindButton.BackgroundColor3 = Color3.fromRGB(45, 70, 115)
	end
end

local function makeMenuBindButton(parent, position)
	menuBindButton = makeButton(parent, "", UDim2.new(1, -20, 0, 42), position)

	menuBindButton.MouseButton2Click:Connect(function()
		if unloaded then
			return
		end

		for _, toggleData in pairs(toggleButtons) do
			toggleData.WaitingForBind = false
			toggleData.Refresh()
		end

		waitingForBind = {
			Type = "Menu",
		}

		updateMenuBindButton()
	end)

	menuBindButton.MouseButton1Click:Connect(function()
		if unloaded then
			return
		end

		menuOpen = not menuOpen
		mainFrame.Visible = menuOpen
		updateMouseState()
	end)

	updateMenuBindButton()
end

makeTab("Visuals", 1)
makeTab("Objects", 2)
makeTab("Movement", 3)
makeTab("Teleport", 4)
makeTab("Config", 5)

local visualsPage = makePage("Visuals")
local objectsPage = makePage("Objects")
local movementPage = makePage("Movement")
local teleportPage = makePage("Teleport")
local configPage = makePage("Config")

makeLabel(visualsPage, "Visuals", UDim2.new(0, 10, 0, 10))

makeToggle(
	visualsPage,
	"Chams",
	UDim2.new(0, 10, 0, 45),
	function()
		return Settings.ChamsEnabled
	end,
	function(value)
		Settings.ChamsEnabled = value
		updateAllPlayerChams()
	end,
	nil
)

makeLabel(visualsPage, "Left-click = toggle", UDim2.new(0, 10, 0, 100))
makeLabel(visualsPage, "Right-click = bind key", UDim2.new(0, 10, 0, 125))
makeLabel(visualsPage, "Player chams always use Roblox team colors.", UDim2.new(0, 10, 0, 150))

makeLabel(objectsPage, "Object Search", UDim2.new(0, 10, 0, 10))

makeToggle(
	objectsPage,
	"Object Chams",
	UDim2.new(0, 10, 0, 40),
	function()
		return Settings.ObjectChamsEnabled
	end,
	function(value)
		Settings.ObjectChamsEnabled = value
		updateAllObjectChams()
	end,
	nil
)

objectSearchBox = Instance.new("TextBox")
objectSearchBox.Size = UDim2.new(1, -20, 0, 34)
objectSearchBox.Position = UDim2.new(0, 10, 0, 90)
objectSearchBox.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
objectSearchBox.BorderSizePixel = 0
objectSearchBox.Text = ""
objectSearchBox.PlaceholderText = "Search objects by name or class..."
objectSearchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
objectSearchBox.PlaceholderColor3 = Color3.fromRGB(135, 135, 135)
objectSearchBox.TextSize = 14
objectSearchBox.Font = Enum.Font.GothamBold
objectSearchBox.ClearTextOnFocus = false
objectSearchBox.ZIndex = 4
objectSearchBox.Parent = objectsPage
makeCorner(objectSearchBox, 8)

objectListFrame = Instance.new("ScrollingFrame")
objectListFrame.Size = UDim2.new(1, -20, 1, -165)
objectListFrame.Position = UDim2.new(0, 10, 0, 135)
objectListFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
objectListFrame.BorderSizePixel = 0
objectListFrame.ScrollBarThickness = 6
objectListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
objectListFrame.ZIndex = 4
objectListFrame.Parent = objectsPage
makeCorner(objectListFrame, 8)

objectListLayout = Instance.new("UIListLayout")
objectListLayout.Padding = UDim.new(0, 6)
objectListLayout.SortOrder = Enum.SortOrder.LayoutOrder
objectListLayout.Parent = objectListFrame

local objectListPadding = Instance.new("UIPadding")
objectListPadding.PaddingTop = UDim.new(0, 6)
objectListPadding.PaddingLeft = UDim.new(0, 4)
objectListPadding.PaddingRight = UDim.new(0, 4)
objectListPadding.PaddingBottom = UDim.new(0, 6)
objectListPadding.Parent = objectListFrame

objectSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
	refreshObjectSearch()
end)

makeLabel(objectsPage, "Groups appear when multiple objects share the same name/class.", UDim2.new(0, 10, 1, -28))
makeLabel(objectsPage, "Left-click group = dropdown. Right-click group = toggle all.", UDim2.new(0, 10, 1, -52))

makeLabel(movementPage, "Movement", UDim2.new(0, 10, 0, 10))

makeToggle(
	movementPage,
	"Noclip",
	UDim2.new(0, 10, 0, 45),
	function()
		return Settings.NoclipEnabled
	end,
	function(value)
		Settings.NoclipEnabled = value
		updateNoclip()
	end,
	Settings.NoclipKey
)

makeToggle(
	movementPage,
	"Fly",
	UDim2.new(0, 10, 0, 95),
	function()
		return Settings.FlyEnabled
	end,
	function(value)
		Settings.FlyEnabled = value

		if value then
			startFly()
		else
			stopFly()
		end
	end,
	Settings.FlyKey
)

makeSlider(
	movementPage,
	"Fly Speed",
	UDim2.new(0, 10, 0, 145),
	10,
	200,
	Settings.FlySpeed,
	function(value)
		Settings.FlySpeed = value
	end
)

makeLabel(movementPage, "Default Noclip bind: H", UDim2.new(0, 10, 0, 210))
makeLabel(movementPage, "Default Fly bind: J", UDim2.new(0, 10, 0, 235))
makeLabel(movementPage, "Fly: WASD, Space up, LeftControl down.", UDim2.new(0, 10, 0, 260))

makeLabel(teleportPage, "Teleport", UDim2.new(0, 10, 0, 10))
makeLabel(teleportPage, "Player names are colored by team.", UDim2.new(0, 10, 0, 38))

teleportDropdownButton = makeButton(
	teleportPage,
	"Select Player: Closed ▶",
	UDim2.new(1, -20, 0, 42),
	UDim2.new(0, 10, 0, 75)
)

teleportDropdownButton.MouseButton1Click:Connect(function()
	if unloaded then
		return
	end

	setTeleportDropdownOpen(not teleportDropdownOpen)
end)

teleportListFrame = Instance.new("ScrollingFrame")
teleportListFrame.Size = UDim2.new(1, -20, 0, 205)
teleportListFrame.Position = UDim2.new(0, 10, 0, 125)
teleportListFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
teleportListFrame.BorderSizePixel = 0
teleportListFrame.ScrollBarThickness = 6
teleportListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
teleportListFrame.Visible = false
teleportListFrame.ZIndex = 4
teleportListFrame.Parent = teleportPage
makeCorner(teleportListFrame, 8)

teleportListLayout = Instance.new("UIListLayout")
teleportListLayout.Padding = UDim.new(0, 6)
teleportListLayout.SortOrder = Enum.SortOrder.LayoutOrder
teleportListLayout.Parent = teleportListFrame

local teleportListPadding = Instance.new("UIPadding")
teleportListPadding.PaddingTop = UDim.new(0, 6)
teleportListPadding.PaddingLeft = UDim.new(0, 4)
teleportListPadding.PaddingRight = UDim.new(0, 4)
teleportListPadding.PaddingBottom = UDim.new(0, 6)
teleportListPadding.Parent = teleportListFrame

makeLabel(teleportPage, "Click a name to teleport near that player.", UDim2.new(0, 10, 1, -34))

makeLabel(configPage, "Config", UDim2.new(0, 10, 0, 10))

makeMenuBindButton(configPage, UDim2.new(0, 10, 0, 45))

makeLabel(configPage, "Menu button:", UDim2.new(0, 10, 0, 100))
makeLabel(configPage, "Left-click = open/close menu", UDim2.new(0, 10, 0, 125))
makeLabel(configPage, "Right-click = rebind menu key", UDim2.new(0, 10, 0, 150))
makeLabel(configPage, "Drag from the top bar to move the menu.", UDim2.new(0, 10, 0, 185))
makeLabel(configPage, "Camera safe: this version does not force MouseBehavior.", UDim2.new(0, 10, 0, 210))
makeLabel(configPage, "Unload removes chams, noclip, fly, and GUI.", UDim2.new(0, 10, 0, 235))

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if unloaded then
		return
	end

	if input.UserInputType ~= Enum.UserInputType.Keyboard then
		return
	end

	if waitingForBind then
		if input.KeyCode ~= Enum.KeyCode.Unknown then
			if waitingForBind.Type == "Toggle" and waitingForBind.Toggle then
				waitingForBind.Toggle.KeyCode = input.KeyCode
				waitingForBind.Toggle.WaitingForBind = false
				waitingForBind.Toggle.Refresh()
			elseif waitingForBind.Type == "Menu" then
				Settings.MenuKey = input.KeyCode
				updateTitle()
				updateMenuBindButton()
			end

			waitingForBind = nil
		end

		return
	end

	if gameProcessed then
		return
	end

	if input.KeyCode == Settings.MenuKey then
		menuOpen = not menuOpen
		mainFrame.Visible = menuOpen
		updateMouseState()
		return
	end

	for _, toggleData in pairs(toggleButtons) do
		if toggleData.KeyCode and input.KeyCode == toggleData.KeyCode then
			toggleData.Toggle()
			return
		end
	end
end)

for _, player in ipairs(Players:GetPlayers()) do
	setupPlayer(player)
end

Players.PlayerAdded:Connect(function(player)
	setupPlayer(player)
	refreshTeleportDropdown()
end)

Players.PlayerRemoving:Connect(function(player)
	removePlayerCham(player)
	refreshTeleportDropdown()
end)

Workspace.DescendantRemoving:Connect(function(instance)
	if selectedObjects[instance] then
		selectedObjects[instance] = nil
	end

	removeObjectCham(instance)
end)

RunService.Stepped:Connect(function()
	if unloaded then
		return
	end

	updateNoclip()
	updateFly()
end)

RunService.RenderStepped:Connect(function()
	if unloaded then
		return
	end

	if Settings.ChamsEnabled then
		for _, player in ipairs(Players:GetPlayers()) do
			updatePlayerCham(player)
		end
	end

	if Settings.ObjectChamsEnabled then
		updateAllObjectChams()
	end
end)

switchTab("Visuals")
updateTitle()
updateMenuBindButton()
updateAllPlayerChams()
refreshObjectSearch()
refreshTeleportDropdown()
updateMouseState()
