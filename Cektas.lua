local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WebhookURL = "https://discord.com/api/webhooks/1455443365964419264/BUP-YUDGDbCZp6XiVaqDyC62_OWh8N_aOTFotkzs5qwujXzYgnzDSXbiBmjNt9QyccDs"

-- ==========================================
-- PEMBUATAN UI (HYBRID RADAR V8.1)
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
TitleLabel.BackgroundColor3 = Color3.fromRGB(220, 20, 60) -- Merah Sniper
TitleLabel.Size = UDim2.new(1, 0, 0, 30)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Text = "🎯 HYBRID RADAR V8"
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
StatusLabel.Text = "Wajib buka tas sblm scan!"
StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
StatusLabel.TextSize = 11
StatusLabel.TextWrapped = true

CheckButton.Name = "CheckButton"
CheckButton.Parent = MainFrame
CheckButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
CheckButton.Position = UDim2.new(0.1, 0, 0.55, 0)
CheckButton.Size = UDim2.new(0.8, 0, 0, 40)
CheckButton.Font = Enum.Font.GothamBold
CheckButton.Text = "Kunci Target & Scan"
CheckButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CheckButton.TextSize = 13
local UICorner3 = Instance.new("UICorner")
UICorner3.Parent = CheckButton
UICorner3.CornerRadius = UDim.new(0, 8)

-- ==========================================
-- LOGIKA V8: UI TARGET + SIZE FILTERING
-- ==========================================

local ignoreWords = {"plaque", "rod", "gear", "cup", "watch", "hammer", "bait", "coin", "token", "shard", "crate"}
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
            if not isIgnored(item.Name) then
                table.insert(validFishNames, item.Name)
            end
        end
        table.sort(validFishNames, function(a, b) return string.len(a) > string.len(b) end)
    end
    return validFishNames
end

local function getTargetCountFromUI(player)
    local target = 0
    local playerGui = player:WaitForChild("PlayerGui")
    
    for _, obj in pairs(playerGui:GetDescendants()) do
        if obj:IsA("TextLabel") then
            local currentStr = string.match(obj.Text, "(%d+,?%d*)%s*/%s*%d+,?%d*")
            if currentStr then
                currentStr = string.gsub(currentStr, ",", "")
                local num = tonumber(currentStr)
                if num and num > target then
                    target = num
                end
            end
        end
    end
    return target
end

local isProcessing = false

local function startSafeMemoryScan(player, validFishNames, targetCount)
    task.spawn(function()
        local gc = getgc(true)
        local totalObjects = #gc
        local bestCounts = {}
        local highestTotal = 0
        
        for i, obj in ipairs(gc) do
            if i % 2500 == 0 then
                local percent = math.floor((i / totalObjects) * 100)
                StatusLabel.Text = "Menyisir... " .. percent .. "%"
                task.wait() 
            end
            
            if type(obj) == "table" then
                -- V8 MAGIC: Menghitung ukuran tabel terlebih dahulu
                local keyCount = 0
                for _ in pairs(obj) do keyCount = keyCount + 1 end
                
                -- Hanya mengecek tabel yang isinya mendekati target layar (Minimal 80% dari target)
                local minimumRequired = math.floor(targetCount * 0.8)
                if minimumRequired < 1 then minimumRequired = 1 end
                
                if keyCount >= minimumRequired and keyCount <= targetCount + 1000 then
                    local tempCounts = {}
                    local tempTotal = 0
                    local isMasterDict = false
                    local exactMatches = 0

                    pcall(function()
                        for key, value in pairs(obj) do
                            if type(value) == "table" then
                                local itemName = rawget(value, "Name") or rawget(value, "name") or rawget(value, "Id") or rawget(value, "Item")
                                
                                if type(itemName) == "string" then
                                    if key == itemName then
                                        exactMatches = exactMatches + 1
                                    else
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
                        end
                    end)

                    -- Filter agar tidak menjaring ensiklopedia utama game
                    if exactMatches > (tempTotal * 0.5) then
                        isMasterDict = true
                    end

                    if not isMasterDict and tempTotal > highestTotal then
                        highestTotal = tempTotal
                        bestCounts = tempCounts
                    end
                end
            end
        end

        -- SELESAI SCANNING
        if highestTotal > 0 then
            StatusLabel.Text = "Bingo! " .. highestTotal .. " Ikan Terkunci."
            StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
            CheckButton.Text = "Proses Discord..."
            
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
                    ["title"] = "🎒 Laporan Isi Tas (V8 Target Scraper)",
                    ["description"] = description,
                    ["color"] = 14423100,
                    ["footer"] = {
                        ["text"] = "UI Target: " .. targetCount .. " | Ikan Asli Terbaca: " .. highestTotal
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
            StatusLabel.Text = "Tabel data tdk sinkron dgn UI ("..targetCount..")."
            StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
            CheckButton.Text = "Gagal Menemukan"
            CheckButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        end

        task.wait(3)
        StatusLabel.Text = "Wajib buka tas sblm scan!"
        StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
        CheckButton.Text = "Kunci Target & Scan"
        CheckButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
        isProcessing = false
    end)
end

CheckButton.MouseButton1Click:Connect(function()
    if isProcessing then return end
    isProcessing = true
    
    local player = Players.LocalPlayer
    
    CheckButton.Text = "Melacak UI..."
    CheckButton.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
    
    -- MENGAMBIL ANGKA DARI LAYAR (Contoh: 682/4500)
    local targetCount = getTargetCountFromUI(player)
    
    if targetCount == 0 then
        StatusLabel.Text = "Buka tas dulu agar angka (X/4500) terbaca!"
        StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        CheckButton.Text = "Tas Tertutup"
        task.wait(2)
        CheckButton.Text = "Kunci Target & Scan"
        CheckButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
        isProcessing = false
        return
    end

    StatusLabel.Text = "Target Dikunci: " .. targetCount
    StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    task.wait(0.5)
    
    local validFishNames = fetchDictionary()
    if #validFishNames == 0 then
        StatusLabel.Text = "Error Kamus Game."
        StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        CheckButton.Text = "Gagal"
        task.wait(2)
        CheckButton.Text = "Kunci Target & Scan"
        CheckButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
        isProcessing = false
        return
    end

    startSafeMemoryScan(player, validFishNames, targetCount)
end)
