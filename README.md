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

### PokermonPack — 50 Gen 1 Pokémon Jokers, with evolution and the evolution stones (v1.3.0)

From **Pokermon** by InertSteak (the #2 most popular Balatro mod). Bulbasaur, Charmander and Squirtle (with their +hand size / +discard / +hand passives), Pikachu, Magikarp, the Caterpie, Weedle and Pidgey lines, Rattata/Raticate, Diglett/Dugtrio, Shellder/Cloyster, Goldeen/Seaking, Mr. Mime, Pinsir, Rapidash, Articuno, and more. Zip: `balatro3ds-pokermon-pack-v1.3.0.zip` (the v1.0.0, v1.1.0 and v1.2.0 zips are kept alongside).

Pokermon is **GPLv3**, so this port is published under GPLv3 with the original code credited below.

**Evolution (new in v1.1.0)** is implemented at pack level with the fork's Tier 1 mod API. On PC, Pokermon raises an evolution step after each round; the port checks the same counters on the round-end context. Where PC transforms the card in place and keeps its slot, the port destroys the old Joker and creates the evolved form (`SMODS.destroy_joker` + `SMODS.add_card`), so the evolved form takes the last Joker slot; the edition and any grown values PC would keep (a scaling total whose per-step gain is still on the card) carry over, stickers do not. **Evolution needs the [fork](https://github.com/sen2008/balatro3ds-fork) build** — on the stock game the Tier 1 calls do not exist and nothing evolves, exactly as in v1.0.0; every stage is still a standalone shop Joker either way.

Per-chain status:

- **Ported:** Bulbasaur → Ivysaur → Venusaur (after earning $16 in held-card payouts per stage), Charmander → Charmeleon → Charizard (at +16, then +36 grown Mult; the Mult carries), Squirtle → Wartortle → Blastoise (at +40, then +120 grown Chips; the Chips carry), Caterpie → Metapod (2 rounds) → Butterfree (3), Weedle → Kakuna (2) → Beedrill (3), Pidgey → Pidgeotto (4) → Pidgeot (4), Rattata → Raticate (5), Ekans → Arbok (4), Sandshrew → Sandslash (4), Diglett → Dugtrio (4), Tentacool → Tentacruel (5), Krabby → Kingler (4), Magnemite → Magneton (4), Goldeen → Seaking (5), Magikarp → Gyarados (8).
- **Item evolutions (new in v1.2.0):** Pikachu → Raichu (Thunder Stone), Clefairy → Clefable (Moon Stone), Jigglypuff → Wigglytuff (Moon Stone), Growlithe → Arcanine (Fire Stone), Shellder → Cloyster (Water Stone). The four stones are Item consumables registered under the pack's own `poke_item` type through the fork's `SMODS.ConsumableType`, at PC's shop_rate 4 and $4 cost, so they roll in the shop as their own kind. Since v1.3.0 a stone evolves the Joker you choose for it (open the Joker's tooltip or focus it, then use the stone) through the fork's Joker targeting, instead of the leftmost eligible one; an Item Pack booster (3 cards, $4) is registered as on PC, and the kind has its own collection category. The Leaf Stone is not ported (its Gen 1 targets — Gloom, Weepinbell, Exeggcute — are not in the pack), and Magneton does not take the Thunder Stone here (its PC evolution, Magnezone, is not in the pack).
- The fifteen new forms' art is sliced from Pokermon's own Natdex atlas; the original 35 keep their pack art.

Port notes:

- **No Energy**: Balatro3DS has no Energy system, so each Pokémon ships with its base effect at base (un-energized) values. The custom `poke_safari` rarity maps to Rare.
- **Stones are evolution-only here**: on PC a stone also carries a secondary playing-card effect (Fire: Mult cards, Water: Bonus cards, Thunder: Gold copies, Moon: upgrade a poker hand), and the evolution lands at the end of the round. The secondary effects are not ported, so a stone here is usable exactly when the Joker chosen for it is a held, non-debuffed pre-form it evolves, and it evolves that Joker on the spot through the same destroy+create call as the other chains. Stones arrive through the shop roll and the registered Item Pack (which draws the engine's plain booster fallback panel — no pack-wrapper art exists for it in this workspace). On the stock game the type API does not exist, no stones register, and the five chains stay unevolved.
- Bulbasaur's designated rank is re-rolled at blind select, as in the original. Charmander/Squirtle scaling reads the port's live `G.discards` / `G.hands` counters.
- Retrigger Pokémon (Rattata line, Shellder line, Goldeen line, Mr. Mime) use the port's `context.repetition`; "first N scoring cards" is resolved through `context.port.played_cards`, since the repetition context has no `scoring_hand`.
- Magneton counts adjacent Metal Jokers as PC does, but Pokémon types do not exist in the port and the only Metal line in this roster is Magnemite/Magneton, so adjacency counts those two. Arbok creates its Tarot during scoring instead of before it.
- Tentacruel's "10s can't be debuffed" and Snorlax/Eevee-style effects bound to Pokermon's item/evolution systems did not port. Eevee and Snorlax are not in the pack for that reason.
- Articuno adds Foil and a random seal to the first scoring card, but only if it has neither yet (the original converts unconditionally). Art is cropped from Pokermon's own Natdex sheet, with the legendary "soul" layer composited in.

### BuncoPack — 55 Jokers, the exotic suits and the Spectrum hands (v1.3.0)

Download: `balatro3ds-bunco-pack-v1.3.0.zip`.

From **Bunco** by Firch — the biggest single pack here, and the first to port a PC mod's custom suits and poker hands. Bunco adds two **exotic suits** (Fleurons, Halberds), four **Spectrum-family hands** (Spectrum, Straight Spectrum, Spectrum House, Spectrum Five) plus Registration Plate's **Deal**, and a per-run exotic system: score any Spectrum-family hand once and exotic-suit cards start appearing in Standard packs and the shop, and the exotic Jokers enter the pools. Also included: the four Spectrum Planets (Quaoar, Haumea, Sedna, Makemake) and the exotic Tarots (The Sky, The Abyss).

New in v1.2.0 (the Tier 3 top-up): **Neon** and **Bounty Hunter**, and Bunco's **Fluorescent edition** registered through the fork's `SMODS.Edition` (Neon grants it; its PC immunities are Lovely-hook effects and are not implemented — see Port notes).

New in v1.3.0 (the Wave 1 top-up): **Fiendish** and **Head in the Clouds**, riding the fork's Wave 1 contexts (`money_transform`, `level_up_hand`). Bounty Hunter's tax moved onto the same `money_transform` seat: the gain itself now lands $1 short, exactly as on PC, instead of landing in full and being taxed as a separate money event afterwards.

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
| Head in the Clouds | Uncommon / $6 | 1 in 3 chance to level up High Card when another hand is levelled; only appears once High Card is above level 1 (v1.3.0) |
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
| Fiendish Joker | Uncommon / $5 | Doubles all money gains; 1 in 3 chance a gain pays out $1 instead (v1.3.0) |
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
| Neon | Uncommon / $5 | When a card's enhancement changes, it gains the Fluorescent edition if it has none (v1.2.0) |
| Bounty Hunter | Common / $5 | Whenever you gain money, this Joker takes $1 of it and permanently gains +1 Mult (v1.2.0) |
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
- **Juggalo**'s own edition roll is still Foil / Holographic / Polychrome. The Fluorescent edition is registered since v1.2.0 (Neon grants it), but on PC its whole effect is a set of Lovely-hook immunities (it cannot be flipped, debuffed or force-selected) and fork editions are config-only with no hooks, so the registered Fluorescent is stat-less and its tooltip says the immunities are not implemented. **Stylophone**'s sound-click ladder is cosmetic on PC and is not ported.
- **Deal** rewrites its own hand stats inside its `evaluate` (level 1, base values set to the banked totals), the one place the port recomputes a hand's score from its stats.

### PaperbackPack — 280 Jokers, the Stars and Crowns suits, the Spectrum hands and the Minor Arcana (v1.2.0)

Download: `balatro3ds-paperback-pack-v1.2.0.zip`.

From **Paperback** by Nether and contributors (MIT License) — the largest pack here. 280 of Paperback's 316 Jokers are ported, plus its two custom suits (**Stars**, light; **Crowns**, dark), the four **Spectrum-family hands** (Spectrum, Straight Spectrum, Spectrum House, Spectrum Five, at Paperback's own values), and **45 of the 56 Minor Arcana** as a registered `minor_arcana` consumable type. The full roster with one-line effects is in the pack's README.txt. **The whole pack needs the [Balatro3DS fork](https://github.com/sen2008/balatro3ds-fork) build** — it creates and destroys cards (Tier 1), registers suits, hands and rarities (Tier 2), registers the Minor Arcana type and gates exotic-suit fronts (`SMODS.ConsumableType`, the suit `in_pool` hook), and — since v1.1.0 — registers Paperback's custom enhancements, tags and the Dichrome edition, and the Minor Arcana booster packs (Tier 3). New in v1.2.0 (the Wave 1 top-up): eleven more Jokers and the Two of Swords Arcana, riding the fork's Wave 1 additions — the permanent per-card fields (`SMODS.set_perma` / `SMODS.get_perma`), the numeric partial-`balance` return, and the `game_over` / `saved` context.

Port notes:

- **The exotic gate works like Bunco's**: score any Spectrum-family hand once (or hold a Stars/Crowns card in the deck) and the two suits enter the random card-front pool. Where Bunco and Paperback register the same hand names, the values agree; the guards make double registration a no-op, so the two packs coexist.
- **Minor Arcana arrive as on PC since v1.1.0**: shop rate 0, delivered by registered Minor Arcana booster packs (normal / jumbo / mega) now that the fork has `SMODS.Booster`. Joker-targeting Arcana (Nine of Cups, Nine of Swords, King of Swords, Two of Pentacles) act on the Joker you choose through the fork's Joker targeting, not the leftmost eligible one.
- **Nazar counts Tarot and Minor Arcana**, as on PC. The tag Jokers are all in since v1.1.0: 56 Leaf Clover, Ghost Cola and ShadowMantle create the *vanilla* Negative Tag through `Game:addTag` (the route Bunco's Zero Shapiro uses for the D6 Tag), and Paperback's own tags (Angel Investment, Breaking, High Risk, Dichrome, Divination) are registered through `SMODS.Tag`, which unblocked the other nine tag Jokers and the Knight / Seven of Wands Arcana.
- **Destruction ordering rides the before/after passes**: PC's `destroy_card` context has no exact fork equivalent (the fork's `destroying_card` is a pre-destruction veto), so Jokers that destroy scored cards (Alert, The Batter, Thornring, Whitebeard, Buckshot and friends) destroy in the hand's before/after slots, the Dayman/Bunco precedent — the card still scores first where PC scores it first. Since v1.1.0 the fork also raises `joker_type_destroyed`, so the Off addon Jokers and Cross / Unholy Alliance's destruction reactions are ported; Black Forest Cake and Cardboard Box still scale only on playing-card destruction, and Sacrificial Lamb keeps only its playing-card half.
- **The ports follow Paperback's code where it disagrees with its tooltips** (Disco checks the wallet when buying; Der Freischütz takes the lowest chip-value card in the full deck, 7s included; Showdown's chance gate; The Normal Joker is Rare $8 as its def says, not Common). Permanent per-card bonuses write the fields the fork's scoring reads (`card_data.chip_bonus` / `mult_bonus` / `Bonus`).
- **OFF Switch** creates its eternal addon Jokers (Off Alpha/Epsilon/Omega, ported in v1.1.0 on the `joker_type_destroyed` context) Eternal, as on PC. Its `add_to_deck` also means a test (or player) adding it gains a second Joker — intended, as on PC. **Red Key** creates a random Rare (no Ultra Secret rarity exists here), **Freezer** a random Negative Common/Uncommon (no Food pool exists).

### MoreFluffPack — 108 Jokers (v1.3.0)

Download: `balatro3ds-morefluff-pack-v1.3.0.zip`.

From **MoreFluff** by notmario — the biggest single-author Joker mod for PC Balatro. 108 of its 229 Jokers are ported, including the Letter Jokers, the Scrapped set and the token Jokers. **The pack needs the [Balatro3DS fork](https://github.com/sen2008/balatro3ds-fork) build**: it registers MoreFluff's six custom rarities and uses the fork's `SMODS.add_card` / `SMODS.destroy_card`, retrigger returns, `post_trigger` passes and probability-shaping contexts. The six custom rarities are registered at weight 0, as on PC their Jokers arrive through other Jokers and effects rather than the shop (Forge and Letter F create them; Fish is a token). The v1.2.0 top-up also registered five of MoreFluff's custom enhancements (Teal, Marigold, Brass, Gemstone, Yucky) at poll weight 0 — on PC they reach the player through the unported Rotarots. New in v1.3.0 (the Wave 1 top-up): five more Jokers riding the fork's `SMODS.poll_enhancement` / `SMODS.poll_seal` polls and the `xlog_chips` return reader (Ace Up The Sleeve, Balatro Mods (Working 2024), Glitter Bomb, Seal the Deal, Freaky Pizza). The other 121 Jokers stay blocked on systems the fork does not have — Slivers, Colour cards, prepared cards, exile and more; each one is listed under Not ported below. Deviations from PC are listed in the pack's README.txt (the largest: Blade Dance's Steel cards are permanent here, Brainrot's destroy forces past Eternal, and Expansion Pack's modded pool is this pack's own Jokers).

| Joker | Rarity | Cost |
|---|---|---|
| [[BIG SHOT]] | Scrapped | $7 |
| A | Letter | $2 |
| Ace Up The Sleeve | Scrapped | $6 |
| All I Can't Do | Rare | $9 |
| Bad Legal Defence | Uncommon | $6 |
| Balatro Mods (Working 2024) | Scrapped | $3 |
| Basepaul Card | Common | $5 |
| Big Win | Uncommon | $7 |
| Black Market | Scrapped | $4 |
| Blade Dance | Uncommon | $8 |
| Blåhaj | Common | $1 |
| Book Move | Rare | $10 |
| Bowling Ball | Rare | $8 |
| Brainrot | Scrapped | $6 |
| Brilliant | Uncommon | $8 |
| Brass Joker | Rare | $10 |
| Burner Phone | Scrapped | $2 |
| C | Letter | $6 |
| Card Buffer Advanced | Rare | $10 |
| Clownfish | Common | $6 |
| Contract from Below | Rare | $9 |
| Coupon Catalogue | Scrapped | $7 |
| D | Letter | $4 |
| DINNER! | Uncommon | $5 |
| Disintegration Loop | Rare | $10 |
| E | Letter | $2 |
| Dramatic Entrance | Uncommon | $6 |
| Expansion Pack | Common | $6 |
| F | Letter | $8 |
| Fish | Token | $1 |
| Forge Residue | Token | $0 |
| Freaky Pizza | Scrapped | $6 |
| Friend Inside Me | Uncommon | $7 |
| Flint and Steel | Scrapped | $4 |
| G | Letter | $4 |
| Globe | Uncommon | $6 |
| Glitter Bomb | Scrapped | $14 |
| Golden Carrot | Uncommon | $4 |
| Gemstone Joker | Uncommon | $6 |
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
| Jankman | Rare | $9 |
| Joker Forge | Uncommon | $6 |
| Jokes for Balatro Players | Common | $7 |
| K | Letter | $10 |
| Knuckleblaster | Uncommon | $6 |
| Less Fluff | Rare | $10 |
| Lollipop | Common | $6 |
| Lucky Charm | Common | $6 |
| M | Letter | $6 |
| Mashup Album | Scrapped | $8 |
| Marigold | Legendary | $20 |
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
| Rose-Tinted Glasses | Scrapped | $5 |
| S | Letter | $2 |
| Seal the Deal | Scrapped | $6 |
| Simplified Joker | Common | $5 |
| Spiral Joker | Common | $5 |
| Steamflogger Boss | Scrapped | $6 |
| Stifle | Common | $4 |
| StoneJoker Joker | Uncommon | $8 |
| Stormscale Scion | Scrapped | $10 |
| Style Meter | Uncommon | $6 |
| Sudoku Joker | Scrapped | $9 |
| Sword of Steven and Todd | Rare | $10 |
| Teacup | Uncommon | $7 |
| Teal Joker | Uncommon | $7 |
| The Baseball Stream | Rare | $10 |
| The Broom Closet | Uncommon | $4 |
| The Jester | Scrapped | $20 |
| The Solo | Rare | $7 |
| Top 10 Jokers From 1 To 10 | Rare | $10 |
| Treasure Map | Common | $4 |
| Triangular Joker | Scrapped | $7 |
| Unpleasant Card | Uncommon | $6.5 |
| V | Letter | $8 |
| Virtual Joker | Scrapped | $7 |
| W | Letter | $8 |
| Whiteboard | Scrapped | $6 |
| Wide Joker | Rare | $9 |
| Wild Draw Four | Scrapped | $7 |
| Y | Letter | $8 |
| Yucky Rat | Uncommon | $8 |

### CryptidPack — 172 Jokers, four custom rarities, the Bulwark and UltPair hands, the Code and Unique consumable types (v1.3.0)

Download: `balatro3ds-cryptid-pack-v1.3.0.zip`.

From **Cryptid** by the Cryptid team (SpectralPack) — the biggest content mod for PC Balatro. 172 of its Jokers and 28 of its consumables are ported, completing the v1.0.0 seven-Joker first pass (Dubious Joker, Absurd Joker, Shrewd Joker, Nutty Joker, The Duos, The Home, Triplet Rhythm — unchanged). **The pack needs the [Balatro3DS fork](https://github.com/sen2008/balatro3ds-fork) build**: it registers Cryptid's Epic, Exotic, Candy and Cursed rarities, the Bulwark and UltPair poker hands and the Code and Unique consumable types, and uses the fork's create/destroy APIs and retrigger returns throughout; since v1.2.0 it also registers Cryptid seals, editions and tags (Tier 3) and the Talisman-scale Jokers run on the fork's big numbers. New in v1.3.0 (the Wave 1 top-up): ://ALTTAB, Kidnapping, Necromancer, Pumpkin, Carved Pumpkin and Familiar Currency, riding the fork's Wave 1 systems (the `G.jokers_sold` sale history, the `game_over` context). On the stock Universal-Updater build the pack does not load.

- **Epic** registers at shop weight 0.3, as on PC; **Exotic** at weight 0, as on PC — Exotics are never sold, they arrive through Gateway and other creation effects. **Candy** and **Cursed** take the fork's default weight of 3.
- **Bulwark** (five Stone cards) and **UltPair** (two or more pairs in each of two suits) register as poker hands with their PC values, and their Planet consumables (Asteroid Belt, Phobos & Deimos) plus the Finnish planet family and Kaikki level them here. Like every custom hand on the fork they rank below High Card in hand contests, because the fork's evaluator names hands by list position.
- **Code** cards get shop rate 1: PC rates them 0 because PC has Code booster packs, which the fork does not, so the shop is the only way the ported Code cards (://ALTTAB, ://CTRL+V, ://COMMIT, ://REWORK) can appear. **Unique** stays at rate 0, as on PC.
- Cryptid's gameset system (Modest / Mainline / Madness) is not ported; every effect uses its standard rules. Cube is free instead of -$27 (the fork requires cost >= 0), Kitty Printer's Cat Tag conversion is ported since v1.2.0 (with a timing deviation), Adversary drops its shop-price doubling (so the port is strictly stronger than PC), ://CTRL+V covers playing cards only, and Conduit's Joker branch is ported while its two-Joker swap is not. Every deviation is listed in the pack's README.txt.
- Twelve of the fourteen Talisman big-number Jokers are ported since v1.2.0, on the fork's big numbers (the `e_mult` / `e_chips` return readers; totals promote past the double range instead of overflowing). The Complete and Utter Annihilation of Everything That Makes Balatro Sacred stays blocked because its cry_WholeDeck hand can never be formed here (the whole deck in one play; selection caps at 5 and there is no play-limit API), and Exponentia stays blocked because its growth hooks `SMODS.calculate_individual_effect`, which the fork does not expose. The other 99 blocked items each name their missing system under Not ported below and in the pack's README.txt.

### MikasPack — Mika's Mod Collection, 58 Jokers + 3 consumables + 6 decks

Download: `balatro3ds-mikas-pack-v1.0.0.zip`. The full roster is in the pack's README.txt. Requires the fork build: its decks register through `SMODS.Back`, two Jokers lower live blind targets through `SMODS.adjust_blind_target`, and Student Loans spends into debt through the fork's `debt_limit` config. Not ported: Dagonet (rewrites other Jokers' ability values in place; vanilla Jokers have no generic ability layer to scale), Cicero (needs a mutation hook over unowned shop offers), and the "Jokers for Hire" deck (dynamic run rules with no deck-config equivalent). The 6 in-development and 2 empty-stub Tarots are off or unimplemented on PC too and stay out. Pack tests: 32/32.

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
- Dayman and Nightman (Neato) destroy played cards in the port's `after` pass, the slot the port's own Sixth Sense uses for Steamodded's `destroying_card` context (the fork now raises `destroying_card`, but as a pre-destruction veto, not a destruction moment); the destroyed card still scores first, as on PC. Dayman's "first hand of round" reads the game's `get_round_hands_played()`.
- Frosted Prime Rib's permanent gains write `card_data.Bonus` (the field Hiker writes) and `card_data.mult_bonus`, the two fields the game's modifier path reads back when the card scores again; only scoring cards are granted, via the `counts_for_play_score` marker Hiker checks.
- Blue Yourself answers both of the port's retrigger passes: `retrigger_joker_check` for Foil Jokers (the other Joker's def id and normalized edition stand in for PC's `config.center.key` / `edition.key`) and `context.repetition` for Foil playing cards (whose edition lives in `card_data.modifier.edition`). Its `in_pool` gate is kept — the port supports `in_pool` and the deck half reads the game's full-deck counter — but PC's guard against retriggering a foil Blueprint that is itself copying Blue Yourself reads `context.other_ret`, which the port does not provide, and is dropped.
- Australian Shepherd and Dogs Playing Balatro pick their random consumable with the game's own `random_consumable_id_of_kind` (which never offers The Soul or a Black Hole), since the fork's `add_card` needs a def id where Steamodded picks for you. Australian Shepherd's `getting_sliced` check is dropped; port Jokers do not carry that flag.
- The Banana Stand destroys itself with the fork's `SMODS.destroy_joker` and zeroes the money through the mod environment's `ease_dollars`, where PC queues a delayed event; the rolls go through `SMODS.pseudorandom_probability`, so Oops! All 6s applies as on PC.
- JokerZD counts unique purchases by def id (`context.port.offer_id` on the port's shop-buy event) where PC counts by card label; buying JokerZD itself is excluded, as on PC.
- Hatsune Joku is the effect only: the PC mod's custom music track (`SMODS.Sound`, its config tab and the `add_to_deck` juice) has no port equivalent.

## Not ported (and why)

The other four KCVanilla Jokers still need things Balatro3DS mods do not have, even on the fork after Tier 3 (rechecked 2026-10-23): Five-Day Forecast (the rank-up path — `change_rank` is still on the fork's not-raised context list, and rank changes are direct writes with no setter to hang a context on), Rakugo (booster-pack internals: registered packs deal from fixed pools and `open_booster` fires before the pack's cards exist, so there is no route to read or alter a live pack), Squid (live hands-left and projected score mid-round — neither is exposed to mods), Luck of the Irish (the port passes `trigger_obj = nil` for the game's own probability rolls, so a mod cannot tell which card rolled). Fortune Cookie, Rats!, Cosmic Collapse, Loose Tooth and Scapegoat were unblocked by the fork's Tier 1 API and joined the pack in v1.1.0.

Neato Jokers is fully ported as of NeatoPack v1.1.0 (15/15): the nine that were blocked on create/destroy/retrigger-return mechanics (Australian Shepherd, The Banana Stand, Blue Yourself, Dayman, Nightman, Dogs Playing Balatro, Frosted Prime Rib, Hatsune Joku, JokerZD) were unblocked by the same Tier 1 API. Only pieces around them did not port: Hatsune Joku's music track and config tab, and Blue Yourself's `other_ret` sub-guard (see Port notes).

Bunco is 55 of 80 in BuncoPack v1.3.0. The other 25 stay blocked, each on a named system the port does not expose: Gameplan and Conquest (their debuff work targets Jokers — the fork's debuff setter and `debuff_card` context cover playing cards only, and there is no mod-settable Joker debuff), JMJB and Aristocrat (booster-pack internals: the `open_booster` context still fires with an empty payload and a registered Booster exposes neither its dealt cards nor a choice count to change), Kite Experiment and Robot (the `rescore_cards` context; the Copper enhancement is not registered because its only effect is that rescore — an inert Copper would print false text), Hardtack, Pica and the Adjustment Tarot (Bunco's Cracker system is a Lovely hijack of the discard button; there is no discard-to-play redirect or veto), Sledgehammer, Dwarven and Metallurgist (they rewrite vanilla enhancement center configs — Glass XMult and break odds, Stone and Gold held effects — which are hardcoded game constants), Doorhanger and Running Joke (Doorhanger rewrites the rarity of every card as it is created, a create_card patch; Running Joke inserts a free Negative Joker offer into the shop at shop start, and there is no shop-offer insertion API for Jokers), Myopia and Astigmatism (global `Card:is_suit` patches; neither Joker has a calculate on PC), Trigger Finger, Vandalism and Cellphone (a `highlight_card` context, face-down card information, and Lovely play-flow redirects), Domino (pre-purchase shop contexts carrying a neighbour payload), Knight (its Mult reset rides a patch on Joker-area reordering; the port raises no rearrangement event), Glue Gun, Taped, Rubber Band Ball and Games Collector (Bunco's linked-group card system and its `groups_drawn` context), Headache (the Arcade Tag is registrable now, but its payload — a free Mega Virtual Pack dealing Polymino linked-group cards through custom UI — does not exist here).

Paperback is 280 of 316 in PaperbackPack v1.2.0, plus 45 of 56 Minor Arcana. The other 36 Jokers stay blocked, each on a named system: paperclips block 4 (Chip Clip, Clippy, Clothespin, Manilla Folder) and 11 Arcana — verified from the PC source, clip state lives on playing-card instances across 11 colors, each color with its own calculate at contexts the fork never raises, plus `G.GAME` counters with no persistence route for a mod; E.G.O Gifts block 4 (Arayashiki, Fodder, Grimoire, The Strongest — on PC the gifts are held objects with passive calculates firing from the consumable area, a Corroded sticker system, their own booster and a custom `sold_gift` context, not consumables a mod can register); the Apostle custom rank blocks 6 (As Above So Below, In Case I Make It, One Sin and Hundreds of Good Deeds, Penumbra Phantasm, Plague Doctor, White Night — custom ranks cannot be registered); two enhancement neighbours stay out (Blood Rain, whose effect lives in Paperback utility hooks rather than a calculate; Medic, which only maintains the Bandaged counter nothing in the fork queries); shop/pool/voucher manipulation blocks 9 (Backpack, Membership Card, NormalJKR, Protocol, Shopping Center, Touch Tone Joker, Ouija Board, Chaplin, Everything Must Go); blueprint-copy effects block 3 (Forgery, Master Plan, Photocopy — they ride `SMODS.blueprint_effect`, which the fork does not provide); and single blockers take the rest (Burning Pact's draws, Jimbocards' inflation, Lager's permanent per-card odds bonus — the fork's probability modifier is Joker-scoped and cannot outlive it, Nichola's held-card scoring, The Sun Rises' `modify_scoring_hand` context, Ddakji / Vacation Juice's `G.GAME.paperback` state systems, The World's global `Card:calculate_joker` and `Blind:stay_flipped` hooks). The eleven Arcana still out are exactly the paperclip eleven; Two of Swords joined in v1.2.0, its last-scored-suit state tracked pack-side.

MoreFluff is 108 of 229 in MoreFluffPack v1.3.0. The other 121 stay blocked, each on a named system: Astral Sliver, Megantic Sliver, Plasma Sliver, Sinew Sliver, Fortunate Sliver, Fury Sliver, Mindlash Sliver, Muscle Sliver, Quantum Sliver, Sliver Jockey, The First Sliver, Gemhide Sliver, Might Sliver, Virulent Sliver (the Sliver system — a shared `mf_sliver_ability` registry and `FLUFF.sliver_effects` the port has no equivalent for); Paint Can, Rainbow Joker, Clipart Joker, Monochrome Joker, CSS, Loaded Disk (the Colour consumable system); Aura Farm, the seven Emeritus Jokers, Perkeo!, Yorick!, Canio!, Triboulet!, Chicot!, Triangle! (the prepared-cards system); Cosmogoyf, Hold Music, the Pacts, A-Hit the Road, Stasis Chamber, Diabolical Joker, Ghostly Reflection, Space Elevator, Suspension of Disbelief (the exile/suspend system, `G.mf_exile`); Teal/Marigold/Brass/Gemstone/Yucky enhancement neighbours crimsonglassdecomposition and halt (a transform chain riding enhancement draw/redirect overrides) and Ransom Note (its payoff is the enhancement's own retriggers, which centers never receive — the five enhancements themselves are registered since v1.2.0 and their five Jokers are ported); crypticmod (fork editions are config-only, with no calculate and no way to apply one to a held Joker); 4rd Sanctuary, Cartomancer!, Cue Ball (the Rotarot consumable system); John Balatro..?, Jimbo, the Mind Sculptor, Triangle, Planeswalker (the loyalty/planeswalker system); Apex Devastator, Violent Outburst, Zhulodok, Void Gorger (`FLUFF.cascade`); Lone Wolf (tempname001 on PC), Tall Joker, Refrigerator, Joker Reacts To Broccoli (the FLUFF attribute registry); Joker With Set's Mechanic, Phyrexian Battle Standard (the FLUFF poisonous system); Bouncer, Junk Mail, B, Shopping Spree, Gem Alert (shop manipulation — the `store_joker` moments belong to Tags, not Jokers, and there is no offer-insertion or voucher/booster injection API); Bonus Sheet, Repack (booster-pack internals; there is no `add_card` route for boosters); Flesh Prison, P and Chicot!? (`xblindsize`, still no reader); Event Horizon (levels a *random other* hand — the `level_up` reader levels the scored hand only — plus scale_card and an in-place transform); Bridge from Below, Purple Economy Joker, Whiplash, crad shuffler, deadheatpulse, Hyperjimbo, Junkyard, John Balatro, Unregistered Hypercam 2, Overlord of the Plasmadeck, Gentlemelon, A Heart of Cold, Homing Sliver, Z, Mr. Loans, Intervention Pact, Marigold!?, L, Marigold!, U, Snake, Missing Texture (contexts the port never raises — MoreFluff's own `mf_*` events, `initial_scoring_step`, `modify_weights`, `game_over` / the death-prevention `saved` return, `check_enhancement`, `modify_scoring_hand`, `forcetrigger`, add-to-hand tracking, and in-place transforms that destroy+create cannot reproduce); Blasphemy, the way home, Box of Hands, Dropkick, 5D Joker with Multiverse Time Travel, R, T, Mathemagics, Blunder, Doubled Scale, Triangle!?, Saturn Burger, Fast-Growing Sapling, Three Steps Ahead, Triboulet!?, Joke Merge Valley (engine APIs the port does not expose — changing hands/ante/round mid-play, `SMODS.draw_cards`, forcing a selection, the `scale_card` system, levelling the *discarded* hand, winning a blind outright, perma_* merging); Apple Friends, X, Marketable Plushie (global function overrides — `calculate_individual_effect`, PokerHand evaluation); Nemesis (its tag's apply needs a custom booster with a create_card override and `SMODS.poll_object`); Name Sticker Goblin, John Balatro. (another mod being installed — aikoyorisshenanigans; Jen).

Cryptid is 172 Jokers and 28 consumables in CryptidPack v1.3.0. The other 101 stay blocked. Of the fourteen Talisman big-number Jokers, twelve are ported (above): The Complete and Utter Annihilation of Everything That Makes Balatro Sacred stays out because the cry_WholeDeck hand can never be formed here (the entire deck in one play; the fork caps selection at 5 and has no play-limit API), and Exponentia stays out because its ^0.03 growth hooks `SMODS.calculate_individual_effect` on every XMult trigger, which the fork does not expose (its `post_trigger` carries no effect payload). The Echo system stays out whole (The Eclipse, Spectrogram, Sock and Sock: Echo's effect is a per-card retrigger, and fork enhancements have no retrigger channel — only seals do — so `m_cry_echo` cannot be registered honestly), and The Seraph and Instability stay with it (Light needs per-card persistent state; Abstract's rank/suit self-read, base-card replacement and destroy roll have no support). The other WholeDeck-dependent Jokers stay out (Many Have Lost Their Minds Comprehending This Joker, The Universe In Its Fucking Entirety, Words Can’t Even Begin to Describe This Joker, Perkele in part, and the cry_None / cry_Clusterfuck Jokers whose hands likewise cannot be formed or levelled). Meld and On the Flip Side (the Double-Sided edition is flip/merge state, not an edition effect) and ://MACHINECODE, ://MALWARE and ://SPAGHETTI (the Glitched edition's effect is on-apply value randomization through `Cryptid.manipulate`; an inert label would fake it) stay out, as does ://PATCH (it needs debuff *immunity* — the fork's `debuff_card` is an after-the-fact notification and Boss debuffs are predicates). Familiar Currency joined in v1.3.0: the Meme pool is enumerable like the M pool, and 16 of PC's 17 Meme-flagged Jokers are now in the pack (only Cat Owl is unported). The rest keep their blockers — Cryptid's Code-card program state and custom UI (most of the remaining Code consumables), `Cryptid.manipulate`, stickers, `copy_card`, the Ascension system, CCD, draw / voucher-redeem / round-state APIs, global and init hooks, and the debug items — each named with its exact blocker in the pack's README.txt.

Also found while porting: Balatro3DS does not fill `context.full_hand` for discard contexts (the batch is only in `context.port.discarded_nodes`). Handy Joker works around it; other discard mods should too.

## Validation

Each port was loaded through the real ModLoader and exercised in Balatro3DS's own headless test harness: Swiss Cheese 4/4 checks, the KCVanilla pack 13/13 at v1.0.0 and 9/9 in its v1.1.0 suite (unchanged by the Tier 3 top-up; its four blocked Jokers were rechecked against the new systems and stay blocked), the Pokermon pack 18/18 at v1.0.0, 25/25 in its v1.1.0 suite and 31/31 in its v1.2.0 suite, and 32/32 in its v1.3.0 suite (real chosen-Joker stone targeting replacing the leftmost rule, edition/scaling preservation through a targeted evolution, refusal cases, and the Item Pack booster's registration and deals), the Neato pack 7/7 at v1.0.0 and 18/18 in its v1.1.0 suite (registration and tooltips for all fifteen, create/destroy/retrigger behavior for each of the nine new Jokers, the self-destroy fixes for Ice Cream Sandwich and The Banana Stand, plus regression checks on the original six), the Bunco pack 17/17 at v1.0.0, 38/38 in its v1.1.0 suite and 43/43 in its v1.3.0 suite (the Fluorescent edition's registration, Neon's grant on enhancement change, Bounty Hunter's money tax and growth, and the v1.3.0 money transforms and hand-level reactions), the Paperback pack 41/41 in its main suite, 45/45 in its Minor Arcana suite (type registration, all forty-five cards, the enhancement conversions, the tag-granting cards, the boosters, Joker targeting, Two of Swords) and 111/111 in its expansion suite (registration, names, rarities, costs and clean tooltips for all 280 Jokers, behavior tests across the expansion, the registered enhancements/tags/edition, the context-class Jokers, the rewritten OFF Switch and the Wave 1 additions), the MoreFluff pack 73/73 in its v1.3.0 suite (registration and tooltips for all 108 Jokers, plus behaviour tests for the non-trivial effects, including the Tier 3 return readers, the level_up ports, the enhancement registrations, the debuff port and the Wave 1 poll / xlog_chips ports), the Cryptid pack 84/84 in its v1.3.0 suite (registration, names, rarities, costs and clean tooltips for all 172 Jokers and 28 consumables, the big-number Jokers scoring past the double range, the destruction/tag/consumable additions, the restored Exposed/Mask, Conduit, Seal the Deal and Kitty Printer behaviors, and the Wave 1 sale-history and game_over additions), with the game's own mod suite still green on the fork (106/106, including the Tier 3 registrar, context, targeting, booster and big-number tests) and negative controls confirming the tests can fail. Hardware testing is the remaining step.

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
