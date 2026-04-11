local Menu = getObjectFromGUID("cd5f9f")

local foodBags = {
	Invertebrate = getObjectFromGUID("06fe2c"),
	Seed         = getObjectFromGUID("8bac58"),
	Fruit        = getObjectFromGUID("c5a428"),
	Fish         = getObjectFromGUID("6a29be"),
	Rodent       = getObjectFromGUID("676cc2"),
	Nectar       = getObjectFromGUID("407db6"),
}

local playerTrays = {
	White  = getObjectFromGUID("d57317"),
	Green  = getObjectFromGUID("ace029"),
	Blue   = getObjectFromGUID("4ab953"),
	Orange = getObjectFromGUID("5e6632"),
	Red    = getObjectFromGUID("72bafc"),
	Yellow = getObjectFromGUID("944536"),
	Pink   = getObjectFromGUID("69c15e"),
}

local queuedDice = false
local playerColor = nil
local value = nil

function onCollisionExit(collision)
	if collision.collision_object.hasTag("birdfeeder") then
		queuedDice = true
	else
		queuedDice = false
	end
end

function onCollisionEnter(collision)
	if queuedDice and collision.collision_object.hasTag("spentFood") then
		chooseFood()
	end
	queuedDice = false
end

function onPickUp(_playerColor)
	playerColor = _playerColor
	value = self.getRotationValue()
end

function moveToTray(object)
	local position = playerTrays[playerColor].getPosition()
	position[2] = 3
	object.setPositionSmooth(position, false)
	Wait.condition(
		function()
			object.locked = false
			Wait.frames(function()
				if not object.isDestroyed() then
					-- Need to wait 1 frame between unlock and setVelocity
					Menu.call("dumpObjectOnTrayPacked", { object, playerColor })
					Global.call("removeFilteredContainerObject", object)
				end
			end)
		end,
		function()
			return not object.isSmoothMoving()
		end
	)
end

function moveToDice(object)
	object.locked = true
	local position = self.getPosition()
	position[2] = position[2] + 3
	object.setPositionSmooth(position, false, true)
	Wait.condition(
		function()
			moveToTray(object)
		end,
		function()
			return not object.isSmoothMoving()
		end
	)
end

function dealFood(playerColor, food)
	local bag = foodBags[food]
	local position = bag.getPosition()
	position[2] = position[2] + 3
	local object = bag.takeObject({
		index = 1,
		position = position,
		callback_function = moveToDice
	})
	Global.call("setFilteredContainerObject", object)
end

function chooseFood()
	local food1, food2 = value:match("(%w+) / (%w+)")
	if food1 then
		Player[playerColor].showOptionsDialog(
			"Choose which food to gain:",
			{ food1, food2 },
			1,
			function(text, index, playerColor)
				dealFood(playerColor, text)
			end
		)
	else
		dealFood(playerColor, value)
	end
end
