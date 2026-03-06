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
StatusLabel.Text = "Mode: Directory Locator"
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLabel.TextSize = 11
StatusLabel.TextWrapped = true

CheckButton.Name = "CheckButton"
CheckButton.Parent = MainFrame
CheckButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
CheckButton.Position = UDim2.new(0.1, 0, 0.55, 0)
CheckButton.Size = UDim2.new(0.8, 0, 0, 40)
CheckButton.Font = Enum.Font.GothamBold
CheckButton.Text = "Cari Tas & Kirim"
CheckButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CheckButton.TextSize = 14

local UICorner3 = Instance.new("UICorner")
UICorner3.Parent = CheckButton
UICorner3.CornerRadius = UDim.new(0, 8)

-- ==========================================
-- LOGIKA PENCARIAN DIREKTORI & PENCOCOKAN KAMUS
-- ==========================================

local function buildFishDictionary()
    local validFishNames = {}
    local itemsFolder = ReplicatedStorage:FindFirstChild("Items")
    
    if itemsFolder then
        for _, item in pairs(itemsFolder:GetChildren()) do
            table.insert(validFishNames, item.Name)
        end
        -- Urutkan nama dari terpanjang ke terpendek agar akurat saat filtering
        table.sort(validFishNames, function(a, b) return string.len(a) > string.len(b) end)
    end
    return validFishNames
end

local function locateAndReadInventory(player, validFishNames)
    local bestDirectory = nil
    local highestMatchScore = 0
    local totalItemsInDir = 0

    -- 1. MENCARI DIREKTORI TAS (Auto-Locate)
    -- Kita scan semua folder di dalam data pemain
    local scanTargets = player:GetDescendants()
    
    for _, obj in pairs(scanTargets) do
        -- Cari tempat yang bisa menampung banyak item (Folder, Configuration, Model)
        if obj:IsA("Folder") or obj:IsA("Configuration") or obj:IsA("Model") then
            local matchScore = 0
            local itemCount = 0
            
            -- Cek isi folder ini, apakah isinya adalah ikan-ikan kita?
            pcall(function()
                for _, item in pairs(obj:GetChildren()) do
                    itemCount = itemCount + 1
                    local itemNameLower = string.lower(item.Name)
                    
                    -- Cek apakah nama objek ini ada di kamus ikan
                    for _, fishName in ipairs(validFishNames) do
                        if string.find(itemNameLower, string.lower(fishName), 1, true) then
                            matchScore = matchScore + 1
                            break
                        end
                    end
                end
            end)

            -- Jika folder ini punya banyak ikan (lebih dari 5) dan mengalahkan folder lain,
            -- maka ini dipastikan adalah Direktori Tas yang asli!
            if matchScore > highestMatchScore and matchScore > 5 then
                highestMatchScore = matchScore
                bestDirectory = obj
                totalItemsInDir = itemCount
            end
        end
    end

    -- Jika tas tidak ditemukan di bentuk folder fisik
    if not bestDirectory then
        return nil, 0, 0, "Gagal: Direktori Tas Fisik tidak ditemukan."
    end

    -- 2. MEMBACA ISI DIREKTORI TAS YANG DITEMUKAN
    local fishCounts = {}
    local validFishCount = 0

    for _, item in pairs(bestDirectory:GetChildren()) do
        local itemNameLower = string.lower(item.Name)
        local foundBaseName = nil

        -- Mencocokkan nama dengan kamus untuk mengabaikan varian (mutasi)
        for _, baseName in ipairs(validFishNames) do
            if string.find(itemNameLower, string.lower(baseName), 1, true) then
                foundBaseName = baseName
                break
            end
        end

        -- Jika ikan valid, masukkan ke laporan
        if foundBaseName then
            fishCounts[foundBaseName] = (fishCounts[foundBaseName] or 0) + 1
            validFishCount = validFishCount + 1
        end
    end

    local dirPath = bestDirectory:GetFullName()
    -- Memotong nama path jika terlalu panjang agar rapi di Discord
    if string.len(dirPath) > 50 then
        dirPath = "..." .. string.sub(dirPath, -47)
    end

    return fishCounts, validFishCount, totalItemsInDir, dirPath
end

local isProcessing = false

CheckButton.MouseButton1Click:Connect(function()
    if isProcessing then return end
    isProcessing = true
    
    local player = Players.LocalPlayer
    
    StatusLabel.Text = "1. Mengambil Kamus Ikan..."
    CheckButton.Text = "Memproses..."
    CheckButton.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
    task.wait(0.5) -- Sedikit delay agar UI sempat update
    
    local validFishNames = buildFishDictionary()
    if #validFishNames == 0 then
        StatusLabel.Text = "Error: Kamus Local.Storage Kosong!"
        StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        CheckButton.Text = "Gagal"
        task.wait(2)
        CheckButton.Text = "Cari Tas & Kirim"
        CheckButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
        isProcessing = false
        return
    end

    StatusLabel.Text = "2. Melacak Direktori Tas..."
    task.wait(0.5)
    
    -- Menjalankan pencari direktori
    local fishCounts, validFishCount, totalItemsInDir, dirPath = locateAndReadInventory(player, validFishNames)
    
    if not fishCounts then
        StatusLabel.Text = dirPath -- Menampilkan pesan error
        StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        CheckButton.Text = "Tas Tidak Fisik"
        task.wait(3)
        CheckButton.Text = "Cari Tas & Kirim"
        CheckButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
        isProcessing = false
        return
    end

    StatusLabel.Text = "Direktori Ditemukan!"
    StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    CheckButton.Text = "Mengirim Data..."

    -- Menyusun Laporan
    local description = ""
    if validFishCount > 0 then
        local sortedNames = {}
        for name in pairs(fishCounts) do table.insert(sortedNames, name) end
        table.sort(sortedNames)

        for _, name in ipairs(sortedNames) do
            description = description .. "🐟 **" .. name .. "**: " .. fishCounts[name] .. "\n"
        end
    else
        description = "Tas saat ini kosong."
    end

    -- Mencegah pesan error Discord karena kepanjangan
    if string.len(description) > 3900 then
        description = string.sub(description, 1, 3900) .. "\n\n*[Data terpotong karena batas Discord]*"
    end

    local payload = {
        ["username"] = player.Name .. " Radar",
        ["embeds"] = {{
            ["title"] = "🎒 Laporan Isi Tas (Inventory)",
            ["description"] = description,
            ["color"] = 3447003,
            ["footer"] = {
                -- Menampilkan format X/Y (Valid Fish / Total Items In Folder) dan lokasi direktori
                ["text"] = "Total Ikan: " .. validFishCount .. "/" .. totalItemsInDir .. " | Path: " .. dirPath
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
            CheckButton.Text = "Gagal Webhook!"
            CheckButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
        end
    else
        CheckButton.Text = "Executor Tdk Support"
        CheckButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    end

    task.wait(3)
    StatusLabel.Text = "Mode: Directory Locator"
    StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    CheckButton.Text = "Cari Tas & Kirim"
    CheckButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
    isProcessing = false
end)
