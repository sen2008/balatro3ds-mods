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

### PaperbackPack — 224 Jokers, the Stars and Crowns suits, the Spectrum hands and the Minor Arcana (v1.0.0)

Download: `balatro3ds-paperback-pack-v1.0.0.zip`.

From **Paperback** by Nether and contributors (MIT License) — the largest pack here. 224 of Paperback's 316 Jokers are ported, plus its two custom suits (**Stars**, light; **Crowns**, dark), the four **Spectrum-family hands** (Spectrum, Straight Spectrum, Spectrum House, Spectrum Five, at Paperback's own values), and **33 of the 56 Minor Arcana** as a registered `minor_arcana` consumable type. The full roster with one-line effects is in the pack's README.txt. **The whole pack needs the [Balatro3DS fork](https://github.com/sen2008/balatro3ds-fork) build** — it creates and destroys cards (Tier 1), registers suits, hands and rarities (Tier 2), registers the Minor Arcana type and gates exotic-suit fronts (`SMODS.ConsumableType`, the suit `in_pool` hook), and grants vanilla tags through `Game:addTag`.

Port notes:

- **The exotic gate works like Bunco's**: score any Spectrum-family hand once (or hold a Stars/Crowns card in the deck) and the two suits enter the random card-front pool. Where Bunco and Paperback register the same hand names, the values agree; the guards make double registration a no-op, so the two packs coexist.
- **Minor Arcana have shop rate 3 here**; on PC their rate is 0 (booster-delivered) and the fork cannot register boosters — the one structural deviation of the set. Joker-targeting Arcana act on the leftmost eligible held Joker (no Joker-highlight targeting exists), the same compromise as the Pokermon stones.
- **Nazar counts Tarot and Minor Arcana**, as on PC — and the re-audit rescued three Jokers the first audit had classed as tag-blocked: **56 Leaf Clover, Ghost Cola and ShadowMantle** create the *vanilla* Negative Tag, which the fork grants through `Game:addTag` (the route Bunco's Zero Shapiro uses for the D6 Tag). Paperback's *custom* tags remain unregistrable, which is what keeps the other nine tag Jokers out (see Not ported).
- **Destruction ordering rides the before/after passes**: the fork never raises PC's `destroy_card` context, so Jokers that destroy scored cards (Alert, The Batter, Thornring, Whitebeard, Buckshot and friends) destroy in the hand's before/after slots, the Dayman/Bunco precedent — the card still scores first where PC scores it first. Jokers that *react* to destructions they did not order stay blocked: another Joker's destruction raises no event a mod can see, so Black Forest Cake and Cardboard Box scale only on playing-card destruction, and Sacrificial Lamb keeps only its playing-card half.
- **The ports follow Paperback's code where it disagrees with its tooltips** (Disco checks the wallet when buying; Der Freischütz takes the lowest chip-value card in the full deck, 7s included; Showdown's chance gate; The Normal Joker is Rare $8 as its def says, not Common). Permanent per-card bonuses write the fields the fork's scoring reads (`card_data.chip_bonus` / `mult_bonus` / `Bonus`).
- **OFF Switch** cannot create its eternal addon Jokers (Off Alpha/Epsilon/Omega are themselves blocked on the `joker_type_destroyed` context); it creates **The Batter** uneternal instead, only when that def is registered. Its `add_to_deck` also means a test (or player) adding it gains a second Joker — intended, as on PC. **Red Key** creates a random Rare (no Ultra Secret rarity exists here), **Freezer** a random Negative Common/Uncommon (no Food pool exists).

### MoreFluffPack — 89 Jokers (v1.1.0)

Download: `balatro3ds-morefluff-pack-v1.1.0.zip`.

From **MoreFluff** by notmario — the biggest single-author Joker mod for PC Balatro. 89 of its 229 Jokers are ported, including the Letter Jokers, the Scrapped set and the token Jokers. **The pack needs the [Balatro3DS fork](https://github.com/sen2008/balatro3ds-fork) build**: it registers MoreFluff's six custom rarities and uses the fork's `SMODS.add_card` / `SMODS.destroy_card`, retrigger returns, `post_trigger` passes and probability-shaping contexts. The six custom rarities are registered at weight 0, as on PC their Jokers arrive through other Jokers and effects rather than the shop (Forge and Letter F create them; Fish is a token). The other 140 Jokers stay blocked on systems the fork does not have — Slivers, Colour cards, prepared cards, exile, custom enhancements and more; each one is listed under Not ported below. Deviations from PC are listed in the pack's README.txt (the largest: Blade Dance's Steel cards are permanent here, Brainrot's destroy forces past Eternal, and Expansion Pack's modded pool is this pack's own Jokers).

| Joker | Rarity | Cost |
|---|---|---|
| [[BIG SHOT]] | Scrapped | $7 |
| A | Letter | $2 |
| Bad Legal Defence | Uncommon | $6 |
| Basepaul Card | Common | $5 |
| Big Win | Uncommon | $7 |
| Black Market | Scrapped | $4 |
| Blade Dance | Uncommon | $8 |
| Book Move | Rare | $10 |
| Bowling Ball | Rare | $8 |
| Brainrot | Scrapped | $6 |
| Brilliant | Uncommon | $8 |
| Burner Phone | Scrapped | $2 |
| C | Letter | $6 |
| Card Buffer Advanced | Rare | $10 |
| Clownfish | Common | $6 |
| Contract from Below | Rare | $9 |
| Coupon Catalogue | Scrapped | $7 |
| D | Letter | $4 |
| DINNER! | Uncommon | $5 |
| Disintegration Loop | Rare | $10 |
| Dramatic Entrance | Uncommon | $6 |
| Expansion Pack | Common | $6 |
| F | Letter | $8 |
| Fish | Token | $1 |
| Forge Residue | Token | $0 |
| Friend Inside Me | Uncommon | $7 |
| G | Letter | $4 |
| Globe | Uncommon | $6 |
| Golden Carrot | Uncommon | $4 |
| grep | Rare | $8 |
| H | Letter | $8 |
| Hall of Mirrors | Scrapped | $6 |
| Hollow Joker | Common | $4 |
| Huge Joker | Rare | $8 |
| Hyper Beam | Uncommon | $8 |
| I | Letter | $2 |
| I Sip Toner Soup | Scrapped | $8 |
| Ice Cube | Uncommon | $6 |
| Impostor | Scrapped | $7 |
| J | Letter | $16 |
| Jack of All Trades | Common | $6 |
| Jester | Common | $2 |
| Joker Forge | Uncommon | $6 |
| Jokes for Balatro Players | Common | $7 |
| K | Letter | $10 |
| Knuckleblaster | Uncommon | $6 |
| Less Fluff | Rare | $10 |
| Lollipop | Common | $6 |
| Lucky Charm | Common | $6 |
| M | Letter | $6 |
| Mashup Album | Scrapped | $8 |
| Miner | Scrapped | $5 |
| Money Printer | Scrapped | $5 |
| MS Paint Joker | Common | $5 |
| N | Letter | $2 |
| O | Letter | $2 |
| One Slip Too Late | Uncommon | $5 |
| Oops! All 5s | Token | $1 |
| Particle Accelerator | Scrapped | $7 |
| Passing Balatro in 5 Minutes | Uncommon | $6 |
| Philosophical Joker | Common | $1 |
| Pixel Joker | Rare | $8 |
| Q | Letter | $20 |
| Recycling | Uncommon | $5 |
| Retrigger Joker | Uncommon | $8 |
| Riding the Dilu Horse | Rare | $7 |
| S | Letter | $2 |
| Simplified Joker | Common | $5 |
| Spiral Joker | Common | $5 |
| Steamflogger Boss | Scrapped | $6 |
| Stifle | Common | $4 |
| StoneJoker Joker | Uncommon | $8 |
| Stormscale Scion | Scrapped | $10 |
| Style Meter | Uncommon | $6 |
| Sudoku Joker | Scrapped | $9 |
| Sword of Steven and Todd | Rare | $10 |
| The Baseball Stream | Rare | $10 |
| The Broom Closet | Uncommon | $4 |
| The Jester | Scrapped | $20 |
| The Solo | Rare | $7 |
| Top 10 Jokers From 1 To 10 | Rare | $10 |
| Treasure Map | Common | $4 |
| Triangular Joker | Scrapped | $7 |
| V | Letter | $8 |
| Virtual Joker | Scrapped | $7 |
| W | Letter | $8 |
| Whiteboard | Scrapped | $6 |
| Wild Draw Four | Scrapped | $7 |
| Y | Letter | $8 |

### CryptidPack — 140 Jokers, four custom rarities, the Bulwark and UltPair hands, the Code and Unique consumable types (v1.1.0)

Download: `balatro3ds-cryptid-pack-v1.1.0.zip`.

From **Cryptid** by the Cryptid team (SpectralPack) — the biggest content mod for PC Balatro. 140 of its Jokers and 22 of its consumables are ported, completing the v1.0.0 seven-Joker first pass (Dubious Joker, Absurd Joker, Shrewd Joker, Nutty Joker, The Duos, The Home, Triplet Rhythm — unchanged). **The pack needs the [Balatro3DS fork](https://github.com/sen2008/balatro3ds-fork) build**: it registers Cryptid's Epic, Exotic, Candy and Cursed rarities, the Bulwark and UltPair poker hands and the Code and Unique consumable types, and uses the fork's create/destroy APIs and retrigger returns throughout. On the stock Universal-Updater build the pack does not load.

- **Epic** registers at shop weight 0.3, as on PC; **Exotic** at weight 0, as on PC — Exotics are never sold, they arrive through Gateway and other creation effects. **Candy** and **Cursed** take the fork's default weight of 3.
- **Bulwark** (five Stone cards) and **UltPair** (two or more pairs in each of two suits) register as poker hands with their PC values, and their Planet consumables (Asteroid Belt, Phobos & Deimos) plus the Finnish planet family and Kaikki level them here. Like every custom hand on the fork they rank below High Card in hand contests, because the fork's evaluator names hands by list position.
- **Code** cards get shop rate 1: PC rates them 0 because PC has Code booster packs, which the fork does not, so the shop is the only way the two ported Code cards (://CTRL+V and The Automaton's creations) can appear. **Unique** stays at rate 0, as on PC.
- Cryptid's gameset system (Modest / Mainline / Madness) is not ported; every effect uses its standard rules. Cube is free instead of -$27 (the fork requires cost >= 0), Kitty Printer drops its Cat Tag conversion, Adversary drops its shop-price doubling (so the port is strictly stronger than PC), and ://CTRL+V and Conduit cover playing cards only. Every deviation is listed in the pack's README.txt.
- The 14 Talisman big-number Jokers stay blocked, uncapped and unfaked; the other 125 blocked items each name their missing system under Not ported below and in the pack's README.txt.

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

Paperback is 224 of 316 in PaperbackPack v1.0.0, plus 33 of 56 Minor Arcana. The other 92 Jokers stay blocked, each on a named system: the eight custom enhancements (Soaked, Sleeved, Bandaged, Wrapped, Ceramic, Domino, Stained, Antique) gate 16 (Blood Rain, Collector, Festive Joker, Gauze, Greeting Card, Happy Accident, Kintsugi Joker, Medic, Mexican Train, Pink Joker, Pinot Noir, Plastic Wrap, Sommelier, Spotty Joker, Teapot, Watercolor Joker) and 8 more Arcana; XChips and permanent-X fields with no scoring reader block 14 (Bergentrücking, Blue Star, Chocolate Joker, Crispy Taco, Deck of Cards, Freedom of Choice, Grenadine, Nachos, Nigori, Oracle, Quartz, Ready to Fly, Shinzaemon, Stella Octangula); Paperback's custom tags and tag copying/polling block 9 (Angel Investor, Book of Life, J and Js, Jimbo Adventure, Jokers 11, Shopkeep, Spirit Box, Stereoscopic Specs, The Wonder of You); the Apostle custom rank blocks 6 (As Above So Below, In Case I Make It, One Sin and Hundreds of Good Deeds, Penumbra Phantasm, Plague Doctor, White Night); E.G.O Gifts block 4 (Arayashiki, Fodder, Grimoire, The Strongest); paperclips block 4 Jokers (Chip Clip, Clippy, Clothespin, Manilla Folder) and 11 Arcana; shop/pool/voucher manipulation blocks 9 (Backpack, Membership Card, NormalJKR, Protocol, Shopping Center, Touch Tone Joker, Ouija Board, Chaplin, Everything Must Go); blueprint-copy effects block 3 (Forgery, Master Plan, Photocopy); the balance mechanic blocks 3 (Let It Happen, Milk Tea, Stardrop); unraised contexts block 10 (Coin Collection and Frutiger Aero on money_altered, Cream Liqueur on tag activation, Off Alpha/Epsilon/Omega on joker_type_destroyed, One With Nothing on press_play, The Sun Rises on modify_scoring_hand, Watermelon on setting_ability, Weather Radio on blind_disabled); and single blockers take the rest (Aperol's perma_p_dollars, Burning Pact's draws, Cross and Unholy Alliance reacting to others' destructions, Da Capo and Jester of Nihil's debuff work, Ddakji / Vacation Juice / The World's state systems, Determination's death prevention, Jimbocards' inflation, Lager's permanent odds, Nichola's held-card scoring, Sacred Heart's permanent retriggers). 56 Leaf Clover, Ghost Cola and Shadowmantle were rescued from the tag class during the port: they create only the vanilla Negative Tag, which `Game:addTag` grants.

MoreFluff is 89 of 229 in MoreFluffPack v1.1.0. The other 140 stay blocked, each on a named system: Astral Sliver, Megantic Sliver, Plasma Sliver, Sinew Sliver, Fortunate Sliver, Fury Sliver, Mindlash Sliver, Muscle Sliver, Quantum Sliver, Sliver Jockey, The First Sliver, Gemhide Sliver, Might Sliver, Virulent Sliver (the Sliver system (a shared `mf_sliver_ability` registry and `FLUFF.sliver_effects` the port has no equivalent for)); Paint Can, Rainbow Joker, Clipart Joker, Monochrome Joker, CSS, Loaded Disk (the Colour consumable system); Aura Farm, Emeritus of Eternity, Emeritus of Lore, Emeritus of Decay, Emeritus of Growth, Emeritus of Variety, Emeritus of Inevitability, Emeritus of Rebirth, Perkeo!, Yorick!, Canio!, Triboulet!, Chicot!, Triangle! (the prepared-cards system); Cosmogoyf, Hold Music, Pact of the Titan, Summoner's Pact, Pact of Negation, A-Hit the Road, Stasis Chamber, Diabolical Joker, Ghostly Reflection, Slaughter Pact, Space Elevator, Suspension of Disbelief (the exile/suspend system (`G.mf_exile`)); Teal Joker, Marigold, Brass Joker, Gemstone Joker, crimsonglassdecomposition, halt, Yucky Rat, Ransom          Note (custom enhancements, which cannot be registered (the port's enhancement constants are hardcoded)); crypticmod (a custom edition); 4rd Sanctuary, Cartomancer!, Cue Ball (the Rotarot consumable system); John Balatro..?, Jimbo, the Mind Sculptor, Triangle, Planeswalker (the loyalty/planeswalker system); Apex Devastator, Violent Outburst, Zhulodok, Void Gorger (`FLUFF.cascade`); Lone Wolf (tempname001 on PC), Tall Joker, Refrigerator, Joker Reacts To Broccoli (the FLUFF attribute registry); Joker With Set's Mechanic, Phyrexian Battle Standard (the FLUFF poisonous system); Ace Up The Sleeve, Balatro Mods (Working 2024), Glitter Bomb, Seal the Deal (`SMODS.poll_enhancement` / `SMODS.poll_seal`, which the port does not implement); Bouncer, Junk Mail, B, Shopping Spree, Gem Alert (shop manipulation (moving Jokers through the shop, injecting vouchers/boosters, resizing the shop, editing shop cards)); Bonus Sheet, Repack (booster-pack internals and custom boosters); eventhorizon, Teacup, Flesh Prison, P, Chicot!?, Jankman, Unpleasant Card, Blåhaj, Wide Joker, E, Freaky Pizza (return fields no reader applies (`level_up`, `xblindsize`, `xchips`, `swap`, `emult`/pow-mult, `xlog_chips`)); Bridge from Below, Purple Economy Joker, Whiplash, crad shuffler, deadheatpulse, Hyperjimbo, Junkyard, John Balatro, Unregistered Hypercam 2, Overlord of the Plasmadeck, Gentlemelon, A Heart of Cold, Homing Sliver, Z, Mr. Loans, Intervention Pact, Marigold!?, L, Marigold!, U, Snake, Missing Texture, Rose-Tinted Glasses (contexts the port never raises (MoreFluff's own `mf_*` events, `drawing_cards`, `initial_scoring_step`, `modify_weights`, `game_over`, `check_enhancement`, `setting_ability`, `modify_scoring_hand`, `forcetrigger`, `main_eval`, `destroying_card`)); Blasphemy, the way home, Box of Hands, Dropkick, 5D Joker with Multiverse Time Travel, R, T, Mathemagics, All I Can't Do, Blunder, Doubled Scale, Triangle, Triangle!?, Flint and Steel, Saturn Burger, Fast-Growing Sapling, Three Steps Ahead, Triboulet!?, Joke Merge Valley (engine APIs the port does not expose (changing hands/ante/round mid-play, drawing cards for effects, debuffing cards, forcing a selection, the `scale_card` system, levelling hands outside Planet use, winning a blind outright, transforming playing cards, scoring held cards)); Apple Friends, X, Marketable Plushie (global function overrides (`calculate_individual_effect`, PokerHand evaluation)); Nemesis (a custom tag); Name Sticker Goblin, John Balatro. (another mod being installed (aikoyorisshenanigans; Jen)).

Cryptid is 140 Jokers and 22 consumables in CryptidPack v1.1.0. The other 139 stay blocked. Fourteen are Talisman big-number Jokers whose effects return or scale e_mult / e_chips values (Mult or Chips raised to a power) that Lua numbers in this engine cannot represent — Happy House (Mult ^ 4), The Complete and Utter Annihilation of Everything That Makes Balatro Sacred (Mult ^ 5.2), Night (Mult ^ 3), Universe (Mult ^ 1.2), Googol Play Card (XMult 1e100), Jimbo-tron 9000 (e_mult), Starfruit (e_mult), Exponentia, Primus, Stella Mortis, Facile, Formidiulosus, Circulus Pistoris and Tredecim (all e_mult / e_chips scaling) — and they stay out whole rather than capped. The other 125 block on named fork gaps, the largest classes being: Cryptid's Code-card program state and custom UI (34 of the 36 Code consumables — only ://CTRL+V and The Automaton ported), custom enhancements and seals that cannot be registered, contexts the fork never raises (destroying_card, debuff_card, cry_press, money_altered and friends), return fields with no scoring reader (xchips, balance), the WholeDeck hand and Cryptid's Clusterfuck and cry_None hand keys, global hooks and init overrides (Maximized's Card:get_id override, the crash and cryupdate joke cards), and Cryptid's custom tags. Every one of the 125 is named with its exact blocker in the pack's README.txt.

Also found while porting: Balatro3DS does not fill `context.full_hand` for discard contexts (the batch is only in `context.port.discarded_nodes`). Handy Joker works around it; other discard mods should too.

## Validation

Each port was loaded through the real ModLoader and exercised in Balatro3DS's own headless test harness: Swiss Cheese 4/4 checks, the KCVanilla pack 13/13 at v1.0.0 and 9/9 in its v1.1.0 suite (registration and tooltips for all fourteen, create/destroy behavior for each of the five new Jokers, plus regression checks on the original nine), the Pokermon pack 18/18 at v1.0.0, 25/25 in its v1.1.0 suite and 31/31 in its v1.2.0 suite (registration and tooltips for all fifty, evolution chains end to end for the Caterpie, Charmander, Squirtle, Bulbasaur and Magikarp lines, edition preservation, stone chains correctly never evolving on round end alone, plus — at v1.2.0 — the four stones' registration under the poke_item type, shop-roll sampling, per-line evolution and refusal checks, leftmost targeting, and edition/scaling preservation through a stone evolution, plus regression checks on the original eighteen), the Neato pack 7/7 at v1.0.0 and 18/18 in its v1.1.0 suite (registration and tooltips for all fifteen, create/destroy/retrigger behavior for each of the nine new Jokers, the self-destroy fixes for Ice Cream Sandwich and The Banana Stand, plus regression checks on the original six), the Bunco pack 17/17 at v1.0.0 and 38/38 in its v1.1.0 suite (registration and tooltips for all fifty-one Jokers and six consumables, both exotic suits, every Spectrum-family hand plus Deal evaluated through the game's own hand classifier, the exotic gate opening and shutting, and create/destroy/level/retrigger behavior for the new Jokers), the Paperback pack 41/41 in its main suite (the original thirty-six Jokers' behavior, both suits, the Spectrum hands through the game's own classifier and the exotic gate), 34/34 in its Minor Arcana suite (type registration, all thirty-three cards, one behavior test each) and 57/57 in its expansion suite (registration, names, rarities, costs and clean tooltips for all 224 Jokers, plus behavior tests across the 188 expansion Jokers, including the three rescued tag Jokers end to end), the MoreFluff pack 56/56 in its suite (registration, names, rarities, costs and clean tooltips for all eighty-nine Jokers, plus behaviour tests for the flat and X-Mult scorers, the Letter Jokers' per-card effects, grep's deck sort, Letter D's end-of-round destruction, the retrigger and post-trigger passes, probability shaping through Ice Cube / Oops! All 5s / Letter O, blind-select and shop creation, and the sell timers), the Cryptid pack 41/41 in its suite (registration, names, rarities, costs and clean tooltips for all 140 Jokers and 22 consumables, the four custom rarities at their PC weights, the Bulwark and UltPair evaluators tested directly and through their Planets, the Code and Unique types, and behavior tests across the new Jokers and consumables — creation and destruction through Gateway, Summoning and Analog, sell-scaling through M and Sapling, the round-end timers on Red Bloon, Chili Pepper and Pot of Jokes, and the dollar bonuses on Compound Interest, Magnet and Gold Joker), with the game's own mod suite still green (38 tests on the stock tree, 54/54 on the fork, including the suit-front gate test the Bunco pack needed and the consumable-type tests the Pokermon stones needed) and negative controls confirming the tests can fail. Hardware testing is the remaining step.

## Credits

- **krackocloud** — KCVanilla, its Joker designs, text and art. KCVanilla ships no license; this is an unofficial fan port made for personal use, published with credit. If you are krackocloud and want anything changed or removed, open an issue and it will be handled immediately.
- **neatoqueen (Neato)** — Neato Jokers, its Joker designs, text and art. Neato Jokers ships no license; this is an unofficial fan port made for personal use, published with credit. If you are neatoqueen and want anything changed or removed, open an issue and it will be handled immediately.
- **InertSteak and the Pokermon contributors** — Pokermon, its Joker designs, text and art (GPLv3).
- **Firch** — Bunco, its Joker designs, text and art, including the exotic suits and Spectrum hands. Bunco ships no license; this is an unofficial fan port made for personal use, published with credit. If you are Firch and want anything changed or removed, open an issue and it will be handled immediately.
- **Nether and contributors** — Paperback, its Joker designs, text and art, the Stars and Crowns suits, the Spectrum hands and the Minor Arcana. Paperback is MIT License, Copyright (c) 2025; the license text ships in the pack (LICENSE.txt). Source: https://github.com/Balatro-Paperback/paperback
- **notmario** — MoreFluff, its Joker designs, text and art. MoreFluff ships no license file; this is an unofficial fan port made for personal use, published with credit. If you are notmario and want anything changed or removed, open an issue and it will be handled immediately.
- **The Cryptid team (SpectralPack)** — Cryptid, its Joker and consumable designs, text and art, the Epic / Exotic / Candy / Cursed rarities, the Bulwark and UltPair hands and the Code card system. Cryptid is GPLv3; the license text ships in the pack (LICENSE). Source: https://github.com/SpectralPack/Cryptid
- **idkhan / Gazpacho** — Balatro3DS and its mod API.
- **LocalThunk** — Balatro.
