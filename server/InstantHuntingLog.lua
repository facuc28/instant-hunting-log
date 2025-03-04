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
    return player:getLevel() >= 400 and ToBigInt(player:getMasterExperience()) or ToBigInt(player:getExp())
end

function GetPlayerLevel(player)
    return player:getLevel() >= 400 and player:getMasterLevel() or player:getLevel()
end

function GetPlayerNextExp(player)
    local exp = player:getLevel() >= 400 and LevelExperience(player:getMasterLevel() + player:getMasterLevel()) or player:getNextExp()
    return ToBigInt(exp)
end

function UpdateHuntingLog(aIndex)
    local player = User.new(aIndex)

    if not huntingLogs[aIndex] then
        huntingLogs[aIndex] = {
            startTime = os.time(),
            sessionStartTime = os.time(),
            lastExp = GetPlayerExp(player),
            expAccumulator = 0,
            nextLevelSeconds = 0,
            resetLevelSeconds = 0,
            maxLevelSeconds = 0,
            lastUpdate = os.time(),
            totalExpPerMin = 0,
            startLevel = GetPlayerLevel(player),
            lastKillTime = 0,
            isActive = false
        }
    end

    local logData = huntingLogs[aIndex]
    local currentTime = os.time()
    local elapsedTime = currentTime - logData.startTime
    local currentExp = GetPlayerExp(player)
    local nextExpThreshold = GetPlayerNextExp(player)
    local resetLevelExpThreshold = ToBigInt(LevelExperience(350))
    local maxLevelExpThreshold = ToBigInt(LevelExperience(400))
    local lastExpFixed = ToBigInt(logData.lastExp)
    local gainedExp = currentExp - lastExpFixed
    local currentLevel = GetPlayerLevel(player)
    logData.expAccumulator = logData.expAccumulator + gainedExp

    if  logData.lastKillTime ~= 0 and os.time() - logData.lastKillTime >= autoCloseTime then
        ResetLog(aIndex, currentLevel)
        logData = huntingLogs[aIndex]
    elseif logData.lastKillTime ~= 0 then
        logData.isActive = true
    end

    if logData.expAccumulator > 0 and player:getLevel() < 400 then
        local remainingExp = nextExpThreshold - currentExp
        local experience = logData.totalExpPerMin > 0 and logData.totalExpPerMin or logData.expAccumulator
        local remainingMaxLevelExp = maxLevelExpThreshold - currentExp
        local remainingResetLevelExp = resetLevelExpThreshold - currentExp
        
        logData.nextLevelSeconds = math.max(0, math.ceil((remainingExp * 60) / experience))
        logData.resetLevelSeconds = math.max(0, math.ceil((remainingResetLevelExp * 60) / experience))
        logData.maxLevelSeconds = math.max(0, math.ceil((remainingMaxLevelExp * 60) / experience))
    else
        logData.nextLevelSeconds = 0
        logData.resetLevelSeconds = 0
        logData.maxLevelSeconds = 0
    end

    if elapsedTime >= 60 then
        logData.totalExpPerMin = logData.expAccumulator
        logData.expAccumulator = 0
        logData.startTime = os.time()
    end

    logData.lastUpdate = currentTime
    logData.lastExp = currentExp
    
    if logData.isActive then
        local packetName = string.format(HUNTING_LOG_PACKET_NAME, GetNameObject(aIndex))
        local exp = (logData.totalExpPerMin == 0) and logData.expAccumulator or logData.totalExpPerMin
        local gainedLevels = (GetPlayerLevel(player) - logData.startLevel) or 0
        
        CreatePacket(packetName, HUNTING_LOG_PACKET)
        SetDwordPacket(packetName, exp) -- Byte offset 0
        SetDwordPacket(packetName, gainedExp) -- Byte offset 4
        SetDwordPacket(packetName, gainedLevels) -- Byte offset 8
        SetDwordPacket(packetName, logData.nextLevelSeconds) -- Byte offset 12
        SetDwordPacket(packetName, logData.maxLevelSeconds) -- Byte offset 16
        SetDwordPacket(packetName, logData.resetLevelSeconds) -- Byte offset 20
        SetDwordPacket(packetName, logData.sessionStartTime) -- Byte offset 24
        SendPacket(packetName, aIndex)
        ClearPacket(packetName)
    end
end

function ResetLog(aIndex, startLevel)
    if huntingLogs[aIndex] then
        huntingLogs[aIndex] = {
            startTime = os.time(),
            sessionStartTime = os.time(),
            lastExp = ToBigInt(0),
            expAccumulator = 0,
            nextLevelSeconds = 0,
            resetLevelSeconds = 0,
            maxLevelSeconds = 0,
            lastUpdate = os.time(),
            totalExpPerMin = 0,
            startLevel = startLevel,
            lastKillTime = 0,
            isActive = false
        }
    end
end

function OnMonsterKilled(aIndex)
    if huntingLogs[aIndex] then
        huntingLogs[aIndex].lastKillTime = os.time()
        huntingLogs[aIndex].isActive = true
    end
end

GameServerFunctions.MonsterDieGiveItem(UpdateHuntingLog)
GameServerFunctions.MonsterDieGiveItem(OnMonsterKilled)
GameServerFunctions.EnterCharacter(UpdateHuntingLog)
