local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
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
local collectDistance = 20 -- Distance within which Bonds will be collected
local walkDelay = 0.1 -- Delay for processing collection checks

local trackedBonds = {} -- Table to track collected Bonds

-- Function to create a tween to move the player
local function tweenToPosition(newZ)
    local goal = {}
    goal.CFrame = CFrame.new(Vector3.new(x, y, newZ))
    local tween = TweenService:Create(root, TweenInfo.new(duration, Enum.EasingStyle.Linear), goal)
    tween:Play()
    tween.Completed:Wait() -- Wait for the tween to complete
end

-- Function to create a floating label above the Bond
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

-- Function to add a highlight to the Bond
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

-- Highlight and label Bonds within detection radius
local function highlightNearbyBonds()
    for _, bond in pairs(runtimeItems:GetChildren()) do
        if bond:IsA("Model") and bond.Name:match("Bond") then
            local distance = (root.Position - bond:GetModelCFrame().Position).Magnitude
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

-- Function to find the nearest Bond within collection distance
local function GetNearestBond()
    local closestBond = nil
    local closestDistance = math.huge
    for _, bond in pairs(runtimeItems:GetChildren()) do
        if bond:IsA("Model") and bond.Name:match("Bond") then
            local distance = (root.Position - bond:GetModelCFrame().Position).Magnitude
            if distance < closestDistance then
                closestBond = bond
                closestDistance = distance
            end
        end
    end
    return closestBond, closestDistance
end

-- Continuous monitoring for Bond collection
RunService.Heartbeat:Connect(function()
    highlightNearbyBonds() -- Continuously update visibility

    local bond, distance = GetNearestBond()
    if bond and distance <= collectDistance then
        remote:FireServer(bond) -- Collect Bond
        if not table.find(trackedBonds, bond) then
            table.insert(trackedBonds, bond) -- Track collected Bond
            print("Collected Bond:", bond.Name)
        end
    end
    task.wait(walkDelay)
end)

-- Tween through the Z range (optional movement logic)
task.spawn(function()
    for z = startZ, endZ, stepZ do
        tweenToPosition(z)
        task.wait(walkDelay) -- Small wait between steps
    end

    print("Finished tweening.")
end)
