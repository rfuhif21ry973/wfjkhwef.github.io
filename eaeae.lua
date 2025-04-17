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
local stepZ = -3000 -- Increased step size for faster tweening
local duration = 0.5 -- Duration for each tween step
local detectionRadius = 150 -- Radius for highlighting and labeling Bonds
local collectDistance = 20 -- Distance to collect nearby Bonds
local walkDelay = 0.1 -- Delay between collection checks

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

-- Adds a highlight to the Bond
local function highlightBond(bond)
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

-- Highlights & labels Bonds within range
local function highlightNearbyBonds()
    for _, bond in pairs(runtimeItems:GetChildren()) do
        if bond:IsA("Model") and bond.Name:match("Bond") then
            local distance = (humanoidRootPart.Position - bond:GetModelCFrame().Position).Magnitude
            if distance <= detectionRadius then
                createBillboard(bond)
                highlightBond(bond)
            else
                local label = bond:FindFirstChild("BondLabel")
                if label then label:Destroy() end

                local highlight = bond:FindFirstChild("Highlight")
                if highlight then highlight:Destroy() end
            end
        end
    end
end

-- Gets the nearest Bond within collect distance
local function GetNearestBond()
    local closestBond = nil
    local closestDistance = math.huge
    for _, bond in pairs(runtimeItems:GetChildren()) do
        if bond:IsA("Model") and bond.Name:match("Bond") then
            local distance = (humanoidRootPart.Position - bond:GetModelCFrame().Position).Magnitude
            if distance < closestDistance then
                closestBond = bond
                closestDistance = distance
            end
        end
    end
    return closestBond, closestDistance
end

-- Function to tween the player along the Z-axis
local function tweenToPosition(newZ)
    local goal = {}
    goal.CFrame = CFrame.new(Vector3.new(x, y, newZ))
    local tween = TweenService:Create(humanoidRootPart, TweenInfo.new(duration, Enum.EasingStyle.Linear), goal)
    tween:Play()
    tween.Completed:Wait() -- Wait for the tween to finish
end

-- Start script logic
task.spawn(function()
    -- Tween through the specified Z range, checking for Bonds
    for z = startZ, endZ, stepZ do
        tweenToPosition(z)
        highlightNearbyBonds() -- Update highlights and labels
        local bond, distance = GetNearestBond() -- Find the nearest Bond
        if bond and distance <= collectDistance then
            remote:FireServer(bond) -- Collect the Bond
            print("Collected Bond:", bond.Name)
        end
        task.wait(walkDelay) -- Delay between checks
    end

    -- Final cleanup: Highlight and collect remaining Bonds
    highlightNearbyBonds()
    print("Finished tweening and bond collection.")
end)
