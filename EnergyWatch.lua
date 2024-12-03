local frame = CreateFrame("StatusBar", "EnergyWatch", UIParent, "BackdropTemplate")
frame:SetSize(75, 20)
frame:SetPoint("CENTER")
frame:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
frame:SetStatusBarColor(1, 1, 0)
frame:SetMinMaxValues(0, 1)
frame:SetValue(0)
frame:EnableMouse(true)
frame:SetMovable(true)
frame:SetClampedToScreen(true)
frame:RegisterForDrag("LeftButton")

-- Debug for SavedVariables
print("DEBUG: EnergyWatch.lua loaded.")
local function debugSavedVariables()
    if not EnergyWatchDB then
        print("DEBUG: EnergyWatchDB does not exist!")
    else
        print("DEBUG: EnergyWatchDB exists. textVisible = " .. tostring(EnergyWatchDB.textVisible))
    end
end

-- ADDON_LOADED Event
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, EnergyWatch)
    if EnergyWatch == "EnergyWatch" then
        if not EnergyWatchDB then
            EnergyWatchDB = { textVisible = true } -- Initialiser SavedVariables
            print("DEBUG: EnergyWatchDB initialized.")
        else
            print("DEBUG: EnergyWatchDB loaded. textVisible = " .. tostring(EnergyWatchDB.textVisible))
        end
    end
end)

-- Resten af din kode her...


frame:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
frame:SetBackdropColor(0, 0, 0, 0.8)
frame:SetBackdropBorderColor(1, 1, 1, 0.5)

local energyBar = CreateFrame("StatusBar", nil, frame)
energyBar:SetSize(65, 10)
energyBar:SetPoint("CENTER", frame, "CENTER", 0, 0)
energyBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
energyBar:SetStatusBarColor(1, 1, 0)
energyBar:SetMinMaxValues(0, 1)
energyBar:SetValue(0)

local isLocked = true
local tickDuration = 2.0225
local lastTickTime = GetTime()
local lastEnergy = UnitPower("player", Enum.PowerType.Energy)

frame:SetScript("OnUpdate", function(self, elapsed)
    local currentTime = GetTime()
    local elapsedTime = currentTime - lastTickTime
    if elapsedTime >= tickDuration then
        elapsedTime = elapsedTime % tickDuration
        lastTickTime = currentTime
        energyBar:SetValue(0) -- Reset bar
    else
        energyBar:SetValue(elapsedTime / tickDuration)
    end
end)

frame:RegisterEvent("UNIT_POWER_UPDATE")
frame:SetScript("OnEvent", function(self, event, unit, powerType)
    if unit == "player" and powerType == "ENERGY" then
        local currentEnergy = UnitPower("player", Enum.PowerType.Energy)
        if currentEnergy > lastEnergy then
            lastTickTime = GetTime() -- Resync tick
        end
        lastEnergy = currentEnergy
    end
end)

frame:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" and IsShiftKeyDown() then
        isLocked = not isLocked
        self:EnableMouse(not isLocked)
        print(isLocked and "Bar locked" or "Bar unlocked")
    end
end)

frame:SetScript("OnDragStart", function(self)
    if not isLocked then
        self:StartMoving()
    end
end)

frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
end)

-- Opret tekst foran energibaren
local energyText = energyBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
energyText:SetPoint("CENTER", energyBar, "CENTER", 0, 0)
energyText:SetTextColor(1, 1, 1)

-- Funktion til at opdatere teksten
local function updateEnergyText()
    local currentEnergy = UnitPower("player", Enum.PowerType.Energy)
    energyText:SetText(currentEnergy)
end

-- Opdater teksten når energien ændrer sig
frame:RegisterEvent("UNIT_POWER_UPDATE")
frame:HookScript("OnEvent", function(self, event, unit, powerType)
    if unit == "player" and powerType == "ENERGY" then
        updateEnergyText()
    end
end)

-- Initial tekstopdatering
updateEnergyText()

frame:Show()

-- Slash commands for resetting bar position and toggling text visibility
SLASH_ENERGYWATCH1, SLASH_ENERGYWATCH2, SLASH_ENERGYWATCH3, SLASH_ENERGYWATCH4, SLASH_ENERGYWATCH5 = '/EW', '/ew', '/EnergyWatch', '/energywatch', '/Energywatch'

SlashCmdList["ENERGYWATCH"] = function(msg)
    msg = msg:lower()
    if msg == "reset" then
        frame:ClearAllPoints()
        frame:SetPoint("CENTER")
        print("EnergyWatch: Bar position has been reset to center.")
    elseif msg == "numbers" then
        local textVisible = not energyText:IsShown()
        energyText:SetShown(textVisible)
        EnergyWatchDB.textVisible = textVisible -- Gem præference
        debugSavedVariables() -- Debug efter ændring
        print("EnergyWatch: Numbers are now " .. (textVisible and "visible." or "hidden."))
    else
        print("EnergyWatch commands:")
        print("/ew reset - Resets the bar to the center of the screen.")
        print("/ew numbers - Toggles visibility of the numbers on the bar.")
        print("Shift-click to lock/unlock the bar for moving.")
    end
end
