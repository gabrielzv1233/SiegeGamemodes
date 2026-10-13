local { Game, Renderer } = require("HeatedMetal");

// Neon Dawn foundation. Game modes are currently configuration only.
// No weapon, damage, reinforcement or team changes are automatic.
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

local Channel = "SiegeGamemodes.Config.v1";
local ModeIndex = 0;
local RandomEachRound = false;
local Revision = 0;
local Window = Renderer.CreateWindow("SiegeGamemodes", Vector2(540.0, 540.0));
Window.Active = false;

local Overview = Window.Tab("Selection");
local Status = Overview.Text("Waiting for host configuration...");
Overview.SeparatorText("Choose a game mode");

function RefreshStatus() {
    local mode = Modes[ModeIndex];
    Status.Text = "Selected: " + mode.name
        + " | Reinforcements: " + (mode.reinforcements ? "ON" : "OFF")
        + " | Round randomizer: " + (RandomEachRound ? "ON" : "OFF")
        + " | Revision: " + Revision;
}

function PublishMode() {
    if (!Game.IsHost()) return;
    Revision++;
    SendNetworkTable(Channel, {
        type = "state",
        mode = ModeIndex,
        randomRound = RandomEachRound,
        revision = Revision
    });
    RefreshStatus();
    Game.AddNotification("Mode selected: " + Modes[ModeIndex].name, 0, true);
}

function SelectMode(index) {
    if (!Game.IsHost()) return;
    ModeIndex = index;
    PublishMode();
}

for (local i = 0; i < Modes.len(); i++) {
    local index = i;
    Overview.Selectable((i + 1).tostring() + ". " + Modes[i].name, function() {
        SelectMode(index);
    });
}

Overview.SeparatorText("Host tools");
Overview.Button("Choose random mode", function() {
    if (!Game.IsHost()) return;
    ModeIndex = RandomIntRange(0, Modes.len() - 1);
    PublishMode();
});
Overview.Toggle("Randomize every new round", false, function(value) {
    if (!Game.IsHost()) return;
    RandomEachRound = value;
    PublishMode();
});
Overview.Button("Sync selection to all players", function() {
    PublishMode();
});
Overview.Text("Mode rules are NOT implemented yet. Selection is synchronized only.");

local Experiments = Window.Tab("Experiments");
Experiments.Text("Only the HOST can execute the optional inventory test.");
Experiments.Text("Replaces your primary slot with your CURRENT secondary item ID.");
Experiments.Text("Test in a disposable private match. May not replicate or equip correctly.");
Experiments.Button("TEST: secondary item into primary slot", function() {
    if (!Game.IsHost()) return;
    local player = Game.GetLocalPlayer();
    if (player == null || player.SecondaryID == 0) {
        print("[SiegeGamemodes] No local player or secondary weapon.");
        return;
    }
    print("[SiegeGamemodes] Testing primary swap, item ID: " + player.SecondaryID);
    player.ItemSlotApply(0, player.SecondaryID);
});

function Network(name, payload, sender) {
    if (name != Channel || sender != null) return;
    if (Game.IsHost()) return;
    if (payload.type != "state") return;
    if (payload.mode < 0 || payload.mode >= Modes.len()) return;
    if (payload.revision < Revision) return;
    ModeIndex = payload.mode;
    RandomEachRound = payload.randomRound;
    Revision = payload.revision;
    RefreshStatus();
}

function RoundStart(world) {
    if (!Game.IsHost()) return;
    if (RandomEachRound)
        ModeIndex = RandomIntRange(0, Modes.len() - 1);
    PublishMode();
}

function ToggleWindow(args) {
    Window.Active = !Window.Active;
    RefreshStatus();
}

RefreshStatus();
AddCallback_NetworkTable(Network);
AddCallback_RoundStart(RoundStart);
RegisterCommand(ToggleWindow, "sgm", "", "Toggle SiegeGamemodes selector");
print("[SiegeGamemodes] Foundation loaded. Console command: sgm");
