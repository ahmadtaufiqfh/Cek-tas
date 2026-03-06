local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local WebhookURL = "https://discord.com/api/webhooks/1455443365964419264/BUP-YUDGDbCZp6XiVaqDyC62_OWh8N_aOTFotkzs5qwujXzYgnzDSXbiBmjNt9QyccDs"

-- ==========================================
-- PEMBUATAN UI (USER INTERFACE)
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local TitleLabel = Instance.new("TextLabel")
local StatusLabel = Instance.new("TextLabel") -- Label baru untuk info direktori
local CheckButton = Instance.new("TextButton")
local UICorner1 = Instance.new("UICorner")
local UICorner2 = Instance.new("UICorner")

ScreenGui.Name = "RadarIkanUI"
local successGui, errGui = pcall(function()
    ScreenGui.Parent = (gethui and gethui()) or CoreGui
end)
if not successGui then
    ScreenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
end

-- Setup MainFrame (Diperbesar sedikit untuk menampung label status)
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
MainFrame.Position = UDim2.new(0.5, -100, 0.8, -70)
MainFrame.Size = UDim2.new(0, 200, 0, 130)
MainFrame.Active = true
MainFrame.Draggable = true 

UICorner1.Parent = MainFrame
UICorner1.CornerRadius = UDim.new(0, 10)

-- Setup Title
TitleLabel.Name = "TitleLabel"
TitleLabel.Parent = MainFrame
TitleLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
TitleLabel.Size = UDim2.new(1, 0, 0, 30)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Text = "Radar Fishit"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 14

UICorner2.Parent = TitleLabel
UICorner2.CornerRadius = UDim.new(0, 10)

-- Setup Status Label (Untuk menampilkan direktori yang ditemukan)
StatusLabel.Name = "StatusLabel"
StatusLabel.Parent = MainFrame
StatusLabel.BackgroundTransparency = 1
StatusLabel.Position = UDim2.new(0, 0, 0, 35)
StatusLabel.Size = UDim2.new(1, 0, 0, 25)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.Text = "Menunggu perintah..."
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLabel.TextSize = 11
StatusLabel.TextWrapped = true

-- Setup Button
CheckButton.Name = "CheckButton"
CheckButton.Parent = MainFrame
CheckButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
CheckButton.Position = UDim2.new(0.1, 0, 0.55, 0)
CheckButton.Size = UDim2.new(0.8, 0, 0, 40)
CheckButton.Font = Enum.Font.GothamBold
CheckButton.Text = "Cek Tas & Kirim"
CheckButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CheckButton.TextSize = 14

local UICorner3 = Instance.new("UICorner")
UICorner3.Parent = CheckButton
UICorner3.CornerRadius = UDim.new(0, 8)

-- ==========================================
-- LOGIKA PENCARIAN & PENGIRIMAN
-- ==========================================

local function getBaseFishName(rawName)
    return rawName:gsub("%[.-%]%s*", ""):gsub("%(.-%)%s*", "")
end

-- Fungsi baru untuk mencari lokasi tas
local function findInventory(player)
    -- 1. Prioritas utama: Cek folder kustom yang sering dipakai game
    local possibleFolderNames = {"Inventory", "Fish", "Items", "Bag"}
    for _, name in pairs(possibleFolderNames) do
        local customFolder = player:FindFirstChild(name)
        if customFolder then
            return customFolder, "Folder: " .. name
        end
    end
    
    -- 2. Prioritas kedua: Cek Backpack bawaan Roblox
    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        return backpack, "Player Backpack"
    end
    
    -- Jika tidak ketemu sama sekali
    return nil, "Tidak Ditemukan"
end

local isProcessing = false

CheckButton.MouseButton1Click:Connect(function()
    if isProcessing then return end
    isProcessing = true
    
    local player = Players.LocalPlayer
    CheckButton.Text = "Mencari Tas..."
    CheckButton.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
    
    -- Memanggil fungsi pencari tas
    local inventory, dirName = findInventory(player)
    
    if not inventory then
        StatusLabel.Text = "Error: Tas tidak ditemukan!"
        StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        CheckButton.Text = "Gagal"
        task.wait(2)
        CheckButton.Text = "Cek Tas & Kirim"
        CheckButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
        isProcessing = false
        return
    end

    StatusLabel.Text = "Lokasi: " .. dirName
    StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    CheckButton.Text = "Menghitung Ikan..."

    local fishCounts = {}
    local totalFish = 0

    -- Mengecek isi dari direktori yang ditemukan
    for _, item in pairs(inventory:GetChildren()) do
        -- Menghitung item jika berupa Tool atau StringValue/NumberValue
        if item:IsA("Tool") or item:IsA("ValueBase") or item:IsA("Model") then
            local fishName = getBaseFishName(item.Name)
            if fishCounts[fishName] then
                fishCounts[fishName] = fishCounts[fishName] + 1
            else
                fishCounts[fishName] = 1
            end
            totalFish = totalFish + 1
        end
    end

    local description = ""
    if totalFish > 0 then
        for name, count in pairs(fishCounts) do
            description = description .. "🐟 **" .. name .. "**: " .. count .. "\n"
        end
    else
        description = "Tas saat ini kosong. Tidak ada ikan di " .. dirName .. "."
    end

    local payload = {
        ["username"] = player.Name .. " Radar",
        ["embeds"] = {{
            ["title"] = "🎒 Laporan Isi Tas (Inventory)",
            ["description"] = description,
            ["color"] = 3447003,
            ["footer"] = {
                ["text"] = "Total Ikan: " .. totalFish .. " | Direktori: " .. dirName
            }
        }}
    }

    local httprequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request

    if httprequest then
        local success, err = pcall(function()
            httprequest({
                Url = WebhookURL,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = HttpService:JSONEncode(payload)
            })
        end)
        
        if success then
            CheckButton.Text = "Berhasil Dikirim!"
            CheckButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
        else
            CheckButton.Text = "Gagal Mengirim!"
            CheckButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
            StatusLabel.Text = "Error Webhook!"
            StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        end
    else
        CheckButton.Text = "Executor Tidak Support"
        CheckButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    end

    task.wait(3)
    StatusLabel.Text = "Menunggu perintah..."
    StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    CheckButton.Text = "Cek Tas & Kirim"
    CheckButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
    isProcessing = false
end)
