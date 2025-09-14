--[[erm i should make a hanlde to stop execute in other game]] --
local ok, lib = pcall(loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/vthiep2412/hiep-script/refs/heads/main/OsmiumLibraryFix.lua")));
local win = lib:CreateWindow("Drive World Hack - Keybind: RightAlt");

--ui setup
local tabFarm = win:CreateTab("Farm");
local tabRace = win:CreateTab("Race");
local tabMisc = win:CreateTab("Misc");
local tabCredits = win:CreateTab("Credits");

--drop farm and dash var
local flyingFarm = false;
local unused1 = false;
local speedDash = false;
local dashKey = Enum.KeyCode.F;
local unused2 = false;
local defaultGravity = game:GetService("Workspace").Gravity;
local farmSpeed = 1;
local dashPower = 0.005;

--flying around var
local flyaround = false
local vehicleFlySpeed = 1200 -- studs/sec
local pointA = Vector3.new(4100, 100, -5100)
local pointB = Vector3.new(4900, 410, -5100)
local flyaroundTeleportCoord = Vector3.new(4100, 80, -5100) -- <<< CHANGE THIS: Coordinate to teleport to for fly around farm
local flyaroundDuration = 20 -- Duration in minutes for the fly around cycle

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local dashConnection = nil
local antiAfkConnection = nil

local function getCar() -- Forward declaration for toggleNoclip
    for _, car in pairs(workspace.Cars:GetChildren()) do
        if car:FindFirstChild("Owner") and car.Owner.Value == player then
            return car
        end
    end
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
    task.wait(1)
    root.Anchored = wasAnchored
end

local vehicleNoclip = false
local noclipConnections = {}
local originalCollisions = {}

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

    while elapsed < travelTime and flyaround do
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

local function getCar()
    for _, car in pairs(workspace.Cars:GetChildren()) do
        if car:FindFirstChild("Owner") and car.Owner.Value == player then
            if car.PrimaryPart then
                return car
            end
        end
    end
end

function dash(dashPower, dirhehe)
    local player = game:GetService("Players").LocalPlayer;
    local char = player.Character or player.CharacterAdded:Wait();
    if (char and char:FindFirstChild("Head")) then
        local velocity = dirhehe * defaultGravity * dashPower;
        for _, car in pairs(game:GetService("Workspace").Cars:GetChildren()) do
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

tabRace:CreateToggle("Speed Dash [keybind: F]", false, function(val)
    speedDash = val;
end);
local inputService = game:GetService("UserInputService");
dashConnection = inputService.InputBegan:Connect(function(input, isProcessed)
    if isProcessed then return end
    if (speedDash and (input.KeyCode == dashKey)) then
        pcall(function()
            local player = game:GetService("Players").LocalPlayer;
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
-- Remove duplicate or outdated Flying Farm toggles
local flyingFarm = false;
tabFarm:CreateToggle("Flying Farm", false, function(val)
    flyingFarm = val;
    if val then
        task.spawn(function()
            while flyingFarm do
                pcall(function()
                    game:GetService("Workspace").Gravity = 500;
                    for _, car in pairs(game:GetService("Workspace").Cars:GetChildren()) do
                        if (tostring(car.Owner.Value) == game:GetService("Players").LocalPlayer.Name) then
                            car.Main.CFrame = CFrame.new(4900, 400, -5100);
                        end
                    end
                end);
                task.wait(farmSpeed);
            end
        end);
    else
        game:GetService("Workspace").Gravity = defaultGravity;
    end
end);
tabFarm:CreateTextbox("Farm speed (In seconds, default: 1-2)", function(val)
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

tabFarm:CreateToggle("Flying around farm", false, function(val)
    flyaround = val
    if val then
        task.spawn(function()
            print("starting farm")
            local function respawnFirstCar()
                pcall(function()
                    local player = game:GetService("Players").LocalPlayer
                    local character = player.Character or player.CharacterAdded:Wait()
                    local hrp = character:WaitForChild("HumanoidRootPart")
                    if not hrp then return end

                    local ReplicatedStorage = game:GetService("ReplicatedStorage")
                    local CarsFolder = ReplicatedStorage:WaitForChild("PlayerData"):WaitForChild(player.Name):WaitForChild("Inventory"):WaitForChild("Cars")
                    local CarModel = CarsFolder:FindFirstChildWhichIsA("Folder")

                    if not CarModel then
                        warn("Auto-respawn: No car found in inventory for player " .. player.Name)
                        return
                    end
                    hrp.CFrame = CFrame.new(4100, 80, -5100)
                    task.wait(1)
                    print("respawning car")
                    local playerCFrame = hrp.CFrame
                    local args = {
                        CarModel,
                        [3] = playerCFrame
                    }
                    -- print(playerCFrame)
                    ReplicatedStorage:WaitForChild("Systems"):WaitForChild("CarInteraction"):WaitForChild("SpawnPlayerCar"):InvokeServer(unpack(args))
                    task.wait(1)
                    local CARRR = getCar()
                    if CARRR and CARRR.PrimaryPart then
                        CARRR:SetPrimaryPartCFrame(playerCFrame)
                        print("car respawned")
                    end
                    local VirtualInputManager = game:GetService("VirtualInputManager")
                    task.wait(1)
                    VirtualInputManager:SendKeyEvent(true, "E", false, game)
                    VirtualInputManager:SendKeyEvent(false, "E", false, game)
                end)
            end

            while flyaround do
                local car = getCar()
                if car and car.PrimaryPart then
                    print("car found")
                    -- Teleport to start position
                    TptoVector(flyaroundTeleportCoord)
                    task.wait(1) -- wait a bit after teleport

                    local startTime = tick()
                    local lastCheck = tick()
                    -- Fly for 30 minutes
                    while flyaround and (tick() - startTime) < (flyaroundDuration * 60) do
                        if tick() - lastCheck > 10 then
                            pcall(function()
                                local player = game:GetService("Players").LocalPlayer
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
                                end
                            end)
                            lastCheck = tick()
                        else 
                            print("car found, ticked")
                        end

                        local currentCar = getCar()
                        if not currentCar then
                            warn("Car lost during flight, stopping this cycle.")
                            break
                        end
                        pcall(function()
                            flyCarTo(currentCar, pointA, pointB, vehicleFlySpeed)
                            if flyaround and (tick() - startTime) < (flyaroundDuration * 60) then
                                flyCarTo(currentCar, pointB, pointA, vehicleFlySpeed)
                            end
                        end)
                    end

                    -- After 30 mins or if toggle is turned off
                    if flyaround then
                        -- Teleport back and wait
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
                    -- No car found, wait before trying again
                    warn("Car not found for fly around. Retrying in 3 seconds.")
                    task.wait(3)
                    respawnFirstCar()
                end
            end
        end)
    end
end)

local antiAFKGui = nil
function showAntiAFKGui()
    if antiAFKGui and antiAFKGui.Parent == game.CoreGui then return end
    antiAFKGui = Instance.new("ScreenGui")
    local lblTitle = Instance.new("TextLabel")
    local frame = Instance.new("Frame")
    local lblMade = Instance.new("TextLabel")
    local lblStatus = Instance.new("TextLabel")
    antiAFKGui.Parent = game.CoreGui
    antiAFKGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
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
    frame.Parent = lblTitle
    frame.BackgroundColor3 = Color3.new(0.196078, 0.196078, 0.196078)
    frame.Position = UDim2.new(0, 0, 1.0192306, 0)
    frame.Size = UDim2.new(0, 370, 0, 107)
    lblMade.Parent = frame
    lblMade.BackgroundColor3 = Color3.new(0.176471, 0.176471, 0.176471)
    lblMade.Position = UDim2.new(0, 0, 0.800455689, 0)
    lblMade.Size = UDim2.new(0, 370, 0, 21)
    lblMade.Font = Enum.Font.Arial
    lblMade.Text = "Made by Dynamic. (please subscribe)"
    lblMade.TextColor3 = Color3.new(0, 1, 1)
    lblMade.TextSize = 20
    lblStatus.Parent = frame
    lblStatus.BackgroundColor3 = Color3.new(0.176471, 0.176471, 0.176471)
    lblStatus.Position = UDim2.new(0, 0, 0.158377, 0)
    lblStatus.Size = UDim2.new(0, 370, 0, 44)
    lblStatus.Font = Enum.Font.ArialBold
    lblStatus.Text = "Status: Active"
    lblStatus.TextColor3 = Color3.new(0, 1, 1)
    lblStatus.TextSize = 20
    local virtUser = game:service("VirtualUser")
    antiAfkConnection = game:service("Players").LocalPlayer.Idled:connect(function()
        virtUser:CaptureController()
        virtUser:ClickButton2(Vector2.new())
        lblStatus.Text = "Roblox Tried to kick you but we didn't let them kick you :D"
        wait(2)
        lblStatus.Text = "Status : Active"
    end)
end

tabFarm:CreateToggle("Vehicle Noclip", false, function(val)
    toggleNoclip(val)
end)

tabFarm:CreateButton("Anti AFK", function()
    pcall(function()
        wait(0.5)
        showAntiAFKGui()
    end)
end)
tabMisc:CreateButton("Anti AFK", function()
    pcall(function()
        wait(0.5)
        showAntiAFKGui()
    end)
end)
tabMisc:CreateButton("Server Hop", function()
    pcall(function()
        local servers = game:GetService("HttpService"):JSONDecode(game:HttpGet(
            "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"));
        for _, srv in pairs(servers.data) do
            if (srv.playing < srv.maxPlayers) then
                game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, srv.id,
                    game:GetService("Players").LocalPlayer);
                break
            end
        end
    end);
end);
tabMisc:CreateButton("Rejoin", function()
    pcall(function()
        local tpService = game:GetService("TeleportService");
        local players = game:GetService("Players");
        tpService:Teleport(game.PlaceId, players.LocalPlayer);
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

tabCredits:CreateLabel("Made by Hiep");
tabCredits:CreateLabel("Discord: Hiepvu123");
tabCredits:CreateLabel("GitHub: https://github.com/vthiep2412/hiep-script");
tabCredits:CreateLabel("This script is open source, for everyone to use, not update daily btw")

win:OnDestroy(function()
    -- Disconnect signals
    if dashConnection then dashConnection:Disconnect() end
    if antiAfkConnection then antiAfkConnection:Disconnect() end

    -- Stop loops
    flyingFarm = false
    flyaround = false

    -- Clean up noclip
    if vehicleNoclip then
        toggleNoclip(false)
    end

    -- Reset gravity
    game:GetService("Workspace").Gravity = defaultGravity

    -- Destroy anti-afk gui
    if antiAFKGui then antiAFKGui:Destroy() end
end)