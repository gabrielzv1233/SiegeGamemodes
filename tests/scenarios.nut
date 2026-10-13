Check(Modes.len() == 13, "13 active modes");
foreach (index, mode in Modes)
    Check(mode.reinforcements == ([2, 5, 6, 8, 9, 10, 11].indexof(index) == null), "reinforcement policy");
foreach (invalid in [null, -1, 13, 2.0, "2", true])
    Check(!ValidMode(invalid), "reject invalid mode index");
foreach (payload in [null, [], {}, { type = "state" }])
    Check(!ValidState(payload), "reject incomplete packet");
Check(ReadyModes(Catalog).len() == 0, "empty catalog is not ready");

local alice = MockPlayer("Alice", 0x100000000);
local bob = MockPlayer("Bob", 0x100000001);
Harness.players = [alice, bob];
Check(Harness.writes.len() == 0, "loading module never mutates equipment");
Click("Capture current SECONDARY as shared pistol");
Check(Catalog.pistol == 222, "capture secondary object ID");
Click("3. Sidearm Showdown");
WorldStart();
Check(Harness.writes.len() == 0, "unarmed round never mutates equipment");
Check(ActiveMode == 2, "selected mode becomes active at round start");
foreach (name in ["network", "spawn", "end", "detonation", "update"])
    Check(Harness.callbacks[name].len() == 1, "callbacks rebound after world reload");

Click("Arm / disarm EXPERIMENTAL equipment for next round");
Check(!Running, "arming during a round takes effect next round");
WorldStart();
Check(Running && RoundWeaponID == 222, "armed pistol round captures one shared ID");
foreach (player in Harness.players) {
    Check(player.inventory[0] == 0 && player.inventory[1] == 222 && player.inventory[2] == 0,
        "shared pistol only, including tertiary removal");
    Check(player.inventory[3] == 444 && player.inventory[4] == 555, "keep ability and utility");
}
local count = Harness.writes.len();
PlayerSpawn(alice);
Update();
Check(Harness.writes.len() == count, "duplicate spawn/update is idempotent");
Click("7. TCSG Crutch");
Check(ActiveMode == 2 && ModeIndex == 6, "selection changes do not mix current-round rules");
Click("Capture current PRIMARY as TCSG12");
Check(Catalog.tcsg == 0, "cannot capture mutated inventory");

local delayed = MockPlayer("Delayed", 0x100000002);
local entity = delayed.Entity;
delayed.Entity = null;
Harness.players.append(delayed);
PlayerSpawn(delayed);
Check(Harness.writes.len() == count, "null entity spawn is deferred");
delayed.Entity = entity;
Update();
Check(delayed.inventory[0] == 0 && delayed.inventory[1] == 222, "late-created entity receives mode");
alice.Entity = { ObjectID = 0x100000003 };
PlayerSpawn(alice);
Check(Harness.writes.len() == count + 6, "new entity on respawn receives mode again");

local broken = MockPlayer("Broken", 0x100000004);
broken.fail = true;
Harness.players.append(broken);
PlayerSpawn(broken);
count = Harness.writes.len();
Update();
Check(Harness.writes.len() == count, "failed inventory does not retry forever");
RoundEnd();
count = Harness.writes.len();
PlayerSpawn(bob);
Check(!Running && Harness.writes.len() == count, "round end stops inventory mutation");

Click("Arm / disarm EXPERIMENTAL equipment for next round");
alice.PrimaryID = 0x123456789;
Click("Capture current PRIMARY as TCSG12");
alice.PrimaryID = 0x234567890;
Click("Capture current PRIMARY as CSRX 300");
Check(Catalog.tcsg == 0x123456789 && Catalog.sniper == 0x234567890, "64-bit IDs are preserved");
Check(ReadyModes(Catalog).len() == 3, "three equipped prototypes are eligible");
Click("Arm / disarm EXPERIMENTAL equipment for next round");
broken.fail = false;
foreach (choice in ["7. TCSG Crutch", "9. Sniper Wars"]) {
    Click(choice);
    WorldStart();
    foreach (player in Harness.players)
        Check(player.inventory[0] == RoundWeaponID && player.inventory[1] == 0
            && player.inventory[2] == 0, "primary-only prototype applies to all players");
}
Click("10. Last Laugh");
WorldStart();
Check(!Running, "unimplemented modes never execute equipment rules");
Click("Choose random mode");
Check(ModeIndex == 2, "armed randomizer limits choices to captured equipment prototypes");
Click("Toggle randomization every new round");
WorldStart();
Check(ActiveMode == 2 && Running, "randomize each round applies ready equipment rules");

Harness.sent.clear();
Network(Channel, { type = "request", protocol = 2 }, bob);
Check(Harness.sent.len() == 1 && Harness.sent[0].receiver == bob, "late join receives targeted reply");
Check(ValidState(Harness.sent[0].payload), "host emits complete valid state");
local hostMode = ModeIndex;
Network(Channel, { type = "state", protocol = 2, mode = 9 }, bob);
Check(ModeIndex == hostMode, "clients cannot modify host state");
local revision = Revision;
Update();
Check(Revision == revision, "heartbeat never advances revision");

Harness.host = false;
WorldStart();
Check(!HaveState && Revision == 0, "client clears previous world's watermark");
Check(Harness.sent.top().payload.type == "request", "client requests host state after reload");
local packet = { type = "state", protocol = 2, session = 100, mode = 6, active = 2,
    randomRound = false, revision = 8, armed = true, running = true };
Network(Channel, packet, alice);
Check(!HaveState, "ignore peer-forged state");
Network(Channel, {}, null);
Check(!HaveState, "ignore malformed state");
Network(Channel, packet, null);
Check(HaveState && ModeIndex == 6 && ActiveMode == 2, "accept authoritative host state");
local older = clone packet;
older.revision = 7;
older.mode = 8;
Network(Channel, older, null);
Check(ModeIndex == 6, "ignore stale revision");
local bad = clone packet;
bad.active = "2";
Network(Channel, bad, null);
Check(ModeIndex == 6, "reject invalid active mode type");
local newHost = clone packet;
newHost.session = 101;
newHost.revision = 0;
newHost.mode = 8;
Network(Channel, newHost, null);
Check(ModeIndex == 8 && Revision == 0, "host module reload can restart revisions");
Network(Channel, packet, null);
Check(ModeIndex == 8, "ignore retired host session packets");
count = Harness.writes.len();
Click("3. Sidearm Showdown");
Click("Arm / disarm EXPERIMENTAL equipment for next round");
PlayerSpawn(alice);
Check(ModeIndex == 8 && Harness.writes.len() == count, "client cannot change selection or inventory");
Check(Harness.controls["3. Sidearm Showdown"].Disabled, "host controls disabled for client");
print("PASS: " + Checks + " Quirrel regression checks");
