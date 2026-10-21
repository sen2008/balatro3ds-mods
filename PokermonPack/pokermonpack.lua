-- PokermonPack: 35 Gen 1 Pokemon Jokers ported from Pokermon (PC, SMODS)
-- by InertSteak, https://github.com/InertSteak/Pokermon (GPLv3), v3.9.1.
--
-- Port notes (Balatro3DS has no evolution, Energy, items, or custom
-- rarities):
--   * Evolution is stripped everywhere; each Pokemon keeps its base
--     effect at its base (un-energized) values.
--   * The custom "poke_safari" rarity maps to Rare (3).
--   * Charmander/Squirtle/Bulbasaur passives (+1 discard / +1 hand /
--     +1 hand size) are native Balatro3DS Joker modifiers here.
--   * Bulbasaur's "designated rank" is re-rolled at blind select,
--     as in the original (rank changes every round).
--   * Tentacruel's "10s can't be debuffed" passive and Goldeen/Seaking's
--     card_effects nuance have no 3DS equivalent and are dropped.
--   * Articuno only adds Foil/a seal when the card has none yet
--     (the original converts unconditionally).

local RANK_NAMES = { [14] = "Ace", [13] = "King", [12] = "Queen", [11] = "Jack" }
local function rank_name(id)
    return RANK_NAMES[id] or tostring(id)
end

-- Distinct ranks + distinct suits present in the scoring hand (Pidgey line).
local function distinct_rs(scoring_hand)
    local seen, ranks = {}, 0
    for _, c in ipairs(scoring_hand) do
        local id = c:get_id()
        if id and not seen[id] then
            seen[id] = true
            ranks = ranks + 1
        end
    end
    local suits = 0
    for _, s in ipairs({ "Hearts", "Diamonds", "Clubs", "Spades" }) do
        for _, c in ipairs(scoring_hand) do
            if c:is_suit(s) then
                suits = suits + 1
                break
            end
        end
    end
    return ranks + suits
end

-- Position (1-based) of context.other_card among the scoring cards of the
-- played hand, plus the total number of scoring cards. The repetition
-- context carries the raw event as context.port.
local function scoring_pos(context)
    local played = context.port and context.port.played_cards
    if type(played) ~= "table" then return nil, 0 end
    local pos, total = nil, 0
    for _, n in ipairs(played) do
        if n and n.counts_for_play_score then
            total = total + 1
            if n == context.other_card then pos = total end
        end
    end
    return pos, total
end

local function flat_mult(key, name, text_vars, rarity, cost, mult, extra_def)
    local def = {
        key = key,
        sprite = key .. ".png",
        negative_sprite = key .. "_negative.png",
        loc_txt = { name = name, text = { "{C:mult}+#1#{} Mult" } },
        loc_vars = function(self, info_queue, card)
            return { vars = { card.ability.extra.mult } }
        end,
        rarity = rarity,
        cost = cost,
        config = { extra = { mult = mult } },
        blueprint_compat = true,
        calculate = function(self, card, context)
            if context.joker_main then
                return {
                    mult_mod = card.ability.extra.mult,
                    message = "+" .. card.ability.extra.mult .. " Mult",
                }
            end
        end,
    }
    if extra_def then for k, v in pairs(extra_def) do def[k] = v end end
    SMODS.Joker(def)
end

local function flat_chips(key, name, rarity, cost, chips, extra_def)
    local def = {
        key = key,
        sprite = key .. ".png",
        negative_sprite = key .. "_negative.png",
        loc_txt = { name = name, text = { "{C:chips}+#1#{} Chips" } },
        loc_vars = function(self, info_queue, card)
            return { vars = { card.ability.extra.chips } }
        end,
        rarity = rarity,
        cost = cost,
        config = { extra = { chips = chips } },
        blueprint_compat = true,
        calculate = function(self, card, context)
            if context.joker_main then
                return {
                    chip_mod = card.ability.extra.chips,
                    message = "+" .. card.ability.extra.chips .. " Chips",
                }
            end
        end,
    }
    if extra_def then for k, v in pairs(extra_def) do def[k] = v end end
    SMODS.Joker(def)
end

-- Bulbasaur: +1 hand size; earn $1 for each held card of a rank that is
-- re-rolled every round (Ace until the first blind is selected).
SMODS.Joker {
    key = "bulbasaur",
    sprite = "bulbasaur.png",
    negative_sprite = "bulbasaur_negative.png",
    loc_txt = {
        name = "Bulbasaur",
        text = {
            "{C:attention}+#3#{} hand size",
            "Earn {C:money}$#1#{} for each",
            "{C:attention}#2#{} held in hand",
            "{C:inactive}(Rank changes every round){}",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = {
            card.ability.extra.money_mod,
            rank_name(card.ability.extra.target_rank or 14),
            card.ability.h_size,
        } }
    end,
    rarity = 2,
    cost = 5,
    config = { h_size = 1, extra = { money_mod = 1, target_rank = 14 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.setting_blind and not context.blueprint then
            card.ability.extra.target_rank = SMODS.pseudorandom_element(
                { 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14 }, "poke_bulbasaur")
        end
        if context.individual and context.cardarea == G.hand and not context.end_of_round then
            local oc = context.other_card
            if oc and oc:get_id() == (card.ability.extra.target_rank or 14) then
                if oc.debuff then return { message = "Debuffed!" } end
                return { dollars = card.ability.extra.money_mod }
            end
        end
    end,
}

-- Charmander: +1 discard. Gains +1 Mult permanently when a hand is
-- played with no discards remaining.
SMODS.Joker {
    key = "charmander",
    sprite = "charmander.png",
    negative_sprite = "charmander_negative.png",
    loc_txt = {
        name = "Charmander",
        text = {
            "{C:red}+#4#{} discard",
            "Gains {C:mult}+#2#{} Mult if",
            "hand is played when",
            "{C:attention}#3#{} discards remaining",
            "{C:inactive}(Currently {C:mult}+#1#{C:inactive} Mult)",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = {
            card.ability.extra.mult,
            card.ability.extra.mult_mod,
            card.ability.extra.d_remaining,
            card.ability.d_size,
        } }
    end,
    rarity = 2,
    cost = 5,
    perishable_compat = false,
    config = { d_size = 1, extra = { mult = 0, mult_mod = 1, d_remaining = 0 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.before and not context.blueprint then
            if (tonumber(G.discards) or 0) <= (card.ability.extra.d_remaining or 0) then
                card.ability.extra.mult = card.ability.extra.mult + card.ability.extra.mult_mod
                return { message = "+" .. card.ability.extra.mult_mod .. " Mult" }
            end
        end
        if context.joker_main and card.ability.extra.mult > 0 then
            return {
                mult_mod = card.ability.extra.mult,
                message = "+" .. card.ability.extra.mult .. " Mult",
            }
        end
    end,
}

-- Squirtle: +1 hand. Gains Chips permanently when a hand is played,
-- +1 Chip for each remaining hand.
SMODS.Joker {
    key = "squirtle",
    sprite = "squirtle.png",
    negative_sprite = "squirtle_negative.png",
    loc_txt = {
        name = "Squirtle",
        text = {
            "{C:chips}+#2#{} hand",
            "Gains {C:chips}+#3#{} Chips for each",
            "remaining {C:attention}hand{} when",
            "hand is played",
            "{C:inactive}(Currently {C:chips}+#1#{C:inactive} Chips)",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = {
            card.ability.extra.chips,
            card.ability.hands,
            card.ability.extra.chip_mod,
        } }
    end,
    rarity = 2,
    cost = 6,
    perishable_compat = false,
    config = { hands = 1, extra = { chips = 0, chip_mod = 1 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.before and not context.blueprint then
            local gain = card.ability.extra.chip_mod
                * math.max(0, math.floor(tonumber(G.hands) or 0))
            if gain > 0 then
                card.ability.extra.chips = card.ability.extra.chips + gain
                return { message = "+" .. gain .. " Chips" }
            end
        end
        if context.joker_main and card.ability.extra.chips > 0 then
            return {
                chip_mod = card.ability.extra.chips,
                message = "+" .. card.ability.extra.chips .. " Chips",
            }
        end
    end,
}

flat_mult("caterpie", "Caterpie", nil, 1, 2, 3)
flat_mult("metapod", "Metapod", nil, 1, 4, 6)
flat_mult("butterfree", "Butterfree", nil, 2, 5, 12)
flat_chips("weedle", "Weedle", 1, 2, 20)
flat_chips("kakuna", "Kakuna", 1, 4, 40)
flat_chips("beedrill", "Beedrill", 2, 5, 80)
flat_chips("magikarp", "Magikarp", 1, 2, 1)

-- Pidgey line: +Mult per distinct rank and suit in the scoring hand.
local function pidgey_line(key, name, rarity, cost, mult_mod)
    SMODS.Joker {
        key = key,
        sprite = key .. ".png",
        negative_sprite = key .. "_negative.png",
        loc_txt = {
            name = name,
            text = {
                "Gives {C:mult}+#1#{} Mult for each",
                "different {C:attention}rank{} and {C:attention}suit",
                "in poker hand",
            },
        },
        loc_vars = function(self, info_queue, card)
            return { vars = { card.ability.extra.mult_mod } }
        end,
        rarity = rarity,
        cost = cost,
        config = { extra = { mult_mod = mult_mod } },
        blueprint_compat = true,
        calculate = function(self, card, context)
            if context.joker_main and context.scoring_hand then
                local n = distinct_rs(context.scoring_hand)
                if n > 0 then
                    local total = card.ability.extra.mult_mod * n
                    return { mult_mod = total, message = "+" .. total .. " Mult" }
                end
            end
        end,
    }
end
pidgey_line("pidgey", "Pidgey", 1, 5, 2)
pidgey_line("pidgeotto", "Pidgeotto", 3, 6, 3)
pidgey_line("pidgeot", "Pidgeot", 3, 10, 5)

-- Rattata line: retrigger the first N scoring cards once more.
local function rattata_line(key, name, rarity, cost, first)
    SMODS.Joker {
        key = key,
        sprite = key .. ".png",
        negative_sprite = key .. "_negative.png",
        loc_txt = {
            name = name,
            text = {
                "Retrigger {C:attention}first",
                "{C:attention}#2#{} scored cards",
                "{C:attention}#1#{} additional time",
            },
        },
        loc_vars = function(self, info_queue, card)
            return { vars = { card.ability.extra.retriggers, card.ability.extra.first } }
        end,
        rarity = rarity,
        cost = cost,
        config = { extra = { retriggers = 1, first = first } },
        blueprint_compat = true,
        calculate = function(self, card, context)
            if context.repetition and context.cardarea == G.play then
                local pos = scoring_pos(context)
                if pos and pos <= card.ability.extra.first then
                    return {
                        repetitions = card.ability.extra.retriggers,
                        message = "Again!",
                    }
                end
            end
        end,
    }
end
rattata_line("rattata", "Rattata", 1, 5, 2)
rattata_line("raticate", "Raticate", 3, 7, 3)

-- Ekans: +10 Mult if the played hand contains a Straight.
SMODS.Joker {
    key = "ekans",
    sprite = "ekans.png",
    negative_sprite = "ekans_negative.png",
    loc_txt = {
        name = "Ekans",
        text = {
            "{C:mult}+#1#{} Mult if played hand",
            "contains a {C:attention}Straight{}",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult } }
    end,
    rarity = 1,
    cost = 5,
    config = { extra = { mult = 10 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.joker_main and context.poker_hands
            and next(context.poker_hands["Straight"]) then
            return {
                mult_mod = card.ability.extra.mult,
                message = "+" .. card.ability.extra.mult .. " Mult",
            }
        end
    end,
}

-- Growlithe: +8 Mult if the played hand contains a Flush.
SMODS.Joker {
    key = "growlithe",
    sprite = "growlithe.png",
    negative_sprite = "growlithe_negative.png",
    loc_txt = {
        name = "Growlithe",
        text = {
            "{C:mult}+#1#{} Mult if played hand",
            "contains a {C:attention}Flush{}",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult } }
    end,
    rarity = 1,
    cost = 5,
    config = { extra = { mult = 8 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.joker_main and context.poker_hands
            and next(context.poker_hands["Flush"]) then
            return {
                mult_mod = card.ability.extra.mult,
                message = "+" .. card.ability.extra.mult .. " Mult",
            }
        end
    end,
}

-- Sandshrew: +25 Chips for each Glass card in your full deck.
SMODS.Joker {
    key = "sandshrew",
    sprite = "sandshrew.png",
    negative_sprite = "sandshrew_negative.png",
    loc_txt = {
        name = "Sandshrew",
        text = {
            "{C:chips}+#1#{} Chips for each {C:attention}Glass",
            "card in your {C:attention}full deck",
            "{C:inactive}(Currently {C:chips}+#2#{C:inactive} Chips)",
        },
    },
    loc_vars = function(self, info_queue, card)
        local tally = 0
        if G and G.count_cards_in_full_deck then
            tally = G:count_cards_in_full_deck(function(c)
                return c.enhancement == "glass"
            end)
        end
        return { vars = { card.ability.extra.chip_mod, card.ability.extra.chip_mod * tally } }
    end,
    rarity = 1,
    cost = 4,
    config = { extra = { chip_mod = 25 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.joker_main and G and G.count_cards_in_full_deck then
            local tally = G:count_cards_in_full_deck(function(c)
                return c.enhancement == "glass"
            end)
            if tally > 0 then
                local total = card.ability.extra.chip_mod * tally
                return { chip_mod = total, message = "+" .. total .. " Chips" }
            end
        end
    end,
}

-- Diglett: +60 Chips if the hand contains Three of a Kind; +4 Mult if
-- it contains a scoring 2, 3, or 4. Both can apply.
SMODS.Joker {
    key = "diglett",
    sprite = "diglett.png",
    negative_sprite = "diglett_negative.png",
    loc_txt = {
        name = "Diglett",
        text = {
            "{C:chips}+#1#{} Chips if played hand",
            "contains a {C:attention}Three of a kind{}",
            "{C:mult}+#2#{} Mult if played hand",
            "contains a scoring {C:attention}2{}, {C:attention}3{}, or {C:attention}4{}",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chips, card.ability.extra.mult } }
    end,
    rarity = 1,
    cost = 5,
    config = { extra = { chips = 60, mult = 4 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.joker_main and context.scoring_hand then
            local tok = context.poker_hands
                and next(context.poker_hands["Three of a Kind"])
            local low = false
            for _, c in ipairs(context.scoring_hand) do
                local id = c:get_id()
                if id == 2 or id == 3 or id == 4 then
                    low = true
                    break
                end
            end
            if tok and low then
                return {
                    chip_mod = card.ability.extra.chips,
                    mult_mod = card.ability.extra.mult,
                    message = "Dig!",
                }
            elseif tok then
                return { chip_mod = card.ability.extra.chips, message = "+" .. card.ability.extra.chips .. " Chips" }
            elseif low then
                return { mult_mod = card.ability.extra.mult, message = "+" .. card.ability.extra.mult .. " Mult" }
            end
        end
    end,
}

-- Dugtrio: same shape as Diglett, +120 Chips and X1.5 Mult.
SMODS.Joker {
    key = "dugtrio",
    sprite = "dugtrio.png",
    negative_sprite = "dugtrio_negative.png",
    loc_txt = {
        name = "Dugtrio",
        text = {
            "{C:chips}+#2#{} Chips if played hand",
            "contains a {C:attention}Three of a kind{}",
            "{X:mult,C:white} X#1# {} Mult if played hand",
            "contains a scoring {C:attention}2{}, {C:attention}3{}, or {C:attention}4{}",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.xmult, card.ability.extra.chips } }
    end,
    rarity = 2,
    cost = 6,
    perishable_compat = false,
    config = { extra = { chips = 120, xmult = 1.5 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.joker_main and context.scoring_hand then
            local tok = context.poker_hands
                and next(context.poker_hands["Three of a Kind"])
            local low = false
            for _, c in ipairs(context.scoring_hand) do
                local id = c:get_id()
                if id == 2 or id == 3 or id == 4 then
                    low = true
                    break
                end
            end
            if tok and low then
                return {
                    chip_mod = card.ability.extra.chips,
                    x_mult = card.ability.extra.xmult,
                    message = "Dig!",
                }
            elseif tok then
                return { chip_mod = card.ability.extra.chips, message = "+" .. card.ability.extra.chips .. " Chips" }
            elseif low then
                return { x_mult = card.ability.extra.xmult, message = "X" .. card.ability.extra.xmult .. " Mult" }
            end
        end
    end,
}

-- Clefairy: played Clubs give +3 Mult when scored.
SMODS.Joker {
    key = "clefairy",
    sprite = "clefairy.png",
    negative_sprite = "clefairy_negative.png",
    loc_txt = {
        name = "Clefairy",
        text = {
            "Played {C:clubs}#2#{} cards give",
            "{C:mult}+#1#{} Mult when scored",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult, "Club" } }
    end,
    rarity = 1,
    cost = 4,
    config = { extra = { mult = 3 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            local oc = context.other_card
            if oc and not oc.debuff and oc:is_suit("Clubs") then
                return { mult = card.ability.extra.mult, message = "+" .. card.ability.extra.mult .. " Mult" }
            end
        end
    end,
}

-- Jigglypuff: played Spades give +2 Mult and +10 Chips when scored.
SMODS.Joker {
    key = "jigglypuff",
    sprite = "jigglypuff.png",
    negative_sprite = "jigglypuff_negative.png",
    loc_txt = {
        name = "Jigglypuff",
        text = {
            "Played {C:spades}#2#{} cards give",
            "{C:mult}+#1#{} Mult and {C:chips}+#3#{} Chips",
            "when scored",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult, "Spade", card.ability.extra.chips } }
    end,
    rarity = 1,
    cost = 4,
    perishable_compat = false,
    config = { extra = { mult = 2, chips = 10 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            local oc = context.other_card
            if oc and not oc.debuff and oc:is_suit("Spades") then
                return {
                    mult = card.ability.extra.mult,
                    chips = card.ability.extra.chips,
                    message = "Puff!",
                }
            end
        end
    end,
}

-- Tentacool / Tentacruel: played 10s give +Mult when scored.
local function tentacool_line(key, name, rarity, cost, mult)
    SMODS.Joker {
        key = key,
        sprite = key .. ".png",
        negative_sprite = key .. "_negative.png",
        loc_txt = {
            name = name,
            text = {
                "Each played {C:attention}10{} gives",
                "{C:mult}+#1#{} Mult when scored",
            },
        },
        loc_vars = function(self, info_queue, card)
            return { vars = { card.ability.extra.mult } }
        end,
        rarity = rarity,
        cost = cost,
        config = { extra = { mult = mult } },
        blueprint_compat = true,
        calculate = function(self, card, context)
            if context.individual and context.cardarea == G.play then
                local oc = context.other_card
                if oc and not oc.debuff and oc:get_id() == 10 then
                    return { mult = card.ability.extra.mult, message = "+" .. card.ability.extra.mult .. " Mult" }
                end
            end
        end,
    }
end
tentacool_line("tentacool", "Tentacool", 1, 4, 7)
tentacool_line("tentacruel", "Tentacruel", 2, 6, 10)

-- Krabby: played face cards give +20 Chips when scored.
SMODS.Joker {
    key = "krabby",
    sprite = "krabby.png",
    negative_sprite = "krabby_negative.png",
    loc_txt = {
        name = "Krabby",
        text = {
            "Played {C:attention}face{} cards give",
            "{C:chips}+#1#{} Chips when scored",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chips } }
    end,
    rarity = 1,
    cost = 4,
    config = { extra = { chips = 20 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            local oc = context.other_card
            if oc and not oc.debuff and oc:is_face() then
                return { chips = card.ability.extra.chips, message = "+" .. card.ability.extra.chips .. " Chips" }
            end
        end
    end,
}

-- Magnemite: played Steel cards give X1.5 Mult when scored.
SMODS.Joker {
    key = "magnemite",
    sprite = "magnemite.png",
    negative_sprite = "magnemite_negative.png",
    loc_txt = {
        name = "Magnemite",
        text = {
            "Played {C:attention}Steel{} cards",
            "give {X:mult,C:white}X#1#{} Mult",
            "when scored",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.xmult } }
    end,
    rarity = 2,
    cost = 7,
    config = { extra = { xmult = 1.5 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            local oc = context.other_card
            if oc and not oc.debuff and oc.enhancement == "steel" then
                return { x_mult = card.ability.extra.xmult, message = "X" .. card.ability.extra.xmult .. " Mult" }
            end
        end
    end,
}

-- Shellder / Cloyster: with exactly 5 scoring cards, each has a chance
-- to retrigger once more.
local function shellder_line(key, name, rarity, cost, dem, extra_def)
    local def = {
        key = key,
        sprite = key .. ".png",
        negative_sprite = key .. "_negative.png",
        loc_txt = {
            name = name,
            text = {
                "If hand has {C:attention}5{} scoring cards,",
                "each have a {C:green}#1# in #2#{} chance to",
                "retrigger {C:attention}#3#{} additional time",
            },
        },
        loc_vars = function(self, info_queue, card)
            local n, d = SMODS.get_probability_vars(
                card, card.ability.extra.num, card.ability.extra.dem, "poke_" .. key)
            return { vars = { n, d, card.ability.extra.retriggers } }
        end,
        rarity = rarity,
        cost = cost,
        config = { extra = { retriggers = 1, num = 1, dem = dem } },
        blueprint_compat = true,
        calculate = function(self, card, context)
            if context.repetition and context.cardarea == G.play then
                local pos, total = scoring_pos(context)
                if pos and total == 5 then
                    local hit = SMODS.pseudorandom_probability(
                        card, "poke_" .. key, card.ability.extra.num,
                        card.ability.extra.dem, "poke_" .. key)
                    if hit then
                        return {
                            repetitions = card.ability.extra.retriggers,
                            message = "Again!",
                        }
                    end
                end
            end
        end,
    }
    if extra_def then for k, v in pairs(extra_def) do def[k] = v end end
    SMODS.Joker(def)
end
shellder_line("shellder", "Shellder", 2, 5, 3)
shellder_line("cloyster", "Cloyster", 3, 8, 2, { eternal_compat = false })

-- Goldeen / Seaking: Gold cards held in hand retrigger.
local function goldeen_line(key, name, rarity, cost, retriggers, with_count_line)
    local text = {
        "Retrigger all {C:attention}Gold{}",
        "card {C:attention}held in",
        "{C:attention}hand{} abilities",
    }
    if with_count_line then
        text[#text + 1] = "{C:attention}#1#{} additional times"
    end
    SMODS.Joker {
        key = key,
        sprite = key .. ".png",
        negative_sprite = key .. "_negative.png",
        loc_txt = { name = name, text = text },
        loc_vars = function(self, info_queue, card)
            return { vars = { card.ability.extra.retriggers } }
        end,
        rarity = rarity,
        cost = cost,
        config = { extra = { retriggers = retriggers } },
        blueprint_compat = true,
        calculate = function(self, card, context)
            if context.repetition and context.cardarea == G.hand then
                local oc = context.other_card
                if oc and oc.enhancement == "gold" then
                    return {
                        repetitions = card.ability.extra.retriggers,
                        message = "Again!",
                    }
                end
            end
        end,
    }
end
goldeen_line("goldeen", "Goldeen", 1, 5, 1, false)
goldeen_line("seaking", "Seaking", 3, 8, 2, true)

-- Mr. Mime: the leftmost card held in hand retriggers 3 additional times.
SMODS.Joker {
    key = "mrmime",
    sprite = "mrmime.png",
    negative_sprite = "mrmime_negative.png",
    loc_txt = {
        name = "Mr. Mime",
        text = {
            "Retrigger leftmost card",
            "{C:attention}held in hand{} abilities",
            "{C:attention}#1#{} additional times",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.retriggers } }
    end,
    rarity = 3,
    cost = 8,
    perishable_compat = false,
    config = { extra = { retriggers = 3 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.repetition and context.cardarea == G.hand then
            local nodes = G.hand and G.hand.card_nodes
            if nodes and nodes[1] and context.other_card == nodes[1] then
                return {
                    repetitions = card.ability.extra.retriggers,
                    message = "Again!",
                }
            end
        end
    end,
}

-- Pinsir: X2 Mult if a scored card has the same rank as a card held
-- in hand.
SMODS.Joker {
    key = "pinsir",
    sprite = "pinsir.png",
    negative_sprite = "pinsir_negative.png",
    loc_txt = {
        name = "Pinsir",
        text = {
            "{X:mult,C:white} X#1# {} Mult if a scored card",
            "has the {C:attention}same rank{} as",
            "a card {C:attention}held in hand{}",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.xmult } }
    end,
    rarity = 2,
    cost = 6,
    config = { extra = { xmult = 2 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.joker_main and context.scoring_hand then
            local nodes = G.hand and G.hand.card_nodes
            if nodes then
                local scored_ranks = {}
                for _, c in ipairs(context.scoring_hand) do
                    scored_ranks[c:get_id()] = true
                end
                for _, hc in ipairs(nodes) do
                    if hc.get_id and scored_ranks[hc:get_id()] then
                        return {
                            x_mult = card.ability.extra.xmult,
                            message = "X" .. card.ability.extra.xmult .. " Mult",
                        }
                    end
                end
            end
        end
    end,
}

-- Pikachu: earn $2 when a Blind is selected if you have less than $25;
-- +10 Mult while you have $25 or more.
SMODS.Joker {
    key = "pikachu",
    sprite = "pikachu.png",
    negative_sprite = "pikachu_negative.png",
    loc_txt = {
        name = "Pikachu",
        text = {
            "{C:mult}+#1#{} Mult if you",
            "have {C:money}$#3#{} or more",
            "Earn {C:money}$#2#{} when {C:attention}Blind{}",
            "is selected if you",
            "have less than {C:money}$#3#",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = {
            card.ability.extra.mult,
            card.ability.extra.money,
            card.ability.extra.money_threshold,
        } }
    end,
    rarity = 1,
    cost = 6,
    config = { extra = { money = 2, mult = 10, money_threshold = 25 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.setting_blind then
            if (tonumber(G.money) or 0) < card.ability.extra.money_threshold then
                return { dollars = card.ability.extra.money }
            end
        end
        if context.joker_main
            and (tonumber(G.money) or 0) >= card.ability.extra.money_threshold then
            return {
                mult_mod = card.ability.extra.mult,
                message = "+" .. card.ability.extra.mult .. " Mult",
            }
        end
    end,
}

-- Rapidash: gains Chips permanently when a played hand contains a
-- Straight; the gain itself grows by +1 each time it triggers.
SMODS.Joker {
    key = "rapidash",
    sprite = "rapidash.png",
    negative_sprite = "rapidash_negative.png",
    loc_txt = {
        name = "Rapidash",
        text = {
            "Gains {C:chips}+#2#{} Chips if played",
            "hand contains a {C:attention}Straight{}",
            "Chip increase goes up",
            "by {C:chips}+1{} each time",
            "{C:inactive}(Currently {C:chips}+#1#{C:inactive} Chips)",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chips, card.ability.extra.chip_mod } }
    end,
    rarity = 3,
    cost = 8,
    perishable_compat = false,
    config = { extra = { chips = 0, chip_mod = 15 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.before and not context.blueprint and context.poker_hands
            and next(context.poker_hands["Straight"]) then
            local gain = card.ability.extra.chip_mod
            card.ability.extra.chips = card.ability.extra.chips + gain
            card.ability.extra.chip_mod = gain + 1
            return { message = "+" .. gain .. " Chips" }
        end
        if context.joker_main and card.ability.extra.chips > 0 then
            return {
                chip_mod = card.ability.extra.chips,
                message = "+" .. card.ability.extra.chips .. " Chips",
            }
        end
    end,
}

-- Articuno: the first scoring card of each played hand gains Foil and a
-- random seal (only if it has neither yet).
SMODS.Joker {
    key = "articuno",
    sprite = "articuno.png",
    negative_sprite = "articuno_negative.png",
    loc_txt = {
        name = "Articuno",
        text = {
            "Add {C:attention}Foil{} and a {C:attention}seal{} to",
            "first scoring card",
            "in played hand",
        },
    },
    rarity = 4,
    cost = 20,
    blueprint_compat = false,
    calculate = function(self, card, context)
        if context.before and not context.blueprint
            and context.scoring_hand and context.scoring_hand[1] then
            local target = context.scoring_hand[1]
            local changed = false
            if target.card_data then
                target.card_data.modifier = target.card_data.modifier or {}
                if not target.card_data.modifier.edition then
                    target.card_data.modifier.edition = "foil"
                    changed = true
                end
            end
            if target.set_seal and not target.seal then
                target:set_seal(SMODS.pseudorandom_element(
                    { "red", "gold", "blue", "purple" }, "poke_articuno"))
                changed = true
            end
            if changed then return { message = "Legendary!" } end
        end
    end,
}
