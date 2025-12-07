-- Boilerplate to load library and create window/tab
local ok, lib = pcall(loadstring(game:HttpGet("https://raw.githubusercontent.com/vthiep2412/hiep-script/refs/heads/main/OsmiumLibraryFix.lua")))
if not ok then warn(lib) return end

local win = lib:CreateWindow("Vehicle Automation")
local tab = win:CreateTab("Main")

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local staffWatchEnabled = false
local playerAddedConnection = nil
local antiAfkConnection = nil
local safeRespawnCoord = Vector3.new(4100, 80, -5100) -- Safe spot for car respawn
local initialMoney = 0
local previousRaceName = nil
local isDebugMode = false

local function debugPrint(message)
    if isDebugMode then
        print(message)
    end
end

local raceNameMap = {
    ["3/4MileRunwayDragStrip"] = "DragStripThreeQuarterMile",
    ["3/4MileCityDragStrip"] = "DragStripThreeQuarterMileCity",
    ["Homeowners'Association"] = "HOA"
}

-- Keywords to identify staff roles.
local staffKeywords = {
    "mod", "admin", "staff", "dev", "founder", "owner", "supervis",
    "manager", "management", "executive", "president", "chairman",
    "chairwoman", "chairperson", "director", "moderator", "supervisor",
    "administrator", "developer"
};

-- Noclip variables and function
local vehicleNoclip = false
local noclipConnections = {}
local originalCollisions = {}

-- Formats a number with commas for readability.
local function formatMoney(amount)
    local formatted = tostring(math.floor(amount))
    while true do
        local k
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return "$" .. formatted
end

local function getCar() -- Forward declaration for toggleNoclip
    for _, car in pairs(workspace.Cars:GetChildren()) do
        if car:FindFirstChild("Owner") and car.Owner.Value == player then
            return car
        end
    end
end

local function toggleNoclip(val)
    vehicleNoclip = val
    
    if val then
        -- Noclip ON
        originalCollisions = {} -- Clear any old data
        
        local conn = game:GetService("RunService").Heartbeat:Connect(function()
            pcall(function()
                local player = game:GetService("Players").LocalPlayer
                local character = player.Character or player.CharacterAdded:Wait()
                
                local function processPart(part)
                    if part:IsA("BasePart") then
                        if originalCollisions[part] == nil then
                            originalCollisions[part] = part.CanCollide
                        end
                        part.CanCollide = false
                    end
                end

                for _, part in ipairs(character:GetDescendants()) do
                    processPart(part)
                end
                
                local car = getCar()
                if car then
                    for _, part in ipairs(car:GetDescendants()) do
                        processPart(part)
                    end
                end
            end)
        end)
        table.insert(noclipConnections, conn)
    else
        -- Noclip OFF
        for _, conn in ipairs(noclipConnections) do
            conn:Disconnect()
        end
        noclipConnections = {}

        pcall(function()
            for part, originalState in pairs(originalCollisions) do
                if part and part.Parent then
                    part.CanCollide = originalState
                end
            end
        end)
        
        originalCollisions = {}
    end
end

local function checkPlayerForStaffRole(playerToCheck)
    local roleInGroup = playerToCheck:GetRoleInGroup(game.CreatorId)
    local staffInfo = {
        Role = roleInGroup,
        IsStaff = false
    }

    -- Check for Roblox employees (group ID 1200769 is for Roblox Admins)
    if playerToCheck:IsInGroup(1200769) then
        staffInfo.Role = "Roblox Employee"
        staffInfo.IsStaff = true
    end

    -- Check for group staff roles by keyword
    if not staffInfo.IsStaff then
        for _, keyword in ipairs(staffKeywords) do
            if string.find(string.lower(roleInGroup), keyword) then
                staffInfo.IsStaff = true
                break -- Found a match, no need to check further
            end
        end
    end

    return staffInfo
end

-- Automation state
local autoRaceActive = false
local customAutoRaceActive = false

-- Core flight function
local function FlyToCheckpoint(car, targetPos, speed)
    local root = car.PrimaryPart
    if not root then return end

    local startPos = root.Position
    local BG = Instance.new("BodyGyro")
    local BV = Instance.new("BodyVelocity")

    BG.P = 9e4
    BG.maxTorque = Vector3.new(9e9, 9e9, 9e9)
    BG.cframe = CFrame.new(startPos, targetPos)
    BG.Parent = root

    BV.maxForce = Vector3.new(9e9, 9e9, 9e9)
    BV.Parent = root

    local direction = (targetPos - startPos).Unit
    local distance = (targetPos - startPos).Magnitude
    if distance == 0 then return end

    -- Fly until close to the target
    while autoRaceActive and (root.Position - targetPos).Magnitude > 15 do
        if not (car and car.Parent) then break end
        BV.velocity = direction * speed
        BG.cframe = CFrame.new(root.Position, targetPos)
        task.wait()
    end

    if BG.Parent then BG:Destroy() end
    if BV.Parent then BV:Destroy() end
end


local function TptoVector(targetpos)
    local car = getCar()
    if not (car and car.PrimaryPart) then
        warn("Player car not found for GoTo.")
        return false
    end
    local root = car.PrimaryPart
    local wasAnchored = root.Anchored
    root.Anchored = true
    task.wait() -- Wait a moment for anchor to take effect
    car:SetPrimaryPartCFrame(CFrame.new(targetpos))
    root.Anchored = wasAnchored
    return true
end

local function clickButton(button)
    if button and button:IsA("GuiButton") then
        pcall(function()
            for i,v in next, getconnections(button.MouseButton1Click) do
                v:Fire()
            end
            debugPrint("Clicked button via getconnections: " .. button.Name)
        end)
        pcall(function()
            button.MouseButton1Click:Fire()
            debugPrint("Clicked button via fire(): " .. button.Name)
        end)
    end
end


local function stopCarVelocity()
    local car = getCar()
    if not (car and car.PrimaryPart) then return end

    debugPrint("Stopping all car velocity.")
    for _, part in ipairs(car:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Velocity = Vector3.new(0, 0, 0)
            part.RotVelocity = Vector3.new(0, 0, 0)
        end
    end
end

local function respawnCarAtCoord(coord)
    debugPrint("[Auto Respawn] Starting car respawn process at: " .. tostring(coord))
    pcall(function()
        task.wait()
        
        local character
        local hrp
        local timeout = 5
        local end_time = tick() + timeout

        repeat
            character = player.Character
            if character then
                hrp = character:FindFirstChild("HumanoidRootPart")
            end
            task.wait(0.1)
        until hrp or tick() > end_time

        if not hrp then
            warn("[Auto Respawn] Failed to find HumanoidRootPart after " .. timeout .. " seconds.")
            return nil
        end

        local CarsFolder = ReplicatedStorage:WaitForChild("PlayerData"):WaitForChild(player.Name):WaitForChild("Inventory"):WaitForChild("Cars")
        local CarModel = CarsFolder:FindFirstChildWhichIsA("Folder")

        if not CarModel then
            warn("[Auto Respawn] No car found in inventory for player " .. player.Name)
            return
        end
        local currentCar = getCar()
        if currentCar and currentCar.PrimaryPart then
            debugPrint("[Auto Respawn] Existing car found, teleporting to coordinate.")
            -- TptoVector(coord+Vector3.new(0,5,0))
            -- VirtualInputManager:SendKeyEvent(true, "Enum.KeyCode.Space", false, game)
            -- VirtualInputManager:SendKeyEvent(false, "Enum.KeyCode.Space", false, game)
            -- local newCarCframe = currentCar.PrimaryPart.CFrame
            -- if currentCar and currentCar.PrimaryPart then
            --     debugPrint("[Auto Respawn] New car found, snapping to position.")
            --     hrp:SetPrimaryPartCFrame(newCarCframe + Vector3.new(10, 10, 0))
            -- else
            --     warn("[Auto Respawn] Failed to find newly spawned car.")
            -- end
        else
            debugPrint("[Auto Respawn] Teleporting player to coordinate.")
            hrp.CFrame = CFrame.new(coord+Vector3.new(math.random(-100,100),5,math.random(-100,100)))
        end
        task.wait(1)
        
        local playerCFrame = hrp.CFrame
        debugPrint("[Auto Respawn] Invoking server to spawn car at CFrame: " .. tostring(playerCFrame))
        local args = {
            CarModel,
            [3] = playerCFrame
        }
        ReplicatedStorage:WaitForChild("Systems"):WaitForChild("CarInteraction"):WaitForChild("SpawnPlayerCar"):InvokeServer(unpack(args))
        task.wait(1)
        
        local newCar = getCar()
        local newCarCframe = newCar.PrimaryPart.CFrame
        if newCar and newCar.PrimaryPart then
            debugPrint("[Auto Respawn] New car found, snapping to position.")
            newCar:SetPrimaryPartCFrame(playerCFrame + Vector3.new(10, 5, 0))
        else
            warn("[Auto Respawn] Failed to find newly spawned car.")
        end
        -- task.wait(1)
        debugPrint("[Auto Respawn] Simulating 'E' key press to enter car.")
        VirtualInputManager:SendKeyEvent(true, "E", false, game)
        VirtualInputManager:SendKeyEvent(false, "E", false, game)
        task.wait(1.5)
    end)
    debugPrint("[Auto Respawn] Car respawn process finished.")
end

local function autoWin(raceFolder, ignoreFailure)
    local car = getCar()
    if not (car and car.PrimaryPart) then
        warn("AutoWin: Car not found.")
        return
    end

    local checkpointsFolder = raceFolder:FindFirstChild("Checkpoints")
    if not checkpointsFolder then
        warn("AutoWin: Checkpoints folder not found in " .. raceFolder.Name)
        return
    end

    debugPrint("AutoWin: Starting...")

    local findFailCount = 0

    -- init check for blue checkpoint and green checkpoint
    local closestBlueCheckpointtmp = nil
    for _, descendant in ipairs(checkpointsFolder:GetDescendants()) do
        if descendant:IsA("BasePart") and (descendant.BrickColor.Name == "Electric blue" or descendant.BrickColor.Name == "Sea green") then
            closestBlueCheckpointtmp = descendant
        end
    end
    if findFailCount >= 15 then
        debugPrint("AutoWin: Failed to find checkpoint 15 times during init")
    elseif closestBlueCheckpointtmp then
        debugPrint("AutoWin: init check pass")
    else
        debugPrint("AutoWin: init check fail")
        if findFailCount < 15 then
            debugPrint("AutoWin: No checkpoints found during init, checked: " .. findFailCount)
        elseif not ignoreFailure then
            debugPrint("AutoWin: Respawning car at safe spot.")
            respawnCarAtCoord(safeRespawnCoord)
            return
        else
            debugPrint("AutoWin: Ignoring failure as requested.")
            return
        end
    end


    toggleNoclip(true)
    -- Loop until checkpoints folder is empty
    while autoRaceActive and #checkpointsFolder:GetChildren() > 0 do
        local targetCheckpoint = nil
        local isFinalCheckpoint = false

        -- 1. Find the CLOSEST "Electric blue" checkpoint
        local closestBlueCheckpoint = nil
        local minDistance = math.huge
        
        for _, descendant in ipairs(checkpointsFolder:GetDescendants()) do
            if descendant:IsA("BasePart") and descendant.BrickColor.Name == "Electric blue" then
                local distance = (car.PrimaryPart.Position - descendant.Position).Magnitude
                if distance < minDistance then
                    minDistance = distance
                    closestBlueCheckpoint = descendant
                end
            end
        end
        
        if closestBlueCheckpoint then
            targetCheckpoint = closestBlueCheckpoint
        else
            -- 2. If no blue, search for "Sea green" (final checkpoint)
            for _, descendant in ipairs(checkpointsFolder:GetDescendants()) do
                if descendant:IsA("BasePart") and descendant.BrickColor.Name == "Sea green" then
                    targetCheckpoint = descendant
                    isFinalCheckpoint = true
                    break
                end
            end
        end

        -- 3. Act based on what was found
        if targetCheckpoint then
            findFailCount = 0 -- Reset counter on success
            debugPrint("AutoWin: Flying to " .. targetCheckpoint.BrickColor.Name .. " checkpoint: " .. targetCheckpoint.Name)
            FlyToCheckpoint(car, targetCheckpoint:GetPivot().Position, 450)
            
            if isFinalCheckpoint then
                debugPrint("AutoWin: Final checkpoint reached. Breaking loop.")
                toggleNoclip(false)
                task.wait(0.2)
                stopCarVelocity()
                break -- Race is over
            else
                task.wait(0.08) -- Wait after a normal checkpoint
            end
        else
            -- 4. If nothing was found
            findFailCount = findFailCount + 1
            debugPrint("AutoWin: No checkpoints found. Fail count: " .. findFailCount)
            
            if findFailCount >= 15 then
                debugPrint("AutoWin: Failed to find checkpoint 15 times. Aborting race.")
                if not ignoreFailure then
                    debugPrint("AutoWin: Respawning car at safe spot.")
                    stopCarVelocity()
                    toggleNoclip(false)
                    respawnCarAtCoord(safeRespawnCoord)
                else
                    debugPrint("AutoWin: Ignoring failure as requested.")
                end
                break -- Exit the autoWin loop
            end

            task.wait(0.1)
        end
    end
    
    debugPrint("AutoWin: Race finished.")
    toggleNoclip(false)
end

local function checkAndRespawnCar()
    local needsRespawn = false
    local reason = ""

    local char = player.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")

    if not (humanoid and humanoid.Health > 0) then
        needsRespawn = true
        reason = "Player is dead or character not found."
    else
        local currentCar = getCar()
        if not (currentCar and currentCar.PrimaryPart) then
            needsRespawn = true
            reason = "Car not found."
        else
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local dist = (hrp.Position - currentCar.PrimaryPart.Position).Magnitude
                if dist > 30 then
                    needsRespawn = true
                    reason = "Player is too far from car ("..tostring(dist).." studs)."
                end
            end
        end
    end

    if needsRespawn then
        debugPrint("[Auto Respawn] Condition triggered respawn. Reason: " .. reason)
        
        local retryAttempts = 3
        for i = 1, retryAttempts do
            debugPrint("[Auto Respawn] Spawning car, attempt " .. i)
            respawnCarAtCoord(safeRespawnCoord)
            task.wait(2) -- Wait for spawn
            local newCar = getCar()
            if newCar then
                debugPrint("[Auto Respawn] Car spawn successful.")
                break -- Exit retry loop
            else
                debugPrint("[Auto Respawn] Car not found after spawn, retrying...")
                if i == retryAttempts then
                    warn("[Auto Respawn] Failed to spawn car after " .. retryAttempts .. " attempts.")
                end
            end
        end
    end
end

local function toggleAntiAFK(isEnabled)
    if isEnabled then
        if not antiAfkConnection then
            antiAfkConnection = player.Idled:connect(function()
                debugPrint("[Anti-AFK] Idle detected, preventing kick.")
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
            debugPrint("[Anti-AFK] Enabled.")
        end
    else
        if antiAfkConnection then
            antiAfkConnection:Disconnect()
            antiAfkConnection = nil
            debugPrint("[Anti-AFK] Disabled.")
        end
    end
end

-- Money Counter
task.spawn(function()
    local leaderstats = player:WaitForChild("leaderstats")
    local cash = leaderstats and leaderstats:WaitForChild("Cash")
    if cash then
        initialMoney = cash.Value
        debugPrint("[MoneyCounter] Initialized. Starting money: " .. formatMoney(initialMoney))
    else
        warn("[MoneyCounter] Could not find Cash value on startup.")
    end
end)

-- UI Elements
tab:CreateToggle("Enable Debug Prints", false, function(val)
    isDebugMode = val
    debugPrint("Debug Prints: " .. (val and "Enabled" or "Disabled"))
end)

local raceSequenceConfig = {
    OverAndOut = {
        folderName = "OverAndOut",
        fallbackStart = Vector3.new(4100, 80, -5100) -- Airport area
    },
    SplitSurfaceCircuit = {
        folderName = "SplitSurfaceCircuit",
        fallbackStart = Vector3.new(347, 21, 1058) -- City area
    }
}
local nextRaceInSequence = "OverAndOut"

local function customAutoRaceLoop()
    while customAutoRaceActive do
        pcall(function()
            local currentRaceKey = nextRaceInSequence
            local config = raceSequenceConfig[currentRaceKey]
            debugPrint("Custom Race Sequence: Starting race: " .. config.folderName)

            local raceFolder = workspace.Races:FindFirstChild(config.folderName)
            if not raceFolder then
                debugPrint("Custom Race Sequence: ERROR: Could not find race folder '" .. config.folderName .. "'. Skipping to next race.")
                -- Switch to the other race and restart the loop
                nextRaceInSequence = (currentRaceKey == "OverAndOut") and "SplitSurfaceCircuit" or "OverAndOut"
                task.wait(2)
                return
            end

            local startPosition
            local queuePart = raceFolder:FindFirstChild("MultiplayerQueue")
            if queuePart then
                startPosition = queuePart:GetPivot().Position
                debugPrint("Custom Race Sequence: Found MultiplayerQueue part for " .. config.folderName)
            else
                startPosition = config.fallbackStart
                debugPrint("Custom Race Sequence: WARNING: Could not find MultiplayerQueue for " .. config.folderName .. ". Using hardcoded fallback.")
            end

            checkAndRespawnCar()
            debugPrint("Custom Race Sequence: Teleporting to " .. config.folderName .. " start.")
            if not TptoVector(startPosition) then
                debugPrint("Custom Race Sequence: Failed to teleport to start, retrying...")
                task.wait(2)
                return
            end

            debugPrint("Custom Race Sequence: Waiting for blue checkpoint...")
            local blueCheckpoint = nil
            local checkpointsFolder = raceFolder:FindFirstChild("Checkpoints")
            if not checkpointsFolder then
                debugPrint("Custom Race Sequence: ERROR: No 'Checkpoints' folder in '" .. config.folderName .. "'. Skipping.")
                nextRaceInSequence = (currentRaceKey == "OverAndOut") and "SplitSurfaceCircuit" or "OverAndOut"
                task.wait(2)
                return
            end
            local car = getCar()
            local root = car.PrimaryPart
            local wasAnchored = root.Anchored
            root.Anchored = true
            task.wait(1) -- Wait a moment for world to load
            root.Anchored = wasAnchored
            stopCarVelocity(car)
            local waitStartTime = tick()
            while customAutoRaceActive and blueCheckpoint == nil do
                if tick() - waitStartTime > 45 then -- 45 second timeout
                    debugPrint("Custom Race Sequence: Timed out waiting for blue checkpoint. Skipping to next race.")
                    break
                end
                for _, descendant in ipairs(checkpointsFolder:GetDescendants()) do
                    if descendant:IsA("BasePart") and descendant.BrickColor.Name == "Electric blue" then
                        blueCheckpoint = descendant
                        break
                    end
                end
                task.wait(0.2)
            end

            if not customAutoRaceActive then return end
            
            if not blueCheckpoint then
                debugPrint("Custom Race Sequence: Did not find blue checkpoint for " .. config.folderName .. ". Skipping to next race.")
                nextRaceInSequence = (currentRaceKey == "OverAndOut") and "SplitSurfaceCircuit" or "OverAndOut"
                task.wait(2)
                return
            end

            debugPrint("Custom Race Sequence: Blue checkpoint found! Waiting 5 seconds...")
            task.wait(4.5)

            if not customAutoRaceActive then return end

            debugPrint("Custom Race Sequence: Starting autoWin for " .. config.folderName)
            local wasServerRacing = autoRaceActive
            autoRaceActive = true
            
            autoWin(raceFolder, true)
            task.wait(.05)
            toggleNoclip(false)
            autoWin(raceFolder, true)
            toggleNoclip(false)
            
            autoRaceActive = wasServerRacing
            debugPrint("Custom Race Sequence: autoWin finished.")

            task.wait(.15)
            -- Switch to the other race for the next iteration
            nextRaceInSequence = (currentRaceKey == "OverAndOut") and "SplitSurfaceCircuit" or "OverAndOut"
        end)
        task.wait(1) -- pcall error cooldown
    end
    debugPrint("Custom Race Sequence: Loop stopped.")
end

tab:CreateToggle("Custom Auto Race (Sequence)", false, function(val)
    customAutoRaceActive = val
    if customAutoRaceActive then
        nextRaceInSequence = "OverAndOut" -- Always start with OverAndOut
        task.spawn(customAutoRaceLoop)
    end
end)

tab:CreateToggle("Anti-AFK", false, function(val)
    toggleAntiAFK(val)
end)

tab:CreateButton("Check Money Gained", function()
    local leaderstats = player:FindFirstChild("leaderstats")
    local cash = leaderstats and leaderstats:FindFirstChild("Cash")
    if cash then
        local currentMoney = cash.Value
        local gained = currentMoney - initialMoney
        debugPrint("[MoneyCounter] Total Money Gained: " .. formatMoney(gained))
    else
        warn("[MoneyCounter] Could not find Cash value to check.")
    end
end)

tab:CreateButton("Reset Money Counter", function()
    local leaderstats = player:FindFirstChild("leaderstats")
    local cash = leaderstats and leaderstats:FindFirstChild("Cash")
    if cash then
        initialMoney = cash.Value
        debugPrint("[MoneyCounter] Counter has been reset. New initial money: " .. formatMoney(initialMoney))
    else
        warn("[MoneyCounter] Could not find Cash value to reset.")
    end
end)

tab:CreateToggle("Staff Watch", false, function(isEnabled)
    staffWatchEnabled = isEnabled
    if staffWatchEnabled then
        if playerAddedConnection then
            playerAddedConnection:Disconnect()
        end

        if game.CreatorType == Enum.CreatorType.Group then
            playerAddedConnection = Players.PlayerAdded:Connect(function(newPlayer)
                local playerStaffInfo = checkPlayerForStaffRole(newPlayer)
                if playerStaffInfo and playerStaffInfo.IsStaff then
                    player:Kick("A staff member has joined: " .. newPlayer.Name)
                end
            end)

            for _, playerInGame in ipairs(Players:GetPlayers()) do
                if playerInGame ~= player then
                    local playerInGameStaffInfo = checkPlayerForStaffRole(playerInGame)
                    if playerInGameStaffInfo and playerInGameStaffInfo.IsStaff then
                        player:Kick("A staff member is already in the game: " .. playerInGame.Name)
                    end
                end
            end
        end
    elseif playerAddedConnection then
        playerAddedConnection:Disconnect()
        playerAddedConnection = nil
    end
end)

tab:CreateToggle("Vehicle Noclip", false, function(val)
    toggleNoclip(val)
end)

-- Unload Button
tab:CreateButton("Unload Script", function()
    local car = getCar()
    if car and car.PrimaryPart then
        car.PrimaryPart.Anchored = false
    end
    autoRaceActive = false -- Stop the loop
    autoRespawnEnabled = false
    toggleNoclip(false) -- Turn off noclip
    win:Destroy()
end)