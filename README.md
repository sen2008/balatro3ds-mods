# Balatro3DS Mods: KCVanilla Ports

Ports of Jokers from [KCVanilla](https://github.com/kcgidw/kcvanilla) (PC Balatro mod by **krackocloud**) to [Balatro3DS](https://github.com/idkhan/Balatro3DS), the Balatro remake for Nintendo 3DS available on Universal-Updater.

Balatro3DS has a Steamodded-style mod loader, but PC mods do not drop in: there is no Lovely, no `G.GAME`, and card art must be one `.t3x` texture per card. Each Joker here was re-expressed against the port's documented mod API, with art cropped from KCVanilla's atlas, converted with tex3ds, and given a shader-free Negative variant made with Balatro3DS's own `dev/make_negative.py`.

## Install

1. Download a zip from this repo (or clone it).
2. Copy the mod folder (`KCVanillaSwiss` or `KCVanillaPack`) to your SD card at `/3ds/save/Balatro3DS/sdmc/mods/`.
3. Start (or restart) Balatro3DS and check **Options → Mods**.
4. If a mod fails to load, the reason is written to `mods/mods_log.txt` in the same folder.

## The mods

### KCVanillaSwiss — Swiss Cheese (Rare, $8)

`{X:mult,C:white} X1 Mult for each gap of 1 rank between the ranks in the played poker hand` (ex: 2s and 4s, but no 3). Download: `balatro3ds-kcvanilla-swiss-v1.0.0.zip`.

### KCVanillaPack — nine more Jokers

Download: `balatro3ds-kcvanilla-pack-v1.0.0.zip`.

| Joker | Rarity / Cost | Effect |
|---|---|---|
| Composition | Common / $4 | +4 Mult per Joker to the left, +20 Chips per Joker to the right |
| Royal Guard | Common / $5 | If the played hand has no Kings or Queens, +10 Chips per King/Queen in your full deck |
| Joker-chan | Uncommon / $6 | At end of round, gains +2 Mult per Common Joker held |
| Red Envelope | Uncommon / $5 | Earn $8 per Common Joker when the Boss Blind is defeated |
| Jimbot | Uncommon / $5 | Gains the Chip value of the first scoring numbered card each round |
| Ten-Pin | Uncommon / $5 | A scoring 10 gives X2 Mult for the next 2 hands |
| Handy Joker | Uncommon / $6 | Gains X1 Mult per single enhanced card discarded; resets after the Boss Blind |
| Joker Energy | Uncommon / $6 | Scored Wild cards give a random one of +10 Mult, +100 Chips, X2 Mult, $5 |
| Power Grid | Uncommon / $6 | Scored Mult cards give X Mult, growing +0.1 per Mult card scored this round |

## Port notes

- Descriptions are KCVanilla's en-us text verbatim. One mismatch inherited on purpose: Handy Joker's text says "first discard of round", but the PC code triggers on *every* single enhanced-card discard. These ports follow the code.
- Handy Joker and Ten-Pin keep their state in `ability.x_mult`, which PC Balatro applies itself; Balatro3DS only applies what `calculate` returns, so their `joker_main` returns it.
- Power Grid's PC version counts scored Mult cards with a Lovely patch; here the Joker counts them itself. Same numbers (the patch increments before the Joker's effect, and so does this).
- Red Envelope checks the blind index (3 = Boss) instead of `G.GAME.blind.boss`; it is still paid by `calc_dollar_bonus` in the end-of-round cash-out, as on PC.
- Jimbot reads the card view's base chip value; a Bonus card's +30 is added back by hand. Stone cards are excluded (on PC they have no number to capture).

## Not ported (and why)

The other nine KCVanilla Jokers need things Balatro3DS mods do not have: Five-Day Forecast (Lovely patch on the rank-up path), Fortune Cookie, Rats! and Cosmic Collapse (destroy/create cards), Loose Tooth (`SMODS.add_card`), Rakugo (booster-pack internals), Scapegoat (destroying discards), Squid (live hands-left and projected score mid-round), Luck of the Irish (the port passes `trigger_obj = nil` for vanilla probability rolls, so a mod cannot tell which card rolled).

Also found while porting: Balatro3DS does not fill `context.full_hand` for discard contexts (the batch is only in `context.port.discarded_nodes`). Handy Joker works around it; other discard mods should too.

## Validation

Each port was loaded through the real ModLoader and exercised in Balatro3DS's own headless test harness: Swiss Cheese 4/4 checks, the pack 13/13 (loading, registration, and per-Joker scoring behaviour), with the game's own mod suite (38 tests) still green and a negative control confirming the tests can fail. Hardware testing is the remaining step.

## Credits

- **krackocloud** — KCVanilla, its Joker designs, text and art. KCVanilla ships no license; this is an unofficial fan port made for personal use, published with credit. If you are krackocloud and want anything changed or removed, open an issue and it will be handled immediately.
- **idkhan / Gazpacho** — Balatro3DS and its mod API.
- **LocalThunk** — Balatro.
