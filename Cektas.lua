local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WebhookURL = "https://discord.com/api/webhooks/1455443365964419264/BUP-YUDGDbCZp6XiVaqDyC62_OWh8N_aOTFotkzs5qwujXzYgnzDSXbiBmjNt9QyccDs"

-- ==========================================
-- PEMBUATAN UI (SMART MEMORY MAPPER V7.2)
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
TitleLabel.Text = "🧠 MEMORY RADAR V7.2"
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
StatusLabel.Text = "Precision Filter: ON"
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
-- LOGIKA ANTI-FREEZE & PRECISION FILTERING
-- ==========================================

-- Filter untuk membuang item non-ikan
local ignoreWords = {"plaque", "rod", "gear", "cup", "watch", "hammer", "bait", "coin"}
local function isIgnored(name)
    local lower = string.lower(name)
    for _, word in ipairs(ignoreWords) do
        if string.find(lower, word) then return true end
    end
    return false
end

local function fetchDictionary()
    local validFishNames = {}
    local itemsFolder = ReplicatedStorage:FindFirstChild("Items")
    if itemsFolder then
        for _, item in pairs(itemsFolder:GetChildren()) do
            -- Abaikan item sampah dari awal
            if not isIgnored(item.Name) then
                table.insert(validFishNames, item.Name)
            end
        end
        table.sort(validFishNames, function(a, b) return string.len(a) > string.len(b) end)
    end
    return validFishNames
end

local isProcessing = false

local function startSafeMemoryScan(player, validFishNames)
    task.spawn(function()
        local gc = getgc(true)
        local totalObjects = #gc
        local bestCounts = {}
        local highestTotal = 0
        
        for i, obj in ipairs(gc) do
            -- Jeda Anti-Freeze (Bernapas tiap 2000 objek)
            if i % 2000 == 0 then
                local percent = math.floor((i / totalObjects) * 100)
                StatusLabel.Text = "Menganalisis... " .. percent .. "%"
                task.wait() 
            end
            
            if type(obj) == "table" then
                local tempCounts = {}
                local tempTotal = 0
                local masterDictionaryKeys = 0
                local validInventoryKeys = 0

                pcall(function()
                    local checks = 0
                    for key, value in pairs(obj) do
                        checks = checks + 1
                        
                        -- Ciri khas item tas: value nya BUKAN string, melainkan Tabel Data (punya stats)
                        if type(value) == "table" then
                            local itemName = rawget(value, "Name") or rawget(value, "name") or rawget(value, "Item") or rawget(value, "Id")
                            
                            if type(itemName) == "string" then
                                -- MENCEGAH BUG ENSIKLOPEDIA: Jika kunci(key) sama persis dengan nama item, ini adalah Ensiklopedia Game!
                                if key == itemName then
                                    masterDictionaryKeys = masterDictionaryKeys + 1
                                else
                                    -- Ini adalah struktur Tas Asli (menggunakan UUID/Index sebagai key)
                                    validInventoryKeys = validInventoryKeys + 1
                                    
                                    local lowerName = string.lower(itemName)
                                    local foundBaseName = nil

                                    for _, baseName in ipairs(validFishNames) do
                                        if string.find(lowerName, string.lower(baseName), 1, true) then
                                            foundBaseName = baseName
                                            break
                                        end
                                    end

                                    if foundBaseName then
                                        tempCounts[foundBaseName] = (tempCounts[foundBaseName] or 0) + 1
                                        tempTotal = tempTotal + 1
                                    end
                                end
                            end
                        end

                        -- EXIT CEPAT: Jika di 15 entri pertama tidak ada struktur tas sama sekali, lewati tabel ini!
                        if checks == 15 and validInventoryKeys == 0 and masterDictionaryKeys == 0 then
                            break
                        end
                    end
                end)

                -- SYARAT MUTLAK TAS: Tidak boleh lebih banyak Master Keys daripada Valid Keys
                if masterDictionaryKeys > validInventoryKeys then
                    -- Abaikan tabel ini, ini adalah kamus server!
                elseif tempTotal > highestTotal then
                    highestTotal = tempTotal
                    bestCounts = tempCounts
                end
            end
        end

        -- SELESAI SCANNING
        if highestTotal > 0 then
            StatusLabel.Text = "Target Locked: " .. highestTotal .. " Ikan!"
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
                description = string.sub(description, 1, 3900) .. "\n\n*[Data terpotong karena batas Discord]*"
            end

            local payload = {
                ["username"] = player.Name .. " Radar",
                ["embeds"] = {{
                    ["title"] = "🎒 Laporan Isi Tas (Deep Memory Hook)",
                    ["description"] = description,
                    ["color"] = 9055202,
                    ["footer"] = {
                        ["text"] = "Total Ikan Asli: " .. highestTotal .. " | V7.2 Precision Scraper"
                    }
                }}
            }

            local httprequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
            if httprequest then
                pcall(function()
                    httprequest({
                        Url = WebhookURL, Method = "POST",
                        Headers = {["Content-Type"] = "application/json"},
                        Body = HttpService:JSONEncode(payload)
                    })
                end)
                CheckButton.Text = "Berhasil Dikirim!"
                CheckButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
            else
                CheckButton.Text = "Exe Tdk Support"
                CheckButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
            end
        else
            StatusLabel.Text = "Tas kosong atau tidak sinkron."
            StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
            CheckButton.Text = "Gagal Menemukan"
            CheckButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        end

        task.wait(3)
        StatusLabel.Text = "Precision Filter: ON"
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
    
    local validFishNames = fetchDictionary()
    if #validFishNames == 0 then
        StatusLabel.Text = "Gagal memuat Kamus."
        StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        CheckButton.Text = "Error"
        task.wait(2)
        CheckButton.Text = "Scan Memori & Kirim"
        CheckButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
        isProcessing = false
        return
    end

    startSafeMemoryScan(player, validFishNames)
end)
