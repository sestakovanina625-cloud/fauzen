-- BoogaX Simple Working GUI
-- Простой и рабочий интерфейс
-- 
-- ОПТИМИЗАЦИИ:
-- ✓ Управление connections (отключение при выключении функций)
-- ✓ Автоматическое обновление ESP/Hitboxes при подключении/отключении игроков
-- ✓ Кэширование waypoints для уменьшения сортировки
-- ✓ Оптимизация частоты обновлений
-- ✓ Замена wait() на task.wait()
-- ✓ Безопасная работа с setclipboard
-- ✓ Проверка существования объектов перед использованием
-- ✓ Система HWID для защиты скрипта
-- 
-- ОПТИМИЗАЦИИ FPS (2024):
-- ✓ RenderStepped заменен на task.spawn с интервалом 2 сек (Old Boards удаление)
-- ✓ WalkSpeed - агрессивное поддержание (проверяет каждый кадр, игра не может сбросить)
-- ✓ GetRawGoldAmount кэшируется на 3 секунды (GetDescendants оптимизация)
-- ✓ ESP оптимизирован с debounce 0.1 сек (обновление расстояния)
-- ✓ Отключен избыточный вывод warn() для производительности
-- ✓ Все print/warn HWID системы отключены

-- ============================================
-- СИСТЕМА HWID (Hardware ID)
-- ============================================
-- вот тут удаляем старые доски
-- ОПТИМИЗАЦИЯ: вместо каждого кадра (RenderStepped) проверяем раз в 2 секунды
task.spawn(function()
    while task.wait(2) do
        pcall(function()
            if workspace.Resources then
                local oldBoards = workspace.Resources:FindFirstChild("Old Boards")
                if oldBoards then
                    oldBoards:Destroy()
                end
            end
        end)
    end
end)

local partsData = {
    {name="SigmaPart", shape=Enum.PartType.Wedge, pos=Vector3.new(-122,-28,-193), size=Vector3.new(4,30,25), ori=Vector3.new(0,180,0)},
    {name="SigmaPart2", shape=Enum.PartType.Wedge, pos=Vector3.new(-202,5,-616), size=Vector3.new(4,30,25), ori=Vector3.new(0,200,0)},
    {name="SigmaPart3", pos=Vector3.new(-214,18,-627), size=Vector3.new(12,1,12)},
    {name="SigmaPart4", shape=Enum.PartType.Wedge, pos=Vector3.new(-44,-104,-392), size=Vector3.new(6,20,17)},
    {name="SigmaPart5", pos=Vector3.new(-45,-94,-374), size=Vector3.new(13,1,13)},
}

for _, data in ipairs(partsData) do
    local p = Instance.new("Part")
    p.Name = data.name
    p.Parent = workspace
    p.Anchored = true
    p.Color = Color3.fromRGB(255, 0, 0)
    p.Transparency = 0.9
    if data.shape then p.Shape = data.shape end
    if data.ori then p.Orientation = data.ori end
    p.Position, p.Size = data.pos, data.size
end
-- Безопасная инициализация персонажа
pcall(function()
	local player = game:GetService("Players").LocalPlayer
	if player then
		local char = player.Character or player.CharacterAdded:Wait()
		if char then
			local humanoid = char:WaitForChild("Humanoid", 10)
			if humanoid then
				humanoid.MaxSlopeAngle = 90
			end
		end
	end
end)
-- Глобальная настройка: полностью отключить вывод в консоль
local SILENT_MODE = false  -- ОТКЛЮЧЕН для диагностики координат

do
	if SILENT_MODE then
		local function noop(...) end
		-- Переопределяем стандартные функции вывода
		print = noop
		warn = noop
		pcall(function() if rconsoleprint then rconsoleprint = noop end end)
		pcall(function() if rconsoleinfo then rconsoleinfo = noop end end)
		pcall(function() if rconsolewarn then rconsolewarn = noop end end)
		pcall(function() if rconsoleerr then rconsoleerr = noop end end)
	end
end

-- Опция для отключения проверки HWID (для тестирования)
local HWID_CHECK_ENABLED = true -- Установите false чтобы отключить проверку HWID

-- Pastebin URL для списка HWID
local PASTEBIN_URL = "https://pastebin.com/ud5g2T3T"
local PASTEBIN_RAW = "https://pastebin.com/raw/ud5g2T3T"

-- Список разрешённых HWID (загружается из Pastebin или используется локальный)
local WhitelistedHWIDs = {
    "329B7058-2122-480A-8ED7-2C18AD6D623B", -- улитка
}

-- Функция загрузки HWID из Pastebin
local function LoadHWIDsFromPastebin()
    local response = nil
    local success = false
    local usedMethod = "none"
    
    -- Метод 1: Через game:HttpGet (если доступен)
    if not success then
        local tryHttpGet = pcall(function()
            if game.HttpGet then
                response = game:HttpGet(PASTEBIN_RAW)
                if response then 
                    success = true 
                    usedMethod = "game:HttpGet"
                end
            end
        end)
    end
    
    -- Метод 2: Через http_request (если доступен)
    if not success then
        local tryHttpRequest = pcall(function()
            if http_request then
                local req = http_request({
                    Url = PASTEBIN_RAW,
                    Method = "GET"
                })
                if req and req.Body then
                    response = req.Body
                    success = true
                    usedMethod = "http_request"
                end
            end
        end)
    end
    
    -- Метод 3: Через syn.request (Synapse X)
    if not success then
        local trySynRequest = pcall(function()
            if syn and syn.request then
                local req = syn.request({
                    Url = PASTEBIN_RAW,
                    Method = "GET"
                })
                if req and req.Body then
                    response = req.Body
                    success = true
                    usedMethod = "syn.request"
                end
            end
        end)
    end
    
    -- Метод 4: Через request (другие executor'ы)
    if not success then
        local tryRequest = pcall(function()
            if request then
                local req = request({
                    Url = PASTEBIN_RAW,
                    Method = "GET"
                })
                if req and req.Body then
                    response = req.Body
                    success = true
                    usedMethod = "request"
                end
            end
        end)
    end
    
    -- Метод 5: Через HttpService:GetAsync (последний вариант)
    if not success then
        local tryGetAsync = pcall(function()
            if game:GetService("HttpService") then
                local HttpService = game:GetService("HttpService")
                response = HttpService:GetAsync(PASTEBIN_RAW)
                if response then 
                    success = true 
                    usedMethod = "HttpService:GetAsync"
                end
            end
        end)
    end
    
    -- Если загрузка не удалась, возвращаем false
    if not response or not success then
        --print("⚠️ Could not load HWIDs from Pastebin")
        --print("Attempted methods:")
        local methodChecks = {}
        pcall(function() methodChecks[1] = game.HttpGet and "available" or "not available" end)
        pcall(function() methodChecks[2] = http_request and "available" or "not available" end)
        pcall(function() methodChecks[3] = (syn and syn.request) and "available" or "not available" end)
        pcall(function() methodChecks[4] = request and "available" or "not available" end)
        
        --print("  1. game:HttpGet - " .. (methodChecks[1] or "not available"))
        --print("  2. http_request - " .. (methodChecks[2] or "not available"))
        --print("  3. syn.request - " .. (methodChecks[3] or "not available"))
        --print("  4. request - " .. (methodChecks[4] or "not available"))
        --print("  5. HttpService:GetAsync - available (but blocked)")
        --print("All methods were blocked or unavailable")
        --print("Make sure your executor supports HTTP requests to external URLs")
        --warn("Failed to load HWIDs from Pastebin")
        return false
    end
    
    -- Парсим ответ
    local parseSuccess, parseResult = pcall(function()
        --print("=== Pastebin Response ===")
        --print("Used method: " .. usedMethod)
        --print("Raw response length: " .. string.len(response))
        --print("First 200 chars: " .. string.sub(response, 1, 200))
        --print("=========================")
        
        -- Очищаем старый список (кроме базовых)
        local baseHWIDs = {}
        for _, hwid in ipairs(WhitelistedHWIDs) do
            if hwid == "329B7058-2122-480A-8ED7-2C18AD6D623B" then
                table.insert(baseHWIDs, hwid)
            end
        end
        WhitelistedHWIDs = baseHWIDs
        
        local loadedCount = 0
        
        -- Улучшенный парсинг (формат: return {"hwid1", "hwid2", ...})
        -- Убираем комментарии (включая многострочные)
        local cleaned = response:gsub("%s*%-%-[^\n]*", "") -- Однострочные комментарии
        cleaned = cleaned:gsub("%-%-%[%[.-%]%]%-%-", "") -- Многострочные комментарии
        
        -- Убираем return и пробелы
        cleaned = cleaned:gsub("return%s*", "")
        cleaned = cleaned:gsub("^%s*{", "{") -- Убираем пробелы перед {
        cleaned = cleaned:gsub("}%s*$", "}") -- Убираем пробелы после }
        
        -- Извлекаем HWID между кавычками (учитываем разные варианты кавычек)
        for hwid in cleaned:gmatch('["\']([^"\']+)["\']') do
            hwid = hwid:gsub("^%s+", ""):gsub("%s+$", "") -- Убираем пробелы
            
            -- Пропускаем пустые строки и тестовые "hwid"
            if hwid ~= "" and hwid:lower() ~= "hwid" then
                -- Проверяем, нет ли уже такого HWID
                local exists = false
                for _, existing in ipairs(WhitelistedHWIDs) do
                    if existing == hwid then
                        exists = true
                        break
                    end
                end
                if not exists then
                    table.insert(WhitelistedHWIDs, hwid)
                    loadedCount = loadedCount + 1
                    --print("Loaded HWID: " .. hwid)
                end
            end
        end
        
        --print("=== Pastebin Load Result ===")
        --print("Total HWIDs loaded: " .. loadedCount)
        --print("Total HWIDs in whitelist: " .. #WhitelistedHWIDs)
        --print("HWID List:")
        --for i, hwid in ipairs(WhitelistedHWIDs) do
        --    print("  [" .. i .. "] " .. tostring(hwid))
        --end
        --print("============================")
        
        return true
    end)
    
    if not parseSuccess then
        warn("Failed to parse Pastebin response: " .. tostring(parseResult))
        return false
    end
    
    return parseResult
end

-- Функция получения HWID пользователя
local function GetHWID()
    local hwid = nil
    
    -- Метод 1: Через executor функции (самый надежный)
    if not hwid then
        pcall(function()
            if gethwid then
                hwid = gethwid()
            elseif syn and syn.get_hwid then
                hwid = syn.get_hwid()
            elseif fluxus and fluxus.get_hwid then
                hwid = fluxus.get_hwid()
            elseif krnl and krnl.get_hwid then
                hwid = krnl.get_hwid()
            end
        end)
    end
    
    -- Метод 2: Через identifyexecutor
    if not hwid then
        pcall(function()
            if identifyexecutor then
                local executor = identifyexecutor()
                if executor == "Synapse X" and syn and syn.get_hwid then
                    hwid = syn.get_hwid()
                elseif executor == "Fluxus" and fluxus and fluxus.get_hwid then
                    hwid = fluxus.get_hwid()
                end
            end
        end)
    end
    
    -- Метод 3: Через getgenv
    if not hwid then
        pcall(function()
            if getgenv then
                if getgenv().hwid then
                    hwid = getgenv().hwid
                elseif getgenv().HardwareID then
                    hwid = getgenv().HardwareID
                elseif getgenv().hardware_id then
                    hwid = getgenv().hardware_id
                end
            end
        end)
    end
    
    -- Метод 4: Через Roblox сервисы
    if not hwid then
        pcall(function()
            local HttpService = game:GetService("HttpService")
            if HttpService then
                -- Генерируем уникальный ID на основе игрока
                local Players = game:GetService("Players")
                if Players.LocalPlayer then
                    local userId = Players.LocalPlayer.UserId
                    hwid = HttpService:GenerateGUID(false) .. "-" .. tostring(userId)
                else
                    hwid = HttpService:GenerateGUID(false)
                end
            end
        end)
    end
    
    -- Метод 5: Последний резерв - UserId
    if not hwid then
        pcall(function()
            local Players = game:GetService("Players")
            if Players.LocalPlayer then
                hwid = tostring(Players.LocalPlayer.UserId)
            end
        end)
    end
    
    return hwid or "unknown"
end

-- Функция проверки HWID
local function CheckHWID()
    local userHWID = GetHWID()
    
    -- Преобразуем в строку для надежности
    userHWID = tostring(userHWID):gsub("^%s+", ""):gsub("%s+$", "") -- Убираем пробелы
    
    --print("=== HWID Check ===")
    --print("Your HWID: [" .. userHWID .. "]")
    --print("HWID length: " .. string.len(userHWID))
    --print("Whitelisted HWIDs count: " .. #WhitelistedHWIDs)
    
    -- Сначала проверяем, есть ли "hwid" в списке (разрешает всем для тестирования)
    for _, whitelistedHWID in ipairs(WhitelistedHWIDs) do
        local whitelistedStr = tostring(whitelistedHWID):gsub("^%s+", ""):gsub("%s+$", "")
        if whitelistedStr:lower() == "hwid" then
            --print("Found 'hwid' in whitelist - granting access to all")
            return true -- Если в списке есть "hwid", разрешаем всем
        end
    end
    
    -- Проверяем, есть ли точное совпадение HWID в белом списке
    for i, whitelistedHWID in ipairs(WhitelistedHWIDs) do
        local whitelistedStr = tostring(whitelistedHWID):gsub("^%s+", ""):gsub("%s+$", "")
        --print("  Comparing with [" .. i .. "]: [" .. whitelistedStr .. "] (length: " .. string.len(whitelistedStr) .. ")")
        
        -- Точное совпадение (с учетом регистра)
        if whitelistedStr == userHWID then
            --print("✓ EXACT MATCH FOUND! HWID authorized.")
            return true
        end
        
        -- Также проверяем без учета регистра (на всякий случай)
        if whitelistedStr:lower() == userHWID:lower() then
            --print("✓ MATCH FOUND (case-insensitive)! HWID authorized.")
            return true
        end
    end
    
    --print("✗ HWID NOT FOUND in whitelist")
    --print("Your HWID: [" .. userHWID .. "]")
    --print("Whitelist:")
    --for i, hwid in ipairs(WhitelistedHWIDs) do
    --    print("  [" .. i .. "] [" .. tostring(hwid) .. "]")
    --end
    --print("===================")
    return false -- HWID не найден в белом списке
end

-- Загружаем HWID из Pastebin при запуске
if HWID_CHECK_ENABLED then
    task.spawn(function()
        LoadHWIDsFromPastebin()
    end)
    task.wait(1) -- Даём время на загрузку
end

-- Проверка HWID перед запуском скрипта (если включена)
local userHWID = GetHWID()
local hwidAuthorized = true -- По умолчанию разрешено

if HWID_CHECK_ENABLED then
    hwidAuthorized = CheckHWID()
    
    -- Отладочная информация
    --print("=== BoogaX HWID Check ===")
    --print("HWID Check: ENABLED")
    --print("Your HWID: " .. tostring(userHWID))
    --print("Whitelisted HWIDs count: " .. #WhitelistedHWIDs)
    --print("Authorized: " .. tostring(hwidAuthorized))
    --print("=========================")
else
    --print("=== BoogaX HWID Check ===")
    --print("HWID Check: DISABLED (Testing Mode)")
    --print("Your HWID: " .. tostring(userHWID))
    --print("All access granted for testing")
    --print("=========================")
end

-- GUI для авторизации HWID (показывается только если не авторизован)
local HWIDAuthGUI = nil

-- Объявляем функцию CreateMainGUI() заранее (определена ниже)
local CreateMainGUI = nil

local function CreateHWIDAuthGUI()
    if HWIDAuthGUI then return end -- Уже создано
    
    -- Получаем HWID пользователя
    local currentUserHWID = GetHWID()
    
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer or Players:GetPlayers()[1]
    
    -- Создание GUI
    HWIDAuthGUI = Instance.new("ScreenGui")
    HWIDAuthGUI.Name = "BoogaXHWIDAuth"
    HWIDAuthGUI.ResetOnSpawn = false
    HWIDAuthGUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    pcall(function()
        HWIDAuthGUI.Parent = game:GetService("CoreGui")
    end)
    if not HWIDAuthGUI.Parent then
        HWIDAuthGUI.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    
    -- Главное окно
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 500, 0, 400)
    MainFrame.Position = UDim2.new(0.5, -250, 0.5, -200)
    MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = HWIDAuthGUI
    
    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 12)
    MainCorner.Parent = MainFrame
    
    -- Заголовок
    local Header = Instance.new("Frame")
    Header.Size = UDim2.new(1, 0, 0, 50)
    Header.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    Header.BorderSizePixel = 0
    Header.Parent = MainFrame
    
    local HeaderCorner = Instance.new("UICorner")
    HeaderCorner.CornerRadius = UDim.new(0, 12)
    HeaderCorner.Parent = Header
    
    local Title = Instance.new("TextLabel")
    Title.Text = "🔐 BoogaX HWID Authorization"
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 18
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.Size = UDim2.new(1, -20, 1, 0)
    Title.Position = UDim2.new(0, 10, 0, 0)
    Title.BackgroundTransparency = 1
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Header
    
    -- Ваш HWID
    local HWIDFrame = Instance.new("Frame")
    HWIDFrame.Size = UDim2.new(1, -20, 0, 100)
    HWIDFrame.Position = UDim2.new(0, 10, 0, 60)
    HWIDFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    HWIDFrame.BorderSizePixel = 0
    HWIDFrame.Parent = MainFrame
    
    local HWIDCorner = Instance.new("UICorner")
    HWIDCorner.CornerRadius = UDim.new(0, 8)
    HWIDCorner.Parent = HWIDFrame
    
    local HWIDLabel = Instance.new("TextLabel")
    HWIDLabel.Text = "Your HWID:"
    HWIDLabel.Font = Enum.Font.Gotham
    HWIDLabel.TextSize = 14
    HWIDLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    HWIDLabel.Size = UDim2.new(1, -20, 0, 25)
    HWIDLabel.Position = UDim2.new(0, 10, 0, 5)
    HWIDLabel.BackgroundTransparency = 1
    HWIDLabel.TextXAlignment = Enum.TextXAlignment.Left
    HWIDLabel.Parent = HWIDFrame
    
    local HWIDDisplay = Instance.new("TextBox")
    HWIDDisplay.Text = currentUserHWID or "Loading..."
    HWIDDisplay.Font = Enum.Font.Gotham
    HWIDDisplay.TextSize = 12
    HWIDDisplay.TextColor3 = Color3.fromRGB(255, 255, 255)
    HWIDDisplay.Size = UDim2.new(1, -100, 0, 35)
    HWIDDisplay.Position = UDim2.new(0, 10, 0, 30)
    HWIDDisplay.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    HWIDDisplay.BorderSizePixel = 0
    HWIDDisplay.ClearTextOnFocus = false
    HWIDDisplay.Parent = HWIDFrame
    
    -- Обновляем HWID если он ещё не получен
    if not currentUserHWID or currentUserHWID == "unknown" or HWIDDisplay.Text == "Loading..." then
        task.spawn(function()
            task.wait(0.5)
            local updatedHWID = GetHWID()
            if updatedHWID and updatedHWID ~= "unknown" then
                HWIDDisplay.Text = updatedHWID
                currentUserHWID = updatedHWID
            end
        end)
    end
    
    local HWIDCorner2 = Instance.new("UICorner")
    HWIDCorner2.CornerRadius = UDim.new(0, 6)
    HWIDCorner2.Parent = HWIDDisplay
    
    -- Кнопка копировать HWID
    local CopyBtn = Instance.new("TextButton")
    CopyBtn.Size = UDim2.new(0, 80, 0, 35)
    CopyBtn.Position = UDim2.new(1, -90, 0, 30)
    CopyBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 255)
    CopyBtn.Text = "Copy"
    CopyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CopyBtn.Font = Enum.Font.GothamBold
    CopyBtn.TextSize = 12
    CopyBtn.BorderSizePixel = 0
    CopyBtn.Parent = HWIDFrame
    
    local CopyCorner = Instance.new("UICorner")
    CopyCorner.CornerRadius = UDim.new(0, 6)
    CopyCorner.Parent = CopyBtn
    
    CopyBtn.MouseButton1Click:Connect(function()
        local hwidText = currentUserHWID or GetHWID()
        pcall(function()
            if setclipboard then
                setclipboard(hwidText)
            elseif writeclipboard then
                writeclipboard(hwidText)
            end
        end)
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "BoogaX",
            Text = "HWID copied to clipboard!",
            Duration = 2
        })
    end)
    
    -- Убрали поле для ввода HWID - доступ только через Pastebin
    
    -- Кнопки (перемещены сразу после блока HWID)
    local ButtonFrame = Instance.new("Frame")
    ButtonFrame.Size = UDim2.new(1, -20, 0, 100)
    ButtonFrame.Position = UDim2.new(0, 10, 0, 170)
    ButtonFrame.BackgroundTransparency = 1
    ButtonFrame.Parent = MainFrame
    
    local function CreateAuthButton(text, color, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.48, 0, 0, 40)
        btn.BackgroundColor3 = color
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 14
        btn.BorderSizePixel = 0
        btn.Parent = ButtonFrame
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 8)
        btnCorner.Parent = btn
        
        btn.MouseButton1Click:Connect(callback)
        return btn
    end
    
    -- Убрали кнопку "Add HWID" - доступ только через Pastebin
    -- Теперь кнопка "Check Pastebin" занимает всю ширину
    local pastebinBtn = CreateAuthButton("Check Pastebin", Color3.fromRGB(255, 180, 50), function()
        task.spawn(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "BoogaX",
                Text = "Checking Pastebin for your HWID...",
                Duration = 2
            })
            
            local loaded = LoadHWIDsFromPastebin()
            if loaded then
                -- Проверяем, авторизован ли теперь
                if CheckHWID() then
                    game:GetService("StarterGui"):SetCore("SendNotification", {
                        Title = "BoogaX",
                        Text = "✅ Access granted! Your HWID is authorized!",
                        Duration = 3
                    })
                    task.wait(1)
                    if HWIDAuthGUI then
                        HWIDAuthGUI:Destroy()
                        HWIDAuthGUI = nil
                    end
                    
                    -- Создаём основной GUI скрипта
                    task.wait(0.5)
                    CreateMainGUI()
                else
                    local currentHWID = GetHWID()
                    game:GetService("StarterGui"):SetCore("SendNotification", {
                        Title = "BoogaX",
                        Text = "Your HWID not found in Pastebin.\nCheck console for details.",
                        Duration = 5
                    })
                    --print("⚠️ HWID Check Failed!")
                    --print("Your HWID: " .. tostring(currentHWID))
                    --print("Whitelisted HWIDs (" .. #WhitelistedHWIDs .. " total):")
                    --for i, hwid in ipairs(WhitelistedHWIDs) do
                    --    print("  [" .. i .. "] " .. tostring(hwid))
                    --end
                    --print("Make sure your HWID is added to Pastebin in the correct format.")
                end
            else
                game:GetService("StarterGui"):SetCore("SendNotification", {
                    Title = "BoogaX",
                    Text = "Failed to load from Pastebin! Check internet connection.",
                    Duration = 3
                })
            end
        end)
    end)
    pastebinBtn.Size = UDim2.new(1, 0, 0, 40)
    pastebinBtn.Position = UDim2.new(0, 0, 0, 0)
    
    -- Кнопка автоматической проверки (обновляет каждые 5 секунд)
    local autoChecking = false
    local autoCheckBtn = CreateAuthButton("Auto Check (5s)", Color3.fromRGB(100, 200, 255), function()
        if autoChecking then 
            autoChecking = false
            -- Безопасная проверка перед изменением текста
            pcall(function()
                if autoCheckBtn and autoCheckBtn.Parent then
                    autoCheckBtn.Text = "Auto Check (5s)"
                end
            end)
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "BoogaX",
                Text = "Auto check stopped",
                Duration = 2
            })
            return 
        end
        
        autoChecking = true
        -- Безопасная проверка перед изменением текста
        pcall(function()
            if autoCheckBtn and autoCheckBtn.Parent then
                autoCheckBtn.Text = "Stop Auto Check"
            end
        end)
        
        task.spawn(function()
            while autoChecking do
                -- Проверяем, что GUI ещё существует
                if not HWIDAuthGUI or not HWIDAuthGUI.Parent then
                    autoChecking = false
                    break
                end
                
                local loaded = LoadHWIDsFromPastebin()
                if loaded and CheckHWID() then
                    game:GetService("StarterGui"):SetCore("SendNotification", {
                        Title = "BoogaX",
                        Text = "✅ Access granted! Your HWID is authorized!",
                        Duration = 3
                    })
                    task.wait(1)
                    autoChecking = false -- Останавливаем проверку перед уничтожением GUI
                    
                    if HWIDAuthGUI then
                        HWIDAuthGUI:Destroy()
                        HWIDAuthGUI = nil
                    end
                    CreateMainGUI()
                    break
                end
                if autoChecking then
                    task.wait(5) -- Проверяем каждые 5 секунд
                end
            end
        end)
    end)
    autoCheckBtn.Size = UDim2.new(1, 0, 0, 40)
    autoCheckBtn.Position = UDim2.new(0, 0, 0, 50)
    
    -- Убрали кнопку "Continue Anyway" - теперь авторизация обязательна
    
    -- Инструкции для пользователя (после кнопок)
    local InstructionsFrame = Instance.new("Frame")
    InstructionsFrame.Size = UDim2.new(1, -20, 0, 100)
    InstructionsFrame.Position = UDim2.new(0, 10, 0, 280)
    InstructionsFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    InstructionsFrame.BorderSizePixel = 0
    InstructionsFrame.Parent = MainFrame
    
    local InstructionsCorner = Instance.new("UICorner")
    InstructionsCorner.CornerRadius = UDim.new(0, 8)
    InstructionsCorner.Parent = InstructionsFrame
    
    local InstructionsLabel = Instance.new("TextLabel")
    InstructionsLabel.Text = "📋 Instructions:\n1. Copy your HWID\n2. Send to script owner\n3. Wait for owner to add it to Pastebin\n4. Click 'Check Pastebin' or enable 'Auto Check'"
    InstructionsLabel.Font = Enum.Font.Gotham
    InstructionsLabel.TextSize = 11
    InstructionsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    InstructionsLabel.Size = UDim2.new(1, -20, 1, -10)
    InstructionsLabel.Position = UDim2.new(0, 10, 0, 5)
    InstructionsLabel.BackgroundTransparency = 1
    InstructionsLabel.TextXAlignment = Enum.TextXAlignment.Left
    InstructionsLabel.TextYAlignment = Enum.TextYAlignment.Top
    InstructionsLabel.TextWrapped = true
    InstructionsLabel.Parent = InstructionsFrame
end

-- Переменная для отслеживания авторизации
local hwidAuthorizedFlag = hwidAuthorized

-- Функция для создания основного GUI скрипта (вызывается только после авторизации)
CreateMainGUI = function()
    -- Проверяем, что GUI ещё не создан
    if game:GetService("CoreGui"):FindFirstChild("BoogaXSimple") then
        return -- GUI уже создан
    end
    
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local RunService = game:GetService("RunService")
    local TweenService = game:GetService("TweenService")
    local UserInputService = game:GetService("UserInputService")
    local Lighting = game:GetService("Lighting")
	local HttpService = game:GetService("HttpService")

-- Создание папки BoogaX при запуске
local function CreateBoogaXFolder()
    local folderPath = "BoogaX"
    local success = false
    
    -- Пробуем создать папку через makefolder
    local tryMakefolder = pcall(function()
        if makefolder then
            makefolder(folderPath)
            success = true
        end
    end)
    
    -- Если не получилось через makefolder, пробуем через writefile (создаст папку автоматически)
    if not success then
        local tryWritefile = pcall(function()
            if writefile then
                -- Создаём файл-пример в папке (это создаст папку)
                writefile(folderPath .. "/coordinates.txt", "-- Place your coordinates here (JSON or simple format)\n-- JSON format: {\"position\":[{\"X\":1,\"Y\":2,\"Z\":3}]}\n-- Simple format: X,Y,Z; X,Y,Z; ...\n\n-- WAIT FORMAT (NEW!) - Waypoints with pause times:\n-- {\"wait\":[10,20,5],\"positions\":[\"X,Y,Z\",\"X,Y,Z\",\"X,Y,Z\"]}\n-- Each position gets paired with its wait time (in seconds)\n-- Example: {\"wait\":[10],\"positions\":[\"-69.68,-31.02,-96.48\"]}\n-- This will create a waypoint at (-69.68,-31.02,-96.48) and wait 10 seconds there")
                success = true
            end
        end)
    end
    
    if success then
        print("✓ BoogaX folder created successfully!")
        print("📁 Folder path: " .. folderPath)
        print("📝 Place your coordinates file in: " .. folderPath .. "/coordinates.txt")
    else
        warn("⚠️ Could not create BoogaX folder. Make sure your executor supports file operations.")
        print("Available functions check:")
        pcall(function() print("  makefolder: " .. (makefolder and "available" or "not available")) end)
        pcall(function() print("  writefile: " .. (writefile and "available" or "not available")) end)
    end
end

-- Вызываем создание папки при запуске
CreateBoogaXFolder()

-- Переменные
local BASE_WALK_SPEED = 16
local MAX_WALK_SPEED = 22
local CurrentWalkSpeed = BASE_WALK_SPEED
local ESP_ENABLED = false
local MOUNTAIN_CLIMBER_ENABLED = false
local HITBOXES_ENABLED = false
local NIGHT_VISION_ENABLED = false
local GLOW_ENABLED = false
local WAYPOINTS_ENABLED = false
local CRYSTAL_FARM_ENABLED = false
local CRYSTAL_FARM_RUNNING = false
local ANCIENT_TREE_FARM_ENABLED = false
local ANCIENT_TREE_FARM_RUNNING = false
local ESSENCE_PICKUP_RUNNING = false
local GOLD_FARM_ENABLED = false
local GOLD_FARM_RUNNING = false
local NOCLIP_ENABLED = false

-- Оптимизация: Connections для управления
local NoclipConnection = nil
local MountainClimberConnection = nil
local WaypointsInputConnection = nil
local FlyWaypointsInputConnection = nil
local AfkWaypointsInputConnection = nil
local ESPPlayersConnection = nil
local GoldESPConnection = nil
local HitboxesPlayersConnection = nil
local GlowCharacterConnection = nil

-- Контейнеры
local ESP_HOLDER = Instance.new("Folder")
ESP_HOLDER.Name = "ESP_HOLDER"
ESP_HOLDER.Parent = game:GetService("CoreGui")

local HITBOX_HOLDER = Instance.new("Folder", workspace)
HITBOX_HOLDER.Name = "HitboxHolder"
local WAYPOINTS_HOLDER = Instance.new("Folder", workspace)
WAYPOINTS_HOLDER.Name = "WaypointsHolder"

local GlowHighlight = nil
local defaultLighting = {
    Ambient = Lighting.Ambient,
    Brightness = Lighting.Brightness,
    OutdoorAmbient = Lighting.OutdoorAmbient
}

	-- Telegram notifier state
	local TELEGRAM_ENABLED = false
	local TELEGRAM_BOT_TOKEN = ""
	local TELEGRAM_CHAT_ID = "" -- Основной Chat ID этого аккаунта
	local TELEGRAM_CHAT_IDS = {} -- Список ВСЕХ подключенных Chat ID
	local GOLD_FARMED_TOTAL = 0
	local PLAYER_NAME = "Player"
	pcall(function()
		local player = game:GetService("Players").LocalPlayer
		if player then
			PLAYER_NAME = player.Name or "Player"
		end
	end)
	local SCRIPT_START_TIME = tick() -- Время запуска скрипта

	-- Функция форматирования времени работы скрипта в HH:MM:SS
	local function FormatUptime()
		local elapsed = tick() - SCRIPT_START_TIME
		local hours = math.floor(elapsed / 3600)
		local minutes = math.floor((elapsed % 3600) / 60)
		local seconds = math.floor(elapsed % 60)
		return string.format("%02d:%02d:%02d", hours, minutes, seconds)
	end

	-- Кэширование для GetRawGoldAmount
	local cachedRawGold = 0
	local lastGoldCheck = 0
	local GOLD_CHECK_INTERVAL = 3 -- Проверяем раз в 3 секунды для актуальности данных

	local function GetRawGoldAmount()
		-- Используем кэш если прошло меньше заданного интервала
		local currentTime = tick()
		if currentTime - lastGoldCheck < GOLD_CHECK_INTERVAL then
			print("[GetRawGoldAmount] Returning cached value: " .. cachedRawGold)
			return cachedRawGold
		end
		lastGoldCheck = currentTime
		
		print("[GetRawGoldAmount] Scanning for Raw Gold...")
		
		local player = game:GetService("Players").LocalPlayer
		if not player or not player.PlayerGui then 
			print("[GetRawGoldAmount] Player or PlayerGui not found!")
			return 0
		end
		
		local totalRawGold = 0
		local foundItems = {}
		
		for _, element in ipairs(player.PlayerGui:GetDescendants()) do
			if (element:IsA("ImageButton") or element:IsA("ImageLabel") or element:IsA("Frame")) and element.Visible then
				
				local elementName = element.Name:lower()
				local isRawGold = false
				
				if (elementName:find("raw") and elementName:find("gold")) or elementName:find("rawgold") then
					isRawGold = true
				end
				
				if not isRawGold then
					for _, child in ipairs(element:GetChildren()) do
						if child:IsA("TextLabel") and child.Name:lower():find("name") then
							local itemName = child.Text:lower()
							if (itemName:find("raw") and itemName:find("gold")) or itemName:find("rawgold") then
								isRawGold = true
								break
							end
						end
					end
				end
				
				if not isRawGold and (element:IsA("ImageLabel") or element:IsA("ImageButton")) then
					local imageId = tostring(element.Image):lower()
					if imageId:find("gold") or imageId:find("ore") then
						isRawGold = true
					end
				end
				
				if isRawGold then
					local amount = 0
					
					for _, child in ipairs(element:GetDescendants()) do
						if child:IsA("TextLabel") and child.Visible then
							local text = child.Text
							if not text:lower():find("raw") and not text:lower():find("gold") then
								local num = tonumber(text)
								if num and num > 0 then
									amount = num
									break
								end
							end
						end
					end
					
					if amount == 0 then
						amount = 1
					end
					
					totalRawGold = totalRawGold + amount
					table.insert(foundItems, {path = element:GetFullName(), amount = amount})
				end
			end
		end
		
		cachedRawGold = totalRawGold
		print("[GetRawGoldAmount] Found " .. #foundItems .. " items, Total gold: " .. totalRawGold)
		
		-- Выводим детали найденных предметов (для диагностики)
		if #foundItems > 0 then
			print("[GetRawGoldAmount] Details:")
			for i, item in ipairs(foundItems) do
				print("  [" .. i .. "] Amount: " .. item.amount .. " | Path: " .. item.path)
			end
		else
			print("[GetRawGoldAmount] ⚠️ No Raw Gold items found in PlayerGui!")
		end
		
		return totalRawGold
	end

	-- Система синхронизации аккаунтов
	local function UpdateAccountInfo()
		-- Обновляем информацию о текущем аккаунте в общем файле
		local folderPath = "BoogaX"
		local accountsFile = folderPath .. "/accounts.json"
		local accounts = {}
		
		-- Читаем существующие аккаунты
		pcall(function()
			if readfile then
				local content = readfile(accountsFile)
				if content and content ~= "" then
					accounts = HttpService:JSONDecode(content) or {}
				end
			end
		end)
		
	-- ОБНОВЛЯЕМ ЗОЛОТО ПЕРЕД СОХРАНЕНИЕМ
	local currentGold = GetRawGoldAmount()
	
	-- Обновляем/добавляем текущий аккаунт
	accounts[PLAYER_NAME] = {
		player_name = PLAYER_NAME,
		chat_id = TELEGRAM_CHAT_ID,
		raw_gold = currentGold,
		last_update = os.time(),
	}
		
		-- Сохраняем
		pcall(function()
			if writefile then
				writefile(accountsFile, HttpService:JSONEncode(accounts))
			end
		end)
		
		return accounts
	end
	
	local function GetAllAccounts()
		local folderPath = "BoogaX"
		local accountsFile = folderPath .. "/accounts.json"
		local accounts = {}
		
		pcall(function()
			if readfile then
				local content = readfile(accountsFile)
				if content and content ~= "" then
					accounts = HttpService:JSONDecode(content) or {}
				end
			end
		end)
		
		return accounts
	end

	-- Persistence helpers for Telegram settings
	local function LoadTelegramSettings()
		print("📂 LoadTelegramSettings: Loading settings...")
		local folderPath = "BoogaX"
		local filePath = folderPath .. "/telegram.json"
		local loaded = false
		pcall(function()
			if readfile then
				local content = readfile(filePath)
				if content and content ~= "" then
					local data = HttpService:JSONDecode(content)
					TELEGRAM_BOT_TOKEN = tostring(data.bot_token or "")
					TELEGRAM_CHAT_ID = tostring(data.chat_id or "")
					TELEGRAM_CHAT_IDS = data.chat_ids or {}
					TELEGRAM_ENABLED = data.enabled == true
					GOLD_FARMED_TOTAL = tonumber(data.gold_total or 0) or 0
					loaded = true
					print("✅ LoadTelegramSettings: Settings loaded")
					print("   TELEGRAM_ENABLED: " .. tostring(TELEGRAM_ENABLED))
					print("   TELEGRAM_BOT_TOKEN: " .. (TELEGRAM_BOT_TOKEN ~= "" and string.sub(TELEGRAM_BOT_TOKEN, 1, 10) .. "..." or "EMPTY"))
					print("   TELEGRAM_CHAT_ID: " .. (TELEGRAM_CHAT_ID ~= "" and TELEGRAM_CHAT_ID or "EMPTY"))
					print("   TELEGRAM_CHAT_IDS count: " .. #TELEGRAM_CHAT_IDS)
				else
					print("⚠️ LoadTelegramSettings: File is empty or doesn't exist")
				end
			else
				print("⚠️ LoadTelegramSettings: readfile function not available")
			end
		end)
		if not loaded then
			print("❌ LoadTelegramSettings: Failed to load settings")
		end
		return loaded
	end

	local function SaveTelegramSettings()
		local folderPath = "BoogaX"
		local filePath = folderPath .. "/telegram.json"
		
		-- ВАЖНО: Перечитываем файл чтобы получить актуальный список всех Chat ID
		local allChatIds = {}
		local existingBotToken = TELEGRAM_BOT_TOKEN
		local existingEnabled = TELEGRAM_ENABLED
		
		pcall(function()
			if readfile then
				local content = readfile(filePath)
				if content and content ~= "" then
					local data = HttpService:JSONDecode(content)
					allChatIds = data.chat_ids or {}
					-- Используем существующий токен если текущий пустой
					if TELEGRAM_BOT_TOKEN == "" and data.bot_token then
						existingBotToken = tostring(data.bot_token)
					end
				end
			end
		end)
		
		-- Добавляем текущий Chat ID в общий список если его там нет
		if TELEGRAM_CHAT_ID ~= "" then
			local found = false
			for _, id in ipairs(allChatIds) do
				if tostring(id) == tostring(TELEGRAM_CHAT_ID) then
					found = true
					break
				end
			end
			if not found then
				table.insert(allChatIds, TELEGRAM_CHAT_ID)
			end
		end
		
		-- Обновляем локальную переменную
		TELEGRAM_CHAT_IDS = allChatIds
		
		local data = {
			bot_token = existingBotToken,
			chat_id = TELEGRAM_CHAT_ID,
			chat_ids = allChatIds, -- Все подключенные Chat ID
			enabled = existingEnabled,
			gold_total = GOLD_FARMED_TOTAL,
		}
		pcall(function()
			if writefile then
				writefile(filePath, HttpService:JSONEncode(data))
			end
		end)
	end

	-- Telegram sender with executor fallbacks
	local function UrlEncode(str)
		str = tostring(str)
		-- First handle newlines
		str = str:gsub("\r\n", "\n")
		str = str:gsub("\r", "\n")
		
		-- Encode each byte properly (handles UTF-8 multibyte characters)
		local encoded = ""
		for i = 1, #str do
			local c = str:sub(i, i)
			local byte = string.byte(c)
			
			-- Keep unreserved characters as-is
			if (byte >= 48 and byte <= 57) or  -- 0-9
			   (byte >= 65 and byte <= 90) or  -- A-Z
			   (byte >= 97 and byte <= 122) or -- a-z
			   c == "-" or c == "_" or c == "." or c == "~" then
				encoded = encoded .. c
			-- Convert newline to %0A
			elseif c == "\n" then
				encoded = encoded .. "%0A"
			-- Convert space to +
			elseif c == " " then
				encoded = encoded .. "+"
			-- Percent-encode everything else (including UTF-8 bytes)
			else
				encoded = encoded .. string.format("%%%02X", byte)
			end
		end
		
		return encoded
	end

	-- Универсальная функция для HTTP запросов
	local function MakeHttpRequest(url)
		local response = nil
		local success = false
		
		-- Try http_request
		if not success then
			pcall(function()
				if http_request then
					local r = http_request({ Url = url, Method = "GET" })
					if r and r.Body then
						response = r.Body
						success = true
					end
				end
			end)
		end
		
		-- Try syn.request
		if not success then
			pcall(function()
				if syn and syn.request then
					local r = syn.request({ Url = url, Method = "GET" })
					if r and r.Body then
						response = r.Body
						success = true
					end
				end
			end)
		end
		
		-- Try request
		if not success then
			pcall(function()
				if request then
					local r = request({ Url = url, Method = "GET" })
					if r and r.Body then
						response = r.Body
						success = true
					end
				end
			end)
		end
		
		-- Try HttpService:GetAsync
		if not success then
			pcall(function()
				response = HttpService:GetAsync(url)
				success = true
			end)
		end
		
		return success, response
	end

	-- Проверка токена бота
	local function CheckBotToken()
		if TELEGRAM_BOT_TOKEN == "" then
			return false, "Token is empty"
		end
		
		local url = "https://api.telegram.org/bot" .. TELEGRAM_BOT_TOKEN .. "/getMe"
		local success, response = MakeHttpRequest(url)
		
		if not success or not response then
			return false, "No HTTP methods available in executor"
		end
		
		print("Bot check response:", response)
		
		if response:find('"ok":true') then
			local botName = response:match('"username":"([^"]+)"')
			return true, "Bot OK: @" .. (botName or "unknown")
		elseif response:find('"error_code":401') or response:find("Unauthorized") then
			return false, "Invalid Bot Token (401 Unauthorized)"
		else
			return false, "Unknown error: " .. string.sub(response, 1, 100)
		end
	end

	-- Получение обновлений для определения Chat ID
	local function GetChatIdFromUpdates()
		if TELEGRAM_BOT_TOKEN == "" then
			return nil, "❌ Токен бота пустой!"
		end
		
		print("🔍 Получаю обновления от Telegram бота...")
		
		local url = "https://api.telegram.org/bot" .. TELEGRAM_BOT_TOKEN .. "/getUpdates?offset=-1"
		local success, response = MakeHttpRequest(url)
		
		if not success or not response then
			return nil, "❌ HTTP запрос не удался\nПроверь интернет подключение"
		end
		
		print("📡 Ответ от Telegram:", string.sub(response, 1, 300))
		
		if response:find('"ok":true') then
			-- Улучшенный поиск chat id - ищем ВСЕ возможные варианты
			local chatId = response:match('"chat":{"id":([%-]?%d+)')
			
			-- Альтернативные паттерны на случай другого формата
			if not chatId then
				chatId = response:match('"from":{"id":([%-]?%d+)')
			end
			
			if chatId then
				print("✅ Chat ID найден: " .. chatId)
				return chatId, "Успешно!"
			else
				print("⚠️ Сообщения не найдены в ответе")
				return nil, "❌ Сообщений не найдено!\n\n📱 Отправь /start боту в Telegram:\n1. Открой бота в Telegram\n2. Нажми START или напиши /start\n3. Нажми эту кнопку снова"
			end
		elseif response:find('"error_code":401') or response:find("Unauthorized") then
			return nil, "❌ Неверный токен бота!\nПроверь Bot Token"
		else
			return nil, "❌ Ошибка Telegram API\n" .. string.sub(response, 1, 100)
		end
	end

	-- СИСТЕМА ПОИСКА RAW GOLD ДЛЯ BOOGA BOOGA REBORN
	-- Ищет во всех возможных местах, где игра может хранить Raw Gold
	
	-- Улучшенный парсинг чисел из текста
	local function ParseNumberFromText(text)
		if not text then return 0 end
		text = tostring(text):gsub("%s", "") -- убираем пробелы
		
		-- Формат с суффиксом: 10.5M, 1.2K, 5B
		local numStr, suffix = text:match("([%d%.]+)([KkMmBb])")
		if numStr and suffix then
			local num = tonumber(numStr)
			if num then
				local mult = {k=1000, m=1000000, b=1000000000}
				return math.floor(num * (mult[suffix:lower()] or 1))
			end
		end
		
		-- Убираем запятые (разделители тысяч): 10,000 -> 10000
		text = text:gsub(",", "")
		
		-- Пробуем распарсить как число напрямую
		local num = tonumber(text)
		if num then
			return math.floor(num)
		end
		
		-- Ищем первое число в строке (даже если есть текст)
		local numStr = text:match("([%d%.]+)")
		if numStr then
			num = tonumber(numStr)
			if num then
				return math.floor(num)
			end
		end
		
		-- Последняя попытка: ищем любую последовательность цифр
		local digits = text:match("%d+")
		if digits then
			num = tonumber(digits)
			return num or 0
		end
		
		return 0
	end
	
	local function SendTelegramMessage(text)
		if not TELEGRAM_ENABLED or TELEGRAM_BOT_TOKEN == "" or TELEGRAM_CHAT_ID == "" then 
			print("❌ Telegram not enabled or missing credentials")
			return false 
		end
		
		local url = "https://api.telegram.org/bot" .. TELEGRAM_BOT_TOKEN .. "/sendMessage?chat_id=" .. UrlEncode(TELEGRAM_CHAT_ID) .. "&text=" .. UrlEncode(text)
		
		print("=== Telegram Send Attempt ===")
		print("Bot Token: " .. string.sub(TELEGRAM_BOT_TOKEN, 1, 20) .. "...")
		print("Chat ID: " .. TELEGRAM_CHAT_ID)
		print("Message: " .. text)
		
		local success, response = MakeHttpRequest(url)
		
		if success and response then
			print("Response:", string.sub(response, 1, 200))
			if response:find('"ok":true') then
				print("✅ Message sent successfully!")
				return true
			else
				print("❌ Telegram API error:", response)
				return false
			end
		else
			print("❌ No HTTP method available in executor!")
			return false
		end
	end

	local function IncrementGold(amount)
		amount = tonumber(amount) or 0
		if amount == 0 then return end
		GOLD_FARMED_TOTAL = math.max(0, GOLD_FARMED_TOTAL + amount)
		SaveTelegramSettings()
		if TELEGRAM_ENABLED then
			local playerName = (game:GetService("Players").LocalPlayer and game:GetService("Players").LocalPlayer.Name) or "Player"
			local msg = "💰 Gold farmed: +" .. tostring(amount) .. "\nTotal: " .. tostring(GOLD_FARMED_TOTAL) .. "\n👤 " .. playerName
			SendTelegramMessage(msg)
		end
	end


	-- Telegram bot command handler
	local LAST_UPDATE_ID = 0
	local BOT_LOOP_RUNNING = false -- Флаг для предотвращения множественных запусков
	
	local function GetTelegramUpdates()
		if not TELEGRAM_ENABLED or TELEGRAM_BOT_TOKEN == "" then 
			-- Не логируем каждый раз, чтобы не засорять консоль
			return nil 
		end
		
		-- Используем offset для получения только новых обновлений
		-- Если LAST_UPDATE_ID = 0, получим все непрочитанные обновления
		local offset = LAST_UPDATE_ID + 1
		local url = "https://api.telegram.org/bot" .. TELEGRAM_BOT_TOKEN .. "/getUpdates?offset=" .. tostring(offset) .. "&timeout=1&allowed_updates=[\"message\"]"
		
		local success, response = MakeHttpRequest(url)
		
		if not success or not response then
			-- Логируем только периодически, чтобы не засорять консоль
			return nil
		end
		
		local decodeSuccess, data = pcall(function()
			return HttpService:JSONDecode(response)
		end)
		
		if not decodeSuccess then
			print("❌ GetTelegramUpdates: JSON decode failed")
			print("Response: " .. string.sub(tostring(response), 1, 200))
			return nil
		end
		
		if data and data.ok and data.result then
			if #data.result > 0 then
				print("✅ GetTelegramUpdates: Received " .. #data.result .. " update(s), offset was: " .. offset)
			end
			return data.result
		elseif data and not data.ok then
			local errorDescription = tostring(data.description or "Unknown error")
			local errorCode = data.error_code or 0
			
			-- Обработка конфликта: если другой экземпляр бота уже получает обновления
			if errorCode == 409 or errorDescription:find("Conflict") or errorDescription:find("terminated by other getUpdates") then
				-- Это нормальная ситуация, если запущено несколько экземпляров скрипта
				-- Не логируем каждый раз, чтобы не засорять консоль
				-- Просто ждем и пробуем снова в следующей итерации
				return nil
			end
			
			-- Для других ошибок логируем только первый раз
			if not (GetTelegramUpdates.lastError == errorDescription) then
				print("❌ GetTelegramUpdates: Telegram API error: " .. errorDescription)
				GetTelegramUpdates.lastError = errorDescription
				if errorCode == 401 then
					print("   This usually means the bot token is invalid!")
				end
			end
		end
		
		return nil
	end
	
	local function HandleTelegramCommand(message)
		if not message or not message.text then 
			print("⚠️ HandleTelegramCommand: No message or text")
			return 
		end
		
		local text = message.text
		local chatId = tostring(message.chat.id)
		
		print("📨 HandleTelegramCommand: Received command '" .. text .. "' from chat " .. chatId)
		
		-- Получаем актуальный список Chat ID из файла
		local allChatIds = {}
		local folderPath = "BoogaX"
		local filePath = folderPath .. "/telegram.json"
		pcall(function()
			if readfile then
				local content = readfile(filePath)
				if content and content ~= "" then
					local data = HttpService:JSONDecode(content)
					allChatIds = data.chat_ids or {}
				end
			end
		end)
		
		-- Проверяем что это один из наших Chat ID
		local isAuthorized = false
		for _, id in ipairs(allChatIds) do
			if tostring(id) == chatId then
				isAuthorized = true
				break
			end
		end
		
		-- Разрешаем /start от любого пользователя (для первого подключения)
		-- Если это /start и пользователь не авторизован, добавляем его в список
		if text == "/start" and not isAuthorized then
			-- Добавляем новый Chat ID в список (мы уже знаем, что его там нет)
			table.insert(allChatIds, chatId)
			-- Сохраняем обновленный список
			local folderPath = "BoogaX"
			local filePath = folderPath .. "/telegram.json"
			pcall(function()
				if readfile and writefile then
					local content = readfile(filePath)
					local data = {}
					if content and content ~= "" then
						data = HttpService:JSONDecode(content) or {}
					end
					-- Сохраняем все существующие данные и обновляем chat_ids
					data.chat_ids = allChatIds
					writefile(filePath, HttpService:JSONEncode(data))
					print("✅ Новый Chat ID добавлен: " .. chatId)
				end
			end)
			isAuthorized = true -- Теперь пользователь авторизован
		end
		
		-- Для всех остальных команд требуем авторизацию
		if not isAuthorized then 
			print("⚠️ HandleTelegramCommand: User not authorized, chat ID: " .. chatId)
			return 
		end

	if text == "/start" then
		print("🚀 Processing /start command from chat " .. chatId)
		if TELEGRAM_BOT_TOKEN == "" then 
			print("❌ /start: Bot token is empty")
			return 
		end
		
		-- ОБНОВЛЯЕМ КЭШИРОВАННОЕ ЗОЛОТО ПЕРЕД ИСПОЛЬЗОВАНИЕМ
		print("💰 Getting raw gold amount...")
		local currentGold = GetRawGoldAmount()
		print("✅ GetRawGoldAmount completed. Current gold: " .. tostring(currentGold))
		
		local folderPath = "BoogaX"
		local lockFile = folderPath .. "/start_lock.json"
		local accountsFile = folderPath .. "/accounts.json"
		
		print("📁 Checking lock file...")
		-- ПРОВЕРКА БЛОКИРОВКИ СРАЗУ (до обновления данных!)
		local canRespond = false
		local currentTime = tick()
		print("   Current time: " .. tostring(currentTime))
		
		local lockCheckSuccess, lockCheckErr = pcall(function()
			if readfile then
				local content = readfile(lockFile)
				if content and content ~= "" then
					print("   Lock file exists, checking timestamp...")
					local lockData = HttpService:JSONDecode(content)
					local timeSince = currentTime - (lockData.timestamp or 0)
					print("   Time since lock: " .. tostring(timeSince) .. " seconds")
					if timeSince >= 5 then -- Блокировка на 5 секунд
						canRespond = true
						print("   ✅ Lock expired, can respond")
					else
						print("   ⏸️ Lock still active, cannot respond")
					end
				else
					canRespond = true -- Файла нет, можем отвечать
					print("   ✅ No lock file, can respond")
				end
			else
				canRespond = true
				print("   ⚠️ readfile not available, assuming can respond")
			end
		end)
		
		if not lockCheckSuccess then
			print("   ⚠️ Error checking lock: " .. tostring(lockCheckErr))
			canRespond = true -- В случае ошибки разрешаем отвечать
		end
		
		print("   Final canRespond: " .. tostring(canRespond))
		
		-- Если не можем отвечать, обновляем данные и выходим
		if not canRespond then
			print("⏸️ Cannot respond (locked), updating data and exiting...")
			-- Быстро обновляем только свои данные
			local accounts = {}
			pcall(function()
				if readfile then
					local content = readfile(accountsFile)
					if content and content ~= "" then
						accounts = HttpService:JSONDecode(content) or {}
					end
				end
			end)
			
			accounts[PLAYER_NAME] = {
				player_name = PLAYER_NAME,
				chat_id = TELEGRAM_CHAT_ID,
				raw_gold = currentGold,
				last_update = os.time(),
			}
			
			pcall(function()
				if writefile then
					writefile(accountsFile, HttpService:JSONEncode(accounts))
				end
			end)
			print("✅ Data updated, exiting (another account is responding)")
			return -- Другой аккаунт уже отвечает
		end
		
		print("✅ Can respond, proceeding...")
		
		-- СОЗДАЁМ БЛОКИРОВКУ СРАЗУ
		print("🔒 Creating lock file...")
		pcall(function()
			if writefile then
				writefile(lockFile, HttpService:JSONEncode({timestamp = currentTime, player = PLAYER_NAME}))
				print("   ✅ Lock file created")
			else
				print("   ⚠️ writefile not available")
			end
		end)
		
		-- Обновляем свои данные
		print("💾 Updating account data...")
		local accounts = {}
		pcall(function()
			if readfile then
				local content = readfile(accountsFile)
				if content and content ~= "" then
					accounts = HttpService:JSONDecode(content) or {}
					print("   ✅ Loaded existing accounts file")
				else
					print("   ℹ️ No existing accounts file")
				end
			end
		end)
		
		accounts[PLAYER_NAME] = {
			player_name = PLAYER_NAME,
			chat_id = TELEGRAM_CHAT_ID,
			raw_gold = currentGold,
			last_update = os.time(),
		}
		print("   Updated account: " .. PLAYER_NAME .. " with gold: " .. tostring(currentGold))
		
		pcall(function()
			if writefile then
				writefile(accountsFile, HttpService:JSONEncode(accounts))
				print("   ✅ Accounts file saved")
			end
		end)
		
		-- Маленькая задержка для других аккаунтов
		print("⏳ Waiting 0.2 seconds for other accounts...")
		task.wait(0.2)
		print("✅ Wait completed, getting all accounts...")
		
		-- Получаем всех аккаунтов с обработкой ошибок
		print("📋 Getting all accounts...")
		local allAccounts = {}
		local success, err = pcall(function()
			allAccounts = GetAllAccounts()
		end)
		
		if not success then
			print("❌ Error getting accounts: " .. tostring(err))
			allAccounts = {}
		else
			print("✅ Got accounts, processing...")
		end
		
		-- ДИАГНОСТИКА
		print("=== /start command debug ===")
		print("Current player gold: " .. currentGold)
		
		-- Правильно считаем количество аккаунтов (для таблиц с строковыми ключами)
		local accountCount = 0
		for _ in pairs(allAccounts) do
			accountCount = accountCount + 1
		end
		print("Total accounts found: " .. tostring(accountCount))
		
		for playerName, accountData in pairs(allAccounts) do
			print("  Player: " .. tostring(playerName) .. " | Gold: " .. tostring(accountData.raw_gold or 0))
		end
		
		-- КОМПАКТНЫЙ ФОРМАТ
		local msg = "🎮 *BoogaX Dashboard*\n\n"
		
		local totalAccounts = 0
		local totalGold = 0
		
		for playerName, accountData in pairs(allAccounts) do
			totalAccounts = totalAccounts + 1
			totalGold = totalGold + (tonumber(accountData.raw_gold) or 0)
		end
		
		msg = msg .. "📊 Аккаунтов: " .. totalAccounts .. " | 💰 Золота: " .. totalGold .. "\n\n"
		
		-- Сортируем аккаунты по золоту (больше → меньше)
		local sortedAccounts = {}
		for playerName, accountData in pairs(allAccounts) do
			table.insert(sortedAccounts, {name = tostring(playerName), data = accountData})
		end
		table.sort(sortedAccounts, function(a, b)
			return (tonumber(a.data.raw_gold) or 0) > (tonumber(b.data.raw_gold) or 0)
		end)
		
		-- Выводим аккаунты компактно
		for _, account in ipairs(sortedAccounts) do
			local timeSince = os.time() - (tonumber(account.data.last_update) or 0)
			local status = timeSince < 60 and "🟢" or (timeSince < 300 and "🟡" or "🔴")
			local gold = tonumber(account.data.raw_gold) or 0
			
			msg = msg .. status .. " *" .. (account.data.player_name or account.name or "Unknown") .. "*\n"
			msg = msg .. "   💰 " .. gold .. " gold\n"
		end
		
		msg = msg .. "\n⏰ Время работы: " .. FormatUptime()
		
		-- ДОПОЛНИТЕЛЬНАЯ ДИАГНОСТИКА В СООБЩЕНИИ
		print("=== Sending Telegram message ===")
		print("Message length: " .. string.len(msg))
		print("Message preview:\n" .. msg)
		
		-- Отправляем с обработкой ошибок
		print("📤 Preparing to send response to chat " .. chatId)
		print("   Bot token exists: " .. tostring(TELEGRAM_BOT_TOKEN ~= ""))
		print("   Message length: " .. string.len(msg))
		
		-- Пробуем отправить без Markdown сначала (на случай проблем с форматированием)
		local sendSuccess, sendErr = pcall(function()
			-- Убираем Markdown форматирование для надежности
			local plainMsg = msg:gsub("%*", ""):gsub("_", "") -- Убираем * и _
			local url = "https://api.telegram.org/bot" .. TELEGRAM_BOT_TOKEN .. "/sendMessage?chat_id=" .. UrlEncode(chatId) .. "&text=" .. UrlEncode(plainMsg)
			
			print("   URL length: " .. string.len(url))
			print("   Making HTTP request...")
			
			local success, response = MakeHttpRequest(url)
			
			print("   HTTP request completed. Success: " .. tostring(success))
			
			if success and response then
				print("📡 Telegram API response: " .. string.sub(tostring(response), 1, 300))
				if response:find('"ok":true') then
					print("✅ Message sent successfully to chat " .. chatId)
				else
					print("❌ Telegram API returned error in response")
					-- Пробуем найти описание ошибки
					local errorDesc = response:match('"description":"([^"]+)"')
					if errorDesc then
						print("   Error description: " .. errorDesc)
					end
					print("Full response: " .. tostring(response))
				end
			else
				print("❌ Failed to send message - HTTP request failed")
				print("   Success: " .. tostring(success))
				print("   Response type: " .. type(response))
				if response then
					print("   Response: " .. tostring(response))
				end
			end
		end)
		
		if not sendSuccess then
			print("❌ Error sending message (pcall failed): " .. tostring(sendErr))
			-- Пробуем отправить простейшее сообщение для теста
			pcall(function()
				local testUrl = "https://api.telegram.org/bot" .. TELEGRAM_BOT_TOKEN .. "/sendMessage?chat_id=" .. UrlEncode(chatId) .. "&text=Test"
				local testSuccess, testResponse = MakeHttpRequest(testUrl)
				print("   Test message send result: " .. tostring(testSuccess))
			end)
		end
	end
end
	
	local function StartTelegramBot()
		print("🔍 StartTelegramBot called")
		print("   TELEGRAM_ENABLED: " .. tostring(TELEGRAM_ENABLED))
		print("   TELEGRAM_BOT_TOKEN: " .. (TELEGRAM_BOT_TOKEN ~= "" and string.sub(TELEGRAM_BOT_TOKEN, 1, 10) .. "..." or "EMPTY"))
		
		if not TELEGRAM_ENABLED then 
			print("❌ StartTelegramBot: Bot not enabled, exiting")
			return 
		end
		
		if TELEGRAM_BOT_TOKEN == "" then
			print("❌ StartTelegramBot: Bot token is empty, exiting")
			return
		end
		
		-- Предотвращаем множественные запуски
		if BOT_LOOP_RUNNING then
			print("⚠️ StartTelegramBot: Bot loop already running, skipping...")
			return
		end
		
		BOT_LOOP_RUNNING = true
		print("✅ StartTelegramBot: Starting bot loop...")
		
		-- Сбрасываем LAST_UPDATE_ID при первом запуске, чтобы получить все непрочитанные сообщения
		-- Но сначала получаем последний update_id, чтобы не обрабатывать старые сообщения
		task.spawn(function()
			print("🔄 Getting last update ID to skip old messages...")
			local testUrl = "https://api.telegram.org/bot" .. TELEGRAM_BOT_TOKEN .. "/getUpdates?offset=-1&limit=1"
			local success, response = MakeHttpRequest(testUrl)
			if success and response then
				local decodeSuccess, data = pcall(function()
					return HttpService:JSONDecode(response)
				end)
				if decodeSuccess and data and data.ok and data.result and #data.result > 0 then
					local lastUpdateId = data.result[1].update_id
					LAST_UPDATE_ID = lastUpdateId
					print("✅ Last update ID: " .. LAST_UPDATE_ID .. " (old messages will be skipped)")
				else
					print("ℹ️ No previous updates found, starting from 0")
					LAST_UPDATE_ID = 0
				end
			else
				print("⚠️ Could not get last update ID, starting from 0")
				LAST_UPDATE_ID = 0
			end
		end)
		
		-- Цикл проверки команд от Telegram
		task.spawn(function()
			-- Небольшая задержка, чтобы дать время получить последний update_id
			task.wait(1)
			print("🤖 StartTelegramBot: Bot loop started (LAST_UPDATE_ID: " .. LAST_UPDATE_ID .. ")")
			local loopCount = 0
			local conflictCount = 0
			while TELEGRAM_ENABLED do
				loopCount = loopCount + 1
				
				local updates = GetTelegramUpdates()
				
				-- Если получили обновления, сбрасываем счетчик конфликтов
				if updates then
					conflictCount = 0
					if #updates > 0 then
						print("📬 Processing " .. #updates .. " update(s)")
						for _, update in ipairs(updates) do
							if update.update_id then
								LAST_UPDATE_ID = math.max(LAST_UPDATE_ID, update.update_id)
								print("   Update ID: " .. update.update_id .. " (LAST_UPDATE_ID now: " .. LAST_UPDATE_ID .. ")")
							end
							if update.message then
								pcall(function()
									HandleTelegramCommand(update.message)
								end)
							end
						end
					end
				else
					-- Если updates = nil, возможно конфликт или другая ошибка
					-- Увеличиваем счетчик и делаем паузу, если слишком много конфликтов подряд
					conflictCount = conflictCount + 1
					if conflictCount >= 5 then
						-- Если 5 раз подряд конфликт, увеличиваем интервал проверки
						task.wait(5) -- Ждем 5 секунд вместо 2
						conflictCount = 0 -- Сбрасываем счетчик после паузы
					end
				end
				
				-- Логируем каждые 30 итераций (каждые 60 секунд при нормальной работе)
				if loopCount % 30 == 0 then
					print("🔄 Bot loop running... (iteration " .. loopCount .. ", LAST_UPDATE_ID: " .. LAST_UPDATE_ID .. ")")
				end
				
				task.wait(2) -- Check every 2 seconds (или 5, если был конфликт)
			end
			BOT_LOOP_RUNNING = false
			print("🛑 StartTelegramBot: Bot loop stopped")
		end)
		
	-- Автоматическое обновление информации об аккаунте
	task.spawn(function()
		while TELEGRAM_ENABLED do
			if TELEGRAM_CHAT_ID ~= "" then
				UpdateAccountInfo()
			end
			
			-- Синхронизируем список Chat ID из файла
			local folderPath = "BoogaX"
			local filePath = folderPath .. "/telegram.json"
			pcall(function()
				if readfile then
					local content = readfile(filePath)
					if content and content ~= "" then
						local data = HttpService:JSONDecode(content)
						TELEGRAM_CHAT_IDS = data.chat_ids or {}
					end
				end
			end)
			
			task.wait(30) -- Обновляем каждые 30 секунд
		end
	end)
	end

-- Создание GUI с Fluent UI
local Fluent = loadstring(game:HttpGet("https://github.com/1dontgiveaf/Fluent/releases/latest/download/main.lua"))()

local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/1dontgiveaf/Fluent/main/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/1dontgiveaf/Fluent/main/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "BoogaX Simple",
    SubTitle = "by Snail",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "" }),
    Movement = Window:AddTab({ Title = "Movement", Icon = "running" }),
    Visual = Window:AddTab({ Title = "Visual", Icon = "eye" }),
    Waypoints = Window:AddTab({ Title = "Waypoints", Icon = "map-pin" }),
    AutoFarm = Window:AddTab({ Title = "Auto Farm", Icon = "trending-up" }),
    Coordinates = Window:AddTab({ Title = "Coordinates", Icon = "map" }),
    Misc = Window:AddTab({ Title = "Misc", Icon = "more-horizontal" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Options = Fluent.Options

-- Hand the library over to our managers
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("BoogaXScriptHub")
SaveManager:SetFolder("BoogaXScriptHub/specific-game")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)
Window:SelectTab(1)

	-- Load Telegram settings early
	LoadTelegramSettings()
	
	-- Start Telegram bot if already enabled (нужен только токен, Chat ID не обязателен для обработки команд)
	if TELEGRAM_ENABLED and TELEGRAM_BOT_TOKEN ~= "" then
		print("🚀 Starting Telegram bot on load...")
		StartTelegramBot()
	else
		if not TELEGRAM_ENABLED then
			print("⚠️ Telegram bot not enabled")
		elseif TELEGRAM_BOT_TOKEN == "" then
			print("⚠️ Telegram bot token is empty")
		end
	end

-- Функции создания элементов (адаптированы для Fluent UI с поддержкой вкладок)
local function CreateToggle(name, default, callback, tab)
    tab = tab or Tabs.Main -- По умолчанию в Main tab
    local toggleId = name:gsub("[^%w]", "") -- Убираем спецсимволы для ID
    local Toggle = tab:AddToggle(toggleId, {
        Title = name,
        Default = default
    })
    
    Toggle:OnChanged(function()
        callback(Options[toggleId].Value)
    end)
    
    return Toggle
end

local function CreateSlider(name, min, max, default, callback, tab)
    tab = tab or Tabs.Main -- По умолчанию в Main tab
    local sliderId = name:gsub("[^%w]", "") -- Убираем спецсимволы для ID
    local Slider = tab:AddSlider(sliderId, {
        Title = name,
        Default = default,
        Min = min,
        Max = max,
        Rounding = 1,
        Callback = callback
    })
    
    return Slider
end

local function CreateButton(name, callback, tab)
    tab = tab or Tabs.Main -- По умолчанию в Main tab
    local button = tab:AddButton({
        Title = name,
        Description = "",
        Callback = callback
    })
    
    return button
end

local function CreateTextBox(name, placeholder, callback)
    local inputId = name:gsub("[^%w]", "") -- Убираем спецсимволы для ID
    local Input = Tabs.Main:AddInput(inputId, {
        Title = name,
        Default = "",
        Placeholder = placeholder,
        Numeric = false,
        Finished = false,
        Callback = callback
    })
    
    return Input
end

	local function CreateInput(name, placeholder, defaultValue, onChanged)
		local inputId = name:gsub("[^%w]", "") -- Убираем спецсимволы для ID
		local Input = Tabs.Main:AddInput(inputId, {
			Title = name,
			Default = tostring(defaultValue or ""),
			Placeholder = placeholder,
			Numeric = false,
			Finished = true, -- Вызывается при нажатии Enter
			Callback = onChanged
		})
		
		return Input
	end

-- ============================================
-- ФУНКЦИОНАЛ
-- ============================================

-- Walk Speed (Максимально агрессивная система)
local SpeedConnection

-- МЕТОД 1: Hook метаметод для перехвата попыток изменения WalkSpeed (если поддерживается)
pcall(function()
    if hookmetamethod then
        local oldIndex
        oldIndex = hookmetamethod(game, "__newindex", function(self, property, value)
            if self:IsA("Humanoid") and property == "WalkSpeed" then
                if LocalPlayer.Character and self == LocalPlayer.Character:FindFirstChild("Humanoid") then
                    -- Заменяем любую попытку установки WalkSpeed на наше значение
                    value = CurrentWalkSpeed
                end
            end
            return oldIndex(self, property, value)
        end)
    end
end)

-- МЕТОД 2: Устанавливаем начальную скорость
task.spawn(function()
    task.wait(1)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = CurrentWalkSpeed
    end
end)

-- МЕТОД 3: RenderStepped для постоянного применения (срабатывает ДО рендера каждого кадра)
SpeedConnection = RunService.RenderStepped:Connect(function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        local humanoid = LocalPlayer.Character.Humanoid
        -- Устанавливаем скорость каждый кадр БЕЗ pcall для быстроты
        humanoid.WalkSpeed = CurrentWalkSpeed
    end
end)

-- Автоматическое обновление при респавне
LocalPlayer.CharacterAdded:Connect(function(character)
    task.spawn(function()
        task.wait(0.5)
        local humanoid = character:WaitForChild("Humanoid", 5)
        if humanoid then
            -- Применяем скорость несколько раз с задержкой для надежности
            for i = 1, 5 do
                humanoid.WalkSpeed = CurrentWalkSpeed
                task.wait(0.3)
            end
        end
    end)
end)

-- ============================================
-- NOCLIP SYSTEM
-- ============================================

-- Функция включения noclip
local function EnableNoclip()
	NOCLIP_ENABLED = true
	
	-- Отключаем существующее соединение если есть
	if NoclipConnection then
		NoclipConnection:Disconnect()
		NoclipConnection = nil
	end
	
	-- Создаём функцию noclip loop
	local function NoclipLoop()
		if NOCLIP_ENABLED and LocalPlayer.Character then
			pcall(function()
				for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
					if part:IsA("BasePart") and part.CanCollide then
						part.CanCollide = false
					end
				end
			end)
		end
	end
	
	-- Подключаемся к Stepped событию
	NoclipConnection = RunService.Stepped:Connect(NoclipLoop)
	
	-- Отправляем уведомление
	game:GetService("StarterGui"):SetCore("SendNotification", {
		Title = "Noclip",
		Text = "Noclip Enabled",
		Duration = 2
	})
end

-- Функция отключения noclip
local function DisableNoclip()
	NOCLIP_ENABLED = false
	
	-- Отключаем соединение
	if NoclipConnection then
		NoclipConnection:Disconnect()
		NoclipConnection = nil
	end
	
	-- Восстанавливаем коллизии на частях персонажа
	if LocalPlayer.Character then
		pcall(function()
			for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CanCollide = true
				end
			end
		end)
	end
	
	-- Отправляем уведомление
	game:GetService("StarterGui"):SetCore("SendNotification", {
		Title = "Noclip",
		Text = "Noclip Disabled",
		Duration = 2
	})
end

-- Функция переключения noclip
local function ToggleNoclip(state)
	if state then
		EnableNoclip()
	else
		DisableNoclip()
	end
end

-- Обработчик респавна персонажа для noclip
LocalPlayer.CharacterAdded:Connect(function(character)
	if NOCLIP_ENABLED then
		task.spawn(function()
			-- Ждём загрузки всех частей персонажа
			task.wait(0.5)
			-- Переприменяем noclip
			EnableNoclip()
		end)
	end
end)

-- ============================================
-- MOVEMENT TAB
-- ============================================
CreateSlider("Walk Speed", BASE_WALK_SPEED, MAX_WALK_SPEED, BASE_WALK_SPEED, function(value)
    CurrentWalkSpeed = value
    
    -- Сразу применяем скорость
    pcall(function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = CurrentWalkSpeed
        end
    end)
end, Tabs.Movement)

-- Mountain Climber (Оптимизировано)
CreateToggle("Mountain Climber", false, function(state)
	MOUNTAIN_CLIMBER_ENABLED = state
	if MountainClimberConnection then
		MountainClimberConnection:Disconnect()
		MountainClimberConnection = nil
	end
	if state then
		task.spawn(function()
			local char = game.Players.LocalPlayer.Character or game.Players.LocalPlayer.CharacterAdded:Wait()
			char:WaitForChild("Humanoid").MaxSlopeAngle = 90
		end)
	else
		task.spawn(function()
			local char = game.Players.LocalPlayer.Character
			if char and char:FindFirstChild("Humanoid") then
				char.Humanoid.MaxSlopeAngle = 45
			end
		end)
	end
end, Tabs.Movement)

-- Noclip Toggle
CreateToggle("Noclip", false, function(state)
	ToggleNoclip(state)
end, Tabs.Movement)

-- ============================================
-- VISUAL TAB
-- ============================================
-- ESP СИСТЕМА (ПЕРЕПИСАН С НУЛЯ)
-- ============================================

local function CreateESP(player)
    if player == LocalPlayer then return end
    if not ESP_ENABLED then return end
    
    local function UpdateESP()
        if not player.Character then return end
        
        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
        local head = player.Character:FindFirstChild("Head")
        if not hrp or not head then return end
        
        -- Удаляем старый ESP
        for _, v in pairs(player.Character:GetChildren()) do
            if v.Name == "ESPBox" or v.Name == "ESPText" then
                v:Destroy()
            end
        end
        
        -- Создаем БОКС
        local box = Instance.new("BoxHandleAdornment")
        box.Name = "ESPBox"
        box.Size = Vector3.new(4, 5, 1)
        box.Adornee = hrp
        box.AlwaysOnTop = true
        box.ZIndex = 5
        box.Transparency = 0.7
        box.Color3 = Color3.fromRGB(255, 0, 0)
        box.Parent = player.Character
        
        -- Создаем ТЕКСТ
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "ESPText"
        billboard.Adornee = head
        billboard.Size = UDim2.new(0, 200, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 2, 0)
        billboard.AlwaysOnTop = true
        billboard.Parent = player.Character
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = player.Name
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.TextSize = 16
        nameLabel.Font = Enum.Font.SourceSansBold
        nameLabel.TextStrokeTransparency = 0.5
        nameLabel.Parent = billboard
        
        local distLabel = Instance.new("TextLabel")
        distLabel.Name = "Distance"
        distLabel.Size = UDim2.new(1, 0, 0.5, 0)
        distLabel.Position = UDim2.new(0, 0, 0.5, 0)
        distLabel.BackgroundTransparency = 1
        distLabel.Text = "0m"
        distLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
        distLabel.TextSize = 14
        distLabel.Font = Enum.Font.SourceSans
        distLabel.TextStrokeTransparency = 0.5
        distLabel.Parent = billboard
        
        -- Обновление расстояния в цикле
        task.spawn(function()
            while ESP_ENABLED and box.Parent do
                task.wait(0.1)
                
                -- ИСПРАВЛЕНИЕ: проверяем что персонажи существуют
                if player and player.Character and LocalPlayer and LocalPlayer.Character then
                    local myHRP = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    local theirHRP = player.Character:FindFirstChild("HumanoidRootPart")
                    
                    if myHRP and theirHRP then
                        local dist = (myHRP.Position - theirHRP.Position).Magnitude
                        distLabel.Text = math.floor(dist) .. "m"
                        
                        -- Меняем цвет по расстоянию
                        if dist < 50 then
                            box.Color3 = Color3.fromRGB(255, 0, 0)
                        elseif dist < 150 then
                            box.Color3 = Color3.fromRGB(255, 255, 0)
                        else
                            box.Color3 = Color3.fromRGB(0, 255, 0)
                        end
                    end
                end
            end
        end)
    end
    
    -- Создаем ESP сейчас
    UpdateESP()
    
    -- Пересоздаем при респавне
    player.CharacterAdded:Connect(function()
        if ESP_ENABLED then
            task.wait(1)
            UpdateESP()
        end
    end)
end

local function RemoveESP(player)
    if player.Character then
        for _, v in pairs(player.Character:GetChildren()) do
            if v.Name == "ESPBox" or v.Name == "ESPText" then
                v:Destroy()
            end
        end
    end
end

local function RemoveAllESP()
    for _, player in pairs(Players:GetPlayers()) do
        RemoveESP(player)
    end
end

CreateToggle("ESP Players", false, function(state)
    ESP_ENABLED = state
    
    if state then
        -- Включаем ESP для всех игроков
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                CreateESP(player)
            end
        end
        
        -- Автоматически добавляем ESP новым игрокам
        ESPPlayersConnection = Players.PlayerAdded:Connect(function(player)
            if player ~= LocalPlayer then
                task.wait(1)
                CreateESP(player)
            end
        end)
    else
        -- Выключаем ESP
        if ESPPlayersConnection then
            ESPPlayersConnection:Disconnect()
            ESPPlayersConnection = nil
        end
        
        RemoveAllESP()
    end
end, Tabs.Visual)

-- Автоматическое удаление при выходе игрока
Players.PlayerRemoving:Connect(function(player)
    RemoveESP(player)
end)

-- ============================================
-- ESP Gold Node
-- ============================================
local GOLD_ESP_ENABLED = false
local GoldESPConnection = nil
local goldESPObjects = {}

local function CreateGoldESP(goldNode)
    if not goldNode or not goldNode.Parent then return end
    if not GOLD_ESP_ENABLED then return end
    
    -- Проверяем, не создан ли уже ESP для этого объекта
    if goldESPObjects[goldNode] then return end
    
    local primaryPart = goldNode:IsA("Model") and (goldNode.PrimaryPart or goldNode:FindFirstChildWhichIsA("BasePart")) or goldNode
    if not primaryPart then return end
    
    -- Создаем БОКС для золота
    local box = Instance.new("BoxHandleAdornment")
    box.Name = "GoldESPBox"
    box.Size = primaryPart.Size + Vector3.new(0.5, 0.5, 0.5)
    box.Adornee = primaryPart
    box.AlwaysOnTop = true
    box.ZIndex = 5
    box.Transparency = 0.6
    box.Color3 = Color3.fromRGB(255, 215, 0) -- Золотой цвет
    box.Parent = primaryPart
    
    -- Создаем ТЕКСТ над золотом
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "GoldESPText"
    billboard.Adornee = primaryPart
    billboard.Size = UDim2.new(0, 150, 0, 50)
    billboard.StudsOffset = Vector3.new(0, primaryPart.Size.Y / 2 + 2, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = primaryPart
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = "💰 Gold Ore"
    nameLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    nameLabel.TextSize = 14
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextStrokeTransparency = 0.3
    nameLabel.Parent = billboard
    
    local distLabel = Instance.new("TextLabel")
    distLabel.Name = "Distance"
    distLabel.Size = UDim2.new(1, 0, 0.5, 0)
    distLabel.Position = UDim2.new(0, 0, 0.5, 0)
    distLabel.BackgroundTransparency = 1
    distLabel.Text = "0m"
    distLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    distLabel.TextSize = 12
    distLabel.Font = Enum.Font.Gotham
    distLabel.TextStrokeTransparency = 0.3
    distLabel.Parent = billboard
    
    -- Сохраняем ссылки
    goldESPObjects[goldNode] = {box = box, billboard = billboard}
    
    -- Обновление расстояния в цикле
    task.spawn(function()
        while GOLD_ESP_ENABLED and box.Parent and goldNode.Parent do
            task.wait(0.2)
            
            if LocalPlayer and LocalPlayer.Character then
                local myHRP = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                
                if myHRP and primaryPart then
                    local dist = (myHRP.Position - primaryPart.Position).Magnitude
                    distLabel.Text = math.floor(dist) .. "m"
                    
                    -- Меняем цвет по расстоянию
                    if dist < 30 then
                        box.Color3 = Color3.fromRGB(255, 0, 0) -- Красный (очень близко)
                        nameLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
                    elseif dist < 80 then
                        box.Color3 = Color3.fromRGB(255, 215, 0) -- Золотой (средне)
                        nameLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
                    else
                        box.Color3 = Color3.fromRGB(0, 255, 0) -- Зеленый (далеко)
                        nameLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
                    end
                end
            end
        end
        
        -- Очистка при завершении
        if goldESPObjects[goldNode] then
            goldESPObjects[goldNode] = nil
        end
    end)
end

local function RemoveGoldESP(goldNode)
    if goldESPObjects[goldNode] then
        local espData = goldESPObjects[goldNode]
        if espData.box then pcall(function() espData.box:Destroy() end) end
        if espData.billboard then pcall(function() espData.billboard:Destroy() end) end
        goldESPObjects[goldNode] = nil
    end
end

local function RemoveAllGoldESP()
    for goldNode, espData in pairs(goldESPObjects) do
        if espData.box then pcall(function() espData.box:Destroy() end) end
        if espData.billboard then pcall(function() espData.billboard:Destroy() end) end
    end
    goldESPObjects = {}
end

local function UpdateGoldESP()
    if not GOLD_ESP_ENABLED then return end
    
    local resourcesFolder = workspace:FindFirstChild("Resources")
    if not resourcesFolder then return end
    
    -- Ищем все золотые ноды
    for _, resource in ipairs(resourcesFolder:GetChildren()) do
        if resource:IsA("Model") then
            local name = resource.Name:lower()
            -- Проверяем, является ли это золотом
            if name:match("[Gg]old") or name:match("[Oo]re") then
                CreateGoldESP(resource)
            end
        end
    end
end

CreateToggle("ESP Gold Node", false, function(state)
    GOLD_ESP_ENABLED = state
    
    if state then
        -- Включаем ESP для всех золотых нодов
        UpdateGoldESP()
        
        -- Автоматически обновляем ESP каждые 5 секунд
        GoldESPConnection = task.spawn(function()
            while GOLD_ESP_ENABLED do
                task.wait(5)
                UpdateGoldESP()
            end
        end)
        
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Gold ESP Enabled",
            Text = "Gold nodes are now highlighted!",
            Duration = 3
        })
    else
        -- Выключаем ESP
        if GoldESPConnection then
            task.cancel(GoldESPConnection)
            GoldESPConnection = nil
        end
        
        RemoveAllGoldESP()
        
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Gold ESP Disabled",
            Text = "Gold ESP turned off",
            Duration = 2
        })
    end
end, Tabs.Visual)

-- Night Vision
CreateToggle("Night Vision", false, function(state)
    NIGHT_VISION_ENABLED = state
    if state then
        Lighting.Ambient = Color3.new(1, 1, 1)
        Lighting.Brightness = 2
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
    else
        Lighting.Ambient = defaultLighting.Ambient
        Lighting.Brightness = defaultLighting.Brightness
        Lighting.OutdoorAmbient = defaultLighting.OutdoorAmbient
    end
end, Tabs.Visual)

-- Glow (Оптимизировано с автоматическим обновлением)
local function UpdateGlow()
    if not GLOW_ENABLED then return end
    local char = LocalPlayer.Character
    if char then
        if GlowHighlight then 
            GlowHighlight:Destroy() 
        end
        GlowHighlight = Instance.new("Highlight")
        GlowHighlight.FillColor = Color3.fromRGB(100, 100, 255)
        GlowHighlight.OutlineColor = Color3.fromRGB(100, 100, 255)
        GlowHighlight.FillTransparency = 0.5
        GlowHighlight.Adornee = char
        GlowHighlight.Parent = char
    end
end

CreateToggle("Character Glow", false, function(state)
    GLOW_ENABLED = state
    
    -- Отключаем предыдущее соединение
    if GlowCharacterConnection then
        GlowCharacterConnection:Disconnect()
        GlowCharacterConnection = nil
    end
    
    if state then
        UpdateGlow()
        
        -- Автоматическое обновление при спавне нового персонажа
        GlowCharacterConnection = LocalPlayer.CharacterAdded:Connect(function()
            task.wait(0.5)
            UpdateGlow()
        end)
    else
        if GlowHighlight then
            GlowHighlight:Destroy()
            GlowHighlight = nil
        end
    end
end, Tabs.Visual)

-- Hitboxes (Оптимизировано с автоматическим обновлением)
local function CreateHitbox(player)
    if not HITBOXES_ENABLED or player == LocalPlayer then return end
    if player.Character then
        local root = player.Character:WaitForChild("HumanoidRootPart", 5)
        if root then
            local existingHitbox = HITBOX_HOLDER:FindFirstChild("Hitbox_" .. player.Name)
            if existingHitbox then existingHitbox:Destroy() end
            
            local box = Instance.new("BoxHandleAdornment")
            box.Name = "Hitbox_" .. player.Name
            box.Adornee = root
            box.Size = Vector3.new(6, 8, 6)
            box.Transparency = 0.8
            box.Color3 = Color3.fromRGB(255, 200, 0)
            box.AlwaysOnTop = true
            box.Parent = HITBOX_HOLDER
        end
    end
end

local function RemoveHitbox(player)
    local hitbox = HITBOX_HOLDER:FindFirstChild("Hitbox_" .. player.Name)
    if hitbox then hitbox:Destroy() end
end

CreateToggle("Hitboxes", false, function(state)
    HITBOXES_ENABLED = state
    
    -- Отключаем предыдущее соединение
    if HitboxesPlayersConnection then
        HitboxesPlayersConnection:Disconnect()
        HitboxesPlayersConnection = nil
    end
    
    if state then
        -- Создаём Hitboxes для всех существующих игроков
        for _, player in ipairs(Players:GetPlayers()) do
            CreateHitbox(player)
        end
        
        -- Автоматическое обновление при добавлении игроков
        HitboxesPlayersConnection = Players.PlayerAdded:Connect(function(player)
            CreateHitbox(player)
            
            -- Обновление при спавне персонажа
            player.CharacterAdded:Connect(function()
                task.wait(0.5)
                CreateHitbox(player)
            end)
        end)
        
        -- Обработка существующих игроков
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                player.CharacterAdded:Connect(function()
                    task.wait(0.5)
                    CreateHitbox(player)
                end)
            end
        end
    else
        HITBOX_HOLDER:ClearAllChildren()
    end
end, Tabs.Visual)

-- Автоматическое удаление при выходе игрока
Players.PlayerRemoving:Connect(function(player)
    RemoveHitbox(player)
end)

-- Waypoints System
local WAYPOINTS_MOVING = false
local WAYPOINTS_FLYING = false
local FLY_WAYPOINTS_ENABLED = false
local AFK_WAYPOINTS_ENABLED = false
local FLY_SPEED = 30
local AFK_WAIT_TIME = 2 -- 2 секунды (оптимизировано)
local currentBodyVelocity = nil
local currentBodyGyro = nil

-- Функция создания BodyVelocity для полёта
local function CreateBodyVelocity(rootPart)
    if not rootPart then return nil end
    
    -- Удаляем старые объекты если существуют
    if currentBodyVelocity then
        pcall(function() currentBodyVelocity:Destroy() end)
        currentBodyVelocity = nil
    end
    if currentBodyGyro then
        pcall(function() currentBodyGyro:Destroy() end)
        currentBodyGyro = nil
    end
    
    -- Отключаем обычное управление персонажем
    local char = rootPart.Parent
    if char then
        local humanoid = char:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.PlatformStand = true
        end
    end
    
    -- Создаём BodyVelocity для движения (увеличенная сила)
    local bodyVel = Instance.new("BodyVelocity")
    bodyVel.MaxForce = Vector3.new(math.huge, math.huge, math.huge) -- Максимальная сила
    bodyVel.Velocity = Vector3.new(0, 0, 0)
    bodyVel.P = 1250 -- Увеличиваем мощность
    bodyVel.Parent = rootPart
    
    -- Создаём BodyGyro для стабильности
    local bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    bodyGyro.CFrame = rootPart.CFrame
    bodyGyro.P = 3000
    bodyGyro.Parent = rootPart
    
    currentBodyVelocity = bodyVel
    currentBodyGyro = bodyGyro
    return bodyVel
end

-- Функция удаления BodyVelocity
local function RemoveBodyVelocity()
    if currentBodyVelocity then
        pcall(function() 
            currentBodyVelocity:Destroy() 
        end)
        currentBodyVelocity = nil
    end
    if currentBodyGyro then
        pcall(function() 
            currentBodyGyro:Destroy() 
        end)
        currentBodyGyro = nil
    end
    
    -- Восстанавливаем обычное управление
    if LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.PlatformStand = false
        end
    end
end

-- Функция расчёта направления полёта
local function CalculateDirection(from, to)
    local direction = (to - from).Unit
    return direction * FLY_SPEED
end

local function CreateWaypoint()
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    local waypointNumber = #WAYPOINTS_HOLDER:GetChildren() + 1
    
    -- Создаём простую оптимизированную точку
    local part = Instance.new("Part")
    part.Position = LocalPlayer.Character.HumanoidRootPart.Position + Vector3.new(0, 0.5, 0)
    part.Anchored = true
    part.CanCollide = false
    part.Size = Vector3.new(1, 1, 1)
    part.BrickColor = BrickColor.new("Lime green")
    part.Material = Enum.Material.SmoothPlastic
    part.Transparency = 0.3
    part.Shape = Enum.PartType.Ball
    part:SetAttribute("Visited", false)
    part:SetAttribute("WaypointNumber", waypointNumber)
    part:SetAttribute("WaypointType", "walk") -- Тип: ходьба
    part.Parent = WAYPOINTS_HOLDER
    
    -- Простая табличка с номером (оптимизированная)
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 25, 0, 25)
    billboard.StudsOffset = Vector3.new(0, 1.2, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 100
    billboard.LightInfluence = 0
    billboard.Parent = part
    
    -- Простой фон
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
    bg.BackgroundTransparency = 0.2
    bg.BorderSizePixel = 0
    bg.Parent = billboard
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.3, 0)
    corner.Parent = bg
    
    -- Номер точки
    local numberLabel = Instance.new("TextLabel")
    numberLabel.Size = UDim2.new(1, 0, 1, 0)
    numberLabel.BackgroundTransparency = 1
    numberLabel.Text = tostring(waypointNumber)
    numberLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    numberLabel.TextStrokeTransparency = 0.5
    numberLabel.Font = Enum.Font.GothamBold
    numberLabel.TextSize = 12
    numberLabel.Parent = bg
    
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Waypoint Created",
        Text = "Point " .. waypointNumber .. " created!",
        Duration = 2
    })
end

-- Функция создания Fly Waypoint (жёлтого цвета)
local function CreateFlyWaypoint()
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    local waypointNumber = #WAYPOINTS_HOLDER:GetChildren() + 1
    
    -- Создаём жёлтую точку для полёта
    local part = Instance.new("Part")
    part.Position = LocalPlayer.Character.HumanoidRootPart.Position + Vector3.new(0, 0.5, 0)
    part.Anchored = true
    part.CanCollide = false
    part.Size = Vector3.new(1, 1, 1)
    part.BrickColor = BrickColor.new("New Yeller") -- Жёлтый цвет
    part.Material = Enum.Material.SmoothPlastic
    part.Transparency = 0.3
    part.Shape = Enum.PartType.Ball
    part:SetAttribute("Visited", false)
    part:SetAttribute("WaypointNumber", waypointNumber)
    part:SetAttribute("WaypointType", "fly") -- Тип: полёт
    part.Parent = WAYPOINTS_HOLDER
    
    -- Простая табличка с номером
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 25, 0, 25)
    billboard.StudsOffset = Vector3.new(0, 1.2, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 100
    billboard.LightInfluence = 0
    billboard.Parent = part
    
    -- Жёлтый фон
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(255, 200, 0) -- Жёлтый
    bg.BackgroundTransparency = 0.2
    bg.BorderSizePixel = 0
    bg.Parent = billboard
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.3, 0)
    corner.Parent = bg
    
    -- Номер точки
    local numberLabel = Instance.new("TextLabel")
    numberLabel.Size = UDim2.new(1, 0, 1, 0)
    numberLabel.BackgroundTransparency = 1
    numberLabel.Text = tostring(waypointNumber)
    numberLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    numberLabel.TextStrokeTransparency = 0.5
    numberLabel.Font = Enum.Font.GothamBold
    numberLabel.TextSize = 12
    numberLabel.Parent = bg
    
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Fly Waypoint Created",
        Text = "Point " .. waypointNumber .. " (Fly) created!",
        Duration = 2
    })
end

-- Функция создания AFK Waypoint (оранжевого цвета) - УЛУЧШЕННАЯ
local function CreateAfkWaypoint()
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    local waypointNumber = #WAYPOINTS_HOLDER:GetChildren() + 1
    
    -- Создаём оранжевую точку для AFK (улучшенная версия)
    local part = Instance.new("Part")
    part.Position = LocalPlayer.Character.HumanoidRootPart.Position + Vector3.new(0, 0.5, 0)
    part.Anchored = true
    part.CanCollide = false
    part.Size = Vector3.new(1.2, 1.2, 1.2) -- Немного больше для выделения
    part.BrickColor = BrickColor.new("Deep orange") -- Оранжевый цвет
    part.Material = Enum.Material.Neon -- Светящийся материал
    part.Transparency = 0.2 -- Более видимый
    part.Shape = Enum.PartType.Ball
    part:SetAttribute("Visited", false)
    part:SetAttribute("WaypointNumber", waypointNumber)
    part:SetAttribute("WaypointType", "afk") -- Тип: AFK
    part.Parent = WAYPOINTS_HOLDER
    
    -- Добавляем пульсирующий эффект
    task.spawn(function()
        local originalSize = part.Size
        local originalTransparency = part.Transparency
        while part and part.Parent do
            for i = 1, 10 do
                if not part or not part.Parent then break end
                local scale = 1 + (math.sin(i / 10 * math.pi * 2) * 0.1)
                part.Size = originalSize * scale
                part.Transparency = originalTransparency + (math.sin(i / 10 * math.pi * 2) * 0.1)
                task.wait(0.1)
            end
        end
    end)
    
    -- Улучшенная табличка с номером и иконкой
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 35, 0, 35) -- Больше размер
    billboard.StudsOffset = Vector3.new(0, 1.5, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 150
    billboard.LightInfluence = 0
    billboard.Parent = part
    
    -- Оранжевый фон с тенью
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(255, 140, 0) -- Оранжевый
    bg.BackgroundTransparency = 0.1
    bg.BorderSizePixel = 2
    bg.BorderColor3 = Color3.fromRGB(200, 100, 0)
    bg.Parent = billboard
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.3, 0)
    corner.Parent = bg
    
    -- Номер точки
    local numberLabel = Instance.new("TextLabel")
    numberLabel.Size = UDim2.new(1, 0, 0.6, 0)
    numberLabel.Position = UDim2.new(0, 0, 0, 0)
    numberLabel.BackgroundTransparency = 1
    numberLabel.Text = tostring(waypointNumber)
    numberLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    numberLabel.TextStrokeTransparency = 0.3
    numberLabel.Font = Enum.Font.GothamBold
    numberLabel.TextSize = 14
    numberLabel.Parent = bg
    
    -- Добавляем иконку AFK (⏸️)
    local afkLabel = Instance.new("TextLabel")
    afkLabel.Size = UDim2.new(1, 0, 0.4, 0)
    afkLabel.Position = UDim2.new(0, 0, 0.6, 0)
    afkLabel.BackgroundTransparency = 1
    afkLabel.Text = "⏸️"
    afkLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    afkLabel.TextStrokeTransparency = 0.3
    afkLabel.Font = Enum.Font.GothamBold
    afkLabel.TextSize = 10
    afkLabel.Parent = bg
    
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "AFK Waypoint Created",
        Text = "Point " .. waypointNumber .. " (AFK 2s) created!",
        Duration = 2
    })
end

-- ============================================
-- WAYPOINTS TAB
-- ============================================
CreateToggle("Waypoints (Press E)", false, function(state)
    WAYPOINTS_ENABLED = state
    
    -- Отключаем предыдущее соединение
    if WaypointsInputConnection then
        WaypointsInputConnection:Disconnect()
        WaypointsInputConnection = nil
    end
    
    if state then
        -- Оптимизация: один connection вместо создания нового при каждом включении
        WaypointsInputConnection = UserInputService.InputBegan:Connect(function(input, gp)
            if not gp and WAYPOINTS_ENABLED and input.KeyCode == Enum.KeyCode.E then
                CreateWaypoint()
            end
        end)
    end
end, Tabs.Waypoints)

CreateToggle("Fly Waypoints (Press R)", false, function(state)
    FLY_WAYPOINTS_ENABLED = state
    
    -- Отключаем предыдущее соединение
    if FlyWaypointsInputConnection then
        FlyWaypointsInputConnection:Disconnect()
        FlyWaypointsInputConnection = nil
    end
    
    if state then
        -- Создаём connection для клавиши R
        FlyWaypointsInputConnection = UserInputService.InputBegan:Connect(function(input, gp)
            if not gp and FLY_WAYPOINTS_ENABLED and input.KeyCode == Enum.KeyCode.R then
                CreateFlyWaypoint()
            end
        end)
    end
end, Tabs.Waypoints)

CreateToggle("AFK Waypoints 2s (Press G)", false, function(state)
    AFK_WAYPOINTS_ENABLED = state
    
    -- Отключаем предыдущее соединение
    if AfkWaypointsInputConnection then
        AfkWaypointsInputConnection:Disconnect()
        AfkWaypointsInputConnection = nil
    end
    
    if state then
        -- Создаём connection для клавиши G
        AfkWaypointsInputConnection = UserInputService.InputBegan:Connect(function(input, gp)
            if not gp and AFK_WAYPOINTS_ENABLED and input.KeyCode == Enum.KeyCode.G then
                CreateAfkWaypoint()
            end
        end)
        
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "AFK Waypoints Enabled",
            Text = "Press G to create AFK points (2s wait)",
            Duration = 3
        })
    end
end, Tabs.Waypoints)

CreateButton("Start Waypoints Movement", function()
    if #WAYPOINTS_HOLDER:GetChildren() == 0 then
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "BoogaX",
            Text = "No waypoints! Press E or R to create.",
            Duration = 3
        })
        return
    end
    
    WAYPOINTS_MOVING = true
    
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "BoogaX",
        Text = "Moving to waypoints!",
        Duration = 3
    })
    
    task.spawn(function()
        local currentIndex = 1
        local lastMoveTime = tick()
        
        -- Оптимизация: кэшируем отсортированный список waypoints
        local cachedWaypoints = {}
        local lastCacheUpdate = 0
        
        while WAYPOINTS_MOVING and (WAYPOINTS_ENABLED or FLY_WAYPOINTS_ENABLED or AFK_WAYPOINTS_ENABLED) do
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("Humanoid") and char:FindFirstChild("HumanoidRootPart") then
                local humanoid = char.Humanoid
                local rootPart = char.HumanoidRootPart
                
                -- Обновляем кэш только при изменении количества waypoints
                local currentWaypointCount = #WAYPOINTS_HOLDER:GetChildren()
                if currentWaypointCount ~= #cachedWaypoints or tick() - lastCacheUpdate > 5 then
                    cachedWaypoints = WAYPOINTS_HOLDER:GetChildren()
                    table.sort(cachedWaypoints, function(a, b)
                        return (a:GetAttribute("WaypointNumber") or 0) < (b:GetAttribute("WaypointNumber") or 0)
                    end)
                    lastCacheUpdate = tick()
                end
                
                local waypoints = cachedWaypoints
                
                if #waypoints > 0 then
                    local currentWaypoint = nil
                    for i = currentIndex, #waypoints do
                        local waypoint = waypoints[i]
                        if not waypoint:GetAttribute("Visited") then
                            currentWaypoint = waypoint
                            currentIndex = i
                            break
                        end
                    end
                    
                    -- Если все посещены, начинаем заново
                    if not currentWaypoint then
                        for _, waypoint in ipairs(waypoints) do
                            waypoint:SetAttribute("Visited", false)
                            -- Восстанавливаем оригинальный цвет в зависимости от типа или наличия WaitTime
                            local wpType = waypoint:GetAttribute("WaypointType") or "walk"
                            local hasWaitTime = waypoint:GetAttribute("WaitTime") and waypoint:GetAttribute("WaitTime") > 0
                            
                            if hasWaitTime then
                                waypoint.BrickColor = BrickColor.new("Bright blue")
                            elseif wpType == "fly" then
                                waypoint.BrickColor = BrickColor.new("New Yeller")
                            elseif wpType == "afk" then
                                waypoint.BrickColor = BrickColor.new("Deep orange")
                            else
                                waypoint.BrickColor = BrickColor.new("Lime green")
                            end
                            
                            local billboard = waypoint:FindFirstChildOfClass("BillboardGui")
                            if billboard then
                                local holoBg = billboard:FindFirstChildOfClass("Frame")
                                if holoBg and hasWaitTime then
                                    holoBg.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
                                elseif holoBg and wpType == "fly" then
                                    holoBg.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
                                elseif holoBg and wpType == "afk" then
                                    holoBg.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
                                elseif holoBg then
                                    holoBg.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
                                end
                            end
                        end
                        currentIndex = 1
                        currentWaypoint = waypoints[1]
                    end
                    
                    if currentWaypoint then
                        local distance = (rootPart.Position - currentWaypoint.Position).Magnitude
                        local waypointType = currentWaypoint:GetAttribute("WaypointType") or "walk"
                        
                        -- Определяем метод движения в зависимости от типа точки
                        if waypointType == "fly" or waypointType == "afk" then
                            -- Полёт к точке (для fly и afk waypoints)
                            local bodyVel = CreateBodyVelocity(rootPart)
                            if bodyVel then
                                local velocity = CalculateDirection(rootPart.Position, currentWaypoint.Position)
                                bodyVel.Velocity = velocity
                            end
                        else
                            -- Обычное движение к точке (только для walk waypoints)
                            RemoveBodyVelocity() -- Убираем BodyVelocity если был
                            if tick() - lastMoveTime > 0.5 or humanoid.MoveDirection.Magnitude < 0.1 then
                                humanoid:MoveTo(currentWaypoint.Position)
                                lastMoveTime = tick()
                            end
                        end
                        
                        if distance < 3 then
                            -- Помечаем как посещённую
                            currentWaypoint:SetAttribute("Visited", true)
                            currentWaypoint.BrickColor = BrickColor.new("Really red")
                            
                            local billboard = currentWaypoint:FindFirstChildOfClass("BillboardGui")
                            if billboard then
                                local holoBg = billboard:FindFirstChildOfClass("Frame")
                                if holoBg then
                                    holoBg.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
                                end
                            end
                            
                            -- Проверяем наличие WaitTime атрибута
                            local waitTime = currentWaypoint:GetAttribute("WaitTime")
                            if waitTime and waitTime > 0 then
                                RemoveBodyVelocity() -- Останавливаем движение
                                game:GetService("StarterGui"):SetCore("SendNotification", {
                                    Title = "BoogaX",
                                    Text = "Waiting " .. waitTime .. " seconds...",
                                    Duration = 3
                                })
                                
                                -- Ждём с обратным отсчётом
                                for countdown = waitTime, 1, -1 do
                                    if not WAYPOINTS_MOVING then break end
                                    print("⏱️ Waiting at waypoint " .. (currentWaypoint:GetAttribute("WaypointNumber") or "?") .. ": " .. countdown .. "s remaining")
                                    task.wait(1)
                                end
                                
                                game:GetService("StarterGui"):SetCore("SendNotification", {
                                    Title = "BoogaX",
                                    Text = "Wait complete! Moving on...",
                                    Duration = 2
                                })
                            -- Если это AFK точка, ждём 3 секунды (улучшено)
                            elseif waypointType == "afk" then
                                RemoveBodyVelocity() -- Останавливаем движение
                                
                                -- Останавливаем персонажа полностью
                                if humanoid then
                                    humanoid:MoveTo(rootPart.Position)
                                end
                                
                                game:GetService("StarterGui"):SetCore("SendNotification", {
                                    Title = "BoogaX",
                                    Text = "⏸️ AFK for 2 seconds...",
                                    Duration = 3
                                })
                                
                                -- Ждём с обратным отсчётом (улучшенная версия)
                                for countdown = AFK_WAIT_TIME, 1, -1 do
                                    if not WAYPOINTS_MOVING then break end
                                    print("⏱️ AFK at waypoint " .. (currentWaypoint:GetAttribute("WaypointNumber") or "?") .. ": " .. countdown .. "s remaining")
                                    
                                    -- Удерживаем персонажа на месте во время ожидания
                                    if humanoid and rootPart then
                                        humanoid:MoveTo(rootPart.Position)
                                    end
                                    
                                    task.wait(1)
                                end
                                
                                game:GetService("StarterGui"):SetCore("SendNotification", {
                                    Title = "BoogaX",
                                    Text = "✅ AFK complete! Moving on...",
                                    Duration = 2
                                })
                            end
                            
                            currentIndex = currentIndex + 1
                        end
                    end
                end
            end
            task.wait(0.05)
        end
        
        -- Очистка при выходе из цикла
        RemoveBodyVelocity()
    end)
end, Tabs.Waypoints)

CreateButton("Stop Movement", function()
    WAYPOINTS_MOVING = false
    WAYPOINTS_FLYING = false
    RemoveBodyVelocity()
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "BoogaX",
        Text = "Movement stopped!",
        Duration = 2
    })
end, Tabs.Waypoints)

CreateButton("Delete 1 Waypoint", function()
    -- Находим последний waypoint (с максимальным номером)
    local waypoints = WAYPOINTS_HOLDER:GetChildren()
    if #waypoints == 0 then
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "BoogaX",
            Text = "No waypoints to delete!",
            Duration = 2
        })
        return
    end
    
    local lastWaypoint = nil
    local maxNumber = -1
    
    for _, waypoint in ipairs(waypoints) do
        local waypointNumber = waypoint:GetAttribute("WaypointNumber")
        if waypointNumber and waypointNumber > maxNumber then
            maxNumber = waypointNumber
            lastWaypoint = waypoint
        end
    end
    
    if lastWaypoint then
        local waypointType = lastWaypoint:GetAttribute("WaypointType") or "walk"
        local waypointNumber = lastWaypoint:GetAttribute("WaypointNumber")
        
        -- Сначала удаляем Parent, чтобы убрать из workspace
        lastWaypoint.Parent = nil
        
        -- Затем удаляем все дочерние элементы
        for _, child in ipairs(lastWaypoint:GetChildren()) do
            pcall(function()
                child:Destroy()
            end)
        end
        
        -- И наконец удаляем сам waypoint
        pcall(function()
            lastWaypoint:Destroy()
        end)
        
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "BoogaX",
            Text = "Deleted waypoint #" .. waypointNumber .. " (" .. waypointType .. ")",
            Duration = 2
        })
    end
end, Tabs.Waypoints)

CreateButton("Clear Waypoints", function()
    WAYPOINTS_MOVING = false
    
    -- Собираем все waypoints в массив для безопасного удаления
    local waypointsToRemove = {}
    for _, waypoint in ipairs(WAYPOINTS_HOLDER:GetChildren()) do
        table.insert(waypointsToRemove, waypoint)
    end
    
    -- Явно удаляем все waypoints и их дочерние элементы
    for _, waypoint in ipairs(waypointsToRemove) do
        if waypoint:IsA("Part") or waypoint:IsA("BasePart") then
            -- Удаляем все дочерние элементы (BillboardGui, Frame, etc.)
            local descendants = waypoint:GetDescendants()
            for _, child in ipairs(descendants) do
                if child then
                    child:Destroy()
                end
            end
            waypoint:Destroy()
        elseif waypoint then
            waypoint:Destroy()
        end
    end
    
    -- Дополнительная очистка на случай, если что-то осталось
    WAYPOINTS_HOLDER:ClearAllChildren()
    
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "BoogaX",
        Text = "All waypoints cleared!",
        Duration = 2
    })
end, Tabs.Waypoints)

-- Слайдер для настройки скорости полёта
CreateSlider("Flight Speed", 10, 100, 30, function(value)
    FLY_SPEED = value
end, Tabs.Waypoints)

-- ============================================
-- Auto Farm Crystal
-- ============================================

local function FindNearestCrystalLode()
	local player = game:GetService("Players").LocalPlayer
	if not player or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
		return nil
	end
	
	local rootPart = player.Character.HumanoidRootPart
	local nearestCrystal = nil
	local nearestDistance = math.huge
	
	-- Ищем Crystal Lode в Workspace
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("Model") or obj:IsA("Part") then
			local name = obj.Name:lower()
			-- Ищем кристаллы (разные варианты названий)
			if name:find("crystal") and (name:find("lode") or name:find("rock") or name:find("ore")) then
				-- Пропускаем помеченные кристаллы
				if not obj:FindFirstChild("_SkipMarker") then
					local crystalPos = obj:IsA("Model") and obj:GetModelCFrame().Position or obj.Position
					local distance = (rootPart.Position - crystalPos).Magnitude
					
					-- Игнорируем слишком далёкие кристаллы
					if distance < 500 and distance < nearestDistance then
						nearestDistance = distance
						nearestCrystal = obj
					end
				end
			end
		end
	end
	
	return nearestCrystal, nearestDistance
end

local currentCrystalHighlight = nil

local function StartCrystalFarm()
	if CRYSTAL_FARM_RUNNING then return end
	
	CRYSTAL_FARM_RUNNING = true
	
	game:GetService("StarterGui"):SetCore("SendNotification", {
		Title = "BoogaX",
		Text = "🔷 Crystal Farm Started!",
		Duration = 3
	})
	
	task.spawn(function()
		local player = game:GetService("Players").LocalPlayer
		local currentCrystal = nil
		local arrivalTime = 0
		local maxWaitTime = 15 -- Максимум 15 секунд ждать около кристалла
		
		while CRYSTAL_FARM_ENABLED and CRYSTAL_FARM_RUNNING do
			local char = player.Character
			if char and char:FindFirstChild("Humanoid") and char:FindFirstChild("HumanoidRootPart") then
				local humanoid = char.Humanoid
				local rootPart = char.HumanoidRootPart
				
				-- Если текущего кристалла нет или он далеко/удалён, ищем новый
				if not currentCrystal or not currentCrystal.Parent or (rootPart.Position - (currentCrystal:IsA("Model") and currentCrystal:GetModelCFrame().Position or currentCrystal.Position)).Magnitude > 100 then
					-- Убираем старую подсветку
					if currentCrystalHighlight then
						currentCrystalHighlight:Destroy()
						currentCrystalHighlight = nil
					end
					
					currentCrystal, _ = FindNearestCrystalLode()
					arrivalTime = 0
					
					-- Добавляем подсветку к новому кристаллу
					if currentCrystal and currentCrystal.Parent then
						pcall(function()
							local highlight = Instance.new("Highlight")
							highlight.FillColor = Color3.fromRGB(0, 255, 255)
							highlight.OutlineColor = Color3.fromRGB(0, 150, 255)
							highlight.FillTransparency = 0.5
							highlight.OutlineTransparency = 0
							highlight.Parent = currentCrystal
							currentCrystalHighlight = highlight
						end)
					end
				end
				
				if currentCrystal and currentCrystal.Parent then
					local crystalPos = currentCrystal:IsA("Model") and currentCrystal:GetModelCFrame().Position or currentCrystal.Position
					local distance = (rootPart.Position - crystalPos).Magnitude
					
					if distance > 5 then
						-- Идём к кристаллу
						humanoid:MoveTo(crystalPos)
						arrivalTime = 0
					else
						-- Мы у кристалла
						if arrivalTime == 0 then
							arrivalTime = tick()
							game:GetService("StarterGui"):SetCore("SendNotification", {
								Title = "BoogaX",
								Text = "🔷 Near crystal! Waiting for you to break it...",
								Duration = 3
							})
						end
						
						-- Проверяем сколько времени мы тут стоим
						local waitedTime = tick() - arrivalTime
						
						-- Если кристалл не сломали за maxWaitTime секунд, ищем следующий
						if waitedTime > maxWaitTime then
							game:GetService("StarterGui"):SetCore("SendNotification", {
								Title = "BoogaX",
								Text = "⏩ Skipping this crystal...",
								Duration = 2
							})
							-- Помечаем как "пропущенный" временно
							local tempMarker = Instance.new("BoolValue")
							tempMarker.Name = "_SkipMarker"
							tempMarker.Parent = currentCrystal
							task.delay(60, function() -- Через минуту можно вернуться
								if tempMarker and tempMarker.Parent then
									tempMarker:Destroy()
								end
							end)
							currentCrystal = nil
							arrivalTime = 0
						end
					end
				else
					-- Кристаллов не найдено
					game:GetService("StarterGui"):SetCore("SendNotification", {
						Title = "BoogaX",
						Text = "🔍 Searching for crystals...",
						Duration = 3
					})
					task.wait(5)
				end
			end
			
			task.wait(0.5)
		end
		
		-- Убираем подсветку при остановке
		if currentCrystalHighlight then
			currentCrystalHighlight:Destroy()
			currentCrystalHighlight = nil
		end
		
		game:GetService("StarterGui"):SetCore("SendNotification", {
			Title = "BoogaX",
			Text = "🔷 Crystal Farm Stopped!",
			Duration = 3
		})
	end)
end

local function StopCrystalFarm()
	CRYSTAL_FARM_RUNNING = false
	
	-- Убираем подсветку
	if currentCrystalHighlight then
		currentCrystalHighlight:Destroy()
		currentCrystalHighlight = nil
	end
end

-- ============================================
-- AUTO FARM TAB
-- ============================================
-- UI для Crystal Farm
CreateToggle("Auto Farm Crystal", false, function(state)
	CRYSTAL_FARM_ENABLED = state
	
	if state then
		StartCrystalFarm()
	else
		StopCrystalFarm()
	end
end, Tabs.AutoFarm)

-- ============================================
-- Auto Farm Gold
-- ============================================

-- Кэш для поиска золота
local goldOreCache = {}
local goldOreCacheTime = 0
local goldOreCacheInterval = 3 -- Обновляем кэш раз в 3 секунды

local function FindNearestGoldOre()
	local player = game:GetService("Players").LocalPlayer
	if not player or not player.Character then
		return nil
	end
	
	local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return nil
	end
	
	local currentTime = tick()
	local rootPos = rootPart.Position
	
	-- Обновляем кэш реже
	if currentTime - goldOreCacheTime > goldOreCacheInterval then
		goldOreCache = {}
		goldOreCacheTime = currentTime
		
		-- Ищем Gold Ore в Workspace (оптимизированный поиск)
		for _, obj in ipairs(workspace:GetDescendants()) do
			if (obj:IsA("Model") or obj:IsA("Part")) and not obj:FindFirstChild("_SkipMarker") then
				local name = obj.Name:lower()
				-- Быстрая проверка названия
				if name:find("gold") then
					if name:find("ore") or name:find("rock") or name:find("lode") or name:find("vein") or 
					   name:find("rawgold") or name:find("goldore") then
						table.insert(goldOreCache, obj)
					end
				end
			end
		end
	end
	
	-- Ищем ближайшее из кэша
	local nearestGold = nil
	local nearestDistance = math.huge
	
	for _, obj in ipairs(goldOreCache) do
		if obj.Parent and not obj:FindFirstChild("_SkipMarker") then
			local goldPos = obj:IsA("Model") and obj:GetModelCFrame().Position or obj.Position
			local distance = (rootPos - goldPos).Magnitude
			
			if distance < 500 and distance < nearestDistance then
				nearestDistance = distance
				nearestGold = obj
			end
		end
	end
	
	return nearestGold, nearestDistance
end

local currentGoldHighlight = nil

-- Встроенные координаты для автоматического движения
local GOLD_FARM_COORDINATES = {
	Vector3.new(-147.61, -34.35, -114.51), Vector3.new(-144.79, -34.96, -125.01), Vector3.new(-142.15, -35.15, -134.86),
	Vector3.new(-139.40, -35.07, -145.09), Vector3.new(-136.62, -35.01, -155.43), Vector3.new(-137.92, -35.00, -162.06),
	Vector3.new(-141.83, -34.86, -163.96), Vector3.new(-150.81, -33.12, -166.14), Vector3.new(-142.13, -34.81, -164.10),
	Vector3.new(-150.50, -33.26, -166.06), Vector3.new(-141.49, -34.93, -163.95), Vector3.new(-151.05, -32.80, -166.25),
	Vector3.new(-140.20, -34.99, -163.75), Vector3.new(-150.29, -33.15, -166.17), Vector3.new(-138.63, -35.01, -163.44),
	Vector3.new(-129.54, -35.00, -167.41), Vector3.new(-119.51, -35.00, -173.63), Vector3.new(-113.08, -33.58, -175.86),
	Vector3.new(-107.69, -28.22, -178.14), Vector3.new(-103.02, -25.67, -183.40), Vector3.new(-109.34, -26.60, -190.82),
	Vector3.new(-102.70, -25.55, -183.03), Vector3.new(-109.53, -26.58, -191.05), Vector3.new(-103.13, -25.59, -183.53),
	Vector3.new(-108.86, -26.60, -190.26), Vector3.new(-103.54, -25.74, -184.01), Vector3.new(-110.88, -26.51, -190.02),
	Vector3.new(-116.90, -26.08, -191.14), Vector3.new(-119.92, -26.72, -191.33), Vector3.new(-122.27, -23.89, -194.36),
	Vector3.new(-121.96, -17.50, -199.60), Vector3.new(-121.74, -11.27, -203.75), Vector3.new(-122.35, -6.44, -207.77),
	Vector3.new(-128.01, -6.40, -209.41), Vector3.new(-134.90, -6.55, -207.02), Vector3.new(-127.80, -6.62, -209.16),
	Vector3.new(-121.59, -5.92, -208.77), Vector3.new(-127.99, -6.59, -209.17), Vector3.new(-135.23, -6.77, -206.22),
	Vector3.new(-129.78, -5.88, -210.33), Vector3.new(-121.76, -5.44, -209.83), Vector3.new(-134.32, -6.57, -207.39),
	Vector3.new(-126.07, -4.65, -213.14), Vector3.new(-116.15, -3.02, -219.78), Vector3.new(-104.89, -3.00, -225.43),
	Vector3.new(-95.60, -3.00, -231.50), Vector3.new(-86.13, -3.00, -237.67), Vector3.new(-76.67, -3.00, -243.85),
	Vector3.new(-67.96, -3.00, -249.53), Vector3.new(-62.98, -3.00, -252.77), Vector3.new(-57.26, -3.00, -258.38),
	Vector3.new(-48.24, -3.00, -264.08), Vector3.new(-36.56, -3.00, -269.31), Vector3.new(-24.60, -3.00, -274.65),
	Vector3.new(-11.18, -3.00, -280.65), Vector3.new(1.24, -3.00, -286.20), Vector3.new(14.39, -3.00, -292.07),
	Vector3.new(27.26, -3.00, -297.83), Vector3.new(39.40, -3.00, -303.25), Vector3.new(51.37, -3.00, -308.60),
	Vector3.new(62.96, -3.00, -313.78), Vector3.new(73.28, -3.00, -318.39), Vector3.new(82.75, -3.00, -326.72),
	Vector3.new(91.61, -3.00, -336.27), Vector3.new(105.95, -3.00, -345.06), Vector3.new(119.31, -3.00, -354.05),
	Vector3.new(129.84, -3.00, -361.14), Vector3.new(141.53, -3.00, -369.02), Vector3.new(153.89, -3.00, -377.34),
	Vector3.new(164.68, -3.00, -384.60), Vector3.new(176.54, -3.00, -392.59), Vector3.new(185.50, -3.00, -398.62),
	Vector3.new(203.97, -3.00, -402.47), Vector3.new(218.50, -3.00, -400.99), Vector3.new(234.42, -3.00, -399.36),
	Vector3.new(252.15, -5.20, -397.96), Vector3.new(267.53, -7.12, -396.95), Vector3.new(282.19, -7.80, -395.98),
	Vector3.new(297.54, -7.64, -394.98), Vector3.new(310.84, -7.71, -394.10), Vector3.new(324.71, -7.00, -393.19),
	Vector3.new(340.90, -7.15, -392.13), Vector3.new(358.03, -7.00, -391.00), Vector3.new(374.19, -7.78, -389.94),
	Vector3.new(391.04, -7.54, -388.83), Vector3.new(408.35, -7.07, -387.70), Vector3.new(425.68, -7.30, -386.56),
	Vector3.new(441.44, -7.35, -385.52), Vector3.new(457.02, -7.11, -384.50), Vector3.new(474.81, -7.82, -383.33),
	Vector3.new(489.42, -7.00, -382.37), Vector3.new(506.66, -5.02, -383.01), Vector3.new(519.15, -3.64, -384.29),
	Vector3.new(530.66, -3.14, -385.50), Vector3.new(537.68, 1.99, -386.20), Vector3.new(545.14, 10.03, -386.96),
	Vector3.new(560.54, 9.91, -388.54), Vector3.new(571.87, 7.53, -389.71), Vector3.new(581.41, 2.46, -389.52),
	Vector3.new(589.89, -3.41, -386.22), Vector3.new(600.45, -4.85, -383.12), Vector3.new(617.37, -7.20, -386.44),
	Vector3.new(606.88, -5.65, -383.96), Vector3.new(618.44, -7.20, -386.61), Vector3.new(607.01, -5.96, -383.92),
	Vector3.new(616.69, -7.20, -386.16), Vector3.new(606.80, -5.58, -383.82), Vector3.new(618.40, -7.22, -386.52),
	Vector3.new(623.59, -7.67, -381.30), Vector3.new(633.52, -7.29, -377.13), Vector3.new(639.42, -6.54, -367.93),
	Vector3.new(636.73, -7.00, -379.41), Vector3.new(639.20, -6.64, -368.56), Vector3.new(636.55, -6.88, -379.82),
	Vector3.new(639.39, -6.67, -367.67), Vector3.new(636.58, -6.91, -379.41), Vector3.new(639.03, -6.84, -368.96),
	Vector3.new(634.90, -7.01, -362.12), Vector3.new(630.60, -6.11, -356.84), Vector3.new(626.38, -6.86, -355.86),
	Vector3.new(617.69, -7.43, -353.86), Vector3.new(627.80, -6.69, -356.25), Vector3.new(617.14, -7.31, -353.79),
	Vector3.new(627.85, -6.52, -356.32), Vector3.new(618.18, -7.52, -354.11), Vector3.new(627.36, -6.72, -356.29),
	Vector3.new(616.04, -7.31, -353.65), Vector3.new(604.80, -7.22, -354.09), Vector3.new(612.25, -7.30, -350.15),
	Vector3.new(605.57, -7.20, -353.77), Vector3.new(612.23, -7.08, -349.78), Vector3.new(605.40, -7.14, -352.78),
	Vector3.new(612.36, -6.92, -349.64), Vector3.new(603.96, -7.36, -355.77), Vector3.new(599.42, -8.70, -366.29),
	Vector3.new(595.12, -7.42, -374.95), Vector3.new(590.62, -3.38, -382.74), Vector3.new(586.60, -2.09, -385.22),
	Vector3.new(581.46, 1.43, -387.32), Vector3.new(569.45, 8.14, -391.87), Vector3.new(558.39, 11.75, -396.05),
	Vector3.new(549.06, 12.50, -399.59), Vector3.new(548.70, 16.19, -408.24), Vector3.new(547.69, 22.65, -412.93),
	Vector3.new(547.66, 29.50, -420.48), Vector3.new(555.22, 35.61, -424.18), Vector3.new(560.31, 41.63, -423.11),
	Vector3.new(568.35, 44.77, -419.78), Vector3.new(578.80, 48.22, -416.94), Vector3.new(591.21, 48.72, -413.57),
	Vector3.new(605.25, 48.86, -409.76), Vector3.new(617.44, 52.03, -406.44), Vector3.new(629.17, 52.20, -407.06),
	Vector3.new(639.20, 56.46, -410.03), Vector3.new(646.43, 62.68, -411.21), Vector3.new(654.62, 67.82, -412.71),
	Vector3.new(661.05, 75.48, -413.77), Vector3.new(670.20, 81.38, -413.36), Vector3.new(677.45, 84.17, -406.63),
	Vector3.new(685.06, 84.31, -399.78), Vector3.new(687.93, 87.35, -392.17), Vector3.new(684.61, 82.92, -387.02),
	Vector3.new(690.42, 88.08, -391.77), Vector3.new(686.14, 85.42, -397.52), Vector3.new(691.42, 89.42, -390.12),
	Vector3.new(686.92, 86.00, -388.10), Vector3.new(691.35, 88.42, -393.90), Vector3.new(685.37, 85.16, -398.43),
	Vector3.new(690.49, 88.36, -390.22), Vector3.new(686.93, 86.96, -387.26), Vector3.new(682.36, 81.07, -383.93),
	Vector3.new(679.44, 80.00, -376.66), Vector3.new(673.83, 76.25, -369.37), Vector3.new(674.09, 71.24, -362.47),
	Vector3.new(674.54, 66.13, -355.84), Vector3.new(675.20, 59.68, -345.14), Vector3.new(675.98, 56.23, -332.65),
	Vector3.new(677.48, 53.01, -319.71), Vector3.new(683.46, 48.41, -311.14), Vector3.new(690.01, 41.61, -305.37),
	Vector3.new(697.32, 35.26, -298.91), Vector3.new(707.83, 31.32, -295.69), Vector3.new(716.79, 26.11, -291.91),
	Vector3.new(723.64, 23.42, -283.73), Vector3.new(729.00, 23.97, -273.60), Vector3.new(729.92, 23.17, -261.17),
	Vector3.new(728.88, 22.22, -249.38), Vector3.new(729.50, 23.39, -239.39), Vector3.new(725.20, 25.38, -229.51),
	Vector3.new(719.27, 27.17, -219.92), Vector3.new(714.48, 24.80, -210.83), Vector3.new(706.45, 26.39, -201.73),
	Vector3.new(697.91, 28.34, -194.39), Vector3.new(690.06, 29.09, -186.80), Vector3.new(682.85, 32.87, -180.40),
	Vector3.new(672.57, 32.87, -179.76), Vector3.new(662.89, 32.74, -184.24), Vector3.new(668.61, 33.69, -192.43),
	Vector3.new(659.71, 32.00, -186.87), Vector3.new(667.98, 33.59, -191.95), Vector3.new(659.40, 32.01, -186.60),
	Vector3.new(668.90, 33.88, -192.44), Vector3.new(658.91, 31.76, -186.27), Vector3.new(667.99, 33.45, -191.82),
	Vector3.new(658.16, 31.53, -185.76), Vector3.new(653.46, 30.98, -182.80), Vector3.new(643.75, 28.92, -177.40),
	Vector3.new(632.18, 32.24, -180.14), Vector3.new(626.28, 32.83, -184.21), Vector3.new(614.21, 31.60, -189.07),
	Vector3.new(600.82, 20.97, -194.46), Vector3.new(594.35, 9.85, -197.06), Vector3.new(583.68, -0.36, -201.35),
	Vector3.new(574.05, -3.79, -205.23), Vector3.new(564.88, -6.76, -208.92), Vector3.new(555.36, -7.75, -212.75),
	Vector3.new(544.12, -7.01, -217.27), Vector3.new(533.23, -7.05, -221.65), Vector3.new(522.96, -7.03, -225.78),
	Vector3.new(511.05, -7.36, -230.58), Vector3.new(495.08, -7.52, -238.86), Vector3.new(481.53, -7.15, -246.85),
	Vector3.new(469.25, -7.12, -254.08), Vector3.new(455.80, -7.38, -262.00), Vector3.new(443.50, -7.02, -269.25),
	Vector3.new(431.62, -7.75, -276.24), Vector3.new(420.67, -7.23, -282.69), Vector3.new(408.13, -7.86, -290.08),
	Vector3.new(397.15, -7.00, -296.55), Vector3.new(387.06, -7.53, -302.49), Vector3.new(374.98, -7.49, -309.60),
	Vector3.new(364.07, -7.91, -316.03), Vector3.new(353.51, -7.34, -322.25), Vector3.new(343.20, -7.01, -328.32),
	Vector3.new(333.73, -7.01, -333.90), Vector3.new(323.46, -7.26, -339.95), Vector3.new(312.73, -7.07, -346.27),
	Vector3.new(301.79, -7.00, -352.71), Vector3.new(291.02, -7.00, -359.05), Vector3.new(280.69, -7.01, -365.14),
	Vector3.new(270.52, -7.00, -371.13), Vector3.new(260.18, -7.00, -377.22), Vector3.new(251.09, -3.87, -382.57),
	Vector3.new(241.28, -3.00, -388.35), Vector3.new(230.68, -3.00, -394.60), Vector3.new(221.80, -3.00, -399.82),
	Vector3.new(211.55, -3.00, -405.86), Vector3.new(202.33, -3.00, -411.29), Vector3.new(192.59, -3.00, -417.03),
	Vector3.new(180.40, -6.89, -426.14), Vector3.new(169.63, -7.46, -435.15), Vector3.new(157.75, -7.47, -438.31),
	Vector3.new(144.36, -7.58, -441.87), Vector3.new(130.84, -7.42, -445.47), Vector3.new(118.11, -7.78, -448.86),
	Vector3.new(106.87, -7.20, -451.85), Vector3.new(95.04, -7.11, -455.00), Vector3.new(83.28, -7.04, -458.12),
	Vector3.new(70.84, -7.59, -461.44), Vector3.new(58.64, -7.25, -464.68), Vector3.new(46.11, -7.00, -468.01),
	Vector3.new(34.50, -4.62, -471.12), Vector3.new(22.60, -3.00, -474.28), Vector3.new(12.07, -3.00, -477.08),
	Vector3.new(-0.21, -3.00, -480.35), Vector3.new(-10.93, -3.00, -483.20), Vector3.new(-21.66, -3.00, -486.05),
	Vector3.new(-33.74, -3.00, -489.26), Vector3.new(-44.56, -3.00, -492.14), Vector3.new(-58.65, -3.00, -496.52),
	Vector3.new(-75.01, -1.06, -502.49), Vector3.new(-82.08, 2.70, -505.03), Vector3.new(-96.42, 5.00, -508.30),
	Vector3.new(-104.53, 5.00, -512.09), Vector3.new(-112.05, 5.00, -514.87), Vector3.new(-124.59, 5.00, -519.08),
	Vector3.new(-130.97, 5.00, -521.26), Vector3.new(-137.11, 5.00, -528.09), Vector3.new(-151.25, 5.00, -544.15),
	Vector3.new(-160.12, 5.00, -554.33), Vector3.new(-170.43, 5.00, -566.18), Vector3.new(-179.42, 5.00, -576.51),
	Vector3.new(-187.66, 5.00, -590.16), Vector3.new(-192.56, 5.00, -609.12), Vector3.new(-199.63, 5.54, -615.26),
	Vector3.new(-202.66, 9.81, -617.36), Vector3.new(-204.17, 14.94, -621.38), Vector3.new(-205.84, 20.61, -625.81),
	Vector3.new(-209.51, 21.50, -629.30), Vector3.new(-215.91, 21.51, -626.02), Vector3.new(-208.97, 21.50, -629.71),
	Vector3.new(-216.30, 21.50, -625.77), Vector3.new(-208.94, 21.50, -629.68), Vector3.new(-216.35, 21.50, -625.70),
	Vector3.new(-209.34, 21.50, -629.43), Vector3.new(-216.82, 21.50, -625.40), Vector3.new(-210.44, 21.50, -628.79),
	Vector3.new(-208.27, 21.50, -630.86), Vector3.new(-203.15, 5.64, -633.59), Vector3.new(-202.11, -1.23, -638.33),
	Vector3.new(-209.11, -3.00, -644.87), Vector3.new(-218.71, -2.75, -644.40), Vector3.new(-227.01, -2.26, -638.84),
	Vector3.new(-237.80, -2.52, -631.61), Vector3.new(-246.85, -2.74, -625.54), Vector3.new(-256.61, -3.50, -619.01),
	Vector3.new(-266.60, -4.69, -612.31), Vector3.new(-276.37, -4.00, -605.77), Vector3.new(-281.88, -3.23, -602.14),
	Vector3.new(-295.47, -3.07, -602.32), Vector3.new(-311.98, -3.00, -603.67), Vector3.new(-327.08, -3.00, -603.87),
	Vector3.new(-343.48, -3.00, -604.09), Vector3.new(-354.84, -3.01, -603.40), Vector3.new(-367.95, -3.06, -606.66),
	Vector3.new(-374.54, -5.25, -613.30), Vector3.new(-383.16, -8.54, -615.22), Vector3.new(-387.82, -12.39, -612.32),
	Vector3.new(-391.54, -20.52, -608.88), Vector3.new(-398.49, -23.51, -602.52), Vector3.new(-404.36, -26.75, -596.60),
	Vector3.new(-406.86, -27.70, -585.35), Vector3.new(-406.82, -27.98, -575.62), Vector3.new(-407.18, -31.25, -569.14),
	Vector3.new(-407.82, -35.40, -559.90), Vector3.new(-408.11, -39.45, -554.45), Vector3.new(-399.61, -40.12, -555.41),
	Vector3.new(-394.11, -42.79, -556.55), Vector3.new(-384.07, -43.46, -558.76), Vector3.new(-377.33, -43.68, -554.74),
	Vector3.new(-379.88, -43.31, -563.82), Vector3.new(-377.46, -43.60, -555.42), Vector3.new(-379.87, -43.24, -564.02),
	Vector3.new(-377.56, -43.62, -555.91), Vector3.new(-379.73, -43.27, -563.87), Vector3.new(-377.19, -43.69, -554.83),
	Vector3.new(-379.80, -43.22, -564.03), Vector3.new(-369.30, -44.02, -561.79), Vector3.new(-357.81, -46.77, -563.45),
	Vector3.new(-348.37, -47.00, -565.62), Vector3.new(-338.26, -47.17, -567.22), Vector3.new(-325.86, -47.88, -569.19),
	Vector3.new(-313.90, -50.15, -571.10), Vector3.new(-305.49, -56.78, -572.44), Vector3.new(-295.66, -56.52, -568.77),
	Vector3.new(-287.83, -57.03, -563.86), Vector3.new(-282.13, -56.71, -562.03), Vector3.new(-271.18, -56.69, -557.98),
	Vector3.new(-260.31, -55.76, -553.95), Vector3.new(-248.73, -57.76, -549.66), Vector3.new(-240.44, -59.34, -546.58),
	Vector3.new(-234.53, -59.21, -544.89), Vector3.new(-229.02, -59.23, -543.81), Vector3.new(-219.82, -59.91, -541.37),
	Vector3.new(-211.49, -60.00, -540.35), Vector3.new(-204.54, -60.53, -540.86), Vector3.new(-192.28, -62.99, -545.57),
	Vector3.new(-184.09, -63.09, -551.28), Vector3.new(-177.89, -63.51, -559.07), Vector3.new(-173.17, -63.10, -563.74),
	Vector3.new(-172.99, -63.94, -571.72), Vector3.new(-172.74, -63.76, -582.49), Vector3.new(-174.07, -63.99, -595.80),
	Vector3.new(-180.83, -64.31, -604.20), Vector3.new(-188.60, -63.12, -612.33), Vector3.new(-197.98, -63.08, -620.45),
	Vector3.new(-206.63, -61.22, -622.08), Vector3.new(-211.96, -59.76, -631.69), Vector3.new(-207.59, -61.73, -624.33),
	Vector3.new(-210.32, -60.14, -630.53), Vector3.new(-206.87, -61.65, -623.97), Vector3.new(-209.75, -60.36, -629.77),
	Vector3.new(-206.39, -61.48, -623.43), Vector3.new(-208.71, -60.44, -629.14), Vector3.new(-204.61, -61.32, -623.20),
	Vector3.new(-208.61, -60.27, -629.79), Vector3.new(-203.96, -61.28, -622.94), Vector3.new(-195.54, -63.53, -621.08),
	Vector3.new(-187.94, -63.55, -619.39), Vector3.new(-178.95, -64.30, -606.00), Vector3.new(-175.84, -63.60, -595.05),
	Vector3.new(-174.40, -63.98, -580.44), Vector3.new(-174.44, -63.41, -567.58), Vector3.new(-174.47, -63.32, -556.70),
	Vector3.new(-171.78, -64.30, -545.25), Vector3.new(-167.79, -63.38, -536.17), Vector3.new(-166.40, -63.40, -526.96),
	Vector3.new(-167.43, -63.02, -515.59), Vector3.new(-167.46, -63.15, -505.79), Vector3.new(-169.04, -63.16, -496.85),
	Vector3.new(-172.15, -64.83, -487.18), Vector3.new(-175.96, -66.28, -480.06), Vector3.new(-180.27, -66.50, -471.97),
	Vector3.new(-185.08, -67.10, -463.90), Vector3.new(-188.78, -67.31, -455.85), Vector3.new(-190.57, -68.11, -447.11),
	Vector3.new(-190.60, -67.11, -436.98), Vector3.new(-190.98, -67.00, -426.33), Vector3.new(-191.15, -67.00, -417.38),
	Vector3.new(-193.44, -67.00, -408.23), Vector3.new(-199.01, -67.56, -402.70), Vector3.new(-201.08, -70.16, -392.76),
	Vector3.new(-203.00, -71.31, -385.01), Vector3.new(-205.70, -71.31, -378.37), Vector3.new(-211.56, -72.01, -372.34),
	Vector3.new(-218.91, -75.02, -365.04), Vector3.new(-225.00, -75.23, -358.98), Vector3.new(-232.32, -76.44, -351.70),
	Vector3.new(-238.83, -79.01, -345.24), Vector3.new(-245.92, -79.00, -338.19), Vector3.new(-252.70, -79.00, -334.03),
	Vector3.new(-263.69, -79.00, -340.99), Vector3.new(-277.66, -79.00, -351.84), Vector3.new(-292.04, -79.00, -363.01),
	Vector3.new(-298.88, -79.00, -368.28), Vector3.new(-308.21, -79.00, -372.80), Vector3.new(-299.34, -79.01, -368.46),
	Vector3.new(-308.23, -79.00, -372.72), Vector3.new(-300.85, -79.00, -369.11), Vector3.new(-307.45, -79.00, -372.28),
	Vector3.new(-299.46, -79.01, -368.37), Vector3.new(-308.34, -79.00, -372.61), Vector3.new(-300.34, -79.01, -368.72),
	Vector3.new(-308.62, -79.00, -372.67), Vector3.new(-300.71, -79.01, -368.81), Vector3.new(-307.98, -79.01, -372.28),
	Vector3.new(-298.48, -79.00, -367.64), Vector3.new(-308.69, -79.01, -372.53), Vector3.new(-295.99, -79.00, -366.38),
	Vector3.new(-283.56, -79.00, -357.83), Vector3.new(-270.80, -79.00, -345.51), Vector3.new(-259.97, -79.00, -336.39),
	Vector3.new(-247.28, -78.88, -325.09), Vector3.new(-234.96, -79.00, -314.13), Vector3.new(-227.46, -79.35, -307.46),
	Vector3.new(-229.66, -79.39, -294.27), Vector3.new(-230.01, -79.83, -273.16), Vector3.new(-230.25, -83.03, -257.40),
	Vector3.new(-240.66, -83.00, -249.44), Vector3.new(-239.88, -81.97, -244.07), Vector3.new(-243.19, -83.00, -249.15),
	Vector3.new(-240.74, -83.13, -245.31), Vector3.new(-243.57, -83.09, -249.83), Vector3.new(-240.25, -82.17, -244.64),
	Vector3.new(-243.46, -83.00, -249.69), Vector3.new(-240.15, -81.84, -244.52), Vector3.new(-243.39, -83.02, -249.77),
	Vector3.new(-240.51, -82.24, -245.29), Vector3.new(-241.95, -83.01, -247.68), Vector3.new(-241.19, -83.10, -246.39),
	Vector3.new(-242.79, -83.07, -249.06), Vector3.new(-240.68, -82.40, -245.83), Vector3.new(-242.86, -83.04, -249.32),
	Vector3.new(-239.94, -81.50, -244.64), Vector3.new(-241.94, -83.00, -247.68), Vector3.new(-240.02, -81.69, -244.60),
	Vector3.new(-242.62, -83.00, -248.60), Vector3.new(-233.85, -83.00, -252.09), Vector3.new(-221.28, -83.16, -253.70),
	Vector3.new(-209.30, -86.46, -254.52), Vector3.new(-197.42, -87.36, -255.33), Vector3.new(-183.45, -87.36, -257.45),
	Vector3.new(-170.37, -87.36, -260.35), Vector3.new(-154.32, -87.36, -263.90), Vector3.new(-143.50, -87.36, -271.22),
	Vector3.new(-130.07, -88.04, -282.23), Vector3.new(-117.54, -91.42, -293.77), Vector3.new(-116.01, -94.66, -307.09),
	Vector3.new(-117.32, -99.16, -320.98), Vector3.new(-118.31, -101.71, -333.70), Vector3.new(-127.89, -103.00, -344.10),
	Vector3.new(-143.56, -103.00, -350.27), Vector3.new(-151.77, -103.00, -356.97), Vector3.new(-154.81, -103.00, -370.24),
	Vector3.new(-155.96, -103.00, -383.12), Vector3.new(-154.64, -103.00, -395.89), Vector3.new(-153.56, -103.00, -409.16),
	Vector3.new(-151.20, -103.00, -428.60), Vector3.new(-150.31, -103.00, -445.42), Vector3.new(-151.43, -103.00, -463.22),
	Vector3.new(-151.48, -103.00, -480.81), Vector3.new(-157.54, -103.00, -497.28), Vector3.new(-165.29, -103.00, -502.72),
	Vector3.new(-175.67, -103.67, -505.33), Vector3.new(-184.20, -103.00, -505.57), Vector3.new(-189.96, -103.61, -502.40),
	Vector3.new(-193.19, -103.24, -495.34), Vector3.new(-192.85, -103.04, -487.97), Vector3.new(-191.50, -103.06, -478.64),
	Vector3.new(-190.08, -103.56, -468.76), Vector3.new(-188.80, -104.18, -459.88), Vector3.new(-192.17, -103.88, -456.45),
	Vector3.new(-186.03, -102.77, -455.94), Vector3.new(-193.05, -103.52, -456.55), Vector3.new(-185.94, -103.11, -455.95),
	Vector3.new(-192.95, -103.56, -456.58), Vector3.new(-185.95, -103.13, -456.00), Vector3.new(-192.46, -103.60, -456.58),
	Vector3.new(-186.14, -102.94, -456.18), Vector3.new(-191.75, -103.81, -456.66), Vector3.new(-186.59, -103.16, -456.38),
	Vector3.new(-191.57, -103.82, -456.80), Vector3.new(-185.71, -102.95, -456.33), Vector3.new(-188.92, -104.12, -461.88),
	Vector3.new(-190.77, -103.47, -472.81), Vector3.new(-192.71, -103.00, -484.04), Vector3.new(-193.22, -103.27, -495.59),
	Vector3.new(-189.82, -103.27, -504.69), Vector3.new(-184.02, -103.00, -506.17), Vector3.new(-175.33, -103.04, -504.19),
	Vector3.new(-168.44, -103.00, -502.97), Vector3.new(-157.99, -103.00, -497.63), Vector3.new(-145.49, -103.00, -492.19),
	Vector3.new(-133.40, -103.00, -487.97), Vector3.new(-121.41, -103.00, -483.78), Vector3.new(-109.14, -103.00, -481.15),
	Vector3.new(-96.11, -103.00, -476.60), Vector3.new(-82.61, -103.00, -471.89), Vector3.new(-70.64, -103.00, -466.28),
	Vector3.new(-58.75, -103.00, -462.13), Vector3.new(-47.23, -103.00, -457.14), Vector3.new(-37.16, -103.00, -452.05),
	Vector3.new(-26.48, -103.01, -446.82), Vector3.new(-16.08, -103.00, -441.55), Vector3.new(-6.76, -103.00, -435.07),
	Vector3.new(1.80, -103.00, -428.57), Vector3.new(10.08, -103.00, -419.54), Vector3.new(15.18, -100.57, -409.51),
	Vector3.new(19.08, -99.00, -397.69), Vector3.new(22.93, -99.00, -385.34), Vector3.new(20.36, -99.00, -381.41),
	Vector3.new(25.59, -99.03, -372.45), Vector3.new(20.87, -99.00, -381.29), Vector3.new(24.71, -99.01, -372.05),
	Vector3.new(20.85, -99.00, -379.81), Vector3.new(24.83, -99.00, -373.21), Vector3.new(20.49, -99.00, -380.82),
	Vector3.new(23.61, -99.00, -374.26), Vector3.new(20.23, -99.02, -381.21), Vector3.new(24.14, -99.01, -372.98),
	Vector3.new(20.62, -99.00, -380.32), Vector3.new(27.53, -99.04, -373.71), Vector3.new(34.18, -99.17, -372.36),
	Vector3.new(40.60, -99.00, -366.24), Vector3.new(33.14, -99.14, -373.28), Vector3.new(39.38, -99.01, -367.31),
	Vector3.new(34.17, -99.17, -372.22), Vector3.new(39.13, -99.02, -367.43), Vector3.new(32.91, -99.14, -373.31),
	Vector3.new(39.81, -99.00, -366.70), Vector3.new(32.12, -99.11, -373.97), Vector3.new(40.88, -99.00, -365.62),
	Vector3.new(49.69, -99.31, -357.20), Vector3.new(56.43, -98.92, -361.94), Vector3.new(50.91, -99.41, -356.18),
	Vector3.new(56.99, -98.85, -362.61), Vector3.new(51.40, -99.20, -356.80), Vector3.new(55.55, -98.99, -361.19),
	Vector3.new(50.69, -99.30, -356.14), Vector3.new(56.45, -98.91, -362.25), Vector3.new(51.41, -98.88, -357.01),
	Vector3.new(50.58, -99.00, -365.04), Vector3.new(46.89, -99.00, -365.28), Vector3.new(36.18, -99.13, -369.16),
	Vector3.new(28.61, -99.64, -379.16), Vector3.new(21.13, -99.00, -387.02), Vector3.new(19.61, -99.01, -399.88),
	Vector3.new(16.29, -99.99, -408.38), Vector3.new(12.52, -102.83, -415.95), Vector3.new(2.88, -103.00, -416.74),
	Vector3.new(-5.27, -103.00, -412.93), Vector3.new(-18.36, -103.00, -406.92), Vector3.new(-37.55, -103.00, -397.81),
	Vector3.new(-42.93, -103.00, -395.64), Vector3.new(-43.23, -99.37, -390.00), Vector3.new(-43.41, -94.71, -386.59),
	Vector3.new(-45.26, -92.20, -384.52), Vector3.new(-46.08, -90.38, -381.46), Vector3.new(-46.33, -90.50, -376.68),
	Vector3.new(-42.28, -90.50, -372.31), Vector3.new(-38.35, -90.92, -368.08), Vector3.new(-28.05, -91.22, -366.62),
	Vector3.new(-17.04, -91.75, -366.21), Vector3.new(-9.96, -91.02, -367.77), Vector3.new(-5.57, -87.80, -367.37),
	Vector3.new(-1.00, -83.84, -369.03), Vector3.new(-9.29, -81.09, -376.34), Vector3.new(-18.92, -81.23, -379.42),
	Vector3.new(-29.99, -78.77, -384.24), Vector3.new(-33.80, -75.71, -389.49), Vector3.new(-36.88, -72.92, -399.01),
	Vector3.new(-31.22, -72.99, -413.04), Vector3.new(-26.78, -73.11, -421.44), Vector3.new(-24.22, -73.17, -434.57),
	Vector3.new(-26.22, -73.05, -421.72), Vector3.new(-24.46, -73.16, -433.78), Vector3.new(-26.30, -73.05, -421.79),
	Vector3.new(-24.60, -73.16, -433.43), Vector3.new(-26.17, -73.14, -423.11), Vector3.new(-24.58, -73.16, -434.06),
	Vector3.new(-26.24, -73.14, -423.19), Vector3.new(-24.63, -73.17, -434.13), Vector3.new(-26.89, -72.94, -419.10),
	Vector3.new(-33.78, -72.94, -411.30), Vector3.new(-32.45, -73.11, -397.83), Vector3.new(-32.49, -76.29, -386.62),
	Vector3.new(-27.16, -79.85, -382.42), Vector3.new(-16.76, -81.42, -379.20), Vector3.new(-6.28, -81.91, -374.35),
	Vector3.new(0.63, -83.61, -367.78), Vector3.new(10.51, -85.28, -357.49), Vector3.new(17.90, -85.53, -347.46),
	Vector3.new(16.52, -88.14, -339.22), Vector3.new(11.15, -91.20, -329.05), Vector3.new(6.99, -91.87, -317.73),
	Vector3.new(3.01, -94.00, -306.17), Vector3.new(0.84, -93.96, -294.93), Vector3.new(-1.56, -92.56, -282.51),
	Vector3.new(-7.63, -91.18, -270.22), Vector3.new(-9.77, -86.03, -264.32), Vector3.new(-6.70, -84.81, -256.31),
	Vector3.new(-8.52, -84.96, -246.94), Vector3.new(-15.11, -86.50, -237.76), Vector3.new(-20.45, -87.00, -234.15),
	Vector3.new(-27.67, -87.00, -239.11), Vector3.new(-40.16, -86.27, -240.71), Vector3.new(-46.45, -87.73, -236.90),
	Vector3.new(-47.58, -84.47, -228.88), Vector3.new(-48.09, -85.12, -218.38), Vector3.new(-41.47, -83.31, -209.35),
	Vector3.new(-34.58, -83.04, -203.48), Vector3.new(-26.26, -83.19, -194.97), Vector3.new(-21.84, -83.13, -187.97),
	Vector3.new(-15.99, -83.74, -178.53), Vector3.new(-11.23, -83.28, -169.77), Vector3.new(-6.14, -83.37, -160.38),
	Vector3.new(-0.61, -83.15, -150.19), Vector3.new(1.81, -83.00, -140.42), Vector3.new(0.94, -83.00, -131.04),
	Vector3.new(-0.40, -83.00, -121.33), Vector3.new(0.09, -83.00, -112.00), Vector3.new(1.09, -83.00, -101.70),
	Vector3.new(1.37, -83.00, -92.72), Vector3.new(-1.64, -83.00, -77.70), Vector3.new(0.52, -83.00, -88.31),
	Vector3.new(-1.53, -83.00, -78.43), Vector3.new(0.41, -83.00, -88.12), Vector3.new(-1.87, -83.00, -77.31),
	Vector3.new(0.41, -83.00, -88.63), Vector3.new(-1.55, -83.00, -76.96), Vector3.new(1.46, -82.07, -70.95),
	Vector3.new(3.84, -79.33, -62.64), Vector3.new(18.37, -75.00, -44.16), Vector3.new(24.82, -75.00, -35.38),
	Vector3.new(31.15, -75.00, -26.75), Vector3.new(38.25, -75.00, -17.08), Vector3.new(46.74, -75.00, -11.12),
	Vector3.new(55.69, -75.00, -7.89), Vector3.new(65.51, -75.00, -4.30), Vector3.new(75.13, -75.00, -0.75),
	Vector3.new(83.86, -75.00, 3.02), Vector3.new(93.11, -75.00, 6.65), Vector3.new(101.41, -75.00, 10.07),
	Vector3.new(111.09, -75.00, 14.42), Vector3.new(120.81, -75.00, 17.63), Vector3.new(128.37, -75.00, 20.65),
	Vector3.new(140.82, -75.00, 26.97), Vector3.new(151.77, -75.00, 27.58), Vector3.new(142.02, -75.00, 27.05),
	Vector3.new(151.44, -75.00, 27.50), Vector3.new(141.49, -75.01, 26.95), Vector3.new(151.92, -75.00, 27.46),
	Vector3.new(141.40, -75.00, 26.92), Vector3.new(152.26, -75.00, 27.45), Vector3.new(142.30, -75.01, 26.89),
	Vector3.new(152.22, -75.00, 27.37), Vector3.new(136.11, -75.00, 26.55), Vector3.new(117.42, -75.00, 20.66),
	Vector3.new(106.45, -75.00, 16.89), Vector3.new(95.92, -75.00, 11.78), Vector3.new(86.64, -75.00, 6.94),
	Vector3.new(75.30, -75.00, 2.90), Vector3.new(61.11, -75.00, -3.10), Vector3.new(49.49, -75.00, -9.34),
	Vector3.new(39.99, -75.00, -14.62), Vector3.new(31.60, -75.00, -21.31), Vector3.new(26.86, -75.00, -31.01),
	Vector3.new(14.42, -75.00, -35.37), Vector3.new(3.91, -75.00, -34.79), Vector3.new(-6.12, -75.00, -35.25),
	Vector3.new(-14.06, -75.28, -34.76), Vector3.new(-21.17, -75.93, -37.30), Vector3.new(-25.82, -75.54, -44.30),
	Vector3.new(-30.15, -75.01, -52.85), Vector3.new(-35.18, -75.00, -60.43), Vector3.new(-42.93, -75.00, -65.46),
	Vector3.new(-49.55, -75.00, -71.84), Vector3.new(-58.28, -75.81, -74.90), Vector3.new(-62.01, -78.97, -73.37),
	Vector3.new(-64.22, -82.98, -67.34), Vector3.new(-68.59, -87.65, -60.55), Vector3.new(-68.60, -90.02, -55.46),
	Vector3.new(-59.72, -91.21, -51.07), Vector3.new(-52.35, -91.53, -45.45), Vector3.new(-41.25, -91.19, -38.25),
	Vector3.new(-33.50, -91.17, -32.99), Vector3.new(-28.48, -91.19, -23.03), Vector3.new(-20.16, -91.12, -9.74),
	Vector3.new(-15.80, -91.23, -10.52), Vector3.new(-23.86, -91.47, -8.27), Vector3.new(-15.77, -91.23, -10.94),
	Vector3.new(-24.55, -91.67, -8.80), Vector3.new(-16.10, -91.18, -11.76), Vector3.new(-24.33, -91.66, -9.62),
	Vector3.new(-16.57, -91.18, -12.24), Vector3.new(-24.66, -91.57, -10.01), Vector3.new(-25.14, -91.19, -22.26),
	Vector3.new(-29.18, -91.19, -27.03), Vector3.new(-37.11, -91.19, -34.93), Vector3.new(-47.53, -91.19, -42.53),
	Vector3.new(-58.04, -91.25, -48.55), Vector3.new(-66.63, -90.87, -52.34), Vector3.new(-76.55, -90.73, -50.85),
	Vector3.new(-85.38, -95.27, -49.52), Vector3.new(-99.27, -95.11, -48.78), Vector3.new(-110.81, -95.58, -51.84),
	Vector3.new(-124.97, -95.13, -57.73), Vector3.new(-134.51, -95.33, -62.61), Vector3.new(-144.35, -95.10, -69.41),
	Vector3.new(-154.76, -95.30, -77.76), Vector3.new(-163.28, -95.31, -84.59), Vector3.new(-175.12, -95.15, -94.08),
	Vector3.new(-184.42, -95.18, -101.54), Vector3.new(-184.93, -95.28, -101.95), Vector3.new(-199.18, -95.31, -113.38),
	Vector3.new(-208.91, -95.22, -121.18), Vector3.new(-218.07, -95.37, -127.81), Vector3.new(-228.34, -95.19, -126.67),
	Vector3.new(-241.35, -95.80, -116.92), Vector3.new(-251.36, -95.26, -105.34), Vector3.new(-260.85, -99.63, -94.36),
	Vector3.new(-269.29, -99.56, -84.59), Vector3.new(-277.84, -99.26, -74.70), Vector3.new(-296.81, -96.97, -62.82),
	Vector3.new(-296.02, -97.61, -63.18), Vector3.new(-303.04, -95.14, -59.77), Vector3.new(-317.35, -95.05, -56.19),
	Vector3.new(-328.10, -91.72, -54.46), Vector3.new(-338.29, -91.02, -51.19), Vector3.new(-343.28, -91.02, -43.15),
	Vector3.new(-338.78, -91.02, -50.49), Vector3.new(-343.94, -91.02, -42.14), Vector3.new(-339.29, -91.02, -49.76),
	Vector3.new(-344.00, -91.02, -42.18), Vector3.new(-339.45, -91.02, -49.58), Vector3.new(-343.56, -91.02, -42.97),
	Vector3.new(-339.79, -91.02, -49.12), Vector3.new(-344.13, -91.02, -42.11), Vector3.new(-339.49, -91.02, -49.72),
	Vector3.new(-344.51, -91.02, -41.63), Vector3.new(-339.85, -91.02, -49.15), Vector3.new(-335.26, -91.02, -60.21),
	Vector3.new(-330.49, -90.97, -72.47), Vector3.new(-327.27, -90.09, -85.28), Vector3.new(-324.26, -86.93, -99.02),
	Vector3.new(-319.71, -85.38, -108.98), Vector3.new(-312.95, -81.57, -111.32), Vector3.new(-309.49, -79.18, -106.98),
	Vector3.new(-305.59, -76.57, -99.88), Vector3.new(-297.07, -75.33, -97.11), Vector3.new(-290.01, -72.67, -95.05),
	Vector3.new(-280.86, -70.67, -92.38), Vector3.new(-272.70, -69.83, -86.23), Vector3.new(-264.33, -71.38, -82.69),
	Vector3.new(-254.59, -71.14, -78.14), Vector3.new(-244.52, -71.66, -75.20), Vector3.new(-235.69, -71.66, -75.13),
	Vector3.new(-239.29, -71.66, -80.37), Vector3.new(-240.75, -71.66, -74.99), Vector3.new(-234.75, -71.66, -75.82),
	Vector3.new(-238.95, -71.66, -81.32), Vector3.new(-244.25, -71.66, -75.88), Vector3.new(-236.63, -71.66, -74.09),
	Vector3.new(-238.20, -71.66, -80.76), Vector3.new(-242.74, -71.66, -75.31), Vector3.new(-235.91, -71.66, -73.80),
	Vector3.new(-239.51, -71.66, -79.95), Vector3.new(-240.68, -71.67, -74.26), Vector3.new(-235.42, -71.66, -76.58),
	Vector3.new(-239.40, -71.66, -80.20), Vector3.new(-251.40, -71.44, -80.53), Vector3.new(-261.87, -71.34, -82.40),
	Vector3.new(-269.62, -70.14, -84.82), Vector3.new(-279.70, -70.10, -90.02), Vector3.new(-286.30, -71.44, -93.42),
	Vector3.new(-292.97, -73.93, -96.30), Vector3.new(-300.06, -75.34, -99.77), Vector3.new(-307.56, -77.54, -104.99),
	Vector3.new(-310.73, -79.36, -107.47), Vector3.new(-316.53, -83.12, -107.88), Vector3.new(-321.19, -86.00, -102.67),
	Vector3.new(-325.21, -86.12, -99.97), Vector3.new(-326.19, -88.09, -92.36), Vector3.new(-327.75, -90.81, -82.75),
	Vector3.new(-329.79, -91.01, -75.97), Vector3.new(-332.02, -91.01, -66.12), Vector3.new(-334.45, -91.02, -55.15),
	Vector3.new(-341.37, -91.02, -47.97), Vector3.new(-342.53, -91.02, -40.31), Vector3.new(-342.44, -91.01, -32.48),
	Vector3.new(-342.34, -91.02, -24.15), Vector3.new(-343.19, -91.00, -16.19), Vector3.new(-344.22, -90.27, -8.33),
	Vector3.new(-347.89, -89.17, -2.00), Vector3.new(-351.91, -88.62, -1.05), Vector3.new(-361.44, -90.12, -0.02),
	Vector3.new(-371.80, -88.75, 1.10), Vector3.new(-381.00, -87.00, 1.26), Vector3.new(-393.63, -87.00, 1.67),
	Vector3.new(-401.60, -87.00, 1.48), Vector3.new(-406.70, -87.18, 2.02), Vector3.new(-408.23, -87.68, 3.36),
	Vector3.new(-418.42, -87.00, 2.79), Vector3.new(-427.45, -85.42, 1.46), Vector3.new(-436.88, -83.04, -0.68),
	Vector3.new(-446.90, -83.00, -6.12), Vector3.new(-453.56, -83.01, -13.58), Vector3.new(-460.15, -83.63, -19.35),
	Vector3.new(-465.34, -83.76, -25.16), Vector3.new(-471.95, -83.51, -27.72), Vector3.new(-481.45, -84.01, -27.07),
	Vector3.new(-487.77, -84.50, -25.15), Vector3.new(-492.79, -84.07, -20.44), Vector3.new(-493.70, -83.25, -15.08),
	Vector3.new(-501.15, -83.25, -6.38), Vector3.new(-507.33, -83.02, -1.49), Vector3.new(-514.35, -83.00, 2.40),
	Vector3.new(-522.85, -83.03, 4.07), Vector3.new(-531.68, -82.72, 3.61), Vector3.new(-537.20, -80.34, 2.85),
	Vector3.new(-544.36, -79.38, 3.42), Vector3.new(-550.98, -79.14, 6.24), Vector3.new(-558.95, -79.16, 8.58),
	Vector3.new(-566.51, -78.92, 12.69), Vector3.new(-572.64, -76.77, 15.73), Vector3.new(-580.24, -75.94, 19.89),
	Vector3.new(-588.26, -75.28, 23.09), Vector3.new(-594.61, -73.25, 28.17), Vector3.new(-599.59, -73.82, 32.82),
	Vector3.new(-606.67, -73.39, 36.11), Vector3.new(-613.82, -72.78, 37.84), Vector3.new(-619.51, -72.55, 40.37),
	Vector3.new(-625.00, -73.01, 44.11), Vector3.new(-630.87, -72.61, 48.82), Vector3.new(-633.44, -72.11, 51.85),
	Vector3.new(-636.66, -71.63, 55.64), Vector3.new(-635.17, -71.33, 61.95), Vector3.new(-634.55, -71.12, 72.08),
	Vector3.new(-633.94, -70.81, 79.84), Vector3.new(-634.31, -69.35, 87.67), Vector3.new(-634.12, -68.29, 94.13),
	Vector3.new(-633.55, -67.77, 101.40), Vector3.new(-634.95, -68.33, 108.17), Vector3.new(-635.74, -68.77, 114.21),
	Vector3.new(-639.19, -68.73, 120.53), Vector3.new(-642.32, -68.71, 126.77), Vector3.new(-644.58, -69.18, 134.54),
	Vector3.new(-644.99, -68.05, 142.07), Vector3.new(-645.46, -67.46, 150.10), Vector3.new(-646.34, -65.66, 155.45),
	Vector3.new(-647.07, -63.77, 163.48), Vector3.new(-647.92, -63.02, 171.99), Vector3.new(-647.51, -63.05, 177.30),
	Vector3.new(-648.02, -63.05, 184.42), Vector3.new(-649.33, -63.16, 188.85), Vector3.new(-649.17, -63.24, 199.00),
	Vector3.new(-652.22, -64.35, 204.35), Vector3.new(-656.31, -66.70, 208.30), Vector3.new(-661.11, -70.84, 211.44),
	Vector3.new(-667.32, -71.58, 213.45), Vector3.new(-672.76, -72.48, 215.71), Vector3.new(-680.59, -71.90, 218.94),
	Vector3.new(-686.70, -71.14, 218.75), Vector3.new(-693.00, -70.88, 216.13), Vector3.new(-700.52, -68.59, 213.00),
	Vector3.new(-706.50, -67.95, 210.52), Vector3.new(-716.19, -68.23, 208.07), Vector3.new(-723.35, -67.25, 211.03),
	Vector3.new(-715.48, -68.22, 207.79), Vector3.new(-723.91, -67.20, 211.35), Vector3.new(-714.93, -68.25, 207.64),
	Vector3.new(-723.64, -67.19, 211.33), Vector3.new(-714.80, -68.20, 207.67), Vector3.new(-724.29, -67.10, 211.64),
	Vector3.new(-714.87, -68.21, 207.74), Vector3.new(-723.77, -67.13, 211.47), Vector3.new(-715.62, -68.19, 208.12),
	Vector3.new(-726.30, -67.04, 212.71), Vector3.new(-729.16, -65.59, 219.61), Vector3.new(-733.35, -63.12, 226.83),
	Vector3.new(-739.76, -62.67, 230.99), Vector3.new(-742.74, -59.40, 238.16), Vector3.new(-745.13, -56.46, 243.91),
	Vector3.new(-748.32, -53.51, 251.61), Vector3.new(-750.93, -51.47, 257.90), Vector3.new(-753.67, -50.15, 264.49),
	Vector3.new(-756.26, -47.49, 270.71), Vector3.new(-758.85, -45.65, 276.95), Vector3.new(-753.49, -43.45, 280.61),
	Vector3.new(-746.60, -43.03, 283.46), Vector3.new(-738.95, -39.57, 284.73), Vector3.new(-732.51, -39.18, 280.90),
	Vector3.new(-725.94, -38.78, 276.99), Vector3.new(-718.90, -35.89, 272.81), Vector3.new(-712.58, -34.35, 269.06),
	Vector3.new(-705.84, -31.18, 265.06), Vector3.new(-697.24, -31.31, 259.96), Vector3.new(-690.75, -28.94, 258.63),
	Vector3.new(-685.68, -25.29, 255.62), Vector3.new(-679.16, -21.87, 251.74), Vector3.new(-673.25, -18.18, 248.23),
	Vector3.new(-668.49, -16.02, 243.24), Vector3.new(-663.59, -12.96, 238.25), Vector3.new(-658.58, -8.85, 235.27),
	Vector3.new(-652.85, -4.89, 231.87), Vector3.new(-647.26, -3.04, 228.56), Vector3.new(-636.95, -3.00, 222.43),
	Vector3.new(-629.78, -3.00, 218.17), Vector3.new(-622.90, -3.00, 214.09), Vector3.new(-616.02, -3.00, 210.00),
	Vector3.new(-609.29, -3.00, 206.00), Vector3.new(-602.55, -3.00, 202.01), Vector3.new(-597.53, -3.00, 199.03),
	Vector3.new(-591.23, -3.00, 195.28), Vector3.new(-569.42, -3.00, 181.00), Vector3.new(-560.31, -3.00, 175.14),
	Vector3.new(-552.46, -3.00, 170.09), Vector3.new(-543.49, -3.00, 164.32), Vector3.new(-535.50, -3.00, 159.18),
	Vector3.new(-527.80, -2.99, 154.22), Vector3.new(-519.15, -2.35, 148.65), Vector3.new(-512.17, -2.44, 144.16),
	Vector3.new(-504.61, -3.00, 139.29), Vector3.new(-497.00, -3.07, 134.40), Vector3.new(-489.08, -3.00, 129.30),
	Vector3.new(-476.33, -3.00, 121.09), Vector3.new(-468.48, -4.28, 116.05), Vector3.new(-460.96, -7.01, 111.21),
	Vector3.new(-453.59, -6.99, 106.46), Vector3.new(-446.44, -7.00, 101.86), Vector3.new(-437.92, -7.00, 96.38),
	Vector3.new(-430.08, -7.00, 91.33), Vector3.new(-422.23, -7.01, 86.29), Vector3.new(-413.83, -7.00, 80.88),
	Vector3.new(-405.30, -3.95, 75.39), Vector3.new(-398.18, -3.00, 70.81), Vector3.new(-389.91, -3.00, 65.49),
	Vector3.new(-382.48, -3.00, 60.71), Vector3.new(-375.47, -3.00, 56.20), Vector3.new(-361.51, -3.00, 48.06),
	Vector3.new(-350.54, -3.00, 42.08), Vector3.new(-341.03, -3.17, 36.89), Vector3.new(-328.90, -7.00, 30.28),
	Vector3.new(-319.56, -7.40, 25.19), Vector3.new(-309.37, -7.51, 19.63), Vector3.new(-299.77, -7.37, 14.40),
	Vector3.new(-290.73, -7.08, 9.47), Vector3.new(-282.98, -7.01, 5.24), Vector3.new(-273.47, -7.01, 0.06),
	Vector3.new(-265.13, -7.00, -4.49), Vector3.new(-256.06, -7.01, -9.43), Vector3.new(-247.29, -7.00, -14.22),
	Vector3.new(-240.54, -3.17, -20.24), Vector3.new(-235.61, -3.00, -28.92), Vector3.new(-227.02, -3.00, -37.22),
	Vector3.new(-220.65, -4.03, -47.37), Vector3.new(-212.91, -4.33, -57.41), Vector3.new(-210.64, -4.25, -72.15),
	Vector3.new(-212.94, -4.23, -85.45), Vector3.new(-214.59, -4.23, -94.98), Vector3.new(-209.84, -6.06, -103.67),
	Vector3.new(-204.07, -4.23, -111.86), Vector3.new(-194.05, -4.24, -115.03), Vector3.new(-182.65, -4.25, -119.47),
	Vector3.new(-172.51, -4.78, -121.23), Vector3.new(-165.11, -8.62, -124.60), Vector3.new(-163.06, -11.11, -124.19),
	Vector3.new(-157.87, -18.57, -121.83), Vector3.new(-154.72, -26.68, -121.25), Vector3.new(-149.49, -33.92, -119.13)
}

local function StartGoldFarm()
	if GOLD_FARM_RUNNING then return end
	
	GOLD_FARM_RUNNING = true
	
	-- Используем встроенные координаты
	game:GetService("StarterGui"):SetCore("SendNotification", {
		Title = "BoogaX",
		Text = "💰 Gold Farm Started!\n✅ Following " .. #GOLD_FARM_COORDINATES .. " waypoints",
		Duration = 3
	})
	
	task.spawn(function()
		local player = game:GetService("Players").LocalPlayer
		local RunService = game:GetService("RunService")
		
		-- Кэшированные переменные
		local currentGold = nil
		local goldPos = nil
		local arrivalTime = 0
		local maxWaitTime = 15
		local currentWaypointIndex = 1
		local lastMoveTime = 0
		local lastGoldSearchTime = 0
		local goldSearchInterval = 1.5 -- Ищем золото раз в 1.5 секунды
		local humanoid = nil
		local rootPart = nil
		local char = nil
		
		-- Функция для обновления ссылок на персонажа
		local function updateCharacter()
			char = player.Character
			if char then
				humanoid = char:FindFirstChild("Humanoid")
				rootPart = char:FindFirstChild("HumanoidRootPart")
				return humanoid and rootPart
			end
			return false
		end
		
		-- Инициализация
		if not updateCharacter() then
			GOLD_FARM_RUNNING = false
			return
		end
		
		local connection
		connection = RunService.Heartbeat:Connect(function()
			if not GOLD_FARM_ENABLED or not GOLD_FARM_RUNNING then
				connection:Disconnect()
				-- Убираем подсветку при остановке
				if currentGoldHighlight then
					currentGoldHighlight:Destroy()
					currentGoldHighlight = nil
				end
				game:GetService("StarterGui"):SetCore("SendNotification", {
					Title = "BoogaX",
					Text = "💰 Gold Farm Stopped!",
					Duration = 3
				})
				return
			end
			
			-- Проверяем персонажа
			if not char or not char.Parent or not humanoid or not rootPart then
				if not updateCharacter() then
					return
				end
			end
			
			local currentTime = tick()
			local rootPos = rootPart.Position
			
			-- Оптимизированный поиск золота (реже)
			if currentTime - lastGoldSearchTime > goldSearchInterval then
				lastGoldSearchTime = currentTime
				
				-- Проверяем текущее золото
				if currentGold and currentGold.Parent then
					goldPos = currentGold:IsA("Model") and currentGold:GetModelCFrame().Position or currentGold.Position
					local distance = (rootPos - goldPos).Magnitude
					
					-- Если золото слишком далеко, сбрасываем
					if distance > 50 then
						currentGold = nil
						goldPos = nil
					end
				end
				
				-- Ищем новое золото только если текущего нет
				if not currentGold or not currentGold.Parent then
					currentGold, _ = FindNearestGoldOre()
					if currentGold and currentGold.Parent then
						goldPos = currentGold:IsA("Model") and currentGold:GetModelCFrame().Position or currentGold.Position
					end
				end
			end
			
			-- Обработка золота
			if currentGold and currentGold.Parent and goldPos then
				local distance = (rootPos - goldPos).Magnitude
				
				if distance < 150 then -- Увеличено с 50 до 150
					-- Добавляем подсветку только один раз
					if not currentGoldHighlight or currentGoldHighlight.Parent ~= currentGold then
						if currentGoldHighlight then
							currentGoldHighlight:Destroy()
						end
						pcall(function()
							local highlight = Instance.new("Highlight")
							highlight.FillColor = Color3.fromRGB(255, 215, 0)
							highlight.OutlineColor = Color3.fromRGB(255, 165, 0)
							highlight.FillTransparency = 0.5
							highlight.OutlineTransparency = 0
							highlight.Parent = currentGold
							currentGoldHighlight = highlight
						end)
					end
					
					if distance > 5 then
						humanoid:MoveTo(goldPos)
						arrivalTime = 0
					else
						if arrivalTime == 0 then
							arrivalTime = currentTime
						end
						
						if currentTime - arrivalTime > maxWaitTime then
							local tempMarker = Instance.new("BoolValue")
							tempMarker.Name = "_SkipMarker"
							tempMarker.Parent = currentGold
							task.delay(60, function()
								if tempMarker and tempMarker.Parent then
									tempMarker:Destroy()
								end
							end)
							currentGold = nil
							goldPos = nil
							arrivalTime = 0
						end
					end
				else
					currentGold = nil
					goldPos = nil
				end
			end
			
			-- Движение по координатам (если нет золота)
			if not currentGold or not currentGold.Parent then
				if currentWaypointIndex > #GOLD_FARM_COORDINATES then
					currentWaypointIndex = 1
				end
				
				local currentWaypoint = GOLD_FARM_COORDINATES[currentWaypointIndex]
				if currentWaypoint then
					local distance = (rootPos - currentWaypoint).Magnitude
					
					-- Оптимизированное обновление движения
					if currentTime - lastMoveTime > 0.3 or humanoid.MoveDirection.Magnitude < 0.1 then
						humanoid:MoveTo(currentWaypoint)
						lastMoveTime = currentTime
					end
					
					if distance < 3 then
						currentWaypointIndex = currentWaypointIndex + 1
						if currentWaypointIndex <= #GOLD_FARM_COORDINATES then
							local nextWaypoint = GOLD_FARM_COORDINATES[currentWaypointIndex]
							if nextWaypoint then
								humanoid:MoveTo(nextWaypoint)
								lastMoveTime = currentTime
							end
						end
					end
				end
			end
		end)
	end)
end

local function StopGoldFarm()
	GOLD_FARM_RUNNING = false
	
	-- Убираем подсветку
	if currentGoldHighlight then
		currentGoldHighlight:Destroy()
		currentGoldHighlight = nil
	end
end

-- UI для Gold Farm
CreateToggle("Auto Farm Gold", false, function(state)
	GOLD_FARM_ENABLED = state
	
	if state then
		StartGoldFarm()
	else
		StopGoldFarm()
	end
end, Tabs.AutoFarm)

-- ============================================
-- Fast Farm Gold
-- ============================================

local FAST_GOLD_FARM_ENABLED = false
local FAST_GOLD_FARM_RUNNING = false
local FAST_GOLD_FARM_MARKERS = {} -- Визуальные маркеры маршрута
local FAST_GOLD_FARM_SHOW_MARKERS = false -- Показывать маркеры маршрута
local FAST_GOLD_FARM_SPEED = 21.5 -- Скорость полета Fast Farm Gold

-- Координаты для быстрого фарма золота (JSON формат)
local FAST_GOLD_JSON_DATA = [[
{"waits":[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],"types":["afk","afk","fly","afk","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","afk","fly","fly","fly","fly","afk","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","afk","fly","afk","fly","fly","fly","fly","fly","fly","afk","fly","fly","fly","fly","fly","fly","fly","afk","fly","fly","fly","fly","afk","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","afk","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","afk","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","afk","afk","afk","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","afk","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","afk","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","afk","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","afk","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","afk","fly","afk","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","afk","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","afk","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","afk","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","afk","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","afk","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","afk","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","afk","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","afk","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly","fly"],"position":[{"Y":-34.95,"X":-140.96,"Z":-164.22},{"Y":-27.63,"X":-107.97,"Z":-180.2},{"Y":-24.63,"X":-122.51,"Z":-193.32},{"Y":-19.22,"X":-122.2,"Z":-198.15},{"Y":-6.15,"X":-119.12,"Z":-207.35},{"Y":-3.01,"X":-109.19,"Z":-225.22},{"Y":-3,"X":-95.6,"Z":-231.89},{"Y":-3,"X":-69.4,"Z":-243.62},{"Y":-3.01,"X":-36.61,"Z":-260.67},{"Y":-3,"X":-10.26,"Z":-271.56},{"Y":-3,"X":22.83,"Z":-280.67},{"Y":-3,"X":52.03,"Z":-282.81},{"Y":-3,"X":78.43,"Z":-283.75},{"Y":-3,"X":105.88,"Z":-283.01},{"Y":-4.17,"X":129.94,"Z":-278.9},{"Y":-3.86,"X":153.98,"Z":-267.99},{"Y":-3.27,"X":175.71,"Z":-254.59},{"Y":-4.07,"X":199.64,"Z":-237.54},{"Y":-3.01,"X":215.5,"Z":-215.5},{"Y":-3.01,"X":229.27,"Z":-194.71},{"Y":-3.01,"X":239.7,"Z":-171.24},{"Y":-3.01,"X":249.5,"Z":-151.01},{"Y":-1.85,"X":260.67,"Z":-129.48},{"Y":-3.01,"X":273.38,"Z":-108.02},{"Y":-7.03,"X":284.47,"Z":-87.68},{"Y":-7.45,"X":295.7,"Z":-69.92},{"Y":-7.1,"X":309.01,"Z":-48.46},{"Y":-7.48,"X":322.76,"Z":-27.15},{"Y":-7.16,"X":335.89,"Z":-6.81},{"Y":-7.29,"X":348.94,"Z":13.42},{"Y":-7.03,"X":360.62,"Z":31.51},{"Y":-7.01,"X":373.8,"Z":51.1},{"Y":-7.01,"X":387.41,"Z":67.4},{"Y":-7.18,"X":402.33,"Z":85.27},{"Y":-7.1,"X":417.36,"Z":101.31},{"Y":-7.69,"X":437.81,"Z":119.57},{"Y":8.13,"X":456.21,"Z":135.9},{"Y":14.77,"X":460.14,"Z":139.77},{"Y":16.48,"X":464.31,"Z":146.48},{"Y":12.99,"X":477.46,"Z":157.15},{"Y":13.62,"X":489.25,"Z":168.69},{"Y":12.88,"X":492.53,"Z":191.92},{"Y":13.14,"X":482.98,"Z":210.49},{"Y":11.49,"X":470.19,"Z":229.98},{"Y":12.29,"X":488.08,"Z":218.88},{"Y":6.12,"X":497.76,"Z":223.51},{"Y":-3.01,"X":506.83,"Z":234.49},{"Y":-3.01,"X":522.81,"Z":254.59},{"Y":-3.01,"X":543.39,"Z":274.35},{"Y":-3.01,"X":560.59,"Z":292.26},{"Y":-3.01,"X":578.98,"Z":311.69},{"Y":-3.01,"X":598.79,"Z":324.22},{"Y":-3.01,"X":623.18,"Z":337.06},{"Y":-3.01,"X":645.61,"Z":348.54},{"Y":-3.01,"X":666.94,"Z":359.46},{"Y":-3.01,"X":689.2,"Z":368.21},{"Y":-3.53,"X":722.4,"Z":378.92},{"Y":-7.11,"X":746.15,"Z":387.98},{"Y":-7.06,"X":767.67,"Z":398.26},{"Y":-7.75,"X":788.57,"Z":408.93},{"Y":-7.34,"X":811.62,"Z":419.74},{"Y":-7.71,"X":832.11,"Z":429.35},{"Y":-7.52,"X":852.44,"Z":438.88},{"Y":-7.09,"X":872.03,"Z":448.06},{"Y":-7.41,"X":892.23,"Z":458.62},{"Y":-2.99,"X":908.56,"Z":467.94},{"Y":0.42,"X":928.33,"Z":471.96},{"Y":1.41,"X":956.57,"Z":471.52},{"Y":-0.85,"X":981.13,"Z":473.23},{"Y":-0.77,"X":1004.25,"Z":477.69},{"Y":-1.24,"X":1026.5,"Z":484.14},{"Y":0.76,"X":1050.62,"Z":493.94},{"Y":2.67,"X":1072.63,"Z":511.86},{"Y":1.25,"X":1090.52,"Z":529.11},{"Y":-1.95,"X":1108.31,"Z":548.15},{"Y":-3.2,"X":1127.35,"Z":566.6},{"Y":-3.22,"X":1152.88,"Z":574.87},{"Y":-5.83,"X":1176.92,"Z":564.89},{"Y":-8.5,"X":1195.29,"Z":544.19},{"Y":-11.24,"X":1210.2,"Z":531.34},{"Y":-12.26,"X":1215.06,"Z":521.15},{"Y":-15.01,"X":1205.76,"Z":500.93},{"Y":-15.18,"X":1196.91,"Z":483.86},{"Y":-15.4,"X":1188.05,"Z":464.97},{"Y":-15.02,"X":1185.45,"Z":473.44},{"Y":-15.08,"X":1168.25,"Z":483.35},{"Y":-15.01,"X":1174.63,"Z":481.57},{"Y":-15.01,"X":1186.44,"Z":478.38},{"Y":-15.01,"X":1200.61,"Z":491.99},{"Y":-15.01,"X":1210.51,"Z":511.34},{"Y":-12.26,"X":1216.19,"Z":529.31},{"Y":-11.59,"X":1227.94,"Z":543.78},{"Y":-15.46,"X":1241.72,"Z":566.99},{"Y":-15.81,"X":1245.82,"Z":578.49},{"Y":-15.52,"X":1259.37,"Z":594.93},{"Y":-15.54,"X":1276.19,"Z":609.92},{"Y":-16.11,"X":1286.67,"Z":620.16},{"Y":-16.72,"X":1299.51,"Z":638.26},{"Y":-15.66,"X":1310.06,"Z":654.08},{"Y":-15.97,"X":1309.16,"Z":667.61},{"Y":-19.01,"X":1284.94,"Z":685.79},{"Y":-18.97,"X":1295.11,"Z":679.26},{"Y":-15.63,"X":1311.37,"Z":668.42},{"Y":-15.54,"X":1329.01,"Z":667.93},{"Y":-15.97,"X":1341.24,"Z":673.08},{"Y":-19.01,"X":1357.9,"Z":677.09},{"Y":-17.89,"X":1351.09,"Z":674.65},{"Y":-15.73,"X":1333.56,"Z":669.45},{"Y":-15.7,"X":1319.92,"Z":660.41},{"Y":-15.98,"X":1308.39,"Z":648.71},{"Y":-16.67,"X":1294.16,"Z":632.69},{"Y":-15.76,"X":1281.45,"Z":617.07},{"Y":-15.53,"X":1265.99,"Z":600.9},{"Y":-15.59,"X":1250.47,"Z":584.68},{"Y":-15.1,"X":1239.84,"Z":560.5},{"Y":-11.7,"X":1226,"Z":542.63},{"Y":-11.67,"X":1213.48,"Z":533.05},{"Y":-9.35,"X":1197.03,"Z":538.68},{"Y":-7.22,"X":1184,"Z":553.15},{"Y":-5.15,"X":1171.35,"Z":568.48},{"Y":-2.95,"X":1158.08,"Z":583.03},{"Y":-1.37,"X":1144.35,"Z":587.77},{"Y":-2.28,"X":1127.92,"Z":574.44},{"Y":-2.06,"X":1110.12,"Z":557.2},{"Y":-0.81,"X":1092.33,"Z":538.33},{"Y":2.27,"X":1078.74,"Z":522.82},{"Y":2.51,"X":1065.2,"Z":505.8},{"Y":-1.05,"X":1052.09,"Z":483.54},{"Y":-2.14,"X":1041.72,"Z":459.87},{"Y":1.84,"X":1030.46,"Z":434.15},{"Y":2.66,"X":1019.37,"Z":408.85},{"Y":0.44,"X":1016.99,"Z":389.71},{"Y":-7.98,"X":1017.42,"Z":364.05},{"Y":-7.01,"X":1010.39,"Z":344.32},{"Y":-7.16,"X":1001.21,"Z":318.13},{"Y":-7.29,"X":991.37,"Z":296.23},{"Y":-7.8,"X":979.56,"Z":269.95},{"Y":-7.49,"X":966.93,"Z":241.84},{"Y":-7.32,"X":953.05,"Z":213.41},{"Y":-7.27,"X":917.91,"Z":157.6},{"Y":-7.15,"X":883.26,"Z":103.81},{"Y":-7.8,"X":853.66,"Z":58.56},{"Y":-7.44,"X":821.82,"Z":10.69},{"Y":-7.55,"X":799.3,"Z":-23.5},{"Y":-7.08,"X":770.53,"Z":-59.96},{"Y":-7.07,"X":737.89,"Z":-96.39},{"Y":-7.43,"X":722.33,"Z":-129.11},{"Y":1.41,"X":714.51,"Z":-154.58},{"Y":10.74,"X":708.99,"Z":-168.13},{"Y":21.93,"X":697.74,"Z":-177.67},{"Y":29.06,"X":691.02,"Z":-183.96},{"Y":32.21,"X":684.3,"Z":-182.76},{"Y":32.93,"X":666.51,"Z":-183.18},{"Y":32.92,"X":677.33,"Z":-184.01},{"Y":28.34,"X":698.02,"Z":-195.96},{"Y":24.74,"X":713.49,"Z":-209.02},{"Y":25.03,"X":718.35,"Z":-215.63},{"Y":24.73,"X":726.52,"Z":-232.12},{"Y":22.14,"X":730.02,"Z":-250.52},{"Y":24.32,"X":728,"Z":-270.05},{"Y":22.78,"X":723.57,"Z":-290.26},{"Y":29.44,"X":713.39,"Z":-300.47},{"Y":36.91,"X":696.11,"Z":-314.72},{"Y":45.59,"X":691.38,"Z":-319.99},{"Y":51.94,"X":680.32,"Z":-324.65},{"Y":54.37,"X":665.66,"Z":-332.71},{"Y":53.3,"X":656.33,"Z":-349.59},{"Y":66.23,"X":666.17,"Z":-363.64},{"Y":75.09,"X":671.26,"Z":-371.58},{"Y":77.62,"X":673.97,"Z":-383.78},{"Y":83.91,"X":683.32,"Z":-395.85},{"Y":83.52,"X":673.56,"Z":-403.4},{"Y":78.08,"X":660.09,"Z":-408.72},{"Y":63.83,"X":651.84,"Z":-418.83},{"Y":52.48,"X":636.78,"Z":-428.92},{"Y":49.02,"X":618.57,"Z":-428.07},{"Y":52.23,"X":596.57,"Z":-427.94},{"Y":48.41,"X":582.25,"Z":-426.6},{"Y":44.33,"X":567.69,"Z":-425.76},{"Y":33.05,"X":553.97,"Z":-421.99},{"Y":27.97,"X":546.56,"Z":-418.35},{"Y":19.42,"X":543.23,"Z":-413.47},{"Y":11.33,"X":538.24,"Z":-406.6},{"Y":9.18,"X":541.12,"Z":-395.31},{"Y":11.67,"X":555.31,"Z":-392.55},{"Y":7.73,"X":570.67,"Z":-390.01},{"Y":-2.29,"X":587.59,"Z":-385.64},{"Y":-5.19,"X":599.74,"Z":-381.91},{"Y":-7.55,"X":617.49,"Z":-381.29},{"Y":-7.16,"X":632.24,"Z":-369.94},{"Y":-7.49,"X":617.03,"Z":-359.59},{"Y":-8.43,"X":605.77,"Z":-363.24},{"Y":-7.65,"X":597.71,"Z":-375.1},{"Y":-0.49,"X":584.53,"Z":-384.47},{"Y":4.94,"X":575.95,"Z":-388.37},{"Y":8.28,"X":569,"Z":-392.38},{"Y":10.8,"X":558.39,"Z":-392.69},{"Y":9.97,"X":551.38,"Z":-386.84},{"Y":7.48,"X":552.22,"Z":-375.25},{"Y":1.05,"X":547.85,"Z":-365.65},{"Y":-3.65,"X":537.04,"Z":-361.42},{"Y":-5.34,"X":524.66,"Z":-358.01},{"Y":-7.19,"X":510.3,"Z":-356.69},{"Y":-7.74,"X":487.16,"Z":-366.42},{"Y":-7.35,"X":472.55,"Z":-372.75},{"Y":-7.03,"X":456.52,"Z":-380.46},{"Y":-7.03,"X":438.36,"Z":-389.05},{"Y":-7.14,"X":420.08,"Z":-397.68},{"Y":-7.72,"X":403.33,"Z":-406.17},{"Y":-7.49,"X":381.95,"Z":-416.59},{"Y":-7.28,"X":367.94,"Z":-423.16},{"Y":-7.75,"X":346.84,"Z":-433.06},{"Y":-7.22,"X":326.29,"Z":-442.69},{"Y":-7.86,"X":306.9,"Z":-451.66},{"Y":-7.01,"X":282.87,"Z":-464},{"Y":-7.46,"X":263.28,"Z":-473.93},{"Y":-7.61,"X":241.5,"Z":-481.68},{"Y":-7.26,"X":220.44,"Z":-488.86},{"Y":-7.2,"X":197.39,"Z":-493.87},{"Y":-7.15,"X":179.95,"Z":-497.97},{"Y":-7.73,"X":175.25,"Z":-513.91},{"Y":-3.48,"X":169.71,"Z":-537.12},{"Y":-3.01,"X":156.1,"Z":-549.3},{"Y":-3.01,"X":137.13,"Z":-559.44},{"Y":-3.01,"X":114.22,"Z":-568.48},{"Y":-3.98,"X":90.06,"Z":-570.56},{"Y":-7.12,"X":72.75,"Z":-567.98},{"Y":-7.31,"X":49.44,"Z":-563.73},{"Y":-7.07,"X":23.79,"Z":-559.05},{"Y":-3.62,"X":-3.98,"Z":-552.84},{"Y":-3.01,"X":-20.85,"Z":-549.9},{"Y":-3.01,"X":-41.32,"Z":-550.65},{"Y":-3.01,"X":-58.56,"Z":-555.35},{"Y":-3.01,"X":-76.31,"Z":-560.18},{"Y":1.57,"X":-105.57,"Z":-569.9},{"Y":4.25,"X":-128.05,"Z":-575.93},{"Y":4.99,"X":-146.86,"Z":-584.35},{"Y":4.99,"X":-164.39,"Z":-593.68},{"Y":4.99,"X":-181.98,"Z":-603.47},{"Y":12.47,"X":-203.38,"Z":-619.47},{"Y":18.48,"X":-204.97,"Z":-624.23},{"Y":5.99,"X":-200.71,"Z":-614.37},{"Y":5.59,"X":-210.87,"Z":-605.99},{"Y":3.45,"X":-226.22,"Z":-604.4},{"Y":0.49,"X":-242.83,"Z":-602.43},{"Y":-3,"X":-264.43,"Z":-600.03},{"Y":-3.04,"X":-281.49,"Z":-599.84},{"Y":-3.01,"X":-306.34,"Z":-603.83},{"Y":-3.01,"X":-327.88,"Z":-610.44},{"Y":-3.01,"X":-347.03,"Z":-615.14},{"Y":-3.03,"X":-361.7,"Z":-616.94},{"Y":-8.46,"X":-384.4,"Z":-616.07},{"Y":-22.09,"X":-395.59,"Z":-609.92},{"Y":-27.14,"X":-405.68,"Z":-596.69},{"Y":-28.11,"X":-412.44,"Z":-579.87},{"Y":-35.6,"X":-417.69,"Z":-561.21},{"Y":-38.74,"X":-414.2,"Z":-551.14},{"Y":-41.74,"X":-397.45,"Z":-553.32},{"Y":-43.62,"X":-379.11,"Z":-558.16},{"Y":-44.02,"X":-367.59,"Z":-561.06},{"Y":-47.01,"X":-350.99,"Z":-564.19},{"Y":-47.37,"X":-331.26,"Z":-566.18},{"Y":-48.55,"X":-316.8,"Z":-567.98},{"Y":-56.41,"X":-303.73,"Z":-571.28},{"Y":-57.2,"X":-287.8,"Z":-569.69},{"Y":-57.18,"X":-279.11,"Z":-563.02},{"Y":-56.57,"X":-263.62,"Z":-555.96},{"Y":-58.14,"X":-246.39,"Z":-548.37},{"Y":-59.5,"X":-231.76,"Z":-542.23},{"Y":-60.37,"X":-216.95,"Z":-537.83},{"Y":-59.62,"X":-206.16,"Z":-537.34},{"Y":-63.03,"X":-187.18,"Z":-544.19},{"Y":-63.77,"X":-168.42,"Z":-540.3},{"Y":-63.38,"X":-155.99,"Z":-538.33},{"Y":-60.92,"X":-137.81,"Z":-537.39},{"Y":-56.01,"X":-129.69,"Z":-525.29},{"Y":-57.77,"X":-115.61,"Z":-521.27},{"Y":-61.21,"X":-98.19,"Z":-518.84},{"Y":-64.32,"X":-83.53,"Z":-518.09},{"Y":-66.95,"X":-69.08,"Z":-518.48},{"Y":-67.41,"X":-53.67,"Z":-519.37},{"Y":-68.62,"X":-39.47,"Z":-521.29},{"Y":-70.05,"X":-22.75,"Z":-514.62},{"Y":-71.03,"X":-13.61,"Z":-501.6},{"Y":-71.01,"X":-13.82,"Z":-486.33},{"Y":-72.05,"X":-17.45,"Z":-470.87},{"Y":-72.61,"X":-21.77,"Z":-456.34},{"Y":-73.18,"X":-27.38,"Z":-435.26},{"Y":-72.94,"X":-33.23,"Z":-416.09},{"Y":-72.9,"X":-34.88,"Z":-404.47},{"Y":-74.49,"X":-34.56,"Z":-389.93},{"Y":-79.35,"X":-24.51,"Z":-382.37},{"Y":-87.02,"X":-8.78,"Z":-369.33},{"Y":-91.01,"X":-11.35,"Z":-362.52},{"Y":-92.64,"X":-21.81,"Z":-361.74},{"Y":-91.2,"X":-32.48,"Z":-366.18},{"Y":-90.51,"X":-44.43,"Z":-371.42},{"Y":-90.28,"X":-44.86,"Z":-382.27},{"Y":-101.5,"X":-44.7,"Z":-392.5},{"Y":-103.01,"X":-50.02,"Z":-406.64},{"Y":-103.01,"X":-62.41,"Z":-416.08},{"Y":-103.01,"X":-79.28,"Z":-419.43},{"Y":-103.01,"X":-94.62,"Z":-424.95},{"Y":-103.01,"X":-117.12,"Z":-434.13},{"Y":-103.01,"X":-123.07,"Z":-449.58},{"Y":-103.01,"X":-125.21,"Z":-468.09},{"Y":-103.01,"X":-134.19,"Z":-481.37},{"Y":-103.01,"X":-148.41,"Z":-492.18},{"Y":-103.01,"X":-163.7,"Z":-501.88},{"Y":-103.29,"X":-178.93,"Z":-506.18},{"Y":-103.92,"X":-190.97,"Z":-500.78},{"Y":-103.12,"X":-194.42,"Z":-487.01},{"Y":-103.37,"X":-190.38,"Z":-473.48},{"Y":-104.14,"X":-189.03,"Z":-454.91},{"Y":-103.55,"X":-189.66,"Z":-470.31},{"Y":-103.01,"X":-192.12,"Z":-484.21},{"Y":-103.21,"X":-193.45,"Z":-497.51},{"Y":-103.01,"X":-183.76,"Z":-505.84},{"Y":-103.01,"X":-168.66,"Z":-503.74},{"Y":-103.01,"X":-155.27,"Z":-497.49},{"Y":-103.01,"X":-144.38,"Z":-487.64},{"Y":-103.01,"X":-135.63,"Z":-475.42},{"Y":-103.01,"X":-127.15,"Z":-462.8},{"Y":-103.01,"X":-119.62,"Z":-450.69},{"Y":-103.01,"X":-111.8,"Z":-437.35},{"Y":-103.01,"X":-103,"Z":-425.73},{"Y":-103.01,"X":-90.51,"Z":-417.67},{"Y":-103.01,"X":-77.73,"Z":-411.03},{"Y":-103.01,"X":-46.23,"Z":-407.55},{"Y":-103.01,"X":-30.21,"Z":-412.54},{"Y":-103.01,"X":-16.1,"Z":-413.43},{"Y":-103.01,"X":2.32,"Z":-416.34},{"Y":-100.5,"X":16.29,"Z":-410.68},{"Y":-99.01,"X":20.1,"Z":-394.68},{"Y":-99.01,"X":22.79,"Z":-377.32},{"Y":-99.08,"X":35.6,"Z":-364.89},{"Y":-99.01,"X":47.7,"Z":-363.53},{"Y":-99.17,"X":29.19,"Z":-376.34},{"Y":-99.02,"X":23.5,"Z":-384.97},{"Y":-99.01,"X":18.7,"Z":-396.88},{"Y":-100.44,"X":15.9,"Z":-410.73},{"Y":-103.01,"X":8.61,"Z":-420.39},{"Y":-103.01,"X":-4.58,"Z":-421.49},{"Y":-103.01,"X":-17.7,"Z":-417.89},{"Y":-103.01,"X":-32.48,"Z":-413.82},{"Y":-103.01,"X":-44,"Z":-410.65},{"Y":-103.01,"X":-48.97,"Z":-404.69},{"Y":-99.98,"X":-43.64,"Z":-390.93},{"Y":-94.2,"X":-45.5,"Z":-386.22},{"Y":-90.09,"X":-44.85,"Z":-381.16},{"Y":-90.52,"X":-46.4,"Z":-372.84},{"Y":-91.84,"X":-38.77,"Z":-363.45},{"Y":-92.23,"X":-31.78,"Z":-352.61},{"Y":-91.69,"X":-25.84,"Z":-337.8},{"Y":-91.04,"X":-21.45,"Z":-323.4},{"Y":-91.94,"X":-14.39,"Z":-303.1},{"Y":-91.8,"X":-9.75,"Z":-284.92},{"Y":-88.1,"X":-4.8,"Z":-267.83},{"Y":-85.43,"X":-3.91,"Z":-255.1},{"Y":-87.01,"X":-7.87,"Z":-243.52},{"Y":-86.76,"X":-17.32,"Z":-236.45},{"Y":-87.02,"X":-30.15,"Z":-238.6},{"Y":-87.01,"X":-40.89,"Z":-240.41},{"Y":-84.69,"X":-46.23,"Z":-229.21},{"Y":-85.49,"X":-48.13,"Z":-217.55},{"Y":-83.24,"X":-41.95,"Z":-207.37},{"Y":-83.07,"X":-32.05,"Z":-198.27},{"Y":-83.26,"X":-22.87,"Z":-188.26},{"Y":-83.76,"X":-15.64,"Z":-177.76},{"Y":-83.06,"X":-9.25,"Z":-166.46},{"Y":-83.4,"X":-4.06,"Z":-154.78},{"Y":-83.01,"X":1.08,"Z":-140.26},{"Y":-83.01,"X":3.31,"Z":-124.58},{"Y":-83.01,"X":2.51,"Z":-110.89},{"Y":-83.01,"X":2.1,"Z":-98.5},{"Y":-83.01,"X":1.07,"Z":-86.28},{"Y":-82.31,"X":1.85,"Z":-71.23},{"Y":-78.12,"X":5.52,"Z":-61.11},{"Y":-75.03,"X":10.93,"Z":-49.78},{"Y":-75.01,"X":7.25,"Z":-37.97},{"Y":-75.68,"X":-15.16,"Z":-36.51},{"Y":-75.96,"X":-25.95,"Z":-41.91},{"Y":-75.01,"X":-30.04,"Z":-54.53},{"Y":-75.01,"X":-37.98,"Z":-64.68},{"Y":-75.07,"X":-51.29,"Z":-74.7},{"Y":-77.44,"X":-63.66,"Z":-78.89},{"Y":-83.06,"X":-71.44,"Z":-70.47},{"Y":-89.15,"X":-68.67,"Z":-58.03},{"Y":-91.64,"X":-64.75,"Z":-50.23},{"Y":-91.94,"X":-53.66,"Z":-43.86},{"Y":-91.19,"X":-39.17,"Z":-35.51},{"Y":-91.19,"X":-28.71,"Z":-25.07},{"Y":-91.14,"X":-20.35,"Z":-11.92},{"Y":-91.19,"X":-31.57,"Z":-28.88},{"Y":-91.19,"X":-40.53,"Z":-37.44},{"Y":-91.19,"X":-50.75,"Z":-43.79},{"Y":-91.45,"X":-59.45,"Z":-47.51},{"Y":-90.48,"X":-69.21,"Z":-53.82},{"Y":-86.85,"X":-70.94,"Z":-65.22},{"Y":-80.34,"X":-67.4,"Z":-75.18},{"Y":-76.39,"X":-57.16,"Z":-77.74},{"Y":-75.01,"X":-45.74,"Z":-70.73},{"Y":-75.01,"X":-36.43,"Z":-63.39},{"Y":-75.01,"X":-28.88,"Z":-53.86},{"Y":-75.92,"X":-24.69,"Z":-42.13},{"Y":-75.92,"X":-16.18,"Z":-35.78},{"Y":-75.05,"X":-3.23,"Z":-36.52},{"Y":-75.01,"X":9.77,"Z":-34.61},{"Y":-75.01,"X":21.61,"Z":-30.63},{"Y":-75.01,"X":32.5,"Z":-25.92},{"Y":-75.01,"X":42.59,"Z":-18.77},{"Y":-75.01,"X":51.82,"Z":-11.11},{"Y":-75.01,"X":62.01,"Z":-5.06},{"Y":-75.01,"X":72.54,"Z":-0.2},{"Y":-75.01,"X":84.09,"Z":4.65},{"Y":-75.01,"X":95.57,"Z":8.99},{"Y":-75.01,"X":105.84,"Z":13.45},{"Y":-75.01,"X":117.45,"Z":18.51},{"Y":-75.01,"X":127.6,"Z":22.92},{"Y":-75.01,"X":141.51,"Z":28.57},{"Y":-75,"X":136.74,"Z":26.44},{"Y":-75,"X":125.7,"Z":22.12},{"Y":-75,"X":115.31,"Z":17.26},{"Y":-75,"X":104.73,"Z":12.5},{"Y":-75,"X":91.72,"Z":6.65},{"Y":-75,"X":80.03,"Z":1.8},{"Y":-75,"X":68.93,"Z":-2.78},{"Y":-75,"X":56.09,"Z":-8.64},{"Y":-75,"X":44.43,"Z":-16.78},{"Y":-75,"X":35.84,"Z":-26.21},{"Y":-75,"X":28.3,"Z":-37.05},{"Y":-75.01,"X":22.49,"Z":-43.82},{"Y":-75.02,"X":12.66,"Z":-50.15},{"Y":-76.47,"X":6.03,"Z":-58.97},{"Y":-81.34,"X":2.76,"Z":-69.44},{"Y":-83.01,"X":1.18,"Z":-80.31},{"Y":-83.01,"X":0.38,"Z":-94.92},{"Y":-83.01,"X":1.08,"Z":-108.37},{"Y":-83.01,"X":1.74,"Z":-121.02},{"Y":-83.01,"X":2.42,"Z":-134.07},{"Y":-83.06,"X":0.19,"Z":-145.63},{"Y":-83.49,"X":-3.58,"Z":-158.13},{"Y":-83.15,"X":-8.46,"Z":-170.19},{"Y":-83.85,"X":-14.91,"Z":-180.06},{"Y":-83.32,"X":-22.06,"Z":-190.44},{"Y":-83.07,"X":-28.91,"Z":-199.58},{"Y":-83.04,"X":-39.04,"Z":-206.58},{"Y":-85.54,"X":-50.5,"Z":-211.42},{"Y":-87.36,"X":-61.58,"Z":-215.44},{"Y":-87.23,"X":-71.49,"Z":-218.37},{"Y":-87.12,"X":-85.28,"Z":-222.42},{"Y":-87.1,"X":-96.36,"Z":-227.53},{"Y":-87.19,"X":-107.18,"Z":-233.59},{"Y":-87.38,"X":-119.27,"Z":-238.83},{"Y":-87.36,"X":-130.79,"Z":-244.22},{"Y":-87.36,"X":-142.05,"Z":-247.9},{"Y":-87.38,"X":-153.41,"Z":-251.68},{"Y":-87.37,"X":-165.32,"Z":-253.92},{"Y":-87.36,"X":-177.84,"Z":-254.31},{"Y":-87.36,"X":-189.57,"Z":-254.11},{"Y":-87.36,"X":-200.5,"Z":-253.92},{"Y":-86.03,"X":-211.82,"Z":-253.73},{"Y":-83.19,"X":-221.79,"Z":-253.55},{"Y":-83.01,"X":-241.67,"Z":-248.4},{"Y":-83.01,"X":-232.8,"Z":-252.35},{"Y":-83.02,"X":-228.4,"Z":-260.31},{"Y":-80.57,"X":-226.17,"Z":-270.16},{"Y":-79.5,"X":-229.29,"Z":-280.75},{"Y":-79.36,"X":-231.35,"Z":-291.97},{"Y":-79.01,"X":-237.1,"Z":-302.3},{"Y":-79.01,"X":-242.94,"Z":-311.22},{"Y":-79.01,"X":-249.83,"Z":-320.85},{"Y":-79.01,"X":-260.73,"Z":-330.05},{"Y":-79.01,"X":-269.79,"Z":-335.85},{"Y":-79.01,"X":-277.33,"Z":-343.54},{"Y":-79.01,"X":-286.62,"Z":-353.11},{"Y":-79.01,"X":-293.72,"Z":-360.51},{"Y":-79.01,"X":-298.97,"Z":-367.41},{"Y":-79.01,"X":-301.04,"Z":-359.02},{"Y":-79.01,"X":-304.08,"Z":-347.77},{"Y":-79.01,"X":-306.07,"Z":-335.81},{"Y":-79.01,"X":-309.94,"Z":-322.67},{"Y":-79.01,"X":-312.33,"Z":-309.17},{"Y":-79.01,"X":-315.32,"Z":-293.05},{"Y":-79.01,"X":-310.43,"Z":-282.09},{"Y":-79.01,"X":-305.24,"Z":-270.1},{"Y":-76.4,"X":-305.29,"Z":-257.46},{"Y":-76.94,"X":-306.21,"Z":-245.99},{"Y":-78.87,"X":-300.17,"Z":-235.14},{"Y":-81.44,"X":-293.97,"Z":-225.59},{"Y":-83.5,"X":-288.67,"Z":-215.29},{"Y":-87.11,"X":-287.67,"Z":-204.84},{"Y":-87.51,"X":-279.5,"Z":-199.88},{"Y":-87.51,"X":-269.93,"Z":-205.89},{"Y":-87.24,"X":-260.76,"Z":-213.18},{"Y":-91.48,"X":-252.18,"Z":-204.67},{"Y":-95.67,"X":-243.53,"Z":-202.04},{"Y":-95.4,"X":-234.05,"Z":-194.46},{"Y":-95.25,"X":-230.62,"Z":-183.14},{"Y":-95.23,"X":-232.43,"Z":-171.24},{"Y":-95.05,"X":-237.84,"Z":-160.17},{"Y":-95.17,"X":-244.27,"Z":-149.76},{"Y":-95.08,"X":-251.08,"Z":-139.63},{"Y":-95.01,"X":-261.26,"Z":-124.87},{"Y":-95.52,"X":-274,"Z":-108.19},{"Y":-95.74,"X":-285.97,"Z":-92.01},{"Y":-95.19,"X":-297.88,"Z":-78.88},{"Y":-95.57,"X":-311.68,"Z":-69.36},{"Y":-91.76,"X":-322.82,"Z":-66.37},{"Y":-91.02,"X":-339.9,"Z":-48.1},{"Y":-90.95,"X":-331.58,"Z":-69.22},{"Y":-90,"X":-327.01,"Z":-85.33},{"Y":-86.3,"X":-324.55,"Z":-101.2},{"Y":-84.43,"X":-319.99,"Z":-112.88},{"Y":-79.74,"X":-310.58,"Z":-109.04},{"Y":-76.1,"X":-302.79,"Z":-100.03},{"Y":-73.4,"X":-292.41,"Z":-93.64},{"Y":-70.51,"X":-279.85,"Z":-88.52},{"Y":-70.23,"X":-269.27,"Z":-83.77},{"Y":-71.16,"X":-257.92,"Z":-80.94},{"Y":-71.66,"X":-247.69,"Z":-79.2},{"Y":-71.66,"X":-240.2,"Z":-77.51},{"Y":-71.67,"X":-247.66,"Z":-79.51},{"Y":-71.24,"X":-259.58,"Z":-81.63},{"Y":-71.34,"X":-263.61,"Z":-82.41},{"Y":-69.92,"X":-274.33,"Z":-83.88},{"Y":-71.19,"X":-285.14,"Z":-90.46},{"Y":-75.07,"X":-295.56,"Z":-95.77},{"Y":-76.67,"X":-305.24,"Z":-102.81},{"Y":-80.2,"X":-311.37,"Z":-111.04},{"Y":-84.78,"X":-321.08,"Z":-110.9},{"Y":-85.94,"X":-325.16,"Z":-101.11},{"Y":-89.06,"X":-326.63,"Z":-87.95},{"Y":-91.02,"X":-329.15,"Z":-75.99},{"Y":-91.02,"X":-335.41,"Z":-76.54},{"Y":-90.8,"X":-344.09,"Z":-81.92},{"Y":-91.54,"X":-356.59,"Z":-84.56},{"Y":-92.81,"X":-369.17,"Z":-76.31},{"Y":-95.01,"X":-377.15,"Z":-66.48},{"Y":-95.01,"X":-382.45,"Z":-55.14},{"Y":-91.78,"X":-386.06,"Z":-43.21},{"Y":-91.28,"X":-389.17,"Z":-32.58},{"Y":-90.59,"X":-392.46,"Z":-20.31},{"Y":-87.03,"X":-395.31,"Z":-8.08},{"Y":-86.7,"X":-401.25,"Z":-0.24},{"Y":-87.06,"X":-413.25,"Z":1.4},{"Y":-86.45,"X":-424.29,"Z":1.81},{"Y":-83.3,"X":-435.64,"Z":0.3},{"Y":-83.01,"X":-444.55,"Z":-5.08},{"Y":-83.01,"X":-453.77,"Z":-11.9},{"Y":-83.88,"X":-463.4,"Z":-19.61},{"Y":-83.69,"X":-473.87,"Z":-26.11},{"Y":-84.37,"X":-485.57,"Z":-26.4},{"Y":-83.7,"X":-494.31,"Z":-18.33},{"Y":-83.29,"X":-500.98,"Z":-6.52},{"Y":-83.01,"X":-510.96,"Z":1.72},{"Y":-83.01,"X":-523.27,"Z":6.77},{"Y":-80.44,"X":-535.49,"Z":9.49},{"Y":-79.44,"X":-546.44,"Z":10.62},{"Y":-79.16,"X":-558.99,"Z":12.2},{"Y":-77.32,"X":-570.07,"Z":15.5},{"Y":-75.95,"X":-580.52,"Z":19.97},{"Y":-74.9,"X":-592.09,"Z":25.21},{"Y":-75.02,"X":-604.26,"Z":32.01},{"Y":-72.68,"X":-615.7,"Z":38.05},{"Y":-73.09,"X":-625.72,"Z":44.59},{"Y":-71.83,"X":-635.33,"Z":54.08},{"Y":-71.64,"X":-638.7,"Z":65.86},{"Y":-70.97,"X":-635.52,"Z":77.76},{"Y":-68.5,"X":-635.54,"Z":91.15},{"Y":-67.44,"X":-636.53,"Z":102.86},{"Y":-68.59,"X":-637.86,"Z":114.3},{"Y":-68.98,"X":-640.19,"Z":124.96},{"Y":-69.05,"X":-643.66,"Z":137.76},{"Y":-67.45,"X":-645.31,"Z":150.14},{"Y":-64.29,"X":-646.77,"Z":161.74},{"Y":-63,"X":-648.06,"Z":172.6},{"Y":-63.06,"X":-647.92,"Z":185.56},{"Y":-63.58,"X":-645.97,"Z":196.35},{"Y":-67.9,"X":-648.52,"Z":208.34},{"Y":-71.08,"X":-653.74,"Z":218.49},{"Y":-71.74,"X":-661.93,"Z":229.32},{"Y":-72.66,"X":-673.29,"Z":232.6},{"Y":-71.24,"X":-684.19,"Z":228.22},{"Y":-70.14,"X":-695.16,"Z":220.78},{"Y":-68.24,"X":-703.51,"Z":215.7},{"Y":-67.8,"X":-718.15,"Z":210.58},{"Y":-67.04,"X":-725.19,"Z":214.43},{"Y":-63.23,"X":-733.63,"Z":224.78},{"Y":-61.34,"X":-741.44,"Z":233.34},{"Y":-56.07,"X":-748.11,"Z":243.09},{"Y":-51.96,"X":-752.62,"Z":254.69},{"Y":-49.42,"X":-755.09,"Z":265.76},{"Y":-45.28,"X":-754.55,"Z":276.79},{"Y":-43.01,"X":-745.89,"Z":284.77},{"Y":-39.28,"X":-733.74,"Z":285.45},{"Y":-37.86,"X":-723.1,"Z":278.36},{"Y":-34.87,"X":-712.38,"Z":272},{"Y":-31.07,"X":-702.78,"Z":266.3},{"Y":-29.99,"X":-692.06,"Z":259.95},{"Y":-23.52,"X":-682.76,"Z":254.09},{"Y":-18.71,"X":-674.21,"Z":246.89},{"Y":-14.57,"X":-666.15,"Z":239.94},{"Y":-7.85,"X":-657.53,"Z":232.7},{"Y":-3.15,"X":-649.33,"Z":226.41},{"Y":-3.01,"X":-640.09,"Z":219.41},{"Y":-3.01,"X":-629.88,"Z":211.47},{"Y":-3.01,"X":-619.73,"Z":204.62},{"Y":-3.01,"X":-608.83,"Z":197.91},{"Y":-3.01,"X":-598.32,"Z":191.85},{"Y":-3.01,"X":-588.78,"Z":186.8},{"Y":-3.01,"X":-577.66,"Z":182.3},{"Y":-3.01,"X":-567.97,"Z":178.52},{"Y":-3.01,"X":-557.66,"Z":174.5},{"Y":-3.01,"X":-547.1,"Z":170.38},{"Y":-3.01,"X":-536.67,"Z":166.31},{"Y":-3.01,"X":-526.24,"Z":162.23},{"Y":-3.01,"X":-515.68,"Z":158.11},{"Y":-3.01,"X":-505.12,"Z":153.99},{"Y":-3.01,"X":-495.43,"Z":150.21},{"Y":-3.01,"X":-485,"Z":146.14},{"Y":-3.01,"X":-475.31,"Z":142.36},{"Y":-3.01,"X":-465.75,"Z":138.63},{"Y":-3.01,"X":-455.81,"Z":134.75},{"Y":-3.01,"X":-441.9,"Z":129.32},{"Y":-3.01,"X":-428.2,"Z":123.71},{"Y":-3.01,"X":-416.67,"Z":117.96},{"Y":-3.01,"X":-406.99,"Z":110.88},{"Y":-3.01,"X":-397.98,"Z":102.18},{"Y":-3.01,"X":-389.9,"Z":93.31},{"Y":-3.01,"X":-381.19,"Z":82.87},{"Y":-3.01,"X":-374.04,"Z":73.23},{"Y":-3.01,"X":-367.46,"Z":64.01},{"Y":-3.01,"X":-360.25,"Z":53.76},{"Y":-3.01,"X":-353.42,"Z":44.21},{"Y":-3.13,"X":-341.38,"Z":35.28},{"Y":-7.13,"X":-325.94,"Z":33.56},{"Y":-8.54,"X":-309.94,"Z":28.42},{"Y":-7.76,"X":-293.19,"Z":19.83},{"Y":-7.02,"X":-278.43,"Z":11.79},{"Y":-7.05,"X":-265.25,"Z":3.89},{"Y":-7.01,"X":-254.05,"Z":-3.81},{"Y":-3.23,"X":-239.49,"Z":-16},{"Y":-3.01,"X":-228.54,"Z":-27.78},{"Y":-3.01,"X":-220.69,"Z":-43.05},{"Y":-4.57,"X":-217.09,"Z":-59.69},{"Y":-4.24,"X":-215.87,"Z":-74.03},{"Y":-4.24,"X":-212.02,"Z":-89.13},{"Y":-5.13,"X":-205.35,"Z":-102.24},{"Y":-4.24,"X":-192.12,"Z":-112.43},{"Y":-4.24,"X":-179.04,"Z":-118.3},{"Y":-8.33,"X":-163.93,"Z":-119.77},{"Y":-19.55,"X":-158.69,"Z":-119.1},{"Y":-33.28,"X":-151.73,"Z":-117.4},{"Y":-35.08,"X":-141.75,"Z":-129.1}]}
]]

local function ParseFastGoldCoordinate(coordString)
	local coords = {}
	for num in string.gmatch(coordString, "%-?%d+%.?%d*") do
		local n = tonumber(num)
		if n then
			table.insert(coords, n)
		end
	end
	if #coords == 3 then
		return Vector3.new(coords[1], coords[2], coords[3])
	end
	return nil
end

-- Функция для парсинга JSON координат (возвращает позиции, типы и waits)
local function ParseJSONCoordinates()
	local positions = {}
	local types = {}
	local waits = {}
	
	-- Пробуем распарсить JSON
	local success, jsonData = pcall(function()
		return HttpService:JSONDecode(FAST_GOLD_JSON_DATA)
	end)
	
	if success and jsonData and jsonData.position then
		print("✅ Successfully parsed JSON coordinates: " .. #jsonData.position .. " positions")
		print("📊 Types count: " .. (jsonData.types and #jsonData.types or 0))
		print("📊 Waits count: " .. (jsonData.waits and #jsonData.waits or 0))
		
		local afkCount = 0
		for i, pos in ipairs(jsonData.position) do
			if pos.X and pos.Y and pos.Z then
				table.insert(positions, Vector3.new(pos.X, pos.Y, pos.Z))
				-- Добавляем тип waypoint (fly, afk, walk)
				local wpType = jsonData.types and jsonData.types[i] or "fly"
				table.insert(types, wpType)
				if wpType == "afk" then
					afkCount = afkCount + 1
				end
				-- Добавляем время ожидания
				table.insert(waits, jsonData.waits and jsonData.waits[i] or 0)
			end
		end
		print("✅ Found " .. afkCount .. " AFK waypoints")
	else
		print("⚠️ Failed to parse JSON, using old coordinates")
		-- Используем старые координаты
		for _, coordStr in ipairs(FAST_GOLD_COORDINATES) do
			local pos = ParseFastGoldCoordinate(coordStr)
			if pos then
				table.insert(positions, pos)
				table.insert(types, "fly")
				table.insert(waits, 0)
			end
		end
	end
	
	return positions, types, waits
end

local function StartFastGoldFarm()
	if FAST_GOLD_FARM_RUNNING then
		print("⚠️ Fast Gold Farm already running!")
		return
	end
	
	FAST_GOLD_FARM_RUNNING = true
	
	game:GetService("StarterGui"):SetCore("SendNotification", {
		Title = "Fast Gold Farm",
		Text = "Starting fast gold farm with auto break...",
		Duration = 3
	})
	
	-- Парсим позиции СРАЗУ (до task.spawn)
	local positions = {}
	local waypointTypes = {}
	local waypointWaits = {}
	local waypointsCount = #WAYPOINTS_HOLDER:GetChildren()
	
	if waypointsCount > 0 then
		print("📍 Found " .. waypointsCount .. " total waypoints")
		local waypoints = WAYPOINTS_HOLDER:GetChildren()
		table.sort(waypoints, function(a, b)
			return (a:GetAttribute("WaypointNumber") or 0) < (b:GetAttribute("WaypointNumber") or 0)
		end)
		for i, waypoint in ipairs(waypoints) do
			local wpNum = waypoint:GetAttribute("WaypointNumber") or 0
			local wpType = waypoint:GetAttribute("WaypointType") or "fly"
			table.insert(positions, waypoint.Position)
			table.insert(waypointTypes, wpType)
			table.insert(waypointWaits, waypoint:GetAttribute("WaitTime") or 0)
			-- DEBUG: Выводим первые 5 точек
			if i <= 5 then
				print(string.format("  WP #%d: Type=%s, Pos=(%.1f, %.1f, %.1f)", wpNum, wpType, waypoint.Position.X, waypoint.Position.Y, waypoint.Position.Z))
			end
		end
		print("📍 Using " .. #positions .. " waypoints for fast gold farm")
	else
		print("📍 Parsing JSON coordinates...")
		positions, waypointTypes, waypointWaits = ParseJSONCoordinates()
		-- DEBUG: Выводим первые 5 точек из JSON
		for i = 1, math.min(5, #positions) do
			print(string.format("  JSON #%d: Type=%s, Pos=(%.1f, %.1f, %.1f)", i, waypointTypes[i], positions[i].X, positions[i].Y, positions[i].Z))
		end
	end
	
	print("✅ Parsed " .. #positions .. " positions for fast gold farm")
	
	if #positions == 0 then
		print("❌ No valid positions found!")
		FAST_GOLD_FARM_RUNNING = false
		return
	end
	
	-- Удаляем старые маркеры если есть
	for _, marker in ipairs(FAST_GOLD_FARM_MARKERS) do
		if marker and marker.Parent then
			marker:Destroy()
		end
	end
	FAST_GOLD_FARM_MARKERS = {}
	
	-- Создаём визуальные маркеры для всех точек маршрута (только если включено отображение)
	if FAST_GOLD_FARM_SHOW_MARKERS then
		for i, pos in ipairs(positions) do
			local wpType = waypointTypes[i] or "fly"
			local marker = Instance.new("Part")
			marker.Name = "FastFarmMarker_" .. i
			marker.Size = Vector3.new(1.2, 1.2, 1.2) -- Уменьшенный размер куба
			marker.Shape = Enum.PartType.Block -- Кубическая форма
			marker.Position = pos
			marker.Anchored = true
			marker.CanCollide = false
			marker.Transparency = 0.7 -- Прозрачный
			marker.Material = Enum.Material.Neon
			
			-- Цвет в зависимости от типа точки
			if wpType == "afk" then
				marker.Color = Color3.fromRGB(255, 165, 0) -- Оранжевый для AFK
			elseif wpType == "fly" then
				marker.Color = Color3.fromRGB(255, 255, 0) -- Жёлтый для полёта
			else
				marker.Color = Color3.fromRGB(0, 255, 0) -- Зелёный для ходьбы
			end
			
			-- Добавляем рамку (SelectionBox)
			local selectionBox = Instance.new("SelectionBox")
			selectionBox.Adornee = marker
			selectionBox.LineThickness = 0.05
			selectionBox.Color3 = marker.Color
			selectionBox.Transparency = 0
			selectionBox.Parent = marker
			
			-- Добавляем табличку с номером (меньше)
			local billboard = Instance.new("BillboardGui")
			billboard.Size = UDim2.new(0, 25, 0, 25) -- Уменьшенный размер
			billboard.StudsOffset = Vector3.new(0, 1.5, 0) -- Ближе к кубу
			billboard.AlwaysOnTop = true
			billboard.Parent = marker
			
			local label = Instance.new("TextLabel")
			label.Size = UDim2.new(1, 0, 1, 0)
			label.BackgroundTransparency = 1
			label.Text = tostring(i)
			label.TextColor3 = Color3.fromRGB(255, 255, 255)
			label.TextScaled = true
			label.Font = Enum.Font.GothamBold
			label.TextStrokeTransparency = 0.5
			label.Parent = billboard
			
			marker.Parent = workspace
			table.insert(FAST_GOLD_FARM_MARKERS, marker)
		end
		
		print("✅ Created " .. #FAST_GOLD_FARM_MARKERS .. " visual markers for route")
	end
	
	-- НЕМЕДЛЕННО начинаем лететь к первой координате (ДО task.spawn)
	local char = LocalPlayer.Character
	if char and char:FindFirstChild("HumanoidRootPart") then
		local rootPart = char.HumanoidRootPart
		local firstPos = positions[1]
		print("🚀 Flying to first coordinate: " .. tostring(firstPos))
		
		-- Создаем BodyVelocity для немедленного полета
		local bodyVel = CreateBodyVelocity(rootPart)
		if bodyVel then
			local direction = (firstPos - rootPart.Position).Unit
			bodyVel.Velocity = direction * FAST_GOLD_FARM_SPEED
		end
	end
	
	task.spawn(function()
		local currentIndex = 1
		
		-- Функция для поиска всех ресурсов в радиусе
		local function FindAllGoldInRange()
			local goldList = {}
			local searchDistance = 150 -- УВЕЛИЧЕНО: больший радиус поиска (150 стадов)
			local maxGoldToFind = 25 -- УВЕЛИЧЕНО: больше золота за раз (25 руд)
			
			local resourcesFolder = workspace:FindFirstChild("Resources")
			if not resourcesFolder then return goldList end
			
			local char = LocalPlayer.Character
			if not char then return goldList end
			
			local rootPart = char:FindFirstChild("HumanoidRootPart")
			if not rootPart then return goldList end
			
			local rootPos = rootPart.Position -- ОПТИМИЗАЦИЯ: кэшируем позицию
			
			-- ОПТИМИЗАЦИЯ: используем GetChildren() только один раз
			local resources = resourcesFolder:GetChildren()
			for i = 1, #resources do
				-- ОПТИМИЗАЦИЯ: прерываем поиск если нашли достаточно
				if #goldList >= maxGoldToFind then break end
				
				local resource = resources[i]
				if resource:IsA("Model") then
					local entityID = resource:GetAttribute("EntityID")
					if entityID then
						local name = resource.Name
						-- ОПТИМИЗАЦИЯ: быстрая проверка без lower() и find()
						if name:match("[Gg]old") or name:match("[Oo]re") then
							local primaryPart = resource.PrimaryPart or resource:FindFirstChildWhichIsA("BasePart")
							if primaryPart then
								-- ОПТИМИЗАЦИЯ: быстрая проверка дистанции
								local dx = rootPos.X - primaryPart.Position.X
								local dy = rootPos.Y - primaryPart.Position.Y
								local dz = rootPos.Z - primaryPart.Position.Z
								local distSq = dx*dx + dy*dy + dz*dz
								
								if distSq <= searchDistance * searchDistance then
									goldList[#goldList + 1] = {
										Model = resource,
										Position = primaryPart.Position,
										EntityID = entityID
									}
								end
							end
						end
					end
				end
			end
			
			return goldList
		end
		
		-- ОПТИМИЗАЦИЯ: Кэшируем Packets модуль (не require каждый раз)
		local packetsModule = nil
		pcall(function()
			packetsModule = require(game:GetService("ReplicatedStorage").Modules.Packets)
		end)
		
		-- Функция для ломания золота (отправляет все entityIDs сразу)
		local function BreakMultipleGold(entityIDs)
			if not entityIDs or #entityIDs == 0 then return 0 end
			if not packetsModule or not packetsModule.SwingTool then return 0 end
			
			-- Отправляем все entityIDs одним пакетом (как было раньше)
			local success, result = pcall(function()
				packetsModule.SwingTool.send(entityIDs)
				return #entityIDs
			end)
			
			if success then
				return result or #entityIDs
			end
			
			return 0
		end
		
		-- Функция для подбора raw gold
		local collectedGoldIDs = {}
		local function CollectRawGold()
			if not packetsModule or not packetsModule.Pickup then return 0 end
			
			local collected = 0
			local pickupDistance = 150 -- Радиус подбора 150 стадов
			local maxPickupPerCycle = 15 -- ОПТИМИЗАЦИЯ: уменьшено до 15 (быстрее)
			
			local itemsFolder = workspace:FindFirstChild("Items")
			if not itemsFolder then return 0 end
			
			local char = LocalPlayer.Character
			if not char then return 0 end
			
			local rootPart = char:FindFirstChild("HumanoidRootPart")
			if not rootPart then return 0 end
			
			local rootPos = rootPart.Position -- ОПТИМИЗАЦИЯ: кэшируем позицию
			local pickupDistSq = pickupDistance * pickupDistance
			
			-- ОПТИМИЗАЦИЯ: используем GetChildren() только один раз
			local items = itemsFolder:GetChildren()
			for i = 1, #items do
				-- ОПТИМИЗАЦИЯ: прерываем если подобрали достаточно
				if collected >= maxPickupPerCycle then break end
				
				local item = items[i]
				if item:IsA("BasePart") or item:IsA("MeshPart") then
					local itemName = item.Name
					-- ОПТИМИЗАЦИЯ: быстрая проверка без lower()
					if itemName:match("[Rr]aw") and itemName:match("[Gg]old") then
						local entityID = item:GetAttribute("EntityID")
						if entityID and not collectedGoldIDs[entityID] then
							-- ОПТИМИЗАЦИЯ: быстрая проверка дистанции (без Magnitude)
							local dx = rootPos.X - item.Position.X
							local dy = rootPos.Y - item.Position.Y
							local dz = rootPos.Z - item.Position.Z
							local distSq = dx*dx + dy*dy + dz*dz
							
							if distSq <= pickupDistSq then
								pcall(function()
									packetsModule.Pickup.send(entityID)
									collectedGoldIDs[entityID] = true
									collected = collected + 1
								end)
							end
						end
					end
				end
			end
			return collected
		end
		
		local lastBreakTime = 0
		local breakCooldown = 0.001 -- УСКОРЕНО: мгновенное ломание (1ms)
		local lastSearchTime = 0
		local searchCooldown = 0.15 -- Поиск каждые 0.15 секунды (еще быстрее)
		local lastPickupTime = 0
		local pickupCooldown = 0.05 -- Подбор каждые 50ms (в 2 раза быстрее)
		local cachedGoldList = {} -- Кэшируем список золота
		
		while FAST_GOLD_FARM_ENABLED and FAST_GOLD_FARM_RUNNING do
			local currentTime = tick()
			local char = LocalPlayer.Character
			if char and char:FindFirstChild("HumanoidRootPart") then
				local rootPart = char.HumanoidRootPart
				
				-- Ищем золото чаще (каждые 0.3 сек)
				if (currentTime - lastSearchTime) >= searchCooldown then
					cachedGoldList = FindAllGoldInRange()
					lastSearchTime = currentTime
					if #cachedGoldList > 0 then
						print("🔍 Fast Gold Farm: Found " .. #cachedGoldList .. " gold ores nearby")
					end
				end
				
				-- Бьем руды из кэша (МАКСИМАЛЬНО БЫСТРО - каждые 10ms)
				if #cachedGoldList > 0 and (currentTime - lastBreakTime) >= breakCooldown then
					local entityIDs = {}
					for _, gold in ipairs(cachedGoldList) do
						table.insert(entityIDs, gold.EntityID)
					end
					
					local brokenCount = BreakMultipleGold(entityIDs)
					if brokenCount > 0 then
						print("⛏️ Fast Gold Farm: Hit " .. brokenCount .. " gold ores")
					end
					
					lastBreakTime = currentTime
				end
				
				-- Подбираем raw gold (чаще)
				if (currentTime - lastPickupTime) >= pickupCooldown then
					local collected = CollectRawGold()
					if collected > 0 then
						print("💰 Fast Gold Farm: Collected " .. collected .. " raw gold")
					end
					lastPickupTime = currentTime
				end
				
				-- Получаем текущую цель
				local targetPos = positions[currentIndex]
				local waypointType = waypointTypes[currentIndex] or "fly"
				local waitTime = waypointWaits[currentIndex] or 0
				
				-- DEBUG: Выводим информацию о текущей точке (чаще для отладки)
				if currentIndex % 5 == 0 or waypointType == "afk" then
					print(string.format("📍 Waypoint %d/%d | Type: %s | Pos: %.1f,%.1f,%.1f", 
						currentIndex, #positions, waypointType, targetPos.X, targetPos.Y, targetPos.Z))
				end
				
				-- Проверяем расстояние до цели
				local distance = (rootPart.Position - targetPos).Magnitude
				
				-- DEBUG: Выводим расстояние для AFK точек
				if waypointType == "afk" and distance < 20 then
					print(string.format("🎯 Approaching AFK point %d | Distance: %.1f", currentIndex, distance))
				end
				
				-- Радиус остановки (меньше для AFK точек для точного долета)
				local stopDistance = (waypointType == "afk") and 3 or 5
				
				-- Если достигли точки
				if distance < stopDistance then
					-- Если это AFK точка - останавливаемся и ждем
					if waypointType == "afk" then
						-- Останавливаем движение
						RemoveBodyVelocity()
						
						print("⏸️ AFK waypoint reached! Distance: " .. math.floor(distance) .. " | Waiting 2 seconds...")
						game:GetService("StarterGui"):SetCore("SendNotification", {
							Title = "Fast Gold Farm",
							Text = "AFK point - waiting 2s",
							Duration = 2
						})
						
						-- Ждем 2 секунды, но продолжаем ломать золото
						local afkStartTime = tick()
						while (tick() - afkStartTime) < 2 do
							-- Продолжаем ломать золото во время ожидания
							local afkCurrentTime = tick()
							
							-- Поиск золота
							if (afkCurrentTime - lastSearchTime) >= searchCooldown then
								cachedGoldList = FindAllGoldInRange()
								lastSearchTime = afkCurrentTime
								if #cachedGoldList > 0 then
									print("🔍 AFK: Found " .. #cachedGoldList .. " gold ores")
								end
							end
							
							-- Ломание золота
							if #cachedGoldList > 0 and (afkCurrentTime - lastBreakTime) >= breakCooldown then
								local entityIDs = {}
								for _, gold in ipairs(cachedGoldList) do
									table.insert(entityIDs, gold.EntityID)
								end
								
								local brokenCount = BreakMultipleGold(entityIDs)
								if brokenCount > 0 then
									print("⛏️ AFK: Hit " .. brokenCount .. " gold ores")
								end
								
								lastBreakTime = afkCurrentTime
							end
							
							-- Подбор золота
							if (afkCurrentTime - lastPickupTime) >= pickupCooldown then
								local collected = CollectRawGold()
								if collected > 0 then
									print("💰 AFK: Collected " .. collected .. " raw gold")
								end
								lastPickupTime = afkCurrentTime
							end
							
							task.wait(0.05) -- Короткий wait для продолжения ломания
						end
						
						print("✅ AFK wait complete, moving to next waypoint")
					end
					
					-- Переходим к следующей точке
					currentIndex = currentIndex + 1
					
					-- Если прошли все точки, начинаем заново
					if currentIndex > #positions then
						currentIndex = 1
						print("🔄 Fast Gold Farm: Completed full route, restarting...")
						game:GetService("StarterGui"):SetCore("SendNotification", {
							Title = "Fast Gold Farm",
							Text = "Route completed! Restarting...",
							Duration = 2
						})
					end
				else
					-- Летим к цели на постоянной скорости
					local bodyVel = CreateBodyVelocity(rootPart)
					if bodyVel then
						local direction = (targetPos - rootPart.Position).Unit
						bodyVel.Velocity = direction * FAST_GOLD_FARM_SPEED
					end
				end
			end
			
			task.wait(0.1) -- ОПТИМИЗАЦИЯ: 100ms для баланса скорости и FPS
		end
		
		-- Очистка при остановке
		RemoveBodyVelocity()
		
		-- Останавливаем idle анимацию
		if idleAnimationTrack then
			pcall(function()
				idleAnimationTrack:Stop()
				idleAnimationTrack:Destroy()
			end)
			idleAnimationTrack = nil
			print("✅ Idle animation stopped")
		end
		
		print("⏹️ Fast Gold Farm stopped")
	end)
end

local function StopFastGoldFarm()
	FAST_GOLD_FARM_RUNNING = false
	RemoveBodyVelocity()
	
	-- Восстанавливаем WalkSpeed
	local char = LocalPlayer.Character
	if char then
		local humanoid = char:FindFirstChild("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = 16
			
			-- Останавливаем все анимации (включая idle)
			for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
				if track.Animation then
					track:Stop(0.1)
				end
			end
		end
	end
	
	-- Удаляем визуальные маркеры
	for _, marker in ipairs(FAST_GOLD_FARM_MARKERS) do
		if marker and marker.Parent then
			marker:Destroy()
		end
	end
	FAST_GOLD_FARM_MARKERS = {}
	print("✅ Removed all visual markers")
	
	game:GetService("StarterGui"):SetCore("SendNotification", {
		Title = "Fast Gold Farm",
		Text = "Fast gold farm stopped!",
		Duration = 2
	})
end

CreateToggle("Fast Farm Gold", false, function(state)
	FAST_GOLD_FARM_ENABLED = state
	
	if state then
		StartFastGoldFarm()
	else
		StopFastGoldFarm()
	end
end, Tabs.AutoFarm)

-- Функция для показа маркеров
local function ShowFastFarmMarkers()
	-- Удаляем старые маркеры
	for _, marker in ipairs(FAST_GOLD_FARM_MARKERS) do
		if marker and marker.Parent then
			marker:Destroy()
		end
	end
	FAST_GOLD_FARM_MARKERS = {}
	
	-- Если Fast Farm не запущен, ничего не делаем
	if not FAST_GOLD_FARM_RUNNING then
		return
	end
	
	-- Получаем позиции из waypoints или JSON
	local positions = {}
	local waypointTypes = {}
	local waypointsCount = #WAYPOINTS_HOLDER:GetChildren()
	
	if waypointsCount > 0 then
		local waypoints = WAYPOINTS_HOLDER:GetChildren()
		table.sort(waypoints, function(a, b)
			return (a:GetAttribute("WaypointNumber") or 0) < (b:GetAttribute("WaypointNumber") or 0)
		end)
		for _, waypoint in ipairs(waypoints) do
			table.insert(positions, waypoint.Position)
			table.insert(waypointTypes, waypoint:GetAttribute("WaypointType") or "fly")
		end
	else
		positions, waypointTypes = ParseJSONCoordinates()
	end
	
	-- Создаём маркеры
	for i, pos in ipairs(positions) do
		local wpType = waypointTypes[i] or "fly"
		local marker = Instance.new("Part")
		marker.Name = "FastFarmMarker_" .. i
		marker.Size = Vector3.new(1.2, 1.2, 1.2) -- Уменьшенный размер куба
		marker.Shape = Enum.PartType.Block -- Кубическая форма
		marker.Position = pos
		marker.Anchored = true
		marker.CanCollide = false
		marker.Transparency = 0.7 -- Прозрачный
		marker.Material = Enum.Material.Neon
		
		if wpType == "afk" then
			marker.Color = Color3.fromRGB(255, 165, 0)
		elseif wpType == "fly" then
			marker.Color = Color3.fromRGB(255, 255, 0)
		else
			marker.Color = Color3.fromRGB(0, 255, 0)
		end
		
		-- Добавляем рамку (SelectionBox)
		local selectionBox = Instance.new("SelectionBox")
		selectionBox.Adornee = marker
		selectionBox.LineThickness = 0.05
		selectionBox.Color3 = marker.Color
		selectionBox.Transparency = 0
		selectionBox.Parent = marker
		
		local billboard = Instance.new("BillboardGui")
		billboard.Size = UDim2.new(0, 25, 0, 25) -- Уменьшенный размер
		billboard.StudsOffset = Vector3.new(0, 1.5, 0) -- Ближе к кубу
		billboard.AlwaysOnTop = true
		billboard.Parent = marker
		
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Text = tostring(i)
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		label.TextScaled = true
		label.Font = Enum.Font.GothamBold
		label.TextStrokeTransparency = 0.5
		label.Parent = billboard
		
		marker.Parent = workspace
		table.insert(FAST_GOLD_FARM_MARKERS, marker)
	end
	
	print("✅ Showing " .. #FAST_GOLD_FARM_MARKERS .. " route markers")
end

-- Функция для скрытия маркеров
local function HideFastFarmMarkers()
	for _, marker in ipairs(FAST_GOLD_FARM_MARKERS) do
		if marker and marker.Parent then
			marker:Destroy()
		end
	end
	FAST_GOLD_FARM_MARKERS = {}
	print("✅ Hidden all route markers")
end

-- Поле ввода для скорости Fast Farm Gold
local FastFarmSpeedInput = Tabs.AutoFarm:AddInput("FastFarmSpeedInput", {
	Title = "Fast Farm Speed",
	Default = "21.5",
	Placeholder = "Enter speed (10-30)",
	Numeric = true,
	Finished = true,
	Callback = function(value)
		local speed = tonumber(value)
		if speed then
			-- Ограничиваем значение в пределах 10-30
			speed = math.clamp(speed, 10, 30)
			FAST_GOLD_FARM_SPEED = speed
			game:GetService("StarterGui"):SetCore("SendNotification", {
				Title = "Fast Farm Gold",
				Text = "Speed set to " .. speed,
				Duration = 2
			})
			print("✅ Fast Farm Gold speed set to: " .. speed)
		else
			game:GetService("StarterGui"):SetCore("SendNotification", {
				Title = "Fast Farm Gold",
				Text = "Invalid value! Enter a number between 10-30",
				Duration = 3
			})
		end
	end
})

-- Toggle для показа/скрытия маркеров
CreateToggle("Show Route Markers", false, function(state)
	FAST_GOLD_FARM_SHOW_MARKERS = state
	
	if state then
		ShowFastFarmMarkers()
	else
		HideFastFarmMarkers()
	end
end, Tabs.AutoFarm)

-- ============================================
-- Auto Break (без движения)
-- ============================================

local AUTO_BREAK_ENABLED = false
local AUTO_BREAK_RUNNING = false

local function StartAutoBreak()
	if AUTO_BREAK_RUNNING then
		print("⚠️ Auto Break already running!")
		return
	end
	
	AUTO_BREAK_RUNNING = true
	
	game:GetService("StarterGui"):SetCore("SendNotification", {
		Title = "Auto Break",
		Text = "Auto break started! Breaking resources nearby...",
		Duration = 3
	})
	
	task.spawn(function()
		-- ОПТИМИЗАЦИЯ: Кэшируем Packets модуль один раз (из Fast Gold Farm)
		local packetsModule = nil
		pcall(function()
			packetsModule = require(game:GetService("ReplicatedStorage").Modules.Packets)
		end)
		
		if not packetsModule then
			print("❌ Auto Break: Failed to load Packets module!")
			AUTO_BREAK_RUNNING = false
			return
		end
		
		-- Функция для поиска всех золотых ресурсов в радиусе (из Fast Gold Farm)
		local function FindAllGoldInRange()
			local goldList = {}
			local searchDistance = 120 -- ОПТИМИЗАЦИЯ: уменьшен радиус до 120 (меньше проверок)
			local maxGoldToFind = 12 -- ОПТИМИЗАЦИЯ: уменьшено до 12 (быстрее обработка)
			
			local resourcesFolder = workspace:FindFirstChild("Resources")
			if not resourcesFolder then return goldList end
			
			local char = LocalPlayer.Character
			if not char then return goldList end
			
			local rootPart = char:FindFirstChild("HumanoidRootPart")
			if not rootPart then return goldList end
			
			local rootPos = rootPart.Position -- ОПТИМИЗАЦИЯ: кэшируем позицию
			
			-- ОПТИМИЗАЦИЯ: используем GetChildren() только один раз
			local resources = resourcesFolder:GetChildren()
			for i = 1, #resources do
				-- ОПТИМИЗАЦИЯ: прерываем поиск если нашли достаточно
				if #goldList >= maxGoldToFind then break end
				
				local resource = resources[i]
				if resource:IsA("Model") then
					local entityID = resource:GetAttribute("EntityID")
					if entityID then
						local name = resource.Name
						-- ОПТИМИЗАЦИЯ: быстрая проверка без lower() и find()
						if name:match("[Gg]old") or name:match("[Oo]re") then
							local primaryPart = resource.PrimaryPart or resource:FindFirstChildWhichIsA("BasePart")
							if primaryPart then
								-- ОПТИМИЗАЦИЯ: быстрая проверка дистанции
								local dx = rootPos.X - primaryPart.Position.X
								local dy = rootPos.Y - primaryPart.Position.Y
								local dz = rootPos.Z - primaryPart.Position.Z
								local distSq = dx*dx + dy*dy + dz*dz
								
								if distSq <= searchDistance * searchDistance then
									goldList[#goldList + 1] = {
										Model = resource,
										Position = primaryPart.Position,
										EntityID = entityID
									}
								end
							end
						end
					end
				end
			end
			
			return goldList
		end
		
		-- Функция для ломания золота (из Fast Gold Farm)
		local function BreakMultipleGold(entityIDs)
			if not entityIDs or #entityIDs == 0 then return 0 end
			if not packetsModule or not packetsModule.SwingTool then return 0 end
			
			-- Отправляем все entityIDs одним пакетом (как было раньше)
			local success, result = pcall(function()
				packetsModule.SwingTool.send(entityIDs)
				return #entityIDs
			end)
			
			if success then
				return result or #entityIDs
			end
			
			return 0
		end
		
		-- Функция для подбора raw gold (из Fast Gold Farm)
		local collectedGoldIDs = {}
		local function CollectRawGold()
			if not packetsModule or not packetsModule.Pickup then return 0 end
			
			local collected = 0
			local pickupDistance = 150 -- Радиус подбора 150 стадов
			local maxPickupPerCycle = 15 -- ОПТИМИЗАЦИЯ: уменьшено до 15 (быстрее)
			
			local itemsFolder = workspace:FindFirstChild("Items")
			if not itemsFolder then return 0 end
			
			local char = LocalPlayer.Character
			if not char then return 0 end
			
			local rootPart = char:FindFirstChild("HumanoidRootPart")
			if not rootPart then return 0 end
			
			local rootPos = rootPart.Position -- ОПТИМИЗАЦИЯ: кэшируем позицию
			local pickupDistSq = pickupDistance * pickupDistance
			
			-- ОПТИМИЗАЦИЯ: используем GetChildren() только один раз
			local items = itemsFolder:GetChildren()
			for i = 1, #items do
				-- ОПТИМИЗАЦИЯ: прерываем если подобрали достаточно
				if collected >= maxPickupPerCycle then break end
				
				local item = items[i]
				if item:IsA("BasePart") or item:IsA("MeshPart") then
					local itemName = item.Name
					-- ОПТИМИЗАЦИЯ: быстрая проверка без lower()
					if itemName:match("[Rr]aw") and itemName:match("[Gg]old") then
						local entityID = item:GetAttribute("EntityID")
						if entityID and not collectedGoldIDs[entityID] then
							-- ОПТИМИЗАЦИЯ: быстрая проверка дистанции (без Magnitude)
							local dx = rootPos.X - item.Position.X
							local dy = rootPos.Y - item.Position.Y
							local dz = rootPos.Z - item.Position.Z
							local distSq = dx*dx + dy*dy + dz*dz
							
							if distSq <= pickupDistSq then
								pcall(function()
									packetsModule.Pickup.send(entityID)
									collectedGoldIDs[entityID] = true
									collected = collected + 1
								end)
							end
						end
					end
				end
			end
			return collected
		end
		
		local lastBreakTime = 0
		local breakCooldown = 0.05 -- УСКОРЕНО: очень быстрое ломание (50ms)
		local lastSearchTime = 0
		local searchCooldown = 1.0 -- ОПТИМИЗАЦИЯ: поиск раз в секунду (убирает фризы)
		local lastPickupTime = 0
		local pickupCooldown = 0.4 -- Подбор каждые 400ms (убирает фризы)
		local cachedGoldList = {} -- Кэшируем список золота
		
		print("✅ Auto Break: Loop started")
		
		while AUTO_BREAK_ENABLED and AUTO_BREAK_RUNNING do
			local currentTime = tick()
			local char = LocalPlayer.Character
			
			if char and char:FindFirstChild("HumanoidRootPart") then
				local rootPart = char.HumanoidRootPart
				
				-- ОПТИМИЗАЦИЯ: Ищем золото раз в секунду (убирает фризы)
				if (currentTime - lastSearchTime) >= searchCooldown then
					cachedGoldList = FindAllGoldInRange()
					lastSearchTime = currentTime
				end
				
				-- Бьем руды из кэша (ОЧЕНЬ БЫСТРО - каждые 50ms)
				if #cachedGoldList > 0 and (currentTime - lastBreakTime) >= breakCooldown then
					local entityIDs = {}
					for _, gold in ipairs(cachedGoldList) do
						table.insert(entityIDs, gold.EntityID)
					end
					
					local brokenCount = BreakMultipleGold(entityIDs)
					if brokenCount > 0 then
						print("⛏️ Auto Break: Hit " .. brokenCount .. " gold ores")
					end
					
					lastBreakTime = currentTime
				end
				
				-- Подбираем raw gold (реже, чтобы не фризить)
				if (currentTime - lastPickupTime) >= pickupCooldown then
					local collected = CollectRawGold()
					if collected > 0 then
						print("💰 Auto Break: Collected " .. collected .. " raw gold")
					end
					lastPickupTime = currentTime
				end
			else
				task.wait(0.5) -- Ждём персонажа
			end
			
			task.wait(0.1) -- ОПТИМИЗАЦИЯ: 100ms для баланса скорости и FPS
		end
		
		print("⏹️ Auto Break: Loop ended")
		
		print("⏹️ Auto Break stopped")
	end)
end

local function StopAutoBreak()
	AUTO_BREAK_RUNNING = false
	
	game:GetService("StarterGui"):SetCore("SendNotification", {
		Title = "Auto Break",
		Text = "Auto break stopped!",
		Duration = 2
	})
end

CreateToggle("Auto Break", false, function(state)
	AUTO_BREAK_ENABLED = state
	
	if state then
		StartAutoBreak()
	else
		StopAutoBreak()
	end
end, Tabs.AutoFarm)

	-- ============================================
	-- Telegram Bot Integration
	-- ============================================

	local function CreateTelegramSection()
		Tabs.Main:AddParagraph({
			Title = "📨 Telegram Notifier",
			Content = "Настройка Telegram уведомлений"
		})

		local tokenInput = CreateInput("Bot Token", "123456:ABC-DEF...", TELEGRAM_BOT_TOKEN, function(text)
			TELEGRAM_BOT_TOKEN = tostring(text or "")
			SaveTelegramSettings()
		end)

		local chatInput = CreateInput("Chat ID", "e.g. 123456789", TELEGRAM_CHAT_ID, function(text)
			TELEGRAM_CHAT_ID = tostring(text or "")
			SaveTelegramSettings()
		end)

		local enabledToggle = CreateToggle("Enable Telegram notifications", TELEGRAM_ENABLED, function(state)
			TELEGRAM_ENABLED = state
			SaveTelegramSettings()
			if state and TELEGRAM_BOT_TOKEN ~= "" then
				-- Start bot to listen for commands (нужен только токен)
				StartTelegramBot()
				-- Отправляем уведомление только если есть Chat ID
				if TELEGRAM_CHAT_ID ~= "" then
					local rawGold = GetRawGoldAmount()
					SendTelegramMessage("✅ Notifications enabled. Raw Gold: " .. tostring(rawGold))
				else
					print("ℹ️ Bot started, but no Chat ID set. Bot will respond to /start commands.")
				end
			end
		end)



		local checkTokenBtn = CreateButton("1️⃣ Check Bot Token", function()
			local ok, msg = CheckBotToken()
			print("Token check result:", ok, msg)
			Fluent:Notify({
				Title = "Bot Token Check",
				Content = msg,
				Duration = 5
			})
		end)

	-- Кнопка для тестирования получения обновлений
	local testUpdatesBtn = CreateButton("🔍 Test Get Updates", function()
		print("🧪 Testing GetTelegramUpdates...")
		if not TELEGRAM_ENABLED then
			print("❌ Bot is not enabled!")
			game:GetService("StarterGui"):SetCore("SendNotification", {
				Title = "Test Updates",
				Text = "❌ Bot is not enabled!",
				Duration = 3
			})
			return
		end
		if TELEGRAM_BOT_TOKEN == "" then
			print("❌ Bot token is empty!")
			game:GetService("StarterGui"):SetCore("SendNotification", {
				Title = "Test Updates",
				Text = "❌ Bot token is empty!",
				Duration = 3
			})
			return
		end
		local updates = GetTelegramUpdates()
		if updates then
			local msg = "✅ Got " .. #updates .. " update(s)"
			print(msg)
			game:GetService("StarterGui"):SetCore("SendNotification", {
				Title = "Test Updates",
				Text = msg,
				Duration = 3
			})
		else
			print("❌ No updates received")
			game:GetService("StarterGui"):SetCore("SendNotification", {
				Title = "Test Updates",
				Text = "❌ No updates received (check console for details)",
				Duration = 3
			})
		end
	end)
	if testUpdatesBtn then testUpdatesBtn.LayoutOrder = 11.5 end

	local getChatIdBtn = CreateButton("2️⃣ Get My Chat ID (send /start to bot first!)", function()
		local chatId, msg = GetChatIdFromUpdates()
		print("Chat ID result:", chatId, msg)
		
		if chatId then
			TELEGRAM_CHAT_ID = chatId
			SaveTelegramSettings()
			
			-- Обновляем поле ввода
			if chatInput then
				if chatInput.SetValue then
					chatInput:SetValue(chatId)
				elseif Options and Options.ChatID then
					Options.ChatID:SetValue(chatId)
				end
			end
			
			-- ✅ АВТОМАТИЧЕСКОЕ КОПИРОВАНИЕ В БУФЕР ОБМЕНА
			local copied = false
			pcall(function()
				if setclipboard then
					setclipboard(tostring(chatId))
					copied = true
				elseif toclipboard then
					toclipboard(tostring(chatId))
					copied = true
				end
			end)
			
			-- Улучшенное уведомление
			game:GetService("StarterGui"):SetCore("SendNotification", {
				Title = "✅ Chat ID Получен!",
				Text = "ID: " .. chatId .. (copied and "\n📋 Скопировано в буфер обмена!" or "\n⚠️ Не удалось скопировать"),
				Duration = 7
			})
			
			print("✅ Chat ID успешно получен: " .. chatId)
			if copied then
				print("📋 Chat ID скопирован в буфер обмена!")
			end
		else
			game:GetService("StarterGui"):SetCore("SendNotification", {
				Title = "❌ Ошибка",
				Text = msg or "Не удалось получить Chat ID\nОтправь /start боту в Telegram!",
				Duration = 7
			})
			print("❌ Ошибка получения Chat ID:", msg)
		end
	end)
	if getChatIdBtn then getChatIdBtn.LayoutOrder = 12 end

	local testBtn = CreateButton("3️⃣ Send Test Message", function()
		local rawGold = GetRawGoldAmount()
		local ok = SendTelegramMessage("🔔 Test message from BoogaX. Gold: " .. tostring(rawGold))
		game:GetService("StarterGui"):SetCore("SendNotification", {
			Title = "BoogaX",
			Text = ok and "Test message sent!" or "Failed - check console for details",
			Duration = 3
		})
	end)
		if testBtn then testBtn.LayoutOrder = 13 end
		
		-- Инструкция
		Tabs.Main:AddParagraph({
			Title = "📝 Как настроить",
			Content = "1. Создай бота через @BotFather\n2. Скопируй токен, вставь выше\n3. Нажми 'Check Bot Token'\n4. Отправь /start боту в Telegram\n5. Нажми 'Get My Chat ID'\n6. Включи notifications\n\n📋 Команды бота:\n/start - Покажет сколько Raw Gold в инвентаре"
		})
	end

	-- Build Telegram section at the end
	CreateTelegramSection()

-- УЛУЧШЕННОЕ: Многострочное текстовое поле для координат
-- Используем AddInput с большим лимитом символов
local coordsTextBox = Tabs.Coordinates:AddInput("CoordinatesInput", {
    Title = "Coordinates (Paste JSON here)",
    Default = "",
    Placeholder = "Paste full JSON here (supports long text)",
    Numeric = false,
    Finished = false,
    MultiLine = true, -- Многострочный режим
    Lines = 5, -- 5 строк видимых
    Callback = function(value)
        -- Сохраняем значение
        if value and value ~= "" then
            print("📝 Coordinates pasted: " .. string.len(value) .. " characters")
        end
    end
})

-- Функция для загрузки координат из текста (выделена отдельно для повторного использования)
function LoadCoordinatesFromText(coordsText)
    -- УЛУЧШЕННАЯ ОЧИСТКА ТЕКСТА (для файлов с телефона)
    print("\n=== CLEANING TEXT ===")
    print("Raw length: " .. string.len(coordsText))
    
    -- Убираем BOM (Byte Order Mark) если есть
    coordsText = coordsText:gsub("^\239\187\191", "") -- UTF-8 BOM
    
    -- Нормализуем переносы строк (телефон может использовать \r\n, \r или \n)
    coordsText = coordsText:gsub("\r\n", "\n") -- Windows -> Unix
    coordsText = coordsText:gsub("\r", "\n")   -- Old Mac -> Unix
    
    -- Убираем комментарии и пустые строки
    local cleanedText = ""
    for line in string.gmatch(coordsText, "[^\n]+") do
        local trimmedLine = line:match("^%s*(.-)%s*$") -- Убираем пробелы
        if trimmedLine and trimmedLine ~= "" and not trimmedLine:match("^%-%-") then
            if cleanedText == "" then
                cleanedText = trimmedLine
            else
                cleanedText = cleanedText .. "\n" .. trimmedLine
            end
        end
    end
    
    -- Используем очищенный текст
    if cleanedText ~= "" then
        coordsText = cleanedText
    end
    
    print("Cleaned length: " .. string.len(coordsText))
    
    -- Очищаем старые точки
    WAYPOINTS_MOVING = false
    
    local waypointsToRemove = {}
    for _, waypoint in ipairs(WAYPOINTS_HOLDER:GetChildren()) do
        table.insert(waypointsToRemove, waypoint)
    end
    
    for _, waypoint in ipairs(waypointsToRemove) do
        if waypoint:IsA("Part") or waypoint:IsA("BasePart") then
            local descendants = waypoint:GetDescendants()
            for _, child in ipairs(descendants) do
                if child then
                    child:Destroy()
                end
            end
            waypoint:Destroy()
        elseif waypoint then
            waypoint:Destroy()
        end
    end
    WAYPOINTS_HOLDER:ClearAllChildren()
    
    local loadedCount = 0
    local positions = {}
    
    -- Проверяем формат (JSON или простой)
    print("\n=== PARSING COORDINATES ===")
    print("Checking format...")
    
    local hasPosition = string.find(coordsText, "position") ~= nil
    local hasWait = string.find(coordsText, "wait") ~= nil
    local hasPositions = string.find(coordsText, "positions") ~= nil
    local hasBrace = string.find(coordsText, "{", 1, true) ~= nil
    local hasBracket = string.find(coordsText, "[", 1, true) ~= nil
    
    print("  Has 'position': " .. tostring(hasPosition))
    print("  Has 'wait': " .. tostring(hasWait))
    print("  Has 'positions': " .. tostring(hasPositions))
    print("  Has '{': " .. tostring(hasBrace))
    print("  Has '[': " .. tostring(hasBracket))
    
    -- Проверяем wait формат первым (приоритет)
    if hasWait and hasPositions and hasBrace and hasBracket then
        print("=== Detected WAIT FORMAT ===")
        local success, decoded = pcall(function()
            return game:GetService("HttpService"):JSONDecode(coordsText)
        end)
        
        print("JSON decode success: " .. tostring(success))
        
        if success and decoded and decoded.wait and decoded.positions then
            print("✓ Wait format detected!")
            print("  Wait array length: " .. #decoded.wait)
            print("  Positions array length: " .. #decoded.positions)
            
            -- Проверяем, что массивы одинаковой длины
            if #decoded.wait ~= #decoded.positions then
                print("⚠️ WARNING: wait and positions arrays have different lengths!")
                print("  wait: " .. #decoded.wait .. ", positions: " .. #decoded.positions)
                print("  Will use minimum length: " .. math.min(#decoded.wait, #decoded.positions))
            end
            
            local minLength = math.min(#decoded.wait, #decoded.positions)
            
            for i = 1, minLength do
                local waitTime = decoded.wait[i]
                local posString = decoded.positions[i]
                
                print("  Processing [" .. i .. "]: wait=" .. tostring(waitTime) .. ", pos=" .. tostring(posString))
                
                -- Парсим строку позиции "X,Y,Z"
                local coords = {}
                for num in string.gmatch(posString, "%-?%d+%.?%d*") do
                    local n = tonumber(num)
                    if n then
                        table.insert(coords, n)
                    end
                end
                
                if #coords == 3 then
                    -- Добавляем позицию с wait временем
                    table.insert(positions, {coords[1], coords[2], coords[3], waitTime})
                    print("    ✅ Added position with wait: " .. coords[1] .. ", " .. coords[2] .. ", " .. coords[3] .. " (wait: " .. waitTime .. "s)")
                else
                    print("    ⚠️ Skipped invalid position (expected 3 coords, got " .. #coords .. ")")
                end
            end
        else
            print("✗ Wait format decode failed or missing fields")
        end
    elseif hasPosition or (hasBrace and hasBracket) then
        -- JSON формат (стандартный)
        print("=== Trying JSON format ===")
        print("First 200 chars: " .. string.sub(coordsText, 1, 200))
        print("Last 100 chars: " .. string.sub(coordsText, -100))
        
        -- ИСПРАВЛЕНИЕ: Проверяем что JSON полный (не обрезан)
        local jsonComplete = coordsText:match("}%s*$") ~= nil
        print("JSON appears complete: " .. tostring(jsonComplete))
        
        if not jsonComplete then
            print("⚠️ WARNING: JSON appears truncated! Trying to fix...")
            
            -- Подсчитываем открывающие и закрывающие скобки
            local openBrackets = select(2, coordsText:gsub("%[", ""))
            local closeBrackets = select(2, coordsText:gsub("%]", ""))
            local openBraces = select(2, coordsText:gsub("{", ""))
            local closeBraces = select(2, coordsText:gsub("}", ""))
            
            print("  Brackets: [ = " .. openBrackets .. ", ] = " .. closeBrackets)
            print("  Braces: { = " .. openBraces .. ", } = " .. closeBraces)
            
            -- Закрываем недостающие скобки в правильном порядке
            local missingBrackets = openBrackets - closeBrackets
            local missingBraces = openBraces - closeBraces
            
            if missingBrackets > 0 then
                for i = 1, missingBrackets do
                    coordsText = coordsText .. "]"
                end
                print("  Added " .. missingBrackets .. " closing bracket(s) ]")
            end
            
            if missingBraces > 0 then
                for i = 1, missingBraces do
                    coordsText = coordsText .. "}"
                end
                print("  Added " .. missingBraces .. " closing brace(s) }")
            end
            
            print("Fixed JSON last 100 chars: " .. string.sub(coordsText, -100))
        end
        
        local success, decoded = pcall(function()
            return game:GetService("HttpService"):JSONDecode(coordsText)
        end)
        
        print("JSON decode success: " .. tostring(success))
        
        if success and decoded then
            print("Decoded type: " .. type(decoded))
            local keys = {}
            for k, v in pairs(decoded) do
                table.insert(keys, tostring(k))
            end
            print("Decoded keys: " .. table.concat(keys, ", "))
            
            if decoded.position then
                print("✓ JSON decoded successfully, found 'position' array")
                print("  Array length: " .. #decoded.position)
                print("  Array type: " .. type(decoded.position))
                
                -- Проверяем наличие массивов types и waits
                local hasTypes = decoded.types and type(decoded.types) == "table"
                local hasWaits = decoded.waits and type(decoded.waits) == "table"
                
                print("  Has types array: " .. tostring(hasTypes))
                print("  Has waits array: " .. tostring(hasWaits))
                
                for i, pos in ipairs(decoded.position) do
                    print("  Processing element " .. i .. ": type=" .. type(pos))
                    
                    if type(pos) == "table" then
                        local posKeys = {}
                        for k, v in pairs(pos) do
                            table.insert(posKeys, tostring(k) .. "=" .. tostring(v))
                        end
                        print("    Keys: " .. table.concat(posKeys, ", "))
                        
                        -- ИСПРАВЛЕНИЕ: проверяем разные варианты ключей
                        local x = pos.X or pos.x or pos["X"] or pos["x"]
                        local y = pos.Y or pos.y or pos["Y"] or pos["y"]
                        local z = pos.Z or pos.z or pos["Z"] or pos["z"]
                        
                        if x and y and z then
                            -- Получаем wait время и тип если есть
                            local waitTime = hasWaits and decoded.waits[i] or 0
                            local wpType = hasTypes and decoded.types[i] or "walk"
                            
                            table.insert(positions, {x, y, z, waitTime, wpType})
                            print("    ✅ Added position: " .. x .. ", " .. y .. ", " .. z .. " (type: " .. wpType .. ", wait: " .. waitTime .. "s)")
                        else
                            print("    ⚠️ Skipped table without X/Y/Z (x=" .. tostring(x) .. ", y=" .. tostring(y) .. ", z=" .. tostring(z) .. ")")
                        end
                    else
                        print("    ⚠️ Skipped non-table element: " .. tostring(pos))
                    end
                end
            else
                print("✗ JSON decoded but no 'position' field found")
                print("Available fields:")
                for k, v in pairs(decoded) do
                    print("  " .. tostring(k) .. " = " .. tostring(v))
                end
            end
        else
            print("✗ JSON decode failed")
            print("Error: " .. tostring(decoded))
            print("Text length: " .. string.len(coordsText))
            print("First 500 chars:")
            print(string.sub(coordsText, 1, 500))
        end
    else
        -- Простой формат
        print("=== Trying simple format ===")
        
        local allCoordSets = {}
        
        print("Splitting by newlines and semicolons...")
        local lineCount = 0
        for line in string.gmatch(coordsText, "[^\n]+") do
            lineCount = lineCount + 1
            print("  Line " .. lineCount .. ": " .. string.sub(line, 1, 50))
            for coordSet in string.gmatch(line, "([^;]+)") do
                local trimmed = coordSet:match("^%s*(.-)%s*$")
                if trimmed and trimmed ~= "" then
                    table.insert(allCoordSets, trimmed)
                    print("    Found coord set: " .. string.sub(trimmed, 1, 50))
                end
            end
        end
        
        if #allCoordSets == 0 then
            print("No lines found, trying to split by semicolons only...")
            for coordSet in string.gmatch(coordsText, "([^;]+)") do
                local trimmed = coordSet:match("^%s*(.-)%s*$")
                if trimmed and trimmed ~= "" then
                    table.insert(allCoordSets, trimmed)
                    print("  Found coord set: " .. string.sub(trimmed, 1, 50))
                end
            end
        end
        
        print("Total coord sets found: " .. #allCoordSets)
        
        for i, coordSet in ipairs(allCoordSets) do
            local coords = {}
            for num in string.gmatch(coordSet, "%-?%d+%.?%d*") do
                local n = tonumber(num)
                if n then
                    table.insert(coords, n)
                end
            end
            
            print("  Set " .. i .. ": found " .. #coords .. " numbers")
            
            if #coords == 3 then
                table.insert(positions, coords)
                print("    ✅ Added position: " .. coords[1] .. ", " .. coords[2] .. ", " .. coords[3])
            elseif #coords > 0 then
                print("    ⚠️ Skipped invalid coords (expected 3, got " .. #coords .. ")")
            end
        end
        
        print("Total positions parsed: " .. #positions)
    end
    
    -- Проверяем результат
    print("\n=== FINAL CHECK ===")
    print("Total positions loaded: " .. #positions)
    
    if #positions == 0 then
        print("\n❌ NO VALID COORDINATES FOUND!")
        print("\nExpected formats:")
        print("1. JSON: {\"position\":[{\"X\":1,\"Y\":2,\"Z\":3}]}")
        print("2. Simple: X,Y,Z; X,Y,Z")
        print("3. Simple: 100,50,200")
        print("          150,60,250")
        
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "BoogaX",
            Text = "No valid coordinates found!\nCheck console for details.",
            Duration = 5
        })
        return
    end
    
    print("✅ Coordinates parsed successfully!")
    print("Creating waypoints in optimized batches...")
    
    local totalWaypoints = #positions
    local batchSize = 30 -- Оптимальный баланс: быстро и без лагов
    local batches = math.ceil(totalWaypoints / batchSize)
    
    print("Total waypoints: " .. totalWaypoints)
    print("Batch size: " .. batchSize .. " (balanced)")
    print("Total batches: " .. batches)
    print("Estimated time: ~" .. math.ceil(batches * 0.05) .. " seconds")
    
    -- Создаём точки асинхронно
    task.spawn(function()
        local startTime = tick()
        
        for batchNum = 1, batches do
            local startIdx = (batchNum - 1) * batchSize + 1
            local endIdx = math.min(batchNum * batchSize, totalWaypoints)
            
            -- Показываем прогресс каждые 5 батчей (чаще)
            if batchNum % 5 == 0 or batchNum == 1 or batchNum == batches then
                local progress = math.floor((batchNum / batches) * 100)
                print("📦 " .. progress .. "% (" .. endIdx .. "/" .. totalWaypoints .. ")")
                
                game:GetService("StarterGui"):SetCore("SendNotification", {
                    Title = "BoogaX",
                    Text = "Loading: " .. progress .. "% (" .. endIdx .. "/" .. totalWaypoints .. ")",
                    Duration = 0.3
                })
            end
            
            -- Создаём точки в этом батче
            for i = startIdx, endIdx do
                local coords = positions[i]
                local x, y, z = coords[1], coords[2], coords[3]
                local waitTime = coords[4] -- Может быть nil если нет wait времени
                local wpType = coords[5] or "walk" -- Тип waypoint (walk, fly, afk)
                local waypointNumber = i
                
                -- Максимально упрощённая точка
                local part = Instance.new("Part")
                part.Position = Vector3.new(x, y + 0.5, z)
                part.Anchored = true
                part.CanCollide = false
                
                -- Размер зависит от типа
                if wpType == "afk" then
                    part.Size = Vector3.new(1.2, 1.2, 1.2) -- AFK точки больше
                else
                    part.Size = Vector3.new(0.8, 0.8, 0.8)
                end
                
                -- Цвет и материал зависят от типа
                if wpType == "afk" then
                    part.BrickColor = BrickColor.new("Deep orange")
                    part.Material = Enum.Material.Neon
                    part.Transparency = 0.2
                elseif wpType == "fly" then
                    part.BrickColor = BrickColor.new("New Yeller")
                    part.Material = Enum.Material.SmoothPlastic
                    part.Transparency = 0.3
                elseif waitTime and waitTime > 0 then
                    part.BrickColor = BrickColor.new("Bright blue")
                    part.Material = Enum.Material.Neon
                    part.Transparency = 0.4
                else
                    part.BrickColor = BrickColor.new("Lime green")
                    part.Material = Enum.Material.Neon
                    part.Transparency = 0.4
                end
                
                part.Shape = Enum.PartType.Ball
                part:SetAttribute("Visited", false)
                part:SetAttribute("WaypointNumber", waypointNumber)
                part:SetAttribute("WaypointType", wpType) -- Сохраняем тип
                
                if waitTime and waitTime > 0 then
                    part:SetAttribute("WaitTime", waitTime)
                end
                
                part.Parent = WAYPOINTS_HOLDER
                
                -- Табличка создаётся для каждой 10-й точки, точек с wait, или специальных типов (afk, fly)
                if waypointNumber % 10 == 1 or waypointNumber == 1 or (waitTime and waitTime > 0) or wpType == "afk" or wpType == "fly" then
                    local billboard = Instance.new("BillboardGui")
                    
                    -- Размер зависит от типа
                    if wpType == "afk" then
                        billboard.Size = UDim2.new(0, 35, 0, 35)
                        billboard.StudsOffset = Vector3.new(0, 1.5, 0)
                    else
                        billboard.Size = UDim2.new(0, 18, 0, 18)
                        billboard.StudsOffset = Vector3.new(0, 1, 0)
                    end
                    
                    billboard.AlwaysOnTop = true
                    billboard.MaxDistance = wpType == "afk" and 150 or 40
                    billboard.LightInfluence = 0
                    billboard.Parent = part
                    
                    -- Фон для AFK точек
                    if wpType == "afk" then
                        local bg = Instance.new("Frame")
                        bg.Size = UDim2.new(1, 0, 1, 0)
                        bg.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
                        bg.BackgroundTransparency = 0.1
                        bg.BorderSizePixel = 2
                        bg.BorderColor3 = Color3.fromRGB(200, 100, 0)
                        bg.Parent = billboard
                        
                        local corner = Instance.new("UICorner")
                        corner.CornerRadius = UDim.new(0.3, 0)
                        corner.Parent = bg
                        
                        -- Номер
                        local numberLabel = Instance.new("TextLabel")
                        numberLabel.Size = UDim2.new(1, 0, 0.6, 0)
                        numberLabel.Position = UDim2.new(0, 0, 0, 0)
                        numberLabel.BackgroundTransparency = 1
                        numberLabel.Text = tostring(waypointNumber)
                        numberLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                        numberLabel.TextStrokeTransparency = 0.3
                        numberLabel.Font = Enum.Font.GothamBold
                        numberLabel.TextSize = 14
                        numberLabel.Parent = bg
                        
                        -- Иконка AFK
                        local afkLabel = Instance.new("TextLabel")
                        afkLabel.Size = UDim2.new(1, 0, 0.4, 0)
                        afkLabel.Position = UDim2.new(0, 0, 0.6, 0)
                        afkLabel.BackgroundTransparency = 1
                        afkLabel.Text = "⏸️"
                        afkLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                        afkLabel.TextStrokeTransparency = 0.3
                        afkLabel.Font = Enum.Font.GothamBold
                        afkLabel.TextSize = 10
                        afkLabel.Parent = bg
                    else
                        -- Обычная табличка
                        local numberLabel = Instance.new("TextLabel")
                        numberLabel.Size = UDim2.new(1, 0, 1, 0)
                        numberLabel.BackgroundTransparency = 1
                        
                        -- Текст зависит от типа
                        if waitTime and waitTime > 0 then
                            numberLabel.Text = tostring(waypointNumber) .. "\n⏱" .. waitTime .. "s"
                            numberLabel.TextSize = 8
                        elseif wpType == "fly" then
                            numberLabel.Text = tostring(waypointNumber) .. "\n✈️"
                            numberLabel.TextSize = 8
                        else
                            numberLabel.Text = tostring(waypointNumber)
                            numberLabel.TextSize = 9
                        end
                        
                        numberLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                        numberLabel.TextStrokeTransparency = 0.3
                        numberLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                        numberLabel.Font = Enum.Font.GothamBold
                        numberLabel.Parent = billboard
                    end
                end
                
                loadedCount = loadedCount + 1
            end
            
            -- Минимальная пауза для плавности
            task.wait(0.05) -- 50ms между батчами - БЫСТРО!
        end
        
        local elapsed = math.floor((tick() - startTime) * 10) / 10
        
        -- Финальное уведомление
        print("\n" .. string.rep("=", 60))
        print("=== LOAD COMPLETE ===")
        print("✅ Successfully loaded " .. loadedCount .. " waypoints!")
        print("⏱️  Loading time: " .. elapsed .. " seconds")
        print("Total waypoints in holder: " .. #WAYPOINTS_HOLDER:GetChildren())
        print(string.rep("=", 60) .. "\n")
        
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "BoogaX",
            Text = "✅ " .. loadedCount .. " waypoints loaded in " .. elapsed .. "s!\nReady to start!",
            Duration = 4
        })
    end)
    
    -- Немедленно возвращаем управление (не ждём завершения загрузки)
    print("\n⏳ Loading started in background...")
    print("You can continue using the GUI while waypoints are loading.")
end

-- ============================================
-- COORDINATES TAB
-- ============================================

-- УЛУЧШЕННАЯ ФУНКЦИЯ: Быстрая загрузка (работает всегда!)
CreateButton("⚡ Quick Load", function()
    local coordsText = ""
    if coordsTextBox and coordsTextBox.Value then coordsText = tostring(coordsTextBox.Value) end
    if (not coordsText or coordsText == "") and Options and Options.CoordinatesInput then coordsText = tostring(Options.CoordinatesInput.Value or "") end
    if not coordsText or coordsText == "" or coordsText:match("^Paste") then
        game:GetService("StarterGui"):SetCore("SendNotification", {Title = "BoogaX", Text = "❌ Paste JSON in text box first!", Duration = 4})
        return
    end
    LoadCoordinatesFromText(coordsText)
end, Tabs.Coordinates)

-- СТАРАЯ ФУНКЦИЯ: Загрузка из буфера обмена (решает проблему обрезки)
CreateButton("  CLoad from Clipboard", function()
    print("\n" .. string.rep("=", 60))
    print("=== LOADING FROM CLIPBOARD ===")
    
    local clipboardText = ""
    local clipboardSuccess = false
    
    -- Пробуем получить текст из буфера обмена
    local tryGetclipboard = pcall(function()
        if getclipboard then
            clipboardText = getclipboard()
            clipboardSuccess = true
            print("✓ Got clipboard via getclipboard()")
        end
    end)
    
    if not clipboardSuccess then
        local tryReadclipboard = pcall(function()
            if readclipboard then
                clipboardText = readclipboard()
                clipboardSuccess = true
                print("✓ Got clipboard via readclipboard()")
            end
        end)
    end
    
    if not clipboardSuccess or not clipboardText or clipboardText == "" then
        print("❌ Failed to read clipboard!")
        print("   getclipboard available: " .. tostring(getclipboard ~= nil))
        print("   readclipboard available: " .. tostring(readclipboard ~= nil))
        
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "BoogaX",
            Text = "❌ Failed to read clipboard!\nYour executor may not support this.",
            Duration = 5
        })
        return
    end
    
    print("✅ Clipboard read successfully!")
    print("   Length: " .. string.len(clipboardText) .. " characters")
    print("   First 200 chars: " .. string.sub(clipboardText, 1, 200))
    print("   Last 100 chars: " .. string.sub(clipboardText, -100))
    print(string.rep("=", 60))
    
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "BoogaX",
        Text = "📋 Loading " .. string.len(clipboardText) .. " chars from clipboard...",
        Duration = 3
    })
    
    -- Загружаем координаты из буфера обмена
    LoadCoordinatesFromText(clipboardText)
end, Tabs.Coordinates)

-- Кнопка для проверки содержимого текстового поля (отладка)
CreateButton("🔍 Check Text Box Content", function()
    print("\n" .. string.rep("=", 60))
    print("=== TEXT BOX DEBUG ===")
    
    print("\n1. coordsTextBox object:")
    print("   Exists: " .. tostring(coordsTextBox ~= nil))
    
    if coordsTextBox then
        print("   Type: " .. type(coordsTextBox))
        print("   Has .Value: " .. tostring(coordsTextBox.Value ~= nil))
        print("   Has .Text: " .. tostring(coordsTextBox.Text ~= nil))
        
        if coordsTextBox.Value then
            local val = tostring(coordsTextBox.Value)
            print("   .Value length: " .. string.len(val))
            print("   .Value content (first 200): " .. string.sub(val, 1, 200))
        end
    end
    
    print("\n2. Options table:")
    print("   Exists: " .. tostring(Options ~= nil))
    
    if Options then
        print("   Searching for coordinate-related keys...")
        for k, v in pairs(Options) do
            local keyLower = tostring(k):lower()
            if keyLower:match("coord") or keyLower:match("optional") then
                print("   Found: '" .. tostring(k) .. "'")
                if type(v) == "table" and v.Value then
                    local val = tostring(v.Value)
                    print("     Value length: " .. string.len(val))
                    print("     Value (first 200): " .. string.sub(val, 1, 200))
                end
            end
        end
    end
    
    print(string.rep("=", 60) .. "\n")
    
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "BoogaX",
        Text = "Text box content printed to console (F9)",
        Duration = 3
    })
end, Tabs.Coordinates)

CreateButton("Load Coordinates", function()
    -- Показываем что кнопка нажата
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "BoogaX",
        Text = "Starting coordinate load...\nCheck console (F9) for details",
        Duration = 3
    })
    
    local coordsText = ""
    local fileFound = false
    local folderPath = "BoogaX"
    
    print("\n" .. string.rep("=", 60))
    print("=== LOADING COORDINATES ===")
    
    -- Шаг 1: Проверяем доступность функций
    print("\n🔧 Checking available functions:")
    print("  readfile: " .. tostring(readfile ~= nil))
    print("  isfile: " .. tostring(isfile ~= nil))
    print("  listfiles: " .. tostring(listfiles ~= nil))
    print("  isfolder: " .. tostring(isfolder ~= nil))
    print("  makefolder: " .. tostring(makefolder ~= nil))
    
    -- Шаг 2: Попробовать загрузить из файла
    if readfile then
        print("\n📁 Step 2: Trying to load from file...")
        print("Folder path: " .. folderPath)
        
        -- Проверяем существует ли папка BoogaX
        if isfolder then
            local folderExists = isfolder(folderPath)
            print("  Folder '" .. folderPath .. "' exists: " .. tostring(folderExists))
            
            if not folderExists and makefolder then
                print("  Creating folder...")
                pcall(function() makefolder(folderPath) end)
            end
        end
        
        -- Пробуем получить список файлов в папке
        if listfiles then
            print("\n  📂 Listing files in BoogaX folder:")
            local success, files = pcall(function()
                return listfiles(folderPath)
            end)
            
            if success and files then
                print("  Found " .. #files .. " file(s):")
                for i, file in ipairs(files) do
                    print("    [" .. i .. "] " .. tostring(file))
                end
            else
                print("  ⚠️ Could not list files: " .. tostring(files))
            end
        end
        
        -- Пробуем разные варианты путей
        local possiblePaths = {
            folderPath .. "/coordinates.txt",
            folderPath .. "\\coordinates.txt",
            "coordinates.txt",
            "./BoogaX/coordinates.txt",
            ".\\BoogaX\\coordinates.txt",
            folderPath .. "/coords.txt",
            folderPath .. "/waypoints.txt",
            folderPath .. "/points.txt"
        }
        
        print("\n  🔍 Trying different file paths:")
        for i, filePath in ipairs(possiblePaths) do
            print("  [" .. i .. "] Trying: " .. filePath)
            
            -- Проверяем существование файла
            if isfile then
                local exists = isfile(filePath)
                print("      isfile() = " .. tostring(exists))
            end
            
            -- Пробуем прочитать
            local success, content = pcall(function()
                return readfile(filePath)
            end)
            
            if success and content and content ~= "" then
                coordsText = content
                fileFound = true
                print("      ✅ SUCCESS! File loaded!")
                print("      Content length: " .. string.len(content))
                print("      First 100 chars: " .. string.sub(content, 1, 100))
                break
            else
                if not success then
                    print("      ❌ Error: " .. tostring(content))
                else
                    print("      ⚠️ Empty or not found")
                end
            end
        end
    else
        print("\n⚠️ Step 2: readfile function not available!")
        print("   Your executor doesn't support file reading.")
        print("   Please use the text box method instead.")
    end
    
    -- Шаг 3: Если файл не найден, попробовать текстовое поле
    if not fileFound or coordsText == "" then
        print("\n📝 Step 3: Trying to load from text box...")
        print("  coordsTextBox exists: " .. tostring(coordsTextBox ~= nil))
        print("  Options exists: " .. tostring(Options ~= nil))
        
        local textBoxContent = ""
        
        -- УЛУЧШЕННОЕ ЧТЕНИЕ: Пробуем все возможные способы
        
        -- Способ 1: Через coordsTextBox напрямую
        if coordsTextBox then
            print("\n  Method 1: Direct coordsTextBox access")
            if coordsTextBox.Value then
                textBoxContent = tostring(coordsTextBox.Value)
                print("    coordsTextBox.Value: " .. string.len(textBoxContent) .. " chars")
            end
            
            if textBoxContent == "" and coordsTextBox.Text then
                textBoxContent = tostring(coordsTextBox.Text)
                print("    coordsTextBox.Text: " .. string.len(textBoxContent) .. " chars")
            end
        end
        
        -- Способ 2: Через Options.Coordinatesoptional
        if textBoxContent == "" and Options then
            print("\n  Method 2: Options table access")
            
            -- Показываем все доступные ключи в Options
            if Options then
                print("    Available Options keys:")
                local count = 0
                for k, v in pairs(Options) do
                    count = count + 1
                    if count <= 10 then -- Показываем первые 10
                        print("      - " .. tostring(k))
                    end
                end
                print("    Total Options keys: " .. count)
            end
            
            -- Пробуем разные варианты имени
            local possibleKeys = {
                "Coordinatesoptional",
                "Coordinates (optional)",
                "Coordinates(optional)",
                "CoordinatesOptional",
                "coordinates_optional"
            }
            
            for _, key in ipairs(possibleKeys) do
                if Options[key] then
                    print("    Found Options['" .. key .. "']")
                    if Options[key].Value then
                        textBoxContent = tostring(Options[key].Value)
                        print("      Value: " .. string.len(textBoxContent) .. " chars")
                        if textBoxContent ~= "" then break end
                    end
                end
            end
        end
        
        -- Проверяем результат
        if textBoxContent and textBoxContent ~= "" and textBoxContent ~= "Paste coordinates here if file not found" then
            coordsText = textBoxContent
            print("\n    ✅ Text box has content!")
            print("    Content length: " .. string.len(coordsText))
            print("    First 300 chars: " .. string.sub(coordsText, 1, 300))
            print("    Last 100 chars: " .. string.sub(coordsText, -100))
        else
            print("\n    ⚠️ Text box is empty or contains placeholder")
            print("    Content: '" .. tostring(textBoxContent) .. "'")
        end
    end
    
    -- Шаг 4: Если ничего не найдено - показать ошибку
    if not coordsText or coordsText == "" then
        print("\n❌ NO COORDINATES FOUND!")
        print("\n📋 How to use:")
        print("  Method 1 (File):")
        print("    1. Place coordinates.txt in: workspace/BoogaX/")
        print("    2. Click 'Load Coordinates'")
        print("\n  Method 2 (Text Box):")
        print("    1. Paste coordinates in the text box above")
        print("    2. Click 'Load Coordinates'")
        print("\n📝 Tried files:")
        if readfile then
            for _, fileName in ipairs({"coordinates.txt", "coords.txt", "waypoints.txt", "points.txt"}) do
                print("  - " .. folderPath .. "/" .. fileName)
            end
        else
            print("  - readfile not available")
        end
        print(string.rep("=", 60) .. "\n")
        
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "BoogaX",
            Text = "No coordinates found!\nPaste in text box or place file in BoogaX folder.",
            Duration = 5
        })
        return
    end
    
    -- Шаг 5: Загружаем координаты
    print("\n✅ Coordinates found! Loading...")
    print(string.rep("=", 60))
    
    LoadCoordinatesFromText(coordsText)
end, Tabs.Coordinates)

CreateButton("Save Coordinates (JSON)", function()
    local waypoints = WAYPOINTS_HOLDER:GetChildren()
    if #waypoints == 0 then
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "BoogaX",
            Text = "No waypoints to save!",
            Duration = 3
        })
        return
    end
    
    -- Сортируем по номерам
    table.sort(waypoints, function(a, b)
        return (a:GetAttribute("WaypointNumber") or 0) < (b:GetAttribute("WaypointNumber") or 0)
    end)
    
    local positions = {}
    local types = {}
    local waits = {}
    
    for _, waypoint in ipairs(waypoints) do
        local pos = waypoint.Position - Vector3.new(0, 0.5, 0) -- Убираем смещение
        table.insert(positions, {
            X = math.floor(pos.X * 100) / 100,
            Y = math.floor(pos.Y * 100) / 100,
            Z = math.floor(pos.Z * 100) / 100
        })
        
        -- Сохраняем тип waypoint (walk, fly, afk)
        local wpType = waypoint:GetAttribute("WaypointType") or "walk"
        table.insert(types, wpType)
        
        -- Сохраняем wait время если есть
        local waitTime = waypoint:GetAttribute("WaitTime") or 0
        table.insert(waits, waitTime)
    end
    
    -- УЛУЧШЕННЫЙ JSON с типами и wait временами
    local jsonData = {
        position = positions,
        types = types,
        waits = waits
    }
    local jsonText = game:GetService("HttpService"):JSONEncode(jsonData)
    
    -- Сохраняем в файл в папке BoogaX
    local folderPath = "BoogaX"
    local filePath = folderPath .. "/coordinates.txt"
    local fileSaved = false
    
    local tryWritefile = pcall(function()
        if writefile then
            writefile(filePath, jsonText)
            fileSaved = true
            print("✓ Coordinates saved to: " .. filePath)
        end
    end)
    
    -- Пробуем скопировать в clipboard
    local clipboardSuccess = false
    
    local trySetclipboard = pcall(function()
        if setclipboard then
            setclipboard(jsonText)
            clipboardSuccess = true
        end
    end)
    
    if not clipboardSuccess then
        local tryWriteclipboard = pcall(function()
            if writeclipboard then
                writeclipboard(jsonText)
                clipboardSuccess = true
            end
        end)
    end
    
    if not clipboardSuccess then
        print("JSON Coordinates:")
        print(jsonText)
    end
    
    -- Показываем подробную информацию
    print("\n" .. string.rep("=", 60))
    print("=== COORDINATES SAVED ===")
    print("Total waypoints: " .. #waypoints)
    print("JSON length: " .. string.len(jsonText) .. " characters")
    print("File saved: " .. tostring(fileSaved))
    print("Clipboard: " .. tostring(clipboardSuccess))
    
    if fileSaved then
        print("File location: " .. filePath)
    end
    
    print("\n📋 HOW TO LOAD:")
    print("  1. Click '📋 Load from Clipboard' button")
    print("  2. Coordinates will load from clipboard automatically")
    print("  (No need to paste in text box!)")
    print(string.rep("=", 60) .. "\n")
    
    local message = ""
    local duration = 5
    
    if fileSaved and clipboardSuccess then
        message = "✅ Saved to file & clipboard!\n📋 Use 'Load from Clipboard' button to load"
        duration = 6
    elseif fileSaved then
        message = "✅ Saved to file: " .. filePath
    elseif clipboardSuccess then
        message = "✅ Copied to clipboard!\n📋 Use 'Load from Clipboard' button to load"
        duration = 6
    else
        message = "⚠️ JSON printed to console (F9)"
    end
    
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "BoogaX - " .. #waypoints .. " waypoints",
        Text = message,
        Duration = duration
    })
end, Tabs.Coordinates)

-- ============================================
-- MISC TAB - ANIMATIONS
-- ============================================
local AnimationSection = Tabs.Misc:AddSection("Animation")

local plr = game:GetService("Players").LocalPlayer

local animationPresets = {
    ["Bounce Dance"] = "84555531182471",
    ["Parrot Party"] = "121067808279598",
    ["Russian Dance"] = "74608751145756",
    ["JumpStyle"] = "133248139921782",
    ["ZeroTwo"] = "95385842020103",
    ["Rat Dance"] = "98603994713783",
    ["Barking Dog"] = "88859617281337",
    ["Headless Aura Pose"] = "92584189942958",
    ["67"] = "112661109226148",
    ["Sit"] = "120810323002195",
    ["Fly Up"] = "93511411593120",
    ["Box"] = "101743611146845",
    ["Flying Body Parts"] = "133782344132643"
}

local AnimationInput = AnimationSection:AddInput("AnimationInput", {
    Title = "Animation ID",
    Default = "",
    Placeholder = "Enter Animation ID",
    Numeric = false,
    Finished = false
})

local AnimationDropdown = AnimationSection:AddDropdown("AnimationDropdown", {
    Title = "Animation Presets",
    Values = {"Bounce Dance", "Parrot Party", "Russian Dance", "JumpStyle", "ZeroTwo", "Rat Dance", "Barking Dog", "Headless Aura Pose", "67", "Sit", "Fly Up", "Box", "Flying Body Parts"},
    Default = "Bounce Dance"
})

local PlayAnimationToggle = AnimationSection:AddToggle("PlayAnimationToggle", {
    Title = "Play Animation",
    Default = false
})

local currentAnimationTrack = nil
local HttpService = game:GetService("HttpService")

local function playAnimation()
    local character = plr.Character
    if not character then return end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    local animId = Options.AnimationInput.Value
    local animIdTrimmed = animId and animId:gsub("%s+", "") or ""
    
    if animIdTrimmed == "" then
        local selectedPreset = Options.AnimationDropdown.Value
        if selectedPreset and animationPresets[selectedPreset] then
            animId = animationPresets[selectedPreset]
        else
            return
        end
    else
        animId = animIdTrimmed
    end
    
    if currentAnimationTrack then
        pcall(function()
            currentAnimationTrack:Stop()
            currentAnimationTrack:Destroy()
        end)
        currentAnimationTrack = nil
    end
    
    for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
        if track.Animation then
            track:Stop(0.1)
        end
    end
    
    local animIdString = tostring(animId):gsub("%s+", "")
    local animIdNum = tonumber(animIdString)
    if not animIdNum then return end
    
    task.spawn(function()
        local InsertService = game:GetService("InsertService")
        local ContentProvider = game:GetService("ContentProvider")
        
        local function loadAndPlay(animationObj)
            if not animationObj then return false end
            
            task.wait(0.05)
            
            for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
                if track.Animation and track ~= currentAnimationTrack then
                    track:Stop(0)
                end
            end
            
            local track = humanoid:LoadAnimation(animationObj)
            track.Priority = Enum.AnimationPriority.Action4
            track.Looped = true
            track:AdjustSpeed(1)
            track:Play(0.1)
            currentAnimationTrack = track
            return true
        end
        
        local success, objects = pcall(function()
            return game:GetObjects("rbxassetid://" .. animIdNum)
        end)
        
        if success and objects and #objects > 0 then
            for _, obj in ipairs(objects) do
                if obj:IsA("Animation") then
                    if loadAndPlay(obj) then
                        obj:Destroy()
                        return
                    end
                elseif obj:FindFirstChildOfClass("Animation") then
                    local anim = obj:FindFirstChildOfClass("Animation")
                    if loadAndPlay(anim) then
                        obj:Destroy()
                        return
                    end
                end
            end
            for _, obj in ipairs(objects) do
                obj:Destroy()
            end
        end
        
        local success, result = pcall(function()
            return InsertService:LoadAsset(animIdNum)
        end)
        
        if success and result then
            for _, child in ipairs(result:GetChildren()) do
                if child:IsA("Animation") then
                    if loadAndPlay(child) then
                        result:Destroy()
                        return
                    end
                end
            end
            result:Destroy()
        end
        
        local animation = Instance.new("Animation")
        animation.AnimationId = "rbxassetid://" .. animIdString
        
        pcall(function()
            ContentProvider:PreloadAsync({animation}, function() end)
        end)
        
        task.wait(0.2)
        
        task.wait(0.05)
        
        for _, playingTrack in pairs(humanoid:GetPlayingAnimationTracks()) do
            if playingTrack.Animation and playingTrack ~= currentAnimationTrack then
                playingTrack:Stop(0)
            end
        end
        
        local track = humanoid:LoadAnimation(animation)
        track.Priority = Enum.AnimationPriority.Action4
        track.Looped = true
        track:AdjustSpeed(1)
        track:Play(0.1)
        currentAnimationTrack = track
    end)
end

Options.PlayAnimationToggle:OnChanged(function(value)
    if value then
        playAnimation()
    else
        if currentAnimationTrack then
            currentAnimationTrack:Stop()
            currentAnimationTrack:Destroy()
            currentAnimationTrack = nil
        end
    end
end)

Options.AnimationDropdown:OnChanged(function(value)
    if animationPresets[value] then
        local animId = animationPresets[value]
        local currentInput = Options.AnimationInput.Value
        local currentInputTrimmed = currentInput and currentInput:gsub("%s+", "") or ""
        
        local isCurrentInputAPreset = false
        for presetName, presetId in pairs(animationPresets) do
            if currentInputTrimmed == presetId then
                isCurrentInputAPreset = true
                break
            end
        end
        
        if not currentInput or currentInputTrimmed == "" or isCurrentInputAPreset then
            Options.AnimationInput.Value = animId
        end
        
        if Options.PlayAnimationToggle.Value then
            task.spawn(function()
                if currentAnimationTrack then
                    pcall(function()
                        currentAnimationTrack:Stop(0)
                        currentAnimationTrack:Destroy()
                    end)
                    currentAnimationTrack = nil
                end
                
                local character = plr.Character
                if character then
                    local humanoid = character:FindFirstChildOfClass("Humanoid")
                    if humanoid then
                        for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
                            if track.Animation and track ~= currentAnimationTrack then
                                track:Stop(0)
                            end
                        end
                    end
                end
                
                task.wait(0.1)
                
                local animIdToUse = Options.AnimationInput.Value
                local animIdToUseTrimmed = animIdToUse and animIdToUse:gsub("%s+", "") or ""
                if animIdToUseTrimmed == "" then
                    animIdToUseTrimmed = animId
                end
                
                local animIdNum = tonumber(animIdToUseTrimmed)
                if not animIdNum then return end
                
                task.spawn(function()
                    local InsertService = game:GetService("InsertService")
                    local ContentProvider = game:GetService("ContentProvider")
                    
                    local function loadAndPlay(animationObj)
                        if not animationObj then return false end
                        
                        task.wait(0.05)
                        
                        for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
                            if track.Animation and track ~= currentAnimationTrack then
                                track:Stop(0)
                            end
                        end
                        
                        local track = humanoid:LoadAnimation(animationObj)
                        track.Priority = Enum.AnimationPriority.Action4
                        track.Looped = true
                        track:AdjustSpeed(1)
                        track:Play(0.1)
                        currentAnimationTrack = track
                        return true
                    end
                    
                    local success, objects = pcall(function()
                        return game:GetObjects("rbxassetid://" .. animIdNum)
                    end)
                    
                    if success and objects and #objects > 0 then
                        for _, obj in ipairs(objects) do
                            if obj:IsA("Animation") then
                                if loadAndPlay(obj) then
                                    obj:Destroy()
                                    return
                                end
                            elseif obj:FindFirstChildOfClass("Animation") then
                                local anim = obj:FindFirstChildOfClass("Animation")
                                if loadAndPlay(anim) then
                                    obj:Destroy()
                                    return
                                end
                            end
                        end
                        for _, obj in ipairs(objects) do
                            obj:Destroy()
                        end
                    end
                    
                    local success, result = pcall(function()
                        return InsertService:LoadAsset(animIdNum)
                    end)
                    
                    if success and result then
                        for _, child in ipairs(result:GetChildren()) do
                            if child:IsA("Animation") then
                                if loadAndPlay(child) then
                                    result:Destroy()
                                    return
                                end
                            end
                        end
                        result:Destroy()
                    end
                    
                    local animation = Instance.new("Animation")
                    animation.AnimationId = "rbxassetid://" .. animIdToUseTrimmed
                    
                    pcall(function()
                        ContentProvider:PreloadAsync({animation}, function() end)
                    end)
                    
                    task.wait(0.2)
                    
                    task.wait(0.05)
                    
                    for _, playingTrack in pairs(humanoid:GetPlayingAnimationTracks()) do
                        if playingTrack.Animation and playingTrack ~= currentAnimationTrack then
                            playingTrack:Stop(0)
                        end
                    end
                    
                    local track = humanoid:LoadAnimation(animation)
                    track.Priority = Enum.AnimationPriority.Action4
                    track.Looped = true
                    track:AdjustSpeed(1)
                    track:Play(0.1)
                    currentAnimationTrack = track
                end)
            end)
        end
    end
end)

Options.AnimationInput:OnChanged(function()
    if Options.PlayAnimationToggle.Value then
        playAnimation()
    end
end)

plr.CharacterAdded:Connect(function(character)
    if Options.PlayAnimationToggle.Value then
        playAnimation()
    end
end)

	
	-- Загрузка автосохранённой конфигурации
	SaveManager:LoadAutoloadConfig()
end -- Конец функции CreateMainGUI()

-- Обновляем функции авторизации, чтобы они вызывали CreateMainGUI() после успешной авторизации
local originalAddHWID = nil
local originalPastebin = nil

-- Показываем GUI авторизации только если не авторизован
if HWID_CHECK_ENABLED and not hwidAuthorized then
    -- Ждём немного чтобы GUI успел загрузиться
    task.wait(0.5)
    CreateHWIDAuthGUI()
    --print("⚠️ HWID Authorization Required - GUI shown")
    
    -- Обновляем логику кнопок в GUI авторизации
    -- Нужно переопределить функции после создания GUI
    task.wait(0.1)
    -- Переопределение будет в самой функции CreateHWIDAuthGUI
else
    -- HWID авторизован, создаём основной GUI сразу
    --print("✓ HWID Check Passed - Creating main GUI...")
    
    -- Диагностика HTTP методов
    print("=== HTTP Methods Diagnostic ===")
    if http_request then print("✓ http_request available") else print("✗ http_request NOT available") end
    if syn and syn.request then print("✓ syn.request available") else print("✗ syn.request NOT available") end
    if request then print("✓ request available") else print("✗ request NOT available") end
    
    local httpOk = pcall(function()
        game:GetService("HttpService"):GetAsync("https://google.com")
    end)
    if httpOk then 
        print("✓ HttpService:GetAsync available") 
    else 
        print("✗ HttpService:GetAsync NOT available (likely blocked)")
    end
    print("===============================")
    
    CreateMainGUI()
end
