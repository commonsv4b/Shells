local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Network = require(RS.Modules.Communication.Network)

local lp = Players.LocalPlayer
local qte = lp.PlayerGui:WaitForChild("QTE")
local main = qte:WaitForChild("Main")
local line = main:WaitForChild("Line")
local bars = main:WaitForChild("Bars")
local wayStones = workspace:WaitForChild("WayStones")

-- Все переменные (оригинал)
local autoDigBarMethod = false
local autoDigEventMethod = false
local autoTargetDig = false
local autoSell = false
local autoMerchant = false
local eventDelay = 0.5
local sellDelay = 30
local favoritedItems = {}
local weightFilters = {}
local selectedWeightItem = ""
local selectedBuyTool = ""
local minWeightInput = 0
local targetRarities = {}
local workerCount = 3
local lock = false

-- Загрузка данных
local fishList = {}
local shellTools = RS:WaitForChild("Assets"):WaitForChild("Shells"):WaitForChild("Tools")
for _, item in pairs(shellTools:GetChildren()) do
    table.insert(fishList, item.Name)
end
table.sort(fishList)

local equipList = {}
local equipTools = RS:WaitForChild("Assets"):WaitForChild("Equipment"):WaitForChild("Tools")
task.wait(3)
for _, item in pairs(equipTools:GetChildren()) do
    table.insert(equipList, item.Name)
end
table.sort(equipList)

local islandList = {}
for _, island in pairs(wayStones:GetChildren()) do
    table.insert(islandList, island.Name)
end
table.sort(islandList)

-- Функции (все оригинальные)
local function favoriteAll()
    for _, tool in pairs(lp.Backpack:GetChildren()) do
        local fishName = tool.Name:split("_")[1]
        if favoritedItems[fishName] then
            pcall(function()
                local args = {
                    buffer.fromstring("\003\001\001"),
                    {tool}
                }
                RS:WaitForChild("ByteNetReliable"):FireServer(unpack(args))
            end)
        end
    end
end

local function favoriteByWeight()
    for _, tool in pairs(lp.Backpack:GetChildren()) do
        local fishName = tool.Name:split("_")[1]
        local minWeight = weightFilters[fishName]
        if minWeight then
            local weight = tool:GetAttribute("Weight")
            if weight and weight >= minWeight then
                pcall(function()
                    local args = {
                        buffer.fromstring("\003\001\001"),
                        {tool}
                    }
                    RS:WaitForChild("ByteNetReliable"):FireServer(unpack(args))
                end)
            end
        end
    end
end

local function teleportTo(islandName)
    local island = wayStones:FindFirstChild(islandName)
    if island then
        local char = lp.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame = island:GetModelCFrame()
        end
    end
end

local function buyAllMerchant()
    local buying = true
    while buying do
        buying = false
        local result = Network.TravellingMerchant.queries.GetShop.invoke()
        if result then
            local data = HttpService:JSONDecode(result)
            if data.isActive then
                for item, stock in pairs(data.stock or {}) do
                    if stock > 0 then
                        pcall(function()
                            local buyResult = Network.TravellingMerchant.queries.BuyItem.invoke(item)
                            if buyResult and buyResult.success then
                                if buyResult.remaining > 0 then
                                    buying = true
                                end
                            end
                        end)
                        task.wait(0.1)
                    end
                end
            end
        end
    end
end

local function isTargetRarity(rarity)
    return targetRarities[rarity] == true
end

local function spawnWorkers()
    for i = 1, workerCount do
        task.spawn(function()
            while autoTargetDig do
                if not lock then
                    lock = true
                    pcall(function()
                        local args1 = {
                            buffer.fromstring("\016"),
                            [3] = 16
                        }
                        RS:WaitForChild("ByteNetQuery"):InvokeServer(unpack(args1, 1, 3))
                        task.wait(0)
                        local result = Network.QTE.queries.StartQTE.invoke()
                        if result and result.rarity then
                            if isTargetRarity(result.rarity) then
                                task.wait(2)
                                Network.QTE.packets.FinishQTE.send({
                                    state = true,
                                    hits = 45,
                                    perfects = 30
                                })
                                task.wait(1)
                            else
                                Network.QTE.packets.CancelQTE.send()
                            end
                        end
                    end)
                    lock = false
                end
                task.wait(0)
            end
        end)
        task.wait(0.05)
    end
end

-- ===== ПРОСТОЙ UI ДЛЯ SOLARA (без TweenService, без анимаций) =====

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DiamondHub"
ScreenGui.Parent = game.CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Основное окно
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 700, 0, 450)
MainFrame.Position = UDim2.new(0.5, -350, 0.5, -225)
MainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 28)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 40)
TopBar.BackgroundColor3 = Color3.fromRGB(18, 18, 40)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 1, 0)
Title.BackgroundTransparency = 1
Title.Text = "DIAMOND HUB (Solara)"
Title.TextColor3 = Color3.fromRGB(210, 215, 255)
Title.TextSize = 18
Title.Font = Enum.Font.GothamBold
Title.Parent = TopBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -40, 0.5, -15)
CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 14
CloseBtn.Parent = TopBar
CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Вкладки (просто кнопки вверху)
local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, 0, 0, 40)
TabBar.Position = UDim2.new(0, 0, 0, 40)
TabBar.BackgroundColor3 = Color3.fromRGB(14, 14, 32)
TabBar.BorderSizePixel = 0
TabBar.Parent = MainFrame

-- Контейнер для содержимого вкладок
local ContentContainer = Instance.new("ScrollingFrame")
ContentContainer.Size = UDim2.new(1, -10, 1, -90)
ContentContainer.Position = UDim2.new(0, 5, 0, 85)
ContentContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
ContentContainer.BorderSizePixel = 0
ContentContainer.ScrollBarThickness = 5
ContentContainer.Parent = MainFrame

local tabButtons = {} -- храним кнопки
local tabContents = {} -- храним фреймы для каждой вкладки

local function switchTab(tabName)
    for name, frame in pairs(tabContents) do
        frame.Visible = (name == tabName)
    end
    for name, btn in pairs(tabButtons) do
        btn.BackgroundColor3 = (name == tabName) and Color3.fromRGB(60, 80, 180) or Color3.fromRGB(30, 30, 50)
        btn.TextColor3 = (name == tabName) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 180, 200)
    end
end

local function createTab(name)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 120, 0, 35)
    btn.Position = UDim2.new(0, 5 + #tabButtons * 125, 0, 2.5)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(180, 180, 200)
    btn.TextSize = 14
    btn.Font = Enum.Font.GothamSemibold
    btn.Parent = TabBar
    tabButtons[name] = btn

    local contentFrame = Instance.new("Frame")
    contentFrame.Size = UDim2.new(1, 0, 1, 0)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Visible = false
    contentFrame.Parent = ContentContainer
    tabContents[name] = contentFrame

    btn.MouseButton1Click:Connect(function()
        switchTab(name)
    end)

    return contentFrame
end

-- Простая утилита для создания UI-элементов
local function addSection(parent, text)
    local section = Instance.new("TextLabel")
    section.Size = UDim2.new(1, 0, 0, 25)
    section.BackgroundTransparency = 1
    section.Text = text
    section.TextColor3 = Color3.fromRGB(140, 160, 255)
    section.TextSize = 14
    section.Font = Enum.Font.GothamBold
    section.TextXAlignment = Enum.TextXAlignment.Left
    section.Parent = parent
    return section
end

local function addToggle(parent, text, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 35)
    frame.BackgroundColor3 = Color3.fromRGB(22, 22, 40)
    frame.BorderSizePixel = 0
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -50, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(200, 200, 220)
    label.TextSize = 14
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 40, 0, 25)
    toggleBtn.Position = UDim2.new(1, -50, 0.5, -12.5)
    toggleBtn.BackgroundColor3 = default and Color3.fromRGB(80, 120, 255) or Color3.fromRGB(50, 50, 70)
    toggleBtn.Text = default and "ON" or "OFF"
    toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleBtn.TextSize = 12
    toggleBtn.Font = Enum.Font.GothamSemibold
    toggleBtn.Parent = frame

    local state = default
    toggleBtn.MouseButton1Click:Connect(function()
        state = not state
        toggleBtn.BackgroundColor3 = state and Color3.fromRGB(80, 120, 255) or Color3.fromRGB(50, 50, 70)
        toggleBtn.Text = state and "ON" or "OFF"
        callback(state)
    end)
    return frame
end

local function addButton(parent, text, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 35)
    btn.BackgroundColor3 = Color3.fromRGB(60, 80, 200)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 14
    btn.Font = Enum.Font.GothamSemibold
    btn.Parent = parent
    btn.MouseButton1Click:Connect(callback)
    return btn
end

local function addInput(parent, placeholder, callback)
    local input = Instance.new("TextBox")
    input.Size = UDim2.new(1, 0, 0, 30)
    input.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
    input.Text = ""
    input.PlaceholderText = placeholder
    input.TextColor3 = Color3.fromRGB(255, 255, 255)
    input.PlaceholderColor3 = Color3.fromRGB(120, 120, 140)
    input.TextSize = 14
    input.Font = Enum.Font.Gotham
    input.Parent = parent
    input.FocusLost:Connect(function()
        callback(input.Text)
    end)
    return input
end

-- Создаем все вкладки
local digTab = createTab("Auto Dig")
local sellTab = createTab("Auto Sell")
local favTab = createTab("Auto Favorite")
local weightTab = createTab("Fav by Weight")
local buyTab = createTab("Buy Tool")
local tpTab = createTab("Teleport")
local merchTab = createTab("Merchant")

-- ===== Заполняем вкладки =====

-- DigTab
addSection(digTab, "Method 1 - Bar Follow")
addToggle(digTab, "Bar Follow Line", false, function(val) autoDigBarMethod = val end)

addSection(digTab, "Method 2 - Event Fire")
addToggle(digTab, "Auto Dig (Events)", false, function(val)
    autoDigEventMethod = val
    if val then
        task.spawn(function()
            while autoDigEventMethod do
                pcall(function()
                    local args1 = {
                        buffer.fromstring("\016"),
                        [3] = 16
                    }
                    RS:WaitForChild("ByteNetQuery"):InvokeServer(unpack(args1, 1, 3))
                end)
                task.wait(eventDelay)
                pcall(function()
                    local args2 = {
                        buffer.fromstring("*\001\002\000\002\000")
                    }
                    RS:WaitForChild("ByteNetReliable"):FireServer(unpack(args2))
                end)
                task.wait(0.5)
            end
        end)
    end
end)

addSection(digTab, "Event Loop Delay (s)")
local delayInput = addInput(digTab, "Current: 0.5", function(val)
    local num = tonumber(val)
    if num then eventDelay = num end
end)
delayInput.Text = "0.5"

addSection(digTab, "Method 3 - Targeted Dig")
addToggle(digTab, "Target: Legendary", false, function(val) targetRarities["Legendary"] = val end)
addToggle(digTab, "Target: Mythic", false, function(val) targetRarities["Mythic"] = val end)
addToggle(digTab, "Target: Exotic", false, function(val) targetRarities["Exotic"] = val end)

addSection(digTab, "Worker Count")
local workerInput = addInput(digTab, "Current: 3", function(val)
    local num = tonumber(val)
    if num then workerCount = num end
end)
workerInput.Text = "3"

addToggle(digTab, "Targeted Dig", false, function(val)
    autoTargetDig = val
    if val then spawnWorkers() end
end)

-- SellTab
addSection(sellTab, "Auto Sell")
addToggle(sellTab, "Auto Sell", false, function(val)
    autoSell = val
    if val then
        task.spawn(function()
            while autoSell do
                pcall(function() Network.Merchant.packets.SellAll.send() end)
                task.wait(sellDelay)
            end
        end)
    end
end)

addSection(sellTab, "Sell Delay (s)")
local sellDelayInput = addInput(sellTab, "Current: 30", function(val)
    local num = tonumber(val)
    if num then sellDelay = num end
end)
sellDelayInput.Text = "30"

-- FavoriteTab
addSection(favTab, "Select Items to Favorite")
for _, fishName in pairs(fishList) do
    addToggle(favTab, fishName, false, function(val) favoritedItems[fishName] = val end)
end

addSection(favTab, "Run")
addButton(favTab, "Favorite Selected Now", function()
    favoriteAll()
    warn("Favorited selected items!")
end)

addToggle(favTab, "Auto Favorite on Backpack Change", false, function(val)
    if val then
        lp.Backpack.ChildAdded:Connect(function()
            task.wait(0.1)
            favoriteAll()
        end)
    end
end)

-- FavWeightTab
addSection(weightTab, "Add Weight Filter")
-- Простой выбор из списка: используем кнопки с перебором по порядковому номеру
local itemIndex = 1
addButton(weightTab, "Next Item: " .. fishList[itemIndex], function()
    itemIndex = itemIndex + 1
    if itemIndex > #fishList then itemIndex = 1 end
    selectedWeightItem = fishList[itemIndex]
    -- обновим текст на кнопке? но кнопка уже создана, проще добавить текстовую метку
end)

local weightLabel = Instance.new("TextLabel")
weightLabel.Size = UDim2.new(1, 0, 0, 20)
weightLabel.BackgroundTransparency = 1
weightLabel.Text = "Selected: " .. fishList[itemIndex]
weightLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
weightLabel.Parent = weightTab

local minWeightInputField = addInput(weightTab, "Min weight (kg)", function(val)
    minWeightInput = tonumber(val) or 0
end)

addButton(weightTab, "Add Filter", function()
    if selectedWeightItem ~= "" and minWeightInput > 0 then
        weightFilters[selectedWeightItem] = minWeightInput
        warn("Filter added: " .. selectedWeightItem .. " >= " .. minWeightInput)
    end
end)

addButton(weightTab, "Remove Selected Filter", function()
    if weightFilters[selectedWeightItem] then
        weightFilters[selectedWeightItem] = nil
        warn("Filter removed")
    end
end)

addSection(weightTab, "Run")
addButton(weightTab, "Favorite by Weight Now", function()
    favoriteByWeight()
    warn("Favorited by weight!")
end)

addToggle(weightTab, "Auto Fav by Weight on Change", false, function(val)
    if val then
        lp.Backpack.ChildAdded:Connect(function()
            task.wait(0.1)
            favoriteByWeight()
        end)
    end
end)

-- BuyTab
addSection(buyTab, "Select Tool to Buy")
-- Опять простой выбор через кнопку
local toolIndex = 1
addButton(buyTab, "Next Tool: " .. equipList[toolIndex], function()
    toolIndex = toolIndex + 1
    if toolIndex > #equipList then toolIndex = 1 end
    selectedBuyTool = equipList[toolIndex]
end)

local buyLabel = Instance.new("TextLabel")
buyLabel.Size = UDim2.new(1, 0, 0, 20)
buyLabel.BackgroundTransparency = 1
buyLabel.Text = "Selected: " .. equipList[toolIndex]
buyLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
buyLabel.Parent = buyTab

addButton(buyTab, "Buy Tool", function()
    if selectedBuyTool ~= "" then
        pcall(function() Network.Equipment.queries.Buy.invoke(selectedBuyTool) end)
        warn("Buying: " .. selectedBuyTool)
    end
end)

-- TpTab
addSection(tpTab, "Islands")
for _, name in pairs(islandList) do
    addButton(tpTab, name, function()
        teleportTo(name)
        warn("Teleported to " .. name)
    end)
end

-- MerchantTab
addSection(merchTab, "Travelling Merchant")
addButton(merchTab, "Check Status", function()
    pcall(function()
        local result = Network.TravellingMerchant.queries.GetShop.invoke()
        if result then
            local data = HttpService:JSONDecode(result)
            if data.isActive then
                warn("Merchant ACTIVE!")
            else
                local timeLeft = data.nextChangeTime - os.time()
                warn("Arrives in " .. math.floor(timeLeft/60) .. "m")
            end
        end
    end)
end)

addButton(merchTab, "Buy All Now", function()
    pcall(function()
        local result = Network.TravellingMerchant.queries.GetShop.invoke()
        if result then
            local data = HttpService:JSONDecode(result)
            if data.isActive then
                task.spawn(buyAllMerchant)
                warn("Buying all merchant items...")
            else
                warn("Merchant not active")
            end
        end
    end)
end)

addToggle(merchTab, "Auto Buy When Arrives", false, function(val)
    autoMerchant = val
    if val then
        task.spawn(function()
            local bought = false
            while autoMerchant do
                pcall(function()
                    local result = Network.TravellingMerchant.queries.GetShop.invoke()
                    if result then
                        local data = HttpService:JSONDecode(result)
                        if data.isActive and not bought then
                            buyAllMerchant()
                            bought = true
                            warn("Bought all!")
                        elseif not data.isActive then
                            bought = false
                        end
                    end
                end)
                task.wait(5)
            end
        end)
    end
end)

-- Выбираем первую вкладку по умолчанию
switchTab("Auto Dig")

-- Оригинальная связка с RenderStepped
RunService.RenderStepped:Connect(function()
    if autoDigBarMethod and qte.Enabled then
        pcall(function()
            local rot = line.Rotation
            bars.Bar_10.Rotation = rot
            bars.Bar_15.Rotation = rot
            bars.Bar_20.Rotation = rot
        end)
    end
end)

print("Diamond Hub loaded for Solara!")
