local function loadScriptFromURL(url)
    local success, result = pcall(function()
        return game:HttpGet(url)
    end)
    
    if success and result then
        local loadSuccess, scriptFunction = pcall(function()
            return loadstring(result)
        end)
        
        if loadSuccess and scriptFunction then
            local runSuccess, err = pcall(scriptFunction)
            if not runSuccess then
                warn("Error saat menjalankan script: " .. tostring(err))
            end
        else
            warn("Gagal melakukan parse/loadstring pada script.")
        end
    else
        warn("Gagal mendownload script dari URL: " .. tostring(url))
    end
end

-- Coba tambahkan task.spawn atau pcall tambahan di pemanggilan utama untuk menghindari freeze UI saat init
task.spawn(function()
    loadScriptFromURL("https://raw.githubusercontent.com/donyfiebryprayoga/Donn/refs/heads/main/loader/D.lua")
end)
