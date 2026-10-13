// Pure rules shared by the module and offline Quirrel tests.
local Modes = [
    { name = "Operator Mayhem", reinforcements = true },
    { name = "Loadout Roulette", reinforcements = true },
    { name = "Sidearm Showdown", reinforcements = false },
    { name = "Reverse Siege", reinforcements = true },
    { name = "One Tap", reinforcements = true },
    { name = "Frag Wars", reinforcements = false },
    { name = "TCSG Crutch", reinforcements = false },
    { name = "Overdrive", reinforcements = true },
    { name = "Sniper Wars", reinforcements = false },
    { name = "Last Laugh", reinforcements = false },
    { name = "Army Men", reinforcements = false },
    { name = "Oryx Uprising", reinforcements = false },
    { name = "Shoulder Surfing", reinforcements = true }
];

function ValidMode(index) {
    return typeof index == "integer" && index >= 0 && index < Modes.len();
}

function EquipmentKey(index) {
    if (index == 2) return "pistol";
    if (index == 6) return "tcsg";
    if (index == 8) return "sniper";
    return null;
}

function ValidState(payload) {
    if (typeof payload != "table") return false;
    foreach (key in ["type", "protocol", "session", "mode", "active", "randomRound", "revision", "armed", "running"])
        if (!(key in payload)) return false;
    return payload.type == "state" && typeof payload.protocol == "integer" && payload.protocol == 2
        && typeof payload.session == "integer" && payload.session > 0
        && ValidMode(payload.mode) && ValidMode(payload.active)
        && typeof payload.randomRound == "bool" && typeof payload.armed == "bool"
        && typeof payload.running == "bool"
        && typeof payload.revision == "integer" && payload.revision >= 0;
}

function ReadyModes(catalog) {
    local ready = [];
    foreach (index, mode in Modes) {
        local key = EquipmentKey(index);
        if (key != null && catalog[key] > 0) ready.append(index);
    }
    return ready;
}

return { Modes, ValidMode, EquipmentKey, ValidState, ReadyModes };
