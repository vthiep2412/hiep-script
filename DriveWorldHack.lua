--[[
- Drive World Hack by Hiep
- Keybind: RightAlt to toggle window
- Features: Drop Farm, Flying Farm, Speed Dash, Noclip, and more.
- v1.5.1: fix car enter, add box to reduce problem, noclip for the farm reducing problem
- next update: fix wrong seat entered
]]
local ok, lib = pcall(loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/vthiep2412/hiep-script/refs/heads/main/OsmiumLibraryFix.lua")));
local win = lib:CreateWindow("Drive World Hack - Keybind: RightAlt");

--==============================================================================
-- UI Setup
--==============================================================================
local tabFarm = win:CreateTab("Farm");
local tabRace = win:CreateTab("Race");
local tabMisc = win:CreateTab("Misc");
local tabCredits = win:CreateTab("Credits");

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

--==============================================================================
-- Configuration & State Variables
--==============================================================================

-- General script state
local speedDash = false;
local dashKey = Enum.KeyCode.F;
local defaultGravity = Workspace.Gravity;
local farmSpeed = 0.1;
local dashPower = 0.005;

-- Farm-specific state variables
local dropFarm = false
local flyingFarm = false 
local vehicleFlySpeed = 1200 -- studs/sec
local pointA = Vector3.new(4100, 100, -5100)
local pointB = Vector3.new(4900, 410, -5100)
local flyaroundTeleportCoord = Vector3.new(4100, 80, -5100) -- <<< CHANGE THIS: Coordinate to teleport to for fly around farm
local flyaroundDuration = 20 -- Duration in minutes for the fly around cycle

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
local targetChunk1, targetChunk2, dropFarmChunk

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
    task.wait(3)
    local terrainChunkFolder = workspace:WaitForChild("TerrainChunks", 10)
    if not terrainChunkFolder then
        warn("TerrainChunks folder not found! De-collide feature may not work.")
        return
    end

    targetChunk1 = getChunk(terrainChunkFolder, "Chunk_X4608_Z-5632", 10)
    targetChunk2 = getChunk(terrainChunkFolder, "Chunk_X4608_Z-5120", 10)
    dropFarmChunk = getChunk(terrainChunkFolder, "Chunk_X4096_Z-5632", 10)

    if targetChunk1 then setCollision(targetChunk1, false); print("Uncollided targetChunk1.") else warn("Could not find targetChunk1.") end
    if targetChunk2 then setCollision(targetChunk2, false); print("Uncollided targetChunk2.") else warn("Could not find targetChunk2.") end
    if dropFarmChunk then setCollision(dropFarmChunk, false); print("Uncollided dropFarmChunk.") else warn("Could not find dropFarmChunk.") end
end

local function collideFarmChunks()
    if targetChunk1 then setCollision(targetChunk1, true) end
    if targetChunk2 then setCollision(targetChunk2, true) end
    if dropFarmChunk then setCollision(dropFarmChunk, true) end
    print("Re-collided farm chunks.")
    targetChunk1, targetChunk2, dropFarmChunk = nil, nil, nil
end

--==============================================================================
-- Core Functions
--==============================================================================

-- Intercepts the Roblox idle kick message and simulates input to prevent it.
local function initAntiAFK()
    antiAfkConnection = Players.LocalPlayer.Idled:connect(function()
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
        print("Roblox Tried to kick you but we didn't let them kick you :D")
    end)
end

-- Creates or toggles the visibility of the Anti-AFK status GUI.
local function manageAntiAFKGui()
    if antiAFKGui and antiAFKGui.Parent then
        -- If GUI exists, just toggle its visibility
        antiAFKGui.Enabled = not antiAFKGui.Enabled
        return
    end

    -- Create the GUI for the first time if it doesn't exist
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
        {Name = "TopWall", Size = Vector3.new(1002, 2, 602), Position = Vector3.new(4500, 700, -5000)},
        {Name = "BottomWall", Size = Vector3.new(1002, 2, 602), Position = Vector3.new(4500, 50, -5000)},
        {Name = "RightWall", Size = Vector3.new(2, 640, 600), Position = Vector3.new(5000, 380, -5000)},
        {Name = "LeftWall", Size = Vector3.new(2, 640, 600), Position = Vector3.new(4000, 380, -5000)},
        {Name = "BackWall", Size = Vector3.new(1000, 640, 2), Position = Vector3.new(4500, 380, -4700)},
        {Name = "FrontWall", Size = Vector3.new(1000, 640, 2), Position = Vector3.new(4500, 380, -5300)}
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
end

-- Finds and returns the player's currently owned car.
local function getCar()
    for _, car in pairs(Workspace.Cars:GetChildren()) do
        if car:FindFirstChild("Owner") and car.Owner.Value == player then
            return car
        end
    end
end

-- Teleports the player's car to a specific Vector3 position.
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
    task.wait(1)
    root.Anchored = wasAnchored
end

-- Enables or disables noclip for the player and their vehicle.
local function toggleNoclip(val)
    vehicleNoclip = val
    
    if val then
        -- Noclip ON: Store original collision states and set CanCollide to false.
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
        -- Noclip OFF: Disconnect the Heartbeat loop and restore original collision states.
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

-- Uses BodyMovers to fly a car from a start to an end position.
local function flyCarTo(car, startPos, endPos, speed)
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

    -- Keep flying until the destination is reached or the farm is toggled off.
    while elapsed < travelTime and flyingFarm do
        BV.velocity = direction * speed
        BG.cframe = CFrame.new(root.Position, endPos)
        elapsed += task.wait()
    end

    BV:Destroy()
    BG:Destroy()
    if elapsed >= travelTime then
        root.CFrame = CFrame.new(endPos)
    end
end

-- Applies a forward velocity to the player's car.
function dash(dashPower, dirhehe)
    local char = player.Character or player.CharacterAdded:Wait();
    if (char and char:FindFirstChild("Head")) then
        local velocity = dirhehe * defaultGravity * dashPower;
        for _, car in pairs(Workspace.Cars:GetChildren()) do
            if (tostring(car.Owner.Value) == player.Name) then
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
-- Activates the Anti-AFK logic immediately on script load.
initAntiAFK()
-- Creates the visualization box but keeps it hidden until a farm is active.
setupVisualizationBox()

--==============================================================================
-- UI Element Creation
--==============================================================================

-- Race Tab
tabRace:CreateToggle("Speed Dash [keybind: F]", false, function(val)
    speedDash = val;
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
        return;
    end
    dashPower = tonumber(val) * 0.001;
end, "Change Dash Power");

-- Farm Tab
dropFarmToggle = tabFarm:CreateToggle("Drop Farm", false, function(val)
    dropFarm = val;
    updateBoxState(dropFarm or flyingFarm)
    if val then
        -- Ensure other farm is disabled
        flyingFarm = false
        if flyingFarmToggle then
            flyingFarmToggle:SetValue(false)
        end

        task.spawn(uncollideFarmChunks)

        task.spawn(function()
            while dropFarm do
                pcall(function()
                    Workspace.Gravity = 500;
                    for _, car in pairs(Workspace.Cars:GetChildren()) do
                        if (tostring(car.Owner.Value) == player.Name) then
                            car.Main.CFrame = CFrame.new(4900, 415, -5100);
                        end
                    end
                end);
                task.wait(farmSpeed);
            end
        end);
    else
        collideFarmChunks()
        -- Reset gravity when toggled off
        Workspace.Gravity = defaultGravity;
    end
end);

tabFarm:CreateTextbox("Farm speed (In seconds, default: 0.2 to 0.5)", function(val)
    if (val == "") then return end
    if (tonumber(val) == nil) then return end
    if (tonumber(val) <= 0) then
        farmSpeed = 0.1;
        return;
    end
    farmSpeed = tonumber(val);
end, "Change Farm Speed");

tabFarm:CreateSlider("Fly Around Speed", 400, 1800, function(val)
    vehicleFlySpeed = val
end, 1200, false)

flyingFarmToggle = tabFarm:CreateToggle("Flying Farm", false, function(val)
    flyingFarm = val
    updateBoxState(dropFarm or flyingFarm)
    if val then
        -- Ensure other farm is disabled
        dropFarm = false
        if dropFarmToggle then
            dropFarmToggle:SetValue(false)
        end
        -- Reset gravity in case drop farm was active
        Workspace.Gravity = defaultGravity

        task.spawn(uncollideFarmChunks)

        task.spawn(function()
            print("starting farm")
            local function respawnFirstCar()
                pcall(function()
                    print("respawning car 1")
                    flyingFarm = false
                    task.wait()
                    local character = player.Character or player.CharacterAdded:Wait()
                    local hrp = character:WaitForChild("HumanoidRootPart")
                    if not hrp then return end

                    local CarsFolder = ReplicatedStorage:WaitForChild("PlayerData"):WaitForChild(player.Name):WaitForChild("Inventory"):WaitForChild("Cars")
                    local CarModel = CarsFolder:FindFirstChildWhichIsA("Folder")

                    if not CarModel then
                        warn("Auto-respawn: No car found in inventory for player " .. player.Name)
                        return
                    end
                    hrp.CFrame = CFrame.new(4100, 80, -5100)
                    task.wait(1)
                    print("respawning car 2")
                    local playerCFrame = hrp.CFrame
                    print("playerCFrame: ", playerCFrame)
                    local args = {
                        CarModel,
                        [3] = playerCFrame
                    }
                    print("args: ", args)
                    ReplicatedStorage:WaitForChild("Systems"):WaitForChild("CarInteraction"):WaitForChild("SpawnPlayerCar"):InvokeServer(unpack(args))
                    task.wait(1)
                    local CARRR = getCar()
                    print("getted car: ", CARRR)
                    if CARRR and CARRR.PrimaryPart then
                        print("snapping car")
                        CARRR:SetPrimaryPartCFrame(playerCFrame + Vector3.new(10, 0, 0))
                        print("car respawned and +10 studs")
                    else
                        respawnFirstCar()
                        print("respawn car not found")
                        return
                    end
                    print("pressing E")
                    VirtualInputManager:SendKeyEvent(true, "E", false, game)
                    VirtualInputManager:SendKeyEvent(false, "E", false, game)
                    task.wait(0.5)
                    flyingFarm = true
                end)
            end

            while flyingFarm do
                local car = getCar()
                if car and car.PrimaryPart then
                    print("car found")
                    TptoVector(flyaroundTeleportCoord)
                    task.wait(1) 

                    local startTime = tick()
                    local lastCheck = tick()
                    -- Main farm loop; runs for the specified duration.
                    while flyingFarm and (tick() - startTime) < (flyaroundDuration * 60) do
                        if tick() - lastCheck > 5 then
                            pcall(function()
                                local char = player.Character
                                if not (char and char:FindFirstChild("HumanoidRootPart")) then return end
                                local hrp = char.HumanoidRootPart
                                local currentCar = getCar()

                                if currentCar and currentCar.PrimaryPart then
                                    local dist = (hrp.Position - currentCar.PrimaryPart.Position).Magnitude
                                    if dist > 30 then
                                        warn("Flyaround: Player is too far from car ("..tostring(dist).." studs). Respawning car.")
                                        respawnFirstCar()
                                    end
                                else
                                    warn("Flyaround: Car not found during flight. Respawning car.")
                                    respawnFirstCar()
                                    task.wait(1)
                                end
                            end)
                            lastCheck = tick()
                        else
                            local carcheck = getCar()
                            if carcheck and carcheck.PrimaryPart then
                                print("car found, ", carcheck.PrimaryPart.Position)
                            else
                                warn("Flyaround: Car lost during flight. Respawning car.")
                                respawnFirstCar()
                                task.wait(1)
                            end
                        end

                        local currentCar = getCar()
                        if not currentCar then
                            warn("Car lost during flight, stopping this cycle.")
                            break
                        end
                        pcall(function()
                            flyCarTo(currentCar, pointA, pointB, vehicleFlySpeed)
                            if flyingFarm and (tick() - startTime) < (flyaroundDuration * 60) then
                                flyCarTo(currentCar, pointB, pointA, vehicleFlySpeed)
                            end
                        end)
                    end

                    -- After the farm duration, or if the toggle is disabled manually.
                    if flyingFarm then
                        -- Teleport the car back to the starting area and reset its velocity.
                        local finalCar = getCar()
                        if finalCar and finalCar.PrimaryPart then
                            TptoVector(flyaroundTeleportCoord)
                            if finalCar.Parent then
                                for _, part in ipairs(finalCar:GetDescendants()) do
                                    if part:IsA("BasePart") then
                                        part.Velocity = Vector3.new(0, 0, 0)
                                        part.RotVelocity = Vector3.new(0, 0, 0)
                                    end
                                end
                            end
                        end
                        task.wait(5)
                    end
                else
                    -- If no car is found, try to respawn it.
                    warn("Car not found for fly around. Retrying in 3 seconds.")
                    respawnFirstCar()
                    task.wait(3)
                end
            end
        end)
    else
        collideFarmChunks()
    end
end)

tabFarm:CreateToggle("Vehicle Noclip", false, function(val)
    toggleNoclip(val)
end)

tabFarm:CreateButton("Anti AFK", function()
    manageAntiAFKGui()
end)

-- Misc Tab
tabMisc:CreateButton("Anti AFK", function()
    manageAntiAFKGui()
end)
tabMisc:CreateButton("Server Hop", function()
    pcall(function()
        local servers = HttpService:JSONDecode(game:HttpGet(
            "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"));
        for _, srv in pairs(servers.data) do
            if (srv.playing < srv.maxPlayers) then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id, player);
                break
            end
        end
    end);
end);
tabMisc:CreateButton("Rejoin", function()
    pcall(function()
        TeleportService:Teleport(game.PlaceId, player);
    end);
end);
tabMisc:CreateButton("Inf Yield", function()
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
    -- Disconnect all event connections to prevent memory leaks
    if dashConnection then dashConnection:Disconnect() end
    if antiAfkConnection then antiAfkConnection:Disconnect() end

    -- Stop any active farm loops
    dropFarm = false
    flyingFarm = false

    -- Disable noclip if it's active
    if vehicleNoclip then
        toggleNoclip(false)
    end

    -- Restore default workspace gravity
    Workspace.Gravity = defaultGravity

    -- Destroy any GUIs created by the script
    if antiAFKGui then antiAFKGui:Destroy() end
    if visualizationBox then visualizationBox:Destroy() end
end)
