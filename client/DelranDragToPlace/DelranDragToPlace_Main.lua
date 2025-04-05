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

local DelranDragToPlace = {};

---@type IsoPlayer
DelranDragToPlace.player = nil;
---@type integer
DelranDragToPlace.playerIndex = nil;
---@type ISInventoryPaneDraggedItems
DelranDragToPlace.draggedItems = nil;
---@type InventoryItem
DelranDragToPlace.actualDraggedItem = nil;
---@type ISInventoryPane
DelranDragToPlace.startedFrom = nil;
---@type ISPlace3DItemCursor
DelranDragToPlace.placeItemCursor = nil;

DelranDragToPlace.placingItem = false;
DelranDragToPlace.hidden = true;

DelranDragToPlace.lastUpdateInMs = 0;

DelranDragToPlace.OnTick = function(tick)
    if tick % DelranDragToPlace.WaitBeforeShowCursorTimer.TIME_STEP == 0 then
        DelranDragToPlace.WaitBeforeShowCursorTimer:UpdateTimer();
    end
end

---@param player IsoPlayer
---@param draggedItems ISInventoryPaneDraggedItems
---@param startedFrom ISInventoryPane
function DelranDragToPlace:Start(player, draggedItems, startedFrom)
    self.placingItem = true;
    self.startedFrom = startedFrom;

    self.player = player;
    self.startDirection = self.player:getDirectionAngle();
    self.playerIndex = self.player:getIndex();
    self.draggedItems = draggedItems;
    self.actualDraggedItem = draggedItems.items[1];
    self.startingContainer = self.actualDraggedItem:getContainer();

    self.placeItemCursor = ISPlace3DItemCursor:new(self.player, self.draggedItems.items);
    if self.actualDraggedItem:getWorldItem() then
        self.placeItemCursor.render3DItemRot = self.actualDraggedItem:getWorldZRotation();
    end
    self.WaitBeforeShowCursorTimer:Start(self.startedFrom);

    function OnPlayerMoveTemp(_player)
        self:OnPlayerMove(_player);
    end

    Events.OnPlayerMove.Add(OnPlayerMoveTemp);
    Events.OnMouseMove.Add(self.OnMouseMove);
end

function DelranDragToPlace:Finish()
    Events.OnPlayerMove.Remove(OnPlayerMoveTemp);
    Events.OnMouseMove.Remove(self.OnMouseMove);
    -- Clear the show cursor timer
    self.WaitBeforeShowCursorTimer:Reset();

    -- Destroy the 3D cursor
    self.placeItemCursor = nil;

    -- Reset everything to default values
    self.hidden = true;
    self.placingItem = false;

    self.player = nil;
    self.playerIndex = nil;
    self.draggedItems = nil;
end

function DelranDragToPlace:StartShowCursorTimer()
    -- Start the show cursor timer
    self.WaitBeforeShowCursorTimer:Start(self.startedFrom);
end

function DelranDragToPlace:ShowCursor()
    -- Setting dragging from the ISInventoryPane to nil will
    --  stop the renderering of the dragged items
    dprint("Show cursor")
    self.startedFrom.dragging = nil;
    self.hidden = false;

    -- Setting drag back to the cursor so it will show on the world
    getCell():setDrag(self.placeItemCursor, self.playerIndex)
end

function DelranDragToPlace:HideCursor()
    self.hidden = true;
    -- Set drag to nil, the 3d cursor will disapear but not be deleted
    getCell():setDrag(nil, self.playerIndex);

    self.player:setDirectionAngle(self.startDirection);
    --@type ISInventoryPage
    -- local test = getPlayerData(self.playerIndex).lootInventory;
    -- test:setNewContainer(self.startingContainer);
    -- Let the ISInventoryPane draw the dragged inventory item
    self.startedFrom.dragging = 1;
end

function DelranDragToPlace:PlaceItem()
    -- Get the dragged item from the ISInventoryPane
    -- There should only be one as we don't start the drag if there is more than one dragged item
    local draggedItem = self.draggedItems.items[1];
    local worldItem = draggedItem:getWorldItem();
    if worldItem then
        -- If the item is in the world, walk nest to it first
        luautils.walkAdj(self.player, worldItem:getSquare(), true);
    end
    -- Transfer the item in the inventory if needed
    ISWorldObjectContextMenu.transferIfNeeded(self.player, draggedItem);
    -- Walk to the square where we want to drop the item
    if luautils.walkAdjAltTest(self.player, self.placeItemCursor.selectedSqDrop, self.placeItemCursor.itemSq, true) then
        -- Unequip the item if it is equipped on the player
        if self.player:isEquipped(draggedItem) then
            ISTimedActionQueue.add(ISUnequipAction:new(self.player, draggedItem, 50));
        end
        -- Finaly, drop the item at the position and rotation of the cursor.
        ISTimedActionQueue.add(ISDropWorldItemAction:new(self.player, draggedItem,
            self.placeItemCursor.selectedSqDrop,
            self.placeItemCursor.render3DItemXOffset, self.placeItemCursor.render3DItemYOffset,
            self.placeItemCursor.render3DItemZOffset, self.placeItemCursor.render3DItemRot, false));
    end
    -- Hide the 3D cursor
    getCell():setDrag(nil, self.playerIndex);
    -- Clean and stop
    self:Finish();
end

function DelranDragToPlace:OnMouseMove(x, y, xMultiplied, yMultiplied)
end

---@param player IsoPlayer
function DelranDragToPlace:OnPlayerMove(player)
    if player == self.player then
        self.startDirection = player:getDirectionAngle();
    end
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

DelranDragToPlace.WaitBeforeShowCursorTimer = {}
---@type ISInventoryPane
DelranDragToPlace.WaitBeforeShowCursorTimer.owner = nil;
---@type integer
DelranDragToPlace.WaitBeforeShowCursorTimer.ticksElapsed = 0;
DelranDragToPlace.WaitBeforeShowCursorTimer.TIME_STEP = 2;
DelranDragToPlace.WaitBeforeShowCursorTimer.TICKS_BEFORE_DRAGGING = 20;

---@param owner ISInventoryPane
function DelranDragToPlace.WaitBeforeShowCursorTimer:Start(owner)
    if self.owner == owner then return end;
    dprint("starting timer");
    self.owner = owner;
    self.items = self.owner.draggedItems;
    Events.OnTick.Add(DelranDragToPlace.OnTick);
end

function DelranDragToPlace.WaitBeforeShowCursorTimer:Reset()
    Events.OnTick.Remove(DelranDragToPlace.OnTick);
    self.ticksElapsed = 0;
    self.owner = nil;
    self.items = nil;
end

function DelranDragToPlace.WaitBeforeShowCursorTimer:UpdateTimer()
    if IsMouseOverUi() then
        self:Reset();
    else
        self.ticksElapsed = self.ticksElapsed + self.TIME_STEP;
        if self.ticksElapsed > self.TICKS_BEFORE_DRAGGING then
            DelranDragToPlace:ShowCursor();
            self:Reset();
        end
    end
end

---@diagnostic disable-next-line: duplicate-set-field
function ISInventoryPane:onMouseMoveOutside(dx, dy)
    ORIGINAL_ISInventoryPane_onMouseMoveOutside(self, dx, dy);
    if DelranDragToPlace.placingItem and DelranDragToPlace.startedFrom == self then
        local isMouseOverUi = IsMouseOverUi();
        if DelranDragToPlace.hidden and not isMouseOverUi then
            DelranDragToPlace:StartShowCursorTimer();
        elseif not DelranDragToPlace.hidden and isMouseOverUi then
            DelranDragToPlace:HideCursor();
        end
    elseif self.dragging and self.draggedItems and self.draggedItems.items and #self.draggedItems.items == 1 then
        if not DelranDragToPlace.placingItem then
            DelranDragToPlace:Start(getPlayer(), self.draggedItems, self);
        end
    end
end

---@diagnostic disable-next-line: duplicate-set-field
function ISInventoryPane:onMouseMove(dx, dy)
    ORIGINAL_ISInventoryPane_onMouseMove(self, dx, dy);
    if DelranDragToPlace.placingItem and DelranDragToPlace.startedFrom == self and not DelranDragToPlace.hidden then
        DelranDragToPlace:HideCursor();
    end
end

---@diagnostic disable-next-line: duplicate-set-field
function ISInventoryPane:onMouseUpOutside(dx, dy)
    --DelranDragToPlace.WaitBeforeShowCursorTimer:Reset();
    if not DelranDragToPlace.hidden and self == DelranDragToPlace.startedFrom and DelranDragToPlace.placingItem and not IsMouseOverUi() then
        DelranDragToPlace:PlaceItem();
    else
        ORIGINAL_ISInventoryPane_onMouseUpOutside(self, dx, dy);
        if self == DelranDragToPlace.startedFrom then
            self.dragging = nil;
            DelranDragToPlace:Finish();
        end;
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
