
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Network = require(RS.Modules.Communication.Network)

local lp = Players.LocalPlayer
local qte = lp.PlayerGui:WaitForChild("QTE")
local main = qte:WaitForChild("Main")
local line = main:WaitForChild("Line")
local bars = main:WaitForChild("Bars")
local wayStones = workspace:WaitForChild("WayStones")

-- Variables (сохранены все оригинальные)
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

-- Data loading (оригинальный код)
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

-- Functions (сохранены все оригинальные функции)
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

-- CUSTOM UI SYSTEM
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DiamondHub"
ScreenGui.Parent = game.CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "Main"
MainFrame.Size = UDim2.new(0, 700, 0, 450)
MainFrame.Position = UDim2.new(0.5, -350, 0.5, -225)
MainFrame.BackgroundColor3 = Color3.fromRGB(13, 13, 23)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

-- Shadow
local Shadow = Instance.new("ImageLabel")
Shadow.Name = "Shadow"
Shadow.AnchorPoint = Vector2.new(0.5, 0.5)
Shadow.BackgroundTransparency = 1
Shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
Shadow.Size = UDim2.new(1, 40, 1, 40)
Shadow.ZIndex = -1
Shadow.Image = "rbxassetid://5554236805"
Shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
Shadow.ImageTransparency = 0.4
Shadow.ScaleType = Enum.ScaleType.Slice
Shadow.SliceCenter = Rect.new(23, 23, 277, 277)
Shadow.Parent = MainFrame

-- Top Bar
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 50)
TopBar.BackgroundColor3 = Color3.fromRGB(18, 18, 32)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local TopBarCorner = Instance.new("UICorner")
TopBarCorner.CornerRadius = UDim.new(0, 12)
TopBarCorner.Parent = TopBar

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, -100, 1, 0)
Title.Position = UDim2.new(0, 20, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "DIAMOND HUB"
Title.TextColor3 = Color3.fromRGB(220, 220, 255)
Title.TextSize = 20
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "Close"
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -40, 0.5, -15)
CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 70, 70)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 14
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = TopBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 8)
CloseCorner.Parent = CloseBtn

-- Sidebar
local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, 160, 1, -50)
Sidebar.Position = UDim2.new(0, 0, 0, 50)
Sidebar.BackgroundColor3 = Color3.fromRGB(16, 16, 28)
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame

local SidebarCorner = Instance.new("UICorner")
SidebarCorner.CornerRadius = UDim.new(0, 12)
SidebarCorner.Parent = Sidebar

-- Content Container
local ContentContainer = Instance.new("Frame")
ContentContainer.Name = "Content"
ContentContainer.Size = UDim2.new(1, -160, 1, -50)
ContentContainer.Position = UDim2.new(0, 160, 0, 50)
ContentContainer.BackgroundTransparency = 1
ContentContainer.Parent = MainFrame

-- Notification System
local function ShowNotification(title, text, duration)
    local NotifFrame = Instance.new("Frame")
    NotifFrame.Size = UDim2.new(0, 250, 0, 80)
    NotifFrame.Position = UDim2.new(1, 20, 1, -100)
    NotifFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 45)
    NotifFrame.BorderSizePixel = 0
    NotifFrame.Parent = ScreenGui
    
    local NotifCorner = Instance.new("UICorner")
    NotifCorner.CornerRadius = UDim.new(0, 8)
    NotifCorner.Parent = NotifFrame
    
    local NotifTitle = Instance.new("TextLabel")
    NotifTitle.Size = UDim2.new(1, -20, 0, 25)
    NotifTitle.Position = UDim2.new(0, 10, 0, 10)
    NotifTitle.BackgroundTransparency = 1
    NotifTitle.Text = title
    NotifTitle.TextColor3 = Color3.fromRGB(140, 160, 255)
    NotifTitle.TextSize = 16
    NotifTitle.Font = Enum.Font.GothamBold
    NotifTitle.TextXAlignment = Enum.TextXAlignment.Left
    NotifTitle.Parent = NotifFrame
    
    local NotifText = Instance.new("TextLabel")
    NotifText.Size = UDim2.new(1, -20, 0, 40)
    NotifText.Position = UDim2.new(0, 10, 0, 35)
    NotifText.BackgroundTransparency = 1
    NotifText.Text = text
    NotifText.TextColor3 = Color3.fromRGB(200, 200, 220)
    NotifText.TextSize = 14
    NotifText.Font = Enum.Font.Gotham
    NotifText.TextXAlignment = Enum.TextXAlignment.Left
    NotifText.TextWrapped = true
    NotifText.Parent = NotifFrame
    
    TweenService:Create(NotifFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quart), {Position = UDim2.new(1, -270, 1, -100)}):Play()
    
    task.delay(duration or 3, function()
        TweenService:Create(NotifFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quart), {Position = UDim2.new(1, 20, 1, -100)}):Play()
        task.wait(0.5)
        NotifFrame:Destroy()
    end)
end

-- Tab System
local Tabs = {}
local CurrentTab = nil

local function CreateTab(name, icon)
    local TabBtn = Instance.new("TextButton")
    TabBtn.Size = UDim2.new(1, -20, 0, 40)
    TabBtn.Position = UDim2.new(0, 10, 0, 10 + (#Tabs * 50))
    TabBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    TabBtn.Text = "  " .. name
    TabBtn.TextColor3 = Color3.fromRGB(180, 180, 200)
    TabBtn.TextSize = 14
    TabBtn.Font = Enum.Font.GothamSemibold
    TabBtn.TextXAlignment = Enum.TextXAlignment.Left
    TabBtn.Parent = Sidebar
    
    local TabCorner = Instance.new("UICorner")
    TabCorner.CornerRadius = UDim.new(0, 8)
    TabCorner.Parent = TabBtn
    
    local TabContent = Instance.new("ScrollingFrame")
    TabContent.Name = name
    TabContent.Size = UDim2.new(1, -20, 1, -20)
    TabContent.Position = UDim2.new(0, 10, 0, 10)
    TabContent.BackgroundTransparency = 1
    TabContent.ScrollBarThickness = 4
    TabContent.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 100)
    TabContent.Visible = false
    TabContent.Parent = ContentContainer
    
    local ListLayout = Instance.new("UIListLayout")
    ListLayout.Padding = UDim.new(0, 12)
    ListLayout.Parent = TabContent
    
    ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        TabContent.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y + 20)
    end)
    
    table.insert(Tabs, {Button = TabBtn, Content = TabContent})
    
    TabBtn.MouseButton1Click:Connect(function()
        if CurrentTab then
            CurrentTab.Content.Visible = false
            TweenService:Create(CurrentTab.Button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(30, 30, 50), TextColor3 = Color3.fromRGB(180, 180, 200)}):Play()
        end
        CurrentTab = {Button = TabBtn, Content = TabContent}
        TabContent.Visible = true
        TweenService:Create(TabBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60, 80, 180), TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
    end)
    
    return TabContent
end

-- UI Elements
local function CreateSection(parent, text)
    local Section = Instance.new("TextLabel")
    Section.Size = UDim2.new(1, 0, 0, 30)
    Section.BackgroundTransparency = 1
    Section.Text = text
    Section.TextColor3 = Color3.fromRGB(140, 160, 255)
    Section.TextSize = 14
    Section.Font = Enum.Font.GothamBold
    Section.TextXAlignment = Enum.TextXAlignment.Left
    Section.Parent = parent
    return Section
end

local function CreateToggle(parent, text, default, callback)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 45)
    Frame.BackgroundColor3 = Color3.fromRGB(22, 22, 38)
    Frame.Parent = parent
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = Frame
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -70, 1, 0)
    Label.Position = UDim2.new(0, 15, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Color3.fromRGB(220, 220, 240)
    Label.TextSize = 14
    Label.Font = Enum.Font.Gotham
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame
    
    local ToggleBg = Instance.new("TextButton")
    ToggleBg.Size = UDim2.new(0, 44, 0, 24)
    ToggleBg.Position = UDim2.new(1, -59, 0.5, -12)
    ToggleBg.BackgroundColor3 = default and Color3.fromRGB(80, 120, 255) or Color3.fromRGB(50, 50, 70)
    ToggleBg.Text = ""
    ToggleBg.AutoButtonColor = false
    ToggleBg.Parent = Frame
    
    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(1, 0)
    ToggleCorner.Parent = ToggleBg
    
    local Circle = Instance.new("Frame")
    Circle.Size = UDim2.new(0, 18, 0, 18)
    Circle.Position = default and UDim2.new(0, 23, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
    Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Circle.Parent = ToggleBg
    
    local CircleCorner = Instance.new("UICorner")
    CircleCorner.CornerRadius = UDim.new(1, 0)
    CircleCorner.Parent = Circle
    
    local Enabled = default
    
    ToggleBg.MouseButton1Click:Connect(function()
        Enabled = not Enabled
        TweenService:Create(ToggleBg, TweenInfo.new(0.2), {BackgroundColor3 = Enabled and Color3.fromRGB(80, 120, 255) or Color3.fromRGB(50, 50, 70)}):Play()
        TweenService:Create(Circle, TweenInfo.new(0.2), {Position = Enabled and UDim2.new(0, 23, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)}):Play()
        callback(Enabled)
    end)
    
    return Frame
end

local function CreateSlider(parent, text, min, max, default, increment, callback)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 70)
    Frame.BackgroundColor3 = Color3.fromRGB(22, 22, 38)
    Frame.Parent = parent
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = Frame
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -100, 0, 30)
    Label.Position = UDim2.new(0, 15, 0, 5)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Color3.fromRGB(220, 220, 240)
    Label.TextSize = 14
    Label.Font = Enum.Font.Gotham
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame
    
    local ValueLabel = Instance.new("TextLabel")
    ValueLabel.Size = UDim2.new(0, 80, 0, 30)
    ValueLabel.Position = UDim2.new(1, -95, 0, 5)
    ValueLabel.BackgroundTransparency = 1
    ValueLabel.Text = tostring(default)
    ValueLabel.TextColor3 = Color3.fromRGB(140, 160, 255)
    ValueLabel.TextSize = 14
    ValueLabel.Font = Enum.Font.GothamBold
    ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
    ValueLabel.Parent = Frame
    
    local SliderBg = Instance.new("Frame")
    SliderBg.Size = UDim2.new(1, -30, 0, 6)
    SliderBg.Position = UDim2.new(0, 15, 0, 45)
    SliderBg.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    SliderBg.BorderSizePixel = 0
    SliderBg.Parent = Frame
    
    local SliderBgCorner = Instance.new("UICorner")
    SliderBgCorner.CornerRadius = UDim.new(0, 3)
    SliderBgCorner.Parent = SliderBg
    
    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    Fill.BackgroundColor3 = Color3.fromRGB(100, 120, 255)
    Fill.BorderSizePixel = 0
    Fill.Parent = SliderBg
    
    local FillCorner = Instance.new("UICorner")
    FillCorner.CornerRadius = UDim.new(0, 3)
    FillCorner.Parent = Fill
    
    local DragBtn = Instance.new("TextButton")
    DragBtn.Size = UDim2.new(0, 16, 0, 16)
    DragBtn.Position = UDim2.new((default - min) / (max - min), -8, 0.5, -8)
    DragBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    DragBtn.Text = ""
    DragBtn.Parent = SliderBg
    
    local DragCorner = Instance.new("UICorner")
    DragCorner.CornerRadius = UDim.new(1, 0)
    DragCorner.Parent = DragBtn
    
    local Dragging = false
    
    local function Update(input)
        local pos = math.clamp((input.Position.X - SliderBg.AbsolutePosition.X) / SliderBg.AbsoluteSize.X, 0, 1)
        local val = math.floor((min + (max - min) * pos) / increment + 0.5) * increment
        val = math.clamp(val, min, max)
        
        Fill.Size = UDim2.new(pos, 0, 1, 0)
        DragBtn.Position = UDim2.new(pos, -8, 0.5, -8)
        ValueLabel.Text = tostring(val)
        callback(val)
    end
    
    DragBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Dragging = true
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if Dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            Update(input)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Dragging = false
        end
    end)
    
    return Frame
end

local function CreateButton(parent, text, callback)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, 0, 0, 40)
    Btn.BackgroundColor3 = Color3.fromRGB(60, 80, 200)
    Btn.Text = text
    Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Btn.TextSize = 14
    Btn.Font = Enum.Font.GothamSemibold
    Btn.Parent = parent
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = Btn
    
    Btn.MouseButton1Click:Connect(function()
        TweenService:Create(Btn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(80, 100, 255)}):Play()
        task.wait(0.1)
        TweenService:Create(Btn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(60, 80, 200)}):Play()
        callback()
    end)
    
    return Btn
end

local function CreateDropdown(parent, text, options, callback)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 45)
    Frame.BackgroundColor3 = Color3.fromRGB(22, 22, 38)
    Frame.ClipsDescendants = true
    Frame.Parent = parent
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = Frame
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -20, 0, 45)
    Label.Position = UDim2.new(0, 15, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text .. ": " .. (options[1] or "None")
    Label.TextColor3 = Color3.fromRGB(220, 220, 240)
    Label.TextSize = 14
    Label.Font = Enum.Font.Gotham
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame
    
    local Arrow = Instance.new("TextLabel")
    Arrow.Size = UDim2.new(0, 30, 0, 45)
    Arrow.Position = UDim2.new(1, -40, 0, 0)
    Arrow.BackgroundTransparency = 1
    Arrow.Text = "▼"
    Arrow.TextColor3 = Color3.fromRGB(140, 140, 160)
    Arrow.TextSize = 12
    Arrow.Font = Enum.Font.Gotham
    Arrow.Parent = Frame
    
    local Expanded = false
    local Selected = options[1]
    
    local OptionsFrame = Instance.new("Frame")
    OptionsFrame.Size = UDim2.new(1, 0, 0, #options * 35)
    OptionsFrame.Position = UDim2.new(0, 0, 0, 45)
    OptionsFrame.BackgroundTransparency = 1
    OptionsFrame.Parent = Frame
    
    for i, opt in ipairs(options) do
        local OptBtn = Instance.new("TextButton")
        OptBtn.Size = UDim2.new(1, -20, 0, 30)
        OptBtn.Position = UDim2.new(0, 10, 0, (i-1) * 35 + 5)
        OptBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
        OptBtn.Text = opt
        OptBtn.TextColor3 = Color3.fromRGB(200, 200, 220)
        OptBtn.TextSize = 13
        OptBtn.Font = Enum.Font.Gotham
        OptBtn.Parent = OptionsFrame
        
        local OptCorner = Instance.new("UICorner")
        OptCorner.CornerRadius = UDim.new(0, 6)
        OptCorner.Parent = OptBtn
        
        OptBtn.MouseButton1Click:Connect(function()
            Selected = opt
            Label.Text = text .. ": " .. opt
            Expanded = false
            TweenService:Create(Frame, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 0, 45)}):Play()
            TweenService:Create(Arrow, TweenInfo.new(0.2), {Rotation = 0}):Play()
            callback(Selected)
        end)
    end
    
    Frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            Expanded = not Expanded
            local targetSize = Expanded and UDim2.new(1, 0, 0, 45 + #options * 35) or UDim2.new(1, 0, 0, 45)
            TweenService:Create(Frame, TweenInfo.new(0.2), {Size = targetSize}):Play()
            TweenService:Create(Arrow, TweenInfo.new(0.2), {Rotation = Expanded and 180 or 0}):Play()
        end
    end)
    
    return Frame
end

local function CreateInput(parent, text, placeholder, callback)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 70)
    Frame.BackgroundColor3 = Color3.fromRGB(22, 22, 38)
    Frame.Parent = parent
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = Frame
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -20, 0, 30)
    Label.Position = UDim2.new(0, 15, 0, 5)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Color3.fromRGB(220, 220, 240)
    Label.TextSize = 14
    Label.Font = Enum.Font.Gotham
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame
    
    local InputBox = Instance.new("TextBox")
    InputBox.Size = UDim2.new(1, -30, 0, 30)
    InputBox.Position = UDim2.new(0, 15, 0, 35)
    InputBox.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
    InputBox.Text = ""
    InputBox.PlaceholderText = placeholder
    InputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    InputBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 140)
    InputBox.TextSize = 14
    InputBox.Font = Enum.Font.Gotham
    InputBox.ClearTextOnFocus = false
    InputBox.Parent = Frame
    
    local InputCorner = Instance.new("UICorner")
    InputCorner.CornerRadius = UDim.new(0, 6)
    InputCorner.Parent = InputBox
    
    InputBox.FocusLost:Connect(function()
        callback(InputBox.Text)
    end)
    
    return Frame
end

-- Draggable
local Dragging = false
local DragStart = nil
local StartPos = nil

TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        Dragging = true
        DragStart = input.Position
        StartPos = MainFrame.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if Dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - DragStart
        MainFrame.Position = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + delta.X, StartPos.Y.Scale, StartPos.Y.Offset + delta.Y)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        Dragging = false
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- BUILDING TABS
-- Auto Dig Tab
local DigTab = CreateTab("Auto Dig")
CreateSection(DigTab, "Method 1 - Bar Follow")
CreateToggle(DigTab, "Bar Follow Line", false, function(val)
    autoDigBarMethod = val
end)

CreateSection(DigTab, "Method 2 - Event Fire")
CreateToggle(DigTab, "Auto Dig (Events)", false, function(val)
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

CreateSlider(DigTab, "Event Loop Delay", 0.1, 1, 0.5, 0.1, function(val)
    eventDelay = val
end)

CreateSection(DigTab, "Method 3 - Targeted Dig")
CreateToggle(DigTab, "Target: Legendary", false, function(val)
    targetRarities["Legendary"] = val
end)
CreateToggle(DigTab, "Target: Mythic", false, function(val)
    targetRarities["Mythic"] = val
end)
CreateToggle(DigTab, "Target: Exotic", false, function(val)
    targetRarities["Exotic"] = val
end)

CreateSlider(DigTab, "Worker Count", 1, 10, 3, 1, function(val)
    workerCount = val
end)

CreateToggle(DigTab, "Targeted Dig", false, function(val)
    autoTargetDig = val
    if val then
        spawnWorkers()
    end
end)

-- Auto Sell Tab
local SellTab = CreateTab("Auto Sell")
CreateSection(SellTab, "Auto Sell")
CreateToggle(SellTab, "Auto Sell", false, function(val)
    autoSell = val
    if val then
        task.spawn(function()
            while autoSell do
                pcall(function()
                    Network.Merchant.packets.SellAll.send()
                end)
                task.wait(sellDelay)
            end
        end)
    end
end)

CreateSlider(SellTab, "Sell Delay (s)", 10, 60, 30, 5, function(val)
    sellDelay = val
end)

-- Auto Favorite Tab
local FavTab = CreateTab("Auto Favorite")
CreateSection(FavTab, "Select Items to Favorite")
for _, fishName in pairs(fishList) do
    CreateToggle(FavTab, fishName, false, function(val)
        favoritedItems[fishName] = val
    end)
end

CreateSection(FavTab, "Run")
CreateButton(FavTab, "Favorite Selected Now", function()
    favoriteAll()
    ShowNotification("Auto Favorite", "Favorited all selected items in backpack!", 2)
end)

CreateToggle(FavTab, "Auto Favorite on Backpack Change", false, function(val)
    if val then
        lp.Backpack.ChildAdded:Connect(function()
            task.wait(0.1)
            favoriteAll()
        end)
    end
end)

-- Fav by Weight Tab
local WeightTab = CreateTab("Fav by Weight")
CreateSection(WeightTab, "Add Weight Filter")
CreateDropdown(WeightTab, "Select Item", fishList, function(val)
    selectedWeightItem = val
end)

CreateInput(WeightTab, "Minimum Weight (kg)", "e.g. 50", function(val)
    minWeightInput = tonumber(val) or 0
end)

local FilterList = Instance.new("TextLabel")
FilterList.Size = UDim2.new(1, 0, 0, 60)
FilterList.BackgroundTransparency = 1
FilterList.Text = "Active Filters:\nNone"
FilterList.TextColor3 = Color3.fromRGB(140, 160, 255)
FilterList.TextSize = 13
FilterList.Font = Enum.Font.Gotham
FilterList.TextWrapped = true
FilterList.Parent = WeightTab

local function updateWeightList()
    local lines = {}
    for name, w in pairs(weightFilters) do
        table.insert(lines, name .. " >= " .. w .. " kg")
    end
    FilterList.Text = "Active Filters:\n" .. (#lines > 0 and table.concat(lines, ", ") or "None")
end

CreateButton(WeightTab, "Add Filter", function()
    if selectedWeightItem ~= "" and minWeightInput > 0 then
        weightFilters[selectedWeightItem] = minWeightInput
        updateWeightList()
        ShowNotification("Filter Added", selectedWeightItem .. " >= " .. minWeightInput .. " kg", 2)
    else
        ShowNotification("Error", "Select an item and enter a valid weight!", 2)
    end
end)

CreateButton(WeightTab, "Remove Selected Filter", function()
    if weightFilters[selectedWeightItem] then
        weightFilters[selectedWeightItem] = nil
        updateWeightList()
        ShowNotification("Filter Removed", selectedWeightItem .. " filter removed.", 2)
    end
end)

CreateSection(WeightTab, "Run")
CreateButton(WeightTab, "Favorite by Weight Now", function()
    favoriteByWeight()
    ShowNotification("Auto Favorite", "Favorited items matching weight filters!", 2)
end)

CreateToggle(WeightTab, "Auto Favorite by Weight on Change", false, function(val)
    if val then
        lp.Backpack.ChildAdded:Connect(function()
            task.wait(0.1)
            favoriteByWeight()
        end)
    end
end)

-- Buy Tool Tab
local BuyTab = CreateTab("Buy Tool")
CreateSection(BuyTab, "Select Tool to Buy")
CreateDropdown(BuyTab, "Select Tool", equipList, function(val)
    selectedBuyTool = val
end)

CreateButton(BuyTab, "Buy Tool", function()
    if selectedBuyTool ~= "" then
        pcall(function()
            Network.Equipment.queries.Buy.invoke(selectedBuyTool)
        end)
        ShowNotification("Buy Tool", "Attempted to buy: " .. selectedBuyTool, 2)
    else
        ShowNotification("Error", "Please select a tool first!", 2)
    end
end)

-- Teleport Tab
local TpTab = CreateTab("Teleport")
CreateSection(TpTab, "Islands")
for _, name in pairs(islandList) do
    CreateButton(TpTab, name, function()
        teleportTo(name)
        ShowNotification("Teleport", "Teleporting to " .. name, 2)
    end)
end

-- Merchant Tab
local MerchantTab = CreateTab("Merchant")
CreateSection(MerchantTab, "Travelling Merchant")
CreateButton(MerchantTab, "Check Merchant Status", function()
    pcall(function()
        local result = Network.TravellingMerchant.queries.GetShop.invoke()
        if result then
            local data = HttpService:JSONDecode(result)
            if data.isActive then
                ShowNotification("Merchant", "Merchant is currently ACTIVE!", 3)
            else
                local timeLeft = data.nextChangeTime - os.time()
                local mins = math.floor(timeLeft / 60)
                local secs = timeLeft % 60
                ShowNotification("Merchant", "Arrives in: " .. mins .. "m " .. secs .. "s", 3)
            end
        end
    end)
end)

CreateButton(MerchantTab, "Buy All Now", function()
    pcall(function()
        local result = Network.TravellingMerchant.queries.GetShop.invoke()
        if result then
            local data = HttpService:JSONDecode(result)
            if data.isActive then
                task.spawn(buyAllMerchant)
                ShowNotification("Merchant", "Buying all items!", 2)
            else
                ShowNotification("Merchant", "Merchant is not active!", 2)
            end
        end
    end)
end)

CreateToggle(MerchantTab, "Auto Buy When Merchant Arrives", false, function(val)
    autoMerchant = val
    if val then
        task.spawn(function()
            local merchantBought = false
            while autoMerchant do
                pcall(function()
                    local result = Network.TravellingMerchant.queries.GetShop.invoke()
                    if result then
                        local data = HttpService:JSONDecode(result)
                        if data.isActive and not merchantBought then
                            buyAllMerchant()
                            merchantBought = true
                            ShowNotification("Merchant", "Bought all merchant items!", 3)
                        elseif not data.isActive then
                            merchantBought = false
                        end
                    end
                end)
                task.wait(5)
            end
        end)
    end
end)

-- Select first tab by default
if Tabs[1] then
    Tabs[1].Button.BackgroundColor3 = Color3.fromRGB(60, 80, 180)
    Tabs[1].Button.TextColor3 = Color3.fromRGB(255, 255, 255)
    Tabs[1].Content.Visible = true
    CurrentTab = {Button = Tabs[1].Button, Content = Tabs[1].Content}
end

-- RenderStepped Connection (оригинальный код)
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

ShowNotification("Diamond Hub", "Loaded successfully!", 3)
