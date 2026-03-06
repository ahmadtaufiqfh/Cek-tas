local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WebhookURL = "https://discord.com/api/webhooks/1455443365964419264/BUP-YUDGDbCZp6XiVaqDyC62_OWh8N_aOTFotkzs5qwujXzYgnzDSXbiBmjNt9QyccDs"

-- ==========================================
-- PEMBUATAN UI (USER INTERFACE)
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local TitleLabel = Instance.new("TextLabel")
local StatusLabel = Instance.new("TextLabel") 
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

MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
MainFrame.Position = UDim2.new(0.5, -100, 0.8, -70)
MainFrame.Size = UDim2.new(0, 200, 0, 130)
MainFrame.Active = true
MainFrame.Draggable = true 

UICorner1.Parent = MainFrame
UICorner1.CornerRadius = UDim.new(0, 10)

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

StatusLabel.Name = "StatusLabel"
StatusLabel.Parent = MainFrame
StatusLabel.BackgroundTransparency = 1
StatusLabel.Position = UDim2.new(0, 0, 0, 35)
StatusLabel.Size = UDim2.new(1, 0, 0, 25)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.Text = "Mode: Smart Dict Match"
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLabel.TextSize = 11
StatusLabel.TextWrapped = true

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
-- LOGIKA PEMINDAIAN SUPER AKURAT (DICTIONARY MATCH)
-- ==========================================

local function scanInventoryAccurately(player)
    -- 1. Mengambil Database Nama Ikan Resmi dari Game
    local itemsFolder = ReplicatedStorage:FindFirstChild("Items")
    if not itemsFolder then
        return nil, 0, "Gagal: Folder Items tidak ditemukan"
    end

    local validFishNames = {}
    for _, item in pairs(itemsFolder:GetChildren()) do
        table.insert(validFishNames, item.Name)
    end

    -- Urutkan dari nama terpanjang ke terpendek agar pencocokan akurat
    -- (Misal: agar "Robot Kraken" tidak dibaca setengah jadi "Kraken")
    table.sort(validFishNames, function(a, b)
        return string.len(a) > string.len(b)
    end)

    -- 2. Mencari Wadah Grid Tas di Latar Belakang
    local playerGui = player:WaitForChild("PlayerGui")
    local bestGrid = nil
    local maxKgCount = 0

    for _, obj in pairs(playerGui:GetDescendants()) do
        if obj:IsA("ScrollingFrame") or obj:IsA("Frame") then
            local kgCount = 0
            -- Hitung ada berapa tulisan "kg" di dalam frame ini
            for _, child in pairs(obj:GetDescendants()) do
                if child:IsA("TextLabel") and string.match(string.lower(child.Text), "kg") then
                    kgCount = kgCount + 1
                end
            end
            
            -- Frame yang paling banyak tulisan "kg" dipastikan adalah tas inventory
            if kgCount > maxKgCount and kgCount > 1 then
                maxKgCount = kgCount
                bestGrid = obj
            end
        end
    end

    if not bestGrid then
        return nil, 0, "Tas belum ter-load. Buka menu tas 1x lalu tutup."
    end

    -- 3. Membaca Kotak Ikan dan Mencocokkan dengan Database
    local fishCounts = {}
    local totalFish = 0

    for _, card in pairs(bestGrid:GetChildren()) do
        if card:IsA("GuiObject") then
            local cardText = ""
            local hasKg = false
            
            -- Kumpulkan semua teks yang ada di kotak ikan ini
            for _, desc in pairs(card:GetDescendants()) do
                if desc:IsA("TextLabel") then
                    cardText = cardText .. " " .. desc.Text
                    if string.match(string.lower(desc.Text), "kg") then
                        hasKg = true
                    end
                end
            end

            -- Jika ini benar-benar kotak ikan (karena ada informasi kg)
            if hasKg then
                local cardTextLower = string.lower(cardText)
                local foundBaseName = nil

                -- Cocokkan teks dengan daftar nama ikan asli
                for _, baseName in ipairs(validFishNames) do
                    -- Mencari nama ikan dasar di dalam seluruh teks kartu
                    if string.find(cardTextLower, string.lower(baseName), 1, true) then
                        foundBaseName = baseName
                        break
                    end
                end

                if foundBaseName then
                    fishCounts[foundBaseName] = (fishCounts[foundBaseName] or 0) + 1
                    totalFish = totalFish + 1
                end
            end
        end
    end

    return fishCounts, totalFish, "Database Match Sukses"
end

local isProcessing = false

CheckButton.MouseButton1Click:Connect(function()
    if isProcessing then return end
    isProcessing = true
    
    local player = Players.LocalPlayer
    CheckButton.Text = "Memindai Data..."
    CheckButton.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
    
    local fishCounts, totalFish, statusMsg = scanInventoryAccurately(player)
    
    if not fishCounts then
        StatusLabel.Text = statusMsg
        StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        CheckButton.Text = "Gagal"
        task.wait(2)
        CheckButton.Text = "Cek Tas & Kirim"
        CheckButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
        isProcessing = false
        return
    end

    StatusLabel.Text = "Lokasi: " .. statusMsg
    StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    CheckButton.Text = "Mengirim ke Discord..."

    local description = ""
    if totalFish > 0 then
        -- Mengurutkan nama ikan sesuai abjad untuk laporan
        local sortedNames = {}
        for name in pairs(fishCounts) do table.insert(sortedNames, name) end
        table.sort(sortedNames)

        for _, name in ipairs(sortedNames) do
            description = description .. "🐟 **" .. name .. "**: " .. fishCounts[name] .. "\n"
        end
    else
        description = "Tas saat ini kosong."
    end

    local payload = {
        ["username"] = player.Name .. " Radar",
        ["embeds"] = {{
            ["title"] = "🎒 Laporan Isi Tas (Inventory)",
            ["description"] = description,
            ["color"] = 3447003,
            ["footer"] = {
                ["text"] = "Total Ikan: " .. totalFish .. " | System: Dict Scrape"
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
    StatusLabel.Text = "Mode: Smart Dict Match"
    StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    CheckButton.Text = "Cek Tas & Kirim"
    CheckButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
    isProcessing = false
end)
