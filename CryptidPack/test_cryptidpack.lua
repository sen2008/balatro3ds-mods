--- Tests for the CryptidPack Balatro3DS mod (not part of the game repo).
--- The mod's real main file is read from the CRY_PACK_LUA env var.
local T = require("tests.testlib")
local bootstrap = require("tests.bootstrap")

local suite = T.suite()

bootstrap.load()
local ModLoader = require("mod_loader")

local function wipe_mods()
    local fs = love.filesystem
    local function rm(path)
        for _, item in ipairs(fs.getDirectoryItems(path)) do
            local child = path .. "/" .. item
            if fs.getInfo(child, "file") then fs.remove(child) else rm(child); fs.remove(child) end
        end
    end
    if fs.getInfo(ModLoader.DIR) then rm(ModLoader.DIR) end
    ModLoader.reset()
end

local JOKER_EXPECT = {
    ["dropshot"] = { name = "Dropshot", cost = 8, rarity = 3 },
    ["pot_of_jokes"] = { name = "Pot of Jokes", cost = 10, rarity = 3 },
    ["wee_fib"] = { name = "Weebonacci", cost = 9, rarity = 3 },
    ["whip"] = { name = "The WHIP", cost = 8, rarity = 2 },
    ["cursor"] = { name = "Cursor", cost = 5, rarity = 1 },
    ["cube"] = { name = "Cube", cost = 0, rarity = 1 },
    ["chili_pepper"] = { name = "Chili Pepper", cost = 6, rarity = 2 },
    ["compound_interest"] = { name = "Compound Interest", cost = 10, rarity = 3 },
    ["eternalflame"] = { name = "Eternal Flame", cost = 9, rarity = 3 },
    ["nice"] = { name = "Nice", cost = 6, rarity = 3 },
    ["seal_the_deal"] = { name = "Seal the Deal", cost = 5, rarity = 2 },
    ["chad"] = { name = "Chad", cost = 10, rarity = 3 },
    ["jimball"] = { name = "Jimball", cost = 9, rarity = 3 },
    ["sus"] = { name = "SUS", cost = 7, rarity = 3 },
    ["fspinner"] = { name = "Fidget Spinner", cost = 5, rarity = 1 },
    ["waluigi"] = { name = "Waluigi", cost = 20, rarity = 4 },
    ["wario"] = { name = "Wario", cost = 20, rarity = 4 },
    ["krustytheclown"] = { name = "Krusty the Clown", cost = 7, rarity = 2 },
    ["blurred"] = { name = "Blurred Joker", cost = 4, rarity = 1 },
    ["gardenfork"] = { name = "Garden of Forking Paths", cost = 7, rarity = 3 },
    ["lightupthenight"] = { name = "Light Up the Night", cost = 7, rarity = 3 },
    ["nosound"] = { name = "No Sound, No Memory", cost = 7, rarity = 3 },
    ["hunger"] = { name = "Consume-able", cost = 6, rarity = 2 },
    ["weegaming"] = { name = "2D", cost = 5, rarity = 1 },
    ["redbloon"] = { name = "Red Bloon", cost = 4, rarity = 1 },
    ["apjoker"] = { name = "AP Joker", cost = 6, rarity = 2 },
    ["panopticon"] = { name = "Panopticon", cost = 1, rarity = 1 },
    ["magnet"] = { name = "Fridge Magnet", cost = 6, rarity = 1 },
    ["unjust_dagger"] = { name = "Unjust Dagger", cost = 8, rarity = 2 },
    ["monkey_dagger"] = { name = "Monkey Dagger", cost = 6, rarity = 2 },
    ["mondrian"] = { name = "Mondrian", cost = 7, rarity = 2 },
    ["sapling"] = { name = "Sapling", cost = 6, rarity = 2 },
    ["happy"] = { name = ":D", cost = 2, rarity = 1 },
    ["meteor"] = { name = "Meteor Shower", cost = 4, rarity = 1 },
    ["exoplanet"] = { name = "Exoplanet", cost = 3, rarity = 1 },
    ["stardust"] = { name = "Stardust", cost = 2, rarity = 1 },
    ["filler"] = { name = "The Filler", cost = 1, rarity = 3 },
    ["nuts"] = { name = "The Nuts", cost = 8, rarity = 3 },
    ["quintet"] = { name = "The Quintet", cost = 8, rarity = 3 },
    ["unity"] = { name = "The Unity", cost = 8, rarity = 3 },
    ["swarm"] = { name = "The Swarm", cost = 8, rarity = 3 },
    ["stronghold"] = { name = "The Stronghold", cost = 8, rarity = 3 },
    ["clash"] = { name = "The Clash", cost = 8, rarity = 3 },
    ["manic"] = { name = "Manic Joker", cost = 4, rarity = 1 },
    ["silly"] = { name = "Silly Joker", cost = 4, rarity = 1 },
    ["delirious"] = { name = "Delirious Joker", cost = 4, rarity = 1 },
    ["wacky"] = { name = "Wacky Joker", cost = 4, rarity = 1 },
    ["kooky"] = { name = "Kooky Joker", cost = 4, rarity = 1 },
    ["bonkers"] = { name = "Bonkers Joker", cost = 4, rarity = 1 },
    ["foolhardy"] = { name = "Foolhardy Joker", cost = 4, rarity = 1 },
    ["tricksy"] = { name = "Tricksy Joker", cost = 4, rarity = 1 },
    ["foxy"] = { name = "Foxy Joker", cost = 4, rarity = 1 },
    ["savvy"] = { name = "Savvy Joker", cost = 4, rarity = 1 },
    ["subtle"] = { name = "Subtle Joker", cost = 4, rarity = 1 },
    ["discreet"] = { name = "Discreet Joker", cost = 4, rarity = 1 },
    ["adroit"] = { name = "Adroit Joker", cost = 4, rarity = 1 },
    ["treacherous"] = { name = "Treacherous Joker", cost = 4, rarity = 1 },
    ["coin"] = { name = "Crypto Coin", cost = 5, rarity = 1 },
    ["wheelhope"] = { name = "Wheel of Hope", cost = 5, rarity = 2 },
    ["busdriver"] = { name = "Bus Driver", cost = 7, rarity = 2 },
    ["translucent"] = { name = "Translucent Joker", cost = 4, rarity = 1 },
    ["morse"] = { name = "Morse Code", cost = 5, rarity = 1 },
    ["kscope"] = { name = "Kaleidoscope", cost = 7, rarity = 3 },
    ["cryptidmoment"] = { name = "M Chain", cost = 4, rarity = 1 },
    ["oldinvisible"] = { name = "Nostalgic Invisible Joker", cost = 20, rarity = 4 },
    ["kittyprinter"] = { name = "Kitty Printer", cost = 6, rarity = 2 },
    ["exposed"] = { name = "Exposed", cost = 8, rarity = 3 },
    ["mask"] = { name = "Mask", cost = 7, rarity = 3 },
    ["clicked_cookie"] = { name = "Clicked Cookie", cost = 4, rarity = 1 },
    ["tax_fraud"] = { name = "Tax Fraud", cost = 10, rarity = 3 },
    ["zooble"] = { name = "Zooble", cost = 6, rarity = 2 },
    ["lebaron_james"] = { name = "LeBaron James", cost = 6, rarity = 3 },
    ["eyeofhagane"] = { name = "Eye of Hagane", cost = 6, rarity = 2 },
    ["highfive"] = { name = "High Five", cost = 5, rarity = 3 },
    ["brokenhome"] = { name = "Broken Home", cost = 8, rarity = 3 },
    ["pizza"] = { name = "Pizza", cost = 8, rarity = 3 },
    ["pizza_slice"] = { name = "Pizza Slice", cost = 8, rarity = 3 },
    ["fading_joker"] = { name = "Fading Joker", cost = 6, rarity = 2 },
    ["poor_joker"] = { name = "Poor Joker", cost = 6, rarity = 2 },
    ["thalia"] = { name = "Thalia and Melpomeme", cost = 20, rarity = 4 },
    ["keychange"] = { name = "Key Change", cost = 5, rarity = 2 },
    ["negative"] = { name = "Negative Joker", cost = 10, rarity = "epic" },
    ["canvas"] = { name = "Canvas", cost = 18, rarity = "epic" },
    ["m"] = { name = "m", cost = 13, rarity = "epic" },
    ["M"] = { name = "M", cost = 13, rarity = "epic" },
    ["boredom"] = { name = "Boredom", cost = 14, rarity = "epic" },
    ["circus"] = { name = "Circus", cost = 16, rarity = "epic" },
    ["caramel"] = { name = "Caramel", cost = 12, rarity = "epic" },
    ["curse_sob"] = { name = "Sob", cost = 9, rarity = "epic" },
    ["multjoker"] = { name = "Mult Joker", cost = 11, rarity = "epic" },
    ["goldjoker"] = { name = "Gold Joker", cost = 14, rarity = "epic" },
    ["soccer"] = { name = "One for All", cost = 20, rarity = "epic" },
    ["demicolon"] = { name = "Demicolon", cost = 14, rarity = "epic" },
    ["iterum"] = { name = "Iterum", cost = 50, rarity = "exotic" },
    ["speculo"] = { name = "Speculo", cost = 50, rarity = "exotic" },
    ["redeo"] = { name = "Redeo", cost = 50, rarity = "exotic" },
    ["tenebris"] = { name = "Tenebris", cost = 50, rarity = "exotic" },
    ["crustulum"] = { name = "Crustulum", cost = 50, rarity = "exotic" },
    ["verisimile"] = { name = "Non Verisimile", cost = 50, rarity = "exotic" },
    ["duplicare"] = { name = "Duplicare", cost = 50, rarity = "exotic" },
    ["CodeJoker"] = { name = "Code Joker", cost = 11, rarity = "epic" },
    ["copypaste"] = { name = "Copy/Paste", cost = 14, rarity = "epic" },
    ["cut"] = { name = "Cut", cost = 7, rarity = 2 },
    ["blender"] = { name = "Blender", cost = 5, rarity = 1 },
    ["python"] = { name = "Python", cost = 7, rarity = 2 },
    ["jollysus"] = { name = "Jolly Joker?", cost = 4, rarity = 1 },
    ["bubblem"] = { name = "Bubble M", cost = 2, rarity = 1 },
    ["foodm"] = { name = "Fast Food M", cost = 5, rarity = 1 },
    ["mstack"] = { name = "M Stack", cost = 7, rarity = 3 },
    ["mneon"] = { name = "Neon M", cost = 7, rarity = 2 },
    ["notebook"] = { name = "Motebook", cost = 9, rarity = 3 },
    ["bonk"] = { name = "Bonk", cost = 5, rarity = 2 },
    ["loopy"] = { name = "Loopy", cost = 4, rarity = 1 },
    ["scrabble"] = { name = "Scrabble Tile", cost = 8, rarity = 2 },
    ["sacrifice"] = { name = "Sacrifice", cost = 4, rarity = 1 },
    ["reverse"] = { name = "Reverse Card", cost = 4, rarity = 2 },
    ["doodlem"] = { name = "Doodle M", cost = 13, rarity = "epic" },
    ["virgo"] = { name = "Virgo", cost = 8, rarity = "epic" },
    ["biggestm"] = { name = "Huge", cost = 12, rarity = "epic" },
    ["macabre"] = { name = "Macabre Joker", cost = 5, rarity = 1 },
    ["megg"] = { name = "Megg", cost = 4, rarity = 1 },
    ["longboi"] = { name = "Monster", cost = 5, rarity = 1 },
    ["cotton_candy"] = { name = "Cotton Candy", cost = 10, rarity = "candy" },
    ["wrapped"] = { name = "Wrapped Candy", cost = 10, rarity = "candy" },
    ["trick_or_treat"] = { name = "Trick-or-Treat", cost = 5, rarity = 2 },
    ["candy_basket"] = { name = "Candy Basket", cost = 6, rarity = 2 },
    ["rotten_egg"] = { name = "Rotten Egg", cost = 0, rarity = "cursed" },
    ["candy_dagger"] = { name = "Candy Dagger", cost = 8, rarity = 2 },
    ["candy_cane"] = { name = "Candy Cane", cost = 10, rarity = "candy" },
    ["candy_buttons"] = { name = "Candy Buttons", cost = 10, rarity = "candy" },
    ["mellowcreme"] = { name = "Mellowcreme", cost = 10, rarity = "candy" },
    ["brittle"] = { name = "Brittle Candy", cost = 10, rarity = "candy" },
    ["monopoly_money"] = { name = "Monopoly Money", cost = 0, rarity = "cursed" },
    ["dubious"] = { name = "Dubious Joker", cost = 1, rarity = 1 },
    ["absurd"] = { name = "Absurd Joker", cost = 1, rarity = 1 },
    ["shrewd"] = { name = "Shrewd Joker", cost = 4, rarity = 1 },
    ["nutty"] = { name = "Nutty Joker", cost = 4, rarity = 1 },
    ["the_duos"] = { name = "The Duos", cost = 8, rarity = 3 },
    ["the_home"] = { name = "The Home", cost = 8, rarity = 3 },
    ["triplet_rhythm"] = { name = "Triplet Rhythm", cost = 6, rarity = 1 },
    ["circulus_pistoris"] = { name = "Circulus Pistoris", cost = 31, rarity = "exotic" },
    ["facile"] = { name = "Facile", cost = 50, rarity = "exotic" },
    ["primus"] = { name = "Primus", cost = 53, rarity = "exotic" },
    ["stella_mortis"] = { name = "Stella Mortis", cost = 50, rarity = "exotic" },
    ["formidiulosus"] = { name = "Formidiulosus", cost = 50, rarity = "exotic" },
    ["mprime"] = { name = "Tredecim", cost = 50, rarity = "exotic" },
    ["energia"] = { name = "Energia", cost = 50, rarity = "exotic" },
    ["happyhouse"] = { name = "Happy House", cost = 2, rarity = 2 },
    ["night"] = { name = "Night", cost = 6, rarity = 3 },
    ["jtron"] = { name = "Jimbo-tron 9000", cost = 14, rarity = "epic" },
    ["starfruit"] = { name = "Starfruit", cost = 14, rarity = "epic" },
    ["googol_play"] = { name = "Googol Play Card", cost = 10, rarity = "epic" },
    ["supercell"] = { name = "Supercell", cost = 14, rarity = "epic" },
    ["sync_catalyst"] = { name = "Sync Catalyst", cost = 12, rarity = "epic" },
    ["smallestm"] = { name = "Tiny", cost = 8, rarity = "epic" },
    ["universe"] = { name = "Universe", cost = 6, rarity = 3 },
    ["antennatoheaven"] = { name = "...Like Antennas to Heaven", cost = 7, rarity = 3 },
    ["big_cube"] = { name = "Big Cube", cost = 27, rarity = 1 },
    ["spaceglobe"] = { name = "Celestial Globe", cost = 8, rarity = 3 },
    ["pirate_dagger"] = { name = "Pirate Dagger", cost = 8, rarity = 2 },
    ["arsonist"] = { name = "Arsonist", cost = 5, rarity = 3 },
    ["queens_gambit"] = { name = "Queen's Gambit", cost = 7, rarity = 1 },
    ["huntingseason"] = { name = "Hunting Season", cost = 7, rarity = 2 },
    ["astral_bottle"] = { name = "Astral in a Bottle", cost = 6, rarity = 2 },
    ["pickle"] = { name = "Pickle", cost = 6, rarity = 2 },
    ["pity_prize"] = { name = "Pity Prize", cost = 2, rarity = 1 },
    ["yarnball"] = { name = "Yarn Ball", cost = 8, rarity = 3 },
    ["kidnap"] = { name = "Kidnapping", cost = 4, rarity = 1 },
    ["necromancer"] = { name = "Necromancer", cost = 5, rarity = 2 },
    ["pumpkin"] = { name = "Pumpkin", cost = 10, rarity = 3 },
    ["carved_pumpkin"] = { name = "Carved Pumpkin", cost = 10, rarity = 3 },
    ["familiar_currency"] = { name = "Familiar Currency", cost = 0, rarity = 3 },
}

local CONSUMABLE_EXPECT = {
    ["ctrl_v"] = { name = "://CTRL+V", set = "Code", cost = 4 },
    ["automaton"] = { name = "The Automaton", set = "Tarot", cost = nil },
    ["asteroidbelt"] = { name = "Asteroid Belt", set = "Planet", cost = nil },
    ["marsmoons"] = { name = "Phobos & Deimos", set = "Planet", cost = nil },
    ["planetlua"] = { name = "Planet.lua", set = "Planet", cost = 4 },
    ["nstar"] = { name = "Neutron Star", set = "Planet", cost = 4 },
    ["Timantii"] = { name = "Ruutu", set = "Planet", cost = 4 },
    ["Klubi"] = { name = "Risti", set = "Planet", cost = 4 },
    ["Sydan"] = { name = "Hertta", set = "Planet", cost = 4 },
    ["Lapio"] = { name = "Pata", set = "Planet", cost = 4 },
    ["Kaikki"] = { name = "Kaikki", set = "Planet", cost = 4 },
    ["lock"] = { name = "Lock", set = "Spectral", cost = 4 },
    ["vacuum"] = { name = "Vacuum", set = "Spectral", cost = 4 },
    ["replica"] = { name = "Replica", set = "Spectral", cost = 4 },
    ["analog"] = { name = "Analog", set = "Spectral", cost = 4 },
    ["adversary"] = { name = "Adversary", set = "Spectral", cost = 4 },
    ["chambered"] = { name = "Chambered", set = "Spectral", cost = 4 },
    ["conduit"] = { name = "Conduit", set = "Spectral", cost = 4 },
    ["white_hole"] = { name = "White Hole", set = "Spectral", cost = 4 },
    ["summoning"] = { name = "Summoning", set = "Spectral", cost = 4 },
    ["theblessing"] = { name = "The Blessing", set = "Tarot", cost = 3 },
    ["gateway"] = { name = "Gateway", set = "Spectral", cost = 4 },
    ["source"] = { name = "Source", set = "Spectral", cost = 4 },
    ["typhoon"] = { name = "Typhoon", set = "Spectral", cost = 4 },
    ["ritual"] = { name = "Ritual", set = "Spectral", cost = 5 },
    ["commit"] = { name = "://COMMIT", set = "Code", cost = 4 },
    ["rework"] = { name = "://REWORK", set = "Code", cost = 4 },
    ["alttab"] = { name = "://ALTTAB", set = "Code", cost = 4 },
}

local SPRITE_STEMS = {
    "CodeJoker",
    "CodeJoker_negative",
    "Kaikki",
    "Kaikki_negative",
    "Klubi",
    "Klubi_negative",
    "Lapio",
    "Lapio_negative",
    "M",
    "M_negative",
    "Sydan",
    "Sydan_negative",
    "Timantii",
    "Timantii_negative",
    "absurd",
    "absurd_negative",
    "adroit",
    "adroit_negative",
    "adversary",
    "adversary_negative",
    "analog",
    "analog_negative",
    "apjoker",
    "apjoker_negative",
    "asteroidbelt",
    "asteroidbelt_negative",
    "automaton",
    "automaton_negative",
    "biggestm",
    "biggestm_negative",
    "blender",
    "blender_negative",
    "blurred",
    "blurred_negative",
    "bonk",
    "bonk_negative",
    "bonkers",
    "bonkers_negative",
    "boredom",
    "boredom_negative",
    "brittle",
    "brittle_negative",
    "brokenhome",
    "brokenhome_negative",
    "bubblem",
    "bubblem_negative",
    "busdriver",
    "busdriver_negative",
    "candy_basket",
    "candy_basket_negative",
    "candy_buttons",
    "candy_buttons_negative",
    "candy_cane",
    "candy_cane_negative",
    "candy_dagger",
    "candy_dagger_negative",
    "canvas",
    "canvas_negative",
    "caramel",
    "caramel_negative",
    "chad",
    "chad_negative",
    "chambered",
    "chambered_negative",
    "chili_pepper",
    "chili_pepper_negative",
    "circus",
    "circus_negative",
    "clash",
    "clash_negative",
    "clicked_cookie",
    "clicked_cookie_negative",
    "coin",
    "coin_negative",
    "compound_interest",
    "compound_interest_negative",
    "conduit",
    "conduit_negative",
    "copypaste",
    "copypaste_negative",
    "cotton_candy",
    "cotton_candy_negative",
    "crustulum",
    "crustulum_negative",
    "crustulum_soul",
    "cryptidmoment",
    "cryptidmoment_negative",
    "ctrl_v",
    "ctrl_v_negative",
    "cube",
    "cube_negative",
    "curse_sob",
    "curse_sob_negative",
    "cursor",
    "cursor_negative",
    "cut",
    "cut_negative",
    "delirious",
    "delirious_negative",
    "demicolon",
    "demicolon_negative",
    "discreet",
    "discreet_negative",
    "doodlem",
    "doodlem_negative",
    "dropshot",
    "dropshot_negative",
    "dubious",
    "dubious_negative",
    "duplicare",
    "duplicare_negative",
    "duplicare_soul",
    "eternalflame",
    "eternalflame_negative",
    "exoplanet",
    "exoplanet_negative",
    "exposed",
    "exposed_negative",
    "eyeofhagane",
    "eyeofhagane_negative",
    "fading_joker",
    "fading_joker_negative",
    "filler",
    "filler_negative",
    "foodm",
    "foodm_negative",
    "foolhardy",
    "foolhardy_negative",
    "foxy",
    "foxy_negative",
    "fspinner",
    "fspinner_negative",
    "gardenfork",
    "gardenfork_negative",
    "gateway",
    "gateway_negative",
    "goldjoker",
    "goldjoker_negative",
    "happy",
    "happy_negative",
    "highfive",
    "highfive_negative",
    "hunger",
    "hunger_negative",
    "iterum",
    "iterum_negative",
    "iterum_soul",
    "jimball",
    "jimball_negative",
    "jollysus",
    "jollysus_negative",
    "keychange",
    "keychange_negative",
    "kittyprinter",
    "kittyprinter_negative",
    "kooky",
    "kooky_negative",
    "krustytheclown",
    "krustytheclown_negative",
    "kscope",
    "kscope_negative",
    "lebaron_james",
    "lebaron_james_negative",
    "lightupthenight",
    "lightupthenight_negative",
    "lock",
    "lock_negative",
    "longboi",
    "longboi_negative",
    "loopy",
    "loopy_negative",
    "m",
    "m_negative",
    "macabre",
    "macabre_negative",
    "magnet",
    "magnet_negative",
    "manic",
    "manic_negative",
    "marsmoons",
    "marsmoons_negative",
    "mask",
    "mask_negative",
    "megg",
    "megg_negative",
    "mellowcreme",
    "mellowcreme_negative",
    "meteor",
    "meteor_negative",
    "mneon",
    "mneon_negative",
    "mondrian",
    "mondrian_negative",
    "monkey_dagger",
    "monkey_dagger_negative",
    "monopoly_money",
    "monopoly_money_negative",
    "morse",
    "morse_negative",
    "mstack",
    "mstack_negative",
    "multjoker",
    "multjoker_negative",
    "negative",
    "negative_negative",
    "nice",
    "nice_negative",
    "nosound",
    "nosound_negative",
    "notebook",
    "notebook_negative",
    "nstar",
    "nstar_negative",
    "nuts",
    "nuts_negative",
    "nutty",
    "nutty_negative",
    "oldinvisible",
    "oldinvisible_negative",
    "panopticon",
    "panopticon_negative",
    "pizza",
    "pizza_negative",
    "pizza_slice",
    "pizza_slice_negative",
    "planetlua",
    "planetlua_negative",
    "poor_joker",
    "poor_joker_negative",
    "pot_of_jokes",
    "pot_of_jokes_negative",
    "python",
    "python_negative",
    "quintet",
    "quintet_negative",
    "redbloon",
    "redbloon_negative",
    "redeo",
    "redeo_negative",
    "redeo_soul",
    "replica",
    "replica_negative",
    "reverse",
    "reverse_negative",
    "rotten_egg",
    "rotten_egg_negative",
    "sacrifice",
    "sacrifice_negative",
    "sapling",
    "sapling_negative",
    "savvy",
    "savvy_negative",
    "scrabble",
    "scrabble_negative",
    "seal_the_deal",
    "seal_the_deal_negative",
    "shrewd",
    "shrewd_negative",
    "silly",
    "silly_negative",
    "soccer",
    "soccer_negative",
    "speculo",
    "speculo_negative",
    "speculo_soul",
    "stardust",
    "stardust_negative",
    "stronghold",
    "stronghold_negative",
    "subtle",
    "subtle_negative",
    "summoning",
    "summoning_negative",
    "sus",
    "sus_negative",
    "swarm",
    "swarm_negative",
    "tax_fraud",
    "tax_fraud_negative",
    "tenebris",
    "tenebris_negative",
    "tenebris_soul",
    "thalia",
    "thalia_negative",
    "thalia_soul",
    "the_duos",
    "the_duos_negative",
    "the_home",
    "the_home_negative",
    "theblessing",
    "theblessing_negative",
    "translucent",
    "translucent_negative",
    "treacherous",
    "treacherous_negative",
    "trick_or_treat",
    "trick_or_treat_negative",
    "tricksy",
    "tricksy_negative",
    "triplet_rhythm",
    "triplet_rhythm_negative",
    "unity",
    "unity_negative",
    "unjust_dagger",
    "unjust_dagger_negative",
    "vacuum",
    "vacuum_negative",
    "verisimile",
    "verisimile_negative",
    "verisimile_soul",
    "virgo",
    "virgo_negative",
    "virgo_soul",
    "wacky",
    "wacky_negative",
    "waluigi",
    "waluigi_negative",
    "waluigi_soul",
    "wario",
    "wario_negative",
    "wario_soul",
    "wee_fib",
    "wee_fib_negative",
    "weegaming",
    "weegaming_negative",
    "wheelhope",
    "wheelhope_negative",
    "whip",
    "whip_negative",
    "white_hole",
    "white_hole_negative",
    "wrapped",
    "wrapped_negative",
    "zooble",
    "zooble_negative",
    "antennatoheaven",
    "antennatoheaven_negative",
    "arsonist",
    "arsonist_negative",
    "astral_bottle",
    "astral_bottle_negative",
    "big_cube",
    "big_cube_negative",
    "circulus_pistoris",
    "circulus_pistoris_negative",
    "circulus_pistoris_soul",
    "commit",
    "commit_negative",
    "cry_astral",
    "cry_astral_negative",
    "cry_azure",
    "cry_azure_negative",
    "cry_cat",
    "cry_cat_negative",
    "cry_double_m",
    "cry_double_m_negative",
    "cry_green",
    "cry_green_negative",
    "cry_m",
    "cry_m_negative",
    "cry_mosaic",
    "cry_mosaic_negative",
    "cry_rework",
    "cry_rework_negative",
    "energia",
    "energia_negative",
    "energia_soul",
    "facile",
    "facile_negative",
    "facile_soul",
    "formidiulosus",
    "formidiulosus_negative",
    "formidiulosus_soul",
    "googol_play",
    "googol_play_negative",
    "happyhouse",
    "happyhouse_negative",
    "huntingseason",
    "huntingseason_negative",
    "jtron",
    "jtron_negative",
    "mprime",
    "mprime_negative",
    "mprime_soul",
    "night",
    "night_negative",
    "pickle",
    "pickle_negative",
    "pirate_dagger",
    "pirate_dagger_negative",
    "pity_prize",
    "pity_prize_negative",
    "primus",
    "primus_negative",
    "primus_soul",
    "queens_gambit",
    "queens_gambit_negative",
    "rework",
    "rework_negative",
    "ritual",
    "ritual_negative",
    "smallestm",
    "smallestm_negative",
    "source",
    "source_negative",
    "spaceglobe",
    "spaceglobe_negative",
    "starfruit",
    "starfruit_negative",
    "stella_mortis",
    "stella_mortis_negative",
    "stella_mortis_soul",
    "supercell",
    "supercell_negative",
    "sync_catalyst",
    "sync_catalyst_negative",
    "typhoon",
    "typhoon_negative",
    "universe",
    "universe_negative",
    "yarnball",
    "yarnball_negative",
    "kidnap",
    "kidnap_negative",
    "necromancer",
    "necromancer_negative",
    "pumpkin",
    "pumpkin_negative",
    "carved_pumpkin",
    "carved_pumpkin_negative",
    "familiar_currency",
    "familiar_currency_negative",
    "alttab",
    "alttab_negative",
}


local function install_pack()
    wipe_mods()
    local path = os.getenv("CRY_PACK_LUA")
    assert(path, "CRY_PACK_LUA not set")
    local fh = assert(io.open(path, "rb"))
    local main = fh:read("*a")
    fh:close()
    local base = ModLoader.DIR .. "/CryptidPack"
    love.filesystem.createDirectory(base)
    love.filesystem.write(base .. "/CryptidPack.json", [[{
        "id": "CryptidPack", "name": "Cryptid Pack", "prefix": "cryp",
        "main_file": "cryptidpack.lua", "version": "1.3.0",
        "author": ["Cryptid team", "3DS port"]
    }]])
    love.filesystem.write(base .. "/cryptidpack.lua", main)
    for _, n in ipairs(SPRITE_STEMS) do
        love.filesystem.write(base .. "/assets/1x/" .. n .. ".png", "png")
    end
    ModLoader.load_all()
    local game = bootstrap.new_game(7740)
    G = game
    G.play = G.play or SMODS.PLAY
    _G.Top = _G.Top or { addPopup = function() end }
    return game
end

-- Full install for consumable tests: hand/deck/consumable areas set up
-- the way the Paperback suites do it.
local function install_pack_full()
    local game = install_pack()
    game.hand = Hand(game)
    game.deck = Deck(game)
    game.consumables, game.consumable_nodes = {}, {}
    game.jokers = {}
    return game
end

local function add(game, id)
    game.jokers = game.jokers or {}
    T.assert_true(game:add_joker_by_def(id), id .. " should be addable")
    return game.jokers[#game.jokers]
end

local function card(rank, suit, enhancement)
    local data = { rank = rank, suit = suit or "Hearts" }
    if enhancement then data.enhancement = enhancement end
    local c = Card(0, 0, 1, 1, data)
    c.counts_for_play_score = true
    return c
end

local function fire(joker, event_name, extra)
    local ctx = { event = event_name, event_name = event_name, chips = 10, mult = 2 }
    for k, v in pairs(extra or {}) do ctx[k] = v end
    ctx.cards = ctx.cards or ctx.played_cards
    if joker:matches_trigger(event_name, ctx) then joker:apply_effect(ctx) end
    return ctx
end

local function scored(joker, extra)
    return fire(joker, "on_hand_scored", extra)
end

-- Drive a per-card scored context (card_played is the individual pipeline).
local function play_card(joker, node, played)
    local ctx = { event = "card_played", event_name = "card_played", chips = 0, mult = 1,
        rank = node.card_data.rank, suit = node.card_data.suit, card_node = node,
        played_cards = played, full_hand = played }
    if joker:matches_trigger("card_played", ctx) then joker:apply_effect(ctx) end
    return ctx
end

local function flatten(t, out)
    out = out or {}
    if type(t) == "string" then out[#out + 1] = t
    elseif type(t) == "table" then
        if type(t.text) == "string" then out[#out + 1] = t.text end
        for _, v in pairs(t) do if type(v) == "table" then flatten(v, out) end end
    end
    return out
end

local function hand_index(game, name)
    for i, n in ipairs(game.handlist) do if n == name then return i end end
    return nil
end

--------------------------------------------------------------------------------
-- Registration: rarities, hands, consumable types, every item + tooltips
--------------------------------------------------------------------------------

suite.test("pack loads: 172 Jokers, 28 consumables, rarities, hands, types", function()
    local game = install_pack()
    local mod = ModLoader.by_id.CryptidPack
    T.assert_eq(mod.status, "loaded", tostring(mod.error))
    T.assert_eq(#mod.registered.jokers, 172, "172 Jokers register")
    T.assert_eq(#mod.registered.consumables, 28, "28 consumables register")

    T.assert_eq(SMODS.Rarities["cryp_epic"].weight, 0.3, "epic weight")
    T.assert_eq(SMODS.Rarities["cryp_exotic"].weight, 0, "exotic weight 0 (never in shop)")
    T.assert_eq(SMODS.Rarities["cryp_candy"].weight, 3, "candy weight")
    T.assert_eq(SMODS.Rarities["cryp_cursed"].weight, 3, "cursed weight")

    T.assert_true(hand_index(game, "Bulwark") ~= nil, "Bulwark is in the hand list")
    T.assert_true(hand_index(game, "UltPair") ~= nil, "UltPair is in the hand list")
    local bw = game.hand_stats[hand_index(game, "Bulwark")]
    T.assert_eq(bw.base_chips, 100, "Bulwark base chips")
    T.assert_eq(bw.base_mult, 10, "Bulwark base mult")
    local up = game.hand_stats[hand_index(game, "UltPair")]
    T.assert_eq(up.base_chips, 220, "UltPair base chips")
    T.assert_eq(up.base_mult, 22, "UltPair base mult")

    T.assert_true(game:is_consumable_kind("Code"), "Code is a consumable kind")
    T.assert_true(game:is_consumable_kind("Unique"), "Unique is a consumable kind")

    for key, e in pairs(JOKER_EXPECT) do
        local id = "j_cryp_" .. key
        local def = JOKER_DEFS[id]
        T.assert_true(def ~= nil, id .. " registered")
        T.assert_eq(def.name, e.name, id .. " name")
        if e.cost then T.assert_eq(def.cost, e.cost, id .. " cost") end
        if type(e.rarity) == "number" then
            T.assert_eq(def.rarity, e.rarity, id .. " rarity")
        elseif type(e.rarity) == "string" then
            local entry = SMODS.Rarities["cryp_" .. e.rarity]
            T.assert_true(entry ~= nil, id .. " rarity registered")
            T.assert_eq(def.rarity, entry.index, id .. " custom rarity resolves")
        end
    end
    for key, e in pairs(CONSUMABLE_EXPECT) do
        local id = "c_cryp_" .. key
        local def = CONSUMABLE_DEFS[id]
        T.assert_true(def ~= nil, id .. " registered")
        T.assert_eq(def.name, e.name, id .. " name")
        local kind = e.set == "Code" and "Code" or (e.set == "Unique" and "Unique")
            or string.lower(e.set)
        T.assert_eq(def.kind, kind, id .. " kind")
        if e.cost then T.assert_eq(def.cost, e.cost, id .. " cost") end
    end
    wipe_mods()
end)

suite.test("every ported Joker and consumable has a clean tooltip", function()
    local game = install_pack()
    for key in pairs(JOKER_EXPECT) do
        game.jokers = {}
        local j = add(game, "j_cryp_" .. key)
        local lines = SMODS.tooltip_lines("j_cryp_" .. key, j)
        T.assert_true(type(lines) == "table" and #lines >= 1, key .. " tooltip has lines")
        local text = table.concat(flatten(lines), " ")
        T.assert_true(text:find("#", 1, true) == nil, key .. " tooltip has no raw placeholder: " .. text)
    end
    for key in pairs(CONSUMABLE_EXPECT) do
        local lines = SMODS.tooltip_lines("c_cryp_" .. key, nil)
        T.assert_true(type(lines) == "table" and #lines >= 1, key .. " tooltip has lines")
        local text = table.concat(flatten(lines), " ")
        T.assert_true(text:find("#", 1, true) == nil, key .. " tooltip has no raw placeholder: " .. text)
    end
    wipe_mods()
end)

--------------------------------------------------------------------------------
-- The original seven (behavior kept from the v1.0.0 suite)
--------------------------------------------------------------------------------

suite.test("dubious and absurd pay on every hand, as on PC", function()
    local game = install_pack()
    local dubious = add(game, "j_cryp_dubious")
    local absurd = add(game, "j_cryp_absurd")
    local pair = { card(4), card(4, "Spades") }
    T.assert_eq(scored(dubious, { played_cards = pair }).chips, 30, "+20 Chips on a Pair")
    T.assert_eq(scored(absurd, { played_cards = pair }).mult, 6, "+4 Mult on a Pair")
    local high = { card(14) }
    T.assert_eq(scored(dubious, { played_cards = high }).chips, 30, "+20 Chips on High Card")
    T.assert_eq(scored(absurd, { played_cards = high }).mult, 6, "+4 Mult on High Card")
    wipe_mods()
end)

suite.test("shrewd and nutty pay on Four of a Kind only", function()
    local game = install_pack()
    local shrewd = add(game, "j_cryp_shrewd")
    local nutty = add(game, "j_cryp_nutty")
    local quads = { card(9), card(9, "Spades"), card(9, "Clubs"), card(9, "Diamonds") }
    local four = { ["Four of a Kind"] = true }
    T.assert_eq(scored(shrewd, { played_cards = quads, contains_hand_types = four }).chips, 160, "+150 Chips")
    T.assert_eq(scored(nutty, { played_cards = quads, contains_hand_types = four }).mult, 21, "+19 Mult")
    local pair = { card(4), card(4, "Spades") }
    T.assert_eq(scored(shrewd, { played_cards = pair, contains_hand_types = { Pair = true } }).chips, 10, "Pair pays nothing")
    T.assert_eq(scored(nutty, { played_cards = pair, contains_hand_types = { Pair = true } }).mult, 2, "Pair pays nothing")
    wipe_mods()
end)

suite.test("the duos pays on Two Pair and on a Full House", function()
    local game = install_pack()
    local duos = add(game, "j_cryp_the_duos")
    local tp = { card(4), card(4, "Spades"), card(9), card(9, "Clubs") }
    T.assert_near(scored(duos, { played_cards = tp, contains_hand_types = { ["Two Pair"] = true } }).mult, 5, 0.001, "X2.5 on Two Pair")
    local fh = { card(4), card(4, "Spades"), card(4, "Clubs"), card(9), card(9, "Clubs") }
    T.assert_near(scored(duos, { played_cards = fh, contains_hand_types = { ["Two Pair"] = true, ["Three of a Kind"] = true }, hand_type = "Full House" }).mult, 5, 0.001, "X2.5 on a Full House")
    local pair = { card(4), card(4, "Spades") }
    T.assert_eq(scored(duos, { played_cards = pair, contains_hand_types = { Pair = true } }).mult, 2, "a single Pair pays nothing")
    wipe_mods()
end)

suite.test("the home pays on a Full House only", function()
    local game = install_pack()
    local home = add(game, "j_cryp_the_home")
    local fh = { card(4), card(4, "Spades"), card(4, "Clubs"), card(9), card(9, "Clubs") }
    T.assert_near(scored(home, { played_cards = fh, contains_hand_types = { ["Two Pair"] = true, ["Three of a Kind"] = true }, hand_type = "Full House" }).mult, 7, 0.001, "X3.5 on a Full House")
    local tp = { card(4), card(4, "Spades"), card(9), card(9, "Clubs") }
    T.assert_eq(scored(home, { played_cards = tp, contains_hand_types = { ["Two Pair"] = true }, hand_type = "Two Pair" }).mult, 2, "Two Pair pays nothing")
    wipe_mods()
end)

suite.test("triplet rhythm needs exactly three 3s in the scoring hand", function()
    local game = install_pack()
    local tr = add(game, "j_cryp_triplet_rhythm")
    local three = { card(3), card(3, "Spades"), card(3, "Clubs"), card(9) }
    T.assert_near(scored(tr, { played_cards = three }).mult, 6, 0.001, "X3 on exactly three 3s")
    local two = { card(3), card(3, "Spades"), card(9), card(11) }
    T.assert_eq(scored(tr, { played_cards = two }).mult, 2, "two 3s pay nothing")
    local four = { card(3), card(3, "Spades"), card(3, "Clubs"), card(3, "Diamonds") }
    T.assert_eq(scored(tr, { played_cards = four }).mult, 2, "four 3s pay nothing")
    wipe_mods()
end)

--------------------------------------------------------------------------------
-- New Jokers: scoring effects
--------------------------------------------------------------------------------

suite.test("nice pays 420 Chips for a 6 and a 9", function()
    local game = install_pack()
    local nice = add(game, "j_cryp_nice")
    local hand = { card(6), card(9, "Spades"), card(2, "Clubs") }
    T.assert_eq(scored(nice, { played_cards = hand }).chips, 430, "6 + 9 -> +420 Chips")
    local no = { card(6), card(2, "Spades"), card(3, "Clubs") }
    T.assert_eq(scored(nice, { played_cards = no }).chips, 10, "6 without 9 pays nothing")
    wipe_mods()
end)

suite.test("filler multiplies by exactly 1.00000000000003", function()
    local game = install_pack()
    local filler = add(game, "j_cryp_filler")
    local ctx = scored(filler, { played_cards = { card(5) } })
    T.assert_near(ctx.mult, 2 * 1.00000000000003, 1e-9, "the joke value is kept exact")
    wipe_mods()
end)

suite.test("wee fib grows on Aces and 8s, then pays the stored Mult", function()
    local game = install_pack()
    local fib = add(game, "j_cryp_wee_fib")
    local a, four, eight = card(14), card(4, "Spades"), card(8, "Clubs")
    local played = { a, four, eight }
    play_card(fib, a, played)
    play_card(fib, four, played)
    play_card(fib, eight, played)
    T.assert_eq(fib.ability.extra.mult, 6, "Ace and 8 give +3 each, the 4 nothing")
    T.assert_eq(scored(fib, { played_cards = played }).mult, 8, "stored +6 Mult pays")
    wipe_mods()
end)

suite.test("quintet, stronghold and clash pay on their hands", function()
    local game = install_pack()
    local quintet = add(game, "j_cryp_quintet")
    local five = { card(7), card(7, "Spades"), card(7, "Clubs"), card(7, "Diamonds"), card(7) }
    T.assert_near(scored(quintet, { played_cards = five, contains_hand_types = { ["Five of a Kind"] = true } }).mult, 10, 0.001, "quintet X5 on Five of a Kind")
    T.assert_eq(scored(quintet, { played_cards = { card(2) }, contains_hand_types = { Pair = true } }).mult, 2, "quintet quiet otherwise")
    local stronghold = add(game, "j_cryp_stronghold")
    local stones = { card(2, "Hearts", "stone"), card(3, "Spades", "stone"), card(4, "Clubs", "stone"), card(5, "Diamonds", "stone"), card(6, "Hearts", "stone") }
    T.assert_near(scored(stronghold, { played_cards = stones, contains_hand_types = { Bulwark = true } }).mult, 10, 0.001, "stronghold X5 on Bulwark")
    local clash = add(game, "j_cryp_clash")
    T.assert_near(scored(clash, { played_cards = five, contains_hand_types = { UltPair = true } }).mult, 24, 0.001, "clash X12 on UltPair")
    wipe_mods()
end)

suite.test("apjoker only fires on the Boss Blind", function()
    local game = install_pack()
    local ap = add(game, "j_cryp_apjoker")
    local hand = { card(9) }
    G.current_blind_index = 1
    T.assert_eq(scored(ap, { played_cards = hand }).mult, 2, "Small Blind: nothing")
    G.current_blind_index = 3
    T.assert_near(scored(ap, { played_cards = hand }).mult, 8, 0.001, "Boss Blind: X4 Mult")
    G.current_blind_index = nil
    wipe_mods()
end)

suite.test("eternal flame gains X0.1 Mult per card sold", function()
    local game = install_pack()
    local flame = add(game, "j_cryp_eternalflame")
    local other = add(game, "j_joker")
    fire(flame, "on_joker_sold", { joker = other })
    T.assert_near(flame.ability.extra.x_mult, 1.1, 0.001, "one sale -> X1.1 stored")
    T.assert_near(scored(flame, { played_cards = { card(5) } }).mult, 2.2, 0.001, "stored XMult pays")
    wipe_mods()
end)

suite.test("crypto coin pays $1-10 when a Joker is sold", function()
    local game = install_pack()
    local coin = add(game, "j_cryp_coin")
    local other = add(game, "j_joker")
    G.money = 0
    fire(coin, "on_joker_sold", { joker = other })
    T.assert_true(G.money >= 1 and G.money <= 10,
        "coin pays $1-10, got " .. tostring(G.money))
    wipe_mods()
end)

suite.test("crustulum refunds the reroll and banks Chips", function()
    local game = install_pack()
    local crust = add(game, "j_cryp_crustulum")
    G.money = 20
    fire(crust, "on_shop_reroll", { reroll_cost = 5 })
    T.assert_eq(G.money, 25, "reroll price refunded")
    T.assert_eq(scored(crust, { played_cards = { card(5) } }).chips, 14, "banked +4 Chips pay out")
    wipe_mods()
end)

suite.test("python gains X0.15 Mult per Code card used", function()
    local game = install_pack()
    local python = add(game, "j_cryp_python")
    fire(python, "on_consumable_used", { consumable_kind = "Code" })
    T.assert_near(python.ability.extra.Xmult, 1.15, 0.001, "one Code card -> X1.15")
    T.assert_near(scored(python, { played_cards = { card(5) } }).mult, 2.3, 0.001, "stored XMult pays")
    wipe_mods()
end)

suite.test("jimball grows while its hand stays the most played", function()
    local game = install_pack()
    local jim = add(game, "j_cryp_jimball")
    local pair_idx = hand_index(game, "Pair")
    game.hand_play_counts[pair_idx] = 5
    local pair = { card(4), card(4, "Spades") }
    fire(jim, "on_hand_played", { played_cards = pair, hand_type = "Pair" })
    T.assert_near(jim.ability.extra.x_mult, 1.15, 0.001, "first repeat hand -> X1.15")
    fire(jim, "on_hand_played", { played_cards = pair, hand_type = "Pair" })
    T.assert_near(jim.ability.extra.x_mult, 1.3, 0.001, "second -> X1.30")
    wipe_mods()
end)

--------------------------------------------------------------------------------
-- New Jokers: selling, creation, round-end and dollar bonuses
--------------------------------------------------------------------------------

suite.test("m scales to X14 when a Jolly Joker is sold", function()
    local game = install_pack()
    local m = add(game, "j_cryp_m")
    local jolly = add(game, "j_jolly")
    fire(m, "on_joker_sold", { joker = jolly })
    T.assert_near(m.ability.extra.x_mult, 14, 0.001, "selling a Jolly -> X14")
    T.assert_near(scored(m, { played_cards = { card(5) } }).mult, 28, 0.001, "X14 pays")
    wipe_mods()
end)

suite.test("M creates a Negative Jolly Joker when a Blind is selected", function()
    local game = install_pack()
    local bigm = add(game, "j_cryp_M")
    local before = #game.jokers
    fire(bigm, "on_blind_selected", {})
    T.assert_eq(#game.jokers, before + 1, "a Joker appears")
    local made = game.jokers[#game.jokers]
    T.assert_eq(made.def and made.def.id or made.id, "j_jolly", "it is a Jolly Joker")
    T.assert_eq(made.edition, "negative", "and it is Negative")
    wipe_mods()
end)

suite.test("sob creates a Negative Obelisk when gained", function()
    local game = install_pack()
    local sob = add(game, "j_cryp_curse_sob")
    local found = false
    for _, j in ipairs(game.jokers) do
        if (j.def and j.def.id or j.id) == "j_obelisk" and j.edition == "negative" then found = true end
    end
    T.assert_true(found, "a Negative Obelisk was created on gain")
    wipe_mods()
end)

suite.test("sapling sells into a random Epic Joker at 18 enhanced cards", function()
    local game = install_pack()
    local sap = add(game, "j_cryp_sapling")
    local gold = card(7, "Hearts", "gold")
    for _ = 1, 18 do play_card(sap, gold, { gold }) end
    T.assert_true(sap.ability.immutable.score >= 18, "counter reached 18")
    local before = #game.jokers
    fire(sap, "on_joker_sold", { joker = sap })
    -- The shop removes the sold card itself in a real game; the harness only
    -- drives the context, so the Epic appears alongside the (sold) sapling.
    T.assert_eq(#game.jokers, before + 1, "an Epic Joker is created on the sale")
    local made = game.jokers[#game.jokers]
    T.assert_eq(made.def.rarity, SMODS.Rarities["cryp_epic"].index, "the new Joker is Epic")
    wipe_mods()
end)

suite.test("happy creates a random Joker at end of round when there is room", function()
    local game = install_pack()
    local happy = add(game, "j_cryp_happy")
    local before = #game.jokers
    fire(happy, "on_round_end", {})
    T.assert_eq(#game.jokers, before + 1, "a random Joker appears")
    wipe_mods()
end)

suite.test("redbloon pays $20 and pops after 2 rounds", function()
    local game = install_pack()
    local bloon = add(game, "j_cryp_redbloon")
    G.money = 0
    fire(bloon, "on_round_end", {})
    T.assert_eq(#game.jokers, 1, "still held after round 1")
    fire(bloon, "on_round_end", {})
    T.assert_eq(#game.jokers, 0, "destroyed after round 2")
    T.assert_eq(G.money, 20, "$20 paid out")
    wipe_mods()
end)

suite.test("chili pepper grows XMult each round and burns out on round 8", function()
    local game = install_pack()
    local chili = add(game, "j_cryp_chili_pepper")
    fire(chili, "on_round_end", {})
    T.assert_near(scored(chili, { played_cards = { card(5) } }).mult, 3, 0.001, "X1.5 after one round")
    for _ = 1, 7 do fire(chili, "on_round_end", {}) end
    T.assert_eq(#game.jokers, 0, "destroyed at the end of round 8")
    wipe_mods()
end)

suite.test("pot of jokes regrows its hand size each round", function()
    local game = install_pack()
    local pot = add(game, "j_cryp_pot_of_jokes")
    T.assert_eq(pot.ability.h_size, -2, "starts at -2 hand size")
    fire(pot, "on_round_end", {})
    T.assert_eq(pot.ability.h_size, -1, "-1 after one round")
    wipe_mods()
end)

suite.test("compound interest pays a growing percent of money", function()
    local game = install_pack()
    local ci = add(game, "j_cryp_compound_interest")
    local def = JOKER_DEFS["j_cryp_compound_interest"]
    G.money = 100
    local bonus = def.smods.calc_dollar_bonus(def.smods, ci)
    T.assert_eq(bonus, 12, "12% of $100")
    T.assert_eq(ci.ability.extra.percent, 15, "percent grows by 3")
    T.assert_eq(def.smods.calc_dollar_bonus(def.smods, ci), 15, "next payout is 15%")
    wipe_mods()
end)

suite.test("magnet pays more with a small Joker area", function()
    local game = install_pack()
    local magnet = add(game, "j_cryp_magnet")
    local def = JOKER_DEFS["j_cryp_magnet"]
    local small = def.smods.calc_dollar_bonus(def.smods, magnet)
    T.assert_eq(small, magnet.ability.extra.money * magnet.ability.extra.Xmoney, "small area pays the multiplied bonus")
    add(game, "j_joker"); add(game, "j_joker"); add(game, "j_joker"); add(game, "j_joker")
    local big = def.smods.calc_dollar_bonus(def.smods, magnet)
    T.assert_eq(big, magnet.ability.extra.money, "5+ Jokers pays the base bonus")
    wipe_mods()
end)

suite.test("gold joker banks percent per Gold card scored", function()
    local game = install_pack()
    local gold = add(game, "j_cryp_goldjoker")
    local g1, g2 = card(7, "Hearts", "gold"), card(9, "Spades", "gold")
    play_card(gold, g1, { g1, g2 })
    play_card(gold, g2, { g1, g2 })
    T.assert_eq(gold.ability.extra.percent, 4, "two Gold cards -> 4% banked")
    local def = JOKER_DEFS["j_cryp_goldjoker"]
    G.money = 100
    T.assert_eq(def.smods.calc_dollar_bonus(def.smods, gold), 4, "4% of $100 pays $4")
    wipe_mods()
end)

suite.test("soccer and tenebris are pure slot modifiers", function()
    local game = install_pack()
    local soccer = add(game, "j_cryp_soccer")
    T.assert_eq(soccer.ability.joker_slots, 1, "soccer +1 Joker slot")
    T.assert_eq(soccer.ability.h_size, 1, "soccer +1 hand size")
    T.assert_eq(soccer.ability.consumable_slots, 1, "soccer +1 consumable slot")
    local tenebris = add(game, "j_cryp_tenebris")
    T.assert_eq(tenebris.ability.joker_slots, 25, "tenebris +25 Joker slots")
    wipe_mods()
end)

--------------------------------------------------------------------------------
-- Custom hands: evaluators
--------------------------------------------------------------------------------

suite.test("Bulwark needs five Stone cards; UltPair needs suited pairs in 2+ suits", function()
    local game = install_pack()
    local bw, up
    for _, h in ipairs(SMODS.PokerHands) do
        if h.key == "Bulwark" then bw = h end
        if h.key == "UltPair" then up = h end
    end
    T.assert_true(bw ~= nil and up ~= nil, "both hands registered")
    local stones = { card(2, "Hearts", "stone"), card(3, "Spades", "stone"), card(4, "Clubs", "stone"), card(5, "Diamonds", "stone"), card(6, "Hearts", "stone") }
    local res = bw.evaluate(bw, stones)
    T.assert_true(type(res) == "table" and #res == 5, "five Stone cards make a Bulwark")
    local mixed = { card(2, "Hearts", "stone"), card(3, "Spades", "stone"), card(4, "Clubs", "stone"), card(5, "Diamonds", "stone"), card(6, "Hearts") }
    T.assert_true(bw.evaluate(bw, mixed) == nil, "four Stone cards do not")
    local ult = { card(13, "Spades"), card(13, "Spades"), card(13, "Hearts"), card(13, "Hearts"),
        card(12, "Spades"), card(12, "Spades"), card(12, "Hearts"), card(12, "Hearts") }
    local ures = up.evaluate(up, ult)
    T.assert_true(type(ures) == "table" and #ures == 8, "suited pairs in two suits make an UltPair")
    local mono = { card(13, "Spades"), card(13, "Spades"), card(13, "Spades"), card(13, "Spades"),
        card(12, "Spades"), card(12, "Spades"), card(12, "Spades"), card(12, "Spades") }
    T.assert_true(up.evaluate(up, mono) == nil, "a single suit does not")
    wipe_mods()
end)

--------------------------------------------------------------------------------
-- Consumables
--------------------------------------------------------------------------------

local function hold_consumable(game, key)
    local id = "c_cryp_" .. key
    T.assert_true(game:add_consumable(id), id .. " should be addable")
    return #game.consumables
end

local function use_slot(game, slot)
    game.STATE = game.STATES.SELECTING_HAND
    T.assert_true(game:consumable_use_enabled(slot), "consumable usable")
    T.assert_true(game:use_consumable(slot), "consumable used")
end

local function setup_hand(game, nodes, selected)
    game.hand.card_nodes = nodes
    game.hand.cards = {}
    for i, n in ipairs(nodes) do game.hand.cards[i] = n.card_data end
    game.hand.selected = selected or {}
    game.STATE = game.STATES.SELECTING_HAND
end

suite.test("asteroid belt and mars moons level Bulwark and UltPair", function()
    local game = install_pack_full()
    local bw_idx, up_idx = hand_index(game, "Bulwark"), hand_index(game, "UltPair")
    use_slot(game, hold_consumable(game, "asteroidbelt"))
    T.assert_eq(game.hand_stats[bw_idx].level, 2, "Bulwark level 2")
    use_slot(game, hold_consumable(game, "marsmoons"))
    T.assert_eq(game.hand_stats[up_idx].level, 2, "UltPair level 2")
    wipe_mods()
end)

suite.test("the Finnish planets level their three hands; Kaikki levels the customs", function()
    local game = install_pack_full()
    use_slot(game, hold_consumable(game, "Timantii"))
    for _, n in ipairs({ "High Card", "Pair", "Two Pair" }) do
        T.assert_eq(game.hand_stats[hand_index(game, n)].level, 2, n .. " level 2")
    end
    T.assert_eq(game.hand_stats[hand_index(game, "Flush")].level, 1, "Flush untouched")
    use_slot(game, hold_consumable(game, "Kaikki"))
    T.assert_eq(game.hand_stats[hand_index(game, "Bulwark")].level, 2, "Bulwark level 2 via Kaikki")
    T.assert_eq(game.hand_stats[hand_index(game, "UltPair")].level, 2, "UltPair level 2 via Kaikki")
    wipe_mods()
end)

suite.test("neutron star levels one hand, then two", function()
    local game = install_pack_full()
    local function total_levels()
        local sum = 0
        for _, s in ipairs(game.hand_stats) do sum = sum + (s.level or 0) end
        return sum
    end
    local before = total_levels()
    use_slot(game, hold_consumable(game, "nstar"))
    T.assert_eq(total_levels(), before + 1, "first use: +1 level total")
    use_slot(game, hold_consumable(game, "nstar"))
    T.assert_eq(total_levels(), before + 3, "second use: +2 levels total")
    wipe_mods()
end)

suite.test("the automaton (a Tarot) creates a random Code card", function()
    local game = install_pack_full()
    use_slot(game, hold_consumable(game, "automaton"))
    T.assert_eq(#game.consumables, 1, "one consumable afterwards")
    T.assert_eq(game.consumables[1].kind, "Code", "the created card is a Code card")
    local code_ids = { c_cryp_ctrl_v = true, c_cryp_commit = true, c_cryp_rework = true,
        c_cryp_alttab = true }
    T.assert_true(code_ids[game.consumables[1].id] == true,
        "and it is one of the pack's Code cards: " .. tostring(game.consumables[1].id))
    wipe_mods()
end)

suite.test("ctrl+v copies the highlighted card into the hand", function()
    local game = install_pack_full()
    local seven = card(7, "Hearts", "gold")
    seven.card_data.seal = "gold"
    setup_hand(game, { seven }, { seven })
    use_slot(game, hold_consumable(game, "ctrl_v"))
    T.assert_eq(#game.hand.cards, 2, "a copy joined the hand")
    T.assert_eq(game.hand.cards[2].rank, 7, "the copy is a 7")
    T.assert_eq(game.hand.cards[2].enhancement, "gold", "the copy keeps the enhancement")
    wipe_mods()
end)

suite.test("gateway trades three Jokers for an Exotic; summoning swaps one for an Epic", function()
    local game = install_pack_full()
    add(game, "j_joker"); add(game, "j_joker"); add(game, "j_joker")
    use_slot(game, hold_consumable(game, "gateway"))
    T.assert_eq(#game.jokers, 1, "three Jokers became one")
    T.assert_eq(game.jokers[1].def.rarity, SMODS.Rarities["cryp_exotic"].index, "the new Joker is Exotic")
    wipe_mods()
    game = install_pack_full()
    add(game, "j_joker"); add(game, "j_joker")
    use_slot(game, hold_consumable(game, "summoning"))
    local plain, epics = 0, 0
    for _, j in ipairs(game.jokers) do
        if j.def.id == "j_joker" then plain = plain + 1 end
        if j.def.rarity == SMODS.Rarities["cryp_epic"].index then epics = epics + 1 end
    end
    T.assert_eq(plain, 1, "exactly one of the two Jokers was destroyed")
    T.assert_eq(epics, 1, "exactly one Epic was created")
    wipe_mods()
end)

suite.test("the blessing creates a random other consumable", function()
    local game = install_pack_full()
    use_slot(game, hold_consumable(game, "theblessing"))
    T.assert_eq(#game.consumables, 1, "a consumable fills the freed slot")
    T.assert_true(game.consumables[1].id ~= "c_cryp_theblessing", "and it is not The Blessing")
    wipe_mods()
end)

suite.test("analog destroys two Jokers, duplicates the third, and raises the Ante", function()
    local game = install_pack_full()
    add(game, "j_joker"); add(game, "j_greedy_joker"); add(game, "j_lusty_joker")
    local ante = game.ante
    use_slot(game, hold_consumable(game, "analog"))
    T.assert_eq(game.ante, ante + 1, "Ante increased by 1")
    T.assert_eq(#game.jokers, 3, "one Joker plus two copies remain")
    local id = game.jokers[1].def.id
    for _, j in ipairs(game.jokers) do T.assert_eq(j.def.id, id, "all copies share the survivor") end
    wipe_mods()
end)


suite.test("vacuum strips hand modifications for $4 each", function()
    local game = install_pack_full()
    local gold = card(7, "Hearts", "gold")
    local foil = card(9, "Spades")
    foil.card_data.edition = "foil"
    local sealed = card(11, "Clubs")
    sealed.card_data.seal = "red"
    local plain = card(2, "Diamonds")
    setup_hand(game, { gold, foil, sealed, plain }, {})
    G.money = 0
    use_slot(game, hold_consumable(game, "vacuum"))
    T.assert_eq(G.money, 12, "three modifications at $4 each")
    T.assert_true(gold.card_data.enhancement == nil, "enhancement removed")
    T.assert_true(foil.card_data.edition == nil, "edition removed")
    T.assert_true(sealed.card_data.seal == nil, "seal removed")
    wipe_mods()
end)

suite.test("lock makes exactly one Joker Eternal", function()
    local game = install_pack_full()
    add(game, "j_joker"); add(game, "j_joker"); add(game, "j_joker")
    use_slot(game, hold_consumable(game, "lock"))
    local eternal = 0
    for _, j in ipairs(game.jokers) do if j.eternal then eternal = eternal + 1 end end
    T.assert_eq(eternal, 1, "exactly one Eternal Joker")
    wipe_mods()
end)

suite.test("replica turns every hand card into a copy of one of them", function()
    local game = install_pack_full()
    local nodes = { card(3, "Hearts"), card(7, "Spades"), card(11, "Clubs"), card(13, "Diamonds") }
    setup_hand(game, nodes, {})
    use_slot(game, hold_consumable(game, "replica"))
    local rank, suit = nodes[1].card_data.rank, nodes[1].card_data.suit
    for _, n in ipairs(nodes) do
        T.assert_eq(n.card_data.rank, rank, "all ranks match the chosen card")
        T.assert_eq(n.card_data.suit, suit, "all suits match the chosen card")
    end
    wipe_mods()
end)

--------------------------------------------------------------------------------
-- Tier 3 (v1.2.0): registrations for seals, editions and tags
--------------------------------------------------------------------------------

suite.test("tier 3 registers the Green/Azure seals, Astral/Mosaic/M editions, Cat/Double M/Rework tags", function()
    local game = install_pack()
    T.assert_true(SMODS.SealByValue ~= nil and SMODS.SealByValue["cry_green"] ~= nil, "Green Seal registered")
    T.assert_true(SMODS.SealByValue["cry_azure"] ~= nil, "Azure Seal registered")
    T.assert_eq(SMODS.SealByValue["cry_green"].weight, 0, "Green Seal stays out of random polls")
    T.assert_eq(SMODS.SealByValue["cry_azure"].weight, 0, "Azure Seal stays out of random polls")
    T.assert_true(SMODS.EditionByValue["cry_astral"] ~= nil, "Astral edition registered")
    T.assert_true(SMODS.EditionByValue["cry_mosaic"] ~= nil, "Mosaic edition registered")
    T.assert_true(SMODS.EditionByValue["cry_m"] ~= nil, "M edition registered")
    T.assert_eq(SMODS.EditionByValue["cry_m"].config.mult, 8, "M edition is +8 Mult")
    T.assert_true(SMODS.Tags["cryp_cry_cat"] ~= nil, "Cat Tag registered")
    T.assert_true(SMODS.Tags["cryp_cry_double_m"] ~= nil, "Double M Tag registered")
    T.assert_true(SMODS.Tags["cryp_cry_rework"] ~= nil, "Rework Tag registered")
    game:addTag("cry_cat")
    T.assert_eq(game.tags[#game.tags].type, "cry_cat", "Cat Tag can be granted")
    T.assert_eq(game.tags[#game.tags].ability.level, 1, "Cat Tag starts at level 1")
    wipe_mods()
end)

suite.test("double M tag rewrites a shop draft into an M Joker with the M edition", function()
    local game = install_pack()
    game:addTag("cry_double_m")
    local draft = { id = "j_joker" }
    local fired = SMODS.tag_moment(game, "store_joker_create", { card = draft })
    T.assert_eq(fired, 1, "the tag fires once")
    T.assert_eq(draft.edition, "cry_m", "the draft gains the M edition")
    local m_ids = {}
    for _, id in ipairs({ "j_cryp_m", "j_cryp_M", "j_cryp_jollysus", "j_cryp_bubblem",
        "j_cryp_foodm", "j_cryp_mstack", "j_cryp_mneon", "j_cryp_notebook", "j_cryp_bonk",
        "j_cryp_loopy", "j_cryp_scrabble", "j_cryp_sacrifice", "j_cryp_reverse",
        "j_cryp_doodlem", "j_cryp_virgo", "j_cryp_biggestm", "j_cryp_macabre",
        "j_cryp_megg", "j_cryp_longboi", "j_cryp_smallestm", "j_cryp_mprime" }) do
        m_ids[id] = true
    end
    T.assert_true(m_ids[draft.id] == true, "the draft is an M-pool Joker: " .. tostring(draft.id))
    T.assert_eq(#game.tags, 0, "the tag is consumed")
    wipe_mods()
end)

--------------------------------------------------------------------------------
-- Tier 3: big-number Jokers (e_mult / e_chips returns)
--------------------------------------------------------------------------------

suite.test("circulus pistoris pays ^pi Chips and ^pi Mult at exactly 3 hands remaining", function()
    local game = install_pack()
    local circ = add(game, "j_cryp_circulus_pistoris")
    game.hands = 3
    local ctx = scored(circ, { played_cards = { card(5) } })
    T.assert_near(ctx.chips, 10 ^ math.pi, 5, "^pi Chips at 3 hands")
    T.assert_near(ctx.mult, 2 ^ math.pi, 0.05, "^pi Mult at 3 hands")
    game.hands = 2
    local ctx2 = scored(circ, { played_cards = { card(5) } })
    T.assert_eq(ctx2.chips, 10, "nothing at 2 hands")
    T.assert_eq(ctx2.mult, 2, "nothing at 2 hands")
    wipe_mods()
end)

suite.test("facile pays ^3 Mult when the hand scored 10 or fewer card triggers", function()
    local game = install_pack()
    local facile = add(game, "j_cryp_facile")
    local a, b = card(5), card(9, "Spades")
    local played = { a, b }
    play_card(facile, a, played)
    play_card(facile, b, played)
    T.assert_eq(facile.ability.immutable.check2, 2, "two scored cards counted")
    local ctx = scored(facile, { played_cards = played })
    T.assert_near(ctx.mult, 8, 0.001, "^3 Mult under the cap")
    T.assert_eq(facile.ability.immutable.check2, 0, "counter resets after the hand")
    for _ = 1, 11 do play_card(facile, a, played) end
    local ctx2 = scored(facile, { played_cards = played })
    T.assert_eq(ctx2.mult, 2, "11 triggers is over the cap: no pay")
    wipe_mods()
end)

suite.test("primus grows ^0.17 on prime-only hands and pays the stored ^Mult", function()
    local game = install_pack()
    local primus = add(game, "j_cryp_primus")
    local primes = { card(2), card(3, "Spades"), card(5, "Clubs") }
    fire(primus, "on_hand_played", { played_cards = primes, hand_type = "Three of a Kind" })
    T.assert_near(primus.ability.extra.Emult, 1.18, 0.001, "prime hand grows to ^1.18")
    local ctx = scored(primus, { played_cards = primes })
    T.assert_near(ctx.mult, 2 ^ 1.18, 0.01, "stored ^Mult pays")
    local mixed = { card(2), card(9, "Spades"), card(5, "Clubs") }
    fire(primus, "on_hand_played", { played_cards = mixed, hand_type = "Three of a Kind" })
    T.assert_near(primus.ability.extra.Emult, 1.18, 0.001, "a 9 breaks the prime hand: no growth")
    wipe_mods()
end)

suite.test("stella mortis destroys a Planet at the end of the shop for ^0.4 Mult", function()
    local game = install_pack_full()
    local stella = add(game, "j_cryp_stella_mortis")
    hold_consumable(game, "planetlua")
    fire(stella, "on_shop_exit", {})
    T.assert_eq(#game.consumables, 0, "the Planet card is destroyed")
    T.assert_near(stella.ability.extra.Emult, 1.4, 0.001, "^1.4 stored")
    local ctx = scored(stella, { played_cards = { card(5) } })
    T.assert_near(ctx.mult, 2 ^ 1.4, 0.01, "stored ^Mult pays")
    wipe_mods()
end)

suite.test("happy house pays ^4 Mult only after 114 hands", function()
    local game = install_pack()
    local happy = add(game, "j_cryp_happyhouse")
    local hand = { card(5) }
    for _ = 1, 114 do fire(happy, "on_hand_played", { played_cards = hand, hand_type = "High Card" }) end
    T.assert_eq(happy.ability.immutable.check, 114, "114 hands counted")
    T.assert_eq(scored(happy, { played_cards = hand }).mult, 2, "114 is not past the trigger yet")
    fire(happy, "on_hand_played", { played_cards = hand, hand_type = "High Card" })
    T.assert_near(scored(happy, { played_cards = hand }).mult, 16, 0.001, "^4 Mult after the trigger")
    wipe_mods()
end)

suite.test("night pays ^3 Mult on the final hand, then self-destructs", function()
    local game = install_pack()
    local night = add(game, "j_cryp_night")
    local hand = { card(5) }
    game.hands = 2
    T.assert_eq(scored(night, { played_cards = hand }).mult, 2, "not the final hand: nothing")
    fire(night, "on_hand_after", { played_cards = hand })
    T.assert_eq(#game.jokers, 1, "survives a non-final hand")
    game.hands = 0
    T.assert_near(scored(night, { played_cards = hand }).mult, 8, 0.001, "^3 Mult on the final hand")
    fire(night, "on_hand_after", { played_cards = hand })
    T.assert_eq(#game.jokers, 0, "destroyed after the final hand")
    wipe_mods()
end)

suite.test("jimbo-tron 9000 gains ^1 Mult per default Joker held", function()
    local game = install_pack()
    local jtron = add(game, "j_cryp_jtron")
    local hand = { card(5) }
    T.assert_eq(scored(jtron, { played_cards = hand }).mult, 2, "no default Jokers: ^1 is a no-op")
    add(game, "j_joker"); add(game, "j_joker")
    T.assert_near(scored(jtron, { played_cards = hand }).mult, 8, 0.001, "two default Jokers: ^3 Mult")
    wipe_mods()
end)

suite.test("starfruit loses ^0.2 Mult per reroll and is eaten at ^1", function()
    local game = install_pack()
    local star = add(game, "j_cryp_starfruit")
    local hand = { card(5) }
    for _ = 1, 4 do fire(star, "on_shop_reroll", { reroll_cost = 5 }) end
    T.assert_near(star.ability.extra.emult, 1.2, 0.001, "^1.2 after four rerolls")
    T.assert_eq(#game.jokers, 1, "still held")
    fire(star, "on_shop_reroll", { reroll_cost = 5 })
    T.assert_eq(#game.jokers, 0, "eaten when the decay reaches ^1")
    wipe_mods()
end)

suite.test("googol play card stores an exact X10^100 at 1 in 8", function()
    local game = install_pack()
    local googol = add(game, "j_cryp_googol_play")
    T.assert_eq(googol.ability.extra.Xmult, 1e100, "the googol is stored exact")
    T.assert_eq(googol.ability.extra.odds, 8, "1 in 8")
    wipe_mods()
end)

suite.test("formidiulosus pays per Candy, spawns Negative Candies, and destroys bought Cursed Jokers", function()
    local game = install_pack()
    local formid = add(game, "j_cryp_formidiulosus")
    add(game, "j_cryp_cotton_candy")
    local ctx = scored(formid, { played_cards = { card(5) } })
    T.assert_near(ctx.mult, 2 ^ 1.01, 0.01, "one Candy held: ^1.01 Mult")
    local before = #game.jokers
    fire(formid, "on_shop_exit", {})
    T.assert_eq(#game.jokers, before + 3, "three Candies created at the end of the shop")
    for i = before + 1, #game.jokers do
        T.assert_eq(game.jokers[i].def.rarity, SMODS.Rarities["cryp_candy"].index, "created Joker is Candy")
        T.assert_eq(game.jokers[i].edition, "negative", "created Joker is Negative")
    end
    wipe_mods()
    game = install_pack()
    local formid2 = add(game, "j_cryp_formidiulosus")
    add(game, "j_cryp_monopoly_money")
    T.assert_eq(#game.jokers, 2, "the Cursed Joker is held")
    fire(formid2, "on_shop_buy", { offer_kind = "joker", offer_id = "j_cryp_monopoly_money" })
    T.assert_eq(#game.jokers, 1, "the bought Cursed Joker is destroyed")
    T.assert_eq(game.jokers[1].def.id, "j_cryp_formidiulosus", "Formidiulosus itself remains")
    wipe_mods()
end)

suite.test("tredecim reacts to Jolly and M Jokers, scales on Jolly sales, creates M at round end", function()
    local game = install_pack()
    local tre = add(game, "j_cryp_mprime")
    local sus = add(game, "j_cryp_jollysus")
    local ctx = { event = "on_hand_scored", event_name = "on_hand_scored", chips = 10, mult = 2 }
    SMODS.post_trigger(sus, ctx)
    T.assert_near(ctx.mult, 2 ^ 1.05, 0.01, "a Jolly Joker's trigger gives ^1.05")
    local plain = add(game, "j_joker")
    local ctx2 = { event = "on_hand_scored", event_name = "on_hand_scored", chips = 10, mult = 2 }
    SMODS.post_trigger(plain, ctx2)
    T.assert_eq(ctx2.mult, 2, "a plain Joker's trigger gives nothing")
    fire(tre, "on_joker_sold", { joker = sus })
    T.assert_near(tre.ability.extra.mult, 1.09, 0.001, "selling a Jolly raises the amount")
    local before = #game.jokers
    fire(tre, "on_round_end", {})
    T.assert_eq(#game.jokers, before + 1, "an M Joker is created at end of round")
    wipe_mods()
end)

suite.test("universe pays ^1.2 Mult per other Astral card", function()
    local game = install_pack()
    local uni = add(game, "j_cryp_universe")
    local carrier = add(game, "j_cryp_dubious")
    carrier.edition = "cry_astral"
    local ctx = { event = "on_hand_scored", event_name = "on_hand_scored", chips = 10, mult = 2 }
    SMODS.post_trigger(carrier, ctx)
    T.assert_near(ctx.mult, 2 ^ 1.2, 0.01, "an Astral Joker's trigger gives ^1.2")
    local astral = card(7)
    astral.card_data.edition = "cry_astral"
    local ctx2 = fire(uni, "card_played", { card_node = astral, played_cards = { astral } })
    T.assert_near(ctx2.mult, 2 ^ 1.2, 0.01, "a scored Astral card gives ^1.2")
    local plaincard = card(9)
    local ctx3 = fire(uni, "card_played", { card_node = plaincard, played_cards = { plaincard } })
    T.assert_eq(ctx3.mult, 2, "a plain scored card gives nothing")
    wipe_mods()
end)

--------------------------------------------------------------------------------
-- Tier 3: x_chips class, balance, destruction, tags
--------------------------------------------------------------------------------

suite.test("antennas gains X0.1 Chips per scored 7 or 4; big cube pays X6 Chips", function()
    local game = install_pack()
    local ant = add(game, "j_cryp_antennatoheaven")
    local seven, four, nine = card(7), card(4, "Spades"), card(9, "Clubs")
    local played = { seven, four, nine }
    play_card(ant, seven, played)
    play_card(ant, four, played)
    play_card(ant, nine, played)
    T.assert_near(ant.ability.extra.x_chips, 1.2, 0.001, "7 and 4 grow it, the 9 does not")
    T.assert_near(scored(ant, { played_cards = played }).chips, 12, 0.01, "X1.2 Chips pays")
    local cube = add(game, "j_cryp_big_cube")
    T.assert_eq(scored(cube, { played_cards = played }).chips, 60, "X6 Chips")
    T.assert_false(game:joker_allowed_in_random_pool("j_cryp_big_cube"),
        "Big Cube stays out of the pool without Cube")
    wipe_mods()
    game = install_pack()
    add(game, "j_cryp_cube")
    T.assert_true(game:joker_allowed_in_random_pool("j_cryp_big_cube"),
        "Big Cube joins the pool while Cube is held")
    wipe_mods()
end)

suite.test("celestial globe grows on its target hand, then the target changes", function()
    local game = install_pack()
    local globe = add(game, "j_cryp_spaceglobe")
    local target = globe.ability.extra.type
    T.assert_true(target ~= nil and target ~= "", "a target hand was rolled on creation")
    local hand = { card(5) }
    fire(globe, "on_hand_played", { played_cards = hand, hand_type = target })
    T.assert_near(globe.ability.extra.x_chips, 1.2, 0.001, "hitting the target grows XChips")
    T.assert_true(globe.ability.extra.type ~= target, "the target changes after a hit")
    T.assert_near(scored(globe, { played_cards = hand }).chips, 12, 0.01, "X1.2 Chips pays")
    wipe_mods()
end)

suite.test("pirate dagger destroys the Joker to its right for XChips", function()
    local game = install_pack()
    local dagger = add(game, "j_cryp_pirate_dagger")
    local victim = add(game, "j_joker")
    victim.sell_cost = 8
    fire(dagger, "on_blind_selected", {})
    T.assert_eq(#game.jokers, 1, "the Joker to the right is destroyed")
    T.assert_near(dagger.ability.extra.x_chips, 3, 0.001, "a quarter of $8 sell value banked")
    T.assert_eq(scored(dagger, { played_cards = { card(5) } }).chips, 30, "X3 Chips pays")
    wipe_mods()
end)

suite.test("supercell pays all four stats and $3 at round end; sync catalyst balances", function()
    local game = install_pack()
    local cell = add(game, "j_cryp_supercell")
    local ctx = scored(cell, { played_cards = { card(5) } })
    T.assert_eq(ctx.chips, 50, "+15 Chips then X2 Chips")
    T.assert_eq(ctx.mult, 34, "+15 Mult then X2 Mult")
    local def = JOKER_DEFS["j_cryp_supercell"]
    T.assert_eq(def.smods.calc_dollar_bonus(def.smods, cell), 3, "$3 at end of round")
    local sync = add(game, "j_cryp_sync_catalyst")
    local ctx2 = scored(sync, { played_cards = { card(5) } })
    T.assert_eq(ctx2.chips, ctx2.mult, "Chips and Mult are balanced")
    T.assert_eq(ctx2.chips, 10, "the fork's balance lifts both totals to the larger (10)")
    wipe_mods()
end)

suite.test("arsonist burns the whole played hand after a Full House", function()
    local game = install_pack_full()
    local ars = add(game, "j_cryp_arsonist")
    local fh = { card(4), card(4, "Spades"), card(4, "Clubs"), card(9), card(9, "Clubs") }
    setup_hand(game, fh, {})
    fire(ars, "on_hand_after", { played_cards = fh,
        contains_hand_types = { ["Full House"] = true }, hand_type = "Full House" })
    T.assert_eq(#game.hand.cards, 0, "all played cards are destroyed")
    local pair = { card(4), card(4, "Spades") }
    setup_hand(game, pair, {})
    fire(ars, "on_hand_after", { played_cards = pair,
        contains_hand_types = { Pair = true }, hand_type = "Pair" })
    T.assert_eq(#game.hand.cards, 2, "no Full House: nothing burns")
    wipe_mods()
end)

suite.test("queen's gambit destroys the Queen on a Royal Flush and creates a Negative Rare", function()
    local game = install_pack_full()
    local gambit = add(game, "j_cryp_queens_gambit")
    local royal = { card(10, "Spades"), card(11, "Spades"), card(12, "Spades"),
        card(13, "Spades"), card(14, "Spades") }
    setup_hand(game, royal, {})
    local before = #game.jokers
    fire(gambit, "on_hand_after", { played_cards = royal, hand_type = "Straight Flush" })
    T.assert_eq(#game.hand.cards, 4, "the Queen is destroyed")
    local queen_gone = true
    for _, d in ipairs(game.hand.cards) do if d.rank == 12 then queen_gone = false end end
    T.assert_true(queen_gone, "no Queen remains in hand")
    T.assert_eq(#game.jokers, before + 1, "a Joker is created")
    local made = game.jokers[#game.jokers]
    T.assert_eq(made.def.rarity, 3, "the created Joker is Rare")
    T.assert_eq(made.edition, "negative", "the created Joker is Negative")
    wipe_mods()
end)

suite.test("hunting season destroys the center card of a 3-card hand", function()
    local game = install_pack_full()
    local hunt = add(game, "j_cryp_huntingseason")
    local three = { card(3), card(7, "Spades"), card(11, "Clubs") }
    setup_hand(game, three, {})
    fire(hunt, "on_hand_after", { played_cards = three, hand_type = "Three of a Kind" })
    T.assert_eq(#game.hand.cards, 2, "one card is destroyed")
    local ranks = {}
    for _, d in ipairs(game.hand.cards) do ranks[d.rank] = true end
    T.assert_true(ranks[3] and ranks[11] and not ranks[7], "the center card (7) is the one destroyed")
    wipe_mods()
end)

suite.test("tiny creates a Double M Tag on a Pair", function()
    local game = install_pack()
    local tiny = add(game, "j_cryp_smallestm")
    local pair = { card(4), card(4, "Spades") }
    fire(tiny, "on_hand_played", { played_cards = pair, hand_type = "Pair" })
    T.assert_eq(#game.tags, 1, "one tag gained")
    T.assert_eq(game.tags[1].type, "cry_double_m", "it is a Double M Tag")
    fire(tiny, "on_hand_played", { played_cards = { card(5) }, hand_type = "High Card" })
    T.assert_eq(#game.tags, 1, "no tag on a non-Pair")
    wipe_mods()
end)

suite.test("energia duplicates acquired tags and grows its copy count", function()
    local game = install_pack()
    local energia = add(game, "j_cryp_energia")
    game:addTag("uncommon")
    T.assert_eq(#game.tags, 2, "the acquired tag is duplicated once")
    T.assert_eq(game.tags[1].type, "uncommon", "the copy is the same tag")
    T.assert_eq(game.tags[2].type, "uncommon", "the original is the same tag")
    T.assert_eq(energia.ability.extra.tags, 2, "the copy count grows by 1")
    wipe_mods()
end)

suite.test("pickle creates 3 tags per skip and is eaten after 3 blinds", function()
    local game = install_pack()
    local pickle = add(game, "j_cryp_pickle")
    fire(pickle, "on_blind_skipped", {})
    -- Three tags are granted; immediate tags (Handy, Garbage) pay out on
    -- grant instead of staying held, so the held count can be lower.
    T.assert_true(#game.tags >= 2, "tags created on a skip, got " .. #game.tags)
    for _, t in ipairs(game.tags) do
        T.assert_true(t.type ~= "boss", "never a Boss Tag")
    end
    local function pickle_held()
        for _, j in ipairs(game.jokers) do if j == pickle then return true end end
        return false
    end
    fire(pickle, "on_blind_selected", {})
    fire(pickle, "on_blind_selected", {})
    T.assert_true(pickle_held(), "still held at 1 tag left")
    fire(pickle, "on_blind_selected", {})
    T.assert_false(pickle_held(), "eaten when the count reaches 0")
    wipe_mods()
end)

suite.test("pity prize grants a random tag when a booster is skipped", function()
    local game = install_pack()
    local prize = add(game, "j_cryp_pity_prize")
    fire(prize, "on_booster_skip", {})
    T.assert_eq(#game.tags, 1, "one tag gained")
    T.assert_true(game.tags[1].type ~= "boss", "never a Boss Tag")
    wipe_mods()
end)

suite.test("yarn ball adds the highest Cat Tag level to probabilities and needs a Cat Tag for the pool", function()
    local game = install_pack()
    T.assert_false(game:joker_allowed_in_random_pool("j_cryp_yarnball"),
        "out of the pool without a Cat Tag")
    game:addTag("cry_cat")
    T.assert_true(game:joker_allowed_in_random_pool("j_cryp_yarnball"),
        "in the pool while a Cat Tag is held")
    local yarn = add(game, "j_cryp_yarnball")
    local num, den = SMODS.get_probability_vars(nil, 1, 4)
    T.assert_eq(num, 2, "Cat level 1 adds 1 to the numerator")
    T.assert_eq(den, 4, "the denominator is unchanged")
    wipe_mods()
end)

suite.test("astral in a bottle applies Astral and Perishable to a random Joker when sold", function()
    local game = install_pack()
    local bottle = add(game, "j_cryp_astral_bottle")
    local other = add(game, "j_joker")
    fire(bottle, "on_joker_sold", { joker = bottle })
    T.assert_eq(other.edition, "cry_astral", "the other Joker becomes Astral")
    T.assert_true(other.perishable == true, "and Perishable")
    wipe_mods()
end)

--------------------------------------------------------------------------------
-- Tier 3: deviation restorations
--------------------------------------------------------------------------------

suite.test("exposed debuffs face cards and mask debuffs non-face cards while held", function()
    local game = install_pack_full()
    local queen = card(12)
    local five = card(5, "Spades")
    local stonejack = card(11, "Clubs", "stone")
    setup_hand(game, { queen, five, stonejack }, {})
    local exposed = add(game, "j_cryp_exposed")
    fire(exposed, "on_blind_selected", {})
    T.assert_true(queen.card_data.perma_debuff == true, "Exposed: the Queen is debuffed")
    T.assert_true(five.card_data.perma_debuff ~= true, "Exposed: the 5 is not")
    T.assert_true(stonejack.card_data.perma_debuff ~= true, "Exposed: a Stone Jack is not a face card")
    wipe_mods()
    game = install_pack_full()
    local queen2 = card(12)
    local five2 = card(5, "Spades")
    local stonejack2 = card(11, "Clubs", "stone")
    setup_hand(game, { queen2, five2, stonejack2 }, {})
    local mask = add(game, "j_cryp_mask")
    fire(mask, "on_blind_selected", {})
    T.assert_true(queen2.card_data.perma_debuff ~= true, "Mask: the Queen is not debuffed")
    T.assert_true(five2.card_data.perma_debuff == true, "Mask: the 5 is debuffed")
    T.assert_true(stonejack2.card_data.perma_debuff == true, "Mask: a Stone Jack counts as non-face")
    wipe_mods()
end)

suite.test("seal the deal seals played cards from the full pool including Green and Azure", function()
    local game = install_pack_full()
    local std = add(game, "j_cryp_seal_the_deal")
    local nodes = {}
    for i = 1, 12 do nodes[i] = card(2 + i) end
    setup_hand(game, nodes, {})
    game.hands = 0
    fire(std, "on_hand_after", { played_cards = nodes })
    local pool = { gold = true, red = true, blue = true, purple = true,
        cry_azure = true, cry_green = true }
    local saw_custom = false
    for _, n in ipairs(nodes) do
        T.assert_true(pool[n.card_data.seal] == true,
            "sealed from the pool: " .. tostring(n.card_data.seal))
        if n.card_data.seal == "cry_azure" or n.card_data.seal == "cry_green" then
            saw_custom = true
        end
    end
    T.assert_true(saw_custom, "12 seals draw at least one of Green/Azure")
    wipe_mods()
end)

suite.test("kitty printer turns the next skipped-blind tag into a Cat Tag", function()
    local game = install_pack()
    local kitty = add(game, "j_cryp_kittyprinter")
    game:addTag("uncommon")
    T.assert_eq(game.tags[#game.tags].type, "uncommon", "the rolled tag is held first")
    fire(kitty, "on_blind_skipped", {})
    T.assert_eq(game.tags[#game.tags].type, "cry_cat", "the skip converts it to a Cat Tag")
    wipe_mods()
end)

--------------------------------------------------------------------------------
-- Tier 3: new consumables
--------------------------------------------------------------------------------

local function use_slot_target(game, slot, target)
    game.STATE = game.STATES.SELECTING_HAND
    T.assert_true(game:use_consumable(slot, target), "targeted consumable used")
end

suite.test("source applies the Green Seal and typhoon the Azure Seal", function()
    local game = install_pack_full()
    local seven = card(7)
    setup_hand(game, { seven }, { seven })
    use_slot(game, hold_consumable(game, "source"))
    T.assert_eq(seven.card_data.seal, "cry_green", "Green Seal applied")
    local nine = card(9, "Spades")
    setup_hand(game, { nine }, { nine })
    use_slot(game, hold_consumable(game, "typhoon"))
    T.assert_eq(nine.card_data.seal, "cry_azure", "Azure Seal applied")
    wipe_mods()
end)

suite.test("ritual adds one of Astral, Mosaic or Negative to a selected card", function()
    local game = install_pack_full()
    local seven = card(7)
    setup_hand(game, { seven }, { seven })
    use_slot(game, hold_consumable(game, "ritual"))
    local data = seven.card_data
    local ed = data.edition or (data.modifier and data.modifier.edition)
    local allowed = { cry_astral = true, cry_mosaic = true, negative = true }
    T.assert_true(allowed[ed] == true, "a Ritual edition was applied: " .. tostring(ed))
    wipe_mods()
end)

suite.test("conduit swaps a hand card's edition with a Joker's", function()
    local game = install_pack_full()
    local joker = add(game, "j_joker")
    local seven = card(7)
    seven.card_data.edition = "foil"
    setup_hand(game, { seven }, { seven })
    use_slot_target(game, hold_consumable(game, "conduit"), joker)
    T.assert_eq(joker.edition, "foil", "the Joker gains the card's edition")
    local ed = seven.card_data.edition
        or (seven.card_data.modifier and seven.card_data.modifier.edition)
    T.assert_true(ed == nil or ed == "base", "the card gives its edition up")
    wipe_mods()
end)

suite.test("commit destroys a Joker and creates a random Joker of the same rarity", function()
    local game = install_pack_full()
    local target = add(game, "j_cryp_python")
    use_slot_target(game, hold_consumable(game, "commit"), target)
    T.assert_eq(#game.jokers, 1, "one Joker remains")
    T.assert_true(game.jokers[1] ~= target, "the target was destroyed")
    T.assert_eq(game.jokers[1].def.rarity, 2, "the replacement shares the rarity (Uncommon)")
    wipe_mods()
end)

suite.test("rework destroys a Joker and the next shop Joker is that Joker, one edition up", function()
    local game = install_pack_full()
    local target = add(game, "j_greedy_joker")
    use_slot_target(game, hold_consumable(game, "rework"), target)
    T.assert_eq(#game.jokers, 0, "the target was destroyed")
    T.assert_eq(#game.tags, 1, "a Rework Tag is held")
    local tag = game.tags[1]
    T.assert_eq(tag.type, "cry_rework", "it is the Rework Tag")
    T.assert_eq(tag.ability.rework_key, "j_greedy_joker", "it remembers the Joker")
    T.assert_eq(tag.ability.rework_edition, "foil", "Base climbs to Foil")
    local draft = { id = "j_joker" }
    local fired = SMODS.tag_moment(game, "store_joker_create", { card = draft })
    T.assert_eq(fired, 1, "the tag fires on the next shop Joker")
    T.assert_eq(draft.id, "j_greedy_joker", "the draft becomes the reworked Joker")
    T.assert_eq(draft.edition, "foil", "with the climbed edition")
    T.assert_eq(#game.tags, 0, "the tag is consumed")
    wipe_mods()
end)

--------------------------------------------------------------------------------
-- Wave 1 (v1.3.0): sold-Joker history, game_over, joker_type_destroyed
--------------------------------------------------------------------------------

suite.test("kidnapping pays $4 per unique sold Type Joker", function()
    local game = install_pack()
    local kid = add(game, "j_cryp_kidnap")
    local def = JOKER_DEFS["j_cryp_kidnap"]
    local empty = def.smods.calc_dollar_bonus(def.smods, kid)
    T.assert_true(empty == nil or empty == 0, "no Type sales: no bonus")
    -- j_jolly counts by its "Type Mult" effect, j_sly by its name,
    -- j_cryp_nutty by its PC "Cry Type Mult" effect; the duplicate
    -- j_sly sale counts once, as PC's unique-key history does, and
    -- a plain Joker does not count at all.
    game.jokers_sold = { "j_jolly", "j_sly", "j_cryp_nutty", "j_sly", "j_joker" }
    T.assert_eq(def.smods.calc_dollar_bonus(def.smods, kid), 12,
        "3 unique Type Jokers at $4")
    local lines = SMODS.tooltip_lines("j_cryp_kidnap", kid)
    local text = table.concat(flatten(lines), " ")
    T.assert_true(text:find("$12", 1, true) ~= nil,
        "the tooltip shows the current $12: " .. text)
    wipe_mods()
end)

suite.test("necromancer resurrects a random sold Joker at $0 sell value", function()
    local game = install_pack()
    local necro = add(game, "j_cryp_necromancer")
    local other = add(game, "j_joker")
    fire(necro, "on_joker_sold", { joker = other })
    T.assert_eq(#game.jokers, 2, "empty history: nothing is created")
    game.jokers_sold = { "j_cryp_necromancer" }
    fire(necro, "on_joker_sold", { joker = other })
    T.assert_eq(#game.jokers, 2, "the Necromancer itself is never in the pool")
    game.jokers_sold = { "j_greedy_joker" }
    fire(necro, "on_joker_sold", { joker = other })
    T.assert_eq(#game.jokers, 3, "a sold Joker is created")
    local made = game.jokers[#game.jokers]
    T.assert_eq(made.def.id, "j_greedy_joker", "it is the sold Joker")
    T.assert_eq(made.sell_cost, 0, "with $0 sell value")
    wipe_mods()
end)

suite.test("pumpkin saves the run at 50% of the target, and only then", function()
    local game = install_pack()
    add(game, "j_cryp_pumpkin")
    game.round_score = 150
    game.current_blind_target = 300
    T.assert_eq(SMODS.game_over_saved(game), 1, "150 of 300: the Pumpkin saves")
    game.round_score = 149
    T.assert_true(SMODS.game_over_saved(game) == nil, "149 of 300: no save")
    wipe_mods()
end)

suite.test("pumpkin turns into carved pumpkin when destroyed, unless sold first", function()
    local game = install_pack()
    local pump = add(game, "j_cryp_pumpkin")
    fire(pump, "on_joker_type_destroyed", { joker = pump })
    T.assert_eq(#game.jokers, 2, "a Carved Pumpkin is created")
    T.assert_eq(game.jokers[#game.jokers].def.id, "j_cryp_carved_pumpkin",
        "the new Joker is the Carved Pumpkin")
    wipe_mods()
    game = install_pack()
    local pump2 = add(game, "j_cryp_pumpkin")
    fire(pump2, "on_joker_sold", { joker = pump2 })
    T.assert_eq(pump2.ability.extra.enabled, false, "selling disables the transformation")
    fire(pump2, "on_joker_type_destroyed", { joker = pump2 })
    T.assert_eq(#game.jokers, 1, "a sold Pumpkin does not transform")
    wipe_mods()
end)

suite.test("carved pumpkin disables boss blinds and is eaten after 5", function()
    local game = install_pack()
    T.assert_false(game:joker_allowed_in_random_pool("j_cryp_carved_pumpkin"),
        "Carved Pumpkin stays out of the pool (in_pool = false)")
    local carved = add(game, "j_cryp_carved_pumpkin")
    local disabled = false
    game.disable_boss_blind = function(self) disabled = true end
    game.current_blind_index = 3
    fire(carved, "on_blind_selected", {})
    T.assert_true(disabled, "the Boss Blind is disabled at setting_blind")
    for _ = 1, 4 do fire(carved, "on_round_end", {}) end
    T.assert_eq(carved.ability.extra.disables, 1, "four Boss rounds counted down")
    T.assert_eq(#game.jokers, 1, "still held at 1 disable left")
    fire(carved, "on_round_end", {})
    T.assert_eq(#game.jokers, 0, "destroyed when the disables reach 0")
    wipe_mods()
    game = install_pack()
    local carved2 = add(game, "j_cryp_carved_pumpkin")
    game.current_blind_index = 1
    fire(carved2, "on_round_end", {})
    T.assert_eq(carved2.ability.extra.disables, 5, "a Small Blind does not count down")
    wipe_mods()
end)

suite.test("familiar currency pays $19 for a random Meme Joker at round end", function()
    local game = install_pack()
    local fam = add(game, "j_cryp_familiar_currency")
    G.money = 100
    fire(fam, "on_round_end", {})
    T.assert_eq(#game.jokers, 2, "a Meme Joker is created")
    T.assert_eq(G.money, 81, "$19 was paid")
    local meme_ids = { j_cryp_happyhouse = true, j_cryp_cube = true, j_cryp_nice = true,
        j_cryp_chad = true, j_cryp_jimball = true, j_cryp_sus = true,
        j_cryp_krustytheclown = true, j_cryp_blurred = true, j_cryp_filler = true,
        j_cryp_lebaron_james = true, j_cryp_wario = true, j_cryp_m = true,
        j_cryp_boredom = true, j_cryp_curse_sob = true, j_cryp_bonk = true,
        j_cryp_reverse = true }
    local made = game.jokers[#game.jokers]
    T.assert_true(meme_ids[made.def.id] == true,
        "the created Joker is a Meme Joker: " .. tostring(made.def.id))
    wipe_mods()
    game = install_pack()
    local fam2 = add(game, "j_cryp_familiar_currency")
    G.money = 10
    fire(fam2, "on_round_end", {})
    T.assert_eq(#game.jokers, 1, "under $19: nothing is created")
    T.assert_eq(G.money, 10, "and nothing is charged")
    wipe_mods()
end)

suite.test("alttab creates the current blind's skip tag", function()
    local game = install_pack_full()
    game.skips = { 0, 0 }
    game.current_blind_index = 1
    use_slot(game, hold_consumable(game, "alttab"))
    T.assert_eq(#game.tags, 1, "one tag is gained")
    T.assert_eq(game.tags[1].type, "uncommon", "it is the Small Blind's skip Tag")
    wipe_mods()
end)

suite.test("alttab rolls a random tag on a boss blind and a cat tag with kitty printer", function()
    local game = install_pack_full()
    local captured = nil
    game.addTag = function(self, typ, opts) captured = typ end
    game.current_blind_index = 3
    use_slot(game, hold_consumable(game, "alttab"))
    T.assert_true(type(captured) == "string" and captured ~= "",
        "a Boss Blind grants some tag type: " .. tostring(captured))
    wipe_mods()
    game = install_pack_full()
    add(game, "j_cryp_kittyprinter")
    game.current_blind_index = 1
    use_slot(game, hold_consumable(game, "alttab"))
    T.assert_eq(game.tags[#game.tags].type, "cry_cat",
        "a held Kitty Printer makes it a Cat Tag")
    wipe_mods()
end)

return suite
