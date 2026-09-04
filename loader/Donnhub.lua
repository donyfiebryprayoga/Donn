-- Letakkan LocalScript ini di StarterPlayer > StarterPlayerScripts

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- 1. Membuat UI Loader secara otomatis di pojok kanan bawah
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ScriptLoaderGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 260, 0, 70)
-- Mengatur posisi ke pojok kanan bawah dengan margin/jarak 20 pixel dari tepi
frame.Position = UDim2.new(1, -280, 1, -90)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Parent = screenGui

-- Sudut melengkung untuk tampilan modern
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = frame

local textLabel = Instance.new("TextLabel")
textLabel.Size = UDim2.new(1, 0, 1, 0)
textLabel.BackgroundTransparency = 1
textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
textLabel.TextSize = 16
textLabel.Font = Enum.Font.GothamBold
textLabel.Text = "Memuat skrip..."
textLabel.Parent = frame

-- 2. Proses Mengunduh Skrip Eksternal
local scriptUrl = "https://raw.githubusercontent.com/donyfiebryprayoga/Donn/refs/heads/main/loader/Donnhub.lua"

local success, result = pcall(function()
    return game:HttpGet(scriptUrl)
end)

if success then
    -- 3. Update teks jadi sukses saat berhasil diunduh
    textLabel.Text = "Sukses! Menjalankan skrip..."
    textLabel.TextColor3 = Color3.fromRGB(46, 204, 113) -- Warna Hijau
    
    local loadSuccess, scriptFunc = pcall(function()
        return loadstring(result)
    end)
    
    if loadSuccess and scriptFunc then
        task.spawn(scriptFunc)
        
        -- Hilangkan UI loader setelah 2 detik
        task.wait(2)
        screenGui:Destroy()
    else
        textLabel.Text = "Gagal mengompilasi skrip!"
        textLabel.TextColor3 = Color3.fromRGB(231, 76, 60) -- Warna Merah
        warn("Gagal mengompilasi: " + tostring(scriptFunc))
    end
else
    textLabel.Text = "Gagal mengunduh skrip!"
    textLabel.TextColor3 = Color3.fromRGB(231, 76, 60)
    warn("Gagal mengunduh dari URL: " + tostring(result))
end
