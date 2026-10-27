--- Tests for the PaperbackPack Balatro3DS mod (not part of the game repo).
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

local NAMES = {
    "aurora_borealis", "bicycle", "emergency_broadcast", "find_jimbo",
    "guns_blazin", "insurance_policy", "malibu", "trust_us",
    "attacking_vertical", "better_call_jimbo", "calling_card", "claw",
    "giga_size", "grand_strategy", "jacks", "jestrica", "magic_mushroom",
    "mismatched_sock", "nazar", "planchette", "satellite_array", "technology",
    "toppins", "union_card", "the_quiet", "pocket_pair", "rosary_beads",
    "surfer", "the_girl_from_024", "tian_tian", "time_regression_mix",
    "57_leaf_clover", "unionized_labor", "park_postcard", "river", "langely",
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
    for _, n in ipairs(NAMES) do
        love.filesystem.write(base .. "/assets/1x/" .. n .. ".png", "png")
        love.filesystem.write(base .. "/assets/1x/" .. n .. "_negative.png", "png")
    end
    -- Dummy sprites for the Minor Arcana consumables (added with the
    -- arcana set; their behavior suite is test_paperbackpack_arcana.lua).
    for _, n in ipairs({
        "ace_of_pentacles", "ace_of_swords", "two_of_cups", "four_of_cups",
        "seven_of_cups", "eight_of_cups", "nine_of_cups", "ten_of_cups",
        "knight_of_cups", "king_of_cups", "two_of_wands", "three_of_wands",
        "five_of_wands", "eight_of_wands", "ten_of_wands", "king_of_wands",
        "four_of_swords", "five_of_swords", "nine_of_swords",
        "ten_of_swords", "knight_of_swords", "queen_of_swords",
        "king_of_swords", "two_of_pentacles", "three_of_pentacles",
        "four_of_pentacles", "six_of_cups", "six_of_pentacles",
        "eight_of_pentacles", "ten_of_pentacles", "queen_of_pentacles",
        "knight_of_pentacles", "king_of_pentacles",
        "five_of_cups", "five_of_pentacles", "queen_of_cups",
        "nine_of_wands", "knight_of_wands", "seven_of_wands",
        "queen_of_wands", "page_of_pentacles", "page_of_swords",
        "six_of_wands", "three_of_swords",
    }) do
        love.filesystem.write(base .. "/assets/1x/" .. n .. ".png", "png")
        love.filesystem.write(base .. "/assets/1x/" .. n .. "_negative.png", "png")
    end
    -- Dummy sprites for the 188 expansion Jokers (registered by the
    -- appended port sections; behavior suites live in
    -- test_paperbackpack_extra.lua).
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
    -- Dummy sprites for the Wave 1 (v1.2.0) Jokers and Two of Swords.
    for _, n in ipairs({
        "milk_tea", "stardrop", "stardrop_soul", "bergentrucking",
        "freedom_of_choice", "grenadine", "shinzaemon", "shinzaemon_soul",
        "nigori", "aperol", "pink_joker", "sacred_heart",
        "determination", "two_of_swords",
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
    local game = bootstrap.new_game(7721)
    -- A headless game has no hand or deck until a run starts them.
    game.hand = Hand(game)
    game.deck = Deck(game)
    G = game
    G.play = G.play or SMODS.PLAY
    _G.Top = _G.Top or { addPopup = function() end }
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

-- Drive the joker_main pipeline the way on_hand_scored does.
local function scored(joker, extra)
    local ctx = { event = "on_hand_scored", event_name = "on_hand_scored", chips = 10, mult = 2 }
    for k, v in pairs(extra or {}) do ctx[k] = v end
    ctx.cards = ctx.cards or ctx.played_cards
    if joker:matches_trigger(ctx.event_name, ctx) then joker:apply_effect(ctx) end
    return ctx
end

-- Drive a per-card scored context (card_played is the individual pipeline).
local function play_card(joker, node, played)
    local ctx = { event = "card_played", event_name = "card_played", chips = 0, mult = 1,
        rank = node.card_data.rank, suit = node.card_data.suit, card_node = node,
        played_cards = played, full_hand = played }
    if joker:matches_trigger("card_played", ctx) then joker:apply_effect(ctx) end
    return ctx
end

-- Drive the "before" pipeline (on_hand_played).
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

local function fake_deck(game, list)
    game.count_cards_in_full_deck = function(self, pred)
        local n = 0
        for _, c in ipairs(list) do
            if (not pred) or pred(c) then n = n + 1 end
        end
        return n
    end
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
-- Loading + tooltips
--------------------------------------------------------------------------------

suite.test("pack loads and registers all 296 Paperback Jokers", function()
    local game = install_pack()
    local mod = ModLoader.by_id.PaperbackPack
    T.assert_eq(mod.status, "loaded", tostring(mod.error))
    T.assert_eq(#mod.registered.jokers, 296)
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
    }
    for id, e in pairs(expect) do
        local def = JOKER_DEFS[id]
        T.assert_true(def ~= nil, id .. " registered")
        T.assert_eq(def.name, e[1], id .. " name")
        T.assert_eq(def.rarity, e[2], id .. " rarity")
        T.assert_eq(def.cost, e[3], id .. " cost")
    end
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
-- Per-card scored effects
--------------------------------------------------------------------------------

suite.test("emergency broadcast: scored 5s and 8s give +5 Mult and +8 Chips", function()
    local game = install_pack()
    local j = add(game, "j_pbp_emergency_broadcast")
    local five = card(5, "Clubs")
    local ctx = play_card(j, five, { five })
    T.assert_eq(ctx.mult, 6)
    T.assert_eq(ctx.chips, 8)
    local eight = card(8, "Spades")
    ctx = play_card(j, eight, { eight })
    T.assert_eq(ctx.mult, 6)
    local seven = card(7, "Hearts")
    ctx = play_card(j, seven, { seven })
    T.assert_eq(ctx.mult, 1)
    T.assert_eq(ctx.chips, 0)
    wipe_mods()
end)

suite.test("bicycle: a scored Wild card gives Mult equal to its Chip value", function()
    local game = install_pack()
    local j = add(game, "j_pbp_bicycle")
    local wild_q = card(12, "Hearts", "wild")
    local ctx = play_card(j, wild_q, { wild_q })
    T.assert_eq(ctx.mult, 11, "Queen is worth 10 Chips of Mult")
    local plain_q = card(12, "Hearts")
    ctx = play_card(j, plain_q, { plain_q })
    T.assert_eq(ctx.mult, 1, "a plain Queen gives nothing")
    wipe_mods()
end)

suite.test("guns blazin: played Aces give X1.5 Mult", function()
    local game = install_pack()
    local j = add(game, "j_pbp_guns_blazin")
    local ace = card(14, "Spades")
    local ctx = play_card(j, ace, { ace })
    T.assert_eq(ctx.mult, 1.5)
    local king = card(13, "Spades")
    ctx = play_card(j, king, { king })
    T.assert_eq(ctx.mult, 1)
    wipe_mods()
end)

suite.test("claw: scored 3s grow by 2 and reset at round end", function()
    local game = install_pack()
    local j = add(game, "j_pbp_claw")
    local three = card(3, "Clubs")
    local ctx = play_card(j, three, { three })
    T.assert_eq(ctx.mult, 4, "first 3 gives +3")
    T.assert_eq(j.ability.extra.mult, 5)
    ctx = play_card(j, three, { three })
    T.assert_eq(ctx.mult, 6, "second 3 gives +5")
    fire(j, "on_round_end", {})
    T.assert_eq(j.ability.extra.mult, 3, "resets after the round")
    wipe_mods()
end)

suite.test("toppins: each scored card pays the growing Mult, resets after the hand", function()
    local game = install_pack()
    local j = add(game, "j_pbp_toppins")
    local a, b = card(4, "Clubs"), card(9, "Diamonds")
    local ctx = play_card(j, a, { a, b })
    T.assert_eq(ctx.mult, 3, "first card gives +2")
    ctx = play_card(j, b, { a, b })
    T.assert_eq(ctx.mult, 5, "second card gives +4")
    fire(j, "on_hand_after", {})
    T.assert_eq(j.ability.extra.mult, 2, "reset to +2 after the hand")
    wipe_mods()
end)

suite.test("jestrica: scored 8s grow it, a round without one resets it", function()
    local game = install_pack()
    local j = add(game, "j_pbp_jestrica")
    local eight = card(8, "Hearts")
    play_card(j, eight, { eight })
    T.assert_eq(j.ability.extra.mult, 1)
    local ctx = scored(j, {})
    T.assert_eq(ctx.mult, 3, "joker_main pays the grown Mult")
    fire(j, "on_round_end", {})
    T.assert_eq(j.ability.extra.mult, 1, "kept: an 8 was scored this round")
    fire(j, "on_round_end", {})
    T.assert_eq(j.ability.extra.mult, 0, "reset: no 8 scored in the new round")
    wipe_mods()
end)

suite.test("jacks: discarding a Jack grows its Mult", function()
    local game = install_pack()
    local j = add(game, "j_pbp_jacks")
    local jack = card(11, "Spades")
    fire(j, "on_discard", { card_node = jack })
    T.assert_eq(j.ability.extra.mult, 1)
    local queen = card(12, "Spades")
    fire(j, "on_discard", { card_node = queen })
    T.assert_eq(j.ability.extra.mult, 1, "Queens do not count")
    local ctx = scored(j, {})
    T.assert_eq(ctx.mult, 3)
    wipe_mods()
end)

--------------------------------------------------------------------------------
-- joker_main readers and scalers
--------------------------------------------------------------------------------

suite.test("trust us: X3 with a Three of a Kind inside, X0.5 without", function()
    local game = install_pack()
    local j = add(game, "j_pbp_trust_us")
    local ctx = scored(j, { contains_hand_types = { ["Three of a Kind"] = true } })
    T.assert_eq(ctx.mult, 6)
    ctx = scored(j, {})
    T.assert_eq(ctx.mult, 1)
    wipe_mods()
end)

suite.test("aurora borealis: X0.5 per editioned Joker held, Negatives excluded", function()
    local game = install_pack()
    local j = add(game, "j_pbp_aurora_borealis")
    local other = add(game, "j_pbp_bicycle")
    local ctx = scored(j, {})
    T.assert_eq(ctx.mult, 2, "no editions yet: X1, no return")
    other.edition = "foil"
    ctx = scored(j, {})
    T.assert_eq(ctx.mult, 3, "one Foil Joker: X1.5")
    other.edition = "negative"
    ctx = scored(j, {})
    T.assert_eq(ctx.mult, 2, "Negative does not count")
    wipe_mods()
end)

suite.test("better call jimbo: X0.1 per $4 owned", function()
    local game = install_pack()
    local j = add(game, "j_pbp_better_call_jimbo")
    game.money = 40
    local ctx = scored(j, {})
    T.assert_eq(ctx.mult, 4, "X2 at $40")
    game.money = 3
    ctx = scored(j, {})
    T.assert_eq(ctx.mult, 2, "no full $4: X1, no return")
    wipe_mods()
end)

suite.test("insurance policy: +5 per Jack, -5 per King in the full deck", function()
    local game = install_pack()
    local j = add(game, "j_pbp_insurance_policy")
    fake_deck(game, {
        { rank = 11, suit = "Hearts" }, { rank = 11, suit = "Clubs" },
        { rank = 13, suit = "Spades" }, { rank = 4, suit = "Diamonds" },
    })
    local ctx = scored(j, {})
    T.assert_eq(ctx.mult, 7, "two Jacks and one King: +5")
    fake_deck(game, {
        { rank = 11, suit = "Hearts" }, { rank = 13, suit = "Spades" },
    })
    ctx = scored(j, {})
    T.assert_eq(ctx.mult, 2, "one each cancels out")
    wipe_mods()
end)

suite.test("grand strategy: X4 with 7 distinct enhancements in the full deck", function()
    local game = install_pack()
    local j = add(game, "j_pbp_grand_strategy")
    local deck = {}
    for i, e in ipairs({ "bonus", "mult", "wild", "glass", "steel", "stone", "gold" }) do
        deck[i] = { rank = 5, suit = "Hearts", enhancement = e }
    end
    fake_deck(game, deck)
    local ctx = scored(j, {})
    T.assert_eq(ctx.mult, 8, "X4 with all 7")
    deck[7] = { rank = 5, suit = "Hearts", enhancement = "gold" }
    deck[6] = { rank = 5, suit = "Hearts", enhancement = "gold" }
    fake_deck(game, deck)
    ctx = scored(j, {})
    T.assert_eq(ctx.mult, 2, "only 6 distinct: nothing")
    wipe_mods()
end)

suite.test("the quiet: X0.1 per card below 52 in the full deck", function()
    local game = install_pack()
    local j = add(game, "j_pbp_the_quiet")
    local deck = {}
    for i = 1, 47 do deck[i] = { rank = 5, suit = "Hearts" } end
    fake_deck(game, deck)
    local ctx = scored(j, {})
    T.assert_eq(ctx.mult, 3, "5 cards below 52: X1.5")
    wipe_mods()
end)

suite.test("malibu: Chips are 10x the lowest Chip value in the scored hand", function()
    local game = install_pack()
    local j = add(game, "j_pbp_malibu")
    local played = { card(3, "Clubs"), card(13, "Spades"), card(9, "Hearts") }
    local ctx = scored(j, { played_cards = played })
    T.assert_eq(ctx.chips, 40, "lowest card is the 3: +30 Chips")
    wipe_mods()
end)

suite.test("union card: XMult equals the number of scoring light suit cards", function()
    local game = install_pack()
    local j = add(game, "j_pbp_union_card")
    local played = { card(5, "Hearts"), card(9, "Diamonds"), card(2, "Spades") }
    local ctx = scored(j, { played_cards = played })
    T.assert_eq(ctx.mult, 4, "two light cards: X2")
    ctx = scored(j, { played_cards = { card(5, "Hearts"), card(2, "Spades") } })
    T.assert_eq(ctx.mult, 2, "a single light card is not enough")
    wipe_mods()
end)

suite.test("rosary beads: $5 when 3 or more Hearts score (Wild counts)", function()
    local game = install_pack()
    local j = add(game, "j_pbp_rosary_beads")
    local money = game.money
    local played = { card(5, "Hearts"), card(9, "Hearts"), card(2, "Clubs", "wild"), card(4, "Spades") }
    scored(j, { played_cards = played })
    T.assert_eq(game.money, money + 5, "two Hearts plus a Wild make three")
    scored(j, { played_cards = { card(5, "Hearts"), card(4, "Spades") } })
    T.assert_eq(game.money, money + 5, "two Hearts alone pay nothing")
    wipe_mods()
end)

suite.test("giga size: gains X1 per hand played in the Blind, resets at round end", function()
    local game = install_pack()
    local j = add(game, "j_pbp_giga_size")
    before(j, {})
    T.assert_eq(j.ability.extra.xm, 2)
    local ctx = scored(j, {})
    T.assert_eq(ctx.mult, 4, "X2 after the first hand")
    fire(j, "on_round_end", {})
    T.assert_eq(j.ability.extra.xm, 1)
    wipe_mods()
end)

suite.test("magic mushroom: X3 decays by X0.5 per hand and resets when a Blind falls", function()
    local game = install_pack()
    local j = add(game, "j_pbp_magic_mushroom")
    local ctx = scored(j, {})
    T.assert_eq(ctx.mult, 6, "X3 fresh")
    fire(j, "on_hand_after", {})
    T.assert_eq(j.ability.extra.xm, 2.5)
    fire(j, "on_hand_after", {})
    T.assert_eq(j.ability.extra.xm, 2)
    fire(j, "on_blind_defeated", {})
    T.assert_eq(j.ability.extra.xm, 3, "reset on Blind defeated")
    wipe_mods()
end)

suite.test("calling card: only Boss defeats grow it", function()
    local game = install_pack()
    local j = add(game, "j_pbp_calling_card")
    fire(j, "on_blind_defeated", { blind_index = 2 })
    T.assert_eq(j.ability.extra.xm, 1, "Big Blind does not scale it")
    fire(j, "on_blind_defeated", { blind_index = 3 })
    T.assert_eq(j.ability.extra.xm, 1.25, "Boss Blind scales it")
    local ctx = scored(j, {})
    T.assert_eq(ctx.mult, 2.5)
    wipe_mods()
end)

suite.test("attacking vertical: scored 9s and 5s pay its XMult, Bosses grow it", function()
    local game = install_pack()
    local j = add(game, "j_pbp_attacking_vertical")
    local nine = card(9, "Clubs")
    local ctx = play_card(j, nine, { nine })
    T.assert_eq(ctx.mult, 1.25)
    fire(j, "on_blind_defeated", { blind_index = 3 })
    T.assert_eq(j.ability.extra.xm, 1.5)
    wipe_mods()
end)

suite.test("mismatched sock: single-card discards grow it, a Pair resets it", function()
    local game = install_pack()
    local j = add(game, "j_pbp_mismatched_sock")
    local one = { card(4, "Clubs") }
    fire(j, "on_pre_discard", { discarded_nodes = one })
    T.assert_eq(j.ability.extra.xm, 1.1)
    fire(j, "on_pre_discard", { discarded_nodes = { card(4, "Clubs"), card(6, "Clubs") } })
    T.assert_eq(j.ability.extra.xm, 1.1, "two-card discards do not count")
    before(j, { contains_hand_types = { Pair = true }, played_cards = one })
    T.assert_eq(j.ability.extra.xm, 1, "a played Pair resets it to X1")
    wipe_mods()
end)

suite.test("technology: scoring Mult cards grow it for the round", function()
    local game = install_pack()
    local j = add(game, "j_pbp_technology")
    local played = { card(5, "Hearts", "mult"), card(9, "Clubs", "mult"), card(2, "Spades") }
    before(j, { played_cards = played })
    T.assert_eq(j.ability.extra.xm, 2, "two Mult cards: +X1")
    local ctx = scored(j, {})
    T.assert_eq(ctx.mult, 4)
    fire(j, "on_round_end", {})
    T.assert_eq(j.ability.extra.xm, 1)
    wipe_mods()
end)

suite.test("time regression mix: hands with 4 suits grow its Mult", function()
    local game = install_pack()
    local j = add(game, "j_pbp_time_regression_mix")
    local played = { card(5, "Hearts"), card(9, "Clubs"), card(2, "Spades"), card(12, "Diamonds") }
    before(j, { played_cards = played })
    T.assert_eq(j.ability.extra.mult, 2)
    local ctx = scored(j, {})
    T.assert_eq(ctx.mult, 4)
    before(j, { played_cards = { card(5, "Hearts"), card(9, "Hearts") } })
    T.assert_eq(j.ability.extra.mult, 2, "three suits are not enough")
    wipe_mods()
end)

--------------------------------------------------------------------------------
-- Consumable watchers
--------------------------------------------------------------------------------

suite.test("nazar: gains +8 Chips when a Tarot or Minor Arcana is used", function()
    local game = install_pack()
    local j = add(game, "j_pbp_nazar")
    fire(j, "on_consumable_used", { consumable_kind = "planet" })
    T.assert_eq(j.ability.extra.chips, 0)
    fire(j, "on_consumable_used", { consumable_kind = "tarot" })
    T.assert_eq(j.ability.extra.chips, 8)
    fire(j, "on_consumable_used", { consumable_kind = "minor_arcana" })
    T.assert_eq(j.ability.extra.chips, 16)
    local ctx = scored(j, {})
    T.assert_eq(ctx.chips, 26)
    wipe_mods()
end)

suite.test("planchette: gains X0.25 when a Spectral is used", function()
    local game = install_pack()
    local j = add(game, "j_pbp_planchette")
    fire(j, "on_consumable_used", { consumable_kind = "tarot" })
    T.assert_eq(j.ability.extra.xm, 1)
    fire(j, "on_consumable_used", { consumable_kind = "spectral" })
    T.assert_eq(j.ability.extra.xm, 1.25)
    local ctx = scored(j, {})
    T.assert_eq(ctx.mult, 2.5)
    wipe_mods()
end)

suite.test("satellite array: Planets charge it, hands drain it below zero", function()
    local game = install_pack()
    local j = add(game, "j_pbp_satellite_array")
    fire(j, "on_consumable_used", { consumable_kind = "planet" })
    T.assert_eq(j.ability.extra.chips, 15)
    fire(j, "on_hand_after", {})
    T.assert_eq(j.ability.extra.chips, 10)
    fire(j, "on_hand_after", {})
    fire(j, "on_hand_after", {})
    fire(j, "on_hand_after", {})
    T.assert_eq(j.ability.extra.chips, -5, "the stored value may go negative")
    local ctx = scored(j, {})
    T.assert_eq(ctx.chips, 10, "but a negative value pays nothing")
    fire(j, "on_consumable_used", { consumable_kind = "planet" })
    T.assert_eq(j.ability.extra.chips, 10, "Planets rebuild from below zero")
    ctx = scored(j, {})
    T.assert_eq(ctx.chips, 20)
    wipe_mods()
end)

--------------------------------------------------------------------------------
-- Round-end and deck watchers
--------------------------------------------------------------------------------

suite.test("find jimbo: target re-rolls each round from an actual deck card", function()
    local game = install_pack()
    local j = add(game, "j_pbp_find_jimbo")
    game.deck.cards = { { rank = 9, suit = "Hearts" } }
    game.deck.discard_pile = {}
    fire(j, "on_round_end", {})
    T.assert_eq(j.ability.extra.target_rank, 9)
    T.assert_eq(j.ability.extra.target_suit, "Hearts")
    local money = game.money
    local nine_h = card(9, "Hearts")
    play_card(j, nine_h, { nine_h })
    T.assert_eq(game.money, money + 5, "the target card pays $5 when scored")
    local nine_s = card(9, "Spades")
    play_card(j, nine_s, { nine_s })
    T.assert_eq(game.money, money + 5, "the wrong suit pays nothing")
    wipe_mods()
end)

suite.test("pocket pair: $3 when the opening hand is dealt with a Pair", function()
    local game = install_pack()
    local j = add(game, "j_pbp_pocket_pair")
    if not game.hand then game.hand = Hand(game) end
    game.hand.card_nodes = { card(7, "Clubs"), card(7, "Diamonds"), card(3, "Spades") }
    local money = game.money
    fire(j, "on_round_begin", {})
    T.assert_eq(game.money, money + 3)
    game.hand.card_nodes = { card(7, "Clubs"), card(9, "Diamonds"), card(3, "Spades") }
    fire(j, "on_round_begin", {})
    T.assert_eq(game.money, money + 3, "no Pair, no pay")
    wipe_mods()
end)

suite.test("surfer: gains +10 Chips per 10 held at round end", function()
    local game = install_pack()
    local j = add(game, "j_pbp_surfer")
    if not game.hand then game.hand = Hand(game) end
    game.hand.card_nodes = { card(10, "Clubs"), card(10, "Diamonds"), card(3, "Spades") }
    fire(j, "on_round_end", {})
    T.assert_eq(j.ability.extra.chips, 20)
    local ctx = scored(j, {})
    T.assert_eq(ctx.chips, 30)
    wipe_mods()
end)

suite.test("the girl from 024: gains X0.2 per Queen held at round end", function()
    local game = install_pack()
    local j = add(game, "j_pbp_the_girl_from_024")
    if not game.hand then game.hand = Hand(game) end
    game.hand.card_nodes = { card(12, "Clubs"), card(12, "Diamonds"), card(3, "Spades") }
    fire(j, "on_round_end", {})
    T.assert_eq(j.ability.extra.xm, 1.4)
    wipe_mods()
end)

suite.test("tian tian: gains X0.1 per destroyed playing card", function()
    local game = install_pack()
    local j = add(game, "j_pbp_tian_tian")
    fire(j, "on_destroy", { destroyed_cards = { {}, {} } })
    T.assert_eq(j.ability.extra.xm, 1.2)
    fire(j, "on_destroy", { destroyed_cards = {} })
    T.assert_eq(j.ability.extra.xm, 1.2, "an empty removal does nothing")
    wipe_mods()
end)

suite.test("park postcard: grows at round end, resets when the deck changes", function()
    local game = install_pack()
    local j = add(game, "j_pbp_park_postcard")
    fire(j, "on_round_end", {})
    T.assert_eq(j.ability.extra.xm, 1.2)
    fire(j, "on_cards_added_to_deck", {})
    T.assert_eq(j.ability.extra.xm, 1, "a card added resets it")
    fire(j, "on_round_end", {})
    T.assert_eq(j.ability.extra.xm, 1.2)
    fire(j, "on_destroy", { destroyed_cards = { {} } })
    T.assert_eq(j.ability.extra.xm, 1, "a card removed resets it")
    wipe_mods()
end)

suite.test("river: earns half the lowest scoring card's Chips, capped at $11", function()
    local game = install_pack()
    local j = add(game, "j_pbp_river")
    local played = {
        card(3, "Clubs"), card(13, "Spades"), card(12, "Hearts"),
        card(11, "Diamonds"), card(9, "Clubs"),
    }
    local money = game.money
    before(j, { played_cards = played })
    T.assert_eq(game.money, money + 2, "lowest is the 3: ceil(3/2) = $2")
    local rich = {
        card(14, "Clubs", "bonus"), card(13, "Spades", "bonus"),
        card(12, "Hearts", "bonus"), card(11, "Diamonds", "bonus"),
        card(13, "Clubs", "bonus"),
    }
    before(j, { played_cards = rich })
    T.assert_eq(game.money, money + 2 + 11, "Bonus cards push it to the $11 cap")
    before(j, { played_cards = { card(3, "Clubs") } })
    T.assert_eq(game.money, money + 2 + 11, "fewer than 5 scoring cards pay nothing")
    wipe_mods()
end)

suite.test("langely: full sell value on Boss, half (ceil) on Big, nothing on Small", function()
    local game = install_pack()
    local j = add(game, "j_pbp_langely")
    add(game, "j_pbp_claw")       -- cost 3, sell 1
    add(game, "j_pbp_river")      -- cost 7, sell 3
    -- Langely itself sells for 10: total sell value 1 + 3 + 10 = 14.
    local paid = nil
    local function cash_out(idx)
        paid = nil
        game.current_blind_index = idx
        fire(j, "on_round_end", {
            add_round_win_payout = function(label, n) paid = n end,
        })
        return paid
    end
    T.assert_eq(cash_out(3), 14, "Boss: the full sell value of all Jokers")
    T.assert_eq(cash_out(2), 7, "Big: half, rounded up")
    T.assert_eq(cash_out(1), nil, "Small: nothing")
    wipe_mods()
end)

--------------------------------------------------------------------------------
-- Probability Jokers
--------------------------------------------------------------------------------

suite.test("57 leaf clover: +1 to all probabilities per non-Boss round, resets at Boss", function()
    local game = install_pack()
    local j = add(game, "j_pbp_57_leaf_clover")
    local num = SMODS.get_probability_vars(nil, 1, 4)
    T.assert_eq(num, 2, "starts at +1")
    game.current_blind_index = 1
    fire(j, "on_round_end", {})
    T.assert_eq(j.ability.extra.current, 2)
    num = SMODS.get_probability_vars(nil, 1, 4)
    T.assert_eq(num, 3, "now +2")
    game.current_blind_index = 3
    fire(j, "on_round_end", {})
    T.assert_eq(j.ability.extra.current, 1, "a Boss round resets it")
    wipe_mods()
end)

suite.test("unionized labor: triples probabilities at $25 or less, halves them above", function()
    local game = install_pack()
    add(game, "j_pbp_unionized_labor")
    game.money = 25
    local num, den = SMODS.get_probability_vars(nil, 1, 4)
    T.assert_eq(num, 3)
    T.assert_eq(den, 4)
    game.money = 26
    num, den = SMODS.get_probability_vars(nil, 1, 4)
    T.assert_eq(num, 1)
    T.assert_eq(den, 8)
    wipe_mods()
end)

--------------------------------------------------------------------------------
-- Suits and Spectrum hands
--------------------------------------------------------------------------------

suite.test("stars and crowns register as suits", function()
    local game = install_pack()
    T.assert_true(SMODS.Suits["Stars"] ~= nil, "Stars registered")
    T.assert_true(SMODS.Suits["Crowns"] ~= nil, "Crowns registered")
    local c = SMODS.add_card { set = "Playing", rank = 7, suit = "Stars" }
    T.assert_true(c ~= nil, "a Stars card can be created")
    wipe_mods()
end)

local function classify(game, nodes)
    local h = Hand(game)
    h.card_nodes, h.selected = {}, {}
    for _, nd in ipairs(nodes) do
        h.card_nodes[#h.card_nodes + 1] = nd
        h.selected[#h.selected + 1] = nd
    end
    h:calculate_play()
    return G.handlist and G.handlist[G.selectedHand]
end

suite.test("spectrum family classifies through the game's own evaluation", function()
    local game = install_pack()
    local spectrum = {
        card(2, "Hearts"), card(5, "Diamonds"), card(7, "Clubs"),
        card(9, "Spades"), card(13, "Stars"),
    }
    T.assert_eq(classify(game, spectrum), "Spectrum")
    local straight = {
        card(8, "Hearts"), card(9, "Diamonds"), card(10, "Clubs"),
        card(11, "Spades"), card(12, "Crowns"),
    }
    T.assert_eq(classify(game, straight), "Straight Spectrum")
    local house = {
        card(12, "Hearts"), card(12, "Stars"), card(12, "Clubs"),
        card(8, "Diamonds"), card(8, "Spades"),
    }
    T.assert_eq(classify(game, house), "Spectrum House")
    local five = {
        card(7, "Hearts"), card(7, "Diamonds"), card(7, "Clubs"),
        card(7, "Spades"), card(7, "Stars"),
    }
    T.assert_eq(classify(game, five), "Spectrum Five")
    local flush = {
        card(2, "Stars"), card(5, "Stars"), card(7, "Stars"),
        card(9, "Stars"), card(13, "Stars"),
    }
    T.assert_eq(classify(game, flush), "Flush", "five Stars still make a Flush")
    local plain = {
        card(2, "Hearts"), card(5, "Hearts"), card(7, "Clubs"),
        card(9, "Spades"), card(13, "Diamonds"),
    }
    T.assert_eq(classify(game, plain), "High Card", "a repeated suit is no Spectrum")
    wipe_mods()
end)

suite.test("spectrum stats are Paperback's values", function()
    local game = install_pack()
    local idx
    for i, name in ipairs(game.handlist) do
        if name == "Spectrum" then idx = i end
    end
    T.assert_true(idx ~= nil, "Spectrum is in the hand list")
    local stats = game.hand_stats[idx]
    T.assert_eq(stats.base_chips, 50)
    T.assert_eq(stats.base_mult, 6)
    wipe_mods()
end)

suite.test("exotic suits stay out of random fronts until a Spectrum is played or one is in the deck", function()
    local game = install_pack()
    local fronts = SMODS.extra_playing_card_fronts(game)
    T.assert_eq(#fronts, 0, "no exotic fronts in a fresh run")
    -- Route 1: a Spectrum-family hand scored this run.
    local sidx
    for i, name in ipairs(game.handlist) do
        if name == "Spectrum" then sidx = i end
    end
    game.hand_play_counts[sidx] = 1
    fronts = SMODS.extra_playing_card_fronts(game)
    T.assert_eq(#fronts, 26, "both suits, one front per rank")
    game.hand_play_counts[sidx] = 0
    fronts = SMODS.extra_playing_card_fronts(game)
    T.assert_eq(#fronts, 0, "gate closes again")
    -- Route 2: an exotic card already in the deck opens only its own suit.
    SMODS.add_card { set = "Playing", rank = 5, suit = "Stars", area = "deck" }
    fronts = SMODS.extra_playing_card_fronts(game)
    T.assert_eq(#fronts, 13, "Stars only")
    wipe_mods()
end)

return suite
