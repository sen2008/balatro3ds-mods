Paperback Pack (3DS Port) v1.2.0
280 of Paperback's 316 Jokers, the Stars and Crowns suits, the four
Spectrum-family poker hands, 45 of the 56 Minor Arcana consumables,
Paperback's eight custom enhancements, five of its custom tags and
its Dichrome edition, from Paperback (PC, by Nether and
contributors, MIT License) ported to Balatro3DS.

REQUIRES THE BALATRO3DS FORK (v1.1.0 + Wave 1 APIs)
This pack creates and destroys cards, registers custom suits,
poker hands, a consumable type, enhancements, tags, boosters and
an edition, and grants tags through APIs the stock game's mod API
does not have. It needs the fork build and its Tier 1 + Tier 2 +
Tier 3 mod APIs (SMODS.add_card / SMODS.destroy_joker /
SMODS.destroy_card, SMODS.Suit, SMODS.PokerHand,
SMODS.ConsumableType, SMODS.Enhancement, SMODS.Tag, SMODS.Booster,
SMODS.Edition), plus the Wave 1 additions the v1.2.0 Jokers ride:
partial balance (a numeric balance return), the permanent card
fields (SMODS.set_perma / SMODS.get_perma) and the game_over /
saved context:
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

MINOR ARCANA (45 of 56)
The minor_arcana consumable type is registered with shop rate 0,
as on PC: the cards arrive in Minor Arcana booster packs (normal
3 cards / choose 1 for $4, jumbo 5/1 for $6, mega 5/2 for $8,
registered with the fork's SMODS.Booster) and from Joker effects.
All cards cost $3: Ace of Pentacles, Ace of Swords, Two of Cups,
Four of Cups, Five of Cups, Seven of Cups, Eight of Cups, Nine of
Cups, Ten of Cups, Knight of Cups, King of Cups, Six of Cups, Two
of Wands, Three of Wands, Five of Wands, Eight of Wands, Ten of
Wands, Knight of Wands, King of Wands, Four of Swords, Five of
Swords, Seven of Wands, Nine of Swords, Ten of Swords, Knight of
Swords, Queen of Wands, Queen of Swords, King of Swords, Two of
Pentacles, Three of Pentacles, Four of Pentacles, Five of
Pentacles, Six of Pentacles, Eight of Pentacles, Nine of Wands,
Ten of Pentacles, Queen of Cups, Queen of Pentacles, Knight of
Pentacles, King of Pentacles, Page of Pentacles, Page of Swords,
Six of Wands, Three of Swords, Two of Swords.
Joker-targeting Arcana (Nine of Cups, Nine of Swords, King of
Swords, Two of Pentacles) now use the fork's Joker highlighting:
pick the Joker, then use the card on it, as on PC. The 11
unported Arcana are listed under NOT PORTED below.

CUSTOM ENHANCEMENTS, TAGS AND EDITION (Tier 3 additions)
Paperback's eight custom enhancements are registered: Soaked,
Sleeved, Bandaged, Wrapped, Ceramic, Domino, Stained and Antique.
On PC they are source-gated (created by specific Jokers and
Arcana, never by random polls), so they are registered with poll
weight 0 here too. Five custom tags are registered: Angel
Investment (gain 20% of your money, up to $100), Breaking (skip
the Boss Blind), High Risk (defeat the Boss for $25 - see PORT
NOTES), Dichrome (the next Joker bought in the shop is free and
Dichrome) and Divination (open a free Mega Minor Arcana pack).
The Dichrome edition is registered; its +1 Hand and +1 Discard
effect cannot be expressed (the fork has no edition calculate),
so Dichrome Jokers are cosmetic here beyond their free price
from the Dichrome Tag and Queen of Wands. The custom
enhancements, tags, boosters and the edition ship without
sprites: the PC snapshot this port is built from contains only
the Jokers and Minor Arcana atlases, so those registrations use
the fork's fallback art.

INCLUDED JOKERS (280 of 316)


Common (97):
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
- Pink Joker ($7): While a Stained Card is held in hand, scored cards have a 1 in 5 chance to permanently gain +$2 when scored if they do not already have it
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

- Angel Investor ($4): Create an Angel Investment Tag when a Blind is skipped or a Boss Blind is defeated
- Coin Collection ($6): Earn $1 whenever you earn money
- Cream Liqueur ($4): Earn $5 when you gain a Tag. Consumed in 3 rounds
- Frutiger Aero ($6): +100 Chips. Loses 2 Chips for every $1 spent in the shop. Resets after a Boss Blind (Currently + Chips)
- Gauze ($4): When your last discard is a single card, it becomes Bandaged
- Greeting Card ($4): Scored Wrapped cards add $2 of sell value to this Joker
- Jimbo Adventure ($4): Create a random Tag when a Blind is skipped
- Mexican Train ($6): Scored Domino cards earn $1 for each Domino card in the scoring hand
- Nachos ($6): X1.5 Chips. Loses X0.05 Chips for each discarded card; eaten when it would fall to X1 (Currently X Chips)
- Pinot Noir ($5): Stained cards held in hand lose 1 remaining trigger (starts at 10); destroyed at 0
- Plastic Wrap ($4): When a Sleeved card is destroyed, up to 2 random unenhanced cards in your deck become Sleeved
- Stella Octangula ($6): The first scored Stars card each round gives X2 Chips
- Teapot ($5): This Joker gains +5 Chips for each scored Ceramic card (Currently + Chips)
- Unholy Alliance ($6): This Joker gains +12 Chips for each card or Joker destroyed (Currently + Chips)

Uncommon (104):
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
- Aperol ($6): The next 5 played and scored Diamonds permanently gain $1 when scored
- Grenadine ($6): The next 5 played and scored Hearts permanently gain X0.2 Mult when scored
- Milk Tea ($6): Balance 50% of Chips and Mult. Reduces by 10% if a hand's final Mult ends up greater than its Chips
- Nigori ($6): The next 5 played and scored Stars permanently gain X0.3 Chips when scored
- Stardrop ($7): Scored Stars Balance 2% of Chips and Mult

- Chocolate Joker ($8): X Chips equal to 1 + X0.2 for each Joker held (Currently X Chips)
- Collector ($7): Earn $1 at end of round for each Sleeved card in your full deck
- Crispy Taco ($6): X3 Chips. 1 in 6 chance this card is eaten at end of round
- Cross ($6): Playing cards cannot be destroyed while this Joker is held (see PORT NOTES)
- Deck of Cards ($7): If the played hand is a single Antique card, it gains X0.25 Chips and is destroyed
- Festive Joker ($6): Scored Wrapped cards have a 1 in 5 chance to create a random Consumable (Must have room)
- Happy Accident ($7): Antique cards held in hand give X Chips at halved scaling (X1.5 becomes X1.25)
- J&J's ($6): The next Spectrum-family hand played creates 2 random Tags. Self-destructs after 3 rounds
- Kintsugi Joker ($7): This Joker gains +2 Chips for each Ceramic card destroyed (Max of +10) (Currently + Chips)
- One With Nothing ($5): When Play is pressed, destroy all cards held in hand that were not played (see PORT NOTES)
- Oracle ($6): X Chips for each unique Minor Arcana used this run (Currently X Chips)
- Quartz ($7): Scored Stars give X Chips for each other Stars card in the played hand
- Sommelier ($6): The first Stained card discarded each round gains a random seal
- Spotty Joker ($3): This Joker gains X0.1 Mult for each Domino card in the scoring hand (Currently X Mult)
- Spirit Box ($7): If played hand is this Joker's chosen hand, create a random Tag. Chosen hand changes each round
- The Wonder of You ($9): Create 2 random Tags when a Boss Blind is selected
- Watercolor Joker ($7): Scored Soaked cards give X1.5 Chips
- Watermelon ($6): This Joker gains X0.1 Mult when a card's enhancement changes, and loses X0.1 Mult for each card destroyed. Destroyed below X1 (Currently X Mult)

Rare (72):
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
- Bergentrücking ($8): If scored hand contains a Heart and contains a Crown, scoring Crowns gain X0.05 Mult and scoring Hearts are destroyed
- Determination ($7): Prevents death, on death -1 Ante, -1 hand size and self-destructs
- Freedom of Choice ($8): If played hand contains a Five of a Kind, scoring cards permanently gain X0.05 Mult
- Sacred Heart ($10): If played hand is a Flush Five, give the first scored card 1 permanent retrigger and destroy all other scored cards

Legendary (7):
- L'angely ($20): Earn half the sell value of all Jokers when defeating a Big Blind Earn the full sell value when defeating a Boss Blind
- OFF Switch ($13): Creates Eternal Alpha, Epsilon and Omega when obtained. When a playing card is destroyed, destroy the leftmost non-Eternal Joker and this Joker gains X Mult (Currently X Mult)
- Pedrillo ($20): First scored Queen creates a Planet card for played poker hand (Must have room)
- Shinzaemon ($20): If scored hand contains 5 cards, the 5th card permanently gains X0.2 Mult

- Alpha ($1): Gains +13 Chips for each Joker destroyed (Currently + Chips) (Created by OFF Switch only)
- Epsilon ($1): Earn $13 for each Joker destroyed (Created by OFF Switch only)
- Omega ($1): Gains +13 Mult for each Joker destroyed (Currently + Mult) (Created by OFF Switch only)

PORT NOTES (deviations from PC, beyond the structural ones above)
The expansion Jokers follow Paperback's code, not always its
tooltips, where the two disagree (e.g. Disco checks the wallet when
buying; Der Freischutz follows the code's lowest-chip-value rule).
Jokers that destroy cards do so in the hand's before/after passes,
the slots the port raises, because the fork never raises PC's
destroy_card context. Per-Joker deviations are marked with
PORT NOTE comments in paperbackpack.lua; the largest classes:
- Destruction reactions ported in v1.0.0 predate the fork's
  joker_type_destroyed event: Black Forest Cake and Cardboard
  Box scale only on playing-card destruction, and Sacrificial
  Lamb keeps only its playing-card half. The v1.1.0 ports
  (Unholy Alliance, OFF Switch's addons) use the event.
- OFF Switch now creates its real addons: Alpha, Epsilon and
  Omega are created Eternal, as on PC. Red Key creates a random
  Rare (the fork has no Ultra Secret rarity). Freezer creates a
  random Negative Common/Uncommon Joker (no Food pool exists).
- Permanent per-card bonuses ride the fields the fork's scoring
  actually reads (card_data.chip_bonus / mult_bonus / Bonus).
- Triple Moon Goddess uses its Minor-Arcana-enabled behavior,
  since this pack ships the Arcana.
- Showdown and The Normal Joker follow the PC defs where the
  audit data disagreed with them (Showdown's chance gate;
  The Normal Joker is Rare $8 as its def says).
Tier 3 (v1.1.0) deviations, also marked PORT NOTE in the code:
- Soaked pays the total Chip value of cards held in hand when it
  scores; the fork has no per-card held scoring pass, so its
  PC discard-a-card-to-destroy-a-scored-card half is unported.
  Sleeved is registered with its values only: a boss debuffing
  it on PC is a Blind predicate, and the fork gives enhancements
  no way to block destruction. Bandaged is likewise inert: the
  fork never asks an enhancement for repetitions or destruction
  vetoes, so its +1 repetition cannot fire (Gauze still applies
  it, and Medic stays unported below). Wrapped's plain $2
  scores; its no-rank / no-suit / always-scores traits cannot be
  expressed. Ceramic pays its random dollars; its
  shatter-into-two-copies half is unported (no such hook).
  Domino counts distinct ranks among the scoring cards; PC
  counts ranks played or discarded all round, tracked by a hook
  this snapshot does not contain. Antique grows and pays in its
  one scoring moment (PC grows in the before step).
- High Risk Tag pays only its $25: doubling the Boss Blind's
  score target has no handle at a tag moment. Cream Liqueur
  pays when a Tag is gained; PC pays when a Tag is activated,
  an event the fork does not raise (Stereoscopic Specs tracks
  gains the same way). Book of Life and Joker's 11 translate
  PC's end_of_round-plus-individual-hand combination, which the
  fork never raises, to the round-end and skip moments.
- One With Nothing destroys the unplayed held cards; PC
  discards them, and the fork has no discard-from-hand API.
- Da Capo and Jester of Nihil hold their debuffs as persistent
  per-card flags refreshed at blind selection and after each
  hand, instead of PC's continuous Blind predicates.
- Cross vetoes every playing-card destruction through the
  fork's destroying_card pass; PC also protects Jokers and
  consumables by name, which has no equivalent pass here.
  Unholy Alliance's 666-Chips revive is unported (the fork's
  Wave 1 game_over / saved context could carry it now, but the
  revive was not part of the v1.2.0 wave). Deck of Cards destroys its Antique card
  directly instead of through PC's destroy query. Ready to Fly
  reads the adjacent Jokers' XChips through the fork's
  post_trigger pass, without PC's context filtering.

Wave 1 (v1.2.0) deviations, also marked PORT NOTE in the code:
- Partial balance (Milk Tea, Stardrop): PC's plasma effect moves
  Chips and Mult each the given fraction of the way toward their
  AVERAGE, so the larger total falls (100 Chips / 20 Mult at 50%
  lands on 80/40). The fork's numeric balance return moves each
  total that fraction of the way toward the LARGER total, which
  stays put (the same example lands on 100/60). The fractions,
  triggers and Milk Tea's decay are PC's; only the balance target
  differs.
- The suit drinks (Grenadine, Nigori, Aperol) grant their perma
  fields in each card's individual pass, following the pack's
  earlier drink ports (Stout, Blue Curacao), rather than in PC's
  before pass: the fork reads a card's perma fields after its own
  scoring step, so a grant pays from the next hand the card
  scores. Freedom of Choice checks the hand at joker_main for the
  same reason (the fork's before context does not carry the
  contained hand types, so a Flush Five would not read as
  containing a Five of a Kind there). Aperol pays $1 per card:
  PC's shared drink helper seeds every field at 1, which would
  pay $2 against its own tooltip; the earlier flat drinks made
  the same call. Bergentrucking omits its Lager-destruction
  branch (Lager is unported, so it can never fire), and destroys
  its scored Hearts in the after pass like the pack's other
  destruction effects.
- Two of Swords converts to the last scored suit, tracked
  pack-side: on PC a global hook updates it on every scored
  card, but the fork raises scoring contexts only to held
  Jokers, so the port updates it from the individual passes of
  Bergentrucking, Pink Joker, Stardrop and Jester of Nihil.
  Until one of them has seen a card score this run it reads
  Spades, PC's initial value, and it is not saved with the run.
- Determination writes the Ante directly, clamped at 1 (the
  Punch Card precedent; the fork has no ante API), and its hand
  size cut rides the fork's persistent hand_size_delta field.
  Sacred Heart stashes the played hand's name at joker_main
  (the Journal pattern), since the fork's after context carries
  no hand name.

NOT PORTED (36 Jokers, each on its named blocker)
- Paperclips (4): Chip Clip, Clippy, Clothespin, Manilla Folder.
  On PC a paperclip is per-card state stored on the playing card
  itself (card.ability.paperback_<color>_clip), with eleven clip
  colors each running its own calculate at clip-specific
  contexts, plus run/round clip counters in G.GAME.paperback.
  The fork gives a card exactly one calculate-bearing modifier
  slot family (its enhancement or seal center); a clip would
  displace the card's enhancement, several clip contexts are
  never raised, and the counters have no persistence route.
- E.G.O Gifts (4): Arayashiki, Fodder, Grimoire, The Strongest.
  On PC these are not consumables: a gift is a held object with
  a passive calculation that fires while it sits in the
  consumable area, a sin affinity, the Corroded sticker system,
  its own booster packs and a custom sold_gift context. The
  fork's consumables only have can_use/use - no held passive,
  no stickers, no gift type.
- Custom rank Apostle (6): As Above So Below, In Case I Make It,
  One Sin and Hundreds of Good Deeds, Penumbra Phantasm, Plague
  Doctor, White Night. The fork still has no rank registrar.
- Enhancement-gated (2): Blood Rain (its PC def has no
  calculate at all - the effect lives in global hooks absent
  from this snapshot - and it replaces a scored card's Chips
  with its Mult), Medic (its only effect maintains the
  bandaged_inc counter feeding Bandaged repetitions, which the
  fork never queries).
- Shop / pool manipulation (9): Backpack, Membership Card,
  NormalJKR, Protocol, Shopping Center, Touch Tone Joker,
  Ouija Board (no shop price/rate APIs), plus Chaplin and
  Everything Must Go (no voucher grant/redeem API).
- Copy effects (3): Forgery, Master Plan, Photocopy (they ride
  SMODS.blueprint_effect, which the fork does not provide).
- Other single blockers: Burning Pact (draws cards; no
  draw-cards API), Jimbocards (writes the run's global inflation
  directly), Lager (grants a permanent per-card odds bonus with
  no reader; the fork's probability modifier is Joker-scoped
  and cannot outlive it), Nichola (scores held cards; no
  held-card scoring pass), The Sun Rises (modify_scoring_hand
  is still never raised), Ddakji and Vacation Juice (read and
  write G.GAME.paperback state systems), The World (hooks
  Card:calculate_joker and Blind:stay_flipped globally).
NOT PORTED - MINOR ARCANA (11 of 56)
- Paperclip Arcana (11): Ace of Cups, Ace of Wands, Three of
  Cups, Four of Wands, Page of Wands, Page of Cups, Six of
  Swords, Seven of Swords, Seven of Pentacles, Eight of Swords,
  Nine of Pentacles. Each applies a paperclip to selected
  cards; see the paperclip blocker above.

VALIDATION
Loaded through the real ModLoader and exercised in Balatro3DS's
own headless harness: main suite 41/41 (the original 36 Jokers'
behavior, the suits, the Spectrum hands through the game's own
classifier, the exotic gate), arcana suite 45/45 (type
registration, all 45 cards, the enhancement conversions, the
tag-granting cards, the boosters, Joker targeting, Two of
Swords), expansion suite 111/111 (registration, names, rarities,
costs and clean tooltips for all 280 Jokers, plus behavior tests
across the expansion Jokers, including all 45 Tier 3 additions
and the 14 Wave 1 behavior tests). Hardware testing is the
remaining step.

CREDITS
- Nether and contributors - Paperback, its Joker designs, text
  and art, the Stars and Crowns suits, the Spectrum hands and
  the Minor Arcana. Paperback is MIT License, Copyright (c)
  2025; the full license text ships in LICENSE.txt.
  https://github.com/Balatro-Paperback/paperback
- idkhan / Gazpacho - Balatro3DS and its mod API.
- sen2008 - the Balatro3DS fork (Tier 1/Tier 2/Tier 3 mod APIs).
- LocalThunk - Balatro.
