local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local plr = Players.LocalPlayer
local chr = plr.Character or plr.CharacterAdded:Wait()
local root = chr:WaitForChild("HumanoidRootPart")
local runtimeItems = Workspace:WaitForChild("RuntimeItems")

local x = 57
local y = 3
local startZ = 30000
local endZ = -49032.99
local stepZ = -2000
local duration = 0.5 -- Duration for each tween step

local trackedBonds = {} -- Table to store bond locations

-- Function to create a tween
local function tweenToPosition(newZ)
    local goal = {}
    goal.CFrame = CFrame.new(Vector3.new(x, y, newZ))
    local tween = TweenService:Create(root, TweenInfo.new(duration, Enum.EasingStyle.Linear), goal)
    tween:Play()
    tween.Completed:Wait() -- Wait for the tween to complete
end

-- Function to track bonds and store their locations
local function trackBonds()
    for _, bond in pairs(runtimeItems:GetChildren()) do
        if bond:IsA("Model") and bond.PrimaryPart then
            local bondPos = bond.PrimaryPart.Position
            table.insert(trackedBonds, bondPos) -- Save bond's position
        elseif bond:IsA("BasePart") then
            table.insert(trackedBonds, bond.Position)
        end
    end
end

-- Start script logic
task.spawn(function()
    -- First teleport to the starting position
    root.CFrame = CFrame.new(Vector3.new(x, 10, startZ))
    task.wait(1) -- Wait for 1 second after the first teleport

    -- Tween from startZ to endZ in steps
    for z = startZ, endZ, stepZ do
        tweenToPosition(z)
        trackBonds() -- Track bonds during each step
    end

    -- At the end of the tween, teleport to all tracked bonds extremely fast
    for _, bondPos in ipairs(trackedBonds) do
        root.CFrame = CFrame.new(bondPos)
        task.wait(0.1) -- Very fast teleport delay (adjustable)
    end
end)
