--- KCVanilla Pack (3DS Port) for the Balatro3DS FORK.
---
--- Fourteen Jokers ported from KCVanilla by krackocloud (PC / Steamodded + Lovely):
--- Composition, Royal Guard, Joker-chan, Red Envelope, Jimbot, Ten-Pin,
--- Handy Joker, Joker Energy, Power Grid, plus (v1.1.0, fork-only)
--- Fortune Cookie, Rats!, Cosmic Collapse, Loose Tooth and Scapegoat.
--- (Swiss Cheese ships separately as the KCVanillaSwiss mod.)
---
--- The five v1.1.0 Jokers create and destroy cards, which the stock game's
--- mod API cannot do: they need the fork's Tier 1 API (SMODS.add_card /
--- SMODS.destroy_joker / SMODS.destroy_card) and will not load their
--- effects on the Universal-Updater build. The original nine run on either.
---
--- Port notes: Balatro3DS has no Lovely and no G.GAME, so each Joker is
--- re-expressed with the port's documented mod API only
--- (joker_main / individual / after / discard / end_of_round / calc_dollar_bonus
--- plus the game's own full-deck counter). Where PC Balatro auto-applies an
--- ability field (Handy and Ten-Pin's x_mult), the port returns it from
--- joker_main instead. Descriptions are KCVanilla's en-us text, verbatim.

--- How many held Jokers are Common (rarity 1). On PC this counts
--- G.jokers.cards; Balatro3DS holds plain Joker objects in G.jokers.
local function kcvp_common_count()
    if not (G and G.jokers) then return 0 end
    local list = G.jokers.cards or G.jokers
    if type(list) ~= "table" then return 0 end
    local count = 0
    for _, j in ipairs(list) do
        local r = j.rarity
        if r == nil and j.def then r = j.def.rarity end
        if r == nil and j.config and j.config.center then r = j.config.center.rarity end
        if tonumber(r) == 1 then count = count + 1 end
    end
    return count
end

--------------------------------------------------------------------------------
-- Composition: +4 Mult per Joker to the left, +20 Chips per Joker to the right
--------------------------------------------------------------------------------

local function kcvp_composition_effect(card, extramult, extrachips)
    if not (G and G.jokers) then return { chips = 0, mult = 0 } end
    local list = G.jokers.cards or G.jokers
    if type(list) ~= "table" then return { chips = 0, mult = 0 } end
    local my_pos = nil
    local left, right = 0, 0
    for i = 1, #list do
        if list[i] == card then
            my_pos = i
        elseif my_pos == nil then
            left = left + 1
        else
            right = right + 1
        end
    end
    if my_pos == nil then return { chips = 0, mult = 0 } end
    return { chips = right * extrachips, mult = left * extramult }
end

SMODS.Joker {
    key = "composition",
    loc_txt = {
        name = "Composition",
        text = {
            "{C:mult}+#1#{} Mult for each Joker to the left,",
            "{C:chips}+#2#{} Chips for each Joker to the right",
            "{C:inactive}(Currently {C:mult}+#3#{C:inactive} Mult and {C:chips}+#4#{C:inactive} Chips){}",
        },
    },
    config = { extra = { mult = 4, chips = 20 } },
    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "composition.png",
    negative_sprite = "composition_negative.png",
    loc_vars = function(self, info_queue, card)
        local effect = kcvp_composition_effect(card, card.ability.extra.mult, card.ability.extra.chips)
        return { vars = { card.ability.extra.mult, card.ability.extra.chips, effect.mult, effect.chips } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            local target = context.blueprint_card or card
            local effect = kcvp_composition_effect(target, card.ability.extra.mult, card.ability.extra.chips)
            if effect.chips > 0 and effect.mult > 0 then
                return { chips = effect.chips, extra = { mult = effect.mult } }
            elseif effect.chips > 0 then
                return { chips = effect.chips }
            elseif effect.mult > 0 then
                return { mult = effect.mult }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Royal Guard: if the played hand has no Kings or Queens, +10 Chips for each
-- King or Queen in the full deck
--------------------------------------------------------------------------------

local function kcvp_kq_tally()
    if G and G.deck and G.count_cards_in_full_deck then
        local ok, n = pcall(function()
            return G:count_cards_in_full_deck(function(c)
                return c:get_id() == 12 or c:get_id() == 13
            end)
        end)
        if ok and type(n) == "number" then return n end
    end
    return 8 -- a fresh deck, and the PC mod's out-of-run fallback
end

SMODS.Joker {
    key = "guard",
    loc_txt = {
        name = "Royal Guard",
        text = {
            "If played hand has ",
            "no {C:attention}Kings{} and {C:attention}Queens{},",
            "{C:chips}+#1#{} Chips for each",
            "{C:attention}King{} or {C:attention}Queen{} in",
            "your {C:attention}full deck{}",
            "{C:inactive}(Currently {C:chips}+#2#{C:inactive} Chips)",
        },
    },
    config = { increment = 10 },
    rarity = 1,
    cost = 5,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = false,
    perishable_compat = true,
    sprite = "guard.png",
    negative_sprite = "guard_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.increment, kcvp_kq_tally() * card.ability.increment } }
    end,
    calculate = function(self, card, context)
        if context.joker_main and context.full_hand then
            for _, other in ipairs(context.full_hand) do
                if other:get_id() == 12 or other:get_id() == 13 then return end
            end
            local chips = kcvp_kq_tally() * card.ability.increment
            if chips > 0 then return { chips = chips } end
        end
    end,
}

--------------------------------------------------------------------------------
-- Joker-chan: at end of round, gains +2 Mult for each Common Joker held
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "chan",
    loc_txt = {
        name = "Joker-chan",
        text = {
            "At end of round, this",
            "gains {C:mult}+#1#{} Mult for",
            "each {C:blue}Common{} Joker",
            "{C:inactive}(Currently {C:mult}+#2#{C:inactive} Mult){}",
        },
    },
    config = { mult = 0, extra = 2 },
    rarity = 2,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    sprite = "chan.png",
    negative_sprite = "chan_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra, card.ability.mult } }
    end,
    calculate = function(self, card, context)
        if context.end_of_round and not context.blueprint then
            local amt = kcvp_common_count() * card.ability.extra
            if amt > 0 then
                card.ability.mult = card.ability.mult + amt
                return { message = "+" .. amt .. " Mult" }
            end
        end
        if context.joker_main and card.ability.mult > 0 then
            return { mult = card.ability.mult }
        end
    end,
}

--------------------------------------------------------------------------------
-- Red Envelope: earn $8 for each Common Joker when the Boss Blind is defeated
-- (paid in the end-of-round cash-out, exactly as on PC)
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "redenvelope",
    loc_txt = {
        name = "Red Envelope",
        text = {
            "When Boss Blind is",
            "defeated, earn {C:money}$8{} for",
            "each {C:blue}Common{} Joker",
            "{C:inactive}(Currently {C:money}$#1#{C:inactive})",
        },
    },
    config = {},
    rarity = 2,
    cost = 5,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "redenvelope.png",
    negative_sprite = "redenvelope_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { 8 * kcvp_common_count() } }
    end,
    calc_dollar_bonus = function(self, card)
        -- Balatro3DS tracks the blind by index within the ante: 1 Small, 2 Big, 3 Boss.
        if G and tonumber(G.current_blind_index) == 3 then
            local n = kcvp_common_count()
            if n > 0 then return 8 * n end
        end
    end,
}

--------------------------------------------------------------------------------
-- Jimbot: gains the Chip value of the first scoring numbered card each round
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "robo",
    loc_txt = {
        name = "Jimbot",
        text = {
            "This gains the {C:chips}Chip{} value",
            "of the first scoring",
            "{C:attention}numbered{} card each round",
            "{C:inactive}(Currently {C:chips}+#1#{C:inactive} Chips)",
        },
    },
    config = { chips = 0, extra = 0 },
    rarity = 2,
    cost = 5,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    sprite = "robo.png",
    negative_sprite = "robo_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.chips } }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play and not context.blueprint then
            if card.ability.extra == 0 then
                local other = context.other_card
                local id = other:get_id()
                if not other.debuff and id >= 2 and id <= 10 and other.enhancement ~= "stone" then
                    -- PC reads get_chip_bonus(): base value (+30 on a Bonus card).
                    local val = (other.base and tonumber(other.base.nominal)) or id
                    if other.enhancement == "bonus" then val = val + 30 end
                    card.ability.extra = val
                    card.ability.chips = card.ability.chips + val
                    return { message = "Upgrade!" }
                end
            end
        end
        if context.end_of_round and not context.blueprint then
            card.ability.extra = 0
        end
        if context.joker_main and card.ability.chips > 0 then
            return { chips = card.ability.chips }
        end
    end,
}

--------------------------------------------------------------------------------
-- Ten-Pin: a scoring 10 arms X2 Mult for the next 2 hands. PC Balatro applies
-- ability.x_mult itself; here joker_main returns it while armed.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "tenpin",
    loc_txt = {
        name = "Ten-Pin",
        text = {
            "If played hand contains a",
            "scoring {C:attention}10{}, {X:mult,C:white} X2 {} Mult",
            "for next 2 hands",
            "{C:inactive}(#1#){}",
        },
    },
    config = { x_mult = 1, hands_remaining = 0 },
    rarity = 2,
    cost = 5,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "tenpin.png",
    negative_sprite = "tenpin_negative.png",
    loc_vars = function(self, info_queue, card)
        local txt = "Inactive"
        if card.ability.hands_remaining > 0 then
            txt = "Active for " .. card.ability.hands_remaining .. " more hands"
        end
        return { vars = { txt } }
    end,
    calculate = function(self, card, context)
        if context.joker_main and card.ability.x_mult > 1 then
            return { xmult = card.ability.x_mult }
        end
        if context.after and context.scoring_hand and not context.blueprint then
            local has_10 = false
            for _, other in ipairs(context.scoring_hand) do
                -- The port's `after` hand includes played cards that did not
                -- score; PC's scoring_hand does not. Skip those.
                if other:get_id() == 10 and not other.debuff and other.counts_for_play_score ~= false then
                    has_10 = true
                    break
                end
            end
            if has_10 then
                card.ability.hands_remaining = 2
                card.ability.x_mult = 2
                return { message = "Active!" }
            else
                card.ability.hands_remaining = card.ability.hands_remaining - 1
                if card.ability.hands_remaining <= 0 and card.ability.x_mult == 2 then
                    card.ability.hands_remaining = 0
                    card.ability.x_mult = 1
                    return { message = "Reset" }
                end
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Handy Joker: gains X1 Mult whenever a single enhanced card is discarded,
-- resets when the Boss Blind is defeated. (KCVanilla's description says
-- "first discard of round", but the PC code triggers on every such discard;
-- this ports the code.) PC applies ability.x_mult itself; here joker_main
-- returns it.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "handy",
    loc_txt = {
        name = "Handy Joker",
        text = {
            "If {C:attention}first discard{} of round",
            "is a single enhanced card,",
            "this gains {X:mult,C:white} X1 {} Mult, resets",
            "when Boss Blind is defeated",
            "{C:inactive}(Currently {X:mult,C:white} X#1# {C:inactive} Mult)",
        },
    },
    config = { x_mult = 1 },
    rarity = 2,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "handy.png",
    negative_sprite = "handy_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.x_mult } }
    end,
    calculate = function(self, card, context)
        if context.discard and not context.blueprint then
            -- The port announces a discard per card, and (as of v2.0.5) does
            -- not fill context.full_hand for discard contexts: the batch is
            -- only in the raw event. A one-card batch is the PC mod's
            -- single-card discard.
            local batch_size = context.full_hand and #context.full_hand or 0
            if batch_size == 0 and context.port and context.port.discarded_nodes then
                batch_size = #context.port.discarded_nodes
            end
            if batch_size == 1 then
                local other = context.other_card
                if other and other.enhancement ~= nil then
                    card.ability.x_mult = card.ability.x_mult + 1
                    return { message = "X" .. card.ability.x_mult .. " Mult" }
                end
            end
        end
        if context.end_of_round and not context.blueprint and card.ability.x_mult ~= 1 then
            if G and tonumber(G.current_blind_index) == 3 then
                card.ability.x_mult = 1
                return { message = "Reset" }
            end
        end
        if context.joker_main and card.ability.x_mult > 1 then
            return { xmult = card.ability.x_mult }
        end
    end,
}

--------------------------------------------------------------------------------
-- Joker Energy: played Wild cards give a random one of +10 Mult, +100 Chips,
-- X2 Mult, $5 when scored
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "energy",
    loc_txt = {
        name = "Joker Energy",
        text = {
            "Played {C:attention}Wild{} cards give one",
            "of the following when scored:",
            "{C:mult}+#1#{} Mult, {C:chips}+#2#{} Chips, {X:mult,C:white} X#3# {} Mult, {C:money}$#4#{}",
        },
    },
    config = { kcv = { chips = 100, mult = 10, Xmult = 2, money = 5 } },
    rarity = 2,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "energy.png",
    negative_sprite = "energy_negative.png",
    loc_vars = function(self, info_queue, card)
        return {
            vars = { card.ability.kcv.mult, card.ability.kcv.chips, card.ability.kcv.Xmult, card.ability.kcv.money },
        }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            local other = context.other_card
            if other.enhancement == "wild" and not other.debuff then
                local roll = SMODS.pseudorandom_element({ "amult", "chips", "xmult", "money" }, "kcvp_energy")
                if roll == "amult" then
                    return { mult = card.ability.kcv.mult }
                elseif roll == "chips" then
                    return { chips = card.ability.kcv.chips }
                elseif roll == "xmult" then
                    return { xmult = card.ability.kcv.Xmult }
                elseif roll == "money" then
                    return { dollars = card.ability.kcv.money }
                end
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Power Grid: scored Mult cards give X Mult that grows by 0.1 for each Mult
-- card scored this round. PC counts with a Lovely patch on the scoring
-- function; here the Joker counts the Mult cards it sees, including itself
-- (the patch increments before the Joker's own effect, as here).
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "powergrid",
    loc_txt = {
        name = "Power Grid",
        text = {
            "Scored {C:attention}Mult{} cards",
            "give {X:mult,C:white} X#1# {} Mult",
            "for each {C:attention}Mult{} card",
            "scored this round",
            "{C:inactive}(Next: {X:mult,C:white} X#2# {C:inactive} Mult)",
        },
    },
    config = { extra = 0.1, kcv_count = 0 },
    rarity = 2,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "powergrid.png",
    negative_sprite = "powergrid_negative.png",
    loc_vars = function(self, info_queue, card)
        local count = card.ability.kcv_count or 0
        return { vars = { card.ability.extra, 1 + card.ability.extra + count * card.ability.extra } }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            local other = context.other_card
            if other.enhancement == "mult" and not other.debuff then
                local target = context.blueprint_card or card
                if not context.blueprint then
                    target.ability.kcv_count = (target.ability.kcv_count or 0) + 1
                end
                local count = target.ability.kcv_count or 0
                return { xmult = 1 + count * card.ability.extra }
            end
        end
        if (context.end_of_round or context.setting_blind) and not context.blueprint then
            card.ability.kcv_count = 0
        end
    end,
}

--------------------------------------------------------------------------------
-- v1.1.0: the five Jokers that create or destroy cards. These need the
-- Balatro3DS fork's Tier 1 mod API (SMODS.add_card / destroy_joker /
-- destroy_card); on the stock game they register but their effects no-op
-- because those functions do not exist there.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Fortune Cookie: +150 Chips, -50 Chips whenever a Tarot is used; when the
-- value would run out, the cookie is eaten (it destroys itself). PC pays its
-- chips with a status message; here joker_main returns them like every other
-- flat-Chips Joker in this pack. PC decays through SMODS's using_consumeable
-- context; the port carries the used consumable's kind on the raw event
-- (context.port.consumable_kind).
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "fortunecookie",
    loc_txt = {
        name = "Fortune Cookie",
        text = {
            "{C:chips}+#1#{} Chips,",
            "{C:chips}-#2#{} Chips when",
            "{C:tarot}Tarot{} card is used",
        },
    },
    config = { extra = { chips = 150, chip_mod = 50 } },
    rarity = 1,
    cost = 5,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = false,
    perishable_compat = true,
    sprite = "fortunecookie.png",
    negative_sprite = "fortunecookie_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chips, card.ability.extra.chip_mod } }
    end,
    calculate = function(self, card, context)
        if context.using_consumeable and not context.blueprint then
            local kind = context.port and context.port.consumable_kind
            if kind == nil and context.consumeable then
                kind = context.consumeable.kind
            end
            if kind == "tarot" then
                local new_val = card.ability.extra.chips - card.ability.extra.chip_mod
                if new_val > 0 then
                    card.ability.extra.chips = new_val
                    return { message = "-" .. card.ability.extra.chip_mod .. " Chips" }
                end
                -- PC removes it through a delayed event; the fork destroys
                -- it on the spot, which is what destroy_joker is for.
                SMODS.destroy_joker(card)
                return { message = "Eaten!" }
            end
        end
        if context.joker_main then
            return { chips = card.ability.extra.chips }
        end
    end,
}

--------------------------------------------------------------------------------
-- Rats!: when the round begins, destroy a random card in hand and duplicate
-- this Joker (must have room; the copy loses Negative, as on PC, so a
-- Negative Rats cannot fill the board for free). PC checks #G.hand.cards > 1
-- before destroying; the hand's nodes are the port's equivalent. The PC
-- can_spawn flag is set and reset exactly as on PC even though the PC code
-- never reads it; it is kept so saved ability state matches.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "rats",
    loc_txt = {
        name = "Rats!",
        text = {
            "When round begins, destroy",
            "a random card in hand",
            "and {C:attention}duplicate{} this Joker",
            "{C:inactive}(Must have room,",
            "{C:inactive}removes {C:dark_edition}Negative{C:inactive} from copy)",
        },
    },
    config = { can_spawn = true },
    rarity = 2,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "rats.png",
    negative_sprite = "rats_negative.png",
    calculate = function(self, card, context)
        if context.first_hand_drawn and not context.blueprint then
            card.ability.can_spawn = false
            local nodes = G and G.hand and G.hand.card_nodes
            if nodes and #nodes > 1 then
                local victim = SMODS.pseudorandom_element(nodes, "kcvp_rats")
                if victim then
                    SMODS.destroy_card(victim)
                    local params = { set = "Joker", key = "j_kcvp_rats" }
                    local edition = card.edition
                    if Joker and Joker.normalize_edition then
                        edition = Joker.normalize_edition(edition)
                    end
                    if type(edition) == "string" and edition ~= ""
                        and edition ~= "base" and edition ~= "negative" then
                        params.edition = edition
                    end
                    SMODS.add_card(params) -- nil, and no copy, when there is no room
                    return { message = "Rats!" }
                end
            end
        end
        if context.end_of_round and not context.blueprint then
            card.ability.can_spawn = true
        end
    end,
}

--------------------------------------------------------------------------------
-- Cosmic Collapse: at end of round, each held Planet has a 1 in 2 chance to
-- transform into a Black Hole. The port has no set_ability for consumables,
-- so a transform is the game's own removal (remove_consumable_at, the slot
-- the planet held frees first) followed by creating the Black Hole
-- (spectral_black_hole) through SMODS.add_card. The kcv_collapse mark is
-- PC's, kept so two Collapses resolving in the same pass never transform
-- the same Planet twice.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "collapse",
    loc_txt = {
        name = "Cosmic Collapse",
        text = {
            "At end of round, held {C:planet}Planet{}",
            "cards each have {C:green}#1# in #2#{} chance",
            "to transform into a {C:spectral}Black Hole{}",
        },
    },
    config = { numerator = 1, denominator = 2 },
    rarity = 3,
    cost = 7,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "collapse.png",
    negative_sprite = "collapse_negative.png",
    loc_vars = function(self, info_queue, card)
        local numerator, denominator = SMODS.get_probability_vars(card,
            card.ability.numerator, card.ability.denominator, "cosmiccollapse")
        return { vars = { numerator, denominator } }
    end,
    calculate = function(self, card, context)
        if context.end_of_round then
            local successes = {}
            for _, c in ipairs((G and G.consumables) or {}) do
                if c.kind == "planet" and not c.kcv_collapse then
                    local hit = SMODS.pseudorandom_probability(card, "cosmiccollapse",
                        card.ability.numerator, card.ability.denominator, "cosmiccollapse")
                    if hit then
                        c.kcv_collapse = true
                        successes[#successes + 1] = c
                    end
                end
            end
            if #successes == 0 then return end
            for _, planet in ipairs(successes) do
                for i, c in ipairs(G.consumables) do
                    if c == planet then
                        G:remove_consumable_at(i)
                        break
                    end
                end
                SMODS.add_card { set = "Spectral", key = "spectral_black_hole" }
                planet.kcv_collapse = nil
            end
            return { message = "Collapse!" }
        end
    end,
}

--------------------------------------------------------------------------------
-- Loose Tooth: if the played hand has a non-scoring Ace (an Ace that did not
-- score, or a debuffed Ace), create a random Tarot (must have room). PC
-- creates with SMODS.add_card { set = "Tarot" } and lets Steamodded pick;
-- the port's add_card needs a def id, so the game's own random-Tarot picker
-- (the one The Fool's family uses) picks it. The port's `before` context
-- marks scoring cards with counts_for_play_score, which stands in for PC's
-- scoring_hand membership test.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "loosetooth",
    loc_txt = {
        name = "Loose Tooth",
        text = {
            "Create a {C:tarot}Tarot{} card if",
            "played hand has a",
            "{C:attention}non-scoring Ace{}",
            "{C:inactive}(Must have room){}",
        },
    },
    config = {},
    rarity = 1,
    cost = 5,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "loosetooth.png",
    negative_sprite = "loosetooth_negative.png",
    calculate = function(self, card, context)
        if context.before and context.full_hand then
            local has_nonscoring_ace = false
            for _, other in ipairs(context.full_hand) do
                if other:get_id() == 14 and (other.debuff or other.counts_for_play_score ~= true) then
                    has_nonscoring_ace = true
                    break
                end
            end
            if has_nonscoring_ace and G and G.consumables
                and G.get_effective_consumable_capacity
                and #G.consumables < G:get_effective_consumable_capacity() then
                local id = G.random_consumable_id_of_kind
                    and G:random_consumable_id_of_kind("tarot", {}, "kcvp_loosetooth")
                if id and SMODS.add_card { set = "Tarot", key = id } then
                    return { message = "+1 Tarot" }
                end
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Scapegoat: if the first discard of the round is a single non-debuffed
-- card, destroy it and add its Chip value to a random other card held in
-- hand (a debuffed recipient keeps nothing; the discarded card is still
-- destroyed). Two port adaptations:
-- * "First discard" is tracked on the Joker itself (reset when the round
--   begins): the port decrements its discard counter before the discard
--   events fire, so there is no discards-used value left to read the way
--   PC reads G.GAME.current_round.discards_used.
-- * The chip value is PC's get_chip_bonus rebuilt from card_data: base
--   value (Ace 11, faces 10), +50 for Stone instead of its rank, +30 for a
--   Bonus card, plus any permanent Bonus/chip_bonus already on the card.
--   The grant writes card_data.Bonus, the same field Hiker writes.
-- The discarded card's data is pushed to the discard pile before the
-- discard events fire, as a copy; that copy is removed from the pile here
-- so a destroyed card truly leaves the game instead of haunting the deck.
--------------------------------------------------------------------------------

local function kcvp_chip_value(view)
    local data = (view and view.card_data) or {}
    local val
    if data.enhancement == "stone" then
        val = 50
    else
        local id = view and view.get_id and view:get_id() or tonumber(data.rank) or 0
        if id == 14 then val = 11
        elseif id >= 11 and id <= 13 then val = 10
        else val = id end
    end
    val = val + (tonumber(data.Bonus) or tonumber(data.bonus) or 0)
    val = val + (tonumber(data.chip_bonus) or tonumber(data.chips_bonus) or 0)
    if data.enhancement == "bonus" then val = val + 30 end
    return val
end

SMODS.Joker {
    key = "scapegoat",
    loc_txt = {
        name = "Scapegoat",
        text = {
            "If {C:attention}first discard{} of round",
            "has only {C:attention}1{} card, destroy",
            "it and add its {C:chips}Chip{} value",
            "to a random card in hand",
        },
    },
    config = {},
    rarity = 2,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "scapegoat.png",
    negative_sprite = "scapegoat_negative.png",
    calculate = function(self, card, context)
        if context.first_hand_drawn and not context.blueprint then
            card.ability.kcvp_discarded = false
        end
        if context.discard and not context.blueprint then
            local is_first = not card.ability.kcvp_discarded
            card.ability.kcvp_discarded = true
            if not is_first then return end
            local batch = context.port and context.port.discarded_nodes
            if not (batch and #batch == 1) then return end
            local other = context.other_card
            if not (other and not other.debuff) then return end
            local held = {}
            for _, node in ipairs((G and G.hand and G.hand.card_nodes) or {}) do
                if node ~= other then held[#held + 1] = node end
            end
            if #held == 0 then return end
            local target = SMODS.pseudorandom_element(held, "kcvp_scapegoat")
            if not target then return end
            local value = kcvp_chip_value(other)
            local data = other.card_data
            if data and G and G.deck and G.deck.discard_pile then
                for i, c in ipairs(G.deck.discard_pile) do
                    if c == data or (data.uid ~= nil and c.uid == data.uid) then
                        table.remove(G.deck.discard_pile, i)
                        break
                    end
                end
            end
            SMODS.destroy_card(other)
            -- Raw hand nodes carry no .debuff (contexts synthesize it);
            -- the game's own predicate is debuffed / debuffed_for_scoring.
            if target.debuff or target.debuffed or target.debuffed_for_scoring then
                return { message = "Debuffed!" }
            end
            local cd = target.card_data
            cd.Bonus = (tonumber(cd.Bonus) or tonumber(cd.bonus) or 0) + value
            return { message = "Upgrade!" }
        end
    end,
}
