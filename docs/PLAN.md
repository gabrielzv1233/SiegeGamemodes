# SiegeGamemodes plan

## Target

- Stable Heated Metal: **Neon Dawn (Y5S4.2.0)**.
- Authoritative host-selected mode state, mirrored to clients.
- Build each mode as a separate rule set after engine behavior is tested.
- No Y9S2 dependency; newer versions can be adapted later.

## Mode catalog

| # | Mode | Concept | Reinforcements |
|---|---|---|---|
| 1 | Operator Mayhem | Duplicate operators per team | On |
| 2 | Loadout Roulette | Cross-team random guns, utility and attachments; keep ability | On |
| 3 | Sidearm Showdown | One shared pistol with per-player attachments | Off |
| 4 | Reverse Siege | Attackers and defenders exchange responsibilities | On |
| 5 | One Tap | Headshots kill, body shots do no damage | On |
| 6 | Frag Wars | Unlimited replenishing frags, no other secondary utilities | Off |
| 7 | TCSG Crutch | TCSG12 only, customizable attachments; keep ability/utility | Off |
| 8 | Overdrive | 3-speed, 1-armor and 1.5x mobility | On |
| 9 | Sniper Wars | CSRX 300 only | Off |
| 10 | Last Laugh | C4 detonation kills owner after explosion unless final enemy eliminated | Off |
| 11 | Army Men | Locked prone for whole round | Off |
| 12 | Oryx Uprising | All players play Oryx | Off |
| 13 | Shoulder Surfing | Forced Fortnite-style third-person | On |

Shelved: Size Matters (60% to 125% character scale). Sentry/Striker dual utility is not required on Y5S4.

## Milestones

1. **Foundation:** host selector, randomizer, host-to-client state, round-start update, no automatic gameplay mutations.
2. **Inventory proof:** experiment with applying a known weapon ID to a different slot and verify client replication, animations and ammo. Do not ship this as a game mode until tested.
3. **Equipment modes:** item catalogs with known-safe IDs, randomized attachments, per-player UI and gadget restrictions.
4. **Rules modes:** mobility, headshot filtering, grenade replenishment, reinforcement restrictions and third-person enforcement.
5. **Engine-heavy:** C4 win ordering, forced prone, swapped objectives/teams, operator replacement.

## Testing gates

- Confirm module loads and `sgm` shows UI.
- Verify only host can modify mode selection.
- Verify all clients see host mode choice and round changes.
- Verify reconnect/late join state sync (not implemented yet).
- Verify inventory test is stable and replicated before allowing automatic equipment changes.
- Confirm reinforcement blocking and disabled utilities are actually enforced, rather than just displayed.
- Record SDK/runtime discrepancies separately; the public API is not a guarantee of replication or gameplay correctness.

**Current status:** Module scaffold, configuration selector and optional weapon-slot experiment. No game mode logic is complete.
