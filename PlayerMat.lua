local playerMatZones = {}

function onLoad()
	Scoresheet = getObjectFromGUID("c7f86b")

	playerMatZones[getObjectFromGUID("d77eaf")] = "White"
	playerMatZones[getObjectFromGUID("2ada1e")] = "Green"
	playerMatZones[getObjectFromGUID("714d4f")] = "Blue"
	playerMatZones[getObjectFromGUID("d21068")] = "Orange"
	playerMatZones[getObjectFromGUID("cc8b42")] = "Red"
	playerMatZones[getObjectFromGUID("1f6df3")] = "Yellow"
	playerMatZones[getObjectFromGUID("e902d0")] = "Pink"
end

function onObjectEnterZone(zone, object)
	waitUntilRestingOrDestroyed(zone, object)
end

function onObjectLeaveZone(zone, object)
	waitUntilRestingOrDestroyed(zone, object)
end

function waitUntilRestingOrDestroyed(zone, object)
	Wait.condition(
		function()
			updateZone(zone)
		end,
		function()
			return object.isDestroyed() or object.resting
		end
	)
end

function updateZone(zone)
	local playerColor = playerMatZones[zone]
	if not playerColor then return end

	local eggs = 0
	local food = 0
	local tucked = 0

	local objects = zone.getObjects()
	for _, object in ipairs(objects) do
		for _, tag in ipairs(object.getTags()) do
			if tag == "egg" then
				local count = math.max(object.getQuantity(), 1)
				eggs = eggs + count
				break
			elseif tag == "food" then
				local count = math.max(object.getQuantity(), 1)
				food = food + count
				break
			elseif tag == "bird" then
				if object.is_face_down then
					local count = math.max(object.getQuantity(), 1)
					tucked = tucked + count
				end
			end
		end
	end

	Scoresheet.call("setEggPoints", { playerColor, eggs })
	Scoresheet.call("setFoodPoints", { playerColor, food })
	Scoresheet.call("setTuckedPoints", { playerColor, tucked })
end
