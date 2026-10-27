--- Tests for the PaperbackPack paperclip system (Wave 7): the eleven
--- clips as fork attachments, the clip Jokers and the clip Arcana.
--- The mod's real main file is read from the PB_PACK_LUA env var.
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

local JOKERS = {
    "aurora_borealis", "bicycle", "emergency_broadcast", "find_jimbo",
    "guns_blazin", "insurance_policy", "malibu", "trust_us",
    "attacking_vertical", "better_call_jimbo", "calling_card", "claw",
    "giga_size", "grand_strategy", "jacks", "jestrica", "magic_mushroom",
    "mismatched_sock", "nazar", "planchette", "satellite_array", "technology",
    "toppins", "union_card", "the_quiet", "pocket_pair", "rosary_beads",
    "surfer", "the_girl_from_024", "tian_tian", "time_regression_mix",
    "57_leaf_clover", "unionized_labor", "park_postcard", "river", "langely",
}

local ARCANA = {
    ace_of_pentacles = "Ace of Pentacles",
    ace_of_swords = "Ace of Swords",
    two_of_cups = "Two of Cups",
    four_of_cups = "Four of Cups",
    seven_of_cups = "Seven of Cups",
    eight_of_cups = "Eight of Cups",
    nine_of_cups = "Nine of Cups",
    ten_of_cups = "Ten of Cups",
    knight_of_cups = "Knight of Cups",
    king_of_cups = "King of Cups",
    two_of_wands = "Two of Wands",
    three_of_wands = "Three of Wands",
    five_of_wands = "Five of Wands",
    eight_of_wands = "Eight of Wands",
    ten_of_wands = "Ten of Wands",
    king_of_wands = "King of Wands",
    four_of_swords = "Four of Swords",
    five_of_swords = "Five of Swords",
    nine_of_swords = "Nine of Swords",
    ten_of_swords = "Ten of Swords",
    knight_of_swords = "Knight of Swords",
    queen_of_swords = "Queen of Swords",
    king_of_swords = "King of Swords",
    two_of_pentacles = "Two of Pentacles",
    three_of_pentacles = "Three of Pentacles",
    four_of_pentacles = "Four of Pentacles",
    six_of_cups = "Six of Cups",
    six_of_pentacles = "Six of Pentacles",
    eight_of_pentacles = "Eight of Pentacles",
    ten_of_pentacles = "Ten of Pentacles",
    queen_of_pentacles = "Queen of Pentacles",
    knight_of_pentacles = "Knight of Pentacles",
    king_of_pentacles = "King of Pentacles",
    five_of_cups = "Five of Cups",
    five_of_pentacles = "Five of Pentacles",
    queen_of_cups = "Queen of Cups",
    nine_of_wands = "Nine of Wands",
    knight_of_wands = "Knight of Wands",
    seven_of_wands = "Seven of Wands",
    queen_of_wands = "Queen of Wands",
    page_of_pentacles = "Page of Pentacles",
    page_of_swords = "Page of Swords",
    six_of_wands = "Six of Wands",
    three_of_swords = "Three of Swords",
    two_of_swords = "Two of Swords",
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
    -- Wave 7 paperclip sprites (clips, clip Jokers, clip Arcana).
    for _, n in ipairs({
        "white_clip", "black_clip", "blue_clip", "gold_clip", "green_clip",
        "orange_clip", "pink_clip", "purple_clip", "platinum_clip",
        "red_clip", "yellow_clip",
        "chip_clip", "clippy", "clippy_soul", "clothespin",
        "manilla_folder", "vacation_juice",
        "ace_of_cups", "ace_of_wands", "three_of_cups", "four_of_wands",
        "page_of_wands", "page_of_cups", "six_of_swords", "seven_of_swords",
        "seven_of_pentacles", "eight_of_swords", "nine_of_pentacles",
    }) do
        love.filesystem.write(base .. "/assets/1x/" .. n .. ".png", "png")
        love.filesystem.write(base .. "/assets/1x/" .. n .. "_negative.png", "png")
    end
    for _, n in ipairs(JOKERS) do
        love.filesystem.write(base .. "/assets/1x/" .. n .. ".png", "png")
        love.filesystem.write(base .. "/assets/1x/" .. n .. "_negative.png", "png")
    end
    for n in pairs(ARCANA) do
        love.filesystem.write(base .. "/assets/1x/" .. n .. ".png", "png")
        love.filesystem.write(base .. "/assets/1x/" .. n .. "_negative.png", "png")
    end
    -- Dummy sprites for the 188 expansion Jokers (registered by the
    -- appended port sections of the pack file).
    for _, n in ipairs({
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
        "master_spark", "matcha", "medic", "blood_rain", "meeple", "mezzetino",
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
    }) do
        love.filesystem.write(base .. "/assets/1x/" .. n .. ".png", "png")
        love.filesystem.write(base .. "/assets/1x/" .. n .. "_negative.png", "png")
    end
    -- Dummy sprites for the Tier 3 (v1.1.0) Jokers.
    for _, n in ipairs({
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
        "unholy_alliance", "jimbo_adventure_soul", "off_alpha_soul", "off_epsilon_soul",
        "off_omega_soul",
    }) do
        love.filesystem.write(base .. "/assets/1x/" .. n .. ".png", "png")
        love.filesystem.write(base .. "/assets/1x/" .. n .. "_negative.png", "png")
    end
    -- Dummy sprites for the Wave 1 (v1.2.0) Jokers.
    for _, n in ipairs({
        "milk_tea", "stardrop", "stardrop_soul", "bergentrucking",
        "freedom_of_choice", "grenadine", "shinzaemon", "shinzaemon_soul",
        "nigori", "aperol", "pink_joker", "sacred_heart", "determination",
    }) do
        love.filesystem.write(base .. "/assets/1x/" .. n .. ".png", "png")
        love.filesystem.write(base .. "/assets/1x/" .. n .. "_negative.png", "png")
    end
    -- Dummy sprites for the Wave 5 (v1.3.0) copy Jokers.
    for _, n in ipairs({
        "forgery", "master_plan", "photocopy",
    }) do
        love.filesystem.write(base .. "/assets/1x/" .. n .. ".png", "png")
        love.filesystem.write(base .. "/assets/1x/" .. n .. "_negative.png", "png")
    end
    -- Dummy sprites for the Wave 6 (v1.4.0) shop Jokers.
    for _, n in ipairs({
        "backpack", "protocol", "shopping_center", "touch_tone_joker",
        "chaplin", "everything_must_go", "normalJKR", "oujia_board",
        "chaplin_soul",
    }) do
        love.filesystem.write(base .. "/assets/1x/" .. n .. ".png", "png")
        love.filesystem.write(base .. "/assets/1x/" .. n .. "_negative.png", "png")
    end
    -- Opt-in loader (Wave 7 fixture fix): a pack loads only when its id
    -- is in the saved selection, so write it before load_all.
    love.filesystem.write(ModLoader.ENABLED_PATH, "PaperbackPack\n")
    ModLoader.load_all()
    local game = bootstrap.new_game(9182)
    game.hand = Hand(game)
    game.deck = Deck(game)
    G = game
    G.play = G.play or SMODS.PLAY
    _G.Top = _G.Top or { addPopup = function() end }
    game.consumables, game.consumable_nodes = {}, {}
    game.jokers = {}
    return game
end

local function card(rank, suit, enhancement)
    local data = { rank = rank, suit = suit or "Hearts" }
    if enhancement then data.enhancement = enhancement end
    local c = Card(0, 0, 1, 1, data)
    c.counts_for_play_score = true
    return c
end

local function hold(game, key)
    local id = "c_pbp_" .. key
    T.assert_true(game:add_consumable(id), id .. " should be addable")
    return #game.consumables
end

local function add_joker(game, id)
    game.jokers = game.jokers or {}
    T.assert_true(game:add_joker_by_def(id), id .. " should be addable")
    return game.jokers[#game.jokers]
end

-- Put cards in hand and select some of them (position order preserved).
local function setup_hand(game, nodes, selected)
    game.hand.card_nodes = nodes
    game.hand.cards = {}
    for i, n in ipairs(nodes) do game.hand.cards[i] = n.card_data end
    game.hand.selected = selected or {}
    game.STATE = game.STATES.SELECTING_HAND
end

--------------------------------------------------------------------------------
-- Helpers for the clip tests
--------------------------------------------------------------------------------

local function clip_state(node, bare)
    local atts = node.card_data and node.card_data.attachments
    return type(atts) == "table" and atts["pbp_" .. bare] or nil
end

local function set_clip(node, bare)
    return SMODS.set_attachment(node, "pbp_" .. bare)
end

local function play_ctx()
    return { chips = 0, mult = 1 }
end

--------------------------------------------------------------------------------
-- Registration
--------------------------------------------------------------------------------

suite.test("clips: 11 attachments, 5 jokers, 11 arcana register", function()
    local game = install_pack()
    local mod = ModLoader.by_id.PaperbackPack
    T.assert_eq(mod.status, "loaded", tostring(mod.error))
    T.assert_eq(#mod.registered.attachments, 11, "11 clip attachments register")
    for _, bare in ipairs({ "white_clip", "black_clip", "blue_clip", "gold_clip",
        "green_clip", "orange_clip", "pink_clip", "purple_clip", "platinum_clip",
        "red_clip", "yellow_clip" }) do
        T.assert_true(SMODS.Attachments["pbp_" .. bare] ~= nil, bare .. " registered")
    end
    for _, key in ipairs({ "chip_clip", "clippy", "clothespin", "manilla_folder",
        "vacation_juice" }) do
        T.assert_true(JOKER_DEFS["j_pbp_" .. key] ~= nil, key .. " joker registered")
    end
    for _, key in ipairs({ "ace_of_cups", "ace_of_wands", "three_of_cups",
        "four_of_wands", "page_of_wands", "page_of_cups", "six_of_swords",
        "seven_of_swords", "seven_of_pentacles", "eight_of_swords",
        "nine_of_pentacles" }) do
        T.assert_true(CONSUMABLE_DEFS["c_pbp_" .. key] ~= nil, key .. " arcana registered")
    end
    wipe_mods()
end)

--------------------------------------------------------------------------------
-- Applying clips: the Arcana and the one-clip rule
--------------------------------------------------------------------------------

suite.test("clips: ace of cups applies blue; a second arcana replaces it", function()
    local game = install_pack()
    local a, b = card(5, "Hearts"), card(9, "Clubs")
    setup_hand(game, { a, b }, { a, b })
    local slot = hold(game, "ace_of_cups")
    T.assert_true(game:use_consumable(slot))
    T.assert_true(clip_state(a, "blue_clip") ~= nil, "blue on the first card")
    T.assert_true(clip_state(b, "blue_clip") ~= nil, "blue on the second card")
    setup_hand(game, { a, b }, { a })
    local slot2 = hold(game, "page_of_cups")
    T.assert_true(game:use_consumable(slot2))
    T.assert_true(clip_state(a, "white_clip") ~= nil, "white replaced blue")
    T.assert_eq(clip_state(a, "blue_clip"), nil, "one clip per card")
    T.assert_true(clip_state(b, "blue_clip") ~= nil, "the other card kept its clip")
    wipe_mods()
end)

suite.test("clips: eight of swords applies a random clip to each selected card", function()
    local game = install_pack()
    local a, b = card(5, "Hearts"), card(9, "Clubs")
    setup_hand(game, { a, b }, { a, b })
    local slot = hold(game, "eight_of_swords")
    T.assert_true(game:use_consumable(slot))
    T.assert_true(next(a.card_data.attachments or {}) ~= nil, "first card clipped")
    T.assert_true(next(b.card_data.attachments or {}) ~= nil, "second card clipped")
    wipe_mods()
end)

--------------------------------------------------------------------------------
-- Scoring clips
--------------------------------------------------------------------------------

suite.test("clips: red pays +5 Mult per clip held in hand", function()
    local game = install_pack()
    local h1, h2 = card(3, "Hearts"), card(4, "Clubs")
    set_clip(h1, "white_clip")
    setup_hand(game, { h1, h2 }, {})
    local p = card(7, "Spades")
    set_clip(p, "red_clip")
    local ctx = play_ctx()
    p:emit_hand_event("card_played", ctx)
    T.assert_eq(ctx.mult, 6, "1 + 5 x 1 hand clip")
    wipe_mods()
end)

suite.test("clips: clothespin counts as a hand clip with no clipped cards", function()
    local game = install_pack()
    add_joker(game, "j_pbp_clothespin")
    local h1 = card(3, "Hearts")
    setup_hand(game, { h1 }, {})
    local p = card(7, "Spades")
    set_clip(p, "red_clip")
    local ctx = play_ctx()
    p:emit_hand_event("card_played", ctx)
    T.assert_eq(ctx.mult, 6, "clothespin alone makes the count 1")
    wipe_mods()
end)

suite.test("clips: blue multiplies chips by the hand clip count", function()
    local game = install_pack()
    local h1, h2 = card(3, "Hearts"), card(4, "Clubs")
    set_clip(h1, "white_clip")
    set_clip(h2, "gold_clip")
    setup_hand(game, { h1, h2 }, {})
    local p = card(7, "Spades")
    set_clip(p, "blue_clip")
    local ctx = { chips = 100, mult = 1 }
    p:emit_hand_event("card_played", ctx)
    T.assert_true(math.abs(ctx.chips - 120) < 0.01,
        "100 x (1 + 2 x 0.1) = 120, got " .. tostring(ctx.chips))
    wipe_mods()
end)

suite.test("clips: orange pays $1 per 2 clips held in hand", function()
    local game = install_pack()
    local nodes = {}
    for i = 1, 4 do
        nodes[i] = card(i + 2, "Hearts")
        set_clip(nodes[i], "white_clip")
    end
    setup_hand(game, nodes, {})
    local p = card(7, "Spades")
    set_clip(p, "orange_clip")
    local money = game.money
    p:emit_hand_event("card_played", play_ctx())
    T.assert_eq(game.money, money + 2, "4 clips held: $2")
    wipe_mods()
end)

suite.test("clips: black retriggers only while a clip is held", function()
    local game = install_pack()
    local h1 = card(3, "Hearts")
    setup_hand(game, { h1 }, {})
    local p = card(7, "Spades")
    set_clip(p, "black_clip")
    local out = game:collect_retrigger_sources(false, { card_node = p }, {})
    T.assert_eq(#out, 0, "no clip in hand: no retrigger")
    set_clip(h1, "white_clip")
    setup_hand(game, { h1 }, {})
    out = game:collect_retrigger_sources(false, { card_node = p }, {})
    T.assert_eq(#out, 1, "a clip in hand: one retrigger")
    wipe_mods()
end)

suite.test("clips: white grows at round end by clips scored; gold pays for them", function()
    local game = install_pack()
    local w, gnode = card(3, "Hearts"), card(4, "Clubs")
    set_clip(w, "white_clip")
    set_clip(gnode, "gold_clip")
    setup_hand(game, { w, gnode }, {})
    local p = card(7, "Spades")
    set_clip(p, "red_clip")
    p:emit_hand_event("card_played", play_ctx())
    local money = game.money
    w:emit_hand_event("on_round_end", play_ctx())
    gnode:emit_hand_event("on_round_end", play_ctx())
    T.assert_eq(clip_state(w, "white_clip").chips, 2, "white gained 2 x 1 scored clip")
    T.assert_eq(game.money, money + 1, "gold paid $1 for the scored clip")
    local ctx = play_ctx()
    w:emit_hand_event("card_played", ctx)
    T.assert_eq(ctx.chips, 2, "white's stored chips land when it scores")
    wipe_mods()
end)

suite.test("clips: pink grows per scored clip, pays held, resets after the hand", function()
    local game = install_pack()
    local pk = card(3, "Hearts")
    set_clip(pk, "pink_clip")
    setup_hand(game, { pk }, {})
    local p = card(7, "Spades")
    set_clip(p, "red_clip")
    p:emit_hand_event("card_played", play_ctx())
    T.assert_true(math.abs(clip_state(pk, "pink_clip").x_mult - 1.1) < 0.001,
        "pink heard the scored clip")
    local ctx = { chips = 0, mult = 10 }
    pk:emit_hand_event("held_in_hand", ctx)
    T.assert_true(math.abs(ctx.mult - 11) < 0.001, "held pink pays X1.1")
    pk:emit_hand_event("after_scoring", play_ctx())
    T.assert_eq(clip_state(pk, "pink_clip").x_mult, 1, "pink resets after the hand")
    wipe_mods()
end)

suite.test("clips: purple builds odds per scored clip, creates a tarot, resets in hand", function()
    local game = install_pack()
    local pu = card(3, "Hearts")
    local st = set_clip(pu, "purple_clip")
    st.numerator = 9
    setup_hand(game, { pu }, {})
    local p = card(7, "Spades")
    set_clip(p, "red_clip")
    p:emit_hand_event("card_played", play_ctx())
    T.assert_eq(st.numerator, 10, "the scored clip raised the odds")
    local before = #game.consumables
    pu:emit_hand_event("held_in_hand", play_ctx())
    T.assert_eq(#game.consumables, before + 1, "10 in 10: a tarot was created")
    pu:emit_hand_event("after_scoring", play_ctx())
    T.assert_eq(st.numerator, 0, "purple in hand resets after the hand")
    wipe_mods()
end)

suite.test("clips: green gains from scoring clips and loses from a discarded clip", function()
    local game = install_pack()
    local gr = card(3, "Hearts")
    local gst = set_clip(gr, "green_clip")
    setup_hand(game, { gr }, {})
    local p1, p2 = card(7, "Spades"), card(8, "Spades")
    set_clip(p1, "red_clip")
    set_clip(p2, "blue_clip")
    game.hand._play_sequence = { cards = { p1, p2 } }
    p1:emit_hand_event("card_played", play_ctx())
    T.assert_eq(gst.mult, 1, "2 scoring clips: +1 Mult banked")
    p1:emit_hand_event("on_discard", { discard_reason = "discard" })
    T.assert_eq(gst.mult, 0, "a discarded clip costs 5, floored at 0")
    wipe_mods()
end)

suite.test("clips: yellow rolls without error and platinum force-triggers other clips", function()
    local game = install_pack()
    local h = card(3, "Hearts")
    set_clip(h, "red_clip")
    local w = card(4, "Clubs")
    local wst = set_clip(w, "white_clip")
    wst.chips = 5
    setup_hand(game, { h, w }, {})
    local y = card(6, "Spades")
    set_clip(y, "yellow_clip")
    local yctx = play_ctx()
    y:emit_hand_event("card_played", yctx)
    T.assert_true(type(yctx.chips) == "number" and type(yctx.mult) == "number",
        "yellow's rolls resolve into the scoring totals")

    local pl = card(7, "Spades")
    set_clip(pl, "platinum_clip")
    setup_hand(game, { h }, {})
    game.hand._play_sequence = { cards = { pl, w } }
    local ctx = play_ctx()
    pl:emit_hand_event("card_played", ctx)
    T.assert_eq(ctx.chips, 5, "platinum triggered white's stored chips")
    T.assert_eq(ctx.mult, 6, "platinum triggered red's +5 per hand clip")
    local st = SMODS.mod_state("PaperbackPack")
    T.assert_eq(st.clip_round.scored, 3,
        "platinum's own score + yellow's + red's counted effect (white does not count)")
    wipe_mods()
end)

--------------------------------------------------------------------------------
-- The clip Jokers
--------------------------------------------------------------------------------

suite.test("clips: chip clip scales at round end and pays its chips", function()
    local game = install_pack()
    local j = add_joker(game, "j_pbp_chip_clip")
    local h1, h2 = card(3, "Hearts"), card(4, "Clubs")
    set_clip(h1, "white_clip")
    set_clip(h2, "gold_clip")
    setup_hand(game, { h1, h2 }, {})
    game:emit_joker_event("on_round_end", {})
    T.assert_eq(j.ability.extra.chips, 30, "+15 per clipped card held")
    local ctx = { event = "on_hand_scored", event_name = "on_hand_scored", chips = 0, mult = 1 }
    game:emit_joker_event("on_hand_scored", ctx)
    T.assert_eq(ctx.chips, 30, "joker_main pays the banked chips")
    wipe_mods()
end)

suite.test("clips: clippy clips a random unclipped card at blind select", function()
    local game = install_pack()
    add_joker(game, "j_pbp_clippy")
    local before = 0
    for _, d in ipairs(game.deck.cards) do
        if d.attachments then before = before + 1 end
    end
    game:emit_joker_event("on_blind_selected", {})
    local after = 0
    for _, d in ipairs(game.deck.cards) do
        if d.attachments and next(d.attachments) then after = after + 1 end
    end
    T.assert_eq(after, before + 1, "exactly one deck card gained a clip")
    wipe_mods()
end)

suite.test("clips: manilla folder pays $2 per unique clip in the full deck", function()
    local game = install_pack()
    add_joker(game, "j_pbp_manilla_folder")
    local h1, h2 = card(3, "Hearts"), card(4, "Clubs")
    set_clip(h1, "white_clip")
    set_clip(h2, "gold_clip")
    setup_hand(game, { h1, h2 }, {})
    local money = game.money
    game:emit_joker_event("on_round_end", {})
    T.assert_eq(game.money, money + 4, "2 unique clips: $4")
    wipe_mods()
end)

suite.test("clips: vacation juice drinks on new blind types and destroys itself", function()
    local game = install_pack()
    local j = add_joker(game, "j_pbp_vacation_juice")
    game.current_blind_index = 1
    game:emit_joker_event("on_round_end", {})
    T.assert_eq(j.ability.extra.drank_after, 1, "first Small clear: one sip")
    game.round = (game.round or 1) + 1
    game.current_blind_index = 1
    game:emit_joker_event("on_round_end", {})
    T.assert_eq(j.ability.extra.drank_after, 1, "same type again: no sip")
    game.round = (game.round or 1) + 1
    game.current_blind_index = 2
    game:emit_joker_event("on_round_end", {})
    local alive = false
    for _, held in ipairs(game.jokers) do if held == j then alive = true end end
    T.assert_true(not alive, "second new type: drank and destroyed")
    wipe_mods()
end)

--------------------------------------------------------------------------------
-- Persistence: clips and run state ride the run snapshot
--------------------------------------------------------------------------------

suite.test("clips: attachments and mod state survive a snapshot round-trip", function()
    local game = install_pack()
    local h1 = card(3, "Hearts")
    local st = set_clip(h1, "white_clip")
    st.chips = 42
    setup_hand(game, { h1 }, {})
    local ms = SMODS.mod_state("PaperbackPack")
    ms.test_marker = "wave7"
    local snap = game:build_run_snapshot()

    local game2 = install_pack()
    T.assert_true(game2:load_run_snapshot(snap))
    T.assert_eq(SMODS.mod_state("PaperbackPack").test_marker, "wave7",
        "run state restored")
    local found = nil
    for _, n in ipairs(game2.hand.card_nodes) do
        local s = clip_state(n, "white_clip")
        if s then found = s end
    end
    T.assert_true(found ~= nil and found.chips == 42,
        "the clip and its state ride the snapshot")
    wipe_mods()
end)

return suite
