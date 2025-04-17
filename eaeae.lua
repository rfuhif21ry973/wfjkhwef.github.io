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
local collectWait = 0.3 -- Small wait to ensure Bond collection happens

local detectionRadius = 150 -- Radius for highlighting Bonds
local trackedBonds = {} -- Table to store unique Bond objects

-- Function to create a tween to move the player
local function tweenToPosition(newZ)
    local goal = {}
    goal.CFrame = CFrame.new(Vector3.new(x, y, newZ))
    local tween = TweenService:Create(root, TweenInfo.new(duration, Enum.EasingStyle.Linear), goal)
    tween:Play()
    tween.Completed:Wait() -- Wait for the tween to complete
end

-- Function to highlight Bonds within range
local function highlightNearbyBonds()
    for _, bond in pairs(runtimeItems:GetChildren()) do
        if bond:IsA("Model") and bond.Name:match("Bond") then
            local distance = (root.Position - bond:GetModelCFrame().Position).Magnitude
            if distance <= detectionRadius then
                -- Create label above Bond
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

                -- Highlight Bond
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
end

-- Function to track Bonds during tweening
local function trackBonds()
    for _, bond in pairs(runtimeItems:GetChildren()) do
        -- Only track items explicitly named "Bond"
        if bond.Name:match("Bond") and not table.find(trackedBonds, bond) then
            table.insert(trackedBonds, bond) -- Add Bond object to tracked list
            print("Bond found:", bond.Name)
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
    task.wait(collectWait) -- Small wait after collecting
end

-- Start script logic
task.spawn(function()
    -- Tween through the specified Z range
    for z = startZ, endZ, stepZ do
        tweenToPosition(z) -- Tween player movement
        highlightNearbyBonds() -- Highlight nearby Bonds
        trackBonds() -- Track bonds during each step
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
            collectBond(bond) -- Collect the Bond with a small wait
            task.wait(0.1) -- Very fast teleport delay (adjustable)
        end
    end

    -- Final update on total number of Bonds collected
    print("Total Bonds collected:", #trackedBonds)
end)
