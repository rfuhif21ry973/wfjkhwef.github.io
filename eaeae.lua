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
local collectDelay = 0.1 -- Delay for firing the collection remote repeatedly

local trackedBonds = {} -- Table to store unique Bond objects

-- Function to create a tween to move the player
local function tweenToPosition(newZ)
    local goal = {}
    goal.CFrame = CFrame.new(Vector3.new(x, y, newZ))
    local tween = TweenService:Create(root, TweenInfo.new(duration, Enum.EasingStyle.Linear), goal)
    tween:Play()
    tween.Completed:Wait() -- Wait for the tween to complete
end

-- Function to continuously fire the collection remote
local function collectVisibleBonds()
    for _, bond in pairs(runtimeItems:GetChildren()) do
        if bond:IsA("Model") and bond.Name:match("Bond") and bond.PrimaryPart and not table.find(trackedBonds, bond) then
            remote:FireServer(bond) -- Fire the remote to collect the Bond
            print("Collected Bond:", bond.Name) -- Log the collection
            table.insert(trackedBonds, bond) -- Add Bond to the tracked list
        end
    end
end

-- Function to highlight Bonds within range
local function highlightNearbyBonds()
    for _, bond in pairs(runtimeItems:GetChildren()) do
        if bond:IsA("Model") and bond.Name:match("Bond") then
            if not bond:FindFirstChild("Highlight") then
                local highlight = Instance.new("Highlight")
                highlight.Name = "Highlight"
                highlight.FillColor = Color3.fromRGB(255, 215, 0)
                highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                highlight.FillTransparency = 0.3
                highlight.OutlineTransparency = 0
                highlight.Adornee = bond
                highlight.Parent = bond
            end
        end
    end
end

-- Start script logic
task.spawn(function()
    -- Tween through the specified Z range and continuously collect Bonds
    for z = startZ, endZ, stepZ do
        tweenToPosition(z) -- Tween player movement
        highlightNearbyBonds() -- Highlight Bonds for visibility

        -- Fire collection remote continuously during each tween step
        for _ = 1, math.floor(duration / collectDelay) do
            collectVisibleBonds() -- Collect visible Bonds
            task.wait(collectDelay) -- Wait briefly before the next collection attempt
        end
    end

    -- Final update after completion
    print("Finished tweening and collecting Bonds. Total Bonds collected:", #trackedBonds)
end)
