local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer

-- 1. CONFIGURATION
local stagesFolder = Workspace:WaitForChild("Stages")
local isDestroying = true -- Default state (Starts ON)

-- 2. CREATE THE UI (Created locally on your screen)
local gui = Instance.new("ScreenGui")
gui.Name = "LocalDestroyerUI"
gui.Parent = player:WaitForChild("PlayerGui")

local btn = Instance.new("TextButton")
btn.Size = UDim2.new(0, 200, 0, 50)
btn.Position = UDim2.new(0.5, -100, 0.9, -60) -- Bottom Center
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
	isDestroying = not isDestroying -- Toggle True/False
	
	if isDestroying then
		btn.Text = "Destroyer: ON"
		btn.BackgroundColor3 = Color3.fromRGB(0, 255, 0) -- Green
	else
		btn.Text = "Destroyer: OFF"
		btn.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Red
	end
end)

-- 4. THE DESTRUCTION LOOP (Runs only on your computer)
task.spawn(function()
	while true do
		if isDestroying then
			-- Look inside Stages folder
			for _, object in pairs(stagesFolder:GetDescendants()) do
				-- Check for Uppercase AND Lowercase
				if object.Name == "OBSTACLES" or object.Name == "obstacles" then
					object:Destroy()
					-- No print here to prevent spamming your console
				end
			end
		end
		task.wait(3) -- Check every 3 second
	end
end)
