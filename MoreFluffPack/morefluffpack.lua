--[[
    MoreFluffPack - MoreFluff Jokers ported to Balatro3DS.

    Jokers ported from MoreFluff by notmario (PC / Steamodded):
    https://github.com/notmario/MoreFluff (no license file in the PC
    repo; unofficial fan port, credit in README.txt).

    Port notes:
      * The six v1.0.0 Jokers keep their original port keys
        (bowling_ball, pixel_joker, jack_of_all_trades) for save
        compatibility; newer ports use the PC key verbatim.
      * MoreFluff's six custom rarities are registered below with
        weight 0: on PC they reach the player through hidden-rarity
        rolls, Letter packs, Rotarots and token creation, none of
        which the fork can register, so none of them may take shop
        share here. Their Jokers are created by other ported Jokers
        (Forge, Letter F, ...) or held from debug creation.
      * Descriptions are the mod's en-us text, verbatim except for
        stripped Steamodded font/size attributes the fork ignores.
      * Deviations from PC behaviour are listed in README.txt.
]]

-- Live reference to the running game, refreshed on every call.
local G

local function refresh_g()
    G = rawget(_G, "G") or G
    return G
end

-- Boss Blind? The fork's blind-selected / round-end events carry it
-- on context.port; the game object carries the blind index.
local function mf_is_boss(context)
    if context and context.port and context.port.is_boss_blind ~= nil then
        return context.port.is_boss_blind == true
    end
    local g = refresh_g()
    return g ~= nil and tonumber(g.current_blind_index) == 3
end

-- Hands played this round (fork getter; PC G.GAME.current_round).
local function mf_hands_played()
    local g = refresh_g()
    if g and g.get_round_hands_played then return tonumber(g:get_round_hands_played()) or 0 end
    return 0
end

-- A random Joker def id the way the shop rolls rarities
-- (Common 70 / Uncommon 25 / Rare 5), via the game's own pool roll.
local function mf_random_joker_id(seed)
    local g = refresh_g()
    if not (g and g.random_joker_def_id_by_rarity) then return nil end
    local roll = pseudorandom(seed or "mf_random_joker")
    local rarity = roll < 0.70 and 1 or (roll < 0.95 and 2 or 3)
    return g:random_joker_def_id_by_rarity(rarity, seed or "mf_random_joker")
end

local function mf_create_random_joker(seed)
    local id = mf_random_joker_id(seed)
    if id then return SMODS.add_card { set = "Joker", key = id } end
    return nil
end

local function mf_create_random_consumable(kind, seed)
    local g = refresh_g()
    if not (g and g.random_consumable_id_of_kind) then return nil end
    local id = g:random_consumable_id_of_kind(kind, nil, seed or "mf_consumable")
    if id then return SMODS.add_card { set = kind:sub(1, 1):upper() .. kind:sub(2), key = id } end
    return nil
end

-- Index (1-based) of a Joker in the held-Joker list, or nil.
local function mf_joker_index(card)
    local g = refresh_g()
    local list = g and g.jokers
    if type(list) == "table" and type(list.cards) == "table" then list = list.cards end
    if type(list) ~= "table" then return nil end
    for i, j in ipairs(list) do if j == card then return i, list end end
    return nil
end

local function mf_held_jokers()
    local g = refresh_g()
    local list = g and g.jokers
    if type(list) == "table" and type(list.cards) == "table" then list = list.cards end
    if type(list) ~= "table" then return {} end
    return list
end

-- Chip value of a scoring card view (PC base.nominal + perma bonus;
-- Stone counts 50).
local MF_FACE_CHIPS = { [11] = 10, [12] = 10, [13] = 10, [14] = 11 }
local function mf_chip_value(view)
    local data = (view and view.card_data) or {}
    if data.enhancement == "stone" then return 50 + (tonumber(data.Bonus) or 0) end
    local rank = tonumber(data.rank) or (view and view.get_id and view:get_id()) or 0
    local base = MF_FACE_CHIPS[rank] or rank
    return base + (tonumber(data.Bonus) or tonumber(data.chip_bonus) or 0)
end

local function mf_round2(x) return math.floor(x * 100 + 0.5) / 100 end

--------------------------------------------------------------------------------
-- MoreFluff's custom rarities (PC src/rarities.lua). Weight 0: see header.
--------------------------------------------------------------------------------

if SMODS.Rarity then
    SMODS.Rarity { key = "oldfluff", loc_txt = { name = "Scrapped" }, badge_colour = "#000000", weight = 0 }
    SMODS.Rarity { key = "letter", loc_txt = { name = "Letter" }, badge_colour = "#a9683b", weight = 0 }
    SMODS.Rarity { key = "purple", loc_txt = { name = "Purple" }, badge_colour = "#8d00ab", weight = 0 }
    SMODS.Rarity { key = "token", loc_txt = { name = "Token" }, badge_colour = "#474747", weight = 0 }
    SMODS.Rarity { key = "superlegendary", loc_txt = { name = "Superlegendary" }, badge_colour = "#2852FF", weight = 0 }
    SMODS.Rarity { key = "rot_legendary", loc_txt = { name = "Legendary!" }, badge_colour = "#2852FF", weight = 0 }
end
-- Jester: +40 Chips.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "jester",
    loc_txt = {
        name = "Jester",
        text = {
            "{C:chips}+#1#{} Chips",
        },
    },
    config = { extra = { chips = 40 } },
    rarity = 1,
    cost = 2,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "jester.png",
    negative_sprite = "jester_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chips } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            return { chips = card.ability.extra.chips }
        end
    end,
}

--------------------------------------------------------------------------------
-- Bowling Ball: played 3s give +60 Chips and +10 Mult when scored.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "bowling_ball",
    loc_txt = {
        name = "Bowling Ball",
        text = {
            "Played {C:attention}3s{}",
            "give {C:chips}+#1#{} Chips",
            "and {C:mult}+#2#{} Mult",
            "when scored",
        },
    },
    config = { extra = { chips = 60, mult = 10 } },
    rarity = 3,
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "bowling_ball.png",
    negative_sprite = "bowling_ball_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chips, card.ability.extra.mult } }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            if context.other_card:get_id() == 3 then
                return { chips = card.ability.extra.chips, mult = card.ability.extra.mult }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Pixel Joker: scored Aces, 4s and 9s each give X1.5 Mult.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "pixel_joker",
    loc_txt = {
        name = "Pixel Joker",
        text = {
            "Played {C:attention}Aces{},",
            "{C:attention}4s{} and {C:attention}9s{} each give",
            "{X:mult,C:white} X#1# {} Mult when scored",
        },
    },
    config = { extra = { x_mult = 1.5 } },
    rarity = 3,
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "pixel_joker.png",
    negative_sprite = "pixel_joker_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.x_mult } }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            local id = context.other_card:get_id()
            if id == 14 or id == 4 or id == 9 then
                return { xmult = card.ability.extra.x_mult }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Jack of all Trades: each Jack held in hand gives +2 Mult, +10 Chips
-- and $1.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "jack_of_all_trades",
    loc_txt = {
        name = "Jack of All Trades",
        text = {
            "Each {C:attention}Jack{} held",
            "in hand gives {C:mult}+#1#{} Mult,",
            "{C:chips}+#2#{} Chips, and {C:money}$#3#",
        },
    },
    config = { extra = { mult = 2, chips = 10, dollars = 1 } },
    rarity = 1,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "jack_of_all_trades.png",
    negative_sprite = "jack_of_all_trades_negative.png",
    loc_vars = function(self, info_queue, card)
        local extra = card.ability.extra
        return { vars = { extra.mult, extra.chips, extra.dollars } }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.hand and not context.end_of_round then
            if context.other_card:get_id() == 11 then
                local extra = card.ability.extra
                return { mult = extra.mult, chips = extra.chips, dollars = extra.dollars }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Clownfish: enhanced cards give +15 Chips and +4 Mult when scored.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "clownfish",
    loc_txt = {
        name = "Clownfish",
        text = {
            "{C:attention}Enhanced{} cards",
            "score {C:chips}+#1#{} more Chips",
            "and {C:mult}+#2#{} more Mult",
            "when scored",
        },
    },
    config = { extra = { chips = 15, mult = 4 } },
    rarity = 1,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "clownfish.png",
    negative_sprite = "clownfish_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chips, card.ability.extra.mult } }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            if context.other_card.enhancement ~= nil then
                return { chips = card.ability.extra.chips, mult = card.ability.extra.mult }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- The Solo: gains X0.1 Mult whenever a hand of exactly 1 card is played.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "the_solo",
    loc_txt = {
        name = "The Solo",
        text = {
            "Gains {X:mult,C:white} X#2# {} Mult if played",
            "hand has only {C:attention}1{} card",
            "{C:inactive}(Currently {X:mult,C:white} X#1# {C:inactive} Mult)",
        },
    },
    config = { extra = { x_mult = 1, x_mult_gain = 0.1 } },
    rarity = 3,
    cost = 7,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    sprite = "the_solo.png",
    negative_sprite = "the_solo_negative.png",
    loc_vars = function(self, info_queue, card)
        local extra = card.ability.extra
        return { vars = { extra.x_mult, extra.x_mult_gain } }
    end,
    calculate = function(self, card, context)
        local extra = card.ability.extra
        if context.before and not context.blueprint then
            if context.full_hand and #context.full_hand == 1 then
                extra.x_mult = math.floor((extra.x_mult + extra.x_mult_gain) * 100 + 0.5) / 100
                return { message = "X" .. extra.x_mult .. " Mult" }
            end
        end
        if context.joker_main and extra.x_mult ~= 1 then
            return { xmult = extra.x_mult }
        end
    end,
}

--------------------------------------------------------------------------------
-- Bad Legal Defence: create Death on Boss Blind selected.
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "badlegaldefence",
    loc_txt = { name = "Bad Legal Defence", text = { "Create a {C:attention}Death{} {C:tarot}Tarot{}", "when {C:attention}Boss Blind{}", "is selected", "{C:inactive}(Must have room)" } },
    config = { extra = {} },
    rarity = 2, cost = 6, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "badlegaldefence.png", negative_sprite = "badlegaldefence_negative.png",
    calculate = function(self, card, context)
        refresh_g()
        if context.setting_blind and mf_is_boss(context) then
            if SMODS.add_card { set = "Tarot", key = "tarot_death" } then
                return { message = "Death!" }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- The Baseball Stream: Uncommon Jokers give X1.25; other Rare Jokers
-- held also grant it (PC calculate_extra_effects hook, folded in here).
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "baseball_stream",
    loc_txt = { name = "The Baseball Stream", text = { "{C:uncommon}Uncommon{} {C:attention}Jokers", "give {X:mult,C:white} X#1# {} Mult", "Other {C:rare}Rare{} {C:attention}Jokers{} have", "{C:inactive}\"Uncommon Jokers give {X:mult,C:white} X1.25 {C:inactive} Mult\"" } },
    config = { extra = { xmult = 1.25 } },
    rarity = 3, cost = 10, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "baseball_stream.png", negative_sprite = "baseball_stream_negative.png",
    loc_vars = function(self, info_queue, card) return { vars = { card.ability.extra.xmult } } end,
    calculate = function(self, card, context)
        refresh_g()
        if context.post_trigger and context.other_card and context.other_card ~= card then
            local def = context.other_card.def
            if def and tonumber(def.rarity) == 2 then
                local grants = 1
                for _, j in ipairs(mf_held_jokers()) do
                    if j ~= card and j ~= context.other_card and j.def and tonumber(j.def.rarity) == 3 then
                        grants = grants + 1
                    end
                end
                local x = 1
                for _ = 1, grants do x = x * card.ability.extra.xmult end
                if x ~= 1 then return { xmult = x } end
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Basepaul Card: X1.25 Mult (X12.5 for Paul: profile name unavailable).
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "basepaul_card",
    loc_txt = { name = "Basepaul Card", text = { "{X:mult,C:white} X#1# {} Mult. {X:mult,C:white} X#2# {} Mult", "instead for {C:red}Paul{}", "{C:inactive}(Who's Paul?)" } },
    config = { extra = { x_mult = 1.25 } },
    rarity = 1, cost = 5, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "basepaul_card.png", negative_sprite = "basepaul_card_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.x_mult, card.ability.extra.x_mult * 10 } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then return { xmult = card.ability.extra.x_mult } end
    end,
}

--------------------------------------------------------------------------------
-- [[BIG SHOT]]: scored Aces/9s/7s earn $1; retrigger played 9s.
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "bigshot",
    loc_txt = { name = "[[BIG SHOT]]", text = { "Played {C:attention}Aces{},", "{C:attention}9s{}, and {C:attention}7s{} earn", "{C:money}$#1#{} when scored", "Retrigger all played {C:attention}9s{}" } },
    config = { extra = { money = 1 } },
    rarity = "oldfluff", cost = 7, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "bigshot.png", negative_sprite = "bigshot_negative.png",
    loc_vars = function(self, info_queue, card) return { vars = { card.ability.extra.money } } end,
    calculate = function(self, card, context)
        refresh_g()
        if context.individual and context.cardarea == G.play and context.other_card then
            local id = context.other_card:get_id()
            if id == 14 or id == 9 or id == 7 then return { dollars = card.ability.extra.money } end
        end
        if context.repetition and context.cardarea == G.play and context.other_card then
            if context.other_card:get_id() == 9 then return { repetitions = 1 } end
        end
    end,
}

--------------------------------------------------------------------------------
-- Black Market: on Boss Blind, spend $10 to create an Ankh.
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "blackmarket",
    loc_txt = { name = "Black Market", text = { "When {C:attention}Boss Blind{}", "is selected, spend {C:attention}$10{}", "to summon an {C:spectral}Ankh{} card" } },
    config = { extra = { cost = 10 } },
    rarity = "oldfluff", cost = 4, unlocked = true, discovered = true,
    blueprint_compat = false, eternal_compat = true, perishable_compat = true,
    sprite = "blackmarket.png", negative_sprite = "blackmarket_negative.png",
    loc_vars = function(self, info_queue, card) return { vars = { card.ability.extra.cost } } end,
    calculate = function(self, card, context)
        refresh_g()
        if context.setting_blind and not context.blueprint and mf_is_boss(context) then
            if G and (tonumber(G.money) or 0) >= card.ability.extra.cost then
                local made = SMODS.add_card { set = "Spectral", key = "spectral_ankh" }
                if made then
                    ease_dollars(-card.ability.extra.cost)
                    return { message = "+Ankh" }
                end
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Blade Dance: add 2 Steel cards to hand at round start (PC: temporary).
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "bladedance",
    loc_txt = { name = "Blade Dance", text = { "Adds {C:attention}#1#{} temporary", "{C:attention}Steel Cards{}", "to your deck when", "blind is selected" } },
    config = { extra = { count = 2 } },
    rarity = 2, cost = 8, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "bladedance.png", negative_sprite = "bladedance_negative.png",
    loc_vars = function(self, info_queue, card) return { vars = { card.ability.extra.count } } end,
    calculate = function(self, card, context)
        refresh_g()
        if context.first_hand_drawn then
            local suits = { "Hearts", "Clubs", "Diamonds", "Spades" }
            for i = 1, card.ability.extra.count do
                local rank = pseudorandom_element({ 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14 }, "bladedance_rank" .. i)
                local suit = pseudorandom_element(suits, "bladedance_suit" .. i)
                SMODS.add_card { set = "Playing", rank = rank, suit = suit, enhancement = "steel", bypass_limit = true }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Blood Pact (Contract from Below): X5 if all Hearts, else self-destruct.
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "bloodpact",
    loc_txt = { name = "Contract from Below", text = { "{X:mult,C:white} X#1# {} Mult", "{C:red}Self destructs{} if you play", "a non-{C:hearts}Hearts{} card" } },
    config = { extra = { xmult = 5 } },
    rarity = 3, cost = 9, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = false, perishable_compat = true,
    sprite = "bloodpact.png", negative_sprite = "bloodpact_negative.png",
    loc_vars = function(self, info_queue, card) return { vars = { card.ability.extra.xmult } } end,
    calculate = function(self, card, context)
        refresh_g()
        if context.joker_main and context.full_hand then
            local non_hearts = 0
            for _, v in ipairs(context.full_hand) do
                if not v:is_suit("Hearts") then non_hearts = non_hearts + 1 end
            end
            if non_hearts > 0 then
                if not context.blueprint then
                    SMODS.destroy_joker(card)
                    return { message = "Extinct!" }
                end
            else
                return { xmult = card.ability.extra.xmult }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Book Move: after 3 rounds, sell to create Hanging Chad + Photograph.
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "bookmove",
    loc_txt = { name = "Book Move", text = { "After {C:attention}#2#{} rounds,", "sell this card to create", "{C:attention}Hanging Chad{} and {C:attention}Photograph{}", "{C:inactive}(Currently {C:attention}#1#{C:inactive}/#2#, must have room)" } },
    config = { extra = { c_rounds = 0, rounds = 3 } },
    rarity = 3, cost = 10, unlocked = true, discovered = true,
    blueprint_compat = false, eternal_compat = false, perishable_compat = true,
    sprite = "bookmove.png", negative_sprite = "bookmove_negative.png",
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        return { vars = { e.c_rounds, e.rounds } }
    end,
    calculate = function(self, card, context)
        refresh_g()
        local e = card.ability.extra
        if context.end_of_round and not context.blueprint then
            e.c_rounds = e.c_rounds + 1
            return { message = (e.c_rounds < e.rounds) and (e.c_rounds .. "/" .. e.rounds) or "Active!" }
        end
        if context.selling_self and e.c_rounds >= e.rounds and not context.blueprint then
            SMODS.add_card { set = "Joker", key = "j_hanging_chad" }
            SMODS.add_card { set = "Joker", key = "j_photograph" }
        end
    end,
}

--------------------------------------------------------------------------------
-- Brainrot: on Blind select, destroy leftmost Joker, gain 5x its sell
-- value as permanent Chips (PC checks eternal; destroy_joker forces past).
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "brainrot",
    loc_txt = { name = "Brainrot", text = { "When {C:attention}Blind{} is selected,", "destroy the leftmost Joker", "and permanently add {C:attention}#2#x", "its sell value to these {C:blue}Chips", "{C:inactive}(Currently {C:chips}+#1#{C:inactive} Chips)" } },
    config = { extra = { chips = 0, scale_factor = 5 } },
    rarity = "oldfluff", cost = 6, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = false,
    sprite = "brainrot.png", negative_sprite = "brainrot_negative.png",
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        return { vars = { e.chips, e.scale_factor } }
    end,
    calculate = function(self, card, context)
        refresh_g()
        local e = card.ability.extra
        if context.setting_blind and not context.blueprint then
            local list = mf_held_jokers()
            local target = list[1]
            if target then
                e.chips = e.chips + (tonumber(target.sell_cost) or 0) * e.scale_factor
                SMODS.destroy_joker(target)
                return { message = "+" .. e.chips .. " Chips" }
            end
        end
        if context.joker_main and e.chips ~= 0 then return { chips = e.chips } end
    end,
}

--------------------------------------------------------------------------------
-- Brilliant: beaten in one hand -> random Spectral.
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "brilliant",
    loc_txt = { name = "Brilliant", text = { "If blind was beaten in", "one hand, create a", "random {C:spectral}Spectral{} card", "{C:inactive}(Must have room)" } },
    config = { extra = {} },
    rarity = 2, cost = 8, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "brilliant.png", negative_sprite = "brilliant_negative.png",
    calculate = function(self, card, context)
        refresh_g()
        if context.end_of_round then
            if mf_hands_played() <= 1 then
                if mf_create_random_consumable("spectral", "brilliant") then
                    return { message = "+Spectral" }
                end
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- The Broom Closet: X4 while no purchase since last round end.
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "broomcloset",
    loc_txt = { name = "The Broom Closet", text = { "{X:mult,C:white}X#1#{} Mult if no purchases", "were made in the last {C:attention}Shop{}", "{C:inactive}(Currently #2#)" } },
    config = { extra = { xmult = 4, active = true } },
    rarity = 2, cost = 4, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "broomcloset.png", negative_sprite = "broomcloset_negative.png",
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        return { vars = { e.xmult, e.active and "active!" or "inactive" } }
    end,
    calculate = function(self, card, context)
        refresh_g()
        local e = card.ability.extra
        if ((context.buying_card and context.card ~= card) or context.open_booster) and e.active then
            e.active = false
            return { message = "Disabled!" }
        end
        if context.end_of_round and not context.blueprint then
            e.active = true
            return { message = "Reset!" }
        end
        if context.joker_main and e.active then return { xmult = e.xmult } end
    end,
}

--------------------------------------------------------------------------------
-- Card Buffer Advanced: retrigger first editioned Joker.
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "cba",
    loc_txt = { name = "Card Buffer Advanced", text = { "{C:attention}Retrigger{} your first", "{C:dark_edition}Editioned{} Joker", "{C:inactive}(CBA excluded){}" } },
    config = { extra = {} },
    rarity = 3, cost = 10, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = false,
    sprite = "cba.png", negative_sprite = "cba_negative.png",
    calculate = function(self, card, context)
        refresh_g()
        if context.retrigger_joker_check and not context.retrigger_joker and context.other_card ~= card then
            local first = nil
            for _, j in ipairs(mf_held_jokers()) do
                if j ~= card and j.edition and j.edition ~= "base" then first = j break end
            end
            if first and first == context.other_card then
                return { message = "Again!", repetitions = 1 }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Coupon Catalogue: +15 Mult per voucher purchased this run.
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "coupon_catalogue",
    loc_txt = { name = "Coupon Catalogue", text = { "{C:mult}+#1#{} Mult for each", "{C:attention}Voucher{} purchased", "this run", "{C:inactive}(Currently {C:mult}+#2#{C:inactive} Mult)" } },
    config = { extra = { mult = 15 } },
    rarity = "oldfluff", cost = 7, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "coupon_catalogue.png", negative_sprite = "coupon_catalogue_negative.png",
    loc_vars = function(self, info_queue, card)
        refresh_g()
        local n = G and tonumber(#(G.vouchers or {})) or 0
        return { vars = { card.ability.extra.mult, n * card.ability.extra.mult } }
    end,
    calculate = function(self, card, context)
        refresh_g()
        if context.joker_main then
            local n = G and tonumber(#(G.vouchers or {})) or 0
            if n > 0 then return { mult = card.ability.extra.mult * n } end
        end
    end,
}

--------------------------------------------------------------------------------
-- Dinner: retrigger Joker to the right, for 5 rounds.
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "dinner",
    loc_txt = { name = "DINNER!", text = { "Retrigger the {C:attention}Joker", "to the right for", "the next {C:attention}#1#{} rounds" } },
    config = { extra = { rounds_left = 5 } },
    rarity = 2, cost = 5, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = false, perishable_compat = false,
    sprite = "dinner.png", negative_sprite = "dinner_negative.png",
    loc_vars = function(self, info_queue, card) return { vars = { card.ability.extra.rounds_left } } end,
    calculate = function(self, card, context)
        refresh_g()
        local e = card.ability.extra
        if context.retrigger_joker_check and not context.retrigger_joker and context.other_card ~= card then
            local idx, list = mf_joker_index(card)
            if idx and list[idx + 1] == context.other_card then
                return { message = "Again!", repetitions = 1 }
            end
        end
        if context.end_of_round and not context.blueprint then
            e.rounds_left = e.rounds_left - 1
            if e.rounds_left <= 0 then
                SMODS.destroy_joker(card)
                return { message = "Eaten!" }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Dramatic Entrance: +150 Chips on first hand of each round.
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "dramaticentrance",
    loc_txt = { name = "Dramatic Entrance", text = { "{C:chips}+#1#{} Chips", "for the first hand", "of each round" } },
    config = { extra = { chips = 150 } },
    rarity = 2, cost = 6, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "dramaticentrance.png", negative_sprite = "dramaticentrance_negative.png",
    loc_vars = function(self, info_queue, card) return { vars = { card.ability.extra.chips } } end,
    calculate = function(self, card, context)
        refresh_g()
        -- PC reads current_round.hands_played == 0 here: its counter
        -- increments after scoring. The fork increments its counter
        -- when the hand is played, before the scoring sequence ticks,
        -- so the first hand of a round reads 1.
        if context.joker_main and mf_hands_played() == 1 then
            return { chips = card.ability.extra.chips }
        end
    end,
}

--------------------------------------------------------------------------------
-- Expansion Pack: create a modded Joker on Blind selected (ported set).
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "expansion_pack",
    loc_txt = { name = "Expansion Pack", text = { "When {C:attention}Blind{} is selected,", "create {C:attention}#1# {C:dark_edition}modded{C:attention} Joker", "{C:inactive}(Must have room)" } },
    config = { extra = { count = 1 } },
    rarity = 1, cost = 6, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "expansion_pack.png", negative_sprite = "expansion_pack_negative.png",
    loc_vars = function(self, info_queue, card) return { vars = { card.ability.extra.count } } end,
    calculate = function(self, card, context)
        refresh_g()
        if context.setting_blind then
            -- PC filters the random pool to modded Jokers; here the
            -- modded pool is this pack's own registered defs.
            local pool = {}
            for id in pairs(JOKER_DEFS or {}) do
                if type(id) == "string" and id:sub(1, 6) == "j_mfp_" then pool[#pool + 1] = id end
            end
            if #pool > 0 then
                local pick = pseudorandom_element(pool, "expansion_pack")
                if SMODS.add_card { set = "Joker", key = pick } then
                    return { message = "+Joker" }
                end
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Fish: +4 Chips, +4 Mult (token).
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "fish",
    loc_txt = { name = "Fish", text = { "{C:chips}+#1#{} Chips", "{C:mult}+#2#{} Mult" } },
    config = { extra = { chips = 4, mult = 4 } },
    rarity = "token", cost = 1, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "fish.png", negative_sprite = "fish_negative.png",
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        return { vars = { e.chips, e.mult } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            local e = card.ability.extra
            return { chips = e.chips, mult = e.mult }
        end
    end,
}

--------------------------------------------------------------------------------
-- Joker Forge: every 2 Jokers sold, create a random Joker (Forge
-- Residue instead when another Forge is held).
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "forge",
    loc_txt = { name = "Joker Forge", text = { "Creates a random {C:attention}Joker{}", "card once for every", "{C:attention}#3# Jokers{} sold", "{C:inactive}(Currently {C:attention}#1#{C:inactive}/#2#)" } },
    config = { extra = { partial_rounds = 0, upgrade_rounds = 2 } },
    rarity = 2, cost = 6, unlocked = true, discovered = true,
    blueprint_compat = false, eternal_compat = true, perishable_compat = true,
    sprite = "forge.png", negative_sprite = "forge_negative.png",
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        return { vars = { e.partial_rounds, e.upgrade_rounds, e.upgrade_rounds } }
    end,
    calculate = function(self, card, context)
        refresh_g()
        local e = card.ability.extra
        if context.selling_card and not context.selling_self and context.card then
            local sold = context.card
            if sold.def and sold.def.id == "j_mfp_forgeslop" then return end
            e.partial_rounds = e.partial_rounds + 1
            local made = false
            while e.partial_rounds >= e.upgrade_rounds do
                e.partial_rounds = e.partial_rounds - e.upgrade_rounds
                local shenanigans = false
                for _, j in ipairs(mf_held_jokers()) do
                    if j ~= card and j.def and j.def.id == "j_mfp_forge" then shenanigans = true break end
                end
                if shenanigans then
                    SMODS.add_card { set = "Joker", key = "j_mfp_forgeslop" }
                else
                    mf_create_random_joker("forge")
                end
                made = true
            end
            if not made then return { message = e.partial_rounds .. "/" .. e.upgrade_rounds } end
        end
    end,
}

--------------------------------------------------------------------------------
-- Forge Residue: token, no effect.
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "forgeslop",
    loc_txt = { name = "Forge Residue", text = { "Does not trigger {C:attention}Joker{}", "{C:attention}Forge{} when sold" } },
    config = { extra = {} },
    rarity = "token", cost = 0, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "forgeslop.png", negative_sprite = "forgeslop_negative.png",
}

--------------------------------------------------------------------------------
-- Friend Inside Me: selling Common/Uncommon creates next-rarity Joker;
-- reactivates after Boss Blind (PC: once per ante).
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "friendinsideme",
    loc_txt = { name = "Friend Inside Me", text = { "Once per {C:attention}ante{}, selling a {C:common}Common{}", "or {C:uncommon}Uncommon{} joker creates", "a joker of the next rarity", "{C:inactive}(Currently #1#)" } },
    config = { extra = { active = true } },
    rarity = 2, cost = 7, unlocked = true, discovered = true,
    blueprint_compat = false, eternal_compat = true, perishable_compat = true,
    sprite = "friendinsideme.png", negative_sprite = "friendinsideme_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.active and "active" or "inactive" } }
    end,
    calculate = function(self, card, context)
        refresh_g()
        local e = card.ability.extra
        if context.selling_card and not context.selling_self and e.active and context.card then
            local r = context.card.def and tonumber(context.card.def.rarity)
            if r == 1 or r == 2 then
                e.active = false
                local g = refresh_g()
                local id = g and g.random_joker_def_id_by_rarity
                    and g:random_joker_def_id_by_rarity(r + 1, "friendinsideme") or nil
                if id then
                    local ed = context.card.edition
                    if type(ed) ~= "string" or ed == "base" then ed = nil end
                    SMODS.add_card { set = "Joker", key = id, edition = ed }
                    return { message = "Friend!" }
                end
            end
        end
        if context.end_of_round and not context.blueprint and mf_is_boss(context) then
            if not e.active then
                e.active = true
                return { message = "Active!" }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Globe: create a Planet on shop reroll.
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "globe",
    loc_txt = { name = "Globe", text = { "Create #1# {C:planet}Planet{} card", "when you {C:attention}reroll{} in the shop" } },
    config = { extra = { count = 1 } },
    rarity = 2, cost = 6, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "globe.png", negative_sprite = "globe_negative.png",
    loc_vars = function(self, info_queue, card) return { vars = { card.ability.extra.count } } end,
    calculate = function(self, card, context)
        refresh_g()
        if context.reroll_shop then
            if mf_create_random_consumable("planet", "globe") then
                return { message = "+Planet" }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Golden Carrot: $gain at end of round, -$1 per hand played.
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "goldencarrot",
    loc_txt = { name = "Golden Carrot", text = { "Earn {C:money}$#1#{} at", "end of round", "{C:money}-$#2#{} given", "per hand played" } },
    config = { extra = { gain = 10, loss = 1 } },
    rarity = 2, cost = 4, unlocked = true, discovered = true,
    blueprint_compat = false, eternal_compat = false, perishable_compat = true,
    sprite = "goldencarrot.png", negative_sprite = "goldencarrot_negative.png",
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        return { vars = { e.gain, e.loss } }
    end,
    calc_dollar_bonus = function(self, card)
        local bonus = math.max(0, card.ability.extra.gain)
        if bonus > 0 then return bonus end
    end,
    calculate = function(self, card, context)
        refresh_g()
        local e = card.ability.extra
        if context.after and not context.blueprint then
            e.gain = e.gain - e.loss
            if e.gain <= 0 then
                SMODS.destroy_joker(card)
                return { message = "Eaten!" }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Huge Joker: X3 Mult, -2 hand size.
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "hugejoker",
    loc_txt = { name = "Huge Joker", text = { "{X:red,C:white} X#1# {} Mult", "{C:attention}#2#{} hand size" } },
    config = { h_size = -2, extra = { x_mult = 3 } },
    rarity = 3, cost = 8, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "hugejoker.png", negative_sprite = "hugejoker_negative.png",
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        return { vars = { e.x_mult, card.ability.h_size } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then return { xmult = card.ability.extra.x_mult } end
    end,
}

--------------------------------------------------------------------------------
-- Hyper Beam: X3 Mult (PC also loses all discards on Blind select:
-- no discard-count manipulation in the fork).
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "hyperbeam",
    loc_txt = { name = "Hyper Beam", text = { "{X:red,C:white} X#1# {} Mult", "{C:attention}Lose all discards", "when {C:attention}Blind{} is selected" } },
    config = { extra = { xmult = 3 } },
    rarity = 2, cost = 8, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "hyperbeam.png", negative_sprite = "hyperbeam_negative.png",
    loc_vars = function(self, info_queue, card) return { vars = { card.ability.extra.xmult } } end,
    calculate = function(self, card, context)
        if context.joker_main then return { xmult = card.ability.extra.xmult } end
    end,
}

--------------------------------------------------------------------------------
-- Ice Cube: Xodds to all probabilities, decays X0.5 per round.
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "icecube",
    loc_txt = { name = "Ice Cube", text = { "{X:green,C:white}X#1#{} to all {C:attention}listed", "{C:green}probabilities", "{C:inactive}(ex: {C:green}1 in 3{C:inactive} -> {C:green}#1# in 3{C:inactive})", "Reduce this by {X:green,C:white}X#2#{}", "at end of round" } },
    config = { extra = { odds = 4, odds_mod = 0.5 } },
    rarity = 2, cost = 6, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = false, perishable_compat = true,
    sprite = "icecube.png", negative_sprite = "icecube_negative.png",
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        return { vars = { e.odds, e.odds_mod } }
    end,
    calculate = function(self, card, context)
        refresh_g()
        local e = card.ability.extra
        if context.mod_probability and not context.blueprint then
            return { numerator = (tonumber(context.numerator) or 1) * e.odds }
        end
        if context.end_of_round and not context.blueprint and not context.retrigger_joker then
            e.odds = mf_round2(e.odds - e.odds_mod)
            if e.odds <= 1.01 then
                SMODS.destroy_joker(card)
                return { message = "Eaten!" }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Impostor: X3 if played hand has exactly one red card.
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "impostor",
    loc_txt = { name = "Impostor", text = { "{X:mult,C:white} X#1# {} Mult if the", "played hand has", "exactly one {C:red}red{} card" } },
    config = { extra = { x_mult = 3, check = 0 } },
    rarity = "oldfluff", cost = 7, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "impostor.png", negative_sprite = "impostor_negative.png",
    loc_vars = function(self, info_queue, card) return { vars = { card.ability.extra.x_mult } } end,
    calculate = function(self, card, context)
        refresh_g()
        local e = card.ability.extra
        if context.before and not context.blueprint then
            local red = 0
            for _, v in ipairs(context.full_hand or {}) do
                if v:is_suit("Hearts") or v:is_suit("Diamonds") then red = red + 1 end
            end
            e.check = red
        end
        if context.joker_main and e.check == 1 then return { xmult = e.x_mult } end
    end,
}

--------------------------------------------------------------------------------
-- Jokes for Minecrafters (PC name: Jokes for Balatro Players):
-- first discarded card matching the current page is destroyed.
--------------------------------------------------------------------------------
local MF_JOKES = {
    none = {},
    hearts = { suit = "Hearts" }, diamonds = { suit = "Diamonds" },
    clubs = { suit = "Clubs" }, spades = { suit = "Spades" },
    face = { face = true },
    hack = { ranks = { [2] = true, [3] = true, [4] = true, [5] = true } },
    odd = { ranks = { [14] = true, [3] = true, [5] = true, [7] = true, [9] = true } },
    even = { ranks = { [2] = true, [4] = true, [6] = true, [8] = true, [10] = true } },
    fib = { ranks = { [14] = true, [2] = true, [3] = true, [5] = true, [8] = true } },
}
local MF_JOKE_KEYS = { "none", "hearts", "diamonds", "clubs", "spades", "face", "hack", "odd", "even", "fib" }

SMODS.Joker {
    key = "jokesforminecrafters",
    loc_txt = { name = "Jokes for Balatro Players", text = { "Did you hear about the playing cards?", "They were destroyed!", "{C:inactive}(Turns page at end of round...)" } },
    config = { extra = { current_joke = "none", has_triggered = false } },
    rarity = 1, cost = 7, unlocked = true, discovered = true,
    blueprint_compat = false, eternal_compat = true, perishable_compat = true,
    sprite = "jokesforminecrafters.png", negative_sprite = "jokesforminecrafters_negative.png",
    set_ability = function(self, card, initial)
        card.ability.extra.current_joke =
            pseudorandom_element(MF_JOKE_KEYS, "choose_joke")
    end,
    calculate = function(self, card, context)
        refresh_g()
        local e = card.ability.extra
        if context.end_of_round and not context.blueprint then
            e.current_joke = pseudorandom_element(MF_JOKE_KEYS, "choose_joke")
            e.has_triggered = false
            return { message = "Page turn" }
        end
        if context.pre_discard and not e.has_triggered then
            local joke = MF_JOKES[e.current_joke] or MF_JOKES.none
            local discarded = (context.port and context.port.discarded_nodes) or context.full_hand or {}
            for _, node in ipairs(discarded) do
                local view = node
                local valid = false
                if joke.suit then valid = view.is_suit and view:is_suit(joke.suit) end
                if joke.face then valid = view.is_face and view:is_face() end
                if joke.ranks then valid = joke.ranks[view.get_id and view:get_id() or 0] == true end
                if e.current_joke == "none" then valid = true end
                if valid then
                    e.has_triggered = true
                    SMODS.destroy_card(node)
                    break
                end
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Knuckleblaster: X3 Mult (PC also -1 play limit: unsupported).
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "knuckleblaster",
    loc_txt = { name = "Knuckleblaster", text = { "{X:mult,C:white}X#1#{} Mult", "You can {C:blue}play{} {C:attention}1{} fewer card" } },
    config = { extra = { xmult = 3, play_limit = 1 } },
    rarity = 2, cost = 6, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "knuckleblaster.png", negative_sprite = "knuckleblaster_negative.png",
    loc_vars = function(self, info_queue, card) return { vars = { card.ability.extra.xmult } } end,
    calculate = function(self, card, context)
        if context.joker_main then return { xmult = card.ability.extra.xmult } end
    end,
}

--------------------------------------------------------------------------------
-- Letter Jokers (mf_letter). Sprites are 71x78 cells stretched to 70x94.
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "lettergem_a",
    loc_txt = { name = "A", text = { "Played {C:attention}Aces{}", "give {C:mult}+#1#{} Mult", "and get {C:attention}retriggered" } },
    config = { extra = { mult = 2 } },
    rarity = "letter", cost = 2, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "lettergem_a.png", negative_sprite = "lettergem_a_negative.png",
    loc_vars = function(self, info_queue, card) return { vars = { card.ability.extra.mult } } end,
    calculate = function(self, card, context)
        refresh_g()
        if context.other_card and context.other_card:get_id() == 14 then
            if context.individual and context.cardarea == G.play then
                return { mult = card.ability.extra.mult }
            end
            if context.repetition and context.cardarea == G.play then
                return { repetitions = 1 }
            end
        end
    end,
}

SMODS.Joker {
    key = "lettergem_c",
    loc_txt = { name = "C", text = { "{X:mult,C:white}X#1#{} Mult for every", "{C:chips}100{} chips worth", "of cards scored", "{C:inactive}(Currently #2#/100)" } },
    config = { extra = { xmult = 5, counter = 0 } },
    rarity = "letter", cost = 6, unlocked = true, discovered = true,
    blueprint_compat = false, eternal_compat = true, perishable_compat = true,
    sprite = "lettergem_c.png", negative_sprite = "lettergem_c_negative.png",
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        return { vars = { e.xmult, e.counter } }
    end,
    calculate = function(self, card, context)
        refresh_g()
        local e = card.ability.extra
        if context.individual and context.cardarea == G.play and not context.blueprint and context.other_card then
            e.counter = e.counter + mf_chip_value(context.other_card)
            local times = 0
            while e.counter >= 100 do e.counter = e.counter - 100 times = times + 1 end
            if times > 0 then
                local x = 1
                for _ = 1, times do x = x * e.xmult end
                return { xmult = x }
            end
        end
    end,
}

SMODS.Joker {
    key = "lettergem_f",
    loc_txt = { name = "F", text = { "Creates a {C:attention}Letter {C:attention}Joker{}", "when blind is selected", "{C:inactive}(must have room)" } },
    config = { extra = {} },
    rarity = "letter", cost = 8, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "lettergem_f.png", negative_sprite = "lettergem_f_negative.png",
    calculate = function(self, card, context)
        refresh_g()
        if context.setting_blind then
            local pool = {}
            for id, def in pairs(JOKER_DEFS or {}) do
                local entry = SMODS.Rarities and SMODS.Rarities["mfp_letter"]
                if entry and def and tonumber(def.rarity) == entry.index then pool[#pool + 1] = id end
            end
            if #pool > 0 then
                local pick = pseudorandom_element(pool, "lettergem_f")
                if SMODS.add_card { set = "Joker", key = pick } then
                    return { message = "+Joker" }
                end
            end
        end
    end,
}

SMODS.Joker {
    key = "lettergem_g",
    loc_txt = { name = "G", text = { "Played cards each give", "{X:mult,C:white} X#1# {} Mult when scored" } },
    config = { extra = { xmult = 1.01 } },
    rarity = "letter", cost = 4, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "lettergem_g.png", negative_sprite = "lettergem_g_negative.png",
    loc_vars = function(self, info_queue, card) return { vars = { card.ability.extra.xmult } } end,
    calculate = function(self, card, context)
        refresh_g()
        if context.individual and context.cardarea == G.play then
            return { message = "G", xmult = card.ability.extra.xmult }
        end
        if context.setting_blind then return { message = "G" } end
    end,
}

SMODS.Joker {
    key = "lettergem_h",
    loc_txt = { name = "H", text = { "{C:attention}Retrigger{} all scoring", "cards except {C:attention}the first" } },
    config = { extra = {} },
    rarity = "letter", cost = 8, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "lettergem_h.png", negative_sprite = "lettergem_h_negative.png",
    calculate = function(self, card, context)
        refresh_g()
        if context.repetition and context.cardarea == G.play and context.other_card then
            -- PC compares against scoring_hand[1]; the fork's
            -- retrigger context carries played cards on context.port.
            local played = context.port and (context.port.played_cards or context.port.cards)
            local first = played and played[1]
            if first and context.other_card ~= first then return { repetitions = 1 } end
            if not first then return { repetitions = 1 } end
        end
    end,
}

SMODS.Joker {
    key = "lettergem_i",
    loc_txt = { name = "I", text = { "{C:attention}Straights{} can be formed", "with {C:attention}two{} fewer cards", "{X:mult,C:white}X#1#{} Mult if played hand", "contains a {C:attention}five card straight" } },
    config = { extra = { straight_mult = 2 } },
    rarity = "letter", cost = 2, unlocked = true, discovered = true,
    blueprint_compat = false, eternal_compat = true, perishable_compat = true,
    sprite = "lettergem_i.png", negative_sprite = "lettergem_i_negative.png",
    loc_vars = function(self, info_queue, card) return { vars = { card.ability.extra.straight_mult } } end,
    calculate = function(self, card, context)
        refresh_g()
        if context.joker_main and context.poker_hands then
            -- PC checks a >=5-card Straight in poker_hands; the fork
            -- marks contained hand types with a non-empty list.
            if next(context.poker_hands["Straight"]) and context.scoring_hand
                and #context.scoring_hand >= 5 then
                return { xmult = card.ability.extra.straight_mult }
            end
        end
    end,
}

SMODS.Joker {
    key = "lettergem_j",
    loc_txt = { name = "J", text = { "Retriggers the {C:attention}two{}", "{C:attention}Jokers{} to the right", "Lose {C:money}$#1#{} when", "they trigger" } },
    config = { extra = { money_per = 0.5 } },
    rarity = "letter", cost = 16, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "lettergem_j.png", negative_sprite = "lettergem_j_negative.png",
    loc_vars = function(self, info_queue, card) return { vars = { card.ability.extra.money_per } } end,
    calculate = function(self, card, context)
        refresh_g()
        local idx, list = mf_joker_index(card)
        local near = idx and (list[idx + 1] == context.other_card or list[idx + 2] == context.other_card)
        if not near then return end
        if context.retrigger_joker_check then return { repetitions = 1 } end
        if context.post_trigger then return { dollars = -card.ability.extra.money_per } end
    end,
}

SMODS.Joker {
    key = "lettergem_k",
    loc_txt = { name = "K", text = { "Creates a {C:dark_edition}Negative {C:attention}Cavendish", "when {C:attention}Blind{} is selected, it has a", "{X:green,C:white}X#1#{} chance to be destroyed" } },
    config = { extra = { odds = 500 } },
    rarity = "letter", cost = 10, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "lettergem_k.png", negative_sprite = "lettergem_k_negative.png",
    loc_vars = function(self, info_queue, card) return { vars = { card.ability.extra.odds } } end,
    calculate = function(self, card, context)
        refresh_g()
        if context.setting_blind then
            local made = SMODS.add_card { set = "Joker", key = "j_cavendish", edition = "negative" }
            if made then
                if made.ability and made.ability.extra and tonumber(made.ability.extra.odds) then
                    made.ability.extra.odds = math.floor(made.ability.extra.odds / card.ability.extra.odds)
                end
                return { message = "+Joker" }
            end
        end
    end,
}

SMODS.Joker {
    key = "lettergem_m",
    loc_txt = { name = "M", text = { "Creates a {C:blue}Jolly Joker", "with {C:money}+$#1#{} sell value", "when blind is selected", "{C:inactive}(must have room)" } },
    config = { extra = { price = 3 } },
    rarity = "letter", cost = 6, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "lettergem_m.png", negative_sprite = "lettergem_m_negative.png",
    loc_vars = function(self, info_queue, card) return { vars = { card.ability.extra.price } } end,
    calculate = function(self, card, context)
        refresh_g()
        if context.setting_blind then
            local made = SMODS.add_card { set = "Joker", key = "j_jolly" }
            if made then
                -- PC adds extra_value and re-prices; the fork prices a
                -- Joker from its def, so the +$3 sell value is added
                -- to the created Joker's sell_cost directly.
                made.sell_cost = (tonumber(made.sell_cost) or 0) + card.ability.extra.price
                return { message = "+Joker" }
            end
        end
    end,
}

SMODS.Joker {
    key = "lettergem_n",
    loc_txt = { name = "N", text = { "Creates a {C:dark_edition}Negative {C:attention}Joker{}", "when {C:attention}Boss Blind{} is selected" } },
    config = { extra = {} },
    rarity = "letter", cost = 2, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "lettergem_n.png", negative_sprite = "lettergem_n_negative.png",
    calculate = function(self, card, context)
        refresh_g()
        if context.setting_blind and mf_is_boss(context) then
            if SMODS.add_card { set = "Joker", key = "j_joker", edition = "negative" } then
                return { message = "+Joker" }
            end
        end
    end,
}

SMODS.Joker {
    key = "lettergem_o",
    loc_txt = { name = "O", text = { "All probabilities are {C:green}1 in 2" } },
    config = { extra = {} },
    rarity = "letter", cost = 2, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "lettergem_o.png", negative_sprite = "lettergem_o_negative.png",
    calculate = function(self, card, context)
        if context.fix_probability then return { numerator = 1, denominator = 2 } end
    end,
}

SMODS.Joker {
    key = "lettergem_s",
    loc_txt = { name = "S", text = { "Scored and held {C:attention}6s{} and {C:attention}7s", "give {C:chips}+#1#{} Chips and {C:mult}+#2#{} Mult" } },
    config = { extra = { chips = 6, mult = 7 } },
    rarity = "letter", cost = 2, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "lettergem_s.png", negative_sprite = "lettergem_s_negative.png",
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        return { vars = { e.chips, e.mult } }
    end,
    calculate = function(self, card, context)
        refresh_g()
        if context.individual and not context.end_of_round and context.other_card then
            local id = context.other_card:get_id()
            if id == 6 or id == 7 then
                local e = card.ability.extra
                return { chips = e.chips, mult = e.mult }
            end
        end
    end,
}

SMODS.Joker {
    key = "lettergem_v",
    loc_txt = { name = "V", text = { "Creates a {C:attention}Voucher Tag", "whenever a card is bought" } },
    config = { extra = {} },
    rarity = "letter", cost = 8, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "lettergem_v.png", negative_sprite = "lettergem_v_negative.png",
    calculate = function(self, card, context)
        refresh_g()
        if context.buying_card then
            if G and G.addTag then G:addTag("voucher") end
            return { message = "+Tag" }
        end
    end,
}

SMODS.Joker {
    key = "lettergem_w",
    loc_txt = { name = "W", text = { "Creates a {C:attention}Wheel of Fortune", "when {C:attention}Blind{} is selected, it has", "a {X:green,C:white}X#1#{} chance to trigger", "{C:inactive}(must have room)" } },
    config = { extra = { odds = 0.8 } },
    rarity = "letter", cost = 8, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "lettergem_w.png", negative_sprite = "lettergem_w_negative.png",
    loc_vars = function(self, info_queue, card) return { vars = { card.ability.extra.odds } } end,
    calculate = function(self, card, context)
        refresh_g()
        if context.setting_blind then
            local made = SMODS.add_card { set = "Tarot", key = "tarot_wheel_of_fortune" }
            if made then
                -- PC divides the Wheel's failure odds by 0.8 on the
                -- created card; the fork's consumable ability has no
                -- per-copy odds field, so the boost is dropped.
                return { message = "+Tarot" }
            end
        end
    end,
}

SMODS.Joker {
    key = "lettergem_y",
    loc_txt = { name = "Y", text = { "Earn {C:gold}$#1#{} for every", "{C:attention}#2#{} cards scored", "{C:inactive}(Currently #3#/#2#)" } },
    config = { extra = { dollars = 10, card_total = 13, cards_scored = 0 } },
    rarity = "letter", cost = 8, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "lettergem_y.png", negative_sprite = "lettergem_y_negative.png",
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        return { vars = { e.dollars, e.card_total, e.cards_scored } }
    end,
    calculate = function(self, card, context)
        refresh_g()
        local e = card.ability.extra
        if context.individual and context.cardarea == G.play and not context.blueprint then
            e.cards_scored = e.cards_scored + 1
            local times = 0
            while e.cards_scored >= e.card_total do
                e.cards_scored = e.cards_scored - e.card_total
                times = times + 1
            end
            if times > 0 then return { dollars = e.dollars * times } end
        end
    end,
}

--------------------------------------------------------------------------------
-- Lucky Charm: 1 in 3 for +20 Mult; 1 in 8 to win $20 at round end.
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "luckycharm",
    loc_txt = { name = "Lucky Charm", text = { "{C:green}#1# in #2#{} chance", "for {C:mult}+#3#{} Mult", "{C:green}#4# in #5#{} chance", "to win {C:money}$#6#", "at end of round" } },
    config = { extra = { mult_chance = 3, mult = 20, money_chance = 8, money = 20 } },
    rarity = 1, cost = 6, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "luckycharm.png", negative_sprite = "luckycharm_negative.png",
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        local n1, d1 = SMODS.get_probability_vars(card, 1, e.mult_chance, "luckycharm_mult")
        local n2, d2 = SMODS.get_probability_vars(card, 1, e.money_chance, "luckycharm_money")
        return { vars = { n1, d1, e.mult, n2, d2, e.money } }
    end,
    calculate = function(self, card, context)
        refresh_g()
        local e = card.ability.extra
        if context.end_of_round and not context.blueprint then
            local hit = SMODS.pseudorandom_probability(card, "lucky_charm_money", 1, e.money_chance, "lucky_charm_money")
            if hit then return { dollars = e.money } end
        end
        if context.joker_main then
            local hit = SMODS.pseudorandom_probability(card, "lucky_charm_mult", 1, e.mult_chance, "lucky_charm_mult")
            if hit then return { mult = e.mult } end
        end
    end,
}

--------------------------------------------------------------------------------
-- Lollipop: X1.75, -X0.15 per round, eaten at X1.
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "lollipop",
    loc_txt = { name = "Lollipop", text = { "{X:mult,C:white} X#1# {} Mult", "{X:mult,C:white} -X#2# {} Mult per", "round played" } },
    config = { extra = { xmult = 1.75, xmult_per = 0.15 } },
    rarity = 1, cost = 6, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = false, perishable_compat = true,
    sprite = "lollipop.png", negative_sprite = "lollipop_negative.png",
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        return { vars = { e.xmult, e.xmult_per } }
    end,
    calculate = function(self, card, context)
        refresh_g()
        local e = card.ability.extra
        if context.end_of_round and not context.blueprint and not context.retrigger_joker then
            e.xmult = mf_round2(e.xmult - e.xmult_per)
            if e.xmult <= 1.01 then
                SMODS.destroy_joker(card)
                return { message = "Eaten!" }
            end
        elseif context.joker_main then
            return { xmult = e.xmult }
        end
    end,
}

--------------------------------------------------------------------------------
-- Mashup Album: Flush scaling (+4 Mult red first card, +15 Chips black).
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "mashupalbum",
    loc_txt = { name = "Mashup Album", text = { "Gains {C:mult}+#3#{} Mult if played", "hand contains a {C:hearts}red{} flush", "Gains {C:chips}+#4#{} Chips if played", "hand contains a {C:spades}black{} flush", "{C:inactive}(Currently {C:mult}+#1#{C:inactive} and {C:chips}+#2#{C:inactive})" } },
    config = { extra = { mult = 4, chips = 15, mult_gain = 4, chips_gain = 15 } },
    rarity = "oldfluff", cost = 8, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = false,
    sprite = "mashupalbum.png", negative_sprite = "mashupalbum_negative.png",
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        return { vars = { e.mult, e.chips, e.mult_gain, e.chips_gain } }
    end,
    calculate = function(self, card, context)
        refresh_g()
        local e = card.ability.extra
        if context.before and context.poker_hands and next(context.poker_hands["Flush"]) then
            local first = context.scoring_hand and context.scoring_hand[1] or (context.full_hand or {})[1]
            if first then
                if first:is_suit("Hearts") or first:is_suit("Diamonds") then
                    e.mult = e.mult + e.mult_gain
                else
                    e.chips = e.chips + e.chips_gain
                end
            end
        end
        if context.joker_main then return { mult = e.mult, chips = e.chips } end
    end,
}

--------------------------------------------------------------------------------
-- Miner: D6 Tag on Boss Blind selected.
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "miner",
    loc_txt = { name = "Miner", text = { "Create a {C:attention}D6 Tag", "when {C:attention}Boss Blind{} is selected" } },
    config = { extra = {} },
    rarity = "oldfluff", cost = 5, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "miner.png", negative_sprite = "miner_negative.png",
    calculate = function(self, card, context)
        refresh_g()
        if context.setting_blind and mf_is_boss(context) then
            if G and G.addTag then
                G:addTag("d6")
                return { message = "+Tag" }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Money Printer: $2 per played numbered card matching a money digit.
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "moneyprinter",
    loc_txt = { name = "Money Printer", text = { "Earn {C:money}$2{} for each", "played numbered card", "that is a digit of", "your current money", "{C:inactive}(Ace = 1, 10 = 0)" } },
    config = { extra = { dollars_per = 2 } },
    rarity = "oldfluff", cost = 5, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "moneyprinter.png", negative_sprite = "moneyprinter_negative.png",
    loc_vars = function(self, info_queue, card) return { vars = { card.ability.extra.dollars_per } } end,
    calculate = function(self, card, context)
        refresh_g()
        local e = card.ability.extra
        if context.after and not context.blueprint and context.full_hand then
            local digits = tostring(math.floor(math.abs(tonumber(G and G.money) or 0)))
            local total = 0
            for _, v in ipairs(context.full_hand) do
                if not v:is_face() then
                    -- PC reads base.nominal % 10 (Ace nominal is 11,
                    -- so an Ace counts as the digit 1; 10 counts as 0).
                    local nominal = (v.base and tonumber(v.base.nominal)) or mf_chip_value(v)
                    local digit = nominal % 10
                    if digits:find(tostring(digit), 1, true) then total = total + e.dollars_per end
                end
            end
            if total > 0 then return { dollars = total } end
        end
    end,
}

--------------------------------------------------------------------------------
-- Oops! All 5s: reduce all probability denominators by 1.
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "oopsallfives",
    loc_txt = { name = "Oops! All 5s", text = { "Reduces all {C:attention}listed", "{C:green}denominators{} by {C:green}1", "{C:inactive}(ex: {C:green}1 in 5{C:inactive} -> {C:green}1 in 4{C:inactive})" } },
    config = { extra = { amount = 1 } },
    rarity = "token", cost = 1, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "oopsallfives.png", negative_sprite = "oopsallfives_negative.png",
    loc_vars = function(self, info_queue, card) return { vars = { card.ability.extra.amount } } end,
    calculate = function(self, card, context)
        if context.mod_probability and not context.blueprint then
            local den = tonumber(context.denominator) or 1
            local new_den = den
            if den >= 1 and den < 2 then new_den = 1
            elseif den >= 2 then new_den = den - 1 end
            return { denominator = new_den }
        end
    end,
}

--------------------------------------------------------------------------------
-- Particle Accelerator: +X1 per 1-card hand, else gives banked XMult
-- and resets (PC's x_mult/xmult key mismatch normalised to one field).
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "particleaccelerator",
    loc_txt = { name = "Particle Accelerator", text = { "Gains {X:mult,C:white} X#2# {} Mult if played", "hand has only {C:attention}1{} card,", "otherwise gives {X:mult,C:white} X#1# {} Mult", "and resets to {X:mult,C:white} X1 {} Mult" } },
    config = { extra = { xmult = 1, xmult_scale = 1 } },
    rarity = "oldfluff", cost = 7, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "particleaccelerator.png", negative_sprite = "particleaccelerator_negative.png",
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        return { vars = { e.xmult, e.xmult_scale } }
    end,
    calculate = function(self, card, context)
        refresh_g()
        local e = card.ability.extra
        if context.after and context.full_hand then
            if #context.full_hand == 1 then
                e.xmult = e.xmult + e.xmult_scale
            else
                e.xmult = 1
                return { message = "Reset!" }
            end
        end
        if context.joker_main and context.full_hand and #context.full_hand ~= 1 then
            if e.xmult ~= 1 then return { xmult = e.xmult } end
        end
    end,
}

--------------------------------------------------------------------------------
-- Passing Balatro in 5 Minutes: Negative Diet Cola per 2 Blinds skipped.
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "passando",
    loc_txt = { name = "Passing Balatro in 5 Minutes", text = { "{X:attention,C:white}X2{} Speed", "Creates a {C:dark_edition}Negative{} {C:attention}Diet Cola", "for every {C:attention}2{} Blinds skipped", "{C:inactive}(Currently #1#/#2#)" } },
    config = { extra = { blinds_skipped = 0, threshold = 2 } },
    rarity = 2, cost = 6, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = false,
    sprite = "passando.png", negative_sprite = "passando_negative.png",
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        return { vars = { e.blinds_skipped, e.threshold } }
    end,
    calculate = function(self, card, context)
        refresh_g()
        local e = card.ability.extra
        if context.skip_blind and not context.blueprint then
            e.blinds_skipped = e.blinds_skipped + 1
            local create = 0
            while e.blinds_skipped >= e.threshold do
                create = create + 1
                e.blinds_skipped = e.blinds_skipped - e.threshold
            end
            if create > 0 then
                for _ = 1, create do
                    SMODS.add_card { set = "Joker", key = "j_diet_cola", edition = "negative" }
                end
            else
                return { message = e.blinds_skipped .. "/" .. e.threshold }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Philosophical Joker: +1 Joker slot (fork config modifier).
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "philosophical",
    loc_txt = { name = "Philosophical Joker", text = { "{C:dark_edition}+#1#{} Joker Slot" } },
    config = { joker_slots = 1, extra = { slots = 1 } },
    rarity = 1, cost = 1, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = false,
    sprite = "philosophical.png", negative_sprite = "philosophical_negative.png",
    loc_vars = function(self, info_queue, card) return { vars = { card.ability.extra.slots } } end,
}

--------------------------------------------------------------------------------
-- Recycling: random Tarot or Planet when a Booster Pack is skipped.
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "recycling",
    loc_txt = { name = "Recycling", text = { "Create a random {C:planet}Planet{}", "or {C:tarot}Tarot{} card", "when any {C:attention}Booster{}", "{C:attention}Pack{} is skipped", "{C:inactive}(Must have room)" } },
    config = { extra = {} },
    rarity = 2, cost = 5, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "recycling.png", negative_sprite = "recycling_negative.png",
    calculate = function(self, card, context)
        refresh_g()
        if context.skipping_booster then
            local kind = pseudorandom_element({ "tarot", "planet" }, "recycling_type")
            if mf_create_random_consumable(kind, "recycling") then
                return { message = kind == "tarot" and "+Tarot" or "+Planet" }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Retrigger Joker: retrigger the fifth scoring card (PC's
-- retrigger-attribute Joker clause needs the attributes system).
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "retrigger_joker",
    loc_txt = { name = "Retrigger Joker", text = { "{C:attention}Retrigger{} each other", "{C:attention}Joker{} that {C:attention}retriggers", "{C:attention}Retrigger{} the {C:attention}fifth", "scoring card" } },
    config = { extra = {} },
    rarity = 2, cost = 8, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = false,
    sprite = "retrigger_joker.png", negative_sprite = "retrigger_joker_negative.png",
    calculate = function(self, card, context)
        refresh_g()
        if context.repetition and context.cardarea == G.play and context.other_card then
            local played = context.port and (context.port.played_cards or context.port.cards)
            local fifth = played and played[5]
            if fifth and context.other_card == fifth then return { repetitions = 1 } end
        end
    end,
}

--------------------------------------------------------------------------------
-- Riding the Dilu Horse: retrigger card at this Joker's position;
-- Boss defeat gives right neighbour horsemanship (stacks counted here).
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "riding_the_dilu_horse",
    loc_txt = { name = "Riding the Dilu Horse", text = { "{C:green}Horsemanship", "{C:inactive}(Retrigger the playing card", "{C:inactive}with the same position", "{C:inactive}as this Joker once)", "When a {C:attention}Boss Blind{} is defeated,", "the {C:attention}Joker{} to the right", "gains {C:green}horsemanship", "{C:inactive}(Forever. Multiple instances", "{C:inactive}trigger separately)" } },
    config = { extra = {} },
    rarity = 3, cost = 7, unlocked = true, discovered = true,
    blueprint_compat = false, eternal_compat = false, perishable_compat = true,
    sprite = "riding_the_dilu_horse.png", negative_sprite = "riding_the_dilu_horse_negative.png",
    calculate = function(self, card, context)
        refresh_g()
        if context.end_of_round and not context.blueprint and mf_is_boss(context) then
            local idx, list = mf_joker_index(card)
            local right = idx and list[idx + 1]
            if right then
                right.ability = right.ability or {}
                right.ability.mf_dilu_horse = (tonumber(right.ability.mf_dilu_horse) or 0) + 1
                return { message = "Horsed!" }
            end
        end
        if context.repetition and context.cardarea == G.play and context.other_card then
            local my_ind = mf_joker_index(card)
            local played = context.port and (context.port.played_cards or context.port.cards)
            if my_ind and played then
                local their_ind = nil
                for i, node in ipairs(played) do
                    if node == context.other_card then their_ind = i break end
                end
                if their_ind == my_ind then
                    -- Own horsemanship plus any stacks banked on the
                    -- Joker sitting at the card's position.
                    local _, list = mf_joker_index(card)
                    local holder = list and list[their_ind]
                    local stacks = holder and holder.ability
                        and tonumber(holder.ability.mf_dilu_horse) or 0
                    return { repetitions = 1 + stacks }
                end
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Big Win (Slot Machine): 1 in 7 to retrigger scored 7s seven times.
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "slotmachine",
    loc_txt = { name = "Big Win", text = { "{C:green}#1# in #2#{} chance to retrigger scored {C:attention}7{} cards {C:attention}#3#{} times" } },
    config = { extra = { retriggers = 7, odds = 7 } },
    rarity = 2, cost = 7, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "slotmachine.png", negative_sprite = "slotmachine_negative.png",
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        local n, d = SMODS.get_probability_vars(card, 1, e.odds, "slotmachine")
        return { vars = { n, d, e.retriggers } }
    end,
    calculate = function(self, card, context)
        refresh_g()
        local e = card.ability.extra
        if context.repetition and context.other_card and context.other_card:get_id() == 7 then
            local hit = SMODS.pseudorandom_probability(card, "slotmachine", 1, e.odds, "slotmachine")
            if hit then return { message = "Again!!", repetitions = e.retriggers } end
        end
    end,
}

--------------------------------------------------------------------------------
-- Spiral Joker: Mult follows 10 + 7cos(pi/8 x money).
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "spiral",
    loc_txt = { name = "Spiral Joker", text = { "{C:mult}+(#1#+#2#cos(pi/#3# x {C:attention}$${C:mult})){} Mult {C:inactive}({C:attention}$${C:inactive} is your current money) {C:inactive}(Currently gives {C:mult}+#4#{C:inactive} Mult)" } },
    config = { extra = { mult = 10, coeff = 7, dilation = 8 } },
    rarity = 1, cost = 5, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "spiral.png", negative_sprite = "spiral_negative.png",
    loc_vars = function(self, info_queue, card)
        refresh_g()
        local e = card.ability.extra
        local money = tonumber(G and G.money) or 0
        local val = e.mult + math.floor(e.coeff * math.cos(math.pi / e.dilation * money) + 0.5)
        return { vars = { e.mult, e.coeff, e.dilation, val } }
    end,
    calculate = function(self, card, context)
        refresh_g()
        local e = card.ability.extra
        if context.joker_main then
            local money = tonumber(G and G.money) or 0
            return { mult = e.mult + math.floor(e.coeff * math.cos(math.pi / e.dilation * money) + 0.5) }
        end
    end,
}

--------------------------------------------------------------------------------
-- Steamflogger Boss: +16 Chips per Joker owned (Contraption crank
-- clause needs MoreFluff's Contraption system).
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "steamflogger_boss",
    loc_txt = { name = "Steamflogger Boss", text = { "{C:chips}+#1#{} Chips for every", "{C:attention}Joker{} owned", "{C:inactive}(Currently {C:chips}+#2# {C:inactive}Chips)", "Whenever a {C:attention}Wrench{} would", "{C:attention}crank{} a {C:attention}Contraption{},", "it {C:attention}cranks{} it twice instead" } },
    config = { extra = { chips = 16 } },
    rarity = "oldfluff", cost = 6, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "steamflogger_boss.png", negative_sprite = "steamflogger_boss_negative.png",
    loc_vars = function(self, info_queue, card)
        refresh_g()
        return { vars = { card.ability.extra.chips, card.ability.extra.chips * #mf_held_jokers() } }
    end,
    calculate = function(self, card, context)
        refresh_g()
        if context.joker_main then
            return { chips = card.ability.extra.chips * #mf_held_jokers() }
        end
    end,
}

--------------------------------------------------------------------------------
-- Stifle: +120 Chips if a Joker is to the right (PC also suppresses
-- that Joker via a can_calculate override: unsupported).
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "stifle",
    loc_txt = { name = "Stifle", text = { "The {C:attention}Joker{} to the right", "{C:red}doesn't trigger", "{C:chips}+#1#{} Chips if there is", "a {C:attention}Joker{} to the right" } },
    config = { extra = { chips = 120 } },
    rarity = 1, cost = 4, unlocked = true, discovered = true,
    blueprint_compat = false, eternal_compat = true, perishable_compat = false,
    sprite = "stifle.png", negative_sprite = "stifle_negative.png",
    loc_vars = function(self, info_queue, card) return { vars = { card.ability.extra.chips } } end,
    calculate = function(self, card, context)
        refresh_g()
        if context.joker_main then
            local idx, list = mf_joker_index(card)
            if idx and list[idx + 1] then return { chips = card.ability.extra.chips } end
        end
    end,
}

--------------------------------------------------------------------------------
-- Stone Joker Joker: Negative Marble Joker at end of shop
-- (PC also makes it Eternal: add_card has no eternal flag).
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "stonejokerjoker",
    loc_txt = { name = "StoneJoker Joker", text = { "Creates a {C:dark_edition}Negative{}", "{C:spectral}Eternal{} {C:attention}Marble Joker{}", "at the end of each Shop" } },
    config = { extra = {} },
    rarity = 2, cost = 8, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "stonejokerjoker.png", negative_sprite = "stonejokerjoker_negative.png",
    calculate = function(self, card, context)
        refresh_g()
        if context.ending_shop then
            if SMODS.add_card { set = "Joker", key = "j_marble", edition = "negative" } then
                return { message = "+Joker" }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Stormscale Scion: X1.5; Negative copies per 2 shop purchases,
-- destroyed at end of round.
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "stormscale",
    loc_txt = { name = "Stormscale Scion", text = { "{X:mult,C:white}X#1#{} Mult", "At end of shop, create a {C:dark_edition}Negative{}", "copy of this {C:attention}Joker{} for every {C:attention}#3#{}", "purchases or packs opened in the shop", "{C:red}Destroy{} them at end of round", "{C:inactive}(Currently #4# copies)" } },
    config = { extra = { xmult = 1.5, purchases_required = 2, purchases = 0, stormscale_temp = false } },
    rarity = "oldfluff", cost = 10, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = false, perishable_compat = false,
    sprite = "stormscale.png", negative_sprite = "stormscale_negative.png",
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        return { vars = { e.xmult, 0, e.purchases_required, math.floor(e.purchases / e.purchases_required) } }
    end,
    calculate = function(self, card, context)
        refresh_g()
        local e = card.ability.extra
        if (context.buying_card and context.card ~= card) or context.open_booster then
            if not context.blueprint then
                e.purchases = e.purchases + 1
                if e.purchases % e.purchases_required == 0 then return { message = "Upgrade!" } end
                return { message = (e.purchases % e.purchases_required) .. "/" .. e.purchases_required }
            end
        end
        if context.ending_shop and not context.blueprint and e.purchases >= e.purchases_required then
            local n = math.floor(e.purchases / e.purchases_required)
            for _ = 1, n do
                local made = SMODS.add_card { set = "Joker", key = "j_mfp_stormscale", edition = "negative" }
                if made and made.ability and made.ability.extra then
                    made.ability.extra.stormscale_temp = true
                end
            end
            return { message = "Duplicated!" }
        end
        if context.end_of_round and not context.blueprint then
            if e.stormscale_temp then
                SMODS.destroy_joker(card)
                return { message = "Destroyed!" }
            else
                e.purchases = 0
            end
        end
        if context.joker_main then return { xmult = e.xmult } end
    end,
}

--------------------------------------------------------------------------------
-- Style Meter: $3 per Blind skipped while held (PC counts run total).
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "stylemeter",
    loc_txt = { name = "Style Meter", text = { "Earn {C:money}$#1#{} at end", "of round for each", "{C:attention}Blind{} skipped this run", "{C:inactive}(Currently {C:money}$#2#{C:inactive})" } },
    config = { extra = { per = 3, skips = 0 } },
    rarity = 2, cost = 6, unlocked = true, discovered = true,
    blueprint_compat = false, eternal_compat = true, perishable_compat = true,
    sprite = "stylemeter.png", negative_sprite = "stylemeter_negative.png",
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        return { vars = { e.per, e.per * e.skips } }
    end,
    calc_dollar_bonus = function(self, card)
        local e = card.ability.extra
        if e.skips > 0 then return e.per * e.skips end
    end,
    calculate = function(self, card, context)
        refresh_g()
        if context.skip_blind and not context.blueprint then
            card.ability.extra.skips = card.ability.extra.skips + 1
        end
    end,
}

--------------------------------------------------------------------------------
-- Sudoku Joker: X5 once A-9 all scored; resets on Boss defeat.
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "sudoku",
    loc_txt = { name = "Sudoku Joker", text = { "{X:mult,C:white} X#1# {} Mult if each rank from {C:attention}A-9{}", "has been {C:attention}scored{}, resets when", "a {C:attention}Boss Blind{} is {C:red}defeated", "{C:inactive}(Currently {C:attention}A{C:inactive}, {C:attention}2{C:inactive}, {C:attention}3{C:inactive}, {C:attention}4{C:inactive}, {C:attention}5{C:inactive}, {C:attention}6{C:inactive}, {C:attention}7{C:inactive}, {C:attention}8{C:inactive}, {C:attention}9{C:inactive})" } },
    config = { extra = { xmult = 5, seen = { 0, 0, 0, 0, 0, 0, 0, 0, 0 } } },
    rarity = "oldfluff", cost = 9, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "sudoku.png", negative_sprite = "sudoku_negative.png",
    loc_vars = function(self, info_queue, card) return { vars = { card.ability.extra.xmult } } end,
    calculate = function(self, card, context)
        refresh_g()
        local e = card.ability.extra
        if context.end_of_round and not context.blueprint and mf_is_boss(context) then
            e.seen = { 0, 0, 0, 0, 0, 0, 0, 0, 0 }
            return { message = "Reset!" }
        end
        if context.individual and context.cardarea == G.play and not context.blueprint and context.other_card then
            local rank = context.other_card:get_id()
            if rank == 14 then rank = 1 end
            if rank >= 1 and rank <= 9 and e.seen[rank] == 0 then
                e.seen[rank] = 1
                return { message = "Noted!" }
            end
        end
        if context.joker_main then
            for i = 1, 9 do if e.seen[i] == 0 then return end end
            return { xmult = e.xmult }
        end
    end,
}

--------------------------------------------------------------------------------
-- Sword of Steven and Todd: held even cards +4 Mult, odd/Ace +31 Chips
-- (PC also makes Jokers undebuffable/unflippable: unsupported).
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "sword_of_steven_and_todd",
    loc_txt = { name = "Sword of Steven and Todd", text = { "{C:attention}Jokers{} cannot be debuffed", "or flipped face down", "{C:mult}+#1#{} Mult for each {C:attention}even{} card and", "{C:chips}+#2#{} Chips for each {C:attention}odd{} card", "{C:attention}held in hand{}" } },
    config = { extra = { mult = 4, chips = 31 } },
    rarity = 3, cost = 10, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "sword_of_steven_and_todd.png", negative_sprite = "sword_of_steven_and_todd_negative.png",
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        return { vars = { e.mult, e.chips } }
    end,
    calculate = function(self, card, context)
        refresh_g()
        local e = card.ability.extra
        if context.individual and context.cardarea == G.hand and not context.end_of_round and context.other_card then
            local id = context.other_card:get_id()
            if id <= 10 and id % 2 == 0 then return { mult = e.mult } end
            if (id <= 10 and id % 2 == 1) or id == 14 then return { chips = e.chips } end
        end
    end,
}

--------------------------------------------------------------------------------
-- The Jester: X2.5 per unique played pair.
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "thejester",
    loc_txt = { name = "The Jester", text = { "{X:mult,C:white} X#1# {} Mult for each unique played pair" } },
    config = { extra = { xmult_per = 2.5 } },
    rarity = "oldfluff", cost = 20, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "thejester.png", negative_sprite = "thejester_negative.png",
    loc_vars = function(self, info_queue, card) return { vars = { card.ability.extra.xmult_per } } end,
    calculate = function(self, card, context)
        refresh_g()
        local e = card.ability.extra
        if context.joker_main and context.scoring_hand then
            local counts = {}
            for _, v in ipairs(context.scoring_hand) do
                local id = v:get_id()
                counts[id] = (counts[id] or 0) + 1
            end
            local pairs_count = 0
            for _, n in pairs(counts) do if n == 2 then pairs_count = pairs_count + 1 end end
            if pairs_count > 0 then
                local x = 1
                for _ = 1, pairs_count do x = x * e.xmult_per end
                return { xmult = x }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Disintegration Loop (The Shattering Circle): scored 8s/3s give
-- rotated Chips/Mult; rotates on Blind select and 5-card discards.
-- (Transform into Event Horizon after a Boss: unsupported, dropped.
-- PC in_pool returns false.)
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "theshatteringcircle",
    loc_txt = { name = "Disintegration Loop", text = { "Scored {C:attention}8s{} and {C:attention}3s{} give", "{C:chips}+#1#{} Chips and {C:mult}+#2#{} Mult", "Rotate this effect by {C:attention}45{} degrees", "when a {C:attention}Blind{} is selected", "or {C:attention}five{} cards are discarded" } },
    config = { extra = { rotations = 0, chips = 50, mult = 20, bosses_left = 1 } },
    rarity = 3, cost = 10, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "theshatteringcircle.png", negative_sprite = "theshatteringcircle_negative.png",
    in_pool = function(self, args) return false end,
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        local chips = math.floor(e.chips * math.abs(math.cos(e.rotations * math.pi / 4)))
        local mult = math.floor(e.mult * math.abs(math.sin(e.rotations * math.pi / 4)))
        return { vars = { chips, mult, e.bosses_left } }
    end,
    calculate = function(self, card, context)
        refresh_g()
        local e = card.ability.extra
        local discarded = context.port and context.port.discarded_nodes
        if (context.setting_blind or (context.pre_discard and discarded and #discarded == 5))
            and not context.blueprint then
            e.rotations = e.rotations + 1
            return { message = "Rotated!" }
        end
        if context.individual and context.cardarea == G.play and context.other_card then
            local id = context.other_card:get_id()
            if id == 8 or id == 3 then
                local chips = math.floor(e.chips * math.abs(math.cos(e.rotations * math.pi / 4)))
                local mult = math.floor(e.mult * math.abs(math.sin(e.rotations * math.pi / 4)))
                if chips ~= 0 or mult ~= 0 then return { chips = chips, mult = mult } end
                return { message = "Rotated!" }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- I Sip Toner Soup: Tarot on hand played; destroyed at round end.
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "tonersoup",
    loc_txt = { name = "I Sip Toner Soup", text = { "Create a {C:tarot}Tarot{} card when a hand is played", "Destroyed when blind is defeated", "{C:inactive}(Must have room)" } },
    config = { extra = {} },
    rarity = "oldfluff", cost = 8, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = false, perishable_compat = true,
    sprite = "tonersoup.png", negative_sprite = "tonersoup_negative.png",
    calculate = function(self, card, context)
        refresh_g()
        if context.before then
            if mf_create_random_consumable("tarot", "tonersoup") then
                return { message = "+Tarot" }
            end
        end
        if context.end_of_round and not context.blueprint then
            SMODS.destroy_joker(card)
            return { message = "Drank!" }
        end
    end,
}

--------------------------------------------------------------------------------
-- Top 10 Jokers From 1 To 10: $5 per unique digit in money.
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "top10",
    loc_txt = { name = "Top 10 Jokers From 1 To 10", text = { "Earn {C:money}$#1#{} at end of round for each {C:green}unique digit{} displayed in {C:attention}current money{}", "{C:inactive}(They are 0, 1, 2, 3, 4, 5, 6, 7, 8, and 9.)" } },
    config = { extra = { cash_per = 5 } },
    rarity = 3, cost = 10, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "top10.png", negative_sprite = "top10_negative.png", soul_sprite = "top10_soul.png",
    loc_vars = function(self, info_queue, card) return { vars = { card.ability.extra.cash_per } } end,
    calc_dollar_bonus = function(self, card)
        refresh_g()
        local digits = tostring(math.floor(math.abs(tonumber(G and G.money) or 0)))
        local count = 0
        for i = 0, 9 do if digits:find(tostring(i), 1, true) then count = count + 1 end end
        if count > 0 then return card.ability.extra.cash_per * count end
    end,
}

--------------------------------------------------------------------------------
-- Treasure Map: after 2 rounds, sell for $13.
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "treasuremap",
    loc_txt = { name = "Treasure Map", text = { "After {C:attention}#2#{} rounds, sell this card to earn {C:money}$#3#{}", "{C:inactive}(Currently {C:attention}#1#{C:inactive}/#2#)" } },
    config = { extra = { c_rounds = 0, rounds = 2, money = 13 } },
    rarity = 1, cost = 4, unlocked = true, discovered = true,
    blueprint_compat = false, eternal_compat = false, perishable_compat = true,
    sprite = "treasuremap.png", negative_sprite = "treasuremap_negative.png",
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        return { vars = { e.c_rounds, e.rounds, e.money } }
    end,
    calculate = function(self, card, context)
        refresh_g()
        local e = card.ability.extra
        if context.end_of_round and not context.blueprint then
            e.c_rounds = e.c_rounds + 1
            return { message = (e.c_rounds < e.rounds) and (e.c_rounds .. "/" .. e.rounds) or "Active!" }
        end
        if context.selling_self and e.c_rounds >= e.rounds and not context.blueprint then
            return { dollars = e.money }
        end
    end,
}

--------------------------------------------------------------------------------
-- Triangular Joker: 3-card hands grow Chips, then grow the growth.
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "triangular",
    loc_txt = { name = "Triangular Joker", text = { "Gains {C:chips}+#2#{} Chips and increase {C:chips}Chips{} gained by {C:chips}#3#{} if played hand has exactly {C:attention}3{} cards", "{C:inactive}(Currently {C:chips}#1#{C:inactive} Chips)" } },
    config = { extra = { chips = 1, chip_mod = 2, chip_mod_mod = 1 } },
    rarity = "oldfluff", cost = 7, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = false,
    sprite = "triangular.png", negative_sprite = "triangular_negative.png",
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        return { vars = { e.chips, e.chip_mod, e.chip_mod_mod } }
    end,
    calculate = function(self, card, context)
        refresh_g()
        local e = card.ability.extra
        if context.before and not context.blueprint and context.full_hand and #context.full_hand == 3 then
            e.chips = e.chips + e.chip_mod
            e.chip_mod = e.chip_mod + e.chip_mod_mod
        end
        if context.joker_main then return { chips = e.chips } end
    end,
}

--------------------------------------------------------------------------------
-- Virtual Joker: X3 Mult (flip/shuffle on Blind select unsupported).
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "virtual",
    loc_txt = { name = "Virtual Joker", text = { "{X:red,C:white} X#1# {} Mult", "Flips and shuffles all", "Joker cards when", "blind is selected" } },
    config = { extra = { xmult = 3 } },
    rarity = "oldfluff", cost = 7, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = false,
    sprite = "virtual.png", negative_sprite = "virtual_negative.png",
    loc_vars = function(self, info_queue, card) return { vars = { card.ability.extra.xmult } } end,
    calculate = function(self, card, context)
        if context.joker_main then return { xmult = card.ability.extra.xmult } end
    end,
}

--------------------------------------------------------------------------------
-- Wild Draw Four: +4 hand size per Wild card scored this round.
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "wilddrawfour",
    loc_txt = { name = "Wild Draw Four", text = { "{C:attention}+#2#{} hand size for each {C:attention}Wild Card{} scored in the current round", "{C:inactive}(Currently {C:attention}+#1#{C:inactive} cards)" } },
    config = { h_size = 0, extra = { gain = 4 } },
    rarity = "oldfluff", cost = 7, unlocked = true, discovered = true,
    blueprint_compat = false, eternal_compat = true, perishable_compat = true,
    sprite = "wilddrawfour.png", negative_sprite = "wilddrawfour_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.h_size, card.ability.extra.gain } }
    end,
    calculate = function(self, card, context)
        refresh_g()
        local e = card.ability.extra
        if context.individual and context.cardarea == G.play and not context.blueprint
            and context.other_card and context.other_card.card_data
            and context.other_card.card_data.enhancement == "wild" then
            card.ability.h_size = (tonumber(card.ability.h_size) or 0) + e.gain
            return { message = "Upgrade!" }
        end
        if context.end_of_round and not context.blueprint then
            card.ability.h_size = 0
        end
    end,
}

--------------------------------------------------------------------------------
-- grep: if the first discard of the round is a single card, sort the
-- deck so cards matching its rank or suit sit at the draw end, and
-- report how many matched (PC message: localize a_searched "Found #1#").
-- PC checks G.GAME.current_round.discards_used; the fork has no such
-- counter, so the Joker counts pre_discard batches itself. A copy
-- gained mid-round starts its count at zero (PC would see the round's
-- earlier discards).
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "grep",
    loc_txt = { name = "grep", text = { "If {C:attention}first discard{} of round", "has only {C:attention}1{} card, shuffle", "all cards with {C:attention}matching", "{C:attention}rank or suit{} to", "the top of the {C:dark_edition}deck" } },
    config = { extra = { discards = 0 } },
    rarity = 3, cost = 8, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "grep.png", negative_sprite = "grep_negative.png",
    calculate = function(self, card, context)
        refresh_g()
        local e = card.ability.extra
        if context.end_of_round and not context.blueprint then
            e.discards = 0
        end
        if context.pre_discard and not context.blueprint then
            local first = e.discards == 0
            e.discards = e.discards + 1
            local discarded = context.port and context.port.discarded_nodes or {}
            if first and #discarded == 1 then
                local node = discarded[1]
                local data = node.card_data or {}
                local rank = tonumber(data.rank) or (node.get_id and node:get_id())
                local suit = data.suit or (node.base and node.base.suit)
                local cards = G and G.deck and G.deck.cards
                if cards and rank and suit then
                    local function matches(d)
                        return tonumber(d.rank) == rank or d.suit == suit
                    end
                    -- PC's comparator verbatim: matching cards end up
                    -- at the end of the list, which is where both
                    -- engines draw from.
                    table.sort(cards, function(a, b)
                        return matches(b) and not matches(a)
                    end)
                    local found = 0
                    for _, d in ipairs(cards) do
                        if matches(d) then found = found + 1 end
                    end
                    return { message = "Found " .. found }
                end
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- D (Letter): destroy 2 random playing cards at end of round.
-- PC destroys from G.playing_cards via SMODS.destroy_cards; here the
-- pool is deck + discard pile + hand, destroyed one at a time.
-- Playing cards carry no eternal sticker in the fork, so PC's
-- is_eternal filter is vacuous. PC's custom destroy-banner UI is
-- dropped.
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "lettergem_d",
    loc_txt = { name = "D", text = { "Destroy {C:attention}#1#{} random", "playing cards", "at end of round" } },
    config = { extra = { cards_per_round = 2 } },
    rarity = "letter", cost = 4, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "lettergem_d.png", negative_sprite = "lettergem_d_negative.png",
    loc_vars = function(self, info_queue, card) return { vars = { card.ability.extra.cards_per_round } } end,
    calculate = function(self, card, context)
        refresh_g()
        if context.end_of_round and not context.blueprint then
            local pool = {}
            if G and G.deck then
                for _, d in ipairs(G.deck.cards or {}) do pool[#pool + 1] = d end
                for _, d in ipairs(G.deck.discard_pile or {}) do pool[#pool + 1] = d end
            end
            if G and G.hand and G.hand.card_nodes then
                for _, n in ipairs(G.hand.card_nodes) do pool[#pool + 1] = n end
            end
            local destroyed = 0
            for _ = 1, card.ability.extra.cards_per_round do
                if #pool == 0 then break end
                local pick = pseudorandom_element(pool, "lettergem_d")
                if pick == nil then break end
                for i, v in ipairs(pool) do
                    if v == pick then table.remove(pool, i) break end
                end
                if SMODS.destroy_card(pick) then destroyed = destroyed + 1 end
            end
            if destroyed > 0 then return { message = "Destroyed!" } end
        end
    end,
}

--------------------------------------------------------------------------------
-- One Slip Too Late: XN Mult if the played hand has exactly N scoring
-- cards, N = hands played this round including this one. PC computes
-- N as current_round.hands_played + 1 at joker_main, where its
-- counter has not yet counted the current hand; the fork's counter
-- already has (it increments when the hand is played, before the
-- scoring sequence ticks), so mf_hands_played() IS PC's N here.
-- loc_vars keeps PC's +1: outside scoring the two counters agree.
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "onesliptoolate",
    loc_txt = { name = "One Slip Too Late", text = { "{X:mult,C:white} xN {} Mult if {C:attention}poker hand{} contains", "exactly {C:attention}N{} cards, where {C:attention}N{} is the", "number of hands played this round", "{C:inactive}(N currently equals {C:attention}#1#{C:inactive})" } },
    config = { extra = {} },
    rarity = 2, cost = 5, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = false,
    sprite = "onesliptoolate.png", negative_sprite = "onesliptoolate_negative.png",
    loc_vars = function(self, info_queue, card) return { vars = { mf_hands_played() + 1 } } end,
    calculate = function(self, card, context)
        refresh_g()
        if context.joker_main and context.scoring_hand then
            local n = mf_hands_played()
            if n >= 1 and #context.scoring_hand == n then
                return { xmult = n }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Whiteboard: X2 Mult per empty hand space after 3 cards (X2^(3-n)).
-- PC's context.forcetrigger clause (MoreFluff-internal force
-- triggers) is dropped.
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "whiteboard",
    loc_txt = { name = "Whiteboard", text = { "{X:red,C:white} X#1# {} Mult for each", "empty hand space", "after {C:attention}#2#{} cards" } },
    config = { extra = { xmult_per = 2, starting = 3 } },
    rarity = "oldfluff", cost = 6, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "whiteboard.png", negative_sprite = "whiteboard_negative.png",
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        return { vars = { e.xmult_per, e.starting } }
    end,
    calculate = function(self, card, context)
        refresh_g()
        local e = card.ability.extra
        if context.joker_main then
            local held = (G and G.hand and G.hand.card_nodes) and #G.hand.card_nodes or 0
            if held < e.starting then
                return { xmult = e.xmult_per ^ (e.starting - held) }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Simplified Joker: +4 Mult whenever another Common Joker triggers.
-- PC uses Steamodded's context.other_joker; the fork's post_trigger
-- is the same beat (what it returns scores as if this Joker had
-- triggered). PC's forcetrigger clause is dropped.
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "simplified",
    loc_txt = { name = "Simplified Joker", text = { "All {C:common}Common{} Jokers", "each give {C:mult}+#1#{} Mult" } },
    config = { extra = { mult = 4 } },
    rarity = 1, cost = 5, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "simplified.png", negative_sprite = "simplified_negative.png",
    loc_vars = function(self, info_queue, card) return { vars = { card.ability.extra.mult } } end,
    calculate = function(self, card, context)
        refresh_g()
        if context.post_trigger and context.other_card and context.other_card ~= card then
            local oc = context.other_card
            local r = (oc.def and tonumber(oc.def.rarity)) or tonumber(oc.rarity)
            if r == 1 then return { mult = card.ability.extra.mult } end
        end
    end,
}

--------------------------------------------------------------------------------
-- Burner Phone: no calculate at all; its tooltip reveals the top two
-- cards of the deck (the draw end of the deck list, where both
-- engines draw from). PC's per-fragment tooltip colours are dropped.
--------------------------------------------------------------------------------
local MF_RANK_NAMES = { [11] = "Jack", [12] = "Queen", [13] = "King", [14] = "Ace" }
local function mf_deck_peek(card_data)
    if type(card_data) ~= "table" then return "?", "?" end
    local rank = MF_RANK_NAMES[tonumber(card_data.rank)] or tostring(card_data.rank or "?")
    return rank, tostring(card_data.suit or "?")
end

SMODS.Joker {
    key = "burnerphone",
    loc_txt = { name = "Burner Phone", text = { "Shows the rank and suit", "of the top two cards", "of the deck", "{C:inactive}(Currently #1##2##3#", "{C:inactive}and #4##5##6#{C:inactive})" } },
    config = { extra = {} },
    rarity = "oldfluff", cost = 2, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "burnerphone.png", negative_sprite = "burnerphone_negative.png",
    loc_vars = function(self, info_queue, card)
        refresh_g()
        local owned = false
        if G and G.jokers then
            for _, j in ipairs(G.jokers) do
                if j.def and j.def.id == "j_mfp_burnerphone" then owned = true break end
            end
        end
        if not owned then
            return { vars = { "is ", "not ", "owned,", "you ", "get ", "nothing" } }
        end
        local cards = G and G.deck and G.deck.cards
        if not cards or #cards == 0 then
            return { vars = { "no ", "cards ", "left,", "the deck ", "is ", "empty" } }
        end
        local r1, s1 = mf_deck_peek(cards[#cards])
        if #cards == 1 then
            return { vars = { r1 .. " ", "of ", s1, "that ", "is ", "all" } }
        end
        local r2, s2 = mf_deck_peek(cards[#cards - 1])
        return { vars = { r1 .. " ", "of ", s1, r2 .. " ", "of ", s2 } }
    end,
}

--------------------------------------------------------------------------------
-- Hall of Mirrors: +3 hand size per 6 scored this round, reset at
-- end of round. PC's G.hand:change_size is the ability.h_size field
-- here, the same mechanism as Wild Draw Four.
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "hallofmirrors",
    loc_txt = { name = "Hall of Mirrors", text = { "{C:attention}+#2#{} hand size for", "each {C:attention}6{} scored in", "the current round", "{C:inactive}(Currently {C:attention}+#1#{C:inactive} cards)" } },
    config = { h_size = 0, extra = 3 },
    rarity = "oldfluff", cost = 6, unlocked = true, discovered = true,
    blueprint_compat = false, eternal_compat = true, perishable_compat = false,
    sprite = "hallofmirrors.png", negative_sprite = "hallofmirrors_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.h_size or 0, card.ability.extra } }
    end,
    calculate = function(self, card, context)
        refresh_g()
        if context.individual and context.cardarea == G.play and not context.blueprint
            and context.other_card and context.other_card:get_id() == 6 then
            card.ability.h_size = (card.ability.h_size or 0) + card.ability.extra
            return { message = "Upgrade!" }
        end
        if context.end_of_round and not context.blueprint then
            if (card.ability.h_size or 0) ~= 0 then
                card.ability.h_size = 0
                return { message = "Reset!" }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Hollow Joker: -1 hand size; +10 Mult per hand size below 9.
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "hollow",
    loc_txt = { name = "Hollow Joker", text = { "{C:attention}#1#{} hand size", "{C:mult}+#2#{} Mult per hand", "size below {C:attention}#3#" } },
    config = { h_size = -1, extra = { mult_per = 10, thresh = 9 } },
    rarity = 1, cost = 4, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "hollow.png", negative_sprite = "hollow_negative.png",
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        return { vars = { card.ability.h_size, e.mult_per, e.thresh } }
    end,
    calculate = function(self, card, context)
        refresh_g()
        local e = card.ability.extra
        if context.joker_main and G and G.get_effective_hand_size_limit then
            local limit = G:get_effective_hand_size_limit()
            if limit < e.thresh then
                return { mult = e.mult_per * (e.thresh - limit) }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Less Fluff: at blind select, destroy every other non-modded Joker
-- held and gain X0.2 Mult for each. (PC's tooltip says "Modded"
-- Jokers; PC's code destroys the non-modded ones. The port follows
-- the code, as elsewhere.) "Modded" on the fork = the def carries a
-- mod_id, which the loader sets for every mod Joker.
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "lessfluff",
    loc_txt = { name = "Less Fluff", text = { "Destroys all other {C:dark_edition}Modded{} {C:attention}Jokers{}", "at the start of each {C:attention}Blind{}", "and gains {X:mult,C:white} X#2# {} Mult for each", "{C:attention}Joker{} that was destroyed", "{C:inactive}(Currently {X:red,C:white} X#1# {C:inactive})" } },
    config = { extra = { x_mult = 1, x_mult_per = 0.2 } },
    rarity = 3, cost = 10, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "lessfluff.png", negative_sprite = "lessfluff_negative.png",
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        return { vars = { e.x_mult, e.x_mult_per } }
    end,
    calculate = function(self, card, context)
        refresh_g()
        local e = card.ability.extra
        if context.joker_main then return { xmult = e.x_mult } end
        if context.setting_blind and not context.blueprint then
            local destroyed = 0
            local others = {}
            for _, j in ipairs(mf_held_jokers()) do others[#others + 1] = j end
            for _, j in ipairs(others) do
                if j ~= card and not (j.def and j.def.mod_id) then
                    if SMODS.destroy_joker(j) then destroyed = destroyed + 1 end
                end
            end
            if destroyed > 0 then
                e.x_mult = e.x_mult + e.x_mult_per * destroyed
                return { message = "X" .. e.x_mult .. " Mult!" }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Q (Letter): cards held in hand adjacent to a Queen give X1.3 Mult.
-- PC's debuffed-card message is dropped.
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "lettergem_q",
    loc_txt = { name = "Q", text = { "Cards adjacent to", "{C:attention}Queens{} held in hand", "give {X:mult,C:white} X#1# {} Mult" } },
    config = { extra = { xmult = 1.3 } },
    rarity = "letter", cost = 20, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "lettergem_q.png", negative_sprite = "lettergem_q_negative.png",
    loc_vars = function(self, info_queue, card) return { vars = { card.ability.extra.xmult } } end,
    calculate = function(self, card, context)
        refresh_g()
        if context.individual and context.cardarea == (G and G.hand) and context.other_card
            and not context.other_card.debuff then
            local nodes = (G and G.hand and G.hand.card_nodes) or {}
            local idx = nil
            for i, n in ipairs(nodes) do
                if n == context.other_card then idx = i break end
            end
            if idx then
                local function is_queen(n)
                    return n ~= nil and ((n.card_data and tonumber(n.card_data.rank) == 12)
                        or (n.base and tonumber(n.base.id) == 12))
                end
                if is_queen(nodes[idx - 1]) or is_queen(nodes[idx + 1]) then
                    return { xmult = card.ability.extra.xmult }
                end
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- MS Paint Joker: +3 hand size for the first hand of each blind.
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "mspaint",
    loc_txt = { name = "MS Paint Joker", text = { "{C:attention}+#1#{} hand size", "for the first hand", "of each blind" } },
    config = { h_size = 0, extra = 3 },
    rarity = 1, cost = 5, unlocked = true, discovered = true,
    blueprint_compat = false, eternal_compat = true, perishable_compat = false,
    sprite = "mspaint.png", negative_sprite = "mspaint_negative.png",
    loc_vars = function(self, info_queue, card) return { vars = { card.ability.extra } } end,
    calculate = function(self, card, context)
        refresh_g()
        if context.setting_blind and not context.blueprint and (card.ability.h_size or 0) == 0 then
            card.ability.h_size = (card.ability.h_size or 0) + card.ability.extra
        end
        if context.after and not context.blueprint and (card.ability.h_size or 0) ~= 0 then
            card.ability.h_size = 0
        end
    end,
}

--------------------------------------------------------------------------------
-- Tier 3 top-up (v1.2.0): ports unblocked by the fork's Tier 3 systems
-- (return readers for x_chips / e_mult / swap / level_up, the
-- destroying_card / setting_ability / hand_drawn contexts,
-- SMODS.set_debuff, and the SMODS.Enhancement registrar).
--------------------------------------------------------------------------------

-- The enhancement a card view carries ("" when none).
local function mf_enhancement_of(view)
    if type(view) ~= "table" then return nil end
    if view.card_data and view.card_data.enhancement ~= nil then
        return view.card_data.enhancement
    end
    return view.enhancement
end

-- How many cards in the full deck carry a given enhancement value.
local function mf_count_enhancement(value)
    local g = refresh_g()
    if g and g.count_cards_in_full_deck then
        local ok, n = pcall(function()
            return g:count_cards_in_full_deck(function(c) return c.enhancement == value end)
        end)
        if ok and tonumber(n) then return tonumber(n) end
    end
    local n = 0
    if g and g.deck then
        for _, d in ipairs(g.deck.cards or {}) do
            if d.enhancement == value then n = n + 1 end
        end
        for _, d in ipairs(g.deck.discard_pile or {}) do
            if d.enhancement == value then n = n + 1 end
        end
    end
    if g and g.hand and g.hand.card_nodes then
        for _, node in ipairs(g.hand.card_nodes) do
            if node.card_data and node.card_data.enhancement == value then n = n + 1 end
        end
    end
    return n
end

-- Set a card view's enhancement through its canonical setter when it
-- has one (which raises setting_ability), else write the data field
-- (the PaperbackPack pattern).
local function mf_set_enhancement(view, value)
    if type(view) ~= "table" then return end
    if view.set_enhancement then
        view:set_enhancement(value)
    elseif view.card_data then
        view.card_data.enhancement = value
    end
end

--------------------------------------------------------------------------------
-- MoreFluff's custom enhancements, registered at weight 0: on PC they
-- are delivered by the Rotarot consumables (not ported), so they stay
-- out of the fork's random-enhancement polls; cards can still carry
-- them through SMODS.add_card / mod_conv, and the Jokers below read
-- them. Brass and Yucky have no intrinsic center effect the fork can
-- run (enhancement retriggers and destroy-after-scoring rolls are
-- never asked of a center -- only seals get a retrigger query), so
-- Brass Joker and Yucky Rat mediate those two effects while held.
--------------------------------------------------------------------------------

if SMODS.Enhancement then
    SMODS.Enhancement {
        key = "teal",
        loc_txt = { name = "Teal Card", text = { "{X:chips,C:white} X#1# {} Chips", "while this card", "stays in hand" } },
        config = { h_x_chips = 1.5 },
        weight = 0,
        sprite = "enh_teal.png",
        loc_vars = function(self, info_queue, card)
            return { vars = { self.config.h_x_chips } }
        end,
        calculate = function(self, card, context)
            if context.held_in_hand then
                return { x_chips = self.config.h_x_chips }
            end
        end,
    }
    SMODS.Enhancement {
        key = "marigold",
        loc_txt = { name = "Marigold Card", text = { "Earn {C:money}$#1#{} at", "end of round, plus", "{C:money}$#1#{} for each other", "{C:attention}Marigold Card{} in hand" } },
        config = { cash = 1 },
        weight = 0,
        sprite = "enh_marigold.png",
        loc_vars = function(self, info_queue, card)
            return { vars = { self.config.cash } }
        end,
        calculate = function(self, card, context)
            if context.on_round_end then
                local g = refresh_g()
                local count = 1
                if g and g.hand and g.hand.card_nodes then
                    count = 0
                    for _, node in ipairs(g.hand.card_nodes) do
                        if node.card_data and node.card_data.enhancement == "marigold" then
                            count = count + 1
                        end
                    end
                    if count == 0 then count = 1 end
                end
                return { dollars = self.config.cash * count }
            end
        end,
    }
    SMODS.Enhancement {
        key = "brass",
        loc_txt = { name = "Brass Card", text = { "{C:attention}Retriggers{} #1# additional", "times when scored", "{C:green}#2# in #3#{} chance to be", "{C:red}destroyed{} after being scored" } },
        config = { retriggers = 2, chance = 3 },
        weight = 0,
        sprite = "enh_brass.png",
        loc_vars = function(self, info_queue, card)
            local n, d = 1, self.config.chance
            if card and SMODS.get_probability_vars then
                n, d = SMODS.get_probability_vars(card, 1, self.config.chance, "brass_card")
            end
            return { vars = { self.config.retriggers, n, d } }
        end,
    }
    SMODS.Enhancement {
        key = "gemstone",
        loc_txt = { name = "Gemstone Card", text = { "Earn {C:money}$#1#{} at", "end of round while", "held in hand" } },
        config = { h_dollars = 3 },
        weight = 0,
        sprite = "enh_gemstone.png",
        loc_vars = function(self, info_queue, card)
            return { vars = { self.config.h_dollars } }
        end,
    }
    SMODS.Enhancement {
        key = "yucky",
        loc_txt = { name = "Yucky Card", text = { "{C:green}#1# in #2#{} chance to", "be {C:red}destroyed{}", "after being scored" } },
        config = { chance = 2 },
        weight = 0,
        sprite = "enh_yucky.png",
        loc_vars = function(self, info_queue, card)
            local n, d = 1, self.config.chance
            if card and SMODS.get_probability_vars then
                n, d = SMODS.get_probability_vars(card, 1, self.config.chance, "yucky_card")
            end
            return { vars = { n, d } }
        end,
    }
end

--------------------------------------------------------------------------------
-- Unpleasant Card: X2.067 Chips. PC's second clause (Booster Packs
-- contain only 1 card) is a Lovely patch on pack creation and is
-- dropped; see README.txt.
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "unpleasantcard",
    loc_txt = { name = "Unpleasant Card", text = { "{X:chips,C:white} X#1# {} Chips", "{C:attention}Booster Packs{} contain", "only {C:attention}1{} card" } },
    config = { extra = { x_chips = 2.067 } },
    rarity = 2, cost = 6.5, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "unpleasantcard.png", negative_sprite = "unpleasantcard_negative.png",
    loc_vars = function(self, info_queue, card) return { vars = { card.ability.extra.x_chips } } end,
    calculate = function(self, card, context)
        if context.joker_main then
            return { x_chips = card.ability.extra.x_chips }
        end
    end,
}

--------------------------------------------------------------------------------
-- Blahaj: swap Chips and Mult (the fork's swap return reader).
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "blahaj",
    loc_txt = { name = "Blåhaj", text = { "Swaps {C:chips}Chips{} and {C:mult}Mult{}" } },
    config = { extra = {} },
    rarity = 1, cost = 1, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "blahaj.png", negative_sprite = "blahaj_negative.png",
    calculate = function(self, card, context)
        if context.joker_main then
            return { swap = true, message = "Swapped!" }
        end
    end,
}

--------------------------------------------------------------------------------
-- Wide Joker: Mult ^ 1.14 (the fork's e_mult return reader).
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "widejoker",
    loc_txt = { name = "Wide Joker", text = { "{X:mult,C:white}^#1#{} Mult" } },
    config = { extra = { powmult = 1.14 } },
    rarity = 3, cost = 9, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "widejoker.png", negative_sprite = "widejoker_negative.png",
    loc_vars = function(self, info_queue, card) return { vars = { card.ability.extra.powmult } } end,
    calculate = function(self, card, context)
        if context.joker_main then
            return { e_mult = card.ability.extra.powmult }
        end
    end,
}

--------------------------------------------------------------------------------
-- Letter E: Mult ^ 1.4 (e_mult return reader).
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "lettergem_e",
    loc_txt = { name = "E", text = { "{X:mult,C:white}^#1#{} Mult" } },
    config = { extra = { emult = 1.4 } },
    rarity = "letter", cost = 2, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "lettergem_e.png", negative_sprite = "lettergem_e_negative.png",
    loc_vars = function(self, info_queue, card) return { vars = { card.ability.extra.emult } } end,
    calculate = function(self, card, context)
        if context.joker_main then
            return { e_mult = card.ability.extra.emult }
        end
    end,
}

--------------------------------------------------------------------------------
-- Jankman: every modded Joker (and Jolly Joker, as PC's tooltip jokes)
-- gives X1.31 Chips as it triggers. PC uses context.other_joker; the
-- fork's post_trigger is the same beat (the Simplified Joker pattern).
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "jankman",
    loc_txt = { name = "Jankman", text = { "All {C:dark_edition}modded{} Jokers", "{C:inactive}(and also Jolly Joker){}", "each give {X:chips,C:white} X#1# {} Chips" } },
    config = { extra = { x_chips = 1.31 } },
    rarity = 3, cost = 9, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "jankman.png", negative_sprite = "jankman_negative.png",
    loc_vars = function(self, info_queue, card) return { vars = { card.ability.extra.x_chips } } end,
    calculate = function(self, card, context)
        if context.post_trigger and context.other_card and context.other_card ~= card
            and context.other_context and context.other_context.joker_main then
            local def = context.other_card.def
            if def and (def.smods or def.id == "j_jolly") then
                return { x_chips = card.ability.extra.x_chips }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Teacup: level up each played hand, for the next 5 hands. PC calls
-- level_up_hand in `before`; the port returns level_up at joker_main,
-- where the fork's reader also adds the level's delta to the running
-- totals (the same final numbers). The charge is spent in `before`
-- and the cup is destroyed in `after` once spent, so the last charge
-- still levels its hand, as on PC.
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "teacup",
    loc_txt = { name = "Teacup", text = { "Upgrade the level of", "each {C:attention}played hand{}", "for the next {C:attention}#1#{} hands" } },
    config = { extra = 5 },
    rarity = 2, cost = 7, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = false, perishable_compat = true,
    sprite = "teacup.png", negative_sprite = "teacup_negative.png",
    loc_vars = function(self, info_queue, card) return { vars = { card.ability.extra } } end,
    calculate = function(self, card, context)
        refresh_g()
        if context.before and not context.blueprint and not context.retrigger_joker then
            card.ability.extra = card.ability.extra - 1
        end
        if context.joker_main then
            return { level_up = 1, message = "Upgrade!" }
        end
        if context.after and not context.blueprint and card.ability.extra <= 0 then
            SMODS.destroy_joker(card)
            return { message = "Drank!" }
        end
    end,
}

--------------------------------------------------------------------------------
-- Flint and Steel: level up the played hand when the scoring hand
-- contains a Stone Card and a Steel Card. PC calls
-- SMODS.upgrade_poker_hands in `before`; the level_up return at
-- joker_main levels the same (scored) hand with its delta added.
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "flintandsteel",
    loc_txt = { name = "Flint and Steel", text = { "Upgrade the level of each", "{C:attention}played hand{} if scored hand contains", "a {C:attention}Stone Card{} and {C:attention}Steel Card{}" } },
    config = { extra = {} },
    rarity = "oldfluff", cost = 4, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = false, perishable_compat = true,
    sprite = "flintandsteel.png", negative_sprite = "flintandsteel_negative.png",
    calculate = function(self, card, context)
        if context.joker_main and context.scoring_hand then
            local flint, steel = false, false
            for _, view in ipairs(context.scoring_hand) do
                local enh = mf_enhancement_of(view)
                if enh == "stone" then flint = true end
                if enh == "steel" then steel = true end
            end
            if flint and steel then
                return { level_up = 1, message = "Upgrade!" }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Rose-Tinted Glasses: if the first hand of the round is a single 2,
-- destroy it and create a Double Tag. PC hooks Steamodded's
-- destroying_card check, which runs after scoring; the port destroys
-- in the `after` pass, the Sixth Sense / Dayman slot, so the 2 still
-- scores first, as on PC.
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "rosetinted",
    loc_txt = { name = "Rose-Tinted Glasses", text = { "If {C:attention}first hand{} of round is", "a single {C:attention}2{}, destroy it and", "create a free {C:attention}Double Tag{}" } },
    config = { extra = {} },
    rarity = "oldfluff", cost = 5, unlocked = true, discovered = true,
    blueprint_compat = false, eternal_compat = true, perishable_compat = true,
    sprite = "rosetinted.png", negative_sprite = "rosetinted_negative.png",
    calculate = function(self, card, context)
        refresh_g()
        if context.after and not context.blueprint and mf_hands_played() == 1
            and context.full_hand and #context.full_hand == 1 then
            local view = context.full_hand[1]
            if view and view.get_id and view:get_id() == 2 then
                if SMODS.destroy_card(view) then
                    if G and G.addTag then G:addTag("double") end
                    return { message = "+Double Tag" }
                end
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Teal Joker: X1 + X0.2 Chips per Teal Card in the full deck. PC
-- keeps the tally in an update() tick; the port counts live, the
-- Coupon Catalogue pattern.
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "tealjoker",
    loc_txt = { name = "Teal Joker", text = { "Gives {X:chips,C:white} X#1# {} Chips", "for each {C:attention}Teal Card", "in your {C:attention}full deck", "{C:inactive}(Currently {X:chips,C:white} X#2# {C:inactive} Chips)" } },
    config = { extra = { x_chips_per = 0.2 } },
    rarity = 2, cost = 7, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = false,
    sprite = "tealjoker.png", negative_sprite = "tealjoker_negative.png",
    loc_vars = function(self, info_queue, card)
        local per = card.ability.extra.x_chips_per
        return { vars = { per, 1 + per * mf_count_enhancement("teal") } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            local tally = mf_count_enhancement("teal")
            if tally > 0 then
                return { x_chips = 1 + card.ability.extra.x_chips_per * tally }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Marigold: retrigger played and held Marigold Cards 2 more times
-- (the Joker repetition query covers both, as PC's does).
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "marigold",
    loc_txt = { name = "Marigold", text = { "{C:attention}Retriggers{} played and held", "{C:attention}Marigold Cards{} #1# times" } },
    config = { extra = { retriggers = 2 } },
    rarity = 4, cost = 20, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "marigold.png", negative_sprite = "marigold_negative.png",
    soul_sprite = "marigold_soul.png",
    loc_vars = function(self, info_queue, card) return { vars = { card.ability.extra.retriggers } } end,
    calculate = function(self, card, context)
        if context.repetition and context.other_card
            and mf_enhancement_of(context.other_card) == "marigold" then
            return { message = "Again!", repetitions = card.ability.extra.retriggers }
        end
    end,
}

--------------------------------------------------------------------------------
-- Brass Joker: retrigger the Joker to the right once per 3 Brass
-- Cards destroyed. The Brass Card's own scored retrigger and its
-- 1-in-3 destroy-after-scoring roll are enhancement effects the fork
-- never asks a center for, so this Joker mediates both while held
-- (see the enhancement registration note above).
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "brass",
    loc_txt = { name = "Brass Joker", text = { "{C:attention}Retrigger{} the joker", "to the right once for every", "{C:attention}#4# Brass Cards{} destroyed", "{C:inactive}(Currently {C:attention}#1#{C:inactive}, #2#/#3#{C:inactive})" } },
    config = { extra = { retriggers = 0, partial_rounds = 0, upgrade_rounds = 3 } },
    rarity = 3, cost = 10, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = false,
    sprite = "brass.png", negative_sprite = "brass_negative.png",
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        return { vars = { e.retriggers, e.partial_rounds, e.upgrade_rounds, e.upgrade_rounds } }
    end,
    calculate = function(self, card, context)
        refresh_g()
        local e = card.ability.extra
        if context.retrigger_joker_check and not context.retrigger_joker
            and context.other_card ~= card and e.retriggers >= 1 then
            local idx, list = mf_joker_index(card)
            if idx and list[idx + 1] == context.other_card then
                return { message = "Again!", repetitions = e.retriggers }
            end
        end
        if context.repetition and context.other_card
            and mf_enhancement_of(context.other_card) == "brass" then
            return { message = "Again!", repetitions = 2 }
        end
        if context.remove_playing_cards and not context.blueprint then
            local removed = (context.port and context.port.destroyed_cards) or {}
            local count = 0
            for _, view in ipairs(removed) do
                if mf_enhancement_of(view) == "brass" then count = count + 1 end
            end
            if count > 0 then
                e.partial_rounds = e.partial_rounds + count
                local upgraded = false
                while e.partial_rounds >= e.upgrade_rounds do
                    e.partial_rounds = e.partial_rounds - e.upgrade_rounds
                    e.retriggers = e.retriggers + 1
                    upgraded = true
                end
                if upgraded then return { message = "Upgrade!" } end
                return { message = e.partial_rounds .. "/" .. e.upgrade_rounds }
            end
        end
        if context.after and not context.blueprint and context.full_hand then
            for _, view in ipairs(context.full_hand) do
                if mf_enhancement_of(view) == "brass" then
                    local hit = SMODS.pseudorandom_probability(view, "brass_card", 1, 3, "brass_card")
                    if hit then SMODS.destroy_card(view) end
                end
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Gemstone Joker: earn $1 at end of round per Gemstone Card in the
-- full deck (calc_dollar_bonus, live tally as for Teal).
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "gemstonejoker",
    loc_txt = { name = "Gemstone Joker", text = { "Earn {C:money}$#1#{} at end of round", "for each {C:attention}Gemstone Card{}", "in your {C:attention}full deck{}", "{C:inactive}(Currently {C:money}$#2#{C:inactive})" } },
    config = { extra = { dollars_per = 1 } },
    rarity = 2, cost = 6, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = false,
    sprite = "gemstonejoker.png", negative_sprite = "gemstonejoker_negative.png",
    loc_vars = function(self, info_queue, card)
        local per = card.ability.extra.dollars_per
        return { vars = { per, per * mf_count_enhancement("gemstone") } }
    end,
    calc_dollar_bonus = function(self, card)
        local bonus = card.ability.extra.dollars_per * mf_count_enhancement("gemstone")
        if bonus > 0 then return bonus end
    end,
}

--------------------------------------------------------------------------------
-- Yucky Rat: played unenhanced cards become Yucky Cards; gains
-- X0.05 Mult per card converted. The Yucky Card's 1-in-2
-- destroy-after-scoring roll is an enhancement effect the fork never
-- asks a center for, so the Rat mediates it in the `after` pass while
-- held (see the enhancement registration note above).
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "yuckyrat",
    loc_txt = { name = "Yucky Rat", text = { "Played {C:attention}unenhanced{} cards", "are converted to {C:attention}Yucky Cards{}.", "Gains {X:red,C:white} X#1# {} Mult for", "each card converted", "{C:inactive}(Currently {X:red,C:white} X#2# {C:inactive} Mult)" } },
    config = { extra = { x_mult = 1, x_mult_mod = 0.05 } },
    rarity = 2, cost = 8, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = false,
    sprite = "yuckyrat.png", negative_sprite = "yuckyrat_negative.png",
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        return { vars = { e.x_mult_mod, e.x_mult } }
    end,
    calculate = function(self, card, context)
        refresh_g()
        local e = card.ability.extra
        if context.before and context.full_hand then
            local converted = 0
            for _, view in ipairs(context.full_hand) do
                if mf_enhancement_of(view) == nil then
                    mf_set_enhancement(view, "yucky")
                    converted = converted + 1
                end
            end
            if converted > 0 then
                e.x_mult = mf_round2(e.x_mult + e.x_mult_mod * converted)
                return { message = "Upgrade!" }
            end
        end
        if context.joker_main and e.x_mult > 1 then
            return { xmult = e.x_mult }
        end
        if context.after and not context.blueprint and context.full_hand then
            for _, view in ipairs(context.full_hand) do
                if mf_enhancement_of(view) == "yucky" then
                    local hit = SMODS.pseudorandom_probability(view, "yucky", 1, 2, "yucky_card")
                    if hit then SMODS.destroy_card(view) end
                end
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- All I Can't Do: debuff the first drawn hand of the round; gains
-- X0.1 Mult per debuffed card played. PC debuffs through
-- SMODS.debuff_card at first_hand_drawn; the port arms on
-- setting_blind and debuffs the first hand_drawn deal through
-- SMODS.set_debuff (the fork's canonical setter). PC's debuff is
-- source-keyed and lifts if the Joker leaves; the fork's perma_debuff
-- persists -- see README.txt.
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "allicantdo",
    loc_txt = { name = "All I Can't Do", text = { "{C:red}Debuffs{} first drawn hand", "Gains {X:red,C:white} X#1# {} Mult for", "each played {C:red}debuffed{} card", "{C:inactive}(Currently {X:red,C:white} X#2# {C:inactive})" } },
    config = { extra = { x_mult = 1, x_mult_mod = 0.1, armed = false } },
    rarity = 3, cost = 9, unlocked = true, discovered = true,
    blueprint_compat = true, eternal_compat = true, perishable_compat = false,
    sprite = "allicantdo.png", negative_sprite = "allicantdo_negative.png",
    soul_sprite = "allicantdo_soul.png",
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        return { vars = { e.x_mult_mod, e.x_mult } }
    end,
    calculate = function(self, card, context)
        refresh_g()
        local e = card.ability.extra
        if context.setting_blind and not context.blueprint then
            e.armed = true
        end
        if context.hand_drawn and e.armed and not context.blueprint then
            e.armed = false
            for _, view in ipairs(context.hand_drawn or {}) do
                SMODS.set_debuff(view, true)
            end
            return { message = "Debuffed!" }
        end
        if context.before and not context.blueprint and context.full_hand then
            local count = 0
            for _, view in ipairs(context.full_hand) do
                if view.debuff or (view.card_data and view.card_data.perma_debuff) then
                    count = count + 1
                end
            end
            if count > 0 then
                e.x_mult = mf_round2(e.x_mult + e.x_mult_mod * count)
                return { message = "Upgrade!" }
            end
        end
        if context.joker_main and e.x_mult > 1 then
            return { xmult = e.x_mult }
        end
    end,
}
