--[[
    KING LEGACY - AUTO BUY KEY + AUTO RANDOM + AUTO STORE
    Tự động dò remote, tự check key trong túi. Chỉ cần dán và chạy.
]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

local oldGui = PlayerGui:FindFirstChild("KL_AutoGacha")
if oldGui then oldGui:Destroy() end

--==============================================================
-- AUTO DÒ REMOTE
--==============================================================
local function scanRemotes()
    local found = { Buy = {}, Random = {}, Store = {} }
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local n = obj.Name:lower()
            if n:find("buy") and (n:find("key") or n:find("gacha") or n:find("shop")) then
                table.insert(found.Buy, obj)
            elseif (n:find("random") or n:find("roll") or n:find("gacha") or n:find("usekey"))
                and not n:find("buy") then
                table.insert(found.Random, obj)
            elseif n:find("store") and (n:find("fruit") or n:find("inv")) then
                table.insert(found.Store, obj)
            end
        end
    end
    return found
end

local Remotes = scanRemotes()
local BuyKeyRemote     = Remotes.Buy[1]
local RandomRemote     = Remotes.Random[1]
local StoreFruitRemote = Remotes.Store[1]

--==============================================================
-- AUTO CHECK INVENTORY (đọc số key đang có)
--==============================================================
local function countKeys(keyType)
    local count = 0
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return 0 end
    for _, gui in ipairs(pg:GetDescendants()) do
        if gui:IsA("TextLabel") then
            local t = gui.Text:lower()
            if t:find(keyType:lower()) then
                local num = t:match("(%d+)")
                if num then count = math.max(count, tonumber(num)) end
            end
        end
    end
    return count
end

local function hasAnyKey()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return false end
    for _, gui in ipairs(pg:GetDescendants()) do
        if gui:IsA("TextLabel") or gui:IsA("TextButton") then
            local t = gui.Text:lower()
            if (t:find("copper") or t:find("iron") or t:find("gold"))
                and t:find("%d") then
                local num = t:match("(%d+)")
                if num and tonumber(num) > 0 then return true end
            end
        end
    end
    return false
end

--==============================================================
-- STATE
--==============================================================
local State = {
    Running    = false,
    AutoBuy    = true,
    AutoRandom = true,
    AutoStore  = true,
    KeyType    = "Copper",
    BuyAmount  = 1,
    Stats = { Bought = 0, Rolled = 0, Stored = 0 },
}

--==============================================================
-- GUI
--==============================================================
local GUI = Instance.new("ScreenGui")
GUI.Name = "KL_AutoGacha"
GUI.ResetOnSpawn = false
GUI.IgnoreGuiInset = true
GUI.Parent = PlayerGui

local Frame = Instance.new("Frame")
Frame.Size = UDim2.fromOffset(270, 340)
Frame.Position = UDim2.new(0.5, -135, 0.5, -170)
Frame.BackgroundColor3 = Color3.fromRGB(25, 27, 38)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Parent = GUI
Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 12)
Instance.new("UIStroke", Frame).Color = Color3.fromRGB(60, 70, 95)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -20, 0, 30)
Title.Position = UDim2.fromOffset(10, 4)
Title.BackgroundTransparency = 1
Title.Text = "AUTO GACHA"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 15
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Frame

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -20, 0, 18)
StatusLabel.Position = UDim2.fromOffset(10, 32)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 11
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
StatusLabel.Text = "Chờ lệnh..."
StatusLabel.Parent = Frame

-- Bảng thông tin tự check
local InfoFrame = Instance.new("Frame")
InfoFrame.Size = UDim2.new(1, -20, 0, 54)
InfoFrame.Position = UDim2.fromOffset(10, 54)
InfoFrame.BackgroundColor3 = Color3.fromRGB(35, 38, 52)
InfoFrame.BorderSizePixel = 0
InfoFrame.Parent = Frame
Instance.new("UICorner", InfoFrame).CornerRadius = UDim.new(0, 6)

local InfoLabel = Instance.new("TextLabel")
InfoLabel.Size = UDim2.new(1, -10, 1, -4)
InfoLabel.Position = UDim2.fromOffset(5, 2)
InfoLabel.BackgroundTransparency = 1
InfoLabel.Font = Enum.Font.Code
InfoLabel.TextSize = 10
InfoLabel.TextColor3 = Color3.fromRGB(140, 200, 160)
InfoLabel.TextXAlignment = Enum.TextXAlignment.Left
InfoLabel.TextYAlignment = Enum.TextYAlignment.Top
InfoLabel.Text = "Đang dò..."
InfoLabel.Parent = InfoFrame

local function updateInfo()
    local b = BuyKeyRemote and "OK" or "✗"
    local r = RandomRemote and "OK" or "✗"
    local s = StoreFruitRemote and "OK" or "✗"
    InfoLabel.Text = string.format(
        "Remote: Buy[%s] Random[%s] Store[%s]\nCó key: %s\nĐã mua:%d Roll:%d Store:%d",
        b, r, s,
        hasAnyKey() and "Có" or "Không",
        State.Stats.Bought, State.Stats.Rolled, State.Stats.Stored
    )
end

local function createButton(text, y, height, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, height or 30)
    btn.Position = UDim2.fromOffset(10, y)
    btn.BackgroundColor3 = Color3.fromRGB(55, 65, 85)
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 12
    btn.Text = text
    btn.AutoButtonColor = true
    btn.Parent = Frame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

local KeyTypeButton = createButton("Key: Copper", 116, 28, function()
    local order = {"Copper", "Iron", "Gold"}
    local idx = 1
    for i, v in ipairs(order) do if v == State.KeyType then idx = i end end
    idx = idx % #order + 1
    State.KeyType = order[idx]
    KeyTypeButton.Text = "Key: " .. State.KeyType
end)

local AmountButton = createButton("SL: 1", 148, 28, function()
    local amounts = {1, 5, 10}
    local idx = 1
    for i, v in ipairs(amounts) do if v == State.BuyAmount then idx = i end end
    idx = idx % #amounts + 1
    State.BuyAmount = amounts[idx]
    AmountButton.Text = "SL: " .. State.BuyAmount
end)

local BuyToggle = createButton("Auto Buy: ON", 182, function()
    State.AutoBuy = not State.AutoBuy
    BuyToggle.Text = "Auto Buy: " .. (State.AutoBuy and "ON" or "OFF")
    BuyToggle.TextColor3 = State.AutoBuy and Color3.new(1,1,1) or Color3.fromRGB(200,120,120)
end)

local RandomToggle = createButton("Auto Random: ON", 214, function()
    State.AutoRandom = not State.AutoRandom
    RandomToggle.Text = "Auto Random: " .. (State.AutoRandom and "ON" or "OFF")
    RandomToggle.TextColor3 = State.AutoRandom and Color3.new(1,1,1) or Color3.fromRGB(200,120,120)
end)

local StoreToggle = createButton("Auto Store: ON", 246, function()
    State.AutoStore = not State.AutoStore
    StoreToggle.Text = "Auto Store: " .. (State.AutoStore and "ON" or "OFF")
    StoreToggle.TextColor3 = State.AutoStore and Color3.new(1,1,1) or Color3.fromRGB(200,120,120)
end)

local RescanButton = createButton("Dò lại Remote", 278, 24, function()
    Remotes = scanRemotes()
    BuyKeyRemote     = Remotes.Buy[1]
    RandomRemote     = Remotes.Random[1]
    StoreFruitRemote = Remotes.Store[1]
    updateInfo()
    StatusLabel.Text = "Đã dò lại."
end)

local StartButton = createButton("START", 306, 30, function()
    State.Running = not State.Running
    StartButton.Text = State.Running and "STOP" or "START"
    StartButton.BackgroundColor3 = State.Running
        and Color3.fromRGB(80, 140, 100) or Color3.fromRGB(55, 65, 85)
    if not State.Running then StatusLabel.Text = "Đã dừng." end
end)
StartButton.Font = Enum.Font.GothamBold

updateInfo()

--==============================================================
-- VÒNG LẶP
--==============================================================
local loopThread = nil

local function startLoop()
    if loopThread then return end
    loopThread = task.spawn(function()
        while State.Running do
            pcall(function()
                -- Mua key nếu bật và có remote
                if State.AutoBuy and BuyKeyRemote then
                    StatusLabel.Text = string.format("Mua %d %s key...",
                        State.BuyAmount, State.KeyType)
                    BuyKeyRemote:FireServer(State.KeyType, State.BuyAmount)
                    State.Stats.Bought = State.Stats.Bought + State.BuyAmount
                    task.wait(0.6)
                end

                -- Random: ưu tiên key đang có, nếu hết thì bỏ qua
                if State.AutoRandom and RandomRemote then
                    local hasKey = hasAnyKey()
                    if hasKey then
                        StatusLabel.Text = "Random bằng " .. State.KeyType .. "..."
                        RandomRemote:FireServer(State.KeyType)
                        State.Stats.Rolled = State.Stats.Rolled + 1
                        task.wait(0.8)
                    else
                        StatusLabel.Text = "Hết key, chờ mua..."
                    end
                end

                -- Store
                if State.AutoStore and StoreFruitRemote then
                    StatusLabel.Text = "Store fruit..."
                    StoreFruitRemote:FireServer()
                    State.Stats.Stored = State.Stats.Stored + 1
                end
            end)
            updateInfo()
            task.wait(1.5)
        end
        loopThread = nil
    end)
end

StartButton.MouseButton1Click:Connect(function()
    if State.Running then startLoop() end
end)

-- Cập nhật info mỗi 2s
task.spawn(function()
    while GUI.Parent do
        if not State.Running then updateInfo() end
        task.wait(2)
    end
end)

--==============================================================
-- KÉO GUI
--==============================================================
local dragging, dragStart, startPos
Frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragStart = input.Position; startPos = Frame.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - dragStart
        Frame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + d.X,
            startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)
Frame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)
