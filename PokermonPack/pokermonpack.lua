-- PokermonPack: 145 Gen 1 Pokemon Jokers ported from Pokermon (PC, SMODS)
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
--   * v1.4.0 (Wave 4) completes the non-Mega Gen 1 roster: 95 more
--     Jokers (Spearow..Mew) under the same rules. The Leaf Stone
--     joins the other four stones, and the stone target maps are now
--     keyed by stone so Eevee branches (Fire/Water/Thunder). Still
--     not ported, with reasons in README.txt: Chansey, Jynx, Ditto,
--     Porygon, Snorlax, Moltres, Missingno, Farfetch'd (8), the aux
--     Shell trigger (not a Joker), and all 22 Mega evolutions (the
--     Mega framework is a later wave).

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
-- Wave 4 (pack v1.4.0): the remaining Gen 1 lines -- Spearow..Mew.
-- 95 more Jokers ported from the same PC source (pokejokers_01..05),
-- under the same rules as the lines above: energy stripped, base
-- values kept, "poke_safari" rarity -> Rare (3). Per-Joker named
-- deviations are in README.txt and the wave census. Stone pre-forms
-- among them (Vulpix, Nidorina, Nidorino, Poliwhirl, Staryu, Eevee,
-- Gloom, Weepinbell, Exeggcute) do not self-evolve; the stone block
-- at the bottom wires them, Eevee branching to three stones.
--------------------------------------------------------------------------------

-- PokermonPack Wave 4 fragment (Part B): Spearow..Poliwag Gen 1 lines
-- ported from Pokermon (PC, SMODS) by InertSteak,
-- https://github.com/InertSteak/Pokermon (GPLv3), pokemon/pokejokers_01.lua
-- and pokejokers_02.lua.
--
-- Fragment: expects the pack helpers flat_mult / flat_chips /
-- poke_evolve / poke_level_evo / poke_scaling_evo / card_chip_value in
-- scope at the integration point (defined at the top of
-- pokermonpack.lua). Energy is stripped everywhere, per pack design.
-- "poke_safari" rarity maps to Rare (3). Deviations are named per def
-- below and in census_poke_1.md; nothing is silently approximated.

-- Spearow: after drawing 30 cards during Blinds, the next played hand
-- is levelled up; evolves after triggering that 3 times. PC spends the
-- stored upgrade in `before` and levels the hand there; the port
-- spends it in `before` and returns level_up at joker_main (the
-- Teacup pattern: the fork's reader adds the level delta to the
-- running totals, same final numbers). The juice-until-active
-- cosmetic is dropped.
SMODS.Joker {
    key = "spearow",
    sprite = "spearow.png",
    negative_sprite = "spearow_negative.png",
    loc_txt = {
        name = "Spearow",
        text = {
            "After drawing {C:attention}#2#{} {C:inactive}[#3#]{} cards",
            "during {C:attention}Blinds{}, upgrade level",
            "of next played {C:attention}poker hand{}{C:inactive}#4#{}",
            "{C:inactive}(Evolves after triggering {C:attention}#1#{C:inactive} times)",
        },
    },
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        return { vars = {
            math.max(0, 3 - (e.triggers or 0)),
            e.card_threshold,
            math.max(0, e.card_threshold - (e.cards_drawn or 0)),
            e.upgrade and "(Active!)" or "",
        } }
    end,
    rarity = 1,
    cost = 4,
    config = { extra = { triggers = 0, card_threshold = 30, cards_drawn = 0,
        upgrade = false, pending = false } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        local e = card.ability.extra
        if context.hand_drawn and not context.blueprint then
            e.cards_drawn = (e.cards_drawn or 0) + #context.hand_drawn
            if e.cards_drawn >= e.card_threshold then
                e.upgrade = true
                e.cards_drawn = e.cards_drawn % e.card_threshold
            end
        end
        if context.before and not context.blueprint and e.upgrade then
            e.upgrade = false
            e.pending = true
            e.triggers = (e.triggers or 0) + 1
        end
        if context.joker_main and e.pending then
            e.pending = false
            return { level_up = 1, message = "Level Up!" }
        end
        poke_scaling_evo(card, context, "j_pokep_fearow", e.triggers, 3)
    end,
}

-- Fearow: Spearow's upgrade with no further evolution, plus +1
-- discard as a native config modifier (PC add_to_deck bumps the
-- round's discards). (Spearow evolution.)
SMODS.Joker {
    key = "fearow",
    sprite = "fearow.png",
    negative_sprite = "fearow_negative.png",
    loc_txt = {
        name = "Fearow",
        text = {
            "{C:red}+#4#{} discard",
            "After drawing {C:attention}#1#{} {C:inactive}[#2#]{} cards",
            "during {C:attention}Blinds{}, upgrade level",
            "of next played {C:attention}poker hand{}{C:inactive}#3#{}",
        },
    },
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        return { vars = {
            e.card_threshold,
            math.max(0, e.card_threshold - (e.cards_drawn or 0)),
            e.upgrade and "(Active!)" or "",
            card.ability.d_size,
        } }
    end,
    rarity = 3,
    cost = 6,
    config = { d_size = 1, extra = { card_threshold = 30, cards_drawn = 0,
        upgrade = false, pending = false } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        local e = card.ability.extra
        if context.hand_drawn and not context.blueprint then
            e.cards_drawn = (e.cards_drawn or 0) + #context.hand_drawn
            if e.cards_drawn >= e.card_threshold then
                e.upgrade = true
                e.cards_drawn = e.cards_drawn % e.card_threshold
            end
        end
        if context.before and not context.blueprint and e.upgrade then
            e.upgrade = false
            e.pending = true
        end
        if context.joker_main and e.pending then
            e.pending = false
            return { level_up = 1, message = "Level Up!" }
        end
    end,
}

-- Nidoran F: each Queen held in hand gives +50 Chips.
SMODS.Joker {
    key = "nidoranf",
    sprite = "nidoranf.png",
    negative_sprite = "nidoranf_negative.png",
    loc_txt = {
        name = "Nidoran F",
        text = {
            "Each {C:attention}Queen{} held in hand",
            "gives {C:chips}+#1#{} Chips",
            "{C:inactive}(Evolves after {C:attention}#2#{C:inactive} rounds)",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chips, card.ability.extra.rounds } }
    end,
    rarity = 1,
    cost = 4,
    config = { extra = { chips = 50, rounds = 4 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.hand
            and not context.end_of_round then
            local oc = context.other_card
            if oc and oc:get_id() == 12 then
                if oc.debuff then return { message = "Debuffed!" } end
                return { h_chips = card.ability.extra.chips }
            end
        end
        poke_level_evo(card, context, "j_pokep_nidorina")
    end,
}

-- Nidorina: each Queen held in hand gives +75 Chips.
-- (Moon Stone evolution.)
SMODS.Joker {
    key = "nidorina",
    sprite = "nidorina.png",
    negative_sprite = "nidorina_negative.png",
    loc_txt = {
        name = "Nidorina",
        text = {
            "Each {C:attention}Queen{} held in hand",
            "gives {C:chips}+#1#{} Chips",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chips } }
    end,
    rarity = 3,
    cost = 7,
    config = { extra = { chips = 75 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.hand
            and not context.end_of_round then
            local oc = context.other_card
            if oc and oc:get_id() == 12 then
                if oc.debuff then return { message = "Debuffed!" } end
                return { h_chips = card.ability.extra.chips }
            end
        end
    end,
}

-- Nidoqueen: +1 hand size (native config modifier; PC changes hand
-- size in add/remove_from_deck) and each Queen held in hand gives
-- +90 Chips. (Moon Stone evolution.)
SMODS.Joker {
    key = "nidoqueen",
    sprite = "nidoqueen.png",
    negative_sprite = "nidoqueen_negative.png",
    loc_txt = {
        name = "Nidoqueen",
        text = {
            "{C:attention}+#2#{} hand size",
            "Each {C:attention}Queen{} held in hand",
            "gives {C:chips}+#1#{} Chips",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chips, card.ability.h_size } }
    end,
    rarity = 3,
    cost = 10,
    config = { h_size = 1, extra = { chips = 90 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.hand
            and not context.end_of_round then
            local oc = context.other_card
            if oc and oc:get_id() == 12 then
                if oc.debuff then return { message = "Debuffed!" } end
                return { h_chips = card.ability.extra.chips }
            end
        end
    end,
}

-- Nidoran M: each King held in hand gives +8 Mult.
SMODS.Joker {
    key = "nidoranm",
    sprite = "nidoranm.png",
    negative_sprite = "nidoranm_negative.png",
    loc_txt = {
        name = "Nidoran M",
        text = {
            "Each {C:attention}King{} held in hand",
            "gives {C:mult}+#1#{} Mult",
            "{C:inactive}(Evolves after {C:attention}#2#{C:inactive} rounds)",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult, card.ability.extra.rounds } }
    end,
    rarity = 1,
    cost = 5,
    config = { extra = { mult = 8, rounds = 4 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.hand
            and not context.end_of_round then
            local oc = context.other_card
            if oc and oc:get_id() == 13 then
                if oc.debuff then return { message = "Debuffed!" } end
                return { h_mult = card.ability.extra.mult }
            end
        end
        poke_level_evo(card, context, "j_pokep_nidorino")
    end,
}

-- Nidorino: each King held in hand gives +12 Mult.
-- (Moon Stone evolution.)
SMODS.Joker {
    key = "nidorino",
    sprite = "nidorino.png",
    negative_sprite = "nidorino_negative.png",
    loc_txt = {
        name = "Nidorino",
        text = {
            "Each {C:attention}King{} held in hand",
            "gives {C:mult}+#1#{} Mult",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult } }
    end,
    rarity = 3,
    cost = 7,
    config = { extra = { mult = 12 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.hand
            and not context.end_of_round then
            local oc = context.other_card
            if oc and oc:get_id() == 13 then
                if oc.debuff then return { message = "Debuffed!" } end
                return { h_mult = card.ability.extra.mult }
            end
        end
    end,
}

-- Nidoking: +1 hand size (native config modifier) and each King held
-- in hand gives +15 Mult. (Moon Stone evolution.)
SMODS.Joker {
    key = "nidoking",
    sprite = "nidoking.png",
    negative_sprite = "nidoking_negative.png",
    loc_txt = {
        name = "Nidoking",
        text = {
            "{C:attention}+#2#{} hand size",
            "Each {C:attention}King{} held in hand",
            "gives {C:mult}+#1#{} Mult",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult, card.ability.h_size } }
    end,
    rarity = 3,
    cost = 10,
    config = { h_size = 1, extra = { mult = 15 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.hand
            and not context.end_of_round then
            local oc = context.other_card
            if oc and oc:get_id() == 13 then
                if oc.debuff then return { message = "Debuffed!" } end
                return { h_mult = card.ability.extra.mult }
            end
        end
    end,
}

-- Vulpix: each played 9 has a 1 in 3 chance to create a Tarot card
-- when scored (room check and random Tarot follow the pack's Arbok).
-- (Fire Stone evolution.)
SMODS.Joker {
    key = "vulpix",
    sprite = "vulpix.png",
    negative_sprite = "vulpix_negative.png",
    loc_txt = {
        name = "Vulpix",
        text = {
            "{C:green}#1# in #2#{} chance for each",
            "played {C:attention}9{} to create a",
            "{C:tarot}Tarot{} card when scored",
            "{C:inactive}(Must have room)",
        },
    },
    loc_vars = function(self, info_queue, card)
        local num, dem = SMODS.get_probability_vars(card,
            card.ability.extra.num, card.ability.extra.dem, "vulpix")
        return { vars = { num, dem } }
    end,
    rarity = 1,
    cost = 4,
    config = { extra = { num = 1, dem = 3 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            local oc = context.other_card
            if oc and not oc.debuff and oc:get_id() == 9 then
                local hit = SMODS.pseudorandom_probability(card,
                    "poke_vulpix", card.ability.extra.num,
                    card.ability.extra.dem, "poke_vulpix")
                if hit and G and G.random_consumable_id_of_kind then
                    local used = G.consumables and #G.consumables or 0
                    local cap = G.get_effective_consumable_capacity
                        and G:get_effective_consumable_capacity() or 2
                    if used < cap then
                        local id = G:random_consumable_id_of_kind(
                            "tarot", {}, "pokep_vulpix")
                        if id then
                            SMODS.add_card { set = "Tarot", key = id }
                            return { message = "+ Tarot!" }
                        end
                    end
                end
            end
        end
    end,
}

-- Ninetales: Vulpix's Tarot chance at 1 in 2. DEVIATION: PC also
-- grants a Negative Medium on add_to_deck (the "holding" mechanic);
-- that held-item grant is dropped, the scoring mechanic is the def.
-- (Fire Stone evolution.)
SMODS.Joker {
    key = "ninetales",
    sprite = "ninetales.png",
    negative_sprite = "ninetales_negative.png",
    loc_txt = {
        name = "Ninetales",
        text = {
            "{C:green}#1# in #2#{} chance for each",
            "played {C:attention}9{} to create a",
            "{C:tarot}Tarot{} card when scored",
            "{C:inactive}(Must have room)",
        },
    },
    loc_vars = function(self, info_queue, card)
        local num, dem = SMODS.get_probability_vars(card,
            card.ability.extra.num, card.ability.extra.dem, "ninetales")
        return { vars = { num, dem } }
    end,
    rarity = 3,
    cost = 8,
    config = { extra = { num = 1, dem = 2 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            local oc = context.other_card
            if oc and not oc.debuff and oc:get_id() == 9 then
                local hit = SMODS.pseudorandom_probability(card,
                    "poke_ninetales", card.ability.extra.num,
                    card.ability.extra.dem, "poke_ninetales")
                if hit and G and G.random_consumable_id_of_kind then
                    local used = G.consumables and #G.consumables or 0
                    local cap = G.get_effective_consumable_capacity
                        and G:get_effective_consumable_capacity() or 2
                    if used < cap then
                        local id = G:random_consumable_id_of_kind(
                            "tarot", {}, "pokep_ninetales")
                        if id then
                            SMODS.add_card { set = "Tarot", key = id }
                            return { message = "+ Tarot!" }
                        end
                    end
                end
            end
        end
    end,
}

-- Zubat: the first scoring Enhanced card loses its Enhancement and
-- Zubat gains +2 Mult permanently; evolves at +12 Mult. PC removes
-- the enhancement via set_ability(c_base); the port uses the node's
-- set_enhancement(nil), the canonical clearer.
SMODS.Joker {
    key = "zubat",
    sprite = "zubat.png",
    negative_sprite = "zubat_negative.png",
    loc_txt = {
        name = "Zubat",
        text = {
            "Gains {C:mult}+#2#{} Mult if played hand",
            "contains a scoring {C:attention}Enhanced{} card,",
            "removes card {C:attention}Enhancement{} from",
            "first scoring {C:attention}Enhanced{} card",
            "{C:inactive}(Evolves at {C:mult}+#1#{C:inactive} / +#3# Mult)",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult,
            card.ability.extra.mult_mod, 12 } }
    end,
    rarity = 1,
    cost = 5,
    perishable_compat = false,
    config = { extra = { mult = 0, mult_mod = 2 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        local e = card.ability.extra
        if context.before and not context.blueprint and context.scoring_hand then
            for _, c in ipairs(context.scoring_hand) do
                local enh = c.enhancement
                    or (c.card_data and c.card_data.enhancement)
                if enh and enh ~= "base" and not c.debuff then
                    if c.set_enhancement then c:set_enhancement(nil) end
                    e.mult = e.mult + e.mult_mod
                    return { message = "+" .. e.mult_mod .. " Mult" }
                end
            end
        end
        if context.joker_main and e.mult > 0 then
            return { mult_mod = e.mult, message = "+" .. e.mult .. " Mult" }
        end
        poke_scaling_evo(card, context, "j_pokep_golbat", e.mult, 12)
    end,
}

-- Golbat: EVERY scoring Enhanced card loses its Enhancement, +2 Mult
-- each. DEVIATION: PC evolves into Crobat (Gen 2) after eating 16
-- Enhancements; Crobat is not in this Gen 1 pack, so the evolution,
-- the eaten counter and the evolves text line are dropped.
SMODS.Joker {
    key = "golbat",
    sprite = "golbat.png",
    negative_sprite = "golbat_negative.png",
    loc_txt = {
        name = "Golbat",
        text = {
            "Gains {C:mult}+#2#{} Mult for each",
            "{C:attention}Enhanced{} card in poker hand,",
            "removes card {C:attention}Enhancement{}",
            "{C:inactive}(Currently {C:mult}+#1#{C:inactive} Mult)",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult,
            card.ability.extra.mult_mod } }
    end,
    rarity = 3,
    cost = 8,
    perishable_compat = false,
    config = { extra = { mult = 0, mult_mod = 2 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        local e = card.ability.extra
        if context.before and not context.blueprint and context.scoring_hand then
            local eaten = 0
            for _, c in ipairs(context.scoring_hand) do
                local enh = c.enhancement
                    or (c.card_data and c.card_data.enhancement)
                if enh and enh ~= "base" and not c.debuff then
                    if c.set_enhancement then c:set_enhancement(nil) end
                    eaten = eaten + 1
                end
            end
            if eaten > 0 then
                e.mult = e.mult + e.mult_mod * eaten
                return { message = "+" .. (e.mult_mod * eaten) .. " Mult" }
            end
        end
        if context.joker_main and e.mult > 0 then
            return { mult_mod = e.mult, message = "+" .. e.mult .. " Mult" }
        end
    end,
}

-- Oddish: played cards with an odd rank (Ace, 3, 5, 7, 9 -- PC
-- pokermon.is_odd) give a random +1, +3 or +5 Mult when scored.
SMODS.Joker {
    key = "oddish",
    sprite = "oddish.png",
    negative_sprite = "oddish_negative.png",
    loc_txt = {
        name = "Oddish",
        text = {
            "Played cards with {C:attention}odd{}",
            "rank give {C:mult}+#1#{}, {C:mult}+#4#{}, or",
            "{C:mult}+#2#{} Mult when scored",
            "{C:inactive}(Evolves after {C:attention}#3#{C:inactive} rounds)",
        },
    },
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        return { vars = { e.mult, e.mult2, e.rounds, e.mult1 } }
    end,
    rarity = 1,
    cost = 4,
    config = { extra = { mult = 1, mult1 = 3, mult2 = 5, rounds = 4 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            local oc = context.other_card
            if oc and not oc.debuff then
                local id = oc:get_id()
                if id == 14 or id == 3 or id == 5 or id == 7 or id == 9 then
                    local e = card.ability.extra
                    local roll = pseudorandom("poke_oddish")
                    local value = roll < (1 / 3) and e.mult
                        or (roll < (2 / 3) and e.mult1 or e.mult2)
                    return { mult = value, message = "+" .. value .. " Mult" }
                end
            end
        end
        poke_level_evo(card, context, "j_pokep_gloom")
    end,
}

-- Gloom: Oddish's odd-rank roll at +3, +5 or +7 Mult.
-- (Stone evolution: Leaf Stone to Vileplume; PC's alternate Sun
-- Stone target, Bellossom, is Gen 2 and not in this pack.)
SMODS.Joker {
    key = "gloom",
    sprite = "gloom.png",
    negative_sprite = "gloom_negative.png",
    loc_txt = {
        name = "Gloom",
        text = {
            "Played cards with {C:attention}odd{}",
            "rank give {C:mult}+#1#{}, {C:mult}+#3#{}, or",
            "{C:mult}+#2#{} Mult when scored",
        },
    },
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        return { vars = { e.mult, e.mult2, e.mult1 } }
    end,
    rarity = 2,
    cost = 6,
    config = { extra = { mult = 3, mult1 = 5, mult2 = 7 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            local oc = context.other_card
            if oc and not oc.debuff then
                local id = oc:get_id()
                if id == 14 or id == 3 or id == 5 or id == 7 or id == 9 then
                    local e = card.ability.extra
                    local roll = pseudorandom("poke_gloom")
                    local value = roll < (1 / 3) and e.mult
                        or (roll < (2 / 3) and e.mult1 or e.mult2)
                    return { mult = value, message = "+" .. value .. " Mult" }
                end
            end
        end
    end,
}

-- Vileplume: played odd-rank cards give a random +7 Mult, X1.3 Mult
-- or X1.5 Mult when scored. (Leaf Stone evolution.)
SMODS.Joker {
    key = "vileplume",
    sprite = "vileplume.png",
    negative_sprite = "vileplume_negative.png",
    loc_txt = {
        name = "Vileplume",
        text = {
            "Played cards with {C:attention}odd{}",
            "rank give {C:mult}+#2#{}, {X:mult,C:white}X#3#{}, or",
            "{X:mult,C:white}X#1#{} Mult when scored",
        },
    },
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        return { vars = { e.Xmult_multi, e.mult, e.Xmult_multi2 } }
    end,
    rarity = 3,
    cost = 10,
    config = { extra = { Xmult_multi = 1.5, mult = 7, Xmult_multi2 = 1.3 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            local oc = context.other_card
            if oc and not oc.debuff then
                local id = oc:get_id()
                if id == 14 or id == 3 or id == 5 or id == 7 or id == 9 then
                    local e = card.ability.extra
                    local roll = pseudorandom("poke_vileplume")
                    if roll < (1 / 3) then
                        return { mult = e.mult,
                            message = "+" .. e.mult .. " Mult" }
                    elseif roll < (2 / 3) then
                        return { x_mult = e.Xmult_multi2,
                            message = "X" .. e.Xmult_multi2 .. " Mult" }
                    else
                        return { x_mult = e.Xmult_multi,
                            message = "X" .. e.Xmult_multi .. " Mult" }
                    end
                end
            end
        end
    end,
}

-- Paras: gains +1 Mult permanently whenever a played hand contains
-- a Two Pair; evolves at +8 Mult.
SMODS.Joker {
    key = "paras",
    sprite = "paras.png",
    negative_sprite = "paras_negative.png",
    loc_txt = {
        name = "Paras",
        text = {
            "Gains {C:mult}+#2#{} Mult if played",
            "hand contains a {C:attention}Two Pair{}",
            "{C:inactive}(Evolves at {C:mult}+#1#{C:inactive} / +8 Mult)",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult,
            card.ability.extra.mult_mod } }
    end,
    rarity = 1,
    cost = 5,
    perishable_compat = false,
    config = { extra = { mult = 0, mult_mod = 1 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        local e = card.ability.extra
        if context.before and not context.blueprint and context.poker_hands
            and next(context.poker_hands["Two Pair"]) then
            e.mult = e.mult + e.mult_mod
            return { message = "+" .. e.mult_mod .. " Mult" }
        end
        if context.joker_main and e.mult > 0 then
            return { mult_mod = e.mult, message = "+" .. e.mult .. " Mult" }
        end
        poke_scaling_evo(card, context, "j_pokep_parasect", e.mult, 8)
    end,
}

-- Parasect: gains +3 Mult on a Two Pair, loses 2 Mult (min 0) on
-- any other played hand.
SMODS.Joker {
    key = "parasect",
    sprite = "parasect.png",
    negative_sprite = "parasect_negative.png",
    loc_txt = {
        name = "Parasect",
        text = {
            "Gains {C:mult}+#2#{} Mult if played",
            "hand contains a {C:attention}Two Pair{}",
            "{C:mult}-#3#{} Mult otherwise",
            "{C:inactive}(Currently {C:mult}+#1#{C:inactive} Mult)",
        },
    },
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        return { vars = { e.mult, e.mult_mod, e.mult_mod2 } }
    end,
    rarity = 2,
    cost = 8,
    perishable_compat = false,
    config = { extra = { mult = 0, mult_mod = 3, mult_mod2 = 2 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        local e = card.ability.extra
        if context.before and not context.blueprint and context.poker_hands then
            if next(context.poker_hands["Two Pair"]) then
                e.mult = e.mult + e.mult_mod
                return { message = "+" .. e.mult_mod .. " Mult" }
            elseif e.mult > 0 then
                e.mult = math.max(0, e.mult - e.mult_mod2)
                return { message = "-" .. e.mult_mod2 .. " Mult" }
            end
        end
        if context.joker_main and e.mult > 0 then
            return { mult_mod = e.mult, message = "+" .. e.mult .. " Mult" }
        end
    end,
}

-- Venonat: adds +1 to the numerator of all listed probabilities
-- (the fork's mod_probability return is absolute, so the port
-- returns context.numerator + 1, as PC does).
SMODS.Joker {
    key = "venonat",
    sprite = "venonat.png",
    negative_sprite = "venonat_negative.png",
    loc_txt = {
        name = "Venonat",
        text = {
            "Adds {C:attention}#1#{} to all {C:attention}listed",
            "{C:green}probabilities{}",
            "{C:inactive}(ex: {C:green}1 in 6{C:inactive} -> {C:green}2 in 6{C:inactive})",
            "{C:inactive}(Evolves after {C:attention}#2#{C:inactive} rounds)",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.plus_odds,
            card.ability.extra.rounds } }
    end,
    rarity = 2,
    cost = 4,
    config = { extra = { plus_odds = 1, rounds = 5 } },
    blueprint_compat = false,
    calculate = function(self, card, context)
        if context.mod_probability and not context.blueprint then
            return { numerator = (tonumber(context.numerator) or 0)
                + card.ability.extra.plus_odds }
        end
        poke_level_evo(card, context, "j_pokep_venomoth")
    end,
}

-- Venomoth: adds +2 to the numerator of all listed probabilities.
SMODS.Joker {
    key = "venomoth",
    sprite = "venomoth.png",
    negative_sprite = "venomoth_negative.png",
    loc_txt = {
        name = "Venomoth",
        text = {
            "Adds {C:attention}#1#{} to all {C:attention}listed",
            "{C:green}probabilities{}",
            "{C:inactive}(ex: {C:green}1 in 6{C:inactive} -> {C:green}3 in 6{C:inactive})",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.plus_odds } }
    end,
    rarity = 3,
    cost = 7,
    config = { extra = { plus_odds = 2 } },
    blueprint_compat = false,
    calculate = function(self, card, context)
        if context.mod_probability and not context.blueprint then
            return { numerator = (tonumber(context.numerator) or 0)
                + card.ability.extra.plus_odds }
        end
    end,
}

-- Meowth: pays out at end of round; the first successful Lucky card
-- trigger each round raises the payout by $2. PC keys off the Lucky
-- card's lucky_trigger flag on the scored card, which the fork does
-- not raise for mod Jokers; the port keys off the fork's
-- probability_success context for the Lucky rolls (identifiers
-- lucky_mult / lucky_money), capped at the same 1 trigger per round
-- by extra.limit, so the net payout growth matches. PC's
-- "{br:2}ERROR - CONTACT STEAK" placeholder line is not ported.
-- Evolves when the payout reaches $9.
SMODS.Joker {
    key = "meowth",
    sprite = "meowth.png",
    negative_sprite = "meowth_negative.png",
    loc_txt = {
        name = "Meowth",
        text = {
            "Earn {C:money}$#1#{} at end of round",
            "First {C:green}successful{} {C:attention}Lucky{}",
            "card trigger each round",
            "increases payout by {C:money}$#2#{}",
            "{C:inactive}(Evolves at {C:money}$#1#{C:inactive} / $#3# payout)",
        },
    },
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        return { vars = { e.money, e.money_mod, 9 } }
    end,
    rarity = 1,
    cost = 5,
    perishable_compat = false,
    config = { extra = { money = 1, money_mod = 2, limit = 1, triggers = 0 } },
    blueprint_compat = false,
    calc_dollar_bonus = function(self, card)
        if card.ability.extra.money > 0 then
            return card.ability.extra.money
        end
    end,
    calculate = function(self, card, context)
        local e = card.ability.extra
        if context.probability_success and not context.blueprint
            and (context.identifier == "lucky_mult"
                or context.identifier == "lucky_money")
            and (e.triggers or 0) < e.limit then
            e.triggers = (e.triggers or 0) + 1
            e.money = e.money + e.money_mod
        end
        if context.end_of_round and not context.blueprint then
            e.triggers = 0
        end
        poke_scaling_evo(card, context, "j_pokep_persian", e.money, 9)
    end,
}

-- Persian: Meowth's growing payout, with a 1 in 5 chance at end of
-- round to pay double (PC rolls inside calc_dollar_bonus, as here).
SMODS.Joker {
    key = "persian",
    sprite = "persian.png",
    negative_sprite = "persian_negative.png",
    loc_txt = {
        name = "Persian",
        text = {
            "Earn {C:money}$#1#{} at end of round",
            "{C:green}#3# in #4#{} chance to earn {C:attention}double{}",
            "First {C:green}successful{} {C:attention}Lucky{}",
            "card trigger each round",
            "increases payout by {C:money}$#2#{}",
        },
    },
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        local num, dem = SMODS.get_probability_vars(card, e.num, e.dem, "persian")
        return { vars = { e.money, e.money_mod, num, dem } }
    end,
    rarity = 3,
    cost = 9,
    perishable_compat = false,
    config = { extra = { money = 1, money_mod = 2, limit = 1, triggers = 0,
        num = 1, dem = 5 } },
    blueprint_compat = false,
    calc_dollar_bonus = function(self, card)
        local payout = card.ability.extra.money
        if payout > 0 then
            local hit = SMODS.pseudorandom_probability(card,
                "poke_persian", card.ability.extra.num,
                card.ability.extra.dem, "poke_persian")
            if hit then payout = payout * 2 end
            return payout
        end
    end,
    calculate = function(self, card, context)
        local e = card.ability.extra
        if context.probability_success and not context.blueprint
            and (context.identifier == "lucky_mult"
                or context.identifier == "lucky_money")
            and (e.triggers or 0) < e.limit then
            e.triggers = (e.triggers or 0) + 1
            e.money = e.money + e.money_mod
        end
        if context.end_of_round and not context.blueprint then
            e.triggers = 0
        end
    end,
}

-- Psyduck: earn $3 if the played hand is exactly 1 face card.
SMODS.Joker {
    key = "psyduck",
    sprite = "psyduck.png",
    negative_sprite = "psyduck_negative.png",
    loc_txt = {
        name = "Psyduck",
        text = {
            "Earn {C:money}$#1#{} if played hand",
            "is exactly {C:attention}1{} face card",
            "{C:inactive}(Evolves after {C:attention}#2#{C:inactive} rounds)",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.money,
            card.ability.extra.rounds } }
    end,
    rarity = 1,
    cost = 5,
    config = { extra = { money = 3, rounds = 5 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.joker_main and context.full_hand and context.scoring_hand
            and #context.full_hand == 1 and context.scoring_hand[1]
            and context.scoring_hand[1]:is_face() then
            return { dollars = card.ability.extra.money,
                message = "$" .. card.ability.extra.money }
        end
        poke_level_evo(card, context, "j_pokep_golduck")
    end,
}

-- Golduck: a played hand of exactly 1 face card turns that card
-- Gold (the node's set_enhancement, as the pack's Arcanine), and
-- Golduck earns $3 whenever any card becomes Gold -- PC reads that
-- off its setting_ability context (new == m_gold); the port reads
-- the changed card's enhancement in the fork's setting_ability
-- context, which includes Golduck's own conversion, as on PC.
SMODS.Joker {
    key = "golduck",
    sprite = "golduck.png",
    negative_sprite = "golduck_negative.png",
    loc_txt = {
        name = "Golduck",
        text = {
            "If played hand is",
            "exactly {C:attention}1 face{} card",
            "it becomes a {C:attention}Gold{} card",
            "Earn {C:money}$#1#{} when a",
            "card becomes {C:attention}Gold{}",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.money } }
    end,
    rarity = 3,
    cost = 7,
    config = { extra = { money = 3 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.setting_ability and not context.unchanged then
            local oc = context.other_card
            if oc and oc.enhancement == "gold" then
                return { dollars = card.ability.extra.money,
                    message = "$" .. card.ability.extra.money }
            end
        end
        if context.before and not context.blueprint and context.full_hand
            and context.scoring_hand and #context.full_hand == 1
            and context.scoring_hand[1]
            and context.scoring_hand[1]:is_face() then
            local face = context.scoring_hand[1]
            if face.set_enhancement then face:set_enhancement("gold") end
            return { message = "Gold!" }
        end
    end,
}

-- Mankey: each played 2, 3, 5 or 7 gives +3 Mult and +5 Chips when
-- scored.
SMODS.Joker {
    key = "mankey",
    sprite = "mankey.png",
    negative_sprite = "mankey_negative.png",
    loc_txt = {
        name = "Mankey",
        text = {
            "Each played {C:attention}2{}, {C:attention}3{}, {C:attention}5{}, or",
            "{C:attention}7{} gives {C:mult}+#1#{} Mult and",
            "{C:chips}+#2#{} Chips when scored",
            "{C:inactive}(Evolves after {C:attention}#3#{C:inactive} rounds)",
        },
    },
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        return { vars = { e.mult_mod, e.chip_mod, e.rounds } }
    end,
    rarity = 2,
    cost = 6,
    config = { extra = { mult_mod = 3, chip_mod = 5, rounds = 5 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            local oc = context.other_card
            if oc and not oc.debuff then
                local id = oc:get_id()
                if id == 2 or id == 3 or id == 5 or id == 7 then
                    return { chips = card.ability.extra.chip_mod,
                        mult = card.ability.extra.mult_mod }
                end
            end
        end
        poke_level_evo(card, context, "j_pokep_primeape")
    end,
}

-- Primeape: Mankey's prime-rank bonus at +5 Mult and +7 Chips.
-- DEVIATION: PC evolves into Annihilape (Gen 9) after 29 prime
-- triggers; Annihilape is not in this Gen 1 pack, so the evolution,
-- the primes_played counter and the evolves text line are dropped.
SMODS.Joker {
    key = "primeape",
    sprite = "primeape.png",
    negative_sprite = "primeape_negative.png",
    loc_txt = {
        name = "Primeape",
        text = {
            "Each played {C:attention}2{}, {C:attention}3{}, {C:attention}5{}, or",
            "{C:attention}7{} gives {C:mult}+#1#{} Mult and",
            "{C:chips}+#2#{} Chips when scored",
        },
    },
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        return { vars = { e.mult_mod, e.chip_mod } }
    end,
    rarity = 3,
    cost = 9,
    config = { extra = { mult_mod = 5, chip_mod = 7 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            local oc = context.other_card
            if oc and not oc.debuff then
                local id = oc:get_id()
                if id == 2 or id == 3 or id == 5 or id == 7 then
                    return { chips = card.ability.extra.chip_mod,
                        mult = card.ability.extra.mult_mod }
                end
            end
        end
    end,
}

-- Poliwag: played cards of its suit give +4 Mult when scored; the
-- suit cycles Spades -> Hearts -> Clubs -> Diamonds after every
-- played hand. DEVIATION: PC keeps ONE run-global suit shared by
-- the whole Poli line (G.GAME.poke_poli_suit, cycled by the mod's
-- own calculate on every `after`); the port keeps the suit per
-- Joker in extra.suit, cycled on `after` the same way.
SMODS.Joker {
    key = "poliwag",
    sprite = "poliwag.png",
    negative_sprite = "poliwag_negative.png",
    loc_txt = {
        name = "Poliwag",
        text = {
            "Played {C:attention}#3#{} cards give",
            "{C:mult}+#1#{} Mult when scored,",
            "suit cycles after scoring",
            "{C:inactive}(#4#, #5#, #6#, #7#){}",
            "{C:inactive}(Evolves after {C:attention}#2#{C:inactive} rounds)",
        },
    },
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        local suit = e.suit or "Spades"
        return { vars = { e.mult, e.rounds, suit:sub(1, -2),
            "Spades", "Hearts", "Clubs", "Diamonds" } }
    end,
    rarity = 1,
    cost = 4,
    config = { extra = { mult = 4, rounds = 5, suit = "Spades" } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        local e = card.ability.extra
        if context.individual and context.cardarea == G.play then
            local oc = context.other_card
            if oc and not oc.debuff and oc:is_suit(e.suit or "Spades") then
                return { mult = e.mult, message = "+" .. e.mult .. " Mult" }
            end
        end
        if context.after and not context.blueprint then
            local suits = { "Spades", "Hearts", "Clubs", "Diamonds" }
            for i, s in ipairs(suits) do
                if s == e.suit then
                    e.suit = suits[i % #suits + 1]
                    break
                end
            end
        end
        poke_level_evo(card, context, "j_pokep_poliwhirl")
    end,
}

-- frag_poke_2.lua -- Wave 4 Part B fragment for PokermonPack integration.
-- Ported from Pokermon (PC, SMODS) by InertSteak,
-- https://github.com/InertSteak/Pokermon (GPLv3), pokejokers_03.lua.
-- NOT a standalone file: it is meant to be appended into pokermonpack.lua
-- below the pack helpers (poke_evolve / poke_level_evo / poke_scaling_evo /
-- card_chip_value), which every def here uses. Energy is stripped, as
-- everywhere in the pack. Deviations are named per def below and in
-- census_poke_2.md; nothing is approximated silently.
--
-- Shared notes for this fragment:
--   * The Poli line's suit is tracked per Joker in extra.suit and cycles
--     on context.after. On PC the suit is one run-global
--     (G.GAME.poke_poli_suit) shared by the whole line; the fork has no
--     G.GAME, so two held Poli Jokers can sit on different suits here.
--   * The Abra line's "hand already played this round" test is tracked
--     per Joker in extra.seen (reset every end_of_round) instead of
--     PC's G.GAME.hands[name].played_this_round, which the fork does
--     not expose to mods.
--   * Grimer/Muk capture their deck-size baseline in add_to_deck: the
--     fork exposes no run-start deck size (PC's
--     G.GAME.starting_deck_size), so the baseline is the full-deck size
--     at the moment the Joker is gained.

local POLI_SUITS = { "Spades", "Hearts", "Clubs", "Diamonds" }
local POLI_SINGULAR = {
    Spades = "Spade", Hearts = "Heart", Clubs = "Club", Diamonds = "Diamond",
}
local RAND_RANKS = { 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14 }
local RAND_SUITS = { "Hearts", "Diamonds", "Clubs", "Spades" }

local function is_even_card(view)
    if not (view and view.get_id) then return false end
    local id = view:get_id()
    return id == 2 or id == 4 or id == 6 or id == 8 or id == 10
end

local function full_deck_count()
    if G and G.count_cards_in_full_deck then
        return G:count_cards_in_full_deck(function() return true end)
    end
    return 0
end

-- Create a random consumable of the given kind ("tarot" or the pack's
-- "poke_item") if there is room, PC create_card style. Returns true
-- when a card was created.
local function create_random_consumable(kind, seed)
    local used = (G.consumables and #G.consumables) or (G.consumeables and #G.consumeables) or 0
    local cap = (G.get_effective_consumable_capacity
        and G:get_effective_consumable_capacity()) or 2
    if used >= cap then return false end
    if not (G and G.random_consumable_id_of_kind) then return false end
    local id = G:random_consumable_id_of_kind(kind, {}, seed)
    if not id then return false end
    local set = (kind == "tarot") and "Tarot" or kind
    return SMODS.add_card { set = set, key = id } ~= nil
end

--------------------------------------------------------------------------------
-- Poliwhirl / Poliwrath: played cards of the cycling suit give Mult
-- (Poliwrath also gives X Mult). Stone evolutions do not self-evolve:
-- Poliwhirl is a Water Stone target (its King's Rock -> Politoed branch
-- is dropped: Politoed is Gen 2 and not in the pack, and the King's
-- Rock item is not ported).
--------------------------------------------------------------------------------

local function poli_line(key, name, cost, mult, xmult)
    local text
    if xmult then
        text = {
            "Played #2# cards give {C:mult}+#7#{} Mult",
            "and {X:mult,C:white}X#1#{} Mult when scored,",
            "suit cycles after scoring",
            "{C:inactive}(#3#, #4#, #5#, #6#)",
        }
    else
        text = {
            "Played #2# cards give",
            "{C:mult}+#1#{} Mult when scored",
            "suit cycles after scoring",
            "{C:inactive}(#3#, #4#, #5#, #6#)",
        }
    end
    local extra = { mult = mult, suit = "Spades" }
    if xmult then extra.xmult = xmult end
    SMODS.Joker {
        key = key,
        sprite = key .. ".png",
        negative_sprite = key .. "_negative.png",
        loc_txt = { name = name, text = text },
        loc_vars = function(self, info_queue, card)
            local suit = card.ability.extra.suit or "Spades"
            return { vars = {
                card.ability.extra.xmult or card.ability.extra.mult,
                POLI_SINGULAR[suit] or suit,
                "Spades", "Hearts", "Clubs", "Diamonds",
                card.ability.extra.mult,
            } }
        end,
        rarity = 3,
        cost = cost,
        config = { extra = extra },
        blueprint_compat = true,
        calculate = function(self, card, context)
            if context.individual and context.cardarea == G.play then
                local oc = context.other_card
                local suit = card.ability.extra.suit or "Spades"
                if oc and not oc.debuff and oc:is_suit(suit) then
                    if card.ability.extra.xmult then
                        return {
                            mult = card.ability.extra.mult,
                            x_mult = card.ability.extra.xmult,
                        }
                    end
                    return { mult = card.ability.extra.mult }
                end
            end
            if context.after and not context.blueprint then
                local suit = card.ability.extra.suit or "Spades"
                local idx = 1
                for i, s in ipairs(POLI_SUITS) do
                    if s == suit then idx = i break end
                end
                card.ability.extra.suit = POLI_SUITS[idx % #POLI_SUITS + 1]
            end
        end,
    }
end
poli_line("poliwhirl", "Poliwhirl", 7, 6)
poli_line("poliwrath", "Poliwrath", 10, 3, 1.3)

--------------------------------------------------------------------------------
-- Abra / Kadabra / Alakazam: on a repeat hand type this round, a 1 in 2
-- chance to create a Tarot or Item card. PC Kadabra/Alakazam name the
-- Twisted Spoon for the item branch; the Twisted Spoon is not in this
-- pack, so the item branch creates a random Item instead (the pack's
-- Item pool is the evolution stones). Alakazam's Tarot branch is the
-- specific Fool, as on PC. Kadabra's Linking Cord evolution does not
-- self-evolve (the Linking Cord is not a stone in this pack).
--------------------------------------------------------------------------------

-- Shared repeat-hand creation roll for the Abra line. `mode` is
-- "random" (Abra/Kadabra: random Tarot or random Item) or "fool"
-- (Alakazam: the Fool or a random Item).
local function abra_line_roll(card, seed, mode)
    return function(context)
        if context.joker_main and context.scoring_hand then
            local hand_name = context.scoring_name
            local seen = card.ability.extra.seen
            local repeat_hand = hand_name and seen and seen[hand_name]
            if hand_name and seen and not context.blueprint then
                seen[hand_name] = true
            end
            if repeat_hand then
                local hit = SMODS.pseudorandom_probability(
                    card, seed, card.ability.extra.num,
                    card.ability.extra.dem, seed)
                if hit then
                    if pseudorandom(seed .. "_item") < 0.5 then
                        create_random_consumable("poke_item", seed)
                    elseif mode == "fool" then
                        local used = (G.consumables and #G.consumables)
                            or (G.consumeables and #G.consumeables) or 0
                        local cap = (G.get_effective_consumable_capacity
                            and G:get_effective_consumable_capacity()) or 2
                        if used < cap then
                            SMODS.add_card { set = "Tarot", key = "tarot_fool" }
                        end
                    else
                        create_random_consumable("tarot", seed)
                    end
                end
            end
        end
        if context.end_of_round and not context.blueprint then
            card.ability.extra.seen = {}
        end
    end
end

SMODS.Joker {
    key = "abra",
    sprite = "abra.png",
    negative_sprite = "abra_negative.png",
    loc_txt = {
        name = "Abra",
        text = {
            "{C:green}#1# in #2#{} chance to create a {C:tarot}Tarot{}",
            "or {C:attention}Item{} card if played {C:attention}poker hand{}",
            "has already been played this round",
            "{C:inactive}(Evolves after {C:attention}#3#{C:inactive} rounds)",
        },
    },
    loc_vars = function(self, info_queue, card)
        local n, d = SMODS.get_probability_vars(
            card, card.ability.extra.num, card.ability.extra.dem, "poke_abra")
        return { vars = { n, d, card.ability.extra.rounds } }
    end,
    rarity = 1,
    cost = 6,
    config = { extra = { num = 1, dem = 2, rounds = 5, seen = {} } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        abra_line_roll(card, "poke_abra", "random")(context)
        poke_level_evo(card, context, "j_pokep_kadabra")
    end,
}

SMODS.Joker {
    key = "kadabra",
    sprite = "kadabra.png",
    negative_sprite = "kadabra_negative.png",
    loc_txt = {
        name = "Kadabra",
        text = {
            "{C:green}#1# in #2#{} chance to create a {C:tarot}Tarot{} or",
            "{C:attention}Item{} card if {C:attention}poker hand{}",
            "has already been played this round",
        },
    },
    loc_vars = function(self, info_queue, card)
        local n, d = SMODS.get_probability_vars(
            card, card.ability.extra.num, card.ability.extra.dem, "poke_kadabra")
        return { vars = { n, d } }
    end,
    rarity = 3,
    cost = 8,
    config = { extra = { num = 1, dem = 2, seen = {} } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        abra_line_roll(card, "poke_kadabra", "random")(context)
    end,
}

SMODS.Joker {
    key = "alakazam",
    sprite = "alakazam.png",
    negative_sprite = "alakazam_negative.png",
    loc_txt = {
        name = "Alakazam",
        text = {
            "{C:attention}+#3#{} consumable slot",
            "{C:green}#1# in #2#{} chance to create a {C:attention}Fool{} or",
            "{C:attention}Item{} card if {C:attention}poker hand{}",
            "has already been played this round",
        },
    },
    loc_vars = function(self, info_queue, card)
        local n, d = SMODS.get_probability_vars(
            card, card.ability.extra.num, card.ability.extra.dem, "poke_alakazam")
        return { vars = { n, d, card.ability.consumable_slots or 1 } }
    end,
    rarity = 3,
    cost = 10,
    config = { consumable_slots = 1, extra = { num = 1, dem = 2, seen = {} } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        abra_line_roll(card, "poke_alakazam", "fool")(context)
    end,
}

--------------------------------------------------------------------------------
-- Machop line: +hands and -discards as native modifiers, plus flat
-- Mult. Machop evolves by rounds; Machoke's Linking Cord evolution
-- does not self-evolve (the Linking Cord is not a stone in this pack).
--------------------------------------------------------------------------------

local function mach_line(key, name, rarity, cost, hands, discards, mult, rounds, evo_to)
    local text, extra
    if evo_to then
        text = {
            "{C:chips}+#1#{} hand",
            "{C:red}-#2#{} discards",
            "{C:mult}+#4#{} Mult",
            "{C:inactive}(Evolves after {C:attention}#3#{C:inactive} rounds)",
        }
        extra = { mult = mult, rounds = rounds }
    else
        text = {
            "{C:chips}+#1#{} hands",
            "{C:red}-#2#{} discards",
            "{C:mult}+#3#{} Mult",
        }
        extra = { mult = mult }
    end
    SMODS.Joker {
        key = key,
        sprite = key .. ".png",
        negative_sprite = key .. "_negative.png",
        loc_txt = { name = name, text = text },
        loc_vars = function(self, info_queue, card)
            if evo_to then
                return { vars = {
                    card.ability.hands,
                    math.abs(card.ability.d_size or 0),
                    card.ability.extra.rounds,
                    card.ability.extra.mult,
                } }
            end
            return { vars = {
                card.ability.hands,
                math.abs(card.ability.d_size or 0),
                card.ability.extra.mult,
            } }
        end,
        rarity = rarity,
        cost = cost,
        config = { hands = hands, d_size = -discards, extra = extra },
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
end
mach_line("machop", "Machop", 1, 6, 1, 1, 2, 5, "j_pokep_machoke")
mach_line("machoke", "Machoke", 3, 8, 2, 2, 10)
mach_line("machamp", "Machamp", 3, 10, 4, 4, 20)

--------------------------------------------------------------------------------
-- Bellsprout line: played cards with an even rank (2/4/6/8/10, PC
-- pokermon.is_even) give Chips when scored. Bellsprout evolves by
-- rounds; Weepinbell's Leaf Stone evolution does not self-evolve (the
-- stone block at the bottom of this file wires it).
-- Victreebel also retriggers the first 4 even scored cards each round.
--------------------------------------------------------------------------------

local function bell_line(key, name, rarity, cost, chips, rounds, evo_to)
    local text = {
        "Played cards with {C:attention}even{} rank",
        "give {C:chips}+#1#{} Chips when scored",
    }
    if evo_to then
        text[#text + 1] = "{C:inactive}(Evolves after {C:attention}#2#{C:inactive} rounds)"
    end
    local extra = { chips = chips }
    if rounds then extra.rounds = rounds end
    SMODS.Joker {
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
            if context.individual and context.cardarea == G.play then
                local oc = context.other_card
                if oc and not oc.debuff and is_even_card(oc) then
                    return { chips = card.ability.extra.chips }
                end
            end
            if evo_to then poke_level_evo(card, context, evo_to) end
        end,
    }
end
bell_line("bellsprout", "Bellsprout", 1, 4, 16, 4, "j_pokep_weepinbell")
bell_line("weepinbell", "Weepinbell", 2, 7, 32)

SMODS.Joker {
    key = "victreebel",
    sprite = "victreebel.png",
    negative_sprite = "victreebel_negative.png",
    loc_txt = {
        name = "Victreebel",
        text = {
            "Played cards with {C:attention}even{} rank",
            "give {C:chips}+#1#{} Chips when scored",
            "Retrigger the first {C:attention}#2#{} {C:inactive}[#3#]{}",
            "scored cards with {C:attention}even{}",
            "rank each round",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = {
            card.ability.extra.chips,
            card.ability.extra.retrigger_max,
            math.max(0, card.ability.extra.retrigger_max
                - (card.ability.extra.round_retriggers or 0)),
        } }
    end,
    rarity = 3,
    cost = 10,
    config = { extra = {
        chips = 24, retriggers = 1, retrigger_max = 4, round_retriggers = 0,
    } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            local oc = context.other_card
            if oc and not oc.debuff and is_even_card(oc) then
                return { chips = card.ability.extra.chips }
            end
        end
        if context.repetition and context.cardarea == G.play then
            local oc = context.other_card
            if oc and not oc.debuff and is_even_card(oc)
                and (card.ability.extra.round_retriggers or 0)
                    < card.ability.extra.retrigger_max then
                if not context.blueprint then
                    card.ability.extra.round_retriggers =
                        (card.ability.extra.round_retriggers or 0) + 1
                end
                return {
                    repetitions = card.ability.extra.retriggers,
                    message = "Again!",
                }
            end
        end
        if context.end_of_round and not context.blueprint then
            card.ability.extra.round_retriggers = 0
        end
    end,
}

--------------------------------------------------------------------------------
-- Geodude line: flat Chips with a negative hand size as a native
-- modifier. Geodude evolves by rounds; Graveler's Linking Cord
-- evolution does not self-evolve (see Machoke note).
--------------------------------------------------------------------------------

local function geo_line(key, name, rarity, cost, chips, h_size, rounds, evo_to)
    local text = {
        "{C:chips}+#1#{} Chips",
        "{C:attention}-#2#{} hand size",
    }
    if evo_to then
        text[#text + 1] = "{C:inactive}(Evolves after {C:attention}#3#{C:inactive} rounds)"
    end
    local extra = { chips = chips }
    if rounds then extra.rounds = rounds end
    SMODS.Joker {
        key = key,
        sprite = key .. ".png",
        negative_sprite = key .. "_negative.png",
        loc_txt = { name = name, text = text },
        loc_vars = function(self, info_queue, card)
            return { vars = {
                card.ability.extra.chips,
                math.abs(card.ability.h_size or 0),
                card.ability.extra.rounds,
            } }
        end,
        rarity = rarity,
        cost = cost,
        config = { h_size = -h_size, extra = extra },
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
end
geo_line("geodude", "Geodude", 1, 6, 75, 1, 4, "j_pokep_graveler")
geo_line("graveler", "Graveler", 3, 8, 175, 2)
geo_line("golem", "Golem", 3, 10, 275, 3)

--------------------------------------------------------------------------------
-- Ponyta: gains +12 Chips permanently when a played hand contains a
-- Straight; evolves into Rapidash (already in the pack) at +60 Chips.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "ponyta",
    sprite = "ponyta.png",
    negative_sprite = "ponyta_negative.png",
    loc_txt = {
        name = "Ponyta",
        text = {
            "Gains {C:chips}+#2#{} Chips if played",
            "hand contains a {C:attention}Straight{}",
            "{C:inactive}(Evolves at {C:chips}+#1#{C:inactive} / +60 Chips)",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chips, card.ability.extra.chip_mod } }
    end,
    rarity = 1,
    cost = 5,
    perishable_compat = false,
    config = { extra = { chips = 0, chip_mod = 12 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.before and not context.blueprint and context.poker_hands
            and next(context.poker_hands["Straight"]) then
            card.ability.extra.chips = card.ability.extra.chips
                + card.ability.extra.chip_mod
            return { message = "+" .. card.ability.extra.chip_mod .. " Chips" }
        end
        if context.joker_main and card.ability.extra.chips > 0 then
            return {
                chip_mod = card.ability.extra.chips,
                message = "+" .. card.ability.extra.chips .. " Chips",
            }
        end
        poke_scaling_evo(card, context, "j_pokep_rapidash",
            card.ability.extra.chips, 60)
    end,
}

--------------------------------------------------------------------------------
-- Slowpoke: X2 Mult on the final hand of the round; evolves into
-- Slowbro after triggering 4 times. Dropped from PC, named in the
-- census: the King's Rock -> Slowking branch (Slowking is Gen 2, not
-- in the pack; the King's Rock item is not ported), the 1-in-7 shop
-- reroll cameo that creates a Shell, and the Shell-triggered evolution
-- (the Shell is an aux trigger, not a standalone Joker -- see census).
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "slowpoke",
    sprite = "slowpoke.png",
    negative_sprite = "slowpoke_negative.png",
    loc_txt = {
        name = "Slowpoke",
        text = {
            "{X:mult,C:white} X#1# {} Mult on {C:attention}final hand{} of round",
            "{C:inactive}(Evolves after triggering {C:attention}#2#{C:inactive} times)",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = {
            card.ability.extra.xmult,
            math.max(0, 4 - (card.ability.extra.last_counter or 0)),
        } }
    end,
    rarity = 2,
    cost = 6,
    config = { extra = { xmult = 2, last_counter = 0 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.joker_main and (tonumber(G.hands) or 1) == 0 then
            if not context.blueprint then
                card.ability.extra.last_counter =
                    (card.ability.extra.last_counter or 0) + 1
            end
            return {
                x_mult = card.ability.extra.xmult,
                message = "X" .. card.ability.extra.xmult .. " Mult",
            }
        end
        poke_scaling_evo(card, context, "j_pokep_slowbro",
            card.ability.extra.last_counter, 4)
    end,
}

-- Slowbro: X Mult grows by X0.4 for each hand played this round,
-- counting the hand being scored (the fork counts a hand at
-- press-play, so this matches PC's 1 + (1 + hands already played)).
SMODS.Joker {
    key = "slowbro",
    sprite = "slowbro.png",
    negative_sprite = "slowbro_negative.png",
    loc_txt = {
        name = "Slowbro",
        text = {
            "{X:mult,C:white} X#1# {} Mult per hand",
            "played this round",
            "{C:inactive}(Currently {X:mult,C:white}X#2#{C:inactive} Mult)",
        },
    },
    loc_vars = function(self, info_queue, card)
        local played = (G and G.get_round_hands_played)
            and G:get_round_hands_played() or 0
        return { vars = {
            card.ability.extra.xmult_mod,
            card.ability.extra.xmult + played * card.ability.extra.xmult_mod,
        } }
    end,
    rarity = 3,
    cost = 10,
    config = { extra = { xmult_mod = 0.4, xmult = 1 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.joker_main then
            local played = (G and G.get_round_hands_played)
                and G:get_round_hands_played() or 0
            local total = card.ability.extra.xmult
                + played * card.ability.extra.xmult_mod
            return { x_mult = total, message = "X" .. total .. " Mult" }
        end
        if context.end_of_round and not context.blueprint then
            return { message = "Reset!" }
        end
    end,
}

--------------------------------------------------------------------------------
-- Doduo / Dodrio: the first 2 (Doduo) or 3 (Dodrio) played face cards
-- give Mult when scored. Dodrio's extra "+1 hand size this round when
-- the poker hand is exactly 3 face cards" is dropped, named in the
-- census: the fork has no temporary hand-size change a Joker can make
-- mid-round. Doduo evolves by rounds.
--------------------------------------------------------------------------------

local function first_face_hit(context, count)
    local hand = context.scoring_hand
    if not hand then return false end
    local seen = 0
    for _, c in ipairs(hand) do
        if c.is_face and c:is_face() then
            seen = seen + 1
            if c == context.other_card then return seen <= count end
            if seen >= count then return false end
        end
    end
    return false
end

SMODS.Joker {
    key = "doduo",
    sprite = "doduo.png",
    negative_sprite = "doduo_negative.png",
    loc_txt = {
        name = "Doduo",
        text = {
            "First {C:attention}2{} played {C:attention}face{} cards",
            "give {C:mult}+#1#{} Mult when scored",
            "{C:inactive}(Evolves after {C:attention}#2#{C:inactive} rounds)",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult, card.ability.extra.rounds } }
    end,
    rarity = 1,
    cost = 4,
    config = { extra = { mult = 6, rounds = 4 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play
            and not context.end_of_round then
            if first_face_hit(context, 2) then
                return { mult = card.ability.extra.mult }
            end
        end
        poke_level_evo(card, context, "j_pokep_dodrio")
    end,
}

SMODS.Joker {
    key = "dodrio",
    sprite = "dodrio.png",
    negative_sprite = "dodrio_negative.png",
    loc_txt = {
        name = "Dodrio",
        text = {
            "First {C:attention}3{} played {C:attention}face{} cards",
            "give {C:mult}+#1#{} Mult when scored",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult } }
    end,
    rarity = 3,
    cost = 7,
    config = { extra = { mult = 7 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play
            and not context.end_of_round then
            if first_face_hit(context, 3) then
                return { mult = card.ability.extra.mult }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Seel / Dewgong: add a random seal to the first scoring card on the
-- first hand of the round (Seel: 1 in 2 chance; Dewgong: always). The
-- fork counts a hand at press-play, so the first hand of the round is
-- get_round_hands_played() == 1 at the before pass. PC's
-- first_hand_drawn juice is cosmetic and dropped. Seel evolves by
-- rounds.
--------------------------------------------------------------------------------

local function seal_line(key, name, rarity, cost, with_roll, rounds, evo_to)
    local text
    if with_roll then
        text = {
            "{C:green}#1# in #2#{} chance to add a random",
            "{C:attention}seal{} to first scoring card",
            "on {C:attention}first hand{} of round",
            "{C:inactive}(Evolves after {C:attention}#3#{C:inactive} rounds)",
        }
    else
        text = {
            "Add a random {C:attention}seal{} to the",
            "leftmost scoring card on",
            "{C:attention}first hand{} of round",
        }
    end
    local extra = {}
    if with_roll then extra.num, extra.dem = 1, 2 end
    if rounds then extra.rounds = rounds end
    SMODS.Joker {
        key = key,
        sprite = key .. ".png",
        negative_sprite = key .. "_negative.png",
        loc_txt = { name = name, text = text },
        loc_vars = function(self, info_queue, card)
            if with_roll then
                local n, d = SMODS.get_probability_vars(
                    card, card.ability.extra.num, card.ability.extra.dem,
                    "poke_" .. key)
                return { vars = { n, d, card.ability.extra.rounds } }
            end
            return { vars = {} }
        end,
        rarity = rarity,
        cost = cost,
        config = { extra = extra },
        blueprint_compat = false,
        calculate = function(self, card, context)
            if context.before and not context.blueprint then
                local played = (G and G.get_round_hands_played)
                    and G:get_round_hands_played() or 1
                local target = context.scoring_hand and context.scoring_hand[1]
                if played == 1 and target and target.set_seal then
                    local do_seal = true
                    if with_roll then
                        do_seal = SMODS.pseudorandom_probability(
                            card, "poke_" .. key, card.ability.extra.num,
                            card.ability.extra.dem, "poke_" .. key)
                    end
                    if do_seal then
                        target:set_seal(SMODS.poll_seal({ guaranteed = true }))
                        return { message = "Seal!" }
                    end
                end
            end
            if evo_to then poke_level_evo(card, context, evo_to) end
        end,
    }
end
seal_line("seel", "Seel", 2, 6, true, 5, "j_pokep_dewgong")
seal_line("dewgong", "Dewgong", 3, 9, false)

--------------------------------------------------------------------------------
-- Grimer / Muk: Mult that needs the full deck to be bigger than it was
-- when the Joker was gained (baseline note at the top of this file),
-- and end-of-round deck churn. PC creates its random cards with
-- SMODS.add_card { set = 'Base' }; the fork's Playing creation needs
-- an explicit rank and suit, so both are rolled here. Grimer evolves
-- by rounds.
--------------------------------------------------------------------------------

local function add_random_card_to_deck(seed)
    if not SMODS.add_card then return end
    SMODS.add_card {
        set = "Playing",
        rank = pseudorandom_element(RAND_RANKS, seed),
        suit = pseudorandom_element(RAND_SUITS, seed),
        area = "deck",
    }
end

SMODS.Joker {
    key = "grimer",
    sprite = "grimer.png",
    negative_sprite = "grimer_negative.png",
    loc_txt = {
        name = "Grimer",
        text = {
            "{C:mult}+#1#{} Mult if deck size > {C:attention}#3#{}",
            "Add a random playing card",
            "to deck at end of round",
            "{C:inactive}(Evolves after {C:attention}#2#{C:inactive} rounds)",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = {
            card.ability.extra.mult,
            card.ability.extra.rounds,
            card.ability.extra.start_size or full_deck_count(),
        } }
    end,
    rarity = 1,
    cost = 4,
    config = { extra = { mult = 8, rounds = 5 } },
    blueprint_compat = true,
    add_to_deck = function(self, card, from_debuff)
        if card.ability.extra.start_size == nil then
            card.ability.extra.start_size = full_deck_count()
        end
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            local start = card.ability.extra.start_size or full_deck_count()
            if full_deck_count() > start then
                return {
                    mult_mod = card.ability.extra.mult,
                    message = "+" .. card.ability.extra.mult .. " Mult",
                }
            end
        end
        if context.end_of_round and not context.individual
            and not context.repetition then
            add_random_card_to_deck("poke_grimer")
        end
        poke_level_evo(card, context, "j_pokep_muk")
    end,
}

SMODS.Joker {
    key = "muk",
    sprite = "muk.png",
    negative_sprite = "muk_negative.png",
    loc_txt = {
        name = "Muk",
        text = {
            "{C:mult}+#1#{} Mult per card over {C:attention}#2#{} in your deck",
            "At end of round, destroy {C:attention}1{} random card",
            "in deck then add {C:attention}2{} random cards",
            "{C:inactive}(Currently {C:mult}+#3#{C:inactive} Mult)",
        },
    },
    loc_vars = function(self, info_queue, card)
        local start = card.ability.extra.start_size or full_deck_count()
        return { vars = {
            card.ability.extra.mult_mod,
            start,
            math.max(0, (full_deck_count() - start)
                * card.ability.extra.mult_mod),
        } }
    end,
    rarity = 3,
    cost = 6,
    config = { extra = { mult_mod = 2 } },
    blueprint_compat = true,
    add_to_deck = function(self, card, from_debuff)
        if card.ability.extra.start_size == nil then
            card.ability.extra.start_size = full_deck_count()
        end
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            local start = card.ability.extra.start_size or full_deck_count()
            local over = full_deck_count() - start
            if over > 0 then
                local total = card.ability.extra.mult_mod * over
                return {
                    mult_mod = total,
                    message = "+" .. total .. " Mult",
                }
            end
        end
        if context.end_of_round and not context.individual
            and not context.repetition then
            add_random_card_to_deck("poke_muk")
            add_random_card_to_deck("poke_muk")
            local pool = {}
            if G.deck then
                for _, c in ipairs(G.deck.cards or {}) do pool[#pool + 1] = c end
                for _, c in ipairs(G.deck.discard_pile or {}) do pool[#pool + 1] = c end
            end
            if G.hand and G.hand.card_nodes then
                for _, n in ipairs(G.hand.card_nodes) do
                    if n.card_data then pool[#pool + 1] = n.card_data end
                end
            end
            if #pool > 0 and SMODS.destroy_card then
                local victim = pseudorandom_element(pool, "poke_muk")
                if victim then SMODS.destroy_card(victim) end
            end
        end
    end,
}

-- PokermonPack wave 4 fragment poke_3: Gen 1 Jokers #092-#117 (Gastly
-- through Seadra) ported from Pokermon (PC, SMODS) by InertSteak,
-- https://github.com/InertSteak/Pokermon (GPLv3), v3.9.1.
--
-- Port notes: energy stripped everywhere (pack-wide design); the custom
-- "poke_safari" rarity maps to Rare (3). Every deviation from PC is
-- named in the def's comment and in census_poke_3.md. Chansey (#113)
-- is BLOCKED (see the census) and does not appear in this fragment.
-- This fragment expects the main pack file's helpers in scope
-- (poke_evolve, poke_level_evo, poke_scaling_evo).

--------------------------------------------------------------------------------
-- Fragment-local helpers
--------------------------------------------------------------------------------

-- Make `target` Negative the only way the fork's documented API allows:
-- destroy it and recreate the same def with the Negative edition,
-- carrying the scaled totals poke_evolve would carry (a total whose
-- *_mod sits next to it). DEVIATION from PC, which sets the edition in
-- place: the Joker moves to the end of the Joker area and stickers /
-- non-scaling state do not carry. Returns true on a successful swap.
local function poke3_make_negative(target)
    if not (SMODS.add_card and SMODS.destroy_joker) then return false end
    local id = target.def and target.def.id
    if not id then return false end
    local extra = target.ability and target.ability.extra or {}
    local keep = {}
    for _, k in ipairs({ "mult", "chips", "Xmult", "money" }) do
        local v = extra[k]
        if type(v) == "number"
            and (extra[k .. "_mod"] ~= nil or extra[k:sub(1, -2) .. "_mod"] ~= nil) then
            keep[k] = v
        end
    end
    if not SMODS.destroy_joker(target) then return false end
    local newj = SMODS.add_card { set = "Joker", key = id, edition = "negative" }
    if newj and type(newj.ability) == "table" and type(newj.ability.extra) == "table" then
        for k, v in pairs(keep) do
            local nv = newj.ability.extra[k]
            if type(nv) == "number" and v > nv then newj.ability.extra[k] = v end
        end
    end
    return newj ~= nil
end

-- A random held Joker other than `card` (PC's eligible pool for the
-- Gastly line's Lick), or nil. With exclude_gengar, Gengars are out too.
local function poke3_random_joker(card, seed, exclude_gengar)
    local eligible = {}
    for _, j in ipairs((G and G.jokers) or {}) do
        if j ~= card
            and not (exclude_gengar and j.def and j.def.id == "j_pokep_gengar") then
            eligible[#eligible + 1] = j
        end
    end
    if #eligible == 0 then return nil end
    return SMODS.pseudorandom_element(eligible, seed)
end

-- PC pokermon.volatile_active: a Volatile Left Joker is active unless a
-- non-Volatile Joker sits to its left; Volatile Right mirrors that.
local function poke3_volatile_active(card, direction)
    local self_pos, first_normal, last_normal = nil, nil, nil
    for i, j in ipairs((G and G.jokers) or {}) do
        if j == card then self_pos = i end
        local is_volatile = j.ability and type(j.ability.extra) == "table"
            and j.ability.extra.volatile
        if not is_volatile then
            if not first_normal then first_normal = i end
            last_normal = i
        end
    end
    if not self_pos then return false end
    if direction == "left" then
        return not (first_normal and first_normal < self_pos)
    end
    return not (last_normal and last_normal > self_pos)
end

-- Number of consumables currently held (the fork's G.consumables is a
-- flat list; tolerate the {cards = ...} shape too).
local function poke3_held_consumables()
    local area = G and (G.consumables or G.consumeables)
    if type(area) ~= "table" then return 0 end
    if type(area.cards) == "table" then return #area.cards end
    return #area
end

-- Distinct Planet cards used this run. The fork tracks usage exactly
-- like PC's G.GAME.consumeable_usage (one entry per consumable id), so
-- this is PC's own count, planets used before the Joker arrived too.
local function poke3_planets_used()
    local usage = G and G.consumable_usage
    if type(usage) ~= "table" then return 0 end
    local n = 0
    for _, u in pairs(usage) do
        if type(u) == "table" and (u.kind == "planet" or u.kind == "Planet") then
            n = n + 1
        end
    end
    return n
end

local function poke3_full_deck_count()
    if G and G.count_cards_in_full_deck then
        return tonumber(G:count_cards_in_full_deck(function() return true end)) or 0
    end
    local n = 0
    if G and G.deck then
        n = n + #(G.deck.cards or {}) + #(G.deck.discard_pile or {})
    end
    if G and G.hand and G.hand.card_nodes then n = n + #G.hand.card_nodes end
    return n
end

local function poke3_starting_deck_size()
    return tonumber(G and G.STARTING_DECK_SIZE) or 52
end

--------------------------------------------------------------------------------
-- Gastly: at end of round, a 1 in 6 chance to make a random other
-- Joker Negative, destroying itself in the process. Evolves to Haunter
-- after 3 rounds. DEVIATIONS: PC fires at its round_eval context (the
-- port's end_of_round is the equivalent step); the Negative edition is
-- applied by the destroy/recreate swap in poke3_make_negative, not in
-- place.
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "gastly",
    sprite = "gastly.png",
    negative_sprite = "gastly_negative.png",
    loc_txt = {
        name = "Gastly",
        text = {
            "{C:green}#1# in #2#{} chance to {C:attention}replace{} the",
            "edition of a random {C:attention}Joker{} with",
            "{C:dark_edition}Negative{} at end of round",
            "{C:red}self destructs{}",
            "{C:inactive}(Evolves after {C:attention}#3#{C:inactive} rounds)",
        },
    },
    loc_vars = function(self, info_queue, card)
        local num, dem = SMODS.get_probability_vars(
            card, card.ability.extra.num, card.ability.extra.dem, "poke_gastly")
        return { vars = { num, dem, card.ability.extra.rounds } }
    end,
    rarity = 2,
    cost = 7,
    config = { extra = { num = 1, dem = 6, rounds = 3 } },
    eternal_compat = false,
    blueprint_compat = false,
    calculate = function(self, card, context)
        if context.end_of_round and not context.blueprint then
            local hit = SMODS.pseudorandom_probability(
                card, "poke_gastly", card.ability.extra.num,
                card.ability.extra.dem, "poke_gastly")
            if hit then
                local target = poke3_random_joker(card, "poke_gastly", false)
                if target and poke3_make_negative(target) then
                    SMODS.destroy_joker(card)
                    return { message = "Lick!" }
                end
            end
        end
        poke_level_evo(card, context, "j_pokep_haunter")
    end,
}

--------------------------------------------------------------------------------
-- Haunter: Gastly's Lick at 1 in 4. Its PC evolution is item_evo with a
-- Linking Cord, which is not in the pack, so Haunter does not
-- self-evolve here (Gengar is a standalone Joker, as with the pack's
-- other item evolutions). Same round_eval / Negative-swap deviations
-- as Gastly.
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "haunter",
    sprite = "haunter.png",
    negative_sprite = "haunter_negative.png",
    loc_txt = {
        name = "Haunter",
        text = {
            "{C:green}#1# in #2#{} chance to {C:attention}replace{} the",
            "edition of a random {C:attention}Joker{} with",
            "{C:dark_edition}Negative{} at end of round",
            "{C:red}self destructs{}",
        },
    },
    loc_vars = function(self, info_queue, card)
        local num, dem = SMODS.get_probability_vars(
            card, card.ability.extra.num, card.ability.extra.dem, "poke_haunter")
        return { vars = { num, dem } }
    end,
    rarity = 3,
    cost = 9,
    config = { extra = { num = 1, dem = 4 } },
    eternal_compat = false,
    blueprint_compat = false,
    calculate = function(self, card, context)
        if context.end_of_round and not context.blueprint then
            local hit = SMODS.pseudorandom_probability(
                card, "poke_haunter", card.ability.extra.num,
                card.ability.extra.dem, "poke_haunter")
            if hit then
                local target = poke3_random_joker(card, "poke_haunter", false)
                if target and poke3_make_negative(target) then
                    SMODS.destroy_joker(card)
                    return { message = "Lick!" }
                end
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Gengar: counts down a random 2-8 round timer (weighted as on PC,
-- rolled when the Joker is first created); when it runs out, a random
-- non-Gengar Joker becomes Negative and the timer re-rolls.
-- DEVIATIONS: PC sets the trigger at end_of_round and fires it at the
-- next round_eval; the port fires on the same end_of_round the timer
-- reaches zero. Negative applied via poke3_make_negative, as above.
--------------------------------------------------------------------------------
local function poke3_gengar_roll(card)
    local p = pseudorandom("poke_gengar")
    local ex = card.ability.extra
    if p < 0.05 then ex.gengar_rounds = 2
    elseif p < 0.15 then ex.gengar_rounds = 3
    elseif p < 0.35 then ex.gengar_rounds = 4
    elseif p < 0.65 then ex.gengar_rounds = 5
    elseif p < 0.85 then ex.gengar_rounds = 6
    elseif p < 0.95 then ex.gengar_rounds = 7
    else ex.gengar_rounds = 8 end
end

SMODS.Joker {
    key = "gengar",
    sprite = "gengar.png",
    negative_sprite = "gengar_negative.png",
    loc_txt = {
        name = "Gengar",
        text = {
            "{C:attention}Replace{} the edition of a",
            "random {C:attention}Joker{} with",
            "{C:dark_edition}Negative{} in {C:dark_edition}#1#{} rounds",
            "{C:inactive}(Gengar picks a new number!){}",
            "{C:inactive}(Excludes Gengars){}",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.gengar_rounds } }
    end,
    rarity = 3,
    cost = 10,
    config = { extra = { gengar_rounds = 5, trigger = false } },
    eternal_compat = true,
    blueprint_compat = false,
    set_ability = function(self, card, initial)
        if initial then poke3_gengar_roll(card) end
    end,
    calculate = function(self, card, context)
        if context.end_of_round and not context.blueprint then
            card.ability.extra.gengar_rounds = card.ability.extra.gengar_rounds - 1
            if card.ability.extra.gengar_rounds > 0 then
                return { message = "Nasty Plot!" }
            end
            local target = poke3_random_joker(card, "poke_gengar", true)
            if target then poke3_make_negative(target) end
            poke3_gengar_roll(card)
            return { message = "Lick!" }
        end
    end,
}

--------------------------------------------------------------------------------
-- Onix: when a non-Stone playing card is destroyed, add a Stone card
-- to the deck (random rank/suit underneath, as a PC Base card rolled
-- the same way). DEVIATION: PC's type_evo to Steelix (Metal sticker)
-- is not wired -- the fork has no type/sticker evolution framework and
-- Steelix is not a Gen 1 def.
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "onix",
    sprite = "onix.png",
    negative_sprite = "onix_negative.png",
    loc_txt = {
        name = "Onix",
        text = {
            "When a {C:attention}non-Stone{} card",
            "is destroyed, add a",
            "{C:attention}Stone{} card to {C:attention}deck",
        },
    },
    rarity = 2,
    cost = 6,
    config = { extra = {} },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.remove_playing_cards then
            local destroyed = context.port and context.port.destroyed_cards
            if type(destroyed) ~= "table" then return end
            local added = 0
            for _, dc in ipairs(destroyed) do
                if dc and dc.enhancement ~= "stone" then
                    local rank = SMODS.pseudorandom_element(
                        { 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14 },
                        "poke_onix_rank")
                    local suit = SMODS.pseudorandom_element(
                        { "Hearts", "Diamonds", "Clubs", "Spades" },
                        "poke_onix_suit")
                    if SMODS.add_card { set = "Playing", rank = rank, suit = suit,
                        enhancement = "stone", area = "deck" } then
                        added = added + 1
                    end
                end
            end
            if added > 0 then return { message = "+ Stone" } end
        end
    end,
}

--------------------------------------------------------------------------------
-- Drowzee / Hypno: XMult per distinct Planet card used this run
-- (G.consumable_usage, PC's own source). Drowzee evolves at 7 distinct
-- Planets. Hypno's PC "Holding Trance" grant is dropped: the Trance
-- Spectral / held-item consumables are not in the pack (deviation,
-- named in the census), so its "Holding Trance" text line goes too.
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "drowzee",
    sprite = "drowzee.png",
    negative_sprite = "drowzee_negative.png",
    loc_txt = {
        name = "Drowzee",
        text = {
            "{X:mult,C:white}X#2#{} Mult per unique",
            "{C:planet}Planet{} card used this run",
            "{C:inactive}(Currently {X:mult,C:white}X#1#{C:inactive} Mult)",
            "{C:inactive}(Evolves after playing {C:planet}#3#{C:inactive} unique planet cards)",
        },
    },
    loc_vars = function(self, info_queue, card)
        local used = poke3_planets_used()
        return { vars = {
            1 + used * card.ability.extra.Xmult_mod,
            card.ability.extra.Xmult_mod,
            math.max(0, 7 - used),
        } }
    end,
    rarity = 2,
    cost = 5,
    config = { extra = { Xmult_mod = 0.2 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.joker_main then
            local used = poke3_planets_used()
            if used > 0 then
                return { x_mult = 1 + used * card.ability.extra.Xmult_mod }
            end
        end
        poke_scaling_evo(card, context, "j_pokep_hypno", poke3_planets_used(), 7)
    end,
}

SMODS.Joker {
    key = "hypno",
    sprite = "hypno.png",
    negative_sprite = "hypno_negative.png",
    loc_txt = {
        name = "Hypno",
        text = {
            "{X:mult,C:white}X#2#{} Mult per unique",
            "{C:planet}Planet{} card used this run",
            "{C:inactive}(Currently {X:mult,C:white}X#1#{C:inactive} Mult)",
        },
    },
    loc_vars = function(self, info_queue, card)
        local used = poke3_planets_used()
        return { vars = {
            1 + used * card.ability.extra.Xmult_mod,
            card.ability.extra.Xmult_mod,
        } }
    end,
    rarity = 3,
    cost = 8,
    config = { extra = { Xmult_mod = 0.25 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.joker_main then
            local used = poke3_planets_used()
            if used > 0 then
                return { x_mult = 1 + used * card.ability.extra.Xmult_mod }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Voltorb / Electrode / Koffing / Weezing: Volatile Jokers. When the
-- volatile position condition holds at joker_main, the effect fires
-- and the Joker faints for the rest of the round. DEVIATION (all four):
-- the fork has no Joker self-debuff API (SMODS.set_debuff is the
-- playing-card channel), so fainting is a self-gate flag in extra,
-- cleared at end_of_round: the effect cannot retrigger that round,
-- exactly as a debuff achieves on PC, but the Joker does not show as
-- debuffed and still evolves on schedule. A Blueprint copy firing the
-- effect does not faint the original, as on PC.
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "voltorb",
    sprite = "voltorb.png",
    negative_sprite = "voltorb_negative.png",
    loc_txt = {
        name = "Voltorb",
        text = {
            "{C:attention}Volatile Right{}",
            "{X:mult,C:white} X#1# {} Mult then",
            "debuff self this round",
            "{C:inactive}(Evolves after {C:attention}#2#{C:inactive} rounds)",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.Xmult, card.ability.extra.rounds } }
    end,
    rarity = 1,
    cost = 4,
    config = { extra = { Xmult = 1.75, rounds = 4, volatile = "right", fainted = false } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.joker_main and not card.ability.extra.fainted
            and poke3_volatile_active(card, card.ability.extra.volatile) then
            if not context.blueprint then card.ability.extra.fainted = true end
            return {
                x_mult = card.ability.extra.Xmult,
                message = "Explosion!",
            }
        end
        if context.end_of_round then card.ability.extra.fainted = false end
        poke_level_evo(card, context, "j_pokep_electrode")
    end,
}

SMODS.Joker {
    key = "electrode",
    sprite = "electrode.png",
    negative_sprite = "electrode_negative.png",
    loc_txt = {
        name = "Electrode",
        text = {
            "{C:attention}Volatile Right{}",
            "{X:mult,C:white} X#1# {} Mult and earn {C:money}$#2#{}",
            "then debuff self this round",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.Xmult, card.ability.extra.money } }
    end,
    rarity = 3,
    cost = 6,
    config = { extra = { Xmult = 2.25, money = 3, volatile = "right", fainted = false } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.joker_main and not card.ability.extra.fainted
            and poke3_volatile_active(card, card.ability.extra.volatile) then
            if not context.blueprint then card.ability.extra.fainted = true end
            return {
                x_mult = card.ability.extra.Xmult,
                dollars = card.ability.extra.money,
                message = "Explosion!",
            }
        end
        if context.end_of_round then card.ability.extra.fainted = false end
    end,
}

--------------------------------------------------------------------------------
-- Exeggcute / Exeggutor: scored Hearts give Mult. DEVIATIONS: PC's
-- Foresight (scry) passive and its Foreseen-card branch have no fork
-- equivalent and are dropped (the +Foresight text lines go with them);
-- Exeggcute's evolution is a stone evolution -- stone: leafstone --
-- so it does not self-evolve; the stone block at the bottom of this
-- file wires it (Exeggutor is a standalone Joker too, as with the
-- pack's other stone lines).
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "exeggcute",
    sprite = "exeggcute.png",
    negative_sprite = "exeggcute_negative.png",
    loc_txt = {
        name = "Exeggcute",
        text = {
            "Played {C:hearts}Hearts{} cards give",
            "{C:mult}+#1#{} Mult when scored",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult_mod } }
    end,
    rarity = 1,
    cost = 4,
    config = { extra = { mult_mod = 3, suit = "Hearts" } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            local oc = context.other_card
            if oc and not oc.debuff and oc:is_suit(card.ability.extra.suit) then
                return { mult = card.ability.extra.mult_mod }
            end
        end
    end,
}

SMODS.Joker {
    key = "exeggutor",
    sprite = "exeggutor.png",
    negative_sprite = "exeggutor_negative.png",
    loc_txt = {
        name = "Exeggutor",
        text = {
            "Played {C:hearts}Hearts{} cards give",
            "{C:mult}+#1#{} Mult when scored",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult_mod } }
    end,
    rarity = 3,
    cost = 10,
    config = { extra = { mult_mod = 4, suit = "Hearts" } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            local oc = context.other_card
            if oc and not oc.debuff and oc:is_suit(card.ability.extra.suit) then
                return { mult = card.ability.extra.mult_mod }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Cubone / Marowak: Mult / XMult per held consumable; Marowak also
-- grants +1 consumable slot (the fork's declarative consumable_slots
-- modifier, where PC edits the consumable area's card_limit).
-- DEVIATIONS: PC's Thick Club held-item consumable is not in the pack,
-- so Cubone's on-pickup Thick Club grant and the "Thick Clubs count
-- as double" rule are dropped (the "Holding Thick Club" text line goes
-- with them); every held consumable counts once. Cubone's evolution
-- counter (consumables used while held) is PC's own.
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "cubone",
    sprite = "cubone.png",
    negative_sprite = "cubone_negative.png",
    loc_txt = {
        name = "Cubone",
        text = {
            "Gives {C:mult}+#1#{} Mult for",
            "each {C:attention}held consumable",
            "{C:inactive}(Currently {C:mult}+#2#{C:inactive} Mult)",
            "{C:inactive}(Evolves after using {C:attention}#3#{C:inactive} consumables)",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = {
            card.ability.extra.mult,
            card.ability.extra.mult * poke3_held_consumables(),
            math.max(0, 20 - (card.ability.extra.consumables_used or 0)),
        } }
    end,
    rarity = 1,
    cost = 5,
    config = { extra = { mult = 5, consumables_used = 0 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.joker_main then
            local count = poke3_held_consumables()
            if count > 0 then
                return {
                    mult_mod = card.ability.extra.mult * count,
                    message = "+" .. (card.ability.extra.mult * count) .. " Mult",
                }
            end
        end
        if context.using_consumeable then
            card.ability.extra.consumables_used =
                (card.ability.extra.consumables_used or 0) + 1
        end
        poke_scaling_evo(card, context, "j_pokep_marowak",
            card.ability.extra.consumables_used, 20)
    end,
}

SMODS.Joker {
    key = "marowak",
    sprite = "marowak.png",
    negative_sprite = "marowak_negative.png",
    loc_txt = {
        name = "Marowak",
        text = {
            "{C:attention}+#2#{} consumable slots",
            "Gives {X:mult,C:white} X#1# {} Mult for",
            "each {C:attention}held consumable",
            "{C:inactive}(Currently {X:mult,C:white} X#3# {C:inactive} Mult)",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = {
            card.ability.extra.Xmult_mod,
            card.ability.extra.card_limit,
            1 + card.ability.extra.Xmult_mod * poke3_held_consumables(),
        } }
    end,
    rarity = 3,
    cost = 8,
    config = { consumable_slots = 1, extra = { Xmult_mod = 0.4, card_limit = 1 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.joker_main then
            local count = poke3_held_consumables()
            if count > 0 then
                return { x_mult = 1 + card.ability.extra.Xmult_mod * count }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Hitmonlee / Hitmonchan: XMult for every card the full deck is below
-- / above its starting size (G.STARTING_DECK_SIZE, the fork's own
-- baseline, 52 on a standard deck; full deck counted with the fork's
-- count_cards_in_full_deck).
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "hitmonlee",
    sprite = "hitmonlee.png",
    negative_sprite = "hitmonlee_negative.png",
    loc_txt = {
        name = "Hitmonlee",
        text = {
            "{X:mult,C:white}X#1#{} Mult for every card",
            "below {C:attention}#2#{} in your {C:attention}full deck",
            "{C:inactive}(Currently {X:mult,C:white}X#3#{C:inactive} Mult)",
        },
    },
    loc_vars = function(self, info_queue, card)
        local start = poke3_starting_deck_size()
        return { vars = {
            card.ability.extra.Xmult_mod,
            start,
            math.max(1, 1 + (start - poke3_full_deck_count())
                * card.ability.extra.Xmult_mod),
        } }
    end,
    rarity = 2,
    cost = 6,
    config = { extra = { Xmult_mod = 0.15 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.joker_main then
            local xmult = 1 + (poke3_starting_deck_size() - poke3_full_deck_count())
                * card.ability.extra.Xmult_mod
            if xmult > 1 then return { x_mult = xmult } end
        end
    end,
}

SMODS.Joker {
    key = "hitmonchan",
    sprite = "hitmonchan.png",
    negative_sprite = "hitmonchan_negative.png",
    loc_txt = {
        name = "Hitmonchan",
        text = {
            "{X:mult,C:white}X#1#{} Mult for every card",
            "above {C:attention}#2#{} in your {C:attention}full deck",
            "{C:inactive}(Currently {X:mult,C:white}X#3#{C:inactive} Mult)",
        },
    },
    loc_vars = function(self, info_queue, card)
        local start = poke3_starting_deck_size()
        return { vars = {
            card.ability.extra.Xmult_mod,
            start,
            math.max(1, 1 + (poke3_full_deck_count() - start)
                * card.ability.extra.Xmult_mod),
        } }
    end,
    rarity = 2,
    cost = 6,
    config = { extra = { Xmult_mod = 0.15 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.joker_main then
            local xmult = 1 + (poke3_full_deck_count() - poke3_starting_deck_size())
                * card.ability.extra.Xmult_mod
            if xmult > 1 then return { x_mult = xmult } end
        end
    end,
}

--------------------------------------------------------------------------------
-- Lickitung: the first and second scored Jacks each give X1.5 Mult.
-- DEVIATION: PC's scaling evolution (15 Jack triggers) targets
-- Lickilicky, which is not a Gen 1 def, so it is not wired; the
-- jacks_played counter is kept but drives nothing, and the evolution
-- text line is dropped.
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "lickitung",
    sprite = "lickitung.png",
    negative_sprite = "lickitung_negative.png",
    loc_txt = {
        name = "Lickitung",
        text = {
            "First and second played {C:attention}Jacks{}",
            "give {X:mult,C:white} X#1# {} Mult when scored",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.Xmult_multi } }
    end,
    rarity = 2,
    cost = 6,
    config = { extra = { Xmult_multi = 1.5, jacks_played = 0 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            local oc = context.other_card
            if oc and not oc.debuff and oc.get_id and oc:get_id() == 11 then
                local jacks = 0
                for _, c in ipairs(context.scoring_hand or {}) do
                    if c.get_id and c:get_id() == 11 then
                        jacks = jacks + 1
                        if c == oc then
                            if jacks <= 2 then
                                if not context.blueprint then
                                    card.ability.extra.jacks_played =
                                        (card.ability.extra.jacks_played or 0) + 1
                                end
                                return {
                                    x_mult = card.ability.extra.Xmult_multi,
                                    message = "X" .. card.ability.extra.Xmult_multi .. " Mult",
                                }
                            end
                            break
                        end
                    end
                end
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Koffing / Weezing: Volatile Left flat Mult (see the volatile note at
-- Voltorb for the faint deviation). Weezing also disables the current
-- Boss Blind when sold, through the engine's own disable funnel
-- (Game:disable_boss_blind, the same call Luchador's sale makes).
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "koffing",
    sprite = "koffing.png",
    negative_sprite = "koffing_negative.png",
    loc_txt = {
        name = "Koffing",
        text = {
            "{C:attention}Volatile Left{}",
            "{C:mult}+#1#{} Mult then",
            "debuff self this round",
            "{C:inactive}(Evolves after {C:attention}#2#{C:inactive} rounds)",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult, card.ability.extra.rounds } }
    end,
    rarity = 1,
    cost = 5,
    config = { extra = { mult = 12, rounds = 2, volatile = "left", fainted = false } },
    blueprint_compat = true,
    eternal_compat = false,
    calculate = function(self, card, context)
        if context.joker_main and not card.ability.extra.fainted
            and poke3_volatile_active(card, card.ability.extra.volatile) then
            if not context.blueprint then card.ability.extra.fainted = true end
            return {
                mult_mod = card.ability.extra.mult,
                message = "Explosion!",
            }
        end
        if context.end_of_round then card.ability.extra.fainted = false end
        poke_level_evo(card, context, "j_pokep_weezing")
    end,
}

SMODS.Joker {
    key = "weezing",
    sprite = "weezing.png",
    negative_sprite = "weezing_negative.png",
    loc_txt = {
        name = "Weezing",
        text = {
            "{C:attention}Volatile Left{}",
            "{C:mult}+#1#{} Mult then",
            "debuff self this round",
            "Sell this card to {C:attention}disable{}",
            "the current {C:attention}Boss Blind{}",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult } }
    end,
    rarity = 3,
    cost = 7,
    config = { extra = { mult = 18, volatile = "left", fainted = false } },
    blueprint_compat = true,
    eternal_compat = false,
    calculate = function(self, card, context)
        if context.joker_main and not card.ability.extra.fainted
            and poke3_volatile_active(card, card.ability.extra.volatile) then
            if not context.blueprint then card.ability.extra.fainted = true end
            return {
                mult_mod = card.ability.extra.mult,
                message = "Explosion!",
            }
        end
        if context.end_of_round then card.ability.extra.fainted = false end
        if context.selling_self and not context.blueprint then
            if G and G.get_active_boss_blind_id and G.disable_boss_blind
                and G:get_active_boss_blind_id() then
                G:disable_boss_blind()
                return { message = "Boss Disabled!" }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Rhyhorn / Rhydon: every played Stone card permanently gains Chips
-- when scored (SMODS perma_bonus). Rhydon also retriggers the first
-- scored Stone card. DEVIATION: Rhydon's PC item_evo (Linking Cord to
-- Rhyperior) is not wired -- the Linking Cord is not in the pack and
-- Rhyperior is not a Gen 1 def; its evolution text line is dropped.
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "rhyhorn",
    sprite = "rhyhorn.png",
    negative_sprite = "rhyhorn_negative.png",
    loc_txt = {
        name = "Rhyhorn",
        text = {
            "Every played {C:attention}Stone{} card",
            "permanently gains",
            "{C:chips}+#1#{} Chips when scored",
            "{C:inactive}(Evolves after {C:attention}#2#{C:inactive} rounds)",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chips, card.ability.extra.rounds } }
    end,
    rarity = 1,
    cost = 5,
    config = { extra = { chips = 12, rounds = 4 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            local oc = context.other_card
            if oc and not oc.debuff and oc.enhancement == "stone" then
                SMODS.set_perma(oc, "perma_bonus",
                    (tonumber(SMODS.get_perma(oc, "perma_bonus")) or 0)
                    + card.ability.extra.chips)
                return { message = localize("k_upgrade_ex") }
            end
        end
        poke_level_evo(card, context, "j_pokep_rhydon")
    end,
}

SMODS.Joker {
    key = "rhydon",
    sprite = "rhydon.png",
    negative_sprite = "rhydon_negative.png",
    loc_txt = {
        name = "Rhydon",
        text = {
            "Every played {C:attention}Stone{} card permanently",
            "gains {C:chips}+#1#{} Chips when scored",
            "Retrigger {C:attention}first{} scored {C:attention}Stone{} card",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chips } }
    end,
    rarity = 3,
    cost = 8,
    config = { extra = { chips = 16, retriggers = 1 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            local oc = context.other_card
            if oc and not oc.debuff and oc.enhancement == "stone" then
                SMODS.set_perma(oc, "perma_bonus",
                    (tonumber(SMODS.get_perma(oc, "perma_bonus")) or 0)
                    + card.ability.extra.chips)
                return { message = localize("k_upgrade_ex") }
            end
        end
        if context.repetition and context.cardarea == G.play then
            local oc = context.other_card
            if oc and oc.enhancement == "stone" then
                local played = context.port and context.port.played_cards
                if type(played) == "table" then
                    for _, n in ipairs(played) do
                        if n and n.counts_for_play_score then
                            if n.enhancement == "stone" then
                                if n == oc then
                                    return {
                                        repetitions = card.ability.extra.retriggers,
                                        message = "Again!",
                                    }
                                end
                                break
                            end
                        end
                    end
                end
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Tangela: played Wild cards give one of +10 Mult / +50 Chips / $3 at
-- random, or all three on a 1 in 4 roll. DEVIATION: PC's scaling
-- evolution (10 Wild cards scored) targets Tangrowth, which is not a
-- Gen 1 def, so it is not wired; the wilds_scored counter is kept but
-- drives nothing, and the evolution text line is dropped.
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "tangela",
    sprite = "tangela.png",
    negative_sprite = "tangela_negative.png",
    loc_txt = {
        name = "Tangela",
        text = {
            "Played {C:attention}Wild{} cards give",
            "{C:mult}+#1#{} Mult, {C:chips}+#2#{} Chips, or {C:money}$#3#{}",
            "{C:green}#4# in #5#{} chance for {C:attention}all three{}",
        },
    },
    loc_vars = function(self, info_queue, card)
        local num, dem = SMODS.get_probability_vars(
            card, card.ability.extra.num, card.ability.extra.dem, "poke_tangela")
        return { vars = {
            card.ability.extra.mult,
            card.ability.extra.chips,
            card.ability.extra.money_mod,
            num, dem,
        } }
    end,
    rarity = 1,
    cost = 6,
    config = { extra = { mult = 10, chips = 50, money_mod = 3, num = 1, dem = 4,
        wilds_scored = 0 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            local oc = context.other_card
            if oc and not oc.debuff and oc.enhancement == "wild" then
                if not context.blueprint then
                    card.ability.extra.wilds_scored =
                        (card.ability.extra.wilds_scored or 0) + 1
                end
                local hit = SMODS.pseudorandom_probability(
                    card, "poke_tangela", card.ability.extra.num,
                    card.ability.extra.dem, "poke_tangela")
                if hit then
                    return {
                        mult = card.ability.extra.mult,
                        chips = card.ability.extra.chips,
                        dollars = card.ability.extra.money_mod,
                        message = "All three!",
                    }
                end
                local bonus = SMODS.pseudorandom_element(
                    { "Mult", "Chips", "Money" }, "poke_tangela")
                if bonus == "Mult" then
                    return { mult = card.ability.extra.mult }
                elseif bonus == "Chips" then
                    return { chips = card.ability.extra.chips }
                end
                return { dollars = card.ability.extra.money_mod }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Kangaskhan: +2 consumable slots, nothing else (PC has no calculate;
-- the fork's declarative consumable_slots modifier replaces PC's
-- add/remove_from_deck card_limit edits).
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "kangaskhan",
    sprite = "kangaskhan.png",
    negative_sprite = "kangaskhan_negative.png",
    loc_txt = {
        name = "Kangaskhan",
        text = {
            "{C:attention}+#1#{} consumable slots",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.card_limit } }
    end,
    rarity = 2,
    cost = 6,
    config = { consumable_slots = 2, extra = { card_limit = 2 } },
    blueprint_compat = false,
}

--------------------------------------------------------------------------------
-- Horsea / Seadra: gain Mult permanently from scored 6s. Horsea gains
-- at hand level (+1 per 6 in the poker hand, before scoring) and
-- evolves at +12 Mult; Seadra gains per scored 6, doubled while a King
-- is held in hand. DEVIATION: Seadra's PC type_evo (Dragon sticker to
-- Kingdra) is not wired -- no type/sticker evolution framework, and
-- Kingdra is not a Gen 1 def; its evolution text line is dropped.
--------------------------------------------------------------------------------
SMODS.Joker {
    key = "horsea",
    sprite = "horsea.png",
    negative_sprite = "horsea_negative.png",
    loc_txt = {
        name = "Horsea",
        text = {
            "Gains {C:mult}+#2#{} Mult",
            "for each {C:attention}6{}",
            "in poker hand",
            "{C:inactive}(Evolves at {C:mult}+#1#{C:inactive} / +12 Mult)",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult, card.ability.extra.mult_mod } }
    end,
    rarity = 2,
    cost = 6,
    perishable_compat = false,
    config = { extra = { mult = 0, mult_mod = 1 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.before and not context.blueprint then
            local sixes = 0
            for _, c in ipairs(context.scoring_hand or {}) do
                if c.get_id and c:get_id() == 6 then sixes = sixes + 1 end
            end
            if sixes > 0 then
                local gain = card.ability.extra.mult_mod * sixes
                card.ability.extra.mult = card.ability.extra.mult + gain
                return { message = "+" .. gain .. " Mult" }
            end
        end
        if context.joker_main and card.ability.extra.mult > 0 then
            return {
                mult_mod = card.ability.extra.mult,
                message = "+" .. card.ability.extra.mult .. " Mult",
            }
        end
        poke_scaling_evo(card, context, "j_pokep_seadra",
            card.ability.extra.mult, 12)
    end,
}

SMODS.Joker {
    key = "seadra",
    sprite = "seadra.png",
    negative_sprite = "seadra_negative.png",
    loc_txt = {
        name = "Seadra",
        text = {
            "Gains {C:mult}+#2#{} Mult when each",
            "played {C:attention}6{} is scored",
            "Doubled if a {C:attention}King{}",
            "is {C:attention}held{} in hand",
            "{C:inactive}(Currently {C:mult}+#1#{C:inactive} Mult)",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult, card.ability.extra.mult_mod } }
    end,
    rarity = 3,
    cost = 6,
    perishable_compat = false,
    config = { extra = { mult = 0, mult_mod = 1 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play and not context.blueprint then
            local oc = context.other_card
            if oc and not oc.debuff and oc.get_id and oc:get_id() == 6 then
                local has_king = false
                local hand_cards = G and G.hand and G.hand.card_nodes or {}
                for _, c in ipairs(hand_cards) do
                    if c.get_id and c:get_id() == 13 then
                        has_king = true
                        break
                    end
                end
                local gain = card.ability.extra.mult_mod * (has_king and 2 or 1)
                card.ability.extra.mult = card.ability.extra.mult + gain
                return { message = "+" .. gain .. " Mult" }
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

--------------------------------------------------------------------------------
-- PokermonPack fragment, Wave 4 Part B: Gen 1 Pokemon 120-151 + Missingno.
-- PC source: Pokermon by InertSteak, https://github.com/InertSteak/Pokermon
-- (GPLv3), defs in pokemon/pokejokers_04.lua (Staryu), powejokers_05.lua,
-- powejokers_06.lua (Mew) and pokemon/zmissingno.lua; text adapted from
-- localization/en-us.lua (descriptions.Joker.j_poke_<name>).
--
-- INTEGRATOR: this fragment is pack body, not a standalone file. It uses
-- the pack helpers already defined in pokermonpack.lua (flat_mult,
-- poke_scaling_evo, scoring_pos, SMODS.set_perma via the fork) and must be
-- spliced after them. Stone evolutions do NOT self-evolve here; the
-- integrator must extend the stone block's STONE_OF / STONE_EVOLUTION
-- maps with: j_pokep_staryu = waterstone -> j_pokep_starmie, and Eevee's
-- branching entries j_pokep_eevee = firestone -> j_pokep_flareon,
-- waterstone -> j_pokep_vaporeon, thunderstone -> j_pokep_jolteon (the
-- current maps are 1:1 per pre-form, so Eevee needs map support for one
-- pre-form appearing under three stones).
--
-- Energy is stripped everywhere, as in the rest of the pack.
-- "poke_safari" rarity maps to Rare (3), as in the rest of the pack.
-- BLOCKED (see census_poke_4.md for the precise reasons): jynx, ditto,
-- porygon, snorlax, moltres, missingno. No defs are registered for them.
--------------------------------------------------------------------------------

-- Staryu: played Diamonds give +1 Mult and $1 when scored.
-- (Water Stone evolution; does not self-evolve.)
SMODS.Joker {
    key = "staryu",
    sprite = "staryu.png",
    negative_sprite = "staryu_negative.png",
    loc_txt = {
        name = "Staryu",
        text = {
            "Played {C:diamonds}#2#{} cards give",
            "{C:mult}+#1#{} Mult and {C:money}$#3#{} when scored",
            "{C:inactive}(Evolves with a {C:attention}Water Stone{C:inactive})",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult, "Diamond",
            card.ability.extra.money_mod } }
    end,
    rarity = 1,
    cost = 4,
    config = { extra = { mult = 1, money_mod = 1, suit = "Diamonds" } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            local oc = context.other_card
            if oc and not oc.debuff and oc:is_suit(card.ability.extra.suit) then
                return {
                    mult = card.ability.extra.mult,
                    dollars = card.ability.extra.money_mod,
                    message = "+$" .. card.ability.extra.money_mod,
                }
            end
        end
    end,
}

-- Starmie: played Diamonds give +2 Mult and $2 when scored.
SMODS.Joker {
    key = "starmie",
    sprite = "starmie.png",
    negative_sprite = "starmie_negative.png",
    loc_txt = {
        name = "Starmie",
        text = {
            "Played {C:diamonds}#3#{} cards give",
            "{C:mult}+#1#{} Mult and {C:money}$#2#{} when scored",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult,
            card.ability.extra.money_mod, "Diamond" } }
    end,
    rarity = 3,
    cost = 10,
    config = { extra = { mult = 2, money_mod = 2, suit = "Diamonds" } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            local oc = context.other_card
            if oc and not oc.debuff and oc:is_suit(card.ability.extra.suit) then
                return {
                    mult = card.ability.extra.mult,
                    dollars = card.ability.extra.money_mod,
                    message = "+$" .. card.ability.extra.money_mod,
                }
            end
        end
    end,
}

-- Scyther: when a Blind is selected, destroy the Joker to the right to
-- gain +4 Mult permanently; if that Joker was not Common or Uncommon and
-- Scyther has no edition, Scyther gains a random Foil, Holographic or
-- Polychrome edition. PC's evolutions (Scizor via a Metal sticker,
-- Kleavor via a Hard Stone) are not ported: neither target is Gen 1 or
-- in this pack, and neither the sticker nor the stone exists here.
SMODS.Joker {
    key = "scyther",
    sprite = "scyther.png",
    negative_sprite = "scyther_negative.png",
    loc_txt = {
        name = "Scyther",
        text = {
            "When Blind is selected, destroy Joker",
            "to the right to gain {C:mult}+#2#{} Mult",
            "If that Joker wasn't {C:blue}Common{} or",
            "{C:green}Uncommon{}, replaces own {C:attention}edition{} with",
            "{C:dark_edition}Foil{}, {C:dark_edition}Holographic{}, or {C:dark_edition}Polychrome{}",
            "{C:inactive}(Currently {C:mult}+#1#{C:inactive} Mult)",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult,
            card.ability.extra.mult_mod } }
    end,
    rarity = 2,
    cost = 6,
    perishable_compat = false,
    config = { extra = { mult = 0, mult_mod = 4 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.setting_blind and not context.blueprint then
            local jokers = G and G.jokers or {}
            local idx
            for i, j in ipairs(jokers) do
                if j == card then idx = i break end
            end
            local victim = idx and jokers[idx + 1] or nil
            if victim and not victim.eternal
                and SMODS.destroy_joker and SMODS.destroy_joker(victim) then
                card.ability.extra.mult = card.ability.extra.mult
                    + card.ability.extra.mult_mod
                local ed = card.edition
                if victim.rarity ~= 1 and victim.rarity ~= 2
                    and (not ed or ed == "" or ed == "base") then
                    card.edition = SMODS.pseudorandom_element(
                        { "foil", "holo", "polychrome" }, "poke_scyther")
                end
                return { message = "+" .. card.ability.extra.mult_mod
                    .. " Mult" }
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

-- Electabuzz: gains $2 of sell value when a card is sold and at end of
-- round; earns 25% of its sell value (rounded up, max $20) at end of
-- round. PC grows ability.extra_value and re-prices with set_cost; the
-- fork's sell path reads the Joker's sell_cost field directly (the
-- Cryptid/Paperback pattern), so the port writes sell_cost. PC's
-- evolution (Electivire, via a Linking Cord) is not ported: the target
-- is not Gen 1 and the item is not in this pack.
SMODS.Joker {
    key = "electabuzz",
    sprite = "electabuzz.png",
    negative_sprite = "electabuzz_negative.png",
    loc_txt = {
        name = "Electabuzz",
        text = {
            "Gains {C:money}$#1#{} of {C:attention}sell value{} when a card",
            "is {C:attention}sold{} and at end of round",
            "Earn {C:attention}#2#%{} of this Joker's sell value",
            "at end of round {C:inactive}(rounded up){}",
            "{C:inactive}(Currently earns {C:money}$#3#{C:inactive}/$#4# Max)",
        },
    },
    loc_vars = function(self, info_queue, card)
        local sell = tonumber(card.sell_cost) or 0
        return { vars = { card.ability.extra.money_mod,
            card.ability.extra.percent,
            math.min(card.ability.extra.max,
                math.ceil(sell * card.ability.extra.percent / 100)),
            card.ability.extra.max } }
    end,
    rarity = 3,
    cost = 8,
    config = { extra = { money_mod = 2, percent = 25, max = 20 } },
    blueprint_compat = false,
    calculate = function(self, card, context)
        if not context.blueprint
            and ((context.selling_card and not context.selling_self)
                or context.end_of_round) then
            card.sell_cost = (tonumber(card.sell_cost) or 0)
                + card.ability.extra.money_mod
            return { message = "Value Up!" }
        end
    end,
    calc_dollar_bonus = function(self, card)
        local sell = tonumber(card.sell_cost) or 0
        local earned = math.min(card.ability.extra.max,
            math.ceil(sell * card.ability.extra.percent / 100))
        if earned > 0 then return earned end
    end,
}

-- Magmar: if the first discard of the round is a single card, destroy
-- it and gain +2 Mult permanently. The fork has no discards_used
-- counter, so this Joker counts its own discard contexts and resets at
-- end of round (the MoreFluff grep pattern); PC's discard-context
-- remove=true becomes SMODS.destroy_card on the discarded card. PC's
-- evolution (Magmortar, via a Linking Cord) is not ported: the target
-- is not Gen 1 and the item is not in this pack.
SMODS.Joker {
    key = "magmar",
    sprite = "magmar.png",
    negative_sprite = "magmar_negative.png",
    loc_txt = {
        name = "Magmar",
        text = {
            "If {C:attention}first discard{} of round",
            "has only {C:attention}1{} card, destroy",
            "it and gain {C:mult}+#2#{} Mult",
            "{C:inactive}(Currently {C:mult}+#1#{C:inactive} Mult)",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult,
            card.ability.extra.mult_mod } }
    end,
    rarity = 3,
    cost = 7,
    perishable_compat = false,
    config = { extra = { mult = 0, mult_mod = 2, discards = 0 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.discard and not context.blueprint then
            local batch = context.port and context.port.discarded_nodes
                or {}
            local first = (card.ability.extra.discards or 0) == 0
            card.ability.extra.discards =
                (card.ability.extra.discards or 0) + 1
            if first and #batch == 1 and context.other_card then
                card.ability.extra.mult = card.ability.extra.mult
                    + card.ability.extra.mult_mod
                if SMODS.destroy_card then
                    SMODS.destroy_card(context.other_card)
                end
                return { message = "+" .. card.ability.extra.mult_mod
                    .. " Mult" }
            end
        end
        if context.joker_main and card.ability.extra.mult > 0 then
            return {
                mult_mod = card.ability.extra.mult,
                message = "+" .. card.ability.extra.mult .. " Mult",
            }
        end
        if context.end_of_round and not context.blueprint then
            card.ability.extra.discards = 0
        end
    end,
}

-- Tauros (Leader): Tauros and Tauros (Herd) Jokers each give X1.75
-- Mult (PC's context.other_joker is the fork's post_trigger; Miltank
-- is not in this pack). DEVIATION: PC's reroll effect (1 in 15 chance
-- to add a Tauros (Herd) to the shop on reroll) is dropped -- the fork
-- has no API to inject a specific Joker into the shop offers, and
-- SMODS.add_card would hand the Joker to the player for free instead.
SMODS.Joker {
    key = "tauros",
    sprite = "tauros.png",
    negative_sprite = "tauros_negative.png",
    loc_txt = {
        name = "Tauros (Leader)",
        text = {
            "{C:attention}Tauros{} and {C:attention}Tauros (Herd){} Jokers",
            "each give {X:mult,C:white} X#1# {} Mult",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.xmult } }
    end,
    rarity = 2,
    cost = 7,
    config = { extra = { xmult = 1.75, num = 1, dem = 15 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.post_trigger and context.other_card
            and context.other_card ~= card
            and context.other_card.def then
            local id = context.other_card.def.id
            if id == "j_pokep_tauros" or id == "j_pokep_taurosh" then
                return {
                    x_mult = card.ability.extra.xmult,
                    message = "X" .. card.ability.extra.xmult .. " Mult",
                }
            end
        end
    end,
}

-- Tauros (Herd): +6 Mult. PC marks it aux / no_collection with
-- in_pool = false (it only ever arrives via the Leader's reroll
-- effect, dropped above); the in_pool gate is kept.
flat_mult("taurosh", "Tauros (Herd)", nil, 3, 6, 6, {
    in_pool = function(self, args) return false end,
})

-- Lapras: +25 Chips for each Blind skipped this run. The fork has no
-- run skip counter, so this Joker counts its own skip_blind contexts
-- (skips made before Lapras was obtained are not counted).
-- DEVIATION: PC's second effect (skipping a Blind no longer skips the
-- Shop) is dropped -- skip_blind fires after the skip is resolved and
-- the fork exposes no way to force the shop to open after a skip.
SMODS.Joker {
    key = "lapras",
    sprite = "lapras.png",
    negative_sprite = "lapras_negative.png",
    loc_txt = {
        name = "Lapras",
        text = {
            "{C:chips}+#2#{} Chips for each",
            "{C:attention}Blind{} skipped this run",
            "{C:inactive}(Currently {C:chips}+#1#{C:inactive} Chips)",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = {
            (card.ability.extra.skips or 0) * card.ability.extra.chip_mod,
            card.ability.extra.chip_mod } }
    end,
    rarity = 3,
    cost = 5,
    perishable_compat = false,
    config = { extra = { chips = 0, chip_mod = 25, skips = 0 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.skip_blind and not context.blueprint then
            card.ability.extra.skips = (card.ability.extra.skips or 0) + 1
            card.ability.extra.chips = card.ability.extra.skips
                * card.ability.extra.chip_mod
            return { message = "+" .. card.ability.extra.chip_mod
                .. " Chips" }
        end
        if context.joker_main and (card.ability.extra.chips or 0) > 0 then
            return {
                chip_mod = card.ability.extra.chips,
                message = "+" .. card.ability.extra.chips .. " Chips",
            }
        end
    end,
}

-- Eevee: +4 Mult for each held Joker that can evolve. The fork exposes
-- no stage/evolution metadata on held Jokers, so the count tests def
-- ids against the pre-forms this pack actually evolves (level, scaling
-- and stone chains in pokermonpack.lua plus this fragment) -- PC
-- counts any staged Joker with an evolution, including lines this
-- pack has not ported. Stone evolution is branching (see header).
local POKE4_EVOLVABLE = {
    j_pokep_bulbasaur = true, j_pokep_ivysaur = true,
    j_pokep_charmander = true, j_pokep_charmeleon = true,
    j_pokep_squirtle = true, j_pokep_wartortle = true,
    j_pokep_caterpie = true, j_pokep_metapod = true,
    j_pokep_weedle = true, j_pokep_kakuna = true,
    j_pokep_magikarp = true, j_pokep_pidgey = true,
    j_pokep_pidgeotto = true, j_pokep_rattata = true,
    j_pokep_ekans = true, j_pokep_sandshrew = true,
    j_pokep_diglett = true, j_pokep_tentacool = true,
    j_pokep_krabby = true, j_pokep_magnemite = true,
    j_pokep_goldeen = true, j_pokep_growlithe = true,
    j_pokep_shellder = true, j_pokep_pikachu = true,
    j_pokep_clefairy = true, j_pokep_jigglypuff = true,
    j_pokep_staryu = true, j_pokep_eevee = true,
    j_pokep_omanyte = true, j_pokep_kabuto = true,
    j_pokep_dratini = true, j_pokep_dragonair = true,
}
local function poke4_evolvable_count()
    local n = 0
    for _, j in ipairs(G and G.jokers or {}) do
        if j.def and POKE4_EVOLVABLE[j.def.id] then n = n + 1 end
    end
    return n
end
SMODS.Joker {
    key = "eevee",
    sprite = "eevee.png",
    negative_sprite = "eevee_negative.png",
    loc_txt = {
        name = "Eevee",
        text = {
            "{C:mult}+#1#{} Mult for each",
            "Joker you have that",
            "can {C:attention}evolve",
            "{C:inactive}(Currently {C:mult}+#2#{C:inactive} Mult)",
            "{C:inactive}(Evolves with...a lot)",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult_mod,
            card.ability.extra.mult_mod * poke4_evolvable_count() } }
    end,
    rarity = 1,
    cost = 3,
    config = { extra = { mult_mod = 4 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.joker_main then
            local total = card.ability.extra.mult_mod
                * poke4_evolvable_count()
            if total > 0 then
                return { mult_mod = total,
                    message = "+" .. total .. " Mult" }
            end
        end
    end,
}

-- Vaporeon: when a Bonus card scores, every card in the poker hand
-- permanently gains +4 Chips (once per scoring Bonus card, as on PC).
SMODS.Joker {
    key = "vaporeon",
    sprite = "vaporeon.png",
    negative_sprite = "vaporeon_negative.png",
    loc_txt = {
        name = "Vaporeon",
        text = {
            "Every card in {C:attention}poker hand",
            "permanently gains {C:chips}+#1#{} Chips",
            "when a {C:attention}Bonus{} card scores",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chip_mod } }
    end,
    rarity = 3,
    cost = 7,
    config = { extra = { chip_mod = 4 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play
            and SMODS.set_perma and SMODS.get_perma then
            local oc = context.other_card
            if oc and not oc.debuff and oc.enhancement == "bonus"
                and context.scoring_hand then
                for _, c in ipairs(context.scoring_hand) do
                    SMODS.set_perma(c, "perma_bonus",
                        (SMODS.get_perma(c, "perma_bonus") or 0)
                        + card.ability.extra.chip_mod)
                end
                return { message = "Upgrade!" }
            end
        end
    end,
}

-- Jolteon: earn $5 for each discarded Gold card.
SMODS.Joker {
    key = "jolteon",
    sprite = "jolteon.png",
    negative_sprite = "jolteon_negative.png",
    loc_txt = {
        name = "Jolteon",
        text = {
            "Earn {C:money}$#1#{} for each",
            "discarded {C:attention}Gold{} card",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.money } }
    end,
    rarity = 3,
    cost = 7,
    config = { extra = { money = 5 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.discard then
            local oc = context.other_card
            if oc and oc.enhancement == "gold" then
                if oc.debuff then
                    return { message = "Debuffed!" }
                end
                return {
                    dollars = card.ability.extra.money,
                    message = "+$" .. card.ability.extra.money,
                }
            end
        end
    end,
}

-- Flareon: the last 2 played Mult cards give X2 Mult when scored.
SMODS.Joker {
    key = "flareon",
    sprite = "flareon.png",
    negative_sprite = "flareon_negative.png",
    loc_txt = {
        name = "Flareon",
        text = {
            "Last {C:attention}2{} played {C:attention}Mult{} cards",
            "give {X:mult,C:white} X#1# {} Mult",
            "when scored",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.xmult } }
    end,
    rarity = 3,
    cost = 7,
    config = { extra = { xmult = 2 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play
            and context.scoring_hand then
            local oc = context.other_card
            if not oc or oc.debuff then return end
            local mult_cards = {}
            for _, c in ipairs(context.scoring_hand) do
                if c.enhancement == "mult" then
                    mult_cards[#mult_cards + 1] = c
                end
            end
            if oc == mult_cards[#mult_cards]
                or (#mult_cards > 1
                    and oc == mult_cards[#mult_cards - 1]) then
                return {
                    x_mult = card.ability.extra.xmult,
                    message = "X" .. card.ability.extra.xmult .. " Mult",
                }
            end
        end
    end,
}

-- Ancient helpers (Omanyte line, Kabuto line, Aerodactyl): PC's
-- pokermon.get_ancient_amount counts scoring cards of one rank; the
-- port counts them in `before` and reads the stored count afterwards.
local function poke4_ancient_count(card, context, rank_id)
    local n = 0
    for _, c in ipairs(context.scoring_hand or {}) do
        if c.get_id and c:get_id() == rank_id then n = n + 1 end
    end
    card.ability.extra.ancient_count = n
    return n
end
local function poke4_create_consumable(kind, set, seed)
    if not (G and G.random_consumable_id_of_kind and SMODS.add_card) then
        return nil
    end
    local id = G:random_consumable_id_of_kind(kind, {}, seed)
    if not id then return nil end
    return SMODS.add_card { set = set, key = id }
end

-- Omanyte: Ancient 3s. 1+: create a Tarot; 2+: earn $2; 3+: create an
-- Item card. Triggering the 3+ ability 5 times evolves it (scaling).
SMODS.Joker {
    key = "omanyte",
    sprite = "omanyte.png",
    negative_sprite = "omanyte_negative.png",
    loc_txt = {
        name = "Omanyte",
        text = {
            "{C:attention}Ancient #1#s{}",
            "{X:attention,C:white}1+{} : Create a {C:tarot}Tarot{} card",
            "{X:attention,C:white}2+{} : Earn {C:money}$#2#{}",
            "{X:attention,C:white}3+{} : Create an {C:attention}Item{} card",
            "{C:inactive}(Must have room)",
            "{C:inactive}(Trigger {X:attention,C:white}3+{C:inactive} ability {C:attention}#3#{C:inactive} times to evolve)",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { "3", card.ability.extra.money,
            math.max(0, 5 - (card.ability.extra.third_times or 0)) } }
    end,
    rarity = 2,
    cost = 5,
    config = { extra = { rank = "3", money = 2, third_times = 0,
        ancient_count = 0 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.before and context.scoring_hand then
            poke4_ancient_count(card, context, 3)
        end
        if context.joker_main then
            local n = card.ability.extra.ancient_count or 0
            if n > 0 then
                if not context.blueprint then
                    poke4_create_consumable("tarot", "Tarot",
                        "poke_omanyte")
                    if n > 2 then
                        card.ability.extra.third_times =
                            (card.ability.extra.third_times or 0) + 1
                        poke4_create_consumable("poke_item", "poke_item",
                            "poke_omanyte_item")
                    end
                end
                if n > 1 then
                    return { dollars = card.ability.extra.money,
                        message = "+$" .. card.ability.extra.money }
                end
            end
        end
        if context.after then card.ability.extra.ancient_count = 0 end
        poke_scaling_evo(card, context, "j_pokep_omastar",
            card.ability.extra.third_times, 5)
    end,
}

-- Omastar: Ancient 3s, as Omanyte at $4, plus 4+: create a random Tag
-- (Handy, Garbage, Investment, Economy or D6) once per round.
SMODS.Joker {
    key = "omastar",
    sprite = "omastar.png",
    negative_sprite = "omastar_negative.png",
    loc_txt = {
        name = "Omastar",
        text = {
            "{C:attention}Ancient #1#s{}",
            "{X:attention,C:white}1+{} : Create a {C:tarot}Tarot{} card",
            "{X:attention,C:white}2+{} : Earn {C:money}$#2#{}",
            "{X:attention,C:white}3+{} : Create an {C:attention}Item{} card",
            "{C:inactive}(Must have room)",
            "{X:attention,C:white}4+{} : Create a {C:attention}Tag{} once per round #3#",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { "3", card.ability.extra.money,
            card.ability.extra.tag_created and "" or "(Active)" } }
    end,
    rarity = 3,
    cost = 8,
    config = { extra = { rank = "3", money = 4, tag_created = false,
        ancient_count = 0 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.before and context.scoring_hand then
            poke4_ancient_count(card, context, 3)
        end
        if context.joker_main then
            local n = card.ability.extra.ancient_count or 0
            if n > 0 then
                if not context.blueprint then
                    poke4_create_consumable("tarot", "Tarot",
                        "poke_omastar")
                    if n > 2 then
                        poke4_create_consumable("poke_item", "poke_item",
                            "poke_omastar_item")
                    end
                    if n > 3 and not card.ability.extra.tag_created
                        and G and G.addTag then
                        card.ability.extra.tag_created = true
                        G:addTag(SMODS.pseudorandom_element(
                            { "handy", "garbage", "investment",
                                "economy", "d6" }, "poke_omastar_tag"))
                    end
                end
                if n > 1 then
                    return { dollars = card.ability.extra.money,
                        message = "+$" .. card.ability.extra.money }
                end
            end
        end
        if context.after then card.ability.extra.ancient_count = 0 end
        if context.end_of_round and not context.blueprint then
            card.ability.extra.tag_created = false
        end
    end,
}

-- Kabuto: Ancient 2s. 1+: +50 Chips; 2+: scoring 2s permanently gain
-- +5 Chips; 3+: +50 more Chips. Triggering the 3+ ability 5 times
-- evolves it (scaling).
SMODS.Joker {
    key = "kabuto",
    sprite = "kabuto.png",
    negative_sprite = "kabuto_negative.png",
    loc_txt = {
        name = "Kabuto",
        text = {
            "{C:attention}Ancient #1#s{}",
            "{X:attention,C:white}1+{} : {C:chips}+#2#{} Chips",
            "{X:attention,C:white}2+{} : Scoring {C:attention}#1#s{} permanently gain {C:chips}+#3#{} Chips",
            "{X:attention,C:white}3+{} : {C:chips}+#4#{} Chips",
            "{C:inactive}(Trigger {X:attention,C:white}3+{C:inactive} ability {C:attention}#5#{C:inactive} times to evolve)",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { "2", card.ability.extra.chips1,
            card.ability.extra.chips2, card.ability.extra.chips3,
            math.max(0, 5 - (card.ability.extra.third_times or 0)) } }
    end,
    rarity = 2,
    cost = 5,
    config = { extra = { rank = "2", chips1 = 50, chips2 = 5,
        chips3 = 50, third_times = 0, ancient_count = 0 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.before and context.scoring_hand then
            poke4_ancient_count(card, context, 2)
        end
        if context.joker_main then
            local n = card.ability.extra.ancient_count or 0
            if n > 0 then
                local chips = card.ability.extra.chips1
                if n > 2 then
                    if not context.blueprint then
                        card.ability.extra.third_times =
                            (card.ability.extra.third_times or 0) + 1
                    end
                    chips = chips + card.ability.extra.chips3
                end
                return { chip_mod = chips,
                    message = "+" .. chips .. " Chips" }
            end
        end
        if context.individual and context.cardarea == G.play
            and (card.ability.extra.ancient_count or 0) > 1
            and SMODS.set_perma and SMODS.get_perma then
            local oc = context.other_card
            if oc and not oc.debuff and oc:get_id() == 2 then
                SMODS.set_perma(oc, "perma_bonus",
                    (SMODS.get_perma(oc, "perma_bonus") or 0)
                    + card.ability.extra.chips2)
                return { message = "Upgrade!" }
            end
        end
        if context.after then card.ability.extra.ancient_count = 0 end
        poke_scaling_evo(card, context, "j_pokep_kabutops",
            card.ability.extra.third_times, 5)
    end,
}

-- Kabutops: Ancient 2s, as Kabuto at 70 Chips, plus 4+: retrigger all
-- played 2s.
SMODS.Joker {
    key = "kabutops",
    sprite = "kabutops.png",
    negative_sprite = "kabutops_negative.png",
    loc_txt = {
        name = "Kabutops",
        text = {
            "{C:attention}Ancient #1#s{}",
            "{X:attention,C:white}1+{} : {C:chips}+#2#{} Chips",
            "{X:attention,C:white}2+{} : Scoring {C:attention}#1#s{} permanently gain {C:chips}+#3#{} Chips",
            "{X:attention,C:white}3+{} : {C:chips}+#4#{} Chips",
            "{X:attention,C:white}4+{} : Retrigger all played {C:attention}#1#s{}",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { "2", card.ability.extra.chips1,
            card.ability.extra.chips2, card.ability.extra.chips3,
            card.ability.extra.retriggers } }
    end,
    rarity = 3,
    cost = 8,
    config = { extra = { rank = "2", chips1 = 70, chips2 = 5,
        chips3 = 70, retriggers = 1, ancient_count = 0 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.before and context.scoring_hand then
            poke4_ancient_count(card, context, 2)
        end
        if context.joker_main then
            local n = card.ability.extra.ancient_count or 0
            if n > 0 then
                local chips = card.ability.extra.chips1
                if n > 2 then chips = chips + card.ability.extra.chips3 end
                return { chip_mod = chips,
                    message = "+" .. chips .. " Chips" }
            end
        end
        if context.individual and context.cardarea == G.play
            and (card.ability.extra.ancient_count or 0) > 1
            and SMODS.set_perma and SMODS.get_perma then
            local oc = context.other_card
            if oc and not oc.debuff and oc:get_id() == 2 then
                SMODS.set_perma(oc, "perma_bonus",
                    (SMODS.get_perma(oc, "perma_bonus") or 0)
                    + card.ability.extra.chips2)
                return { message = "Upgrade!" }
            end
        end
        if context.repetition and context.cardarea == G.play
            and (card.ability.extra.ancient_count or 0) > 3 then
            local oc = context.other_card
            if oc and oc:get_id() == 2 then
                return { repetitions = card.ability.extra.retriggers,
                    message = "Again!" }
            end
        end
        if context.after then card.ability.extra.ancient_count = 0 end
    end,
}

-- Aerodactyl: Ancient Aces. 1+: X2 Mult; 2+: gains X0.5 Mult; 3+: the
-- first scoring unenhanced Ace becomes a Glass card; 4+: double this
-- Joker's X Mult. Resets at end of round (PC's two scale_card steps,
-- in PC's order: the +0.5 lands before the doubling).
SMODS.Joker {
    key = "aerodactyl",
    sprite = "aerodactyl.png",
    negative_sprite = "aerodactyl_negative.png",
    loc_txt = {
        name = "Aerodactyl",
        text = {
            "{C:attention}Ancient #1#s{}",
            "{X:attention,C:white}1+{} : {X:mult,C:white}X#2#{} Mult",
            "{X:attention,C:white}2+{} : Gains {X:mult,C:white}X#3#{} Mult",
            "{X:attention,C:white}3+{} : The first scoring unenhanced {C:attention}#1#{}",
            "becomes a {C:attention}Glass{} card",
            "{X:attention,C:white}4+{} : {C:attention}Double{} this Joker's {X:mult,C:white}X{} Mult",
            "{C:inactive}(Resets at end of round){}",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { "Ace", card.ability.extra.xmult,
            card.ability.extra.xmult_mod } }
    end,
    rarity = 3,
    cost = 6,
    config = { extra = { rank = "Ace", xmult = 2, xmult_mod = 0.5,
        xmult_reset = 2, ancient_count = 0 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.before and context.scoring_hand then
            local n = poke4_ancient_count(card, context, 14)
            if n > 2 and not context.blueprint then
                for _, c in ipairs(context.scoring_hand) do
                    if c.get_id and c:get_id() == 14
                        and (not c.enhancement or c.enhancement == "base")
                        and c.set_enhancement then
                        c:set_enhancement("glass")
                        return { message = "Glass!" }
                    end
                end
            end
        end
        if context.joker_main then
            local n = card.ability.extra.ancient_count or 0
            if n > 0 then
                if not context.blueprint then
                    if n > 1 then
                        card.ability.extra.xmult =
                            card.ability.extra.xmult
                            + card.ability.extra.xmult_mod
                    end
                    if n > 3 then
                        card.ability.extra.xmult =
                            card.ability.extra.xmult * 2
                    end
                end
                return { x_mult = card.ability.extra.xmult,
                    message = "X" .. card.ability.extra.xmult .. " Mult" }
            end
        end
        if context.after then card.ability.extra.ancient_count = 0 end
        if context.end_of_round and not context.blueprint
            and not context.individual and not context.repetition then
            card.ability.extra.xmult = card.ability.extra.xmult_reset
            return { message = "Reset!" }
        end
    end,
}

-- Zapdos: X0.08 Mult for every $2 you have.
SMODS.Joker {
    key = "zapdos",
    sprite = "zapdos.png",
    negative_sprite = "zapdos_negative.png",
    soul_sprite = "zapdos_soul.png",
    loc_txt = {
        name = "Zapdos",
        text = {
            "{X:mult,C:white} X#1# {} Mult for",
            "every {C:money}$#2#{} you have",
            "{C:inactive}(Currently {X:mult,C:white}X#3#{C:inactive} Mult)",
        },
    },
    loc_vars = function(self, info_queue, card)
        local cur = 1 + card.ability.extra.xmult
            * math.floor(math.max(0, tonumber(G and G.money) or 0)
                / card.ability.extra.money_threshold)
        return { vars = { card.ability.extra.xmult,
            card.ability.extra.money_threshold, cur } }
    end,
    rarity = 4,
    cost = 20,
    config = { extra = { xmult = 0.08, money_threshold = 2 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.joker_main then
            local total = 1 + card.ability.extra.xmult
                * math.floor(math.max(0, tonumber(G.money) or 0)
                    / card.ability.extra.money_threshold)
            if total > 1 then
                return { x_mult = total,
                    message = "X" .. total .. " Mult" }
            end
        end
    end,
}

-- Dratini: gains +1 Mult whenever a played hand has 3 or fewer cards;
-- evolves at +15 Mult (scaling).
SMODS.Joker {
    key = "dratini",
    sprite = "dratini.png",
    negative_sprite = "dratini_negative.png",
    loc_txt = {
        name = "Dratini",
        text = {
            "Gains {C:mult}+#2#{} Mult if",
            "played hand contains",
            "{C:attention}#3#{} or fewer cards",
            "{C:inactive}(Evolves at {C:mult}+#1#{C:inactive} / +#4# Mult)",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult,
            card.ability.extra.mult_mod, card.ability.extra.size,
            card.ability.extra.evo_rqmt } }
    end,
    rarity = 2,
    cost = 6,
    perishable_compat = false,
    config = { extra = { mult = 0, mult_mod = 1, size = 3,
        evo_rqmt = 15 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.before and not context.blueprint
            and context.full_hand
            and #context.full_hand <= card.ability.extra.size then
            card.ability.extra.mult = card.ability.extra.mult
                + card.ability.extra.mult_mod
        end
        if context.joker_main and card.ability.extra.mult > 0 then
            return { mult_mod = card.ability.extra.mult,
                message = "+" .. card.ability.extra.mult .. " Mult" }
        end
        poke_scaling_evo(card, context, "j_pokep_dragonair",
            card.ability.extra.mult, card.ability.extra.evo_rqmt)
    end,
}

-- Dragonair: gains +2 Mult whenever a played hand has 2 or fewer
-- cards; evolves at +55 Mult (scaling).
SMODS.Joker {
    key = "dragonair",
    sprite = "dragonair.png",
    negative_sprite = "dragonair_negative.png",
    loc_txt = {
        name = "Dragonair",
        text = {
            "Gains {C:mult}+#2#{} Mult if",
            "played hand contains",
            "{C:attention}#3#{} or fewer cards",
            "{C:inactive}(Evolves at {C:mult}+#1#{C:inactive} / +#4# Mult)",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult,
            card.ability.extra.mult_mod, card.ability.extra.size,
            card.ability.extra.evo_rqmt } }
    end,
    rarity = 3,
    cost = 8,
    perishable_compat = false,
    config = { extra = { mult = 0, mult_mod = 2, size = 2,
        evo_rqmt = 55 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.before and not context.blueprint
            and context.full_hand
            and #context.full_hand <= card.ability.extra.size then
            card.ability.extra.mult = card.ability.extra.mult
                + card.ability.extra.mult_mod
        end
        if context.joker_main and card.ability.extra.mult > 0 then
            return { mult_mod = card.ability.extra.mult,
                message = "+" .. card.ability.extra.mult .. " Mult" }
        end
        poke_scaling_evo(card, context, "j_pokep_dragonite",
            card.ability.extra.mult, card.ability.extra.evo_rqmt)
    end,
}

-- Dragonite: +55 Mult; if the played hand is exactly 1 scoring card,
-- retrigger it 5 additional times.
SMODS.Joker {
    key = "dragonite",
    sprite = "dragonite.png",
    negative_sprite = "dragonite_negative.png",
    loc_txt = {
        name = "Dragonite",
        text = {
            "{C:mult}+#1#{} Mult",
            "If played hand contains",
            "exactly {C:attention}1{} card, retrigger",
            "it {C:attention}#2#{} additional times",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult,
            card.ability.extra.retriggers } }
    end,
    rarity = 3,
    cost = 10,
    config = { extra = { mult = 55, retriggers = 5 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.joker_main then
            return { mult_mod = card.ability.extra.mult,
                message = "+" .. card.ability.extra.mult .. " Mult" }
        end
        if context.repetition and context.cardarea == G.play then
            local _, total = scoring_pos(context)
            if total == 1 then
                return { repetitions = card.ability.extra.retriggers,
                    message = "Again!" }
            end
        end
    end,
}

-- Mewtwo: Polychrome Jokers give X1.2 Mult (PC's context.other_joker
-- is the fork's post_trigger). When a Boss Blind is defeated, create a
-- Polychrome duplicate of the leftmost Joker, then destroy the
-- leftmost Joker (never itself; an Eternal leftmost Joker is not
-- destroyed, as on PC). DEVIATIONS: PC's copy_card duplicate keeps
-- the original's scaled ability values -- the fork has no Joker copy
-- API, so the duplicate is a fresh copy of the same def created with
-- SMODS.add_card (edition Polychrome); and the duplicate's Energize
-- step is stripped with the rest of the Energy system. The fork's
-- blind_defeated context (Boss = blind_index 3, the Paperback
-- pattern) stands in for PC's end-of-round Boss check.
SMODS.Joker {
    key = "mewtwo",
    sprite = "mewtwo.png",
    negative_sprite = "mewtwo_negative.png",
    soul_sprite = "mewtwo_soul.png",
    loc_txt = {
        name = "Mewtwo",
        text = {
            "When {C:attention}Boss Blind{} is defeated, create a",
            "{C:dark_edition}Polychrome{} {C:attention}duplicate{} of leftmost",
            "{C:attention}Joker{}, then destroy leftmost {C:attention}Joker{}",
            "{C:dark_edition}Polychrome{} Jokers give {X:mult,C:white} X#1# {} Mult",
            "{C:inactive}(Can't destroy self)",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.xmult_multi } }
    end,
    rarity = 4,
    cost = 20,
    config = { extra = { xmult_multi = 1.2 } },
    blueprint_compat = false,
    calculate = function(self, card, context)
        if context.post_trigger and context.other_card
            and context.other_card ~= card
            and context.other_card.edition == "polychrome" then
            return { x_mult = card.ability.extra.xmult_multi,
                message = "X" .. card.ability.extra.xmult_multi
                    .. " Mult" }
        end
        if context.blind_defeated and not context.blueprint then
            local boss = (context.port
                    and context.port.blind_index == 3)
                or (tonumber(G.current_blind_index) == 3)
            if not boss then return end
            local jokers = G and G.jokers or {}
            local leftmost = jokers[1]
            if not leftmost or leftmost == card then return end
            local key = leftmost.def and leftmost.def.id
            if not key or not SMODS.add_card then return end
            if leftmost.eternal then
                -- add_card itself refuses when there is no room,
                -- which is PC's eternal-case capacity check.
                SMODS.add_card { set = "Joker", key = key,
                    edition = "polychrome" }
            elseif SMODS.destroy_joker
                and SMODS.destroy_joker(leftmost) then
                SMODS.add_card { set = "Joker", key = key,
                    edition = "polychrome" }
                return { message = "Duplicated!" }
            end
        end
    end,
}

-- Mew: at the end of the shop, a fixed 15% chance (PC: odds can't be
-- increased, so the roll is a plain pseudorandom, not a probability
-- context) to create a Negative Joker instead of a Negative Tarot,
-- Spectral or Item card.
SMODS.Joker {
    key = "mew",
    sprite = "mew.png",
    negative_sprite = "mew_negative.png",
    soul_sprite = "mew_soul.png",
    loc_txt = {
        name = "Mew",
        text = {
            "At the end of the {C:attention}shop{},",
            "create a {C:dark_edition}Negative{} {C:tarot}Tarot{},",
            "{C:spectral}Spectral{} or {C:attention}Item{} card",
            "{C:green}#1#%{} chance to create a",
            "{C:dark_edition}Negative{} Joker {C:attention}instead{}",
            "{C:inactive}(Odds can't be increased){}",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.percent } }
    end,
    rarity = 4,
    cost = 20,
    config = { extra = { percent = 15 } },
    blueprint_compat = true,
    calculate = function(self, card, context)
        if context.ending_shop and not context.blueprint
            and SMODS.add_card then
            if pseudorandom("poke_mew")
                < card.ability.extra.percent / 100 then
                if SMODS.add_card { set = "Joker",
                    edition = "negative" } then
                    return { message = "+ Joker" }
                end
            else
                local kind = SMODS.pseudorandom_element(
                    { "tarot", "spectral", "poke_item" },
                    "poke_mew_create")
                local set = kind == "tarot" and "Tarot"
                    or kind == "spectral" and "Spectral" or "poke_item"
                if G and G.random_consumable_id_of_kind then
                    local id = G:random_consumable_id_of_kind(
                        kind, {}, "poke_mew")
                    if id and SMODS.add_card { set = set, key = id,
                        edition = "negative" } then
                        return { message = "+ Card" }
                    end
                end
            end
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
-- (PC "item_req" on the base forms): Fire (Growlithe, Vulpix, Eevee),
-- Water (Shellder, Poliwhirl, Staryu, Eevee), Thunder (Pikachu,
-- Eevee), Moon (Clefairy, Jigglypuff, Nidorina, Nidorino) and, since
-- v1.4.0, Leaf (Gloom, Weepinbell, Exeggcute) -- its Gen 1 targets
-- joined the pack in the same wave. Magneton is NOT a Thunder Stone
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

    -- Per stone: base Joker id -> its evolved form (PC item_req / the
    -- chains documented at the top of this file). Keyed by stone first
    -- because Eevee branches: one pre-form under three stones (pack
    -- v1.4.0; the v1.2.0 1:1 STONE_OF map could not express that).
    local STONE_TARGETS = {
        firestone = {
            j_pokep_growlithe = "j_pokep_arcanine",
            j_pokep_vulpix = "j_pokep_ninetales",
            j_pokep_eevee = "j_pokep_flareon",
        },
        waterstone = {
            j_pokep_shellder = "j_pokep_cloyster",
            j_pokep_poliwhirl = "j_pokep_poliwrath",
            j_pokep_staryu = "j_pokep_starmie",
            j_pokep_eevee = "j_pokep_vaporeon",
        },
        thunderstone = {
            j_pokep_pikachu = "j_pokep_raichu",
            j_pokep_eevee = "j_pokep_jolteon",
        },
        moonstone = {
            j_pokep_clefairy = "j_pokep_clefable",
            j_pokep_jigglypuff = "j_pokep_wigglytuff",
            j_pokep_nidorina = "j_pokep_nidoqueen",
            j_pokep_nidorino = "j_pokep_nidoking",
        },
        leafstone = {
            j_pokep_gloom = "j_pokep_vileplume",
            j_pokep_weepinbell = "j_pokep_victreebel",
            j_pokep_exeggcute = "j_pokep_exeggutor",
        },
    }

    -- Is `target` a Joker this stone may evolve right now: the right
    -- pre-form, actually held, and not debuffed (as on PC)? The
    -- engine only ever resolves held Jokers as targets, but the held
    -- check keeps can_use honest when called directly.
    local function stone_target_ok(stone_key, target)
        if type(target) ~= "table" or not target.def then return false end
        local targets = STONE_TARGETS[stone_key]
        if not targets or not targets[target.def.id] then return false end
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
                    poke_evolve(target, STONE_TARGETS[key][target.def.id])
                end
            end,
        }
    end

    evolution_stone("firestone", "Fire Stone", {
        "{C:attention}Evolution Card{}",
        "Evolves the {C:attention}chosen Growlithe{} into",
        "{C:attention}Arcanine{}, {C:attention}Vulpix{} into {C:attention}Ninetales{},",
        "or {C:attention}Eevee{} into {C:attention}Flareon{}",
        "{C:inactive}(Open a Joker's tooltip, then use){}",
    })
    evolution_stone("waterstone", "Water Stone", {
        "{C:attention}Evolution Card{}",
        "Evolves the {C:attention}chosen Shellder{} into",
        "{C:attention}Cloyster{}, {C:attention}Poliwhirl{} into {C:attention}Poliwrath{},",
        "{C:attention}Staryu{} into {C:attention}Starmie{}, or {C:attention}Eevee{} into {C:attention}Vaporeon{}",
        "{C:inactive}(Open a Joker's tooltip, then use){}",
    })
    evolution_stone("thunderstone", "Thunder Stone", {
        "{C:attention}Evolution Card{}",
        "Evolves the {C:attention}chosen Pikachu{} into",
        "{C:attention}Raichu{}, or {C:attention}Eevee{} into {C:attention}Jolteon{}",
        "{C:inactive}(Open a Joker's tooltip, then use){}",
    })
    evolution_stone("moonstone", "Moon Stone", {
        "{C:attention}Evolution Card{}",
        "Evolves the {C:attention}chosen Clefairy{} into",
        "{C:attention}Clefable{}, {C:attention}Jigglypuff{} into {C:attention}Wigglytuff{},",
        "{C:attention}Nidorina{} into {C:attention}Nidoqueen{}, or",
        "{C:attention}Nidorino{} into {C:attention}Nidoking{}",
        "{C:inactive}(Open a Joker's tooltip, then use){}",
    })
    evolution_stone("leafstone", "Leaf Stone", {
        "{C:attention}Evolution Card{}",
        "Evolves the {C:attention}chosen Gloom{} into",
        "{C:attention}Vileplume{}, {C:attention}Weepinbell{} into {C:attention}Victreebel{},",
        "or {C:attention}Exeggcute{} into {C:attention}Exeggutor{}",
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
