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
StatusLabel.Text = "Mode: Background Scan"
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
-- LOGIKA PEMINDAIAN UI TERSEMBUNYI (BACKGROUND)
-- ==========================================

-- Fungsi untuk membersihkan nama ikan dari varian seperti "Big", "Shiny", "[Tag]", dll.
local function cleanFishName(rawName)
    local name = rawName:gsub("%[.-%]%s*", ""):gsub("%(.-%)%s*", "")
    -- Menghapus awalan ukuran/varian yang umum ada di game memancing
    name = name:gsub("^Big ", ""):gsub("^Huge ", ""):gsub("^Giant ", ""):gsub("^Tiny ", ""):gsub("^Shiny ", "")
    return name
end

-- Fungsi utama untuk membaca UI tanpa membukanya
local function scanHiddenUI(player)
    local playerGui = player:WaitForChild("PlayerGui")
    local frameScores = {}
    
    -- Langkah 1: Mencari lokasi wadah/grid tas dengan mendeteksi teks "kg"
    for _, obj in pairs(playerGui:GetDescendants()) do
        if obj:IsA("TextLabel") then
            local textLower = string.lower(obj.Text)
            -- Mendeteksi format berat seperti "880K kg", "813.81K kg"
            if string.match(textLower, "%d+%.?%d*%w*%s*kg") then
                local card = obj.Parent
                if card and card.Parent then
                    local grid = card.Parent
                    frameScores[grid] = (frameScores[grid] or 0) + 1
                end
            end
        end
    end
    
    -- Menentukan mana wadah tas yang asli (yang punya teks "kg" terbanyak)
    local bestGrid = nil
    local maxScore = 0
    for grid, score in pairs(frameScores) do
        if score > maxScore then
            maxScore = score
            bestGrid = grid
        end
    end
    
    if not bestGrid then
        return nil, 0, "Gagal: UI Tas belum ter-load."
    end
    
    -- Langkah 2: Mengekstrak nama ikan dari wadah tersebut
    local fishCounts = {}
    local totalFish = 0
    
    for _, card in pairs(bestGrid:GetChildren()) do
        if card:IsA("GuiObject") then
            local hasWeight = false
            local texts = {}
            
            -- Kumpulkan semua teks di dalam kartu ikan
            for _, desc in pairs(card:GetDescendants()) do
                if desc:IsA("TextLabel") then
                    local txt = desc.Text
                    if string.match(string.lower(txt), "%d+%.?%d*%w*%s*kg") then
                        hasWeight = true
                    else
                        -- Bersihkan spasi kosong
                        txt = string.match(txt, "^%s*(.-)%s*$")
                        if txt and txt ~= "" then
                            table.insert(texts, txt)
                        end
                    end
                end
            end
            
            -- Jika kartu valid (punya berat dan teks lain)
            if hasWeight and #texts > 0 then
                -- Teks terpanjang pasti adalah nama ikannya (bukan label mutasi spt "Sandy")
                local longestText = ""
                for _, txt in pairs(texts) do
                    if string.len(txt) > string.len(longestText) then
                        longestText = txt
                    end
                end
                
                if longestText ~= "" then
                    local fishName = cleanFishName(longestText)
                    fishCounts[fishName] = (fishCounts[fishName] or 0) + 1
                    totalFish = totalFish + 1
                end
            end
        end
    end
    
    return fishCounts, totalFish, "Data UI Hidden"
end

local isProcessing = false

CheckButton.MouseButton1Click:Connect(function()
    if isProcessing then return end
    isProcessing = true
    
    local player = Players.LocalPlayer
    CheckButton.Text = "Memindai Background..."
    CheckButton.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
    
    -- Jalankan scanner
    local fishCounts, totalFish, statusMsg = scanHiddenUI(player)
    
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
        for name, count in pairs(fishCounts) do
            description = description .. "🐟 **" .. name .. "**: " .. count .. "\n"
        end
    else
        description = "Tas saat ini kosong. Tidak ada data yang ditemukan di UI."
    end

    local payload = {
        ["username"] = player.Name .. " Radar",
        ["embeds"] = {{
            ["title"] = "🎒 Laporan Isi Tas (Inventory)",
            ["description"] = description,
            ["color"] = 3447003,
            ["footer"] = {
                ["text"] = "Total Ikan: " .. totalFish .. " | Auto-Scrape Background"
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
    StatusLabel.Text = "Mode: Background Scan"
    StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    CheckButton.Text = "Cek Tas & Kirim"
    CheckButton.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
    isProcessing = false
end)
