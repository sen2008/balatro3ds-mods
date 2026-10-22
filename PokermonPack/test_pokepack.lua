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
    "bulbasaur", "ivysaur", "venusaur", "charmander", "charmeleon", "charizard",
    "squirtle", "wartortle", "blastoise", "caterpie", "metapod", "butterfree",
    "weedle", "kakuna", "beedrill", "pidgey", "pidgeotto", "pidgeot",
    "rattata", "raticate", "ekans", "arbok", "sandshrew", "sandslash",
    "diglett", "dugtrio", "clefairy", "clefable", "jigglypuff", "wigglytuff",
    "growlithe", "arcanine", "tentacool", "tentacruel",
    "magnemite", "magneton", "shellder", "cloyster", "krabby", "kingler",
    "goldeen", "seaking", "mrmime", "pinsir", "pikachu", "raichu",
    "magikarp", "gyarados", "rapidash", "articuno",
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
        "main_file": "pokermonpack.lua", "version": "1.2.0",
        "author": ["InertSteak", "3DS port"]
    }]])
    love.filesystem.write(base .. "/pokermonpack.lua", main)
    for _, n in ipairs(NAMES) do
        love.filesystem.write(base .. "/assets/1x/" .. n .. ".png", "png")
        love.filesystem.write(base .. "/assets/1x/" .. n .. "_negative.png", "png")
    end
    for _, n in ipairs({ "firestone", "waterstone", "thunderstone", "moonstone" }) do
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

suite.test("pack loads and registers all 50 Pokemon", function()
    local game = install_pack()
    local mod = ModLoader.by_id.PokermonPack
    T.assert_eq(mod.status, "loaded")
    T.assert_eq(#mod.registered.jokers, 50)
    local expect = {
        j_pokep_bulbasaur = { "Bulbasaur", 2, 5 }, j_pokep_charmander = { "Charmander", 2, 5 },
        j_pokep_squirtle = { "Squirtle", 2, 6 }, j_pokep_caterpie = { "Caterpie", 1, 2 },
        j_pokep_butterfree = { "Butterfree", 2, 5 }, j_pokep_beedrill = { "Beedrill", 2, 5 },
        j_pokep_pidgey = { "Pidgey", 1, 5 }, j_pokep_pidgeot = { "Pidgeot", 3, 10 },
        j_pokep_rattata = { "Rattata", 1, 5 }, j_pokep_raticate = { "Raticate", 3, 7 },
        j_pokep_articuno = { "Articuno", 4, 20 }, j_pokep_mrmime = { "Mr. Mime", 3, 8 },
        j_pokep_pikachu = { "Pikachu", 1, 6 }, j_pokep_magikarp = { "Magikarp", 1, 2 },
        j_pokep_cloyster = { "Cloyster", 3, 8 }, j_pokep_rapidash = { "Rapidash", 3, 8 },
        j_pokep_ivysaur = { "Ivysaur", 3, 9 }, j_pokep_venusaur = { "Venusaur", 3, 10 },
        j_pokep_charmeleon = { "Charmeleon", 3, 8 }, j_pokep_charizard = { "Charizard", 3, 10 },
        j_pokep_wartortle = { "Wartortle", 3, 8 }, j_pokep_blastoise = { "Blastoise", 3, 10 },
        j_pokep_arbok = { "Arbok", 2, 7 }, j_pokep_raichu = { "Raichu", 3, 8 },
        j_pokep_sandslash = { "Sandslash", 3, 6 }, j_pokep_clefable = { "Clefable", 3, 10 },
        j_pokep_wigglytuff = { "Wigglytuff", 3, 10 }, j_pokep_arcanine = { "Arcanine", 3, 8 },
        j_pokep_magneton = { "Magneton", 3, 8 }, j_pokep_kingler = { "Kingler", 2, 7 },
        j_pokep_gyarados = { "Gyarados", 3, 10 },
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
    T.assert_eq(JOKER_DEFS.j_pokep_ivysaur.config.h_size, 1)
    T.assert_eq(JOKER_DEFS.j_pokep_venusaur.config.h_size, 1)
    T.assert_eq(JOKER_DEFS.j_pokep_charmander.config.d_size, 1)
    T.assert_eq(JOKER_DEFS.j_pokep_charizard.config.d_size, 1)
    T.assert_eq(JOKER_DEFS.j_pokep_squirtle.config.hands, 1)
    T.assert_eq(JOKER_DEFS.j_pokep_wartortle.config.hands, 1)
    T.assert_eq(JOKER_DEFS.j_pokep_blastoise.config.hands, 1)
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

--------------------------------------------------------------------------------
-- Evolution (fork Tier 1: destroy + create at the round-end step)
--------------------------------------------------------------------------------

local function round_end(joker)
    local ctx = { event = "on_round_end", event_name = "on_round_end", game_over = false }
    if joker:matches_trigger("on_round_end", ctx) then joker:apply_effect(ctx) end
    return ctx
end

local function only_joker(game)
    T.assert_eq(#game.jokers, 1, "exactly one Joker after evolution")
    return game.jokers[1]
end

suite.test("caterpie evolves to metapod, then butterfree", function()
    local game = install_pack()
    game.jokers = {}
    local cat = add(game, "j_pokep_caterpie")
    round_end(cat)
    T.assert_eq(only_joker(game).def.id, "j_pokep_caterpie", "1 of 2 rounds: still Caterpie")
    T.assert_eq(cat.ability.extra.rounds, 1, "counter ticked down")
    round_end(cat)
    local meta = only_joker(game)
    T.assert_eq(meta.def.id, "j_pokep_metapod", "2 rounds: Metapod")
    T.assert_eq(meta.ability.extra.mult, 6, "Metapod's own +6 Mult")
    round_end(meta)
    round_end(meta)
    T.assert_eq(only_joker(game).def.id, "j_pokep_metapod", "2 of 3 rounds: still Metapod")
    round_end(meta)
    local bf = only_joker(game)
    T.assert_eq(bf.def.id, "j_pokep_butterfree", "3 more rounds: Butterfree")
    local ctx = scored(bf)
    T.assert_eq(ctx.mult, 14, "2 base + 12 Butterfree")
    wipe_mods()
end)

suite.test("evolution preserves the edition", function()
    local game = install_pack()
    game.jokers = {}
    T.assert_true(game:add_joker_by_def("j_pokep_caterpie", { edition = "foil" }))
    local cat = game.jokers[#game.jokers]
    T.assert_eq(cat.edition, "foil")
    round_end(cat)
    round_end(cat)
    local meta = only_joker(game)
    T.assert_eq(meta.def.id, "j_pokep_metapod")
    T.assert_eq(meta.edition, "foil", "foil carries through evolution")
    wipe_mods()
end)

suite.test("charmander evolves on grown Mult and keeps it", function()
    local game = install_pack()
    game.jokers = {}
    local charm = add(game, "j_pokep_charmander")
    charm.ability.extra.mult = 15
    round_end(charm)
    T.assert_eq(only_joker(game).def.id, "j_pokep_charmander", "+15 Mult: not yet")
    charm.ability.extra.mult = 16
    round_end(charm)
    local meleon = only_joker(game)
    T.assert_eq(meleon.def.id, "j_pokep_charmeleon", "+16 Mult: Charmeleon")
    T.assert_eq(meleon.ability.extra.mult, 16, "grown Mult carries over")
    meleon.ability.extra.mult = 36
    round_end(meleon)
    local zard = only_joker(game)
    T.assert_eq(zard.def.id, "j_pokep_charizard", "+36 Mult: Charizard")
    T.assert_eq(zard.ability.extra.mult, 36, "Charizard starts from the carried Mult")
    game.discards = 0
    local ctx = scored(zard)
    T.assert_eq(ctx.mult, 57, "(2 base + 36) x 1.5 Fire Blast at 0 discards")
    game.discards = 2
    ctx = scored(zard)
    T.assert_eq(ctx.mult, 38, "discards left: flat +36, no X1.5")
    wipe_mods()
end)

suite.test("squirtle evolves on grown Chips and keeps them", function()
    local game = install_pack()
    game.jokers = {}
    local squir = add(game, "j_pokep_squirtle")
    squir.ability.extra.chips = 39
    round_end(squir)
    T.assert_eq(only_joker(game).def.id, "j_pokep_squirtle", "+39 Chips: not yet")
    squir.ability.extra.chips = 55
    round_end(squir)
    local wart = only_joker(game)
    T.assert_eq(wart.def.id, "j_pokep_wartortle", "past +40: Wartortle")
    T.assert_eq(wart.ability.extra.chips, 55, "grown Chips carry (55 > Wartortle's 40)")
    wart.ability.extra.chips = 120
    round_end(wart)
    local blast = only_joker(game)
    T.assert_eq(blast.def.id, "j_pokep_blastoise", "+120: Blastoise")
    game.hands = 2
    local ctx = scored(blast)
    T.assert_eq(ctx.chips, 180, "10 base + 120 + 25 x 2 hands left")
    wipe_mods()
end)

suite.test("bulbasaur evolves after earning $16 as Bulbasaur", function()
    local game = install_pack()
    game.jokers = {}
    local bulb = add(game, "j_pokep_bulbasaur")
    bulb.ability.extra.earned = 15
    round_end(bulb)
    T.assert_eq(only_joker(game).def.id, "j_pokep_bulbasaur", "$15 earned: not yet")
    bulb.ability.extra.earned = 16
    round_end(bulb)
    local ivy = only_joker(game)
    T.assert_eq(ivy.def.id, "j_pokep_ivysaur", "$16 earned: Ivysaur")
    T.assert_eq(ivy.ability.extra.earned, 0, "the evolved form earns its own $16")
    ivy.ability.extra.target_rank = 9
    ivy.ability.extra.earned = 16
    round_end(ivy)
    T.assert_eq(only_joker(game).def.id, "j_pokep_venusaur", "Ivysaur's $16: Venusaur")
    wipe_mods()
end)

suite.test("stone chains need their stone; unmet conditions never evolve", function()
    local game = install_pack()
    game.jokers = {}
    local pika = add(game, "j_pokep_pikachu")
    for _ = 1, 10 do round_end(pika) end
    T.assert_eq(only_joker(game).def.id, "j_pokep_pikachu",
        "round end alone never evolves Pikachu: it needs the Thunder Stone")
    game.jokers = {}
    local shell = add(game, "j_pokep_shellder")
    for _ = 1, 10 do round_end(shell) end
    T.assert_eq(only_joker(game).def.id, "j_pokep_shellder",
        "round end alone never evolves Shellder: it needs the Water Stone")
    game.jokers = {}
    local karp = add(game, "j_pokep_magikarp")
    for _ = 1, 7 do round_end(karp) end
    T.assert_eq(only_joker(game).def.id, "j_pokep_magikarp", "7 of 8 rounds: still Magikarp")
    round_end(karp)
    local gyar = only_joker(game)
    T.assert_eq(gyar.def.id, "j_pokep_gyarados", "8 rounds: Gyarados")
    local ctx = scored(gyar)
    T.assert_eq(ctx.mult, 5, "2 base x 2.5 Gyarados")
    wipe_mods()
end)

suite.test("evolved forms work standalone: raichu, gyarados line, kingler, arcanine", function()
    local game = install_pack()
    game.jokers = {}
    local rai = add(game, "j_pokep_raichu")
    game.money = 25
    local bctx = { event = "on_blind_selected", event_name = "on_blind_selected" }
    if rai:matches_trigger("on_blind_selected", bctx) then rai:apply_effect(bctx) end
    T.assert_eq(game.money, 30, "$25 + $5 interest at blind select")
    local ctx = scored(rai)
    T.assert_eq(ctx.mult, 14, "2 base + 4 x floor(30/10) Raichu")
    game.jokers = {}
    local king = add(game, "j_pokep_kingler")
    local face = card(12, "Spades")
    local plain = card(7)
    before(king, { played_cards = { face, plain }, full_hand = { face, plain },
        cards = { face, plain } })
    T.assert_eq(face.card_data.enhancement, "bonus", "scoring face card becomes Bonus")
    T.assert_true(plain.card_data.enhancement == nil, "non-face card untouched")
    local pctx = play_card(king, face, { face })
    T.assert_eq(pctx.chips, 20, "Kingler pays 20 Chips on a face card")
    game.jokers = {}
    local arc = add(game, "j_pokep_arcanine")
    local a1, a2 = card(3), card(4)
    local flush = { a1, a2, card(6), card(8), card(10) }
    before(arc, { played_cards = flush, full_hand = flush, cards = flush,
        contains_hand_types = { Flush = true } })
    T.assert_eq(a1.card_data.enhancement, "mult", "first scoring card becomes Mult")
    T.assert_true(a2.card_data.enhancement == nil, "only the first card converts")
    ctx = scored(arc, { full_hand = flush, played_cards = flush, cards = flush,
        contains_hand_types = { Flush = true } })
    T.assert_near(ctx.mult, 3, 0.001, "2 base x 1.5 Arcanine on a Flush")
    wipe_mods()
end)

--------------------------------------------------------------------------------
-- Evolution stones (fork SMODS.ConsumableType, pack v1.2.0)
--------------------------------------------------------------------------------

local STONE_IDS = {
    c_pokep_firestone = true, c_pokep_waterstone = true,
    c_pokep_thunderstone = true, c_pokep_moonstone = true,
}

local function stone_setup()
    local game = install_pack()
    game.jokers = {}
    game.consumables, game.consumable_nodes = {}, {}
    game.STATE = game.STATES.SHOP
    return game
end

-- Add a stone to the consumable area; returns its slot index.
local function hold_stone(game, id)
    T.assert_true(game:add_consumable(id), id .. " should be addable")
    return #game.consumables
end

suite.test("stones register under the pack's own poke_item type", function()
    local game = install_pack()
    local mod = ModLoader.by_id.PokermonPack
    T.assert_eq(#mod.registered.consumables, 4, "four stones register as consumables")
    local entry = SMODS.ConsumableTypes["pokep_poke_item"]
    T.assert_true(entry ~= nil, "the poke_item type registers")
    T.assert_eq(entry.kind, "poke_item")
    T.assert_eq(entry.shop_rate, 4, "PC registers poke_item at shop_rate 4")
    T.assert_true(game:is_consumable_kind("poke_item"))
    for id in pairs(STONE_IDS) do
        local def = CONSUMABLE_DEFS[id]
        T.assert_true(def ~= nil, id .. " registered")
        T.assert_eq(def.kind, "poke_item", id .. " carries the type's kind")
        T.assert_eq(def.cost, 4, id .. " costs $4, as on PC")
        local lines = SMODS.tooltip_lines(id, def)
        T.assert_true(type(lines) == "table" and #lines >= 1, id .. " tooltip has lines")
    end
    -- The kind's own pool is exactly the four stones.
    for _ = 1, 40 do
        local rolled = game:random_consumable_id_of_kind("poke_item", nil, "stone")
        T.assert_true(STONE_IDS[rolled] == true, "kind pool rolls only stones: " .. tostring(rolled))
    end
    -- Tier 1 creation resolves the custom set name too.
    game.consumables, game.consumable_nodes = {}, {}
    local made = SMODS.add_card { set = "poke_item", key = "c_pokep_moonstone" }
    T.assert_true(made ~= nil and made.id == "c_pokep_moonstone" and made.kind == "poke_item",
        "add_card creates a stone by set name")
    wipe_mods()
end)

suite.test("stones appear in the shop roll at their type's rate", function()
    local game = install_pack()
    game.consumables, game.shop_offers = {}, {}
    local seen = 0
    for ante = 1, 400 do
        game.ante = ante
        local offer = game:_generate_next_shop_queue_offer()
        if offer and offer.kind == "poke_item" then
            seen = seen + 1
            T.assert_true(STONE_IDS[offer.id] == true,
                "a poke_item offer is always a stone: " .. tostring(offer.id))
        end
    end
    T.assert_true(seen > 0, "poke_item offers roll (got " .. seen .. " in 400)")
    wipe_mods()
end)

suite.test("each stone evolves its own line and refuses the others", function()
    -- Thunder Stone: Pikachu -> Raichu.
    local game = stone_setup()
    local pika = add(game, "j_pokep_pikachu")
    local slot = hold_stone(game, "c_pokep_thunderstone")
    T.assert_true(game:consumable_use_enabled(slot), "a held Pikachu makes the stone usable")
    T.assert_true(game:use_consumable(slot))
    T.assert_eq(#game.consumables, 0, "the stone is spent")
    T.assert_eq(only_joker(game).def.id, "j_pokep_raichu", "Pikachu evolved into Raichu")
    wipe_mods()

    -- Fire Stone refuses Pikachu (wrong stone for the line).
    game = stone_setup()
    add(game, "j_pokep_pikachu")
    slot = hold_stone(game, "c_pokep_firestone")
    T.assert_false(game:consumable_use_enabled(slot), "Fire Stone has no target in a lone Pikachu")
    T.assert_false(game:use_consumable(slot), "and cannot be used")
    T.assert_eq(#game.consumables, 1, "the refused stone stays held")
    T.assert_eq(only_joker(game).def.id, "j_pokep_pikachu", "nothing evolved")
    wipe_mods()

    -- Fire Stone: Growlithe -> Arcanine.
    game = stone_setup()
    add(game, "j_pokep_growlithe")
    slot = hold_stone(game, "c_pokep_firestone")
    T.assert_true(game:consumable_use_enabled(slot))
    T.assert_true(game:use_consumable(slot))
    T.assert_eq(only_joker(game).def.id, "j_pokep_arcanine", "Growlithe evolved into Arcanine")
    wipe_mods()

    -- Water Stone: Shellder -> Cloyster.
    game = stone_setup()
    add(game, "j_pokep_shellder")
    slot = hold_stone(game, "c_pokep_waterstone")
    T.assert_true(game:consumable_use_enabled(slot))
    T.assert_true(game:use_consumable(slot))
    local cloy = only_joker(game)
    T.assert_eq(cloy.def.id, "j_pokep_cloyster", "Shellder evolved into Cloyster")
    T.assert_eq(cloy.ability.extra.dem, 2, "Cloyster's own 1-in-2, not Shellder's 1-in-3")
    wipe_mods()

    -- Moon Stone covers both of its lines.
    game = stone_setup()
    add(game, "j_pokep_clefairy")
    slot = hold_stone(game, "c_pokep_moonstone")
    T.assert_true(game:consumable_use_enabled(slot))
    T.assert_true(game:use_consumable(slot))
    T.assert_eq(only_joker(game).def.id, "j_pokep_clefable", "Clefairy evolved into Clefable")
    wipe_mods()

    game = stone_setup()
    add(game, "j_pokep_jigglypuff")
    slot = hold_stone(game, "c_pokep_moonstone")
    T.assert_true(game:consumable_use_enabled(slot))
    T.assert_true(game:use_consumable(slot))
    T.assert_eq(only_joker(game).def.id, "j_pokep_wigglytuff", "Jigglypuff evolved into Wigglytuff")
    wipe_mods()
end)

suite.test("stones need a valid target: none held, wrong line, debuffed, Magneton", function()
    -- No Jokers at all.
    local game = stone_setup()
    local slot = hold_stone(game, "c_pokep_thunderstone")
    T.assert_false(game:consumable_use_enabled(slot), "no Jokers: not usable")
    wipe_mods()

    -- A Joker no stone evolves.
    game = stone_setup()
    add(game, "j_pokep_caterpie")
    slot = hold_stone(game, "c_pokep_moonstone")
    T.assert_false(game:consumable_use_enabled(slot), "Caterpie is not a Moon Stone target")
    wipe_mods()

    -- Magneton is not a Thunder Stone target in this pack (its PC
    -- evolution, Magnezone, is not in the pack).
    game = stone_setup()
    add(game, "j_pokep_magneton")
    slot = hold_stone(game, "c_pokep_thunderstone")
    T.assert_false(game:consumable_use_enabled(slot), "Magneton refuses the Thunder Stone here")
    T.assert_false(game:use_consumable(slot))
    T.assert_eq(only_joker(game).def.id, "j_pokep_magneton", "Magneton stays Magneton")
    wipe_mods()

    -- The evolved form is not a target either (already evolved).
    game = stone_setup()
    add(game, "j_pokep_raichu")
    slot = hold_stone(game, "c_pokep_thunderstone")
    T.assert_false(game:consumable_use_enabled(slot), "Raichu cannot evolve further")
    wipe_mods()

    -- A debuffed target is skipped, as on PC.
    game = stone_setup()
    local growl = add(game, "j_pokep_growlithe")
    growl.debuff = true
    slot = hold_stone(game, "c_pokep_firestone")
    T.assert_false(game:consumable_use_enabled(slot), "a debuffed Growlithe is not a target")
    wipe_mods()
end)

suite.test("a stone evolves the leftmost eligible Joker", function()
    local game = stone_setup()
    add(game, "j_pokep_jigglypuff")
    add(game, "j_pokep_clefairy")
    local slot = hold_stone(game, "c_pokep_moonstone")
    T.assert_true(game:use_consumable(slot))
    -- The destroy+create swap puts the evolved form in the last slot,
    -- so the list reads {Clefairy, Wigglytuff}: it was the leftmost
    -- target (Jigglypuff) that evolved, not Clefairy.
    T.assert_eq(game.jokers[1].def.id, "j_pokep_clefairy",
        "Clefairy is untouched: the leftmost target was Jigglypuff")
    T.assert_eq(game.jokers[2].def.id, "j_pokep_wigglytuff",
        "Jigglypuff (the leftmost eligible Joker) evolved")
    slot = hold_stone(game, "c_pokep_moonstone")
    T.assert_true(game:use_consumable(slot))
    T.assert_eq(game.jokers[2].def.id, "j_pokep_clefable",
        "a second Moon Stone evolves the remaining Clefairy")
    wipe_mods()
end)

suite.test("stone evolution preserves the edition and grown scaling", function()
    -- Edition: a Foil Pikachu becomes a Foil Raichu.
    local game = stone_setup()
    T.assert_true(game:add_joker_by_def("j_pokep_pikachu", { edition = "foil" }))
    local pika = game.jokers[#game.jokers]
    T.assert_eq(pika.edition, "foil")
    local slot = hold_stone(game, "c_pokep_thunderstone")
    T.assert_true(game:use_consumable(slot))
    local rai = only_joker(game)
    T.assert_eq(rai.def.id, "j_pokep_raichu")
    T.assert_eq(rai.edition, "foil", "foil carries through the stone evolution")
    T.assert_eq(rai.ability.extra.mult_mod, 4, "Raichu starts from its own config")
    wipe_mods()

    -- Grown scaling: put a grown Chips total on Jigglypuff the way a
    -- scaling Joker holds one (total with its *_mod beside it), and it
    -- carries into Wigglytuff exactly as the Charmander/Squirtle chains
    -- carry theirs -- the stone uses the same poke_evolve call.
    game = stone_setup()
    local jig = add(game, "j_pokep_jigglypuff")
    jig.ability.extra.chips = 45
    jig.ability.extra.chip_mod = 5
    slot = hold_stone(game, "c_pokep_moonstone")
    T.assert_true(game:use_consumable(slot))
    local tuff = only_joker(game)
    T.assert_eq(tuff.def.id, "j_pokep_wigglytuff")
    T.assert_eq(tuff.ability.extra.chips, 45,
        "grown Chips carry (45 > Wigglytuff's base 30)")
    T.assert_eq(tuff.ability.extra.mult, 2, "ungrown values take the new form's config")
    wipe_mods()
end)

return suite
