-- Грук LUA: Компактный чит с исправленным GUI, полный функционал Kychar.txt
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local rs = game:GetService("ReplicatedStorage")
local plr = Players.LocalPlayer
local Cam = workspace.CurrentCamera

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "GrokLUA_Cheat"
gui.Enabled = true
gui.ResetOnSpawn = false
-- Используем gethui для совместимости с эксплойтами
local success, err = pcall(function()
    gui.Parent = game:GetService("CoreGui")
end)
if not success then
    gui.Parent = game:GetService("Players").LocalPlayer.PlayerGui
end
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 300, 0, 400)
frame.Position = UDim2.new(0, 10, 0, 10)
frame.BackgroundColor3 = Color3.new(0, 0, 0)
frame.BackgroundTransparency = 0.5
frame.Visible = true
local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 30)
title.Text = "Grok LUA Cheat"
title.TextColor3 = Color3.new(1, 1, 1)
title.BackgroundTransparency = 1
title.TextSize = 20
local yOffset = 40

local function addToggle(name, callback)
    local toggle = Instance.new("TextButton", frame)
    toggle.Size = UDim2.new(0.8, 0, 0, 30)
    toggle.Position = UDim2.new(0.1, 0, 0, yOffset)
    toggle.Text = name .. ": OFF"
    toggle.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    toggle.TextColor3 = Color3.new(1, 1, 1)
    local state = false
    toggle.MouseButton1Click:Connect(function()
        state = not state
        toggle.Text = name .. (state and ": ON" or ": OFF")
        callback(state)
    end)
    yOffset = yOffset + 40
    return toggle
end

local function addSlider(name, min, max, default, callback)
    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(0.8, 0, 0, 20)
    label.Position = UDim2.new(0.1, 0, 0, yOffset)
    label.Text = name .. ": " .. default
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1, 1, 1)
    yOffset = yOffset + 30
    local slider = Instance.new("TextButton", frame)
    slider.Size = UDim2.new(0.8, 0, 0, 20)
    slider.Position = UDim2.new(0.1, 0, 0, yOffset)
    slider.Text = "-    +"
    slider.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
    local value = default
    slider.MouseButton1Click:Connect(function()
        value = value + 10
        if value > max then value = min end
        label.Text = name .. ": " .. value
        callback(value)
    end)
    yOffset = yOffset + 30
    return slider
end

local function addButton(name, callback)
    local button = Instance.new("TextButton", frame)
    button.Size = UDim2.new(0.8, 0, 0, 30)
    button.Position = UDim2.new(0.1, 0, 0, yOffset)
    button.Text = name
    button.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.MouseButton1Click:Connect(callback)
    yOffset = yOffset + 40
    return button
end

-- Aimbot
local validNPCs = {}
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
local fovCircle = Drawing.new("Circle")
fovCircle.Visible = false
fovCircle.Thickness = 1
fovCircle.Color = Color3.new(1, 1, 1)
fovCircle.Filled = false
local fovRadius = 100
local aimbotEnabled = false
local aimbotKey = Enum.UserInputType.MouseButton2

-- ESP
local ESPHandles = {}
local ESPEnabled = false
local ESPPlayerEnabled = false
local ESPZombyEnabled = false
local ESPColor = Color3.fromRGB(255, 0, 0)

-- Movement
local speedHackEnabled = false
local speedValue = 16
local jumpHackEnabled = false
local jumpMultiplier = 1.5
local noClipEnabled = false
local infiniteJumpEnabled = false
local flyEnabled = false
local auraOn = false
local killDist = 15
local selectedItem = "Select an item"

local function isNPC(obj)
    return obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj.Humanoid.Health > 0 and obj:FindFirstChild("Head") and obj:FindFirstChild("HumanoidRootPart") and not Players:GetPlayerFromCharacter(obj)
end

local function updateNPCs()
    local tempTable = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if isNPC(obj) then tempTable[obj] = true end
    end
    for i = #validNPCs, 1, -1 do
        if not tempTable[validNPCs[i]] then table.remove(validNPCs, i) end
    end
    for obj in pairs(tempTable) do
        if not table.find(validNPCs, obj) then table.insert(validNPCs, obj) end
    end
end

workspace.DescendantAdded:Connect(function(descendant)
    if isNPC(descendant) then
        table.insert(validNPCs, descendant)
        local humanoid = descendant:WaitForChild("Humanoid")
        humanoid.Destroying:Connect(function()
            for i = #validNPCs, 1, -1 do
                if validNPCs[i] == descendant then table.remove(validNPCs, i) break end
            end
        end)
    end
end)

workspace.DescendantRemoving:Connect(function(descendant)
    if isNPC(descendant) then
        for i = #validNPCs, 1, -1 do
            if validNPCs[i] == descendant then table.remove(validNPCs, i) break end
        end
    end
end)

local function predictPos(target)
    local rootPart = target:FindFirstChild("HumanoidRootPart")
    local head = target:FindFirstChild("Head")
    if not rootPart or not head then return head and head.Position or rootPart and rootPart.Position end
    local velocity = rootPart.Velocity
    local predictionTime = 0.02
    local basePosition = rootPart.Position + velocity * predictionTime
    local headOffset = head.Position - rootPart.Position
    return basePosition + headOffset
end

local function getTarget()
    local nearest, minDistance = nil, math.huge
    local viewportCenter = Cam.ViewportSize / 2
    raycastParams.FilterDescendantsInstances = {plr.Character or {}}
    for _, npc in ipairs(validNPCs) do
        local predictedPos = predictPos(npc)
        local screenPos, visible = Cam:WorldToViewportPoint(predictedPos)
        if visible and screenPos.Z > 0 then
            local distance = (Vector2.new(screenPos.X, screenPos.Y) - viewportCenter).Magnitude
            if distance <= fovRadius then
                local ray = workspace:Raycast(Cam.CFrame.Position, (predictedPos - Cam.CFrame.Position).Unit * 1000, raycastParams)
                if ray and ray.Instance:IsDescendantOf(npc) and distance < minDistance then
                    minDistance = distance
                    nearest = npc
                end
            end
        end
    end
    return nearest
end

local function aim(targetPosition)
    local currentCF = Cam.CFrame
    local targetDirection = (targetPosition - currentCF.Position).Unit
    local newLookVector = currentCF.LookVector:Lerp(targetDirection, 0.581)
    Cam.CFrame = CFrame.new(currentCF.Position, currentCF.Position + newLookVector)
end

local function CreateESP(object, color)
    if not object or not object.PrimaryPart or ESPHandles[object] then return end
    local highlight = Instance.new("Highlight", object)
    highlight.Name = "ESP_Highlight"
    highlight.Adornee = object
    highlight.FillColor = color
    highlight.OutlineColor = color
    local billboard = Instance.new("BillboardGui", object)
    billboard.Name = "ESP_Billboard"
    billboard.Adornee = object.PrimaryPart
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 5, 0)
    billboard.AlwaysOnTop = true
    local textLabel = Instance.new("TextLabel", billboard)
    textLabel.Text = object.Name
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.TextColor3 = color
    textLabel.BackgroundTransparency = 1
    textLabel.TextSize = 7
    ESPHandles[object] = {Highlight = highlight, Billboard = billboard}
end

local function ClearESP()
    for obj, handles in pairs(ESPHandles) do
        if handles.Highlight then handles.Highlight:Destroy() end
        if handles.Billboard then handles.Billboard:Destroy() end
        ESPHandles[obj] = nil
    end
end

local function UpdateESP()
    ClearESP()
    local runtimeItems = workspace:FindFirstChild("RuntimeItems")
    if runtimeItems then
        for _, item in ipairs(runtimeItems:GetDescendants()) do
            if item:IsA("Model") then CreateESP(item, Color3.new(1, 0, 0)) end
        end
    end
    local nightEnemies = workspace:FindFirstChild("NightEnemies")
    if nightEnemies then
        for _, enemy in ipairs(nightEnemies:GetDescendants()) do
            if enemy:IsA("Model") then CreateESP(enemy, Color3.new(0, 0, 1)) end
        end
    end
end

local function AddESPForPlayer(player)
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") or player == plr then return end
    local character = player.Character
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    local humanoid = character:WaitForChild("Humanoid")
    local espFrame = Instance.new("BillboardGui", character)
    espFrame.Adornee = humanoidRootPart
    espFrame.Size = UDim2.new(0, 100, 0, 40)
    espFrame.StudsOffset = Vector3.new(0, 3, 0)
    espFrame.AlwaysOnTop = true
    espFrame.Name = "ESPFrame"
    local frame = Instance.new("Frame", espFrame)
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1
    local healthText = Instance.new("TextLabel", frame)
    healthText.Size = UDim2.new(1, 0, 0.3, 0)
    healthText.BackgroundTransparency = 1
    healthText.TextColor3 = Color3.fromRGB(255, 255, 255)
    healthText.TextSize = 10
    healthText.Text = "Health: " .. math.floor(humanoid.Health)
    humanoid:GetPropertyChangedSignal("Health"):Connect(function()
        healthText.Text = "Health: " .. math.floor(humanoid.Health)
    end)
end

local function AddESPForEnemy(enemy)
    if not enemy or not enemy:FindFirstChild("HumanoidRootPart") or not enemy:FindFirstChild("Humanoid") then return end
    local espFrame = Instance.new("BillboardGui", enemy)
    espFrame.Adornee = enemy.HumanoidRootPart
    espFrame.Size = UDim2.new(0, 100, 0, 40)
    espFrame.StudsOffset = Vector3.new(0, 3, 0)
    espFrame.AlwaysOnTop = true
    espFrame.Name = "ESPFrame"
    local frame = Instance.new("Frame", espFrame)
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1
    local healthText = Instance.new("TextLabel", frame)
    healthText.Size = UDim2.new(1, 0, 0.3, 0)
    healthText.BackgroundTransparency = 1
    healthText.TextColor3 = ESPColor
    healthText.TextSize = 10
    healthText.Text = "Health: " .. math.floor(enemy.Humanoid.Health)
    enemy.Humanoid:GetPropertyChangedSignal("Health"):Connect(function()
        healthText.Text = "Health: " .. math.floor(enemy.Humanoid.Health)
    end)
end

local function GetItemNames()
    local items = {"Select an item"}
    local runtimeItems = workspace:FindFirstChild("RuntimeItems")
    if runtimeItems then
        for _, item in ipairs(runtimeItems:GetDescendants()) do
            if item:IsA("Model") then table.insert(items, item.Name) end
        end
    end
    return items
end

local function applySpeedHack()
    local humanoid = plr.Character and plr.Character:FindFirstChild("Humanoid")
    if humanoid then humanoid.WalkSpeed = speedHackEnabled and speedValue or 16 end
end

local function applyJumpHack()
    local humanoid = plr.Character and plr.Character:FindFirstChild("Humanoid")
    if humanoid then humanoid.JumpHeight = jumpHackEnabled and (7.2 * jumpMultiplier) or 7.2 end
end

local function applyNoClip()
    local char = plr.Character
    if char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = not noClipEnabled end
        end
    end
end

local function getNearestNPC()
    local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local nearest, minDist = nil, math.huge
    for _, npc in ipairs(workspace:GetDescendants()) do
        if npc:IsA("Model") and npc:FindFirstChild("HumanoidRootPart") and npc:FindFirstChild("Humanoid") and not Players:GetPlayerFromCharacter(npc) then
            local hrp, hum = npc.HumanoidRootPart, npc.Humanoid
            local dist = (hrp.Position - root.Position).Magnitude
            if hum.Health > 0 and dist < minDist and dist <= killDist then
                nearest, minDist = npc, dist
            end
        end
    end
    return nearest
end

local function dragAndKill(npc)
    if not npc then return end
    local hum = npc:FindFirstChild("Humanoid")
    if hum and hum.Health <= 0 then return end
    local dragRemote = rs:FindFirstChild("Shared") and rs.Shared:FindFirstChild("Remotes") and rs.Shared.Remotes:FindFirstChild("RequestStartDrag")
    if dragRemote then
        dragRemote:FireServer(npc)
        task.wait(0.5)
        if hum and hum.Health > 0 then npc:BreakJoints() end
    else
        if hum then hum:TakeDamage(hum.MaxHealth) end
    end
end

local function killAuraLoop()
    while auraOn do
        local target = getNearestNPC()
        if target then dragAndKill(target) end
        task.wait(math.random(0.1, 0.3))
    end
end

-- GUI Controls
addToggle("Aimbot", function(v)
    aimbotEnabled = v
    fovCircle.Visible = v
end)
addSlider("FOV Radius", 50, 500, 100, function(v)
    fovRadius = v
    fovCircle.Radius = v
    fovCircle.Position = Cam.ViewportSize / 2
end)
addToggle("ESP Items/Mobs", function(v)
    ESPEnabled = v
    if v then
        UpdateESP()
        spawn(function() while ESPEnabled do UpdateESP() wait(1) end end)
    else
        ClearESP()
    end
end)
addToggle("ESP Players", function(v) ESPPlayerEnabled = v end)
addToggle("ESP Zombies", function(v) ESPZombyEnabled = v end)
addSlider("WalkSpeed", 1, 500, 50, function(v)
    speedValue = v
    applySpeedHack()
end)
addToggle("Speed Hack", function(v)
    speedHackEnabled = v
    applySpeedHack()
end)
addSlider("Jump Height", 10, 500, 50, function(v)
    local humanoid = plr.Character and plr.Character:FindFirstChild("Humanoid")
    if humanoid then humanoid.JumpHeight = v end
end)
addToggle("Infinite Jump", function(v)
    infiniteJumpEnabled = v
    if v then
        UserInputService.JumpRequest:Connect(function()
            local humanoid = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then humanoid:ChangeState("Jumping") end
        end)
    end
end)
addToggle("Fly", function(v)
    flyEnabled = v
    local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if v then
        local speed = 50
        local bodyVelocity = Instance.new("BodyVelocity", hrp)
        bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        local bodyGyro = Instance.new("BodyGyro", hrp)
        bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        bodyGyro.CFrame = hrp.CFrame
        spawn(function()
            while flyEnabled and hrp and hrp.Parent do
                local cam = workspace.CurrentCamera
                local moveDirection = Vector3.new(
                    (UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.A) and 1 or 0),
                    (UserInputService:IsKeyDown(Enum.KeyCode.Space) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) and 1 or 0),
                    (UserInputService:IsKeyDown(Enum.KeyCode.S) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.W) and 1 or 0)
                )
                bodyVelocity.Velocity = cam.CFrame:VectorToWorldSpace(moveDirection) * speed
                bodyGyro.CFrame = cam.CFrame
                RunService.RenderStepped:Wait()
            end
            if bodyVelocity then bodyVelocity:Destroy() end
            if bodyGyro then bodyGyro:Destroy() end
        end)
    else
        local bodyVelocity = hrp:FindFirstChildOfClass("BodyVelocity")
        local bodyGyro = hrp:FindFirstChildOfClass("BodyGyro")
        if bodyVelocity then bodyVelocity:Destroy() end
        if bodyGyro then bodyGyro:Destroy() end
    end
end)
addToggle("Jump Hack", function(v)
    jumpHackEnabled = v
    applyJumpHack()
end)
addSlider("Jump Power", 1, 5, 1.5, function(v)
    jumpMultiplier = v
    applyJumpHack()
end)
addToggle("NoClip", function(v) noClipEnabled = v end)
addToggle("Kill Aura", function(v)
    auraOn = v
    if v then spawn(killAuraLoop) end
end)
addSlider("Kill Aura Range", 5, 50, 15, function(v) killDist = v end)
addButton("Select Item", function()
    selectedItem = GetItemNames()[math.random(2, #GetItemNames())] or "Select an item"
end)
addButton("Collect Item", function()
    if selectedItem == "Select an item" then return end
    local runtimeItems = workspace:FindFirstChild("RuntimeItems")
    if not runtimeItems then return end
    local itemToCollect
    for _, item in ipairs(runtimeItems:GetDescendants()) do
        if item:IsA("Model") and item.Name == selectedItem then
            itemToCollect = item
            break
        end
    end
    if itemToCollect and itemToCollect.PrimaryPart then
        local char = plr.Character or plr.CharacterAdded:Wait()
        local hrp = char:WaitForChild("HumanoidRootPart")
        itemToCollect:SetPrimaryPartCFrame(hrp.CFrame + Vector3.new(0, 1, 0))
    end
end)
addButton("Collect All Items", function()
    local runtimeItems = workspace:FindFirstChild("RuntimeItems")
    if not runtimeItems then return end
    local char = plr.Character or plr.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")
    for _, item in ipairs(runtimeItems:GetDescendants()) do
        if item:IsA("Model") and item.PrimaryPart then
            local offset = hrp.CFrame.LookVector * 5
            item:SetPrimaryPartCFrame(hrp.CFrame + offset)
        end
    end
end)

-- Main Loop
RunService.Heartbeat:Connect(function(dt)
    if aimbotEnabled then
        local target = getTarget()
        if target then aim(predictPos(target)) end
    end
    if ESPPlayerEnabled then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= plr and player.Character and not player.Character:FindFirstChild("ESPFrame") then
                AddESPForPlayer(player)
            end
        end
    end
    if ESPZombyEnabled then
        for _, enemy in pairs(workspace:GetDescendants()) do
            if enemy:IsA("Model") and enemy:FindFirstChild("Humanoid") and not Players:GetPlayerFromCharacter(enemy) and not enemy:FindFirstChild("ESPFrame") then
                AddESPForEnemy(enemy)
            end
        end
    end
end)

RunService.Stepped:Connect(function()
    if noClipEnabled then applyNoClip() end
end)

UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == aimbotKey then aimbotEnabled = true end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == aimbotKey then aimbotEnabled = false end
end)
