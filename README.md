# Balatro3DS Mods

Ports of PC Balatro mods to [Balatro3DS](https://github.com/idkhan/Balatro3DS) (the 3DS remake on Universal-Updater).

Ports of Jokers from [KCVanilla](https://github.com/kcgidw/kcvanilla) (PC Balatro mod by **krackocloud**) to [Balatro3DS](https://github.com/idkhan/Balatro3DS), the Balatro remake for Nintendo 3DS available on Universal-Updater.

Balatro3DS has a Steamodded-style mod loader, but PC mods do not drop in: there is no Lovely, no `G.GAME`, and card art must be one `.t3x` texture per card. Each Joker here was re-expressed against the port's documented mod API, with art cropped from KCVanilla's atlas, converted with tex3ds, and given a shader-free Negative variant made with Balatro3DS's own `dev/make_negative.py`.

## Install

1. Download a zip from this repo (or clone it).
2. Copy the mod folder (`KCVanillaSwiss`, `KCVanillaPack` or `NeatoPack`) to your SD card at `/3ds/save/Balatro3DS/sdmc/mods/`.
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


### NeatoPack — fifteen Jokers

Download: `balatro3ds-neato-pack-v1.1.0.zip`.

From **Neato Jokers** by neatoqueen. All fifteen Jokers in the PC mod are ported.

| Joker | Rarity / Cost | Effect |
|---|---|---|
| Unpaid Intern | Common / $6 | Scored 9s and 5s give +40 Chips |
| Tabby Cat | Common / $6 | Gains +2 Mult every 9 cards discarded |
| Wild Card Charlie | Uncommon / $7 | Wild Cards give X1.5 Mult when scored or held in hand |
| Lock-In Joker | Common / $4 | Gains +3 Mult when a Blind is selected, resets when a Joker is sold |
| Spare Cutoffs | Uncommon / $6 | Gains +12 Chips whenever a played hand contains a Two Pair |
| Ice Cream Sandwich | Uncommon / $6 | X5 Mult, loses X1 Mult per round played, eaten when it runs out |
| Australian Shepherd | Common / $4 | Create a random Planet card when a Blind is selected |
| The Banana Stand | Common / $6 | 1 in 4 chance for a played hand to give $10; 1 in 25 chance at end of round to be destroyed and lose ALL money |
| Blue Yourself | Rare / $8 | Retriggers Jokers and cards with the Foil edition |
| Dayman | Uncommon / $6 | If the first hand of the round is a single Queen, destroy it and gain X0.5 Mult |
| Nightman | Uncommon / $6 | When a hand is played, destroy a random scoring card and gain X0.1 Mult |
| Dogs Playing Balatro | Rare / $6 | 1 in 4 chance to fetch a random Spectral card when a Planet is used |
| Frosted Prime Rib | Uncommon / $6 | For the next 22 hands, every scored card permanently gains +2 Chips and +1 Mult |
| Hatsune Joku | Uncommon / $5 | Retrigger played 9s an additional two times |
| JokerZD | Rare / $8 | Gains X0.15 Mult for every unique Joker purchased |

**The last nine need the [Balatro3DS fork](https://github.com/sen2008/balatro3ds-fork) build.** They create and destroy cards and use retrigger returns through the fork's Tier 1 mod API (`SMODS.add_card` / `SMODS.destroy_joker` / `SMODS.destroy_card`), which the stock game does not have. On the stock Universal-Updater build the pack loads and the original six work, but those nine have no effects, and Ice Cream Sandwich floors at X1 instead of being eaten (it is destroyed as on PC only with the fork).

### PokermonPack — 50 Gen 1 Pokémon Jokers, with evolution (v1.1.0)

From **Pokermon** by InertSteak (the #2 most popular Balatro mod). Bulbasaur, Charmander and Squirtle (with their +hand size / +discard / +hand passives), Pikachu, Magikarp, the Caterpie, Weedle and Pidgey lines, Rattata/Raticate, Diglett/Dugtrio, Shellder/Cloyster, Goldeen/Seaking, Mr. Mime, Pinsir, Rapidash, Articuno, and more. Zip: `balatro3ds-pokermon-pack-v1.1.0.zip` (v1.0.0's zip is kept alongside).

Pokermon is **GPLv3**, so this port is published under GPLv3 with the original code credited below.

**Evolution (new in v1.1.0)** is implemented at pack level with the fork's Tier 1 mod API. On PC, Pokermon raises an evolution step after each round; the port checks the same counters on the round-end context. Where PC transforms the card in place and keeps its slot, the port destroys the old Joker and creates the evolved form (`SMODS.destroy_joker` + `SMODS.add_card`), so the evolved form takes the last Joker slot; the edition and any grown values PC would keep (a scaling total whose per-step gain is still on the card) carry over, stickers do not. **Evolution needs the [fork](https://github.com/sen2008/balatro3ds-fork) build** — on the stock game the Tier 1 calls do not exist and nothing evolves, exactly as in v1.0.0; every stage is still a standalone shop Joker either way.

Per-chain status:

- **Ported:** Bulbasaur → Ivysaur → Venusaur (after earning $16 in held-card payouts per stage), Charmander → Charmeleon → Charizard (at +16, then +36 grown Mult; the Mult carries), Squirtle → Wartortle → Blastoise (at +40, then +120 grown Chips; the Chips carry), Caterpie → Metapod (2 rounds) → Butterfree (3), Weedle → Kakuna (2) → Beedrill (3), Pidgey → Pidgeotto (4) → Pidgeot (4), Rattata → Raticate (5), Ekans → Arbok (4), Sandshrew → Sandslash (4), Diglett → Dugtrio (4), Tentacool → Tentacruel (5), Krabby → Kingler (4), Magnemite → Magneton (4), Goldeen → Seaking (5), Magikarp → Gyarados (8).
- **Blocked — item evolutions:** Pikachu → Raichu (Thunder Stone), Clefairy → Clefable (Moon Stone), Jigglypuff → Wigglytuff (Moon Stone), Growlithe → Arcanine (Fire Stone), Shellder → Cloyster (Water Stone). The stones are Pokermon consumable items and do not exist in the port, so these chains never evolve; Raichu, Clefable, Wigglytuff and Arcanine are still in the pack as standalone Jokers (Cloyster already was).
- The fifteen new forms' art is sliced from Pokermon's own Natdex atlas; the original 35 keep their pack art.

Port notes:

- **No Energy, no items**: Balatro3DS has neither system, so each Pokémon ships with its base effect at base (un-energized) values. The custom `poke_safari` rarity maps to Rare.
- Bulbasaur's designated rank is re-rolled at blind select, as in the original. Charmander/Squirtle scaling reads the port's live `G.discards` / `G.hands` counters.
- Retrigger Pokémon (Rattata line, Shellder line, Goldeen line, Mr. Mime) use the port's `context.repetition`; "first N scoring cards" is resolved through `context.port.played_cards`, since the repetition context has no `scoring_hand`.
- Magneton counts adjacent Metal Jokers as PC does, but Pokémon types do not exist in the port and the only Metal line in this roster is Magnemite/Magneton, so adjacency counts those two. Arbok creates its Tarot during scoring instead of before it.
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
- Dayman and Nightman (Neato) destroy played cards in the port's `after` pass, the slot the port's own Sixth Sense uses for Steamodded's `destroying_card` context, which Balatro3DS never raises; the destroyed card still scores first, as on PC. Dayman's "first hand of round" reads the game's `get_round_hands_played()`.
- Frosted Prime Rib's permanent gains write `card_data.Bonus` (the field Hiker writes) and `card_data.mult_bonus`, the two fields the game's modifier path reads back when the card scores again; only scoring cards are granted, via the `counts_for_play_score` marker Hiker checks.
- Blue Yourself answers both of the port's retrigger passes: `retrigger_joker_check` for Foil Jokers (the other Joker's def id and normalized edition stand in for PC's `config.center.key` / `edition.key`) and `context.repetition` for Foil playing cards (whose edition lives in `card_data.modifier.edition`). Its `in_pool` gate is kept — the port supports `in_pool` and the deck half reads the game's full-deck counter — but PC's guard against retriggering a foil Blueprint that is itself copying Blue Yourself reads `context.other_ret`, which the port does not provide, and is dropped.
- Australian Shepherd and Dogs Playing Balatro pick their random consumable with the game's own `random_consumable_id_of_kind` (which never offers The Soul or a Black Hole), since the fork's `add_card` needs a def id where Steamodded picks for you. Australian Shepherd's `getting_sliced` check is dropped; port Jokers do not carry that flag.
- The Banana Stand destroys itself with the fork's `SMODS.destroy_joker` and zeroes the money through the mod environment's `ease_dollars`, where PC queues a delayed event; the rolls go through `SMODS.pseudorandom_probability`, so Oops! All 6s applies as on PC.
- JokerZD counts unique purchases by def id (`context.port.offer_id` on the port's shop-buy event) where PC counts by card label; buying JokerZD itself is excluded, as on PC.
- Hatsune Joku is the effect only: the PC mod's custom music track (`SMODS.Sound`, its config tab and the `add_to_deck` juice) has no port equivalent.

## Not ported (and why)

The other four KCVanilla Jokers still need things Balatro3DS mods do not have, even on the fork: Five-Day Forecast (Lovely patch on the rank-up path), Rakugo (booster-pack internals), Squid (live hands-left and projected score mid-round), Luck of the Irish (the port passes `trigger_obj = nil` for vanilla probability rolls, so a mod cannot tell which card rolled). Fortune Cookie, Rats!, Cosmic Collapse, Loose Tooth and Scapegoat were unblocked by the fork's Tier 1 API and joined the pack in v1.1.0.

Neato Jokers is fully ported as of NeatoPack v1.1.0 (15/15): the nine that were blocked on create/destroy/retrigger-return mechanics (Australian Shepherd, The Banana Stand, Blue Yourself, Dayman, Nightman, Dogs Playing Balatro, Frosted Prime Rib, Hatsune Joku, JokerZD) were unblocked by the same Tier 1 API. Only pieces around them did not port: Hatsune Joku's music track and config tab, and Blue Yourself's `other_ret` sub-guard (see Port notes).

Also found while porting: Balatro3DS does not fill `context.full_hand` for discard contexts (the batch is only in `context.port.discarded_nodes`). Handy Joker works around it; other discard mods should too.

## Validation

Each port was loaded through the real ModLoader and exercised in Balatro3DS's own headless test harness: Swiss Cheese 4/4 checks, the KCVanilla pack 13/13 at v1.0.0 and 9/9 in its v1.1.0 suite (registration and tooltips for all fourteen, create/destroy behavior for each of the five new Jokers, plus regression checks on the original nine), the Pokermon pack 18/18 at v1.0.0 and 25/25 in its v1.1.0 suite (registration and tooltips for all fifty, evolution chains end to end for the Caterpie, Charmander, Squirtle, Bulbasaur and Magikarp lines, edition preservation, blocked stone chains correctly never evolving, plus regression checks on the original eighteen), the Neato pack 7/7 at v1.0.0 and 18/18 in its v1.1.0 suite (registration and tooltips for all fifteen, create/destroy/retrigger behavior for each of the nine new Jokers, the self-destroy fixes for Ice Cream Sandwich and The Banana Stand, plus regression checks on the original six), with the game's own mod suite still green (38 tests on the stock tree, 43/43 on the fork) and negative controls confirming the tests can fail. Hardware testing is the remaining step.

## Credits

- **krackocloud** — KCVanilla, its Joker designs, text and art. KCVanilla ships no license; this is an unofficial fan port made for personal use, published with credit. If you are krackocloud and want anything changed or removed, open an issue and it will be handled immediately.
- **neatoqueen (Neato)** — Neato Jokers, its Joker designs, text and art. Neato Jokers ships no license; this is an unofficial fan port made for personal use, published with credit. If you are neatoqueen and want anything changed or removed, open an issue and it will be handled immediately.
- **InertSteak and the Pokermon contributors** — Pokermon, its Joker designs, text and art (GPLv3).
- **idkhan / Gazpacho** — Balatro3DS and its mod API.
- **LocalThunk** — Balatro.
