Bunco Pack (3DS Port) v1.1.0
Fifty-one of Bunco's eighty Jokers, both exotic suits, the four
Spectrum-family poker hands plus Deal, and six consumables, from
Bunco (PC, by Firch) ported to Balatro3DS.

REQUIRES THE BALATRO3DS FORK (v1.1.0)
The v1.1.0 additions create and destroy cards, use retrigger
returns, register suits and poker hands, and gate exotic-suit cards
in the random card-front pool the fork builds for Standard packs and
shop playing cards, which the stock game's mod API cannot do. They
need the fork build and its Tier 1 + Tier 2 mod APIs
(SMODS.add_card / SMODS.destroy_joker / SMODS.destroy_card,
SMODS.Suit, SMODS.PokerHand):
  https://github.com/sen2008/balatro3ds-fork
On the stock Universal-Updater build the pack still loads and the
original nineteen Jokers work (without their exotic-suit branches),
but the new content has no effects.
The test file (test_buncopack.lua) stays in the mod folder; the
game ignores it.

INSTALL
1. Unzip this file.
2. Copy the BuncoPack folder to your SD card at:
     /3ds/save/Balatro3DS/sdmc/mods/BuncoPack
3. Start (or restart) Balatro3DS.
4. Check Options -> Mods: "Bunco Pack" should be listed.
   If a mod fails to load, the reason is written to mods/mods_log.txt
   in the same folder.

THE EXOTIC SYSTEM
Fleurons and Halberds join the game exactly as on PC: score any
Spectrum-family hand (Spectrum, Straight Spectrum, Spectrum House,
Spectrum Five) once, and from then on exotic-suit cards can appear
in Standard packs and the shop, the thirteen exotic Jokers enter the
pools, and Cassette / Crop Circles pay on the new suits. The four
Planets (Quaoar, Haumea, Sedna, Makemake) level the Spectrum hands;
The Sky and The Abyss convert up to 3 selected cards to Fleurons or
Halberds. Registration Plate picks five ranks from your deck each
round; playing exactly those ranks scores as the Deal hand, which
carries the Chips and Mult of every poker hand played this run.

INCLUDED JOKERS (51 of 80)
Original nineteen: Cassette, Mosaic, Voxel, Crop Circles,
Prehistoric, Shepherd, Dogs Playing Poker, Nil Bill, Slothful,
Hierarchy of Needs, Headshot, Protester, Disproportionality,
On Broadway, Rasta, Critic, Wino, Tangram, Jumper.
New in v1.1.0:
- Basement (Rare, $8) [fork only]: when the Boss Blind is defeated, create a random Spectral card (must have room).
- Carnival (Rare, $10) [fork only]: after defeating the Boss Blind, destroy a random Joker and go one Ante back; works once per Ante value.
- Dread (Rare, $8) [fork only]: after your last hand, level that hand up by 2 and destroy the played cards; selling Dread reverses the levels.
- The Joker (Rare, $10) [fork only]: each scoring card without an enhancement has a 1 in 3 chance to be destroyed after play.
- Registration Plate (Rare, $8) [fork only]: enables the Deal hand (see above).
- Righthook (Rare, $8) [fork only]: retrigger the last scoring card once per remaining hand.
- Linocut (Uncommon, $4) [fork only]: a played Pair of exactly two cards converts the left card's suit into the right card's.
- Ghost Print (Uncommon, $6): gives the Chips and Mult of the last hand type played.
- Loan Shark (Uncommon, $3): gain $50 when acquired; its sell value is -$100.
- Fingerprints (Uncommon, $8): scored cards gain +50 Chips for the next round.
- Bierdeckel (Uncommon, $4): cards left in hand gain +10 Chips until the end of the round.
- Zero Shapiro (Uncommon, $4): scored Kings, Queens, Jacks and Stone cards have a 1 in 8 chance to create a D6 Tag.
- Doodle (Rare, $10): once per round, using a Tarot or Planet duplicates it (if there is room).
- Pawn (Common, $5): scored cards tied for the deck's lowest rank gain +1 rank after play.
- Hopscotch (Common, $4): +1 discard this round when you play a Straight.
- X-Ray (Common, $4): X0.2 Mult per card drawn face down.
- Mousetrap (Uncommon, $6): 1 in 3 chance to lose a hand instead of scoring; with no hands left, the hand scores +300 Chips instead.
- Stylophone (Uncommon, $5): scored cards give +0.3 Mult per pip of rank.
- Juggalo (Rare, $5): when a blind is selected, a random owned consumable gains a random edition.
- Puzzle Board (Uncommon, $6): using a Tarot has a 1 in 4 chance to put a random edition on a random highlighted card.
Exotic Jokers (appear once the exotic system is on):
- Zealous (Common, $3): +10 Mult if the played hand contains a Spectrum.
- Lurid (Common, $3): +80 Chips if the played hand contains a Spectrum.
- Envious (Common, $5): scored Fleurons give +6 Mult.
- Proud (Common, $5): scored Halberds give +6 Mult.
- Wishalloy (Uncommon, $7): 1 in 7 chance for scored Fleurons to earn $ equal to their scored Chips.
- Unobtanium (Uncommon, $7): scored Halberds give +30 Chips and +6 Mult.
- Magic Wand (Common, $5): gains +3 Mult per consecutive hand containing a Spectrum, resets on any other hand.
- Starfruit (Uncommon, $5): level up the played hand if it contains a Spectrum; 1 in 4 chance to be destroyed at end of round.
- Fondue (Rare, $8): scored cards in the first hand of the round become Fleurons.
- Roy G. Biv (Uncommon, $8): 1 in 7 chance to give every scored card Polychrome when the hand contains a Spectrum.
- The Dynasty (Rare, $8): X5 Mult if the played hand contains a Spectrum.
- Rigoletto (Legendary, $20): X1 Mult plus X0.2 per exotic card (exotic suit or Wild) in your full deck.

Validated headlessly against the Balatro3DS fork source (pack suite
38/38, including suit/hand evaluation, the exotic gate, and
create/destroy behavior; the fork's own mod suite is 49/49) on
2026-10-22. Not yet tested on real hardware.

Port notes:
- The exotic gate is derived, not stored: PC sets a flag the first
  time a Spectrum-family hand is scored; the port reads the game's
  own per-hand play counts, which persist in the save the same way.
- The Sky and The Abyss are not pool-gated on the port (mod
  consumables have no pool gate here); on PC they are exotic-only.
  Using one is still just a suit conversion.
- Bunco's temporary extra Chips (Fingerprints, Bierdeckel) ride on
  the port's per-card Bonus field, tracked per Joker and removed at
  end of round, which reproduces their lifetimes.
- X-Ray banks its Mult when a draw completes (the port reports draws
  in one event), not card by card as on PC.
- Juggalo's edition roll leaves out Glitter, a Bunco custom edition
  that does not exist here; Foil, Holographic and Polychrome remain.
- Stylophone's sound-click ladder is cosmetic on PC and is not
  ported; the Mult effect is.
- Cassette is a single Joker whose side flips on discard; its art
  always shows the A side (one sprite per Joker in this API).
- Disproportionality loses its fake-crash tooltip gag; plain text
  instead.
- Descriptions are Bunco's en-us text, verbatim where the port's
  markup allows (Bunco's custom suit colours become plain emphasis).

Original mod: https://github.com/Firch/Bunco (no license;
unofficial fan port with credit - takedown on request, see the repo
README).
Game: https://github.com/idkhan/Balatro3DS
Fork: https://github.com/sen2008/balatro3ds-fork
