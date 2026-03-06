-- Kita gunakan "leviathan" karena ada di daftar tas kamu (Big Leviathan)
local targetFish = "leviathan"

print("🔍 Memulai pemindaian super untuk mencari: '" .. targetFish .. "'...")

local function searchDirectory(directory)
    local foundSomething = false
    -- Menggunakan pcall agar script tidak error jika ada folder yang dikunci game
    pcall(function()
        for _, item in pairs(directory:GetDescendants()) do
            if string.find(string.lower(item.Name), string.lower(targetFish)) then
                print("-------------------------------------------------")
                print("✅ DITEMUKAN!")
                print("Nama Objek : " .. item.Name)
                print("Tipe Objek : " .. item.ClassName)
                print("Lokasi/Path: " .. item:GetFullName())
                if item:IsA("ValueBase") then
                    print("Isi Value  : " .. tostring(item.Value))
                end
                print("-------------------------------------------------")
                foundSomething = true
            end
        end
    end)
    return foundSomething
end

local foundInPlayer = searchDirectory(game.Players.LocalPlayer)
local foundInReplicated = searchDirectory(game:GetService("ReplicatedStorage"))

if not foundInPlayer and not foundInReplicated then
    warn("❌ Masih tidak ditemukan. Game mungkin menyandikan (enkripsi) nama itemnya.")
end

print("🏁 Pelacakan selesai! Silakan cek konsol (F9).")
