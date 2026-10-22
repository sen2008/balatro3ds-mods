# Balatro3DS Mods

Ports of PC Balatro mods to [Balatro3DS](https://github.com/idkhan/Balatro3DS) (the 3DS remake on Universal-Updater).

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

### KCVanillaPack — fourteen Jokers

Download: `balatro3ds-kcvanilla-pack-v1.1.0.zip`.

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
| Fortune Cookie | Common / $5 | +150 Chips, −50 Chips when a Tarot is used; eaten when it runs out |
| Rats! | Uncommon / $6 | When the round begins, destroy a random card in hand and duplicate this Joker |
| Cosmic Collapse | Rare / $7 | At end of round, each held Planet has a 1 in 2 chance to transform into a Black Hole |
| Loose Tooth | Common / $5 | Create a Tarot card if the played hand has a non-scoring Ace |
| Scapegoat | Uncommon / $6 | If the first discard of the round is 1 card, destroy it and add its Chip value to a random card in hand |

**The last five need the [Balatro3DS fork](https://github.com/sen2008/balatro3ds-fork) build.** They create and destroy cards through the fork's Tier 1 mod API (`SMODS.add_card` / `SMODS.destroy_joker` / `SMODS.destroy_card`), which the stock game does not have. On the stock Universal-Updater build the pack loads and the original nine work, but those five have no effects.


### PokermonPack — 35 Gen 1 Pokémon Jokers

From **Pokermon** by InertSteak (the #2 most popular Balatro mod). Bulbasaur, Charmander and Squirtle (with their +hand size / +discard / +hand passives), Pikachu, Magikarp, the Caterpie, Weedle and Pidgey lines, Rattata/Raticate, Diglett/Dugtrio, Shellder/Cloyster, Goldeen/Seaking, Mr. Mime, Pinsir, Rapidash, Articuno, and more. Zip: `balatro3ds-pokermon-pack-v1.0.0.zip`.

Pokermon is **GPLv3**, so this port is published under GPLv3 with the original code credited below.

Port notes:

- **No evolution, no Energy, no items**: Balatro3DS has none of those systems, so each Pokémon ships with its base effect at base (un-energized) values, and the "Evolves…" tooltip lines are removed. The custom `poke_safari` rarity maps to Rare.
- Bulbasaur's designated rank is re-rolled at blind select, as in the original. Charmander/Squirtle scaling reads the port's live `G.discards` / `G.hands` counters.
- Retrigger Pokémon (Rattata line, Shellder line, Goldeen line, Mr. Mime) use the port's `context.repetition`; "first N scoring cards" is resolved through `context.port.played_cards`, since the repetition context has no `scoring_hand`.
- Tentacruel's "10s can't be debuffed" and Snorlax/Eevee-style effects bound to Pokermon's item/evolution systems did not port. Eevee and Snorlax are not in the pack for that reason.
- Articuno adds Foil and a random seal to the first scoring card, but only if it has neither yet (the original converts unconditionally). Art is cropped from Pokermon's own Natdex sheet, with the legendary "soul" layer composited in.

## Port notes

- Descriptions are KCVanilla's en-us text verbatim. One mismatch inherited on purpose: Handy Joker's text says "first discard of round", but the PC code triggers on *every* single enhanced-card discard. These ports follow the code.
- Handy Joker and Ten-Pin keep their state in `ability.x_mult`, which PC Balatro applies itself; Balatro3DS only applies what `calculate` returns, so their `joker_main` returns it.
- Power Grid's PC version counts scored Mult cards with a Lovely patch; here the Joker counts them itself. Same numbers (the patch increments before the Joker's effect, and so does this).
- Red Envelope checks the blind index (3 = Boss) instead of `G.GAME.blind.boss`; it is still paid by `calc_dollar_bonus` in the end-of-round cash-out, as on PC.
- Jimbot reads the card view's base chip value; a Bonus card's +30 is added back by hand. Stone cards are excluded (on PC they have no number to capture).
- Fortune Cookie decays on the port's `using_consumeable` event (the used consumable's kind rides on `context.port.consumable_kind`) and eats itself with the fork's `SMODS.destroy_joker` instead of PC's delayed removal event.
- Rats! destroys through `SMODS.destroy_card` and duplicates through `SMODS.add_card`; the copy is created without an edition when the original is Negative, which is PC's anti-fill rule (PC's `can_spawn` flag is carried but, as on PC, never read).
- Cosmic Collapse has no `set_ability` to call, so a transform is the game's own consumable removal (which frees the Planet's slot first) plus a created `spectral_black_hole`. The odds roll through `SMODS.pseudorandom_probability`, so Oops! All 6s and probability Jokers apply as on PC.
- Loose Tooth's random Tarot is picked by the game's own `random_consumable_id_of_kind` (the pool The Fool's family uses), because the fork's `add_card` needs a def id where Steamodded picks for you. A scoring Ace is read off the port's `counts_for_play_score` marker.
- Scapegoat tracks "first discard of round" itself (reset at round begin): the port decrements its discard counter before the discard events fire, so PC's `discards_used` read has no equivalent. Its chip value rebuilds PC's `get_chip_bonus` from `card_data` (Stone counts 50, Bonus +30, permanent bonuses included) and the grant writes `card_data.Bonus`, the field Hiker writes. Because the game pushes a *copy* of a discarded card to the discard pile before the events fire, the port also removes that copy, so a destroyed card really leaves the game. Raw hand nodes have no `.debuff` field in this port, so the recipient check uses the game's own `debuffed` / `debuffed_for_scoring` predicate.

## Not ported (and why)

The other four KCVanilla Jokers still need things Balatro3DS mods do not have, even on the fork: Five-Day Forecast (Lovely patch on the rank-up path), Rakugo (booster-pack internals), Squid (live hands-left and projected score mid-round), Luck of the Irish (the port passes `trigger_obj = nil` for vanilla probability rolls, so a mod cannot tell which card rolled). Fortune Cookie, Rats!, Cosmic Collapse, Loose Tooth and Scapegoat were unblocked by the fork's Tier 1 API and joined the pack in v1.1.0.

Also found while porting: Balatro3DS does not fill `context.full_hand` for discard contexts (the batch is only in `context.port.discarded_nodes`). Handy Joker works around it; other discard mods should too.

## Validation

Each port was loaded through the real ModLoader and exercised in Balatro3DS's own headless test harness: Swiss Cheese 4/4 checks, the KCVanilla pack 13/13 at v1.0.0 and 9/9 in its v1.1.0 suite (registration and tooltips for all fourteen, create/destroy behavior for each of the five new Jokers, plus regression checks on the original nine), the Pokermon pack 18/18 (loading, registration, tooltips, scoring, retriggers, scaling, Articuno's card conversion), with the game's own mod suite still green (38 tests on the stock tree, 43/43 on the fork) and negative controls confirming the tests can fail. Hardware testing is the remaining step.

## Credits

- **krackocloud** — KCVanilla, its Joker designs, text and art. KCVanilla ships no license; this is an unofficial fan port made for personal use, published with credit. If you are krackocloud and want anything changed or removed, open an issue and it will be handled immediately.
- **InertSteak and the Pokermon contributors** — Pokermon, its Joker designs, text and art (GPLv3).
- **idkhan / Gazpacho** — Balatro3DS and its mod API.
- **LocalThunk** — Balatro.
