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

function onObjectEnterZone(zone, _object)
	updateZone(zone)
end

function onObjectLeaveZone(zone, _object)
	updateZone(zone)
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
				eggs = eggs + 1
				break
			elseif tag == "food" then
				food = food + 1
				break
			elseif tag == "bird" then
				if object.is_face_down then
					tucked = tucked + 1
				end
			end
		end
	end

	Scoresheet.call("setEggPoints", { playerColor, eggs })
	Scoresheet.call("setFoodPoints", { playerColor, food })
	Scoresheet.call("setTuckedPoints", { playerColor, tucked })
end
