local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer

-- 1. CONFIGURATION
local stagesFolder = Workspace:WaitForChild("Stages")
local isDestroying = false -- Default: OFF

-- 2. CREATE UI CONTAINER
local gui = Instance.new("ScreenGui")
gui.Name = "LocalDestroyerUI"
gui.Parent = player:WaitForChild("PlayerGui")

-- 3. THE CLEANING FUNCTION (Shared by both buttons)
local function runCleaner()
	-- CHECK A: Inside "Stages" folder
	for _, object in pairs(stagesFolder:GetDescendants()) do
		if object.Parent then 
			if object.Name == "OBSTACLES" or object.Name == "obstacles" or object.Name == "Obstacle" then
				object:Destroy()
			end
		end
	end

	-- CHECK B: Loose folders in Workspace
	local looseFolder = Workspace:FindFirstChild("Obstacle")
	if looseFolder then looseFolder:Destroy() end
	
	local looseFolderPlural = Workspace:FindFirstChild("Obstacles")
	if looseFolderPlural then looseFolderPlural:Destroy() end
end

-- 4. BUTTON 1: AUTO-TOGGLE (Bottom Button)
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 200, 0, 50)
toggleBtn.Position = UDim2.new(0.5, -100, 0.9, -60) -- Bottom Center
toggleBtn.Text = "Destroyer: OFF"
toggleBtn.TextSize = 20
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Red
toggleBtn.Parent = gui

local uiCorner1 = Instance.new("UICorner")
uiCorner1.CornerRadius = UDim.new(0, 8)
uiCorner1.Parent = toggleBtn

toggleBtn.MouseButton1Click:Connect(function()
	isDestroying = not isDestroying
	if isDestroying then
		toggleBtn.Text = "Destroyer: ON"
		toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 0) -- Green
	else
		toggleBtn.Text = "Destroyer: OFF"
		toggleBtn.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- Red
	end
end)

-- 5. BUTTON 2: RUN ONCE (Top Button)
local onceBtn = Instance.new("TextButton")
onceBtn.Size = UDim2.new(0, 200, 0, 50)
onceBtn.Position = UDim2.new(0.5, -100, 0.9, -120) -- 60 pixels above the other button
onceBtn.Text = "Delete Once"
onceBtn.TextSize = 20
onceBtn.Font = Enum.Font.GothamBold
onceBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255) -- Blue
onceBtn.Parent = gui

local uiCorner2 = Instance.new("UICorner")
uiCorner2.CornerRadius = UDim.new(0, 8)
uiCorner2.Parent = onceBtn

onceBtn.MouseButton1Click:Connect(function()
	-- Visual Feedback (Flash White)
	onceBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	onceBtn.Text = "Cleaning..."
	
	runCleaner() -- Run the logic 1 time
	
	task.wait(0.2)
	onceBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255) -- Back to Blue
	onceBtn.Text = "Delete Once"
end)

-- 6. THE AUTO LOOP
task.spawn(function()
	while true do
		if isDestroying then
			runCleaner() -- Run the logic if toggle is ON
		end
		task.wait(3)
	end
end)
