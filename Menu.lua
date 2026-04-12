local expansionBags = {
	Core = getObjectFromGUID("64aee4"),
	ee   = getObjectFromGUID("cf00dc"),
	oe   = getObjectFromGUID("de7d9d"),
	as   = getObjectFromGUID("2d8132"),
	am   = getObjectFromGUID("35528a"),
}

local foodBags = {
	invertebrate = getObjectFromGUID("06fe2c"),
	seed         = getObjectFromGUID("8bac58"),
	fruit        = getObjectFromGUID("c5a428"),
	fish         = getObjectFromGUID("6a29be"),
	rodent       = getObjectFromGUID("676cc2"),
	nectar       = getObjectFromGUID("407db6"),
}
foodBags.nectar.interactable = false

local enabledExpansions = {
	Core = true,
}

local Mode = {
	Flock    = 0,
	Standard = 1,
	Duet     = 2,
	Automa   = 3,
}

local currentMode = Mode.Standard

local birdDeck = getObjectFromGUID("6a8307")
local bonusDeck = getObjectFromGUID("a71713")
local goalDeck = getObjectFromGUID("dc9bc7")
local decks = { birdDeck, bonusDeck, goalDeck }

local cardRot = { 0, 0, 180 }

local nectarBagPos = { -3.98, 0.94, 6.60 }

local hbirdDeck = "295346"
local hbirdDeckPos = { -5.33, 1.17, 1.44 }
local hbirdGarden = "59dd5b"
local hbirdGardenPos = { 0.80, 1.06, 2.79 }
local hbirdTrackSource = getObjectFromGUID("a706e1")
hbirdTrackSource.interactable = false
local hbirdTracks = {}

local playerMats = {
	White  = getObjectFromGUID("a4346b"),
	Green  = getObjectFromGUID("c92aff"),
	Blue   = getObjectFromGUID("30fc97"),
	Orange = getObjectFromGUID("e86a62"),
	Red    = getObjectFromGUID("a1dbbe"),
	Yellow = getObjectFromGUID("08d8e4"),
	Pink   = getObjectFromGUID("86b0b0"),
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

local playerDecks = {}

local diceTrays = {
	Standard = getObjectFromGUID("418789"),
	Flock    = getObjectFromGUID("887839"),
}

local dice = {
	Standard = "e6d7ac",
	Oceania  = "d416c7",
}

local DiceState = {
	Standard     = 1,
	Oceania      = 2,
	Flock        = 3,
	OceaniaFlock = 4,
}

local currentDiceState = DiceState.Standard

function onExpansionToggle(_player, value, expansion)
	if value == "True" then
		enableExpansion(expansion)
	else
		disableExpansion(expansion)
	end

	setPlayerMatStates()
	setDiceStates()
end

function onModeChanged(_player, modeString)
	local mode = tonumber(modeString)
	currentMode = mode
	setGoalBoardState(mode)
	updateTable(mode)
	setFlockComponentState(mode)
	setDiceStates()
	-- TODO Duet Tokens: Prefer dealing to first two seated players, then choose defaults
end

function onPlayerChangeColor()
	updateTable(currentMode)
end

function enableExpansion(expansion)
	enabledExpansions[expansion] = true
	local bag = expansionBags[expansion]
	local objects = bag.getObjects()
	for _, object in ipairs(objects) do
		for _, tag in ipairs(object.tags) do
			if tag == "bird" then
				moveContainerObject(bag, object.guid, birdDeck)
			elseif tag == "bonus" then
				moveContainerObject(bag, object.guid, bonusDeck)
			elseif tag == "goal" then
				moveContainerObject(bag, object.guid, goalDeck)
			end

			if expansion == "am" and tag == "hummingbird" then
				takeContainerObject(bag, object.guid, hbirdDeckPos)
			end
		end
		if expansion == "am" and object.guid == hbirdGarden then
			takeContainerObject(bag, hbirdGarden, hbirdGardenPos)
		end
	end

	if expansion == "oe" or expansion == "am" then
		foodBags.nectar.setPosition(nectarBagPos)
		foodBags.nectar.interactable = true
	end

	if expansion == "am" then
		cloneHummingbirdTracks()
	end
end

function disableExpansion(expansion)
	enabledExpansions[expansion] = nil
	local bag = expansionBags[expansion]
	for _, deck in ipairs(decks) do
		local objects = deck.getObjects()
		for _, object in ipairs(objects) do
			for _, tag in ipairs(object.tags) do
				if tag == expansion then
					moveContainerObject(deck, object.guid, bag)
				end
			end
		end
	end

	if not (enabledExpansions["oe"] or enabledExpansions["am"]) then
		foodBags.nectar.setPosition({ 0, -5, 0 })
		foodBags.nectar.interactable = false
	end

	if expansion == "oe" then
		-- destruct nectar
	elseif expansion == "am" then
		bag.putObject(getObjectFromGUID(hbirdDeck), 1)
		bag.putObject(getObjectFromGUID(hbirdGarden), 1)
		deleteHummingbirdTracks()
	end
end

function setPlayerMatStates()
	local playerMatState = 1
	if enabledExpansions["am"] and enabledExpansions["oe"] then
		playerMatState = 4
	elseif enabledExpansions["am"] then
		playerMatState = 3
	elseif enabledExpansions["oe"] then
		playerMatState = 2
	end
	for player, playerMat in pairs(playerMats) do
		local states = playerMat.getStates()
		local newStateGUID = playerMat.guid
		for _, state in ipairs(states) do
			if state.id == playerMatState then
				newStateGUID = state.guid
				playerMat.setState(playerMatState)
				playerMats[player] = getObjectFromGUID(newStateGUID)
				break
			end
		end
	end
end

function dumpOnStandardTray(object)
	Wait.frames(function()
		dumpObjectOnTray(object, diceTrays.Standard)
	end, 4)
end

function dumpOnFlockTray(object)
	Wait.frames(function()
		dumpObjectOnTray(object, diceTrays.Flock)
	end, 4)
end

function setDiceStates()
	local state = DiceState.Standard
	if currentMode == Mode.Flock and enabledExpansions["oe"] then
		state = DiceState.OceaniaFlock
	elseif currentMode == Mode.Flock then
		state = DiceState.Flock
	elseif enabledExpansions["oe"] then
		state = DiceState.Oceania
	end

	if state ~= currentDiceState then
		for j, dice in ipairs(getObjectsWithTag("Dice")) do
			dice.destruct()
		end
		if state == DiceState.Standard then
			for i = 1, 5 do
				spawnContainerObject(expansionBags.Core, dice.Standard, dumpOnStandardTray)
			end
		elseif state == DiceState.Oceania then
			for i = 1, 5 do
				spawnContainerObject(expansionBags.oe, dice.Oceania, dumpOnStandardTray)
			end
		elseif state == DiceState.Flock then
			for i = 1, 5 do
				spawnContainerObject(expansionBags.Core, dice.Standard, dumpOnStandardTray)
				spawnContainerObject(expansionBags.Core, dice.Standard, dumpOnFlockTray)
			end
		elseif state == DiceState.OceaniaFlock then
			for i = 1, 3 do
				spawnContainerObject(expansionBags.Core, dice.Standard, dumpOnStandardTray)
				spawnContainerObject(expansionBags.Core, dice.Standard, dumpOnFlockTray)
			end
			for i = 1, 2 do
				spawnContainerObject(expansionBags.oe, dice.Oceania, dumpOnStandardTray)
				spawnContainerObject(expansionBags.oe, dice.Oceania, dumpOnFlockTray)
			end
		end
	end

	currentDiceState = state
end

function moveContainerObject(oldContainer, guid, newContainer)
	oldContainer.takeObject({
		guid = guid,
		rotation = cardRot,
		smooth = false,
		callback_function = function(object)
			newContainer.putObject(object, 1)
		end,
	})
end

local unlockedObjects = {
	Card = true,
	Deck = true,
	Token = true,
}

function takeContainerObject(container, guid, position)
	container.takeObject({
		guid = guid,
		position = position,
		rotation = cardRot,
		smooth = false,
		callback_function = function(object)
			if not unlockedObjects[object.type] then
				object.locked = true
			end
		end,
	})
end

function cloneHummingbirdTracks()
	for _, playerMat in pairs(playerMats) do
		local rotation = playerMat.getRotation()
		local scale = playerMat.getScale()
		local position = playerMat.positionToWorld({ -9.35 / scale[1], 4.96, 1.75 / scale[3] })
		local hbirdTrack = hbirdTrackSource.clone({ position = position })
		hbirdTrack.setRotation(rotation)
		hbirdTrack.removeAttachments()
		table.insert(hbirdTracks, hbirdTrack)
	end
end

function deleteHummingbirdTracks()
	for i, hbirdTrack in ipairs(hbirdTracks) do
		hbirdTrack.destruct()
		hbirdTracks[i] = nil
	end
	for _, hbirdToken in ipairs(getObjectsWithAnyTags({ "bee", "brilliant", "emerald", "mango", "topaz" })) do
		hbirdToken.destruct()
	end
end

local goalBoardModeStates = {
	[Mode.Flock] = 3,
	[Mode.Standard] = 2,
	[Mode.Duet] = 4,
	[Mode.Automa] = 2,
}

local goalBoard = getObjectFromGUID("208915")

function setGoalBoardState(mode)
	local goalBoardState = goalBoardModeStates[mode]
	local states = goalBoard.getStates()
	local newStateGUID = goalBoard.guid
	for _, state in ipairs(states) do
		if state.id == goalBoardState then
			newStateGUID = state.guid
			goalBoard.setState(goalBoardState)
			goalBoard = getObjectFromGUID(newStateGUID)
			break
		end
	end
end

local Table = {
	None = {},
	Six = {
		{
			name = "table6",
			url = "https://steamusercontent-a.akamaihd.net/ugc/9698628281126128536/00C796CA38660F6D474CEA7EF5D301300C8387AE",
			position = { 0, 3.046875, 0 },
			rotation = { 90, 0, 0 },
			scale = { 66.85, 39.9, 1 },
		}
	},
	Seven = {
		{
			name = "table7",
			url = "https://steamusercontent-a.akamaihd.net/ugc/14142098684572174503/42720D7F2D2CD7EA369A3190F99E57B410627A50",
			position = { 0, 3.046875, 0 },
			rotation = { 90, 0, 0 },
			scale = { 66.85, 39.9, 1 },
		}
	},
}

local currentTable = Table.None

function updateTable(mode)
	local newTable = Table.None
	if mode == Mode.Flock then
		local numPlayers = #getSeatedPlayers()
		newTable = numPlayers > 6 and Table.Seven or Table.Six
	end
	if newTable ~= currentTable then
		Tables.getTableObject().setDecals(newTable)
		currentTable = newTable
	end
end

local flockComponents = {
	getObjectFromGUID("166ce5"), -- Card Mat
	getObjectFromGUID("887839"), -- Birdfeeder
	getObjectFromGUID("84cebc"), -- Spent Food Dice
}

for _, component in ipairs(flockComponents) do
	component.interactable = false
end

local shownHeight = 0.96
local hiddenHeight = -5

function setFlockComponentState(mode)
	for _, component in ipairs(flockComponents) do
		local position = component.getPosition()
		position[2] = mode == Mode.Flock and shownHeight or hiddenHeight
		component.setPosition(position)
		component.interactable = mode == Mode.Flock
	end
end

function startGame()
	local xml = self.UI.getXmlTable()
	disableInputs(xml)
	self.UI.setXmlTable(xml)
	birdDeck.shuffle()
	bonusDeck.shuffle()
	assignDecks()
	for playerColor, decks in pairs(playerDecks) do
		decks.birdDeck.deal(5, playerColor)
		decks.bonusDeck.deal(2, playerColor)
	end
	foodBags.invertebrate.deal(1)
	foodBags.seed.deal(1)
	foodBags.fruit.deal(1)
	foodBags.fish.deal(1)
	foodBags.rodent.deal(1)
	chooseInHand("start", 6, 6, "Choose a mix of 5 birds and food to discard. Also choose 1 bonus to discard.")
end

local flockDeckPos = {
	birdDeck = { 26.93, 2, 2.56 },
	bonusDeck = { 13.72, 2, 2.52 },
}

local standardDecks = {
	birdDeck = birdDeck,
	bonusDeck = bonusDeck,
	birdDiscardPos = { -3.69, 2, -2.48 },
	bonusDiscardPos = { 1.70, 2, -2.50 },
}
local flockDecks = {
	birdDiscardPos = { 16.52, 2, 2.49 },
	bonusDiscardPos = { 11.13, 2, 2.51 },
}

function assignDecks()
	local players = getSeatedPlayers()
	for _, playerColor in ipairs(players) do
		playerDecks[playerColor] = standardDecks
	end

	if currentMode == Mode.Flock then
		local birdDecks = birdDeck.split(2)
		flockDecks.birdDeck = birdDecks[1]
		flockDecks.birdDeck.setPositionSmooth(flockDeckPos.birdDeck, false)
		flockDecks.birdDeck.setRotation(cardRot)
		local bonusDecks = bonusDeck.split(2)
		flockDecks.bonusDeck = bonusDecks[1]
		flockDecks.bonusDeck.setPositionSmooth(flockDeckPos.bonusDeck, false)
		flockDecks.bonusDeck.setRotation(cardRot)

		playerDecks.Orange = playerDecks.Orange and flockDecks or nil
		playerDecks.Red = playerDecks.Red and flockDecks or nil
		if #players == 6 then
			playerDecks.Yellow = playerDecks.Yellow and flockDecks or nil
			playerDecks.Pink = playerDecks.Pink and flockDecks or nil
		else
			playerDecks.Blue = playerDecks.Blue and flockDecks or nil
		end
	end
end

function disableInputs(parent)
	for _, element in ipairs(parent) do
		if element.tag == "Button" or element.tag == "ToggleButton" then
			element.attributes.interactable = "false"
		elseif element.children then
			disableInputs(element.children)
		end
	end
end

function onPlayerHandChoice(playerColor, label, objects)
	local valid, info = validateChoice(objects)
	if valid then
		discardChoice(playerColor, objects)
		dumpFoodOnTray(playerColor)
		if enabledExpansions["oe"] then
			foodBags.nectar.takeObject({
				index = 1,
				callback_function = function(object)
					dumpObjectOnTray(object, playerColor)
				end
			})
		end
	else
		Player[playerColor].showInfoDialog(info)
		chooseInHand("start", 6, 6, "Choose a mix of 5 birds and food to discard. Also choose 1 bonus to discard.", { playerColor })
	end
end

function validateChoice(objects)
	local birds = 0
	local food = 0
	local bonuses = 0
	for _, object in ipairs(objects) do
		for _, tag in ipairs(object.getTags()) do
			if tag == "bird" then
				birds = birds + 1
			elseif tag == "bonus" then
				bonuses = bonuses + 1
			elseif tag == "food" then
				food = food + 1
			end
		end
	end

	if birds + food == 5 and bonuses == 1 then
		return true
	else
		return false, string.format("You chose %d birds, %d food, and %d bonuses. Please choose carefully!", birds, food, bonuses)
	end
end

function discardChoice(playerColor, objects)
	local decks = playerDecks[playerColor]
	for _, object in ipairs(objects) do
		for _, tag in ipairs(object.getTags()) do
			if tag == "bird" then
				discardCard(object, decks, "birdDiscard", decks.birdDiscardPos)
				break
			elseif tag == "bonus" then
				discardCard(object, decks, "bonusDiscard", decks.bonusDiscardPos)
				break
			elseif tag == "food" then
				object.destruct()
			end
		end
	end
end

local queuedDiscards = {}

function discardCard(card, decks, deckName, deckPos)
	if decks[deckName] then
		decks[deckName].putObject(card)
	else
		card.setPosition(deckPos)
		queuedDiscards[card] = { decks, deckName }
	end
end

function onObjectEnterContainer(container, object)
	if queuedDiscards[object] then
		local deckInfo = queuedDiscards[object]
		local decks, deckName = unpack(deckInfo)
		decks[deckName] = container
		queuedDiscards[container] = deckInfo
		queuedDiscards[object] = nil
	end
end

do
	local offset = 0

	function dumpObjectOnTray(object, tray)
		object.use_hands = false
		local position = tray.getPosition()
		position[2] = 3 + offset
		offset = (offset + 1) % 5
		object.setPosition(position)
		-- Random position on a donut with radii in [min, max]
		local minRadius = 2
		local maxRadius = 5
		local radius = math.random() * (maxRadius - minRadius) + minRadius
		local angle = math.random() * 2 * math.pi
		local x = radius * math.cos(angle)
		local z = radius * math.sin(angle)
		object.setVelocity({ x, 0, z })
	end
end

function dumpObjectOnPlayerTray(object, playerColor)
	dumpObjectOnTray(object, playerTrays[playerColor])
end

-- Packed alias so other scripts can call()
function dumpObjectOnPlayerTrayPacked(params)
	dumpObjectOnPlayerTray(unpack(params))
end

function dumpFoodOnTray(playerColor)
	local hand = Player[playerColor].getHandObjects()
	for _, object in ipairs(hand) do
		if object.hasTag("food") then
			dumpObjectOnTray(object, playerColor)
		end
	end
end

do
	local offset = 0

	function spawnContainerObject(container, guid, callback)
		local containerData = container.getData()
		for _, objectData in ipairs(containerData.ContainedObjects) do
			if objectData.GUID == guid then
				local position = container.getPosition()
				position[2] = position[2] + 3 + offset
				offset = (offset + 1) % 5
				Wait.frames(
					function()
						spawnObjectData({
							data = objectData,
							position = position,
							callback_function = callback,
						})
					end
				)
			end
		end
	end
end
