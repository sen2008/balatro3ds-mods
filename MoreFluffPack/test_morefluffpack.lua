--- MoreFluffPack: install the real pack through ModLoader and drive its
--- Jokers through the mod-context pipeline (same harness the fork's own
--- tests and the sibling packs use). Balatro3DS keeps owned consumables at
--- `game.consumables` and dollars land directly on game.money.
---
--- Run with MF_PACK_LUA pointing at the pack's main file.
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
            if fs.getInfo(child, "file") then
                fs.remove(child)
            else
                rm(child)
                fs.remove(child)
            end
        end
    end
    if fs.getInfo(ModLoader.DIR) then rm(ModLoader.DIR) end
    ModLoader.reset()
end

-- Sprite bases the pack references (plus top10's soul layer). Dummy
-- images are written for each so the loader's sprite-existence check
-- passes; the real PNGs/t3x files are verified on disk separately.
local NAMES = {
    "badlegaldefence", "baseball_stream", "basepaul_card", "bigshot", "blackmarket", "bladedance",
    "bloodpact", "bookmove", "bowling_ball", "brainrot", "brilliant", "broomcloset",
    "burnerphone", "cba", "clownfish", "coupon_catalogue", "dinner", "dramaticentrance",
    "expansion_pack", "fish", "forge", "forgeslop", "friendinsideme", "globe",
    "goldencarrot", "grep", "hallofmirrors", "hollow", "hugejoker", "hyperbeam",
    "icecube", "impostor", "jack_of_all_trades", "jester", "jokesforminecrafters", "knuckleblaster",
    "lessfluff", "lettergem_a", "lettergem_c", "lettergem_d", "lettergem_f", "lettergem_g",
    "lettergem_h", "lettergem_i", "lettergem_j", "lettergem_k", "lettergem_m", "lettergem_n",
    "lettergem_o", "lettergem_q", "lettergem_s", "lettergem_v", "lettergem_w", "lettergem_y",
    "lollipop", "luckycharm", "mashupalbum", "miner", "moneyprinter", "mspaint",
    "onesliptoolate", "oopsallfives", "particleaccelerator", "passando", "philosophical", "pixel_joker",
    "recycling", "retrigger_joker", "riding_the_dilu_horse", "simplified", "slotmachine", "spiral",
    "steamflogger_boss", "stifle", "stonejokerjoker", "stormscale", "stylemeter", "sudoku",
    "sword_of_steven_and_todd", "the_solo", "thejester", "theshatteringcircle", "tonersoup", "top10",
    "top10_soul", "treasuremap", "triangular", "virtual", "whiteboard", "wilddrawfour",
}

local function install_pack()
    wipe_mods()
    local path = os.getenv("MF_PACK_LUA")
    assert(path and path ~= "", "MF_PACK_LUA must point at morefluffpack.lua")
    local fh = assert(io.open(path, "rb"))
    local main = fh:read("*a")
    fh:close()

    local base = ModLoader.DIR .. "/MoreFluffPack"
    love.filesystem.createDirectory(base)
    love.filesystem.write(base .. "/MoreFluffPack.json", [[{
        "id": "MoreFluffPack",
        "name": "MoreFluff Pack",
        "prefix": "mfp",
        "main_file": "morefluffpack.lua",
        "version": "1.1.0",
        "author": ["notmario", "3DS port"]
    }]])
    love.filesystem.write(base .. "/morefluffpack.lua", main)
    love.filesystem.createDirectory(base .. "/assets/1x")
    for _, name in ipairs(NAMES) do
        love.filesystem.write(base .. "/assets/1x/" .. name .. ".png", "png")
        love.filesystem.write(base .. "/assets/1x/" .. name .. "_negative.png", "png")
    end
    ModLoader.load_all()
    local rec = ModLoader.by_id and ModLoader.by_id.MoreFluffPack
    assert(rec, "pack should load")
    assert(rec.status == "loaded", "pack load failed: " .. tostring(rec.error))
    local game = bootstrap.new_game(7730)
    G = game
    if not game.hand then game.hand = Hand(game) end
    if not game.deck then game.deck = Deck(game) end
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
    c.base = { id = rank, suit = data.suit }
    return c
end

local function fire(joker, ev, ctx)
    ctx = ctx or {}
    ctx.event = ev
    ctx.event_name = ev
    if joker:matches_trigger(ev, ctx) then joker:apply_effect(ctx) end
    return ctx
end

--- One Joker's joker_main against a played hand (ctx starts at 10 chips / 2 mult).
local function scored(joker, played)
    played = played or {}
    local ctx = { event = "on_hand_scored", event_name = "on_hand_scored", chips = 10, mult = 2,
        cards = played, played_cards = played, full_hand = played }
    if joker:matches_trigger("on_hand_scored", ctx) then joker:apply_effect(ctx) end
    return ctx
end

--- The whole held row's joker_main through the game's own emit.
local function scored_emit(game, played)
    played = played or {}
    local ctx = { event = "on_hand_scored", event_name = "on_hand_scored", chips = 10, mult = 2,
        cards = played, played_cards = played, full_hand = played }
    game:emit_joker_event("on_hand_scored", ctx)
    return ctx
end

local function play_card(joker, c, ctx_extra)
    local ctx = { event = "card_played", event_name = "card_played", chips = 0, mult = 1,
        rank = c.base.id, suit = c.base.suit, card_node = c, played_cards = { c }, full_hand = { c } }
    if ctx_extra then for k, v in pairs(ctx_extra) do ctx[k] = v end end
    if joker:matches_trigger("card_played", ctx) then joker:apply_effect(ctx) end
    return ctx
end

local function held_card(joker, c)
    local ctx = { event = "card_held", event_name = "card_held", chips = 0, mult = 1,
        rank = c.base.id, suit = c.base.suit, card_node = c, full_hand = { c } }
    if joker:matches_trigger("card_held", ctx) then joker:apply_effect(ctx) end
    return ctx
end

local function before(joker, played, extra)
    local ctx = { event = "on_hand_played", event_name = "on_hand_played",
        played_cards = played, full_hand = played, cards = played }
    if extra then for k, v in pairs(extra) do ctx[k] = v end end
    if joker:matches_trigger("on_hand_played", ctx) then joker:apply_effect(ctx) end
    return ctx
end

local function consumables(game)
    return #(game.consumables or {})
end

local function total_cards(game)
    local n = #(game.deck.cards or {}) + #(game.deck.discard_pile or {})
    if game.hand and game.hand.card_nodes then n = n + #game.hand.card_nodes end
    return n
end

local function defid(j)
    if j == nil then return nil end
    if j.def and j.def.id then return j.def.id end
    return j.def_id or j.id
end

local function flatten(lines, out)
    out = out or {}
    if type(lines) == "string" then out[#out + 1] = lines end
    if type(lines) == "table" then
        for _, v in pairs(lines) do flatten(v, out) end
    end
    return out
end

local EXPECT = {
    ["j_mfp_badlegaldefence"] = { "Bad Legal Defence", 2, 6 },
    ["j_mfp_baseball_stream"] = { "The Baseball Stream", 3, 10 },
    ["j_mfp_basepaul_card"] = { "Basepaul Card", 1, 5 },
    ["j_mfp_bigshot"] = { "[[BIG SHOT]]", 5, 7 },
    ["j_mfp_blackmarket"] = { "Black Market", 5, 4 },
    ["j_mfp_bladedance"] = { "Blade Dance", 2, 8 },
    ["j_mfp_bloodpact"] = { "Contract from Below", 3, 9 },
    ["j_mfp_bookmove"] = { "Book Move", 3, 10 },
    ["j_mfp_bowling_ball"] = { "Bowling Ball", 3, 8 },
    ["j_mfp_brainrot"] = { "Brainrot", 5, 6 },
    ["j_mfp_brilliant"] = { "Brilliant", 2, 8 },
    ["j_mfp_broomcloset"] = { "The Broom Closet", 2, 4 },
    ["j_mfp_burnerphone"] = { "Burner Phone", 5, 2 },
    ["j_mfp_cba"] = { "Card Buffer Advanced", 3, 10 },
    ["j_mfp_clownfish"] = { "Clownfish", 1, 6 },
    ["j_mfp_coupon_catalogue"] = { "Coupon Catalogue", 5, 7 },
    ["j_mfp_dinner"] = { "DINNER!", 2, 5 },
    ["j_mfp_dramaticentrance"] = { "Dramatic Entrance", 2, 6 },
    ["j_mfp_expansion_pack"] = { "Expansion Pack", 1, 6 },
    ["j_mfp_fish"] = { "Fish", 8, 1 },
    ["j_mfp_forge"] = { "Joker Forge", 2, 6 },
    ["j_mfp_forgeslop"] = { "Forge Residue", 8, 0 },
    ["j_mfp_friendinsideme"] = { "Friend Inside Me", 2, 7 },
    ["j_mfp_globe"] = { "Globe", 2, 6 },
    ["j_mfp_goldencarrot"] = { "Golden Carrot", 2, 4 },
    ["j_mfp_grep"] = { "grep", 3, 8 },
    ["j_mfp_hallofmirrors"] = { "Hall of Mirrors", 5, 6 },
    ["j_mfp_hollow"] = { "Hollow Joker", 1, 4 },
    ["j_mfp_hugejoker"] = { "Huge Joker", 3, 8 },
    ["j_mfp_hyperbeam"] = { "Hyper Beam", 2, 8 },
    ["j_mfp_icecube"] = { "Ice Cube", 2, 6 },
    ["j_mfp_impostor"] = { "Impostor", 5, 7 },
    ["j_mfp_jack_of_all_trades"] = { "Jack of All Trades", 1, 6 },
    ["j_mfp_jester"] = { "Jester", 1, 2 },
    ["j_mfp_jokesforminecrafters"] = { "Jokes for Balatro Players", 1, 7 },
    ["j_mfp_knuckleblaster"] = { "Knuckleblaster", 2, 6 },
    ["j_mfp_lessfluff"] = { "Less Fluff", 3, 10 },
    ["j_mfp_lettergem_a"] = { "A", 6, 2 },
    ["j_mfp_lettergem_c"] = { "C", 6, 6 },
    ["j_mfp_lettergem_d"] = { "D", 6, 4 },
    ["j_mfp_lettergem_f"] = { "F", 6, 8 },
    ["j_mfp_lettergem_g"] = { "G", 6, 4 },
    ["j_mfp_lettergem_h"] = { "H", 6, 8 },
    ["j_mfp_lettergem_i"] = { "I", 6, 2 },
    ["j_mfp_lettergem_j"] = { "J", 6, 16 },
    ["j_mfp_lettergem_k"] = { "K", 6, 10 },
    ["j_mfp_lettergem_m"] = { "M", 6, 6 },
    ["j_mfp_lettergem_n"] = { "N", 6, 2 },
    ["j_mfp_lettergem_o"] = { "O", 6, 2 },
    ["j_mfp_lettergem_q"] = { "Q", 6, 20 },
    ["j_mfp_lettergem_s"] = { "S", 6, 2 },
    ["j_mfp_lettergem_v"] = { "V", 6, 8 },
    ["j_mfp_lettergem_w"] = { "W", 6, 8 },
    ["j_mfp_lettergem_y"] = { "Y", 6, 8 },
    ["j_mfp_lollipop"] = { "Lollipop", 1, 6 },
    ["j_mfp_luckycharm"] = { "Lucky Charm", 1, 6 },
    ["j_mfp_mashupalbum"] = { "Mashup Album", 5, 8 },
    ["j_mfp_miner"] = { "Miner", 5, 5 },
    ["j_mfp_moneyprinter"] = { "Money Printer", 5, 5 },
    ["j_mfp_mspaint"] = { "MS Paint Joker", 1, 5 },
    ["j_mfp_onesliptoolate"] = { "One Slip Too Late", 2, 5 },
    ["j_mfp_oopsallfives"] = { "Oops! All 5s", 8, 1 },
    ["j_mfp_particleaccelerator"] = { "Particle Accelerator", 5, 7 },
    ["j_mfp_passando"] = { "Passing Balatro in 5 Minutes", 2, 6 },
    ["j_mfp_philosophical"] = { "Philosophical Joker", 1, 1 },
    ["j_mfp_pixel_joker"] = { "Pixel Joker", 3, 8 },
    ["j_mfp_recycling"] = { "Recycling", 2, 5 },
    ["j_mfp_retrigger_joker"] = { "Retrigger Joker", 2, 8 },
    ["j_mfp_riding_the_dilu_horse"] = { "Riding the Dilu Horse", 3, 7 },
    ["j_mfp_simplified"] = { "Simplified Joker", 1, 5 },
    ["j_mfp_slotmachine"] = { "Big Win", 2, 7 },
    ["j_mfp_spiral"] = { "Spiral Joker", 1, 5 },
    ["j_mfp_steamflogger_boss"] = { "Steamflogger Boss", 5, 6 },
    ["j_mfp_stifle"] = { "Stifle", 1, 4 },
    ["j_mfp_stonejokerjoker"] = { "StoneJoker Joker", 2, 8 },
    ["j_mfp_stormscale"] = { "Stormscale Scion", 5, 10 },
    ["j_mfp_stylemeter"] = { "Style Meter", 2, 6 },
    ["j_mfp_sudoku"] = { "Sudoku Joker", 5, 9 },
    ["j_mfp_sword_of_steven_and_todd"] = { "Sword of Steven and Todd", 3, 10 },
    ["j_mfp_the_solo"] = { "The Solo", 3, 7 },
    ["j_mfp_thejester"] = { "The Jester", 5, 20 },
    ["j_mfp_theshatteringcircle"] = { "Disintegration Loop", 3, 10 },
    ["j_mfp_tonersoup"] = { "I Sip Toner Soup", 5, 8 },
    ["j_mfp_top10"] = { "Top 10 Jokers From 1 To 10", 3, 10 },
    ["j_mfp_treasuremap"] = { "Treasure Map", 1, 4 },
    ["j_mfp_triangular"] = { "Triangular Joker", 5, 7 },
    ["j_mfp_virtual"] = { "Virtual Joker", 5, 7 },
    ["j_mfp_whiteboard"] = { "Whiteboard", 5, 6 },
    ["j_mfp_wilddrawfour"] = { "Wild Draw Four", 5, 7 },
}

suite.test("pack loads and registers all 89 Jokers", function()
    install_pack()
    local n = 0
    for id in pairs(JOKER_DEFS) do
        if id:sub(1, 6) == "j_mfp_" then n = n + 1 end
    end
    T.assert_eq(n, 89, "89 pack Jokers registered")
    for id, want in pairs(EXPECT) do
        local def = JOKER_DEFS[id]
        T.assert_not_nil(def, id .. " registered")
        if def then
            T.assert_eq(def.name, want[1], id .. " name")
            T.assert_eq(tonumber(def.rarity), want[2], id .. " rarity")
            T.assert_eq(tonumber(def.cost), want[3], id .. " cost")
        end
    end
    local rarities = 0
    for _ in pairs(SMODS.Rarities) do rarities = rarities + 1 end
    T.assert_true(rarities >= 6, "pack rarities registered")
    wipe_mods()
end)

suite.test("every pack Joker has a clean tooltip", function()
    local game = install_pack()
    for id in pairs(EXPECT) do
        local joker = add(game, id)
        local lines = SMODS.tooltip_lines(id, joker)
        T.assert_true(#flatten(lines) > 0, id .. " has tooltip text")
        for _, line in ipairs(flatten(lines)) do
            T.assert_false(line:find("#", 1, true) ~= nil, id .. " tooltip has no unfilled #")
        end
        table.remove(game.jokers)
    end
    wipe_mods()
end)

-- ---------------------------------------------------------------------------
-- Behaviour: flat and X-Mult scoring
-- ---------------------------------------------------------------------------

suite.test("fish levels every scored card type once", function()
    local game = install_pack()
    local fish = add(game, "j_mfp_fish")
    local ctx = scored(fish, { card(9) })
    T.assert_eq(ctx.chips, 14)
    T.assert_eq(ctx.mult, 6)
    wipe_mods()
end)

suite.test("flat and X-Mult joker_main Jokers", function()
    local game = install_pack()
    T.assert_near(scored(add(game, "j_mfp_basepaul_card")).mult, 2.5, 0.001, "Basepaul X1.25")
    local huge = add(game, "j_mfp_hugejoker")
    T.assert_eq(scored(huge).mult, 6, "Huge X3")
    T.assert_eq(huge.ability.h_size, -2, "Huge is -2 hand size")
    T.assert_eq(scored(add(game, "j_mfp_virtual")).mult, 6, "Virtual X3")
    T.assert_eq(scored(add(game, "j_mfp_hyperbeam")).mult, 6, "Hyper Beam X3")
    T.assert_eq(scored(add(game, "j_mfp_knuckleblaster")).mult, 6, "Knuckleblaster X3")
    wipe_mods()
end)

suite.test("steamflogger and stifle count neighbours", function()
    local game = install_pack()
    local flogger = add(game, "j_mfp_steamflogger_boss")
    add(game, "j_mfp_jester")
    T.assert_eq(scored(flogger).chips, 42, "+16 per other Joker held (2 total)")
    wipe_mods()
    game = install_pack()
    local stifle = add(game, "j_mfp_stifle")
    T.assert_eq(scored(stifle).chips, 10, "no right neighbour, no bonus")
    add(game, "j_mfp_jester")
    T.assert_eq(scored(stifle).chips, 130, "+120 with a right neighbour")
    wipe_mods()
end)

suite.test("spiral scales with money", function()
    local game = install_pack()
    local spiral = add(game, "j_mfp_spiral")
    game.money = 0
    T.assert_eq(scored(spiral).mult, 19, "10 + 7cos(0) = +17 Mult at $0")
    wipe_mods()
end)

suite.test("coupon catalogue counts vouchers redeemed", function()
    local game = install_pack()
    local coupon = add(game, "j_mfp_coupon_catalogue")
    game.vouchers = { "v_a", "v_b" }
    T.assert_eq(scored(coupon).mult, 32, "+15 per voucher (2)")
    wipe_mods()
end)

-- ---------------------------------------------------------------------------
-- Behaviour: new ports from the completion pass
-- ---------------------------------------------------------------------------

suite.test("grep sorts matching cards to the draw end on a first single discard", function()
    local game = install_pack()
    local grep = add(game, "j_mfp_grep")
    local deck = game.deck.cards
    T.assert_eq(#deck, 52)
    local node = card(3, "Hearts")
    fire(grep, "on_pre_discard", { discarded_nodes = { node }, discarded_cards = { node.card_data } })
    T.assert_eq(#deck, 52, "no cards lost")
    local matches, last_nonmatch, first_match = 0, 0, nil
    for i, d in ipairs(deck) do
        if d.rank == 3 or d.suit == "Hearts" then
            matches = matches + 1
            first_match = first_match or i
        else
            last_nonmatch = i
        end
    end
    T.assert_eq(matches, 16, "13 Hearts + 3 other 3s")
    T.assert_true(last_nonmatch < first_match, "all matches sit at the draw end")
    local before_order = {}
    for i, d in ipairs(deck) do before_order[i] = tostring(d.rank) .. d.suit end
    fire(grep, "on_pre_discard", { discarded_nodes = { card(9, "Clubs") }, discarded_cards = {} })
    for i, d in ipairs(deck) do
        T.assert_eq(tostring(d.rank) .. d.suit, before_order[i], "second discard does not re-sort")
    end
    wipe_mods()
end)

suite.test("letter D destroys two playing cards at end of round", function()
    local game = install_pack()
    local d = add(game, "j_mfp_lettergem_d")
    T.assert_eq(total_cards(game), 52)
    fire(d, "on_round_end", {})
    T.assert_eq(total_cards(game), 50)
    wipe_mods()
end)

suite.test("one slip too late keys off hands played this round", function()
    local game = install_pack()
    local osl = add(game, "j_mfp_onesliptoolate")
    game.round_hands_played = 2
    T.assert_eq(scored(osl, { card(5), card(6) }).mult, 4, "2-card hand on hand 2: X2")
    T.assert_eq(scored(osl, { card(5), card(6), card(7) }).mult, 2, "3-card hand on hand 2: nothing")
    wipe_mods()
end)

suite.test("whiteboard pays per empty hand space after 3", function()
    local game = install_pack()
    add(game, "j_mfp_whiteboard")
    game.hand.card_nodes = { card(5, "Clubs"), card(6, "Clubs") }
    T.assert_near(scored_emit(game, { card(9) }).mult, 4, 0.001, "X2 with 2 cards in hand")
    game.hand.card_nodes = { card(5, "Clubs"), card(6, "Clubs"), card(7, "Clubs") }
    T.assert_eq(scored_emit(game, { card(9) }).mult, 2, "no bonus at 3 cards in hand")
    wipe_mods()
end)

suite.test("simplified pays when another Common Joker triggers", function()
    local game = install_pack()
    add(game, "j_mfp_simplified")
    add(game, "j_mfp_jester")
    local ctx = scored_emit(game, { card(9) })
    T.assert_eq(ctx.chips, 50, "jester +40")
    T.assert_eq(ctx.mult, 6, "simplified +4 via post_trigger")
    wipe_mods()
end)

suite.test("dramatic entrance pays on the first hand only", function()
    local game = install_pack()
    local de = add(game, "j_mfp_dramaticentrance")
    -- The fork increments its hands-played counter when the hand is
    -- played, before scoring ticks, so the first hand reads 1.
    game.round_hands_played = 1
    T.assert_eq(scored(de).chips, 160, "+150 on the first hand")
    game.round_hands_played = 2
    T.assert_eq(scored(de).chips, 10, "nothing on the second hand")
    wipe_mods()
end)

-- ---------------------------------------------------------------------------
-- Behaviour: per-card effects
-- ---------------------------------------------------------------------------

suite.test("big shot pays for Aces only", function()
    local game = install_pack()
    local big = add(game, "j_mfp_bigshot")
    local m0 = game.money
    play_card(big, card(14))
    T.assert_eq(game.money, m0 + 1, "Ace pays $1")
    play_card(big, card(12))
    T.assert_eq(game.money, m0 + 1, "Queen pays nothing")
    wipe_mods()
end)

suite.test("letter A and G on played cards", function()
    local game = install_pack()
    local a = add(game, "j_mfp_lettergem_a")
    T.assert_eq(play_card(a, card(14)).mult, 3, "Ace +2 Mult")
    T.assert_eq(play_card(a, card(13)).mult, 1, "King nothing")
    local g = add(game, "j_mfp_lettergem_g")
    T.assert_near(play_card(g, card(5)).mult, 1.01, 0.0001, "X1.01 per card")
    wipe_mods()
end)

suite.test("letter S matches ranks 6 and 7, played or held", function()
    local game = install_pack()
    local s = add(game, "j_mfp_lettergem_s")
    local ctx = play_card(s, card(6))
    T.assert_eq(ctx.chips, 6)
    T.assert_eq(ctx.mult, 8)
    ctx = play_card(s, card(8))
    T.assert_eq(ctx.chips, 0)
    T.assert_eq(ctx.mult, 1)
    ctx = held_card(s, card(7))
    T.assert_eq(ctx.chips, 6)
    T.assert_eq(ctx.mult, 8)
    wipe_mods()
end)

suite.test("letter C cashes in every 100 chips of cards played", function()
    local game = install_pack()
    local cgem = add(game, "j_mfp_lettergem_c")
    for _ = 1, 9 do play_card(cgem, card(10)) end
    T.assert_eq(cgem.ability.extra.counter, 90)
    local ctx = play_card(cgem, card(10))
    T.assert_eq(ctx.mult, 5, "tenth card: X5")
    T.assert_eq(cgem.ability.extra.counter, 0, "counter spent")
    wipe_mods()
end)

suite.test("letter Y pays on the 13th scored card", function()
    local game = install_pack()
    local y = add(game, "j_mfp_lettergem_y")
    local m0 = game.money
    for _ = 1, 12 do play_card(y, card(4)) end
    T.assert_eq(game.money, m0, "nothing before 13")
    play_card(y, card(4))
    T.assert_eq(game.money, m0 + 10, "$10 on the 13th")
    wipe_mods()
end)

suite.test("sword pays on held cards by parity", function()
    local game = install_pack()
    local sword = add(game, "j_mfp_sword_of_steven_and_todd")
    local ctx = held_card(sword, card(4))
    T.assert_eq(ctx.mult, 5, "even: +4 Mult")
    T.assert_eq(ctx.chips, 0)
    ctx = held_card(sword, card(5))
    T.assert_eq(ctx.chips, 31, "odd: +31 Chips")
    T.assert_eq(ctx.mult, 1)
    wipe_mods()
end)

suite.test("the shattering circle rotates on blind select", function()
    local game = install_pack()
    local circle = add(game, "j_mfp_theshatteringcircle")
    local ctx = play_card(circle, card(8))
    T.assert_eq(ctx.chips, 50, "rotation 0: +50 Chips")
    T.assert_eq(ctx.mult, 1)
    fire(circle, "on_blind_selected", {})
    ctx = play_card(circle, card(8))
    T.assert_eq(ctx.chips, 35, "rotation 1: floor(50*cos45)")
    T.assert_eq(ctx.mult, 15, "rotation 1: +floor(20*sin45) Mult")
    wipe_mods()
end)

suite.test("wild draw four grows hand size on Wild cards, resets at round end", function()
    local game = install_pack()
    local w = add(game, "j_mfp_wilddrawfour")
    play_card(w, card(5, "Hearts", "wild"))
    T.assert_eq(w.ability.h_size, 4)
    fire(w, "on_round_end", {})
    T.assert_eq(w.ability.h_size, 0)
    wipe_mods()
end)

-- ---------------------------------------------------------------------------
-- Behaviour: hand-level effects
-- ---------------------------------------------------------------------------

suite.test("triangular gains a chip per card in the played hand", function()
    local game = install_pack()
    local tri = add(game, "j_mfp_triangular")
    before(tri, { card(2), card(3), card(4) })
    T.assert_eq(tri.ability.extra.chips, 3)
    T.assert_eq(tri.ability.extra.chip_mod, 3)
    T.assert_eq(scored(tri).chips, 13)
    wipe_mods()
end)

suite.test("impostor triples when exactly one scoring card is red", function()
    local game = install_pack()
    local imp = add(game, "j_mfp_impostor")
    before(imp, { card(5, "Hearts"), card(6, "Clubs"), card(7, "Spades") })
    T.assert_eq(imp.ability.extra.check, 1)
    T.assert_eq(scored(imp).mult, 6, "X3")
    wipe_mods()
end)

suite.test("mashup album grows on flushes by colour", function()
    local game = install_pack()
    local mash = add(game, "j_mfp_mashupalbum")
    local hearts = { card(2), card(4), card(6), card(8), card(10) }
    before(mash, hearts, { contains_hand_types = { Flush = { true } } })
    T.assert_eq(mash.ability.extra.mult, 8, "red flush: +4 Mult")
    local ctx = scored(mash, hearts)
    T.assert_eq(ctx.mult, 10)
    T.assert_eq(ctx.chips, 25)
    wipe_mods()
    game = install_pack()
    local mash2 = add(game, "j_mfp_mashupalbum")
    local spades = { card(2, "Spades"), card(4, "Spades"), card(6, "Spades"), card(8, "Spades"), card(10, "Spades") }
    before(mash2, spades, { contains_hand_types = { Flush = { true } } })
    T.assert_eq(mash2.ability.extra.chips, 30, "black flush: +15 Chips")
    wipe_mods()
end)

suite.test("the jester pays per unique pair in the scoring hand", function()
    local game = install_pack()
    local jest = add(game, "j_mfp_thejester")
    local ctx = scored(jest, { card(5), card(5, "Clubs"), card(9), card(9, "Clubs"), card(13) })
    T.assert_near(ctx.mult, 12.5, 0.001, "X2.5 twice")
    wipe_mods()
end)

suite.test("sudoku completes after every rank A-9 scores", function()
    local game = install_pack()
    local sud = add(game, "j_mfp_sudoku")
    T.assert_eq(scored(sud).mult, 2, "incomplete: nothing")
    for _, r in ipairs({ 14, 2, 3, 4, 5, 6, 7, 8, 9 }) do play_card(sud, card(r)) end
    T.assert_eq(scored(sud).mult, 10, "complete: X5")
    wipe_mods()
end)

suite.test("bloodpact pays X5 all-Hearts and dies otherwise", function()
    local game = install_pack()
    local pact = add(game, "j_mfp_bloodpact")
    T.assert_eq(scored(pact, { card(5), card(6) }).mult, 10, "X5 all Hearts")
    T.assert_eq(#game.jokers, 1)
    scored(pact, { card(5), card(6, "Clubs") })
    T.assert_eq(#game.jokers, 0, "destroyed by a non-Heart")
    wipe_mods()
end)

-- ---------------------------------------------------------------------------
-- Behaviour: scaling, decay and sell timers
-- ---------------------------------------------------------------------------

suite.test("lollipop decays at end of round", function()
    local game = install_pack()
    local lol = add(game, "j_mfp_lollipop")
    T.assert_near(scored(lol).mult, 3.5, 0.001, "X1.75")
    fire(lol, "on_round_end", {})
    T.assert_near(lol.ability.extra.xmult, 1.6, 0.001, "decayed to 1.6")
    wipe_mods()
end)

suite.test("particle accelerator banks on solo hands and cashes in on others", function()
    local game = install_pack()
    local pa = add(game, "j_mfp_particleaccelerator")
    local one = { card(5) }
    fire(pa, "on_hand_after", { played_cards = one, cards = one, full_hand = one })
    T.assert_eq(pa.ability.extra.xmult, 2)
    T.assert_eq(scored(pa, { card(5), card(6), card(7) }).mult, 4, "cashed in at X2")
    local three = { card(5), card(6), card(7) }
    fire(pa, "on_hand_after", { played_cards = three, cards = three, full_hand = three })
    T.assert_eq(pa.ability.extra.xmult, 1, "reset after cashing in")
    wipe_mods()
end)

suite.test("golden carrot pays what is left at end of round", function()
    local game = install_pack()
    local gc = add(game, "j_mfp_goldencarrot")
    local one = { card(5) }
    fire(gc, "on_hand_after", { played_cards = one, cards = one, full_hand = one })
    T.assert_eq(gc.ability.extra.gain, 9)
    local m0 = game.money
    fire(gc, "on_round_end", {})
    T.assert_eq(game.money - m0, 9)
    wipe_mods()
end)

suite.test("money printer pays per played card matching a money digit", function()
    local game = install_pack()
    local mp = add(game, "j_mfp_moneyprinter")
    game.money = 1111
    local m0 = game.money
    local played = { card(2), card(5), card(14) }
    fire(mp, "on_hand_after", { played_cards = played, cards = played, full_hand = played })
    T.assert_eq(game.money - m0, 2, "only the Ace (digit 1) pays")
    wipe_mods()
end)

suite.test("style meter pays for blinds skipped while held", function()
    local game = install_pack()
    local sm = add(game, "j_mfp_stylemeter")
    fire(sm, "on_blind_skipped", {})
    T.assert_eq(sm.ability.extra.skips, 1)
    local m0 = game.money
    fire(sm, "on_round_end", {})
    T.assert_eq(game.money - m0, 3)
    wipe_mods()
end)

suite.test("treasure map pays out when sold after 2 rounds", function()
    local game = install_pack()
    local tm = add(game, "j_mfp_treasuremap")
    fire(tm, "on_round_end", {})
    fire(tm, "on_round_end", {})
    local m0 = game.money
    fire(tm, "on_joker_sold", { joker = tm })
    T.assert_eq(game.money - m0, 13)
    wipe_mods()
end)

suite.test("book move creates chad and photograph when sold after 3 rounds", function()
    local game = install_pack()
    local bm = add(game, "j_mfp_bookmove")
    for _ = 1, 3 do fire(bm, "on_round_end", {}) end
    fire(bm, "on_joker_sold", { joker = bm })
    T.assert_eq(#game.jokers, 3)
    wipe_mods()
end)

suite.test("forge creates a Joker after two other Jokers are sold", function()
    local game = install_pack()
    local forge = add(game, "j_mfp_forge")
    local a = add(game, "j_mfp_jester")
    local b = add(game, "j_mfp_lettergem_g")
    fire(forge, "on_joker_sold", { joker = a })
    T.assert_eq(#game.jokers, 3)
    fire(forge, "on_joker_sold", { joker = b })
    T.assert_eq(#game.jokers, 4, "second sale creates a Joker")
    wipe_mods()
end)

suite.test("friend inside me trades a sold Common for an Uncommon", function()
    local game = install_pack()
    local fim = add(game, "j_mfp_friendinsideme")
    local sold = add(game, "j_mfp_jester")
    fire(fim, "on_joker_sold", { joker = sold })
    T.assert_eq(#game.jokers, 3, "a new Joker was created")
    T.assert_eq(fim.ability.extra.active, false, "and it is spent")
    wipe_mods()
end)

-- ---------------------------------------------------------------------------
-- Behaviour: retriggers, post-trigger and probability
-- ---------------------------------------------------------------------------

suite.test("baseball stream pays off Uncommon triggers per Rare held", function()
    local game = install_pack()
    add(game, "j_mfp_baseball_stream")
    add(game, "j_mfp_hyperbeam")
    T.assert_near(scored_emit(game, { card(9) }).mult, 7.5, 0.001, "X3 then X1.25")
    add(game, "j_mfp_hugejoker")
    T.assert_near(scored_emit(game, { card(9) }).mult, 28.125, 0.001, "two Rares held: X1.25^2")
    wipe_mods()
end)

suite.test("cba retriggers the leftmost editioned Joker", function()
    local game = install_pack()
    add(game, "j_mfp_cba")
    local jest = add(game, "j_mfp_jester")
    jest.edition = "foil"
    -- 10 base + 40 jester + 50 foil edition + 40 retriggered jester.
    T.assert_eq(scored_emit(game, { card(9) }).chips, 140)
    wipe_mods()
end)

suite.test("dinner retriggers the Joker to its right once", function()
    local game = install_pack()
    add(game, "j_mfp_dinner")
    add(game, "j_mfp_jester")
    T.assert_eq(scored_emit(game, { card(9) }).chips, 90, "40 twice")
    wipe_mods()
end)

suite.test("ice cube quadruples listed odds and melts", function()
    local game = install_pack()
    local cube = add(game, "j_mfp_icecube")
    local num, den = SMODS.get_probability_vars(nil, 1, 4)
    T.assert_eq(num, 4)
    T.assert_eq(den, 4)
    fire(cube, "on_round_end", {})
    T.assert_near(cube.ability.extra.odds, 3.5, 0.001, "melts by 0.5")
    for _ = 1, 5 do fire(cube, "on_round_end", {}) end
    T.assert_eq(#game.jokers, 0, "destroyed at X1")
    wipe_mods()
end)

suite.test("oops all fives and letter O reshape denominators", function()
    local game = install_pack()
    add(game, "j_mfp_oopsallfives")
    local num, den = SMODS.get_probability_vars(nil, 1, 5)
    T.assert_eq(num, 1)
    T.assert_eq(den, 4, "5 becomes 4")
    wipe_mods()
    game = install_pack()
    add(game, "j_mfp_lettergem_o")
    num, den = SMODS.get_probability_vars(nil, 3, 7)
    T.assert_eq(num, 1)
    T.assert_eq(den, 2, "any roll becomes 1 in 2")
    wipe_mods()
end)

-- ---------------------------------------------------------------------------
-- Behaviour: blind selection, shop and creation
-- ---------------------------------------------------------------------------

suite.test("brainrot eats the leftmost Joker at blind select", function()
    local game = install_pack()
    add(game, "j_mfp_jester")
    local brain = add(game, "j_mfp_brainrot")
    fire(brain, "on_blind_selected", {})
    T.assert_eq(#game.jokers, 1, "jester destroyed")
    T.assert_eq(brain.ability.extra.chips, 5, "+5 per sell value (jester sells for 1)")
    T.assert_eq(scored(brain).chips, 15)
    wipe_mods()
end)

suite.test("creation on blind select: expansion pack, letters F, K, M", function()
    local game = install_pack()
    local ep = add(game, "j_mfp_expansion_pack")
    fire(ep, "on_blind_selected", {})
    T.assert_eq(#game.jokers, 2, "expansion pack created a modded Joker")
    wipe_mods()
    game = install_pack()
    local f = add(game, "j_mfp_lettergem_f")
    fire(f, "on_blind_selected", {})
    T.assert_eq(#game.jokers, 2)
    T.assert_eq(tonumber(game.jokers[2].def.rarity), tonumber(JOKER_DEFS["j_mfp_lettergem_f"].rarity), "created a Letter Joker")
    wipe_mods()
    game = install_pack()
    local k = add(game, "j_mfp_lettergem_k")
    fire(k, "on_blind_selected", {})
    T.assert_eq(defid(game.jokers[2]), "j_cavendish")
    wipe_mods()
    game = install_pack()
    local m = add(game, "j_mfp_lettergem_m")
    fire(m, "on_blind_selected", {})
    T.assert_eq(defid(game.jokers[2]), "j_jolly")
    T.assert_eq(game.jokers[2].sell_cost, 4, "sell value raised by 3 (Jolly base 1)")
    wipe_mods()
end)

suite.test("boss blind rewards: miner tag, black market, bad legal defence, letter N", function()
    local game = install_pack()
    local miner = add(game, "j_mfp_miner")
    game.current_blind_index = 3
    local tags0 = #(game.tags or {})
    fire(miner, "on_blind_selected", {})
    T.assert_eq(#(game.tags or {}), tags0 + 1, "D6 Tag gained")
    wipe_mods()
    game = install_pack()
    local bm = add(game, "j_mfp_blackmarket")
    game.current_blind_index = 3
    game.money = 20
    fire(bm, "on_blind_selected", {})
    T.assert_eq(game.money, 10, "paid $10")
    T.assert_eq(consumables(game), 1, "Ankh created")
    wipe_mods()
    game = install_pack()
    local bld = add(game, "j_mfp_badlegaldefence")
    game.current_blind_index = 1
    fire(bld, "on_blind_selected", {})
    T.assert_eq(consumables(game), 0, "small blind: nothing")
    game.current_blind_index = 3
    fire(bld, "on_blind_selected", {})
    T.assert_eq(consumables(game), 1, "boss: Death created")
    wipe_mods()
    game = install_pack()
    local n = add(game, "j_mfp_lettergem_n")
    game.current_blind_index = 3
    fire(n, "on_blind_selected", {})
    T.assert_eq(#game.jokers, 2, "negative Joker created")
    T.assert_eq(game.jokers[2].edition, "negative")
    wipe_mods()
end)

suite.test("blade dance adds permanent Steel cards at round begin", function()
    local game = install_pack()
    local bd = add(game, "j_mfp_bladedance")
    fire(bd, "on_round_begin", {})
    T.assert_eq(#game.hand.card_nodes, 2, "two cards added to hand")
    for _, node in ipairs(game.hand.card_nodes) do
        T.assert_eq(node.card_data.enhancement, "steel")
    end
    wipe_mods()
end)

suite.test("consumable creators: globe, recycling, letter W, toner soup", function()
    local game = install_pack()
    local globe = add(game, "j_mfp_globe")
    fire(globe, "on_shop_reroll", {})
    T.assert_eq(consumables(game), 1, "Planet on reroll")
    wipe_mods()
    game = install_pack()
    local rec = add(game, "j_mfp_recycling")
    fire(rec, "on_booster_skip", {})
    T.assert_eq(consumables(game), 1, "consumable on booster skip")
    wipe_mods()
    game = install_pack()
    local w = add(game, "j_mfp_lettergem_w")
    fire(w, "on_blind_selected", {})
    T.assert_eq(consumables(game), 1, "Wheel of Fortune on blind select")
    wipe_mods()
    game = install_pack()
    local soup = add(game, "j_mfp_tonersoup")
    local played = { card(5) }
    before(soup, played)
    T.assert_eq(consumables(game), 1, "random consumable each hand")
    fire(soup, "on_round_end", {})
    T.assert_eq(#game.jokers, 0, "destroyed at end of round")
    wipe_mods()
end)

suite.test("top 10 pays per unique digit of your money", function()
    local game = install_pack()
    local t10 = add(game, "j_mfp_top10")
    game.money = 1234
    local m0 = game.money
    fire(t10, "on_round_end", {})
    T.assert_eq(game.money - m0, 20, "four unique digits: $20")
    wipe_mods()
end)

suite.test("stormscale copies bought Jokers, copies burn at round end", function()
    local game = install_pack()
    local storm = add(game, "j_mfp_stormscale")
    local bought = add(game, "j_mfp_jester")
    fire(storm, "on_shop_buy", { card = bought, joker = bought })
    fire(storm, "on_shop_buy", { card = bought, joker = bought })
    T.assert_eq(storm.ability.extra.purchases, 2)
    fire(storm, "on_shop_exit", {})
    T.assert_eq(#game.jokers, 3, "one negative copy per 2 purchases")
    local copy = game.jokers[3]
    T.assert_eq(copy.edition, "negative")
    fire(copy, "on_round_end", {})
    T.assert_eq(#game.jokers, 2, "temporary copy destroyed")
    wipe_mods()
end)

suite.test("riding the dilu horse marks the right Joker on boss defeat", function()
    local game = install_pack()
    local horse = add(game, "j_mfp_riding_the_dilu_horse")
    local right = add(game, "j_mfp_jester")
    game.current_blind_index = 3
    fire(horse, "on_round_end", {})
    T.assert_eq(right.ability.mf_dilu_horse, 1)
    wipe_mods()
end)

suite.test("jokes for minecrafters destroys discarded cards of its suit", function()
    local game = install_pack()
    local jokes = add(game, "j_mfp_jokesforminecrafters")
    jokes.ability.extra.current_joke = "hearts"
    local heart = SMODS.add_card { set = "Playing", rank = 5, suit = "Hearts", area = "hand" }
    local club = SMODS.add_card { set = "Playing", rank = 6, suit = "Clubs", area = "hand" }
    T.assert_eq(#game.hand.card_nodes, 2)
    fire(jokes, "on_pre_discard", { discarded_nodes = { heart, club } })
    T.assert_eq(#game.hand.card_nodes, 1, "the Hearts card was destroyed")
    T.assert_eq(game.hand.card_nodes[1], club, "the Clubs card survives")
    T.assert_eq(#game.deck.discard_pile, 0, "destroyed, not discarded")
    wipe_mods()
end)

-- ---------------------------------------------------------------------------
-- Behaviour: the completion-pass additions
-- ---------------------------------------------------------------------------

suite.test("hall of mirrors grows hand size on scored 6s, resets at round end", function()
    local game = install_pack()
    local hall = add(game, "j_mfp_hallofmirrors")
    play_card(hall, card(6))
    T.assert_eq(hall.ability.h_size, 3)
    play_card(hall, card(5))
    T.assert_eq(hall.ability.h_size, 3, "only 6s count")
    play_card(hall, card(6, "Clubs"))
    T.assert_eq(hall.ability.h_size, 6)
    fire(hall, "on_round_end", {})
    T.assert_eq(hall.ability.h_size, 0, "reset at end of round")
    wipe_mods()
end)

suite.test("ms paint gives +3 hand size for the first hand of a blind", function()
    local game = install_pack()
    local paint = add(game, "j_mfp_mspaint")
    fire(paint, "on_blind_selected", {})
    T.assert_eq(paint.ability.h_size, 3)
    local one = { card(5) }
    fire(paint, "on_hand_after", { played_cards = one, cards = one, full_hand = one })
    T.assert_eq(paint.ability.h_size, 0, "expires after the first hand")
    fire(paint, "on_blind_selected", {})
    T.assert_eq(paint.ability.h_size, 3, "and returns next blind")
    wipe_mods()
end)

suite.test("hollow pays +10 Mult per hand size below 9", function()
    local game = install_pack()
    local hollow = add(game, "j_mfp_hollow")
    -- Base limit 8, Hollow itself is -1: limit 7, two below 9.
    T.assert_eq(scored(hollow).mult, 22, "+20 Mult")
    wipe_mods()
end)

suite.test("less fluff destroys non-modded Jokers at blind select and scales", function()
    local game = install_pack()
    local less = add(game, "j_mfp_lessfluff")
    add(game, "j_mfp_jester")
    add(game, "j_joker")
    T.assert_eq(#game.jokers, 3)
    fire(less, "on_blind_selected", {})
    T.assert_eq(#game.jokers, 2, "the vanilla Joker was destroyed, the modded one spared")
    T.assert_near(less.ability.extra.x_mult, 1.2, 0.001, "X1.2 after one destroy")
    T.assert_near(scored(less).mult, 2.4, 0.001)
    wipe_mods()
end)

suite.test("letter Q pays for held cards adjacent to a Queen", function()
    local game = install_pack()
    local q = add(game, "j_mfp_lettergem_q")
    local queen = card(12, "Spades")
    local five = card(5)
    local nine = card(9, "Clubs")
    game.hand.card_nodes = { queen, five, nine }
    T.assert_near(held_card(q, five).mult, 1.3, 0.001, "adjacent to the Queen: X1.3")
    T.assert_eq(held_card(q, nine).mult, 1, "not adjacent: nothing")
    wipe_mods()
end)

suite.test("burner phone tooltip names the top cards of the deck", function()
    local game = install_pack()
    local phone = add(game, "j_mfp_burnerphone")
    local text = table.concat(flatten(SMODS.tooltip_lines("j_mfp_burnerphone", phone)), " ")
    T.assert_true(text:find("of", 1, true) ~= nil, "tooltip shows a rank of a suit")
    T.assert_false(text:find("#", 1, true) ~= nil, "and every fragment is filled")
    wipe_mods()
end)

return suite
