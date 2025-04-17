local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local plr = Players.LocalPlayer
local chr = plr.Character or plr.CharacterAdded:Wait()
local root = chr:WaitForChild("HumanoidRootPart")
local runtimeItems = Workspace:WaitForChild("RuntimeItems")

local x = 57
local y = 3
local startZ = 30000
local endZ = -49032.99
local stepZ = -3000 -- Step size for tweening
local duration = 0.5 -- Duration for each tween step

local trackedBonds = {} -- Table to store Bond objects
local gui = plr.PlayerGui:FindFirstChild("BondGUI") or Instance.new("ScreenGui", plr.PlayerGui) -- Ensure GUI exists

gui.Name = "BondGUI"

-- Function to create the GUI button for a Bond
local function createBondButton(bondName, bondPosition)
    local button = Instance.new("TextButton")
    button.Parent = gui
    button.Size = UDim2.new(0, 200, 0, 50)
    button.Position = UDim2.new(0, 10, 0, (#gui:GetChildren() - 1) * 60) -- Position buttons dynamically
    button.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    button.TextColor3 = Color3.fromRGB(0, 0, 0)
    button.TextScaled = true
    button.Font = Enum.Font.GothamBold
    button.Text = bondName

    -- Teleport the player when the button is clicked
    button.MouseButton1Click:Connect(function()
        root.CFrame = CFrame.new(bondPosition)
        print("Teleported to Bond:", bondName, "| Location:", bondPosition)
    end)
end

-- Function to dynamically track and create GUI entries for Bonds
local function trackBonds()
    for _, bond in pairs(runtimeItems:GetChildren()) do
        if bond:IsA("Model") and bond.Name:match("Bond") and bond.PrimaryPart and not table.find(trackedBonds, bond.PrimaryPart.Position) then
            table.insert(trackedBonds, bond.PrimaryPart.Position) -- Log Bond's location
            print("Bond tracked:", bond.Name, "| Location:", bond.PrimaryPart.Position)
            createBondButton(bond.Name, bond.PrimaryPart.Position) -- Create GUI button for this Bond
        elseif bond:IsA("BasePart") and bond.Name:match("Bond") and not table.find(trackedBonds, bond.Position) then
            table.insert(trackedBonds, bond.Position) -- Log Bond's location
            print("Bond tracked (BasePart):", bond.Name, "| Location:", bond.Position)
            createBondButton(bond.Name, bond.Position) -- Create GUI button for this Bond
        end
    end
end

-- Function to create a tween to move the player
local function tweenToPosition(newZ)
    local goal = {}
    goal.CFrame = CFrame.new(Vector3.new(x, y, newZ))
    local tween = TweenService:Create(root, TweenInfo.new(duration, Enum.EasingStyle.Linear), goal)
    tween:Play()
    tween.Completed:Wait() -- Wait for the tween to complete
end

-- Main script logic
task.spawn(function()
    -- Tween through the Z-axis and track Bonds
    for z = startZ, endZ, stepZ do
        tweenToPosition(z) -- Tween player movement
        trackBonds() -- Track Bonds and create GUI entries
    end

    print("Finished tweening. Total Bonds tracked:", #trackedBonds)
end)
