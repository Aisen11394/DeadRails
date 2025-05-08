-- Грук LUA: Компактный чит с маленьким GUI, фикс багов, байпас античита, полёт для мобилок
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
local success, err = pcall(function()
    gui.Parent = game:GetService("CoreGui")
end)
if not success then
    gui.Parent = game:GetService("Players").LocalPlayer.PlayerGui
end

-- Кнопка открытия/закрытия
local toggleButton = Instance.new("TextButton", gui)
toggleButton.Size = UDim2.new(0, 50, 0, 50)
toggleButton.Position = UDim2.new(0, 0, 0.5, -25)
toggleButton.Text = ">"
toggleButton.BackgroundColor3 = Color3.new(0, 0, 0)
toggleButton.TextColor3 = Color3.new(1, 1, 1)
toggleButton.TextSize = 20
toggleButton.BackgroundTransparency = 0.5

-- Основной Frame
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 200, 0, 300)
frame.Position = UDim2.new(0, 60, 0.5, -150)
frame.BackgroundColor3 = Color3.new(0, 0, 0)
frame.BackgroundTransparency = 0.5
frame.Visible = false
local scrollingFrame = Instance.new("ScrollingFrame", frame)
scrollingFrame.Size = UDim2.new(1, 0, 1, -30)
scrollingFrame.Position = UDim2.new(0, 0, 0, 30)
scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 600)
scrollingFrame.BackgroundTransparency = 1
scrollingFrame.ScrollBarThickness = 5
local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 30)
title.Text = "Grok LUA"
title.TextColor3 = Color3.new(1, 1, 1)
title.BackgroundTransparency = 1
title.TextSize = 16
local yOffset = 10

-- Функции для GUI
local function addToggle(name, callback)
    local toggle = Instance.new("TextButton", scrollingFrame)
    toggle.Size = UDim2.new(0.9, 0, 0, 25)
    toggle.Position = UDim2.new(0.05, 0, 0, yOffset)
    toggle.Text = name .. ": OFF"
    toggle.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    toggle.TextColor3 = Color3.new(1, 1, 1)
    toggle.TextSize = 12
    local state = false
    toggle.MouseButton1Click:Connect(function()
        state = not state
        toggle.Text = name .. (state and ": ON" or ": OFF")
        callback(state)
    end)
    yOffset = yOffset + 30
    return toggle, function() return state end
end

local function addSlider(name, min, max, default, callback)
    local label = Instance.new("TextLabel", scrollingFrame)
    label.Size = UDim2.new(0.9, 0, 0, 20)
    label.Position = UDim2.new(0.05, 0, 0, yOffset)
    label.Text = name .. ": " .. default
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextSize = 12
    yOffset = yOffset + 25
    local slider = Instance.new("TextButton", scrollingFrame)
    slider.Size = UDim2.new(0.9, 0, 0, 20)
    slider.Position = UDim2.new(0.05, 0, 0, yOffset)
    slider.Text = "- +"
    slider.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
    slider.TextSize = 12
    local value = default
    slider.MouseButton1Click:Connect(function()
        value = value + math.ceil((max - min) / 10)
        if value > max then value = min end
        label.Text = name .. ": " .. value
        callback(value)
    end)
    yOffset = yOffset + 25
    return slider
end

local function addButton(name, callback)
    local button = Instance.new("TextButton", scrollingFrame)
    button.Size = UDim2.new(0.9, 0, 0, 25)
    button.Position = UDim2.new(0.05, 0, 0, yOffset)
    button.Text = name
    button.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.TextSize = 12
    button.MouseButton1Click:Connect(callback)
    yOffset = yOffset + 30
    return button
end

-- Открытие/закрытие GUI
toggleButton.MouseButton1Click:Connect(function()
    frame.Visible = not frame.Visible
    toggleButton.Text = frame.Visible and "<" or ">"
end)

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
local lastPosition = Vector3.new(0, 0, 0)
local infiniteJumpConnection = nil

-- Mobile Fly
local flySpeed = 50
local joystick = Instance.new("Frame", gui)
joystick.Size = UDim2.new(0, 100, 0, 100)
joystick.Position = UDim2.new(0, 10, 1, -110)
joystick.BackgroundColor3 = Color3.new(0.5, 0.5, 0.5)
joystick.BackgroundTransparency = 0.5
joystick.Visible = false
local joystickDot = Instance.new("Frame", joystick)
joystickDot.Size = UDim2.new(0, 20, 0, 20)
joystickDot.Position = UDim2.new(0.5, -10, 0.5, -10)
joystickDot.BackgroundColor3 = Color3.new(1, 1, 1)
local touchStart = nil
local touchId = nil

-- Античит мониторинг
local function checkTeleport()
    local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
    if hrp and (hrp.Position - lastPosition).Magnitude > 50 then
        speedHackEnabled = false
        jumpHackEnabled = false
        infiniteJumpEnabled = false
        flyEnabled = false
        return true
    end
    lastPosition = hrp and hrp.Position or lastPosition
    return false
end

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

local function applySpeedHack(state)
    local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
    local humanoid = plr.Character and plr.Character:FindFirstChild("Humanoid")
    if hrp and humanoid then
        local bodyVelocity = hrp:FindFirstChild("SpeedHackVelocity")
        if state and speedHackEnabled then
            if not bodyVelocity then
                bodyVelocity = Instance.new("BodyVelocity", hrp)
                bodyVelocity.Name = "SpeedHackVelocity"
                bodyVelocity.MaxForce = Vector3.new(math.huge, 0, math.huge)
            end
            bodyVelocity.Velocity = humanoid.MoveDirection * speedValue
        elseif bodyVelocity then
            bodyVelocity:Destroy()
            humanoid.WalkSpeed = 16
        end
    end
end

local function applyJumpHack(state)
    local humanoid = plr.Character and plr.Character:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.JumpHeight = state and jumpHackEnabled and (7.2 * jumpMultiplier) or 7.2
    end
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

local function applyFly(state)
    local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local bodyVelocity = hrp:FindFirstChild("FlyVelocity")
    local bodyGyro = hrp:FindFirstChild("FlyGyro")
    if state and flyEnabled then
        if not bodyVelocity then
            bodyVelocity = Instance.new("BodyVelocity", hrp)
            bodyVelocity.Name = "FlyVelocity"
            bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        end
        if not bodyGyro then
            bodyGyro = Instance.new("BodyGyro", hrp)
            bodyGyro.Name = "FlyGyro"
            bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
            bodyGyro.CFrame = hrp.CFrame
        end
        joystick.Visible = true
    else
        if bodyVelocity then bodyVelocity:Destroy() end
        if bodyGyro then bodyGyro:Destroy() end
        joystick.Visible = false
    end
end

-- Mobile Fly Controls
UserInputService.TouchStarted:Connect(function(input)
    if flyEnabled and input.UserInputState == Enum.UserInputState.Begin then
        touchStart = input.Position
        touchId = input.UserInputId
        joystickDot.Position = UDim2.new(0.5, -10, 0.5, -10)
    end
end)

UserInputService.TouchMoved:Connect(function(input)
    if flyEnabled and input.UserInputId == touchId then
        local delta = input.Position - touchStart
        local normalized = Vector2.new(
            math.clamp(delta.X / 50, -1, 1),
            math.clamp(delta.Y / 50, -1, 1)
        )
        joystickDot.Position = UDim2.new(0.5 + normalized.X * 0.4, -10, 0.5 + normalized.Y * 0.4, -10)
    end
end)

UserInputService.TouchEnded:Connect(function(input)
    if input.UserInputId == touchId then
        touchStart = nil
        touchId = nil
        joystickDot.Position = UDim2.new(0.5, -10, 0.5, -10)
    end
end)

-- GUI Controls
local aimbotToggle = addToggle("Aimbot", function(v)
    aimbotEnabled = v
    fovCircle.Visible = v
end)
addSlider("FOV Radius", 50, 500, 100, function(v)
    fovRadius = v
    fovCircle.Radius = v
    fovCircle.Position = Cam.ViewportSize / 2
end)
local espToggle = addToggle("ESP Items/Mobs", function(v)
    ESPEnabled = v
    if v then
        UpdateESP()
        spawn(function() while ESPEnabled do UpdateESP() wait(1) end end)
    else
        ClearESP()
    end
end)
local espPlayerToggle = addToggle("ESP Players", function(v)
    ESPPlayerEnabled = v
    if not v then
        for _, player in pairs(Players:GetPlayers()) do
            if player.Character then
                local espFrame = player.Character:FindFirstChild("ESPFrame")
                if espFrame then espFrame:Destroy() end
            end
        end
    end
end)
local espZombyToggle = addToggle("ESP Zombies", function(v)
    ESPZombyEnabled = v
    if not v then
        for _, enemy in pairs(workspace:GetDescendants()) do
            if enemy:IsA("Model") and enemy:FindFirstChild("ESPFrame") then
                enemy.ESPFrame:Destroy()
            end
        end
    end
end)
addSlider("WalkSpeed", 16, 100, 50, function(v)
    speedValue = v
    applySpeedHack(speedHackEnabled)
end)
local speedHackToggle = addToggle("Speed Hack", function(v)
    speedHackEnabled = v
    applySpeedHack(v)
end)
addSlider("Jump Height", 7.2, 50, 7.2, function(v)
    jumpMultiplier = v / 7.2
    applyJumpHack(jumpHackEnabled)
end)
local infiniteJumpToggle = addToggle("Infinite Jump", function(v)
    infiniteJumpEnabled = v
    if infiniteJumpConnection then
        infiniteJumpConnection:Disconnect()
        infiniteJumpConnection = nil
    end
    if v then
        infiniteJumpConnection = UserInputService.JumpRequest:Connect(function()
            local humanoid = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid:GetState() ~= Enum.HumanoidStateType.Jumping then
                humanoid:ChangeState("Jumping")
                task.wait(0.2)
            end
        end)
    end
end)
local flyToggle = addToggle("Fly", function(v)
    flyEnabled = v
    applyFly(v)
end)
addSlider("Fly Speed", 10, 100, 50, function(v)
    flySpeed = v
end)
local jumpHackToggle = addToggle("Jump Hack", function(v)
    jumpHackEnabled = v
    applyJumpHack(v)
end)
addSlider("Jump Power", 1, 5, 1.5, function(v)
    jumpMultiplier = v
    applyJumpHack(jumpHackEnabled)
end)
local noClipToggle = addToggle("NoClip", function(v)
    noClipEnabled = v
    if not v then
        local char = plr.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = true end
            end
        end
    end
end)
local killAuraToggle = addToggle("Kill Aura", function(v)
    auraOn = v
    if v then spawn(killAuraLoop) end
end)
addSlider("Kill Aura Range", 5, 50, 15, function(v)
    killDist = v
end)
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
    if speedHackEnabled then
        applySpeedHack(true)
    end
    if flyEnabled then
        local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local bodyVelocity = hrp:FindFirstChild("FlyVelocity")
            local bodyGyro = hrp:FindFirstChild("FlyGyro")
            if bodyVelocity and bodyGyro then
                local moveDirection = Vector3.new(0, 0, 0)
                if touchStart and touchId then
                    local delta = UserInputService:GetMouseLocation() - touchStart
                    moveDirection = Vector3.new(
                        math.clamp(delta.X / 50, -1, 1),
                        -math.clamp(delta.Y / 50, -1, 1),
                        0
                    )
                else
                    moveDirection = Vector3.new(
                        (UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.A) and 1 or 0),
                        (UserInputService:IsKeyDown(Enum.KeyCode.Space) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) and 1 or 0),
                        (UserInputService:IsKeyDown(Enum.KeyCode.S) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.W) and 1 or 0)
                    )
                end
                bodyVelocity.Velocity = Cam.CFrame:VectorToWorldSpace(moveDirection) * flySpeed
                bodyGyro.CFrame = Cam.CFrame
            end
        end
    end
    if checkTeleport() then
        aimbotToggle[1].Text = "Aimbot: OFF"
        espToggle[1].Text = "ESP Items/Mobs: OFF"
        espPlayerToggle[1].Text = "ESP Players: OFF"
        espZombyToggle[1].Text = "ESP Zombies: OFF"
        speedHackToggle[1].Text = "Speed Hack: OFF"
        infiniteJumpToggle[1].Text = "Infinite Jump: OFF"
        flyToggle[1].Text = "Fly: OFF"
        jumpHackToggle[1].Text = "Jump Hack: OFF"
        noClipToggle[1].Text = "NoClip: OFF"
        killAuraToggle[1].Text = "Kill Aura: OFF"
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
