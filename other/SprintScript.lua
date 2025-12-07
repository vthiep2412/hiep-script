local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local isRunning = false

local function tweenFOV(targetFOV, duration)
	local camera = game.Workspace.CurrentCamera
	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local goal = { FieldOfView = targetFOV }
	local tween = TweenService:Create(camera, tweenInfo, goal)
	tween:Play()
end

local function stopSprint()
	if isRunning then
		isRunning = false
		humanoid.WalkSpeed = 16
		tweenFOV(70, 0.5)
	end
end

local function startSprint()
	if not isRunning then
		isRunning = true
		tweenFOV(75, 0.5)
		humanoid.WalkSpeed = 25
	end
end

UIS.InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.LeftShift and not isRunning then
		startSprint()
	end
end)

UIS.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.LeftShift and isRunning then
		stopSprint()
	end
end)
