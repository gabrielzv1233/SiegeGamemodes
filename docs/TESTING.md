# Validation and in-game test procedure

## What offline tests establish

The real module and rules files execute under upstream Quirrel, with test doubles for native SDK objects. The suite exercises:

- Callback registration after simulated world reloads.
- Host-only mode selection and inventory writes.
- Complete network schema validation; peer-forged and stale states are ignored.
- Targeted replies to client requests and periodic broadcasts.
- New host sessions restarting revisions without accepting retired-session packets.
- Selection changes waiting until the next round.
- Shared pistol and primary-only inventory rules, including tertiary removal.
- Operator abilities and secondary utility remaining untouched.
- Delayed entity creation, late joiners, duplicate spawn callbacks and respawns.
- Failed inventory swaps being attempted once per entity, without endless retries.
- Large object IDs remaining exact integers.
- Armed randomization choosing only captured equipment prototypes.

The mock treats inventory writes as immediate and successful unless deliberately failed. It cannot validate engine acceptance, animation compatibility, network replication, attachment handling, native callback timing, ammo counts or game stability.

## First runtime session

1. Use matching Neon Dawn Heated Metal installations on a host and at least one client.
2. Install the complete module directory, including both `main.nut` and `rules.nut`.
3. Keep equipment unarmed. Open `sgm` on both peers. Select each mode, check its name and the reinforcement policy text.
4. Confirm clients cannot activate host controls. Confirm **Sync with host** works.
5. Join a client after the host's selection and check that it receives both the next and active mode.
6. Play through two world reloads. Verify selection and syncing still work on later rounds.
7. Reload the host module and verify clients accept its new session/revision.

## Equipment tests

1. With experiments off, equip a pistol normally on the host and spawn. Capture its secondary ID.
2. Select **Sidearm Showdown**, arm equipment for next round, then begin another round.
3. Check that host and client both have exactly that pistol, with no primary or tertiary firearm.
4. Check operator abilities and secondary gadgets still work. Verify ammo, reload, ADS, switching and death/spectating.
5. Change the selected mode mid-round. It should change only the next-round status, without touching current inventories.
6. Test a late join/respawn if the chosen match type permits one.
7. Disarm and begin a normal round. Check normal loadouts return.
8. Repeat with **TCSG Crutch**, capturing a real TCSG12 primary; repeat with **Sniper Wars**, capturing Kali's CSRX 300.
9. Record SDK console errors and whether host/client inventories disagree.

The host must equip the named weapon before capture. There is no reliable named weapon catalog or attachment setter in this module yet. A captured weapon ID does not prove attachments are included. Per-player attachment UI and random pistol selection remain planned.

Reinforcements remain available in these prototypes. Their planned OFF labels are not gameplay enforcement.

## Last Laugh investigation

Enable **Trace detonations for Last Laugh research** in Diagnostics, then detonate C4 in a normal round. Save the gadget ID, owner and health snapshot printed at callback time. Try a miss, a nonfinal enemy kill, and the final enemy kill. Determine whether the callback runs before or after damage/round resolution before implementing a delayed self-kill.

The diagnostic does not change C4 counts, health or round winners. Last Laugh is not implemented.

## API provenance

Implementation was checked against Heated Metal public source commit `b8c16f940e10f5a2c8497d712869477350273c0a`, specifically `QuirrelDoc.h`, `Modules/Core/enums.nut`, `Modules/BuyExample/main.nut`, and the native window example. The documentation says only RoundStart callbacks persist across world reloads. The module rebinds the other callbacks on that event.
