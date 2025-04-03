local function dprint(...)
    if isDebugEnabled() then
        print("[DELRAN'S DRAG TO PLACE]: ", ...);
    end
end

local function IsMouseOverUi()
    local uis = UIManager.getUI()
    for i = 1, uis:size() do
        local ui = uis:get(i - 1)
        if ui:isMouseOver() then
            return true;
        end
    end
    return false;
end

DRAGGING_TIMER = 0;

local DelranDragToPlace = {

};
DelranDragToPlace.DRAG_UPDATE = 100;

---@type IsoPlayer
DelranDragToPlace.player = nil;
---@type integer
DelranDragToPlace.playerIndex = nil;
---@type ISInventoryPaneDraggedItems
DelranDragToPlace.draggedItems = nil;
---@type ISInventoryPane
DelranDragToPlace.dragOwner = nil;
---@type ISPlace3DItemCursor
DelranDragToPlace.placeItemCursor = nil;

DelranDragToPlace.placingItem = false;
DelranDragToPlace.hidden = false;

DelranDragToPlace.lastUpdateInMs = 0;

DelranDragToPlace.OnTick = function(tick)
    if tick % DelranDragToPlace.WaitBeforeDragTimer.TIME_STEP == 0 then
        DelranDragToPlace.WaitBeforeDragTimer:UpdateTimer();
    end
end

---comment
---@param player IsoPlayer
---@param draggedItems ISInventoryPaneDraggedItems
---@param dragOwner ISInventoryPane
function DelranDragToPlace:Start(player, draggedItems, dragOwner)
    dprint("Creating 3d cursor");
    self.placingItem = true;
    self.dragging = true;
    self.dragOwner = dragOwner;

    self.player = player;
    self.playerIndex = self.player:getIndex();
    self.draggedItems = draggedItems;

    self.placeItemCursor = ISPlace3DItemCursor:new(self.player, self.draggedItems.items);
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
    self.dragOwner.dragging = nil;
    --self.dragOwner.draggedItems:reset();
    self.hidden = false;
    dprint("Showing 3d cursor");
    getCell():setDrag(self.placeItemCursor, self.playerIndex)
end

function DelranDragToPlace:HideCursor()
    self.hidden = true;
    dprint("Hiding 3d cursor");
    getCell():setDrag(nil, self.playerIndex);
    self.dragOwner.dragging = 1;
    --self.dragOwner.draggedItems = self.draggedItems;
end

function DelranDragToPlace:PlaceItem()
    self.placingItem = false;
    local draggedItem = self.draggedItems.items[1];
    local worldItem = draggedItem:getWorldItem();
    if worldItem then
        luautils.walkAdj(self.player, worldItem:getSquare(), true);
    end
    ISWorldObjectContextMenu.transferIfNeeded(self.player, draggedItem)
    if luautils.walkAdjAltTest(self.player, self.placeItemCursor.selectedSqDrop, self.placeItemCursor.itemSq, true) then
        if self.player:isEquipped(draggedItem) then
            ISTimedActionQueue.add(ISUnequipAction:new(self.player, draggedItem, 50));
        end
        ISTimedActionQueue.add(ISDropWorldItemAction:new(self.player, draggedItem,
            self.placeItemCursor.selectedSqDrop,
            self.placeItemCursor.render3DItemXOffset, self.placeItemCursor.render3DItemYOffset,
            self.placeItemCursor.render3DItemZOffset, self.placeItemCursor.render3DItemRot, false));
    end
    getCell():setDrag(nil, self.playerIndex);
    self:Finish();
end

function DelranDragToPlace:OnMouseMove(x, y, xMultiplied, yMultiplied)
end

-- Function overrides
if not ORIGINAL_ISInventoryPane_onMouseMoveOutside then
    ORIGINAL_ISInventoryPane_onMouseMoveOutside = ISInventoryPane.onMouseMoveOutside;
end
if not ORIGINAL_ISInventoryPane_onMouseMove then
    ORIGINAL_ISInventoryPane_onMouseMove = ISInventoryPane.onMouseMove;
end
if not ORIGINAL_ISInventoryPane_onMouseUpOutside then
    ORIGINAL_ISInventoryPane_onMouseUpOutside = ISInventoryPane.onMouseUpOutside;
end
if not ORIGINAL_ISInventoryPane_onMouseUp then
    ORIGINAL_ISInventoryPane_onMouseUp = ISInventoryPane.onMouseUp;
end

DelranDragToPlace.WaitBeforeDragTimer = {}
---@type ISInventoryPane
DelranDragToPlace.WaitBeforeDragTimer.owner = nil;
---@type integer
DelranDragToPlace.WaitBeforeDragTimer.ticksElapsed = 0;
DelranDragToPlace.WaitBeforeDragTimer.TIME_STEP = 2;
DelranDragToPlace.WaitBeforeDragTimer.TICKS_BEFORE_DRAGGING = 20;

---@param owner ISInventoryPane
function DelranDragToPlace.WaitBeforeDragTimer:Start(owner)
    if self.owner == owner then return end;
    dprint("starting timer");
    self.owner = owner;
    self.items = self.owner.draggedItems;
    Events.OnTick.Add(DelranDragToPlace.OnTick);
end

function DelranDragToPlace.WaitBeforeDragTimer:Reset()
    Events.OnTick.Remove(DelranDragToPlace.OnTick);
    self.ticksElapsed = 0;
    self.owner = nil;
    self.items = nil;
end

function DelranDragToPlace.WaitBeforeDragTimer:UpdateTimer()
    if IsMouseOverUi() then
        self:Reset();
    else
        self.ticksElapsed = self.ticksElapsed + self.TIME_STEP;
        if self.ticksElapsed > self.TICKS_BEFORE_DRAGGING then
            DelranDragToPlace:Start(getPlayer(), self.items, self.owner);
            self:Reset();
        end
    end
end

---@diagnostic disable-next-line: duplicate-set-field
function ISInventoryPane:onMouseMoveOutside(dx, dy)
    ORIGINAL_ISInventoryPane_onMouseMoveOutside(self, dx, dy);
    if DelranDragToPlace.placingItem and self == DelranDragToPlace.dragOwner then
        local isMouseOverUi = IsMouseOverUi();
        if DelranDragToPlace.hidden and not isMouseOverUi then
            DelranDragToPlace:ShowCursor();
        elseif not DelranDragToPlace.hidden and isMouseOverUi then
            DelranDragToPlace:HideCursor();
        end
    elseif self.dragging and self.draggedItems and self.draggedItems.items and #self.draggedItems.items == 1 then
        DelranDragToPlace.WaitBeforeDragTimer:Start(self);
    end
end

---@diagnostic disable-next-line: duplicate-set-field
function ISInventoryPane:onMouseMove(dx, dy)
    ORIGINAL_ISInventoryPane_onMouseMove(self, dx, dy);
    if self ~= DelranDragToPlace.dragOwner then
        return
    end
    if DelranDragToPlace.placingItem and not DelranDragToPlace.hidden then
        DelranDragToPlace:HideCursor();
    end
end

---@diagnostic disable-next-line: duplicate-set-field
function ISInventoryPane:onMouseUpOutside(dx, dy)
    DelranDragToPlace.WaitBeforeDragTimer:Reset();
    if self == DelranDragToPlace.dragOwner and DelranDragToPlace.placingItem and not IsMouseOverUi() then
        --self.dragging = nil;
        DelranDragToPlace:PlaceItem();
    else
        ORIGINAL_ISInventoryPane_onMouseUpOutside(self, dx, dy);
    end
end

---@diagnostic disable-next-line: duplicate-set-field
function ISInventoryPane:onMouseUp(dx, dy)
    if DelranDragToPlace.placingItem then
        DelranDragToPlace:Finish();
    end
    ORIGINAL_ISInventoryPane_onMouseUp(self, dx, dy);
end

--[[
Ressources

Mouse.UICaptured

ISInventoryPage.onKeyPressed = function(key)
	if getCore():isKey("Toggle Inventory", key) and getSpecificPlayer(0) and getGameSpeed() > 0 and getPlayerInventory(0) and getCore():getGameMode() ~= "Tutorial" then
        getPlayerInventory(0):setVisible(not getPlayerInventory(0):getIsVisible());
        getPlayerLoot(0):setVisible(getPlayerInventory(0):getIsVisible());
    end
end
]]
