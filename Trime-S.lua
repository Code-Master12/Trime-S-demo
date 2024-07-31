local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Code-Master12/trime-ui-lib/main/trime-library.lua"))()
--https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua
local Window = Library.CreateLib("Trime -S", "BloodTheme")

local Main = Window:NewTab("Main")
local Section = Main:NewSection("Main")
local plr = game.Players.LocalPlayer
local humanoid = plr.Character.Humanoid
local disabled = false
local userInputService = game:GetService("UserInputService")
local oldWalkSpeed = humanoid.WalkSpeed
local oldJumpPower = humanoid.JumpPower

local ESP = loadstring(game:HttpGet('https://raw.githubusercontent.com/Code-Master12/Trime-S-ESP/main/esp.lua'))()
local PKN = loadstring(game:HttpGet('https://raw.githubusercontent.com/Code-Master12/Trime-S-PKN/main/pkn.lua'))()
local TP = loadstring(game:HttpGet('https://raw.githubusercontent.com/Code-Master12/Trime-S-TP/main/tp.lua'))()
local tpEnabled = false

print("Trime -S: Succesfully injected! Developed by: Metricsect Dev & mutocan_baba1")

game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Trime -S";
    Text = "Succesfully injected!\nDeveloped by: Metricsect Dev & mutocan_baba1";
})

game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Trime -S";
    Text = "Press Z for toggle UI";
})

Section:NewButton("Infinite Yield", "FE Admin commands for all roblox games.", function()
    loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
    print("Trime -S: Infinite yield succesfully started! Place ID:", game.PlaceId)
end)

Section:NewToggle("Toggle ESP", "Toggle ESP.", function(state)
    ESP:toggleESP()
    print("Trime -S: ESP Toggled! Place ID:", game.PlaceId)
end)

Section:NewButton("Exit", "Exits from Trime -S", function()
    disabled = true
    tpEnabled = false
    ESP:DisableESP()
    PKN:disablePKN()
    Library:HideUI()
    print("Trime -S: Exit made Place ID:", game.PlaceId)
end)

local Section = Main:NewSection("---------------------------- CONTROLS ----------------------------")

Section:NewLabel("Z: Toggle UI")

local Main = Window:NewTab("Player")
local Section = Main:NewSection("Player")

Section:NewButton("Reset Speed & Jump Power", "This button reset speed & jump power.", function()
    humanoid.WalkSpeed = oldWalkSpeed
    humanoid.JumpPower = oldJumpPower
    print("Trime -S: Speed & Jump Power have been reset! Place ID:", game.PlaceId)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Trime -S";
        Text = "Speed & Jump Power have been reset!";
    })
end)

Section:NewSlider("Speed Hack", "This slider adjusts the speed hack.", 200, 16, function(speed)
    humanoid.WalkSpeed = speed
end)
Section:NewSlider("Jump Hack", "This slider adjusts the jump power hack.", 1000, 50, function(jumpPower)
    humanoid.JumpPower = jumpPower
end)

local Main = Window:NewTab("MVS")
local Section = Main:NewSection("Murderers VS Sheriffs Scripts")

Section:NewButton("MVS Script", "Murderers VS Sheriffs script. (legit)", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Mrpopcatfrombupge/FreeCpsvirs/main/Mvss"))()
    print("Trime -S: MVS Script succesfully started! Place ID:", game.PlaceId)
end)

Section:NewButton("MVS Script 2", "Murderers VS Sheriffs script 2 (kill all).", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Deni210/murdersvssherrifsduels/main/rubyhub", true))()
    print("Trime -S: MVS Script succesfully started! Place ID:", game.PlaceId)
end)

Section:NewToggle("Toggle PKN", "Toggle Player Kill Notification.", function(state)
    PKN:togglePKN()
    print("Trime -S: PKN Toggled! Place ID:", game.PlaceId)
end)

Section:NewToggle("Toggle Teleport (C)", "When activated, pressing C will teleport to the enemy player's base", function(state)
    tpEnabled = not tpEnabled
    if tpEnabled then
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Trime -S";
            Text = "TP Enabled!";
        })
    else
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Trime -S";
            Text = "TP Disabled!";
        })
    end
end)

local function onKeyPressZ(input, gameProcessed)
    if gameProcessed then
        return
    end

    if disabled then return end

    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Z then
        Library:ToggleUI()
    end
end

local function onKeyPressC(input, gameProcessed)
    if gameProcessed then
        return
    end

    if disabled then return end

    if not tpEnabled then return end

    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.C then
        TP:checkAndMovePlayer()
    end
end

userInputService.InputBegan:Connect(onKeyPressC)
userInputService.InputBegan:Connect(onKeyPressZ)
