# SiegeGamemodes

Private-match custom game modes for Rainbow Six Siege via [Heated Metal](https://github.com/DataCluster0/HeatedMetal).

**Target:** stable Heated Metal on **Neon Dawn (Y5S4.2.0)**, not the experimental Y9S2 port.

## Current state

Early proof of concept: in-game selector for 13 planned modes, random selection, random-each-round setting, and host-to-client configuration messages. **The actual gameplay rules are not implemented yet.** An explicit, host-only inventory swap experiment is included to test the most important SDK mechanic.

See [the full mode list and roadmap](docs/PLAN.md).

## Install and try

1. Obtain a matching Neon Dawn game build and install the stable Heated Metal release according to its official instructions. Only test with compatible private/offline modded games, not live Ubisoft matchmaking.
2. Copy the `Modules/SiegeGamemodes` directory into the SDK's `Modules` directory, alongside `ExampleModule`, and load it using the SDK's module-loading workflow.
3. Open the Heated Metal console (default F1 context menu) and enter `sgm` to toggle the mode selector.
4. Select a mode as host or press **Choose random mode**. Other players should receive the selection through network tables.
5. In a disposable test match, optionally use **Experiments > TEST: secondary item into primary slot**. Expect possible inventory/animation issues; it is not a finished feature.

The exact module discovery/loading behavior and runtime API compatibility have **not yet been tested in game**.

## References

- [Heated Metal README](https://github.com/DataCluster0/HeatedMetal)
- [Quarrel API](https://github.com/DataCluster0/HeatedMetal/blob/main/QuirrelDoc.h)
- [Window example](https://github.com/DataCluster0/HeatedMetal/blob/main/Modules/ExampleModule/Examples/Window.nut)
- [Network table example](https://github.com/DataCluster0/HeatedMetal/blob/main/Modules/BuyExample/main.nut)
