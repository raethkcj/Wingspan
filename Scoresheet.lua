---@diagnostic disable: lowercase-global

local UI = self.UI
local scoresheetXml
local rows = {}
local playerPoints = {}
local playerHabitatNectar = {}

local nextInputID = 1
local inputIDs = {}

function onLoad()
	reloadXml()
end

function reloadXml()
	scoresheetXml = UI.getXmlTable()
	local scoresheet = scoresheetXml[2].children[1]

	for _, child in ipairs(scoresheet.children) do
		if child.tag == "Row" then
			rows[child.attributes.id] = child
		end
	end

	initializeScoresheet()
end

local xmlNeedsUpdate = false

Wait.time(
	function()
		if xmlNeedsUpdate then
			xmlNeedsUpdate = false
			UI.setXmlTable(scoresheetXml)
		end
	end,
	1,
	-1
)

function onPlayerChangeColor()
	initializeScoresheet()
end

function initializeScoresheet()
	for k in pairs(playerPoints) do
		playerPoints[k] = nil
	end
	local players = Player.getPlayers()
	for rowName, row in pairs(rows) do
		for i, player in ipairs(players) do
			if player.color ~= "Grey" and player.color ~= "Black" then
				local cell = row.children[i]
				cell.attributes.playerColor = player.color
				local initializer = rowInitializers[rowName]
				if initializer then
					local points = initializer(cell, player)
					playerPoints[player.color][rowName] = points
				end
			end
		end
	end
	xmlNeedsUpdate = true
end

function initializeName(cell, player)
	cell.children[1].value = player.steam_name
	cell.attributes.color = player.color
	playerPoints[player.color] = {}
end

function initializeBonusPoints(cell, player)
	local id = newOnPointsInput(player, "bonuses")
	cell.children[1].attributes.id = id
	local points = tonumber(cell.children[1].value) or 0
	return points
end

function initializeDuetPoints(cell, player)
	local id = newOnPointsInput(player, "duet")
	cell.children[1].attributes.id = id
	local points = tonumber(cell.children[1].value) or 0
	return points
end

function initializeZero(cell, player)
	for _, child in ipairs(cell.children) do
		child.attributes.value = 0
		child.value = 0
	end
end

function setTotalPoints(playerColor)
	local points = 0
	for rowName, rowPoints in pairs(playerPoints[playerColor]) do
		if rowName ~= "total" then
			points = points + rowPoints
		end
	end
	setCellPoints("total", playerColor, points)
end

rowInitializers = {
	names   = initializeName,
	birds   = initializeZero,
	bonuses = initializeBonusPoints,
	goals   = initializeZero,
	eggs    = initializeZero,
	food    = initializeZero,
	tucked  = initializeZero,
	duet    = initializeDuetPoints,
	nectar  = initializeZero,
	hbird   = initializeZero,
	total   = initializeZero,
}

function onPointsInput(_player, value, idString)
	local id = tonumber(idString)
	if idString then
		UI.setAttribute(idString, "text", value)
		UI.setValue(idString, value)
		local func = inputIDs[id]
		if func then
			func(value)
		end
	end
end

function newOnPointsInput(player, rowName)
	local id = nextInputID
	inputIDs[id] = function(value)
		playerPoints[player.color][rowName] = tonumber(value)
		for _, cell in ipairs(rows[rowName].children) do
			if cell.attributes.playerColor == player.color then
				cell.children[1].value = value
				break
			end
		end
		setTotalPoints(player.color)
		xmlNeedsUpdate = true
	end
	nextInputID = nextInputID + 1
	return id
end

function setCellPoints(rowName, playerColor, points)
	for _, cell in ipairs(rows[rowName].children) do
		if cell.attributes.playerColor == playerColor then
			cell.children[1].attributes.value = points
			cell.children[1].value = points
			break
		end
	end
end

function setBirdPoints(params)
	local playerColor, points = params[1], params[2]
	local rowPoints = playerPoints[playerColor]
	if rowPoints and rowPoints["birds"] ~= points then
		rowPoints["birds"] = points
		setCellPoints("birds", playerColor, points)
		setTotalPoints(playerColor)
		xmlNeedsUpdate = true
	end
end

function setGoalPoints(goalPoints)
	for playerColor, rowPoints in pairs(playerPoints) do
		local points = goalPoints[playerColor] or 0
		rowPoints["goals"] = points
		setCellPoints("goals", playerColor, points)
		setTotalPoints(playerColor)
	end
	xmlNeedsUpdate = true
end

function setEggPoints(params)
	local playerColor, points = params[1], params[2]
	local rowPoints = playerPoints[playerColor]
	if rowPoints and rowPoints["eggs"] ~= points then
		rowPoints["eggs"] = points
		setCellPoints("eggs", playerColor, points)
		setTotalPoints(playerColor)
		xmlNeedsUpdate = true
	end
end

function setFoodPoints(params)
	local playerColor, points = params[1], params[2]
	local rowPoints = playerPoints[playerColor]
	if rowPoints and rowPoints["food"] ~= points then
		rowPoints["food"] = points
		setCellPoints("food", playerColor, points)
		setTotalPoints(playerColor)
		xmlNeedsUpdate = true
	end
end

function setTuckedPoints(params)
	local playerColor, points = params[1], params[2]
	local rowPoints = playerPoints[playerColor]
	if rowPoints and rowPoints["tucked"] ~= points then
		rowPoints["tucked"] = points
		setCellPoints("tucked", playerColor, points)
		setTotalPoints(playerColor)
		xmlNeedsUpdate = true
	end
end

function setDuetPoints(duetPoints)
end

function setHabitatNectar(params)
	local playerColor, habitatNectar = table.unpack(params)
	playerHabitatNectar[playerColor] = habitatNectar
	updateHabitatNectar()
end

---@alias TopHabitatPlayers { [string]: string[][] }

function updateHabitatNectar()
	local topHabitatNectar = {
		forest = {},
		grassland = {},
		wetland = {},
	}
	---@type TopHabitatPlayers
	local topHabitatPlayers = {
		forest = {},
		grassland = {},
		wetland = {},
	}
	for playerColor, habitatNectar in pairs(playerHabitatNectar) do
		for habitat, nectar in pairs(habitatNectar) do
			if nectar > 0 then
				local topNectar = topHabitatNectar[habitat]
				local firstNectar, secondNectar = table.unpack(topNectar)
				if not firstNectar then
					table.insert(topHabitatNectar[habitat], 1, nectar)
					table.insert(topHabitatPlayers[habitat], 1, { playerColor })
				elseif nectar > firstNectar then
					table.insert(topHabitatNectar[habitat], 1, nectar)
					table.insert(topHabitatPlayers[habitat], 1, { playerColor })
				elseif nectar == firstNectar then
					table.insert(topHabitatPlayers[habitat][1], playerColor)
				elseif not secondNectar or nectar > secondNectar then
					table.insert(topHabitatNectar[habitat], 2, nectar)
					table.insert(topHabitatPlayers[habitat], 2, { playerColor })
				elseif nectar == secondNectar then
					table.insert(topHabitatPlayers[habitat][2], playerColor)
				end
			end
		end
	end
	setNectarPoints(topHabitatPlayers)
end

---@param topHabitatPlayers TopHabitatPlayers
function setNectarPoints(topHabitatPlayers)
	for playerColor, rowPoints in pairs(playerPoints) do
		for habitat, places in pairs(topHabitatPlayers) do
			local points = 0
			for i = 1, 2 do
				local tied = false
				local players = places[i]
				if players then
					if #players > 1 then
						tied = true
					end
					for _, player in ipairs(players) do
						if player == playerColor then
							points = i == 1 and 5 or 2
							if tied then
								points = i == 1 and 7 or 2
								points = math.floor(points / #players)
							end
						end
					end
				end
				if tied then break end
			end
			if rowPoints[habitat] ~= points then
				rowPoints[habitat] = points
				setNectarCellPoints(playerColor, habitat, points)
				setTotalPoints(playerColor)
				xmlNeedsUpdate = true
			end
		end
	end
end

function setNectarCellPoints(playerColor, habitat, points)
	for _, cell in ipairs(rows["nectar"].children) do
		if cell.attributes.playerColor == playerColor then
			for _, text in ipairs(cell.children) do
				if text.attributes.habitat == habitat then
					text.attributes.value = points
					text.value = points
					break
				end
			end
			break
		end
	end
end

function setHummingbirdPoints(hummingbirdPoints)
end
