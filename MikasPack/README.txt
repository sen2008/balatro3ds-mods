Mika's Mod Collection (3DS Port) v1.0.0
58 of Mika's 60 Jokers, 3 consumables and 6 decks, ported to Balatro3DS.

REQUIRES THE BALATRO3DS FORK
The decks register through the fork's SMODS.Back API, Grudgeful Joker
and Historical Joker lower live blind targets through
SMODS.adjust_blind_target, and Student Loans spends into debt through
the fork's debt_limit Joker config. On the stock Universal-Updater
build the pack cannot load its decks and those Jokers have no effects.
  https://github.com/sen2008/balatro3ds-fork
The test file (test_mikaspack.lua) stays in the mod folder; the
game ignores it.

INSTALL
1. Unzip this file.
2. Copy the MikasPack folder to your SD card at:
     /3ds/save/Balatro3DS/sdmc/mods/MikasPack
3. Start (or restart) Balatro3DS.
4. Check Options -> Mods: "Mika's Mod Collection" should be listed.
   If a mod fails to load, the reason is written to mods/mods_log.txt
   in the same folder.

COUNTS
- Jokers: 58 of 60 (full list below).
- Consumables: 3 of 3 default-enabled (Ace of Pentacles and Page of
  Pentacles, Tarots; Incense, Spectral).
- Decks: 6 of 7 (below).

NOT PORTED, AND WHY
- Dagonet (Joker): doubles every base value on every other held Joker
  by rewriting their ability tables in place. The fork's vanilla
  Jokers are engine-coded effects reading their own configs, not a
  generic ability-value layer a mod can scale, so there is nothing
  for the doubling to bite on. Doubling only other mod Jokers would
  be a different, weaker mechanic.
- Cicero (Joker): forces shop Jokers whose text lacks Mult / Chips /
  retrigger to be Negative as their edition is set. Fork Jokers get
  no hook over unowned shop offers (the store moments exist only as
  Tag apply types), and offer mutation is a new API, not a small
  addition, so Cicero stays out rather than shipping a lookalike.
- "Jokers for Hire" (Deck): every held Joker grants +1 Joker slot
  while Joker and Buffoon Pack prices scale per Joker owned. Both
  halves are dynamic run rules with no deck-config equivalent, and a
  static version would mislead, so the deck is not registered.
- The 6 in-development Tarots (King of Cups, Chips, Mult, XMult,
  Money, Support) and the 2 empty-stub Tarots (Card Chips, Card
  Mult) are config-off or unimplemented on PC too; they stay out.
  One PC sprite (j_mmc_statistic.png, an unregistered "Statistic"
  Joker) is likewise unused upstream and not shipped.

DECKS
- Even Steven's Deck: only even cards (2, 4, 6, 8, 10); start with
  Even Steven.
- Odd Todd's Deck: only odd cards (3, 5, 7, 9, Aces); start with
  Odd Todd.
- Fibonacci Deck: only Fibonacci ranks (2, 3, 5, 8, Aces); start
  with Fibonacci.
- Prime Deck: only prime ranks (2, 3, 5, 7, Aces); start with
  Prime Time.
- Midas's Deck: only face cards, all Gold; start with Midas Mask.
- Perfect Precision Deck: +1 hand, +1 discard, +1 hand size, Antes
  scale X1.5 as fast; start with a Negative Sniper.

JOKERS
Prime Time, Straight Nate, The Fisherman, Impatient Joker, Cultist,
Seal Collector, Camper, Scratch Card, Delayed Joker, The Show-Off,
The Sniper, Blackjack Joker, Batman, Bomb, Eye Chart, Grudgeful
Joker, Finishing Blow, Aurora Borealis, Historical Joker, Suit
Alley, The Printer, Training Wheels, Horseshoe, Incomplete Joker,
Abbey Road, Fishing License, Gold Bar, Rigged Joker, The Commander,
Blue Moon, Glue, Harp Seal, Football Card, Special Edition Joker,
The Stockpiler, Student Loans, Broke Joker, Go For Broke, Street
Fighter, Checklist, One Of Us, The Investor, Mountain Climber,
Shackles, Buy One Get One, Pack A Punch, Seal Steal, Tax Collector,
Glass Cannon, Scoring Test, Dawn, Savings, Monopolist, Nebula,
Cheapskate, Psychic Joker, Cheat, Plus One.

PORT NOTES (deliberate deviations from PC)
- Incense charges a flat -$50 per use. On PC the price climbs $25
  per use, kept in run-persistent state the fork has no home for.
- Harp Seal's Gold Seal money, Scratch Card's tiers and The
  Investor's payout are paid once. On PC all three pay twice (an
  ease_dollars call plus a dollars return saying the same thing).
- Cheapskate stashes half a Booster Pack's price when the pack is
  bought and pays it when a pack is skipped. On PC it read the
  price off the opened pack; the fork's pack-opened context carries
  no price, so the buy is the closest priced moment.
- Finishing Blow enhances the round's High Card cards at round end
  rather than when the blind falls; the same cards are enhanced.
- Aurora Borealis and Harp Seal count held Blue Seals at round end
  and make their extra Planets then. On PC they ride the seal's own
  end-of-round effect; the cards counted (held, Blue Seal, not
  debuffed) and the Planets made are the same, including Harp Seal
  doubling Aurora's Negative Planet when both are held.
- Eye Chart re-rolls its letter when the Joker is gained, not when
  a shop copy's price is set; the fork gives held Jokers no
  shop-appearance hook.
- Checklist picks its hand from the full hand list. PC restricts
  the pool to visible hands; the fork exposes no visibility flag.
- Monopolist settles its money thresholds on every money change
  instead of per frame; it converges to the same resting state.
- Glue, The Stockpiler and Student Loans drive the fork's dynamic
  while-held modifier fields (joker_slots, h_size, d_size), where PC
  maintained the same numbers in global add/remove hooks.

Original mod: https://github.com/MikaSchoenmakers/MikasModCollection
(GPLv3; this port is GPLv3 too. The full license text ships in the
pack as LICENSE.txt.)
Game: https://github.com/idkhan/Balatro3DS
Fork: https://github.com/sen2008/balatro3ds-fork
