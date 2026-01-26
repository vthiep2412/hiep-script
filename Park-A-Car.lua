local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer

-- 1. CONFIGURATION
local stagesFolder = Workspace:WaitForChild("Stages")
local isDestroying = false -- CHANGED: Default is now OFF (Sleeping)

-- 2. CREATE UI
local gui = Instance.new("ScreenGui")
gui.Name = "LocalDestroyerUI"
gui.Parent = player:WaitForChild("PlayerGui")

local btn = Instance.new("TextButton")
btn.Size = UDim2.new(0, 200, 0, 50)
btn.Position = UDim2.new(0.5, -100, 0.9, -60)
btn.Text = "Destroyer: OFF" -- CHANGED: Starts with text OFF
btn.TextSize = 20
btn.Font = Enum.Font.GothamBold
btn.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- CHANGED: Starts Red (OFF)
btn.Parent = gui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 8)
uiCorner.Parent = btn

-- 3. BUTTON LOGIC
btn.MouseButton1Click:Connect(function()
	isDestroying = not isDestroying
	if isDestroying then
		btn.Text = "Destroyer: ON"
		btn.BackgroundColor3 = Color3.fromRGB(0, 255, 0) -- Green
	else
		btn.Text = "Destroyer: OFF"
		btn.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Red
	end
end)

-- 4. THE LOOP
task.spawn(function()
	while true do
		if isDestroying then
			-- CHECK 1: Inside Stages
			for _, object in pairs(stagesFolder:GetDescendants()) do
				if object.Parent then 
					if object.Name == "OBSTACLES" or object.Name == "obstacles" or object.Name == "Obstacle" then
						object:Destroy()
					end
				end
			end

			-- CHECK 2: Workspace Folders
			local looseFolder = Workspace:FindFirstChild("Obstacle")
			if looseFolder then looseFolder:Destroy() end
			
			local looseFolderPlural = Workspace:FindFirstChild("Obstacles")
			if looseFolderPlural then looseFolderPlural:Destroy() end
		end
		
		task.wait(3) -- Runs every 3 seconds
	end
end)
