-- PaperbackPack: Paperback for Balatro3DS (Steamodded-style mod API).
--
-- A Balatro3DS-native port of Paperback (MIT License, Copyright (c)
-- 2025 Nether and contributors; full text in LICENSE.txt) for PC
-- Balatro + Steamodded:
--   https://github.com/Balatro-Paperback/paperback
-- PC mods cannot run on the 3DS build (no Lovely injector); these were
-- re-implemented against the Balatro3DS fork's mod API, effect by
-- effect, from Paperback's MIT-licensed sources (v0.9.0 tree), and
-- validated in the game's headless test harness. REQUIRES the fork
-- build (Tier 1 create/destroy, Tier 2 suits/hands/rarities,
-- SMODS.ConsumableType):
--   https://github.com/sen2008/balatro3ds-fork
--
-- Contents: 224 of Paperback's 316 Jokers, the Stars and Crowns
-- suits, the four Spectrum-family poker hands, and 33 of the 56
-- Minor Arcana consumables under a registered minor_arcana type.
-- The remaining 92 Jokers and 23 Arcana stay unported, each on a
-- named system the fork does not expose (custom enhancements, the
-- paperclip system, x_chips returns, the Apostle rank, custom tags
-- and editions, and a handful of contexts the port never raises);
-- README.txt lists them all with their blockers.
--
-- Port notes:
--   * Nazar counts Tarot AND Minor Arcana, as on PC.
--   * Find Jimbo's target card is drawn from the deck cards reachable
--     through the API at each round end (and at the first Blind select
--     after it is obtained).
--   * The Quiet counts cards below a 52-card starting deck.
--   * Calling Card and Attacking Vertical scale when a Boss Blind is
--     defeated (Paperback's extra debuff-trigger scale paths are dropped).
--   * Park Postcard resets on deck add/remove, as on PC.
--   * Minor Arcana arrive through the registered Minor Arcana booster
--     packs, as on PC, so the type's shop_rate is PC's 0 (v1.1.0).
--   * Sub-effect deviations in the expansion sections are marked
--     with PORT NOTE comments at each Joker.

local MOD_PREFIX = "pbp"

-- Live references to the running game, refreshed on every calculate call.
local G

-- Chip value of a scoring card view, PC get_chip_bonus style: the card's
-- chip total (rank value for plain cards) plus enhancement/per-card bonus.
local PB_RANK_CHIPS = { [11] = 10, [12] = 10, [13] = 10, [14] = 11 }
local function pb_chip_value(view)
    local data = (view and view.card_data) or {}
    local base = tonumber(data.chips)
    if not base then base = PB_RANK_CHIPS[tonumber(data.rank) or 0] or tonumber(data.rank) or 0 end
    if data.enhancement == "bonus" then base = base + 30 end
    base = base + (tonumber(data.Bonus) or tonumber(data.bonus) or 0)
    return base
end

-- Distinct enhancement types present in the full deck (Grand Strategy).
local function pb_distinct_enhancements(game)
    local seen = {}
    game:count_cards_in_full_deck(function(data)
        if data.enhancement then seen[data.enhancement] = true end
        return false
    end)
    local n = 0
    for _ in pairs(seen) do n = n + 1 end
    return n
end

-- Jokers in the run carrying a real edition, self included. Uneditioned
-- Jokers carry the edition string "base"; Negative is excluded by PC rule.
local PB_REAL_EDITIONS = { foil = true, holo = true, polychrome = true }
local function pb_editioned_jokers()
    local n = 0
    local list = (G and (G.jokers_cards or G.jokers)) or {}
    if G and G.jokers and G.jokers.cards then list = G.jokers.cards end
    for _, j in ipairs(list) do
        if type(j) == "table" and PB_REAL_EDITIONS[j.edition] then n = n + 1 end
    end
    return n
end

local function pb_deck_mult_by_rank(game, rank, sign)
    return game:count_cards_in_full_deck(function(data)
        return data.enhancement ~= "stone" and tonumber(data.rank) == rank
    end) * sign
end

local function pb_boss(context)
    local idx = context.port and context.port.blind_index
    if not idx and G then idx = G.current_blind_index end
    return idx == 3
end

local function pb_round2(x)
    return math.floor(x * 100 + 0.5) / 100
end

-- Find Jimbo: draw a target rank/suit from the run's actual cards.
local RANK_NAMES = {
    [2] = "2", [3] = "3", [4] = "4", [5] = "5", [6] = "6", [7] = "7",
    [8] = "8", [9] = "9", [10] = "10", [11] = "Jack", [12] = "Queen",
    [13] = "King", [14] = "Ace",
}
local function pb_find_jimbo_roll(state)
    local pool = {}
    local function add_all(list, is_nodes)
        for _, item in ipairs(type(list) == "table" and list or {}) do
            local data = is_nodes and item.card_data or item
            if type(data) == "table" and data.enhancement ~= "stone"
                and tonumber(data.rank) and data.suit then
                pool[#pool + 1] = data
            end
        end
    end
    if G then
        if G.deck then
            add_all(G.deck.cards, false)
            add_all(G.deck.discard_pile, false)
        end
        if G.hand then add_all(G.hand.cards, false) end
    end
    if #pool == 0 then return end
    local pick = pool[SMODS.pseudorandom("paperback_find_jimbo", 1, #pool)]
    state.target_rank = tonumber(pick.rank)
    state.target_rank_name = RANK_NAMES[state.target_rank] or "Ace"
    state.target_suit = pick.suit
end


SMODS.Joker {
    key = "aurora_borealis",
    name = "Aurora Borealis",
    rarity = 2,
    cost = 6,
    sprite = "aurora_borealis.png",
    negative_sprite = "aurora_borealis_negative.png",
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return {
            vars = { 0.5, 1 + 0.5 * pb_editioned_jokers() },
        }
    end,
    loc_txt = { name = "Aurora Borealis", text = {"This Joker gains X0.5 Mult for each", "editioned Joker card held", "(Negatives are excluded)", "(Currently X#2# Mult)"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.joker_main then
                local x = 1 + 0.5 * pb_editioned_jokers()
                if x > 1 then return { xmult = x } end
            end
    end,
}

SMODS.Joker {
    key = "bicycle",
    name = "Bicycle",
    rarity = 2,
    cost = 6,
    sprite = "bicycle.png",
    negative_sprite = "bicycle_negative.png",
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return { vars = { "Wild Card" } }
    end,
    loc_txt = { name = "Bicycle", text = {"Wild Cards give Mult equal", "to their Chip value when scored"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.individual and context.cardarea == G.play and context.other_card
                and context.other_card.card_data
                and context.other_card.card_data.enhancement == "wild" then
                return { mult = pb_chip_value(context.other_card) }
            end
    end,
}

SMODS.Joker {
    key = "emergency_broadcast",
    name = "Emergency Broadcast",
    rarity = 1,
    cost = 6,
    sprite = "emergency_broadcast.png",
    negative_sprite = "emergency_broadcast_negative.png",
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return { vars = { 5, 8 } }
    end,
    loc_txt = { name = "Emergency Broadcast", text = {"Scored 5s and 8s give", "+5 Mult and +8 Chips"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.individual and context.cardarea == G.play and context.other_card then
                local rank = context.other_card:get_id()
                if rank == 5 or rank == 8 then
                    return { mult = 5, chips = 8 }
                end
            end
    end,
}

SMODS.Joker {
    key = "find_jimbo",
    name = "Find Jimbo",
    rarity = 1,
    cost = 4,
    sprite = "find_jimbo.png",
    negative_sprite = "find_jimbo_negative.png",
    config = { extra = {
            money = 5, target_rank = 14, target_rank_name = "Ace",
            target_suit = "Spades", rolled = false,
        } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return {
            vars = { card.ability.extra.target_rank_name,
                card.ability.extra.target_suit, 5 },
        }
    end,
    loc_txt = { name = "Find Jimbo", text = {"Each played #1# of #2# earns", "$#3# when scored", "(Card changes every round)"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.individual and context.cardarea == G.play and context.other_card then
                local st = card.ability.extra
                if context.other_card:get_id() == st.target_rank
                    and context.other_card:is_suit(st.target_suit) then
                    return { dollars = st.money }
                end
            end
            if context.setting_blind and not card.ability.extra.rolled then
                card.ability.extra.rolled = true
                pb_find_jimbo_roll(card.ability.extra)
            end
            if context.end_of_round then
                card.ability.extra.rolled = true
                pb_find_jimbo_roll(card.ability.extra)
            end
    end,
}

SMODS.Joker {
    key = "guns_blazin",
    name = "Guns Blazin'",
    rarity = 2,
    cost = 8,
    sprite = "guns_blazin.png",
    negative_sprite = "guns_blazin_negative.png",
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return { vars = { 1.5, "Ace" } }
    end,
    loc_txt = { name = "Guns Blazin'", text = {"Played Aces give X1.5 Mult", "when scored"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.individual and context.cardarea == G.play and context.other_card
                and context.other_card:get_id() == 14 then
                return { xmult = 1.5 }
            end
    end,
}

SMODS.Joker {
    key = "insurance_policy",
    name = "Insurance Policy",
    rarity = 2,
    cost = 6,
    sprite = "insurance_policy.png",
    negative_sprite = "insurance_policy_negative.png",
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        local current = 0
        if G and G.count_cards_in_full_deck then
            current = 5 * (pb_deck_mult_by_rank(G, 11, 1) + pb_deck_mult_by_rank(G, 13, -1))
        end
        return { vars = { 5, current, "Jack", "King" } }
    end,
    loc_txt = { name = "Insurance Policy", text = {"+5 Mult for each Jack and", "-5 Mult for each King", "in your full deck", "(Currently #2# Mult)"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.joker_main and G and G.count_cards_in_full_deck then
                local tally = pb_deck_mult_by_rank(G, 11, 1) + pb_deck_mult_by_rank(G, 13, -1)
                if tally ~= 0 then return { mult = 5 * tally } end
            end
    end,
}

SMODS.Joker {
    key = "malibu",
    name = "Malibu",
    rarity = 2,
    cost = 7,
    sprite = "malibu.png",
    negative_sprite = "malibu_negative.png",
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        local lowest
        local nodes = G and G.hand and G.hand.card_nodes
        for _, view in ipairs(type(nodes) == "table" and nodes or {}) do
            local v = pb_chip_value(view)
            if not lowest or v < lowest then lowest = v end
        end
        return { vars = { 10, lowest and (10 * lowest) or 0 } }
    end,
    loc_txt = { name = "Malibu", text = {"Gives Chips equal to 10 times", "the lowest Chip value card", "in the scored hand", "(Currently +#2# Chips)"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.joker_main and context.scoring_hand and #context.scoring_hand > 0 then
                local lowest
                for _, view in ipairs(context.scoring_hand) do
                    local v = pb_chip_value(view)
                    if not lowest or v < lowest then lowest = v end
                end
                if lowest then return { chips = 10 * lowest } end
            end
    end,
}

SMODS.Joker {
    key = "trust_us",
    name = "Trust Us!",
    rarity = 2,
    cost = 6,
    sprite = "trust_us.png",
    negative_sprite = "trust_us_negative.png",
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return { vars = { 3, 0.5, "Three of a Kind" } }
    end,
    loc_txt = { name = "Trust Us!", text = {"X3 Mult if played hand contains", "a Three of a Kind, X0.5 Mult otherwise"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.joker_main then
                if next(context.poker_hands["Three of a Kind"]) then
                    return { xmult = 3 }
                end
                return { xmult = 0.5 }
            end
    end,
}

SMODS.Joker {
    key = "attacking_vertical",
    name = "Attacking Vertical",
    rarity = 3,
    cost = 8,
    sprite = "attacking_vertical.png",
    negative_sprite = "attacking_vertical_negative.png",
    config = { extra = { xm = 1.25 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return {
            vars = { 9, 5, card.ability.extra.xm, 0.25 },
        }
    end,
    loc_txt = { name = "Attacking Vertical", text = {"Scored 9s and 5s give X#3# Mult", "Gains +X0.25 Mult when a", "Boss Blind is defeated"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.individual and context.cardarea == G.play and context.other_card then
                local rank = context.other_card:get_id()
                if rank == 9 or rank == 5 then
                    return { xmult = card.ability.extra.xm }
                end
            end
            if context.blind_defeated and pb_boss(context) then
                card.ability.extra.xm = pb_round2(card.ability.extra.xm + 0.25)
                return { message = "Upgrade!" }
            end
    end,
}

SMODS.Joker {
    key = "better_call_jimbo",
    name = "Better Call Jimbo",
    rarity = 3,
    cost = 8,
    sprite = "better_call_jimbo.png",
    negative_sprite = "better_call_jimbo_negative.png",
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return {
            vars = { 0.1, 4, 1 + 0.1 * math.floor(math.max(0, (G and G.money) or 0) / 4) },
        }
    end,
    loc_txt = { name = "Better Call Jimbo", text = {"X0.1 Mult for every $4 owned", "(Currently X#3# Mult)"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.joker_main then
                local x = 1 + 0.1 * math.floor(math.max(0, (G and G.money) or 0) / 4)
                if x > 1 then return { xmult = x } end
            end
    end,
}

SMODS.Joker {
    key = "calling_card",
    name = "Calling Card",
    rarity = 2,
    cost = 6,
    sprite = "calling_card.png",
    negative_sprite = "calling_card_negative.png",
    config = { extra = { xm = 1 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return {
            vars = { 0.25, card.ability.extra.xm },
        }
    end,
    loc_txt = { name = "Calling Card", text = {"Gains +X0.25 Mult whenever you", "defeat a Boss Blind", "(Currently X#2# Mult)"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.blind_defeated and pb_boss(context) then
                card.ability.extra.xm = pb_round2(card.ability.extra.xm + 0.25)
                return { message = "Upgrade!" }
            end
            if context.joker_main and card.ability.extra.xm > 1 then
                return { xmult = card.ability.extra.xm }
            end
    end,
}

SMODS.Joker {
    key = "claw",
    name = "Claw",
    rarity = 1,
    cost = 3,
    sprite = "claw.png",
    negative_sprite = "claw_negative.png",
    config = { extra = { mult = 3 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return {
            vars = { "3", 2, card.ability.extra.mult, 3 },
        }
    end,
    loc_txt = { name = "Claw", text = {"Scored 3s give +#4# Mult,", "+2 more Mult for each previously", "scored 3 this round", "(Currently +#3# Mult)"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.individual and context.cardarea == G.play and context.other_card
                and context.other_card:get_id() == 3 then
                local give = card.ability.extra.mult
                card.ability.extra.mult = give + 2
                return { mult = give }
            end
            if context.end_of_round then
                card.ability.extra.mult = 3
            end
    end,
}

SMODS.Joker {
    key = "giga_size",
    name = "GIGA SIZE",
    rarity = 3,
    cost = 8,
    sprite = "giga_size.png",
    negative_sprite = "giga_size_negative.png",
    config = { extra = { xm = 1 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return {
            vars = { card.ability.extra.xm, 1 },
        }
    end,
    loc_txt = { name = "GIGA SIZE", text = {"Gains +X1 Mult for every hand", "played in the current Blind", "(Currently X#1# Mult)"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.before then
                card.ability.extra.xm = card.ability.extra.xm + 1
            end
            if context.joker_main then
                return { xmult = card.ability.extra.xm }
            end
            if context.end_of_round then
                card.ability.extra.xm = 1
            end
    end,
}

SMODS.Joker {
    key = "grand_strategy",
    name = "Grand Strategy",
    rarity = 3,
    cost = 8,
    sprite = "grand_strategy.png",
    negative_sprite = "grand_strategy_negative.png",
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        local distinct = 0
        if G and G.count_cards_in_full_deck then
            distinct = pb_distinct_enhancements(G)
        end
        return { vars = { 4, 7, distinct } }
    end,
    loc_txt = { name = "Grand Strategy", text = {"X4 Mult if 7 unique enhancements", "are in your full deck", "(Currently #3# enhancements)"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.joker_main and G and G.count_cards_in_full_deck
                and pb_distinct_enhancements(G) >= 7 then
                return { xmult = 4 }
            end
    end,
}

SMODS.Joker {
    key = "jacks",
    name = "Jacks",
    rarity = 1,
    cost = 5,
    sprite = "jacks.png",
    negative_sprite = "jacks_negative.png",
    config = { extra = { mult = 0 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return {
            vars = { 1, card.ability.extra.mult, "Jack" },
        }
    end,
    loc_txt = { name = "Jacks", text = {"Gains +1 Mult when a Jack", "is discarded", "(Currently +#2# Mult)"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.discard and context.other_card
                and context.other_card:get_id() == 11 then
                card.ability.extra.mult = card.ability.extra.mult + 1
                return { message = "Upgrade!" }
            end
            if context.joker_main and card.ability.extra.mult > 0 then
                return { mult = card.ability.extra.mult }
            end
    end,
}

SMODS.Joker {
    key = "jestrica",
    name = "Jestrica",
    rarity = 1,
    cost = 5,
    sprite = "jestrica.png",
    negative_sprite = "jestrica_negative.png",
    config = { extra = { mult = 0, scored8 = false } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return {
            vars = { 1, card.ability.extra.mult, "8" },
        }
    end,
    loc_txt = { name = "Jestrica", text = {"Gains +1 Mult when an 8 is scored", "Resets if no 8s are scored in a round", "(Currently +#2# Mult)"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.individual and context.cardarea == G.play and context.other_card
                and context.other_card:get_id() == 8 then
                card.ability.extra.mult = card.ability.extra.mult + 1
                card.ability.extra.scored8 = true
                return { message = "Upgrade!" }
            end
            if context.joker_main and card.ability.extra.mult > 0 then
                return { mult = card.ability.extra.mult }
            end
            if context.end_of_round then
                if not card.ability.extra.scored8 then
                    card.ability.extra.mult = 0
                end
                card.ability.extra.scored8 = false
            end
    end,
}

SMODS.Joker {
    key = "magic_mushroom",
    name = "Magic Mushroom",
    rarity = 3,
    cost = 8,
    sprite = "magic_mushroom.png",
    negative_sprite = "magic_mushroom_negative.png",
    config = { extra = { xm = 3 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return {
            vars = { 3, 0.5, card.ability.extra.xm },
        }
    end,
    loc_txt = { name = "Magic Mushroom", text = {"X#3# Mult", "Loses X0.5 Mult for every hand played", "Resets after clearing a Blind"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.joker_main and card.ability.extra.xm > 1 then
                return { xmult = card.ability.extra.xm }
            end
            if context.after and card.ability.extra.xm - 0.5 >= 1 then
                card.ability.extra.xm = pb_round2(card.ability.extra.xm - 0.5)
            end
            if context.blind_defeated then
                card.ability.extra.xm = 3
            end
    end,
}

SMODS.Joker {
    key = "mismatched_sock",
    name = "Mismatched Sock",
    rarity = 2,
    cost = 6,
    sprite = "mismatched_sock.png",
    negative_sprite = "mismatched_sock_negative.png",
    config = { extra = { xm = 1 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return {
            vars = { 0.1, card.ability.extra.xm },
        }
    end,
    loc_txt = { name = "Mismatched Sock", text = {"Gains +X0.1 Mult if a discard", "contains exactly one card", "Resets if a played hand contains a Pair", "(Currently X#2# Mult)"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.pre_discard and context.port and context.port.discarded_nodes
                and #context.port.discarded_nodes == 1 then
                card.ability.extra.xm = pb_round2(card.ability.extra.xm + 0.1)
                return { message = "Upgrade!" }
            end
            if context.before and next(context.poker_hands["Pair"]) then
                card.ability.extra.xm = 1
            end
            if context.joker_main and card.ability.extra.xm > 1 then
                return { xmult = card.ability.extra.xm }
            end
    end,
}

SMODS.Joker {
    key = "nazar",
    name = "Nazar",
    rarity = 1,
    cost = 5,
    sprite = "nazar.png",
    negative_sprite = "nazar_negative.png",
    config = { extra = { chips = 0 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return {
            vars = { 8, card.ability.extra.chips },
        }
    end,
    loc_txt = { name = "Nazar", text = {"Gains +8 Chips when a Tarot", "or Minor Arcana card is used", "(Currently +#2# Chips)"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.using_consumeable and context.port
                and (context.port.consumable_kind == "tarot"
                    or context.port.consumable_kind == "minor_arcana") then
                card.ability.extra.chips = card.ability.extra.chips + 8
                return { message = "Upgrade!" }
            end
            if context.joker_main and card.ability.extra.chips > 0 then
                return { chips = card.ability.extra.chips }
            end
    end,
}

SMODS.Joker {
    key = "planchette",
    name = "Planchette",
    rarity = 2,
    cost = 6,
    sprite = "planchette.png",
    negative_sprite = "planchette_negative.png",
    config = { extra = { xm = 1 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return {
            vars = { 0.25, card.ability.extra.xm },
        }
    end,
    loc_txt = { name = "Planchette", text = {"Gains +X0.25 Mult when a Spectral", "card is used", "(Currently X#2# Mult)"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.using_consumeable and context.port
                and context.port.consumable_kind == "spectral" then
                card.ability.extra.xm = pb_round2(card.ability.extra.xm + 0.25)
                return { message = "Upgrade!" }
            end
            if context.joker_main and card.ability.extra.xm > 1 then
                return { xmult = card.ability.extra.xm }
            end
    end,
}

SMODS.Joker {
    key = "satellite_array",
    name = "Satellite Array",
    rarity = 2,
    cost = 7,
    sprite = "satellite_array.png",
    negative_sprite = "satellite_array_negative.png",
    config = { extra = { chips = 0 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return {
            vars = { 15, 5, card.ability.extra.chips,
                "Planet" },
        }
    end,
    loc_txt = { name = "Satellite Array", text = {"Gains +15 Chips for each Planet", "card used, and loses -5 Chips", "for every hand played", "(Currently +#3# Chips)"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.using_consumeable and context.port
                and context.port.consumable_kind == "planet" then
                card.ability.extra.chips = card.ability.extra.chips + 15
                return { message = "Upgrade!" }
            end
            if context.joker_main and card.ability.extra.chips > 0 then
                return { chips = card.ability.extra.chips }
            end
            if context.after then
                card.ability.extra.chips = card.ability.extra.chips - 5
            end
    end,
}

SMODS.Joker {
    key = "technology",
    name = "Technology",
    rarity = 2,
    cost = 8,
    sprite = "technology.png",
    negative_sprite = "technology_negative.png",
    config = { extra = { xm = 1 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return {
            vars = { card.ability.extra.xm,
                "Mult Cards", card.ability.extra.xm },
        }
    end,
    loc_txt = { name = "Technology", text = {"Gains +X0.5 Mult for each scoring", "Mult Card, during this round", "(Currently X#1# Mult)"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.before and context.scoring_hand then
                local n = 0
                for _, view in ipairs(context.scoring_hand) do
                    if view.card_data and view.card_data.enhancement == "mult" then
                        n = n + 1
                    end
                end
                if n > 0 then
                    card.ability.extra.xm = pb_round2(card.ability.extra.xm + 0.5 * n)
                end
            end
            if context.joker_main and card.ability.extra.xm > 1 then
                return { xmult = card.ability.extra.xm }
            end
            if context.end_of_round then
                card.ability.extra.xm = 1
            end
    end,
}

SMODS.Joker {
    key = "toppins",
    name = "Toppins",
    rarity = 1,
    cost = 5,
    sprite = "toppins.png",
    negative_sprite = "toppins_negative.png",
    config = { extra = { mult = 2 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return {
            vars = { 2, 2, card.ability.extra.mult },
        }
    end,
    loc_txt = { name = "Toppins", text = {"Cards give +#1# Mult when scored", "Increases by +2 Mult for each", "previously scored card", "(Resets after each hand played)"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.individual and context.cardarea == G.play then
                local give = card.ability.extra.mult
                card.ability.extra.mult = give + 2
                return { mult = give }
            end
            if context.after then
                card.ability.extra.mult = 2
            end
    end,
}

SMODS.Joker {
    key = "union_card",
    name = "Union Card",
    rarity = 3,
    cost = 8,
    sprite = "union_card.png",
    negative_sprite = "union_card_negative.png",
    loc_txt = { name = "Union Card", text = {"XMult equal to the number of", "scoring light suit cards", "(Hearts and Diamonds)"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.joker_main and context.scoring_hand then
                local n = 0
                for _, view in ipairs(context.scoring_hand) do
                    if view:is_suit("Hearts") or view:is_suit("Diamonds") then
                        n = n + 1
                    end
                end
                if n > 1 then return { xmult = n } end
            end
    end,
}

SMODS.Joker {
    key = "the_quiet",
    name = "The Quiet",
    rarity = 3,
    cost = 8,
    sprite = "the_quiet.png",
    negative_sprite = "the_quiet_negative.png",
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        local current = 1
        if G and G.count_cards_in_full_deck then
            local total = G:count_cards_in_full_deck(function() return true end)
            current = 1 + 0.1 * math.max(0, 52 - total)
        end
        return { vars = { current, 52, current } }
    end,
    loc_txt = { name = "The Quiet", text = {"X0.1 Mult for each card below", "52 in your full deck", "(Currently X#1# Mult)"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.joker_main and G and G.count_cards_in_full_deck then
                local total = G:count_cards_in_full_deck(function() return true end)
                local x = 1 + 0.1 * math.max(0, 52 - total)
                if x > 1 then return { xmult = pb_round2(x) } end
            end
    end,
}

SMODS.Joker {
    key = "pocket_pair",
    name = "Pocket Pair",
    rarity = 1,
    cost = 5,
    sprite = "pocket_pair.png",
    negative_sprite = "pocket_pair_negative.png",
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return { vars = { 3, "Pair" } }
    end,
    loc_txt = { name = "Pocket Pair", text = {"Earn $3 if a Pair is drawn", "at start of round"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.first_hand_drawn and G and G.hand and G.hand.card_nodes then
                local counts = {}
                for _, node in ipairs(G.hand.card_nodes) do
                    local rank = node.card_data and tonumber(node.card_data.rank)
                    if rank then
                        counts[rank] = (counts[rank] or 0) + 1
                        if counts[rank] >= 2 then
                            return { dollars = 3 }
                        end
                    end
                end
            end
    end,
}

SMODS.Joker {
    key = "rosary_beads",
    name = "Rosary Beads",
    rarity = 1,
    cost = 4,
    sprite = "rosary_beads.png",
    negative_sprite = "rosary_beads_negative.png",
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return { vars = { 3, 5, "Hearts" } }
    end,
    loc_txt = { name = "Rosary Beads", text = {"If the scored hand contains 3 or", "more Hearts, earn $5"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.joker_main and context.scoring_hand then
                local hearts = 0
                for _, view in ipairs(context.scoring_hand) do
                    if view:is_suit("Hearts") then hearts = hearts + 1 end
                end
                if hearts >= 3 then return { dollars = 5 } end
            end
    end,
}

SMODS.Joker {
    key = "surfer",
    name = "Surfer",
    rarity = 2,
    cost = 7,
    sprite = "surfer.png",
    negative_sprite = "surfer_negative.png",
    config = { extra = { chips = 0 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return {
            vars = { 10, "10", card.ability.extra.chips },
        }
    end,
    loc_txt = { name = "Surfer", text = {"Gains +10 Chips for every 10", "held in hand at end of round", "(Currently +#3# Chips)"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.end_of_round and G and G.hand and G.hand.card_nodes then
                local n = 0
                for _, node in ipairs(G.hand.card_nodes) do
                    if node.card_data and tonumber(node.card_data.rank) == 10 then
                        n = n + 1
                    end
                end
                if n > 0 then
                    card.ability.extra.chips = card.ability.extra.chips + 10 * n
                    return { message = "Upgrade!" }
                end
            end
            if context.joker_main and card.ability.extra.chips > 0 then
                return { chips = card.ability.extra.chips }
            end
    end,
}

SMODS.Joker {
    key = "the_girl_from_024",
    name = "The Girl From 024",
    rarity = 2,
    cost = 7,
    sprite = "the_girl_from_024.png",
    negative_sprite = "the_girl_from_024_negative.png",
    config = { extra = { xm = 1 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return {
            vars = { 0.2, card.ability.extra.xm },
        }
    end,
    loc_txt = { name = "The Girl From 024", text = {"Gains +X0.2 Mult for every Queen", "held in hand at end of round", "(Currently X#2# Mult)"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.end_of_round and G and G.hand and G.hand.card_nodes then
                local n = 0
                for _, node in ipairs(G.hand.card_nodes) do
                    if node.card_data and tonumber(node.card_data.rank) == 12 then
                        n = n + 1
                    end
                end
                if n > 0 then
                    card.ability.extra.xm = pb_round2(card.ability.extra.xm + 0.2 * n)
                    return { message = "Upgrade!" }
                end
            end
            if context.joker_main and card.ability.extra.xm > 1 then
                return { xmult = card.ability.extra.xm }
            end
    end,
}

SMODS.Joker {
    key = "tian_tian",
    name = "Tian Tian",
    rarity = 3,
    cost = 7,
    sprite = "tian_tian.png",
    negative_sprite = "tian_tian_negative.png",
    config = { extra = { xm = 1 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return {
            vars = { 0.1, card.ability.extra.xm },
        }
    end,
    loc_txt = { name = "Tian Tian", text = {"Gains +X0.1 Mult when a playing", "card is destroyed", "(Currently X#2# Mult)"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.remove_playing_cards and context.port
                and context.port.destroyed_cards
                and #context.port.destroyed_cards > 0 then
                card.ability.extra.xm = pb_round2(
                    card.ability.extra.xm + 0.1 * #context.port.destroyed_cards)
                return { message = "Upgrade!" }
            end
            if context.joker_main and card.ability.extra.xm > 1 then
                return { xmult = card.ability.extra.xm }
            end
    end,
}

SMODS.Joker {
    key = "time_regression_mix",
    name = "Time Regression Mix",
    rarity = 1,
    cost = 3,
    sprite = "time_regression_mix.png",
    negative_sprite = "time_regression_mix_negative.png",
    config = { extra = { mult = 0 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return {
            vars = { 4, 2, card.ability.extra.mult },
        }
    end,
    loc_txt = { name = "Time Regression Mix", text = {"If the scoring hand contains at", "least 4 suits, gains +2 Mult", "(Currently +#3# Mult)"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.before and context.scoring_hand then
                local suits, wilds = {}, 0
                for _, view in ipairs(context.scoring_hand) do
                    local data = view.card_data or {}
                    if data.enhancement == "wild" then
                        wilds = wilds + 1
                    elseif data.enhancement ~= "stone" and data.suit then
                        suits[data.suit] = true
                    end
                end
                local distinct = 0
                for _ in pairs(suits) do distinct = distinct + 1 end
                distinct = math.min(4, distinct + wilds)
                if distinct >= 4 then
                    card.ability.extra.mult = card.ability.extra.mult + 2
                    return { message = "Upgrade!" }
                end
            end
            if context.joker_main and card.ability.extra.mult > 0 then
                return { mult = card.ability.extra.mult }
            end
    end,
}

SMODS.Joker {
    key = "57_leaf_clover",
    name = "57 Leaf Clover",
    rarity = 3,
    cost = 7,
    sprite = "57_leaf_clover.png",
    negative_sprite = "57_leaf_clover_negative.png",
    config = { extra = { current = 1 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return {
            vars = { card.ability.extra.current, 1 },
        }
    end,
    loc_txt = { name = "57 Leaf Clover", text = {"+#1# to all listed probabilities", "(Currently +#1#)"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.blueprint then return end
            if context.mod_probability then
                return {
                    numerator = (context.numerator or 0)
                        + card.ability.extra.current,
                }
            end
            if context.end_of_round then
                if G and G.current_blind_index == 3 then
                    card.ability.extra.current = 1
                else
                    card.ability.extra.current = card.ability.extra.current + 1
                end
            end
    end,
}

SMODS.Joker {
    key = "unionized_labor",
    name = "Unionized Labor",
    rarity = 2,
    cost = 7,
    sprite = "unionized_labor.png",
    negative_sprite = "unionized_labor_negative.png",
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return { vars = { 25, 3, 2 } }
    end,
    loc_txt = { name = "Unionized Labor", text = {"Triples all listed probabilities", "while you have $25 or less", "Halves probabilities otherwise"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.mod_probability then
                if ((G and G.money) or 0) <= 25 then
                    return { numerator = (context.numerator or 0) * 3 }
                end
                return { denominator = (context.denominator or 0) * 2 }
            end
    end,
}

SMODS.Joker {
    key = "park_postcard",
    name = "Park Postcard",
    rarity = 3,
    cost = 8,
    sprite = "park_postcard.png",
    negative_sprite = "park_postcard_negative.png",
    config = { extra = { xm = 1 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return {
            vars = { 0.2, card.ability.extra.xm },
        }
    end,
    loc_txt = { name = "Park Postcard", text = {"Gains +X0.2 Mult at end of round", "Resets when a card is added to", "or removed from your deck", "(Currently X#2# Mult)"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.playing_card_added or context.remove_playing_cards then
                card.ability.extra.xm = 1
            end
            if context.end_of_round then
                card.ability.extra.xm = pb_round2(card.ability.extra.xm + 0.2)
                return { message = "Upgrade!" }
            end
            if context.joker_main and card.ability.extra.xm > 1 then
                return { xmult = card.ability.extra.xm }
            end
    end,
}

SMODS.Joker {
    key = "river",
    name = "River",
    rarity = 2,
    cost = 7,
    sprite = "river.png",
    negative_sprite = "river_negative.png",
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return { vars = { 11 } }
    end,
    loc_txt = { name = "River", text = {"If the played hand contains 5 scoring", "cards, earn half the lowest scoring", "card's Chip value as money", "(Max of $11)"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.before and context.scoring_hand
                and #context.scoring_hand >= 5 then
                local lowest, any_live
                for _, view in ipairs(context.scoring_hand) do
                    local v = pb_chip_value(view)
                    if not lowest or v < lowest then
                        lowest, any_live = v, not view.debuff
                    elseif v == lowest and not view.debuff then
                        any_live = true
                    end
                end
                if lowest and any_live then
                    local give = math.min(math.ceil(lowest / 2), 11)
                    if give > 0 then
                        return { dollars = give, message = "$" .. give }
                    end
                end
            end
    end,
}

SMODS.Joker {
    key = "langely",
    name = "L'angely",
    rarity = 4,
    cost = 20,
    sprite = "langely.png",
    negative_sprite = "langely_negative.png",
    loc_txt = { name = "L'angely", text = {"Earn half the sell value of all", "Jokers when defeating a Big Blind", "Earn the full sell value when", "defeating a Boss Blind"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.end_of_round and G then
                local idx = G.current_blind_index
                if idx == 3 or idx == 2 then
                    local total = 0
                    local list = (G.jokers and G.jokers.cards) or G.jokers or {}
                    for _, j in ipairs(type(list) == "table" and list or {}) do
                        if type(j) == "table" then
                            total = total + (tonumber(j.sell_cost) or 0)
                        end
                    end
                    local give = idx == 3 and total or math.ceil(total / 2)
                    if give > 0 then return { dollars = give } end
                end
            end
    end,
}

--------------------------------------------------------------------------------
-- Suits: Stars (light) and Crowns (dark)
--
-- PC gates the suits' random pool on "the suit is already in the deck, or a
-- Spectrum-family hand has been played this run" (PB_UTIL.has_suit_in_deck /
-- spectrum_played). The fork calls a suit's in_pool(self, game) when building
-- random card fronts, so both facts are derived from the game on demand:
-- hand_play_counts is persisted with the run, and the full-deck count covers
-- cards the player added themselves. Cards also enter through creation and
-- suit conversion at any time; the standard deck stays the four vanilla suits.
--------------------------------------------------------------------------------

local PB_SPECTRUM_HANDS = {
    ["Spectrum"] = true, ["Straight Spectrum"] = true,
    ["Spectrum House"] = true, ["Spectrum Five"] = true,
}

local function pb_spectrum_played(game)
    local list = game and game.handlist
    local counts = game and game.hand_play_counts
    if type(list) ~= "table" or type(counts) ~= "table" then return false end
    for i, name in ipairs(list) do
        if PB_SPECTRUM_HANDS[name] and (tonumber(counts[i]) or 0) > 0 then
            return true
        end
    end
    return false
end

local function pb_suit_in_pool(suit)
    return function(self, game)
        if type(game) ~= "table" or game.handlist == nil then
            game = rawget(_G, "G")
        end
        if not game then return false end
        if pb_spectrum_played(game) then return true end
        if game.count_cards_in_full_deck then
            return game:count_cards_in_full_deck(function(data)
                return data.suit == suit
            end) > 0
        end
        return false
    end
end

if SMODS.Suit then
    if not (SMODS.Suits and SMODS.Suits["Stars"]) then
        SMODS.Suit {
            key = "Stars",
            loc_txt = { name = "Stars" },
            ui_colour = "#dda72c",
            card_key = "STARS",
            in_pool = pb_suit_in_pool("Stars"),
        }
    end
    if not (SMODS.Suits and SMODS.Suits["Crowns"]) then
        SMODS.Suit {
            key = "Crowns",
            loc_txt = { name = "Crowns" },
            ui_colour = "#8b61ad",
            card_key = "CROWNS",
            in_pool = pb_suit_in_pool("Crowns"),
        }
    end
end

--------------------------------------------------------------------------------
-- Poker hands: the Spectrum family
--
-- Values and orders are Paperback's own (identical to Bunco's registrations;
-- if another pack already registered a hand under the same name, the fork
-- would refuse a duplicate, so each registration is skipped when the name is
-- taken -- the hands are interchangeable). A Spectrum is five cards that can
-- be assigned five different suits: Wild cards flex, Stone cards never count
-- (the view's is_suit already excludes them).
--------------------------------------------------------------------------------

local function pb_spectrum(hand)
    if #hand < 5 then return false end
    local remaining = { Spades = 1, Hearts = 1, Clubs = 1, Diamonds = 1 }
    for name in pairs(SMODS.Suits or {}) do remaining[name] = 1 end
    local flex = {}
    for _, view in ipairs(hand) do
        local options = {}
        for suit in pairs(remaining) do
            if view:is_suit(suit) then options[#options + 1] = suit end
        end
        if #options == 0 then
            return false
        elseif #options == 1 then
            if remaining[options[1]] == 0 then return false end
            remaining[options[1]] = 0
        elseif #options < 5 then
            flex[#flex + 1] = options
        end
    end
    local function assign(i)
        if i > #flex then return true end
        for _, suit in ipairs(flex[i]) do
            if remaining[suit] == 1 then
                remaining[suit] = 0
                if assign(i + 1) then return true end
                remaining[suit] = 1
            end
        end
        return false
    end
    return assign(1)
end

local function pb_is_straight(hand)
    local seen, lo, hi = {}, 99, 0
    for _, view in ipairs(hand) do
        local id = view:get_id()
        if seen[id] then return false end
        seen[id] = true
        if id < lo then lo = id end
        if id > hi then hi = id end
    end
    if hi - lo == 4 then return true end
    return seen[14] and seen[5] and seen[4] and seen[3] and seen[2] or false
end

local function pb_rank_groups(hand)
    local counts = {}
    for _, view in ipairs(hand) do
        local id = view:get_id()
        counts[id] = (counts[id] or 0) + 1
    end
    local groups = {}
    for _, n in pairs(counts) do groups[#groups + 1] = n end
    table.sort(groups, function(a, b) return a > b end)
    return groups
end

if SMODS.PokerHand then
    local function pb_register_hand(def)
        if SMODS.PokerHandByName and SMODS.PokerHandByName[def.key] then return end
        SMODS.PokerHand(def)
    end

    pb_register_hand {
        key = "Spectrum",
        loc_txt = { name = "Spectrum", text = { "5 cards with different suits" } },
        chips = 50, mult = 6, l_chips = 20, l_mult = 2,
        order = 55,
        visible = false,
        evaluate = function(self, hand)
            if pb_spectrum(hand) then return true end
            return nil
        end,
    }

    pb_register_hand {
        key = "Straight Spectrum",
        loc_txt = { name = "Straight Spectrum", text = {
            "5 cards in a row (consecutive ranks),",
            "each with a different suit",
        } },
        chips = 120, mult = 10, l_chips = 45, l_mult = 4,
        order = 118,
        visible = false,
        evaluate = function(self, hand)
            if #hand == 5 and pb_spectrum(hand) and pb_is_straight(hand) then
                return true
            end
            return nil
        end,
    }

    pb_register_hand {
        key = "Spectrum House",
        loc_txt = { name = "Spectrum House", text = {
            "A Three of a Kind and a Pair with",
            "each card having a different suit",
        } },
        chips = 150, mult = 15, l_chips = 40, l_mult = 4,
        order = 112,
        visible = false,
        evaluate = function(self, hand)
            if #hand ~= 5 or not pb_spectrum(hand) then return nil end
            local groups = pb_rank_groups(hand)
            if groups[1] == 3 and groups[2] == 2 then return true end
            return nil
        end,
    }

    pb_register_hand {
        key = "Spectrum Five",
        loc_txt = { name = "Spectrum Five", text = {
            "5 cards with the same rank,",
            "each with a different suit",
        } },
        chips = 180, mult = 18, l_chips = 55, l_mult = 3,
        order = 125,
        visible = false,
        evaluate = function(self, hand)
            if #hand ~= 5 or not pb_spectrum(hand) then return nil end
            local groups = pb_rank_groups(hand)
            if groups[1] == 5 then return true end
            return nil
        end,
    }
end

--------------------------------------------------------------------------------
-- Minor Arcana (Paperback consumable set, ported 2026-10-22)
--
-- PC registers this set at shop_rate 0 because the cards arrive through
-- Minor Arcana booster packs; since v1.1.0 the fork registers booster
-- packs, so the packs are registered in the Tier 3 section at the end of
-- this file and the type keeps PC's rate of 0.
--
-- BLOCKED, not ported:
--   * The 11 paperclip arcana (ace_of_cups, ace_of_wands, three_of_cups,
--     four_of_wands, page_of_wands, page_of_cups, six_of_swords,
--     seven_of_swords, seven_of_pentacles, eight_of_swords,
--     nine_of_pentacles): clip state lives on playing-card instances as
--     a second modifier beside the enhancement, with its own calculate
--     contexts; the fork gives a card exactly one center calculate slot
--     family (enhancement / seal) and no card-modifier registry, so a
--     clip has nowhere to live. See the Tier 3 section header.
--   * two_of_swords converts to the last scored suit, which the fork
--     does not track anywhere.
--
-- Ported in the Tier 3 section (v1.1.0): the 8 enhancement-conversion
-- arcana (five_of_cups, five_of_pentacles, nine_of_wands,
-- page_of_pentacles, page_of_swords, queen_of_cups, six_of_wands,
-- three_of_swords), knight_of_wands, seven_of_wands and queen_of_wands.
--
-- Port deviations inside the ported set:
--   * Joker-targeting arcana (nine_of_cups, nine_of_swords,
--     two_of_pentacles, king_of_swords) use the fork's target_joker
--     consumable path since v1.1.0: the player picks the Joker, as on
--     PC. (In v1.0.0 they acted on the leftmost eligible held Joker.)
--   * nine_of_swords cannot ban the destroyed Joker for the rest of the
--     run (no run-ban API); the destroy and the $5 are as on PC.
--   * Random-enhancement rolls (seven_of_cups, five_of_swords) draw from
--     the 8 vanilla enhancements; PC's ranked pool includes Paperback
--     enhancements that do not exist here.
--   * ten_of_wands writes the gained Chips into card_data.chip_bonus,
--     the field the fork's scoring actually reads, in place of PC's
--     ability.perma_bonus.
--   * knight_of_pentacles resets the fork shop's reroll counter
--     (shop_reroll_count) instead of PC's reroll cost fields, and is
--     usable only in the shop, as on PC.
--------------------------------------------------------------------------------

if SMODS.ConsumableType then

if not (SMODS.ConsumableKinds and SMODS.ConsumableKinds["minor_arcana"]) then
    SMODS.ConsumableType {
        key = "minor_arcana",
        loc_txt = { name = "Minor Arcana" },
        shop_rate = 0,
    }
end

local function pba_game() return rawget(_G, "G") end

local function pba_cfg(card)
    return (card and (card.ability or card.config)) or {}
end

local function pba_highlighted()
    local g = pba_game()
    local h = g and g.hand
    if h and type(h.highlighted) == "table" then return h.highlighted end
    return {}
end

local function pba_sync(view)
    if view and view.sync_visual_from_card_data then
        view:sync_visual_from_card_data()
    end
end

local function pba_set_enhancement(view, enh)
    if not view then return end
    if view.set_enhancement then
        view:set_enhancement(enh)
    elseif view.card_data then
        view.card_data.enhancement = enh
    end
    pba_sync(view)
end

local function pba_set_rank(view, rank)
    local d = view and view.card_data
    if not d then return end
    d.rank = rank
    if d.chips ~= nil then
        d.chips = (rank == 14 and 11) or math.min(rank, 10)
    end
    pba_sync(view)
end

local function pba_jokers()
    local g = pba_game()
    if not g then return {} end
    if g.jokers and g.jokers.cards then return g.jokers.cards end
    return g.jokers or {}
end

local function pba_joker_capacity()
    local g = pba_game()
    if not g then return 5 end
    if tonumber(g.joker_capacity) then return g.joker_capacity end
    if g.joker_base_capacity then
        local ok, n = pcall(function() return g:joker_base_capacity() end)
        if ok and tonumber(n) then return n end
    end
    return 5
end

local function pba_first_joker(pred)
    for _, j in ipairs(pba_jokers()) do
        if type(j) == "table" and (not pred or pred(j)) then return j end
    end
    return nil
end

local PBA_ENHANCEMENTS = {
    "bonus", "mult", "wild", "glass", "steel", "stone", "gold", "lucky",
}

local function pba_all_suits()
    local out = { "Spades", "Hearts", "Clubs", "Diamonds" }
    if SMODS.Suits and SMODS.Suits["Stars"] then out[#out + 1] = "Stars" end
    if SMODS.Suits and SMODS.Suits["Crowns"] then out[#out + 1] = "Crowns" end
    return out
end

local function pba_pick(list, seed)
    if #list == 0 then return nil end
    return list[SMODS.pseudorandom(seed, 1, #list)]
end

-- Every card_data in the full deck (deck + discard + hand data), gathered
-- through the game's own counter so the set matches its definition.
local function pba_full_deck_data()
    local g = pba_game()
    local out = {}
    if g and g.count_cards_in_full_deck then
        g:count_cards_in_full_deck(function(d)
            out[#out + 1] = d
            return false
        end)
    end
    return out
end

local function pba_arcana_used_count()
    local g = pba_game()
    local n = 0
    if g and type(g.consumable_usage) == "table" then
        for _, u in pairs(g.consumable_usage) do
            if type(u) == "table"
                and (u.kind == "tarot" or u.kind == "minor_arcana") then
                n = n + 1
            end
        end
    end
    return n
end

local function pba_complete_suits()
    local by = {}
    for _, d in ipairs(pba_full_deck_data()) do
        if d.suit and d.enhancement ~= "stone" and tonumber(d.rank) then
            by[d.suit] = by[d.suit] or {}
            by[d.suit][tonumber(d.rank)] = true
        end
    end
    local n = 0
    for _, set in pairs(by) do
        local ok = true
        for r = 2, 14 do
            if not set[r] then ok = false break end
        end
        if ok then n = n + 1 end
    end
    return n
end

local function pba_face_count()
    local g = pba_game()
    if not g or not g.count_cards_in_full_deck then return 0 end
    return g:count_cards_in_full_deck(function(d)
        local r = tonumber(d.rank)
        return r ~= nil and r >= 11 and r <= 13
            and d.enhancement ~= "stone"
    end)
end

--------------------------------------------------------------------------------
-- Declarative suit conversions
--------------------------------------------------------------------------------

SMODS.Consumable {
    set = "minor_arcana", key = "ace_of_pentacles", cost = 3,
    loc_txt = { name = "Ace of Pentacles", text = {
        "Converts up to", "{C:attention}#1#{} selected cards", "to {C:attention}#2#{}",
    } },
    config = { max_highlighted = 3, suit_conv = "Stars" },
    sprite = "ace_of_pentacles.png",
    negative_sprite = "ace_of_pentacles_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { pba_cfg(card).max_highlighted, "Stars" } }
    end,
}

SMODS.Consumable {
    set = "minor_arcana", key = "ace_of_swords", cost = 3,
    loc_txt = { name = "Ace of Swords", text = {
        "Converts up to", "{C:attention}#1#{} selected cards", "to {C:attention}#2#{}",
    } },
    config = { max_highlighted = 3, suit_conv = "Crowns" },
    sprite = "ace_of_swords.png",
    negative_sprite = "ace_of_swords_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { pba_cfg(card).max_highlighted, "Crowns" } }
    end,
}

--------------------------------------------------------------------------------
-- Cups
--------------------------------------------------------------------------------

SMODS.Consumable {
    set = "minor_arcana", key = "two_of_cups", cost = 3,
    loc_txt = { name = "Two of Cups", text = {
        "Gives a {C:purple}Polychrome{},", "{C:purple}Holographic{}, {C:purple}Foil{},",
        "{C:mult}Rare{} or {C:green}Uncommon{} Tag",
    } },
    sprite = "two_of_cups.png",
    negative_sprite = "two_of_cups_negative.png",
    can_use = function(self, card) return true end,
    use = function(self, card, area, copier)
        local g = pba_game()
        if g and g.addTag then
            g:addTag(pba_pick(
                { "uncommon", "rare", "foil", "holo", "polychrome" },
                "two_of_cups"))
        end
    end,
}

SMODS.Consumable {
    set = "minor_arcana", key = "four_of_cups", cost = 3,
    loc_txt = { name = "Four of Cups", text = {
        "Remove {C:attention}enhancements{}, {C:attention}seals{} and {C:attention}editions{}",
        "from up to {C:attention}#1#{} selected cards.",
        "Earn {C:money}$#2#{} for each one removed",
    } },
    config = { max_highlighted = 3, extra = { money = 5 } },
    sprite = "four_of_cups.png",
    negative_sprite = "four_of_cups_negative.png",
    loc_vars = function(self, info_queue, card)
        local cfg = pba_cfg(card)
        return { vars = { cfg.max_highlighted, (cfg.extra or {}).money } }
    end,
    use = function(self, card, area, copier)
        local money = (pba_cfg(card).extra or {}).money or 5
        local total = 0
        for _, view in ipairs(pba_highlighted()) do
            local d = view.card_data
            if d then
                if d.enhancement then total = total + money pba_set_enhancement(view, nil) end
                if d.seal then total = total + money d.seal = nil end
                if d.edition then total = total + money d.edition = nil end
                pba_sync(view)
            end
        end
        if total > 0 then ease_dollars(total) end
    end,
}

SMODS.Consumable {
    set = "minor_arcana", key = "seven_of_cups", cost = 3,
    loc_txt = { name = "Seven of Cups", text = {
        "Give a random {C:attention}enhancement",
        "to up to {C:attention}#1#{} selected cards",
    } },
    config = { max_highlighted = 2 },
    sprite = "seven_of_cups.png",
    negative_sprite = "seven_of_cups_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { pba_cfg(card).max_highlighted } }
    end,
    use = function(self, card, area, copier)
        for _, view in ipairs(pba_highlighted()) do
            pba_set_enhancement(view, pba_pick(PBA_ENHANCEMENTS, "seven_of_cups"))
        end
    end,
}

SMODS.Consumable {
    set = "minor_arcana", key = "eight_of_cups", cost = 3,
    loc_txt = { name = "Eight of Cups", text = {
        "Converts up to {C:attention}#1#{} selected",
        "cards into a suit that is", "not {C:attention}currently selected",
    } },
    config = { max_highlighted = 4 },
    sprite = "eight_of_cups.png",
    negative_sprite = "eight_of_cups_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { pba_cfg(card).max_highlighted } }
    end,
    use = function(self, card, area, copier)
        local hl = pba_highlighted()
        local highlighted_suits, unique = {}, 0
        for _, view in ipairs(hl) do
            local d = view.card_data
            if d and d.suit and d.enhancement ~= "stone"
                and not highlighted_suits[d.suit] then
                highlighted_suits[d.suit] = true
                unique = unique + 1
            end
        end
        local pool = {}
        if unique >= (pba_cfg(card).max_highlighted or 4) then
            for _, s in ipairs(pba_all_suits()) do pool[s] = true end
        else
            local g = pba_game()
            for _, s in ipairs(pba_all_suits()) do
                if g and g.count_cards_in_full_deck
                    and g:count_cards_in_full_deck(function(d)
                        return d.suit == s and d.enhancement ~= "stone"
                    end) > 0 then
                    pool[s] = true
                end
            end
        end
        for s in pairs(highlighted_suits) do pool[s] = nil end
        local choices = {}
        for s in pairs(pool) do choices[#choices + 1] = s end
        local suit = pba_pick(choices, "eight_of_cups")
        if suit then
            for _, view in ipairs(hl) do
                local d = view.card_data
                if d then d.suit = suit pba_sync(view) end
            end
        end
    end,
}

SMODS.Consumable {
    set = "minor_arcana", key = "nine_of_cups", cost = 3,
    loc_txt = { name = "Nine of Cups", text = {
        "Destroy selected {C:attention}Joker{} and",
        "create a new {C:attention}Joker{} of higher",
        "{C:attention}rarity{} if possible, otherwise",
        "create one of equal rarity",
        "{C:inactive}(Cannot upgrade to {C:legendary}Legendary{C:inactive})",
    } },
    config = { extra = { max_jokers = 1 } },
    target_joker = true,
    sprite = "nine_of_cups.png",
    negative_sprite = "nine_of_cups_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { (pba_cfg(card).extra or {}).max_jokers } }
    end,
    can_use = function(self, card, target)
        return target ~= nil and not target.eternal
    end,
    use = function(self, card, area, copier, target)
        local g = pba_game()
        if not target or not g then return end
        local rarity = 1
        local def = target.def and JOKER_DEFS and JOKER_DEFS[target.def.id]
        rarity = tonumber((def and def.rarity) or target.rarity) or 1
        local edition = target.edition
        if edition ~= "foil" and edition ~= "holo"
            and edition ~= "polychrome" and edition ~= "negative" then
            edition = nil
        end
        local new_rarity = rarity < 3 and (rarity + 1) or rarity
        -- PC rarity override: OFF Switch counts as Rare for this card.
        if target.def and target.def.id == "j_pbp_off_switch" then
            new_rarity = 3
        end
        SMODS.destroy_joker(target)
        local id = g.random_joker_def_id_by_rarity
            and g:random_joker_def_id_by_rarity(new_rarity, "nine_of_cups")
        if id then
            SMODS.add_card { set = "Joker", key = id, edition = edition }
        end
    end,
}

SMODS.Consumable {
    set = "minor_arcana", key = "ten_of_cups", cost = 3,
    loc_txt = { name = "Ten of Cups", text = {
        "{C:green}#1# in #2#{} chance to add",
        "{C:purple}Polychrome{} edition to",
        "{C:attention}1{} selected card",
    } },
    config = { max_highlighted = 1, extra = { odds = 3 } },
    sprite = "ten_of_cups.png",
    negative_sprite = "ten_of_cups_negative.png",
    loc_vars = function(self, info_queue, card)
        local num, den = 1, (pba_cfg(card).extra or {}).odds or 3
        if SMODS.get_probability_vars then
            num, den = SMODS.get_probability_vars(card, num, den,
                "paperback_ten_of_cups")
        end
        return { vars = { num, den } }
    end,
    can_use = function(self, card)
        local hl = pba_highlighted()
        return #hl == 1 and hl[1].card_data ~= nil
            and hl[1].card_data.edition == nil
    end,
    use = function(self, card, area, copier)
        local hl = pba_highlighted()
        local view = hl[1]
        if not view or not view.card_data then return end
        local odds = (pba_cfg(card).extra or {}).odds or 3
        if SMODS.pseudorandom_probability(card, "ten_of_cups", 1, odds,
            "paperback_ten_of_cups") then
            view.card_data.edition = "polychrome"
            pba_sync(view)
        end
    end,
}

SMODS.Consumable {
    set = "minor_arcana", key = "knight_of_cups", cost = 3,
    loc_txt = { name = "Knight of Cups", text = {
        "Select {C:attention}#1#{} cards, the {C:attention}left{} card",
        "copies {C:attention}everything{} from the {C:attention}right",
        "card except {C:attention}rank{} and {C:attention}suit",
        "Destroys the {C:attention}right{} card",
    } },
    config = { min_highlighted = 2, max_highlighted = 2 },
    sprite = "knight_of_cups.png",
    negative_sprite = "knight_of_cups_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { pba_cfg(card).min_highlighted } }
    end,
    use = function(self, card, area, copier)
        local hl = pba_highlighted()
        local left, right = hl[1], hl[2]
        if not left or not right then return end
        local ld, rd = left.card_data, right.card_data
        if not ld or not rd then return end
        for _, f in ipairs({ "enhancement", "seal", "edition",
            "chip_bonus", "chips_bonus", "mult_bonus" }) do
            ld[f] = rd[f]
        end
        pba_sync(left)
        SMODS.destroy_card(right)
    end,
}

SMODS.Consumable {
    set = "minor_arcana", key = "king_of_cups", cost = 3,
    loc_txt = { name = "King of Cups", text = {
        "Earn {C:money}$#1#{} for each suit with all",
        "13 {C:attention}base ranks{} that you have",
        "{C:inactive}(Currently {C:money}$#2#{C:inactive})",
    } },
    config = { extra = { money = 5 } },
    sprite = "king_of_cups.png",
    negative_sprite = "king_of_cups_negative.png",
    loc_vars = function(self, info_queue, card)
        local money = (pba_cfg(card).extra or {}).money or 5
        return { vars = { money, pba_complete_suits() * money } }
    end,
    can_use = function(self, card) return true end,
    use = function(self, card, area, copier)
        local money = (pba_cfg(card).extra or {}).money or 5
        local amount = pba_complete_suits() * money
        if amount > 0 then ease_dollars(amount) end
    end,
}

--------------------------------------------------------------------------------
-- Wands
--------------------------------------------------------------------------------

SMODS.Consumable {
    set = "minor_arcana", key = "two_of_wands", cost = 3,
    loc_txt = { name = "Two of Wands", text = {
        "Create the {C:attention}Planet{} card",
        "for your {C:attention}most{} and {C:attention}least",
        "played {C:attention}poker hands",
        "{C:inactive}(Must have room)",
    } },
    sprite = "two_of_wands.png",
    negative_sprite = "two_of_wands_negative.png",
    can_use = function(self, card) return true end,
    use = function(self, card, area, copier)
        local g = pba_game()
        if not g or not g.handlist or not g.random_planet_id_for_hand_name then
            return
        end
        local counts = g.hand_play_counts or {}
        local candidates = {}
        for i, name in ipairs(g.handlist) do
            local id = g:random_planet_id_for_hand_name(name, "two_of_wands")
            if id then
                candidates[#candidates + 1] = {
                    id = id, count = tonumber(counts[i]) or 0, order = i,
                }
            end
        end
        if #candidates == 0 then return end
        table.sort(candidates, function(a, b)
            if a.count ~= b.count then return a.count > b.count end
            return a.order < b.order
        end)
        SMODS.add_card { set = "Planet", key = candidates[1].id }
        if #candidates > 1 then
            SMODS.add_card { set = "Planet", key = candidates[#candidates].id }
        end
    end,
}

SMODS.Consumable {
    set = "minor_arcana", key = "three_of_wands", cost = 3,
    loc_txt = { name = "Three of Wands", text = {
        "Create a copy of {C:attention}#1#",
        "selected card in", "your hand",
    } },
    config = { max_highlighted = 1 },
    sprite = "three_of_wands.png",
    negative_sprite = "three_of_wands_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { pba_cfg(card).max_highlighted } }
    end,
    use = function(self, card, area, copier)
        local view = pba_highlighted()[1]
        local d = view and view.card_data
        if not d then return end
        SMODS.add_card {
            set = "Playing", rank = d.rank, suit = d.suit,
            enhancement = d.enhancement, seal = d.seal, edition = d.edition,
        }
    end,
}

SMODS.Consumable {
    set = "minor_arcana", key = "five_of_wands", cost = 3,
    loc_txt = { name = "Five of Wands", text = {
        "Destroys all cards", "{C:attention}held in hand{}, and",
        "sets money to {C:money}$0",
    } },
    sprite = "five_of_wands.png",
    negative_sprite = "five_of_wands_negative.png",
    can_use = function(self, card)
        local g = pba_game()
        local h = g and g.hand
        return h ~= nil and type(h.card_nodes) == "table"
            and #h.card_nodes > 0
    end,
    use = function(self, card, area, copier)
        local g = pba_game()
        local h = g and g.hand
        if not h or type(h.card_nodes) ~= "table" then return end
        local nodes = {}
        for _, n in ipairs(h.card_nodes) do nodes[#nodes + 1] = n end
        for _, n in ipairs(nodes) do SMODS.destroy_card(n) end
        if g and (tonumber(g.money) or 0) ~= 0 then
            ease_dollars(-g.money)
        end
    end,
}

SMODS.Consumable {
    set = "minor_arcana", key = "eight_of_wands", cost = 3,
    loc_txt = { name = "Eight of Wands", text = {
        "Create a {C:purple}Negative {C:attention}Tag{} and",
        "lose {C:money}$#1#{}, plus {C:money}$#2#{} for every",
        "Joker over {C:attention}#3#{} owned",
        "{C:inactive}(Currently {C:money}$#4#{C:inactive})",
    } },
    config = { base_cost = 15, cost_per_joker = 5 },
    sprite = "eight_of_wands.png",
    negative_sprite = "eight_of_wands_negative.png",
    loc_vars = function(self, info_queue, card)
        local cfg = pba_cfg(card)
        local base = cfg.base_cost or 15
        local per = cfg.cost_per_joker or 5
        local slots = pba_joker_capacity()
        local over = math.max(0, #pba_jokers() - slots)
        return { vars = { base, per, slots, base + per * over } }
    end,
    can_use = function(self, card) return true end,
    use = function(self, card, area, copier)
        local g = pba_game()
        local cfg = pba_cfg(card)
        local base = cfg.base_cost or 15
        local per = cfg.cost_per_joker or 5
        local over = math.max(0, #pba_jokers() - pba_joker_capacity())
        if g and g.addTag then g:addTag("negative") end
        ease_dollars(-(base + per * over))
    end,
}

SMODS.Consumable {
    set = "minor_arcana", key = "ten_of_wands", cost = 3,
    loc_txt = { name = "Ten of Wands", text = {
        "Select {C:attention}#1#{} cards, destroy the",
        "{C:attention}rightmost two{} and give their",
        "{C:chips}Chip value{} to the {C:attention}leftmost",
        "{C:inactive}(Drag to rearrange)",
    } },
    config = { min_highlighted = 3, max_highlighted = 3 },
    sprite = "ten_of_wands.png",
    negative_sprite = "ten_of_wands_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { pba_cfg(card).max_highlighted } }
    end,
    use = function(self, card, area, copier)
        local hl = pba_highlighted()
        local left, mid, right = hl[1], hl[2], hl[3]
        if not left or not mid or not right then return end
        local increase = pb_chip_value(mid) + pb_chip_value(right)
        local d = left.card_data
        if d then
            d.chip_bonus = (tonumber(d.chip_bonus) or 0) + increase
            pba_sync(left)
        end
        SMODS.destroy_card(right)
        SMODS.destroy_card(mid)
    end,
}

SMODS.Consumable {
    set = "minor_arcana", key = "king_of_wands", cost = 3,
    loc_txt = { name = "King of Wands", text = {
        "Creates a random", "non-{C:chips}Common{C:attention} Joker",
        "{C:inactive}(Except Legendary)",
    } },
    sprite = "king_of_wands.png",
    negative_sprite = "king_of_wands_negative.png",
    can_use = function(self, card)
        return #pba_jokers() < pba_joker_capacity()
    end,
    use = function(self, card, area, copier)
        local g = pba_game()
        if not g or not g.random_joker_def_id_by_rarity then return end
        local rarity = SMODS.pseudorandom("king_of_wands", 2, 3)
        local id = g:random_joker_def_id_by_rarity(rarity, "king_of_wands")
        if id then SMODS.add_card { set = "Joker", key = id } end
    end,
}

--------------------------------------------------------------------------------
-- Swords
--------------------------------------------------------------------------------

SMODS.Consumable {
    set = "minor_arcana", key = "four_of_swords", cost = 3,
    loc_txt = { name = "Four of Swords", text = {
        "Converts up to {C:attention}#1#",
        "selected cards to", "random {C:attention}Face{} cards",
    } },
    config = { max_highlighted = 2 },
    sprite = "four_of_swords.png",
    negative_sprite = "four_of_swords_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { pba_cfg(card).max_highlighted } }
    end,
    use = function(self, card, area, copier)
        for _, view in ipairs(pba_highlighted()) do
            pba_set_rank(view, pba_pick({ 11, 12, 13 }, "four_of_swords"))
        end
    end,
}

SMODS.Consumable {
    set = "minor_arcana", key = "five_of_swords", cost = 3,
    loc_txt = { name = "Five of Swords", text = {
        "Give a random {C:attention}edition{},",
        "{C:attention}seal{} or {C:attention}enhancement",
        "to {C:attention}#1#{} selected card",
    } },
    config = { max_highlighted = 1 },
    sprite = "five_of_swords.png",
    negative_sprite = "five_of_swords_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { pba_cfg(card).max_highlighted } }
    end,
    use = function(self, card, area, copier)
        local view = pba_highlighted()[1]
        local d = view and view.card_data
        if not d then return end
        local missing = {}
        if not d.seal then missing[#missing + 1] = "seal" end
        if not d.edition then missing[#missing + 1] = "edition" end
        if not d.enhancement then missing[#missing + 1] = "enhancement" end
        local modifier = pba_pick(
            #missing > 0 and missing
                or { "seal", "edition", "enhancement" },
            "five_of_swords")
        if modifier == "seal" then
            d.seal = pba_pick({ "gold", "red", "blue", "purple" },
                "five_of_swords_seal")
            pba_sync(view)
        elseif modifier == "edition" then
            d.edition = pba_pick({ "foil", "holo", "polychrome" },
                "five_of_swords_edition")
            pba_sync(view)
        else
            pba_set_enhancement(view,
                pba_pick(PBA_ENHANCEMENTS, "five_of_swords_enhancement"))
        end
    end,
}

SMODS.Consumable {
    set = "minor_arcana", key = "nine_of_swords", cost = 3,
    loc_txt = { name = "Nine of Swords", text = {
        "Destroy selected Joker and earn {C:money}$#2#{}",
        "{C:inactive}(Can destroy Eternals)",
    } },
    config = { extra = { max_jokers = 1, money = 5 } },
    target_joker = true,
    sprite = "nine_of_swords.png",
    negative_sprite = "nine_of_swords_negative.png",
    loc_vars = function(self, info_queue, card)
        local extra = pba_cfg(card).extra or {}
        return { vars = { extra.max_jokers, extra.money } }
    end,
    can_use = function(self, card, target)
        return target ~= nil
    end,
    use = function(self, card, area, copier, target)
        if not target then return end
        if SMODS.destroy_joker(target) then
            ease_dollars((pba_cfg(card).extra or {}).money or 5)
        end
    end,
}

SMODS.Consumable {
    set = "minor_arcana", key = "ten_of_swords", cost = 3,
    loc_txt = { name = "Ten of Swords", text = {
        "{C:attention}Destroy{} all cards in full deck",
        "with the same {C:attention}rank{} as selected card",
    } },
    config = { max_highlighted = 1 },
    sprite = "ten_of_swords.png",
    negative_sprite = "ten_of_swords_negative.png",
    use = function(self, card, area, copier)
        local view = pba_highlighted()[1]
        local d = view and view.card_data
        if not d then return end
        local no_rank = d.enhancement == "stone"
        local rank = tonumber(d.rank)
        local function matches(data)
            if no_rank then return data.enhancement == "stone" end
            return data.enhancement ~= "stone"
                and tonumber(data.rank) == rank
        end
        local g = pba_game()
        local hand_targets = {}
        if g and g.hand and type(g.hand.card_nodes) == "table" then
            for _, node in ipairs(g.hand.card_nodes) do
                if node.card_data and matches(node.card_data) then
                    hand_targets[#hand_targets + 1] = node
                end
            end
        end
        local deck_targets = {}
        for _, data in ipairs(pba_full_deck_data()) do
            if matches(data) then deck_targets[#deck_targets + 1] = data end
        end
        for _, node in ipairs(hand_targets) do SMODS.destroy_card(node) end
        for _, data in ipairs(deck_targets) do SMODS.destroy_card(data) end
    end,
}

SMODS.Consumable {
    set = "minor_arcana", key = "knight_of_swords", cost = 3,
    loc_txt = { name = "Knight of Swords", text = {
        "Create a random {C:purple}Minor Arcana{} card",
        "and a random {C:purple}Tarot{} card",
        "{C:inactive}(Must have room)",
    } },
    sprite = "knight_of_swords.png",
    negative_sprite = "knight_of_swords_negative.png",
    can_use = function(self, card) return true end,
    use = function(self, card, area, copier)
        local g = pba_game()
        local pool = {}
        for id, def in pairs(CONSUMABLE_DEFS or {}) do
            if type(def) == "table" and def.kind == "minor_arcana" then
                pool[#pool + 1] = id
            end
        end
        local arcana = pba_pick(pool, "knight_of_swords")
        if arcana then
            SMODS.add_card { set = "minor_arcana", key = arcana }
        end
        local tarot = nil
        if g and g.random_non_fool_tarot_id then
            tarot = g:random_non_fool_tarot_id("knight_of_swords")
        elseif g and g.random_consumable_id_of_kind then
            tarot = g:random_consumable_id_of_kind("tarot", nil,
                "knight_of_swords")
        end
        if tarot then SMODS.add_card { set = "Tarot", key = tarot } end
    end,
}

SMODS.Consumable {
    set = "minor_arcana", key = "queen_of_swords", cost = 3,
    loc_txt = { name = "Queen of Swords", text = {
        "Converts {C:attention}#1#{} random cards in",
        "full deck with {C:attention}different suits",
        "to the selected card's {C:attention}suit",
    } },
    config = { max_highlighted = 1, targets = 3 },
    sprite = "queen_of_swords.png",
    negative_sprite = "queen_of_swords_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { pba_cfg(card).targets } }
    end,
    can_use = function(self, card)
        local hl = pba_highlighted()
        return #hl == 1 and hl[1].card_data ~= nil
            and hl[1].card_data.suit ~= nil
            and hl[1].card_data.enhancement ~= "stone"
    end,
    use = function(self, card, area, copier)
        local view = pba_highlighted()[1]
        local ref = view and view.card_data and view.card_data.suit
        if not ref then return end
        local limit = pba_cfg(card).targets or 3
        local possible = {}
        for _, data in ipairs(pba_full_deck_data()) do
            if data.suit and data.suit ~= ref
                and data.enhancement ~= "stone" then
                possible[#possible + 1] = data
            end
        end
        local chosen_suits = {}
        local targets = {}
        while #targets < limit and #possible > 0 do
            local idx = SMODS.pseudorandom("queen_of_swords", 1, #possible)
            local target = table.remove(possible, idx)
            targets[#targets + 1] = target
            chosen_suits[target.suit] = true
            for i = #possible, 1, -1 do
                if chosen_suits[possible[i].suit] then
                    table.remove(possible, i)
                end
            end
        end
        for _, data in ipairs(targets) do data.suit = ref end
    end,
}

SMODS.Consumable {
    set = "minor_arcana", key = "king_of_swords", cost = 3,
    loc_txt = { name = "King of Swords", text = {
        "Remove {C:money}Rental{} and {C:purple}Perishable",
        "from selected Joker",
    } },
    target_joker = true,
    sprite = "king_of_swords.png",
    negative_sprite = "king_of_swords_negative.png",
    can_use = function(self, card, target)
        return target ~= nil
            and (target.rental or target.perishable) and true or false
    end,
    use = function(self, card, area, copier, target)
        local j = target
        if not j then return end
        j.rental = nil
        j.perishable = nil
        j.perishable_counter = nil
    end,
}

--------------------------------------------------------------------------------
-- Pentacles
--------------------------------------------------------------------------------

SMODS.Consumable {
    set = "minor_arcana", key = "two_of_pentacles", cost = 3,
    loc_txt = { name = "Two of Pentacles", text = {
        "Selected Joker gains",
        "or loses {C:purple}Eternal{}",
    } },
    target_joker = true,
    sprite = "two_of_pentacles.png",
    negative_sprite = "two_of_pentacles_negative.png",
    can_use = function(self, card, target)
        return target ~= nil
    end,
    use = function(self, card, area, copier, target)
        local j = target
        if not j then return end
        if j.eternal then
            j.eternal = false
        else
            j.perishable = nil
            j.perishable_counter = nil
            j.eternal = true
        end
    end,
}

SMODS.Consumable {
    set = "minor_arcana", key = "three_of_pentacles", cost = 3,
    loc_txt = { name = "Three of Pentacles", text = {
        "Select {C:attention}#1#{} cards, the",
        "{C:attention}leftmost two{} copy the",
        "{C:attention}rightmost{} card's {C:attention}enhancement{}",
    } },
    config = { min_highlighted = 3, max_highlighted = 3 },
    sprite = "three_of_pentacles.png",
    negative_sprite = "three_of_pentacles_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { pba_cfg(card).max_highlighted } }
    end,
    use = function(self, card, area, copier)
        local hl = pba_highlighted()
        local source = hl[#hl]
        if not source or not source.card_data then return end
        local enh = source.card_data.enhancement
        for i = 1, #hl - 1 do
            pba_set_enhancement(hl[i], enh)
        end
    end,
}

SMODS.Consumable {
    set = "minor_arcana", key = "four_of_pentacles", cost = 3,
    loc_txt = { name = "Four of Pentacles", text = {
        "Select {C:attention}#1#{} cards.",
        "{C:green}#2# in #3#{} chance to",
        "destroy each {C:attention}unselected{}",
        "card in hand",
    } },
    config = {
        min_highlighted = 4, max_highlighted = 4,
        extra = { numerator = 1, denominator = 2 },
    },
    sprite = "four_of_pentacles.png",
    negative_sprite = "four_of_pentacles_negative.png",
    loc_vars = function(self, info_queue, card)
        local extra = pba_cfg(card).extra or {}
        local num = extra.numerator or 1
        local den = extra.denominator or 2
        if SMODS.get_probability_vars then
            num, den = SMODS.get_probability_vars(card, num, den,
                "paperback_four_of_pentacles")
        end
        return { vars = { pba_cfg(card).max_highlighted, num, den } }
    end,
    use = function(self, card, area, copier)
        local g = pba_game()
        local h = g and g.hand
        if not h or type(h.card_nodes) ~= "table" then return end
        local selected = {}
        for _, view in ipairs(pba_highlighted()) do selected[view] = true end
        local extra = pba_cfg(card).extra or {}
        local targets = {}
        for _, node in ipairs(h.card_nodes) do
            if not selected[node]
                and SMODS.pseudorandom_probability(card,
                    "four_of_pentacles",
                    extra.numerator or 1, extra.denominator or 2,
                    "paperback_four_of_pentacles") then
                targets[#targets + 1] = node
            end
        end
        for _, node in ipairs(targets) do SMODS.destroy_card(node) end
    end,
}

SMODS.Consumable {
    set = "minor_arcana", key = "six_of_cups", cost = 3,
    loc_txt = { name = "Six of Cups", text = {
        "Earn {C:attention}half{} the {C:chips}Chip",
        "{C:chips}value{} of {C:attention}#1#{} selected",
        "card as {C:money}money",
        "{C:inactive}(Max of {C:money}$#2#{C:inactive})",
    } },
    config = { max_highlighted = 1, money_cap = 30 },
    sprite = "six_of_cups.png",
    negative_sprite = "six_of_cups_negative.png",
    loc_vars = function(self, info_queue, card)
        local cfg = pba_cfg(card)
        return { vars = { cfg.max_highlighted, cfg.money_cap } }
    end,
    use = function(self, card, area, copier)
        local view = pba_highlighted()[1]
        if not view then return end
        local money = math.ceil(pb_chip_value(view) / 2)
        local cap = pba_cfg(card).money_cap or 30
        if money > 0 then ease_dollars(math.min(cap, money)) end
    end,
}

SMODS.Consumable {
    set = "minor_arcana", key = "six_of_pentacles", cost = 3,
    loc_txt = { name = "Six of Pentacles", text = {
        "Gives an {C:money}Investment{},",
        "{C:money}Economy{}, {C:red}Coupon{},",
        "{C:green}D6{}, or {C:attention}Juggle Tag{}",
    } },
    sprite = "six_of_pentacles.png",
    negative_sprite = "six_of_pentacles_negative.png",
    can_use = function(self, card) return true end,
    use = function(self, card, area, copier)
        local g = pba_game()
        if g and g.addTag then
            g:addTag(pba_pick(
                { "investment", "economy", "coupon", "d_six", "juggle" },
                "six_of_pentacles"))
        end
    end,
}

SMODS.Consumable {
    set = "minor_arcana", key = "eight_of_pentacles", cost = 3,
    loc_txt = { name = "Eight of Pentacles", text = {
        "Earn {C:money}$#1#{} for every unique",
        "{C:purple}Tarot{} and {C:purple}Minor Arcana{}",
        "card used this run",
        "{C:inactive}(Currently {C:money}$#2#{C:inactive})",
    } },
    config = { extra = { money = 1 } },
    sprite = "eight_of_pentacles.png",
    negative_sprite = "eight_of_pentacles_negative.png",
    loc_vars = function(self, info_queue, card)
        local money = (pba_cfg(card).extra or {}).money or 1
        return { vars = { money, pba_arcana_used_count() * money } }
    end,
    can_use = function(self, card) return true end,
    use = function(self, card, area, copier)
        local money = (pba_cfg(card).extra or {}).money or 1
        local amount = pba_arcana_used_count() * money
        if amount > 0 then ease_dollars(amount) end
    end,
}

SMODS.Consumable {
    set = "minor_arcana", key = "ten_of_pentacles", cost = 3,
    loc_txt = { name = "Ten of Pentacles", text = {
        "Earn between {C:money}$#1#{} and {C:money}$#2#{}",
    } },
    config = { extra = { min = 5, max = 10 } },
    sprite = "ten_of_pentacles.png",
    negative_sprite = "ten_of_pentacles_negative.png",
    loc_vars = function(self, info_queue, card)
        local extra = pba_cfg(card).extra or {}
        return { vars = { extra.min, extra.max } }
    end,
    can_use = function(self, card) return true end,
    use = function(self, card, area, copier)
        local extra = pba_cfg(card).extra or {}
        ease_dollars(SMODS.pseudorandom("ten_of_pentacles",
            extra.min or 5, extra.max or 10))
    end,
}

SMODS.Consumable {
    set = "minor_arcana", key = "queen_of_pentacles", cost = 3,
    loc_txt = { name = "Queen of Pentacles", text = {
        "Select {C:attention}#1#{} cards.",
        "Copy the {C:attention}right{} card's",
        "{C:attention}rank{} onto the {C:attention}left{} card",
    } },
    config = { min_highlighted = 2, max_highlighted = 2 },
    sprite = "queen_of_pentacles.png",
    negative_sprite = "queen_of_pentacles_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { pba_cfg(card).max_highlighted } }
    end,
    can_use = function(self, card)
        local hl = pba_highlighted()
        if #hl < 2 then return false end
        local source = hl[#hl]
        return source.card_data ~= nil
            and source.card_data.enhancement ~= "stone"
    end,
    use = function(self, card, area, copier)
        local hl = pba_highlighted()
        local source = hl[#hl]
        if not source or not source.card_data then return end
        local rank = source.card_data.rank
        for i = 1, #hl - 1 do
            pba_set_rank(hl[i], rank)
        end
    end,
}

SMODS.Consumable {
    set = "minor_arcana", key = "knight_of_pentacles", cost = 3,
    loc_txt = { name = "Knight of Pentacles", text = {
        "Reset {C:green}Reroll{} cost to {C:money}$#1#{}",
        "{C:inactive}(Currently {C:money}$#2#{C:inactive})",
    } },
    sprite = "knight_of_pentacles.png",
    negative_sprite = "knight_of_pentacles_negative.png",
    loc_vars = function(self, info_queue, card)
        local g = pba_game()
        local base = 5
        local current = base
        if g then
            base = tonumber(g.shop_reroll_base_cost) or 5
            if g.shop_current_reroll_cost then
                local ok, n = pcall(function()
                    return g:shop_current_reroll_cost()
                end)
                if ok and tonumber(n) then current = n end
            end
        end
        return { vars = { base, current } }
    end,
    can_use = function(self, card)
        local g = pba_game()
        return g ~= nil and g.STATES ~= nil and g.STATE == g.STATES.SHOP
    end,
    use = function(self, card, area, copier)
        local g = pba_game()
        if not g then return end
        g.shop_reroll_count = 0
        g.shop_free_rerolls_used = 0
    end,
}

SMODS.Consumable {
    set = "minor_arcana", key = "king_of_pentacles", cost = 3,
    loc_txt = { name = "King of Pentacles", text = {
        "Earn {C:money}$#1#{} for each {C:attention}face",
        "card in your full deck",
        "{C:inactive}(Currently {C:money}$#2#{C:inactive})",
    } },
    config = { extra = { money = 1 } },
    sprite = "king_of_pentacles.png",
    negative_sprite = "king_of_pentacles_negative.png",
    loc_vars = function(self, info_queue, card)
        local money = (pba_cfg(card).extra or {}).money or 1
        return { vars = { money, pba_face_count() * money } }
    end,
    can_use = function(self, card) return true end,
    use = function(self, card, area, copier)
        local money = (pba_cfg(card).extra or {}).money or 1
        local amount = pba_face_count() * money
        if amount > 0 then ease_dollars(amount) end
    end,
}

end

--------------------------------------------------------------------------------
-- Tag Jokers (re-audit: the fork does have a tag API after all)
-- Ported from Paperback's MIT-licensed sources against the fork API.
-- Sub-effect deviations are marked with PORT NOTE comments inline.
--------------------------------------------------------------------------------
do
-- pb_frag_0: three Jokers the re-audit had classed BLOCKED-OTHER-tag on the
-- assumption the fork has no tag API. It does: G:addTag("negative") grants
-- the vanilla Negative Tag (BuncoPack's Zero Shapiro uses G:addTag("d6")).
-- All three create only that vanilla tag, so all three port.

-- 56_leaf_clover
SMODS.Joker {
    key = "56_leaf_clover",
    name = "56 Leaf Clover",
    rarity = 2,
    cost = 6,
    sprite = "56_leaf_clover.png",
    negative_sprite = "56_leaf_clover_negative.png",
    config = { extra = { active = false } },
    loc_txt = { name = "56 Leaf Clover", text = {"If the winning hand of a Boss", "Blind scores only Clubs,", "create a Negative Tag"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.before and context.scoring_hand then
            local active = true
            for _, view in ipairs(context.scoring_hand) do
                if not (view.is_suit and view:is_suit("Clubs")) then
                    active = false
                    break
                end
            end
            card.ability.extra.active = active
        end
        if context.end_of_round and not context.game_over
                and card.ability.extra.active
                and G and tonumber(G.current_blind_index) == 3 then
            if G.addTag then G:addTag("negative") end
            return { message = "+Tag!" }
        end
    end,
}

-- ghost_cola
SMODS.Joker {
    key = "ghost_cola",
    name = "Ghost Cola",
    rarity = 2,
    cost = 6,
    sprite = "ghost_cola.png",
    negative_sprite = "ghost_cola_negative.png",
    loc_txt = { name = "Ghost Cola", text = {"Sell this card to create a", "Negative Tag and a random", "Spectral card", "(Must have room)"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.selling_card then
            -- PORT NOTE: PC's Diet-Cola-sold spawn/unlock hook is part of
            -- Paperback's unlock system, which the port does not implement;
            -- Ghost Cola is a normal shop Joker here, as on a fresh PC
            -- install once unlocked.
            if G and G.addTag then G:addTag("negative") end
            if G and G.can_add_consumable and G:can_add_consumable()
                    and G.random_consumable_id_of_kind then
                local id = G:random_consumable_id_of_kind("spectral")
                if id and G.add_consumable then G:add_consumable(id) end
            end
            return { message = "+Tag!" }
        end
    end,
}

-- shadowmantle
SMODS.Joker {
    key = "shadowmantle",
    name = "ShadowMantle",
    rarity = 3,
    cost = 8,
    sprite = "shadowmantle.png",
    negative_sprite = "shadowmantle_negative.png",
    config = { extra = { odds = 15, active = true } },
    -- PC pool gate: only appears once a Stars card is in the full deck.
    in_pool = function(self, game)
        if type(game) ~= "table" or game.handlist == nil then game = G end
        if not game or not game.count_cards_in_full_deck then return true end
        local ok, n = pcall(function()
            return game:count_cards_in_full_deck(function(c)
                return c and c.suit == "Stars" and c.enhancement ~= "stone"
            end)
        end)
        if not ok then return true end
        return (tonumber(n) or 0) > 0
    end,
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        local num, den = 1, (card.ability.extra and card.ability.extra.odds) or 15
        if SMODS.get_probability_vars then
            num, den = SMODS.get_probability_vars(card, num, den,
                "paperback_shadowmantle")
        end
        return { vars = { "Stars", num, den } }
    end,
    loc_txt = { name = "ShadowMantle", text = {"Scored #1# have a #2# in #3#", "chance to create a", "Negative Tag", "(Once per round)"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.individual and context.cardarea == G.play
                and card.ability.extra.active and context.other_card
                and context.other_card.is_suit
                and context.other_card:is_suit("Stars") then
            if SMODS.pseudorandom_probability
                    and SMODS.pseudorandom_probability(card, "shadowmantle",
                        1, card.ability.extra.odds or 15,
                        "paperback_shadowmantle") then
                card.ability.extra.active = false
                if G and G.addTag then G:addTag("negative") end
                return { message = "+Tag!" }
            end
        end
        if context.end_of_round then
            card.ability.extra.active = true
        end
    end,
}
end

--------------------------------------------------------------------------------
-- Expansion Jokers, slice 1 (a_balatro_movie .. double_dutchman)
-- Ported from Paperback's MIT-licensed sources against the fork API.
-- Sub-effect deviations are marked with PORT NOTE comments inline.
--------------------------------------------------------------------------------
do
-- PaperbackPack fragment 1 of 4: 45 Paperback Jokers (a_balatro_movie ..
-- double_dutchman) ported to the Balatro3DS fork mod API. Loads after the
-- main pack file; references SMODS and G only. Helper locals are pb1_.

local G

local function pb1_refresh()
    G = rawget(_G, "G") or G
    return G
end

local function pb1_round2(x)
    return math.floor(x * 100 + 0.5) / 100
end

local PB1_RANK_CHIPS = { [11] = 10, [12] = 10, [13] = 10, [14] = 11 }
local function pb1_chip_value(view)
    local data = (view and view.card_data) or {}
    if data.enhancement == "stone" then
        local v = 50 + (tonumber(data.Bonus) or tonumber(data.bonus) or 0)
            + (tonumber(data.chip_bonus) or 0)
        return v
    end
    local base = tonumber(data.chips)
    if not base then base = PB1_RANK_CHIPS[tonumber(data.rank) or 0] or tonumber(data.rank) or 0 end
    if data.enhancement == "bonus" then base = base + 30 end
    base = base + (tonumber(data.Bonus) or tonumber(data.bonus) or 0)
    base = base + (tonumber(data.chip_bonus) or 0)
    if data.modifier and data.modifier.edition == "foil" then base = base + 50 end
    return base
end

local function pb1_sync(view)
    if view and view.sync_visual_from_card_data then
        view:sync_visual_from_card_data()
    end
end

local function pb1_is_light(view)
    if not (view and view.is_suit) then return false end
    return view:is_suit("Hearts") or view:is_suit("Diamonds") or view:is_suit("Stars")
end

local function pb1_is_dark(view)
    if not (view and view.is_suit) then return false end
    return view:is_suit("Spades") or view:is_suit("Clubs") or view:is_suit("Crowns")
end

local function pb1_card_edition(view)
    local data = (view and view.card_data) or {}
    if data.modifier and data.modifier.edition then return data.modifier.edition end
    return data.edition
end

local function pb1_set_card_edition(view, edition)
    local data = view and view.card_data
    if not data then return end
    data.modifier = data.modifier or {}
    data.modifier.edition = edition
    pb1_sync(view)
end

local function pb1_ensure_uid(data)
    if type(data) ~= "table" then return nil end
    if data.uid == nil and G and G.ensure_card_uid then G:ensure_card_uid(data) end
    return data.uid
end

-- All playing-card data reachable from the game: deck, discard pile, hand.
local function pb1_all_card_data()
    local out = {}
    if not G then return out end
    if G.deck then
        for _, d in ipairs(G.deck.cards or {}) do out[#out + 1] = d end
        for _, d in ipairs(G.deck.discard_pile or {}) do out[#out + 1] = d end
    end
    if G.hand then
        for _, node in ipairs(G.hand.card_nodes or {}) do
            if node.card_data then out[#out + 1] = node.card_data end
        end
    end
    return out
end

local function pb1_find_data_by_uid(uid)
    if uid == nil then return nil end
    for _, d in ipairs(pb1_all_card_data()) do
        if d.uid == uid then return d end
    end
    return nil
end

-- Panorama family (autumn_leaves / birches / blue_bonnets / cherry_blossoms):
-- scored cards of the suit give a growing XMult per consecutively scored
-- card of that suit; the streak resets after each hand played.
local function pb1_panorama_calc(card, context, suit)
    local st = card.ability.extra
    if context.individual and context.cardarea == G.play and context.other_card then
        if context.other_card:is_suit(suit) then
            local give = pb1_round2(st.base + st.gain * st.streak)
            st.streak = st.streak + 1
            st.xmult = pb1_round2(st.base + st.gain * st.streak)
            return { xmult = give }
        end
        st.streak = 0
        st.xmult = st.base
    end
    if context.after then
        st.streak = 0
        st.xmult = st.base
    end
    return nil
end

-- Stick-food family (cakepop / caramel_apple / charred_marshmallow):
-- scored cards of the suit give +Mult; 1 in odds eaten at end of round.
local function pb1_stick_food_calc(card, context, suit)
    local st = card.ability.extra
    if context.individual and context.cardarea == G.play and context.other_card
        and context.other_card:is_suit(suit) then
        return { mult = st.mult }
    end
    if context.end_of_round then
        if SMODS.pseudorandom_probability(card, "pbp_stick_food", 1, st.odds) then
            SMODS.destroy_joker(card)
            return { message = "Eaten!" }
        end
    end
    return nil
end

local PB1_STICK_IDS = {
    j_pbp_bamboo_stick = true, j_pbp_pointy_stick = true, j_pbp_pop_stick = true,
    j_pbp_popsicle_stick = true, j_pbp_rockin_stick = true,
    j_pbp_sticky_stick = true, j_pbp_sweet_stick = true,
}

local function pb1_other_stick_held(card)
    if not G then return false end
    for _, j in ipairs(G.jokers or {}) do
        if j ~= card and j.def and PB1_STICK_IDS[j.def.id] then return true end
    end
    return false
end

-- a_balatro_movie
SMODS.Joker {
    key = "a_balatro_movie",
    name = "A Balatro Movie",
    rarity = 1,
    cost = 4,
    sprite = "a_balatro_movie.png",
    negative_sprite = "a_balatro_movie_negative.png",
    config = { extra = { dollars = 2, last_hand = "" } },
    loc_vars = function(self, info_queue, card)
        pb1_refresh()
        local last = card.ability.extra.last_hand
        return { vars = { (last ~= "" and last) or "None", card.ability.extra.dollars } }
    end,
    loc_txt = { name = "A Balatro Movie", text = {
        "If played hand is the same",
        "as the previous hand, earn $#2#",
        "(Last played: #1#)",
    } },
    calculate = function(self, card, context)
        pb1_refresh()
        if context.joker_main then
            local last = card.ability.extra.last_hand
            if last ~= "" and context.scoring_name and context.scoring_name == last then
                return { dollars = card.ability.extra.dollars }
            end
        end
        if context.after and context.scoring_name then
            card.ability.extra.last_hand = context.scoring_name
        end
    end,
}

-- alert
SMODS.Joker {
    key = "alert",
    name = "Alert",
    rarity = 2,
    cost = 4,
    sprite = "alert.png",
    negative_sprite = "alert_negative.png",
    config = { extra = { current = 0, max = 3 } },
    loc_vars = function(self, info_queue, card)
        pb1_refresh()
        return { vars = { card.ability.extra.current, card.ability.extra.max } }
    end,
    loc_txt = { name = "Alert", text = {
        "If played hand is a single",
        "face card, destroy it",
        "(#1#/#2#)",
    } },
    calculate = function(self, card, context)
        pb1_refresh()
        -- PORT NOTE: PC destroys through the destroying_card context during
        -- scoring; the fork has no such context, so the card is destroyed
        -- in the before pass and does not score.
        if context.before and context.full_hand and #context.full_hand == 1
            and context.scoring_hand and context.scoring_hand[1] then
            local target = context.scoring_hand[1]
            local st = card.ability.extra
            if target.is_face and target:is_face() and st.current < st.max then
                if SMODS.destroy_card(target) then
                    st.current = st.current + 1
                    if st.current >= st.max then
                        local edition = card.edition
                        if edition == "base" then edition = nil end
                        SMODS.destroy_joker(card)
                        SMODS.add_card { set = "Joker", key = "j_pbp_legacy", edition = edition }
                        return { message = "Destroyed!" }
                    end
                    return { message = st.current .. "/" .. st.max }
                end
            end
        end
    end,
}

-- ampersand
SMODS.Joker {
    key = "ampersand",
    name = "&",
    rarity = 1,
    cost = 3,
    sprite = "ampersand.png",
    negative_sprite = "ampersand_negative.png",
    config = { extra = { retriggers = 1, is_white = true } },
    loc_vars = function(self, info_queue, card)
        pb1_refresh()
        return { vars = { card.ability.extra.retriggers } }
    end,
    loc_txt = { name = "&", text = {
        "If scored hand contains both",
        "dark and light suits,",
        "retrigger the first of each #1# time",
    } },
    calculate = function(self, card, context)
        pb1_refresh()
        if context.repetition and context.other_card then
            local hand = context.scoring_hand
            if not hand or #hand == 0 then
                hand = (context.port and (context.port.played_cards or context.port.full_hand)) or {}
            end
            local dark, light, wilds, counter = nil, nil, {}, 0
            for _, v in ipairs(hand) do
                local is_dark, is_light = pb1_is_dark(v), pb1_is_light(v)
                if is_dark and is_light then
                    wilds[#wilds + 1] = v
                    counter = counter + 1
                elseif is_dark and not dark then
                    dark = v
                    counter = counter + 1
                elseif is_light and not light then
                    light = v
                    counter = counter + 1
                end
                if counter >= 2 then break end
            end
            if counter >= 2 then
                local hit = context.other_card == dark or context.other_card == light
                if not hit then
                    for _, v in ipairs(wilds) do
                        if v == context.other_card then hit = true break end
                    end
                end
                if hit then
                    card.ability.extra.is_white = not card.ability.extra.is_white
                    return { repetitions = card.ability.extra.retriggers }
                end
            end
        end
    end,
}

-- apple
SMODS.Joker {
    key = "apple",
    name = "Apple",
    rarity = 1,
    cost = 1,
    sprite = "apple.png",
    negative_sprite = "apple_negative.png",
    config = { extra = { odds = 3, break_odds = 6 } },
    loc_vars = function(self, info_queue, card)
        pb1_refresh()
        local n1, d1 = SMODS.get_probability_vars(card, 1, card.ability.extra.odds, "pbp_apple")
        local n2, d2 = SMODS.get_probability_vars(card, 1, card.ability.extra.break_odds, "pbp_apple_break")
        return { vars = { n1, d1, n2, d2 } }
    end,
    loc_txt = { name = "Apple", text = {
        "When buying a Consumable, has a",
        "#1# in #2# chance to create a",
        "Negative copy and a",
        "#3# in #4# chance to self-destruct",
    } },
    calculate = function(self, card, context)
        pb1_refresh()
        if context.buying_card and context.port then
            local kind = context.port.offer_kind
            local is_consumable = kind == "tarot" or kind == "planet"
                or kind == "spectral" or kind == "minor_arcana" or kind == "consumable"
            if is_consumable and context.port.offer_id then
                if SMODS.pseudorandom_probability(card, "pbp_apple", 1, card.ability.extra.odds) then
                    if G and G.can_add_consumable and G:can_add_consumable({ edition = "negative" }) then
                        G:add_consumable(context.port.offer_id, { edition = "negative" })
                    end
                    if SMODS.pseudorandom_probability(card, "pbp_apple_break", 1, card.ability.extra.break_odds) then
                        SMODS.destroy_joker(card)
                        return { message = "Destroyed!" }
                    end
                    return { message = "Copy!" }
                end
            end
        end
    end,
}

-- autumn_leaves
SMODS.Joker {
    key = "autumn_leaves",
    name = "Autumn Leaves",
    rarity = 2,
    cost = 6,
    sprite = "autumn_leaves.png",
    negative_sprite = "autumn_leaves_negative.png",
    config = { extra = { xmult = 1.05, gain = 0.05, base = 1.05, suit = "Diamonds", streak = 0 } },
    loc_vars = function(self, info_queue, card)
        pb1_refresh()
        local st = card.ability.extra
        return { vars = { "Diamonds", st.xmult, st.gain, "Diamonds" } }
    end,
    loc_txt = { name = "Autumn Leaves", text = {
        "#1# give X#2# Mult when scored.",
        "Increases by X#3# Mult for each",
        "consecutively scored #4#",
        "(Resets after each hand played)",
    } },
    calculate = function(self, card, context)
        pb1_refresh()
        return pb1_panorama_calc(card, context, "Diamonds")
    end,
}

-- b_soda
SMODS.Joker {
    key = "b_soda",
    name = "B-Soda",
    rarity = 1,
    cost = 4,
    sprite = "b_soda.png",
    negative_sprite = "b_soda_negative.png",
    config = { extra = { hands = 1, last_hands_left = -1 } },
    loc_vars = function(self, info_queue, card)
        pb1_refresh()
        return { vars = { card.ability.extra.hands } }
    end,
    loc_txt = { name = "B-Soda", text = {
        "When Blind is selected,",
        "gain +#1# Hand",
        "Consumed if Blind is",
        "cleared with 0 hands remaining",
    } },
    calculate = function(self, card, context)
        pb1_refresh()
        if context.setting_blind and G then
            G.hands = (tonumber(G.hands) or 0) + card.ability.extra.hands
            return { message = "+1 Hand" }
        end
        if context.after and G then
            card.ability.extra.last_hands_left = tonumber(G.hands) or -1
        end
        -- PORT NOTE: PC reads hands_left at end_of_round; the fork may have
        -- already refilled G.hands by then, so the value banked after the
        -- last played hand is used instead.
        if context.end_of_round then
            local left = card.ability.extra.last_hands_left
            if left == 0 or (G and (tonumber(G.hands) or -1) == 0) then
                SMODS.destroy_joker(card)
                return { message = "Consumed!" }
            end
        end
    end,
}

-- bamboo_stick
SMODS.Joker {
    key = "bamboo_stick",
    name = "Bamboo Stick",
    rarity = 1,
    cost = 7,
    sprite = "bamboo_stick.png",
    negative_sprite = "bamboo_stick_negative.png",
    config = { extra = { xmult_if_stick = 2 } },
    loc_vars = function(self, info_queue, card)
        pb1_refresh()
        local cur = pb1_other_stick_held(card) and card.ability.extra.xmult_if_stick or 1
        return { vars = { card.ability.extra.xmult_if_stick, cur } }
    end,
    loc_txt = { name = "Bamboo Stick", text = {
        "X#1# Mult if you have",
        "another \"Stick\" Joker",
        "(Currently X#2# Mult)",
    } },
    calculate = function(self, card, context)
        pb1_refresh()
        if context.joker_main and pb1_other_stick_held(card) then
            return { xmult = card.ability.extra.xmult_if_stick }
        end
    end,
}

-- banana_man
SMODS.Joker {
    key = "banana_man",
    name = "Banana Man",
    rarity = 3,
    cost = 8,
    sprite = "banana_man.png",
    negative_sprite = "banana_man_negative.png",
    config = { extra = { xmult = 2, odds = 3 } },
    loc_vars = function(self, info_queue, card)
        pb1_refresh()
        local num, den = SMODS.get_probability_vars(card, 1, card.ability.extra.odds, "pbp_banana_man")
        return { vars = { num, den, card.ability.extra.xmult } }
    end,
    loc_txt = { name = "Banana Man", text = {
        "Jokers have a #1# in #2# chance",
        "to give X#3# Mult",
    } },
    calculate = function(self, card, context)
        pb1_refresh()
        -- PORT NOTE: PC hooks context.other_joker during Joker evaluation;
        -- the fork equivalent is the post_trigger pass, which applies this
        -- return as if it had triggered on the other Joker's event.
        if context.post_trigger and context.other_card and context.other_card ~= card then
            if SMODS.pseudorandom_probability(card, "pbp_banana_man", 1, card.ability.extra.odds) then
                return { xmult = card.ability.extra.xmult }
            end
        end
    end,
}

-- basic_energy
SMODS.Joker {
    key = "basic_energy",
    name = "Basic Joker Energy",
    rarity = 2,
    cost = 6,
    sprite = "basic_energy.png",
    negative_sprite = "basic_energy_negative.png",
    config = { extra = { odds = 4 } },
    loc_vars = function(self, info_queue, card)
        pb1_refresh()
        local num, den = SMODS.get_probability_vars(card, 1, card.ability.extra.odds, "pbp_basic_energy")
        return { vars = { num, den } }
    end,
    loc_txt = { name = "Basic Joker Energy", text = {
        "Using any Consumable has a",
        "#1# in #2# chance to make a copy",
        "(Cannot make copy of a copy)",
        "(Must have room)",
    } },
    calculate = function(self, card, context)
        pb1_refresh()
        if context.using_consumeable and context.port then
            local raw = context.port
            local src = raw.consumable
            -- PORT NOTE: PC marks copies with a paperback_energized sticker;
            -- the fork has no consumable stickers, so copies carry a plain
            -- pbp_energized flag field instead.
            if src and src.pbp_energized then return end
            if raw.consumable_id and G and G.can_add_consumable and G:can_add_consumable() then
                if SMODS.pseudorandom_probability(card, "pbp_basic_energy", 1, card.ability.extra.odds) then
                    local edition = src and src.edition
                    local params = nil
                    if edition and edition ~= "base" then params = { edition = edition } end
                    if G:add_consumable(raw.consumable_id, params) then
                        local copy = G.consumables and G.consumables[#G.consumables]
                        if copy then copy.pbp_energized = true end
                        return { message = "Copy!" }
                    end
                end
            end
        end
    end,
}

-- big_misser
SMODS.Joker {
    key = "big_misser",
    name = "Big Misser",
    rarity = 2,
    cost = 6,
    sprite = "big_misser.png",
    negative_sprite = "big_misser_negative.png",
    config = { extra = { xmult_mod = 0.75 } },
    loc_vars = function(self, info_queue, card)
        pb1_refresh()
        local cur = 0
        if G and G.get_effective_consumable_capacity then
            local empty = math.max(0, G:get_effective_consumable_capacity() - #(G.consumables or {}))
            cur = empty * card.ability.extra.xmult_mod
        end
        return { vars = { card.ability.extra.xmult_mod, cur } }
    end,
    loc_txt = { name = "Big Misser", text = {
        "X#1# Mult for each empty",
        "consumable slot",
        "(Currently X#2# Mult)",
    } },
    calculate = function(self, card, context)
        pb1_refresh()
        if context.joker_main and G and G.get_effective_consumable_capacity then
            local empty = math.max(0, G:get_effective_consumable_capacity() - #(G.consumables or {}))
            if empty > 0 then
                return { xmult = empty * card.ability.extra.xmult_mod }
            end
        end
    end,
}

-- birches
SMODS.Joker {
    key = "birches",
    name = "Birches",
    rarity = 2,
    cost = 6,
    sprite = "birches.png",
    negative_sprite = "birches_negative.png",
    config = { extra = { xmult = 1.08, gain = 0.3, base = 1.08, suit = "Stars", streak = 0 } },
    loc_vars = function(self, info_queue, card)
        pb1_refresh()
        local st = card.ability.extra
        return { vars = { "Stars", st.xmult, st.gain, "Stars" } }
    end,
    loc_txt = { name = "Birches", text = {
        "#1# give X#2# Mult when scored.",
        "Increases by X#3# Mult for each",
        "consecutively scored #4#",
        "(Resets after each hand played)",
    } },
    calculate = function(self, card, context)
        pb1_refresh()
        return pb1_panorama_calc(card, context, "Stars")
    end,
}

-- bismuth
SMODS.Joker {
    key = "bismuth",
    name = "Bismuth",
    rarity = 2,
    cost = 7,
    sprite = "bismuth.png",
    negative_sprite = "bismuth_negative.png",
    config = { extra = { odds = 5 } },
    loc_vars = function(self, info_queue, card)
        pb1_refresh()
        local num, den = SMODS.get_probability_vars(card, 1, card.ability.extra.odds, "pbp_bismuth")
        return { vars = { "Crowns", "Stars", num, den } }
    end,
    loc_txt = { name = "Bismuth", text = {
        "Scored #1# and #2# have a",
        "#3# in #4# chance to gain a",
        "random edition",
    } },
    calculate = function(self, card, context)
        pb1_refresh()
        -- PORT NOTE: PC rolls in its modify_final_hand hook; the fork
        -- equivalent is the final_scoring_step pass over the scored hand.
        if context.final_scoring_step and context.scoring_hand then
            local hit = false
            for _, view in ipairs(context.scoring_hand) do
                if not pb1_card_edition(view)
                    and (view:is_suit("Crowns") or view:is_suit("Stars")) then
                    if SMODS.pseudorandom_probability(card, "pbp_bismuth", 1, card.ability.extra.odds) then
                        local editions = { "foil", "holo", "polychrome" }
                        pb1_set_card_edition(view, editions[SMODS.pseudorandom("pbp_bismuth_ed", 1, 3)])
                        hit = true
                    end
                end
            end
            if hit then return { message = "Edition!" } end
        end
    end,
}

-- black_forest_cake
SMODS.Joker {
    key = "black_forest_cake",
    name = "Black Forest Cake",
    rarity = 1,
    cost = 3,
    sprite = "black_forest_cake.png",
    negative_sprite = "black_forest_cake_negative.png",
    config = { extra = { mult = 2, a_mult = 2 } },
    loc_vars = function(self, info_queue, card)
        pb1_refresh()
        return { vars = { card.ability.extra.mult, card.ability.extra.a_mult } }
    end,
    loc_txt = { name = "Black Forest Cake", text = {
        "This Joker gains +#2# Mult",
        "for each Blind defeated",
        "Self-destructs if any",
        "card or Joker is destroyed",
        "(Currently +#1# Mult)",
    } },
    calculate = function(self, card, context)
        pb1_refresh()
        if context.remove_playing_cards and context.port
            and context.port.destroyed_cards and #context.port.destroyed_cards > 0 then
            -- PORT NOTE: PC also self-destructs when another Joker is
            -- destroyed; the fork raises no such event, so only playing
            -- card destruction is covered.
            SMODS.destroy_joker(card)
            return { message = "Eaten!" }
        end
        if context.joker_main and card.ability.extra.mult > 0 then
            return { mult = card.ability.extra.mult }
        end
        if context.end_of_round then
            card.ability.extra.mult = card.ability.extra.mult + card.ability.extra.a_mult
            return { message = "Upgrade!" }
        end
    end,
}

-- black_knife
SMODS.Joker {
    key = "black_knife",
    name = "Black Knife",
    rarity = 3,
    cost = 9,
    sprite = "black_knife.png",
    negative_sprite = "black_knife_negative.png",
    config = { extra = { destroy = 10, left = 10, odds = 10 } },
    loc_vars = function(self, info_queue, card)
        pb1_refresh()
        local num, den = SMODS.get_probability_vars(card, 1, card.ability.extra.odds, "pbp_black_knife")
        return { vars = { card.ability.extra.destroy, card.ability.extra.left, num, den } }
    end,
    loc_txt = { name = "Black Knife", text = {
        "Create a random Negative Joker",
        "for every #1# [#2#] destroyed light suits",
        "Scored light suits have a",
        "#3# in #4# chance to",
        "destroy a random Joker",
    } },
    calculate = function(self, card, context)
        pb1_refresh()
        local st = card.ability.extra
        if context.remove_playing_cards and context.port and context.port.destroyed_cards then
            for _, view in ipairs(context.port.destroyed_cards) do
                if pb1_is_light(view) then
                    st.left = st.left - 1
                    if st.left <= 0 then
                        st.left = st.destroy
                        if G and G.random_joker_def_id_by_rarity then
                            local roll = SMODS.pseudorandom("pbp_black_knife_rarity", 1, 100)
                            local rarity = roll <= 70 and 1 or (roll <= 95 and 2 or 3)
                            local id = G:random_joker_def_id_by_rarity(rarity, "pbp_black_knife")
                            if id then
                                SMODS.add_card { set = "Joker", key = id, edition = "negative", bypass_limit = true }
                            end
                        end
                    end
                end
            end
        end
        if context.after and context.scoring_hand and G then
            local targets = {}
            for _, j in ipairs(G.jokers or {}) do
                if j ~= card and not j.eternal then targets[#targets + 1] = j end
            end
            for _, view in ipairs(context.scoring_hand) do
                if #targets == 0 then break end
                if pb1_is_light(view)
                    and SMODS.pseudorandom_probability(card, "pbp_black_knife", 1, st.odds) then
                    local idx = SMODS.pseudorandom("pbp_black_knife_pick", 1, #targets)
                    local victim = targets[idx]
                    table.remove(targets, idx)
                    SMODS.destroy_joker(victim)
                end
            end
        end
    end,
}

-- black_rainbows
SMODS.Joker {
    key = "black_rainbows",
    name = "Black Rainbows",
    rarity = 2,
    cost = 8,
    sprite = "black_rainbows.png",
    negative_sprite = "black_rainbows_negative.png",
    config = { extra = { odds = 11 } },
    loc_vars = function(self, info_queue, card)
        pb1_refresh()
        local num, den = SMODS.get_probability_vars(card, 1, card.ability.extra.odds, "pbp_black_rainbows")
        return { vars = { num, den, "Spades", "Clubs" } }
    end,
    loc_txt = { name = "Black Rainbows", text = {
        "Scored #3# and #4#",
        "have a #1# in #2# chance",
        "to become Polychrome",
    } },
    calculate = function(self, card, context)
        pb1_refresh()
        if context.final_scoring_step and context.scoring_hand then
            local hit = false
            for _, view in ipairs(context.scoring_hand) do
                if not pb1_card_edition(view)
                    and (view:is_suit("Spades") or view:is_suit("Clubs")) then
                    if SMODS.pseudorandom_probability(card, "pbp_black_rainbows", 1, card.ability.extra.odds) then
                        pb1_set_card_edition(view, "polychrome")
                        hit = true
                    end
                end
            end
            if hit then return { message = "Polychrome!" } end
        end
    end,
}

-- black_star
SMODS.Joker {
    key = "black_star",
    name = "Black Star",
    rarity = 3,
    cost = 6,
    sprite = "black_star.png",
    negative_sprite = "black_star_negative.png",
    config = { extra = { suit_conv = "Stars" } },
    loc_vars = function(self, info_queue, card)
        pb1_refresh()
        return { vars = { card.ability.extra.suit_conv } }
    end,
    loc_txt = { name = "Black Star", text = {
        "Scored dark suits",
        "become #1#",
    } },
    calculate = function(self, card, context)
        pb1_refresh()
        if context.after and context.scoring_hand then
            local hit = false
            for _, view in ipairs(context.scoring_hand) do
                if pb1_is_dark(view) and view.card_data then
                    view.card_data.suit = card.ability.extra.suit_conv
                    pb1_sync(view)
                    hit = true
                end
            end
            if hit then return { message = "Converted!" } end
        end
    end,
}

-- blade_dance
SMODS.Joker {
    key = "blade_dance",
    name = "Blade Dance",
    rarity = 2,
    cost = 6,
    sprite = "blade_dance.png",
    negative_sprite = "blade_dance_negative.png",
    config = { extra = { cards = 3, temp_uids = {} } },
    loc_vars = function(self, info_queue, card)
        pb1_refresh()
        return { vars = { card.ability.extra.cards, "Steel Card" } }
    end,
    loc_txt = { name = "Blade Dance", text = {
        "When Blind is selected,",
        "add #1# random temporary",
        "#2#s to your hand",
    } },
    calculate = function(self, card, context)
        pb1_refresh()
        -- PORT NOTE: PC's temporary sticker is emulated by tracking the
        -- created cards' uids and destroying them at end of round (the
        -- audit's temporary-sticker emulation). Cards enter the hand
        -- directly; PC deals them from the play area.
        if context.first_hand_drawn then
            local suits = { "Hearts", "Diamonds", "Clubs", "Spades" }
            for _ = 1, card.ability.extra.cards do
                local rank = SMODS.pseudorandom("pbp_blade_dance_rank", 2, 14)
                local suit = suits[SMODS.pseudorandom("pbp_blade_dance_suit", 1, 4)]
                local node = SMODS.add_card {
                    set = "Playing", rank = rank, suit = suit,
                    enhancement = "steel", bypass_limit = true,
                }
                if node and node.card_data then
                    local uid = pb1_ensure_uid(node.card_data)
                    if uid ~= nil then
                        card.ability.extra.temp_uids[#card.ability.extra.temp_uids + 1] = uid
                    end
                end
            end
            return { message = "+3 Steel!" }
        end
        if context.end_of_round then
            for _, uid in ipairs(card.ability.extra.temp_uids or {}) do
                local data = pb1_find_data_by_uid(uid)
                if data then SMODS.destroy_card(data) end
            end
            card.ability.extra.temp_uids = {}
        end
    end,
}

-- blazing_trails
SMODS.Joker {
    key = "blazing_trails",
    name = "Blazing Trails",
    rarity = 2,
    cost = 6,
    sprite = "blazing_trails.png",
    negative_sprite = "blazing_trails_negative.png",
    config = { extra = { required_cards = 5 } },
    loc_vars = function(self, info_queue, card)
        pb1_refresh()
        return { vars = { card.ability.extra.required_cards } }
    end,
    loc_txt = { name = "Blazing Trails", text = {
        "If discard has exactly #1# cards,",
        "destroy the rightmost card",
    } },
    calculate = function(self, card, context)
        pb1_refresh()
        -- PORT NOTE: PC marks the card at pre_discard and destroys it as
        -- the discard resolves; the fork destroys it at pre_discard, so
        -- the card never reaches the discard pile.
        if context.pre_discard and context.port and context.port.discarded_nodes
            and #context.port.discarded_nodes == card.ability.extra.required_cards then
            local target = context.port.discarded_nodes[#context.port.discarded_nodes]
            if target and SMODS.destroy_card(target) then
                return { message = "Destroyed!" }
            end
        end
    end,
}

-- blue_bonnets
SMODS.Joker {
    key = "blue_bonnets",
    name = "Blue Bonnets",
    rarity = 2,
    cost = 6,
    sprite = "blue_bonnets.png",
    negative_sprite = "blue_bonnets_negative.png",
    config = { extra = { xmult = 1.05, gain = 0.05, base = 1.05, suit = "Clubs", streak = 0 } },
    loc_vars = function(self, info_queue, card)
        pb1_refresh()
        local st = card.ability.extra
        return { vars = { "Clubs", st.xmult, st.gain, "Clubs" } }
    end,
    loc_txt = { name = "Blue Bonnets", text = {
        "#1# give X#2# Mult when scored.",
        "Increases by X#3# Mult for each",
        "consecutively scored #4#",
        "(Resets after each hand played)",
    } },
    calculate = function(self, card, context)
        pb1_refresh()
        return pb1_panorama_calc(card, context, "Clubs")
    end,
}

-- blue_curacao
SMODS.Joker {
    key = "blue_curacao",
    name = "Blue Curaçao",
    rarity = 2,
    cost = 6,
    sprite = "blue_curacao.png",
    negative_sprite = "blue_curacao_negative.png",
    config = { extra = { amount = 6, remaining = 5 } },
    loc_vars = function(self, info_queue, card)
        pb1_refresh()
        return { vars = { card.ability.extra.remaining, "Clubs", card.ability.extra.amount } }
    end,
    loc_txt = { name = "Blue Curaçao", text = {
        "The next #1# played and scored #2#",
        "permanently gain +#3# Mult when scored",
    } },
    calculate = function(self, card, context)
        pb1_refresh()
        if context.individual and context.cardarea == G.play and context.other_card
            and card.ability.extra.remaining > 0
            and context.other_card:is_suit("Clubs") and context.other_card.card_data then
            local data = context.other_card.card_data
            data.mult_bonus = (tonumber(data.mult_bonus) or 0) + card.ability.extra.amount
            card.ability.extra.remaining = card.ability.extra.remaining - 1
            return { message = "Upgrade!" }
        end
    end,
}

-- blue_marble
SMODS.Joker {
    key = "blue_marble",
    name = "Blue Marble",
    rarity = 1,
    cost = 3,
    sprite = "blue_marble.png",
    negative_sprite = "blue_marble_negative.png",
    config = { extra = { mult = 0, increment = 2 } },
    loc_vars = function(self, info_queue, card)
        pb1_refresh()
        return { vars = { card.ability.extra.increment, card.ability.extra.mult } }
    end,
    loc_txt = { name = "Blue Marble", text = {
        "When a Planet card is used,",
        "this Joker gains +#1# Mult",
        "(Currently +#2# Mult)",
    } },
    calculate = function(self, card, context)
        pb1_refresh()
        if context.using_consumeable and context.port
            and context.port.consumable_kind == "planet" then
            card.ability.extra.mult = card.ability.extra.mult + card.ability.extra.increment
            return { message = "Upgrade!" }
        end
        if context.joker_main and card.ability.extra.mult > 0 then
            return { mult = card.ability.extra.mult }
        end
    end,
}

-- book_of_vengeance
SMODS.Joker {
    key = "book_of_vengeance",
    name = "Book of Vengeance",
    rarity = 3,
    cost = 9,
    sprite = "book_of_vengeance.png",
    negative_sprite = "book_of_vengeance_negative.png",
    loc_txt = { name = "Book of Vengeance", text = {
        "After defeating a Boss Blind,",
        "destroys itself and the Joker to its left,",
        "then makes a copy of Joker to its right",
    } },
    calculate = function(self, card, context)
        pb1_refresh()
        if context.end_of_round and G and G.current_blind_index == 3 then
            local left, right
            for i, j in ipairs(G.jokers or {}) do
                if j == card then
                    left = (G.jokers or {})[i - 1]
                    right = (G.jokers or {})[i + 1]
                    break
                end
            end
            if left and right and not left.eternal then
                local right_id = right.def and right.def.id
                local edition = right.edition
                if edition == "base" or edition == "negative" then edition = nil end
                -- PORT NOTE: PC's copy_card preserves the right Joker's
                -- scaled ability state; the fork creates a fresh copy, so
                -- accumulated scaling on the original is not carried over.
                SMODS.destroy_joker(card)
                SMODS.destroy_joker(left)
                if right_id then
                    SMODS.add_card { set = "Joker", key = right_id, edition = edition, bypass_limit = true }
                end
                return { message = "Duplicated!" }
            end
        end
    end,
}

-- boundary_of_death
SMODS.Joker {
    key = "boundary_of_death",
    name = "Boundary of Death",
    rarity = 2,
    cost = 8,
    sprite = "boundary_of_death.png",
    negative_sprite = "boundary_of_death_negative.png",
    config = { extra = { odds = 4, mult = 46 } },
    loc_vars = function(self, info_queue, card)
        pb1_refresh()
        local num, den = SMODS.get_probability_vars(card, 1, card.ability.extra.odds, "pbp_boundary_of_death")
        return { vars = { "Mult Card", num, den, card.ability.extra.mult } }
    end,
    loc_txt = { name = "Boundary of Death", text = {
        "#1#s have a",
        "#2# in #3# chance to",
        "give +#4# additional Mult",
    } },
    calculate = function(self, card, context)
        pb1_refresh()
        -- PORT NOTE: PC hooks Card:get_chip_mult so each Mult card's own
        -- Mult can grow; the fork has no such hook, so the bonus is paid
        -- as hand Mult from the card's individual pass instead.
        if context.individual and context.cardarea == G.play and context.other_card
            and context.other_card.card_data
            and context.other_card.card_data.enhancement == "mult" then
            if SMODS.pseudorandom_probability(card, "pbp_boundary_of_death", 1, card.ability.extra.odds) then
                return { mult = card.ability.extra.mult }
            end
        end
    end,
}

-- buckshot
SMODS.Joker {
    key = "buckshot",
    name = "Buckshot",
    rarity = 2,
    cost = 6,
    sprite = "buckshot.png",
    negative_sprite = "buckshot_negative.png",
    config = { extra = { dollars = 3, poker_hand = "Two Pair" } },
    loc_vars = function(self, info_queue, card)
        pb1_refresh()
        return { vars = { card.ability.extra.dollars } }
    end,
    loc_txt = { name = "Buckshot", text = {
        "If played hand",
        "contains a Two Pair,",
        "destroy all cards of a",
        "random rank in",
        "scoring hand and",
        "earn $#1# for each",
    } },
    calculate = function(self, card, context)
        pb1_refresh()
        if context.after and context.scoring_hand
            and next(context.poker_hands[card.ability.extra.poker_hand]) then
            local groups, order = {}, {}
            for _, view in ipairs(context.scoring_hand) do
                local data = view.card_data or {}
                if data.enhancement ~= "stone" then
                    local rank = view:get_id()
                    if not groups[rank] then
                        groups[rank] = {}
                        order[#order + 1] = rank
                    end
                    groups[rank][#groups[rank] + 1] = view
                end
            end
            if #order == 0 then return end
            local pick = order[SMODS.pseudorandom("pbp_buckshot", 1, #order)]
            local victims = groups[pick]
            local count = 0
            for _, view in ipairs(victims) do
                if SMODS.destroy_card(view) then count = count + 1 end
            end
            if count > 0 then
                return { dollars = count * card.ability.extra.dollars, message = "Destroyed!" }
            end
        end
    end,
}

-- cakepop
SMODS.Joker {
    key = "cakepop",
    name = "Cakepop",
    rarity = 1,
    cost = 6,
    sprite = "cakepop.png",
    negative_sprite = "cakepop_negative.png",
    config = { extra = { mult = 5, odds = 4, suit = "Hearts" } },
    loc_vars = function(self, info_queue, card)
        pb1_refresh()
        local num, den = SMODS.get_probability_vars(card, 1, card.ability.extra.odds, "pbp_cakepop")
        return { vars = { card.ability.extra.mult, num, den, "Hearts" } }
    end,
    loc_txt = { name = "Cakepop", text = {
        "Scored #4# give +#1# Mult",
        "#2# in #3# chance this card is",
        "eaten at end of round",
    } },
    calculate = function(self, card, context)
        pb1_refresh()
        return pb1_stick_food_calc(card, context, "Hearts")
    end,
}

-- caramel_apple
SMODS.Joker {
    key = "caramel_apple",
    name = "Caramel Apple",
    rarity = 1,
    cost = 6,
    sprite = "caramel_apple.png",
    negative_sprite = "caramel_apple_negative.png",
    config = { extra = { mult = 5, odds = 4, suit = "Clubs" } },
    loc_vars = function(self, info_queue, card)
        pb1_refresh()
        local num, den = SMODS.get_probability_vars(card, 1, card.ability.extra.odds, "pbp_caramel_apple")
        return { vars = { card.ability.extra.mult, num, den, "Clubs" } }
    end,
    loc_txt = { name = "Caramel Apple", text = {
        "Scored #4# give +#1# Mult",
        "#2# in #3# chance this card is",
        "eaten at end of round",
    } },
    calculate = function(self, card, context)
        pb1_refresh()
        return pb1_stick_food_calc(card, context, "Clubs")
    end,
}

-- card_sleeve
SMODS.Joker {
    key = "card_sleeve",
    name = "Card Sleeve",
    rarity = 1,
    cost = 4,
    sprite = "card_sleeve.png",
    negative_sprite = "card_sleeve_negative.png",
    loc_txt = { name = "Card Sleeve", text = {
        "Sell this card to make Joker",
        "to the right Eternal",
    } },
    calculate = function(self, card, context)
        pb1_refresh()
        if context.selling_card and context.selling_self and G then
            local right
            for i, j in ipairs(G.jokers or {}) do
                if j == card then right = (G.jokers or {})[i + 1] break end
            end
            if right then
                -- PORT NOTE: PC's set_eternal also recalculates debuffs;
                -- the fork stores Eternal as a plain field (the pack's own
                -- Minor Arcana precedent sets it directly).
                right.perishable = nil
                right.perishable_counter = nil
                right.eternal = true
                return { message = "Eternal!" }
            end
        end
    end,
}

-- cardboard_box
SMODS.Joker {
    key = "cardboard_box",
    name = "Cardboard Box",
    rarity = 2,
    cost = 7,
    sprite = "cardboard_box.png",
    negative_sprite = "cardboard_box_negative.png",
    config = { extra = { sell_value = 1, a_sell_value = 1, hands_played = 0 } },
    loc_vars = function(self, info_queue, card)
        pb1_refresh()
        return { vars = { card.ability.extra.sell_value, card.ability.extra.a_sell_value, "Queen" } }
    end,
    loc_txt = { name = "Cardboard Box", text = {
        "If first played hand of round",
        "contains a scoring Queen,",
        "add $#1# of sell value",
        "to every Joker",
        "Increases by $#2# when",
        "a Food Joker is destroyed",
    } },
    calculate = function(self, card, context)
        pb1_refresh()
        -- PORT NOTE: the +$1 growth when a Food Joker is destroyed is
        -- dropped: the fork raises no event for another Joker's
        -- destruction.
        if context.before and card.ability.extra.hands_played == 0 and context.scoring_hand then
            local has_queen = false
            for _, view in ipairs(context.scoring_hand) do
                if view:get_id() == 12 then has_queen = true break end
            end
            if has_queen and G then
                for _, j in ipairs(G.jokers or {}) do
                    j.sell_cost = (tonumber(j.sell_cost) or 0) + card.ability.extra.sell_value
                end
                return { message = "Value Up!" }
            end
        end
        if context.after then
            card.ability.extra.hands_played = card.ability.extra.hands_played + 1
        end
        if context.end_of_round then
            card.ability.extra.hands_played = 0
        end
    end,
}

-- cast_iron
SMODS.Joker {
    key = "cast_iron",
    name = "Cast Iron",
    rarity = 2,
    cost = 7,
    sprite = "cast_iron.png",
    negative_sprite = "cast_iron_negative.png",
    config = { h_size = 0, extra = { divisor = 3, hand_size = 0, max = 5, modifier = 1 } },
    loc_vars = function(self, info_queue, card)
        pb1_refresh()
        local st = card.ability.extra
        return { vars = { 10, st.divisor, "Steel Card", st.hand_size, st.max, st.modifier } }
    end,
    loc_txt = { name = "Cast Iron", text = {
        "Gives +#6# hand size",
        "for every #2# #3#s",
        "in your full deck",
        "(Currently +#4# hand size, Max #5#)",
    } },
    calculate = function(self, card, context)
        pb1_refresh()
        -- PORT NOTE: PC drives G.hand:change_size from an update hook;
        -- the fork recomputes hand size from the declarative h_size
        -- modifier on the Joker's ability, so the count is refreshed on
        -- deck-change and blind-select events instead.
        if (context.playing_card_added or context.remove_playing_cards
            or context.setting_blind or context.first_hand_drawn) and G
            and G.count_cards_in_full_deck then
            local steel = G:count_cards_in_full_deck(function(data)
                return data.enhancement == "steel"
            end)
            local st = card.ability.extra
            local size = math.min(math.floor(steel / st.divisor) * st.modifier, st.max)
            st.hand_size = size
            card.ability.h_size = size
        end
    end,
}

-- champagne
SMODS.Joker {
    key = "champagne",
    name = "Champagne",
    rarity = 1,
    cost = 5,
    sprite = "champagne.png",
    negative_sprite = "champagne_negative.png",
    config = { extra = { money = 1, rounds_left = 3 } },
    loc_vars = function(self, info_queue, card)
        pb1_refresh()
        return { vars = { card.ability.extra.money, card.ability.extra.rounds_left } }
    end,
    loc_txt = { name = "Champagne", text = {
        "During a Boss Blind, scored",
        "cards earn $#1#, doubled if",
        "the card has a seal",
        "Consumed in #2# rounds",
    } },
    calculate = function(self, card, context)
        pb1_refresh()
        if context.individual and context.cardarea == G.play and context.other_card
            and G and G.current_blind_index == 3 then
            local sealed = context.other_card.card_data and context.other_card.card_data.seal
            return { dollars = sealed and (card.ability.extra.money * 2) or card.ability.extra.money }
        end
        if context.end_of_round then
            card.ability.extra.rounds_left = card.ability.extra.rounds_left - 1
            if card.ability.extra.rounds_left <= 0 then
                SMODS.destroy_joker(card)
                return { message = "Consumed!" }
            end
            return { message = card.ability.extra.rounds_left .. " Rounds" }
        end
    end,
}

-- charred_marshmallow
SMODS.Joker {
    key = "charred_marshmallow",
    name = "Charred Marshmallow",
    rarity = 1,
    cost = 6,
    sprite = "charred_marshmallow.png",
    negative_sprite = "charred_marshmallow_negative.png",
    config = { extra = { mult = 5, odds = 4, suit = "Spades" } },
    loc_vars = function(self, info_queue, card)
        pb1_refresh()
        local num, den = SMODS.get_probability_vars(card, 1, card.ability.extra.odds, "pbp_charred_marshmallow")
        return { vars = { card.ability.extra.mult, num, den, "Spades" } }
    end,
    loc_txt = { name = "Charred Marshmallow", text = {
        "Scored #4# give +#1# Mult",
        "#2# in #3# chance this card is",
        "eaten at end of round",
    } },
    calculate = function(self, card, context)
        pb1_refresh()
        return pb1_stick_food_calc(card, context, "Spades")
    end,
}

-- cherry_blossoms
SMODS.Joker {
    key = "cherry_blossoms",
    name = "Cherry Blossoms",
    rarity = 2,
    cost = 6,
    sprite = "cherry_blossoms.png",
    negative_sprite = "cherry_blossoms_negative.png",
    config = { extra = { xmult = 1.05, gain = 0.05, base = 1.05, suit = "Hearts", streak = 0 } },
    loc_vars = function(self, info_queue, card)
        pb1_refresh()
        local st = card.ability.extra
        return { vars = { "Hearts", st.xmult, st.gain, "Hearts" } }
    end,
    loc_txt = { name = "Cherry Blossoms", text = {
        "#1# give X#2# Mult when scored.",
        "Increases by X#3# Mult for each",
        "consecutively scored #4#",
        "(Resets after each hand played)",
    } },
    calculate = function(self, card, context)
        pb1_refresh()
        return pb1_panorama_calc(card, context, "Hearts")
    end,
}

-- chocolate_coins
SMODS.Joker {
    key = "chocolate_coins",
    name = "Chocolate Coins",
    rarity = 1,
    cost = 6,
    sprite = "chocolate_coins.png",
    negative_sprite = "chocolate_coins_negative.png",
    config = { extra = { dollars = 8, eaten = 2 } },
    loc_vars = function(self, info_queue, card)
        pb1_refresh()
        return { vars = { card.ability.extra.dollars, card.ability.extra.eaten } }
    end,
    loc_txt = { name = "Chocolate Coins", text = {
        "Earn $#1# at end of round",
        "Reduces by $#2# each round",
    } },
    calc_dollar_bonus = function(self, card)
        return card.ability.extra.dollars
    end,
    calculate = function(self, card, context)
        pb1_refresh()
        if context.starting_shop then
            if card.ability.extra.dollars - card.ability.extra.eaten <= 0 then
                SMODS.destroy_joker(card)
                return { message = "Eaten!" }
            end
            card.ability.extra.dollars = card.ability.extra.dollars - card.ability.extra.eaten
        end
    end,
}

-- coffee
SMODS.Joker {
    key = "coffee",
    name = "Coffee",
    rarity = 2,
    cost = 6,
    sprite = "coffee.png",
    negative_sprite = "coffee_negative.png",
    config = { h_size = 1, extra = { hand_size = 1, increase = 1, odds = 6 } },
    loc_vars = function(self, info_queue, card)
        pb1_refresh()
        local num, den = SMODS.get_probability_vars(card, 1, card.ability.extra.odds, "pbp_coffee")
        return { vars = { card.ability.extra.hand_size, card.ability.extra.increase, num, den } }
    end,
    loc_txt = { name = "Coffee", text = {
        "+#1# hand size,",
        "increases by #2# when Blind is skipped.",
        "#3# in #4# chance this card is consumed when",
        "Small Blind or Big Blind is selected",
    } },
    calculate = function(self, card, context)
        pb1_refresh()
        -- PORT NOTE: PC changes hand size imperatively with
        -- G.hand:change_size; the fork's declarative h_size modifier on
        -- the ability is kept in sync instead, which the game recomputes.
        if context.skip_blind then
            card.ability.extra.hand_size = card.ability.extra.hand_size + card.ability.extra.increase
            card.ability.h_size = card.ability.extra.hand_size
            return { message = "Upgrade!" }
        end
        if context.setting_blind and G and G.current_blind_index ~= 3 then
            if SMODS.pseudorandom_probability(card, "pbp_coffee", 1, card.ability.extra.odds) then
                SMODS.destroy_joker(card)
                return { message = "Consumed!" }
            end
        end
    end,
}

-- complete_breakfast
SMODS.Joker {
    key = "complete_breakfast",
    name = "Complete Breakfast",
    rarity = 1,
    cost = 4,
    sprite = "complete_breakfast.png",
    negative_sprite = "complete_breakfast_negative.png",
    config = { extra = { mult = 5, chips = 50, odds = 8, chance_multiplier = 1, chance_inc = 1 } },
    loc_vars = function(self, info_queue, card)
        pb1_refresh()
        local st = card.ability.extra
        local num, den = SMODS.get_probability_vars(card, st.chance_multiplier, st.odds, "pbp_complete_breakfast")
        return { vars = { st.mult, st.chips, num, den, st.chance_multiplier } }
    end,
    loc_txt = { name = "Complete Breakfast", text = {
        "+#1# Mult and +#2# Chips",
        "#3# in #4# chance this card is",
        "eaten after played hand",
        "Chance increases by #5# after",
        "every played hand",
    } },
    calculate = function(self, card, context)
        pb1_refresh()
        if context.joker_main then
            return { mult = card.ability.extra.mult, chips = card.ability.extra.chips }
        end
        if context.after then
            local st = card.ability.extra
            if SMODS.pseudorandom_probability(card, "pbp_complete_breakfast", st.chance_multiplier, st.odds) then
                SMODS.destroy_joker(card)
                return { message = "Eaten!" }
            end
            st.chance_multiplier = st.chance_multiplier + st.chance_inc
            return { message = "Safe!" }
        end
    end,
}

-- deadringer
SMODS.Joker {
    key = "deadringer",
    name = "Deadringer",
    rarity = 3,
    cost = 7,
    sprite = "deadringer.png",
    negative_sprite = "deadringer_negative.png",
    config = { extra = { ace_reps = 1, seven_reps = 1, nine_reps = 2 } },
    loc_vars = function(self, info_queue, card)
        pb1_refresh()
        return { vars = { "Ace", "7", "9" } }
    end,
    loc_txt = { name = "Deadringer", text = {
        "Retrigger scored #1#s and #2#s",
        "once, and scored #3#s twice",
    } },
    calculate = function(self, card, context)
        pb1_refresh()
        if context.repetition and context.other_card then
            local rank = context.other_card:get_id()
            local st = card.ability.extra
            if rank == 14 then return { repetitions = st.ace_reps } end
            if rank == 7 then return { repetitions = st.seven_reps } end
            if rank == 9 then return { repetitions = st.nine_reps } end
        end
    end,
}

-- degenerate_joker
SMODS.Joker {
    key = "degenerate_joker",
    name = "Degenerate Joker",
    rarity = 1,
    cost = 4,
    sprite = "degenerate_joker.png",
    negative_sprite = "degenerate_joker_negative.png",
    config = { extra = { enhancement = "wild" } },
    loc_vars = function(self, info_queue, card)
        pb1_refresh()
        return { vars = { "Wild Card" } }
    end,
    loc_txt = { name = "Degenerate Joker", text = {
        "Played #1#s turn",
        "into the card to the right",
    } },
    calculate = function(self, card, context)
        pb1_refresh()
        if context.before and context.full_hand then
            local hand = context.full_hand
            for i = 1, #hand - 1 do
                local view, src = hand[i], hand[i + 1]
                if view.card_data and src.card_data
                    and view.card_data.enhancement == card.ability.extra.enhancement then
                    local d, s = view.card_data, src.card_data
                    d.rank, d.suit = s.rank, s.suit
                    d.enhancement, d.seal = s.enhancement, s.seal
                    d.Bonus, d.bonus = s.Bonus, s.bonus
                    d.chip_bonus, d.mult_bonus = s.chip_bonus, s.mult_bonus
                    if s.modifier then
                        d.modifier = { edition = s.modifier.edition }
                    else
                        d.modifier = nil
                    end
                    d.edition = s.edition
                    pb1_sync(view)
                end
            end
        end
    end,
}

-- der_fluschutze
SMODS.Joker {
    key = "der_fluschutze",
    name = "Der Fluschütze",
    rarity = 3,
    cost = 9,
    sprite = "der_fluschutze.png",
    negative_sprite = "der_fluschutze_negative.png",
    config = { extra = { xmult_mod = 0.25, xm = 1, hands_played = 0 } },
    loc_vars = function(self, info_queue, card)
        pb1_refresh()
        return { vars = { card.ability.extra.xmult_mod, card.ability.extra.xm } }
    end,
    loc_txt = { name = "Der Fluschütze", text = {
        "If first played hand of round",
        "is a single face card, destroy it",
        "and this Joker gains X#1# Mult",
        "(Currently X#2# Mult)",
    } },
    calculate = function(self, card, context)
        pb1_refresh()
        -- PORT NOTE: PC destroys through the destroy_card context during
        -- scoring; the fork has no such context, so the card is destroyed
        -- in the before pass and does not score.
        if context.before and card.ability.extra.hands_played == 0
            and context.full_hand and #context.full_hand == 1
            and context.scoring_hand and context.scoring_hand[1] then
            local target = context.scoring_hand[1]
            if target.is_face and target:is_face() then
                if SMODS.destroy_card(target) then
                    card.ability.extra.xm = pb1_round2(card.ability.extra.xm + card.ability.extra.xmult_mod)
                    return { message = "Upgrade!" }
                end
            end
        end
        if context.joker_main and card.ability.extra.xm > 1 then
            return { xmult = card.ability.extra.xm }
        end
        if context.after then
            card.ability.extra.hands_played = card.ability.extra.hands_played + 1
        end
        if context.end_of_round then
            card.ability.extra.hands_played = 0
        end
    end,
}

-- der_freischutz
SMODS.Joker {
    key = "der_freischutz",
    name = "Der Freischütz",
    rarity = 2,
    cost = 6,
    sprite = "der_freischutz.png",
    negative_sprite = "der_freischutz_negative.png",
    config = { extra = { max = 6, current = 0 } },
    loc_vars = function(self, info_queue, card)
        pb1_refresh()
        local st = card.ability.extra
        return { vars = { math.min(st.current, st.max), st.max } }
    end,
    loc_txt = { name = "Der Freischütz", text = {
        "If poker hand contains only 7s,",
        "destroy the lowest chip-value",
        "card in your full deck",
        "Avoid the Seventh Bullet... #1#/#2#",
    } },
    calculate = function(self, card, context)
        pb1_refresh()
        if context.after and context.scoring_hand and #context.scoring_hand > 0 then
            local all_sevens = true
            for _, view in ipairs(context.scoring_hand) do
                if view:get_id() ~= 7 then all_sevens = false break end
            end
            if not all_sevens then return end
            local st = card.ability.extra
            st.current = st.current + 1
            if st.current <= st.max then
                local best, best_chips = nil, nil
                for _, data in ipairs(pb1_all_card_data()) do
                    local chips = pb1_chip_value({ card_data = data })
                    if not best_chips or chips < best_chips then
                        best, best_chips = data, chips
                    end
                end
                if best and SMODS.destroy_card(best) then
                    return { message = "Destroyed!" }
                end
            else
                st.current = 0
                if G and G.hand then
                    local nodes = {}
                    for _, node in ipairs(G.hand.card_nodes or {}) do nodes[#nodes + 1] = node end
                    for _, node in ipairs(nodes) do SMODS.destroy_card(node) end
                end
                return { message = "Fire!" }
            end
        end
    end,
}

-- derecho
SMODS.Joker {
    key = "derecho",
    name = "Derecho",
    rarity = 2,
    cost = 6,
    sprite = "derecho.png",
    negative_sprite = "derecho_negative.png",
    config = { extra = { xmult_mod = 0.1, xm = 1 } },
    loc_vars = function(self, info_queue, card)
        pb1_refresh()
        return { vars = { card.ability.extra.xmult_mod, card.ability.extra.xm } }
    end,
    loc_txt = { name = "Derecho", text = {
        "Gains X#1# Mult if",
        "scored suits are all dark",
        "(Currently X#2# Mult)",
    } },
    calculate = function(self, card, context)
        pb1_refresh()
        if context.before and context.scoring_hand and #context.scoring_hand > 0 then
            local all_dark = true
            for _, view in ipairs(context.scoring_hand) do
                if not pb1_is_dark(view) then all_dark = false break end
            end
            if all_dark then
                card.ability.extra.xm = pb1_round2(card.ability.extra.xm + card.ability.extra.xmult_mod)
                return { message = "Upgrade!" }
            end
        end
        if context.joker_main and card.ability.extra.xm > 1 then
            return { xmult = card.ability.extra.xm }
        end
    end,
}

-- deviled_egg
SMODS.Joker {
    key = "deviled_egg",
    name = "Deviled Egg",
    rarity = 1,
    cost = 5,
    sprite = "deviled_egg.png",
    negative_sprite = "deviled_egg_negative.png",
    config = { extra = { rounds_left = 5, enabled = true } },
    loc_vars = function(self, info_queue, card)
        pb1_refresh()
        return { vars = { card.ability.extra.rounds_left } }
    end,
    loc_txt = { name = "Deviled Egg", text = {
        "The first scored card",
        "each round becomes Gold.",
        "Eaten in #1# rounds",
    } },
    calculate = function(self, card, context)
        pb1_refresh()
        if context.before and card.ability.extra.enabled and context.scoring_hand
            and context.scoring_hand[1] then
            card.ability.extra.enabled = false
            local target = context.scoring_hand[1]
            if target.card_data and target.card_data.enhancement ~= "gold" then
                target.card_data.enhancement = "gold"
                pb1_sync(target)
                return { message = "Gold!" }
            end
        end
        if context.end_of_round then
            card.ability.extra.enabled = true
            card.ability.extra.rounds_left = card.ability.extra.rounds_left - 1
            if card.ability.extra.rounds_left <= 0 then
                SMODS.destroy_joker(card)
                return { message = "Eaten!" }
            end
        end
    end,
}

-- disco
SMODS.Joker {
    key = "disco",
    name = "Disco Joker",
    rarity = 2,
    cost = 7,
    sprite = "disco.png",
    negative_sprite = "disco_negative.png",
    config = { extra = { mult_mod = 2, dollars = 25, mult = 0 } },
    loc_vars = function(self, info_queue, card)
        pb1_refresh()
        local st = card.ability.extra
        return { vars = { st.mult_mod, st.dollars, st.mult } }
    end,
    loc_txt = { name = "Disco Joker", text = {
        "This Joker gains +#1# Mult when",
        "buying a card with $#2# or less",
        "(Currently +#3# Mult)",
    } },
    calculate = function(self, card, context)
        pb1_refresh()
        if context.buying_card and G then
            -- PC rule: the wallet balance at the moment of buying must be
            -- at or below the threshold (not the bought card's price).
            local own_id = card.def and card.def.id
            local is_self = context.port and context.port.offer_kind == "joker"
                and own_id ~= nil and context.port.offer_id == own_id
            if not is_self and (tonumber(G.money) or 0) <= card.ability.extra.dollars then
                card.ability.extra.mult = card.ability.extra.mult + card.ability.extra.mult_mod
                return { message = "Upgrade!" }
            end
        end
        if context.joker_main and card.ability.extra.mult > 0 then
            return { mult = card.ability.extra.mult }
        end
    end,
}

-- donor_card
SMODS.Joker {
    key = "donor_card",
    name = "Donor Card",
    rarity = 2,
    cost = 6,
    sprite = "donor_card.png",
    negative_sprite = "donor_card_negative.png",
    config = { extra = { mult = 0, a_mult = 1, s_chips = 2, to_destroy_uids = {} } },
    loc_vars = function(self, info_queue, card)
        pb1_refresh()
        local st = card.ability.extra
        return { vars = { st.a_mult, st.s_chips, st.mult } }
    end,
    loc_txt = { name = "Donor Card", text = {
        "This Joker gains +#1# Mult for",
        "every scored Heart card",
        "(Currently +#3# Mult)",
        "Scored Hearts lose #2# Chips",
        "and are destroyed upon reaching 0",
    } },
    calculate = function(self, card, context)
        pb1_refresh()
        -- PORT NOTE: PC drains the card's perma_bonus field; the fork's
        -- persistent chip field is card_data.Bonus, drained here instead.
        if context.individual and context.cardarea == G.play and context.other_card
            and context.other_card.card_data
            and context.other_card:is_suit("Hearts") then
            local st = card.ability.extra
            local view = context.other_card
            local data = view.card_data
            local value = pb1_chip_value(view)
            local drain = math.min(st.s_chips, math.max(0, value))
            if drain > 0 then
                data.Bonus = (tonumber(data.Bonus) or tonumber(data.bonus) or 0) - drain
            end
            if value - drain <= 0 then
                local uid = pb1_ensure_uid(data)
                if uid ~= nil then st.to_destroy_uids[#st.to_destroy_uids + 1] = uid end
            end
            st.mult = st.mult + st.a_mult
            return { message = "+" .. st.a_mult .. " Mult" }
        end
        if context.after and #(card.ability.extra.to_destroy_uids or {}) > 0 then
            for _, uid in ipairs(card.ability.extra.to_destroy_uids) do
                local data = pb1_find_data_by_uid(uid)
                if data then SMODS.destroy_card(data) end
            end
            card.ability.extra.to_destroy_uids = {}
        end
        if context.joker_main and card.ability.extra.mult > 0 then
            return { mult = card.ability.extra.mult }
        end
    end,
}

-- doppler_radar
SMODS.Joker {
    key = "doppler_radar",
    name = "Doppler Radar",
    rarity = 2,
    cost = 7,
    sprite = "doppler_radar.png",
    negative_sprite = "doppler_radar_negative.png",
    loc_vars = function(self, info_queue, card)
        pb1_refresh()
        return { vars = { "Planet" } }
    end,
    loc_txt = { name = "Doppler Radar", text = {
        "Fill consumable slots",
        "with random #1# cards",
        "upon clearing a Blind",
    } },
    calculate = function(self, card, context)
        pb1_refresh()
        -- PORT NOTE: PC fires at end_of_round with main_eval (the round
        -- was cleared); the fork's blind_defeated event is the same beat.
        if context.blind_defeated and G and G.can_add_consumable then
            local made = 0
            for _ = 1, 10 do
                if not G:can_add_consumable() then break end
                local id = G.random_consumable_id_of_kind
                    and G:random_consumable_id_of_kind("planet")
                if not id then break end
                if not G:add_consumable(id) then break end
                made = made + 1
            end
            if made > 0 then return { message = "+Planet!" } end
        end
    end,
}

-- double_dutchman
SMODS.Joker {
    key = "double_dutchman",
    name = "Double Dutchman",
    rarity = 3,
    cost = 8,
    sprite = "double_dutchman.png",
    negative_sprite = "double_dutchman_negative.png",
    config = { extra = { odds = 4, hands_left = 5 } },
    loc_vars = function(self, info_queue, card)
        pb1_refresh()
        local num, den = SMODS.get_probability_vars(card, 1, card.ability.extra.odds, "pbp_double_dutchman")
        return { vars = { num, den, den * 2, card.ability.extra.hands_left } }
    end,
    loc_txt = { name = "Double Dutchman", text = {
        "For the next #4# hands,",
        "each card held in hand has a",
        "#1# in #2# chance to get a random enhancement",
        "and a #1# in #3# chance to get a random seal",
    } },
    calculate = function(self, card, context)
        pb1_refresh()
        if context.after and G and G.hand then
            local enhancements = { "bonus", "mult", "wild", "glass", "steel", "stone", "gold", "lucky" }
            local seals = { "gold", "red", "blue", "purple" }
            for _, node in ipairs(G.hand.card_nodes or {}) do
                local data = node.card_data
                if data then
                    if not data.enhancement
                        and SMODS.pseudorandom_probability(card, "pbp_double_dutchman_enh", 1, card.ability.extra.odds) then
                        data.enhancement = enhancements[SMODS.pseudorandom("pbp_double_dutchman_enh_pick", 1, #enhancements)]
                        pb1_sync(node)
                    end
                    if not data.seal
                        and SMODS.pseudorandom_probability(card, "pbp_double_dutchman_seal", 1, card.ability.extra.odds * 2) then
                        data.seal = seals[SMODS.pseudorandom("pbp_double_dutchman_seal_pick", 1, #seals)]
                        pb1_sync(node)
                    end
                end
            end
            card.ability.extra.hands_left = card.ability.extra.hands_left - 1
            if card.ability.extra.hands_left < 1 then
                SMODS.destroy_joker(card)
                return { message = "Consumed!" }
            end
        end
    end,
}
end

--------------------------------------------------------------------------------
-- Expansion Jokers, slice 2 (dreamsicle .. mandela_effect)
-- Ported from Paperback's MIT-licensed sources against the fork API.
-- Sub-effect deviations are marked with PORT NOTE comments inline.
--------------------------------------------------------------------------------
do
-- pb_frag_2: Paperback slice 2 (47 Jokers) for the Balatro3DS fork mod API.
-- Loads after paperbackpack.lua; uses only SMODS / G globals, fork dialect.
-- Rank-change / perma-bonus / sell-value effects mutate card_data / Joker
-- fields directly where the fork has no PC-style API (see pb_notes_2.md).

local function pb2_round2(x)
    return math.floor(x * 100 + 0.5) / 100
end

local PB2_RANK_CHIPS = { [11] = 10, [12] = 10, [13] = 10, [14] = 11 }
local function pb2_chip_value(view)
    local data = (view and view.card_data) or {}
    local base = tonumber(data.chips)
    if not base then base = PB2_RANK_CHIPS[tonumber(data.rank) or 0] or tonumber(data.rank) or 0 end
    if data.enhancement == "bonus" then base = base + 30 end
    base = base + (tonumber(data.chip_bonus) or 0)
    return base
end

local function pb2_is_dark(view)
    if not (view and view.is_suit) then return false end
    return view:is_suit("Spades") or view:is_suit("Clubs") or view:is_suit("Crowns")
end

local function pb2_joker_list()
    if not G then return {} end
    local list = G.jokers
    if type(list) == "table" and type(list.cards) == "table" then list = list.cards end
    if type(list) ~= "table" then return {} end
    return list
end

local function pb2_boss(context)
    local idx = context and context.port and context.port.blind_index
    if not idx and G then idx = G.current_blind_index end
    return tonumber(idx) == 3
end

local function pb2_prob_vars(card, num, den, id)
    if SMODS.get_probability_vars then
        local n, d = SMODS.get_probability_vars(card, num, den, id)
        return n or num, d or den
    end
    return num, den
end

local function pb2_spawn_consumable(kind)
    if not (G and G.can_add_consumable and G:can_add_consumable()) then return false end
    if not (G.random_consumable_id_of_kind and G.add_consumable) then return false end
    local id = G:random_consumable_id_of_kind(kind)
    if id and G:add_consumable(id) then return true end
    return false
end

local function pb2_scoring_views(context)
    if context.scoring_hand and #context.scoring_hand > 0 then
        return context.scoring_hand
    end
    local port = context.port or {}
    local list = port.played_cards or port.cards or port.full_hand or {}
    local out = {}
    for _, v in ipairs(type(list) == "table" and list or {}) do
        if type(v) == "table" and v.counts_for_play_score ~= false then
            out[#out + 1] = v
        end
    end
    return out
end

local function pb2_transform(card, key)
    local edition = card.edition
    if edition == "base" then edition = nil end
    if SMODS.destroy_joker then SMODS.destroy_joker(card) end
    if SMODS.add_card then
        SMODS.add_card { set = "Joker", key = "j_pbp_" .. key, edition = edition }
    end
end

local PB2_FACE_CHIPS = { [11] = 10, [12] = 10, [13] = 10, [14] = 11 }
local function pb2_rank_down(data)
    local rank = tonumber(data.rank) or 2
    local new_rank = rank - 1
    if new_rank < 2 then new_rank = 14 end
    data.rank = new_rank
    data.chips = PB2_FACE_CHIPS[new_rank] or new_rank
end

-- dreamsicle
SMODS.Joker {
    key = "dreamsicle",
    name = "Dreamsicle",
    rarity = 1,
    cost = 6,
    sprite = "dreamsicle.png",
    negative_sprite = "dreamsicle_negative.png",
    config = { extra = { mult = 5, odds = 4 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        local num, den = pb2_prob_vars(card, 1, card.ability.extra.odds, "paperback_dreamsicle")
        return { vars = { card.ability.extra.mult, num, den, "Diamonds" } }
    end,
    loc_txt = { name = "Dreamsicle", text = {"Scored Diamonds give +#1# Mult", "#2# in #3# chance this card is", "eaten at end of round"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.individual and context.cardarea == G.play and context.other_card
                and context.other_card.is_suit and context.other_card:is_suit("Diamonds") then
            return { mult = card.ability.extra.mult }
        end
        if context.end_of_round then
            -- PORT NOTE: PC also leaves a Popsicle Stick Joker when eaten;
            -- that Joker is not part of this slice, so only the eating
            -- itself is ported.
            if SMODS.pseudorandom_probability
                    and SMODS.pseudorandom_probability(card, "pb2_dreamsicle", 1,
                        card.ability.extra.odds, "paperback_dreamsicle") then
                if SMODS.destroy_joker then SMODS.destroy_joker(card) end
                return { message = "Eaten!" }
            end
            return { message = "Safe!" }
        end
    end,
}

-- emf_reader
SMODS.Joker {
    key = "emf_reader",
    name = "EMF Reader",
    rarity = 3,
    cost = 8,
    sprite = "emf_reader.png",
    negative_sprite = "emf_reader_negative.png",
    config = { extra = { first = true, pending = nil } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return { vars = { "Spectrum", "Spectral" } }
    end,
    loc_txt = { name = "EMF Reader", text = {"If first hand of round", "contains a Spectrum, destroy", "played cards and create", "a random Spectral card"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        local st = card.ability.extra
        if context.first_hand_drawn then
            st.first = true
            st.pending = nil
        end
        if context.before and st.first and context.poker_hands
                and next(context.poker_hands["Spectrum"]) then
            st.pending = context.scoring_hand or context.full_hand
        end
        if context.after then
            local pending = st.pending
            st.pending = nil
            st.first = false
            if pending and #pending > 0 then
                if SMODS.destroy_card then
                    for _, view in ipairs(pending) do SMODS.destroy_card(view) end
                end
                pb2_spawn_consumable("spectral")
                return { message = "+Spectral!" }
            end
        end
    end,
}

-- epic_sauce
SMODS.Joker {
    key = "epic_sauce",
    name = "Epic Sauce",
    rarity = 3,
    cost = 8,
    sprite = "epic_sauce.png",
    negative_sprite = "epic_sauce_negative.png",
    config = { extra = { x_mult = 4, seen = 0 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return { vars = { card.ability.extra.x_mult } }
    end,
    loc_txt = { name = "Epic Sauce", text = {"X#1# Mult", "Destroy a random Joker", "if played hand is not", "the first hand of round"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        local st = card.ability.extra
        if context.before then
            st.seen = st.seen + 1
        end
        if context.joker_main then
            return { xmult = st.x_mult }
        end
        if context.after and st.seen >= 2 then
            local pool = pb2_joker_list()
            if #pool > 0 and SMODS.destroy_joker and SMODS.pseudorandom then
                local victim = pool[SMODS.pseudorandom("pb2_epic_sauce", 1, #pool)]
                if victim then
                    SMODS.destroy_joker(victim)
                    return { message = "Too Hot!" }
                end
            end
        end
        if context.end_of_round then
            st.seen = 0
        end
    end,
}

-- evergreens
SMODS.Joker {
    key = "evergreens",
    name = "Evergreens",
    rarity = 2,
    cost = 6,
    sprite = "evergreens.png",
    negative_sprite = "evergreens_negative.png",
    config = { extra = { x_mult = 1.05, gain = 0.05 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return { vars = { "Spades", card.ability.extra.x_mult, card.ability.extra.gain, "Spades" } }
    end,
    loc_txt = { name = "Evergreens", text = {"Spades give X#2# Mult when scored.", "Increases by X#3# Mult for each", "consecutively scored Spades", "(Resets after each hand played)"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        local st = card.ability.extra
        if context.individual and context.cardarea == G.play and context.other_card
                and context.other_card.is_suit and context.other_card:is_suit("Spades") then
            local give = st.x_mult
            st.x_mult = pb2_round2(st.x_mult + st.gain)
            return { xmult = give }
        end
        if context.after then
            st.x_mult = 1.05
        end
    end,
}

-- eyelander
SMODS.Joker {
    key = "eyelander",
    name = "Eyelander",
    rarity = 3,
    cost = 8,
    sprite = "eyelander.png",
    negative_sprite = "eyelander_negative.png",
    config = { extra = { heads = 0, heads_req = 9, pending = nil } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return { vars = { card.ability.extra.heads_req, card.ability.extra.heads } }
    end,
    loc_txt = { name = "Eyelander", text = {"Scored face cards are destroyed.", "After scoring #1# face cards,", "selling this Joker adds Negative", "to a random Joker", "(Currently #2# Heads)"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        local st = card.ability.extra
        if context.before and context.scoring_hand then
            local faces = {}
            for _, view in ipairs(context.scoring_hand) do
                local rank = view.get_id and view:get_id() or 0
                if rank >= 11 and rank <= 13 then faces[#faces + 1] = view end
            end
            st.pending = #faces > 0 and faces or nil
            if #faces > 0 then st.heads = st.heads + #faces end
        end
        if context.after then
            local pending = st.pending
            st.pending = nil
            if pending and SMODS.destroy_card then
                for _, view in ipairs(pending) do SMODS.destroy_card(view) end
            end
            if pending then return { message = "Heads!" } end
        end
        if context.selling_card and st.heads >= st.heads_req then
            local sold = context.card or (context.port and context.port.joker)
            if context.selling_self or sold == nil or sold == card then
                local pool = {}
                for _, j in ipairs(pb2_joker_list()) do
                    if j ~= card and (j.edition == nil or j.edition == "base") then
                        pool[#pool + 1] = j
                    end
                end
                if #pool > 0 and SMODS.pseudorandom then
                    local pick = pool[SMODS.pseudorandom("pb2_eyelander", 1, #pool)]
                    if pick then pick.edition = "negative" end
                    return { message = "Negative!" }
                end
            end
        end
    end,
}

-- first_contact
SMODS.Joker {
    key = "first_contact",
    name = "First Contact",
    rarity = 3,
    cost = 8,
    sprite = "first_contact.png",
    negative_sprite = "first_contact_negative.png",
    config = { extra = { required = 17, count = 0 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        local st = card.ability.extra
        return { vars = { st.required, st.required - (st.count % st.required), "Spectral" } }
    end,
    loc_txt = { name = "First Contact", text = {"Create a random Spectral card", "for every #1# [#2#] scored dark suits", "(Must have room)"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        local st = card.ability.extra
        if context.individual and context.cardarea == G.play and context.other_card
                and pb2_is_dark(context.other_card) then
            st.count = st.count + 1
            if st.count % st.required == 0 then
                if pb2_spawn_consumable("spectral") then
                    return { message = "+Spectral!" }
                end
            end
        end
    end,
}

-- forlorn
SMODS.Joker {
    key = "forlorn",
    name = "Forlorn",
    rarity = 1,
    cost = 6,
    sprite = "forlorn.png",
    negative_sprite = "forlorn_negative.png",
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return { vars = { "Spades" } }
    end,
    loc_txt = { name = "Forlorn", text = {"If played hand's only scored suit", "is Spades, destroy a random", "card held in hand"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.after and context.scoring_hand and #context.scoring_hand > 0 then
            local bad, spade = false, false
            for _, view in ipairs(context.scoring_hand) do
                local data = view.card_data or {}
                if data.enhancement ~= "stone" then
                    if view.is_suit and view:is_suit("Spades") then
                        spade = true
                    else
                        bad = true
                    end
                end
            end
            if spade and not bad and G and G.hand and G.hand.card_nodes
                    and #G.hand.card_nodes > 0 and SMODS.destroy_card
                    and SMODS.pseudorandom then
                local nodes = G.hand.card_nodes
                local target = nodes[SMODS.pseudorandom("pb2_forlorn", 1, #nodes)]
                if target and SMODS.destroy_card(target) then
                    return { message = "Destroyed!" }
                end
            end
        end
    end,
}

-- fraudulent_joker
SMODS.Joker {
    key = "fraudulent_joker",
    name = "Fraudulent Joker",
    rarity = 1,
    cost = 5,
    sprite = "fraudulent_joker.png",
    negative_sprite = "fraudulent_joker_negative.png",
    config = { extra = { s_mult = 5 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return { vars = { card.ability.extra.s_mult, "Crowns" } }
    end,
    loc_txt = { name = "Fraudulent Joker", text = {"Played cards with", "Crowns suit give", "+#1# Mult when scored"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.individual and context.cardarea == G.play and context.other_card
                and context.other_card.is_suit and context.other_card:is_suit("Crowns") then
            return { mult = card.ability.extra.s_mult }
        end
    end,
}

-- freezer
SMODS.Joker {
    key = "freezer",
    name = "Freezer",
    rarity = 3,
    cost = 7,
    sprite = "freezer.png",
    negative_sprite = "freezer_negative.png",
    loc_txt = { name = "Freezer", text = {"Create a Negative Food Joker", "after defeating a Boss Blind"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.end_of_round and not context.game_over and pb2_boss(context) then
            -- PORT NOTE: the fork has no Food Joker pool, so this creates a
            -- random Common/Uncommon Joker with the Negative edition
            -- instead of a random Food Joker.
            if G and G.random_joker_def_id_by_rarity and SMODS.add_card
                    and SMODS.pseudorandom then
                local rarity = SMODS.pseudorandom("pb2_freezer", 1, 2)
                local id = G:random_joker_def_id_by_rarity(rarity)
                if id then
                    SMODS.add_card { set = "Joker", key = id, edition = "negative" }
                    return { message = "Frozen!" }
                end
            end
        end
    end,
}

-- freight
SMODS.Joker {
    key = "freight",
    name = "Freight",
    rarity = 2,
    cost = 8,
    sprite = "freight.png",
    negative_sprite = "freight_negative.png",
    config = { extra = { gain = 2, discards = 1, per_dollar = 2 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        local st = card.ability.extra
        return { vars = { st.gain, st.discards, st.per_dollar } }
    end,
    loc_txt = { name = "Freight", text = {"If cleared Blind is a Boss Blind,", "gain $#1# of sell value, otherwise", "earn the sell value of this Joker.", "When sold, gain +#2# discard per $#3#", "of sell value instead of money"} },
    calc_dollar_bonus = function(self, card)
        if not pb2_boss({}) then
            return tonumber(card.sell_cost) or 0
        end
        return 0
    end,
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        local st = card.ability.extra
        if context.end_of_round and not context.game_over and pb2_boss(context) then
            card.sell_cost = (tonumber(card.sell_cost) or 0) + st.gain
            return { message = "Value Up!" }
        end
        if context.selling_card then
            local sold = context.card or (context.port and context.port.joker)
            if context.selling_self or sold == nil or sold == card then
                -- PORT NOTE: PC suppresses the sale money (sell value set
                -- to 0); the fork pays sell value on sale regardless, so
                -- only the discard conversion is ported.
                local n = st.discards * math.floor((tonumber(card.sell_cost) or 0) / st.per_dollar)
                if n > 0 and G then
                    G.discards = (tonumber(G.discards) or 0) + n
                    return { message = "+" .. n .. " Discard" }
                end
            end
        end
    end,
}

-- full_moon
SMODS.Joker {
    key = "full_moon",
    name = "Full Moon",
    rarity = 2,
    cost = 7,
    sprite = "full_moon.png",
    negative_sprite = "full_moon_negative.png",
    config = { extra = { odds = 2 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        local num, den = pb2_prob_vars(card, 1, card.ability.extra.odds, "paperback_full_moon")
        return { vars = { num, den } }
    end,
    loc_txt = { name = "Full Moon", text = {"Planet cards have", "a #1# in #2# chance", "to level up again"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.using_consumeable and context.port
                and context.port.consumable_kind == "planet" then
            if SMODS.pseudorandom_probability
                    and SMODS.pseudorandom_probability(card, "pb2_full_moon", 1,
                        card.ability.extra.odds, "paperback_full_moon") then
                local hand_name = nil
                local cons = context.port.consumable
                if type(cons) == "table" and type(cons.hand) == "string" then
                    hand_name = cons.hand
                end
                if not hand_name and context.port.consumable_id
                        and type(CONSUMABLE_DEFS) == "table" then
                    local def = CONSUMABLE_DEFS[context.port.consumable_id]
                    if def and type(def.hand) == "string" then hand_name = def.hand end
                end
                if hand_name and G and G.handlist and G.upgrade_hand_level_at_index then
                    for i, name in ipairs(G.handlist) do
                        if name == hand_name then
                            G:upgrade_hand_level_at_index(i)
                            return { message = "Level Up!" }
                        end
                    end
                end
            end
        end
    end,
}

-- furioso
SMODS.Joker {
    key = "furioso",
    name = "Furioso",
    rarity = 2,
    cost = 6,
    sprite = "furioso.png",
    negative_sprite = "furioso_negative.png",
    config = { extra = { x_mult = 1, x_mult_mod = 0.2, ranks = {} } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        local st = card.ability.extra
        local names = {}
        for rank in pairs(st.ranks or {}) do names[#names + 1] = tonumber(rank) or 0 end
        table.sort(names)
        local labels = { [11] = "Jack", [12] = "Queen", [13] = "King", [14] = "Ace" }
        local parts = {}
        for _, r in ipairs(names) do parts[#parts + 1] = labels[r] or tostring(r) end
        local played = #parts > 0 and (" " .. table.concat(parts, " ")) or " None"
        return { vars = { st.x_mult_mod, st.x_mult, played } }
    end,
    loc_txt = { name = "Furioso", text = {"This Joker gains X#1# Mult for", "each unique scored rank.", "Resets after Boss Blind", "(Currently X#2# Mult)", "(Ranks played:#3#)"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        local st = card.ability.extra
        if context.individual and context.cardarea == G.play and context.other_card then
            local data = context.other_card.card_data or {}
            if data.enhancement ~= "stone" then
                local rank = context.other_card.get_id and context.other_card:get_id() or 0
                if rank > 0 and not st.ranks[rank] then
                    st.ranks[rank] = true
                    st.x_mult = pb2_round2(st.x_mult + st.x_mult_mod)
                    return { message = "Upgrade!" }
                end
            end
        end
        if context.joker_main and st.x_mult > 1 then
            return { xmult = st.x_mult }
        end
        if context.end_of_round and pb2_boss(context) then
            st.x_mult = 1
            st.ranks = {}
        end
    end,
}

-- gambit
SMODS.Joker {
    key = "gambit",
    name = "Gambit",
    rarity = 2,
    cost = 6,
    sprite = "gambit.png",
    negative_sprite = "gambit_negative.png",
    config = { extra = { chip_mult = 2, crown = nil, armed = false } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return { vars = { "Crowns" } }
    end,
    loc_txt = { name = "Gambit", text = {"If played hand contains a scoring Crowns,", "the first scored Crowns destroys", "the first non-Crowns held in hand", "and gains twice its Chip value"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        local st = card.ability.extra
        if context.before and context.scoring_hand then
            st.crown = nil
            st.armed = false
            for _, view in ipairs(context.scoring_hand) do
                if view.is_suit and view:is_suit("Crowns") then
                    st.crown = view
                    st.armed = true
                    break
                end
            end
        end
        if context.after and st.armed then
            st.armed = false
            local crown = st.crown
            st.crown = nil
            if crown and crown.card_data and G and G.hand and G.hand.card_nodes then
                for _, node in ipairs(G.hand.card_nodes) do
                    if not (node.is_suit and node:is_suit("Crowns")) then
                        local gain = pb2_chip_value(node) * (st.chip_mult or 2)
                        crown.card_data.chip_bonus = (tonumber(crown.card_data.chip_bonus) or 0) + gain
                        if SMODS.destroy_card then SMODS.destroy_card(node) end
                        return { message = "Upgrade!" }
                    end
                end
            end
        end
    end,
}

-- golden_apple
SMODS.Joker {
    key = "golden_apple",
    name = "Golden Apple",
    rarity = 2,
    cost = 7,
    sprite = "golden_apple.png",
    negative_sprite = "golden_apple_negative.png",
    config = { extra = { money = 1, rounds = 3 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        local st = card.ability.extra
        local current = 0
        if G and G.count_cards_in_full_deck then
            current = st.money * G:count_cards_in_full_deck(function(data)
                return data.enhancement ~= nil
            end)
        end
        return { vars = { st.money, st.rounds, current } }
    end,
    loc_txt = { name = "Golden Apple", text = {"Earn $#1# for each enhanced", "card in your deck at the", "end of the next #2# rounds", "(Currently $#3#)"} },
    calc_dollar_bonus = function(self, card)
        if not (G and G.count_cards_in_full_deck) then return 0 end
        local n = G:count_cards_in_full_deck(function(data)
            return data.enhancement ~= nil
        end)
        return (tonumber(card.ability.extra.money) or 1) * n
    end,
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        local st = card.ability.extra
        if context.end_of_round and not context.game_over then
            st.rounds = st.rounds - 1
            if st.rounds <= 0 then
                if SMODS.destroy_joker then SMODS.destroy_joker(card) end
                return { message = "Eaten!" }
            end
            return { message = st.rounds .. " Rounds Left" }
        end
    end,
}

-- golden_egg
SMODS.Joker {
    key = "golden_egg",
    name = "Golden Egg",
    rarity = 3,
    cost = 8,
    sprite = "golden_egg.png",
    negative_sprite = "golden_egg_negative.png",
    loc_txt = { name = "Golden Egg", text = {"When a secret hand is played,", "earn the sell value of", "the Joker to the right"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.joker_main then
            local name = context.scoring_name
                or (context.port and context.port.hand_type)
            local secret = name == "Spectrum" or name == "Straight Spectrum"
                or name == "Spectrum House" or name == "Spectrum Five"
            if secret then
                local list = pb2_joker_list()
                for i, j in ipairs(list) do
                    if j == card then
                        local nxt = list[i + 1]
                        if nxt then
                            local value = tonumber(nxt.sell_cost) or 0
                            if value > 0 then return { dollars = value } end
                        end
                        break
                    end
                end
            end
        end
    end,
}

-- great_wave
SMODS.Joker {
    key = "great_wave",
    name = "Great Wave",
    rarity = 3,
    cost = 8,
    sprite = "great_wave.png",
    negative_sprite = "great_wave_negative.png",
    loc_txt = { name = "Great Wave", text = {"Retrigger rightmost scoring card", "once for each other scoring card"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.repetition and context.cardarea == G.play and context.other_card then
            local scoring = pb2_scoring_views(context)
            if #scoring > 1 and context.other_card == scoring[#scoring] then
                return { repetitions = #scoring - 1, message = "Again!" }
            end
        end
    end,
}

-- hamsa
SMODS.Joker {
    key = "hamsa",
    name = "Hamsa",
    rarity = 1,
    cost = 5,
    sprite = "hamsa.png",
    negative_sprite = "hamsa_negative.png",
    config = { extra = { select = 2, hands = 0 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return { vars = { card.ability.extra.select } }
    end,
    loc_txt = { name = "Hamsa", text = {"On the first hand of round,", "retrigger the first", "#1# played cards..."} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        local st = card.ability.extra
        if context.first_hand_drawn then
            st.hands = 0
        end
        if context.before then
            st.hands = st.hands + 1
        end
        if context.repetition and context.cardarea == G.play and context.other_card
                and st.hands <= 1 then
            local scoring = pb2_scoring_views(context)
            for i = 1, math.min(st.select, #scoring) do
                if context.other_card == scoring[i] then
                    return { repetitions = 1 }
                end
            end
        end
        if context.end_of_round and not context.game_over then
            -- PORT NOTE: PC flips this Joker into its reverse in place;
            -- the port destroys and recreates it (edition preserved,
            -- slot position and stickers are not).
            pb2_transform(card, "hamsa_r")
            return { message = "Reverse!" }
        end
    end,
}

-- hamsa_r
SMODS.Joker {
    key = "hamsa_r",
    name = "Hamsa",
    rarity = 1,
    cost = 5,
    sprite = "hamsa_r.png",
    negative_sprite = "hamsa_r_negative.png",
    config = { extra = { luck = 3, ready = true } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return { vars = { card.ability.extra.luck } }
    end,
    loc_txt = { name = "Hamsa", text = {"...On the last hand of round,", "+#1# to all listed probabilites"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        local st = card.ability.extra
        if context.first_hand_drawn then
            st.ready = true
        end
        if context.before then
            st.ready = false
        end
        if context.mod_probability then
            local hands_left = tonumber(G and G.hands) or 1
            local active = hands_left <= 0 or (hands_left == 1 and st.ready)
            if active then
                return { numerator = (context.numerator or 0) + st.luck }
            end
        end
        if context.end_of_round and not context.game_over then
            pb2_transform(card, "hamsa")
            return { message = "Reverse!" }
        end
    end,
}

-- hatred
SMODS.Joker {
    key = "hatred",
    name = "HATRED",
    rarity = 2,
    cost = 5,
    sprite = "hatred.png",
    negative_sprite = "hatred_negative.png",
    config = { extra = { xmult = 1.5, marked_uid = nil, mark_new = true } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return { vars = { card.ability.extra.xmult } }
    end,
    loc_txt = { name = "HATRED", text = {"Before each hand, mark a random", "card held in hand", "Marked cards give X#1# Mult when scored", "and are destroyed if not scored"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        local st = card.ability.extra
        local function mark_random()
            if not (G and G.hand and G.hand.card_nodes) then return end
            local pool = {}
            for _, node in ipairs(G.hand.card_nodes) do
                if node.card_data and node.card_data.uid ~= nil
                        and node.card_data.uid ~= st.marked_uid then
                    pool[#pool + 1] = node
                end
            end
            if #pool > 0 and SMODS.pseudorandom then
                local pick = pool[SMODS.pseudorandom("pb2_hatred", 1, #pool)]
                if pick then
                    st.marked_uid = pick.card_data.uid
                    st.mark_new = false
                end
            end
        end
        if context.first_hand_drawn and st.mark_new then
            mark_random()
        end
        if context.before and st.mark_new and st.marked_uid == nil then
            mark_random()
        end
        if context.individual and context.cardarea == G.play and context.other_card
                and st.marked_uid ~= nil and context.other_card.card_data
                and context.other_card.card_data.uid == st.marked_uid then
            return { xmult = st.xmult }
        end
        if context.discard and context.other_card and st.marked_uid ~= nil
                and context.other_card.card_data
                and context.other_card.card_data.uid == st.marked_uid then
            st.marked_uid = nil
            st.mark_new = true
            if SMODS.destroy_card then SMODS.destroy_card(context.other_card) end
            return { message = "Death!" }
        end
        if context.after then
            local destroyed = false
            if st.marked_uid ~= nil and G and G.hand and G.hand.card_nodes then
                for _, node in ipairs(G.hand.card_nodes) do
                    if node.card_data and node.card_data.uid == st.marked_uid then
                        if SMODS.destroy_card and SMODS.destroy_card(node) then
                            destroyed = true
                        end
                    end
                end
            end
            if st.marked_uid ~= nil then
                local was_scored = false
                for _, view in ipairs(context.scoring_hand or {}) do
                    if view.card_data and view.card_data.uid == st.marked_uid then
                        was_scored = true
                    end
                end
                if was_scored or destroyed then st.marked_uid = nil end
            end
            st.mark_new = true
            if destroyed then return { message = "Death!" } end
        end
    end,
}

-- heretical_joker
SMODS.Joker {
    key = "heretical_joker",
    name = "Heretical Joker",
    rarity = 1,
    cost = 5,
    sprite = "heretical_joker.png",
    negative_sprite = "heretical_joker_negative.png",
    config = { extra = { s_mult = 5 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return { vars = { card.ability.extra.s_mult, "Stars" } }
    end,
    loc_txt = { name = "Heretical Joker", text = {"Played cards with", "Stars suit give", "+#1# Mult when scored"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.individual and context.cardarea == G.play and context.other_card
                and context.other_card.is_suit and context.other_card:is_suit("Stars") then
            return { mult = card.ability.extra.s_mult }
        end
    end,
}

-- high_speed_rail
SMODS.Joker {
    key = "high_speed_rail",
    name = "High Speed Rail",
    rarity = 1,
    cost = 3,
    sprite = "high_speed_rail.png",
    negative_sprite = "high_speed_rail_negative.png",
    config = { extra = { mult = 3 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return { vars = { card.ability.extra.mult } }
    end,
    loc_txt = { name = "High Speed Rail", text = {"This Joker gains Mult equal to", "the cost of bought Jokers", "This Joker loses Mult equal to", "the sell value of sold Jokers", "(Currently +#1# Mult)"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        local st = card.ability.extra
        if context.buying_card and context.port
                and context.port.offer_kind == "joker" then
            -- PORT NOTE: PC adds the bought Joker's listed cost; the fork's
            -- shop event carries the price actually paid (offer_price),
            -- which equals the listed cost in a vanilla shop.
            st.mult = st.mult + (tonumber(context.port.offer_price) or 0)
            return { message = "Upgrade!" }
        end
        if context.selling_card then
            local sold = context.card or (context.port and context.port.joker)
            if sold ~= nil and sold ~= card and not context.selling_self then
                local value = tonumber(sold.sell_cost)
                    or tonumber(context.port and context.port.sold_value) or 0
                st.mult = math.max(0, st.mult - value)
                return { message = "Downgrade!" }
            end
        end
        if context.joker_main and st.mult ~= 0 then
            return { mult = st.mult }
        end
    end,
}

-- hole_in_one
SMODS.Joker {
    key = "hole_in_one",
    name = "Hole in One",
    rarity = 3,
    cost = 8,
    sprite = "hole_in_one.png",
    negative_sprite = "hole_in_one_negative.png",
    config = { extra = { money_max = 9, hands = 0 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return { vars = { card.ability.extra.money_max } }
    end,
    loc_txt = { name = "Hole in One", text = {"If first hand of round cleared the", "Blind, double the sell value of all cards", "(Max of $#1# per round)", "When this Joker is sold, set the", "sell value of all cards to $0"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        local st = card.ability.extra
        if context.before then
            st.hands = st.hands + 1
        end
        if context.end_of_round and not context.game_over then
            local quick = st.hands <= 1
            st.hands = 0
            if quick then
                -- PORT NOTE: sell values are raised directly on the held
                -- Joker/consumable objects (no sell-value API in the fork).
                for _, j in ipairs(pb2_joker_list()) do
                    if tonumber(j.sell_cost) then
                        j.sell_cost = j.sell_cost + math.min(j.sell_cost, st.money_max)
                    end
                end
                if G and type(G.consumables) == "table" then
                    for _, c in ipairs(G.consumables) do
                        if type(c) == "table" and tonumber(c.sell_cost) then
                            c.sell_cost = c.sell_cost + math.min(c.sell_cost, st.money_max)
                        end
                    end
                end
                return { message = "Value Up!" }
            end
        end
        if context.selling_card then
            local sold = context.card or (context.port and context.port.joker)
            if context.selling_self or sold == nil or sold == card then
                for _, j in ipairs(pb2_joker_list()) do
                    if j ~= card and tonumber(j.sell_cost) then j.sell_cost = 0 end
                end
                if G and type(G.consumables) == "table" then
                    for _, c in ipairs(G.consumables) do
                        if type(c) == "table" and tonumber(c.sell_cost) then
                            c.sell_cost = 0
                        end
                    end
                end
                return { message = "Value Down!" }
            end
        end
    end,
}

-- hotel_guest
SMODS.Joker {
    key = "hotel_guest",
    name = "Hotel Guest",
    rarity = 3,
    cost = 5,
    sprite = "hotel_guest.png",
    negative_sprite = "hotel_guest_negative.png",
    config = { extra = { mult_per_queen = 0.5 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        local queens = 0
        if G and G.hand and G.hand.card_nodes then
            for _, node in ipairs(G.hand.card_nodes) do
                if node.card_data and tonumber(node.card_data.rank) == 12 then
                    queens = queens + 1
                end
            end
        end
        return { vars = { card.ability.extra.mult_per_queen,
            1 + queens * card.ability.extra.mult_per_queen } }
    end,
    loc_txt = { name = "Hotel Guest", text = {"Gives X#1# Mult for each", "Queen held in hand", "(Currently X#2# Mult)"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.joker_main then
            local queens = 0
            if G and G.hand and G.hand.card_nodes then
                for _, node in ipairs(G.hand.card_nodes) do
                    if node.card_data and tonumber(node.card_data.rank) == 12 then
                        queens = queens + 1
                    end
                end
            end
            local x = 1 + queens * card.ability.extra.mult_per_queen
            if x > 1 then return { xmult = x } end
        end
    end,
}

-- i_wish_that_i_could_fall
SMODS.Joker {
    key = "i_wish_that_i_could_fall",
    name = "I Wish That I Could Fall",
    rarity = 3,
    cost = 7,
    sprite = "i_wish_that_i_could_fall.png",
    negative_sprite = "i_wish_that_i_could_fall_negative.png",
    config = { extra = { chips = 0, chip_gain = 4 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        local st = card.ability.extra
        return { vars = { st.chip_gain, st.chips } }
    end,
    loc_txt = { name = "I Wish That I Could Fall", text = {"When a card is scored, this", "Joker decreases the card's", "rank and gains +#1# Chips", "(2 -> Ace -> King)", "(Currently +#2# Chips)"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        local st = card.ability.extra
        if context.individual and context.cardarea == G.play and context.other_card
                and context.other_card.card_data then
            -- PORT NOTE: PC lowers the rank through SMODS.modify_rank; the
            -- fork has no rank-change API, so card_data.rank/chips are
            -- rewritten directly (2 wraps to Ace, Ace to King). The PC
            -- animated atlas, shader and music are not ported.
            pb2_rank_down(context.other_card.card_data)
            st.chips = st.chips + st.chip_gain
            return { message = "Fall!" }
        end
        if context.joker_main and st.chips > 0 then
            return { chips = st.chips }
        end
    end,
}

-- ice_cube
SMODS.Joker {
    key = "ice_cube",
    name = "Ice Cube",
    rarity = 1,
    cost = 4,
    sprite = "ice_cube.png",
    negative_sprite = "ice_cube_negative.png",
    config = { extra = { hands = 1 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return { vars = { card.ability.extra.hands } }
    end,
    loc_txt = { name = "Ice Cube", text = {"+#1# Hand when Blind is selected", "Melts if score catches fire"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.setting_blind and G then
            G.hands = (tonumber(G.hands) or 0) + card.ability.extra.hands
            return { message = "+1 Hand" }
        end
        if context.after and G then
            -- PORT NOTE: PC melts on SMODS.last_hand_oneshot (the hand's
            -- score catching fire); the fork does not expose that flag, so
            -- this melts when the just-played hand's score alone meets the
            -- current Blind target, the closest observable equivalent.
            local target = tonumber(G.current_blind_target) or 0
            local score = tonumber(G.last_hand_score) or 0
            if target > 0 and score >= target then
                if SMODS.destroy_joker then SMODS.destroy_joker(card) end
                return { message = "Melted!" }
            end
        end
    end,
}

-- inner_peace
SMODS.Joker {
    key = "inner_peace",
    name = "Inner Peace",
    rarity = 2,
    cost = 6,
    sprite = "inner_peace.png",
    negative_sprite = "inner_peace_negative.png",
    config = { extra = { h_size = 3, applied = false } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return { vars = { card.ability.extra.h_size } }
    end,
    loc_txt = { name = "Inner Peace", text = {"+#1# hand size", "before first hand", "of round is played"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        local st = card.ability.extra
        -- PORT NOTE: PC adds real hand size until the first hand is played.
        -- The fork exposes hand size only as summed game deltas, so the
        -- bonus rides G.hand_size_delta_juggle additively and is removed
        -- on the first played hand; the opening draw itself is not grown
        -- (it happens before the round-begin event), only refills are.
        if context.first_hand_drawn and not st.applied and G then
            G.hand_size_delta_juggle = (tonumber(G.hand_size_delta_juggle) or 0) + st.h_size
            st.applied = true
        end
        if context.before and st.applied and G then
            G.hand_size_delta_juggle = (tonumber(G.hand_size_delta_juggle) or 0) - st.h_size
            st.applied = false
        end
    end,
}

-- its_tv_time
SMODS.Joker {
    key = "its_tv_time",
    name = "It's TV Time!",
    rarity = 1,
    cost = 5,
    sprite = "its_tv_time.png",
    negative_sprite = "its_tv_time_negative.png",
    config = { extra = { chips = 30 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return { vars = { "Stars", card.ability.extra.chips } }
    end,
    loc_txt = { name = "It's TV Time!", text = {"Played Stars give", "+#2# chips when scored"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.individual and context.cardarea == G.play and context.other_card
                and context.other_card.is_suit and context.other_card:is_suit("Stars") then
            return { chips = card.ability.extra.chips }
        end
    end,
}

-- jester
SMODS.Joker {
    key = "jester",
    name = "Jester",
    rarity = 2,
    cost = 7,
    sprite = "jester.png",
    negative_sprite = "jester_negative.png",
    config = { extra = { busy = false } },
    loc_txt = { name = "Jester", text = {"Whenever a card is destroyed, also", "destroy a random card in your full deck"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        local st = card.ability.extra
        if context.remove_playing_cards and context.port
                and context.port.destroyed_cards and #context.port.destroyed_cards > 0
                and not st.busy and G then
            st.busy = true
            local pool = {}
            if G.count_cards_in_full_deck and G.deck then
                local destroyed = {}
                for _, d in ipairs(context.port.destroyed_cards) do
                    local data = d.card_data or d
                    if data and data.uid ~= nil then destroyed[data.uid] = true end
                end
                local function add_all(list)
                    for _, data in ipairs(type(list) == "table" and list or {}) do
                        if type(data) == "table" and not destroyed[data.uid] then
                            pool[#pool + 1] = data
                        end
                    end
                end
                add_all(G.deck.cards)
                add_all(G.deck.discard_pile)
                if G.hand and G.hand.card_nodes then
                    for _, node in ipairs(G.hand.card_nodes) do
                        if node.card_data and not destroyed[node.card_data.uid] then
                            pool[#pool + 1] = node.card_data
                        end
                    end
                end
            end
            local n = math.min(#context.port.destroyed_cards, #pool)
            local done = false
            for _ = 1, n do
                if SMODS.pseudorandom and SMODS.destroy_card then
                    local idx = SMODS.pseudorandom("pb2_jester", 1, #pool)
                    local victim = table.remove(pool, idx)
                    if victim and SMODS.destroy_card(victim) then done = true end
                end
            end
            st.busy = false
            if done then return { message = "Destroyed!" } end
        end
    end,
}

-- jestosterone
SMODS.Joker {
    key = "jestosterone",
    name = "Jestosterone",
    rarity = 1,
    cost = 5,
    sprite = "jestosterone.png",
    negative_sprite = "jestosterone_negative.png",
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return { vars = { "Queen", "King" } }
    end,
    loc_txt = { name = "Jestosterone", text = {"Scored Queens become Kings"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.after and context.scoring_hand then
            -- PORT NOTE: PC rewrites the rank through SMODS.change_base; the
            -- fork has no rank-change API, so card_data is rewritten
            -- directly (rank and its base Chip value).
            local changed = false
            for _, view in ipairs(context.scoring_hand) do
                if view.card_data and tonumber(view.card_data.rank) == 12 then
                    view.card_data.rank = 13
                    view.card_data.chips = 10
                    changed = true
                end
            end
            if changed then return { message = "Jestosterone!" } end
        end
    end,
}

-- jestrogen
SMODS.Joker {
    key = "jestrogen",
    name = "Jestrogen",
    rarity = 1,
    cost = 5,
    sprite = "jestrogen.png",
    negative_sprite = "jestrogen_negative.png",
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return { vars = { "King", "Jack", "Queen" } }
    end,
    loc_txt = { name = "Jestrogen", text = {"Scored Kings and Jacks become Queens"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.after and context.scoring_hand then
            local changed = false
            for _, view in ipairs(context.scoring_hand) do
                local rank = view.card_data and tonumber(view.card_data.rank)
                if rank == 11 or rank == 13 then
                    view.card_data.rank = 12
                    view.card_data.chips = 10
                    changed = true
                end
            end
            if changed then return { message = "Jestrogen!" } end
        end
    end,
}

-- jimbos_inferno
SMODS.Joker {
    key = "jimbos_inferno",
    name = "Jimbo's Inferno",
    rarity = 1,
    cost = 5,
    sprite = "jimbos_inferno.png",
    negative_sprite = "jimbos_inferno_negative.png",
    config = { extra = { mult_per_dark = 2 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        local dark = 0
        if G and G.hand and G.hand.card_nodes then
            for _, node in ipairs(G.hand.card_nodes) do
                if pb2_is_dark(node) then dark = dark + 1 end
            end
        end
        return { vars = { card.ability.extra.mult_per_dark,
            dark * card.ability.extra.mult_per_dark } }
    end,
    loc_txt = { name = "Jimbo's Inferno", text = {"Scored dark suits give", "+#1# Mult for every", "dark suit held in hand", "(Currently +#2# Mult)"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.individual and context.cardarea == G.play and context.other_card
                and pb2_is_dark(context.other_card) then
            local dark = 0
            if G and G.hand and G.hand.card_nodes then
                for _, node in ipairs(G.hand.card_nodes) do
                    if pb2_is_dark(node) then dark = dark + 1 end
                end
            end
            local give = dark * card.ability.extra.mult_per_dark
            if give > 0 then return { mult = give } end
        end
    end,
}

-- jimbos_joyous_joker_jamboree
SMODS.Joker {
    key = "jimbos_joyous_joker_jamboree",
    name = "Jimbo's Joyous Joker Jamboree",
    rarity = 2,
    cost = 6,
    sprite = "jimbos_joyous_joker_jamboree.png",
    negative_sprite = "jimbos_joyous_joker_jamboree_negative.png",
    config = { extra = { required = 13, count = 0 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        local st = card.ability.extra
        return { vars = { st.required, st.required - (st.count % st.required) } }
    end,
    loc_txt = { name = "Jimbo's Joyous Joker Jamboree", text = {"Create a random Minor Arcana card", "for every #1# [#2#] scored cards", "(Must have room)"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        local st = card.ability.extra
        if context.individual and context.cardarea == G.play then
            st.count = st.count + 1
            if st.count % st.required == 0 then
                if pb2_spawn_consumable("minor_arcana") then
                    return { message = "+Minor Arcana!" }
                end
            end
        end
    end,
}

-- joke_master
SMODS.Joker {
    key = "joke_master",
    name = "Joke Master",
    rarity = 1,
    cost = 3,
    sprite = "joke_master.png",
    negative_sprite = "joke_master_negative.png",
    config = { extra = { mult = 0, a_mult = 2, target = nil } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        local st = card.ability.extra
        return { vars = { st.a_mult, st.target or "Pair", st.mult } }
    end,
    loc_txt = { name = "Joke Master", text = {"This Joker gains +#1# Mult if", "played hand is a #2#", "hand changes every round", "(Currently +#3# Mult)"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        local st = card.ability.extra
        if context.first_hand_drawn and G and G.handlist and SMODS.pseudorandom then
            -- PORT NOTE: PC's target hand is chosen by Paperback's own run
            -- state; the port rolls a random hand from G.handlist each
            -- round (the PC weighting across hand types is not ported).
            st.target = G.handlist[SMODS.pseudorandom("pb2_joke_master", 1, #G.handlist)]
        end
        if context.before and st.target
                and context.poker_hands and next(context.poker_hands[st.target]) then
            st.mult = st.mult + st.a_mult
            return { message = "Upgrade!" }
        end
        if context.joker_main and st.mult > 0 then
            return { mult = st.mult }
        end
    end,
}

-- joker_cd_i
SMODS.Joker {
    key = "joker_cd_i",
    name = "Joker CD-i",
    rarity = 1,
    cost = 3,
    sprite = "joker_cd_i.png",
    negative_sprite = "joker_cd_i_negative.png",
    config = { extra = { odds = 2, cards = 4 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        local num, den = pb2_prob_vars(card, 1, card.ability.extra.odds, "paperback_joker_cd_i")
        return { vars = { num, den, card.ability.extra.cards } }
    end,
    loc_txt = { name = "Joker CD-i", text = {"#1# in #2# chance to create", "a random Planet card if", "played hand has exactly #3# cards", "(Must have room)"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.before and context.full_hand
                and #context.full_hand == card.ability.extra.cards then
            if SMODS.pseudorandom_probability
                    and SMODS.pseudorandom_probability(card, "pb2_joker_cd_i", 1,
                        card.ability.extra.odds, "paperback_joker_cd_i") then
                if pb2_spawn_consumable("planet") then
                    return { message = "+Planet!" }
                end
            end
        end
    end,
}

-- joker_cookie
SMODS.Joker {
    key = "joker_cookie",
    name = "Joker Cookie",
    rarity = 1,
    cost = 1,
    sprite = "joker_cookie.png",
    negative_sprite = "joker_cookie_negative.png",
    config = { extra = { dollar_bonus = 1, dollar_gain = 2, dollar_max = 11, odds = 5, cashed = false } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        local st = card.ability.extra
        local num, den = pb2_prob_vars(card, 1, st.odds, "paperback_joker_cookie")
        return { vars = { st.dollar_bonus, st.dollar_gain, st.dollar_max, num, den } }
    end,
    loc_txt = { name = "Joker Cookie", text = {"Earn $#1# at end of round", "Payout increases by $#2# when cashing out", "#4# in #5# chance this card", "is eaten at end of round", "(Max of $#3#)"} },
    calc_dollar_bonus = function(self, card)
        return tonumber(card.ability.extra.dollar_bonus) or 0
    end,
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        local st = card.ability.extra
        if context.end_of_round and not context.game_over then
            -- PORT NOTE: PC grows the payout on its cashing_out beat, which
            -- the fork folds into the round-end payout; the port grows the
            -- bonus after each survived round instead (same cadence: one
            -- growth per cash-out) and rolls the eating chance there too.
            if st.cashed and st.dollar_bonus < st.dollar_max then
                st.dollar_bonus = math.min(st.dollar_max, st.dollar_bonus + st.dollar_gain)
            end
            st.cashed = true
            if SMODS.pseudorandom_probability
                    and SMODS.pseudorandom_probability(card, "pb2_joker_cookie", 1,
                        st.odds, "paperback_joker_cookie") then
                if SMODS.destroy_joker then SMODS.destroy_joker(card) end
                return { message = "Eaten!" }
            end
            return { message = "Safe!" }
        end
    end,
}

-- joker_crossing
SMODS.Joker {
    key = "joker_crossing",
    name = "Joker Crossing",
    rarity = 2,
    cost = 8,
    sprite = "joker_crossing.png",
    negative_sprite = "joker_crossing_negative.png",
    config = { extra = { odds = 3 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        local num, den = pb2_prob_vars(card, 1, card.ability.extra.odds, "paperback_joker_crossing")
        return { vars = { num, den } }
    end,
    loc_txt = { name = "Joker Crossing", text = {"Enhanced cards", "have a #1# in #2#", "chance to retrigger"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.repetition and context.other_card and context.other_card.card_data then
            local in_play = context.cardarea == G.play
            local in_hand = G and context.cardarea == G.hand
            if (in_play or in_hand)
                    and context.other_card.card_data.enhancement ~= nil then
                -- PORT NOTE: PC's held-in-hand branch also requires the held
                -- card to have scored effects this hand; the fork's
                -- retrigger query carries no card_effects, so held enhanced
                -- cards roll on the same terms as played ones.
                if SMODS.pseudorandom_probability
                        and SMODS.pseudorandom_probability(card, "pb2_joker_crossing", 1,
                            card.ability.extra.odds, "paperback_joker_crossing") then
                    return { repetitions = 1, message = "Again!" }
                end
            end
        end
    end,
}

-- joker_duty
SMODS.Joker {
    key = "joker_duty",
    name = "Joker Duty",
    rarity = 1,
    cost = 6,
    sprite = "joker_duty.png",
    negative_sprite = "joker_duty_negative.png",
    config = { extra = { mult = 0, change = 3 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        local st = card.ability.extra
        return { vars = { st.change, st.mult } }
    end,
    loc_txt = { name = "Joker Duty", text = {"This Joker gains +#1# Mult if", "round was cleared with", "equal hands and discards", "(Currently +#2# Mult)"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        local st = card.ability.extra
        if context.joker_main and st.mult > 0 then
            return { mult = st.mult }
        end
        if context.end_of_round and not context.game_over and G then
            local hands_left = tonumber(G.hands) or 0
            local discards_left = tonumber(G.discards) or 0
            if discards_left == hands_left then
                st.mult = st.mult + st.change
                return { message = "Upgrade!" }
            end
        end
    end,
}

-- joker_jacks
SMODS.Joker {
    key = "joker_jacks",
    name = "Joker Jacks",
    rarity = 1,
    cost = 6,
    sprite = "joker_jacks.png",
    negative_sprite = "joker_jacks_negative.png",
    config = { extra = { dollars = 3, m_dollars = 1 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        local st = card.ability.extra
        return { vars = { st.dollars, "Jack", st.m_dollars } }
    end,
    loc_txt = { name = "Joker Jacks", text = {"Scored Jacks give $#1#", "Decreases by $#3#", "at end of round", "Create a prize", "after being consumed", "(Must have room)"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        local st = card.ability.extra
        if context.individual and context.cardarea == G.play and context.other_card
                and context.other_card.get_id and context.other_card:get_id() == 11 then
            return { dollars = st.dollars }
        end
        if context.end_of_round and not context.game_over then
            if st.dollars - st.m_dollars < 1 then
                -- PORT NOTE: PC's prize table also weights Minor Arcana
                -- when that set is enabled; the port's table is Planet x3,
                -- Tarot x3, Spectral x1 (the arcana-off weights).
                local kinds = { "planet", "planet", "planet",
                    "tarot", "tarot", "tarot", "spectral" }
                if SMODS.pseudorandom then
                    local kind = kinds[SMODS.pseudorandom("pb2_joker_jacks", 1, #kinds)]
                    pb2_spawn_consumable(kind)
                end
                if SMODS.destroy_joker then SMODS.destroy_joker(card) end
                return { message = "Consumed!" }
            end
            st.dollars = st.dollars - st.m_dollars
            return { message = "-$" .. st.m_dollars }
        end
    end,
}

-- journal
SMODS.Joker {
    key = "journal",
    name = "Journal",
    rarity = 2,
    cost = 6,
    sprite = "journal.png",
    negative_sprite = "journal_negative.png",
    config = { extra = { chips = 0, next_chips = 0 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return { vars = { card.ability.extra.chips } }
    end,
    loc_txt = { name = "Journal", text = {"This Joker gives the", "total Chips of", "the previous hand.", "(Currently +#1# Chips)"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        local st = card.ability.extra
        if context.before then
            st.chips = st.next_chips
            st.next_chips = 0
        end
        if context.joker_main then
            local total = tonumber(context.port and context.port.chips) or 0
            if total > 0 then st.next_chips = total end
            if st.chips > 0 then return { chips = st.chips } end
        end
    end,
}

-- keycard
SMODS.Joker {
    key = "keycard",
    name = "Keycard",
    rarity = 2,
    cost = 5,
    sprite = "keycard.png",
    negative_sprite = "keycard_negative.png",
    config = { extra = { dollars = 25, active = false } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return { vars = { card.ability.extra.dollars } }
    end,
    loc_txt = { name = "Keycard", text = {"After defeating a Boss Blind,", "this Joker self-destructs", "and gives $#1# after cashing out"} },
    calc_dollar_bonus = function(self, card)
        if card.ability.extra.active then
            return tonumber(card.ability.extra.dollars) or 0
        end
        return 0
    end,
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        local st = card.ability.extra
        if context.end_of_round and not context.game_over and pb2_boss(context) then
            -- PORT NOTE: PC arms on the Boss falling and pays + destroys
            -- itself on the separate cashing_out beat; the fork folds
            -- cash-out into the round-end payout, so the port arms, pays
            -- through calc_dollar_bonus in the same payout, and destroys
            -- itself on the following round end.
            if st.active then
                st.active = false
                if SMODS.destroy_joker then SMODS.destroy_joker(card) end
                return { message = "Destroyed!" }
            end
            st.active = true
            return { message = "Active!" }
        end
        if context.end_of_round and not context.game_over and st.active then
            st.active = false
            if SMODS.destroy_joker then SMODS.destroy_joker(card) end
            return { message = "Destroyed!" }
        end
    end,
}

-- king_me
SMODS.Joker {
    key = "king_me",
    name = "King Me",
    rarity = 1,
    cost = 6,
    sprite = "king_me.png",
    negative_sprite = "king_me_negative.png",
    config = { extra = { rank_mod = 1 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return { vars = { "Crowns", card.ability.extra.rank_mod } }
    end,
    loc_txt = { name = "King Me", text = {"Scored non-King Crowns", "increase their rank by #2#"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.after and context.scoring_hand then
            -- PORT NOTE: PC raises ranks through SMODS.modify_rank; the
            -- fork has no rank-change API, so card_data is rewritten
            -- directly (rank capped at Ace; base Chips follow the rank).
            local changed = false
            for _, view in ipairs(context.scoring_hand) do
                local data = view.card_data
                if data and view.is_suit and view:is_suit("Crowns") then
                    local rank = tonumber(data.rank) or 0
                    if rank > 0 and rank ~= 13 and rank < 14 then
                        local new_rank = math.min(14, rank + card.ability.extra.rank_mod)
                        data.rank = new_rank
                        data.chips = PB2_FACE_CHIPS[new_rank] or new_rank
                        changed = true
                    end
                end
            end
            if changed then return { message = "Upgrade!" } end
        end
    end,
}

-- legacy
SMODS.Joker {
    key = "legacy",
    name = "Legacy",
    rarity = 3,
    cost = 8,
    sprite = "legacy.png",
    negative_sprite = "legacy_negative.png",
    config = { extra = { mult = 0 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return { vars = { card.ability.extra.mult } }
    end,
    loc_txt = { name = "Legacy", text = {"When a non-Enhanced card is", "destroyed, add its Chip value", "as Mult to this Joker", "(Currently +#1# Mult)"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        local st = card.ability.extra
        if context.remove_playing_cards and context.port
                and context.port.destroyed_cards then
            local gained = 0
            for _, item in ipairs(context.port.destroyed_cards) do
                local view = item
                local data = (item and item.card_data) or item or {}
                if data.enhancement == nil then
                    gained = gained + pb2_chip_value(view)
                end
            end
            if gained > 0 then
                st.mult = st.mult + gained
                return { message = "+" .. gained .. " Mult" }
            end
        end
        if context.joker_main and st.mult > 0 then
            return { mult = st.mult }
        end
    end,
}

-- loaded_dice
SMODS.Joker {
    key = "loaded_dice",
    name = "Loaded Dice",
    rarity = 1,
    cost = 6,
    sprite = "loaded_dice.png",
    negative_sprite = "loaded_dice_negative.png",
    config = { extra = { a_odds = 1, triggered = false } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        local a = card.ability.extra.a_odds
        return { vars = { (a >= 0 and "+" or "") .. a, "Crowns" } }
    end,
    loc_txt = { name = "Loaded Dice", text = {"Adds #1# to all listed probabilities", "if hand contains a scoring Crowns"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        local st = card.ability.extra
        if context.before and context.scoring_hand then
            st.triggered = false
            for _, view in ipairs(context.scoring_hand) do
                if view.is_suit and view:is_suit("Crowns") then
                    st.triggered = true
                    break
                end
            end
        end
        if context.mod_probability and st.triggered then
            return { numerator = (context.numerator or 0) + st.a_odds }
        end
        if context.after then
            st.triggered = false
        end
    end,
}

-- lone_digger
SMODS.Joker {
    key = "lone_digger",
    name = "Lone Digger",
    rarity = 3,
    cost = 8,
    sprite = "lone_digger.png",
    negative_sprite = "lone_digger_negative.png",
    loc_txt = { name = "Lone Digger", text = {"If scored hand has only", "one face card, retrigger it", "for each scored card"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.repetition and context.cardarea == G.play and context.other_card then
            local rank = context.other_card.get_id and context.other_card:get_id() or 0
            if rank >= 11 and rank <= 13 then
                local scoring = pb2_scoring_views(context)
                local faces = 0
                for _, view in ipairs(scoring) do
                    local r = view.get_id and view:get_id() or 0
                    if r >= 11 and r <= 13 then faces = faces + 1 end
                end
                if faces == 1 and #scoring > 0 then
                    return { repetitions = #scoring }
                end
            end
        end
    end,
}

-- lurid_joker
SMODS.Joker {
    key = "lurid_joker",
    name = "Lurid Joker",
    rarity = 1,
    cost = 3,
    sprite = "lurid_joker.png",
    negative_sprite = "lurid_joker_negative.png",
    config = { extra = { t_chips = 80 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return { vars = { card.ability.extra.t_chips, "Spectrum" } }
    end,
    loc_txt = { name = "Lurid Joker", text = {"+#1# Chips if played", "hand contains", "a #2#"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.joker_main and context.poker_hands
                and next(context.poker_hands["Spectrum"]) then
            return { chips = card.ability.extra.t_chips }
        end
    end,
}

-- man
SMODS.Joker {
    key = "man",
    name = "Man",
    rarity = 2,
    cost = 7,
    sprite = "man.png",
    negative_sprite = "man_negative.png",
    config = { extra = { perma_mult = 1 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return { vars = { card.ability.extra.perma_mult } }
    end,
    loc_txt = { name = "Man", text = {"Played dark suit cards", "permanently gain +#1# Mult", "when scored"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.individual and context.cardarea == G.play and context.other_card
                and pb2_is_dark(context.other_card) and context.other_card.card_data then
            -- PORT NOTE: PC adds to the card's ability.perma_mult, which the
            -- fork's scoring reads as card_data.mult_bonus; the bonus is
            -- stored there instead.
            local data = context.other_card.card_data
            data.mult_bonus = (tonumber(data.mult_bonus) or 0) + card.ability.extra.perma_mult
            return { message = "Upgrade!" }
        end
    end,
}

-- mandela_effect
SMODS.Joker {
    key = "mandela_effect",
    name = "Mandela Effect",
    rarity = 1,
    cost = 4,
    sprite = "mandela_effect.png",
    negative_sprite = "mandela_effect_negative.png",
    loc_txt = { name = "Mandela Effect", text = {"Randomly enhance the first", "scored face card each hand"} },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.before and context.scoring_hand then
            -- PORT NOTE: PC polls a random enhancement weighted by a
            -- ranked-enhancement table the fork does not have; the port
            -- picks uniformly from the 8 vanilla enhancements and writes
            -- card_data.enhancement directly (no enhancement API).
            local enhancements = { "bonus", "mult", "wild", "glass",
                "steel", "stone", "gold", "lucky" }
            for _, view in ipairs(context.scoring_hand) do
                local rank = view.get_id and view:get_id() or 0
                if rank >= 11 and rank <= 13 then
                    if not view.debuff and view.card_data and SMODS.pseudorandom then
                        local pick = enhancements[SMODS.pseudorandom("pb2_mandela", 1, #enhancements)]
                        view.card_data.enhancement = pick
                        return { message = "Enhanced!" }
                    end
                    break
                end
            end
        end
    end,
}
end

--------------------------------------------------------------------------------
-- Expansion Jokers, slice 3 (marble_soda .. shuttle)
-- Ported from Paperback's MIT-licensed sources against the fork API.
-- Sub-effect deviations are marked with PORT NOTE comments inline.
--------------------------------------------------------------------------------
do
-- PaperbackPack fragment 3: Paperback Jokers (slice 3 of 4) for Balatro3DS.
-- Loads after paperbackpack.lua; registers 50 Jokers against the fork API.
-- Ported effect-by-effect from Paperback's MIT-licensed PC sources.
-- Deviations from PC are marked with -- PORT NOTE: at the Joker they affect.

local G

local function pb3_round2(x)
    return math.floor(x * 100 + 0.5) / 100
end

-- Held Jokers as a plain list (the game keeps G.jokers as a list; some
-- contexts expose a .cards sub-table instead).
local function pb3_jokers()
    if not G then return {} end
    local list = G.jokers
    if type(list) == "table" and type(list.cards) == "table" then return list.cards end
    if type(list) == "table" then return list end
    return {}
end

local function pb3_joker_id(j)
    if type(j) ~= "table" then return nil end
    if j.def and j.def.id then return j.def.id end
    return j.def_id or j.id or j.center_key or j.key
end

local function pb3_id(view)
    if not view then return 0 end
    if type(view.get_id) == "function" then return view:get_id() or 0 end
    local data = view.card_data or view
    return tonumber(data.rank) or 0
end

local function pb3_is_face(view)
    local id = pb3_id(view)
    return id >= 11 and id <= 13
end

local function pb3_nominal(view)
    local id = pb3_id(view)
    if id == 14 then return 11 end
    if id >= 11 then return 10 end
    return id
end

local PB3_LIGHT = { Hearts = true, Diamonds = true, Stars = true }
local PB3_DARK = { Spades = true, Clubs = true, Crowns = true }

local function pb3_is_light(view)
    if not view then return false end
    if type(view.is_suit) == "function" then
        return view:is_suit("Hearts") or view:is_suit("Diamonds")
            or view:is_suit("Stars")
    end
    local data = view.card_data or {}
    if data.enhancement == "stone" then return false end
    if data.enhancement == "wild" then return true end
    return PB3_LIGHT[data.suit] == true
end

local function pb3_is_suit(view, suit)
    if not view then return false end
    if type(view.is_suit) == "function" then return view:is_suit(suit) end
    local data = view.card_data or {}
    if data.enhancement == "stone" then return false end
    if data.enhancement == "wild" then return true end
    return data.suit == suit
end

-- Distinct suits among views; a Wild card flexes as one extra suit when
-- wild_extra is set (PC get_unique_suits with the wild flag).
local function pb3_unique_suits(views, wild_extra, skip_debuff)
    local seen, wild = {}, false
    for _, view in ipairs(type(views) == "table" and views or {}) do
        if not (skip_debuff and view.debuff) then
            local data = view.card_data or {}
            if data.enhancement == "wild" then
                wild = true
                if data.suit then seen[data.suit] = true end
            elseif data.enhancement ~= "stone" and data.suit then
                seen[data.suit] = true
            end
        end
    end
    local n = 0
    for _ in pairs(seen) do n = n + 1 end
    if wild_extra and wild then n = math.min(6, n + 1) end
    return n
end

local function pb3_hit(card, num, den, seed)
    if SMODS.pseudorandom_probability then
        local hit = SMODS.pseudorandom_probability(card, seed, num, den, seed)
        return hit == true
    end
    return false
end

local function pb3_prob_vars(card, num, den, seed)
    if SMODS.get_probability_vars then
        return SMODS.get_probability_vars(card, num, den, seed)
    end
    return num, den
end

local function pb3_spawn_planet(hand_name)
    if not hand_name or not G or not G.random_planet_id_for_hand_name
        or not SMODS.add_card then
        return nil
    end
    local id = G:random_planet_id_for_hand_name(hand_name)
    if not id then return nil end
    return SMODS.add_card { set = "Planet", key = id }
end

local function pb3_spawn_tarot()
    if not G or not G.random_consumable_id_of_kind or not SMODS.add_card then
        return nil
    end
    local id = G:random_consumable_id_of_kind("tarot")
    if not id then return nil end
    return SMODS.add_card { set = "Tarot", key = id }
end

local function pb3_hands_played()
    if not G then return 0 end
    if type(G.get_round_hands_played) == "function" then
        return tonumber(G:get_round_hands_played()) or 0
    end
    return tonumber(G.round_hands_played) or 0
end

local function pb3_hand_index(name)
    if not G or type(G.handlist) ~= "table" then return nil end
    for i, n in ipairs(G.handlist) do
        if n == name then return i end
    end
    return nil
end

local function pb3_hand_level(name)
    local idx = pb3_hand_index(name)
    local stats = idx and G and G.hand_stats and G.hand_stats[idx]
    if not stats then return nil end
    return tonumber(stats.level) or 1
end

local PB3_SUITS = { "Hearts", "Diamonds", "Clubs", "Spades", "Stars", "Crowns" }

local PB3_STICKS = {
    j_pbp_bamboo_stick = true, j_pbp_pointy_stick = true,
    j_pbp_pop_stick = true, j_pbp_popsicle_stick = true,
    j_pbp_rockin_stick = true, j_pbp_sticky_stick = true,
    j_pbp_sweet_stick = true,
    bamboo_stick = true, pointy_stick = true, pop_stick = true,
    popsicle_stick = true, rockin_stick = true, sticky_stick = true,
    sweet_stick = true,
}

local function pb3_is_stick(j)
    local id = pb3_joker_id(j)
    return id ~= nil and PB3_STICKS[id] == true
end

local function pb3_other_sticks(card)
    local n = 0
    for _, j in ipairs(pb3_jokers()) do
        if j ~= card and pb3_is_stick(j) then n = n + 1 end
    end
    return n
end

-- Cards marked for destruction at the after pass (Mind Electric, Power
-- Surge), keyed by the owning Joker; runtime-only, never saved.
local pb3_marks = setmetatable({}, { __mode = "k" })
local function pb3_mark(card, view)
    if not view then return end
    local list = pb3_marks[card]
    if not list then list = {} pb3_marks[card] = list end
    list[#list + 1] = view
end
local function pb3_flush_marks(card)
    local list = pb3_marks[card]
    pb3_marks[card] = nil
    if not list or not SMODS.destroy_card then return end
    for _, view in ipairs(list) do SMODS.destroy_card(view) end
end

-- Red Key's temporary Joker, keyed by the Red Key; runtime-only.
local pb3_temp = setmetatable({}, { __mode = "k" })

-- marble_soda
SMODS.Joker {
    key = "marble_soda",
    name = "Marble Soda",
    rarity = 2,
    cost = 6,
    sprite = "marble_soda.png",
    negative_sprite = "marble_soda_negative.png",
    config = { extra = { xmult = 1.5, drank_after = 5 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return { vars = { "Glass Cards", card.ability.extra.xmult,
            card.ability.extra.drank_after } }
    end,
    loc_txt = { name = "Marble Soda", text = {
        "Scored #1# give X#2# Mult",
        "Destroyed after #3# more playing",
        "cards are destroyed",
    } },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.individual and context.cardarea == G.play
            and context.other_card and context.other_card.card_data
            and context.other_card.card_data.enhancement == "glass" then
            return { xmult = card.ability.extra.xmult }
        end
        if context.remove_playing_cards and context.port
            and context.port.destroyed_cards
            and #context.port.destroyed_cards > 0 then
            local st = card.ability.extra
            st.drank_after = math.max(0, st.drank_after - #context.port.destroyed_cards)
            if st.drank_after <= 0 then
                if SMODS.destroy_joker then SMODS.destroy_joker(card) end
                return { message = "Drank!" }
            end
        end
    end,
}

-- master_spark
-- PORT NOTE: PC destroys held cards through the destroy_card context,
-- which the fork never raises; held cards are destroyed directly at the
-- after pass instead (same set, one beat later). Played cards are made
-- Polychrome by writing card_data.modifier.edition (Bunco precedent).
SMODS.Joker {
    key = "master_spark",
    name = "Master Spark",
    rarity = 3,
    cost = 8,
    sprite = "master_spark.png",
    negative_sprite = "master_spark_negative.png",
    config = { extra = { ready = false } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return { vars = { "Spectrum", "Polychrome" } }
    end,
    loc_txt = { name = "Master Spark", text = {
        "If played hand contains a Spectrum,",
        "destroy all cards held in hand and",
        "all played cards become Polychrome",
        "Self-destructs",
    } },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.before then
            if next(context.poker_hands["Spectrum"])
                or next(context.poker_hands["Straight Spectrum"])
                or next(context.poker_hands["Spectrum House"])
                or next(context.poker_hands["Spectrum Five"]) then
                card.ability.extra.ready = true
            end
        end
        if context.after and card.ability.extra.ready then
            card.ability.extra.ready = false
            if G and G.hand and G.hand.card_nodes and SMODS.destroy_card then
                local held = {}
                for _, node in ipairs(G.hand.card_nodes) do held[#held + 1] = node end
                for _, node in ipairs(held) do SMODS.destroy_card(node) end
            end
            for _, view in ipairs(context.full_hand or {}) do
                local data = view.card_data
                if data and not data.edition
                    and not (data.modifier and data.modifier.edition) then
                    data.modifier = data.modifier or {}
                    data.modifier.edition = "polychrome"
                    if view.sync_visual_from_card_data then
                        view:sync_visual_from_card_data()
                    end
                end
            end
            if SMODS.destroy_joker then SMODS.destroy_joker(card) end
            return { message = "Polychrome!" }
        end
    end,
}

-- matcha
SMODS.Joker {
    key = "matcha",
    name = "Matcha",
    rarity = 1,
    cost = 3,
    sprite = "matcha.png",
    negative_sprite = "matcha_negative.png",
    config = { extra = { odds = 5, a_chips = 2, chips = 0 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        local num, den = pb3_prob_vars(card, 1, card.ability.extra.odds,
            "paperback_matcha")
        return { vars = { card.ability.extra.a_chips, num, den,
            card.ability.extra.chips } }
    end,
    loc_txt = { name = "Matcha", text = {
        "This Joker gains +#1# Chips",
        "when a card is scored",
        "#2# in #3# chance to consume",
        "on discard (Currently +#4# Chips)",
    } },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.individual and context.cardarea == G.play then
            card.ability.extra.chips = card.ability.extra.chips
                + card.ability.extra.a_chips
        end
        if context.pre_discard then
            if pb3_hit(card, 1, card.ability.extra.odds, "paperback_matcha") then
                if SMODS.destroy_joker then SMODS.destroy_joker(card) end
                return { message = "Consumed!" }
            end
        end
        if context.joker_main and card.ability.extra.chips ~= 0 then
            return { chips = card.ability.extra.chips }
        end
    end,
}

-- meeple
-- PORT NOTE: the fork has no ease_discard helper; the gained discard is
-- written to G.discards (the round's remaining discards) directly.
SMODS.Joker {
    key = "meeple",
    name = "Meeple",
    rarity = 1,
    cost = 6,
    sprite = "meeple.png",
    negative_sprite = "meeple_negative.png",
    config = { extra = { discards_given = 1, odds = 2 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        local num, den = pb3_prob_vars(card, 1, card.ability.extra.odds,
            "paperback_meeple")
        return { vars = { num, den, card.ability.extra.discards_given } }
    end,
    loc_txt = { name = "Meeple", text = {
        "If played hand contains a scoring",
        "face card, #1# in #2# chance to gain",
        "+#3# discard this round",
    } },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.before and context.scoring_hand then
            for _, view in ipairs(context.scoring_hand) do
                if pb3_is_face(view)
                    and pb3_hit(card, 1, card.ability.extra.odds, "paperback_meeple") then
                    if G then
                        G.discards = (tonumber(G.discards) or 0)
                            + card.ability.extra.discards_given
                    end
                    return { message = "+1 Discard" }
                end
            end
        end
    end,
}

-- mezzetino
SMODS.Joker {
    key = "mezzetino",
    name = "Mezzetino",
    rarity = 2,
    cost = 7,
    sprite = "mezzetino.png",
    negative_sprite = "mezzetino_negative.png",
    config = { extra = { dollars = 2 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return { vars = { card.ability.extra.dollars } }
    end,
    loc_txt = { name = "Mezzetino", text = {
        "At end of round, spend remaining",
        "discards to destroy a random card",
        "in hand and earn $#1# each",
    } },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.end_of_round and G and G.hand and G.hand.card_nodes
            and SMODS.destroy_card then
            local left = tonumber(G.discards) or 0
            local nodes = {}
            for _, node in ipairs(G.hand.card_nodes) do nodes[#nodes + 1] = node end
            local n = math.min(left, #nodes)
            if n > 0 then
                for _ = 1, n do
                    local idx = SMODS.pseudorandom("paperback_mezzetino", 1, #nodes)
                    local node = table.remove(nodes, idx)
                    if node then SMODS.destroy_card(node) end
                end
                return { dollars = card.ability.extra.dollars * n }
            end
        end
    end,
}

-- mind_electric
-- PORT NOTE: PC destroys scored Mult Cards through the destroy_card
-- context, which the fork never raises; scored Mult Cards are marked
-- during their individual pass and destroyed at the after pass (Bunco
-- "The Joker" precedent), so the XMult gain and the destruction both land.
SMODS.Joker {
    key = "mind_electric",
    name = "The Mind Electric",
    rarity = 3,
    cost = 3,
    sprite = "mind_electric.png",
    negative_sprite = "mind_electric_negative.png",
    config = { extra = { change = 0.2, xm = 1 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return { vars = { card.ability.extra.change, card.ability.extra.xm,
            "Mult Cards" } }
    end,
    loc_txt = { name = "The Mind Electric", text = {
        "Scored #3# are destroyed and",
        "give this Joker X#1# Mult",
        "(Currently X#2# Mult)",
    } },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.individual and context.cardarea == G.play
            and context.other_card and context.other_card.card_data
            and context.other_card.card_data.enhancement == "mult" then
            card.ability.extra.xm = pb3_round2(card.ability.extra.xm
                + card.ability.extra.change)
            pb3_mark(card, context.other_card)
            return { message = "Upgrade!" }
        end
        if context.after then pb3_flush_marks(card) end
        if context.joker_main and card.ability.extra.xm > 1 then
            return { xmult = card.ability.extra.xm }
        end
    end,
}

-- moneyback
-- PORT NOTE: booster-open spending is dropped: PC reads the booster's
-- price from its open_booster context, but the fork raises
-- on_booster_open with no price (buying the booster in the shop is still
-- counted, through on_shop_buy like every other purchase).
SMODS.Joker {
    key = "moneyback",
    name = "Moneyback",
    rarity = 1,
    cost = 6,
    sprite = "moneyback.png",
    negative_sprite = "moneyback_negative.png",
    config = { extra = { spend = 50, spent = 0, money = 10 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return { vars = { card.ability.extra.spend, card.ability.extra.spent,
            card.ability.extra.money } }
    end,
    loc_txt = { name = "Moneyback", text = {
        "Every $#1# [#2#] spent",
        "earns $#3#",
    } },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        local amount = nil
        if context.buying_card and context.port then
            local self_buy = context.port.offer_kind == "joker"
                and card.def and context.port.offer_id == card.def.id
            if not self_buy then amount = tonumber(context.port.offer_price) end
        elseif context.reroll_shop and context.port then
            amount = tonumber(context.port.reroll_cost)
        end
        if amount and amount > 0 then
            local st = card.ability.extra
            st.spent = st.spent + amount
            if st.spent >= st.spend then
                st.spent = st.spent - st.spend
                return { dollars = st.money }
            end
        end
    end,
}

-- moribund
-- PORT NOTE: the double-on-a-failed-Blind half is unreachable in the
-- fork (on_round_end only fires on the win path); it is implemented
-- against the raw round_score/blind target guard for completeness.
SMODS.Joker {
    key = "moribund",
    name = "Moribund",
    rarity = 2,
    cost = 6,
    sprite = "moribund.png",
    negative_sprite = "moribund_negative.png",
    config = { extra = { a_mult = 5, mult = 0, ax_mult = 2 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return { vars = { card.ability.extra.a_mult, card.ability.extra.mult } }
    end,
    loc_txt = { name = "Moribund", text = {
        "This Joker gains +#1# Mult when a Blind",
        "is cleared with 0 hands remaining.",
        "This Joker doubles its Mult if",
        "Blind is not cleared (Currently +#2# Mult)",
    } },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.end_of_round and context.port then
            local score = tonumber(context.port.round_score)
            local target = tonumber(G and G.current_blind_target)
            if score and target and score < target then
                card.ability.extra.mult = card.ability.extra.mult
                    * card.ability.extra.ax_mult
                return { message = "Doubled!" }
            elseif tonumber(context.port.hands_left) == 0 then
                card.ability.extra.mult = card.ability.extra.mult
                    + card.ability.extra.a_mult
                return { message = "Upgrade!" }
            end
        end
        if context.joker_main and card.ability.extra.mult ~= 0 then
            return { mult = card.ability.extra.mult }
        end
    end,
}

-- moving_out
SMODS.Joker {
    key = "moving_out",
    name = "Moving Out",
    rarity = 1,
    cost = 4,
    sprite = "moving_out.png",
    negative_sprite = "moving_out_negative.png",
    config = { extra = { a_mult = 4, mult = 0 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return { vars = { card.ability.extra.a_mult, card.ability.extra.mult } }
    end,
    loc_txt = { name = "Moving Out", text = {
        "This Joker gains +#1# Mult if winning",
        "poker hand is not your most played hand",
        "(Currently +#2# Mult)",
    } },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.end_of_round and context.port and G
            and type(G.handlist) == "table"
            and type(G.hand_play_counts) == "table" then
            local idx = tonumber(context.port.last_played_hand_index)
            if idx then
                local last_count = tonumber(G.hand_play_counts[idx]) or 0
                local other_max = 0
                for i in ipairs(G.handlist) do
                    if i ~= idx then
                        local c = tonumber(G.hand_play_counts[i]) or 0
                        if c > other_max then other_max = c end
                    end
                end
                if last_count <= other_max then
                    card.ability.extra.mult = card.ability.extra.mult
                        + card.ability.extra.a_mult
                    return { message = "Upgrade!" }
                end
            end
        end
        if context.joker_main and card.ability.extra.mult ~= 0 then
            return { mult = card.ability.extra.mult }
        end
    end,
}

-- nazca_lines
SMODS.Joker {
    key = "nazca_lines",
    name = "Nazca Lines",
    rarity = 1,
    cost = 6,
    sprite = "nazca_lines.png",
    negative_sprite = "nazca_lines_negative.png",
    config = { extra = { money = 1 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return { vars = { card.ability.extra.money } }
    end,
    loc_txt = { name = "Nazca Lines", text = {
        "Scored cards earn $#1# for each",
        "adjacent debuffed or unscored card",
    } },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.individual and context.cardarea == G.play
            and context.other_card and context.full_hand then
            local idx = nil
            for i, view in ipairs(context.full_hand) do
                if view == context.other_card
                    or (view.card_data and view.card_data == context.other_card.card_data) then
                    idx = i break
                end
            end
            if not idx then return end
            local function neighbour_bad(view)
                if not view then return 0 end
                if view.debuff then return 1 end
                for _, sv in ipairs(context.scoring_hand or {}) do
                    if sv == view or (sv.card_data and sv.card_data == view.card_data) then
                        return 0
                    end
                end
                return 1
            end
            local count = neighbour_bad(context.full_hand[idx - 1])
                + neighbour_bad(context.full_hand[idx + 1])
            if count > 0 then
                return { dollars = count * card.ability.extra.money }
            end
        end
    end,
}

-- ncj
SMODS.Joker {
    key = "ncj",
    name = "NoCopyrightJokers",
    rarity = 1,
    cost = 5,
    sprite = "ncj.png",
    negative_sprite = "ncj_negative.png",
    config = { extra = { scaling = 4 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        local total = 0
        for _, j in ipairs(pb3_jokers()) do
            if j ~= card then total = total + (tonumber(j.sell_cost) or 0) end
        end
        return { vars = { card.ability.extra.scaling,
            math.max(0, total * card.ability.extra.scaling) } }
    end,
    loc_txt = { name = "NoCopyrightJokers", text = {
        "+#1# Chips for every $1 of sell value",
        "your other Jokers have",
        "(Currently +#2# Chips)",
    } },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.joker_main then
            local total = 0
            for _, j in ipairs(pb3_jokers()) do
                if j ~= card then total = total + (tonumber(j.sell_cost) or 0) end
            end
            local chips = math.max(0, total * card.ability.extra.scaling)
            if chips > 0 then return { chips = chips } end
        end
    end,
}

-- nigiri
SMODS.Joker {
    key = "nigiri",
    name = "Nigiri",
    rarity = 3,
    cost = 6,
    sprite = "nigiri.png",
    negative_sprite = "nigiri_negative.png",
    config = { extra = { xmult = 1, factor = 100 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return { vars = { card.ability.extra.xmult, card.ability.extra.factor } }
    end,
    loc_txt = { name = "Nigiri", text = {
        "This Joker gains 1/#2#th of the rank",
        "of discarded cards as XMult,",
        "self-destructs if a Face card scores,",
        "resets when Boss Blind is defeated",
        "(Currently X#1# Mult)",
    } },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.discard and context.other_card
            and not (context.other_card.card_data
                and context.other_card.card_data.enhancement == "stone") then
            local gain = pb3_nominal(context.other_card) / card.ability.extra.factor
            if gain > 0 then
                card.ability.extra.xmult = pb3_round2(card.ability.extra.xmult + gain)
            end
        end
        if context.individual and context.cardarea == G.play
            and context.other_card and pb3_is_face(context.other_card) then
            if SMODS.destroy_joker then SMODS.destroy_joker(card) end
            return { message = "Eaten!" }
        end
        if context.blind_defeated and context.port
            and context.port.blind_index == 3 then
            card.ability.extra.xmult = 1
            return { message = "Reset" }
        end
        if context.joker_main and card.ability.extra.xmult ~= 1 then
            return { xmult = card.ability.extra.xmult }
        end
    end,
}

-- off_switch
-- The addon Jokers (off_alpha/epsilon/omega) are registered in the Tier 3
-- section at the end of this file. PC applies their Eternal sticker at
-- creation; the fork's sticker channel is the Joker's `eternal` field,
-- set on the Joker SMODS.add_card returns (the same write card_sleeve's
-- port makes). The XMult gain rides the joker_type_destroyed context,
-- which also hears the destructions this Joker itself orders, as PC's
-- is_joker_destroyed check does.
SMODS.Joker {
    key = "off_switch",
    name = "OFF Switch",
    rarity = 4,
    cost = 13,
    sprite = "off_switch.png",
    negative_sprite = "off_switch_negative.png",
    config = { extra = { a_xmult = 2, x_mult = 1 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return { vars = { card.ability.extra.a_xmult, card.ability.extra.x_mult } }
    end,
    loc_txt = { name = "OFF Switch", text = {
        "When a playing card is destroyed,",
        "attempt to destroy leftmost",
        "destructible Joker and this Joker",
        "gains X#1# Mult if successful",
        "(Currently X#2# Mult)",
    } },
    add_to_deck = function(self, card, from_debuff)
        G = rawget(_G, "G") or G
        if from_debuff then return end
        if not SMODS.add_card then return end
        for _, key in ipairs({ "j_pbp_off_alpha", "j_pbp_off_omega",
            "j_pbp_off_epsilon" }) do
            if JOKER_DEFS and JOKER_DEFS[key] then
                local j = SMODS.add_card { set = "Joker", key = key }
                if j then j.eternal = true end
            end
        end
    end,
    remove_from_deck = function(self, card, from_debuff)
        G = rawget(_G, "G") or G
        if from_debuff then return end
        if not SMODS.destroy_joker then return end
        local addons = { j_pbp_off_alpha = true, j_pbp_off_omega = true,
            j_pbp_off_epsilon = true }
        local targets = {}
        for _, j in ipairs(pb3_jokers()) do
            if j ~= card and j.def and addons[j.def.id] then
                targets[#targets + 1] = j
            end
        end
        for _, j in ipairs(targets) do SMODS.destroy_joker(j) end
    end,
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.remove_playing_cards and context.port
            and context.port.destroyed_cards
            and #context.port.destroyed_cards > 0 and SMODS.destroy_joker then
            local triggered = false
            for _ = 1, #context.port.destroyed_cards do
                local target = nil
                for _, j in ipairs(pb3_jokers()) do
                    if j ~= card and not j.eternal then target = j break end
                end
                if target and SMODS.destroy_joker(target) then
                    triggered = true
                else
                    break
                end
            end
            if triggered then return { message = "OFF!" } end
        end
        if context.joker_type_destroyed then
            card.ability.extra.x_mult = pb3_round2(card.ability.extra.x_mult
                + card.ability.extra.a_xmult)
            return { message = "Upgrade!" }
        end
        if context.joker_main and card.ability.extra.x_mult > 1 then
            return { xmult = card.ability.extra.x_mult }
        end
    end,
}

-- one_shift_more
SMODS.Joker {
    key = "one_shift_more",
    name = "One Shift More",
    rarity = 2,
    cost = 7,
    sprite = "one_shift_more.png",
    negative_sprite = "one_shift_more_negative.png",
    config = { extra = { current = 0, required = 7, suit = "Hearts",
        x_mult = 1, a_xmult = 0.25 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return { vars = { card.ability.extra.a_xmult, card.ability.extra.required,
            card.ability.extra.current, card.ability.extra.x_mult,
            card.ability.extra.suit } }
    end,
    loc_txt = { name = "One Shift More", text = {
        "This Joker gains X#1# Mult for every",
        "#2# [#3#] scored #5# cards",
        "(Currently X#4# Mult)",
    } },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.individual and context.cardarea == G.play
            and context.other_card
            and pb3_is_suit(context.other_card, card.ability.extra.suit) then
            local st = card.ability.extra
            st.current = st.current + 1
            if st.current >= st.required then
                st.current = 0
                st.x_mult = pb3_round2(st.x_mult + st.a_xmult)
                return { message = "Upgrade!" }
            end
        end
        if context.joker_main and card.ability.extra.x_mult > 1 then
            return { xmult = card.ability.extra.x_mult }
        end
    end,
}

-- paralyzed
SMODS.Joker {
    key = "paralyzed",
    name = "Paralyzed",
    rarity = 2,
    cost = 7,
    sprite = "paralyzed.png",
    negative_sprite = "paralyzed_negative.png",
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return { vars = { "Tarot" } }
    end,
    loc_txt = { name = "Paralyzed", text = {
        "Create a random #1# card",
        "upon clearing a blind",
    } },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.end_of_round and not context.game_over then
            if pb3_spawn_tarot() then
                return { message = "+ Tarot" }
            end
        end
    end,
}

-- paranoia
-- PORT NOTE: PC reads a run-wide destroyed-suits tally the fork does
-- not keep; this Joker tallies dark-suit destructions itself from
-- remove_playing_cards (destroyed cards arrive as raw card data).
SMODS.Joker {
    key = "paranoia",
    name = "Paranoia",
    rarity = 3,
    cost = 8,
    sprite = "paranoia.png",
    negative_sprite = "paranoia_negative.png",
    config = { extra = { a_mult = 2, dark_destroyed = 0 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return { vars = { card.ability.extra.a_mult,
            card.ability.extra.dark_destroyed * card.ability.extra.a_mult } }
    end,
    loc_txt = { name = "Paranoia", text = {
        "Light suits give +#1# Mult when scored",
        "for every dark suit card destroyed",
        "this run (Currently +#2# Mult)",
    } },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.remove_playing_cards and context.port
            and context.port.destroyed_cards then
            local n = 0
            for _, data in ipairs(context.port.destroyed_cards) do
                if type(data) == "table" and PB3_DARK[data.suit] then n = n + 1 end
            end
            if n > 0 then
                card.ability.extra.dark_destroyed = card.ability.extra.dark_destroyed + n
            end
        end
        if context.individual and context.cardarea == G.play
            and context.other_card and pb3_is_light(context.other_card)
            and card.ability.extra.dark_destroyed > 0 then
            return { mult = card.ability.extra.dark_destroyed
                * card.ability.extra.a_mult }
        end
    end,
}

-- pear
SMODS.Joker {
    key = "pear",
    name = "Pear",
    rarity = 1,
    cost = 4,
    sprite = "pear.png",
    negative_sprite = "pear_negative.png",
    config = { extra = { chips = 0, chip_gain = 5, chip_loss = 10 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return { vars = { "Pair", card.ability.extra.chip_gain,
            card.ability.extra.chip_loss, card.ability.extra.chips } }
    end,
    loc_txt = { name = "Pear", text = {
        "This Joker gains +#2# Chips if played",
        "hand contains a #1#. Otherwise,",
        "this Joker loses -#3# Chips.",
        "Eaten if Chips fall below 0",
        "(Currently +#4# Chips)",
    } },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.before then
            local st = card.ability.extra
            if next(context.poker_hands["Pair"]) then
                st.chips = st.chips + st.chip_gain
                return { message = "Upgrade!" }
            elseif st.chips < st.chip_loss then
                if SMODS.destroy_joker then SMODS.destroy_joker(card) end
                return { message = "Eaten!" }
            else
                st.chips = st.chips - st.chip_loss
                return { message = "Downgrade!" }
            end
        end
        if context.joker_main and card.ability.extra.chips ~= 0 then
            return { chips = card.ability.extra.chips }
        end
    end,
}

-- pedrillo
SMODS.Joker {
    key = "pedrillo",
    name = "Pedrillo",
    rarity = 4,
    cost = 20,
    sprite = "pedrillo.png",
    negative_sprite = "pedrillo_negative.png",
    config = { extra = { rank = "Queen", triggered = false } },
    loc_txt = { name = "Pedrillo", text = {
        "First scored Queen creates a",
        "Planet card for played poker hand",
        "(Must have room)",
    } },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.individual and context.cardarea == G.play
            and context.other_card and not card.ability.extra.triggered
            and pb3_id(context.other_card) == 12 then
            if pb3_spawn_planet(context.scoring_name) then
                card.ability.extra.triggered = true
                return { message = "+ Planet" }
            end
        end
        if context.after then
            card.ability.extra.triggered = false
        end
    end,
}

-- percussion_ensemble
SMODS.Joker {
    key = "percussion_ensemble",
    name = "Percussion Ensemble",
    rarity = 2,
    cost = 7,
    sprite = "percussion_ensemble.png",
    negative_sprite = "percussion_ensemble_negative.png",
    config = { extra = { xMult = 1, xMult_mod = 0.25 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        local distinct = 0
        if G and G.count_cards_in_full_deck then
            local seen = {}
            G:count_cards_in_full_deck(function(data)
                if data.enhancement then seen[data.enhancement] = true end
                return false
            end)
            for _ in pairs(seen) do distinct = distinct + 1 end
        end
        return { vars = { card.ability.extra.xMult_mod,
            card.ability.extra.xMult + card.ability.extra.xMult_mod * distinct } }
    end,
    loc_txt = { name = "Percussion Ensemble", text = {
        "X#1# Mult for each unique",
        "Enhancement in your full deck",
        "(Currently X#2# Mult)",
    } },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.joker_main and G and G.count_cards_in_full_deck then
            local seen = {}
            G:count_cards_in_full_deck(function(data)
                if data.enhancement then seen[data.enhancement] = true end
                return false
            end)
            local distinct = 0
            for _ in pairs(seen) do distinct = distinct + 1 end
            if distinct >= 1 then
                return { xmult = pb3_round2(card.ability.extra.xMult
                    + card.ability.extra.xMult_mod * distinct) }
            end
        end
    end,
}

-- pointy_stick
SMODS.Joker {
    key = "pointy_stick",
    name = "Pointy Stick",
    rarity = 1,
    cost = 7,
    sprite = "pointy_stick.png",
    negative_sprite = "pointy_stick_negative.png",
    config = { extra = { xMult_if_stick = 2 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        local cur = pb3_other_sticks(card) >= 1
            and card.ability.extra.xMult_if_stick or 1
        return { vars = { card.ability.extra.xMult_if_stick, cur } }
    end,
    loc_txt = { name = "Pointy Stick", text = {
        "X#1# Mult if you have another",
        "\"Stick\" Joker (Currently X#2# Mult)",
    } },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.joker_main and pb3_other_sticks(card) >= 1 then
            return { xmult = card.ability.extra.xMult_if_stick }
        end
    end,
}

-- ponzu
-- PORT NOTE: PC keeps the target suit in run-global state shared by
-- all copies and rerolls it at round end; the fork has no run-global
-- store, so each copy keeps its own suit in extra and rerolls it at
-- round end when it triggered.
SMODS.Joker {
    key = "ponzu",
    name = "Ponzu",
    rarity = 1,
    cost = 6,
    sprite = "ponzu.png",
    negative_sprite = "ponzu_negative.png",
    config = { extra = { odds = 2, dollars = 2, active = false, suit = "Spades" } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        local num, den = pb3_prob_vars(card, 1, card.ability.extra.odds,
            "paperback_ponzu")
        return { vars = { num, den, card.ability.extra.dollars,
            card.ability.extra.suit } }
    end,
    loc_txt = { name = "Ponzu", text = {
        "#4# held in hand have a #1# in #2#",
        "chance to give $#3#. Consumed if not",
        "triggered during a round",
        "Suit changes at end of round",
    } },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.individual and context.cardarea == G.hand
            and context.other_card
            and pb3_is_suit(context.other_card, card.ability.extra.suit) then
            if not context.other_card.debuff
                and pb3_hit(card, 1, card.ability.extra.odds, "paperback_ponzu") then
                card.ability.extra.active = true
                return { dollars = card.ability.extra.dollars }
            end
        end
        if context.end_of_round then
            if not card.ability.extra.active then
                if SMODS.destroy_joker then SMODS.destroy_joker(card) end
                return { message = "Consumed!" }
            end
            card.ability.extra.active = false
            card.ability.extra.suit = SMODS.pseudorandom_element(PB3_SUITS,
                "paperback_ponzu") or card.ability.extra.suit
        end
    end,
}

-- pool_table
SMODS.Joker {
    key = "pool_table",
    name = "Pool Table",
    rarity = 3,
    cost = 8,
    sprite = "pool_table.png",
    negative_sprite = "pool_table_negative.png",
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return { vars = { "Planet" } }
    end,
    loc_txt = { name = "Pool Table", text = {
        "If first hand of round scores no",
        "face cards, create the #1# card",
        "for played poker hand (Must have room)",
    } },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.before and pb3_hands_played() == 0 and context.scoring_hand then
            local faces = false
            for _, view in ipairs(context.scoring_hand) do
                if pb3_is_face(view) then faces = true break end
            end
            if not faces and pb3_spawn_planet(context.scoring_name) then
                return { message = "+ Planet" }
            end
        end
    end,
}

-- pop_stick
SMODS.Joker {
    key = "pop_stick",
    name = "Pop-Stick",
    rarity = 1,
    cost = 7,
    sprite = "pop_stick.png",
    negative_sprite = "pop_stick_negative.png",
    config = { extra = { xMult_if_stick = 2 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        local cur = pb3_other_sticks(card) >= 1
            and card.ability.extra.xMult_if_stick or 1
        return { vars = { card.ability.extra.xMult_if_stick, cur } }
    end,
    loc_txt = { name = "Pop-Stick", text = {
        "X#1# Mult if you have another",
        "\"Stick\" Joker (Currently X#2# Mult)",
    } },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.joker_main and pb3_other_sticks(card) >= 1 then
            return { xmult = card.ability.extra.xMult_if_stick }
        end
    end,
}

-- popsicle_stick
SMODS.Joker {
    key = "popsicle_stick",
    name = "Popsicle Stick",
    rarity = 1,
    cost = 7,
    sprite = "popsicle_stick.png",
    negative_sprite = "popsicle_stick_negative.png",
    config = { extra = { xMult_if_stick = 2 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        local cur = pb3_other_sticks(card) >= 1
            and card.ability.extra.xMult_if_stick or 1
        return { vars = { card.ability.extra.xMult_if_stick, cur } }
    end,
    loc_txt = { name = "Popsicle Stick", text = {
        "X#1# Mult if you have another",
        "\"Stick\" Joker (Currently X#2# Mult)",
    } },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.joker_main and pb3_other_sticks(card) >= 1 then
            return { xmult = card.ability.extra.xMult_if_stick }
        end
    end,
}

-- power_surge
-- PORT NOTE: PC destroys the held card through the destroy_card
-- context, which the fork never raises; the victim is marked when the
-- 7 scores and destroyed directly at the after pass.
SMODS.Joker {
    key = "power_surge",
    name = "Power Surge",
    rarity = 3,
    cost = 8,
    sprite = "power_surge.png",
    negative_sprite = "power_surge_negative.png",
    config = { extra = { rank = 7, xMult = 1.5, odds = 4 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        local num, den = pb3_prob_vars(card, 1, card.ability.extra.odds,
            "paperback_power_surge")
        return { vars = { card.ability.extra.rank, card.ability.extra.xMult,
            num, den } }
    end,
    loc_txt = { name = "Power Surge", text = {
        "Played #1#s give X#2# Mult when scored",
        "and have a #3# in #4# chance to",
        "destroy a card held in hand",
    } },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.individual and context.cardarea == G.play
            and context.other_card
            and pb3_id(context.other_card) == card.ability.extra.rank then
            if pb3_hit(card, 1, card.ability.extra.odds, "paperback_power_surge")
                and G and G.hand and G.hand.card_nodes
                and #G.hand.card_nodes > 0 then
                local node = SMODS.pseudorandom_element(G.hand.card_nodes,
                    "paperback_power_surge")
                pb3_mark(card, node)
            end
            return { xmult = card.ability.extra.xMult }
        end
        if context.after then pb3_flush_marks(card) end
    end,
}

-- prescript
SMODS.Joker {
    key = "prescript",
    name = "Prescript",
    rarity = 2,
    cost = 6,
    sprite = "prescript.png",
    negative_sprite = "prescript_negative.png",
    config = { extra = { hand = "High Card", active = false } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return { vars = { card.ability.extra.hand,
            card.ability.extra.active and "Active" or "Inactive" } }
    end,
    loc_txt = { name = "Prescript", text = {
        "Retrigger all played cards this round",
        "if first hand of round contains a #1#",
        "Poker hand changes every round",
        "(Currently #2#)",
    } },
    set_ability = function(self, card, initial)
        G = rawget(_G, "G") or G
        if not initial or not G or type(G.handlist) ~= "table" then return end
        local pool = {}
        for i, name in ipairs(G.handlist) do
            local visible = true
            if type(G.is_hand_stats_visible) == "function" then
                visible = G:is_hand_stats_visible(i)
            end
            if visible then pool[#pool + 1] = name end
        end
        if #pool > 0 then
            card.ability.extra.hand = SMODS.pseudorandom_element(pool,
                "paperback_prescript") or card.ability.extra.hand
        end
    end,
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.before and pb3_hands_played() == 0
            and next(context.poker_hands[card.ability.extra.hand]) then
            card.ability.extra.active = true
            return { message = "Active!" }
        end
        if context.repetition and context.cardarea == G.play
            and card.ability.extra.active then
            return { repetitions = 1 }
        end
        if context.end_of_round and G and type(G.handlist) == "table" then
            local pool = {}
            for i, name in ipairs(G.handlist) do
                if name ~= card.ability.extra.hand then
                    local visible = true
                    if type(G.is_hand_stats_visible) == "function" then
                        visible = G:is_hand_stats_visible(i)
                    end
                    if visible then pool[#pool + 1] = name end
                end
            end
            if #pool > 0 then
                card.ability.extra.hand = SMODS.pseudorandom_element(pool,
                    "paperback_prescript") or card.ability.extra.hand
            end
            card.ability.extra.active = false
            return { message = "Reset" }
        end
    end,
}

-- pride_flag
-- PORT NOTE: the fork registers the Spectrum family (main pack file),
-- so the Spectrums variant of this Joker is ported; the no-Spectrums
-- fallback variant (Chips per unique suit) is dropped.
SMODS.Joker {
    key = "pride_flag",
    name = "Pride Flag",
    rarity = 1,
    cost = 6,
    sprite = "pride_flag.png",
    negative_sprite = "pride_flag_negative.png",
    config = { extra = { a_chips = 12, chips = 0 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return { vars = { card.ability.extra.a_chips, card.ability.extra.chips } }
    end,
    loc_txt = { name = "Pride Flag", text = {
        "Gains +#1# Chips if played hand",
        "contains a Spectrum. Resets if played",
        "hand contains a Straight",
        "(Currently +#2# Chips)",
    } },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.before then
            if next(context.poker_hands["Straight"]) then
                if card.ability.extra.chips ~= 0 then
                    card.ability.extra.chips = 0
                    return { message = "Reset" }
                end
            elseif pb3_unique_suits(context.full_hand, true) >= 5 then
                card.ability.extra.chips = card.ability.extra.chips
                    + card.ability.extra.a_chips
                return { message = "Upgrade!" }
            end
        end
        if context.joker_main and card.ability.extra.chips ~= 0 then
            return { chips = card.ability.extra.chips }
        end
    end,
}

-- prince_of_darkness
SMODS.Joker {
    key = "prince_of_darkness",
    name = "Prince of Darkness",
    rarity = 2,
    cost = 7,
    sprite = "prince_of_darkness.png",
    negative_sprite = "prince_of_darkness_negative.png",
    config = { extra = { unique_suits = 2, x_mult = 2, hands = 3,
        hands_remaining = 0, suit = "Hearts" } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return { vars = { card.ability.extra.unique_suits,
            card.ability.extra.x_mult,
            math.max(0, card.ability.extra.hands - 1),
            card.ability.extra.hands_remaining, card.ability.extra.suit } }
    end,
    loc_txt = { name = "Prince of Darkness", text = {
        "If scoring hand contains a #5# and",
        "#1# other unique suits, this Joker gives",
        "X#2# Mult for this hand and the next #3#",
        "(Currently the next #4# hands)",
    } },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.before and context.scoring_hand then
            local heart = false
            for _, view in ipairs(context.scoring_hand) do
                if pb3_is_suit(view, card.ability.extra.suit) then
                    heart = true break
                end
            end
            if heart and pb3_unique_suits(context.scoring_hand, true, true) >= 3 then
                card.ability.extra.hands_remaining = card.ability.extra.hands
                return { message = "Active!" }
            end
        end
        if context.joker_main and card.ability.extra.hands_remaining > 0 then
            return { xmult = card.ability.extra.x_mult }
        end
        if context.after and card.ability.extra.hands_remaining > 0 then
            card.ability.extra.hands_remaining = card.ability.extra.hands_remaining - 1
            if card.ability.extra.hands_remaining == 0 then
                return { message = "Inactive" }
            end
            return { message = "-1 Hands" }
        end
    end,
}

-- prism
-- PORT NOTE: suit conversion writes card_data.suit directly (the
-- game's own convert_suit_ripple does the same); only the six suits
-- the pack knows (4 vanilla + Stars + Crowns) are offered.
SMODS.Joker {
    key = "prism",
    name = "Prism",
    rarity = 2,
    cost = 6,
    sprite = "prism.png",
    negative_sprite = "prism_negative.png",
    config = { extra = { hand = "Flush" } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return { vars = { card.ability.extra.hand } }
    end,
    loc_txt = { name = "Prism", text = {
        "If played hand contains a #1#,",
        "convert all scored cards into",
        "random different suits",
    } },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.after and next(context.poker_hands[card.ability.extra.hand])
            and context.scoring_hand then
            local played = {}
            for _, view in ipairs(context.scoring_hand) do
                local data = view.card_data or {}
                if data.enhancement ~= "stone" and data.suit then
                    played[data.suit] = true
                end
            end
            local available = {}
            for _, suit in ipairs(PB3_SUITS) do
                if not played[suit] then available[#available + 1] = suit end
            end
            local changed = false
            for _, view in ipairs(context.scoring_hand) do
                local data = view.card_data
                if data and data.enhancement ~= "stone" and data.suit
                    and #available > 0 then
                    local idx = SMODS.pseudorandom("paperback_prism", 1, #available)
                    data.suit = table.remove(available, idx)
                    if view.sync_visual_from_card_data then
                        view:sync_visual_from_card_data()
                    end
                    changed = true
                end
            end
            if changed then return { message = "Prism!" } end
        end
    end,
}

-- punch_card
-- PORT NOTE: the fork has no ante-change API; selling a ready Punch
-- Card writes G.ante directly (clamped at 1), mirroring PC ease_ante(-1).
SMODS.Joker {
    key = "punch_card",
    name = "Punch Card",
    rarity = 3,
    cost = 10,
    sprite = "punch_card.png",
    negative_sprite = "punch_card_negative.png",
    config = { extra = { current_rounds = 0, total_rounds = 3, antes = -1 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return { vars = { card.ability.extra.total_rounds,
            card.ability.extra.current_rounds, card.ability.extra.antes } }
    end,
    loc_txt = { name = "Punch Card", text = {
        "After #1# rounds, sell this card",
        "for #3# Ante (Currently #2#/#1#)",
    } },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.selling_card and context.selling_self
            and card.ability.extra.current_rounds >= card.ability.extra.total_rounds then
            if G then
                G.ante = math.max(1, (tonumber(G.ante) or 1)
                    + card.ability.extra.antes)
            end
            return { message = "-1 Ante" }
        end
        if context.end_of_round and not context.game_over then
            local st = card.ability.extra
            st.current_rounds = st.current_rounds + 1
            if st.current_rounds < st.total_rounds then
                return { message = st.current_rounds .. "/" .. st.total_rounds }
            end
            return { message = "Active!" }
        end
    end,
}

-- pyrite
SMODS.Joker {
    key = "pyrite",
    name = "Pyrite",
    rarity = 2,
    cost = 7,
    sprite = "pyrite.png",
    negative_sprite = "pyrite_negative.png",
    config = { extra = { suit = "Crowns", odds = 3 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        local num, den = pb3_prob_vars(card, 1, card.ability.extra.odds,
            "paperback_pyrite")
        return { vars = { card.ability.extra.suit, num, den } }
    end,
    loc_txt = { name = "Pyrite", text = {
        "Played #1# have a #2# in #3# chance",
        "to create a random Tarot card",
        "when scored (Must have room)",
    } },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.individual and context.cardarea == G.play
            and context.other_card
            and pb3_is_suit(context.other_card, card.ability.extra.suit) then
            if pb3_hit(card, 1, card.ability.extra.odds, "paperback_pyrite")
                and pb3_spawn_tarot() then
                return { message = "+ Tarot" }
            end
        end
    end,
}

-- quick_fix
-- PORT NOTE: the +2 hand size rides the fork's modifier system
-- (ability.h_size is summed by SMODS.modifier_total, as PC's
-- card.ability.h_size); the pool-flag removal after breaking is
-- dropped (no pool flags in the fork).
SMODS.Joker {
    key = "quick_fix",
    name = "Quick Fix",
    rarity = 1,
    cost = 6,
    sprite = "quick_fix.png",
    negative_sprite = "quick_fix_negative.png",
    config = { h_size = 2, extra = { odds = 4 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        local num, den = pb3_prob_vars(card, 1, card.ability.extra.odds,
            "paperback_quick_fix")
        return { vars = { card.ability.h_size or 2, num, den } }
    end,
    loc_txt = { name = "Quick Fix", text = {
        "+#1# hand size. #2# in #3# chance",
        "this card is destroyed at end of round...",
    } },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.end_of_round and not context.game_over then
            if pb3_hit(card, 1, card.ability.extra.odds, "paperback_quick_fix") then
                local edition = card.edition
                if edition == "base" then edition = nil end
                if SMODS.destroy_joker then SMODS.destroy_joker(card) end
                if SMODS.add_card then
                    local params = { set = "Joker", key = "j_half" }
                    if edition then params.edition = edition end
                    SMODS.add_card(params)
                end
                return { message = "Broken!" }
            end
            return { message = "Safe!" }
        end
    end,
}

-- red_key
-- PORT NOTE: the fork has no Ultra Secret rarity; per the established
-- port ruling, a random Rare Joker is created instead. The temporary
-- sticker does not exist either: the created Joker is tracked at
-- runtime and destroyed at end of round; selling Red Key untracks it
-- (PC removes temporary from all Jokers when sold).
SMODS.Joker {
    key = "red_key",
    name = "Red Key",
    rarity = 2,
    cost = 7,
    sprite = "red_key.png",
    negative_sprite = "red_key_negative.png",
    loc_txt = { name = "Red Key", text = {
        "When Blind is selected, create",
        "a temporary Rare Joker",
        "When sold, remove temporary",
        "from all Jokers",
    } },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.setting_blind and G and G.random_joker_def_id_by_rarity
            and SMODS.add_card then
            local id = G:random_joker_def_id_by_rarity(3, "paperback_red_key")
            if id then
                local created = SMODS.add_card { set = "Joker", key = id }
                if created then
                    pb3_temp[card] = created
                    return { message = "Red!" }
                end
            end
        end
        if context.selling_card and context.selling_self then
            pb3_temp[card] = nil
        end
        if context.end_of_round then
            local created = pb3_temp[card]
            pb3_temp[card] = nil
            if created and SMODS.destroy_joker then
                SMODS.destroy_joker(created)
            end
        end
    end,
}

-- red_sun_in_the_sky
SMODS.Joker {
    key = "red_sun_in_the_sky",
    name = "Red Sun in the Sky",
    rarity = 1,
    cost = 5,
    sprite = "red_sun_in_the_sky.png",
    negative_sprite = "red_sun_in_the_sky_negative.png",
    config = { extra = { mult = 0, change = 1 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return { vars = { card.ability.extra.change, card.ability.extra.mult } }
    end,
    loc_txt = { name = "Red Sun in the Sky", text = {
        "Scored light suits give +#1# Mult for",
        "each scored light suit this round",
        "(Currently +#2# Mult)",
    } },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.individual and context.cardarea == G.play
            and context.other_card and pb3_is_light(context.other_card) then
            card.ability.extra.mult = card.ability.extra.mult
                + card.ability.extra.change
            return { mult = card.ability.extra.mult }
        end
        if context.end_of_round then
            card.ability.extra.mult = 0
        end
    end,
}

-- redscreen
SMODS.Joker {
    key = "redscreen",
    name = "Redscreen",
    rarity = 2,
    cost = 6,
    sprite = "redscreen.png",
    negative_sprite = "redscreen_negative.png",
    config = { extra = { a_xmult = 0.1 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        local tally = 0
        if G and G.count_cards_in_full_deck then
            local light = G:count_cards_in_full_deck(function(data)
                return data.enhancement ~= "stone"
                    and (data.enhancement == "wild" or PB3_LIGHT[data.suit] == true)
            end)
            local dark = G:count_cards_in_full_deck(function(data)
                return data.enhancement ~= "stone"
                    and data.enhancement ~= "wild" and PB3_DARK[data.suit] == true
            end)
            tally = math.max(light - dark, -10)
        end
        return { vars = { card.ability.extra.a_xmult,
            math.max(1 + card.ability.extra.a_xmult * tally, 1) } }
    end,
    loc_txt = { name = "Redscreen", text = {
        "+X#1# Mult for each light suit and",
        "-X#1# Mult for each dark suit",
        "in your full deck (Currently X#2# Mult)",
    } },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.joker_main and G and G.count_cards_in_full_deck then
            local light = G:count_cards_in_full_deck(function(data)
                return data.enhancement ~= "stone"
                    and (data.enhancement == "wild" or PB3_LIGHT[data.suit] == true)
            end)
            local dark = G:count_cards_in_full_deck(function(data)
                return data.enhancement ~= "stone"
                    and data.enhancement ~= "wild" and PB3_DARK[data.suit] == true
            end)
            local tally = math.max(light - dark, -10)
            local x = math.max(1 + card.ability.extra.a_xmult * tally, 1)
            if x > 1 then return { xmult = pb3_round2(x) } end
        end
    end,
}

-- reference_card
SMODS.Joker {
    key = "reference_card",
    name = "Reference Card",
    rarity = 2,
    cost = 6,
    sprite = "reference_card.png",
    negative_sprite = "reference_card_negative.png",
    config = { extra = { x_mult = 1, x_mult_mod = 2 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        local ct = 0
        if G and type(G.handlist) == "table" and type(G.hand_play_counts) == "table" then
            local base = { ["High Card"] = true, ["Pair"] = true,
                ["Two Pair"] = true, ["Three of a Kind"] = true,
                ["Straight"] = true, ["Flush"] = true, ["Full House"] = true,
                ["Four of a Kind"] = true, ["Straight Flush"] = true }
            local min_played = nil
            for i, name in ipairs(G.handlist) do
                if base[name] then
                    local c = tonumber(G.hand_play_counts[i]) or 0
                    if min_played == nil or c < min_played then min_played = c end
                end
            end
            ct = min_played or 0
        end
        return { vars = { card.ability.extra.x_mult_mod,
            card.ability.extra.x_mult + card.ability.extra.x_mult_mod * ct } }
    end,
    loc_txt = { name = "Reference Card", text = {
        "Gives X#1# Mult for every time all 9",
        "base poker hands have been played",
        "(Currently X#2# Mult)",
    } },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.joker_main and G and type(G.handlist) == "table"
            and type(G.hand_play_counts) == "table" then
            local base = { ["High Card"] = true, ["Pair"] = true,
                ["Two Pair"] = true, ["Three of a Kind"] = true,
                ["Straight"] = true, ["Flush"] = true, ["Full House"] = true,
                ["Four of a Kind"] = true, ["Straight Flush"] = true }
            local min_played = nil
            for i, name in ipairs(G.handlist) do
                if base[name] then
                    local c = tonumber(G.hand_play_counts[i]) or 0
                    if min_played == nil or c < min_played then min_played = c end
                end
            end
            local x = card.ability.extra.x_mult
                + card.ability.extra.x_mult_mod * (min_played or 0)
            if x ~= 1 then return { xmult = x } end
        end
    end,
}

-- resurrections
SMODS.Joker {
    key = "resurrections",
    name = "Resurrections",
    rarity = 3,
    cost = 8,
    sprite = "resurrections.png",
    negative_sprite = "resurrections_negative.png",
    config = { extra = { sell_cost = 10, odds = 5, chance_mult = 1 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        local num, den = pb3_prob_vars(card, card.ability.extra.chance_mult,
            card.ability.extra.odds, "paperback_resurrections")
        return { vars = { num, den, card.ability.extra.sell_cost, 1 } }
    end,
    loc_txt = { name = "Resurrections", text = {
        "#1# in #2# chance to return sold",
        "Jokers and create an extra Negative",
        "copy with -$#3# sell value",
        "Chance increases by #4# on fail",
        "Self-destructs",
    } },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.selling_card and not context.selling_self
            and context.port and context.port.joker then
            local sold = context.card or context.port.joker
            local def_id = sold and pb3_joker_id(sold)
            if def_id and SMODS.add_card then
                local st = card.ability.extra
                if pb3_hit(card, st.chance_mult, st.odds, "paperback_resurrections") then
                    SMODS.add_card { set = "Joker", key = def_id }
                    local neg = SMODS.add_card { set = "Joker", key = def_id,
                        edition = "negative" }
                    if neg then neg.sell_cost = -st.sell_cost end
                    if SMODS.destroy_joker then SMODS.destroy_joker(card) end
                    return { message = "Duplicated!" }
                end
                st.chance_mult = st.chance_mult + 1
            end
        end
    end,
}

-- rock_candy
-- PORT NOTE: PC routes this through a shared stick-food helper that
-- is not in the fork; the behaviour stated by its own text (scored
-- Stars give Mult, chance to be eaten at round end) is ported directly.
SMODS.Joker {
    key = "rock_candy",
    name = "Rock Candy",
    rarity = 1,
    cost = 6,
    sprite = "rock_candy.png",
    negative_sprite = "rock_candy_negative.png",
    config = { extra = { mult = 10, odds = 4, suit = "Stars" } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        local num, den = pb3_prob_vars(card, 1, card.ability.extra.odds,
            "paperback_rock_candy")
        return { vars = { card.ability.extra.mult, num, den,
            card.ability.extra.suit } }
    end,
    loc_txt = { name = "Rock Candy", text = {
        "Scored #4# give +#1# Mult",
        "#2# in #3# chance this card is",
        "eaten at end of round",
    } },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.individual and context.cardarea == G.play
            and context.other_card
            and pb3_is_suit(context.other_card, card.ability.extra.suit) then
            return { mult = card.ability.extra.mult }
        end
        if context.end_of_round
            and pb3_hit(card, 1, card.ability.extra.odds, "paperback_rock_candy") then
            if SMODS.destroy_joker then SMODS.destroy_joker(card) end
            return { message = "Eaten!" }
        end
    end,
}

-- rockin_stick
-- PORT NOTE: PC's shared stick helper is not in the fork; "X1.5 for
-- every Stick Joker you have" is read multiplicatively, counting this
-- Joker itself (alone it gives X1.5, two Sticks give X2.25, and so on).
SMODS.Joker {
    key = "rockin_stick",
    name = "Rockin' Stick",
    rarity = 1,
    cost = 7,
    sprite = "rockin_stick.png",
    negative_sprite = "rockin_stick_negative.png",
    config = { extra = { xMult = 1.5 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        local total = pb3_other_sticks(card) + 1
        return { vars = { card.ability.extra.xMult,
            pb3_round2(card.ability.extra.xMult ^ total) } }
    end,
    loc_txt = { name = "Rockin' Stick", text = {
        "Gives X#1# Mult for every",
        "\"Stick\" Joker you have",
        "(Currently X#2# Mult)",
    } },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.joker_main then
            local total = pb3_other_sticks(card) + 1
            return { xmult = pb3_round2(card.ability.extra.xMult ^ total) }
        end
    end,
}

-- roulette
SMODS.Joker {
    key = "roulette",
    name = "Roulette",
    rarity = 2,
    cost = 7,
    sprite = "roulette.png",
    negative_sprite = "roulette_negative.png",
    config = { extra = { money_for_suit = 1, money_for_rank = 5,
        money_for_both = 25, suit = "Spades", rank = 14 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return { vars = { card.ability.extra.money_for_suit,
            card.ability.extra.money_for_rank, card.ability.extra.money_for_both } }
    end,
    loc_txt = { name = "Roulette", text = {
        "Each hand played, this Joker chooses a",
        "random rank and suit. Scored cards earn",
        "$#1# if they match suit, $#2# if they",
        "match rank, or $#3# if they match exactly",
    } },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.before then
            card.ability.extra.suit = SMODS.pseudorandom_element(PB3_SUITS,
                "paperback_roulette") or card.ability.extra.suit
            card.ability.extra.rank = SMODS.pseudorandom("paperback_roulette", 2, 14)
        end
        if context.individual and context.cardarea == G.play and context.other_card then
            local suit_match = pb3_is_suit(context.other_card, card.ability.extra.suit)
            local rank_match = pb3_id(context.other_card) == card.ability.extra.rank
            if suit_match and rank_match then
                return { dollars = card.ability.extra.money_for_both }
            elseif suit_match then
                return { dollars = card.ability.extra.money_for_suit }
            elseif rank_match then
                return { dollars = card.ability.extra.money_for_rank }
            end
        end
    end,
}

-- royalty_free
SMODS.Joker {
    key = "royalty_free",
    name = "Royalty Free",
    rarity = 1,
    cost = 4,
    sprite = "royalty_free.png",
    negative_sprite = "royalty_free_negative.png",
    config = { extra = { perma_bonus = 5, active = true } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return { vars = { card.ability.extra.perma_bonus } }
    end,
    loc_txt = { name = "Royalty Free", text = {
        "The first scored non-face card",
        "each round permanently gains",
        "+#1# Chips",
    } },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.before and card.ability.extra.active and context.scoring_hand then
            for _, view in ipairs(context.scoring_hand) do
                if not pb3_is_face(view) and view.card_data then
                    view.card_data.chip_bonus = (tonumber(view.card_data.chip_bonus) or 0)
                        + card.ability.extra.perma_bonus
                    card.ability.extra.active = false
                    return { message = "Upgrade!" }
                end
            end
        end
        if context.end_of_round then
            card.ability.extra.active = true
        end
    end,
}

-- sacrificial_lamb
-- PORT NOTE: Joker-destruction scaling is unobservable in the fork
-- (no joker-destroyed context is raised), so only the playing-card
-- half is ported: +Mult for each playing card destroyed.
SMODS.Joker {
    key = "sacrificial_lamb",
    name = "Sacrificial Lamb",
    rarity = 1,
    cost = 6,
    sprite = "sacrificial_lamb.png",
    negative_sprite = "sacrificial_lamb_negative.png",
    config = { extra = { mult_mod = 3, mult = 0 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return { vars = { card.ability.extra.mult_mod, card.ability.extra.mult } }
    end,
    loc_txt = { name = "Sacrificial Lamb", text = {
        "Gains +#1# Mult for each card",
        "destroyed (Currently +#2# Mult)",
    } },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.remove_playing_cards and context.port
            and context.port.destroyed_cards
            and #context.port.destroyed_cards > 0 then
            card.ability.extra.mult = card.ability.extra.mult
                + card.ability.extra.mult_mod * #context.port.destroyed_cards
            return { message = "Upgrade!" }
        end
        if context.joker_main and card.ability.extra.mult > 0 then
            return { mult = card.ability.extra.mult }
        end
    end,
}

-- sake_cup
SMODS.Joker {
    key = "sake_cup",
    name = "Sake Cup",
    rarity = 3,
    cost = 8,
    sprite = "sake_cup.png",
    negative_sprite = "sake_cup_negative.png",
    config = { extra = { odds = 2, rank = 9 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        local num, den = pb3_prob_vars(card, 1, card.ability.extra.odds,
            "paperback_sake_cup")
        return { vars = { card.ability.extra.rank, num, den } }
    end,
    loc_txt = { name = "Sake Cup", text = {
        "After a hand is played, #1#s held in",
        "hand have a #2# in #3# chance to create",
        "the Planet card for played poker hand",
        "(Must have room)",
    } },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.individual and context.cardarea == G.hand
            and context.other_card
            and pb3_id(context.other_card) == card.ability.extra.rank then
            if not context.other_card.debuff
                and pb3_hit(card, 1, card.ability.extra.odds, "paperback_sake_cup")
                and pb3_spawn_planet(context.scoring_name) then
                return { message = "+ Planet" }
            end
        end
    end,
}

-- scorecard
SMODS.Joker {
    key = "scorecard",
    name = "Scorecard",
    rarity = 2,
    cost = 7,
    sprite = "scorecard.png",
    negative_sprite = "scorecard_negative.png",
    config = { extra = { suit = "Clubs", req = 9, current = 9, mult = 0 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return { vars = { card.ability.extra.req, card.ability.extra.current,
            card.ability.extra.suit, card.ability.extra.mult } }
    end,
    loc_txt = { name = "Scorecard", text = {
        "Every #1# [#2#] discarded #3#, this",
        "Joker gains another's sell value",
        "as +Mult (Currently +#4# Mult)",
    } },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.discard and context.other_card
            and not context.other_card.debuff
            and pb3_is_suit(context.other_card, card.ability.extra.suit) then
            local st = card.ability.extra
            st.current = st.current - 1
            if st.current <= 0 then
                local others = {}
                for _, j in ipairs(pb3_jokers()) do
                    if j ~= card then others[#others + 1] = j end
                end
                if #others > 0 then
                    local target = SMODS.pseudorandom_element(others,
                        "paperback_scorecard")
                    st.mult = st.mult + (tonumber(target and target.sell_cost) or 0)
                    st.current = st.req
                    return { message = "Upgrade!" }
                end
                st.current = 0
            end
        end
        if context.joker_main and card.ability.extra.mult ~= 0 then
            return { mult = card.ability.extra.mult }
        end
    end,
}

-- seven_stars
SMODS.Joker {
    key = "seven_stars",
    name = "Seven Stars",
    rarity = 3,
    cost = 8,
    sprite = "seven_stars.png",
    negative_sprite = "seven_stars_negative.png",
    config = { extra = { suit = "Stars" } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return { vars = { card.ability.extra.suit } }
    end,
    loc_txt = { name = "Seven Stars", text = {
        "Retrigger all scored #1#",
    } },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.repetition and context.cardarea == G.play
            and context.other_card
            and pb3_is_suit(context.other_card, card.ability.extra.suit) then
            return { repetitions = 1 }
        end
    end,
}

-- shabu_shabu
-- PORT NOTE: the slot grant rides the fork's modifier system
-- (ability.joker_slots is summed by SMODS.modifier_total, replacing
-- PC's add_to_deck/change_size calls); the decrement fires on
-- blind_defeated (Boss) instead of PC's end-of-round boss check.
SMODS.Joker {
    key = "shabu_shabu",
    name = "Shabu Shabu",
    rarity = 3,
    cost = 10,
    sprite = "shabu_shabu.png",
    negative_sprite = "shabu_shabu_negative.png",
    config = { joker_slots = 3, extra = { slots = 3, decrement = 1 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return { vars = { card.ability.extra.slots, card.ability.extra.decrement } }
    end,
    loc_txt = { name = "Shabu Shabu", text = {
        "+#1# Joker slots. Reduces by #2#",
        "after clearing Boss Blind",
    } },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.blind_defeated and context.port
            and context.port.blind_index == 3 then
            local st = card.ability.extra
            if st.slots - st.decrement <= 0 then
                if SMODS.destroy_joker then SMODS.destroy_joker(card) end
                return { message = "Eaten!" }
            end
            st.slots = st.slots - st.decrement
            card.ability.joker_slots = st.slots
            return { message = "Downgrade!" }
        end
    end,
}

-- shooting_star
SMODS.Joker {
    key = "shooting_star",
    name = "Shooting Star",
    rarity = 2,
    cost = 6,
    sprite = "shooting_star.png",
    negative_sprite = "shooting_star_negative.png",
    config = { extra = { odds = 4, suit = "Stars" } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        local num, den = pb3_prob_vars(card, 1, card.ability.extra.odds,
            "paperback_shooting_star")
        return { vars = { card.ability.extra.suit, num, den } }
    end,
    loc_txt = { name = "Shooting Star", text = {
        "Scored #1# have a #2# in #3# chance",
        "to create the Planet card for",
        "played poker hand",
    } },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.individual and context.cardarea == G.play
            and context.other_card
            and pb3_is_suit(context.other_card, card.ability.extra.suit) then
            if pb3_hit(card, 1, card.ability.extra.odds, "paperback_shooting_star")
                and pb3_spawn_planet(context.scoring_name) then
                return { message = "+ Planet" }
            end
        end
    end,
}

-- showdown
-- PORT NOTE: PC's trigger condition has an operator-precedence bug
-- ((chance and Stars) or Crowns: Crowns always pay, Stars pay on the
-- roll). The documented behaviour is ported instead: either suit,
-- decided by the 1-in-2 roll.
SMODS.Joker {
    key = "showdown",
    name = "Showdown",
    rarity = 1,
    cost = 5,
    sprite = "showdown.png",
    negative_sprite = "showdown_negative.png",
    config = { extra = { dollars = 1, odds = 2, suit1 = "Stars", suit2 = "Crowns" } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        local num, den = pb3_prob_vars(card, 1, card.ability.extra.odds,
            "paperback_showdown_money")
        return { vars = { card.ability.extra.suit1, card.ability.extra.suit2,
            num, den, card.ability.extra.dollars } }
    end,
    loc_txt = { name = "Showdown", text = {
        "#1# and #2# held in hand have a",
        "#3# in #4# chance to earn $#5#",
    } },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.individual and context.cardarea == G.hand
            and context.other_card then
            if (pb3_is_suit(context.other_card, card.ability.extra.suit1)
                or pb3_is_suit(context.other_card, card.ability.extra.suit2))
                and pb3_hit(card, 1, card.ability.extra.odds,
                    "paperback_showdown_money") then
                return { dollars = card.ability.extra.dollars }
            end
        end
    end,
}

-- shugi_bukuro
SMODS.Joker {
    key = "shugi_bukuro",
    name = "Shūgi Bukuro",
    rarity = 1,
    cost = 6,
    sprite = "shugi_bukuro.png",
    negative_sprite = "shugi_bukuro_negative.png",
    config = { extra = { dollars = 2, a_dollars = 2 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return { vars = { card.ability.extra.dollars, card.ability.extra.a_dollars } }
    end,
    loc_txt = { name = "Shūgi Bukuro", text = {
        "Earn $#1# when a Blind is skipped",
        "Increases by $#2# each time",
    } },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.skip_blind then
            card.ability.extra.dollars = card.ability.extra.dollars
                + card.ability.extra.a_dollars
            return { dollars = card.ability.extra.dollars }
        end
    end,
}

-- shuttle
SMODS.Joker {
    key = "shuttle",
    name = "Shuttle",
    rarity = 1,
    cost = 6,
    sprite = "shuttle.png",
    negative_sprite = "shuttle_negative.png",
    config = { extra = { max = 10, multiplier = 2 } },
    loc_vars = function(self, info_queue, card)
        G = rawget(_G, "G") or G
        return { vars = { card.ability.extra.max } }
    end,
    loc_txt = { name = "Shuttle", text = {
        "The first played hand of round gives",
        "money equal to double the played",
        "hand's level (Max of $#1#)",
    } },
    calculate = function(self, card, context)
        G = rawget(_G, "G") or G
        if context.joker_main and pb3_hands_played() == 0 then
            local level = pb3_hand_level(context.scoring_name)
            if level then
                local money = math.min(level * card.ability.extra.multiplier,
                    card.ability.extra.max)
                if money > 0 then return { dollars = money } end
            end
        end
    end,
}
end

--------------------------------------------------------------------------------
-- Expansion Jokers, slice 4 (silent_assassin .. zealous_joker)
-- Ported from Paperback's MIT-licensed sources against the fork API.
-- Sub-effect deviations are marked with PORT NOTE comments inline.
--------------------------------------------------------------------------------
do
-- PaperbackPack fragment 4 of 4: Paperback Jokers (silent_assassin .. zealous_joker).
-- Balatro3DS-native ports written against the fork mod API, matching the
-- dialect of paperbackpack.lua. Loads after the main pack file; uses only
-- SMODS / G. State lives in card.ability.extra. Helper locals are pb4_*.

local pb4_STICK_KEYS = {
    j_pbp_bamboo_stick = true, j_pbp_pointy_stick = true,
    j_pbp_pop_stick = true, j_pbp_popsicle_stick = true,
    j_pbp_rockin_stick = true, j_pbp_sticky_stick = true,
    j_pbp_sweet_stick = true,
}

local function pb4_game() return rawget(_G, "G") end

local function pb4_play()
    local g = pb4_game()
    return g and g.play
end

local function pb4_round2(x) return math.floor(x * 100 + 0.5) / 100 end

local function pb4_jokers()
    local g = pb4_game()
    if not g then return {} end
    if g.jokers and g.jokers.cards then return g.jokers.cards end
    return g.jokers or {}
end

local PB4_RARITY_BY_NAME = { common = 1, uncommon = 2, rare = 3, legendary = 4 }
local function pb4_joker_rarity(j)
    if type(j) ~= "table" then return nil end
    local def = j.def and JOKER_DEFS and JOKER_DEFS[j.def.id]
    local r = tonumber(def and def.rarity) or tonumber(j.rarity)
    if r then return r end
    if type(j.rarity) == "string" then
        return PB4_RARITY_BY_NAME[j.rarity:lower()]
    end
    return nil
end

local function pb4_edition_of(j)
    local e = j and j.edition
    if e == "foil" or e == "holo" or e == "polychrome" or e == "negative" then
        return e
    end
    return nil
end

local PB4_RANK_CHIPS = { [11] = 10, [12] = 10, [13] = 10, [14] = 11 }
local function pb4_chip_value(view)
    local data = (view and view.card_data) or {}
    local base = tonumber(data.chips)
    if not base then
        base = PB4_RANK_CHIPS[tonumber(data.rank) or 0] or tonumber(data.rank) or 0
    end
    if data.enhancement == "bonus" then base = base + 30 end
    base = base + (tonumber(data.chip_bonus) or 0)
    return base
end

local function pb4_is_light(view)
    return view:is_suit("Hearts") or view:is_suit("Diamonds")
        or view:is_suit("Stars")
end

local function pb4_is_dark(view)
    return view:is_suit("Spades") or view:is_suit("Clubs")
        or view:is_suit("Crowns")
end

local function pb4_boss(context)
    local idx = context.port and context.port.blind_index
    if not idx then
        local g = pb4_game()
        idx = g and g.current_blind_index
    end
    return idx == 3
end

-- Hands played this round, fork counter (incremented when a hand is played,
-- so during scoring the first hand reads 1). 0 when unavailable.
local function pb4_hands_played()
    local g = pb4_game()
    if not g then return 0 end
    if g.get_round_hands_played then
        return tonumber(g:get_round_hands_played()) or 0
    end
    return tonumber(g.round_hands_played) or 0
end

local function pb4_sync(view)
    if view and view.sync_visual_from_card_data then
        view:sync_visual_from_card_data()
    end
end

local function pb4_stick_count(card, include_self)
    local n = 0
    for _, j in ipairs(pb4_jokers()) do
        if type(j) == "table" and j.def and pb4_STICK_KEYS[j.def.id] then
            if include_self or j ~= card then n = n + 1 end
        end
    end
    return n
end

local PB4_BASE_HANDS = {
    "High Card", "Pair", "Two Pair", "Three of a Kind", "Straight",
    "Flush", "Full House", "Four of a Kind", "Straight Flush",
}
local PB4_BASE_HAND_SET = {}
for _, n in ipairs(PB4_BASE_HANDS) do PB4_BASE_HAND_SET[n] = true end

local function pb4_min_hand_level()
    local g = pb4_game()
    if not g or not g.handlist or not g.hand_stats then return 1 end
    local min_level = nil
    for i, name in ipairs(g.handlist) do
        if PB4_BASE_HAND_SET[name] then
            local lvl = tonumber(g.hand_stats[i] and g.hand_stats[i].level) or 1
            if not min_level or lvl < min_level then min_level = lvl end
        end
    end
    return math.max(1, min_level or 1)
end

-- Distinct hand types played this run; `current_name` (the hand being
-- played, whose play count may not be banked yet) counts when given.
local function pb4_distinct_hands_played(current_name)
    local g = pb4_game()
    if not g or not g.handlist or not g.hand_play_counts then return 0 end
    local n, current_counted = 0, false
    for i, name in ipairs(g.handlist) do
        if (tonumber(g.hand_play_counts[i]) or 0) > 0 then
            n = n + 1
            if name == current_name then current_counted = true end
        end
    end
    if current_name and not current_counted then n = n + 1 end
    return n
end

-- Position (1-based) of context.other_card among the scoring cards of the
-- played hand, plus the number of scoring cards (PokermonPack precedent).
local function pb4_scoring_pos(context)
    local played = context.port and context.port.played_cards
    if type(played) ~= "table" then played = context.scoring_hand end
    if type(played) ~= "table" then return nil, 0 end
    local pos, total = nil, 0
    for _, n in ipairs(played) do
        if n and (n.counts_for_play_score or played == context.scoring_hand) then
            total = total + 1
            if n == context.other_card then pos = total end
        end
    end
    return pos, total
end

-- silent_assassin
SMODS.Joker {
    key = "silent_assassin",
    name = "Silent Assassin",
    rarity = 1,
    cost = 8,
    sprite = "silent_assassin.png",
    negative_sprite = "silent_assassin_negative.png",
    config = { extra = {
        mult = 1, change = 1, destroy_req = 2, destroyed = 0,
    } },
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        return { vars = { "4", "7", e.mult, e.change, e.destroy_req,
            e.destroy_req - e.destroyed } }
    end,
    loc_txt = { name = "Silent Assassin", text = {
        "Scored 4s and 7s give +#3# Mult",
        "Increased by +#4# Mult",
        "for every #5# [#6#] cards destroyed",
    } },
    calculate = function(self, card, context)
        local e = card.ability.extra
        if context.individual and context.cardarea == pb4_play()
            and context.other_card then
            local rank = context.other_card:get_id()
            if rank == 4 or rank == 7 then return { mult = e.mult } end
        end
        if context.remove_playing_cards and context.port
            and context.port.destroyed_cards then
            local total = e.destroyed + #context.port.destroyed_cards
            local gains = math.floor(total / e.destroy_req)
            e.destroyed = total % e.destroy_req
            if gains > 0 then
                e.mult = e.mult + e.change * gains
                return { message = "Upgrade!" }
            end
        end
    end,
}

-- sinister_minds
SMODS.Joker {
    key = "sinister_minds",
    name = "Sinister Minds",
    rarity = 3,
    cost = 8,
    sprite = "sinister_minds.png",
    negative_sprite = "sinister_minds_negative.png",
    config = { extra = {
        retriggers = 1, a_retriggers = 1, required_spectrals = 1,
        required_inc = 1, hand = "Pair", spectrals_left = 1,
    } },
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        return { vars = { e.retriggers, e.retriggers == 1 and "" or "s",
            e.a_retriggers, e.required_spectrals, "Spectral",
            e.required_spectrals == 1 and "" or "s", e.hand,
            e.spectrals_left, e.required_inc } }
    end,
    loc_txt = { name = "Sinister Minds", text = {
        "Retrigger all scored cards #1# time#2#",
        "if played hand is a #7#",
        "Increases by #3# when",
        "using #4# Spectral card#6#,",
        "then requirement increases by #9#",
        "(Currently #8# Spectral card#6# left)",
    } },
    calculate = function(self, card, context)
        local e = card.ability.extra
        if context.repetition and context.cardarea == pb4_play() then
            if (context.scoring_name == e.hand)
                or (context.poker_hands and context.poker_hands[e.hand]
                    and next(context.poker_hands[e.hand])) then
                return { repetitions = e.retriggers }
            end
        end
        if context.using_consumeable and context.port
            and context.port.consumable_kind == "spectral" then
            e.spectrals_left = e.spectrals_left - e.a_retriggers
            if e.spectrals_left <= 0 then
                e.retriggers = e.retriggers + e.a_retriggers
                e.required_spectrals = e.required_spectrals + e.required_inc
                e.spectrals_left = e.required_spectrals
                return { message = "Upgrade!" }
            end
        end
    end,
}

-- skydiver
SMODS.Joker {
    key = "skydiver",
    name = "Skydiver",
    rarity = 2,
    cost = 6,
    sprite = "skydiver.png",
    negative_sprite = "skydiver_negative.png",
    config = { extra = { x_mult = 2, lowest_rank = 14, lowest_name = "Ace" } },
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        return { vars = { e.x_mult, e.lowest_name } }
    end,
    loc_txt = { name = "Skydiver", text = {
        "X#1# Mult if all scored cards",
        "are less than or equal to the",
        "lowest rank scored this round",
        "(Updates at end of played hand)",
        "(Currently: #2#)",
    } },
    calculate = function(self, card, context)
        local e = card.ability.extra
        if context.joker_main and context.scoring_hand then
            for _, view in ipairs(context.scoring_hand) do
                local d = view.card_data or {}
                if d.enhancement ~= "stone"
                    and (view:get_id() or 0) > e.lowest_rank then
                    return
                end
            end
            return { xmult = e.x_mult }
        end
        if context.after and context.scoring_hand then
            local names = { [11] = "Jack", [12] = "Queen", [13] = "King",
                [14] = "Ace" }
            local new_low = e.lowest_rank
            for _, view in ipairs(context.scoring_hand) do
                local d = view.card_data or {}
                if d.enhancement ~= "stone" then
                    local id = view:get_id() or 0
                    if id > 0 and id < new_low then new_low = id end
                end
            end
            if new_low ~= e.lowest_rank then
                e.lowest_rank = new_low
                e.lowest_name = names[new_low] or tostring(new_low)
                return { message = e.lowest_name }
            end
        end
        if context.end_of_round then
            e.lowest_rank = 14
            e.lowest_name = "Ace"
            return { message = "Reset!" }
        end
    end,
}

-- small_scale_onshore_wind
SMODS.Joker {
    key = "small_scale_onshore_wind",
    name = "Small Scale Onshore Wind",
    rarity = 1,
    cost = 6,
    sprite = "small_scale_onshore_wind.png",
    negative_sprite = "small_scale_onshore_wind_negative.png",
    config = { extra = { mult = 0, bonus = 2, card_req = 5 } },
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        return { vars = { e.bonus, e.card_req, e.mult } }
    end,
    loc_txt = { name = "Small Scale Onshore Wind", text = {
        "This Joker gains +#1# Mult",
        "per consecutive discard",
        "of exactly #2# cards",
        "(Currently +#3# Mult)",
    } },
    calculate = function(self, card, context)
        local e = card.ability.extra
        if context.pre_discard then
            local nodes = (context.port and context.port.discarded_nodes)
                or context.full_hand
            if nodes and #nodes == e.card_req then
                e.mult = e.mult + e.bonus
                return { message = "Upgrade!" }
            end
            e.mult = 0
        end
        if context.joker_main and e.mult > 0 then
            return { mult = e.mult }
        end
    end,
}

-- soft_taco
SMODS.Joker {
    key = "soft_taco",
    name = "Soft Taco",
    rarity = 2,
    cost = 6,
    sprite = "soft_taco.png",
    negative_sprite = "soft_taco_negative.png",
    config = { extra = { x_mult = 3, odds = 6 } },
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        local n, d = SMODS.get_probability_vars(card, 1, e.odds,
            "paperback_soft_taco")
        return { vars = { e.x_mult, n, d } }
    end,
    loc_txt = { name = "Soft Taco", text = {
        "X#1# Mult",
        "#2# in #3# chance this card",
        "is eaten at end of round",
    } },
    calculate = function(self, card, context)
        local e = card.ability.extra
        if context.joker_main then return { xmult = e.x_mult } end
        if context.end_of_round then
            if SMODS.pseudorandom_probability(card, "pb4_soft_taco", 1,
                e.odds, "paperback_soft_taco") then
                SMODS.destroy_joker(card)
                return { message = "Eaten!" }
            end
            return { message = "Safe!" }
        end
    end,
}

-- solar_eclipse
SMODS.Joker {
    key = "solar_eclipse",
    name = "Solar Eclipse",
    rarity = 3,
    cost = 6,
    sprite = "solar_eclipse.png",
    negative_sprite = "solar_eclipse_negative.png",
    config = { extra = { suit = "Crowns" } },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.suit } }
    end,
    loc_txt = { name = "Solar Eclipse", text = {
        "Scored light suits",
        "become #1#",
    } },
    calculate = function(self, card, context)
        if context.after and context.scoring_hand then
            local changed = 0
            for _, view in ipairs(context.scoring_hand) do
                local d = view.card_data
                if d and d.enhancement ~= "stone" and d.suit ~= "Crowns"
                    and pb4_is_light(view) then
                    d.suit = "Crowns"
                    pb4_sync(view)
                    changed = changed + 1
                end
            end
            if changed > 0 then return { message = "Eclipse!" } end
        end
    end,
}

-- solar_system
SMODS.Joker {
    key = "solar_system",
    name = "Solar System",
    rarity = 2,
    cost = 8,
    sprite = "solar_system.png",
    negative_sprite = "solar_system_negative.png",
    config = { extra = { x_mult_mod = 1.5 } },
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        return { vars = { e.x_mult_mod, e.x_mult_mod * pb4_min_hand_level(),
            "Planet" } }
    end,
    loc_txt = { name = "Solar System", text = {
        "Gives X#1# Mult for",
        "every level all 9",
        "base Planet hands share",
        "(Currently X#2# Mult)",
    } },
    calculate = function(self, card, context)
        if context.joker_main then
            local x = card.ability.extra.x_mult_mod * pb4_min_hand_level()
            if x > 1 then return { xmult = x } end
        end
    end,
}

-- solemn_lament
SMODS.Joker {
    key = "solemn_lament",
    name = "Solemn Lament",
    rarity = 3,
    cost = 8,
    sprite = "solemn_lament.png",
    negative_sprite = "solemn_lament_negative.png",
    config = { extra = { x_mult_mod = 0.15, x_mult = 1 } },
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        return { vars = { e.x_mult_mod, e.x_mult } }
    end,
    loc_txt = { name = "Solemn Lament", text = {
        "This Joker gains X#1# Mult",
        "if scored hand contains both",
        "dark and light suits",
        "(Currently X#2# Mult)",
    } },
    calculate = function(self, card, context)
        local e = card.ability.extra
        if context.before and context.scoring_hand then
            local dark, light = false, false
            for _, view in ipairs(context.scoring_hand) do
                local d = view.card_data or {}
                if d.enhancement ~= "stone" then
                    if pb4_is_dark(view) then dark = true end
                    if pb4_is_light(view) then light = true end
                end
            end
            if dark and light then
                e.x_mult = pb4_round2(e.x_mult + e.x_mult_mod)
                return { message = "Upgrade!" }
            end
        end
        if context.joker_main and e.x_mult > 1 then
            return { xmult = e.x_mult }
        end
    end,
}

-- stamp
SMODS.Joker {
    key = "stamp",
    name = "Stamp",
    rarity = 3,
    cost = 8,
    sprite = "stamp.png",
    negative_sprite = "stamp_negative.png",
    config = { extra = {
        chips = 0, chip_mod = 25, numerator = 2, denominator = 5,
    } },
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        local n, d = SMODS.get_probability_vars(card, e.numerator,
            e.denominator, "paperback_stamp")
        return { vars = { n, d, e.chip_mod, e.chips } }
    end,
    loc_txt = { name = "Stamp", text = {
        "#1# in #2# chance this",
        "Joker gains +#3# Chips when",
        "any card with a seal is scored",
        "(Currently +#4# Chips)",
    } },
    calculate = function(self, card, context)
        local e = card.ability.extra
        if context.individual and context.cardarea == pb4_play()
            and context.other_card and context.other_card.card_data
            and context.other_card.card_data.seal then
            if SMODS.pseudorandom_probability(card, "pb4_stamp",
                e.numerator, e.denominator, "paperback_stamp") then
                e.chips = e.chips + e.chip_mod
                return { message = "Upgrade!" }
            end
        end
        if context.joker_main and e.chips > 0 then
            return { chips = e.chips }
        end
    end,
}

-- sticky_stick
SMODS.Joker {
    key = "sticky_stick",
    name = "Sticky Stick",
    rarity = 1,
    cost = 7,
    sprite = "sticky_stick.png",
    negative_sprite = "sticky_stick_negative.png",
    config = { extra = { xMult_if_stick = 2 } },
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        local current = pb4_stick_count(card, false) > 0
            and e.xMult_if_stick or 1
        return { vars = { e.xMult_if_stick, current } }
    end,
    loc_txt = { name = "Sticky Stick", text = {
        "X#1# Mult if you have",
        "another \"Stick\" Joker",
        "(Currently X#2# Mult)",
    } },
    calculate = function(self, card, context)
        if context.joker_main and pb4_stick_count(card, false) > 0 then
            return { xmult = card.ability.extra.xMult_if_stick }
        end
    end,
}

-- stout
-- PORT NOTE: PC grants perma_bonus through its card-ability hook; the fork
-- has no such hook, so the Chips are written to card_data.chip_bonus, the
-- field the fork's scoring reads (Minor Arcana ten_of_wands precedent).
SMODS.Joker {
    key = "stout",
    name = "Stout",
    rarity = 2,
    cost = 6,
    sprite = "stout.png",
    negative_sprite = "stout_negative.png",
    config = { extra = { amount = 30, suit = "Spades", remaining = 5 } },
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        return { vars = { e.remaining, e.suit, e.amount } }
    end,
    loc_txt = { name = "Stout", text = {
        "The next #1# played and scored #2#",
        "permanently gain +#3# Chips when scored",
    } },
    calculate = function(self, card, context)
        local e = card.ability.extra
        if context.individual and context.cardarea == pb4_play()
            and context.other_card and e.remaining > 0
            and context.other_card:is_suit(e.suit) then
            local d = context.other_card.card_data
            if d then
                d.chip_bonus = (tonumber(d.chip_bonus) or 0) + e.amount
                pb4_sync(context.other_card)
            end
            e.remaining = e.remaining - 1
            return { message = "+" .. e.amount .. " Chips" }
        end
        if context.after and e.remaining <= 0 then
            SMODS.destroy_joker(card)
            return { message = "Eaten!" }
        end
    end,
}

-- subterfuge
-- Destroy-ordering follows the task contract: the played hand is stashed
-- at `before` and destroyed in the after pass.
local pb4_sub_pending = {}
SMODS.Joker {
    key = "subterfuge",
    name = "Subterfuge",
    rarity = 3,
    cost = 8,
    sprite = "subterfuge.png",
    negative_sprite = "subterfuge_negative.png",
    loc_txt = { name = "Subterfuge", text = {
        "Destroys the first played",
        "hand every round",
    } },
    calculate = function(self, card, context)
        if context.before and pb4_hands_played() <= 1 then
            local views = {}
            for _, view in ipairs(context.full_hand or {}) do
                views[#views + 1] = view
            end
            pb4_sub_pending[card] = views
        end
        if context.after then
            local views = pb4_sub_pending[card]
            pb4_sub_pending[card] = nil
            if views and #views > 0 then
                for _, view in ipairs(views) do SMODS.destroy_card(view) end
                return { message = "Destroyed!" }
            end
        end
        if context.end_of_round then pb4_sub_pending[card] = nil end
    end,
}

-- summoning_circle
SMODS.Joker {
    key = "summoning_circle",
    name = "Summoning Circle",
    rarity = 3,
    cost = 8,
    sprite = "summoning_circle.png",
    negative_sprite = "summoning_circle_negative.png",
    config = { extra = { hand = "Five of a Kind" } },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.hand } }
    end,
    loc_txt = { name = "Summoning Circle", text = {
        "If played hand contains a",
        "#1#, create a copy",
        "of a random consumable",
        "(Must have room)",
    } },
    calculate = function(self, card, context)
        local e = card.ability.extra
        if context.before and context.poker_hands
            and context.poker_hands[e.hand]
            and next(context.poker_hands[e.hand]) then
            local g = pb4_game()
            local held = (g and g.consumables) or {}
            if #held == 0 then return end
            local src = held[SMODS.pseudorandom("pb4_summoning", 1, #held)]
            if not src or not src.id then return end
            local kind = src.kind or "tarot"
            local set = kind
            if kind == "tarot" then set = "Tarot"
            elseif kind == "planet" then set = "Planet"
            elseif kind == "spectral" then set = "Spectral" end
            local edition = nil
            if src.edition == "foil" or src.edition == "holo"
                or src.edition == "polychrome" then
                edition = src.edition
            end
            local made = SMODS.add_card {
                set = set, key = src.id, edition = edition,
            }
            if made then return { message = "Duplicated!" } end
        end
    end,
}

-- superjoker
-- PORT NOTE: PC retriggers the whole first hand through the joker-level
-- repetition pass, which the fork does not raise; the port returns one
-- repetition per scored card on the first hand instead (same net effect).
-- The fork counts the hand in progress, so the first hand reads 1 played.
SMODS.Joker {
    key = "superjoker",
    name = "SUPERJOKER",
    rarity = 2,
    cost = 5,
    sprite = "superjoker.png",
    negative_sprite = "superjoker_negative.png",
    config = { extra = { x_mult = 0.5 } },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.x_mult } }
    end,
    loc_txt = { name = "SUPERJOKER", text = {
        "Retrigger all cards in first hand",
        "Gives X#1# Mult on subsequent hands",
    } },
    calculate = function(self, card, context)
        local played = pb4_hands_played()
        if context.repetition and context.cardarea == pb4_play()
            and played <= 1 then
            return { repetitions = 1, message = "Again!" }
        end
        if context.joker_main and played >= 2 then
            return { xmult = card.ability.extra.x_mult }
        end
    end,
}

-- sweet_stick
SMODS.Joker {
    key = "sweet_stick",
    name = "Sweet Stick",
    rarity = 1,
    cost = 7,
    sprite = "sweet_stick.png",
    negative_sprite = "sweet_stick_negative.png",
    config = { extra = { xMult = 1.5 } },
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        local current = e.xMult ^ pb4_stick_count(card, true)
        return { vars = { e.xMult, pb4_round2(current) } }
    end,
    loc_txt = { name = "Sweet Stick", text = {
        "Gives X#1# Mult for every",
        "\"Stick\" Joker you have",
        "(Currently X#2# Mult)",
    } },
    calculate = function(self, card, context)
        if context.joker_main then
            local x = card.ability.extra.xMult ^ pb4_stick_count(card, true)
            if x > 1 then return { xmult = pb4_round2(x) } end
        end
    end,
}

-- takoyaki
SMODS.Joker {
    key = "takoyaki",
    name = "Takoyaki",
    rarity = 1,
    cost = 6,
    sprite = "takoyaki.png",
    negative_sprite = "takoyaki_negative.png",
    config = { extra = { dollars = 2, odds = 8, eaten = false } },
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        local n, d = SMODS.get_probability_vars(card, 1, e.odds,
            "paperback_takoyaki")
        return { vars = { "8", e.dollars, n, d } }
    end,
    loc_txt = { name = "Takoyaki", text = {
        "Scored #1#s give $#2#",
        "#3# in #4# chance to eat",
        "this Joker when an #1# scores",
    } },
    calculate = function(self, card, context)
        local e = card.ability.extra
        if context.individual and context.cardarea == pb4_play()
            and context.other_card and not e.eaten
            and context.other_card:get_id() == 8 then
            if SMODS.pseudorandom_probability(card, "pb4_takoyaki", 1,
                e.odds, "paperback_takoyaki") then
                e.eaten = true
                return { dollars = e.dollars, message = "Goner!" }
            end
            return { dollars = e.dollars }
        end
        if context.after and e.eaten then
            local edition = pb4_edition_of(card)
            SMODS.destroy_joker(card)
            if JOKER_DEFS and JOKER_DEFS["j_pbp_bamboo_stick"] then
                SMODS.add_card {
                    set = "Joker", key = "j_pbp_bamboo_stick",
                    edition = edition,
                }
            end
            return { message = "Eaten!" }
        end
    end,
}

-- tanghulu
SMODS.Joker {
    key = "tanghulu",
    name = "Tanghulu",
    rarity = 1,
    cost = 6,
    sprite = "tanghulu.png",
    negative_sprite = "tanghulu_negative.png",
    config = { extra = { mult = 10, odds = 4, suit = "Crowns" } },
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        local n, d = SMODS.get_probability_vars(card, 1, e.odds,
            "paperback_tanghulu")
        return { vars = { e.mult, n, d, e.suit } }
    end,
    loc_txt = { name = "Tanghulu", text = {
        "Scored #4# give +#1# Mult",
        "#2# in #3# chance this card is",
        "eaten at end of round",
    } },
    calculate = function(self, card, context)
        local e = card.ability.extra
        if context.individual and context.cardarea == pb4_play()
            and context.other_card
            and context.other_card:is_suit(e.suit) then
            return { mult = e.mult }
        end
        if context.end_of_round then
            if SMODS.pseudorandom_probability(card, "pb4_tanghulu", 1,
                e.odds, "paperback_tanghulu") then
                local edition = pb4_edition_of(card)
                SMODS.destroy_joker(card)
                if JOKER_DEFS and JOKER_DEFS["j_pbp_sweet_stick"] then
                    SMODS.add_card {
                        set = "Joker", key = "j_pbp_sweet_stick",
                        edition = edition,
                    }
                end
                return { message = "Eaten!" }
            end
            return { message = "Safe!" }
        end
    end,
}

-- telamon
SMODS.Joker {
    key = "telamon",
    name = "Telamon",
    rarity = 2,
    cost = 6,
    sprite = "telamon.png",
    negative_sprite = "telamon_negative.png",
    config = { extra = { hand = "Pair", active = false } },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.hand, "Minor Arcana" } }
    end,
    loc_txt = { name = "Telamon", text = {
        "If winning hand contains",
        "a #1#, create a random",
        "Swords #2# card",
        "(Must have room)",
    } },
    calculate = function(self, card, context)
        local e = card.ability.extra
        if context.after and context.poker_hands then
            e.active = context.poker_hands[e.hand] ~= nil
                and next(context.poker_hands[e.hand]) ~= nil
        end
        if context.end_of_round and e.active then
            e.active = false
            local g = pb4_game()
            local pool = {}
            for id, def in pairs(CONSUMABLE_DEFS or {}) do
                if type(def) == "table" and def.kind == "minor_arcana"
                    and id:find("swords", 1, true) then
                    pool[#pool + 1] = id
                end
            end
            local id = nil
            if #pool > 0 then
                id = pool[SMODS.pseudorandom("pb4_telamon", 1, #pool)]
            elseif g and g.random_consumable_id_of_kind then
                id = g:random_consumable_id_of_kind("minor_arcana",
                    nil, "pb4_telamon")
            end
            if id and SMODS.add_card { set = "minor_arcana", key = id } then
                return { message = "+Minor Arcana!" }
            end
        end
    end,
}

-- the_batter
-- Destroy-ordering follows the task contract: scored 3s are destroyed in
-- the after pass via SMODS.destroy_card on scoring_hand views.
SMODS.Joker {
    key = "the_batter",
    name = "The Batter",
    rarity = 2,
    cost = 4,
    sprite = "the_batter.png",
    negative_sprite = "the_batter_negative.png",
    config = { extra = { current = 0, max = 6, done = false } },
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        return { vars = { e.current, e.max, "3" } }
    end,
    loc_txt = { name = "The Batter", text = {
        "Scored 3s are destroyed",
        "(#1#/#2#...)",
    } },
    calculate = function(self, card, context)
        local e = card.ability.extra
        if context.after and context.scoring_hand and not e.done then
            local targets = {}
            for _, view in ipairs(context.scoring_hand) do
                if view:get_id() == 3 then targets[#targets + 1] = view end
            end
            if #targets == 0 then return end
            for _, view in ipairs(targets) do SMODS.destroy_card(view) end
            e.current = e.current + #targets
            if e.current >= e.max then
                e.done = true
                local edition = pb4_edition_of(card)
                SMODS.destroy_joker(card)
                if JOKER_DEFS and JOKER_DEFS["j_pbp_off_switch"] then
                    SMODS.add_card {
                        set = "Joker", key = "j_pbp_off_switch",
                        edition = edition,
                    }
                end
                return { message = "Destroyed!" }
            end
            return { message = e.current .. "/" .. e.max }
        end
    end,
}

-- the_dynasty
SMODS.Joker {
    key = "the_dynasty",
    name = "The Dynasty",
    rarity = 3,
    cost = 8,
    sprite = "the_dynasty.png",
    negative_sprite = "the_dynasty_negative.png",
    config = { extra = { xmult = 5, hand = "Spectrum" } },
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        return { vars = { e.xmult, e.hand } }
    end,
    loc_txt = { name = "The Dynasty", text = {
        "X#1# Mult if played",
        "hand contains",
        "a #2#",
    } },
    calculate = function(self, card, context)
        local e = card.ability.extra
        if context.joker_main and context.poker_hands
            and context.poker_hands[e.hand]
            and next(context.poker_hands[e.hand]) then
            return { xmult = e.xmult }
        end
    end,
}

-- the_normal_joker
SMODS.Joker {
    key = "the_normal_joker",
    name = "The Normal Joker",
    rarity = 3,
    cost = 8,
    sprite = "the_normal_joker.png",
    negative_sprite = "the_normal_joker_negative.png",
    config = { extra = { rarity = 1 } },
    loc_txt = { name = "The Normal Joker", text = {
        "Retrigger all",
        "Common Jokers",
    } },
    calculate = function(self, card, context)
        if context.retrigger_joker_check and context.other_card
            and context.other_card ~= card then
            if pb4_joker_rarity(context.other_card)
                == card.ability.extra.rarity then
                return { repetitions = 1 }
            end
        end
    end,
}

-- the_one_who_waits
SMODS.Joker {
    key = "the_one_who_waits",
    name = "The One Who Waits",
    rarity = 3,
    cost = 8,
    sprite = "the_one_who_waits.png",
    negative_sprite = "the_one_who_waits_negative.png",
    config = { extra = {
        suit = "Crowns", upgrade_odds = 3, x_mult = 1, x_mult_mod = 0.1,
        tarot_odds = 6,
    } },
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        local n1, d1 = SMODS.get_probability_vars(card, 1, e.upgrade_odds,
            "paperback_one_who_waits_upgrade")
        local n2, d2 = SMODS.get_probability_vars(card, 1, e.tarot_odds,
            "paperback_one_who_waits_tarot")
        return { vars = { e.suit, n1, d1, e.x_mult_mod, n2, d2, "Death",
            e.x_mult } }
    end,
    loc_txt = { name = "The One Who Waits", text = {
        "When a #1# is scored,",
        "#2# in #3# chance this Joker gains X#4# Mult",
        "(Currently X#8# Mult)",
        "#5# in #6# chance to create a #7# Tarot",
        "(Must have room)",
    } },
    calculate = function(self, card, context)
        local e = card.ability.extra
        if context.individual and context.cardarea == pb4_play()
            and context.other_card
            and context.other_card:is_suit(e.suit) then
            local upgraded = false
            if SMODS.pseudorandom_probability(card, "pb4_waits_upgrade",
                1, e.upgrade_odds, "paperback_one_who_waits_upgrade") then
                e.x_mult = pb4_round2(e.x_mult + e.x_mult_mod)
                upgraded = true
            end
            local made = false
            if SMODS.pseudorandom_probability(card, "pb4_waits_tarot",
                1, e.tarot_odds, "paperback_one_who_waits_tarot") then
                made = SMODS.add_card {
                    set = "Tarot", key = "tarot_death",
                } ~= nil
            end
            if upgraded then return { message = "Upgrade!" } end
            if made then return { message = "+Tarot!" } end
        end
        if context.joker_main and e.x_mult > 1 then
            return { xmult = e.x_mult }
        end
    end,
}

-- the_sun
SMODS.Joker {
    key = "the_sun",
    name = "The Sun",
    rarity = 1,
    cost = 3,
    sprite = "the_sun.png",
    negative_sprite = "the_sun_negative.png",
    config = { extra = { a_mult = 2, mult = 0 } },
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        return { vars = { e.a_mult, e.mult } }
    end,
    loc_txt = { name = "The Sun", text = {
        "If all scored suits are light,",
        "this Joker gains +#1# Mult",
        "When a suit that isn't light scores,",
        "this Joker loses -#1# Mult",
        "(Currently +#2# Mult)",
    } },
    calculate = function(self, card, context)
        local e = card.ability.extra
        if context.before and context.scoring_hand
            and #context.scoring_hand > 0 then
            local all_light = true
            for _, view in ipairs(context.scoring_hand) do
                local d = view.card_data or {}
                if d.enhancement == "stone" or not pb4_is_light(view) then
                    all_light = false
                    break
                end
            end
            if all_light then
                e.mult = e.mult + e.a_mult
                return { message = "Upgrade!" }
            end
        end
        if context.individual and context.cardarea == pb4_play()
            and context.other_card and e.mult > 0 then
            local d = context.other_card.card_data or {}
            if d.enhancement == "stone"
                or not pb4_is_light(context.other_card) then
                e.mult = e.mult - e.a_mult
                return { message = "Downgrade!" }
            end
        end
        if context.joker_main and e.mult ~= 0 then
            return { mult = e.mult }
        end
    end,
}

-- thornring
-- PORT NOTE: PC cycles hand targets through destroy_card checks and has a
-- second "weird" description once the list runs out; the port keeps one
-- description, tracks the cycle in extra (as PC does), destroys the played
-- hand in the after pass, and creates the Spectral there.
local PB4_THORNRING_FALLBACK = {
    "High Card", "Pair", "Two Pair", "Three of a Kind", "Straight",
    "Flush", "Full House", "Four of a Kind", "Straight Flush",
    "Five of a Kind", "Flush House", "Flush Five",
}
local function pb4_thornring_proceed(card)
    local e = card.ability.extra
    if #e.remaining == 0 then
        e.current = nil
        return
    end
    local idx = SMODS.pseudorandom("pb4_thornring", 1, #e.remaining)
    e.current = table.remove(e.remaining, idx)
end
SMODS.Joker {
    key = "thornring",
    name = "ThornRing",
    rarity = 3,
    cost = 7,
    sprite = "thornring.png",
    negative_sprite = "thornring_negative.png",
    config = { extra = { remaining = {}, current = "High Card",
        suit = "Hearts" } },
    set_ability = function(self, card, initial)
        if not initial then return end
        local g = pb4_game()
        local names = {}
        if g and g.handlist then
            for _, n in ipairs(g.handlist) do names[#names + 1] = n end
        end
        if #names == 0 then
            for _, n in ipairs(PB4_THORNRING_FALLBACK) do
                names[#names + 1] = n
            end
        end
        card.ability.extra.remaining = names
        pb4_thornring_proceed(card)
    end,
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        if e.current then
            return { vars = { e.current, #e.remaining + 1 } }
        end
        return { vars = { e.suit, 0 } }
    end,
    loc_txt = { name = "ThornRing", text = {
        "When a #1# is played,",
        "destroy the played hand and",
        "create a random Spectral card",
        "(Must have room)",
        "* #2# left.",
    } },
    calculate = function(self, card, context)
        local e = card.ability.extra
        if context.after and context.poker_hands then
            local trigger = false
            if e.current then
                trigger = context.poker_hands[e.current] ~= nil
                    and next(context.poker_hands[e.current]) ~= nil
            else
                for _, view in ipairs(context.scoring_hand or {}) do
                    if view:is_suit(e.suit) then trigger = true break end
                end
            end
            if trigger then
                local views = {}
                for _, view in ipairs(context.full_hand
                    or context.scoring_hand or {}) do
                    views[#views + 1] = view
                end
                for _, view in ipairs(views) do SMODS.destroy_card(view) end
                local g = pb4_game()
                if g and g.random_consumable_id_of_kind then
                    local id = g:random_consumable_id_of_kind("spectral",
                        nil, "pb4_thornring")
                    if id then
                        SMODS.add_card { set = "Spectral", key = id }
                    end
                end
                pb4_thornring_proceed(card)
                return { message = "Proceed!" }
            end
        end
    end,
}

-- tome
-- PORT NOTE: PC polls in update(); the fork recomputes consumable slots
-- from card.ability on demand, so the port refreshes its own
-- ability.consumable_slots whenever it calculates or joins/leaves.
local function pb4_tome_refresh(card)
    local seen, n = {}, 0
    for _, j in ipairs(pb4_jokers()) do
        local r = pb4_joker_rarity(j)
        if r and not seen[r] then seen[r] = true n = n + 1 end
    end
    if n == 0 then n = 1 end
    card.ability.consumable_slots = n
    card.ability.extra.slots = n
end
SMODS.Joker {
    key = "tome",
    name = "Tome",
    rarity = 2,
    cost = 6,
    sprite = "tome.png",
    negative_sprite = "tome_negative.png",
    config = { consumable_slots = 1, extra = { slots_per = 1, slots = 1 } },
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        return { vars = { e.slots_per, e.slots,
            e.slots == 1 and "" or "s" } }
    end,
    loc_txt = { name = "Tome", text = {
        "+#1# Consumable Slot for every",
        "unique Joker rarity you have",
        "(Currently +#2# Slot#3#)",
    } },
    add_to_deck = function(self, card) pb4_tome_refresh(card) end,
    remove_from_deck = function(self, card)
        card.ability.consumable_slots = 0
        card.ability.extra.slots = 0
    end,
    calculate = function(self, card, context)
        pb4_tome_refresh(card)
    end,
}

-- torii
-- PORT NOTE: PC tracks finished antes in its own run state; the port
-- keeps the finished-ante set in extra (string keys) and moves the ante
-- with the game's own ante-change event (Bunco Carnival precedent).
SMODS.Joker {
    key = "torii",
    name = "Torii",
    rarity = 3,
    cost = 8,
    sprite = "torii.png",
    negative_sprite = "torii_negative.png",
    config = { extra = {
        max = 2, current = 0, antes = -1, finished_antes = {},
    } },
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        local g = pb4_game()
        local ante = g and tonumber(g.ante)
        local finished = ante ~= nil
            and e.finished_antes[tostring(ante)] == true
        return { vars = { e.antes, e.max, e.max - e.current,
            finished and "Inactive" or "Active" } }
    end,
    loc_txt = { name = "Torii", text = {
        "Gives #1# Ante every",
        "#2# (#3#) skipped Blinds",
        "(Only counts skips in new antes,",
        "currently #4#)",
    } },
    calculate = function(self, card, context)
        local e = card.ability.extra
        local g = pb4_game()
        if context.ante_change and context.ante_end and g then
            local ended = (tonumber(g.ante) or 1)
                - (tonumber(context.ante_change) or 0)
            e.finished_antes[tostring(ended)] = true
        end
        if context.skip_blind and g then
            local ante = tonumber(g.ante) or 1
            if e.finished_antes[tostring(ante)] then return end
            e.current = e.current + 1
            if e.current >= e.max then
                e.current = 0
                g.ante = ante + e.antes
                if g.emit_joker_event then
                    g:emit_joker_event("on_ante_change", {
                        ante_change = e.antes, ante_end = false,
                    })
                end
                return { message = "-1 Ante" }
            end
            return { message = e.current .. "/" .. e.max }
        end
    end,
}

-- towering_pillar_of_hats
SMODS.Joker {
    key = "towering_pillar_of_hats",
    name = "Towering Pillar of Hats",
    rarity = 1,
    cost = 6,
    sprite = "towering_pillar_of_hats.png",
    negative_sprite = "towering_pillar_of_hats_negative.png",
    config = { extra = {
        mult = 0, change = 1, divisor = 2, suit = "Crowns",
    } },
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        return { vars = { e.change, e.mult, e.divisor, "Jack", "Queen",
            "King", e.suit } }
    end,
    loc_txt = { name = "Towering Pillar of Hats", text = {
        "Played #7# give +#1# Mult for every #3#",
        "#4#s, #5#s or #6#s in the deck",
        "(Currently +#2# Mult)",
    } },
    calculate = function(self, card, context)
        local e = card.ability.extra
        local g = pb4_game()
        if g and g.count_cards_in_full_deck then
            local tally = g:count_cards_in_full_deck(function(data)
                local r = tonumber(data.rank)
                return data.enhancement ~= "stone"
                    and (r == 11 or r == 12 or r == 13)
            end)
            e.mult = math.floor(tally / e.divisor) * e.change
        end
        if context.individual and context.cardarea == pb4_play()
            and context.other_card
            and context.other_card:is_suit(e.suit) and e.mult > 0 then
            return { mult = e.mult }
        end
    end,
}

-- trans_flag
SMODS.Joker {
    key = "trans_flag",
    name = "Trans Flag",
    rarity = 1,
    cost = 6,
    sprite = "trans_flag.png",
    negative_sprite = "trans_flag_negative.png",
    config = { extra = { a_mult = 5 } },
    loc_vars = function(self, info_queue, card)
        local g = pb4_game()
        local discards = tonumber(g and g.discards) or 0
        return { vars = { card.ability.extra.a_mult,
            discards * card.ability.extra.a_mult } }
    end,
    loc_txt = { name = "Trans Flag", text = {
        "Gives +#1# Mult for each",
        "remaining discard",
        "(Currently +#2# Mult)",
    } },
    calculate = function(self, card, context)
        local g = pb4_game()
        local discards = tonumber(g and g.discards) or 0
        if context.joker_main and discards > 0 then
            return { mult = discards * card.ability.extra.a_mult }
        end
    end,
}

-- triple_moon_goddess
-- This pack ships Minor Arcana, so the PC Minor-Arcana variant is used:
-- Tarot at 1 in 2 and Minor Arcana at 1 in 4 (no Planet roll).
SMODS.Joker {
    key = "triple_moon_goddess",
    name = "Triple Moon Goddess",
    rarity = 2,
    cost = 6,
    sprite = "triple_moon_goddess.png",
    negative_sprite = "triple_moon_goddess_negative.png",
    config = { extra = { tarot_odds = 2, minor_arcana_odds = 4 } },
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        local n1, d1 = SMODS.get_probability_vars(card, 1, e.tarot_odds,
            "paperback_triple_moon_tarot")
        local n2, d2 = SMODS.get_probability_vars(card, 1,
            e.minor_arcana_odds, "paperback_triple_moon_arcana")
        return { vars = { n1, d1, n2, d2 } }
    end,
    loc_txt = { name = "Triple Moon Goddess", text = {
        "If played hand contains a Three of a Kind,",
        "#1# in #2# chance to create a random Tarot card and",
        "#3# in #4# chance to create a random Minor Arcana card",
        "(Must have room)",
    } },
    calculate = function(self, card, context)
        local e = card.ability.extra
        if context.before and context.poker_hands
            and context.poker_hands["Three of a Kind"]
            and next(context.poker_hands["Three of a Kind"]) then
            local g = pb4_game()
            local made = false
            if SMODS.pseudorandom_probability(card, "pb4_moon_tarot", 1,
                e.tarot_odds, "paperback_triple_moon_tarot") then
                local id = g and g.random_consumable_id_of_kind
                    and g:random_consumable_id_of_kind("tarot", nil,
                        "pb4_moon_tarot")
                if id and SMODS.add_card { set = "Tarot", key = id } then
                    made = true
                end
            end
            if SMODS.pseudorandom_probability(card, "pb4_moon_arcana", 1,
                e.minor_arcana_odds, "paperback_triple_moon_arcana") then
                local id = g and g.random_consumable_id_of_kind
                    and g:random_consumable_id_of_kind("minor_arcana", nil,
                        "pb4_moon_arcana")
                if id and SMODS.add_card {
                    set = "minor_arcana", key = id,
                } then
                    made = true
                end
            end
            if made then return { message = "+Consumable!" } end
        end
    end,
}

-- tropic_birds
SMODS.Joker {
    key = "tropic_birds",
    name = "Tropic Birds",
    rarity = 1,
    cost = 6,
    sprite = "tropic_birds.png",
    negative_sprite = "tropic_birds_negative.png",
    config = { extra = { repetitions = 1, triggered = false } },
    loc_vars = function(self, info_queue, card)
        return { vars = { "Ace" } }
    end,
    loc_txt = { name = "Tropic Birds", text = {
        "If scoring hand",
        "contains an #1#,",
        "retrigger the first",
        "and last card",
    } },
    calculate = function(self, card, context)
        local e = card.ability.extra
        if context.before and context.scoring_hand then
            e.triggered = false
            for _, view in ipairs(context.scoring_hand) do
                if view:get_id() == 14 then e.triggered = true break end
            end
        end
        if context.repetition and context.cardarea == pb4_play()
            and e.triggered then
            local pos, total = pb4_scoring_pos(context)
            if pos and (pos == 1 or pos == total) then
                return { repetitions = e.repetitions, message = "Again!" }
            end
        end
        if context.after then e.triggered = false end
    end,
}

-- tutor
-- PORT NOTE: PC doubles numbered cards' Chip value through a
-- get_chip_bonus hook the fork does not expose; the port pays the card's
-- Chip value again when it scores, which doubles its Chips exactly.
SMODS.Joker {
    key = "tutor",
    name = "Tutor",
    rarity = 1,
    cost = 6,
    sprite = "tutor.png",
    negative_sprite = "tutor_negative.png",
    loc_txt = { name = "Tutor", text = {
        "Numbered cards have",
        "double Chip value",
    } },
    calculate = function(self, card, context)
        if context.individual and context.cardarea == pb4_play()
            and context.other_card then
            local rank = context.other_card:get_id() or 0
            if rank >= 2 and rank <= 10 then
                local v = pb4_chip_value(context.other_card)
                if v > 0 then return { chips = v } end
            end
        end
    end,
}

-- twenty_first_century
SMODS.Joker {
    key = "twenty_first_century",
    name = "21st Century Joker",
    rarity = 3,
    cost = 10,
    sprite = "twenty_first_century.png",
    negative_sprite = "twenty_first_century_negative.png",
    loc_txt = { name = "21st Century Joker", text = {
        "When Big Blind or Boss Blind",
        "is cleared, destroy Joker to the left",
        "and create a new Joker",
        "of equal or higher rarity",
        "(Cannot upgrade to Legendary Jokers)",
    } },
    calculate = function(self, card, context)
        if context.end_of_round then
            local idx = (context.port and context.port.blind_index)
                or (pb4_game() and pb4_game().current_blind_index)
            if idx ~= 2 and idx ~= 3 then return end
            local jokers = pb4_jokers()
            local my_pos = nil
            for i, j in ipairs(jokers) do
                if j == card then my_pos = i break end
            end
            if not my_pos then return end
            local target = jokers[my_pos - 1]
            if not target or target.eternal then return end
            local rarity = pb4_joker_rarity(target)
            if not rarity then return end
            local edition = pb4_edition_of(target)
            local new_rarity = rarity
            if rarity < 3 then
                new_rarity = rarity
                    + SMODS.pseudorandom("pb4_21c", 0, 1)
            end
            local g = pb4_game()
            if not (g and g.random_joker_def_id_by_rarity) then return end
            SMODS.destroy_joker(target)
            local id = g:random_joker_def_id_by_rarity(new_rarity,
                "pb4_21c")
            if id then
                SMODS.add_card {
                    set = "Joker", key = id, edition = edition,
                }
            end
            return { message = "Upgrade!" }
        end
    end,
}

-- ultra_rare
-- Temporary Jokers are tracked as transient object references in this
-- module-local registry (never in ability.extra, which is serialized).
local pb4_ultra_temp = {}
SMODS.Joker {
    key = "ultra_rare",
    name = "Ultra Rare",
    rarity = 3,
    cost = 9,
    sprite = "ultra_rare.png",
    negative_sprite = "ultra_rare_negative.png",
    config = { extra = { sell_value = 0 } },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.sell_value } }
    end,
    loc_txt = { name = "Ultra Rare", text = {
        "When Blind is selected, create",
        "random Common, Uncommon",
        "and Rare Temporary Negative",
        "Jokers with $#1# sell value",
    } },
    calculate = function(self, card, context)
        local e = card.ability.extra
        if context.setting_blind then
            local g = pb4_game()
            if not (g and g.random_joker_def_id_by_rarity) then return end
            local made = 0
            for rarity = 1, 3 do
                local id = g:random_joker_def_id_by_rarity(rarity,
                    "pb4_ultra")
                if id then
                    local j = SMODS.add_card {
                        set = "Joker", key = id, edition = "negative",
                    }
                    if j then
                        j.sell_cost = e.sell_value
                        pb4_ultra_temp[j] = true
                        made = made + 1
                    end
                end
            end
            if made > 0 then return { message = "Rare!" } end
        end
        if context.end_of_round then
            local held = {}
            for _, j in ipairs(pb4_jokers()) do held[j] = true end
            for j in pairs(pb4_ultra_temp) do
                if held[j] then SMODS.destroy_joker(j) end
                pb4_ultra_temp[j] = nil
            end
        end
    end,
}

-- war_without_reason
-- PORT NOTE: PC's paperclip check only excluded held cards that carry a
-- paperclip from the seal target pool; the paperclip system does not
-- exist in the fork, so that exclusion filter is dropped (per contract).
SMODS.Joker {
    key = "war_without_reason",
    name = "War Without Reason",
    rarity = 2,
    cost = 6,
    sprite = "war_without_reason.png",
    negative_sprite = "war_without_reason_negative.png",
    loc_txt = { name = "War Without Reason", text = {
        "When first hand is drawn,",
        "destroy Joker to the right",
        "and add a random seal",
        "to a card held in hand",
    } },
    calculate = function(self, card, context)
        if context.first_hand_drawn then
            local jokers = pb4_jokers()
            local my_pos = nil
            for i, j in ipairs(jokers) do
                if j == card then my_pos = i break end
            end
            if not my_pos then return end
            local target = jokers[my_pos + 1]
            if not target or target.eternal then return end
            SMODS.destroy_joker(target)
            local g = pb4_game()
            local nodes = g and g.hand and g.hand.card_nodes
            if nodes and #nodes > 0 then
                local view = nodes[SMODS.pseudorandom("pb4_war", 1, #nodes)]
                local seals = { "gold", "red", "blue", "purple" }
                local seal = seals[SMODS.pseudorandom("pb4_war_seal",
                    1, #seals)]
                if view and view.card_data then
                    view.card_data.seal = seal
                    pb4_sync(view)
                end
            end
            return { message = "War!" }
        end
    end,
}

-- wheat_field
-- Panorama family (PC PB_UTIL.panorama_logic): each scored suit card
-- pays the current XMult, then the XMult grows; resets after the hand.
SMODS.Joker {
    key = "wheat_field",
    name = "Wheat Field",
    rarity = 2,
    cost = 6,
    sprite = "wheat_field.png",
    negative_sprite = "wheat_field_negative.png",
    config = { extra = {
        xMult = 1.08, xMult_gain = 0.3, xMult_base = 1.08, suit = "Crowns",
    } },
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        return { vars = { e.suit, e.xMult, e.xMult_gain, e.suit } }
    end,
    loc_txt = { name = "Wheat Field", text = {
        "#1# give X#2# Mult when scored.",
        "Increases by X#3# Mult for each",
        "consecutively scored #4#",
        "(Resets after each hand played)",
    } },
    calculate = function(self, card, context)
        local e = card.ability.extra
        if context.individual and context.cardarea == pb4_play()
            and context.other_card
            and context.other_card:is_suit(e.suit) then
            local give = e.xMult
            e.xMult = pb4_round2(e.xMult + e.xMult_gain)
            return { xmult = give }
        end
        if context.after then e.xMult = e.xMult_base end
    end,
}

-- whitebeard
-- PORT NOTE: PC compares the live round score plus the hand in flight
-- against the Blind score; the port uses the banked round score plus
-- this hand's running total (context.port) in the after pass, then
-- destroys the winning played hand, per the destroy-ordering contract.
SMODS.Joker {
    key = "whitebeard",
    name = "Whitebeard",
    rarity = 3,
    cost = 8,
    sprite = "whitebeard.png",
    negative_sprite = "whitebeard_negative.png",
    config = { extra = { xmult = 1.5 } },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.xmult } }
    end,
    loc_txt = { name = "Whitebeard", text = {
        "During a Boss Blind,",
        "scored cards give X#1# Mult",
        "Defeating the Boss Blind",
        "destroys the winning hand",
    } },
    calculate = function(self, card, context)
        local e = card.ability.extra
        if context.individual and context.cardarea == pb4_play()
            and pb4_boss(context) then
            return { xmult = e.xmult }
        end
        if context.after and pb4_boss(context) then
            local g = pb4_game()
            if not g then return end
            local target = tonumber(g.current_blind_target) or 0
            if target <= 0 then return end
            local banked = tonumber(g.round_score) or 0
            local hand_score = (tonumber(context.port
                and context.port.chips) or 0)
                * (tonumber(context.port and context.port.mult) or 0)
            local total = banked
            if total <= target and hand_score > 0 then
                total = total + hand_score
            end
            if total > target then
                local views = {}
                for _, view in ipairs(context.full_hand
                    or context.scoring_hand or {}) do
                    views[#views + 1] = view
                end
                for _, view in ipairs(views) do SMODS.destroy_card(view) end
                if #views > 0 then return { message = "Destroyed!" } end
            end
        end
    end,
}

-- wild_plus_four
SMODS.Joker {
    key = "wild_plus_four",
    name = "Wild +4",
    rarity = 3,
    cost = 10,
    sprite = "wild_plus_four.png",
    negative_sprite = "wild_plus_four_negative.png",
    config = { h_size = 4, hands = -1, extra = { h_size = 4, hands = -1 } },
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        return { vars = { e.h_size, e.hands } }
    end,
    loc_txt = { name = "Wild +4", text = {
        "+#1# hand size",
        "#2# Hand",
    } },
}

-- wild_prize
SMODS.Joker {
    key = "wild_prize",
    name = "Wild Prize!",
    rarity = 1,
    cost = 7,
    sprite = "wild_prize.png",
    negative_sprite = "wild_prize_negative.png",
    config = { extra = {
        a_money_low = -1, a_money_high = 9, retrigger_odds = 4,
        money_odds = 2,
    } },
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        local n1, d1 = SMODS.get_probability_vars(card, 1,
            e.retrigger_odds, "paperback_wild_prize_retrigger")
        local n2, d2 = SMODS.get_probability_vars(card, 1, e.money_odds,
            "paperback_wild_prize_money")
        return { vars = { n1, d1, n2, d2, "-$1", e.a_money_high,
            "Wild Card" } }
    end,
    loc_txt = { name = "Wild Prize!", text = {
        "#7#s have a #1# in #2# chance",
        "to retrigger and a #3# in #4# chance",
        "to earn between #5# and $#6# when scored",
    } },
    calculate = function(self, card, context)
        local e = card.ability.extra
        if context.individual and context.cardarea == pb4_play()
            and context.other_card and context.other_card.card_data
            and context.other_card.card_data.enhancement == "wild" then
            if SMODS.pseudorandom_probability(card, "pb4_wild_money", 1,
                e.money_odds, "paperback_wild_prize_money") then
                local dollars = SMODS.pseudorandom("pb4_wild_amount",
                    e.a_money_low, e.a_money_high)
                return { dollars = dollars }
            end
        end
        if context.repetition and context.cardarea == pb4_play()
            and context.other_card and context.other_card.card_data
            and context.other_card.card_data.enhancement == "wild" then
            if SMODS.pseudorandom_probability(card, "pb4_wild_retrigger",
                1, e.retrigger_odds, "paperback_wild_prize_retrigger") then
                return { repetitions = 1, message = "Again!" }
            end
        end
    end,
}

-- wish_you_were_here
-- PORT NOTE: PC grows sell value through ability.extra_value + set_cost;
-- the fork's sell path reads the Joker's sell_cost field directly (Bunco
-- Loan Shark precedent), so the port increments that field.
SMODS.Joker {
    key = "wish_you_were_here",
    name = "Wish You Were Here",
    rarity = 2,
    cost = 6,
    sprite = "wish_you_were_here.png",
    negative_sprite = "wish_you_were_here_negative.png",
    config = { extra = { sv_gain = 1, mult_mod = 2 } },
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        return { vars = { e.mult_mod, e.sv_gain,
            e.mult_mod * (tonumber(card.sell_cost) or 0) } }
    end,
    loc_txt = { name = "Wish You Were Here", text = {
        "Gives +Mult equal to #1#X the",
        "sell value of this card.",
        "Gains $#2# of sell value",
        "at end of round",
        "(Currently +#3# Mult)",
    } },
    calculate = function(self, card, context)
        local e = card.ability.extra
        if context.joker_main then
            local mult = e.mult_mod * (tonumber(card.sell_cost) or 0)
            if mult ~= 0 then return { mult = mult } end
        end
        if context.end_of_round then
            card.sell_cost = (tonumber(card.sell_cost) or 0) + e.sv_gain
            return { message = "Value Up!" }
        end
    end,
}

-- yacht
SMODS.Joker {
    key = "yacht",
    name = "Yacht",
    rarity = 1,
    cost = 5,
    sprite = "yacht.png",
    negative_sprite = "yacht_negative.png",
    config = { extra = { chips = 0, change = 10 } },
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        return { vars = { e.change, e.chips, "Stars", "Crowns" } }
    end,
    loc_txt = { name = "Yacht", text = {
        "This Joker gains +#1# Chips if",
        "hand contains a scoring",
        "#3# or #4#",
        "(Currently +#2# Chips)",
    } },
    calculate = function(self, card, context)
        local e = card.ability.extra
        if context.before and context.scoring_hand then
            for _, view in ipairs(context.scoring_hand) do
                if view:is_suit("Stars") or view:is_suit("Crowns") then
                    e.chips = e.chips + e.change
                    return { message = "Upgrade!" }
                end
            end
        end
        if context.joker_main and e.chips > 0 then
            return { chips = e.chips }
        end
    end,
}

-- yacht_dice
SMODS.Joker {
    key = "yacht_dice",
    name = "Yacht Dice",
    rarity = 3,
    cost = 8,
    sprite = "yacht_dice.png",
    negative_sprite = "yacht_dice_negative.png",
    config = { extra = { change = 0.25, xm = 1 } },
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        local xm = 1 + e.change * pb4_distinct_hands_played(nil)
        return { vars = { e.change, pb4_round2(xm) } }
    end,
    loc_txt = { name = "Yacht Dice", text = {
        "This Joker gains X#1# Mult",
        "for each unique hand type",
        "played this run",
        "(Currently X#2# Mult)",
    } },
    calculate = function(self, card, context)
        local e = card.ability.extra
        if context.before then
            local xm = 1 + e.change
                * pb4_distinct_hands_played(context.scoring_name)
            if xm > e.xm then
                e.xm = pb4_round2(xm)
                return { message = "Upgrade!" }
            end
            e.xm = pb4_round2(xm)
        end
        if context.joker_main then
            local xm = 1 + e.change
                * pb4_distinct_hands_played(context.scoring_name)
            e.xm = pb4_round2(xm)
            if e.xm > 1 then return { xmult = e.xm } end
        end
    end,
}

-- you_are_a_fool
SMODS.Joker {
    key = "you_are_a_fool",
    name = "You Are a Fool!",
    rarity = 3,
    cost = 8,
    sprite = "you_are_a_fool.png",
    negative_sprite = "you_are_a_fool_negative.png",
    config = { extra = { faces = 3 } },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.faces } }
    end,
    loc_txt = { name = "You Are a Fool!", text = {
        "If scored hand contains #1#",
        "or more face cards, convert",
        "all cards held in hand to",
        "the leftmost scored card",
        "self-destructs",
    } },
    calculate = function(self, card, context)
        local e = card.ability.extra
        if context.after and context.scoring_hand
            and #context.scoring_hand > 0 then
            local faces = 0
            for _, view in ipairs(context.scoring_hand) do
                if view:is_face() then faces = faces + 1 end
            end
            if faces < e.faces then return end
            local src = (context.scoring_hand[1].card_data) or {}
            local g = pb4_game()
            local nodes = g and g.hand and g.hand.card_nodes
            if nodes then
                for _, view in ipairs(nodes) do
                    local d = view.card_data
                    if d then
                        for _, f in ipairs({ "rank", "suit", "enhancement",
                            "seal", "edition", "chip_bonus", "mult_bonus",
                            "chips" }) do
                            d[f] = src[f]
                        end
                        pb4_sync(view)
                    end
                end
            end
            SMODS.destroy_joker(card)
            return { message = "Destroyed!" }
        end
    end,
}

-- zealous_joker
SMODS.Joker {
    key = "zealous_joker",
    name = "Zealous Joker",
    rarity = 1,
    cost = 3,
    sprite = "zealous_joker.png",
    negative_sprite = "zealous_joker_negative.png",
    config = { extra = { mult = 10, hand = "Spectrum" } },
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        return { vars = { e.mult, e.hand } }
    end,
    loc_txt = { name = "Zealous Joker", text = {
        "+#1# Mult if played",
        "hand contains",
        "a #2#",
    } },
    calculate = function(self, card, context)
        local e = card.ability.extra
        if context.joker_main and context.poker_hands
            and context.poker_hands[e.hand]
            and next(context.poker_hands[e.hand]) then
            return { mult = e.mult }
        end
    end,
}
end

--------------------------------------------------------------------------------
-- Tier 3 expansion (v1.1.0): enhancements, tags, boosters, Dichrome edition
-- and the Jokers / Minor Arcana they unblock.
-- Ported from Paperback's MIT-licensed sources against the fork's Tier 3
-- API (SMODS.Enhancement / Tag / Booster / Edition, target_joker
-- consumables, and the joker_type_destroyed / money_altered / press_play /
-- blind_disabled / setting_ability / destroying_card / tag_added
-- contexts). Sub-effect deviations are marked with PORT NOTE comments.
--------------------------------------------------------------------------------
do

local function pb5_game() return rawget(_G, "G") end

local function pb5_jokers()
    local g = pb5_game()
    if not g then return {} end
    if g.jokers and g.jokers.cards then return g.jokers.cards end
    return g.jokers or {}
end

local function pb5_round2(x) return math.floor(x * 100 + 0.5) / 100 end

local function pb5_enh(view)
    local d = view and view.card_data
    if d and d.enhancement then return d.enhancement end
    return view and view.enhancement or nil
end

local function pb5_suit(view)
    local d = view and view.card_data
    if d and d.suit then return d.suit end
    return view and view.suit or nil
end

local function pb5_rank(view)
    local d = view and view.card_data
    local r = tonumber(d and d.rank)
    if r then return r end
    return tonumber(view and view.rank)
end

local PB5_RANK_CHIPS = { [11] = 10, [12] = 10, [13] = 10, [14] = 11 }
local function pb5_chip_value(view)
    local data = (view and view.card_data) or {}
    local base = tonumber(data.chips)
    if not base then
        base = PB5_RANK_CHIPS[tonumber(data.rank) or 0]
            or tonumber(data.rank) or 0
    end
    if data.enhancement == "bonus" then base = base + 30 end
    base = base + (tonumber(data.Bonus) or tonumber(data.bonus) or 0)
    return base
end

-- Nodes of the hand currently being scored: the play area when the engine
-- moved the cards there, else the hand nodes flagged as scoring.
local function pb5_scoring_nodes()
    local g = pb5_game()
    if not g then return {} end
    if g.play and type(g.play.card_nodes) == "table"
        and #g.play.card_nodes > 0 then
        return g.play.card_nodes
    end
    local out = {}
    if g.hand and type(g.hand.card_nodes) == "table" then
        for _, n in ipairs(g.hand.card_nodes) do
            if n.counts_for_play_score then out[#out + 1] = n end
        end
    end
    return out
end

-- Nodes still held in hand while a hand scores.
local function pb5_held_nodes()
    local g = pb5_game()
    local out = {}
    if not g or not g.hand or type(g.hand.card_nodes) ~= "table" then
        return out
    end
    local in_play = g.play and type(g.play.card_nodes) == "table"
        and #g.play.card_nodes > 0
    for _, n in ipairs(g.hand.card_nodes) do
        if in_play or not n.counts_for_play_score then out[#out + 1] = n end
    end
    return out
end

local function pb5_full_deck_data()
    local g = pb5_game()
    local out = {}
    if g and g.count_cards_in_full_deck then
        g:count_cards_in_full_deck(function(d)
            out[#out + 1] = d
            return false
        end)
    end
    return out
end

local function pb5_boss(context)
    local idx = context and context.port and context.port.blind_index
    if not idx then
        local g = pb5_game()
        idx = g and g.current_blind_index
    end
    return idx == 3
end

-- The fork's context translation marks both individual passes with
-- context.individual and tells them apart by cardarea (play area vs
-- hand), never with an individual_hand flag.
local function pb5_play_area(context)
    if not context.individual then return false end
    local g = pb5_game()
    if g and g.hand and context.cardarea == g.hand then return false end
    return true
end

local function pb5_hand_area(context)
    if not context.individual then return false end
    local g = pb5_game()
    return g and g.hand and context.cardarea == g.hand or false
end

local function pb5_add_tag(type_name)
    local g = pb5_game()
    if g and g.addTag and type_name then g:addTag(type_name) end
end

-- The pool PB_UTIL.poll_tag draws from on PC: every vanilla tag plus the
-- Paperback tags that appear in polls. Angel Investment and High Risk
-- carry in_pool = false on PC and are excluded.
local PB5_TAG_POOL = {
    "uncommon", "rare", "negative", "foil", "holo", "polychrome",
    "investment", "voucher", "boss", "standard", "charm", "meteor",
    "buffoon", "handy", "garbage", "ethereal", "coupon", "double",
    "juggle", "d6", "topup", "speed", "orbital", "economy",
    "breaking", "dichrome", "divination",
}

local function pb5_random_tag(seed)
    return PB5_TAG_POOL[SMODS.pseudorandom(seed, 1, #PB5_TAG_POOL)]
end

-- Kintsugi Joker's running total, summed over held copies: PC keeps it in
-- a G.GAME counter the Ceramic enhancement reads; the port reads the
-- Jokers directly, which is the same number.
local function pb5_ceramic_inc()
    local total = 0
    for _, j in ipairs(pb5_jokers()) do
        if j.def and j.def.id == "j_pbp_kintsugi_joker" then
            total = total + (tonumber(j.ability.extra.total) or 0)
        end
    end
    return total
end

--------------------------------------------------------------------------------
-- The 8 Paperback enhancements. All register at weight 0: on PC they are
-- source-gated (conversions and specific effects only) and never enter
-- the random enhancement polls.
--------------------------------------------------------------------------------

if SMODS.Enhancement then

-- PORT NOTE (Soaked): PC scores every held card in full (its own
-- enhancement, seal, edition and Joker-on-held effects) through
-- SMODS.score_card; the fork raises no per-card scoring pass for held
-- cards, so only each held card's Chip value is credited. The 1-in-2
-- destroy-on-discard half is unported: enhancement calculate is never
-- raised on discard in the fork.
SMODS.Enhancement {
    key = "soaked",
    loc_txt = { name = "Soaked Card", text = {
        "When scored, cards {C:attention}held in hand{}",
        "score their {C:chips}Chip value{}",
        "{C:green}#1# in #2#{} chance to",
        "{C:red}destroy{} card on {C:red}discard",
    } },
    config = { extra = { odds = 2 } },
    weight = 0,
    loc_vars = function(self, info_queue, card)
        return { vars = { 1, self.config.extra.odds } }
    end,
    calculate = function(self, card, context)
        if context.card_played then
            local total = 0
            for _, node in ipairs(pb5_held_nodes()) do
                total = total + pb5_chip_value(node)
            end
            if total > 0 then return { chips = total } end
        end
    end,
}

-- PORT NOTE (Sleeved): neither half has a hook in the fork. Boss debuffs
-- are Blind predicates, not applications a center can refuse, and no
-- center calculate is raised when a card is destroyed. It registers so
-- conversions can apply it and the gated Jokers can count it.
SMODS.Enhancement {
    key = "sleeved",
    loc_txt = { name = "Sleeved Card", text = {
        "Cannot be {C:attention}debuffed{} or",
        "{C:attention}flipped{} face down",
        "Earn {C:money}$#1#{} if destroyed",
    } },
    config = { extra = { money = 5 } },
    weight = 0,
    loc_vars = function(self, info_queue, card)
        return { vars = { self.config.extra.money } }
    end,
}

-- PORT NOTE (Bandaged): registered but inert. PC's effect answers a
-- repetition query from the scoring card beside it and a destroy query
-- when it is scored; the fork asks repetition and destruction questions
-- of seals and Jokers only, never of enhancements, so there is no
-- calculate moment this effect could live in.
SMODS.Enhancement {
    key = "bandaged",
    loc_txt = { name = "Bandaged Card", text = {
        "Retrigger {C:attention}adjacent{} cards",
        "{C:green}#1# in #2#{} chance to",
        "{C:red}break{} when scored",
    } },
    config = { extra = { odds = 5 } },
    weight = 0,
    loc_vars = function(self, info_queue, card)
        return { vars = { 1, self.config.extra.odds } }
    end,
}

-- PORT NOTE (Wrapped): PC's no_rank / no_suit / always_scores flags have
-- no counterpart in the fork's enhancement registration; the card keeps
-- its rank and suit and scores normally. The $2 on score is exact.
SMODS.Enhancement {
    key = "wrapped",
    loc_txt = { name = "Wrapped Card", text = {
        "Earn {C:money}$#1#{} when scored",
        "no rank or suit",
    } },
    config = { extra = { money = 2 } },
    weight = 0,
    loc_vars = function(self, info_queue, card)
        return { vars = { self.config.extra.money } }
    end,
    calculate = function(self, card, context)
        if context.card_played then
            return { dollars = self.config.extra.money }
        end
    end,
}

-- PORT NOTE (Ceramic): the shatter half is unported. PC decides it in a
-- destroy query answered after the final scoring step; the fork raises
-- neither moment for enhancement centers.
SMODS.Enhancement {
    key = "ceramic",
    loc_txt = { name = "Ceramic Card", text = {
        "Earn between {C:money}$#1#{}",
        "and {C:money}$#2#{} when scored",
        "{C:red}Shatters{} if {C:mult}Mult{} ended up",
        "{C:attention}greater{} than {C:chips}Chips{}",
        "while played or held",
    } },
    config = { extra = { a_money_low = 1, a_money_high = 5 } },
    weight = 0,
    loc_vars = function(self, info_queue, card)
        local inc = pb5_ceramic_inc()
        return { vars = { self.config.extra.a_money_low + inc,
            self.config.extra.a_money_high + inc } }
    end,
    calculate = function(self, card, context)
        if context.card_played then
            local inc = pb5_ceramic_inc()
            return { dollars = SMODS.pseudorandom("ceramic",
                self.config.extra.a_money_low + inc,
                self.config.extra.a_money_high + inc) }
        end
    end,
}

-- PORT NOTE (Domino): PC counts every distinct rank played or discarded
-- so far this round, tracked by a hook outside the def; the fork raises
-- no discard moment for centers and keeps no such tally, so the port
-- counts the distinct ranks of the hand being scored.
SMODS.Enhancement {
    key = "domino",
    loc_txt = { name = "Domino Card", text = {
        "{C:mult}+#1#{} Mult for every played",
        "or discarded rank this round",
        "{C:inactive}(Currently {C:mult}+#2#{C:inactive} Mult)",
    } },
    config = { extra = { scaling = 1 } },
    weight = 0,
    loc_vars = function(self, info_queue, card)
        local seen = {}
        for _, node in ipairs(pb5_scoring_nodes()) do
            local r = pb5_rank(node)
            if r then seen[r] = true end
        end
        local n = 0
        for _ in pairs(seen) do n = n + 1 end
        return { vars = { self.config.extra.scaling,
            self.config.extra.scaling * n } }
    end,
    calculate = function(self, card, context)
        if context.card_played then
            local seen = {}
            for _, node in ipairs(pb5_scoring_nodes()) do
                local r = pb5_rank(node)
                if r then seen[r] = true end
            end
            local n = 0
            for _ in pairs(seen) do n = n + 1 end
            if n > 0 then return { mult = self.config.extra.scaling * n } end
        end
    end,
}

SMODS.Enhancement {
    key = "stained",
    loc_txt = { name = "Stained Card", text = {
        "If {C:attention}held in hand{} after a",
        "hand is played, scored cards",
        "permanently gain {C:mult}+#1#{} Mult",
    } },
    config = { extra = { mult_mod = 1 } },
    weight = 0,
    loc_vars = function(self, info_queue, card)
        return { vars = { self.config.extra.mult_mod } }
    end,
    calculate = function(self, card, context)
        if context.held_in_hand and context.port
            and type(context.port.played_cards) == "table" then
            -- Pinot Noir raises the gain by 1 per copy while it lasts;
            -- PC keeps that in a G.GAME counter, the port scans for it.
            local bonus = self.config.extra.mult_mod
            for _, j in ipairs(pb5_jokers()) do
                if j.def and j.def.id == "j_pbp_pinot_noir"
                    and (tonumber(j.ability.extra.remaining) or 0) > 0 then
                    bonus = bonus + (tonumber(j.ability.extra.extra_mult) or 1)
                end
            end
            local hit = false
            for _, node in ipairs(context.port.played_cards) do
                local d = node.card_data
                if d then
                    d.mult_bonus = (tonumber(d.mult_bonus) or 0) + bonus
                    hit = true
                end
            end
            if hit then return { message = "Upgrade!" } end
        end
    end,
}

SMODS.Enhancement {
    key = "antique",
    loc_txt = { name = "Antique Card", text = {
        "{X:chips,C:white}X#1#{} Chips,",
        "increases by {X:chips,C:white}X#2#{} when",
        "played in scoring hand",
    } },
    config = { extra = { xchips = 1, xchips_mod = 0.1 } },
    weight = 0,
    loc_vars = function(self, info_queue, card)
        local d = card and card.card_data
        return { vars = { (d and tonumber(d.pb_antique_x)) or 1, 0.1 } }
    end,
    calculate = function(self, card, context)
        if context.card_played and card and card.card_data then
            local d = card.card_data
            -- PC grows the value in the `before` step and returns it at
            -- scoring; the fork raises one moment, so it grows and pays
            -- in the same step, the same total.
            d.pb_antique_x = pb5_round2(
                (tonumber(d.pb_antique_x) or 1) + self.config.extra.xchips_mod)
            return { x_chips = d.pb_antique_x }
        end
    end,
}

end -- SMODS.Enhancement

--------------------------------------------------------------------------------
-- Dichrome edition. PORT NOTE: PC's effect (+1 Hand or Discard, whichever
-- is lower, when a Blind is selected / the card is drawn) lives in an
-- edition calculate; the fork's edition registration takes config only
-- (chips / mult / x_mult / joker_slots) and raises no calculate for
-- editions, so the edition registers with no effect of its own. It is
-- kept out of the edition polls (weight 0; PC weighs it 3 in shop) so an
-- inert edition is never sold as a working one; Queen of Wands applies
-- it directly. Cost matches PC's extra_cost 5.
--------------------------------------------------------------------------------

if SMODS.Edition then
SMODS.Edition {
    key = "dichrome",
    loc_txt = { name = "Dichrome", text = {
        "When {C:attention}Blind{} is selected,",
        "gain {C:attention}+#1#{C:blue} Hand{} or {C:red}Discard",
        "{C:inactive}(Whichever is lower)",
    } },
    config = {},
    weight = 0,
    cost = 5,
    loc_vars = function(self, info_queue, card)
        return { vars = { 1 } }
    end,
}
end

--------------------------------------------------------------------------------
-- Paperback tags. (Divination included: its apply opens the registered
-- Mega Minor Arcana Pack through the same begin_booster_session the
-- vanilla pack tags use.)
--------------------------------------------------------------------------------

if SMODS.Tag then

SMODS.Tag {
    key = "angel_investment",
    loc_txt = { name = "Angel Investment Tag", text = {
        "Earn {C:money}$#1#{} per {C:money}$#2#{} you have",
        "{C:inactive}(Max of {C:money}$#3#{C:inactive})",
        "{C:inactive}(Will give {C:money}$#4#{C:inactive})",
    } },
    config = { type = "immediate", money = 1, every = 5, max = 100 },
    weight = 0,
    loc_vars = function(self, tag)
        local g = pb5_game()
        local money = tonumber(g and g.money) or 0
        local gain = math.min(self.config.max,
            math.floor(money / self.config.every) * self.config.money)
        return { vars = { self.config.money, self.config.every,
            self.config.max, gain } }
    end,
    apply = function(self, tag, context)
        local g = pb5_game()
        if not g then return false end
        local gain = math.min(tag.ability.max,
            math.floor((tonumber(g.money) or 0) / tag.ability.every)
                * tag.ability.money)
        if gain > 0 then
            if g.ease_dollars then g:ease_dollars(gain)
            else g.money = (tonumber(g.money) or 0) + gain end
        end
        return true
    end,
}

SMODS.Tag {
    key = "breaking",
    loc_txt = { name = "Breaking Tag", text = {
        "Disables the",
        "{C:attention}Boss Blind",
    } },
    config = { type = "round_start_bonus" },
    apply = function(self, tag, context)
        local g = pb5_game()
        if g and g.current_blind_index == 3 and g.disable_boss_blind then
            g:disable_boss_blind()
            return true
        end
        return false
    end,
}

-- PORT NOTE (High Risk): PC also doubles the Boss Blind's score
-- requirement; a tag apply gets no blind-target handle in the fork, so
-- only the $25 lands. The requirement half stays with the Blind.
SMODS.Tag {
    key = "high_risk",
    loc_txt = { name = "High Risk Tag", text = {
        "When selecting {C:attention}Boss",
        "{C:attention}Blind{}, {C:attention}double{} its",
        "score requirement",
        "and gain {C:money}$#1#",
    } },
    config = { type = "round_start_bonus", money = 25 },
    weight = 0,
    loc_vars = function(self, tag)
        return { vars = { self.config.money } }
    end,
    apply = function(self, tag, context)
        local g = pb5_game()
        if g and g.current_blind_index == 3 then
            if g.ease_dollars then g:ease_dollars(tag.ability.money)
            else g.money = (tonumber(g.money) or 0) + tag.ability.money end
            return true
        end
        return false
    end,
}

SMODS.Tag {
    key = "dichrome",
    loc_txt = { name = "Dichrome Tag", text = {
        "Next base edition shop",
        "Joker is free and",
        "becomes {C:dark_edition}Dichrome",
    } },
    config = { type = "store_joker_modify" },
    apply = function(self, tag, context)
        local offer = context.card
        if type(offer) == "table" and type(offer.id) == "string"
            and offer.id:sub(1, 2) == "j_"
            and (offer.edition == nil or offer.edition == "base") then
            offer.edition = "dichrome"
            offer.price = 0
            return true
        end
        return false
    end,
}

SMODS.Tag {
    key = "divination",
    loc_txt = { name = "Divination Tag", text = {
        "Gives a free",
        "{C:paperback_minor_arcana}Mega Minor Arcana Pack",
    } },
    config = { type = "new_blind_choice" },
    apply = function(self, tag, context)
        local g = pb5_game()
        if g and g.begin_booster_session then
            g:begin_booster_session({
                kind = "booster",
                pack = "minor_arcana_mega",
                price = 0,
                name = "Mega Minor Arcana Pack",
                card_count = 5,
                picks_granted = 2,
            })
            return true
        end
        return false
    end,
}

end -- SMODS.Tag

--------------------------------------------------------------------------------
-- Minor Arcana booster packs: how PC delivers the set (its shop_rate is
-- 0 there for this reason). One registration per size; PC's extra
-- variants differ only in wrapper art, which this snapshot's Boosters
-- atlas does not survive to port, so the packs register without a
-- sprite and draw the fork's fallback panel.
--------------------------------------------------------------------------------

if SMODS.Booster then

SMODS.Booster {
    key = "minor_arcana_normal",
    loc_txt = { name = "Minor Arcana Pack", text = {
        "Choose {C:attention}1{} of up to {C:attention}3{}",
        "{C:paperback_minor_arcana}Minor Arcana{} cards",
        "to be used immediately",
    } },
    pool = { consumable = "minor_arcana" },
    card_count = 3, picks = 1, cost = 4, weight = 100,
    colour = { 0.55, 0.45, 0.85 },
}

SMODS.Booster {
    key = "minor_arcana_jumbo",
    loc_txt = { name = "Jumbo Minor Arcana Pack", text = {
        "Choose {C:attention}1{} of up to {C:attention}5{}",
        "{C:paperback_minor_arcana}Minor Arcana{} cards",
        "to be used immediately",
    } },
    pool = { consumable = "minor_arcana" },
    card_count = 5, picks = 1, cost = 6, weight = 100,
    colour = { 0.55, 0.45, 0.85 },
}

SMODS.Booster {
    key = "minor_arcana_mega",
    loc_txt = { name = "Mega Minor Arcana Pack", text = {
        "Choose {C:attention}2{} of up to {C:attention}5{}",
        "{C:paperback_minor_arcana}Minor Arcana{} cards",
        "to be used immediately",
    } },
    pool = { consumable = "minor_arcana" },
    card_count = 5, picks = 2, cost = 8, weight = 25,
    colour = { 0.55, 0.45, 0.85 },
}

end -- SMODS.Booster

--------------------------------------------------------------------------------
-- Jokers gated on the enhancements
--------------------------------------------------------------------------------

if SMODS.Joker then

-- collector
SMODS.Joker {
    key = "collector",
    name = "Collector",
    rarity = 2,
    cost = 7,
    sprite = "collector.png",
    negative_sprite = "collector_negative.png",
    config = { extra = { money = 1 } },
    loc_vars = function(self, info_queue, card)
        local g = pb5_game()
        local n = 0
        if g and g.count_cards_in_full_deck then
            n = g:count_cards_in_full_deck(function(d)
                return d.enhancement == "sleeved"
            end)
        end
        return { vars = { card.ability.extra.money, "Sleeved Card",
            card.ability.extra.money * n } }
    end,
    loc_txt = { name = "Collector", text = {
        "Earn {C:money}$#1#{} at end of round",
        "for each {C:attention}#2#{}",
        "in your full deck",
        "{C:inactive}(Currently {C:money}$#3#{C:inactive})",
    } },
    calc_dollar_bonus = function(self, card)
        local g = pb5_game()
        if not g or not g.count_cards_in_full_deck then return nil end
        local n = g:count_cards_in_full_deck(function(d)
            return d.enhancement == "sleeved"
        end)
        if n > 0 then return n * card.ability.extra.money end
        return nil
    end,
}

-- festive_joker
SMODS.Joker {
    key = "festive_joker",
    name = "Festive Joker",
    rarity = 2,
    cost = 6,
    sprite = "festive_joker.png",
    negative_sprite = "festive_joker_negative.png",
    config = { extra = { odds = 5, enhancement = "wrapped" } },
    loc_vars = function(self, info_queue, card)
        local num, den = 1, card.ability.extra.odds
        if SMODS.get_probability_vars then
            num, den = SMODS.get_probability_vars(card, num, den,
                "paperback_festive_joker")
        end
        return { vars = { "Wrapped Card", num, den } }
    end,
    loc_txt = { name = "Festive Joker", text = {
        "{C:attention}#1#s{} have a {C:green}#2# in #3#",
        "chance to create a random",
        "{C:attention}Consumable{} when scored",
        "{C:inactive}(Must have room)",
    } },
    calculate = function(self, card, context)
        if context.individual and pb5_play_area(context)
            and context.other_card
            and pb5_enh(context.other_card) == card.ability.extra.enhancement
            and SMODS.pseudorandom_probability(card, "festive_joker",
                1, card.ability.extra.odds, "paperback_festive_joker") then
            local g = pb5_game()
            if g and g.random_consumable_id_of_kind
                and (not g.can_add_consumable or g:can_add_consumable()) then
                local kinds = { "tarot", "planet", "spectral", "minor_arcana" }
                local kind = kinds[SMODS.pseudorandom(
                    "festive_joker_type", 1, #kinds)]
                local id = g:random_consumable_id_of_kind(kind)
                if id then
                    local set = kind == "minor_arcana" and "minor_arcana"
                        or (kind:sub(1, 1):upper() .. kind:sub(2))
                    SMODS.add_card { set = set, key = id }
                    return { message = "+Consumable!" }
                end
            end
        end
    end,
}

-- greeting_card
SMODS.Joker {
    key = "greeting_card",
    name = "Greeting Card",
    rarity = 1,
    cost = 4,
    sprite = "greeting_card.png",
    negative_sprite = "greeting_card_negative.png",
    config = { extra = { enhancement = "wrapped", a_value = 2 } },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.a_value, "Wrapped Card" } }
    end,
    loc_txt = { name = "Greeting Card", text = {
        "Gains {C:money}$#1#{} of {C:attention}sell value{} if a",
        "played {C:attention}#2#{} is {C:attention}scored",
    } },
    calculate = function(self, card, context)
        if context.individual and pb5_play_area(context)
            and context.other_card
            and pb5_enh(context.other_card) == card.ability.extra.enhancement then
            card.sell_cost = (tonumber(card.sell_cost) or 0)
                + card.ability.extra.a_value
            return { message = "Value Up!" }
        end
    end,
}

-- happy_accident
SMODS.Joker {
    key = "happy_accident",
    name = "Happy Accident",
    rarity = 2,
    cost = 7,
    sprite = "happy_accident.png",
    negative_sprite = "happy_accident_negative.png",
    config = { extra = { enhancement = "antique" } },
    loc_vars = function(self, info_queue, card)
        return { vars = { "Antique Card" } }
    end,
    loc_txt = { name = "Happy Accident", text = {
        "Each {C:attention}#1#{}",
        "held in hand",
        "gives {X:chips,C:white}XChips{}",
        "at {C:attention}halved{} scaling",
        "{X:chips,C:white}X1.5{C:inactive} -> {X:chips,C:white}X1.25{}",
    } },
    calculate = function(self, card, context)
        if pb5_hand_area(context) and context.other_card
            and pb5_enh(context.other_card) == card.ability.extra.enhancement then
            local d = context.other_card.card_data or {}
            local x = tonumber(d.pb_antique_x) or 1
            return { x_chips = ((x - 1) / 2) + 1 }
        end
    end,
}

-- kintsugi_joker
SMODS.Joker {
    key = "kintsugi_joker",
    name = "Kintsugi Joker",
    rarity = 2,
    cost = 7,
    sprite = "kintsugi_joker.png",
    negative_sprite = "kintsugi_joker_negative.png",
    config = { extra = { increase = 2, total = 0,
        enhancement = "ceramic", max = 10 } },
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        return { vars = { e.increase, "Ceramic Card", e.total, e.max } }
    end,
    loc_txt = { name = "Kintsugi Joker", text = {
        "Increases the payout of",
        "{C:attention}#2#s{} by {C:money}$#1#{} up to {C:money}$#4#{}",
        "when a {C:attention}#2#{} is destroyed",
        "{C:inactive}(Currently increased by {C:money}$#3#{C:inactive})",
    } },
    calculate = function(self, card, context)
        local e = card.ability.extra
        if context.remove_playing_cards and context.port
            and context.port.destroyed_cards and e.total < e.max then
            local inc = 0
            for _, view in ipairs(context.port.destroyed_cards) do
                if pb5_enh(view) == e.enhancement then inc = inc + 1 end
            end
            if inc > 0 then
                e.total = math.min(e.max, e.total + e.increase * inc)
                return { message = "Upgrade!" }
            end
        end
    end,
}

-- mexican_train
SMODS.Joker {
    key = "mexican_train",
    name = "Mexican Train",
    rarity = 1,
    cost = 6,
    sprite = "mexican_train.png",
    negative_sprite = "mexican_train_negative.png",
    config = { extra = { dollars = 1 } },
    loc_vars = function(self, info_queue, card)
        local n = 0
        for _, node in ipairs(pb5_scoring_nodes()) do
            if pb5_enh(node) == "domino" then n = n + 1 end
        end
        return { vars = { "Domino Card", card.ability.extra.dollars,
            card.ability.extra.dollars * n } }
    end,
    loc_txt = { name = "Mexican Train", text = {
        "Scored {C:attention}#1#s{} give {C:money}$#2#",
        "for every played {C:attention}#1#{}",
        "{C:inactive}(Currently {C:money}$#3#{C:inactive})",
    } },
    calculate = function(self, card, context)
        if context.individual and pb5_play_area(context)
            and context.other_card
            and pb5_enh(context.other_card) == "domino" then
            local n = 0
            for _, node in ipairs(pb5_scoring_nodes()) do
                if pb5_enh(node) == "domino" then n = n + 1 end
            end
            if n > 0 then
                return { dollars = card.ability.extra.dollars * n }
            end
        end
    end,
}

-- plastic_wrap
-- PORT NOTE: PC converts through set_ability on full-deck card objects;
-- the port writes the same card_data directly, except for cards sitting
-- in hand, whose node setter is used so the change announces itself the
-- canonical way (setting_ability fires, the face resyncs).
SMODS.Joker {
    key = "plastic_wrap",
    name = "Plastic Wrap",
    rarity = 1,
    cost = 4,
    sprite = "plastic_wrap.png",
    negative_sprite = "plastic_wrap_negative.png",
    config = { extra = { amount = 2, enhancement = "sleeved" } },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.amount, "Sleeved Card" } }
    end,
    loc_txt = { name = "Plastic Wrap", text = {
        "When a {C:attention}#2#{} is",
        "{C:attention}destroyed{}, enhance {C:attention}#1#{}",
        "{C:attention}unenhanced{} cards in your",
        "full deck to {C:attention}#2#s{}",
    } },
    calculate = function(self, card, context)
        local e = card.ability.extra
        if context.remove_playing_cards and context.port
            and context.port.destroyed_cards then
            local hit = false
            for _, view in ipairs(context.port.destroyed_cards) do
                if pb5_enh(view) == e.enhancement then hit = true break end
            end
            if not hit then return end
            local targets = {}
            for _, d in ipairs(pb5_full_deck_data()) do
                if not d.enhancement then targets[#targets + 1] = d end
            end
            local g = pb5_game()
            local converted = 0
            while converted < e.amount and #targets > 0 do
                local idx = SMODS.pseudorandom("plastic_wrap", 1, #targets)
                local d = table.remove(targets, idx)
                local node = nil
                if g and g.hand and type(g.hand.card_nodes) == "table" then
                    for _, n in ipairs(g.hand.card_nodes) do
                        if n.card_data == d then node = n break end
                    end
                end
                if node and node.set_enhancement then
                    node:set_enhancement(e.enhancement)
                else
                    d.enhancement = e.enhancement
                end
                converted = converted + 1
            end
            if converted > 0 then return { message = "Enhanced!" } end
        end
    end,
}

-- sommelier
SMODS.Joker {
    key = "sommelier",
    name = "Sommelier",
    rarity = 2,
    cost = 6,
    sprite = "sommelier.png",
    negative_sprite = "sommelier_negative.png",
    config = { extra = { active = true } },
    loc_vars = function(self, info_queue, card)
        return { vars = { "Stained Card" } }
    end,
    loc_txt = { name = "Sommelier", text = {
        "If {C:attention}first discard{} of round",
        "contains a {C:attention}#1#{},",
        "the first discarded {C:attention}#1#{}",
        "gets a random {C:attention}seal",
    } },
    calculate = function(self, card, context)
        local e = card.ability.extra
        if context.pre_discard and e.active then
            local nodes = (context.port and context.port.discarded_nodes)
                or context.full_hand
            if type(nodes) == "table" then
                for _, node in ipairs(nodes) do
                    if pb5_enh(node) == "stained" then
                        local seal = ({ "gold", "red", "blue", "purple" })[
                            SMODS.pseudorandom("sommelier_seal", 1, 4)]
                        if node.set_seal then
                            node:set_seal(seal)
                        elseif node.card_data then
                            node.card_data.seal = seal
                        end
                        e.active = false
                        return { message = "Sealed!" }
                    end
                end
            end
        end
        if context.end_of_round or context.setting_blind then
            e.active = true
        end
    end,
}

-- spotty_joker
SMODS.Joker {
    key = "spotty_joker",
    name = "Spotty Joker",
    rarity = 2,
    cost = 3,
    sprite = "spotty_joker.png",
    negative_sprite = "spotty_joker_negative.png",
    config = { extra = { xmult_mod = 0.1, xmult = 1 } },
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        return { vars = { e.xmult_mod, "Domino Card", e.xmult } }
    end,
    loc_txt = { name = "Spotty Joker", text = {
        "This Joker gains {X:mult,C:white}X#1#{} Mult",
        "for every {C:attention}#2#{}",
        "in {C:attention}scoring hand{}",
        "{C:inactive}(Currently {X:mult,C:white}X#3#{}{C:inactive} Mult)",
    } },
    calculate = function(self, card, context)
        local e = card.ability.extra
        if context.before and context.scoring_hand then
            local n = 0
            for _, view in ipairs(context.scoring_hand) do
                if pb5_enh(view) == "domino" then n = n + 1 end
            end
            if n > 0 then
                e.xmult = pb5_round2(e.xmult + e.xmult_mod * n)
                return { message = "Upgrade!" }
            end
        end
        if context.joker_main and e.xmult ~= 1 then
            return { xmult = e.xmult }
        end
    end,
}

-- teapot
SMODS.Joker {
    key = "teapot",
    name = "Teapot",
    rarity = 1,
    cost = 5,
    sprite = "teapot.png",
    negative_sprite = "teapot_negative.png",
    config = { extra = { enhancement = "ceramic", a_chips = 5, chips = 0 } },
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        return { vars = { e.a_chips, "Ceramic Card", e.chips } }
    end,
    loc_txt = { name = "Teapot", text = {
        "This Joker gains {C:blue}+#1#{} Chips whenever",
        "a {C:attention}#2#{} is {C:attention}scored",
        "{C:inactive}(Currently {C:blue}+#3#{C:inactive} Chips)",
    } },
    calculate = function(self, card, context)
        local e = card.ability.extra
        if context.individual and pb5_play_area(context)
            and context.other_card
            and pb5_enh(context.other_card) == e.enhancement then
            e.chips = e.chips + e.a_chips
            return { message = "Upgrade!" }
        end
        if context.joker_main and e.chips > 0 then
            return { chips = e.chips }
        end
    end,
}

-- watercolor_joker
SMODS.Joker {
    key = "watercolor_joker",
    name = "Watercolor Joker",
    rarity = 2,
    cost = 7,
    sprite = "watercolor_joker.png",
    negative_sprite = "watercolor_joker_negative.png",
    config = { extra = { enhancement = "soaked", xChips = 1.5 } },
    loc_vars = function(self, info_queue, card)
        return { vars = { "Soaked Card", card.ability.extra.xChips } }
    end,
    loc_txt = { name = "Watercolor Joker", text = {
        "{C:attention}#1#s{} give",
        "{X:chips,C:white}X#2#{} Chips when scored",
    } },
    calculate = function(self, card, context)
        if context.individual and pb5_play_area(context)
            and context.other_card
            and pb5_enh(context.other_card) == card.ability.extra.enhancement then
            return { x_chips = card.ability.extra.xChips }
        end
    end,
}

-- pinot_noir
SMODS.Joker {
    key = "pinot_noir",
    name = "Pinot Noir",
    rarity = 1,
    cost = 5,
    sprite = "pinot_noir.png",
    negative_sprite = "pinot_noir_negative.png",
    config = { extra = { remaining = 10, extra_mult = 1 } },
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        return { vars = { e.remaining, "Stained Card", e.extra_mult } }
    end,
    loc_txt = { name = "Pinot Noir", text = {
        "The next {C:attention}#1#{} times a",
        "{C:attention}#2#{} triggers, it",
        "gives {C:mult}+#3#{} more permanent Mult",
    } },
    calculate = function(self, card, context)
        local e = card.ability.extra
        if pb5_hand_area(context) and context.other_card
            and pb5_enh(context.other_card) == "stained"
            and e.remaining > 0 then
            e.remaining = e.remaining - 1
            if e.remaining < 1 then
                if SMODS.destroy_joker then SMODS.destroy_joker(card) end
                return { message = "Consumed!" }
            end
        end
    end,
}

-- gauze
-- PORT NOTE: the Bandaged card it creates carries an enhancement whose
-- own effect the fork cannot run (see the Bandaged registration note);
-- the conversion itself is exact.
SMODS.Joker {
    key = "gauze",
    name = "Gauze",
    rarity = 1,
    cost = 4,
    sprite = "gauze.png",
    negative_sprite = "gauze_negative.png",
    config = { extra = { enhancement = "bandaged" } },
    loc_vars = function(self, info_queue, card)
        return { vars = { "Bandaged Card" } }
    end,
    loc_txt = { name = "Gauze", text = {
        "If last discard of round is a single card,",
        "it becomes a {C:attention}#1#{}",
    } },
    calculate = function(self, card, context)
        if context.pre_discard then
            local g = pb5_game()
            local left = g and tonumber(g.discards)
            if left ~= nil and left ~= 1 then return end
            local nodes = (context.port and context.port.discarded_nodes)
                or context.full_hand
            if type(nodes) == "table" and #nodes == 1 then
                local node = nodes[1]
                if node.set_enhancement then
                    node:set_enhancement(card.ability.extra.enhancement)
                elseif node.card_data then
                    node.card_data.enhancement = card.ability.extra.enhancement
                end
                return { message = "Bandaged!" }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- XChips class
--------------------------------------------------------------------------------

local function pb5_is_suit(view, suit)
    local d = view and view.card_data or {}
    if d.enhancement == "wild" then return true end
    return pb5_suit(view) == suit
end

-- blue_star
SMODS.Joker {
    key = "blue_star",
    name = "Blue Star",
    rarity = 3,
    cost = 8,
    sprite = "blue_star.png",
    negative_sprite = "blue_star_negative.png",
    config = { extra = { x_chips = 1,
        good = { suit = "Stars", a_xchips = 0.05 },
        bad = { suit = "Clubs", a_xchips = 0.2 } } },
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        return { vars = { e.good.a_xchips, e.good.suit, e.bad.a_xchips,
            e.bad.suit, e.x_chips } }
    end,
    loc_txt = { name = "Blue Star", text = {
        "Gains {X:chips,C:white}X#1#{} Chips when a {V:1}#2#{} scores",
        "Loses {X:chips,C:white}X#3#{} Chips when a {V:2}#4#{} scores",
        "{C:inactive}(Currently {X:chips,C:white}X#5#{C:inactive} Chips)",
    } },
    calculate = function(self, card, context)
        local e = card.ability.extra
        if context.individual and pb5_play_area(context)
            and context.other_card then
            if pb5_is_suit(context.other_card, e.good.suit) then
                e.x_chips = pb5_round2(e.x_chips + e.good.a_xchips)
                return { message = "Upgrade!" }
            elseif pb5_is_suit(context.other_card, e.bad.suit) then
                e.x_chips = math.max(0, pb5_round2(e.x_chips - e.bad.a_xchips))
                return { message = "Downgrade!" }
            end
        end
        if context.joker_main then
            return { x_chips = e.x_chips }
        end
    end,
}

-- chocolate_joker
SMODS.Joker {
    key = "chocolate_joker",
    name = "Chocolate Joker",
    rarity = 2,
    cost = 8,
    sprite = "chocolate_joker.png",
    negative_sprite = "chocolate_joker_negative.png",
    config = { extra = { a_xchips = 0.2 } },
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        return { vars = { e.a_xchips,
            1 + #pb5_jokers() * e.a_xchips } }
    end,
    loc_txt = { name = "Chocolate Joker", text = {
        "This Joker gains {X:chips,C:white}X#1#{} Chips",
        "for each {C:attention}Joker{} card",
        "{C:inactive}(Currently {X:chips,C:white}X#2#{C:inactive} Chips)",
    } },
    calculate = function(self, card, context)
        if context.joker_main then
            return { x_chips = 1
                + #pb5_jokers() * card.ability.extra.a_xchips }
        end
    end,
}

-- crispy_taco
SMODS.Joker {
    key = "crispy_taco",
    name = "Crispy Taco",
    rarity = 2,
    cost = 6,
    sprite = "crispy_taco.png",
    negative_sprite = "crispy_taco_negative.png",
    config = { extra = { x_chips = 3, odds = 6 } },
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        local num, den = 1, e.odds
        if SMODS.get_probability_vars then
            num, den = SMODS.get_probability_vars(card, num, den,
                "paperback_crispy_taco")
        end
        return { vars = { e.x_chips, num, den } }
    end,
    loc_txt = { name = "Crispy Taco", text = {
        "{X:chips,C:white}X#1#{} Chips",
        "{C:green}#2# in #3#{} chance this card",
        "is eaten at end of round",
    } },
    calculate = function(self, card, context)
        local e = card.ability.extra
        if context.joker_main then
            return { x_chips = e.x_chips }
        end
        if context.end_of_round then
            if SMODS.pseudorandom_probability(card, "crispy_taco",
                1, e.odds, "paperback_crispy_taco") then
                if SMODS.destroy_joker then SMODS.destroy_joker(card) end
                return { message = "Eaten!" }
            end
            return { message = "Safe!" }
        end
    end,
}

-- deck_of_cards
-- PORT NOTE: PC arms itself in `before` and destroys the Antique card
-- through the destroy_card query; the port destroys it directly in
-- `before`, the same card at the same point of the hand.
SMODS.Joker {
    key = "deck_of_cards",
    name = "Deck of Cards",
    rarity = 2,
    cost = 7,
    sprite = "deck_of_cards.png",
    negative_sprite = "deck_of_cards_negative.png",
    config = { extra = { Xchips_mod = 0.25, x_chips = 1,
        enhancement = "antique" } },
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        return { vars = { "Antique Card", e.Xchips_mod, e.x_chips } }
    end,
    loc_txt = { name = "Deck of Cards", text = {
        "If played hand is a single {C:attention}#1#{},",
        "this Joker gains {X:chips,C:white}X#2#{} Chips and destroys it",
        "{C:inactive}(Currently {X:chips,C:white}X#3#{} {C:inactive}Chips)",
    } },
    calculate = function(self, card, context)
        local e = card.ability.extra
        if context.before and context.full_hand
            and #context.full_hand == 1 and context.scoring_hand
            and context.scoring_hand[1]
            and pb5_enh(context.scoring_hand[1]) == e.enhancement then
            e.x_chips = pb5_round2(e.x_chips + e.Xchips_mod)
            if SMODS.destroy_card then
                SMODS.destroy_card(context.scoring_hand[1])
            end
            return { message = "Upgrade!" }
        end
        if context.joker_main then
            return { x_chips = e.x_chips }
        end
    end,
}

-- nachos
SMODS.Joker {
    key = "nachos",
    name = "Nachos",
    rarity = 1,
    cost = 6,
    sprite = "nachos.png",
    negative_sprite = "nachos_negative.png",
    config = { extra = { X_chips = 2, reduction_amount = 0.05 } },
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        return { vars = { e.X_chips, e.reduction_amount } }
    end,
    loc_txt = { name = "Nachos", text = {
        "{X:chips,C:white}X#1#{} Chips,",
        "loses {X:chips,C:white}X#2#{} Chips",
        "per {C:attention}card{} discarded",
    } },
    calculate = function(self, card, context)
        local e = card.ability.extra
        if context.joker_main then
            return { x_chips = e.X_chips }
        end
        if context.discard and context.other_card and e.X_chips > 1 then
            if e.X_chips - e.reduction_amount <= 1 then
                if SMODS.destroy_joker then SMODS.destroy_joker(card) end
                return { message = "Eaten!" }
            end
            e.X_chips = pb5_round2(e.X_chips - e.reduction_amount)
            return { message = "Downgrade!" }
        end
    end,
}

-- oracle
SMODS.Joker {
    key = "oracle",
    name = "Oracle",
    rarity = 2,
    cost = 6,
    sprite = "oracle.png",
    negative_sprite = "oracle_negative.png",
    config = { extra = { Xchip_mod = 0.1, Xchip = 1 } },
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        return { vars = { e.Xchip_mod, e.Xchip, "Minor Arcana" } }
    end,
    loc_txt = { name = "Oracle", text = {
        "This Joker gains {X:chips,C:white}X#1#",
        "Chips for every {C:attention}unique",
        "{C:paperback_minor_arcana}#3#{} card used",
        "{C:inactive}(Currently {X:chips,C:white}X#2#{C:inactive} Chips)",
    } },
    calculate = function(self, card, context)
        local e = card.ability.extra
        if context.joker_main then
            local g = pb5_game()
            local n = 0
            if g and type(g.consumable_usage) == "table" then
                for _, u in pairs(g.consumable_usage) do
                    if type(u) == "table" and u.kind == "minor_arcana" then
                        n = n + 1
                    end
                end
            end
            e.Xchip = pb5_round2(1 + n * e.Xchip_mod)
            return { x_chips = e.Xchip }
        end
    end,
}

-- quartz
SMODS.Joker {
    key = "quartz",
    name = "Quartz",
    rarity = 2,
    cost = 7,
    sprite = "quartz.png",
    negative_sprite = "quartz_negative.png",
    config = { extra = { x_chips = 0.2 } },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.x_chips } }
    end,
    loc_txt = { name = "Quartz", text = {
        "Scored {C:paperback_stars}Stars{} give {X:chips,C:white}X1{} Chips,",
        "{X:chips,C:white}+X#1#{} for each other played {C:paperback_stars}Star",
    } },
    calculate = function(self, card, context)
        if context.individual and pb5_play_area(context)
            and context.other_card
            and pb5_is_suit(context.other_card, "Stars")
            and type(context.full_hand) == "table" then
            local stars = 0
            for _, view in ipairs(context.full_hand) do
                if view ~= context.other_card
                    and pb5_is_suit(view, "Stars") then
                    stars = stars + 1
                end
            end
            if stars > 0 then
                return { x_chips = 1
                    + card.ability.extra.x_chips * stars }
            end
        end
    end,
}

-- ready_to_fly
-- PORT NOTE: PC also skips a list of message-less contexts (its
-- ignored_contexts refinement reads the triggered Joker's return); the
-- fork's post_trigger carries no return table, so every adjacent
-- trigger counts.
SMODS.Joker {
    key = "ready_to_fly",
    name = "Ready to Fly",
    rarity = 3,
    cost = 6,
    sprite = "ready_to_fly.png",
    negative_sprite = "ready_to_fly_negative.png",
    config = { extra = { xchips = 1, scaling = 0.02 } },
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        return { vars = { e.xchips, e.scaling } }
    end,
    loc_txt = { name = "Ready to Fly", text = {
        "This Joker gains {X:chips,C:white}X#2#{} Chips",
        "whenever an adjacent Joker {C:attention}triggers",
        "{C:inactive}(Currently {X:chips,C:white}X#1#{C:inactive} Chips)",
    } },
    calculate = function(self, card, context)
        local e = card.ability.extra
        if context.post_trigger and context.other_card
            and context.other_card ~= card then
            local list = pb5_jokers()
            for i, j in ipairs(list) do
                if j == card then
                    if list[i - 1] == context.other_card
                        or list[i + 1] == context.other_card then
                        e.xchips = pb5_round2(e.xchips + e.scaling)
                        return { message = "Upgrade!" }
                    end
                    break
                end
            end
        end
        if context.joker_main then
            return { x_chips = e.xchips }
        end
    end,
}

-- stella_octangula
-- PORT NOTE: PC arms on initial_scoring_step, a context the fork never
-- raises; `before` (on_hand_played) is the same point of the hand for
-- this purpose.
SMODS.Joker {
    key = "stella_octangula",
    name = "Stella Octangula",
    rarity = 1,
    cost = 6,
    sprite = "stella_octangula.png",
    negative_sprite = "stella_octangula_negative.png",
    config = { extra = { xc = 2, active = true, used = false } },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.xc, "Stars" } }
    end,
    loc_txt = { name = "Stella Octangula", text = {
        "The first played {V:1}#2#{} each round",
        "gives {X:chips,C:white} X#1# {} Chips",
    } },
    calculate = function(self, card, context)
        local e = card.ability.extra
        if context.before and context.scoring_hand and not e.used then
            e.first_star = nil
            for _, view in ipairs(context.scoring_hand) do
                if pb5_is_suit(view, "Stars") then
                    e.first_star = view
                    break
                end
            end
        end
        if context.individual and pb5_play_area(context)
            and context.other_card
            and e.first_star and context.other_card == e.first_star
            and not e.used then
            e.used = true
            return { x_chips = e.xc }
        end
        if context.end_of_round then
            e.used = false
            e.first_star = nil
        end
    end,
}

end -- SMODS.Joker (enhancement-gated + XChips)

--------------------------------------------------------------------------------
-- Tag Jokers
--------------------------------------------------------------------------------

if SMODS.Joker then

-- angel_investor
SMODS.Joker {
    key = "angel_investor",
    name = "Angel Investor",
    rarity = 1,
    cost = 4,
    sprite = "angel_investor.png",
    negative_sprite = "angel_investor_negative.png",
    config = { extra = { tags = 1 } },
    loc_txt = { name = "Angel Investor", text = {
        "Skipping a {C:attention}Blind{} or defeating",
        "a {C:attention}Boss Blind{} gives",
        "an {C:money}Angel Investment Tag",
    } },
    calculate = function(self, card, context)
        if context.skip_blind
            or (context.end_of_round and pb5_boss(context)) then
            pb5_add_tag("angel_investment")
            return { message = "+Tag!" }
        end
    end,
}

-- book_of_life
-- The blind's Tag is read from the fork's own skip rewards: G.skips
-- holds each blind's reward id and Game:tag_type_for_id resolves it,
-- the same pair the skip tooltip uses.
SMODS.Joker {
    key = "book_of_life",
    name = "Book of Life",
    rarity = 3,
    cost = 8,
    sprite = "book_of_life.png",
    negative_sprite = "book_of_life_negative.png",
    config = { extra = { odds = 2 } },
    loc_vars = function(self, info_queue, card)
        local num, den = 1, card.ability.extra.odds
        if SMODS.get_probability_vars then
            num, den = SMODS.get_probability_vars(card, num, den,
                "paperback_book_of_life")
        end
        return { vars = { num, den } }
    end,
    loc_txt = { name = "Book of Life", text = {
        "After skipping or clearing",
        "a {C:attention}Blind{}, {C:green}#1# in #2#{} chance to",
        "create a {C:attention}copy{} of its {C:attention}Tag{}",
    } },
    calculate = function(self, card, context)
        local idx = nil
        if context.end_of_round then
            local g = pb5_game()
            idx = g and g.current_blind_index
        elseif context.skip_blind then
            idx = context.port and context.port.blind_index
        end
        if not idx then return end
        local g = pb5_game()
        if not g or type(g.skips) ~= "table" or not g.tag_type_for_id then
            return
        end
        local type_name = g:tag_type_for_id(g.skips[idx])
        if type_name and SMODS.pseudorandom_probability(card,
            "book_of_life", 1, card.ability.extra.odds,
            "paperback_book_of_life") then
            pb5_add_tag(type_name)
            return { message = "+Tag!" }
        end
    end,
}

-- j_and_js
SMODS.Joker {
    key = "j_and_js",
    name = "J&J's",
    rarity = 2,
    cost = 6,
    sprite = "j_and_js.png",
    negative_sprite = "j_and_js_negative.png",
    config = { extra = { tags = 2, rounds = 3, rounds_reset = 3 } },
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        return { vars = { e.tags, e.rounds } }
    end,
    loc_txt = { name = "J&J's", text = {
        "If played hand contains a",
        "{C:attention}Spectrum{}, create {C:attention}#1#{} random {C:attention}Tags",
        "Consumed in {C:attention}#2#{} rounds",
    } },
    calculate = function(self, card, context)
        local e = card.ability.extra
        if context.before and context.poker_hands
            and context.poker_hands["Spectrum"]
            and next(context.poker_hands["Spectrum"]) then
            for _ = 1, e.tags do
                pb5_add_tag(pb5_random_tag("j_and_js"))
            end
            return { message = "+Tags!" }
        end
        if context.end_of_round then
            e.rounds = e.rounds - 1
            if e.rounds <= 0 then
                if SMODS.destroy_joker then SMODS.destroy_joker(card) end
                return { message = "Consumed!" }
            end
            return { message = e.rounds .. " Rounds Left" }
        end
    end,
}

-- jimbo_adventure
SMODS.Joker {
    key = "jimbo_adventure",
    name = "Jimbo Adventure",
    rarity = 1,
    cost = 4,
    sprite = "jimbo_adventure.png",
    negative_sprite = "jimbo_adventure_negative.png",
    soul_sprite = "jimbo_adventure_soul.png",
    loc_txt = { name = "Jimbo Adventure", text = {
        "Skipping a {C:attention}Blind{} creates",
        "a random {C:attention}Tag{}",
    } },
    calculate = function(self, card, context)
        if context.skip_blind then
            pb5_add_tag(pb5_random_tag("jimbo_adventure"))
            return { message = "+Tag!" }
        end
    end,
}

-- jokers_11
-- PORT NOTE: PC fires per Ace on an end_of_round + individual + hand
-- context combination; the fork never raises that combination, so the
-- port counts the Aces held in hand when the Boss round ends, one Tag
-- per Ace, the same total.
SMODS.Joker {
    key = "jokers_11",
    name = "Joker's 11",
    rarity = 3,
    cost = 8,
    sprite = "jokers_11.png",
    negative_sprite = "jokers_11_negative.png",
    config = { extra = { rank = "Ace" } },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.rank } }
    end,
    loc_txt = { name = "Joker's 11", text = {
        "{C:attention}#1#s{} held in hand after",
        "defeating a {C:attention}Boss Blind{}",
        "create a random {C:attention}Tag{}",
    } },
    calculate = function(self, card, context)
        if context.end_of_round and pb5_boss(context) then
            local g = pb5_game()
            local n = 0
            if g and g.hand and type(g.hand.card_nodes) == "table" then
                for _, node in ipairs(g.hand.card_nodes) do
                    if pb5_rank(node) == 14 then n = n + 1 end
                end
            end
            for _ = 1, n do
                pb5_add_tag(pb5_random_tag("jokers_11"))
            end
            if n > 0 then return { message = "+Tags!" } end
        end
    end,
}

-- shopkeep
SMODS.Joker {
    key = "shopkeep",
    name = "Shopkeep",
    rarity = 3,
    cost = 10,
    sprite = "shopkeep.png",
    negative_sprite = "shopkeep_negative.png",
    config = { extra = { count = 0, coupon_blinds_needed = 2 } },
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        return { vars = { e.coupon_blinds_needed,
            e.count % e.coupon_blinds_needed, "Coupon Tag", "Voucher Tag" } }
    end,
    loc_txt = { name = "Shopkeep", text = {
        "Get a {C:attention}#3#{} every",
        "{C:attention}#1#{} {C:attention}Blinds{} defeated {C:inactive}(#2#/#1#){}",
        "Get a {C:attention}#4#{} when",
        "{C:attention}Boss Blind{} is defeated",
    } },
    calculate = function(self, card, context)
        local e = card.ability.extra
        if context.end_of_round then
            e.count = e.count + 1
            local made = false
            if e.count % e.coupon_blinds_needed == 0 then
                pb5_add_tag("coupon")
                made = true
            end
            if pb5_boss(context) then
                pb5_add_tag("voucher")
                made = true
            end
            if made then return { message = "+Tag!" } end
        end
    end,
}

-- spirit_box
-- PORT NOTE: on PC the target hand is the mod-wide
-- G.GAME.paperback.weather_radio_hand, shared with Weather Radio and
-- re-rolled each round by a hook outside the defs; the port keeps its
-- own target hand per Joker, re-rolled at each blind select.
SMODS.Joker {
    key = "spirit_box",
    name = "Spirit Box",
    rarity = 2,
    cost = 7,
    sprite = "spirit_box.png",
    negative_sprite = "spirit_box_negative.png",
    config = { extra = { active = true } },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.hand or "Pair" } }
    end,
    loc_txt = { name = "Spirit Box", text = {
        "Create a random {C:attention}Tag{} if",
        "played hand contains a {C:attention}#1#{}",
        "{C:inactive}(Once per round)",
        "{s:0.75}poker hand changes at end of round",
    } },
    calculate = function(self, card, context)
        local e = card.ability.extra
        if context.setting_blind or (context.end_of_round and not e.hand) then
            local g = pb5_game()
            if g and type(g.handlist) == "table" and #g.handlist > 0 then
                e.hand = g.handlist[SMODS.pseudorandom(
                    "spirit_box_hand", 1, #g.handlist)]
            end
        end
        if context.before and e.active and e.hand and context.poker_hands
            and context.poker_hands[e.hand]
            and next(context.poker_hands[e.hand]) then
            e.active = false
            pb5_add_tag(pb5_random_tag("spirit_box"))
            return { message = "+Tag!" }
        end
        if context.end_of_round then
            e.active = true
            e.hand = nil
        end
    end,
}

-- stereoscopic_specs
-- PORT NOTE: PC copies the last Tag *used*, heard on a tag_triggered
-- context; the fork raises no such context, so the port tracks the last
-- Tag *gained* (tag_added). Tags that fire the moment they are gained
-- read identically; held tags copy on gain rather than on use.
SMODS.Joker {
    key = "stereoscopic_specs",
    name = "Stereoscopic Specs",
    rarity = 3,
    cost = 8,
    sprite = "stereoscopic_specs.png",
    negative_sprite = "stereoscopic_specs_negative.png",
    config = { extra = { last_tag = nil } },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.last_tag or "None" } }
    end,
    loc_txt = { name = "Stereoscopic Specs", text = {
        "Create a {C:attention}copy{} of the",
        "last tag used after",
        "beating a {C:attention}Boss Blind{}",
        "{C:inactive}(Currently {C:attention}#1#{C:inactive})",
    } },
    calculate = function(self, card, context)
        local e = card.ability.extra
        if context.tag_added then
            local t = context.tag_added
            e.last_tag = (type(t) == "table" and t.type) or t
        end
        if context.end_of_round and pb5_boss(context) and e.last_tag then
            pb5_add_tag(e.last_tag)
            return { message = "+Tag!" }
        end
    end,
}

-- the_wonder_of_you
SMODS.Joker {
    key = "the_wonder_of_you",
    name = "The Wonder of You",
    rarity = 2,
    cost = 9,
    sprite = "the_wonder_of_you.png",
    negative_sprite = "the_wonder_of_you_negative.png",
    config = { extra = { tag_count = 2 } },
    loc_txt = { name = "The Wonder of You", text = {
        "When selecting a {C:attention}Boss Blind{},",
        "create two random {C:attention}tags",
    } },
    calculate = function(self, card, context)
        if context.setting_blind and pb5_boss(context) then
            for _ = 1, card.ability.extra.tag_count do
                pb5_add_tag(pb5_random_tag("the_wonder_of_you"))
            end
            return { message = "+Tags!" }
        end
    end,
}

--------------------------------------------------------------------------------
-- Balance
--------------------------------------------------------------------------------

-- let_it_happen
SMODS.Joker {
    key = "let_it_happen",
    name = "Let it Happen",
    rarity = 3,
    cost = 8,
    sprite = "let_it_happen.png",
    negative_sprite = "let_it_happen_negative.png",
    config = { extra = { hands_played_this_ante = {} } },
    loc_vars = function(self, info_queue, card)
        local list = card.ability.extra.hands_played_this_ante
        return { vars = { #list > 0 and table.concat(list, ", ") or "None" } }
    end,
    loc_txt = { name = "Let it Happen", text = {
        "If hand has not been played this",
        "{C:attention}Ante{}, {C:purple}balance{} {C:mult}Mult{} and {C:chips}Chips",
        "{C:inactive}(Hands played:{C:attention}#1#{C:inactive})",
    } },
    calculate = function(self, card, context)
        local e = card.ability.extra
        if context.joker_main then
            local name = context.scoring_name
                or (context.port and context.port.scoring_name)
            if name then
                for _, h in ipairs(e.hands_played_this_ante) do
                    if h == name then return end
                end
                e.hands_played_this_ante[#e.hands_played_this_ante + 1] = name
                return { balance = true }
            end
        end
        if context.end_of_round and pb5_boss(context) then
            e.hands_played_this_ante = {}
            return { message = "Reset!" }
        end
    end,
}

--------------------------------------------------------------------------------
-- New-context class
--------------------------------------------------------------------------------

-- coin_collection
-- The $1 is eased from inside the handler under a guard flag on the
-- game (PC's guard is the same shape, a G.GAME flag): a dollars return
-- would re-enter money_altered with nothing to stop it but the fork's
-- nesting cap, and would pay once per level.
SMODS.Joker {
    key = "coin_collection",
    name = "Coin Collection",
    rarity = 1,
    cost = 6,
    sprite = "coin_collection.png",
    negative_sprite = "coin_collection_negative.png",
    config = { extra = { dollars = 1 } },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.dollars } }
    end,
    loc_txt = { name = "Coin Collection", text = {
        "Any time you earn {C:money}money{},",
        "earn an additional {C:money}$#1#",
    } },
    calculate = function(self, card, context)
        if context.money_altered and (tonumber(context.amount) or 0) > 0 then
            local g = pb5_game()
            if not g or g.pb5_coin_guard then return end
            g.pb5_coin_guard = true
            if g.ease_dollars then
                g:ease_dollars(card.ability.extra.dollars)
            else
                g.money = (tonumber(g.money) or 0)
                    + card.ability.extra.dollars
            end
            g.pb5_coin_guard = nil
            return { message = "+$1" }
        end
    end,
}

-- frutiger_aero
-- PC initializes Chips to base in set_ability; the port's config starts
-- there, which is the same state a fresh Joker is in.
SMODS.Joker {
    key = "frutiger_aero",
    name = "Frutiger Aero",
    rarity = 1,
    cost = 6,
    sprite = "frutiger_aero.png",
    negative_sprite = "frutiger_aero_negative.png",
    config = { extra = { base = 100, chips = 100, rate = 2 } },
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        return { vars = { e.chips, e.rate } }
    end,
    loc_txt = { name = "Frutiger Aero", text = {
        "{C:chips}#1#{} Chips, loses",
        "{C:chips}#2#{} Chips per {C:money}$1{} spent.",
        "{C:attention}Resets{} after defeating",
        "a {C:attention}Boss Blind{}",
    } },
    calculate = function(self, card, context)
        local e = card.ability.extra
        if context.money_altered and (tonumber(context.amount) or 0) < 0
            and context.from_shop then
            e.chips = math.max(0, e.chips
                + e.rate * (tonumber(context.amount) or 0))
            return { message = "Downgrade!" }
        end
        if context.end_of_round and pb5_boss(context) then
            e.chips = e.base
            return { message = "Reset!" }
        end
        if context.joker_main and e.chips > 0 then
            return { chips = e.chips }
        end
    end,
}

-- cream_liqueur
-- PORT NOTE: PC pays when a Tag *activates* (a paperback.using_tag
-- context) and resets its fuse when one is *acquired*
-- (paperback.tag_acquired). The fork raises tag_added on acquisition
-- and no activation context at all, so the port pays on acquisition --
-- the two coincide for tags that fire the moment they are gained -- and
-- the fuse reset rides along, as PC's does.
SMODS.Joker {
    key = "cream_liqueur",
    name = "Cream Liqueur",
    rarity = 1,
    cost = 4,
    sprite = "cream_liqueur.png",
    negative_sprite = "cream_liqueur_negative.png",
    config = { extra = { rounds_reset = 3, rounds = 3, money = 5 } },
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        return { vars = { e.money, e.rounds, e.rounds == 1 and "" or "s" } }
    end,
    loc_txt = { name = "Cream Liqueur", text = {
        "{C:attention}Tags{} earn {C:money}$#1#{} when activated",
        "Consumed in {C:attention}#2#{} round#3#",
        "{C:inactive}(Resets when a {C:attention}Tag{C:inactive} is acquired)",
    } },
    calculate = function(self, card, context)
        local e = card.ability.extra
        if context.tag_added then
            if e.rounds > 0 and e.rounds < e.rounds_reset then
                e.rounds = e.rounds_reset
            end
            return { dollars = e.money }
        end
        if context.end_of_round then
            e.rounds = e.rounds - 1
            if e.rounds <= 0 then
                if SMODS.destroy_joker then SMODS.destroy_joker(card) end
                return { message = "Consumed!" }
            end
            return { message = e.rounds .. " Rounds Left" }
        end
    end,
}

-- off_alpha / off_epsilon / off_omega: the OFF Switch addons. PC counts
-- destructions with its include-self flag set; a Joker scaling itself
-- as it dies changes nothing, so every destruction counts.
local function pb5_off_addon(key, name, sprite, config, loc, calc)
    SMODS.Joker {
        key = key,
        name = name,
        rarity = 4,
        cost = 1,
        sprite = sprite .. ".png",
        negative_sprite = sprite .. "_negative.png",
        soul_sprite = sprite .. "_soul.png",
        config = { extra = config },
        loc_vars = function(self, info_queue, card)
            local e = card.ability.extra
            return { vars = { e.chips_mod or e.dollars or e.mult_mod,
                e.chips or e.mult or "" } }
        end,
        loc_txt = loc,
        in_pool = function(self, game) return false end,
        calculate = calc,
    }
end

pb5_off_addon("off_alpha", "Alpha", "off_alpha",
    { chips_mod = 13, chips = 0 },
    { name = "Alpha", text = {
        "Gains {C:chips}+#1#{} Chips for each",
        "Joker {C:attention}destroyed",
        "{C:inactive}(Currently {C:chips}+#2# {C:inactive}Chips)",
    } },
    function(self, card, context)
        local e = card.ability.extra
        if context.joker_type_destroyed then
            e.chips = e.chips + e.chips_mod
            return { message = "Upgrade!" }
        end
        if context.joker_main and e.chips > 0 then
            return { chips = e.chips }
        end
    end)

pb5_off_addon("off_epsilon", "Epsilon", "off_epsilon",
    { dollars = 13 },
    { name = "Epsilon", text = {
        "Earn {C:gold}$#1#{} for each",
        "Joker {C:attention}destroyed",
    } },
    function(self, card, context)
        if context.joker_type_destroyed then
            return { dollars = card.ability.extra.dollars }
        end
    end)

pb5_off_addon("off_omega", "Omega", "off_omega",
    { mult_mod = 13, mult = 0 },
    { name = "Omega", text = {
        "Gains {C:mult}+#1#{} Mult for each",
        "Joker {C:attention}destroyed",
        "{C:inactive}(Currently {C:mult}+#2# {C:inactive}Mult)",
    } },
    function(self, card, context)
        local e = card.ability.extra
        if context.joker_type_destroyed then
            e.mult = e.mult + e.mult_mod
            return { message = "Upgrade!" }
        end
        if context.joker_main and e.mult > 0 then
            return { mult = e.mult }
        end
    end)

-- one_with_nothing
-- PORT NOTE: PC discards the held cards (they pass through the discard
-- pile and its effects). The fork has no discard-from-hand API, so the
-- port destroys the held unplayed cards instead; destruction effects
-- (and Cross's veto) apply where discard effects would have.
SMODS.Joker {
    key = "one_with_nothing",
    name = "One With Nothing",
    rarity = 2,
    cost = 5,
    sprite = "one_with_nothing.png",
    negative_sprite = "one_with_nothing_negative.png",
    loc_txt = { name = "One With Nothing", text = {
        "After playing a hand,",
        "{C:attention}discard{} all cards in hand",
    } },
    calculate = function(self, card, context)
        if context.press_play and type(context.full_hand) == "table" then
            local played = {}
            for _, node in ipairs(context.full_hand) do
                played[node] = true
            end
            local g = pb5_game()
            if g and g.hand and type(g.hand.card_nodes) == "table"
                and SMODS.destroy_card then
                local targets = {}
                for _, node in ipairs(g.hand.card_nodes) do
                    if not played[node] then targets[#targets + 1] = node end
                end
                for _, node in ipairs(targets) do
                    SMODS.destroy_card(node)
                end
                if #targets > 0 then return { message = "Discarded!" } end
            end
        end
    end,
}

-- watermelon
-- PORT NOTE: setting_ability fires for seal changes too; the port
-- counts a change when the card now carries an enhancement different
-- from the reported old value, which is exact for enhancement changes
-- and can also count a seal change made on an already-enhanced card.
SMODS.Joker {
    key = "watermelon",
    name = "Watermelon",
    rarity = 2,
    cost = 6,
    sprite = "watermelon.png",
    negative_sprite = "watermelon_negative.png",
    config = { extra = { a_xmult = 0.1, x_mult = 1 } },
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        return { vars = { e.a_xmult, e.x_mult } }
    end,
    loc_txt = { name = "Watermelon", text = {
        "Gains {X:mult,C:white}X#1#{} Mult when {C:attention}Enhancing{}",
        "a playing card. Loses {X:mult,C:white}X#1#{} Mult",
        "when a playing card is {C:attention}destroyed{}",
        "{C:inactive}(Currently {X:mult,C:white}X#2#{} {C:inactive}Mult)",
    } },
    calculate = function(self, card, context)
        local e = card.ability.extra
        if context.setting_ability and not context.unchanged
            and context.other_card then
            local enh = pb5_enh(context.other_card)
            if enh and context.old ~= enh then
                e.x_mult = pb5_round2(e.x_mult + e.a_xmult)
                return { message = "Upgrade!" }
            end
        end
        if context.remove_playing_cards and context.port
            and context.port.destroyed_cards
            and #context.port.destroyed_cards > 0 then
            local n = #context.port.destroyed_cards
            if e.x_mult - e.a_xmult * n < 1 then
                if SMODS.destroy_joker then SMODS.destroy_joker(card) end
                return { message = "Eaten!" }
            end
            e.x_mult = pb5_round2(e.x_mult - e.a_xmult * n)
            return { message = "Downgrade!" }
        end
        if context.joker_main and e.x_mult ~= 1 then
            return { xmult = e.x_mult }
        end
    end,
}

-- weather_radio
-- PORT NOTE: the target hand is per-Joker here (see Spirit Box's note);
-- the boss disable runs through Game:disable_boss_blind, the fork's
-- canonical disable, at the same two moments PC disables (first hand
-- drawn, and in `before` as the scale lands).
SMODS.Joker {
    key = "weather_radio",
    name = "Weather Radio",
    rarity = 3,
    cost = 9,
    sprite = "weather_radio.png",
    negative_sprite = "weather_radio_negative.png",
    config = { extra = { x_mult = 1, a_xmult = 0.5,
        xmult_disable = 3, xmult_penalty = 2 } },
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        return { vars = { e.a_xmult, e.hand or "Pair", e.xmult_disable,
            e.xmult_penalty, e.x_mult } }
    end,
    loc_txt = { name = "Weather Radio", text = {
        "This Joker gains {X:mult,C:white}X#1#{} Mult if",
        "{C:attention}played hand{} contains a {C:attention}#2#{}.",
        "During {C:attention}Boss Blind{}, if this Joker has",
        "{X:mult,C:white}X#3#{} Mult or more, disable {C:attention}Boss Blind{}",
        "and this Joker loses {X:mult,C:white}X#4#{} Mult",
        "{C:inactive}(Currently {X:mult,C:white}X#5#{C:inactive} Mult)",
        "{s:0.75}poker hand changes at end of round",
    } },
    calculate = function(self, card, context)
        local e = card.ability.extra
        local g = pb5_game()
        local function roll_hand()
            if g and type(g.handlist) == "table" and #g.handlist > 0 then
                e.hand = g.handlist[SMODS.pseudorandom(
                    "weather_radio_hand", 1, #g.handlist)]
            end
        end
        local function try_disable()
            if pb5_boss(context) and not e.boss_disabled
                and e.x_mult >= e.xmult_disable
                and g and g.disable_boss_blind then
                e.x_mult = pb5_round2(e.x_mult - e.xmult_penalty)
                e.boss_disabled = true
                g:disable_boss_blind()
                return true
            end
            return false
        end
        if context.setting_blind then
            e.boss_disabled = false
            if not e.hand then roll_hand() end
        end
        if context.first_hand_drawn then
            if try_disable() then return { message = "Boss Disabled!" } end
        end
        if context.before and e.hand and context.poker_hands
            and context.poker_hands[e.hand]
            and next(context.poker_hands[e.hand]) then
            e.x_mult = pb5_round2(e.x_mult + e.a_xmult)
            if try_disable() then return { message = "Boss Disabled!" } end
            return { message = "Upgrade!" }
        end
        if context.joker_main and e.x_mult ~= 1 then
            return { xmult = e.x_mult }
        end
        if context.end_of_round then
            e.hand = nil
            roll_hand()
        end
    end,
}

--------------------------------------------------------------------------------
-- Debuff pair. PORT NOTE (both): PC's debuffs are Blind predicates
-- re-evaluated over the deck continuously. The fork's canonical channel
-- is the persistent perma_debuff flag, applied through SMODS.set_debuff,
-- so the ports refresh the whole deck's flags at the moments PC
-- re-evaluates (blind select / after each hand / when the tracked suit
-- changes). A card drawn mid-hand keeps its flag until the next
-- refresh, and leaving the Joker clears the flags it was maintaining.
--------------------------------------------------------------------------------

local PB5_DA_CAPO_CYCLE = { "Clubs", "Spades", "Diamonds", "Hearts", "None" }

local function pb5_set_debuff(target, flag)
    if SMODS.set_debuff then
        SMODS.set_debuff(target, flag)
    elseif type(target) == "table" and target.card_data then
        target.card_data.perma_debuff = flag or nil
    elseif type(target) == "table" then
        target.perma_debuff = flag or nil
    end
end

-- Apply `flag_for(data)` across the full deck, through the node setter
-- for cards in hand (the canonical path) and the data channel for the
-- rest.
local function pb5_refresh_debuffs(flag_for)
    local g = pb5_game()
    local by_data = {}
    if g and g.hand and type(g.hand.card_nodes) == "table" then
        for _, n in ipairs(g.hand.card_nodes) do
            if n.card_data then by_data[n.card_data] = n end
        end
    end
    for _, d in ipairs(pb5_full_deck_data()) do
        pb5_set_debuff(by_data[d] or d, flag_for(d) and true or false)
    end
end

-- da_capo
SMODS.Joker {
    key = "da_capo",
    name = "Da Capo",
    rarity = 3,
    cost = 8,
    sprite = "da_capo.png",
    negative_sprite = "da_capo_negative.png",
    config = { extra = { xmult = 4, suit_idx = 1 } },
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        return { vars = { e.xmult, PB5_DA_CAPO_CYCLE[e.suit_idx] } }
    end,
    loc_txt = { name = "Da Capo", text = {
        "{X:mult,C:white}X#1#{} Mult",
        "{C:red}Debuffs{} all but one {C:attention}suit{}",
        "every {C:attention}hand{}, in order:",
        "{C:clubs}Clubs{}, {C:spades}Spades{}, {C:diamonds}Diamonds{}, {C:hearts}Hearts{}, {C:inactive}None{}",
        "{C:inactive}(Currently: {V:1}#2#{C:inactive}){}",
    } },
    calculate = function(self, card, context)
        local e = card.ability.extra
        local function refresh()
            local suit = PB5_DA_CAPO_CYCLE[e.suit_idx]
            pb5_refresh_debuffs(function(d)
                if suit == "None" then return false end
                return d.enhancement ~= "stone" and d.suit ~= suit
            end)
        end
        if context.setting_blind then refresh() end
        if context.after then
            e.suit_idx = e.suit_idx % #PB5_DA_CAPO_CYCLE + 1
            refresh()
            return { message = PB5_DA_CAPO_CYCLE[e.suit_idx] }
        end
        if context.joker_main then
            return { xmult = e.xmult }
        end
    end,
    remove_from_deck = function(self, card, from_debuff)
        pb5_refresh_debuffs(function(d) return false end)
    end,
}

-- jester_of_nihil
SMODS.Joker {
    key = "jester_of_nihil",
    name = "Jester of Nihil",
    rarity = 3,
    cost = 7,
    sprite = "jester_of_nihil.png",
    negative_sprite = "jester_of_nihil_negative.png",
    config = { extra = { suit = "Spades", debuff_mult = 5 } },
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        local n = 0
        for _, d in ipairs(pb5_full_deck_data()) do
            if d.perma_debuff then n = n + 1 end
        end
        return { vars = { e.debuff_mult, e.suit, e.debuff_mult * n } }
    end,
    loc_txt = { name = "Jester of Nihil", text = {
        "{C:attention}Debuffs{} the suit of the",
        "{C:attention}last scored{} card",
        "{C:mult}+#1#{} Mult for every {C:attention}debuffed{}",
        "card in your full deck",
        "{C:inactive}(Currently {V:1}#2#{C:inactive} and {C:mult}+#3#{C:inactive} Mult)",
    } },
    calculate = function(self, card, context)
        local e = card.ability.extra
        if context.individual and pb5_play_area(context)
            and context.other_card
            and pb5_enh(context.other_card) ~= "stone" then
            e.last_suit = pb5_suit(context.other_card)
        end
        if context.after and e.last_suit and e.last_suit ~= e.suit then
            e.suit = e.last_suit
            pb5_refresh_debuffs(function(d)
                return d.enhancement ~= "stone" and d.suit == e.suit
            end)
            return { message = e.suit }
        end
        if context.joker_main then
            local n = 0
            for _, d in ipairs(pb5_full_deck_data()) do
                if d.perma_debuff then n = n + 1 end
            end
            if n > 0 then return { mult = e.debuff_mult * n } end
        end
    end,
    remove_from_deck = function(self, card, from_debuff)
        pb5_refresh_debuffs(function(d) return false end)
    end,
}

--------------------------------------------------------------------------------
-- Cross + Unholy Alliance
--------------------------------------------------------------------------------

-- cross
-- PORT NOTE: PC also makes Jokers and consumables indestructible
-- (a check_eternal query) and keeps protected cards out of other
-- effects' removed lists. The fork's destroying_card pass covers
-- playing cards only, so the veto lands there; a blanket veto also
-- stops destructions other effects pay as a cost, as PC's does for
-- playing cards.
SMODS.Joker {
    key = "cross",
    name = "Cross",
    rarity = 2,
    cost = 6,
    sprite = "cross.png",
    negative_sprite = "cross_negative.png",
    loc_txt = { name = "Cross", text = {
        "Playing cards, Jokers, and",
        "Consumables {C:attention}cannot{} be {C:red}destroyed{}",
        "{C:inactive}(Does not prevent {C:money}selling{}",
        "{C:inactive}or {C:red}self-destruction{C:inactive})",
    } },
    calculate = function(self, card, context)
        if context.destroying_card then
            return { remove = false }
        end
    end,
}

-- unholy_alliance
-- PORT NOTE: PC's revive (destroy itself instead of losing at 666+
-- Chips) answers a game_over check inside end_of_round; the fork raises
-- no game_over context and no return carries a save, so the revive is
-- unported. The scaling is exact.
SMODS.Joker {
    key = "unholy_alliance",
    name = "Unholy Alliance",
    rarity = 1,
    cost = 6,
    sprite = "unholy_alliance.png",
    negative_sprite = "unholy_alliance_negative.png",
    config = { extra = { a_chips = 12, chips = 0, revive_treshold = 666 } },
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        return { vars = { e.a_chips, e.chips } }
    end,
    loc_txt = { name = "Unholy Alliance", text = {
        "This Joker gains {C:chips}+#1#{} Chips",
        "when a card or Joker is {C:attention}destroyed{}",
        "{C:inactive}(Currently {C:chips}+#2#{C:inactive} Chips)",
    } },
    calculate = function(self, card, context)
        local e = card.ability.extra
        if context.remove_playing_cards and context.port
            and context.port.destroyed_cards
            and #context.port.destroyed_cards > 0 then
            e.chips = e.chips + e.a_chips * #context.port.destroyed_cards
            return { message = "Upgrade!" }
        end
        if context.joker_type_destroyed and context.card ~= card then
            e.chips = e.chips + e.a_chips
            return { message = "Upgrade!" }
        end
        if context.joker_main and e.chips > 0 then
            return { chips = e.chips }
        end
    end,
}

end -- SMODS.Joker (Tier 3 wave 2)

--------------------------------------------------------------------------------
-- Minor Arcana additions: the 8 enhancement conversions (mod_conv now
-- accepts the registered enhancements), the two Tag-granting Wands, and
-- Queen of Wands (Dichrome edition).
--------------------------------------------------------------------------------

if SMODS.Consumable then

local function pb5_conversion(key, name, max_hl, enh_value, enh_name, plural)
    SMODS.Consumable {
        set = "minor_arcana", key = key, cost = 3,
        loc_txt = { name = name, text = {
            "Enhances {C:attention}#1#{}",
            max_hl == 1 and "selected card into an" or "selected cards to",
            "{C:attention}#2#" .. (plural and "s{}" or "{}"),
        } },
        config = { max_highlighted = max_hl,
            mod_conv = "m_pbp_" .. enh_value },
        sprite = key .. ".png",
        negative_sprite = key .. "_negative.png",
        loc_vars = function(self, info_queue, card)
            local cfg = (card and (card.ability or card.config)) or {}
            return { vars = { cfg.max_highlighted, enh_name } }
        end,
    }
end

pb5_conversion("five_of_cups", "Five of Cups", 2, "soaked", "Soaked Card", true)
pb5_conversion("five_of_pentacles", "Five of Pentacles", 1, "antique", "Antique Card", false)
pb5_conversion("nine_of_wands", "Nine of Wands", 2, "bandaged", "Bandaged Card", true)
pb5_conversion("page_of_pentacles", "Page of Pentacles", 2, "sleeved", "Sleeved Card", true)
pb5_conversion("page_of_swords", "Page of Swords", 2, "domino", "Domino Card", true)
pb5_conversion("queen_of_cups", "Queen of Cups", 2, "ceramic", "Ceramic Card", true)
pb5_conversion("six_of_wands", "Six of Wands", 2, "wrapped", "Wrapped Card", true)
pb5_conversion("three_of_swords", "Three of Swords", 2, "stained", "Stained Card", true)

SMODS.Consumable {
    set = "minor_arcana", key = "knight_of_wands", cost = 3,
    loc_txt = { name = "Knight of Wands", text = {
        "Gives a {C:mult}High Risk{C:attention} Tag",
    } },
    sprite = "knight_of_wands.png",
    negative_sprite = "knight_of_wands_negative.png",
    can_use = function(self, card) return true end,
    use = function(self, card, area, copier)
        pb5_add_tag("high_risk")
    end,
}

SMODS.Consumable {
    set = "minor_arcana", key = "seven_of_wands", cost = 3,
    loc_txt = { name = "Seven of Wands", text = {
        "Gives a {C:attention}Breaking Tag",
    } },
    sprite = "seven_of_wands.png",
    negative_sprite = "seven_of_wands_negative.png",
    can_use = function(self, card) return true end,
    use = function(self, card, area, copier)
        pb5_add_tag("breaking")
    end,
}

-- queen_of_wands: PC picks a random uneditioned Joker (not a selected
-- one), so this stays a plain use, not a target_joker card.
SMODS.Consumable {
    set = "minor_arcana", key = "queen_of_wands", cost = 3,
    loc_txt = { name = "Queen of Wands", text = {
        "{C:green}#1# in #2#{} chance to",
        "add {C:dark_edition}Dichrome{} edition",
        "to a random {C:attention}Joker",
    } },
    config = { extra = { odds = 3 } },
    sprite = "queen_of_wands.png",
    negative_sprite = "queen_of_wands_negative.png",
    loc_vars = function(self, info_queue, card)
        local cfg = (card and (card.ability or card.config)) or {}
        local extra = cfg.extra or {}
        local num, den = 1, extra.odds or 3
        if SMODS.get_probability_vars then
            num, den = SMODS.get_probability_vars(card, num, den,
                "paperback_queen_of_wands")
        end
        return { vars = { num, den } }
    end,
    can_use = function(self, card)
        for _, j in ipairs(pb5_jokers()) do
            if j.edition == nil or j.edition == "base" then
                return true
            end
        end
        return false
    end,
    use = function(self, card, area, copier)
        local eligible = {}
        for _, j in ipairs(pb5_jokers()) do
            if j.edition == nil or j.edition == "base" then
                eligible[#eligible + 1] = j
            end
        end
        if #eligible == 0 then return end
        local cfg = (card and (card.ability or card.config)) or {}
        local odds = (cfg.extra or {}).odds or 3
        if SMODS.pseudorandom_probability(card, "queen_of_wands",
            1, odds, "paperback_queen_of_wands") then
            local target = eligible[SMODS.pseudorandom(
                "queen_of_wands_joker", 1, #eligible)]
            target.edition = "dichrome"
        end
    end,
}

end -- SMODS.Consumable (Tier 3 arcana)

end -- Tier 3 expansion block
