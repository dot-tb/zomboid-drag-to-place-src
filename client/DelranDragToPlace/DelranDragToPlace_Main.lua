local TileFinder = require("DelranDragToPlace/DelranLib/DelranTileFinder");
local DelranUtils = require("DelranDragToPlace/DelranLib/DelranUtils");

local dprint = DelranUtils.GetDebugPrint("[DELRAN'S DRAG TO PLACE]");

local keyBinding = keyBinding;
local Keyboard = Keyboard;
local dragToPlaceRotateKey = "drag_to_place_left_rotate_key";
local bind = {};
bind.value = dragToPlaceRotateKey;
bind.key = Keyboard.KEY_LSHIFT;
table.insert(keyBinding, bind);

local Core = getCore();

--- UI Class to run UI code even when inventory panes are closed.
---@class CodeRunnerUI : ISPanel
---@field dragToPlace DelranDragToPlace
local CodeRunnerUI = ISPanel:derive("CodeRunnerUI")

---@param dragToPlace DelranDragToPlace
---@return CodeRunnerUI
function CodeRunnerUI:new(dragToPlace)
    local o = ISPanel:new(0, 0, 0, 0)
    setmetatable(o, self)
    self.__index = self
    ---@cast o CodeRunnerUI
    o.dragToPlace = dragToPlace;
    return o
end

function CodeRunnerUI:onMouseUpOutside(x, y)
    if not self.dragToPlace.canceled and DelranUtils.IsMouseOverUI() then
        self.dragToPlace:Stop();
    end
end

function CodeRunnerUI:onMouseMoveOutside(x, y)
    local isMouseOverUI = DelranUtils.IsMouseOverUI();
    if self.dragToPlace.hidden and not isMouseOverUI then
        self.dragToPlace:StartShowCursorTimer();
    elseif not self.dragToPlace.hidden and isMouseOverUI then
        self.dragToPlace:HideCursor();
    end
    --self.dragToPlace:OnMouseMove(x, y);
end

---@class DelranDragToPlace
---@field player IsoPlayer
---@field playerInventory ISInventoryPage
---@field playerIndex integer
---@field draggedItems InventoryItem[]
---@field actualDraggedItem InventoryItem
---@field startedFrom ISInventoryPane
---@field lootInventoryPage ISInventoryPage
---@field placeItemCursor ISPlace3DItemCursor
---@field codeRunner CodeRunnerUI
---@field placingItem boolean
---@field hidden boolean
---@field canceled boolean
---Probably should make a class out of that, and switch the object to have multiple modes
---@field rotating {square: IsoGridSquare, rotation: number, initialAngle: number, startingAngle: number|nil, x: number|nil , y: number|nil, z: number|nil}
local DelranDragToPlace = {};

DelranDragToPlace.player = nil;
DelranDragToPlace.playerInventory = nil;
DelranDragToPlace.playerIndex = nil;
DelranDragToPlace.draggedItems = nil;
DelranDragToPlace.actualDraggedItem = nil;
DelranDragToPlace.startedFrom = nil;
DelranDragToPlace.placeItemCursor = nil;
DelranDragToPlace.codeRunner = nil;

DelranDragToPlace.hidden = true;
DelranDragToPlace.placingItem = false;
DelranDragToPlace.canceled = false;

DelranDragToPlace.options = require("DelranDragToPlace/DelranDragToPlace_ModOptions");

---@param player IsoPlayer
---@param draggedItems InventoryItem[]
---@param startedFrom ISInventoryPane
function DelranDragToPlace:Start(player, draggedItems, startedFrom)
    self.placingItem = true;
    self.startedFrom = startedFrom;

    self.player = player;
    self.startDirection = self.player:getDirectionAngle();
    self.playerIndex = self.player:getIndex();
    self.playerInventory = getPlayerInventory(self.playerIndex);

    self.lootInventoryPage = getPlayerLoot(self.playerIndex);

    self.draggedItems = draggedItems;
    self.actualDraggedItem = draggedItems[1];
    ---@type ISInventoryPane
    local inventoryPane = self.lootInventoryPage.inventoryPane;
    self.startingContainer = inventoryPane.inventory;

    self.placeItemCursor = ISPlace3DItemCursor:new(self.player, self.draggedItems);
    if self.actualDraggedItem:getWorldItem() then
        self.placeItemCursor.render3DItemRot = self.actualDraggedItem:getWorldZRotation();
    end
    self.WaitBeforeShowCursorTimer:Start(self.startedFrom);

    function OnPlayerMoveTemp(_player)
        self:OnPlayerMove(_player);
    end

    function DelranDragToPlace.OnKeyPressed(key)
        if Core:isKey("Toggle Inventory", key) then
            --self.playerInventory.inventoryPane:clearWorldObjectHighlights();
            if not self.playerInventory:getIsVisible() and not self:IsVisible() then
                self:ShowCursor();
            end
        elseif Core:isKey(dragToPlaceRotateKey, key) then
            --Rotate key released
            if not self.rotating then
                local rotation = self.placeItemCursor.render3DItemRot;
                self.rotating = { square = self.placeItemCursor.square, rotation = rotation, initialAngle = rotation, startingAngle = nil };

                function DelranDragToPlace.Rotate3DCursorOnMouseMove(x, y)
                    if not self.placingItem then
                        self.rotating = nil;
                        Events.OnMouseMove.Remove(self.Rotate3DCursorOnMouseMove);
                        return;
                    end
                    local rx = self.rotating.x;
                    local ry = self.rotating.y;
                    if not rx or not ry then return end;
                    local z = self.player:getZ();
                    local isoX = screenToIsoX(self.playerIndex, x, y, self.rotating.z);
                    local isoY = screenToIsoY(self.playerIndex, x, y, self.rotating.z);

                    local newAngle = math.atan2(isoY - ry, isoX - rx);
                    -- Keep the radians in the positive
                    dprint("Radians : ", newAngle)
                    newAngle = (newAngle + 6.28) % 6.28;
                    dprint("Positive Radians : ", newAngle)
                    -- Convert to degrees
                    newAngle = newAngle * 180 / 3.14;
                    dprint("degrees : ", newAngle)
                    if not self.rotating.startingAngle then
                        if newAngle ~= 0 then
                            self.rotating.startingAngle = newAngle;
                        end
                    else
                        local delta = (newAngle - self.rotating.startingAngle + 360) % 360;
                        local finalAngle = self.rotating.initialAngle + delta;
                        self.rotating.rotation = finalAngle;
                        self.placeItemCursor.render3DItemRot = finalAngle;
                    end
                end

                Events.OnMouseMove.Add(DelranDragToPlace.Rotate3DCursorOnMouseMove);
            else
                self.rotating = nil;
                Events.OnMouseMove.Remove(DelranDragToPlace.Rotate3DCursorOnMouseMove);
            end
        end
    end

    function DelranDragToPlace.OnMouseUp(x, y)
        self:PlaceItem();
    end

    self.codeRunner = CodeRunnerUI:new(self);
    self.codeRunner:addToUIManager();

    Events.OnMouseUp.Add(DelranDragToPlace.OnMouseUp);
    Events.OnPlayerMove.Add(OnPlayerMoveTemp);
    Events.OnKeyPressed.Add(DelranDragToPlace.OnKeyPressed);
end

function DelranDragToPlace:Stop()
    self.codeRunner:removeFromUIManager();
    self.codeRunner = nil;
    -- Hide the 3D cursor
    if not self.hidden then
        ---@diagnostic disable-next-line: param-type-mismatch
        getCell():setDrag(nil, self.playerIndex);
    end

    Events.OnPlayerMove.Remove(OnPlayerMoveTemp);
    Events.OnKeyPressed.Remove(DelranDragToPlace.OnKeyPressed);
    Events.OnMouseUp.Remove(DelranDragToPlace.OnMouseUp);
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
    getCell():setDrag(self.placeItemCursor, self.playerIndex);
end

---@param resetDirection? boolean
function DelranDragToPlace:HideCursor(resetDirection)
    if self.canceled or self.hidden then return end
    self.hidden = true;
    -- Set drag to nil, the 3d cursor will disapear but not be deleted
    ---@diagnostic disable-next-line: param-type-mismatch
    getCell():setDrag(nil, self.playerIndex);

    resetDirection = resetDirection == nil or resetDirection;
    if resetDirection then
        ---@type ISInventoryPage
        local lootInventoryPage = getPlayerLoot(self.playerIndex);
        self.player:setDirectionAngle(self.startDirection);

        if self.player:shouldBeTurning() then
            lootInventoryPage:setForceSelectedContainer(self.startingContainer)
        end
        lootInventoryPage:selectButtonForContainer(self.startingContainer)
    end

    -- Let the ISInventoryPane draw the dragged inventory item
    self.startedFrom.dragging = 1;
end

function DelranDragToPlace:PlaceItem()
    if self.canceled then return end
    self:HideCursor(false);
    -- Get the dragged item from the ISInventoryPane
    -- There should only be one as we don't start the drag if there is more than one dragged item
    local draggedItem = self.actualDraggedItem;
    local worldItem = draggedItem:getWorldItem();
    local tileFinder = TileFinder:BuildForPlayer(self.player);
    local pickupSquare = nil;
    if worldItem then
        local itemSquare = worldItem:getSquare();
        if not tileFinder:IsNextToSquare(itemSquare) then
            -- If the item is in the world, walk next to it first
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
    local dropSquare = self.rotating and self.rotating.square or self.placeItemCursor.selectedSqDrop;
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

    local x = 0;
    local y = 0;

    if self.rotating then
        x = self.rotating.x;
        y = self.rotating.y;
        self.placeItemCursor.render3DItemXOffset = x - dropSquare:getX();
        self.placeItemCursor.render3DItemYOffset = y - dropSquare:getY();
        self.placeItemCursor.render3DItemZOffset = self.rotating.z;
        self.placeItemCursor.render3DItemRot = self.rotating.rotation;
    else
        x = screenToIsoX(self.playerIndex, getMouseX(), getMouseY(), self.player:getZ());
        y = screenToIsoY(self.playerIndex, getMouseX(), getMouseY(), self.player:getZ());
    end

    ISTimedActionQueue.add(FaceCoordinatesAction:new(self.player, x, y));
    -- Finaly, drop the item at the position and rotation of the cursor.
    ISTimedActionQueue.add(ISDropWorldItemAction:new(self.player, draggedItem, dropSquare,
        self.placeItemCursor.render3DItemXOffset, self.placeItemCursor.render3DItemYOffset,
        self.placeItemCursor.render3DItemZOffset, self.placeItemCursor.render3DItemRot, false));
    -- Clean and stop
    self.canceled = true;
    ISTimedActionQueue.add(ExecuteCallbackAction:new(self.player, function()
        self:Stop();
    end));
end

---@param player IsoPlayer
function DelranDragToPlace:OnPlayerMove(player)
    if player == self.player then
        self.startDirection = player:getDirectionAngle();
    end
end

function DelranDragToPlace:IsHidden()
    return not self.placingItem or self.hidden;
end

function DelranDragToPlace:IsVisible()
    return self.placingItem and not self.hidden;
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

    function UpdateDragToPlaceTimer(gameTick)
        self:UpdateTimer(gameTick);
    end

    Events.OnTick.Add(UpdateDragToPlaceTimer);
end

function DelranDragToPlace.WaitBeforeShowCursorTimer:Reset()
    Events.OnTick.Remove(UpdateDragToPlaceTimer);
    self.ticksElapsed = 0;
    self.owner = nil;
end

function DelranDragToPlace:IsInventoryPaneDragging()
end

---@diagnostic disable-next-line: duplicate-set-field
function ISInventoryPane:onMouseMoveOutside(dx, dy)
    ORIGINAL_ISInventoryPane_onMouseMoveOutside(self, dx, dy);
    if not DelranDragToPlace.placingItem and self.dragging and self.draggedItems and self.draggedItems.items and #self.draggedItems.items == 1 then
        DelranDragToPlace:Start(getPlayer(), self.draggedItems.items, self);
    end
end

---@diagnostic disable-next-line: duplicate-set-field
function ISInventoryPane:onMouseMove(dx, dy)
    ORIGINAL_ISInventoryPane_onMouseMove(self, dx, dy);
    if DelranDragToPlace.placingItem then
        if DelranDragToPlace.startedFrom == self and not DelranDragToPlace.hidden then
            DelranDragToPlace:HideCursor();
        end
    elseif self.dragging and self.draggedItems and self.draggedItems.items and #self.draggedItems.items == 1 then
        DelranDragToPlace:Start(getPlayer(), self.draggedItems.items, self);
    end
end

---@diagnostic disable-next-line: duplicate-set-field
function ISInventoryPane:onMouseUp(dx, dy)
    if DelranDragToPlace.placingItem then
        DelranDragToPlace:Stop();
    end
    ORIGINAL_ISInventoryPane_onMouseUp(self, dx, dy);
end

-- ISInventoryPane will catch the fact that we are trying to drop an item
-- inside the update function, we hijack the drop item function to cancel
-- the drop if the dragging player is trying to drop the dragged item.
ORIGINAL_ISUnequip_new = ORIGINAL_ISUnequip_new or ISInventoryPaneContextMenu.dropItem;
---@diagnostic disable-next-line: duplicate-set-field
function ISInventoryPaneContextMenu.dropItem(item, player)
    if DelranDragToPlace.placingItem then
        if DelranDragToPlace.playerIndex == player and DelranDragToPlace.actualDraggedItem == item then
            return
        end
    end
    ORIGINAL_ISUnequip_new(item, player);
end

OG_RENDER_3D_ITEM = OG_RENDER_3D_ITEM or Render3DItem;
---@param item InventoryItem
---@param sq IsoGridSquare
---@param xoffset number
---@param yoffset number
---@param zoffset number
---@param rotation number
function Render3DItem(item, sq, xoffset, yoffset, zoffset, rotation)
    local dtp = DelranDragToPlace;
    if dtp.placingItem and dtp.actualDraggedItem == item and dtp.rotating then
        local rotateData = dtp.rotating;
        if not rotateData.x or not rotateData.y or not rotateData.z then
            rotateData.x = xoffset;
            rotateData.y = yoffset;
            rotateData.z = zoffset;
        end
        OG_RENDER_3D_ITEM(item, sq, rotateData.x, rotateData.y, rotateData.z,
            rotateData.rotation);
        return;
    end
    OG_RENDER_3D_ITEM(item, sq, xoffset, yoffset, zoffset, rotation);
end

return DelranDragToPlace
