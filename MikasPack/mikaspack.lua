--- Mika's Mod Collection (3DS port) for Balatro3DS.
---
--- A port of Mika's Mod Collection (PC, by Mika -- https://github.com/MikaSchoenmakers/MikasModCollection,
--- GPLv3) to the Balatro3DS fork's Steamodded-style mod API. The PC mod targets
--- Steamodded 0.9.x, so every effect was re-expressed in the fork's terms:
--- per-frame `Card.update` patches became `calculate` reads of live state,
--- `G.GAME` bookkeeping became ability fields, and the two run-rule channels
--- the mod needs (shrinking a blind's target, spending into debt) are small
--- general fork APIs (`SMODS.adjust_blind_target`, the `debt_limit` Joker
--- config field). Two Jokers stay unported -- Dagonet and Cicero; the README
--- says exactly why.
---
--- Roster: 58 of 60 Jokers, the 3 default-enabled consumables (Ace of
--- Pentacles, Page of Pentacles, Incense) and 6 of 7 decks. The 6 in-dev
--- Tarots and 2 empty-stub Tarots are off / empty on PC too and stay out.

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

local function ex(card) return card.ability.extra end

local function jokers()
    return (G and G.jokers) or {}
end

local function find_joker(id)
    for _, j in ipairs(jokers()) do
        if j.def and j.def.id == id then return j end
    end
    return nil
end

local function data_of(c)
    return (c and c.card_data) or c or {}
end

local function edition_of(data)
    return data.edition or (data.modifier and data.modifier.edition)
end

--- Count cards matching `pred` across the whole deck (deck + discard + hand),
--- plus any `views` not already in those areas (the cards being scored are in
--- none of them while a hand runs). `pred` receives nodes and bare card_data
--- alike; read through `data_of`.
local function full_deck_count(pred, views)
    local n = 0
    if G and G.count_cards_in_full_deck then
        local ok, c = pcall(function() return G:count_cards_in_full_deck(pred) end)
        if ok and type(c) == "number" then n = c end
    end
    if views then
        local seen = {}
        local function mark(list)
            if type(list) == "table" then
                for _, c in ipairs(list) do seen[c] = true end
            end
        end
        if G then
            if G.deck then mark(G.deck.cards); mark(G.deck.discard_pile) end
            if G.hand then mark(G.hand.cards) end
        end
        for _, v in ipairs(views) do
            if not seen[v] and pred(v) then n = n + 1 end
        end
    end
    return n
end

local function create_planet(hand_name, edition)
    if not hand_name or not G or not G.random_planet_id_for_hand_name then return nil end
    local id = G:random_planet_id_for_hand_name(hand_name)
    if not id then return nil end
    return SMODS.add_card { set = "Planet", key = id, edition = edition }
end

local function create_random_tarot()
    if not G or not G.random_consumable_id_of_kind then return nil end
    local id = G:random_consumable_id_of_kind("tarot")
    if not id then return nil end
    return SMODS.add_card { set = "Tarot", key = id }
end

--- A random Joker the way the shop deals them (70 / 25 / 5 by rarity).
local function create_random_joker(edition, bypass_limit)
    if not G or not G.random_joker_def_id_by_rarity then return nil end
    local roll = SMODS.pseudorandom("mmc_random_joker", 1, 100)
    local rarity = roll <= 70 and 1 or (roll <= 95 and 2 or 3)
    local id = G:random_joker_def_id_by_rarity(rarity, "mmc_random_joker")
    if not id then return nil end
    return SMODS.add_card { set = "Joker", key = id, edition = edition, bypass_limit = bypass_limit }
end

--- PC's `poll_edition`, as a table draw: foil and holo common, polychrome
--- rarer, negative rarest (and never when the source forbids it).
local function roll_edition(seed, allow_negative)
    local pool = { "foil", "foil", "holo", "holo", "polychrome" }
    if allow_negative then pool[#pool + 1] = "negative" end
    return SMODS.pseudorandom_element(pool, seed)
end

local function set_joker_edition(j, edition)
    j.edition = edition
    if G and G.refresh_joker_capacity_from_negatives then
        G:refresh_joker_capacity_from_negatives()
    end
end

--- The finished hand's score at `final_scoring_step`. Big-safe: the totals
--- multiply with the plain operators, which promote.
local function hand_total(context)
    local p = context.port or {}
    return (p.chips or 0) * (p.mult or 1)
end

local function blind_target()
    return G and G.current_blind_target or 0
end

--- Track the last hand this Joker saw scored (the Blue Seal planets name it).
local function note_hand(card, context)
    if context.scoring_name then ex(card).last_hand = context.scoring_name end
end

--------------------------------------------------------------------------------
-- Consumables
--------------------------------------------------------------------------------

SMODS.Consumable {
    set = "Tarot", key = "ace_of_pentacles", cost = 4,
    loc_txt = { name = "Ace Of Pentacles", text = {
        "{C:green}#2# in #1#{} chance",
        "to set money to",
        "{C:money}$0{}, otherwise",
        "{C:attention}double{} your money",
    } },
    config = { extra = { odds = 4 } },
    sprite = "c_mmc_ace_of_pentacles.png",
    negative_sprite = "c_mmc_ace_of_pentacles_negative.png",
    loc_vars = function(self, info_queue, card)
        local num, den = SMODS.get_probability_vars(card, 1, card.ability.extra.odds,
            "mmc_ace_of_pentacles")
        return { vars = { den, num } }
    end,
    can_use = function(self, card) return true end,
    use = function(self, card)
        if SMODS.pseudorandom_probability(card, "mmc_ace_of_pentacles", 1,
                card.ability.extra.odds) then
            G:ease_dollars(-(tonumber(G.money) or 0))
        else
            G:ease_dollars(tonumber(G.money) or 0)
        end
    end,
}

SMODS.Consumable {
    set = "Tarot", key = "page_of_pentacles", cost = 1,
    loc_txt = { name = "Page Of Pentacles", text = {
        "Multiply",
        "money by {C:red}-1{}",
    } },
    config = {},
    sprite = "c_mmc_page_of_pentacles.png",
    negative_sprite = "c_mmc_page_of_pentacles_negative.png",
    can_use = function(self, card) return true end,
    use = function(self, card)
        local money = tonumber(G.money) or 0
        if money ~= 0 then G:ease_dollars(-2 * money) end
    end,
}

SMODS.Consumable {
    set = "Spectral", key = "incense", cost = 4,
    loc_txt = { name = "Incense", text = {
        "Add {C:dark_edition}Negative{} to",
        "a random {C:attention}Joker{},",
        "{C:red}-$#1#{}",
    } },
    config = { extra = { dollars = 50 } },
    sprite = "c_mmc_incense.png",
    negative_sprite = "c_mmc_incense_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.dollars } }
    end,
    can_use = function(self, card)
        for _, j in ipairs(jokers()) do
            if j.edition == nil or j.edition == "base" then return true end
        end
        return false
    end,
    use = function(self, card)
        -- PORT NOTE: on PC the price climbs $25 per use, kept in run state the
        -- fork has no home for. The port charges the flat $50 every time.
        local pool = {}
        for _, j in ipairs(jokers()) do
            if j.edition == nil or j.edition == "base" then pool[#pool + 1] = j end
        end
        if #pool == 0 then return end
        local pick = SMODS.pseudorandom_element(pool, "mmc_incense")
        if pick then
            G:ease_dollars(-card.ability.extra.dollars)
            set_joker_edition(pick, "negative")
        end
    end,
}

--------------------------------------------------------------------------------
-- Jokers
--------------------------------------------------------------------------------

-- Prime Time: scored 2s, 3s, 5s, 7s and Aces give X1.2 Mult.
SMODS.Joker {
    key = "prime_time", rarity = 1, cost = 4,
    loc_txt = { name = "Prime Time", text = {
        "Each played {C:attention}2{},",
        "{C:attention}3{}, {C:attention}5{}, {C:attention}7{} or {C:attention}Ace{}, gives",
        "{X:mult,C:white}X#1#{} Mult when scored",
    } },
    config = { extra = { x_mult = 1.2 } },
    sprite = "j_mmc_prime_time.png", negative_sprite = "j_mmc_prime_time_negative.png",
    blueprint_compat = true,
    loc_vars = function(self, info_queue, card)
        return { vars = { ex(card).x_mult } }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            local id = context.other_card:get_id()
            if id == 2 or id == 3 or id == 5 or id == 7 or id == 14 then
                return { x_mult = ex(card).x_mult }
            end
        end
    end,
}

-- Straight Nate: X4 Mult with a Straight while Odd Todd and Even Steven are
-- held; +1 Joker slot is declarative (PC added and removed it by hand).
SMODS.Joker {
    key = "straight_nate", rarity = 3, cost = 7,
    loc_txt = { name = "Straight Nate", text = {
        "{X:mult,C:white} X#1# {} Mult if played hand",
        "contains a {C:attention}Straight{} and you have",
        "both {C:attention}Odd Todd{} and {C:attention}Even Steven{}",
        "Gives {C:dark_edition}+#2#{} Joker slot",
    } },
    config = { extra = { x_mult = 4 }, joker_slots = 1 },
    sprite = "j_mmc_straight_nate.png", negative_sprite = "j_mmc_straight_nate_negative.png",
    blueprint_compat = true,
    loc_vars = function(self, info_queue, card)
        return { vars = { ex(card).x_mult, card.ability.joker_slots } }
    end,
    calculate = function(self, card, context)
        if context.joker_main and next(context.poker_hands["Straight"])
            and find_joker("j_odd_todd") and find_joker("j_even_steven") then
            return { x_mult = ex(card).x_mult }
        end
    end,
}

-- The Fisherman: +1 hand size per discard action, -1 per hand played, reset
-- each round. The size itself is the dynamic `h_size` ability field.
SMODS.Joker {
    key = "fisherman", rarity = 2, cost = 6,
    loc_txt = { name = "The Fisherman", text = {
        "{C:attention}+#2#{} hand size per discard",
        "{C:attention}-#2#{} hand size per hand played",
        "Resets every round",
        "{C:inactive}(Currently {C:attention}+#1#{C:inactive} hand size)",
    } },
    config = { extra = { current_h_size = 0, h_mod = 1 }, h_size = 0 },
    sprite = "j_mmc_fisherman.png", negative_sprite = "j_mmc_fisherman_negative.png",
    blueprint_compat = false,
    loc_vars = function(self, info_queue, card)
        return { vars = { ex(card).current_h_size, ex(card).h_mod } }
    end,
    calculate = function(self, card, context)
        local e = ex(card)
        if context.pre_discard then
            e.current_h_size = e.current_h_size + e.h_mod
            card.ability.h_size = e.current_h_size
            return { message = "Hand Up!" }
        end
        if context.joker_main and e.current_h_size > 0 then
            e.current_h_size = math.max(0, e.current_h_size - e.h_mod)
            card.ability.h_size = e.current_h_size
            return { message = "Hand Down!" }
        end
        if context.end_of_round then
            e.current_h_size = 0
            card.ability.h_size = 0
        end
    end,
}

-- Impatient Joker: +3 Mult per card discarded this round.
SMODS.Joker {
    key = "impatient", rarity = 2, cost = 6,
    loc_txt = { name = "Impatient Joker", text = {
        "{C:mult}+#2#{} Mult per card discarded",
        "Resets every round",
        "{C:inactive}(Currently {C:mult}+#1#{C:inactive} Mult)",
    } },
    config = { extra = { mult_mod = 3, current_mult = 0 } },
    sprite = "j_mmc_impatient.png", negative_sprite = "j_mmc_impatient_negative.png",
    blueprint_compat = true,
    loc_vars = function(self, info_queue, card)
        return { vars = { ex(card).current_mult, ex(card).mult_mod } }
    end,
    calculate = function(self, card, context)
        local e = ex(card)
        if context.discard and not context.blueprint then
            e.current_mult = e.current_mult + e.mult_mod
            return { message = "+" .. e.mult_mod .. " Mult" }
        end
        if context.joker_main and e.current_mult > 0 then
            return { mult = e.current_mult }
        end
        if context.end_of_round then e.current_mult = 0 end
    end,
}

-- Cultist: XMult grows by 1 per hand played this round; a hand scores the
-- value the counter held before it (so the first hand of a round is X1).
SMODS.Joker {
    key = "cultist", rarity = 3, cost = 8,
    loc_txt = { name = "Cultist", text = {
        "{X:mult,C:white}X#2#{} Mult per hand played",
        "Resets every round",
        "{C:inactive}(Currently {X:mult,C:white}X#1#{C:inactive} Mult)",
    } },
    config = { extra = { current_x_mult = 1, x_mult_mod = 1, old = 0 } },
    sprite = "j_mmc_cultist.png", negative_sprite = "j_mmc_cultist_negative.png",
    blueprint_compat = true,
    loc_vars = function(self, info_queue, card)
        return { vars = { ex(card).current_x_mult, ex(card).x_mult_mod } }
    end,
    calculate = function(self, card, context)
        local e = ex(card)
        if context.before and not context.blueprint then
            e.old = e.current_x_mult
            e.current_x_mult = e.current_x_mult + e.x_mult_mod
        end
        if context.joker_main and e.old > 1 then
            return { x_mult = e.old }
        end
        if context.end_of_round then
            e.current_x_mult = 1
            e.old = 0
        end
    end,
}

-- Seal Collector: +25 Chips per sealed card in the full deck.
SMODS.Joker {
    key = "seal_collector", rarity = 1, cost = 4,
    loc_txt = { name = "Seal Collector", text = {
        "Gains {C:chips}+#2#{} Chips for",
        "every card with a {C:attention}seal{}",
        "{C:inactive}(Currently {C:chips}+#1#{C:inactive} Chips)",
    } },
    config = { extra = { chip_mod = 25 } },
    sprite = "j_mmc_seal_collector.png", negative_sprite = "j_mmc_seal_collector_negative.png",
    blueprint_compat = true,
    loc_vars = function(self, info_queue, card)
        local n = full_deck_count(function(c) return data_of(c).seal ~= nil end)
        return { vars = { n * ex(card).chip_mod, ex(card).chip_mod } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            local n = full_deck_count(function(c) return data_of(c).seal ~= nil end,
                context.full_hand)
            if n > 0 then return { chips = n * ex(card).chip_mod } end
        end
    end,
}

-- Camper: discarded cards permanently gain +4 Chips.
SMODS.Joker {
    key = "camper", rarity = 2, cost = 5,
    loc_txt = { name = "Camper", text = {
        "Every discarded {C:attention}card{}",
        "permanently gains",
        "{C:chips}+#1#{} Chips",
    } },
    config = { extra = { chip_mod = 4 } },
    sprite = "j_mmc_camper.png", negative_sprite = "j_mmc_camper_negative.png",
    blueprint_compat = true,
    loc_vars = function(self, info_queue, card)
        return { vars = { ex(card).chip_mod } }
    end,
    calculate = function(self, card, context)
        if context.discard and context.other_card then
            local other = context.other_card
            SMODS.set_perma(other, "perma_bonus",
                (SMODS.get_perma(other, "perma_bonus") or 0) + ex(card).chip_mod)
            return { message = "+" .. ex(card).chip_mod .. " Chips" }
        end
    end,
}

-- Scratch Card: pays for scored 7s -- $1 / $3 / $10 / $25 / $50 for 1-5+.
-- (PC pays twice over, once by hand and once through the return; the port
-- pays the listed amount once, through the return alone.)
SMODS.Joker {
    key = "scratch_card", rarity = 1, cost = 4,
    loc_txt = { name = "Scratch Card", text = {
        "Gain {C:money}$#1#{}, {C:money}$#2#{}, {C:money}$#3#{}, {C:money}$#4#{},",
        "{C:money}$#5#{} when 1, 2, 3, 4 or 5",
        "{C:attention}7 cards{} are scored,",
        "respectively",
    } },
    config = { extra = { seven_tally = 0 } },
    sprite = "j_mmc_scratch_card.png", negative_sprite = "j_mmc_scratch_card_negative.png",
    blueprint_compat = true,
    loc_vars = function(self, info_queue, card)
        return { vars = { 1, 3, 10, 25, 50 } }
    end,
    calculate = function(self, card, context)
        local e = ex(card)
        if context.individual and context.cardarea == G.play
            and context.other_card:get_id() == 7 then
            e.seven_tally = e.seven_tally + 1
        end
        if context.joker_main then
            local pay = ({ [1] = 1, [2] = 3, [3] = 10, [4] = 25 })[e.seven_tally]
                or (e.seven_tally >= 5 and 50 or nil)
            if pay then return { dollars = pay } end
        end
        if context.after then e.seven_tally = 0 end
    end,
}

-- Delayed Joker: every 5th action (hand played or discard) pays out
-- +20 Mult, +100 Chips and X1.5 Mult.
SMODS.Joker {
    key = "delayed", rarity = 2, cost = 7,
    loc_txt = { name = "Delayed Joker", text = {
        "Gives {C:mult}+#1#{} Mult, {C:chips}+#2#{}",
        "Chips and {X:mult,C:white}X#3#{} Mult on",
        "the {C:attention}#5#th{} action",
        "{C:inactive}(Current action: {C:attention}#4#{C:inactive} )",
    } },
    config = { extra = { mult = 20, chips = 100, x_mult = 1.5, every = 4, action_tally = 1 } },
    sprite = "j_mmc_delayed.png", negative_sprite = "j_mmc_delayed_negative.png",
    blueprint_compat = true,
    loc_vars = function(self, info_queue, card)
        local e = ex(card)
        return { vars = { e.mult, e.chips, e.x_mult, e.action_tally, e.every } }
    end,
    calculate = function(self, card, context)
        local e = ex(card)
        if context.before and not context.blueprint then
            e.action_tally = e.action_tally + 1
        end
        if context.pre_discard and not context.blueprint then
            e.action_tally = e.action_tally % e.every + 1
        end
        if context.joker_main then
            if e.action_tally == e.every + 1 then
                return { mult = e.mult, chips = e.chips, x_mult = e.x_mult }
            end
            return { message = "Charging..." }
        end
        if context.after and e.action_tally == e.every + 1 then
            e.action_tally = 1
        end
    end,
}

-- The Show-Off: +X0.25 Mult whenever a blind is finished with more than
-- double its requirement across the round.
SMODS.Joker {
    key = "showoff", rarity = 3, cost = 8,
    loc_txt = { name = "The Show-Off", text = {
        "Gains {X:mult,C:white}X#2#{} Mult when",
        "a blind is finished with",
        "{C:attention}X#3#{} the chip requirement",
        "{C:inactive}(Currently {X:mult,C:white}X#1#{C:inactive} Mult)",
    } },
    config = { extra = { current_x_mult = 1, x_mult_mod = 0.25, req = 2 } },
    sprite = "j_mmc_showoff.png", negative_sprite = "j_mmc_showoff_negative.png",
    blueprint_compat = true,
    loc_vars = function(self, info_queue, card)
        local e = ex(card)
        return { vars = { e.current_x_mult, e.x_mult_mod, e.req } }
    end,
    calculate = function(self, card, context)
        local e = ex(card)
        note_hand(card, context)
        if context.final_scoring_step then
            card._mmc_round_total = (card._mmc_round_total or 0) + hand_total(context)
        end
        if context.joker_main and e.current_x_mult > 1 then
            return { x_mult = e.current_x_mult }
        end
        if context.end_of_round and not context.game_over then
            local total = card._mmc_round_total or 0
            card._mmc_round_total = 0
            if SMODS.big_cmp(total, blind_target() * e.req) > 0 then
                e.current_x_mult = e.current_x_mult + e.x_mult_mod
                return { message = "X" .. e.current_x_mult .. " Mult" }
            end
        end
    end,
}

-- The Sniper: +X2 Mult whenever a blind is finished within 110% of its
-- requirement (a beaten blind always scored at least 100%).
SMODS.Joker {
    key = "sniper", rarity = 3, cost = 10,
    loc_txt = { name = "The Sniper", text = {
        "Gains {X:mult,C:white}X#2#{} Mult when a",
        "blind is finished within {C:attention}#3#%{} of",
        "the {C:attention}exact{} chip requirement",
        "{C:inactive}(Currently {X:mult,C:white}X#1#{C:inactive} Mult)",
    } },
    config = { extra = { current_x_mult = 1, x_mult_mod = 2, percentage = 10 } },
    sprite = "j_mmc_sniper.png", negative_sprite = "j_mmc_sniper_negative.png",
    blueprint_compat = true,
    loc_vars = function(self, info_queue, card)
        local e = ex(card)
        return { vars = { e.current_x_mult, e.x_mult_mod, e.percentage } }
    end,
    calculate = function(self, card, context)
        local e = ex(card)
        note_hand(card, context)
        if context.final_scoring_step then
            card._mmc_round_total = (card._mmc_round_total or 0) + hand_total(context)
        end
        if context.joker_main and e.current_x_mult > 1 then
            return { x_mult = e.current_x_mult }
        end
        if context.end_of_round and not context.game_over then
            local total = card._mmc_round_total or 0
            card._mmc_round_total = 0
            local limit = blind_target() * (1 + e.percentage / 100)
            if SMODS.big_cmp(total, limit) <= 0 and SMODS.big_cmp(total, 0) > 0 then
                e.current_x_mult = e.current_x_mult + e.x_mult_mod
                return { message = "Bullseye!" }
            end
        end
    end,
}

-- Blackjack Joker: XMult from the played cards' blackjack total -- X3 at
-- exactly 21, X0.5 less per point below, nothing at 16 or under. Aces count
-- as 11 or 1, whichever makes the best total that does not bust.
SMODS.Joker {
    key = "blackjack", rarity = 2, cost = 6,
    loc_txt = { name = "Blackjack Joker", text = {
        "Gives {X:mult,C:white}X#1#{} Mult when",
        "the ranks of all played",
        "cards is {C:attention}exactly #2#{}",
        "Gives {X:mult,C:white}X#3#{} Mult less for",
        "every point below #2#",
    } },
    config = { extra = { x_mult = 3, target = 21, step = 0.5, rank_tally = nil } },
    sprite = "j_mmc_blackjack.png", negative_sprite = "j_mmc_blackjack_negative.png",
    blueprint_compat = true,
    loc_vars = function(self, info_queue, card)
        local e = ex(card)
        return { vars = { e.x_mult, e.target, e.step } }
    end,
    calculate = function(self, card, context)
        local e = ex(card)
        if context.before and not context.blueprint then
            local tallies = { 0 }
            for _, view in ipairs(context.full_hand or {}) do
                local id = view:get_id()
                local next_tallies = {}
                if id == 14 then
                    for _, t in ipairs(tallies) do
                        next_tallies[#next_tallies + 1] = t + 11
                        next_tallies[#next_tallies + 1] = t + 1
                    end
                else
                    local v = id > 10 and 10 or id
                    for _, t in ipairs(tallies) do
                        next_tallies[#next_tallies + 1] = t + v
                    end
                end
                tallies = next_tallies
            end
            e.rank_tally = tallies
        end
        if context.joker_main and e.rank_tally then
            local best = nil
            for _, t in ipairs(e.rank_tally) do
                if t <= e.target and (best == nil or t > best) then best = t end
            end
            if best then
                local xm = e.x_mult - (e.target - best) * e.step
                if xm > 1 then return { x_mult = xm } end
            end
        end
        if context.after then e.rank_tally = nil end
    end,
}

-- Batman: +Mult for every non-lethal hand; the gain grows by 1 per Joker
-- with "Joker" in its name. (PC recounts the gain every frame; the port
-- recomputes it when a hand's score lands, the only moment it is spent.)
SMODS.Joker {
    key = "batman", rarity = 3, cost = 8,
    loc_txt = { name = "Batman", text = {
        "Gains {C:mult}+#2#{} Mult for",
        "every {C:attention}non-lethal{} hand played",
        "Mult gain increases for every",
        "Joker with {C:attention}Joker{} in the name",
        "{C:inactive}(Currently {C:mult}+#1#{C:inactive} Mult)",
    } },
    config = { extra = { current_mult = 1, base = 1 } },
    sprite = "j_mmc_batman.png", negative_sprite = "j_mmc_batman_negative.png",
    blueprint_compat = true,
    loc_vars = function(self, info_queue, card)
        local e = ex(card)
        local gain = e.base
        for _, j in ipairs(jokers()) do
            if j.def and j.def.name and j.def.name:find("Joker", 1, true) then
                gain = gain + 1
            end
        end
        return { vars = { e.current_mult, gain } }
    end,
    calculate = function(self, card, context)
        local e = ex(card)
        note_hand(card, context)
        if context.final_scoring_step then
            card._mmc_round_total = (card._mmc_round_total or 0) + hand_total(context)
            if SMODS.big_cmp(card._mmc_round_total, blind_target()) < 0 then
                local gain = e.base
                for _, j in ipairs(jokers()) do
                    if j.def and j.def.name and j.def.name:find("Joker", 1, true) then
                        gain = gain + 1
                    end
                end
                e.current_mult = e.current_mult + gain
            end
        end
        if context.joker_main and e.current_mult > 1 then
            return { mult = e.current_mult }
        end
        if context.end_of_round then card._mmc_round_total = 0 end
    end,
}

-- Bomb: +15 Mult, +15 more per round, self-destructs after 3 rounds.
SMODS.Joker {
    key = "bomb", rarity = 1, cost = 5,
    loc_txt = { name = "Bomb", text = {
        "Gains {C:mult}+#2#{} Mult per round",
        "self destructs after {C:attention}#3#{} rounds",
        "{C:inactive}(Currently {C:mult}+#1#{C:inactive} Mult)",
    } },
    config = { extra = { current_mult = 15, mult_mod = 15, rounds = 3 } },
    sprite = "j_mmc_bomb.png", negative_sprite = "j_mmc_bomb_negative.png",
    blueprint_compat = true, eternal_compat = false,
    loc_vars = function(self, info_queue, card)
        local e = ex(card)
        return { vars = { e.current_mult, e.mult_mod, e.rounds } }
    end,
    calculate = function(self, card, context)
        local e = ex(card)
        if context.joker_main then
            return { mult = e.current_mult }
        end
        if context.end_of_round and not context.blueprint then
            e.rounds = e.rounds - 1
            if e.rounds <= 0 then
                SMODS.destroy_joker(card)
                return { message = "Boom!" }
            end
            e.current_mult = e.current_mult + e.mult_mod
            return { message = "+" .. e.mult_mod .. " Mult" }
        end
    end,
}

-- Eye Chart: +20 Chips per occurrence of its letter in other Jokers' names.
-- PC re-rolls the letter whenever the card is (re)priced in the shop; the
-- port re-rolls when the shop opens and when Eye Chart itself is gained.
SMODS.Joker {
    key = "eye_chart", rarity = 1, cost = 4,
    loc_txt = { name = "Eye Chart", text = {
        "Gives {C:chips}+#1#{} Chips for every",
        "letter {C:attention}#2#{} in your Jokers' names",
        "Letter changes when this",
        "Joker appears in the shop",
    } },
    config = { extra = { chips = 20, letter = "A" } },
    sprite = "j_mmc_eye_chart.png", negative_sprite = "j_mmc_eye_chart_negative.png",
    blueprint_compat = false,
    loc_vars = function(self, info_queue, card)
        return { vars = { ex(card).chips, ex(card).letter } }
    end,
    calculate = function(self, card, context)
        local e = ex(card)
        if context.post_trigger and context.other_card ~= card
            and context.other_card and context.other_card.def then
            local name = (context.other_card.def.name or ""):lower()
            local letter = e.letter:lower()
            local _, count = name:gsub(letter, "")
            if count > 0 then return { chips = e.chips * count } end
        end
    end,
    add_to_deck = function(self, card)
        local letters = { "a", "b", "c", "d", "e", "é", "f", "g", "h", "i", "j",
            "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w",
            "x", "y", "z" }
        ex(card).letter = SMODS.pseudorandom_element(letters, "mmc_eye_chart"):upper()
    end,
}

--- Held Blue Seal cards in hand right now -- the set whose end-of-round
--- effect Aurora Borealis and Harp Seal ride on.
local function held_blue_seals()
    local out = {}
    local hand = G and G.hand
    if not hand then return out end
    local nodes = hand.card_nodes
    if type(nodes) ~= "table" or #nodes == 0 then
        nodes = {}
        for _, d in ipairs(hand.cards or {}) do nodes[#nodes + 1] = { card_data = d } end
    end
    for _, node in ipairs(nodes) do
        local d = data_of(node)
        if d.seal == "blue" then
            local debuffed = node.is_debuffed and node:is_debuffed()
            if not debuffed then out[#out + 1] = node end
        end
    end
    return out
end

-- Grudgeful Joker: bank up to 25% of the blind's requirement from last
-- round's excess score, and spend it off the next blind's target.
SMODS.Joker {
    key = "grudgeful", rarity = 3, cost = 9,
    loc_txt = { name = "Grudgeful Joker", text = {
        "Lowers blind requirement",
        "with {C:attention}excess Chips{} from",
        "last round. Caps at {C:attention}#2#%",
        "of current blind's Chips",
        "{C:inactive}(Currently {C:chips}+#1#{C:inactive} Chips)",
    } },
    config = { extra = { current_chips = 0, percentage = 25 } },
    sprite = "j_mmc_grudgeful.png", negative_sprite = "j_mmc_grudgeful_negative.png",
    blueprint_compat = true,
    loc_vars = function(self, info_queue, card)
        local e = ex(card)
        return { vars = { e.current_chips, e.percentage } }
    end,
    calculate = function(self, card, context)
        local e = ex(card)
        if context.final_scoring_step then
            card._mmc_round_total = (card._mmc_round_total or 0) + hand_total(context)
        end
        if context.joker_main and not context.blueprint then
            local stored = tonumber(e.current_chips) or 0
            if SMODS.is_big(e.current_chips) or stored > 0 then
                SMODS.adjust_blind_target(-e.current_chips)
                return { message = "-" .. tostring(e.current_chips) .. " Chips" }
            end
        end
        if context.after and not context.blueprint then
            e.current_chips = 0
        end
        if context.end_of_round and not context.blueprint then
            local total = card._mmc_round_total or 0
            card._mmc_round_total = 0
            local target = blind_target()
            if SMODS.big_cmp(total, target) >= 0 then
                local excess = total - target
                local cap = target * e.percentage / 100
                local banked = SMODS.big_cmp(excess, cap) > 0 and cap or excess
                if SMODS.is_big(banked) then
                    e.current_chips = banked
                else
                    e.current_chips = math.ceil(banked)
                end
                return { message = "Banked!" }
            end
        end
    end,
}

-- Finishing Blow: when a round's last scored hand is a High Card, every
-- unenhanced card scored in a High Card that round gains a random
-- enhancement at round end (PC collects the refs the same way).
SMODS.Joker {
    key = "finishing_blow", rarity = 2, cost = 6,
    loc_txt = { name = "Finishing Blow", text = {
        "If a blind is finished",
        "with a {C:attention}High Card{}, randomly",
        "{C:attention}Enhance{} scored cards",
    } },
    config = { extra = {} },
    sprite = "j_mmc_finishing_blow.png", negative_sprite = "j_mmc_finishing_blow_negative.png",
    blueprint_compat = false,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            card._mmc_high_card = context.scoring_name == "High Card"
            if card._mmc_high_card and not context.blueprint then
                local d = data_of(context.other_card)
                if (d.enhancement == nil or d.enhancement == "none") and not d.no_rank then
                    card._mmc_refs = card._mmc_refs or {}
                    card._mmc_refs[#card._mmc_refs + 1] = context.other_card
                end
            end
        end
        if context.end_of_round and not context.blueprint then
            if card._mmc_high_card and card._mmc_refs then
                for _, view in ipairs(card._mmc_refs) do
                    if view.set_enhancement then
                        view:set_enhancement(SMODS.poll_enhancement())
                    end
                end
            end
            card._mmc_refs = nil
            card._mmc_high_card = nil
        end
    end,
}

-- Aurora Borealis: every held Blue Seal also makes a Negative Planet.
-- PC hangs this on the seal's own end-of-round effect; the port counts the
-- same cards (held, Blue Seal, not debuffed) at round end -- the seal's own
-- Planet is the vanilla one, this is the extra.
SMODS.Joker {
    key = "aurora_borealis", rarity = 1, cost = 6,
    loc_txt = { name = "Aurora Borealis", text = {
        "{C:attention}Blue Seals{} give an",
        "extra {C:dark_edition}negative {C:planet}Planet{} card",
    } },
    config = { extra = {} },
    sprite = "j_mmc_aurora_borealis.png", negative_sprite = "j_mmc_aurora_borealis_negative.png",
    blueprint_compat = false,
    calculate = function(self, card, context)
        note_hand(card, context)
        if context.end_of_round and not context.game_over then
            local n = #held_blue_seals()
            local made = false
            for _ = 1, n do
                if create_planet(ex(card).last_hand, "negative") then made = true end
            end
            if made then return { message = "Aurora!" } end
        end
    end,
}

-- Historical Joker: when a hand repeats the previous hand's ranks in the
-- same order, cut the blind's target by the banked amount (the previous
-- hand's score, capped at 25% of the target).
SMODS.Joker {
    key = "historical", rarity = 3, cost = 9,
    loc_txt = { name = "Historical Joker", text = {
        "If scored cards have the same",
        "{C:attention}ranks{} and {C:attention}order{} as previous",
        "hand, reduce blind requirement",
        "by previous hands {C:chips}Chips{}. Caps at",
        "{C:attention}#1#%{} of current blind's Chips",
    } },
    config = { extra = { percentage = 25, prev_cards = "", current_cards = "" } },
    sprite = "j_mmc_historical.png", negative_sprite = "j_mmc_historical_negative.png",
    blueprint_compat = true,
    loc_vars = function(self, info_queue, card)
        return { vars = { ex(card).percentage } }
    end,
    calculate = function(self, card, context)
        local e = ex(card)
        if context.before and not context.blueprint then
            local ids = {}
            for _, view in ipairs(context.full_hand or {}) do
                ids[#ids + 1] = tostring(view:get_id())
            end
            e.current_cards = table.concat(ids, ",")
        end
        if context.final_scoring_step then
            local total = hand_total(context)
            local cap = blind_target() * e.percentage / 100
            local banked = SMODS.big_cmp(total, cap) > 0 and cap or total
            card._mmc_pending = SMODS.is_big(banked) and banked or math.ceil(banked)
        end
        if context.joker_main and not context.blueprint then
            local pending = card._mmc_pending
            if pending ~= nil and e.prev_cards ~= "" and e.prev_cards == e.current_cards
                and SMODS.big_cmp(pending, 0) > 0 then
                SMODS.adjust_blind_target(-pending)
                return { message = "-" .. tostring(pending) .. " Chips" }
            end
        end
        if context.after and not context.blueprint then
            e.prev_cards = e.current_cards
            e.current_cards = ""
            card._mmc_pending = nil
        end
    end,
}

-- Suit Alley: scored Diamonds and Clubs give +12 Chips; Hearts and Spades
-- give +3 Mult. Wild cards count as both.
SMODS.Joker {
    key = "suit_alley", rarity = 1, cost = 4,
    loc_txt = { name = "Suit Alley", text = {
        "{C:diamonds}Diamond{} and {C:clubs}Club{} cards",
        "gain {C:chips}+#1#{} Chips when scored",
        "{C:hearts}Heart{} and {C:spades}Spade{} cards",
        "gain {C:mult}+#2#{} Mult when scored",
    } },
    config = { extra = { chips = 12, mult = 3 } },
    sprite = "j_mmc_suit_alley.png", negative_sprite = "j_mmc_suit_alley_negative.png",
    blueprint_compat = true,
    loc_vars = function(self, info_queue, card)
        local e = ex(card)
        return { vars = { e.chips, e.mult } }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            local other = context.other_card
            local e = ex(card)
            local ret = {}
            if other:is_suit("Diamonds") or other:is_suit("Clubs") then
                ret.chips = e.chips
            end
            if other:is_suit("Hearts") or other:is_suit("Spades") then
                ret.mult = e.mult
            end
            if ret.chips or ret.mult then return ret end
        end
    end,
}

-- The Printer: a hand that beats the blind's whole requirement duplicates
-- every played card into the deck.
SMODS.Joker {
    key = "printer", rarity = 3, cost = 9,
    loc_txt = { name = "The Printer", text = {
        "If hand scores more than",
        "blind's Chips, {C:attention}duplicate{}",
        "played cards",
    } },
    config = { extra = {} },
    sprite = "j_mmc_printer.png", negative_sprite = "j_mmc_printer_negative.png",
    blueprint_compat = false,
    calculate = function(self, card, context)
        if context.before then
            card._mmc_saved = context.full_hand
        end
        if context.final_scoring_step then
            if SMODS.big_cmp(hand_total(context), blind_target()) >= 0
                and card._mmc_saved then
                for _, view in ipairs(card._mmc_saved) do
                    local d = data_of(view)
                    SMODS.add_card {
                        set = "Playing", rank = d.rank, suit = d.suit,
                        enhancement = d.enhancement, seal = d.seal,
                        edition = edition_of(d), area = "deck",
                    }
                end
                return { message = "Printed!" }
            end
        end
        if context.after then card._mmc_saved = nil end
    end,
}

-- Training Wheels: X1 Mult, +X0.1 per 10 cards scored.
SMODS.Joker {
    key = "training_wheels", rarity = 2, cost = 6,
    loc_txt = { name = "Training Wheels", text = {
        "{X:mult,C:white}X#1#{} Mult, gains {X:mult,C:white}X#2#{}",
        "Mult per {C:attention}#4# cards{} scored",
        "{C:inactive}Currently {C:attention}#3# {C:inactive}cards scored",
    } },
    config = { extra = { current_x_mult = 1, x_mult_mod = 0.1, card_count = 0, req = 10 } },
    sprite = "j_mmc_training_wheels.png", negative_sprite = "j_mmc_training_wheels_negative.png",
    blueprint_compat = true,
    loc_vars = function(self, info_queue, card)
        local e = ex(card)
        return { vars = { e.current_x_mult, e.x_mult_mod, e.card_count, e.req } }
    end,
    calculate = function(self, card, context)
        local e = ex(card)
        if context.individual and context.cardarea == G.play and not context.blueprint then
            e.card_count = e.card_count + 1
            if e.card_count >= e.req then
                e.card_count = 0
                e.current_x_mult = e.current_x_mult + e.x_mult_mod
                return { message = "X" .. e.current_x_mult .. " Mult" }
            end
        end
        if context.joker_main and e.current_x_mult > 1 then
            return { x_mult = e.current_x_mult }
        end
    end,
}

-- Horseshoe: retrigger all scored Lucky cards once.
SMODS.Joker {
    key = "horseshoe", rarity = 2, cost = 6,
    loc_txt = { name = "Horseshoe", text = {
        "Retrigger all",
        "scored {C:attention}Lucky{} cards",
    } },
    config = { extra = { repetitions = 1 } },
    sprite = "j_mmc_horseshoe.png", negative_sprite = "j_mmc_horseshoe_negative.png",
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.repetition and context.cardarea == G.play
            and data_of(context.other_card).enhancement == "lucky" then
            return { repetitions = ex(card).repetitions, message = "Again!" }
        end
    end,
}

-- Incomplete Joker: +100 Chips on hands of 3 or fewer cards.
SMODS.Joker {
    key = "incomplete", rarity = 1, cost = 4,
    loc_txt = { name = "Incomplete Joker", text = {
        "{C:chips}+#1#{} Chips if played",
        "hand contains",
        "{C:attention}#2#{} or fewer cards",
    } },
    config = { extra = { chips = 100, req = 3 } },
    sprite = "j_mmc_incomplete.png", negative_sprite = "j_mmc_incomplete_negative.png",
    blueprint_compat = true,
    loc_vars = function(self, info_queue, card)
        local e = ex(card)
        return { vars = { e.chips, e.req } }
    end,
    calculate = function(self, card, context)
        if context.joker_main and context.full_hand
            and #context.full_hand <= ex(card).req then
            return { chips = ex(card).chips }
        end
    end,
}

-- Abbey Road: X4 Mult once at least 5 poker hands have been played the same
-- number of times (checked after each hand, so it lands on the next one,
-- as on PC).
SMODS.Joker {
    key = "abbey_road", rarity = 2, cost = 6,
    loc_txt = { name = "Abbey Road", text = {
        "If at least {C:attention}#2#{} poker hands",
        "have been played the same",
        "amount of times, give {X:mult,C:white}X#1#{} Mult",
    } },
    config = { extra = { x_mult = 4, req = 5, triggered = false } },
    sprite = "j_mmc_abbey_road.png", negative_sprite = "j_mmc_abbey_road_negative.png",
    blueprint_compat = true,
    loc_vars = function(self, info_queue, card)
        local e = ex(card)
        return { vars = { e.x_mult, e.req } }
    end,
    calculate = function(self, card, context)
        local e = ex(card)
        if context.joker_main and e.triggered then
            return { x_mult = e.x_mult }
        end
        if context.after and G and G.handlist and G.hand_play_counts then
            local by_count = {}
            for i in ipairs(G.handlist) do
                local c = tonumber(G.hand_play_counts[i]) or 0
                if c > 0 then by_count[c] = (by_count[c] or 0) + 1 end
            end
            e.triggered = false
            for _, n in pairs(by_count) do
                if n >= e.req then e.triggered = true break end
            end
        end
    end,
}

-- Fishing License: copies the scoring effect of every scored enhanced card.
SMODS.Joker {
    key = "fishing_license", rarity = 3, cost = 8,
    loc_txt = { name = "Fishing License", text = {
        "{C:attention}Copies{} effects of all",
        "scored {C:attention}Enhanced{} cards",
    } },
    config = { extra = {} },
    sprite = "j_mmc_fishing_license.png", negative_sprite = "j_mmc_fishing_license_negative.png",
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            local d = data_of(context.other_card)
            local enh = d.enhancement
            if enh == "bonus" then
                return { chips = 30 }
            elseif enh == "stone" then
                return { chips = 50 }
            elseif enh == "mult" then
                return { mult = 4 }
            elseif enh == "glass" then
                return { x_mult = 2 }
            elseif enh == "lucky" then
                -- No roll identifier: these are the License's own copies, not
                -- the card's triggers, so Blue Moon and Rigged must not count
                -- them (on PC they key off the card, and never see these).
                local ret = {}
                if SMODS.pseudorandom_probability(card, "mmc_fishing_mult", 1, 5) then
                    ret.mult = 20
                end
                if SMODS.pseudorandom_probability(card, "mmc_fishing_money", 1, 15) then
                    ret.dollars = 20
                end
                if ret.mult or ret.dollars then return ret end
            end
        end
    end,
}

-- Gold Bar: $2 per Gold card and per Gold Seal in the full deck, at round end.
SMODS.Joker {
    key = "gold_bar", rarity = 1, cost = 5,
    loc_txt = { name = "Gold Bar", text = {
        "Earn {C:money}$#1#{} for every",
        "{C:attention}Gold Seal{} and {C:attention}Gold card{}",
        "at end of round",
    } },
    config = { extra = { dollars = 2 } },
    sprite = "j_mmc_gold_bar.png", negative_sprite = "j_mmc_gold_bar_negative.png",
    blueprint_compat = true,
    loc_vars = function(self, info_queue, card)
        return { vars = { ex(card).dollars } }
    end,
    calc_dollar_bonus = function(self, card)
        local gold_cards = full_deck_count(function(c)
            return data_of(c).enhancement == "gold"
        end)
        local gold_seals = full_deck_count(function(c)
            return data_of(c).seal == "gold"
        end)
        return (gold_cards + gold_seals) * ex(card).dollars
    end,
}

-- Rigged Joker: once per round, the first Lucky card that fails both its
-- rolls adds +1 to every listed probability until round end.
SMODS.Joker {
    key = "rigged", rarity = 1, cost = 5,
    loc_txt = { name = "Rigged Joker", text = {
        "Once per hand, add {C:attention}+#1#{} to all",
        "listed {C:green}probabilities{} whenever a",
        "{C:attention}Lucky{} card does not trigger",
        "Resets every round",
    } },
    config = { extra = { bonus = 0, increase = 1, whiffed = false } },
    sprite = "j_mmc_rigged.png", negative_sprite = "j_mmc_rigged_negative.png",
    blueprint_compat = true,
    loc_vars = function(self, info_queue, card)
        return { vars = { ex(card).increase } }
    end,
    calculate = function(self, card, context)
        local e = ex(card)
        if context.pseudorandom_result
            and (context.identifier == "lucky_mult" or context.identifier == "lucky_money") then
            if context.identifier == "lucky_mult" then
                card._mmc_lucky_whiff = context.result == false
            elseif card._mmc_lucky_whiff and context.result == false then
                e.whiffed = true
            end
            if context.result then card._mmc_lucky_whiff = false end
        end
        if context.mod_probability and e.bonus > 0 then
            return { numerator = context.numerator + e.bonus,
                denominator = context.denominator }
        end
        if context.joker_main and e.whiffed and e.bonus == 0 and not context.blueprint then
            e.bonus = e.bonus + e.increase
            return { message = "Rigged!" }
        end
        if context.after then e.whiffed = false end
        if context.end_of_round then
            e.bonus = 0
            e.whiffed = false
            card._mmc_lucky_whiff = false
        end
    end,
}

-- The Commander: a lone first-hand card gains a random Enhancement, Seal
-- and Edition (each only if it lacks one).
SMODS.Joker {
    key = "commander", rarity = 3, cost = 9,
    loc_txt = { name = "The Commander", text = {
        "If {C:attention}first hand{} of round",
        "has only {C:attention}#1#{} card, give it a",
        "random {C:attention}Enhancement{}, {C:attention}Seal",
        "and {C:attention}Edition{}",
    } },
    config = { extra = { req = 1 } },
    sprite = "j_mmc_commander.png", negative_sprite = "j_mmc_commander_negative.png",
    blueprint_compat = false,
    loc_vars = function(self, info_queue, card)
        return { vars = { ex(card).req } }
    end,
    calculate = function(self, card, context)
        if context.before and G and G.get_round_hands_played
            and G:get_round_hands_played() == 0
            and context.full_hand and #context.full_hand == ex(card).req then
            for _, view in ipairs(context.full_hand) do
                local d = data_of(view)
                if view.set_seal and (d.seal == nil or d.seal == "none") then
                    view:set_seal(SMODS.poll_seal())
                end
                if view.set_enhancement
                    and (d.enhancement == nil or d.enhancement == "none") then
                    view:set_enhancement(SMODS.poll_enhancement())
                end
                if not edition_of(d) then
                    d.modifier = d.modifier or {}
                    d.modifier.edition = roll_edition("mmc_commander", false)
                    if view.sync_visual_from_card_data then
                        view:sync_visual_from_card_data()
                    end
                end
            end
            return { message = "Upgraded!" }
        end
    end,
}

-- Blue Moon: 3 Lucky triggers in one hand create a random Negative Joker.
SMODS.Joker {
    key = "blue_moon", rarity = 2, cost = 8,
    loc_txt = { name = "Blue Moon", text = {
        "If {C:attention}#1# Lucky cards{} trigger",
        "in one hand, create a",
        "random {C:dark_edition}negative{} Joker",
    } },
    config = { extra = { req = 3, lucky_tally = 0 } },
    sprite = "j_mmc_blue_moon.png", negative_sprite = "j_mmc_blue_moon_negative.png",
    blueprint_compat = true,
    loc_vars = function(self, info_queue, card)
        return { vars = { ex(card).req } }
    end,
    calculate = function(self, card, context)
        local e = ex(card)
        if context.probability_success
            and (context.identifier == "lucky_mult" or context.identifier == "lucky_money") then
            e.lucky_tally = e.lucky_tally + 1
            return { repetitions = 0 }
        end
        if context.joker_main then
            if e.lucky_tally >= e.req then
                if create_random_joker("negative") then
                    return { message = "Blue Moon!" }
                end
            else
                return { message = "Nope!" }
            end
        end
        if context.after then e.lucky_tally = 0 end
    end,
}

--------------------------------------------------------------------------------
-- Helpers for the second half of the roster
--------------------------------------------------------------------------------

--- A held Joker's numeric rarity (1 Common .. 4 Legendary), however the
--- def stored it.
local function joker_rarity(j)
    local r = tonumber(j and j.def and j.def.rarity) or tonumber(j and j.rarity)
    if not r then
        r = ({ common = 1, uncommon = 2, rare = 3, legendary = 4 })[j and j.rarity] or 1
    end
    return r
end

local function view_debuffed(view)
    if view and view.is_debuffed then return view:is_debuffed() end
    return data_of(view).debuffed == true
end

-- Glue: X5 Mult and +2 Joker slots while both Half Joker and this mod's
-- Incomplete Joker are held. PC maintains the flags (and the slot grant) in
-- the global add/remove hooks; the port recomputes the held set whenever it
-- can change and drives the slots through the dynamic `joker_slots` field.
SMODS.Joker {
    key = "glue", rarity = 1, cost = 5,
    loc_txt = { name = "Glue", text = {
        "If you have both {C:attention}Half",
        "and {C:attention}Incomplete Joker{}, give",
        "{C:dark_edition}+#2#{} Joker slots and {X:mult,C:white}X#1#{} Mult",
    } },
    config = { extra = { x_mult = 5, j_slots = 2 }, joker_slots = 0 },
    sprite = "j_mmc_glue.png", negative_sprite = "j_mmc_glue_negative.png",
    blueprint_compat = true,
    loc_vars = function(self, info_queue, card)
        local e = ex(card)
        return { vars = { e.x_mult, e.j_slots } }
    end,
    calculate = function(self, card, context)
        local e = ex(card)
        if context.card_added or context.selling_card or context.joker_type_destroyed
            or context.before or context.joker_main then
            local both = find_joker("j_half") ~= nil and find_joker("j_mmc_incomplete") ~= nil
            card.ability.joker_slots = both and e.j_slots or 0
            e.triggered = both
        end
        if context.joker_main and e.triggered then
            return { x_mult = e.x_mult }
        end
    end,
    add_to_deck = function(self, card)
        local both = find_joker("j_half") ~= nil and find_joker("j_mmc_incomplete") ~= nil
        card.ability.joker_slots = both and ex(card).j_slots or 0
        ex(card).triggered = both
    end,
    remove_from_deck = function(self, card)
        card.ability.joker_slots = 0
        ex(card).triggered = false
    end,
}

-- Harp Seal: doubles every seal. Scored Gold Seals pay $3, Red Seals
-- retrigger (in play and in hand), discarded Purple Seals make a random
-- Tarot, and each held Blue Seal makes an extra Planet at round end (plus
-- an extra Negative one when Aurora Borealis rides the same seal). PC pays
-- the Gold money twice (an ease_dollars plus a dollars return); the port
-- pays once, like Scratch Card.
SMODS.Joker {
    key = "harp_seal", rarity = 2, cost = 6,
    loc_txt = { name = "Harp Seal", text = {
        "{C:attention}Doubles{} the effect",
        "of all {C:attention}Seals",
    } },
    config = { extra = {} },
    sprite = "j_mmc_harp_seal.png", negative_sprite = "j_mmc_harp_seal_negative.png",
    blueprint_compat = false,
    calculate = function(self, card, context)
        note_hand(card, context)
        if context.end_of_round and not context.game_over then
            local n = #held_blue_seals()
            local aurora = find_joker("j_mmc_aurora_borealis") ~= nil
            local made = false
            for _ = 1, n do
                if create_planet(ex(card).last_hand) then made = true end
                if aurora and create_planet(ex(card).last_hand, "negative") then made = true end
            end
            if made then return { message = "Harp!" } end
            return
        end
        local other = context.other_card
        if not other then return end
        local seal = data_of(other).seal
        if view_debuffed(other) then return end
        if context.individual and context.cardarea == G.play then
            if seal == "gold" then
                return { dollars = 3 }
            end
        end
        if context.repetition and seal == "red" then
            if context.cardarea == G.play or context.cardarea == G.hand then
                return { repetitions = 1 }
            end
        end
        if context.discard and seal == "purple" then
            if create_random_tarot() then
                return { message = "Tarot!" }
            end
        end
    end,
}

-- Football Card: every Common Joker that triggers adds +50 Chips.
SMODS.Joker {
    key = "football_card", rarity = 2, cost = 7,
    loc_txt = { name = "Football Card", text = {
        "{C:blue}Common{} Jokers",
        "each give {C:chips}+#1#{} Chips",
    } },
    config = { extra = { chips = 50 } },
    sprite = "j_mmc_football_card.png", negative_sprite = "j_mmc_football_card_negative.png",
    blueprint_compat = true,
    loc_vars = function(self, info_queue, card)
        return { vars = { ex(card).chips } }
    end,
    calculate = function(self, card, context)
        if context.post_trigger and context.other_card and context.other_card ~= card then
            if joker_rarity(context.other_card) == 1 then
                return { chips = ex(card).chips }
            end
        end
    end,
}

-- Special Edition Joker: the whole deck is its scaling source -- +2 Mult
-- per Seal, +10 Chips per Enhancement, X0.1 Mult per Edition, counted on
-- demand where PC recounted every frame.
SMODS.Joker {
    key = "special_edition", rarity = 2, cost = 6,
    loc_txt = { name = "Special Edition Joker", text = {
        "Gains {C:mult}+#2#{} Mult per {C:attention}Seal{}, {C:chips}+#4#{}",
        "Chips per {C:attention}Enhancement{} and {X:mult,C:white}X#6#{} Mult",
        "per {C:attention}Edition{} for every card in deck",
        "{C:inactive}(Currently {C:mult}+#1#{C:inactive} Mult, {C:chips}+#3#{C:inactive} Chips and {X:mult,C:white}X#5#{C:inactive} Mult)",
    } },
    config = { extra = {
        current_mult = 0, mult_mod = 2, current_chips = 0, chip_mod = 10,
        current_x_mult = 1, x_mult_mod = 0.1,
    } },
    sprite = "j_mmc_special_edition.png", negative_sprite = "j_mmc_special_edition_negative.png",
    blueprint_compat = true,
    loc_vars = function(self, info_queue, card)
        local e = ex(card)
        return { vars = { e.current_mult, e.mult_mod, e.current_chips,
            e.chip_mod, e.current_x_mult, e.x_mult_mod } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            local e = ex(card)
            local seals = full_deck_count(function(c) return data_of(c).seal ~= nil end)
            local enhanced = full_deck_count(function(c)
                local enh = data_of(c).enhancement
                return enh ~= nil and enh ~= "none"
            end)
            local editions = full_deck_count(function(c) return edition_of(data_of(c)) ~= nil end)
            e.current_mult = seals * e.mult_mod
            e.current_chips = enhanced * e.chip_mod
            e.current_x_mult = 1 + editions * e.x_mult_mod
            if e.current_mult > 0 or e.current_chips > 0 or e.current_x_mult > 1 then
                return { mult = e.current_mult, chips = e.current_chips, x_mult = e.current_x_mult }
            end
        end
    end,
}

-- The Stockpiler: +1 hand size per 4 cards above 52 in the deck, capped at
-- the current Ante. The dynamic `h_size` field carries it, recomputed
-- whenever the deck or the Ante can have changed.
SMODS.Joker {
    key = "stockpiler", rarity = 1, cost = 4,
    loc_txt = { name = "The Stockpiler", text = {
        "{C:attention}+#2#{} hand size for every #4#",
        "cards in deck above {C:attention}#3#{}",
        "Caps at the current Ante",
        "{C:inactive}(Currently {C:attention}+#1#{C:inactive} hand size)",
    } },
    config = { extra = { current_h_size = 0, h_mod = 1, base = 52, every = 4 }, h_size = 0 },
    sprite = "j_mmc_stockpiler.png", negative_sprite = "j_mmc_stockpiler_negative.png",
    blueprint_compat = false,
    loc_vars = function(self, info_queue, card)
        local e = ex(card)
        return { vars = { e.current_h_size, e.h_mod, e.base, e.every } }
    end,
    calculate = function(self, card, context)
        if context.repetition and not context.individual then return end
        local e = ex(card)
        local total = full_deck_count(function() return true end)
        local bonus = 0
        if total > e.base then
            bonus = math.floor((total - e.base) / e.every) * e.h_mod
            bonus = math.min(bonus, tonumber(G and G.ante) or 1)
        end
        if bonus ~= e.current_h_size then
            e.current_h_size = bonus
            card.ability.h_size = bonus
            return { message = bonus > 0 and "Stocked!" or nil }
        end
    end,
    remove_from_deck = function(self, card)
        card.ability.h_size = 0
        ex(card).current_h_size = 0
    end,
}

-- Student Loans: spend up to -$100 (the `debt_limit` config), and lose a
-- discard for every $25 of debt, PC's floor rounding kept (at -$30 the
-- second discard is already gone).
SMODS.Joker {
    key = "student_loans", rarity = 2, cost = 4,
    loc_txt = { name = "Student Loans", text = {
        "Go up to {C:red}-$#1#{} in debt",
        "Gives -#4# {C:red}discard{}",
        "for every {C:red}-$#2#{} in debt",
        "{C:inactive}(Currently {C:attention}#3#{C:inactive} discards)",
    } },
    config = { extra = { negative_bal = 100, every = 25, discards = 0, discard_sub = 1 },
        debt_limit = 100, d_size = 0 },
    sprite = "j_mmc_student_loans.png", negative_sprite = "j_mmc_student_loans_negative.png",
    blueprint_compat = false,
    loc_vars = function(self, info_queue, card)
        local e = ex(card)
        return { vars = { e.negative_bal, e.every, e.discards, e.discard_sub } }
    end,
    calculate = function(self, card, context)
        if context.money_altered or context.joker_main or context.end_of_round then
            local e = ex(card)
            local money = tonumber(G and G.money) or 0
            local penalty = 0
            if money < 0 then
                penalty = math.floor(money / e.every) * e.discard_sub
            end
            card.ability.d_size = penalty
            e.discards = -penalty
        end
    end,
    remove_from_deck = function(self, card)
        card.ability.d_size = 0
        ex(card).discards = 0
    end,
}

-- Broke Joker: +1 Mult per -$2 of balance, counted on demand (PC's
-- per-frame update used the same rounded-down debt steps).
SMODS.Joker {
    key = "broke", rarity = 1, cost = 2,
    loc_txt = { name = "Broke Joker", text = {
        "Gains {C:mult}+#1#{} Mult",
        "per {C:red}-$#3#",
        "{C:inactive}(Currently {C:mult}+#2#{C:inactive} Mult)",
    } },
    config = { extra = { current_mult = 0, mult_mod = 1, every = 2 } },
    sprite = "j_mmc_broke.png", negative_sprite = "j_mmc_broke_negative.png",
    blueprint_compat = true,
    loc_vars = function(self, info_queue, card)
        local e = ex(card)
        return { vars = { e.mult_mod, e.current_mult, e.every } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            local e = ex(card)
            local money = tonumber(G and G.money) or 0
            e.current_mult = money < 0 and math.floor(-money / e.every) * e.mult_mod or 0
            if e.current_mult > 0 then
                return { mult = e.current_mult }
            end
        end
    end,
}

-- Go For Broke: +4 Chips per -$1 of balance.
SMODS.Joker {
    key = "go_for_broke", rarity = 1, cost = 4,
    loc_txt = { name = "Go For Broke", text = {
        "Gains {C:chips}+#1#{} Chips",
        "per {C:red}-$#3#",
        "{C:inactive}(Currently {C:chips}+#2#{C:inactive} Chips)",
    } },
    config = { extra = { current_chips = 0, every = 1, chip_mod = 4 } },
    sprite = "j_mmc_go_for_broke.png", negative_sprite = "j_mmc_go_for_broke_negative.png",
    blueprint_compat = true,
    loc_vars = function(self, info_queue, card)
        local e = ex(card)
        return { vars = { e.chip_mod, e.current_chips, e.every } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            local e = ex(card)
            local money = tonumber(G and G.money) or 0
            e.current_chips = money < 0 and math.floor(-money / e.every) * e.chip_mod or 0
            if e.current_chips > 0 then
                return { chips = e.current_chips }
            end
        end
    end,
}

-- Street Fighter: X4 Mult while the balance is at or below -$20.
SMODS.Joker {
    key = "street_fighter", rarity = 2, cost = 7,
    loc_txt = { name = "Street Fighter", text = {
        "Gives {X:mult,C:white}X#1#{} Mult",
        "when balance is",
        "at or below {C:red}-$#2#",
    } },
    config = { extra = { x_mult = 4, req = 20 } },
    sprite = "j_mmc_street_fighter.png", negative_sprite = "j_mmc_street_fighter_negative.png",
    blueprint_compat = true,
    loc_vars = function(self, info_queue, card)
        local e = ex(card)
        return { vars = { e.x_mult, e.req } }
    end,
    calculate = function(self, card, context)
        if context.joker_main and (tonumber(G and G.money) or 0) <= -ex(card).req then
            return { x_mult = ex(card).x_mult }
        end
    end,
}

-- Checklist: playing the named hand levels it up; the named hand is picked
-- at creation (PC's set_ability roll, never the hand it replaces) and
-- re-picked at round end. The fork has no hand-visibility flag, so the
-- pool is the whole hand list, as in the Jimball precedent.
SMODS.Joker {
    key = "checklist", rarity = 2, cost = 7,
    loc_txt = { name = "Checklist", text = {
        "Playing {C:attention}#1#{} upgrades",
        "it by #2# level,",
        "poker hand changes",
        "at end of round",
    } },
    config = { extra = { poker_hand = "High Card", increase = 1 } },
    sprite = "j_mmc_checklist.png", negative_sprite = "j_mmc_checklist_negative.png",
    blueprint_compat = true,
    loc_vars = function(self, info_queue, card)
        local e = ex(card)
        return { vars = { e.poker_hand, e.increase } }
    end,
    set_ability = function(self, card, initial)
        if not (G and G.handlist) then return end
        local e = ex(card)
        local pool = {}
        for _, name in ipairs(G.handlist) do
            if name ~= e.poker_hand then pool[#pool + 1] = name end
        end
        if #pool > 0 then
            e.poker_hand = SMODS.pseudorandom_element(pool, "mmc_checklist")
        end
    end,
    calculate = function(self, card, context)
        local e = ex(card)
        if context.before and context.scoring_name == e.poker_hand then
            return { level_up = e.increase, message = "Upgrade!" }
        end
        if context.end_of_round and not context.blueprint and G and G.handlist then
            local pool = {}
            for _, name in ipairs(G.handlist) do
                if name ~= e.poker_hand then pool[#pool + 1] = name end
            end
            if #pool > 0 then
                e.poker_hand = SMODS.pseudorandom_element(pool, "mmc_checklist")
                return { message = "Reset" }
            end
        end
    end,
}

-- One Of Us: a hand with at least 5 Enhanced cards gives a random
-- editionless held Joker a random edition.
SMODS.Joker {
    key = "one_of_us", rarity = 2, cost = 6,
    loc_txt = { name = "One Of Us", text = {
        "If played hand",
        "contains {C:attention}#1# Enhanced cards,",
        "give a random Joker",
        "a random {C:attention}Edition",
    } },
    config = { extra = { req = 5 } },
    sprite = "j_mmc_one_of_us.png", negative_sprite = "j_mmc_one_of_us_negative.png",
    blueprint_compat = false,
    loc_vars = function(self, info_queue, card)
        return { vars = { ex(card).req } }
    end,
    calculate = function(self, card, context)
        if context.joker_main and not context.blueprint and context.full_hand then
            local tally = 0
            for _, view in ipairs(context.full_hand) do
                local enh = data_of(view).enhancement
                if enh ~= nil and enh ~= "none" then tally = tally + 1 end
            end
            if tally >= ex(card).req then
                local editionless = {}
                for _, j in ipairs(jokers()) do
                    if j.edition == nil or j.edition == "base" then
                        editionless[#editionless + 1] = j
                    end
                end
                if #editionless > 0 then
                    local target = SMODS.pseudorandom_element(editionless, "mmc_one_of_us")
                    set_joker_edition(target, roll_edition("mmc_one_of_us", true))
                    return { message = "Upgrade!" }
                end
            end
        end
    end,
}

-- The Investor: $5 at round end, with a 1-in-4 chance it takes $5 instead.
-- PC both eased and returned the dollars; the port pays once.
SMODS.Joker {
    key = "investor", rarity = 1, cost = 4,
    loc_txt = { name = "The Investor", text = {
        "Gives {C:money}$#1#{} at end of",
        "round. {C:green}#3# in #2#{} chance to",
        "give {C:red}-$#1#{} instead",
    } },
    config = { extra = { dollars = 5, odds = 4 } },
    sprite = "j_mmc_investor.png", negative_sprite = "j_mmc_investor_negative.png",
    blueprint_compat = true,
    loc_vars = function(self, info_queue, card)
        local e = ex(card)
        local num, den = SMODS.get_probability_vars(card, 1, e.odds, "mmc_investor")
        return { vars = { e.dollars, den, num } }
    end,
    calculate = function(self, card, context)
        if context.end_of_round then
            local e = ex(card)
            local bad = SMODS.pseudorandom_probability(card, "mmc_investor", 1, e.odds, "mmc_investor")
            local amount = bad and -e.dollars or e.dollars
            if G and G.ease_dollars then G:ease_dollars(amount) end
            return { message = (amount >= 0 and "$" or "-$") .. math.abs(amount) }
        end
    end,
}

-- Mountain Climber: every scored card permanently gains +1 Mult. PC writes
-- its own perma_mult field behind a Lovely display patch; the fork reads
-- `perma_mult` natively, so the write is the whole port.
SMODS.Joker {
    key = "mountain_climber", rarity = 2, cost = 7,
    loc_txt = { name = "Mountain Climber", text = {
        "Every played {C:attention}card{}",
        "permanently gains",
        "{C:mult}+#1#{} Mult when scored",
    } },
    config = { extra = { mult = 1 } },
    sprite = "j_mmc_mountain_climber.png", negative_sprite = "j_mmc_mountain_climber_negative.png",
    blueprint_compat = true,
    loc_vars = function(self, info_queue, card)
        return { vars = { ex(card).mult } }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play and context.other_card then
            local other = context.other_card
            SMODS.set_perma(other, "perma_mult",
                (SMODS.get_perma(other, "perma_mult") or 0) + ex(card).mult)
            return { message = "Upgrade!" }
        end
    end,
}

-- Shackles: +1 hand, +1 discard, +1 hand size while held -- and destroyed
-- if a hand ever plays more than 4 cards. PC hand-rolled the stats in the
-- add/remove hooks; the fork's declarative modifiers are the same numbers.
SMODS.Joker {
    key = "shackles", rarity = 1, cost = 5,
    loc_txt = { name = "Shackles", text = {
        "{C:blue}+#1#{} hand, {C:red}+#2#{} discard,",
        "{C:attention}+#3#{} hand size. Destroyed",
        "if you play more than",
        "{C:attention}#4#{} cards in one hand",
    } },
    config = { extra = { req = 4 }, hands = 1, d_size = 1, h_size = 1 },
    sprite = "j_mmc_shackles.png", negative_sprite = "j_mmc_shackles_negative.png",
    blueprint_compat = false, eternal_compat = false,
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.hands, card.ability.d_size,
            card.ability.h_size, ex(card).req } }
    end,
    calculate = function(self, card, context)
        if context.joker_main and context.full_hand
            and #context.full_hand > ex(card).req then
            card._mmc_shatter = true
        end
        if context.after and card._mmc_shatter then
            card._mmc_shatter = nil
            SMODS.destroy_joker(card)
            return { message = "Shattered!" }
        end
    end,
}

-- Buy One Get One: a 1-in-4 chance, whenever you buy a card, to get a
-- random extra card of the same kind. PC's create_card(type) becomes a
-- per-kind pool roll here, since the fork's add_card wants an explicit key.
SMODS.Joker {
    key = "buy_one_get_one", rarity = 1, cost = 5,
    loc_txt = { name = "Buy One Get One", text = {
        "{C:green}#2# in #1#{} chance to",
        "get a random {C:attention}extra card{}",
        "of whatever you're buying",
        "{C:inactive}(Must have room)",
    } },
    config = { extra = { odds = 4 } },
    sprite = "j_mmc_buy_one_get_one.png", negative_sprite = "j_mmc_buy_one_get_one_negative.png",
    blueprint_compat = true,
    loc_vars = function(self, info_queue, card)
        local e = ex(card)
        local num, den = SMODS.get_probability_vars(card, 1, e.odds, "mmc_buy_one_get_one")
        return { vars = { den, num } }
    end,
    calculate = function(self, card, context)
        if context.buying_card and not context.blueprint then
            local kind = (context.port or {}).offer_kind
            if kind ~= "joker" and kind ~= "tarot" and kind ~= "spectral"
                and kind ~= "planet" and kind ~= "playing_card" then
                return
            end
            local hit = SMODS.pseudorandom_probability(card, "mmc_buy_one_get_one",
                1, ex(card).odds, "mmc_buy_one_get_one")
            if not hit then return { message = "Nope!" } end
            local made = nil
            if kind == "joker" then
                made = create_random_joker(nil)
            elseif kind == "tarot" then
                made = create_random_tarot()
            elseif kind == "spectral" and G and G.random_consumable_id_of_kind then
                local id = G:random_consumable_id_of_kind("spectral")
                if id then made = SMODS.add_card { set = "Spectral", key = id } end
            elseif kind == "planet" and G and G.handlist then
                local hand = SMODS.pseudorandom_element(G.handlist, "mmc_bogo_planet")
                made = create_planet(hand)
            elseif kind == "playing_card" then
                local suits = { "Spades", "Hearts", "Clubs", "Diamonds" }
                made = SMODS.add_card { set = "Playing",
                    rank = SMODS.pseudorandom("mmc_bogo_rank", 2, 14),
                    suit = SMODS.pseudorandom_element(suits, "mmc_bogo_suit"),
                    area = "deck" }
            end
            if made then return { message = "Free!" } end
        end
    end,
}

-- Pack A Punch: when a Blind is selected, pay $20 to give the left-most
-- Joker a random edition, replacing its current one. If stripping a
-- Negative pushes the Joker count over the limit, Pack A Punch itself is
-- destroyed, exactly as PC's dissolve did.
SMODS.Joker {
    key = "pack_a_punch", rarity = 3, cost = 10,
    loc_txt = { name = "Pack A Punch", text = {
        "When {C:attention}Blind{} is selected,",
        "lose {C:money}$#1#{} and give the",
        "{C:attention}left-most{} Joker",
        "a random {C:attention}Edition",
        "{C:inactive}(Will replace current edition)",
    } },
    config = { extra = { dollars = 20 } },
    sprite = "j_mmc_pack_a_punch.png", negative_sprite = "j_mmc_pack_a_punch_negative.png",
    blueprint_compat = false,
    loc_vars = function(self, info_queue, card)
        return { vars = { ex(card).dollars } }
    end,
    calculate = function(self, card, context)
        if context.setting_blind and not context.blueprint then
            local target = jokers()[1]
            if target then
                if G and G.ease_dollars then G:ease_dollars(-ex(card).dollars) end
                set_joker_edition(target, roll_edition("mmc_pack_a_punch", true))
                local capacity = G and G.joker_capacity
                if capacity and #jokers() > capacity then
                    SMODS.destroy_joker(card)
                end
                return { message = "Upgrade!" }
            end
        end
    end,
}

-- Seal Steal: scored Purple Seals make a random Tarot, scored Blue Seals
-- make a Planet for the last hand played -- and Harp Seal / Aurora
-- Borealis held alongside double their parts, as on PC.
SMODS.Joker {
    key = "seal_steal", rarity = 1, cost = 5,
    loc_txt = { name = "Seal Steal", text = {
        "Played {C:purple}Purple{} and",
        "{C:blue}Blue{} Seals trigger",
        "when {C:attention}scored",
    } },
    config = { extra = {} },
    sprite = "j_mmc_seal_steal.png", negative_sprite = "j_mmc_seal_steal_negative.png",
    blueprint_compat = false,
    calculate = function(self, card, context)
        note_hand(card, context)
        if context.individual and context.cardarea == G.play and context.other_card then
            local other = context.other_card
            if view_debuffed(other) then return end
            local seal = data_of(other).seal
            local harp = find_joker("j_mmc_harp_seal") ~= nil
            if seal == "purple" then
                local made = create_random_tarot() ~= nil
                if harp then made = create_random_tarot() ~= nil or made end
                if made then return { message = "Tarot!" } end
            elseif seal == "blue" then
                local aurora = find_joker("j_mmc_aurora_borealis") ~= nil
                local hand = ex(card).last_hand
                local made = create_planet(hand) ~= nil
                if aurora then made = create_planet(hand, "negative") ~= nil or made end
                if harp then
                    made = create_planet(hand) ~= nil or made
                    if aurora then made = create_planet(hand, "negative") ~= nil or made end
                end
                if made then return { message = "Planet!" } end
            end
        end
    end,
}

-- Tax Collector: at round end, $1 per Uncommon, $2 per Rare and $4 per
-- Legendary Joker held. PC paid per Joker in a loop of events; the payout
-- lands in one calc_dollar_bonus sum here.
SMODS.Joker {
    key = "tax_collector", rarity = 1, cost = 4,
    loc_txt = { name = "Tax Collector", text = {
        "Gives {C:green}$#1#{}, {C:red}$#2#{} or {C:legendary}$#3#",
        "per Joker with the",
        "respective {C:attention}rarity",
        "at end of round",
    } },
    config = { extra = { dollars = 1 } },
    sprite = "j_mmc_tax_collector.png", negative_sprite = "j_mmc_tax_collector_negative.png",
    blueprint_compat = true,
    loc_vars = function(self, info_queue, card)
        local d = ex(card).dollars
        return { vars = { d, d * 2, d * 4 } }
    end,
    calc_dollar_bonus = function(self, card)
        local total = 0
        for _, j in ipairs(jokers()) do
            if j ~= card then
                local r = joker_rarity(j)
                if r > 1 then
                    total = total + ex(card).dollars * (r - 1) + (r == 4 and 1 or 0)
                end
            end
        end
        return total
    end,
}

-- Glass Cannon: retrigger every scored Glass card, then destroy the ones
-- that scored. PC marked them in `individual` and shattered them after
-- the hand; the port destroys the marked views at `after`.
SMODS.Joker {
    key = "glass_cannon", rarity = 2, cost = 7,
    loc_txt = { name = "Glass Cannon", text = {
        "{C:attention}Retrigger{} all {C:attention}Glass",
        "{C:attention}Cards{}, but they are",
        "{C:red}guaranteed{} to break",
    } },
    config = { extra = { repetitions = 1 } },
    sprite = "j_mmc_glass_cannon.png", negative_sprite = "j_mmc_glass_cannon_negative.png",
    blueprint_compat = true,
    loc_vars = function(self, info_queue, card)
        return { vars = { ex(card).repetitions } }
    end,
    calculate = function(self, card, context)
        if context.other_card and data_of(context.other_card).enhancement == "glass" then
            if context.repetition and context.cardarea == G.play then
                return { repetitions = ex(card).repetitions }
            end
            if context.individual and context.cardarea == G.play then
                card._mmc_glass = card._mmc_glass or {}
                card._mmc_glass[#card._mmc_glass + 1] = context.other_card
            end
        end
        if context.after and card._mmc_glass then
            local marked = card._mmc_glass
            card._mmc_glass = nil
            for _, view in ipairs(marked) do
                SMODS.destroy_card(view)
            end
            return { message = "Shattered!" }
        end
    end,
}

-- Scoring Test: destroy a played hand that scores less than 1% of the
-- blind's requirement.
SMODS.Joker {
    key = "scoring_test", rarity = 2, cost = 6,
    loc_txt = { name = "Scoring Test", text = {
        "If played hand",
        "scores less than {C:attention}#1#%",
        "of blind requirement",
        "{C:red}destroy{} it",
    } },
    config = { extra = { percentage = 1 } },
    sprite = "j_mmc_scoring_test.png", negative_sprite = "j_mmc_scoring_test_negative.png",
    blueprint_compat = false,
    loc_vars = function(self, info_queue, card)
        return { vars = { ex(card).percentage } }
    end,
    calculate = function(self, card, context)
        if context.joker_main and context.full_hand then
            card._mmc_played = {}
            for _, view in ipairs(context.full_hand) do
                card._mmc_played[#card._mmc_played + 1] = view
            end
        end
        if context.final_scoring_step then
            local total = hand_total(context)
            local target = blind_target()
            -- total < target * percentage / 100, compared Big-safely.
            card._mmc_doomed = SMODS.big_cmp(total * 100, target * ex(card).percentage) < 0
        end
        if context.after then
            local doomed, played = card._mmc_doomed, card._mmc_played
            card._mmc_doomed, card._mmc_played = nil, nil
            if doomed and played then
                for _, view in ipairs(played) do
                    SMODS.destroy_card(view)
                end
                return { message = "Destroy!" }
            end
        end
    end,
}

-- Dawn: retrigger every played card in the first hand of the round.
SMODS.Joker {
    key = "dawn", rarity = 2, cost = 6,
    loc_txt = { name = "Dawn", text = {
        "Retrigger all played",
        "cards in {C:attention}first",
        "{C:attention}hand{} of round",
    } },
    config = { extra = { repetitions = 1 } },
    sprite = "j_mmc_dawn.png", negative_sprite = "j_mmc_dawn_negative.png",
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.repetition and context.cardarea == G.play and context.other_card
            and G and G.get_round_hands_played and G:get_round_hands_played() == 0 then
            return { repetitions = ex(card).repetitions }
        end
    end,
}

-- Savings: +5 Mult per round, resetting to zero whenever a card is bought.
SMODS.Joker {
    key = "savings", rarity = 2, cost = 6,
    loc_txt = { name = "Savings", text = {
        "{C:mult}+#1#{} Mult per round",
        "Resets when",
        "buying a {C:attention}card",
        "{C:inactive}(Currently {C:mult}+#2#{C:inactive} Mult)",
    } },
    config = { extra = { mult_mod = 5, current_mult = 0 } },
    sprite = "j_mmc_savings.png", negative_sprite = "j_mmc_savings_negative.png",
    blueprint_compat = true,
    loc_vars = function(self, info_queue, card)
        local e = ex(card)
        return { vars = { e.mult_mod, e.current_mult } }
    end,
    calculate = function(self, card, context)
        local e = ex(card)
        if context.buying_card and not context.blueprint then
            if e.current_mult ~= 0 then
                e.current_mult = 0
                return { message = "Reset" }
            end
            return
        end
        if context.joker_main and e.current_mult > 0 then
            return { mult = e.current_mult }
        end
        if context.end_of_round and not context.blueprint then
            e.current_mult = e.current_mult + e.mult_mod
            return { message = "+" .. e.mult_mod .. " Mult" }
        end
    end,
}

-- Monopolist: X0.5 Mult per money threshold, starting at $10 and doubling
-- each time it is met; it steps back down when the balance falls below
-- half the current threshold. PC ran the state machine per frame; the
-- port settles it on every money change, which converges to the same
-- resting state.
SMODS.Joker {
    key = "monopolist", rarity = 3, cost = 10,
    loc_txt = { name = "Monopolist", text = {
        "{X:mult,C:white}X#1#{} Mult, gains",
        "{X:mult,C:white}X#2#{} Mult at {C:money}$#3#{},",
        "requirement doubles",
        "when met",
    } },
    config = { extra = { current_x_mult = 1, x_mult_mod = 0.5, req = 10, base = 10 } },
    sprite = "j_mmc_monopolist.png", negative_sprite = "j_mmc_monopolist_negative.png",
    blueprint_compat = true,
    loc_vars = function(self, info_queue, card)
        local e = ex(card)
        return { vars = { e.current_x_mult, e.x_mult_mod, e.req } }
    end,
    calculate = function(self, card, context)
        local e = ex(card)
        if context.money_altered and not context.blueprint then
            local bal = tonumber(G and G.money) or 0
            local guard = 0
            while bal >= e.req and guard < 64 do
                e.current_x_mult = e.current_x_mult + e.x_mult_mod
                e.req = e.req * 2
                guard = guard + 1
            end
            while e.req ~= e.base and bal < e.req / 2 and guard < 128 do
                e.current_x_mult = e.current_x_mult - e.x_mult_mod
                e.req = e.req / 2
                guard = guard + 1
            end
        end
        if context.joker_main and e.current_x_mult > 1 then
            return { x_mult = e.current_x_mult }
        end
    end,
}

-- Nebula: Mult equal to every poker hand level above 1, summed.
SMODS.Joker {
    key = "nebula", rarity = 1, cost = 5,
    loc_txt = { name = "Nebula", text = {
        "Adds all {C:attention}poker",
        "{C:attention}hand{} levels above",
        "#1# to {C:mult}Mult",
    } },
    config = { extra = { req = 1 } },
    sprite = "j_mmc_nebula.png", negative_sprite = "j_mmc_nebula_negative.png",
    blueprint_compat = true,
    loc_vars = function(self, info_queue, card)
        return { vars = { ex(card).req } }
    end,
    calculate = function(self, card, context)
        if context.joker_main and G and G.handlist and G.get_hand_level_stats then
            local tally = 0
            for i in ipairs(G.handlist) do
                local level = G:get_hand_level_stats(i)
                if level > ex(card).req then tally = tally + level - ex(card).req end
            end
            if tally > 0 then return { mult = tally } end
        end
    end,
}

-- Cheapskate: earn half the cost of a Booster Pack when you skip it. PC
-- read the price off the opened pack; the fork's open context carries no
-- price, so the port stashes half the price when the pack is bought and
-- pays it out on the skip.
SMODS.Joker {
    key = "cheapskate", rarity = 1, cost = 0,
    loc_txt = { name = "Cheapskate", text = {
        "If a {C:attention}Booster Pack",
        "is skipped, earn",
        "half of it's {C:money}cost",
    } },
    config = { extra = { cost = 0 } },
    sprite = "j_mmc_cheapskate.png", negative_sprite = "j_mmc_cheapskate_negative.png",
    blueprint_compat = true,
    calculate = function(self, card, context)
        local e = ex(card)
        if context.buying_card then
            local p = context.port or {}
            if p.offer_kind == "booster" then
                e.cost = math.floor((tonumber(p.offer_price) or 0) / 2)
            end
        end
        if context.skipping_booster and e.cost > 0 then
            local amount = e.cost
            e.cost = 0
            if G and G.ease_dollars then G:ease_dollars(amount) end
            return { message = "$" .. amount }
        end
    end,
}

-- Psychic Joker: +150 Chips, but destroyed if a hand plays fewer than 5
-- cards.
SMODS.Joker {
    key = "psychic", rarity = 1, cost = 5,
    loc_txt = { name = "Psychic Joker", text = {
        "{C:chips}+#1#{} Chips, destroyed",
        "if you play less",
        "than {C:attention}#2#{} cards",
        "in one hand",
    } },
    config = { extra = { chips = 150, req = 5 } },
    sprite = "j_mmc_psychic.png", negative_sprite = "j_mmc_psychic_negative.png",
    blueprint_compat = true, eternal_compat = false,
    loc_vars = function(self, info_queue, card)
        local e = ex(card)
        return { vars = { e.chips, e.req } }
    end,
    calculate = function(self, card, context)
        if context.joker_main and context.full_hand then
            if #context.full_hand < ex(card).req then
                card._mmc_shatter = true
            else
                return { chips = ex(card).chips }
            end
        end
        if context.after and card._mmc_shatter then
            card._mmc_shatter = nil
            SMODS.destroy_joker(card)
            return { message = "Shattered!" }
        end
    end,
}

-- Cheat: retrigger every played card when the hand contains a Straight.
-- The fork's repetition query carries no hand information, so the hand's
-- shape is latched at `before` (where poker_hands exists) and read back
-- during the query -- the same net effect as PC's direct read.
SMODS.Joker {
    key = "cheat", rarity = 2, cost = 6,
    loc_txt = { name = "Cheat", text = {
        "Retrigger all cards",
        "if played hand",
        "contains a {C:attention}Straight{}",
    } },
    config = { extra = { repetitions = 1 } },
    sprite = "j_mmc_cheat.png", negative_sprite = "j_mmc_cheat_negative.png",
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.before then
            card._mmc_straight = context.poker_hands
                and next(context.poker_hands["Straight"]) ~= nil or nil
        end
        if context.repetition and context.cardarea == G.play and context.other_card then
            local straight = card._mmc_straight
            if not straight and context.poker_hands then
                straight = next(context.poker_hands["Straight"]) ~= nil
            end
            if straight then
                return { repetitions = ex(card).repetitions }
            end
        end
        if context.after then card._mmc_straight = nil end
    end,
}

-- Plus One: scored cards on the first hand of the round permanently gain
-- a rank (Aces wrap to 2, nothing passes Ace). PC rebuilt the card front;
-- the port writes the rank into the card data, PC's chip values kept.
SMODS.Joker {
    key = "plus_one", rarity = 3, cost = 8,
    loc_txt = { name = "Plus One", text = {
        "Increases rank",
        "of scored cards by",
        "{C:attention}#1#{} on the {C:attention}first",
        "{C:attention}hand{} of round",
    } },
    config = { extra = { increase = 1 } },
    sprite = "j_mmc_plus_one.png", negative_sprite = "j_mmc_plus_one_negative.png",
    blueprint_compat = false,
    loc_vars = function(self, info_queue, card)
        return { vars = { ex(card).increase } }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play and context.other_card
            and G and G.get_round_hands_played and G:get_round_hands_played() == 0 then
            local view = context.other_card
            local d = data_of(view)
            local rank = tonumber(d.rank)
            if rank then
                local new_rank = rank == 14 and 2 or math.min(rank + ex(card).increase, 14)
                if new_rank ~= rank then
                    d.rank = new_rank
                    d.chips = ({ [11] = 10, [12] = 10, [13] = 10, [14] = 11 })[new_rank] or new_rank
                    if view.sync_visual_from_card_data then
                        view:sync_visual_from_card_data()
                    end
                    return { message = "Upgrade!" }
                end
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Decks (SMODS.Back)
--------------------------------------------------------------------------------

--- Keep only the starting cards whose rank id passes `pred` (ids as on PC:
--- 2-10 pip values, 11-13 faces, 14 Ace).
local function filter_starting_deck(game, pred)
    local deck = game and game.deck
    if not deck or type(deck.cards) ~= "table" then return end
    local kept = {}
    for _, c in ipairs(deck.cards) do
        local d = data_of(c)
        if pred(tonumber(d.rank) or 0) then kept[#kept + 1] = c end
    end
    deck.cards = kept
end

local function grant_start_joker(key, edition)
    return SMODS.add_card { set = "Joker", key = key, edition = edition }
end

-- Even Steven's Deck: only even cards (2, 4, 6, 8, 10), start with
-- Even Steven. Atlas position and text are PC's.
SMODS.Back {
    key = "even_stevens",
    loc_txt = { name = "Even Steven's Deck", text = {
        "Start run with only",
        "{C:attention}even cards{} and",
        "the {C:attention}Even Steven{} joker",
    } },
    pos = { x = 5, y = 2 },
    unlocked = true,
    apply = function(game)
        filter_starting_deck(game, function(id) return id <= 10 and id % 2 == 0 end)
        grant_start_joker("j_even_steven")
    end,
}

-- Odd Todd's Deck: only odd cards (3, 5, 7, 9 and Aces), start with
-- Odd Todd.
SMODS.Back {
    key = "odd_todds",
    loc_txt = { name = "Odd Todd's Deck", text = {
        "Start run with only",
        "{C:attention}odd cards{} and",
        "the {C:attention}Odd Todd{} joker",
    } },
    pos = { x = 5, y = 2 },
    unlocked = true,
    apply = function(game)
        filter_starting_deck(game, function(id) return (id % 2 ~= 0 and id < 10) or id == 14 end)
        grant_start_joker("j_odd_todd")
    end,
}

-- Fibonacci Deck: only Fibonacci ranks (2, 3, 5, 8, Ace), start with
-- Fibonacci.
SMODS.Back {
    key = "fibonacci",
    loc_txt = { name = "Fibonacci Deck", text = {
        "Start run with only",
        "{C:attention}Fibonacci cards{} and",
        "the {C:attention}Fibonacci{} joker",
    } },
    pos = { x = 5, y = 2 },
    unlocked = true,
    apply = function(game)
        filter_starting_deck(game, function(id)
            return id == 2 or id == 3 or id == 5 or id == 8 or id == 14
        end)
        grant_start_joker("j_fibonacci")
    end,
}

-- Prime Deck: only prime ranks (2, 3, 5, 7, Ace), start with Prime Time.
SMODS.Back {
    key = "prime",
    loc_txt = { name = "Prime Deck", text = {
        "Start run with",
        "only {C:attention}prime cards{} and",
        "the {C:attention}Prime Time{} joker",
    } },
    pos = { x = 5, y = 2 },
    unlocked = true,
    apply = function(game)
        filter_starting_deck(game, function(id)
            return id == 2 or id == 3 or id == 5 or id == 7 or id == 14
        end)
        grant_start_joker("j_mmc_prime_time")
    end,
}

-- Midas's Deck: only face cards, all Gold, start with Midas Mask.
SMODS.Back {
    key = "midas",
    loc_txt = { name = "Midas's Deck", text = {
        "Start run with only",
        "{C:attention}Gold Face cards{} and",
        "the {C:attention}Midas Mask{} joker",
    } },
    pos = { x = 6, y = 0 },
    unlocked = true,
    apply = function(game)
        filter_starting_deck(game, function(id) return id >= 11 and id <= 13 end)
        local deck = game and game.deck
        if deck and type(deck.cards) == "table" then
            for _, c in ipairs(deck.cards) do
                data_of(c).enhancement = "gold"
            end
        end
        grant_start_joker("j_midas_mask")
    end,
}

-- Perfect Precision: +1 hands, discards and hand size, Antes scale X1.5,
-- and a Negative Sniper to start. The stats are deck config; the Sniper
-- rides the apply hook.
SMODS.Back {
    key = "perfect_precision",
    loc_txt = { name = "Perfect Precision Deck", text = {
        "+1 {C:blue}hands{}, {C:red}discards{} and",
        "{C:attention}hand size{}. Start with",
        "a {C:dark_edition}negative {C:attention}The Sniper{}",
        "Joker. Ante scales {C:attention}X1.5{}",
        "as fast",
    } },
    config = { hands = 1, discards = 1, hand_size = 1, ante_scale = 1.5 },
    pos = { x = 5, y = 2 },
    unlocked = true,
    apply = function(game)
        grant_start_joker("j_mmc_sniper", "negative")
    end,
}
