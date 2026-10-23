-- PokermonPack: 50 Gen 1 Pokemon Jokers ported from Pokermon (PC, SMODS)
-- by InertSteak, https://github.com/InertSteak/Pokermon (GPLv3), v3.9.1.
--
-- Port notes (v1.1.0, Balatro3DS fork):
--   * Evolution is implemented at pack level with the fork's Tier 1 API
--     (SMODS.add_card / SMODS.destroy_joker). Where PC transforms the
--     card in place and keeps its slot, the port destroys the old Joker
--     and creates the evolved form, which lands at the end of the Joker
--     area; the edition and any scaled values PC would keep (a grown
--     Mult/Chips total whose *_mod is still on the card) carry over.
--     Stickers do not carry. On the stock game the Tier 1 calls do not
--     exist and nothing evolves, exactly as in v1.0.0.
--   * Rounds-held (level) and counter (scaling) evolutions are checked
--     on the port's end_of_round context, where PC raises its own
--     evolution context after end_round().
--   * Stone evolutions (v1.2.0) use the fork's SMODS.ConsumableType:
--     the Moon, Fire, Water and Thunder Stones are registered under
--     the pack's own "poke_item" type (as on PC) at the bottom of
--     this file. v1.3.0 upgrades them to the fork's Tier 3 Joker
--     targeting (target_joker): the player chooses the Joker, and
--     using one evolves the chosen held Clefairy, Jigglypuff,
--     Growlithe, Pikachu or Shellder through the same poke_evolve
--     call; the kind also gets a collection category and an Item
--     Pack booster. On the stock game the type API does not
--     exist, no stones register, and those five never evolve; their
--     evolved forms (Clefable, Wigglytuff, Arcanine, Raichu) are
--     still in the pack as standalone Jokers either way, like every
--     other stage; Cloyster was already here.
--   * Energy is stripped everywhere; each Pokemon keeps its base
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

--------------------------------------------------------------------------------
-- Evolution (pack level, fork Tier 1 API)
--------------------------------------------------------------------------------

-- Replace `card` with the Joker `target_key`, PC backend_evolve style:
-- the scaled values PC keeps (a total whose *_mod sits next to it) and
-- the edition carry to the new form; everything else starts fresh from
-- the evolved form's own config. Returns the new Joker, or nil when the
-- Tier 1 API is absent (stock game) or the swap failed.
local function poke_evolve(card, target_key)
    if not (SMODS.add_card and SMODS.destroy_joker) then return nil end
    local extra = card.ability and card.ability.extra or {}
    local keep = {}
    for _, k in ipairs({ "mult", "chips", "Xmult", "money" }) do
        local v = extra[k]
        if type(v) == "number"
            and (extra[k .. "_mod"] ~= nil or extra[k:sub(1, -2) .. "_mod"] ~= nil) then
            keep[k] = v
        end
    end
    local edition = card.edition
    if edition == "base" or edition == "" then edition = nil end
    if not SMODS.destroy_joker(card) then return nil end
    local newj = SMODS.add_card { set = "Joker", key = target_key, edition = edition }
    if newj and type(newj.ability) == "table" and type(newj.ability.extra) == "table" then
        for k, v in pairs(keep) do
            local nv = newj.ability.extra[k]
            if type(nv) == "number" and v > nv then newj.ability.extra[k] = v end
        end
    end
    return newj
end

-- PC pokermon.level_evo: on the evolution step (the port's end_of_round),
-- count down extra.rounds and evolve when it runs out. A debuffed or
-- Blueprint-copied Joker never evolves, as on PC.
local function poke_level_evo(card, context, target_key)
    if not context.end_of_round or context.blueprint then return end
    local extra = card.ability and card.ability.extra
    if type(extra) ~= "table" or type(extra.rounds) ~= "number" then return end
    if card.debuff == true or card.debuffed == true then return end
    if extra.rounds > 0 then extra.rounds = extra.rounds - 1 end
    if extra.rounds <= 0 then poke_evolve(card, target_key) end
end

-- PC pokermon.scaling_evo: evolve on the evolution step once the
-- tracked counter reaches its target.
local function poke_scaling_evo(card, context, target_key, value, target)
    if not context.end_of_round or context.blueprint then return end
    if (tonumber(value) or 0) >= target then poke_evolve(card, target_key) end
end

-- A scoring card's total Chips, PC pokermon.total_chips rebuilt from
-- card_data the way Scapegoat (KCVanillaPack) rebuilds get_chip_bonus:
-- rank value (Ace 11, faces 10), 50 for Stone instead of its rank,
-- +30 for a Bonus card, +50 for a Foil edition, plus any permanent
-- Bonus/chip_bonus already on the card.
local function card_chip_value(view)
    local data = view.card_data or {}
    local id = view.get_id and view:get_id() or tonumber(data.rank)
    local base
    if data.enhancement == "stone" then
        base = 50
    elseif id == 14 then
        base = 11
    elseif id and id >= 11 then
        base = 10
    else
        base = id or 0
    end
    if data.enhancement == "bonus" then base = base + 30 end
    if data.modifier and data.modifier.edition == "foil" then base = base + 50 end
    base = base + (tonumber(data.Bonus) or tonumber(data.bonus)
        or tonumber(data.chip_bonus) or 0)
    return base
end

local function flat_mult(key, name, text_vars, rarity, cost, mult, extra_def)
    local evo_to, evo_rounds
    if extra_def then
        evo_to, evo_rounds = extra_def.evo_to, extra_def.evo_rounds
        extra_def.evo_to, extra_def.evo_rounds = nil, nil
    end
    local text = { "{C:mult}+#1#{} Mult" }
    if evo_to then
        text[#text + 1] = "{C:inactive}(Evolves after {C:attention}#2#{C:inactive} rounds)"
    end
    local extra = { mult = mult }
    if evo_rounds then extra.rounds = evo_rounds end
    local def = {
        key = key,
        sprite = key .. ".png",
        negative_sprite = key .. "_negative.png",
        loc_txt = { name = name, text = text },
        loc_vars = function(self, info_queue, card)
            return { vars = { card.ability.extra.mult, card.ability.extra.rounds } }
        end,
        rarity = rarity,
        cost = cost,
        config = { extra = extra },
        blueprint_compat = true,
        calculate = function(self, card, context)
            if context.joker_main then
                return {
                    mult_mod = card.ability.extra.mult,
                    message = "+" .. card.ability.extra.mult .. " Mult",
                }
            end
            if evo_to then poke_level_evo(card, context, evo_to) end
        end,
    }
    if extra_def then for k, v in pairs(extra_def) do def[k] = v end end
    SMODS.Joker(def)
end

local function flat_chips(key, name, rarity, cost, chips, extra_def)
    local evo_to, evo_rounds
    if extra_def then
        evo_to, evo_rounds = extra_def.evo_to, extra_def.evo_rounds
        extra_def.evo_to, extra_def.evo_rounds = nil, nil
    end
    local text = { "{C:chips}+#1#{} Chips" }
    if evo_to then
        text[#text + 1] = "{C:inactive}(Evolves after {C:attention}#2#{C:inactive} rounds)"
    end
    local extra = { chips = chips }
    if evo_rounds then extra.rounds = evo_rounds end
    local def = {
        key = key,
        sprite = key .. ".png",
        negative_sprite = key .. "_negative.png",
        loc_txt = { name = name, text = text },
        loc_vars = function(self, info_queue, card)
            return { vars = { card.ability.extra.chips, card.ability.extra.rounds } }
        end,
        rarity = rarity,
        cost = cost,
        config = { extra = extra },
        blueprint_compat = true,
        calculate = function(self, card, context)
            if context.joker_main then
                return {
                    chip_mod = card.ability.extra.chips,
                    message = "+" .. card.ability.extra.chips .. " Chips",
                }
            end
            if evo_to then poke_level_evo(card, context, evo_to) end
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
            "{C:inactive}(Evolves after earning {C:money}$#4#{C:inactive})",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = {
            card.ability.extra.money_mod,
            rank_name(card.ability.extra.target_rank or 14),
            card.ability.h_size,
            math.max(0, 16 - (card.ability.extra.earned or 0)),
        } }
    end,
    rarity = 2,
    cost = 5,
    config = { h_size = 1, extra = { money_mod = 1, earned = 0, target_rank = 14 } },
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
                if not context.blueprint then
                    card.ability.extra.earned = (card.ability.extra.earned or 0)
                        + card.ability.extra.money_mod
                end
                return { dollars = card.ability.extra.money_mod }
            end
        end
        poke_scaling_evo(card, context, "j_pokep_ivysaur",
            card.ability.extra.earned, 16)
    end,
}

-- Ivysaur: like Bulbasaur, but each held match has a 1 in 2 chance to
-- pay an extra $1, and the bonus counts toward its own evolution.
-- Venusaur: the same shape at $2 a match, no roll, no further evolution.
local function bulb_line(key, name, cost, money_mod, bonus_roll, evo_to)
    local text = {
        "{C:attention}+#3#{} hand size",
        bonus_roll and "Earn {C:money}$#1#{} or {C:money}$#5#{} for each"
            or "Earn {C:money}$#1#{} for each",
        "{C:attention}#4#{} held in hand",
        "{C:inactive}(Rank changes every round){}",
    }
    if evo_to then
        text[#text + 1] = "{C:inactive}(Evolves after earning {C:money}$#2#{C:inactive})"
    end
    SMODS.Joker {
        key = key,
        sprite = key .. ".png",
        negative_sprite = key .. "_negative.png",
        loc_txt = { name = name, text = text },
        loc_vars = function(self, info_queue, card)
            return { vars = {
                card.ability.extra.money_mod,
                math.max(0, 16 - (card.ability.extra.earned or 0)),
                card.ability.h_size,
                rank_name(card.ability.extra.target_rank or 14),
                card.ability.extra.money_mod + 1,
            } }
        end,
        rarity = 3,
        cost = cost,
        config = { h_size = 1, extra = { money_mod = money_mod, earned = 0, target_rank = 14 } },
        blueprint_compat = true,
        calculate = function(self, card, context)
            if context.setting_blind and not context.blueprint then
                card.ability.extra.target_rank = SMODS.pseudorandom_element(
                    { 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14 }, "poke_" .. key)
            end
            if context.individual and context.cardarea == G.hand and not context.end_of_round then
                local oc = context.other_card
                if oc and oc:get_id() == (card.ability.extra.target_rank or 14) then
                    if oc.debuff then return { message = "Debuffed!" } end
                    local gain = card.ability.extra.money_mod
                    if bonus_roll then
                        local hit = SMODS.pseudorandom_probability(
                            card, "poke_" .. key, 1, 2, "poke_" .. key)
                        if hit then gain = gain + 1 end
                    end
                    if not context.blueprint then
                        card.ability.extra.earned = (card.ability.extra.earned or 0) + gain
                    end
                    return { dollars = gain }
                end
            end
            if evo_to then
                poke_scaling_evo(card, context, evo_to, card.ability.extra.earned, 16)
            end
        end,
    }
end
bulb_line("ivysaur", "Ivysaur", 9, 1, true, "j_pokep_venusaur")
bulb_line("venusaur", "Venusaur", 10, 2, false, nil)

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
            "{C:inactive}(Evolves at {C:mult}+#1#{C:inactive} / +16 Mult)",
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
        poke_scaling_evo(card, context, "j_pokep_charmeleon",
            card.ability.extra.mult, 16)
    end,
}

-- Charmeleon: Charmander's growth at +2 Mult a time, evolving at +36.
SMODS.Joker {
    key = "charmeleon",
    sprite = "charmeleon.png",
    negative_sprite = "charmeleon_negative.png",
    loc_txt = {
        name = "Charmeleon",
        text = {
            "{C:red}+#4#{} discard",
            "Gains {C:mult}+#2#{} Mult if",
            "hand is played when",
            "{C:attention}#3#{} discards remaining",
            "{C:inactive}(Currently {C:mult}+#1#{C:inactive} Mult)",
            "{C:inactive}(Evolves at {C:mult}+#1#{C:inactive} / +36 Mult)",
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
    rarity = 3,
    cost = 8,
    perishable_compat = false,
    config = { d_size = 1, extra = { mult = 0, mult_mod = 2, d_remaining = 0 } },
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
        poke_scaling_evo(card, context, "j_pokep_charizard",
            card.ability.extra.mult, 36)
    end,
}

-- Charizard: +36 Mult, and X1.5 Mult on top when no discards remain.
SMODS.Joker {
    key = "charizard",
    sprite = "charizard.png",
    negative_sprite = "charizard_negative.png",
    loc_txt = {
        name = "Charizard",
        text = {
            "{C:red}+#4#{} discard, {C:mult}+#1#{} Mult",
            "{X:mult,C:white} X#2# {} Mult when",
            "{C:attention}#3#{} discards remaining",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = {
            card.ability.extra.mult,
            card.ability.extra.xmult,
            card.ability.extra.d_remaining,
            card.ability.d_size,
        } }
    end,
    rarity = 3,
    cost = 10,
    config = { d_size = 1, extra = { mult = 36, xmult = 1.5, d_remaining = 0 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.joker_main then
            if (tonumber(G.discards) or 0) <= (card.ability.extra.d_remaining or 0) then
                return {
                    mult_mod = card.ability.extra.mult,
                    x_mult = card.ability.extra.xmult,
                    message = "Fire Blast!",
                }
            end
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
            "{C:inactive}(Evolves at {C:chips}+#1#{C:inactive} / +40 Chips)",
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
        poke_scaling_evo(card, context, "j_pokep_wartortle",
            card.ability.extra.chips, 40)
    end,
}

-- Wartortle: Squirtle's growth at +2 Chips per remaining hand,
-- evolving at +120 Chips.
SMODS.Joker {
    key = "wartortle",
    sprite = "wartortle.png",
    negative_sprite = "wartortle_negative.png",
    loc_txt = {
        name = "Wartortle",
        text = {
            "{C:chips}+#2#{} hand",
            "Gains {C:chips}+#3#{} Chips for each",
            "remaining {C:attention}hand{} when",
            "hand is played",
            "{C:inactive}(Currently {C:chips}+#1#{C:inactive} Chips)",
            "{C:inactive}(Evolves at {C:chips}+#1#{C:inactive} / +120 Chips)",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = {
            card.ability.extra.chips,
            card.ability.hands,
            card.ability.extra.chip_mod,
        } }
    end,
    rarity = 3,
    cost = 8,
    perishable_compat = false,
    config = { hands = 1, extra = { chips = 40, chip_mod = 2 } },
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
        poke_scaling_evo(card, context, "j_pokep_blastoise",
            card.ability.extra.chips, 120)
    end,
}

-- Blastoise: +120 Chips, plus +25 Chips for each remaining hand,
-- counted fresh at scoring time instead of grown.
SMODS.Joker {
    key = "blastoise",
    sprite = "blastoise.png",
    negative_sprite = "blastoise_negative.png",
    loc_txt = {
        name = "Blastoise",
        text = {
            "{C:chips}+#3#{} hand, {C:chips}+#1#{} Chips",
            "{C:chips}+#2#{} Chips for each",
            "remaining hand",
            "{C:inactive}(Currently {C:chips}+#4#{C:inactive} Chips)",
        },
    },
    loc_vars = function(self, info_queue, card)
        local hands_left = math.max(0, math.floor(tonumber(G and G.hands) or 0))
        return { vars = {
            card.ability.extra.chips,
            card.ability.extra.chip_mod,
            card.ability.hands,
            card.ability.extra.chips + card.ability.extra.chip_mod * hands_left,
        } }
    end,
    rarity = 3,
    cost = 10,
    config = { hands = 1, extra = { chips = 120, chip_mod = 25 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.joker_main then
            local total = card.ability.extra.chips
                + card.ability.extra.chip_mod
                * math.max(0, math.floor(tonumber(G.hands) or 0))
            return {
                chip_mod = total,
                message = "+" .. total .. " Chips",
            }
        end
    end,
}

flat_mult("caterpie", "Caterpie", nil, 1, 2, 3,
    { evo_to = "j_pokep_metapod", evo_rounds = 2 })
flat_mult("metapod", "Metapod", nil, 1, 4, 6,
    { evo_to = "j_pokep_butterfree", evo_rounds = 3 })
flat_mult("butterfree", "Butterfree", nil, 2, 5, 12)
flat_chips("weedle", "Weedle", 1, 2, 20,
    { evo_to = "j_pokep_kakuna", evo_rounds = 2 })
flat_chips("kakuna", "Kakuna", 1, 4, 40,
    { evo_to = "j_pokep_beedrill", evo_rounds = 3 })
flat_chips("beedrill", "Beedrill", 2, 5, 80)
flat_chips("magikarp", "Magikarp", 1, 2, 1,
    { evo_to = "j_pokep_gyarados", evo_rounds = 8 })

-- Gyarados: X2.5 Mult.
SMODS.Joker {
    key = "gyarados",
    sprite = "gyarados.png",
    negative_sprite = "gyarados_negative.png",
    loc_txt = {
        name = "Gyarados",
        text = { "{X:mult,C:white} X#1# {} Mult" },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.xmult } }
    end,
    rarity = 3,
    cost = 10,
    config = { extra = { xmult = 2.5 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.joker_main then
            return {
                x_mult = card.ability.extra.xmult,
                message = "X" .. card.ability.extra.xmult .. " Mult",
            }
        end
    end,
}

-- Pidgey line: +Mult per distinct rank and suit in the scoring hand.
local function pidgey_line(key, name, rarity, cost, mult_mod, rounds, evo_to)
    local text = {
        "Gives {C:mult}+#1#{} Mult for each",
        "different {C:attention}rank{} and {C:attention}suit",
        "in poker hand",
    }
    if evo_to then
        text[#text + 1] = "{C:inactive}(Evolves after {C:attention}#2#{C:inactive} rounds)"
    end
    local extra = { mult_mod = mult_mod }
    if rounds then extra.rounds = rounds end
    SMODS.Joker {
        key = key,
        sprite = key .. ".png",
        negative_sprite = key .. "_negative.png",
        loc_txt = {
            name = name,
            text = text,
        },
        loc_vars = function(self, info_queue, card)
            return { vars = { card.ability.extra.mult_mod,
                card.ability.extra.rounds } }
        end,
        rarity = rarity,
        cost = cost,
        config = { extra = extra },
        blueprint_compat = true,
        calculate = function(self, card, context)
            if context.joker_main and context.scoring_hand then
                local n = distinct_rs(context.scoring_hand)
                if n > 0 then
                    local total = card.ability.extra.mult_mod * n
                    return { mult_mod = total, message = "+" .. total .. " Mult" }
                end
            end
            if evo_to then poke_level_evo(card, context, evo_to) end
        end,
    }
end
pidgey_line("pidgey", "Pidgey", 1, 5, 2, 4, "j_pokep_pidgeotto")
pidgey_line("pidgeotto", "Pidgeotto", 3, 6, 3, 4, "j_pokep_pidgeot")
pidgey_line("pidgeot", "Pidgeot", 3, 10, 5)

-- Rattata line: retrigger the first N scoring cards once more.
local function rattata_line(key, name, rarity, cost, first, rounds, evo_to)
    local text = {
        "Retrigger {C:attention}first",
        "{C:attention}#2#{} scored cards",
        "{C:attention}#1#{} additional time",
    }
    if evo_to then
        text[#text + 1] = "{C:inactive}(Evolves after {C:attention}#3#{C:inactive} rounds)"
    end
    local extra = { retriggers = 1, first = first }
    if rounds then extra.rounds = rounds end
    SMODS.Joker {
        key = key,
        sprite = key .. ".png",
        negative_sprite = key .. "_negative.png",
        loc_txt = {
            name = name,
            text = text,
        },
        loc_vars = function(self, info_queue, card)
            return { vars = { card.ability.extra.retriggers, card.ability.extra.first,
                card.ability.extra.rounds } }
        end,
        rarity = rarity,
        cost = cost,
        config = { extra = extra },
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
            if evo_to then poke_level_evo(card, context, evo_to) end
        end,
    }
end
rattata_line("rattata", "Rattata", 1, 5, 2, 5, "j_pokep_raticate")
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
            "{C:inactive}(Evolves after {C:attention}#2#{C:inactive} rounds)",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult, card.ability.extra.rounds } }
    end,
    rarity = 1,
    cost = 5,
    config = { extra = { mult = 10, rounds = 4 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.joker_main and context.poker_hands
            and next(context.poker_hands["Straight"]) then
            return {
                mult_mod = card.ability.extra.mult,
                message = "+" .. card.ability.extra.mult .. " Mult",
            }
        end
        poke_level_evo(card, context, "j_pokep_arbok")
    end,
}

-- Arbok: +15 Mult on a Straight; if the scoring hand also contains an
-- Ace and there is consumable room, create a random Tarot card.
SMODS.Joker {
    key = "arbok",
    sprite = "arbok.png",
    negative_sprite = "arbok_negative.png",
    loc_txt = {
        name = "Arbok",
        text = {
            "{C:mult}+#1#{} Mult if played hand",
            "contains a {C:attention}Straight{}",
            "Create a {C:tarot}Tarot{} card",
            "if it also contains an {C:attention}Ace{}",
            "{C:inactive}(Must have room)",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult } }
    end,
    rarity = 2,
    cost = 7,
    config = { extra = { mult = 15 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.joker_main and context.poker_hands
            and next(context.poker_hands["Straight"]) then
            if not context.blueprint and context.scoring_hand then
                local has_ace = false
                for _, c in ipairs(context.scoring_hand) do
                    if c.get_id and c:get_id() == 14 then
                        has_ace = true
                        break
                    end
                end
                local used = G.consumables and #G.consumables or 0
                local cap = G.get_effective_consumable_capacity
                    and G:get_effective_consumable_capacity() or 2
                if has_ace and used < cap then
                    local id = G:random_consumable_id_of_kind("tarot", {}, "pokep_arbok")
                    if id then
                        SMODS.add_card { set = "Tarot", key = id }
                    end
                end
            end
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

-- Arcanine: X1.5 Mult on a Flush, and the first unenhanced scoring
-- card becomes a Mult card before it scores. (Fire Stone evolution.)
SMODS.Joker {
    key = "arcanine",
    sprite = "arcanine.png",
    negative_sprite = "arcanine_negative.png",
    loc_txt = {
        name = "Arcanine",
        text = {
            "{X:mult,C:white} X#1# {} Mult if played",
            "hand contains a {C:attention}Flush{}",
            "First scoring card becomes",
            "a {C:attention}Mult{} card if unenhanced",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.xmult } }
    end,
    rarity = 3,
    cost = 8,
    config = { extra = { xmult = 1.5 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.before and not context.blueprint and context.poker_hands
            and next(context.poker_hands["Flush"]) and context.scoring_hand then
            for _, c in ipairs(context.scoring_hand) do
                if not c.debuff and (not c.enhancement or c.enhancement == "base")
                    and c.set_enhancement then
                    c:set_enhancement("mult")
                    return { message = "Mult!" }
                end
            end
        end
        if context.joker_main and context.poker_hands
            and next(context.poker_hands["Flush"]) then
            return {
                x_mult = card.ability.extra.xmult,
                message = "X" .. card.ability.extra.xmult .. " Mult",
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
            "{C:inactive}(Evolves after {C:attention}#3#{C:inactive} rounds)",
        },
    },
    loc_vars = function(self, info_queue, card)
        local tally = 0
        if G and G.count_cards_in_full_deck then
            tally = G:count_cards_in_full_deck(function(c)
                return c.enhancement == "glass"
            end)
        end
        return { vars = { card.ability.extra.chip_mod,
            card.ability.extra.chip_mod * tally, card.ability.extra.rounds } }
    end,
    rarity = 1,
    cost = 4,
    config = { extra = { chip_mod = 25, rounds = 4 } },
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
        poke_level_evo(card, context, "j_pokep_sandslash")
    end,
}

-- Sandslash: +40 Chips per Glass card in the full deck, and each
-- discarded Enhanced card has a 1 in 3 chance to become a Glass card.
SMODS.Joker {
    key = "sandslash",
    sprite = "sandslash.png",
    negative_sprite = "sandslash_negative.png",
    loc_txt = {
        name = "Sandslash",
        text = {
            "{C:chips}+#1#{} Chips for each {C:attention}Glass",
            "card in your {C:attention}full deck",
            "{C:inactive}(Currently {C:chips}+#2#{C:inactive} Chips)",
            "{C:green}#3# in #4#{} chance for each",
            "discarded {C:attention}Enhanced{} card",
            "to become a {C:attention}Glass{} card",
        },
    },
    loc_vars = function(self, info_queue, card)
        local tally = 0
        if G and G.count_cards_in_full_deck then
            tally = G:count_cards_in_full_deck(function(c)
                return c.enhancement == "glass"
            end)
        end
        return { vars = { card.ability.extra.chip_mod,
            card.ability.extra.chip_mod * tally, 1, 3 } }
    end,
    rarity = 3,
    cost = 6,
    config = { extra = { chip_mod = 40 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.discard and not context.blueprint then
            local oc = context.other_card
            if oc and oc.enhancement and oc.enhancement ~= "base"
                and oc.enhancement ~= "glass" and not oc.debuff then
                local hit = SMODS.pseudorandom_probability(
                    card, "poke_sandslash", 1, 3, "poke_sandslash")
                if hit and oc.set_enhancement then
                    oc:set_enhancement("glass")
                    return { message = "Glass!" }
                end
            end
            return
        end
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
            "{C:inactive}(Evolves after {C:attention}#3#{C:inactive} rounds)",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chips, card.ability.extra.mult,
            card.ability.extra.rounds } }
    end,
    rarity = 1,
    cost = 5,
    config = { extra = { chips = 60, mult = 4, rounds = 4 } },
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
        poke_level_evo(card, context, "j_pokep_dugtrio")
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

-- Clefable: played Clubs give Mult equal to +1 per Club scored so far
-- this round; the count builds as hands are played and resets at the
-- end of the round. (Moon Stone evolution.)
SMODS.Joker {
    key = "clefable",
    sprite = "clefable.png",
    negative_sprite = "clefable_negative.png",
    loc_txt = {
        name = "Clefable",
        text = {
            "Played {C:clubs}Club{} cards give",
            "{C:mult}+#1#{} Mult when scored for each",
            "{C:clubs}Club{} scored this round",
            "{C:inactive}(Currently {C:mult}+#2#{C:inactive} Mult)",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult_mod,
            card.ability.extra.mult_mod * (card.ability.extra.clubs_scored or 0) } }
    end,
    rarity = 3,
    cost = 10,
    config = { extra = { mult_mod = 1, clubs_scored = 0 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.before and not context.blueprint and context.scoring_hand then
            for _, c in ipairs(context.scoring_hand) do
                if c.is_suit and c:is_suit("Clubs") then
                    card.ability.extra.clubs_scored =
                        (card.ability.extra.clubs_scored or 0) + 1
                end
            end
        end
        if context.individual and context.cardarea == G.play then
            local oc = context.other_card
            local n = card.ability.extra.clubs_scored or 0
            if oc and not oc.debuff and oc:is_suit("Clubs") and n > 0 then
                local total = card.ability.extra.mult_mod * n
                return { mult = total, message = "+" .. total .. " Mult" }
            end
        end
        if context.end_of_round and not context.blueprint then
            card.ability.extra.clubs_scored = 0
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

-- Wigglytuff: played Spades give +2 Mult and Chips equal to 30 plus
-- the card's own Chips when scored. (Moon Stone evolution.)
SMODS.Joker {
    key = "wigglytuff",
    sprite = "wigglytuff.png",
    negative_sprite = "wigglytuff_negative.png",
    loc_txt = {
        name = "Wigglytuff",
        text = {
            "Played {C:spades}Spade{} cards give",
            "{C:mult}+#1#{} Mult and {C:chips}+#2#{} Chips plus",
            "the card's Chips when scored",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult, card.ability.extra.chips } }
    end,
    rarity = 3,
    cost = 10,
    config = { extra = { mult = 2, chips = 30 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            local oc = context.other_card
            if oc and not oc.debuff and oc:is_suit("Spades") then
                return {
                    mult = card.ability.extra.mult,
                    chips = card.ability.extra.chips + card_chip_value(oc),
                    message = "Tuff!",
                }
            end
        end
    end,
}

-- Tentacool / Tentacruel: played 10s give +Mult when scored.
local function tentacool_line(key, name, rarity, cost, mult, rounds, evo_to)
    local text = {
        "Each played {C:attention}10{} gives",
        "{C:mult}+#1#{} Mult when scored",
    }
    if evo_to then
        text[#text + 1] = "{C:inactive}(Evolves after {C:attention}#2#{C:inactive} rounds)"
    end
    local extra = { mult = mult }
    if rounds then extra.rounds = rounds end
    SMODS.Joker {
        key = key,
        sprite = key .. ".png",
        negative_sprite = key .. "_negative.png",
        loc_txt = {
            name = name,
            text = text,
        },
        loc_vars = function(self, info_queue, card)
            return { vars = { card.ability.extra.mult, card.ability.extra.rounds } }
        end,
        rarity = rarity,
        cost = cost,
        config = { extra = extra },
        blueprint_compat = true,
        calculate = function(self, card, context)
            if context.individual and context.cardarea == G.play then
                local oc = context.other_card
                if oc and not oc.debuff and oc:get_id() == 10 then
                    return { mult = card.ability.extra.mult, message = "+" .. card.ability.extra.mult .. " Mult" }
                end
            end
            if evo_to then poke_level_evo(card, context, evo_to) end
        end,
    }
end
tentacool_line("tentacool", "Tentacool", 1, 4, 7, 5, "j_pokep_tentacruel")
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
            "{C:inactive}(Evolves after {C:attention}#2#{C:inactive} rounds)",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chips, card.ability.extra.rounds } }
    end,
    rarity = 1,
    cost = 4,
    config = { extra = { chips = 20, rounds = 4 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            local oc = context.other_card
            if oc and not oc.debuff and oc:is_face() then
                return { chips = card.ability.extra.chips, message = "+" .. card.ability.extra.chips .. " Chips" }
            end
        end
        poke_level_evo(card, context, "j_pokep_kingler")
    end,
}

-- Kingler: played face cards give +20 Chips when scored, and every
-- scoring face card without an enhancement becomes a Bonus card
-- before it scores.
SMODS.Joker {
    key = "kingler",
    sprite = "kingler.png",
    negative_sprite = "kingler_negative.png",
    loc_txt = {
        name = "Kingler",
        text = {
            "Played {C:attention}face{} cards give",
            "{C:chips}+#1#{} Chips when scored and",
            "become {C:attention}Bonus{} cards if unenhanced",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chips } }
    end,
    rarity = 2,
    cost = 7,
    config = { extra = { chips = 20 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.before and not context.blueprint and context.scoring_hand then
            local changed = false
            for _, c in ipairs(context.scoring_hand) do
                if c.is_face and c:is_face() and not c.debuff
                    and (not c.enhancement or c.enhancement == "base")
                    and c.set_enhancement then
                    c:set_enhancement("bonus")
                    changed = true
                end
            end
            if changed then return { message = "Surf!" } end
        end
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
            "{C:inactive}(Evolves after {C:attention}#2#{C:inactive} rounds)",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.xmult, card.ability.extra.rounds } }
    end,
    rarity = 2,
    cost = 7,
    config = { extra = { xmult = 1.5, rounds = 4 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            local oc = context.other_card
            if oc and not oc.debuff and oc.enhancement == "steel" then
                return { x_mult = card.ability.extra.xmult, message = "X" .. card.ability.extra.xmult .. " Mult" }
            end
        end
        poke_level_evo(card, context, "j_pokep_magneton")
    end,
}

-- Magneton: played Steel cards give X1.5 Mult, plus X0.2 Mult for
-- each adjacent Metal Joker. The port has no Pokemon types; the only
-- Metal line in the pack is Magnemite/Magneton, so adjacency counts
-- those (see README port notes).
SMODS.Joker {
    key = "magneton",
    sprite = "magneton.png",
    negative_sprite = "magneton_negative.png",
    loc_txt = {
        name = "Magneton",
        text = {
            "Played {C:attention}Steel{} cards give",
            "{X:mult,C:white}X#1#{} Mult when scored,",
            "{X:mult,C:white}X#3#{} for each adjacent",
            "{C:inactive}Metal{} Joker",
            "{C:inactive}(Currently {X:mult,C:white}X#2#{C:inactive} Mult)",
        },
    },
    loc_vars = function(self, info_queue, card)
        local metal = 0
        local jokers = G and G.jokers or {}
        local idx
        for i, j in ipairs(jokers) do if j == card then idx = i break end end
        if idx then
            for _, n in ipairs({ jokers[idx - 1], jokers[idx + 1] }) do
                if n and n.def and (n.def.id == "j_pokep_magnemite"
                    or n.def.id == "j_pokep_magneton") then
                    metal = metal + 1
                end
            end
        end
        return { vars = { card.ability.extra.xmult_base,
            card.ability.extra.xmult_base + card.ability.extra.xmult_mod * metal,
            card.ability.extra.xmult_mod } }
    end,
    rarity = 3,
    cost = 8,
    config = { extra = { xmult_base = 1.5, xmult_mod = 0.2 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            local oc = context.other_card
            if oc and not oc.debuff and oc.enhancement == "steel" then
                local metal = 0
                local jokers = G.jokers or {}
                local idx
                for i, j in ipairs(jokers) do if j == card then idx = i break end end
                if idx then
                    for _, n in ipairs({ jokers[idx - 1], jokers[idx + 1] }) do
                        if n and n.def and (n.def.id == "j_pokep_magnemite"
                            or n.def.id == "j_pokep_magneton") then
                            metal = metal + 1
                        end
                    end
                end
                local total = card.ability.extra.xmult_base
                    + card.ability.extra.xmult_mod * metal
                return { x_mult = total, message = "X" .. total .. " Mult" }
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
local function goldeen_line(key, name, rarity, cost, retriggers, with_count_line, rounds, evo_to)
    local text = {
        "Retrigger all {C:attention}Gold{}",
        "card {C:attention}held in",
        "{C:attention}hand{} abilities",
    }
    if with_count_line then
        text[#text + 1] = "{C:attention}#1#{} additional times"
    end
    if evo_to then
        text[#text + 1] = "{C:inactive}(Evolves after {C:attention}#2#{C:inactive} rounds)"
    end
    local extra = { retriggers = retriggers }
    if rounds then extra.rounds = rounds end
    SMODS.Joker {
        key = key,
        sprite = key .. ".png",
        negative_sprite = key .. "_negative.png",
        loc_txt = { name = name, text = text },
        loc_vars = function(self, info_queue, card)
            return { vars = { card.ability.extra.retriggers,
                card.ability.extra.rounds } }
        end,
        rarity = rarity,
        cost = cost,
        config = { extra = extra },
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
            if evo_to then poke_level_evo(card, context, evo_to) end
        end,
    }
end
goldeen_line("goldeen", "Goldeen", 1, 5, 1, false, 5, "j_pokep_seaking")
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

-- Raichu: +4 Mult for each $10 you have, and earn interest when a
-- Blind is selected. (Thunder Stone evolution.)
SMODS.Joker {
    key = "raichu",
    sprite = "raichu.png",
    negative_sprite = "raichu_negative.png",
    loc_txt = {
        name = "Raichu",
        text = {
            "{C:mult}+#1#{} Mult for each",
            "{C:money}$10{} you have",
            "{C:inactive}(Currently {C:mult}+#2#{C:inactive} Mult)",
            "Earn {C:attention}interest{} when",
            "{C:attention}Blind{} is selected",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = {
            card.ability.extra.mult_mod,
            card.ability.extra.mult_mod
                * math.floor(math.max(0, tonumber(G and G.money) or 0) / 10),
        } }
    end,
    rarity = 3,
    cost = 8,
    config = { extra = { mult_mod = 4 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.setting_blind then
            local cap = G.get_interest_round_cap_dollars
                and G:get_interest_round_cap_dollars() or 5
            local interest = math.min(
                math.floor(math.max(0, tonumber(G.money) or 0) / 5), cap)
            if interest > 0 then return { dollars = interest } end
        end
        if context.joker_main then
            local total = card.ability.extra.mult_mod
                * math.floor(math.max(0, tonumber(G.money) or 0) / 10)
            if total > 0 then
                return { mult_mod = total, message = "+" .. total .. " Mult" }
            end
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

--------------------------------------------------------------------------------
-- Evolution stones (fork SMODS.ConsumableType; pack v1.2.0, targeting v1.3.0)
--------------------------------------------------------------------------------
-- PC Pokermon registers its items under its own consumable type
-- ("consumable types/type1.lua": key "poke_item", name "Item",
-- shop_rate 4) and the stones are consumables of that set
-- ("consumables/03_mart_items.lua": cost 4, evo_item = true). The fork's
-- SMODS.ConsumableType is the same registration with the same rate
-- units (Tarot and Planet weigh 4), so the stones below are registered
-- exactly as on PC and roll in the shop as their own kind. Since the
-- fork's Tier 3 API the kind also gets a collection category, and the
-- Item Pack booster registered below (pool = poke_item) deals stones
-- the way PC's Item packs do. The booster carries no sprite: the pack
-- has no pack-wrapper art (its card art was sliced from the NatDex
-- atlas, and PC Pokermon's own pack art lives in its repo, not here),
-- so the engine draws its plain booster fallback panel -- noted in
-- README.txt.
--
-- Which stones: exactly the ones that evolve Jokers in this pack
-- (PC "item_req" on the base forms): Fire (Growlithe), Water
-- (Shellder), Thunder (Pikachu) and Moon (Clefairy, Jigglypuff). The
-- Leaf Stone is not ported: its Gen 1 targets (Gloom, Weepinbell,
-- Exeggcute) are not in the pack. Magneton is NOT a Thunder Stone
-- target here: on PC it evolves into Magnezone, which is not in the
-- pack, so the stone refuses it.
--
-- Targeting: since v1.3.0 the stones declare `target_joker = true`
-- (fork Tier 3). The player chooses the Joker -- the tooltip-open
-- Joker, or the gamepad-focused one -- and can_use accepts only that
-- Joker, when it is held, is not debuffed, and is a pre-form this
-- stone evolves (Moon Stone: either of its two lines). Using the
-- stone evolves the CHOSEN Joker on the spot through poke_evolve
-- (the same call the level/scaling chains use, so the edition and any
-- kept scaling carry the same way). The stones' secondary
-- playing-card effects (Fire: Mult cards, Water: Bonus cards,
-- Thunder: Gold copies, Moon: poker-hand upgrade) are not ported.
--
-- On the stock game SMODS.ConsumableType does not exist: this whole
-- block is skipped, no stones register, and the pack behaves exactly
-- as in v1.1.0.

if SMODS.ConsumableType then
    SMODS.ConsumableType {
        key = "poke_item",
        loc_txt = { name = "Item" },
        shop_rate = 4,
    }

    -- Base Joker id -> the stone that evolves it, and -> its evolved
    -- form (PC item_req / the chains documented at the top of this file).
    local STONE_OF = {
        j_pokep_growlithe = "firestone",
        j_pokep_shellder = "waterstone",
        j_pokep_pikachu = "thunderstone",
        j_pokep_clefairy = "moonstone",
        j_pokep_jigglypuff = "moonstone",
    }
    local STONE_EVOLUTION = {
        j_pokep_growlithe = "j_pokep_arcanine",
        j_pokep_shellder = "j_pokep_cloyster",
        j_pokep_pikachu = "j_pokep_raichu",
        j_pokep_clefairy = "j_pokep_clefable",
        j_pokep_jigglypuff = "j_pokep_wigglytuff",
    }

    -- Is `target` a Joker this stone may evolve right now: the right
    -- pre-form, actually held, and not debuffed (as on PC)? The
    -- engine only ever resolves held Jokers as targets, but the held
    -- check keeps can_use honest when called directly.
    local function stone_target_ok(stone_key, target)
        if type(target) ~= "table" or not target.def then return false end
        if STONE_OF[target.def.id] ~= stone_key then return false end
        if target.debuff == true or target.debuffed == true then return false end
        local jokers = G and G.jokers
        if type(jokers) ~= "table" then return false end
        for _, j in ipairs(jokers) do
            if j == target then return true end
        end
        return false
    end

    local function evolution_stone(key, name, text)
        SMODS.Consumable {
            set = "poke_item",
            key = key,
            sprite = key .. ".png",
            negative_sprite = key .. "_negative.png",
            loc_txt = { name = name, text = text },
            cost = 4,
            target_joker = true,
            can_use = function(self, card, target)
                return stone_target_ok(key, target)
            end,
            use = function(self, card, area, copier, target)
                if stone_target_ok(key, target) then
                    poke_evolve(target, STONE_EVOLUTION[target.def.id])
                end
            end,
        }
    end

    evolution_stone("firestone", "Fire Stone", {
        "{C:attention}Evolution Card{}",
        "Evolves the {C:attention}chosen Growlithe{}",
        "into {C:attention}Arcanine{}",
        "{C:inactive}(Open a Joker's tooltip, then use){}",
    })
    evolution_stone("waterstone", "Water Stone", {
        "{C:attention}Evolution Card{}",
        "Evolves the {C:attention}chosen Shellder{}",
        "into {C:attention}Cloyster{}",
        "{C:inactive}(Open a Joker's tooltip, then use){}",
    })
    evolution_stone("thunderstone", "Thunder Stone", {
        "{C:attention}Evolution Card{}",
        "Evolves the {C:attention}chosen Pikachu{}",
        "into {C:attention}Raichu{}",
        "{C:inactive}(Open a Joker's tooltip, then use){}",
    })
    evolution_stone("moonstone", "Moon Stone", {
        "{C:attention}Evolution Card{}",
        "Evolves the {C:attention}chosen Clefairy{} into",
        "{C:attention}Clefable{}, or the {C:attention}chosen Jigglypuff{}",
        "into {C:attention}Wigglytuff{}",
        "{C:inactive}(Open a Joker's tooltip, then use){}",
    })

    -- Item Pack: on PC the stones also reach the player through Item
    -- packs. Registered without a sprite (no pack-wrapper art exists
    -- in this pack), so the shop shows the engine's plain booster
    -- fallback panel. Guarded separately: an older fork build could
    -- have ConsumableType without Booster.
    if SMODS.Booster then
        SMODS.Booster {
            key = "itempack",
            loc_txt = {
                name = "Item Pack",
                text = { "Choose {C:attention}1{} of {C:attention}3{} Item cards" },
            },
            pool = { consumable = "poke_item" },
            card_count = 3,
            picks = 1,
            cost = 4,
            weight = 100,
            colour = { 0.95, 0.8, 0.25 },
        }
    end
end
