HUNTING_LOG_PACKET = 0xF3

HuntingLog = {}

local expPerMinute = 0
local lastExpReceived = 0
local levelUpCount = 0
local sessionStartTime = 0
local nextLevelIn = "00:00:00"
local resetLevelIn = "00:00:00"
local maxLevelIn = "00:00:00"
local sessionTime = "00:00:00"
local lastPacketTime = 0
local isHuntingLogVisible = false
local isMinimized = false

local panelX = 850
local panelY = 440
local boxWidth = 150
local boxHeight = 115
local headerHeight = 20

function HuntingLog.Render()
    if not isHuntingLogVisible then
        return
    end

    local posX = panelX
    local posY = panelY
    local textColor = {255, 255, 255, 255}
    local currentHeight = isMinimized and headerHeight or boxHeight

    UIFramework.CreatePanel(
        posX,
        posY,
        boxWidth,
        currentHeight,
        {0.0, 0.0, 0.0, 0.7},
        {0.2, 0.2, 0.2, 0.9},
        "Instant Hunting Log"
    )

    local buttonWidth = math.floor(boxWidth * 0.2)
    local buttonHeight = headerHeight
    local buttonX = posX + boxWidth - buttonWidth
    local buttonY = posY

    local buttonText = isMinimized and "+" or "-"
    UIFramework.CreateTextLabel(
        buttonX + (buttonWidth / 2),
        buttonY + 5,
        buttonText,
        textColor,
        2,
        ALIGN_CENTER
    )

    if not isMinimized then
        local lineHeight = 11
        local contentPosY = posY + headerHeight + lineHeight
        local sessionElapsedTime = os.time() - sessionStartTime
        local sessionHours = math.floor(sessionElapsedTime / 3600)
        local sessionMinutes = math.floor((sessionElapsedTime % 3600) / 60)
        local sessionSeconds = sessionElapsedTime % 60
        sessionTime = string.format("%02d:%02d:%02d", sessionHours, sessionMinutes, sessionSeconds)

        UIFramework.CreateTextLabel(posX + 10, contentPosY, "Farming Time:", textColor)
        UIFramework.CreateTextLabel(posX + 98, contentPosY, sessionTime, textColor, 0, ALIGN_RIGHT)

        UIFramework.CreateTextLabel(posX + 10, contentPosY + lineHeight, "Exp. per minute:", textColor)
        UIFramework.CreateTextLabel(posX + 98, contentPosY + lineHeight, FormatNumber(expPerMinute), textColor, 0, ALIGN_RIGHT)

        UIFramework.CreateTextLabel(posX + 10, contentPosY + lineHeight * 2, "Last exp. received:", textColor)
        UIFramework.CreateTextLabel(posX + 98, contentPosY + lineHeight * 2, FormatNumber(lastExpReceived), textColor, 0, ALIGN_RIGHT)

        UIFramework.CreateTextLabel(posX + 10, contentPosY + lineHeight * 3, "Level Ups:", textColor)
        UIFramework.CreateTextLabel(posX + 98, contentPosY + lineHeight * 3, tostring(levelUpCount), textColor, 0, ALIGN_RIGHT)

        UIFramework.CreateTextLabel(posX + 10, contentPosY + lineHeight * 4, "Next level in:", textColor)
        UIFramework.CreateTextLabel(posX + 98, contentPosY + lineHeight * 4, nextLevelIn, textColor, 0, ALIGN_RIGHT)

        UIFramework.CreateTextLabel(posX + 10, contentPosY + lineHeight * 5, "Reset(350) in:", textColor)
        UIFramework.CreateTextLabel(posX + 98, contentPosY + lineHeight * 5, resetLevelIn, textColor, 0, ALIGN_RIGHT)

        UIFramework.CreateTextLabel(posX + 10, contentPosY + lineHeight * 6, "Max level(400) in:", textColor)
        UIFramework.CreateTextLabel(posX + 98, contentPosY + lineHeight * 6, maxLevelIn, textColor, 0, ALIGN_RIGHT)
    end
end

function HuntingLog.Update(Packet, PacketName)
    if Packet == HUNTING_LOG_PACKET then
        expPerMinute = GetDwordPacket(PacketName, 0) or 0
        local lastGainedExp = GetDwordPacket(PacketName, 4) or 0
        levelUpCount = GetDwordPacket(PacketName, 8) or 0

        local nextLevelTimeRaw = GetDwordPacket(PacketName, 12) or 0
        local maxLevelTimeRaw = GetDwordPacket(PacketName, 16) or 0
        local resetLevelTimeRaw = GetDwordPacket(PacketName, 20) or 0

        sessionStartTime = GetDwordPacket(PacketName, 24) or 0
        lastExpReceived = (lastGainedExp > 0) and lastGainedExp or lastExpReceived

        local days = math.floor(nextLevelTimeRaw / 86400)
        local hours = math.floor(nextLevelTimeRaw / 3600)
        local minutes = math.floor((nextLevelTimeRaw % 3600) / 60)
        local seconds = nextLevelTimeRaw % 60
        nextLevelIn = string.format("%02d:%02d:%02d:%02d", days, hours, minutes, seconds)

        local maxDays = math.floor(maxLevelTimeRaw / 86400)
        local maxHours = math.floor(maxLevelTimeRaw / 3600)
        local maxMinutes = math.floor((maxLevelTimeRaw % 3600) / 60)
        local maxSeconds = maxLevelTimeRaw % 60
        maxLevelIn = string.format("%02d:%02d:%02d:%02d", maxDays, maxHours, maxMinutes, maxSeconds)

        local resetDays = math.floor(resetLevelTimeRaw / 86400)
        local resetHours = math.floor(resetLevelTimeRaw / 3600)
        local resetMinutes = math.floor((resetLevelTimeRaw % 3600) / 60)
        local resetSeconds = resetLevelTimeRaw % 60
        resetLevelIn = string.format("%02d:%02d:%02d:%02d", resetDays, resetHours, resetMinutes, resetSeconds)

        lastPacketTime = os.time()
        isHuntingLogVisible = true
        ClearPacket(Packet)
    end
end

function HuntingLog.UpdateUI()
    if isHuntingLogVisible and (os.time() - lastPacketTime > 15) then
        isHuntingLogVisible = false
    end
end

function HuntingLog.CheckHeaderClick()
    if CheckClickClient() == 1 then
        local mouseX = MousePosX()
        local mouseY = MousePosY()
        local headerX = panelX
        local headerY = panelY
        local headerW = boxWidth
        local headerH = headerHeight

        if mouseX >= headerX and mouseX <= (headerX + headerW) and
           mouseY >= headerY and mouseY <= (headerY + headerH) then

            DisableClickClient()

            local buttonW = math.floor(headerW * 0.2)
            local buttonH = headerH
            local buttonX = headerX + headerW - buttonW
            local buttonY = headerY

            if mouseX >= buttonX and mouseX <= (buttonX + buttonW) and
               mouseY >= buttonY and mouseY <= (buttonY + buttonH) then
                isMinimized = not isMinimized
            end
        end
    end
end

function FormatNumber(value)
    local str = tostring(value)
    if not str:match("^%d+$") then
        return value
    end
    local formatted = str:reverse():gsub("(%d%d%d)", "%1 "):reverse()
    return formatted:match("^%s*(.-)%s*$")
end

function HuntingLog.Init()
    InterfaceController.BeforeMainProc(HuntingLog.Render)
    InterfaceController.ClientProtocol(HuntingLog.Update)
    InterfaceController.UpdateProc(HuntingLog.UpdateUI)
    InterfaceController.UpdateProc(HuntingLog.CheckHeaderClick)
end

HuntingLog.Init()
