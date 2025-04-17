local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local runtimeItems = Workspace:WaitForChild("RuntimeItems")
local remote = ReplicatedStorage.Packages.RemotePromise.Remotes.C_ActivateObject -- Remote for collecting Bonds

local x = 57
local y = 3
local startZ = 30000
local endZ = -49032.99
local stepZ = -3000 -- Movement step for faster tweening
local duration = 0.5 -- Duration for each tween step
local collectDistance = 20 -- Distance within which Bonds are collected
local detectionRadius = 150 -- Radius for highlighting Bonds
local trackedBonds = {} -- Track collected Bonds to prevent duplicates

-- Function to tween the player along the Z-axis
local function tweenToPosition(newZ)
    local goal = {}
    goal.CFrame = CFrame.new(Vector3.new(x, y, newZ))
    local tween = TweenService:Create(humanoidRootPart, TweenInfo.new(duration, Enum.EasingStyle.Linear), goal)
    tween:Play()
    tween.Completed:Wait() -- Wait for the tween to finish
end

-- Function to highlight Bonds within range
local function highlightNearbyBonds()
    for _, bond in pairs(runtimeItems:GetChildren()) do
        if bond:IsA("Model") and bond.Name:match("Bond") then
            local distance = (humanoidRootPart.Position - bond:GetModelCFrame().Position).Magnitude
            if distance <= detectionRadius and not table.find(trackedBonds, bond) then
                if not bond:FindFirstChild("BondLabel") then
                    local billboard = Instance.new("BillboardGui")
                    billboard.Name = "BondLabel"
                    billboard.Size = UDim2.new(0, 100, 0, 50)
                    billboard.StudsOffset = Vector3.new(0, 3, 0)
                    billboard.AlwaysOnTop = true
                    billboard.Adornee = bond.PrimaryPart
                    billboard.Parent = bond

                    local label = Instance.new("TextLabel")
                    label.Size = UDim2.new(1, 0, 1, 0)
                    label.BackgroundTransparency = 1
                    label.Text = "BOND"
                    label.TextColor3 = Color3.fromRGB(255, 255, 0)
                    label.TextStrokeTransparency = 0
                    label.TextScaled = true
                    label.Font = Enum.Font.GothamBold
                    label.Parent = billboard
                end
            end
        end
    end
end

-- Function to collect the nearest Bond within range
local function collectNearestBond()
    local closestBond = nil
    local closestDistance = math.huge

    for _, bond in pairs(runtimeItems:GetChildren()) do
        if bond:IsA("Model") and bond.Name:match("Bond") then
            local distance = (humanoidRootPart.Position - bond:GetModelCFrame().Position).Magnitude
            if distance < closestDistance and distance <= collectDistance and not table.find(trackedBonds, bond) then
                closestBond = bond
                closestDistance = distance
            end
        end
    end

    if closestBond then
        remote:FireServer(closestBond) -- Fire the remote to collect the Bond
        table.insert(trackedBonds, closestBond) -- Track collected Bond
        print("Collected Bond:", closestBond.Name) -- Log collection
    end
end

-- Main logic: Tween and collect Bonds
task.spawn(function()
    -- Tween through the specified Z range and collect Bonds
    for z = startZ, endZ, stepZ do
        tweenToPosition(z)
        highlightNearbyBonds() -- Highlight nearby Bonds
        collectNearestBond() -- Collect the closest Bond
    end

    -- Final message after completion
    print("Finished tweening and collecting Bonds. Total Bonds collected:", #trackedBonds)
end)
