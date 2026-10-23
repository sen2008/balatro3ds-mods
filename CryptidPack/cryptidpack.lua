--[[
    CryptidPack - Cryptid content ported to Balatro3DS.

    140 Jokers and 22 consumables ported from Cryptid by the Cryptid
    team / SpectralPack (PC / Steamodded + Talisman, GPLv3, source
    v0.5.17c). Requires the Balatro3DS fork build
    (https://github.com/sen2008/balatro3ds-fork): custom rarities,
    SMODS.PokerHand, SMODS.ConsumableType, create/destroy and
    retrigger returns are fork features.

    Port notes:
      * The Talisman bignum wrapper (lenient_bignum / to_big) is
        stripped wherever the values are ordinary numbers. Jokers
        whose effects need Talisman values (e_mult / ee_mult /
        e_chips returns, 1e100+ stats, exponent-scaling) are NOT in
        this pack; neither are Jokers bound to systems the fork does
        not have (Cryptid editions, enhancements, seals, tags,
        stickers, code-program state). Every unported item is listed
        with its exact blocker in README.txt.
      * Cryptid's "gameset" system (modest / mainline / madness) is
        dropped: every item ships with its plain (mainline) config
        and text, and content gates on gamesets are removed.
      * Dubious and Absurd pay on every hand, exactly as on PC: every
        played hand "contains a High Card" there.
      * Descriptions are Cryptid's en-us text with hand types inlined
        and markup reduced to the colours the port supports.
]]

--------------------------------------------------------------------------------
-- Registrations: Cryptid's rarities (SMODS.Rarity), its two registerable
-- poker hands (SMODS.PokerHand) and the Code consumable type
-- (SMODS.ConsumableType). Guarded so the pack also loads its original
-- seven Jokers on the stock game, where these registries do not exist.
--
-- Rarity weights are fork shop units (Common 70 / Uncommon 25 / Rare 5):
--   epic   0.3  -- PC gives Epic a 0.3% share of rarity rolls.
--   exotic 0    -- PC keeps Exotic out of the shop pool entirely; they
--                  arrive via Gateway / Summoning creation, as here.
--   candy  3    -- PC leaves Candy at the Steamodded custom default.
--   cursed 3    -- PC leaves Cursed at the Steamodded custom default.
-- Badge colours are Cryptid's own (lib/content.lua).
--------------------------------------------------------------------------------

if SMODS.Rarity then
    if not SMODS.Rarities["cryp_epic"] then
        SMODS.Rarity { key = "epic", loc_txt = { name = "Epic" }, badge_colour = "#ef0098", weight = 0.3 }
    end
    if not SMODS.Rarities["cryp_exotic"] then
        SMODS.Rarity { key = "exotic", loc_txt = { name = "Exotic" }, badge_colour = "#aa76e8", weight = 0 }
    end
    if not SMODS.Rarities["cryp_candy"] then
        SMODS.Rarity { key = "candy", loc_txt = { name = "Candy" }, badge_colour = "#e275e6", weight = 3 }
    end
    if not SMODS.Rarities["cryp_cursed"] then
        SMODS.Rarity { key = "cursed", loc_txt = { name = "Cursed" }, badge_colour = "#474931", weight = 3 }
    end
end

if SMODS.PokerHand then
    local function cryp_hand_registered(key)
        for _, h in ipairs(SMODS.PokerHands or {}) do
            if h.key == key then return true end
        end
        return false
    end
    -- Bulwark: five Stone cards. The fork's own evaluator already
    -- treats Stone cards as rankless/suitless, exactly PC's rule.
    if not cryp_hand_registered("Bulwark") then
        SMODS.PokerHand {
            key = "Bulwark",
            loc_txt = { name = "Bulwark", text = { "5 Stone cards" } },
            chips = 100, mult = 10, l_chips = 50, l_mult = 1,
            order = 115,
            visible = false,
            evaluate = function(self, hand)
                local stones = {}
                for _, c in ipairs(hand) do
                    if c.enhancement == "stone" then stones[#stones + 1] = c end
                end
                if #stones >= 5 then return stones end
                return nil
            end,
        }
    end
    -- UltPair: pairs that share a suit, in at least two suits, at
    -- least four such pairs (PC's evaluate, parts._2 rewritten over
    -- card views; Stone cards have no rank and never pair).
    if not cryp_hand_registered("UltPair") then
        SMODS.PokerHand {
            key = "UltPair",
            loc_txt = { name = "UltPair", text = { "4+ pairs, each pair sharing a suit,", "across 2+ suits" } },
            chips = 220, mult = 22, l_chips = 40, l_mult = 4,
            order = 118,
            visible = false,
            evaluate = function(self, hand)
                local by_rank = {}
                for _, c in ipairs(hand) do
                    if c.enhancement ~= "stone" then
                        local id = c:get_id()
                        if id then
                            by_rank[id] = by_rank[id] or {}
                            by_rank[id][#by_rank[id] + 1] = c
                        end
                    end
                end
                local pairs_ = {}
                for _, group in pairs(by_rank) do
                    for i = 1, #group - 1, 2 do
                        pairs_[#pairs_ + 1] = { group[i], group[i + 1] }
                    end
                end
                if #pairs_ < 4 then return nil end
                local suits = { "Hearts", "Diamonds", "Clubs", "Spades" }
                local seen = {}
                for _, pr in ipairs(pairs_) do
                    for _, c in ipairs(pr) do
                        if c.base and c.base.suit and not seen[c.base.suit] then
                            seen[c.base.suit] = true
                            suits[#suits + 1] = c.base.suit
                        end
                    end
                end
                local scoring_pairs, unique_suits = {}, 0
                for _, suit in ipairs(suits) do
                    local in_suit = {}
                    for i, pr in ipairs(pairs_) do
                        if pr[1]:is_suit(suit) and pr[2]:is_suit(suit) then
                            in_suit[#in_suit + 1] = i
                        end
                    end
                    if #in_suit >= 2 then
                        unique_suits = unique_suits + 1
                        for _, i in ipairs(in_suit) do
                            scoring_pairs[i] = (scoring_pairs[i] or 0) + 1
                        end
                    end
                end
                if unique_suits < 2 then return nil end
                local scored, sc_max, sc_unique = {}, 0, 0
                for i, pr in ipairs(pairs_) do
                    if scoring_pairs[i] then
                        if scoring_pairs[i] > 1 then sc_unique = sc_unique + 1 end
                        sc_max = math.max(sc_max, scoring_pairs[i])
                        scored[#scored + 1] = pr[1]
                        scored[#scored + 1] = pr[2]
                    end
                end
                if sc_max == #scored / 2 - 1 and sc_unique == 1 then return nil end
                if #scored >= 8 then return scored end
                return nil
            end,
        }
    end
end

if SMODS.ConsumableType then
    -- Code: PC shop_rate is 0.0 (Code cards arrive via packs and
    -- effects there); the fork has no Code packs, so a small shop
    -- rate is the only way the two ported Code cards can appear.
    if not (SMODS.ConsumableKinds and SMODS.ConsumableKinds["Code"]) then
        SMODS.ConsumableType { key = "Code", loc_txt = { name = "Code" }, shop_rate = 1 }
    end
    if not (SMODS.ConsumableKinds and SMODS.ConsumableKinds["Unique"]) then
        SMODS.ConsumableType { key = "Unique", loc_txt = { name = "Unique" }, shop_rate = 0 }
    end
end


--------------------------------------------------------------------------------
-- The original seven (2026-10-20 first-pass port)
--------------------------------------------------------------------------------

----

SMODS.Joker {
    key = "dubious",
    loc_txt = {
        name = "Dubious Joker",
        text = {
            "{C:chips}+#1#{} Chips if played",
            "hand contains",
            "a {C:attention}High Card{}",
        },
    },
    config = { extra = { chips = 20 } },
    rarity = 1,
    cost = 1,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "dubious.png",
    negative_sprite = "dubious_negative.png",
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
-- Absurd Joker: +4 Mult (High Card; see header note).
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "absurd",
    loc_txt = {
        name = "Absurd Joker",
        text = {
            "{C:mult}+#1#{} Mult if played",
            "hand contains",
            "a {C:attention}High Card{}",
        },
    },
    config = { extra = { mult = 4 } },
    rarity = 1,
    cost = 1,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "absurd.png",
    negative_sprite = "absurd_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            return { mult = card.ability.extra.mult }
        end
    end,
}

--------------------------------------------------------------------------------
-- Shrewd Joker: +150 Chips if the played hand contains a Four of a Kind.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "shrewd",
    loc_txt = {
        name = "Shrewd Joker",
        text = {
            "{C:chips}+#1#{} Chips if played",
            "hand contains",
            "a {C:attention}Four of a Kind{}",
        },
    },
    config = { extra = { chips = 150 } },
    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "shrewd.png",
    negative_sprite = "shrewd_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chips } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            if context.poker_hands and next(context.poker_hands["Four of a Kind"]) then
                return { chips = card.ability.extra.chips }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Nutty Joker: +19 Mult if the played hand contains a Four of a Kind.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "nutty",
    loc_txt = {
        name = "Nutty Joker",
        text = {
            "{C:mult}+#1#{} Mult if played",
            "hand contains",
            "a {C:attention}Four of a Kind{}",
        },
    },
    config = { extra = { mult = 19 } },
    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "nutty.png",
    negative_sprite = "nutty_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            if context.poker_hands and next(context.poker_hands["Four of a Kind"]) then
                return { mult = card.ability.extra.mult }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- The Duos: X2.5 Mult if the played hand contains a Two Pair (a Full
-- House contains one too, as on PC).
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "the_duos",
    loc_txt = {
        name = "The Duos",
        text = {
            "{X:mult,C:white} X#1# {} Mult if played",
            "hand contains",
            "a {C:attention}Two Pair{}",
        },
    },
    config = { extra = { xmult = 2.5 } },
    rarity = 3,
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "the_duos.png",
    negative_sprite = "the_duos_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.xmult } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            if context.poker_hands and next(context.poker_hands["Two Pair"]) then
                return { xmult = card.ability.extra.xmult }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- The Home: X3.5 Mult if the played hand contains a Full House.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "the_home",
    loc_txt = {
        name = "The Home",
        text = {
            "{X:mult,C:white} X#1# {} Mult if played",
            "hand contains",
            "a {C:attention}Full House{}",
        },
    },
    config = { extra = { xmult = 3.5 } },
    rarity = 3,
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "the_home.png",
    negative_sprite = "the_home_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.xmult } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            if context.poker_hands and next(context.poker_hands["Full House"]) then
                return { xmult = card.ability.extra.xmult }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Triplet Rhythm: X3 Mult if the scoring hand contains exactly three 3s.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "triplet_rhythm",
    loc_txt = {
        name = "Triplet Rhythm",
        text = {
            "{X:mult,C:white} X#1# {} Mult if scoring hand",
            "contains {C:attention}exactly{} three {C:attention}3s{}",
        },
    },
    config = { extra = { xmult = 3 } },
    rarity = 1,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "triplet_rhythm.png",
    negative_sprite = "triplet_rhythm_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.xmult } }
    end,
    calculate = function(self, card, context)
        if context.joker_main and context.scoring_hand then
            local threes = 0
            for _, c in ipairs(context.scoring_hand) do
                if c:get_id() == 3 then threes = threes + 1 end
            end
            if threes == 3 then
                return { xmult = card.ability.extra.xmult }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Dropshot: gains X0.2 Mult for each played, nonscoring card of a target
-- suit; the suit changes every round.
-- PORT NOTE: PC keeps the target suit in G.GAME.current_round (set by a
-- reset_game_globals override from a random deck card's suit). The fork
-- has no round-reset hook, so the suit is stored on the Joker and re-rolled
-- from the full deck's suits at setting_blind and end_of_round (the Find
-- Jimbo pattern). PC's juice events are dropped.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "dropshot",
    loc_txt = {
        name = "Dropshot",
        text = {
            "This Joker gains {X:mult,C:white} X#1# {} Mult for",
            "each played, {C:attention}nonscoring{} #2# card,",
            "suit changes every round",
            "{C:inactive}(Currently {X:mult,C:white} X#3# {C:inactive} Mult)",
        },
    },
    config = { extra = { Xmult_mod = 0.2, x_mult = 1, target_suit = "Spades" } },
    rarity = 3,
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    sprite = "dropshot.png",
    negative_sprite = "dropshot_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.Xmult_mod, card.ability.extra.target_suit, card.ability.extra.x_mult } }
    end,
    calculate = function(self, card, context)
        local extra = card.ability.extra
        if context.setting_blind or context.end_of_round then
            local suits = {}
            local function add_all(list)
                for _, data in ipairs(type(list) == "table" and list or {}) do
                    if type(data) == "table" and data.suit and data.enhancement ~= "stone" then
                        suits[#suits + 1] = data.suit
                    end
                end
            end
            if G and G.deck then
                add_all(G.deck.cards)
                add_all(G.deck.discard_pile)
            end
            if G and G.hand then add_all(G.hand.cards) end
            if #suits > 0 then
                extra.target_suit = suits[SMODS.pseudorandom("cryp_dropshot", 1, #suits)]
            end
        end
        if context.before and not context.blueprint and context.full_hand then
            local scoring = {}
            for _, c in ipairs(context.scoring_hand or {}) do
                if c.card_data then scoring[c.card_data] = true end
            end
            local count = 0
            for _, c in ipairs(context.full_hand) do
                if not (c.card_data and scoring[c.card_data]) and c:is_suit(extra.target_suit) then
                    count = count + 1
                end
            end
            if count > 0 then
                extra.x_mult = extra.x_mult + extra.Xmult_mod * count
                return { message = "Upgrade!" }
            end
        end
        if context.joker_main and extra.x_mult > 1 then
            return { xmult = extra.x_mult }
        end
    end,
}

--------------------------------------------------------------------------------
-- Pot of Jokes: -2 hand size, increases by 1 every round (max 1000).
-- PORT NOTE: PC drives G.hand:change_size imperatively; the fork recomputes
-- hand size from the declarative h_size modifier on the ability, so the
-- growing value is kept in sync at end_of_round (the Cast Iron pattern).
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "pot_of_jokes",
    loc_txt = {
        name = "Pot of Jokes",
        text = {
            "{C:attention}#1#{} hand size,",
            "increases by",
            "{C:attention}#2#{} every round",
            "{C:inactive}(Maximum {C:attention}#3#{C:inactive} hand size)",
        },
    },
    config = { h_size = -2, extra = { h_size = -2, h_mod = 1, h_max = 1000 } },
    rarity = 3,
    cost = 10,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = false,
    sprite = "pot_of_jokes.png",
    negative_sprite = "pot_of_jokes_negative.png",
    loc_vars = function(self, info_queue, card)
        local h = card.ability.extra.h_size
        return { vars = { h < 0 and h or "+" .. h, card.ability.extra.h_mod, "+" .. card.ability.extra.h_max } }
    end,
    calculate = function(self, card, context)
        if context.end_of_round and not context.blueprint then
            local extra = card.ability.extra
            extra.h_size = math.min(extra.h_max, extra.h_size + extra.h_mod)
            card.ability.h_size = extra.h_size
            return { message = "Upgrade!" }
        end
    end,
}

--------------------------------------------------------------------------------
-- Weebonacci: gains +3 Mult when each played Ace, 2, 3, 5 or 8 is scored.
-- PORT NOTE: PC chunk declares no atlas (pos 1,5 collides with other
-- sheets' cells); sprite name follows the pack convention regardless.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "wee_fib",
    loc_txt = {
        name = "Weebonacci",
        text = {
            "This Joker gains",
            "{C:mult}+#2#{} Mult when each played",
            "{C:attention}Ace{}, {C:attention}2{}, {C:attention}3{}, {C:attention}5{}, or {C:attention}8{}",
            "is scored",
            "{C:inactive}(Currently {C:mult}+#1#{C:inactive} Mult)",
        },
    },
    config = { extra = { mult = 0, mult_mod = 3 } },
    rarity = 3,
    cost = 9,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    sprite = "wee_fib.png",
    negative_sprite = "wee_fib_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult, card.ability.extra.mult_mod } }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play and not context.blueprint and context.other_card then
            local rank = context.other_card:get_id()
            if rank == 14 or rank == 2 or rank == 3 or rank == 5 or rank == 8 then
                card.ability.extra.mult = card.ability.extra.mult + card.ability.extra.mult_mod
                return { message = "Upgrade!" }
            end
        end
        if context.joker_main and card.ability.extra.mult > 0 then
            return { mult = card.ability.extra.mult }
        end
    end,
}

--------------------------------------------------------------------------------
-- The WHIP: gains X0.5 Mult if the played hand contains a 2 and a 7 of
-- different suits.
-- PORT NOTE: PC iterates SMODS.Suits (every registered suit); the fork
-- check uses the four vanilla suits, which is every suit in this pack.
-- Wild cards count as all suits via the fork's is_suit, as on PC.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "whip",
    loc_txt = {
        name = "The WHIP",
        text = {
            "This Joker gains {X:mult,C:white} X#1# {} Mult",
            "if {C:attention}played hand{} contains a",
            "{C:attention}2{} and {C:attention}7{} of different suits",
            "{C:inactive}(Currently {X:mult,C:white} X#2# {C:inactive} Mult)",
        },
    },
    config = { extra = { Xmult_mod = 0.5, x_mult = 1 } },
    rarity = 2,
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    sprite = "whip.png",
    negative_sprite = "whip_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.Xmult_mod, card.ability.extra.x_mult } }
    end,
    calculate = function(self, card, context)
        if context.before and not context.blueprint and context.full_hand then
            local suits = { "Hearts", "Clubs", "Diamonds", "Spades" }
            local two_suits, seven_suits = {}, {}
            local function collect(card_view, set)
                for _, s in ipairs(suits) do
                    if card_view:is_suit(s) then set[s] = true end
                end
            end
            local function count(set)
                local n = 0
                for _ in pairs(set) do n = n + 1 end
                return n
            end
            for _, c in ipairs(context.full_hand) do
                local id = c:get_id()
                if id == 2 then collect(c, two_suits) end
                if id == 7 then collect(c, seven_suits) end
            end
            local nt, ns = count(two_suits), count(seven_suits)
            local different = false
            if nt > 0 and ns > 0 then
                if nt > 1 or ns > 1 then
                    different = true
                else
                    for s in pairs(two_suits) do
                        if not seven_suits[s] then different = true end
                    end
                end
            end
            if different then
                card.ability.extra.x_mult = card.ability.extra.x_mult + card.ability.extra.Xmult_mod
                return { message = "Upgrade!" }
            end
        end
        if context.joker_main and card.ability.extra.x_mult > 1 then
            return { xmult = card.ability.extra.x_mult }
        end
    end,
}

--------------------------------------------------------------------------------
-- Cursor: gains +8 Chips for each card purchased.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "cursor",
    loc_txt = {
        name = "Cursor",
        text = {
            "This Joker gains {C:chips}+#2#{} Chips",
            "for each card {C:attention}purchased{}",
            "{C:inactive}(Currently {C:chips}+#1#{C:inactive} Chips)",
        },
    },
    config = { extra = { chips = 0, chip_mod = 8 } },
    rarity = 1,
    cost = 5,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    sprite = "cursor.png",
    negative_sprite = "cursor_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chips, card.ability.extra.chip_mod } }
    end,
    calculate = function(self, card, context)
        if context.buying_card and not context.blueprint and context.card ~= card then
            card.ability.extra.chips = card.ability.extra.chips + card.ability.extra.chip_mod
            return { message = "Upgrade!" }
        end
        if context.joker_main and card.ability.extra.chips > 0 then
            return { chips = card.ability.extra.chips }
        end
    end,
}

--------------------------------------------------------------------------------
-- Cube: +6 Chips.
-- PORT NOTE: PC cost is -27 (a Meme-pool joke price; the shop pays you).
-- The fork requires cost >= 0, so it is free here instead.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "cube",
    loc_txt = {
        name = "Cube",
        text = {
            "{C:chips}+#1#{} Chips",
        },
    },
    config = { extra = { chips = 6 } },
    rarity = 1,
    cost = 0,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "cube.png",
    negative_sprite = "cube_negative.png",
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
-- Chili Pepper: gains X0.5 Mult at end of round, self destructs after
-- 8 rounds.
-- PORT NOTE: PC removes itself through an event-manager dissolve; the
-- fork uses SMODS.destroy_joker at the same end_of_round beat (the
-- Champagne pattern).
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "chili_pepper",
    loc_txt = {
        name = "Chili Pepper",
        text = {
            "This Joker gains {X:mult,C:white} X#2# {} Mult",
            "at end of round,",
            "{C:red}self destructs{} after {C:attention}#3#{} rounds",
            "{C:inactive}(Currently {X:mult,C:white} X#1# {C:inactive} Mult)",
        },
    },
    config = { extra = { Xmult = 1, Xmult_mod = 0.5, rounds_remaining = 8 } },
    rarity = 2,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = false,
    perishable_compat = false,
    sprite = "chili_pepper.png",
    negative_sprite = "chili_pepper_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.Xmult, card.ability.extra.Xmult_mod, card.ability.extra.rounds_remaining } }
    end,
    calculate = function(self, card, context)
        if context.joker_main and card.ability.extra.Xmult > 1 then
            return { xmult = card.ability.extra.Xmult }
        end
        if context.end_of_round and not context.blueprint and not context.retrigger_joker then
            local extra = card.ability.extra
            extra.rounds_remaining = extra.rounds_remaining - 1
            extra.Xmult = extra.Xmult + extra.Xmult_mod
            if extra.rounds_remaining > 0 then
                return { message = "X" .. extra.Xmult .. " Mult" }
            end
            SMODS.destroy_joker(card)
            return { message = "Eaten!" }
        end
    end,
}

--------------------------------------------------------------------------------
-- Compound Interest: earn 12% of total money at end of round, percent
-- increases by 3% per payout.
-- PORT NOTE: PC reads G.GAME.dollars; the fork's money is G.money.
-- PC scales the percent on every payout call with money > 0, even when
-- the floored bonus is 0; kept.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "compound_interest",
    loc_txt = {
        name = "Compound Interest",
        text = {
            "Earn {C:money}#1#%{} of total money",
            "at end of round,",
            "increases by {C:money}#2#%{} per",
            "consecutive payout",
        },
    },
    config = { extra = { percent_mod = 3, percent = 12 } },
    rarity = 3,
    cost = 10,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = false,
    sprite = "compound_interest.png",
    negative_sprite = "compound_interest_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.percent, card.ability.extra.percent_mod } }
    end,
    calc_dollar_bonus = function(self, card)
        local money = (G and tonumber(G.money)) or 0
        if money > 0 then
            local bonus = math.floor(0.01 * card.ability.extra.percent * money)
            card.ability.extra.percent = card.ability.extra.percent + card.ability.extra.percent_mod
            return bonus
        end
        return 0
    end,
}

--------------------------------------------------------------------------------
-- Eternal Flame: gains X0.1 Mult for each card sold.
-- PORT NOTE: this is PC's mainline (eternalflame2) text and behaviour:
-- the PC calculate's gameset check makes the $3 sell-value floor
-- modest-only, so on mainline every sold card counts. The fork's
-- selling_card context fires for sold Jokers and consumables, as PC's.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "eternalflame",
    loc_txt = {
        name = "Eternal Flame",
        text = {
            "This Joker gains {X:mult,C:white} X#1# {} Mult",
            "for each card {C:attention}sold{}",
            "{C:inactive}(Currently {X:mult,C:white} X#2# {C:inactive} Mult)",
        },
    },
    config = { extra = { extra = 0.1, x_mult = 1 } },
    rarity = 3,
    cost = 9,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    sprite = "eternalflame.png",
    negative_sprite = "eternalflame_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.extra, card.ability.extra.x_mult } }
    end,
    calculate = function(self, card, context)
        if context.joker_main and card.ability.extra.x_mult > 1 then
            return { xmult = card.ability.extra.x_mult }
        end
        if context.selling_card and not context.blueprint then
            card.ability.extra.x_mult = card.ability.extra.x_mult + card.ability.extra.extra
            return { message = "Upgrade!" }
        end
    end,
}

--------------------------------------------------------------------------------
-- Nice: +420 Chips if the played hand contains a 6 and a 9.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "nice",
    loc_txt = {
        name = "Nice",
        text = {
            "{C:chips}+#1#{} Chips if played hand",
            "contains a {C:attention}6{} and a {C:attention}9{}",
            "{C:inactive}Nice.{}",
        },
    },
    config = { extra = { chips = 420 } },
    rarity = 3,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "nice.png",
    negative_sprite = "nice_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chips } }
    end,
    calculate = function(self, card, context)
        if context.joker_main and context.full_hand then
            local has_six, has_nine = false, false
            for _, c in ipairs(context.full_hand) do
                local id = c:get_id()
                if id == 6 then has_six = true end
                if id == 9 then has_nine = true end
            end
            if has_six and has_nine then
                return { chips = card.ability.extra.chips }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Seal the Deal: add a random seal to each card scored on the final hand
-- of the round.
-- PORT NOTE: PC picks from every seal via SMODS.poll_seal, including the
-- Cryptid-only Green and Azure seals, which cannot exist here; the pool
-- is the four vanilla seals, written to card_data.seal (the Paperback
-- pattern). "Final hand" is the fork's hands-remaining counter G.hands
-- hitting 0; the Panopticon branch checks the held-Joker list for
-- j_cryp_panopticon instead of SMODS.find_card. PC's sprite-variant
-- set_ability (art chosen by a random seal name) is dropped: one sprite
-- per card here.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "seal_the_deal",
    loc_txt = {
        name = "Seal the Deal",
        text = {
            "Add a {C:attention}random seal{} to each card",
            "scored on {C:attention}final hand{} of round",
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
    sprite = "seal_the_deal.png",
    negative_sprite = "seal_the_deal_negative.png",
    calculate = function(self, card, context)
        if context.after and not context.blueprint and not context.retrigger_joker and context.scoring_hand then
            local final = (G and tonumber(G.hands) or 1) <= 0
            if not final and G and G.jokers then
                for _, j in ipairs(G.jokers) do
                    if j.def and j.def.id == "j_cryp_panopticon" then
                        final = true
                        break
                    end
                end
            end
            if not final then return end
            local seals = { "gold", "red", "blue", "purple" }
            local sealed_any = false
            for _, view in ipairs(context.scoring_hand) do
                local data = view.card_data
                if data and not data.seal then
                    data.seal = SMODS.pseudorandom_element(seals, "cryp_seal_the_deal")
                    if view.sync_visual_from_card_data then view:sync_visual_from_card_data() end
                    sealed_any = true
                end
            end
            if sealed_any then
                return { message = "Sealed!" }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Chad: retrigger the leftmost Joker 2 additional times.
-- PORT NOTE: PC compares context.other_card against G.jokers.cards[1];
-- the fork's held list is G.jokers. PC's "other_card ~= self" compares
-- a card against the Joker's center table (always true), so a leftmost
-- Chad retriggers itself, as here.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "chad",
    loc_txt = {
        name = "Chad",
        text = {
            "Retrigger {C:attention}leftmost{} Joker",
            "{C:attention}#1#{} additional times",
        },
    },
    config = { extra = { retriggers = 2 }, immutable = { max_retriggers = 25 } },
    rarity = 3,
    cost = 10,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "chad.png",
    negative_sprite = "chad_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { math.min(card.ability.immutable.max_retriggers, card.ability.extra.retriggers) } }
    end,
    calculate = function(self, card, context)
        if context.retrigger_joker_check and not context.retrigger_joker and context.other_card then
            if G and G.jokers and context.other_card == G.jokers[1] then
                return {
                    message = "Again!",
                    repetitions = math.min(card.ability.immutable.max_retriggers, card.ability.extra.retriggers),
                }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Jimball: gains X0.15 Mult per consecutive hand played while playing
-- your most played poker hand; resets when that stops.
-- PORT NOTE: PC reads G.GAME.hands[name].played; the fork's equivalent
-- is G.hand_play_counts indexed by G.handlist position. The fork
-- increments the count before the before context fires, matching PC's
-- timing. PC's visible-hand check is dropped (secret hands are not
-- distinguishable in the fork's counts). The jimball notification
-- overlay / music init is dropped with the rest of the Cryptid UI.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "jimball",
    loc_txt = {
        name = "Jimball",
        text = {
            "This Joker gains {X:mult,C:white} X#1# {} Mult",
            "per {C:attention}consecutive{} hand played",
            "while playing your",
            "most played {C:attention}poker hand{}",
            "{C:inactive}(Currently {X:mult,C:white} X#2# {C:inactive} Mult)",
        },
    },
    config = { extra = { x_mult = 1, x_mult_mod = 0.15 } },
    rarity = 3,
    cost = 9,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    sprite = "jimball.png",
    negative_sprite = "jimball_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.x_mult_mod, card.ability.extra.x_mult } }
    end,
    calculate = function(self, card, context)
        if context.before and not context.blueprint and context.scoring_name then
            local function play_count(name)
                if not (G and G.handlist and G.hand_play_counts) then return 0 end
                for i, n in ipairs(G.handlist) do
                    if n == name then return tonumber(G.hand_play_counts[i]) or 0 end
                end
                return 0
            end
            local mine = play_count(context.scoring_name)
            local reset = false
            if G and G.handlist then
                for _, n in ipairs(G.handlist) do
                    if n ~= context.scoring_name and play_count(n) >= mine then
                        reset = true
                        break
                    end
                end
            end
            if reset then
                if card.ability.extra.x_mult > 1 then
                    card.ability.extra.x_mult = 1
                    return { message = "Reset" }
                end
            else
                card.ability.extra.x_mult = card.ability.extra.x_mult + card.ability.extra.x_mult_mod
                return { message = "Upgrade!" }
            end
        end
        if context.joker_main and card.ability.extra.x_mult > 1 then
            return { xmult = card.ability.extra.x_mult }
        end
    end,
}

--------------------------------------------------------------------------------
-- SUS: at end of round, create a copy of a random card held in hand and
-- destroy all others; Kings of Hearts are prioritized.
-- PORT NOTE: PC uses copy_card, G.play emplacement, dissolve events and
-- a G.GAME.sus_cards guard shared between copies. The fork port destroys
-- with SMODS.destroy_card and creates the copy straight into the deck
-- with SMODS.add_card (area = "deck"), capturing the copy source's data
-- before destroying. PC marks the chosen card with a field on the card
-- object; here the mark lives on card_data (cryp_sus_chosen), which
-- persists with the deck the same way. PC's eternal check for playing
-- cards is dropped (fork playing cards carry no eternal sticker) and
-- its shatter check is dropped (no Glass-style shatter distinction).
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "sus",
    loc_txt = {
        name = "SUS",
        text = {
            "At end of round, create",
            "a {C:attention}copy{} of a random",
            "card {C:attention}held in hand{},",
            "destroy all others",
            "{C:attention}Kings of Hearts{} are prioritized",
        },
    },
    config = { extra = {} },
    rarity = 3,
    cost = 7,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "sus.png",
    negative_sprite = "sus_negative.png",
    calculate = function(self, card, context)
        if context.end_of_round and G and G.hand and G.hand.card_nodes and #G.hand.card_nodes >= 1 then
            local nodes = G.hand.card_nodes
            local function is_impostor(view)
                local data = view.card_data or {}
                return data.enhancement ~= "stone" and view:get_id() == 13 and view:is_suit("Hearts")
            end
            local impostors, chosen = {}, nil
            for _, view in ipairs(nodes) do
                if is_impostor(view) then impostors[#impostors + 1] = view end
                if view.card_data and view.card_data.cryp_sus_chosen then chosen = view end
            end
            if not chosen then
                chosen = SMODS.pseudorandom_element(nodes, "cryp_sus")
                if chosen and chosen.card_data then chosen.card_data.cryp_sus_chosen = true end
            end
            if not chosen then return end
            local to_copy = chosen
            if #impostors > 0 then
                to_copy = SMODS.pseudorandom_element(impostors, "cryp_sus2") or chosen
            end
            local src = to_copy.card_data or {}
            local copy_args = {
                set = "Playing",
                rank = src.rank,
                suit = src.suit,
                enhancement = src.enhancement,
                seal = src.seal,
                area = "deck",
            }
            if type(to_copy.edition) == "string" then copy_args.edition = to_copy.edition end
            for _, view in ipairs(nodes) do
                if not is_impostor(view) and not (view == chosen and #impostors == 0) then
                    SMODS.destroy_card(view)
                end
            end
            SMODS.add_card(copy_args)
            return { message = "Sus!" }
        end
    end,
}

--------------------------------------------------------------------------------
-- Fidget Spinner: gains +6 Chips if the hand played is not your most
-- played poker hand.
-- PORT NOTE: same hand_play_counts adaptation as Jimball; PC's
-- visible-hand check is dropped the same way.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "fspinner",
    loc_txt = {
        name = "Fidget Spinner",
        text = {
            "This Joker gains {C:chips}+#2#{} Chips",
            "if hand played is {C:attention}not{}",
            "most played {C:attention}poker hand{}",
            "{C:inactive}(Currently {C:chips}+#1#{C:inactive} Chips)",
        },
    },
    config = { extra = { chips = 0, chip_mod = 6 } },
    rarity = 1,
    cost = 5,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    sprite = "fspinner.png",
    negative_sprite = "fspinner_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chips, card.ability.extra.chip_mod } }
    end,
    calculate = function(self, card, context)
        if context.before and not context.blueprint and context.scoring_name then
            local function play_count(name)
                if not (G and G.handlist and G.hand_play_counts) then return 0 end
                for i, n in ipairs(G.handlist) do
                    if n == name then return tonumber(G.hand_play_counts[i]) or 0 end
                end
                return 0
            end
            local mine = play_count(context.scoring_name)
            local not_most = false
            if G and G.handlist then
                for _, n in ipairs(G.handlist) do
                    if n ~= context.scoring_name and play_count(n) >= mine then
                        not_most = true
                        break
                    end
                end
            end
            if not_most then
                card.ability.extra.chips = card.ability.extra.chips + card.ability.extra.chip_mod
                return { message = "Upgrade!" }
            end
        end
        if context.joker_main and card.ability.extra.chips > 0 then
            return { chips = card.ability.extra.chips }
        end
    end,
}

--------------------------------------------------------------------------------
-- Waluigi: all Jokers give X2.5 Mult.
-- PORT NOTE: PC uses Steamodded's context.other_joker; the fork's
-- equivalent is context.post_trigger (the established sibling-pack
-- adaptation). The Talisman animation guard is dropped.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "waluigi",
    loc_txt = {
        name = "Waluigi",
        text = {
            "All Jokers give",
            "{X:mult,C:white} X#1# {} Mult",
        },
    },
    config = { extra = { Xmult = 2.5 } },
    rarity = 4,
    cost = 20,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "waluigi.png",
    soul_sprite = "waluigi_soul.png",
    negative_sprite = "waluigi_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.Xmult } }
    end,
    calculate = function(self, card, context)
        if context.post_trigger and context.other_card and context.other_card ~= card then
            return { xmult = card.ability.extra.Xmult }
        end
    end,
}

--------------------------------------------------------------------------------
-- Wario: all Jokers give $3 when triggered.
-- PORT NOTE: PC already uses context.post_trigger; its exclusion of
-- fixed/mod_probability other-contexts is dropped because the fork
-- never raises post_trigger for probability queries.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "wario",
    loc_txt = {
        name = "Wario",
        text = {
            "All Jokers give",
            "{C:money}$#1#{} when triggered",
        },
    },
    config = { extra = { money = 3 } },
    rarity = 4,
    cost = 20,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "wario.png",
    soul_sprite = "wario_soul.png",
    negative_sprite = "wario_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.money } }
    end,
    calculate = function(self, card, context)
        if context.post_trigger and context.other_card and context.other_card ~= card then
            return { dollars = card.ability.extra.money }
        end
    end,
}

--------------------------------------------------------------------------------
-- Krusty the Clown: gains X0.02 Mult when each played card is scored.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "krustytheclown",
    loc_txt = {
        name = "Krusty the Clown",
        text = {
            "This Joker gains",
            "{X:mult,C:white} X#1# {} Mult when",
            "each played {C:attention}card{} is scored",
            "{C:inactive}(Currently {X:mult,C:white} X#2# {C:inactive} Mult)",
        },
    },
    config = { extra = { extra = 0.02, x_mult = 1 } },
    rarity = 2,
    cost = 7,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    sprite = "krustytheclown.png",
    negative_sprite = "krustytheclown_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.extra, card.ability.extra.x_mult } }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play and not context.blueprint then
            card.ability.extra.x_mult = card.ability.extra.x_mult + card.ability.extra.extra
            return { message = "Upgrade!" }
        end
        if context.joker_main and card.ability.extra.x_mult > 1 then
            return { xmult = card.ability.extra.x_mult }
        end
    end,
}

--------------------------------------------------------------------------------
-- Blurred Joker: gain +1 hand when Blind is selected.
-- PORT NOTE: PC calls ease_hands_played(+1) at setting_blind, which is
-- exactly +1 hand per round while held; the fork expresses that as the
-- declarative hands modifier, with no calculate. Small deviation: the
-- modifier also applies if the Joker is gained mid-round, where PC
-- would wait for the next Blind. The SDM_0's Stuff tooltip hook is
-- dropped.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "blurred",
    loc_txt = {
        name = "Blurred Joker",
        text = {
            "Gain {C:attention}+#1#{} hand when",
            "{C:attention}Blind{} is selected",
        },
    },
    config = { hands = 1, extra = { extra_hands = 1 } },
    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "blurred.png",
    negative_sprite = "blurred_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.extra_hands } }
    end,
}

--------------------------------------------------------------------------------
-- Garden of Forking Paths: earn $7 if the played hand contains an
-- Ace and a 7.
-- PORT NOTE: PC eases the dollars and returns only a message; the same
-- shape is kept (ease_dollars is a listed helper in this pack).
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "gardenfork",
    loc_txt = {
        name = "Garden of Forking Paths",
        text = {
            "Earn {C:money}$#1#{} if {C:attention}played hand{}",
            "contains an {C:attention}Ace{} and a {C:attention}7{}",
        },
    },
    config = { extra = { money = 7 } },
    rarity = 3,
    cost = 7,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "gardenfork.png",
    negative_sprite = "gardenfork_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.money } }
    end,
    calculate = function(self, card, context)
        if context.before and context.full_hand then
            local has_ace, has_seven = false, false
            for _, c in ipairs(context.full_hand) do
                local id = c:get_id()
                if id == 14 then has_ace = true end
                if id == 7 then has_seven = true end
            end
            if has_ace and has_seven then
                ease_dollars(card.ability.extra.money)
                return { message = "$" .. card.ability.extra.money }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Light Up the Night: each played 7 or 2 gives X1.5 Mult when scored.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "lightupthenight",
    loc_txt = {
        name = "Light Up the Night",
        text = {
            "Each played {C:attention}7{} or {C:attention}2{}",
            "gives {X:mult,C:white}X#1#{} Mult when scored",
        },
    },
    config = { extra = { xmult = 1.5 } },
    rarity = 3,
    cost = 7,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "lightupthenight.png",
    negative_sprite = "lightupthenight_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.xmult } }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play and context.other_card then
            local rank = context.other_card:get_id()
            if rank == 2 or rank == 7 then
                return { xmult = card.ability.extra.xmult }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- No Sound, No Memory: retrigger each played 7 three additional times.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "nosound",
    loc_txt = {
        name = "No Sound, No Memory",
        text = {
            "Retrigger each played {C:attention}7{}",
            "{C:attention}#1#{} additional times",
        },
    },
    config = { extra = { retriggers = 3 }, immutable = { max_retriggers = 40 } },
    rarity = 3,
    cost = 7,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "nosound.png",
    negative_sprite = "nosound_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { math.min(card.ability.immutable.max_retriggers, card.ability.extra.retriggers) } }
    end,
    calculate = function(self, card, context)
        if context.repetition and context.cardarea == G.play and context.other_card then
            if context.other_card:get_id() == 7 then
                return {
                    message = "Again!",
                    repetitions = math.min(card.ability.immutable.max_retriggers, card.ability.extra.retriggers),
                }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Consume-able: earn $3 when using a consumable.
-- PORT NOTE: PC returns p_dollars; the fork's return reader accepts
-- dollars for the same field (smods apply_return), paid on use.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "hunger",
    loc_txt = {
        name = "Consume-able",
        text = {
            "Earn {C:money}$#1#{} when",
            "using a {C:attention}consumable{}",
        },
    },
    config = { extra = { money = 3 } },
    rarity = 2,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "hunger.png",
    negative_sprite = "hunger_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.money } }
    end,
    calculate = function(self, card, context)
        if context.using_consumeable then
            return { dollars = card.ability.extra.money }
        end
    end,
}

--------------------------------------------------------------------------------
-- 2D: retrigger each played 2 two additional times.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "weegaming",
    loc_txt = {
        name = "2D",
        text = {
            "Retrigger each played {C:attention}2{}",
            "{C:attention}#1#{} additional times",
            "{C:inactive}Wee Gaming?{}",
        },
    },
    config = { extra = { retriggers = 2 }, immutable = { max_retriggers = 25 } },
    rarity = 1,
    cost = 5,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "weegaming.png",
    negative_sprite = "weegaming_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { math.min(card.ability.immutable.max_retriggers, card.ability.extra.retriggers) } }
    end,
    calculate = function(self, card, context)
        if context.repetition and context.cardarea == G.play and context.other_card then
            if context.other_card:get_id() == 2 then
                return {
                    message = "Again!",
                    repetitions = math.min(card.ability.immutable.max_retriggers, card.ability.extra.retriggers),
                }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Red Bloon: earn $20 in 2 rounds, then self destructs.
-- PORT NOTE: PC removes itself through an event-manager dissolve; the
-- fork uses SMODS.destroy_joker plus ease_dollars at the same
-- end_of_round beat. PC's countdown message is the Cryptid-only
-- cry_minus_round key; a literal is used.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "redbloon",
    loc_txt = {
        name = "Red Bloon",
        text = {
            "Earn {C:money}$#1#{} in {C:attention}#2#{} rounds",
            "{C:red}self destructs{}",
        },
    },
    config = { extra = { money = 20, rounds_remaining = 2 } },
    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = false,
    perishable_compat = false,
    sprite = "redbloon.png",
    negative_sprite = "redbloon_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.money, card.ability.extra.rounds_remaining } }
    end,
    calculate = function(self, card, context)
        if context.end_of_round and not context.blueprint and not context.retrigger_joker then
            local extra = card.ability.extra
            extra.rounds_remaining = extra.rounds_remaining - 1
            if extra.rounds_remaining > 0 then
                return { message = "-1 Round" }
            end
            ease_dollars(extra.money)
            SMODS.destroy_joker(card)
            return { message = "$" .. extra.money }
        end
    end,
}

--------------------------------------------------------------------------------
-- AP Joker: X4 Mult against Boss Blinds.
-- PORT NOTE: PC checks Cryptid.is_boss_blind(G.GAME.blind); the fork's
-- equivalent is G.current_blind_index == 3 (the Champagne pattern).
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "apjoker",
    loc_txt = {
        name = "AP Joker",
        text = {
            "{X:mult,C:white} X#1# {} Mult against {C:attention}Boss Blinds{}",
        },
    },
    config = { extra = { x_mult = 4 } },
    rarity = 2,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    sprite = "apjoker.png",
    negative_sprite = "apjoker_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.x_mult } }
    end,
    calculate = function(self, card, context)
        if context.joker_main and G and G.current_blind_index == 3 then
            return { xmult = card.ability.extra.x_mult }
        end
    end,
}

--------------------------------------------------------------------------------
-- Panopticon: all hands are considered the last hand of each round.
-- PORT NOTE: PC juggles G.GAME.current_round.hands_left to 0 between
-- the before and after contexts and restores it after; the fork port
-- does the same juggle on G.hands, the fork's hands-remaining counter,
-- with the shared stash kept on G itself (G.cryp_panop_juggle) so
-- multiple copies share one stash exactly as PC's G.GAME field does.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "panopticon",
    loc_txt = {
        name = "Panopticon",
        text = {
            "All hands are considered the",
            "{C:attention}last hand{} of each round",
        },
    },
    config = { extra = {} },
    rarity = 1,
    cost = 1,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "panopticon.png",
    negative_sprite = "panopticon_negative.png",
    calculate = function(self, card, context)
        if not G then return end
        if context.before and not context.blueprint and not context.retrigger_joker then
            if G.cryp_panop_juggle == nil then
                G.cryp_panop_juggle = tonumber(G.hands) or 0
            end
            G.hands = 0
        end
        if context.after and not context.blueprint and not context.retrigger_joker then
            if G.cryp_panop_juggle ~= nil then
                G.hands = G.cryp_panop_juggle
                G.cryp_panop_juggle = nil
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Fridge Magnet: earn $2 at end of round; this earns X5 if there are
-- 4 or fewer Joker cards.
-- PORT NOTE: PC counts #G.jokers.cards; the fork's held list is
-- G.jokers itself.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "magnet",
    loc_txt = {
        name = "Fridge Magnet",
        text = {
            "Earn {C:money}$#1#{} at end of round",
            "This earns {X:money,C:white} X#2# {} if there are",
            "{C:attention}#3#{} or fewer {C:attention}Joker{} cards",
        },
    },
    config = { extra = { money = 2, Xmoney = 5, slots = 4 } },
    rarity = 1,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "magnet.png",
    negative_sprite = "magnet_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.money, card.ability.extra.Xmoney, card.ability.extra.slots } }
    end,
    calc_dollar_bonus = function(self, card)
        local held = (G and G.jokers and #G.jokers) or 0
        if held <= card.ability.extra.slots then
            return card.ability.extra.money * card.ability.extra.Xmoney
        end
        return card.ability.extra.money
    end,
}

--------------------------------------------------------------------------------
-- Unjust Dagger: when Blind is selected, destroy the Joker to the left
-- and gain one-fifth of its sell value as XMult.
-- PORT NOTE: PC dissolves the neighbour through the event manager and
-- guards on getting_sliced flags; the fork destroys immediately with
-- SMODS.destroy_joker, so no slice flags are needed. The exotic-slice
-- achievement check is dropped (no achievement system here).
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "unjust_dagger",
    loc_txt = {
        name = "Unjust Dagger",
        text = {
            "When {C:attention}Blind{} is selected,",
            "destroy Joker to the left",
            "and gain {C:attention}one-fifth{} of",
            "its sell value as {X:mult,C:white} XMult {}",
            "{C:inactive}(Currently {X:mult,C:white} X#1# {C:inactive} Mult)",
        },
    },
    config = { extra = { x_mult = 1 } },
    rarity = 2,
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    sprite = "unjust_dagger.png",
    negative_sprite = "unjust_dagger_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.x_mult } }
    end,
    calculate = function(self, card, context)
        if context.joker_main and card.ability.extra.x_mult > 1 then
            return { xmult = card.ability.extra.x_mult }
        end
        if context.setting_blind and not context.blueprint and G and G.jokers then
            local my_pos = nil
            for i, j in ipairs(G.jokers) do
                if j == card then
                    my_pos = i
                    break
                end
            end
            local left = my_pos and G.jokers[my_pos - 1] or nil
            if left and not left.eternal then
                local gain = 0.2 * (tonumber(left.sell_cost) or 0)
                if SMODS.destroy_joker(left) then
                    card.ability.extra.x_mult = card.ability.extra.x_mult + gain
                    return { message = "Upgrade!" }
                end
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Monkey Dagger: when Blind is selected, destroy the Joker to the left
-- and permanently add ten times its sell value to this Chips.
-- PORT NOTE: same immediate-destroy adaptation as Unjust Dagger.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "monkey_dagger",
    loc_txt = {
        name = "Monkey Dagger",
        text = {
            "When {C:attention}Blind{} is selected,",
            "destroy Joker to the left",
            "and permanently add {C:attention}ten times{}",
            "its sell value to this {C:chips}Chips{}",
            "{C:inactive}(Currently {C:chips}+#1#{C:inactive} Chips)",
        },
    },
    config = { extra = { chips = 0 } },
    rarity = 2,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    sprite = "monkey_dagger.png",
    negative_sprite = "monkey_dagger_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chips } }
    end,
    calculate = function(self, card, context)
        if context.joker_main and card.ability.extra.chips > 0 then
            return { chips = card.ability.extra.chips }
        end
        if context.setting_blind and not context.blueprint and G and G.jokers then
            local my_pos = nil
            for i, j in ipairs(G.jokers) do
                if j == card then
                    my_pos = i
                    break
                end
            end
            local left = my_pos and G.jokers[my_pos - 1] or nil
            if left and not left.eternal then
                local gain = 10 * (tonumber(left.sell_cost) or 0)
                if SMODS.destroy_joker(left) then
                    card.ability.extra.chips = card.ability.extra.chips + gain
                    return { message = "Upgrade!" }
                end
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Mondrian: gains X0.25 Mult if no discards were used this round.
-- PORT NOTE: PC reads G.GAME.current_round.discards_used; the fork has
-- no such counter, so this Joker counts its own discard contexts and
-- resets at end_of_round (the MoreFluff grep pattern). Only the
-- zero/non-zero distinction matters, so counting cards instead of
-- discard actions is exact. A copy gained mid-round starts at zero
-- even if discards were already used (same caveat as grep).
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "mondrian",
    loc_txt = {
        name = "Mondrian",
        text = {
            "This Joker gains {X:mult,C:white} X#1# {} Mult",
            "if no {C:attention}discards{} were",
            "used this round",
            "{C:inactive}(Currently {X:mult,C:white} X#2# {C:inactive} Mult)",
        },
    },
    config = { extra = { extra = 0.25, x_mult = 1, discards_used = 0 } },
    rarity = 2,
    cost = 7,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    sprite = "mondrian.png",
    negative_sprite = "mondrian_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.extra, card.ability.extra.x_mult } }
    end,
    calculate = function(self, card, context)
        if context.discard and not context.blueprint then
            card.ability.extra.discards_used = card.ability.extra.discards_used + 1
        end
        if context.joker_main and card.ability.extra.x_mult > 1 then
            return { xmult = card.ability.extra.x_mult }
        end
        if context.end_of_round and not context.blueprint and not context.retrigger_joker then
            local used = card.ability.extra.discards_used
            card.ability.extra.discards_used = 0
            if used == 0 then
                card.ability.extra.x_mult = card.ability.extra.x_mult + card.ability.extra.extra
                return { message = "Upgrade!" }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Sapling: after scoring 18 Enhanced cards, sell this card to create
-- an Epic Joker.
-- PORT NOTE: PC counts other_card.ability.effect ~= "Base"; the fork
-- reads card_data.enhancement instead. All Cryptid content is enabled
-- here and the pack registers the Epic rarity, so the created Joker is
-- Epic: its numeric rarity is resolved at runtime from
-- SMODS.Rarities["cryp_epic"].index, falling back to Rare (PC's 0.99
-- rarity roll) if the registration is somehow absent. PC's
-- juice_card_until "ready" animation becomes a one-time message.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "sapling",
    loc_txt = {
        name = "Sapling",
        text = {
            "After scoring {C:attention}#2#{} {C:inactive}[#1#]{} Enhanced",
            "cards, sell this card to",
            "create #4# {C:purple}#3#{} {C:attention}Joker{}",
        },
    },
    config = { extra = { req = 18, check = false }, immutable = { score = 0 } },
    rarity = 2,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = false,
    perishable_compat = true,
    sprite = "sapling.png",
    negative_sprite = "sapling_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.immutable.score, card.ability.extra.req, "Epic", "an" } }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play and not context.blueprint and not context.retrigger_joker and context.other_card then
            local data = context.other_card.card_data or {}
            if data.enhancement and data.enhancement ~= "base" then
                card.ability.immutable.score = card.ability.immutable.score + 1
                if card.ability.immutable.score >= card.ability.extra.req and not card.ability.extra.check then
                    card.ability.extra.check = true
                    return { message = "Ready!" }
                end
            end
        end
        if context.selling_self and not context.blueprint and not context.retrigger_joker then
            if card.ability.immutable.score >= card.ability.extra.req then
                local rarity_num = SMODS.Rarities and SMODS.Rarities["cryp_epic"] and SMODS.Rarities["cryp_epic"].index or 3
                local id = G and G.random_joker_def_id_by_rarity
                    and G:random_joker_def_id_by_rarity(rarity_num, "cryp_sapling") or nil
                if id then
                    SMODS.add_card { set = "Joker", key = id }
                end
                return { message = "+ Joker!" }
            end
            return { message = "Nope!" }
        end
    end,
}

--------------------------------------------------------------------------------
-- :D (Happy): create a random Joker at end of round; sell this card to
-- create a random Joker.
-- PORT NOTE: PC uses create_card("Joker", ...) through the event
-- manager with a joker_buffer capacity dance; the fork rolls a def with
-- G:random_joker_def_id and creates it with SMODS.add_card, which
-- returns nil when there is no room (PC's "Must have room"). As on PC,
-- neither branch excludes Blueprint copies. The sell branch relies on
-- the fork removing the sold Joker before the selling_self context
-- fires, freeing its slot, as PC's buffer check assumes.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "happy",
    loc_txt = {
        name = ":D",
        text = {
            "Create a random {C:attention}Joker{}",
            "at end of round",
            "Sell this card to",
            "create a random {C:attention}Joker{}",
            "{C:inactive}(Must have room){}",
        },
    },
    config = { extra = {} },
    rarity = 1,
    cost = 2,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = false,
    perishable_compat = true,
    sprite = "happy.png",
    negative_sprite = "happy_negative.png",
    calculate = function(self, card, context)
        if context.selling_self or (context.end_of_round and not context.individual and not context.repetition) then
            local id = G and G.random_joker_def_id and G:random_joker_def_id("cryp_happy") or nil
            if id then
                local created = SMODS.add_card { set = "Joker", key = id }
                if created then
                    return { message = "+ Joker!" }
                end
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Meteor Shower: other Foil cards each give +75 Chips.
-- PORT NOTE: PC's context.other_joker beat maps to the fork's post_trigger
-- pass (sibling-pack pattern); the Talisman juice-up event is dropped (no
-- event manager). Joker editions are plain strings in the fork; a played
-- card's edition lives in card_data.modifier.edition.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "meteor",
    loc_txt = {
        name = "Meteor Shower",
        text = {
            "Other {C:dark_edition}Foil{} cards each",
            "give {C:chips}+#1#{} Chips",
        },
    },
    config = { extra = { chips = 75 } },
    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "meteor.png",
    negative_sprite = "meteor_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chips } }
    end,
    calculate = function(self, card, context)
        if context.post_trigger and context.other_card and context.other_card ~= card then
            local e = context.other_card.edition
            if type(e) == "table" then e = e.key end
            if e == "foil" or e == "e_foil" then
                return { chips = card.ability.extra.chips }
            end
        end
        if context.individual and context.other_card then
            local cd = context.other_card.card_data
            local ed = cd and cd.modifier and cd.modifier.edition
            if ed == "foil" then
                if context.cardarea == G.play then
                    return { chips = card.ability.extra.chips }
                end
                if context.cardarea == G.hand and not context.end_of_round then
                    if context.other_card.debuff then
                        return { message = "Debuffed!" }
                    end
                    return { chips = card.ability.extra.chips }
                end
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Exoplanet: other Holographic cards each give +15 Mult.
-- PORT NOTE: same post_trigger / edition mapping as Meteor Shower. PC's
-- held-card branch returns h_mult; the fork has no h_mult return, so the
-- held branch returns mult (the sibling packs' held-card pattern).
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "exoplanet",
    loc_txt = {
        name = "Exoplanet",
        text = {
            "Other {C:dark_edition}Holographic{} cards",
            "each give {C:mult}+#1#{} Mult",
        },
    },
    config = { extra = { mult = 15 } },
    rarity = 1,
    cost = 3,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "exoplanet.png",
    negative_sprite = "exoplanet_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult } }
    end,
    calculate = function(self, card, context)
        if context.post_trigger and context.other_card and context.other_card ~= card then
            local e = context.other_card.edition
            if type(e) == "table" then e = e.key end
            if e == "holo" or e == "e_holo" then
                return { mult = card.ability.extra.mult }
            end
        end
        if context.individual and context.other_card then
            local cd = context.other_card.card_data
            local ed = cd and cd.modifier and cd.modifier.edition
            if ed == "holo" then
                if context.cardarea == G.play then
                    return { mult = card.ability.extra.mult }
                end
                if context.cardarea == G.hand and not context.end_of_round then
                    if context.other_card.debuff then
                        return { message = "Debuffed!" }
                    end
                    return { mult = card.ability.extra.mult }
                end
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Stardust: other Polychrome cards each give X2 Mult.
-- PORT NOTE: same post_trigger / edition mapping as Meteor Shower.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "stardust",
    loc_txt = {
        name = "Stardust",
        text = {
            "Other {C:dark_edition}Polychrome{} cards",
            "each give {X:mult,C:white}X#1#{} Mult",
        },
    },
    config = { extra = { xmult = 2 } },
    rarity = 1,
    cost = 2,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "stardust.png",
    negative_sprite = "stardust_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.xmult } }
    end,
    calculate = function(self, card, context)
        if context.post_trigger and context.other_card and context.other_card ~= card then
            local e = context.other_card.edition
            if type(e) == "table" then e = e.key end
            if e == "polychrome" or e == "e_polychrome" then
                return { xmult = card.ability.extra.xmult }
            end
        end
        if context.individual and context.other_card then
            local cd = context.other_card.card_data
            local ed = cd and cd.modifier and cd.modifier.edition
            if ed == "polychrome" then
                if context.cardarea == G.play then
                    return { xmult = card.ability.extra.xmult }
                end
                if context.cardarea == G.hand and not context.end_of_round then
                    if context.other_card.debuff then
                        return { message = "Debuffed!" }
                    end
                    return { xmult = card.ability.extra.xmult }
                end
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- The Filler: X1.00000000000003 Mult if played hand contains a High Card.
-- PORT NOTE: PC defines this Joker twice with the same effect (the chunk is
-- the second definition, whose top-level config is normalised into extra
-- here). High Card fires unconditionally in joker_main, as in the existing
-- pack (the fork's contained-types map has no High Card entry).
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "filler",
    loc_txt = {
        name = "The Filler",
        text = {
            "{X:mult,C:white} X#1# {} Mult if played",
            "hand contains",
            "a {C:attention}High Card{}",
        },
    },
    config = { extra = { xmult = 1.00000000000003 } },
    rarity = 3,
    cost = 1,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "filler.png",
    negative_sprite = "filler_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.xmult } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            return { xmult = card.ability.extra.xmult }
        end
    end,
}

--------------------------------------------------------------------------------
-- The Nuts: X5 Mult if played hand contains a Straight Flush.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "nuts",
    loc_txt = {
        name = "The Nuts",
        text = {
            "{X:mult,C:white} X#1# {} Mult if played",
            "hand contains",
            "a {C:attention}Straight Flush{}",
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
    sprite = "nuts.png",
    negative_sprite = "nuts_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.xmult } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            if context.poker_hands and next(context.poker_hands["Straight Flush"]) then
                return { xmult = card.ability.extra.xmult }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- The Quintet: X5 Mult if played hand contains a Five of a Kind.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "quintet",
    loc_txt = {
        name = "The Quintet",
        text = {
            "{X:mult,C:white} X#1# {} Mult if played",
            "hand contains",
            "a {C:attention}Five of a Kind{}",
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
    sprite = "quintet.png",
    negative_sprite = "quintet_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.xmult } }
    end,
    in_pool = function(self, args)
        if not (G and G.handlist and G.hand_play_counts) then return false end
        for i, hand_name in ipairs(G.handlist) do
            if hand_name == "Five of a Kind" and (tonumber(G.hand_play_counts[i]) or 0) > 0 then
                return true
            end
        end
        return false
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            if context.poker_hands and next(context.poker_hands["Five of a Kind"]) then
                return { xmult = card.ability.extra.xmult }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- The Unity: X9 Mult if played hand contains a Flush House.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "unity",
    loc_txt = {
        name = "The Unity",
        text = {
            "{X:mult,C:white} X#1# {} Mult if played",
            "hand contains",
            "a {C:attention}Flush House{}",
        },
    },
    config = { extra = { xmult = 9 } },
    rarity = 3,
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "unity.png",
    negative_sprite = "unity_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.xmult } }
    end,
    in_pool = function(self, args)
        if not (G and G.handlist and G.hand_play_counts) then return false end
        for i, hand_name in ipairs(G.handlist) do
            if hand_name == "Flush House" and (tonumber(G.hand_play_counts[i]) or 0) > 0 then
                return true
            end
        end
        return false
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            if context.poker_hands and next(context.poker_hands["Flush House"]) then
                return { xmult = card.ability.extra.xmult }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- The Swarm: X9 Mult if played hand contains a Flush Five.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "swarm",
    loc_txt = {
        name = "The Swarm",
        text = {
            "{X:mult,C:white} X#1# {} Mult if played",
            "hand contains",
            "a {C:attention}Flush Five{}",
        },
    },
    config = { extra = { xmult = 9 } },
    rarity = 3,
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "swarm.png",
    negative_sprite = "swarm_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.xmult } }
    end,
    in_pool = function(self, args)
        if not (G and G.handlist and G.hand_play_counts) then return false end
        for i, hand_name in ipairs(G.handlist) do
            if hand_name == "Flush Five" and (tonumber(G.hand_play_counts[i]) or 0) > 0 then
                return true
            end
        end
        return false
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            if context.poker_hands and next(context.poker_hands["Flush Five"]) then
                return { xmult = card.ability.extra.xmult }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- The Stronghold: X5 Mult if played hand contains a Bulwark.
-- PORT NOTE: requires the Bulwark poker hand (5+ Stone cards) to be
-- registered centrally under the key "Bulwark"; the in_pool gate reads
-- that hand's play count.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "stronghold",
    loc_txt = {
        name = "The Stronghold",
        text = {
            "{X:mult,C:white} X#1# {} Mult if played",
            "hand contains",
            "a {C:attention}Bulwark{}",
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
    sprite = "stronghold.png",
    negative_sprite = "stronghold_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.xmult } }
    end,
    in_pool = function(self, args)
        if not (G and G.handlist and G.hand_play_counts) then return false end
        for i, hand_name in ipairs(G.handlist) do
            if hand_name == "Bulwark" and (tonumber(G.hand_play_counts[i]) or 0) > 0 then
                return true
            end
        end
        return false
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            if context.poker_hands and next(context.poker_hands["Bulwark"]) then
                return { xmult = card.ability.extra.xmult }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- The Clash: X12 Mult if played hand contains an Ultimate Pair.
-- PORT NOTE: requires the UltPair poker hand (two same-suit Two Pairs in
-- two suits) to be registered centrally under the key "UltPair"; the
-- in_pool gate reads that hand's play count.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "clash",
    loc_txt = {
        name = "The Clash",
        text = {
            "{X:mult,C:white} X#1# {} Mult if played",
            "hand contains",
            "an {C:attention}Ultimate Pair{}",
        },
    },
    config = { extra = { xmult = 12 } },
    rarity = 3,
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "clash.png",
    negative_sprite = "clash_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.xmult } }
    end,
    in_pool = function(self, args)
        if not (G and G.handlist and G.hand_play_counts) then return false end
        for i, hand_name in ipairs(G.handlist) do
            if hand_name == "UltPair" and (tonumber(G.hand_play_counts[i]) or 0) > 0 then
                return true
            end
        end
        return false
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            if context.poker_hands and next(context.poker_hands["UltPair"]) then
                return { xmult = card.ability.extra.xmult }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Manic Joker: +22 Mult if played hand contains a Straight Flush.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "manic",
    loc_txt = {
        name = "Manic Joker",
        text = {
            "{C:mult}+#1#{} Mult if played",
            "hand contains",
            "a {C:attention}Straight Flush{}",
        },
    },
    config = { extra = { t_mult = 22 } },
    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "manic.png",
    negative_sprite = "manic_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.t_mult } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            if context.poker_hands and next(context.poker_hands["Straight Flush"]) then
                return { mult = card.ability.extra.t_mult }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Silly Joker: +16 Mult if played hand contains a Full House.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "silly",
    loc_txt = {
        name = "Silly Joker",
        text = {
            "{C:mult}+#1#{} Mult if played",
            "hand contains",
            "a {C:attention}Full House{}",
        },
    },
    config = { extra = { t_mult = 16 } },
    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "silly.png",
    negative_sprite = "silly_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.t_mult } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            if context.poker_hands and next(context.poker_hands["Full House"]) then
                return { mult = card.ability.extra.t_mult }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Delirious Joker: +22 Mult if played hand contains a Five of a Kind.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "delirious",
    loc_txt = {
        name = "Delirious Joker",
        text = {
            "{C:mult}+#1#{} Mult if played",
            "hand contains",
            "a {C:attention}Five of a Kind{}",
        },
    },
    config = { extra = { t_mult = 22 } },
    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "delirious.png",
    negative_sprite = "delirious_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.t_mult } }
    end,
    in_pool = function(self, args)
        if not (G and G.handlist and G.hand_play_counts) then return false end
        for i, hand_name in ipairs(G.handlist) do
            if hand_name == "Five of a Kind" and (tonumber(G.hand_play_counts[i]) or 0) > 0 then
                return true
            end
        end
        return false
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            if context.poker_hands and next(context.poker_hands["Five of a Kind"]) then
                return { mult = card.ability.extra.t_mult }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Wacky Joker: +30 Mult if played hand contains a Flush House.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "wacky",
    loc_txt = {
        name = "Wacky Joker",
        text = {
            "{C:mult}+#1#{} Mult if played",
            "hand contains",
            "a {C:attention}Flush House{}",
        },
    },
    config = { extra = { t_mult = 30 } },
    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "wacky.png",
    negative_sprite = "wacky_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.t_mult } }
    end,
    in_pool = function(self, args)
        if not (G and G.handlist and G.hand_play_counts) then return false end
        for i, hand_name in ipairs(G.handlist) do
            if hand_name == "Flush House" and (tonumber(G.hand_play_counts[i]) or 0) > 0 then
                return true
            end
        end
        return false
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            if context.poker_hands and next(context.poker_hands["Flush House"]) then
                return { mult = card.ability.extra.t_mult }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Kooky Joker: +30 Mult if played hand contains a Flush Five.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "kooky",
    loc_txt = {
        name = "Kooky Joker",
        text = {
            "{C:mult}+#1#{} Mult if played",
            "hand contains",
            "a {C:attention}Flush Five{}",
        },
    },
    config = { extra = { t_mult = 30 } },
    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "kooky.png",
    negative_sprite = "kooky_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.t_mult } }
    end,
    in_pool = function(self, args)
        if not (G and G.handlist and G.hand_play_counts) then return false end
        for i, hand_name in ipairs(G.handlist) do
            if hand_name == "Flush Five" and (tonumber(G.hand_play_counts[i]) or 0) > 0 then
                return true
            end
        end
        return false
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            if context.poker_hands and next(context.poker_hands["Flush Five"]) then
                return { mult = card.ability.extra.t_mult }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Bonkers Joker: +20 Mult if played hand contains a Bulwark.
-- PORT NOTE: requires the Bulwark poker hand (5+ Stone cards) to be
-- registered centrally under the key "Bulwark"; the in_pool gate reads
-- that hand's play count.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "bonkers",
    loc_txt = {
        name = "Bonkers Joker",
        text = {
            "{C:mult}+#1#{} Mult if played",
            "hand contains",
            "a {C:attention}Bulwark{}",
        },
    },
    config = { extra = { t_mult = 20 } },
    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "bonkers.png",
    negative_sprite = "bonkers_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.t_mult } }
    end,
    in_pool = function(self, args)
        if not (G and G.handlist and G.hand_play_counts) then return false end
        for i, hand_name in ipairs(G.handlist) do
            if hand_name == "Bulwark" and (tonumber(G.hand_play_counts[i]) or 0) > 0 then
                return true
            end
        end
        return false
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            if context.poker_hands and next(context.poker_hands["Bulwark"]) then
                return { mult = card.ability.extra.t_mult }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Foolhardy Joker: +42 Mult if played hand contains an Ultimate Pair.
-- PORT NOTE: requires the UltPair poker hand (two same-suit Two Pairs in
-- two suits) to be registered centrally under the key "UltPair"; the
-- in_pool gate reads that hand's play count.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "foolhardy",
    loc_txt = {
        name = "Foolhardy Joker",
        text = {
            "{C:mult}+#1#{} Mult if played",
            "hand contains",
            "an {C:attention}Ultimate Pair{}",
        },
    },
    config = { extra = { t_mult = 42 } },
    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "foolhardy.png",
    negative_sprite = "foolhardy_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.t_mult } }
    end,
    in_pool = function(self, args)
        if not (G and G.handlist and G.hand_play_counts) then return false end
        for i, hand_name in ipairs(G.handlist) do
            if hand_name == "UltPair" and (tonumber(G.hand_play_counts[i]) or 0) > 0 then
                return true
            end
        end
        return false
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            if context.poker_hands and next(context.poker_hands["UltPair"]) then
                return { mult = card.ability.extra.t_mult }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Tricksy Joker: +170 Chips if played hand contains a Straight Flush.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "tricksy",
    loc_txt = {
        name = "Tricksy Joker",
        text = {
            "{C:chips}+#1#{} Chips if played",
            "hand contains",
            "a {C:attention}Straight Flush{}",
        },
    },
    config = { extra = { t_chips = 170 } },
    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "tricksy.png",
    negative_sprite = "tricksy_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.t_chips } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            if context.poker_hands and next(context.poker_hands["Straight Flush"]) then
                return { chips = card.ability.extra.t_chips }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Foxy Joker: +130 Chips if played hand contains a Full House.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "foxy",
    loc_txt = {
        name = "Foxy Joker",
        text = {
            "{C:chips}+#1#{} Chips if played",
            "hand contains",
            "a {C:attention}Full House{}",
        },
    },
    config = { extra = { t_chips = 130 } },
    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "foxy.png",
    negative_sprite = "foxy_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.t_chips } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            if context.poker_hands and next(context.poker_hands["Full House"]) then
                return { chips = card.ability.extra.t_chips }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Savvy Joker: +170 Chips if played hand contains a Five of a Kind.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "savvy",
    loc_txt = {
        name = "Savvy Joker",
        text = {
            "{C:chips}+#1#{} Chips if played",
            "hand contains",
            "a {C:attention}Five of a Kind{}",
        },
    },
    config = { extra = { t_chips = 170 } },
    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "savvy.png",
    negative_sprite = "savvy_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.t_chips } }
    end,
    in_pool = function(self, args)
        if not (G and G.handlist and G.hand_play_counts) then return false end
        for i, hand_name in ipairs(G.handlist) do
            if hand_name == "Five of a Kind" and (tonumber(G.hand_play_counts[i]) or 0) > 0 then
                return true
            end
        end
        return false
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            if context.poker_hands and next(context.poker_hands["Five of a Kind"]) then
                return { chips = card.ability.extra.t_chips }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Subtle Joker: +240 Chips if played hand contains a Flush House.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "subtle",
    loc_txt = {
        name = "Subtle Joker",
        text = {
            "{C:chips}+#1#{} Chips if played",
            "hand contains",
            "a {C:attention}Flush House{}",
        },
    },
    config = { extra = { t_chips = 240 } },
    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "subtle.png",
    negative_sprite = "subtle_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.t_chips } }
    end,
    in_pool = function(self, args)
        if not (G and G.handlist and G.hand_play_counts) then return false end
        for i, hand_name in ipairs(G.handlist) do
            if hand_name == "Flush House" and (tonumber(G.hand_play_counts[i]) or 0) > 0 then
                return true
            end
        end
        return false
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            if context.poker_hands and next(context.poker_hands["Flush House"]) then
                return { chips = card.ability.extra.t_chips }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Discreet Joker: +240 Chips if played hand contains a Flush Five.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "discreet",
    loc_txt = {
        name = "Discreet Joker",
        text = {
            "{C:chips}+#1#{} Chips if played",
            "hand contains",
            "a {C:attention}Flush Five{}",
        },
    },
    config = { extra = { t_chips = 240 } },
    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "discreet.png",
    negative_sprite = "discreet_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.t_chips } }
    end,
    in_pool = function(self, args)
        if not (G and G.handlist and G.hand_play_counts) then return false end
        for i, hand_name in ipairs(G.handlist) do
            if hand_name == "Flush Five" and (tonumber(G.hand_play_counts[i]) or 0) > 0 then
                return true
            end
        end
        return false
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            if context.poker_hands and next(context.poker_hands["Flush Five"]) then
                return { chips = card.ability.extra.t_chips }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Adroit Joker: +170 Chips if played hand contains a Bulwark.
-- PORT NOTE: requires the Bulwark poker hand (5+ Stone cards) to be
-- registered centrally under the key "Bulwark"; the in_pool gate reads
-- that hand's play count.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "adroit",
    loc_txt = {
        name = "Adroit Joker",
        text = {
            "{C:chips}+#1#{} Chips if played",
            "hand contains",
            "a {C:attention}Bulwark{}",
        },
    },
    config = { extra = { t_chips = 170 } },
    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "adroit.png",
    negative_sprite = "adroit_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.t_chips } }
    end,
    in_pool = function(self, args)
        if not (G and G.handlist and G.hand_play_counts) then return false end
        for i, hand_name in ipairs(G.handlist) do
            if hand_name == "Bulwark" and (tonumber(G.hand_play_counts[i]) or 0) > 0 then
                return true
            end
        end
        return false
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            if context.poker_hands and next(context.poker_hands["Bulwark"]) then
                return { chips = card.ability.extra.t_chips }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Treacherous Joker: +300 Chips if played hand contains an Ultimate Pair.
-- PORT NOTE: requires the UltPair poker hand (two same-suit Two Pairs in
-- two suits) to be registered centrally under the key "UltPair"; the
-- in_pool gate reads that hand's play count.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "treacherous",
    loc_txt = {
        name = "Treacherous Joker",
        text = {
            "{C:chips}+#1#{} Chips if played",
            "hand contains",
            "an {C:attention}Ultimate Pair{}",
        },
    },
    config = { extra = { t_chips = 300 } },
    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "treacherous.png",
    negative_sprite = "treacherous_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.t_chips } }
    end,
    in_pool = function(self, args)
        if not (G and G.handlist and G.hand_play_counts) then return false end
        for i, hand_name in ipairs(G.handlist) do
            if hand_name == "UltPair" and (tonumber(G.hand_play_counts[i]) or 0) > 0 then
                return true
            end
        end
        return false
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            if context.poker_hands and next(context.poker_hands["UltPair"]) then
                return { chips = card.ability.extra.t_chips }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Crypto Coin: earn $1-$10 for each Joker sold.
-- PORT NOTE: PC's roll is floor(pseudorandom * money_mod) + 1, i.e. a plain
-- 1..10 integer, done here with SMODS.pseudorandom; the G.GAME.dollar_buffer
-- bookkeeping is dropped (a dollars return pays directly). The fork raises
-- selling_card for consumable sales too, so the sale must carry a Joker
-- (context.card / context.port.joker, the sibling packs' test).
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "coin",
    loc_txt = {
        name = "Crypto Coin",
        text = {
            "Earn between",
            "{C:money}$#1#{} and {C:money}$#2#{} for",
            "each Joker {C:attention}sold{}",
        },
    },
    config = { extra = { money = 1 }, immutable = { money_mod = 10 } },
    rarity = 1,
    cost = 5,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "coin.png",
    negative_sprite = "coin_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.money,
            card.ability.extra.money * card.ability.immutable.money_mod } }
    end,
    calculate = function(self, card, context)
        if context.selling_card then
            local sold = context.card or (context.port and context.port.joker)
            if sold then
                local mod = SMODS.pseudorandom("cryp_coin", 1,
                    card.ability.immutable.money_mod)
                return { dollars = card.ability.extra.money * mod }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Wheel of Hope: gains X0.5 Mult when a Wheel of Fortune fails.
-- PORT NOTE: PC scales via SMODS.scale_card, which the fork does not list;
-- the same addition is done directly on card.ability. PC's return of
-- (nil, true) after scaling becomes a message-only return, which the fork
-- counts as this Joker triggering.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "wheelhope",
    loc_txt = {
        name = "Wheel of Hope",
        text = {
            "This Joker gains",
            "{X:mult,C:white} X#1# {} Mult when failing",
            "a {C:attention}Wheel of Fortune{}",
            "{C:inactive}(Currently {X:mult,C:white} X#2# {C:inactive} Mult)",
        },
    },
    config = { extra = { extra = 0.5, x_mult = 1 } },
    rarity = 2,
    cost = 5,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    sprite = "wheelhope.png",
    negative_sprite = "wheelhope_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.extra, card.ability.extra.x_mult } }
    end,
    calculate = function(self, card, context)
        if context.joker_main and card.ability.extra.x_mult > 1 then
            return { xmult = card.ability.extra.x_mult }
        end
        if context.pseudorandom_result and not context.result
            and context.identifier == "wheel_of_fortune" then
            card.ability.extra.x_mult = card.ability.extra.x_mult
                + card.ability.extra.extra
            return { message = "Upgrade!" }
        end
    end,
}

--------------------------------------------------------------------------------
-- Bus Driver: 3 in 4 chance for +50 Mult, 1 in 4 chance for -50 Mult.
-- PORT NOTE: PC's cry_prob roll is rewritten as a 1-in-4
-- SMODS.pseudorandom_probability roll for the -50 branch (the complement
-- of PC's success roll); forcetrigger branch dropped.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "busdriver",
    loc_txt = {
        name = "Bus Driver",
        text = {
            "{C:green}#1# in #3#{} chance",
            "for {C:mult}+#2#{} Mult",
            "{C:green}#4# in #3#{} chance",
            "for {C:mult}-#2#{} Mult",
        },
    },
    config = { extra = { mult = 50, odds = 4 } },
    rarity = 2,
    cost = 7,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "busdriver.png",
    negative_sprite = "busdriver_negative.png",
    loc_vars = function(self, info_queue, card)
        local num, den = SMODS.get_probability_vars(card, 1, card.ability.extra.odds, "busdriver")
        return { vars = { den - num, card.ability.extra.mult, den, num } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            local hit = SMODS.pseudorandom_probability(card, "busdriver", 1, card.ability.extra.odds, "busdriver")
            if hit then
                return { mult = -card.ability.extra.mult }
            end
            return { mult = card.ability.extra.mult }
        end
    end,
}

--------------------------------------------------------------------------------
-- Translucent Joker: sell this card to create a Perishable copy of a
-- random other Joker.
-- PORT NOTE: the Banana sticker half of "Banana Perishable" is dropped
-- (the fork has no Banana sticker); the copy is Perishable only, made
-- with SMODS.add_card (bypass_limit, since this Joker's own slot is
-- being vacated) and flagged perishable directly, following the
-- sibling packs' sticker-field precedent. Copy is a fresh copy (its
-- ability values are not cloned; the fork has no copy_card).
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "translucent",
    loc_txt = {
        name = "Translucent Joker",
        text = {
            "Sell this card to create",
            "a {C:attention}Perishable{} copy",
            "of a random {C:attention}Joker{}",
            "{C:inactive}(Copy bypasses perish compat)",
        },
    },
    config = { extra = {} },
    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = false,
    perishable_compat = true,
    sprite = "translucent.png",
    negative_sprite = "translucent_negative.png",
    calculate = function(self, card, context)
        if context.selling_card and context.selling_self and G then
            local pool = {}
            for _, j in ipairs(G.jokers or {}) do
                if j ~= card then pool[#pool + 1] = j end
            end
            if #pool == 0 then return nil end
            local pick = pool[SMODS.pseudorandom("cryp_translucent", 1, #pool)]
            local def_id = pick and ((pick.def and pick.def.id) or pick.def_id)
            if not def_id then return nil end
            local edition = pick.edition
            if edition ~= "foil" and edition ~= "holo"
                and edition ~= "polychrome" and edition ~= "negative" then
                edition = nil
            end
            local created = SMODS.add_card { set = "Joker", key = def_id, edition = edition, bypass_limit = true }
            if created then
                created.perishable = true
                created.perishable_counter = 5
                return { message = "Duplicated!" }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Morse Code: earn $1 at end of round; payout grows by $2 whenever a
-- card with an Edition is sold.
-- PORT NOTE: the fork's selling_card context only covers sold Jokers,
-- so the growth trigger is an editioned Joker sale (PC counts any
-- editioned card sold).
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "morse",
    loc_txt = {
        name = "Morse Code",
        text = {
            "Earn {C:money}$#2#{} at end of round",
            "Increase payout by {C:money}$#1#{} when",
            "a card with an {C:attention}Edition{} is sold",
        },
    },
    config = { extra = { bonus = 2, money = 1 } },
    rarity = 1,
    cost = 5,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = false,
    sprite = "morse.png",
    negative_sprite = "morse_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.bonus, card.ability.extra.money } }
    end,
    calculate = function(self, card, context)
        if context.selling_card and not context.blueprint then
            local sold = context.card or (context.port and context.port.joker)
            if sold and sold.edition and sold.edition ~= "base" then
                card.ability.extra.money = card.ability.extra.money + card.ability.extra.bonus
                return { message = localize("k_upgrade_ex") }
            end
        end
    end,
    calc_dollar_bonus = function(self, card)
        if card.ability.extra.money > 0 then
            return card.ability.extra.money
        end
    end,
}

--------------------------------------------------------------------------------
-- Kaleidoscope: add Polychrome to a random uneditioned Joker when a
-- Boss Blind is defeated.
-- PORT NOTE: boss check uses the fork's blind index (3 = Boss, via
-- context.port or G.current_blind_index, the sibling-pack pattern);
-- the edition is set by direct field assignment, the fork's precedent
-- for re-editioning a held Joker.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "kscope",
    loc_txt = {
        name = "Kaleidoscope",
        text = {
            "Add {C:purple}Polychrome{} to",
            "a random {C:attention}Joker{} when",
            "{C:attention}Boss Blind{} is defeated",
        },
    },
    config = { extra = {} },
    rarity = 3,
    cost = 7,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "kscope.png",
    negative_sprite = "kscope_negative.png",
    calculate = function(self, card, context)
        if context.end_of_round and not context.blueprint and G then
            local idx = (context.port and context.port.blind_index) or G.current_blind_index
            if idx ~= 3 then return nil end
            local pool = {}
            for _, j in ipairs(G.jokers or {}) do
                if j ~= card and (j.edition == nil or j.edition == "base") then
                    pool[#pool + 1] = j
                end
            end
            if #pool == 0 then return nil end
            local pick = pool[SMODS.pseudorandom("cryp_kscope", 1, #pool)]
            if pick then
                pick.edition = "polychrome"
                return { message = "Polychrome!" }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- M Chain: sell this card to add $1 of sell value to every Joker.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "cryptidmoment",
    loc_txt = {
        name = "M Chain",
        text = {
            "Sell this card to",
            "add {C:money}$#1#{} of {C:attention}sell value{}",
            "to every {C:attention}Joker{} card",
        },
    },
    config = { extra = { money = 1, max_added_val = 1 } },
    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = false,
    perishable_compat = true,
    sprite = "cryptidmoment.png",
    negative_sprite = "cryptidmoment_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { math.max(card.ability.extra.max_added_val, math.floor(card.ability.extra.money)) } }
    end,
    calculate = function(self, card, context)
        if context.selling_card and context.selling_self and G then
            local amt = math.max(card.ability.extra.max_added_val, math.floor(card.ability.extra.money))
            for _, j in ipairs(G.jokers or {}) do
                if tonumber(j.sell_cost) then
                    j.sell_cost = j.sell_cost + amt
                end
            end
            return { message = "Value Up!" }
        end
    end,
}

--------------------------------------------------------------------------------
-- Nostalgic Invisible Joker: duplicate a random Joker every 4 Joker
-- cards sold (this Joker excluded).
-- PORT NOTE: the copy is created with SMODS.add_card from the chosen
-- Joker's def id (fresh ability values; the fork has no copy_card),
-- keeping the chosen Joker's edition when it is a fork edition.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "oldinvisible",
    loc_txt = {
        name = "Nostalgic Invisible Joker",
        text = {
            "{C:attention}Duplicate{} a random",
            "{C:attention}Joker{} every {C:attention}4{}",
            "Joker cards sold",
            "{C:inactive}Nostalgic Invisible Joker Excluded{}",
            "{C:inactive}(Currently #1#/4){}",
        },
    },
    config = { extra = { sold = 0 } },
    rarity = 4,
    cost = 20,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "oldinvisible.png",
    negative_sprite = "oldinvisible_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.sold } }
    end,
    calculate = function(self, card, context)
        if context.selling_card and not context.blueprint and G then
            local sold_card = context.card or (context.port and context.port.joker)
            if card.ability.extra.sold >= 3 then
                card.ability.extra.sold = 0
                local own_id = card.def and card.def.id
                local pool = {}
                for _, j in ipairs(G.jokers or {}) do
                    local jid = (j.def and j.def.id) or j.def_id
                    if j ~= sold_card and jid and jid ~= own_id then
                        pool[#pool + 1] = j
                    end
                end
                if #pool == 0 then return nil end
                local pick = pool[SMODS.pseudorandom("cryp_oldinvisible", 1, #pool)]
                local def_id = (pick.def and pick.def.id) or pick.def_id
                local edition = pick.edition
                if edition ~= "foil" and edition ~= "holo"
                    and edition ~= "polychrome" and edition ~= "negative" then
                    edition = nil
                end
                local created = SMODS.add_card { set = "Joker", key = def_id, edition = edition }
                if created then return { message = "Duplicated!" } end
            else
                card.ability.extra.sold = card.ability.extra.sold + 1
                return { message = card.ability.extra.sold .. "/4" }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Kitty Printer: X2 Mult.
-- PORT NOTE: the "all skip tags become Cat Tags" half is dropped and
-- its description line removed: it lives in Cryptid's library tag
-- hook (Cryptid.get_next_tag) and Cat Tags are Cryptid tags, which
-- cannot be registered in the fork. Only the Joker's own calculate
-- (X2 Mult) is ported.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "kittyprinter",
    loc_txt = {
        name = "Kitty Printer",
        text = {
            "{X:mult,C:white} X#1# {} Mult",
        },
    },
    config = { extra = { Xmult = 2 } },
    rarity = 2,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "kittyprinter.png",
    negative_sprite = "kittyprinter_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.Xmult } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            return { xmult = card.ability.extra.Xmult }
        end
    end,
}

--------------------------------------------------------------------------------
-- Exposed: retrigger all scored non-face cards 2 additional times.
-- PORT NOTE: the "all face cards are debuffed" half is dropped: it
-- uses the debuff_card context, which the fork does not raise.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "exposed",
    loc_txt = {
        name = "Exposed",
        text = {
            "Retrigger all scored non-{C:attention}face{} cards",
            "{C:attention}#1#{} additional times",
        },
    },
    config = { extra = { retriggers = 2, max_retriggers = 40 } },
    rarity = 3,
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "exposed.png",
    negative_sprite = "exposed_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { math.min(card.ability.extra.max_retriggers, card.ability.extra.retriggers) } }
    end,
    calculate = function(self, card, context)
        if context.repetition and context.cardarea == G.play and context.other_card then
            if not context.other_card:is_face() then
                return {
                    repetitions = math.min(card.ability.extra.max_retriggers, card.ability.extra.retriggers),
                }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Mask: retrigger all scored face cards 3 additional times.
-- PORT NOTE: the "all non-face cards are debuffed" half is dropped:
-- it uses the debuff_card context, which the fork does not raise.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "mask",
    loc_txt = {
        name = "Mask",
        text = {
            "Retrigger all scored {C:attention}face{} cards",
            "{C:attention}#1#{} additional times",
        },
    },
    config = { extra = { retriggers = 3, max_retriggers = 40 } },
    rarity = 3,
    cost = 7,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "mask.png",
    negative_sprite = "mask_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { math.min(card.ability.extra.max_retriggers, card.ability.extra.retriggers) } }
    end,
    calculate = function(self, card, context)
        if context.repetition and context.cardarea == G.play and context.other_card then
            if context.other_card:is_face() then
                return {
                    repetitions = math.min(card.ability.extra.max_retriggers, card.ability.extra.retriggers),
                }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Clicked Cookie: +200 Chips.
-- PORT NOTE: the -1 Chips per click decay is dropped: it uses the
-- Cryptid-specific cry_press context (clicking the Joker), which the
-- fork does not raise. The description is trimmed to the Chips line.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "clicked_cookie",
    loc_txt = {
        name = "Clicked Cookie",
        text = {
            "{C:chips}+#1#{} Chips",
        },
    },
    config = { extra = { chips = 200, chip_mod = 1 } },
    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = false,
    perishable_compat = false,
    sprite = "clicked_cookie.png",
    negative_sprite = "clicked_cookie_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chips, card.ability.extra.chip_mod } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            return { chips = card.ability.extra.chips }
        end
    end,
}

--------------------------------------------------------------------------------
-- Tax Fraud: gain $6 per Rental Joker at end of round.
-- PORT NOTE: PC counts rentals through Cryptid.advanced_find_joker;
-- the fork exposes the rental sticker as a plain field on held Joker
-- instances, counted directly. PC's in_pool gate (rentals enabled in
-- shop) is dropped: the fork exposes no such modifier flag.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "tax_fraud",
    loc_txt = {
        name = "Tax Fraud",
        text = {
            "Gain {C:attention}$#1#{} per {C:attention}Rental Joker{}",
            "at end of round",
        },
    },
    config = { extra = { money = 6 } },
    rarity = 3,
    cost = 10,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "tax_fraud.png",
    negative_sprite = "tax_fraud_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.money } }
    end,
    calc_dollar_bonus = function(self, card)
        if not G then return nil end
        local rentals = 0
        for _, j in ipairs(G.jokers or {}) do
            if j.rental then rentals = rentals + 1 end
        end
        if rentals > 0 then
            return card.ability.extra.money * rentals
        end
    end,
}

--------------------------------------------------------------------------------
-- Zooble: if the played hand does not contain a Straight, this Joker
-- gains +1 Mult for every unique rank in the scoring hand.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "zooble",
    loc_txt = {
        name = "Zooble",
        text = {
            "If played hand does",
            "{C:attention}not{} contain a {C:attention}Straight{},",
            "this Joker gains {C:mult}+#2#{} Mult for every",
            "{C:attention}unique rank{} in scoring hand",
            "{C:inactive}(Currently {C:mult}+#1#{C:inactive} Mult)",
        },
    },
    config = { extra = { mult = 0, a_mult = 1 } },
    rarity = 2,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "zooble.png",
    negative_sprite = "zooble_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult, card.ability.extra.a_mult } }
    end,
    calculate = function(self, card, context)
        if context.before and not context.blueprint and context.scoring_hand then
            if context.poker_hands and not next(context.poker_hands["Straight"]) then
                local seen = {}
                local unique = 0
                for _, v in ipairs(context.scoring_hand) do
                    local data = v.card_data or {}
                    if data.enhancement ~= "stone" then
                        local id = v:get_id()
                        if id and not seen[id] then
                            seen[id] = true
                            unique = unique + 1
                        end
                    end
                end
                if unique >= 1 then
                    card.ability.extra.mult = card.ability.extra.mult
                        + card.ability.extra.a_mult * unique
                    return { message = localize("k_upgrade_ex") }
                end
            end
        end
        if context.joker_main and card.ability.extra.mult > 0 then
            return { mult = card.ability.extra.mult }
        end
    end,
}

--------------------------------------------------------------------------------
-- LeBaron James: played and scoring Kings give +1 hand size for the
-- round.
-- PORT NOTE: PC also makes scored Kings trigger held-in-hand effects
-- by hooking SMODS.score_card; that half is dropped (no such hook in
-- the fork). Hand size rides the fork's declarative h_size modifier
-- on this Joker's ability (the sibling packs' dynamic-h_size
-- pattern), accumulated per scoring King and reset at end of round.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "lebaron_james",
    loc_txt = {
        name = "LeBaron James",
        text = {
            "Played and scoring {C:attention}Kings{} give",
            "{C:attention}+#1#{} hand size for the round",
            "{C:inactive}(Currently {C:attention}+#2#{C:inactive})",
        },
    },
    config = { h_size = 0, extra = { h_mod = 1, added_h = 0, max_h_mod = 1000 } },
    rarity = 3,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "lebaron_james.png",
    negative_sprite = "lebaron_james_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.h_mod, card.ability.extra.added_h } }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play and context.other_card then
            if context.other_card:get_id() == 13 then
                local extra = card.ability.extra
                local add = math.min(extra.h_mod, extra.max_h_mod - extra.added_h)
                if add > 0 then
                    extra.added_h = extra.added_h + add
                    card.ability.h_size = extra.added_h
                    return { message = "+1 Hand Size" }
                end
            end
        end
        if context.end_of_round then
            card.ability.extra.added_h = 0
            card.ability.h_size = 0
        end
    end,
}

--------------------------------------------------------------------------------
-- Eye of Hagane: all played face cards become Steel cards when scored.
-- PORT NOTE: PC swaps the card's center via set_ability; the fork has
-- no enhancement-swap API for a live card, so the card's card_data
-- enhancement is rewritten directly in context.before (the sibling
-- packs' direct card_data rewrite pattern), before scoring reads it.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "eyeofhagane",
    loc_txt = {
        name = "Eye of Hagane",
        text = {
            "All played {C:attention}face{} cards",
            "become {C:attention}Steel{} cards",
            "when scored",
        },
    },
    config = { extra = {} },
    rarity = 2,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "eyeofhagane.png",
    negative_sprite = "eyeofhagane_negative.png",
    calculate = function(self, card, context)
        if context.before and context.scoring_hand then
            local changed = false
            for _, v in ipairs(context.scoring_hand) do
                local id = v:get_id()
                if id and id >= 11 and id <= 13 and v.card_data then
                    v.card_data.enhancement = "steel"
                    changed = true
                end
            end
            if changed then return { message = "Steel!" } end
        end
    end,
}

--------------------------------------------------------------------------------
-- High Five: if the highest scoring rank is 5, convert all scoring
-- cards into 5s (Aces are considered 1).
-- PORT NOTE: PC converts via SMODS.change_base in
-- final_scoring_step; the fork has no rank-change API, so the cards'
-- card_data rank/chips are rewritten directly (the sibling packs'
-- pattern). As on PC, the conversion is permanent and happens after
-- the cards have scored.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "highfive",
    loc_txt = {
        name = "High Five",
        text = {
            "If highest {C:attention}scoring rank{}",
            "is {C:attention}5{}, convert {C:attention}all{} scoring cards",
            "into {C:attention}5{}s",
            "{C:inactive}Aces are considered 1",
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
    sprite = "highfive.png",
    negative_sprite = "highfive_negative.png",
    calculate = function(self, card, context)
        if context.final_scoring_step and context.scoring_hand then
            local maximum = -1
            local fives = 0
            for _, v in ipairs(context.scoring_hand) do
                local data = v.card_data or {}
                if data.enhancement ~= "stone" then
                    local id = v:get_id()
                    local thunk = id == 14 and 1 or id
                    if thunk == 5 then fives = fives + 1 end
                    if thunk and thunk > maximum then maximum = thunk end
                end
            end
            if maximum == 5 and fives ~= #context.scoring_hand then
                local changed = false
                for _, v in ipairs(context.scoring_hand) do
                    local data = v.card_data or {}
                    if data.enhancement ~= "stone" and v:get_id() ~= 5 and v.card_data then
                        v.card_data.rank = 5
                        v.card_data.chips = 5
                        changed = true
                    end
                end
                if changed then return { message = "High Five!" } end
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Broken Home: X11.4 Mult; 1 in 4 chance this card is destroyed at
-- end of round.
-- PORT NOTE: PC destroys itself through an event queue; the fork
-- uses SMODS.destroy_joker directly in end_of_round.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "brokenhome",
    loc_txt = {
        name = "Broken Home",
        text = {
            "{X:mult,C:white} X#1# {} Mult",
            "{C:green}#2# in #3#{} chance this",
            "card is destroyed",
            "at end of round",
        },
    },
    config = { extra = { Xmult = 11.4, odds = 4 } },
    rarity = 3,
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = false,
    perishable_compat = true,
    sprite = "brokenhome.png",
    negative_sprite = "brokenhome_negative.png",
    loc_vars = function(self, info_queue, card)
        local num, den = SMODS.get_probability_vars(card, 1, card.ability.extra.odds, "brokenhome")
        return { vars = { card.ability.extra.Xmult, num, den } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            return { xmult = card.ability.extra.Xmult }
        end
        if context.end_of_round and not context.blueprint then
            if SMODS.pseudorandom_probability(card, "brokenhome", 1, card.ability.extra.odds, "brokenhome") then
                SMODS.destroy_joker(card)
                return { message = "Divorced!" }
            end
            return { message = "Safe!" }
        end
    end,
}

--------------------------------------------------------------------------------
-- Pizza: after 3 rounds, sell this Joker to create 6 Pizza Slices.
-- PORT NOTE: slices are created with SMODS.add_card under this
-- pack's id (j_cryp_pizza_slice; PC creates j_cry_pizza_slice). PC
-- pre-computes room including the slot Pizza itself vacates; the
-- fork's add_card returns nil at the limit, so a full board can
-- yield one fewer slice than PC.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "pizza",
    loc_txt = {
        name = "Pizza",
        text = {
            "After {C:attention}#1#{} {C:inactive}[#2#]{} rounds",
            "sell this Joker to create",
            "{C:attention}#3#{} Pizza Slices",
        },
    },
    config = { extra = { rounds_needed = 3, rounds_left = 3, slices = 6, max_spawn = 100 } },
    rarity = 3,
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = false,
    perishable_compat = true,
    sprite = "pizza.png",
    negative_sprite = "pizza_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = {
            card.ability.extra.rounds_needed,
            card.ability.extra.rounds_left,
            math.min(card.ability.extra.slices, card.ability.extra.max_spawn),
        } }
    end,
    calculate = function(self, card, context)
        if context.end_of_round and not context.blueprint then
            local extra = card.ability.extra
            extra.rounds_left = extra.rounds_left - 1
            if extra.rounds_left < 0 then extra.rounds_left = 0 end
            return {
                message = (extra.rounds_needed - extra.rounds_left) .. "/" .. extra.rounds_needed,
            }
        end
        if context.selling_card and context.selling_self then
            if card.ability.extra.rounds_left <= 0 then
                local made = 0
                for _ = 1, math.min(card.ability.extra.slices, card.ability.extra.max_spawn) do
                    local created = SMODS.add_card { set = "Joker", key = "j_cryp_pizza_slice" }
                    if not created then break end
                    made = made + 1
                end
                if made > 0 then return { message = "Pizza!" } end
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Pizza Slice: this Joker gains X0.5 Mult when a Pizza Slice is sold
-- (currently X1 Mult). Never appears in pools (created by Pizza).
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "pizza_slice",
    loc_txt = {
        name = "Pizza Slice",
        text = {
            "This Joker gains {X:mult,C:white}X#1#{} Mult",
            "when a {C:attention}Pizza Slice{} is sold",
            "{C:inactive}(Currently {X:mult,C:white}X#2#{C:inactive} Mult)",
        },
    },
    config = { extra = { xmult = 1, xmult_mod = 0.5 } },
    rarity = 3,
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = false,
    perishable_compat = true,
    sprite = "pizza_slice.png",
    negative_sprite = "pizza_slice_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.xmult_mod, card.ability.extra.xmult } }
    end,
    in_pool = function(self, args)
        return false
    end,
    calculate = function(self, card, context)
        if context.selling_card then
            local sold = context.card or (context.port and context.port.joker)
            local sold_id = sold and ((sold.def and sold.def.id) or sold.def_id)
            if sold and sold ~= card and sold_id == "j_cryp_pizza_slice" then
                card.ability.extra.xmult = card.ability.extra.xmult + card.ability.extra.xmult_mod
                return { message = localize("k_upgrade_ex") }
            end
        end
        if context.joker_main then
            return { xmult = card.ability.extra.xmult }
        end
    end,
}

--------------------------------------------------------------------------------
-- Fading Joker: this Joker gains X1 Mult whenever a Perishable card
-- is debuffed (currently X1 Mult).
-- PORT NOTE: PC hooks Card:calculate_perishable to raise a custom
-- context at the moment of debuff; the fork raises nothing there, so
-- the port polls held Jokers at end of round and blind selection and
-- scales by the increase in debuffed-Perishable count (a debuff can
-- register up to a round later than on PC, but is never lost or
-- double-counted).
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "fading_joker",
    loc_txt = {
        name = "Fading Joker",
        text = {
            "This Joker gains",
            "{X:mult,C:white}X#1#{} Mult whenever",
            "a {C:attention}Perishable{} card is debuffed",
            "{C:inactive}(Currently {X:mult,C:white}X#2#{C:inactive} Mult)",
        },
    },
    config = { extra = { xmult = 1, xmult_mod = 1, debuffed_seen = 0 } },
    rarity = 2,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "fading_joker.png",
    negative_sprite = "fading_joker_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.xmult_mod, card.ability.extra.xmult } }
    end,
    in_pool = function(self, args)
        if G and G.jokers then
            for _, j in ipairs(G.jokers) do
                if j.perishable then return true end
            end
        end
        return false
    end,
    calculate = function(self, card, context)
        local function poll_debuffed()
            if not G then return end
            local n = 0
            for _, j in ipairs(G.jokers or {}) do
                if j.perishable and (j.perishable_debuffed == true
                    or (tonumber(j.perishable_counter) or 5) <= 0) then
                    n = n + 1
                end
            end
            local extra = card.ability.extra
            if n > extra.debuffed_seen then
                extra.xmult = extra.xmult + extra.xmult_mod * (n - extra.debuffed_seen)
            end
            extra.debuffed_seen = n
        end
        if (context.end_of_round or context.setting_blind) and not context.blueprint then
            poll_debuffed()
        end
        if context.joker_main then
            return { xmult = card.ability.extra.xmult }
        end
    end,
}

--------------------------------------------------------------------------------
-- Poor Joker: this Joker gains +4 Mult whenever a Rental card takes
-- money (currently +0 Mult).
-- PORT NOTE: PC hooks Card:calculate_rental to raise a custom
-- context per rental payment; the fork raises nothing there, so the
-- port counts held Rental Jokers at end of round (each Rental takes
-- its $3 at round end in the fork) and scales once per Rental.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "poor_joker",
    loc_txt = {
        name = "Poor Joker",
        text = {
            "This Joker gains",
            "{C:mult}+#1#{} Mult whenever",
            "a {C:attention}Rental{} card takes money",
            "{C:inactive}(Currently {C:mult}+#2#{C:inactive} Mult)",
        },
    },
    config = { extra = { mult = 0, mult_mod = 4 } },
    rarity = 2,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "poor_joker.png",
    negative_sprite = "poor_joker_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult_mod, card.ability.extra.mult } }
    end,
    in_pool = function(self, args)
        if G and G.jokers then
            for _, j in ipairs(G.jokers) do
                if j.rental then return true end
            end
        end
        return false
    end,
    calculate = function(self, card, context)
        if context.end_of_round and not context.blueprint and G then
            local rentals = 0
            for _, j in ipairs(G.jokers or {}) do
                if j.rental then rentals = rentals + 1 end
            end
            if rentals > 0 then
                card.ability.extra.mult = card.ability.extra.mult
                    + card.ability.extra.mult_mod * rentals
                return { message = localize("k_upgrade_ex") }
            end
        end
        if context.joker_main and card.ability.extra.mult > 0 then
            return { mult = card.ability.extra.mult }
        end
    end,
}

--------------------------------------------------------------------------------
-- Thalia and Melpomeme: X1 Mult for every unique pair of held
-- rarities (n rarities give n*(n-1)/2 pairs).
-- PORT NOTE: PC reads each held Joker's center rarity; the fork
-- carries rarity on the held Joker instance, counted directly.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "thalia",
    loc_txt = {
        name = "Thalia and Melpomeme",
        text = {
            "{X:mult,C:white}X#1#{} Mult for every",
            "{C:attention}unique pair{} of",
            "{C:attention}held rarities{}",
            "{C:inactive}(Currently {X:mult,C:white}X#2#{C:inactive} Mult)",
        },
    },
    config = { extra = { xmgain = 1 } },
    rarity = 4,
    cost = 20,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "thalia.png",
    soul_sprite = "thalia_soul.png",
    negative_sprite = "thalia_negative.png",
    loc_vars = function(self, info_queue, card)
        local seen = {}
        if G then
            for _, j in ipairs(G.jokers or {}) do
                local r = j.rarity or (j.def and j.def.rarity)
                if r then seen[r] = true end
            end
        end
        local n = 0
        for _ in pairs(seen) do n = n + 1 end
        local bonus = (n * (n - 1)) / 2
        local current = bonus < 1 and 1 or bonus * card.ability.extra.xmgain
        return { vars = { card.ability.extra.xmgain, current } }
    end,
    calculate = function(self, card, context)
        if context.joker_main and G then
            local seen = {}
            for _, j in ipairs(G.jokers or {}) do
                local r = j.rarity or (j.def and j.def.rarity)
                if r then seen[r] = true end
            end
            local n = 0
            for _ in pairs(seen) do n = n + 1 end
            local bonus = (n * (n - 1)) / 2
            local current = bonus < 1 and 1 or bonus * card.ability.extra.xmgain
            return { xmult = current }
        end
    end,
}

--------------------------------------------------------------------------------
-- Key Change: gains X0.25 Mult if the played poker hand has not been
-- played this round; resets at end of round.
-- PORT NOTE: PC reads G.GAME.hands[name].played_this_round; the fork
-- has no per-round per-hand play count by name, so this Joker tracks
-- the hand names it has seen in context.before itself (first play of
-- each hand type per round gains, exactly PC's played_this_round < 2
-- test at before-time) and clears the record when its XMult resets.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "keychange",
    loc_txt = {
        name = "Key Change",
        text = {
            "Gains {X:mult,C:white}X#1#{} if {C:attention}poker hand{} has",
            "not been played this round",
            "Resets at {C:attention}end of round{}",
            "{C:inactive}(Currently {X:mult,C:white}X#2#{C:inactive})",
        },
    },
    config = { extra = { xm = 1, xmgain = 0.25, played = {} } },
    rarity = 2,
    cost = 5,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "keychange.png",
    negative_sprite = "keychange_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.xmgain, card.ability.extra.xm } }
    end,
    calculate = function(self, card, context)
        if context.before and context.scoring_name then
            local played = card.ability.extra.played
            if not played[context.scoring_name] then
                played[context.scoring_name] = true
                card.ability.extra.xm = card.ability.extra.xm + card.ability.extra.xmgain
                return { message = localize("k_upgrade_ex") }
            end
        end
        if context.joker_main then
            return { xmult = card.ability.extra.xm }
        end
        if context.end_of_round and not context.blueprint then
            card.ability.extra.xm = 1
            card.ability.extra.played = {}
        end
    end,
}

--------------------------------------------------------------------------------
-- Slice D helpers (crypd_ prefix: fragments are assembled into one file).
--------------------------------------------------------------------------------

local function crypd_held_jokers()
    if not (G and G.jokers) then return {} end
    local list = G.jokers.cards or G.jokers
    if type(list) ~= "table" then return {} end
    return list
end

local function crypd_joker_rarity(j)
    if type(j) ~= "table" then return nil end
    local r = tonumber(j.rarity)
    if r then return r end
    if j.def then return tonumber(j.def.rarity) end
    return nil
end

--------------------------------------------------------------------------------
-- Negative Joker: +4 Joker slots while held.
-- PORT NOTE: PC uses add_to_deck/remove_from_deck with
-- G.jokers:change_size; the fork's held-Joker config field joker_slots
-- is the same effect. The PC cap of 100 slots (immutable.max_slots) is
-- dropped; no fork equivalent.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "negative",
    loc_txt = {
        name = "Negative Joker",
        text = {
            "{C:purple}+#1#{} {C:attention}Joker{} slots",
        },
    },
    config = { extra = { slots = 4 }, joker_slots = 4 },
    rarity = "epic",
    cost = 10,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "negative.png",
    negative_sprite = "negative_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.slots } }
    end,
}

--------------------------------------------------------------------------------
-- Canvas: retrigger all Jokers to the left once for every non-Common
-- Joker to the right of this Joker.
-- PORT NOTE: PC reads card.rank / card.area.cards and v:is_rarity(1);
-- the port reads position and rarity from the G.jokers list (instance
-- .rarity, falling back to def.rarity), the sibling-pack pattern. The
-- modest-gameset cap of 2 retriggers and its candy-rarity exception are
-- gameset branches and are dropped (mainline config has no cap).
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "canvas",
    loc_txt = {
        name = "Canvas",
        text = {
            "{C:attention}Retrigger{} all {C:attention}Jokers{} to the left",
            "once for {C:attention}every{} non-{C:purple}Common{} {C:attention}Joker{}",
            "to the right of this Joker",
        },
    },
    config = { extra = {} },
    rarity = "epic",
    cost = 18,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "canvas.png",
    negative_sprite = "canvas_negative.png",
    calculate = function(self, card, context)
        if context.retrigger_joker_check and not context.retrigger_joker
            and context.other_card and context.other_card ~= card then
            local list = crypd_held_jokers()
            local my_idx, other_idx = nil, nil
            for i, j in ipairs(list) do
                if j == card then my_idx = i end
                if j == context.other_card then other_idx = i end
            end
            if my_idx and other_idx and other_idx < my_idx then
                local count = 0
                for i = my_idx + 1, #list do
                    local r = crypd_joker_rarity(list[i])
                    if r and r ~= 1 then count = count + 1 end
                end
                if count > 0 then
                    return { repetitions = count }
                end
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- m: gains X13 Mult when Jolly Joker is sold (starts at X1).
-- PORT NOTE: PC scales via SMODS.scale_card (scalar add of extra=13 to
-- x_mult); the port does the same addition directly. The sold Joker is
-- identified by context.card's def id (j_jolly), the sibling-pack
-- pattern for selling_card.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "m",
    loc_txt = {
        name = "m",
        text = {
            "This Joker gains {X:mult,C:white} X#1# {} Mult",
            "when {C:attention}Jolly Joker{} is sold",
            "{C:inactive}(Currently {X:mult,C:white} X#2# {C:inactive} Mult)",
        },
    },
    config = { extra = { extra = 13, x_mult = 1 } },
    rarity = "epic",
    cost = 13,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    sprite = "m.png",
    negative_sprite = "m_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.extra, card.ability.extra.x_mult } }
    end,
    calculate = function(self, card, context)
        if context.joker_main and card.ability.extra.x_mult > 1 then
            return { xmult = card.ability.extra.x_mult }
        end
        if context.selling_card and not context.blueprint and context.card then
            local sold = context.card
            if sold.def and sold.def.id == "j_jolly" then
                card.ability.extra.x_mult = card.ability.extra.x_mult
                    + card.ability.extra.extra
                return { message = localize("k_upgrade_ex") }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- M: create a Negative Jolly Joker when Blind is selected.
-- PORT NOTE: PC create_card + set_edition(negative) becomes one
-- SMODS.add_card call; if there is no room it returns nil and nothing
-- is created, as on PC.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "M",
    loc_txt = {
        name = "M",
        text = {
            "Create a {C:purple}Negative{}",
            "{C:attention}Jolly Joker{} when",
            "{C:attention}Blind{} is selected",
        },
    },
    config = { extra = {} },
    rarity = "epic",
    cost = 13,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "M.png",
    negative_sprite = "M_negative.png",
    calculate = function(self, card, context)
        if context.setting_blind then
            local made = SMODS.add_card {
                set = "Joker", key = "j_jolly", edition = "negative",
            }
            if made then
                return { message = "Created!" }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Boredom: 1 in 2 chance to retrigger each Joker or played card.
-- PORT NOTE: PC rolls SMODS.pseudorandom_probability in both the
-- retrigger_joker_check and repetition contexts; same here (hit only,
-- the sibling-pack pattern). PC excludes Boredom by center key; the
-- port excludes any Joker whose def id is this one, plus itself.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "boredom",
    loc_txt = {
        name = "Boredom",
        text = {
            "{C:green}#1# in #2#{} chance to",
            "{C:attention}retrigger{} each {C:attention}Joker{}",
            "or {C:attention}played card{}",
            "{C:inactive}Does not affect other Boredom{}",
        },
    },
    config = { extra = { odds = 2 } },
    rarity = "epic",
    cost = 14,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "boredom.png",
    negative_sprite = "boredom_negative.png",
    loc_vars = function(self, info_queue, card)
        local num, den = SMODS.get_probability_vars(
            card, 1, card.ability.extra.odds, "Boredom")
        return { vars = { num, den } }
    end,
    calculate = function(self, card, context)
        if context.retrigger_joker_check and not context.retrigger_joker
            and context.other_card and context.other_card ~= card then
            local oc = context.other_card
            if not (oc.def and oc.def.id == "j_cryp_boredom") then
                local hit = SMODS.pseudorandom_probability(
                    card, "cry_boredom_joker", 1, card.ability.extra.odds, "Boredom")
                if hit then
                    return { message = "Again!", repetitions = 1 }
                end
            end
        end
        if context.repetition and context.cardarea == G.play then
            local hit = SMODS.pseudorandom_probability(
                card, "cry_boredom_joker", 1, card.ability.extra.odds, "Boredom")
            if hit then
                return { message = "Again!", repetitions = 1 }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Circus: Rare Jokers give X2 Mult, Epic X3, Legendary X4, Exotic X20
-- (each time they trigger).
-- PORT NOTE: PC hooks context.other_joker with a rarity table built
-- from Cryptid.circus_rarities; the fork equivalent is post_trigger
-- (sibling-pack pattern). Vanilla rarities are read from the instance
-- rarity number (3 = Rare, 4 = Legendary); the custom Epic/Exotic
-- branches are keyed on the other Joker's def rarity string, since
-- their assigned numbers depend on central registration order.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "circus",
    loc_txt = {
        name = "Circus",
        text = {
            "{C:red}Rare{} Jokers each give {X:mult,C:white} X#1# {} Mult",
            "{C:purple}Epic{} Jokers each give {X:mult,C:white} X#2# {} Mult",
            "{C:attention}Legendary{} Jokers each give {X:mult,C:white} X#3# {} Mult",
            "{C:purple}Exotic{} Jokers each give {X:mult,C:white} X#4# {} Mult",
        },
    },
    config = {
        extra = {
            rare_mult = 2, epic_mult = 3, legendary_mult = 4, exotic_mult = 20,
        },
    },
    rarity = "epic",
    cost = 16,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "circus.png",
    negative_sprite = "circus_negative.png",
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        return { vars = { e.rare_mult, e.epic_mult, e.legendary_mult, e.exotic_mult } }
    end,
    calculate = function(self, card, context)
        if context.post_trigger and context.other_card
            and context.other_card ~= card then
            local oc = context.other_card
            local e = card.ability.extra
            local xmult = nil
            local dr = oc.def and oc.def.rarity
            local r = tonumber(oc.rarity) or tonumber(dr)
            local epic_i = SMODS.Rarities and SMODS.Rarities["cryp_epic"] and SMODS.Rarities["cryp_epic"].index
            local exotic_i = SMODS.Rarities and SMODS.Rarities["cryp_exotic"] and SMODS.Rarities["cryp_exotic"].index
            if exotic_i and r == exotic_i then
                xmult = e.exotic_mult
            elseif epic_i and r == epic_i then
                xmult = e.epic_mult
            elseif r == 3 then
                xmult = e.rare_mult
            elseif r == 4 then
                xmult = e.legendary_mult
            end
            if xmult then
                return { xmult = xmult }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Caramel: each scored card gives X1.75 Mult, for the next 11 rounds;
-- then it is eaten.
-- PORT NOTE: PC removes itself through a delayed event-queue
-- animation at 0 rounds; the port destroys itself on the spot with
-- SMODS.destroy_joker at end_of_round (sibling-pack pattern; the
-- fork's destroy forces past eternal, PC's remove could be refused).
-- The per-round message is plain text: PC's cry_minus_round string is
-- Cryptid localization the fork does not carry.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "caramel",
    loc_txt = {
        name = "Caramel",
        text = {
            "Each played card gives",
            "{X:mult,C:white}X#1#{} Mult when scored",
            "for the next {C:attention}#2#{} rounds",
        },
    },
    config = { extra = { x_mult = 1.75, rounds_remaining = 11 } },
    rarity = "epic",
    cost = 12,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = false,
    perishable_compat = true,
    sprite = "caramel.png",
    negative_sprite = "caramel_negative.png",
    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                card.ability.extra.x_mult,
                card.ability.extra.rounds_remaining,
            },
        }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            return { xmult = card.ability.extra.x_mult }
        end
        if context.end_of_round and not context.blueprint
            and not context.retrigger_joker then
            card.ability.extra.rounds_remaining =
                card.ability.extra.rounds_remaining - 1
            if card.ability.extra.rounds_remaining > 0 then
                return { message = "-1 Round" }
            else
                SMODS.destroy_joker(card)
                return { message = "Eaten!" }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Sob: you cannot run, you cannot hide... Creates an Obelisk on almost
-- every game action, and a Negative Obelisk when it enters the deck.
-- PORT NOTE: PC creates via create_card + G.jokers:emplace with a
-- G.GAME.joker_buffer capacity check; SMODS.add_card covers both (it
-- returns nil when there is no room). The Negative Obelisk created on
-- entry cannot carry PC's cry_absolute sticker (the fork has no
-- sticker system), so it is a plain Negative Obelisk. Selling an
-- Obelisk creates nothing, as on PC. PC's unlock check (hold an
-- Eternal Obelisk) is dropped; mod Jokers are unlocked by default.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "curse_sob",
    loc_txt = {
        name = "Sob",
        text = {
            "{C:red}you cannot{} {C:purple}run...{}",
            "{C:red}you cannot{} {C:purple}hide...{}",
            "{C:purple}you cannot escape...{}",
            "{C:inactive}(Must have room){}",
        },
    },
    config = { extra = {} },
    rarity = "epic",
    cost = 9,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "curse_sob.png",
    negative_sprite = "curse_sob_negative.png",
    add_to_deck = function(self, card, from_debuff)
        if not from_debuff then
            SMODS.add_card {
                set = "Joker", key = "j_obelisk", edition = "negative",
            }
        end
    end,
    calculate = function(self, card, context)
        if context.selling_card and context.card then
            local sold = context.card
            if sold.def and sold.def.id == "j_obelisk" then
                return
            end
        end
        if context.selling_self or context.selling_card or context.discard
            or context.reroll_shop or context.buying_card
            or context.skip_blind or context.using_consumeable
            or context.setting_blind or context.skipping_booster
            or context.open_booster then
            local made = SMODS.add_card { set = "Joker", key = "j_obelisk" }
            if made then
                return { message = "Curse!" }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Mult Joker: 1 in 3 chance for each scored Mult card to create a
-- Cryptid (the vanilla Spectral) card.
-- PORT NOTE: PC tests SMODS.has_enhancement(other_card, "m_mult");
-- the port reads other_card.card_data.enhancement (sibling-pack
-- pattern). Capacity is SMODS.add_card returning nil, replacing PC's
-- G.GAME.consumeable_buffer check and event-queue creation.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "multjoker",
    loc_txt = {
        name = "Mult Joker",
        text = {
            "{C:green}#1# in #2#{} chance for each",
            "played {C:attention}Mult{} card to create",
            "a {C:purple}Cryptid{} card when scored",
            "{C:inactive}(Must have room){}",
        },
    },
    config = { extra = { odds = 3 } },
    rarity = "epic",
    cost = 11,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "multjoker.png",
    negative_sprite = "multjoker_negative.png",
    loc_vars = function(self, info_queue, card)
        local num, den = SMODS.get_probability_vars(
            card, 1, card.ability.extra.odds, "Mult Joker")
        return { vars = { num, den } }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play
            and context.other_card then
            local enh = context.other_card.card_data
                and context.other_card.card_data.enhancement
            if enh == "mult" then
                local hit = SMODS.pseudorandom_probability(
                    card, "multjoker", 1, card.ability.extra.odds, "Mult Joker")
                if hit then
                    local made = SMODS.add_card {
                        set = "Spectral", key = "spectral_cryptid",
                    }
                    if made then
                        return { message = "+Cryptid!" }
                    end
                end
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Gold Joker: payout grows by 2% for each scored Gold card; earns
-- that percent of total money at end of round.
-- PORT NOTE: PC scales via SMODS.scale_card (scalar add); the port
-- adds percent_mod directly. PC reads G.GAME.dollars in
-- calc_dollar_bonus; the fork's equivalent is G.money.
-- Enhancement test as in Mult Joker above.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "goldjoker",
    loc_txt = {
        name = "Gold Joker",
        text = {
            "Earn {C:money}#1#%{} of total",
            "money at end of round",
            "Payout increases by {C:money}#2#%{}",
            "when each played {C:attention}Gold{}",
            "card is scored",
        },
    },
    config = { extra = { percent_mod = 2, percent = 0 } },
    rarity = "epic",
    cost = 14,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = false,
    sprite = "goldjoker.png",
    negative_sprite = "goldjoker_negative.png",
    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                card.ability.extra.percent,
                card.ability.extra.percent_mod,
            },
        }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play
            and not context.blueprint and context.other_card then
            local enh = context.other_card.card_data
                and context.other_card.card_data.enhancement
            if enh == "gold" then
                card.ability.extra.percent = card.ability.extra.percent
                    + card.ability.extra.percent_mod
                return { message = localize("k_upgrade_ex") }
            end
        end
    end,
    calc_dollar_bonus = function(self, card)
        local money = (G and G.money) or 0
        local bonus = math.floor(0.01 * card.ability.extra.percent * money)
        if bonus > 0 then
            return bonus
        end
    end,
}

--------------------------------------------------------------------------------
-- One for All (PC key soccer): +1 Joker slot, +1 hand size,
-- +1 consumable slot while held.
-- PORT NOTE: the three held-size effects are fork config fields. PC
-- also gives +1 Booster Pack slot, +1 card in shop and +1 voucher
-- slot via change_size / SMODS.change_booster_limit /
-- SMODS.change_voucher_limit; the fork has no config field or API
-- for those three, so they are dropped (see notes_D.md). PC's unlock
-- check (win a run playing only High Card) is dropped; mod Jokers
-- are unlocked by default.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "soccer",
    loc_txt = {
        name = "One for All",
        text = {
            "{C:attention}+#1#{} Joker slot",
            "{C:attention}+#1#{} hand size",
            "{C:attention}+#1#{} consumable slot",
        },
    },
    config = {
        extra = { holygrail = 1 },
        joker_slots = 1,
        consumable_slots = 1,
        h_size = 1,
    },
    rarity = "epic",
    cost = 20,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "soccer.png",
    negative_sprite = "soccer_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.holygrail } }
    end,
}

--------------------------------------------------------------------------------
-- Demicolon: force-trigger the Joker to the right.
-- PORT NOTE: PC uses Cryptid.forcetrigger plus the
-- demicoloncompat/forcetriggerVanillaCheck allowlists. The fork has
-- no force-trigger, but its retrigger_joker return runs the named
-- Joker's effect once more inside this Joker's joker_main beat,
-- which is the same net result for a right neighbour (it also runs
-- on its own turn). The allowlist is dropped: a neighbour with no
-- joker_main effect simply returns nothing. PC's compatibility
-- tooltip (loc_vars UI nodes) is dropped.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "demicolon",
    loc_txt = {
        name = "Demicolon",
        text = {
            "{C:attention}Force-trigger{} the Joker",
            "to the right",
        },
    },
    config = { extra = {} },
    rarity = "epic",
    cost = 14,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "demicolon.png",
    negative_sprite = "demicolon_negative.png",
    calculate = function(self, card, context)
        if context.joker_main and not context.blueprint then
            local list = crypd_held_jokers()
            for i, j in ipairs(list) do
                if j == card then
                    local nxt = list[i + 1]
                    if nxt then
                        return {
                            message = "Demicolon!",
                            retrigger_joker = nxt,
                        }
                    end
                end
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Iterum: retrigger all played cards #2# times; each played card gives
-- X2 Mult when scored.
-- PORT NOTE: the PC forcetrigger branch is dropped (demicolon system).
-- PORT NOTE: PC's immutable max_repetitions cap (40) is folded into extra.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "iterum",
    loc_txt = {
        name = "Iterum",
        text = {
            "Retrigger all cards played",
            "{C:attention}#2#{} time,",
            "each played card gives",
            "{X:mult,C:white} X#1# {} Mult when scored",
            "{C:inactive}(Max {}{C:attention}#3#{}{C:inactive} retriggers)",
        },
    },
    config = { extra = { x_mult = 2, repetitions = 1, max_repetitions = 40 } },
    rarity = "exotic",
    cost = 50,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "iterum.png",
    soul_sprite = "iterum_soul.png",
    negative_sprite = "iterum_negative.png",
    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                card.ability.extra.x_mult,
                math.min(card.ability.extra.max_repetitions, card.ability.extra.repetitions),
                card.ability.extra.max_repetitions,
            },
        }
    end,
    calculate = function(self, card, context)
        if context.repetition and context.cardarea == G.play then
            return {
                message = localize("k_again_ex"),
                repetitions = math.min(
                    card.ability.extra.max_repetitions,
                    card.ability.extra.repetitions
                ),
            }
        elseif context.individual and context.cardarea == G.play then
            return { xmult = card.ability.extra.x_mult }
        end
    end,
}

--------------------------------------------------------------------------------
-- Speculo: at the end of the shop, create a Negative copy of a random
-- other Joker (never another Speculo).
-- PORT NOTE: PC copies via copy_card, preserving scaled ability state;
-- the fork creates a fresh copy (same deviation as Paperback's Book of
-- Vengeance). A Negative copy makes its own slot, as on PC.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "speculo",
    loc_txt = {
        name = "Speculo",
        text = {
            "Creates a {C:attention}Negative{} copy",
            "of a random {C:attention}Joker{}",
            "at the end of the {C:attention}shop{}",
            "{C:inactive}Does not copy other Speculo{}",
        },
    },
    config = { extra = {} },
    rarity = "exotic",
    cost = 50,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "speculo.png",
    soul_sprite = "speculo_soul.png",
    negative_sprite = "speculo_negative.png",
    calculate = function(self, card, context)
        if context.ending_shop then
            local eligible = {}
            for _, j in ipairs(G.jokers or {}) do
                if j ~= card and j.def and j.def.id ~= "j_cryp_speculo" then
                    eligible[#eligible + 1] = j
                end
            end
            if #eligible > 0 then
                local target = eligible[SMODS.pseudorandom("cryp_speculo", 1, #eligible)]
                if target.def and target.def.id then
                    SMODS.add_card { set = "Joker", key = target.def.id, edition = "negative" }
                    return { message = "Duplicated!" }
                end
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Redeo: -1 Ante each time a money threshold has been spent; the
-- threshold grows after each use.
-- PORT NOTE: PC hooks ease_dollars (money_altered is not a fork
-- context). Spending is tracked through the two shop events that carry
-- prices: buying_card (context.port.offer_price covers Jokers,
-- consumables, playing cards, boosters and vouchers) and reroll_shop
-- (context.port.reroll_cost) -- together every spend in the fork's
-- economy (the Paperback Moneyback pattern). The Ante drop itself uses
-- the Bunco Carnival recipe (G.ante + an ante_change event); Ante is
-- clamped at 1.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "redeo",
    loc_txt = {
        name = "Redeo",
        text = {
            "{C:attention}-#1#{} Ante when",
            "{C:money}$#2#{} {C:inactive}($#3#){} spent",
            "Requirements increase",
            "exponentially per use",
            "{C:money}Next increase: $#4#",
        },
    },
    config = {
        extra = { ante_reduction = 1, money_req = 10, money_remaining = 0, money_mod = 10 },
    },
    rarity = "exotic",
    cost = 50,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "redeo.png",
    soul_sprite = "redeo_soul.png",
    negative_sprite = "redeo_negative.png",
    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                card.ability.extra.ante_reduction,
                card.ability.extra.money_req,
                card.ability.extra.money_remaining,
                card.ability.extra.money_mod,
            },
        }
    end,
    calculate = function(self, card, context)
        if context.blueprint then return end
        local spent = nil
        if context.buying_card and context.port then
            spent = tonumber(context.port.offer_price)
        elseif context.reroll_shop and context.port then
            spent = tonumber(context.port.reroll_cost)
        end
        if not spent or spent <= 0 then return end
        local e = card.ability.extra
        e.money_remaining = e.money_remaining + spent
        local ante_mod = 0
        while e.money_remaining >= e.money_req do
            e.money_remaining = e.money_remaining - e.money_req
            e.money_req = e.money_req + e.money_mod
            e.money_mod = math.ceil(e.money_mod * 1.06)
            ante_mod = ante_mod - e.ante_reduction
        end
        if ante_mod < 0 and G and G.ante then
            local old_ante = tonumber(G.ante) or 1
            local new_ante = math.max(1, old_ante + ante_mod)
            if new_ante ~= old_ante then
                G.ante = new_ante
                if G.emit_joker_event then
                    G:emit_joker_event("on_ante_change", {
                        ante_change = new_ante - old_ante,
                        ante_end = false,
                    })
                end
                G.boss_rerolls_used_this_ante = 0
                return { message = "Ante Down!" }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Tenebris: +25 Joker slots; earn $25 at end of round.
-- PORT NOTE: PC changes the Joker area size in add_to_deck /
-- remove_from_deck; the fork's held-Joker joker_slots modifier is the
-- same effect (PC's displayed value is min(100, 25) = 25).
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "tenebris",
    loc_txt = {
        name = "Tenebris",
        text = {
            "{C:attention}+#1#{} Joker slots",
            "Earn {C:money}$#2#{} at end of round",
        },
    },
    config = { joker_slots = 25, extra = { slots = 25, money = 25, max_slots = 100 } },
    rarity = "exotic",
    cost = 50,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "tenebris.png",
    soul_sprite = "tenebris_soul.png",
    negative_sprite = "tenebris_negative.png",
    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                math.min(card.ability.extra.max_slots, card.ability.extra.slots),
                card.ability.extra.money,
            },
        }
    end,
    calc_dollar_bonus = function(self, card)
        return card.ability.extra.money
    end,
}

--------------------------------------------------------------------------------
-- Crustulum: gains +4 Chips per shop reroll; all rerolls are free.
-- PORT NOTE: on PC "all rerolls are free" is a Cryptid lib override of
-- calculate_reroll_cost keyed on owning Crustulum; the fork computes
-- reroll prices inside the game, so the port refunds the price the
-- reroll just charged (context.port.reroll_cost) in the same event --
-- net cost $0, though the player must be able to afford the sticker
-- price up front. PC's add_to_deck free-reroll bump is dropped (it
-- only worked around that same override).
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "crustulum",
    loc_txt = {
        name = "Crustulum",
        text = {
            "This Joker gains {C:chips}+#2#{} Chips",
            "per {C:attention}reroll{} in the shop",
            "{C:green}All rerolls are free{}",
            "{C:inactive}(Currently {C:chips}+#1#{C:inactive} Chips)",
        },
    },
    config = { extra = { chips = 0, chip_mod = 4 } },
    rarity = "exotic",
    cost = 50,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    sprite = "crustulum.png",
    soul_sprite = "crustulum_soul.png",
    negative_sprite = "crustulum_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chips, card.ability.extra.chip_mod } }
    end,
    calculate = function(self, card, context)
        if context.reroll_shop and not context.blueprint then
            card.ability.extra.chips = card.ability.extra.chips + card.ability.extra.chip_mod
            local refund = tonumber(context.port and context.port.reroll_cost) or 0
            if refund > 0 then
                return { message = "Upgrade!", extra = { dollars = refund } }
            end
            return { message = "Upgrade!" }
        end
        if context.joker_main and card.ability.extra.chips > 0 then
            return { chips = card.ability.extra.chips }
        end
    end,
}

--------------------------------------------------------------------------------
-- Non Verisimile: when any probability effect succeeds, this Joker
-- gains XMult equal to that roll's denominator.
-- PORT NOTE: the fork's pseudorandom_result context carries the
-- roll's final numerator/denominator (post Oops-style modification),
-- exactly what PC's scale used. The upgrade message is formatted by
-- hand (the fork's localize has no variable-string form here).
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "verisimile",
    loc_txt = {
        name = "Non Verisimile",
        text = {
            "When any probability",
            "is {C:green}successfully{} triggered,",
            "this Joker gains {X:mult,C:white}XMult{}",
            "equal to its listed {C:attention}odds{}",
            "{C:inactive}(Currently {X:mult,C:white} X#1# {C:inactive} Mult)",
        },
    },
    config = { extra = { xmult = 1 } },
    rarity = "exotic",
    cost = 50,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "verisimile.png",
    soul_sprite = "verisimile_soul.png",
    negative_sprite = "verisimile_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.xmult } }
    end,
    calculate = function(self, card, context)
        if context.pseudorandom_result and context.result and not context.blueprint then
            card.ability.extra.xmult = card.ability.extra.xmult
                + (tonumber(context.denominator) or 0)
            return { message = "X" .. card.ability.extra.xmult .. " Mult" }
        elseif context.joker_main then
            return { xmult = card.ability.extra.xmult }
        end
    end,
}

--------------------------------------------------------------------------------
-- Duplicare: gains X1 Mult whenever another Joker triggers or a
-- playing card is scored.
-- PORT NOTE: PC also required Cryptid.isNonScalingContext on the
-- triggering context; that check is `not context.scaling_card`, and
-- the fork never raises a scaling_card context, so it is vacuous here
-- and dropped.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "duplicare",
    loc_txt = {
        name = "Duplicare",
        text = {
            "This Joker gains {X:mult,C:white} X#2# {} Mult",
            "when a {C:attention}Joker{} or",
            "playing card is scored",
            "{C:inactive}(Currently {X:mult,C:white} X#1# {C:inactive} Mult)",
        },
    },
    config = { extra = { Xmult = 1, Xmult_mod = 1 } },
    rarity = "exotic",
    cost = 50,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "duplicare.png",
    soul_sprite = "duplicare_soul.png",
    negative_sprite = "duplicare_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.Xmult, card.ability.extra.Xmult_mod } }
    end,
    calculate = function(self, card, context)
        if not context.blueprint
            and ((context.post_trigger and context.other_card and context.other_card ~= card)
                or (context.individual and context.cardarea == G.play)) then
            card.ability.extra.Xmult = card.ability.extra.Xmult + card.ability.extra.Xmult_mod
            return { message = "Upgrade!" }
        end
        if context.joker_main and card.ability.extra.Xmult > 1 then
            return { xmult = card.ability.extra.Xmult }
        end
    end,
}

--------------------------------------------------------------------------------
-- Code Joker: create a Negative Code card when a Blind is selected.
-- PORT NOTE: PC's unlock gate (discover every Code card) and the
-- modest-gameset Boss-Blind-only variant are dropped with the gameset
-- system; the mainline effect fires on every Blind. The random Code
-- card comes from the game's own kind pool (kind string matches the
-- central ConsumableType registration; lowercase tried as a guard).
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "CodeJoker",
    loc_txt = {
        name = "Code Joker",
        text = {
            "Create a {C:attention}Negative{}",
            "{C:purple}Code{} Card when",
            "{C:attention}Blind{} is selected",
        },
    },
    config = { extra = {} },
    rarity = "epic",
    cost = 11,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "CodeJoker.png",
    negative_sprite = "CodeJoker_negative.png",
    calculate = function(self, card, context)
        if context.setting_blind and G and G.random_consumable_id_of_kind then
            local id = G:random_consumable_id_of_kind("Code")
                or G:random_consumable_id_of_kind("code")
            if id and G.add_consumable and G:can_add_consumable({ edition = "negative" }) then
                G:add_consumable(id, { edition = "negative" })
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Copy/Paste: 1 in 2 chance to duplicate a used Code card, once per
-- round (must have room).
-- PORT NOTE: mainline gameset only -- the modest (duplicate pulled
-- Code cards) and madness (no once-per-round cap) variants are dropped
-- with the gameset system, as is PC's beginning_end check (code-card
-- program state does not exist in the fork). The copy keeps the used
-- card's edition (Paperback Basic Joker Energy idiom); PC's copy_card
-- also carried the card's ability state, which a fresh copy resets.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "copypaste",
    loc_txt = {
        name = "Copy/Paste",
        text = {
            "{C:green}#1# in #2#{} chance to duplicate",
            "used {C:purple}Code{} cards",
            "{C:red}Works once per round{}",
            "{C:inactive}(Must have room)",
        },
    },
    config = { extra = { odds = 2, ckt = nil } },
    rarity = "epic",
    cost = 14,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "copypaste.png",
    negative_sprite = "copypaste_negative.png",
    loc_vars = function(self, info_queue, card)
        local num, den = SMODS.get_probability_vars(card, 1, card.ability.extra.odds, "cryp_copypaste")
        return { vars = { num, den } }
    end,
    calculate = function(self, card, context)
        if context.using_consumeable and context.port
            and tostring(context.port.consumable_kind or ""):lower() == "code"
            and not card.ability.extra.ckt
            and context.port.consumable_id
            and G and G.add_consumable then
            local src = context.port.consumable
            local edition = src and src.edition
            local params = nil
            if edition and edition ~= "base" then params = { edition = edition } end
            if G:can_add_consumable(params) then
                local hit = SMODS.pseudorandom_probability(
                    card, "cryp_copypaste", 1, card.ability.extra.odds, "cryp_copypaste")
                if hit and G:add_consumable(context.port.consumable_id, params) then
                    card.ability.extra.ckt = true
                    return { message = "Copied!" }
                end
            end
        elseif context.end_of_round and not context.blueprint and card.ability.extra.ckt then
            card.ability.extra.ckt = nil
            return { message = "Reset!" }
        end
    end,
}

--------------------------------------------------------------------------------
-- Cut: at the end of the shop, destroy a random held Code card to
-- gain X0.5 Mult.
-- PORT NOTE: destruction goes through G:remove_consumable_at (the
-- KCVanillaPack Cosmic Collapse idiom). PC's eternal / getting_sliced
-- guards are dropped: fork consumables carry no eternal sticker and
-- no dissolve-in-progress state.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "cut",
    loc_txt = {
        name = "Cut",
        text = {
            "This Joker destroys",
            "a random {C:purple}Code{} card",
            "to gain {X:mult,C:white} X#1# {} Mult",
            "at the end of the {C:attention}shop{}",
            "{C:inactive}(Currently {X:mult,C:white} X#2# {C:inactive} Mult)",
        },
    },
    config = { extra = { Xmult = 1, Xmult_mod = 0.5 } },
    rarity = 2,
    cost = 7,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    sprite = "cut.png",
    negative_sprite = "cut_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.Xmult_mod, card.ability.extra.Xmult } }
    end,
    calculate = function(self, card, context)
        if context.ending_shop and G and G.consumables then
            local targets = {}
            for i, c in ipairs(G.consumables) do
                if tostring(c.kind or ""):lower() == "code" then
                    targets[#targets + 1] = i
                end
            end
            if #targets > 0 then
                local idx = targets[SMODS.pseudorandom("cryp_cut", 1, #targets)]
                G:remove_consumable_at(idx)
                card.ability.extra.Xmult = card.ability.extra.Xmult + card.ability.extra.Xmult_mod
                return { message = "Upgrade!" }
            end
        end
        if context.joker_main and card.ability.extra.Xmult > 1 then
            return { xmult = card.ability.extra.Xmult }
        end
    end,
}

--------------------------------------------------------------------------------
-- Blender: create a random consumable when a Code card is used
-- (must have room).
-- PORT NOTE: PC rolls Steamodded's unified "Consumeables" pool; the
-- fork rolls per kind, so the port picks a random kind first (Tarot,
-- Planet, Spectral, or this pack's Code / Unique) and then a random
-- card of that kind -- kind weighting differs slightly from PC's
-- flat pool.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "blender",
    loc_txt = {
        name = "Blender",
        text = {
            "Create a {C:attention}random{}",
            "consumable when a",
            "{C:purple}Code{} card is used",
            "{C:inactive}(Must have room)",
        },
    },
    config = { extra = {} },
    rarity = 1,
    cost = 5,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "blender.png",
    negative_sprite = "blender_negative.png",
    calculate = function(self, card, context)
        if context.using_consumeable and context.port
            and tostring(context.port.consumable_kind or ""):lower() == "code"
            and G and G.random_consumable_id_of_kind and G.add_consumable
            and G:can_add_consumable() then
            local kinds = { "tarot", "planet", "spectral", "Code", "Unique" }
            local start = SMODS.pseudorandom("cryp_blender", 1, #kinds)
            for n = 0, #kinds - 1 do
                local kind = kinds[((start + n - 1) % #kinds) + 1]
                local id = G:random_consumable_id_of_kind(kind)
                if id and G:add_consumable(id) then
                    return { message = "+Consumable!" }
                end
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Python: gains X0.15 Mult when a Code card is used.
-- PORT NOTE: the running XMult is rounded to 2 decimal places per
-- gain (Paperback Planchette idiom) so the tooltip does not drift
-- into floating-point noise; PC accumulates the raw double.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "python",
    loc_txt = {
        name = "Python",
        text = {
            "This Joker gains",
            "{X:mult,C:white} X#1# {} Mult when a",
            "{C:purple}Code{} card is used",
            "{C:inactive}(Currently {X:mult,C:white} X#2# {C:inactive} Mult)",
        },
    },
    config = { extra = { Xmult = 1, Xmult_mod = 0.15 } },
    rarity = 2,
    cost = 7,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    sprite = "python.png",
    negative_sprite = "python_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.Xmult_mod, card.ability.extra.Xmult } }
    end,
    calculate = function(self, card, context)
        if context.using_consumeable and context.port
            and tostring(context.port.consumable_kind or ""):lower() == "code"
            and not context.blueprint then
            card.ability.extra.Xmult = math.floor(
                (card.ability.extra.Xmult + card.ability.extra.Xmult_mod) * 100 + 0.5) / 100
            return { message = "Upgrade!" }
        end
        if context.joker_main and card.ability.extra.Xmult > 1 then
            return { xmult = card.ability.extra.Xmult }
        end
    end,
}

--------------------------------------------------------------------------------
-- Jolly Joker? (jollysus): create a random Joker when a Joker is sold,
-- once per round.
-- PORT NOTE: PC applies the M edition (e_cry_m) to the created Joker when
-- that edition is enabled, which is what makes it count as a "Jolly" Joker;
-- the fork has no M edition, so the created Joker is a plain random Joker
-- (shop rarity weights 70/25/5, MoreFluff pattern). PC's forcetrigger
-- branch is dropped, as throughout the pack.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "jollysus",
    loc_txt = {
        name = "Jolly Joker?",
        text = {
            "Create a {C:purple}Jolly{} Joker",
            "when a Joker is {C:attention}sold{}",
            "{C:red}Works once per round{}",
            "{C:inactive}#1#{}",
        },
    },
    config = { extra = { spawn = true, active = "Active!" } },
    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = false,
    perishable_compat = true,
    sprite = "jollysus.png",
    negative_sprite = "jollysus_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.active } }
    end,
    calculate = function(self, card, context)
        if context.end_of_round and not context.retrigger_joker and not context.blueprint then
            if not card.ability.extra.spawn then
                card.ability.extra.spawn = true
                card.ability.extra.active = "Active!"
                return { message = "Reset!" }
            end
        end
        if context.selling_card and card.ability.extra.spawn and not context.retrigger_joker then
            local sold = context.card or (context.port and context.port.joker)
            local sold_is_joker = (context.port and context.port.joker ~= nil)
                or (sold and sold.def and type(sold.def.id) == "string"
                    and sold.def.id:sub(1, 2) == "j_")
            if sold_is_joker then
                if not context.blueprint then
                    card.ability.extra.spawn = false
                    card.ability.extra.active = "No triggers left!"
                end
                local id
                if G and G.random_joker_def_id_by_rarity then
                    local roll = pseudorandom("cryp_jollysus")
                    local rarity = roll < 0.70 and 1 or (roll < 0.95 and 2 or 3)
                    id = G:random_joker_def_id_by_rarity(rarity, "cryp_jollysus")
                end
                if id and SMODS.add_card { set = "Joker", key = id } then
                    return { message = "M!" }
                end
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Bubble M (bubblem): if the played hand contains a Three of a Kind,
-- self-destruct and create a Foil Jolly Joker.
-- PORT NOTE: PC queues its own removal in an event and creates the Jolly
-- immediately; the port destroys itself first so the Jolly always has a
-- slot, which is the same end state.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "bubblem",
    loc_txt = {
        name = "Bubble M",
        text = {
            "Create a {C:attention}Foil{} {C:attention}Jolly Joker{}",
            "if played hand contains",
            "a {C:attention}#1#{}",
            "{C:red}self destructs{}",
        },
    },
    config = { extra = { spawn = false, type = "Three of a Kind" } },
    rarity = 1,
    cost = 2,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = false,
    perishable_compat = true,
    sprite = "bubblem.png",
    negative_sprite = "bubblem_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.type } }
    end,
    calculate = function(self, card, context)
        if context.before and not context.blueprint and not context.retrigger_joker
            and context.poker_hands and next(context.poker_hands[card.ability.extra.type]) then
            if SMODS.destroy_joker then SMODS.destroy_joker(card) end
            SMODS.add_card { set = "Joker", key = "j_jolly", edition = "foil" }
            return { message = "M!" }
        end
    end,
}

--------------------------------------------------------------------------------
-- Fast Food M (foodm): +40 Mult; self-destructs after 2 rounds; selling
-- a Jolly Joker adds 1 round.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "foodm",
    loc_txt = {
        name = "Fast Food M",
        text = {
            "{C:mult}+#1#{} Mult",
            "{C:red}self destructs{} in {C:attention}#2#{} rounds",
            "Increases by {C:attention}#3#{} round when",
            "{C:attention}Jolly Joker{} is {C:attention}sold{}",
        },
    },
    config = { extra = { mult = 40, rounds_remaining = 2, round_inc = 1 } },
    rarity = 1,
    cost = 5,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = false,
    perishable_compat = true,
    sprite = "foodm.png",
    negative_sprite = "foodm_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult,
            card.ability.extra.rounds_remaining, card.ability.extra.round_inc } }
    end,
    calculate = function(self, card, context)
        if context.joker_main and card.ability.extra.mult > 0 then
            return { mult = card.ability.extra.mult }
        end
        if context.end_of_round and not context.blueprint and not context.retrigger_joker then
            card.ability.extra.rounds_remaining = card.ability.extra.rounds_remaining - 1
            if card.ability.extra.rounds_remaining > 0 then
                return { message = "-1 Round" }
            end
            if SMODS.destroy_joker then SMODS.destroy_joker(card) end
            return { message = "M!" }
        end
        if context.selling_card and not context.blueprint and not context.retrigger_joker then
            local sold = context.card or (context.port and context.port.joker)
            local id = sold and sold.def and sold.def.id
            if id == "j_jolly" or id == "j_cryp_jollysus" then
                card.ability.extra.rounds_remaining =
                    card.ability.extra.rounds_remaining + card.ability.extra.round_inc
                return { message = "+1 Round" }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- M Stack (mstack): retrigger all played cards; +1 retrigger (max 40)
-- for every 3 Jolly Jokers sold.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "mstack",
    loc_txt = {
        name = "M Stack",
        text = {
            "Retrigger all cards played",
            "once for every",
            "{C:attention}#2#{} {C:inactive}[#3#]{} {C:attention}Jolly Jokers{} sold",
            "{C:inactive}(Currently {C:attention}#1#{} {C:inactive}retriggers){}",
        },
    },
    config = { extra = { sell = 0, sell_req = 3, retriggers = 1, check = false },
        immutable = { max_retriggers = 40 } },
    rarity = 3,
    cost = 7,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    sprite = "mstack.png",
    negative_sprite = "mstack_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = {
            math.min(card.ability.extra.retriggers, card.ability.immutable.max_retriggers),
            card.ability.extra.sell_req, card.ability.extra.sell } }
    end,
    calculate = function(self, card, context)
        if context.repetition and context.cardarea == G.play then
            return {
                message = "Again!",
                repetitions = math.min(card.ability.extra.retriggers,
                    card.ability.immutable.max_retriggers),
            }
        end
        if context.selling_card and not context.blueprint and not context.retrigger_joker then
            local sold = context.card or (context.port and context.port.joker)
            local id = sold and sold.def and sold.def.id
            if id == "j_jolly" or id == "j_cryp_jollysus" then
                card.ability.extra.check = true
                if card.ability.extra.sell + 1 >= card.ability.extra.sell_req then
                    card.ability.extra.retriggers = card.ability.extra.retriggers + 1
                    card.ability.extra.sell = 0
                    return { message = "Upgrade!" }
                end
                card.ability.extra.sell = card.ability.extra.sell + 1
                return { message = card.ability.extra.sell .. "/"
                    .. card.ability.extra.sell_req }
            end
        end
    end,
    add_to_deck = function(self, card, from_debuff)
        card.ability.extra.retriggers = math.floor(card.ability.extra.retriggers)
        if card.ability.extra.retriggers < 1 and not card.ability.extra.check then
            card.ability.extra.retriggers = 1
        end
    end,
}

--------------------------------------------------------------------------------
-- Neon M (mneon): at end of round, bank $1 more for each Jolly Joker or
-- M Joker held; the banked amount is paid out at end of round.
-- PORT NOTE: PC detects M Jokers through Cryptid's ObjectType pool; the
-- port tests the held Joker's def id against this pack's M Joker ids
-- (the M edition half of PC's is_jolly check does not exist here).
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "mneon",
    loc_txt = {
        name = "Neon M",
        text = {
            "Earn {C:money}$#2#{} at end of round",
            "Increase payout by",
            "{C:money}$#1#{} for each {C:attention}Jolly Joker{}",
            "or {C:purple}M Joker{} at",
            "end of round",
        },
    },
    config = { extra = { bonus = 1, money = 0 } },
    rarity = 2,
    cost = 7,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = false,
    sprite = "mneon.png",
    negative_sprite = "mneon_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.bonus, card.ability.extra.money } }
    end,
    calculate = function(self, card, context)
        if context.end_of_round and not context.blueprint and not context.retrigger_joker then
            local m_ids = {
                j_cryp_jollysus = true, j_cryp_bubblem = true, j_cryp_foodm = true,
                j_cryp_mstack = true, j_cryp_mneon = true, j_cryp_notebook = true,
                j_cryp_bonk = true, j_cryp_loopy = true, j_cryp_scrabble = true,
                j_cryp_sacrifice = true, j_cryp_reverse = true, j_cryp_doodlem = true,
                j_cryp_virgo = true, j_cryp_smallestm = true, j_cryp_biggestm = true,
                j_cryp_mprime = true, j_cryp_macabre = true, j_cryp_megg = true,
                j_cryp_longboi = true,
            }
            local count = 0
            for _, j in ipairs(G.jokers or {}) do
                local id = j.def and j.def.id
                if id == "j_jolly" or (id and m_ids[id]) then
                    count = count + 1
                end
            end
            if count > 0 then
                card.ability.extra.money = card.ability.extra.money
                    + card.ability.extra.bonus * count
            end
            return { message = "M!" }
        end
    end,
    calc_dollar_bonus = function(self, card)
        if card.ability.extra.money > 0 then
            return card.ability.extra.money
        end
    end,
}

--------------------------------------------------------------------------------
-- Motebook (notebook): once per round, a shop reroll has a 1 in 7 chance
-- (guaranteed with 4+ Jolly Jokers held) to gain +1 Joker slot, max 100.
-- PORT NOTE: PC grows the Joker area with G.jokers:change_size and an
-- immutable slots counter; the port instead grows the fork's declarative
-- joker_slots modifier on card.ability, which the game sums live over
-- held Jokers, so add/remove bookkeeping is automatic.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "notebook",
    loc_txt = {
        name = "Motebook",
        text = {
            "{C:green}#1# in #2#{} chance to gain {C:purple}+#6#{} Joker",
            "slot per {C:attention}reroll{} in the shop",
            "{C:green}Always triggers{} if there are",
            "{C:attention}#5#{} or more {C:attention}Jolly Jokers{}",
            "{C:red}Works once per round{}",
            "{C:inactive}(Currently {C:purple}+#3#{} {C:inactive}and #4#){}",
        },
    },
    config = { joker_slots = 0,
        extra = { add = 1, odds = 7, jollies = 4, check = true,
            active = "Active", inactive = "" } },
    rarity = 3,
    cost = 9,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = false,
    sprite = "notebook.png",
    negative_sprite = "notebook_negative.png",
    loc_vars = function(self, info_queue, card)
        local num, den = SMODS.get_probability_vars(card, 1,
            card.ability.extra.odds, "Notebook")
        return { vars = { num, den, card.ability.joker_slots or 0,
            card.ability.extra.active, card.ability.extra.jollies,
            card.ability.extra.add } }
    end,
    calculate = function(self, card, context)
        if context.reroll_shop and card.ability.extra.check
            and not context.blueprint and not context.retrigger_joker then
            local jollycount = 0
            for _, j in ipairs(G.jokers or {}) do
                local id = j.def and j.def.id
                if id == "j_jolly" or id == "j_cryp_jollysus" then
                    jollycount = jollycount + 1
                end
            end
            if jollycount >= card.ability.extra.jollies
                or SMODS.pseudorandom_probability(card, "cryp_notebook", 1,
                    card.ability.extra.odds, "Notebook") then
                card.ability.joker_slots = math.min(100,
                    (card.ability.joker_slots or 0) + card.ability.extra.add)
                if (card.ability.joker_slots or 0) >= 100 then
                    card.ability.extra.add = 0
                end
                card.ability.extra.check = false
                card.ability.extra.active = "Inactive"
                return { message = "Upgrade!" }
            end
        end
        if context.end_of_round and not context.blueprint and not context.retrigger_joker then
            if not card.ability.extra.check then
                card.ability.extra.check = true
                card.ability.extra.active = "Active"
                return { message = "Reset!" }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Bonk (bonk): each other Joker that triggers gives +6 Chips (Jolly
-- Jokers give +18 instead); +1 Chips whenever a Pair is played.
-- PORT NOTE: PC's context.other_joker pass is the fork's post_trigger
-- pass (Paperback precedent); post_trigger only fires for Jokers that
-- actually triggered, and can also fire for triggers outside the main
-- scoring step.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "bonk",
    loc_txt = {
        name = "Bonk",
        text = {
            "Each {C:attention}Joker{} gives {C:chips}+#1#{} Chips",
            "Increase amount by {C:chips}+#2#{} if",
            "{C:attention}poker hand{} is a {C:attention}#3#{}",
            "{C:inactive}Jolly Jokers give {C:chips}+#4#{} {C:inactive}Chips instead{}",
        },
    },
    config = { extra = { chips = 6, bonus = 1, xchips = 3, type = "Pair" } },
    rarity = 2,
    cost = 5,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    sprite = "bonk.png",
    negative_sprite = "bonk_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chips, card.ability.extra.bonus,
            card.ability.extra.type,
            card.ability.extra.chips * card.ability.extra.xchips } }
    end,
    calculate = function(self, card, context)
        if context.before and not context.blueprint
            and context.scoring_name == card.ability.extra.type then
            card.ability.extra.chips = card.ability.extra.chips + card.ability.extra.bonus
        end
        if context.post_trigger and context.other_card and context.other_card ~= card then
            local oc = context.other_card
            local id = oc.def and oc.def.id
            if id == "j_jolly" or id == "j_cryp_jollysus" then
                return { chips = card.ability.extra.chips * card.ability.extra.xchips }
            end
            return { chips = card.ability.extra.chips }
        end
    end,
    add_to_deck = function(self, card, from_debuff)
        card.ability.extra.xchips = math.floor(card.ability.extra.xchips + 0.5)
    end,
}

--------------------------------------------------------------------------------
-- Loopy (loopy): retrigger all Jokers once for each Jolly Joker sold
-- (max 40).
-- PORT NOTE: PC compares context.other_card against the center table
-- (never equal), so it also offers retriggers for itself; Loopy never
-- triggers on its own, so the port's ~= card check is equivalent in play.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "loopy",
    loc_txt = {
        name = "Loopy",
        text = {
            "{C:attention}Retrigger{} all Jokers",
            "once for each {C:attention}Jolly{}",
            "{C:attention}Joker{} sold this round",
            "{C:inactive}(Currently {C:attention}#1#{} {C:inactive}retriggers){}",
        },
    },
    config = { extra = { retrigger = 0 }, immutable = { limit = 40 } },
    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "loopy.png",
    negative_sprite = "loopy_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { math.min(card.ability.extra.retrigger,
            card.ability.immutable.limit) } }
    end,
    calculate = function(self, card, context)
        if context.selling_card and not context.blueprint and not context.retrigger_joker then
            local sold = context.card or (context.port and context.port.joker)
            local id = sold and sold.def and sold.def.id
            if id == "j_jolly" or id == "j_cryp_jollysus" then
                card.ability.extra.retrigger = math.min(
                    card.ability.extra.retrigger + 1, card.ability.immutable.limit)
                return { message = "M!" }
            end
        end
        if context.retrigger_joker_check and not context.retrigger_joker
            and context.other_card and context.other_card ~= card
            and card.ability.extra.retrigger ~= 0 then
            return {
                message = "Again!",
                repetitions = math.min(card.ability.extra.retrigger,
                    card.ability.immutable.limit),
            }
        end
    end,
}

--------------------------------------------------------------------------------
-- Scrabble Tile (scrabble): 1 in 4 chance when a hand is played to
-- create an Uncommon Joker.
-- PORT NOTE: PC's create_card rarity argument 0.9 forces the Uncommon
-- pool (and the created Joker gets the M edition when enabled, hence
-- "Jolly" in the text); the port rolls the fork's Uncommon pool and the
-- M edition is dropped. The returned times from the probability roll
-- (Oops-style retriggers) create that many Jokers.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "scrabble",
    loc_txt = {
        name = "Scrabble Tile",
        text = {
            "{C:green}#1# in #2#{} chance to create",
            "a {C:purple}Jolly {C:green}Uncommon{} Joker",
            "when hand is played",
        },
    },
    config = { extra = { odds = 4 } },
    rarity = 2,
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "scrabble.png",
    negative_sprite = "scrabble_negative.png",
    loc_vars = function(self, info_queue, card)
        local num, den = SMODS.get_probability_vars(card, 1,
            card.ability.extra.odds, "Scrabble Tile")
        return { vars = { num, den } }
    end,
    calculate = function(self, card, context)
        if context.before and not context.retrigger_joker then
            local hit, times = SMODS.pseudorandom_probability(card,
                "cryp_scrabble", 1, card.ability.extra.odds, "Scrabble Tile")
            if hit and G and G.random_joker_def_id_by_rarity then
                local made = false
                for _ = 1, (times or 1) do
                    local id = G:random_joker_def_id_by_rarity(2, "cryp_scrabble")
                    if id and SMODS.add_card { set = "Joker", key = id } then
                        made = true
                    end
                end
                if made then return { message = "M!" } end
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Sacrifice (sacrifice): when a Spectral card is used, create 3 Jolly
-- Jokers and 1 Uncommon Joker; once per round.
-- PORT NOTE: the fork's using_consumeable context names the consumable
-- kind on context.port (Paperback precedent) instead of exposing the
-- consumable's set. Like PC, a Blueprint copy creates the Jokers but
-- does not consume the once-per-round flag.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "sacrifice",
    loc_txt = {
        name = "Sacrifice",
        text = {
            "Create #3# {C:green}Uncommon{} Jokers",
            "and #2# {C:attention}Jolly Jokers{} when",
            "a {C:purple}Spectral{} card is used",
            "{C:red}Works once per round{}",
            "{C:inactive}#1#{}",
        },
    },
    config = { extra = { jollies = 3, unc = 1, text = "Active!", spawn = true },
        immutable = { max_spawns = 30 } },
    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "sacrifice.png",
    negative_sprite = "sacrifice_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.text,
            math.min(card.ability.immutable.max_spawns, card.ability.extra.jollies),
            math.min(card.ability.immutable.max_spawns, card.ability.extra.unc) } }
    end,
    calculate = function(self, card, context)
        if context.using_consumeable and card.ability.extra.spawn
            and not context.retrigger_joker
            and context.port and context.port.consumable_kind == "spectral" then
            if not context.blueprint then
                card.ability.extra.spawn = false
                card.ability.extra.text = "Inactive"
            end
            for _ = 1, math.min(card.ability.immutable.max_spawns,
                math.max(1, card.ability.extra.jollies)) do
                if not SMODS.add_card { set = "Joker", key = "j_jolly" } then break end
            end
            for _ = 1, math.min(card.ability.immutable.max_spawns,
                math.max(1, card.ability.extra.unc)) do
                local id = G and G.random_joker_def_id_by_rarity
                    and G:random_joker_def_id_by_rarity(2, "cryp_sacrifice")
                if not (id and SMODS.add_card { set = "Joker", key = id }) then break end
            end
            return { message = "M!" }
        end
        if context.end_of_round and not context.blueprint and not context.retrigger_joker then
            if not card.ability.extra.spawn then
                card.ability.extra.spawn = true
                card.ability.extra.text = "Active!"
                return { message = "Reset!" }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Reverse Card (reverse): if the discarded hand is a Pair, self-destruct
-- and fill all empty Joker slots with Holographic Jolly Jokers.
-- PORT NOTE: PC evaluates the highlighted cards with
-- G.FUNCS.get_poker_hand_info; the port evaluates the discarded cards
-- itself (exactly one pair, no three of a kind or better, ranks only --
-- Wild cards do not make pairs here). PC spawns into the joker buffer
-- while it dissolves; the port destroys itself first and then fills
-- slots until add_card reports no room, the same end state.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "reverse",
    loc_txt = {
        name = "Reverse Card",
        text = {
            "Fill all empty Joker slots {C:inactive}(Max 100){}",
            "with {C:attention}Holographic{} {C:attention}Jolly Jokers{} if",
            "{C:attention}discarded poker hand{} is a {C:attention}#1#{}",
            "{C:red}self destructs{}",
        },
    },
    config = { extra = { type = "Pair" }, immutable = { max_spawns = 100 } },
    rarity = 2,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = false,
    perishable_compat = true,
    sprite = "reverse.png",
    negative_sprite = "reverse_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.type } }
    end,
    calculate = function(self, card, context)
        if context.pre_discard and not context.blueprint and not context.retrigger_joker then
            local nodes = context.full_hand
            if (not nodes or #nodes == 0) and context.port then
                nodes = context.port.discarded_nodes
            end
            if not nodes or #nodes == 0 then return end
            local counts, pairs, bigger = {}, 0, false
            for _, n in ipairs(nodes) do
                local rank = n.get_id and n:get_id() or 0
                if rank > 0 then
                    counts[rank] = (counts[rank] or 0) + 1
                end
            end
            for _, c in pairs(counts) do
                if c == 2 then pairs = pairs + 1
                elseif c > 2 then bigger = true end
            end
            if pairs ~= 1 or bigger then return end
            local cap = tonumber(G and G.joker_capacity) or #(G.jokers or {})
            if #(G.jokers or {}) > cap then return end
            if SMODS.destroy_joker then SMODS.destroy_joker(card) end
            for _ = 1, card.ability.immutable.max_spawns do
                if not SMODS.add_card { set = "Joker", key = "j_jolly",
                    edition = "holo" } then break end
            end
            return { message = "M!" }
        end
    end,
}

--------------------------------------------------------------------------------
-- Doodle M (doodlem): when a Blind is selected, create 2 Negative
-- consumables, plus 1 more for each Jolly Joker held (max 25).
-- PORT NOTE: PC draws from the general consumable pool; the port picks
-- a kind (Tarot/Planet/Spectral) at random for each, then a random card
-- of that kind through the game's own pool helper.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "doodlem",
    loc_txt = {
        name = "Doodle M",
        text = {
            "Create #2# {C:purple}Negative{} {C:attention}consumables{}",
            "when {C:attention}Blind{} is selected",
            "Create #1# more {C:attention}consumable{}",
            "for each {C:attention}Jolly Joker{}",
        },
    },
    config = { extra = { add = 1, init = 2 }, immutable = { max_jollies = 25 } },
    rarity = "epic",
    cost = 13,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "doodlem.png",
    negative_sprite = "doodlem_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.add, card.ability.extra.init } }
    end,
    calculate = function(self, card, context)
        if context.setting_blind then
            local count = card.ability.extra.init
            for _, j in ipairs(G.jokers or {}) do
                local id = j.def and j.def.id
                if id == "j_jolly" or id == "j_cryp_jollysus" then
                    count = count + math.floor(card.ability.extra.add)
                end
            end
            count = math.min(count, card.ability.immutable.max_jollies)
            if not (G and G.random_consumable_id_of_kind) then return end
            local kinds = { "tarot", "planet", "spectral" }
            local made = false
            for _ = 1, count do
                local kind = pseudorandom_element(kinds, "cryp_doodlem")
                local id = kind and G:random_consumable_id_of_kind(kind, nil,
                    "cryp_doodlem")
                if id and SMODS.add_card { set = "Consumable", key = id,
                    edition = "negative" } then
                    made = true
                else
                    break
                end
            end
            if made then return { message = "M!" } end
        end
    end,
}

--------------------------------------------------------------------------------
-- Virgo (virgo): gains $4 of sell value when a played hand contains a
-- Pair; when sold, create 1 Polychrome Jolly Joker per $4 of sell value
-- (min 1, max 80).
-- PORT NOTE: PC grows ability.extra_value and re-prices with set_cost;
-- the fork's sell path reads the Joker's sell_cost field directly
-- (Paperback precedent), so the port grows that field and reads the
-- summon count back from it.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "virgo",
    loc_txt = {
        name = "Virgo",
        text = {
            "This Joker gains {C:money}$#1#{} of {C:attention}sell value{}",
            "if {C:attention}poker hand{} contains a {C:attention}#2#{}",
            "Sell this card to create a",
            "{C:attention}Polychrome{} {C:attention}Jolly Joker{} for",
            "every {C:money}$4{} of {C:attention}sell value{} {C:inactive}(Min 1){}",
        },
    },
    config = { extra = { bonus = 4, type = "Pair" },
        immutable = { max_summons = 80 } },
    rarity = "epic",
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = false,
    perishable_compat = true,
    sprite = "virgo.png",
    soul_sprite = "virgo_soul.png",
    negative_sprite = "virgo_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.bonus, card.ability.extra.type } }
    end,
    calculate = function(self, card, context)
        if context.before and not context.blueprint
            and context.poker_hands and next(context.poker_hands[card.ability.extra.type]) then
            card.sell_cost = (tonumber(card.sell_cost) or 0) + card.ability.extra.bonus
            return { message = "Value Up!" }
        end
        if context.selling_self and not context.blueprint and not context.retrigger_joker then
            local summon = math.floor((tonumber(card.sell_cost) or 0)
                / card.ability.extra.bonus)
            if summon < 1 then summon = 1 end
            summon = math.min(summon, card.ability.immutable.max_summons)
            for _ = 1, summon do
                if not SMODS.add_card { set = "Joker", key = "j_jolly",
                    edition = "polychrome" } then break end
            end
            return { message = "M!" }
        end
    end,
}

--------------------------------------------------------------------------------
-- Huge (biggestm): after a Pair is played, X7 Mult until end of round.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "biggestm",
    loc_txt = {
        name = "Huge",
        text = {
            "{X:mult,C:white} X#1# {} Mult until end",
            "of round if {C:attention}poker hand{}",
            "is a {C:attention}#2#{}",
            "{C:inactive}(Currently {C:attention}#3#{}{C:inactive}){}",
        },
    },
    config = { extra = { x_mult = 7, type = "Pair", check = false,
        text = "Inactive" } },
    rarity = "epic",
    cost = 12,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "biggestm.png",
    negative_sprite = "biggestm_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.x_mult, card.ability.extra.type,
            card.ability.extra.text } }
    end,
    calculate = function(self, card, context)
        if context.joker_main and card.ability.extra.check then
            return { xmult = card.ability.extra.x_mult }
        end
        if context.before and not context.blueprint
            and context.scoring_name == card.ability.extra.type
            and not card.ability.extra.check then
            card.ability.extra.check = true
            card.ability.extra.text = "Active"
            return { message = "Active!" }
        end
        if context.end_of_round and card.ability.extra.check
            and not context.blueprint and not context.retrigger_joker then
            card.ability.extra.check = false
            card.ability.extra.text = "Inactive"
            return { message = "Reset!" }
        end
    end,
}

--------------------------------------------------------------------------------
-- Macabre Joker (macabre): when a Blind is selected, destroy every
-- other Joker except M Jokers, Jolly Jokers and Eternal Jokers, and
-- create 1 Jolly Joker for each destroyed Joker.
-- PORT NOTE: PC checks the M ObjectType pool and SMODS.is_eternal; the
-- port tests def ids against this pack's M Joker ids and the instance
-- eternal flag (destroy_joker itself would force past eternal, so the
-- filter here is what protects them, as on PC).
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "macabre",
    loc_txt = {
        name = "Macabre Joker",
        text = {
            "When {C:attention}Blind{} is selected,",
            "destroys each {C:attention}Joker{} except",
            "{C:purple}M Jokers{} and {C:attention}Jolly Jokers{}",
            "and create #1# {C:attention}Jolly Joker{}",
            "for each destroyed card",
        },
    },
    config = { extra = { add = 1 }, immutable = { max_spawn = 15 } },
    rarity = 1,
    cost = 5,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "macabre.png",
    negative_sprite = "macabre_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { math.min(card.ability.immutable.max_spawn,
            card.ability.extra.add) } }
    end,
    calculate = function(self, card, context)
        if context.setting_blind and not context.blueprint
            and not context.retrigger_joker then
            local m_ids = {
                j_cryp_jollysus = true, j_cryp_bubblem = true, j_cryp_foodm = true,
                j_cryp_mstack = true, j_cryp_mneon = true, j_cryp_notebook = true,
                j_cryp_bonk = true, j_cryp_loopy = true, j_cryp_scrabble = true,
                j_cryp_sacrifice = true, j_cryp_reverse = true, j_cryp_doodlem = true,
                j_cryp_virgo = true, j_cryp_smallestm = true, j_cryp_biggestm = true,
                j_cryp_mprime = true, j_cryp_macabre = true, j_cryp_megg = true,
                j_cryp_longboi = true,
            }
            local victims = {}
            for _, j in ipairs(G.jokers or {}) do
                local id = j.def and j.def.id
                if j ~= card and id ~= "j_jolly" and id ~= "j_cryp_jollysus"
                    and not (id and m_ids[id]) and not j.eternal then
                    victims[#victims + 1] = j
                end
            end
            local destroyed = 0
            for _, v in ipairs(victims) do
                if SMODS.destroy_joker and SMODS.destroy_joker(v) then
                    destroyed = destroyed + 1
                end
            end
            if destroyed > 0 then
                local spawns = math.min(card.ability.immutable.max_spawn,
                    card.ability.extra.add)
                for _ = 1, destroyed do
                    for _ = 1, spawns do
                        if not SMODS.add_card { set = "Joker",
                            key = "j_jolly" } then break end
                    end
                end
                return { message = "M!" }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Megg (megg): gains +1 stored Jolly Joker at end of round (max 200);
-- when sold, create that many Jolly Jokers.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "megg",
    loc_txt = {
        name = "Megg",
        text = {
            "Sell this card to create",
            "{C:attention}#2#{} Jolly Jokers, increase",
            "by {C:attention}#1#{} at end of round",
        },
    },
    config = { extra = { amount = 0, amount_mod = 1 },
        immutable = { max_amount = 200 } },
    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = false,
    perishable_compat = true,
    sprite = "megg.png",
    negative_sprite = "megg_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { math.max(1, card.ability.extra.amount_mod),
            math.min(card.ability.immutable.max_amount,
                math.floor(card.ability.extra.amount)) } }
    end,
    calculate = function(self, card, context)
        if context.end_of_round and not context.blueprint
            and card.ability.extra.amount < card.ability.immutable.max_amount then
            card.ability.extra.amount_mod = math.max(1, card.ability.extra.amount_mod)
            card.ability.extra.amount = math.min(card.ability.immutable.max_amount,
                card.ability.extra.amount + card.ability.extra.amount_mod)
            return { message = "Jolly Up!" }
        end
        if context.selling_self and not context.blueprint
            and not context.retrigger_joker and card.ability.extra.amount > 0 then
            local n = math.min(card.ability.immutable.max_amount,
                math.floor(card.ability.extra.amount))
            for _ = 1, n do
                if not SMODS.add_card { set = "Joker", key = "j_jolly" } then break end
            end
            return { message = "M!" }
        end
    end,
}

--------------------------------------------------------------------------------
-- Monster (longboi): XMult grows by 0.75 at end of round.
-- PORT NOTE: PC grows the shared G.GAME.monstermult counter, which
-- every copy of this Joker reads back in set_ability, so later copies
-- enter at the grown value. The fork has no G.GAME; the port tracks the
-- value per copy, so a newly gained copy starts at X1. PC's sprite
-- changes at X12321 and X1234567654321 are dropped (per-file sprites).
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "longboi",
    loc_txt = {
        name = "Monster",
        text = {
            "Give future copies of",
            "this Joker {X:mult,C:white}X#1#{} Mult",
            "at end of round",
            "{C:inactive}(Currently {X:mult,C:white}X#2#{}{C:inactive} Mult){}",
        },
    },
    config = { extra = { monster = 1, bonus = 0.75 },
        immutable = { max_bonus = 0.75 } },
    rarity = 1,
    cost = 5,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = false,
    perishable_compat = true,
    sprite = "longboi.png",
    negative_sprite = "longboi_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { math.max(card.ability.immutable.max_bonus,
            card.ability.extra.bonus), card.ability.extra.monster } }
    end,
    calculate = function(self, card, context)
        if context.end_of_round and not context.retrigger_joker then
            card.ability.extra.bonus = math.max(card.ability.extra.bonus,
                card.ability.immutable.max_bonus)
            card.ability.extra.monster = card.ability.extra.monster
                + card.ability.extra.bonus
            return { message = "M!" }
        end
        if context.joker_main and card.ability.extra.monster > 1 then
            return { xmult = card.ability.extra.monster }
        end
    end,
}

--------------------------------------------------------------------------------
-- Cotton Candy (cotton_candy): when sold, the Jokers to its left and
-- right become Negative.
-- PORT NOTE: PC uses set_edition, which also re-prices the neighbours
-- and refreshes Joker capacity; the port writes the edition field
-- directly (Paperback precedent for edition edits on held Jokers).
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "cotton_candy",
    loc_txt = {
        name = "Cotton Candy",
        text = {
            "When sold, adjacent",
            "{C:attention}Jokers{} become {C:purple}Negative{}",
        },
    },
    config = { extra = {} },
    rarity = "candy",
    cost = 10,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = false,
    perishable_compat = false,
    sprite = "cotton_candy.png",
    negative_sprite = "cotton_candy_negative.png",
    calculate = function(self, card, context)
        if context.selling_self and not context.blueprint
            and not context.retrigger_joker then
            local jokers = G.jokers or {}
            for i, j in ipairs(jokers) do
                if j == card then
                    if jokers[i - 1] then jokers[i - 1].edition = "negative" end
                    if jokers[i + 1] then jokers[i + 1].edition = "negative" end
                    return { message = "M!" }
                end
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Wrapped Candy (wrapped): after 2 rounds, self-destructs and creates
-- a random Food Joker.
-- PORT NOTE: the fork has no Food Joker pool (Paperback's Freezer hit
-- the same wall); the port creates a random Joker at shop rarity
-- weights (70/25/5) instead. PC creates before its delayed removal
-- lands; the port destroys first so the new Joker has a slot.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "wrapped",
    loc_txt = {
        name = "Wrapped Candy",
        text = {
            "Create a random {C:attention}Food Joker{}",
            "in {C:attention}#1#{} rounds",
            "{C:red}self destructs{}",
        },
    },
    config = { extra = { rounds = 2 } },
    rarity = "candy",
    cost = 10,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = false,
    perishable_compat = false,
    sprite = "wrapped.png",
    negative_sprite = "wrapped_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.rounds } }
    end,
    calculate = function(self, card, context)
        if context.end_of_round and not context.blueprint
            and not context.retrigger_joker then
            card.ability.extra.rounds = card.ability.extra.rounds - 1
            if card.ability.extra.rounds > 0 then
                return { message = "-1 Round" }
            end
            if SMODS.destroy_joker then SMODS.destroy_joker(card) end
            if G and G.random_joker_def_id_by_rarity then
                local roll = pseudorandom("cryp_wrapped")
                local rarity = roll < 0.70 and 1 or (roll < 0.95 and 2 or 3)
                local id = G:random_joker_def_id_by_rarity(rarity, "cryp_wrapped")
                if id then SMODS.add_card { set = "Joker", key = id } end
            end
            return { message = "Eaten!" }
        end
    end,
}

--------------------------------------------------------------------------------
-- Trick-or-Treat (trick_or_treat): when sold, 3 in 4 chance to create
-- 2 Candy Jokers; otherwise create 1 Cursed Joker.
-- PORT NOTE: PC creates from the cry_candy / cry_cursed rarity pools;
-- the port builds the same pools from JOKER_DEFS by the registered
-- rarity index (MoreFluff lettergem pattern), preferring Jokers not
-- already held, and can overflow Joker slots on PC only -- add_card
-- here stops at capacity. The roll's times (Oops-style retriggers)
-- multiply the candies created.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "trick_or_treat",
    loc_txt = {
        name = "Trick-or-Treat",
        text = {
            "When {C:attention}sold{}:",
            "{C:green}#1# in #2#{} chance to create {C:attention}#3#{} {C:purple}Candies{}",
            "Otherwise, create a {C:purple}Cursed{} Joker",
            "{C:inactive}(Can overflow){}",
        },
    },
    config = { extra = { odds = 4, num_candies = 2 },
        immutable = { prob_mod = 3, max_candies = 40 } },
    rarity = 2,
    cost = 5,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = false,
    perishable_compat = false,
    sprite = "trick_or_treat.png",
    negative_sprite = "trick_or_treat_negative.png",
    loc_vars = function(self, info_queue, card)
        local num, den = SMODS.get_probability_vars(card, 3,
            card.ability.extra.odds, "cry_trick_or_treat")
        return { vars = { num, den, card.ability.extra.num_candies } }
    end,
    calculate = function(self, card, context)
        if context.selling_self and not context.retrigger_joker then
            local function spawn_from_rarity(rarity_key, seed)
                local entry = SMODS.Rarities and SMODS.Rarities[rarity_key]
                if not entry then return nil end
                local held, pool = {}, {}
                for _, j in ipairs(G.jokers or {}) do
                    if j.def and j.def.id then held[j.def.id] = true end
                end
                for id, def in pairs(JOKER_DEFS or {}) do
                    if type(def) == "table" and tonumber(def.rarity) == entry.index
                        and not held[id] then
                        pool[#pool + 1] = id
                    end
                end
                if #pool == 0 then
                    for id, def in pairs(JOKER_DEFS or {}) do
                        if type(def) == "table"
                            and tonumber(def.rarity) == entry.index then
                            pool[#pool + 1] = id
                        end
                    end
                end
                if #pool == 0 then return nil end
                return SMODS.add_card { set = "Joker",
                    key = pseudorandom_element(pool, seed) }
            end
            local hit, times = SMODS.pseudorandom_probability(card,
                "cryp_trick_or_treat", 3, card.ability.extra.odds,
                "cry_trick_or_treat")
            if hit then
                local n = math.min(card.ability.immutable.max_candies,
                    card.ability.extra.num_candies * (times or 1))
                for _ = 1, n do
                    if not spawn_from_rarity("cryp_candy",
                        "cryp_trick_or_treat") then break end
                end
            else
                spawn_from_rarity("cryp_cursed", "cryp_trick_or_treat")
            end
            return { message = "M!" }
        end
    end,
}

--------------------------------------------------------------------------------
-- Candy Basket (candy_basket): gains +1 Candy every 2 rounds and +2
-- more when a Boss Blind is beaten; when sold, create that many Candy
-- Jokers.
-- PORT NOTE: rarity-pool creation as in Trick-or-Treat. PC detects the
-- Boss Blind through Cryptid.is_boss_blind(G.GAME.blind); the port uses
-- the event's is_boss_blind flag, falling back to the blind index
-- (MoreFluff precedent).
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "candy_basket",
    loc_txt = {
        name = "Candy Basket",
        text = {
            "Sell this card to create {C:attention}#1#{} {C:purple}Candies{}",
            "{C:attention}+#2#{} {C:purple}Candies{} every {C:attention}#3#{} Blinds defeated",
            "{C:attention}+#4#{} {C:purple}Candies{} when {C:attention}Boss Blind{} defeated",
        },
    },
    config = { extra = { candies = 0, candy_mod = 1, candy_boss_mod = 2 },
        immutable = { current_win_count = 0, wins_needed = 2, max_spawn = 100 } },
    rarity = 2,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = false,
    perishable_compat = false,
    sprite = "candy_basket.png",
    negative_sprite = "candy_basket_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = {
            math.floor(math.min(card.ability.immutable.max_spawn,
                card.ability.extra.candies)),
            card.ability.extra.candy_mod, card.ability.immutable.wins_needed,
            card.ability.extra.candy_mod * card.ability.extra.candy_boss_mod } }
    end,
    calculate = function(self, card, context)
        if context.selling_self and not context.retrigger_joker then
            local entry = SMODS.Rarities and SMODS.Rarities["cryp_candy"]
            if entry then
                local held, pool = {}, {}
                for _, j in ipairs(G.jokers or {}) do
                    if j.def and j.def.id then held[j.def.id] = true end
                end
                for id, def in pairs(JOKER_DEFS or {}) do
                    if type(def) == "table" and tonumber(def.rarity) == entry.index
                        and not held[id] then
                        pool[#pool + 1] = id
                    end
                end
                if #pool == 0 then
                    for id, def in pairs(JOKER_DEFS or {}) do
                        if type(def) == "table"
                            and tonumber(def.rarity) == entry.index then
                            pool[#pool + 1] = id
                        end
                    end
                end
                local n = math.floor(math.min(card.ability.immutable.max_spawn,
                    card.ability.extra.candies))
                for _ = 1, n do
                    if #pool == 0 then break end
                    if not SMODS.add_card { set = "Joker",
                        key = pseudorandom_element(pool,
                            "cryp_candy_basket") } then break end
                end
            end
            return { message = "M!" }
        end
        if context.end_of_round and not context.retrigger_joker then
            card.ability.immutable.current_win_count =
                card.ability.immutable.current_win_count + 1
            local boss = (context.port and context.port.is_boss_blind)
                or (G and tonumber(G.current_blind_index) == 3)
            local scaled = false
            if boss then
                card.ability.extra.candies = card.ability.extra.candies
                    + card.ability.extra.candy_boss_mod * card.ability.extra.candy_mod
                scaled = true
            end
            if card.ability.immutable.current_win_count
                >= card.ability.immutable.wins_needed then
                card.ability.immutable.current_win_count = 0
                card.ability.extra.candies = card.ability.extra.candies
                    + card.ability.extra.candy_mod
                scaled = true
            end
            if scaled then return { message = "M!" } end
        end
    end,
}

--------------------------------------------------------------------------------
-- Rotten Egg (rotten_egg): while held, every Joker's sell value is $1;
-- all sell values drop by $1 at end of round; after $10 has been gained
-- from selling Jokers, self-destruct.
-- PORT NOTE: PC forces the $1 price through a global set_sell_value
-- hook keyed on G.GAME.cry_rotten_amount (current AND future Jokers,
-- shop cards included). The port sets held Jokers to $1 on
-- add_to_deck, catches future Jokers on card_added, and restores the
-- plain price (max(1, floor(cost/2)) from the instance cost, which is
-- edition-adjusted) on remove_from_deck -- that restore also wipes
-- sell value grown by other effects, exactly as PC's re-pricing does.
-- Shop Jokers are not repriced here. The $1 decrement is floored at $0;
-- PC's raw field write can go negative.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "rotten_egg",
    loc_txt = {
        name = "Rotten Egg",
        text = {
            "When obtained, set sell value of",
            "all current and future Jokers to {C:attention}$#1#{}",
            "Reduce sell value of all {C:attention}Jokers{} by {C:attention}$#2#{}",
            "at end of round, after gaining {C:attention}$#3#{} {C:inactive}[#4#]{}",
            "from selling {C:attention}Jokers{}, {C:red}Self-destruct{}",
        },
    },
    config = { extra = { starting_money = 1, lose_money = 1,
        needed_money = 10, left_money = 10 } },
    rarity = "cursed",
    cost = 0,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = false,
    perishable_compat = false,
    sprite = "rotten_egg.png",
    negative_sprite = "rotten_egg_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.starting_money,
            card.ability.extra.lose_money, card.ability.extra.needed_money,
            card.ability.extra.left_money } }
    end,
    add_to_deck = function(self, card, from_debuff)
        for _, j in ipairs(G.jokers or {}) do
            if j ~= card then j.sell_cost = card.ability.extra.starting_money end
        end
    end,
    remove_from_deck = function(self, card, from_debuff)
        for _, j in ipairs(G.jokers or {}) do
            if j ~= card then
                j.sell_cost = math.max(1, math.floor((tonumber(j.cost) or 0) / 2))
            end
        end
    end,
    calculate = function(self, card, context)
        if context.card_added and context.card and context.card ~= card then
            context.card.sell_cost = card.ability.extra.starting_money
        end
        if context.end_of_round and not context.blueprint
            and not context.retrigger_joker then
            for _, j in ipairs(G.jokers or {}) do
                j.sell_cost = math.max(0, (tonumber(j.sell_cost) or 0)
                    - card.ability.extra.lose_money)
            end
            return { message = "Downgraded!" }
        end
        if context.selling_card and not context.retrigger_joker then
            local sold = context.card or (context.port and context.port.joker)
            local id = sold and sold.def and sold.def.id
            local is_joker = (context.port and context.port.joker ~= nil)
                or (type(id) == "string" and id:sub(1, 2) == "j_")
            if is_joker and sold and (tonumber(sold.sell_cost) or 0) ~= 0 then
                card.ability.extra.left_money = card.ability.extra.left_money
                    - (tonumber(sold.sell_cost) or 0)
                if card.ability.extra.left_money <= 0 then
                    if SMODS.destroy_joker then SMODS.destroy_joker(card) end
                    return { message = "M!" }
                end
                return { message = (card.ability.extra.needed_money
                    - card.ability.extra.left_money) .. "/"
                    .. card.ability.extra.needed_money }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Candy Dagger (candy_dagger): when a Blind is selected, destroy the
-- Joker to the right (unless Eternal) and create a Candy Joker.
-- PORT NOTE: rarity-pool creation as in Trick-or-Treat. PC creates the
-- Candy while the victim dissolves on a joker buffer; the port destroys
-- the victim first, so the Candy takes the freed slot.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "candy_dagger",
    loc_txt = {
        name = "Candy Dagger",
        text = {
            "When {C:attention}Blind{} is selected,",
            "destroy Joker to the right",
            "to create a {C:purple}Candy{}",
        },
    },
    config = { extra = {} },
    rarity = 2,
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "candy_dagger.png",
    negative_sprite = "candy_dagger_negative.png",
    calculate = function(self, card, context)
        if context.setting_blind and not context.retrigger_joker then
            local jokers = G.jokers or {}
            local my_pos
            for i, j in ipairs(jokers) do
                if j == card then my_pos = i break end
            end
            local victim = my_pos and jokers[my_pos + 1]
            if victim and not victim.eternal
                and SMODS.destroy_joker and SMODS.destroy_joker(victim) then
                local entry = SMODS.Rarities and SMODS.Rarities["cryp_candy"]
                if entry then
                    local held, pool = {}, {}
                    for _, j in ipairs(G.jokers or {}) do
                        if j.def and j.def.id then held[j.def.id] = true end
                    end
                    for id, def in pairs(JOKER_DEFS or {}) do
                        if type(def) == "table"
                            and tonumber(def.rarity) == entry.index
                            and not held[id] then
                            pool[#pool + 1] = id
                        end
                    end
                    if #pool == 0 then
                        for id, def in pairs(JOKER_DEFS or {}) do
                            if type(def) == "table"
                                and tonumber(def.rarity) == entry.index then
                                pool[#pool + 1] = id
                            end
                        end
                    end
                    if #pool > 0 then
                        SMODS.add_card { set = "Joker",
                            key = pseudorandom_element(pool,
                                "cryp_candy_dagger") }
                    end
                end
                return { message = "+1 Candy" }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Candy Cane (candy_cane): for the next 11 rounds, playing cards give
-- $4 when retriggered.
-- PORT NOTE: PC marks the scored card object and clears the mark with
-- a queued event later in the same hand; the port marks the card's
-- card_data and clears all marks at context.after, so a card pays on
-- its second and later scorings within one hand only. The $4 is
-- returned as dollars instead of PC's ease_dollars call.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "candy_cane",
    loc_txt = {
        name = "Candy Cane",
        text = {
            "For the next {C:attention}#1#{} rounds,",
            "playing cards give {C:money}$#2#{}",
            "when {C:attention}retriggered{}",
        },
    },
    config = { extra = { rounds = 11, dollars = 4 } },
    rarity = "candy",
    cost = 10,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "candy_cane.png",
    negative_sprite = "candy_cane_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.rounds, card.ability.extra.dollars } }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play and context.other_card then
            local data = context.other_card.card_data
            if data then
                if not data.cry_candy_caned then
                    data.cry_candy_caned = true
                else
                    return { dollars = card.ability.extra.dollars }
                end
            end
        end
        if context.after and context.full_hand then
            for _, n in ipairs(context.full_hand) do
                if n.card_data then n.card_data.cry_candy_caned = nil end
            end
        end
        if context.end_of_round and not context.blueprint
            and not context.retrigger_joker then
            card.ability.extra.rounds = card.ability.extra.rounds - 1
            if card.ability.extra.rounds > 0 then
                return { message = "-1 Round" }
            end
            if SMODS.destroy_joker then SMODS.destroy_joker(card) end
            return { message = "Eaten!" }
        end
    end,
}

--------------------------------------------------------------------------------
-- Candy Buttons (candy_buttons): the next 15 rerolls cost $1; then
-- this Joker is eaten.
-- PORT NOTE: PC caps the price inside a calculate_reroll_cost hook;
-- the fork charges first and reports the price on context.port, so the
-- port refunds the difference on reroll_shop (net cost $1, but the
-- player must be able to pay the full listed price up front).
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "candy_buttons",
    loc_txt = {
        name = "Candy Buttons",
        text = {
            "The next {C:attention}#1#{} rerolls",
            "cost {C:money}$1{}",
        },
    },
    config = { extra = { rerolls = 15 } },
    rarity = "candy",
    cost = 10,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "candy_buttons.png",
    negative_sprite = "candy_buttons_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.rerolls } }
    end,
    calculate = function(self, card, context)
        if context.reroll_shop and not context.blueprint
            and not context.retrigger_joker then
            card.ability.extra.rerolls = card.ability.extra.rerolls - 1
            local paid = tonumber(context.port and context.port.reroll_cost) or 0
            local refund = math.max(0, paid - 1)
            if card.ability.extra.rerolls <= 0 then
                if SMODS.destroy_joker then SMODS.destroy_joker(card) end
                return { dollars = refund > 0 and refund or nil,
                    message = "Eaten!" }
            end
            if refund > 0 then return { dollars = refund } end
        end
    end,
}

--------------------------------------------------------------------------------
-- Mellowcreme (mellowcreme): when sold, multiply the sell value of
-- all held consumables by X4.
-- PORT NOTE: PC accumulates ability.extra_value on each consumable and
-- re-prices with set_cost, which multiplies its current sell value by
-- 4; the fork's consumables carry a plain sell_cost field, so the port
-- multiplies that directly.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "mellowcreme",
    loc_txt = {
        name = "Mellowcreme",
        text = {
            "Sell this card to {C:attention}multiply{}",
            "the sell value of all",
            "{C:attention}consumables{} by {C:attention}X#1#{}",
        },
    },
    config = { extra = { sell_mult = 4 } },
    rarity = "candy",
    cost = 10,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = false,
    perishable_compat = true,
    sprite = "mellowcreme.png",
    negative_sprite = "mellowcreme_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.sell_mult } }
    end,
    calculate = function(self, card, context)
        if context.selling_self and not context.retrigger_joker then
            local list = G.consumables or G.consumeables or {}
            if type(list) == "table" and type(list.cards) == "table" then
                list = list.cards
            end
            for _, v in ipairs(list) do
                v.sell_cost = (tonumber(v.sell_cost) or 0)
                    * card.ability.extra.sell_mult
            end
            return { message = "M!" }
        end
    end,
}

--------------------------------------------------------------------------------
-- Brittle Candy (brittle): for the next 9 hands, the rightmost scoring
-- card gains a random Stone, Gold or Steel enhancement; then eaten.
-- PORT NOTE: PC sets the enhancement with set_ability on the card
-- object and guards re-entry with a flag cleared by a queued event;
-- the port writes card_data.enhancement on the scoring view (Paperback
-- precedent) and clears its guard flags at context.after.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "brittle",
    loc_txt = {
        name = "Brittle Candy",
        text = {
            "For the next {C:attention}#1#{} hands,",
            "add {C:attention}Stone{}, {C:attention}Gold{}, or {C:attention}Steel{} to",
            "the rightmost scoring card",
        },
    },
    config = { extra = { rounds = 9 } },
    rarity = "candy",
    cost = 10,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "brittle.png",
    negative_sprite = "brittle_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.rounds } }
    end,
    calculate = function(self, card, context)
        if context.before and not context.blueprint and not context.retrigger_joker
            and context.scoring_hand and #context.scoring_hand > 0 then
            local target = context.scoring_hand[#context.scoring_hand]
            local data = target and target.card_data
            if data and not data.cry_brittled then
                data.cry_brittled = true
                card.ability.extra.rounds = card.ability.extra.rounds - 1
                data.enhancement = pseudorandom_element(
                    { "stone", "gold", "steel" }, "cryp_brittle")
                if card.ability.extra.rounds > 0 then
                    return { message = "Enhanced!" }
                end
                if SMODS.destroy_joker then SMODS.destroy_joker(card) end
                return { message = "Eaten!" }
            end
        end
        if context.after and context.full_hand then
            for _, n in ipairs(context.full_hand) do
                if n.card_data then n.card_data.cry_brittled = nil end
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Monopoly Money (monopoly_money): 1 in 4 chance to destroy purchased
-- items; when sold, lose half your money.
-- PORT NOTE: PC destroys the bought card object directly. The fork's
-- buying_card event carries only offer_kind/offer_id, so the port
-- destroys the most recently gained held Joker or consumable with that
-- id (Jokers via destroy_joker, consumables via remove_consumable_at,
-- KC precedent). Voucher and booster purchases are skipped -- PC's
-- dissolve does nothing useful to an already-redeemed voucher, and a
-- booster is already open. Buying this Joker itself is excluded, as
-- on PC.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "monopoly_money",
    loc_txt = {
        name = "Monopoly Money",
        text = {
            "{C:green}#1# in #2#{} chance to",
            "{C:attention}destroy{} purchased items",
            "Halves money when {C:attention}sold{}",
        },
    },
    config = { extra = { odds = 4 } },
    rarity = "cursed",
    cost = 0,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = false,
    perishable_compat = false,
    sprite = "monopoly_money.png",
    negative_sprite = "monopoly_money_negative.png",
    loc_vars = function(self, info_queue, card)
        local num, den = SMODS.get_probability_vars(card, 1,
            card.ability.extra.odds, "cry_monopoly_money")
        return { vars = { num, den } }
    end,
    calculate = function(self, card, context)
        if context.buying_card and not context.blueprint
            and not context.retrigger_joker and context.port then
            local kind = context.port.offer_kind
            local oid = context.port.offer_id
            local own_id = card.def and card.def.id
            if oid and oid ~= own_id
                and (kind == "joker" or kind == "tarot" or kind == "planet"
                    or kind == "spectral" or kind == "consumable") then
                if SMODS.pseudorandom_probability(card, "cryp_monopoly_money",
                    1, card.ability.extra.odds, "cry_monopoly_money") then
                    if kind == "joker" then
                        local jokers = G.jokers or {}
                        for i = #jokers, 1, -1 do
                            if jokers[i] ~= card and jokers[i].def
                                and jokers[i].def.id == oid then
                                if SMODS.destroy_joker then
                                    SMODS.destroy_joker(jokers[i])
                                end
                                break
                            end
                        end
                    else
                        local list = G.consumables or G.consumeables or {}
                        if type(list) == "table" and type(list.cards) == "table" then
                            list = list.cards
                        end
                        for i = #list, 1, -1 do
                            if list[i].id == oid and G.remove_consumable_at then
                                G:remove_consumable_at(i)
                                break
                            end
                        end
                    end
                    return { message = "Nope!" }
                end
            end
        end
        if context.selling_self and not context.blueprint
            and not context.retrigger_joker then
            local money = tonumber(G and G.money) or 0
            if money > 0 then
                ease_dollars(-math.ceil(money / 2))
            end
            return { message = "Nope!" }
        end
    end,
}

--------------------------------------------------------------------------------
-- ://CTRL+V: create a copy of a selected playing card or consumable.
-- PORT NOTE: only the playing-card branch ports. The fork's consumable
-- selection is G.hand.highlighted (playing cards in hand) and there is no
-- copy_card; the copy is rebuilt with SMODS.add_card from the highlighted
-- card's card_data (rank/suit/enhancement/seal/edition), the Paperback
-- Three of Wands pattern. The PC consumable and booster-pack-card target
-- branches, and bulk_use, are dropped. The copy is a fresh card: PC's
-- copy preserves the original's ability state, the fork copy does not.
--------------------------------------------------------------------------------

SMODS.Consumable {
    set = "Code",
    key = "ctrl_v",
    loc_txt = {
        name = "://CTRL+V",
        text = {
            "Create a {C:purple}copy{} of {C:attention}#1#{} selected",
            "card in your hand",
        },
    },
    config = { max_highlighted = 1 },
    cost = 4,
    unlocked = true,
    discovered = true,
    sprite = "ctrl_v.png",
    negative_sprite = "ctrl_v_negative.png",
    loc_vars = function(self, info_queue, card)
        local mh = card and card.ability and card.ability.max_highlighted
            or (self.config and self.config.max_highlighted) or 1
        return { vars = { mh } }
    end,
    use = function(self, card, area, copier)
        local hl = G.hand and G.hand.highlighted
        local view = hl and hl[1]
        local d = view and view.card_data
        if not d then return end
        SMODS.add_card {
            set = "Playing", rank = d.rank, suit = d.suit,
            enhancement = d.enhancement, seal = d.seal, edition = d.edition,
        }
    end,
}

--------------------------------------------------------------------------------
-- The Automaton: creates up to 1 random Code card (must have room).
-- PORT NOTE: PC set is "Tarot", not "Code" -- this is the Code set's
-- generator card wearing a Tarot slot, kept as-is. PC creates via
-- create_card("Code", ...); the port rolls the registered Code kind with
-- G:random_consumable_id_of_kind and creates with SMODS.add_card, the
-- sibling-pack pattern. PC's create count is fixed at 1 here
-- (misprintize scaling of config.create is PC-only metadata, dropped).
--------------------------------------------------------------------------------

SMODS.Consumable {
    set = "Tarot",
    key = "automaton",
    loc_txt = {
        name = "The Automaton",
        text = {
            "Creates up to {C:attention}#1#",
            "random {C:purple}Code{} card",
            "{C:inactive}(Must have room)",
        },
    },
    config = { create = 1 },
    unlocked = true,
    discovered = true,
    sprite = "automaton.png",
    negative_sprite = "automaton_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { (card and card.ability and card.ability.create) or (self.config and self.config.create) or 1 } }
    end,
    can_use = function(self, card)
        if not (G and (G.consumables or G.consumeables)) then return false end
        local area = G.consumables or G.consumeables
        local list = area.cards or area
        if type(list) ~= "table" then return false end
        local used = #list
        for _, c in ipairs(list) do
            if c == card then used = used - 1 break end
        end
        local cap = G.get_effective_consumable_capacity
            and G:get_effective_consumable_capacity() or (used + 1)
        return used < cap
    end,
    use = function(self, card, area, copier)
        local n = math.floor((card.ability and card.ability.create) or 1)
        for _ = 1, n do
            local id = G.random_consumable_id_of_kind
                and G:random_consumable_id_of_kind("Code", {}, "cryp_automaton")
            if not id then break end
            if not SMODS.add_card { set = "Code", key = id } then break end
        end
    end,
}

-- Slice H helpers (consumables). Prefixed crypH_ so they cannot collide
-- with helpers from other slices when the fragments are assembled.

local function crypH_jokers()
    if not G then return {} end
    local src = (G.jokers and G.jokers.cards) or G.jokers or {}
    local out = {}
    for i, j in ipairs(src) do out[i] = j end
    return out
end

local function crypH_joker_id(j)
    if type(j) ~= "table" then return nil end
    if j.def and j.def.id then return j.def.id end
    return j.def_id or j.id or j.center_key or j.key
end

local function crypH_joker_capacity()
    if not G then return 5 end
    if tonumber(G.joker_capacity) then return G.joker_capacity end
    if G.joker_base_capacity then
        local ok, n = pcall(function() return G:joker_base_capacity() end)
        if ok and tonumber(n) then return n end
    end
    return 5
end

local function crypH_hand_nodes()
    if not (G and G.hand) then return {} end
    return G.hand.card_nodes or {}
end

local function crypH_sync(view)
    if view and view.sync_visual_from_card_data then
        view:sync_visual_from_card_data()
    end
end

local function crypH_card_edition(d)
    if not d then return nil end
    if d.edition then return d.edition end
    if d.modifier and d.modifier.edition then return d.modifier.edition end
    return nil
end

local function crypH_set_card_edition(d, e)
    if not d then return end
    d.edition = e
    if d.modifier then d.modifier.edition = e end
end

local function crypH_hand_index(name)
    if not (G and G.handlist) then return nil end
    for i, n in ipairs(G.handlist) do
        if n == name then return i end
    end
    return nil
end

local function crypH_level_up_at(i, times)
    if not (i and G and G.upgrade_hand_level_at_index) then return end
    for _ = 1, (times or 1) do G:upgrade_hand_level_at_index(i) end
end

local function crypH_level_up(name, times)
    crypH_level_up_at(crypH_hand_index(name), times)
end

local function crypH_hand_level(name)
    local i = crypH_hand_index(name)
    if i and G and G.get_hand_level_stats then
        local lvl = G:get_hand_level_stats(i)
        return tonumber(lvl) or 1
    end
    return 1
end

-- loc_vars for the multi-hand Planets: vars are the hand names first,
-- then their current levels, matching the PC text layout.
local function crypH_loc_vars_multi(self, info_queue, card)
    local hands = (card and card.ability and card.ability.hand_types) or (self.config and self.config.hand_types) or {}
    local vars = {}
    for _, name in ipairs(hands) do vars[#vars + 1] = name end
    for _, name in ipairs(hands) do vars[#vars + 1] = crypH_hand_level(name) end
    return { vars = vars }
end

local function crypH_use_multi(self, card, area, copier)
    local hands = (card and card.ability and card.ability.hand_types) or (self.config and self.config.hand_types) or {}
    for _, name in ipairs(hands) do crypH_level_up(name, 1) end
end

--------------------------------------------------------------------------------
-- Asteroid Belt: Level up Bulwark (+50 Chips, +1 Mult per level).
-- PORT NOTE: PC hand_type "cry_Bulwark" becomes the fork hand name
-- "Bulwark" (registered centrally: 5+ Stone cards, 100/10, l 50/1).
-- PORT NOTE: the PC cry_observatory calculate is dropped; the fork has
-- no Observatory voucher/context, here and on every Planet below.
-- PORT NOTE: name-only loc_txt, following the BuncoPack Planet precedent
-- (the fork renders a Planet's level-up text from hand_type).
--------------------------------------------------------------------------------

SMODS.Consumable {
    set = "Planet", key = "asteroidbelt",
    loc_txt = {
        name = "Asteroid Belt",
        text = {
            "Level up {C:attention}Bulwark{}",
            "{C:mult}+1{} Mult and",
            "{C:chips}+50{} Chips",
        },
    },
    config = { hand_type = "Bulwark" },
    sprite = "asteroidbelt.png",
    negative_sprite = "asteroidbelt_negative.png",
}

--------------------------------------------------------------------------------
-- Phobos & Deimos: Level up UltPair (+40 Chips, +4 Mult per level).
-- PORT NOTE: PC hand_type "cry_UltPair" becomes the fork hand name
-- "UltPair" (registered centrally: pairs sharing a suit, 220/22, l 40/4).
--------------------------------------------------------------------------------

SMODS.Consumable {
    set = "Planet", key = "marsmoons",
    loc_txt = {
        name = "Phobos & Deimos",
        text = {
            "Level up {C:attention}UltPair{}",
            "{C:mult}+4{} Mult and",
            "{C:chips}+40{} Chips",
        },
    },
    config = { hand_type = "UltPair" },
    sprite = "marsmoons.png",
    negative_sprite = "marsmoons_negative.png",
}

--------------------------------------------------------------------------------
-- Planet.lua: 1 in 5 chance to upgrade every poker hand by 1 level.
-- PORT NOTE: PC levels hands through level_up_hand/events; the port
-- calls the fork's own upgrade_hand_level_at_index for every hand in
-- G.handlist. bulk_use and the DynaText tooltip are PC/Overflow-only
-- machinery and are dropped.
--------------------------------------------------------------------------------

SMODS.Consumable {
    set = "Planet", key = "planetlua",
    loc_txt = {
        name = "Planet.lua",
        text = {
            "{C:green}#1# in #2#{} chance to",
            "upgrade every",
            "{C:attention}poker hand{}",
            "by {C:attention}1{} level",
        },
    },
    config = { extra = { odds = 5 } },
    cost = 4,
    sprite = "planetlua.png",
    negative_sprite = "planetlua_negative.png",
    loc_vars = function(self, info_queue, card)
        local odds = (card and card.ability and card.ability.extra
            and card.ability.extra.odds)
            or (self.config and self.config.extra and self.config.extra.odds) or 5
        local num, den = SMODS.get_probability_vars(card, 1,
            odds, "cryp_planetlua")
        return { vars = { num, den } }
    end,
    can_use = function(self, card)
        return true
    end,
    use = function(self, card, area, copier)
        local hit = SMODS.pseudorandom_probability(card, "cryp_planetlua",
            1, card.ability.extra.odds, "cryp_planetlua")
        if hit and G and G.handlist then
            for i in ipairs(G.handlist) do
                crypH_level_up_at(i, 1)
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Neutron Star: Upgrade a random poker hand by 1 level for each
-- Neutron Star used in this run (including this one).
-- PORT NOTE: PC counts uses in G.GAME.neutronstarsusedinthisrun; the
-- fork has no per-run consumable counter, so the count lives on G as
-- G.cryp_nstar_used and resets if a run is reloaded. The random hand is
-- drawn from the fork's visible hands (is_hand_stats_visible), where PC
-- used Cryptid.get_random_hand over visible G.GAME.hands.
--------------------------------------------------------------------------------

SMODS.Consumable {
    set = "Planet", key = "nstar",
    loc_txt = {
        name = "Neutron Star",
        text = {
            "Upgrade a random",
            "poker hand by",
            "{C:attention}1{} level for each",
            "{C:attention}Neutron Star{} used",
            "in this run",
            "{C:inactive}(Currently {C:attention}#1#{C:inactive}){}",
        },
    },
    cost = 4,
    sprite = "nstar.png",
    negative_sprite = "nstar_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { (G and tonumber(G.cryp_nstar_used)) or 0 } }
    end,
    can_use = function(self, card)
        return true
    end,
    use = function(self, card, area, copier)
        if not G then return end
        G.cryp_nstar_used = (tonumber(G.cryp_nstar_used) or 0) + 1
        local pool = {}
        for i in ipairs(G.handlist or {}) do
            if not G.is_hand_stats_visible or G:is_hand_stats_visible(i) then
                pool[#pool + 1] = i
            end
        end
        if #pool == 0 then return end
        local pick = pool[SMODS.pseudorandom("cryp_nstar", 1, #pool)]
        crypH_level_up_at(pick, G.cryp_nstar_used)
    end,
}

--------------------------------------------------------------------------------
-- Ruutu (PC key Timantii): Level up High Card, Pair and Two Pair.
-- PORT NOTE: PC levels several hands through Cryptid.suit_level_up,
-- which the fork has no equivalent for; the port is a Planet with no
-- hand_type whose use() upgrades each listed hand through
-- G:upgrade_hand_level_at_index (the Bunco/Paperback pattern). The
-- same applies to Risti, Hertta, Pata and Kaikki below.
--------------------------------------------------------------------------------

SMODS.Consumable {
    set = "Planet", key = "Timantii",
    loc_txt = {
        name = "Ruutu",
        text = {
            "{C:inactive}(lvl.#4#) (lvl.#5#) (lvl.#6#){}",
            "Level up",
            "{C:attention}#1#{},",
            "{C:attention}#2#{},",
            "and {C:attention}#3#{}",
        },
    },
    config = { hand_types = { "High Card", "Pair", "Two Pair" } },
    cost = 4,
    sprite = "Timantii.png",
    negative_sprite = "Timantii_negative.png",
    loc_vars = crypH_loc_vars_multi,
    can_use = function(self, card)
        return true
    end,
    use = crypH_use_multi,
}

--------------------------------------------------------------------------------
-- Risti (PC key Klubi): Level up Three of a Kind, Straight and Flush.
--------------------------------------------------------------------------------

SMODS.Consumable {
    set = "Planet", key = "Klubi",
    loc_txt = {
        name = "Risti",
        text = {
            "{C:inactive}(lvl.#4#) (lvl.#5#) (lvl.#6#){}",
            "Level up",
            "{C:attention}#1#{},",
            "{C:attention}#2#{},",
            "and {C:attention}#3#{}",
        },
    },
    config = { hand_types = { "Three of a Kind", "Straight", "Flush" } },
    cost = 4,
    sprite = "Klubi.png",
    negative_sprite = "Klubi_negative.png",
    loc_vars = crypH_loc_vars_multi,
    can_use = function(self, card)
        return true
    end,
    use = crypH_use_multi,
}

--------------------------------------------------------------------------------
-- Hertta (PC key Sydan): Level up Full House, Four of a Kind and
-- Straight Flush.
--------------------------------------------------------------------------------

SMODS.Consumable {
    set = "Planet", key = "Sydan",
    loc_txt = {
        name = "Hertta",
        text = {
            "{C:inactive}(lvl.#4#) (lvl.#5#) (lvl.#6#){}",
            "Level up",
            "{C:attention}#1#{},",
            "{C:attention}#2#{},",
            "and {C:attention}#3#{}",
        },
    },
    config = { hand_types = { "Full House", "Four of a Kind", "Straight Flush" } },
    cost = 4,
    sprite = "Sydan.png",
    negative_sprite = "Sydan_negative.png",
    loc_vars = crypH_loc_vars_multi,
    can_use = function(self, card)
        return true
    end,
    use = crypH_use_multi,
}

--------------------------------------------------------------------------------
-- Pata (PC key Lapio): Level up Five of a Kind, Flush House and
-- Flush Five.
--------------------------------------------------------------------------------

SMODS.Consumable {
    set = "Planet", key = "Lapio",
    loc_txt = {
        name = "Pata",
        text = {
            "{C:inactive}(lvl.#4#) (lvl.#5#) (lvl.#6#){}",
            "Level up",
            "{C:attention}#1#{},",
            "{C:attention}#2#{},",
            "and {C:attention}#3#{}",
        },
    },
    config = { hand_types = { "Five of a Kind", "Flush House", "Flush Five" } },
    cost = 4,
    sprite = "Lapio.png",
    negative_sprite = "Lapio_negative.png",
    loc_vars = crypH_loc_vars_multi,
    can_use = function(self, card)
        return true
    end,
    use = crypH_use_multi,
}

--------------------------------------------------------------------------------
-- Kaikki: Level up Bulwark and UltPair.
-- PORT NOTE: PC also levels Clusterfuck; that hand cannot be
-- registered in the fork (it needs more than 5 played cards), so the
-- Clusterfuck branch is dropped and only the two registerable custom
-- hands are levelled.
--------------------------------------------------------------------------------

SMODS.Consumable {
    set = "Planet", key = "Kaikki",
    loc_txt = {
        name = "Kaikki",
        text = {
            "{C:inactive}(lvl.#3#) (lvl.#4#){}",
            "Level up",
            "{C:attention}#1#{}",
            "and {C:attention}#2#{}",
        },
    },
    config = { hand_types = { "Bulwark", "UltPair" } },
    cost = 4,
    sprite = "Kaikki.png",
    negative_sprite = "Kaikki_negative.png",
    loc_vars = crypH_loc_vars_multi,
    can_use = function(self, card)
        return true
    end,
    use = crypH_use_multi,
}

--------------------------------------------------------------------------------
-- Lock: Remove all stickers from all Jokers, then apply Eternal to a
-- random Joker.
-- PORT NOTE: the fork has no sticker system; the only sticker-like
-- flags a held Joker carries are eternal and pinned, so the strip
-- clears those two on every Joker before the target is made Eternal.
-- PC's Cryptid-sticker removals (flickering, banana, possessed, rental)
-- have no fork counterparts and are dropped.
--------------------------------------------------------------------------------

SMODS.Consumable {
    set = "Spectral", key = "lock",
    loc_txt = {
        name = "Lock",
        text = {
            "Remove {C:red}all{} stickers",
            "from {C:red}all{} Jokers,",
            "then apply {C:purple}Eternal{}",
            "to a random {C:attention}Joker{}",
        },
    },
    cost = 4,
    sprite = "lock.png",
    negative_sprite = "lock_negative.png",
    can_use = function(self, card)
        return #crypH_jokers() > 0
    end,
    use = function(self, card, area, copier)
        local jokers = crypH_jokers()
        if #jokers == 0 then return end
        local target = jokers[SMODS.pseudorandom("cryp_lock", 1, #jokers)]
        for _, j in ipairs(jokers) do
            if type(j) == "table" then
                j.eternal = false
                j.pinned = nil
            end
        end
        if type(target) == "table" then target.eternal = true end
    end,
}

--------------------------------------------------------------------------------
-- Vacuum: Remove all modifications from all cards held in hand.
-- Earn $4 per modification removed.
-- PORT NOTE: PC resets each card through set_ability/set_edition/
-- set_seal events; the port clears the same fields directly on each
-- hand card's card_data (enhancement, edition, seal, plus any banked
-- chip/mult bonuses, which are not counted, as on PC).
--------------------------------------------------------------------------------

SMODS.Consumable {
    set = "Spectral", key = "vacuum",
    loc_txt = {
        name = "Vacuum",
        text = {
            "Removes {C:red}all {C:green}modifications{}",
            "from {C:red}all{} cards held in hand,",
            "Earn {C:money}$#1#{} per {C:green}modification{} removed",
            "{C:inactive}(ex. Enhancements, Seals, Editions){}",
        },
    },
    config = { extra = 4 },
    cost = 4,
    sprite = "vacuum.png",
    negative_sprite = "vacuum_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { (card and card.ability and card.ability.extra) or (self.config and self.config.extra) or 4 } }
    end,
    can_use = function(self, card)
        return #crypH_hand_nodes() > 0
    end,
    use = function(self, card, area, copier)
        local earnings = 0
        for _, view in ipairs(crypH_hand_nodes()) do
            local d = view and view.card_data
            if d then
                if d.enhancement then
                    earnings = earnings + 1
                    d.enhancement = nil
                end
                if crypH_card_edition(d) then
                    earnings = earnings + 1
                    crypH_set_card_edition(d, nil)
                    d.modifier = nil
                end
                if d.seal then
                    earnings = earnings + 1
                    d.seal = nil
                end
                d.chip_bonus, d.mult_bonus = nil, nil
                d.Bonus, d.bonus = nil, nil
                crypH_sync(view)
            end
        end
        if earnings > 0 then
            ease_dollars(earnings * (tonumber(card.ability.extra) or 4))
        end
    end,
}

--------------------------------------------------------------------------------
-- Replica: Convert all cards held in hand to a random card held in
-- hand.
-- PORT NOTE: the field copy follows the fork's own card-copy field
-- list (PaperbackPack's degenerate_joker): rank, suit, enhancement,
-- seal, edition and banked bonuses. PC's eternal filter is vacuous
-- here; playing cards carry no eternal sticker in the fork.
--------------------------------------------------------------------------------

SMODS.Consumable {
    set = "Spectral", key = "replica",
    loc_txt = {
        name = "Replica",
        text = {
            "Convert all cards",
            "held in hand",
            "to a {C:attention}random{}",
            "card held in hand",
        },
    },
    cost = 4,
    sprite = "replica.png",
    negative_sprite = "replica_negative.png",
    can_use = function(self, card)
        return #crypH_hand_nodes() > 0
    end,
    use = function(self, card, area, copier)
        local nodes = crypH_hand_nodes()
        if #nodes == 0 then return end
        local chosen = nodes[SMODS.pseudorandom("cryp_replica", 1, #nodes)]
        local s = chosen and chosen.card_data
        if not s then return end
        for _, view in ipairs(nodes) do
            local d = view and view.card_data
            if d and d ~= s then
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
                local rank = tonumber(d.rank)
                if rank and d.chips ~= nil then
                    d.chips = (rank == 14 and 11) or math.min(rank, 10)
                end
                crypH_sync(view)
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Analog: Create 2 copies of a random Joker, destroy all other
-- Jokers, +1 Ante.
-- PORT NOTE: PC's copy_card duplicates carry the original's ability
-- state; fork copies are created fresh from the def with
-- SMODS.add_card (edition carried), so scaled ability values on the
-- original do not carry to the copies. The original itself survives
-- untouched, as on PC. The +1 Ante writes G.ante directly and emits
-- the ante_change event, the fork's Hieroglyph recipe in reverse.
-- PC's immutable caps (200 copies, 1e300 Ante) are Talisman-scale
-- metadata and are dropped; the plain values 2 and 1 are used.
--------------------------------------------------------------------------------

SMODS.Consumable {
    set = "Spectral", key = "analog",
    loc_txt = {
        name = "Analog",
        text = {
            "Create {C:attention}#1#{} copies of a",
            "random {C:attention}Joker{}, destroy",
            "all other Jokers, {C:attention}+#2#{} Ante",
        },
    },
    config = { copies = 2, ante = 1 },
    cost = 4,
    sprite = "analog.png",
    negative_sprite = "analog_negative.png",
    loc_vars = function(self, info_queue, card)
        local ab = (card and card.ability) or self.config or {}
        return { vars = { ab.copies or 2, ab.ante or 1 } }
    end,
    can_use = function(self, card)
        return #crypH_jokers() > 0
    end,
    use = function(self, card, area, copier)
        local jokers = crypH_jokers()
        if #jokers == 0 or not G then return end
        local chosen = jokers[SMODS.pseudorandom("cryp_analog", 1, #jokers)]
        local id = crypH_joker_id(chosen)
        local edition = chosen and chosen.edition
        if edition == "base" or edition == "" then edition = nil end
        for _, j in ipairs(jokers) do
            if j ~= chosen and not j.eternal then
                SMODS.destroy_joker(j)
            end
        end
        if id then
            for _ = 1, (tonumber(card.ability.copies) or 2) do
                SMODS.add_card { set = "Joker", key = id, edition = edition }
            end
        end
        local ante_mod = tonumber(card.ability.ante) or 1
        G.ante = (tonumber(G.ante) or 1) + ante_mod
        if G.emit_joker_event then
            G:emit_joker_event("on_ante_change",
                { ante_change = ante_mod, ante_end = false })
        end
    end,
}

--------------------------------------------------------------------------------
-- Adversary: All of your Jokers become Negative.
-- PORT NOTE: PC also doubles shop Joker prices for the rest of the
-- run (G.GAME.cry_shop_joker_price_modifier); the fork has no
-- shop-price modifier API, so that half is dropped. Only Jokers
-- without an edition are made Negative, as on PC.
--------------------------------------------------------------------------------

SMODS.Consumable {
    set = "Spectral", key = "adversary",
    loc_txt = {
        name = "Adversary",
        text = {
            "{C:red}All{} of your {C:attention}Jokers{}",
            "become {C:purple}Negative{}",
        },
    },
    cost = 4,
    sprite = "adversary.png",
    negative_sprite = "adversary_negative.png",
    can_use = function(self, card)
        return #crypH_jokers() > 0
    end,
    use = function(self, card, area, copier)
        for _, j in ipairs(crypH_jokers()) do
            if type(j) == "table"
                and (j.edition == nil or j.edition == "base" or j.edition == "") then
                j.edition = "negative"
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Chambered: Create 3 Negative copies of a random consumable in your
-- possession. Does not copy Chambered.
-- PORT NOTE: PC copies any held consumable through copy_card; the
-- port re-creates the target from its def id with SMODS.add_card.
-- The fork's Negative-consumable capacity rule (one slot over the
-- cap) can yield fewer than 3 copies when consumable slots are full;
-- PC always creates all 3.
--------------------------------------------------------------------------------

SMODS.Consumable {
    set = "Spectral", key = "chambered",
    loc_txt = {
        name = "Chambered",
        text = {
            "Create {C:attention}#1#{} {C:purple}Negative{}",
            "copies of a",
            "{C:attention}random{} consumable",
            "in your possession",
            "{C:inactive}Does not copy Chambered{}",
        },
    },
    config = { extra = { num_copies = 3 } },
    cost = 4,
    sprite = "chambered.png",
    negative_sprite = "chambered_negative.png",
    loc_vars = function(self, info_queue, card)
        local ab = (card and card.ability) or {}
        local ex = ab.extra or (self.config and self.config.extra) or {}
        return { vars = { ex.num_copies or 2 } }
    end,
    can_use = function(self, card)
        if not (G and G.consumables) then return false end
        for _, c in ipairs(G.consumables) do
            if c ~= card and c.id and c.id ~= "c_cryp_chambered" then
                return true
            end
        end
        return false
    end,
    use = function(self, card, area, copier)
        if not (G and G.consumables) then return end
        local pool = {}
        for _, c in ipairs(G.consumables) do
            if c ~= card and c.id and c.id ~= "c_cryp_chambered" then
                pool[#pool + 1] = c
            end
        end
        if #pool == 0 then return end
        local target = pool[SMODS.pseudorandom("cryp_chambered", 1, #pool)]
        local set_for_kind = {
            tarot = "Tarot", planet = "Planet", spectral = "Spectral",
        }
        local set_name = set_for_kind[target.kind] or target.kind or "Consumable"
        for _ = 1, (tonumber(card.ability.extra.num_copies) or 3) do
            SMODS.add_card {
                set = set_name, key = target.id, edition = "negative",
            }
        end
    end,
}

--------------------------------------------------------------------------------
-- Conduit: Swap the editions of 2 selected playing cards.
-- PORT NOTE: PC can also target Jokers (Cryptid.get_highlighted_cards
-- over G.hand and G.jokers); the fork has no Joker-selection path for
-- consumables (selection is hand cards only), so the port covers
-- playing cards only and the description is adjusted to match.
--------------------------------------------------------------------------------

SMODS.Consumable {
    set = "Spectral", key = "conduit",
    loc_txt = {
        name = "Conduit",
        text = {
            "Swap the {C:attention}editions{} of",
            "{C:attention}2{} selected playing cards",
        },
    },
    config = { min_highlighted = 2, max_highlighted = 2 },
    cost = 4,
    sprite = "conduit.png",
    negative_sprite = "conduit_negative.png",
    loc_vars = function(self, info_queue, card)
        local mh = card and card.ability and card.ability.max_highlighted
            or (self.config and self.config.max_highlighted) or 1
        return { vars = { mh } }
    end,
    use = function(self, card, area, copier)
        local hl = (G and G.hand and G.hand.highlighted) or {}
        if #hl ~= 2 then return end
        local d1 = hl[1] and hl[1].card_data
        local d2 = hl[2] and hl[2].card_data
        if not (d1 and d2) then return end
        local e1, e2 = crypH_card_edition(d1), crypH_card_edition(d2)
        crypH_set_card_edition(d1, e2)
        crypH_set_card_edition(d2, e1)
        crypH_sync(hl[1])
        crypH_sync(hl[2])
    end,
}

--------------------------------------------------------------------------------
-- White Hole: Remove all hand levels, upgrade the most played poker
-- hand by 3 for each removed level.
-- PORT NOTE: this is the PC mainline (non-modest) effect and text
-- (en-us c_cry_white_hole2); the modest gameset variant (+4 flat, most
-- played hand keeps its levels) is dropped with the gameset system.
-- PC removes levels through level_up_hand events; the port writes
-- hand_stats levels directly (refreshing the selected-hand readout)
-- and re-levels through upgrade_hand_level_at_index. The 1e300 cap
-- is dropped; removed levels are ordinary numbers here.
--------------------------------------------------------------------------------

SMODS.Consumable {
    set = "Spectral", key = "white_hole",
    loc_txt = {
        name = "White Hole",
        text = {
            "{C:attention}Remove{} all hand levels,",
            "upgrade {C:attention}most played{} poker hand",
            "by {C:attention}3{} for each removed level",
        },
    },
    cost = 4,
    sprite = "white_hole.png",
    negative_sprite = "white_hole_negative.png",
    can_use = function(self, card)
        return true
    end,
    use = function(self, card, area, copier)
        if not (G and G.handlist and G.hand_stats) then return end
        local most_idx, best = nil, -1
        for i in ipairs(G.handlist) do
            local visible = not G.is_hand_stats_visible
                or G:is_hand_stats_visible(i)
            local played = tonumber(G.hand_play_counts
                and G.hand_play_counts[i]) or 0
            if visible and played > best then
                best = played
                most_idx = i
            end
        end
        local removed = 0
        for _, stats in ipairs(G.hand_stats) do
            local lvl = tonumber(stats.level) or 1
            if lvl > 1 then
                removed = removed + (lvl - 1)
                stats.level = 1
            end
        end
        if G.selectedHand and G.get_hand_display_stats then
            local l, c, m = G:get_hand_display_stats(
                tonumber(G.selectedHand))
            G.selectedHandLevel, G.selectedHandChips,
                G.selectedHandMult = l, c, m
        end
        if most_idx and removed > 0 then
            crypH_level_up_at(most_idx, 3 * removed)
        end
    end,
}

--------------------------------------------------------------------------------
-- Summoning: Create a random Epic Joker, destroy one random Joker.
-- PORT NOTE: PC falls back to Rare when the Epic set is disabled;
-- the gameset/enabled system is dropped and Epic is pack content, so
-- the port always rolls the Epic rarity (resolved through
-- SMODS.Rarities["cryp_epic"]). PC picks its victim from all Jokers
-- but only dissolves non-Eternal ones; the port does the same with
-- SMODS.destroy_joker. PC's can_use is looser (it can fire with no
-- Jokers held); the port requires at least one held Joker.
--------------------------------------------------------------------------------

SMODS.Consumable {
    set = "Spectral", key = "summoning",
    loc_txt = {
        name = "Summoning",
        text = {
            "Create a random",
            "{C:purple}#1#{} {C:attention}Joker{}, destroy",
            "one random {C:attention}Joker{}",
        },
    },
    cost = 4,
    sprite = "summoning.png",
    negative_sprite = "summoning_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { "Epic" } }
    end,
    can_use = function(self, card)
        return #crypH_jokers() > 0
    end,
    use = function(self, card, area, copier)
        local jokers = crypH_jokers()
        if #jokers == 0 or not G then return end
        local chosen = jokers[SMODS.pseudorandom("cryp_summoning", 1, #jokers)]
        if chosen and not chosen.eternal then
            SMODS.destroy_joker(chosen)
        end
        local rarity = 3
        local entry = SMODS.Rarities and SMODS.Rarities["cryp_epic"]
        if entry and tonumber(entry.index) then
            rarity = tonumber(entry.index)
        end
        if G.random_joker_def_id_by_rarity then
            local id = G:random_joker_def_id_by_rarity(rarity,
                "cryp_summoning")
            if id then
                SMODS.add_card { set = "Joker", key = id }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Gateway: Create a random Exotic Joker, destroy all other Jokers.
-- PORT NOTE: PC is a hidden soul-style Spectral (soul_set default,
-- 0.3% in Spectral packs); the fork has no soul/hidden consumable
-- mechanic, so Gateway appears in the normal Spectral pool. The
-- Exotic rarity is resolved through SMODS.Rarities["cryp_exotic"];
-- if no Exotic Jokers are registered the creation half does nothing.
-- PC destroys every non-Eternal Joker (its deletable list), which is
-- what the port does; an all-Eternal board with a free slot can still
-- use it, as on PC.
--------------------------------------------------------------------------------

SMODS.Consumable {
    set = "Spectral", key = "gateway",
    loc_txt = {
        name = "Gateway",
        text = {
            "Create a random",
            "{C:purple}Exotic{} {C:attention}Joker{}, destroy",
            "all other Jokers",
        },
    },
    cost = 4,
    sprite = "gateway.png",
    negative_sprite = "gateway_negative.png",
    can_use = function(self, card)
        local jokers = crypH_jokers()
        if #jokers < crypH_joker_capacity() then return true end
        for _, j in ipairs(jokers) do
            if not j.eternal then return true end
        end
        return false
    end,
    use = function(self, card, area, copier)
        if not G then return end
        for _, j in ipairs(crypH_jokers()) do
            if not j.eternal then SMODS.destroy_joker(j) end
        end
        local entry = SMODS.Rarities and SMODS.Rarities["cryp_exotic"]
        local rarity = entry and tonumber(entry.index)
        if rarity and G.random_joker_def_id_by_rarity then
            local id = G:random_joker_def_id_by_rarity(rarity,
                "cryp_gateway")
            if id then
                SMODS.add_card { set = "Joker", key = id }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- The Blessing: Creates 1 random consumable (must have room).
-- PORT NOTE: PC draws uniformly from the whole Consumeables pool
-- (Cryptid.random_consumable, excluding Blessing itself); the fork
-- only rolls per kind, so the port picks a kind uniformly among
-- Tarot/Planet/Spectral/Code/Unique and then rolls that kind through
-- G:random_consumable_id_of_kind, skipping empty kinds. The kind
-- weighting therefore differs slightly from PC's flat pool.
--------------------------------------------------------------------------------

SMODS.Consumable {
    set = "Tarot", key = "theblessing",
    loc_txt = {
        name = "The Blessing",
        text = {
            "Creates {C:attention}1{}",
            "random {C:attention}consumable{}",
            "{C:inactive}(Must have room){}",
        },
    },
    cost = 3,
    sprite = "theblessing.png",
    negative_sprite = "theblessing_negative.png",
    can_use = function(self, card)
        return true
    end,
    use = function(self, card, area, copier)
        if not (G and G.random_consumable_id_of_kind) then return end
        local kinds = { "tarot", "planet", "spectral", "Code", "Unique" }
        local set_for_kind = {
            tarot = "Tarot", planet = "Planet", spectral = "Spectral",
            Code = "Code", Unique = "Unique",
        }
        local start = SMODS.pseudorandom("cryp_theblessing", 1, #kinds)
        for n = 0, #kinds - 1 do
            local kind = kinds[((start - 1 + n) % #kinds) + 1]
            local id = G:random_consumable_id_of_kind(kind,
                { ["c_cryp_theblessing"] = true }, "cryp_theblessing")
            if id then
                SMODS.add_card { set = set_for_kind[kind], key = id }
                return
            end
        end
    end,
}
