local expansionBags = {
	Core = getObjectFromGUID("64aee4"),
	ee   = getObjectFromGUID("cf00dc"),
	oe   = getObjectFromGUID("de7d9d"),
	as   = getObjectFromGUID("2d8132"),
	am   = getObjectFromGUID("35528a"),
}

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

function onExpansionToggle(_player, value, expansion)
	if value == "True" then
		enableExpansion(expansion)
	else
		disableExpansion(expansion)
	end

	setPlayerMatStates()

	-- TODO: Oceania vs core dice
end

function onModeChanged(_player, modeString)
	local mode = tonumber(modeString)
	currentMode = mode
	setGoalBoardState(mode)
	updateTable(mode)
	setFlockComponentState(mode)
	-- TODO:
	-- Oceania vs core dice
	-- Duet Tokens: Prefer dealing to first two seated players, then choose defaults
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
				spawnContainerObject(bag, object.guid, hbirdDeckPos)
			end

			if expansion == "am" and object.guid == hbirdGarden then
				spawnContainerObject(bag, hbirdGarden, hbirdGardenPos)
			end
		end
	end

	if expansion == "am" then
		cloneHummingbirdTracks()
	end

	-- TODO:
	-- Deal Nectar if Oceania
	-- Hide/show nectar bag
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

	if expansion == "am" then
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

function spawnContainerObject(container, guid, position)
	container.takeObject({
		guid = guid,
		position = position,
		rotation = cardRot,
		smooth = false,
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
