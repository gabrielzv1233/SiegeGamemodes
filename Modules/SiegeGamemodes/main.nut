local { Game, Renderer } = require("HeatedMetal");
local { Modes, ValidMode, EquipmentKey, ValidState, ReadyModes } = require("rules.nut");

// ItemSlot values from Heated Metal Modules/Core/enums.nut.
local PRIMARY = 0;
local SECONDARY = 1;
local TERTIARY = 2;
local Channel = "SiegeGamemodes.Config.v2";
local ModeIndex = 0;
local ActiveMode = 0;
local RandomEachRound = false;
local Revision = 0;
local Session = RandomIntRange(1, 0x3fffffff);
local RetiredSessions = {};
local Armed = false;
local Running = false;
local InRound = false;
local HaveState = false;
local Catalog = { pistol = 0, tcsg = 0, sniper = 0 };
local RoundWeaponID = 0;
local Applied = {};
local Failed = {};
local SyncTimer = Timer(true);
local Trace = false;
local Window = Renderer.CreateWindow("SiegeGamemodes", Vector2(680.0, 600.0));
Window.Active = false;
local Overview = Window.Tab("Selection");
local Status = Overview.Text("");
local RuleStatus = Overview.Text("");
local SyncStatus = Overview.Text("");
local HostControls = [];
local Equipment = Window.Tab("Equipment");
local CatalogStatus = Equipment.Text("");

function RefreshStatus() {
    Status.Text = "Next round: " + Modes[ModeIndex].name + " | Active: " + Modes[ActiveMode].name;
    RuleStatus.Text = "Equipment experiment: " + (Running ? "RUNNING" : (Armed ? "ARMED for next round" : "OFF"))
        + " | Planned reinforcements: " + (Modes[ActiveMode].reinforcements ? "ON" : "OFF")
        + " (NOT enforced)";
    SyncStatus.Text = "Round randomizer: " + (RandomEachRound ? "ON" : "OFF")
        + " | Sync: " + (Game.IsHost() ? "HOST" : (HaveState ? "CONNECTED" : "waiting for host"));
    CatalogStatus.Text = "Captured IDs | Pistol: " + Catalog.pistol
        + " | TCSG12: " + Catalog.tcsg + " | CSRX 300: " + Catalog.sniper;
    foreach (control in HostControls) control.Disabled = !Game.IsHost();
}

// Sync replies and heartbeats do not change the revision or announce a selection.
function PublishState(receiver = null) {
    if (!Game.IsHost()) return;
    local state = {
        type = "state", protocol = 2, session = Session, mode = ModeIndex, active = ActiveMode,
        randomRound = RandomEachRound, revision = Revision, armed = Armed, running = Running
    };
    if (receiver == null) SendNetworkTable(Channel, state);
    else SendNetworkTable(Channel, state, receiver);
    RefreshStatus();
}

function Changed() {
    Revision++;
    PublishState();
}

function RequestState() {
    if (!Game.IsHost()) SendNetworkTable(Channel, { type = "request", protocol = 2 });
}

function SelectMode(index) {
    if (!Game.IsHost() || !ValidMode(index)) return;
    ModeIndex = index;
    Changed();
}

function ChooseRandom() {
    if (!Game.IsHost()) return false;
    local choices = [];
    if (Armed) choices = ReadyModes(Catalog);
    else foreach (index, mode in Modes) choices.append(index);
    if (choices.len() == 0) {
        print("[SiegeGamemodes] Capture a weapon before randomizing armed equipment modes.");
        return false;
    }
    ModeIndex = choices[RandomIntRange(0, choices.len() - 1)];
    return true;
}

Overview.SeparatorText("Choose next round's mode");
for (local i = 0; i < Modes.len(); i++) {
    local index = i;
    HostControls.append(Overview.Selectable((i + 1).tostring() + ". " + Modes[i].name, function() {
        SelectMode(index);
    }));
}
Overview.SeparatorText("Host tools");
HostControls.append(Overview.Button("Choose random mode", function() {
    if (ChooseRandom()) Changed();
}));
HostControls.append(Overview.Button("Toggle randomization every new round", function() {
    if (!Game.IsHost()) return;
    RandomEachRound = !RandomEachRound;
    Changed();
}));
HostControls.append(Overview.Button("Arm / disarm EXPERIMENTAL equipment for next round", function() {
    if (!Game.IsHost()) return;
    Armed = !Armed;
    Changed();
}));
Overview.Button("Sync with host", function() {
    if (Game.IsHost()) PublishState();
    else RequestState();
});
Overview.Text("Armed randomizer only chooses captured pistol / TCSG / sniper prototypes.");
Overview.Text("Other modes are plans. Equipment prototypes still need multiplayer testing.");

// Capture real object IDs instead of guessing version-dependent weapon identifiers.
function Capture(key, slot) {
    if (!Game.IsHost()) return;
    if (InRound && Running) {
        print("[SiegeGamemodes] Cannot capture modified loadouts during an equipment round.");
        return;
    }
    local player = Game.GetLocalPlayer();
    if (player == null || player.Entity == null) return;
    local id = slot == SECONDARY ? player.SecondaryID : player.PrimaryID;
    if (id == 0) return;
    Catalog[key] = id;
    print("[SiegeGamemodes] Captured " + key + " item ID " + id);
    RefreshStatus();
}

Equipment.Text("Host: equip the named weapon normally, spawn, then capture it here.");
Equipment.Text("IDs last for this module session only. Captures are not verified by weapon name.");
HostControls.append(Equipment.Button("Capture current SECONDARY as shared pistol", function() {
    Capture("pistol", SECONDARY);
}));
HostControls.append(Equipment.Button("Capture current PRIMARY as TCSG12", function() {
    Capture("tcsg", PRIMARY);
}));
HostControls.append(Equipment.Button("Capture current PRIMARY as CSRX 300", function() {
    Capture("sniper", PRIMARY);
}));
Equipment.Text("Then select the matching mode and arm equipment rules for the next round.");
Equipment.Text("Abilities and secondary gadgets are preserved. Tertiary firearms are removed.");
Equipment.Text("Attachments are not configured here yet; inspect the resulting loadout.");

function ApplyEquipment(player) {
    if (!Game.IsHost() || !InRound || !Running || RoundWeaponID == 0
        || player == null || player.Entity == null) return;
    local entityID = player.Entity.ObjectID.tostring();
    if (entityID in Applied || entityID in Failed) return;
    // Do not repeatedly retry a partial inventory failure.
    try {
        if (ActiveMode == 2) {
            player.ItemSlotApply(SECONDARY, RoundWeaponID);
            player.ItemSlotRemove(PRIMARY);
        } else {
            player.ItemSlotApply(PRIMARY, RoundWeaponID);
            player.ItemSlotRemove(SECONDARY);
        }
        player.ItemSlotRemove(TERTIARY);
        Applied[entityID] <- true;
        print("[SiegeGamemodes] Applied " + Modes[ActiveMode].name + " to " + player.Name);
    } catch (error) {
        Failed[entityID] <- true;
        print("[SiegeGamemodes] Inventory failure for " + player.Name + ": " + error);
    }
}

function Network(name, payload, sender) {
    if (name != Channel || typeof payload != "table") return;
    if (Game.IsHost()) {
        if (sender != null && "type" in payload && payload.type == "request"
            && "protocol" in payload && payload.protocol == 2) PublishState(sender);
        return;
    }
    if (sender != null || !ValidState(payload)) return;
    local sessionKey = payload.session.tostring();
    if (sessionKey in RetiredSessions) return;
    if (HaveState && payload.session == Session && payload.revision < Revision) return;
    if (HaveState && payload.session != Session) RetiredSessions[Session.tostring()] <- true;
    Session = payload.session;
    ModeIndex = payload.mode;
    ActiveMode = payload.active;
    RandomEachRound = payload.randomRound;
    Revision = payload.revision;
    Armed = payload.armed;
    Running = payload.running;
    HaveState = true;
    RefreshStatus();
}

function PlayerSpawn(player) {
    // The periodic update also handles delayed entity creation after this callback.
    ApplyEquipment(player);
}

function RoundEnd() {
    InRound = false;
    Running = false;
    Applied.clear();
    Failed.clear();
    if (Game.IsHost()) Changed();
    else RefreshStatus();
}

function GadgetDetonated(player, gadget, id) {
    if (!Trace || !Game.IsHost()) return;
    print("[SiegeGamemodes] Detonation | owner=" + (player == null ? "none" : player.Name)
        + " | gadget=" + id);
    foreach (other in Game.GetPlayerList()) {
        if (other.Entity == null || other.DamageComponent == null) continue;
        print("[SiegeGamemodes] At detonation | " + other.Name + " | alliance="
            + other.Alliance + " | health=" + other.DamageComponent.Health);
    }
}

function Update() {
    if (!SyncTimer.HasElapsed(2.0)) return;
    if (Game.IsHost()) {
        if (InRound && Running)
            foreach (player in Game.GetPlayerList()) ApplyEquipment(player);
        PublishState();
    } else if (!HaveState) RequestState();
}

// RoundStart survives world reloads. Heated Metal clears all other callbacks.
function BindWorldCallbacks() {
    AddCallback_NetworkTable(Network);
    AddCallback_PlayerSpawn(PlayerSpawn);
    AddCallback_RoundEnd(RoundEnd);
    AddCallback_GadgetDetonated(GadgetDetonated);
    AddCallback_Update(Update);
}

function RoundStart(world) {
    BindWorldCallbacks();
    InRound = true;
    Running = false;
    RoundWeaponID = 0;
    Applied.clear();
    Failed.clear();
    SyncTimer.Reset();
    if (!Game.IsHost()) {
        // New hosts may start revisions at zero. Reset the previous world's watermark.
        HaveState = false;
        Revision = 0;
        RetiredSessions.clear();
        RequestState();
        RefreshStatus();
        return;
    }
    if (RandomEachRound) ChooseRandom();
    ActiveMode = ModeIndex;
    local key = EquipmentKey(ActiveMode);
    if (Armed && key != null && Catalog[key] > 0) {
        RoundWeaponID = Catalog[key];
        Running = true;
    } else if (Armed) {
        print("[SiegeGamemodes] Equipment rules skipped: mode unsupported or no captured weapon.");
    }
    Changed();
    Game.AddNotification("SiegeGamemodes: " + Modes[ActiveMode].name
        + (Running ? " (equipment experiment)" : " (selection only)"), 0, true);
    foreach (player in Game.GetPlayerList()) ApplyEquipment(player);
}

local Experiments = Window.Tab("Diagnostics");
Experiments.Text("Host-only tests. Use a disposable private match.");
HostControls.append(Experiments.Button("Print current lobby inventory IDs", function() {
    if (!Game.IsHost()) return;
    foreach (player in Game.GetPlayerList()) {
        print("[SiegeGamemodes] " + player.Name + " | primary=" + player.PrimaryID
            + " | secondary=" + player.SecondaryID + " | tertiary=" + player.TertiaryID
            + " | ability=" + player.PrimaryGadgetID + " | utility=" + player.SecondaryGadgetID);
    }
}));
HostControls.append(Experiments.Toggle("Trace detonations for Last Laugh research", false, function(value) {
    if (Game.IsHost()) Trace = value;
}));
Experiments.Text("Traces record gadget IDs and health at detonation time; no self-kill yet.");

function ToggleWindow(args) {
    Window.Active = !Window.Active;
    RefreshStatus();
    if (!Game.IsHost()) RequestState();
}

BindWorldCallbacks();
AddCallback_RoundStart(RoundStart);
RegisterCommand(ToggleWindow, "sgm", "", "Toggle SiegeGamemodes selector");
RefreshStatus();
if (Game.IsHost()) PublishState();
else RequestState();
print("[SiegeGamemodes] Equipment prototype loaded. Console command: sgm");
