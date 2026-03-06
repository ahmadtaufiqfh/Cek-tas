local player = game.Players.LocalPlayer
local targetFish = "megalodon"
local targetFolder = "storage"

print("🔍 Memulai pelacakan untuk kata kunci: '" .. targetFish .. "' dan '" .. targetFolder .. "'...")

local found = false

-- Melacak semua yang ada di dalam LocalPlayer
for _, item in pairs(player:GetDescendants()) do
    local itemNameLower = string.lower(item.Name)
    
    -- Jika nama objek mengandung kata "megalodon" ATAU "storage"
    if string.find(itemNameLower, targetFish) or string.find(itemNameLower, targetFolder) then
        print("-------------------------------------------------")
        print("✅ DITEMUKAN KECOCOKAN!")
        print("Nama Objek : " .. item.Name)
        print("Tipe Objek : " .. item.ClassName)
        print("Lokasi/Path: " .. item:GetFullName())
        
        -- Jika objek tersebut menyimpan angka/teks (ValueBase), kita tampilkan isinya
        if item:IsA("ValueBase") then
            print("Isi Data   : " .. tostring(item.Value))
        end
        print("-------------------------------------------------")
        found = true
    end
end

if not found then
    warn("❌ Tidak ditemukan apapun di dalam LocalPlayer. Coba periksa apakah ikan megalodon benar-benar ada di tasmu saat ini.")
end

print("🏁 Pelacakan selesai! Buka konsol (F9) untuk melihat hasilnya.")
