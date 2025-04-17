local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local runtimeItems = Workspace:WaitForChild("RuntimeItems")
local remote = ReplicatedStorage.Packages.RemotePromise.Remotes.C_ActivateObject

local collectDistance = 20 -- Distance within which Bonds will be collected
local walkDelay = 0.1 -- Delay for checking nearby Bonds
local teleportDelay = 0.7 -- Delay between teleporting to Bond locations

local trackedBonds = {} -- Table to store all Bond objects

local x = 57
local y = 3
local startZ = 30000
local endZ = -49032.99
local stepZ = -3000 -- Step size for tweening
local duration = 0.5 -- Duration for each tween step

-- Creates a floating label above the Bond
local function createBillboard(bond)
    if not bond:FindFirstChild("BondLabel") then
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "BondLabel"
        billboard.Size = UDim2.new(0, 100, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.AlwaysOnTop = true
        billboard.Adornee = bond:FindFirstChildWhichIsA("BasePart")
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

-- Highlight Bonds within range
local function highlightNearbyBonds()
    for _, bond in pairs(runtimeItems:GetChildren()) do
        if bond:IsA("Model") and bond.Name:match("Bond") then
            local distance = (humanoidRootPart.Position - bond:GetModelCFrame().Position).Magnitude
            if distance <= 150 then -- Larger detection radius for visibility
                createBillboard(bond)
            else
                local label = bond:FindFirstChild("BondLabel")
                if label then label:Destroy() end
            end
        end
    end
end

-- Function to dynamically track Bond locations during tweening
local function trackBonds()
    for _, bond in pairs(runtimeItems:GetChildren()) do
        if bond:IsA("Model") and bond.Name:match("Bond") and bond.PrimaryPart and not table.find(trackedBonds, bond.PrimaryPart.Position) then
            table.insert(trackedBonds, bond.PrimaryPart.Position)
            print("Bond tracked:", bond.Name, "| Location:", bond.PrimaryPart.Position)
        elseif bond:IsA("BasePart") and bond.Name:match("Bond") and not table.find(trackedBonds, bond.Position) then
            table.insert(trackedBonds, bond.Position)
            print("Bond tracked (BasePart):", bond.Name, "| Location:", bond.Position)
        end
    end
end

-- Function to create a tween to move the player
local function tweenToPosition(newZ)
    local goal = {}
    goal.CFrame = CFrame.new(Vector3.new(x, y, newZ))
    local tween = TweenService:Create(humanoidRootPart, TweenInfo.new(duration, Enum.EasingStyle.Linear), goal)
    tween:Play()
    tween.Completed:Wait() -- Wait for the tween to complete
end

-- Function to teleport to all tracked Bonds and collect them
local function teleportAndCollect()
    for _, bondPosition in ipairs(trackedBonds) do
        humanoidRootPart.CFrame = CFrame.new(bondPosition) -- Teleport to Bond
        print("Teleported to Bond at:", bondPosition)

        -- Check nearby Bonds and collect them
        for _, bond in pairs(runtimeItems:GetChildren()) do
            if bond.PrimaryPart and (bond.PrimaryPart.Position - bondPosition).Magnitude <= collectDistance then
                remote:FireServer(bond)
                print("Collected Bond:", bond.Name)
            elseif bond:IsA("BasePart") and (bond.Position - bondPosition).Magnitude <= collectDistance then
                remote:FireServer(bond)
                print("Collected Bond (BasePart):", bond.Name)
            end
        end
        task.wait(teleportDelay) -- Delay before teleporting to the next Bond
    end
end

-- Main script logic
task.spawn(function()
    -- Tween through the Z-axis and track Bond locations
    for z = startZ, endZ, stepZ do
        tweenToPosition(z) -- Tween player movement
        trackBonds() -- Track Bonds at each step
    end

    -- After tweening, teleport and collect all Bonds
    print("Finished tweening. Starting teleportation and collection.")
    teleportAndCollect()
    print("Collection complete. Total Bonds collected:", #trackedBonds)
end)

-- Continuous highlighting of nearby Bonds
RunService.Heartbeat:Connect(function()
    highlightNearbyBonds()
    task.wait(walkDelay) -- Delay for updating highlights
end)
