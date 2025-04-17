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
local stepZ = -2000
local duration = 0.5 -- Duration for each tween step
local teleportDelay = 1 -- Delay between teleports (increased for slower collection)

local trackedBonds = {} -- Table to store unique Bond objects

-- Function to create a tween to move the player
local function tweenToPosition(newZ)
    local goal = {}
    goal.CFrame = CFrame.new(Vector3.new(x, y, newZ))
    local tween = TweenService:Create(root, TweenInfo.new(duration, Enum.EasingStyle.Linear), goal)
    tween:Play()
    tween.Completed:Wait() -- Wait for the tween to complete
end

-- Function to track bonds during the tween
local function trackBonds()
    for _, item in pairs(runtimeItems:GetChildren()) do
        -- Only track items explicitly named "Bond"
        if item.Name:match("Bond") and not table.find(trackedBonds, item) then
            if item:IsA("Model") and item.PrimaryPart then
                table.insert(trackedBonds, item) -- Add Model with a defined PrimaryPart
                print("Bond found (Model):", item.Name)
            elseif item:IsA("BasePart") then
                table.insert(trackedBonds, item) -- Add BasePart directly
                print("Bond found (BasePart):", item.Name)
            end
        end
    end
end

-- Function to collect a Bond
local function collectBond(bond)
    if bond:IsA("Model") and bond.PrimaryPart then
        remote:FireServer(bond) -- Collect the Bond using the Model's PrimaryPart
        print("Collected Bond (Model):", bond.Name)
    elseif bond:IsA("BasePart") then
        remote:FireServer(bond) -- Collect the Bond if it’s a BasePart
        print("Collected Bond (BasePart):", bond.Name)
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
        task.wait(teleportDelay) -- Increased delay to ensure collection happens properly
    end

    -- At the end of the tween, teleport to all tracked bonds extremely fast and collect them
    for _, bond in ipairs(trackedBonds) do
        local bondPos = nil
        if bond:IsA("Model") and bond.PrimaryPart then
            bondPos = bond.PrimaryPart.Position -- Use PrimaryPart for Models
        elseif bond:IsA("BasePart") then
            bondPos = bond.Position -- Use Position for BaseParts
        end

        if bondPos then
            root.CFrame = CFrame.new(bondPos) -- Teleport to the Bond
            collectBond(bond) -- Collect the Bond
            task.wait(0.5) -- Slight delay between collections for reliability
        end
    end

    -- Final update on total number of Bonds collected
    print("Total Bonds collected:", #trackedBonds)
end)
