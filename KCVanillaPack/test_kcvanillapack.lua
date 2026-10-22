--- Tests for the KCVanillaPack Balatro3DS mod (not part of the game repo).
--- The mod's real main file is read from the KCV_PACK_LUA env var.
--- Run against the Balatro3DS FORK tree: the five v1.1.0 Jokers need its
--- Tier 1 API (SMODS.add_card / destroy_joker / destroy_card).
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
    "composition", "guard", "chan", "redenvelope", "robo", "tenpin", "handy",
    "energy", "powergrid", "fortunecookie", "rats", "collapse", "loosetooth",
    "scapegoat",
}

local function install_pack()
    wipe_mods()
    local path = os.getenv("KCV_PACK_LUA")
    assert(path, "KCV_PACK_LUA not set")
    local fh = assert(io.open(path, "rb"))
    local main = fh:read("*a")
    fh:close()
    local base = ModLoader.DIR .. "/KCVanillaPack"
    love.filesystem.createDirectory(base)
    love.filesystem.write(base .. "/KCVanillaPack.json", [[{
        "id": "KCVanillaPack", "name": "KCVanilla Pack (3DS Port)", "prefix": "kcvp",
        "main_file": "KCVanillaPack.lua", "version": "1.1.0",
        "author": ["krackocloud", "3DS port"]
    }]])
    love.filesystem.write(base .. "/KCVanillaPack.lua", main)
    for _, n in ipairs(NAMES) do
        love.filesystem.write(base .. "/assets/1x/" .. n .. ".png", "png")
        love.filesystem.write(base .. "/assets/1x/" .. n .. "_negative.png", "png")
    end
    ModLoader.load_all()
    local game = bootstrap.new_game(3301)
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
-- Loading + tooltips
--------------------------------------------------------------------------------

suite.test("pack loads and registers all 14 KCVanilla Jokers", function()
    local game = install_pack()
    local mod = ModLoader.by_id.KCVanillaPack
    T.assert_eq(mod.status, "loaded", tostring(mod.error))
    T.assert_eq(#mod.registered.jokers, 14)
    local expect_new = {
        j_kcvp_fortunecookie = { "Fortune Cookie", 1, 5 },
        j_kcvp_rats = { "Rats!", 2, 6 },
        j_kcvp_collapse = { "Cosmic Collapse", 3, 7 },
        j_kcvp_loosetooth = { "Loose Tooth", 1, 5 },
        j_kcvp_scapegoat = { "Scapegoat", 2, 6 },
    }
    for id, e in pairs(expect_new) do
        local def = JOKER_DEFS[id]
        T.assert_true(def ~= nil, id .. " registered")
        T.assert_eq(def.name, e[1], id .. " name")
        T.assert_eq(def.rarity, e[2], id .. " rarity")
        T.assert_eq(def.cost, e[3], id .. " cost")
    end
    for _, n in ipairs(NAMES) do
        game.jokers = {}
        local j = add(game, "j_kcvp_" .. n)
        local lines = SMODS.tooltip_lines("j_kcvp_" .. n, j)
        T.assert_true(type(lines) == "table" and #lines >= 1, n .. " tooltip has lines")
        local text = table.concat(flatten(lines), " ")
        T.assert_true(text:find("#", 1, true) == nil, n .. " tooltip has no raw placeholder: " .. text)
    end
    wipe_mods()
end)

--------------------------------------------------------------------------------
-- Regression: two of the original nine still behave after the v1.1.0 edit
--------------------------------------------------------------------------------

suite.test("regression: composition and handy still work", function()
    local game = install_pack()
    local comp = add(game, "j_kcvp_composition")
    add(game, "j_kcvp_guard")
    local ctx = scored(comp, { played_cards = { card(4) } })
    T.assert_eq(ctx.chips, 30, "Composition: +20 Chips for the Joker to its right")
    T.assert_eq(ctx.mult, 2, "Composition: no Joker to its left, no Mult")

    local handy = add(game, "j_kcvp_handy")
    local enhanced = card(7, "Clubs", "bonus")
    fire(handy, "on_discard", { card_node = enhanced, discarded_nodes = { enhanced } })
    T.assert_eq(handy.ability.x_mult, 2, "Handy gained X1 on a single enhanced discard")
    ctx = scored(handy, { played_cards = { card(4) } })
    T.assert_eq(ctx.mult, 4, "Handy joker_main returns X2 Mult")
    wipe_mods()
end)

--------------------------------------------------------------------------------
-- Fortune Cookie
--------------------------------------------------------------------------------

suite.test("fortune cookie pays 150, decays 50 per Tarot, and is eaten at zero", function()
    local game = install_pack()
    local cookie = add(game, "j_kcvp_fortunecookie")
    T.assert_eq(scored(cookie, { played_cards = { card(4) } }).chips, 160, "10 base + 150")

    fire(cookie, "on_consumable_used", { consumable_kind = "planet" })
    T.assert_eq(cookie.ability.extra.chips, 150, "a Planet does not decay it")
    fire(cookie, "on_consumable_used", { consumable_kind = "tarot" })
    T.assert_eq(cookie.ability.extra.chips, 100, "first Tarot: -50")
    T.assert_eq(scored(cookie, { played_cards = { card(4) } }).chips, 110, "pays the decayed value")
    fire(cookie, "on_consumable_used", { consumable_kind = "tarot" })
    T.assert_eq(cookie.ability.extra.chips, 50, "second Tarot: -50")

    local before_count = #game.jokers
    fire(cookie, "on_consumable_used", { consumable_kind = "tarot" })
    T.assert_eq(#game.jokers, before_count - 1, "third Tarot eats the cookie (destroy_joker)")
    local still_there = false
    for _, j in ipairs(game.jokers) do if j == cookie then still_there = true end end
    T.assert_false(still_there, "the cookie is gone from G.jokers")
    wipe_mods()
end)

--------------------------------------------------------------------------------
-- Rats!
--------------------------------------------------------------------------------

local function rats_setup(game)
    game.hand = Hand(game)
    game.deck = Deck(game)
    local rats = add(game, "j_kcvp_rats")
    return rats
end

suite.test("rats destroys a random hand card and duplicates itself", function()
    local game = install_pack()
    local rats = rats_setup(game)
    SMODS.add_card { set = "Playing", rank = 4, suit = "Hearts" }
    SMODS.add_card { set = "Playing", rank = 7, suit = "Clubs" }
    SMODS.add_card { set = "Playing", rank = 9, suit = "Spades" }
    T.assert_eq(#game.hand.card_nodes, 3)
    fire(rats, "on_round_begin")
    T.assert_eq(#game.hand.card_nodes, 2, "one hand card destroyed")
    T.assert_eq(#game.deck.discard_pile, 0, "destroyed, not discarded")
    T.assert_eq(#game.jokers, 2, "a copy of Rats! was created")
    T.assert_eq(game.jokers[2].def.id, "j_kcvp_rats", "the copy is Rats! itself")
    wipe_mods()
end)

suite.test("rats copy loses Negative; a one-card hand is left alone", function()
    local game = install_pack()
    local rats = rats_setup(game)
    game.jokers = {}
    local neg = SMODS.add_card { set = "Joker", key = "j_kcvp_rats", edition = "negative" }
    T.assert_true(neg ~= nil, "negative Rats! created")
    T.assert_eq(Joker.normalize_edition(neg.edition), "negative", "the original is Negative")
    SMODS.add_card { set = "Playing", rank = 4, suit = "Hearts" }
    SMODS.add_card { set = "Playing", rank = 7, suit = "Clubs" }
    fire(neg, "on_round_begin")
    T.assert_eq(#game.jokers, 2, "copy created")
    T.assert_true(Joker.normalize_edition(game.jokers[2].edition) ~= "negative",
        "the copy is not Negative")
    wipe_mods()

    local game2 = install_pack()
    local rats2 = rats_setup(game2)
    SMODS.add_card { set = "Playing", rank = 4, suit = "Hearts" }
    fire(rats2, "on_round_begin")
    T.assert_eq(#game2.hand.card_nodes, 1, "one-card hand: nothing destroyed")
    T.assert_eq(#game2.jokers, 1, "one-card hand: no copy")
    wipe_mods()
end)

--------------------------------------------------------------------------------
-- Cosmic Collapse
--------------------------------------------------------------------------------

suite.test("cosmic collapse turns held Planets into Black Holes over rounds", function()
    local game = install_pack()
    game.consumables, game.consumable_nodes = {}, {}
    local collapse = add(game, "j_kcvp_collapse")
    T.assert_true(SMODS.add_card { set = "Planet", key = "planet_mars" } ~= nil)
    T.assert_true(SMODS.add_card { set = "Planet", key = "planet_venus" } ~= nil)
    T.assert_eq(#game.consumables, 2)
    local holes = 0
    for _ = 1, 8 do
        fire(collapse, "on_round_end", { game_over = false })
        T.assert_eq(#game.consumables, 2, "transforms are 1-for-1, nothing lost or duplicated")
        holes = 0
        for _, c in ipairs(game.consumables) do
            T.assert_true(c.kind == "planet" or c.id == "spectral_black_hole",
                "only Planets and Black Holes remain, saw " .. tostring(c.id))
            if c.id == "spectral_black_hole" then holes = holes + 1 end
        end
        if holes > 0 then break end
    end
    T.assert_true(holes > 0, "at least one Planet collapsed within 8 round ends (1-in-2 each)")
    wipe_mods()
end)

--------------------------------------------------------------------------------
-- Loose Tooth
--------------------------------------------------------------------------------

suite.test("loose tooth creates a Tarot for a non-scoring or debuffed Ace only", function()
    local game = install_pack()
    game.consumables, game.consumable_nodes = {}, {}
    local tooth = add(game, "j_kcvp_loosetooth")
    local ace, king = card(14, "Spades"), card(13, "Hearts")
    ace.counts_for_play_score = false
    before(tooth, { played_cards = { ace, king } })
    T.assert_eq(#game.consumables, 1, "non-scoring Ace created a consumable")
    T.assert_eq(game.consumables[1].kind, "tarot", "and it is a Tarot")
    wipe_mods()

    local game2 = install_pack()
    game2.consumables, game2.consumable_nodes = {}, {}
    local tooth2 = add(game2, "j_kcvp_loosetooth")
    local ace2, king2 = card(14, "Spades"), card(13, "Hearts")
    before(tooth2, { played_cards = { ace2, king2 } })
    T.assert_eq(#game2.consumables, 0, "a scoring Ace creates nothing")
    wipe_mods()

    local game3 = install_pack()
    game3.consumables, game3.consumable_nodes = {}, {}
    local tooth3 = add(game3, "j_kcvp_loosetooth")
    local ace3 = card(14, "Spades")
    ace3.debuffed = true
    before(tooth3, { played_cards = { ace3, card(13, "Hearts") } })
    T.assert_eq(#game3.consumables, 1, "a debuffed Ace counts even though it would 'score'")
    wipe_mods()
end)

--------------------------------------------------------------------------------
-- Scapegoat
--------------------------------------------------------------------------------

local function scapegoat_setup(game)
    game.hand = Hand(game)
    game.deck = Deck(game)
    return add(game, "j_kcvp_scapegoat")
end

local function bonus_total(game)
    local total, holders = 0, 0
    for _, node in ipairs(game.hand.card_nodes) do
        local b = tonumber(node.card_data.Bonus) or tonumber(node.card_data.bonus) or 0
        total = total + b
        if b > 0 then holders = holders + 1 end
    end
    return total, holders
end

suite.test("scapegoat destroys the first single discard and banks its chips on a held card", function()
    local game = install_pack()
    local goat = scapegoat_setup(game)
    SMODS.add_card { set = "Playing", rank = 5, suit = "Hearts" }
    local nine = SMODS.add_card { set = "Playing", rank = 9, suit = "Spades" }
    SMODS.add_card { set = "Playing", rank = 3, suit = "Diamonds" }
    T.assert_eq(#game.hand.card_nodes, 3)
    game.deck:push_discard(nine.card_data) -- the game pushes the pile copy before the events
    T.assert_eq(#game.deck.discard_pile, 1)
    fire(goat, "on_discard", {
        card_node = nine, discarded_nodes = { nine }, discarded_cards = { nine.card_data },
    })
    T.assert_eq(#game.hand.card_nodes, 2, "the discarded card was destroyed out of the hand")
    T.assert_eq(#game.deck.discard_pile, 0, "and its pile copy is gone: it left the game")
    local total, holders = bonus_total(game)
    T.assert_eq(total, 9, "the 9's chip value landed on a held card")
    T.assert_eq(holders, 1, "on exactly one held card")

    -- A second discard in the same round is not the first: nothing happens.
    local five = game.hand.card_nodes[1]
    game.deck:push_discard(five.card_data)
    fire(goat, "on_discard", {
        card_node = five, discarded_nodes = { five }, discarded_cards = { five.card_data },
    })
    T.assert_eq(#game.hand.card_nodes, 2, "second discard survives")
    T.assert_eq(#game.deck.discard_pile, 1, "second discard reaches the pile normally")
    local total2 = bonus_total(game)
    T.assert_eq(total2, 9, "no further chips banked")
    wipe_mods()
end)

suite.test("scapegoat with all held cards debuffed still destroys, banks nothing", function()
    local game = install_pack()
    local goat = scapegoat_setup(game)
    local a = SMODS.add_card { set = "Playing", rank = 5, suit = "Hearts" }
    local nine = SMODS.add_card { set = "Playing", rank = 9, suit = "Spades" }
    local b = SMODS.add_card { set = "Playing", rank = 3, suit = "Diamonds" }
    a.debuffed = true
    b.debuffed = true
    game.deck:push_discard(nine.card_data)
    fire(goat, "on_discard", {
        card_node = nine, discarded_nodes = { nine }, discarded_cards = { nine.card_data },
    })
    T.assert_eq(#game.hand.card_nodes, 2, "discarded card destroyed")
    T.assert_eq(#game.deck.discard_pile, 0, "pile copy removed")
    local total = bonus_total(game)
    T.assert_eq(total, 0, "a debuffed recipient banks nothing")
    wipe_mods()
end)

return suite
