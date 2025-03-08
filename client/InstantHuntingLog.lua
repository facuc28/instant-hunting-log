--------------------------------------------------------------------------------
-- InstantHuntingLog.lua
-- Client side script for the Hunting Log UI, with a custom stylized header.
--------------------------------------------------------------------------------

local HuntingLogConfigs = {}

-- [Panel Position & Dimensions]
HuntingLogConfigs.panelX       = 850
HuntingLogConfigs.panelY       = 420
HuntingLogConfigs.boxWidth     = 165
HuntingLogConfigs.boxHeight    = 165  -- Height for main panel
HuntingLogConfigs.headerHeight = 20   -- Height of the custom header bar

-- [Colors (RGBA)]
HuntingLogConfigs.panelBgColor     = {0.0, 0.0, 0.0, 0.8}
HuntingLogConfigs.panelBorderColor = {0.3, 0.2, 0.2, 1.0}
HuntingLogConfigs.labelColor       = {230, 230, 230, 255}
HuntingLogConfigs.valueColor       = {255, 165, 0, 255}

-- [Fonts & Spacing]
HuntingLogConfigs.toggleButtonFontType = 2
HuntingLogConfigs.defaultFontType      = 1
HuntingLogConfigs.lineHeight           = 11

-- [Other Visual Settings]
HuntingLogConfigs.titleText     = "Instant Hunting Log"
HuntingLogConfigs.autoHideTime  = 17
HUNTING_LOG_PACKET              = 0xF3

HuntingLog = {}

-------------------------------------------------------------------------------
-- Internal state variables
-------------------------------------------------------------------------------
local expPerMinute        = 0
local lastExpReceived     = 0
local levelUpCount        = 0
local sessionStartTime    = 0
local nextLevelIn         = "00:00:00"
local resetLevelIn        = "00:00:00"
local maxLevelIn          = "00:00:00"
local sessionTime         = "00:00:00"
local lastPacketTime      = 0
local isHuntingLogVisible = false
local isMinimized         = false

-- Zen stats
local zenPerMinute        = 0
local lastZenReceived     = 0

-- Drag variables
local isDragging          = false
local dragOffsetX         = 0
local dragOffsetY         = 0

-------------------------------------------------------------------------------
-- RENDER
-------------------------------------------------------------------------------
function HuntingLog.Render()
    if not isHuntingLogVisible then
        return
    end

    local posX = HuntingLogConfigs.panelX
    local posY = HuntingLogConfigs.panelY
    local currentHeight = isMinimized and HuntingLogConfigs.headerHeight or HuntingLogConfigs.boxHeight

    -- Draw the main panel background with NO title (we'll do a custom header)
    UIFramework.CreatePanel(
        posX,
        posY,
        HuntingLogConfigs.boxWidth,
        currentHeight,
        HuntingLogConfigs.panelBgColor,
        HuntingLogConfigs.panelBorderColor,
        HuntingLogConfigs.titleText
    )
    
    -- Draw the toggle button on the right side of the header
    local buttonWidth = math.floor(HuntingLogConfigs.boxWidth * 0.3)
    local buttonX     = posX + HuntingLogConfigs.boxWidth - buttonWidth
    local buttonY     = posY
    local buttonText  = isMinimized and "▼" or "▲"

    UIFramework.CreateTextLabel(
        buttonX + (buttonWidth / 2),
        buttonY + 5,
        buttonText,
        HuntingLogConfigs.labelColor,
        3,
        ALIGN_CENTER,
        HuntingLogConfigs.panelBorderColor
    )

    -- If minimized, skip drawing the stats
    if isMinimized then
        return
    end

    -- Draw all stats below the header
    local lineHeight  = HuntingLogConfigs.lineHeight
    local contentPosY = posY + HuntingLogConfigs.headerHeight + lineHeight

    -- Calculate "Hunting Time"
    local sessionElapsedTime = os.time() - sessionStartTime
    local sessionHours       = math.floor(sessionElapsedTime / 3600)
    local sessionMinutes     = math.floor((sessionElapsedTime % 3600) / 60)
    local sessionSeconds     = sessionElapsedTime % 60
    sessionTime = string.format("%02d:%02d:%02d", sessionHours, sessionMinutes, sessionSeconds)

    UIFramework.CreateTextLabel(posX + 10, contentPosY, "Hunting Time:", HuntingLogConfigs.labelColor, HuntingLogConfigs.defaultFontType)
    UIFramework.CreateTextLabel(posX + 100, contentPosY, sessionTime, HuntingLogConfigs.valueColor, HuntingLogConfigs.defaultFontType, ALIGN_RIGHT)

    -- Empty line for spacing
    UIFramework.CreateTextLabel(posX + 10, contentPosY + lineHeight, " ", HuntingLogConfigs.labelColor, HuntingLogConfigs.defaultFontType)

    UIFramework.CreateTextLabel(posX + 10, contentPosY + lineHeight * 2, "Exp. per minute:", HuntingLogConfigs.labelColor, HuntingLogConfigs.defaultFontType)
    UIFramework.CreateTextLabel(posX + 100, contentPosY + lineHeight * 2, FormatNumber(expPerMinute), HuntingLogConfigs.valueColor, HuntingLogConfigs.defaultFontType, ALIGN_RIGHT)

    UIFramework.CreateTextLabel(posX + 10, contentPosY + lineHeight * 3, "Last exp. received:", HuntingLogConfigs.labelColor, HuntingLogConfigs.defaultFontType)
    UIFramework.CreateTextLabel(posX + 100, contentPosY + lineHeight * 3, FormatNumber(lastExpReceived), HuntingLogConfigs.valueColor, HuntingLogConfigs.defaultFontType, ALIGN_RIGHT)

    UIFramework.CreateTextLabel(posX + 10, contentPosY + lineHeight * 4, "Level Ups:", HuntingLogConfigs.labelColor, HuntingLogConfigs.defaultFontType)
    UIFramework.CreateTextLabel(posX + 100, contentPosY + lineHeight * 4, tostring(levelUpCount), HuntingLogConfigs.valueColor, HuntingLogConfigs.defaultFontType, ALIGN_RIGHT)

    UIFramework.CreateTextLabel(posX + 10, contentPosY + lineHeight * 5, "Next level in:", HuntingLogConfigs.labelColor, HuntingLogConfigs.defaultFontType)
    UIFramework.CreateTextLabel(posX + 100, contentPosY + lineHeight * 5, nextLevelIn, HuntingLogConfigs.valueColor, HuntingLogConfigs.defaultFontType, ALIGN_RIGHT)

    UIFramework.CreateTextLabel(posX + 10, contentPosY + lineHeight * 6, "Reset(350) in:", HuntingLogConfigs.labelColor, HuntingLogConfigs.defaultFontType)
    UIFramework.CreateTextLabel(posX + 100, contentPosY + lineHeight * 6, resetLevelIn, HuntingLogConfigs.valueColor, HuntingLogConfigs.defaultFontType, ALIGN_RIGHT)

    UIFramework.CreateTextLabel(posX + 10, contentPosY + lineHeight * 7, "Max level(400) in:", HuntingLogConfigs.labelColor, HuntingLogConfigs.defaultFontType)
    UIFramework.CreateTextLabel(posX + 100, contentPosY + lineHeight * 7, maxLevelIn, HuntingLogConfigs.valueColor, HuntingLogConfigs.defaultFontType, ALIGN_RIGHT)

    -- Another spacing line
    UIFramework.CreateTextLabel(posX + 10, contentPosY + lineHeight * 8, " ", HuntingLogConfigs.labelColor, HuntingLogConfigs.defaultFontType)

    UIFramework.CreateTextLabel(posX + 10, contentPosY + lineHeight * 9, "Zen per minute:", HuntingLogConfigs.labelColor, HuntingLogConfigs.defaultFontType)
    UIFramework.CreateTextLabel(posX + 100, contentPosY + lineHeight * 9, FormatNumber(zenPerMinute), HuntingLogConfigs.valueColor, HuntingLogConfigs.defaultFontType, ALIGN_RIGHT)

    UIFramework.CreateTextLabel(posX + 10, contentPosY + lineHeight * 10, "Last Zen received:", HuntingLogConfigs.labelColor, HuntingLogConfigs.defaultFontType)
    UIFramework.CreateTextLabel(posX + 100, contentPosY + lineHeight * 10, FormatNumber(lastZenReceived), HuntingLogConfigs.valueColor, HuntingLogConfigs.defaultFontType, ALIGN_RIGHT)
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

        sessionStartTime     = GetDwordPacket(PacketName, 24) or 0
        zenPerMinute         = GetDwordPacket(PacketName, 28) or 0
        local lastZen        = GetDwordPacket(PacketName, 32) or 0
        lastZenReceived      = (lastZen > 0) and lastZen or lastZenReceived
        lastExpReceived      = (lastGainedExp > 0) and lastGainedExp or lastExpReceived

        local days    = math.floor(nextLevelTimeRaw / 86400)
        local hours   = math.floor((nextLevelTimeRaw % 86400) / 3600)
        local minutes = math.floor((nextLevelTimeRaw % 3600) / 60)
        local seconds = nextLevelTimeRaw % 60
        nextLevelIn   = string.format("%02d:%02d:%02d:%02d", days, hours, minutes, seconds)

        local maxDays    = math.floor(maxLevelTimeRaw / 86400)
        local maxHours   = math.floor((maxLevelTimeRaw % 86400) / 3600)
        local maxMinutes = math.floor((maxLevelTimeRaw % 3600) / 60)
        local maxSeconds = maxLevelTimeRaw % 60
        maxLevelIn       = string.format("%02d:%02d:%02d:%02d", maxDays, maxHours, maxMinutes, maxSeconds)

        local resetDays    = math.floor(resetLevelTimeRaw / 86400)
        local resetHours   = math.floor((resetLevelTimeRaw % 86400) / 3600)
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
-- CLICK CHECK: Handles header clicks for toggling and drag mode
-------------------------------------------------------------------------------
function HuntingLog.CheckHeaderClick()
    if CheckClickClient() == 1 then
        local mouseX = MousePosX()
        local mouseY = MousePosY()

        local headerX = HuntingLogConfigs.panelX
        local headerY = HuntingLogConfigs.panelY
        local headerW = HuntingLogConfigs.boxWidth
        local headerH = HuntingLogConfigs.headerHeight

        if (mouseX >= headerX and mouseX <= (headerX + headerW)) and
           (mouseY >= headerY and mouseY <= (headerY + headerH)) then

            DisableClickClient()

            local buttonW = math.floor(headerW * 0.2)
            local buttonH = headerH
            local buttonX = headerX + headerW - buttonW
            local buttonY = headerY

            if (mouseX >= buttonX and mouseX <= (buttonX + buttonW)) and
               (mouseY >= buttonY and mouseY <= (buttonY + buttonH)) then
                isMinimized = not isMinimized
            else
                if isDragging then
                    isDragging = false
                else
                    isDragging = true
                    dragOffsetX = HuntingLogConfigs.panelX - mouseX
                    dragOffsetY = HuntingLogConfigs.panelY - mouseY
                end
            end
        end
    end
end

-------------------------------------------------------------------------------
-- DRAG PANEL
-------------------------------------------------------------------------------
function HuntingLog.DragPanel()
    if isDragging then
        HuntingLogConfigs.panelX = MousePosX() + dragOffsetX
        HuntingLogConfigs.panelY = MousePosY() + dragOffsetY
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
    InterfaceController.UpdateProc(HuntingLog.UpdateUI)
    InterfaceController.UpdateProc(HuntingLog.CheckHeaderClick)
    InterfaceController.UpdateMouse(HuntingLog.DragPanel)
end

HuntingLog.Init()
