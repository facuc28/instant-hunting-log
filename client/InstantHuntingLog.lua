HUNTING_LOG_PACKET = 0xF3

HuntingLog = {}

local expPerMinute = 0
local isHuntingLogVisible = false
local lastExpReceived = 0
local levelUpCount = 0
local nextLevelIn = "00:00:00"
local resetLevelIn = "00:00:00"
local maxLevelIn = "00:00:00"

function HuntingLog.Render()
    if not isHuntingLogVisible then return end

    local screenWidth = ReturnWideScreenX()
    local posX = 900 - screenWidth
    local posY = 400
    local boxWidth = 150
    local boxHeight = 100
    local lineHeight = 10

    UIFramework.CreatePanel(posX, posY, boxWidth, boxHeight, {0.0, 0.0, 0.0, 0.7}, {0.2, 0.2, 0.2, 0.9}, "Instant Hunting Log")

    local contentPosY = posY + lineHeight + 20
    local textColor = {255, 255, 255, 255}

    UIFramework.CreateTextLabel(posX + 10, contentPosY, "Exp. per minute:", textColor)
    UIFramework.CreateTextLabel(posX + 98, contentPosY, string.format("%s", FormatNumber(expPerMinute)), textColor, ALIGN_RIGHT)
    UIFramework.CreateTextLabel(posX + 10, contentPosY + lineHeight, "Last exp. received:", textColor)
    UIFramework.CreateTextLabel(posX + 98, contentPosY + lineHeight, string.format("%s", FormatNumber(lastExpReceived)), textColor, ALIGN_RIGHT)
    UIFramework.CreateTextLabel(posX + 10, contentPosY + lineHeight * 2, "Level Ups:", textColor)
    UIFramework.CreateTextLabel(posX + 98, contentPosY + lineHeight * 2, string.format("%s", levelUpCount), textColor, ALIGN_RIGHT)
    UIFramework.CreateTextLabel(posX + 10, contentPosY + lineHeight * 3, "Next level in:", textColor)
    UIFramework.CreateTextLabel(posX + 98, contentPosY + lineHeight * 3, string.format("%s", nextLevelIn), textColor, ALIGN_RIGHT)
    UIFramework.CreateTextLabel(posX + 10, contentPosY + lineHeight * 4, "Reset(350) in:", textColor)
    UIFramework.CreateTextLabel(posX + 98, contentPosY + lineHeight * 4, string.format("%s", resetLevelIn), textColor, ALIGN_RIGHT)
    UIFramework.CreateTextLabel(posX + 10, contentPosY + lineHeight * 5, "Max level(400) in:", textColor)
    UIFramework.CreateTextLabel(posX + 98, contentPosY + lineHeight * 5, string.format("%s", maxLevelIn), textColor, ALIGN_RIGHT)
end

function HuntingLog.Update(Packet, PacketName)
    if Packet == HUNTING_LOG_PACKET then
        local exp = GetDwordPacket(PacketName, 0) or 0
        local lastGainedExp = GetDwordPacket(PacketName, 4) or 0
        local gainedLevels = GetDwordPacket(PacketName, 8) or 0
        local nextLevelTimeRaw = GetDwordPacket(PacketName, 12) or 0
        local maxLevelTimeRaw = GetDwordPacket(PacketName, 16) or 0
        local resetLevelTimeRaw = GetDwordPacket(PacketName, 20) or 0

        if exp > 0 then
            expPerMinute = exp
            lastExpReceived = lastGainedExp > 0 and lastGainedExp or lastExpReceived
            levelUpCount = gainedLevels

            local days = math.floor(nextLevelTimeRaw / 86400)
            local hours = math.floor(nextLevelTimeRaw / 3600)
            local minutes = math.floor((nextLevelTimeRaw % 3600) / 60)
            local seconds = nextLevelTimeRaw % 60
            nextLevelIn = string.format("%02d:%02d:%02d:%02d", days, hours, minutes, seconds)

            local maxDays = math.floor(maxLevelTimeRaw / 86400)
            local maxHours = math.floor(maxLevelTimeRaw / 3600)
            local maxMinutes = math.floor((maxLevelTimeRaw % 3600) / 60)
            local maxSeconds = nextLevelTimeRaw % 60
            maxLevelIn = string.format("%02d:%02d:%02d:%02d", maxDays, maxHours, maxMinutes, maxSeconds)

            local resetDays = math.floor(resetLevelTimeRaw / 86400)
            local resetHours = math.floor(resetLevelTimeRaw / 3600)
            local resetMinutes = math.floor((resetLevelTimeRaw % 3600) / 60)
            local resetSeconds = resetLevelTimeRaw % 60
            resetLevelIn = string.format("%02d:%02d:%02d:%02d", resetDays, resetHours, resetMinutes, resetSeconds)

            isHuntingLogVisible = true
        else
            isHuntingLogVisible = false
        end

        ClearPacket(Packet)
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
end

HuntingLog.Init()
