KCVanilla Pack (3DS Port) v1.1.0
Fourteen Jokers from KCVanilla (PC, by krackocloud) ported to Balatro3DS.
(Swiss Cheese is a separate download: KCVanillaSwiss.)

REQUIRES THE BALATRO3DS FORK (v1.1.0)
The five new Jokers (Fortune Cookie, Rats!, Cosmic Collapse, Loose
Tooth, Scapegoat) create and destroy cards, which the stock game's mod
API cannot do. They need the fork build and its Tier 1 mod API
(SMODS.add_card / SMODS.destroy_joker / SMODS.destroy_card):
  https://github.com/sen2008/balatro3ds-fork
On the stock Universal-Updater build the pack still loads and the
original nine Jokers work, but the five new ones have no effects.
The test file (test_kcvanillapack.lua) stays in the mod folder; the
game ignores it.

INSTALL
1. Unzip this file.
2. Copy the KCVanillaPack folder to your SD card at:
     /3ds/save/Balatro3DS/sdmc/mods/KCVanillaPack
3. Start (or restart) Balatro3DS.
4. Check Options -> Mods: "KCVanilla Pack (3DS Port)" should be listed.
   If a mod fails to load, the reason is written to mods/mods_log.txt
   in the same folder.

INCLUDED JOKERS
- Composition (Common, $4): +4 Mult per Joker to the left, +20 Chips per Joker to the right.
- Royal Guard (Common, $5): if the played hand has no Kings or Queens, +10 Chips per King/Queen in your full deck.
- Joker-chan (Uncommon, $6): at end of round, gains +2 Mult per Common Joker held.
- Red Envelope (Uncommon, $5): earn $8 per Common Joker when the Boss Blind is defeated.
- Jimbot (Uncommon, $5): gains the Chip value of the first scoring numbered card each round.
- Ten-Pin (Uncommon, $5): a scoring 10 gives X2 Mult for the next 2 hands.
- Handy Joker (Uncommon, $6): gains X1 Mult per single enhanced card discarded; resets after the Boss Blind.
- Joker Energy (Uncommon, $6): scored Wild cards give a random one of +10 Mult, +100 Chips, X2 Mult, $5.
- Power Grid (Uncommon, $6): scored Mult cards give X Mult, growing +0.1 per Mult card scored this round.
- Fortune Cookie (Common, $5) [NEW, fork only]: +150 Chips, -50 Chips when a Tarot is used; eaten when it runs out.
- Rats! (Uncommon, $6) [NEW, fork only]: when the round begins, destroy a random card in hand and duplicate this Joker (copy loses Negative).
- Cosmic Collapse (Rare, $7) [NEW, fork only]: at end of round, each held Planet has a 1 in 2 chance to transform into a Black Hole.
- Loose Tooth (Common, $5) [NEW, fork only]: create a Tarot if the played hand has a non-scoring Ace (must have room).
- Scapegoat (Uncommon, $6) [NEW, fork only]: if the first discard of the round is 1 card, destroy it and add its Chip value to a random card in hand.

Validated headlessly against the Balatro3DS fork source (loader +
per-Joker tests incl. create/destroy behavior, 9/9; the fork's own mod
suite stays 43/43) on 2026-10-22. Not yet tested on real hardware.

Original mod: https://github.com/kcgidw/kcvanilla (no license; unofficial
fan port with credit - takedown on request, see the repo README).
Game: https://github.com/idkhan/Balatro3DS
Fork: https://github.com/sen2008/balatro3ds-fork
