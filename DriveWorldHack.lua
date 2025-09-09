--[[no longer obfuscated fully open source]] --
local ok, lib = pcall(loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/vthiep2412/hiep-script/refs/heads/main/OsmiumLibraryFix.lua")));
local win = lib:CreateWindow("Drive World Hack - Keybind: RightAlt");
local tabFarm = win:CreateTab("Farm");
local tabRace = win:CreateTab("Race");
local tabMisc = win:CreateTab("Misc");
local tabCredits = win:CreateTab("Credits");
local flyingFarm = false;
local unused1 = false;
local speedDash = false;
local dashKey = Enum.KeyCode.F;
local unused2 = false;
local defaultGravity = game:GetService("Workspace").Gravity;
local farmSpeed = 1;
local dashPower = 0.005;
tabRace:CreateToggle("Speed Dash [keybind: F]", false, function(val)
    speedDash = val;
end);
local inputService = game:GetService("UserInputService");
inputService.InputBegan:Connect(function(input, isProcessed)
    if isProcessed then return end
    if (speedDash and (input.KeyCode == dashKey)) then
        pcall(function()
            local player = game:GetService("Players").LocalPlayer;
            local char = player.Character or player.CharacterAdded:Wait();
            if (char and char:FindFirstChild("Head")) then
                local head = char.Head;
                local velocity = head.CFrame.LookVector * defaultGravity * dashPower;
                for _, part in pairs(game:GetService("Workspace"):GetDescendants()) do
                    if (part:IsA("BasePart") and not part.Anchored) then
                        part.Velocity = part.Velocity + velocity;
                    end
                end
            end
        end);
    end
end);
tabRace:CreateTextbox("Dash Power [default: 5]", function(val)
    if (val == "") then return end
    if (tonumber(val) == nil) then return end
    if (tonumber(val) <= 0) then
        dashPower = 0.001;
        return;
    end
    dashPower = tonumber(val) * 0.001;
end, "Change Dash Power");
tabFarm:CreateToggle("Flying Farm", false, function(val)
    flyingFarm = val;
    if val then
        task.spawn(function()
            while flyingFarm do
                pcall(function()
                    game:GetService("Workspace").Gravity = 500;
                    for _, car in pairs(game:GetService("Workspace").Cars:GetChildren()) do
                        if (tostring(car.Owner.Value) == game:GetService("Players").LocalPlayer.Name) then
                            car.Main.CFrame = CFrame.new(0, 700, 0);
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
    game:service("Players").LocalPlayer.Idled:connect(function()
        virtUser:CaptureController()
        virtUser:ClickButton2(Vector2.new())
        lblStatus.Text = "Roblox Tried to kick you but we didn't let them kick you :D"
        wait(2)
        lblStatus.Text = "Status : Active"
    end)
end
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
tabCredits:CreateLabel("Made by Hiep");
tabCredits:CreateLabel("Discord: Hiepvu123");
tabCredits:CreateLabel("GitHub: https://github.com/vthiep2412/hiep-script");
