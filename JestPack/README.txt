Jest Pack (3DS Port) v1.0.0
All in Jest v0.7.4 (PC, Steamodded) ported to Balatro3DS: 337
Jokers, 52 consumables, 8 Tags, 8 booster packs and 2
enhancements.

LICENSE / CREDIT
The PC mod ships no license file and none was found in its repo
(checked 2026-10-23). This port is published with full credit to
the All in Jest team (Nevernamed, Survivalaren, RattlingSnow353,
Jumbocarrot, ejwu2, HEAVENBRAND, Jamie!, Vitellary) and a standing
takedown offer: if you are one of the authors and want it removed,
say the word and it comes down.
Original mod: https://github.com/survovoaneend/All-In-Jest
Game: https://github.com/idkhan/Balatro3DS
Fork (the mod API this pack uses):
  https://github.com/sen2008/balatro3ds-fork

INSTALL
1. Unzip this file.
2. Copy the JestPack folder to your SD card at:
     /3ds/save/Balatro3DS/sdmc/mods/JestPack
3. Start (or restart) Balatro3DS.
4. Check Options -> Mods: "Jest Pack" should be listed.
   If a mod fails to load, the reason is written to mods/mods_log.txt
   in the same folder.

WHAT IS IN HERE
- 337 of the 626 ACTIVE Jokers. (Upstream also carries 481 more
  Jokers marked ignore = true -- work in progress the PC build
  itself never deals. Those are out of scope, not "blocked".)
- Consumables: the conversion Tarots (Magus -> Fervent, Sanctuary
  Gate -> Wood), the other portable Tarots and Spectrals, all 32
  Moons plus Gravastar and Pulsar (Planets that level ONE stat of
  a hand at double rate; see port notes), the portable Hex Tarots,
  and the Astral and Hex Tarot consumable TYPES.
- 8 Tags (the portable Gold Tags register at weight 0: out of the
  skip poll, creatable directly -- the closest shape to PC's
  separate golden pool).
- 8 Sidereal booster packs (normal / jumbo / mega art variants).
  They deal Astral cards -- and every Astral consumable is blocked
  on the pin system (below), so until pins exist the packs are
  registered but inert.
- Enhancements: Fervent (gains +10 Chips every time it scores,
  permanently) and Wood (held-in-hand Chips, scaling per Wood
  card held).

PORTED JOKERS (337)
- a young hamlet, abandoned joker, alas, alexandre, angel number, angoulevent,
  animatronic, antonio, art of the deal, atom, bad apple, bad guy, baroque
  joker, bartender, bear, bearded joker, bebe, beekeeper, beelzebub,
  biancolelli, big ears, big red, bingo card, bingsu, birthday clown, blue
  eyes white joker, blue star, bluet, body pillow, bogdonoff, bon vivant,
  bonus bob, bonus pay, bonus round, bozo, bucolic hills, bumper sticker,
  buzzy bee, cairoli, candidate
- candy wrapper, cavalier, cebee credits joker, cerium, cesar, charles,
  cheerio, cheese squigglies, chippy, chips n dip, choleric joker, christmas
  eve, chromatic aberrant, circle joker, clapperdudgeon, cloth joker, clowns
  on parade, coconut, colquhoun, comedy of errors, comic panel, copper,
  coulrorachne, crab in a bucket, crop circle, croupier, cut here, cyclops,
  dandiprat, david, default credits joker, desiderium, devil deal,
  diamantaire, dicky, dim bulb, dire warning, disco joker, doctors orders, dog
  treat
- dont be a joker, dot matrix, downing street, duende, dwarf, earl, egg cc,
  elf, emergent pattern, event horizon, evil joker, executioner, famulus,
  father and son, father christmas, fatuus, feedback form, firework, fish
  fingers, flibbertigibbit, flushed face, flying ace, fortunato, fortune
  cookie, fou du roi, fruity joker, funny bone, funny bunch, funny money,
  funny phone, gameshow, gelato, geoglyph, giocoliere, glasgow smile,
  gloaming, goblet, gonnella, goo joker, goon joker
- great kraken, great white north, grumpy gus, guillaume, guiser, gummy,
  haggler, hallucinaut, happy as larry, hat trick, haughty joker, haunted
  maze, heavenbrand credits joker, hei tiki, histrio, hofnarr the barbarian,
  homemade comic, honker, imageboard, imperious joker, in vino veritas,
  infamous machine, infinite jest, interstate, iron, jackpot, jamie credits
  joker, jeff the joker, jerko, joka lisa, joker baby, jpeg, jumbocarrot
  credits joker, komar, krampus, la commedia e finita, laurel, le fils de
  banane, lead, legerdemain
- lemarchand cube, little boy blue, little devil, lonely night, low priest,
  lucignolo, lucina, lucky horseshoe, lucky seven, maguelonne, mandrake, marcy
  credits joker, mariachi, master of pegs, meaty joker, melancholic joker,
  melpomene, mike check, mixel perfect, mondrian joker, mr lonely, mummer,
  mute joker, napkin, nedda, neon sign, neptunium, neutronium, nevernamed
  credits joker, nichola, notsoai credits joker, null joker, odd rod, oklo
  reactor, old joker, omlette, one little duck, orphic joker, overdesigned
  joker, pangram
- pantomimus, papermoon credits joker, paracosm, parking space, party
  streamers, peanut brittle, pedestrian, pedrolino, pell mel, pellucid joker,
  pengelding, penny, petrushka, pierrot, pigpen, pinhead, pipine, plain jane,
  plain packaging, plutonium, polybius, pompey, poppins, postcard from
  perdition trail, pour one out, profile, propaganda, protophanes, prototype
  credits joker, public bathroom, punk joker, quadrangled joker, quantum foam,
  quark, queen bee, quicksilver, rattling snow credits joker, realty sign, red
  joker, remina
- richie rich, rising sun, rock n roll clown, rodeo clown, rubberhose,
  rudolph, sam mcgee, sanguine joker, sapphic joker, saucy jacky, saveloy,
  scaramouche, scopaesthesia, scorecard, scott free, scroggin, scrunched
  joker, scurra, second tier meme, semaphore, servillus, sherrif, shredded
  joker, silent sam, silly billy, silver, silver screen, silvio, simple simon,
  single cell, skomorokh, sleepy joker, slim joker, slippery when wet,
  slubberdegullion, smide, sneaky pete, sommers, soviet, splat
- square eyes, squeezy pete, stagehand, stave, stracciatella, sudoku, suibhne,
  sundae 1, sundae 2, sundae 3, sunny joker, sunny side, survivalaren credits
  joker, taggart, taikomochi, taillefer, tangled joker, taylor credits joker,
  teeny joker, ten sharp, tetraphobia, tetrominoker, the house that jack
  built, the jester, the ludovico technique, theyre laughing at you,
  thomazina, tin, tin man, tipteerer, tonpraten, tornado, toto, tract, triple
  gooberberry sunrise, trophy kill, trypophobia, tussaud, unobtanium, uranium
- valentine, veggie joker, vesti la guibba, vitellary credits joker, vitruvian
  joker, whiteface grotesque, windswept joker, wire joker, wizard, word art,
  yang, yin, youve got mail, yu sze, zanni, zenzizenzizenzic, zerco

NOT PORTED, WITH REASONS (refreshed census, Wave 4 J1)
- 84 Jokers are REWRITE class: portable in substance, but each
  needs restructuring onto a different fork seat (running totals
  read from context.port at final_scoring_step instead of PC's
  globals, Jest events approximated by fork contexts, and similar).
  They are the next Jest wave, not blocked on engine features.
- 205 Jokers are BLOCKED. The recurring blockers, all verified
  item by item in the census: Jest's set-total returns
  (aij_set_chips / aij_set_mult have no fork seat); shop, booster
  and voucher slot counts are not Joker modifiers here; perma_*
  exists only for playing cards, not for Jokers; click-activated
  abilities do not exist; blind-modifying and boss-blind effects
  have no seat; rank/suit identity overrides and mutation have no
  seat; and several Jest-only subsystems (attributes in their PC
  form, the Jolly/fusion layers, trophy/achievement hooks) have
  no equivalent. The full per-item census ships in the porting
  record.
- Non-Joker: all 14 Astral consumables (the pin system: persistent
  per-hand pins with their own calculate pass, a pin card area
  and a replacement UI -- none of it exists in the fork); 18
  rarity-filtered Joker booster packs plus the hidden-Legendary
  shader packs and the fixed-contents pack; all 14 Vouchers
  (voucher calculate does not exist); all 5 Editions and all 3
  Seals (fork editions/seals are flat config, these are
  calculate-driven); all 4 Decks (their subsystems are absent);
  5 of 7 Enhancements (Canvas, Charged, Ice, Scorched, Simulated:
  rank/suit mutation, fusion layers and simulation).

PORT NOTES (deviations, all named; per-item detail in the census)
- Moons: the fork derives a hand's Chips and Mult from one level,
  so a moon raises the level through the fork's own funnel and
  then compensates the base stats -- the moon's stat keeps a
  second step, the other stat gives its step back. The
  compensation is exact and composes with later full level-ups.
  The eight paper_* moons target Paperback's Spectrum hands and
  only do something when a pack registering those hands is
  installed, exactly as on PC without Paperback.
- Hex Tarots are dealt on PC by a soul_rate roll off the Tarot
  pool; the fork has no consumable soul roll, so the ported Hex
  Tarots exist and are creatable but no shop or pack deals them.
- Meowth-class Lucky reads: where PC reads a card's lucky_trigger
  flag, the port keys off the fork's probability_success context
  (identifiers lucky_mult / lucky_money), which fires once per
  successful roll -- a card hitting both Lucky rolls can count
  twice where PC counts once (named on the affected Jokers).
- Enhancement conversion strings are re-prefixed to this pack
  (m_jest_fervent / m_jest_wood), as the fork resolves mod_conv
  against its own registrations.
- Unlock conditions are not registered by the fork: everything is
  unlocked and discovered, as in the sibling packs.
- Sprite records note: three Jokers use the hi-res / jumbo /
  trophy art variants on PC; all art here is cut to the standard
  70 x 94 card size from the PC atlases.

Validated headlessly against the Balatro3DS fork source (loader,
registration counts 337 / 52 / 8 / 8 / 2, every Joker tooltip, a
blanket no-error scoring pass over all 337, a Moon level-up test
with exact stat compensation, and the inert-Sidereal check;
suite 6/6) on 2026-10-23. Not yet tested on real hardware.
