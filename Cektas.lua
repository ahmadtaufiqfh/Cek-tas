local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WebhookURL = "https://discord.com/api/webhooks/1455443365964419264/BUP-YUDGDbCZp6XiVaqDyC62_OWh8N_aOTFotkzs5qwujXzYgnzDSXbiBmjNt9QyccDs"

-- ==========================================
-- PEMBUATAN UI (SMART MEMORY MAPPER)
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local TitleLabel = Instance.new("TextLabel")
local StatusLabel = Instance.new("TextLabel") 
local CheckButton = Instance.new("TextButton")

ScreenGui.Name = "MemoryRadarUI"
local successGui, _ = pcall(function() ScreenGui.Parent = (gethui and gethui()) or CoreGui end)
if not successGui then ScreenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui") end

MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.Position = UDim2.new(0.5, -100, 0.7, 0)
MainFrame.Size = UDim2.new(0, 200, 0, 130)
MainFrame.Active = true
MainFrame.Draggable = true 

local UICorner1 = Instance.new("UICorner")
UICorner1.Parent = MainFrame
UICorner1.CornerRadius = UDim.new(0, 8)

TitleLabel.Name = "TitleLabel"
TitleLabel.Parent = MainFrame
TitleLabel.BackgroundColor3 = Color3.fromRGB(138, 43, 226) -- Warna ungu (Memory Theme)
TitleLabel.Size = UDim2.new(1, 0, 0, 30)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Text = "🧠 MEMORY RADAR V7"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 13
local UICorner2 = Instance.new("UICorner")
UICorner2.Parent = TitleLabel
UICorner2.CornerRadius = UDim.new(0, 8)

StatusLabel.Name = "StatusLabel"
StatusLabel.Parent = MainFrame
StatusLabel.BackgroundTransparency = 1
StatusLabel.Position = UDim2.new(0, 0, 0, 35)
StatusLabel.Size = UDim2.new(1, 0, 0, 25)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.Text = "Mode: getgc() Memory Scan"
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLabel.TextSize = 11
StatusLabel.TextWrapped = true

CheckButton.Name = "CheckButton"
CheckButton.Parent = MainFrame
CheckButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
CheckButton.Position = UDim2.new(0.1, 0, 0.55, 0)
CheckButton.Size = UDim2.new(0.8, 0, 0, 40)
CheckButton.Font = Enum.Font.GothamBold
CheckButton.Text = "Scan Memori & Kirim"
CheckButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CheckButton.TextSize = 13
local UICorner3 = Instance.new("UICorner")
UICorner3.Parent = CheckButton
UICorner3.CornerRadius = UDim.new(0, 8)

-- ==========================================
-- LOGIKA DEEP MEMORY SCANNING (GETGC)
-- ==========================================

local function fetchDictionary()
    local validFishNames = {}
    local itemsFolder = ReplicatedStorage:FindFirstChild("Items")
    if itemsFolder then
        for _, item in pairs(itemsFolder:GetChildren()) do
            table.insert(validFishNames, item.Name)
        end
        -- Urutkan nama terpanjang ke terpendek agar mutasi tidak menimpa nama asli
        table.sort(validFishNames, function(a, b) return string.len(a) > string.len(b) end)
    end
    return validFishNames
end

local function scanMemoryForInventory(validFishNames)
    local bestCounts = {}
    local highestTotal = 0
    
    -- Memeriksa apakah executor mendukung getgc
    if type(getgc) ~= "function" then
        return nil, 0, "Executor tidak support getgc()"
    end

    -- Menyisir seluruh Garbage Collector (Memory)
    local gc = getgc(true)
    
    for _, obj in pairs(gc) do
        -- Kita hanya mencari tabel (karena data tas biasanya disimpan dalam tabel)
        if type(obj) == "table" then
            local tempCounts = {}
            local tempTotal = 0
            local isInventoryTable = false

            -- Menggunakan pcall agar game tidak crash jika membaca tabel yang terkunci
            pcall(function()
                for key, value in pairs(obj) do
                    local fishDataName = nil
                    
                    -- Skenario 1: Data ikan disimpan sebagai sub-tabel (misal: v.Name = "Big Leviathan")
                    if type(value) == "table" and type(value.Name) == "string" then
                        fishDataName = value.Name
                    -- Skenario 2: Data ikan disimpan langsung sebagai string di dalam tabel
                    elseif type(value) == "string" then
                        fishDataName = value
                    end

                    -- Jika kita menemukan indikasi nama, cocokkan dengan Kamus Ikan
                    if fishDataName then
                        local foundBaseName = nil
                        local lowerName = string.lower(fishDataName)
                        
                        for _, baseName in ipairs(validFishNames) do
                            if string.find(lowerName, string.lower(baseName), 1, true) then
                                foundBaseName = baseName
                                break
                            end
                        end

                        if foundBaseName then
                            tempCounts[foundBaseName] = (tempCounts[foundBaseName] or 0) + 1
                            tempTotal = tempTotal + 1
                            isInventoryTable = true
                        end
                    end
                end
            end)

            -- Tabel yang memiliki kecocokan ikan paling banyak dipastikan adalah tabel Tas/Inventory utama
            if isInventoryTable and tempTotal > highestTotal then
                highestTotal = tempTotal
                bestCounts = tempCounts
            end
        end
    end

    if highestTotal > 0 then
        return bestCounts, highestTotal, "Memori Tas Ditemukan!"
    else
        return nil, 0, "Data tas tidak ditemukan di memori."
    end
end

local isProcessing = false

CheckButton.MouseButton1Click:Connect(function()
    if isProcessing then return end
    isProcessing = true
    
    local player = Players.LocalPlayer
    
    CheckButton.Text = "Menyisir Memori..."
    CheckButton.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
    StatusLabel.Text = "Mengekstrak tabel getgc()..."
    StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
    
    task.wait(0.1) -- Jeda kecil agar UI tidak freeze
    
    local validFishNames = fetchDictionary()
    if #validFishNames == 0 then
        StatusLabel.Text = "Gagal memuat Kamus Game."
        StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        CheckButton.Text = "Error"
        task.wait(2)
        CheckButton.Text = "Scan Memori & Kirim"
        CheckButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
        isProcessing = false
        return
    end

    local fishCounts, totalFish, statusMsg = scanMemoryForInventory(validFishNames)

    if not fishCounts then
        StatusLabel.Text = statusMsg
        StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        CheckButton.Text = "Gagal"
        task.wait(2)
        CheckButton.Text = "Scan Memori & Kirim"
        CheckButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
        isProcessing = false
        return
    end

    StatusLabel.Text = statusMsg
    StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    CheckButton.Text = "Mengirim Discord..."

    local description = ""
    local sortedNames = {}
    for name in pairs(fishCounts) do table.insert(sortedNames, name) end
    table.sort(sortedNames)

    for _, name in ipairs(sortedNames) do
        description = description .. "🐟 **" .. name .. "**: " .. fishCounts[name] .. "\n"
    end

    if string.len(description) > 3900 then
        description = string.sub(description, 1, 3900) .. "\n\n*[Data terpotong karena batas limit Discord]*"
    end

    local payload = {
        ["username"] = player.Name .. " Radar",
        ["embeds"] = {{
            ["title"] = "🎒 Laporan Isi Tas (Memory Extracted)",
            ["description"] = description,
            ["color"] = 9055202, -- Warna ungu khas
            ["footer"] = {
                ["text"] = "Total Ikan: " .. totalFish .. " | System: getgc() Mapper V7"
            }
        }}
    }

    local httprequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request

    if httprequest then
        local success, _ = pcall(function()
            httprequest({
                Url = WebhookURL,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
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
        CheckButton.Text = "Exe Tdk Support API"
        CheckButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    end

    task.wait(3)
    StatusLabel.Text = "Mode: getgc() Memory Scan"
    StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    CheckButton.Text = "Scan Memori & Kirim"
    CheckButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
    isProcessing = false
end)
