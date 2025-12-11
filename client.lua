-- Simple Roblox whitelist client
-- Requirements: exploit must support http_request/syn.request and readfile

local function get_hwid()
    -- Basic HWID example; adapt if your executor exposes a better identifier
    local sys = identifyexecutor and identifyexecutor() or "unknown"
    local randomFile = "hwid_seed.txt"
    if not isfile(randomFile) then
        writefile(randomFile, tostring(os.time()) .. "-" .. sys)
    end
    return game:GetService("HttpService"):GenerateGUID(false) .. "-" .. readfile(randomFile)
end

-- URL Netlify live
local API_BASE = "https://sage-capybara-e179a6.netlify.app/api"
local hwid = get_hwid()

local function request(url, body)
    local json = game:GetService("HttpService"):JSONEncode(body)
    local resp = (syn and syn.request or http_request)({
        Url = url,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = json
    })
    if not resp or resp.StatusCode >= 400 then
        return nil, resp and resp.Body or "http error"
    end
    local ok, decoded = pcall(function()
        return game:GetService("HttpService"):JSONDecode(resp.Body)
    end)
    if not ok then
        return nil, "decode error"
    end
    return decoded, nil
end

local function validate_key(key)
    local data, err = request(API_BASE .. "/validate", { key = key, hwid = hwid })
    if err then
        return false, err
    end
    if data.error then
        return false, tostring(data.error)
    end
    return true, nil
end

-- Usage: set your key here or provide _G.script_key before loadstring
local KEY = _G.script_key or ""
-- Daftar script yang akan dieksekusi setelah valid (default, tanpa perlu set apapun)
local NEXT_SCRIPT_LIST = {
    "https://raw.githubusercontent.com/Kurniaharun/pisit/refs/heads/main/main",
    "https://raw.githubusercontent.com/Kurniaharun/pisit/refs/heads/main/x5",
    "https://raw.githubusercontent.com/Kurniaharun/pisit/refs/heads/main/x7",
}

local ok, err = validate_key(KEY)
if ok then
    print("Key valid; script lanjut jalan")
    -- Notif pojok kanan bawah kalau tersedia
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "SCRIPT VALID",
            Text = "LOADING EXECUTE",
            Duration = 5
        })
    end)
    for _, url in ipairs(NEXT_SCRIPT_LIST) do
        local success, execErr = pcall(function()
            local code = game:HttpGet(url)
            local fn = loadstring(code)
            if fn then fn() end
        end)
        if not success then
            warn("Gagal menjalankan script: " .. tostring(url) .. " => " .. tostring(execErr))
        end
    end
else
    if not KEY or KEY == "" then
        game.Players.LocalPlayer:Kick("Key kosong: set _G.script_key sebelum loadstring")
        return
    end
    if err == "HWID mismatch" then
        game.Players.LocalPlayer:Kick("HWID tidak valid / beda device")
    else
        game.Players.LocalPlayer:Kick("Key tidak valid: " .. tostring(err or "unknown error"))
    end
end

