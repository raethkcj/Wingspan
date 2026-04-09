local UI = self.UI
local scoresheetXml
local rows = {}
local playerPoints = {}

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

function initializeBirdPoints(cell, player)
	local id = newOnPointsInput(player, "birds") 
	cell.children[1].attributes.id = id
	local points = tonumber(cell.children[1].value) or 0
	return points
end

function initializeBonusPoints(cell, player)
	local id = newOnPointsInput(player, "bonuses") 
	cell.children[1].attributes.id = id
	local points = tonumber(cell.children[1].value) or 0
	return points
end

function initializeNectarPoints(cell, player)
	local points = 0
	for i, inputField in ipairs(cell.children) do
		local id = newOnPointsInput(player, inputField.attributes.habitat) 
		inputField.attributes.id = id
		points = points + (tonumber(inputField.value) or 0)
	end
	return points
end

function initializeZero(cell, player)
	cell.children[1].attributes.value = 0
	cell.children[1].value = 0
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
	birds   = initializeBirdPoints,
	bonuses = initializeBonusPoints,
	goals   = initializeZero,
	eggs    = initializeZero,
	food    = initializeZero,
	tucked  = initializeZero,
	duet    = initializeZero,
	nectar  = initializeNectarPoints,
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

local nectarLabels = {
	forest = true,
	grassland = true,
	wetland = true,
}

function newOnPointsInput(player, label)
	local id = nextInputID
	inputIDs[id] = function(value)
		playerPoints[player.color][label] = tonumber(value)
		local rowName = label
		if nectarLabels[label] then
			rowName = "nectar"
		end
		for _, cell in ipairs(rows[rowName].children) do
			if cell.attributes.playerColor == player.color then
				if not nectarLabels[label] then
					cell.children[1].value = value
				else
					for _, inputField in ipairs(cell.children) do
						if inputField.attributes.habitat == label then
							inputField.value = value
							break
						end
					end
				end
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

function setHummingbirdPoints(hummingbirdPoints)
end
