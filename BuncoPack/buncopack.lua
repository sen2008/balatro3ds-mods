--[[
    BuncoPack - Bunco content ported to Balatro3DS.

    Sixty-two of Bunco's eighty Jokers, both exotic suits, the four
    Spectrum-family poker hands plus Registration Plate's Deal, and six
    consumables (the four Spectrum Planets, The Sky, The Abyss), ported
    from Bunco by Firch (PC / Steamodded + Lovely). The v1.1.0 additions
    need the Balatro3DS fork's Tier 1 + Tier 2 mod APIs (create/destroy,
    retrigger returns, SMODS.Suit, SMODS.PokerHand) and the fork's
    suit-pool gate for random card fronts.

    Port notes (Balatro3DS API differences that shaped the code):
      * Exotic suits: PC keeps a per-run G.GAME.Exotic flag, set the first
        time a Spectrum-family hand is scored (or by an exotic enabler).
        The port has no hand-played hook a mod can set state from, so the
        pack derives the flag on demand: a Spectrum-family hand in
        G.hand_play_counts (which the game persists) with a count above
        zero means exotics are on. The suits' SMODS.Suit in_pool gate
        feeds that to the fork's random-front pool, which is how exotic
        cards enter Standard packs and the shop, exactly PC's routes.
      * Cassette is a single Joker whose side flips on discard; the 3DS
        API gives each Joker one sprite, so the art always shows the
        A side.
      * PC update()-driven values (Voxel, Hierarchy of Needs, Rigoletto)
        are computed inside joker_main / loc_vars from the deck.
      * Protester reads the pre_discard batch from the raw event
        (context.port.discarded_nodes); Nil Bill counts card removals in
        context.port.destroyed_cards.
      * Critic compares the scoring context's running totals
        (context.port.chips / context.port.mult) against
        G.current_blind_target, like PC's hand_chips * mult globals.
      * Disproportionality's fake-crash tooltip gag cannot be expressed in
        the port's tooltip markup; its description is plain text instead.
      * Bunco's temporary extra chips (Fingerprints, Bierdeckel) ride on
        card_data.Bonus, tracked per Joker by card uid and removed again
        at end of round, which reproduces their lifetimes.
      * Descriptions are Bunco's en-us text, verbatim where the markup
        allows.
]]

--------------------------------------------------------------------------------
-- Cassette: two-sided Joker. Light suits pay Chips on side A, dark suits
-- pay Mult on side B; the side flips every time you discard.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "cassette",
    loc_txt = {
        name = "Cassette",
        text = {
            "{C:attention}A Side:{} Cards with {C:attention}light suit{}",
            "give {C:chips}+#1#{} Chips when scored",
            "{C:attention}B Side:{} Cards with {C:attention}dark suit{}",
            "give {C:mult}+#2#{} Mult when scored",
            "{C:inactive}(Flips side when you discard)",
        },
    },
    config = { extra = { chips = 45, mult = 6, side = "A" } },
    rarity = 2,
    cost = 5,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "cassette.png",
    negative_sprite = "cassette_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chips, card.ability.extra.mult } }
    end,
    calculate = function(self, card, context)
        local extra = card.ability.extra
        if context.pre_discard and not context.blueprint then
            extra.side = (extra.side == "A") and "B" or "A"
            return { message = (extra.side == "A") and "A Side!" or "B Side!" }
        end
        if context.individual and context.cardarea == G.play then
            local other = context.other_card
            if other:is_suit("Hearts") or other:is_suit("Diamonds") or other:is_suit("Fleurons") then
                if extra.side == "A" then return { chips = extra.chips } end
            end
            if other:is_suit("Spades") or other:is_suit("Clubs") or other:is_suit("Halberds") then
                if extra.side == "B" then return { mult = extra.mult } end
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Mosaic: played Stone Cards give +6 Mult when scored.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "mosaic",
    loc_txt = {
        name = "Mosaic Joker",
        text = {
            "Played {C:attention}Stone Cards{}",
            "give {C:mult}+#1#{} Mult",
            "when scored",
        },
    },
    config = { extra = { mult = 6 } },
    rarity = 2,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "mosaic.png",
    negative_sprite = "mosaic_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult } }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            if context.other_card.enhancement == "stone" then
                return { mult = card.ability.extra.mult }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Voxel: X3 Mult, -X0.1 Mult for each Enhanced card in your full deck
-- (minimum X1). PC recomputes in update(); here joker_main tallies the deck.
--------------------------------------------------------------------------------

local function buncp_voxel_x(extra)
    local tally = 0
    if G and G.count_cards_in_full_deck then
        tally = G:count_cards_in_full_deck(function(c) return c.enhancement ~= nil end)
    end
    local x = extra.base - tally * extra.bonus
    if x < 1 then x = 1 end
    return x
end

SMODS.Joker {
    key = "voxel",
    loc_txt = {
        name = "Voxel Joker",
        text = {
            "{X:mult,C:white}X#1#{} Mult, {X:mult,C:white}-X#2#{} Mult for each",
            "{C:attention}Enhanced card{} in your {C:attention}full deck{}",
            "{C:inactive}(Currently {X:mult,C:white}X#3#{C:inactive} Mult)",
        },
    },
    config = { extra = { base = 3, bonus = 0.1 } },
    rarity = 2,
    cost = 5,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "voxel.png",
    negative_sprite = "voxel_negative.png",
    loc_vars = function(self, info_queue, card)
        local extra = card.ability.extra
        return { vars = { extra.base, extra.bonus, buncp_voxel_x(extra) } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            local x = buncp_voxel_x(card.ability.extra)
            if x ~= 1 then return { xmult = x } end
        end
    end,
}

--------------------------------------------------------------------------------
-- Crop Circles: scored cards give Mult by natural suit and rank. Fleurons
-- pay the most, then Clubs; Stone Cards pay nothing. PC checks the base
-- suit, so this reads card_data.suit, not is_suit (which would count Wild
-- Cards as Clubs).
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "crop_circles",
    loc_txt = {
        name = "Crop Circles",
        text = {
            "Base suit {C:clubs}Clubs{} give {C:mult}+3{} Mult,",
            "{C:attention}8s{} give {C:mult}+2{} Mult,",
            "{C:attention}Qs{}, {C:attention}10s{}, {C:attention}9s{}, {C:attention}6s{} give {C:mult}+1{} Mult",
        },
    },
    config = {},
    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "crop_circles.png",
    negative_sprite = "crop_circles_negative.png",
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            local other = context.other_card
            if other.enhancement == "stone" then return end
            local id = other:get_id()
            local bonus_rank = (id == 12 or id == 10 or id == 9 or id == 6)
            local mult = 0
            if other.card_data and other.card_data.suit == "Fleurons" then
                if id == 8 then mult = 6
                elseif bonus_rank then mult = 5
                else mult = 4 end
            elseif other.card_data and other.card_data.suit == "Clubs" then
                if id == 8 then mult = 5
                elseif bonus_rank then mult = 4
                else mult = 3 end
            elseif id == 8 then mult = 2
            elseif bonus_rank then mult = 1 end
            if mult ~= 0 then return { mult = mult } end
        end
    end,
}

--------------------------------------------------------------------------------
-- Prehistoric: a scored card that matches (rank and suit) a card already
-- scored this round gives +16 Mult. PC stores the card objects; the port
-- stores {rank, suit, wild} keys, cleared at end of round.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "prehistoric",
    loc_txt = {
        name = "Prehistoric Joker",
        text = {
            "Played cards that share",
            "both {C:attention}rank and suit{} with an",
            "{C:attention}already-scored card{} this round",
            "give {C:mult}+#1#{} Mult",
        },
    },
    config = { extra = { mult = 16, seen = {} } },
    rarity = 2,
    cost = 5,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "prehistoric.png",
    negative_sprite = "prehistoric_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult } }
    end,
    calculate = function(self, card, context)
        local extra = card.ability.extra
        if context.individual and context.cardarea == G.play then
            local other = context.other_card
            if other.enhancement ~= "stone" then
                local id = other:get_id()
                local suit = other.card_data and other.card_data.suit
                local wild = other.enhancement == "wild"
                for _, e in ipairs(extra.seen) do
                    if e.id == id and (e.suit == suit or e.wild or wild) then
                        return { mult = extra.mult }
                    end
                end
            end
            if not context.blueprint and other.enhancement ~= "stone" then
                extra.seen[#extra.seen + 1] = {
                    id = other:get_id(),
                    suit = other.card_data and other.card_data.suit,
                    wild = other.enhancement == "wild",
                }
            end
        end
        if context.end_of_round and not context.blueprint then
            extra.seen = {}
        end
    end,
}

--------------------------------------------------------------------------------
-- Shepherd: gains +6 Chips permanently whenever a played hand contains a
-- Pair. Jumper is the same shape for a Flush, at +8.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "shepherd",
    loc_txt = {
        name = "Shepherd Joker",
        text = {
            "Gains {C:chips}+#1#{} Chips",
            "when played hand",
            "contains a {C:attention}Pair{}",
            "{C:inactive}(Currently {C:chips}+#2#{C:inactive} Chips)",
        },
    },
    config = { extra = { bonus = 6, chips = 0 } },
    rarity = 1,
    cost = 5,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    sprite = "shepherd.png",
    negative_sprite = "shepherd_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.bonus, card.ability.extra.chips } }
    end,
    calculate = function(self, card, context)
        local extra = card.ability.extra
        if context.before and not context.blueprint then
            if context.poker_hands and next(context.poker_hands["Pair"]) then
                extra.chips = extra.chips + extra.bonus
                return { message = "+" .. extra.chips .. " Chips" }
            end
        end
        if context.joker_main and extra.chips ~= 0 then
            return { chips = extra.chips }
        end
    end,
}

SMODS.Joker {
    key = "jumper",
    loc_txt = {
        name = "Jumper",
        text = {
            "Gains {C:chips}+#1#{} Chips",
            "if played hand",
            "contains a {C:attention}Flush{}",
            "{C:inactive}(Currently {C:chips}+#2#{C:inactive} Chips)",
        },
    },
    config = { extra = { bonus = 8, chips = 0 } },
    rarity = 1,
    cost = 5,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    sprite = "jumper.png",
    negative_sprite = "jumper_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.bonus, card.ability.extra.chips } }
    end,
    calculate = function(self, card, context)
        local extra = card.ability.extra
        if context.before and not context.blueprint then
            if context.poker_hands and next(context.poker_hands["Flush"]) then
                extra.chips = extra.chips + extra.bonus
                return { message = "+" .. extra.chips .. " Chips" }
            end
        end
        if context.joker_main and extra.chips ~= 0 then
            return { chips = extra.chips }
        end
    end,
}

--------------------------------------------------------------------------------
-- Dogs Playing Poker: X2.5 Mult if every scoring card is a 2, 3, 4 or 5
-- (Stone Cards do not disqualify the hand, as on PC).
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "dogs_playing_poker",
    loc_txt = {
        name = "Dogs Playing Poker",
        text = {
            "{X:mult,C:white}X#1#{} Mult if every scored",
            "rank is {C:attention}2{}, {C:attention}3{}, {C:attention}4{}, or {C:attention}5{}",
        },
    },
    config = { extra = { xmult = 2.5 } },
    rarity = 2,
    cost = 5,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "dogs_playing_poker.png",
    negative_sprite = "dogs_playing_poker_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.xmult } }
    end,
    calculate = function(self, card, context)
        if context.joker_main and context.scoring_hand then
            for _, c in ipairs(context.scoring_hand) do
                if c.enhancement ~= "stone" then
                    local id = c:get_id()
                    if id < 2 or id > 5 then return end
                end
            end
            return { xmult = card.ability.extra.xmult }
        end
    end,
}

--------------------------------------------------------------------------------
-- Headshot: X3 Mult if exactly one face card scores.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "headshot",
    loc_txt = {
        name = "Headshot",
        text = {
            "{X:mult,C:white}X#1#{} Mult if played hand",
            "contains only a single",
            "scoring {C:attention}face card{}",
        },
    },
    config = { extra = { xmult = 3 } },
    rarity = 2,
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "headshot.png",
    negative_sprite = "headshot_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.xmult } }
    end,
    calculate = function(self, card, context)
        if context.joker_main and context.scoring_hand then
            local faces = 0
            for _, c in ipairs(context.scoring_hand) do
                if c:is_face() then faces = faces + 1 end
            end
            if faces == 1 then
                return { xmult = card.ability.extra.xmult }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Nil Bill: earn $2 for each playing card destroyed.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "nil_bill",
    loc_txt = {
        name = "Nil Bill",
        text = {
            "Earn {C:money}$#1#{}",
            "when a playing card",
            "is destroyed",
        },
    },
    config = { extra = { bonus = 2 } },
    rarity = 2,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "nil_bill.png",
    negative_sprite = "nil_bill_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.bonus } }
    end,
    calculate = function(self, card, context)
        if context.remove_playing_cards then
            local removed = (context.port and context.port.destroyed_cards) or {}
            local n = #removed
            if n > 0 then
                local dollars = card.ability.extra.bonus * n
                return { dollars = dollars, message = "$" .. dollars }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Slothful: played Wild Cards give +9 Mult when scored.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "slothful",
    loc_txt = {
        name = "Slothful Joker",
        text = {
            "Played {C:attention}Wild Cards{}",
            "give {C:mult}+#1#{} Mult",
            "when scored",
        },
    },
    config = { extra = { mult = 9 } },
    rarity = 2,
    cost = 5,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "slothful.png",
    negative_sprite = "slothful_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult } }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            if context.other_card.enhancement == "wild" then
                return { mult = card.ability.extra.mult }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Hierarchy of Needs: +5 Mult per complete 2-to-Ace sequence of the same
-- suit in your full deck (per suit, the count of the scarcest rank). PC
-- consumes ranks iteratively in update(); the port tallies in joker_main.
--------------------------------------------------------------------------------

local function buncp_hierarchy_mult(extra)
    if not (G and G.count_cards_in_full_deck) then return extra.bonus * 4 end
    local total = G:count_cards_in_full_deck(function() return true end)
    if total == 0 then return extra.bonus * 4 end
    local sets = 0
    for _, suit in ipairs({ "Spades", "Hearts", "Clubs", "Diamonds" }) do
        local scarcest = nil
        for id = 2, 14 do
            local n = G:count_cards_in_full_deck(function(c)
                return c.enhancement ~= "stone" and c.suit == suit and c.rank == id
            end)
            if scarcest == nil or n < scarcest then scarcest = n end
        end
        sets = sets + (scarcest or 0)
    end
    return extra.bonus * sets
end

SMODS.Joker {
    key = "hierarchy_of_needs",
    loc_txt = {
        name = "Hierarchy of Needs",
        text = {
            "{C:mult}+#1#{} Mult per {C:attention}2 to Ace{}",
            "sequence of the same suit",
            "in your {C:attention}full deck{}",
            "{C:inactive}(Currently {C:mult}+#2#{C:inactive} Mult)",
        },
    },
    config = { extra = { bonus = 5 } },
    rarity = 1,
    cost = 5,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "hierarchy_of_needs.png",
    negative_sprite = "hierarchy_of_needs_negative.png",
    loc_vars = function(self, info_queue, card)
        local extra = card.ability.extra
        return { vars = { extra.bonus, buncp_hierarchy_mult(extra) } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            local mult = buncp_hierarchy_mult(card.ability.extra)
            if mult ~= 0 then return { mult = mult } end
        end
    end,
}

--------------------------------------------------------------------------------
-- Protester: gains Chips equal to 8 x the highest rank discarded this
-- round; resets at end of round. PC reads the highlighted cards at
-- pre_discard; the port reads the raw event's discarded nodes, which also
-- skips Stone Cards cleanly (PC checks a buggy parallel index for that).
--------------------------------------------------------------------------------

local function buncp_nominal(id)
    if id == 14 then return 11 end
    if id >= 11 then return 10 end
    return id
end

SMODS.Joker {
    key = "protester",
    loc_txt = {
        name = "Protester",
        text = {
            "Adds {C:attention}#1#X{} the highest rank",
            "discarded this round to Chips",
            "{C:inactive}(Currently {C:chips}+#2#{C:inactive} Chips)",
        },
    },
    config = { extra = { chip_mult = 8, chips = 0, rank = 0 } },
    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "protester.png",
    negative_sprite = "protester_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chip_mult, card.ability.extra.chips } }
    end,
    calculate = function(self, card, context)
        local extra = card.ability.extra
        if context.pre_discard and not context.blueprint then
            local nodes = (context.port and context.port.discarded_nodes) or {}
            for _, node in ipairs(nodes) do
                if node.card_data and node.card_data.enhancement ~= "stone" then
                    local nominal = buncp_nominal(node:get_id())
                    if nominal > extra.rank then
                        extra.rank = nominal
                        extra.chips = nominal * extra.chip_mult
                    end
                end
            end
        end
        if context.joker_main and extra.chips ~= 0 then
            return { chips = extra.chips }
        end
        if context.end_of_round and not context.blueprint and extra.rank ~= 0 then
            extra.rank = 0
            extra.chips = 0
            return { message = "Reset!" }
        end
    end,
}

--------------------------------------------------------------------------------
-- Disproportionality: gives a random 0-200 Chips each hand. (PC presents
-- this behind a fake crash tooltip, which the port cannot reproduce.)
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "disproportionality",
    loc_txt = {
        name = "Disproportionality",
        text = {
            "Gives a random amount",
            "of {C:chips}Chips{} each hand",
            "{C:inactive}(Between {C:chips}0{} and {C:chips}200{}{C:inactive})",
        },
    },
    config = { extra = { min = 0, max = 200 } },
    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "disproportionality.png",
    negative_sprite = "disproportionality_negative.png",
    calculate = function(self, card, context)
        if context.joker_main then
            local extra = card.ability.extra
            local chips = SMODS.pseudorandom("buncp_disproportionality", extra.min, extra.max)
            if chips ~= 0 then return { chips = chips } end
        end
    end,
}

--------------------------------------------------------------------------------
-- On Broadway: +120 Chips and +20 Mult if the played hand contains a
-- Straight with a scoring face card. PC adds the Chips by mutating the
-- hand globals; the port returns both parts.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "on_broadway",
    loc_txt = {
        name = "On Broadway",
        text = {
            "{C:chips}+#1#{} Chips and {C:mult}+#2#{} Mult if",
            "played hand contains a {C:attention}Straight{}",
            "with a scoring {C:attention}face card{}",
        },
    },
    config = { extra = { chips = 120, mult = 20 } },
    rarity = 2,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "on_broadway.png",
    negative_sprite = "on_broadway_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chips, card.ability.extra.mult } }
    end,
    calculate = function(self, card, context)
        if context.joker_main and context.scoring_hand then
            if context.poker_hands and next(context.poker_hands["Straight"]) then
                for _, c in ipairs(context.scoring_hand) do
                    if c:is_face() then
                        return { chips = card.ability.extra.chips, mult = card.ability.extra.mult }
                    end
                end
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Rasta: +12 Mult if no Enhanced cards are scored.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "rasta",
    loc_txt = {
        name = "Rasta",
        text = {
            "{C:mult}+#1#{} Mult if no",
            "{C:attention}Enhanced cards{}",
            "are scored",
        },
    },
    config = { extra = { mult = 12 } },
    rarity = 1,
    cost = 5,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "rasta.png",
    negative_sprite = "rasta_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult } }
    end,
    calculate = function(self, card, context)
        if context.joker_main and context.scoring_hand then
            for _, c in ipairs(context.scoring_hand) do
                if c.enhancement ~= nil then return end
            end
            return { mult = card.ability.extra.mult }
        end
    end,
}

--------------------------------------------------------------------------------
-- Critic: X2 Mult while the hand's current score (running chips x mult at
-- the point this Joker is evaluated) is under 1/3 of the blind's target.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "critic",
    loc_txt = {
        name = "Critic",
        text = {
            "{X:mult,C:white}X#1#{} Mult if played hand's",
            "current score is",
            "{C:attention}less than 1/#2#{} of",
            "blind's required score",
        },
    },
    config = { extra = { xmult = 2, fraction = 3 } },
    rarity = 1,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "critic.png",
    negative_sprite = "critic_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.xmult, card.ability.extra.fraction } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            local raw = context.port or {}
            local score = (tonumber(raw.chips) or 0) * (tonumber(raw.mult) or 0)
            local target = (G and tonumber(G.current_blind_target)) or 0
            if score < target / card.ability.extra.fraction then
                return { xmult = card.ability.extra.xmult }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Wino: played Hearts and Diamonds give +12 Chips when scored.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "wino",
    loc_txt = {
        name = "Wino",
        text = {
            "Played cards with",
            "{C:hearts}Heart{} and {C:diamonds}Diamond{} suit",
            "give {C:chips}+#1#{} Chips when scored",
        },
    },
    config = { extra = { chips = 12 } },
    rarity = 1,
    cost = 5,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "wino.png",
    negative_sprite = "wino_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chips } }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            local other = context.other_card
            if other:is_suit("Hearts") or other:is_suit("Diamonds") then
                return { chips = card.ability.extra.chips }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Tangram: when a 7 is scored, +7 Mult times the number of scored 7s
-- (PC counts 7s across the full played hand).
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "tangram",
    loc_txt = {
        name = "Tangram",
        text = {
            "When a {C:attention}7{} is scored,",
            "{C:mult}+#1#{} Mult times the",
            "amount of scored {C:attention}7s{}",
        },
    },
    config = { extra = { mult = 7 } },
    rarity = 3,
    cost = 7,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "tangram.png",
    negative_sprite = "tangram_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult } }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            if context.other_card:get_id() == 7 then
                local sevens = 0
                for _, c in ipairs(context.full_hand or {}) do
                    if c:get_id() == 7 then sevens = sevens + 1 end
                end
                return { mult = card.ability.extra.mult * sevens }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- v1.1.0: exotic suits, Spectrum hands, and the Jokers Tier 1 + Tier 2
-- unlock. Everything below needs the Balatro3DS fork.
--------------------------------------------------------------------------------

local BUNCP_SPECTRUM_HANDS = { "Spectrum", "Straight Spectrum", "Spectrum House", "Spectrum Five" }

--- Bunco's exotic-system flag, derived: PC sets G.GAME.Exotic the first time
--- a Spectrum-family hand is scored. The game counts every hand played by
--- handlist position and saves the counts with the run, so a Spectrum-family
--- name with a count above zero is the same fact, read on demand.
local function buncp_exotics_on(game)
    game = game or G
    if not (game and game.handlist and game.hand_play_counts) then return false end
    for i, name in ipairs(game.handlist) do
        for _, hand in ipairs(BUNCP_SPECTRUM_HANDS) do
            if name == hand and (tonumber(game.hand_play_counts[i]) or 0) > 0 then
                return true
            end
        end
    end
    return false
end

local function buncp_exotic_pool(self, game)
    -- SMODS.in_pool passes an args table, not the game; only trust a game
    -- that actually carries a handlist.
    if type(game) ~= "table" or game.handlist == nil then game = G end
    return buncp_exotics_on(game)
end

--- Is the current blind the Boss? (The third blind of an ante always is.)
local function buncp_is_boss_round()
    if not G then return false end
    if tonumber(G.current_blind_index) == 3 then return true end
    if G.get_active_boss_blind_id then return G:get_active_boss_blind_id() ~= nil end
    return false
end

local BUNCP_RANK_NAMES = { [11] = "Jack", [12] = "Queen", [13] = "King", [14] = "Ace" }
local function buncp_rank_name(id)
    return BUNCP_RANK_NAMES[id] or tostring(id)
end

--- Every card_data in the full deck (draw pile, discard pile, hand, draw
--- queue), the same set G:count_cards_in_full_deck walks.
local function buncp_full_deck_data()
    local out = {}
    if not G then return out end
    local deck = G.deck
    if deck then
        for _, list in ipairs({ deck.cards, deck.discard_pile }) do
            if type(list) == "table" then
                for _, data in ipairs(list) do out[#out + 1] = data end
            end
        end
    end
    if G.hand then
        if type(G.hand.cards) == "table" then
            for _, data in ipairs(G.hand.cards) do out[#out + 1] = data end
        elseif type(G.hand.card_nodes) == "table" then
            for _, node in ipairs(G.hand.card_nodes) do
                if node.card_data then out[#out + 1] = node.card_data end
            end
        end
        if type(G.hand._draw_queue) == "table" then
            for _, data in ipairs(G.hand._draw_queue) do
                if type(data) == "table" then out[#out + 1] = data end
            end
        end
    end
    return out
end

local function buncp_ensure_uid(data)
    if type(data) ~= "table" then return nil end
    if data.uid == nil and G and G.ensure_card_uid then G:ensure_card_uid(data) end
    return data.uid
end

local function buncp_find_card_data(uid)
    if uid == nil then return nil end
    for _, data in ipairs(buncp_full_deck_data()) do
        if type(data) == "table" and data.uid == uid then return data end
    end
    return nil
end

--- Bunco's temporary extra chips, emulated on card_data.Bonus (the field the
--- game's own chip getter reads): grants are tracked per Joker by uid and
--- removed at end of round, which is the lifetime Bunco's end_round hook
--- gives the real thing (Bierdeckel's last the rest of the round,
--- Fingerprints' last through the next one).
local function buncp_temp_clear(extra)
    for _, grant in ipairs(extra.temp_grants or {}) do
        local data = buncp_find_card_data(grant.uid)
        if data then
            data.Bonus = math.max(0, (tonumber(data.Bonus) or 0) - grant.amount)
        end
    end
    extra.temp_grants = {}
end

local function buncp_temp_grant(extra, uid, amount)
    if uid == nil then return false end
    local data = buncp_find_card_data(uid)
    if not data then return false end
    data.Bonus = (tonumber(data.Bonus) or 0) + amount
    extra.temp_grants = extra.temp_grants or {}
    extra.temp_grants[#extra.temp_grants + 1] = { uid = uid, amount = amount }
    return true
end

--- What a card scores in Chips, the port's own arithmetic (base rank value,
--- Bonus enhancement, permanent and temporary bonus fields, Foil edition) --
--- PC Wishalloy reads Card:get_chip_bonus, which totals the same parts.
local function buncp_card_chips(view)
    local data = (view and view.card_data) or {}
    if data.enhancement == "stone" then return 50 end
    local rank = tonumber(data.rank) or 0
    local chips = rank
    if rank == 14 then chips = 11
    elseif rank >= 11 then chips = 10 end
    if data.enhancement == "bonus" then chips = chips + 30 end
    chips = chips + (tonumber(data.Bonus) or tonumber(data.bonus) or 0)
    chips = chips + (tonumber(data.chip_bonus) or 0) + (tonumber(data.chips_bonus) or 0)
    if data.modifier and data.modifier.edition == "foil" then chips = chips + 50 end
    return chips
end

--- Give a playing-card node an edition, the way the game's own Aura does it.
local function buncp_set_card_edition(node, edition)
    if not (node and node.card_data) then return end
    node.card_data.modifier = node.card_data.modifier or {}
    node.card_data.modifier.edition = edition
    if node.sync_visual_from_card_data then node:sync_visual_from_card_data() end
end

local function buncp_card_editionless(view)
    local data = (view and view.card_data) or {}
    return not (data.modifier and data.modifier.edition)
end

--------------------------------------------------------------------------------
-- Exotic suits (Tier 2). The in_pool gate is the exotic system: while it is
-- shut the suits stay out of random card fronts entirely.
--------------------------------------------------------------------------------

SMODS.Suit {
    key = "Fleurons",
    loc_txt = { name = "Fleurons" },
    ui_colour = "#dbb529",
    card_key = "FLEURON",
    in_pool = buncp_exotic_pool,
}

SMODS.Suit {
    key = "Halberds",
    loc_txt = { name = "Halberds" },
    ui_colour = "#993283",
    card_key = "HALBERD",
    in_pool = buncp_exotic_pool,
}

--------------------------------------------------------------------------------
-- Spectrum-family poker hands (Tier 2), plus Registration Plate's Deal.
-- The Spectrum test is Bunco's own (from SixSuits): single-suit cards claim
-- their suit greedily, flexible cards (Wilds in a six-suit world count as
-- fully flexible and are skipped) are matched recursively.
--------------------------------------------------------------------------------

local function buncp_spectrum(hand)
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

local function buncp_is_straight(hand)
    local seen, lo, hi = {}, 99, 0
    for _, view in ipairs(hand) do
        local id = view:get_id()
        if seen[id] then return false end
        seen[id] = true
        if id < lo then lo = id end
        if id > hi then hi = id end
    end
    if hi - lo == 4 then return true end
    return seen[14] and seen[5] and seen[4] and seen[3] and seen[2]
end

local function buncp_rank_groups(hand)
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

SMODS.PokerHand {
    key = "Spectrum",
    loc_txt = { name = "Spectrum", text = { "5 cards with different suits" } },
    chips = 50, mult = 6, l_chips = 20, l_mult = 2,
    order = 55,
    visible = false,
    evaluate = function(self, hand)
        if buncp_spectrum(hand) then return true end
        return nil
    end,
}

SMODS.PokerHand {
    key = "Straight Spectrum",
    loc_txt = { name = "Straight Spectrum", text = {
        "5 cards in a row (consecutive ranks),",
        "each with a different suit",
    } },
    chips = 120, mult = 10, l_chips = 45, l_mult = 4,
    order = 118,
    visible = false,
    evaluate = function(self, hand)
        if #hand == 5 and buncp_spectrum(hand) and buncp_is_straight(hand) then
            return true
        end
        return nil
    end,
}

SMODS.PokerHand {
    key = "Spectrum House",
    loc_txt = { name = "Spectrum House", text = {
        "A Three of a Kind and a Pair with",
        "each card having a different suit",
    } },
    chips = 150, mult = 15, l_chips = 40, l_mult = 4,
    order = 112,
    visible = false,
    evaluate = function(self, hand)
        if #hand ~= 5 or not buncp_spectrum(hand) then return nil end
        local groups = buncp_rank_groups(hand)
        if groups[1] == 3 and groups[2] == 2 then return true end
        return nil
    end,
}

SMODS.PokerHand {
    key = "Spectrum Five",
    loc_txt = { name = "Spectrum Five", text = {
        "5 cards with the same rank,",
        "each with a different suit",
    } },
    chips = 180, mult = 18, l_chips = 55, l_mult = 3,
    order = 125,
    visible = false,
    evaluate = function(self, hand)
        if #hand ~= 5 or not buncp_spectrum(hand) then return nil end
        local groups = buncp_rank_groups(hand)
        if groups[1] == 5 then return true end
        return nil
    end,
}

--- Deal: scores when the played ranks are exactly a held Registration
--- Plate's combination. PC rewrites the hand's Chips/Mult mid-evaluation
--- to the totals of every poker hand played this run; the port's evaluate
--- does the same rewrite on its hand_stats entry (level 1, l 0/0, so the
--- stored base values are what the hand scores).
SMODS.PokerHand {
    key = "Deal",
    loc_txt = { name = "Deal", text = {
        "5 ranks picked",
        "by Registration Plate",
    } },
    chips = 0, mult = 0, l_chips = 0, l_mult = 0,
    order = 130,
    visible = false,
    evaluate = function(self, hand)
        if #hand ~= 5 or not G then return nil end
        local deal = nil
        for _, j in ipairs(G.jokers or {}) do
            if j.def and j.def.id == "j_buncp_registration_plate"
                and j.ability and j.ability.extra and j.ability.extra.ranks then
                deal = j.ability.extra.ranks
                break
            end
        end
        if not deal or #deal ~= 5 then return nil end
        local counts, wanted = {}, {}
        for _, view in ipairs(hand) do
            local id = view:get_id()
            counts[id] = (counts[id] or 0) + 1
        end
        for _, id in ipairs(deal) do wanted[id] = (wanted[id] or 0) + 1 end
        for id, n in pairs(counts) do if wanted[id] ~= n then return nil end end
        for id, n in pairs(wanted) do if counts[id] ~= n then return nil end end
        if G.handlist and G.hand_stats and G.hand_play_counts then
            local idx = nil
            for i, name in ipairs(G.handlist) do
                if name == "Deal" then idx = i break end
            end
            local stats = idx and G.hand_stats[idx]
            if stats then
                local chips, mult = 0, 0
                for i, name in ipairs(G.handlist) do
                    if name ~= "Deal" and SMODS.hand_order(name) > 0
                        and (tonumber(G.hand_play_counts[i]) or 0) > 0 then
                        local _, c, m
                        if G.get_hand_level_stats then
                            _, c, m = G:get_hand_level_stats(i)
                        elseif G.get_hand_display_stats then
                            _, c, m = G:get_hand_display_stats(i)
                        end
                        chips = chips + (tonumber(c) or 0)
                        mult = mult + (tonumber(m) or 0)
                    end
                end
                stats.level = 1
                stats.base_chips = chips
                stats.base_mult = mult
            end
        end
        return true
    end,
}

--------------------------------------------------------------------------------
-- Consumables: the four Spectrum Planets (they level the hands above by
-- name) and the two exotic Tarots. On PC both Tarots are exotic-gated in
-- the pool; mod consumables have no pool gate here, so they can turn up
-- before exotics are on -- using one is still just a suit conversion.
--------------------------------------------------------------------------------

SMODS.Consumable {
    set = "Planet", key = "quaoar",
    loc_txt = { name = "Quaoar" },
    config = { hand_type = "Spectrum" },
    cost = 3,
    sprite = "quaoar.png",
    negative_sprite = "quaoar_negative.png",
}

SMODS.Consumable {
    set = "Planet", key = "haumea",
    loc_txt = { name = "Haumea" },
    config = { hand_type = "Straight Spectrum" },
    cost = 3,
    sprite = "haumea.png",
    negative_sprite = "haumea_negative.png",
}

SMODS.Consumable {
    set = "Planet", key = "sedna",
    loc_txt = { name = "Sedna" },
    config = { hand_type = "Spectrum House" },
    cost = 3,
    sprite = "sedna.png",
    negative_sprite = "sedna_negative.png",
}

SMODS.Consumable {
    set = "Planet", key = "makemake",
    loc_txt = { name = "Makemake" },
    config = { hand_type = "Spectrum Five" },
    cost = 3,
    sprite = "makemake.png",
    negative_sprite = "makemake_negative.png",
}

SMODS.Consumable {
    set = "Tarot", key = "sky",
    loc_txt = {
        name = "The Sky",
        text = {
            "Converts up to",
            "{C:attention}#1#{} selected cards",
            "to {C:attention}Fleurons{}",
        },
    },
    config = { max_highlighted = 3, suit_conv = "Fleurons" },
    cost = 3,
    sprite = "sky.png",
    negative_sprite = "sky_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { (card.ability and card.ability.max_highlighted) or 3 } }
    end,
}

SMODS.Consumable {
    set = "Tarot", key = "abyss",
    loc_txt = {
        name = "The Abyss",
        text = {
            "Converts up to",
            "{C:attention}#1#{} selected cards",
            "to {C:attention}Halberds{}",
        },
    },
    config = { max_highlighted = 3, suit_conv = "Halberds" },
    cost = 3,
    sprite = "abyss.png",
    negative_sprite = "abyss_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { (card.ability and card.ability.max_highlighted) or 3 } }
    end,
}

--------------------------------------------------------------------------------
-- Basement: when the Boss Blind is defeated, create a random Spectral
-- card (must have room).
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "basement",
    loc_txt = {
        name = "Basement Joker",
        text = {
            "When {C:attention}Boss Blind{} is defeated,",
            "create a {C:spectral}Spectral{} card",
            "{C:inactive}(Must have room)",
        },
    },
    config = { extra = {} },
    rarity = 3,
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "basement.png",
    negative_sprite = "basement_negative.png",
    calculate = function(self, card, context)
        if context.end_of_round and not context.game_over and buncp_is_boss_round() then
            if G and G.can_add_consumable and G:can_add_consumable() then
                local id = G:random_consumable_id_of_kind("spectral")
                if id and G:add_consumable(id) then
                    return { message = "+Spectral!" }
                end
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Carnival: after defeating the Boss Blind, destroy a random other Joker
-- and go one Ante back (the game's own Hieroglyph recipe: ante - 1 and an
-- ante_change event). Works once per Ante value, as on PC.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "carnival",
    loc_txt = {
        name = "Carnival",
        text = {
            "After defeating {C:attention}Boss Blind{},",
            "{C:attention}destroy{} a random Joker to",
            "go one Ante back, next time",
            "works only on a greater Ante",
        },
    },
    config = { extra = { last_ante = 0 } },
    rarity = 3,
    cost = 10,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "carnival.png",
    negative_sprite = "carnival_negative.png",
    calculate = function(self, card, context)
        local extra = card.ability.extra
        if context.end_of_round and not context.game_over and not context.blueprint
            and buncp_is_boss_round() then
            local ante = tonumber(G and G.ante) or 1
            if ante > (tonumber(extra.last_ante) or 0) then
                local targets = {}
                for _, j in ipairs((G and G.jokers) or {}) do
                    if j ~= card and not j.eternal then targets[#targets + 1] = j end
                end
                if #targets > 0 then
                    local victim = targets[SMODS.pseudorandom("buncp_carnival", 1, #targets)]
                    extra.last_ante = ante
                    SMODS.destroy_joker(victim)
                    G.ante = ante - 1
                    if G.emit_joker_event then
                        G:emit_joker_event("on_ante_change", { ante_change = -1, ante_end = false })
                    end
                    G.boss_rerolls_used_this_ante = 0
                    return { message = "Loop!" }
                end
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Dread: after your last hand of the round, level that hand up by 2 and
-- destroy every card of the played hand. Removing Dread reverses the
-- levels it granted. PC captures the whole played hand; the port stores
-- card uids at `before` and destroys by uid at `after`.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "dread",
    loc_txt = {
        name = "Dread",
        text = {
            "After scoring your {C:attention}last{} hand,",
            "upgrade it by {C:attention}#1# levels{}",
            "and {C:attention}destroy{} scored cards",
            "{C:inactive,s:0.8}All levels gained by this Joker",
            "{C:inactive,s:0.8}are lost on its removal",
        },
    },
    config = { extra = { levels = 2, trash_uids = {}, pending_hand = nil, level_up_list = {} } },
    rarity = 3,
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "dread.png",
    negative_sprite = "dread_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.levels } }
    end,
    calculate = function(self, card, context)
        local extra = card.ability.extra
        if context.before and not context.blueprint then
            extra.trash_uids = {}
            for _, view in ipairs(context.full_hand or {}) do
                local uid = view.card_data and buncp_ensure_uid(view.card_data)
                if uid ~= nil then extra.trash_uids[#extra.trash_uids + 1] = uid end
            end
            extra.pending_hand = context.scoring_name
        end
        if context.after and not context.blueprint and G and (tonumber(G.hands) or 1) <= 0 then
            local name = extra.pending_hand or context.scoring_name
            if name and G.handlist and G.upgrade_hand_level_at_index then
                for i, hand_name in ipairs(G.handlist) do
                    if hand_name == name then
                        for _ = 1, extra.levels do G:upgrade_hand_level_at_index(i) end
                        extra.level_up_list[name] = (extra.level_up_list[name] or 0) + extra.levels
                        break
                    end
                end
            end
            local by_uid = {}
            for _, view in ipairs(context.full_hand or {}) do
                if view.card_data and view.card_data.uid ~= nil then
                    by_uid[view.card_data.uid] = view
                end
            end
            for _, uid in ipairs(extra.trash_uids) do
                if by_uid[uid] then SMODS.destroy_card(by_uid[uid]) end
            end
            extra.trash_uids = {}
            return { message = "Level Up!" }
        end
    end,
    remove_from_deck = function(self, card)
        if not (G and G.handlist and G.hand_stats) then return end
        for name, levels in pairs(card.ability.extra.level_up_list or {}) do
            for i, hand_name in ipairs(G.handlist) do
                if hand_name == name then
                    local stats = G.hand_stats[i]
                    if stats then
                        stats.level = math.max(1, (tonumber(stats.level) or 1) - levels)
                        if tonumber(G.selectedHand) == i and G.get_hand_display_stats then
                            local level, chips, mult = G:get_hand_display_stats(i)
                            G.selectedHandLevel, G.selectedHandChips, G.selectedHandMult = level, chips, mult
                        end
                    end
                    break
                end
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- The Joker: after play, each scoring card without an enhancement had a
-- 1 in 3 chance (rolled at `before`) to be destroyed.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "the_joker",
    loc_txt = {
        name = "The Joker",
        text = {
            "After play, each scored",
            "card without an enhancement has",
            "{C:green}#1# in #2#{} chance to be destroyed",
        },
    },
    config = { extra = { odds = 3, trash_uids = {} } },
    rarity = 3,
    cost = 10,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "the_joker.png",
    negative_sprite = "the_joker_negative.png",
    loc_vars = function(self, info_queue, card)
        local num, den = SMODS.get_probability_vars(card, 1, card.ability.extra.odds, "buncp_the_joker")
        return { vars = { num, den } }
    end,
    calculate = function(self, card, context)
        local extra = card.ability.extra
        if context.before and not context.blueprint then
            extra.trash_uids = {}
            for _, view in ipairs(context.scoring_hand or {}) do
                if view.counts_for_play_score and view.card_data
                    and view.card_data.enhancement == nil then
                    if SMODS.pseudorandom_probability(card, "buncp_the_joker", 1, extra.odds) then
                        local uid = buncp_ensure_uid(view.card_data)
                        if uid ~= nil then extra.trash_uids[#extra.trash_uids + 1] = uid end
                    end
                end
            end
        end
        if context.after and not context.blueprint and #(extra.trash_uids or {}) > 0 then
            local by_uid = {}
            for _, view in ipairs(context.full_hand or {}) do
                if view.card_data and view.card_data.uid ~= nil then
                    by_uid[view.card_data.uid] = view
                end
            end
            local destroyed = 0
            for _, uid in ipairs(extra.trash_uids) do
                if by_uid[uid] and SMODS.destroy_card(by_uid[uid]) then
                    destroyed = destroyed + 1
                end
            end
            extra.trash_uids = {}
            if destroyed > 0 then return { message = "Destroyed!" } end
        end
    end,
}

--------------------------------------------------------------------------------
-- Loan Shark: gain $50 when acquired; selling it costs $100 (its sell
-- price is set to -$100, which the game's sell path pays out as-is).
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "loan_shark",
    loc_txt = {
        name = "Loan Shark",
        text = {
            "Gain {C:money}$#1#{}",
            "when acquired...",
        },
    },
    config = { extra = { dollars = 50, cost = -100 } },
    rarity = 2,
    cost = 3,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "loan_shark.png",
    negative_sprite = "loan_shark_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.dollars, card.ability.extra.cost } }
    end,
    add_to_deck = function(self, card)
        if G and G.money then G.money = (tonumber(G.money) or 0) + card.ability.extra.dollars end
        card.sell_cost = card.ability.extra.cost
    end,
}

--------------------------------------------------------------------------------
-- Ghost Print: gives the Chips and Mult of the last hand type played
-- (its own hand's values are banked for the next hand at joker_main).
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "ghost_print",
    loc_txt = {
        name = "Ghost Print",
        text = {
            "Gives Chips and Mult",
            "from last {C:attention}hand type{} played",
            "{C:inactive}(Last poker hand: #1#)",
        },
    },
    config = { extra = { last_hand = "Nothing" } },
    rarity = 2,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "ghost_print.png",
    negative_sprite = "ghost_print_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.last_hand } }
    end,
    calculate = function(self, card, context)
        local extra = card.ability.extra
        if context.joker_main then
            local chips, mult = 0, 0
            if extra.last_hand ~= "Nothing" and G and G.handlist then
                for i, name in ipairs(G.handlist) do
                    if name == extra.last_hand then
                        local _, c, m
                        if G.get_hand_level_stats then
                            _, c, m = G:get_hand_level_stats(i)
                        elseif G.get_hand_display_stats then
                            _, c, m = G:get_hand_display_stats(i)
                        end
                        chips, mult = tonumber(c) or 0, tonumber(m) or 0
                        break
                    end
                end
            end
            local copied = extra.last_hand
            if not context.blueprint and context.scoring_name then
                extra.last_hand = context.scoring_name
            end
            if chips ~= 0 or mult ~= 0 then
                return { chips = chips, mult = mult, message = copied .. "!" }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Linocut: a played Pair of exactly two scoring cards converts the left
-- card's suit into the right card's.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "linocut",
    loc_txt = {
        name = "Linocut Joker",
        text = {
            "When you play exactly {C:attention}2{} cards",
            "that form a {C:attention}Pair{},",
            "convert the {C:attention}left{} card's suit",
            "into the {C:attention}right{} card's suit",
            "{C:inactive}(Drag to rearrange)",
        },
    },
    config = { extra = {} },
    rarity = 2,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "linocut.png",
    negative_sprite = "linocut_negative.png",
    calculate = function(self, card, context)
        if context.after and context.scoring_hand and #context.scoring_hand == 2
            and not context.blueprint then
            if context.poker_hands and next(context.poker_hands["Pair"]) then
                local left, right = context.scoring_hand[1], context.scoring_hand[2]
                if right.card_data and right.card_data.suit and G and G.convert_suit_ripple then
                    G:convert_suit_ripple({ left }, right.card_data.suit)
                    return { message = "Copied!" }
                end
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Registration Plate: five random ranks from your deck form a
-- combination, re-rolled every round. Playing exactly those ranks scores
-- as the Deal hand (registered above), which carries the Chips and Mult
-- of every poker hand played this run.
--------------------------------------------------------------------------------

local function buncp_roll_combination(card)
    local extra = card.ability.extra
    local deck = (G and G.deck and G.deck.cards) or {}
    if #deck == 0 then return end
    local ranks, names = {}, {}
    for i = 1, 5 do
        local data = deck[SMODS.pseudorandom("buncp_registration_plate", 1, #deck)]
        ranks[i] = tonumber(data and data.rank) or 2
        names[i] = buncp_rank_name(ranks[i])
    end
    extra.ranks = ranks
    extra.combination = table.concat(names, ", ", 1, 4) .. " and " .. names[5]
end

SMODS.Joker {
    key = "registration_plate",
    loc_txt = {
        name = "Registration Plate",
        text = {
            "#1#",
            "has the Chips and Mult of all",
            "{C:attention}poker hands{} played this game",
            "{C:inactive,s:0.8}Combination changes every round",
        },
    },
    config = { extra = { combination = "", ranks = {} } },
    rarity = 3,
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "registration_plate.png",
    negative_sprite = "registration_plate_negative.png",
    loc_vars = function(self, info_queue, card)
        local combination = card.ability.extra.combination
        if combination == nil or combination == "" then combination = "2, 3, 4, 5 and 6" end
        return { vars = { combination } }
    end,
    add_to_deck = function(self, card)
        buncp_roll_combination(card)
    end,
    calculate = function(self, card, context)
        if context.end_of_round and not context.blueprint then
            buncp_roll_combination(card)
        end
    end,
}

--------------------------------------------------------------------------------
-- Righthook: the last scoring card of a played hand is retriggered once
-- per remaining hand this round (Tier 1's retrigger return).
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "righthook",
    loc_txt = {
        name = "Righthook",
        text = {
            "Retrigger the {C:attention}last played",
            "{C:attention}scoring card{} once for every",
            "{C:attention}remaining hand{} this round",
        },
    },
    config = { extra = {} },
    rarity = 3,
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "righthook.png",
    negative_sprite = "righthook_negative.png",
    calculate = function(self, card, context)
        if context.repetition and context.cardarea == G.play and context.other_card then
            local played = context.port and context.port.played_cards
            if played then
                local last = nil
                for _, view in ipairs(played) do
                    if view.counts_for_play_score then last = view end
                end
                if last and context.other_card == last then
                    local hands_left = tonumber((G and G.hands) or 0) or 0
                    if hands_left > 0 then
                        return { repetitions = hands_left }
                    end
                end
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Fingerprints: scored cards gain +50 Chips for their next scoring round
-- (granted at end of round, cleared at the next one, by uid).
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "fingerprints",
    loc_txt = {
        name = "Fingerprints",
        text = {
            "Cards gain {C:chips}+50{} Chips",
            "after being scored last round",
        },
    },
    config = { extra = { chips = 50, last_scoring = {} } },
    rarity = 2,
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "fingerprints.png",
    negative_sprite = "fingerprints_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chips } }
    end,
    calculate = function(self, card, context)
        local extra = card.ability.extra
        if context.after and not context.blueprint and context.scoring_hand then
            extra.last_scoring = {}
            for _, view in ipairs(context.scoring_hand) do
                if view.card_data then
                    local uid = buncp_ensure_uid(view.card_data)
                    if uid ~= nil then
                        extra.last_scoring[#extra.last_scoring + 1] = uid
                    end
                end
            end
        end
        if context.end_of_round and not context.blueprint then
            buncp_temp_clear(extra)
            if G and (tonumber(G.hands) or 0) > 0 and not context.game_over then
                for _, uid in ipairs(extra.last_scoring or {}) do
                    buncp_temp_grant(extra, uid, extra.chips)
                end
            end
            extra.last_scoring = {}
        end
    end,
}

--------------------------------------------------------------------------------
-- Bierdeckel: cards left in hand at scoring or discard time gain +10 Chips
-- until the end of the round (same Bonus emu00e9lation as Fingerprints).
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "bierdeckel",
    loc_txt = {
        name = "Bierdeckel",
        text = {
            "Cards left in your hand give",
            "{C:chips}+#1#{} Chips until the",
            "end of the round",
        },
    },
    config = { extra = { chips = 10 } },
    rarity = 2,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "bierdeckel.png",
    negative_sprite = "bierdeckel_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chips } }
    end,
    calculate = function(self, card, context)
        local extra = card.ability.extra
        if context.after and not context.blueprint and G and G.hand then
            local played = {}
            for _, view in ipairs(context.full_hand or {}) do
                if view.card_data and view.card_data.uid ~= nil then
                    played[view.card_data.uid] = true
                end
            end
            for _, node in ipairs(G.hand.card_nodes or {}) do
                if node.card_data then
                    local uid = buncp_ensure_uid(node.card_data)
                    if uid ~= nil and not played[uid] then
                        buncp_temp_grant(extra, uid, extra.chips)
                    end
                end
            end
        end
        if context.discard and context.other_card and not context.blueprint and G and G.hand then
            local batch = (context.port and context.port.discarded_nodes) or {}
            if context.other_card == batch[1] then
                local in_batch = {}
                for _, node in ipairs(batch) do
                    if node.card_data and node.card_data.uid ~= nil then
                        in_batch[node.card_data.uid] = true
                    end
                end
                for _, node in ipairs(G.hand.card_nodes or {}) do
                    if node.card_data then
                        local uid = buncp_ensure_uid(node.card_data)
                        if uid ~= nil and not in_batch[uid] then
                            buncp_temp_grant(extra, uid, extra.chips)
                        end
                    end
                end
            end
        end
        if context.end_of_round and not context.blueprint then
            buncp_temp_clear(extra)
        end
    end,
}

--------------------------------------------------------------------------------
-- Zero Shapiro: scored Kings, Queens, Jacks and rankless (Stone) cards
-- have a 1 in 8 chance to create a D6 Tag.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "zero_shapiro",
    loc_txt = {
        name = "Zero Shapiro",
        text = {
            "Scored {C:attention}Ks, Qs, Js, or Rankless{} cards",
            "have a {C:green}#1# in #2#{} chance to",
            "create a {C:attention}D6 Tag{}",
        },
    },
    config = { extra = { odds = 8 } },
    rarity = 2,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "zero_shapiro.png",
    negative_sprite = "zero_shapiro_negative.png",
    loc_vars = function(self, info_queue, card)
        local num, den = SMODS.get_probability_vars(card, 1, card.ability.extra.odds, "buncp_zero_shapiro")
        return { vars = { num, den } }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play and context.other_card then
            local other = context.other_card
            local stone = other.card_data and other.card_data.enhancement == "stone"
            if stone or other:is_face() then
                if SMODS.pseudorandom_probability(card, "buncp_zero_shapiro", 1, card.ability.extra.odds) then
                    if G and G.addTag then G:addTag("d6") end
                    return { message = "Tag!" }
                end
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Pawn: after play, every scored card tied for the deck's lowest rank
-- (Stone excluded, Aces immune) gains +1 rank.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "pawn",
    loc_txt = {
        name = "Pawn",
        text = {
            "After play, if no {C:attention}rank{} in your",
            "full deck is lower than a {C:attention}scored{}",
            "card's rank, it gains {C:attention}+1{} rank instead",
            "{C:inactive}(Lowest rank in deck now: #1#)",
            "{C:inactive}(Stone Cards are ignored)",
        },
    },
    config = { extra = {} },
    rarity = 1,
    cost = 5,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "pawn.png",
    negative_sprite = "pawn_negative.png",
    loc_vars = function(self, info_queue, card)
        local lowest = 14
        for _, data in ipairs(buncp_full_deck_data()) do
            if type(data) == "table" and data.enhancement ~= "stone" then
                local rank = tonumber(data.rank) or 14
                if rank < lowest then lowest = rank end
            end
        end
        return { vars = { buncp_rank_name(lowest) } }
    end,
    calculate = function(self, card, context)
        if context.after and context.scoring_hand and not context.blueprint then
            local lowest = nil
            for _, data in ipairs(buncp_full_deck_data()) do
                if data.enhancement ~= "stone" then
                    local rank = tonumber(data.rank) or 14
                    if lowest == nil or rank < lowest then lowest = rank end
                end
            end
            if lowest ~= nil and lowest < 14 then
                local raised = 0
                for _, view in ipairs(context.scoring_hand) do
                    if view.card_data and view.card_data.enhancement ~= "stone"
                        and view:get_id() == lowest then
                        view.card_data.rank = view.card_data.rank + 1
                        if view.sync_visual_from_card_data then
                            view:sync_visual_from_card_data()
                        end
                        raised = raised + 1
                    end
                end
                if raised > 0 then return { message = "+1 Rank!" } end
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Hopscotch: +1 discard this round when you play a Straight.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "hopscotch",
    loc_txt = {
        name = "Hopscotch",
        text = {
            "Gain {C:attention}+#1#{} Discard",
            "this round if poker hand",
            "contains a {C:attention}Straight",
        },
    },
    config = { extra = { d_discards = 1 } },
    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "hopscotch.png",
    negative_sprite = "hopscotch_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.d_discards } }
    end,
    calculate = function(self, card, context)
        if context.before and context.poker_hands and next(context.poker_hands["Straight"]) then
            if G then G.discards = (tonumber(G.discards) or 0) + card.ability.extra.d_discards end
            return { message = "+" .. card.ability.extra.d_discards .. " Discard" }
        end
    end,
}

--------------------------------------------------------------------------------
-- Doodle: once per round, using a Tarot or Planet duplicates it (when it
-- left room for the copy). Re-arms at end of round.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "doodle",
    loc_txt = {
        name = "Doodle",
        text = {
            "When you use a non-{C:attention}Negative{}",
            "{C:tarot}Tarot{} or {C:planet}Planet{} card, duplicate it",
            "{C:inactive}(If there is room)",
            "{C:inactive}Once per round",
        },
    },
    config = { extra = { active = true } },
    rarity = 3,
    cost = 10,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "doodle.png",
    negative_sprite = "doodle_negative.png",
    calculate = function(self, card, context)
        local extra = card.ability.extra
        if context.using_consumeable and not context.blueprint and extra.active then
            local raw = context.port or {}
            local kind = raw.consumable_kind
            if kind == "tarot" or kind == "planet" then
                if G and G.can_add_consumable and G:can_add_consumable() then
                    extra.active = false
                    local edition = raw.consumable and raw.consumable.edition
                    local params = nil
                    if edition then params = { edition = edition } end
                    if raw.consumable_id and G:add_consumable(raw.consumable_id, params) then
                        return { message = "Duplicated!" }
                    end
                end
            end
        end
        if context.end_of_round and not context.blueprint then
            extra.active = true
        end
    end,
}

--------------------------------------------------------------------------------
-- X-Ray: X0.2 Mult for every card drawn face down this run phase. The
-- port reports draws once per deal (the hand_drawn context carries the
-- whole drawn set), so the XMult banks at deal time instead of per card.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "xray",
    loc_txt = {
        name = "X-Ray",
        text = {
            "{X:mult,C:white}X#2#{} Mult for every card",
            "drawn {C:attention}face down{}",
            "{C:inactive}(Currently {X:mult,C:white}X#1#{C:inactive} Mult)",
        },
    },
    config = { extra = { xmult_gain = 0.2, xmult = 1 } },
    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = false,
    perishable_compat = false,
    sprite = "xray.png",
    negative_sprite = "xray_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.xmult, card.ability.extra.xmult_gain } }
    end,
    calculate = function(self, card, context)
        local extra = card.ability.extra
        if context.hand_drawn and not context.blueprint then
            local drawn = context.hand_drawn
            local facedown = 0
            for _, view in ipairs(drawn) do
                if view.face_up == false then facedown = facedown + 1 end
            end
            if facedown > 0 then
                extra.xmult = extra.xmult + extra.xmult_gain * facedown
                return { message = "X" .. string.format("%.1f", extra.xmult) }
            end
        end
        if context.joker_main and extra.xmult ~= 1 then
            return { xmult = extra.xmult }
        end
    end,
}

--------------------------------------------------------------------------------
-- Mousetrap: 1 in 3 chance to lose a hand this round instead of scoring;
-- when no hands remain, the hand scores +300 Chips.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "mousetrap",
    loc_txt = {
        name = "Mousetrap",
        text = {
            "{C:green}#1# in #2#{} chance to {C:attention}lose a hand{}",
            "instead of scoring",
            "If no hands are left, this hand",
            "scores {C:chips}+300{} Chips instead",
        },
    },
    config = { extra = { odds = 3, chips = 300 } },
    rarity = 2,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "mousetrap.png",
    negative_sprite = "mousetrap_negative.png",
    loc_vars = function(self, info_queue, card)
        local num, den = SMODS.get_probability_vars(card, 1, card.ability.extra.odds, "buncp_mousetrap")
        return { vars = { num, den } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            if SMODS.pseudorandom_probability(card, "buncp_mousetrap", 1, card.ability.extra.odds) then
                if G and (tonumber(G.hands) or 0) > 0 then
                    G.hands = G.hands - 1
                    return { message = "Ouch!" }
                end
                return { chips = card.ability.extra.chips, message = "+300" }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Stylophone: scored cards give Mult equal to 0.3 times their rank
-- (Stone Cards are rankless and pay nothing). PC's sound-click ladder is
-- cosmetic and has no equivalent here.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "stylophone",
    loc_txt = {
        name = "Stylophone",
        text = {
            "Played cards give",
            "{C:mult}+#1#{} Mult for every {C:attention}pip",
            "they have when scored",
        },
    },
    config = { extra = { mult = 0.3 } },
    rarity = 2,
    cost = 5,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "stylophone.png",
    negative_sprite = "stylophone_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult } }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play and context.other_card then
            local other = context.other_card
            if not (other.card_data and other.card_data.enhancement == "stone") then
                local mult = other:get_id() * card.ability.extra.mult
                if mult ~= 0 then return { mult = mult } end
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Juggalo: when a blind is selected, a random owned consumable without an
-- edition gains a random edition (Foil, Holographic or Polychrome --
-- Bunco's fourth option, Glitter, is a custom edition and is left out).
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "juggalo",
    loc_txt = {
        name = "Juggalo",
        text = {
            "When blind is selected, apply",
            "a random {C:attention}edition{} to a random",
            "{C:attention}consumable{} you own",
        },
    },
    config = { extra = {} },
    rarity = 3,
    cost = 5,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "juggalo.png",
    negative_sprite = "juggalo_negative.png",
    calculate = function(self, card, context)
        if context.setting_blind and G then
            local plain = {}
            for i, c in ipairs(G.consumables or {}) do
                if not c.edition then plain[#plain + 1] = i end
            end
            if #plain > 0 then
                local idx = plain[SMODS.pseudorandom("buncp_juggalo", 1, #plain)]
                local editions = { "foil", "holo", "polychrome" }
                local edition = editions[SMODS.pseudorandom("buncp_juggalo", 1, #editions)]
                G.consumables[idx].edition = edition
                if G.consumable_nodes and G.consumable_nodes[idx] then
                    G.consumable_nodes[idx].edition = edition
                end
                return { message = "Edition!" }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Puzzle Board: using a Tarot has a 1 in 4 chance to apply a random
-- edition to a random highlighted card without one.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "puzzle_board",
    loc_txt = {
        name = "Puzzle Board",
        text = {
            "When you use a {C:tarot}Tarot{} card,",
            "{C:green}#1# in #2#{} chance to apply a random",
            "{C:attention}edition{} to a random",
            "{C:attention}highlighted{} card",
        },
    },
    config = { extra = { odds = 4 } },
    rarity = 2,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "puzzle_board.png",
    negative_sprite = "puzzle_board_negative.png",
    loc_vars = function(self, info_queue, card)
        local num, den = SMODS.get_probability_vars(card, 1, card.ability.extra.odds, "buncp_puzzle_board")
        return { vars = { num, den } }
    end,
    calculate = function(self, card, context)
        if context.using_consumeable and not context.blueprint then
            local raw = context.port or {}
            if raw.consumable_kind == "tarot" then
                if SMODS.pseudorandom_probability(card, "buncp_puzzle_board", 1, card.ability.extra.odds) then
                    local highlighted = nil
                    if G and G.hand then
                        highlighted = G.hand.highlighted
                        if (not highlighted or #highlighted == 0) and G.hand.ordered_selected_nodes then
                            highlighted = G.hand:ordered_selected_nodes()
                        end
                    end
                    local plain = {}
                    for _, node in ipairs(highlighted or {}) do
                        if buncp_card_editionless(node) then plain[#plain + 1] = node end
                    end
                    if #plain > 0 and G and G.poll_guaranteed_edition then
                        local node = plain[SMODS.pseudorandom("buncp_puzzle_board", 1, #plain)]
                        buncp_set_card_edition(node, G:poll_guaranteed_edition("wheel_of_fortune"))
                        return { message = "Edition!" }
                    end
                end
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Exotic Jokers. Their in_pool is Bunco's exotic_in_pool: they only enter
-- pools once the exotic system is on (first Spectrum-family hand scored).
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "zealous",
    loc_txt = {
        name = "Zealous Joker",
        text = {
            "{C:mult}+#1#{} Mult if played",
            "hand contains",
            "a {C:attention}Spectrum",
        },
    },
    config = { extra = { mult = 10 } },
    rarity = 1,
    cost = 3,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    in_pool = buncp_exotic_pool,
    sprite = "zealous.png",
    negative_sprite = "zealous_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            if context.poker_hands and next(context.poker_hands["Spectrum"]) then
                return { mult = card.ability.extra.mult }
            end
        end
    end,
}

SMODS.Joker {
    key = "lurid",
    loc_txt = {
        name = "Lurid Joker",
        text = {
            "{C:chips}+#1#{} Chips if played",
            "hand contains",
            "a {C:attention}Spectrum",
        },
    },
    config = { extra = { chips = 80 } },
    rarity = 1,
    cost = 3,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    in_pool = buncp_exotic_pool,
    sprite = "lurid.png",
    negative_sprite = "lurid_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chips } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            if context.poker_hands and next(context.poker_hands["Spectrum"]) then
                return { chips = card.ability.extra.chips }
            end
        end
    end,
}

SMODS.Joker {
    key = "envious",
    loc_txt = {
        name = "Envious Joker",
        text = {
            "Played cards with",
            "{C:attention}Fleuron{} suit give",
            "{C:mult}+#1#{} Mult when scored",
        },
    },
    config = { extra = { mult = 6 } },
    rarity = 1,
    cost = 5,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    in_pool = buncp_exotic_pool,
    sprite = "envious.png",
    negative_sprite = "envious_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult } }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play and context.other_card then
            if context.other_card:is_suit("Fleurons") then
                return { mult = card.ability.extra.mult }
            end
        end
    end,
}

SMODS.Joker {
    key = "proud",
    loc_txt = {
        name = "Proud Joker",
        text = {
            "Played cards with",
            "{C:attention}Halberd{} suit give",
            "{C:mult}+#1#{} Mult when scored",
        },
    },
    config = { extra = { mult = 6 } },
    rarity = 1,
    cost = 5,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    in_pool = buncp_exotic_pool,
    sprite = "proud.png",
    negative_sprite = "proud_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult } }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play and context.other_card then
            if context.other_card:is_suit("Halberds") then
                return { mult = card.ability.extra.mult }
            end
        end
    end,
}

SMODS.Joker {
    key = "wishalloy",
    loc_txt = {
        name = "Wishalloy",
        text = {
            "{C:green}#1# in #2#{} chance for",
            "played {C:attention}Fleurons{} to",
            "earn {C:money}${} equal to",
            "card's scored Chips",
        },
    },
    config = { extra = { odds = 7 } },
    rarity = 2,
    cost = 7,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    in_pool = buncp_exotic_pool,
    sprite = "wishalloy.png",
    negative_sprite = "wishalloy_negative.png",
    loc_vars = function(self, info_queue, card)
        local num, den = SMODS.get_probability_vars(card, 1, card.ability.extra.odds, "buncp_wishalloy")
        return { vars = { num, den } }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play and context.other_card then
            local other = context.other_card
            if other:is_suit("Fleurons") then
                if SMODS.pseudorandom_probability(card, "buncp_wishalloy", 1, card.ability.extra.odds) then
                    return { dollars = buncp_card_chips(other) }
                end
            end
        end
    end,
}

SMODS.Joker {
    key = "unobtanium",
    loc_txt = {
        name = "Unobtanium",
        text = {
            "Played cards with",
            "{C:attention}Halberd{} suit give",
            "{C:chips}+#1#{} Chips and {C:mult}+#2#{} Mult",
            "when scored",
        },
    },
    config = { extra = { chips = 30, mult = 6 } },
    rarity = 2,
    cost = 7,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    in_pool = buncp_exotic_pool,
    sprite = "unobtanium.png",
    negative_sprite = "unobtanium_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chips, card.ability.extra.mult } }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play and context.other_card then
            if context.other_card:is_suit("Halberds") then
                return { chips = card.ability.extra.chips, mult = card.ability.extra.mult }
            end
        end
    end,
}

SMODS.Joker {
    key = "dynasty",
    loc_txt = {
        name = "The Dynasty",
        text = {
            "{X:mult,C:white}X#1#{} Mult if played",
            "hand contains",
            "a {C:attention}Spectrum",
        },
    },
    config = { extra = { xmult = 5 } },
    rarity = 3,
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    in_pool = buncp_exotic_pool,
    sprite = "dynasty.png",
    negative_sprite = "dynasty_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.xmult } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            if context.poker_hands and next(context.poker_hands["Spectrum"]) then
                return { xmult = card.ability.extra.xmult }
            end
        end
    end,
}

SMODS.Joker {
    key = "magic_wand",
    loc_txt = {
        name = "Magic Wand",
        text = {
            "This Joker gains {C:mult}+#1#{} Mult",
            "per {C:attention}consecutive{} played hand",
            "containing a {C:attention}Spectrum{}",
            "{C:inactive}(Currently {C:mult}+#2#{C:inactive} Mult)",
        },
    },
    config = { extra = { mult_gain = 3, mult = 0 } },
    rarity = 1,
    cost = 5,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    in_pool = buncp_exotic_pool,
    sprite = "magic_wand.png",
    negative_sprite = "magic_wand_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult_gain, card.ability.extra.mult } }
    end,
    calculate = function(self, card, context)
        local extra = card.ability.extra
        if context.before and not context.blueprint then
            if context.poker_hands and next(context.poker_hands["Spectrum"]) then
                extra.mult = extra.mult + extra.mult_gain
            end
        end
        if context.after and not context.blueprint then
            if not (context.poker_hands and next(context.poker_hands["Spectrum"])) then
                extra.mult = 0
            end
        end
        if context.joker_main and extra.mult > 0 then
            return { mult = extra.mult }
        end
    end,
}

SMODS.Joker {
    key = "starfruit",
    loc_txt = {
        name = "Starfruit",
        text = {
            "Level up played poker hand",
            "if it contains a {C:attention}Spectrum",
            "{C:green}#1# in #2#{} chance this card is",
            "destroyed at the end of round",
        },
    },
    config = { extra = { odds = 4 } },
    rarity = 2,
    cost = 5,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    in_pool = buncp_exotic_pool,
    sprite = "starfruit.png",
    negative_sprite = "starfruit_negative.png",
    loc_vars = function(self, info_queue, card)
        local num, den = SMODS.get_probability_vars(card, 1, card.ability.extra.odds, "buncp_starfruit")
        return { vars = { num, den } }
    end,
    calculate = function(self, card, context)
        local extra = card.ability.extra
        if context.before and not context.blueprint then
            if context.poker_hands and next(context.poker_hands["Spectrum"]) then
                if context.scoring_name and G and G.handlist and G.upgrade_hand_level_at_index then
                    for i, name in ipairs(G.handlist) do
                        if name == context.scoring_name then
                            G:upgrade_hand_level_at_index(i)
                            break
                        end
                    end
                    return { message = "Level Up!" }
                end
            end
        end
        if context.end_of_round and not context.blueprint and G and (tonumber(G.hands) or 0) > 0 then
            if SMODS.pseudorandom_probability(card, "buncp_starfruit", 1, extra.odds) then
                SMODS.destroy_joker(card)
                return { message = "Eaten!" }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Fondue: scored cards in the first hand of the round become Fleurons
-- (conversion runs in chunks of three, the conversion ripple's cap).
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "fondue",
    loc_txt = {
        name = "Fondue",
        text = {
            "Scored cards in the",
            "{C:attention}first hand{} of round are",
            "converted to {C:attention}Fleurons",
        },
    },
    config = { extra = { armed = false } },
    rarity = 3,
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    in_pool = buncp_exotic_pool,
    sprite = "fondue.png",
    negative_sprite = "fondue_negative.png",
    calculate = function(self, card, context)
        local extra = card.ability.extra
        if context.first_hand_drawn and not context.blueprint then
            extra.armed = true
        end
        if context.after and not context.blueprint and extra.armed and context.scoring_hand then
            extra.armed = false
            if G and G.convert_suit_ripple then
                local chunk = {}
                for _, view in ipairs(context.scoring_hand) do
                    chunk[#chunk + 1] = view
                    if #chunk == 3 then
                        G:convert_suit_ripple(chunk, "Fleurons")
                        chunk = {}
                    end
                end
                if #chunk > 0 then G:convert_suit_ripple(chunk, "Fleurons") end
                return { message = "Converted!" }
            end
        end
    end,
}

SMODS.Joker {
    key = "roygbiv",
    loc_txt = {
        name = "Roy G. Biv",
        text = {
            "{C:green}#1# in #2#{} chance to add",
            "{C:dark_edition}Polychrome{} edition",
            "to all scored cards if",
            "hand contains a {C:attention}Spectrum",
        },
    },
    config = { extra = { odds = 7 } },
    rarity = 2,
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    in_pool = buncp_exotic_pool,
    sprite = "roygbiv.png",
    negative_sprite = "roygbiv_negative.png",
    loc_vars = function(self, info_queue, card)
        local num, den = SMODS.get_probability_vars(card, 1, card.ability.extra.odds, "buncp_roygbiv")
        return { vars = { num, den } }
    end,
    calculate = function(self, card, context)
        if context.before and not context.blueprint and context.scoring_hand then
            if context.poker_hands and next(context.poker_hands["Spectrum"]) then
                if SMODS.pseudorandom_probability(card, "buncp_roygbiv", 1, card.ability.extra.odds) then
                    local changed = 0
                    for _, view in ipairs(context.scoring_hand) do
                        if buncp_card_editionless(view) then
                            buncp_set_card_edition(view, "polychrome")
                            changed = changed + 1
                        end
                    end
                    if changed > 0 then return { message = "Polychrome!" } end
                end
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Rigoletto: X1 Mult, plus X0.2 per exotic card (Fleurons/Halberds suit or
-- Wild enhancement) in the full deck. Legendary: soul sprite beside it.
--------------------------------------------------------------------------------

local function buncp_exotic_count()
    local count = 0
    for _, data in ipairs(buncp_full_deck_data()) do
        if type(data) == "table" then
            if data.enhancement ~= "stone" then
                if data.suit == "Fleurons" or data.suit == "Halberds"
                    or data.enhancement == "wild" then
                    count = count + 1
                end
            else
                -- Stone cards hide their suit; PC counts them as nothing.
            end
        end
    end
    return count
end

SMODS.Joker {
    key = "rigoletto",
    loc_txt = {
        name = "Rigoletto",
        text = {
            "{X:mult,C:white}X#1#{} Mult per {C:attention}Exotic card{}",
            "in your {C:attention}full deck",
            "{C:inactive}(Currently {X:mult,C:white}X#2#{C:inactive} Mult)",
        },
    },
    config = { extra = { xmult = 0.2 } },
    rarity = 4,
    cost = 20,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    in_pool = buncp_exotic_pool,
    sprite = "rigoletto.png",
    negative_sprite = "rigoletto_negative.png",
    soul_sprite = "rigoletto_soul.png",
    loc_vars = function(self, info_queue, card)
        local total = 1 + card.ability.extra.xmult * buncp_exotic_count()
        return { vars = { card.ability.extra.xmult, total } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            local total = 1 + card.ability.extra.xmult * buncp_exotic_count()
            if total ~= 1 then return { xmult = total } end
        end
    end,
}

--------------------------------------------------------------------------------
-- v1.2.0: Tier 3 top-ups. The Fluorescent edition + Neon (setting_ability),
-- and Bounty Hunter (money_altered at v1.2.0; its tax moved to the Wave 1
-- money_transform seat in v1.3.0, below). Everything below needs the
-- fork's Tier 3 API.
--------------------------------------------------------------------------------

-- Fluorescent edition (PC SMODS.Edition key "fluorescent", in_shop = true,
-- weight 18 on PC's scale, where Foil weighs 20). The fork's edition poll
-- weights are percents of a roll (Foil 4, Holo 2, Polychrome 0.6), so 3.5
-- keeps roughly PC's relative rarity. PC Fluorescent has NO stats: its
-- whole effect is immunities -- it cannot be flipped, debuffed or forced
-- to be selected, enforced on PC by Lovely patches on set_debuff and card
-- selection. The fork's editions are config-only, with no calculate and no
-- hooks, so those immunities are NOT implemented here: the edition
-- registers with an empty config, carries no sprite (PC's look is a
-- shader; there is no overlay art to port, and the engine draws the card
-- plainly), and its tooltip says the immunities are missing. What DOES
-- port exactly is Neon's grant of it, below.
if SMODS.Edition then
    SMODS.Edition {
        key = "fluorescent",
        loc_txt = {
            name = "Fluorescent",
            text = {
                "Cannot be flipped, debuffed",
                "or forced to be selected",
                "{C:inactive}(Those immunities are not",
                "{C:inactive}implemented on 3DS; no stats){}",
            },
        },
        config = {},
        weight = 3.5,
    }
end

--------------------------------------------------------------------------------
-- Neon: playing cards gain the Fluorescent edition when enhanced.
-- PC hooks Bunco's own enhance_card context (a Lovely patch on
-- Card:set_ability that fires when a card's center changes to a DIFFERENT
-- Enhanced center, not on the initial set). The fork's equivalent is the
-- Tier 3 setting_ability context, raised by the canonical setters
-- (Card:set_enhancement / set_seal): the changed card arrives as
-- context.other_card, the kind ("enhancement"/"seal") rides the raw event,
-- and `unchanged` marks a re-set to the same value. The grant itself
-- writes the edition the way the pack's own edition writers do
-- (buncp_set_card_edition on the card's node data, the Juggalo / Puzzle
-- Board precedent: playing-card editions have no node setter).
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "neon",
    loc_txt = {
        name = "Neon Joker",
        text = {
            "Playing cards gain",
            "{C:dark_edition}Fluorescent{} edition",
            "when {C:attention}enhanced{}",
        },
    },
    config = { extra = {} },
    rarity = 2,
    cost = 5,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "neon.png",
    negative_sprite = "neon_negative.png",
    calculate = function(self, card, context)
        if context.setting_ability and not context.blueprint
            and not context.unchanged
            and context.port and context.port.ability_kind == "enhancement"
            and context.other_card then
            if SMODS.EditionByValue and SMODS.EditionByValue.fluorescent
                and buncp_card_editionless(context.other_card) then
                buncp_set_card_edition(context.other_card, "fluorescent")
                return { message = "Fluorescent!" }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Bounty Hunter: every positive money gain is taxed $1, and this Joker
-- permanently gains +1 Mult per taxed gain.
-- PC implements this inside Bunco's ease_dollars wrapper (funcs.ease_dollars
-- + the get_money calculate): before a positive gain lands, each held
-- Bounty Hunter takes $1 off it and grows. Since v1.3.0 the port does the
-- same on the fork's Wave 1 money_transform seat, which is asked of each
-- held Joker in slot order before the gain lands with the gain as the
-- previous Joker left it in context.amount: returning the amount minus
-- $1 shrinks the gain itself, so several copies tax the shrinking
-- remainder in turn (a later copy stands down once the gain is gone,
-- because the seat stops at zero), exactly as PC's wrapper does. (At
-- v1.2.0 the tax rode money_altered as a separate -$1 event after the
-- gain landed in full; the totals matched but the ordering did not.)
-- Blueprint copies do neither, as on PC: the seat only asks the held
-- Joker's own calculate, never a copy's, and the get_money growth is
-- blueprint-guarded there too.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "bounty_hunter",
    loc_txt = {
        name = "Bounty Hunter",
        text = {
            "All sources of money",
            "give {C:money}$1{} less and this Joker",
            "gains {C:mult}+#1#{} Mult each time",
            "you earn money",
            "{C:inactive}(Currently {C:mult}+#2#{C:inactive} Mult){}",
        },
    },
    config = { extra = { bonus = 1, mult = 0 } },
    rarity = 1,
    cost = 5,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    sprite = "bounty_hunter.png",
    negative_sprite = "bounty_hunter_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.bonus, card.ability.extra.mult } }
    end,
    calculate = function(self, card, context)
        if context.money_transform and not context.blueprint
            and (tonumber(context.amount) or 0) > 0 then
            card.ability.extra.mult = card.ability.extra.mult + card.ability.extra.bonus
            return { amount = context.amount - 1, message = "Robbed!" }
        end
        if context.joker_main and card.ability.extra.mult ~= 0 then
            return { mult = card.ability.extra.mult }
        end
    end,
}

--------------------------------------------------------------------------------
-- v1.3.0: Wave 1 top-ups. Fiendish and Bounty Hunter's tax (above) ride
-- the money_transform seat; Head in the Clouds rides level_up_hand.
-- Everything below needs the fork's Wave 1 mod API.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Fiendish: rewrites every money gain before it lands. On a 1 in 3 roll
-- the gain pays out as $1 instead; otherwise the gain is doubled.
-- PC has no calculate for this at all: Bunco's ease_dollars wrapper walks
-- the held Jokers itself, and for each non-debuffed Fiendish, on a
-- positive gain, rolls pseudorandom against probabilities.normal / odds
-- -- success sets the gain to $1, failure doubles it -- with later copies
-- transforming the amount earlier copies left. The fork's money_transform
-- seat is that wrapper's shape: asked of each held Joker in slot order
-- before the gain lands, context.amount is the gain as the previous
-- Joker left it, and returning { amount = n } replaces it. Boss-debuffed
-- Jokers are skipped by the seat and a Blueprint/Brainstorm copy does
-- not transform, both matching PC (whose wrapper keys off the held
-- Joker's own center; PC also marks this Joker blueprint-incompatible).
-- The roll goes through SMODS.pseudorandom_probability, the pack's usual
-- surface, so Oops! All 6s and mod_probability Jokers count, as PC's
-- probabilities.normal does.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "fiendish",
    loc_txt = {
        name = "Fiendish Joker",
        text = {
            "Double all sources of money,",
            "{C:green}#1# in #2#{} chance to pay out",
            "with {C:money}$1{} instead",
        },
    },
    config = { extra = { odds = 3 } },
    rarity = 2,
    cost = 5,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "fiendish.png",
    negative_sprite = "fiendish_negative.png",
    loc_vars = function(self, info_queue, card)
        local num, den = SMODS.get_probability_vars(card, 1, card.ability.extra.odds, "buncp_fiendish")
        return { vars = { num, den } }
    end,
    calculate = function(self, card, context)
        if context.money_transform and not context.blueprint then
            local amount = tonumber(context.amount) or 0
            if amount > 0 then
                if SMODS.pseudorandom_probability(card, "buncp_fiendish", 1, card.ability.extra.odds) then
                    return { amount = 1, message = "$1" }
                else
                    return { amount = amount * 2, message = "$" .. (amount * 2) }
                end
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Head in the Clouds: whenever any OTHER hand is levelled, a 1 in 3
-- chance to level High Card.
-- PC's calculate answers Bunco's level_up_hand context (a Lovely patch
-- on level_up_hand itself, which fires the context for every held Head
-- before the level lands): on a hit it levels the hand by calling
-- level_up_hand with its own name, "Head in the Clouds", as the hand
-- argument -- a sentinel a second patch translates to High Card after
-- the contexts have fired. The guard context.level_up_hand ~= self.name
-- is what keeps it from chaining: its own level-ups arrive carrying that
-- sentinel name, never a real hand. The fork's level_up_hand context
-- carries the hand's NAME (Steamodded's shape), so the port keeps PC's
-- guard verbatim (no hand here is named "Head in the Clouds", so it
-- never blocks a real level-up) and does the sentinel's real work with a
-- game-level flag: while a Head-caused High Card upgrade is landing --
-- the fork's upgrade funnel raises the context again as it lands, and
-- chains are capped by the engine besides -- every held copy stands
-- down, for this copy and for the other copies PC's sentinel would also
-- have silenced. The level itself goes through the game's own upgrade
-- funnel (G:upgrade_hand_level_at_index, the Dread / Starfruit route).
-- PC also gates the pool: the Joker only appears once High Card is
-- above level 1 (custom_in_pool), ported as in_pool below.
--------------------------------------------------------------------------------

local function buncp_head_in_the_clouds_pool(self, game)
    -- SMODS.in_pool passes an args table, not the game; only trust a game
    -- that actually carries a handlist.
    if type(game) ~= "table" or game.handlist == nil then game = G end
    if not (game and game.handlist and game.hand_stats) then return false end
    for i, name in ipairs(game.handlist) do
        if name == "High Card" then
            return (tonumber(game.hand_stats[i].level) or 1) > 1
        end
    end
    return false
end

SMODS.Joker {
    key = "head_in_the_clouds",
    loc_txt = {
        name = "Head in the Clouds",
        text = {
            "{C:green}#1# in #2#{} chance to upgrade",
            "{C:attention}High Card{} when you",
            "upgrade any {C:attention}poker hand",
        },
    },
    config = { extra = { odds = 3 } },
    rarity = 2,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    in_pool = buncp_head_in_the_clouds_pool,
    sprite = "head_in_the_clouds.png",
    negative_sprite = "head_in_the_clouds_negative.png",
    loc_vars = function(self, info_queue, card)
        local num, den = SMODS.get_probability_vars(card, 1, card.ability.extra.odds, "buncp_head_in_the_clouds")
        return { vars = { num, den } }
    end,
    calculate = function(self, card, context)
        if context.level_up_hand and context.level_up_hand ~= "Head in the Clouds"
            and not (G and G._buncp_head_leveling) then
            if SMODS.pseudorandom_probability(card, "buncp_head_in_the_clouds", 1, card.ability.extra.odds) then
                if G and G.handlist and G.upgrade_hand_level_at_index then
                    for i, name in ipairs(G.handlist) do
                        if name == "High Card" then
                            G._buncp_head_leveling = true
                            G:upgrade_hand_level_at_index(i)
                            G._buncp_head_leveling = false
                            return { message = "Upgrade!" }
                        end
                    end
                end
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- v1.4.0: Wave 5 top-ups, on the fork's Wave 5 seats. Gameplan and
-- Conquest ride the mod Joker debuff (SMODS.set_joker_debuff); Myopia and
-- Astigmatism are pure suit_aliases declarations; Sledgehammer, Dwarven
-- and Metallurgist are pure center_overrides declarations. Everything
-- below needs the fork's Wave 5 mod API.
--------------------------------------------------------------------------------

--- Is `j` a held Gameplan? (Def id check; the row holds instances.)
local function buncp_is_gameplan(j)
    return j and j.def and j.def.id == "j_buncp_gameplan"
end

--- The Jokers currently debuffed BY a Gameplan (weak keys: a Joker that
--- leaves play drops out on its own). PC derives Gameplan's debuff from
--- position inside its global set_debuff predicate, re-evaluated every
--- frame; the fork's debuff is a stored flag, so the pack re-derives it
--- at every sync point instead (see buncp_sync_gameplans). Tracking
--- which debuffs are Gameplan's own keeps the sync from ever lifting a
--- debuff another source (Conquest, a boss, a sticker) put there.
local buncp_gameplan_claims = setmetatable({}, { __mode = "k" })

--- Re-derive every Gameplan debuff from the current row, PC-style: a
--- Joker is debuffed when an immediate neighbour is a Gameplan that is
--- not itself debuffed (through any channel). Called from Gameplan's
--- add_to_deck / remove_from_deck and its calculate at setting_blind,
--- before, card_added and joker_debuffed, and from Conquest after it
--- moves its own victim, which covers every way the row or a debuff
--- state can change while the pack is in play. One honest residue: if
--- Gameplan itself is debuffed while its neighbours are claimed, no
--- sync runs until the next sync point, because a debuffed Joker hears
--- no contexts -- PC's per-frame predicate lifts them instantly.
local function buncp_sync_gameplans()
    if not (G and G.jokers and SMODS and SMODS.set_joker_debuff) then return end
    local desired = {}
    for i, j in ipairs(G.jokers) do
        if buncp_is_gameplan(j) and not SMODS.joker_debuffed(j) then
            for _, nb in ipairs({ G.jokers[i - 1], G.jokers[i + 1] }) do
                if nb then desired[nb] = true end
            end
        end
    end
    for j in pairs(buncp_gameplan_claims) do
        if not desired[j] then
            buncp_gameplan_claims[j] = nil
            SMODS.set_joker_debuff(j, false)
        end
    end
    for j in pairs(desired) do
        if not buncp_gameplan_claims[j] and not j.mod_debuffed then
            SMODS.set_joker_debuff(j, true)
            if j.mod_debuffed then buncp_gameplan_claims[j] = true end
        end
    end
end

--------------------------------------------------------------------------------
-- Gameplan: Jokers next to this one are debuffed, and each neighbour
-- gives +20 Mult. PC has no debuff code in the Joker at all: Bunco's
-- global set_debuff predicate debuffs any Joker whose neighbour is a
-- non-debuffed Gameplan, and Gameplan's update()/remove() hooks just
-- ask the blind to re-evaluate every Joker. The port re-derives the
-- same state with buncp_sync_gameplans above. Gameplan's own scoring
-- is its joker_main: +20 Mult per neighbour that exists, debuffed or
-- not, exactly as PC counts the slots.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "gameplan",
    loc_txt = {
        name = "Gameplan",
        text = {
            "{C:attention}Jokers{} next to this Joker",
            "are {C:red}debuffed{} and",
            "give {C:mult}+#1#{} Mult",
        },
    },
    config = { extra = { mult = 20 } },
    rarity = 2,
    cost = 5,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "gameplan.png",
    negative_sprite = "gameplan_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult } }
    end,
    add_to_deck = function(self, card)
        buncp_sync_gameplans()
    end,
    remove_from_deck = function(self, card)
        buncp_sync_gameplans()
    end,
    calculate = function(self, card, context)
        if not context.blueprint and (context.setting_blind or context.before
            or context.card_added or context.joker_debuffed) then
            buncp_sync_gameplans()
        end
        if context.joker_main then
            local my_pos = nil
            for i, j in ipairs((G and G.jokers) or {}) do
                if j == card then my_pos = i break end
            end
            if not my_pos then return end
            local mult = 0
            if G.jokers[my_pos - 1] then mult = mult + card.ability.extra.mult end
            if G.jokers[my_pos + 1] then mult = mult + card.ability.extra.mult end
            if mult ~= 0 then return { mult = mult } end
        end
    end,
}

--------------------------------------------------------------------------------
-- Conquest: +200 Chips; when a Blind is selected, debuffs a random
-- other Joker. PC picks the victim in its setting_blind calculate
-- (never under Blueprint) and stores the Joker object in
-- ability.extra.joker; Bunco's set_debuff predicate then debuffs
-- whatever Joker that field points at, so the victim stays down until
-- the next Blind re-picks or Conquest leaves. The port keeps the same
-- shape on the fork's stored flag: the pick is applied with
-- SMODS.set_joker_debuff at setting_blind (the seat the fork designs
-- the debuff_joker return for, called directly so the previous victim
-- can be lifted in the same pass), and the victim is tracked in a
-- runtime map, not ability, so no live Joker reference ever enters a
-- save (the debuff flag itself saves on the victim, as the fork has
-- it). PC's pick is math.random; the port's is the run's seeded
-- pseudorandom, the pack's usual surface.
--------------------------------------------------------------------------------

local buncp_conquest_victims = setmetatable({}, { __mode = "k" })

local function buncp_conquest_lift(card)
    local victim = buncp_conquest_victims[card]
    buncp_conquest_victims[card] = nil
    if victim and victim.mod_debuffed then
        SMODS.set_joker_debuff(victim, false)
    end
end

SMODS.Joker {
    key = "conquest",
    loc_txt = {
        name = "Conquest",
        text = {
            "{C:chips}+#1#{} Chips,",
            "{C:red}debuffs{} random Joker",
            "when {C:attention}Blind{} is selected",
        },
    },
    config = { extra = { chips = 200 } },
    rarity = 2,
    cost = 5,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "conquest.png",
    negative_sprite = "conquest_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chips } }
    end,
    remove_from_deck = function(self, card)
        buncp_conquest_lift(card)
        buncp_sync_gameplans()
    end,
    calculate = function(self, card, context)
        if context.setting_blind and not context.blueprint then
            buncp_conquest_lift(card)
            local targets = {}
            for _, j in ipairs((G and G.jokers) or {}) do
                if j ~= card then targets[#targets + 1] = j end
            end
            if #targets > 0 then
                local victim = targets[SMODS.pseudorandom("buncp_conquest", 1, #targets)]
                buncp_conquest_victims[card] = victim
                SMODS.set_joker_debuff(victim, true)
                buncp_sync_gameplans()
                return { message = "Debuffed!" }
            end
            buncp_sync_gameplans()
        end
        if context.joker_main then
            return { chips = card.ability.extra.chips }
        end
    end,
}

--------------------------------------------------------------------------------
-- Myopia / Astigmatism: no calculate at all, on PC or here. PC patches
-- Card:is_suit globally (Lovely): while a non-debuffed copy is held,
-- Spades and Clubs also count as Halberds (Myopia), Hearts and Diamonds
-- also count as Fleurons (Astigmatism). The fork's suit_aliases field
-- is that patch at its single is_suit choke, derived from the held row
-- on every check, so selling or debuffing the Joker ends the alias
-- with no cleanup. Both are Exotic Jokers on PC, so the pack's exotic
-- pool gate applies. One honest limit, the fork's own: hand-type Flush
-- grouping reads suits directly, not through is_suit, so the alias
-- does not forge Flushes out of mixed printed suits (on PC the global
-- patch sits inside Card:is_suit, which PC's flush grouping also
-- consults, so a Spades/Clubs mix can flush as Halberds there).
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "myopia",
    loc_txt = {
        name = "Myopia",
        text = {
            "{C:attention}Spades{} and {C:attention}Clubs{}",
            "count as {C:attention}Halberds{}",
        },
    },
    config = { extra = {} },
    rarity = 2,
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    in_pool = buncp_exotic_pool,
    sprite = "myopia.png",
    negative_sprite = "myopia_negative.png",
    suit_aliases = { Spades = "Halberds", Clubs = "Halberds" },
}

SMODS.Joker {
    key = "astigmatism",
    loc_txt = {
        name = "Astigmatism",
        text = {
            "{C:attention}Hearts{} and {C:attention}Diamonds{}",
            "count as {C:attention}Fleurons{}",
        },
    },
    config = { extra = {} },
    rarity = 2,
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    in_pool = buncp_exotic_pool,
    sprite = "astigmatism.png",
    negative_sprite = "astigmatism_negative.png",
    suit_aliases = { Hearts = "Fleurons", Diamonds = "Fleurons" },
}

--------------------------------------------------------------------------------
-- The center-override trio. PC implements all three with add/remove
-- hooks that rewrite a vanilla center's config (and patch every live
-- card to match); the fork never materialised a per-card copy, so the
-- same numbers are declared as center_overrides and folded over the
-- base config at every read, reversible by construction. All three
-- also carry PC's custom_in_pool gate: the Joker only appears while
-- your deck holds a card of its enhancement.
--------------------------------------------------------------------------------

local function buncp_deck_has_enhancement(enhancement)
    for _, data in ipairs(buncp_full_deck_data()) do
        if data.enhancement == enhancement then return true end
    end
    return false
end

--------------------------------------------------------------------------------
-- Sledgehammer: Glass Cards give +X1 Mult per held copy, but the break
-- odds denominator is divided by 4 (4 -> 1: guaranteed to break, as
-- PC's text says) once, no matter how many copies are held. PC's add
-- hook adds plus_xmult unconditionally and divides extra only when it
-- is the first Sledgehammer in the row (its find_card guard), and its
-- remove hook mirrors that; the fork's ops say the same thing
-- directly: add per copy, divide with once = true. PC also re-applies
-- the pair from Game:start_run for loaded runs; the fork's read-time
-- fold needs no re-application.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "sledgehammer",
    loc_txt = {
        name = "Sledgehammer",
        text = {
            "{C:attention}Glass Cards{} give +{X:mult,C:white}X#1#{} Mult",
            "but are guaranteed to break",
        },
    },
    config = { extra = { plus_xmult = 1, div_chance_denom = 4 } },
    rarity = 2,
    cost = 5,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    in_pool = function(self, args) return buncp_deck_has_enhancement("glass") end,
    sprite = "sledgehammer.png",
    negative_sprite = "sledgehammer_negative.png",
    center_overrides = {
        { center = "m_glass", field = "Xmult", add = 1 },
        { center = "m_glass", field = "extra", divide = 4, once = true },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.plus_xmult } }
    end,
}

--------------------------------------------------------------------------------
-- Dwarven: Stone Cards held in hand have the abilities of Steel and
-- Gold Cards: Stone gains Steel's h_x_mult (X1.5) and Gold's h_dollars
-- ($3), lent with add_from, which reads the other centers' BASE
-- values. PC's add hook lends both values once per held copy (two
-- Dwarvens lend double), so the entries are per-copy here too, no
-- once flag. Stone's own +50 Chips when played is untouched, and the
-- lent fields only wake Stone's held / round-end readers while an
-- override supplies them (the fork's reader wiring).
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "dwarven",
    loc_txt = {
        name = "Dwarven Joker",
        text = {
            "{C:attention}Stone Cards{} held in hand",
            "have the abilities of",
            "{C:attention}Steel{} and {C:attention}Gold Cards{}",
        },
    },
    config = { extra = {} },
    rarity = 2,
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    in_pool = function(self, args) return buncp_deck_has_enhancement("stone") end,
    sprite = "dwarven.png",
    negative_sprite = "dwarven_negative.png",
    center_overrides = {
        { center = "m_stone", field = "h_x_mult", add_from = { center = "m_steel", field = "h_x_mult" } },
        { center = "m_stone", field = "h_dollars", add_from = { center = "m_gold", field = "h_dollars" } },
    },
}

--------------------------------------------------------------------------------
-- Metallurgist: Gold Cards give +10 Mult while held in hand, per held
-- copy. PC's add hook writes h_mult onto the Gold center config (its
-- per-card patch of already-dealt Gold cards starts them at 0 -- a PC
-- quirk the read-time fold does not reproduce: here every held Gold
-- card pays, dealt before or after). Gold's own $3 at round end is
-- untouched.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "metallurgist",
    loc_txt = {
        name = "Metallurgist",
        text = {
            "{C:attention}Gold Cards{} give {C:mult}+#1#{} Mult",
            "while held in hand",
        },
    },
    config = { extra = { mult = 10 } },
    rarity = 1,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    in_pool = function(self, args) return buncp_deck_has_enhancement("gold") end,
    sprite = "metallurgist.png",
    negative_sprite = "metallurgist_negative.png",
    center_overrides = {
        { center = "m_gold", field = "h_mult", add = 10 },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult } }
    end,
}
