local function dprint(...)
    if isDebugEnabled() then
        print("[DELRAN'S DRAG TO PLACE]: ", ...);
    end
end

local DelranDragToPlace = {

};
DelranDragToPlace.DRAG_UPDATE = 100;

---@type IsoPlayer
DelranDragToPlace.player = nil;
---@type integer
DelranDragToPlace.playerIndex = nil;
---@type InventoryItem[]
DelranDragToPlace.draggedItems = nil;
---@type ISInventoryPane
DelranDragToPlace.dragOwner = nil;
---@type ISPlace3DItemCursor
DelranDragToPlace.placeItemCursor = nil;

DelranDragToPlace.placingItem = false;
DelranDragToPlace.hidden = false;

DelranDragToPlace.lastUpdateInMs = 0;



DelranDragToPlace.OnTick = function(tick)
    if tick % 1000 == 0 then
        ---dprint("TICKING")
    end
end

---comment
---@param player IsoPlayer
---@param draggedItems InventoryItem[]
---@param dragOwner ISInventoryPane
function DelranDragToPlace:Start(player, draggedItems, dragOwner)
    dprint("Creating 3d cursor");
    self.placingItem = true;

    self.dragOwner = dragOwner;

    self.player = player;
    self.playerIndex = self.player:getIndex();
    self.draggedItems = draggedItems;
    self:ShowCursor();
end

function DelranDragToPlace:Finish()
    dprint("Deleting 3d cursor")
    self.hidden = false;
    self.placingItem = false;

    self.player = nil;
    self.playerIndex = nil;
    self.draggedItems = nil;
    self.placeItemCursor = nil;
end

function DelranDragToPlace:ShowCursor()
    self.hidden = false;
    dprint("Showing 3d cursor");
    self.placeItemCursor = ISPlace3DItemCursor:new(self.player, self.draggedItems);
    getCell():setDrag(self.placeItemCursor, self.playerIndex)
end

function DelranDragToPlace:HideCursor()
    self.hidden = true;
    dprint("Hiding 3d cursor");
    self.placeItemCursor = nil;
    getCell():setDrag(nil, self.playerIndex);
end

function DelranDragToPlace:PlaceItem()
    --luautils.walkAdj(self.player, self.placeItemCursor.selectedSqDrop, true);
    local draggedItem = self.draggedItems[1];
    ISWorldObjectContextMenu.transferIfNeeded(self.player, draggedItem)
    if luautils.walkAdjAltTest(self.player, self.placeItemCursor.selectedSqDrop, self.placeItemCursor.itemSq, true) then
        if self.player:isEquipped(draggedItem) then
            ISTimedActionQueue.add(ISUnequipAction:new(self.player, draggedItem, 100));
        end
        ISTimedActionQueue.add(ISDropWorldItemAction:new(self.player, draggedItem,
            self.placeItemCursor.selectedSqDrop,
            self.placeItemCursor.render3DItemXOffset, self.placeItemCursor.render3DItemYOffset,
            self.placeItemCursor.render3DItemZOffset, self.placeItemCursor.render3DItemRot, false));
    end
    self.placeItemCursor:deactivate();
    getCell():setDrag(nil, self.playerIndex);
    self:Finish();
end

function DelranDragToPlace:OnMouseMove(x, y, xMultiplied, yMultiplied)
end

Events.OnTick.Add(DelranDragToPlace.OnTick);
Events.OnMouseMove.Add(DelranDragToPlace.OnMouseMove);

if not ORIGINAL_ISInventoryPane_onMouseMoveOutside then
    ORIGINAL_ISInventoryPane_onMouseMoveOutside = ISInventoryPane.onMouseMoveOutside;
end
---@diagnostic disable-next-line: duplicate-set-field
function ISInventoryPane:onMouseMoveOutside(dx, dy)
    ORIGINAL_ISInventoryPane_onMouseMoveOutside(self, dx, dy);
    if not DelranDragToPlace:NeedsUpdate() then return; end;
    if self.draggedItems and self.draggedItems.items and #self.draggedItems.items == 1 then
        if DelranDragToPlace.placingItem then
            if DelranDragToPlace.hidden then
                DelranDragToPlace:ShowCursor();
            end
        else
            local player = getPlayer();
            DelranDragToPlace:Start(player, self.draggedItems.items, self);
        end
    end
end

if not ORIGINAL_ISInventoryPane_onMouseUpOutside then
    ORIGINAL_ISInventoryPane_onMouseUpOutside = ISInventoryPane.onMouseUpOutside;
end
---@diagnostic disable-next-line: duplicate-set-field
function ISInventoryPane:onMouseUpOutside(dx, dy)
    if DelranDragToPlace.placingItem and DelranDragToPlace.dragOwner ~= self then
        DelranDragToPlace:PlaceItem();
    else
        ORIGINAL_ISInventoryPane_onMouseUpOutside(self, dx, dy);
    end
end

if not ORIGINAL_ISInventoryPane_onMouseUp then
    ORIGINAL_ISInventoryPane_onMouseUp = ISInventoryPane.onMouseUp;
end
---@diagnostic disable-next-line: duplicate-set-field
function ISInventoryPane:onMouseUp(dx, dy)
    if DelranDragToPlace.placingItem then
        DelranDragToPlace:Finish();
    end
    ORIGINAL_ISInventoryPane_onMouseUp(self, dx, dy);
end

if not ORIGINAL_ISInventoryPane_onMouseMove then
    ORIGINAL_ISInventoryPane_onMouseMove = ISInventoryPane.onMouseMove;
end
---@diagnostic disable-next-line: duplicate-set-field
function ISInventoryPane:onMouseMove(dx, dy)
    ORIGINAL_ISInventoryPane_onMouseMove(self, dx, dy);
    if DelranDragToPlace.placingItem and not DelranDragToPlace.hidden then
        DelranDragToPlace:HideCursor();
    end
end

if not ORIGINAL_ISUI3DScene_onMouseMove then
    ORIGINAL_ISUI3DScene_onMouseMove = ISUI3DScene.onMouseMove;
end
function ISUI3DScene:onMouseMove(dx, dy)
    dprint("Moving in 3d scene")
    ORIGINAL_ISUI3DScene_onMouseMove(self, dx, dy);
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
