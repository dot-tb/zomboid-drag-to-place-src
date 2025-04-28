local DelranUtils = require("DelranDragToPlace/DelranLib/DelranUtils")

--- UI Class to run UI code even when inventory panes are closed.
---@class UICodeRunner : ISPanel
---@field dragToPlace DelranDragToPlace
local UICodeRunner = ISPanel:derive("UICodeRunner")

---@param dragToPlace DelranDragToPlace
---@return UICodeRunner
function UICodeRunner:new(dragToPlace)
    local o = ISPanel:new(0, 0, 0, 0)
    setmetatable(o, self)
    self.__index = self
    ---@cast o UICodeRunner
    o.dragToPlace = dragToPlace;
    return o
end

function UICodeRunner:onMouseUpOutside(x, y)
    if self.dragToPlace:IsHidden() then
        self.dragToPlace:Stop();
    else
        self.dragToPlace:PlaceItem();
    end
end

function UICodeRunner:onMouseMoveOutside(x, y)
    local isMouseOverUI = DelranUtils.IsMouseOverUI();
    if self.dragToPlace.hidden and not isMouseOverUI then
        self.dragToPlace:StartShowCursorTimer();
    elseif not self.dragToPlace.hidden and isMouseOverUI then
        self.dragToPlace:HideCursor();
    end
end

return UICodeRunner;
