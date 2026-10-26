--- Tests for the BuncoPack Balatro3DS mod (not part of the game repo).
--- The mod's real main file is read from the BUNCO_PACK_LUA env var.
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
    "cassette", "mosaic", "voxel", "crop_circles", "prehistoric", "shepherd",
    "jumper", "dogs_playing_poker", "headshot", "nil_bill", "slothful",
    "hierarchy_of_needs", "protester", "disproportionality", "on_broadway",
    "rasta", "critic", "wino", "tangram",
    -- v1.1.0
    "basement", "linocut", "ghost_print", "loan_shark", "righthook", "carnival",
    "fingerprints", "zero_shapiro", "bierdeckel", "registration_plate",
    "juggalo", "hopscotch", "pawn", "stylophone", "mousetrap", "doodle",
    "xray", "dread", "the_joker", "puzzle_board",
    "zealous", "lurid", "envious", "proud", "wishalloy", "unobtanium",
    "dynasty", "magic_wand", "starfruit", "fondue", "roygbiv", "rigoletto",
    "rigoletto_soul",
    "quaoar", "haumea", "sedna", "makemake", "sky", "abyss",
    -- v1.2.0
    "neon", "bounty_hunter",
    -- v1.3.0
    "fiendish", "head_in_the_clouds",
    -- v1.4.0
    "gameplan", "conquest", "myopia", "astigmatism",
    "sledgehammer", "dwarven", "metallurgist",
    -- v1.5.0
    "jmjb", "aristocrat", "doorhanger", "running_joke",
}

local NEW_JOKERS = {
    "basement", "linocut", "ghost_print", "loan_shark", "righthook", "carnival",
    "fingerprints", "zero_shapiro", "bierdeckel", "registration_plate",
    "juggalo", "hopscotch", "pawn", "stylophone", "mousetrap", "doodle",
    "xray", "dread", "the_joker", "puzzle_board",
    "zealous", "lurid", "envious", "proud", "wishalloy", "unobtanium",
    "dynasty", "magic_wand", "starfruit", "fondue", "roygbiv", "rigoletto",
    -- v1.2.0
    "neon", "bounty_hunter",
    -- v1.3.0
    "fiendish", "head_in_the_clouds",
    -- v1.4.0
    "gameplan", "conquest", "myopia", "astigmatism",
    "sledgehammer", "dwarven", "metallurgist",
    -- v1.5.0
    "jmjb", "aristocrat", "doorhanger", "running_joke",
}

local function install_pack()
    wipe_mods()
    local path = os.getenv("BUNCO_PACK_LUA")
    assert(path, "BUNCO_PACK_LUA not set")
    local fh = assert(io.open(path, "rb"))
    local main = fh:read("*a")
    fh:close()
    local base = ModLoader.DIR .. "/BuncoPack"
    love.filesystem.createDirectory(base)
    love.filesystem.write(base .. "/BuncoPack.json", [[{
        "id": "BuncoPack", "name": "Bunco Pack", "prefix": "buncp",
        "main_file": "buncopack.lua", "version": "1.0.0",
        "author": ["Firch", "3DS port"]
    }]])
    love.filesystem.write(base .. "/buncopack.lua", main)
    for _, n in ipairs(NAMES) do
        love.filesystem.write(base .. "/assets/1x/" .. n .. ".png", "png")
        love.filesystem.write(base .. "/assets/1x/" .. n .. "_negative.png", "png")
    end
    ModLoader.load_all()
    local game = bootstrap.new_game(7710)
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

local function fake_deck(game, list)
    game.count_cards_in_full_deck = function(self, pred)
        local n = 0
        for _, c in ipairs(list) do
            if (not pred) or pred(c) then n = n + 1 end
        end
        return n
    end
end

--------------------------------------------------------------------------------
-- Loading + tooltips
--------------------------------------------------------------------------------

suite.test("pack loads and registers all 66 Bunco Jokers", function()
    local game = install_pack()
    local mod = ModLoader.by_id.BuncoPack
    T.assert_eq(mod.status, "loaded", tostring(mod.error))
    T.assert_eq(#mod.registered.jokers, 66)
    local expect = {
        j_buncp_cassette = { "Cassette", 2, 5 }, j_buncp_mosaic = { "Mosaic Joker", 2, 4 },
        j_buncp_voxel = { "Voxel Joker", 2, 5 }, j_buncp_crop_circles = { "Crop Circles", 1, 4 },
        j_buncp_prehistoric = { "Prehistoric Joker", 2, 5 }, j_buncp_shepherd = { "Shepherd Joker", 1, 5 },
        j_buncp_jumper = { "Jumper", 1, 5 }, j_buncp_dogs_playing_poker = { "Dogs Playing Poker", 2, 5 },
        j_buncp_headshot = { "Headshot", 2, 8 }, j_buncp_nil_bill = { "Nil Bill", 2, 4 },
        j_buncp_slothful = { "Slothful Joker", 2, 5 }, j_buncp_hierarchy_of_needs = { "Hierarchy of Needs", 1, 5 },
        j_buncp_protester = { "Protester", 1, 4 }, j_buncp_disproportionality = { "Disproportionality", 1, 4 },
        j_buncp_on_broadway = { "On Broadway", 2, 6 }, j_buncp_rasta = { "Rasta", 1, 5 },
        j_buncp_critic = { "Critic", 1, 6 }, j_buncp_wino = { "Wino", 1, 5 },
        j_buncp_tangram = { "Tangram", 3, 7 },
    }
    for id, e in pairs(expect) do
        local def = JOKER_DEFS[id]
        T.assert_true(def ~= nil, id .. " registered")
        T.assert_eq(def.name, e[1], id .. " name")
        T.assert_eq(def.rarity, e[2], id .. " rarity")
        T.assert_eq(def.cost, e[3], id .. " cost")
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
    for _, n in ipairs(NAMES) do
        if n ~= "rigoletto_soul" and n ~= "quaoar" and n ~= "haumea" and n ~= "sedna"
            and n ~= "makemake" and n ~= "sky" and n ~= "abyss" then
            game.jokers = {}
            local j = add(game, "j_buncp_" .. n)
            local lines = SMODS.tooltip_lines("j_buncp_" .. n, j)
            T.assert_true(type(lines) == "table" and #lines >= 1, n .. " tooltip has lines")
            local text = table.concat(flatten(lines), " ")
            T.assert_true(text:find("#", 1, true) == nil, n .. " tooltip has no raw placeholder: " .. text)
        end
    end
    -- v1.1.0 registrations: names, rarities, costs.
    local expect_new = {
        j_buncp_basement = { "Basement Joker", 3, 8 }, j_buncp_linocut = { "Linocut Joker", 2, 4 },
        j_buncp_ghost_print = { "Ghost Print", 2, 6 }, j_buncp_loan_shark = { "Loan Shark", 2, 3 },
        j_buncp_righthook = { "Righthook", 3, 8 }, j_buncp_carnival = { "Carnival", 3, 10 },
        j_buncp_fingerprints = { "Fingerprints", 2, 8 }, j_buncp_zero_shapiro = { "Zero Shapiro", 2, 4 },
        j_buncp_bierdeckel = { "Bierdeckel", 2, 4 }, j_buncp_registration_plate = { "Registration Plate", 3, 8 },
        j_buncp_juggalo = { "Juggalo", 3, 5 }, j_buncp_hopscotch = { "Hopscotch", 1, 4 },
        j_buncp_pawn = { "Pawn", 1, 5 }, j_buncp_stylophone = { "Stylophone", 2, 5 },
        j_buncp_mousetrap = { "Mousetrap", 2, 6 }, j_buncp_doodle = { "Doodle", 3, 10 },
        j_buncp_xray = { "X-Ray", 1, 4 }, j_buncp_dread = { "Dread", 3, 8 },
        j_buncp_the_joker = { "The Joker", 3, 10 }, j_buncp_puzzle_board = { "Puzzle Board", 2, 6 },
        j_buncp_zealous = { "Zealous Joker", 1, 3 }, j_buncp_lurid = { "Lurid Joker", 1, 3 },
        j_buncp_envious = { "Envious Joker", 1, 5 }, j_buncp_proud = { "Proud Joker", 1, 5 },
        j_buncp_wishalloy = { "Wishalloy", 2, 7 }, j_buncp_unobtanium = { "Unobtanium", 2, 7 },
        j_buncp_dynasty = { "The Dynasty", 3, 8 }, j_buncp_magic_wand = { "Magic Wand", 1, 5 },
        j_buncp_starfruit = { "Starfruit", 2, 5 }, j_buncp_fondue = { "Fondue", 3, 8 },
        j_buncp_roygbiv = { "Roy G. Biv", 2, 8 }, j_buncp_rigoletto = { "Rigoletto", 4, 20 },
        j_buncp_neon = { "Neon Joker", 2, 5 }, j_buncp_bounty_hunter = { "Bounty Hunter", 1, 5 },
        j_buncp_fiendish = { "Fiendish Joker", 2, 5 }, j_buncp_head_in_the_clouds = { "Head in the Clouds", 2, 6 },
        j_buncp_gameplan = { "Gameplan", 2, 5 }, j_buncp_conquest = { "Conquest", 2, 5 },
        j_buncp_myopia = { "Myopia", 2, 8 }, j_buncp_astigmatism = { "Astigmatism", 2, 8 },
        j_buncp_sledgehammer = { "Sledgehammer", 2, 5 }, j_buncp_dwarven = { "Dwarven Joker", 2, 8 },
        j_buncp_metallurgist = { "Metallurgist", 1, 6 },
        j_buncp_jmjb = { "Joker Man & Jester Boy Trading Card No. 54", 3, 5 },
        j_buncp_aristocrat = { "Aristocrat", 2, 6 },
        j_buncp_doorhanger = { "Doorhanger", 3, 10 },
        j_buncp_running_joke = { "Running Joke", 3, 8 },
    }
    for id, e in pairs(expect_new) do
        local def = JOKER_DEFS[id]
        T.assert_true(def ~= nil, id .. " registered")
        T.assert_eq(def.name, e[1], id .. " name")
        T.assert_eq(def.rarity, e[2], id .. " rarity")
        T.assert_eq(def.cost, e[3], id .. " cost")
    end
    for _, n in ipairs(NEW_JOKERS) do
        game.jokers = {}
        local j = add(game, "j_buncp_" .. n)
        local lines = SMODS.tooltip_lines("j_buncp_" .. n, j)
        T.assert_true(type(lines) == "table" and #lines >= 1, n .. " tooltip has lines")
        local text = table.concat(flatten(lines), " ")
        T.assert_true(text:find("#", 1, true) == nil, n .. " tooltip has no raw placeholder: " .. text)
    end
    -- Consumables: the four Spectrum Planets and the two exotic Tarots.
    T.assert_eq(#mod.registered.consumables, 6, "six consumables registered")
    wipe_mods()
end)

--------------------------------------------------------------------------------
-- Individual-card Jokers
--------------------------------------------------------------------------------

suite.test("mosaic, slothful and wino pay on their card types", function()
    local game = install_pack()
    local mosaic = add(game, "j_buncp_mosaic")
    local slothful = add(game, "j_buncp_slothful")
    local wino = add(game, "j_buncp_wino")
    local stone, wild, heart, spade = card(9, "Clubs", "stone"), card(9, "Clubs", "wild"), card(9, "Hearts"), card(9, "Spades")
    local played = { stone, wild, heart, spade }
    T.assert_eq(play_card(mosaic, stone, played).mult, 7, "Mosaic +6 on Stone")
    T.assert_eq(play_card(mosaic, heart, played).mult, 1, "Mosaic quiet on plain")
    T.assert_eq(play_card(slothful, wild, played).mult, 10, "Slothful +9 on Wild")
    T.assert_eq(play_card(slothful, stone, played).mult, 1, "Slothful quiet on Stone")
    T.assert_eq(play_card(wino, heart, played).chips, 12, "Wino +12 on Hearts")
    T.assert_eq(play_card(wino, spade, played).chips, 0, "Wino quiet on Spades")
    wipe_mods()
end)

suite.test("crop circles pays by natural suit and rank, never on Stone", function()
    local game = install_pack()
    local cc = add(game, "j_buncp_crop_circles")
    local function pay(node)
        return play_card(cc, node, { node }).mult - 1
    end
    T.assert_eq(pay(card(8, "Clubs")), 5, "Clubs 8 pays 5")
    T.assert_eq(pay(card(12, "Clubs")), 4, "Clubs Q pays 4")
    T.assert_eq(pay(card(5, "Clubs")), 3, "Clubs 5 pays 3")
    T.assert_eq(pay(card(8, "Hearts")), 2, "Hearts 8 pays 2")
    T.assert_eq(pay(card(10, "Hearts")), 1, "Hearts 10 pays 1")
    T.assert_eq(pay(card(5, "Hearts")), 0, "Hearts 5 pays 0")
    T.assert_eq(pay(card(8, "Clubs", "stone")), 0, "Stone pays 0")
    T.assert_eq(pay(card(5, "Clubs", "wild")), 3, "Wild counts as its base suit (Clubs)")
    wipe_mods()
end)

suite.test("tangram multiplies by the number of 7s in the hand", function()
    local game = install_pack()
    local tangram = add(game, "j_buncp_tangram")
    local a, b, c, d = card(7, "Spades"), card(7, "Hearts"), card(7, "Clubs"), card(12, "Clubs")
    local played = { a, b, c, d }
    T.assert_eq(play_card(tangram, a, played).mult, 22, "each 7 gives +21 (7 x 3)")
    T.assert_eq(play_card(tangram, d, played).mult, 1, "non-7 gives nothing")
    wipe_mods()
end)

suite.test("prehistoric pays when a card repeats an earlier scored card", function()
    local game = install_pack()
    local pre = add(game, "j_buncp_prehistoric")
    local k1, k2, q = card(13, "Spades"), card(13, "Spades"), card(12, "Spades")
    local played = { k1, k2, q }
    T.assert_eq(play_card(pre, k1, played).mult, 1, "first King scores quietly")
    T.assert_eq(play_card(pre, k2, played).mult, 17, "second King matches: +16")
    T.assert_eq(play_card(pre, q, played).mult, 1, "Queen does not match")
    fire(pre, "on_round_end", { game_over = false })
    T.assert_eq(play_card(pre, k1, played).mult, 1, "list cleared at round end")
    wipe_mods()
end)

--------------------------------------------------------------------------------
-- joker_main Jokers
--------------------------------------------------------------------------------

suite.test("shepherd and jumper scale on Pair and Flush", function()
    local game = install_pack()
    local shep = add(game, "j_buncp_shepherd")
    local jump = add(game, "j_buncp_jumper")
    local pair_hand = { card(4), card(4, "Spades") }
    before(shep, { played_cards = pair_hand, contains_hand_types = { Pair = true } })
    before(shep, { played_cards = pair_hand, contains_hand_types = { Pair = true } })
    before(shep, { played_cards = { card(2), card(5), card(7) }, contains_hand_types = {} })
    local ctx = scored(shep, { played_cards = pair_hand })
    T.assert_eq(ctx.chips, 22, "Shepherd at +12 after two Pairs (10 base + 12), a Pair-less hand adds nothing")
    local flush_hand = { card(2), card(4), card(6), card(8), card(10) }
    before(jump, { played_cards = flush_hand, contains_hand_types = { Flush = true } })
    ctx = scored(jump, { played_cards = flush_hand })
    T.assert_eq(ctx.chips, 18, "Jumper at +8 after one Flush")
    wipe_mods()
end)

suite.test("dogs playing poker needs every scoring rank at 5 or below", function()
    local game = install_pack()
    local dogs = add(game, "j_buncp_dogs_playing_poker")
    local low = { card(2), card(3, "Spades"), card(4, "Clubs"), card(5, "Diamonds") }
    local ctx = scored(dogs, { played_cards = low })
    T.assert_near(ctx.mult, 5, 0.001, "X2.5 applied (2 x 2.5)")
    local mixed = { card(2), card(9) }
    ctx = scored(dogs, { played_cards = mixed })
    T.assert_eq(ctx.mult, 2, "a 9 disqualifies")
    local with_stone = { card(2), card(14, "Clubs", "stone") }
    ctx = scored(dogs, { played_cards = with_stone })
    T.assert_near(ctx.mult, 5, 0.001, "Stone does not disqualify")
    wipe_mods()
end)

suite.test("headshot needs exactly one scoring face card", function()
    local game = install_pack()
    local hs = add(game, "j_buncp_headshot")
    local one = { card(12), card(4), card(6) }
    T.assert_near(scored(hs, { played_cards = one }).mult, 6, 0.001, "one face: X3")
    local two = { card(12), card(13), card(6) }
    T.assert_eq(scored(hs, { played_cards = two }).mult, 2, "two faces: nothing")
    local none = { card(4), card(6) }
    T.assert_eq(scored(hs, { played_cards = none }).mult, 2, "no faces: nothing")
    wipe_mods()
end)

suite.test("rasta pays only with no enhanced scoring cards", function()
    local game = install_pack()
    local rasta = add(game, "j_buncp_rasta")
    local plain = { card(4), card(6) }
    T.assert_eq(scored(rasta, { played_cards = plain }).mult, 14, "+12 Mult on a plain hand")
    local enhanced = { card(4, "Hearts", "bonus"), card(6) }
    T.assert_eq(scored(rasta, { played_cards = enhanced }).mult, 2, "an enhanced card blocks it")
    wipe_mods()
end)

suite.test("on broadway pays on a Straight with a scoring face card", function()
    local game = install_pack()
    local ob = add(game, "j_buncp_on_broadway")
    local straight_face = { card(10), card(11), card(12), card(13), card(14) }
    local ctx = scored(ob, { played_cards = straight_face, contains_hand_types = { Straight = true } })
    T.assert_eq(ctx.chips, 130, "+120 Chips")
    T.assert_eq(ctx.mult, 22, "+20 Mult")
    local straight_plain = { card(6), card(7), card(8), card(9), card(10) }
    ctx = scored(ob, { played_cards = straight_plain, contains_hand_types = { Straight = true } })
    T.assert_eq(ctx.chips, 10, "no face card: no Chips")
    T.assert_eq(ctx.mult, 2, "no face card: no Mult")
    local pair_face = { card(12), card(12, "Spades"), card(4) }
    ctx = scored(ob, { played_cards = pair_face, contains_hand_types = { Pair = true } })
    T.assert_eq(ctx.chips, 10, "a Pair with a face card is not a Straight: no Chips")
    T.assert_eq(ctx.mult, 2, "a Pair with a face card is not a Straight: no Mult")
    wipe_mods()
end)

suite.test("critic doubles Mult only under a third of the blind target", function()
    local game = install_pack()
    game.current_blind_target = 900
    local critic = add(game, "j_buncp_critic")
    local low = { card(4) }
    T.assert_eq(scored(critic, { played_cards = low }).mult, 4, "score 20 < 300: X2")
    local high_ctx = { played_cards = low, chips = 200, mult = 2 }
    T.assert_eq(scored(critic, high_ctx).mult, 2, "score 400 >= 300: nothing")
    wipe_mods()
end)

suite.test("disproportionality pays a bounded random chip amount", function()
    local game = install_pack()
    local dis = add(game, "j_buncp_disproportionality")
    local ctx = scored(dis, { played_cards = { card(4) } })
    T.assert_true(ctx.chips >= 10 and ctx.chips <= 210, "chips within 10..210, got " .. tostring(ctx.chips))
    wipe_mods()
end)

--------------------------------------------------------------------------------
-- State and deck Jokers
--------------------------------------------------------------------------------

suite.test("cassette flips sides on discard and pays per side", function()
    local game = install_pack()
    local cas = add(game, "j_buncp_cassette")
    local heart, spade = card(9, "Hearts"), card(9, "Spades")
    T.assert_eq(play_card(cas, heart, { heart }).chips, 45, "side A: Hearts +45 Chips")
    T.assert_eq(play_card(cas, spade, { spade }).chips, 0, "side A: Spades nothing")
    fire(cas, "on_pre_discard", { discarded_nodes = { spade } })
    T.assert_eq(play_card(cas, spade, { spade }).mult, 7, "side B: Spades +6 Mult")
    T.assert_eq(play_card(cas, heart, { heart }).mult, 1, "side B: Hearts nothing")
    fire(cas, "on_pre_discard", { discarded_nodes = { heart } })
    T.assert_eq(play_card(cas, heart, { heart }).chips, 45, "back on side A")
    wipe_mods()
end)

suite.test("voxel scales down with enhanced cards in the deck", function()
    local game = install_pack()
    local vox = add(game, "j_buncp_voxel")
    local deck = {}
    fake_deck(game, deck)
    T.assert_near(scored(vox, { played_cards = { card(4) } }).mult, 6, 0.001, "clean deck: X3")
    for _ = 1, 10 do deck[#deck + 1] = { rank = 5, suit = "Clubs", enhancement = "bonus" } end
    T.assert_near(scored(vox, { played_cards = { card(4) } }).mult, 4, 0.001, "10 enhanced: X2")
    for _ = 1, 25 do deck[#deck + 1] = { rank = 5, suit = "Clubs", enhancement = "mult" } end
    T.assert_eq(scored(vox, { played_cards = { card(4) } }).mult, 2, "35 enhanced: floored at X1 (no effect)")
    wipe_mods()
end)

suite.test("hierarchy of needs counts complete suit sequences", function()
    local game = install_pack()
    local hier = add(game, "j_buncp_hierarchy_of_needs")
    local deck = {}
    for _, suit in ipairs({ "Spades", "Hearts" }) do
        for id = 2, 14 do deck[#deck + 1] = { rank = id, suit = suit } end
    end
    fake_deck(game, deck)
    T.assert_eq(scored(hier, { played_cards = { card(4) } }).mult, 12, "two complete suits: +10 Mult")
    fake_deck(game, {})
    T.assert_eq(scored(hier, { played_cards = { card(4) } }).mult, 22, "empty deck shows the collection default +20")
    wipe_mods()
end)

suite.test("protester banks 8x the highest discarded rank until round end", function()
    local game = install_pack()
    local pro = add(game, "j_buncp_protester")
    local batch = { card(5), card(13, "Diamonds"), card(9, "Clubs") }
    fire(pro, "on_pre_discard", { discarded_nodes = batch })
    T.assert_eq(scored(pro, { played_cards = { card(4) } }).chips, 90, "King discarded: +80 Chips")
    fire(pro, "on_pre_discard", { discarded_nodes = { card(3) } })
    T.assert_eq(scored(pro, { played_cards = { card(4) } }).chips, 90, "a lower discard does not reduce it")
    fire(pro, "on_round_end", { game_over = false })
    T.assert_eq(scored(pro, { played_cards = { card(4) } }).chips, 10, "reset at round end")
    local stone_batch = { card(13, "Spades", "stone") }
    fire(pro, "on_pre_discard", { discarded_nodes = stone_batch })
    T.assert_eq(scored(pro, { played_cards = { card(4) } }).chips, 10, "Stone discards do not count")
    wipe_mods()
end)

suite.test("nil bill pays $2 per destroyed card", function()
    local game = install_pack()
    local nb = add(game, "j_buncp_nil_bill")
    local before_money = game.money
    fire(nb, "on_destroy", { destroyed_cards = { {}, {}, {} } })
    T.assert_eq(game.money - before_money, 6, "3 destroyed cards pay $6")
    fire(nb, "on_destroy", { destroyed_cards = {} })
    T.assert_eq(game.money - before_money, 6, "an empty removal pays nothing")
    wipe_mods()
end)

--------------------------------------------------------------------------------
-- v1.1.0: suits, hands, the exotic gate
--------------------------------------------------------------------------------

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

local function hand_index(game, name)
    for i, n in ipairs(game.handlist) do if n == name then return i end end
    return nil
end

local function ensure_hand(game)
    if not game.hand then game.hand = Hand(game) end
    return game.hand
end

--- A card properly registered in the game's hand (data + node + uid), the
--- way real play holds it; destroy and deck scans only see registered cards.
local function hand_card(game, rank, suit, enhancement)
    ensure_hand(game)
    local data = { rank = rank, suit = suit or "Hearts" }
    if enhancement then data.enhancement = enhancement end
    local node = game.hand:add_card(data, true)
    node.counts_for_play_score = true
    return node
end

suite.test("exotic suits register and a custom-suit flush scores as Flush", function()
    local game = install_pack()
    T.assert_true(SMODS.Suits["Fleurons"] ~= nil, "Fleurons registered")
    T.assert_true(SMODS.Suits["Halberds"] ~= nil, "Halberds registered")
    T.assert_eq(SMODS.Suits["Fleurons"].card_key, "FLEURON")
    T.assert_eq(SMODS.Suits["Halberds"].card_key, "HALBERD")
    local nodes = { card(2, "Fleurons"), card(5, "Fleurons"), card(9, "Fleurons"),
        card(11, "Fleurons"), card(13, "Fleurons") }
    T.assert_eq(classify(game, nodes), "Flush", "five Fleurons flush")
    T.assert_true(nodes[1]:is_suit("Fleurons"), "is_suit sees the custom suit")
    wipe_mods()
end)

suite.test("spectrum family hands evaluate, with edge cases", function()
    local game = install_pack()
    local name = classify(game, { card(2, "Hearts"), card(5, "Spades"), card(9, "Clubs"),
        card(11, "Diamonds"), card(7, "Fleurons") })
    T.assert_eq(name, "Spectrum", "five distinct suits")
    T.assert_eq(G.selectedHandChips, 50, "Spectrum base chips")
    T.assert_eq(G.selectedHandMult, 6, "Spectrum base mult")
    name = classify(game, { card(5, "Hearts"), card(6, "Spades"), card(7, "Clubs"),
        card(8, "Diamonds"), card(9, "Halberds") })
    T.assert_eq(name, "Straight Spectrum", "straight in five suits")
    name = classify(game, { card(9, "Hearts"), card(9, "Spades"), card(9, "Clubs"),
        card(13, "Diamonds"), card(13, "Fleurons") })
    T.assert_eq(name, "Spectrum House", "full house in five suits")
    name = classify(game, { card(9, "Hearts"), card(9, "Spades"), card(9, "Clubs"),
        card(9, "Diamonds"), card(9, "Fleurons") })
    T.assert_eq(name, "Spectrum Five", "five of a kind in five suits")
    name = classify(game, { card(2, "Hearts"), card(5, "Spades"), card(9, "Clubs"),
        card(11, "Diamonds"), card(12, "Clubs", "wild") })
    T.assert_eq(name, "Spectrum", "a Wild fills the fifth suit")
    name = classify(game, { card(2, "Hearts"), card(5, "Hearts"), card(9, "Clubs"),
        card(11, "Diamonds"), card(7, "Spades") })
    T.assert_eq(name, "High Card", "a duplicated suit is no Spectrum")
    name = classify(game, { card(2, "Hearts"), card(5, "Spades"), card(9, "Clubs"),
        card(11, "Diamonds"), card(13, "Spades", "stone") })
    T.assert_eq(name, "High Card", "a Stone card has no suit to offer")
    wipe_mods()
end)

suite.test("the exotic gate opens on the first Spectrum-family hand", function()
    local game = install_pack()
    T.assert_eq(#SMODS.extra_playing_card_fronts(game), 0, "gate shut: vanilla fronts only")
    T.assert_false(SMODS.in_pool(JOKER_DEFS.j_buncp_zealous.smods), "exotic Jokers out of pool")
    local idx = hand_index(game, "Spectrum")
    T.assert_true(idx ~= nil, "Spectrum is in the handlist")
    game.hand_play_counts[idx] = 1
    local fronts = SMODS.extra_playing_card_fronts(game)
    T.assert_eq(#fronts, 26, "gate open: 13 ranks in each exotic suit")
    local suits = {}
    for _, f in ipairs(fronts) do suits[f.suit] = true end
    T.assert_true(suits["Fleurons"] and suits["Halberds"], "both exotic suits offered")
    T.assert_true(SMODS.in_pool(JOKER_DEFS.j_buncp_zealous.smods), "exotic Jokers in pool")
    game.hand_play_counts[idx] = 0
    T.assert_eq(#SMODS.extra_playing_card_fronts(game), 0, "gate shuts again")
    wipe_mods()
end)

suite.test("registration plate's combination scores as Deal with banked totals", function()
    local game = install_pack()
    local plate = add(game, "j_buncp_registration_plate")
    classify(game, { card(4, "Hearts"), card(4, "Spades") })
    local pair_idx = hand_index(game, "Pair")
    game.hand_play_counts[pair_idx] = 1
    plate.ability.extra.ranks = { 2, 3, 4, 5, 6 }
    local name = classify(game, { card(2, "Hearts"), card(3, "Spades"), card(4, "Clubs"),
        card(5, "Diamonds"), card(6, "Hearts") })
    T.assert_eq(name, "Deal", "the combination hand wins over the Straight")
    local deal_idx = hand_index(game, "Deal")
    T.assert_eq(game.hand_stats[deal_idx].base_chips, 10, "Deal banks the Pair's chips")
    T.assert_eq(game.hand_stats[deal_idx].base_mult, 2, "Deal banks the Pair's mult")
    wipe_mods()
end)

--------------------------------------------------------------------------------
-- v1.1.0: create / destroy / conversion Jokers
--------------------------------------------------------------------------------

suite.test("basement creates a Spectral only on a Boss round", function()
    local game = install_pack()
    local base = add(game, "j_buncp_basement")
    game.current_blind_index = 1
    fire(base, "on_round_end", { game_over = false })
    T.assert_eq(#game.consumables, 0, "small blind: nothing")
    game.current_blind_index = 3
    fire(base, "on_round_end", { game_over = false })
    T.assert_eq(#game.consumables, 1, "boss defeated: one Spectral")
    wipe_mods()
end)

suite.test("carnival destroys a random Joker and rewinds the Ante once", function()
    local game = install_pack()
    local carn = add(game, "j_buncp_carnival")
    add(game, "j_buncp_mosaic")
    game.ante = 2
    game.current_blind_index = 3
    fire(carn, "on_round_end", { game_over = false })
    T.assert_eq(#game.jokers, 1, "the other Joker was destroyed")
    T.assert_eq(game.jokers[1], carn, "Carnival itself survives")
    T.assert_eq(game.ante, 1, "back one Ante")
    fire(carn, "on_round_end", { game_over = false })
    T.assert_eq(game.ante, 1, "no second rewind on a lower Ante")
    wipe_mods()
end)

suite.test("dread levels the last hand by 2, destroys it, and removal reverses", function()
    local game = install_pack()
    local dread = add(game, "j_buncp_dread")
    local a, b = hand_card(game, 5, "Hearts"), hand_card(game, 5, "Spades")
    local pair_idx = hand_index(game, "Pair")
    local level_before = game.hand_stats[pair_idx].level
    local nodes_before = #game.hand.card_nodes
    fire(dread, "on_hand_played", { played_cards = { a, b }, hand_type = "Pair" })
    game.hands = 0
    fire(dread, "on_hand_after", { played_cards = { a, b }, hand_type = "Pair" })
    T.assert_eq(game.hand_stats[pair_idx].level, level_before + 2, "Pair levelled by 2")
    T.assert_eq(#game.hand.card_nodes, nodes_before - 2, "both played cards destroyed")
    game:sell_owned_joker(1)
    T.assert_eq(game.hand_stats[pair_idx].level, level_before, "selling Dread reverses the levels")
    wipe_mods()
end)

suite.test("the joker destroys unenhanced scoring cards on a forced roll", function()
    local game = install_pack()
    local tj = add(game, "j_buncp_the_joker")
    tj.ability.extra.odds = 1
    local a, b, enh = hand_card(game, 5, "Hearts"), hand_card(game, 9, "Spades"),
        hand_card(game, 7, "Clubs", "bonus")
    local nodes_before = #game.hand.card_nodes
    local played = { a, b, enh }
    fire(tj, "on_hand_played", { played_cards = played, cards = played })
    fire(tj, "on_hand_after", { played_cards = played, cards = played })
    T.assert_eq(#game.hand.card_nodes, nodes_before - 2, "both plain cards destroyed")
    local found = false
    for _, nd in ipairs(game.hand.card_nodes) do if nd == enh then found = true end end
    T.assert_true(found, "the enhanced card survives")
    wipe_mods()
end)

suite.test("fondue converts the first hand's scored cards to Fleurons", function()
    local game = install_pack()
    local fon = add(game, "j_buncp_fondue")
    local nodes = { card(2, "Hearts"), card(5, "Spades"), card(9, "Clubs"),
        card(11, "Diamonds"), card(7, "Spades") }
    fire(fon, "on_round_begin", {})
    fire(fon, "on_hand_after", { played_cards = nodes, cards = nodes })
    for _, nd in ipairs(nodes) do
        T.assert_eq(nd.card_data.suit, "Fleurons", "converted to Fleurons")
    end
    local later = { card(3, "Hearts") }
    fire(fon, "on_hand_after", { played_cards = later, cards = later })
    T.assert_eq(later[1].card_data.suit, "Hearts", "only the first hand converts")
    wipe_mods()
end)

suite.test("linocut copies the right card's suit onto the left in a Pair", function()
    local game = install_pack()
    local lino = add(game, "j_buncp_linocut")
    local left, right = card(5, "Hearts"), card(5, "Spades")
    local pair = { left, right }
    fire(lino, "on_hand_after", { played_cards = pair, cards = pair,
        contains_hand_types = { Pair = true }, hand_type = "Pair" })
    T.assert_eq(left.card_data.suit, "Spades", "left card took the right card's suit")
    wipe_mods()
end)

--------------------------------------------------------------------------------
-- v1.1.0: money, state, and temp-chip Jokers
--------------------------------------------------------------------------------

suite.test("loan shark pays $50 on entry and sells for -$100", function()
    local game = install_pack()
    local before_money = game.money
    local shark = add(game, "j_buncp_loan_shark")
    T.assert_eq(game.money - before_money, 50, "+$50 on acquire")
    T.assert_eq(shark.sell_cost, -100, "sell value is -$100")
    wipe_mods()
end)

suite.test("ghost print banks the last hand and pays its totals next hand", function()
    local game = install_pack()
    local gp = add(game, "j_buncp_ghost_print")
    local pair = { card(4), card(4, "Spades") }
    local ctx = scored(gp, { played_cards = pair, hand_type = "Pair" })
    T.assert_eq(ctx.chips, 10, "first hand: nothing banked yet")
    T.assert_eq(gp.ability.extra.last_hand, "Pair", "Pair banked")
    ctx = scored(gp, { played_cards = { card(9) }, hand_type = "High Card" })
    T.assert_eq(ctx.chips, 20, "pays the Pair's 10 Chips on top of the base 10")
    T.assert_eq(ctx.mult, 4, "pays the Pair's 2 Mult on top of the base 2")
    wipe_mods()
end)

suite.test("fingerprints grants +50 Chips for one round, then clears", function()
    local game = install_pack()
    local fp = add(game, "j_buncp_fingerprints")
    game.hands = 3
    local a = hand_card(game, 5, "Hearts")
    fire(fp, "on_hand_after", { played_cards = { a }, cards = { a } })
    fire(fp, "on_round_end", { game_over = false })
    T.assert_eq(a.card_data.Bonus, 50, "scored card carries +50 into the next round")
    fire(fp, "on_round_end", { game_over = false })
    T.assert_eq(a.card_data.Bonus or 0, 0, "cleared at the next round end")
    wipe_mods()
end)

suite.test("bierdeckel marks held cards +10 until round end", function()
    local game = install_pack()
    local bd = add(game, "j_buncp_bierdeckel")
    local played, held = hand_card(game, 5, "Hearts"), hand_card(game, 9, "Clubs")
    fire(bd, "on_hand_after", { played_cards = { played }, cards = { played } })
    T.assert_eq(held.card_data.Bonus, 10, "held card +10")
    T.assert_eq(played.card_data.Bonus or 0, 0, "played card unmarked")
    fire(bd, "on_round_end", { game_over = false })
    T.assert_eq(held.card_data.Bonus or 0, 0, "cleared at round end")
    wipe_mods()
end)

suite.test("righthook retriggers the last scoring card once per hand left", function()
    local game = install_pack()
    local rh = add(game, "j_buncp_righthook")
    game.hands = 3
    local a, b = card(5, "Hearts"), card(9, "Spades")
    local center = JOKER_DEFS.j_buncp_righthook.smods
    local ctx = { repetition = true, cardarea = game.play, other_card = b,
        port = { played_cards = { a, b } } }
    local res = SMODS.call(center.mod, center.calculate, center, rh, ctx)
    T.assert_true(res ~= nil and res.repetitions == 3, "last card: 3 repetitions")
    ctx.other_card = a
    res = SMODS.call(center.mod, center.calculate, center, rh, ctx)
    T.assert_true(res == nil, "not the last card: no retrigger")
    wipe_mods()
end)

suite.test("cassette and crop circles pay on the exotic suits", function()
    local game = install_pack()
    local cas = add(game, "j_buncp_cassette")
    local fleuron, halberd = card(9, "Fleurons"), card(9, "Halberds")
    T.assert_eq(play_card(cas, fleuron, { fleuron }).chips, 45, "side A: Fleurons are light")
    fire(cas, "on_pre_discard", { discarded_nodes = { fleuron } })
    T.assert_eq(play_card(cas, halberd, { halberd }).mult, 7, "side B: Halberds are dark")
    local cc = add(game, "j_buncp_crop_circles")
    T.assert_eq(play_card(cc, card(8, "Fleurons"), { card(8, "Fleurons") }).mult - 1, 6,
        "Crop Circles: Fleuron 8 pays 6")
    wipe_mods()
end)

suite.test("spectrum jokers pay only when the hand contains a Spectrum", function()
    local game = install_pack()
    local zeal = add(game, "j_buncp_zealous")
    local dyn = add(game, "j_buncp_dynasty")
    local wand = add(game, "j_buncp_magic_wand")
    local spec = { card(2, "Hearts"), card(5, "Spades"), card(9, "Clubs"),
        card(11, "Diamonds"), card(7, "Fleurons") }
    local spec_ctx = { played_cards = spec, hand_type = "Spectrum",
        contains_hand_types = { Spectrum = true } }
    T.assert_eq(scored(zeal, spec_ctx).mult, 12, "Zealous +10 on Spectrum")
    T.assert_near(scored(dyn, spec_ctx).mult, 10, 0.001, "Dynasty X5 on Spectrum")
    before(wand, spec_ctx)
    T.assert_eq(scored(wand, spec_ctx).mult, 5, "Magic Wand banked +3 (2 + 3)")
    local plain = { card(2, "Hearts"), card(5, "Hearts") }
    T.assert_eq(scored(zeal, { played_cards = plain, hand_type = "Pair" }).mult, 2,
        "no Spectrum: Zealous quiet")
    fire(wand, "on_hand_after", { played_cards = plain, hand_type = "Pair" })
    T.assert_eq(wand.ability.extra.mult, 0, "a non-Spectrum hand resets the Wand")
    wipe_mods()
end)

suite.test("starfruit levels the played hand when it contains a Spectrum", function()
    local game = install_pack()
    local sf = add(game, "j_buncp_starfruit")
    local idx = hand_index(game, "Spectrum")
    local before_level = game.hand_stats[idx].level
    local spec = { card(2, "Hearts"), card(5, "Spades"), card(9, "Clubs"),
        card(11, "Diamonds"), card(7, "Fleurons") }
    before(sf, { played_cards = spec, hand_type = "Spectrum",
        contains_hand_types = { Spectrum = true } })
    T.assert_eq(game.hand_stats[idx].level, before_level + 1, "Spectrum levelled up")
    wipe_mods()
end)

suite.test("doodle duplicates a used Tarot once per round", function()
    local game = install_pack()
    local dd = add(game, "j_buncp_doodle")
    T.assert_true(game:add_consumable("tarot_fool"), "a Tarot to use")
    local before_n = #game.consumables
    fire(dd, "on_consumable_used", { consumable_id = "tarot_fool", consumable_kind = "tarot" })
    T.assert_eq(#game.consumables, before_n + 1, "the used Tarot was duplicated")
    T.assert_eq(dd.ability.extra.active, false, "spent for this round")
    fire(dd, "on_round_end", { game_over = false })
    T.assert_eq(dd.ability.extra.active, true, "re-armed at round end")
    wipe_mods()
end)

suite.test("xray banks XMult for face-down draws; mousetrap snaps or pays", function()
    local game = install_pack()
    local xr = add(game, "j_buncp_xray")
    local down, up = card(5, "Hearts"), card(9, "Spades")
    down.face_up = false
    up.face_up = true
    fire(xr, "on_hand_drawn", { drawn_cards = { down, up } })
    T.assert_near(xr.ability.extra.xmult, 1.2, 0.001, "one face-down card: X1.2 banked")
    local mt = add(game, "j_buncp_mousetrap")
    mt.ability.extra.odds = 1
    game.hands = 2
    local ctx = scored(mt, { played_cards = { card(4) } })
    T.assert_eq(game.hands, 1, "the trap costs a hand")
    T.assert_eq(ctx.chips, 10, "and the hand scores nothing extra")
    game.hands = 0
    ctx = scored(mt, { played_cards = { card(4) } })
    T.assert_eq(ctx.chips, 310, "no hands left: +300 Chips instead")
    wipe_mods()
end)

suite.test("zero shapiro tags on a face card; juggalo and puzzle board edit editions", function()
    local game = install_pack()
    local zs = add(game, "j_buncp_zero_shapiro")
    zs.ability.extra.odds = 1
    local tags_before = #game.tags
    play_card(zs, card(13, "Hearts"), { card(13, "Hearts") })
    T.assert_eq(#game.tags, tags_before + 1, "a D6 Tag was created")
    local jg = add(game, "j_buncp_juggalo")
    T.assert_true(game:add_consumable("tarot_fool"))
    fire(jg, "on_blind_selected", {})
    T.assert_true(game.consumables[#game.consumables].edition ~= nil, "consumable gained an edition")
    local pb = add(game, "j_buncp_puzzle_board")
    pb.ability.extra.odds = 1
    local target = card(7, "Clubs")
    ensure_hand(game)
    game.hand.highlighted = { target }
    fire(pb, "on_consumable_used", { consumable_id = "tarot_fool", consumable_kind = "tarot" })
    T.assert_true(target.card_data.modifier ~= nil and target.card_data.modifier.edition ~= nil,
        "highlighted card gained an edition")
    wipe_mods()
end)

--------------------------------------------------------------------------------
-- v1.2.0: Fluorescent edition + Neon, Bounty Hunter
--------------------------------------------------------------------------------

suite.test("fluorescent edition registers with no stats and no immunities claimed", function()
    local game = install_pack()
    local entry = SMODS.EditionByValue and SMODS.EditionByValue.fluorescent
    T.assert_true(entry ~= nil, "the Fluorescent edition registers by value")
    T.assert_eq(entry.id or entry.key, "buncp_fluorescent", "under the pack's prefix")
    T.assert_eq(entry.weight, 3.5, "PC weight 18 of Foil's 20, rescaled to the fork's poll")
    -- Empty config: an editioned playing card scores exactly as a plain one.
    local cb, mb, xb = SMODS.playing_card_edition_bonus("fluorescent")
    T.assert_eq(cb, 0, "no chip bonus")
    T.assert_eq(mb, 0, "no mult bonus")
    T.assert_eq(xb, 1, "no xmult")
    T.assert_eq(entry.name, "Fluorescent")
    T.assert_true(type(entry.loc_txt) == "table"
        and type(entry.loc_txt.text) == "table" and #entry.loc_txt.text >= 1,
        "the edition carries its (honest) tooltip text")
    wipe_mods()
end)

suite.test("neon grants fluorescent when a card's enhancement changes", function()
    local game = install_pack()
    local neon = add(game, "j_buncp_neon")

    -- An enhancement change on an editionless card: Fluorescent lands.
    local plain = card(7, "Clubs")
    fire(neon, "on_setting_ability", {
        card_node = plain, ability_kind = "enhancement",
        old = "base", new = "bonus", unchanged = false,
    })
    T.assert_true(plain.card_data.modifier ~= nil
        and plain.card_data.modifier.edition == "fluorescent",
        "the enhanced card gained Fluorescent")

    -- A card that already has an edition keeps it.
    local foiled = card(8, "Clubs")
    foiled.card_data.modifier = { edition = "foil" }
    fire(neon, "on_setting_ability", {
        card_node = foiled, ability_kind = "enhancement",
        old = "base", new = "bonus", unchanged = false,
    })
    T.assert_eq(foiled.card_data.modifier.edition, "foil",
        "an editioned card is not overwritten")

    -- A seal change is not an enhancement.
    local sealed = card(9, "Clubs")
    fire(neon, "on_setting_ability", {
        card_node = sealed, ability_kind = "seal",
        old = "base", new = "gold", unchanged = false,
    })
    T.assert_true(sealed.card_data.modifier == nil
        or sealed.card_data.modifier.edition == nil,
        "a seal change grants nothing")

    -- A re-set to the same enhancement (unchanged) does not fire either.
    local same = card(10, "Clubs")
    fire(neon, "on_setting_ability", {
        card_node = same, ability_kind = "enhancement",
        old = "bonus", new = "bonus", unchanged = true,
    })
    T.assert_true(same.card_data.modifier == nil
        or same.card_data.modifier.edition == nil,
        "an unchanged re-set grants nothing")
    wipe_mods()
end)

suite.test("bounty hunter taxes positive gains and grows mult", function()
    local game = install_pack()
    local bh = add(game, "j_buncp_bounty_hunter")
    T.assert_eq(bh.ability.extra.mult, 0, "starts at +0 Mult")

    -- A positive gain through the real ease_dollars seat: the gain
    -- itself lands $1 short (money_transform, not a separate -$1 event)
    -- and the Mult grows by the bonus.
    local before_money = game.money
    game:ease_dollars(10)
    T.assert_eq(game.money - before_money, 9, "the gain is taxed $1 before it lands")
    T.assert_eq(bh.ability.extra.mult, 1, "and the Joker gains +1 Mult")

    -- Another gain: taxed and grown again.
    before_money = game.money
    game:ease_dollars(3)
    T.assert_eq(game.money - before_money, 2, "every positive gain is taxed")
    T.assert_eq(bh.ability.extra.mult, 2, "Mult keeps growing")

    -- Spending is never transformed: no tax, no growth.
    before_money = game.money
    game:ease_dollars(-5)
    T.assert_eq(game.money - before_money, -5, "spending lands in full")
    T.assert_eq(bh.ability.extra.mult, 2, "no growth on spending")

    -- A second copy taxes the shrinking remainder, as PC's wrapper
    -- does: a $1 gain is fully eaten by the first copy and the second
    -- copy stands down.
    local bh2 = add(game, "j_buncp_bounty_hunter")
    before_money = game.money
    game:ease_dollars(10)
    T.assert_eq(game.money - before_money, 8, "two copies tax the same gain twice")
    T.assert_eq(bh.ability.extra.mult, 3)
    T.assert_eq(bh2.ability.extra.mult, 1)
    before_money = game.money
    game:ease_dollars(1)
    T.assert_eq(game.money - before_money, 0, "a $1 gain is eaten whole by the first copy")
    T.assert_eq(bh.ability.extra.mult, 4, "the first copy still grows")
    T.assert_eq(bh2.ability.extra.mult, 1, "the second copy stands down on an empty gain")

    -- The grown Mult scores at joker_main.
    local ctx = scored(bh)
    T.assert_eq(ctx.mult, 6, "base 2 + the grown +4 Mult")
    wipe_mods()
end)

--------------------------------------------------------------------------------
-- v1.3.0: Fiendish (money_transform), Head in the Clouds (level_up_hand)
--------------------------------------------------------------------------------

suite.test("fiendish pays $1 on a hit and doubles on a miss", function()
    local game = install_pack()
    local fi = add(game, "j_buncp_fiendish")

    -- Forced hit (odds 1 in 1): the gain pays out as $1 instead.
    fi.ability.extra.odds = 1
    local before_money = game.money
    game:ease_dollars(10)
    T.assert_eq(game.money - before_money, 1, "a hit turns a $10 gain into $1")

    -- Forced miss (astronomical odds): the gain doubles.
    fi.ability.extra.odds = 1000000000
    before_money = game.money
    game:ease_dollars(10)
    T.assert_eq(game.money - before_money, 20, "a miss doubles a $10 gain to $20")

    -- Spending is never transformed.
    before_money = game.money
    game:ease_dollars(-5)
    T.assert_eq(game.money - before_money, -5, "spending lands untouched")

    -- A second copy transforms what the first copy left: two forced
    -- misses quadruple the gain, in slot order.
    local fi2 = add(game, "j_buncp_fiendish")
    fi2.ability.extra.odds = 1000000000
    before_money = game.money
    game:ease_dollars(10)
    T.assert_eq(game.money - before_money, 40, "two misses: $10 -> $20 -> $40")
    wipe_mods()
end)

suite.test("head in the clouds levels High Card on other hands' level-ups", function()
    local game = install_pack()
    local head = add(game, "j_buncp_head_in_the_clouds")
    head.ability.extra.odds = 1
    local hc_idx = hand_index(game, "High Card")
    T.assert_true(hc_idx ~= nil, "High Card is in the handlist")

    -- Pool gate (PC's custom_in_pool): shut while High Card is level 1.
    T.assert_false(SMODS.in_pool(JOKER_DEFS.j_buncp_head_in_the_clouds.smods),
        "out of pool until High Card is above level 1")

    -- Another hand levels: High Card rises by exactly 1 -- the Joker's
    -- own level-up does not chain back into it (with odds forced to 1,
    -- an unguarded chain would keep rising to the engine's cap).
    local before_level = game.hand_stats[hc_idx].level
    fire(head, "on_hand_level_up", { hand_name = "Pair", level = 2, amount = 1 })
    T.assert_eq(game.hand_stats[hc_idx].level, before_level + 1,
        "High Card levelled once, and only once")

    -- The pool gate is open now.
    T.assert_true(SMODS.in_pool(JOKER_DEFS.j_buncp_head_in_the_clouds.smods),
        "in pool once High Card is above level 1")

    -- PC's sentinel: a level-up carrying the Joker's own name (what its
    -- own level_up_hand call passes on PC) never triggers it.
    fire(head, "on_hand_level_up", { hand_name = "Head in the Clouds", level = 2, amount = 1 })
    T.assert_eq(game.hand_stats[hc_idx].level, before_level + 1,
        "its own sentinel name does not trigger it")

    -- A missed roll (astronomical odds) levels nothing.
    head.ability.extra.odds = 1000000000
    fire(head, "on_hand_level_up", { hand_name = "Flush", level = 2, amount = 1 })
    T.assert_eq(game.hand_stats[hc_idx].level, before_level + 1,
        "a missed roll leaves High Card alone")
    wipe_mods()
end)

--------------------------------------------------------------------------------
-- v1.4.0: Gameplan / Conquest (Joker debuff), Myopia / Astigmatism
-- (suit aliasing), Sledgehammer / Dwarven / Metallurgist (center overrides)
--------------------------------------------------------------------------------

suite.test("gameplan debuffs both neighbours, pays per neighbour, lifts on sale", function()
    local game = install_pack()
    local left = add(game, "j_buncp_mosaic")
    local gp = add(game, "j_buncp_gameplan")
    local right = add(game, "j_buncp_wino")

    -- Both neighbours are debuffed (the left at Gameplan's add, the
    -- right when it joined the row); Gameplan itself is not.
    T.assert_true(SMODS.joker_debuffed(left), "left neighbour debuffed")
    T.assert_true(SMODS.joker_debuffed(right), "right neighbour debuffed")
    T.assert_false(SMODS.joker_debuffed(gp), "Gameplan itself stays up")

    -- Debuffed neighbours do not calculate.
    local stone = card(9, "Clubs", "stone")
    T.assert_eq(play_card(left, stone, { stone }).mult, 1, "Mosaic silenced by the debuff")
    local heart = card(9, "Hearts")
    T.assert_eq(play_card(right, heart, { heart }).chips, 0, "Wino silenced by the debuff")

    -- Gameplan pays +20 Mult per neighbour that exists.
    local ctx = scored(gp, { played_cards = { card(4) } })
    T.assert_eq(ctx.mult, 42, "two neighbours: 2 base + 40 Mult")

    -- Selling Gameplan lifts both debuffs (PC's remove hook re-evaluates).
    game:sell_owned_joker(2)
    T.assert_false(SMODS.joker_debuffed(left), "left neighbour freed on sale")
    T.assert_false(SMODS.joker_debuffed(right), "right neighbour freed on sale")
    T.assert_eq(play_card(left, stone, { stone }).mult, 7, "Mosaic calculates again")
    wipe_mods()
end)

suite.test("conquest debuffs a random other Joker when the Blind is selected", function()
    local game = install_pack()
    local cq = add(game, "j_buncp_conquest")
    local a = add(game, "j_buncp_mosaic")
    local b = add(game, "j_buncp_wino")
    T.assert_false(SMODS.joker_debuffed(a) or SMODS.joker_debuffed(b),
        "nothing debuffed before a Blind is selected")

    fire(cq, "on_blind_selected", {})
    local da, db = SMODS.joker_debuffed(a), SMODS.joker_debuffed(b)
    T.assert_true(da ~= db, "exactly one of the other Jokers is debuffed")
    T.assert_false(SMODS.joker_debuffed(cq), "Conquest never debuffs itself")

    -- The victim does not calculate; the other still does.
    local stone = card(9, "Clubs", "stone")
    local heart = card(9, "Hearts")
    if da then
        T.assert_eq(play_card(a, stone, { stone }).mult, 1, "victim Mosaic silenced")
        T.assert_eq(play_card(b, heart, { heart }).chips, 12, "the other Joker still pays")
    else
        T.assert_eq(play_card(b, heart, { heart }).chips, 0, "victim Wino silenced")
        T.assert_eq(play_card(a, stone, { stone }).mult, 7, "the other Joker still pays")
    end

    -- Conquest itself pays +200 Chips at joker_main.
    T.assert_eq(scored(cq, { played_cards = { card(4) } }).chips, 210, "+200 Chips")

    -- The next Blind re-picks: still exactly one victim among the two.
    fire(cq, "on_blind_selected", {})
    da, db = SMODS.joker_debuffed(a), SMODS.joker_debuffed(b)
    T.assert_true(da ~= db, "the re-pick leaves exactly one victim")

    -- Selling Conquest lifts the debuff (PC's remove hook re-evaluates).
    game:sell_owned_joker(1)
    T.assert_false(SMODS.joker_debuffed(a) or SMODS.joker_debuffed(b),
        "the victim is freed when Conquest leaves")
    wipe_mods()
end)

suite.test("myopia and astigmatism alias suits while held, undebuffed and exotic-gated", function()
    local game = install_pack()
    -- Exotic pool gate, as on PC (type = 'Exotic').
    T.assert_false(SMODS.in_pool(JOKER_DEFS.j_buncp_myopia.smods), "Myopia exotic-gated")
    T.assert_false(SMODS.in_pool(JOKER_DEFS.j_buncp_astigmatism.smods), "Astigmatism exotic-gated")

    local proud = add(game, "j_buncp_proud")
    local spade = card(9, "Spades")
    T.assert_eq(play_card(proud, spade, { spade }).mult, 1, "a Spade is no Halberd yet")
    T.assert_false(JokerEffects.is_suit("Spades", "Halberds"), "no alias without Myopia")

    local myo = add(game, "j_buncp_myopia")
    T.assert_true(JokerEffects.is_suit("Spades", "Halberds"), "Spades count as Halberds")
    T.assert_true(JokerEffects.is_suit("Clubs", "Halberds"), "Clubs count as Halberds")
    T.assert_false(JokerEffects.is_suit("Hearts", "Halberds"), "red suits are not aliased")
    T.assert_false(JokerEffects.is_suit("Halberds", "Spades"), "the alias is one-way")
    T.assert_eq(play_card(proud, spade, { spade }).mult, 7, "Proud pays on an aliased Spade")

    -- A debuffed Myopia aliases nothing; clearing restores it.
    SMODS.set_joker_debuff(myo, true)
    T.assert_false(JokerEffects.is_suit("Spades", "Halberds"), "debuffed: no alias")
    SMODS.set_joker_debuff(myo, false)
    T.assert_true(JokerEffects.is_suit("Spades", "Halberds"), "cleared: alias back")

    -- Selling Myopia ends the alias with no leak.
    game:sell_owned_joker(2)
    T.assert_false(JokerEffects.is_suit("Spades", "Halberds"), "sold: no alias")

    -- Astigmatism: Hearts and Diamonds count as Fleurons (Envious pays).
    local env = add(game, "j_buncp_envious")
    local heart = card(9, "Hearts")
    T.assert_eq(play_card(env, heart, { heart }).mult, 1, "a Heart is no Fleuron yet")
    add(game, "j_buncp_astigmatism")
    T.assert_true(JokerEffects.is_suit("Hearts", "Fleurons"), "Hearts count as Fleurons")
    T.assert_true(JokerEffects.is_suit("Diamonds", "Fleurons"), "Diamonds count as Fleurons")
    T.assert_eq(play_card(env, heart, { heart }).mult, 7, "Envious pays on an aliased Heart")
    wipe_mods()
end)

local function playing_card(game, rank, suit, enhancement)
    ensure_hand(game)
    return SMODS.add_card { set = "Playing", rank = rank, suit = suit, enhancement = enhancement }
end

suite.test("sledgehammer raises Glass Xmult per copy, divides break odds once, reverts on sell", function()
    local game = install_pack()
    T.assert_false(SMODS.in_pool(JOKER_DEFS.j_buncp_sledgehammer.smods),
        "out of pool with no Glass card in the deck")
    local base = SMODS.center_config("m_glass")
    T.assert_eq(base.Xmult, 2, "vanilla Glass Xmult")
    T.assert_eq(base.extra, 4, "vanilla break odds denominator")

    local s1 = add(game, "j_buncp_sledgehammer")
    local cfg = SMODS.center_config("m_glass")
    T.assert_eq(cfg.Xmult, 3, "one copy: Xmult 3")
    T.assert_eq(cfg.extra, 1, "one copy: odds denominator 4 / 4 = 1")
    local glass = playing_card(game, 9, "Hearts", "glass")
    T.assert_true(SMODS.in_pool(JOKER_DEFS.j_buncp_sledgehammer.smods),
        "in pool once the deck holds a Glass card")
    local gctx = { chips = 0, mult = 1 }
    glass:emit_hand_event("card_played", gctx)
    T.assert_eq(gctx.mult, 3, "a scored Glass card lands the overridden Xmult")

    add(game, "j_buncp_sledgehammer")
    cfg = SMODS.center_config("m_glass")
    T.assert_eq(cfg.Xmult, 4, "a second copy adds its own Xmult")
    T.assert_eq(cfg.extra, 1, "but the odds divide only once")

    game:sell_owned_joker(2)
    game:sell_owned_joker(1)
    cfg = SMODS.center_config("m_glass")
    T.assert_eq(cfg.Xmult, 2, "sold out: Xmult reverts")
    T.assert_eq(cfg.extra, 4, "sold out: odds revert")
    wipe_mods()
end)

suite.test("dwarven lends held Stone cards Steel's Xmult and Gold's dollars", function()
    local game = install_pack()
    T.assert_false(SMODS.in_pool(JOKER_DEFS.j_buncp_dwarven.smods),
        "out of pool with no Stone card in the deck")
    local base = SMODS.center_config("m_stone")
    T.assert_eq(base.h_x_mult, nil, "vanilla Stone has no held Xmult")
    T.assert_eq(base.h_dollars, nil, "vanilla Stone has no held dollars")

    add(game, "j_buncp_dwarven")
    local cfg = SMODS.center_config("m_stone")
    T.assert_eq(cfg.h_x_mult, 1.5, "Stone gains Steel's h_x_mult")
    T.assert_eq(cfg.h_dollars, 3, "Stone gains Gold's h_dollars")
    T.assert_eq(cfg.chips, 50, "Stone's own chips untouched")

    local stone = playing_card(game, 9, "Clubs", "stone")
    T.assert_true(SMODS.in_pool(JOKER_DEFS.j_buncp_dwarven.smods),
        "in pool once the deck holds a Stone card")
    local sctx = { chips = 0, mult = 2 }
    stone:emit_hand_event("held_in_hand", sctx)
    T.assert_eq(sctx.mult, 3, "a held Stone card multiplies with the borrowed Xmult")
    local money = game.money
    stone:emit_hand_event("on_round_end", { chips = 0, mult = 1 })
    T.assert_eq(game.money, money + 3, "a held Stone card pays the borrowed dollars")
    local pctx = { chips = 0, mult = 1 }
    stone:emit_hand_event("card_played", pctx)
    T.assert_eq(pctx.chips, 50, "a played Stone card still scores its own +50 Chips")

    -- PC's add hook lends once per held copy: a second Dwarven doubles.
    add(game, "j_buncp_dwarven")
    cfg = SMODS.center_config("m_stone")
    T.assert_eq(cfg.h_x_mult, 3, "two copies lend double Xmult, as PC stacks")
    T.assert_eq(cfg.h_dollars, 6, "two copies lend double dollars")
    game:sell_owned_joker(2)
    game:sell_owned_joker(1)
    T.assert_eq(SMODS.center_config("m_stone").h_x_mult, nil, "sold out: the loan reverts")
    wipe_mods()
end)

suite.test("metallurgist gives held Gold cards +10 Mult per copy", function()
    local game = install_pack()
    T.assert_false(SMODS.in_pool(JOKER_DEFS.j_buncp_metallurgist.smods),
        "out of pool with no Gold card in the deck")
    add(game, "j_buncp_metallurgist")
    T.assert_eq(SMODS.center_config("m_gold").h_mult, 10, "Gold gains h_mult 10")
    T.assert_eq(SMODS.center_config("m_gold").h_dollars, 3, "Gold's own dollars untouched")

    local gold = playing_card(game, 9, "Diamonds", "gold")
    T.assert_true(SMODS.in_pool(JOKER_DEFS.j_buncp_metallurgist.smods),
        "in pool once the deck holds a Gold card")
    local hctx = { chips = 0, mult = 1 }
    gold:emit_hand_event("held_in_hand", hctx)
    T.assert_eq(hctx.mult, 11, "a held Gold card gives +10 Mult")
    local money = game.money
    gold:emit_hand_event("on_round_end", { chips = 0, mult = 1 })
    T.assert_eq(game.money, money + 3, "Gold's own $3 still pays at round end")

    add(game, "j_buncp_metallurgist")
    local hctx2 = { chips = 0, mult = 1 }
    gold:emit_hand_event("held_in_hand", hctx2)
    T.assert_eq(hctx2.mult, 21, "a second copy gives +20 Mult in total")
    game:sell_owned_joker(2)
    game:sell_owned_joker(1)
    T.assert_eq(SMODS.center_config("m_gold").h_mult, nil, "sold out: h_mult reverts")
    wipe_mods()
end)

--------------------------------------------------------------------------------
-- Wave 6 (v1.5.0)
--------------------------------------------------------------------------------

suite.test("wave6 jmjb: a Standard Pack deals only Enhanced cards", function()
    local game = install_pack()
    add(game, "j_buncp_jmjb")
    game:enter_shop_after_blind()
    game:begin_booster_session({ kind = "booster", pack = "standard",
        size = "normal", price = 4, name = "Standard Pack",
        card_count = 3, picks_granted = 1 })
    local choices = game.booster_session.choices
    T.assert_eq(#choices, 3)
    for _, c in ipairs(choices) do
        T.assert_eq(c.kind, "playing")
        T.assert_true(c.playing_data.enhancement ~= nil,
            "every dealt card is enhanced, got "
            .. tostring(c.playing_data.enhancement))
    end
    game:end_booster_session()
    wipe_mods()
end)

suite.test("wave6 jmjb: other packs are untouched", function()
    local game = install_pack()
    add(game, "j_buncp_jmjb")
    game:enter_shop_after_blind()
    game:begin_booster_session({ kind = "booster", pack = "arcana",
        size = "normal", price = 4, name = "Arcana Pack",
        card_count = 2, picks_granted = 1 })
    for _, c in ipairs(game.booster_session.choices) do
        T.assert_true(c.consumable_def ~= nil, "arcana still deals Tarots")
    end
    game:end_booster_session()
    wipe_mods()
end)

suite.test("wave6 aristocrat: an extra pick from every pack", function()
    local game = install_pack()
    add(game, "j_buncp_aristocrat")
    game:enter_shop_after_blind()
    game:begin_booster_session({ kind = "booster", pack = "arcana",
        size = "normal", price = 4, name = "Arcana Pack",
        card_count = 2, picks_granted = 1 })
    T.assert_eq(game.booster_session.picks_remaining, 2,
        "1 granted + 1 from Aristocrat")
    game:end_booster_session()
    wipe_mods()
end)

suite.test("wave6 doorhanger: Common shop rolls become Uncommon or Rare", function()
    local game = install_pack()
    local dh = add(game, "j_buncp_doorhanger")
    local function rolled_rarity()
        local id = game:_pick_joker_id_shop_rarity_distribution(
            function(lo, hi) return game:random("dhtest", lo, hi) end,
            "sho", {})
        return id and JOKER_DEFS[id] and JOKER_DEFS[id].rarity
    end
    for _ = 1, 60 do
        local r = rolled_rarity()
        T.assert_true(r == 2 or r == 3,
            "no Common while Doorhanger is held, got " .. tostring(r))
    end
    SMODS.set_joker_debuff(dh, true)
    local saw_common = false
    for _ = 1, 60 do
        if rolled_rarity() == 1 then saw_common = true break end
    end
    T.assert_true(saw_common, "debuffed, Doorhanger stands down (PC checks not debuff)")
    wipe_mods()
end)

suite.test("wave6 running joke: a priced Negative Joker joins the shelf", function()
    local game = install_pack()
    add(game, "j_buncp_running_joke")
    game:enter_shop_after_blind()
    local found = nil
    for _, o in ipairs(game.shop_offers) do
        if o.id == "j_joker" and o.edition == "negative" then found = o end
    end
    T.assert_true(found ~= nil, "the Negative Joker offer is shelved")
    T.assert_eq(game:get_shop_offer_price(found), 7,
        "priced like a Joker offer ($2 + $5 Negative), not free")
    wipe_mods()
end)

return suite
