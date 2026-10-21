--- Tests for the PokermonPack Balatro3DS mod (not part of the game repo).
--- The mod's real main file is read from the POKE_PACK_LUA env var.
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
    "bulbasaur", "charmander", "squirtle", "caterpie", "metapod", "butterfree",
    "weedle", "kakuna", "beedrill", "pidgey", "pidgeotto", "pidgeot",
    "rattata", "raticate", "ekans", "sandshrew", "diglett", "dugtrio",
    "clefairy", "jigglypuff", "growlithe", "tentacool", "tentacruel",
    "magnemite", "shellder", "cloyster", "krabby", "goldeen", "seaking",
    "mrmime", "pinsir", "pikachu", "magikarp", "rapidash", "articuno",
}

local function install_pack()
    wipe_mods()
    local path = os.getenv("POKE_PACK_LUA")
    assert(path, "POKE_PACK_LUA not set")
    local fh = assert(io.open(path, "rb"))
    local main = fh:read("*a")
    fh:close()
    local base = ModLoader.DIR .. "/PokermonPack"
    love.filesystem.createDirectory(base)
    love.filesystem.write(base .. "/PokermonPack.json", [[{
        "id": "PokermonPack", "name": "Pokermon (3DS port)", "prefix": "pokep",
        "main_file": "pokermonpack.lua", "version": "1.0.0",
        "author": ["InertSteak", "3DS port"]
    }]])
    love.filesystem.write(base .. "/pokermonpack.lua", main)
    for _, n in ipairs(NAMES) do
        love.filesystem.write(base .. "/assets/1x/" .. n .. ".png", "png")
        love.filesystem.write(base .. "/assets/1x/" .. n .. "_negative.png", "png")
    end
    ModLoader.load_all()
    local game = bootstrap.new_game(7702)
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

--------------------------------------------------------------------------------
-- Loading + tooltips
--------------------------------------------------------------------------------

suite.test("pack loads and registers all 35 Pokemon", function()
    local game = install_pack()
    local mod = ModLoader.by_id.PokermonPack
    T.assert_eq(mod.status, "loaded")
    T.assert_eq(#mod.registered.jokers, 35)
    local expect = {
        j_pokep_bulbasaur = { "Bulbasaur", 2, 5 }, j_pokep_charmander = { "Charmander", 2, 5 },
        j_pokep_squirtle = { "Squirtle", 2, 6 }, j_pokep_caterpie = { "Caterpie", 1, 2 },
        j_pokep_butterfree = { "Butterfree", 2, 5 }, j_pokep_beedrill = { "Beedrill", 2, 5 },
        j_pokep_pidgey = { "Pidgey", 1, 5 }, j_pokep_pidgeot = { "Pidgeot", 3, 10 },
        j_pokep_rattata = { "Rattata", 1, 5 }, j_pokep_raticate = { "Raticate", 3, 7 },
        j_pokep_articuno = { "Articuno", 4, 20 }, j_pokep_mrmime = { "Mr. Mime", 3, 8 },
        j_pokep_pikachu = { "Pikachu", 1, 6 }, j_pokep_magikarp = { "Magikarp", 1, 2 },
        j_pokep_cloyster = { "Cloyster", 3, 8 }, j_pokep_rapidash = { "Rapidash", 3, 8 },
    }
    for id, e in pairs(expect) do
        local def = JOKER_DEFS[id]
        T.assert_true(def ~= nil, id .. " registered")
        T.assert_eq(def.name, e[1], id .. " name")
        T.assert_eq(def.rarity, e[2], id .. " rarity")
        T.assert_eq(def.cost, e[3], id .. " cost")
    end
    T.assert_eq(JOKER_DEFS.j_pokep_articuno.blueprint_compat, false)
    T.assert_eq(JOKER_DEFS.j_pokep_charmander.perishable_compat, false)
    T.assert_eq(JOKER_DEFS.j_pokep_cloyster.eternal_compat, false)
    -- passives ride the native modifier fields
    T.assert_eq(JOKER_DEFS.j_pokep_bulbasaur.config.h_size, 1)
    T.assert_eq(JOKER_DEFS.j_pokep_charmander.config.d_size, 1)
    T.assert_eq(JOKER_DEFS.j_pokep_squirtle.config.hands, 1)
    wipe_mods()
end)

suite.test("every tooltip formats with live values", function()
    local game = install_pack()
    game.jokers = {}
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
        game.jokers = {}
        local j = add(game, "j_pokep_" .. n)
        local lines = SMODS.tooltip_lines("j_pokep_" .. n, j)
        T.assert_true(type(lines) == "table" and #lines >= 1, n .. " tooltip has lines")
        local text = table.concat(flatten(lines), " ")
        T.assert_true(text:find("#", 1, true) == nil,
            n .. " tooltip has no raw placeholder: " .. text)
    end
    wipe_mods()
end)

--------------------------------------------------------------------------------
-- Flat + counting jokers via the real scoring pipeline
--------------------------------------------------------------------------------

suite.test("flat Mult and Chips jokers apply in joker_main", function()
    local game = install_pack()
    game.jokers = {}
    local ctx = scored(add(game, "j_pokep_caterpie"))
    T.assert_eq(ctx.mult, 5, "2 base + 3 Caterpie")
    game.jokers = {}
    ctx = scored(add(game, "j_pokep_butterfree"))
    T.assert_eq(ctx.mult, 14, "2 base + 12 Butterfree")
    game.jokers = {}
    ctx = scored(add(game, "j_pokep_beedrill"))
    T.assert_eq(ctx.chips, 90, "10 base + 80 Beedrill")
    game.jokers = {}
    ctx = scored(add(game, "j_pokep_magikarp"))
    T.assert_eq(ctx.chips, 11, "10 base + 1 Magikarp (it tries its best)")
    wipe_mods()
end)

suite.test("pidgey counts distinct ranks and suits", function()
    local game = install_pack()
    game.jokers = {}
    local pidgey = add(game, "j_pokep_pidgey")
    -- pair of 7s, one suit: 1 rank + 1 suit = 2 x +2 = +4
    local hand = { card(7), card(7) }
    local ctx = scored(pidgey, { full_hand = hand, played_cards = hand, cards = hand })
    T.assert_eq(ctx.mult, 6, "2 base + 4 Pidgey")
    wipe_mods()
end)

suite.test("ekans and growlithe check the poker hand", function()
    local game = install_pack()
    game.jokers = {}
    local ekans = add(game, "j_pokep_ekans")
    local straight = { card(5), card(6), card(7), card(8), card(9, "Clubs") }
    local ctx = scored(ekans, { full_hand = straight, played_cards = straight, cards = straight, contains_hand_types = { Straight = true } })
    T.assert_eq(ctx.mult, 12, "2 base + 10 Ekans on a Straight")
    local pair = { card(7), card(7) }
    ctx = scored(ekans, { full_hand = pair, played_cards = pair, cards = pair })
    T.assert_eq(ctx.mult, 2, "no Straight, no Mult")
    game.jokers = {}
    local growlithe = add(game, "j_pokep_growlithe")
    local flush = { card(2), card(5), card(7), card(9), card(11) }
    ctx = scored(growlithe, { full_hand = flush, played_cards = flush, cards = flush, contains_hand_types = { Flush = true } })
    T.assert_eq(ctx.mult, 10, "2 base + 8 Growlithe on a Flush")
    wipe_mods()
end)

suite.test("diglett pays chips for trips and mult for a scoring low card", function()
    local game = install_pack()
    game.jokers = {}
    local diglett = add(game, "j_pokep_diglett")
    local trips = { card(2), card(2, "Clubs"), card(2, "Spades") }
    local ctx = scored(diglett, { full_hand = trips, played_cards = trips, cards = trips, contains_hand_types = { ["Three of a Kind"] = true } })
    T.assert_eq(ctx.chips, 70, "10 base + 60 Diglett")
    T.assert_eq(ctx.mult, 6, "2 base + 4 Diglett (a 2 scored)")
    local high_trips = { card(13), card(13, "Clubs"), card(13, "Spades") }
    ctx = scored(diglett, { full_hand = high_trips, played_cards = high_trips, cards = high_trips, contains_hand_types = { ["Three of a Kind"] = true } })
    T.assert_eq(ctx.chips, 70)
    T.assert_eq(ctx.mult, 2, "no low card, no Mult")
    wipe_mods()
end)

suite.test("individual jokers pay per scored card", function()
    local game = install_pack()
    game.jokers = {}
    local clefairy = add(game, "j_pokep_clefairy")
    local club = card(9, "Clubs")
    local ctx = play_card(clefairy, club, { club })
    T.assert_eq(ctx.mult, 4, "1 base + 3 Clefairy on a Club")
    local heart = card(9, "Hearts")
    ctx = play_card(clefairy, heart, { heart })
    T.assert_eq(ctx.mult, 1, "no Club, no Mult")
    game.jokers = {}
    local tenta = add(game, "j_pokep_tentacool")
    local ten = card(10, "Spades")
    ctx = play_card(tenta, ten, { ten })
    T.assert_eq(ctx.mult, 8, "1 base + 7 Tentacool on a 10")
    game.jokers = {}
    local krabby = add(game, "j_pokep_krabby")
    local king = card(13, "Spades")
    ctx = play_card(krabby, king, { king })
    T.assert_eq(ctx.chips, 20, "Krabby pays 20 Chips on a face card")
    game.jokers = {}
    local mag = add(game, "j_pokep_magnemite")
    local steel = card(10, "Spades", "steel")
    ctx = play_card(mag, steel, { steel })
    T.assert_near(ctx.mult, 1.5, 0.001, "Magnemite X1.5 folds into the card mult")
    local plain = card(10, "Spades")
    ctx = play_card(mag, plain, { plain })
    T.assert_eq(ctx.mult, 1, "no Steel, no XMult")
    wipe_mods()
end)

--------------------------------------------------------------------------------
-- Retriggers through query_retrigger
--------------------------------------------------------------------------------

local function retrigger(joker, rctx)
    return joker:query_retrigger(rctx)
end

suite.test("rattata retriggers only the first two scoring cards", function()
    local game = install_pack()
    game.jokers = {}
    local rattata = add(game, "j_pokep_rattata")
    local a, b, c = card(7), card(8), card(9)
    local played = { a, b, c }
    T.assert_eq(retrigger(rattata, { card_node = a, played_cards = played, held = false }), 1)
    T.assert_eq(retrigger(rattata, { card_node = b, played_cards = played, held = false }), 1)
    T.assert_eq(retrigger(rattata, { card_node = c, played_cards = played, held = false }), 0)
    wipe_mods()
end)

suite.test("shellder needs five scoring cards (and luck)", function()
    local game = install_pack()
    game.jokers = {}
    local shellder = add(game, "j_pokep_shellder")
    local four = { card(2), card(3), card(4), card(5) }
    T.assert_eq(retrigger(shellder, { card_node = four[1], played_cards = four, held = false }), 0,
        "four scoring cards is not five")
    local five = { card(2), card(3), card(4), card(5), card(6) }
    local hits = 0
    for _ = 1, 60 do
        hits = hits + retrigger(shellder, { card_node = five[1], played_cards = five, held = false })
    end
    T.assert_true(hits > 0 and hits < 60, "1-in-3 chance lands sometimes, not always (got " .. hits .. ")")
    wipe_mods()
end)

suite.test("goldeen retriggers held Gold cards; mr. mime the leftmost held card", function()
    local game = install_pack()
    game.jokers = {}
    local goldeen = add(game, "j_pokep_goldeen")
    local gold = card(12, "Spades", "gold")
    local plain = card(12, "Clubs")
    game.hand = { cards = {}, card_nodes = { gold, plain } }
    T.assert_eq(retrigger(goldeen, { card_node = gold, held = true }), 1)
    T.assert_eq(retrigger(goldeen, { card_node = plain, held = true }), 0)
    game.jokers = {}
    local mime = add(game, "j_pokep_mrmime")
    T.assert_eq(retrigger(mime, { card_node = gold, held = true }), 3, "leftmost held card x3")
    T.assert_eq(retrigger(mime, { card_node = plain, held = true }), 0, "not leftmost")
    wipe_mods()
end)

--------------------------------------------------------------------------------
-- Scaling starters, Pikachu, Rapidash, Pinsir, Bulbasaur, Articuno
--------------------------------------------------------------------------------

suite.test("charmander scales when the last discard is gone", function()
    local game = install_pack()
    game.jokers = {}
    local charm = add(game, "j_pokep_charmander")
    game.discards = 2
    before(charm, { played_cards = { card(7) }, full_hand = { card(7) } })
    T.assert_eq(charm.ability.extra.mult, 0, "discards remain: no growth")
    game.discards = 0
    before(charm, { played_cards = { card(7) }, full_hand = { card(7) } })
    T.assert_eq(charm.ability.extra.mult, 1, "no discards left: +1 Mult")
    local ctx = scored(charm)
    T.assert_eq(ctx.mult, 3, "2 base + 1 grown")
    wipe_mods()
end)

suite.test("squirtle scales by remaining hands", function()
    local game = install_pack()
    game.jokers = {}
    local squir = add(game, "j_pokep_squirtle")
    game.hands = 4
    before(squir, { played_cards = { card(7) }, full_hand = { card(7) } })
    T.assert_eq(squir.ability.extra.chips, 4, "+1 per remaining hand x4")
    local ctx = scored(squir)
    T.assert_eq(ctx.chips, 14, "10 base + 4 grown")
    wipe_mods()
end)

suite.test("rapidash grows chips and the growth rate on straights", function()
    local game = install_pack()
    game.jokers = {}
    local rapidash = add(game, "j_pokep_rapidash")
    local straight = { card(5), card(6), card(7), card(8), card(9, "Clubs") }
    before(rapidash, { played_cards = straight, full_hand = straight, contains_hand_types = { Straight = true } })
    T.assert_eq(rapidash.ability.extra.chips, 15)
    T.assert_eq(rapidash.ability.extra.chip_mod, 16)
    before(rapidash, { played_cards = straight, full_hand = straight, contains_hand_types = { Straight = true } })
    T.assert_eq(rapidash.ability.extra.chips, 31, "15 + 16")
    local pair = { card(7), card(7) }
    before(rapidash, { played_cards = pair, full_hand = pair })
    T.assert_eq(rapidash.ability.extra.chips, 31, "no Straight, no growth")
    wipe_mods()
end)

suite.test("pikachu pays poor players at blind select and boosts rich ones", function()
    local game = install_pack()
    game.jokers = {}
    local pika = add(game, "j_pokep_pikachu")
    game.money = 10
    local bctx = { event = "on_blind_selected", event_name = "on_blind_selected" }
    if pika:matches_trigger("on_blind_selected", bctx) then pika:apply_effect(bctx) end
    T.assert_eq(game.money, 12, "$10 + $2 Pikachu")
    game.money = 30
    bctx = { event = "on_blind_selected", event_name = "on_blind_selected" }
    if pika:matches_trigger("on_blind_selected", bctx) then pika:apply_effect(bctx) end
    T.assert_eq(game.money, 30, "already rich: no handout")
    local ctx = scored(pika)
    T.assert_eq(ctx.mult, 12, "2 base + 10 Pikachu at $30")
    game.money = 5
    ctx = scored(pika)
    T.assert_eq(ctx.mult, 2, "poor: no Mult")
    wipe_mods()
end)

suite.test("pinsir needs a held card matching a scored rank", function()
    local game = install_pack()
    game.jokers = {}
    local pinsir = add(game, "j_pokep_pinsir")
    local hand = { card(7), card(7, "Clubs") }
    game.hand = { cards = {}, card_nodes = { card(3, "Spades"), card(9, "Diamonds") } }
    local ctx = scored(pinsir, { full_hand = hand, played_cards = hand, cards = hand })
    T.assert_eq(ctx.mult, 2, "no rank match held")
    game.hand.card_nodes = { card(7, "Spades"), card(9, "Diamonds") }
    ctx = scored(pinsir, { full_hand = hand, played_cards = hand, cards = hand })
    T.assert_true((ctx.xmult or 1) > 1 or ctx.mult > 2, "held 7 matches: Pinsir fires")
    wipe_mods()
end)

suite.test("bulbasaur re-rolls its rank and pays for held matches", function()
    local game = install_pack()
    game.jokers = {}
    local bulb = add(game, "j_pokep_bulbasaur")
    local bctx = { event = "on_blind_selected", event_name = "on_blind_selected" }
    if bulb:matches_trigger("on_blind_selected", bctx) then bulb:apply_effect(bctx) end
    local rank = bulb.ability.extra.target_rank
    T.assert_true(type(rank) == "number" and rank >= 2 and rank <= 14, "rank re-rolled: " .. tostring(rank))
    game.money = 0
    local held = card(rank, "Clubs")
    local hctx = { event = "card_held", event_name = "card_held", card_node = held,
        rank = held.card_data.rank, suit = held.card_data.suit }
    if bulb:matches_trigger("card_held", hctx) then bulb:apply_effect(hctx) end
    T.assert_eq(game.money, 1, "held target rank pays $1")
    local other = card(rank == 14 and 13 or 14, "Clubs")
    hctx = { event = "card_held", event_name = "card_held", card_node = other,
        rank = other.card_data.rank, suit = other.card_data.suit }
    if bulb:matches_trigger("card_held", hctx) then bulb:apply_effect(hctx) end
    T.assert_eq(game.money, 1, "wrong rank pays nothing")
    wipe_mods()
end)

suite.test("articuno foils and seals the first scoring card", function()
    local game = install_pack()
    game.jokers = {}
    local art = add(game, "j_pokep_articuno")
    local first, second = card(5), card(5, "Clubs")
    before(art, { played_cards = { first, second }, full_hand = { first, second } })
    T.assert_eq(first.card_data.modifier and first.card_data.modifier.edition, "foil")
    T.assert_true(first.seal ~= nil, "seal applied: " .. tostring(first.seal))
    T.assert_true(second.card_data.modifier == nil or second.card_data.modifier.edition == nil,
        "second card untouched")
    wipe_mods()
end)

suite.test("sandshrew counts glass cards in the full deck", function()
    local game = install_pack()
    game.jokers = {}
    local shrew = add(game, "j_pokep_sandshrew")
    local hand = { card(7), card(7, "Clubs") }
    game.deck = { cards = {
        { rank = 2, suit = "Hearts" }, { rank = 3, suit = "Clubs" },
        { rank = 4, suit = "Spades" }, { rank = 5, suit = "Diamonds" },
    } }
    local ctx = scored(shrew, { full_hand = hand, played_cards = hand, cards = hand })
    T.assert_eq(ctx.chips, 10, "fresh deck has no Glass")
    game.deck.cards[1].enhancement = "glass"
    game.deck.cards[2].enhancement = "glass"
    ctx = scored(shrew, { full_hand = hand, played_cards = hand, cards = hand })
    T.assert_eq(ctx.chips, 60, "10 base + 2 Glass x 25")
    wipe_mods()
end)

return suite
