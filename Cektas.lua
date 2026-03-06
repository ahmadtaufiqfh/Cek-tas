local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WebhookURL = "https://discord.com/api/webhooks/1455443365964419264/BUP-YUDGDbCZp6XiVaqDyC62_OWh8N_aOTFotkzs5qwujXzYgnzDSXbiBmjNt9QyccDs"

-- ==========================================
-- PEMBUATAN UI (SMART MEMORY MAPPER V7.1)
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
TitleLabel.BackgroundColor3 = Color3.fromRGB(138, 43, 226)
TitleLabel.Size = UDim2.new(1, 0, 0, 30)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Text = "🧠 MEMORY RADAR V7.1"
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
StatusLabel.Text = "Anti-Freeze Enabled"
StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
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
-- LOGIKA ANTI-FREEZE DEEP SCANNING
-- ==========================================

local function fetchDictionary()
    local validFishNames = {}
    local itemsFolder = ReplicatedStorage:FindFirstChild("Items")
    if itemsFolder then
        for _, item in pairs(itemsFolder:GetChildren()) do
            table.insert(validFishNames, item.Name)
        end
        table.sort(validFishNames, function(a, b) return string.len(a) > string.len(b) end)
    end
    return validFishNames
end

local isProcessing = false

-- Fungsi memindai dengan Jeda (Yield) agar game tidak macet
local function startSafeMemoryScan(player, validFishNames)
    task.spawn(function()
        local gc = getgc(true)
        local totalObjects = #gc
        local bestCounts = {}
        local highestTotal = 0
        
        for i, obj in ipairs(gc) do
            -- Memberi nafas (jeda) setiap 1500 objek yang dicek
            if i % 1500 == 0 then
                local percent = math.floor((i / totalObjects) * 100)
                StatusLabel.Text = "Menyisir... " .. percent .. "%"
                task.wait() -- INI KUNCI AGAR LAYAR TIDAK FREEZE
            end
            
            if type(obj) == "table" then
                local tempCounts = {}
                local tempTotal = 0
                local matchFoundInTable = false

                pcall(function()
                    local checks = 0
                    for key, value in pairs(obj) do
                        checks = checks + 1
                        
                        local fishDataName = nil
                        -- Menggunakan rawget untuk mencegah error metamethod
                        if type(value) == "table" then
                            fishDataName = rawget(value, "Name") or rawget(value, "name") or rawget(value, "Id")
                        elseif type(value) == "string" then
                            fishDataName = value
                        end

                        if type(fishDataName) == "string" then
                            local lowerName = string.lower(fishDataName)
                            for _, baseName in ipairs(validFishNames) do
                                if string.find(lowerName, string.lower(baseName), 1, true) then
                                    tempCounts[baseName] = (tempCounts[baseName] or 0) + 1
                                    tempTotal = tempTotal + 1
                                    matchFoundInTable = true
                                    break
                                end
                            end
                        end

                        -- FILTER CERDAS: Jika sudah cek 10 item pertama di tabel ini 
                        -- dan tidak ada satupun yang mirip ikan, langsung batalkan tabel ini!
                        if checks == 10 and not matchFoundInTable then
                            break
                        end
                    end
                end)

                -- Simpan tabel dengan jumlah ikan terbanyak
                if matchFoundInTable and tempTotal > highestTotal then
                    highestTotal = tempTotal
                    bestCounts = tempCounts
                end
            end
        end

        -- SELESAI SCANNING: Lanjut Proses Discord
        if highestTotal > 0 then
            StatusLabel.Text = "Ditemukan " .. highestTotal .. " Ikan!"
            StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
            CheckButton.Text = "Mengirim Discord..."
            
            local description = ""
            local sortedNames = {}
            for name in pairs(bestCounts) do table.insert(sortedNames, name) end
            table.sort(sortedNames)

            for _, name in ipairs(sortedNames) do
                description = description .. "🐟 **" .. name .. "**: " .. bestCounts[name] .. "\n"
            end

            if string.len(description) > 3900 then
                description = string.sub(description, 1, 3900) .. "\n\n*[Data terpotong karena batas limit Discord]*"
            end

            local payload = {
                ["username"] = player.Name .. " Radar",
                ["embeds"] = {{
                    ["title"] = "🎒 Laporan Isi Tas (Memory Extracted)",
                    ["description"] = description,
                    ["color"] = 9055202,
                    ["footer"] = {
                        ["text"] = "Total Ikan: " .. highestTotal .. " | System: getgc() Mapper V7.1"
                    }
                }}
            }

            local httprequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request

            if httprequest then
                local success, _ = pcall(function()
                    httprequest({
                        Url = WebhookURL, Method = "POST",
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
                CheckButton.Text = "Exe Tdk Support"
                CheckButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
            end
        else
            StatusLabel.Text = "Data tidak ditemukan di memori."
            StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
            CheckButton.Text = "Tas Kosong / Gagal"
            CheckButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        end

        task.wait(3)
        StatusLabel.Text = "Anti-Freeze Enabled"
        StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        CheckButton.Text = "Scan Memori & Kirim"
        CheckButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
        isProcessing = false
    end)
end

CheckButton.MouseButton1Click:Connect(function()
    if isProcessing then return end
    isProcessing = true
    
    local player = Players.LocalPlayer
    
    CheckButton.Text = "Menyiapkan Scan..."
    CheckButton.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
    StatusLabel.Text = "Mengekstrak Kamus..."
    StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
    
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

    -- Memulai proses scan memori berat di latar belakang (tanpa freeze)
    startSafeMemoryScan(player, validFishNames)
end)
