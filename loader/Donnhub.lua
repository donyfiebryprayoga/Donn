-- UI Loader di pojok kanan bawah dengan penanganan error yang jelas
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ScriptLoaderGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = game:GetService("CoreGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 260, 0, 70)
frame.Position = UDim2.new(1, -280, 1, -90)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Parent = screenGui

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

local scriptUrl = "https://raw.githubusercontent.com/donyfiebryprayoga/Donn/refs/heads/main/loader/Donnhub.lua"

-- Mengunduh skrip dengan pengaman pcall
local success, result = pcall(function()
    return game:HttpGet(scriptUrl)
end)

if success and result and result ~= "" then
    -- Coba kompilasi skrip yang diunduh
    local loadSuccess, scriptFunc = pcall(function()
        return loadstring(result)
    end)
    
    if loadSuccess and type(scriptFunc) == "function" then
        textLabel.Text = "Sukses! Menjalankan skrip..."
        textLabel.TextColor3 = Color3.fromRGB(46, 204, 113) -- Hijau
        
        -- Jalankan skrip utama
        task.spawn(scriptFunc)
        
        task.wait(2)
        screenGui:Destroy()
    else
        textLabel.Text = "Gagal Kompilasi!"
        textLabel.TextColor3 = Color3.fromRGB(231, 76, 60) -- Merah
        warn("Error Kompilasi: " .. tostring(scriptFunc))
    end
else
    textLabel.Text = "Gagal Mengunduh!"
    textLabel.TextColor3 = Color3.fromRGB(231, 76, 60) -- Merah
    warn("Error HTTP/URL Kosong: " .. tostring(result))
end
