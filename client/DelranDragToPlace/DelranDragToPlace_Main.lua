local TileFinder = require("DelranDragToPlace/DelranLib/DelranTileFinder");
local DelranUtils = require("DelranDragToPlace/DelranLib/DelranUtils");

local dprint = DelranUtils.GetDebugPrint("[DELRAN'S DRAG TO PLACE]");

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
DelranDragToPlace.canceled = false;

---@param player IsoPlayer
---@param draggedItems InventoryItem[]
---@param startedFrom ISInventoryPane
function DelranDragToPlace:Start(player, draggedItems, startedFrom)
    self.placingItem = true;
    self.startedFrom = startedFrom;

    self.player = player;
    self.startDirection = self.player:getDirectionAngle();
    self.playerIndex = self.player:getIndex();
    self.draggedItems = draggedItems;
    self.actualDraggedItem = draggedItems[1];
    self.startingContainer = self.actualDraggedItem:getContainer();

    self.placeItemCursor = ISPlace3DItemCursor:new(self.player, self.draggedItems);
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

function DelranDragToPlace:Stop()
    -- Hide the 3D cursor
    if not self.hidden then
        ---@diagnostic disable-next-line: param-type-mismatch
        getCell():setDrag(nil, self.playerIndex);
    end

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
    self.canceled = false;
end

---Force DragToPlace to cancel without stopping the UI drag
function DelranDragToPlace:Cancel()
    self:HideCursor();
    self.canceled = true;
end

function DelranDragToPlace:StartShowCursorTimer()
    if self.canceled then return end
    -- Start the show cursor timer
    self.WaitBeforeShowCursorTimer:Start(self.startedFrom);
end

function DelranDragToPlace:ShowCursor()
    -- Setting dragging from the ISInventoryPane to nil will
    --  stop the renderering of the dragged items
    self.startedFrom.dragging = nil;
    self.hidden = false;

    -- Setting drag back to the cursor so it will show on the world
    getCell():setDrag(self.placeItemCursor, self.playerIndex)
end

function DelranDragToPlace:HideCursor()
    if self.canceled then return end
    self.hidden = true;
    -- Set drag to nil, the 3d cursor will disapear but not be deleted
    ---@diagnostic disable-next-line: param-type-mismatch
    getCell():setDrag(nil, self.playerIndex);

    ---@type ISInventoryPage
    local lootInventoryPage = getPlayerLoot(self.playerIndex);
    self.player:setDirectionAngle(self.startDirection);

    if self.player:shouldBeTurning() then
        lootInventoryPage:setForceSelectedContainer(self.actualDraggedItem:getContainer())
    end
    lootInventoryPage:selectButtonForContainer(self.actualDraggedItem:getContainer())

    -- test:setNewContainer(self.startingContainer);
    -- Let the ISInventoryPane draw the dragged inventory item
    self.startedFrom.dragging = 1;
end

function DelranDragToPlace:PlaceItem()
    if self.canceled then return end
    -- Get the dragged item from the ISInventoryPane
    -- There should only be one as we don't start the drag if there is more than one dragged item
    local draggedItem = self.actualDraggedItem;
    local worldItem = draggedItem:getWorldItem();
    local tileFinder = TileFinder:BuildForPlayer(self.player);
    local pickupSquare = nil;
    if worldItem then
        local itemSquare = worldItem:getSquare();
        if not tileFinder:IsNextToSquare(itemSquare) then
            -- If the item is in the world, walk nest to it first
            pickupSquare = tileFinder:Find(itemSquare);
            -- If there is no free square next to the item, we cannot reach it, abort.
            if pickupSquare == nil then
                self:Stop();
                return;
            end
            ISTimedActionQueue.add(ISWalkToTimedAction:new(self.player, pickupSquare));
        end
    end
    -- Transfer the item in the inventory if needed
    ISWorldObjectContextMenu.transferIfNeeded(self.player, draggedItem);
    pickupSquare = pickupSquare or self.player:getSquare();
    tileFinder = TileFinder:BuildForSquare(pickupSquare);
    -- Walk to the square where we want to drop the item
    ---@type IsoGridSquare
    local dropSquare = self.placeItemCursor.selectedSqDrop;
    if not tileFinder:IsNextToSquare(dropSquare) then
        local freeSquare = tileFinder:Find(dropSquare);
        if freeSquare == nil then
            ISTimedActionQueue:clearQueue();
            self:Stop();
            return;
        end
        ISTimedActionQueue.add(ISWalkToTimedAction:new(self.player, freeSquare));
    end
    -- Unequip the item if it is equipped on the player
    if self.player:isEquipped(draggedItem) then
        ISTimedActionQueue.add(ISUnequipAction:new(self.player, draggedItem, 50));
    end
    --self.player:faceDirection();
    local x = screenToIsoX(self.playerIndex, getMouseX(), getMouseY(), self.player:getZ());
    local y = screenToIsoY(self.playerIndex, getMouseX(), getMouseY(), self.player:getZ());
    ISTimedActionQueue.add(FaceCoordinatesAction:new(self.player, x, y));

    -- Finaly, drop the item at the position and rotation of the cursor.
    ISTimedActionQueue.add(ISDropWorldItemAction:new(self.player, draggedItem, dropSquare,
        self.placeItemCursor.render3DItemXOffset, self.placeItemCursor.render3DItemYOffset,
        self.placeItemCursor.render3DItemZOffset, self.placeItemCursor.render3DItemRot, false));
    -- Clean and stop
    self:Stop();
end

---@param player IsoPlayer
function DelranDragToPlace:OnPlayerMove(player)
    if player == self.player then
        self.startDirection = player:getDirectionAngle();
    end
end

function DelranDragToPlace:IsHidden()
    return self.hidden;
end

function DelranDragToPlace:IsVisible()
    return not self.hidden;
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

---@class WaitBeforeShowCursorTimer
DelranDragToPlace.WaitBeforeShowCursorTimer = {}
---@type ISInventoryPane
DelranDragToPlace.WaitBeforeShowCursorTimer.owner = nil;
---@type integer
DelranDragToPlace.WaitBeforeShowCursorTimer.ticksElapsed = 0;
DelranDragToPlace.WaitBeforeShowCursorTimer.TIME_STEP = 2;
DelranDragToPlace.WaitBeforeShowCursorTimer.TICKS_BEFORE_DRAGGING = 20;

function DelranDragToPlace.WaitBeforeShowCursorTimer:UpdateTimer(gameTick)
    if gameTick % self.TIME_STEP ~= 0 then return end;

    -- If the mouse over any UI, reset the timer, we don't show the cursor
    --  unless the mouse is in the gameworld
    if DelranUtils.IsMouseOverUI() then
        self:Reset();
    else
        -- If the mouse is not
        self.ticksElapsed = self.ticksElapsed + self.TIME_STEP;
        if self.ticksElapsed > self.TICKS_BEFORE_DRAGGING then
            DelranDragToPlace:ShowCursor();
            self:Reset();
        end
    end
end

---@param owner ISInventoryPane
function DelranDragToPlace.WaitBeforeShowCursorTimer:Start(owner)
    if self.owner == owner then return end;
    self.owner = owner;
    self.items = self.owner.draggedItems;

    function UpdateDragToPlaceTimer(gameTick)
        self:UpdateTimer(gameTick);
    end

    Events.OnTick.Add(UpdateDragToPlaceTimer);
end

function DelranDragToPlace.WaitBeforeShowCursorTimer:Reset()
    Events.OnTick.Remove(UpdateDragToPlaceTimer);
    self.ticksElapsed = 0;
    self.owner = nil;
    self.items = nil;
end

local DragAndDrop = require("InventoryTetris/System/DragAndDrop");

---@diagnostic disable-next-line: duplicate-set-field
function ISInventoryPane:onMouseMoveOutside(dx, dy)
    ORIGINAL_ISInventoryPane_onMouseMoveOutside(self, dx, dy);
    if DelranDragToPlace.placingItem and DelranDragToPlace.startedFrom == self then
        local isMouseOverUI = DelranUtils.IsMouseOverUI();
        if DelranDragToPlace.hidden and not isMouseOverUI then
            DelranDragToPlace:StartShowCursorTimer();
        elseif not DelranDragToPlace.hidden and isMouseOverUI then
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
    if not DelranDragToPlace.hidden and self == DelranDragToPlace.startedFrom and DelranDragToPlace.placingItem and not DelranUtils.IsMouseOverUI() then
        DelranDragToPlace:PlaceItem();
    else
        ORIGINAL_ISInventoryPane_onMouseUpOutside(self, dx, dy);
        if DelranDragToPlace.placingItem and self == DelranDragToPlace.startedFrom then
            self.dragging = nil;
            DelranDragToPlace:Stop();
        end;
    end
end

---@diagnostic disable-next-line: duplicate-set-field
function ISInventoryPane:onMouseUp(dx, dy)
    if DelranDragToPlace.placingItem then
        DelranDragToPlace:Stop();
    end
    ORIGINAL_ISInventoryPane_onMouseUp(self, dx, dy);
end

return DelranDragToPlace

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
