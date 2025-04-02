local function dprint(...)
    if isDebugEnabled() then
        print("[DELRAN'S DRAG TO PLACE]: ", ...);
    end
end

local DelranDragToPlace = {};

DelranDragToPlace.OnDragItem = function(item, playerNum)
    ---dprint("HAHA DRAGIN THIS : ", item);
end

DelranDragToPlace.OnTick = function(tick)
    if tick % 1000 == 0 then
        ---dprint("TICKING")
    end
end

Events.SetDragItem.Add(DelranDragToPlace.OnDragItem);
Events.OnTick.Add(DelranDragToPlace.OnTick);
---Events.mo
---
MyThingy = nil;

if not ORIGINAL_ISINVENTORYPANE_ONMOUSEMOVEOUTSIDE then
    ORIGINAL_ISINVENTORYPANE_ONMOUSEMOVEOUTSIDE = ISInventoryPane.onMouseMoveOutside;
end

---@diagnostic disable-next-line: duplicate-set-field
function ISInventoryPane:onMouseMoveOutside(dx, dy)
    ORIGINAL_ISINVENTORYPANE_ONMOUSEMOVEOUTSIDE(self, dx, dy);
    if self.dragging and self.dragStarted and #self.draggedItems.items == 1 then
        local player = getSpecificPlayer(0);
        MyThingy = ISPlace3DItemCursor:new(player, self.draggedItems.items);
        getCell():setDrag(MyThingy, player:getIndex())
    end
end

if not ORIGINAL_ISInventoryPane_onMouseUpOutside then
    ORIGINAL_ISInventoryPane_onMouseUpOutside = ISInventoryPane.onMouseUpOutside;
end
---@diagnostic disable-next-line: duplicate-set-field
function ISInventoryPane:onMouseUpOutside(dx, dy)
    if MyThingy then
        MyThingy:create(nil, nil, nil, nil, nil);
        getCell():setDrag(nil, getSpecificPlayer(0):getIndex());
        MyThingy = nil;
    end
    ORIGINAL_ISInventoryPane_onMouseUpOutside(self, dx, dy);
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
