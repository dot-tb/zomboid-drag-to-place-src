local utils = require("DelranDragToPlace/DelranLib/DelranUtils");

local OPTIONS_ID = "DelranDragToPlaceModOptions";

---@type ModOptions.Options
local dragToPlaceOptions = PZAPI.ModOptions:create(OPTIONS_ID, "Drag To Place Options");

dragToPlaceOptions:addDescription("This is the mod options for the Drag To Place mod")

dragToPlaceOptions:addSeparator()
dragToPlaceOptions:addDescription("Should the player follow the item while placing it (In vanilla, this would be true).")
dragToPlaceOptions:addTickBox("DTPFaceItemTickBox", "Face item while placing", false)

---@type {["DTPFaceItemTickBox"]: boolean}
local DragToPlaceOptions = {}

dragToPlaceOptions.apply = utils.ExtractModOptions(DragToPlaceOptions);

Events.OnMainMenuEnter.Add(function()
    dragToPlaceOptions:apply()
end)

return DragToPlaceOptions
