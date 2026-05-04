-- Ultra-Lightweight UI for Solara
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

local Network = require(RS.Modules.Communication.Network)
local lp = Players.LocalPlayer

-- Безопасная загрузка с таймаутом чтобы не висло
local qte = lp.PlayerGui:WaitForChild("QTE", 10)
local main = qte and qte:WaitForChild("Main", 10)
local line = main and main:WaitForChild("Line", 10)
local bars = main and main:WaitForChild("Bars", 10)
local wayStones = workspace:WaitForChild("WayStones", 10)

local autoDigBarMethod, autoDigEventMethod, autoTargetDig, autoSell, autoMerchant = false, false, false, false, false
local eventDelay, sellDelay, workerCount = 0.5, 30, 3
local favoritedItems, weightFilters, targetRarities = {}, {}, {}
local lock = false

local fishList, equipList, islandList = {}, {}, {}
local shellTools = RS:WaitForChild("Assets"):WaitForChild("Shells"):WaitForChild("Tools", 10)
if shellTools then for _, i in pairs(shellTools:GetChildren()) do table.insert(fishList, i.Name) end end

local equipTools = RS:WaitForChild("Assets"):WaitForChild("Equipment"):WaitForChild("Tools", 10)
if equipTools then wait(1) for _, i in pairs(equipTools:GetChildren()) do table.insert(equipList, i.Name) end end

if wayStones then for _, i in pairs(wayStones:GetChildren()) do table.insert(islandList, i.Name) end end

-- === СОЗДАНИЕ МИНИМАЛИСТИЧНОГО UI ===
local gui = Instance.new("ScreenGui")
gui.Name = "SolaraHub"
gui.Parent = game.CoreGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 240, 0, 400)
frame.Position = UDim2.new(0.5, -120, 0.5, -200)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 45)
frame.BorderSizePixel = 1
frame.BorderColor3 = Color3.fromRGB(80, 80, 150)
frame.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.Text = "Diamond Hub [Solara]"
title.TextColor3 = Color3.fromRGB(255,255,255)
title.TextSize = 15
title.Font = Enum.Font.SourceSansBold
title.Parent = frame

-- Перетаскивание окна
local drag, dragStart, startPos = false, nil, nil
title.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        drag = true; dragStart = i.Position; startPos = frame.Position
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + (i.Position.X - dragStart.X), startPos.Y.Scale, startPos.Y.Offset + (i.Position.Y - dragStart.Y))
    end
end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end end)

local content = Instance.new("ScrollingFrame")
content.Size = UDim2.new(1, -10, 1, -40)
content.Position = UDim2.new(0, 5, 0, 35)
content.BackgroundTransparency = 1
content.ScrollBarThickness = 4
content.CanvasSize = UDim2.new(0, 0, 0, 1200) -- Фиксированный размер, чтобы не лагало
content.Parent = frame

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 4)
layout.Parent = content

-- === ЛЁГКИЕ ФУНКЦИИ ДЛЯ СОЗДАНИЯ ЭЛЕМЕНТОВ ===
local function addSection(txt)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -10, 0, 20)
    l.BackgroundTransparency = 1
    l.Text = txt
    l.TextColor3 = Color3.fromRGB(150, 150, 255)
    l.TextSize = 13
    l.Font = Enum.Font.SourceSansBold
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = content
end

local function makeToggle(txt, def, cb)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -10, 0, 28)
    b.BackgroundColor3 = def and Color3.fromRGB(0,120,0) or Color3.fromRGB(120,0,0)
    b.Text = (def and "[ON] " or "[OFF] ") .. txt
    b.TextColor3 = Color3.fromRGB(255,255,255)
    b.TextSize = 13
    b.Font = Enum.Font.SourceSans
    b.Parent 
