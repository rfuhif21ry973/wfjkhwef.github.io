local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local runtimeItems = Workspace:WaitForChild("RuntimeItems")
local remote = ReplicatedStorage.Packages.RemotePromise.Remotes.C_ActivateObject

local collectDistance = 20 -- Distance for collecting nearby Bonds
local trackedBonds = {} -- Table to store Bond locations
local x = 57
local y = 3
local startZ = 30000
local endZ = -49032.99
local stepZ = -3000 -- Step size for tweening
local duration = 0.5 -- Tween duration
local walkDelay = 0.1 -- Delay between checks

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

-- Highlight Bonds within range
local function highlightNearbyBonds()
    for _, bond in pairs(runtimeItems:GetChildren()) do
        if bond:IsA("Model") and bond.Name:match("Bond") then
            local distance = (humanoidRootPart.Position - bond:GetModelCFrame().Position).Magnitude
            if distance <= 150 then -- Larger detection radius
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

-- Tween the player along the Z-axis and store Bond locations
for z = startZ, endZ, stepZ do
    local goal = {}
    goal.CFrame = CFrame.new(Vector3.new(x, y, z))
    local tween = TweenService:Create(humanoidRootPart, TweenInfo.new(duration, Enum.EasingStyle.Linear), goal)
    tween:Play()
    tween.Completed:Wait() -- Wait for tween completion

    -- Track Bonds during tweening
    for _, bond in pairs(runtimeItems:GetChildren()) do
        if bond:IsA("Model") and bond.Name:match("Bond") and bond.PrimaryPart then
            table.insert(trackedBonds, bond.PrimaryPart.Position) -- Store Bond location
        elseif bond:IsA("BasePart") and bond.Name:match("Bond") then
            table.insert(trackedBonds, bond.Position) -- Store Bond location
        end
    end
end

-- Automatically teleport to stored Bonds and collect them
for _, bondPosition in ipairs(trackedBonds) do
    humanoidRootPart.CFrame = CFrame.new(bondPosition) -- Teleport to Bond location
    highlightNearbyBonds() -- Highlight nearby Bonds

    -- Check nearby Bonds and collect them
    for _, bond in pairs(runtimeItems:GetChildren()) do
        if bond.Name:match("Bond") then -- Ensure the name matches "Bond"
            local distance = bond.PrimaryPart and (bond.PrimaryPart.Position - bondPosition).Magnitude or (bond.Position - bondPosition).Magnitude
            if distance and distance <= collectDistance then
                remote:FireServer(bond) -- Collect Bond
                print("Collected Bond:", bond.Name)
            end
        end
        task.wait(walkDelay) -- Add a delay to prevent overwhelming the server
    end
end
