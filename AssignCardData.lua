-- Insert appropriate deck GUID and bird json as a string
local deckGUID = "402984"
local data = [[ Paste JSON here ]]

local birds = JSON.decode(data)

function onLoad()
    local deck = getObjectFromGUID(deckGUID)
    
    for i, card in ipairs(deck.getObjects()) do
        local bird = birds[i]
        Wait.frames(function()
            takeCard(deck, card, i)
        end, i * 5)
    end
end

function takeCard(deck, card, i)
    local position = deck.getPosition()
    position[1] = position[1] + 2
    position[2] = 5
    deck.takeObject({
        guid = card.guid,
        position = position,
        flip = true,
        callback_function = function(object)
            setData(object, birds[i])
        end
    })
    if deck.remainder then
        setData(deck.remainder, birds[i + 1])
    end
end

function setData(card, bird)
    card.setName(bird.name)
    card.setMemo(bird.points)
end