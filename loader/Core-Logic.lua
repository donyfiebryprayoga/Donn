-- File: loader/Core-Logic.lua (Script Pelacak Struktur Game)
print("[DonnHub Inspector] Memulai pelacakan struktur Grow a Garden 2...")

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Cek folder penting di Workspace
task.spawn(function()
    print("--- DAFTAR OBJEK DI WORKSPACE ---")
    for _, v in pairs(Workspace:GetChildren()) do
        if v:IsA("Folder") or v:IsA("Model") then
            print("Folder/Model ditemukan: " .. v.Name)
        end
    end
end)

-- Cek RemoteEvents (Biasanya dipakai untuk interaksi panen/beli)
task.spawn(function()
    print("--- DAFTAR REMOTE EVENTS ---")
    for _, v in pairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
            print("Remote ditemukan: " .. v.Name)
        end
    end
end)
