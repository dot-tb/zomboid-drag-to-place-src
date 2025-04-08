if not getActivatedMods():contains("\\INVENTORY_TETRIS") then return end;

DragToPlace = require("DelranDragToPlace/DelranDragToPlace_Main");
DelranUtils = require("DelranDragToPlace/DelranLib/DelranUtils");

local dprint = DelranUtils.GetDebugPrint("[DRAG TO PLACE, TETRIS PATCH]")

local DragAndDrop = require("InventoryTetris/System/DragAndDrop");
local DragItemRenderer = require("InventoryTetris/UI/TetrisDragItemRenderer");
local ItemGridUI = require("InventoryTetris/UI/Grid/ItemGridUI_rendering");
local ItemGridContainerUI = require("InventoryTetris/UI/Container/ItemGridContainerUI")

---@diagnostic disable-next-line: duplicate-set-field
function ISInventoryPane:onMouseMove(dx, dy)
    --[[
        if true then return end;
        --]]
    --dprint("onMouseMove")
    --ORIGINAL_ISInventoryPane_onMouseMove(self);
    if DragToPlace.placingItem and DragToPlace.startedFrom == self and not DragToPlace.hidden then
        DragToPlace:HideCursor();
    end
end

---@diagnostic disable-next-line: duplicate-set-field
function ISInventoryPane:onMouseMoveOutside(dx, dy)
    --ORIGINAL_ISInventoryPane_onMouseMoveOutside(self);
    --dprint("onMouseMoveOutside")
    if DragToPlace.placingItem and DragToPlace.startedFrom == self then
        local isMouseOverUI = DelranUtils.IsMouseOverUI();
        if DragToPlace:IsHidden() and not isMouseOverUI then
            DragToPlace:StartShowCursorTimer();
        elseif DragToPlace:IsVisible() and isMouseOverUI then
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
            dprint("Starting new drag")
            DragToPlace:Start(getPlayer(), draggedItems, self);
        end
    end
end

--[[
ORIGINAL_DragToPlace_ShowCursor = ORIGINAL_DragToPlace_ShowCursor or DragToPlace.ShowCursor;
---@diagnostic disable-next-line: duplicate-set-field
function DragToPlace:ShowCursor()
    ORIGINAL_DragToPlace_ShowCursor(self);
end
 ]]

ORIGINAL_DragItemRenderer_render = ORIGINAL_DragItemRenderer_render or DragItemRenderer.render;
---@diagnostic disable-next-line: duplicate-set-field
function DragItemRenderer:render()
    -- Disabling Inventory tetris drag renderer if the 3d cursor is visible
    if DragToPlace:IsVisible() then return end;
    ORIGINAL_DragItemRenderer_render(self);
end

local EquipmentUITypes = { "EquipmentUI", "EquipmentSlot", "EquipmentSuperSlot", "WeaponSlot", "HotbarSlot" }

local function CancelOnMouseUp(UIElement)
    -- Event should always come from an ISInventoryPane, except for EquipmentUI
    if UIElement.Type ~= "ISInventoryPane" then
        -- If we got a mouse up on a EquipmentUI ui, stop no matter what
        for _, EquipmentUIType in ipairs(EquipmentUITypes) do
            if EquipmentUIType == UIElement.Type then
                DragToPlace:Stop();
                break
            end
        end
        -- If the cursor is hidden, it means that we are over UI,
        --   then we need to cancel the drag
    elseif DragToPlace.placingItem and DragToPlace:IsHidden() then
        DragToPlace:Stop();
    end
end

-- I have no idea wtf I am doingg

---@diagnostic disable-next-line: duplicate-set-field
function ISInventoryPane:onMouseUpOutside(x, y)
    --ORIGINAL_ISInventoryPane_onMouseUpOutside(self, x, y);
    --DelranDragToPlace.WaitBeforeShowCursorTimer:Reset();
    if not DragToPlace.hidden and self == DragToPlace.startedFrom then
        DragToPlace:PlaceItem();
    else
        ORIGINAL_ISInventoryPane_onMouseUpOutside(self, x, y);
        CancelOnMouseUp(self);
    end
end

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
ORIGINAL_EquipmentUI_onMouseUp = ORIGINAL_EquipmentUI_onMouseUp or EquipmentUI.onMouseUp;
function EquipmentUI:onMouseUp(x, y)
    CancelOnMouseUp(self);
    ORIGINAL_EquipmentUI_onMouseUp(self, x, y);
end

ORIGINAL_EquipmentSlot_onMouseUp = ORIGINAL_EquipmentSlot_onMouseUp or EquipmentSlot.onMouseUp;
function EquipmentSlot:onMouseUp(x, y)
    CancelOnMouseUp(self);
    ORIGINAL_EquipmentSlot_onMouseUp(self, x, y);
end

ORIGINAL_EquipmentSuperSlot_onMouseUp = ORIGINAL_EquipmentSuperSlot_onMouseUp or EquipmentSuperSlot.onMouseUp;
function EquipmentSuperSlot:onMouseUp(x, y)
    CancelOnMouseUp(self);
    ORIGINAL_EquipmentSuperSlot_onMouseUp(self, x, y);
end

ORIGINAL_WeaponSlot_onMouseUp = ORIGINAL_WeaponSlot_onMouseUp or WeaponSlot.onMouseUp;
function WeaponSlot:onMouseUp(x, y)
    CancelOnMouseUp(self);
    ORIGINAL_WeaponSlot_onMouseUp(self, x, y);
end

ORIGINAL_HotbarSlot_onMouseUp = ORIGINAL_HotbarSlot_onMouseUp or HotbarSlot.onMouseUp;
function HotbarSlot:onMouseUp(x, y)
    CancelOnMouseUp(self);
    ORIGINAL_HotbarSlot_onMouseUp(self, x, y);
end
