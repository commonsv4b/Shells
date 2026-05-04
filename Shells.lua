-- extracurlydiamond | Solara Compatible
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

-- Ждём загрузки модулей
local Network = require(RS:WaitForChild("Modules"):WaitForChild("Communication"):WaitForChild("Network"))

local lp = Players.LocalPlayer
local char = lp.Character or lp.CharacterAdded:Wait()

local wayStones = workspace:WaitForChild("WayStones")
local shellTools = RS:WaitForChild("Assets"):WaitForChild("Shells"):WaitForChild("Tools")
local equipTools = RS:WaitForChild("Assets"):WaitForChild("Equipment"):WaitForChild("Tools")

-- Состояния
local State = {
    autoDigBar = false,
    autoDigEvent = false,
    autoTargetDig = false,
    autoSell = false,
    autoMerchant = false,
    autoFav = false,
    autoFavWeight = false,
}

local Settings = {
    eventDelay = 0.5,
    sellDelay = 30,
    workerCount = 3,
}

local favoritedItems = {}
local weightFilters = {}
local targetRarities = {}
local lock = false

-- Списки
local fishList = {}
for _, v in pairs(shellTools:GetChildren()) do
    table.insert(fishList, v.Name)
end
table.sort(fishList)

task.wait(3)
local equipList = {}
for _, v in pairs(equipTools:GetChildren()) do
    table.insert(equipList, v.Name)
end
table.sort(equipList)

local islandList = {}
for _, v in pairs(wayStones:GetChildren()) do
    table.insert(islandList, v.Name)
end
table.sort(islandList)

-- ==================== CORE FUNCTIONS ====================

local function sendReliable(data)
    pcall(function()
        RS:WaitForChild("ByteNetReliable"):FireServer(buffer.fromstring(data))
    end)
end

local function favoriteAll()
    for _, tool in pairs(lp.Backpack:GetChildren()) do
        local name = tool.Name:split("_")[1]
        if favoritedItems[name] then
            pcall(function()
                RS:WaitForChild("ByteNetReliable"):FireServer(
                    buffer.fromstring("\003\001\001"), {tool}
                )
            end)
            task.wait(0.05)
        end
    end
end

local function favoriteByWeight()
    for _, tool in pairs(lp.Backpack:GetChildren()) do
        local name = tool.Name:split("_")[1]
        local minW = weightFilters[name]
        if minW then
            local w = tool:GetAttribute("Weight")
            if w and w >= minW then
                pcall(function()
                    RS:WaitForChild("ByteNetReliable"):FireServer(
                        buffer.fromstring("\003\001\001"), {tool}
                    )
                end)
                task.wait(0.05)
            end
        end
    end
end

local function teleportTo(islandName)
    local island = wayStones:FindFirstChild(islandName)
    if island then
        local c = lp.Character
        if c and c:FindFirstChild("HumanoidRootPart") then
            c.HumanoidRootPart.CFrame = island:GetModelCFrame()
        end
    end
end

local function doSell()
    pcall(function()
        Network.Merchant.packets.SellAll.send()
    end)
end

local function spawnWorkers()
    for i = 1, Settings.workerCount do
        task.spawn(function()
            while State.autoTargetDig do
                if not lock then
                    lock = true
                    pcall(function()
                        RS:WaitForChild("ByteNetQuery"):InvokeServer(
                            buffer.fromstring("\016"), nil, 16
                        )
                        task.wait(0)
                        local result = Network.QTE.queries.StartQTE.invoke()
                        if result and result.rarity then
                            if targetRarities[result.rarity] then
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

local function buyAllMerchant()
    local buying = true
    while buying do
        buying = false
        pcall(function()
            local result = Network.TravellingMerchant.queries.GetShop.invoke()
            if result then
                local data = HttpService:JSONDecode(result)
                if data.isActive then
                    for item, stock in pairs(data.stock or {}) do
                        if stock > 0 then
                            pcall(function()
                                local r = Network.TravellingMerchant.queries.BuyItem.invoke(item)
                                if r and r.success and r.remaining > 0 then
                                    buying = true
                                end
                            end)
                            task.wait(0.1)
                        end
                    end
                end
            end
        end)
    end
end

-- ==================== AUTO LOOPS ====================

-- Auto Sell Loop
task.spawn(function()
    while true do
        task.wait(1)
        if State.autoSell then
            doSell()
            task.wait(Settings.sellDelay)
        end
    end
end)

-- Auto Dig Event Loop
task.spawn(function()
    while true do
        task.wait(0.1)
        if State.autoDigEvent then
            pcall(function()
                RS:WaitForChild("ByteNetQuery"):InvokeServer(
                    buffer.fromstring("\016"), nil, 16
                )
            end)
            task.wait(Settings.eventDelay)
            pcall(function()
                RS:WaitForChild("ByteNetReliable"):FireServer(
                    buffer.fromstring("*\001\002\000\002\000")
                )
            end)
            task.wait(0.5)
        end
    end
end)

-- Auto Merchant Loop
task.spawn(function()
    local bought = false
    while true do
        task.wait(5)
        if State.autoMerchant then
            pcall(function()
                local result = Network.TravellingMerchant.queries.GetShop.invoke()
                if result then
                    local data = HttpService:JSONDecode(result)
                    if data.isActive and not bought then
                        buyAllMerchant()
                        bought = true
                        print("[Merchant] Bought all!")
                    elseif not data.isActive then
                        bought = false
                    end
                end
            end)
        end
    end
end)

-- Auto Favorite on pickup
lp.Backpack.ChildAdded:Connect(function()
    task.wait(0.1)
    if State.autoFav then favoriteAll() end
    if State.autoFavWeight then favoriteByWeight() end
end)

-- Bar Follow
local qteGui = lp.PlayerGui:WaitForChild("QTE", 10)
if qteGui then
    local main = qteGui:FindFirstChild("Main")
    if main then
        local line = main:FindFirstChild("Line")
        local bars = main:FindFirstChild("Bars")
        RunService.RenderStepped:Connect(function()
            if State.autoDigBar and qteGui.Enabled and line and bars then
                pcall(function()
                    local rot = line.Rotation
                    if bars:FindFirstChild("Bar_10") then bars.Bar_10.Rotation = rot end
                    if bars:FindFirstChild("Bar_15") then bars.Bar_15.Rotation = rot end
                    if bars:FindFirstChild("Bar_20") then bars.Bar_20.Rotation = rot end
                end)
            end
        end)
    end
end

-- ==================== SIMPLE GUI ====================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "extracurlydiamond"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Безопасное добавление GUI
local success = pcall(function()
    ScreenGui.Parent = lp:WaitForChild("PlayerGui")
end)
if not success then
    ScreenGui.Parent = game:GetService("CoreGui")
end

-- Главный фрейм
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 320, 0, 500)
Main.Position = UDim2.new(0.5, -160, 0.5, -250)
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 30)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui

Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 8)

-- Топбар
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 36)
TopBar.BackgroundColor3 = Color3.fromRGB(25, 25, 55)
TopBar.BorderSizePixel = 0
TopBar.Parent = Main

Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 8)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -10, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "extracurlydiamond"
Title.TextColor3 = Color3.fromRGB(160, 175, 255)
Title.TextSize = 16
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

-- Кнопка закрытия
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -33, 0, 3)
CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 14
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = TopBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)
CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Минимизировать
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 30, 0, 30)
MinBtn.Position = UDim2.new(1, -67, 0, 3)
MinBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 100)
MinBtn.Text = "_"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.TextSize = 14
MinBtn.Font = Enum.Font.GothamBold
MinBtn.BorderSizePixel = 0
MinBtn.Parent = TopBar
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

local minimized = false
local ContentFrame
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if ContentFrame then
        ContentFrame.Visible = not minimized
    end
    Main.Size = minimized and UDim2.new(0, 320, 0, 36) or UDim2.new(0, 320, 0, 500)
end)

-- Табы
local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, 0, 0, 30)
TabBar.Position = UDim2.new(0, 0, 0, 36)
TabBar.BackgroundColor3 = Color3.fromRGB(20, 20, 45)
TabBar.BorderSizePixel = 0
TabBar.Parent = Main

local TabLayout = Instance.new("UIListLayout")
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabLayout.Parent = TabBar

ContentFrame = Instance.new("Frame")
ContentFrame.Name = "Content"
ContentFrame.Size = UDim2.new(1, 0, 1, -66)
ContentFrame.Position = UDim2.new(0, 0, 0, 66)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = Main

-- ==================== TAB SYSTEM ====================

local tabs = {}
local tabContents = {}
local activeTab = nil

local tabNames = {"Dig", "Sell", "Fav", "Weight", "Buy", "TP", "Merchant"}

local function createTab(name, order)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 45, 1, 0)
    btn.BackgroundColor3 = Color3.fromRGB(20, 20, 45)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(120, 120, 180)
    btn.TextSize = 10
    btn.Font = Enum.Font.Gotham
    btn.BorderSizePixel = 0
    btn.LayoutOrder = order
    btn.Parent = TabBar

    local content = Instance.new("ScrollingFrame")
    content.Size = UDim2.new(1, 0, 1, 0)
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.ScrollBarThickness = 4
    content.ScrollBarImageColor3 = Color3.fromRGB(100, 120, 255)
    content.Visible = false
    content.Parent = ContentFrame
    content.AutomaticCanvasSize = Enum.AutomaticSize.Y
    content.CanvasSize = UDim2.new(0, 0, 0, 0)

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 4)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = content

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 6)
    padding.PaddingLeft = UDim.new(0, 6)
    padding.PaddingRight = UDim.new(0, 6)
    padding.Parent = content

    tabs[name] = btn
    tabContents[name] = content

    btn.MouseButton1Click:Connect(function()
        if activeTab then
            tabContents[activeTab].Visible = false
            tabs[activeTab].BackgroundColor3 = Color3.fromRGB(20, 20, 45)
            tabs[activeTab].TextColor3 = Color3.fromRGB(120, 120, 180)
        end
        activeTab = name
        content.Visible = true
        btn.BackgroundColor3 = Color3.fromRGB(35, 35, 80)
        btn.TextColor3 = Color3.fromRGB(160, 175, 255)
    end)

    return content
end

for i, name in ipairs(tabNames) do
    createTab(name, i)
end

-- Активируем первый таб
do
    local firstName = tabNames[1]
    activeTab = firstName
    tabContents[firstName].Visible = true
    tabs[firstName].BackgroundColor3 = Color3.fromRGB(35, 35, 80)
    tabs[firstName].TextColor3 = Color3.fromRGB(160, 175, 255)
end

-- ==================== UI HELPERS ====================

local function makeToggle(parent, labelText, order, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -12, 0, 32)
    row.BackgroundColor3 = Color3.fromRGB(22, 22, 50)
    row.BorderSizePixel = 0
    row.LayoutOrder = order
    row.Parent = parent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -50, 1, 0)
    lbl.Position = UDim2.new(0, 8, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = Color3.fromRGB(210, 215, 255)
    lbl.TextSize = 12
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local togBtn = Instance.new("TextButton")
    togBtn.Size = UDim2.new(0, 36, 0, 20)
    togBtn.Position = UDim2.new(1, -44, 0.5, -10)
    togBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 90)
    togBtn.Text = "OFF"
    togBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
    togBtn.TextSize = 10
    togBtn.Font = Enum.Font.GothamBold
    togBtn.BorderSizePixel = 0
    togBtn.Parent = row
    Instance.new("UICorner", togBtn).CornerRadius = UDim.new(0, 10)

    local enabled = false
    togBtn.MouseButton1Click:Connect(function()
        enabled = not enabled
        togBtn.Text = enabled and "ON" or "OFF"
        togBtn.BackgroundColor3 = enabled 
            and Color3.fromRGB(80, 120, 255) 
            or Color3.fromRGB(50, 50, 90)
        togBtn.TextColor3 = enabled 
            and Color3.fromRGB(255, 255, 255)
            or Color3.fromRGB(180, 180, 180)
        callback(enabled)
    end)

    return togBtn
end

local function makeButton(parent, labelText, order, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -12, 0, 32)
    btn.BackgroundColor3 = Color3.fromRGB(55, 60, 140)
    btn.Text = labelText
    btn.TextColor3 = Color3.fromRGB(220, 225, 255)
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    btn.LayoutOrder = order
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

local function makeLabel(parent, text, order)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -12, 0, 22)
    lbl.BackgroundColor3 = Color3.fromRGB(18, 18, 42)
    lbl.Text = "  " .. text
    lbl.TextColor3 = Color3.fromRGB(140, 160, 255)
    lbl.TextSize = 11
    lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.BorderSizePixel = 0
    lbl.LayoutOrder = order
    lbl.Parent = parent
    Instance.new("UICorner", lbl).CornerRadius = UDim.new(0, 4)
    return lbl
end

local function makeInput(parent, placeholder, order, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -12, 0, 32)
    row.BackgroundColor3 = Color3.fromRGB(20, 20, 45)
    row.BorderSizePixel = 0
    row.LayoutOrder = order
    row.Parent = parent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

    local inp = Instance.new("TextBox")
    inp.Size = UDim2.new(1, -10, 1, -6)
    inp.Position = UDim2.new(0, 5, 0, 3)
    inp.BackgroundTransparency = 1
    inp.PlaceholderText = placeholder
    inp.PlaceholderColor3 = Color3.fromRGB(90, 90, 140)
    inp.Text = ""
    inp.TextColor3 = Color3.fromRGB(210, 215, 255)
    inp.TextSize = 12
    inp.Font = Enum.Font.Gotham
    inp.TextXAlignment = Enum.TextXAlignment.Left
    inp.ClearTextOnFocus = false
    inp.Parent = row

    inp.FocusLost:Connect(function()
        callback(inp.Text)
    end)

    return inp
end

local function makeDropdown(parent, options, order, callback)
    local current = options[1] or ""
    
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -12, 0, 32)
    row.BackgroundColor3 = Color3.fromRGB(22, 22, 50)
    row.BorderSizePixel = 0
    row.LayoutOrder = order
    row.ClipsDescendants = false
    row.ZIndex = 10
    row.Parent = parent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

    local dropBtn = Instance.new("TextButton")
    dropBtn.Size = UDim2.new(1, 0, 1, 0)
    dropBtn.BackgroundTransparency = 1
    dropBtn.Text = "  " .. current .. "  ▼"
    dropBtn.TextColor3 = Color3.fromRGB(210, 215, 255)
    dropBtn.TextSize = 11
    dropBtn.Font = Enum.Font.Gotham
    dropBtn.TextXAlignment = Enum.TextXAlignment.Left
    dropBtn.ZIndex = 11
    dropBtn.Parent = row

    local listFrame = Instance.new("Frame")
    listFrame.Size = UDim2.new(1, 0, 0, math.min(#options, 6) * 26)
    listFrame.Position = UDim2.new(0, 0, 1, 2)
    listFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 55)
    listFrame.BorderSizePixel = 0
    listFrame.Visible = false
    listFrame.ZIndex = 20
    listFrame.ClipsDescendants = true
    listFrame.Parent = row
    Instance.new("UICorner", listFrame).CornerRadius = UDim.new(0, 6)

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, 0, 1, 0)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 3
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.ZIndex = 21
    scroll.Parent = listFrame

    local ll = Instance.new("UIListLayout")
    ll.SortOrder = Enum.SortOrder.LayoutOrder
    ll.Parent = scroll

    for i, opt in ipairs(options) do
        local optBtn = Instance.new("TextButton")
        optBtn.Size = UDim2.new(1, 0, 0, 26)
        optBtn.BackgroundTransparency = 1
        optBtn.Text = "  " .. opt
        optBtn.TextColor3 = Color3.fromRGB(200, 205, 255)
        optBtn.TextSize = 11
        optBtn.Font = Enum.Font.Gotham
        optBtn.TextXAlignment = Enum.TextXAlignment.Left
        optBtn.ZIndex = 22
        optBtn.LayoutOrder = i
        optBtn.Parent = scroll

        optBtn.MouseButton1Click:Connect(function()
            current = opt
            dropBtn.Text = "  " .. opt .. "  ▼"
            listFrame.Visible = false
            callback(opt)
        end)

        optBtn.MouseEnter:Connect(function()
            optBtn.BackgroundTransparency = 0
            optBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 90)
        end)
        optBtn.MouseLeave:Connect(function()
            optBtn.BackgroundTransparency = 1
        end)
    end

    dropBtn.MouseButton1Click:Connect(function()
        listFrame.Visible = not listFrame.Visible
    end)

    callback(current)
    return row, function() return current end
end

-- ==================== DIG TAB ====================

local digTab = tabContents["Dig"]
local digOrder = 1

makeLabel(digTab, "Method 1 - Bar Follow", digOrder) digOrder += 1
makeToggle(digTab, "Bar Follow Line", digOrder, function(v)
    State.autoDigBar = v
end) digOrder += 1

makeLabel(digTab, "Method 2 - Event Fire", digOrder) digOrder += 1
makeToggle(digTab, "Auto Dig (Events)", digOrder, function(v)
    State.autoDigEvent = v
end) digOrder += 1

-- Слайдер задержки (упрощённый)
local delayRow = Instance.new("Frame")
delayRow.Size = UDim2.new(1, -12, 0, 32)
delayRow.BackgroundColor3 = Color3.fromRGB(22, 22, 50)
delayRow.BorderSizePixel = 0
delayRow.LayoutOrder = digOrder
delayRow.Parent = digTab
digOrder += 1
Instance.new("UICorner", delayRow).CornerRadius = UDim.new(0, 6)

local delayLbl = Instance.new("TextLabel")
delayLbl.Size = UDim2.new(1, -80, 1, 0)
delayLbl.Position = UDim2.new(0, 8, 0, 0)
delayLbl.BackgroundTransparency = 1
delayLbl.Text = "Event Delay: 0.5s"
delayLbl.TextColor3 = Color3.fromRGB(210, 215, 255)
delayLbl.TextSize = 11
delayLbl.Font = Enum.Font.Gotham
delayLbl.TextXAlignment = Enum.TextXAlignment.Left
delayLbl.Parent = delayRow

local delayInput = Instance.new("TextBox")
delayInput.Size = UDim2.new(0, 60, 0, 22)
delayInput.Position = UDim2.new(1, -68, 0.5, -11)
delayInput.BackgroundColor3 = Color3.fromRGB(30, 30, 65)
delayInput.Text = "0.5"
delayInput.TextColor3 = Color3.fromRGB(210, 215, 255)
delayInput.TextSize = 11
delayInput.Font = Enum.Font.Gotham
delayInput.BorderSizePixel = 0
delayInput.Parent = delayRow
Instance.new("UICorner", delayInput).CornerRadius = UDim.new(0, 4)
delayInput.FocusLost:Connect(function()
    local v = tonumber(delayInput.Text)
    if v then
        Settings.eventDelay = math.clamp(v, 0.1, 2)
        delayLbl.Text = "Event Delay: " .. Settings.eventDelay .. "s"
    end
end)

makeLabel(digTab, "Method 3 - Targeted Dig", digOrder) digOrder += 1
makeToggle(digTab, "Target: Legendary", digOrder, function(v)
    targetRarities["Legendary"] = v
end) digOrder += 1
makeToggle(digTab, "Target: Mythic", digOrder, function(v)
    targetRarities["Mythic"] = v
end) digOrder += 1
makeToggle(digTab, "Target: Exotic", digOrder, function(v)
    targetRarities["Exotic"] = v
end) digOrder += 1

-- Workers Input
local wRow = Instance.new("Frame")
wRow.Size = UDim2.new(1, -12, 0, 32)
wRow.BackgroundColor3 = Color3.fromRGB(22, 22, 50)
wRow.BorderSizePixel = 0
wRow.LayoutOrder = digOrder
wRow.Parent = digTab
digOrder += 1
Instance.new("UICorner", wRow).CornerRadius = UDim.new(0, 6)

local wLbl = Instance.new("TextLabel")
wLbl.Size = UDim2.new(1, -80, 1, 0)
wLbl.Position = UDim2.new(0, 8, 0, 0)
wLbl.BackgroundTransparency = 1
wLbl.Text = "Workers: 3"
wLbl.TextColor3 = Color3.fromRGB(210, 215, 255)
wLbl.TextSize = 11
wLbl.Font = Enum.Font.Gotham
wLbl.TextXAlignment = Enum.TextXAlignment.Left
wLbl.Parent = wRow

local wInput = Instance.new("TextBox")
wInput.Size = UDim2.new(0, 60, 0, 22)
wInput.Position = UDim2.new(1, -68, 0.5, -11)
wInput.BackgroundColor3 = Color3.fromRGB(30, 30, 65)
wInput.Text = "3"
wInput.TextColor3 = Color3.fromRGB(210, 215, 255)
wInput.TextSize = 11
wInput.Font = Enum.Font.Gotham
wInput.BorderSizePixel = 0
wInput.Parent = wRow
Instance.new("UICorner", wInput).CornerRadius = UDim.new(0, 4)
wInput.FocusLost:Connect(function()
    local v = tonumber(wInput.Text)
    if v then
        Settings.workerCount = math.clamp(math.floor(v), 1, 10)
        wLbl.Text = "Workers: " .. Settings.workerCount
    end
end)

makeToggle(digTab, "Targeted Dig", digOrder, function(v)
    State.autoTargetDig = v
    if v then spawnWorkers() end
end) digOrder += 1

-- ==================== SELL TAB ====================

local sellTab = tabContents["Sell"]
local sellOrder = 1

makeLabel(sellTab, "Auto Sell Settings", sellOrder) sellOrder += 1
makeToggle(sellTab, "Auto Sell", sellOrder, function(v)
    State.autoSell = v
end) sellOrder += 1

local sRow = Instance.new("Frame")
sRow.Size = UDim2.new(1, -12, 0, 32)
sRow.BackgroundColor3 = Color3.fromRGB(22, 22, 50)
sRow.BorderSizePixel = 0
sRow.LayoutOrder = sellOrder
sRow.Parent = sellTab
sellOrder += 1
Instance.new("UICorner", sRow).CornerRadius = UDim.new(0, 6)

local sLbl = Instance.new("TextLabel")
sLbl.Size = UDim2.new(1, -80, 1, 0)
sLbl.Position = UDim2.new(0, 8, 0, 0)
sLbl.BackgroundTransparency = 1
sLbl.Text = "Sell Delay: 30s"
sLbl.TextColor3 = Color3.fromRGB(210, 215, 255)
sLbl.TextSize = 11
sLbl.Font = Enum.Font.Gotham
sLbl.TextXAlignment = Enum.TextXAlignment.Left
sLbl.Parent = sRow

local sInput = Instance.new("TextBox")
sInput.Size = UDim2.new(0, 60, 0, 22)
sInput.Position = UDim2.new(1, -68, 0.5, -11)
sInput.BackgroundColor3 = Color3.fromRGB(30, 30, 65)
sInput.Text = "30"
sInput.TextColor3 = Color3.fromRGB(210, 215, 255)
sInput.TextSize = 11
sInput.Font = Enum.Font.Gotham
sInput.BorderSizePixel = 0
sInput.Parent = sRow
Instance.new("UICorner", sInput).CornerRadius = UDim.new(0, 4)
sInput.FocusLost:Connect(function()
    local v = tonumber(sInput.Text)
    if v then
        Settings.sellDelay = math.clamp(v, 5, 120)
        sLbl.Text = "Sell Delay: " .. Settings.sellDelay .. "s"
    end
end)

makeButton(sellTab, "Sell Now", sellOrder, function()
    doSell()
end) sellOrder += 1

-- ==================== FAV TAB ====================

local favTab = tabContents["Fav"]
local favOrder = 1

makeLabel(favTab, "Select Items to Favorite", favOrder) favOrder += 1

for _, name in ipairs(fishList) do
    makeToggle(favTab, name, favOrder, function(v)
        favoritedItems[name] = v
    end)
    favOrder += 1
end

makeButton(favTab, "Favorite Selected Now", favOrder, function()
    favoriteAll()
end) favOrder += 1

makeToggle(favTab, "Auto Favorite on Pickup", favOrder, function(v)
    State.autoFav = v
end) favOrder += 1

-- ==================== WEIGHT TAB ====================

local weightTab = tabContents["Weight"]
local weightOrder = 1

makeLabel(weightTab, "Add Weight Filter", weightOrder) weightOrder += 1

local selectedWeightItem = fishList[1] or ""
makeDropdown(weightTab, fishList, weightOrder, function(v)
    selectedWeightItem = v
end) weightOrder += 1

local minWeightVal = 0
local wInp = makeInput(weightTab, "Min Weight (kg) e.g. 50", weightOrder, function(v)
    minWeightVal = tonumber(v) or 0
end) weightOrder += 1

local filterInfoLbl = Instance.new("TextLabel")
filterInfoLbl.Size = UDim2.new(1, -12, 0, 50)
filterInfoLbl.BackgroundColor3 = Color3.fromRGB(18, 18, 42)
filterInfoLbl.Text = "Active Filters:\nNone"
filterInfoLbl.TextColor3 = Color3.fromRGB(180, 185, 255)
filterInfoLbl.TextSize = 10
filterInfoLbl.Font = Enum.Font.Gotham
filterInfoLbl.TextWrapped = true
filterInfoLbl.BorderSizePixel = 0
filterInfoLbl.LayoutOrder = weightOrder
filterInfoLbl.Parent = weightTab
weightOrder += 1
Instance.new("UICorner", filterInfoLbl).CornerRadius = UDim.new(0, 6)

local function updateFilterLabel()
    local lines = {"Active Filters:"}
    for n, w in pairs(weightFilters) do
        table.insert(lines, n .. " >= " .. w .. " kg")
    end
    filterInfoLbl.Text = #lines > 1 and table.concat(lines, "\n") or "Active Filters:\nNone"
end

makeButton(weightTab, "Add Filter", weightOrder, function()
    if selectedWeightItem ~= "" and minWeightVal > 0 then
        weightFilters[selectedWeightItem] = minWeightVal
        updateFilterLabel()
    end
end) weightOrder += 1

makeButton(weightTab, "Remove Selected Filter", weightOrder, function()
    weightFilters[selectedWeightItem] = nil
    updateFilterLabel()
end) weightOrder += 1

makeButton(weightTab, "Favorite by Weight Now", weightOrder, function()
    favoriteByWeight()
end) weightOrder += 1

makeToggle(weightTab, "Auto Fav by Weight on Pickup", weightOrder, function(v)
    State.autoFavWeight = v
end) weightOrder += 1

-- ==================== BUY TAB ====================

local buyTab = tabContents["Buy"]
local buyOrder = 1

makeLabel(buyTab, "Select Equipment to Buy", buyOrder) buyOrder += 1

local selectedTool = equipList[1] or ""
makeDropdown(buyTab, equipList, buyOrder, function(v)
    selectedTool = v
end) buyOrder += 1

makeButton(buyTab, "Buy Selected", buyOrder, function()
    if selectedTool ~= "" then
        pcall(function()
            Network.Equipment.queries.Buy.invoke(selectedTool)
        end)
    end
end) buyOrder += 1

-- ==================== TP TAB ====================

local tpTab = tabContents["TP"]
local tpOrder = 1

makeLabel(tpTab, "Islands", tpOrder) tpOrder += 1

for _, name in ipairs(islandList) do
    makeButton(tpTab, name, tpOrder, function()
        teleportTo(name)
    end)
    tpOrder += 1
end

-- ==================== MERCHANT TAB ====================

local merchantTab = tabContents["Merchant"]
local mOrder = 1

makeLabel(merchantTab, "Travelling Merchant", mOrder) mOrder += 1

makeButton(merchantTab, "Check Status", mOrder, function()
    pcall(function()
        local result = Network.TravellingMerchant.queries.GetShop.invoke()
        if result then
            local data = HttpService:JSONDecode(result)
            local infoLbl = merchantTab:FindFirstChild("StatusInfo")
            if not infoLbl then
                infoLbl = Instance.new("TextLabel")
                infoLbl.Name = "StatusInfo"
                infoLbl.Size = UDim2.new(1, -12, 0, 36)
                infoLbl.BackgroundColor3 = Color3.fromRGB(18, 18, 42)
                infoLbl.TextColor3 = Color3.fromRGB(180, 185, 255)
                infoLbl.TextSize = 11
                infoLbl.Font = Enum.Font.Gotham
                infoLbl.TextWrapped = true
                infoLbl.BorderSizePixel = 0
                infoLbl.LayoutOrder = 999
                infoLbl.Parent = merchantTab
                Instance.new("UICorner", infoLbl).CornerRadius = UDim.new(0, 6)
            end
            if data.isActive then
                infoLbl.Text = "✓ Merchant is ACTIVE!"
                infoLbl.TextColor3 = Color3.fromRGB(100, 255, 120)
            else
                local tl = (data.nextChangeTime or 0) - os.time()
                local m = math.max(0, math.floor(tl / 60))
                local s = math.max(0, tl % 60)
                infoLbl.Text = "Arrives in: " .. m .. "m " .. s .. "s"
                infoLbl.TextColor3 = Color3.fromRGB(255, 180, 80)
            end
        end
    end)
end) mOrder += 1

makeButton(merchantTab, "Buy All Now", mOrder, function()
    pcall(function()
        local result = Network.TravellingMerchant.queries.GetShop.invoke()
        if result then
            local data = HttpService:JSONDecode(result)
            if data.isActive then
                task.spawn(buyAllMerchant)
            end
        end
    end)
end) mOrder += 1

makeToggle(merchantTab, "Auto Buy on Merchant Arrive", mOrder, function(v)
    State.autoMerchant = v
end) mOrder += 1

print("[extracurlydiamond] Loaded!")
