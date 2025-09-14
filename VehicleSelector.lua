-- Boilerplate to load library and create window/tab
local ok, lib = pcall(loadstring(game:HttpGet("https://raw.githubusercontent.com/vthiep2412/hiep-script/refs/heads/main/OsmiumLibraryFix.lua")))
if not ok then warn(lib) return end

local win = lib:CreateWindow("Vehicle Automation")
local tab = win:CreateTab("Main")

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local VirtualInputManager = game:GetService("VirtualInputManager")

-- Noclip variables and function
local vehicleNoclip = false
local noclipConnections = {}
local originalCollisions = {}

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

-- Automation state
local trailerFarmActive = false

-- Corrected function to get the ATTACHED trailer from inside the car
local function getAttachedTrailer()
    local car = getCar()
    if car then
        return car:FindFirstChild("Trailer")
    end
end

-- Core flight function (stops at destination)
local function SimpleFly(car, startPos, endPos, speed)
    local root = car.PrimaryPart
    if not root then return end

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
    if distance == 0 then return end

    while trailerFarmActive and (root.Position - endPos).Magnitude > 50 do
        if not (car and car.Parent) then break end
        BV.velocity = direction * speed
        BG.cframe = CFrame.new(root.Position, endPos)
        task.wait()
    end

    if BG.Parent then BG:Destroy() end
    if BV.Parent then BV:Destroy() end

    -- Stop all velocity on the car to prevent drifting
    if car and car.Parent then
        for _, part in ipairs(car:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Velocity = Vector3.new(0, 0, 0)
                part.RotVelocity = Vector3.new(0, 0, 0)
            end
        end
    end
end

-- Reusable 3-step teleport function
local function GoToLocation(targetPosition)
    local car = getCar()
    if not (car and car.PrimaryPart) then
        warn("Player car not found for GoTo.")
        return false
    end

    local finalTargetPos = targetPosition
    local startPos = car.PrimaryPart.Position
    local downPos = Vector3.new(startPos.X, startPos.Y - 50, startPos.Z)
    local acrossPos = Vector3.new(finalTargetPos.X, finalTargetPos.Y - 50, finalTargetPos.Z)

    local root = car.PrimaryPart
    local wasAnchored = root.Anchored
    
    -- Step 1: Go Down (Instant)
    root.Anchored = true
    car:SetPrimaryPartCFrame(CFrame.new(downPos))
    root.Anchored = wasAnchored
    task.wait(0.1)

    -- Step 2: Fly Across (Smooth)
    toggleNoclip(true)
    if trailerFarmActive then SimpleFly(car, downPos, acrossPos, 640) end
    toggleNoclip(false)
    -- Step 3: Go Up (Instant)
    task.wait(1)
    if trailerFarmActive then
        root.Anchored = true
        car:SetPrimaryPartCFrame(CFrame.new(finalTargetPos.X-10, finalTargetPos.Y + 5, finalTargetPos.Z-10))
        root.Anchored = wasAnchored
    end
    
    -- Final step: Stop velocity
    task.wait(0.1)
    for _, part in ipairs(car:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Velocity = Vector3.new(0, 0, 0)
            part.RotVelocity = Vector3.new(0, 0, 0)
        end
    end
    return true
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
end

-- Main automation loop
local function mainLoop()
    while trailerFarmActive do
        pcall(function()
            local gui = game.Players.LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("TrailerDeliveryComplete")
            if gui then
                for i,v in next, getconnections(game:GetService("Players").LocalPlayer.PlayerGui.TrailerDeliveryComplete.Frame.Content.Buttons.CashOut.MouseButton1Click) do
                    v:Fire()
                    print("closed")
                end
                for i,v in next, getconnections(game:GetService("Players").LocalPlayer.PlayerGui.TrailerDeliveryComplete.Frame.Content.Buttons.CloseButton.MouseButton1Click) do
                    v:Fire()
                    print("closed")
                end
                task.wait(0.5)
            end
            local car = getCar()
            if not car then
                -- warn("no car found, trying to create a new one")
                local Cars = ReplicatedStorage:WaitForChild("PlayerData"):WaitForChild(game:GetService("Players").LocalPlayer.Name):WaitForChild("Inventory"):WaitForChild("Cars")
                local normalcar = Cars:FindFirstChildWhichIsA("Folder")
                ReplicatedStorage:WaitForChild("Systems"):WaitForChild("CarInteraction"):WaitForChild("SpawnPlayerCar"):InvokeServer(normalcar)
                task.wait(.5)
                car = getCar()
            else
                -- print("there already a car")
            end
            local rootCAR = car.PrimaryPart
            rootCAR.Anchored = false
            local destinationPart
            countdown = workspace:FindFirstChild("DestinationCountdown", true)
            if not (countdown and countdown.Parent and countdown.Parent.Parent) then
                game:GetService("ReplicatedStorage"):WaitForChild("Systems"):WaitForChild("TrailerJobs"):WaitForChild("JobQuit"):FireServer()
                game:GetService("ReplicatedStorage"):WaitForChild("Systems"):WaitForChild("Trailers"):WaitForChild("DetachTrailer"):FireServer()
            end
            -- Check for an existing job first
            local countdown = workspace:FindFirstChild("DestinationCountdown", true)
            if countdown and countdown.Parent and countdown.Parent.Parent then
                print("Existing job found, proceeding to destination.")
                destinationPart = countdown.Parent.Parent
            else
                -- 1. FIND AND GO TO JOB TRAILER
                print("No active job found. Starting a new one.")
                local jobTrailersFolder = workspace:FindFirstChild("JobTrailers")
                if not (jobTrailersFolder and #jobTrailersFolder:GetChildren() > 0) then
                    warn("No job trailers found. Waiting...")
                    task.wait(3) -- Wait before checking again
                    return
                end
                local jobTrailerForPickup = jobTrailersFolder:GetChildren()[math.random(1, #jobTrailersFolder:GetChildren())]
                local jobTrailerPos = jobTrailerForPickup:GetPivot().Position + Vector3.new(0, 5, 0)
                
                print("Moving to job trailer pickup...")
                TptoVector(jobTrailerPos)
                task.wait(1)

                -- 2. ATTACH TRAILER (PRESS E)
                print("Attempting to attach trailer...")
                VirtualInputManager:SendKeyEvent(true, "E", false, game)
                VirtualInputManager:SendKeyEvent(false, "E", false, game)
                task.wait(0.5) -- Wait for trailer to attach

                -- 3. START THE JOB
                local attachedTrailer = getAttachedTrailer()
                if not attachedTrailer then
                    warn("Failed to attach trailer. Restarting loop.")
                    -- TptoVector(CFrame.new(0, 0, 0))
                    -- print("waiting 5min")
                    -- task.wait(1)
                    -- return
                end
                print("Attempting to start job...")
                local args = {
                    workspace:WaitForChild("Cars"):WaitForChild(car.Name):WaitForChild("Trailer")
                }
                game:GetService("ReplicatedStorage"):WaitForChild("Systems"):WaitForChild("TrailerJobs"):WaitForChild("StartTrailerJob"):FireServer(unpack(args))
                print("started job ",car.Name)
                task.wait(1) -- Wait for destination to appear

                -- Re-check for destination
                countdown = workspace:FindFirstChild("DestinationCountdown", true)
                while not (countdown and countdown.Parent and countdown.Parent.Parent) do
                    warn("Job destination did not appear after starting job. Retrying.")
                    local args = {
                        workspace:WaitForChild("Cars"):WaitForChild(car.Name):WaitForChild("Trailer")
                    }
                    game:GetService("ReplicatedStorage"):WaitForChild("Systems"):WaitForChild("TrailerJobs"):WaitForChild("StartTrailerJob"):FireServer(unpack(args))
                end
                destinationPart = countdown.Parent.Parent
            end

            -- 4. GO TO DESTINATION
            local destinationPos = destinationPart:GetPivot().Position
            print("Moving to final destination...")
            if not GoToLocation(destinationPos) then return end
            if not trailerFarmActive then return end
            task.wait(1)

            -- 5. DELIVER TRAILER & VERIFY
            local deliveryAttempts = 0
            while deliveryAttempts < 3 and trailerFarmActive do
                -- Check if destination still exists before attempting delivery
                if not (destinationPart and destinationPart.Parent) then
                    print("Destination disappeared, assuming job complete.")
                    -- break -- Exit the delivery loop
                end

                print("Delivering trailer (Attempt " .. deliveryAttempts + 1 .. ")...")
                local finalAttachedTrailer = getAttachedTrailer()
                if finalAttachedTrailer and finalAttachedTrailer.PrimaryPart then
                    local rootCarr = car.PrimaryPart
                    local wasCarAnchored = rootCarr.Anchored
                    local root = finalAttachedTrailer.PrimaryPart
                    local wasAnchored = root.Anchored
                    task.wait(.3)
                    root.Anchored = true
                    rootCarr.Anchored = true
                    car:SetPrimaryPartCFrame(CFrame.new(destinationPos))
                    finalAttachedTrailer:SetPrimaryPartCFrame(CFrame.new(destinationPos))
                    task.wait(3.2)
                    -- finalAttachedTrailer:SetPrimaryPartCFrame(CFrame.new(destinationPos))
                    rootCarr.Anchored = wasCarAnchored
                    root.Anchored = wasAnchored
                    -- task.wait(4) -- Wait for delay
                    -- game:GetService("ReplicatedStorage"):WaitForChild("Systems"):WaitForChild("TrailerJobs"):WaitForChild("JobCompleted"):FireServer()
                    -- task.wait(1) -- Wait for delivery to process
                else
                    warn("Could not find attached trailer to deliver. Restarting main loop.")
                    return -- Exit pcall to restart main loop
                end
                
                task.wait(.5) -- Wait for delivery to register

                -- If destination is gone, break the delivery loop
                if not workspace:FindFirstChild("DestinationCountdown", true) then
                    print("Delivery successful.")
                    local root = car.PrimaryPart
                    root.Anchored = false
                    task.wait()
                    break
                end
                
                deliveryAttempts = deliveryAttempts + 1
                if deliveryAttempts < 2 then
                    warn("Delivery may have failed. Retrying...")
                    game:GetService("ReplicatedStorage"):WaitForChild("Systems"):WaitForChild("TrailerJobs"):WaitForChild("JobQuit"):FireServer()
                    game:GetService("ReplicatedStorage"):WaitForChild("Systems"):WaitForChild("Trailers"):WaitForChild("DetachTrailer"):FireServer()
                else
                    warn("Failed to deliver trailer after 2 attempts. Restarting main loop.")
                    return -- Exit pcall to restart main loop
                end
            end
            for i,v in next, getconnections(game:GetService("Players").LocalPlayer.PlayerGui.TrailerDeliveryComplete.Frame.Content.Buttons.CashOut.MouseButton1Click) do
                v:Fire()
                print("closed")
            end
            for i,v in next, getconnections(game:GetService("Players").LocalPlayer.PlayerGui.TrailerDeliveryComplete.Frame.Content.Buttons.CloseButton.MouseButton1Click) do
                v:Fire()
                print("closed")
            end
            task.wait(0.5)
            -- 6. FINAL STEP
            print("Job cycle finished. Starting next one.")
        end)
        task.wait(1) -- Cooldown before next loop
    end
end

-- UI Elements
tab:CreateToggle("Trailer Farm", false, function(val)
    trailerFarmActive = val
    if trailerFarmActive then
        task.spawn(mainLoop)
    end
end)

tab:CreateToggle("Vehicle Noclip", false, function(val)
    toggleNoclip(val)
end)

-- Unload Button
tab:CreateButton("Unload Script", function()
    car = getCar()
    local root = car.PrimaryPart
    root.Anchored = false
    trailerFarmActive = false -- Stop the loop
    toggleNoclip(false) -- Turn off noclip
    win:Destroy()
end)