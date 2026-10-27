--- Tests for the NeatoPack Balatro3DS mod (not part of the game repo).
--- The mod's real main file is read from the NEATO_PACK_LUA env var.
--- Run against the Balatro3DS FORK tree: the nine v1.1.0 Jokers need its
--- Tier 1 API (SMODS.add_card / destroy_joker / destroy_card, retriggers).
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

-- Joker keys (def ids are j_neatp_<key>).
local KEYS = {
    "unpaid_intern", "tabby_cat", "wild_card_charlie", "lock_in",
    "spare_cutoffs", "ice_cream_sandwich", "australianshepherd",
    "bananastand", "blueyourself", "dayman", "nightman",
    "dogsplayingbalatro", "frostedprimerib", "hatsunejoku", "jokerzd",
}

-- Sprite file base names (not always the key).
local SPRITES = {
    "unpaid_intern", "tabby_cat", "wild_card_charlie", "lock_in",
    "spare_cutoffs", "ice_cream_sandwich", "australian_shepherd",
    "banana_stand", "blue_yourself", "dayman", "nightman",
    "dogs_playing_balatro", "frosted_prime_rib", "hatsune_joku", "jokerzd",
}

local function install_pack()
    wipe_mods()
    local path = os.getenv("NEATO_PACK_LUA")
    assert(path, "NEATO_PACK_LUA not set")
    local fh = assert(io.open(path, "rb"))
    local main = fh:read("*a")
    fh:close()
    local base = ModLoader.DIR .. "/NeatoPack"
    love.filesystem.createDirectory(base)
    love.filesystem.write(base .. "/NeatoPack.json", [[{
        "id": "NeatoPack", "name": "Neato Pack", "prefix": "neatp",
        "main_file": "neatopack.lua", "version": "1.1.0",
        "author": ["neatoqueen", "3DS port"]
    }]])
    love.filesystem.write(base .. "/neatopack.lua", main)
    for _, n in ipairs(SPRITES) do
        love.filesystem.write(base .. "/assets/1x/" .. n .. ".png", "png")
        love.filesystem.write(base .. "/assets/1x/" .. n .. "_negative.png", "png")
    end
    -- Opt-in loader (Wave 7 fixture fix): a pack loads only when its id
    -- is in the saved selection, so write it before load_all.
    love.filesystem.write(ModLoader.ENABLED_PATH, "NeatoPack\n")
    ModLoader.load_all()
    local game = bootstrap.new_game(7720)
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

local function held_card(joker, node)
    local ctx = { event = "card_held", event_name = "card_held", chips = 0, mult = 1,
        card_node = node, card = node.card_data }
    if joker:matches_trigger("card_held", ctx) then joker:apply_effect(ctx) end
    return ctx
end

local function fire(joker, event_name, extra)
    local ctx = { event = event_name, event_name = event_name }
    for k, v in pairs(extra or {}) do ctx[k] = v end
    if joker:matches_trigger(event_name, ctx) then joker:apply_effect(ctx) end
    return ctx
end

local function discard_one(joker, node)
    return fire(joker, "on_discard", { card_node = node, discarded_nodes = { node } })
end

local function held(game, joker)
    for _, j in ipairs(game.jokers or {}) do if j == joker then return true end end
    return false
end

local function hand_setup(game)
    game.hand = Hand(game)
    game.deck = Deck(game)
end

--------------------------------------------------------------------------------
-- Loading + tooltips
--------------------------------------------------------------------------------

suite.test("pack loads and registers all 15 Neato Jokers", function()
    local game = install_pack()
    local mod = ModLoader.by_id.NeatoPack
    T.assert_eq(mod.status, "loaded", tostring(mod.error))
    T.assert_eq(#mod.registered.jokers, 15)
    local expect = {
        j_neatp_unpaid_intern = { "Unpaid Intern", 1, 6 },
        j_neatp_tabby_cat = { "Tabby Cat", 1, 6 },
        j_neatp_wild_card_charlie = { "Wild Card Charlie", 2, 7 },
        j_neatp_lock_in = { "Lock-In Joker", 1, 4 },
        j_neatp_spare_cutoffs = { "Spare Cutoffs", 2, 6 },
        j_neatp_ice_cream_sandwich = { "Ice Cream Sandwich", 2, 6 },
        j_neatp_australianshepherd = { "Australian Shepherd", 1, 4 },
        j_neatp_bananastand = { "The Banana Stand", 1, 6 },
        j_neatp_blueyourself = { "Blue Yourself", 3, 8 },
        j_neatp_dayman = { "Dayman", 2, 6 },
        j_neatp_nightman = { "Nightman", 2, 6 },
        j_neatp_dogsplayingbalatro = { "Dogs Playing Balatro", 3, 6 },
        j_neatp_frostedprimerib = { "Frosted Prime Rib", 2, 6 },
        j_neatp_hatsunejoku = { "Hatsune Joku", 2, 5 },
        j_neatp_jokerzd = { "JokerZD", 3, 8 },
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
    for _, n in ipairs(KEYS) do
        game.jokers = {}
        local j = add(game, "j_neatp_" .. n)
        local lines = SMODS.tooltip_lines("j_neatp_" .. n, j)
        T.assert_true(type(lines) == "table" and #lines >= 1, n .. " tooltip has lines")
        local text = table.concat(flatten(lines), " ")
        T.assert_true(text:find("#", 1, true) == nil, n .. " tooltip has no raw placeholder: " .. text)
    end
    wipe_mods()
end)

--------------------------------------------------------------------------------
-- Original six (regression)
--------------------------------------------------------------------------------

suite.test("unpaid intern pays +40 Chips on scored 9s and 5s", function()
    local game = install_pack()
    local intern = add(game, "j_neatp_unpaid_intern")
    T.assert_eq(play_card(intern, card(9), { card(9) }).chips, 40, "9 pays")
    T.assert_eq(play_card(intern, card(5), { card(5) }).chips, 40, "5 pays")
    T.assert_eq(play_card(intern, card(7), { card(7) }).chips, 0, "7 does not")
    wipe_mods()
end)

suite.test("tabby cat gains +2 Mult every 9 discards", function()
    local game = install_pack()
    local tabby = add(game, "j_neatp_tabby_cat")
    for _ = 1, 8 do discard_one(tabby, card(2)) end
    T.assert_eq(scored(tabby, { played_cards = { card(4) } }).mult, 2, "no gain before 9 discards")
    discard_one(tabby, card(2))
    T.assert_eq(scored(tabby, { played_cards = { card(4) } }).mult, 4, "+2 Mult after 9 discards")
    for _ = 1, 9 do discard_one(tabby, card(3)) end
    T.assert_eq(scored(tabby, { played_cards = { card(4) } }).mult, 6, "+4 Mult after 18 discards")
    wipe_mods()
end)

suite.test("wild card charlie multiplies Wild Cards scored or held", function()
    local game = install_pack()
    local charlie = add(game, "j_neatp_wild_card_charlie")
    local wild, plain = card(9, "Clubs", "wild"), card(9, "Clubs")
    T.assert_near(play_card(charlie, wild, { wild }).mult, 1.5, 0.001, "scored Wild X1.5")
    T.assert_near(held_card(charlie, wild).mult, 1.5, 0.001, "held Wild X1.5")
    T.assert_eq(play_card(charlie, plain, { plain }).mult, 1, "plain card nothing")
    T.assert_eq(held_card(charlie, plain).mult, 1, "held plain nothing")
    wipe_mods()
end)

suite.test("lock-in gains on blind select and resets on a Joker sale", function()
    local game = install_pack()
    local lockin = add(game, "j_neatp_lock_in")
    local other = add(game, "j_neatp_unpaid_intern")
    fire(lockin, "on_blind_selected", {})
    fire(lockin, "on_blind_selected", {})
    T.assert_eq(scored(lockin, { played_cards = { card(4) } }).mult, 8, "+6 Mult after two blinds (2 x (2+6))")
    fire(lockin, "on_joker_sold", { consumable = { kind = "tarot" } })
    T.assert_eq(scored(lockin, { played_cards = { card(4) } }).mult, 8, "a consumable sale does not reset it")
    fire(lockin, "on_joker_sold", { joker = other })
    T.assert_eq(scored(lockin, { played_cards = { card(4) } }).mult, 2, "a Joker sale resets it")
    wipe_mods()
end)

suite.test("spare cutoffs gains +12 Chips per Two Pair", function()
    local game = install_pack()
    local spare = add(game, "j_neatp_spare_cutoffs")
    local hand = { card(4), card(4, "Spades"), card(9), card(9, "Clubs") }
    local function play_with(types)
        local bctx = { event = "on_hand_played", event_name = "on_hand_played", chips = 0, mult = 1,
            played_cards = hand, contains_hand_types = types }
        if spare:matches_trigger("on_hand_played", bctx) then spare:apply_effect(bctx) end
    end
    play_with({ Pair = true })
    T.assert_eq(scored(spare, { played_cards = hand }).chips, 10, "a single Pair banks nothing")
    play_with({ ["Two Pair"] = true })
    T.assert_eq(scored(spare, { played_cards = hand }).chips, 22, "+12 Chips banked (10 base + 12)")
    wipe_mods()
end)

suite.test("ice cream sandwich melts X1 per round and is eaten when it runs out", function()
    local game = install_pack()
    local ics = add(game, "j_neatp_ice_cream_sandwich")
    T.assert_eq(scored(ics, { played_cards = { card(4) } }).mult, 10, "X5 at first")
    fire(ics, "on_round_end", { game_over = false })
    T.assert_eq(scored(ics, { played_cards = { card(4) } }).mult, 8, "X4 after round 1")
    fire(ics, "on_round_end", { game_over = false })
    fire(ics, "on_round_end", { game_over = false })
    T.assert_eq(scored(ics, { played_cards = { card(4) } }).mult, 4, "X2 after round 3")
    fire(ics, "on_round_end", { game_over = false })
    T.assert_false(held(game, ics), "eaten (destroyed) when the X Mult runs out")
    wipe_mods()
end)

--------------------------------------------------------------------------------
-- Australian Shepherd
--------------------------------------------------------------------------------

suite.test("australian shepherd creates a Planet when a Blind is selected", function()
    local game = install_pack()
    game.consumables, game.consumable_nodes = {}, {}
    local dog = add(game, "j_neatp_australianshepherd")
    fire(dog, "on_blind_selected", {})
    T.assert_eq(#game.consumables, 1, "one consumable created")
    T.assert_eq(game.consumables[1].kind, "planet", "and it is a Planet")
    fire(dog, "on_blind_selected", {})
    T.assert_eq(#game.consumables, 2, "one per Blind")
    wipe_mods()
end)

--------------------------------------------------------------------------------
-- The Banana Stand
--------------------------------------------------------------------------------

suite.test("banana stand pays $10 on a 1-in-4 played hand", function()
    local game = install_pack()
    local stand = add(game, "j_neatp_bananastand")
    game.money = 20
    local paid = false
    for _ = 1, 200 do
        fire(stand, "on_hand_played", { played_cards = { card(4) } })
        if game.money == 30 then paid = true break end
        T.assert_true(game.money == 20, "money only ever moves by the $10 payout")
    end
    T.assert_true(paid, "the 1-in-4 payout landed within 200 hands")
    wipe_mods()
end)

suite.test("banana stand is destroyed on a 1-in-25 round end and takes all money", function()
    local game = install_pack()
    local stand = add(game, "j_neatp_bananastand")
    game.money = 30
    local gone = false
    for _ = 1, 600 do
        fire(stand, "on_round_end", { game_over = false })
        if not held(game, stand) then gone = true break end
        T.assert_eq(game.money, 30, "money untouched while the stand survives")
    end
    T.assert_true(gone, "the stand was destroyed within 600 round ends (1-in-25)")
    T.assert_eq(game.money, 0, "all money lost when it was destroyed")
    wipe_mods()
end)

--------------------------------------------------------------------------------
-- Blue Yourself
--------------------------------------------------------------------------------

suite.test("blue yourself retriggers Foil cards and Foil Jokers, and gates its pool on Foils", function()
    local game = install_pack()
    local by = add(game, "j_neatp_blueyourself")

    -- Pool gate: nothing Foil owned yet.
    local center = SMODS.Centers["j_neatp_blueyourself"]
    T.assert_false(SMODS.in_pool(center), "no Foils owned: out of the pool")

    -- Playing cards: a Foil 9 in the play area retriggers once, a plain one never.
    local foil = card(9, "Clubs")
    foil.card_data.modifier = { edition = "foil" }
    T.assert_eq(by:query_retrigger({ card_node = foil }), 1, "Foil played card retriggered once")
    T.assert_eq(by:query_retrigger({ card_node = card(9, "Clubs") }), 0, "plain card not retriggered")
    local heldfoil = card(9, "Clubs")
    heldfoil.card_data.modifier = { edition = "foil" }
    game.hand = Hand(game) -- the real game always has one; the retrigger context keys off it
    T.assert_eq(by:query_retrigger({ card_node = heldfoil, held = true }), 0,
        "a held Foil card is not retriggered (play area only)")

    -- Jokers: a Foil Joker is retriggered by Blue Yourself; a plain one is not.
    local plain_j = add(game, "j_neatp_unpaid_intern")
    T.assert_eq(#SMODS.joker_retriggers(plain_j, { event_name = "on_hand_scored" }), 0,
        "plain Joker not retriggered")
    local foil_j = add(game, "j_neatp_tabby_cat")
    foil_j.edition = Joker.normalize_edition("foil")
    local res = SMODS.joker_retriggers(foil_j, { event_name = "on_hand_scored" })
    T.assert_eq(#res, 1, "Foil Joker retriggered once")
    T.assert_eq(res[1], by, "by Blue Yourself")
    T.assert_true(SMODS.in_pool(center), "a Foil Joker owned: in the pool")

    -- Blue Yourself itself is excluded, even a Foil copy of it.
    by.edition = Joker.normalize_edition("foil")
    T.assert_eq(#SMODS.joker_retriggers(by, { event_name = "on_hand_scored" }), 0,
        "Blue Yourself never retriggers itself")
    wipe_mods()
end)

--------------------------------------------------------------------------------
-- Dayman
--------------------------------------------------------------------------------

local function dayman_setup(game)
    hand_setup(game)
    return add(game, "j_neatp_dayman")
end

suite.test("dayman destroys a lone Queen on the first hand and gains X0.5", function()
    local game = install_pack()
    local day = dayman_setup(game)
    local queen = SMODS.add_card { set = "Playing", rank = 12, suit = "Hearts" }
    T.assert_eq(#game.hand.card_nodes, 1)
    game.round_hands_played = 1
    fire(day, "on_hand_after", { cards = { queen }, full_hand = { queen }, played_cards = { queen } })
    T.assert_eq(#game.hand.card_nodes, 0, "the Queen was destroyed")
    T.assert_eq(#game.deck.discard_pile, 0, "destroyed, not discarded")
    T.assert_near(day.ability.extra.x_mult, 1.5, 0.001, "gained X0.5 Mult")
    T.assert_near(scored(day, { played_cards = { card(4) } }).mult, 3, 0.001, "pays X1.5")
    wipe_mods()
end)

suite.test("dayman leaves other first hands and later lone Queens alone", function()
    local game = install_pack()
    local day = dayman_setup(game)
    local queen = SMODS.add_card { set = "Playing", rank = 12, suit = "Hearts" }
    local king = SMODS.add_card { set = "Playing", rank = 13, suit = "Clubs" }
    game.round_hands_played = 1
    fire(day, "on_hand_after", { cards = { queen, king }, full_hand = { queen, king },
        played_cards = { queen, king } })
    T.assert_eq(#game.hand.card_nodes, 2, "a two-card hand is not a single Queen")
    T.assert_near(day.ability.extra.x_mult, 1, 0.001, "no gain")

    local game2 = install_pack()
    local day2 = dayman_setup(game2)
    local queen2 = SMODS.add_card { set = "Playing", rank = 12, suit = "Hearts" }
    game2.round_hands_played = 2
    fire(day2, "on_hand_after", { cards = { queen2 }, full_hand = { queen2 }, played_cards = { queen2 } })
    T.assert_eq(#game2.hand.card_nodes, 1, "a lone Queen on a later hand survives")
    T.assert_near(day2.ability.extra.x_mult, 1, 0.001, "no gain on later hands")
    wipe_mods()
end)

--------------------------------------------------------------------------------
-- Nightman
--------------------------------------------------------------------------------

suite.test("nightman destroys a random scoring card each hand and gains X0.1", function()
    local game = install_pack()
    hand_setup(game)
    local night = add(game, "j_neatp_nightman")
    local nodes = {}
    for i, r in ipairs({ 4, 7, 9 }) do
        nodes[i] = SMODS.add_card { set = "Playing", rank = r, suit = "Hearts" }
    end
    T.assert_eq(#game.hand.card_nodes, 3)
    local function after()
        fire(night, "on_hand_after", { cards = nodes, full_hand = nodes, played_cards = nodes })
    end
    after()
    T.assert_eq(#game.hand.card_nodes, 2, "one scoring card destroyed")
    T.assert_eq(#game.deck.discard_pile, 0, "destroyed, not discarded")
    T.assert_near(night.ability.extra.x_mult, 1.1, 0.001, "gained X0.1 Mult")
    after()
    T.assert_eq(#game.hand.card_nodes, 1, "one more destroyed next hand")
    T.assert_near(night.ability.extra.x_mult, 1.2, 0.001, "gained X0.1 again")
    T.assert_near(scored(night, { played_cards = { card(4) } }).mult, 2.4, 0.001, "pays X1.2")
    wipe_mods()
end)

--------------------------------------------------------------------------------
-- Dogs Playing Balatro
--------------------------------------------------------------------------------

suite.test("dogs fetch a Spectral on a 1-in-4 when a Planet is used", function()
    local game = install_pack()
    game.consumables, game.consumable_nodes = {}, {}
    local dogs = add(game, "j_neatp_dogsplayingbalatro")
    fire(dogs, "on_consumable_used", { consumable_kind = "tarot" })
    fire(dogs, "on_consumable_used", { consumable_kind = "spectral" })
    T.assert_eq(#game.consumables, 0, "only Planets fetch")
    local fetched = false
    for _ = 1, 200 do
        fire(dogs, "on_consumable_used", { consumable_kind = "planet" })
        if #game.consumables > 0 then fetched = true break end
    end
    T.assert_true(fetched, "a Spectral was fetched within 200 Planet uses (1-in-4)")
    T.assert_eq(game.consumables[1].kind, "spectral", "and it is a Spectral")
    wipe_mods()
end)

--------------------------------------------------------------------------------
-- Frosted Prime Rib
--------------------------------------------------------------------------------

suite.test("frosted prime rib permanently buffs scored cards and is eaten after its hands", function()
    local game = install_pack()
    local rib = add(game, "j_neatp_frostedprimerib")
    local nine = card(9)
    play_card(rib, nine, { nine })
    T.assert_eq(nine.card_data.Bonus, 2, "+2 permanent Chips on the scored card")
    T.assert_eq(nine.card_data.mult_bonus, 1, "+1 permanent Mult on the scored card")
    play_card(rib, nine, { nine })
    T.assert_eq(nine.card_data.Bonus, 4, "the gains stack")
    T.assert_eq(nine.card_data.mult_bonus, 2, "the gains stack")
    local bystander = card(7)
    bystander.counts_for_play_score = false
    play_card(rib, bystander, { bystander })
    T.assert_eq(bystander.card_data.Bonus, nil, "a non-scoring card gains nothing")

    rib.ability.extra.hands = 2
    fire(rib, "on_hand_after", {})
    T.assert_true(held(game, rib), "still here with a hand left")
    T.assert_eq(rib.ability.extra.hands, 1, "one hand counted down")
    fire(rib, "on_hand_after", {})
    T.assert_false(held(game, rib), "eaten when the hands run out")
    wipe_mods()
end)

--------------------------------------------------------------------------------
-- Hatsune Joku
--------------------------------------------------------------------------------

suite.test("hatsune joku retriggers played 9s two additional times", function()
    local game = install_pack()
    local joku = add(game, "j_neatp_hatsunejoku")
    T.assert_eq(joku:query_retrigger({ card_node = card(9) }), 2, "a played 9 retriggers twice")
    T.assert_eq(joku:query_retrigger({ card_node = card(7) }), 0, "other ranks do not")
    game.hand = Hand(game) -- the real game always has one; the retrigger context keys off it
    T.assert_eq(joku:query_retrigger({ card_node = card(9), held = true }), 0,
        "a held 9 does not (play area only)")
    wipe_mods()
end)

--------------------------------------------------------------------------------
-- JokerZD
--------------------------------------------------------------------------------

suite.test("jokerzd gains X0.15 per unique Joker purchased", function()
    local game = install_pack()
    local zd = add(game, "j_neatp_jokerzd")
    fire(zd, "on_shop_buy", { offer_kind = "joker", offer_id = "j_joker" })
    T.assert_near(zd.ability.extra.x_mult, 1.15, 0.001, "first unique Joker: +X0.15")
    fire(zd, "on_shop_buy", { offer_kind = "joker", offer_id = "j_joker" })
    T.assert_near(zd.ability.extra.x_mult, 1.15, 0.001, "buying the same Joker again does not count")
    fire(zd, "on_shop_buy", { offer_kind = "joker", offer_id = "j_gros_michel" })
    T.assert_near(zd.ability.extra.x_mult, 1.30, 0.001, "a second unique Joker counts")
    fire(zd, "on_shop_buy", { offer_kind = "tarot", offer_id = "tarot_fool" })
    T.assert_near(zd.ability.extra.x_mult, 1.30, 0.001, "consumable purchases do not count")
    fire(zd, "on_shop_buy", { offer_kind = "joker", offer_id = "j_neatp_jokerzd" })
    T.assert_near(zd.ability.extra.x_mult, 1.30, 0.001, "buying JokerZD itself does not count")
    T.assert_near(scored(zd, { played_cards = { card(4) } }).mult, 2.6, 0.001, "pays X1.3")
    wipe_mods()
end)

return suite
