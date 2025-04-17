local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local plr = Players.LocalPlayer
local chr = plr.Character or plr.CharacterAdded:Wait()
local root = chr:WaitForChild("HumanoidRootPart")
local runtimeItems = Workspace:WaitForChild("RuntimeItems")

local remote = ReplicatedStorage.Packages.RemotePromise.Remotes.C_ActivateObject -- Remote for collecting Bonds

local x = 57
local y = 3
local startZ = 30000
local endZ = -49032.99
local stepZ = -3000 -- Step size for faster tweening
local duration = 0.5 -- Duration for each tween step
local delayBetweenCollections = 0.2 -- Adjusted delay for consistent collection

local trackedBonds = {} -- Table to store unique Bond objects

-- Function to create a tween to move the player
local function tweenToPosition(newZ)
    local goal = {}
    goal.CFrame = CFrame.new(Vector3.new(x, y, newZ))
    local tween = TweenService:Create(root, TweenInfo.new(duration, Enum.EasingStyle.Linear), goal)
    tween:Play()
    tween.Completed:Wait() -- Wait for the tween to complete
end

-- Function to track all visible Bonds during tweening
local function trackBonds()
    for _, bond in pairs(runtimeItems:GetChildren()) do
        if bond.Name:match("Bond") and not table.find(trackedBonds, bond) then
            table.insert(trackedBonds, bond) -- Add Bond to the tracked list
            print("Bond found:", bond.Name)
        end
    end
end

-- Function to collect a Bond
local function collectBond(bond)
    if bond:IsA("Model") and bond.PrimaryPart then
        remote:FireServer(bond) -- Fire remote for Model's PrimaryPart
        print("Collected Bond (Model):", bond.Name)
    elseif bond:IsA("BasePart") then
        remote:FireServer(bond) -- Fire remote for BasePart
        print("Collected Bond (BasePart):", bond.Name)
    end
    task.wait(delayBetweenCollections) -- Add delay to ensure the remote processes properly
end

-- Start script logic
task.spawn(function()
    -- Tween through the Z range and track Bonds during each step
    for z = startZ, endZ, stepZ do
        tweenToPosition(z) -- Tween player movement
        trackBonds() -- Track Bonds at each position
    end

    -- After tweening, teleport to each tracked Bond and collect them
    for _, bond in ipairs(trackedBonds) do
        local bondPos = nil
        if bond:IsA("Model") and bond.PrimaryPart then
            bondPos = bond.PrimaryPart.Position -- Use Model's PrimaryPart position
        elseif bond:IsA("BasePart") then
            bondPos = bond.Position -- Use BasePart position
        end

        if bondPos then
            root.CFrame = CFrame.new(bondPos) -- Teleport to Bond
            collectBond(bond) -- Collect the Bond
        end
    end

    -- Final log after collection
    print("Finished collecting Bonds. Total Bonds collected:", #trackedBonds)
end)
