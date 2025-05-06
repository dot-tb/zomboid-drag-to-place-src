local DelranUtils = {}

local debugEnabled = isDebugEnabled();

---Is the passed InventoryItem a bag ?
---@param item InventoryItem
function DelranUtils.IsBackpack(item)
    if item:IsInventoryContainer() then
        ---@cast item InventoryContainer
        return item:canBeEquipped() == "Back";
    end
    return false
end

function DelranUtils.IsMouseOverUI()
    local uis = UIManager.getUI()
    for i = 0, uis:size() - 1 do
        local ui = uis:get(i)
        if ui:isMouseOver() then
            return true;
        end
    end
    return false;
end

---comment
---@param moduleName string
function DelranUtils.GetDebugPrint(moduleName)
    return function(...)
        if debugEnabled then
            print(moduleName, " ", ...);
        end
    end
end

return DelranUtils
