local player = game.Players.LocalPlayer
local targetFish = "leviathan" -- Tetap pakai ikan ini sebagai pelacak

print("🕵️‍♂️ Mencari brankas data tas di latar belakang...")

local found = false

local function scanVault(directory)
    pcall(function()
        for _, obj in pairs(directory:GetDescendants()) do
            local path = obj:GetFullName()
            
            -- KITA ABAIKAN KAMUS GAME & UI agar tidak muncul hasil palsu
            if string.find(path, "ReplicatedStorage.Items") or 
               string.find(path, "ReplicatedStorage.Variants") or
               string.find(path, "PlayerGui") or 
               string.find(path, "CmdrClient") then
                continue
            end

            -- Jika nama objek mengandung leviathan
            if string.find(string.lower(obj.Name), targetFish) then
                print("-------------------------------------------------")
                print("✅ POTENSI DATA TAS DITEMUKAN!")
                print("Nama Objek : " .. obj.Name)
                print("Tipe Objek : " .. obj.ClassName)
                print("Lokasi/Path: " .. path)
                
                if obj:IsA("ValueBase") then
                    print("Isi Value  : " .. tostring(obj.Value))
                end
                print("-------------------------------------------------")
                found = true
            end
        end
    end)
end

-- Memindai karakter/data pemain
scanVault(player)
-- Memindai tempat penyimpanan umum server
scanVault(game:GetService("ReplicatedStorage"))

if not found then
    warn("❌ Data tidak ditemukan dalam bentuk objek. Game sepertinya menggunakan 'ModuleScript' atau 'RemoteFunction'.")
end
print("🏁 Pemindaian latar belakang selesai! Silakan cek F9.")
