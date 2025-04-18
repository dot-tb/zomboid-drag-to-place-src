local DragToPlace = require("DelranDragToPlace/DelranDragToPlace_Main")
local DelranUtils = require("DelranDragToPlace/DelranLib/DelranUtils")

local dprint = DelranUtils.GetDebugPrint("[DELRAN'S DRAG TO PLACE - SERVER]")

if not ORIGINAL_ISObjectClickHandler_doRClick then
    ORIGINAL_ISObjectClickHandler_doRClick = ISObjectClickHandler.doRClick;
end
---@diagnostic disable-next-line: duplicate-set-field
ISObjectClickHandler.doRClick = function(object, x, y)
    if DragToPlace.placingItem then
        DragToPlace:Cancel();
    else
        ORIGINAL_ISObjectClickHandler_doRClick(object, x, y);
    end
    --[[
    if instanceof(object, "IsoObject") then
        --sq = object:getCurrentSquare();
        ---@type IsoObject
        local isoObject = object;
        dprint(isoObject);
        local square = isoObject:getSquare();
        local objects = square:getWorldObjects();
        for i = 0, objects:size() - 1, 1 do
            ---@type IsoWorldInventoryObject
            local worldObect = objects:get(i);
            if instanceof(worldObect, "IsoWorldInventoryObject") then
                dprint(worldObect:getSprite());
                dprint(worldObect:getWorldPosX())
                dprint(worldObect:getWorldPosY())
                ---dprint(worldObect:getWorldPosZ())
                dprint(screenToIsoX(getPlayer():getIndex(), x, y, getPlayer():getZ()));
                dprint(screenToIsoY(getPlayer():getIndex(), x, y, getPlayer():getZ()));
            end
        end
    end
    ]]
end

local original_isvalid = ISPlace3DItemCursor.isValid;
---@diagnostic disable-next-line: duplicate-set-field
function ISPlace3DItemCursor:isValid(square)
    if not DragToPlace.options.faceItemWhilePlacing and DragToPlace.placingItem then return true end
    return original_isvalid(self, square);
end

OG_CURSOR_RENDER = OG_CURSOR_RENDER or ISPlace3DItemCursor.render;
---@diagnostic disable-next-line: duplicate-set-field
function ISPlace3DItemCursor:render(x, y, z, square)
    if DragToPlace.placingItem and DragToPlace.rotating then
        local rt = DragToPlace.rotating
        OG_CURSOR_RENDER(self, rt.x, rt.y, rt.z, rt.square);
    else
        OG_CURSOR_RENDER(self, x, y, z, square);
    end
end

OG_CHECK_ROTATE_KEY = OG_CHECK_ROTATE_KEY or ISPlace3DItemCursor.checkRotateKey;
---@diagnostic disable-next-line: duplicate-set-field
function ISPlace3DItemCursor:checkRotateKey()
    if not DragToPlace.options.faceItemWhilePlacing and DragToPlace.placingItem then return end
    OG_CHECK_ROTATE_KEY(self);
end

--[[
Ressources
ISInventoryPage.onKeyPressed = function(key)
	if getCore():isKey("Toggle Inventory", key) and getSpecificPlayer(0) and getGameSpeed() > 0 and getPlayerInventory(0) and getCore():getGameMode() ~= "Tutorial" then
        getPlayerInventory(0):setVisible(not getPlayerInventory(0):getIsVisible());
        getPlayerLoot(0):setVisible(getPlayerInventory(0):getIsVisible());
    end
end
]]
