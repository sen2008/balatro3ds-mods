MoreFluffPack for Balatro3DS
============================

133 Jokers ported from MoreFluff (PC mod by notmario), including the
Letter Jokers, the Scrapped set and the token Jokers, plus 14 Colour
consumables and 6 booster packs (2 Modded, 4 Colour). The full roster
is in the repository README; the 96 PC Jokers that could not be
ported are listed there too, each with the exact system it is blocked
on.

v1.4.0 (Wave 6) adds 25 Jokers, the Colour consumable system and six
booster packs, unblocked by the fork's Wave 6 shop / voucher /
booster APIs:
- Shop and booster Jokers: Bouncer (the card to its right returns to
  the shop as an offer, and Bouncer gains +3 Chips per $1 of its sell
  value; a moved Joker also creates a Fish; the fork re-offers a
  fresh copy from the definition where PC moves the actual card, so
  a moved Joker's scaled stats do not ride along), Junk Mail (an
  extra shop voucher at 1.5x price), Letter B (a $7 Buffoon Pack),
  Shopping Spree (15 rerolls make rerolls $2 cheaper; 4 skipped
  Blinds add a shop slot), Gem Alert (X0.1 Mult per editioned or
  Rare shop Joker seen, and while held Rare Jokers are 6.7x as
  likely in the shop), Bonus Sheet (Buffoon Packs gain an appended
  oldfluff or Letter Joker) and Repack (two Modded Packs shelved per
  round; a Modded Pack deals mod Jokers and mod consumables card by
  card).
- 12 of the Slivers: Sinew, Muscle, Might, Megantic, Plasma, Astral,
  Fury, Mindlash, Quantum, Gemhide, Fortunate and Sliver Jockey.
  Each grants its listed effect to every Sliver the player holds,
  itself included, through a pack-side runner that mirrors PC's
  granted-abilities pass. What is NOT ported is each Sliver's own
  second effect, PC's modify_weights pool pass (odds of other
  effects firing), a context this engine never raises: Slivers
  here appear at normal rarity rates instead. Three Slivers stay
  blocked: The First Sliver (its grant is the Cascade system, a
  shop-buying machine), Virulent Sliver (its grant pays off the
  raw hand score, a value this engine's scoring returns do not
  expose) and Homing Sliver (it has no granted effect at all; its
  whole effect is the modify_weights pass).
- The Colour system: Colour cards are investments. Each starts at
  val 0 and gains +1 val per upgrade period held (2-5 rounds,
  card-dependent; Paint Can can add extra rounds), then pays its
  effect val times when used. 14 of the 17 Colour cards are ported
  (Deep Blue, Red, Orange, Black, Seaweed, Brown, Crimson, Grey,
  Silver, White, Blue, Lilac, Green, Pink) plus four Colour packs
  and the six Colour Jokers: Paint Can, Rainbow Joker (X1.5 Mult
  per Colour card held, folded into its own scoring return), Clipart
  Joker, CSS, Monochrome Joker and Loaded Disk. Deviations: Pink's
  random target pool cannot include the Pink being used (this
  engine removes a consumable before its use runs; PC runs the use
  first), and Loaded Disk creates the Pink only, because Yellow is
  not ported. Yellow stays blocked: its only effect is sell-value
  growth, and this engine sells every consumable for a flat $1 with
  no per-card value. Peach stays blocked (it creates Rotarot cards,
  a type not ported) and Gold stays blocked (a hidden card that
  enters only through a Colour pack's rare poll, which the engine's
  pools do not run for a custom kind). The Colour Tag and the Paint
  Roller / Colour Theory vouchers are not part of this wave.

v1.3.0 (Wave 1 top-up) adds 5 Jokers unblocked by the fork's Wave 1
polls (SMODS.poll_enhancement / SMODS.poll_seal) and the xlog_chips
return reader: Ace Up The Sleeve, Balatro Mods (Working 2024) and
Glitter Bomb (poll_enhancement), Seal the Deal (poll_seal) and
Freaky Pizza (xlog_chips; its end-of-round scale_card growth is done
with plain ability.extra arithmetic, which is all scale_card's
scalar add does). The polls deal from the vanilla enhancements and
seals plus any registered center with a positive weight; this pack's
five custom enhancements stay at weight 0, exactly as in v1.2.0, so
they never come out of these polls. Note: PC's Seaweed Colour card
polls with key = "mf_seaweed" for a fixed "seaweed" enhancement, but
MoreFluff registers no such enhancement on PC either (Seaweed there
is a Colour consumable, a system this pack does not port), and no
ported item needs it, so no seaweed enhancement is registered here.

v1.2.0 (Tier 3 top-up) adds 14 Jokers unblocked by the fork's Tier 3
systems: Unpleasant Card, Blahaj, Wide Joker, Letter E and Jankman
(the x_chips / swap / e_mult return readers), Teacup and Flint and
Steel (the level_up return reader), Rose-Tinted Glasses (the
destroying_card beat, taken in the after pass), Teal Joker, Marigold,
Brass Joker, Gemstone Joker and Yucky Rat (SMODS.Enhancement
registrations for the Teal / Marigold / Brass / Gemstone / Yucky
cards), and All I Can't Do (SMODS.set_debuff). The five custom
enhancements are registered at weight 0: on PC they are delivered by
the Rotarot consumables, which are not ported, so they stay out of
the random-enhancement polls and reach cards only through direct
creation (SMODS.add_card / mod_conv).

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
- Unpleasant Card: the X2.067 Chips port; PC's second clause
  (Booster Packs contain only 1 card) is a Lovely patch on pack
  creation (G.GAME.pack_choices) and is dropped.
- Teacup and Flint and Steel: PC levels the hand with
  level_up_hand / upgrade_poker_hands in the before pass; the port
  returns level_up at joker_main, where the fork's reader levels the
  scored hand and adds the level delta to the running totals (same
  final numbers). Teacup's spent cup is destroyed in the after pass
  instead of by a queued event, so its last charge still levels.
- Jankman: PC's context.other_joker is folded into the fork's
  post_trigger pass (the Baseball Stream / Simplified pattern), so
  it pays when a modded Joker actually triggers on the hand.
- Rose-Tinted Glasses: PC hooks Steamodded's destroying_card check;
  the port destroys the 2 in the after pass (the Sixth Sense slot),
  so the 2 still scores first, as on PC.
- Brass Joker and Yucky Rat: a Brass / Yucky Card's own scored
  retrigger and destroy-after-scoring roll are enhancement effects
  the fork never asks a center for (only seals get a retrigger
  query), so the two Jokers mediate those effects in their
  repetition / after passes while held.
- Gemstone Card: the fork has no no-rank / no-suit / always-scores
  enhancement flags, so Gemstone Cards keep their rank and suit
  here; the $3 held-at-round-end payout (PC's p_dollars) is kept.
- All I Can't Do: PC's debuff is source-keyed and lifts when the
  Joker leaves; the fork's SMODS.set_debuff writes the persistent
  perma_debuff, so debuffed cards stay debuffed if it is sold.
- Teal Joker and Gemstone Joker: PC keeps their tallies in an
  update() tick; the port counts the full deck live (the Coupon
  Catalogue pattern), same numbers.
- Bowling Ball, Pixel Joker and Jack of all Trades keep their
  v1.0.0 port keys (bowling_ball, pixel_joker, jack_of_all_trades)
  so old saves keep working. Pixel Joker's art is a single solid
  pixel on PC, stretched over the card by the game; same here.
- Freaky Pizza: PC's xlog_chips branch reads card.ability.freakiness,
  a field that is never set on PC (the value lives in
  ability.extra.freakiness, which PC's own fallback path and its
  tooltip both use). The port returns extra.freakiness, the
  effective PC behaviour.
- Ace Up The Sleeve, Balatro Mods (Working 2024) and Glitter Bomb:
  PC's per-card flip and juice event queues are dropped (cosmetic);
  the enhancements land immediately. Balatro Mods' first_hand_drawn
  highlight (juice_card_until) is likewise dropped. Ace Up The
  Sleeve rolls its Ace's suit itself, since the fork's add_card
  needs one named (PC's add_card picks it internally).

Validation: 86 pack tests (registration and tooltips for all 133,
behaviour tests for the non-trivial effects, including the Tier 3
return readers, the level_up ports, the enhancement registrations,
the debuff port, the Wave 1 poll / xlog_chips ports and the Wave 6
shop, Sliver and Colour ports) plus the fork's own mod suite, all
passing on the fork build (2026-10-25).

Credit: MoreFluff is by notmario (github.com/notmario/MoreFluff).
The PC repo carries no license file; this is an unofficial fan port
and will be taken down if the author asks.
