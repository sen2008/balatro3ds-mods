Bunco Pack (3DS Port) v1.2.0
Fifty-three of Bunco's eighty Jokers, both exotic suits, the four
Spectrum-family poker hands plus Deal, six consumables, and the
Fluorescent edition, from Bunco (PC, by Firch) ported to
Balatro3DS.

REQUIRES THE BALATRO3DS FORK (v1.1.0; v1.2.0 additions need
Tier 3)
The v1.1.0 additions create and destroy cards, use retrigger
returns, register suits and poker hands, and gate exotic-suit cards
in the random card-front pool the fork builds for Standard packs and
shop playing cards, which the stock game's mod API cannot do. They
need the fork build and its Tier 1 + Tier 2 mod APIs
(SMODS.add_card / SMODS.destroy_joker / SMODS.destroy_card,
SMODS.Suit, SMODS.PokerHand). The v1.2.0 additions (Neon, Bounty
Hunter, the Fluorescent edition) use Tier 3
(SMODS.Edition, the setting_ability and money_altered contexts):
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

INCLUDED JOKERS (53 of 80)
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
New in v1.2.0:
- Neon (Uncommon, $5) [fork only]: playing cards gain the Fluorescent edition when enhanced (see port notes for what Fluorescent does and does not do here).
- Bounty Hunter (Common, $5) [fork only]: every money gain is taxed $1, and this Joker permanently gains +1 Mult per taxed gain.
Also new in v1.2.0: the Fluorescent edition itself (Bunco's
stat-less edition; Neon's grant and the shop/Aura edition polls
can apply it).

Validated headlessly against the Balatro3DS fork source (pack suite
41/41, including suit/hand evaluation, the exotic gate,
create/destroy behavior, and the v1.2.0 edition grant and money
tax) on 2026-10-23. Not yet tested on real hardware.

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
- Fluorescent's PC effect is pure immunities (cannot be flipped,
  debuffed or forced to be selected), enforced on PC by Lovely
  patches. The fork's editions are config-only with no hooks, so
  the immunities are NOT implemented: the edition registers with
  no stats and no shader (PC's look is a shader), and its tooltip
  says so. Neon's grant of it works exactly as on PC.
- Bounty Hunter's tax lands as its own -$1 money event right after
  each gain, rather than shrinking the gain before it lands as
  PC's money wrapper does; final totals and Mult growth match.
  One corner differs: with several copies held, each copy taxes
  the same gain, where PC's later copies see the already-taxed
  remainder (and stand down on a $1 gain).

NOT PORTED (27 of 80 Jokers)
- Gameplan, Conquest: both debuff JOKERS (Gameplan its two
  neighbours, Conquest a random other Joker). Tier 3 debuff
  (SMODS.set_debuff / debuff_card) covers playing cards only;
  there is no mod-settable Joker debuff to build them on.
- Fiendish: rewrites every money gain before it lands (1 in 3
  chance it becomes $1, otherwise it doubles). money_altered
  returns are additive amounts applied after the gain; doubling
  via a second gain would be seen as a new gain by other Jokers
  and would compound wrongly with multiple copies.
- JMJB, Aristocrat: rewrite or extend Booster Pack contents (only
  Enhanced cards in Standard Packs; one extra pack choice). The
  open_booster context still carries no payload, and SMODS.Booster
  registers new packs without exposing dealt cards or choice
  counts.
- Kite Experiment, Robot: both score entirely on PC's
  rescore_cards context (rescored Copper cards), which the fork
  still does not have. Copper's only effect is that rescore, so
  the Copper enhancement is not registered either: an inert
  Copper would print text it cannot honour.
- Hardtack, Pica (and the Adjustment Tarot): the Cracker system
  is a Lovely hijack of the discard button: highlighted Cracker
  cards (with Pica, all highlighted cards) are PLAYED instead of
  discarded, then destroyed after scoring unless Hardtack is
  held. There is no discard-to-play redirect or discard veto.
- Sledgehammer, Dwarven, Metallurgist: add/remove hooks that
  rewrite the vanilla Glass, Stone and Gold center configs.
  Registered enhancements do not touch vanilla centers.
- Doorhanger, Running Joke: Doorhanger rewrites the rarity of
  every card as it is created (a create_card patch); Running Joke
  inserts a free Negative Joker offer into the shop at shop
  start. There is no shop-offer insertion API for Jokers.
- Myopia, Astigmatism: no calculate at all on PC; global
  Card:is_suit patches make Spades/Clubs count as Halberds and
  Hearts/Diamonds count as Fleurons everywhere. No global
  is_suit patch surface exists.
- Trigger Finger, Vandalism, Cellphone: Trigger Finger needs
  the highlight_card context plus forcing a play; Vandalism
  needs cards drawn and kept face down (the fork turns played
  face-down cards face up before any Joker context); Cellphone's
  return-scored-cards-to-hand after the first play is a Lovely
  redirect of the play flow (press_play exists, but only arms
  it on PC).
- Head in the Clouds: hooks the level_up_hand context, which
  fires for ANY hand levelled, by any means. No hand-levelled
  context exists; watching Planet use would miss level-ups from
  Jokers and other sources.
- Domino: acquires the two cards adjacent to a bought or used
  shop/Booster card, via pre-purchase contexts carrying the
  neighbours. The fork's buying contexts carry no such payload.
- Knight: gains Mult when the Blind is selected and shuffles
  the Joker row; the Mult resets when any Joker is rearranged.
  Neither a Joker-row shuffle nor a reorder (break_positions)
  context exists.
- Glue Gun, Taped, Rubber Band Ball, Games Collector: Bunco's
  linked-group system (group consumables, the groups_drawn
  context) has no fork equivalent.
- Headache: counts destroyed playing cards and creates an
  Arcade Tag per four. The tag itself is registrable now, but
  its payload is a free Mega Virtual Pack dealing Polymino
  (linked-group) cards through a custom whole-deck UI; neither
  the cards nor the UI exist here.

Original mod: https://github.com/Firch/Bunco (no license;
unofficial fan port with credit - takedown on request, see the repo
README).
Game: https://github.com/idkhan/Balatro3DS
Fork: https://github.com/sen2008/balatro3ds-fork
