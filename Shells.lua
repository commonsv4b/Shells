-- Services
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Network = require(RS.Modules.Communication.Network)

-- Player
local lp = Players.LocalPlayer
local qte = lp.PlayerGui:WaitForChild("QTE")
local main = qte:WaitForChild("Main")
local line = main:WaitForChild("Line")
local bars = main:WaitForChild("Bars")
local wayStones = workspace:WaitForChild("WayStones")

-- Variables
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

-- Load fish list
local fishList = {}
local shellTools = RS:WaitForChild("Assets"):WaitForChild("Shells"):WaitForChild("Tools")
for _, item in pairs(shellTools:GetChildren()) do
    table.insert(fishList, item.Name)
end
table.sort(fishList)

-- Load equip list
local equipList = {}
local equipTools = RS:WaitForChild("Assets"):WaitForChild("Equipment"):WaitForChild("Tools")
task.wait(3)
for _, item in pairs(equipTools:GetChildren()) do
    table.insert(equipList, item.Name)
end
table.sort(equipList)

-- Load island list
local islandList = {}
for _, island in pairs(wayStones:GetChildren()) do
    table.insert(islandList, island.Name)
end
table.sort(islandList)

-- Functions
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

-- MINIMAL UI (only TextButton and TextLabel)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MinHub"
ScreenGui.Parent = game.CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Main Window (centered)
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 500, 0, 350)
MainFrame.Position = UDim2.new(0.5, -250, 0.5, -175)
MainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 28)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

-- Top Bar (for title and close)
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 35)
TopBar.BackgroundColor3 = Color3.fromRGB(18, 18, 40)
TopBar.BorderSizePixel = 0
TopFrame.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -50, 1, 0)
Title.BackgroundTransparency = 1
Title.Text = "DIAMOND HUB (Min)"
Title.TextColor3 = Color3.fromRGB(210, 215, 255)
Title.TextSize = 16
Title.Font = Enum.Font.GothamBold
Title.Parent = TopBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 25, 0, 25)
CloseBtn.Position = UDim2.new(1, -35, 0.5, -12.5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.new(255, 255, 255)
CloseBtn.TextSize = 12
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = TopBar
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- Tab Buttons (simple, no hover)
local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, 0, 
