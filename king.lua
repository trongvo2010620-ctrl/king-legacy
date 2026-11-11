-- Script theo dõi chu kỳ Sea King -> Hydra
-- Cố gắng đọc bộ đếm số La Mã (I, II, III) trên GUI của game
-- Lưu ý: Script này phụ thuộc vào cấu trúc GUI của game,
-- có thể không hoạt động nếu game thay đổi giao diện.

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Tạo GUI hiển thị
local GUI = Instance.new("ScreenGui")
GUI.Name = "KingLegacyHydraTracker"
GUI.ResetOnSpawn = false
GUI.Parent = PlayerGui

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 250, 0, 60)
Frame.Position = UDim2.new(1, -260, 0, 10)
Frame.BackgroundColor3 = Color3.fromRGB(25, 27, 38)
Frame.BorderSizePixel = 0
Frame.Parent = GUI
Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 8)

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -20, 1, -10)
StatusLabel.Position = UDim2.new(0, 10, 0, 5)
StatusLabel.BackgroundTransparency = 1
StatusLabel.TextColor3 = Color3.new(1, 1, 1)
StatusLabel.TextSize = 13
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.TextWrap = true
StatusLabel.Text = "Đang tìm bộ đếm Sea King..."
StatusLabel.Parent = Frame

-- Hàm cố gắng tìm text chứa số La Mã (I, II, III) trong toàn bộ PlayerGui
-- Đây là cách "hybrid": quét mọi TextLabel và TextButton
local function findRomanNumeralCounter()
    for _, gui in ipairs(PlayerGui:GetDescendants()) do
        if gui:IsA("TextLabel") or gui:IsA("TextButton") then
            local text = gui.Text
            -- Tìm các mẫu phổ biến: "I", "II", "III", hoặc "1", "2", "3"
            -- và phải nằm trong ngữ cảnh liên quan đến Sea King (nếu có)
            if text == "I" or text == "II" or text == "III" then
                -- Kiểm tra thêm: thường text này nằm gần một label khác có chữ "Sea King"
                -- hoặc nằm trong một Frame có tên liên quan
                return text, gui
            end
            -- Một số phiên bản có thể dùng số Ả Rập thay vì số La Mã
            if text == "1" or text == "2" or text == "3" then
                -- Chỉ chấp nhận nếu text ngắn (tránh nhầm với các số khác)
                if #text == 1 then
                    return text, gui
                end
            end
        end
    end
    return nil, nil
end

-- Vòng lặp cập nhật
task.spawn(function()
    while GUI.Parent do
        local roman, obj = findRomanNumeralCounter()
        if roman then
            local num = 0
            if roman == "I" or roman == "1" then num = 1
            elseif roman == "II" or roman == "2" then num = 2
            elseif roman == "III" or roman == "3" then num = 3
            end

            if num == 1 or num == 2 then
                StatusLabel.Text = string.format(
                    "Chu kỳ Sea King: %s\nHydra: CHƯA THỂ xuất hiện.", roman
                )
                StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
            elseif num == 3 then
                StatusLabel.Text = string.format(
                    "Chu kỳ Sea King: III\n→ Hạ Sea King này, Hydra sẽ xuất hiện sau 1 giờ!"
                )
                StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
            end
        else
            StatusLabel.Text = "Không tìm thấy bộ đếm.\nHãy chắc chắn bạn đang ở Sea 2 và đứng gần khu vực Sea King."
            StatusLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
        end

        task.wait(2)
    end
end)

-- Theo dõi thông báo Hydra xuất hiện (dự phòng)
-- Khi Hydra spawn, server sẽ gửi thông báo "Hydra has appear in the sea"
-- Script sẽ bắt thông báo này qua hook SetCore
local StarterGui = game:GetService("StarterGui")
local oldSetCore = StarterGui.SetCore
StarterGui.SetCore = function(self, coreName, ...)
    if coreName == "SendNotification" then
        local args = {...}
        local text = args[1] and args[1].Text or ""
        if string.find(string.lower(text), "hydra") then
            StatusLabel.Text = "⚠️ HYDRA ĐÃ XUẤT HIỆN!\nNó sẽ biến mất sau 20 phút."
            StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
        end
    end
    return oldSetCore(self, coreName, ...)
end
