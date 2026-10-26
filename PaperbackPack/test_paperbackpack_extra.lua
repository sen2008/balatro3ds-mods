--- Tests for the PaperbackPack expansion Jokers (the 188 ported after the
--- original 36) for the Balatro3DS fork build. Registration and tooltip
--- sanity for all 291 Jokers in the pack, plus the per-slice behavior
--- suites (PB_TESTS_0 .. PB_TESTS_8). The mod's real main file is read
--- from the PB_PACK_LUA env var, like the other pack suites.
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

local NAMES = {
    "aurora_borealis", "bicycle", "emergency_broadcast", "find_jimbo",
    "guns_blazin", "insurance_policy", "malibu", "trust_us",
    "attacking_vertical", "better_call_jimbo", "calling_card", "claw",
    "giga_size", "grand_strategy", "jacks", "jestrica",
    "magic_mushroom", "mismatched_sock", "nazar", "planchette",
    "satellite_array", "technology", "toppins", "union_card",
    "the_quiet", "pocket_pair", "rosary_beads", "surfer",
    "the_girl_from_024", "tian_tian", "time_regression_mix", "57_leaf_clover",
    "unionized_labor", "park_postcard", "river", "langely",
    "56_leaf_clover", "ghost_cola", "shadowmantle", "a_balatro_movie",
    "alert", "ampersand", "apple", "autumn_leaves",
    "b_soda", "bamboo_stick", "banana_man", "basic_energy",
    "big_misser", "birches", "bismuth", "black_forest_cake",
    "black_knife", "black_rainbows", "black_star", "blade_dance",
    "blazing_trails", "blue_bonnets", "blue_curacao", "blue_marble",
    "book_of_vengeance", "boundary_of_death", "buckshot", "cakepop",
    "caramel_apple", "card_sleeve", "cardboard_box", "cast_iron",
    "champagne", "charred_marshmallow", "cherry_blossoms", "chocolate_coins",
    "coffee", "complete_breakfast", "deadringer", "degenerate_joker",
    "der_fluschutze", "der_freischutz", "derecho", "deviled_egg",
    "disco", "donor_card", "doppler_radar", "double_dutchman",
    "dreamsicle", "emf_reader", "epic_sauce", "evergreens",
    "eyelander", "first_contact", "forlorn", "fraudulent_joker",
    "freezer", "freight", "full_moon", "furioso",
    "gambit", "golden_apple", "golden_egg", "great_wave",
    "hamsa", "hamsa_r", "hatred", "heretical_joker",
    "high_speed_rail", "hole_in_one", "hotel_guest", "i_wish_that_i_could_fall",
    "ice_cube", "inner_peace", "its_tv_time", "jester",
    "jestosterone", "jestrogen", "jimbos_inferno", "jimbos_joyous_joker_jamboree",
    "joke_master", "joker_cd_i", "joker_cookie", "joker_crossing",
    "joker_duty", "joker_jacks", "journal", "keycard",
    "king_me", "legacy", "loaded_dice", "lone_digger",
    "lurid_joker", "man", "mandela_effect", "marble_soda",
    "master_spark", "matcha", "meeple", "mezzetino",
    "mind_electric", "moneyback", "moribund", "moving_out",
    "nazca_lines", "ncj", "nigiri", "off_switch",
    "one_shift_more", "paralyzed", "paranoia", "pear",
    "pedrillo", "percussion_ensemble", "pointy_stick", "ponzu",
    "pool_table", "pop_stick", "popsicle_stick", "power_surge",
    "prescript", "pride_flag", "prince_of_darkness", "prism",
    "punch_card", "pyrite", "quick_fix", "red_key",
    "red_sun_in_the_sky", "redscreen", "reference_card", "resurrections",
    "rock_candy", "rockin_stick", "roulette", "royalty_free",
    "sacrificial_lamb", "sake_cup", "scorecard", "seven_stars",
    "shabu_shabu", "shooting_star", "showdown", "shugi_bukuro",
    "shuttle", "silent_assassin", "sinister_minds", "skydiver",
    "small_scale_onshore_wind", "soft_taco", "solar_eclipse", "solar_system",
    "solemn_lament", "stamp", "sticky_stick", "stout",
    "subterfuge", "summoning_circle", "superjoker", "sweet_stick",
    "takoyaki", "tanghulu", "telamon", "the_batter",
    "the_dynasty", "the_normal_joker", "the_one_who_waits", "the_sun",
    "thornring", "tome", "torii", "towering_pillar_of_hats",
    "trans_flag", "triple_moon_goddess", "tropic_birds", "tutor",
    "twenty_first_century", "ultra_rare", "war_without_reason", "wheat_field",
    "whitebeard", "wild_plus_four", "wild_prize", "wish_you_were_here",
    "yacht", "yacht_dice", "you_are_a_fool", "zealous_joker",
    "collector", "festive_joker", "greeting_card", "happy_accident",
        "kintsugi_joker", "mexican_train", "plastic_wrap", "sommelier",
        "spotty_joker", "teapot", "watercolor_joker", "pinot_noir",
        "gauze", "blue_star", "chocolate_joker", "crispy_taco",
        "deck_of_cards", "nachos", "oracle", "quartz",
        "ready_to_fly", "stella_octangula", "angel_investor", "book_of_life",
        "j_and_js", "jimbo_adventure", "jokers_11", "shopkeep",
        "spirit_box", "stereoscopic_specs", "the_wonder_of_you", "let_it_happen",
        "coin_collection", "frutiger_aero", "cream_liqueur", "off_alpha",
        "off_epsilon", "off_omega", "one_with_nothing", "watermelon",
        "weather_radio", "da_capo", "jester_of_nihil", "cross",
        "unholy_alliance",
    "milk_tea", "stardrop", "bergentrucking", "freedom_of_choice",
    "grenadine", "shinzaemon", "nigori", "aperol", "pink_joker",
    "sacred_heart", "determination",
    "forgery", "master_plan", "photocopy",
    "backpack", "protocol", "shopping_center", "touch_tone_joker",
    "chaplin", "everything_must_go", "normalJKR", "oujia_board",
}

local ARCANA = {
    "ace_of_pentacles", "ace_of_swords", "two_of_cups", "four_of_cups",
    "seven_of_cups", "eight_of_cups", "nine_of_cups", "ten_of_cups",
    "knight_of_cups", "king_of_cups", "six_of_cups", "two_of_wands",
    "three_of_wands", "five_of_wands", "eight_of_wands", "ten_of_wands",
    "king_of_wands", "four_of_swords", "five_of_swords", "nine_of_swords",
    "ten_of_swords", "knight_of_swords", "queen_of_swords", "king_of_swords",
    "two_of_pentacles", "three_of_pentacles", "four_of_pentacles",
    "six_of_pentacles", "eight_of_pentacles", "ten_of_pentacles",
    "queen_of_pentacles", "knight_of_pentacles", "king_of_pentacles",
    "five_of_cups", "five_of_pentacles", "queen_of_cups",
    "nine_of_wands", "knight_of_wands", "seven_of_wands",
    "queen_of_wands", "page_of_pentacles", "page_of_swords",
    "six_of_wands", "three_of_swords", "two_of_swords",
}

local function install_pack()
    wipe_mods()
    local path = os.getenv("PB_PACK_LUA")
    assert(path, "PB_PACK_LUA not set")
    local fh = assert(io.open(path, "rb"))
    local main = fh:read("*a")
    fh:close()
    local base = ModLoader.DIR .. "/PaperbackPack"
    love.filesystem.createDirectory(base)
    love.filesystem.write(base .. "/PaperbackPack.json", [[{
        "id": "PaperbackPack", "name": "Paperback Pack", "prefix": "pbp",
        "main_file": "paperbackpack.lua", "version": "1.0.0",
        "author": ["Nether and contributors", "3DS port"]
    }]])
    love.filesystem.write(base .. "/paperbackpack.lua", main)
    for _, n in ipairs(NAMES) do
        love.filesystem.write(base .. "/assets/1x/" .. n .. ".png", "png")
        love.filesystem.write(base .. "/assets/1x/" .. n .. "_negative.png", "png")
    end
    for _, n in ipairs(ARCANA) do
        love.filesystem.write(base .. "/assets/1x/" .. n .. ".png", "png")
        love.filesystem.write(base .. "/assets/1x/" .. n .. "_negative.png", "png")
    end
    for _, n in ipairs({
        "jimbo_adventure_soul", "off_alpha_soul", "off_epsilon_soul",
        "off_omega_soul", "stardrop_soul", "shinzaemon_soul",
        "chaplin_soul",
    }) do
        love.filesystem.write(base .. "/assets/1x/" .. n .. ".png", "png")
    end
    ModLoader.load_all()
    local game = bootstrap.new_game(7721)
    game.hand = Hand(game)
    game.deck = Deck(game)
    G = game
    G.play = G.play or SMODS.PLAY
    _G.Top = _G.Top or { addPopup = function() end }
    return game
end

local function add(game, id)
    game.jokers = game.jokers or {}
    -- The added Joker takes the next slot; add_to_deck creations (OFF
    -- Switch spawning The Batter) append after it, so index, not last.
    local idx = #game.jokers + 1
    T.assert_true(game:add_joker_by_def(id), id .. " should be addable")
    return game.jokers[idx]
end

local function card(rank, suit, opts)
    local data = { rank = rank, suit = suit or "Hearts" }
    if opts then
        if opts.enhancement then data.enhancement = opts.enhancement end
        if opts.seal then data.seal = opts.seal end
        if opts.edition then data.edition = opts.edition end
    end
    local c = Card(0, 0, 1, 1, data)
    c.counts_for_play_score = true
    return c
end

local function scored(joker, extra)
    local ctx = { event = "on_hand_scored", event_name = "on_hand_scored", chips = 10, mult = 2 }
    for k, v in pairs(extra or {}) do ctx[k] = v end
    ctx.cards = ctx.cards or ctx.played_cards
    if joker:matches_trigger(ctx.event_name, ctx) then joker:apply_effect(ctx) end
    return ctx
end

local function play_card(joker, node, played)
    local ctx = { event = "card_played", event_name = "card_played", chips = 0, mult = 1,
        rank = node.card_data.rank, suit = node.card_data.suit, card_node = node,
        played_cards = played, full_hand = played }
    if joker:matches_trigger("card_played", ctx) then joker:apply_effect(ctx) end
    return ctx
end

local function before(joker, extra)
    local ctx = { event = "on_hand_played", event_name = "on_hand_played", chips = 0, mult = 1 }
    for k, v in pairs(extra or {}) do ctx[k] = v end
    ctx.cards = ctx.cards or ctx.played_cards
    if joker:matches_trigger(ctx.event_name, ctx) then joker:apply_effect(ctx) end
    return ctx
end

local function fire(joker, event_name, extra)
    local ctx = { event = event_name, event_name = event_name }
    for k, v in pairs(extra or {}) do ctx[k] = v end
    if joker:matches_trigger(event_name, ctx) then joker:apply_effect(ctx) end
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

--------------------------------------------------------------------------------
-- Registration + tooltips for the whole pack
--------------------------------------------------------------------------------

suite.test("pack loads and registers all 291 Paperback Jokers", function()
    local game = install_pack()
    local mod = ModLoader.by_id.PaperbackPack
    T.assert_eq(mod.status, "loaded", tostring(mod.error))
    T.assert_eq(#mod.registered.jokers, 291)
    local expect = {
        j_pbp_aurora_borealis = { "Aurora Borealis", 2, 6 },
        j_pbp_bicycle = { "Bicycle", 2, 6 },
        j_pbp_emergency_broadcast = { "Emergency Broadcast", 1, 6 },
        j_pbp_find_jimbo = { "Find Jimbo", 1, 4 },
        j_pbp_guns_blazin = { "Guns Blazin'", 2, 8 },
        j_pbp_insurance_policy = { "Insurance Policy", 2, 6 },
        j_pbp_malibu = { "Malibu", 2, 7 },
        j_pbp_trust_us = { "Trust Us!", 2, 6 },
        j_pbp_attacking_vertical = { "Attacking Vertical", 3, 8 },
        j_pbp_better_call_jimbo = { "Better Call Jimbo", 3, 8 },
        j_pbp_calling_card = { "Calling Card", 2, 6 },
        j_pbp_claw = { "Claw", 1, 3 },
        j_pbp_giga_size = { "GIGA SIZE", 3, 8 },
        j_pbp_grand_strategy = { "Grand Strategy", 3, 8 },
        j_pbp_jacks = { "Jacks", 1, 5 },
        j_pbp_jestrica = { "Jestrica", 1, 5 },
        j_pbp_magic_mushroom = { "Magic Mushroom", 3, 8 },
        j_pbp_mismatched_sock = { "Mismatched Sock", 2, 6 },
        j_pbp_nazar = { "Nazar", 1, 5 },
        j_pbp_planchette = { "Planchette", 2, 6 },
        j_pbp_satellite_array = { "Satellite Array", 2, 7 },
        j_pbp_technology = { "Technology", 2, 8 },
        j_pbp_toppins = { "Toppins", 1, 5 },
        j_pbp_union_card = { "Union Card", 3, 8 },
        j_pbp_the_quiet = { "The Quiet", 3, 8 },
        j_pbp_pocket_pair = { "Pocket Pair", 1, 5 },
        j_pbp_rosary_beads = { "Rosary Beads", 1, 4 },
        j_pbp_surfer = { "Surfer", 2, 7 },
        j_pbp_the_girl_from_024 = { "The Girl From 024", 2, 7 },
        j_pbp_tian_tian = { "Tian Tian", 3, 7 },
        j_pbp_time_regression_mix = { "Time Regression Mix", 1, 3 },
        j_pbp_57_leaf_clover = { "57 Leaf Clover", 3, 7 },
        j_pbp_unionized_labor = { "Unionized Labor", 2, 7 },
        j_pbp_park_postcard = { "Park Postcard", 3, 8 },
        j_pbp_river = { "River", 2, 7 },
        j_pbp_langely = { "L'angely", 4, 20 },
        j_pbp_56_leaf_clover = { "56 Leaf Clover", 2, 6 },
        j_pbp_ghost_cola = { "Ghost Cola", 2, 6 },
        j_pbp_shadowmantle = { "ShadowMantle", 3, 8 },
        j_pbp_a_balatro_movie = { "A Balatro Movie", 1, 4 },
        j_pbp_alert = { "Alert", 2, 4 },
        j_pbp_ampersand = { "&", 1, 3 },
        j_pbp_apple = { "Apple", 1, 1 },
        j_pbp_autumn_leaves = { "Autumn Leaves", 2, 6 },
        j_pbp_b_soda = { "B-Soda", 1, 4 },
        j_pbp_bamboo_stick = { "Bamboo Stick", 1, 7 },
        j_pbp_banana_man = { "Banana Man", 3, 8 },
        j_pbp_basic_energy = { "Basic Joker Energy", 2, 6 },
        j_pbp_big_misser = { "Big Misser", 2, 6 },
        j_pbp_birches = { "Birches", 2, 6 },
        j_pbp_bismuth = { "Bismuth", 2, 7 },
        j_pbp_black_forest_cake = { "Black Forest Cake", 1, 3 },
        j_pbp_black_knife = { "Black Knife", 3, 9 },
        j_pbp_black_rainbows = { "Black Rainbows", 2, 8 },
        j_pbp_black_star = { "Black Star", 3, 6 },
        j_pbp_blade_dance = { "Blade Dance", 2, 6 },
        j_pbp_blazing_trails = { "Blazing Trails", 2, 6 },
        j_pbp_blue_bonnets = { "Blue Bonnets", 2, 6 },
        j_pbp_blue_curacao = { "Blue Curaçao", 2, 6 },
        j_pbp_blue_marble = { "Blue Marble", 1, 3 },
        j_pbp_book_of_vengeance = { "Book of Vengeance", 3, 9 },
        j_pbp_boundary_of_death = { "Boundary of Death", 2, 8 },
        j_pbp_buckshot = { "Buckshot", 2, 6 },
        j_pbp_cakepop = { "Cakepop", 1, 6 },
        j_pbp_caramel_apple = { "Caramel Apple", 1, 6 },
        j_pbp_card_sleeve = { "Card Sleeve", 1, 4 },
        j_pbp_cardboard_box = { "Cardboard Box", 2, 7 },
        j_pbp_cast_iron = { "Cast Iron", 2, 7 },
        j_pbp_champagne = { "Champagne", 1, 5 },
        j_pbp_charred_marshmallow = { "Charred Marshmallow", 1, 6 },
        j_pbp_cherry_blossoms = { "Cherry Blossoms", 2, 6 },
        j_pbp_chocolate_coins = { "Chocolate Coins", 1, 6 },
        j_pbp_coffee = { "Coffee", 2, 6 },
        j_pbp_complete_breakfast = { "Complete Breakfast", 1, 4 },
        j_pbp_deadringer = { "Deadringer", 3, 7 },
        j_pbp_degenerate_joker = { "Degenerate Joker", 1, 4 },
        j_pbp_der_fluschutze = { "Der Fluschütze", 3, 9 },
        j_pbp_der_freischutz = { "Der Freischütz", 2, 6 },
        j_pbp_derecho = { "Derecho", 2, 6 },
        j_pbp_deviled_egg = { "Deviled Egg", 1, 5 },
        j_pbp_disco = { "Disco Joker", 2, 7 },
        j_pbp_donor_card = { "Donor Card", 2, 6 },
        j_pbp_doppler_radar = { "Doppler Radar", 2, 7 },
        j_pbp_double_dutchman = { "Double Dutchman", 3, 8 },
        j_pbp_dreamsicle = { "Dreamsicle", 1, 6 },
        j_pbp_emf_reader = { "EMF Reader", 3, 8 },
        j_pbp_epic_sauce = { "Epic Sauce", 3, 8 },
        j_pbp_evergreens = { "Evergreens", 2, 6 },
        j_pbp_eyelander = { "Eyelander", 3, 8 },
        j_pbp_first_contact = { "First Contact", 3, 8 },
        j_pbp_forlorn = { "Forlorn", 1, 6 },
        j_pbp_fraudulent_joker = { "Fraudulent Joker", 1, 5 },
        j_pbp_freezer = { "Freezer", 3, 7 },
        j_pbp_freight = { "Freight", 2, 8 },
        j_pbp_full_moon = { "Full Moon", 2, 7 },
        j_pbp_furioso = { "Furioso", 2, 6 },
        j_pbp_gambit = { "Gambit", 2, 6 },
        j_pbp_golden_apple = { "Golden Apple", 2, 7 },
        j_pbp_golden_egg = { "Golden Egg", 3, 8 },
        j_pbp_great_wave = { "Great Wave", 3, 8 },
        j_pbp_hamsa = { "Hamsa", 1, 5 },
        j_pbp_hamsa_r = { "Hamsa", 1, 5 },
        j_pbp_hatred = { "HATRED", 2, 5 },
        j_pbp_heretical_joker = { "Heretical Joker", 1, 5 },
        j_pbp_high_speed_rail = { "High Speed Rail", 1, 3 },
        j_pbp_hole_in_one = { "Hole in One", 3, 8 },
        j_pbp_hotel_guest = { "Hotel Guest", 3, 5 },
        j_pbp_i_wish_that_i_could_fall = { "I Wish That I Could Fall", 3, 7 },
        j_pbp_ice_cube = { "Ice Cube", 1, 4 },
        j_pbp_inner_peace = { "Inner Peace", 2, 6 },
        j_pbp_its_tv_time = { "It's TV Time!", 1, 5 },
        j_pbp_jester = { "Jester", 2, 7 },
        j_pbp_jestosterone = { "Jestosterone", 1, 5 },
        j_pbp_jestrogen = { "Jestrogen", 1, 5 },
        j_pbp_jimbos_inferno = { "Jimbo's Inferno", 1, 5 },
        j_pbp_jimbos_joyous_joker_jamboree = { "Jimbo's Joyous Joker Jamboree", 2, 6 },
        j_pbp_joke_master = { "Joke Master", 1, 3 },
        j_pbp_joker_cd_i = { "Joker CD-i", 1, 3 },
        j_pbp_joker_cookie = { "Joker Cookie", 1, 1 },
        j_pbp_joker_crossing = { "Joker Crossing", 2, 8 },
        j_pbp_joker_duty = { "Joker Duty", 1, 6 },
        j_pbp_joker_jacks = { "Joker Jacks", 1, 6 },
        j_pbp_journal = { "Journal", 2, 6 },
        j_pbp_keycard = { "Keycard", 2, 5 },
        j_pbp_king_me = { "King Me", 1, 6 },
        j_pbp_legacy = { "Legacy", 3, 8 },
        j_pbp_loaded_dice = { "Loaded Dice", 1, 6 },
        j_pbp_lone_digger = { "Lone Digger", 3, 8 },
        j_pbp_lurid_joker = { "Lurid Joker", 1, 3 },
        j_pbp_man = { "Man", 2, 7 },
        j_pbp_mandela_effect = { "Mandela Effect", 1, 4 },
        j_pbp_marble_soda = { "Marble Soda", 2, 6 },
        j_pbp_master_spark = { "Master Spark", 3, 8 },
        j_pbp_matcha = { "Matcha", 1, 3 },
        j_pbp_meeple = { "Meeple", 1, 6 },
        j_pbp_mezzetino = { "Mezzetino", 2, 7 },
        j_pbp_mind_electric = { "The Mind Electric", 3, 3 },
        j_pbp_moneyback = { "Moneyback", 1, 6 },
        j_pbp_moribund = { "Moribund", 2, 6 },
        j_pbp_moving_out = { "Moving Out", 1, 4 },
        j_pbp_nazca_lines = { "Nazca Lines", 1, 6 },
        j_pbp_ncj = { "NoCopyrightJokers", 1, 5 },
        j_pbp_nigiri = { "Nigiri", 3, 6 },
        j_pbp_off_switch = { "OFF Switch", 4, 13 },
        j_pbp_one_shift_more = { "One Shift More", 2, 7 },
        j_pbp_paralyzed = { "Paralyzed", 2, 7 },
        j_pbp_paranoia = { "Paranoia", 3, 8 },
        j_pbp_pear = { "Pear", 1, 4 },
        j_pbp_pedrillo = { "Pedrillo", 4, 20 },
        j_pbp_percussion_ensemble = { "Percussion Ensemble", 2, 7 },
        j_pbp_pointy_stick = { "Pointy Stick", 1, 7 },
        j_pbp_ponzu = { "Ponzu", 1, 6 },
        j_pbp_pool_table = { "Pool Table", 3, 8 },
        j_pbp_pop_stick = { "Pop-Stick", 1, 7 },
        j_pbp_popsicle_stick = { "Popsicle Stick", 1, 7 },
        j_pbp_power_surge = { "Power Surge", 3, 8 },
        j_pbp_prescript = { "Prescript", 2, 6 },
        j_pbp_pride_flag = { "Pride Flag", 1, 6 },
        j_pbp_prince_of_darkness = { "Prince of Darkness", 2, 7 },
        j_pbp_prism = { "Prism", 2, 6 },
        j_pbp_punch_card = { "Punch Card", 3, 10 },
        j_pbp_pyrite = { "Pyrite", 2, 7 },
        j_pbp_quick_fix = { "Quick Fix", 1, 6 },
        j_pbp_red_key = { "Red Key", 2, 7 },
        j_pbp_red_sun_in_the_sky = { "Red Sun in the Sky", 1, 5 },
        j_pbp_redscreen = { "Redscreen", 2, 6 },
        j_pbp_reference_card = { "Reference Card", 2, 6 },
        j_pbp_resurrections = { "Resurrections", 3, 8 },
        j_pbp_rock_candy = { "Rock Candy", 1, 6 },
        j_pbp_rockin_stick = { "Rockin' Stick", 1, 7 },
        j_pbp_roulette = { "Roulette", 2, 7 },
        j_pbp_royalty_free = { "Royalty Free", 1, 4 },
        j_pbp_sacrificial_lamb = { "Sacrificial Lamb", 1, 6 },
        j_pbp_sake_cup = { "Sake Cup", 3, 8 },
        j_pbp_scorecard = { "Scorecard", 2, 7 },
        j_pbp_seven_stars = { "Seven Stars", 3, 8 },
        j_pbp_shabu_shabu = { "Shabu Shabu", 3, 10 },
        j_pbp_shooting_star = { "Shooting Star", 2, 6 },
        j_pbp_showdown = { "Showdown", 1, 5 },
        j_pbp_shugi_bukuro = { "Shūgi Bukuro", 1, 6 },
        j_pbp_shuttle = { "Shuttle", 1, 6 },
        j_pbp_silent_assassin = { "Silent Assassin", 1, 8 },
        j_pbp_sinister_minds = { "Sinister Minds", 3, 8 },
        j_pbp_skydiver = { "Skydiver", 2, 6 },
        j_pbp_small_scale_onshore_wind = { "Small Scale Onshore Wind", 1, 6 },
        j_pbp_soft_taco = { "Soft Taco", 2, 6 },
        j_pbp_solar_eclipse = { "Solar Eclipse", 3, 6 },
        j_pbp_solar_system = { "Solar System", 2, 8 },
        j_pbp_solemn_lament = { "Solemn Lament", 3, 8 },
        j_pbp_stamp = { "Stamp", 3, 8 },
        j_pbp_sticky_stick = { "Sticky Stick", 1, 7 },
        j_pbp_stout = { "Stout", 2, 6 },
        j_pbp_subterfuge = { "Subterfuge", 3, 8 },
        j_pbp_summoning_circle = { "Summoning Circle", 3, 8 },
        j_pbp_superjoker = { "SUPERJOKER", 2, 5 },
        j_pbp_sweet_stick = { "Sweet Stick", 1, 7 },
        j_pbp_takoyaki = { "Takoyaki", 1, 6 },
        j_pbp_tanghulu = { "Tanghulu", 1, 6 },
        j_pbp_telamon = { "Telamon", 2, 6 },
        j_pbp_the_batter = { "The Batter", 2, 4 },
        j_pbp_the_dynasty = { "The Dynasty", 3, 8 },
        j_pbp_the_normal_joker = { "The Normal Joker", 3, 8 },
        j_pbp_the_one_who_waits = { "The One Who Waits", 3, 8 },
        j_pbp_the_sun = { "The Sun", 1, 3 },
        j_pbp_thornring = { "ThornRing", 3, 7 },
        j_pbp_tome = { "Tome", 2, 6 },
        j_pbp_torii = { "Torii", 3, 8 },
        j_pbp_towering_pillar_of_hats = { "Towering Pillar of Hats", 1, 6 },
        j_pbp_trans_flag = { "Trans Flag", 1, 6 },
        j_pbp_triple_moon_goddess = { "Triple Moon Goddess", 2, 6 },
        j_pbp_tropic_birds = { "Tropic Birds", 1, 6 },
        j_pbp_tutor = { "Tutor", 1, 6 },
        j_pbp_twenty_first_century = { "21st Century Joker", 3, 10 },
        j_pbp_ultra_rare = { "Ultra Rare", 3, 9 },
        j_pbp_war_without_reason = { "War Without Reason", 2, 6 },
        j_pbp_wheat_field = { "Wheat Field", 2, 6 },
        j_pbp_whitebeard = { "Whitebeard", 3, 8 },
        j_pbp_wild_plus_four = { "Wild +4", 3, 10 },
        j_pbp_wild_prize = { "Wild Prize!", 1, 7 },
        j_pbp_wish_you_were_here = { "Wish You Were Here", 2, 6 },
        j_pbp_yacht = { "Yacht", 1, 5 },
        j_pbp_yacht_dice = { "Yacht Dice", 3, 8 },
        j_pbp_you_are_a_fool = { "You Are a Fool!", 3, 8 },
        j_pbp_zealous_joker = { "Zealous Joker", 1, 3 },
        j_pbp_milk_tea = { "Milk Tea", 2, 6 },
        j_pbp_stardrop = { "Stardrop", 2, 7 },
        j_pbp_bergentrucking = { "Bergentrücking", 3, 8 },
        j_pbp_freedom_of_choice = { "Freedom of Choice", 3, 8 },
        j_pbp_grenadine = { "Grenadine", 2, 6 },
        j_pbp_shinzaemon = { "Shinzaemon", 4, 20 },
        j_pbp_nigori = { "Nigori", 2, 6 },
        j_pbp_aperol = { "Aperol", 2, 6 },
        j_pbp_pink_joker = { "Pink Joker", 1, 7 },
        j_pbp_sacred_heart = { "Sacred Heart", 3, 10 },
        j_pbp_determination = { "Determination", 3, 7 },
        j_pbp_forgery = { "Forgery", 3, 2 },
        j_pbp_master_plan = { "Master Plan", 3, 10 },
        j_pbp_photocopy = { "Photocopy", 3, 10 },
        j_pbp_backpack = { "Backpack", 1, 4 },
        j_pbp_protocol = { "Protocol", 1, 5 },
        j_pbp_shopping_center = { "Shopping Center", 1, 6 },
        j_pbp_everything_must_go = { "Everything Must Go!", 2, 6 },
        j_pbp_normalJKR = { "normalJKR", 1, 6 },
        j_pbp_touch_tone_joker = { "Touch Tone Joker", 2, 8 },
        j_pbp_chaplin = { "Chaplin", 4, 20 },
        j_pbp_oujia_board = { "Ouija Board", 3, 8 },
    }
    for id, e in pairs(expect) do
        local def = JOKER_DEFS[id]
        T.assert_true(def ~= nil, id .. " registered")
        T.assert_eq(def.name, e[1], id .. " name")
        T.assert_eq(def.rarity, e[2], id .. " rarity")
        T.assert_eq(def.cost, e[3], id .. " cost")
    end
    wipe_mods()
end)

suite.test("every Joker has a clean tooltip (no raw placeholders, no functions)", function()
    local game = install_pack()
    for _, n in ipairs(NAMES) do
        game.jokers = {}
        local j = add(game, "j_pbp_" .. n)
        local lines = SMODS.tooltip_lines("j_pbp_" .. n, j)
        T.assert_true(type(lines) == "table" and #lines >= 1, n .. " tooltip has lines")
        local text = table.concat(flatten(lines), " ")
        T.assert_true(text:find("#", 1, true) == nil, n .. " tooltip has no raw placeholder: " .. text)
        T.assert_true(text:find("function:", 1, true) == nil, n .. " tooltip has no raw function: " .. text)
    end
    wipe_mods()
end)

--------------------------------------------------------------------------------
-- Per-slice behavior suites
--------------------------------------------------------------------------------

local H = {}
function H.test(name, fn)
    suite.test(name, function()
        local game = install_pack()
        fn(game)
        wipe_mods()
    end)
end
function H.new_game() return install_pack() end
function H.make_joker(game, key) return add(game, "j_pbp_" .. key) end
H.fire = fire
H.scored = scored
H.play_card = play_card
H.before = before
H.node = card
H.assert_eq = function(a, b, msg) T.assert_eq(a, b, msg) end
H.assert_true = function(a, msg) T.assert_true(a, msg) end
function H.classify(game, nodes)
    local h = Hand(game)
    h.card_nodes, h.selected = {}, {}
    for _, nd in ipairs(nodes) do
        h.card_nodes[#h.card_nodes + 1] = nd
        h.selected[#h.selected + 1] = nd
    end
    h:calculate_play()
    return G.handlist and G.handlist[G.selectedHand]
end

PB_TESTS_0 = function(H)
    local function tag_spy(game)
        game._tags = {}
        game.addTag = function(self, t) self._tags[#self._tags + 1] = t end
        return game._tags
    end

    H.test("56 leaf clover: all-Clubs winning hand on the Boss makes a Negative Tag", function()
        local game = H.new_game()
        local tags = tag_spy(game)
        game.current_blind_index = 3
        local j = H.make_joker(game, "56_leaf_clover")
        local hand = { H.node(9, "Clubs"), H.node(12, "Clubs"), H.node(14, "Clubs") }
        H.before(j, { scoring_hand = hand, cards = hand })
        H.assert_eq(j.ability.extra.active, true)
        H.fire(j, "on_round_end", {})
        H.assert_eq(#tags, 1)
        H.assert_eq(tags[1], "negative")
    end)

    H.test("56 leaf clover: a non-Clubs scoring card or a non-Boss blind makes nothing", function()
        local game = H.new_game()
        local tags = tag_spy(game)
        game.current_blind_index = 3
        local j = H.make_joker(game, "56_leaf_clover")
        local hand = { H.node(9, "Clubs"), H.node(12, "Hearts") }
        H.before(j, { scoring_hand = hand, cards = hand })
        H.assert_eq(j.ability.extra.active, false)
        H.fire(j, "on_round_end", {})
        H.assert_eq(#tags, 0)
        local hand2 = { H.node(9, "Clubs") }
        game.current_blind_index = 1
        H.before(j, { scoring_hand = hand2, cards = hand2 })
        H.assert_eq(j.ability.extra.active, true)
        H.fire(j, "on_round_end", {})
        H.assert_eq(#tags, 0)
    end)

    H.test("ghost cola: selling it creates a Negative Tag and a random Spectral", function()
        local game = H.new_game()
        local tags = tag_spy(game)
        local made = {}
        game.can_add_consumable = function(self) return true end
        game.random_consumable_id_of_kind = function(self, kind) return "spectral_test" end
        game.add_consumable = function(self, id) made[#made + 1] = id; return true end
        local j = H.make_joker(game, "ghost_cola")
        H.fire(j, "on_joker_sold", {})
        H.assert_eq(#tags, 1)
        H.assert_eq(tags[1], "negative")
        H.assert_eq(made[1], "spectral_test")
    end)

    H.test("shadowmantle: re-arms at end of round; non-Stars cards never fire it", function()
        local game = H.new_game()
        tag_spy(game)
        local j = H.make_joker(game, "shadowmantle")
        j.ability.extra.active = false
        H.fire(j, "on_round_end", {})
        H.assert_eq(j.ability.extra.active, true)
        local ctx = H.play_card(j, H.node(10, "Hearts"), nil)
        H.assert_eq(j.ability.extra.active, true, "Hearts are not Stars: still armed, no roll consumed")
    end)
end

-- Behavior tests for PaperbackPack slice 1 (pb_frag_1.lua).
-- PB_TESTS_1(H) registers tests with the pack's headless harness.

PB_TESTS_1 = function(H)
    H.test("a_balatro_movie: repeating the previous hand type pays $2", function(game)
        local j = H.make_joker(game, "a_balatro_movie")
        H.fire(j, "on_hand_after", { hand_type = "Pair" })
        local money = game.money
        H.scored(j, { hand_type = "Pair" })
        assert(game.money == money + 2, "same hand as previous should pay $2, money=" .. tostring(game.money))
        H.fire(j, "on_hand_after", { hand_type = "Flush" })
        H.scored(j, { hand_type = "Pair" })
        assert(game.money == money + 2, "different hand should pay nothing")
    end)

    H.test("autumn_leaves: consecutive Diamonds grow the XMult, other suits reset it", function(game)
        local j = H.make_joker(game, "autumn_leaves")
        local d1 = H.node(5, "Diamonds")
        local ctx = H.play_card(j, d1, { d1 })
        assert(math.abs(ctx.mult - 1.05) < 0.001, "first Diamond X1.05, got " .. tostring(ctx.mult))
        local d2 = H.node(9, "Diamonds")
        ctx = H.play_card(j, d2, { d2 })
        assert(math.abs(ctx.mult - 1.10) < 0.001, "second consecutive Diamond X1.10, got " .. tostring(ctx.mult))
        local s1 = H.node(4, "Spades")
        H.play_card(j, s1, { s1 })
        local d3 = H.node(2, "Diamonds")
        ctx = H.play_card(j, d3, { d3 })
        assert(math.abs(ctx.mult - 1.05) < 0.001, "streak broken by a Spade: back to X1.05, got " .. tostring(ctx.mult))
    end)

    H.test("bamboo_stick: X2 only while another Stick Joker is held", function(game)
        local j = H.make_joker(game, "bamboo_stick")
        local ctx = H.scored(j, {})
        assert(ctx.mult == 2, "lone stick gives nothing, mult=" .. tostring(ctx.mult))
        H.make_joker(game, "bamboo_stick")
        ctx = H.scored(j, {})
        assert(ctx.mult == 4, "two sticks: X2, mult=" .. tostring(ctx.mult))
    end)

    H.test("blue_marble: using a Planet grows its Mult", function(game)
        local j = H.make_joker(game, "blue_marble")
        H.fire(j, "on_consumable_used", { consumable_kind = "tarot" })
        assert(j.ability.extra.mult == 0, "Tarot does not count")
        H.fire(j, "on_consumable_used", { consumable_kind = "planet" })
        assert(j.ability.extra.mult == 2, "one Planet: +2")
        local ctx = H.scored(j, {})
        assert(ctx.mult == 4, "joker_main pays +2 Mult, mult=" .. tostring(ctx.mult))
    end)

    H.test("cakepop: scored Hearts give +5 Mult, other suits nothing", function(game)
        local j = H.make_joker(game, "cakepop")
        local h = H.node(6, "Hearts")
        local ctx = H.play_card(j, h, { h })
        assert(ctx.mult == 6, "Heart gives +5 Mult, mult=" .. tostring(ctx.mult))
        local c = H.node(6, "Clubs")
        ctx = H.play_card(j, c, { c })
        assert(ctx.mult == 1, "Club gives nothing, mult=" .. tostring(ctx.mult))
    end)

    H.test("champagne: Boss Blind scored cards pay $1, doubled with a seal", function(game)
        local j = H.make_joker(game, "champagne")
        game.current_blind_index = 3
        local money = game.money
        local plain = H.node(10, "Hearts")
        H.play_card(j, plain, { plain })
        assert(game.money == money + 1, "unsealed card pays $1, money=" .. tostring(game.money))
        local sealed = H.node(10, "Clubs", { seal = "gold" })
        H.play_card(j, sealed, { sealed })
        assert(game.money == money + 3, "sealed card pays $2, money=" .. tostring(game.money))
        game.current_blind_index = 1
        local off = H.node(10, "Hearts")
        H.play_card(j, off, { off })
        assert(game.money == money + 3, "no pay outside a Boss Blind")
    end)

    H.test("complete_breakfast: pays +50 Chips and +5 Mult on joker_main", function(game)
        local j = H.make_joker(game, "complete_breakfast")
        local ctx = H.scored(j, {})
        assert(ctx.chips == 60, "chips 10 + 50, got " .. tostring(ctx.chips))
        assert(ctx.mult == 7, "mult 2 + 5, got " .. tostring(ctx.mult))
    end)

    H.test("derecho: an all-dark scored hand grows its XMult", function(game)
        local j = H.make_joker(game, "derecho")
        local played = { H.node(5, "Spades"), H.node(9, "Clubs") }
        H.before(j, { played_cards = played })
        assert(math.abs(j.ability.extra.xm - 1.1) < 0.001, "all dark: X1.1, got " .. tostring(j.ability.extra.xm))
        local mixed = { H.node(5, "Spades"), H.node(9, "Hearts") }
        H.before(j, { played_cards = mixed })
        assert(math.abs(j.ability.extra.xm - 1.1) < 0.001, "a light card blocks growth")
        local ctx = H.scored(j, {})
        assert(math.abs(ctx.mult - 2.2) < 0.001, "joker_main pays X1.1, mult=" .. tostring(ctx.mult))
    end)

    H.test("deviled_egg: first scored card of the round becomes Gold, once per round", function(game)
        local j = H.make_joker(game, "deviled_egg")
        local a, b = H.node(4, "Clubs"), H.node(8, "Spades")
        H.before(j, { played_cards = { a, b } })
        assert(a.card_data.enhancement == "gold", "first card becomes Gold, got " .. tostring(a.card_data.enhancement))
        local c = H.node(3, "Hearts")
        H.before(j, { played_cards = { c } })
        assert(c.card_data.enhancement == nil, "second hand in the round is not converted")
        H.fire(j, "on_round_end", {})
        local d = H.node(7, "Diamonds")
        H.before(j, { played_cards = { d } })
        assert(d.card_data.enhancement == "gold", "re-arms next round")
    end)

    H.test("disco: buying while holding $25 or less grows its Mult", function(game)
        local j = H.make_joker(game, "disco")
        game.money = 25
        H.fire(j, "on_shop_buy", { offer_kind = "joker", offer_id = "j_joker", offer_price = 5 })
        assert(j.ability.extra.mult == 2, "buy at $25: +2 Mult, got " .. tostring(j.ability.extra.mult))
        game.money = 26
        H.fire(j, "on_shop_buy", { offer_kind = "joker", offer_id = "j_joker", offer_price = 5 })
        assert(j.ability.extra.mult == 2, "buy at $26: no growth")
        local ctx = H.scored(j, {})
        assert(ctx.mult == 4, "joker_main pays +2 Mult, mult=" .. tostring(ctx.mult))
    end)

    H.test("donor_card: scored Hearts grow Mult and lose 2 Chips", function(game)
        local j = H.make_joker(game, "donor_card")
        local h = H.node(5, "Hearts")
        H.play_card(j, h, { h })
        assert(j.ability.extra.mult == 1, "one Heart: +1 Mult, got " .. tostring(j.ability.extra.mult))
        assert((tonumber(h.card_data.Bonus) or 0) == -2, "Heart lost 2 Chips, Bonus=" .. tostring(h.card_data.Bonus))
        local s = H.node(5, "Spades")
        H.play_card(j, s, { s })
        assert(j.ability.extra.mult == 1, "Spades do not count")
        local ctx = H.scored(j, {})
        assert(ctx.mult == 3, "joker_main pays +1 Mult, mult=" .. tostring(ctx.mult))
    end)

    H.test("doppler_radar: clearing a Blind fills empty consumable slots with Planets", function(game)
        local j = H.make_joker(game, "doppler_radar")
        local before = #(game.consumables or {})
        H.fire(j, "on_blind_defeated", { blind_index = 1 })
        local cap = game:get_effective_consumable_capacity()
        assert(#(game.consumables or {}) == cap,
            "slots filled to capacity " .. tostring(cap) .. ", had " .. tostring(before)
            .. " now " .. tostring(#(game.consumables or {})))
    end)
end

PB_TESTS_2 = function(H)
    H.test("fraudulent joker: scored Crowns give +5 Mult, other suits do not", function()
        local game = H.new_game()
        local j = H.make_joker(game, "fraudulent_joker")
        local ctx = H.play_card(j, H.node(9, "Crowns"), nil)
        H.assert_eq(ctx.mult, 6)
        ctx = H.play_card(j, H.node(9, "Hearts"), nil)
        H.assert_eq(ctx.mult, 1)
    end)

    H.test("heretical joker: scored Stars give +5 Mult", function()
        local game = H.new_game()
        local j = H.make_joker(game, "heretical_joker")
        local ctx = H.play_card(j, H.node(7, "Stars"), nil)
        H.assert_eq(ctx.mult, 6)
        ctx = H.play_card(j, H.node(7, "Clubs"), nil)
        H.assert_eq(ctx.mult, 1)
    end)

    H.test("its tv time: scored Stars give +30 Chips", function()
        local game = H.new_game()
        local j = H.make_joker(game, "its_tv_time")
        local ctx = H.play_card(j, H.node(4, "Stars"), nil)
        H.assert_eq(ctx.chips, 30)
    end)

    H.test("dreamsicle: scored Diamonds give +5 Mult", function()
        local game = H.new_game()
        local j = H.make_joker(game, "dreamsicle")
        local ctx = H.play_card(j, H.node(6, "Diamonds"), nil)
        H.assert_eq(ctx.mult, 6)
        ctx = H.play_card(j, H.node(6, "Clubs"), nil)
        H.assert_eq(ctx.mult, 1)
    end)

    H.test("evergreens: scored Spades pay the growing XMult and reset after the hand", function()
        local game = H.new_game()
        local j = H.make_joker(game, "evergreens")
        local ctx = H.play_card(j, H.node(9, "Spades"), nil)
        H.assert_eq(ctx.mult, 1.05)
        ctx = H.play_card(j, H.node(5, "Spades"), nil)
        H.assert_eq(ctx.mult, 1.1)
        H.fire(j, "on_hand_after", {})
        H.assert_eq(j.ability.extra.x_mult, 1.05)
    end)

    H.test("furioso: unique scored ranks grow its XMult, Boss round resets it", function()
        local game = H.new_game()
        local j = H.make_joker(game, "furioso")
        H.play_card(j, H.node(9, "Clubs"), nil)
        H.assert_eq(j.ability.extra.x_mult, 1.2)
        H.play_card(j, H.node(9, "Hearts"), nil)
        H.assert_eq(j.ability.extra.x_mult, 1.2, "same rank twice does not grow it")
        H.play_card(j, H.node(13, "Spades"), nil)
        H.assert_eq(j.ability.extra.x_mult, 1.4)
        local ctx = H.scored(j, {})
        H.assert_eq(ctx.mult, 2.8)
        game.current_blind_index = 3
        H.fire(j, "on_round_end", {})
        H.assert_eq(j.ability.extra.x_mult, 1)
    end)

    H.test("hotel guest: X0.5 Mult per Queen held in hand", function()
        local game = H.new_game()
        local j = H.make_joker(game, "hotel_guest")
        game.hand.card_nodes = { H.node(12, "Clubs"), H.node(12, "Diamonds"), H.node(3, "Spades") }
        local ctx = H.scored(j, {})
        H.assert_eq(ctx.mult, 4, "two Queens held: X2")
        game.hand.card_nodes = { H.node(3, "Spades") }
        ctx = H.scored(j, {})
        H.assert_eq(ctx.mult, 2, "no Queens held: X1, no return")
    end)

    H.test("lurid joker: +80 Chips when the played hand contains a Spectrum", function()
        local game = H.new_game()
        local j = H.make_joker(game, "lurid_joker")
        local ctx = H.scored(j, { contains_hand_types = { Spectrum = true } })
        H.assert_eq(ctx.chips, 90)
        ctx = H.scored(j, {})
        H.assert_eq(ctx.chips, 10)
    end)

    H.test("golden egg: a Spectrum-family hand earns the right Joker's sell value", function()
        local game = H.new_game()
        local egg = H.make_joker(game, "golden_egg")
        local right = H.make_joker(game, "lurid_joker")
        right.sell_cost = 2
        local money = game.money
        H.scored(egg, { hand_type = "Spectrum" })
        H.assert_eq(game.money, money + 2)
        H.scored(egg, { hand_type = "Pair" })
        H.assert_eq(game.money, money + 2, "non-secret hands pay nothing")
    end)

    H.test("joker jacks: scored Jacks give $3, Kings do not", function()
        local game = H.new_game()
        local j = H.make_joker(game, "joker_jacks")
        local money = game.money
        H.play_card(j, H.node(11, "Hearts"), nil)
        H.assert_eq(game.money, money + 3)
        H.play_card(j, H.node(13, "Hearts"), nil)
        H.assert_eq(game.money, money + 3)
    end)

    H.test("i wish that i could fall: scored cards drop a rank and feed its Chips", function()
        local game = H.new_game()
        local j = H.make_joker(game, "i_wish_that_i_could_fall")
        local five = H.node(5, "Clubs")
        H.play_card(j, five, { five })
        H.assert_eq(five.card_data.rank, 4)
        H.assert_eq(j.ability.extra.chips, 4)
        local two = H.node(2, "Hearts")
        H.play_card(j, two, { two })
        H.assert_eq(two.card_data.rank, 14, "2 wraps to Ace")
        local ctx = H.scored(j, {})
        H.assert_eq(ctx.chips, 18, "base 10 plus 8 banked Chips")
    end)

    H.test("legacy: destroyed non-enhanced cards feed its Mult", function()
        local game = H.new_game()
        local j = H.make_joker(game, "legacy")
        local plain = H.node(9, "Clubs")
        local bonus = H.node(9, "Clubs")
        bonus.card_data.enhancement = "bonus"
        H.fire(j, "on_destroy", { destroyed_cards = { plain, bonus } })
        H.assert_eq(j.ability.extra.mult, 9, "only the plain 9 feeds it")
        local ctx = H.scored(j, {})
        H.assert_eq(ctx.mult, 11)
    end)

    H.test("man: scored dark-suit cards permanently gain +1 Mult", function()
        local game = H.new_game()
        local j = H.make_joker(game, "man")
        local spade = H.node(8, "Spades")
        H.play_card(j, spade, { spade })
        H.assert_eq(spade.card_data.mult_bonus, 1)
        local heart = H.node(8, "Hearts")
        H.play_card(j, heart, { heart })
        H.assert_eq(heart.card_data.mult_bonus, nil)
    end)

    H.test("joker duty: equal hands and discards left grows its Mult at round end", function()
        local game = H.new_game()
        local j = H.make_joker(game, "joker_duty")
        game.hands = 2
        game.discards = 2
        H.fire(j, "on_round_end", {})
        H.assert_eq(j.ability.extra.mult, 3)
        game.discards = 1
        H.fire(j, "on_round_end", {})
        H.assert_eq(j.ability.extra.mult, 3, "unequal leftovers do not grow it")
        local ctx = H.scored(j, {})
        H.assert_eq(ctx.mult, 5)
    end)

    H.test("ice cube: selecting a Blind grants +1 hand", function()
        local game = H.new_game()
        local j = H.make_joker(game, "ice_cube")
        local hands = game.hands
        H.fire(j, "on_blind_selected", {})
        H.assert_eq(game.hands, hands + 1)
    end)
end

--- Behaviour tests for PaperbackPack slice 3 (pb_frag_3.lua).
--- Chunk defines PB_TESTS_3(H); H mirrors test_paperbackpack.lua idioms:
--- H.scored starts at chips 10 / mult 2, H.play_card at chips 0 / mult 1.
PB_TESTS_3 = function(H)

    H.test("marble_soda: scored Glass cards give X1.5 Mult", function()
        local game = H.new_game()
        local j = H.make_joker(game, "marble_soda")
        local glass = H.node(5, "Hearts", { enhancement = "glass" })
        local ctx = H.play_card(j, glass, { glass })
        assert(ctx.mult == 1.5, "glass card should give X1.5, got " .. tostring(ctx.mult))
        local plain = H.node(5, "Hearts")
        ctx = H.play_card(j, plain, { plain })
        assert(ctx.mult == 1, "plain card should give nothing, got " .. tostring(ctx.mult))
    end)

    H.test("matcha: scored cards grow its Chips, joker_main pays them", function()
        local game = H.new_game()
        local j = H.make_joker(game, "matcha")
        local a = H.node(4, "Clubs")
        H.play_card(j, a, { a })
        assert(j.ability.extra.chips == 2, "one scored card: +2, got " .. tostring(j.ability.extra.chips))
        H.play_card(j, a, { a })
        assert(j.ability.extra.chips == 4, "two scored cards: +4, got " .. tostring(j.ability.extra.chips))
        local ctx = H.scored(j, {})
        assert(ctx.chips == 14, "joker_main pays +4 over base 10, got " .. tostring(ctx.chips))
    end)

    H.test("ncj: Chips are 4x the sell value of other Jokers", function()
        local game = H.new_game()
        local j = H.make_joker(game, "ncj")
        local other = H.make_joker(game, "matcha")
        other.sell_cost = 5
        local ctx = H.scored(j, {})
        assert(ctx.chips == 30, "4 * $5 = +20 over base 10, got " .. tostring(ctx.chips))
    end)

    H.test("pear: a Pair grows it, joker_main pays the Chips", function()
        local game = H.new_game()
        local j = H.make_joker(game, "pear")
        H.before(j, { contains_hand_types = { Pair = true } })
        assert(j.ability.extra.chips == 5, "Pair should gain +5, got " .. tostring(j.ability.extra.chips))
        local ctx = H.scored(j, {})
        assert(ctx.chips == 15, "joker_main pays +5 over base 10, got " .. tostring(ctx.chips))
    end)

    H.test("red_sun_in_the_sky: scored light suits pay the growing Mult", function()
        local game = H.new_game()
        local j = H.make_joker(game, "red_sun_in_the_sky")
        local heart = H.node(5, "Hearts")
        local ctx = H.play_card(j, heart, { heart })
        assert(ctx.mult == 2, "first light card pays +1, got " .. tostring(ctx.mult))
        ctx = H.play_card(j, heart, { heart })
        assert(ctx.mult == 3, "second light card pays +2, got " .. tostring(ctx.mult))
        local spade = H.node(5, "Spades")
        ctx = H.play_card(j, spade, { spade })
        assert(ctx.mult == 1, "dark cards pay nothing, got " .. tostring(ctx.mult))
        H.fire(j, "on_round_end", {})
        assert(j.ability.extra.mult == 0, "resets at round end, got " .. tostring(j.ability.extra.mult))
    end)

    H.test("one_shift_more: every 7 scored Hearts gains X0.25 Mult", function()
        local game = H.new_game()
        local j = H.make_joker(game, "one_shift_more")
        local heart = H.node(4, "Hearts")
        for _ = 1, 7 do H.play_card(j, heart, { heart }) end
        assert(j.ability.extra.x_mult == 1.25, "7 Hearts: X1.25, got " .. tostring(j.ability.extra.x_mult))
        assert(j.ability.extra.current == 0, "counter resets, got " .. tostring(j.ability.extra.current))
        local ctx = H.scored(j, {})
        assert(ctx.mult == 2.5, "joker_main applies X1.25 to base 2, got " .. tostring(ctx.mult))
    end)

    H.test("sacrificial_lamb: destroyed playing cards grow its Mult", function()
        local game = H.new_game()
        local j = H.make_joker(game, "sacrificial_lamb")
        H.fire(j, "on_destroy", { destroyed_cards = { {}, {} } })
        assert(j.ability.extra.mult == 6, "2 cards x +3 = +6, got " .. tostring(j.ability.extra.mult))
        local ctx = H.scored(j, {})
        assert(ctx.mult == 8, "joker_main pays +6 over base 2, got " .. tostring(ctx.mult))
    end)

    H.test("paranoia: destroyed dark cards feed scored light cards", function()
        local game = H.new_game()
        local j = H.make_joker(game, "paranoia")
        local heart = H.node(5, "Hearts")
        local ctx = H.play_card(j, heart, { heart })
        assert(ctx.mult == 1, "no dark cards destroyed yet, got " .. tostring(ctx.mult))
        H.fire(j, "on_destroy", { destroyed_cards = { { rank = 5, suit = "Spades" } } })
        assert(j.ability.extra.dark_destroyed == 1, "one dark card tallied")
        ctx = H.play_card(j, heart, { heart })
        assert(ctx.mult == 3, "light card pays +2, got " .. tostring(ctx.mult))
        local spade = H.node(5, "Spades")
        ctx = H.play_card(j, spade, { spade })
        assert(ctx.mult == 1, "dark cards pay nothing, got " .. tostring(ctx.mult))
    end)

    H.test("scorecard: every 9 discarded Clubs gains another Joker's sell value", function()
        local game = H.new_game()
        local j = H.make_joker(game, "scorecard")
        local other = H.make_joker(game, "matcha")
        other.sell_cost = 4
        local club = H.node(5, "Clubs")
        for _ = 1, 8 do H.fire(j, "on_discard", { card_node = club }) end
        assert(j.ability.extra.mult == 0, "8 Clubs: not yet, got " .. tostring(j.ability.extra.mult))
        assert(j.ability.extra.current == 1, "one Club left, got " .. tostring(j.ability.extra.current))
        H.fire(j, "on_discard", { card_node = club })
        assert(j.ability.extra.mult == 4, "9th Club gains $4 of sell value, got " .. tostring(j.ability.extra.mult))
        assert(j.ability.extra.current == 9, "counter resets to 9, got " .. tostring(j.ability.extra.current))
        local heart = H.node(5, "Hearts")
        H.fire(j, "on_discard", { card_node = heart })
        assert(j.ability.extra.current == 9, "non-Clubs do not count")
        local ctx = H.scored(j, {})
        assert(ctx.mult == 6, "joker_main pays +4 over base 2, got " .. tostring(ctx.mult))
    end)

    H.test("pointy_stick: X2 only with another Stick Joker held", function()
        local game = H.new_game()
        local j = H.make_joker(game, "pointy_stick")
        local ctx = H.scored(j, {})
        assert(ctx.mult == 2, "alone: no XMult, got " .. tostring(ctx.mult))
        H.make_joker(game, "pop_stick")
        ctx = H.scored(j, {})
        assert(ctx.mult == 4, "with Pop-Stick: X2 over base 2, got " .. tostring(ctx.mult))
    end)

    H.test("nigiri: discards scale it by rank, Boss defeat resets it", function()
        local game = H.new_game()
        local j = H.make_joker(game, "nigiri")
        local ten = H.node(10, "Clubs")
        H.fire(j, "on_discard", { card_node = ten })
        assert(j.ability.extra.xmult == 1.1, "10 adds 10/100, got " .. tostring(j.ability.extra.xmult))
        local ctx = H.scored(j, {})
        assert(ctx.mult == 2.2, "joker_main applies X1.1 to base 2, got " .. tostring(ctx.mult))
        H.fire(j, "on_blind_defeated", { blind_index = 2 })
        assert(j.ability.extra.xmult == 1.1, "Big Blind does not reset, got " .. tostring(j.ability.extra.xmult))
        H.fire(j, "on_blind_defeated", { blind_index = 3 })
        assert(j.ability.extra.xmult == 1, "Boss Blind resets, got " .. tostring(j.ability.extra.xmult))
    end)

    H.test("shuttle: first hand of round pays double the hand's level", function()
        local game = H.new_game()
        local j = H.make_joker(game, "shuttle")
        game.handlist = { "High Card", "Pair" }
        game.hand_play_counts = { 0, 0 }
        game.hand_stats = { { level = 1 }, { level = 3 } }
        game.round_hands_played = 0
        local money = game.money or 0
        H.scored(j, { hand_type = "Pair" })
        assert((game.money or 0) == money + 6, "level 3 x 2 = $6, got " .. tostring(game.money))
        game.round_hands_played = 1
        H.scored(j, { hand_type = "Pair" })
        assert((game.money or 0) == money + 6, "second hand pays nothing, got " .. tostring(game.money))
    end)

end

-- Behavior tests for PaperbackPack slice 4 (pb_frag_4.lua).
-- Chunk defines PB_TESTS_4(H); H mirrors test_paperbackpack.lua's helpers:
-- H.test, H.fire, H.scored, H.play_card, H.before, H.make_joker,
-- H.new_game, H.node, H.classify. Deterministic only: no RNG assertions.

-- Behavior tests for PaperbackPack slice 4 (pb_frag_4.lua).
-- Chunk defines PB_TESTS_4(H); H mirrors test_paperbackpack.lua's helpers:
-- H.test, H.fire, H.scored, H.play_card, H.before, H.make_joker,
-- H.new_game, H.node, H.classify. Deterministic only: no RNG assertions.

PB_TESTS_4 = function(H)
    local function eq(a, b, msg)
        assert(a == b, (msg or "mismatch") .. ": expected "
            .. tostring(b) .. ", got " .. tostring(a))
    end
    local function near(a, b, msg)
        assert(math.abs((tonumber(a) or 0) - b) < 0.001,
            (msg or "mismatch") .. ": expected ~" .. tostring(b)
            .. ", got " .. tostring(a))
    end

    H.test("silent assassin: scored 4s and 7s pay its Mult, destroyed cards grow it", function()
        local game = H.new_game()
        local j = H.make_joker(game, "silent_assassin")
        local four = H.node(4, "Clubs")
        local ctx = H.play_card(j, four, { four })
        eq(ctx.mult, 2, "first 4 gives +1 Mult")
        H.fire(j, "on_destroy", { destroyed_cards = { {}, {} } })
        eq(j.ability.extra.mult, 2, "two destroyed cards grow it by +1")
        local seven = H.node(7, "Hearts")
        ctx = H.play_card(j, seven, { seven })
        eq(ctx.mult, 3, "a 7 now gives +2 Mult")
        local nine = H.node(9, "Hearts")
        ctx = H.play_card(j, nine, { nine })
        eq(ctx.mult, 1, "other ranks give nothing")
    end)

    H.test("sinister minds: each set of Spectrals raises its retriggers and the requirement", function()
        local game = H.new_game()
        local j = H.make_joker(game, "sinister_minds")
        H.fire(j, "on_consumable_used", { consumable_kind = "planet" })
        eq(j.ability.extra.retriggers, 1, "Planets do not count")
        H.fire(j, "on_consumable_used", { consumable_kind = "spectral" })
        eq(j.ability.extra.retriggers, 2, "first Spectral completes the set")
        eq(j.ability.extra.required_spectrals, 2, "requirement grows")
        eq(j.ability.extra.spectrals_left, 2, "two Spectrals now needed")
        H.fire(j, "on_consumable_used", { consumable_kind = "spectral" })
        eq(j.ability.extra.retriggers, 2, "one of two: no growth yet")
        H.fire(j, "on_consumable_used", { consumable_kind = "spectral" })
        eq(j.ability.extra.retriggers, 3, "second Spectral completes the set")
    end)

    H.test("skydiver: X2 while all scored ranks stay at or below the round's lowest", function()
        local game = H.new_game()
        local j = H.make_joker(game, "skydiver")
        local ctx = H.scored(j, { played_cards = { H.node(13, "Clubs") } })
        eq(ctx.mult, 4, "fresh: lowest is Ace, everything qualifies")
        local five = { H.node(5, "Hearts") }
        H.fire(j, "on_hand_after",
            { played_cards = five, cards = five })
        eq(j.ability.extra.lowest_rank, 5, "the 5 becomes the lowest")
        ctx = H.scored(j, { played_cards = { H.node(13, "Clubs") } })
        eq(ctx.mult, 2, "a King is above the lowest: no XMult")
        ctx = H.scored(j, { played_cards = { H.node(4, "Clubs") } })
        eq(ctx.mult, 4, "a 4 is at or below: X2 again")
        H.fire(j, "on_round_end", {})
        eq(j.ability.extra.lowest_rank, 14, "resets to Ace at round end")
    end)

    H.test("small scale onshore wind: 5-card discards grow it, other discards reset it", function()
        local game = H.new_game()
        local j = H.make_joker(game, "small_scale_onshore_wind")
        local five = { H.node(2, "Clubs"), H.node(3, "Clubs"),
            H.node(4, "Clubs"), H.node(6, "Clubs"), H.node(7, "Clubs") }
        H.fire(j, "on_pre_discard", { discarded_nodes = five })
        eq(j.ability.extra.mult, 2, "first full discard: +2")
        H.fire(j, "on_pre_discard", { discarded_nodes = five })
        eq(j.ability.extra.mult, 4, "consecutive full discard: +4 total")
        local ctx = H.scored(j, {})
        eq(ctx.mult, 6, "joker_main pays the grown Mult")
        H.fire(j, "on_pre_discard",
            { discarded_nodes = { H.node(2, "Clubs") } })
        eq(j.ability.extra.mult, 0, "a short discard resets it")
    end)

    H.test("soft taco: X3 Mult on joker_main", function()
        local game = H.new_game()
        local j = H.make_joker(game, "soft_taco")
        local ctx = H.scored(j, {})
        eq(ctx.mult, 6, "base Mult 2 at X3")
    end)

    H.test("the sun: all-light hands grow it, a dark card scored drains it", function()
        local game = H.new_game()
        local j = H.make_joker(game, "the_sun")
        local light = { H.node(5, "Hearts"), H.node(9, "Diamonds") }
        H.before(j, { played_cards = light })
        eq(j.ability.extra.mult, 2, "all light: +2")
        local mixed = { H.node(5, "Hearts"), H.node(9, "Spades") }
        H.before(j, { played_cards = mixed })
        eq(j.ability.extra.mult, 2, "a dark suit in the hand: no gain")
        local ctx = H.scored(j, {})
        eq(ctx.mult, 4, "joker_main pays +2")
        local spade = H.node(9, "Spades")
        H.play_card(j, spade, { spade })
        eq(j.ability.extra.mult, 0, "the scored Spade drains the +2")
    end)

    H.test("solemn lament: a hand with both dark and light suits grows its XMult", function()
        local game = H.new_game()
        local j = H.make_joker(game, "solemn_lament")
        local mixed = { H.node(5, "Hearts"), H.node(9, "Spades") }
        H.before(j, { played_cards = mixed })
        near(j.ability.extra.x_mult, 1.15, "both shades: +X0.15")
        local ctx = H.scored(j, {})
        near(ctx.mult, 2.3, "joker_main pays X1.15")
        local light_only = { H.node(5, "Hearts"), H.node(9, "Diamonds") }
        H.before(j, { played_cards = light_only })
        near(j.ability.extra.x_mult, 1.15, "light only: no growth")
    end)

    H.test("zealous joker and the dynasty: Spectrum hands pay out", function()
        local game = H.new_game()
        local z = H.make_joker(game, "zealous_joker")
        local ctx = H.scored(z,
            { contains_hand_types = { Spectrum = true } })
        eq(ctx.mult, 12, "Zealous: +10 Mult on a Spectrum")
        ctx = H.scored(z, {})
        eq(ctx.mult, 2, "Zealous: nothing without a Spectrum")
        local d = H.make_joker(game, "the_dynasty")
        ctx = H.scored(d, { contains_hand_types = { Spectrum = true } })
        eq(ctx.mult, 10, "Dynasty: X5 on a Spectrum")
        ctx = H.scored(d, {})
        eq(ctx.mult, 2, "Dynasty: nothing without a Spectrum")
    end)

    H.test("solar system: X1.5 per level shared by all base hands", function()
        local game = H.new_game()
        local j = H.make_joker(game, "solar_system")
        local ctx = H.scored(j, {})
        eq(ctx.mult, 3, "all hands level 1: X1.5")
        for i, name in ipairs(game.handlist) do
            if name ~= "Spectrum" and name ~= "Straight Spectrum"
                and name ~= "Spectrum House" and name ~= "Spectrum Five" then
                game.hand_stats[i].level = 2
            end
        end
        ctx = H.scored(j, {})
        eq(ctx.mult, 6, "all base hands level 2: X3")
    end)

    H.test("tutor: scored numbered cards pay their Chip value again", function()
        local game = H.new_game()
        local j = H.make_joker(game, "tutor")
        local seven = H.node(7, "Clubs")
        local ctx = H.play_card(j, seven, { seven })
        eq(ctx.chips, 7, "a 7 pays +7 Chips (doubling it)")
        local king = H.node(13, "Clubs")
        ctx = H.play_card(j, king, { king })
        eq(ctx.chips, 0, "face cards are not numbered cards")
    end)

    H.test("trans flag: +5 Mult per remaining discard", function()
        local game = H.new_game()
        local j = H.make_joker(game, "trans_flag")
        game.discards = 3
        local ctx = H.scored(j, {})
        eq(ctx.mult, 17, "three discards left: +15 Mult")
        game.discards = 0
        ctx = H.scored(j, {})
        eq(ctx.mult, 2, "no discards left: nothing")
    end)

    H.test("stick family: sticky needs another Stick, sweet scales per Stick", function()
        local game = H.new_game()
        local sticky = H.make_joker(game, "sticky_stick")
        local ctx = H.scored(sticky, {})
        eq(ctx.mult, 2, "alone: no other Stick, X1")
        local sweet = H.make_joker(game, "sweet_stick")
        ctx = H.scored(sticky, {})
        eq(ctx.mult, 4, "with Sweet Stick held: X2")
        ctx = H.scored(sweet, {})
        near(ctx.mult, 4.5, "Sweet counts both Sticks: X1.5 twice")
    end)
end

-- Behavior tests for the Tier 3 (v1.1.0) wave: enhancements and the
-- Jokers / systems they unblock.
PB_TESTS_5 = function(H)
    local function tag_spy(game)
        game._tags = {}
        game.addTag = function(self, t) self._tags[#self._tags + 1] = t end
        return game._tags
    end
    local function defcalc(key, j, ctx)
        local def = JOKER_DEFS["j_pbp_" .. key]
        return def.smods.calculate(def.smods, j, ctx)
    end
    local function near(a, b, msg)
        H.assert_true(math.abs((tonumber(a) or 0) - b) < 0.001,
            (msg or "near") .. ": expected ~" .. tostring(b)
            .. ", got " .. tostring(a))
    end

    H.test("collector: $1 per Sleeved card in the full deck at round end", function()
        local game = H.new_game()
        local j = H.make_joker(game, "collector")
        game.deck.cards = {
            { rank = 5, suit = "Hearts", enhancement = "sleeved" },
            { rank = 9, suit = "Clubs", enhancement = "sleeved" },
            { rank = 9, suit = "Spades", enhancement = "sleeved" },
            { rank = 2, suit = "Spades" },
        }
        local def = JOKER_DEFS["j_pbp_collector"]
        H.assert_eq(def.smods.calc_dollar_bonus(def.smods, j), 3)
    end)

    H.test("greeting card: a scored Wrapped card raises its sell value", function()
        local game = H.new_game()
        local j = H.make_joker(game, "greeting_card")
        local before = j.sell_cost
        local w = H.node(7, "Hearts", { enhancement = "wrapped" })
        H.play_card(j, w, { w })
        H.assert_eq(j.sell_cost, before + 2)
        local p = H.node(7, "Hearts")
        H.play_card(j, p, { p })
        H.assert_eq(j.sell_cost, before + 2, "plain cards do nothing")
    end)

    H.test("teapot: scored Ceramic cards grow its Chips", function()
        local game = H.new_game()
        local j = H.make_joker(game, "teapot")
        local c = H.node(7, "Hearts", { enhancement = "ceramic" })
        H.play_card(j, c, { c })
        H.play_card(j, c, { c })
        H.assert_eq(j.ability.extra.chips, 10)
        local ctx = H.scored(j, {})
        H.assert_eq(ctx.chips, 20, "base 10 + 10 grown")
    end)

    H.test("mexican train: scored Domino pays $1 per played Domino", function()
        local game = H.new_game()
        local j = H.make_joker(game, "mexican_train")
        local d1 = H.node(7, "Hearts", { enhancement = "domino" })
        local d2 = H.node(9, "Clubs", { enhancement = "domino" })
        game.hand.card_nodes = { d1, d2 }
        local money = game.money
        H.play_card(j, d1, { d1, d2 })
        H.assert_eq(game.money, money + 2)
    end)

    H.test("kintsugi: destroyed Ceramic cards raise the Ceramic payout", function()
        local game = H.new_game()
        local j = H.make_joker(game, "kintsugi_joker")
        local c1 = H.node(7, "Hearts", { enhancement = "ceramic" })
        local c2 = H.node(9, "Clubs", { enhancement = "ceramic" })
        local p = H.node(2, "Clubs")
        H.fire(j, "on_destroy", { destroyed_cards = { c1, c2, p } })
        H.assert_eq(j.ability.extra.total, 4, "2 Ceramic x $2 increase")
    end)

    H.test("plastic wrap: a destroyed Sleeved card sleeves 2 deck cards", function()
        local game = H.new_game()
        local j = H.make_joker(game, "plastic_wrap")
        game.deck.cards = {
            { rank = 5, suit = "Hearts" }, { rank = 9, suit = "Clubs" },
            { rank = 2, suit = "Spades" },
        }
        local s = H.node(7, "Hearts", { enhancement = "sleeved" })
        H.fire(j, "on_destroy", { destroyed_cards = { s } })
        local n = 0
        for _, d in ipairs(game.deck.cards) do
            if d.enhancement == "sleeved" then n = n + 1 end
        end
        H.assert_eq(n, 2)
    end)

    H.test("sommelier: the first discard's first Stained card gains a seal", function()
        local game = H.new_game()
        local j = H.make_joker(game, "sommelier")
        local st = H.node(7, "Hearts", { enhancement = "stained" })
        local p = H.node(2, "Clubs")
        H.fire(j, "on_pre_discard", { discarded_nodes = { p, st } })
        H.assert_true(st.card_data.seal ~= nil, "the Stained card is sealed")
        H.assert_eq(j.ability.extra.active, false, "once per round")
    end)

    H.test("gauze: a lone last discard becomes Bandaged", function()
        local game = H.new_game()
        local j = H.make_joker(game, "gauze")
        game.discards = 1
        local p = H.node(2, "Clubs")
        H.fire(j, "on_pre_discard", { discarded_nodes = { p } })
        H.assert_eq(p.card_data.enhancement, "bandaged")
    end)

    H.test("spotty joker: Domino cards in the scoring hand grow its XMult", function()
        local game = H.new_game()
        local j = H.make_joker(game, "spotty_joker")
        local d1 = H.node(7, "Hearts", { enhancement = "domino" })
        local d2 = H.node(9, "Clubs", { enhancement = "domino" })
        H.before(j, { scoring_hand = { d1, d2 }, cards = { d1, d2 } })
        near(j.ability.extra.xmult, 1.2)
        local ctx = H.scored(j, {})
        near(ctx.mult, 2.4, "base Mult 2 at X1.2")
    end)

    H.test("pinot noir: held Stained cards burn its remaining triggers", function()
        local game = H.new_game()
        local j = H.make_joker(game, "pinot_noir")
        local st = H.node(7, "Hearts", { enhancement = "stained" })
        H.fire(j, "card_held", { card_node = st })
        H.assert_eq(j.ability.extra.remaining, 9)
    end)

    H.test("happy accident: a held Antique card pays XChips at halved scaling", function()
        local game = H.new_game()
        local j = H.make_joker(game, "happy_accident")
        local a = H.node(7, "Hearts", { enhancement = "antique" })
        a.card_data.pb_antique_x = 3
        local ctx = H.fire(j, "card_held",
            { card_node = a, chips = 20, mult = 1 })
        near(ctx.chips, 40, "X3 halved is X2: 20 -> 40")
    end)

    H.test("blue star: Stars grow it, Clubs shrink it", function()
        local game = H.new_game()
        local j = H.make_joker(game, "blue_star")
        local s = H.node(7, "Stars")
        H.play_card(j, s, { s })
        near(j.ability.extra.x_chips, 1.05)
        local c = H.node(7, "Clubs")
        H.play_card(j, c, { c })
        near(j.ability.extra.x_chips, 0.85)
        local ctx = H.scored(j, {})
        near(ctx.chips, 8.5, "base 10 at X0.85")
    end)

    H.test("chocolate joker: XChips grows with every held Joker", function()
        local game = H.new_game()
        local j = H.make_joker(game, "chocolate_joker")
        H.make_joker(game, "claw")
        H.make_joker(game, "jacks")
        local ctx = H.scored(j, {})
        near(ctx.chips, 16, "3 Jokers: X1.6 on base 10")
    end)

    H.test("crispy taco: X3 Chips while it lasts", function()
        local game = H.new_game()
        local j = H.make_joker(game, "crispy_taco")
        local ctx = H.scored(j, {})
        near(ctx.chips, 30)
    end)

    H.test("deck of cards: a lone Antique hand grows it and eats the card", function()
        local game = H.new_game()
        local j = H.make_joker(game, "deck_of_cards")
        game.hand:add_card({ rank = 7, suit = "Hearts",
            enhancement = "antique" })
        local a = game.hand.card_nodes[#game.hand.card_nodes]
        H.before(j, { scoring_hand = { a }, cards = { a },
            full_hand = { a }, played_cards = { a } })
        near(j.ability.extra.x_chips, 1.25)
        H.assert_eq(#game.hand.card_nodes, 0, "the Antique card is destroyed")
    end)

    H.test("nachos: discards shave its XChips", function()
        local game = H.new_game()
        local j = H.make_joker(game, "nachos")
        local p = H.node(2, "Clubs")
        H.fire(j, "on_discard", { card_node = p })
        near(j.ability.extra.X_chips, 1.95)
        local ctx = H.scored(j, {})
        near(ctx.chips, 19.5)
    end)

    H.test("oracle: unique Minor Arcana used grow its XChips", function()
        local game = H.new_game()
        local j = H.make_joker(game, "oracle")
        game.consumable_usage = {
            c_pbp_five_of_cups = { kind = "minor_arcana", count = 1 },
            c_pbp_two_of_cups = { kind = "minor_arcana", count = 3 },
            c_fool = { kind = "tarot", count = 1 },
        }
        local ctx = H.scored(j, {})
        near(ctx.chips, 12, "2 unique Arcana: X1.2 on base 10")
    end)

    H.test("quartz: a scored Star pays more per other played Star", function()
        local game = H.new_game()
        local j = H.make_joker(game, "quartz")
        local s1 = H.node(7, "Stars")
        local s2 = H.node(9, "Stars")
        local s3 = H.node(2, "Stars")
        local ctx = H.fire(j, "card_played", {
            card_node = s1, played_cards = { s1, s2, s3 },
            full_hand = { s1, s2, s3 }, chips = 10, mult = 1,
            rank = 7, suit = "Stars",
        })
        near(ctx.chips, 14, "X1.4 for two other Stars")
    end)

    H.test("ready to fly: adjacent Joker triggers grow it", function()
        local game = H.new_game()
        local left = H.make_joker(game, "claw")
        local j = H.make_joker(game, "ready_to_fly")
        H.make_joker(game, "jacks")
        defcalc("ready_to_fly", j, { post_trigger = true, other_card = left })
        near(j.ability.extra.xchips, 1.02)
        local far = H.make_joker(game, "nazar")
        defcalc("ready_to_fly", j, { post_trigger = true, other_card = far })
        near(j.ability.extra.xchips, 1.02, "non-adjacent triggers do nothing")
    end)

    H.test("stella octangula: the first Star each round pays X2 Chips once", function()
        local game = H.new_game()
        local j = H.make_joker(game, "stella_octangula")
        local s = H.node(7, "Stars")
        local p = H.node(2, "Clubs")
        H.before(j, { scoring_hand = { p, s }, cards = { p, s } })
        local ctx = H.fire(j, "card_played", {
            card_node = s, played_cards = { p, s }, full_hand = { p, s },
            chips = 10, mult = 1, rank = 7, suit = "Stars",
        })
        near(ctx.chips, 20, "the first Star pays X2")
        ctx = H.fire(j, "card_played", {
            card_node = s, played_cards = { p, s }, full_hand = { p, s },
            chips = 10, mult = 1, rank = 7, suit = "Stars",
        })
        near(ctx.chips, 10, "only once per round")
    end)

    H.test("angel investor: skipping or beating the Boss grants its Tag", function()
        local game = H.new_game()
        local tags = tag_spy(game)
        local j = H.make_joker(game, "angel_investor")
        H.fire(j, "on_blind_skipped", {})
        H.assert_eq(tags[1], "angel_investment")
        game.current_blind_index = 3
        H.fire(j, "on_round_end", {})
        H.assert_eq(tags[2], "angel_investment")
    end)

    H.test("jimbo adventure: skipping creates a random Tag", function()
        local game = H.new_game()
        local tags = tag_spy(game)
        local j = H.make_joker(game, "jimbo_adventure")
        H.fire(j, "on_blind_skipped", {})
        H.assert_eq(#tags, 1)
    end)

    H.test("j and js: a Spectrum makes 2 Tags; it is consumed in 3 rounds", function()
        local game = H.new_game()
        local tags = tag_spy(game)
        local j = H.make_joker(game, "j_and_js")
        H.before(j, { contains_hand_types = { Spectrum = true },
            scoring_hand = {}, cards = {} })
        H.assert_eq(#tags, 2)
        H.fire(j, "on_round_end", {})
        H.fire(j, "on_round_end", {})
        H.assert_eq(#game.jokers, 1, "still here after 2 rounds")
        H.fire(j, "on_round_end", {})
        H.assert_eq(#game.jokers, 0, "consumed after the 3rd")
    end)

    H.test("shopkeep: Coupon every 2 blinds, Voucher for the Boss", function()
        local game = H.new_game()
        local tags = tag_spy(game)
        local j = H.make_joker(game, "shopkeep")
        game.current_blind_index = 1
        H.fire(j, "on_round_end", {})
        H.assert_eq(#tags, 0)
        H.fire(j, "on_round_end", {})
        H.assert_eq(tags[1], "coupon")
        game.current_blind_index = 3
        H.fire(j, "on_round_end", {})
        H.assert_eq(tags[2], "voucher")
    end)

    H.test("the wonder of you: selecting the Boss creates 2 Tags", function()
        local game = H.new_game()
        local tags = tag_spy(game)
        local j = H.make_joker(game, "the_wonder_of_you")
        game.current_blind_index = 3
        H.fire(j, "on_blind_selected", {})
        H.assert_eq(#tags, 2)
        game.current_blind_index = 1
        H.fire(j, "on_blind_selected", {})
        H.assert_eq(#tags, 2, "not for a small blind")
    end)

    H.test("spirit box: its chosen hand makes a Tag once per round", function()
        local game = H.new_game()
        local tags = tag_spy(game)
        local j = H.make_joker(game, "spirit_box")
        j.ability.extra.hand = "Pair"
        H.before(j, { contains_hand_types = { Pair = true },
            scoring_hand = {}, cards = {} })
        H.assert_eq(#tags, 1)
        H.before(j, { contains_hand_types = { Pair = true },
            scoring_hand = {}, cards = {} })
        H.assert_eq(#tags, 1, "once per round")
        H.fire(j, "on_round_end", {})
        j.ability.extra.hand = "Pair"
        H.before(j, { contains_hand_types = { Pair = true },
            scoring_hand = {}, cards = {} })
        H.assert_eq(#tags, 2, "re-armed next round")
    end)

    H.test("stereoscopic specs: copies the last Tag gained after the Boss", function()
        local game = H.new_game()
        local tags = tag_spy(game)
        local j = H.make_joker(game, "stereoscopic_specs")
        H.fire(j, "on_tag_added", { tag = { type = "double" } })
        H.assert_eq(j.ability.extra.last_tag, "double")
        game.current_blind_index = 3
        H.fire(j, "on_round_end", {})
        H.assert_eq(tags[1], "double")
    end)

    H.test("book of life: copies the blind's own Tag, given a few rounds", function()
        local game = H.new_game()
        local tags = tag_spy(game)
        local j = H.make_joker(game, "book_of_life")
        game.skips = { [1] = 22 } -- the Economy Tag's skip id
        game.current_blind_index = 1
        for _ = 1, 12 do
            H.fire(j, "on_round_end", {})
            if #tags > 0 then break end
        end
        H.assert_eq(tags[1], "economy")
    end)

    H.test("let it happen: balances each hand once per Ante", function()
        local game = H.new_game()
        local j = H.make_joker(game, "let_it_happen")
        local ret = defcalc("let_it_happen", j,
            { joker_main = true, scoring_name = "Pair" })
        H.assert_true(ret and ret.balance == true, "first Pair balances")
        ret = defcalc("let_it_happen", j,
            { joker_main = true, scoring_name = "Pair" })
        H.assert_true(ret == nil, "second Pair does not")
        ret = defcalc("let_it_happen", j,
            { joker_main = true, scoring_name = "Flush" })
        H.assert_true(ret and ret.balance == true, "a new hand balances")
        game.current_blind_index = 3
        H.fire(j, "on_round_end", {})
        ret = defcalc("let_it_happen", j,
            { joker_main = true, scoring_name = "Pair" })
        H.assert_true(ret and ret.balance == true, "reset after the Boss")
    end)

    H.test("coin collection: every gain pays an extra $1, once", function()
        local game = H.new_game()
        local j = H.make_joker(game, "coin_collection")
        game.money = 10
        game:ease_dollars(5)
        H.assert_eq(game.money, 16, "$5 gained + $1 collection")
        game:ease_dollars(-3)
        H.assert_eq(game.money, 13, "spending pays nothing")
    end)

    H.test("frutiger aero: shop spending drains its Chips; Boss resets", function()
        local game = H.new_game()
        local j = H.make_joker(game, "frutiger_aero")
        game:ease_dollars(-10, { from_shop = true })
        H.assert_eq(j.ability.extra.chips, 80)
        local ctx = H.scored(j, {})
        H.assert_eq(ctx.chips, 90)
        game.current_blind_index = 3
        H.fire(j, "on_round_end", {})
        H.assert_eq(j.ability.extra.chips, 100)
    end)

    H.test("cream liqueur: Tags pay $5; it is consumed in 3 rounds", function()
        local game = H.new_game()
        local j = H.make_joker(game, "cream_liqueur")
        local money = game.money
        game:addTag("double")
        H.assert_eq(game.money, money + 5, "the Tag paid $5")
        H.fire(j, "on_round_end", {})
        H.fire(j, "on_round_end", {})
        H.assert_eq(#game.jokers, 1)
        H.fire(j, "on_round_end", {})
        H.assert_eq(#game.jokers, 0, "consumed after the 3rd round")
    end)

    H.test("off switch: creates its three eternal addons, which scale on destroys", function()
        local game = H.new_game()
        local sw = H.make_joker(game, "off_switch")
        H.assert_eq(#game.jokers, 4, "switch + Alpha + Omega + Epsilon")
        local alpha, omega, epsilon
        for _, j in ipairs(game.jokers) do
            if j.def.id == "j_pbp_off_alpha" then alpha = j end
            if j.def.id == "j_pbp_off_omega" then omega = j end
            if j.def.id == "j_pbp_off_epsilon" then epsilon = j end
        end
        H.assert_true(alpha and omega and epsilon, "all three addons exist")
        H.assert_true(alpha.eternal and omega.eternal and epsilon.eternal,
            "the addons are Eternal")
        local victim = H.make_joker(game, "claw")
        local money = game.money
        SMODS.destroy_joker(victim)
        H.assert_eq(alpha.ability.extra.chips, 13)
        H.assert_eq(omega.ability.extra.mult, 13)
        H.assert_eq(game.money, money + 13, "Epsilon paid $13")
        near(sw.ability.extra.x_mult, 3, "the Switch gained X2")
    end)

    H.test("one with nothing: playing a hand destroys the cards left in hand", function()
        local game = H.new_game()
        local j = H.make_joker(game, "one_with_nothing")
        game.hand:add_card({ rank = 7, suit = "Hearts" })
        game.hand:add_card({ rank = 9, suit = "Clubs" })
        game.hand:add_card({ rank = 2, suit = "Spades" })
        local a = game.hand.card_nodes[1]
        H.fire(j, "on_press_play", { full_hand = { a } })
        H.assert_eq(#game.hand.card_nodes, 1, "only the played card remains")
        H.assert_true(game.hand.card_nodes[1] == a)
    end)

    H.test("watermelon: enhancing grows it, destroyed cards shrink and eat it", function()
        local game = H.new_game()
        local j = H.make_joker(game, "watermelon")
        local a = H.node(7, "Hearts", { enhancement = "bonus" })
        H.fire(j, "on_setting_ability",
            { card_node = a, old = nil, unchanged = false })
        near(j.ability.extra.x_mult, 1.1)
        local p = H.node(2, "Clubs")
        H.fire(j, "on_destroy", { destroyed_cards = { p } })
        near(j.ability.extra.x_mult, 1.0)
        H.fire(j, "on_destroy", { destroyed_cards = { p } })
        H.assert_eq(#game.jokers, 0, "dropping below X1 eats it")
    end)

    H.test("cross: playing cards cannot be destroyed while it is held", function()
        local game = H.new_game()
        local j = H.make_joker(game, "cross")
        local hand = Hand(game)
        game.hand = hand
        hand:add_card({ rank = 12, suit = "Hearts" })
        local queen = hand.card_nodes[1]
        H.assert_true(SMODS.card_destroy_vetoed(queen), "the veto answers")
        H.assert_eq(hand:destroy_card_node(queen), false)
        H.assert_eq(#hand.card_nodes, 1)
    end)

    H.test("unholy alliance: destroyed cards and Jokers feed its Chips", function()
        local game = H.new_game()
        local j = H.make_joker(game, "unholy_alliance")
        local p = H.node(2, "Clubs")
        H.fire(j, "on_destroy", { destroyed_cards = { p, p } })
        H.assert_eq(j.ability.extra.chips, 24)
        local victim = H.make_joker(game, "claw")
        SMODS.destroy_joker(victim)
        H.assert_eq(j.ability.extra.chips, 36)
        local ctx = H.scored(j, {})
        H.assert_eq(ctx.chips, 46)
    end)

    H.test("da capo: debuffs every suit but the current movement's", function()
        local game = H.new_game()
        local j = H.make_joker(game, "da_capo")
        game.deck.cards = {
            { rank = 5, suit = "Clubs" }, { rank = 9, suit = "Hearts" },
            { rank = 2, suit = "Spades" },
        }
        H.fire(j, "on_blind_selected", {})
        H.assert_true(game.deck.cards[1].perma_debuff == nil,
            "Clubs (movement 1) stay live")
        H.assert_eq(game.deck.cards[2].perma_debuff, true,
            "Hearts are debuffed")
        local ctx = H.scored(j, {})
        near(ctx.mult, 8, "X4 Mult on base 2")
        H.fire(j, "on_hand_after", {})
        H.assert_eq(game.deck.cards[1].perma_debuff, true,
            "movement 2 debuffs Clubs")
        H.assert_true(game.deck.cards[3].perma_debuff == nil,
            "Spades stay live in movement 2")
    end)

    H.test("jester of nihil: debuffs the last scored suit and pays per debuff", function()
        local game = H.new_game()
        local j = H.make_joker(game, "jester_of_nihil")
        game.deck.cards = {
            { rank = 5, suit = "Hearts" }, { rank = 9, suit = "Hearts" },
            { rank = 2, suit = "Clubs" },
        }
        local h = H.node(7, "Hearts")
        H.play_card(j, h, { h })
        H.fire(j, "on_hand_after", {})
        H.assert_eq(game.deck.cards[1].perma_debuff, true)
        H.assert_eq(game.deck.cards[2].perma_debuff, true)
        H.assert_true(game.deck.cards[3].perma_debuff == nil)
        local ctx = H.scored(j, {})
        H.assert_eq(ctx.mult, 12, "base 2 + 2 debuffed x +5")
    end)

    H.test("weather radio: its hand grows it; at X3+ the Boss is disabled", function()
        local game = H.new_game()
        local j = H.make_joker(game, "weather_radio")
        local disabled = false
        game.disable_boss_blind = function(self) disabled = true end
        j.ability.extra.hand = "Pair"
        H.before(j, { contains_hand_types = { Pair = true },
            scoring_hand = {}, cards = {} })
        near(j.ability.extra.x_mult, 1.5)
        j.ability.extra.x_mult = 3
        game.current_blind_index = 3
        H.before(j, { contains_hand_types = { Pair = true },
            scoring_hand = {}, cards = {} })
        H.assert_true(disabled, "the Boss was disabled")
        near(j.ability.extra.x_mult, 1.5, "3 + 0.5 growth - 2 penalty")
    end)
end

PB_TESTS_6 = function(H)
    local function near(a, b, msg)
        H.assert_true(math.abs((tonumber(a) or 0) - b) < 0.001,
            (msg or "near") .. ": expected ~" .. tostring(b)
            .. ", got " .. tostring(a))
    end

    H.test("milk tea: balances half at joker_main; decays when final Mult beats Chips", function()
        local game = H.new_game()
        local j = H.make_joker(game, "milk_tea")
        local ctx = H.scored(j, {})
        H.assert_eq(ctx.chips, 10, "the larger total stays")
        H.assert_eq(ctx.mult, 6, "2 moves halfway to 10 at 50%")
        H.fire(j, "on_hand_final", { chips = 10, mult = 20 })
        H.fire(j, "on_hand_after", {})
        H.assert_eq(j.ability.extra.percent, 40, "reduced by 10")
        local ctx2 = H.scored(j, {})
        H.assert_eq(ctx2.mult, 5.2, "40%: 2 + 8 x 0.4")
    end)

    H.test("milk tea: no decay when Chips win; destroyed when the percent runs out", function()
        local game = H.new_game()
        local j = H.make_joker(game, "milk_tea")
        H.fire(j, "on_hand_final", { chips = 30, mult = 20 })
        H.fire(j, "on_hand_after", {})
        H.assert_eq(j.ability.extra.percent, 50, "Chips won: no reduction")
        j.ability.extra.percent = 10
        H.fire(j, "on_hand_final", { chips = 10, mult = 20 })
        H.fire(j, "on_hand_after", {})
        H.assert_eq(#game.jokers, 0, "consumed at 0%")
    end)

    H.test("stardrop: each scored Stars card balances 2%, compounding", function()
        local game = H.new_game()
        local j = H.make_joker(game, "stardrop")
        local s = H.node(7, "Stars")
        local ctx = H.fire(j, "card_played", {
            card_node = s, played_cards = { s }, full_hand = { s },
            chips = 100, mult = 20, rank = 7, suit = "Stars",
        })
        H.assert_eq(ctx.chips, 100)
        near(ctx.mult, 21.6, "20 + 80 x 0.02")
        ctx = H.fire(j, "card_played", {
            card_node = s, played_cards = { s }, full_hand = { s },
            chips = ctx.chips, mult = ctx.mult, rank = 7, suit = "Stars",
        })
        near(ctx.mult, 23.168, "the second Stars card balances again")
        local p = H.node(2, "Clubs")
        local ctx2 = H.fire(j, "card_played", {
            card_node = p, played_cards = { p }, full_hand = { p },
            chips = 100, mult = 20, rank = 2, suit = "Clubs",
        })
        H.assert_eq(ctx2.mult, 20, "non-Stars cards do not balance")
    end)

    H.test("grenadine: scored Hearts gain perma X0.2 Mult; eaten after 5", function()
        local game = H.new_game()
        local j = H.make_joker(game, "grenadine")
        local h = H.node(7, "Hearts")
        H.play_card(j, h, { h })
        near(SMODS.get_perma(h, "perma_x_mult"), 1.2)
        H.assert_eq(j.ability.extra.remaining, 4)
        local c = H.node(7, "Clubs")
        H.play_card(j, c, { c })
        H.assert_true(SMODS.get_perma(c, "perma_x_mult") == nil,
            "other suits gain nothing")
        H.assert_eq(j.ability.extra.remaining, 4)
        j.ability.extra.remaining = 1
        local h2 = H.node(9, "Hearts")
        H.play_card(j, h2, { h2 })
        H.assert_eq(j.ability.extra.remaining, 0)
        H.fire(j, "on_hand_after", {})
        H.assert_eq(#game.jokers, 0, "eaten when its charges run out")
    end)

    H.test("nigori: scored Stars gain perma X0.3 Chips", function()
        local game = H.new_game()
        local j = H.make_joker(game, "nigori")
        local s = H.node(7, "Stars")
        H.play_card(j, s, { s })
        near(SMODS.get_perma(s, "perma_x_chips"), 1.3)
        H.assert_eq(j.ability.extra.remaining, 4)
        local h = H.node(7, "Hearts")
        H.play_card(j, h, { h })
        H.assert_true(SMODS.get_perma(h, "perma_x_chips") == nil)
    end)

    H.test("aperol: scored Diamonds each gain perma $1", function()
        local game = H.new_game()
        local j = H.make_joker(game, "aperol")
        local d1 = H.node(7, "Diamonds")
        H.play_card(j, d1, { d1 })
        H.assert_eq(SMODS.get_perma(d1, "perma_p_dollars"), 1)
        local d2 = H.node(9, "Diamonds")
        H.play_card(j, d2, { d2 })
        H.assert_eq(SMODS.get_perma(d2, "perma_p_dollars"), 1,
            "each card gains its own $1")
        H.assert_eq(j.ability.extra.remaining, 3)
    end)

    H.test("pink joker: scored cards can gain perma $2 while a Stained card is held", function()
        local game = H.new_game()
        local j = H.make_joker(game, "pink_joker")
        local target = H.node(7, "Clubs")
        for _ = 1, 10 do H.play_card(j, target, { target }) end
        H.assert_true(SMODS.get_perma(target, "perma_p_dollars") == nil,
            "no Stained card held: nothing is granted")
        local stained = H.node(4, "Hearts", { enhancement = "stained" })
        game.hand.card_nodes = { stained }
        local hit = false
        for _ = 1, 80 do
            target.card_data.perma_p_dollars = nil
            H.play_card(j, target, { target })
            if SMODS.get_perma(target, "perma_p_dollars") == 2 then
                hit = true break
            end
        end
        H.assert_true(hit, "the 1 in 5 roll lands within 80 tries")
    end)

    H.test("bergentrucking: Crowns gain perma X0.05 Mult and Hearts are destroyed", function()
        local game = H.new_game()
        local j = H.make_joker(game, "bergentrucking")
        game.hand:add_card({ rank = 13, suit = "Crowns" })
        game.hand:add_card({ rank = 14, suit = "Hearts" })
        game.hand:add_card({ rank = 2, suit = "Clubs" })
        local by_suit = {}
        for _, n in ipairs(game.hand.card_nodes) do
            by_suit[n.card_data.suit] = n
        end
        local crown = by_suit["Crowns"]
        local heart = by_suit["Hearts"]
        local plain = by_suit["Clubs"]
        local hand = { crown, heart, plain }
        for _, n in ipairs(hand) do H.play_card(j, n, hand) end
        H.scored(j, { cards = hand })
        near(SMODS.get_perma(crown, "perma_x_mult"), 1.05)
        H.fire(j, "on_hand_after", { cards = hand })
        H.assert_eq(#game.hand.card_nodes, 2, "the Hearts card is destroyed")
        local heart_alive = false
        for _, n in ipairs(game.hand.card_nodes) do
            if n == heart then heart_alive = true end
        end
        H.assert_eq(heart_alive, false)
        H.assert_eq(j.ability.extra.active_suit, false, "flags reset")
    end)

    H.test("bergentrucking: Crowns alone trigger nothing", function()
        local game = H.new_game()
        local j = H.make_joker(game, "bergentrucking")
        game.hand:add_card({ rank = 13, suit = "Crowns" })
        game.hand:add_card({ rank = 2, suit = "Clubs" })
        local by_suit = {}
        for _, n in ipairs(game.hand.card_nodes) do
            by_suit[n.card_data.suit] = n
        end
        local crown = by_suit["Crowns"]
        local plain = by_suit["Clubs"]
        local hand = { crown, plain }
        for _, n in ipairs(hand) do H.play_card(j, n, hand) end
        H.scored(j, { cards = hand })
        H.assert_true(SMODS.get_perma(crown, "perma_x_mult") == nil,
            "no Hearts scored: no grant")
        H.fire(j, "on_hand_after", { cards = hand })
        H.assert_eq(#game.hand.card_nodes, 2, "nothing is destroyed")
    end)

    H.test("freedom of choice: a Five of a Kind grows every scoring card", function()
        local game = H.new_game()
        local j = H.make_joker(game, "freedom_of_choice")
        local a, b = H.node(7, "Hearts"), H.node(7, "Clubs")
        H.scored(j, { contains_hand_types = { ["Five of a Kind"] = true },
            cards = { a, b } })
        near(SMODS.get_perma(a, "perma_x_mult"), 1.05)
        near(SMODS.get_perma(b, "perma_x_mult"), 1.05)
        local c = H.node(2, "Spades")
        H.scored(j, { contains_hand_types = { Pair = true },
            cards = { c } })
        H.assert_true(SMODS.get_perma(c, "perma_x_mult") == nil,
            "other hands gain nothing")
    end)

    H.test("shinzaemon: the 5th scoring card gains perma X0.2 Mult", function()
        local game = H.new_game()
        local j = H.make_joker(game, "shinzaemon")
        local hand = {}
        for i = 1, 5 do hand[i] = H.node(i + 2, "Hearts") end
        H.before(j, { scoring_hand = hand, cards = hand,
            full_hand = hand })
        near(SMODS.get_perma(hand[5], "perma_x_mult"), 1.2)
        H.assert_true(SMODS.get_perma(hand[1], "perma_x_mult") == nil,
            "only the 5th card gains")
        local short = {}
        for i = 1, 4 do short[i] = H.node(i + 2, "Clubs") end
        H.before(j, { scoring_hand = short, cards = short,
            full_hand = short })
        H.assert_true(SMODS.get_perma(short[4], "perma_x_mult") == nil,
            "a 4-card hand has no 5th card")
    end)

    H.test("sacred heart: a Flush Five retriggers the first card and destroys the rest", function()
        local game = H.new_game()
        local j = H.make_joker(game, "sacred_heart")
        for _ = 1, 3 do
            game.hand:add_card({ rank = 14, suit = "Hearts" })
        end
        local a = game.hand.card_nodes[1]
        local hand = { game.hand.card_nodes[1], game.hand.card_nodes[2],
            game.hand.card_nodes[3] }
        H.scored(j, { hand_type = "Pair", cards = hand })
        H.fire(j, "on_hand_after", { cards = hand })
        H.assert_eq(#game.hand.card_nodes, 3, "a Pair changes nothing")
        H.scored(j, { hand_type = "Flush Five", cards = hand })
        H.fire(j, "on_hand_after", { cards = hand })
        H.assert_eq(SMODS.get_perma(a, "perma_repetitions"), 1,
            "the first card gains a permanent retrigger")
        H.assert_eq(#game.hand.card_nodes, 1,
            "the other scored cards are destroyed")
    end)

    H.test("determination: a lost blind is survived at -1 Ante and -1 hand size", function()
        local game = H.new_game()
        local j = H.make_joker(game, "determination")
        game.ante = 3
        game.STATE = game.STATES.SELECTING_HAND
        game.hands = 0
        game.round_score = 0
        game.current_blind_target = 300
        game:handle_failed_blind_reset()
        H.assert_true(game.STATE ~= game.STATES.GAME_OVER,
            "saved: the run continues")
        H.assert_eq(#game.jokers, 0, "Determination spent itself")
        H.assert_eq(game.ante, 2, "Ante -1")
        H.assert_eq(game.hand_size_delta_juggle, -1, "hand size -1")
    end)

    H.test("determination: without it, the same lost blind ends the run", function()
        local game = H.new_game()
        H.make_joker(game, "claw")
        game.STATE = game.STATES.SELECTING_HAND
        game.hands = 0
        game.round_score = 0
        game.current_blind_target = 300
        game:handle_failed_blind_reset()
        H.assert_eq(game.STATE, game.STATES.GAME_OVER)
    end)
end

-- Behavior tests for the Wave 5 copy Jokers (v1.3.0): Forgery,
-- Master Plan and Photocopy, all riding SMODS.blueprint_effect.
-- H.scored starts at chips 10 / mult 2. Complete Breakfast is the
-- pack's deterministic mod copy target: blueprint_compat on PC, and
-- at joker_main it returns +50 Chips / +5 Mult.
PB_TESTS_7 = function(H)
    H.test("wave5: pack Jokers declare their PC blueprint_compat values", function()
        local game = H.new_game()
        H.assert_eq(JOKER_DEFS["j_pbp_forgery"].blueprint_compat, true)
        H.assert_eq(JOKER_DEFS["j_pbp_master_plan"].blueprint_compat, true)
        H.assert_eq(JOKER_DEFS["j_pbp_photocopy"].blueprint_compat, true)
        H.assert_eq(JOKER_DEFS["j_pbp_complete_breakfast"].blueprint_compat, true,
            "a PC-true target declares it (Wave 5 compat pass)")
        H.assert_eq(JOKER_DEFS["j_pbp_bamboo_stick"].blueprint_compat, true)
        H.assert_true(JOKER_DEFS["j_pbp_thornring"].blueprint_compat ~= true,
            "ThornRing is PC blueprint_compat = false")
        H.assert_true(JOKER_DEFS["j_pbp_a_balatro_movie"].blueprint_compat ~= true,
            "A Balatro Movie is PC blueprint_compat = false")
    end)

    H.test("forgery: copies a held mod Joker and multiplies its Chips and Mult", function()
        local game = H.new_game()
        local target = H.make_joker(game, "complete_breakfast")
        local j = H.make_joker(game, "forgery")
        H.assert_eq(j.ability.extra.copying, "j_pbp_complete_breakfast",
            "the reset on gaining Forgery picks the only eligible Joker")
        H.assert_eq(j.ability.extra.copying_card, target)
        H.assert_true(j.ability.extra.multiplier >= 1.5
            and j.ability.extra.multiplier <= 2.5,
            "reset multiplier in X1.5..X2.5, got "
            .. tostring(j.ability.extra.multiplier))
        j.ability.extra.multiplier = 2
        local ctx = H.scored(j, {})
        H.assert_eq(ctx.chips, 110, "10 + 50 Chips x2")
        H.assert_eq(ctx.mult, 12, "2 + 5 Mult x2")
    end)

    H.test("forgery: resets its target and multiplier after a hand", function()
        local game = H.new_game()
        local a = H.make_joker(game, "complete_breakfast")
        local b = H.make_joker(game, "bamboo_stick")
        local j = H.make_joker(game, "forgery")
        j.ability.extra.multiplier = 1
        H.fire(j, "on_hand_after", {})
        local pick = j.ability.extra.copying_card
        H.assert_true(pick == a or pick == b,
            "after a hand the target is a held compatible Joker")
        H.assert_eq(j.ability.extra.copying, pick.def.id)
        H.assert_true(j.ability.extra.multiplier >= 1.5
            and j.ability.extra.multiplier <= 2.5,
            "the multiplier rerolled into X1.5..X2.5, got "
            .. tostring(j.ability.extra.multiplier))
    end)

    H.test("forgery: a vanilla target fires in place, unmultiplied", function()
        local game = H.new_game()
        local idx = #game.jokers + 1
        assert(game:add_joker_by_def("j_joker"))
        local vanilla = game.jokers[idx]
        H.assert_eq(vanilla.def.id, "j_joker", "vanilla Joker held")
        local j = H.make_joker(game, "forgery")
        H.assert_eq(j.ability.extra.copying_card, vanilla,
            "the vanilla Joker is the only eligible target")
        j.ability.extra.multiplier = 2
        local ctx = H.scored(j, {})
        H.assert_eq(ctx.mult, 6,
            "the +4 lands once, in place: the documented nil-return delta")
        H.assert_eq(ctx.chips, 10, "no Chips from a vanilla Joker")
    end)

    H.test("master plan: copies the Joker to its left (mod and vanilla)", function()
        local game = H.new_game()
        H.make_joker(game, "complete_breakfast")
        local mp = H.make_joker(game, "master_plan")
        local ctx = H.scored(mp, {})
        H.assert_eq(ctx.chips, 60, "the left mod Joker's +50 Chips, unmodified")
        H.assert_eq(ctx.mult, 7, "the left mod Joker's +5 Mult, unmodified")

        local game2 = H.new_game()
        local idx = #game2.jokers + 1
        assert(game2:add_joker_by_def("j_joker"))
        local mp2 = H.make_joker(game2, "master_plan")
        local ctx2 = H.scored(mp2, {})
        H.assert_eq(ctx2.mult, 6, "the left vanilla Joker's +4 fires in place")
    end)

    H.test("master plan: leftmost copies nothing", function()
        local game = H.new_game()
        local mp = H.make_joker(game, "master_plan")
        H.make_joker(game, "complete_breakfast")
        local ctx = H.scored(mp, {})
        H.assert_eq(ctx.chips, 10)
        H.assert_eq(ctx.mult, 2)
    end)

    H.test("photocopy: copies the rightmost Joker", function()
        local game = H.new_game()
        local pc_ = H.make_joker(game, "photocopy")
        H.make_joker(game, "complete_breakfast")
        local ctx = H.scored(pc_, {})
        H.assert_eq(ctx.chips, 60, "the rightmost Joker's +50 Chips")
        H.assert_eq(ctx.mult, 7, "the rightmost Joker's +5 Mult")
    end)

    H.test("photocopy: rightmost itself copies nothing", function()
        local game = H.new_game()
        H.make_joker(game, "complete_breakfast")
        local pc_ = H.make_joker(game, "photocopy")
        local ctx = H.scored(pc_, {})
        H.assert_eq(ctx.chips, 10, "self-copy is gated by the dispatch")
        H.assert_eq(ctx.mult, 2)
    end)

    H.test("wave5 dispatch: non-compatible and debuffed targets never fire", function()
        local game = H.new_game()
        local thorn = H.make_joker(game, "thornring")
        local mp = H.make_joker(game, "master_plan")
        H.assert_eq(SMODS.blueprint_effect(mp, thorn, { joker_main = true }),
            nil, "ThornRing is not blueprint_compat")
        local ctx = H.scored(mp, {})
        H.assert_eq(ctx.mult, 2, "a non-compat left neighbour gives nothing")

        local game2 = H.new_game()
        local target = H.make_joker(game2, "complete_breakfast")
        local mp2 = H.make_joker(game2, "master_plan")
        local direct = SMODS.blueprint_effect(mp2, target,
            { joker_main = true })
        H.assert_true(type(direct) == "table" and direct.mult == 5,
            "a compat target returns its table while up")
        SMODS.set_joker_debuff(target, true)
        H.assert_eq(SMODS.blueprint_effect(mp2, target,
            { joker_main = true }), nil, "a debuffed target does not fire")
        local ctx2 = H.scored(mp2, {})
        H.assert_eq(ctx2.chips, 10, "and the scoring pass agrees")
        H.assert_eq(ctx2.mult, 2)
        SMODS.set_joker_debuff(target, false)
        local again = SMODS.blueprint_effect(mp2, target,
            { joker_main = true })
        H.assert_true(type(again) == "table" and again.chips == 50,
            "clearing the debuff restores the copy")
    end)
end

PB_TESTS_8 = function(H)
    H.test("wave6 backpack: the shop starts with a free Buffoon Pack", function()
        local game = H.new_game()
        H.make_joker(game, "backpack")
        game:enter_shop_after_blind()
        local found = nil
        for _, o in ipairs(game.shop_booster_offers or {}) do
            if o.pack == "buffoon" then found = o end
        end
        H.assert_true(found ~= nil, "a Buffoon offer is shelved")
        H.assert_eq(game:get_shop_booster_price(found), 0,
            "and it is free")
    end)

    H.test("wave6 protocol: packs deal one extra card while held", function()
        local game = H.new_game()
        game:enter_shop_after_blind()
        local offer = { kind = "booster", pack = "arcana", size = "normal",
            price = 4, name = "Arcana Pack", card_count = 2,
            picks_granted = 1 }
        game:begin_booster_session(offer)
        H.assert_eq(#game.booster_session.choices, 2,
            "a vanilla Arcana pack deals 2")
        game:end_booster_session()
        H.make_joker(game, "protocol")
        game:begin_booster_session(offer)
        H.assert_eq(#game.booster_session.choices, 3, "Protocol makes it 3")
        game:end_booster_session()
    end)

    H.test("wave6 shopping center: the shop fills one extra card slot", function()
        local game = H.new_game()
        game:enter_shop_after_blind()
        H.assert_eq(#game.shop_offers, 2, "the vanilla shelf holds 2")
        local game2 = H.new_game()
        H.make_joker(game2, "shopping_center")
        game2:enter_shop_after_blind()
        H.assert_eq(#game2.shop_offers, 3, "Shopping Center makes it 3")
    end)

    H.test("wave6 everything must go: a second voucher is shelved", function()
        local game = H.new_game()
        H.make_joker(game, "everything_must_go")
        game:enter_shop_after_blind()
        H.assert_eq(#game.shop_voucher_offers, 2)
    end)

    H.test("wave6 normalJKR: bought in a shop, card offers are free", function()
        local game = H.new_game()
        game:enter_shop_after_blind()
        local offer = game.shop_offers[1]
        H.assert_true(game:get_shop_offer_price(offer) > 0,
            "prices are real before the Joker")
        game.STATE = game.STATES.SHOP
        local j = H.make_joker(game, "normalJKR")
        H.assert_eq(j.ability.free_shop_purchases, 1,
            "gaining it in the shop arms the counter")
        game:refresh_shop_prices()
        H.assert_eq(game:get_shop_offer_price(offer), 0,
            "card offers are free while it is held")
        local v = game.shop_voucher_offers[1]
        H.assert_true(game:get_shop_voucher_price(v) > 0,
            "vouchers still charge")
        j.def.smods.remove_from_deck(j.def.smods, j)
        H.assert_eq(j.ability.free_shop_purchases, nil,
            "losing the Joker disarms the counter")
    end)

    H.test("wave6 normalJKR: gained outside a shop, nothing is free", function()
        local game = H.new_game()
        local j = H.make_joker(game, "normalJKR")
        H.assert_eq(j.ability.free_shop_purchases, nil,
            "no arming outside the shop state")
        game:enter_shop_after_blind()
        local offer = game.shop_offers[1]
        H.assert_true(game:get_shop_offer_price(offer) > 0)
    end)

    H.test("wave6 touch tone: the first card of a consumable pack is drawn", function()
        local game = H.new_game()
        H.make_joker(game, "touch_tone_joker")
        game:enter_shop_after_blind()
        local offer = { kind = "booster", pack = "arcana", size = "normal",
            price = 4, name = "Arcana Pack", card_count = 2,
            picks_granted = 1 }
        game:begin_booster_session(offer)
        local s = game.booster_session
        local first = s.choices[1]
        H.assert_eq(first.taken, true, "the first choice was claimed")
        H.assert_eq(#game.consumables, 1, "and it is in the consumables")
        H.assert_eq(game.consumables[1].id, first.consumable_def.id)
        game:end_booster_session()
        game:begin_booster_session(
            { kind = "booster", pack = "buffoon", size = "normal",
              price = 4, name = "Buffoon Pack", card_count = 2,
              picks_granted = 1 })
        local s2 = game.booster_session
        H.assert_eq(#game.consumables, 1, "a Buffoon pack draws nothing")
        for _, c in ipairs(s2.choices) do
            H.assert_true(not c.taken, "its choices stay untouched")
        end
        game:end_booster_session()
    end)

    H.test("wave6 chaplin: buying a voucher redeems its upgrade free", function()
        local game = H.new_game()
        H.make_joker(game, "chaplin")
        game:enter_shop_after_blind()
        game.money = 100
        game.shop_voucher_offers = {
            { id = "v_overstock", name = "Overstock",
              description = "", price = 10 },
        }
        local ok = game:buy_shop_voucher(1)
        H.assert_true(ok, "the base voucher buys")
        H.assert_true(game:has_voucher("v_overstock"))
        H.assert_true(game:has_voucher("v_overstock_plus"),
            "Chaplin redeemed the upgraded version")
        H.assert_eq(game.money, 90, "only the bought voucher was paid for")
    end)

    H.test("wave6 ouija board: spectrals join the queue rate, Jokers shuffle", function()
        local game = H.new_game()
        local keys = { "aurora_borealis", "bicycle", "claw", "jacks" }
        for _, k in ipairs(keys) do H.make_joker(game, k) end
        local ouija = H.make_joker(game, "oujia_board")
        H.assert_eq(SMODS.modifier_total(game, "spectral_rate_mod"), 2)
        local function order()
            local ids = {}
            for _, j in ipairs(game:_collect_jokers_in_slot_order()) do
                ids[#ids + 1] = j.def.id
            end
            return table.concat(ids, ",")
        end
        local before = order()
        game:emit_joker_event("on_press_play", {})
        H.assert_true(order() ~= before,
            "the slot order shuffled before scoring")
        H.assert_eq(#game.jokers, 5, "no Joker was lost in the shuffle")
    end)
end

PB_TESTS_0(H)
PB_TESTS_1(H)
PB_TESTS_2(H)
PB_TESTS_3(H)
PB_TESTS_4(H)
PB_TESTS_5(H)
PB_TESTS_6(H)
PB_TESTS_7(H)
PB_TESTS_8(H)

return suite
