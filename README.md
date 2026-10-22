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

### PokermonPack — 50 Gen 1 Pokémon Jokers, with evolution and the evolution stones (v1.2.0)

From **Pokermon** by InertSteak (the #2 most popular Balatro mod). Bulbasaur, Charmander and Squirtle (with their +hand size / +discard / +hand passives), Pikachu, Magikarp, the Caterpie, Weedle and Pidgey lines, Rattata/Raticate, Diglett/Dugtrio, Shellder/Cloyster, Goldeen/Seaking, Mr. Mime, Pinsir, Rapidash, Articuno, and more. Zip: `balatro3ds-pokermon-pack-v1.2.0.zip` (the v1.0.0 and v1.1.0 zips are kept alongside).

Pokermon is **GPLv3**, so this port is published under GPLv3 with the original code credited below.

**Evolution (new in v1.1.0)** is implemented at pack level with the fork's Tier 1 mod API. On PC, Pokermon raises an evolution step after each round; the port checks the same counters on the round-end context. Where PC transforms the card in place and keeps its slot, the port destroys the old Joker and creates the evolved form (`SMODS.destroy_joker` + `SMODS.add_card`), so the evolved form takes the last Joker slot; the edition and any grown values PC would keep (a scaling total whose per-step gain is still on the card) carry over, stickers do not. **Evolution needs the [fork](https://github.com/sen2008/balatro3ds-fork) build** — on the stock game the Tier 1 calls do not exist and nothing evolves, exactly as in v1.0.0; every stage is still a standalone shop Joker either way.

Per-chain status:

- **Ported:** Bulbasaur → Ivysaur → Venusaur (after earning $16 in held-card payouts per stage), Charmander → Charmeleon → Charizard (at +16, then +36 grown Mult; the Mult carries), Squirtle → Wartortle → Blastoise (at +40, then +120 grown Chips; the Chips carry), Caterpie → Metapod (2 rounds) → Butterfree (3), Weedle → Kakuna (2) → Beedrill (3), Pidgey → Pidgeotto (4) → Pidgeot (4), Rattata → Raticate (5), Ekans → Arbok (4), Sandshrew → Sandslash (4), Diglett → Dugtrio (4), Tentacool → Tentacruel (5), Krabby → Kingler (4), Magnemite → Magneton (4), Goldeen → Seaking (5), Magikarp → Gyarados (8).
- **Item evolutions (new in v1.2.0):** Pikachu → Raichu (Thunder Stone), Clefairy → Clefable (Moon Stone), Jigglypuff → Wigglytuff (Moon Stone), Growlithe → Arcanine (Fire Stone), Shellder → Cloyster (Water Stone). The four stones are Item consumables registered under the pack's own `poke_item` type through the fork's `SMODS.ConsumableType`, at PC's shop_rate 4 and $4 cost, so they roll in the shop as their own kind; using one evolves the leftmost held Joker it applies to. The Leaf Stone is not ported (its Gen 1 targets — Gloom, Weepinbell, Exeggcute — are not in the pack), and Magneton does not take the Thunder Stone here (its PC evolution, Magnezone, is not in the pack).
- The fifteen new forms' art is sliced from Pokermon's own Natdex atlas; the original 35 keep their pack art.

Port notes:

- **No Energy**: Balatro3DS has no Energy system, so each Pokémon ships with its base effect at base (un-energized) values. The custom `poke_safari` rarity maps to Rare.
- **Stones are evolution-only here**: on PC a stone can be aimed at a highlighted Joker, carries a secondary playing-card effect (Fire: Mult cards, Water: Bonus cards, Thunder: Gold copies, Moon: upgrade a poker hand), and the evolution lands at the end of the round. The fork has no Joker highlighting for consumables and the secondary effects are not ported, so a stone is usable exactly when a Joker it evolves is held (never a debuffed one, as on PC) and evolves the leftmost one on the spot through the same destroy+create call as the other chains. The fork also gives a custom kind no booster pack or collection tab, so stones arrive through the shop roll only (PC also puts them in Item packs). On the stock game the type API does not exist, no stones register, and the five chains stay unevolved.
- Bulbasaur's designated rank is re-rolled at blind select, as in the original. Charmander/Squirtle scaling reads the port's live `G.discards` / `G.hands` counters.
- Retrigger Pokémon (Rattata line, Shellder line, Goldeen line, Mr. Mime) use the port's `context.repetition`; "first N scoring cards" is resolved through `context.port.played_cards`, since the repetition context has no `scoring_hand`.
- Magneton counts adjacent Metal Jokers as PC does, but Pokémon types do not exist in the port and the only Metal line in this roster is Magnemite/Magneton, so adjacency counts those two. Arbok creates its Tarot during scoring instead of before it.
- Tentacruel's "10s can't be debuffed" and Snorlax/Eevee-style effects bound to Pokermon's item/evolution systems did not port. Eevee and Snorlax are not in the pack for that reason.
- Articuno adds Foil and a random seal to the first scoring card, but only if it has neither yet (the original converts unconditionally). Art is cropped from Pokermon's own Natdex sheet, with the legendary "soul" layer composited in.

### BuncoPack — 51 Jokers, the exotic suits and the Spectrum hands (v1.1.0)

Download: `balatro3ds-bunco-pack-v1.1.0.zip`.

From **Bunco** by Firch — the biggest single pack here, and the first to port a PC mod's custom suits and poker hands. Bunco adds two **exotic suits** (Fleurons, Halberds), four **Spectrum-family hands** (Spectrum, Straight Spectrum, Spectrum House, Spectrum Five) plus Registration Plate's **Deal**, and a per-run exotic system: score any Spectrum-family hand once and exotic-suit cards start appearing in Standard packs and the shop, and the exotic Jokers enter the pools. Also included: the four Spectrum Planets (Quaoar, Haumea, Sedna, Makemake) and the exotic Tarots (The Sky, The Abyss).

**Everything new in v1.1.0 needs the [Balatro3DS fork](https://github.com/sen2008/balatro3ds-fork) build** — Tier 1 (create/destroy cards, retrigger returns), Tier 2 (`SMODS.Suit`, `SMODS.PokerHand`), and one small fork addition made for this pack: a suit's `in_pool` now also gates the random playing-card fronts the game deals into Standard packs and shop cards, which is the route exotic cards take on PC. On the stock Universal-Updater build the original nineteen Jokers still work (without their exotic branches); the new content has no effects.

| Joker | Rarity / Cost | Effect |
|---|---|---|
| Cassette | Uncommon / $5 | Side A: light-suit cards give +45 Chips when scored; side B: dark-suit cards give +6 Mult; flips on discard |
| Mosaic Joker | Uncommon / $4 | Played Stone Cards give +6 Mult when scored |
| Voxel Joker | Uncommon / $5 | X3 Mult, −X0.1 per enhanced card in the full deck |
| Crop Circles | Common / $4 | Scored cards give Mult by natural suit and rank (Fleurons pay most, then Clubs) |
| Prehistoric Joker | Uncommon / $5 | +16 Mult when a scored card repeats an earlier scored card this round |
| Shepherd Joker | Common / $5 | Gains +12 Chips per Pair played this round |
| Jumper | Common / $5 | Gains +8 Chips per Flush played this round |
| Dogs Playing Poker | Uncommon / $5 | X2.5 Mult if every scoring rank is 5 or below |
| Headshot | Uncommon / $8 | X3 Mult if exactly one face card scores |
| Nil Bill | Uncommon / $4 | Earn $2 per card destroyed |
| Slothful Joker | Uncommon / $5 | Wild Cards give +9 Mult when scored |
| Hierarchy of Needs | Common / $5 | +2 Mult per rank of a complete suit sequence in the deck |
| Protester | Common / $4 | Banks Chips equal to 8× the highest rank discarded this round |
| Disproportionality | Common / $4 | Gives a random amount of Chips (10–210) |
| On Broadway | Uncommon / $6 | +120 Chips and +20 Mult on a Straight with a scoring face card |
| Rasta | Common / $5 | +12 Mult if no scoring card is enhanced |
| Critic | Common / $6 | X2 Mult while the hand's score is under a third of the blind target |
| Wino | Common / $5 | Hearts and Diamonds give +12 Chips when scored |
| Tangram | Rare / $7 | Scored 7s give +7 Mult per 7 in the played hand |
| Basement Joker | Rare / $8 | When the Boss Blind is defeated, create a random Spectral card |
| Carnival | Rare / $10 | After defeating the Boss Blind, destroy a random Joker and go one Ante back (once per Ante) |
| Dread | Rare / $8 | After the last hand, level it by 2 and destroy the played cards; removal reverses the levels |
| The Joker | Rare / $10 | Each unenhanced scoring card has a 1 in 3 chance to be destroyed after play |
| Registration Plate | Rare / $8 | Five ranks from your deck form the Deal hand, re-rolled each round |
| Righthook | Rare / $8 | Retrigger the last scoring card once per remaining hand |
| Linocut Joker | Uncommon / $4 | A played Pair of exactly two converts the left card's suit into the right card's |
| Ghost Print | Uncommon / $6 | Gives the Chips and Mult of the last hand type played |
| Loan Shark | Uncommon / $3 | Gain $50 when acquired; sell value is −$100 |
| Fingerprints | Uncommon / $8 | Scored cards gain +50 Chips for the next round |
| Bierdeckel | Uncommon / $4 | Cards left in hand gain +10 Chips until end of round |
| Zero Shapiro | Uncommon / $4 | Scored Ks, Qs, Js and Stone cards: 1 in 8 chance to create a D6 Tag |
| Doodle | Rare / $10 | Once per round, using a Tarot or Planet duplicates it |
| Pawn | Common / $5 | Scored cards tied for the deck's lowest rank gain +1 rank |
| Hopscotch | Common / $4 | +1 discard this round when you play a Straight |
| X-Ray | Common / $4 | X0.2 Mult per card drawn face down |
| Mousetrap | Uncommon / $6 | 1 in 3 chance to lose a hand instead of scoring; at 0 hands, +300 Chips instead |
| Stylophone | Uncommon / $5 | Scored cards give +0.3 Mult per pip of rank |
| Juggalo | Rare / $5 | On blind select, a random owned consumable gains a random edition |
| Puzzle Board | Uncommon / $6 | Using a Tarot: 1 in 4 chance to put a random edition on a highlighted card |
| Zealous Joker | Common / $3 | +10 Mult if the played hand contains a Spectrum (exotic) |
| Lurid Joker | Common / $3 | +80 Chips if the played hand contains a Spectrum (exotic) |
| Envious Joker | Common / $5 | Scored Fleurons give +6 Mult (exotic) |
| Proud Joker | Common / $5 | Scored Halberds give +6 Mult (exotic) |
| Wishalloy | Uncommon / $7 | 1 in 7 for scored Fleurons to earn $ equal to their scored Chips (exotic) |
| Unobtanium | Uncommon / $7 | Scored Halberds give +30 Chips and +6 Mult (exotic) |
| Magic Wand | Common / $5 | Gains +3 Mult per consecutive Spectrum hand, resets otherwise (exotic) |
| Starfruit | Uncommon / $5 | Level up a Spectrum hand; 1 in 4 chance to be destroyed at end of round (exotic) |
| Fondue | Rare / $8 | First hand's scored cards become Fleurons (exotic) |
| Roy G. Biv | Uncommon / $8 | 1 in 7 to give every scored card Polychrome on a Spectrum hand (exotic) |
| The Dynasty | Rare / $8 | X5 Mult if the played hand contains a Spectrum (exotic) |
| Rigoletto | Legendary / $20 | X1 Mult + X0.2 per exotic card in the full deck (exotic) |

Port notes:

- **The exotic gate is derived, not stored**: PC flips a per-run `G.GAME.Exotic` flag from a Lovely hand-played patch; the port reads the game's own per-hand play counts (persisted in the run save), so a Spectrum-family hand with a count above zero means exotics are on. The same gate feeds both the exotic Jokers' `in_pool` and the fork's random-front pool.
- **The Sky and The Abyss are not pool-gated here**: mod consumables have no `in_pool` on the port, so the two exotic Tarots can appear before exotics are on (on PC they cannot). Using one is still only a suit conversion.
- Bunco's **temporary extra chips** (Fingerprints, Bierdeckel) are a `Card:get_chip_bonus` patch on PC; here the grants ride on `card_data.Bonus`, tracked per Joker by card uid and removed at end of round, which reproduces their lifetimes (Fingerprints through the next round, Bierdeckel for the rest of the current one).
- **X-Ray** banks at deal-complete: the port reports a draw in one `hand_drawn` event carrying the drawn set, where PC patches each card's emplacement.
- **Juggalo** cannot roll Bunco's custom Glitter edition (custom editions cannot be registered); its roll is Foil / Holographic / Polychrome. **Stylophone**'s sound-click ladder is cosmetic on PC and is not ported.
- **Deal** rewrites its own hand stats inside its `evaluate` (level 1, base values set to the banked totals), the one place the port recomputes a hand's score from its stats.

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

Bunco is 51 of 80 in BuncoPack v1.1.0. The other 29 stay blocked, each on a named system the port does not expose: Knight (its Mult reset rides Bunco's Lovely patch on Joker-area reordering; the port raises no rearrangement event), JMJB and Aristocrat (booster-pack internals: the port's booster-open context fires empty, before the pack's cards exist, and mods cannot change a pack's choice count), Fiendish and Bounty Hunter (Bunco's global `ease_dollars` wrapper — double / tax every money gain; the port applies money only through Joker returns), Sledgehammer, Dwarven and Metallurgist (they rewrite enhancement center configs — Glass XMult and break odds, Stone and Gold held effects — which are hardcoded game constants here), Doorhanger (pool filtering of *other* Jokers by rarity; a Joker's `in_pool` governs only itself), Neon (Bunco's custom Fluorescent edition plus an `enhance_card` context the port never raises), Gameplan and Conquest (Bunco's `set_debuff` hook into blind debuff evaluation), Head in the Clouds (a hand-levelled context; the port emits none), Trigger Finger (a `highlight_card` context plus forcing a play), Vandalism (the port flips played face-down cards face-up before any Joker context, so no Joker can learn which were face down), Cellphone (a Lovely redirect of scored cards back to hand plus a `press_play` context), Domino (pre-purchase shop contexts and inserting free acquisitions into the shop), Glue Gun, Taped, Rubber Band Ball and Games Collector (Bunco's linked-group card system and its `groups_drawn` context), Headache (creates Bunco's custom Arcade Tag; mod tags cannot be registered), Kite Experiment and Robot (Bunco's Copper enhancement and `rescore_cards` context; custom enhancements cannot be registered), Hardtack and Pica (their effects live in Bunco's Cracker enhancement system), Myopia and Astigmatism (global `Card:is_suit` patches), Running Joke (inserting a shop offer at shop start; offers are built game-side).

Also found while porting: Balatro3DS does not fill `context.full_hand` for discard contexts (the batch is only in `context.port.discarded_nodes`). Handy Joker works around it; other discard mods should too.

## Validation

Each port was loaded through the real ModLoader and exercised in Balatro3DS's own headless test harness: Swiss Cheese 4/4 checks, the KCVanilla pack 13/13 at v1.0.0 and 9/9 in its v1.1.0 suite (registration and tooltips for all fourteen, create/destroy behavior for each of the five new Jokers, plus regression checks on the original nine), the Pokermon pack 18/18 at v1.0.0, 25/25 in its v1.1.0 suite and 31/31 in its v1.2.0 suite (registration and tooltips for all fifty, evolution chains end to end for the Caterpie, Charmander, Squirtle, Bulbasaur and Magikarp lines, edition preservation, stone chains correctly never evolving on round end alone, plus — at v1.2.0 — the four stones' registration under the poke_item type, shop-roll sampling, per-line evolution and refusal checks, leftmost targeting, and edition/scaling preservation through a stone evolution, plus regression checks on the original eighteen), the Neato pack 7/7 at v1.0.0 and 18/18 in its v1.1.0 suite (registration and tooltips for all fifteen, create/destroy/retrigger behavior for each of the nine new Jokers, the self-destroy fixes for Ice Cream Sandwich and The Banana Stand, plus regression checks on the original six), the Bunco pack 17/17 at v1.0.0 and 38/38 in its v1.1.0 suite (registration and tooltips for all fifty-one Jokers and six consumables, both exotic suits, every Spectrum-family hand plus Deal evaluated through the game's own hand classifier, the exotic gate opening and shutting, and create/destroy/level/retrigger behavior for the new Jokers), with the game's own mod suite still green (38 tests on the stock tree, 54/54 on the fork, including the suit-front gate test the Bunco pack needed and the consumable-type tests the Pokermon stones needed) and negative controls confirming the tests can fail. Hardware testing is the remaining step.

## Credits

- **krackocloud** — KCVanilla, its Joker designs, text and art. KCVanilla ships no license; this is an unofficial fan port made for personal use, published with credit. If you are krackocloud and want anything changed or removed, open an issue and it will be handled immediately.
- **neatoqueen (Neato)** — Neato Jokers, its Joker designs, text and art. Neato Jokers ships no license; this is an unofficial fan port made for personal use, published with credit. If you are neatoqueen and want anything changed or removed, open an issue and it will be handled immediately.
- **InertSteak and the Pokermon contributors** — Pokermon, its Joker designs, text and art (GPLv3).
- **Firch** — Bunco, its Joker designs, text and art, including the exotic suits and Spectrum hands. Bunco ships no license; this is an unofficial fan port made for personal use, published with credit. If you are Firch and want anything changed or removed, open an issue and it will be handled immediately.
- **idkhan / Gazpacho** — Balatro3DS and its mod API.
- **LocalThunk** — Balatro.
