local goalBoardStates = {
	["cca07e"] = true,
	["208915"] = true,
	["719926"] = true,
	["f0f32f"] = true,
}

local zonePoints = {}
local zoneCubes = {}

function onLoad()
	Scoresheet = getObjectFromGUID("c7f86b")

	for goalBoardGUID in pairs(goalBoardStates) do
		local goalBoard = getObjectFromGUID(goalBoardGUID)
		if goalBoard then
			setupZones(goalBoard)
		end
	end
end

function tryObjectStateChange(object, _newStateIndex, _playerColor)
	if goalBoardStates[object.guid] then
		destroyZones()
	end
end

function onObjectStateChange(object, oldGUID)
	if goalBoardStates[oldGUID] then
		setupZones(object)
	end
end

function setupZones(goalBoard)
	local snaps = goalBoard.getSnapPoints()
	for _, snap in ipairs(snaps) do
		local action = nil
		local points = nil
		for _, tag in ipairs(snap.tags) do
			if tag == "action" then
				action = true
			else
				local value = tonumber(tag:match("%d+$"))
				if value then
					points = value
				end
			end
		end
		if action and points then
			spawnZone(goalBoard, snap, points)
		end
	end
end

function spawnZone(goalBoard, snap, points)
	spawnObject({
		type = "ScriptingTrigger",
		position = goalBoard.positionToWorld(snap.position),
		scale = { 1, 5, 1 },
		sound = false,
		callback_function = function(zone)
			zone.setTags({ "action" })
			zonePoints[zone.guid] = points
		end,
	})
end

function destroyZones()
	for zoneGUID in pairs(zonePoints) do
		local zone = getObjectFromGUID(zoneGUID)
		if zone then
			zone.destruct()
		end
		zonePoints[zoneGUID] = nil
	end
end

function onObjectEnterZone(zone, _object)
	local points = zonePoints[zone.guid]
	if points then
		updateZone(zone)
	end
end

function onObjectLeaveZone(zone, _object)
	local points = zonePoints[zone.guid]
	if points then
		updateZone(zone)
	end
end

function updateZone(zone)
	local objects = zone.getObjects()
	zoneCubes[zone.guid] = #objects > 0 and objects or nil
	updateGoalPoints()
end

local colors = {
	White = true,
	Green = true,
	Blue = true,
	Orange = true,
	Red = true,
	Yellow = true,
	Pink = true,
}

function updateGoalPoints()
	local goalPoints = {}
	for zoneGUID, cubes in pairs(zoneCubes) do
		for _, cube in ipairs(cubes) do
			local tags = cube.getTags()
			for _, tag in ipairs(tags) do
				if colors[tag] then
					goalPoints[tag] = (goalPoints[tag] or 0) + zonePoints[zoneGUID]
				end
			end
		end
	end
	Scoresheet.call("setGoalPoints", goalPoints)
end
