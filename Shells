local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
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

local Window = Rayfield:CreateWindow({
    Name = "extracurlydiamond",
    LoadingTitle = "extracurlydiamond",
    LoadingSubtitle = "Loading...",
    Theme = {
        Background = Color3.fromRGB(12, 12, 28),
        Topbar = Color3.fromRGB(18, 18, 40),
        Shadow = Color3.fromRGB(5, 5, 15),
        NotificationBackground = Color3.fromRGB(18, 18, 40),
        NotificationActionsBackground = Color3.fromRGB(22, 22, 48),
        TabBackground = Color3.fromRGB(14, 14, 32),
        TabStroke = Color3.fromRGB(40, 40, 80),
        TabBackgroundSelected = Color3.fromRGB(25, 25, 60),
        TabTextColor = Color3.fromRGB(120, 120, 180),
        SelectedTabTextColor = Color3.fromRGB(140, 160, 255),
        ElementBackground = Color3.fromRGB(20, 20, 45),
        ElementBackgroundHover = Color3.fromRGB(28, 28, 60),
        SecondaryElementBackground = Color3.fromRGB(22, 22, 50),
        ElementStroke = Color3.fromRGB(45, 45, 90),
        SecondaryElementStroke = Color3.fromRGB(38, 38, 75),
        SliderBackground = Color3.fromRGB(30, 30, 65),
        SliderProgress = Color3.fromRGB(100, 120, 255),
        SliderStroke = Color3.fromRGB(50, 50, 100),
        ToggleBackground = Color3.fromRGB(30, 30, 65),
        ToggleEnabled = Color3.fromRGB(100, 120, 255),
        ToggleDisabled = Color3.fromRGB(50, 50, 90),
        ToggleEnabledStroke = Color3.fromRGB(80, 100, 220),
        ToggleDisabledStroke = Color3.fromRGB(40, 40, 80),
        ToggleEnabledOuterStroke = Color3.fromRGB(60, 80, 180),
        ToggleDisabledOuterStroke = Color3.fromRGB(30, 30, 65),
        DropdownSelected = Color3.fromRGB(100, 120, 255),
        DropdownUnselected = Color3.fromRGB(35, 35, 70),
        InputBackground = Color3.fromRGB(20, 20, 45),
        InputStroke = Color3.fromRGB(45, 45, 90),
        PlaceholderColor = Color3.fromRGB(90, 90, 140),
        TextColor = Color3.fromRGB(210, 215, 255),
        SubTextColor = Color3.fromRGB(140, 145, 200),
        PureTitleTextColor = Color3.fromRGB(160, 175, 255),
        TitleTextColor = Color3.fromRGB(160, 175, 255),
        ButtonColor = Color3.fromRGB(55, 60, 140),
        ButtonStroke = Color3.fromRGB(80, 90, 180),
        ButtonTextColor = Color3.fromRGB(220, 225, 255),
    },
    DisableRayfieldPrompts = true,
    DisableBuildWarnings = true,
})

local DigTab = Window:CreateTab("Auto Dig", nil)

DigTab:CreateSection("Method 1 - Bar Follow")

DigTab:CreateToggle({
    Name = "Bar Follow Line",
    CurrentValue = false,
    Flag = "BarFollow",
    Callback = function(val)
        autoDigBarMethod = val
    end
})

DigTab:CreateSection("Method 2 - Event Fire")

DigTab:CreateToggle({
    Name = "Auto Dig (Events)",
    CurrentValue = false,
    Flag = "AutoDigEvent",
    Callback = function(val)
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
    end
})

DigTab:CreateSlider({
    Name = "Event Loop Delay (s)",
    Range = {0.1, 1},
    Increment = 0.1,
    CurrentValue = 0.5,
    Flag = "EventDelay",
    Callback = function(val)
        eventDelay = val
    end
})

DigTab:CreateSection("Method 3 - Targeted Dig")

DigTab:CreateToggle({
    Name = "Target: Legendary",
    CurrentValue = false,
    Flag = "TargetLegendary",
    Callback = function(val)
        targetRarities["Legendary"] = val
    end
})

DigTab:CreateToggle({
    Name = "Target: Mythic",
    CurrentValue = false,
    Flag = "TargetMythic",
    Callback = function(val)
        targetRarities["Mythic"] = val
    end
})

DigTab:CreateToggle({
    Name = "Target: Exotic",
    CurrentValue = false,
    Flag = "TargetExotic",
    Callback = function(val)
        targetRarities["Exotic"] = val
    end
})

DigTab:CreateSlider({
    Name = "Worker Count",
    Range = {1, 10},
    Increment = 1,
    CurrentValue = 3,
    Flag = "WorkerCount",
    Callback = function(val)
        workerCount = val
    end
})

DigTab:CreateToggle({
    Name = "Targeted Dig",
    CurrentValue = false,
    Flag = "TargetDig",
    Callback = function(val)
        autoTargetDig = val
        if val then
            spawnWorkers()
        end
    end
})

local SellTab = Window:CreateTab("Auto Sell", nil)

SellTab:CreateSection("Auto Sell")

SellTab:CreateToggle({
    Name = "Auto Sell",
    CurrentValue = false,
    Flag = "AutoSell",
    Callback = function(val)
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
    end
})

SellTab:CreateSlider({
    Name = "Sell Delay (s)",
    Range = {10, 60},
    Increment = 5,
    CurrentValue = 30,
    Flag = "SellDelay",
    Callback = function(val)
        sellDelay = val
    end
})

local FavTab = Window:CreateTab("Auto Favorite", nil)

FavTab:CreateSection("Select Items to Favorite")

for _, fishName in pairs(fishList) do
    FavTab:CreateToggle({
        Name = fishName,
        CurrentValue = false,
        Flag = "Fav_" .. fishName,
        Callback = function(val)
            favoritedItems[fishName] = val
        end
    })
end

FavTab:CreateSection("Run")

FavTab:CreateButton({
    Name = "Favorite Selected Now",
    Callback = function()
        favoriteAll()
        Rayfield:Notify({
            Title = "Auto Favorite",
            Content = "Favorited all selected items in backpack!",
            Duration = 2,
        })
    end
})

FavTab:CreateToggle({
    Name = "Auto Favorite on Backpack Change",
    CurrentValue = false,
    Flag = "AutoFavToggle",
    Callback = function(val)
        if val then
            lp.Backpack.ChildAdded:Connect(function()
                task.wait(0.1)
                favoriteAll()
            end)
        end
    end
})

local FavWeightTab = Window:CreateTab("Fav by Weight", nil)

FavWeightTab:CreateSection("Add Weight Filter")

FavWeightTab:CreateDropdown({
    Name = "Select Item",
    Options = fishList,
    CurrentOption = {fishList[1]},
    Flag = "WeightItemDropdown",
    Callback = function(val)
        selectedWeightItem = val[1] or val
    end
})

FavWeightTab:CreateInput({
    Name = "Minimum Weight (kg)",
    PlaceholderText = "e.g. 50",
    RemoveTextAfterFocusLost = false,
    Flag = "WeightInput",
    Callback = function(val)
        minWeightInput = tonumber(val) or 0
    end
})

local weightListLabel = FavWeightTab:CreateParagraph({
    Title = "Active Filters",
    Content = "None"
})

local function updateWeightList()
    local lines = {}
    for name, w in pairs(weightFilters) do
        table.insert(lines, name .. " >= " .. w .. " kg")
    end
    weightListLabel:Set({
        Title = "Active Filters",
        Content = #lines > 0 and table.concat(lines, "\n") or "None"
    })
end

FavWeightTab:CreateButton({
    Name = "Add Filter",
    Callback = function()
        if selectedWeightItem ~= "" and minWeightInput > 0 then
            weightFilters[selectedWeightItem] = minWeightInput
            updateWeightList()
            Rayfield:Notify({
                Title = "Filter Added",
                Content = selectedWeightItem .. " >= " .. minWeightInput .. " kg",
                Duration = 2,
            })
        else
            Rayfield:Notify({
                Title = "Error",
                Content = "Select an item and enter a valid weight!",
                Duration = 2,
            })
        end
    end
})

FavWeightTab:CreateButton({
    Name = "Remove Selected Filter",
    Callback = function()
        if weightFilters[selectedWeightItem] then
            weightFilters[selectedWeightItem] = nil
            updateWeightList()
            Rayfield:Notify({
                Title = "Filter Removed",
                Content = selectedWeightItem .. " filter removed.",
                Duration = 2,
            })
        end
    end
})

FavWeightTab:CreateSection("Run")

FavWeightTab:CreateButton({
    Name = "Favorite by Weight Now",
    Callback = function()
        favoriteByWeight()
        Rayfield:Notify({
            Title = "Auto Favorite",
            Content = "Favorited items matching weight filters!",
            Duration = 2,
        })
    end
})

FavWeightTab:CreateToggle({
    Name = "Auto Favorite by Weight on Backpack Change",
    CurrentValue = false,
    Flag = "AutoFavWeightToggle",
    Callback = function(val)
        if val then
            lp.Backpack.ChildAdded:Connect(function()
                task.wait(0.1)
                favoriteByWeight()
            end)
        end
    end
})

local BuyTab = Window:CreateTab("Buy Tool", nil)

BuyTab:CreateSection("Select Tool to Buy")

BuyTab:CreateDropdown({
    Name = "Select Tool",
    Options = equipList,
    CurrentOption = {equipList[1]},
    Flag = "BuyToolDropdown",
    Callback = function(val)
        selectedBuyTool = val[1] or val
    end
})

BuyTab:CreateButton({
    Name = "Buy",
    Callback = function()
        if selectedBuyTool ~= "" then
            pcall(function()
                Network.Equipment.queries.Buy.invoke(selectedBuyTool)
            end)
            Rayfield:Notify({
                Title = "Buy Tool",
                Content = "Attempted to buy: " .. selectedBuyTool,
                Duration = 2,
            })
        else
            Rayfield:Notify({
                Title = "Error",
                Content = "Please select a tool first!",
                Duration = 2,
            })
        end
    end
})

local TpTab = Window:CreateTab("Teleport", nil)

TpTab:CreateSection("Islands")

for _, name in pairs(islandList) do
    TpTab:CreateButton({
        Name = name,
        Callback = function()
            teleportTo(name)
            Rayfield:Notify({
                Title = "Teleport",
                Content = "Teleporting to " .. name,
                Duration = 2,
            })
        end
    })
end

local MerchantTab = Window:CreateTab("Merchant", nil)

MerchantTab:CreateSection("Travelling Merchant")

MerchantTab:CreateButton({
    Name = "Check Merchant Status",
    Callback = function()
        pcall(function()
            local result = Network.TravellingMerchant.queries.GetShop.invoke()
            if result then
                local data = HttpService:JSONDecode(result)
                if data.isActive then
                    Rayfield:Notify({
                        Title = "Merchant",
                        Content = "Merchant is currently ACTIVE!",
                        Duration = 3,
                    })
                else
                    local timeLeft = data.nextChangeTime - os.time()
                    local mins = math.floor(timeLeft / 60)
                    local secs = timeLeft % 60
                    Rayfield:Notify({
                        Title = "Merchant",
                        Content = "Arrives in: " .. mins .. "m " .. secs .. "s",
                        Duration = 3,
                    })
                end
            end
        end)
    end
})

MerchantTab:CreateButton({
    Name = "Buy All Now",
    Callback = function()
        pcall(function()
            local result = Network.TravellingMerchant.queries.GetShop.invoke()
            if result then
                local data = HttpService:JSONDecode(result)
                if data.isActive then
                    task.spawn(buyAllMerchant)
                    Rayfield:Notify({
                        Title = "Merchant",
                        Content = "Buying all items!",
                        Duration = 2,
                    })
                else
                    Rayfield:Notify({
                        Title = "Merchant",
                        Content = "Merchant is not active!",
                        Duration = 2,
                    })
                end
            end
        end)
    end
})

MerchantTab:CreateToggle({
    Name = "Auto Buy When Merchant Arrives",
    CurrentValue = false,
    Flag = "AutoMerchant",
    Callback = function(val)
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
                                Rayfield:Notify({
                                    Title = "Merchant",
                                    Content = "Bought all merchant items!",
                                    Duration = 3,
                                })
                            elseif not data.isActive then
                                merchantBought = false
                            end
                        end
                    end)
                    task.wait(5)
                end
            end)
        end
    end
})

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

Rayfield:Notify({
    Title = "commonSanyaGay",
    Content = "Loaded successfully!",
    Duration = 3,
})
