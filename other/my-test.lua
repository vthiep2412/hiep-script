local _, library = pcall(loadstring(game:HttpGet("https://raw.githubusercontent.com/vthiep2412/hiep-script/refs/heads/main/OsmiumLibraryFix.lua")))

local window = library:CreateWindow("Drive World Hack - Keybind: RightAlt")
local tabFarm = window:CreateTab("Farm")
local tabRace = window:CreateTab("Race")
local tabMisc = window:CreateTab("Misc")
local tabCredits = window:CreateTab("Credits")

-- Variables
local toggleFarm = false
local toggleNoclip = false
local toggleDash = false -- Toggle for Dash feature
local dashBindKey = Enum.KeyCode.F -- Default bind key for dashing (changeable via UI)
local selectedKey = false -- Track if the user is selecting a key
local defGravity = game:GetService("Workspace").Gravity
local Farmspeed = 1
local DashPower = 0.002
local moneyCollectDelay = 5

-- Dash Feature Toggle
tabRace:CreateToggle("Speed Dash [keybind: F]", false, function(value)
    toggleDash = value
end)

-- Key Bind Selector for Dash, i work on it later, it not work now
-- local keyBindBox = tabFarm:CreateButton("Set Dash Key: [F]", function()
--     selectedKey = true -- Enable key selection mode
--     keyBindBox:SetText("Press a Key...") -- Update UI text
-- end)

-- Listen for Key Input
local UserInputService = game:GetService("UserInputService")
UserInputService.InputBegan:Connect(function(input, isProcessed)
    if isProcessed then return end

    -- Key selection mode, i work on it later, it not work now
    -- if selectedKey then
    --     dashBindKey = input.KeyCode -- Update bind key
    --     keyBindBox:SetText("Set Dash Key: [" .. input.KeyCode.Name .. "]") -- Update button text
    --     selectedKey = false -- Exit key selection mode
    --     return
    -- end

    -- Dash Logic: Execute when the bind key is pressed and dash is enabled
    if toggleDash and input.KeyCode == dashBindKey then
        pcall(function()
            local player = game:GetService("Players").LocalPlayer
            local character = player.Character or player.CharacterAdded:Wait()
            if character and character:FindFirstChild("Head") then
                local head = character.Head
                local dashForce = head.CFrame.LookVector * (defGravity * DashPower) -- Dash force at 0.5% gravity strength

                for _, obj in pairs(game:GetService("Workspace"):GetDescendants()) do
                    if obj:IsA("BasePart") and not obj.Anchored then
                        obj.Velocity = obj.Velocity + dashForce -- Apply single dash force
                    end
                end
            end
        end)
    end
end)

tabRace:CreateTextbox("Dash Power [default: 2]", function(value)
    if value == "" then return end
    if tonumber(value) == nil then return end
    if tonumber(value) <= 0 then
        DashPower = 0.001 -- Set to minimum dash power if invalid input
        return
    end
    DashPower = tonumber(value) * 0.001 -- Convert to percentage
end, "Change Dash Power")

-- Farming Function
local function startFarm()
    if not toggleFarm then return end -- Prevents accidental start if disabled

    task.spawn(function()
        while toggleFarm do
            pcall(function()
                game:GetService("Workspace").Gravity = 500
                for _, v in pairs(game:GetService("Workspace").Cars:GetChildren()) do
                    if tostring(v.Owner.Value) == game:GetService("Players").LocalPlayer.Name then
                        v.Main.CFrame = CFrame.new(0, 700, 0)
                    end
                end
            end)
            task.wait(Farmspeed) -- Farming speed delay
        end
    end)
end

tabFarm:CreateToggle("Flying Farm", false, function(value)
    toggleFarm = value

    if value then
        startFarm() -- Start farm using function
    else
        toggleFarm = false -- Stop the farm properly
        game:GetService("Workspace").Gravity = defGravity
    end
end)

tabFarm:CreateTextbox("Farm speed (In seconds, default: 1-2)", function(value)
    if value == "" then return end
    if tonumber(value) == nil then return end
    if tonumber(value) <= 0 then
        Farmspeed = 0.1 -- Set to minimum delay if invalid input
        return
    end
    Farmspeed = tonumber(value)
end, "Change Farm Speed")

-- Money Collector Variables
local toggleMoneyCollector = false -- Toggle for money collection automation
local collectorWaitTime = 5 -- Default wait time in minutes (converted to seconds)

-- Toggle for Money Collection Automation (Continuous Loop)
tabFarm:CreateToggle("Enable Money Collector", false, function(value)
    toggleMoneyCollector = value
    if toggleMoneyCollector then
        task.spawn(function()
            while toggleMoneyCollector do
                task.wait(collectorWaitTime * 60)
                toggleFarm = false
                task.wait(moneyCollectDelay)
                toggleFarm = true
                startFarm()
            end
        end)
    end
end)

-- Input Box for User-Defined Money Collection Time
tabFarm:CreateTextbox("Money Collector Wait Time (Default: 5 min)", function(value)
    if value == "" or tonumber(value) == nil then return end
    if tonumber(value) <= 0 then
        collectorWaitTime = 1 -- Minimum valid delay (in minutes)
    else
        collectorWaitTime = tonumber(value) -- Store user-defined time in minutes
    end
end, "Enter time in minutes")
-- Vehicle Noclip Switch, not work well
local vnoclipParts = {}
tabMisc:CreateToggle("Vehicle Noclip", false, function(value)
    toggleNoclip = value
    if value then
        task.spawn(function()
            vnoclipParts = {}
            local player = game:GetService("Players").LocalPlayer
            local character = player.Character or player.CharacterAdded:Wait()
            local seat = character:FindFirstChildOfClass("Humanoid").SeatPart

            -- Find the Vehicle Model
            if seat then
                local vehicleModel = seat.Parent
                repeat
                    if vehicleModel.ClassName ~= "Model" then
                        vehicleModel = vehicleModel.Parent
                    end
                until vehicleModel.ClassName == "Model"

                -- Wait briefly and start noclip
                task.wait(0.1)
                for _, v in pairs(vehicleModel:GetDescendants()) do
                    if v:IsA("BasePart") and v.CanCollide then
                        table.insert(vnoclipParts, v)
                        v.CanCollide = false -- Disable collisions
                    end
                end
            end
        end)
    else
        -- Reset collisions when Noclip is disabled
        pcall(function()
            for _, v in pairs(vnoclipParts) do
                if v:IsA("BasePart") then
                    v.CanCollide = true
                end
            end
            vnoclipParts = {}
        end)
    end
end)

-- Anti-AFK Script
tabFarm:CreateButton("Anti AFK", function()
    pcall(function()
        wait(0.5)
        local ba = Instance.new("ScreenGui")
        local ca = Instance.new("TextLabel")
        local da = Instance.new("Frame")
        local _b = Instance.new("TextLabel")
        local ab = Instance.new("TextLabel")

        ba.Parent = game.CoreGui
        ba.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        ca.Parent = ba
        ca.Active = true
        ca.BackgroundColor3 = Color3.new(0.176471, 0.176471, 0.176471)
        ca.Draggable = true
        ca.Position = UDim2.new(0.698610067, 0, 0.098096624, 0)
        ca.Size = UDim2.new(0, 370, 0, 52)
        ca.Font = Enum.Font.SourceSansSemibold
        ca.Text = "Anti AFK Script"
        ca.TextColor3 = Color3.new(0, 1, 1)
        ca.TextSize = 22

        da.Parent = ca
        da.BackgroundColor3 = Color3.new(0.196078, 0.196078, 0.196078)
        da.Position = UDim2.new(0, 0, 1.0192306, 0)
        da.Size = UDim2.new(0, 370, 0, 107)

        _b.Parent = da
        _b.BackgroundColor3 = Color3.new(0.176471, 0.176471, 0.176471)
        _b.Position = UDim2.new(0, 0, 0.800455689, 0)
        _b.Size = UDim2.new(0, 370, 0, 21)
        _b.Font = Enum.Font.Arial
        _b.Text = "Made by Dynamic. (please subscribe)"
        _b.TextColor3 = Color3.new(0, 1, 1)
        _b.TextSize = 20

        ab.Parent = da
        ab.BackgroundColor3 = Color3.new(0.176471, 0.176471, 0.176471)
        ab.Position = UDim2.new(0, 0, 0.158377, 0)
        ab.Size = UDim2.new(0, 370, 0, 44)
        ab.Font = Enum.Font.ArialBold
        ab.Text = "Status: Active"
        ab.TextColor3 = Color3.new(0, 1, 1)
        ab.TextSize = 20

        local bb = game:service("VirtualUser")
        game:service("Players").LocalPlayer.Idled:connect(function()
            bb:CaptureController()
            bb:ClickButton2(Vector2.new())
            ab.Text = "Roblox Tried to kick you but we didn't let them kick you :D"
            wait(2)
            ab.Text = "Status : Active"
        end)
    end)
end)

-- Staff Roles Configuration
local staffRoles = {"mod", "admin", "staff", "dev", "founder", "owner", "supervis", "manager", "management", "executive", "president", "chairman", "chairwoman", "chairperson", "director","moderator","supervisor", "administrator", "developer", "founder", "owner"}
-- Function to Determine Staff Role
local getStaffRole = function(player)
    local playerRole = player:GetRoleInGroup(game.CreatorId)
    local result = {Role = playerRole, Staff = false}
    if player:IsInGroup(1200769) then
        result.Role = "Roblox Employee"
        result.Staff = true
    end
    for _, role in pairs(staffRoles) do
        if string.find(string.lower(playerRole), role) then
            result.Staff = true
        end
    end
    return result
end
-- StaffWatch Variables
local toggleStaffWatch = false -- StaffWatch toggle
local staffwatchjoin = nil -- Connection placeholder for StaffWatch

-- StaffWatch Toggle
tabMisc:CreateToggle("StaffWatch", false, function(value)
    toggleStaffWatch = value
    if toggleStaffWatch then
        if staffwatchjoin then
            staffwatchjoin:Disconnect()
        end

        if game.CreatorType == Enum.CreatorType.Group then
            staffwatchjoin = game:GetService("Players").PlayerAdded:Connect(function(player)
                local result = getStaffRole(player)
                if result and result.Staff then
                    toggleMoneyCollector = false
                    toggleFarm = false
                    task.wait(moneyCollectDelay)
                    game:GetService("Players").LocalPlayer:Kick("A staff member has joined: " .. player.Name)
                end
            end)

            -- Check current players already in-game
            for _, player in pairs(game:GetService("Players"):GetPlayers()) do
                local result = getStaffRole(player)
                if result and result.Staff then
                    toggleMoneyCollector = false
                    toggleFarm = false
                    task.wait(moneyCollectDelay)
                    game:GetService("Players").LocalPlayer:Kick("A staff member is already in the game: " .. player.Name)
                end
            end
        end
    else
        if staffwatchjoin then
            staffwatchjoin:Disconnect()
            staffwatchjoin = nil
        end
    end
end)




tabMisc:CreateButton("Anti AFK", function()
    pcall(function()
        wait(0.5)
        local ba = Instance.new("ScreenGui")
        local ca = Instance.new("TextLabel")
        local da = Instance.new("Frame")
        local _b = Instance.new("TextLabel")
        local ab = Instance.new("TextLabel")

        ba.Parent = game.CoreGui
        ba.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        ca.Parent = ba
        ca.Active = true
        ca.BackgroundColor3 = Color3.new(0.176471, 0.176471, 0.176471)
        ca.Draggable = true
        ca.Position = UDim2.new(0.698610067, 0, 0.098096624, 0)
        ca.Size = UDim2.new(0, 370, 0, 52)
        ca.Font = Enum.Font.SourceSansSemibold
        ca.Text = "Anti AFK Script"
        ca.TextColor3 = Color3.new(0, 1, 1)
        ca.TextSize = 22

        da.Parent = ca
        da.BackgroundColor3 = Color3.new(0.196078, 0.196078, 0.196078)
        da.Position = UDim2.new(0, 0, 1.0192306, 0)
        da.Size = UDim2.new(0, 370, 0, 107)

        _b.Parent = da
        _b.BackgroundColor3 = Color3.new(0.176471, 0.176471, 0.176471)
        _b.Position = UDim2.new(0, 0, 0.800455689, 0)
        _b.Size = UDim2.new(0, 370, 0, 21)
        _b.Font = Enum.Font.Arial
        _b.Text = "Made by Dynamic. (please subscribe)"
        _b.TextColor3 = Color3.new(0, 1, 1)
        _b.TextSize = 20

        ab.Parent = da
        ab.BackgroundColor3 = Color3.new(0.176471, 0.176471, 0.176471)
        ab.Position = UDim2.new(0, 0, 0.158377, 0)
        ab.Size = UDim2.new(0, 370, 0, 44)
        ab.Font = Enum.Font.ArialBold
        ab.Text = "Status: Active"
        ab.TextColor3 = Color3.new(0, 1, 1)
        ab.TextSize = 20

        local bb = game:service("VirtualUser")
        game:service("Players").LocalPlayer.Idled:connect(function()
            bb:CaptureController()
            bb:ClickButton2(Vector2.new())
            ab.Text = "Roblox Tried to kick you but we didn't let them kick you :D"
            wait(2)
            ab.Text = "Status : Active"
        end)
    end)
end)

-- Server Hop Button
tabMisc:CreateButton("Server Hop", function()
    pcall(function()
        local servers = game:GetService("HttpService"):JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"))
        for _, server in pairs(servers.data) do
            if server.playing < server.maxPlayers then
                game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, server.id, game:GetService("Players").LocalPlayer)
                break
            end
        end
    end)
end)

-- Rejoin Button
tabMisc:CreateButton("Rejoin", function()
    pcall(function()
        local TeleportService = game:GetService("TeleportService")
        local Players = game:GetService("Players")
        TeleportService:Teleport(game.PlaceId, Players.LocalPlayer)
    end)
end)

tabMisc:CreateButton("Inf Yield", function()
    pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
    end)
end)

tabCredits:CreateLabel("Made by Hiep")
tabCredits:CreateLabel("Discord: Hiepvu123")
tabCredits:CreateLabel("GitHub: https://github.com/vthiep2412/hiep-script")