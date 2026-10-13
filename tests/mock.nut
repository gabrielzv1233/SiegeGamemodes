// Test-only Heated Metal surface. Deliberately models only documented methods.
local Harness = { host = true, controls = {}, callbacks = {}, sent = [], players = [],
    elapsed = true, notifications = [], writes = [] };
local Game = {
    IsHost = function() { return Harness.host; },
    GetPlayerList = function() { return Harness.players; },
    GetLocalPlayer = function() { return Harness.players.len() > 0 ? Harness.players[0] : null; },
    AddNotification = function(text, color, replicate) { Harness.notifications.append(text); }
};
function MockControl(label, callback = null) {
    local control = { Text = label, Disabled = false, callback = callback };
    Harness.controls[label] <- control;
    return control;
}
local MockGui = {
    Text = function(label) { return MockControl(label); },
    SeparatorText = function(label) { return MockControl(label); },
    Button = function(label, callback) { return MockControl(label, callback); },
    Selectable = function(label, callback) { return MockControl(label, callback); },
    Toggle = function(label, initial, callback) { return MockControl(label, callback); }
};
local Renderer = {
    CreateWindow = function(name, size) {
        return { Active = false, Tab = function(label) { return MockGui; } };
    }
};
function Vector2(x, y) { return { x, y }; }
function Timer(startNow) {
    return { Reset = function() {}, HasElapsed = function(duration) { return Harness.elapsed; } };
}
function RandomIntRange(minimum, maximum) { return minimum; }
function SendNetworkTable(name, payload, receiver = null) {
    Harness.sent.append({ name, payload = clone payload, receiver });
}
function MockBind(name, callback) {
    if (!(name in Harness.callbacks)) Harness.callbacks[name] <- [];
    Harness.callbacks[name].append(callback);
}
function AddCallback_NetworkTable(callback) { MockBind("network", callback); }
function AddCallback_PlayerSpawn(callback) { MockBind("spawn", callback); }
function AddCallback_RoundEnd(callback) { MockBind("end", callback); }
function AddCallback_GadgetDetonated(callback) { MockBind("detonation", callback); }
function AddCallback_Update(callback) { MockBind("update", callback); }
function AddCallback_RoundStart(callback) { MockBind("start", callback); }
function RegisterCommand(callback, name, args, description) {
    Harness.controls[name] <- { callback };
}
function MockPlayer(name, entityID) {
    local inventory = [111, 222, 333, 444, 555];
    local player = {
        Name = name, Entity = { ObjectID = entityID }, Alliance = 3,
        DamageComponent = { Health = 100 }, PrimaryID = 111, SecondaryID = 222,
        TertiaryID = 333, PrimaryGadgetID = 444, SecondaryGadgetID = 555,
        inventory, fail = false
    };
    player.ItemSlotApply <- function(slot, id) {
        Harness.writes.append({ name, slot, id });
        if (player.fail) throw "simulated inventory failure";
        inventory[slot] = id;
    };
    player.ItemSlotRemove <- function(slot) {
        Harness.writes.append({ name, slot, id = 0 });
        inventory[slot] = 0;
    };
    return player;
}
function Click(label) { Harness.controls[label].callback(); }
function WorldStart() {
    foreach (name in ["network", "spawn", "end", "detonation", "update"])
        Harness.callbacks[name] = [];
    Harness.callbacks.start[0](12345);
}
local Checks = 0;
function Check(condition, message) {
    if (!condition) throw "FAILED: " + message;
    Checks++;
}
