local DragToPlace = require("DelranDragToPlace/DelranDragToPlace_Main")
local DelranUtils = require("DelranDragToPlace/DelranLib/DelranUtils")

local dprint = DelranUtils.GetDebugPrint("[DELRAN'S DRAG TO PLACE - SERVER]")

if not ORIGINAL_ISObjectClickHandler_doRClick then
    ORIGINAL_ISObjectClickHandler_doRClick = ISObjectClickHandler.doRClick;
end
---@diagnostic disable-next-line: duplicate-set-field
ISObjectClickHandler.doRClick = function(object, x, y)
    -- Cancel Drag to place if we right click on the world.
    if DragToPlace.placingItem then
        DragToPlace:Cancel();
    else
        ORIGINAL_ISObjectClickHandler_doRClick(object, x, y);
    end
end

ORIGINAL_ISPlace3DItemCursor_handleRotate = ORIGINAL_ISPlace3DItemCursor_handleRotate or
    ISPlace3DItemCursor.handleRotate;
---@diagnostic disable-next-line: duplicate-set-field
function ISPlace3DItemCursor:handleRotate(pressed, reverse)
    ORIGINAL_ISPlace3DItemCursor_handleRotate(self, pressed, reverse);
    if (DragToPlace:IsVisible()) then
        DragToPlace.placedItemsRotation[DragToPlace.actualDraggedItem] = self.render3DItemRot;
    end
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
