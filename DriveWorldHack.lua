--[[
- Drive World Hack by Hiep v1.6
- Keybind: RightAlt to toggle window
- Features: Drop Farm, Flying Farm, Speed Dash, Noclip, and more.
- v1.6: i think wrong seat are prevent able, but i cant handle it,
    fix money collecting by remove snap and only remove velocity,
    add debug and reformat debuging, add respawn for drop farm just in case,
    fix code issue and syntax
- Test/support executor:
    velocity: fully support (any level 8 and high unc is support like velocity)
- Not tested executor:
    volcano: not test but still good in my opinion
    solara: shit dont use this, low unc and level
    xeno: even more shit than solara (xeno is detected and low unc and level)
    jjsploit: equal solara, better than xeno
    ronix: idk, it keyed btw
    drift: idk, it keyed btw
    lx63: lot of issue, error, crash but high unc and level
- Most executor that not scam could be found in these 3 website:
    https://wearedevs.net/home
    https://voxlis.net/roblox/
    https://weao.gg/
]]
print("[Hiep's Script] [Loader] Starting script...")
local ok, lib = pcall(loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/vthiep2412/hiep-script/refs/heads/main/OsmiumLibraryFix.lua")));

if not ok or not lib then
    warn("[Hiep's Script] [Loader] Critical error: Failed to load Osmium library. The script cannot continue.")
    return
end
print("[Hiep's Script] [Loader] Osmium library loaded successfully.")

local win = lib:CreateWindow("Drive World Hack - Keybind: RightAlt");
print("[Hiep's Script] [UI] Main window created.")

--==============================================================================
-- UI Setup
--==============================================================================
local tabFarm = win:CreateTab("Farm");
local tabRace = win:CreateTab("Race");
local tabMisc = win:CreateTab("Misc");
local tabCredits = win:CreateTab("Credits");
print("[Hiep's Script] [UI] Tabs created.")

--==============================================================================
-- Services & Globals
--==============================================================================
-- Caching services into local variables for performance and readability.
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")

-- Local player reference
local player = Players.LocalPlayer
print("[Hiep's Script] [Globals] Services and local player cached.")

--==============================================================================
-- Configuration & State Variables
--==============================================================================

-- General script state
local isDebugMode = false
local speedDash = false;
local dashKey = Enum.KeyCode.F;
local defaultGravity = Workspace.Gravity;
local farmSpeed = 0.05;
local dashPower = 0.005;

-- Farm-specific state variables
local dropFarm = false
local flyingFarm = false
local isPaused = false -- For pausing farm loops safely
local vehicleFlySpeed = 1200 -- studs/sec
local pointA = Vector3.new(4100, 100, -5100)
local pointB = Vector3.new(4900, 410, -5100)
local flyaroundTeleportCoord = Vector3.new(4100, 80, -5100) -- <<< CHANGE THIS: Coordinate to teleport to for fly around farm
local dropFarmTeleportCoord = Vector3.new(4900, 80, -5100)
local flyaroundDuration = 20 -- Duration in minutes for the fly around cycle
local dropFarmDuration = 20

-- Holds connections to events to be disconnected later
local dashConnection = nil
local antiAfkConnection = nil
local noclipConnections = {}

-- Holds the UI toggle objects to be controlled from other callbacks
local dropFarmToggle, flyingFarmToggle

-- Holds the GUI elements created by the script
local antiAFKGui = nil
local visualizationBox = nil

-- Farm-related chunk references
local targetChunk1, targetChunk2, dropFarmChunk, dropFarmChunk2

-- Staff Watch state
local staffWatchEnabled = false
local playerAddedConnection = nil

-- Money Counter state
local moneyCounterEnabled = false
local initialMoney = 0
print("[Hiep's Script] [Config] All state variables initialized.")

--==============================================================================
-- Debugger
--==============================================================================
local function debugPrint(message, isWarning)
    if not isDebugMode then return end
    if isWarning then
        warn(message)
    else
        print(message)
    end
end

--==============================================================================
-- de collide part(important)
--==============================================================================
-- Utility: Safe chunk loader with timeout
local function getChunk(folder, name, timeout)
    if not folder then return nil end
    local start = tick()
    local chunk = folder:FindFirstChild(name)
    while not chunk and tick() - start < timeout do
        task.wait(0.1)
        chunk = folder:FindFirstChild(name)
    end
    return chunk
end

-- Utility: Toggle collision for all parts in a model
local function setCollision(model, state)
    if not model then return end
    pcall(function()
        for _, obj in ipairs(model:GetDescendants()) do
            if obj:IsA("BasePart") then
                obj.CanCollide = state
            end
        end
    end)
end

local function uncollideFarmChunks()
    debugPrint("[Hiep's Script] [Collision] Starting to uncollide farm chunks.")
    task.wait(3)
    local terrainChunkFolder = workspace:WaitForChild("TerrainChunks", 10)
    if not terrainChunkFolder then
        debugPrint("[Hiep's Script] [Collision] TerrainChunks folder not found! De-collide feature may not work.", true)
        return
    end

    targetChunk1 = getChunk(terrainChunkFolder, "Chunk_X4608_Z-5632", 10)
    targetChunk2 = getChunk(terrainChunkFolder, "Chunk_X4608_Z-5120", 10)
    dropFarmChunk = getChunk(terrainChunkFolder, "Chunk_X4096_Z-5632", 10)
    dropFarmChunk2 = getChunk(terrainChunkFolder, "Chunk_X4096_Z-6144", 10)

    if targetChunk1 then setCollision(targetChunk1, false); debugPrint("[Hiep's Script] [Collision] Uncollided targetChunk1.") else debugPrint("[Hiep's Script] [Collision] Could not find targetChunk1.", true) end
    if targetChunk2 then setCollision(targetChunk2, false); debugPrint("[Hiep's Script] [Collision] Uncollided targetChunk2.") else debugPrint("[Hiep's Script] [Collision] Could not find targetChunk2.", true) end
    if dropFarmChunk then setCollision(dropFarmChunk, false); debugPrint("[Hiep's Script] [Collision] Uncollided dropFarmChunk.") else debugPrint("[Hiep's Script] [Collision] Could not find dropFarmChunk.", true) end
    if dropFarmChunk2 then setCollision(dropFarmChunk2, false); debugPrint("[Hiep's Script] [Collision] Uncollided dropFarmChunk2.") else debugPrint("[Hiep's Script] [Collision] Could not find dropFarmChunk2.", true) end
    debugPrint("[Hiep's Script] [Collision] Finished uncolliding chunks.")
end

local function collideFarmChunks()
    debugPrint("[Hiep's Script] [Collision] Re-colliding farm chunks.")
    if targetChunk1 then setCollision(targetChunk1, true) end
    if targetChunk2 then setCollision(targetChunk2, true) end
    if dropFarmChunk then setCollision(dropFarmChunk, true) end
    if dropFarmChunk2 then setCollision(dropFarmChunk2, true) end
    debugPrint("[Hiep's Script] [Collision] Finished re-colliding chunks.")
    targetChunk1, targetChunk2, dropFarmChunk, dropFarmChunk2 = nil, nil, nil, nil
end

--==============================================================================
-- Core Functions
--==============================================================================

-- Keywords to identify staff roles.
local staffKeywords = {
    "mod", "admin", "staff", "dev", "founder", "owner", "supervis",
    "manager", "management", "executive", "president", "chairman",
    "chairwoman", "chairperson", "director", "moderator", "supervisor",
    "administrator", "developer"
};

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

-- Checks if a player has a staff role in the group or is a Roblox employee.
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

-- Intercepts the Roblox idle kick message and simulates input to prevent it.
local function initAntiAFK()
    antiAfkConnection = Players.LocalPlayer.Idled:connect(function()
        debugPrint("[Hiep's Script] [Anti-AFK] Idle detected, preventing kick.")
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
        if antiAFKGui and antiAFKGui.Enabled then
            pcall(function()
                local lblStatus = antiAFKGui.lblTitle.frame.lblStatus
                lblStatus.Text = "Roblox Tried to kick you but we didn't let them kick you :D"
                task.wait(2)
                lblStatus.Text = "Status : Active"
            end)
        end
    end)
    debugPrint("[Hiep's Script] [Anti-AFK] Initialized.")
end

-- Creates or toggles the visibility of the Anti-AFK status GUI.
local function manageAntiAFKGui()
    if antiAFKGui and antiAFKGui.Parent then
        antiAFKGui.Enabled = not antiAFKGui.Enabled
        debugPrint("[Hiep's Script] [Anti-AFK] Toggled GUI visibility to: " .. tostring(antiAFKGui.Enabled))
        return
    end

    debugPrint("[Hiep's Script] [Anti-AFK] Creating GUI for the first time.")
    antiAFKGui = Instance.new("ScreenGui")
    local lblTitle = Instance.new("TextLabel")
    local frame = Instance.new("Frame")
    local lblMade = Instance.new("TextLabel")
    local lblStatus = Instance.new("TextLabel")

    antiAFKGui.Name = "AntiAFKGui"
    antiAFKGui.Parent = CoreGui
    antiAFKGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    antiAFKGui.Enabled = true

    lblTitle.Name = "lblTitle"
    lblTitle.Parent = antiAFKGui
    lblTitle.Active = true
    lblTitle.BackgroundColor3 = Color3.new(0.176471, 0.176471, 0.176471)
    lblTitle.Draggable = true
    lblTitle.Position = UDim2.new(0.698610067, 0, 0.098096624, 0)
    lblTitle.Size = UDim2.new(0, 370, 0, 52)
    lblTitle.Font = Enum.Font.SourceSansSemibold
    lblTitle.Text = "Anti AFK Script"
    lblTitle.TextColor3 = Color3.new(0, 1, 1)
    lblTitle.TextSize = 22

    frame.Name = "frame"
    frame.Parent = lblTitle
    frame.BackgroundColor3 = Color3.new(0.196078, 0.196078, 0.196078)
    frame.Position = UDim2.new(0, 0, 1.0192306, 0)
    frame.Size = UDim2.new(0, 370, 0, 107)

    lblMade.Name = "lblMade"
    lblMade.Parent = frame
    lblMade.BackgroundColor3 = Color3.new(0.176471, 0.176471, 0.176471)
    lblMade.Position = UDim2.new(0, 0, 0.800455689, 0)
    lblMade.Size = UDim2.new(0, 370, 0, 21)
    lblMade.Font = Enum.Font.Arial
    lblMade.Text = "Made by Dynamic. (please subscribe)"
    lblMade.TextColor3 = Color3.new(0, 1, 1)
    lblMade.TextSize = 20

    lblStatus.Name = "lblStatus"
    lblStatus.Parent = frame
    lblStatus.BackgroundColor3 = Color3.new(0.176471, 0.176471, 0.176471)
    lblStatus.Position = UDim2.new(0, 0, 0.158377, 0)
    lblStatus.Size = UDim2.new(0, 370, 0, 44)
    lblStatus.Font = Enum.Font.ArialBold
    lblStatus.Text = "Status: Active"
    lblStatus.TextColor3 = Color3.new(0, 1, 1)
    lblStatus.TextSize = 20
end

-- Controls the visibility and collision of the visualization box based on farm state.
local function updateBoxState(isFarming)
    if not visualizationBox then return end
    debugPrint("[Hiep's Script] [Farm-Vis] Updating visualization box state. Farming: " .. tostring(isFarming))
    local targetTransparency = isFarming and 0.75 or 1
    local targetCollide = isFarming

    for _, wall in ipairs(visualizationBox:GetChildren()) do
        if wall:IsA("Part") then
            wall.CanCollide = targetCollide
            wall.Transparency = targetTransparency
        end
    end
end

-- Creates the visual box for the farm area. Called once on script startup.
local function setupVisualizationBox()
    visualizationBox = Instance.new("Folder", Workspace)
    visualizationBox.Name = "VisualizationBox"

    local walls = {
        {Name = "TopWall", Size = Vector3.new(1002, 20, 602), Position = Vector3.new(4500, 700, -5000)},
        {Name = "BottomWall", Size = Vector3.new(1002, 20, 602), Position = Vector3.new(4500, 5, -5000)},
        {Name = "RightWall", Size = Vector3.new(20, 670, 600), Position = Vector3.new(5000, 350, -5000)},
        {Name = "LeftWall", Size = Vector3.new(20, 670, 600), Position = Vector3.new(4000, 350, -5000)},
        {Name = "BackWall", Size = Vector3.new(1000, 670, 20), Position = Vector3.new(4500, 350, -4700)},
        {Name = "FrontWall", Size = Vector3.new(1000, 670, 20), Position = Vector3.new(4500, 350, -5300)}
    }

    for _, wallInfo in ipairs(walls) do
        local wall = Instance.new("Part", visualizationBox)
        wall.Name = wallInfo.Name
        wall.Size = wallInfo.Size
        wall.Position = wallInfo.Position
        wall.Anchored = true
        wall.CanCollide = false
        wall.Color = Color3.fromRGB(0, 255, 255) -- Cyan
        wall.Material = Enum.Material.Neon
        wall.Transparency = 1 -- Initially invisible
    end
    debugPrint("[Hiep's Script] [Farm-Vis] Visualization box created.")
end

-- Finds and returns the player's currently owned car.
local function getCar()
    for _, car in pairs(Workspace.Cars:GetChildren()) do
        if car:FindFirstChild("Owner") and car.Owner.Value == player then
            return car
        end
    end
    return nil
end

-- Teleports the player's car to a specific Vector3 position.
local function TptoVector(targetpos)
    debugPrint("[Hiep's Script] [Teleport] Attempting to teleport car to: " .. tostring(targetpos))
    local car = getCar()
    if not (car and car.PrimaryPart) then
        debugPrint("[Hiep's Script] [Teleport] Player car not found for teleport.", true)
        return false
    end
    task.wait()
    car:SetPrimaryPartCFrame(CFrame.new(targetpos))
    task.wait(1)
    debugPrint("[Hiep's Script] [Teleport] Car teleported successfully. Pos TPed: "..tostring(targetpos))
end

-- Enables or disables noclip for the player and their vehicle.
local function toggleNoclip(val)
    vehicleNoclip = val
    debugPrint("[Hiep's Script] [Noclip] Toggled to: " .. tostring(val))
    if val then
        originalCollisions = {}
        local conn = RunService.Heartbeat:Connect(function()
            pcall(function()
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
        debugPrint("[Hiep's Script] [Noclip] Restored original collisions.")
    end
end

-- Spawns the player's first car at a given coordinate.
local function respawnCarAtCoord(coord)
    isPaused = true
    debugPrint("[Hiep's Script] [Respawn] Starting car respawn process at: " .. tostring(coord))
    pcall(function()
        task.wait()
        local character = player.Character or player.CharacterAdded:Wait()
        local hrp = character:WaitForChild("HumanoidRootPart")
        if not hrp then
            debugPrint("[Hiep's Script] [Respawn] Failed to find HumanoidRootPart.", true)
            isPaused = false; return
        end

        local CarsFolder = ReplicatedStorage:WaitForChild("PlayerData"):WaitForChild(player.Name):WaitForChild("Inventory"):WaitForChild("Cars")
        local CarModel = CarsFolder:FindFirstChildWhichIsA("Folder")

        if not CarModel then
            debugPrint("[Hiep's Script] [Respawn] No car found in inventory for player " .. player.Name, true)
            isPaused = false
            return
        end
        
        debugPrint("[Hiep's Script] [Respawn] Teleporting player to coordinate.")
        hrp.CFrame = CFrame.new(coord)
        task.wait(1)
        
        local playerCFrame = hrp.CFrame
        debugPrint("[Hiep's Script] [Respawn] Invoking server to spawn car at CFrame: " .. tostring(playerCFrame))
        local args = {
            CarModel,
            [3] = playerCFrame
        }
        ReplicatedStorage:WaitForChild("Systems"):WaitForChild("CarInteraction"):WaitForChild("SpawnPlayerCar"):InvokeServer(unpack(args))
        task.wait(1)
        
        local newCar = getCar()
        if newCar and newCar.PrimaryPart then
            debugPrint("[Hiep's Script] [Respawn] New car found, snapping to position.")
            newCar:SetPrimaryPartCFrame(playerCFrame + Vector3.new(10, 0, 0))
        else
            debugPrint("[Hiep's Script] [Respawn] Failed to find newly spawned car.", true)
        end
        
        debugPrint("[Hiep's Script] [Respawn] Simulating 'E' key press to enter car.")
        VirtualInputManager:SendKeyEvent(true, "E", false, game)
        VirtualInputManager:SendKeyEvent(false, "E", false, game)
        task.wait(0.5)
    end)
    debugPrint("[Hiep's Script] [Respawn] Car respawn process finished.")
    isPaused = false
end

-- Uses BodyMovers to fly a car from a start to an end position.
local function flyCarTo(car, startPos, endPos, speed)
    debugPrint("[Hiep's Script] [Fly] Flying car from " .. tostring(startPos) .. " to " .. tostring(endPos))
    local root = car.PrimaryPart
    local BG = Instance.new("BodyGyro")
    local BV = Instance.new("BodyVelocity")

    BG.P = 9e4
    BG.maxTorque = Vector3.new(9e9, 9e9, 9e9)
    BG.cframe = CFrame.new(startPos, endPos)
    BG.Parent = root

    BV.maxForce = Vector3.new(9e9, 9e9, 9e9)
    BV.Parent = root

    local direction = (endPos - startPos).Unit
    local distance = (endPos - startPos).Magnitude
    local travelTime = distance / speed
    local elapsed = 0

    while elapsed < travelTime and flyingFarm and not isPaused do
        BV.velocity = direction * speed
        BG.cframe = CFrame.new(root.Position, endPos)
        elapsed += task.wait()
    end

    BV:Destroy()
    BG:Destroy()
    if elapsed >= travelTime then
        root.CFrame = CFrame.new(endPos)
    end
    debugPrint("[Hiep's Script] [Fly] Flight segment finished. End position: "..tostring(endPos))
end

-- Applies a forward velocity to the player's car.
function dash(dashPower, dirhehe)
    local char = player.Character or player.CharacterAdded:Wait();
    if (char and char:FindFirstChild("Head")) then
        local velocity = dirhehe * defaultGravity * dashPower;
        for _, car in pairs(Workspace.Cars:GetChildren()) do
            if (tostring(car.Owner.Value) == player.Name) then
                debugPrint("[Hiep's Script] [Dash] Applying dash velocity.")
                for _, part in pairs(car:GetDescendants()) do
                    if (part:IsA("BasePart") and not part.Anchored) then
                        part.Velocity = part.Velocity + velocity;
                    end
                end
            end
        end
    end
end

--==============================================================================
-- Feature Initialization
--==============================================================================
initAntiAFK()
setupVisualizationBox()
print("[Hiep's Script] [Init] Core features initialized.")

--==============================================================================
-- UI Element Creation
--==============================================================================

-- Race Tab
tabRace:CreateToggle("Speed Dash [keybind: F]", false, function(val)
    speedDash = val;
    debugPrint("[Hiep's Script] [UI] Speed Dash toggled to: " .. tostring(val))
end);
dashConnection = UserInputService.InputBegan:Connect(function(input, isProcessed)
    if isProcessed then return end
    if (speedDash and (input.KeyCode == dashKey)) then
        pcall(function()
            local char = player.Character or player.CharacterAdded:Wait();
            local head = char.Head;
            local dirhehe = head.CFrame.LookVector;
            dash(dashPower, dirhehe);
        end);
    end
end)
tabRace:CreateTextbox("Dash Power [default: 5]", function(val)
    if (val == "") then return end
    if (tonumber(val) == nil) then return end
    if (tonumber(val) <= 0) then
        dashPower = 0.001;
    else
        dashPower = tonumber(val) * 0.001;
    end
    debugPrint("[Hiep's Script] [UI] Dash Power set to: " .. tostring(dashPower))
end, "Change Dash Power");

-- Farm Tab
dropFarmToggle = tabFarm:CreateToggle("Drop Farm", false, function(val)
    dropFarm = val;
    debugPrint("[Hiep's Script] [DropFarm] Toggled to: " .. tostring(val))
    updateBoxState(dropFarm or flyingFarm)
    if val then
        flyingFarm = false
        if flyingFarmToggle then
            flyingFarmToggle:SetValue(false)
        end
        debugPrint("[Hiep's Script] [DropFarm] Starting farm monitor and main loop.")
        task.spawn(function()
            while dropFarm do
                task.wait(5)
                pcall(function()
                    if isPaused or not dropFarm then return end
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
                                if dist > 50 then
                                    needsRespawn = true
                                    reason = "Player is too far from car ("..tostring(dist).." studs)."
                                end
                            end
                        end
                    end

                    if needsRespawn then
                        debugPrint("[Hiep's Script] [DropFarm-Monitor] Condition triggered respawn. Reason: " .. reason, true)
                        respawnCarAtCoord(dropFarmTeleportCoord)
                        task.wait(5)
                    end
                end)
            end
        end)

        task.spawn(uncollideFarmChunks)
        task.spawn(function()
            while dropFarm do
                local startTime = tick()
                debugPrint("[Hiep's Script] [DropFarm] Starting new drop cycle for " .. dropFarmDuration .. " minutes.")
                while dropFarm and (tick() - startTime) < (dropFarmDuration * 60) and not isPaused do
                    pcall(function()
                        Workspace.Gravity = 490;
                        local car = getCar()
                        if car and not isPaused then
                            car.Main.CFrame = CFrame.new(4900, 430, -5100);
                        end
                    end);
                    task.wait(farmSpeed);
                end

                if dropFarm and not isPaused then
                    debugPrint("[Hiep's Script] [DropFarm] Drop cycle finished. Resetting car velocity and wait for collecting money.")
                    local finalCar = getCar()
                    if finalCar and finalCar.PrimaryPart and finalCar.Parent then
                        for _, part in ipairs(finalCar:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.Velocity = Vector3.new(0, 0, 0)
                                part.RotVelocity = Vector3.new(0, 0, 0)
                            end
                        end
                    end
                    task.wait(6)
                end
            end
        end);
    else
        collideFarmChunks()
        Workspace.Gravity = defaultGravity;
        debugPrint("[Hiep's Script] [DropFarm] Disabled. Gravity restored.")
    end
end);

tabFarm:CreateTextbox("Farm speed (In seconds, default: 0.05 to 0.3)", function(val)
    if (val == "") then return end
    if (tonumber(val) == nil) then return end
    if (tonumber(val) <= 0) then
        farmSpeed = 0;
    else
        farmSpeed = tonumber(val);
    end
    debugPrint("[Hiep's Script] [UI] Farm Speed set to: " .. tostring(farmSpeed))
end, "Change Farm Speed");

tabFarm:CreateSlider("Fly Around Speed", 400, 1800, function(val)
    vehicleFlySpeed = val
    debugPrint("[Hiep's Script] [UI] Fly Around Speed set to: " .. tostring(val))
end, 1200, false)

flyingFarmToggle = tabFarm:CreateToggle("Flying Farm", false, function(val)
    flyingFarm = val
    debugPrint("[Hiep's Script] [FlyingFarm] Toggled to: " .. tostring(val))
    updateBoxState(dropFarm or flyingFarm)
    if val then
        dropFarm = false
        if dropFarmToggle then
            dropFarmToggle:SetValue(false)
        end
        Workspace.Gravity = defaultGravity
        debugPrint("[Hiep's Script] [FlyingFarm] Starting farm monitor and main loop.")
        task.spawn(function()
            while flyingFarm do
                task.wait(5)
                pcall(function()
                    if isPaused or not flyingFarm then return end
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
                                if dist > 50 then
                                    needsRespawn = true
                                    reason = "Player is too far from car ("..tostring(dist).." studs)."
                                end
                            end
                        end
                    end

                    if needsRespawn then
                        debugPrint("[Hiep's Script] [FlyingFarm-Monitor] Condition triggered respawn. Reason: " .. reason, true)
                        respawnCarAtCoord(flyaroundTeleportCoord)
                        task.wait(5)
                    end
                end)
            end
        end)
        task.spawn(uncollideFarmChunks)
        task.spawn(function()
            while flyingFarm do
                while isPaused and flyingFarm do
                    task.wait(0.1)
                end
                if not flyingFarm then break end

                local car = getCar()
                if car and car.PrimaryPart then
                    TptoVector(flyaroundTeleportCoord)
                    task.wait(1)

                    local startTime = tick()
                    debugPrint("[Hiep's Script] [FlyingFarm] Starting new fly cycle for " .. flyaroundDuration .. " minutes.")
                    while flyingFarm and (tick() - startTime) < (flyaroundDuration * 60) do
                        if isPaused then
                            task.wait(0.5)
                        else
                            local currentCar = getCar()
                            if currentCar and currentCar.PrimaryPart then
                                pcall(function()
                                    flyCarTo(currentCar, pointA, pointB, vehicleFlySpeed)
                                    if flyingFarm and (tick() - startTime) < (flyaroundDuration * 60) then
                                        flyCarTo(currentCar, pointB, pointA, vehicleFlySpeed)
                                    end
                                end)
                            else
                                debugPrint("[Hiep's Script] [FlyingFarm] Car not found mid-loop. Waiting for monitor to respawn.", true)
                                task.wait(1)
                            end
                        end
                    end

                    if flyingFarm and not isPaused then
                        debugPrint("[Hiep's Script] [FlyingFarm] Fly cycle finished. Resetting car velocity.")
                        local finalCar = getCar()
                        if finalCar and finalCar.PrimaryPart and finalCar.Parent then
                            for _, part in ipairs(finalCar:GetDescendants()) do
                                if part:IsA("BasePart") then
                                    part.Velocity = Vector3.new(0, 0, 0)
                                    part.RotVelocity = Vector3.new(0, 0, 0)
                                end
                            end
                        end
                        task.wait(6)
                    end
                else
                    debugPrint("[Hiep's Script] [FlyingFarm] Car not found at start of loop. Attempting respawn.", true)
                    respawnCarAtCoord(flyaroundTeleportCoord)
                    task.wait(3)
                end
            end
        end)
    else
        isPaused = false
        collideFarmChunks()
        debugPrint("[Hiep's Script] [FlyingFarm] Disabled.")
    end
end)

tabFarm:CreateToggle("Vehicle Noclip", false, function(val)
    toggleNoclip(val)
end)

tabFarm:CreateButton("Anti AFK", function()
    manageAntiAFKGui()
end)

-- Misc Tab
tabMisc:CreateToggle("Enable Debug Console", false, function(val)
    isDebugMode = val
    if val then
        print("[Hiep's Script] [Debug] Debug console enabled.")
    else
        print("[Hiep's Script] [Debug] Debug console disabled.")
    end
end)

tabMisc:CreateButton("Anti AFK", function()
    manageAntiAFKGui()
end)

tabMisc:CreateToggle("Staff Watch", false, function(isEnabled)
    staffWatchEnabled = isEnabled
    debugPrint("[Hiep's Script] [StaffWatch] Toggled to: " .. tostring(isEnabled))
    if staffWatchEnabled then
        if playerAddedConnection then
            playerAddedConnection:Disconnect()
        end

        if game.CreatorType == Enum.CreatorType.Group then
            debugPrint("[Hiep's Script] [StaffWatch] Group game detected. Activating watch.")
            playerAddedConnection = Players.PlayerAdded:Connect(function(newPlayer)
                local playerStaffInfo = checkPlayerForStaffRole(newPlayer)
                if playerStaffInfo and playerStaffInfo.IsStaff then
                    debugPrint("[Hiep's Script] [StaffWatch] Staff member joined: " .. newPlayer.Name .. ". Kicking local player.", true)
                    player:Kick("A staff member has joined: " .. newPlayer.Name)
                end
            end)

            for _, playerInGame in ipairs(Players:GetPlayers()) do
                if playerInGame ~= player then
                    local playerInGameStaffInfo = checkPlayerForStaffRole(playerInGame)
                    if playerInGameStaffInfo and playerInGameStaffInfo.IsStaff then
                        debugPrint("[Hiep's Script] [StaffWatch] Staff member already in game: " .. playerInGame.Name .. ". Kicking local player.", true)
                        player:Kick("A staff member is already in the game: " .. playerInGame.Name)
                    end
                end
            end
        else
            debugPrint("[Hiep's Script] [StaffWatch] This is not a group game, so the feature won't run.", true)
        end
    elseif playerAddedConnection then
        playerAddedConnection:Disconnect()
        playerAddedConnection = nil
        debugPrint("[Hiep's Script] [StaffWatch] Watch disabled and connection disconnected.")
    end
end)

-- Money Counter
task.spawn(function()
    local leaderstats = player:WaitForChild("leaderstats")
    local cash = leaderstats and leaderstats:WaitForChild("Cash")
    if cash then
        initialMoney = cash.Value
        debugPrint("[Hiep's Script] [MoneyCounter] Initialized. Starting money: " .. formatMoney(initialMoney))
    else
        debugPrint("[Hiep's Script] [MoneyCounter] Could not find Cash value on startup.", true)
    end
end)

tabFarm:CreateButton("Check Money Gained", function()
    local leaderstats = player:FindFirstChild("leaderstats")
    local cash = leaderstats and leaderstats:FindFirstChild("Cash")
    if cash then
        local currentMoney = cash.Value
        local gained = currentMoney - initialMoney
        debugPrint("[Hiep's Script] [MoneyCounter] Total Money Gained: " .. formatMoney(gained))
    else
        debugPrint("[Hiep's Script] [MoneyCounter] Could not find Cash value to check.", true)
    end
end)

tabFarm:CreateButton("Reset Money Counter", function()
    local leaderstats = player:FindFirstChild("leaderstats")
    local cash = leaderstats and leaderstats:FindFirstChild("Cash")
    if cash then
        initialMoney = cash.Value
        debugPrint("[Hiep's Script] [MoneyCounter] Counter has been reset. New initial money: " .. formatMoney(initialMoney))
    else
        debugPrint("[Hiep's Script] [MoneyCounter] Could not find Cash value to reset.", true)
    end
end)

tabMisc:CreateButton("Server Hop", function()
    debugPrint("[Hiep's Script] [Teleport] Attempting to server hop.")
    pcall(function()
        local servers = HttpService:JSONDecode(game:HttpGet(
            "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"));
        for _, srv in pairs(servers.data) do
            if (srv.playing < srv.maxPlayers) then
                debugPrint("[Hiep's Script] [Teleport] Found a server with space. Teleporting to instance " .. srv.id)
                TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id, player);
                break
            end
        end
    end);
end);
tabMisc:CreateButton("Rejoin", function()
    debugPrint("[Hiep's Script] [Teleport] Attempting to rejoin the current server.")
    pcall(function()
        TeleportService:Teleport(game.PlaceId, player);
    end);
end);
tabMisc:CreateButton("Inf Yield", function()
    debugPrint("[Hiep's Script] [Misc] Loading Infinite Yield.")
    pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))();
    end);
end);
tabMisc:CreateButton("Unload Script", function()
    win:Destroy()
end)

-- Credits Tab
tabCredits:CreateLabel("Made by Hiep");
tabCredits:CreateLabel("Discord: Hiepvu123");
tabCredits:CreateLabel("GitHub: https://github.com/vthiep2412/hiep-script");
tabCredits:CreateLabel("This script is open source, for everyone to use, not update daily btw")

--==============================================================================
-- Cleanup Logic
--==============================================================================
win:OnDestroy(function()
    print("[Hiep's Script] [Cleanup] Unloading script and cleaning up connections.")
    -- Disconnect all event connections to prevent memory leaks
    if dashConnection then dashConnection:Disconnect() end
    if antiAfkConnection then antiAfkConnection:Disconnect() end
    if playerAddedConnection then playerAddedConnection:Disconnect() end

    -- Stop any active farm loops
    dropFarm = false
    flyingFarm = false
    moneyCounterEnabled = false

    -- Disable noclip if it's active
    if vehicleNoclip then
        toggleNoclip(false)
    end

    -- Restore default workspace gravity
    Workspace.Gravity = defaultGravity

    -- Destroy any GUIs created by the script
    if antiAFKGui then antiAFKGui:Destroy() end
    if visualizationBox then visualizationBox:Destroy() end
    print("[Hiep's Script] [Cleanup] Script fully unloaded. TYSM for using my script")
end)