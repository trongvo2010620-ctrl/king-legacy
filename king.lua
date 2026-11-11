local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Player    = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local oldGui = PlayerGui:FindFirstChild("KingLegacyUnifiedTimer")
if oldGui then oldGui:Destroy() end

local StartedAt = os.time()
local Events = { SeaKing = nil, Hydra = nil, SeaEvent = nil }
local ServerTimeEnabled = true
local MenuVisible = true

local EXPANDED  = UDim2.fromOffset(260, 305)
local COLLAPSED = UDim2.fromOffset(260, 40)

local GUI = Instance.new("ScreenGui")
GUI.Name = "KingLegacyUnifiedTimer"
GUI.ResetOnSpawn = false
GUI.IgnoreGuiInset = true
GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
GUI.Parent = PlayerGui

local Main = Instance.new("Frame")
Main.Size = EXPANDED
Main.Position = UDim2.new(0.5, -130, 0.5, -152)
Main.BackgroundColor3 = Color3.fromRGB(25, 27, 38)
Main.BorderSizePixel = 0
Main.Active = true
Main.Parent = GUI

Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)
local stroke = Instance.new("UIStroke", Main)
stroke.Color = Color3.fromRGB(60, 70, 95)
stroke.Thickness = 1

local TitleBar = Instance.new("TextLabel")
TitleBar.Size = UDim2.new(1, -44, 0, 34)
TitleBar.Position = UDim2.fromOffset(10, 2)
TitleBar.BackgroundTransparency = 1
TitleBar.Font = Enum.Font.GothamBold
TitleBar.TextSize = 14
TitleBar.TextColor3 = Color3.new(1, 1, 1)
TitleBar.TextXAlignment = Enum.TextXAlignment.Left
TitleBar.Text = "KING LEGACY TIMER HUB"
TitleBar.Active = true
TitleBar.Parent = Main

local Minimize = Instance.new("TextButton")
Minimize.Size = UDim2.fromOffset(30, 30)
Minimize.Position = UDim2.new(1, -36, 0, 3)
Minimize.Text = "-"
Minimize.Font = Enum.Font.GothamBold
Minimize.BackgroundColor3 = Color3.fromRGB(70, 80, 110)
Minimize.TextColor3 = Color3.new(1, 1, 1)
Minimize.AutoButtonColor = true
Minimize.Parent = Main
Instance.new("UICorner", Minimize).CornerRadius = UDim.new(0, 6)

local function Label(text, y)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -20, 0, 26)
    l.Position = UDim2.fromOffset(10, y)
    l.BackgroundTransparency = 1
    l.TextColor3 = Color3.new(1, 1, 1)
    l.TextSize = 13
    l.Font = Enum.Font.Gotham
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Text = text
    l.Parent = Main
    return l
end

local function Button(text, y, callback)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -20, 0, 30)
    b.Position = UDim2.fromOffset(10, y)
    b.BackgroundColor3 = Color3.fromRGB(48, 60, 85)
    b.TextColor3 = Color3.new(1, 1, 1)
    b.TextSize = 12
    b.Font = Enum.Font.Gotham
    b.Text = text
    b.AutoButtonColor = true
    b.Parent = Main
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 7)
    b.MouseButton1Click:Connect(callback)
    return b
end

local ServerLabel = Label("Server Time: 00:00:00", 38)
local SeaLabel    = Label("Sea King: Not recorded", 65)
local HydraLabel  = Label("Hydra: Not recorded", 92)
local EventLabel  = Label("Sea Event: Not recorded", 119)

local TimeToggle = Button("SERVER TIME: ON", 153, function()
    ServerTimeEnabled = not ServerTimeEnabled
    TimeToggle.Text = "SERVER TIME: " .. (ServerTimeEnabled and "ON" or "OFF")
    ServerLabel.Visible = ServerTimeEnabled and MenuVisible
end)

local function Record(key, label, name)
    Events[key] = os.time()
    label.Text = name .. ": 00:00:00"
end

local BtnKing  = Button("RECORD SEA KING",  190, function() Record("SeaKing",  SeaLabel,  "Sea King") end)
local BtnHydra = Button("RECORD HYDRA",     225, function() Record("Hydra",    HydraLabel, "Hydra")    end)
local BtnEvent = Button("RECORD SEA EVENT", 260, function() Record("SeaEvent", EventLabel, "Sea Event") end)

local CONTENT = { ServerLabel, SeaLabel, HydraLabel, EventLabel,
                  TimeToggle, BtnKing, BtnHydra, BtnEvent }

local function FormatTime(sec)
    if sec < 0 then sec = 0 end
    local h = math.floor(sec / 3600)
    local m = math.floor((sec % 3600) / 60)
    local s = sec % 60
    return string.format("%02d:%02d:%02d", h, m, s)
end

local function SetMenu(visible)
    MenuVisible = visible
    for _, obj in ipairs(CONTENT) do
        obj.Visible = visible
    end
    if visible then
        ServerLabel.Visible = ServerTimeEnabled
        Main.Size = EXPANDED
        Minimize.Text = "-"
    else
        Main.Size = COLLAPSED
        Minimize.Text = "+"
    end
end

Minimize.MouseButton1Click:Connect(function()
    SetMenu(not MenuVisible)
end)

do
    local dragging, dragStart, startPos = false, nil, nil

    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = Main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            Main.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

task.spawn(function()
    while GUI.Parent do
        if ServerTimeEnabled then
            ServerLabel.Text = "Server Time: " .. FormatTime(os.time() - StartedAt)
        end
        if Events.SeaKing  then SeaLabel.Text   = "Sea King: "  .. FormatTime(os.time() - Events.SeaKing)  end
        if Events.Hydra    then HydraLabel.Text = "Hydra: "     .. FormatTime(os.time() - Events.Hydra)    end
        if Events.SeaEvent then EventLabel.Text = "Sea Event: " .. FormatTime(os.time() - Events.SeaEvent) end
        task.wait(1)
    end
end)