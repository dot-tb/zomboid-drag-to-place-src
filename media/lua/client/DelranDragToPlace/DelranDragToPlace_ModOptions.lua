-- These are the settings.
local SETTINGS = {
    ---@class DragToPlaceOptions
    ---@field faceItemWhilePlacing boolean
    ---@field collapseUiOnShowCursor boolean
    ---@field rotateModeEnabled boolean
    options = {
        faceItemWhilePlacing = false,
        collapseUiOnShowCursor = true,
        rotateModeEnabled = true,
    },
    names = {
        faceItemWhilePlacing = "Face item while placing",
        collapseUiOnShowCursor = "Collapse the inventory when placing an item",
        rotateModeEnabled = "Enable rotate mode",
    },
    tooltips = {
        faceItemWhilePlacing =
        "If unchecked, unlike in vanilla, the player will not turn around and look at the item while you're placing it.",
        collapseUiOnShowCursor =
        "If checked, the inventory windows will collapse when an item is being placed using this mod.",
        rotateModeEnabled =
        "If checked, you can use the rotate key keybind to enable the rotate mode which allows you to rotate the item using the mouse.",
    },
    mod_id = "DelranDragToPlace",
    mod_shortname = "Drag To Place",
    mod_fullname = "Delran's Drag To Place",
}

-- Connecting the settings to the menu, so user can change them.
if ModOptions and ModOptions.getInstance then
    local modOptions = ModOptions:getInstance(SETTINGS)

    local key_data = {
        key = Keyboard.KEY_R,
        name = "DelranDragToPlaceRotateKeybind",
    }
    ModOptions:AddKeyBinding("[Drag To Place]", key_data);

    local faceItemWhilePlacingOption = modOptions:getData("faceItemWhilePlacing");
    local collapseUiOnShowCursorOption = modOptions:getData("collapseUiOnShowCursor");
    local rotateModeEnabledOption = modOptions:getData("rotateModeEnabled");

    faceItemWhilePlacingOption.tooltip =
    "If unchecked, unlike in vanilla, the player will not turn around and look at the item while you're placing it.";
    collapseUiOnShowCursorOption.tooltip =
    "If checked, the inventory windows will collapse when an item is being placed using this mod.";
    rotateModeEnabledOption.tooltip =
    "If checked, you can use the rotate key keybind to enable the rotate mode which allows you to rotate the item using the mouse.";
end


return SETTINGS.options;
