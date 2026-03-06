local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ==========================================
-- PEMBUATAN UI (USER INTERFACE) SNIPER
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local TitleLabel = Instance.new("TextLabel")
local StatusLabel = Instance.new("TextLabel") 
local Button1 = Instance.new("TextButton")
local Button2 = Instance.new("TextButton")

ScreenGui.Name = "SniperRadarUI"
local successGui, _ = pcall(function() ScreenGui.Parent = (gethui and gethui()) or CoreGui end)
if not successGui then ScreenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui") end

MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.Position = UDim2.new(0.5, -100, 0.7, 0)
MainFrame.Size = UDim2.new(0, 220, 0, 160)
MainFrame.Active = true
MainFrame.Draggable = true 

local UICorner1 = Instance.new("UICorner")
UICorner1.Parent = MainFrame
UICorner1.CornerRadius = UDim.new(0, 8)

TitleLabel.Name = "TitleLabel"
TitleLabel.Parent = MainFrame
TitleLabel.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
TitleLabel.Size = UDim2.new(1, 0, 0, 30)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Text = "🎯 SNIPER DIRECTORY"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 14
local UICorner2 = Instance.new("UICorner")
UICorner2.Parent = TitleLabel
UICorner2.CornerRadius = UDim.new(0, 8)

StatusLabel.Name = "StatusLabel"
StatusLabel.Parent = MainFrame
StatusLabel.BackgroundTransparency = 1
StatusLabel.Position = UDim2.new(0, 0, 0, 35)
StatusLabel.Size = UDim2.new(1, 0, 0, 35)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.Text = "Menunggu perintah..."
StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
StatusLabel.TextSize = 11
StatusLabel.TextWrapped = true

-- Tombol 1: Snapshot Awal
Button1.Parent = MainFrame
Button1.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
Button1.Position = UDim2.new(0.05, 0, 0.45, 0)
Button1.Size = UDim2.new(0.9, 0, 0, 35)
Button1.Font = Enum.Font.GothamBold
Button1.Text = "1. REKAM (Tas Tertutup)"
Button1.TextColor3 = Color3.fromRGB(255, 255, 255)
Button1.TextSize = 13
local UIC1 = Instance.new("UICorner") UIC1.Parent = Button1

-- Tombol 2: Sniper Target
Button2.Parent = MainFrame
Button2.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
Button2.Position = UDim2.new(0.05, 0, 0.70, 0)
Button2.Size = UDim2.new(0.9, 0, 0, 35)
Button2.Font = Enum.Font.GothamBold
Button2.Text = "2. SNIPER (Tas Terbuka)"
Button2.TextColor3 = Color3.fromRGB(255, 255, 255)
Button2.TextSize = 13
local UIC2 = Instance.new("UICorner") UIC2.Parent = Button2

-- ==========================================
-- LOGIKA DEEP SCREENING (SNAPSHOT & DIFF)
-- ==========================================

local SnapshotMemory = {}
local isArmed = false

-- Fungsi memfoto kondisi data memori game
local function takeDeepSnapshot()
    local data = {}
    local targets = {Players.LocalPlayer, ReplicatedStorage}
    
    for _, root in ipairs(targets) do
        for _, obj in ipairs(root:GetDescendants()) do
            -- KITA ABAIKAN FILE UI GAMBAR AGAR FOKUS KE DATA MURNI
            if not obj:IsA("GuiObject") and not obj:IsA("UIBase") then
                -- Jika berupa Folder/Model, catat jumlah isinya
                if obj:IsA("Folder") or obj:IsA("Model") or obj:IsA("Configuration") then
                    data[obj:GetFullName()] = "Isi: " .. #obj:GetChildren()
                -- Jika berupa Angka/Teks, catat nilainya
                elseif obj:IsA("ValueBase") then
                    data[obj:GetFullName()] = "Value: " .. tostring(obj.Value)
                end
            end
        end
    end
    return data
end

-- AKSI TOMBOL 1
Button1.MouseButton1Click:Connect(function()
    Button1.Text = "Merekam..."
    Button1.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    
    -- Mengambil foto memori saat tas ditutup
    SnapshotMemory = takeDeepSnapshot()
    isArmed = true
    
    StatusLabel.Text = "Rekaman Awal Disimpan! Sekarang BUKA TAS KAMU lalu klik tombol ke-2."
    StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
    
    Button1.Text = "1. REKAM ULANG"
    Button1.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
end)

-- AKSI TOMBOL 2
Button2.MouseButton1Click:Connect(function()
    if not isArmed then
        StatusLabel.Text = "ERROR: Klik Tombol 1 dulu saat tas tertutup!"
        StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        return
    end

    Button2.Text = "Menganalisis Anomali..."
    Button2.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    
    -- Mengambil foto memori kedua saat tas sudah terbuka
    local newMemory = takeDeepSnapshot()
    local anomalies = {}
    
    -- Membandingkan perbedaan antara foto 1 dan foto 2
    for path, dataString in pairs(newMemory) do
        local oldDataString = SnapshotMemory[path]
        -- Jika ada folder yang tiba-tiba isinya bertambah/berubah
        if oldDataString and oldDataString ~= dataString then
            table.insert(anomalies, {Path = path, Detail = oldDataString .. " -> " .. dataString})
        -- Jika ada folder/objek data baru yang tiba-tiba tercipta
        elseif not oldDataString then
            table.insert(anomalies, {Path = path, Detail = "Objek Baru Muncul!"})
        end
    end
    
    -- Menampilkan Hasil
    print("\n==================================================")
    print("🎯 HASIL SNIPER DIRECTORY 🎯")
    print("==================================================")
    
    if #anomalies > 0 then
        StatusLabel.Text = "BERHASIL! Ditemukan " .. #anomalies .. " perubahan direktori. Cek konsol (F9)."
        StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        
        for i, anomaly in ipairs(anomalies) do
            print(i .. ". [LOKASI]: " .. anomaly.Path)
            print("   [PERUBAHAN]: " .. anomaly.Detail)
            print("--------------------------------------------------")
        end
        print("💡 TIPS: Cari lokasi yang namanya mengandung 'Inventory', 'Storage', 'Fish', atau 'Bag'.")
    else
        StatusLabel.Text = "Tidak ada direktori data fisik yang berubah. Game menggunakan enkripsi murni."
        StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        warn("Sniper tidak menemukan perubahan data fisik. Ini menandakan data tas dikirim dari server langsung ke dalam UI Frame (tidak disimpan di folder).")
    end
    
    Button2.Text = "2. SNIPER (Tas Terbuka)"
    Button2.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
end)
