local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer

-- 1. CONFIGURATION
local stagesFolder = Workspace:WaitForChild("Stages")
local isDestroying = true -- Default state (Starts ON)

-- 2. CREATE THE UI
local gui = Instance.new("ScreenGui")
gui.Name = "LocalDestroyerUI"
gui.Parent = player:WaitForChild("PlayerGui")

local btn = Instance.new("TextButton")
btn.Size = UDim2.new(0, 200, 0, 50)
btn.Position = UDim2.new(0.5, -100, 0.9, -60)
btn.Text = "Destroyer: ON"
btn.TextSize = 20
btn.Font = Enum.Font.GothamBold
btn.BackgroundColor3 = Color3.fromRGB(0, 255, 0) -- Green
btn.Parent = gui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 8)
uiCorner.Parent = btn

-- 3. BUTTON CLICK LOGIC
btn.MouseButton1Click:Connect(function()
	isDestroying = not isDestroying
	
	if isDestroying then
		btn.Text = "Destroyer: ON"
		btn.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
	else
		btn.Text = "Destroyer: OFF"
		btn.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	end
end)

-- 4. THE DESTRUCTION LOOP
task.spawn(function()
	while true do
		if isDestroying then
			-- TASK A: Clean inside "Stages" (OBSTACLES / obstacles)
			for _, object in pairs(stagesFolder:GetDescendants()) do
				if object.Name == "OBSTACLES" or object.Name == "obstacles" then
					object:Destroy()
				end
			end

			-- TASK B: Check for "Obstacle" folder directly in Workspace
			-- We use FindFirstChild so we don't error if it's already gone
			local badFolder = Workspace:FindFirstChild("Obstacle")
			if badFolder then
				badFolder:Destroy()
				print("🗑️ Deleted 'Obstacle' folder from Workspace")
			end
		end
		
		-- CHANGED: Wait 3 seconds instead of 1
		task.wait(3)
	end
end)
