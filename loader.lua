local function getGameId()
    local marketplaceService = game:GetService("MarketplaceService")
    local productInfo = marketplaceService:GetProductInfo(game.PlaceId)
    return productInfo.AssetId
end

local function getScriptUrl(gameId)
    local baseUrl = "https://raw.githubusercontent.com/TrustsenseDev/Zyra/main/Games/"
    return baseUrl .. gameId .. ".lua"
end

local function loadScript(scriptUrl)
    local success, response = pcall(game.HttpGet, game, scriptUrl)
    if success then
        local script = loadstring(response)
        script()
    else
        print("No script found for this game")
    end
end

local gameId = getGameId()
local scriptUrl = getScriptUrl(gameId)
loadScript(scriptUrl)
