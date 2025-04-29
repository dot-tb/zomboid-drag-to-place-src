if not getActivatedMods():contains("\\INVENTORY_TETRIS") then return end;

local DragToPlace = require("DelranDragToPlace/DelranDragToPlace_Main");
local DelranUtils = require("DelranDragToPlace/DelranLib/DelranUtils");

local dprint = DelranUtils.GetDebugPrint("[DRAG TO PLACE, TETRIS PATCH]")

local DragAndDrop = require("InventoryTetris/System/DragAndDrop");
local DragItemRenderer = require("InventoryTetris/UI/TetrisDragItemRenderer");

local UICodeRunner = require("DelranDragToPlace/DelranDragToPlace_UICodeRunner")

---@return InventoryItem[] | nil
local function getItemFromDragAndDrop()
    ---@type ISInventoryPaneDraggedItems
    local vanillaStack = DragAndDrop.getDraggedStacks();
    if not vanillaStack then return nil end;

    local draggedItems = nil;
    if vanillaStack.items then
        -- Handle drag and drop from EquipmentUI
        draggedItems = vanillaStack.items;
    elseif vanillaStack[1] and not vanillaStack[2] then
        -- Handle drag and drop from ItemGridUI
        local draggedStack = vanillaStack[1];
        if draggedStack.count == 2 then
            draggedItems = { draggedStack.items[1] };
        end
    end
    return draggedItems;
end

---@diagnostic disable-next-line: duplicate-set-field
function ISInventoryPane:onMouseMove(dx, dy)
    if DragToPlace.placingItem then
        if DragToPlace.startedFrom == self and not DragToPlace.hidden then
            DragToPlace:HideCursor();
        end
    elseif DragAndDrop:isDragging() then
        local draggedItems = getItemFromDragAndDrop();
        if draggedItems then
            DragToPlace:Start(getPlayer(), draggedItems, self);
        end
    end
end

---@diagnostic disable-next-line: duplicate-set-field
function ISInventoryPane:onMouseMoveOutside(dx, dy)
    --ORIGINAL_ISInventoryPane_onMouseMoveOutside(self);
    if not DragToPlace.placingItem and DragAndDrop:isDragging() then
        local draggedItems = getItemFromDragAndDrop();
        if not draggedItems then return end;
        DragToPlace:Start(getPlayer(), draggedItems, self);
    end
end

ORIGINAL_UICodeRunner_onMouseUpOutside = ORIGINAL_UICodeRunner_onMouseUpOutside or UICodeRunner.onMouseUpOutside;
function UICodeRunner:onMouseUpOutside(x, y)
    local playerNum = self.dragToPlace.playerIndex;
    ORIGINAL_UICodeRunner_onMouseUpOutside(self);
    if not self.dragToPlace.playerInventory:isVisible() then
        --- Canceling InventoryTetris drag and dropping the dragged item.
        DragAndDrop.ownersForCancel[ISMouseDrag.dragOwner] = {
            callback = function()
                local stack = DragAndDrop.getDraggedStack();
                if not stack or not stack.items then return end;

                local item = stack.items[1];
                if not item then return end;
                ISInventoryPaneContextMenu.dropItem(item, playerNum);
            end
        }
    end
end

-- Disable the rendering of the dragged item when placing it in the world
ORIGINAL_DragItemRenderer_render = ORIGINAL_DragItemRenderer_render or DragItemRenderer.render;
---@diagnostic disable-next-line: duplicate-set-field
function DragItemRenderer:render()
    -- Disabling Inventory tetris drag renderer if the 3d cursor is visible
    if DragToPlace:IsVisible() then return end;
    ORIGINAL_DragItemRenderer_render(self);
end

-- Override IsDragging to return false when we are placing an item.
ORIGINAL_DragAndDrop_isDragging = ORIGINAL_DragAndDrop_isDragging or DragAndDrop.isDragging;
---@diagnostic disable-next-line: duplicate-set-field
function DragAndDrop:isDragging()
    -- Disabling Inventory tetris drag renderer if the 3d cursor is visible
    if DragToPlace:IsVisible() then return false end;
    return ORIGINAL_DragAndDrop_isDragging(self);
end
