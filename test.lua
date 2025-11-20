-- Boilerplate to load library and create window/tab
local ok, lib = pcall(loadstring(game:HttpGet("https://raw.githubusercontent.com/vthiep2412/hiep-script/refs/heads/main/OsmiumLibraryFix.lua")))
if not ok then warn(lib) return end

local win = lib:CreateWindow("Vehicle Selector")
local tab = win:CreateTab("Main")

local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Variables to track highlighted objects
local highlightedCar = {model = nil, highlight = nil}
local highlightedTrailer = {model = nil, highlight = nil}

-- Variables to store teleport positions
local targetPos = Vector3.new(0, 0, 0)
local lookAtPos = Vector3.new(0, 0, 0)

-- Helper to parse Vector3 from string
local function parseVector3(str)
    local parts = {}
    for part in string.gmatch(str, "[^,]+") do
        table.insert(parts, tonumber(part))
    end
    if #parts == 3 then
        return Vector3.new(parts[1], parts[2], parts[3])
    end
    return nil -- Invalid format
end

-- Function to get the player's car
local function getCar()
    for _, car in pairs(workspace.Cars:GetChildren()) do
        if car:FindFirstChild("Owner") and car.Owner.Value == player then
            -- car:FindFirstChild("Trailer"):Destroy();
            return car
        end
    end
end

-- Function to get the player's trailer (assuming structure)
local function getTrailer()
    for _, car in pairs(workspace.Cars:GetChildren()) do
        if car:FindFirstChild("Owner") and car.Owner.Value == player then
            trailer = car:FindFirstChild("Trailer");
            return trailer
        end
    end
end

-- Modified fly function (snaps up, then stops velocity)
local function flyCarTo(car, startPos, endPos, speed)
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
    if distance == 0 then return end -- Avoid division by zero
    local travelTime = distance / speed
    local elapsed = 0

    while elapsed < travelTime do
        if not (car and car.Parent) then break end -- Stop if car is destroyed
        BV.velocity = direction * speed
        BG.cframe = CFrame.new(root.Position, endPos)
        elapsed = elapsed + task.wait()
    end

    if BG.Parent then BG:Destroy() end
    if BV.Parent then BV:Destroy() end
    
    if car and car.PrimaryPart then
        -- Snap upwards by 100 studs, preserving orientation
        local currentCFrame = root.CFrame
        local snapUpPos = currentCFrame.Position + Vector3.new(0, 100, 0)
        car:SetPrimaryPartCFrame(CFrame.new(snapUpPos) * (currentCFrame - currentCFrame.Position))

        -- Stop all vehicle velocity
        task.wait(0.1) -- Short delay to let physics settle
        for _, part in ipairs(car:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Velocity = Vector3.new(0, 0, 0)
                part.RotVelocity = Vector3.new(0, 0, 0)
            end
        end
    end
end

-- Function to clear car highlight
local function clearCarHighlight()
    if highlightedCar.highlight and highlightedCar.highlight.Parent then
        highlightedCar.highlight:Destroy()
    end
    highlightedCar.model = nil
    highlightedCar.highlight = nil
end

-- Function to clear trailer highlight
local function clearTrailerHighlight()
    if highlightedTrailer.highlight and highlightedTrailer.highlight.Parent then
        highlightedTrailer.highlight:Destroy()
    end
    highlightedTrailer.model = nil
    highlightedTrailer.highlight = nil
end

-- Create the dropdown
tab:CreateDropdown("Select Vehicle", {"Get Car", "Get Trailer"}, function(value)
    if value == "Get Car" then
        clearTrailerHighlight()
        clearCarHighlight() -- Clear previous car highlight just in case

        local carModel = getCar()
        if carModel then
            local carHighlight = Instance.new("Highlight")
            carHighlight.FillColor = Color3.fromRGB(0, 255, 0) -- Green
            carHighlight.OutlineColor = Color3.fromRGB(0, 100, 0)
            carHighlight.FillTransparency = 0.5
            carHighlight.Parent = carModel

            highlightedCar.model = carModel
            highlightedCar.highlight = carHighlight
        else
            warn("Player car not found.")
        end

    elseif value == "Get Trailer" then
        clearCarHighlight()
        clearTrailerHighlight() -- Clear previous trailer highlight

        local trailerModel = getTrailer()
        if trailerModel then
            local trailerHighlight = Instance.new("Highlight")
            trailerHighlight.FillColor = Color3.fromRGB(0, 0, 255) -- Blue
            trailerHighlight.OutlineColor = Color3.fromRGB(0, 0, 100)
            trailerHighlight.FillTransparency = 0.5
            trailerHighlight.Parent = trailerModel

            highlightedTrailer.model = trailerModel
            highlightedTrailer.highlight = trailerHighlight
        else
            warn("Player trailer not found.")
        end
    end
end)

-- Position Textbox
tab:CreateTextbox("Position (X,Y,Z)", function(text)
    local newPos = parseVector3(text)
    if newPos then
        targetPos = newPos
    else
        warn("Invalid position format. Use X,Y,Z")
    end
end, "e.g., 0, 100, 0")

-- LookAt Textbox
tab:CreateTextbox("LookAt Position (X,Y,Z)", function(text)
    local newPos = parseVector3(text)
    if newPos then
        lookAtPos = newPos
    else
        warn("Invalid LookAt format. Use X,Y,Z")
    end
end, "e.g., 0, 0, 0")

-- Teleport Button
tab:CreateButton("Teleport Selected Vehicle", function()
    local vehicle = highlightedCar.model or highlightedTrailer.model
    if vehicle and vehicle.PrimaryPart then
        local root = vehicle.PrimaryPart
        local wasAnchored = root.Anchored
        root.Anchored = true
        task.wait() -- Wait a moment for anchor to take effect
        vehicle:SetPrimaryPartCFrame(CFrame.new(targetPos, lookAtPos))
        root.Anchored = wasAnchored
    else
        warn("No vehicle selected from dropdown.")
    end
end)

-- Print Position Button
tab:CreateButton("Print Selected Vehicle Position", function()
    local vehicle = highlightedCar.model or highlightedTrailer.model
    if vehicle and vehicle.PrimaryPart then
        local cf = vehicle.PrimaryPart.CFrame
        print("Vehicle CFrame:", cf)
        print("Position:", cf.Position)
        print("LookVector:", cf.LookVector)
    else
        warn("No vehicle selected from dropdown.")
    end
end)

-- Teleport to Job Destination Button
tab:CreateButton("Teleport to Job Desti", function()
    pcall(function()
        -- 1. Find the destination
        local countdown = workspace:FindFirstChild("DestinationCountdown", true)
        if not (countdown and countdown.Parent and countdown.Parent.Parent) then
            warn("Job destination not found.")
            return
        end
        local destinationPart = countdown.Parent.Parent
        
        -- 2. Find the car
        local car = getCar()
        if not (car and car.PrimaryPart) then
            warn("Player car not found.")
            return
        end

        -- 3. Calculate positions
        local finalTargetPos = Vector3.new(destinationPart:GetPivot().Position.X, destinationPart:GetPivot().Position.Y + 10, destinationPart:GetPivot().Position.Z)
        local startPos = car.PrimaryPart.Position
        local downPos = Vector3.new(startPos.X, startPos.Y - 50, startPos.Z)
        local acrossPos = Vector3.new(finalTargetPos.X, startPos.Y - 50, finalTargetPos.Z)

        local root = car.PrimaryPart
        local wasAnchored = root.Anchored
        
        -- Step 1: Go Down (Instant)
        root.Anchored = true
        car:SetPrimaryPartCFrame(CFrame.new(downPos))
        root.Anchored = wasAnchored
        task.wait(0.1) -- Wait for physics to settle

        -- Step 2: Fly Across (Smooth)
        flyCarTo(car, downPos, acrossPos, 500) -- Blocking call with speed 500

        -- Step 3: Go Up (Instant)
        -- root.Anchored = true
        -- car:SetPrimaryPartCFrame(CFrame.new(finalTargetPos) * (root.CFrame - root.CFrame.Position))
        -- root.Anchored = wasAnchored
        
        print("Completed fly-and-snap teleport to job destination.")
    end)
end)

-- Unload Button
tab:CreateButton("Unload Script", function()
    win:Destroy()
end)

win:OnDestroy(function()
    clearCarHighlight()
    clearTrailerHighlight()
end)