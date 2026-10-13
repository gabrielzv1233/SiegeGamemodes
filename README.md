# SiegeGamemodes

Private-match custom game modes for Rainbow Six Siege via [Heated Metal](https://github.com/DataCluster0/HeatedMetal).

**Target:** stable Heated Metal on **Neon Dawn (Y5S4.2.0)**, not the experimental Y9S2 port.

## Current state

Version **0.2.0** includes the host selector, randomizer, next-round settings, automatic state requests/heartbeats for late joiners, and experimental equipment rules for **Sidearm Showdown**, **TCSG Crutch**, and **Sniper Wars**.

Equipment rules default to **off**. The host captures a real weapon ID from their loadout, then explicitly arms the experiment for the next round. The rules apply a shared weapon to spawned players and remove the other firearm slots, preserving operator abilities and secondary utility.

**These are prototypes, not finished game modes.** No multiplayer game test has been run. Reinforcement restrictions, attachment configuration, random pistol selection, and the other gameplay modes are still unimplemented. The UI explicitly shows reinforcement rules as planned rather than enforced.

See [the full mode list and roadmap](docs/PLAN.md).

## Install and try

1. Obtain a matching Neon Dawn game build and install the stable Heated Metal release according to its official instructions. Only test with compatible private/offline modded games, not live Ubisoft matchmaking.
2. Copy the `Modules/SiegeGamemodes` directory into the SDK's `Modules` directory, alongside `ExampleModule`, and load it using the SDK's module-loading workflow.
3. Open the Heated Metal console (default F1 context menu) and enter `sgm` to toggle the mode selector.
4. Select a mode as host or press **Choose random mode**. Selections take effect next round, so current-round equipment is not mixed with another rule set. Clients receive the host's selection and active mode separately.
5. To try equipment rules, spawn with a normal loadout first, then use the **Equipment** tab to capture the correct gun: secondary for a pistol, primary for TCSG12 or CSRX 300.
6. Choose the matching mode, press **Arm / disarm EXPERIMENTAL equipment for next round**, then begin a new round. Check the text status to confirm it is armed/running.
7. Use **Diagnostics** to print inventory IDs or trace gadget detonations for future Last Laugh work.

Captured IDs exist only for the module session. The capture buttons trust that you equipped the named gun; they do not identify it automatically. Restarting/unloading the module mid-round does not undo earlier inventory changes. Disarm and start a fresh normal round to restore ordinary loadouts.

While armed, the randomizer only picks equipment prototypes with a captured ID. While unarmed, it can select any of the 13 planned modes for configuration testing.

The exact module discovery/loading behavior, runtime API compatibility, gun replication, attachments, animations and ammunition still need in-game testing. See [the test procedure](docs/TESTING.md).

## Offline validation

The regression suite runs the actual module under upstream Quirrel with a mocked Heated Metal API. It checks round reloads, host authority, packet validation, late joins, respawns, equipment restrictions, partial inventory failures and 64-bit object IDs.

```sh
python3 tests/build_quirrel.py --source /tmp/sgm-quirrel --output /tmp/sgm-sq
python3 tests/run.py /tmp/sgm-sq
```

The builder requires Git, GCC and Python, and pins Quirrel to a specific commit. GitHub Actions runs the same suite on pushes and PRs. Mock tests do not establish that Siege will accept or replicate the inventory changes.

## References

- [Heated Metal README](https://github.com/DataCluster0/HeatedMetal)
- [Quarrel API](https://github.com/DataCluster0/HeatedMetal/blob/main/QuirrelDoc.h)
- [Window example](https://github.com/DataCluster0/HeatedMetal/blob/main/Modules/ExampleModule/Examples/Window.nut)
- [Network table example](https://github.com/DataCluster0/HeatedMetal/blob/main/Modules/BuyExample/main.nut)
