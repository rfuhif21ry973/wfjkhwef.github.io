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
local stepZ = -3000 -- Step size for faster tweening
local duration = 0.5 -- Duration for each tween step
local teleportDelay = 0.7 -- Delay between teleporting to Bond locations

local trackedBonds = {} -- Table to store all Bond objects

-- Function to create a tween to move the player
local function tweenToPosition(newZ)
    local goal = {}
    goal.CFrame = CFrame.new(Vector3.new(x, y, newZ))
    local tween = TweenService:Create(root, TweenInfo.new(duration, Enum.EasingStyle.Linear), goal)
    tween:Play()
    tween.Completed:Wait() -- Wait for the tween to complete
end

-- Function to dynamically track and log Bond locations
local function trackBonds()
    for _, bond in pairs(runtimeItems:GetChildren()) do
        if bond.Name:match("Bond") and not table.find(trackedBonds, bond) then
            table.insert(trackedBonds, bond) -- Track new Bond
            print("Tracking Bond:", bond.Name, "| Location:", bond:GetModelCFrame().Position)
        end
    end
end

-- Function to teleport to tracked Bonds
local function teleportToTrackedBonds()
    for _, bond in ipairs(trackedBonds) do
        if runtimeItems:FindFirstChild(bond.Name) then
            local bondPos = nil
            if bond:IsA("Model") and bond.PrimaryPart then
                bondPos = bond.PrimaryPart.Position -- Use PrimaryPart for Model
            elseif bond:IsA("BasePart") then
                bondPos = bond.Position -- Use Position for BasePart
            end

            if bondPos then
                root.CFrame = CFrame.new(bondPos) -- Teleport to Bond location
                print("Teleported to Bond:", bond.Name, "| Location:", bondPos)
            end
            task.wait(teleportDelay) -- Delay before teleporting to the next Bond
        else
            print("Bond no longer exists in Workspace:", bond.Name)
        end
    end
end

-- Start script logic
task.spawn(function()
    -- Tween through the Z range and log Bonds dynamically
    for z = startZ, endZ, stepZ do
        tweenToPosition(z) -- Tween player movement
        trackBonds() -- Dynamically track Bonds
    end

    -- After tweening, teleport to all tracked Bonds
    print("Finished tweening. Starting teleportation to tracked Bonds.")
    teleportToTrackedBonds()

    -- Final log after teleportation
    print("Teleportation complete. Total Bonds tracked:", #trackedBonds)
end)
