MoreFluffPack for Balatro3DS
============================

89 Jokers ported from MoreFluff (PC mod by notmario), including the
Letter Jokers, the Scrapped set and the token Jokers. The full roster
is in the repository README; the 140 PC Jokers that could not be
ported are listed there too, each with the exact system it is blocked
on.

REQUIRES the Balatro3DS fork build
(github.com/sen2008/balatro3ds-fork). The port registers MoreFluff's
custom rarities and uses the fork's SMODS.add_card / destroy_card,
retrigger and post_trigger passes and probability-shaping contexts,
none of which exist on the stock game.

Install: copy the MoreFluffPack folder into
  /3ds/save/Balatro3DS/sdmc/mods/
on your SD card, restart the game, and check Options -> Mods.

Rarities: MoreFluff's six custom rarities (Scrapped, Letter, Purple,
Token, Super Legendary, Rot Legendary) are registered at weight 0.
On PC their Jokers reach the player through hidden-rarity rolls,
Letter packs, Rotarots and token creation, none of which exist here,
so they may not take shop share; ported Jokers of those rarities are
created by other ported Jokers (Forge, Letter F, Fish's family, ...)
or appear through effects. Common/Uncommon/Rare Jokers shop normally.

Deviations from the PC mod (all forced by missing fork systems):
- Hyper Beam: the lose-all-discards clause is dropped (no API to
  change remaining discards mid-round).
- Knuckleblaster: the play-1-fewer-card clause is dropped; the
  X3 Mult is kept.
- Letter I: the short-Straights clause is dropped; the X2 Mult on a
  5-card Straight is kept.
- Stifle: the right Joker still pays +120 Chips, but its trigger is
  not suppressed (no per-Joker calculate override).
- Virtual: the flip/shuffle of scoring cards is dropped.
- Jester: the Marble Joker it creates is not Eternal.
- Letter W: the Wheel of Fortune odds boost is dropped.
- Disintegration Loop: the Event Horizon transform is dropped, and it
  keeps PC's in_pool = false (creation/debug only, as on PC).
- Blade Dance: the Steel cards it adds are permanent (PC removes
  them at end of round).
- Brainrot: its destroy forces past Eternal (PC respects Eternal).
- Style Meter: counts blinds skipped while held (PC counts the
  run total).
- Expansion Pack: its "modded pool" is this pack's own Jokers.
- Friend Inside Me: reactivates when a Boss Blind ends (PC uses a
  custom post-Boss hook).
- Basepaul Card: always X1.25 (PC checks the profile name).
- The Baseball Stream: PC's cross-Joker hook is folded into the
  fork's post_trigger pass; the visible effect is the same.
- Letter D: destroys from deck + discard pile + hand, one card at a
  time; PC's destroy banner art is dropped.
- grep: counts the round's discards itself; a copy gained mid-round
  starts its count at zero.
- Burner Phone: the deck peek is text-only, as on PC; PC's per-word
  tooltip colours are dropped.
- Less Fluff: PC's tooltip says it destroys Modded Jokers, but PC's
  code destroys the non-modded ones. The port follows the code.
- Letter Q: PC's debuffed-card message is dropped; the X1.3 for
  cards next to a held Queen is unchanged.
- Top 10: PC's collection/badge extras are dropped; its soul-layer
  art is included.
- Bowling Ball, Pixel Joker and Jack of all Trades keep their
  v1.0.0 port keys (bowling_ball, pixel_joker, jack_of_all_trades)
  so old saves keep working. Pixel Joker's art is a single solid
  pixel on PC, stretched over the card by the game; same here.

Validation: 56 pack tests (registration and tooltips for all 89,
behaviour tests for the non-trivial effects) plus the fork's own
54-test mod suite, all passing on the fork build.

Credit: MoreFluff is by notmario (github.com/notmario/MoreFluff).
The PC repo carries no license file; this is an unofficial fan port
and will be taken down if the author asks.
