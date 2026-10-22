--[[
    NeatoPack - Neato Jokers ported to Balatro3DS.

    Fifteen Jokers ported from Neato Jokers by neatoqueen (PC / Steamodded):
    Unpaid Intern, Tabby Cat, Wild Card Charlie, Lock-In Joker,
    Spare Cutoffs, Ice Cream Sandwich, Australian Shepherd, The Banana
    Stand, Blue Yourself, Dayman, Nightman, Dogs Playing Balatro,
    Frosted Prime Rib, Hatsune Joku, JokerZD.

    The last nine (v1.1.0) create and destroy cards and use retrigger
    returns, which the stock game's mod API cannot do: they need the
    Balatro3DS fork's Tier 1 mod API (SMODS.add_card / SMODS.destroy_joker /
    SMODS.destroy_card, retrigger fields in calculate returns):
      https://github.com/sen2008/balatro3ds-fork
    On the stock Universal-Updater build the pack still loads and the
    original six Jokers work, but the nine new ones have no effects.
    Ice Cream Sandwich also only melts (and is eaten) as on PC with the
    fork; on the stock game it floors at X1 instead.

    Port notes:
      * Wild Card Charlie's pool gate (needs a Wild Card in the deck) is
        dropped: the port has no enhancement pool query for Jokers.
      * Lock-In Joker resets when any Joker is sold; the port announces
        Joker and consumable sales through the same event, so the port
        checks the raw event for the sold Joker (context.port.joker).
      * Dayman and Nightman destroy played cards in the port's after pass
        (context.after), the same slot the port's own Sixth Sense uses for
        Steamodded's destroying_card context, which Balatro3DS never
        raises. The card still scores first, as on PC.
      * JokerZD counts unique Jokers bought by def id (context.port
        .offer_id on the shop-buy event); PC counts by card label.
      * Blue Yourself cannot see Steamodded's context.other_ret, so the
        sub-guard against retriggering a foil Blueprint that is itself
        copying Blue Yourself is dropped.
      * Hatsune Joku's custom music track (SMODS.Sound) has no port
        equivalent; only the Joker effect is ported.
      * Australian Shepherd's getting_sliced check is dropped: port
        Jokers do not carry that flag.
      * Descriptions are the mod's en-us text, verbatim.
]]

--------------------------------------------------------------------------------
-- Unpaid Intern: scored 9s and 5s give +40 Chips.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "unpaid_intern",
    loc_txt = {
        name = "Unpaid Intern",
        text = {
            "Every {C:attention}9{} and {C:attention}5{}",
            "gives {C:chips}+#1#{} Chips when scored",
        },
    },
    config = { extra = { chips = 40 } },
    rarity = 1,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "unpaid_intern.png",
    negative_sprite = "unpaid_intern_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chips } }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            local id = context.other_card:get_id()
            if id == 9 or id == 5 then
                return { chips = card.ability.extra.chips }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Tabby Cat: gains +2 Mult every 9 cards discarded. The discard context
-- arrives per card in Balatro3DS, exactly as the PC mod expects.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "tabby_cat",
    loc_txt = {
        name = "Tabby Cat",
        text = {
            "This Joker gains {C:mult}+#1#{} Mult",
            "every {C:attention}#2#{} {C:inactive}[#3#]{} cards discarded",
            "{C:inactive}(Currently {C:mult}+#4#{C:inactive} Mult)",
        },
    },
    config = { extra = { mult = 0, mult_gain = 2, discards = 9, discards_remaining = 9 } },
    rarity = 1,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    sprite = "tabby_cat.png",
    negative_sprite = "tabby_cat_negative.png",
    loc_vars = function(self, info_queue, card)
        local extra = card.ability.extra
        return { vars = { extra.mult_gain, extra.discards, extra.discards_remaining, extra.mult } }
    end,
    calculate = function(self, card, context)
        local extra = card.ability.extra
        if context.joker_main and extra.mult > 0 then
            return { mult = extra.mult }
        end
        if context.discard and not context.blueprint then
            if extra.discards_remaining <= 1 then
                extra.discards_remaining = extra.discards
                extra.mult = extra.mult + extra.mult_gain
                return { message = "Upgrade!" }
            else
                extra.discards_remaining = extra.discards_remaining - 1
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Wild Card Charlie: Wild Cards give X1.5 Mult when scored or held in hand.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "wild_card_charlie",
    loc_txt = {
        name = "Wild Card Charlie",
        text = {
            "{C:attention}Wild Cards{} give {X:mult,C:white}X#1#{} Mult when",
            "scored or when held in hand",
        },
    },
    config = { extra = { x_mult = 1.5 } },
    rarity = 2,
    cost = 7,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "wild_card_charlie.png",
    negative_sprite = "wild_card_charlie_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.x_mult } }
    end,
    calculate = function(self, card, context)
        if context.individual and not context.end_of_round then
            if context.cardarea == G.play or context.cardarea == G.hand then
                if context.other_card.enhancement == "wild" then
                    return { xmult = card.ability.extra.x_mult }
                end
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Lock-In Joker: gains +3 Mult when a Blind is selected; resets when a
-- Joker is sold.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "lock_in",
    loc_txt = {
        name = "Lock-In Joker",
        text = {
            "This Joker gains {C:mult}+#1#{} Mult",
            "when {C:attention}Blind{} is selected,",
            "resets when a Joker is {C:attention}sold{}",
            "{C:inactive}(Currently {C:mult}+#2#{C:inactive} Mult)",
        },
    },
    config = { extra = { mult_gain = 3, mult = 0 } },
    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    sprite = "lock_in.png",
    negative_sprite = "lock_in_negative.png",
    loc_vars = function(self, info_queue, card)
        local extra = card.ability.extra
        return { vars = { extra.mult_gain, extra.mult } }
    end,
    calculate = function(self, card, context)
        local extra = card.ability.extra
        if context.joker_main and extra.mult > 0 then
            return { mult = extra.mult }
        end
        if context.setting_blind and not context.blueprint then
            extra.mult = extra.mult + extra.mult_gain
            return { message = "Lock in!" }
        end
        if context.selling_card and not context.blueprint then
            -- The port fires this event for consumable sales too; only a
            -- sold Joker (raw event's joker field) resets Lock-In.
            if context.port and context.port.joker ~= nil then
                extra.mult = 0
                return { message = "Caught!" }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Spare Cutoffs: gains +12 Chips whenever a played hand contains a
-- Two Pair (a Full House counts, as the contained type is present).
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "spare_cutoffs",
    loc_txt = {
        name = "Spare Cutoffs",
        text = {
            "This Joker gains {C:chips}+#1#{} Chips",
            "if played hand contains",
            "a {C:attention}Two Pair{}",
            "{C:inactive}(Currently {C:chips}+#2#{C:inactive} Chips)",
        },
    },
    config = { extra = { chip_mod = 12, chips = 0 } },
    rarity = 2,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    sprite = "spare_cutoffs.png",
    negative_sprite = "spare_cutoffs_negative.png",
    loc_vars = function(self, info_queue, card)
        local extra = card.ability.extra
        return { vars = { extra.chip_mod, extra.chips } }
    end,
    calculate = function(self, card, context)
        local extra = card.ability.extra
        if context.before and not context.blueprint then
            if context.poker_hands and next(context.poker_hands["Two Pair"]) then
                extra.chips = extra.chips + extra.chip_mod
                return { message = "Upgrade!" }
            end
        end
        if context.joker_main and extra.chips > 0 then
            return { chips = extra.chips }
        end
    end,
}

--------------------------------------------------------------------------------
-- Ice Cream Sandwich: X5 Mult, loses X1 Mult per round played. On PC it is
-- destroyed when the X Mult would run out; the fork's SMODS.destroy_joker
-- does the same here. On the stock game destroy_joker does not exist, the
-- destroy call is a no-op and it floors at X1 instead.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "ice_cream_sandwich",
    loc_txt = {
        name = "Ice Cream Sandwich",
        text = {
            "{X:mult,C:white} X#1# {} Mult,",
            "loses {X:mult,C:white} X#2# {} Mult per",
            "round played",
        },
    },
    config = { extra = { xmult = 5, decrease = 1 } },
    rarity = 2,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = false,
    perishable_compat = true,
    sprite = "ice_cream_sandwich.png",
    negative_sprite = "ice_cream_sandwich_negative.png",
    loc_vars = function(self, info_queue, card)
        local extra = card.ability.extra
        return { vars = { extra.xmult, extra.decrease } }
    end,
    calculate = function(self, card, context)
        local extra = card.ability.extra
        if context.joker_main then
            return { xmult = extra.xmult }
        end
        if context.end_of_round and not context.blueprint and not context.game_over then
            if extra.xmult - extra.decrease <= 1 then
                if SMODS.destroy_joker and SMODS.destroy_joker(card) then
                    return { message = "Eaten!" }
                end
                extra.xmult = 1 -- stock game: no destroy, floor at X1
                return { message = "Eaten!" }
            end
            extra.xmult = extra.xmult - extra.decrease
            return { message = "X" .. extra.xmult .. " Mult" }
        end
    end,
}

--------------------------------------------------------------------------------
-- v1.1.0: the nine Jokers that create or destroy cards, or live on
-- retrigger returns. These need the Balatro3DS fork's Tier 1 mod API; on
-- the stock game they register but their effects no-op because
-- SMODS.add_card / destroy_joker / destroy_card do not exist there.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Australian Shepherd: create a random Planet when a Blind is selected.
-- PC creates with SMODS.create_card{set = "Planet"} and lets Steamodded
-- pick; the port's add_card needs a def id, so the game's own random-Planet
-- picker (the pool The Hanged Man's family uses) picks, as in the
-- KCVanillaPack ports. add_card returns nil when there is no room.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "australianshepherd",
    loc_txt = {
        name = "Australian Shepherd",
        text = {
            "Create a random {C:planet}Planet{} card",
            "when {C:attention}Blind{} is selected",
            "{C:inactive}(Must have room){}",
        },
    },
    config = { extra = {} },
    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "australian_shepherd.png",
    negative_sprite = "australian_shepherd_negative.png",
    calculate = function(self, card, context)
        if context.setting_blind then
            local id = G.random_consumable_id_of_kind
                and G:random_consumable_id_of_kind("planet", {}, "neatp_shepherd")
            if id and SMODS.add_card { set = "Planet", key = id } then
                return { message = "Woof!" }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- The Banana Stand: 1 in 4 chance for a played hand to give $10; 1 in 25
-- chance at end of round to be destroyed and lose ALL money. PC destroys
-- through a delayed event and zeroes the money with ease_dollars(-dollars,
-- instant); the fork destroys on the spot with SMODS.destroy_joker and the
-- mod environment's ease_dollars zeroes G.money directly.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "bananastand",
    loc_txt = {
        name = "The Banana Stand",
        text = {
            "{C:green}#1# in #2#{} chance for played",
            "{C:attention}hand{} to give {C:money}$#5#{},",
            "{C:green}#3# in #4#{} chance this card",
            "is {C:red}destroyed{} at the end of round",
            "{C:inactive}Lose ALL money if destroyed{}",
        },
    },
    config = { extra = { earn_chance = 4, destroy_chance = 25, earn_amt = 10 } },
    rarity = 1,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = false,
    perishable_compat = true,
    sprite = "banana_stand.png",
    negative_sprite = "banana_stand_negative.png",
    loc_vars = function(self, info_queue, card)
        local extra = card.ability.extra
        local n1, d1 = SMODS.get_probability_vars(card, 1, extra.earn_chance, "stand")
        local n2, d2 = SMODS.get_probability_vars(card, 1, extra.destroy_chance, "stand")
        return { vars = { n1, d1, n2, d2, extra.earn_amt } }
    end,
    calculate = function(self, card, context)
        local extra = card.ability.extra
        if context.before then
            if SMODS.pseudorandom_probability(card, "stand", 1, extra.earn_chance) then
                return { dollars = extra.earn_amt }
            end
        elseif context.end_of_round and not context.blueprint and not context.game_over then
            if SMODS.pseudorandom_probability(card, "stand", 1, extra.destroy_chance) then
                ease_dollars(-(tonumber(G.money) or 0))
                if SMODS.destroy_joker then SMODS.destroy_joker(card) end
                return { message = "Extinct!" }
            end
            return { message = "Safe!" }
        end
    end,
}

--------------------------------------------------------------------------------
-- Blue Yourself: retrigger Foil Jokers and Foil playing cards once.
-- The joker half rides the port's retrigger_joker_check pass (the other
-- Joker rides on context.other_card, its def id and normalized edition
-- standing in for PC's config.center.key and edition.key); the card half
-- rides context.repetition, where a card's edition lives in
-- card_data.modifier.edition. PC's in_pool gate (a Foil must be owned) is
-- kept: the port supports in_pool, and the deck half reads the game's own
-- full-deck counter. PC's guard against a foil Blueprint copying Blue
-- Yourself reads context.other_ret, which the port does not provide, and
-- is dropped (see header).
--------------------------------------------------------------------------------

local function neatp_is_foil_joker(j)
    local e = j and j.edition
    if type(e) == "table" then e = e.key end
    e = tostring(e or "")
    return e == "foil" or e == "e_foil"
end

SMODS.Joker {
    key = "blueyourself",
    loc_txt = {
        name = "Blue Yourself",
        text = {
            "Retriggers {C:attention}Jokers{} and {C:attention}cards{}",
            "with the {C:dark_edition}Foil{} edition",
            "{C:inactive}(Excluding #1#){}",
        },
    },
    config = { extra = 1 },
    rarity = 3,
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "blue_yourself.png",
    negative_sprite = "blue_yourself_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { "Blue Yourself" } }
    end,
    in_pool = function(self, args)
        if not G then return false end
        for _, j in ipairs(G.jokers or {}) do
            if neatp_is_foil_joker(j) then return true end
        end
        if G.count_cards_in_full_deck then
            local n = G:count_cards_in_full_deck(function(data)
                return type(data) == "table" and data.modifier ~= nil
                    and data.modifier.edition == "foil"
            end)
            if (tonumber(n) or 0) > 0 then return true end
        end
        return false
    end,
    calculate = function(self, card, context)
        if context.retrigger_joker_check and context.other_card
            and context.other_card ~= card then
            local oc = context.other_card
            local oid = oc.def and oc.def.id
            if oid ~= "j_neatp_blueyourself" and neatp_is_foil_joker(oc) then
                return {
                    message = "Again!",
                    repetitions = card.ability.extra,
                }
            end
        elseif context.repetition and context.cardarea == G.play
            and context.other_card then
            local cd = context.other_card.card_data
            if cd and cd.modifier and cd.modifier.edition == "foil" then
                return {
                    message = "Again!",
                    repetitions = card.ability.extra,
                }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Dayman: if the first hand of the round is a single Queen, destroy it
-- and gain X0.5 Mult. PC uses context.destroying_card, which Balatro3DS
-- never raises; the port's own Sixth Sense runs the same trade in the
-- after pass (context.after), where the reference runs destroying_card
-- too, and checks the first hand with G:get_round_hands_played() == 1.
-- PC's first_hand_drawn juice is cosmetic and dropped.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "dayman",
    loc_txt = {
        name = "Dayman",
        text = {
            "If {C:attention}first hand{} of round is",
            "a single {C:attention}Queen{}, destroy it and",
            "gain {X:mult,C:white}X#1#{} Mult",
            "{C:inactive}(Currently {X:mult,C:white}X#2#{} {C:inactive}Mult){}",
        },
    },
    config = { extra = { x_mult = 1, scaling = 0.5 } },
    rarity = 2,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    sprite = "dayman.png",
    negative_sprite = "dayman_negative.png",
    loc_vars = function(self, info_queue, card)
        local extra = card.ability.extra
        return { vars = { extra.scaling, extra.x_mult } }
    end,
    calculate = function(self, card, context)
        local extra = card.ability.extra
        if context.joker_main and extra.x_mult > 1 then
            return { xmult = extra.x_mult }
        end
        if context.after and not context.blueprint then
            local played = G.get_round_hands_played and G:get_round_hands_played() or 0
            local hand = context.full_hand
            if played == 1 and hand and #hand == 1 and hand[1]:get_id() == 12 then
                if SMODS.destroy_card and SMODS.destroy_card(hand[1]) then
                    extra.x_mult = extra.x_mult + extra.scaling
                    return { message = "Upgrade!" }
                end
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Nightman: each hand played, destroy a random scoring card and gain
-- X0.1 Mult. PC picks the victim at before from context.scoring_hand and
-- destroys it in the destroying_card phase; the port does both in the
-- after pass (see Dayman), picking from the scoring subset of the played
-- cards (the counts_for_play_score marker the game's own Hiker reads;
-- if no card carries the marker, the whole played set is the pool).
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "nightman",
    loc_txt = {
        name = "Nightman",
        text = {
            "When a {C:attention}hand{} is played,",
            "{C:attention}destroy{} a random scoring card",
            "and gain {X:mult,C:white}X#1#{} Mult",
            "{C:inactive}(Currently {X:mult,C:white}X#2#{} {C:inactive}Mult){}",
        },
    },
    config = { extra = { x_mult = 1, scaling = 0.1 } },
    rarity = 2,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    sprite = "nightman.png",
    negative_sprite = "nightman_negative.png",
    loc_vars = function(self, info_queue, card)
        local extra = card.ability.extra
        return { vars = { extra.scaling, extra.x_mult } }
    end,
    calculate = function(self, card, context)
        local extra = card.ability.extra
        if context.joker_main and extra.x_mult > 1 then
            return { xmult = extra.x_mult }
        end
        if context.after and not context.blueprint then
            local pool = {}
            for _, view in ipairs(context.scoring_hand or {}) do
                if view.counts_for_play_score == true then pool[#pool + 1] = view end
            end
            if #pool == 0 then pool = context.scoring_hand or {} end
            if #pool > 0 and SMODS.destroy_card then
                local victim = pseudorandom_element(pool, "night")
                if victim and SMODS.destroy_card(victim) then
                    extra.x_mult = extra.x_mult + extra.scaling
                    return { message = "Gasp!" }
                end
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Dogs Playing Balatro: 1 in 4 chance to fetch a random Spectral when a
-- Planet is used. PC creates with SMODS.create_card{set = "Spectral"};
-- the port's add_card needs a def id, so the game's random picker for the
-- kind chooses (it never offers The Soul or a Black Hole, matching the
-- pool PC's create_card draws from). PC checks for room before rolling;
-- add_card returning nil covers a full consumable area after the roll.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "dogsplayingbalatro",
    loc_txt = {
        name = "Dogs Playing Balatro",
        text = {
            "{C:green}#1# in #2#{} chance to fetch",
            "a random {C:spectral}Spectral{} card",
            "when a {C:planet}Planet{} card is used",
            "{C:inactive}(Must have room){}",
        },
    },
    config = { extra = 4 },
    rarity = 3,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "dogs_playing_balatro.png",
    negative_sprite = "dogs_playing_balatro_negative.png",
    loc_vars = function(self, info_queue, card)
        local n, d = SMODS.get_probability_vars(card, 1, card.ability.extra, "dogs")
        return { vars = { n, d } }
    end,
    calculate = function(self, card, context)
        if context.using_consumeable then
            local kind = context.port and context.port.consumable_kind
            if kind == nil and context.consumeable then
                kind = context.consumeable.kind
            end
            if kind == "planet" then
                if SMODS.pseudorandom_probability(card, "dogs", 1, card.ability.extra) then
                    local id = G.random_consumable_id_of_kind
                        and G:random_consumable_id_of_kind("spectral", {}, "neatp_dogs")
                    if id and SMODS.add_card { set = "Spectral", key = id } then
                        return { message = "Woof!" }
                    end
                end
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Frosted Prime Rib: for the next 22 hands, every scored card permanently
-- gains +2 Chips and +1 Mult; then it is eaten. The permanent gains write
-- the port's own fields: card_data.Bonus (the field Hiker writes; the
-- scored card's get_chip_bonus reads it back) and card_data.mult_bonus
-- (read by the same modifier path). PC counts hands down in context.after;
-- the port's after pass is the same beat. Only scoring cards are granted,
-- via the counts_for_play_score marker, as the port's Hiker checks.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "frostedprimerib",
    loc_txt = {
        name = "Frosted Prime Rib",
        text = {
            "For the next {C:attention}#3#{} hands",
            "Every played {C:attention}card{} permanently gains",
            "{C:chips}+#1#{} Chips and {C:mult}+#2#{} Mult when scored",
        },
    },
    config = { extra = { hands = 22, chip_mod = 2, mult_mod = 1 } },
    rarity = 2,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = false,
    perishable_compat = true,
    sprite = "frosted_prime_rib.png",
    negative_sprite = "frosted_prime_rib_negative.png",
    loc_vars = function(self, info_queue, card)
        local extra = card.ability.extra
        return { vars = { extra.chip_mod, extra.mult_mod, extra.hands } }
    end,
    calculate = function(self, card, context)
        local extra = card.ability.extra
        if context.individual and context.cardarea == G.play then
            local other = context.other_card
            if other and other.counts_for_play_score == true and other.card_data then
                local cd = other.card_data
                local cur = tonumber(cd.Bonus) or tonumber(cd.bonus) or 0
                cd.Bonus = math.floor(cur) + extra.chip_mod
                cd.bonus = nil
                cd.mult_bonus = (tonumber(cd.mult_bonus) or 0) + extra.mult_mod
                return { message = "Upgrade!" }
            end
        elseif context.after and not context.blueprint then
            extra.hands = extra.hands - 1
            if extra.hands <= 0 then
                if SMODS.destroy_joker then SMODS.destroy_joker(card) end
                return { message = "Eaten!" }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Hatsune Joku: retrigger played 9s two additional times. This is the
-- port's context.repetition pass (query_retrigger), the same one the
-- PokermonPack retrigger Jokers use. The PC mod's custom music track and
-- its add_to_deck juice have no port equivalent and are not ported.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "hatsunejoku",
    loc_txt = {
        name = "Hatsune Joku",
        text = {
            "{C:attention}Retrigger{} played {C:attention}9s{}",
            "an additional {C:attention}two{} times",
        },
    },
    config = { extra = { repetitions = 2 } },
    rarity = 2,
    cost = 5,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "hatsune_joku.png",
    negative_sprite = "hatsune_joku_negative.png",
    calculate = function(self, card, context)
        if context.repetition and context.cardarea == G.play
            and context.other_card and context.other_card:get_id() == 9 then
            return {
                message = "Again!",
                repetitions = card.ability.extra.repetitions,
            }
        end
    end,
}

--------------------------------------------------------------------------------
-- JokerZD: gains X0.15 Mult for every unique Joker purchased. PC reads
-- context.buying_card with the bought card on context.card; the port's
-- shop-buy event carries the purchase on the raw event instead
-- (context.port.offer_kind / offer_id), and uniqueness is tracked by def
-- id where PC tracks the card's label (see header). Buying this Joker
-- itself does not count, as on PC.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "jokerzd",
    loc_txt = {
        name = "JokerZD",
        text = {
            "This Joker gains {X:mult,C:white}X#1#{} Mult for",
            "every unique joker {C:attention}purchased{}",
            "{C:inactive}(Currently {X:mult,C:white}X#2#{} {C:inactive}Mult){}",
        },
    },
    config = { extra = { scaling = 0.15, seen = {}, x_mult = 1 } },
    rarity = 3,
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    sprite = "jokerzd.png",
    negative_sprite = "jokerzd_negative.png",
    loc_vars = function(self, info_queue, card)
        local extra = card.ability.extra
        return { vars = { extra.scaling, extra.x_mult } }
    end,
    calculate = function(self, card, context)
        local extra = card.ability.extra
        if context.joker_main and extra.x_mult > 1 then
            return { xmult = extra.x_mult }
        end
        if context.buying_card and not context.blueprint then
            local p = context.port or {}
            if p.offer_kind == "joker" and type(p.offer_id) == "string" then
                local own = card.def and card.def.id
                if p.offer_id ~= own and not extra.seen[p.offer_id] then
                    extra.seen[p.offer_id] = true
                    extra.x_mult = extra.x_mult + extra.scaling
                    return { message = "Upgrade!" }
                end
            end
        end
    end,
}
