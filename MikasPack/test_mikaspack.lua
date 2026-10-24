--- Tests for the MikasPack Balatro3DS mod (not part of the game repo).
--- The mod's real main file is read from the MIKA_PACK_LUA env var.
--- Run against the Balatro3DS FORK tree: the decks need SMODS.Back and
--- several Jokers use the fork's blind-target / debt-limit APIs.
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

-- Joker keys (def ids are j_mmc_<key>).
local KEYS = {
    "prime_time", "straight_nate", "fisherman", "impatient", "cultist",
    "seal_collector", "camper", "scratch_card", "delayed", "showoff",
    "sniper", "blackjack", "batman", "bomb", "eye_chart", "grudgeful",
    "finishing_blow", "aurora_borealis", "historical", "suit_alley",
    "printer", "training_wheels", "horseshoe", "incomplete", "abbey_road",
    "fishing_license", "gold_bar", "rigged", "commander", "blue_moon",
    "glue", "harp_seal", "football_card", "special_edition", "stockpiler",
    "student_loans", "broke", "go_for_broke", "street_fighter", "checklist",
    "one_of_us", "investor", "mountain_climber", "shackles",
    "buy_one_get_one", "pack_a_punch", "seal_steal", "tax_collector",
    "glass_cannon", "scoring_test", "dawn", "savings", "monopolist",
    "nebula", "cheapskate", "psychic", "cheat", "plus_one",
}

-- Sprite file base names (the PC art names, which the pack keeps).
local SPRITES = {
    "c_mmc_ace_of_pentacles", "c_mmc_incense", "c_mmc_page_of_pentacles", "j_mmc_abbey_road",
    "j_mmc_aurora_borealis", "j_mmc_batman", "j_mmc_blackjack", "j_mmc_blue_moon",
    "j_mmc_bomb", "j_mmc_broke", "j_mmc_buy_one_get_one", "j_mmc_camper",
    "j_mmc_cheapskate", "j_mmc_cheat", "j_mmc_checklist", "j_mmc_commander",
    "j_mmc_cultist", "j_mmc_dawn", "j_mmc_delayed", "j_mmc_eye_chart",
    "j_mmc_finishing_blow", "j_mmc_fisherman", "j_mmc_fishing_license", "j_mmc_football_card",
    "j_mmc_glass_cannon", "j_mmc_glue", "j_mmc_go_for_broke", "j_mmc_gold_bar",
    "j_mmc_grudgeful", "j_mmc_harp_seal", "j_mmc_historical", "j_mmc_horseshoe",
    "j_mmc_impatient", "j_mmc_incomplete", "j_mmc_investor", "j_mmc_monopolist",
    "j_mmc_mountain_climber", "j_mmc_nebula", "j_mmc_one_of_us", "j_mmc_pack_a_punch",
    "j_mmc_plus_one", "j_mmc_prime_time", "j_mmc_printer", "j_mmc_psychic",
    "j_mmc_rigged", "j_mmc_savings", "j_mmc_scoring_test", "j_mmc_scratch_card",
    "j_mmc_seal_collector", "j_mmc_seal_steal", "j_mmc_shackles", "j_mmc_showoff",
    "j_mmc_sniper", "j_mmc_special_edition", "j_mmc_stockpiler", "j_mmc_straight_nate",
    "j_mmc_street_fighter", "j_mmc_student_loans", "j_mmc_suit_alley", "j_mmc_tax_collector",
    "j_mmc_training_wheels",
}

local function install_pack()
    wipe_mods()
    local path = os.getenv("MIKA_PACK_LUA")
    assert(path, "MIKA_PACK_LUA not set")
    local fh = assert(io.open(path, "rb"))
    local main = fh:read("*a")
    fh:close()
    local base = ModLoader.DIR .. "/MikasPack"
    love.filesystem.createDirectory(base)
    love.filesystem.write(base .. "/MikasPack.json", [[{
        "id": "MikasPack", "name": "Mika's Mod Collection", "prefix": "mmc",
        "main_file": "mikaspack.lua", "version": "1.0.0",
        "author": ["MikaSchoenmakers", "3DS port"]
    }]])
    love.filesystem.write(base .. "/mikaspack.lua", main)
    for _, n in ipairs(SPRITES) do
        love.filesystem.write(base .. "/assets/1x/" .. n .. ".png", "png")
        love.filesystem.write(base .. "/assets/1x/" .. n .. "_negative.png", "png")
    end
    ModLoader.load_all()
    local game = bootstrap.new_game(5150)
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

local function held(game, joker)
    for _, j in ipairs(game.jokers or {}) do if j == joker then return true end end
    return false
end

local function card(rank, suit, extra)
    local data = { rank = rank, suit = suit or "Hearts" }
    for k, v in pairs(extra or {}) do data[k] = v end
    local c = Card(0, 0, 1, 1, data)
    c.counts_for_play_score = true
    return c
end

local function fire(joker, event_name, extra)
    local ctx = { event = event_name, event_name = event_name }
    for k, v in pairs(extra or {}) do ctx[k] = v end
    if joker:matches_trigger(event_name, ctx) then joker:apply_effect(ctx) end
    return ctx
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

local function hand_setup(game)
    game.hand = Hand(game)
    game.deck = Deck(game)
end

--------------------------------------------------------------------------------
-- Loading + roster
--------------------------------------------------------------------------------

suite.test("pack loads and registers 58 Jokers, 3 consumables and 6 decks", function()
    local game = install_pack()
    local mod = ModLoader.by_id.MikasPack
    T.assert_eq(mod.status, "loaded", tostring(mod.error))
    T.assert_eq(#mod.registered.jokers, 58)
    local expect = {
        j_mmc_prime_time = { "Prime Time", 1, 4 },
        j_mmc_straight_nate = { "Straight Nate", 3, 7 },
        j_mmc_fisherman = { "The Fisherman", 2, 6 },
        j_mmc_impatient = { "Impatient Joker", 2, 6 },
        j_mmc_cultist = { "Cultist", 3, 8 },
        j_mmc_seal_collector = { "Seal Collector", 1, 4 },
        j_mmc_camper = { "Camper", 2, 5 },
        j_mmc_scratch_card = { "Scratch Card", 1, 4 },
        j_mmc_delayed = { "Delayed Joker", 2, 7 },
        j_mmc_showoff = { "The Show-Off", 3, 8 },
        j_mmc_sniper = { "The Sniper", 3, 10 },
        j_mmc_blackjack = { "Blackjack Joker", 2, 6 },
        j_mmc_batman = { "Batman", 3, 8 },
        j_mmc_bomb = { "Bomb", 1, 5 },
        j_mmc_eye_chart = { "Eye Chart", 1, 4 },
        j_mmc_grudgeful = { "Grudgeful Joker", 3, 9 },
        j_mmc_finishing_blow = { "Finishing Blow", 2, 6 },
        j_mmc_aurora_borealis = { "Aurora Borealis", 1, 6 },
        j_mmc_historical = { "Historical Joker", 3, 9 },
        j_mmc_suit_alley = { "Suit Alley", 1, 4 },
        j_mmc_printer = { "The Printer", 3, 9 },
        j_mmc_training_wheels = { "Training Wheels", 2, 6 },
        j_mmc_horseshoe = { "Horseshoe", 2, 6 },
        j_mmc_incomplete = { "Incomplete Joker", 1, 4 },
        j_mmc_abbey_road = { "Abbey Road", 2, 6 },
        j_mmc_fishing_license = { "Fishing License", 3, 8 },
        j_mmc_gold_bar = { "Gold Bar", 1, 5 },
        j_mmc_rigged = { "Rigged Joker", 1, 5 },
        j_mmc_commander = { "The Commander", 3, 9 },
        j_mmc_blue_moon = { "Blue Moon", 2, 8 },
        j_mmc_glue = { "Glue", 1, 5 },
        j_mmc_harp_seal = { "Harp Seal", 2, 6 },
        j_mmc_football_card = { "Football Card", 2, 7 },
        j_mmc_special_edition = { "Special Edition Joker", 2, 6 },
        j_mmc_stockpiler = { "The Stockpiler", 1, 4 },
        j_mmc_student_loans = { "Student Loans", 2, 4 },
        j_mmc_broke = { "Broke Joker", 1, 2 },
        j_mmc_go_for_broke = { "Go For Broke", 1, 4 },
        j_mmc_street_fighter = { "Street Fighter", 2, 7 },
        j_mmc_checklist = { "Checklist", 2, 7 },
        j_mmc_one_of_us = { "One Of Us", 2, 6 },
        j_mmc_investor = { "The Investor", 1, 4 },
        j_mmc_mountain_climber = { "Mountain Climber", 2, 7 },
        j_mmc_shackles = { "Shackles", 1, 5 },
        j_mmc_buy_one_get_one = { "Buy One Get One", 1, 5 },
        j_mmc_pack_a_punch = { "Pack A Punch", 3, 10 },
        j_mmc_seal_steal = { "Seal Steal", 1, 5 },
        j_mmc_tax_collector = { "Tax Collector", 1, 4 },
        j_mmc_glass_cannon = { "Glass Cannon", 2, 7 },
        j_mmc_scoring_test = { "Scoring Test", 2, 6 },
        j_mmc_dawn = { "Dawn", 2, 6 },
        j_mmc_savings = { "Savings", 2, 6 },
        j_mmc_monopolist = { "Monopolist", 3, 10 },
        j_mmc_nebula = { "Nebula", 1, 5 },
        j_mmc_cheapskate = { "Cheapskate", 1, 0 },
        j_mmc_psychic = { "Psychic Joker", 1, 5 },
        j_mmc_cheat = { "Cheat", 2, 6 },
        j_mmc_plus_one = { "Plus One", 3, 8 },
    }
    for id, e in pairs(expect) do
        local def = JOKER_DEFS[id]
        T.assert_true(def ~= nil, id .. " registered")
        T.assert_eq(def.name, e[1], id .. " name")
        T.assert_eq(def.rarity, e[2], id .. " rarity")
        T.assert_eq(def.cost, e[3], id .. " cost")
    end
    -- The two Jokers that stay unported, and the seventh deck.
    T.assert_nil(JOKER_DEFS.j_mmc_dagonet, "Dagonet stays out")
    T.assert_nil(JOKER_DEFS.j_mmc_cicero, "Cicero stays out")
    T.assert_nil(DECK_DEFS_BY_ID.b_mmc_jokers_for_hire, "Jokers for Hire stays out")
    -- Consumables.
    T.assert_true(CONSUMABLE_DEFS.c_mmc_ace_of_pentacles ~= nil, "Ace of Pentacles")
    T.assert_true(CONSUMABLE_DEFS.c_mmc_page_of_pentacles ~= nil, "Page of Pentacles")
    T.assert_true(CONSUMABLE_DEFS.c_mmc_incense ~= nil, "Incense")
    -- Decks.
    for _, id in ipairs({ "b_mmc_even_stevens", "b_mmc_odd_todds", "b_mmc_fibonacci",
        "b_mmc_prime", "b_mmc_midas", "b_mmc_perfect_precision" }) do
        T.assert_true(DECK_DEFS_BY_ID[id] ~= nil, id .. " registered")
        T.assert_true(SMODS.Backs[id] ~= nil, id .. " in SMODS.Backs")
    end
    -- Tooltips render for every Joker with no raw placeholders.
    local function flatten(t, out)
        out = out or {}
        if type(t) == "string" then out[#out + 1] = t
        elseif type(t) == "table" then
            if type(t.text) == "string" then out[#out + 1] = t.text end
            for _, v in pairs(t) do if type(v) == "table" then flatten(v, out) end end
        end
        return out
    end
    for _, n in ipairs(KEYS) do
        game.jokers = {}
        local j = add(game, "j_mmc_" .. n)
        local lines = SMODS.tooltip_lines("j_mmc_" .. n, j)
        T.assert_true(type(lines) == "table" and #lines >= 1, n .. " tooltip has lines")
        local text = table.concat(flatten(lines), " ")
        T.assert_true(text:find("#", 1, true) == nil, n .. " tooltip has no raw placeholder: " .. text)
    end
    wipe_mods()
end)

--------------------------------------------------------------------------------
-- Consumables
--------------------------------------------------------------------------------

suite.test("page of pentacles negates the balance, incense marks a Joker", function()
    local game = install_pack()
    game.STATE = game.STATES.SHOP
    game.consumables, game.consumable_nodes = {}, {}
    game.money = 30
    T.assert_true(game:add_consumable("c_mmc_page_of_pentacles"))
    T.assert_true(game:use_consumable(1))
    T.assert_eq(game.money, -30, "Page of Pentacles flips the balance")
    local j = add(game, "j_mmc_broke")
    T.assert_true(j.edition == nil or j.edition == "base", "the Joker starts editionless")
    game.money = 100
    T.assert_true(game:add_consumable("c_mmc_incense"))
    T.assert_true(game:use_consumable(1))
    T.assert_eq(j.edition, "negative", "Incense made it Negative")
    T.assert_eq(game.money, 50, "and charged the flat $50")
    wipe_mods()
end)

suite.test("ace of pentacles zeroes or doubles the balance", function()
    local game = install_pack()
    game.STATE = game.STATES.SHOP
    game.consumables, game.consumable_nodes = {}, {}
    game.money = 10
    T.assert_true(game:add_consumable("c_mmc_ace_of_pentacles"))
    T.assert_true(game:use_consumable(1))
    T.assert_true(game.money == 0 or game.money == 20,
        "money is $0 or doubled, got " .. tostring(game.money))
    wipe_mods()
end)

--------------------------------------------------------------------------------
-- Decks (SMODS.Back)
--------------------------------------------------------------------------------

local function plain_deck()
    local cards = {}
    for _, suit in ipairs({ "Spades", "Hearts", "Clubs", "Diamonds" }) do
        for rank = 2, 14 do cards[#cards + 1] = { rank = rank, suit = suit } end
    end
    return { cards = cards }
end

suite.test("even stevens deck filters the deck and grants its Joker", function()
    local game = install_pack()
    game.deck = plain_deck()
    game:apply_deck_config("b_mmc_even_stevens")
    T.assert_eq(#game.deck.cards, 20, "only the 20 even cards remain")
    for _, c in ipairs(game.deck.cards) do
        T.assert_true(c.rank <= 10 and c.rank % 2 == 0, "every kept card is even")
    end
    T.assert_eq(#game.jokers, 1)
    T.assert_eq(game.jokers[1].def.id, "j_even_steven")
    wipe_mods()
end)

suite.test("midas deck keeps gold face cards only", function()
    local game = install_pack()
    game.deck = plain_deck()
    game:apply_deck_config("b_mmc_midas")
    T.assert_eq(#game.deck.cards, 12, "only the 12 face cards remain")
    for _, c in ipairs(game.deck.cards) do
        T.assert_true(c.rank >= 11 and c.rank <= 13, "kept cards are faces")
        T.assert_eq(c.enhancement, "gold", "and they are Gold")
    end
    T.assert_eq(game.jokers[1].def.id, "j_midas_mask")
    wipe_mods()
end)

suite.test("perfect precision merges its config and grants a negative Sniper", function()
    local game = install_pack()
    game.deck = plain_deck()
    local base_req = game:get_base_requirement_for_ante(1)
    game:apply_deck_config("b_mmc_perfect_precision")
    T.assert_eq(game:get_effective_discards_per_round(), 4, "base 3 + 1 discard")
    T.assert_near(game:get_base_requirement_for_ante(1), base_req * 1.5, 0.001,
        "the ante requirement scales X1.5")
    T.assert_eq(#game.jokers, 1)
    T.assert_eq(game.jokers[1].def.id, "j_mmc_sniper")
    T.assert_eq(game.jokers[1].edition, "negative", "the Sniper is Negative")
    wipe_mods()
end)

--------------------------------------------------------------------------------
-- Glue / Harp Seal / Football Card
--------------------------------------------------------------------------------

suite.test("glue pays X5 and grants slots only with Half and Incomplete held", function()
    local game = install_pack()
    local glue = add(game, "j_mmc_glue")
    T.assert_eq(scored(glue, { played_cards = { card(4) } }).mult, 2, "nothing alone")
    add(game, "j_half")
    fire(glue, "on_joker_added", {})
    T.assert_eq(glue.ability.joker_slots, 0, "no slots with only Half")
    local incomplete = add(game, "j_mmc_incomplete")
    fire(glue, "on_joker_added", {})
    T.assert_eq(glue.ability.joker_slots, 2, "+2 slots with both held")
    T.assert_eq(scored(glue, { played_cards = { card(4) } }).mult, 10, "X5 Mult with both held")
    for i, j in ipairs(game.jokers) do if j == incomplete then table.remove(game.jokers, i) break end end
    fire(glue, "on_joker_sold", { joker = incomplete })
    T.assert_eq(glue.ability.joker_slots, 0, "slots leave with Incomplete")
    T.assert_eq(scored(glue, { played_cards = { card(4) } }).mult, 2, "and so does the X5")
    wipe_mods()
end)

suite.test("harp seal doubles gold, red and purple seals", function()
    local game = install_pack()
    game.consumables, game.consumable_nodes = {}, {}
    local harp = add(game, "j_mmc_harp_seal")
    game.money = 10
    local gold = card(7, "Hearts", { seal = "gold" })
    play_card(harp, gold, { gold })
    T.assert_eq(game.money, 13, "a scored Gold Seal pays $3 more")
    local red = card(8, "Hearts", { seal = "red" })
    T.assert_eq(harp:query_retrigger({ card_node = red, held = false }), 1,
        "a played Red Seal repeats")
    T.assert_eq(harp:query_retrigger({ card_node = red, held = true }), 1,
        "a held Red Seal repeats")
    local before = #game.consumables
    local purple = card(9, "Hearts", { seal = "purple" })
    fire(harp, "on_discard", { card_node = purple })
    T.assert_eq(#game.consumables, before + 1, "a discarded Purple Seal makes a Tarot")
    wipe_mods()
end)

suite.test("harp seal and aurora borealis ride held blue seals at round end", function()
    local game = install_pack()
    game.consumables, game.consumable_nodes = {}, {}
    game.hand = game.hand or {}
    game.hand.cards = {
        { rank = 5, suit = "Hearts", seal = "blue" },
        { rank = 9, suit = "Clubs", seal = "blue" },
        { rank = 2, suit = "Clubs" },
    }
    if game.hand.card_nodes then game.hand.card_nodes = {} end
    local harp = add(game, "j_mmc_harp_seal")
    fire(harp, "on_hand_played", { hand_type = "Pair", played_cards = { card(5) } })
    local before = #game.consumables
    fire(harp, "on_round_end", { game_over = false })
    T.assert_eq(#game.consumables, before + 2, "one extra Planet per held Blue Seal")
    local aurora = add(game, "j_mmc_aurora_borealis")
    fire(aurora, "on_hand_played", { hand_type = "Pair", played_cards = { card(5) } })
    before = #game.consumables
    fire(aurora, "on_round_end", { game_over = false })
    T.assert_eq(#game.consumables, before + 2, "Aurora adds one Negative Planet per seal")
    T.assert_eq(game.consumables[#game.consumables].edition, "negative",
        "Aurora's Planets are Negative")
    wipe_mods()
end)

suite.test("football card adds +50 Chips when a Common Joker triggers", function()
    local game = install_pack()
    add(game, "j_mmc_football_card")
    local plain = add(game, "j_joker")
    local ctx = { event = "on_hand_scored", event_name = "on_hand_scored", chips = 0, mult = 1 }
    SMODS.post_trigger(plain, ctx)
    T.assert_eq(ctx.chips, 50, "a Common trigger pays +50 Chips")
    local rare = add(game, "j_mmc_cultist")
    local ctx2 = { event = "on_hand_scored", event_name = "on_hand_scored", chips = 0, mult = 1 }
    SMODS.post_trigger(rare, ctx2)
    T.assert_eq(ctx2.chips, 0, "a Rare trigger pays nothing")
    wipe_mods()
end)

--------------------------------------------------------------------------------
-- Deck-census and dynamic-size Jokers
--------------------------------------------------------------------------------

suite.test("special edition counts seals, enhancements and editions in the deck", function()
    local game = install_pack()
    hand_setup(game)
    game.deck.cards[1].seal = "gold"
    game.deck.cards[2].enhancement = "bonus"
    game.deck.cards[3].edition = "foil"
    local se = add(game, "j_mmc_special_edition")
    local ctx = scored(se, { played_cards = { card(4) } })
    T.assert_eq(ctx.chips, 20, "+10 Chips for the one Enhancement")
    T.assert_near(ctx.mult, 4.4, 0.01, "(2 + 2 Mult for the Seal) X 1.1 for the Edition")
    wipe_mods()
end)

suite.test("stockpiler grows hand size with the deck, capped at the ante", function()
    local game = install_pack()
    hand_setup(game)
    game.ante = 3
    for _ = 1, 8 do game.deck.cards[#game.deck.cards + 1] = { rank = 2, suit = "Hearts" } end
    local st = add(game, "j_mmc_stockpiler")
    scored(st, { played_cards = { card(4) } })
    T.assert_eq(st.ability.h_size, 2, "60 cards = +2 hand size")
    T.assert_eq(st.ability.extra.current_h_size, 2)
    wipe_mods()
end)

--------------------------------------------------------------------------------
-- The debt family
--------------------------------------------------------------------------------

suite.test("student loans opens -$100 of debt and taxes discards", function()
    local game = install_pack()
    local loans = add(game, "j_mmc_student_loans")
    T.assert_eq(SMODS.debt_limit(game), 100, "the debt limit is $100")
    game.money = -30
    fire(loans, "on_money_altered", { amount = -30 })
    T.assert_eq(loans.ability.d_size, -2, "-$30 costs 2 discards (PC's harsh rounding)")
    T.assert_true(game:can_afford_price(50), "$50 is affordable at -$30 with the loan")
    T.assert_false(game:can_afford_price(200), "but not past the -$100 floor")
    wipe_mods()
end)

suite.test("broke, go for broke and street fighter read the negative balance", function()
    local game = install_pack()
    local broke = add(game, "j_mmc_broke")
    local gfb = add(game, "j_mmc_go_for_broke")
    local sf = add(game, "j_mmc_street_fighter")
    game.money = -30
    T.assert_eq(scored(broke, { played_cards = { card(4) } }).mult, 17,
        "+15 Mult at -$30 (2 base + 15)")
    T.assert_eq(scored(gfb, { played_cards = { card(4) } }).chips, 130,
        "+120 Chips at -$30 (10 base + 120)")
    T.assert_eq(scored(sf, { played_cards = { card(4) } }).mult, 8,
        "X4 Mult at or below -$20")
    game.money = 0
    T.assert_eq(scored(broke, { played_cards = { card(4) } }).mult, 2, "nothing at $0")
    T.assert_eq(scored(sf, { played_cards = { card(4) } }).mult, 2, "nothing at $0")
    wipe_mods()
end)

--------------------------------------------------------------------------------
-- Checklist / One Of Us / Investor / Mountain Climber
--------------------------------------------------------------------------------

suite.test("checklist levels the hand it names", function()
    local game = install_pack()
    local cl = add(game, "j_mmc_checklist")
    local name = cl.ability.extra.poker_hand
    T.assert_true(type(name) == "string", "a hand is named")
    local idx
    for i, n in ipairs(game.handlist) do if n == name then idx = i break end end
    T.assert_true(idx ~= nil, "the named hand is a real hand: " .. tostring(name))
    local before = game:get_hand_level_stats(idx)
    fire(cl, "on_hand_played", { hand_type = name, played_cards = { card(4) } })
    local after = game:get_hand_level_stats(idx)
    T.assert_eq(after, before + 1, "playing the named hand raises its level")
    local keep = cl.ability.extra.poker_hand
    fire(cl, "on_round_end", { game_over = false })
    T.assert_true(cl.ability.extra.poker_hand ~= keep, "the named hand changes at round end")
    wipe_mods()
end)

suite.test("one of us editions a random editionless Joker at five enhanced cards", function()
    local game = install_pack()
    local one = add(game, "j_mmc_one_of_us")
    local target = add(game, "j_mmc_broke")
    local hand = {}
    for i = 1, 5 do hand[i] = card(4 + i, "Hearts", { enhancement = "bonus" }) end
    scored(one, { played_cards = hand })
    T.assert_true(target.edition ~= nil and target.edition ~= "base",
        "the editionless Joker gained an edition")
    wipe_mods()
end)

suite.test("investor pays or takes $5 at round end, never anything else", function()
    local game = install_pack()
    local inv = add(game, "j_mmc_investor")
    game.money = 100
    local gained, lost = false, false
    for _ = 1, 60 do
        local before = game.money
        fire(inv, "on_round_end", { game_over = false })
        local delta = game.money - before
        T.assert_true(delta == 5 or delta == -5, "each round moves exactly $5, got " .. delta)
        if delta == 5 then gained = true else lost = true end
        if gained and lost then break end
    end
    T.assert_true(gained and lost, "both outcomes land within 60 rounds")
    wipe_mods()
end)

suite.test("mountain climber permanently adds +1 Mult to scored cards", function()
    local game = install_pack()
    local mc = add(game, "j_mmc_mountain_climber")
    local node = card(9, "Clubs")
    play_card(mc, node, { node })
    T.assert_eq(SMODS.get_perma(node, "perma_mult"), 1, "+1 after one score")
    play_card(mc, node, { node })
    T.assert_eq(SMODS.get_perma(node, "perma_mult"), 2, "+2 after two")
    wipe_mods()
end)

--------------------------------------------------------------------------------
-- Shop and destruction Jokers
--------------------------------------------------------------------------------

suite.test("shackles grants its stats and breaks over a 4-card hand", function()
    local game = install_pack()
    local sh = add(game, "j_mmc_shackles")
    T.assert_eq(sh.ability.hands, 1)
    T.assert_eq(sh.ability.d_size, 1)
    T.assert_eq(sh.ability.h_size, 1)
    local hand = { card(2), card(3), card(4), card(5), card(6) }
    scored(sh, { played_cards = hand })
    fire(sh, "on_hand_after", {})
    T.assert_false(held(game, sh), "destroyed after playing 5 cards")
    wipe_mods()
end)

suite.test("buy one get one sometimes duplicates a purchase, never more than one", function()
    local game = install_pack()
    local bogo = add(game, "j_mmc_buy_one_get_one")
    local made = 0
    for _ = 1, 80 do
        local before = #game.jokers
        fire(bogo, "on_shop_buy", { offer_kind = "joker" })
        local delta = #game.jokers - before
        T.assert_true(delta == 0 or delta == 1, "a buy adds at most one extra")
        made = made + delta
        if made >= 2 then break end
    end
    T.assert_true(made >= 1, "an extra Joker landed within 80 buys")
    local before = #game.jokers
    fire(bogo, "on_shop_buy", { offer_kind = "booster" })
    T.assert_eq(#game.jokers, before, "buying a pack is not duplicated")
    wipe_mods()
end)

suite.test("pack a punch pays $20 and editions the left-most Joker", function()
    local game = install_pack()
    local target = add(game, "j_mmc_broke")
    local pap = add(game, "j_mmc_pack_a_punch")
    game.money = 100
    fire(pap, "on_blind_selected", {})
    T.assert_eq(game.money, 80, "$20 paid")
    T.assert_true(target.edition ~= nil and target.edition ~= "base",
        "the left-most Joker gained an edition")
    wipe_mods()
end)

suite.test("seal steal turns scored purple and blue seals into cards", function()
    local game = install_pack()
    game.consumables, game.consumable_nodes = {}, {}
    local ss = add(game, "j_mmc_seal_steal")
    fire(ss, "on_hand_played", { hand_type = "Pair", played_cards = { card(5) } })
    local purple = card(9, "Hearts", { seal = "purple" })
    play_card(ss, purple, { purple })
    T.assert_eq(#game.consumables, 1, "a scored Purple Seal makes a Tarot")
    local blue = card(9, "Hearts", { seal = "blue" })
    play_card(ss, blue, { blue })
    T.assert_eq(#game.consumables, 2, "a scored Blue Seal makes a Planet")
    wipe_mods()
end)

suite.test("tax collector pays per held rarity at round end", function()
    local game = install_pack()
    local tax = add(game, "j_mmc_tax_collector")
    add(game, "j_mmc_fisherman")   -- Uncommon: $1
    add(game, "j_mmc_cultist")     -- Rare: $2
    add(game, "j_triboulet")       -- Legendary: $4
    game.money = 0
    fire(tax, "on_round_end", { game_over = false })
    T.assert_eq(game.money, 7, "the payout lands at round end")
    wipe_mods()
end)

suite.test("glass cannon repeats glass cards and destroys the scored ones", function()
    local game = install_pack()
    hand_setup(game)
    local gc = add(game, "j_mmc_glass_cannon")
    local nodes = {}
    for i = 1, 3 do
        local data = game.deck.cards[i]
        data.enhancement = "glass"
        nodes[i] = card(data.rank, data.suit, {})
        nodes[i].card_data = data
    end
    local before = #game.deck.cards
    T.assert_eq(gc:query_retrigger({ card_node = nodes[1], held = false }), 1,
        "a scored Glass card repeats")
    for _, n in ipairs(nodes) do play_card(gc, n, nodes) end
    fire(gc, "on_hand_after", {})
    T.assert_eq(#game.deck.cards, before - 3, "the scored Glass cards are destroyed")
    wipe_mods()
end)

suite.test("scoring test destroys a hand under 1% of the blind", function()
    local game = install_pack()
    hand_setup(game)
    game.current_blind_target = 30000
    local st = add(game, "j_mmc_scoring_test")
    local nodes = {}
    for i = 1, 5 do
        local data = game.deck.cards[i]
        nodes[i] = card(data.rank, data.suit, {})
        nodes[i].card_data = data
    end
    local before = #game.deck.cards
    scored(st, { played_cards = nodes })
    fire(st, "on_hand_final", { chips = 10, mult = 2 })
    fire(st, "on_hand_after", {})
    T.assert_eq(#game.deck.cards, before - 5, "a 20-chip hand against 30000 is destroyed")
    wipe_mods()
end)

--------------------------------------------------------------------------------
-- Round-shape Jokers
--------------------------------------------------------------------------------

suite.test("dawn and cheat retrigger the first hand and straights", function()
    local game = install_pack()
    local dawn = add(game, "j_mmc_dawn")
    local node = card(7, "Hearts")
    T.assert_eq(dawn:query_retrigger({ card_node = node, held = false }), 1,
        "Dawn repeats cards in the first hand of the round")
    local cheat = add(game, "j_mmc_cheat")
    fire(cheat, "on_hand_played", { hand_type = "Pair",
        contains_hand_types = { Pair = true }, played_cards = { node } })
    T.assert_eq(cheat:query_retrigger({ card_node = node, held = false }), 0,
        "Cheat stays quiet without a Straight")
    fire(cheat, "on_hand_played", { hand_type = "Straight",
        contains_hand_types = { Straight = true }, played_cards = { node } })
    T.assert_eq(cheat:query_retrigger({ card_node = node, held = false }), 1,
        "Cheat repeats every card of a Straight")
    wipe_mods()
end)

suite.test("savings grows +5 Mult per round and resets on a purchase", function()
    local game = install_pack()
    local sv = add(game, "j_mmc_savings")
    fire(sv, "on_round_end", { game_over = false })
    fire(sv, "on_round_end", { game_over = false })
    T.assert_eq(scored(sv, { played_cards = { card(4) } }).mult, 12, "+10 Mult after two rounds")
    fire(sv, "on_shop_buy", { offer_kind = "tarot" })
    T.assert_eq(sv.ability.extra.current_mult, 0, "a purchase resets it")
    T.assert_eq(scored(sv, { played_cards = { card(4) } }).mult, 2, "and the Mult is gone")
    wipe_mods()
end)

suite.test("monopolist climbs and falls with the balance", function()
    local game = install_pack()
    local mo = add(game, "j_mmc_monopolist")
    game.money = 25
    fire(mo, "on_money_altered", { amount = 25 })
    T.assert_eq(mo.ability.extra.req, 40, "two thresholds met: $10 and $20")
    T.assert_near(mo.ability.extra.current_x_mult, 2, 0.001, "X2 after two climbs")
    T.assert_eq(scored(mo, { played_cards = { card(4) } }).mult, 4, "the X2 applies")
    game.money = 5
    fire(mo, "on_money_altered", { amount = -20 })
    T.assert_eq(mo.ability.extra.req, 10, "it settles back to the base threshold")
    T.assert_near(mo.ability.extra.current_x_mult, 1, 0.001, "and back to X1")
    wipe_mods()
end)

suite.test("nebula adds hand levels above 1 to Mult", function()
    local game = install_pack()
    local idx
    for i, n in ipairs(game.handlist) do if n == "Pair" then idx = i break end end
    game.hand_stats = game.hand_stats or {}
    game.hand_stats[idx] = { level = 4, base_chips = 15, chips_per_level = 10,
        base_mult = 2, mult_per_level = 1 }
    local neb = add(game, "j_mmc_nebula")
    T.assert_eq(scored(neb, { played_cards = { card(4) } }).mult, 5,
        "Pair at level 4 adds +3 Mult")
    wipe_mods()
end)

suite.test("cheapskate stashes half a pack's price and pays it on the skip", function()
    local game = install_pack()
    local ch = add(game, "j_mmc_cheapskate")
    game.money = 20
    fire(ch, "on_shop_buy", { offer_kind = "booster", offer_price = 10 })
    T.assert_eq(ch.ability.extra.cost, 5, "half the $10 pack is stashed")
    fire(ch, "on_booster_skip", {})
    T.assert_eq(game.money, 25, "skipping the pack pays the $5")
    T.assert_eq(ch.ability.extra.cost, 0, "and the stash is spent")
    wipe_mods()
end)

suite.test("psychic pays +150 Chips for a full hand and breaks on a short one", function()
    local game = install_pack()
    local ps = add(game, "j_mmc_psychic")
    local five = { card(2), card(3), card(4), card(5), card(6) }
    T.assert_eq(scored(ps, { played_cards = five }).chips, 160, "+150 Chips for five cards")
    fire(ps, "on_hand_after", {})
    T.assert_true(held(game, ps), "a full hand leaves it standing")
    local four = { card(2), card(3), card(4), card(5) }
    scored(ps, { played_cards = four })
    fire(ps, "on_hand_after", {})
    T.assert_false(held(game, ps), "a four-card hand destroys it")
    wipe_mods()
end)

suite.test("plus one raises scored ranks on the first hand, aces wrap to 2", function()
    local game = install_pack()
    local po = add(game, "j_mmc_plus_one")
    local five = card(5, "Hearts")
    play_card(po, five, { five })
    T.assert_eq(five.card_data.rank, 6, "a 5 becomes a 6")
    local ace = card(14, "Clubs")
    play_card(po, ace, { ace })
    T.assert_eq(ace.card_data.rank, 2, "an Ace wraps to a 2")
    local king = card(13, "Clubs")
    play_card(po, king, { king })
    T.assert_eq(king.card_data.rank, 14, "a King becomes an Ace")
    wipe_mods()
end)

return suite
