Pokermon Pack (3DS Port) v1.4.0
145 Gen 1 Pokemon Jokers from Pokermon (PC, by InertSteak) ported
to Balatro3DS, with evolution and the evolution stones. That is the
whole non-Mega Gen 1 roster except 8 Jokers blocked on missing
engine pieces (listed under NOT PORTED, with reasons); the 22 Mega
evolutions wait on a Mega framework that does not exist yet.

REQUIRES THE BALATRO3DS FORK FOR EVOLUTION AND THE STONES
Evolution replaces a Joker through the fork's Tier 1 mod API
(SMODS.add_card / SMODS.destroy_joker), and the stones register
through its SMODS.ConsumableType API:
  https://github.com/sen2008/balatro3ds-fork
On the stock Universal-Updater build the pack still loads and all
145 Jokers work, but nothing ever evolves and no stones appear
(those calls do not exist there, and the pack treats that as "no
evolution", exactly as in v1.0.0). The evolved forms below are still
ordinary shop Jokers on both builds.
The test file (test_pokepack.lua) stays in the mod folder; the game
ignores it.

INSTALL
1. Unzip this file.
2. Copy the PokermonPack folder to your SD card at:
     /3ds/save/Balatro3DS/sdmc/mods/PokermonPack
3. Start (or restart) Balatro3DS.
4. Check Options -> Mods: "Pokermon Pack" should be listed.
   If a mod fails to load, the reason is written to mods/mods_log.txt
   in the same folder.

HOW EVOLUTION WORKS HERE
On PC, Pokermon raises an evolution step after each round: counters
tick there, and a Pokemon whose condition is met transforms in
place, keeping its slot. The port checks the same counters on the
round-end context, but a transform does not exist in this engine, so
the old Joker is destroyed and the evolved form is created in its
place (it takes the last Joker slot, not the old one's slot). The
edition carries over, and so do grown values PC would keep (a
scaling total whose per-step gain is still on the card, like
Charmander's Mult or Squirtle's Chips). Stickers do not carry over.

EVOLUTION CHAINS
Ported (the pre-form becomes the next form when its condition is
met; every stage is also a standalone shop Joker):
- Bulbasaur -> Ivysaur -> Venusaur: after earning $16 in held-card
  payouts as that stage (each stage earns its own $16).
- Charmander -> Charmeleon -> Charizard: at +16 grown Mult, then
  +36 grown Mult. The grown Mult carries into the next form.
- Squirtle -> Wartortle -> Blastoise: at +40 grown Chips, then +120
  grown Chips. The grown Chips carry into the next form.
- Caterpie -> Metapod (2 rounds) -> Butterfree (3 rounds).
- Weedle -> Kakuna (2 rounds) -> Beedrill (3 rounds).
- Pidgey -> Pidgeotto (4 rounds) -> Pidgeot (4 rounds).
- Rattata -> Raticate (5 rounds).
- Ekans -> Arbok (4 rounds).
- Sandshrew -> Sandslash (4 rounds).
- Diglett -> Dugtrio (4 rounds).
- Tentacool -> Tentacruel (5 rounds).
- Krabby -> Kingler (4 rounds).
- Magnemite -> Magneton (4 rounds).
- Goldeen -> Seaking (5 rounds).
- Magikarp -> Gyarados (8 rounds).
Wave 4 chains (v1.4.0):
- Spearow -> Fearow: after triggering its hand upgrade 3 times.
- Nidoran F -> Nidorina (4 rounds); Nidoran M -> Nidorino (4 rounds).
- Zubat -> Golbat: at +12 grown Mult.
- Oddish -> Gloom (4 rounds).
- Paras -> Parasect: at +8 grown Mult.
- Venonat -> Venomoth (5 rounds).
- Meowth -> Persian: after paying out $9 in end-of-round money.
- Psyduck -> Golduck (5 rounds).
- Mankey -> Primeape (5 rounds).
- Poliwag -> Poliwhirl (5 rounds).
- Abra -> Kadabra (5 rounds).
- Machop -> Machoke (5 rounds).
- Bellsprout -> Weepinbell (4 rounds).
- Geodude -> Graveler (4 rounds).
- Ponyta -> Rapidash: at +60 grown Chips.
- Slowpoke -> Slowbro: after triggering on the final hand 4 times.
- Doduo -> Dodrio (4 rounds).
- Seel -> Dewgong (5 rounds).
- Grimer -> Muk (5 rounds).
- Gastly -> Haunter (3 rounds).
- Drowzee -> Hypno: after using 7 distinct Planet cards.
- Voltorb -> Electrode (4 rounds).
- Cubone -> Marowak: after using 20 consumables.
- Koffing -> Weezing (2 rounds).
- Rhyhorn -> Rhydon (4 rounds).
- Horsea -> Seadra: at +12 grown Mult.
- Omanyte -> Omastar, Kabuto -> Kabutops: after triggering the
  3+ Ancient ability 5 times.
- Dratini -> Dragonair at +15 grown Mult -> Dragonite at +55.

Item evolutions (v1.2.0, fork build only; real targeting since
v1.3.0). The stones are Item consumables, registered under the
pack's own "poke_item" type at PC's shop_rate 4 and PC's $4 cost,
so they roll in the shop as their own kind, and since v1.3.0 the
pack also registers an Item Pack booster (choose 1 of 3 Items,
$4) that deals stones, as Item packs do on PC:
- Pikachu -> Raichu: use a Thunder Stone.
- Clefairy -> Clefable: use a Moon Stone.
- Jigglypuff -> Wigglytuff: use a Moon Stone.
- Growlithe -> Arcanine: use a Fire Stone.
- Shellder -> Cloyster: use a Water Stone.
Wave 4 stone targets (v1.4.0; the Leaf Stone joins the set):
- Vulpix -> Ninetales: Fire Stone. Eevee -> Flareon: Fire Stone.
- Poliwhirl -> Poliwrath: Water Stone. Staryu -> Starmie: Water
  Stone. Eevee -> Vaporeon: Water Stone.
- Eevee -> Jolteon: Thunder Stone.
- Nidorina -> Nidoqueen, Nidorino -> Nidoking: Moon Stone.
- Gloom -> Vileplume, Weepinbell -> Victreebel, Exeggcute ->
  Exeggutor: Leaf Stone.
Using a stone evolves the Joker you CHOOSE, on the spot: open the
Joker's tooltip (or focus it with the gamepad), then use the
stone. The stone refuses any other Joker, and a debuffed Joker
cannot be evolved (see port notes). Magneton does not take the
Thunder Stone here: its PC evolution is Magnezone, which is not
in the pack.

INCLUDED JOKERS
Starters and their lines:
- Bulbasaur (Uncommon, $5): +1 hand size; earn $1 for each card of a
  designated rank held in hand (rank changes every round).
- Ivysaur (Rare, $9) [NEW]: +1 hand size; earn $1 or $2 (1 in 2
  chance) per designated-rank card held in hand.
- Venusaur (Rare, $10) [NEW]: +1 hand size; earn $2 per
  designated-rank card held in hand.
- Charmander (Uncommon, $5): +1 discard; gains +1 Mult when a hand
  is played with no discards remaining.
- Charmeleon (Rare, $8) [NEW]: +1 discard; gains +2 Mult the same way.
- Charizard (Rare, $10) [NEW]: +1 discard; +36 Mult, and X1.5 Mult
  when no discards remain.
- Squirtle (Uncommon, $6): +1 hand; gains +1 Chips per remaining
  hand when a hand is played.
- Wartortle (Rare, $8) [NEW]: +1 hand; gains +2 Chips per remaining
  hand when a hand is played.
- Blastoise (Rare, $10) [NEW]: +1 hand; +120 Chips plus +25 Chips
  per remaining hand.
Bugs and birds:
- Caterpie (Common, $2): +3 Mult. Metapod (Common, $4): +6 Mult.
  Butterfree (Uncommon, $5): +12 Mult.
- Weedle (Common, $2): +20 Chips. Kakuna (Common, $4): +40 Chips.
  Beedrill (Uncommon, $5): +80 Chips.
- Pidgey (Common, $5): +2 Mult per distinct rank and suit in the
  poker hand. Pidgeotto (Rare, $6): +3. Pidgeot (Rare, $10): +5.
- Rattata (Common, $5): retrigger the first 2 scored cards once.
  Raticate (Rare, $7): the first 3.
Others:
- Ekans (Common, $5): +10 Mult if the hand contains a Straight.
- Arbok (Uncommon, $7) [NEW]: +15 Mult on a Straight; create a
  random Tarot card if the scoring hand also contains an Ace
  (must have room).
- Growlithe (Common, $5): +8 Mult if the hand contains a Flush.
- Arcanine (Rare, $8) [NEW]: X1.5 Mult on a Flush; the first
  unenhanced scoring card becomes a Mult card.
- Sandshrew (Common, $4): +25 Chips per Glass card in the full deck.
- Sandslash (Rare, $6) [NEW]: +40 Chips per Glass card in the full
  deck; each discarded Enhanced card has a 1 in 3 chance to become
  a Glass card.
- Diglett (Common, $5): +60 Chips on Three of a Kind, +4 Mult if a
  2, 3 or 4 scores. Dugtrio (Uncommon, $6): +120 Chips and X1.5 Mult.
- Clefairy (Common, $4): played Clubs give +3 Mult.
- Clefable (Rare, $10) [NEW]: played Clubs give +1 Mult per Club
  scored so far this round (resets each round).
- Jigglypuff (Common, $4): played Spades give +2 Mult and +10 Chips.
- Wigglytuff (Rare, $10) [NEW]: played Spades give +2 Mult and
  +30 Chips plus the card's own Chips.
- Tentacool (Common, $4): played 10s give +7 Mult.
  Tentacruel (Uncommon, $6): played 10s give +10 Mult.
- Magnemite (Uncommon, $7): played Steel cards give X1.5 Mult.
- Magneton (Rare, $8) [NEW]: played Steel cards give X1.5 Mult,
  plus X0.2 per adjacent Magnemite/Magneton (see port notes).
- Shellder (Uncommon, $5) / Cloyster (Rare, $8): with exactly 5
  scoring cards, each has a 1 in 3 (Shellder) or 1 in 2 (Cloyster)
  chance to retrigger once more.
- Krabby (Common, $4): played face cards give +20 Chips.
- Kingler (Uncommon, $7) [NEW]: played face cards give +20 Chips;
  scoring face cards without an enhancement become Bonus cards.
- Goldeen (Common, $5): retrigger held Gold card abilities once.
  Seaking (Rare, $8): twice.
- Mr. Mime (Rare, $8): retrigger the leftmost held card 3 times.
- Pinsir (Uncommon, $6): X2 Mult if a scored card's rank matches a
  card held in hand.
- Pikachu (Common, $6): +10 Mult at $25+; earn $2 at blind select
  when poorer than that.
- Raichu (Rare, $8) [NEW]: +4 Mult per $10 held; earn interest
  when a Blind is selected.
- Magikarp (Common, $2): +1 Chip. It tries its best.
- Gyarados (Rare, $10) [NEW]: X2.5 Mult.
- Rapidash (Rare, $8): gains Chips as hands are played; gains more,
  faster, on Straights.
- Articuno (Legendary, $20): the first scoring card gains Foil and a
  random seal if it has neither yet.

Wave 4 additions (v1.4.0) -- the rest of the non-Mega Gen 1 roster.
Effects are the PC base effects with energy stripped, as above;
each Joker's tooltip in game carries its full text:
- Spearow, Fearow; Nidoran F, Nidorina, Nidoqueen; Nidoran M,
  Nidorino, Nidoking; Vulpix, Ninetales; Zubat, Golbat; Oddish,
  Gloom, Vileplume; Paras, Parasect; Venonat, Venomoth; Meowth,
  Persian; Psyduck, Golduck; Mankey, Primeape; Poliwag, Poliwhirl,
  Poliwrath.
- Abra, Kadabra, Alakazam; Machop, Machoke, Machamp; Bellsprout,
  Weepinbell, Victreebel; Geodude, Graveler, Golem; Ponyta;
  Slowpoke, Slowbro; Doduo, Dodrio; Seel, Dewgong; Grimer, Muk.
- Gastly, Haunter, Gengar; Onix; Drowzee, Hypno; Voltorb,
  Electrode; Exeggcute, Exeggutor; Cubone, Marowak; Hitmonlee,
  Hitmonchan; Lickitung; Koffing, Weezing; Rhyhorn, Rhydon;
  Tangela; Kangaskhan; Horsea, Seadra.
- Staryu, Starmie; Scyther; Electabuzz; Magmar; Tauros; Tauros
  (Herd) (only reachable by direct creation, as on PC); Lapras;
  Eevee, Vaporeon, Jolteon, Flareon; Omanyte, Omastar; Kabuto,
  Kabutops; Aerodactyl; Zapdos (Legendary, with its floating soul
  layer, as are Mewtwo and Mew); Dratini, Dragonair, Dragonite;
  Mewtwo; Mew.

NOT PORTED (with the reason, refreshed for v1.4.0)
- All 22 Mega evolutions: the Mega framework (Mega Stone held
  items, in-battle mega state) does not exist in the fork or this
  pack. A later wave.
- Chansey: a successful Lucky trigger IS visible to Jokers (the
  fork's probability_success context, identifiers lucky_mult /
  lucky_money), but it carries no card identity, so the specific
  card that triggered cannot be copied to hand; the fork has no
  playing-card copy API either. (Its evolution, Blissey, is Gen 2.)
- Jynx: duplicating a card added to the deck needs to know WHICH
  card was added; the fork's playing_card_added context carries
  only a count.
- Ditto: needs a readable Perishable state on held Jokers and
  Pokermon's Volatile (right) system; neither exists in the fork.
- Porygon: its only effects are Energy-system effects; with energy
  stripped pack-wide it would be an empty Joker.
- Snorlax: scales off held Leftovers, an item consumable that is
  not registered in this pack, so the count could never rise.
- Moltres: levelling the DISCARDED hand needs a hand-evaluation
  API for an arbitrary set of cards; the fork exposes none.
- Missingno: copying a consumable into every empty Joker and
  consumable slot is not a state the fork's card areas support,
  and there is no consumable copy API.
- Farfetch'd: its whole mechanic is the Leek, a reusable held
  item; no held-item system exists in this pack.
- Shell: not a Joker on PC either -- an aux trigger card for
  Slowpoke's shop cameo; classified and skipped, and Slowpoke's
  Shell evolution path is dropped with it.

EVOLUTION STONES (Item consumables, $4, fork build only)
- Fire Stone: evolves the chosen Growlithe into Arcanine, Vulpix
  into Ninetales, or Eevee into Flareon.
- Water Stone: evolves the chosen Shellder into Cloyster,
  Poliwhirl into Poliwrath, Staryu into Starmie, or Eevee into
  Vaporeon.
- Thunder Stone: evolves the chosen Pikachu into Raichu, or Eevee
  into Jolteon.
- Moon Stone: evolves the chosen Clefairy into Clefable,
  Jigglypuff into Wigglytuff, Nidorina into Nidoqueen, or Nidorino
  into Nidoking.
- Leaf Stone: evolves the chosen Gloom into Vileplume, Weepinbell
  into Victreebel, or Exeggcute into Exeggutor.
A stone can be used only on a chosen Joker it evolves (held and
not debuffed); using it evolves that Joker immediately, with the
same edition/scaling carry-over as the other chains.

Validated headlessly against the Balatro3DS fork source (loader +
per-Joker tests incl. five evolution chains end to end, edition
preservation, and stone registration, chosen-target evolution and
Item Pack checks; suite 34/34 incl. the Wave 4 Leaf Stone / Eevee
branching tests, a registration count of 145 and a blanket
no-error scoring pass over every Joker) on 2026-10-23. Not yet
tested on real hardware.

Port notes:
- Energy is stripped everywhere; each Pokemon keeps its base effect
  at its base (un-energized) values. The custom "poke_safari" rarity
  maps to Rare.
- Stones: on PC a stone can also be aimed at a highlighted Joker
  and carries a secondary playing-card effect (Fire: Mult cards,
  Water: Bonus cards, Thunder: Gold copies, Moon: upgrade a poker
  hand), and the evolution itself lands at the end of the round.
  The 3DS port does not port the secondary effects, so a stone
  here is an evolution-only card; since v1.3.0 it targets the
  chosen Joker through the fork's Tier 3 targeting (the same
  choice PC's highlighted Joker makes) and evolves it on the
  spot. The Item Pack booster is registered without pack-wrapper
  art (none exists in this pack; its card art was sliced from the
  NatDex atlas), so the shop shows the engine's plain booster
  fallback panel for it. The poke_item kind also gets the fork's
  collection category, as custom kinds now do.
- Magneton's PC effect counts adjacent Metal-type Jokers. Pokemon
  types do not exist in the port, and the only Metal line in this
  roster is Magnemite/Magneton, so adjacency counts those two.
- Arbok creates its Tarot during scoring instead of before it; the
  card still arrives the same hand.
- Tentacruel's "10s can't be debuffed" passive and Goldeen/Seaking's
  card_effects nuance have no 3DS equivalent and are dropped.
- Articuno only adds Foil/a seal when the card has none yet (the
  original converts unconditionally).
- New-form artwork is sliced from the PC mod's own Natdex atlas;
  the original 35 keep their existing pack art.
- Wave 4 named deviations (full per-Joker record ships in the
  porting census): Gastly line applies Negative by destroy/recreate
  and fires at round end instead of PC's round_eval; volatile faint
  (Voltorb line, Koffing line) is a self-gate flag instead of a
  visible debuff; the Poli line tracks its suit per Joker instead
  of run-global; Kadabra/Alakazam create a random Item instead of
  the specific Twisted Spoon; cross-generation and item evolutions
  whose targets are not Gen 1 stay unwired (Haunter, Machoke,
  Graveler, Kadabra item lines; Onix, Seadra, Lickitung, Rhydon,
  Tangela type/item lines; Golbat -> Crobat, Primeape ->
  Annihilape dropped with their counters); held-item grants
  (Ninetales' Medium, Hypno's Trance, Cubone's Thick Club) and the
  Exeggcute line's Foresight/scry passives are dropped; Tauros's
  shop-reroll cameo and Lapras's skip-opens-shop effect have no
  fork equivalent and are dropped; Grimer/Muk compare deck size
  against the size when the Joker was gained (the fork does not
  expose the run-start size); Dodrio's temporary hand-size
  sub-effect is dropped (hand size is a static modifier here).

Original mod: https://github.com/InertSteak/Pokermon (GPLv3).
Game: https://github.com/idkhan/Balatro3DS
Fork: https://github.com/sen2008/balatro3ds-fork
