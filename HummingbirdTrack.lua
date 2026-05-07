---@diagnostic disable: lowercase-global

local hbirdGroupIndices = {
    bee       = 1,
    brilliant = 2,
    emerald   = 3,
    mango     = 4,
    topaz     = 5,
}

local decalStates = {
    { 0, 3, 2, 3, 1 },
    { 1, 0, 3, 3, 2 },
    { 3, 1, 0, 2, 3 },
    { 2, 3, 1, 0, 3 },
    { 3, 2, 3, 1, 0 },
}

local zonePoints = {}
local zoneTokens = {}

function onLoad()
	Scoresheet = getObjectFromGUID("c7f86b")
    setupSnaps()
end

function setupSnaps()
    local stateIndex = math.random(#decalStates)
    local state = decalStates[stateIndex]
    self.setDecals({})

	local snaps = self.getSnapPoints()
	for _, snap in ipairs(snaps) do
        setupDecal(snap, state)
        setupZone(snap)
	end
end

function setupDecal(snap, state)
    local groupIndex, points
    for _, tag in ipairs(snap.tags) do
        if hbirdGroupIndices[tag] then
            groupIndex = hbirdGroupIndices[tag]
        else
            local pointString = tag:match("hbird(%d+)")
            if pointString then
                points = tonumber(pointString)
            end
        end
    end
    if groupIndex and points then
        local points1 = state[groupIndex]
        local points2 = points1 * 2 + 4
        if points == points1 or points == points2 then
            spawnDecal(snap)
        end
    end
end

function spawnDecal(snap)
    local position = snap.position
    position[2] = position[2] + 0.01
    self.addDecal({
        name = "Hummingbird",
        url = "https://steamusercontent-a.akamaihd.net/ugc/11970298409072266643/45CF1282FA1157BD49187D7C7F5E317AB8BE2410/",
        position = position,
        rotation = { 90, 180, 0 },
        scale = { 0.14, 0.14, 1 },
    })
end

function setupZone(snap)
    local group, points, negative
    for _, tag in ipairs(snap.tags) do
        if hbirdGroupIndices[tag] then
            group = tag
        else
            negative, points = tag:match("hbird(%a*)(%d+)")
            if points then
                local sign = negative == "Minus" and -1 or 1
                points = sign * tonumber(points)
            end
        end
    end
    if group and points then
        spawnZone(snap, group, points)
    end
end

function spawnZone(snap, group, points)
	spawnObject({
		type = "ScriptingTrigger",
		position = self.positionToWorld(snap.position),
		scale = { 0.5, 0.5, 0.5 },
		sound = false,
		callback_function = function(zone)
			zone.setTags({ group })
			zonePoints[zone.guid] = points
		end,
	})
end

function onObjectEnterZone(zone, _object)
	if zonePoints[zone.guid] then
		updateZone(zone)
	end
end

function onObjectLeaveZone(zone, _object)
	if zonePoints[zone.guid] then
		updateZone(zone)
	end
end

function updateZone(zone)
	local playerColor = self.getMemo()
	local players = getSeatedPlayers()
	for _, color in ipairs(players) do
		if color == playerColor then
            zoneTokens[zone.guid] = #zone.getObjects()
            updateHummingbirdPoints(playerColor)
			break
		end
	end
end

function updateHummingbirdPoints(playerColor)
    local points = 0
	for zoneGUID, tokens in pairs(zoneTokens) do
        if tokens > 0 then
            points = points + zonePoints[zoneGUID]
        end
	end
	Scoresheet.call("setHummingbirdPoints", { playerColor, points })
end
