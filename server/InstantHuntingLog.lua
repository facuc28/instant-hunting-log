--------------------------------------------------------------------------------
-- InstantHuntingLog.lua
-- Server side LUA Script that implements the Hunting Log feature for KG Emulator
-- Adds Zen per minute tracking and sends data to the client.
--------------------------------------------------------------------------------

HUNTING_LOG_PACKET = 0xF3
HUNTING_LOG_PACKET_NAME = "HUNTING_LOG_PACKET-%s"

local autoCloseTime = 17 -- Close automatically after x seconds of not attacking
local huntingLogs = {}

function ToBigInt(value)
    if value < 0 then
        return value + 4294967296  -- Convert signed 32-bit to unsigned 32-bit
    end
    return value
end

function GetPlayerExp(player)
    if player:getLevel() >= 400 then
        return ToBigInt(player:getMasterExperience())
    else
        return ToBigInt(player:getExp())
    end
end

function GetPlayerLevel(player)
    if player:getLevel() >= 400 then
        return player:getMasterLevel()
    else
        return player:getLevel()
    end
end

function GetPlayerNextExp(player)
    if player:getLevel() < 400 then
        return ToBigInt(player:getNextExp())
    else
        local masterLevel = player:getMasterLevel()
        local nextExp = LevelExperience(400 + masterLevel + 1)
        return ToBigInt(nextExp)
    end
end

function GetPlayerZen(player)
    return ToBigInt(player:getMoney())
end

function UpdateHuntingLog(aIndex)
    local player = User.new(aIndex)

    if not huntingLogs[aIndex] then
        huntingLogs[aIndex] = {
            startTime          = os.time(),
            sessionStartTime   = os.time(),
            lastExp            = GetPlayerExp(player),
            expAccumulator     = 0,
            nextLevelSeconds   = 0,
            resetLevelSeconds  = 0,
            maxLevelSeconds    = 0,
            lastUpdate         = os.time(),
            totalExpPerMin     = 0,
            startLevel         = GetPlayerLevel(player),
            lastKillTime       = 0,
            isActive           = false,
            lastZen            = GetPlayerZen(player),
            zenAccumulator     = 0,
            totalZenPerMin     = 0
        }
    end

    local logData        = huntingLogs[aIndex]
    local currentTime    = os.time()
    local elapsedTime    = currentTime - logData.startTime
    local currentExp     = GetPlayerExp(player)
    local currentZen     = GetPlayerZen(player)

    local nextExpThreshold        = GetPlayerNextExp(player)
    local resetLevelExpThreshold  = ToBigInt(LevelExperience(350))
    local maxLevelExpThreshold    = ToBigInt(LevelExperience(400))

    -- Experience difference
    local gainedExp = currentExp - ToBigInt(logData.lastExp)
    logData.expAccumulator = logData.expAccumulator + gainedExp

    -- Zen difference
    local gainedZen = currentZen - logData.lastZen
    logData.zenAccumulator = logData.zenAccumulator + gainedZen

    local currentLevel = GetPlayerLevel(player)

    -- Check auto-close time
    if logData.lastKillTime ~= 0 and (os.time() - logData.lastKillTime >= autoCloseTime) then
        ResetLog(aIndex, currentLevel)
        logData = huntingLogs[aIndex]  -- re-fetch after reset
    elseif logData.lastKillTime ~= 0 then
        logData.isActive = true
    end

    -- Only compute "time to next level" if not 400 and have some exp
    if logData.expAccumulator > 0 and player:getLevel() < 400 then
        local remainingExp           = nextExpThreshold - currentExp
        local experience             = (logData.totalExpPerMin > 0) and logData.totalExpPerMin or logData.expAccumulator
        local remainingMaxLevelExp   = maxLevelExpThreshold - currentExp
        local remainingResetLevelExp = resetLevelExpThreshold - currentExp

        logData.nextLevelSeconds   = math.max(0, math.ceil((remainingExp           * 60) / experience))
        logData.resetLevelSeconds  = math.max(0, math.ceil((remainingResetLevelExp * 60) / experience))
        logData.maxLevelSeconds    = math.max(0, math.ceil((remainingMaxLevelExp   * 60) / experience))
    else
        logData.nextLevelSeconds   = 0
        logData.resetLevelSeconds  = 0
        logData.maxLevelSeconds    = 0
    end

    -- Every 60s, finalize exp & zen per minute
    if elapsedTime >= 60 then
        logData.totalExpPerMin = logData.expAccumulator
        logData.expAccumulator = 0
        logData.totalZenPerMin = logData.zenAccumulator
        logData.zenAccumulator = 0
        logData.startTime = os.time()
    end

    logData.lastUpdate = currentTime
    logData.lastExp    = currentExp
    logData.lastZen    = currentZen

    if logData.isActive then
        local packetName   = string.format(HUNTING_LOG_PACKET_NAME, GetNameObject(aIndex))
        local expPerMin    = (logData.totalExpPerMin == 0) and logData.expAccumulator or logData.totalExpPerMin
        local gainedLevels = (GetPlayerLevel(player) - logData.startLevel) or 0
        local zenPerMin    = (logData.totalZenPerMin == 0) and logData.zenAccumulator or logData.totalZenPerMin

        CreatePacket(packetName, HUNTING_LOG_PACKET)
        -- Offsets:
        --  0  -> expPerMin
        --  4  -> gainedExp
        --  8  -> gainedLevels
        -- 12  -> nextLevelSeconds
        -- 16  -> maxLevelSeconds
        -- 20  -> resetLevelSeconds
        -- 24  -> sessionStartTime
        -- 28  -> zenPerMin
        -- 32  -> gainedZen
        SetDwordPacket(packetName, expPerMin)               -- offset 0
        SetDwordPacket(packetName, gainedExp)               -- offset 4
        SetDwordPacket(packetName, gainedLevels)            -- offset 8
        SetDwordPacket(packetName, logData.nextLevelSeconds)-- offset 12
        SetDwordPacket(packetName, logData.maxLevelSeconds) -- offset 16
        SetDwordPacket(packetName, logData.resetLevelSeconds)--offset 20
        SetDwordPacket(packetName, logData.sessionStartTime)-- offset 24
        SetDwordPacket(packetName, zenPerMin)               -- offset 28 
        SetDwordPacket(packetName, gainedZen)               -- offset 32 

        SendPacket(packetName, aIndex)
        ClearPacket(packetName)
    end
end

function ResetLog(aIndex, startLevel)
    if huntingLogs[aIndex] then
        huntingLogs[aIndex] = {
            startTime          = os.time(),
            sessionStartTime   = os.time(),
            lastExp            = ToBigInt(0),
            expAccumulator     = 0,
            nextLevelSeconds   = 0,
            resetLevelSeconds  = 0,
            maxLevelSeconds    = 0,
            lastUpdate         = os.time(),
            totalExpPerMin     = 0,
            startLevel         = startLevel,
            lastKillTime       = 0,
            isActive           = false,
            lastZen            = 0,
            zenAccumulator     = 0,
            totalZenPerMin     = 0
        }
    end
end

function OnMonsterKilled(aIndex)
    if huntingLogs[aIndex] then
        huntingLogs[aIndex].lastKillTime = os.time()
        huntingLogs[aIndex].isActive     = true
    end
end

GameServerFunctions.MonsterDieGiveItem(UpdateHuntingLog)
GameServerFunctions.MonsterDieGiveItem(OnMonsterKilled)
GameServerFunctions.EnterCharacter(UpdateHuntingLog)
