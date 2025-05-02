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

local EquipmentUITypes = { "EquipmentUI", "EquipmentSlot", "EquipmentSuperSlot", "WeaponSlot", "HotbarSlot" }

ORIGINAL_ItemGridContainerUI_onMouseMoveOutside = ORIGINAL_ItemGridContainerUI_onMouseMoveOutside or
    ItemGridContainerUI.onMouseMoveOutside;
function ItemGridContainerUI:onMouseMoveOutside(x, y)
    ---@diagnostic disable-next-line: duplicate-set-field
    --[[
        if true then return end;
        --]]
    --ORIGINAL_ISInventoryPane_onMouseMoveOutside(self);
    --dprint("onMouseMoveOutside")
    ORIGINAL_ItemGridContainerUI_onMouseMoveOutside(self, x, y);
    --dprint(DragAndDrop:isDragging(), " ", DragToPlace.placingItem)
    --[[     if DragToPlace.placingItem and DragToPlace.startedFrom == self then
        local isMouseOverUI = DelranUtils.IsMouseOverUI();
        if DragToPlace.hidden and not isMouseOverUI then
            DragToPlace:StartShowCursorTimer();
        elseif not DragToPlace.hidden and isMouseOverUI then
            DragToPlace:HideCursor();
        end
    elseif DragAndDrop:isDragging() and not DragToPlace.placingItem then
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
        if draggedItems then
            DragToPlace:Start(getPlayer(), draggedItems, self);
        end
    end ]]
    --CancelOnMouseUp(self);
end

--[[
ORIGINAL_ItemGridContainerUI_onMouseUpOutside = ORIGINAL_ItemGridContainerUI_onMouseUpOutside or
    ItemGridContainerUI.onMouseUpOutside;
function ItemGridContainerUI:onMouseUpOutside(x, y)
    ORIGINAL_ItemGridContainerUI_onMouseUpOutside(self, x, y);
end

ORIGINAL_ItemGridUI_onMouseMoveOutside = ORIGINAL_ItemGridUI_onMouseMoveOutside or ItemGridUI.onMouseMoveOutside;
function ItemGridUI:onMouseMoveOutside(x, y, gridStack)
    --CancelOnMouseUp(self);
    ORIGINAL_ItemGridUI_onMouseMoveOutside(self, x, y, gridStack);
end
 ]]

-- Equipment UI patch
-- Equipment UI only has globals so...
-- Gotta patch each functions, didn't find an unified way to do this,
--     EquipmentUI is kinda of a pain with all the independant ui elements
--[[ ORIGINAL_EquipmentUI_onMouseUp = ORIGINAL_EquipmentUI_onMouseUp or EquipmentUI.onMouseUp;
function EquipmentUI:onMouseUp(x, y)
    CancelOnMouseUp(self);
    ORIGINAL_EquipmentUI_onMouseUp(self, x, y);
end

ORIGINAL_EquipmentSlot_onMouseUp = ORIGINAL_EquipmentSlot_onMouseUp or EquipmentSlot.onMouseUp;
---@diagnostic disable-next-line: duplicate-set-field
function EquipmentSlot:onMouseUp(x, y)
    CancelOnMouseUp(self);
    ORIGINAL_EquipmentSlot_onMouseUp(self, x, y);
end

ORIGINAL_EquipmentSuperSlot_onMouseUp = ORIGINAL_EquipmentSuperSlot_onMouseUp or EquipmentSuperSlot.onMouseUp;
---@diagnostic disable-next-line: duplicate-set-field
function EquipmentSuperSlot:onMouseUp(x, y)
    CancelOnMouseUp(self);
    ORIGINAL_EquipmentSuperSlot_onMouseUp(self, x, y);
end

ORIGINAL_WeaponSlot_onMouseUp = ORIGINAL_WeaponSlot_onMouseUp or WeaponSlot.onMouseUp;
---@diagnostic disable-next-line: duplicate-set-field
function WeaponSlot:onMouseUp(x, y)
    CancelOnMouseUp(self);
    ORIGINAL_WeaponSlot_onMouseUp(self, x, y);
end

ORIGINAL_HotbarSlot_onMouseUp = ORIGINAL_HotbarSlot_onMouseUp or HotbarSlot.onMouseUp;
---@diagnostic disable-next-line: duplicate-set-field
function HotbarSlot:onMouseUp(x, y)
    CancelOnMouseUp(self);
    ORIGINAL_HotbarSlot_onMouseUp(self, x, y);
end ]]
