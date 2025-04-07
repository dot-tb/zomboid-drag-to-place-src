if not getActivatedMods():contains("\\INVENTORY_TETRIS") then return end;

DragToPlace = require("DelranDragToPlace/DelranDragToPlace_Main");
DelranUtils = require("DelranDragToPlace/DelranLib/DelranUtils");

local dprint = DelranUtils.GetDebugPrint("[DRAG TO PLACE, TETRIS PATCH]")

local DragAndDrop = require("InventoryTetris/System/DragAndDrop");
local DragItemRenderer = require("InventoryTetris/UI/TetrisDragItemRenderer");
local ItemGridUI = require("InventoryTetris/UI/Grid/ItemGridUI_rendering");
local renderDrag = true;

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

--[[
---@diagnostic disable-next-line: duplicate-set-field
function ISInventoryPane:onMouseUpOutside(dx, dy)
    ORIGINAL_ISInventoryPane_onMouseUpOutside(self);
end
--]]

---@diagnostic disable-next-line: duplicate-set-field
function ISInventoryPane:onMouseMoveOutside(dx, dy)
    --[[
        if true then return end;
        --]]
    --ORIGINAL_ISInventoryPane_onMouseMoveOutside(self);
    --dprint("onMouseMoveOutside")
    if DragToPlace.placingItem and DragToPlace.startedFrom == self then
        local isMouseOverUI = DelranUtils.IsMouseOverUI();
        if DragToPlace.hidden and not isMouseOverUI then
            DragToPlace:StartShowCursorTimer();
        elseif not DragToPlace.hidden and isMouseOverUI then
            DragToPlace:HideCursor();
            renderDrag = true;
        end
    elseif DragAndDrop:isDragging() then
        local vanillaStack = DragAndDrop.getDraggedStacks();
        if DragToPlace.placingItem or not vanillaStack or #vanillaStack ~= 1 then return end;
        DragToPlace:Start(getPlayer(), { vanillaStack[1].items[1] }, self);
    end
end

ORIGINAL_DragToPlace_ShowCursor = ORIGINAL_DragToPlace_ShowCursor or DragToPlace.ShowCursor;
---@diagnostic disable-next-line: duplicate-set-field
function DragToPlace:ShowCursor()
    ORIGINAL_DragToPlace_ShowCursor(self);
    renderDrag = false;
end

ORIGINAL_DragItemRenderer_render = ORIGINAL_DragItemRenderer_render or DragItemRenderer.render;
---@diagnostic disable-next-line: duplicate-set-field
function DragItemRenderer:render()
    if renderDrag then
        ORIGINAL_DragItemRenderer_render(self);
    end
end
