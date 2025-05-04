local activatedMods = getActivatedMods();
if not activatedMods:contains("INVENTORY_TETRIS") then return end;

local DragToPlace = require("DelranDragToPlace/DelranDragToPlace_Main");
local DelranUtils = require("DelranDragToPlace/DelranLib/DelranUtils");
local UICodeRunner = require("DelranDragToPlace/DelranDragToPlace_UICodeRunner");

require "EquipmentUI/DragAndDrop"
require "InventoryTetris/Patches/Core/DragAndDrop_TetrisExtensions"
require "InventoryTetris/ItemGrid/UI/Container/ItemGridContainerUI"
require "InventoryTetris/ItemGrid/UI/TetrisDragItemRenderer"
require "EquipmentUI/UI/EquipmentUI"
require "EquipmentUI/UI/EquipmentSlot"
require "EquipmentUI/UI/EquipmentSuperSlot"
require "EquipmentUI/UI/WeaponSlot"
require "EquipmentUI/UI/HotbarSlot"


local dprint = DelranUtils.GetDebugPrint("[DRAG TO PLACE, TETRIS PATCH]");
dprint("Loading module");
local DragAndDrop = DragAndDrop;
local DragItemRenderer = DragItemRenderer;
--local ItemGridUI = require("InventoryTetris/UI/Grid/ItemGridUI_rendering");
local ItemGridContainerUI = ItemGridContainerUI;

---@return InventoryItem[] | nil
local function getItemFromDragAndDrop()
    ---@type ISInventoryPaneDraggedItems
    local vanillaStack = DragAndDrop.getDraggedStack();
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
    if not DragToPlace.placingItem and DragAndDrop:isDragging() then
        local draggedItems = getItemFromDragAndDrop();
        if draggedItems then
            DragToPlace:Start(getPlayer(), draggedItems, self);
        end
    end
end

--- Disabling onMouseMoveOutside otherwise an error occurs
---@diagnostic disable-next-line: duplicate-set-field
function ISInventoryPane:onMouseMoveOutside(dx, dy)
end

ORIGINAL_UICodeRunner_onMouseUpOutside = ORIGINAL_UICodeRunner_onMouseUpOutside or UICodeRunner.onMouseUpOutside;
function UICodeRunner:onMouseUpOutside(x, y)
    local playerNum = self.dragToPlace.playerIndex;
    ORIGINAL_UICodeRunner_onMouseUpOutside(self);
    --- Code from equipmentUI will not run when the inventory page are closed.
    --- We we finish a drag while the inventory page is closed, we finish the
    --- equipmentUI drag ourselves.
    if not self.dragToPlace.playerInventory:isVisible() then
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

ORIGINAL_DragToPlace_PlaceItem = ORIGINAL_DragToPlace_PlaceItem or DragToPlace.PlaceItem;
---@diagnostic disable-next-line: duplicate-set-field
function DragToPlace:PlaceItem()
    local canceled = self.canceled;
    ORIGINAL_DragToPlace_PlaceItem(self);
    if not canceled then
        DragAndDrop.endDrag();
    end
end
