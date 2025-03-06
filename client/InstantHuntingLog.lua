--------------------------------------------------------------------------------
-- HuntingLog.lua
-- Main Hunting Log script that references huntingLogConfigs.lua for all
-- visual/layout configuration values.
--------------------------------------------------------------------------------

local HuntingLogConfigs = {}

-- [Panel Position & Dimensions]
-- The X position of the Hunting Log panel on the screen
HuntingLogConfigs.panelX = 850

-- The Y position of the Hunting Log panel on the screen
HuntingLogConfigs.panelY = 440

-- The width of the Hunting Log panel in pixels
HuntingLogConfigs.boxWidth = 160

-- The height of the Hunting Log panel in pixels when not minimized
HuntingLogConfigs.boxHeight = 115

-- The height of the header bar in pixels
HuntingLogConfigs.headerHeight = 20

-- [Colors (RGBA)]
-- Background color of the panel (values from 0.0 to 1.0)
HuntingLogConfigs.panelBgColor = {0.0, 0.0, 0.0, 0.8}

-- Border/title bar color of the panel
HuntingLogConfigs.panelBorderColor = {0.3, 0.2, 0.2, 1.0}

-- Color used for the title text and the +/- toggle
HuntingLogConfigs.titleColor = {255, 215, 0, 255}

-- Color used for label text (e.g. "Hunting Time:")
HuntingLogConfigs.labelColor = {230, 230, 230, 255}

-- Color used for numeric values (e.g. "2,274,000")
HuntingLogConfigs.valueColor = {255, 165, 0, 255}

-- [Fonts & Spacing]
-- The font type used for the +/- toggle button text
-- 0 = normal, 1 = bold, 2 = big, etc.
HuntingLogConfigs.toggleButtonFontType = 2

-- The default font type used for most label text
HuntingLogConfigs.defaultFontType = 1

-- The line height in pixels for spacing between rows of text
HuntingLogConfigs.lineHeight = 11


-- [Other Visual Settings]
-- The text displayed in the panel's title bar
HuntingLogConfigs.titleText = "Instant Hunting Log"

-- The time in seconds after which the log auto-hides if no packet is received
HuntingLogConfigs.autoHideTime = 17

-- The Packet identifier for the hunting log
HUNTING_LOG_PACKET = 0xF3

HuntingLog = {}

-------------------------------------------------------------------------------
-- Internal state variables (not in config, because these are logic-related)
-------------------------------------------------------------------------------
local expPerMinute       = 0
local lastExpReceived    = 0
local levelUpCount       = 0
local sessionStartTime   = 0
local nextLevelIn        = "00:00:00"
local resetLevelIn       = "00:00:00"
local maxLevelIn         = "00:00:00"
local sessionTime        = "00:00:00"
local lastPacketTime     = 0
local isHuntingLogVisible= false
local isMinimized        = false

-------------------------------------------------------------------------------
-- RENDER
-------------------------------------------------------------------------------
function HuntingLog.Render()
    if not isHuntingLogVisible then
        return
    end

    local posX = HuntingLogConfigs.panelX
    local posY = HuntingLogConfigs.panelY

    -- If minimized, only draw the header area
    local currentHeight = isMinimized and HuntingLogConfigs.headerHeight or HuntingLogConfigs.boxHeight

    -- Draw the panel (header + possibly body)
    UIFramework.CreatePanel(
        posX,
        posY,
        HuntingLogConfigs.boxWidth,
        currentHeight,
        HuntingLogConfigs.panelBgColor, 
        HuntingLogConfigs.panelBorderColor,
        HuntingLogConfigs.titleText
    )

    local buttonWidth  = math.floor(HuntingLogConfigs.boxWidth * 0.3)
    local buttonX      = posX + HuntingLogConfigs.boxWidth - buttonWidth
    local buttonY      = posY
    local buttonText   = isMinimized and "▼" or "▲"

    -- Draw the +/- button text
    UIFramework.CreateTextLabel(
        buttonX + (buttonWidth / 2),
        buttonY + 5,
        buttonText,
        HuntingLogConfigs.labelColor,
        3,
        ALIGN_CENTER,
        HuntingLogConfigs.panelBorderColor
    )

    -- If minimized, do not draw the stats
    if isMinimized then
        return
    end

    -- Render the various stats
    local lineHeight  = HuntingLogConfigs.lineHeight
    local contentPosY = posY + HuntingLogConfigs.headerHeight + lineHeight

    -- Calculate "Hunting Time"
    local sessionElapsedTime = os.time() - sessionStartTime
    local sessionHours       = math.floor(sessionElapsedTime / 3600)
    local sessionMinutes     = math.floor((sessionElapsedTime % 3600) / 60)
    local sessionSeconds     = sessionElapsedTime % 60
    sessionTime              = string.format("%02d:%02d:%02d", sessionHours, sessionMinutes, sessionSeconds)

    -- Hunting Time
    UIFramework.CreateTextLabel(posX + 10, contentPosY, "Hunting Time:", HuntingLogConfigs.labelColor, HuntingLogConfigs.defaultFontType)
    UIFramework.CreateTextLabel(posX + 98, contentPosY, sessionTime, HuntingLogConfigs.valueColor, HuntingLogConfigs.defaultFontType, ALIGN_RIGHT)

    -- Exp. per minute
    UIFramework.CreateTextLabel(posX + 10, contentPosY + lineHeight, "Exp. per minute:", HuntingLogConfigs.labelColor, HuntingLogConfigs.defaultFontType)
    UIFramework.CreateTextLabel(posX + 98, contentPosY + lineHeight, FormatNumber(expPerMinute), HuntingLogConfigs.valueColor, HuntingLogConfigs.defaultFontType, ALIGN_RIGHT)

    -- Last exp. received
    UIFramework.CreateTextLabel(posX + 10, contentPosY + lineHeight * 2, "Last exp. received:", HuntingLogConfigs.labelColor, HuntingLogConfigs.defaultFontType)
    UIFramework.CreateTextLabel(posX + 98, contentPosY + lineHeight * 2, FormatNumber(lastExpReceived), HuntingLogConfigs.valueColor, HuntingLogConfigs.defaultFontType, ALIGN_RIGHT)

    -- Level Ups
    UIFramework.CreateTextLabel(posX + 10, contentPosY + lineHeight * 3, "Level Ups:", HuntingLogConfigs.labelColor, HuntingLogConfigs.defaultFontType)
    UIFramework.CreateTextLabel(posX + 98, contentPosY + lineHeight * 3, tostring(levelUpCount), HuntingLogConfigs.valueColor, HuntingLogConfigs.defaultFontType, ALIGN_RIGHT)

    -- Next level in
    UIFramework.CreateTextLabel(posX + 10, contentPosY + lineHeight * 4, "Next level in:", HuntingLogConfigs.labelColor, HuntingLogConfigs.defaultFontType)
    UIFramework.CreateTextLabel(posX + 98, contentPosY + lineHeight * 4, nextLevelIn, HuntingLogConfigs.valueColor, HuntingLogConfigs.defaultFontType, ALIGN_RIGHT)

    -- Reset(350) in
    UIFramework.CreateTextLabel(posX + 10, contentPosY + lineHeight * 5, "Reset(350) in:", HuntingLogConfigs.labelColor, HuntingLogConfigs.defaultFontType)
    UIFramework.CreateTextLabel(posX + 98, contentPosY + lineHeight * 5, resetLevelIn, HuntingLogConfigs.valueColor, HuntingLogConfigs.defaultFontType, ALIGN_RIGHT)

    -- Max level(400) in
    UIFramework.CreateTextLabel(posX + 10, contentPosY + lineHeight * 6, "Max level(400) in:", HuntingLogConfigs.labelColor, HuntingLogConfigs.defaultFontType)
    UIFramework.CreateTextLabel(posX + 98, contentPosY + lineHeight * 6, maxLevelIn, HuntingLogConfigs.valueColor, HuntingLogConfigs.defaultFontType, ALIGN_RIGHT)
end

-------------------------------------------------------------------------------
-- UPDATE: Processes incoming packets to update stats
-------------------------------------------------------------------------------
function HuntingLog.Update(Packet, PacketName)
    if Packet == HUNTING_LOG_PACKET then
        expPerMinute         = GetDwordPacket(PacketName, 0) or 0
        local lastGainedExp  = GetDwordPacket(PacketName, 4) or 0
        levelUpCount         = GetDwordPacket(PacketName, 8) or 0

        local nextLevelTimeRaw  = GetDwordPacket(PacketName, 12) or 0
        local maxLevelTimeRaw   = GetDwordPacket(PacketName, 16) or 0
        local resetLevelTimeRaw = GetDwordPacket(PacketName, 20) or 0

        sessionStartTime = GetDwordPacket(PacketName, 24) or 0
        lastExpReceived  = (lastGainedExp > 0) and lastGainedExp or lastExpReceived

        local days    = math.floor(nextLevelTimeRaw / 86400)
        local hours   = math.floor(nextLevelTimeRaw / 3600)
        local minutes = math.floor((nextLevelTimeRaw % 3600) / 60)
        local seconds = nextLevelTimeRaw % 60
        nextLevelIn   = string.format("%02d:%02d:%02d:%02d", days, hours, minutes, seconds)

        local maxDays    = math.floor(maxLevelTimeRaw / 86400)
        local maxHours   = math.floor(maxLevelTimeRaw / 3600)
        local maxMinutes = math.floor((maxLevelTimeRaw % 3600) / 60)
        local maxSeconds = maxLevelTimeRaw % 60
        maxLevelIn       = string.format("%02d:%02d:%02d:%02d", maxDays, maxHours, maxMinutes, maxSeconds)

        local resetDays    = math.floor(resetLevelTimeRaw / 86400)
        local resetHours   = math.floor(resetLevelTimeRaw / 3600)
        local resetMinutes = math.floor((resetLevelTimeRaw % 3600) / 60)
        local resetSeconds = resetLevelTimeRaw % 60
        resetLevelIn       = string.format("%02d:%02d:%02d:%02d", resetDays, resetHours, resetMinutes, resetSeconds)

        lastPacketTime      = os.time()
        isHuntingLogVisible = true
        ClearPacket(Packet)
    end
end

-------------------------------------------------------------------------------
-- UPDATE PROC: Hides the log if no new packet after 'autoHideTime' seconds
-------------------------------------------------------------------------------
function HuntingLog.UpdateUI()
    if isHuntingLogVisible and (os.time() - lastPacketTime > HuntingLogConfigs.autoHideTime) then
        isHuntingLogVisible = false
    end
end

-------------------------------------------------------------------------------
-- CLICK CHECK: Disables movement on header click and toggles minimized if +/- button
-------------------------------------------------------------------------------
function HuntingLog.CheckHeaderClick()
    -- Did the player just left-click?
    if CheckClickClient() == 1 then
        local mouseX = MousePosX()
        local mouseY = MousePosY()

        -- Header bounding box
        local headerX = HuntingLogConfigs.panelX
        local headerY = HuntingLogConfigs.panelY
        local headerW = HuntingLogConfigs.boxWidth
        local headerH = HuntingLogConfigs.headerHeight

        -- If user clicked in the header
        if (mouseX >= headerX and mouseX <= (headerX + headerW)) and
           (mouseY >= headerY and mouseY <= (headerY + headerH)) then

            -- Prevent character movement
            DisableClickClient()

            -- +/- button bounding box
            local buttonW = math.floor(headerW * 0.2)
            local buttonH = headerH
            local buttonX = headerX + headerW - buttonW
            local buttonY = headerY

            -- If the user clicked on the +/- button, toggle minimized
            if (mouseX >= buttonX and mouseX <= (buttonX + buttonW)) and
               (mouseY >= buttonY and mouseY <= (buttonY + buttonH)) then
                isMinimized = not isMinimized
            end
        end
    end
end

-------------------------------------------------------------------------------
-- FORMATTING
-------------------------------------------------------------------------------
function FormatNumber(value)
    local str = tostring(value)
    if not str:match("^%d+$") then
        return value
    end
    local formatted = str:reverse():gsub("(%d%d%d)", "%1 "):reverse()
    return formatted:match("^%s*(.-)%s*$")
end

-------------------------------------------------------------------------------
-- INIT
-------------------------------------------------------------------------------
function HuntingLog.Init()
    InterfaceController.BeforeMainProc(HuntingLog.Render)
    InterfaceController.ClientProtocol(HuntingLog.Update)

    -- 1) Auto-hide after 'autoHideTime' seconds
    InterfaceController.UpdateProc(HuntingLog.UpdateUI)

    -- 2) Detect header clicks to toggle minimized
    InterfaceController.UpdateProc(HuntingLog.CheckHeaderClick)
end

HuntingLog.Init()
