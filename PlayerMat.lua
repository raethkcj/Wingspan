---@diagnostic disable: lowercase-global

local Biome = {
	Forest = true,
	Grassland = true,
	Wetland = true,
}

local zoneBiomes = {}
local biomeNectar = {}

function onLoad()
	Scoresheet = getObjectFromGUID("c7f86b")
    setupZones()
	biomeNectar.playerColor = self.getMemo()
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
		local biome = nil
		for _, tag in ipairs(snap.tags) do
			if tag == "nectar" then
				nectar = true
			elseif Biome[tag] then
				biome = tag
			end
		end
		if nectar and biome then
			spawnZone(snap, biome)
		end
	end
end

function spawnZone(snap, biome)
	spawnObject({
		type = "ScriptingTrigger",
		position = self.positionToWorld(snap.position),
		scale = { 1, 5, 1 },
		sound = false,
		callback_function = function(zone)
			zone.setTags({ "nectar" })
			zoneBiomes[zone.guid] = biome
		end,
	})
end

function destroyZones()
	for zoneGUID in pairs(zoneBiomes) do
		local zone = getObjectFromGUID(zoneGUID)
		if zone then
			zone.destruct()
		end
		zoneBiomes[zoneGUID] = nil
	end
end

function onObjectEnterZone(zone, _object)
	if zoneBiomes[zone.guid] then
		updateZone(zone)
	end
end

function onObjectLeaveZone(zone, _object)
	if zoneBiomes[zone.guid] then
		updateZone(zone)
	end
end

function updateZone(zone)
	local objects = zone.getObjects()
	local count = 0
	for _, object in ipairs(objects) do
		count = count + math.max(object.getQuantity(), 1)
	end
	biomeNectar[zoneBiomes[zone.guid]] = count
	Scoresheet.call("setNectarBiome", biomeNectar)
end
