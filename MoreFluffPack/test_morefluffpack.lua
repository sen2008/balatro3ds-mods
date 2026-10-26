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
    "allicantdo", "allicantdo_soul", "blahaj", "brass", "flintandsteel", "gemstonejoker", "jankman",
    "lettergem_e", "marigold", "marigold_soul", "rosetinted", "teacup", "tealjoker", "unpleasantcard",
    "widejoker", "yuckyrat",
    "aceupthesleeve", "balatromods", "freaky_pizza", "glitterbomb", "sealthedeal",
    "enh_brass", "enh_gemstone", "enh_marigold", "enh_teal", "enh_yucky",
    -- v1.4.0
    "bouncer", "junkmail", "lettergem_b", "shopping_spree", "gemalert",
    "bonussheet", "repack", "modded_normal_1", "modded_normal_2",
    "astral_sliver", "megantic_sliver", "plasma_sliver", "sinew_sliver",
    "muscle_sliver", "might_sliver", "fury_sliver", "mindlash_sliver",
    "quantum_sliver", "sliver_jockey", "gemhide_sliver", "fortunate_sliver",
    "paintcan", "rainbowjoker", "clipart", "css", "monochrome", "loadeddisk",
    "black", "deepblue", "crimson", "seaweed", "brown", "grey", "silver",
    "white", "red", "orange", "green", "blue", "lilac", "pink",
    "colour_normal_1", "colour_normal_2", "colour_jumbo_1", "colour_mega_1",
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
        "version": "1.3.0",
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
    ["j_mfp_allicantdo"] = { "All I Can't Do", 3, 9 },
    ["j_mfp_blahaj"] = { "Blåhaj", 1, 1 },
    ["j_mfp_brass"] = { "Brass Joker", 3, 10 },
    ["j_mfp_flintandsteel"] = { "Flint and Steel", 5, 4 },
    ["j_mfp_gemstonejoker"] = { "Gemstone Joker", 2, 6 },
    ["j_mfp_jankman"] = { "Jankman", 3, 9 },
    ["j_mfp_lettergem_e"] = { "E", 6, 2 },
    ["j_mfp_marigold"] = { "Marigold", 4, 20 },
    ["j_mfp_rosetinted"] = { "Rose-Tinted Glasses", 5, 5 },
    ["j_mfp_teacup"] = { "Teacup", 2, 7 },
    ["j_mfp_tealjoker"] = { "Teal Joker", 2, 7 },
    ["j_mfp_unpleasantcard"] = { "Unpleasant Card", 2, 6.5 },
    ["j_mfp_widejoker"] = { "Wide Joker", 3, 9 },
    ["j_mfp_yuckyrat"] = { "Yucky Rat", 2, 8 },
    ["j_mfp_aceupthesleeve"] = { "Ace Up The Sleeve", 5, 6 },
    ["j_mfp_balatromods"] = { "Balatro Mods (Working 2024)", 5, 3 },
    ["j_mfp_freaky_pizza"] = { "Freaky Pizza", 5, 6 },
    ["j_mfp_glitterbomb"] = { "Glitter Bomb", 5, 14 },
    ["j_mfp_sealthedeal"] = { "Seal the Deal", 5, 6 },
    -- v1.4.0 (Wave 6)
    ["j_mfp_bouncer"] = { "Bouncer", 1, 7 },
    ["j_mfp_junkmail"] = { "Junk Mail", 2, 6 },
    ["j_mfp_lettergem_b"] = { "B", 6, 6 },
    ["j_mfp_shopping_spree"] = { "Shopping Spree", 2, 6 },
    ["j_mfp_gemalert"] = { "Gem Alert", 2, 6 },
    ["j_mfp_bonussheet"] = { "Bonus Sheet", 2, 6 },
    ["j_mfp_repack"] = { "Repack", 1, 6 },
    ["j_mfp_sinew_sliver"] = { "Sinew Sliver", 1, 7 },
    ["j_mfp_muscle_sliver"] = { "Muscle Sliver", 1, 7 },
    ["j_mfp_might_sliver"] = { "Might Sliver", 2, 9 },
    ["j_mfp_megantic_sliver"] = { "Megantic Sliver", 3, 10 },
    ["j_mfp_plasma_sliver"] = { "Plasma Sliver", 2, 8 },
    ["j_mfp_astral_sliver"] = { "Astral Sliver", 2, 8 },
    ["j_mfp_fury_sliver"] = { "Fury Sliver", 3, 10 },
    ["j_mfp_mindlash_sliver"] = { "Mindlash Sliver", 2, 6 },
    ["j_mfp_quantum_sliver"] = { "Quantum Sliver", 2, 8 },
    ["j_mfp_gemhide_sliver"] = { "Gemhide Sliver", 2, 8 },
    ["j_mfp_fortunate_sliver"] = { "Fortunate Sliver", 2, 6 },
    ["j_mfp_sliver_jockey"] = { "Sliver Jockey", 2, 7 },
    ["j_mfp_paintcan"] = { "Paint Can", 2, 6 },
    ["j_mfp_rainbowjoker"] = { "Rainbow Joker", 3, 6 },
    ["j_mfp_clipart"] = { "Clipart Joker", 2, 6 },
    ["j_mfp_css"] = { "CSS", 2, 6 },
    ["j_mfp_monochrome"] = { "Monochrome Joker", 5, 6 },
    ["j_mfp_loadeddisk"] = { "Loaded Disk", 2, 6 },
}

suite.test("pack loads and registers all 133 Jokers", function()
    install_pack()
    local n = 0
    for id in pairs(JOKER_DEFS) do
        if id:sub(1, 6) == "j_mfp_" then n = n + 1 end
    end
    T.assert_eq(n, 133, "133 pack Jokers registered")
    for _, value in ipairs({ "teal", "marigold", "brass", "gemstone", "yucky" }) do
        T.assert_not_nil(SMODS.EnhancementByValue[value], value .. " enhancement registered")
        T.assert_eq(SMODS.EnhancementByValue[value].weight, 0, value .. " stays out of the polls")
    end
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

-- ---------------------------------------------------------------------------
-- Behaviour: Tier 3 top-up ports (v1.2.0)
-- ---------------------------------------------------------------------------

-- A joker_main pass with the hand-level plumbing the fork's own
-- level_up test sets up, so level_up returns land for real.
local function scored_hand(game, joker, played, hand_name)
    local idx
    for i, name in ipairs(game.handlist) do if name == hand_name then idx = i end end
    local stats = game.hand_stats[idx]
    game.selectedHand = idx
    game.selectedHandChips = stats.base_chips
    game.selectedHandMult = stats.base_mult
    local ctx = { event = "on_hand_scored", event_name = "on_hand_scored",
        chips = stats.base_chips, mult = stats.base_mult,
        hand_index = idx, hand_type = hand_name,
        cards = played, played_cards = played, full_hand = played }
    if joker:matches_trigger("on_hand_scored", ctx) then joker:apply_effect(ctx) end
    return ctx, stats
end

suite.test("tier3 return readers: x_chips, swap, e_mult", function()
    local game = install_pack()
    T.assert_near(scored(add(game, "j_mfp_unpleasantcard")).chips, 20.67, 0.01, "Unpleasant X2.067 Chips")
    local swap = scored(add(game, "j_mfp_blahaj"))
    T.assert_eq(swap.chips, 2, "Blahaj swaps Chips to the Mult value")
    T.assert_eq(swap.mult, 10, "Blahaj swaps Mult to the Chips value")
    T.assert_near(scored(add(game, "j_mfp_widejoker")).mult, 2.203, 0.01, "Wide Joker Mult ^1.14")
    T.assert_near(scored(add(game, "j_mfp_lettergem_e")).mult, 2.639, 0.01, "Letter E Mult ^1.4")
    wipe_mods()
end)

suite.test("jankman pays X1.31 Chips per modded Joker that triggers", function()
    local game = install_pack()
    add(game, "j_mfp_jankman")
    add(game, "j_mfp_jester")
    local ctx = scored_emit(game, { card(9) })
    T.assert_near(ctx.chips, 65.5, 0.01, "10 + 40 from Jester, then X1.31")
    wipe_mods()
    game = install_pack()
    add(game, "j_mfp_jankman")
    add(game, "j_jolly")
    local pair = { card(9), card(9, "Clubs") }
    ctx = { event = "on_hand_scored", event_name = "on_hand_scored", chips = 10, mult = 2,
        cards = pair, played_cards = pair, full_hand = pair,
        hand_type = "Pair", contains_hand_types = { Pair = true } }
    game:emit_joker_event("on_hand_scored", ctx)
    T.assert_near(ctx.chips, 13.1, 0.01, "Jolly Joker counts too")
    T.assert_eq(ctx.mult, 10, "Jolly's own +8 Mult on the Pair still lands")
    wipe_mods()
    game = install_pack()
    add(game, "j_mfp_jankman")
    add(game, "j_joker")
    ctx = scored_emit(game, { card(9) })
    T.assert_eq(ctx.chips, 10, "a plain vanilla Joker does not count")
    wipe_mods()
end)

suite.test("teacup levels the played hand and is spent after 5", function()
    local game = install_pack()
    local cup = add(game, "j_mfp_teacup")
    local _, stats = scored_hand(game, cup, { card(9), card(9, "Clubs") }, "Pair")
    T.assert_eq(stats.level, 2, "the played hand levelled")
    T.assert_eq(cup.ability.extra, 5, "the charge is spent in before, not yet")
    fire(cup, "on_hand_played", { played_cards = {}, full_hand = {} })
    T.assert_eq(cup.ability.extra, 4, "one charge spent")
    for _ = 1, 4 do fire(cup, "on_hand_played", { played_cards = {}, full_hand = {} }) end
    T.assert_eq(cup.ability.extra, 0)
    fire(cup, "on_hand_after", { played_cards = {}, full_hand = {} })
    T.assert_eq(#game.jokers, 0, "the spent cup destroys itself")
    wipe_mods()
end)

suite.test("flint and steel levels a Stone+Steel scoring hand only", function()
    local game = install_pack()
    local flint = add(game, "j_mfp_flintandsteel")
    local played = { card(7, "Hearts", "stone"), card(8, "Clubs", "steel") }
    local _, stats = scored_hand(game, flint, played, "Pair")
    T.assert_eq(stats.level, 2, "Stone + Steel levels the hand")
    local _, stats2 = scored_hand(game, flint, { card(7, "Hearts", "stone") }, "High Card")
    T.assert_eq(stats2.level, 1, "Stone alone does not")
    wipe_mods()
end)

suite.test("rose-tinted glasses destroys a lone first-hand 2 for a Double Tag", function()
    local game = install_pack()
    add(game, "j_mfp_rosetinted")
    game.round_hands_played = 1
    local two = SMODS.add_card { set = "Playing", rank = 2, suit = "Hearts" }
    T.assert_true(two ~= nil, "the 2 was dealt")
    local in_hand = #game.hand.card_nodes
    local tags = #(game.tags or {})
    fire(game.jokers[1], "on_hand_after", { played_cards = { two }, full_hand = { two }, cards = { two } })
    T.assert_eq(#game.hand.card_nodes, in_hand - 1, "the 2 is destroyed")
    T.assert_eq(#(game.tags or {}), tags + 1, "a tag was granted")
    T.assert_eq(game.tags[#game.tags].type, "double", "and it is the Double Tag")
    wipe_mods()
end)

suite.test("teal joker counts teal cards; teal cards pay X1.5 Chips held", function()
    local game = install_pack()
    local teal = add(game, "j_mfp_tealjoker")
    T.assert_eq(scored(teal).chips, 10, "no Teal Cards, no bonus")
    SMODS.add_card { set = "Playing", rank = 5, suit = "Hearts", enhancement = "teal" }
    SMODS.add_card { set = "Playing", rank = 6, suit = "Clubs", enhancement = "teal" }
    T.assert_near(scored(teal).chips, 14, 0.01, "X1.4 with two Teal Cards")
    local node = game.hand.card_nodes[#game.hand.card_nodes]
    local held = { chips = 10, mult = 1 }
    T.assert_true(node:emit_hand_event("held_in_hand", held))
    T.assert_near(held.chips, 15, 0.01, "a held Teal Card gives X1.5 Chips")
    wipe_mods()
end)

suite.test("marigold retriggers marigold cards; marigold cards pay per hand at round end", function()
    local game = install_pack()
    local mari = add(game, "j_mfp_marigold")
    local mcard = card(5, "Hearts", "marigold")
    local plain = card(6, "Clubs")
    T.assert_eq(mari:query_retrigger({ card_node = mcard, retrigger_card = mcard }), 2,
        "a Marigold Card retriggers twice")
    T.assert_eq(mari:query_retrigger({ card_node = plain, retrigger_card = plain }), 0,
        "a plain card does not")
    SMODS.add_card { set = "Playing", rank = 5, suit = "Hearts", enhancement = "marigold" }
    SMODS.add_card { set = "Playing", rank = 6, suit = "Clubs", enhancement = "marigold" }
    local node = game.hand.card_nodes[#game.hand.card_nodes]
    local m0 = game.money
    node:emit_hand_event("on_round_end", { chips = 0, mult = 1 })
    T.assert_eq(game.money - m0, 2, "$1 per Marigold Card in hand, paid per card")
    wipe_mods()
end)

suite.test("brass scales on destroyed brass cards and retriggers its right neighbour", function()
    local game = install_pack()
    local brass = add(game, "j_mfp_brass")
    local destroyed = { card(4, "Hearts", "brass"), card(5, "Clubs", "brass"), card(6, "Spades", "brass") }
    fire(brass, "on_destroy", { destroyed_cards = destroyed })
    T.assert_eq(brass.ability.extra.retriggers, 1, "3 destroyed Brass Cards buy a retrigger")
    T.assert_eq(brass.ability.extra.partial_rounds, 0)
    add(game, "j_mfp_jester")
    T.assert_eq(scored_emit(game, { card(9) }).chips, 90, "the right Joker triggers twice (40 x2 + 10)")
    local bcard = card(7, "Hearts", "brass")
    T.assert_eq(brass:query_retrigger({ card_node = bcard, retrigger_card = bcard }), 2,
        "a Brass Card retriggers twice while Brass Joker is held")
    wipe_mods()
end)

suite.test("gemstone joker pays per gemstone card; gemstone cards pay held at round end", function()
    local game = install_pack()
    local gem = add(game, "j_mfp_gemstonejoker")
    SMODS.add_card { set = "Playing", rank = 5, suit = "Hearts", enhancement = "gemstone", area = "deck" }
    SMODS.add_card { set = "Playing", rank = 6, suit = "Clubs", enhancement = "gemstone", area = "deck" }
    local m0 = game.money
    fire(gem, "on_round_end", {})
    T.assert_eq(game.money - m0, 2, "$1 per Gemstone Card in the full deck")
    local view = SMODS.add_card { set = "Playing", rank = 7, suit = "Spades", enhancement = "gemstone" }
    local node = game.hand.card_nodes[#game.hand.card_nodes]
    local m1 = game.money
    node:emit_hand_event("on_round_end", { chips = 0, mult = 1 })
    T.assert_eq(game.money - m1, 3, "a held Gemstone Card pays $3 at round end")
    wipe_mods()
end)

suite.test("yucky rat converts unenhanced played cards and scales", function()
    local game = install_pack()
    local rat = add(game, "j_mfp_yuckyrat")
    local plain = card(5, "Hearts")
    local lucky = card(6, "Clubs", "lucky")
    fire(rat, "on_hand_played", { played_cards = { plain, lucky }, full_hand = { plain, lucky }, cards = { plain, lucky } })
    T.assert_eq(plain.card_data.enhancement, "yucky", "the unenhanced card became Yucky")
    T.assert_eq(lucky.card_data.enhancement, "lucky", "the enhanced card was left alone")
    T.assert_near(rat.ability.extra.x_mult, 1.05, 0.001, "X0.05 per conversion")
    T.assert_near(scored(rat).mult, 2.1, 0.001, "and the grown XMult scores")
    wipe_mods()
end)

suite.test("all i can't do debuffs the first drawn hand and scales on debuffed plays", function()
    local game = install_pack()
    local aicd = add(game, "j_mfp_allicantdo")
    local n1, n2 = card(5, "Hearts"), card(6, "Clubs")
    fire(aicd, "on_hand_drawn", { drawn_cards = { n1 } })
    T.assert_true(n1.card_data.perma_debuff == nil, "not armed before the blind is set")
    fire(aicd, "on_blind_selected", {})
    fire(aicd, "on_hand_drawn", { drawn_cards = { n1, n2 } })
    T.assert_eq(n1.card_data.perma_debuff, true, "the first drawn hand is debuffed")
    T.assert_eq(n2.card_data.perma_debuff, true)
    fire(aicd, "on_hand_played", { played_cards = { n1 }, full_hand = { n1 }, cards = { n1 } })
    T.assert_near(aicd.ability.extra.x_mult, 1.1, 0.001, "X0.1 per debuffed card played")
    T.assert_near(scored(aicd).mult, 2.2, 0.001)
    wipe_mods()
end)

-- ---------------------------------------------------------------------------
-- Behaviour: Wave 1 top-up ports (v1.3.0)
-- ---------------------------------------------------------------------------

suite.test("wave1 polls deal pollable centers and never the pack's weight-0 enhancements", function()
    local game = install_pack()
    local vanilla_enh = { bonus = true, mult = true, wild = true, glass = true,
        steel = true, stone = true, gold = true, lucky = true }
    for _ = 1, 40 do
        local v = SMODS.poll_enhancement({ guaranteed = true, no_replace = true })
        T.assert_true(vanilla_enh[v] == true, "polled a pollable enhancement: " .. tostring(v))
    end
    local vanilla_seal = { gold = true, red = true, blue = true, purple = true }
    for _ = 1, 40 do
        local v = SMODS.poll_seal({ guaranteed = true })
        T.assert_true(vanilla_seal[v] == true, "polled a pollable seal: " .. tostring(v))
    end
    T.assert_eq(SMODS.poll_enhancement({ key = "lucky", guaranteed = true }), "lucky",
        "key deals that specific center")
    wipe_mods()
end)

suite.test("freaky pizza logs chips and gains freakiness at round end", function()
    local game = install_pack()
    local pizza = add(game, "j_mfp_freaky_pizza")
    T.assert_eq(scored(pizza).chips, 10, "log_23(10) < 1: a small total is untouched")
    local ctx = { event = "on_hand_scored", event_name = "on_hand_scored", chips = 529, mult = 2,
        cards = {}, played_cards = {}, full_hand = {} }
    if pizza:matches_trigger("on_hand_scored", ctx) then pizza:apply_effect(ctx) end
    T.assert_near(ctx.chips, 1058, 0.01, "log_23(529) = 2: Chips are doubled")
    fire(pizza, "on_round_end", {})
    T.assert_eq(pizza.ability.extra.freakiness, 46, "+23 Freakiness at end of round")
    fire(pizza, "on_round_end", {})
    T.assert_eq(pizza.ability.extra.freakiness, 69, "and +23 again the next round")
    wipe_mods()
end)

suite.test("ace up the sleeve deals an enhanced ace at one hand left", function()
    local game = install_pack()
    local ace = add(game, "j_mfp_aceupthesleeve")
    game.hands = 2
    fire(ace, "on_hand_after", { played_cards = {}, full_hand = {}, cards = {} })
    T.assert_eq(#game.hand.card_nodes, 0, "nothing at 2 hands left")
    game.hands = 1
    fire(ace, "on_hand_after", { played_cards = {}, full_hand = {}, cards = {} })
    T.assert_eq(#game.hand.card_nodes, 1, "an Ace was added at 1 hand left")
    local node = game.hand.card_nodes[1]
    -- A Stone poll parks the rank in _stone_rank (the engine's own
    -- representation); every other enhancement leaves it in rank.
    local rank = node.card_data.rank or node.card_data._stone_rank
    T.assert_eq(rank, 14, "the added card is an Ace")
    T.assert_true(node.card_data.enhancement ~= nil, "and it carries a polled enhancement")
    wipe_mods()
end)

suite.test("balatro mods enhances a lone first-hand card for $2", function()
    local game = install_pack()
    local mods = add(game, "j_mfp_balatromods")
    game.money = 10
    game.round_hands_played = 1
    local lone = card(7, "Clubs")
    before(mods, { lone })
    T.assert_eq(game.money, 8, "$2 spent on the lone first-hand card")
    T.assert_true(lone.card_data.enhancement ~= nil, "the card gained a polled enhancement")
    local second = card(8, "Clubs")
    game.round_hands_played = 2
    before(mods, { second })
    T.assert_eq(game.money, 8, "no spend after the first hand")
    T.assert_eq(second.card_data.enhancement, nil, "and no enhancement")
    local a, b = card(9), card(10)
    game.round_hands_played = 1
    before(mods, { a, b })
    T.assert_eq(game.money, 8, "no spend on a two-card first hand")
    T.assert_eq(a.card_data.enhancement, nil)
    T.assert_eq(b.card_data.enhancement, nil)
    wipe_mods()
end)

suite.test("glitter bomb enhances every held card when sold", function()
    local game = install_pack()
    local bomb = add(game, "j_mfp_glitterbomb")
    local a, b = card(5), card(6, "Clubs")
    game.hand.card_nodes = { a, b }
    fire(bomb, "on_joker_sold", { joker = bomb })
    T.assert_true(a.card_data.enhancement ~= nil, "the first held card was enhanced")
    T.assert_true(b.card_data.enhancement ~= nil, "the second held card was enhanced")
    wipe_mods()
    game = install_pack()
    local bomb2 = add(game, "j_mfp_glitterbomb")
    game.hand.card_nodes = {}
    fire(bomb2, "on_joker_sold", { joker = bomb2 })
    T.assert_eq(#game.hand.card_nodes, 0, "sold with an empty hand: nothing happens")
    wipe_mods()
end)

suite.test("seal the deal seals an unsealed played card on a winning hand only", function()
    local game = install_pack()
    local deal = add(game, "j_mfp_sealthedeal")
    game.current_blind_target = 300
    game.round_score = 100
    local a, b = card(5), card(6, "Clubs")
    fire(deal, "on_hand_after", { played_cards = { a, b }, full_hand = { a, b }, cards = { a, b } })
    T.assert_eq(a.card_data.seal, nil, "a losing hand seals nothing")
    T.assert_eq(b.card_data.seal, nil)
    game.round_score = 300
    fire(deal, "on_hand_after", { played_cards = { a, b }, full_hand = { a, b }, cards = { a, b } })
    local sealed = (a.card_data.seal and 1 or 0) + (b.card_data.seal and 1 or 0)
    T.assert_eq(sealed, 1, "a winning hand seals exactly one played card")
    local c = card(7, "Spades")
    c.card_data.seal = "red"
    c.seal = "red"
    local d = card(8, "Diamonds")
    fire(deal, "on_hand_after", { played_cards = { c, d }, full_hand = { c, d }, cards = { c, d } })
    T.assert_eq(c.card_data.seal, "red", "an already-sealed card keeps its seal")
    T.assert_true(d.card_data.seal ~= nil, "the unsealed card is the one sealed")
    wipe_mods()
end)

--------------------------------------------------------------------------------
-- Wave 6 (v1.4.0): shop, booster, Sliver and Colour behavior
--------------------------------------------------------------------------------

local function calc(joker, ctx)
    return joker.def.smods.calculate(joker.def.smods, joker, ctx)
end

local function scored6(joker, played)
    played = played or {}
    local ctx = { event = "on_hand_scored", event_name = "on_hand_scored",
        chips = 10, mult = 2, xmult = 1, e_mult = 1,
        cards = played, played_cards = played, full_hand = played }
    if joker:matches_trigger("on_hand_scored", ctx) then
        joker:apply_effect(ctx)
    end
    return ctx
end

suite.test("wave6 bouncer: the Joker to the right returns to the shop", function()
    local game = install_pack()
    local b = add(game, "j_mfp_bouncer")
    local idx = #game.jokers + 1
    assert(game:add_joker_by_def("j_joker"))
    local target = game.jokers[idx]
    local sell = target.sell_cost or 0
    game:enter_shop_after_blind()
    local still_held = false
    for _, j in ipairs(game.jokers) do
        if j == target then still_held = true end
    end
    T.assert_false(still_held, "the neighbour left the Joker row")
    T.assert_eq(b.ability.extra.chips, sell * 3,
        "Bouncer gained +3 Chips per $1 of sell value")
    local offered = false
    for _, o in ipairs(game.shop_offers) do
        if o.id == "j_joker" then offered = true end
    end
    T.assert_true(offered, "the neighbour is a shop offer now")
    local fish = false
    for _, j in ipairs(game.jokers) do
        if j.def.id == "j_mfp_fish" then fish = true end
    end
    T.assert_true(fish, "and a Fish was created (it was a Joker)")
    wipe_mods()
end)

suite.test("wave6 junk mail + B + repack: the shop gains their offers", function()
    local game = install_pack()
    add(game, "j_mfp_junkmail")
    add(game, "j_mfp_lettergem_b")
    add(game, "j_mfp_repack")
    game:enter_shop_after_blind()
    T.assert_eq(#game.shop_voucher_offers, 2,
        "Junk Mail shelved a second voucher")
    local junk = game.shop_voucher_offers[2]
    T.assert_eq(junk.price_fac, 1.5, "at 1.5x price")
    T.assert_eq(game:get_shop_voucher_price(junk),
        math.floor(10 * 1.5 + 0.5), "the getter applies the factor")
    local packs = {}
    for _, o in ipairs(game.shop_booster_offers) do packs[o.pack] = o end
    T.assert_true(packs.buffoon ~= nil
        and game:get_shop_booster_price(packs.buffoon) == 7,
        "B's $7 Buffoon Pack is shelved")
    T.assert_true(packs.modded_normal_1 ~= nil
        and packs.modded_normal_2 ~= nil,
        "Repack's two Modded Packs are shelved")
    game:begin_booster_session(packs.modded_normal_1)
    local all_mod = true
    for _, c in ipairs(game.booster_session.choices) do
        local def = (c.joker_id and JOKER_DEFS[c.joker_id])
            or (c.consumable_def and CONSUMABLE_DEFS[c.consumable_def.id])
        if not (def and def.mod_id) then all_mod = false end
    end
    T.assert_true(all_mod, "the Modded Pack deals only mod content")
    game:end_booster_session()
    wipe_mods()
end)

suite.test("wave6 shopping spree: thresholds land through the seats", function()
    local game = install_pack()
    local j = add(game, "j_mfp_shopping_spree")
    local base = game.shop_reroll_base_cost or 5
    for _ = 1, 15 do fire(j, "on_shop_reroll", {}) end
    T.assert_eq(j.ability.extra.rerolls, 15)
    T.assert_eq(game.shop_reroll_base_cost, base - 2,
        "rerolls are $2 cheaper at 15")
    for _ = 1, 4 do fire(j, "on_blind_skipped", {}) end
    T.assert_eq(j.ability.extra.skips, 4)
    T.assert_eq(j.ability.shop_size_mod, 1, "the shop slot is declared")
    T.assert_eq(SMODS.modifier_total(game, "shop_size_mod"), 1)
    j.def.smods.remove_from_deck(j.def.smods, j)
    T.assert_eq(game.shop_reroll_base_cost, base,
        "losing the Joker restores the reroll cost")
    wipe_mods()
end)

suite.test("wave6 gem alert: rare_mod and shop scaling", function()
    local game = install_pack()
    local j = add(game, "j_mfp_gemalert")
    T.assert_eq(game.rare_mod, 6.7, "rare_mod moved on gain")
    fire(j, "on_store_joker_modify", {
        offer_view = { id = "j_x", kind = "joker", edition = "base",
            rarity = 3, price = 8 },
        offer = {},
    })
    T.assert_eq(j.ability.extra.xmult, 1.1,
        "a Rare shop Joker scaled it by X0.1")
    j.def.smods.remove_from_deck(j.def.smods, j)
    T.assert_eq(game.rare_mod, 1, "rare_mod restored on loss")
    wipe_mods()
end)

suite.test("wave6 bonus sheet: a hidden-rarity Joker joins the Buffoon Pack", function()
    local game = install_pack()
    add(game, "j_mfp_bonussheet")
    game:enter_shop_after_blind()
    game:begin_booster_session({ kind = "booster", pack = "buffoon",
        size = "normal", price = 4, name = "Buffoon Pack",
        card_count = 2, picks_granted = 1 })
    local choices = game.booster_session.choices
    T.assert_eq(#choices, 3, "2 dealt + 1 appended")
    local appended = choices[3]
    T.assert_true(appended.joker_id ~= nil, "the appended choice is a Joker")
    local def = JOKER_DEFS[appended.joker_id]
    T.assert_eq(def.mod_id, "MoreFluffPack")
    T.assert_true(def.rarity == SMODS.Rarities.mfp_oldfluff.index
        or def.rarity == SMODS.Rarities.mfp_letter.index,
        "of a hidden rarity (oldfluff or letter)")
    game:end_booster_session()
    wipe_mods()
end)

suite.test("wave6 slivers: grants flow to every Sliver, self included", function()
    local game = install_pack()
    local sinew = add(game, "j_mfp_sinew_sliver")
    local ctx = scored(sinew, { card(9, "Hearts") })
    T.assert_eq(ctx.chips, 50, "a lone Sinew grants itself +40 Chips")
    local muscle = add(game, "j_mfp_muscle_sliver")
    local ctx2 = scored(sinew, { card(9, "Hearts") })
    T.assert_eq(ctx2.chips, 50, "Sinew still gets its Chips")
    T.assert_eq(ctx2.mult, 6, "and Muscle's granted +4 Mult (2 base + 4)")
    local ctx3 = scored(muscle, { card(9, "Hearts") })
    T.assert_eq(ctx3.chips, 50, "Muscle receives Sinew's grant too")
    wipe_mods()
end)

suite.test("wave6 slivers: plasma blends, might and megantic multiply", function()
    local game = install_pack()
    add(game, "j_mfp_plasma_sliver")
    local fury = add(game, "j_mfp_fury_sliver")
    local ctx = scored6(fury, { card(9, "Hearts") })
    T.assert_true(math.abs(ctx.chips - 9.2) < 0.01,
        "10% blend moved Chips 10 -> 9.2, got " .. tostring(ctx.chips))
    T.assert_true(math.abs(ctx.mult - 2.8) < 0.01,
        "and Mult 2 -> 2.8, got " .. tostring(ctx.mult))
    wipe_mods()

    local game2 = install_pack()
    add(game2, "j_mfp_might_sliver")
    local meg = add(game2, "j_mfp_megantic_sliver")
    local ctx2 = scored6(meg, { card(9, "Hearts") })
    T.assert_true(math.abs(ctx2.mult - (2 * 1.2) ^ 1.08) < 0.01,
        "Might X1.2 then Megantic ^1.08 fold into Mult, got "
        .. tostring(ctx2.mult))
    wipe_mods()
end)

suite.test("wave6 slivers: fury, jockey, astral, quantum, gemhide, fortunate", function()
    local game = install_pack()
    local fury = add(game, "j_mfp_fury_sliver")
    local ret = calc(fury, { retrigger_joker_check = true,
        other_card = fury })
    T.assert_eq(ret and ret.repetitions, 1,
        "Fury's grant retriggers the host itself")
    local host = add(game, "j_mfp_sinew_sliver")
    local ret2 = calc(host, { retrigger_joker_check = true,
        other_card = host })
    T.assert_eq(ret2 and ret2.repetitions, 1,
        "and to any other Sliver host checking in")

    local game2 = install_pack()
    local jockey = add(game2, "j_mfp_sliver_jockey")
    local n1, n2 = card(5, "Hearts"), card(7, "Clubs")
    local ret3 = calc(jockey, { repetition = true, cardarea = G.play,
        other_card = n1, scoring_hand = { n1, n2 } })
    T.assert_eq(ret3 and ret3.repetitions, 1,
        "position 1 card, position 1 Joker: retrigger")
    local ret4 = calc(jockey, { repetition = true, cardarea = G.play,
        other_card = n2, scoring_hand = { n1, n2 } })
    T.assert_true(ret4 == nil or ret4.repetitions == nil,
        "position 2 card: no retrigger")

    local game3 = install_pack()
    local astral = add(game3, "j_mfp_astral_sliver")
    local real_prob = SMODS.pseudorandom_probability
    SMODS.pseudorandom_probability = function() return true, 1 end
    local ret5 = calc(astral, { before = true })
    SMODS.pseudorandom_probability = real_prob
    T.assert_true(ret5 ~= nil and ret5.level_up == true,
        "Astral's grant levels the hand on a hit")

    local game4 = install_pack()
    local quantum = add(game4, "j_mfp_quantum_sliver")
    local before_n = #game4.consumables
    SMODS.pseudorandom_probability = function() return true, 1 end
    calc(quantum, { setting_blind = true })
    SMODS.pseudorandom_probability = real_prob
    T.assert_eq(#game4.consumables, before_n + 1,
        "Quantum's grant created a consumable")

    local game5 = install_pack()
    local gem = add(game5, "j_mfp_gemhide_sliver")
    local money = game5.money
    fire(gem, "on_round_end", {})
    T.assert_eq(game5.money, money + 2,
        "Gemhide's grant pays $2 at round end")

    local game6 = install_pack()
    add(game6, "j_mfp_fortunate_sliver")
    local _, den = SMODS.modify_probability(nil, "mf_test", 1, 8)
    T.assert_eq(den, 7, "Fortunate's grant cuts denominators by 1")
    wipe_mods()
end)

suite.test("wave6 mindlash: selling a Sliver disables the Boss Blind", function()
    local game = install_pack()
    local m = add(game, "j_mfp_mindlash_sliver")
    game.current_blind_index = 3
    game.STATE = game.STATES.SELECTING_HAND
    T.assert_true(game:get_active_boss_blind_id() ~= nil,
        "a Boss Blind is active in this setup")
    calc(m, { selling_self = true })
    T.assert_true(game.boss_runtime
        and game.boss_runtime.disable_current_boss_ability == true,
        "the Boss Blind is disabled")
    wipe_mods()
end)

suite.test("wave6 colour: growth, tags, creations and perma effects", function()
    local game = install_pack()
    assert(game:add_consumable("c_mfp_grey"))
    local grey = game.consumables[#game.consumables]
    T.assert_eq(grey.ability.val, 0, "Colour cards start at val 0")
    SMODS.consumable_end_of_round(game)
    T.assert_eq(grey.ability.partial_rounds, 1, "one round banked")
    SMODS.consumable_end_of_round(game)
    SMODS.consumable_end_of_round(game)
    T.assert_eq(grey.ability.val, 1, "val 1 after 3 rounds (Grey)")
    T.assert_eq(grey.ability.partial_rounds, 0)
    grey.ability.val = 2
    game.STATE = game.STATES.SHOP
    local tags = #game.tags
    game:use_consumable(1)
    T.assert_eq(#game.tags, tags + 2, "Grey at val 2 makes two Double Tags")
    T.assert_eq(game.tags[#game.tags].type, "double")

    assert(game:add_consumable("c_mfp_deepblue"))
    local deep = game.consumables[#game.consumables]
    deep.ability.val = 2
    local n1, n2 = card(4, "Hearts"), card(6, "Clubs")
    game.hand.card_nodes = { n1, n2 }
    game:use_consumable(1)
    local total = (SMODS.get_perma(n1, "perma_bonus") or 0)
        + (SMODS.get_perma(n2, "perma_bonus") or 0)
    T.assert_eq(total, 40, "Deep Blue at val 2 grants +20 Chips twice")
    wipe_mods()
end)

suite.test("wave6 colour: paint can speeds growth, pink grows others", function()
    local game = install_pack()
    add(game, "j_mfp_paintcan")
    assert(game:add_consumable("c_mfp_blue"))
    local blue = game.consumables[#game.consumables]
    local real_prob = SMODS.pseudorandom_probability
    SMODS.pseudorandom_probability = function() return true, 1 end
    SMODS.consumable_end_of_round(game)
    SMODS.pseudorandom_probability = real_prob
    T.assert_eq(blue.ability.val, 1,
        "two ticks in one round (base + Paint Can) upgrade Blue (2 rounds)")
    assert(game:add_consumable("c_mfp_pink"))
    local pink = game.consumables[#game.consumables]
    pink.ability.val = 1
    game.STATE = game.STATES.SHOP
    game:use_consumable(2)
    T.assert_eq(blue.ability.partial_rounds, 1,
        "Pink ran a growth trigger on the held Blue")
    wipe_mods()
end)

suite.test("wave6 colour jokers: rainbow, monochrome, clipart, loaded disk, css", function()
    local game = install_pack()
    local rainbow = add(game, "j_mfp_rainbowjoker")
    local ctx0 = scored6(rainbow, { card(9, "Hearts") })
    T.assert_eq(ctx0.mult, 2, "no Colour held, no XMult")
    assert(game:add_consumable("c_mfp_red"))
    assert(game:add_consumable("c_mfp_blue"))
    local ctx = scored6(rainbow, { card(9, "Hearts") })
    T.assert_true(math.abs(ctx.mult - 2 * 2.25) < 0.001,
        "two Colour cards give X1.5^2 Mult, got " .. tostring(ctx.mult))

    local game2 = install_pack()
    local mono = add(game2, "j_mfp_monochrome")
    fire(mono, "on_blind_selected", {})
    T.assert_eq(mono.ability.extra.mult, 4,
        "a round without Colour: +2 Mult (2 -> 4)")
    assert(game2:add_consumable("c_mfp_red"))
    fire(mono, "on_blind_selected", {})
    T.assert_eq(mono.ability.extra.mult, 2,
        "a round with Colour held: reset to +2")

    local game3 = install_pack()
    local clip = add(game3, "j_mfp_clipart")
    fire(clip, "on_blind_selected", {})
    T.assert_eq(#game3.consumables, 1, "Clipart created a Colour card")
    T.assert_eq(game3.consumables[1].kind, "Colour")

    local game4 = install_pack()
    local disk = add(game4, "j_mfp_loadeddisk")
    fire(disk, "on_joker_sold", { joker = disk })
    T.assert_eq(#game4.consumables, 1, "Loaded Disk created a card on sale")
    T.assert_eq(game4.consumables[1].id, "c_mfp_pink", "the Pink")

    local game5 = install_pack()
    local css = add(game5, "j_mfp_css")
    fire(css, "on_hand_scored", {
        contains_hand_types = { Flush = true },
    })
    T.assert_eq(#game5.consumables, 1, "CSS created a Colour card on a Flush")
    T.assert_eq(game5.consumables[1].kind, "Colour")
    wipe_mods()
end)

suite.test("wave6 colour packs: a Colour Pack deals Colour cards", function()
    local game = install_pack()
    game:enter_shop_after_blind()
    game:begin_booster_session({ kind = "booster", pack = "colour_normal_1",
        size = "normal", price = 4, name = "Colour Pack",
        card_count = 2, picks_granted = 1 })
    local s = game.booster_session
    T.assert_eq(#s.choices, 2)
    for _, c in ipairs(s.choices) do
        T.assert_true(c.consumable_def ~= nil
            and c.consumable_def.kind == "Colour",
            "every choice is a Colour card")
    end
    game:end_booster_session()
    wipe_mods()
end)

return suite
