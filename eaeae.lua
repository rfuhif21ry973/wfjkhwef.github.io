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
local delayBetweenCollections = 0.1 -- Faster remote processing delay
local teleportDelay = 0.7 -- Delay between teleporting to each Bond
local maxRetries = 3 -- Number of retry passes

local trackedBonds = {} -- Table to store all Bond objects
local remainingBonds = {} -- To revisit uncollected Bonds

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
            table.insert(remainingBonds, bond) -- Add to remaining Bonds for collection
            print("Tracking Bond:", bond.Name, "| Location:", bond:GetModelCFrame().Position)
        end
    end
end

-- Function to collect a Bond
local function collectBond(bond)
    if bond:IsA("Model") and bond.PrimaryPart then
        remote:FireServer(bond)
        print("Collected Bond:", bond.Name)
    elseif bond:IsA("BasePart") then
        remote:FireServer(bond)
        print("Collected Bond (BasePart):", bond.Name)
    end
    task.wait(delayBetweenCollections) -- Faster delay for collection
end

-- Function to collect all remaining Bonds
local function processRemainingBonds(pass)
    print("Starting collection pass:", pass)
    local uncollected = {}

    for _, bond in ipairs(remainingBonds) do
        if bond:IsA("Model") and bond.PrimaryPart then
            root.CFrame = CFrame.new(bond.PrimaryPart.Position) -- Teleport to Bond
            collectBond(bond) -- Collect Bond
        elseif bond:IsA("BasePart") then
            root.CFrame = CFrame.new(bond.Position) -- Teleport to Bond
            collectBond(bond) -- Collect Bond
        else
            table.insert(uncollected, bond) -- Add to uncollected list if collection fails
        end
        task.wait(teleportDelay) -- Delay before teleporting to the next Bond
    end

    remainingBonds = uncollected -- Update the remaining Bonds for the next pass
    print("Pass complete. Bonds still uncollected:", #remainingBonds)
end

-- Start script logic
task.spawn(function()
    -- Tween through the Z range and log Bonds dynamically
    for z = startZ, endZ, stepZ do
        tweenToPosition(z) -- Tween player movement
        trackBonds() -- Dynamically track Bonds
    end

    -- After tweening, teleport to all tracked Bonds and retry if necessary
    print("Finished tweening. Total Bonds tracked:", #trackedBonds)
    for pass = 1, maxRetries do
        if #remainingBonds > 0 then
            processRemainingBonds(pass) -- Retry collection for uncollected Bonds
        else
            print("All Bonds collected!")
            break
        end
    end

    -- Final log after all retries
    print("Collection complete. Total Bonds collected:", #trackedBonds - #remainingBonds)
end)
