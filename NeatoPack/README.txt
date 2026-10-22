Neato Pack (3DS Port) v1.1.0
Fifteen Jokers from Neato Jokers (PC, by neatoqueen) ported to Balatro3DS.

REQUIRES THE BALATRO3DS FORK (v1.1.0)
The nine new Jokers (Australian Shepherd, The Banana Stand, Blue
Yourself, Dayman, Nightman, Dogs Playing Balatro, Frosted Prime Rib,
Hatsune Joku, JokerZD) create and destroy cards and use retrigger
returns, which the stock game's mod API cannot do. They need the fork
build and its Tier 1 mod API (SMODS.add_card / SMODS.destroy_joker /
SMODS.destroy_card):
  https://github.com/sen2008/balatro3ds-fork
On the stock Universal-Updater build the pack still loads and the
original six Jokers work, but the nine new ones have no effects, and
Ice Cream Sandwich floors at X1 instead of being eaten.
The test file (test_neatopack.lua) stays in the mod folder; the
game ignores it.

INSTALL
1. Unzip this file.
2. Copy the NeatoPack folder to your SD card at:
     /3ds/save/Balatro3DS/sdmc/mods/NeatoPack
3. Start (or restart) Balatro3DS.
4. Check Options -> Mods: "Neato Pack" should be listed.
   If a mod fails to load, the reason is written to mods/mods_log.txt
   in the same folder.

INCLUDED JOKERS
- Unpaid Intern (Common, $6): scored 9s and 5s give +40 Chips.
- Tabby Cat (Common, $6): gains +2 Mult every 9 cards discarded.
- Wild Card Charlie (Uncommon, $7): Wild Cards give X1.5 Mult when scored or held in hand.
- Lock-In Joker (Common, $4): gains +3 Mult when a Blind is selected, resets when a Joker is sold.
- Spare Cutoffs (Uncommon, $6): gains +12 Chips whenever a played hand contains a Two Pair.
- Ice Cream Sandwich (Uncommon, $6): X5 Mult, loses X1 Mult per round played, eaten when it runs out.
- Australian Shepherd (Common, $4) [NEW, fork only]: create a random Planet card when a Blind is selected (must have room).
- The Banana Stand (Common, $6) [NEW, fork only]: 1 in 4 chance for a played hand to give $10; 1 in 25 chance at end of round to be destroyed and lose ALL money.
- Blue Yourself (Rare, $8) [NEW, fork only]: retriggers Jokers and cards with the Foil edition (appears only once you own a Foil).
- Dayman (Uncommon, $6) [NEW, fork only]: if the first hand of the round is a single Queen, destroy it and gain X0.5 Mult.
- Nightman (Uncommon, $6) [NEW, fork only]: when a hand is played, destroy a random scoring card and gain X0.1 Mult.
- Dogs Playing Balatro (Rare, $6) [NEW, fork only]: 1 in 4 chance to fetch a random Spectral card when a Planet is used (must have room).
- Frosted Prime Rib (Uncommon, $6) [NEW, fork only]: for the next 22 hands, every scored card permanently gains +2 Chips and +1 Mult; then it is eaten.
- Hatsune Joku (Uncommon, $5) [NEW, fork only]: retrigger played 9s an additional two times.
- JokerZD (Rare, $8) [NEW, fork only]: gains X0.15 Mult for every unique Joker purchased.

Validated headlessly against the Balatro3DS fork source (loader +
per-Joker tests incl. create/destroy/retrigger behavior, 18/18; the
fork's own mod suite stays 43/43) on 2026-10-22. Not yet tested on
real hardware.

Port notes:
- Dayman and Nightman destroy played cards in the port's after pass,
  the slot the port's own Sixth Sense uses for Steamodded's
  destroying_card context, which Balatro3DS never raises. The card
  still scores first, as on PC.
- Frosted Prime Rib's permanent gains write the port's own card fields
  (card_data.Bonus / mult_bonus), the same ones Hiker writes.
- Blue Yourself's guard against retriggering a foil Blueprint that is
  itself copying Blue Yourself reads a context field the port does not
  provide, and is dropped.
- Hatsune Joku's custom music track has no port equivalent; only the
  Joker effect is ported.
- Australian Shepherd and Dogs Playing Balatro pick their random
  consumable with the game's own per-kind picker (which never offers
  The Soul or a Black Hole), since the fork's add_card needs a def id.
- JokerZD tracks unique purchases by def id instead of card label.
- Wild Card Charlie's pool gate (needs a Wild Card in your deck) is
  dropped; it can appear in the shop at any time.

Original mod: https://github.com/neatoqueen/NeatoJokers (no license;
unofficial fan port with credit - takedown on request, see the repo
README).
Game: https://github.com/idkhan/Balatro3DS
Fork: https://github.com/sen2008/balatro3ds-fork
