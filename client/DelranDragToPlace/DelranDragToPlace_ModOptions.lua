local utils = require("DelranDragToPlace/DelranLib/DelranUtils");

local OPTIONS_ID = "DelranDragToPlaceModOptions";

---@type ModOptions.Options
local dragToPlaceOptions = PZAPI.ModOptions:create(OPTIONS_ID, "Drag To Place Options");

dragToPlaceOptions:addDescription("This is the mod options for the Drag To Place mod")

dragToPlaceOptions:addSeparator()
dragToPlaceOptions:addDescription("Should the player follow the item while placing it (In vanilla, this would be true).")
dragToPlaceOptions:addTickBox("faceItemWhilePlacing", "Face item while placing", false)

dragToPlaceOptions:addSeparator()
dragToPlaceOptions:addDescription(
    "Enable rotate mode when pressing shif key, placed item will be locked in place and can be rotated using the mouse.")
dragToPlaceOptions:addTickBox("useShiftForRotateMode", "Shift key to rotate", true)

---@class DragToPlaceOptions
---@field faceItemWhilePlacing boolean
---@field useShiftForRotateMode boolean
local DragToPlaceOptions = {}

dragToPlaceOptions.apply = utils.ExtractModOptions(DragToPlaceOptions);

Events.OnMainMenuEnter.Add(function()
    dragToPlaceOptions:apply()
end)

return DragToPlaceOptions
