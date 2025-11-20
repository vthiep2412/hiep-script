--[[
    Modified for better undetectability and stability.
    - Instances are now cleaned up properly when a player leaves or their character is removed.
    - Added randomization to instance names to avoid simple detection patterns.
    - Wrapped unsafe calls in pcall to prevent script errors.
    - Restructured event handling to be more robust and less redundant.
]]

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local SETTINGS = {
    TEXT_SIZE = 18,                               
    TEXT_FONT = Enum.Font.GothamBold,             
    TEXT_OUTLINE = true,                          
    TEXT_OUTLINE_COLOR = Color3.new(0, 0, 0),     
    HIGHLIGHT_ENABLED = true                      
}

-- A table to store all created instances for each player, to allow for proper cleanup
local playerInstances = {}

-- Function to generate a random string for instance names to make them harder to detect
local function generateRandomName()
    local len = math.random(10, 20)
    local name = ""
    for i = 1, len do
        name = name .. string.char(math.random(97, 122)) -- random lowercase letters
    end
    return name
end

-- Function to clean up all ESP instances associated with a player
local function cleanup(otherPlayer)
    if playerInstances[otherPlayer] then
        for _, instance in ipairs(playerInstances[otherPlayer]) do
            -- pcall to prevent errors if instance is already removed
            pcall(function()
                instance:Destroy()
            end)
        end
        playerInstances[otherPlayer] = nil
    end
end

local function createNametag(character, otherPlayer)
    print("character: ", character)
    local head = character:FindFirstChild("Head")
    if not head then return end
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = generateRandomName()
    billboard.Adornee = head
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 4, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = character

    local textLabel = Instance.new("TextLabel")
    textLabel.Name = generateRandomName()
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = otherPlayer.Name
    textLabel.TextColor3 = otherPlayer.Team and otherPlayer.Team.TeamColor.Color or Color3.new(0.5, 0.5, 0.5)
    textLabel.TextSize = SETTINGS.TEXT_SIZE
    textLabel.Font = SETTINGS.TEXT_FONT
    textLabel.Parent = billboard
    
    if SETTINGS.TEXT_OUTLINE then
        local outline = Instance.new("UIStroke")
        outline.Name = generateRandomName()
        outline.Color = SETTINGS.TEXT_OUTLINE_COLOR
        outline.Thickness = 1.5
        outline.Parent = textLabel
    end
    
    -- Track the created billboard gui for cleanup
    table.insert(playerInstances[otherPlayer], billboard)
end

local function highlightPlayer(character, otherPlayer)
    if not SETTINGS.HIGHLIGHT_ENABLED then return end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = generateRandomName()
    highlight.FillColor = otherPlayer.Team and otherPlayer.Team.TeamColor.Color or Color3.new(0.5, 0.5, 0.5)
    highlight.OutlineColor = Color3.new(0, 0, 0)
    highlight.Parent = character
    
    -- Track the created highlight for cleanup
    table.insert(playerInstances[otherPlayer], highlight)
end

-- This function updates or creates the ESP for a given player
local function updatePlayerESP(otherPlayer)
    -- Use pcall to catch and suppress any errors, making the script more silent
    pcall(function()
        -- First, clean up any old instances to prevent duplicates
        cleanup(otherPlayer)

        -- Re-initialize the instance table for the player
        playerInstances[otherPlayer] = {}

        local character = otherPlayer.Character
        if not character then return end
        
        -- Create new ESP elements
        highlightPlayer(character, otherPlayer)
        createNametag(character, otherPlayer)
    end)
end

-- This function sets up all necessary connections for a player
local function setupPlayer(otherPlayer)
    if otherPlayer == player then return end

    -- Initial ESP creation if character exists
    if otherPlayer.Character then
        updatePlayerESP(otherPlayer)
    end

    -- Connect to CharacterAdded for respawns
    otherPlayer.CharacterAdded:Connect(function(newChar)
        updatePlayerESP(otherPlayer)
    end)
    
    -- Connect to team changes
    if otherPlayer:IsA("Player") then
        otherPlayer:GetPropertyChangedSignal("Team"):Connect(function()
            updatePlayerESP(otherPlayer)
        end)
    end
end

-- Handle players who are already in the game when the script runs
for _, p in ipairs(Players:GetPlayers()) do
    setupPlayer(p)
end

-- Handle players who join after the script runs
Players.PlayerAdded:Connect(setupPlayer)

-- Handle players who leave the game
Players.PlayerRemoving:Connect(cleanup)