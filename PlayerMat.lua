---@diagnostic disable: lowercase-global

local Habitat = {
	forest = true,
	grassland = true,
	wetland = true,
}

local zoneHabitats = {}
local habitatNectar = {}

function onLoad()
	Scoresheet = getObjectFromGUID("c7f86b")
    setupZones()
	habitatNectar.playerColor = self.getMemo()
end

function tryStateChange(_newStateIndex, _playerColor)
	destroyZones()
end

function onStateChange(_oldGUID)
	setupZones()
end

function setupZones()
	local snaps = self.getSnapPoints()
	for _, snap in ipairs(snaps) do
		local nectar = nil
		local habitat = nil
		for _, tag in ipairs(snap.tags) do
			if tag == "nectar" then
				nectar = true
			elseif Habitat[tag] then
				habitat = tag
			end
		end
		if nectar and habitat then
			spawnZone(snap, habitat)
		end
	end
end

function spawnZone(snap, habitat)
	spawnObject({
		type = "ScriptingTrigger",
		position = self.positionToWorld(snap.position),
		scale = { 1, 5, 1 },
		sound = false,
		callback_function = function(zone)
			zone.setTags({ "nectar" })
			zoneHabitats[zone.guid] = habitat
		end,
	})
end

function destroyZones()
	for zoneGUID in pairs(zoneHabitats) do
		local zone = getObjectFromGUID(zoneGUID)
		if zone then
			zone.destruct()
		end
		zoneHabitats[zoneGUID] = nil
	end
end

function onObjectEnterZone(zone, _object)
	if zoneHabitats[zone.guid] then
		updateZone(zone)
	end
end

function onObjectLeaveZone(zone, _object)
	if zoneHabitats[zone.guid] then
		updateZone(zone)
	end
end

function updateZone(zone)
	local objects = zone.getObjects()
	local count = 0
	for _, object in ipairs(objects) do
		count = count + math.max(object.getQuantity(), 1)
	end
	habitatNectar[zoneHabitats[zone.guid]] = count
	Scoresheet.call("setHabitatNectar", habitatNectar)
end
