--- Tests for the PaperbackPack Minor Arcana set (not part of the game repo).
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
-- Registration
--------------------------------------------------------------------------------

suite.test("minor arcana type and all 45 cards register", function()
    local game = install_pack()
    local mod = ModLoader.by_id.PaperbackPack
    T.assert_eq(mod.status, "loaded", tostring(mod.error))
    T.assert_eq(#mod.registered.consumables, 56, "56 arcana register")
    local entry = SMODS.ConsumableTypes["pbp_minor_arcana"]
    T.assert_true(entry ~= nil, "the minor_arcana type registers")
    T.assert_eq(entry.kind, "minor_arcana", "the kind string is minor_arcana")
    T.assert_eq(entry.shop_rate, 0, "shop_rate 0, as on PC (booster-delivered)")
    T.assert_true(game:is_consumable_kind("minor_arcana"))
    for key, name in pairs(ARCANA) do
        local def = CONSUMABLE_DEFS["c_pbp_" .. key]
        T.assert_true(def ~= nil, key .. " registered")
        T.assert_eq(def.kind, "minor_arcana", key .. " kind")
        T.assert_eq(def.name, name, key .. " name")
        T.assert_eq(def.cost, 3, key .. " cost")
        local lines = SMODS.tooltip_lines("c_pbp_" .. key, def)
        T.assert_true(type(lines) == "table" and #lines >= 1,
            key .. " tooltip has lines")
        local text = table.concat(flatten(lines), " ")
        T.assert_true(text:find("#", 1, true) == nil,
            key .. " tooltip has no raw placeholder: " .. text)
        T.assert_true(text:find("function:", 1, true) == nil,
            key .. " tooltip has no raw function: " .. text)
    end
    wipe_mods()
end)

--------------------------------------------------------------------------------
-- Declarative conversions
--------------------------------------------------------------------------------

suite.test("ace of pentacles converts selected cards to Stars", function()
    local game = install_pack()
    local a, b = card(5, "Hearts"), card(9, "Clubs")
    setup_hand(game, { a, b }, { a, b })
    local slot = hold(game, "ace_of_pentacles")
    T.assert_true(game:consumable_use_enabled(slot))
    T.assert_true(game:use_consumable(slot))
    T.assert_eq(a.card_data.suit, "Stars")
    T.assert_eq(b.card_data.suit, "Stars")
    wipe_mods()
end)

suite.test("ace of swords converts selected cards to Crowns", function()
    local game = install_pack()
    local a = card(5, "Hearts")
    setup_hand(game, { a }, { a })
    local slot = hold(game, "ace_of_swords")
    T.assert_true(game:use_consumable(slot))
    T.assert_eq(a.card_data.suit, "Crowns")
    wipe_mods()
end)

--------------------------------------------------------------------------------
-- Cups
--------------------------------------------------------------------------------

suite.test("two of cups grants a random edition or rarity tag", function()
    local game = install_pack()
    game.STATE = game.STATES.SHOP
    local before = #game.tags
    local slot = hold(game, "two_of_cups")
    T.assert_true(game:use_consumable(slot))
    T.assert_eq(#game.tags, before + 1, "one tag was granted")
    wipe_mods()
end)

suite.test("four of cups strips modifiers and pays $5 per removal", function()
    local game = install_pack()
    local a = card(5, "Hearts", "bonus")
    a.card_data.seal = "red"
    a.card_data.edition = "foil"
    local plain = card(9, "Clubs")
    setup_hand(game, { a, plain }, { a, plain })
    local slot = hold(game, "four_of_cups")
    local money = game.money
    T.assert_true(game:use_consumable(slot))
    T.assert_eq(a.card_data.enhancement, nil, "enhancement removed")
    T.assert_eq(a.card_data.seal, nil, "seal removed")
    T.assert_eq(a.card_data.edition, nil, "edition removed")
    T.assert_eq(game.money, money + 15, "3 removals at $5")
    wipe_mods()
end)

suite.test("seven of cups gives each selected card a random enhancement", function()
    local game = install_pack()
    local a, b = card(5, "Hearts"), card(9, "Clubs")
    setup_hand(game, { a, b }, { a, b })
    local slot = hold(game, "seven_of_cups")
    T.assert_true(game:use_consumable(slot))
    T.assert_true(a.card_data.enhancement ~= nil, "first card enhanced")
    T.assert_true(b.card_data.enhancement ~= nil, "second card enhanced")
    wipe_mods()
end)

suite.test("eight of cups moves selected cards to an unselected deck suit", function()
    local game = install_pack()
    local a, b = card(5, "Hearts"), card(9, "Clubs")
    setup_hand(game, { a, b }, { a, b })
    local slot = hold(game, "eight_of_cups")
    T.assert_true(game:use_consumable(slot))
    local s = a.card_data.suit
    T.assert_true(s == "Spades" or s == "Diamonds",
        "new suit is neither highlighted suit: " .. tostring(s))
    T.assert_eq(b.card_data.suit, s, "both cards take the same new suit")
    wipe_mods()
end)

suite.test("nine of cups destroys the chosen Common Joker and creates an Uncommon one", function()
    local game = install_pack()
    game.STATE = game.STATES.SHOP
    local target = add_joker(game, "j_pbp_claw") -- Common, cost 3
    local slot = hold(game, "nine_of_cups")
    T.assert_true(game:use_consumable(slot, target))
    T.assert_eq(#game.jokers, 1, "one Joker before and after")
    local j = game.jokers[1]
    local def = JOKER_DEFS[j.def.id]
    T.assert_eq(def.rarity, 2, "the replacement is Uncommon")
    wipe_mods()
end)

suite.test("ten of cups can add Polychrome to an uneditioned selected card", function()
    local game = install_pack()
    local a = card(5, "Hearts")
    setup_hand(game, { a }, { a })
    local slot = hold(game, "ten_of_cups")
    T.assert_true(game:consumable_use_enabled(slot),
        "usable on an uneditioned card")
    local hit = false
    for _ = 1, 80 do
        a.card_data.edition = nil
        setup_hand(game, { a }, { a })
        game.consumables, game.consumable_nodes = {}, {}
        slot = hold(game, "ten_of_cups")
        T.assert_true(game:use_consumable(slot))
        if a.card_data.edition == "polychrome" then hit = true break end
    end
    T.assert_true(hit, "the 1 in 3 roll lands within 80 tries")
    wipe_mods()
end)

suite.test("knight of cups copies the right card onto the left and destroys the right", function()
    local game = install_pack()
    local left, right = card(5, "Hearts"), card(9, "Clubs", "gold")
    right.card_data.seal = "blue"
    setup_hand(game, { left, right }, { left, right })
    local slot = hold(game, "knight_of_cups")
    T.assert_true(game:use_consumable(slot))
    T.assert_eq(left.card_data.enhancement, "gold", "enhancement copied")
    T.assert_eq(left.card_data.seal, "blue", "seal copied")
    T.assert_eq(left.card_data.rank, 5, "rank is not copied")
    T.assert_eq(left.card_data.suit, "Hearts", "suit is not copied")
    local still = false
    for _, n in ipairs(game.hand.card_nodes) do
        if n == right then still = true end
    end
    T.assert_false(still, "the right card was destroyed")
    wipe_mods()
end)

suite.test("king of cups pays $5 per complete suit in the full deck", function()
    local game = install_pack()
    game.STATE = game.STATES.SHOP
    local deck = {}
    for r = 2, 14 do deck[#deck + 1] = { rank = r, suit = "Hearts" } end
    deck[#deck + 1] = { rank = 4, suit = "Spades" }
    game.deck.cards = deck
    local slot = hold(game, "king_of_cups")
    local money = game.money
    T.assert_true(game:use_consumable(slot))
    T.assert_eq(game.money, money + 5, "one complete suit pays $5")
    wipe_mods()
end)

suite.test("six of cups pays half the selected card's Chip value, capped at $30", function()
    local game = install_pack()
    local king = card(13, "Hearts")
    setup_hand(game, { king }, { king })
    local slot = hold(game, "six_of_cups")
    local money = game.money
    T.assert_true(game:use_consumable(slot))
    T.assert_eq(game.money, money + 5, "King is worth 10 Chips: $5")
    wipe_mods()
end)

--------------------------------------------------------------------------------
-- Wands
--------------------------------------------------------------------------------

suite.test("two of wands creates Planets for the most and least played hands", function()
    local game = install_pack()
    game.STATE = game.STATES.SHOP
    for i, name in ipairs(game.handlist) do
        game.hand_play_counts[i] = name == "Flush" and 9 or 0
    end
    local slot = hold(game, "two_of_wands")
    T.assert_true(game:use_consumable(slot))
    T.assert_eq(#game.consumables, 2, "two Planet cards were created")
    for _, c in ipairs(game.consumables) do
        T.assert_eq(c.kind, "planet", "created cards are Planets")
    end
    wipe_mods()
end)

suite.test("three of wands copies the selected card into the hand", function()
    local game = install_pack()
    local a = card(12, "Diamonds", "steel")
    setup_hand(game, { a }, { a })
    local before = #game.hand.card_nodes
    local slot = hold(game, "three_of_wands")
    T.assert_true(game:use_consumable(slot))
    T.assert_eq(#game.hand.card_nodes, before + 1, "a copy joined the hand")
    local copy = game.hand.card_nodes[#game.hand.card_nodes]
    T.assert_eq(copy.card_data.rank, 12)
    T.assert_eq(copy.card_data.suit, "Diamonds")
    T.assert_eq(copy.card_data.enhancement, "steel")
    wipe_mods()
end)

suite.test("five of wands destroys the whole hand and zeroes the money", function()
    local game = install_pack()
    local a, b = card(5, "Hearts"), card(9, "Clubs")
    setup_hand(game, { a, b }, {})
    game.money = 20
    local slot = hold(game, "five_of_wands")
    T.assert_true(game:consumable_use_enabled(slot))
    T.assert_true(game:use_consumable(slot))
    T.assert_eq(#game.hand.card_nodes, 0, "the hand is gone")
    T.assert_eq(game.money, 0, "money set to $0")
    wipe_mods()
end)

suite.test("eight of wands grants a Negative Tag and charges the base cost", function()
    local game = install_pack()
    game.STATE = game.STATES.SHOP
    game.money = 100
    local tags = #game.tags
    local slot = hold(game, "eight_of_wands")
    T.assert_true(game:use_consumable(slot))
    T.assert_eq(#game.tags, tags + 1, "a tag was granted")
    T.assert_eq(game.money, 85, "$15 charged with no Jokers over the slots")
    wipe_mods()
end)

suite.test("ten of wands feeds the destroyed pair's Chips to the leftmost card", function()
    local game = install_pack()
    local left, mid, right = card(3, "Hearts"), card(5, "Clubs"), card(9, "Spades")
    setup_hand(game, { left, mid, right }, { left, mid, right })
    local slot = hold(game, "ten_of_wands")
    T.assert_true(game:use_consumable(slot))
    T.assert_eq(left.card_data.chip_bonus, 14, "5 + 9 Chips gained")
    T.assert_eq(#game.hand.card_nodes, 1, "the other two were destroyed")
    wipe_mods()
end)

suite.test("king of wands creates a non-Common, non-Legendary Joker", function()
    local game = install_pack()
    game.STATE = game.STATES.SHOP
    local slot = hold(game, "king_of_wands")
    T.assert_true(game:consumable_use_enabled(slot), "room for a Joker")
    T.assert_true(game:use_consumable(slot))
    T.assert_eq(#game.jokers, 1)
    local rarity = JOKER_DEFS[game.jokers[1].def.id].rarity
    T.assert_true(rarity == 2 or rarity == 3,
        "rarity is Uncommon or Rare, got " .. tostring(rarity))
    wipe_mods()
end)

--------------------------------------------------------------------------------
-- Swords
--------------------------------------------------------------------------------

suite.test("four of swords turns selected cards into random Face cards", function()
    local game = install_pack()
    local a, b = card(4, "Hearts"), card(6, "Clubs")
    setup_hand(game, { a, b }, { a, b })
    local slot = hold(game, "four_of_swords")
    T.assert_true(game:use_consumable(slot))
    for _, c in ipairs({ a, b }) do
        local r = c.card_data.rank
        T.assert_true(r == 11 or r == 12 or r == 13,
            "rank became a face rank, got " .. tostring(r))
    end
    wipe_mods()
end)

suite.test("five of swords grants one missing modifier to the selected card", function()
    local game = install_pack()
    local a = card(5, "Hearts")
    setup_hand(game, { a }, { a })
    local slot = hold(game, "five_of_swords")
    T.assert_true(game:use_consumable(slot))
    local gained = (a.card_data.seal and 1 or 0)
        + (a.card_data.edition and 1 or 0)
        + (a.card_data.enhancement and 1 or 0)
    T.assert_eq(gained, 1, "exactly one modifier was granted")
    wipe_mods()
end)

suite.test("nine of swords destroys the chosen Joker and pays $5", function()
    local game = install_pack()
    game.STATE = game.STATES.SHOP
    local j = add_joker(game, "j_pbp_claw")
    j.eternal = true
    local slot = hold(game, "nine_of_swords")
    local money = game.money
    T.assert_true(game:use_consumable(slot, j))
    T.assert_eq(#game.jokers, 0, "even an Eternal Joker is destroyed")
    T.assert_eq(game.money, money + 5)
    wipe_mods()
end)

suite.test("ten of swords destroys every full-deck card of the selected rank", function()
    local game = install_pack()
    local seven = card(7, "Hearts")
    setup_hand(game, { seven }, { seven })
    game.deck.cards = {
        { rank = 7, suit = "Clubs" }, { rank = 7, suit = "Spades" },
        { rank = 4, suit = "Diamonds" }, { rank = 12, suit = "Hearts" },
    }
    local slot = hold(game, "ten_of_swords")
    T.assert_true(game:use_consumable(slot))
    for _, d in ipairs(game.deck.cards) do
        T.assert_true(d.rank ~= 7, "no 7 remains in the deck")
    end
    T.assert_eq(#game.hand.card_nodes, 0, "the selected 7 is destroyed too")
    wipe_mods()
end)

suite.test("knight of swords creates a Minor Arcana and a Tarot", function()
    local game = install_pack()
    game.STATE = game.STATES.SHOP
    local slot = hold(game, "knight_of_swords")
    T.assert_true(game:use_consumable(slot))
    T.assert_eq(#game.consumables, 2, "two cards were created")
    local kinds = {}
    for _, c in ipairs(game.consumables) do kinds[c.kind] = true end
    T.assert_true(kinds.minor_arcana == true, "one is a Minor Arcana")
    T.assert_true(kinds.tarot == true, "one is a Tarot")
    wipe_mods()
end)

suite.test("queen of swords converts up to 3 distinct-suit deck cards to the selected suit", function()
    local game = install_pack()
    local ref = card(5, "Hearts")
    setup_hand(game, { ref }, { ref })
    game.deck.cards = {
        { rank = 2, suit = "Clubs" }, { rank = 3, suit = "Clubs" },
        { rank = 4, suit = "Spades" }, { rank = 6, suit = "Diamonds" },
        { rank = 8, suit = "Diamonds" }, { rank = 9, suit = "Hearts" },
    }
    local slot = hold(game, "queen_of_swords")
    T.assert_true(game:use_consumable(slot))
    local hearts, converted = 0, 0
    for _, d in ipairs(game.deck.cards) do
        if d.suit == "Hearts" then hearts = hearts + 1 end
    end
    converted = hearts - 1
    T.assert_true(converted >= 1 and converted <= 3,
        "between 1 and 3 cards converted, got " .. converted)
    wipe_mods()
end)

suite.test("king of swords strips Rental and Perishable from a Joker", function()
    local game = install_pack()
    game.STATE = game.STATES.SHOP
    local j = add_joker(game, "j_pbp_claw")
    j.rental = true
    j.perishable = true
    local slot = hold(game, "king_of_swords")
    T.assert_true(game:use_consumable(slot, j))
    T.assert_true(j.rental == nil, "Rental removed")
    T.assert_true(j.perishable == nil, "Perishable removed")
    wipe_mods()
end)

--------------------------------------------------------------------------------
-- Pentacles
--------------------------------------------------------------------------------

suite.test("two of pentacles toggles Eternal on the chosen Joker", function()
    local game = install_pack()
    game.STATE = game.STATES.SHOP
    local j = add_joker(game, "j_pbp_claw")
    local other = add_joker(game, "j_pbp_jacks")
    local slot = hold(game, "two_of_pentacles")
    T.assert_true(game:use_consumable(slot, j))
    T.assert_eq(j.eternal, true, "Eternal gained")
    T.assert_true(other.eternal == nil or other.eternal == false,
        "the unchosen Joker is untouched")
    slot = hold(game, "two_of_pentacles")
    T.assert_true(game:use_consumable(slot, j))
    T.assert_eq(j.eternal, false, "Eternal lost again")
    wipe_mods()
end)

suite.test("three of pentacles copies the rightmost enhancement to the other two", function()
    local game = install_pack()
    local a, b, src = card(3, "Hearts"), card(5, "Clubs"), card(9, "Spades", "gold")
    setup_hand(game, { a, b, src }, { a, b, src })
    local slot = hold(game, "three_of_pentacles")
    T.assert_true(game:use_consumable(slot))
    T.assert_eq(a.card_data.enhancement, "gold")
    T.assert_eq(b.card_data.enhancement, "gold")
    wipe_mods()
end)

suite.test("four of pentacles never destroys the 4 selected cards", function()
    local game = install_pack()
    local nodes, sel = {}, {}
    for i = 1, 6 do
        local c = card(i + 2, "Hearts")
        nodes[#nodes + 1] = c
        if i <= 4 then sel[#sel + 1] = c end
    end
    setup_hand(game, nodes, sel)
    local slot = hold(game, "four_of_pentacles")
    T.assert_true(game:use_consumable(slot))
    for _, c in ipairs(sel) do
        local alive = false
        for _, n in ipairs(game.hand.card_nodes) do
            if n == c then alive = true end
        end
        T.assert_true(alive, "a selected card survived")
    end
    wipe_mods()
end)

suite.test("six of pentacles grants a random economy tag", function()
    local game = install_pack()
    game.STATE = game.STATES.SHOP
    local tags = #game.tags
    local slot = hold(game, "six_of_pentacles")
    T.assert_true(game:use_consumable(slot))
    T.assert_eq(#game.tags, tags + 1, "one tag was granted")
    wipe_mods()
end)

suite.test("eight of pentacles pays $1 per unique Tarot and Minor Arcana used", function()
    local game = install_pack()
    game.STATE = game.STATES.SHOP
    game.consumable_usage = {
        tarot_a = { kind = "tarot", count = 1 },
        tarot_b = { kind = "tarot", count = 3 },
        planet_a = { kind = "planet", count = 1 },
    }
    local slot = hold(game, "eight_of_pentacles")
    local money = game.money
    T.assert_true(game:use_consumable(slot))
    -- 2 unique Tarots seeded + this card itself (tracked before its effect).
    T.assert_eq(game.money, money + 3)
    wipe_mods()
end)

suite.test("ten of pentacles pays between $5 and $10", function()
    local game = install_pack()
    game.STATE = game.STATES.SHOP
    local slot = hold(game, "ten_of_pentacles")
    local money = game.money
    T.assert_true(game:use_consumable(slot))
    local gained = game.money - money
    T.assert_true(gained >= 5 and gained <= 10,
        "paid in range, got " .. gained)
    wipe_mods()
end)

suite.test("queen of pentacles copies the right card's rank onto the left", function()
    local game = install_pack()
    local left, right = card(4, "Hearts"), card(12, "Clubs")
    setup_hand(game, { left, right }, { left, right })
    local slot = hold(game, "queen_of_pentacles")
    T.assert_true(game:use_consumable(slot))
    T.assert_eq(left.card_data.rank, 12)
    wipe_mods()
end)

suite.test("knight of pentacles resets the shop reroll count, shop only", function()
    local game = install_pack()
    local slot = hold(game, "knight_of_pentacles")
    game.STATE = game.STATES.SELECTING_HAND
    T.assert_false(game:consumable_use_enabled(slot),
        "not usable outside the shop")
    game.STATE = game.STATES.SHOP
    game.shop_reroll_count = 4
    T.assert_true(game:consumable_use_enabled(slot))
    T.assert_true(game:use_consumable(slot))
    T.assert_eq(game.shop_reroll_count, 0, "reroll escalation reset")
    wipe_mods()
end)

suite.test("king of pentacles pays $1 per face card in the full deck", function()
    local game = install_pack()
    game.STATE = game.STATES.SHOP
    game.deck.cards = {
        { rank = 11, suit = "Hearts" }, { rank = 12, suit = "Clubs" },
        { rank = 13, suit = "Spades" }, { rank = 13, suit = "Diamonds" },
        { rank = 4, suit = "Diamonds" },
    }
    local slot = hold(game, "king_of_pentacles")
    local money = game.money
    T.assert_true(game:use_consumable(slot))
    T.assert_eq(game.money, money + 4, "four face cards pay $4")
    wipe_mods()
end)

--------------------------------------------------------------------------------
-- Tier 3 additions: enhancements, conversions, tags, boosters, Dichrome
--------------------------------------------------------------------------------

suite.test("tier 3 centers register: 8 enhancements and the Dichrome edition", function()
    local game = install_pack()
    for _, v in ipairs({ "soaked", "sleeved", "bandaged", "wrapped",
        "ceramic", "domino", "stained", "antique" }) do
        T.assert_true(SMODS.EnhancementByValue[v] ~= nil,
            v .. " enhancement registered")
        T.assert_eq(SMODS.EnhancementByValue[v].weight, 0,
            v .. " stays out of the random polls, as on PC")
    end
    T.assert_true(SMODS.EditionByValue.dichrome ~= nil,
        "the Dichrome edition registers")
    T.assert_eq(SMODS.EditionByValue.dichrome.cost, 5)
    wipe_mods()
end)

suite.test("five of cups converts selected cards to Soaked", function()
    local game = install_pack()
    local a, b = card(5, "Hearts"), card(9, "Clubs")
    setup_hand(game, { a, b }, { a, b })
    local slot = hold(game, "five_of_cups")
    T.assert_true(game:consumable_use_enabled(slot))
    T.assert_true(game:use_consumable(slot))
    T.assert_eq(a.card_data.enhancement, "soaked")
    T.assert_eq(b.card_data.enhancement, "soaked")
    wipe_mods()
end)

suite.test("five of pentacles converts one selected card to Antique", function()
    local game = install_pack()
    local a, b = card(5, "Hearts"), card(9, "Clubs")
    setup_hand(game, { a, b }, { a })
    local slot = hold(game, "five_of_pentacles")
    T.assert_true(game:use_consumable(slot))
    T.assert_eq(a.card_data.enhancement, "antique")
    T.assert_eq(b.card_data.enhancement, nil, "only the selected card")
    wipe_mods()
end)

suite.test("antique cards grow and pay XChips through the center event", function()
    local game = install_pack()
    game.hand = Hand(game)
    game.hand:add_card({ rank = 9, suit = "Hearts", enhancement = "antique" })
    local node = game.hand.card_nodes[#game.hand.card_nodes]
    local ctx = { chips = 10, mult = 1 }
    SMODS.card_center_event(node, "card_played", ctx)
    T.assert_eq(node.card_data.pb_antique_x, 1.1, "first play grows to X1.1")
    T.assert_true(ctx.chips > 10, "the X1.1 Chips return lands on the total")
    SMODS.card_center_event(node, "card_played", ctx)
    T.assert_eq(node.card_data.pb_antique_x, 1.2, "second play grows to X1.2")
    wipe_mods()
end)

suite.test("knight of wands grants a High Risk Tag; seven of wands a Breaking Tag", function()
    local game = install_pack()
    game.STATE = game.STATES.SHOP
    local before = #game.tags
    local slot = hold(game, "knight_of_wands")
    T.assert_true(game:use_consumable(slot))
    T.assert_eq(#game.tags, before + 1, "one tag granted")
    T.assert_eq(game.tags[#game.tags].type, "high_risk")
    slot = hold(game, "seven_of_wands")
    T.assert_true(game:use_consumable(slot))
    T.assert_eq(game.tags[#game.tags].type, "breaking")
    wipe_mods()
end)

suite.test("angel investment tag pays $1 per $5 held when gained", function()
    local game = install_pack()
    game.money = 103
    game:addTag("angel_investment")
    T.assert_eq(game.money, 123, "floor(103/5) = $20 paid on gain")
    wipe_mods()
end)

suite.test("divination tag opens the Mega Minor Arcana Pack at blind choice", function()
    local game = install_pack()
    game:addTag("divination")
    T.assert_true(game:apply_new_blind_choice_tags(), "the tag fires")
    T.assert_true(game.booster_session ~= nil, "a pack session opened")
    T.assert_eq(game.booster_session.pack, "minor_arcana_mega")
    wipe_mods()
end)

suite.test("minor arcana booster packs register in all three sizes", function()
    local game = install_pack()
    local expect = {
        pbp_minor_arcana_normal = { 3, 1, 4, 100 },
        pbp_minor_arcana_jumbo = { 5, 1, 6, 100 },
        pbp_minor_arcana_mega = { 5, 2, 8, 25 },
    }
    for id, e in pairs(expect) do
        local entry = SMODS.Boosters[id]
        T.assert_true(entry ~= nil, id .. " registered")
        T.assert_eq(entry.card_count, e[1], id .. " card_count")
        T.assert_eq(entry.picks, e[2], id .. " picks")
        T.assert_eq(entry.cost, e[3], id .. " cost")
        T.assert_eq(entry.weight, e[4], id .. " weight")
        T.assert_eq(entry.pool_kind, "consumable", id .. " pool kind")
    end
    local profiled = SMODS.booster_profile_entries()
    local found = 0
    for _, p in ipairs(profiled) do
        if expect[p.key] then found = found + 1 end
    end
    T.assert_eq(found, 3, "all three packs join the shop booster pool")
    wipe_mods()
end)

suite.test("queen of wands can put Dichrome on a held Joker", function()
    local game = install_pack()
    game.STATE = game.STATES.SHOP
    local j = add_joker(game, "j_pbp_claw")
    local landed = false
    for _ = 1, 12 do
        local slot = hold(game, "queen_of_wands")
        T.assert_true(game:use_consumable(slot))
        if j.edition == "dichrome" then landed = true break end
    end
    T.assert_true(landed, "Dichrome landed within 12 uses (1-in-3 each)")
    wipe_mods()
end)

--------------------------------------------------------------------------------
-- Wave 1 addition: Two of Swords (last scored suit, tracked pack-side)
--------------------------------------------------------------------------------

suite.test("two of swords converts selected cards to Spades before anything scored", function()
    local game = install_pack()
    local a, b = card(5, "Hearts"), card(9, "Clubs")
    setup_hand(game, { a, b }, { a, b })
    local slot = hold(game, "two_of_swords")
    T.assert_true(game:use_consumable(slot))
    T.assert_eq(a.card_data.suit, "Spades", "PC's initial last scored suit")
    T.assert_eq(b.card_data.suit, "Spades")
    wipe_mods()
end)

suite.test("two of swords converts to the last suit a scoring pass observed", function()
    local game = install_pack()
    local stardrop = add_joker(game, "j_pbp_stardrop")
    local diamond = card(7, "Diamonds")
    local ctx = { event = "card_played", event_name = "card_played",
        chips = 0, mult = 1, rank = 7, suit = "Diamonds",
        card_node = diamond, played_cards = { diamond },
        full_hand = { diamond } }
    if stardrop:matches_trigger("card_played", ctx) then
        stardrop:apply_effect(ctx)
    end
    T.assert_eq(game.pb_last_scored_suit, "Diamonds",
        "Stardrop's individual pass tracked the scored card")
    local a = card(5, "Hearts")
    setup_hand(game, { a }, { a })
    local slot = hold(game, "two_of_swords")
    T.assert_true(game:use_consumable(slot))
    T.assert_eq(a.card_data.suit, "Diamonds")
    wipe_mods()
end)

return suite
