---@class DelranTileFinder
local DelranTileFinder = {}

---@param player IsoPlayer
---@return DelranTileFinder
function DelranTileFinder:BuildForPlayer(player)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    self.startingSquare = player:getSquare();
    return o;
end

---@param square IsoGridSquare
---@return DelranTileFinder
function DelranTileFinder:BuildForSquare(square)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    self.startingSquare = square;
    return o;
end

---@param directionsToTest IsoDirections[]
---@param destionationSquare IsoGridSquare
function DelranTileFinder.TestAdjacentSquares(directionsToTest, destionationSquare, results)
    for _, direction in ipairs(directionsToTest) do
        local square = destionationSquare:getAdjacentSquare(direction);
        -- for each of them, test that square then if it's 'adjacent' then add it to the table for picking.
        if square:isFree(false) and AdjacentFreeTileFinder.privTrySquare(destionationSquare, square) then
            table.insert(results, square);
        end
    end
end

---comment
---@param destionationSquare IsoGridSquare
---@return IsoGridSquare|nil
function DelranTileFinder:Find(destionationSquare)
    ---@type IsoGridSquare[]
    local choices = {};
    ---@type IsoDirections[]
    local directions = { IsoDirections.W, IsoDirections.E, IsoDirections.N, IsoDirections.S };
    self.TestAdjacentSquares(directions, destionationSquare, choices);

    -- only do diags if no other choices.
    if table.isempty(choices) then
        -- now do diags.
        directions = { IsoDirections.NW, IsoDirections.NE, IsoDirections.SW, IsoDirections.SE }
        self.TestAdjacentSquares(directions, destionationSquare, choices);
    end

    -- if we have multiple choices, pick the one closest to the player
    if not table.isempty(choices) then
        local lowestdist = 100000;
        local distchoice = nil;

        for _, possibleSquare in ipairs(choices) do
            local dist = possibleSquare:DistToProper(self.startingSquare);
            if dist < lowestdist then
                lowestdist = dist;
                distchoice = possibleSquare;
            end
        end

        return distchoice;
    end
    return nil;
end

---@param square IsoGridSquare
---@return boolean
function DelranTileFinder:IsNextToSquare(square)
    if self.startingSquare == square then return true end;

    local diffX = math.abs(self.startingSquare:getX() + 0.5 - square:getX());
    local diffY = math.abs(self.startingSquare:getY() + 0.5 - square:getY());
    if diffX <= 1.6 and diffY <= 1.6 then
        return true;
    end
    return false;
end

return DelranTileFinder
