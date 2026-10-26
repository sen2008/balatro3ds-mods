# JOB — Top-10 Wave 6: shop/booster APIs + MoreFluff Sliver/Colour

Ordered by Lucas 2026-10-25 ("Keep going until you can do the top 10 best mods",
2026-10-23; Wave 6 go 2026-10-25). Source audit: TOP10-AUDIT-remainders.md §7
item 3 (shop bundle) and item 1/§8 step 8 (MoreFluff pack systems), plus §8
step 7's named unlocks. Waves 1–5 already landed §8 steps 1–6; do not redo
them. Verify every "blocked" claim against each pack's CURRENT README blocked
list before porting — the audit is a snapshot and packs have moved since.

## Track A — fork: shop / pool / voucher / booster APIs

In sen2008/balatro3ds-fork (local ~/workspace/balatro3ds-fork/), extend the
SMODS layer with the shop-manipulation surface the PC mods use, following the
fork's existing patterns (registrars in smods.lua, effects through
JokerEffects, returns read centrally, seeded-RNG invariance for vanilla):

1. **Offer insertion**: a mod API to add a card/Joker/consumable offer into
   the current shop (and to create booster packs as shop offers), usable from
   Joker calculate (e.g. `store_joker_create`-adjacent moments and end-of-round
   effects). PC names to mirror where sensible: `SMODS.add_card` into the shop
   area, booster creation via the existing SMODS.Booster kinds.
2. **Price & rate control**: per-Joker/offer price modifiers and pool rate
   hooks the packs below actually call (read the PC sources in
   ~/workspace/repos/ and the pack READMEs for the exact calls used — build
   what the unlock list needs, not a speculative superset).
3. **Voucher grant/redeem**: API to grant a voucher effect / add a voucher to
   the shop or redeem it directly, as used by the unlock list.
4. **Booster payload & choice counts**: `open_booster` context must carry the
   actual booster card (the audit notes it currently fires with an empty
   table), plus a route for Jokers to alter booster size/choice counts and to
   add cards into an opened booster (`add_card` route into boosters).

Hard requirements, same as every wave:
- Vanilla invariance: with no mod using the new APIs, seeded shop/booster
  offers must be byte-identical to the current build (seeded diff test in
  test_mods, like the Tier 3f invariance proof).
- New behavior covered in tests/test_mods.lua; keep the full-suite failure
  set at exactly the known 9 pre-existing environment failures.
- Document the new surface in the fork's MODDING.md.
- Build the CIA with dev/build.sh (build env:
  DEVKITPRO=$HOME/devkitpro-root/opt/devkitpro
  PATH=$HOME/workspace/forkbin:$HOME/workspace/bin:$HOME/devkitpro-root/opt/devkitpro/tools/bin:$PATH).

## Track B — packs (after Track A lands)

Port, from each pack's current blocked list, the items whose primary blocker
was the shop/booster bundle (audit §7.3: ≈25 total). Named minimums:

- **PaperbackPack** (9 in the shop/pool/voucher group, in part): Backpack,
  Membership Card is STRUCTURAL (live Discord count) — skip it; NormalJKR,
  Protocol, Shopping Center, Touch Tone Joker, Ouija Board, Chaplin,
  Everything Must Go — port those the new APIs honestly cover; document any
  that still fall short and why.
- **BuncoPack** (4): JMJB, Aristocrat (creation/shop-offer insertion),
  Doorhanger, Running Joke.
- **MoreFluffPack** (7 in part): Bouncer, Junk Mail, B, Shopping Spree,
  Gem Alert (shop manipulation group) + Bonus Sheet, Repack (booster
  internals) — plus the pack-level systems below.
- **CryptidPack** (4–5): ://DIVIDE, ://DELETE (the shop/state part),
  ://OFFBYONE, Digital Hallucinations (booster payload in open_booster),
  Trade.
- **MoreFluff pack-level systems (no fork work expected)**: Slivers (14) then
  Colour (6) — the confident core per the audit (§6/§7.1): pack-shared tables
  reproducing the PC registries (src/sliver_abilities.lua, src/colours.lua)
  on the fork's existing contexts, per-effect verification in the pack suite.
  Rotarot (3) and Cascade (4) only if Sliver+Colour land clean and time
  remains; Prepared/Exile/Loyalty stay out of this wave.

Sprites: one .t3x per .png in assets/1x via tex3ds -f rgba
(~/devkitpro-root/opt/devkitpro/tools/bin/tex3ds); negatives via the packs'
existing pattern. Watch FAT case-insensitive collisions pack-wide (the
v1.4.1 lesson): no two asset filenames in a pack may differ only by case.
License rules unchanged: packs with no PC license carry credit + takedown
notes in their README.

## Tests

- Fork: tests.test_mods all green (count grows), full suite failures = the
  known 9 only.
- Each touched pack suite green via the established harness (copy the pack
  test into fork tests/, run with its env var — CRY_PACK_LUA, PB_PACK_LUA,
  BUNCO_PACK_LUA, MF_PACK_LUA — then remove the copy). If lupa or the lua51
  shim are missing: pip3 install --break-system-packages lupa; copy
  ~/workspace/balatro3ds-fork-push/lua51_shim.lua to /tmp/lua51_shim.lua.
- Bump versions: fork build label is date-based at publish; packs bump minor
  (Cryptid 1.4.1 -> 1.5.0 if touched, Paperback 1.3.0 -> 1.4.0, Bunco 1.4.0 ->
  1.5.0, MoreFluff 1.3.0 -> 1.4.0). Update each pack's README blocked list and
  changelog lines, and rebuild each pack zip with the established layout.

## Out of scope

Contexts refactor (§8.11), per-card state/paperclips (§8.10), enhancement
channels (§8.9), selection limits/blind APIs (§8.12), all §8.13 big singles,
§5 structural items. Balatro Multiplayer stays parked.

## Deliverable

Working trees updated in place (fork + packs + zips), all suites green, and a
report: fork APIs added (with MODDING.md section names), per-pack ported
items with new counts, anything attempted but left blocked (with the honest
reason), and the CIA size. Do NOT push anything — publishing is done by the
coordinator after independent verification.

## Completion record (2026-10-25, builder)

DONE, working trees ready, NOT pushed (coordinator publishes).

- Track A (fork): shop/voucher/booster API bundle as specified;
  MODDING.md "Shop, voucher and booster APIs" section added.
  Seeded vanilla invariance proven (SHOP_BASELINE in test_mods).
  21 wave6 tests; test_mods 155/155; full suite 1240 passed /
  9 failed (exactly the baseline 9). One later fix: 
  SMODS.replace_common_rarity skips debuffed holders (PC parity),
  landed during Bunco work; suites re-run after it.
- PaperbackPack v1.4.0: 291 Jokers (+8: Backpack, Protocol,
  Shopping Center, Everything Must Go, NormalJKR, Touch Tone
  Joker, Chaplin, Ouija Board). Membership Card stays blocked
  (structural: reads PC Paperback's live Discord member count).
  Suites 41/41, 45/45, 129/129. Zip PaperbackPack.zip 16,349,410 B.
- BuncoPack v1.5.0: 66 Jokers (+4: JMJB, Aristocrat, Doorhanger,
  Running Joke). Suite 54/54. Zip BuncoPack.zip 1,109,674 B.
- MoreFluffPack v1.4.0: 133 Jokers (+25: Bouncer, Junk Mail,
  Letter B, Shopping Spree, Gem Alert, Bonus Sheet, Repack; 12
  Slivers via a pack-side granted-effects runner; Paint Can,
  Rainbow Joker, Clipart Joker, CSS, Monochrome Joker, Loaded
  Disk) + 14 Colour consumables + 6 booster packs (2 Modded,
  4 Colour). Suite 86/86. Zip balatro3ds-morefluff-pack-v1.4.0.zip
  4,353,770 B. Still blocked: The First Sliver (Cascade),
  Virulent Sliver (raw score return), Homing Sliver
  (modify_weights only), Yellow (flat $1 consumable sell value),
  Peach (Rotarot), Gold (hidden soul-poll); Colour Tag and the
  Colour vouchers were out of scope.
- CryptidPack v1.5.0: 176 Jokers (+ Digital Hallucinations),
  31 consumables (+ ://DIVIDE, ://OFFBYONE, Trade). Suite 95/95.
  Zip balatro3ds-cryptid-pack-v1.5.0.zip 8,284,572 B.
  ://DELETE stays blocked (no shop-item picker / no banish
  state); ://KEYGEN stays blocked (stickers + keygen provenance
  bookkeeping; grant/unredeem alone do not cover it).
- CIA rebuilt from the final tree: 24,613,824 B, copied to
  balatro3ds-mods/Balatro3DS-fork.cia.
