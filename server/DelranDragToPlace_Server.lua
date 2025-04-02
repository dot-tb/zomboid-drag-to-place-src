local function dprint(...)
    if isDebugEnabled() then
        print("[DELRAN'S DRAG TO PLACE]: ", ...);
    end
end

if not ORIGINAL_ISObjectClickHandler_doRClick then
    ORIGINAL_ISObjectClickHandler_doRClick = ISObjectClickHandler.doRClick;
end
ISObjectClickHandler.doRClick = function(object, x, y)
    dprint("BOOPED");
    --ORIGINAL_ISObjectClickHandler_doRClick(object, x, y);
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
