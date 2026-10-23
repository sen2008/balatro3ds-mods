Cryptid Pack (3DS Port) v1.3.0
172 Jokers and 28 consumables from Cryptid (PC, by the Cryptid team),
ported to Balatro3DS: the Epic, Exotic, Candy and Cursed rarities,
the Bulwark and UltPair poker hands, and the Code and Unique
consumable types. v1.2.0 adds the Tier 3 wave: the big-number
(e_mult / e_chips) Jokers, the x_chips class, Sync Catalyst,
the destruction Jokers, the tag Jokers, five consumables, and
registered Green/Azure seals, Astral/Mosaic/M editions and
Cat/Double M/Rework tags. v1.3.0 adds the Wave 1 wave:
://ALTTAB, Kidnapping, Necromancer, Pumpkin, Carved Pumpkin
and Familiar Currency.

REQUIRES THE BALATRO3DS FORK (v1.2.0)
The pack registers custom rarities, poker hands and consumable
types and creates and destroys Jokers and cards, which the stock
game's mod API cannot do. It needs the fork build and its Tier 1 +
Tier 2 + Tier 3 mod APIs (SMODS.add_card / SMODS.destroy_joker /
SMODS.destroy_card, SMODS.Rarity, SMODS.PokerHand,
SMODS.ConsumableType, SMODS.Seal / SMODS.Edition / SMODS.Tag),
and for the v1.3.0 items its Wave 1 systems (G.jokers_sold, the
game_over context, joker_type_destroyed):
  https://github.com/sen2008/balatro3ds-fork
On the stock Universal-Updater build the pack does not load.
The test file (test_cryptidpack.lua) stays in the mod folder; the
game ignores it.

INSTALL
1. Unzip this file.
2. Copy the CryptidPack folder to your SD card at:
     /3ds/save/Balatro3DS/sdmc/mods/CryptidPack
3. Start (or restart) Balatro3DS.
4. Check Options -> Mods: "Cryptid Pack" should be listed.
   If a mod fails to load, the reason is written to mods/mods_log.txt
   in the same folder.

WHAT'S INSIDE
- Rarities: Epic (shop weight 0.3, as on PC), Exotic (weight 0:
  never sold in the shop, exactly as on PC; Exotics arrive through
  Gateway and other creation effects), Candy (weight 3),
  Cursed (weight 3).
- Poker hands: Bulwark (five Stone cards, 100 Chips / 10 Mult,
  +50/+1 per level) and UltPair (two or more pairs in each of two
  suits, 220 Chips / 22 Mult, +40/+4 per level). Like every custom
  hand on the fork they rank below High Card in hand contests,
  because the fork's evaluator names hands by list position.
- Consumable types: Code (shop rate 1; PC rates Code at 0 because
  PC has Code booster packs, which the fork does not, so the shop
  is the only way the four ported Code cards can appear) and
  Unique (shop rate 0, as on PC).
- Seals, editions, tags: Green and Azure Seals, the Astral,
  Mosaic and M (Jolly) editions, and the Cat, Double M and Rework
  tags are registered. The M edition is fully live (+8 Mult);
  Astral, Mosaic, Green and Azure are markers other effects
  produce and read (see DEVIATIONS).
- Cryptid's gameset system (Modest / Mainline / Madness difficulty
  overrides) is not ported; every effect uses its standard rules.

THE 172 JOKERS, BY RARITY
Common (49): 2D, :D, Absurd Joker, Adroit Joker, Big Cube, Blender, Blurred Joker, Bonkers Joker, Bubble M, Clicked Cookie, Crypto Coin, Cube, Cursor, Delirious Joker, Discreet Joker, Dubious Joker, Exoplanet, Fast Food M, Fidget Spinner, Foolhardy Joker, Foxy Joker, Fridge Magnet, Jolly Joker?, Kidnapping, Kooky Joker, Loopy, M Chain, Macabre Joker, Manic Joker, Megg, Meteor Shower, Monster, Morse Code, Nutty Joker, Panopticon, Pity Prize, Queen's Gambit, Red Bloon, Sacrifice, Savvy Joker, Shrewd Joker, Silly Joker, Stardust, Subtle Joker, Translucent Joker, Treacherous Joker, Triplet Rhythm, Tricksy Joker, Wacky Joker
Uncommon (33): AP Joker, Astral in a Bottle, Bonk, Bus Driver, Candy Basket, Candy Dagger, Chili Pepper, Consume-able, Cut, Eye of Hagane, Fading Joker, Happy House, Hunting Season, Key Change, Kitty Printer, Krusty the Clown, Mondrian, Monkey Dagger, Necromancer, Neon M, Pickle, Pirate Dagger, Poor Joker, Python, Reverse Card, Sapling, Scrabble Tile, Seal the Deal, The WHIP, Trick-or-Treat, Unjust Dagger, Wheel of Hope, Zooble
Rare (41): ...Like Antennas to Heaven, Arsonist, Broken Home, Carved Pumpkin, Celestial Globe, Chad, Compound Interest, Dropshot, Eternal Flame, Exposed, Familiar Currency, Garden of Forking Paths, High Five, Jimball, Kaleidoscope, LeBaron James, Light Up the Night, M Stack, Mask, Motebook, Nice, Night, No Sound, No Memory, Pizza, Pizza Slice, Pot of Jokes, Pumpkin, SUS, Tax Fraud, The Clash, The Duos, The Filler, The Home, The Nuts, The Quintet, The Stronghold, The Swarm, The Unity, Universe, Weebonacci, Yarn Ball
Legendary (4): Nostalgic Invisible Joker, Thalia and Melpomeme, Waluigi, Wario
Epic (23): Boredom, Canvas, Caramel, Circus, Code Joker, Copy/Paste, Demicolon, Doodle M, Gold Joker, Googol Play Card, Huge, Jimbo-tron 9000, M, Mult Joker, Negative Joker, One for All, Sob, Starfruit, Supercell, Sync Catalyst, Tiny, Virgo, m
Exotic (14): Circulus Pistoris, Crustulum, Duplicare, Energia, Facile, Formidiulosus, Iterum, Non Verisimile, Primus, Redeo, Speculo, Stella Mortis, Tenebris, Tredecim
Candy (6): Brittle Candy, Candy Buttons, Candy Cane, Cotton Candy, Mellowcreme, Wrapped Candy
Cursed (2): Monopoly Money, Rotten Egg

THE 28 CONSUMABLES
://ALTTAB (Code), ://COMMIT (Code), ://CTRL+V (Code), ://REWORK (Code), Adversary (Spectral), Analog (Spectral), Asteroid Belt (Planet), Chambered (Spectral), Conduit (Spectral), Gateway (Spectral), Hertta (Planet), Kaikki (Planet), Lock (Spectral), Neutron Star (Planet), Pata (Planet), Phobos & Deimos (Planet), Planet.lua (Planet), Replica (Spectral), Risti (Planet), Ritual (Spectral), Ruutu (Planet), Source (Spectral), Summoning (Spectral), The Automaton (Tarot), The Blessing (Tarot), Typhoon (Spectral), Vacuum (Spectral), White Hole (Spectral)

DEVIATIONS FROM PC
- Cube costs $0 instead of -$27: PC's joke price pays you to take
  it, but the fork requires cost >= 0, so it is free here.
- Wee Fib's art is the vanilla Fibonacci sprite: PC gives it no
  atlas of its own (the joke is that it is a tiny Fibonacci), and
  its PC display size of 0.7 has no fork equivalent.
- Virgo's floating soul layer uses the glyph cell of its atlas:
  PC's soul_pos points outside the atlas grid, so on PC that
  layer renders nothing there either.
- Kitty Printer's Cat Tag conversion happens when the Blind is
  skipped rather than when the tag is rolled: PC rewrites the
  rolled tag before it can fire, the fork raises tag_added
  before the tag is held, so the port converts the newest held
  tag at skip time. A rolled tag whose effect is immediate
  keeps that effect instead of becoming a Cat Tag.
- Adversary drops its shop-price doubling (the fork has no
  shop-price modifier API), so the port is strictly stronger
  than PC's version.
- ://CTRL+V copies playing cards only; PC's consumable and
  booster-pack target branches have no fork equivalent.
- Conduit swaps editions between two playing cards, or between
  one playing card and one Joker; swapping two Jokers is not
  possible (a consumable gets a single Joker target).
- Kaikki levels Bulwark and UltPair only; PC's third hand,
  Clusterfuck, cannot be registered.
- Morse Code grows on editioned Joker sales only (the fork's
  selling context covers Jokers, not consumables).
- Clicked Cookie keeps its Chips; the per-click decay needs
  Cryptid's cry_press context.
- LeBaron James keeps its dynamic hand size; the held-in-hand
  scoring half needs an SMODS.score_card hook.
- Monopoly Money destroys bought Jokers and consumables;
  voucher and booster purchases cannot be matched to an offer.
- Code Joker drops PC's unlock gate (discover every Code card).
- The M-edition creations (Jolly Joker?, Scrabble Tile) still
  create plain Jokers; the M edition itself is registered now
  (the Double M Tag stamps it), but those two creation effects
  were not rewired to stamp it.
- Circulus Pistoris costs $31: PC's price is 10*pi dollars and
  the fork's costs are whole dollars.
- Googol Play Card drops PC's unlock gate (score 1e100 Chips
  in one hand), like Code Joker's gate.
- The Astral and Mosaic editions are markers: Ritual, Astral
  in a Bottle and the Rework ladder produce them and Universe
  reads Astral, but their own effects (^1.1 Mult, X2.5 Chips)
  do not apply — edition config has no ^Mult or XChips field.
- The Green and Azure Seals are markers: Source, Typhoon and
  Seal the Deal apply them, but their own effects do not fire —
  Green needs a played-and-unscored moment and Azure a
  destroyed-in-play moment, and fork seals have neither.
- The Double M Tag does not make its Joker free: PC coupons
  the rewritten Joker to $0, but the fork prices a shop offer
  after the create moment, so the M Joker costs its normal
  price.
- ://COMMIT skips PC's rarity guard: on PC the guard compares
  a number to string rarity keys and so never actually refuses
  a custom rarity; here it would refuse exactly those.
- ://REWORK refuses only the Meteor: PC's name check is a Lua
  bug that compares against only its first operand
  ("cry-meteor"), so that is the only refusal that ever fires
  on PC either.
- Astral in a Bottle uses PC's base-gameset behaviour (one
  Joker gets both Astral and Perishable); the gameset variant
  that splits them across two Jokers is dropped with the
  gamesets.
- Arsonist, Queen's Gambit and Hunting Season destroy their
  cards after scoring resolves instead of through PC's
  destroying_card gate (the fork's gate is veto-only and
  carries no hand).
- Energia guards its own duplication with a busy flag instead
  of PC's per-tag flag: the fork raises tag_added from inside
  addTag, before a copy exists that could be flagged.
- One for All drops its booster-slot, shop-size and voucher-slot
  increases; the fork has no config fields for them.
- Demicolon's forcetrigger is expressed through the fork's
  retrigger_joker return on its right neighbour in joker_main.
- Canvas drops the gameset modest cap (no gamesets, see above).
- Kidnapping and Necromancer read the fork's G.jokers_sold,
  which records every sale; PC's history holds each Joker once,
  so both port readers count distinct sold keys, and Necromancer
  excludes its own key (PC never records it). One PC entry has
  no equivalent: a sold Joker carrying the M edition also
  entered PC's history as a Jolly Joker; the fork records only
  the sold Joker itself, so that entry is lost. Kidnapping's
  Type test follows PC's predicate (centre effect "Type Mult" /
  "Cry Type Mult" / "Cry Type Chips" / "Boost Kidnapping", or
  one of the five vanilla Type Chips names); the fork carries
  the effect on vanilla defs but not on mod defs, so the pack's
  own Cry Type Jokers are matched from an explicit list taken
  from their PC defs.
- Necromancer's created Joker has $0 sell value, as on PC; the
  port writes sell_cost = 0 where PC sets its cry_no_sell_value
  flag.
- Pumpkin is not spent by its save (neither is PC's): it stays
  held and can save again on a later lost Blind.
- Carved Pumpkin attempts its Boss disable at setting_blind
  and again when the first hand is drawn, because the fork's
  disable only lands once the Blind is live; the disable call
  itself is a no-op once the Boss is disabled, so the second
  attempt never double-fires.
- Familiar Currency rolls the Meme pool that exists in the
  pack now: 16 of PC's 17 Meme-flagged Jokers (only Cat Owl is
  unported). Its $19 is charged only when a Joker was actually
  created, so a full Joker tray is never charged; PC checks
  room before charging, the same net result. PC's bankrupt_at
  challenge floor has no fork equivalent and is 0 in a normal
  run, so the port checks money directly.

NOT PORTED: OTHER MISSING SYSTEMS (101)
- ://ASSEMBLE: Adds base Mult to the hand formed by the highlighted cards via SMODS.upgrade_poker_hands with a custom function (+1 per owned Joker). The fork has no upgrade_poker_hands, and cannot identify the poker hand of an arbitrary highlighted subset (PC uses G.FUNCS.get_poker_hand_info and G.GAME.hands, incl. the cry_None hand).
- ://CLASS: Chosen-enhancement conversion runs through Cryptid's overlay menu plus init hooks on Card:click and CardArea:emplace, and the choice list includes custom enhancements m_cry_echo, m_cry_light and m_cry_abstract. No menu or method-hook API in the fork (mod_conv only covers one fixed vanilla enhancement).
- ://CRASH: Effect is to crash or freeze the game: use() runs a random crashes[] function that overrides love.errorhandler/love.draw, fills the screen with Crash cards, or opens a text box whose contents are run via loadstring(G.ENTERED_ACE) (arbitrary code execution). No fork equivalent; deliberately destructive.
- ://DECLARE: Creates a brand-new poker hand at runtime from the highlighted cards with a player-typed name (text-input UIBox, Cryptid.create_declare_hand mutating G.GAME.hands, plus localize and SMODS.is_poker_hand_visible hooks). Fork poker hands register only at load and there is no text-input UI.
- ://DELETE: Banish system: writes G.GAME.cry_banished_keys and G.GAME.cry_banned_pcards so the selected shop item (and rank+suit, for playing cards) never appears again this run. No banish/pool-exclusion state in the fork, and its targets are highlighted shop items, which the fork cannot select.
- ://DIVIDE: Halves current shop prices by writing misprint_cost_fac on every card in G.shop_jokers, G.shop_booster and G.shop_vouchers and calling set_cost(). The fork exposes no shop areas or price-modification API.
- ://EXPLOIT: Opens Cryptid's exploit overlay menu (G.FUNCS.overlay_menu / G.UIDEF.exploit_menu) to make the next hand calculate as a chosen visible hand and grant temporary Ascension Power (cry_asc_num, G.GAME.sunnumber). No menu/UI API and no ascension system in the fork.
- ://GLOBAL: Applies Cryptid's cry_global sticker to a selected playing card (the card counts as all suits/ranks via Cryptid hooks). Custom stickers do not exist in the fork.
- ://INSTANTIATE: Draws specific existing deck cards (first matching the selected card's rank, then first matching its suit) into hand via draw_card(G.deck, G.hand, ...). The fork exposes deck contents only as raw card_data and has no move-card-from-deck-to-hand API.
- ://KEYGEN: Creates and redeems a random Voucher (create_card('Voucher') + card:redeem(), perishable/banana/keygen stickers) and dissolves previously keygen-created vouchers, preserving G.GAME.current_round.voucher. Creating/redeeming a voucher as an effect is blocked and there is no G.GAME.
- ://LOG: Whole effect is a custom UIBox readout menu predicting future RNG: next Boss/Voucher via an init hook on SMODS.get_next_vouchers and saved G.GAME.pseudorandom state, the next 5 shop Jokers, or the top 10 deck cards. No UIBox or RNG-state API in the fork.
- ://MACHINECODE: Creates a random consumable that must carry the cry_glitched edition; Glitched's effect is randomizing the card's values (X0.1 to X10) when applied, via Cryptid.manipulate — fork editions have no on-apply effect and there is no value manipulation, so a Glitched label here would be inert and fake
- ://MALWARE: Sets the Cryptid glitched edition on every card held in hand; the edition write itself works, but Glitched's on-apply value randomization needs Cryptid.manipulate, which the fork has no equivalent for (see ://MACHINECODE)
- ://MERGE: Merges a consumable into a playing card: CARD:set_ability(G.P_CENTERS[<consumable key>]) inside temporary CardAreas (the CCD system), turning the playing card into that consumable's centre. Playing cards cannot change centre/set in the fork, and there is no event manager.
- ://MULTIPLY: Doubles all values of a selected Joker via Cryptid.manipulate (Cryptid's generic value-manipulation library) and restores them through an init hook on end_round. No value-manipulation API and no method hooks in the fork; also needs highlighted-Joker targeting.
- ://NPERROR: Returns the last played hand to hand by matching Cryptid-tracked G.GAME.last_hand_played_cards sort_ids in discard/deck and moving them with draw_card(). No last-hand tracking and no move-card-to-hand API in the fork.
- ://OFFBYONE: Effect is Cryptid booster state G.GAME.cry_oboe: the next Booster Pack gets +# extra cards and +# extra choices. The fork can register booster types but cannot modify a rolled pack's size or choices, and there is no G.GAME.
- ://PATCH: Core lasting effect is permanent debuff immunity via the Cryptid flag cry_debuff_immune; the fork's debuff_card context is an after-the-fact notification on canonical-setter applications only (Boss debuffs are predicates and never raise it), so there is no prevention hook to hang immunity on
- ://PAYLOAD: Effect is Cryptid library state G.GAME.cry_payload: a multiplier on the next defeated Blind's interest payout, maintained and paid out by Cryptid hooks. No G.GAME and no interest system in the fork.
- ://QUANTIFY: Transfers a selected card or Booster into the Joker tray as a functioning Joker via init hooks overriding Card:calculate_joker and Blind:debuff_hand, using SMODS.calculate_individual_effect / SMODS.calculate_effect. None of those exist in the fork, and it targets cards in any area (G.I.CARD scan).
- ://REBOOT: Round-state reset: G.FUNCS.draw_from_hand_to_discard / draw_from_discard_to_deck, ease_discard and ease_hands_played computed from G.GAME.round_resets and G.GAME.current_round, then a deck shuffle and G.STATE change via the event manager. No round-state manipulation API in the fork.
- ://REVERT: Rewinds the run to the start of the Ante: an init hook overrides save_run to snapshot state with STR_PACK into G.GAME.cry_revert, and use() calls G:delete_run() / G:start_run({savetext}). No save-state or run-restart API in the fork.
- ://RUN: Visits a shop mid-Blind: stashes the hand in a temporary CardArea, forces G.STATE = G.STATES.SHOP, and restores via init hooks on G.FUNCS.toggle_shop, Game:update_shop and G.UIDEF.shop. No game-state, CardArea or shop-forcing API in the fork.
- ://SEED: Applies Cryptid's cry_rigged sticker to a selected Joker, playing card or consumable so all of its probability rolls succeed (Cryptid probability hooks read ability.cry_rigged). Custom stickers do not exist in the fork.
- ://SPAGHETTI: Creates a random Food-pool Joker with the cry_glitched edition; the Food pool is enumerable now, but the Glitched half is not portable (see ://MACHINECODE)
- ://UPDATE: Placeholder with no effect in the PC source: can_use always returns false and use/bulk_use are commented out ('To Be Determined in a future update'). There is nothing to port.
- ://VARIABLE: Chosen-rank conversion runs through Cryptid's overlay menu plus init hooks on Card:click and CardArea:emplace calling SMODS.change_base. The fork raises no change_rank/change_suit and has no menu or method-hook API.
- ;//: Ends the current non-Boss Blind without cashing out by setting G.GAME.current_round.semicolon and forcing G.STATE = G.STATES.HAND_PLAYED with end_round() via the event manager. No blind-ending or game-state API in the fork.
- ABC: debug/test item in PC source, not player content
- Ace Aequilibrium: creates Jokers in Collection order using the shared G.GAME.aequilibriumkey sequence over the whole Joker pool; fork has no collection-ordered pool API and no G.GAME (random creation would change the effect)
- Allmighty Center Checker: debug/test item in PC source, not player content
- The Complete and Utter Annihilation of Everything That Makes Balatro Sacred: returns emult = 5.2 (Mult ^ 5.2) gated on the cry_WholeDeck hand; WholeDeck needs the entire deck in one play, and the fork caps card selection at 5 with no play-limit API, so the hand can never be formed and its in_pool can never open
- Blacklist: sets the hand's Chips and Mult totals to 0 by writing the hand_chips/mult globals; fork calculate returns only add/multiply and cannot override the running totals
- Bonus Joker: permanently increases Joker/Consumable area size via G.jokers:change_size and G.consumeables:change_size - fork slot modifiers are static and only apply while held; no permanent-change API
- Booster Joker: Effect is SMODS.change_booster_limit in add/remove_from_deck (+1 Booster Pack shop slot) — the fork has no booster-slot modifier or equivalent
- Broken Sync Catalyst: Returns cry_broken_swap (swap 10% of Chips with 10% of Mult mid-scoring), a Cryptid scoring hook with no fork return or context equivalent
- Buttercup: requires a custom cry_storage CardArea with drag UI for stashing shop items plus G.GAME.next_shop_cards shop injection; neither exists in the fork
- Caeruleum: works entirely through an init hook on SMODS.calculate_individual_effect that promotes adjacent Jokers' chip operators (+ to X to ^); the fork has no effect-application hook to promote another Joker's returns through
- Candy Sticks: requires disabling the Boss Blind and restoring it later from a saved blind (blind:disable()/blind:save()/blind:load()); the fork can disable a Boss Blind now, but has no blind save/load API to restore it with
- Cat Owl: Requires the check_enhancement context, which the fork still does not raise, and the m_cry_echo enhancement, which cannot be ported (see The Eclipse)
- Chocolate Die: requires SMODS.Events ev_cry_choco0..10 (Cryptid event system); those events apply the cry_flickering sticker and other global hooks - no event or sticker system in the fork
- Clockwork Joker: requires setting a played card's enhancement to m_steel mid-hand (context.full_hand[1]:set_ability) and copy_card self-duplication when its four counters align - neither API exists in the fork
- Digital Hallucinations: The fork's open_booster context carries no booster card or pack type (the event is emitted with an empty table), so the pack-type-dependent Negative creation cannot be implemented
- Double Scale: whole effect is context.scaling_card plus override_scalar_value (interception of SMODS.scale_card) - that context is not raised and the fork has no scale-card system
- ERROR: on sell it duplicates every other held Joker via copy_card (exact copies incl. ability state) using G.jokers.cards, and its tooltip needs Cryptid.predict_card_for_shop - no fork copy API or G.jokers.cards
- Effarcire: draws the whole deck to hand via SMODS.draw_cards queued through G.E_MANAGER with G.GAME.effarcire_buffer state; fork has no draw-to-hand API, no event manager and no G.GAME
- Emergency Chips: On-sell effect writes the current hand score (G.GAME.chips) and forces G.STATE to HAND_PLAYED; the fork exposes no current-score access or game-state control (no G.GAME)
- Exponentia: gains ^0.03 Mult whenever an XMult effect is triggered anywhere; the gain hooks SMODS.calculate_individual_effect on PC, and the fork has no effect-application hook — its retrigger and post_trigger passes carry no effect payload or amount to count
- FUNCTION://: Depends on Cryptid program state G.GAME.cry_function_cards / cry_last_used_consumeables (the last three consumables used, tracked by Cryptid hooks) and applies the cry_function sticker to the created copy. Neither the tracking state nor custom stickers exist in the fork.
- Flesh Panopticon: multiplies the Boss Blind target via G.GAME.blind.chips at setting_blind - no G.GAME and no blind-target modification API in the fork
- Fractal Fingers: Effect is +2 card selection limit via SMODS.change_play_limit/change_discard_limit; the fork has no play/discard selection-limit modifier (h_size is hand size, not selection limit)
- Fucked-Up Joker: effect requires the cry_Clusterfuck poker hand (8+ played cards forming no pair/flush/straight); the fork evaluates hands on a normal play and Clusterfuck is not registerable
- Gemini: doubles all values of the leftmost Joker via Cryptid.manipulate, Cryptid's value-manipulation library; fork has no API to rewrite another Joker's ability values
- Ghost: possession is the cry_possessed sticker plus a Cryptid calculate hook that inverts the possessed Joker's effects; stickers and effect-inversion hooks do not exist in the fork
- HOOK://: Applies Cryptid's cry_hooked sticker linking 2 selected Jokers so each force-triggers the other (force-trigger/demicolon system), installed via an init hook overriding Card:start_dissolve. No stickers, no force-trigger context and no method hooks in the fork; also needs highlighted-Joker targeting.
- Hammerspace: Requires Cryptid's CCD system: Cryptid.random_consumable(..., true) returns a consumable-as-enhancement center that is applied to playing cards as their ability; the fork has no consumable-as-enhancement (CCD) mechanic
- Instability: mod_conv to the custom Abstract enhancement (m_cry_abstract); Abstract's e_mult return is readable now, but the card must also read its own rank and suit, replace the base card underneath it, and roll its destroy chance, none of which the fork supports for enhancements
- Jawbreaker: requires Cryptid.manipulate (misprintize) to double every numeric value of the adjacent Jokers; fork Jokers do not expose their values in a writable per-copy table (vanilla effects are hardcoded)
- Labyrinth: No calculate/config: effect lives in lib/overrides.lua hooks on G.FUNCS.play_cards_from_highlighted/discard_cards_from_highlighted that zero G.GAME.current_round.hands_played/discards_used — the fork exposes no hook to reset its round counters
- Lucky Joker: PC fires on other_card.lucky_trigger during individual scoring; the fork never exposes lucky_trigger to mod calculate (its lucky rolls surface only as probability_success, which reads repetitions and cannot pay dollars)
- Many Have Lost Their Minds Comprehending This Joker: effect requires the cry_WholeDeck poker hand (the entire deck in one play); the fork caps card selection at 5 with no play-limit API, so the hand can never be formed and the hand is not registered
- Maximized: No calculate at all: effect is an init hook overriding Card:get_id (all faces=Kings, numbered=10s) plus a G.UIDEF.view_deck override — Lovely/global-hook territory, no fork equivalent
- Meld: Applies the Cryptid Double-Sided edition (e_cry_double_sided); Double-Sided is a flip/merge card system with other-side state, not an edition effect the fork's edition config can express, and it also requires selecting a Joker
- Membership Card: Requires Cryptid.member_count (live Cryptid Discord member count fetched over HTTPS by the Cryptid library); no such data source exists in the fork
- Nebulous Joker: effect requires the cry_None poker hand (a hand containing 0 cards); a 0-card play cannot be made or scored in the fork and None is not a registerable hand
- Nibiru: Levels cry_None, Cryptid's no-hand-played pseudo-hand; the fork has no equivalent hand to register or level (its stats are derived from bignum hand state)
- Nostalgic Candy: selling it permanently gains hand size via G.hand:change_size - fork h_size modifiers only apply while a Joker is held; no permanent hand-size API
- Nostalgic Googol Play Card: sell effect creates 2 copies of the leftmost Joker via copy_card (exact duplicate incl. ability state and edition) - the fork has no copy API; SMODS.add_card only creates fresh instances
- Number Blocks: its target rank is G.GAME.current_round.cry_nb_card, state chosen by a Cryptid override tied to The Castle - no G.GAME and no such round state in the fork
- Oil Lamp: Requires Cryptid.manipulate (library value-multiplication of the Joker to the right); no fork equivalent
- Old Blueprint: core effect is SMODS.blueprint_effect (copies the Joker to the right), which has no fork equivalent; its calculate and loc_vars also read G.jokers.cards
- Old Membership Card: effect scales with Cryptid.member_count, the live Cryptid Discord member count fetched over HTTPS - Cryptid library state with no fork equivalent
- On the Flip Side: Requires the cry_double_sided edition on other Jokers; Double-Sided is a flip/merge card system with other-side state (see Meld), not a registrable edition effect
- POINTER://: Opens Cryptid's collection overlay to create an arbitrary chosen card (G.GAME.USING_POINTER state, overlay_menu UI, a Card:click hook, pointer_create_card); the fork has no overlay-menu or click-hook API for mods
- Paved Joker: Effect lives entirely in poker-hand evaluation (Stone cards fill gaps of 1 in Straights and Flushes) via evaluate_poker_hand hooks; the Joker has no calculate and the fork does not raise evaluate_poker_hand
- Penetrating Joker: effect requires the cry_Clusterfuck poker hand (8+ played cards forming no pair/flush/straight); the fork evaluates hands on a normal play and Clusterfuck is not registerable
- Perkele: Levels cry_None and cry_WholeDeck (hands that cannot be formed or do not exist in the fork) plus cry_asc_hands via Cryptid's Ascension system; its WholeDeck Observatory branch also returns emult
- Potion: Its entire use() is gated on Cryptid's Chocolate Die event state (G.GAME.events.ev_cry_choco3) and applies that event's maluses; the event system does not exist in the fork, nothing can grant the card (in_pool is false on PC), and its set (Unique) is not the blocker
- Project Sundial: its payoff is Cryptid's global xblindsize hook (blind size reduced 85% for the rest of the run, lib/calculate.lua) driven by G.GAME.sundial state - no G.GAME and no blind-size API in the fork
- RNJoker: abilities are generated and interpreted by Cryptid.rnjoker_randomize / its calculate interpreter, which uses G.GAME.joker_buffer and consumeable_buffer, G.jokers.cards, the other_joker and debuffed_hand contexts, and x_chips/payout returns - no fork equivalent
- Rescribere: monkey-patches every other held Joker's calculate_joker function to append a sold Joker's effects; fork Jokers carry no per-instance calculate_joker to patch
- Scalae: sole effect is in the Cryptid-specific scaling_card context, rewriting other Jokers' scaling increments as degree-N polynomials through SMODS.scale_card internals; fork never raises scaling_card and exposes no scaling hook
- Sock and Sock: retriggers played Echo cards (m_cry_echo); no ported card can ever carry Echo (see The Eclipse), so there is never anything to retrigger
- Sol: Requires Cryptid's Ascension system (Cryptid.asc_level_up, G.GAME.sunlevel/sunnumber, cry_asc_num ascension power, gated on G.GAME.cry_asc_played); no ascension state or ascended hands exist in the fork
- Spectrogram: counts scored Echo cards (the m_cry_echo enhancement); Echo detection would work, but no ported card can ever carry Echo (see The Eclipse), so the count would be permanently zero
- Spy: disguise requires update()/generate_ui hooks that swap sprite, rarity and cost to a random secret Joker and spoof its description, plus the perishable sticker; no fork equivalent
- Test Joker: debug/test item in PC source, not player content
- The: effect requires the cry_None poker hand (a hand containing 0 cards); a 0-card play cannot be made or scored in the fork and None is not a registerable hand
- The Eclipse: mod_conv to the custom Echo enhancement (m_cry_echo); Echo's whole effect is retriggering its card, and fork enhancements have no retrigger channel (only seals get retrigger counts), so the enhancement cannot be registered honestly and mod_conv would hand out a dead card
- The Fuck!?: effect requires the cry_Clusterfuck poker hand (8+ played cards forming no pair/flush/straight); the fork evaluates hands on a normal play and Clusterfuck is not registerable
- The Seraph: mod_conv to the custom Light enhancement (m_cry_light); Light keeps a per-card counter and reads the scoring hand's size when it scores, and fork enhancement contexts carry neither per-card persistent state nor the scoring hand
- The Universe In Its Fucking Entirety: Levels cry_WholeDeck, which can never be formed in the fork (whole deck in one play; selection caps at 5, no play-limit API); its Observatory calculate also returns emult gated on that hand
- Trade: Requires un-redeeming an owned voucher and redeeming two new ones; the fork has no voucher unredeem/redeem API for mods (owned vouchers are only the G.vouchers id list, redeem() runs at purchase only)
- Tropical Smoothie: Requires Cryptid.manipulate (library value-multiplication of every other Joker's ability values); no fork equivalent
- Undefined Joker: effect requires the cry_None poker hand (a hand containing 0 cards); a 0-card play cannot be made or scored in the fork and None is not a registerable hand
- Universum: sole context is cry_universum, fired by Cryptid's SMODS.upgrade_poker_hands override to multiply hand level-up gains (X2 chips/mult per level); fork raises no level-up context and has no hand-level modification hook
- Void: Levels cry_Clusterfuck, which cannot be registered in the fork (the hand needs more than 5 played cards); there is no hand for its hand_type to level
- Voxel: Levels cry_Declare0/1/2, the custom poker hands created at runtime by the Code card Declare (code-card program state); no Declare hands can exist in the fork
- Wonka Bar: requires SMODS.change_play_limit / SMODS.change_discard_limit; the fork has no play or discard selection-limit system or modifier
- Words Can’t Even Begin to Describe This Joker: effect requires the cry_WholeDeck poker hand (the entire deck in one play); the fork caps card selection at 5 with no play-limit API, so the hand can never be formed
- function dump man B): debug/test item in PC source, not player content

LICENSE AND CREDITS
Cryptid is GPLv3; this port is GPLv3 too, and the full license
text ships in this folder (LICENSE). Original mod by the Cryptid
team (SpectralPack): https://github.com/SpectralPack/Cryptid
Sprites are cropped from the PC mod's own atlases.
