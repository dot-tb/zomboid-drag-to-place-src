if not getActivatedMods():contains("\\INVENTORY_TETRIS") then return end;

local DragToPlace = require("DelranDragToPlace/DelranDragToPlace_Main");
local DelranUtils = require("DelranDragToPlace/DelranLib/DelranUtils");

local dprint = DelranUtils.GetDebugPrint("[DRAG TO PLACE, TETRIS PATCH]")

local DragAndDrop = require("InventoryTetris/System/DragAndDrop");
local DragItemRenderer = require("InventoryTetris/UI/TetrisDragItemRenderer");

---@return InventoryItem[]
local function getItemFromDragAndDrop()
    ---@type ISInventoryPaneDraggedItems
    local vanillaStack = DragAndDrop.getDraggedStacks();
    if not vanillaStack then return end;

    local draggedItems = nil;
    if vanillaStack.items then
        -- Handle drag and drop from EquipmentUI
        draggedItems = vanillaStack.items;
    elseif vanillaStack[1] then
        draggedItems = { vanillaStack[1].items[1] };
        -- Handle drag and drop from ItemGridUI
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
        DragToPlace:Start(getPlayer(), draggedItems, self);
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
