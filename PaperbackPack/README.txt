Paperback Pack (3DS Port) v1.0.0
224 of Paperback's 316 Jokers, the Stars and Crowns suits, the four
Spectrum-family poker hands, and 33 of the 56 Minor Arcana
consumables, from Paperback (PC, by Nether and contributors, MIT
License) ported to Balatro3DS.

REQUIRES THE BALATRO3DS FORK (v1.0.0)
This pack creates and destroys cards, registers custom suits, poker
hands and a consumable type, and grants tags through APIs the stock
game's mod API does not have. It needs the fork build and its Tier 1
+ Tier 2 mod APIs (SMODS.add_card / SMODS.destroy_joker /
SMODS.destroy_card, SMODS.Suit, SMODS.PokerHand,
SMODS.ConsumableType):
  https://github.com/sen2008/balatro3ds-fork
On the stock Universal-Updater build the pack will not load
correctly; use the fork build.
The test files (test_paperbackpack.lua, test_paperbackpack_arcana.lua,
test_paperbackpack_extra.lua) stay in the mod folder; the game
ignores them.

INSTALL
1. Unzip this file.
2. Copy the PaperbackPack folder to your SD card at:
     /3ds/save/Balatro3DS/sdmc/mods/PaperbackPack
3. Start (or restart) Balatro3DS (the fork build).
4. Check Options -> Mods: "Paperback Pack" should be listed.
   If a mod fails to load, the reason is written to mods/mods_log.txt
   in the same folder.

SUITS AND HANDS
Stars (light suit) and Crowns (dark suit) join the game as on PC:
they enter the random card-front pool (Standard packs, shop playing
cards) once a Spectrum-family hand has been scored this run or a
card of the suit is already in the deck. The four Spectrum-family
hands are registered with Paperback's own values: Spectrum (50/6),
Straight Spectrum (120/10), Spectrum House (150/15) and Spectrum
Five (180/18), all hidden until scored.

MINOR ARCANA (33 of 56)
The minor_arcana consumable type is registered (shop rate 3; on PC
the rate is 0 and the cards arrive in boosters, which the fork
cannot register - the one structural deviation of the set). All
cards cost $3: Ace of Pentacles, Ace of Swords, Two of Cups, Four
of Cups, Seven of Cups, Eight of Cups, Nine of Cups, Ten of Cups,
Knight of Cups, King of Cups, Six of Cups, Two of Wands, Three of
Wands, Five of Wands, Eight of Wands, Ten of Wands, King of Wands,
Four of Swords, Five of Swords, Nine of Swords, Ten of Swords,
Knight of Swords, Queen of Swords, King of Swords, Two of
Pentacles, Three of Pentacles, Four of Pentacles, Six of
Pentacles, Eight of Pentacles, Ten of Pentacles, Queen of
Pentacles, Knight of Pentacles, King of Pentacles.
Joker-targeting Arcana act on the leftmost eligible held Joker
(the fork has no Joker-highlight targeting). The 23 unported
Arcana are listed under NOT PORTED below.

INCLUDED JOKERS (224 of 316)


Common (82):
- & ($3): If scored hand contains both dark and light suits, retrigger the first of each time
- A Balatro Movie ($4): If played hand is the same as the previous hand, earn $ (Last played: )
- Apple ($1): When buying a Consumable, has a in chance to create a Negative copy and a in chance to self-destruct
- B-Soda ($4): When Blind is selected, gain + Hand Consumed if Blind is cleared with 0 hands remaining
- Bamboo Stick ($7): X Mult if you have another \ Joker (Currently X Mult)
- Black Forest Cake ($3): This Joker gains + Mult for each Blind defeated Self-destructs if any card or Joker is destroyed (Currently + Mult)
- Blue Marble ($3): When a Planet card is used, this Joker gains + Mult (Currently + Mult)
- Cakepop ($6): Scored give + Mult in chance this card is eaten at end of round
- Caramel Apple ($6): Scored give + Mult in chance this card is eaten at end of round
- Card Sleeve ($4): Sell this card to make Joker to the right Eternal
- Champagne ($5): During a Boss Blind, scored cards earn $, doubled if the card has a seal Consumed in rounds
- Charred Marshmallow ($6): Scored give + Mult in chance this card is eaten at end of round
- Chocolate Coins ($6): Earn $ at end of round Reduces by $ each round
- Claw ($3): Scored 3s give + Mult, +2 more Mult for each previously scored 3 this round (Currently + Mult)
- Complete Breakfast ($4): + Mult and + Chips in chance this card is eaten after played hand Chance increases by after every played hand
- Degenerate Joker ($4): Played s turn into the card to the right
- Deviled Egg ($5): The first scored card each round becomes Gold. Eaten in rounds
- Dreamsicle ($6): Scored Diamonds give + Mult in chance this card is eaten at end of round
- Emergency Broadcast ($6): Scored 5s and 8s give +5 Mult and +8 Chips
- Find Jimbo ($4): Each played of earns $ when scored (Card changes every round)
- Forlorn ($6): If played hand's only scored suit is Spades, destroy a random card held in hand
- Fraudulent Joker ($5): Played cards with Crowns suit give + Mult when scored
- Hamsa ($5): On the first hand of round, retrigger the first played cards...
- Hamsa ($5): ...On the last hand of round, + to all listed probabilites
- Heretical Joker ($5): Played cards with Stars suit give + Mult when scored
- High Speed Rail ($3): This Joker gains Mult equal to the cost of bought Jokers This Joker loses Mult equal to the sell value of sold Jokers (Currently + Mult)
- Ice Cube ($4): + Hand when Blind is selected Melts if score catches fire
- It's TV Time! ($5): Played Stars give + chips when scored
- Jacks ($5): Gains +1 Mult when a Jack is discarded (Currently + Mult)
- Jestosterone ($5): Scored Queens become Kings
- Jestrica ($5): Gains +1 Mult when an 8 is scored Resets if no 8s are scored in a round (Currently + Mult)
- Jestrogen ($5): Scored Kings and Jacks become Queens
- Jimbo's Inferno ($5): Scored dark suits give + Mult for every dark suit held in hand (Currently + Mult)
- Joke Master ($3): This Joker gains + Mult if played hand is a hand changes every round (Currently + Mult)
- Joker CD-i ($3): in chance to create a random Planet card if played hand has exactly cards (Must have room)
- Joker Cookie ($1): Earn $ at end of round Payout increases by $ when cashing out in chance this card is eaten at end of round (Max of $)
- Joker Duty ($6): This Joker gains + Mult if round was cleared with equal hands and discards (Currently + Mult)
- Joker Jacks ($6): Scored Jacks give $ Decreases by $ at end of round Create a prize after being consumed (Must have room)
- King Me ($6): Scored non-King Crowns increase their rank by
- Loaded Dice ($6): Adds to all listed probabilities if hand contains a scoring Crowns
- Lurid Joker ($3): + Chips if played hand contains a
- Mandela Effect ($4): Randomly enhance the first scored face card each hand
- Matcha ($3): This Joker gains + Chips when a card is scored in chance to consume on discard (Currently + Chips)
- Meeple ($6): If played hand contains a scoring face card, in chance to gain + discard this round
- Moneyback ($6): Every $ [] spent earns $
- Moving Out ($4): This Joker gains + Mult if winning poker hand is not your most played hand (Currently + Mult)
- Nazar ($5): Gains +8 Chips when a Tarot or Minor Arcana card is used (Currently + Chips)
- Nazca Lines ($6): Scored cards earn $ for each adjacent debuffed or unscored card
- NoCopyrightJokers ($5): + Chips for every $1 of sell value your other Jokers have (Currently + Chips)
- Pear ($4): This Joker gains + Chips if played hand contains a . Otherwise, this Joker loses - Chips. Eaten if Chips fall below 0 (Currently + Chips)
- Pocket Pair ($5): Earn $3 if a Pair is drawn at start of round
- Pointy Stick ($7): X Mult if you have another \ Joker (Currently X Mult)
- Ponzu ($6): held in hand have a in chance to give $. Consumed if not triggered during a round Suit changes at end of round
- Pop-Stick ($7): X Mult if you have another \ Joker (Currently X Mult)
- Popsicle Stick ($7): X Mult if you have another \ Joker (Currently X Mult)
- Pride Flag ($6): Gains + Chips if played hand contains a Spectrum. Resets if played hand contains a Straight (Currently + Chips)
- Quick Fix ($6): + hand size. in chance this card is destroyed at end of round...
- Red Sun in the Sky ($5): Scored light suits give + Mult for each scored light suit this round (Currently + Mult)
- Rock Candy ($6): Scored give + Mult in chance this card is eaten at end of round
- Rockin' Stick ($7): Gives X Mult for every \ Joker you have (Currently X Mult)
- Rosary Beads ($4): If the scored hand contains 3 or more Hearts, earn $5
- Royalty Free ($4): The first scored non-face card each round permanently gains + Chips
- Sacrificial Lamb ($6): Gains + Mult for each card destroyed (Currently + Mult)
- Showdown ($5): and held in hand have a in chance to earn $
- Shuttle ($6): The first played hand of round gives money equal to double the played hand's level (Max of $)
- Shūgi Bukuro ($6): Earn $ when a Blind is skipped Increases by $ each time
- Silent Assassin ($8): Scored 4s and 7s give + Mult Increased by + Mult for every [] cards destroyed
- Small Scale Onshore Wind ($6): This Joker gains + Mult per consecutive discard of exactly cards (Currently + Mult)
- Sticky Stick ($7): X Mult if you have another \ Joker (Currently X Mult)
- Sweet Stick ($7): Gives X Mult for every \ Joker you have (Currently X Mult)
- Takoyaki ($6): Scored s give $ in chance to eat this Joker when an scores
- Tanghulu ($6): Scored give + Mult in chance this card is eaten at end of round
- The Sun ($3): If all scored suits are light, this Joker gains + Mult When a suit that isn't light scores, this Joker loses - Mult (Currently + Mult)
- Time Regression Mix ($3): If the scoring hand contains at least 4 suits, gains +2 Mult (Currently + Mult)
- Toppins ($5): Cards give + Mult when scored Increases by +2 Mult for each previously scored card (Resets after each hand played)
- Towering Pillar of Hats ($6): Played give + Mult for every s, s or s in the deck (Currently + Mult)
- Trans Flag ($6): Gives + Mult for each remaining discard (Currently + Mult)
- Tropic Birds ($6): If scoring hand contains an , retrigger the first and last card
- Tutor ($6): Numbered cards have double Chip value
- Wild Prize! ($7): s have a in chance to retrigger and a in chance to earn between and $ when scored
- Yacht ($5): This Joker gains + Chips if hand contains a scoring or (Currently + Chips)
- Zealous Joker ($3): + Mult if played hand contains a

Uncommon (81):
- 56 Leaf Clover ($6): If the winning hand of a Boss Blind scores only Clubs, create a Negative Tag
- Alert ($4): If played hand is a single face card, destroy it (/)
- Aurora Borealis ($6): This Joker gains X0.5 Mult for each editioned Joker card held (Negatives are excluded) (Currently X Mult)
- Autumn Leaves ($6): give X Mult when scored. Increases by X Mult for each consecutively scored (Resets after each hand played)
- Basic Joker Energy ($6): Using any Consumable has a in chance to make a copy (Cannot make copy of a copy) (Must have room)
- Bicycle ($6): Wild Cards give Mult equal to their Chip value when scored
- Big Misser ($6): X Mult for each empty consumable slot (Currently X Mult)
- Birches ($6): give X Mult when scored. Increases by X Mult for each consecutively scored (Resets after each hand played)
- Bismuth ($7): Scored and have a in chance to gain a random edition
- Black Rainbows ($8): Scored and have a in chance to become Polychrome
- Blade Dance ($6): When Blind is selected, add random temporary s to your hand
- Blazing Trails ($6): If discard has exactly cards, destroy the rightmost card
- Blue Bonnets ($6): give X Mult when scored. Increases by X Mult for each consecutively scored (Resets after each hand played)
- Blue Curaçao ($6): The next played and scored permanently gain + Mult when scored
- Boundary of Death ($8): s have a in chance to give + additional Mult
- Buckshot ($6): If played hand contains a Two Pair, destroy all cards of a random rank in scoring hand and earn $ for each
- Calling Card ($6): Gains +X0.25 Mult whenever you defeat a Boss Blind (Currently X Mult)
- Cardboard Box ($7): If first played hand of round contains a scoring Queen, add $ of sell value to every Joker Increases by $ when a Food Joker is destroyed
- Cast Iron ($7): Gives + hand size for every s in your full deck (Currently + hand size, Max )
- Cherry Blossoms ($6): give X Mult when scored. Increases by X Mult for each consecutively scored (Resets after each hand played)
- Coffee ($6): + hand size, increases by when Blind is skipped. in chance this card is consumed when Small Blind or Big Blind is selected
- Der Freischütz ($6): If poker hand contains only 7s, destroy the lowest chip-value card in your full deck Avoid the Seventh Bullet... /
- Derecho ($6): Gains X Mult if scored suits are all dark (Currently X Mult)
- Disco Joker ($7): This Joker gains + Mult when buying a card with $ or less (Currently + Mult)
- Donor Card ($6): This Joker gains + Mult for every scored Heart card (Currently + Mult) Scored Hearts lose Chips and are destroyed upon reaching 0
- Doppler Radar ($7): Fill consumable slots with random cards upon clearing a Blind
- Evergreens ($6): Spades give X Mult when scored. Increases by X Mult for each consecutively scored Spades (Resets after each hand played)
- Freight ($8): If cleared Blind is a Boss Blind, gain $ of sell value, otherwise earn the sell value of this Joker. When sold, gain + discard per $ of sell value instead of money
- Full Moon ($7): Planet cards have a in chance to level up again
- Furioso ($6): This Joker gains X Mult for each unique scored rank. Resets after Boss Blind (Currently X Mult) (Ranks played:)
- Gambit ($6): If played hand contains a scoring Crowns, the first scored Crowns destroys the first non-Crowns held in hand and gains twice its Chip value
- Ghost Cola ($6): Sell this card to create a Negative Tag and a random Spectral card (Must have room)
- Golden Apple ($7): Earn $ for each enhanced card in your deck at the end of the next rounds (Currently $)
- Guns Blazin' ($8): Played Aces give X1.5 Mult when scored
- HATRED ($5): Before each hand, mark a random card held in hand Marked cards give X Mult when scored and are destroyed if not scored
- Inner Peace ($6): + hand size before first hand of round is played
- Insurance Policy ($6): +5 Mult for each Jack and -5 Mult for each King in your full deck (Currently Mult)
- Jester ($7): Whenever a card is destroyed, also destroy a random card in your full deck
- Jimbo's Joyous Joker Jamboree ($6): Create a random Minor Arcana card for every [] scored cards (Must have room)
- Joker Crossing ($8): Enhanced cards have a in chance to retrigger
- Journal ($6): This Joker gives the total Chips of the previous hand. (Currently + Chips)
- Keycard ($5): After defeating a Boss Blind, this Joker self-destructs and gives $ after cashing out
- Malibu ($7): Gives Chips equal to 10 times the lowest Chip value card in the scored hand (Currently + Chips)
- Man ($7): Played dark suit cards permanently gain + Mult when scored
- Marble Soda ($6): Scored give X Mult Destroyed after more playing cards are destroyed
- Mezzetino ($7): At end of round, spend remaining discards to destroy a random card in hand and earn $ each
- Mismatched Sock ($6): Gains +X0.1 Mult if a discard contains exactly one card Resets if a played hand contains a Pair (Currently X Mult)
- Moribund ($6): This Joker gains + Mult when a Blind is cleared with 0 hands remaining. This Joker doubles its Mult if Blind is not cleared (Currently + Mult)
- One Shift More ($7): This Joker gains X Mult for every [] scored cards (Currently X Mult)
- Paralyzed ($7): Create a random card upon clearing a blind
- Percussion Ensemble ($7): X Mult for each unique Enhancement in your full deck (Currently X Mult)
- Planchette ($6): Gains +X0.25 Mult when a Spectral card is used (Currently X Mult)
- Prescript ($6): Retrigger all played cards this round if first hand of round contains a Poker hand changes every round (Currently )
- Prince of Darkness ($7): If scoring hand contains a and other unique suits, this Joker gives X Mult for this hand and the next (Currently the next hands)
- Prism ($6): If played hand contains a , convert all scored cards into random different suits
- Pyrite ($7): Played have a in chance to create a random Tarot card when scored (Must have room)
- Red Key ($7): When Blind is selected, create a temporary Rare Joker When sold, remove temporary from all Jokers
- Redscreen ($6): +X Mult for each light suit and -X Mult for each dark suit in your full deck (Currently X Mult)
- Reference Card ($6): Gives X Mult for every time all 9 base poker hands have been played (Currently X Mult)
- River ($7): If the played hand contains 5 scoring cards, earn half the lowest scoring card's Chip value as money (Max of $11)
- Roulette ($7): Each hand played, this Joker chooses a random rank and suit. Scored cards earn $ if they match suit, $ if they match rank, or $ if they match exactly
- Satellite Array ($7): Gains +15 Chips for each Planet card used, and loses -5 Chips for every hand played (Currently + Chips)
- Scorecard ($7): Every [] discarded , this Joker gains another's sell value as +Mult (Currently + Mult)
- Shooting Star ($6): Scored have a in chance to create the Planet card for played poker hand
- Skydiver ($6): X Mult if all scored cards are less than or equal to the lowest rank scored this round (Updates at end of played hand) (Currently: )
- Soft Taco ($6): X Mult in chance this card is eaten at end of round
- Solar System ($8): Gives X Mult for every level all 9 base Planet hands share (Currently X Mult)
- Stout ($6): The next played and scored permanently gain + Chips when scored
- SUPERJOKER ($5): Retrigger all cards in first hand Gives X Mult on subsequent hands
- Surfer ($7): Gains +10 Chips for every 10 held in hand at end of round (Currently + Chips)
- Technology ($8): Gains +X0.5 Mult for each scoring Mult Card, during this round (Currently X Mult)
- Telamon ($6): If winning hand contains a , create a random Swords card (Must have room)
- The Batter ($4): Scored 3s are destroyed (/...)
- The Girl From 024 ($7): Gains +X0.2 Mult for every Queen held in hand at end of round (Currently X Mult)
- Tome ($6): + Consumable Slot for every unique Joker rarity you have (Currently + Slot)
- Triple Moon Goddess ($6): If played hand contains a Three of a Kind, in chance to create a random Tarot card and in chance to create a random Minor Arcana card (Must have room)
- Trust Us! ($6): X3 Mult if played hand contains a Three of a Kind, X0.5 Mult otherwise
- Unionized Labor ($7): Triples all listed probabilities while you have $25 or less Halves probabilities otherwise
- War Without Reason ($6): When first hand is drawn, destroy Joker to the right and add a random seal to a card held in hand
- Wheat Field ($6): give X Mult when scored. Increases by X Mult for each consecutively scored (Resets after each hand played)
- Wish You Were Here ($6): Gives +Mult equal to X the sell value of this card. Gains $ of sell value at end of round (Currently + Mult)

Rare (58):
- 21st Century Joker ($10): When Big Blind or Boss Blind is cleared, destroy Joker to the left and create a new Joker of equal or higher rarity (Cannot upgrade to Legendary Jokers)
- 57 Leaf Clover ($7): + to all listed probabilities (Currently +)
- Attacking Vertical ($8): Scored 9s and 5s give X Mult Gains +X0.25 Mult when a Boss Blind is defeated
- Banana Man ($8): Jokers have a in chance to give X Mult
- Better Call Jimbo ($8): X0.1 Mult for every $4 owned (Currently X Mult)
- Black Knife ($9): Create a random Negative Joker for every [] destroyed light suits Scored light suits have a in chance to destroy a random Joker
- Black Star ($6): Scored dark suits become
- Book of Vengeance ($9): After defeating a Boss Blind, destroys itself and the Joker to its left, then makes a copy of Joker to its right
- Deadringer ($7): Retrigger scored s and s once, and scored s twice
- Der Fluschütze ($9): If first played hand of round is a single face card, destroy it and this Joker gains X Mult (Currently X Mult)
- Double Dutchman ($8): For the next hands, each card held in hand has a in chance to get a random enhancement and a in chance to get a random seal
- EMF Reader ($8): If first hand of round contains a Spectrum, destroy played cards and create a random Spectral card
- Epic Sauce ($8): X Mult Destroy a random Joker if played hand is not the first hand of round
- Eyelander ($8): Scored face cards are destroyed. After scoring face cards, selling this Joker adds Negative to a random Joker (Currently Heads)
- First Contact ($8): Create a random Spectral card for every [] scored dark suits (Must have room)
- Freezer ($7): Create a Negative Food Joker after defeating a Boss Blind
- GIGA SIZE ($8): Gains +X1 Mult for every hand played in the current Blind (Currently X Mult)
- Golden Egg ($8): When a secret hand is played, earn the sell value of the Joker to the right
- Grand Strategy ($8): X4 Mult if 7 unique enhancements are in your full deck (Currently enhancements)
- Great Wave ($8): Retrigger rightmost scoring card once for each other scoring card
- Hole in One ($8): If first hand of round cleared the Blind, double the sell value of all cards (Max of $ per round) When this Joker is sold, set the sell value of all cards to $0
- Hotel Guest ($5): Gives X Mult for each Queen held in hand (Currently X Mult)
- I Wish That I Could Fall ($7): When a card is scored, this Joker decreases the card's rank and gains + Chips (2 -> Ace -> King) (Currently + Chips)
- Legacy ($8): When a non-Enhanced card is destroyed, add its Chip value as Mult to this Joker (Currently + Mult)
- Lone Digger ($8): If scored hand has only one face card, retrigger it for each scored card
- Magic Mushroom ($8): X Mult Loses X0.5 Mult for every hand played Resets after clearing a Blind
- Master Spark ($8): If played hand contains a Spectrum, destroy all cards held in hand and all played cards become Polychrome Self-destructs
- Nigiri ($6): This Joker gains 1/th of the rank of discarded cards as XMult, self-destructs if a Face card scores, resets when Boss Blind is defeated (Currently X Mult)
- Paranoia ($8): Light suits give + Mult when scored for every dark suit card destroyed this run (Currently + Mult)
- Park Postcard ($8): Gains +X0.2 Mult at end of round Resets when a card is added to or removed from your deck (Currently X Mult)
- Pool Table ($8): If first hand of round scores no face cards, create the card for played poker hand (Must have room)
- Power Surge ($8): Played s give X Mult when scored and have a in chance to destroy a card held in hand
- Punch Card ($10): After rounds, sell this card for Ante (Currently /)
- Resurrections ($8): in chance to return sold Jokers and create an extra Negative copy with -$ sell value Chance increases by on fail Self-destructs
- Sake Cup ($8): After a hand is played, s held in hand have a in chance to create the Planet card for played poker hand (Must have room)
- Seven Stars ($8): Retrigger all scored
- Shabu Shabu ($10): + Joker slots. Reduces by after clearing Boss Blind
- ShadowMantle ($8): Scored have a in chance to create a Negative Tag (Once per round)
- Sinister Minds ($8): Retrigger all scored cards time if played hand is a Increases by when using Spectral card, then requirement increases by (Currently Spectral card left)
- Solar Eclipse ($6): Scored light suits become
- Solemn Lament ($8): This Joker gains X Mult if scored hand contains both dark and light suits (Currently X Mult)
- Stamp ($8): in chance this Joker gains + Chips when any card with a seal is scored (Currently + Chips)
- Subterfuge ($8): Destroys the first played hand every round
- Summoning Circle ($8): If played hand contains a , create a copy of a random consumable (Must have room)
- The Dynasty ($8): X Mult if played hand contains a
- The Mind Electric ($3): Scored are destroyed and give this Joker X Mult (Currently X Mult)
- The Normal Joker ($8): Retrigger all Common Jokers
- The One Who Waits ($8): When a is scored, in chance this Joker gains X Mult (Currently X Mult) in chance to create a Tarot (Must have room)
- The Quiet ($8): X0.1 Mult for each card below 52 in your full deck (Currently X Mult)
- ThornRing ($7): When a is played, destroy the played hand and create a random Spectral card (Must have room) * left.
- Tian Tian ($7): Gains +X0.1 Mult when a playing card is destroyed (Currently X Mult)
- Torii ($8): Gives Ante every () skipped Blinds (Only counts skips in new antes, currently )
- Ultra Rare ($9): When Blind is selected, create random Common, Uncommon and Rare Temporary Negative Jokers with $ sell value
- Union Card ($8): XMult equal to the number of scoring light suit cards (Hearts and Diamonds)
- Whitebeard ($8): During a Boss Blind, scored cards give X Mult Defeating the Boss Blind destroys the winning hand
- Wild +4 ($10): + hand size Hand
- Yacht Dice ($8): This Joker gains X Mult for each unique hand type played this run (Currently X Mult)
- You Are a Fool! ($8): If scored hand contains or more face cards, convert all cards held in hand to the leftmost scored card self-destructs

Legendary (3):
- L'angely ($20): Earn half the sell value of all Jokers when defeating a Big Blind Earn the full sell value when defeating a Boss Blind
- OFF Switch ($13): When a playing card is destroyed, attempt to destroy leftmost destructible Joker and this Joker gains X Mult if successful (Currently X Mult)
- Pedrillo ($20): First scored Queen creates a Planet card for played poker hand (Must have room)

PORT NOTES (deviations from PC, beyond the structural ones above)
The expansion Jokers follow Paperback's code, not always its
tooltips, where the two disagree (e.g. Disco checks the wallet when
buying; Der Freischutz follows the code's lowest-chip-value rule).
Jokers that destroy cards do so in the hand's before/after passes,
the slots the port raises, because the fork never raises PC's
destroy_card context. Per-Joker deviations are marked with
PORT NOTE comments in paperbackpack.lua; the largest classes:
- Destruction reactions: a Joker cannot see another Joker being
  destroyed (no such event), so Black Forest Cake and Cardboard
  Box scale only on playing-card destruction, and Sacrificial
  Lamb keeps only its playing-card half.
- OFF Switch's eternal addon Jokers (Alpha/Epsilon/Omega) are
  themselves unportable; it creates The Batter uneternal instead,
  and only when that def is registered. Red Key creates a random
  Rare (the fork has no Ultra Secret rarity). Freezer creates a
  random Negative Common/Uncommon Joker (no Food pool exists).
- Permanent per-card bonuses ride the fields the fork's scoring
  actually reads (card_data.chip_bonus / mult_bonus / Bonus).
- Triple Moon Goddess uses its Minor-Arcana-enabled behavior,
  since this pack ships the Arcana.
- Showdown and The Normal Joker follow the PC defs where the
  audit data disagreed with them (Showdown's chance gate;
  The Normal Joker is Rare $8 as its def says).

NOT PORTED (92 Jokers, each on its named blocker)
- Custom enhancements (16): Blood Rain, Collector, Festive Joker,
  Gauze, Greeting Card, Happy Accident, Kintsugi Joker, Medic,
  Mexican Train, Pink Joker, Pinot Noir, Plastic Wrap, Sommelier,
  Spotty Joker, Teapot, Watercolor Joker. Paperback's eight custom
  enhancements (Soaked, Sleeved, Bandaged, Wrapped, Ceramic,
  Domino, Stained, Antique) cannot be registered; a consumable
  naming one would load-error the whole mod.
- XChips / permanent X (14): Bergentrucking, Blue Star, Chocolate
  Joker, Crispy Taco, Deck of Cards, Freedom of Choice, Grenadine,
  Nachos, Nigori, Oracle, Quartz, Ready to Fly, Shinzaemon,
  Stella Octangula. The fork has no x_chips return and no scoring
  reader for perma_x_mult / perma_x_chips.
- Tags (9): Angel Investor (Paperback's custom Angel Investment
  Tag), Book of Life, J and Js, Jimbo Adventure, Jokers 11,
  Shopkeep, Spirit Box, Stereoscopic Specs, The Wonder of You.
  Only vanilla tags can be granted (G:addTag); Paperback's custom
  tags cannot be registered, and copying/polling a player's tags
  has no API. (56 Leaf Clover, Ghost Cola and ShadowMantle create
  the vanilla Negative Tag and ARE ported.)
- Custom rank Apostle (6): As Above So Below, In Case I Make It,
  One Sin and Hundreds of Good Deeds, Penumbra Phantasm, Plague
  Doctor, White Night. Custom ranks cannot be registered.
- E.G.O Gifts (4): Arayashiki, Fodder, Grimoire, The Strongest.
  Paperback's custom consumable type with its own packs; only its
  Minor Arcana type was in scope for the fork's ConsumableType.
- Paperclips (4): Chip Clip, Clippy, Clothespin, Manilla Folder.
  The paperclip system does not exist in the fork.
- Shop / pool manipulation (9): Backpack, Membership Card,
  NormalJKR, Protocol, Shopping Center, Touch Tone Joker,
  Ouija Board (shop rates), plus Chaplin and Everything Must Go
  (granting/redeeming Vouchers mid-run).
- Copy effects (3): Forgery, Master Plan, Photocopy (they ride
  SMODS.blueprint_effect, which the fork does not provide).
- Balance mechanic (3): Let It Happen, Milk Tea, Stardrop.
- Missing contexts (10): Coin Collection and Frutiger Aero
  (money_altered), Cream Liqueur (tag activation), Off Alpha /
  Off Epsilon / Off Omega (joker_type_destroyed), One With
  Nothing (press_play), The Sun Rises (modify_scoring_hand),
  Watermelon (setting_ability), Weather Radio (blind_disabled).
- Other single blockers: Aperol (perma_p_dollars has no scoring
  reader), Burning Pact (draws cards; no draw API), Cross and
  Unholy Alliance (react to destructions they did not order),
  Da Capo and Jester of Nihil (debuff manipulation), Ddakji and
  Vacation Juice and The World (card/Joker state systems),
  Determination (prevents death), Jimbocards (global inflation),
  Lager (permanent probability modification), Nichola (scores
  held cards; no held-card scoring pass), Sacred Heart
  (permanent retrigger grant).
NOT PORTED - MINOR ARCANA (23 of 56)
- Paperclip Arcana (11): Ace of Cups, Ace of Wands, Three of
  Cups, Four of Wands, Page of Wands, Page of Cups, Six of
  Swords, Seven of Swords, Seven of Pentacles, Eight of Swords,
  Nine of Pentacles.
- Custom-enhancement conversions (8): Five of Cups (Soaked),
  Five of Pentacles (Antique), Nine of Wands (Bandaged), Page
  of Pentacles (Sleeved), Page of Swords (Domino), Queen of
  Cups (Ceramic), Six of Wands (Wrapped), Three of Swords
  (Stained).
- Custom Paperback systems (4): Knight of Wands (High Risk
  Tag), Seven of Wands (Breaking Tag), Queen of Wands (Dichrome
  edition), Two of Swords (needs last-scored-suit state the fork
  does not track).

VALIDATION
Loaded through the real ModLoader and exercised in Balatro3DS's
own headless harness: main suite 41/41 (the original 36 Jokers'
behavior, the suits, the Spectrum hands through the game's own
classifier, the exotic gate), arcana suite 34/34 (type
registration, all 33 cards, one behavior test each), expansion
suite 57/57 (registration, names, rarities, costs and clean
tooltips for all 224 Jokers, plus 57 behavior tests across the
188 expansion Jokers), and the fork's own mod suite still green
at 54/54. Hardware testing is the remaining step.

CREDITS
- Nether and contributors - Paperback, its Joker designs, text
  and art, the Stars and Crowns suits, the Spectrum hands and
  the Minor Arcana. Paperback is MIT License, Copyright (c)
  2025; the full license text ships in LICENSE.txt.
  https://github.com/Balatro-Paperback/paperback
- idkhan / Gazpacho - Balatro3DS and its mod API.
- sen2008 - the Balatro3DS fork (Tier 1/Tier 2 mod APIs).
- LocalThunk - Balatro.
