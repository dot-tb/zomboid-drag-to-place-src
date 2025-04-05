local function dprint(...)
    if isDebugEnabled() then
        print("[DELRAN'S DRAG TO PLACE]: ", ...);
    end
end

if not ORIGINAL_ISObjectClickHandler_doRClick then
    ORIGINAL_ISObjectClickHandler_doRClick = ISObjectClickHandler.doRClick;
end
ISObjectClickHandler.doRClick = function(object, x, y)
    ORIGINAL_ISObjectClickHandler_doRClick(object, x, y);
    if true then return end;
    if instanceof(object, "IsoObject") then
        --sq = object:getCurrentSquare();
        dprint("BOOP")
        ---@type IsoObject
        local isoObject = object;
        dprint(isoObject);
        local square = isoObject:getSquare();
        local objects = square:getWorldObjects();
        for i = 0, objects:size() - 1, 1 do
            ---@type IsoWorldInventoryObject
            local worldObect = objects:get(i);
            if instanceof(worldObect, "IsoWorldInventoryObject") then
                dprint(worldObect:getSprite());
                dprint(worldObect:getWorldPosX())
                dprint(worldObect:getWorldPosY())
                ---dprint(worldObect:getWorldPosZ())
                dprint(screenToIsoX(getPlayer():getIndex(), x, y, getPlayer():getZ()));
                dprint(screenToIsoY(getPlayer():getIndex(), x, y, getPlayer():getZ()));

                dprint(IsoObjectPicker.Instance:Pick(x, y));
            end
        end
    end
end

--[[
Ressources
ISInventoryPage.onKeyPressed = function(key)
	if getCore():isKey("Toggle Inventory", key) and getSpecificPlayer(0) and getGameSpeed() > 0 and getPlayerInventory(0) and getCore():getGameMode() ~= "Tutorial" then
        getPlayerInventory(0):setVisible(not getPlayerInventory(0):getIsVisible());
        getPlayerLoot(0):setVisible(getPlayerInventory(0):getIsVisible());
    end
end
]]
