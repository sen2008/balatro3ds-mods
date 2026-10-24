-- JestPack: All in Jest (PC, Steamodded) ported to Balatro3DS.
-- PC mod: "All in Jest" v0.7.4 by Nevernamed, Survivalaren,
-- RattlingSnow353, Jumbocarrot, ejwu2, HEAVENBRAND, Jamie! and
-- Vitellary, https://github.com/survovoaneend/All-In-Jest.
-- NO LICENSE FILE ships with the PC mod and none was found in its
-- repo (checked 2026-10-23): this port is published with full credit
-- and a takedown offer -- if you are one of the authors and want it
-- removed, say the word and it comes down.
--
-- Wave 4 J1 (pack v1.0.0): the full active-roster census. Of the 626
-- active Jokers (upstream marks 481 more ignore = true -- work in
-- progress the PC build itself never deals; those are out of scope),
-- 337 are ported below, 84 are REWRITE-class (they need restructuring
-- onto fork seats, not new engine features -- a later wave) and 205
-- are blocked on named missing pieces. Non-Joker content: 2
-- ConsumableTypes, 52 consumables, 8 Tags, 8 boosters and 2
-- enhancements ported; vouchers, editions, seals and decks are all
-- blocked (voucher calculate and edition/seal/deck effect seats do
-- not exist in the fork). The item-by-item census with every reason
-- ships in the porting record; README.txt carries the summary.
--
-- Port rules (the sibling-pack conventions): energy/attribute
-- systems do not exist here and are stripped; unlock conditions are
-- not registered by the fork, so everything is unlocked/discovered;
-- deviations are named per item in the fragment headers below and
-- are never silent.


-- Assembly order is load-bearing: the fork validates a Tarot's
-- mod_conv target at registration time, so the Fervent/Wood
-- enhancements (non-Joker part 2) register BEFORE the consumables
-- (part 1); the Sidereal boosters follow the aij_astral type.




--------------------------------------------------------------------------------
-- Enhancements
--------------------------------------------------------------------------------

if SMODS.Enhancement then

-- Fervent: gains +10 Chips every time it scores, permanently.
SMODS.Enhancement {
    key = "fervent",
    loc_txt = { name = "Fervent Card", text = {
        "Gains {C:chips}+#1#{} chips",
        "when scored",
    } },
    config = { extra = { chips_extra = 10 } },
    sprite = "fervent.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { self.config.extra.chips_extra } }
    end,
    calculate = function(self, card, context)
        if context.card_played and card and card.card_data then
            local d = card.card_data
            d.aij_fervent_bonus = (tonumber(d.aij_fervent_bonus) or 0)
                + self.config.extra.chips_extra
            return {
                chips = d.aij_fervent_bonus,
                message = localize("k_upgrade_ex"),
            }
        end
    end,
}

-- Wood: held-in-hand Chips, +5 more for each other Wood card held.
local function aij_wood_count()
    local n = 0
    if G and G.hand and G.hand.card_nodes then
        for _, node in ipairs(G.hand.card_nodes) do
            if node.enhancement == "wood" then n = n + 1 end
        end
    end
    return n
end

local function aij_wood_chips(self)
    local extra = self.config.extra
    local n = aij_wood_count()
    if n > 1 then
        return extra.base_h_chips + extra.h_chips_mod * (n - 1)
    end
    return extra.base_h_chips
end

SMODS.Enhancement {
    key = "wood",
    loc_txt = { name = "Wood Card", text = {
        "When held in hand, {C:chips}+#3#{} chips,",
        "{C:chips}+#2#{} more for each other",
        "{C:attention}Wood{} card held in hand",
        "{C:inactive}(Currently {C:chips}+#1#{C:inactive} chips)",
    } },
    config = { extra = { base_h_chips = 20, h_chips_mod = 5 } },
    sprite = "wood.png",
    loc_vars = function(self, info_queue, card)
        return { vars = {
            aij_wood_chips(self),
            self.config.extra.h_chips_mod,
            self.config.extra.base_h_chips,
        } }
    end,
    calculate = function(self, card, context)
        if context.held_in_hand then
            return { chips = aij_wood_chips(self) }
        end
    end,
}

end -- SMODS.Enhancement

--------------------------------------------------------------------------------
-- JestPack fragment: All in Jest non-Joker content, part 1
-- (Consumables: Tarots / Planets / Spectrals / Hex Tarots, the Astral and
-- Hex consumable types, and Tags.)
--
-- PC source: "All in Jest" v0.7.4 by Nevernamed, Survivalaren and others
-- (https://github.com/survovoaneend/All-In-Jest). See
-- census_nonjoker_1.md for the item-by-item verdicts; only PORTABLE and
-- REWRITE items appear below. BLOCKED items are named in the census with
-- their blockers.
--
-- Deviations (each named, none silent; also flagged per item):
--   * Moons (the 32 jest_spec_moon Planets, plus Gravastar / Pulsar):
--     PC levels ONE stat of a hand at DOUBLE the per-level rate
--     (level_up_hand_chips / level_up_hand_mult). The fork derives both
--     stats from a single level (base + (level-1) x per-level), so the
--     port raises the level through the fork's own funnel
--     (G:upgrade_hand_level_at_index, the Cryptid/Bunco route) and then
--     compensates the hand's base stats: the moon's stat keeps a second
--     step, the other stat gives its step back. The compensation is
--     exact and composes with later full level-ups (the Bunco "Deal"
--     hand writes hand_stats bases the same way). Bases can go negative
--     on paper (e.g. a Mult moon on High Card); the fork's level formula
--     still lands on the PC values at every level.
--   * in_pool gates that read run state the fork does not expose to a
--     consumable (Dark Star's ante >= 4 gate, Sol's played >= 1 gate)
--     are dropped, per the wave-4 conventions for pool gates.
--   * Hex Tarots: PC deals them through a soul_rate roll off the Tarot
--     pool. The fork has no soul roll for consumables, so the
--     aij_hex_tarot kind registers at shop_rate 0 with no packs: the
--     cards exist, are discovered/creatable, but no shop or pack deals
--     them. Same shape for the aij_astral kind (below).
--   * Astral consumables are ALL blocked (the pin system: persistent
--     per-hand pins with their own calculate pass, a pin card area and
--     a replacement UI -- none of it exists in the fork). The
--     aij_astral ConsumableType is still registered, as part 2's
--     Sidereal boosters deal from the kind; with no Astral cards
--     registered the kind's pool is empty and those packs stay inert
--     until pins exist.
--   * Gold Tags (PC's parallel "Jest_Golden_Tag" pool) register with
--     weight = 0: out of the fork's skip poll, creatable directly,
--     which is the closest the fork gets to PC's separate golden pool.
--   * mod_conv values are re-prefixed to this pack: PC's
--     "m_aij_fervent" / "m_aij_wood" become "m_jest_fervent" /
--     "m_jest_wood" (the fork resolves m_<full id>; an enhancement's
--     value is its registered key). Part 2 registers fervent and
--     wood; the other Jest enhancements are BLOCKED there, which is
--     why their conversion Tarots are blocked here too.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Helpers (the CryptidPack crypH patterns, renamed for this pack)
--------------------------------------------------------------------------------

local function jest_hand_index(name)
    if not (G and G.handlist) then return nil end
    for i, n in ipairs(G.handlist) do
        if n == name then return i end
    end
    return nil
end

local function jest_hand_level(name)
    local i = jest_hand_index(name)
    if i and G and G.get_hand_level_stats then
        local lvl = G:get_hand_level_stats(i)
        return tonumber(lvl) or 1
    end
    return 1
end

local function jest_hand_nodes()
    if not (G and G.hand) then return {} end
    return G.hand.card_nodes or {}
end

local function jest_sync(view)
    if view and view.sync_visual_from_card_data then
        view:sync_visual_from_card_data()
    end
end

local function jest_card_edition(d)
    if not d then return nil end
    if d.edition then return d.edition end
    if d.modifier and d.modifier.edition then return d.modifier.edition end
    return nil
end

local function jest_set_card_edition(d, e)
    if not d then return end
    d.edition = e
    if d.modifier then d.modifier.edition = e end
end

-- One moon step on hand index idx: level +1 through the fork funnel,
-- then base compensation so only `stat` ("chips" / "mult") nets a
-- double step. See the header deviation note.
local function jest_moon_step(idx, stat)
    if not (G and G.hand_stats and G.hand_stats[idx]) then return end
    if G.upgrade_hand_level_at_index then
        G:upgrade_hand_level_at_index(idx)
    end
    local stats = G.hand_stats[idx]
    local cpl = tonumber(stats.chips_per_level) or 0
    local mpl = tonumber(stats.mult_per_level) or 0
    if stat == "chips" then
        stats.base_chips = (tonumber(stats.base_chips) or 0) + cpl
        stats.base_mult = (tonumber(stats.base_mult) or 0) - mpl
    else
        stats.base_mult = (tonumber(stats.base_mult) or 0) + mpl
        stats.base_chips = (tonumber(stats.base_chips) or 0) - cpl
    end
    -- The funnel refreshed the selected-hand readout before the
    -- compensation; redo it if this hand is the selected one.
    if tonumber(G.selectedHand) == idx and G.get_hand_display_stats then
        local level, chips, mult = G:get_hand_display_stats(idx)
        G.selectedHandLevel = level
        G.selectedHandChips = chips
        G.selectedHandMult = mult
    end
end

-- Most-played visible hand index (fork seats: G.hand_play_counts +
-- G:is_hand_stats_visible, the Cryptid White Hole pattern).
local function jest_most_played_hand_index()
    if not (G and G.handlist) then return nil end
    local best_idx, best = nil, 0
    for i in ipairs(G.handlist) do
        local visible = not G.is_hand_stats_visible
            or G:is_hand_stats_visible(i)
        local played = tonumber(G.hand_play_counts
            and G.hand_play_counts[i]) or 0
        if visible and played > best then
            best = played
            best_idx = i
        end
    end
    return best_idx
end

--------------------------------------------------------------------------------
-- Consumable types (registered before their consumables)
--------------------------------------------------------------------------------

if SMODS.ConsumableType then

-- Astral kind. PC shop_rate = 0; Astrals enter play only through
-- Sidereal packs and card creation, never the shop roll. All Astral
-- consumables themselves are BLOCKED (pin system, see header).
SMODS.ConsumableType {
    key = "aij_astral",
    loc_txt = { name = "Astral" },
    shop_rate = 0,
}

-- Hex Tarot kind. PC shop_rate = 0, no packs; dealt only by the
-- Tarot soul roll (see header deviation).
SMODS.ConsumableType {
    key = "aij_hex_tarot",
    loc_txt = { name = "Hex Tarot" },
    shop_rate = 0,
}

end -- SMODS.ConsumableType

--------------------------------------------------------------------------------
-- Tarots: the two portable enhancement conversions.
-- Both ride the fork's built-in mod_conv seat; the target enhancements
-- are registered by frag_nonjoker_2 (fervent, wood).
--------------------------------------------------------------------------------

if SMODS.Consumable then

SMODS.Consumable {
    set = "Tarot", key = "magus",
    loc_txt = {
        name = "The Magus",
        text = {
            "Enhances {C:attention}#1#{} selected",
            "card into a {C:attention}#2#{}",
        },
    },
    config = { max_highlighted = 1, mod_conv = "m_jest_fervent" },
    cost = 3,
    sprite = "magus.png",
    negative_sprite = "magus_negative.png",
    loc_vars = function(self, info_queue, card)
        local cfg = (card and card.ability) or self.config or {}
        return { vars = { cfg.max_highlighted or 1, "Fervent Card" } }
    end,
}

SMODS.Consumable {
    set = "Tarot", key = "sanctuary_gate",
    loc_txt = {
        name = "The Sanctuary Gate",
        text = {
            "Enhances {C:attention}#1#{} selected",
            "cards to {C:attention}#2#s{}",
        },
    },
    config = { max_highlighted = 2, mod_conv = "m_jest_wood" },
    cost = 3,
    sprite = "sanctuary_gate.png",
    negative_sprite = "sanctuary_gate_negative.png",
    loc_vars = function(self, info_queue, card)
        local cfg = (card and card.ability) or self.config or {}
        return { vars = { cfg.max_highlighted or 2, "Wood Card" } }
    end,
}

--------------------------------------------------------------------------------
-- Tarots: rewrites
--------------------------------------------------------------------------------

-- Master of the Arcanes: 1 in 2 chance to create a random Spectral.
-- PORT NOTE: PC create_consumable("Spectral") becomes the fork's
-- kind roll (G:random_consumable_id_of_kind + G:add_consumable, the
-- Bunco/Cryptid pattern). Room check follows Cryptid's Automaton.
SMODS.Consumable {
    set = "Tarot", key = "master_arcanes",
    loc_txt = {
        name = "Master of the Arcanes",
        text = {
            "{C:green}#1# in #2#{} chance to create",
            "a random {C:spectral}Spectral{} card",
            "{C:inactive}(Must have room)",
        },
    },
    config = { extra = { odds = 2 } },
    cost = 3,
    sprite = "master_arcanes.png",
    negative_sprite = "master_arcanes_negative.png",
    loc_vars = function(self, info_queue, card)
        local odds = (card and card.ability and card.ability.extra
            and card.ability.extra.odds)
            or (self.config and self.config.extra and self.config.extra.odds)
            or 2
        local num, den = SMODS.get_probability_vars(card, 1, odds,
            "aij_master_arcanes")
        return { vars = { num, den } }
    end,
    can_use = function(self, card)
        if not (G and G.can_add_consumable) then return false end
        return G:can_add_consumable() or false
    end,
    use = function(self, card, area, copier)
        local odds = (card and card.ability and card.ability.extra
            and card.ability.extra.odds) or 2
        local hit = SMODS.pseudorandom_probability(card,
            "aij_master_arcanes", 1, odds, "aij_master_arcanes")
        if hit and G and G.random_consumable_id_of_kind
            and G.add_consumable then
            local id = G:random_consumable_id_of_kind("spectral")
            if id then G:add_consumable(id) end
        end
    end,
}

-- Osiris: destroy 1 selected Joker, earn triple its sell value (cap $150).
-- PORT NOTE: PC picks the highlighted / rightmost Joker by hand; the
-- fork's seat for that is target_joker. The PC tooltip's live
-- "Currently $X" quote has no resolved target at loc time in the fork,
-- so the line is dropped (the cap line stays).
SMODS.Consumable {
    set = "Tarot", key = "osiris",
    target_joker = true,
    loc_txt = {
        name = "Osiris",
        text = {
            "{C:red}Destroy{} {C:attention}1{} selected Joker",
            "and earn triple its {C:money}sell value{}",
            "{C:inactive}(Max of {C:money}$#1#{C:inactive})",
        },
    },
    config = { extra = { cap = 150 } },
    cost = 3,
    sprite = "osiris.png",
    negative_sprite = "osiris_negative.png",
    loc_vars = function(self, info_queue, card)
        local cap = (card and card.ability and card.ability.extra
            and card.ability.extra.cap)
            or (self.config and self.config.extra
                and self.config.extra.cap) or 150
        return { vars = { cap } }
    end,
    can_use = function(self, card, target)
        return target ~= nil and not target.eternal
    end,
    use = function(self, card, area, copier, target)
        if not target then return end
        local cap = (card and card.ability and card.ability.extra
            and card.ability.extra.cap) or 150
        local gain = math.min((tonumber(target.sell_cost) or 0) * 3, cap)
        if SMODS.destroy_joker then SMODS.destroy_joker(target) end
        if gain > 0 then ease_dollars(gain) end
    end,
}

-- The Reaper: convert all 3 selected cards into copies of one of them.
-- PORT NOTE: PC copy_card becomes the fork's card_data field copy
-- (the Cryptid Replica pattern: rank, suit, enhancement, seal,
-- edition and banked bonuses, chips recomputed, then sync). PC's
-- copy also carried per-card ability state; the fork field copy does
-- not (same limit as Replica).
SMODS.Consumable {
    set = "Tarot", key = "reaper",
    loc_txt = {
        name = "The Reaper",
        text = {
            "Select {C:attention}#1#{} cards. All {C:attention}#1#{} cards",
            "will be {C:attention}converted{} into {C:attention}copies{}",
            "of one of them, chosen at {C:attention}random{}",
        },
    },
    config = { min_highlighted = 3, max_highlighted = 3 },
    cost = 3,
    sprite = "reaper.png",
    negative_sprite = "reaper_negative.png",
    loc_vars = function(self, info_queue, card)
        local cfg = (card and card.ability) or self.config or {}
        return { vars = { cfg.max_highlighted or 3 } }
    end,
    use = function(self, card, area, copier)
        local hl = (G and G.hand and G.hand.highlighted) or {}
        if #hl == 0 then return end
        local src = pseudorandom_element(hl, "aij_reaper")
        local s = src and src.card_data
        if not s then return end
        for _, view in ipairs(hl) do
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
                jest_sync(view)
            end
        end
    end,
}

-- The Rising of the Dead: the left selected card gains the Enhancement
-- and Seal of the right one.
-- PORT NOTE: PC also copies the Jest second ("other") enhancement;
-- fork cards carry one enhancement, so only the primary moves.
-- Left/right are by hand position (PC reads T.x; the port orders the
-- highlighted views by their slot in G.hand.card_nodes).
SMODS.Consumable {
    set = "Tarot", key = "rising_dead",
    loc_txt = {
        name = "The Rising of the Dead",
        text = {
            "Select {C:attention}#1#{} cards, give the {C:attention}left{}",
            "card the {C:attention}Enhancement{} and {C:attention}Seal{}",
            "of the {C:attention}right{} card",
        },
    },
    config = { min_highlighted = 2, max_highlighted = 2 },
    cost = 3,
    sprite = "rising_dead.png",
    negative_sprite = "rising_dead_negative.png",
    loc_vars = function(self, info_queue, card)
        local cfg = (card and card.ability) or self.config or {}
        return { vars = { cfg.max_highlighted or 2 } }
    end,
    can_use = function(self, card)
        local hl = (G and G.hand and G.hand.highlighted) or {}
        if #hl ~= 2 then return false end
        local order = {}
        for i, node in ipairs(jest_hand_nodes()) do order[node] = i end
        local src = hl[1]
        for _, v in ipairs(hl) do
            if (order[v] or 0) > (order[src] or 0) then src = v end
        end
        local d = src and src.card_data
        return d ~= nil and (d.enhancement ~= nil or d.seal ~= nil)
    end,
    use = function(self, card, area, copier)
        local hl = (G and G.hand and G.hand.highlighted) or {}
        if #hl ~= 2 then return end
        local order = {}
        for i, node in ipairs(jest_hand_nodes()) do order[node] = i end
        local src, dst = hl[1], hl[2]
        if (order[dst] or 0) > (order[src] or 0) then
            src, dst = dst, src
        end
        local s, d = src and src.card_data, dst and dst.card_data
        if not (s and d) then return end
        d.enhancement = s.enhancement
        d.seal = s.seal
        jest_sync(dst)
    end,
}

-- The Sacrifice: destroy 1 selected card, create a card with a random
-- suit, rank and enhancement in hand.
-- PORT NOTE: PC create_playing_card with a polled guaranteed
-- enhancement (no_replace) becomes SMODS.add_card + SMODS.poll_enhancement
-- (the fork poll returns the port value string add_card takes).
SMODS.Consumable {
    set = "Tarot", key = "sacrifice",
    loc_txt = {
        name = "The Sacrifice",
        text = {
            "{C:red}Destroy{} {C:attention}#1#{} selected card to",
            "create a card with a random {C:attention}suit{},",
            "{C:attention}rank{}, and {C:attention}enhancement{}",
        },
    },
    config = { max_highlighted = 1 },
    cost = 3,
    sprite = "sacrifice.png",
    negative_sprite = "sacrifice_negative.png",
    loc_vars = function(self, info_queue, card)
        local cfg = (card and card.ability) or self.config or {}
        return { vars = { cfg.max_highlighted or 1 } }
    end,
    use = function(self, card, area, copier)
        local hl = (G and G.hand and G.hand.highlighted) or {}
        local victim = hl[1]
        if not victim then return end
        if SMODS.destroy_card then SMODS.destroy_card(victim) end
        local enh = nil
        if SMODS.poll_enhancement then
            enh = SMODS.poll_enhancement({
                guaranteed = true, no_replace = true, key = "aij_sacrifice",
            })
        end
        local suits = { "Hearts", "Diamonds", "Clubs", "Spades" }
        SMODS.add_card {
            set = "Playing",
            rank = SMODS.pseudorandom("aij_sacrifice_rank", 2, 14),
            suit = pseudorandom_element(suits, "aij_sacrifice_suit"),
            enhancement = enh,
        }
    end,
}

-- Twilight: earn $2 per level of your most played poker hand (max $50).
-- PORT NOTE: PC reads G.GAME.hands played/level; the fork seats are
-- G.hand_play_counts, G:is_hand_stats_visible and
-- G:get_hand_level_stats (the Cryptid White Hole pattern).
SMODS.Consumable {
    set = "Tarot", key = "twilight",
    loc_txt = {
        name = "Twilight",
        text = {
            "Earn {C:money}$#1#{} for each level of your",
            "most played poker hand",
            "{C:inactive}(Max of {C:money}$#2#{C:inactive})",
            "{C:inactive}(Currently {C:money}$#3#{C:inactive} - #4#)",
        },
    },
    config = { extra = { dollars_per_level = 2, max = 50 } },
    cost = 3,
    sprite = "twilight.png",
    negative_sprite = "twilight_negative.png",
    loc_vars = function(self, info_queue, card)
        local extra = (card and card.ability and card.ability.extra)
            or (self.config and self.config.extra) or {}
        local per = tonumber(extra.dollars_per_level) or 2
        local cap = tonumber(extra.max) or 50
        local idx = jest_most_played_hand_index()
        local money, hand_name = 0, "None"
        if idx then
            hand_name = G.handlist[idx]
            money = math.min(jest_hand_level(hand_name) * per, cap)
        end
        return { vars = { per, cap, money, hand_name } }
    end,
    can_use = function(self, card)
        return true
    end,
    use = function(self, card, area, copier)
        local extra = (card and card.ability and card.ability.extra) or {}
        local per = tonumber(extra.dollars_per_level) or 2
        local cap = tonumber(extra.max) or 50
        local idx = jest_most_played_hand_index()
        if not idx then return end
        local money = math.min(
            jest_hand_level(G.handlist[idx]) * per, cap)
        if money > 0 then ease_dollars(money) end
    end,
}

-- The Two Ways: split 1 selected card into 2 copies of half the rank.
-- PORT NOTE: PC SMODS.modify_rank has no fork setter; the port writes
-- the original's card_data rank (chips recomputed) and builds the
-- clone with SMODS.add_card from the original's card_data (the
-- Cryptid CTRL+V / Replica patterns). The clone is a fresh card: PC's
-- clone preserved per-card ability state, the fork's does not.
-- Odd ranks split unevenly as on PC (clone ceil, original floor).
SMODS.Consumable {
    set = "Tarot", key = "two_ways",
    loc_txt = {
        name = "The Two Ways",
        text = {
            "Splits {C:attention}#1#{} selected card into {C:attention}2{} copies",
            "with {C:attention}half{} the original {C:attention}rank{}",
            "{C:inactive}(Odd cards split as evenly as possible)",
        },
    },
    config = { max_highlighted = 1 },
    cost = 3,
    sprite = "two_ways.png",
    negative_sprite = "two_ways_negative.png",
    loc_vars = function(self, info_queue, card)
        local cfg = (card and card.ability) or self.config or {}
        return { vars = { cfg.max_highlighted or 1 } }
    end,
    can_use = function(self, card)
        local hl = (G and G.hand and G.hand.highlighted) or {}
        if #hl ~= 1 then return false end
        local view = hl[1]
        local id = view and view.get_id and view:get_id()
        if not id or id == 2 or id == 3 then return false end
        return not (view.enhancement == "canvas")
    end,
    use = function(self, card, area, copier)
        local hl = (G and G.hand and G.hand.highlighted) or {}
        local view = hl[1]
        local d = view and view.card_data
        if not (view and d) then return end
        local id = view.get_id and view:get_id()
        if not id then return end
        local clone_rank = math.max(2, math.min(math.ceil(id / 2), 14))
        local orig_rank = math.max(2, math.min(math.floor(id / 2), 14))
        SMODS.add_card {
            set = "Playing", rank = clone_rank, suit = d.suit,
            enhancement = d.enhancement, seal = d.seal,
            edition = jest_card_edition(d),
        }
        d.rank = orig_rank
        if d.chips ~= nil then
            d.chips = (orig_rank == 14 and 11)
                or math.min(orig_rank, 10)
        end
        jest_sync(view)
    end,
}

-- The Urns: destroy 1 selected enhanced card, apply its enhancement
-- to 3 random other cards in hand.
-- PORT NOTE: PC also copies the Jest second enhancement; fork cards
-- carry one (see Rising Dead). PC requires only 3+ cards in hand and
-- can fizzle for targets; the port requires the full 4 (target + 3
-- recipients) up front.
SMODS.Consumable {
    set = "Tarot", key = "urns",
    loc_txt = {
        name = "The Urns",
        text = {
            "{C:red}Destroy{} {C:attention}#1#{} selected {C:attention}enhanced{} card",
            "and apply its {C:attention}enhancement{} to {C:attention}#2#{}",
            "{C:attention}random{} cards in hand",
        },
    },
    config = { max_highlighted = 1, ran_cards = 3 },
    cost = 3,
    sprite = "urns.png",
    negative_sprite = "urns_negative.png",
    loc_vars = function(self, info_queue, card)
        local cfg = (card and card.ability) or self.config or {}
        return { vars = { cfg.max_highlighted or 1, cfg.ran_cards or 3 } }
    end,
    can_use = function(self, card)
        local hl = (G and G.hand and G.hand.highlighted) or {}
        if #hl ~= 1 then return false end
        local d = hl[1] and hl[1].card_data
        if not (d and d.enhancement) then return false end
        return #jest_hand_nodes() >= 4
    end,
    use = function(self, card, area, copier)
        local hl = (G and G.hand and G.hand.highlighted) or {}
        local victim = hl[1]
        local vd = victim and victim.card_data
        if not vd then return end
        local enh = vd.enhancement
        if SMODS.destroy_card then SMODS.destroy_card(victim) end
        if not enh then return end
        local ran = (card and card.ability and card.ability.ran_cards)
            or 3
        local pool = {}
        for _, node in ipairs(jest_hand_nodes()) do
            local d = node and node.card_data
            if d and d.enhancement ~= enh then
                pool[#pool + 1] = node
            end
        end
        for _ = 1, ran do
            if #pool == 0 then break end
            local pick = pseudorandom_element(pool, "aij_urns")
            for i, node in ipairs(pool) do
                if node == pick then
                    table.remove(pool, i)
                    break
                end
            end
            local d = pick and pick.card_data
            if d then
                d.enhancement = enh
                jest_sync(pick)
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Planets: Sol (portable) and Dark Star (rewrite)
--------------------------------------------------------------------------------

-- Sol: level up Royal Flush.
-- PORT NOTE: PC hand_type "aij_Royal Flush" becomes the fork hand
-- name "Royal Flush" -- DEPENDENCY: the JestPack poker-hands part
-- must register SMODS.PokerHand "Royal Flush". PC's in_pool gate
-- (Royal Flush played >= 1) reads per-hand played counts in a pool
-- context; dropped per the wave-4 pool-gate convention.
SMODS.Consumable {
    set = "Planet", key = "sol",
    loc_txt = { name = "Sol" },
    config = { hand_type = "Royal Flush" },
    cost = 3,
    sprite = "sol.png",
    negative_sprite = "sol_negative.png",
}

-- Dark Star: level up all hands that haven't been played yet.
-- PORT NOTE: PC distinguishes visible (animated) from hidden
-- (instant) unplayed hands; the fork levels both through the same
-- funnel, which is the same end state. PC's in_pool gate (ante >= 4
-- and some visible hand played) reads run state a pool context does
-- not expose here; dropped per convention.
SMODS.Consumable {
    set = "Planet", key = "dark_star",
    loc_txt = {
        name = "Dark Star",
        text = {
            "Level up {C:attention}all hands{}",
            "that haven't been {C:attention}played{} yet",
        },
    },
    config = {},
    cost = 3,
    sprite = "dark_star.png",
    negative_sprite = "dark_star_negative.png",
    can_use = function(self, card)
        if not (G and G.handlist) then return false end
        for i in ipairs(G.handlist) do
            local visible = not G.is_hand_stats_visible
                or G:is_hand_stats_visible(i)
            local played = tonumber(G.hand_play_counts
                and G.hand_play_counts[i]) or 0
            if visible and played > 0 then return true end
        end
        return false
    end,
    use = function(self, card, area, copier)
        if not (G and G.handlist and G.upgrade_hand_level_at_index) then
            return
        end
        for i in ipairs(G.handlist) do
            local played = tonumber(G.hand_play_counts
                and G.hand_play_counts[i]) or 0
            if played == 0 then
                G:upgrade_hand_level_at_index(i)
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Planets: the 32 Moons (jest_spec_moon). All are rewrites on the
-- jest_moon_step compensation (see header). PC "softlock" flags are
-- SMODS pool metadata with no fork seat and are dropped.
-- The eight paper_* moons target Paperback's Spectrum hands; their
-- fork names are the PaperbackPack/BuncoPack registrations
-- ("Spectrum", "Straight Spectrum", "Spectrum House",
-- "Spectrum Five") -- cross-pack dependency: without a pack that
-- registers those hands, the moon's use finds no hand and does
-- nothing, as on PC without Paperback installed.
--------------------------------------------------------------------------------

local function jest_moon(key, name, hand, stat, text_amount_word)
    SMODS.Consumable {
        set = "Planet", key = key,
        loc_txt = {
            name = name,
            text = {
                "{C:inactive}(lvl.#1#){} Level up {C:attention}#2#{}",
                text_amount_word == "chips"
                    and "{C:chips}+#3#{} Chips"
                    or "{C:mult}+#3#{} Mult",
            },
        },
        config = { extra = { hand = hand, stat = stat } },
        cost = 3,
        sprite = key .. ".png",
        negative_sprite = key .. "_negative.png",
        loc_vars = function(self, info_queue, card)
            local extra = (card and card.ability
                and card.ability.extra)
                or (self.config and self.config.extra) or {}
            local hand_name = extra.hand or ""
            local amount = 0
            local idx = jest_hand_index(hand_name)
            local stats = idx and G and G.hand_stats
                and G.hand_stats[idx]
            if stats then
                local per = extra.stat == "chips"
                    and stats.chips_per_level or stats.mult_per_level
                amount = 2 * (tonumber(per) or 0)
            end
            return {
                vars = {
                    jest_hand_level(hand_name), hand_name, amount,
                },
            }
        end,
        can_use = function(self, card)
            return true
        end,
        use = function(self, card, area, copier)
            local extra = (card and card.ability
                and card.ability.extra) or {}
            local idx = extra.hand and jest_hand_index(extra.hand)
            if idx then jest_moon_step(idx, extra.stat) end
        end,
    }
end

-- Chips moons
jest_moon("2000_eu16", "2000 EU16", "Flush House", "chips", "chips")
jest_moon("2013_nd15", "2013 ND15", "Three of a Kind", "chips", "chips")
jest_moon("callisto", "Callisto", "Flush", "chips", "chips")
jest_moon("charon", "Charon", "High Card", "chips", "chips")
jest_moon("deimos", "Deimos", "Four of a Kind", "chips", "chips")
jest_moon("iapetus", "Iapetus", "Straight", "chips", "chips")
jest_moon("kamooalewa", "Kamooalewa", "Full House", "chips", "chips")
jest_moon("kuiper", "Kuiper", "Flush Five", "chips", "chips")
jest_moon("nibiru", "Nibiru", "Five of a Kind", "chips", "chips")
jest_moon("oberon", "Oberon", "Two Pair", "chips", "chips")
jest_moon("phaethon", "Phaethon", "Pair", "chips", "chips")
jest_moon("proteus", "Proteus", "Straight Flush", "chips", "chips")
jest_moon("paper_hiiaka", "Hiiaka", "Straight Spectrum", "chips", "chips")
jest_moon("paper_ixion", "Ixion", "Spectrum", "chips", "chips")
jest_moon("paper_mk2", "Mk2", "Spectrum Five", "chips", "chips")
jest_moon("paper_varda", "Varda", "Spectrum House", "chips", "chips")
-- Mult moons
jest_moon("dysnomia", "Dysnomia", "Flush Five", "mult", "mult")
jest_moon("europa", "Europa", "Flush", "mult", "mult")
jest_moon("luna", "Luna", "Full House", "mult", "mult")
jest_moon("nix", "Nix", "High Card", "mult", "mult")
jest_moon("pallas", "Pallas", "Flush House", "mult", "mult")
jest_moon("phobos", "Phobos", "Four of a Kind", "mult", "mult")
jest_moon("planet_nine", "Planet Nine", "Five of a Kind", "mult", "mult")
jest_moon("titan", "Titan", "Straight", "mult", "mult")
jest_moon("triton", "Triton", "Straight Flush", "mult", "mult")
jest_moon("umbriel", "Umbriel", "Two Pair", "mult", "mult")
jest_moon("vulcanoid", "Vulcanoid", "Pair", "mult", "mult")
jest_moon("zoozve", "Zoozve", "Three of a Kind", "mult", "mult")
jest_moon("paper_ilmare", "Ilmare", "Spectrum House", "mult", "mult")
jest_moon("paper_namaka", "Namaka", "Straight Spectrum", "mult", "mult")
jest_moon("paper_salacia", "Salacia", "Spectrum Five", "mult", "mult")
jest_moon("paper_weywot", "Weywot", "Spectrum", "mult", "mult")

--------------------------------------------------------------------------------
-- Spectrals: rewrites
--------------------------------------------------------------------------------

-- Gravastar / Pulsar: level up the Chips / Mult of ALL poker hands
-- (the moon step applied to every hand). PC deals both through the
-- Planet pool's soul roll (soul_set = "Planet"); the fork has no
-- soul roll, so they sit in the Spectral pool like any Spectral --
-- distribution deviation, named here.
local function jest_all_hands_moon(key, name, stat)
    SMODS.Consumable {
        set = "Spectral", key = key,
        loc_txt = {
            name = name,
            text = {
                "{C:attention}Levels up{} the "
                    .. (stat == "chips" and "{C:chips}Chips{}"
                        or "{C:mult}Mult{}")
                    .. " of all {C:attention}poker hands{}",
            },
        },
        config = { extra = { stat = stat } },
        cost = 4,
        sprite = key .. ".png",
        negative_sprite = key .. "_negative.png",
        can_use = function(self, card)
            return true
        end,
        use = function(self, card, area, copier)
            if not (G and G.handlist) then return end
            for i in ipairs(G.handlist) do
                jest_moon_step(i, stat)
            end
        end,
    }
end

jest_all_hands_moon("gravastar", "Gravastar", "chips")
jest_all_hands_moon("pulsar", "Pulsar", "mult")

-- Maw: destroys a random Joker and all cards held in hand.
-- PORT NOTE: PC destroys through SMODS.destroy_cards (batch); the
-- fork destroys one at a time (SMODS.destroy_joker / destroy_card).
-- PC spares eternal Jokers when picking the victim; so does the port.
SMODS.Consumable {
    set = "Spectral", key = "maw",
    loc_txt = {
        name = "Maw",
        text = {
            "{C:red}Destroys{} a random {C:attention}Joker{}",
            "and {C:attention}all cards{} held in hand",
        },
    },
    config = {},
    cost = 4,
    sprite = "maw.png",
    negative_sprite = "maw_negative.png",
    can_use = function(self, card)
        if #jest_hand_nodes() == 0 then return false end
        for _, j in ipairs((G and G.jokers) or {}) do
            if not j.eternal then return true end
        end
        return false
    end,
    use = function(self, card, area, copier)
        local viable = {}
        for _, j in ipairs((G and G.jokers) or {}) do
            if not j.eternal then viable[#viable + 1] = j end
        end
        local victim = pseudorandom_element(viable, "aij_maw")
        if victim and SMODS.destroy_joker then
            SMODS.destroy_joker(victim)
        end
        local nodes = {}
        for _, node in ipairs(jest_hand_nodes()) do
            nodes[#nodes + 1] = node
        end
        if SMODS.destroy_card then
            for _, node in ipairs(nodes) do
                SMODS.destroy_card(node)
            end
        end
    end,
}

-- Palmistry: apply a random enhancement to each card held in hand.
-- PORT NOTE: PC set_ability per card with an ante-keyed poll; the
-- port writes each node's card_data.enhancement from
-- SMODS.poll_enhancement (port value string) and syncs.
SMODS.Consumable {
    set = "Spectral", key = "palmistry",
    loc_txt = {
        name = "Palmistry",
        text = {
            "Apply a random {C:attention}enhancement{}",
            "to each card {C:attention}held in hand{}",
        },
    },
    config = {},
    cost = 4,
    sprite = "palmistry.png",
    negative_sprite = "palmistry_negative.png",
    can_use = function(self, card)
        return #jest_hand_nodes() > 0
    end,
    use = function(self, card, area, copier)
        if not SMODS.poll_enhancement then return end
        for _, node in ipairs(jest_hand_nodes()) do
            local d = node and node.card_data
            if d then
                local enh = SMODS.poll_enhancement({
                    guaranteed = true, key = "aij_palmistry",
                })
                if enh then
                    d.enhancement = enh
                    jest_sync(node)
                end
            end
        end
    end,
}

-- Shade: add Negative edition to 1 random card in hand.
-- PORT NOTE: PC applies its own e_aij_negative_playing_card (a
-- re-skin of vanilla Negative; part 2 registers nothing for it), so
-- the port applies the fork's built-in "negative" edition value
-- through card_data (the Cryptid Conduit pattern).
SMODS.Consumable {
    set = "Spectral", key = "shade",
    loc_txt = {
        name = "Shade",
        text = {
            "Add {C:dark_edition}Negative{} edition to",
            "{C:attention}#1#{} random card in hand",
        },
    },
    config = { extra = 1 },
    cost = 4,
    sprite = "shade.png",
    negative_sprite = "shade_negative.png",
    loc_vars = function(self, info_queue, card)
        local n = (card and card.ability and card.ability.extra)
            or (self.config and self.config.extra) or 1
        return { vars = { n } }
    end,
    can_use = function(self, card)
        for _, node in ipairs(jest_hand_nodes()) do
            local d = node and node.card_data
            if d and not jest_card_edition(d) then return true end
        end
        return false
    end,
    use = function(self, card, area, copier)
        local count = tonumber(card and card.ability
            and card.ability.extra) or 1
        local pool = {}
        for _, node in ipairs(jest_hand_nodes()) do
            local d = node and node.card_data
            if d and not jest_card_edition(d) then
                pool[#pool + 1] = node
            end
        end
        for _ = 1, count do
            if #pool == 0 then break end
            local pick = pseudorandom_element(pool, "aij_shade")
            for i, node in ipairs(pool) do
                if node == pick then
                    table.remove(pool, i)
                    break
                end
            end
            local d = pick and pick.card_data
            if d then
                jest_set_card_edition(d, "negative")
                jest_sync(pick)
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Hex Tarots (set aij_hex_tarot): rewrites. See the header for the
-- distribution deviation (no Tarot soul roll in the fork).
--------------------------------------------------------------------------------

-- The Faceless: destroy leftmost Joker, create a Negative Joker of
-- lower rarity.
-- PORT NOTE: PC's SMODS rarity-poll values (0 / 0.6 / 0.9 / 1 for
-- victim rarities 1-4) land exactly one rarity band below the
-- victim, so the port rolls that band directly with
-- G:random_joker_def_id_by_rarity. A Common victim creates nothing
-- (PC shows "Nope!"), but is still destroyed, as on PC.
SMODS.Consumable {
    set = "aij_hex_tarot", key = "faceless",
    loc_txt = {
        name = "The Faceless",
        text = {
            "{C:red}Destroy{} leftmost {C:attention}Joker{} and",
            "create a {C:dark_edition}Negative{} {C:attention}Joker{}",
            "of lower rarity",
        },
    },
    config = {},
    cost = 6,
    sprite = "faceless.png",
    negative_sprite = "faceless_negative.png",
    can_use = function(self, card)
        local jokers = (G and G.jokers) or {}
        return #jokers >= 1 and not jokers[1].eternal
    end,
    use = function(self, card, area, copier)
        local jokers = (G and G.jokers) or {}
        local victim = jokers[1]
        if not victim then return end
        local rarity = tonumber(victim.rarity) or 1
        if SMODS.destroy_joker then SMODS.destroy_joker(victim) end
        if rarity > 1 and G and G.random_joker_def_id_by_rarity then
            local id = G:random_joker_def_id_by_rarity(rarity - 1,
                "aij_faceless")
            if id then
                SMODS.add_card {
                    set = "Joker", key = id, edition = "negative",
                }
            end
        end
    end,
}

-- The Janitor: destroy all cards held in hand.
SMODS.Consumable {
    set = "aij_hex_tarot", key = "janitor",
    loc_txt = {
        name = "The Janitor",
        text = {
            "{C:red}Destroy{} all cards",
            "held in {C:attention}hand{}",
        },
    },
    config = {},
    cost = 6,
    sprite = "janitor.png",
    negative_sprite = "janitor_negative.png",
    can_use = function(self, card)
        return #jest_hand_nodes() > 0
    end,
    use = function(self, card, area, copier)
        local nodes = {}
        for _, node in ipairs(jest_hand_nodes()) do
            nodes[#nodes + 1] = node
        end
        if SMODS.destroy_card then
            for _, node in ipairs(nodes) do
                SMODS.destroy_card(node)
            end
        end
    end,
}

-- The Oracle: all cards in hand gain a single random enhancement.
SMODS.Consumable {
    set = "aij_hex_tarot", key = "oracle",
    loc_txt = {
        name = "The Oracle",
        text = {
            "{C:attention}All{} cards in your hand are",
            "given a {C:attention}single random{} enhancement",
        },
    },
    config = {},
    cost = 6,
    sprite = "oracle.png",
    negative_sprite = "oracle_negative.png",
    can_use = function(self, card)
        return #jest_hand_nodes() > 0
    end,
    use = function(self, card, area, copier)
        if not SMODS.poll_enhancement then return end
        local enh = SMODS.poll_enhancement({
            guaranteed = true, key = "aij_oracle",
        })
        if not enh then return end
        for _, node in ipairs(jest_hand_nodes()) do
            local d = node and node.card_data
            if d then
                d.enhancement = enh
                jest_sync(node)
            end
        end
    end,
}

end -- SMODS.Consumable

--------------------------------------------------------------------------------
-- Tags
--------------------------------------------------------------------------------

if SMODS.Tag then

-- Soulbound Tag: creates a random Perishable Legendary Joker.
-- PORT NOTE: PC polls the perishable-compatible Legendary pool
-- through SMODS.create_poll_pool / poll_object; the port rolls
-- G:random_joker_def_id_by_rarity(4) and retries past any
-- perishable-incompatible result (destroying the misfit), then sets
-- the instance's perishable fields directly (the fork saves them;
-- Cryptid sets instance sticker fields the same way).
SMODS.Tag {
    key = "soulbound",
    loc_txt = {
        name = "Soulbound Tag",
        text = {
            "Creates a random {C:attention}Perishable{}",
            "{C:legendary}Legendary{} Joker",
            "{C:inactive}(Must have room)",
        },
    },
    config = { type = "immediate" },
    min_ante = 4,
    sprite = "soulbound.png",
    apply = function(self, tag, context)
        if not (G and G.random_joker_def_id_by_rarity) then
            return false
        end
        local cap = tonumber(G.joker_capacity) or (#G.jokers + 1)
        if #G.jokers >= cap then return false end
        for _ = 1, 8 do
            local id = G:random_joker_def_id_by_rarity(4,
                "aij_soulbound")
            if not id then return false end
            local j = SMODS.add_card { set = "Joker", key = id }
            if not j then return false end
            if j.def and j.def.perishable_compat == false then
                if SMODS.destroy_joker then SMODS.destroy_joker(j) end
            else
                j.perishable = true
                j.perishable_counter = 5
                return true
            end
        end
        return false
    end,
}

-- Windfall Tag (Gold): triples your money (gain capped at $300).
-- Direct port: PC ease_dollars(min(dollars, 150) * 2).
SMODS.Tag {
    key = "windfall",
    loc_txt = {
        name = "Windfall Tag",
        text = {
            "{C:money}Triples{} your money",
            "{C:inactive}(Max of {C:money}$300{C:inactive})",
        },
    },
    config = { type = "immediate" },
    weight = 0,
    sprite = "windfall.png",
    apply = function(self, tag, context)
        local money = tonumber(G and G.money) or 0
        ease_dollars(math.max(0, math.min(money, 150) * 2))
        return true
    end,
}

-- Velocity Tag (Gold): gives $100, minus $2 per round.
-- PORT NOTE: PC reads G.GAME.round; the fork carries the same
-- counter as G.round (sibling packs read G.ante the same way).
-- PC's in_pool gate (round <= 19) is expressible and kept.
SMODS.Tag {
    key = "velocity",
    loc_txt = {
        name = "Velocity Tag",
        text = {
            "Gives {C:money}$#1#{}, minus {C:money}$#2#{}",
            "per {C:attention}round{}",
            "{C:inactive}(Will give {C:money}$#3#{C:inactive})",
        },
    },
    config = { type = "immediate", extra = { money = 100, money_mod = 2 } },
    weight = 0,
    sprite = "velocity.png",
    loc_vars = function(self, info_queue, tag)
        local extra = (tag and tag.ability and tag.ability.extra)
            or self.config.extra or {}
        local round = tonumber(G and G.round) or 1
        local cur = math.max(0, (extra.money or 100)
            - (extra.money_mod or 2) * round)
        return { vars = { extra.money or 100, extra.money_mod or 2, cur } }
    end,
    in_pool = function(self, game)
        return (tonumber(G and G.round) or 1) <= 19
    end,
    apply = function(self, tag, context)
        local extra = (tag and tag.ability and tag.ability.extra)
            or self.config.extra or {}
        local round = tonumber(G and G.round) or 1
        local gain = math.max(0, (extra.money or 100)
            - (extra.money_mod or 2) * round)
        ease_dollars(gain)
        return true
    end,
}

-- Capital Tag (Gold): after defeating the Boss Blind, gain $100.
-- PORT NOTE: PC returns a payout table from the eval moment; the
-- fork's eval context (Boss payout only, as on PC) carries
-- add_round_win_payout(label, dollars) for exactly this.
SMODS.Tag {
    key = "capital",
    loc_txt = {
        name = "Capital Tag",
        text = {
            "After defeating the Boss Blind,",
            "gain {C:money}$#1#{}",
        },
    },
    config = { type = "eval", extra = { dollars = 100 } },
    weight = 0,
    sprite = "capital.png",
    loc_vars = function(self, info_queue, tag)
        local extra = (tag and tag.ability and tag.ability.extra)
            or self.config.extra or {}
        return { vars = { extra.dollars or 100 } }
    end,
    apply = function(self, tag, context)
        if context and type(context.add_round_win_payout) == "function" then
            local extra = (tag and tag.ability and tag.ability.extra)
                or self.config.extra or {}
            context.add_round_win_payout("Capital Tag",
                extra.dollars or 100)
            return true
        end
        return false
    end,
}

-- Landfill Tag (Gold): gives $1 per card discarded this run.
-- PORT NOTE: PC reads G.GAME.round_scores.cards_discarded.amt; the
-- fork keeps the same run counter as G.run_cards_discarded.
SMODS.Tag {
    key = "landfill",
    loc_txt = {
        name = "Landfill Tag",
        text = {
            "Gives {C:money}$1{} per card {C:red}discarded{}",
            "this run",
            "{C:inactive}(Will give {C:money}$#1#{C:inactive})",
        },
    },
    config = { type = "immediate" },
    min_ante = 2,
    weight = 0,
    sprite = "landfill.png",
    loc_vars = function(self, info_queue, tag)
        return { vars = { tonumber(G and G.run_cards_discarded) or 0 } }
    end,
    apply = function(self, tag, context)
        ease_dollars(tonumber(G and G.run_cards_discarded) or 0)
        return true
    end,
}

-- Bierstiefel Tag (Gold): fill all empty Joker slots with random
-- Common or Uncommon Jokers.
-- PORT NOTE: PC's SMODS rarity roll (pseudorandom() * 0.95) lands
-- Common below 0.7 and Uncommon above it -- a 70:25 split the port
-- reproduces before rolling the band with
-- G:random_joker_def_id_by_rarity. Slot room reads G.joker_capacity.
SMODS.Tag {
    key = "bierstiefel",
    loc_txt = {
        name = "Bierstiefel Tag",
        text = {
            "Fill all empty {C:attention}Joker slots{} with",
            "random {C:common}Common{} or {C:uncommon}Uncommon{} Jokers",
        },
    },
    config = { type = "immediate" },
    min_ante = 2,
    weight = 0,
    sprite = "bierstiefel.png",
    apply = function(self, tag, context)
        if not (G and G.random_joker_def_id_by_rarity) then
            return false
        end
        local cap = tonumber(G.joker_capacity)
        if not cap or #G.jokers >= cap then return false end
        local created = false
        while #G.jokers < cap do
            local band = SMODS.pseudorandom("aij_bierstiefel", 1, 95)
                <= 70 and 1 or 2
            local id = G:random_joker_def_id_by_rarity(band,
                "aij_bierstiefel")
            if not id then break end
            if not SMODS.add_card { set = "Joker", key = id } then
                break
            end
            created = true
        end
        return created
    end,
}

-- Circumplanetary Tag (Gold): upgrade most played poker hand by
-- 3 levels.
-- PORT NOTE: PC level_up_hand x3 becomes three trips through the
-- fork's own funnel (which also raises the level_up_hand context,
-- as PC's does).
SMODS.Tag {
    key = "circumplanetary",
    loc_txt = {
        name = "Circumplanetary Tag",
        text = {
            "Upgrade {C:attention}most played poker hand{}",
            "by {C:attention}#1#{} levels",
            "{C:inactive}(Currently #2#)",
        },
    },
    config = { type = "immediate", extra = { times = 3 } },
    min_ante = 3,
    weight = 0,
    sprite = "circumplanetary.png",
    loc_vars = function(self, info_queue, tag)
        local extra = (tag and tag.ability and tag.ability.extra)
            or self.config.extra or {}
        local idx = jest_most_played_hand_index()
        local hand_name = (idx and G.handlist[idx])
            or "[most played hand]"
        return { vars = { extra.times or 3, hand_name } }
    end,
    apply = function(self, tag, context)
        local idx = jest_most_played_hand_index()
        if not idx then return false end
        if not (G and G.upgrade_hand_level_at_index) then
            return false
        end
        local extra = (tag and tag.ability and tag.ability.extra)
            or self.config.extra or {}
        for _ = 1, (extra.times or 3) do
            G:upgrade_hand_level_at_index(idx)
        end
        return true
    end,
}

-- Occult Tag (Gold): create 3 Tarot cards and 2 Spectral cards,
-- all Negative.
-- PORT NOTE: PC create_consumable with a Negative edition becomes
-- the fork's kind roll + SMODS.add_card with edition = "negative"
-- (order as on PC: Tarot, then Tarot/Spectral twice). PC creates
-- through the consumable buffer; the fork creates only while there
-- is room, so a nearly full consumable area may yield fewer cards.
SMODS.Tag {
    key = "occult",
    loc_txt = {
        name = "Occult Tag",
        text = {
            "Create {C:attention}3{} {C:tarot}Tarot{} cards and",
            "{C:attention}2{} {C:spectral}Spectral{} cards",
            "{C:inactive}They are {C:dark_edition}Negative{}",
        },
    },
    config = { type = "immediate" },
    weight = 0,
    sprite = "occult.png",
    apply = function(self, tag, context)
        if not (G and G.random_consumable_id_of_kind) then
            return false
        end
        local kinds = { "Tarot", "Tarot", "Spectral", "Tarot",
            "Spectral" }
        local created = false
        for _, kind in ipairs(kinds) do
            local id = G:random_consumable_id_of_kind(
                kind:lower())
            if id then
                local c = SMODS.add_card {
                    set = kind, key = id, edition = "negative",
                }
                if c then created = true end
            end
        end
        return created
    end,
}

end -- SMODS.Tag

--------------------------------------------------------------------------------
-- JestPack fragment: All in Jest non-Joker content, part 2
-- (Boosters / Vouchers / Enhancements / Editions / Seals / Decks / Other).
--
-- PC source: "All in Jest" v0.7.4 by Nevernamed, Survivalaren and others
-- (https://github.com/survovoaneend/All-In-Jest). Ported under the pack's
-- usual terms; see census_nonjoker_2.md for the item-by-item verdicts.
--
-- Only three groups survived the fork's API (see the census for the named
-- blockers on everything else):
--   * the eight Sidereal booster packs -- DEPENDENCY: they deal from the
--     "aij_astral" consumable kind, so they only work once the JestPack
--     consumables fragment registers SMODS.ConsumableType "aij_astral"
--     (a plain ConsumableType, ported in the consumables part).
--   * the Fervent and Wood enhancements.
--
-- Deviations (each named, none silent):
--   * Sidereal weights: PC splits a family weight across its art variants
--     (0.6 / 0.3 / 0.07 total); the fork's pool units are ~100x Steamodded's,
--     so each variant registers its per-variant share x100 (15 / 15 / 3.5).
--   * Fervent: PC grows the enhancement's own `bonus` field during scoring.
--     The fork has no per-enhancement ability store, so the grown total is
--     kept in card_data (aij_fervent_bonus) and grown-and-paid in the one
--     card_played step, the PaperbackPack Antique pattern; the running
--     total lands on the same plays. PC's tooltip shows only the growth
--     amount, and so does this one.
--   * Wood: PC counts Wood cards through SMODS.has_enhancement; the port
--     counts hand nodes whose enhancement value is "wood" -- the same set.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Sidereal booster packs (Astral cards)
-- PC generates 4 normal / 2 jumbo / 2 mega art variants from one base def;
-- every variant shares the p_aij_sidereal name and text.
--------------------------------------------------------------------------------

if SMODS.Booster then

SMODS.Booster {
    key = "sidereal_normal_1",
    loc_txt = { name = "Sidereal Pack", text = {
        "Choose {C:attention}1{} of up to",
        "{C:attention}3{} {C:spectral}Astral{} cards to",
        "be used immediately",
    } },
    pool = { consumable = "aij_astral" },
    card_count = 3, picks = 1, cost = 4, weight = 15,
    sprite = "sidereal_normal_1.png",
}

SMODS.Booster {
    key = "sidereal_normal_2",
    loc_txt = { name = "Sidereal Pack", text = {
        "Choose {C:attention}1{} of up to",
        "{C:attention}3{} {C:spectral}Astral{} cards to",
        "be used immediately",
    } },
    pool = { consumable = "aij_astral" },
    card_count = 3, picks = 1, cost = 4, weight = 15,
    sprite = "sidereal_normal_2.png",
}

SMODS.Booster {
    key = "sidereal_normal_3",
    loc_txt = { name = "Sidereal Pack", text = {
        "Choose {C:attention}1{} of up to",
        "{C:attention}3{} {C:spectral}Astral{} cards to",
        "be used immediately",
    } },
    pool = { consumable = "aij_astral" },
    card_count = 3, picks = 1, cost = 4, weight = 15,
    sprite = "sidereal_normal_3.png",
}

SMODS.Booster {
    key = "sidereal_normal_4",
    loc_txt = { name = "Sidereal Pack", text = {
        "Choose {C:attention}1{} of up to",
        "{C:attention}3{} {C:spectral}Astral{} cards to",
        "be used immediately",
    } },
    pool = { consumable = "aij_astral" },
    card_count = 3, picks = 1, cost = 4, weight = 15,
    sprite = "sidereal_normal_4.png",
}

SMODS.Booster {
    key = "sidereal_jumbo_1",
    loc_txt = { name = "Sidereal Pack", text = {
        "Choose {C:attention}1{} of up to",
        "{C:attention}5{} {C:spectral}Astral{} cards to",
        "be used immediately",
    } },
    pool = { consumable = "aij_astral" },
    card_count = 5, picks = 1, cost = 6, weight = 15,
    sprite = "sidereal_jumbo_1.png",
}

SMODS.Booster {
    key = "sidereal_jumbo_2",
    loc_txt = { name = "Sidereal Pack", text = {
        "Choose {C:attention}1{} of up to",
        "{C:attention}5{} {C:spectral}Astral{} cards to",
        "be used immediately",
    } },
    pool = { consumable = "aij_astral" },
    card_count = 5, picks = 1, cost = 6, weight = 15,
    sprite = "sidereal_jumbo_2.png",
}

SMODS.Booster {
    key = "sidereal_mega_1",
    loc_txt = { name = "Sidereal Pack", text = {
        "Choose {C:attention}2{} of up to",
        "{C:attention}5{} {C:spectral}Astral{} cards to",
        "be used immediately",
    } },
    pool = { consumable = "aij_astral" },
    card_count = 5, picks = 2, cost = 8, weight = 3.5,
    sprite = "sidereal_mega_1.png",
}

SMODS.Booster {
    key = "sidereal_mega_2",
    loc_txt = { name = "Sidereal Pack", text = {
        "Choose {C:attention}2{} of up to",
        "{C:attention}5{} {C:spectral}Astral{} cards to",
        "be used immediately",
    } },
    pool = { consumable = "aij_astral" },
    card_count = 5, picks = 2, cost = 8, weight = 3.5,
    sprite = "sidereal_mega_2.png",
}

end -- SMODS.Booster

-- JestPack fragment: Wave 4 chunk 00 PORTABLE Jokers (worker 0).
-- Ported from All in Jest (Items/Jokers) against the Balatro3DS fork API.
-- Unlock conditions are not registered by the fork; all defs use
-- unlocked = true, discovered = true (sibling-pack convention).

local G
local function jest0_refresh()
    G = rawget(_G, "G") or G
end

SMODS.Joker {
    key = "a_young_hamlet",
    sprite = "a_young_hamlet.png",
    negative_sprite = "a_young_hamlet_negative.png",
    loc_txt = {
        name = "A Young Hamlet",
        text = {
            "This Joker gains {C:mult}+#2#{} Mult",
            "every {C:attention}#3#{C:inactive} [#4#]{} cards {C:red}discarded{}",
            "{C:inactive}(Currently {C:mult}+#1#{C:inactive} Mult)",
        },
    },
    config = { extra = { mult = 0, mult_mod = 1, discards = 6, discards_remaining = 6 } },
    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult, card.ability.extra.mult_mod,
            card.ability.extra.discards, card.ability.extra.discards_remaining } }
    end,
    calculate = function(self, card, context)
        if context.discard and not context.blueprint then
            if card.ability.extra.discards_remaining <= 1 then
                card.ability.extra.discards_remaining = card.ability.extra.discards
                card.ability.extra.mult = card.ability.extra.mult + card.ability.extra.mult_mod
            else
                card.ability.extra.discards_remaining = card.ability.extra.discards_remaining - 1
            end
        end
        if context.joker_main then
            return { mult = card.ability.extra.mult }
        end
    end,
}

SMODS.Joker {
    key = "abandoned_joker",
    sprite = "abandoned_joker.png",
    negative_sprite = "abandoned_joker_negative.png",
    loc_txt = {
        name = "Abandoned Joker",
        text = {
            "{C:red}Destroy{} all played {C:attention}face",
            "cards on {C:attention}first hand{} of round",
        },
    },
    config = { extra = {} },
    rarity = 2,
    cost = 7,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = false,
    perishable_compat = true,
    loc_vars = function(self, info_queue, card)
        return { vars = {} }
    end,
    calculate = function(self, card, context)
        jest0_refresh()
        if context.after and not context.blueprint and G
            and G:get_round_hands_played() == 0 then
            local destroyed = false
            for i = 1, #(context.full_hand or {}) do
                local node = context.full_hand[i]
                if node:is_face() then
                    if SMODS.destroy_card(node) then destroyed = true end
                end
            end
            if destroyed then
                return { message = "Destroyed!" }
            end
        end
    end,
}

SMODS.Joker {
    key = "alas",
    sprite = "alas.png",
    negative_sprite = "alas_negative.png",
    loc_txt = {
        name = "Alas!",
        text = {
            "This Joker gains {C:chips}+#1#{} Chips",
            "whenever a card is",
            "{C:red}discarded",
            "{C:inactive}(Currently {C:chips}+#2#{} {C:inactive}Chips){}",
        },
    },
    config = { extra = { chips = 0, chip_gain = 1 } },
    rarity = 1,
    cost = 5,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chip_gain, card.ability.extra.chips } }
    end,
    calculate = function(self, card, context)
        if context.discard and not context.blueprint
            and not (context.other_card and context.other_card.debuff) then
            card.ability.extra.chips = card.ability.extra.chips + card.ability.extra.chip_gain
            return { message = localize("k_upgrade_ex") }
        end
        if context.joker_main then
            return { chips = card.ability.extra.chips }
        end
    end,
}

SMODS.Joker {
    key = "alexandre",
    sprite = "alexandre.png",
    negative_sprite = "alexandre_negative.png",
    loc_txt = {
        name = "Alexandre",
        text = {
            "This Joker gains {C:mult}+#1#{}",
            "Mult if {C:attention}played hand{}",
            "is only {C:clubs}Club{} {C:attention}Kings{}",
            "{C:inactive}(Currently{} {C:mult}+#2#{C:inactive} Mult){}",
        },
    },
    config = { extra = { mult = 0, mult_mod = 7 } },
    rarity = 3,
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult_mod, card.ability.extra.mult } }
    end,
    calculate = function(self, card, context)
        if context.before then
            local club_kings, all_cards = 0, 0
            for _, v in ipairs(context.full_hand or {}) do
                all_cards = all_cards + 1
                if v:get_id() == 13 and v:is_suit("Clubs") then
                    club_kings = club_kings + 1
                end
            end
            if all_cards > 0 and club_kings == all_cards and not context.blueprint then
                card.ability.extra.mult = card.ability.extra.mult + card.ability.extra.mult_mod
            end
        end
        if context.joker_main then
            return { mult = card.ability.extra.mult }
        end
    end,
}

SMODS.Joker {
    key = "angel_number",
    sprite = "angel_number.png",
    negative_sprite = "angel_number_negative.png",
    loc_txt = {
        name = "Angel Number",
        text = {
            "{C:green}+#1#{} Odds this hand for",
            "each {C:attention}7{} in scoring hand",
        },
    },
    config = { extra = { numeratormod = 1, sevens = 0 } },
    rarity = 2,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.numeratormod } }
    end,
    calculate = function(self, card, context)
        if context.before and context.scoring_hand and not context.blueprint then
            local sevens = 0
            for i = 1, #context.scoring_hand do
                if context.scoring_hand[i]:get_id() == 7 then
                    sevens = sevens + 1
                end
            end
            if sevens > 0 then
                card.ability.extra.sevens = sevens
                return {
                    message = "+" .. (sevens * card.ability.extra.numeratormod) .. " Odds",
                }
            end
        end
        if context.mod_probability and context.trigger_obj then
            return {
                numerator = (context.numerator or 0)
                    + (card.ability.extra.sevens or 0) * card.ability.extra.numeratormod,
                denominator = context.denominator,
            }
        end
        if context.hand_drawn or context.end_of_round then
            card.ability.extra.sevens = 0
        end
    end,
}

SMODS.Joker {
    key = "angoulevent",
    sprite = "angoulevent.png",
    negative_sprite = "angoulevent_negative.png",
    soul_sprite = "angoulevent_soul.png",
    loc_txt = {
        name = "Angoulevent",
        text = {
            "Retrigger all played cards",
            "{C:attention}#1#{} additional times",
        },
    },
    config = { repetitions = 2 },
    rarity = 4,
    cost = 20,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.repetitions } }
    end,
    calculate = function(self, card, context)
        jest0_refresh()
        if context.repetition and context.cardarea == G.play then
            return {
                message = "Again!",
                repetitions = card.ability.repetitions,
            }
        end
    end,
}

SMODS.Joker {
    key = "animatronic",
    sprite = "animatronic.png",
    negative_sprite = "animatronic_negative.png",
    loc_txt = {
        name = "Animatronic",
        text = {
            "{C:attention}+#1#{} hand size per consecutive",
            "hand containing a {C:attention}Straight",
            "{C:inactive}(Currently {C:attention}+#2#{C:inactive} hand size){}",
            "{C:inactive}(Max of {C:attention}+#3#{C:inactive}){}",
        },
    },
    config = { h_size = 0, extra = { handsize_mod = 1, handsize = 0, cap = 4 } },
    rarity = 2,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.handsize_mod, card.ability.extra.handsize,
            card.ability.extra.cap } }
    end,
    calculate = function(self, card, context)
        if context.before and context.scoring_name and not context.blueprint then
            if context.poker_hands and next(context.poker_hands["Straight"]) then
                if card.ability.extra.handsize < card.ability.extra.cap then
                    card.ability.extra.handsize = card.ability.extra.handsize
                        + card.ability.extra.handsize_mod
                    card.ability.h_size = card.ability.extra.handsize
                    return { message = "+1 Hand Size" }
                end
            else
                if card.ability.extra.handsize > 0 then
                    card.ability.extra.handsize = 0
                    card.ability.h_size = 0
                    return { message = "Reset!" }
                end
            end
        end
    end,
}

SMODS.Joker {
    key = "antonio",
    sprite = "antonio.png",
    negative_sprite = "antonio_negative.png",
    soul_sprite = "antonio_soul.png",
    loc_txt = {
        name = "Antonio",
        text = {
            "When a card is {C:attention}scored{}, all",
            "cards in full deck with",
            "matching {C:attention}rank{} permanently",
            "gain {C:mult}+#1#{} Mult",
        },
    },
    config = { extra = { mult_mod = 1 } },
    rarity = 4,
    cost = 20,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult_mod } }
    end,
    calculate = function(self, card, context)
        jest0_refresh()
        if context.individual and context.cardarea == G.play and context.other_card then
            local rank = context.other_card:get_id()
            local mod = card.ability.extra.mult_mod
            local seen = {}
            local function bump(target)
                if target and not seen[target] then
                    seen[target] = true
                    SMODS.set_perma(target, "perma_mult",
                        (SMODS.get_perma(target, "perma_mult") or 0) + mod)
                end
            end
            for _, node in ipairs(context.full_hand or {}) do
                if node:get_id() == rank then bump(node) end
            end
            if G and G.hand and G.hand.card_nodes then
                for _, node in ipairs(G.hand.card_nodes) do
                    if node:get_id() == rank then bump(node) end
                end
            end
            if G and G.deck then
                for _, data in ipairs(G.deck.cards or {}) do
                    if tonumber(data.rank) == rank then bump(data) end
                end
                for _, data in ipairs(G.deck.discard_pile or {}) do
                    if tonumber(data.rank) == rank then bump(data) end
                end
            end
            return { message = localize("k_upgrade_ex") }
        end
    end,
}

SMODS.Joker {
    key = "art_of_the_deal",
    sprite = "art_of_the_deal.png",
    negative_sprite = "art_of_the_deal_negative.png",
    loc_txt = {
        name = "Art of the Deal",
        text = {
            "Gains {C:mult}+#2#{} Mult when",
            "{C:money}money{} is earned",
            "Resets if you have",
            "{C:money}$#3#{} or less",
            "{C:inactive}(Currently {C:mult}+#1#{C:inactive} Mult)",
        },
    },
    config = { extra = { mult = 0, mult_mod = 1, money_reset = 25 } },
    rarity = 2,
    cost = 7,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult, card.ability.extra.mult_mod,
            card.ability.extra.money_reset } }
    end,
    calculate = function(self, card, context)
        jest0_refresh()
        if context.money_altered and (context.amount or 0) >= 1 and G
            and (G.money or 0) > card.ability.extra.money_reset
            and not context.blueprint then
            card.ability.extra.mult = card.ability.extra.mult + card.ability.extra.mult_mod
        end
        if G and (G.money or 0) <= card.ability.extra.money_reset
            and card.ability.extra.mult ~= 0 and not context.blueprint then
            card.ability.extra.mult = 0
            return { message = "Reset!" }
        end
        if context.joker_main and card.ability.extra.mult > 0 then
            return { mult = card.ability.extra.mult }
        end
    end,
}

SMODS.Joker {
    key = "atom",
    sprite = "atom.png",
    negative_sprite = "atom_negative.png",
    loc_txt = {
        name = "Atom",
        text = {
            "Levels up {C:attention}High Card{}",
            "if played hand is",
            "a single {C:attention}Ace{}",
        },
    },
    config = {},
    rarity = 2,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    loc_vars = function(self, info_queue, card) end,
    calculate = function(self, card, context)
        if context.before and context.full_hand and #context.full_hand == 1
            and context.full_hand[1]:get_id() == 14 then
            return { level_up = 1, message = localize("k_upgrade_ex") }
        end
    end,
}

SMODS.Joker {
    key = "bad_apple",
    sprite = "bad_apple.png",
    negative_sprite = "bad_apple_negative.png",
    loc_txt = {
        name = "Bad Apple",
        text = {
            "This Joker gains {X:mult,C:white}X#2#{} Mult",
            "if {C:attention}scored hand{} contains",
            "{C:attention}#4#{} {C:spades}Dark{} suits and {C:attention}#3#{} {C:hearts}Light{} suits",
            "{C:inactive,s:0.8}(Proportion changes at end of round)",
            "{C:inactive}(Currently {X:mult,C:white}X#1#{} {C:inactive}Mult)",
        },
    },
    config = { extra = { xmult = 1, xmult_mod = 0.2, light_suits = 3, dark_suits = 2 } },
    rarity = 3,
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.xmult, card.ability.extra.xmult_mod,
            card.ability.extra.light_suits, card.ability.extra.dark_suits } }
    end,
    set_ability = function(self, card, initial)
        if initial then
            local random_value = SMODS.pseudorandom("jest_bad_apple", 0, 5)
            card.ability.extra.light_suits = random_value
            card.ability.extra.dark_suits = 5 - random_value
        end
    end,
    calculate = function(self, card, context)
        if context.end_of_round and not context.blueprint then
            local random_value = SMODS.pseudorandom("jest_bad_apple", 0, 5)
            card.ability.extra.light_suits = random_value
            card.ability.extra.dark_suits = 5 - random_value
            return { message = "Reset!" }
        end
        if context.before and not context.blueprint then
            local dark_count, light_count = 0, 0
            for _, scored in ipairs(context.scoring_hand or {}) do
                if scored:is_suit("Spades") or scored:is_suit("Clubs") then
                    dark_count = dark_count + 1
                elseif scored:is_suit("Hearts") or scored:is_suit("Diamonds") then
                    light_count = light_count + 1
                end
            end
            if dark_count == (card.ability.extra.dark_suits or 0)
                and light_count == (card.ability.extra.light_suits or 0) then
                card.ability.extra.xmult = card.ability.extra.xmult + card.ability.extra.xmult_mod
            end
        end
        if context.joker_main then
            return { xmult = card.ability.extra.xmult }
        end
    end,
}

SMODS.Joker {
    key = "bad_guy",
    sprite = "bad_guy.png",
    negative_sprite = "bad_guy_negative.png",
    loc_txt = {
        name = "Bad Guy",
        text = {
            "Apply {C:attention}Foil{} to a random",
            "card {C:attention}held in hand{} when",
            "{C:attention}Blind{} is defeated",
        },
    },
    config = {},
    rarity = 2,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    loc_vars = function(self, info_queue, card) end,
    calculate = function(self, card, context)
        jest0_refresh()
        if context.end_of_round and G and G.hand and G.hand.card_nodes
            and #G.hand.card_nodes > 0 then
            local target = pseudorandom_element(G.hand.card_nodes, "jest_bad_guy")
            if target and target.card_data and target.card_data.modifier then
                target.card_data.modifier.edition = "foil"
                return { message = "Foiled!" }
            end
        end
    end,
}

SMODS.Joker {
    key = "baroque_joker",
    sprite = "baroque_joker.png",
    negative_sprite = "baroque_joker_negative.png",
    loc_txt = {
        name = "Baroque Joker",
        text = {
            "This Joker gains {X:mult,C:white}X#2#{} Mult if",
            "played hand {C:attention}contains{} but is {C:attention}not",
            "{C:attention}scored as{} the last played hand",
            "{C:inactive}(Currently {X:mult,C:white}X#1#{C:inactive} Mult)",
        },
    },
    config = { extra = { xmult = 1, gain = 0.1, last_hand = nil } },
    rarity = 2,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.xmult, card.ability.extra.gain } }
    end,
    calculate = function(self, card, context)
        if context.before and not context.blueprint then
            local target_hand = card.ability.extra.last_hand
            if target_hand and context.poker_hands
                and next(context.poker_hands[target_hand])
                and context.scoring_name ~= target_hand then
                card.ability.extra.xmult = card.ability.extra.xmult + card.ability.extra.gain
                return { message = localize("k_upgrade_ex") }
            end
        end
        if context.after and not context.blueprint then
            card.ability.extra.last_hand = context.scoring_name
        end
        if context.joker_main then
            return { xmult = card.ability.extra.xmult }
        end
    end,
}

SMODS.Joker {
    key = "bartender",
    sprite = "bartender.png",
    negative_sprite = "bartender_negative.png",
    loc_txt = {
        name = "Bartender",
        text = {
            "Apply {C:dark_edition}Foil{}, {C:dark_edition}Holographic{}, or",
            "{C:dark_edition}Polychrome{} to a random held ",
            "{C:attention}consumable{} when leaving the {C:attention}Shop",
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
    loc_vars = function(self, info_queue, card) end,
    calculate = function(self, card, context)
        jest0_refresh()
        if context.ending_shop and G and G.consumables then
            local plain = {}
            for i, c in ipairs(G.consumables) do
                if not c.edition then plain[#plain + 1] = i end
            end
            if #plain > 0 then
                local idx = plain[SMODS.pseudorandom("jest_bartender", 1, #plain)]
                local editions = { "foil", "holo", "polychrome" }
                local edition = editions[SMODS.pseudorandom("jest_bartender", 1, #editions)]
                G.consumables[idx].edition = edition
                if G.consumable_nodes and G.consumable_nodes[idx] then
                    G.consumable_nodes[idx].edition = edition
                end
                return { message = "Edition!" }
            end
        end
    end,
}

SMODS.Joker {
    key = "bear",
    sprite = "bear.png",
    negative_sprite = "bear_negative.png",
    loc_txt = {
        name = "Bear",
        text = {
            "{C:mult}+#1#{} Mult per {C:money}$5{} you",
            "are {C:attention}below{} {C:money}$#2#",
            "{C:inactive}(Currently {C:mult}+#3#{C:inactive} Mult)",
        },
    },
    config = { extra = { mult = 1, dollars = 100 } },
    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    loc_vars = function(self, info_queue, card)
        jest0_refresh()
        local money = (G and G.money) or 0
        local diff = math.max(0, card.ability.extra.dollars - money)
        local mult_to_add = math.floor(diff / 5)
        return { vars = { card.ability.extra.mult, card.ability.extra.dollars,
            mult_to_add * card.ability.extra.mult } }
    end,
    calculate = function(self, card, context)
        jest0_refresh()
        if context.joker_main then
            local money = (G and G.money) or 0
            local diff = math.max(0, card.ability.extra.dollars - money)
            local mult_to_add = math.floor(diff / 5)
            if mult_to_add > 0 then
                return { mult = mult_to_add * card.ability.extra.mult }
            end
        end
    end,
}

SMODS.Joker {
    key = "bearded_joker",
    sprite = "bearded_joker.png",
    negative_sprite = "bearded_joker_negative.png",
    loc_txt = {
        name = "Bearded Joker",
        text = {
            "{C:mult}+#1#{} Mult for each {C:attention}Enhanced{}",
            "card in your {C:attention}full deck",
            "{C:inactive}(Currently {C:mult}+#2#{} {C:inactive}Mult)",
        },
    },
    config = { extra = { mult_mod = 2 } },
    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    loc_vars = function(self, info_queue, card)
        jest0_refresh()
        local tally = 0
        if G and G.count_cards_in_full_deck then
            tally = G:count_cards_in_full_deck(function(data)
                return data.enhancement ~= nil and data.enhancement ~= "base"
            end)
        end
        return { vars = { card.ability.extra.mult_mod, card.ability.extra.mult_mod * tally } }
    end,
    calculate = function(self, card, context)
        jest0_refresh()
        if context.joker_main then
            local tally = 0
            if G and G.count_cards_in_full_deck then
                tally = G:count_cards_in_full_deck(function(data)
                    return data.enhancement ~= nil and data.enhancement ~= "base"
                end)
            end
            return { mult = card.ability.extra.mult_mod * tally }
        end
    end,
}

SMODS.Joker {
    key = "bebe",
    sprite = "bebe.png",
    negative_sprite = "bebe_negative.png",
    soul_sprite = "bebe_soul.png",
    loc_txt = {
        name = "Bébé",
        text = {
            "{C:blue}+#1#{} Hands per round",
        },
    },
    config = { hands = 4, extra = { hands_size = 4 } },
    rarity = 4,
    cost = 20,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.hands_size } }
    end,
}

SMODS.Joker {
    key = "beekeeper",
    sprite = "beekeeper.png",
    negative_sprite = "beekeeper_negative.png",
    loc_txt = {
        name = "Beekeeper",
        text = {
            "{C:attention}6s{} held in hand",
            "give {C:chips}+#1#{} Chips and",
            "{C:mult}+#2#{} Mult",
        },
    },
    config = { extra = { chips = 20, mult = 4 } },
    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chips, card.ability.extra.mult } }
    end,
    calculate = function(self, card, context)
        jest0_refresh()
        if context.individual and context.cardarea == G.hand
            and not context.end_of_round and context.other_card
            and context.other_card:get_id() == 6 then
            if context.other_card.debuff then
                return { message = "Debuffed!" }
            end
            return {
                mult = card.ability.extra.mult,
                chips = card.ability.extra.chips,
            }
        end
    end,
}

SMODS.Joker {
    key = "beelzebub",
    sprite = "beelzebub.png",
    negative_sprite = "beelzebub_negative.png",
    loc_txt = {
        name = "Beelzebub",
        text = {
            "This Joker gains {C:mult}+#1#{} Mult",
            "when any {C:attention}playing card{} is",
            "added to {C:attention}deck",
            "{C:inactive}(Currently {C:mult}+#2#{C:inactive} Mult)",
        },
    },
    config = { extra = { mult = 0, gain = 3 } },
    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.gain, card.ability.extra.mult } }
    end,
    calculate = function(self, card, context)
        if context.playing_card_added and not context.blueprint then
            local n = 1
            if context.cards then n = #context.cards end
            card.ability.extra.mult = card.ability.extra.mult + card.ability.extra.gain * n
            return { message = localize("k_upgrade_ex") }
        end
        if context.joker_main then
            return { mult = card.ability.extra.mult }
        end
    end,
}

SMODS.Joker {
    key = "biancolelli",
    sprite = "biancolelli.png",
    negative_sprite = "biancolelli_negative.png",
    soul_sprite = "biancolelli_soul.png",
    loc_txt = {
        name = "Biancolelli",
        text = {
            "{C:aij_plasma}Balance{} {C:chips}Chips{} and {C:mult}Mult{}",
            "after Jokers trigger",
        },
    },
    config = {},
    rarity = 4,
    cost = 20,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    loc_vars = function(self, info_queue, card) end,
    calculate = function(self, card, context)
        if context.final_scoring_step then
            return { balance = true }
        end
    end,
}

SMODS.Joker {
    key = "big_ears",
    sprite = "big_ears.png",
    negative_sprite = "big_ears_negative.png",
    loc_txt = {
        name = "Big-Ears",
        text = {
            "This Joker gains {C:chips}+#2#{} Chips when",
            "an {C:attention}even{} card is scored,",
            "{C:red}-#3#{} Chips when",
            "an {C:attention}odd{} card is scored",
            "{C:inactive}(Currently {C:chips}+#1#{} {C:inactive}Chips)",
        },
    },
    config = { extra = { chips = 0, chip_mod = 2, chip_dec = 1 } },
    rarity = 2,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chips, card.ability.extra.chip_mod,
            card.ability.extra.chip_dec } }
    end,
    calculate = function(self, card, context)
        jest0_refresh()
        if context.individual and context.cardarea == G.play
            and not context.blueprint and context.other_card then
            local id = context.other_card:get_id()
            if id <= 10 and id % 2 == 0 then
                card.ability.extra.chips = card.ability.extra.chips + card.ability.extra.chip_mod
                return { message = localize("k_upgrade_ex") }
            elseif card.ability.extra.chips > 0
                and ((id <= 10 and id % 2 == 1) or id == 14) then
                card.ability.extra.chips = math.max(0,
                    card.ability.extra.chips - card.ability.extra.chip_dec)
                return { message = "Downgraded!" }
            end
        end
        if context.joker_main then
            return { chips = card.ability.extra.chips }
        end
    end,
}

SMODS.Joker {
    key = "big_red",
    sprite = "big_red.png",
    negative_sprite = "big_red_negative.png",
    loc_txt = {
        name = "Big Red",
        text = {
            "{C:mult}+#1#{} Mult",
            "Only {C:mult}Mult{} Jokers appear",
        },
    },
    config = { extra = { mult = 40 } },
    rarity = 3,
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            return { mult = card.ability.extra.mult }
        end
    end,
}

SMODS.Joker {
    key = "bingo_card",
    sprite = "bingo_card.png",
    negative_sprite = "bingo_card_negative.png",
    loc_txt = {
        name = "Bingo Card",
        text = {
            "Scored {C:attention}Lucky Cards{} have a",
            "{C:green}#1# in #2#{} chance for {X:mult,C:white}X#5#{} Mult",
            "and a {C:green}#3# in #4#{} chance to {C:attention}retrigger",
        },
    },
    config = { extra = { odds = 6, odds2 = 4, xmult = 2 } },
    rarity = 2,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    loc_vars = function(self, info_queue, card)
        local numerator1, denominator1 = SMODS.get_probability_vars(
            card, 1, card.ability.extra.odds, "bingo_card")
        local numerator2, denominator2 = SMODS.get_probability_vars(
            card, 1, card.ability.extra.odds2, "bingo_card")
        return { vars = { numerator1, denominator1, numerator2, denominator2,
            card.ability.extra.xmult } }
    end,
    calculate = function(self, card, context)
        jest0_refresh()
        if context.repetition and context.cardarea == G.play and context.other_card
            and context.other_card.enhancement == "lucky" then
            if SMODS.pseudorandom_probability(card, "bingo_card", 1, card.ability.extra.odds2) then
                return { repetitions = 1, message = "Again!" }
            end
        end
        if context.individual and context.cardarea == G.play and context.other_card
            and context.other_card.enhancement == "lucky" then
            if SMODS.pseudorandom_probability(card, "bingo_card", 1, card.ability.extra.odds) then
                return { xmult = card.ability.extra.xmult }
            end
        end
    end,
}

SMODS.Joker {
    key = "bingsu",
    sprite = "bingsu.png",
    negative_sprite = "bingsu_negative.png",
    loc_txt = {
        name = "Bingsu",
        text = {
            "All scoring cards give {C:chips}+#1#{} Chips",
            "{C:green}#3# in #4#{} chance to reduce",
            "by {C:chips}-#2#{} Chips when a card",
            "is scored",
        },
    },
    config = { extra = { chips = 50, chip_loss = 1, odds = 3 } },
    rarity = 2,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = false,
    perishable_compat = true,
    loc_vars = function(self, info_queue, card)
        local numerator, denominator = SMODS.get_probability_vars(
            card, 1, card.ability.extra.odds, "bingsu")
        return { vars = { card.ability.extra.chips, card.ability.extra.chip_loss,
            numerator, denominator } }
    end,
    calculate = function(self, card, context)
        jest0_refresh()
        if context.individual and context.cardarea == G.play then
            local chip_yield = card.ability.extra.chips
            if not context.blueprint then
                if SMODS.pseudorandom_probability(card, "bingsu", 1, card.ability.extra.odds) then
                    card.ability.extra.chips = card.ability.extra.chips
                        - card.ability.extra.chip_loss
                    if card.ability.extra.chips <= 0 then
                        SMODS.destroy_joker(card)
                        return { chips = chip_yield, message = "Eaten!" }
                    end
                    return {
                        chips = chip_yield,
                        message = "-" .. card.ability.extra.chip_loss .. " Chips",
                    }
                end
            end
            return { chips = chip_yield }
        end
    end,
}

SMODS.Joker {
    key = "birthday_clown",
    sprite = "birthday_clown.png",
    negative_sprite = "birthday_clown_negative.png",
    loc_txt = {
        name = "Birthday Clown",
        text = {
            "{X:mult,C:white}X#1#{} Mult for",
            "{C:attention}1{} round each {C:attention}Ante{}",
            "{C:inactive}#2#",
        },
    },
    config = { extra = { xmult = 3, active = true } },
    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    loc_vars = function(self, info_queue, card)
        local active_text = "(Inactive)"
        if card.ability.extra.active then active_text = "(Active)" end
        return { vars = { card.ability.extra.xmult, active_text } }
    end,
    calculate = function(self, card, context)
        if context.ante_change and (context.ante_change or 0) ~= 0 and context.ante_end then
            card.ability.extra.active = true
        end
        if card.ability.extra.active and context.joker_main then
            return { xmult = card.ability.extra.xmult }
        end
        if card.ability.extra.active and context.end_of_round then
            card.ability.extra.active = false
        end
    end,
}

SMODS.Joker {
    key = "blue_eyes_white_joker",
    sprite = "blue_eyes_white_joker.png",
    negative_sprite = "blue_eyes_white_joker_negative.png",
    loc_txt = {
        name = "Blue-Eyes White Joker",
        text = {
            "If {C:attention}final hand{} of round",
            "is exactly {C:attention}1{} card,",
            "it permanently gains",
            "{C:attention}+#1# retrigger",
        },
    },
    config = { extra = { retriggers = 1 } },
    rarity = 3,
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.retriggers } }
    end,
    calculate = function(self, card, context)
        jest0_refresh()
        if context.after and context.full_hand and G
            and (tonumber(G.hands) or -1) == 0 and #context.full_hand == 1 then
            local target = context.full_hand[1]
            SMODS.set_perma(target, "perma_repetitions",
                (SMODS.get_perma(target, "perma_repetitions") or 0)
                + card.ability.extra.retriggers)
            return { message = localize("k_upgrade_ex") }
        end
    end,
}

SMODS.Joker {
    key = "blue_star",
    sprite = "blue_star.png",
    negative_sprite = "blue_star_negative.png",
    loc_txt = {
        name = "Blue Star",
        text = {
            "{C:green}#1# in #2#{} chance to {C:attention}level up{}",
            "played poker hand if it",
            "contains a {C:attention}Bonus{} or",
            "{C:attention}Fervent Card",
        },
    },
    config = { extra = { odds = 2 } },
    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    loc_vars = function(self, info_queue, card)
        local numerator, denominator = SMODS.get_probability_vars(
            card, 1, card.ability.extra.odds, "blue_star")
        return { vars = { numerator, denominator } }
    end,
    calculate = function(self, card, context)
        if context.before and not context.blueprint then
            local trigger = false
            for _, v in ipairs(context.scoring_hand or {}) do
                if v.enhancement == "bonus" then
                    trigger = true
                    break
                end
            end
            if trigger and SMODS.pseudorandom_probability(
                card, "blue_star", 1, card.ability.extra.odds) then
                return { level_up = 1, message = "Level Up!" }
            end
        end
    end,
}

SMODS.Joker {
    key = "bluet",
    sprite = "bluet.png",
    negative_sprite = "bluet_negative.png",
    soul_sprite = "bluet_soul.png",
    loc_txt = {
        name = "Bluet",
        text = {
            "When {C:attention}Blind{} is selected,",
            "create a {C:dark_edition}Negative{}",
            "{C:spectral}Spectral{} card",
        },
    },
    config = {},
    rarity = 4,
    cost = 20,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    loc_vars = function(self, info_queue, card) end,
    calculate = function(self, card, context)
        if context.setting_blind then
            SMODS.add_card { set = "Spectral", edition = "negative" }
        end
    end,
}

SMODS.Joker {
    key = "body_pillow",
    sprite = "body_pillow.png",
    negative_sprite = "body_pillow_negative.png",
    loc_txt = {
        name = "Body Pillow",
        text = {
            "Played {C:attention}non-scoring{}",
            "cards earn {C:money}$#1#",
        },
    },
    config = { extra = { dollars = 2 } },
    rarity = 3,
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.dollars } }
    end,
    calculate = function(self, card, context)
        if context.before then
            local unscored = 0
            for _, played in ipairs(context.full_hand or {}) do
                local is_scoring = false
                for _, scoring in ipairs(context.scoring_hand or {}) do
                    if played == scoring then is_scoring = true break end
                end
                if not is_scoring then unscored = unscored + 1 end
            end
            if unscored > 0 then
                return { dollars = card.ability.extra.dollars * unscored }
            end
        end
    end,
}

SMODS.Joker {
    key = "bogdonoff",
    sprite = "bogdonoff.png",
    negative_sprite = "bogdonoff_negative.png",
    soul_sprite = "bogdonoff_soul.png",
    loc_txt = {
        name = "Bogdonoff",
        text = {
            "Go up to {C:red}-$#1#{}",
            "in debt",
            "Set money to {C:money}$0{}",
            "when leaving {C:attention}Shop",
        },
    },
    config = { debt_limit = 50, extra = { debt_limit = 50 } },
    rarity = 4,
    cost = 20,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.debt_limit } }
    end,
    calculate = function(self, card, context)
        jest0_refresh()
        if context.ending_shop then
            local money = (G and G.money) or 0
            if money ~= 0 then ease_dollars(-money) end
            return { message = "Reset!" }
        end
    end,
}

SMODS.Joker {
    key = "bon_vivant",
    sprite = "bon_vivant.png",
    negative_sprite = "bon_vivant_negative.png",
    loc_txt = {
        name = "Bon Vivant",
        text = {
            "Earn {C:money}$#1#{} after {C:attention}#3#{}{C:inactive}{} cards",
            "have been scored {C:attention}this round",
            "{C:inactive}(#2# Remaining){}",
        },
    },
    config = { extra = { dollars = 10, count = 0, target = 10 } },
    rarity = 1,
    cost = 5,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.dollars,
            math.max(card.ability.extra.target - card.ability.extra.count, 0),
            card.ability.extra.target } }
    end,
    calculate = function(self, card, context)
        jest0_refresh()
        if context.individual and context.cardarea == G.play and not context.blueprint then
            card.ability.extra.count = card.ability.extra.count + 1
            if card.ability.extra.count == card.ability.extra.target then
                return { dollars = card.ability.extra.dollars }
            end
        end
        if context.end_of_round and not context.blueprint then
            card.ability.extra.count = 0
            return { message = "Reset!" }
        end
    end,
}

SMODS.Joker {
    key = "bonus_bob",
    sprite = "bonus_bob.png",
    negative_sprite = "bonus_bob_negative.png",
    loc_txt = {
        name = "Bonus Bob",
        text = {
            "{C:attention}Bonus Cards{} give",
            "{X:chips,C:white}X#1#{} Chips when scored",
        },
    },
    config = { extra = { xchips = 1.5 } },
    rarity = 3,
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.xchips } }
    end,
    calculate = function(self, card, context)
        jest0_refresh()
        if context.individual and context.cardarea == G.play and context.other_card
            and context.other_card.enhancement == "bonus" then
            return { x_chips = card.ability.extra.xchips }
        end
    end,
}

SMODS.Joker {
    key = "bonus_pay",
    sprite = "bonus_pay.png",
    negative_sprite = "bonus_pay_negative.png",
    loc_txt = {
        name = "Bonus Pay",
        text = {
            "Earn {C:money}$#1#{} when a",
            "{C:attention}Bonus Card{} is scored",
        },
    },
    config = { extra = { money = 3 } },
    rarity = 1,
    cost = 5,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.money } }
    end,
    calculate = function(self, card, context)
        jest0_refresh()
        if context.individual and context.cardarea == G.play and context.other_card
            and context.other_card.enhancement == "bonus" then
            return { dollars = card.ability.extra.money }
        end
    end,
}

SMODS.Joker {
    key = "bonus_round",
    sprite = "bonus_round.png",
    negative_sprite = "bonus_round_negative.png",
    loc_txt = {
        name = "Bonus Round",
        text = {
            "{C:attention}Retrigger{} all",
            "scored {C:attention}Bonus Cards{}",
        },
    },
    config = { extra = { retriggers = 1 } },
    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    loc_vars = function(self, info_queue, card) end,
    calculate = function(self, card, context)
        jest0_refresh()
        if context.repetition and context.cardarea == G.play and context.other_card
            and context.other_card.enhancement == "bonus" then
            return {
                message = "Again!",
                repetitions = card.ability.extra.retriggers,
            }
        end
    end,
}

SMODS.Joker {
    key = "bozo",
    sprite = "bozo.png",
    negative_sprite = "bozo_negative.png",
    soul_sprite = "bozo_soul.png",
    loc_txt = {
        name = "Bozo",
        text = {
            "When {C:attention}Boss Blind{} is",
            "defeated, create {C:attention}two{}",
            "random {C:dark_edition}Negative{} Jokers",
        },
    },
    config = { extra = { jokers = 2 } },
    rarity = 4,
    cost = 20,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.jokers } }
    end,
    calculate = function(self, card, context)
        jest0_refresh()
        if context.end_of_round and G and G.current_blind_index == 3 then
            for _ = 1, card.ability.extra.jokers do
                SMODS.add_card { set = "Joker", edition = "negative" }
            end
            return { message = "+2 Jokers!" }
        end
    end,
}

SMODS.Joker {
    key = "bucolic_hills",
    sprite = "bucolic_hills.png",
    negative_sprite = "bucolic_hills_negative.png",
    loc_txt = {
        name = "Bucolic Hills",
        text = {
            "Earn {C:money}$#1#{} when playing",
            "{C:attention}final hand{} of round",
        },
    },
    config = { extra = { dollars = 8 } },
    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.dollars } }
    end,
    calculate = function(self, card, context)
        jest0_refresh()
        if context.before and G and (tonumber(G.hands) or -1) == 0 then
            return { dollars = card.ability.extra.dollars }
        end
    end,
}

SMODS.Joker {
    key = "bumper_sticker",
    sprite = "bumper_sticker.png",
    negative_sprite = "bumper_sticker_negative.png",
    loc_txt = {
        name = "Bumper Sticker",
        text = {
            "Played {C:attention}cards{}",
            "permanently gain",
            "{C:mult}+#1#{} Mult when scored",
        },
    },
    config = { extra = { mult_mod = 1 } },
    rarity = 2,
    cost = 5,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult_mod } }
    end,
    calculate = function(self, card, context)
        jest0_refresh()
        if context.individual and context.cardarea == G.play and context.other_card then
            SMODS.set_perma(context.other_card, "perma_mult",
                (SMODS.get_perma(context.other_card, "perma_mult") or 0)
                + card.ability.extra.mult_mod)
            return { message = localize("k_upgrade_ex") }
        end
    end,
}

SMODS.Joker {
    key = "buzzy_bee",
    sprite = "buzzy_bee.png",
    negative_sprite = "buzzy_bee_negative.png",
    loc_txt = {
        name = "Buzzy Bee",
        text = {
            "{C:attention}6s{} held in hand{} give",
            "{C:chips}+#1#{} Chips per {C:attention}6{} in",
            "{C:attention}full deck",
            "{C:inactive}(Currently {C:chips}+#2#{}{C:inactive} Chips)",
        },
    },
    config = { extra = { chips = 10 } },
    rarity = 2,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    loc_vars = function(self, info_queue, card)
        jest0_refresh()
        local count = 0
        if G and G.count_cards_in_full_deck then
            count = G:count_cards_in_full_deck(function(data)
                return tonumber(data.rank) == 6
            end)
        end
        return { vars = { card.ability.extra.chips, card.ability.extra.chips * count } }
    end,
    calculate = function(self, card, context)
        jest0_refresh()
        if context.individual and context.cardarea == G.hand
            and not context.end_of_round and context.other_card
            and context.other_card:get_id() == 6 then
            if context.other_card.debuff then
                return { message = "Debuffed!" }
            end
            local count = 0
            if G and G.count_cards_in_full_deck then
                count = G:count_cards_in_full_deck(function(data)
                    return tonumber(data.rank) == 6
                end)
            end
            return { chips = card.ability.extra.chips * count }
        end
    end,
}

SMODS.Joker {
    key = "cairoli",
    sprite = "cairoli.png",
    negative_sprite = "cairoli_negative.png",
    soul_sprite = "cairoli_soul.png",
    loc_txt = {
        name = "Cairoli",
        text = {
            "This Joker gains {X:mult,C:white}X#1#{} Mult",
            "when any {C:attention}Booster Pack{} or",
            "{C:attention}Blind{} is {C:attention}skipped",
            "{C:inactive}(Currently {X:mult,C:white}X#2#{} {C:inactive}Mult){}",
        },
    },
    config = { extra = { xmult = 1, gain = 0.5 } },
    rarity = 4,
    cost = 20,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.gain, card.ability.extra.xmult } }
    end,
    calculate = function(self, card, context)
        if (context.skip_blind or context.skipping_booster) and not context.blueprint then
            card.ability.extra.xmult = card.ability.extra.xmult + card.ability.extra.gain
            return { message = localize("k_upgrade_ex") }
        end
        if context.joker_main then
            return { x_mult = card.ability.extra.xmult }
        end
    end,
}

SMODS.Joker {
    key = "candidate",
    sprite = "candidate.png",
    negative_sprite = "candidate_negative.png",
    loc_txt = {
        name = "Candidate",
        text = {
            "{C:common}Common{} Jokers",
            "give {C:chips}+#2#{} Chips",
            "{C:uncommon}Uncommon{} and {C:rare}Rare{}",
            "Jokers give {C:mult}+#1#{} Mult",
        },
    },
    config = { extra = { mult = 13, chips = 50 } },
    rarity = 3,
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult, card.ability.extra.chips } }
    end,
    calculate = function(self, card, context)
        if context.post_trigger and context.other_card and context.other_card ~= card then
            local rarity = context.other_card.rarity
            if rarity == 1 then
                return { chips = card.ability.extra.chips }
            end
            if rarity == 2 or rarity == 3 then
                return { mult = card.ability.extra.mult }
            end
        end
    end,
}

SMODS.Joker {
    key = "candy_wrapper",
    sprite = "candy_wrapper.png",
    negative_sprite = "candy_wrapper_negative.png",
    loc_txt = {
        name = "Candy Wrapper",
        text = {
            "{C:mult}+#1#{} Mult per {C:money}$1{} of",
            "{C:money}sell value{} of all held",
            "{C:attention}consumables",
            "{C:inactive}(Currently {C:mult}+#2#{C:inactive} Mult)",
        },
    },
    config = { extra = { mult_per_dollar = 4 } },
    rarity = 1,
    cost = 4,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    loc_vars = function(self, info_queue, card)
        local total_val = 0
        local list = G.consumables or (G.consumeables and G.consumeables.cards) or {}
        for _, v in ipairs(list) do
            total_val = total_val + (v.sell_cost or 0)
        end
        return { vars = { card.ability.extra.mult_per_dollar,
            total_val * card.ability.extra.mult_per_dollar } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            local total_val = 0
            local list = G.consumables or (G.consumeables and G.consumeables.cards) or {}
            for _, v in ipairs(list) do
                total_val = total_val + (v.sell_cost or 0)
            end
            if total_val > 0 then
                return { mult = total_val * card.ability.extra.mult_per_dollar }
            end
        end
    end,
}

SMODS.Joker {
    key = "cavalier",
    sprite = "cavalier.png",
    negative_sprite = "cavalier_negative.png",
    loc_txt = {
        name = "Cavalier",
        text = {
            "{C:mult}+#2#{} Mult for each {C:attention}hand",
            "previously scored this {C:attention}round",
            "{C:inactive}(Currently {C:mult}+#1#{C:inactive} Mult)",
        },
    },
    config = { extra = { mult = 0, mult_mod = 5 } },
    rarity = 1,
    cost = 5,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult, card.ability.extra.mult_mod } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            return { mult = card.ability.extra.mult }
        end
        if context.after and not context.blueprint then
            card.ability.extra.mult = card.ability.extra.mult + card.ability.extra.mult_mod
        end
        if context.end_of_round and not context.blueprint then
            card.ability.extra.mult = 0
            return { message = "Reset!" }
        end
    end,
}

SMODS.Joker {
    key = "cebee_credits_joker",
    sprite = "cebee_credits_joker.png",
    negative_sprite = "cebee_credits_joker_negative.png",
    loc_txt = {
        name = "Cebee",
        text = {
            '{C:inactive}"Skibby Dee"',
        },
    },
    config = {},
    rarity = 1,
    cost = 4,
    blueprint_compat = false,
    eternal_compat = false,
    perishable_compat = true,
    in_pool = function(self, args)
        return false
    end,
}

SMODS.Joker {
    key = "cerium",
    sprite = "cerium.png",
    negative_sprite = "cerium_negative.png",
    loc_txt = {
        name = "Cerium",
        text = {
            "If played hand is {C:attention}Flush House{},",
            "retrigger all scoring cards{}",
            "{C:attention}#1#{} times",
        },
    },
    config = { extra = { retriggers = 2 } },
    rarity = 2,
    cost = 7,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.retriggers } }
    end,
    calculate = function(self, card, context)
        if context.repetition and context.cardarea == G.play
            and context.scoring_name == "Flush House" then
            return { repetitions = card.ability.extra.retriggers }
        end
    end,
}

SMODS.Joker {
    key = "cesar",
    sprite = "cesar.png",
    negative_sprite = "cesar_negative.png",
    loc_txt = {
        name = "Cesar",
        text = {
            "Earn {C:money}$#1#{} each hand",
            "played. Increases by {C:money}$#2#{}",
            "if {C:attention}played hand{} is only",
            "{C:diamonds}Diamond {C:attention}Kings",
        },
    },
    config = { extra = { money = 0, money_mod = 1 } },
    rarity = 3,
    cost = 9,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.money, card.ability.extra.money_mod } }
    end,
    calculate = function(self, card, context)
        if context.before then
            local diamond_kings, all_cards = 0, 0
            for _, v in ipairs(context.full_hand or {}) do
                all_cards = all_cards + 1
                if v:get_id() == 13 and v:is_suit("Diamonds") then
                    diamond_kings = diamond_kings + 1
                end
            end
            if all_cards > 0 and diamond_kings == all_cards and not context.blueprint then
                card.ability.extra.money = card.ability.extra.money
                    + card.ability.extra.money_mod
                return { message = localize("k_upgrade_ex") }
            end
        end
        if context.after and card.ability.extra.money > 0 then
            return { dollars = card.ability.extra.money }
        end
    end,
}

SMODS.Joker {
    key = "charles",
    sprite = "charles.png",
    negative_sprite = "charles_negative.png",
    loc_txt = {
        name = "Charles",
        text = {
            "This Joker gains {X:mult,C:white}X#1#{}",
            "Mult if {C:attention}played hand{}",
            "is only {C:hearts}Heart{} {C:attention}Kings{}",
            "{C:inactive}(Currently{} {X:mult,C:white}X#2#{C:inactive} Mult){}",
        },
    },
    config = { extra = { xmult = 1, xmult_mod = 0.25 } },
    rarity = 3,
    cost = 8,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.xmult_mod, card.ability.extra.xmult } }
    end,
    calculate = function(self, card, context)
        if context.before then
            local heart_kings, all_cards = 0, 0
            for _, v in ipairs(context.full_hand or {}) do
                all_cards = all_cards + 1
                if v:get_id() == 13 and v:is_suit("Hearts") then
                    heart_kings = heart_kings + 1
                end
            end
            if all_cards > 0 and heart_kings == all_cards and not context.blueprint then
                card.ability.extra.xmult = card.ability.extra.xmult
                    + card.ability.extra.xmult_mod
                return { message = localize("k_upgrade_ex") }
            end
        end
        if context.joker_main then
            return { xmult = card.ability.extra.xmult }
        end
    end,
}

SMODS.Joker {
    key = "cheerio",
    sprite = "cheerio.png",
    negative_sprite = "cheerio_negative.png",
    loc_txt = {
        name = "Cheerio",
        text = {
            "{C:chips}+#1#{} Chips, loses {C:chips}Chips{} equal",
            "to {C:money}money{} spent {C:green}rerolling{}",
        },
    },
    config = { extra = { chips = 100 } },
    rarity = 1,
    cost = 4,
    blueprint_compat = true,
    eternal_compat = false,
    perishable_compat = true,
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chips } }
    end,
    calculate = function(self, card, context)
        if context.reroll_shop and not context.blueprint then
            local cost = context.cost or (context.port and context.port.cost) or 0
            card.ability.extra.chips = card.ability.extra.chips - cost
            if card.ability.extra.chips <= 0 then
                SMODS.destroy_joker(card)
                return { message = "Eaten!" }
            end
            return { message = "-" .. cost .. " Chips" }
        end
        if context.joker_main then
            return { chips = card.ability.extra.chips }
        end
    end,
}

SMODS.Joker {
    key = "cheese_squigglies",
    sprite = "cheese_squigglies.png",
    negative_sprite = "cheese_squigglies_negative.png",
    loc_txt = {
        name = "Cheese Squigglies",
        text = {
            "This Joker gains {X:mult,C:white}X#2#{} Mult",
            "per {C:green}reroll{} in the Shop,",
            "{C:attention}eaten{} after {C:attention}#4#{} rerolls",
            "{C:inactive}(Currently {X:mult,C:white}X#1#{} {C:inactive}Mult, {C:attention}#3#{C:inactive}/{C:attention}#4#{C:inactive}){}",
        },
    },
    config = { extra = { xmult = 1, gain = 0.25, rolls = 0, limit = 10 } },
    rarity = 2,
    cost = 7,
    blueprint_compat = true,
    eternal_compat = false,
    perishable_compat = true,
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.xmult, card.ability.extra.gain,
            card.ability.extra.rolls, card.ability.extra.limit } }
    end,
    calculate = function(self, card, context)
        if context.reroll_shop and not context.blueprint then
            card.ability.extra.xmult = card.ability.extra.xmult + card.ability.extra.gain
            card.ability.extra.rolls = card.ability.extra.rolls + 1
            if card.ability.extra.rolls >= card.ability.extra.limit then
                SMODS.destroy_joker(card)
                return { message = "Eaten!" }
            end
            return { message = localize("k_upgrade_ex") }
        end
        if context.joker_main then
            return { xmult = card.ability.extra.xmult }
        end
    end,
}

SMODS.Joker {
    key = "chippy",
    sprite = "chippy.png",
    negative_sprite = "chippy_negative.png",
    loc_txt = {
        name = "Chippy",
        text = {
            "This Joker gains {C:chips}Chips{}",
            "equal to {C:money}money{} spent",
            "{C:inactive}(Currently {C:chips}+#1#{C:inactive} Chips)",
        },
    },
    config = { extra = { chips = 0 } },
    rarity = 2,
    cost = 6,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chips } }
    end,
    calculate = function(self, card, context)
        if context.money_altered and context.amount < 0 and not context.blueprint then
            card.ability.extra.chips = card.ability.extra.chips - context.amount
            return { message = localize("k_upgrade_ex") }
        end
        if context.joker_main and card.ability.extra.chips > 0 then
            return { chips = card.ability.extra.chips }
        end
    end,
}

SMODS.Joker {
    key = "chips_n_dip",
    sprite = "chips_n_dip.png",
    negative_sprite = "chips_n_dip_negative.png",
    loc_txt = {
        name = "Chips 'n Dip",
        text = {
            "{X:chips,C:white}X#1#{} Chips, loses {X:chips,C:white}X#2#{} Chips",
            "at end of {C:attention}round",
        },
    },
    config = { extra = { xchips = 3, xchips_mod = 0.25 } },
    rarity = 2,
    cost = 6,
    blueprint_compat = true,
    eternal_compat = false,
    perishable_compat = true,
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.xchips, card.ability.extra.xchips_mod } }
    end,
    calculate = function(self, card, context)
        if context.end_of_round and not context.blueprint then
            if (card.ability.extra.xchips - card.ability.extra.xchips_mod) <= 1 then
                SMODS.destroy_joker(card)
                return { message = "Eaten!" }
            end
            card.ability.extra.xchips = card.ability.extra.xchips
                - card.ability.extra.xchips_mod
            return { message = "XChips -" .. card.ability.extra.xchips_mod }
        end
        if context.joker_main then
            return { x_chips = card.ability.extra.xchips }
        end
    end,
}

SMODS.Joker {
    key = "choleric_joker",
    sprite = "choleric_joker.png",
    negative_sprite = "choleric_joker_negative.png",
    loc_txt = {
        name = "Choleric Joker",
        text = {
            "Played cards with {C:diamonds}Diamond",
            "suit have a {C:green}#1# in #2#{} chance",
            "to create a random {C:tarot}Tarot{}",
            "card when scored",
            "{C:inactive}(Must have room){}",
        },
    },
    config = { extra = { odds = 3 } },
    rarity = 3,
    cost = 8,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    loc_vars = function(self, info_queue, card)
        local numerator, denominator = SMODS.get_probability_vars(card, 1,
            card.ability.extra.odds)
        return { vars = { numerator, denominator } }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play
            and context.other_card and context.other_card:is_suit("Diamonds") then
            local hit = SMODS.pseudorandom_probability(card, "choleric_joker", 1,
                card.ability.extra.odds)
            if hit and G.random_consumable_id_of_kind then
                local id = G:random_consumable_id_of_kind("tarot")
                if id and SMODS.add_card { set = "Tarot", key = id } then
                    return { message = "+ Tarot!" }
                end
            end
        end
    end,
}

SMODS.Joker {
    key = "christmas_eve",
    sprite = "christmas_eve.png",
    negative_sprite = "christmas_eve_negative.png",
    loc_txt = {
        name = "Christmas Eve",
        text = {
            "Create a {C:attention}Coupon Tag{} when",
            "{C:attention}Big Blind{} is defeated",
        },
    },
    config = { extra = {} },
    rarity = 2,
    cost = 7,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.end_of_round and G.current_blind_index == 2 then
            if G.addTag then G:addTag("coupon") end
            return { message = "+ Coupon Tag" }
        end
    end,
}

SMODS.Joker {
    key = "chromatic_aberrant",
    sprite = "chromatic_aberrant.png",
    negative_sprite = "chromatic_aberrant_negative.png",
    loc_txt = {
        name = "Chromatic Aberrant",
        text = {
            "{C:green}+#5#{} to listed {C:green}probabilities{}",
            "{C:attention}this hand{} if hand contains a",
            "{C:attention}Straight{} or a {C:attention}Flush",
            "{C:green}+#3#{} to listed {C:green}probabilities ",
            "{C:attention}permanently{} if played hand",
            "contains a {C:attention}Straight Flush",
            "{C:inactive}(Currently {C:green}+#1#{} {C:inactive}Odds)",
            "{C:inactive}(Max of {C:green}+#2#{} {C:inactive}Odds)",
        },
    },
    config = { extra = { perm_odds = 0, perm_odds_max = 5, perm_odds_mod = 1,
        temp_odds = 0, temp_odds_mod = 1 } },
    rarity = 2,
    cost = 7,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = false,
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.perm_odds, card.ability.extra.perm_odds_max,
            card.ability.extra.perm_odds_mod, card.ability.extra.temp_odds,
            card.ability.extra.temp_odds_mod } }
    end,
    calculate = function(self, card, context)
        if context.before and not context.blueprint then
            card.ability.extra.temp_odds = 0
            if next(context.poker_hands["Straight Flush"]) then
                if card.ability.extra.perm_odds < card.ability.extra.perm_odds_max then
                    card.ability.extra.perm_odds = card.ability.extra.perm_odds
                        + card.ability.extra.perm_odds_mod
                    return { message = localize("k_upgrade_ex") }
                end
            elseif next(context.poker_hands["Straight"])
                or next(context.poker_hands["Flush"]) then
                card.ability.extra.temp_odds = card.ability.extra.temp_odds
                    + card.ability.extra.temp_odds_mod
                return { message = "+" .. card.ability.extra.temp_odds_mod .. " Odds" }
            end
        end
        if context.mod_probability and not context.blueprint then
            local total_boost = card.ability.extra.perm_odds
                + (card.ability.extra.temp_odds or 0)
            if total_boost > 0 then
                return { numerator = (context.numerator or 0) + total_boost }
            end
        end
        if context.after and not context.blueprint then
            card.ability.extra.temp_odds = 0
        end
    end,
}

SMODS.Joker {
    key = "circle_joker",
    sprite = "circle_joker.png",
    negative_sprite = "circle_joker_negative.png",
    loc_txt = {
        name = "Circle Joker",
        text = {
            "{X:mult,C:white}X#1#{} Mult if each {C:attention}rank{}",
            "in scored hand is {C:attention}lower{}",
            "than the {C:attention}previous",
        },
    },
    config = { extra = { xmult = 3.14 } },
    rarity = 3,
    cost = 8,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.xmult } }
    end,
    calculate = function(self, card, context)
        if context.joker_main and context.scoring_hand
            and #context.scoring_hand >= 2 then
            local strictly_decreasing = true
            for i = 1, #context.scoring_hand - 1 do
                if context.scoring_hand[i]:get_id()
                    <= context.scoring_hand[i + 1]:get_id() then
                    strictly_decreasing = false
                    break
                end
            end
            if strictly_decreasing then
                return { xmult = card.ability.extra.xmult }
            end
        end
    end,
}

SMODS.Joker {
    key = "clapperdudgeon",
    sprite = "clapperdudgeon.png",
    negative_sprite = "clapperdudgeon_negative.png",
    loc_txt = {
        name = "Clapperdudgeon",
        text = {
            "{X:mult,C:white}X#1#{} Mult if you have",
            "{C:money}$#2#{} or less",
        },
    },
    config = { extra = { xmult = 3, max_dollars = 4 } },
    rarity = 2,
    cost = 6,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.xmult, card.ability.extra.max_dollars } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            if (G.money or 0) <= card.ability.extra.max_dollars then
                return { xmult = card.ability.extra.xmult }
            end
        end
    end,
}

SMODS.Joker {
    key = "cloth_joker",
    sprite = "cloth_joker.png",
    negative_sprite = "cloth_joker_negative.png",
    loc_txt = {
        name = "Cloth Joker",
        text = {
            "{C:attention}Queens{} give {X:mult,C:white}X#2#{} Mult",
            "and {C:red}-$#1#{} when scored",
        },
    },
    config = { extra = { xmult = 2, dollars = 4 } },
    rarity = 3,
    cost = 8,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.dollars, card.ability.extra.xmult } }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play
            and context.other_card and context.other_card:get_id() == 12 then
            return {
                dollars = -card.ability.extra.dollars,
                xmult = card.ability.extra.xmult,
            }
        end
    end,
}

SMODS.Joker {
    key = "clowns_on_parade",
    sprite = "clowns_on_parade.png",
    negative_sprite = "clowns_on_parade_negative.png",
    loc_txt = {
        name = "Clowns on Parade",
        text = {
            "This {C:attention}Joker{} gains {C:chips}+#2#{} Chips",
            "if played hand contains",
            "at least three {C:attention}2s{}",
            "{C:inactive}(Currently{} {C:chips}+#1#{} {C:inactive}Chips){}",
        },
    },
    config = { extra = { chips = 0, chip_mod = 20 } },
    rarity = 2,
    cost = 6,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chips, card.ability.extra.chip_mod } }
    end,
    calculate = function(self, card, context)
        if context.before and not context.blueprint then
            local twos = 0
            for _, v in ipairs(context.full_hand or {}) do
                if v:get_id() == 2 then twos = twos + 1 end
            end
            if twos >= 3 then
                card.ability.extra.chips = card.ability.extra.chips
                    + card.ability.extra.chip_mod
                return { message = localize("k_upgrade_ex") }
            end
        end
        if context.joker_main then
            return { chips = card.ability.extra.chips }
        end
    end,
}

SMODS.Joker {
    key = "coconut",
    sprite = "coconut.png",
    negative_sprite = "coconut_negative.png",
    loc_txt = {
        name = "Coconut",
        text = {
            "Create a {C:attention}Juggle Tag{}",
            "when this Joker is {C:money}sold{}",
        },
    },
    config = { extra = {} },
    rarity = 1,
    cost = 4,
    blueprint_compat = true,
    eternal_compat = false,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.selling_self then
            if G.addTag then G:addTag("juggle") end
            return { message = "+ Juggle Tag" }
        end
    end,
}

SMODS.Joker {
    key = "colquhoun",
    sprite = "colquhoun.png",
    negative_sprite = "colquhoun_negative.png",
    soul_sprite = "colquhoun_soul.png",
    loc_txt = {
        name = "Colquhoun",
        text = {
            "All cards earn {C:money}$#1#{}",
            "when {C:attention}scored{}, increases",
            "by {C:money}$#2#{} when {C:attention}Boss Blind{}",
            "is defeated",
        },
    },
    config = { extra = { dollars = 1, dollar_mod = 1 } },
    rarity = 4,
    cost = 20,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.dollars, card.ability.extra.dollar_mod } }
    end,
    calculate = function(self, card, context)
        if context.end_of_round and not context.blueprint
            and G.current_blind_index == 3 then
            card.ability.extra.dollars = card.ability.extra.dollars
                + card.ability.extra.dollar_mod
            return { message = localize("k_upgrade_ex") }
        end
        if context.individual and context.cardarea == G.play then
            return { dollars = card.ability.extra.dollars }
        end
    end,
}

SMODS.Joker {
    key = "comedy_of_errors",
    sprite = "comedy_of_errors.png",
    negative_sprite = "comedy_of_errors_negative.png",
    loc_txt = {
        name = "Comedy of Errors",
        text = {
            "Earn {C:money}$#1#{} whenever a",
            "{C:hearts}Heart{} is {C:red}discarded",
        },
    },
    config = { extra = { dollars = 1 } },
    rarity = 1,
    cost = 5,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.dollars } }
    end,
    calculate = function(self, card, context)
        if context.discard and context.other_card
            and context.other_card:is_suit("Hearts") then
            return { dollars = card.ability.extra.dollars }
        end
    end,
}

SMODS.Joker {
    key = "comic_panel",
    sprite = "comic_panel.png",
    negative_sprite = "comic_panel_negative.png",
    loc_txt = {
        name = "Comic Panel",
        text = {
            "{C:green}#1# in #2#{} chance to apply a",
            "random {C:attention}enhancement{} to",
            "{C:attention}all{} cards in played hand",
        },
    },
    config = { extra = { odds = 10 } },
    rarity = 1,
    cost = 5,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    loc_vars = function(self, info_queue, card)
        local numerator, denominator = SMODS.get_probability_vars(card, 1,
            card.ability.extra.odds, "comic_panel")
        return { vars = { numerator, denominator } }
    end,
    calculate = function(self, card, context)
        if context.before then
            local hit = SMODS.pseudorandom_probability(card, "comic_panel", 1,
                card.ability.extra.odds)
            if hit then
                for _, v in ipairs(context.full_hand or {}) do
                    local enh = SMODS.poll_enhancement({ guaranteed = true })
                    if enh and v.set_enhancement then v:set_enhancement(enh) end
                end
                return { message = "Changed!" }
            end
        end
    end,
}

SMODS.Joker {
    key = "copper",
    sprite = "copper.png",
    negative_sprite = "copper_negative.png",
    loc_txt = {
        name = "Copper",
        text = {
            "If played hand is {C:attention}Three of a Kind{},",
            "retrigger all scoring cards{}",
        },
    },
    config = { extra = {} },
    rarity = 1,
    cost = 6,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.repetition and context.cardarea == G.play
            and context.scoring_name == "Three of a Kind" then
            return { repetitions = 1 }
        end
    end,
}

SMODS.Joker {
    key = "coulrorachne",
    sprite = "coulrorachne.png",
    negative_sprite = "coulrorachne_negative.png",
    loc_txt = {
        name = "Coulrorachne",
        text = {
            "This Joker gains {C:mult}+#1#{} Mult",
            "every {C:attention}#4# {C:inactive}[#3#]{} scored {C:attention}8s",
            "{C:inactive}(Currently {C:mult}+#2#{C:inactive} Mult)",
        },
    },
    config = { extra = { mult_mod = 8, cur_mult = 0, eight_count = 0, amt_mod = 8 } },
    rarity = 1,
    cost = 4,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult_mod, card.ability.extra.cur_mult,
            card.ability.extra.amt_mod - card.ability.extra.eight_count,
            card.ability.extra.amt_mod } }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play and not context.blueprint
            and context.other_card and context.other_card:get_id() == 8 then
            card.ability.extra.eight_count = card.ability.extra.eight_count + 1
            if card.ability.extra.eight_count >= card.ability.extra.amt_mod then
                card.ability.extra.eight_count = 0
                card.ability.extra.cur_mult = card.ability.extra.cur_mult
                    + card.ability.extra.mult_mod
                return { message = localize("k_upgrade_ex") }
            end
        end
        if context.joker_main and card.ability.extra.cur_mult > 0 then
            return { mult = card.ability.extra.cur_mult }
        end
    end,
}

SMODS.Joker {
    key = "crab_in_a_bucket",
    sprite = "crab_in_a_bucket.png",
    negative_sprite = "crab_in_a_bucket_negative.png",
    loc_txt = {
        name = "Crab in a Bucket",
        text = {
            "{C:chips}+#1#{} Chips per card above",
            "{C:attention}#2#{} in your {C:attention}full deck",
            "{C:inactive}(Currently {C:chips}+#3#{} {C:inactive}Chips){}",
        },
    },
    config = { extra = { chips = 8 } },
    rarity = 1,
    cost = 4,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    loc_vars = function(self, info_queue, card)
        local total = 52
        if G.count_cards_in_full_deck then
            total = G:count_cards_in_full_deck(function() return true end) or 52
        end
        local diff = math.max(0, total - 52)
        return { vars = { card.ability.extra.chips, 52,
            diff * card.ability.extra.chips } }
    end,
    calculate = function(self, card, context)
        if context.joker_main and G.count_cards_in_full_deck then
            local total = G:count_cards_in_full_deck(function() return true end) or 52
            local diff = math.max(0, total - 52)
            if diff > 0 then
                return { chips = diff * card.ability.extra.chips }
            end
        end
    end,
}

SMODS.Joker {
    key = "crop_circle",
    sprite = "crop_circle.png",
    negative_sprite = "crop_circle_negative.png",
    loc_txt = {
        name = "Crop Circle",
        text = {
            "Add a {C:attention}random enhancement",
            "to {C:attention}#1# random{} card held in hand",
            "when a {C:planet}Planet{} card is used",
        },
    },
    config = { extra = { cards = 1 } },
    rarity = 2,
    cost = 6,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.cards } }
    end,
    calculate = function(self, card, context)
        if context.using_consumeable and context.port
            and context.port.consumable_kind == "planet" then
            local nodes = (G.hand and G.hand.card_nodes) or {}
            if #nodes > 0 then
                for i = 1, card.ability.extra.cards do
                    local enh = SMODS.poll_enhancement({ guaranteed = true,
                        type_key = "crop_circle" .. i })
                    local ran_card = pseudorandom_element(nodes,
                        "crop_circle" .. i)
                    if ran_card and enh and ran_card.set_enhancement then
                        ran_card:set_enhancement(enh)
                    end
                end
                return { message = "Changed!" }
            end
        end
    end,
}

SMODS.Joker {
    key = "croupier",
    sprite = "croupier.png",
    negative_sprite = "croupier_negative.png",
    loc_txt = {
        name = "Croupier",
        text = {
            "Earn {C:money}$#1#{} if final score",
            "is over {C:attention}twice{} the blind",
            "requirement",
        },
    },
    config = { extra = { mod_money = 10 } },
    rarity = 1,
    cost = 4,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mod_money } }
    end,
    calc_dollar_bonus = function(self, card)
        local score = tonumber(G.round_score) or 0
        local target = tonumber(G.current_blind_target) or 0
        if score > target * 2 then
            return card.ability.extra.mod_money
        end
    end,
}

SMODS.Joker {
    key = "cut_here",
    sprite = "cut_here.png",
    negative_sprite = "cut_here_negative.png",
    loc_txt = {
        name = "Cut Here",
        text = {
            "When this Joker is",
            "{C:red}destroyed{}, create a",
            "random {C:red}Rare{} Joker",
        },
    },
    config = {},
    rarity = 2,
    cost = 6,
    blueprint_compat = true,
    eternal_compat = false,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.joker_type_destroyed and context.card == card then
            if G.random_joker_def_id_by_rarity then
                local id = G:random_joker_def_id_by_rarity(3, "cut_here")
                if id and SMODS.add_card { set = "Joker", key = id } then
                    return { message = "+ Joker!" }
                end
            end
        end
    end,
}

SMODS.Joker {
    key = "cyclops",
    sprite = "cyclops.png",
    negative_sprite = "cyclops_negative.png",
    loc_txt = {
        name = "Cyclops",
        text = {
            "This Joker gains {C:mult}+#1#{} Mult if",
            "{C:attention}first hand{} of round is",
            "exactly {C:attention}one{} card",
            "{C:inactive}(Currently {C:mult}+#2#{C:inactive} Mult){}",
        },
    },
    config = { extra = { mult = 0, mult_mod = 3 } },
    rarity = 1,
    cost = 4,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult_mod, card.ability.extra.mult } }
    end,
    calculate = function(self, card, context)
        if context.before and context.full_hand and #context.full_hand == 1
            and G.get_round_hands_played and G:get_round_hands_played() == 0 then
            card.ability.extra.mult = card.ability.extra.mult
                + card.ability.extra.mult_mod
            return { message = localize("k_upgrade_ex") }
        end
        if context.joker_main then
            return { mult = card.ability.extra.mult }
        end
    end,
}

SMODS.Joker {
    key = "dandiprat",
    sprite = "dandiprat.png",
    negative_sprite = "dandiprat_negative.png",
    loc_txt = {
        name = "Dandiprat",
        text = {
            "Scoring {C:attention}2s{}, {C:attention}3s{}, {C:attention}4s{}, and {C:attention}5s{}",
            "earn {C:money}$#1#{} when scored",
        },
    },
    config = { extra = { dollars = 1 } },
    rarity = 1,
    cost = 5,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.dollars } }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play
            and context.other_card then
            local id = context.other_card:get_id()
            if id >= 2 and id <= 5 then
                return { dollars = card.ability.extra.dollars }
            end
        end
    end,
}

SMODS.Joker {
    key = "david",
    sprite = "david.png",
    negative_sprite = "david_negative.png",
    loc_txt = {
        name = "David",
        text = {
            "This Joker gains {C:chips}+#1#{}",
            "Chips if {C:attention}played hand{}",
            "is only {C:spades}Spade{} {C:attention}Kings{}",
            "{C:inactive}(Currently{} {C:chips}+#2#{C:inactive} Chips){}",
        },
    },
    config = { extra = { chips = 0, chip_mod = 50 } },
    rarity = 3,
    cost = 8,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chip_mod, card.ability.extra.chips } }
    end,
    calculate = function(self, card, context)
        if context.before then
            local spade_kings, all_cards = 0, 0
            for _, v in ipairs(context.full_hand or {}) do
                all_cards = all_cards + 1
                if v:get_id() == 13 and v:is_suit("Spades") then
                    spade_kings = spade_kings + 1
                end
            end
            if all_cards > 0 and spade_kings == all_cards and not context.blueprint then
                card.ability.extra.chips = card.ability.extra.chips
                    + card.ability.extra.chip_mod
                return { message = localize("k_upgrade_ex") }
            end
        end
        if context.joker_main then
            return { chips = card.ability.extra.chips }
        end
    end,
}

SMODS.Joker {
    key = "default_credits_joker",
    sprite = "default_credits_joker.png",
    negative_sprite = "default_credits_joker_negative.png",
    loc_txt = {
        name = "Default",
        text = {
            '{C:inactive}"Skibby Dee"',
        },
    },
    config = {},
    rarity = 1,
    cost = 4,
    blueprint_compat = false,
    eternal_compat = false,
    perishable_compat = true,
    in_pool = function(self, args)
        return false
    end,
}

SMODS.Joker {
    key = "desiderium",
    sprite = "desiderium.png",
    negative_sprite = "desiderium_negative.png",
    loc_txt = {
        name = "Desiderium",
        text = {
            "This {C:attention}Joker{} gains {X:mult,C:white}X#1#{}",
            "Mult when leaving a Shop",
            "{C:attention}without{} spending {C:money}money",
            "{C:inactive}(Currently {X:mult,C:white}X#2#{} {C:inactive}Mult){}",
        },
    },
    config = { extra = { xmult_mod = 0.5, xmult = 1, trigger = false } },
    rarity = 2,
    cost = 6,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.xmult_mod, card.ability.extra.xmult } }
    end,
    calculate = function(self, card, context)
        if context.starting_shop and not context.blueprint then
            card.ability.extra.trigger = true
        end
        if context.money_altered and context.amount < 0 and not context.blueprint then
            card.ability.extra.trigger = false
        end
        if context.ending_shop and not context.blueprint
            and card.ability.extra.trigger then
            card.ability.extra.xmult = card.ability.extra.xmult
                + card.ability.extra.xmult_mod
            return { message = localize("k_upgrade_ex") }
        end
        if context.joker_main then
            return { xmult = card.ability.extra.xmult }
        end
    end,
}

SMODS.Joker {
    key = "devil_deal",
    sprite = "devil_deal.png",
    negative_sprite = "devil_deal_negative.png",
    loc_txt = {
        name = "Devil Deal",
        text = {
            "This Joker gains {X:mult,C:white}X#1#{}",
            "Mult when a {C:hearts}Heart{}",
            "is {C:attention}destroyed",
            "{C:inactive}(Currently {X:mult,C:white}X#2#{} {C:inactive}Mult)",
        },
    },
    config = { extra = { xmult = 1, xmult_mod = 0.25 } },
    rarity = 2,
    cost = 6,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.xmult_mod, card.ability.extra.xmult } }
    end,
    calculate = function(self, card, context)
        if context.remove_playing_cards and not context.blueprint
            and context.port and context.port.destroyed_cards then
            local hearts = 0
            for _, val in ipairs(context.port.destroyed_cards) do
                if val.is_suit and val:is_suit("Hearts") then
                    hearts = hearts + 1
                end
            end
            if hearts > 0 then
                card.ability.extra.xmult = card.ability.extra.xmult
                    + card.ability.extra.xmult_mod * hearts
                return { message = localize("k_upgrade_ex") }
            end
        end
        if context.joker_main then
            return { xmult = card.ability.extra.xmult }
        end
    end,
}

SMODS.Joker {
    key = "diamantaire",
    sprite = "diamantaire.png",
    negative_sprite = "diamantaire_negative.png",
    loc_txt = {
        name = "Diamantaire",
        text = {
            "If hand is a single {C:diamonds}Diamond{},",
            "make it a {C:attention}Gold Card{}",
            "and earn {C:money}$#1#",
        },
    },
    config = { extra = { dollars = 3 } },
    rarity = 2,
    cost = 8,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.dollars } }
    end,
    calculate = function(self, card, context)
        if context.before and not context.blueprint and context.full_hand
            and #context.full_hand == 1
            and context.full_hand[1]:is_suit("Diamonds") then
            local target = context.full_hand[1]
            if target.set_enhancement then target:set_enhancement("gold") end
            return { dollars = card.ability.extra.dollars }
        end
    end,
}

SMODS.Joker {
    key = "dicky",
    sprite = "dicky.png",
    negative_sprite = "dicky_negative.png",
    soul_sprite = "dicky_soul.png",
    loc_txt = {
        name = "Dicky",
        text = {
            "At end of round, all cards",
            "that were {C:attention}not{} drawn that",
            "round {C:attention}permanently{} gain",
            "{X:mult,C:white}X#1#{} Mult",
        },
    },
    config = { extra = { perma_mult = 0.1 } },
    rarity = 4,
    cost = 20,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.perma_mult } }
    end,
    calculate = function(self, card, context)
        if context.end_of_round then
            for _, data in ipairs((G.deck and G.deck.cards) or {}) do
                local cur = SMODS.get_perma(data, "perma_x_mult")
                if type(cur) ~= "number" then cur = 0 end
                SMODS.set_perma(data, "perma_x_mult",
                    cur + card.ability.extra.perma_mult)
            end
            return { message = localize("k_upgrade_ex") }
        end
    end,
}

SMODS.Joker {
    key = "dim_bulb",
    sprite = "dim_bulb.png",
    negative_sprite = "dim_bulb_negative.png",
    loc_txt = {
        name = "Dim Bulb",
        text = {
            "{X:mult,C:white}X#1#{} Mult if you have",
            "no {C:uncommon}Uncommon{} or",
            "{C:red}Rare{} {C:attention}Jokers{}",
        },
    },
    config = { extra = { xmult = 2 } },
    rarity = 1,
    cost = 4,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.xmult } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            local only_common = true
            for _, j in ipairs(G.jokers or {}) do
                if j ~= card and (j.rarity == 2 or j.rarity == 3) then
                    only_common = false
                    break
                end
            end
            if only_common then
                return { xmult = card.ability.extra.xmult }
            end
        end
    end,
}

SMODS.Joker {
    key = "dire_warning",
    sprite = "dire_warning.png",
    negative_sprite = "dire_warning_negative.png",
    loc_txt = {
        name = "Dire Warning",
        text = {
            "{X:mult,C:white}X#1#{} Mult if {C:attention}previous round",
            "was won with {C:attention}0{} hands",
            "remaining",
            "{C:inactive}(#2#)",
        },
    },
    config = { extra = { xmult = 3, active = false } },
    rarity = 2,
    cost = 6,
    blueprint_compat = true,
    eternal_compat = false,
    perishable_compat = true,
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.xmult,
            card.ability.extra.active and "Active!" or "Inactive" } }
    end,
    calculate = function(self, card, context)
        if context.joker_main and card.ability.extra.active then
            return { xmult = card.ability.extra.xmult }
        end
        if context.end_of_round and not context.blueprint then
            if (tonumber(G.hands) or 0) == 0 then
                card.ability.extra.active = true
                return { message = "Active!" }
            end
            card.ability.extra.active = false
            return { message = "Reset!" }
        end
    end,
}

SMODS.Joker {
    key = "disco_joker",
    sprite = "disco_joker.png",
    negative_sprite = "disco_joker_negative.png",
    loc_txt = {
        name = "Disco Joker",
        text = {
            "{C:attention}Retrigger{} all cards",
            "with {C:attention}Editions",
        },
    },
    config = { extra = {} },
    rarity = 2,
    cost = 6,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.repetition and context.other_card
            and context.other_card.edition then
            return { repetitions = 1 }
        end
    end,
}

SMODS.Joker {
    key = "doctors_orders",
    sprite = "doctors_orders.png",
    negative_sprite = "doctors_orders_negative.png",
    loc_txt = {
        name = "Doctor's Orders",
        text = {
            "{X:mult,C:white}X#1#{} Mult per {C:attention}9{} in the played",
            "hand, {C:red}self-destructs{} if no",
            "{C:attention}9s{} were played",
        },
    },
    config = { extra = { xmult = 1, nine_tally = 0 } },
    rarity = 2,
    cost = 6,
    blueprint_compat = true,
    eternal_compat = false,
    perishable_compat = true,
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.xmult } }
    end,
    calculate = function(self, card, context)
        if context.before and not context.blueprint then
            for _, playing_card in ipairs(context.full_hand or {}) do
                if playing_card:get_id() == 9 then
                    card.ability.extra.nine_tally = card.ability.extra.nine_tally
                        + card.ability.extra.xmult
                end
            end
        end
        if context.joker_main and card.ability.extra.nine_tally > 0 then
            return { xmult = card.ability.extra.nine_tally }
        end
        if context.after and not context.blueprint then
            if card.ability.extra.nine_tally == 0 then
                SMODS.destroy_joker(card)
                return { message = "Eaten!" }
            end
            card.ability.extra.nine_tally = 0
        end
    end,
}

-- JestPack Wave 4, chunk 02 (worker 2): PORTABLE Jokers only.
-- Ported from All in Jest (Items/Jokers/) to the Balatro3DS fork API.
-- REWRITE / BLOCKED items from this chunk are listed in census_jokers_2.md
-- and are NOT included here.

-- dog_treat: PC checks current_round.hands_played == 1 at end_of_round;
-- the fork's getter reads the same total there. Self-destruct through
-- SMODS.destroy_joker (PC's batch destroy_cards on the single card).
SMODS.Joker {
    key = "dog_treat",
    loc_txt = {
        name = "Dog Treat",
        text = {
            "If Blind is won in {C:attention}one{}",
            "hand, earn {C:money}$#1#{} and",
            "{C:red}self destruct",
        },
    },
    config = { extra = { dollars = 20 } },
    rarity = 1, cost = 5, unlocked = true, discovered = false,
    blueprint_compat = true, eternal_compat = false, perishable_compat = true,
    sprite = "dog_treat.png", negative_sprite = "dog_treat_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.dollars } }
    end,
    calculate = function(self, card, context)
        if context.end_of_round and not context.game_over then
            if G and G.get_round_hands_played and G:get_round_hands_played() == 1 then
                if not context.blueprint then SMODS.destroy_joker(card) end
                return { dollars = card.ability.extra.dollars, message = "Eaten!" }
            end
        end
    end,
}

-- dont_be_a_joker: SMODS.scale_card inlined; PC grows ability.extra_value
-- and re-prices with set_cost -- the fork's sell path reads the Joker's
-- sell_cost field directly (Cryptid Virgo precedent), so it grows that.
SMODS.Joker {
    key = "dont_be_a_joker",
    loc_txt = {
        name = "Don't be a Joker!",
        text = {
            "When a {C:attention}Joker{} is {C:red}destroyed",
            "or {C:money}sold{}, this gains its {C:money}sell",
            "{C:money}value",
        },
    },
    config = { extra = {} },
    rarity = 3, cost = 8, unlocked = true, discovered = false,
    blueprint_compat = false, eternal_compat = true, perishable_compat = true,
    sprite = "dont_be_a_joker.png", negative_sprite = "dont_be_a_joker_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = {} }
    end,
    calculate = function(self, card, context)
        if (context.selling_card or context.joker_type_destroyed) and context.card then
            local gain = tonumber(context.card.sell_cost) or 0
            if gain > 0 then
                card.sell_cost = (tonumber(card.sell_cost) or 0) + gain
                return { message = "Value Up!" }
            end
        end
    end,
}

-- dot_matrix: PC counts unique ranks in the draw pile (G.deck.cards).
-- The fork exposes the same pile as raw card_data; rank strings are
-- normalised the Cryptid way, and Stone cards have no rank on PC
-- (SMODS.has_no_rank), so they are skipped here too.
SMODS.Joker {
    key = "dot_matrix",
    loc_txt = {
        name = "Dot Matrix",
        text = {
            "{C:mult}+#1#{} Mult for each {C:attention}unique",
            "rank {C:attention}remaining{} in deck",
            "{C:inactive}(Currently {C:mult}+#2#{C:inactive} Mult)",
        },
    },
    config = { extra = { mult = 1 } },
    rarity = 1, cost = 4, unlocked = true, discovered = false,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "dot_matrix.png", negative_sprite = "dot_matrix_negative.png",
    loc_vars = function(self, info_queue, card)
        local count = 0
        local seen = {}
        if G and G.deck then
            for _, d in ipairs(G.deck.cards or {}) do
                if d.enhancement ~= "stone" then
                    local id = tonumber(d.rank)
                        or ({ J = 11, Q = 12, K = 13, A = 14, T = 10 })[d.rank]
                    if id and not seen[id] then
                        seen[id] = true
                        count = count + 1
                    end
                end
            end
        end
        return { vars = { card.ability.extra.mult, count * card.ability.extra.mult } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            local count = 0
            local seen = {}
            if G and G.deck then
                for _, d in ipairs(G.deck.cards or {}) do
                    if d.enhancement ~= "stone" then
                        local id = tonumber(d.rank)
                            or ({ J = 11, Q = 12, K = 13, A = 14, T = 10 })[d.rank]
                        if id and not seen[id] then
                            seen[id] = true
                            count = count + 1
                        end
                    end
                end
            end
            if count > 0 then
                return { mult = count * card.ability.extra.mult }
            end
        end
    end,
}

-- downing_street: jest_poll_tag draws from the current Tag pool;
-- the port draws from the vanilla Tag types (the Paperback pb5
-- random-tag pattern) and gains it with G:addTag.
SMODS.Joker {
    key = "downing_street",
    loc_txt = {
        name = "Downing Street",
        text = {
            "Scoring {C:attention}10s{} have a {C:green}#1# in #2#{}",
            "chance to create a random {C:attention}Tag",
        },
    },
    config = { extra = { odds = 10 } },
    rarity = 2, cost = 6, unlocked = true, discovered = false,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "downing_street.png", negative_sprite = "downing_street_negative.png",
    loc_vars = function(self, info_queue, card)
        local numerator, denominator = SMODS.get_probability_vars(card, 1, card.ability.extra.odds)
        return { vars = { numerator, denominator } }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play and context.other_card then
            if context.other_card:get_id() == 10
                and SMODS.pseudorandom_probability(card, "downing", 1,
                    card.ability.extra.odds, "jest_downing_street") then
                local pool = {
                    "uncommon", "rare", "negative", "foil", "holo", "polychrome",
                    "investment", "voucher", "boss", "standard", "charm", "meteor",
                    "buffoon", "handy", "garbage", "ethereal", "coupon", "double",
                    "juggle", "d6", "topup", "speed", "orbital", "economy",
                }
                if G and G.addTag then
                    G:addTag(SMODS.pseudorandom_element(pool, "downing_tag"))
                end
                return { message = "+Tag!" }
            end
        end
    end,
}

-- duende: PC reads G.jokers.config.card_limit; the fork keeps the
-- total on G.joker_capacity. Copies of Duende count their own slots
-- as empty (PC's find_card with count_disabled), as the text says.
SMODS.Joker {
    key = "duende",
    loc_txt = {
        name = "Duende",
        text = {
            "Earn {C:money}$#2#{} at end of round",
            "for each {C:attention}empty{} Joker slot",
            "{s:0.8}Duende included",
            "{C:inactive}(Currently {C:money}$#1#{C:inactive})",
        },
    },
    config = { extra = { dollars = 2 } },
    rarity = 1, cost = 4, unlocked = true, discovered = false,
    blueprint_compat = false, eternal_compat = false, perishable_compat = true,
    sprite = "duende.png", negative_sprite = "duende_negative.png",
    loc_vars = function(self, info_queue, card)
        local empty = 0
        if G and G.jokers then
            local copies = 0
            for _, j in ipairs(G.jokers) do
                if j.def and j.def.id == "j_aij_duende" then copies = copies + 1 end
            end
            empty = math.max(0, (tonumber(G.joker_capacity) or #G.jokers) - #G.jokers + copies)
        end
        return { vars = { empty * card.ability.extra.dollars, card.ability.extra.dollars } }
    end,
    calc_dollar_bonus = function(self, card)
        local empty = 0
        if G and G.jokers then
            local copies = 0
            for _, j in ipairs(G.jokers) do
                if j.def and j.def.id == "j_aij_duende" then copies = copies + 1 end
            end
            empty = math.max(0, (tonumber(G.joker_capacity) or #G.jokers) - #G.jokers + copies)
        end
        if empty > 0 then
            return empty * card.ability.extra.dollars
        end
    end,
}

SMODS.Joker {
    key = "dwarf",
    loc_txt = {
        name = "Dwarf",
        text = {
            "{C:attention}2s{}, {C:attention}3s{}, {C:attention}4s{}, and {C:attention}5s{} give {C:mult}Mult",
            "equal to {C:attention}#1#{} minus their {C:attention}rank",
            "when scored",
        },
    },
    config = { extra = { mult = 6 } },
    rarity = 1, cost = 3, unlocked = true, discovered = false,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "dwarf.png", negative_sprite = "dwarf_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult } }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play and context.other_card then
            local id = context.other_card:get_id()
            if id >= 2 and id <= 5 then
                return { mult = card.ability.extra.mult - id }
            end
        end
    end,
}

-- earl: dollar_buffer + event boilerplate dropped (fork dollars return).
SMODS.Joker {
    key = "earl",
    loc_txt = {
        name = "Earl",
        text = {
            "{C:attention}Kings{} held in",
            "hand earn {C:money}$#1#",
        },
    },
    config = { extra = { dollars = 2 } },
    rarity = 3, cost = 10, unlocked = true, discovered = false,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "earl.png", negative_sprite = "earl_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.dollars } }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.hand
            and not context.end_of_round and context.other_card then
            if context.other_card:get_id() == 13 then
                if context.other_card.debuff then
                    return { message = "Debuffed!" }
                end
                return { dollars = card.ability.extra.dollars }
            end
        end
    end,
}

-- egg_cc: SMODS.scale_card inlined twice; the sell-value growth writes
-- sell_cost directly (see dont_be_a_joker note). PC's event wrapper
-- around the scaling drops.
SMODS.Joker {
    key = "egg_cc",
    loc_txt = {
        name = "\"egg\"",
        text = {
            "This Joker gains {C:chips}+#2#{} Chips",
            "and {C:money}$#3#{} of {C:attention}sell value{}",
            "at end of round",
            "{C:inactive}(Currently {C:chips}+#1#{C:inactive} Chips)",
            "{C:inactive}hey it's \"egg\"",
        },
    },
    config = { extra = { chips = 0, chip_mod = 9, sell_value = 1 } },
    rarity = 1, cost = 6, unlocked = true, discovered = false,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "egg_cc.png", negative_sprite = "egg_cc_negative.png",
    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                card.ability.extra.chips,
                card.ability.extra.chip_mod,
                card.ability.extra.sell_value,
            },
        }
    end,
    calculate = function(self, card, context)
        if context.end_of_round and not context.blueprint then
            card.ability.extra.chips = card.ability.extra.chips + card.ability.extra.chip_mod
            card.sell_cost = (tonumber(card.sell_cost) or 0) + card.ability.extra.sell_value
            return { message = localize("k_upgrade_ex") }
        end
        if context.joker_main and card.ability.extra.chips > 0 then
            return { chips = card.ability.extra.chips }
        end
    end,
}

-- elf: jest_add_tag("tag_investment") becomes G:addTag("investment");
-- the juice-until highlight is cosmetic and drops.
SMODS.Joker {
    key = "elf",
    loc_txt = {
        name = "Elf",
        text = {
            "After skipping {C:attention}#2#{} Blinds,",
            "{C:money}sell{} this Joker to create",
            "{C:attention}#3# Investment Tags",
            "{C:inactive}(Currently {C:attention}#1#{C:inactive}/#2#)",
        },
    },
    config = { extra = { current_skips = 0, skips = 2, tags = 2 } },
    rarity = 2, cost = 6, unlocked = true, discovered = false,
    blueprint_compat = true, eternal_compat = false, perishable_compat = true,
    sprite = "elf.png", negative_sprite = "elf_negative.png",
    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                card.ability.extra.current_skips,
                card.ability.extra.skips,
                card.ability.extra.tags,
            },
        }
    end,
    calculate = function(self, card, context)
        if context.skip_blind and not context.blueprint then
            card.ability.extra.current_skips = card.ability.extra.current_skips + 1
            return {
                message = (card.ability.extra.current_skips < card.ability.extra.skips)
                    and (card.ability.extra.current_skips .. "/" .. card.ability.extra.skips)
                    or "Active!",
            }
        end
        if context.selling_self
            and card.ability.extra.current_skips >= card.ability.extra.skips then
            if G and G.addTag then
                for _ = 1, card.ability.extra.tags do
                    G:addTag("investment")
                end
            end
            return { message = "Merry Christmas!" }
        end
    end,
}

SMODS.Joker {
    key = "emergent_pattern",
    loc_txt = {
        name = "Emergent Pattern",
        text = {
            "Retrigger scored cards if {C:attention}played",
            "{C:attention}hand{} contains exactly {C:attention}#1#{} cards",
        },
    },
    config = { extra = { cards = 3 } },
    rarity = 1, cost = 4, unlocked = true, discovered = false,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "emergent_pattern.png", negative_sprite = "emergent_pattern_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.cards } }
    end,
    calculate = function(self, card, context)
        if context.repetition and context.cardarea == G.play
            and context.full_hand and #context.full_hand == card.ability.extra.cards then
            return { repetitions = 1 }
        end
    end,
}

-- event_horizon: PC's poker_hand_changed context is the fork's
-- level_up_hand (hand NAME in context.level_up_hand, rise in
-- context.amount); SMODS.scale_card inlined.
SMODS.Joker {
    key = "event_horizon",
    loc_txt = {
        name = "Event Horizon",
        text = {
            "This {C:attention}Joker{} gains {X:mult,C:white}X#1#{} Mult",
            "when a hand is {C:attention}leveled up",
            "{C:inactive}(Currently {X:mult,C:white}X#2#{} {C:inactive}Mult){}",
            "{C:attention}Resets{} when the same",
            "hand is {C:attention}leveled up",
            "twice in a row",
            "{C:inactive}(Last leveled hand: {C:attention}#3#{C:inactive}){}",
        },
    },
    config = { extra = { xmult_mod = 0.2, xmult = 1, last_hand = "" } },
    rarity = 3, cost = 8, unlocked = true, discovered = false,
    blueprint_compat = true, eternal_compat = true, perishable_compat = false,
    sprite = "event_horizon.png", negative_sprite = "event_horizon_negative.png",
    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                card.ability.extra.xmult_mod,
                card.ability.extra.xmult,
                (card.ability.extra.last_hand and card.ability.extra.last_hand ~= "")
                    and card.ability.extra.last_hand or "None",
            },
        }
    end,
    calculate = function(self, card, context)
        if context.level_up_hand and not context.blueprint then
            local amt = tonumber(context.amount) or 1
            if amt > 1 or card.ability.extra.last_hand == context.level_up_hand then
                card.ability.extra.xmult = 1
                return { message = "Reset!" }
            elseif amt == 1 then
                card.ability.extra.last_hand = context.level_up_hand
                card.ability.extra.xmult = card.ability.extra.xmult
                    + card.ability.extra.xmult_mod
                return { message = localize("k_upgrade_ex") }
            end
        end
        if context.joker_main then
            return { xmult = card.ability.extra.xmult }
        end
    end,
}

-- evil_joker: PC's SMODS.destroy_cards on the single victim becomes
-- SMODS.destroy_joker; its eternal check reads the view's .eternal.
SMODS.Joker {
    key = "evil_joker",
    loc_txt = {
        name = "Evil Joker",
        text = {
            "{X:mult,C:white}X#1#{} Mult, destroys a",
            "{C:attention}random{} Joker when",
            "{C:attention}obtained",
        },
    },
    config = { extra = { x_mult = 3 } },
    rarity = 3, cost = 8, unlocked = true, discovered = false,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "evil_joker.png", negative_sprite = "evil_joker_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.x_mult } }
    end,
    add_to_deck = function(self, card, from_debuff)
        if from_debuff then return end
        if not (G and G.jokers) then return end
        local pool = {}
        for _, j in ipairs(G.jokers) do
            if j ~= card and not j.eternal then
                pool[#pool + 1] = j
            end
        end
        if #pool > 0 then
            local victim = SMODS.pseudorandom_element(pool, "aij_evil_joker")
            if victim then SMODS.destroy_joker(victim) end
        end
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            return { xmult = card.ability.extra.x_mult }
        end
    end,
}

-- executioner: PC's context.removed / glass_shattered lists are the
-- fork's context.port.destroyed_cards; SMODS.scale_card inlined
-- (one growth per destroyed face card, as PC's loop does).
SMODS.Joker {
    key = "executioner",
    loc_txt = {
        name = "Executioner",
        text = {
            "This Joker gains {C:chips}+#1#{} Chips",
            "when a {C:attention}face{} card is {C:attention}destroyed",
            "{C:inactive}(Currently {C:chips}+#2#{C:inactive} Chips)",
        },
    },
    config = { extra = { chips = 0, chip_gain = 50 } },
    rarity = 2, cost = 6, unlocked = true, discovered = false,
    blueprint_compat = true, eternal_compat = true, perishable_compat = false,
    sprite = "executioner.png", negative_sprite = "executioner_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chip_gain, card.ability.extra.chips } }
    end,
    calculate = function(self, card, context)
        if context.remove_playing_cards and not context.blueprint then
            local removed = (context.port and context.port.destroyed_cards) or {}
            local faces = 0
            for _, v in ipairs(removed) do
                local is_face = false
                if v.is_face then
                    is_face = v:is_face()
                else
                    local d = v.card_data or v
                    if d.enhancement ~= "stone" then
                        local r = tonumber(d.rank)
                            or ({ J = 11, Q = 12, K = 13, A = 14, T = 10 })[d.rank]
                        is_face = (r == 11 or r == 12 or r == 13)
                    end
                end
                if is_face then faces = faces + 1 end
            end
            if faces > 0 then
                card.ability.extra.chips = card.ability.extra.chips
                    + faces * card.ability.extra.chip_gain
                return { message = localize("k_upgrade_ex") }
            end
            return
        end
        if context.joker_main then
            return { chips = card.ability.extra.chips }
        end
    end,
}

-- famulus: PC checks consumeable.ability.set == "Tarot"; the fork's
-- using_consumeable carries the kind on context.port.consumable_kind.
-- dollar_buffer boilerplate dropped.
SMODS.Joker {
    key = "famulus",
    loc_txt = {
        name = "Famulus",
        text = {
            "Earn {C:money}$#1#{} when a",
            "{C:tarot}Tarot Card{} is used",
        },
    },
    config = { extra = { dollars = 2 } },
    rarity = 1, cost = 5, unlocked = true, discovered = false,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "famulus.png", negative_sprite = "famulus_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.dollars } }
    end,
    calculate = function(self, card, context)
        if context.using_consumeable and context.port
            and context.port.consumable_kind == "tarot" then
            return { dollars = card.ability.extra.dollars }
        end
    end,
}

-- father_and_son: SMODS.scale_card inlined.
SMODS.Joker {
    key = "father_and_son",
    loc_txt = {
        name = "Father and Son",
        text = {
            "This Joker gains {X:mult,C:white}X#2#{} Mult",
            "if {C:attention}scored hand{} contains exactly",
            "{C:attention}one King{} and {C:attention}one Jack{}",
            "{C:inactive}(Currently{} {X:mult,C:white}X#1#{}{C:inactive} Mult){}",
        },
    },
    config = { extra = { gain = 0.25, xmult = 1 } },
    rarity = 2, cost = 7, unlocked = true, discovered = false,
    blueprint_compat = true, eternal_compat = true, perishable_compat = false,
    sprite = "father_and_son.png", negative_sprite = "father_and_son_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.xmult, card.ability.extra.gain } }
    end,
    calculate = function(self, card, context)
        if context.before and not context.blueprint and context.scoring_hand then
            local kings, jacks = 0, 0
            for _, v in ipairs(context.scoring_hand) do
                local id = v:get_id()
                if id == 13 then kings = kings + 1 end
                if id == 11 then jacks = jacks + 1 end
            end
            if kings == 1 and jacks == 1 then
                card.ability.extra.xmult = card.ability.extra.xmult
                    + card.ability.extra.gain
                return { message = localize("k_upgrade_ex") }
            end
        end
        if context.joker_main and card.ability.extra.xmult > 1 then
            return { xmult = card.ability.extra.xmult }
        end
    end,
}

-- father_christmas: dollar_buffer boilerplate dropped.
SMODS.Joker {
    key = "father_christmas",
    loc_txt = {
        name = "Father Christmas",
        text = {
            "Earn {C:money}$#1#{} when any",
            "card is {C:attention}scored",
        },
    },
    config = { extra = { dollars = 1 } },
    rarity = 3, cost = 10, unlocked = true, discovered = false,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "father_christmas.png", negative_sprite = "father_christmas_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.dollars } }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            return { dollars = card.ability.extra.dollars }
        end
    end,
}

-- fatuus: PC reads current_round.hands_played == 0 in `after` (its
-- counter ticks after scoring); the fork ticks at play time, so the
-- first hand reads 1 there (the MoreFluff Dramatic Entrance offset).
-- The seal is applied through the node's canonical setter when it
-- has one, else the card_data field (the mf_set_seal pattern).
SMODS.Joker {
    key = "fatuus",
    loc_txt = {
        name = "Fatuus",
        text = {
            "If first hand of round",
            "contains only {C:attention}Kings{} and",
            "{C:attention}Queens{}, apply a {C:blue}Blue Seal{}",
            "to a random played card",
        },
    },
    config = { extra = {} },
    rarity = 3, cost = 9, unlocked = true, discovered = false,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "fatuus.png", negative_sprite = "fatuus_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = {} }
    end,
    calculate = function(self, card, context)
        if context.after and context.full_hand and #context.full_hand > 0 then
            if G and G.get_round_hands_played and G:get_round_hands_played() == 1 then
                local only_kings_queens = true
                for _, played in ipairs(context.full_hand) do
                    local id = played:get_id()
                    if id ~= 13 and id ~= 12 then
                        only_kings_queens = false
                        break
                    end
                end
                if only_kings_queens then
                    local eligible = {}
                    for _, played in ipairs(context.full_hand) do
                        if not played.seal then
                            eligible[#eligible + 1] = played
                        end
                    end
                    if #eligible > 0 then
                        local target = SMODS.pseudorandom_element(eligible, "fatuus_target")
                        if target then
                            if target.set_seal then
                                target:set_seal("blue")
                            elseif target.card_data then
                                target.card_data.seal = "blue"
                            end
                            return { message = "Blue Seal!" }
                        end
                    end
                end
            end
        end
    end,
}

-- feedback_form: SMODS.get_enhancements degenerates to the card's
-- single fork enhancement; "unique" = no other scoring card shares it.
SMODS.Joker {
    key = "feedback_form",
    loc_txt = {
        name = "Feedback Form",
        text = {
            "All {C:attention}unique{} enhancements in",
            "the {C:attention}played hand{} give {X:mult,C:white}X#1#{} Mult",
            "when scored",
        },
    },
    config = { extra = { xmult = 1.5 } },
    rarity = 2, cost = 6, unlocked = true, discovered = false,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "feedback_form.png", negative_sprite = "feedback_form_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.xmult } }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play and context.other_card then
            local enh = context.other_card.enhancement
            if enh and enh ~= "base" then
                local count = 0
                for _, c in ipairs(context.scoring_hand or {}) do
                    if c.enhancement == enh then count = count + 1 end
                end
                if count == 1 then
                    return { xmult = card.ability.extra.xmult }
                end
            end
        end
    end,
}

-- firework: PC's has_enhancement "m_mult" is the fork value "mult".
SMODS.Joker {
    key = "firework",
    loc_txt = {
        name = "Firework",
        text = {
            "First played {C:attention}Mult",
            "card gives {X:mult,C:white}X#1#{} Mult",
            "when scored",
        },
    },
    config = { extra = { xmult = 3 } },
    rarity = 2, cost = 7, unlocked = true, discovered = false,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "firework.png", negative_sprite = "firework_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.xmult } }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play and context.other_card then
            if context.other_card.enhancement == "mult" then
                local is_first_mult = false
                for _, c in ipairs(context.scoring_hand or {}) do
                    if c.enhancement == "mult" then
                        is_first_mult = (c == context.other_card)
                        break
                    end
                end
                if is_first_mult then
                    return { xmult = card.ability.extra.xmult }
                end
            end
        end
    end,
}

-- fish_fingers: PC's ease_hands_played at setting_blind is a direct
-- G.hands write (the Paperback Ice Cube pattern); the countdown and
-- self-destruct run at end_of_round, SMODS.scale_card inlined.
SMODS.Joker {
    key = "fish_fingers",
    loc_txt = {
        name = "Fish Fingers",
        text = {
            "{C:blue}+#1#{} Hands per round,",
            "loses {C:blue}-#2#{} Hand when Blind",
            "is {C:attention}defeated",
        },
    },
    config = { extra = { hands = 5, hand_mod = 1 } },
    rarity = 2, cost = 7, unlocked = true, discovered = false,
    blueprint_compat = true, eternal_compat = false, perishable_compat = true,
    sprite = "fish_fingers.png", negative_sprite = "fish_fingers_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.hands, card.ability.extra.hand_mod } }
    end,
    calculate = function(self, card, context)
        if context.setting_blind then
            if G then
                G.hands = (tonumber(G.hands) or 0) + card.ability.extra.hands
            end
            return { message = "+" .. card.ability.extra.hands .. " Hands" }
        end
        if context.end_of_round and not context.blueprint then
            if (card.ability.extra.hands - card.ability.extra.hand_mod) <= 0 then
                SMODS.destroy_joker(card)
                return { message = "Eaten!" }
            end
            card.ability.extra.hands = card.ability.extra.hands
                - card.ability.extra.hand_mod
            return { message = "-" .. card.ability.extra.hand_mod .. " Hands" }
        end
    end,
}

-- flibbertigibbit: on the fork, context.full_hand is empty for
-- discards; the batch is context.port.discarded_nodes (conventions).
-- PC reads base.suit directly, so Stone cards count their nominal
-- suit here too. dollar_buffer boilerplate dropped.
SMODS.Joker {
    key = "flibbertigibbit",
    loc_txt = {
        name = "Flibbertigibbit",
        text = {
            "Earn {C:money}$#1#{} per {C:attention}unique suit{} in",
            "{C:attention}discarded{} poker hand",
        },
    },
    config = { extra = { dollars = 1 } },
    rarity = 1, cost = 6, unlocked = true, discovered = false,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "flibbertigibbit.png", negative_sprite = "flibbertigibbit_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.dollars } }
    end,
    calculate = function(self, card, context)
        if context.pre_discard then
            local nodes = (context.port and context.port.discarded_nodes)
                or context.full_hand or {}
            local suits = {}
            for _, v in ipairs(nodes) do
                local suit = (v.base and v.base.suit)
                    or (v.card_data and v.card_data.suit)
                if suit then suits[suit] = true end
            end
            local unique = 0
            for _ in pairs(suits) do unique = unique + 1 end
            if unique > 0 then
                return { dollars = unique * card.ability.extra.dollars }
            end
        end
    end,
}

-- flushed_face: SMODS.scale_card inlined (its custom operation is a
-- plain addition); PC's extra-chain message becomes a message return.
SMODS.Joker {
    key = "flushed_face",
    loc_txt = {
        name = "Flushed Face",
        text = {
            "This Joker gains {C:mult}+#1#{} Mult",
            "per scored {C:attention}face card{} in a {C:attention}Flush{}",
            "{C:inactive}(Currently {C:mult}+#2#{C:inactive} Mult)",
        },
    },
    config = { extra = { mult = 0, mult_mod = 1 } },
    rarity = 1, cost = 5, unlocked = true, discovered = false,
    blueprint_compat = true, eternal_compat = true, perishable_compat = false,
    sprite = "flushed_face.png", negative_sprite = "flushed_face_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult_mod, card.ability.extra.mult } }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play
            and not context.blueprint and context.other_card then
            if context.poker_hands and next(context.poker_hands["Flush"])
                and context.other_card:is_face() then
                card.ability.extra.mult = card.ability.extra.mult
                    + card.ability.extra.mult_mod
                return { message = localize("k_upgrade_ex") }
            end
        end
        if context.joker_main and card.ability.extra.mult > 0 then
            return { mult = card.ability.extra.mult }
        end
    end,
}

-- flying_ace: PC resets its tally on the cashing_out beat; the fork
-- folds cash-out into the round-end payout, so the reset rides
-- calc_dollar_bonus itself (Paperback Joker Cookie precedent). PC's
-- not-repetition guard is redundant with the per-suit tally and drops.
SMODS.Joker {
    key = "flying_ace",
    loc_txt = {
        name = "Flying Ace",
        text = {
            "Earn {C:money}$#1#{} at end of round",
            "per {C:attention}Ace{} of unique {C:attention}suit{}",
            "scored this round",
            "{C:inactive}(Currently{} {C:money}$#2#{}{C:inactive}){}",
        },
    },
    config = { extra = { dollar_gain = 2, dollars = 0, aces = {} } },
    rarity = 1, cost = 5, unlocked = true, discovered = false,
    blueprint_compat = false, eternal_compat = true, perishable_compat = true,
    sprite = "flying_ace.png", negative_sprite = "flying_ace_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.dollar_gain, card.ability.extra.dollars } }
    end,
    calculate = function(self, card, context)
        if context.individual and not context.blueprint and context.other_card then
            if context.cardarea == G.play and not context.other_card.debuff then
                if context.other_card:get_id() == 14 then
                    local suit = context.other_card.base.suit
                    if suit and not card.ability.extra.aces[suit] then
                        card.ability.extra.dollars = card.ability.extra.dollars
                            + card.ability.extra.dollar_gain
                        card.ability.extra.aces[suit] = true
                    end
                end
            end
        end
    end,
    calc_dollar_bonus = function(self, card)
        local amt = card.ability.extra.dollars
        card.ability.extra.aces = {}
        card.ability.extra.dollars = 0
        if amt > 0 then return amt end
    end,
}

-- fortunato: PC turns unscored played cards into Stone via
-- set_ability(G.P_CENTERS.m_stone); the port writes the "stone"
-- enhancement through the node's canonical setter when it has one,
-- else the card_data field (the mf_set_enhancement pattern), and
-- reads Stone back off .enhancement instead of ability.name.
-- Scoring membership is compared by card_data, not node identity.
SMODS.Joker {
    key = "fortunato",
    loc_txt = {
        name = "Fortunato",
        text = {
            "Turn all {C:attention}played{} but {C:attention}unscored{}",
            "cards into {C:attention}Stone Cards{}",
            "This {C:attention}Joker{} gains {X:mult,C:white}X#2#{} Mult",
            "when a {C:attention}Stone Card{} is scored",
            "{C:inactive}(Currently{} {X:mult,C:white}X#1#{} {C:inactive}Mult){}",
        },
    },
    config = { extra = { x_mult = 1, xmult_mod = 0.1, activated = false } },
    rarity = 4, cost = 20, unlocked = false, discovered = false,
    blueprint_compat = true, eternal_compat = true, perishable_compat = false,
    sprite = "fortunato.png", negative_sprite = "fortunato_negative.png",
    soul_sprite = "fortunato_soul.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.x_mult, card.ability.extra.xmult_mod } }
    end,
    calculate = function(self, card, context)
        if context.after and not context.blueprint then
            if context.scoring_hand and context.full_hand
                and #context.scoring_hand > 0 and #context.full_hand > 0 then
                if #context.scoring_hand == #context.full_hand then
                    card.ability.extra.activated = false
                end
                local scored = {}
                for _, c in ipairs(context.scoring_hand) do
                    scored[c.card_data or c] = true
                end
                for _, played in ipairs(context.full_hand) do
                    if not scored[played.card_data or played]
                        and played.enhancement ~= "stone" then
                        card.ability.extra.activated = true
                        if played.set_enhancement then
                            played:set_enhancement("stone")
                        elseif played.card_data then
                            played.card_data.enhancement = "stone"
                        end
                    end
                end
                if card.ability.extra.activated then
                    return { message = "Stone" }
                end
            end
        end
        if context.individual and context.cardarea == G.play and context.other_card then
            if context.other_card.enhancement == "stone" and not context.blueprint then
                card.ability.extra.x_mult = card.ability.extra.x_mult
                    + card.ability.extra.xmult_mod
                return { message = localize("k_upgrade_ex") }
            end
        end
        if context.joker_main and card.ability.extra.x_mult > 1 then
            return { xmult = card.ability.extra.x_mult }
        end
    end,
}

-- fortune_cookie: PC's keyless SMODS.add_card({set="Tarot"}) becomes
-- a G:random_consumable_id_of_kind roll plus add_card by id; a nil
-- return is the fork's no-room answer, replacing the buffer check.
-- The pack countdown / self-destruct matches PC (it runs whether or
-- not the Tarot fit).
SMODS.Joker {
    key = "fortune_cookie",
    loc_txt = {
        name = "Fortune Cookie",
        text = {
            "Create a random {C:tarot}Tarot",
            "card when any {C:attention}Booster{}",
            "{C:attention}Pack{} is opened, consumed",
            "after {C:attention}#1#{} packs",
            "{C:inactive}(Must have room){}",
        },
    },
    config = { extra = { packs_remaining = 5, packs = 5 } },
    rarity = 1, cost = 4, unlocked = true, discovered = false,
    blueprint_compat = true, eternal_compat = false, perishable_compat = true,
    sprite = "fortune_cookie.png", negative_sprite = "fortune_cookie_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.packs_remaining, card.ability.extra.packs } }
    end,
    calculate = function(self, card, context)
        if context.open_booster then
            local made = false
            if G and G.random_consumable_id_of_kind then
                local id = G:random_consumable_id_of_kind("tarot", {}, "jest_fortune_cookie")
                if id then
                    made = SMODS.add_card { set = "Tarot", key = id } ~= nil
                end
            end
            if not context.blueprint then
                if (card.ability.extra.packs_remaining - 1) <= 0 then
                    SMODS.destroy_joker(card)
                    return { message = "Eaten!" }
                end
                card.ability.extra.packs_remaining = card.ability.extra.packs_remaining - 1
            end
            if made then
                return { message = "+1 Tarot" }
            end
        end
    end,
}

-- fou_du_roi: the probability roll happens at joker_main whether or
-- not the hand holds a King/Queen, exactly as PC's condition order
-- consumes it; the creation then needs a King or Queen in the played
-- hand and room for the Tarot. PC's seed typo ("fou_du_rou") kept.
SMODS.Joker {
    key = "fou_du_roi",
    loc_txt = {
        name = "Fou du Roi",
        text = {
            "{C:green}#1# in #2#{} chance to create a",
            "{C:tarot}Tarot{} card if played hand",
            "contains a {C:attention}King{} or {C:attention}Queen",
            "{C:inactive}(Must have room)",
        },
    },
    config = { extra = { odds = 2 } },
    rarity = 2, cost = 6, unlocked = true, discovered = false,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "fou_du_roi.png", negative_sprite = "fou_du_roi_negative.png",
    loc_vars = function(self, info_queue, card)
        local numerator, denominator = SMODS.get_probability_vars(card, 1, card.ability.extra.odds)
        return { vars = { numerator, denominator } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            local hit = SMODS.pseudorandom_probability(card, "fou_du_rou", 1,
                card.ability.extra.odds, "jest_fou_du_roi")
            if hit then
                local has_kq = false
                for _, v in ipairs(context.full_hand or {}) do
                    local id = v:get_id()
                    if id == 12 or id == 13 then
                        has_kq = true
                        break
                    end
                end
                if has_kq and G and G.random_consumable_id_of_kind then
                    local id = G:random_consumable_id_of_kind("tarot", {}, "aij_fou_du_roi")
                    if id and SMODS.add_card { set = "Tarot", key = id } then
                        return { message = "+1 Tarot" }
                    end
                end
            end
        end
    end,
}

-- fruity_joker: PC's context.other_joker is the fork's post_trigger
-- (the sibling-pack adaptation); editions are the fork's normalised
-- strings. The held-Joker/playing-card in_pool gate drops (fork
-- in_pool gets no game state) -- see census.
SMODS.Joker {
    key = "fruity_joker",
    loc_txt = {
        name = "Fruity Joker",
        text = {
            "{C:mult}+#1#{} Mult when a",
            "{C:attention}Polychrome{} edition",
            "triggers",
        },
    },
    config = { extra = { mult = 15 } },
    rarity = 1, cost = 5, unlocked = true, discovered = false,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "fruity_joker.png", negative_sprite = "fruity_joker_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult } }
    end,
    calculate = function(self, card, context)
        if context.post_trigger and context.other_card
            and context.other_card ~= card then
            if context.other_card.edition == "polychrome" then
                return { mult = card.ability.extra.mult }
            end
        end
        if context.individual and context.cardarea == G.play and context.other_card then
            if context.other_card.edition == "polychrome" then
                return { mult = card.ability.extra.mult }
            end
        end
    end,
}

-- funny_bone: PC's selling branch is direct; its aij_after_destroying_
-- cards branch filtered to Jokers, which is exactly the fork's
-- joker_type_destroyed. Random Tarot creation as in fortune_cookie.
SMODS.Joker {
    key = "funny_bone",
    loc_txt = {
        name = "Funny Bone",
        text = {
            "When any Joker is {C:money}sold{} or",
            "{C:red}destroyed{}, create a",
            "random {C:tarot}Tarot Card",
        },
    },
    config = { extra = {} },
    rarity = 2, cost = 7, unlocked = true, discovered = false,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "funny_bone.png", negative_sprite = "funny_bone_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = {} }
    end,
    calculate = function(self, card, context)
        if context.selling_card or context.joker_type_destroyed then
            if G and G.random_consumable_id_of_kind then
                local id = G:random_consumable_id_of_kind("tarot", {}, "funny_bone")
                if id and SMODS.add_card { set = "Tarot", key = id } then
                    return { message = "+1 Tarot" }
                end
            end
        end
    end,
}

SMODS.Joker {
    key = "funny_bunch",
    loc_txt = {
        name = "Funny Bunch",
        text = {
            "Gives {X:mult,C:white}X#1#{} Mult per",
            "{C:common}Common{} Joker",
            "{C:inactive}(Currently {X:mult,C:white}X#2#{C:inactive} Mult){}",
        },
    },
    config = { extra = { xmult_mod = 0.5 } },
    rarity = 2, cost = 6, unlocked = true, discovered = false,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "funny_bunch.png", negative_sprite = "funny_bunch_negative.png",
    loc_vars = function(self, info_queue, card)
        local commons = 0
        if G and G.jokers then
            for _, v in ipairs(G.jokers) do
                if tonumber(v.rarity) == 1 then commons = commons + 1 end
            end
        end
        return {
            vars = {
                card.ability.extra.xmult_mod,
                1 + (commons * card.ability.extra.xmult_mod),
            },
        }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            local commons = 0
            if G and G.jokers then
                for _, v in ipairs(G.jokers) do
                    if tonumber(v.rarity) == 1 then commons = commons + 1 end
                end
            end
            if commons > 0 then
                return { xmult = 1 + (commons * card.ability.extra.xmult_mod) }
            end
        end
    end,
}

-- funny_money: dollar_buffer boilerplate dropped.
SMODS.Joker {
    key = "funny_money",
    loc_txt = {
        name = "Funny Money",
        text = {
            "Earn {C:money}$#1#{} when",
            "{C:attention}skipping{} a Blind",
        },
    },
    config = { extra = { dollars = 15 } },
    rarity = 1, cost = 6, unlocked = true, discovered = false,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "funny_money.png", negative_sprite = "funny_money_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.dollars } }
    end,
    calculate = function(self, card, context)
        if context.skip_blind then
            return { dollars = card.ability.extra.dollars }
        end
    end,
}

-- funny_phone: PC scales through a func on the return; the port adds
-- the rolled gain directly at reroll_shop (same end state).
SMODS.Joker {
    key = "funny_phone",
    loc_txt = {
        name = "Funny Phone",
        text = {
            "This Joker gains {C:chips}+#3#-#2#{} Chips",
            "when {C:green}rerolling{} in the {C:attention}Shop",
            "{C:inactive}(Currently {C:chips}+#1#{} {C:inactive}Chips){}",
        },
    },
    config = { extra = { chips = 0, chip_gain = 0, max = 10, min = 1 } },
    rarity = 1, cost = 5, unlocked = true, discovered = false,
    blueprint_compat = true, eternal_compat = true, perishable_compat = false,
    sprite = "funny_phone.png", negative_sprite = "funny_phone_negative.png",
    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                card.ability.extra.chips,
                card.ability.extra.max,
                card.ability.extra.min,
            },
        }
    end,
    calculate = function(self, card, context)
        if context.reroll_shop and not context.blueprint then
            local gain = SMODS.pseudorandom("funny_phone",
                card.ability.extra.min, card.ability.extra.max)
            card.ability.extra.chip_gain = gain
            card.ability.extra.chips = card.ability.extra.chips + gain
            return { message = "+" .. gain .. " Chips" }
        end
        if context.joker_main then
            return { chips = card.ability.extra.chips }
        end
    end,
}

-- gameshow: PC's poll_edition("wheel_of_fortune", nil, true, true) is
-- a guaranteed Foil/Holo/Polychrome draw with no Negative -- the
-- port uses the MikasPack table draw; set_edition becomes a direct
-- field assignment (the Cryptid Kaleidoscope precedent). The $3 is
-- charged whenever an uneditioned Joker exists, win or lose, as PC.
SMODS.Joker {
    key = "gameshow",
    loc_txt = {
        name = "Gameshow",
        text = {
            "{C:green}#1# in #2#{} chance to add",
            "{C:dark_edition}Foil{}, {C:dark_edition}Holographic{}, or",
            "{C:dark_edition}Polychrome{} edition",
            "to a random {C:attention}Joker",
            "when {C:attention}blind{} is selected",
            "{C:money}-$#3#{} when triggered",
            "regardless of outcome",
        },
    },
    config = { extra = { odds = 4, money = 3 } },
    rarity = 2, cost = 6, unlocked = true, discovered = false,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "gameshow.png", negative_sprite = "gameshow_negative.png",
    loc_vars = function(self, info_queue, card)
        local numerator, denominator = SMODS.get_probability_vars(card, 1, card.ability.extra.odds)
        return { vars = { numerator, denominator, card.ability.extra.money } }
    end,
    calculate = function(self, card, context)
        if context.setting_blind then
            local pool = {}
            if G and G.jokers then
                for _, j in ipairs(G.jokers) do
                    if j.edition == nil then
                        pool[#pool + 1] = j
                    end
                end
            end
            if #pool > 0 then
                if SMODS.pseudorandom_probability(card, "gameshow", 1,
                    card.ability.extra.odds, "jest_gameshow") then
                    local pick = SMODS.pseudorandom_element(pool, "gameshow")
                    local edition = SMODS.pseudorandom_element(
                        { "foil", "foil", "holo", "holo", "polychrome" },
                        "gameshow_edition")
                    if pick then pick.edition = edition end
                    return { dollars = -card.ability.extra.money }
                end
                return { dollars = -card.ability.extra.money, message = "Nope!" }
            end
        end
    end,
}

-- gelato: PC destroys itself in `after` once current_round.
-- hands_played > 0 (PC's counter ticks after scoring, so that is
-- the second hand onward); the fork ticks at play time, so the
-- same beat reads > 1 (see fatuus note).
SMODS.Joker {
    key = "gelato",
    loc_txt = {
        name = "Gelato",
        text = {
            "Earn {C:money}$#1#{} at end of",
            "{C:attention}round{}, {C:red}self-destructs{}",
            "if Blind is not beaten",
            "in a {C:attention}single hand{}",
        },
    },
    config = { extra = { dollars = 10 } },
    rarity = 2, cost = 6, unlocked = true, discovered = false,
    blueprint_compat = true, eternal_compat = false, perishable_compat = true,
    sprite = "gelato.png", negative_sprite = "gelato_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.dollars } }
    end,
    calculate = function(self, card, context)
        if context.after and not context.blueprint then
            if G and G.get_round_hands_played and G:get_round_hands_played() > 1 then
                SMODS.destroy_joker(card)
                return { message = "Melted!" }
            end
        end
    end,
    calc_dollar_bonus = function(self, card)
        return card.ability.extra.dollars
    end,
}

-- geoglyph: PC counts G.hand.cards matching the scored card's suit
-- with is_suit; the fork's hand nodes answer the same call (with a
-- card_data fallback for nodes without the method).
SMODS.Joker {
    key = "geoglyph",
    loc_txt = {
        name = "Geoglyph",
        text = {
            "Scoring cards give {C:mult}+#1#{} Mult",
            "for each card of the same",
            "suit {C:attention}held in hand",
        },
    },
    config = { extra = { mult = 1 } },
    rarity = 1, cost = 4, unlocked = true, discovered = false,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "geoglyph.png", negative_sprite = "geoglyph_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult } }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play and context.other_card then
            local suit = context.other_card.base.suit
            local matches = 0
            if G and G.hand and G.hand.card_nodes then
                for _, n in ipairs(G.hand.card_nodes) do
                    if n.is_suit then
                        if n:is_suit(suit) then matches = matches + 1 end
                    elseif n.card_data and n.card_data.suit == suit
                        and n.card_data.enhancement ~= "stone" then
                        matches = matches + 1
                    end
                end
            end
            if matches > 0 then
                return { mult = matches * card.ability.extra.mult }
            end
        end
    end,
}

-- giocoliere: PC drives G.hand:change_size around Boss Blinds; the
-- fork recomputes hand size from the live ability h_size modifier
-- (modifier_total reads j.ability), so the port toggles that field
-- on the boss state -- the Paperback dynamic-h_size pattern. Boss
-- detection: context.port.is_boss_blind, else blind index 3.
SMODS.Joker {
    key = "giocoliere",
    loc_txt = {
        name = "Giocoliere",
        text = {
            "{C:attention}+#1#{} hand size{} during",
            "each {C:attention}Boss Blind",
        },
    },
    config = { extra = { hand_size = 3 } },
    rarity = 1, cost = 4, unlocked = true, discovered = false,
    blueprint_compat = false, eternal_compat = true, perishable_compat = true,
    sprite = "giocoliere.png", negative_sprite = "giocoliere_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.hand_size } }
    end,
    calculate = function(self, card, context)
        if context.setting_blind and not context.blueprint then
            local boss = false
            if context.port and context.port.is_boss_blind ~= nil then
                boss = context.port.is_boss_blind == true
            elseif G then
                boss = tonumber(G.current_blind_index) == 3
            end
            card.ability.h_size = boss and card.ability.extra.hand_size or 0
            card.ability.boss_bonus_active = boss
        end
        if context.blind_defeated and not context.blueprint then
            card.ability.h_size = 0
            card.ability.boss_bonus_active = false
        end
    end,
    add_to_deck = function(self, card, from_debuff)
        card.ability.boss_bonus_active = false
        if G and G.get_active_boss_blind_id and G:get_active_boss_blind_id()
            and not card.debuff then
            card.ability.h_size = card.ability.extra.hand_size
            card.ability.boss_bonus_active = true
        end
    end,
    remove_from_deck = function(self, card, from_debuff)
        card.ability.h_size = 0
        card.ability.boss_bonus_active = false
    end,
}

-- glasgow_smile: first-hand check uses the fork's play-time counter
-- offset (PC hands_played == 0 in `after` reads 1 here; see fatuus).
-- PC's destroy_cards on the single played card is destroy_card;
-- has_enhancement "m_bonus" is the fork value "bonus".
SMODS.Joker {
    key = "glasgow_smile",
    loc_txt = {
        name = "Glasgow Smile",
        text = {
            "{C:chips}+#1#{} Chips when a {C:attention}Bonus",
            "{C:attention}Card{} is scored",
            "If the {C:attention}first{} hand of round",
            "is a single {C:attention}Bonus Card{},",
            "{C:red}destroy{} it and increase this",
            "amount by {C:chips}+#2#{} Chips",
        },
    },
    config = { extra = { chips = 0, gain = 30 } },
    rarity = 2, cost = 6, unlocked = true, discovered = false,
    blueprint_compat = true, eternal_compat = false, perishable_compat = false,
    sprite = "glasgow_smile.png", negative_sprite = "glasgow_smile_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chips, card.ability.extra.gain } }
    end,
    calculate = function(self, card, context)
        if context.after and not context.blueprint then
            if G and G.get_round_hands_played and G:get_round_hands_played() == 1
                and context.full_hand and #context.full_hand == 1 then
                local played = context.full_hand[1]
                if played.enhancement == "bonus" then
                    card.ability.extra.chips = card.ability.extra.chips
                        + card.ability.extra.gain
                    SMODS.destroy_card(played)
                    return { message = localize("k_upgrade_ex") }
                end
            end
        end
        if context.individual and context.cardarea == G.play and context.other_card then
            if context.other_card.enhancement == "bonus"
                and card.ability.extra.chips > 0 then
                return { chips = card.ability.extra.chips }
            end
        end
    end,
}

-- gloaming: PC's current_round.hands_left is the fork's G.hands
-- (the MoreFluff mf_hands_left readout).
SMODS.Joker {
    key = "gloaming",
    loc_txt = {
        name = "Gloaming",
        text = {
            "Scoring cards give",
            "{X:mult,C:white}X#1#{} Mult on {C:attention}final",
            "{C:attention}hand{} of round",
        },
    },
    config = { extra = { xmult = 1.5 } },
    rarity = 3, cost = 8, unlocked = true, discovered = false,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "gloaming.png", negative_sprite = "gloaming_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.xmult } }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            if G and (tonumber(G.hands) or 1) == 0 then
                return { xmult = card.ability.extra.xmult }
            end
        end
    end,
}

-- goblet: PC's add/remove_from_deck card_limit edits become the
-- fork's declarative consumable_slots modifier (sample-pack ruling).
SMODS.Joker {
    key = "goblet",
    loc_txt = {
        name = "Goblet",
        text = {
            "{C:attention}+#1#{} Consumable Slots",
        },
    },
    config = { consumable_slots = 2, extra = { slots = 2 } },
    rarity = 1, cost = 4, unlocked = true, discovered = false,
    blueprint_compat = false, eternal_compat = true, perishable_compat = true,
    sprite = "goblet.png", negative_sprite = "goblet_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.slots } }
    end,
}

-- gonnella: PC's SMODS.add_card with a rarity and poll_edition(...)
-- becomes a G:random_joker_def_id_by_rarity roll plus add_card with
-- a table-drawn edition (the MikasPack roll_edition pattern; the
-- guaranteed draw may include Negative, as PC's does).
SMODS.Joker {
    key = "gonnella",
    loc_txt = {
        name = "Gonella",
        text = {
            "{C:attention}Create{} a random {C:dark_edition}Editioned",
            "Joker of the same rarity",
            "when a non-{C:dark_edition}editioned",
            "Joker is {C:money}sold",
        },
    },
    config = {},
    rarity = 4, cost = 20, unlocked = false, discovered = false,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "gonnella.png", negative_sprite = "gonnella_negative.png",
    soul_sprite = "gonnella_soul.png",
    loc_vars = function(self, info_queue, card)
        return { vars = {} }
    end,
    calculate = function(self, card, context)
        if context.selling_card and context.card and not context.card.edition then
            local sold = context.card
            if G and G.random_joker_def_id_by_rarity then
                local id = G:random_joker_def_id_by_rarity(
                    tonumber(sold.rarity) or sold.rarity, "joker_sold")
                if id then
                    local edition = SMODS.pseudorandom_element(
                        { "foil", "foil", "holo", "holo", "polychrome", "negative" },
                        "joker_sold_edition")
                    if SMODS.add_card { set = "Joker", key = id, edition = edition } then
                        return { message = "+1 Joker" }
                    end
                end
            end
        end
    end,
}

-- goo_joker: get_enhancements degenerates to the single fork
-- enhancement. The in_pool enhancement-in-deck gate drops (fork
-- in_pool gets no game state) -- see census.
SMODS.Joker {
    key = "goo_joker",
    loc_txt = {
        name = "Goo Joker",
        text = {
            "Scored {C:attention}enhanced{}",
            "cards give {C:mult}+#1#{} Mult",
        },
    },
    config = { extra = { mult = 8 } },
    rarity = 1, cost = 4, unlocked = true, discovered = false,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "goo_joker.png", negative_sprite = "goo_joker_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult } }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play and context.other_card then
            local enh = context.other_card.enhancement
            if enh and enh ~= "base" then
                return { mult = card.ability.extra.mult }
            end
        end
    end,
}

-- goon_joker: PC's G.GAME.blind.boss is the fork's is_boss_blind
-- event flag, falling back to blind index 3 (sibling-pack pattern).
SMODS.Joker {
    key = "goon_joker",
    loc_txt = {
        name = "Goon Joker",
        text = {
            "{C:mult}#2#{} Mult on the {C:attention}Boss Blind{},",
            "{C:mult}+#1#{} Mult otherwise",
        },
    },
    config = { extra = { boss_mult = -5, mult = 20 } },
    rarity = 1, cost = 5, unlocked = true, discovered = false,
    blueprint_compat = true, eternal_compat = true, perishable_compat = true,
    sprite = "goon_joker.png", negative_sprite = "goon_joker_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult, card.ability.extra.boss_mult } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            local boss = false
            if context.port and context.port.is_boss_blind ~= nil then
                boss = context.port.is_boss_blind == true
            elseif G then
                boss = tonumber(G.current_blind_index) == 3
            end
            if boss then
                return { mult = card.ability.extra.boss_mult }
            end
            return { mult = card.ability.extra.mult }
        end
    end,
}

-- JestPack Wave 4, chunk 03 — PORTABLE Jokers (All in Jest → Balatro3DS fork)
-- Fragment only: the integrator assembles the pack file + header.

-- great_kraken: XMult per hand remaining this round.
-- G.GAME.current_round.hands_left -> tonumber(G.hands), the fork's live
-- hands-left readout (the PokermonPack pattern).
SMODS.Joker {
    key = "great_kraken",
    sprite = "great_kraken.png",
    negative_sprite = "great_kraken_negative.png",
    rarity = 3,
    cost = 8,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    config = { extra = { xmult_mod = 1 } },
    loc_txt = {
        name = "Great Kraken",
        text = {
            "{X:mult,C:white}X#1#{} Mult for each",
            "{C:blue}hand{} remaining",
            "{C:inactive}(Will give {X:mult,C:white}X#2#{} {C:inactive}Mult)",
            "{C:inactive}(Minimum {X:mult,C:white}X1{C:inactive} Mult)",
        },
    },
    loc_vars = function(self, info_queue, card)
        local xmult = ((tonumber(G and G.hands) or 0) - 1) * card.ability.extra.xmult_mod
        if xmult < 1 then xmult = 1 end
        return { vars = { card.ability.extra.xmult_mod, xmult } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            local xmult = (tonumber(G and G.hands) or 0) * card.ability.extra.xmult_mod
            if xmult < 1 then xmult = 1 end
            return { xmult = xmult }
        end
    end,
}

-- great_white_north: every scored card gives +Mult.
SMODS.Joker {
    key = "great_white_north",
    sprite = "great_white_north.png",
    negative_sprite = "great_white_north_negative.png",
    rarity = 1,
    cost = 4,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    config = { extra = { mult = 2 } },
    loc_txt = {
        name = "Great White North",
        text = {
            "Played cards give {C:mult}+#1#{} Mult",
            "when {C:attention}scored",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult } }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            return { mult = card.ability.extra.mult }
        end
    end,
}

-- grumpy_gus: +Mult per unused discard this run.
-- G.GAME.unused_discards -> G.discardsUnused, the fork engine's own
-- run-accumulated unused-discard counter (added at each blind defeat,
-- so during play it holds the same total PC's counter holds).
SMODS.Joker {
    key = "grumpy_gus",
    sprite = "grumpy_gus.png",
    negative_sprite = "grumpy_gus_negative.png",
    rarity = 1,
    cost = 4,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    config = { extra = { mult = 1 } },
    loc_txt = {
        name = "Grumpy Gus",
        text = {
            "{C:mult}+#1#{} Mult per unused",
            "{C:red}discard{} this run",
            "{C:inactive}(Currently {C:mult}+#2#{C:inactive} Mult)",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult,
            tonumber(G and G.discardsUnused) or 0 } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            local mult = (tonumber(G and G.discardsUnused) or 0)
                * card.ability.extra.mult
            if mult > 0 then return { mult = mult } end
        end
    end,
}

-- guillaume: gains a Joker slot when a Boss Blind is beaten with
-- fewer than 5 Jokers held. PC's end_of_round + beat_boss check ->
-- the fork's blind_defeated (Boss) seat (the Paperback pattern);
-- G.jokers:change_size -> the dynamic card.ability.joker_slots
-- field over a declarative joker_slots = 0 (the Cryptid pattern).
SMODS.Joker {
    key = "guillaume",
    sprite = "guillaume.png",
    negative_sprite = "guillaume_negative.png",
    soul_sprite = "guillaume_soul.png",
    rarity = 4,
    cost = 20,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = false,
    config = { joker_slots = 0,
        extra = { joker_slots = 0, joker_slots_mod = 1 } },
    loc_txt = {
        name = "Guillaume",
        text = {
            "If {C:attention}Boss Blind{} is",
            "defeated with less than",
            "{C:attention}5{} Jokers, this Joker",
            "gains {C:dark_edition}+#2#{} Joker Slot",
            "{C:inactive}(Currently {C:dark_edition}+#1#{C:inactive} Joker Slots){}",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.joker_slots,
            card.ability.extra.joker_slots_mod } }
    end,
    calculate = function(self, card, context)
        if context.blind_defeated and not context.blueprint then
            local idx = (context.port and context.port.blind_index)
                or (G and G.current_blind_index)
            local held = (G and G.jokers) and #G.jokers or 0
            if tonumber(idx) == 3 and held < 5 then
                card.ability.extra.joker_slots = card.ability.extra.joker_slots
                    + card.ability.extra.joker_slots_mod
                card.ability.joker_slots = card.ability.extra.joker_slots
                return { message = "Upgrade!" }
            end
        end
    end,
}

-- guiser: gains sell value when a Tarot is used.
-- PC grows ability.extra_value and re-prices with set_cost; the fork's
-- sell path reads the Joker's sell_cost field directly (the Cryptid
-- pattern). PC's ability.set == "Tarot" check -> consumable_kind.
SMODS.Joker {
    key = "guiser",
    sprite = "guiser.png",
    negative_sprite = "guiser_negative.png",
    rarity = 3,
    cost = 10,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    config = { extra = { money = 5 } },
    loc_txt = {
        name = "Guiser",
        text = {
            "Gains {C:money}$#1#{} of {C:attention}sell value{}",
            "when a {C:tarot}Tarot{} card is used",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.money } }
    end,
    calculate = function(self, card, context)
        if context.using_consumeable and not context.blueprint
            and context.port
            and context.port.consumable_kind == "tarot" then
            card.sell_cost = (tonumber(card.sell_cost) or 0)
                + card.ability.extra.money
            return { message = "Value Up!" }
        end
    end,
}

-- gummy: flat Chips + Mult.
SMODS.Joker {
    key = "gummy",
    sprite = "gummy.png",
    negative_sprite = "gummy_negative.png",
    rarity = 1,
    cost = 2,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    config = { extra = { chips = 15, mult = 2 } },
    loc_txt = {
        name = "Gummy",
        text = {
            "{C:chips}+#1#{} Chips",
            "{C:mult}+#2#{} Mult",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chips, card.ability.extra.mult } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            return {
                chips = card.ability.extra.chips,
                mult = card.ability.extra.mult,
            }
        end
    end,
}

-- haggler: discarded Gold cards may pay out.
-- SMODS.has_enhancement(m_gold) -> the card view's enhancement string;
-- dollar_buffer boilerplate dropped (the dollars return replaces it).
-- in_pool Gold-in-deck gate dropped (availability nuance).
SMODS.Joker {
    key = "haggler",
    sprite = "haggler.png",
    negative_sprite = "haggler_negative.png",
    rarity = 1,
    cost = 6,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    config = { extra = { odds = 2, dollars = 6 } },
    loc_txt = {
        name = "Haggler",
        text = {
            "{C:attention}Gold Cards{} have a {C:green}#1# in #2#{}",
            "chance to earn {C:money}$#3#{} when",
            "{C:attention}discarded",
        },
    },
    loc_vars = function(self, info_queue, card)
        local numerator, denominator = SMODS.get_probability_vars(
            card, 1, card.ability.extra.odds, "haggler")
        return { vars = { numerator, denominator, card.ability.extra.dollars } }
    end,
    calculate = function(self, card, context)
        if context.discard and context.other_card
            and context.other_card.enhancement == "gold"
            and SMODS.pseudorandom_probability(
                card, "haggler", 1, card.ability.extra.odds) then
            return { dollars = card.ability.extra.dollars }
        end
    end,
}

-- hallucinaut: gains XMult when a Booster Pack is opened, resets
-- when a Boss Blind is defeated. SMODS.scale_card inlined. PC's
-- end_of_round + beat_boss reset -> blind_defeated (Boss).
SMODS.Joker {
    key = "hallucinaut",
    sprite = "hallucinaut.png",
    negative_sprite = "hallucinaut_negative.png",
    rarity = 2,
    cost = 6,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    config = { extra = { xmult = 1, xmult_gain = 0.5 } },
    loc_txt = {
        name = "Hallucinaut",
        text = {
            "This Joker gains {X:mult,C:white}X#1#{} Mult",
            "when a {C:attention}Booster Pack{} is",
            "purchased, {C:attention}resets{} when",
            "{C:attention}Boss Blind{} is defeated",
            "{C:inactive}(Currently {X:mult,C:white}X#2#{}{C:inactive} Mult){}",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.xmult_gain,
            card.ability.extra.xmult } }
    end,
    calculate = function(self, card, context)
        if context.open_booster and not context.blueprint then
            card.ability.extra.xmult = card.ability.extra.xmult
                + card.ability.extra.xmult_gain
            return { message = "Upgrade!" }
        end
        if context.blind_defeated and not context.blueprint then
            local idx = (context.port and context.port.blind_index)
                or (G and G.current_blind_index)
            if tonumber(idx) == 3 and card.ability.extra.xmult > 1 then
                card.ability.extra.xmult = 1
                return { message = "Reset!" }
            end
        end
        if context.joker_main and card.ability.extra.xmult > 1 then
            return { xmult = card.ability.extra.xmult }
        end
    end,
}

-- hat_trick: scored cards in a Three of a Kind give Mult equal to
-- its level. G.GAME.hands[name].level -> G.handlist index +
-- G:get_hand_level_stats (the Bunco pattern).
local function aij3_hat_trick_level()
    if not (G and G.handlist and G.get_hand_level_stats) then return 1 end
    for i, name in ipairs(G.handlist) do
        if name == "Three of a Kind" then
            local level = G:get_hand_level_stats(i)
            return tonumber(level) or 1
        end
    end
    return 1
end

SMODS.Joker {
    key = "hat_trick",
    sprite = "hat_trick.png",
    negative_sprite = "hat_trick_negative.png",
    rarity = 1,
    cost = 4,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    config = { extra = { mod = 1 } },
    loc_txt = {
        name = "Hat Trick",
        text = {
            "If played hand is a",
            "{C:attention}Three of a Kind{},",
            "scored cards give {C:mult}Mult{}",
            "equal to its {C:attention}level",
            "{C:inactive}(Currently {C:mult}+#1#{} {C:inactive}Mult)",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mod * aij3_hat_trick_level() } }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play
            and context.scoring_name == "Three of a Kind" then
            return { mult = aij3_hat_trick_level() * card.ability.extra.mod }
        end
    end,
}

-- haughty_joker: +Chips if the played hand contains a Royal Flush
-- (the Jest PokerHand, registered by the pack's hands fragment).
-- in_pool played-before gate dropped (availability nuance).
SMODS.Joker {
    key = "haughty_joker",
    sprite = "haughty_joker.png",
    negative_sprite = "haughty_joker_negative.png",
    rarity = 1,
    cost = 5,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    config = { extra = { chips = 1000 } },
    loc_txt = {
        name = "Haughty Joker",
        text = {
            "{C:chips}+#1#{} Chips if played hand",
            "contains a {C:attention}Royal Flush",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chips } }
    end,
    calculate = function(self, card, context)
        if context.joker_main and context.poker_hands
            and next(context.poker_hands["aij_Royal Flush"]) then
            return { chips = card.ability.extra.chips }
        end
    end,
}

-- haunted_maze: in a Straight, scored cards give Mult equal to the
-- number of times the played hand has been played this run.
-- G.GAME.hands[name].played -> G.hand_play_counts indexed by
-- G.handlist position (the Jimball pattern).
SMODS.Joker {
    key = "haunted_maze",
    sprite = "haunted_maze.png",
    negative_sprite = "haunted_maze_negative.png",
    rarity = 2,
    cost = 6,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    config = {},
    loc_txt = {
        name = "Haunted Maze",
        text = {
            "If played hand contains a",
            "{C:attention}Straight{}, scoring cards give",
            "{C:mult}Mult{} equal to the number of",
            "times hand has been played",
        },
    },
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play
            and context.poker_hands and next(context.poker_hands["Straight"]) then
            local played = 0
            if G and G.handlist and G.hand_play_counts and context.scoring_name then
                for i, name in ipairs(G.handlist) do
                    if name == context.scoring_name then
                        played = tonumber(G.hand_play_counts[i]) or 0
                        break
                    end
                end
            end
            if played > 0 then return { mult = played } end
        end
    end,
}

-- heavenbrand_credits_joker: credits Joker, never in pool
-- (cosmetic badge drops).
SMODS.Joker {
    key = "heavenbrand_credits_joker",
    sprite = "heavenbrand_credits_joker.png",
    negative_sprite = "heavenbrand_credits_joker_negative.png",
    rarity = 1,
    cost = 4,
    blueprint_compat = false,
    eternal_compat = false,
    perishable_compat = true,
    config = {},
    loc_txt = {
        name = "HEAVENBRAND",
        text = {
            '{C:inactive}"As they say in France,',
            "{C:inactive}'I'll take two.'\"",
        },
    },
    in_pool = function(self, args)
        return false
    end,
}

-- hei_tiki: gains XMult when the hand's final Chips exceed its Mult.
-- PC's hand_chips / mult globals -> context.port totals at
-- final_scoring_step, compared with SMODS.big_cmp (totals may be
-- big numbers). SMODS.scale_card inlined.
SMODS.Joker {
    key = "hei_tiki",
    sprite = "hei_tiki.png",
    negative_sprite = "hei_tiki_negative.png",
    rarity = 3,
    cost = 9,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    config = { extra = { xmult = 0, xmult_mod = 0.1 } },
    loc_txt = {
        name = "Hei-tiki",
        text = {
            "This {C:attention}Joker{} gains {X:mult,C:white}X#2#{} Mult",
            "if played hand's final",
            "{C:chips}Chips{} exceeds {C:mult}Mult{}",
            "{C:inactive}(Currently {X:mult,C:white}X#1#{} {C:inactive}Mult)",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { 1 + card.ability.extra.xmult,
            card.ability.extra.xmult_mod } }
    end,
    calculate = function(self, card, context)
        if context.final_scoring_step and not context.blueprint
            and context.port then
            if SMODS.big_cmp(context.port.chips or 0,
                context.port.mult or 0) == 1 then
                card.ability.extra.xmult = card.ability.extra.xmult
                    + card.ability.extra.xmult_mod
            end
        end
        if context.joker_main then
            return { xmult = 1 + card.ability.extra.xmult }
        end
    end,
}

-- histrio: earn more per unused hand at end of round.
-- PC's G.GAME.modifiers.money_per_hand bump -> calc_dollar_bonus
-- over the fork's live hands-left readout (G.hands).
SMODS.Joker {
    key = "histrio",
    sprite = "histrio.png",
    negative_sprite = "histrio_negative.png",
    rarity = 2,
    cost = 7,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    config = { extra = { money = 2 } },
    loc_txt = {
        name = "Histrio",
        text = {
            "Earn {C:money}$#1#{} more for",
            "each {C:attention}unused hand",
            "at end of round",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.money } }
    end,
    calc_dollar_bonus = function(self, card)
        local bonus = (tonumber(G and G.hands) or 0) * card.ability.extra.money
        if bonus > 0 then return bonus end
    end,
}

-- hofnarr_the_barbarian: +Mult; on Showdown Boss Blinds, disables
-- them and gives XMult instead. PC's blind:disable() ->
-- G:disable_boss_blind() (the Carved Pumpkin pattern: attempt at
-- setting_blind and again at first_hand_drawn; the call is a no-op
-- once disabled). Showdown = the fork's bl_final_* Boss ids.
local aij3_showdown_bosses = {
    bl_final_bell = true, bl_final_leaf = true, bl_final_vessel = true,
    bl_final_heart = true, bl_final_acorn = true,
}
local function aij3_is_showdown()
    if not (G and G.get_active_boss_blind_id) then return false end
    local id = G:get_active_boss_blind_id()
    return id ~= nil and aij3_showdown_bosses[id] == true
end

SMODS.Joker {
    key = "hofnarr_the_barbarian",
    sprite = "hofnarr_the_barbarian.png",
    negative_sprite = "hofnarr_the_barbarian_negative.png",
    rarity = 2,
    cost = 6,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    config = { extra = { mult = 10, xmult = 10 } },
    loc_txt = {
        name = "Hofnarr the Barbarian",
        text = {
            "{C:mult}+#1#{} Mult",
            "On {C:attention}Showdown Boss Blinds{}, {C:attention}disables{}",
            "them and gives {X:mult,C:white}X#2#{} Mult",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult, card.ability.extra.xmult } }
    end,
    calculate = function(self, card, context)
        if (context.setting_blind or context.first_hand_drawn)
            and not context.blueprint and aij3_is_showdown()
            and G and G.disable_boss_blind then
            G:disable_boss_blind()
            return { message = "Boss Disabled!" }
        end
        if context.joker_main then
            if aij3_is_showdown() then
                return {
                    mult = card.ability.extra.mult,
                    xmult = card.ability.extra.xmult,
                }
            end
            return { mult = card.ability.extra.mult }
        end
    end,
}

-- homemade_comic: scored Charged cards give XMult.
-- SMODS.has_enhancement(m_aij_charged) -> the card view's
-- enhancement string (the Jest Charged enhancement, registered by
-- the pack's enhancements fragment). in_pool gate dropped.
SMODS.Joker {
    key = "homemade_comic",
    sprite = "homemade_comic.png",
    negative_sprite = "homemade_comic_negative.png",
    rarity = 2,
    cost = 7,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    config = { xmult = 1.5 },
    loc_txt = {
        name = "Homemade Comic",
        text = {
            "Scored {C:attention}Charged Cards{}",
            "give {X:mult,C:white}X#1#{} Mult",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.xmult } }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play
            and context.other_card
            and context.other_card.enhancement == "aij_charged" then
            return { xmult = card.ability.xmult }
        end
    end,
}

-- honker: gains Mult when a Mult card is scored.
-- SMODS.get_enhancements().m_mult -> the view's enhancement string.
-- SMODS.scale_card inlined. in_pool gate dropped.
SMODS.Joker {
    key = "honker",
    sprite = "honker.png",
    negative_sprite = "honker_negative.png",
    rarity = 1,
    cost = 5,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    config = { extra = { mult_mod = 1, cur_mult = 0 } },
    loc_txt = {
        name = "Honker",
        text = {
            "This Joker gains {C:red}+#1#{} Mult",
            "when a {C:attention}Mult Card{} is scored",
            "{C:inactive}(Currently {C:mult}+#2#{C:inactive} Mult)",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult_mod,
            card.ability.extra.cur_mult } }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play
            and not context.blueprint and context.other_card
            and context.other_card.enhancement == "mult" then
            card.ability.extra.cur_mult = card.ability.extra.cur_mult
                + card.ability.extra.mult_mod
            return { message = "Upgrade!" }
        end
        if context.joker_main and card.ability.extra.cur_mult > 0 then
            return { mult = card.ability.extra.cur_mult }
        end
    end,
}

-- imageboard: each scored card gives Mult per time its rank has
-- already scored this hand; the tally already lives in
-- card.ability on PC and carries over unchanged.
SMODS.Joker {
    key = "imageboard",
    sprite = "imageboard.png",
    negative_sprite = "imageboard_negative.png",
    rarity = 1,
    cost = 4,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    config = { extra = { has_been_played = nil, mod_mult = 1 } },
    loc_txt = {
        name = "Imageboard",
        text = {
            "Each {C:attention}scored{} card gives {C:mult}+#1#{} Mult",
            "for each {C:attention}time{} its {C:attention}rank{}",
            "has {C:attention}scored{} this hand",
            "{C:inactive}(ex. {C:attention}2 2 2{C:inactive} -> {C:mult}+#1#{C:inactive}, {C:mult}+#2#{C:inactive}, {C:mult}+#3#{C:inactive})",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mod_mult,
            card.ability.extra.mod_mult * 2, card.ability.extra.mod_mult * 3 } }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play
            and context.other_card then
            card.ability.extra.has_been_played =
                card.ability.extra.has_been_played or {}
            local compare_id = context.other_card:get_id()
            local tally = card.ability.extra.has_been_played
            tally[compare_id] = (tally[compare_id] or 0)
                + card.ability.extra.mod_mult
            return { mult = tally[compare_id] }
        end
        if context.after then
            card.ability.extra.has_been_played = nil
        end
    end,
}

-- imperious_joker: +Mult if the played hand contains a Royal Flush
-- (the Jest PokerHand, registered by the pack's hands fragment).
-- in_pool played-before gate dropped (availability nuance).
SMODS.Joker {
    key = "imperious_joker",
    sprite = "imperious_joker.png",
    negative_sprite = "imperious_joker_negative.png",
    rarity = 1,
    cost = 5,
    blueprint_compat = false,
    eternal_compat = false,
    perishable_compat = true,
    config = { extra = { mult = 120 } },
    loc_txt = {
        name = "Imperious Joker",
        text = {
            "{C:mult}+#1#{} Mult if played hand",
            "contains a {C:attention}Royal Flush",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult } }
    end,
    calculate = function(self, card, context)
        if context.joker_main and context.poker_hands
            and next(context.poker_hands["aij_Royal Flush"]) then
            return { mult = card.ability.extra.mult }
        end
    end,
}

-- in_vino_veritas: +hand size when a consumable is used (max +5),
-- resets at end of round. PC's G.hand:change_size calls -> the
-- dynamic card.ability.h_size field kept in sync (the Mikas /
-- Pot of Jokes pattern); add/remove_from_deck re-application is
-- the declarative modifier's own job and drops.
SMODS.Joker {
    key = "in_vino_veritas",
    sprite = "in_vino_veritas.png",
    negative_sprite = "in_vino_veritas_negative.png",
    rarity = 2,
    cost = 6,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    config = { h_size = 0, extra = { max_h_size = 5,
        current_h_size = 0, h_size_mod = 1 } },
    loc_txt = {
        name = "In Vino Veritas",
        text = {
            "{C:attention}+#1#{} hand size when a",
            "{C:attention}consumable{} is used, {C:attention}resets",
            "at end of {C:attention}round{}",
            "{C:inactive}(Currently {C:attention}+#2#{C:inactive} Hand Size)",
            "{C:inactive}(Max {C:attention}+#3#{C:inactive} Hand Size)",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.h_size_mod,
            card.ability.extra.current_h_size, card.ability.extra.max_h_size } }
    end,
    calculate = function(self, card, context)
        if context.using_consumeable and not context.blueprint
            and card.ability.extra.current_h_size
                < card.ability.extra.max_h_size then
            card.ability.extra.current_h_size =
                card.ability.extra.current_h_size
                + card.ability.extra.h_size_mod
            card.ability.h_size = card.ability.extra.current_h_size
            return { message = "+" .. card.ability.extra.h_size_mod
                .. " Hand Size" }
        end
        if context.end_of_round and not context.game_over
            and not context.blueprint then
            if card.ability.extra.current_h_size > 0 then
                card.ability.extra.current_h_size = 0
                card.ability.h_size = 0
            end
            return { message = "Reset!" }
        end
    end,
}

-- infamous_machine: after the first draw of each round, destroy
-- the leftmost card in hand and gain Mult. PC's batch
-- SMODS.destroy_cards on that one card -> SMODS.destroy_card on
-- the leftmost hand node. SMODS.scale_card inlined.
SMODS.Joker {
    key = "infamous_machine",
    sprite = "infamous_machine.png",
    negative_sprite = "infamous_machine_negative.png",
    rarity = 3,
    cost = 8,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    config = { extra = { mult_mod = 5, mult = 0 } },
    loc_txt = {
        name = "Infamous Machine",
        text = {
            "After the {C:attention}first draw{} of each",
            "round, {C:red}destroy{} the {C:attention}leftmost",
            "{C:attention}playing card{} and this {C:attention}Joker",
            "gains {C:mult}+#1#{} Mult",
            "{C:inactive}(Currently {C:mult}+#2#{C:inactive} Mult)",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult_mod,
            card.ability.extra.mult } }
    end,
    calculate = function(self, card, context)
        if context.first_hand_drawn and not context.blueprint
            and G and G.hand and G.hand.card_nodes
            and G.hand.card_nodes[1] then
            if SMODS.destroy_card(G.hand.card_nodes[1]) then
                card.ability.extra.mult = card.ability.extra.mult
                    + card.ability.extra.mult_mod
                return { message = "Upgrade!" }
            end
        end
        if context.joker_main and card.ability.extra.mult > 0 then
            return { mult = card.ability.extra.mult }
        end
    end,
}

-- infinite_jest: level up all poker hands when a Boss Blind is
-- defeated. PC's per-hand level_up_hand loop -> the fork's
-- G:upgrade_hand_level_at_index funnel over G.handlist (the
-- Bunco pattern), at blind_defeated (Boss) instead of PC's
-- end_of_round boss check; the Black Hole flourish drops.
SMODS.Joker {
    key = "infinite_jest",
    sprite = "infinite_jest.png",
    negative_sprite = "infinite_jest_negative.png",
    rarity = 3,
    cost = 8,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    config = {},
    loc_txt = {
        name = "Infinite Jest",
        text = {
            "Level up {C:attention}all poker",
            "{C:attention}hands{} when {C:attention}Boss Blind",
            "is defeated",
        },
    },
    calculate = function(self, card, context)
        if context.blind_defeated then
            local idx = (context.port and context.port.blind_index)
                or (G and G.current_blind_index)
            if tonumber(idx) == 3 and G and G.handlist
                and G.upgrade_hand_level_at_index then
                for i = 1, #G.handlist do
                    G:upgrade_hand_level_at_index(i)
                end
                return { message = "Upgrade!" }
            end
        end
    end,
}

-- interstate: +Hands this round if the first hand of the round
-- contains a Straight. PC's ease_hands_played -> writing the
-- fork's live hands-left field directly (the G.discards write
-- pattern); G.GAME.current_round.hands_played == 0 ->
-- G:get_round_hands_played() == 0.
SMODS.Joker {
    key = "interstate",
    sprite = "interstate.png",
    negative_sprite = "interstate_negative.png",
    rarity = 1,
    cost = 4,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    config = { extra = { hands = 2 } },
    loc_txt = {
        name = "Interstate",
        text = {
            "{C:blue}+#1#{} Hands this round if",
            "{C:attention}first{} hand of round",
            "contains a {C:attention}Straight{}",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.hands } }
    end,
    calculate = function(self, card, context)
        if context.before and context.scoring_name and G
            and G.get_round_hands_played
            and G:get_round_hands_played() == 0
            and context.poker_hands
            and next(context.poker_hands["Straight"]) then
            G.hands = (tonumber(G.hands) or 0) + card.ability.extra.hands
            return { message = "+" .. card.ability.extra.hands .. " Hands" }
        end
    end,
}

-- iron: retrigger all scoring cards in a Four of a Kind.
SMODS.Joker {
    key = "iron",
    sprite = "iron.png",
    negative_sprite = "iron_negative.png",
    rarity = 2,
    cost = 6,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    config = {},
    loc_txt = {
        name = "Iron",
        text = {
            "If played hand is {C:attention}Four of a Kind{},",
            "retrigger all scoring cards{}",
        },
    },
    calculate = function(self, card, context)
        if context.repetition and context.cardarea == G.play
            and context.scoring_name == "Four of a Kind" then
            return { repetitions = 1 }
        end
    end,
}

-- jamie_credits_joker: credits Joker, never in pool
-- (cosmetic badge drops).
SMODS.Joker {
    key = "jamie_credits_joker",
    sprite = "jamie_credits_joker.png",
    negative_sprite = "jamie_credits_joker_negative.png",
    rarity = 1,
    cost = 4,
    blueprint_compat = false,
    eternal_compat = false,
    perishable_compat = true,
    config = {},
    loc_txt = {
        name = "Jamie!",
        text = {
            '{C:inactive}"me and nevernamed are very good friends"',
            '{C:inactive}"we kiss on the mouth sometimes"',
        },
    },
    in_pool = function(self, args)
        return false
    end,
}

-- joker_baby: scoring 2s, 3s, 4s and 5s permanently gain Mult.
-- Direct perma_mult writes -> SMODS.set_perma / get_perma.
SMODS.Joker {
    key = "joker_baby",
    sprite = "joker_baby.png",
    negative_sprite = "joker_baby_negative.png",
    rarity = 1,
    cost = 4,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    config = { extra = { mult_mod = 1 } },
    loc_txt = {
        name = "Joker Baby",
        text = {
            "Scoring {C:attention}2s{}, {C:attention}3s{}, {C:attention}4s{}, and {C:attention}5s{}",
            "permanently gain {C:mult}+#1#{} Mult",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult_mod } }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play
            and context.other_card then
            local id = context.other_card:get_id()
            if id == 2 or id == 3 or id == 4 or id == 5 then
                SMODS.set_perma(context.other_card, "perma_mult",
                    (SMODS.get_perma(context.other_card, "perma_mult") or 0)
                    + card.ability.extra.mult_mod)
                return { message = "Upgrade!" }
            end
        end
    end,
}

-- jumbocarrot_credits_joker: credits Joker, never in pool
-- (cosmetic badge drops).
SMODS.Joker {
    key = "jumbocarrot_credits_joker",
    sprite = "jumbocarrot_credits_joker.png",
    negative_sprite = "jumbocarrot_credits_joker_negative.png",
    rarity = 1,
    cost = 4,
    blueprint_compat = false,
    eternal_compat = false,
    perishable_compat = true,
    config = {},
    loc_txt = {
        name = "Jumbocarrot",
        text = {
            '{C:inactive}"Hi Alex"',
        },
    },
    in_pool = function(self, args)
        return false
    end,
}

-- komar: all scored cards gain permanent Chips equal to the base
-- Chip value of all other played cards. PC's base.nominal reads ->
-- the PokermonPack card_chip_value pattern (Stone 50, Ace 11,
-- faces 10, Bonus +30); perma_bonus via SMODS.set_perma.
local function aij3_komar_chip_value(view)
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
    return base
end

SMODS.Joker {
    key = "komar",
    sprite = "komar.png",
    negative_sprite = "komar_negative.png",
    soul_sprite = "komar_soul.png",
    rarity = 4,
    cost = 20,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    config = {},
    loc_txt = {
        name = "Komar",
        text = {
            "All {C:attention}scored{} cards gain {C:chips}Chips",
            "equal to the base {C:chips}Chip value{}",
            "of all {C:attention}other{} played cards",
        },
    },
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play
            and context.other_card and context.scoring_hand then
            local added_chips = 0
            for _, other in ipairs(context.scoring_hand) do
                if other ~= context.other_card then
                    added_chips = added_chips + aij3_komar_chip_value(other)
                end
            end
            SMODS.set_perma(context.other_card, "perma_bonus",
                (SMODS.get_perma(context.other_card, "perma_bonus") or 0)
                + added_chips)
            if added_chips > 0 then
                return { message = "Upgrade!" }
            end
        end
    end,
}

-- krampus: scored Gold cards turn to Stone; Stone cards pay when
-- scored. PC's set_ability(m_stone) -> the node setter
-- set_enhancement("stone"); has_enhancement -> view strings.
SMODS.Joker {
    key = "krampus",
    sprite = "krampus.png",
    negative_sprite = "krampus_negative.png",
    rarity = 2,
    cost = 7,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    config = { extra = { dollars = 5 } },
    loc_txt = {
        name = "Krampus",
        text = {
            "Scored {C:attention}Gold Cards{}",
            "turn into {C:attention}Stone Cards{}",
            "{C:attention}Stone Cards{} earn",
            "{C:money}$#1#{} when scored",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.dollars } }
    end,
    calculate = function(self, card, context)
        if context.before and not context.blueprint
            and context.scoring_hand then
            local enhanced_a_card = false
            for _, v in ipairs(context.scoring_hand) do
                if v.enhancement == "gold" and not v.debuff
                    and v.set_enhancement then
                    v:set_enhancement("stone")
                    enhanced_a_card = true
                end
            end
            if enhanced_a_card then
                return { message = "Stone" }
            end
        end
        if context.individual and context.cardarea == G.play
            and context.other_card
            and context.other_card.enhancement == "stone" then
            return { dollars = card.ability.extra.dollars }
        end
    end,
}

-- la_commedia_e_finita: gains Mult when a face card is destroyed.
-- PC's remove_playing_cards / cards_destroyed payloads -> the
-- fork's remove_playing_cards seat, destroyed cards in
-- context.port.destroyed_cards (face = rank 11-13).
-- SMODS.scale_card inlined.
SMODS.Joker {
    key = "la_commedia_e_finita",
    sprite = "la_commedia_e_finita.png",
    negative_sprite = "la_commedia_e_finita_negative.png",
    rarity = 1,
    cost = 4,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    config = { extra = { mult = 0, mult_gain = 5 } },
    loc_txt = {
        name = "La Commedia è Finita",
        text = {
            "This Joker gains {C:mult}+#1#{} Mult",
            "when a {C:attention}face{} card is {C:attention}destroyed",
            "{C:inactive}(Currently {C:mult}+#2#{C:inactive} Mult)",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult_gain,
            card.ability.extra.mult } }
    end,
    calculate = function(self, card, context)
        if context.remove_playing_cards and not context.blueprint then
            local destroyed = (context.port and context.port.destroyed_cards)
                or {}
            local face_cards = 0
            for _, val in ipairs(destroyed) do
                local rank = tonumber(val.rank)
                    or (val.get_id and val:get_id()) or 0
                if rank >= 11 and rank <= 13 then
                    face_cards = face_cards + 1
                end
            end
            if face_cards > 0 then
                card.ability.extra.mult = card.ability.extra.mult
                    + face_cards * card.ability.extra.mult_gain
                return { message = "Upgrade!" }
            end
        end
        if context.joker_main and card.ability.extra.mult > 0 then
            return { mult = card.ability.extra.mult }
        end
    end,
}

-- laurel: XMult per enhanced card in the full deck, read live
-- with G:count_cards_in_full_deck.
SMODS.Joker {
    key = "laurel",
    sprite = "laurel.png",
    negative_sprite = "laurel_negative.png",
    soul_sprite = "laurel_soul.png",
    rarity = 4,
    cost = 20,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    config = { extra = { xmult = 1, xmult_mod = 0.25 } },
    loc_txt = {
        name = "Laurel",
        text = {
            "Gains {X:mult,C:white}X#1#{} Mult per {C:attention}enhanced{}",
            "card in your {C:attention}full deck",
            "{C:inactive}(Currently{} {X:mult,C:white}X#2#{} {C:inactive}Mult){}",
        },
    },
    loc_vars = function(self, info_queue, card)
        local count = 0
        if G and G.count_cards_in_full_deck then
            count = G:count_cards_in_full_deck(function(data)
                return data.enhancement ~= nil
            end)
        end
        return { vars = { card.ability.extra.xmult_mod,
            1 + (count * card.ability.extra.xmult_mod) } }
    end,
    calculate = function(self, card, context)
        if context.joker_main and G and G.count_cards_in_full_deck then
            local count = G:count_cards_in_full_deck(function(data)
                return data.enhancement ~= nil
            end)
            local xmult = 1 + (count * card.ability.extra.xmult_mod)
            if xmult > 1 then return { xmult = xmult } end
        end
    end,
}

-- lead: retrigger all scoring cards in a Straight.
SMODS.Joker {
    key = "lead",
    sprite = "lead.png",
    negative_sprite = "lead_negative.png",
    rarity = 2,
    cost = 7,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    config = {},
    loc_txt = {
        name = "Lead",
        text = {
            "If played hand is {C:attention}Straight{},",
            "retrigger all scoring cards{}",
        },
    },
    calculate = function(self, card, context)
        if context.repetition and context.cardarea == G.play
            and context.scoring_name == "Straight" then
            return { repetitions = 1 }
        end
    end,
}

-- legerdemain: +Discards this round when a Joker is sold during
-- a Blind. PC's ease_discard -> writing G.discards directly (the
-- Meeple pattern). PC's SELECTING_HAND gate drops: G.discards is
-- reset when a Blind is selected, so a shop sale cannot leak
-- discards into a round.
SMODS.Joker {
    key = "legerdemain",
    sprite = "legerdemain.png",
    negative_sprite = "legerdemain_negative.png",
    rarity = 2,
    cost = 6,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    config = { extra = { discards = 2 } },
    loc_txt = {
        name = "Legerdemain",
        text = {
            "{C:red}+#1# Discards{} this round",
            "when a {C:attention}Joker{} is {C:money}sold",
            "during a {C:attention}Blind{}",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.discards } }
    end,
    calculate = function(self, card, context)
        if context.selling_card and context.card and G then
            G.discards = (tonumber(G.discards) or 0)
                + card.ability.extra.discards
            return { message = "+" .. card.ability.extra.discards
                .. " Discards" }
        end
    end,
}

-- happy_as_larry: XMult, and a decaying chance to retrigger
-- itself. PC's probability loop carries over on the fork's
-- SMODS.pseudorandom_probability (hit only; the loop is the
-- effect); PC's G.SEED seed suffix drops.
SMODS.Joker {
    key = "happy_as_larry",
    sprite = "happy_as_larry.png",
    negative_sprite = "happy_as_larry_negative.png",
    rarity = 2,
    cost = 6,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    config = { extra = { xmult = 0.25, odds = 5, new_odds = 5,
        decrease_odds = 1 } },
    loc_txt = {
        name = "Happy as Larry",
        text = {
            "{X:mult,C:white}X#1#{} Mult",
            "{C:green}#2# in #3#{} chance to {C:attention}retrigger{},",
            "{C:attention}Chance{} decreases by {C:green}#4#{} on",
            "each subsequent {C:attention}retrigger",
        },
    },
    loc_vars = function(self, info_queue, card)
        local numerator, denominator = SMODS.get_probability_vars(
            card, card.ability.extra.new_odds, card.ability.extra.odds)
        return { vars = { card.ability.extra.xmult + 1, numerator,
            denominator, card.ability.extra.decrease_odds } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            local mult = card.ability.extra.xmult + 1
            if mult > 1 then return { xmult = mult } end
        end
        if context.retrigger_joker_check and context.other_card == card then
            local retriggers = 0
            while card.ability.extra.new_odds > 0
                and SMODS.pseudorandom_probability(card, "happy_as_larry",
                    card.ability.extra.new_odds, card.ability.extra.odds) do
                card.ability.extra.new_odds = card.ability.extra.new_odds - 1
                retriggers = retriggers + 1
            end
            if retriggers > 0 then
                card.ability.extra.new_odds = card.ability.extra.odds
                return { repetitions = retriggers, message = "Again!" }
            end
        end
        if context.after then
            card.ability.extra.new_odds = card.ability.extra.odds
        end
    end,
}

-- jerko: +Mult, and retriggers itself a random 0-20 times.
-- PC's DynaText main_end tooltip UI has no fork seat and drops;
-- the roll is SMODS.pseudorandom over the PC min/max range (the
-- Weather Radio pattern).
SMODS.Joker {
    key = "jerko",
    sprite = "jerko.png",
    negative_sprite = "jerko_negative.png",
    rarity = 3,
    cost = 8,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    config = { extra = { mult = 4, min = 0, max = 20 } },
    loc_txt = {
        name = "Jerko",
        text = {
            "{C:mult}+#1#{} Mult",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult } }
    end,
    calculate = function(self, card, context)
        if context.retrigger_joker_check and context.other_card == card then
            local retriggers = SMODS.pseudorandom("jerko",
                card.ability.extra.min, card.ability.extra.max)
            if retriggers and retriggers > 0 then
                return { repetitions = retriggers, message = "Again!" }
            end
        end
        if context.joker_main then
            return { mult = card.ability.extra.mult }
        end
    end,
}

-- jpeg: if the first hand of the round has no repeating suits,
-- apply Wild to all scoring unenhanced cards. PC's set_ability
-- (m_wild) -> set_enhancement("wild"); the unenhanced check reads
-- the view's enhancement string. hands_played == 0 ->
-- G:get_round_hands_played() == 0.
SMODS.Joker {
    key = "jpeg",
    sprite = "jpeg.png",
    negative_sprite = "jpeg_negative.png",
    rarity = 2,
    cost = 7,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    config = {},
    loc_txt = {
        name = ".jpeg",
        text = {
            "If {C:attention}first hand{} of round ",
            "contains {C:attention}no{} repeating {C:attention}suits{}, ",
            "apply {C:attention}Wild{} to all scoring",
            "{C:attention}unenhanced{} cards",
        },
    },
    calculate = function(self, card, context)
        if context.before and not context.blueprint and G
            and G.get_round_hands_played
            and G:get_round_hands_played() == 0
            and context.full_hand and context.scoring_hand then
            local suits = {}
            for _, v in ipairs(context.full_hand) do
                local suit = v.base and v.base.suit
                if suit then
                    if suits[suit] then return end
                    suits[suit] = true
                end
            end
            local triggered = false
            for _, v in ipairs(context.scoring_hand) do
                if (v.enhancement == nil or v.enhancement == "base")
                    and v.set_enhancement then
                    v:set_enhancement("wild")
                    triggered = true
                end
            end
            if triggered then
                return { message = "Wild Card!" }
            end
        end
    end,
}

-- jeff_the_joker: when Small Blind is selected, destroy all
-- other Jokers and gain XMult per Joker destroyed. PC's batch
-- SMODS.destroy_cards -> SMODS.destroy_joker one at a time (the
-- fork's destroy forces past Eternal, where PC spares Eternal
-- Jokers). Blind identity via context.port.blind_name.
-- SMODS.scale_card inlined.
SMODS.Joker {
    key = "jeff_the_joker",
    sprite = "jeff_the_joker.png",
    negative_sprite = "jeff_the_joker_negative.png",
    rarity = 2,
    cost = 6,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    config = { extra = { x_mult = 1, x_mult_per_destroy = 0.5 } },
    loc_txt = {
        name = "Jeff the Joker",
        text = {
            "When {C:attention}Small Blind{} is selected,",
            "{C:red}destroy{} all other Jokers and",
            "this Joker gains {X:mult,C:white}X#2#{} Mult for each",
            "{C:inactive}(Currently {X:mult,C:white}X#1#{C:inactive})",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.x_mult or 1,
            card.ability.extra.x_mult_per_destroy } }
    end,
    calculate = function(self, card, context)
        if context.setting_blind and not context.blueprint
            and context.port and context.port.blind_name == "Small Blind"
            and G and G.jokers then
            local held = G.jokers.cards or G.jokers
            local to_destroy = {}
            for _, v in ipairs(held) do
                if v ~= card and v.def
                    and v.def.id ~= "j_aij_jeff_the_joker" then
                    to_destroy[#to_destroy + 1] = v
                end
            end
            local destroyed = 0
            for _, v in ipairs(to_destroy) do
                if SMODS.destroy_joker(v) then
                    destroyed = destroyed + 1
                end
            end
            if destroyed > 0 then
                card.ability.extra.x_mult = card.ability.extra.x_mult
                    + destroyed * card.ability.extra.x_mult_per_destroy
                return { message = "Upgrade!" }
            end
        end
        if context.joker_main and card.ability.extra.x_mult
            and card.ability.extra.x_mult > 1 then
            return { xmult = card.ability.extra.x_mult }
        end
    end,
}

-- jackpot: stored payout grows when a Lucky card successfully
-- triggers. PC's other_card.lucky_trigger flag at individual ->
-- the fork's probability_success seat (identifiers lucky_mult /
-- lucky_money; it fires once per successful roll, so a card
-- hitting both Lucky rolls counts twice where PC counts once).
SMODS.Joker {
    key = "jackpot",
    sprite = "jackpot.png",
    negative_sprite = "jackpot_negative.png",
    rarity = 2,
    cost = 7,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = false,
    config = { extra = { dollars = 0, gain = 1 } },
    loc_txt = {
        name = "Jackpot",
        text = {
            "Earn {C:money}$#1#{} at end of round,",
            "increases by {C:money}$#2#{} when a {C:attention}Lucky",
            "{C:attention}Card{} successfully triggers",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.dollars,
            card.ability.extra.gain } }
    end,
    calculate = function(self, card, context)
        if context.probability_success and not context.blueprint
            and (context.identifier == "lucky_mult"
                or context.identifier == "lucky_money") then
            card.ability.extra.dollars = card.ability.extra.dollars
                + card.ability.extra.gain
            return { message = "Upgrade!" }
        end
    end,
    calc_dollar_bonus = function(self, card)
        if card.ability.extra.dollars > 0 then
            return card.ability.extra.dollars
        end
    end,
}

-- le_fils_de_banane: scored face cards give Mult, but may destroy
-- themselves after scoring. PC's batch SMODS.destroy_cards ->
-- SMODS.destroy_card one at a time; PC's blind debuff_hand guard
-- drops (no fork seat).
SMODS.Joker {
    key = "le_fils_de_banane",
    sprite = "le_fils_de_banane.png",
    negative_sprite = "le_fils_de_banane_negative.png",
    rarity = 2,
    cost = 6,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    config = { extra = { mult = 15, odds = 6 } },
    loc_txt = {
        name = "Le fils de Banane",
        text = {
            "Scored {C:attention}face{} cards give {C:mult}+#3#",
            "Mult, but have a {C:green}#1# in #2#{}",
            "chance to {C:red}destroy{} themselves",
        },
    },
    loc_vars = function(self, info_queue, card)
        local numerator, denominator = SMODS.get_probability_vars(
            card, 1, card.ability.extra.odds)
        return { vars = { numerator, denominator, card.ability.extra.mult } }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play
            and context.other_card and context.other_card:is_face() then
            return { mult = card.ability.extra.mult }
        end
        if context.after and not context.blueprint
            and context.scoring_hand then
            local destroyed_any = false
            for _, v in ipairs(context.scoring_hand) do
                if v:is_face()
                    and SMODS.pseudorandom_probability(
                        card, "le_fils_de_banane", 1,
                        card.ability.extra.odds) then
                    if SMODS.destroy_card(v) then
                        destroyed_any = true
                    end
                end
            end
            if destroyed_any then
                return { message = "Extinct!" }
            end
        end
    end,
}

-- joka_lisa: XMult per hand size above 7. PC's
-- G.hand.config.card_limit -> G:get_effective_hand_size_limit()
-- (the MoreFluff pattern).
SMODS.Joker {
    key = "joka_lisa",
    sprite = "joka_lisa.png",
    negative_sprite = "joka_lisa_negative.png",
    rarity = 3,
    cost = 8,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    config = { extra = { xmult_mod = 1 } },
    loc_txt = {
        name = "Joka Lisa",
        text = {
            "{X:mult,C:white}X#1#{} Mult per {C:attention}hand",
            "{C:attention}size{} above {C:attention}7{}",
            "{C:inactive}(Currently {X:mult,C:white}X#2#{C:inactive} Mult){}",
        },
    },
    loc_vars = function(self, info_queue, card)
        local xmult = 1
        if G and G.get_effective_hand_size_limit then
            xmult = (G:get_effective_hand_size_limit() - 7)
                * card.ability.extra.xmult_mod
        end
        if xmult < 1 then xmult = 1 end
        return { vars = { card.ability.extra.xmult_mod, xmult } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            local xmult = 1
            if G and G.get_effective_hand_size_limit then
                xmult = (G:get_effective_hand_size_limit() - 7)
                    * card.ability.extra.xmult_mod
            end
            if xmult < 1 then xmult = 1 end
            if xmult > 1 then return { xmult = xmult } end
        end
    end,
}

-- JestPack Wave 4 chunk 04: PORTABLE Jokers (lemarchand_cube .. pangram slice).
-- Ported per .jobs/wave4/CONVENTIONS.md against the Balatro3DS fork.
-- Helpers shared by this fragment:

local function jest4_hand_index(name)
    if not (G and G.handlist) then return nil end
    for i, n in ipairs(G.handlist) do
        if n == name then return i end
    end
    return nil
end

local function jest4_hand_level(name)
    local i = jest4_hand_index(name)
    if i and G and G.get_hand_level_stats then
        local lvl = G:get_hand_level_stats(i)
        return tonumber(lvl) or 1
    end
    return 1
end

local function jest4_hand_stats(name)
    local i = jest4_hand_index(name)
    if i and G and G.get_hand_level_stats then
        local _, c, m = G:get_hand_level_stats(i)
        return tonumber(c) or 0, tonumber(m) or 0
    end
    return 0, 0
end

local function jest4_distinct_enhancements()
    local seen = {}
    if G and G.count_cards_in_full_deck then
        G:count_cards_in_full_deck(function(d)
            if d.enhancement then seen[d.enhancement] = true end
            return false
        end)
    end
    local n = 0
    for _ in pairs(seen) do n = n + 1 end
    return n
end

local function jest4_set_enhancement(view, value)
    if type(view) ~= "table" then return end
    if view.set_enhancement then
        view:set_enhancement(value)
    elseif view.card_data then
        view.card_data.enhancement = value
    end
end

-- PC poll_edition as a table draw (MikasPack precedent): foil and holo
-- common, polychrome rarer, negative rarest when allowed.
local function jest4_roll_edition(seed, allow_negative)
    local pool = { "foil", "foil", "holo", "holo", "polychrome" }
    if allow_negative then pool[#pool + 1] = "negative" end
    return SMODS.pseudorandom_element(pool, seed)
end

local function jest4_create_random_joker(rarity, seed)
    if not (G and G.random_joker_def_id_by_rarity) then return nil end
    local id = G:random_joker_def_id_by_rarity(rarity, seed)
    if not id then return nil end
    return SMODS.add_card { set = "Joker", key = id }
end

local function jest4_empty_joker_slots()
    if not (G and G.jokers) then return 0 end
    local cap = (G.joker_base_capacity and G:joker_base_capacity()) or 5
    local neg = 0
    for _, j in ipairs(G.jokers) do
        if j.edition == "negative" then neg = neg + 1 end
    end
    return math.max(0, cap + neg - #G.jokers)
end

local function jest4_is_boss(context)
    if context and context.port and context.port.is_boss_blind ~= nil then
        return context.port.is_boss_blind == true
    end
    return G and G.current_blind_index == 2
end

--------------------------------------------------------------------------------
-- LeMarchand Cube: create a random Spectral every 5 Tarots used.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "lemarchand_cube",
    loc_txt = {
        name = "LeMarchand Cube",
        text = {
            "Create a random {C:spectral}Spectral{} card",
            "every {C:attention}#2#{} {C:tarot}Tarot{} cards used",
            "{C:inactive}(Must have room){}",
            "{C:inactive}({C:attention}#1#{C:inactive}/{C:attention}#2#{C:inactive})",
        },
    },
    config = { extra = { tarots_used = 0, tarots_total = 5 } },
    rarity = 2,
    cost = 7,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "lemarchand_cube.png",
    negative_sprite = "lemarchand_cube_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.tarots_used, card.ability.extra.tarots_total } }
    end,
    calculate = function(self, card, context)
        if context.using_consumeable and context.port
            and context.port.consumable_kind == "tarot" then
            if not context.blueprint then
                card.ability.extra.tarots_used = card.ability.extra.tarots_used + 1
            end
            if card.ability.extra.tarots_used >= card.ability.extra.tarots_total then
                card.ability.extra.tarots_used = 0
                if SMODS.add_card { set = "Spectral" } then
                    return { message = "+Spectral" }
                end
            elseif not context.blueprint then
                return {
                    message = card.ability.extra.tarots_used .. "/" .. card.ability.extra.tarots_total,
                }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Little Boy Blue: +100 Chips. (The "Only Chip Jokers appear" line is
-- big_red.lua's SMODS.add_to_pool hook on PC, not this def; see census.)
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "little_boy_blue",
    loc_txt = {
        name = "Little Boy Blue",
        text = {
            "{C:chips}+#1#{} Chips",
            "Only {C:chips}Chip{} Jokers appear",
        },
    },
    config = { extra = { chips = 100 } },
    rarity = 1,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "little_boy_blue.png",
    negative_sprite = "little_boy_blue_negative.png",
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
-- Little Devil: skipping a Blind creates a random pack Tag.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "little_devil",
    loc_txt = {
        name = "Little Devil",
        text = {
            "When {C:attention}skipping{} a {C:attention}Blind{},",
            "create a {C:attention}Standard{}, {C:tarot}Charm{},",
            "{C:planet}Meteor{}, {C:spectral}Ethereal{}, or",
            "{C:red}Buffoon {C:attention}Tag{}",
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
    sprite = "little_devil.png",
    negative_sprite = "little_devil_negative.png",
    calculate = function(self, card, context)
        if context.skip_blind then
            local types = { "standard", "charm", "meteor", "buffoon", "ethereal" }
            local chosen = pseudorandom_element(types, "little_devil_tag")
            if chosen and G and G.addTag then G:addTag(chosen) end
            return { message = "+Tag" }
        end
    end,
}

--------------------------------------------------------------------------------
-- Lonely Night: retrigger all cards while a Joker slot is empty.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "lonely_night",
    loc_txt = {
        name = "Lonely Night",
        text = {
            "{C:attention}Retrigger{} all cards if",
            "at least one Joker Slot",
            "is {C:attention}empty",
        },
    },
    config = { extra = {} },
    rarity = 2,
    cost = 7,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "lonely_night.png",
    negative_sprite = "lonely_night_negative.png",
    calculate = function(self, card, context)
        if context.repetition then
            if G and G.joker_has_room_for_new and G:joker_has_room_for_new("base") then
                return { repetitions = 1 }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Low Priest: X3 Mult, -X0.2 Mult per level of the played hand.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "low_priest",
    loc_txt = {
        name = "Low Priest",
        text = {
            "{X:mult,C:white}X#1#{} Mult,",
            "{X:mult,C:white}-X#2#{} Mult per {C:attention}level{}",
            "of played hand",
        },
    },
    config = { extra = { xmult = 1, initial_xmult = 3, xmult_mod = 0.2 } },
    rarity = 2,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "low_priest.png",
    negative_sprite = "low_priest_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.initial_xmult, card.ability.extra.xmult_mod } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            local lvl = jest4_hand_level(context.scoring_name)
            card.ability.extra.xmult = card.ability.extra.initial_xmult
                - card.ability.extra.xmult_mod * lvl
            return { xmult = math.max(1, card.ability.extra.xmult) }
        end
    end,
}

--------------------------------------------------------------------------------
-- Lucignolo: earn $5 when any playing card is destroyed.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "lucignolo",
    loc_txt = {
        name = "Lucignolo",
        text = {
            "Earn {C:money}$#1#{} when any",
            "playing card is {C:attention}destroyed{}",
        },
    },
    config = { extra = { dollars = 5 } },
    rarity = 1,
    cost = 5,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "lucignolo.png",
    negative_sprite = "lucignolo_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.dollars } }
    end,
    calculate = function(self, card, context)
        if context.remove_playing_cards and context.port
            and context.port.destroyed_cards and #context.port.destroyed_cards > 0 then
            local money_to_earn = #context.port.destroyed_cards * card.ability.extra.dollars
            if money_to_earn > 0 then
                return { dollars = money_to_earn }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Reveling Jester (lucina): on Blind select, destroy the Joker to the
-- left and give the Joker to the right a random edition (PC poll_edition
-- as a table draw + direct .edition write, MikasPack / Cotton Candy
-- precedents; eternal guard read off the held Joker's .eternal flag).
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "lucina",
    loc_txt = {
        name = "Reveling Jester",
        text = {
            "When Blind is {C:attention}selected{},",
            "{C:red}destroy{} Joker to the {C:attention}left",
            "and apply a random {C:dark_edition}Edition",
            "to the Joker to the {C:attention}right",
        },
    },
    config = { extra = {} },
    rarity = 3,
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "lucina.png",
    negative_sprite = "lucina_negative.png",
    calculate = function(self, card, context)
        if context.setting_blind and not context.blueprint then
            local jokers = (G and G.jokers) or {}
            local my_pos = nil
            for i, j in ipairs(jokers) do
                if j == card then my_pos = i break end
            end
            if my_pos and jokers[my_pos - 1] and not jokers[my_pos - 1].eternal then
                local left = jokers[my_pos - 1]
                local right = jokers[my_pos + 1]
                if right then
                    right.edition = jest4_roll_edition("lucina", true)
                    if G and G.refresh_joker_capacity_from_negatives then
                        G:refresh_joker_capacity_from_negatives()
                    end
                end
                if SMODS.destroy_joker then SMODS.destroy_joker(left) end
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Lucky Horseshoe: Lucky cards held in hand have two chance rolls.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "lucky_horseshoe",
    loc_txt = {
        name = "Lucky Horseshoe",
        text = {
            "{C:attention}Lucky Cards{} held in hand",
            "have a {C:green}#1# in #3#{} chance to",
            "earn {C:money}$#5#{} and a {C:green}#1# in #4#{}",
            "chance for {X:mult,C:white}X#6#{} Mult",
        },
    },
    config = { extra = { dollars = 3, xmult = 1.5, odds_money = 2, odds_mult = 3 } },
    rarity = 2,
    cost = 7,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "lucky_horseshoe.png",
    negative_sprite = "lucky_horseshoe_negative.png",
    loc_vars = function(self, info_queue, card)
        local numerator1, denominator1 =
            SMODS.get_probability_vars(card, 1, card.ability.extra.odds_money, "lucky_horseshoe")
        return {
            vars = {
                numerator1,
                denominator1,
                card.ability.extra.odds_money,
                card.ability.extra.odds_mult,
                card.ability.extra.dollars,
                card.ability.extra.xmult,
            },
        }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.hand
            and context.other_card and context.other_card.enhancement == "lucky"
            and not context.end_of_round then
            local ret = {}
            if SMODS.pseudorandom_probability(card, "horseshoe_money", 1,
                card.ability.extra.odds_money, "lucky_horseshoe") then
                ret.dollars = card.ability.extra.dollars
            end
            if SMODS.pseudorandom_probability(card, "horseshoe_mult", 1,
                card.ability.extra.odds_mult, "lucky_horseshoe") then
                ret.xmult = card.ability.extra.xmult
            end
            if next(ret) then return ret end
        end
    end,
}

--------------------------------------------------------------------------------
-- Lucky Seven: turn all scored unenhanced 7s into Lucky Cards.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "lucky_seven",
    loc_txt = {
        name = "Lucky Seven",
        text = {
            "Turn all scored",
            "unenhanced {C:attention}7s{} into",
            "{C:attention}Lucky Cards{}",
        },
    },
    config = { extra = {} },
    rarity = 2,
    cost = 7,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "lucky_seven.png",
    negative_sprite = "lucky_seven_negative.png",
    calculate = function(self, card, context)
        if context.before and not context.blueprint then
            local enhanced_a_card = false
            for _, v in ipairs(context.scoring_hand or {}) do
                if v:get_id() == 7 and not v.debuff
                    and (v.enhancement == nil or v.enhancement == "base") then
                    jest4_set_enhancement(v, "lucky")
                    enhanced_a_card = true
                end
            end
            if enhanced_a_card then
                return { message = "Lucky!" }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Maguelonne: when Blind is defeated, destroy a random Face card
-- remaining in the deck and gain X0.25 Mult.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "maguelonne",
    loc_txt = {
        name = "Maguelonne",
        text = {
            "When Blind is {C:attention}defeated{},",
            "{C:red}destroy{} a random {C:attention}Face",
            "{C:attention}Card{} remaining in your",
            "deck and gain {X:mult,C:white}X#1#{} Mult",
            "{C:inactive}(Currently {X:mult,C:white}X#2#{} {C:inactive}Mult){}",
        },
    },
    config = { extra = { xmult = 1, xmult_gain = 0.25 } },
    rarity = 3,
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    sprite = "maguelonne.png",
    negative_sprite = "maguelonne_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.xmult_gain, card.ability.extra.xmult } }
    end,
    calculate = function(self, card, context)
        if context.end_of_round and not context.blueprint then
            local face_cards = {}
            for _, d in ipairs((G and G.deck and G.deck.cards) or {}) do
                if d.rank and d.rank >= 11 and d.rank <= 13 then
                    face_cards[#face_cards + 1] = d
                end
            end
            if #face_cards > 0 then
                local destroyed_card = pseudorandom_element(face_cards, "maguelonne")
                card.ability.extra.xmult = card.ability.extra.xmult
                    + card.ability.extra.xmult_gain
                if destroyed_card and SMODS.destroy_card then
                    SMODS.destroy_card(destroyed_card)
                end
                return { message = localize("k_upgrade_ex") }
            end
        end
        if context.joker_main then
            return { xmult = card.ability.extra.xmult }
        end
    end,
}

--------------------------------------------------------------------------------
-- Mandrake: after 2 rounds, sell this Joker to destroy all cards
-- held in hand. (PC's SMODS.destroy_cards batch becomes a
-- one-at-a-time SMODS.destroy_card loop, per the fork's rules.)
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "mandrake",
    loc_txt = {
        name = "Mandrake",
        text = {
            "After {C:attention}#2#{} rounds, {C:money}sell",
            "this Joker to {C:red}destroy{}",
            "all cards {C:attention}held in hand",
            "{C:inactive}(Currently {C:attention}#1#{C:inactive}/#2#)",
        },
    },
    config = { extra = { rounds = 0, total_rounds = 2 } },
    rarity = 2,
    cost = 5,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = false,
    perishable_compat = true,
    sprite = "mandrake.png",
    negative_sprite = "mandrake_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.rounds, card.ability.extra.total_rounds } }
    end,
    calculate = function(self, card, context)
        if context.selling_self
            and card.ability.extra.rounds >= card.ability.extra.total_rounds
            and not context.blueprint then
            local targets = {}
            for _, node in ipairs((G and G.hand and G.hand.card_nodes) or {}) do
                targets[#targets + 1] = node
            end
            for _, node in ipairs(targets) do
                if SMODS.destroy_card then SMODS.destroy_card(node) end
            end
        end
        if context.end_of_round and not context.game_over and not context.blueprint then
            card.ability.extra.rounds = card.ability.extra.rounds + 1
            return {
                message = (card.ability.extra.rounds < card.ability.extra.total_rounds)
                    and (card.ability.extra.rounds .. "/" .. card.ability.extra.total_rounds)
                    or "Active!",
            }
        end
    end,
}

--------------------------------------------------------------------------------
-- Marcy (credits Joker): no calculate, never in pool. The creator
-- badge drops (no fork seat), exactly as the audit's credits pattern.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "marcy_credits_joker",
    loc_txt = {
        name = "Marcy",
        text = { "Skibby Dee" },
    },
    config = { extra = {} },
    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = false,
    perishable_compat = true,
    sprite = "marcy_credits_joker.png",
    negative_sprite = "marcy_credits_joker_negative.png",
    calculate = function(self, card, context) end,
    in_pool = function(self, args) return false end,
}

--------------------------------------------------------------------------------
-- Mariachi: +4 Mult per unique enhancement in your full deck.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "mariachi",
    loc_txt = {
        name = "Mariachi",
        text = {
            "{C:mult}+#1#{} Mult per {C:attention}unique{}",
            "{C:attention}enhancement{} in your",
            "{C:attention}full deck",
            "{C:inactive}(Currently {C:mult}+#2#{C:inactive} Mult)",
        },
    },
    config = { extra = { mult = 4 } },
    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "mariachi.png",
    negative_sprite = "mariachi_negative.png",
    loc_vars = function(self, info_queue, card)
        local count = jest4_distinct_enhancements()
        return { vars = { card.ability.extra.mult, count * card.ability.extra.mult } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            local count = jest4_distinct_enhancements()
            if count > 0 then
                return { mult = count * card.ability.extra.mult }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Master of Pegs: gains X0.25 Mult per enhanced card in full deck,
-- only triggers if no enhanced cards remain in the deck pile.
-- (Query-time tallies ride the fork's count_cards_in_full_deck /
-- count_cards_in_deck live reads; PC in_pool gate dropped, see census.)
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "master_of_pegs",
    loc_txt = {
        name = "Master of Pegs",
        text = {
            "Gains {X:mult,C:white}X#1#{} Mult per {C:attention}enhanced{}",
            "card in {C:attention}full deck{}, only triggers if {C:attention}no",
            "{C:attention}enhanced{} cards are in {C:attention}remaining deck{}",
            "{C:inactive}(Currently {X:mult,C:white}X#2#{C:inactive} Mult)",
            "{C:inactive}#3#",
        },
    },
    config = { extra = { xmult = 1, xmult_gain = 0.25 } },
    rarity = 2,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "master_of_pegs.png",
    negative_sprite = "master_of_pegs_negative.png",
    loc_vars = function(self, info_queue, card)
        local full, remaining = 0, 0
        if G and G.count_cards_in_full_deck then
            full = G:count_cards_in_full_deck(function(d) return d.enhancement ~= nil end)
        end
        if G and G.count_cards_in_deck then
            remaining = G:count_cards_in_deck(function(d) return d.enhancement ~= nil end)
        end
        return {
            vars = {
                card.ability.extra.xmult_gain,
                card.ability.extra.xmult + card.ability.extra.xmult_gain * full,
                remaining <= 0 and "(Active)" or "(Inactive)",
            },
        }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            local full, remaining = 0, 0
            if G and G.count_cards_in_full_deck then
                full = G:count_cards_in_full_deck(function(d) return d.enhancement ~= nil end)
            end
            if G and G.count_cards_in_deck then
                remaining = G:count_cards_in_deck(function(d) return d.enhancement ~= nil end)
            end
            if remaining <= 0 then
                return {
                    xmult = card.ability.extra.xmult
                        + card.ability.extra.xmult_gain * full,
                }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Meaty Joker: X1 Mult for every 20 cards in your full deck (min X1).
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "meaty_joker",
    loc_txt = {
        name = "Meaty Joker",
        text = {
            "{X:mult,C:white}X#1#{} Mult for every {C:attention}#2#{}",
            "cards in your {C:attention}full deck{}",
            "{C:inactive}(Currently {X:mult,C:white}X#3#{C:inactive} Mult){}",
            "{C:inactive}(Minimum {X:mult,C:white}X1{C:inactive} Mult){}",
        },
    },
    config = { extra = { xmult = 1, cards = 20 } },
    rarity = 3,
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "meaty_joker.png",
    negative_sprite = "meaty_joker_negative.png",
    loc_vars = function(self, info_queue, card)
        local total = 0
        if G and G.count_cards_in_full_deck then
            total = G:count_cards_in_full_deck()
        end
        local xmult = math.floor(total / card.ability.extra.cards)
        if xmult < 1 then xmult = 1 end
        return { vars = { card.ability.extra.xmult, card.ability.extra.cards, xmult } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            local total = 0
            if G and G.count_cards_in_full_deck then
                total = G:count_cards_in_full_deck()
            end
            local xmult = math.floor(total / card.ability.extra.cards)
            if xmult < 1 then xmult = 1 end
            return { xmult = xmult }
        end
    end,
}

--------------------------------------------------------------------------------
-- Melancholic Joker: scored Spades have a 1 in 8 chance to create
-- a random Spectral card.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "melancholic_joker",
    loc_txt = {
        name = "Melancholic Joker",
        text = {
            "Played cards with {C:spades}Spade",
            "suit have a {C:green}#1# in #2#{} chance",
            "to create a random",
            "{C:spectral}Spectral{} card when scored",
            "{C:inactive}(Must have room){}",
        },
    },
    config = { extra = { odds = 8 } },
    rarity = 3,
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "melancholic_joker.png",
    negative_sprite = "melancholic_joker_negative.png",
    loc_vars = function(self, info_queue, card)
        local numerator, denominator =
            SMODS.get_probability_vars(card, 1, card.ability.extra.odds, "melancholic_joker")
        return { vars = { numerator, denominator } }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play
            and context.other_card and context.other_card:is_suit("Spades") then
            if SMODS.pseudorandom_probability(card, "melancholic_joker", 1,
                card.ability.extra.odds, "melancholic_joker") then
                if SMODS.add_card { set = "Spectral" } then
                    return { message = "+Spectral" }
                end
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Melpomene: scored face cards give Chips and Mult equal to the
-- base stats of the played poker hand (fork hand stats by handlist
-- index, the Bunco / Cryptid precedent).
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "melpomene",
    loc_txt = {
        name = "Melpomene",
        text = {
            "Scored {C:attention}face cards{} give",
            "{C:chips}Chips{} and {C:mult}Mult{} equal to",
            "the {C:attention}base stats{} of the",
            "played poker hand",
        },
    },
    config = { extra = {} },
    rarity = 4,
    cost = 20,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "melpomene.png",
    negative_sprite = "melpomene_negative.png",
    soul_sprite = "melpomene_soul.png",
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play
            and context.other_card and context.other_card:is_face() then
            local chips, mult = jest4_hand_stats(context.scoring_name)
            return { chips = chips, mult = mult }
        end
    end,
}

--------------------------------------------------------------------------------
-- Mike Check: create a random Uncommon Joker every 3 Jokers sold.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "mike_check",
    loc_txt = {
        name = "Mike Check",
        text = {
            "Create a random {C:uncommon}Uncommon{}",
            "Joker every {C:attention}#1#{} Jokers sold",
            "{C:inactive}({C:attention}#2#{}{C:inactive}/#1#)",
        },
    },
    config = { extra = { count = 0, target = 3 } },
    rarity = 2,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = false,
    perishable_compat = true,
    sprite = "mike_check.png",
    negative_sprite = "mike_check_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.target, card.ability.extra.count } }
    end,
    calculate = function(self, card, context)
        if context.selling_card and not context.blueprint then
            card.ability.extra.count = card.ability.extra.count + 1
            if card.ability.extra.count >= card.ability.extra.target then
                card.ability.extra.count = 0
                if jest4_create_random_joker(2, "mike_check") then
                    return { message = "+Joker" }
                end
            else
                return {
                    message = card.ability.extra.count .. "/" .. card.ability.extra.target,
                }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Mixel Perfect: +9 Mult if the scored hand has an odd card count.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "mixel_perfect",
    loc_txt = {
        name = "Mixel Perfect",
        text = {
            "{C:mult}+#1#{} Mult if {C:attention}scored hand{}",
            "contains an {C:attention}odd{}",
            "number of cards",
        },
    },
    config = { extra = { mult = 9 } },
    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "mixel_perfect.png",
    negative_sprite = "mixel_perfect_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult } }
    end,
    calculate = function(self, card, context)
        if context.joker_main and context.scoring_hand
            and math.fmod(#context.scoring_hand, 2) == 1 then
            return { mult = card.ability.extra.mult }
        end
    end,
}

--------------------------------------------------------------------------------
-- Mondrian Joker: +4 Mult per 4 in your full deck.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "mondrian_joker",
    loc_txt = {
        name = "Mondrian Joker",
        text = {
            "{C:mult}+#1#{} Mult per {C:attention}4",
            "in your {C:attention}full deck",
            "{C:inactive}(Currently{} {C:mult}+#2#{}{C:inactive} Mult)",
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
    sprite = "mondrian_joker.png",
    negative_sprite = "mondrian_joker_negative.png",
    loc_vars = function(self, info_queue, card)
        local four_count = 0
        if G and G.count_cards_in_full_deck then
            four_count = G:count_cards_in_full_deck(function(d) return d.rank == 4 end)
        end
        card.ability.extra.mult = four_count * card.ability.extra.mult_mod
        return { vars = { card.ability.extra.mult_mod, card.ability.extra.mult } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            local four_count = 0
            if G and G.count_cards_in_full_deck then
                four_count = G:count_cards_in_full_deck(function(d) return d.rank == 4 end)
            end
            card.ability.extra.mult = four_count * card.ability.extra.mult_mod
            if card.ability.extra.mult > 0 then
                return { mult = card.ability.extra.mult }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Mr. Lonely: gains +10 Chips per empty Joker slot at end of round.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "mr_lonely",
    loc_txt = {
        name = "Mr. Lonely",
        text = {
            "This Joker gains {C:chips}+#1# Chips",
            "per empty {C:attention}Joker slot{}",
            "at end of {C:attention}round{}",
            "{C:inactive}(Currently{} {C:chips}+#2#{C:inactive} Chips)",
        },
    },
    config = { extra = { chips = 0, chip_mod = 10 } },
    rarity = 2,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    sprite = "mr_lonely.png",
    negative_sprite = "mr_lonely_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chip_mod, card.ability.extra.chips } }
    end,
    calculate = function(self, card, context)
        if context.end_of_round and not context.blueprint then
            local empty = jest4_empty_joker_slots()
            if empty > 0 then
                card.ability.extra.chips = card.ability.extra.chips
                    + card.ability.extra.chip_mod * empty
                return { message = localize("k_upgrade_ex") }
            end
        end
        if context.joker_main and card.ability.extra.chips > 0 then
            return { chips = card.ability.extra.chips }
        end
    end,
}

--------------------------------------------------------------------------------
-- Mummer: retrigger all Steel Cards once per Steel Card in the
-- scored hand. (PC in_pool Steel-in-deck gate dropped, see census.)
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "mummer",
    loc_txt = {
        name = "Mummer",
        text = {
            "Retrigger all {C:attention}Steel Cards{}",
            "once per {C:attention}Steel Card{} in",
            "scored hand",
        },
    },
    config = { triggers = "0" },
    rarity = 3,
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "mummer.png",
    negative_sprite = "mummer_negative.png",
    calculate = function(self, card, context)
        if context.repetition and context.cardarea == G.hand
            and context.other_card and context.other_card.enhancement == "steel" then
            local steel_count = 0
            for _, scoring_card in ipairs(context.scoring_hand or {}) do
                if scoring_card.enhancement == "steel" then
                    steel_count = steel_count + 1
                end
            end
            if steel_count > 0 then
                return { message = "Again!", repetitions = steel_count }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Mute Joker: this round, the first time the chosen poker hand is
-- played, destroy all its scored cards. Hand re-rolls at end of
-- round from the fork's visible-hand list; batch destroy becomes a
-- one-at-a-time SMODS.destroy_card loop.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "mute_joker",
    loc_txt = {
        name = "Mute Joker",
        text = {
            "This round, first {C:attention}#1#{} played",
            "{C:red}destroys{} all scored cards",
            "{C:inactive}(Poker hand changes at end of round)",
        },
    },
    config = { extra = { poker_hand = "(hand)", trigger = false } },
    rarity = 2,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "mute_joker.png",
    negative_sprite = "mute_joker_negative.png",
    loc_vars = function(self, info_queue, card)
        if card.ability.extra.poker_hand == "(hand)" and G and G.handlist then
            local _poker_hands = {}
            for i, name in ipairs(G.handlist) do
                local visible = true
                if G.is_hand_stats_visible then
                    visible = G:is_hand_stats_visible(i)
                end
                if visible and name ~= card.ability.extra.poker_hand then
                    _poker_hands[#_poker_hands + 1] = name
                end
            end
            if #_poker_hands > 0 then
                card.ability.extra.poker_hand =
                    pseudorandom_element(_poker_hands, "mute_joker")
                card.ability.extra.trigger = false
            end
        end
        return { vars = { card.ability.extra.poker_hand } }
    end,
    calculate = function(self, card, context)
        if context.end_of_round and not context.blueprint then
            if G and G.handlist then
                local _poker_hands = {}
                for i, name in ipairs(G.handlist) do
                    local visible = true
                    if G.is_hand_stats_visible then
                        visible = G:is_hand_stats_visible(i)
                    end
                    if visible and name ~= card.ability.extra.poker_hand then
                        _poker_hands[#_poker_hands + 1] = name
                    end
                end
                if #_poker_hands > 0 then
                    card.ability.extra.poker_hand =
                        pseudorandom_element(_poker_hands, "mute_joker")
                end
            end
            card.ability.extra.trigger = false
            return { message = "Reset!" }
        end
        if context.after and context.scoring_hand
            and not card.ability.extra.trigger
            and card.ability.extra.poker_hand ~= "(hand)"
            and not context.blueprint then
            if context.scoring_name == card.ability.extra.poker_hand then
                local targets = {}
                for _, node in ipairs(context.scoring_hand) do
                    targets[#targets + 1] = node
                end
                for _, node in ipairs(targets) do
                    if SMODS.destroy_card then SMODS.destroy_card(node) end
                end
                card.ability.extra.trigger = true
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Napkin: gains X1 Mult when 2 Blinds are skipped in a row.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "napkin",
    loc_txt = {
        name = "Napkin",
        text = {
            "This Joker gains {X:mult,C:white}X#1#{}",
            "Mult when {C:attention}2{} Blinds are",
            "skipped {C:attention}in a row",
            "{C:inactive}(Currently {X:mult,C:white}X#2#{C:inactive} Mult){}",
        },
    },
    config = { extra = { xmult_mod = 1, xmult = 1, state = false } },
    rarity = 2,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    sprite = "napkin.png",
    negative_sprite = "napkin_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.xmult_mod, card.ability.extra.xmult } }
    end,
    calculate = function(self, card, context)
        if not context.blueprint then
            if context.skip_blind then
                if card.ability.extra.state then
                    card.ability.extra.xmult = card.ability.extra.xmult
                        + card.ability.extra.xmult_mod
                    card.ability.extra.state = false
                end
                if not card.ability.extra.state then
                    card.ability.extra.state = true
                end
            end
            if context.setting_blind then
                card.ability.extra.state = false
            end
        end
        if context.joker_main then
            return { xmult = card.ability.extra.xmult }
        end
    end,
}

--------------------------------------------------------------------------------
-- Nedda: Queens held in hand give X2 Mult.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "nedda",
    loc_txt = {
        name = "Nedda",
        text = {
            "{C:attention}Queens{} held in hand",
            "give {X:mult,C:white}X#1#{} Mult",
        },
    },
    config = { extra = { xmult = 2 } },
    rarity = 4,
    cost = 20,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "nedda.png",
    negative_sprite = "nedda_negative.png",
    soul_sprite = "nedda_soul.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.xmult } }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.hand
            and context.other_card and context.other_card:get_id() == 12
            and not context.end_of_round then
            if context.other_card.debuff then
                return { message = "Debuffed!" }
            else
                return { xmult = card.ability.extra.xmult }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Neon Sign: X3 Mult if the played hand contains a Full House and
-- the previous hand did not.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "neon_sign",
    loc_txt = {
        name = "Neon Sign",
        text = {
            "{X:mult,C:white}X#1#{} Mult if played hand",
            "contains a {C:attention}Full House{} and",
            "the previous hand {C:attention}did not",
            "{C:inactive}(#2#)",
        },
    },
    config = { extra = { full_house_last_hand = false, xmult = 3 } },
    rarity = 2,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "neon_sign.png",
    negative_sprite = "neon_sign_negative.png",
    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                card.ability.extra.xmult,
                card.ability.extra.full_house_last_hand and "(Inactive)" or "(Active)",
            },
        }
    end,
    calculate = function(self, card, context)
        if context.joker_main and context.poker_hands
            and next(context.poker_hands["Full House"]) then
            if not card.ability.extra.full_house_last_hand then
                return { xmult = card.ability.extra.xmult }
            end
        end
        if context.after and not context.blueprint and context.poker_hands then
            card.ability.extra.full_house_last_hand =
                next(context.poker_hands["Full House"]) ~= nil
        end
    end,
}

--------------------------------------------------------------------------------
-- Neptunium: Straight Flush retriggers all scoring cards twice.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "neptunium",
    loc_txt = {
        name = "Neptunium",
        text = {
            "If played hand is {C:attention}Straight Flush{},",
            "retrigger all scoring cards{}",
            "{C:attention}#1#{} times",
        },
    },
    config = { extra = { retriggers = 2 } },
    rarity = 2,
    cost = 7,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "neptunium.png",
    negative_sprite = "neptunium_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.retriggers } }
    end,
    calculate = function(self, card, context)
        if context.repetition and context.cardarea == G.play
            and context.scoring_name == "Straight Flush" then
            return { repetitions = card.ability.extra.retriggers }
        end
    end,
}

--------------------------------------------------------------------------------
-- Neutronium: Flush Five retriggers all scoring cards.
-- (in_pool gate kept via the fork's hand play counts, by handlist index.)
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "neutronium",
    loc_txt = {
        name = "Neutronium",
        text = {
            "If played hand is {C:attention}Flush Five{},",
            "retrigger all scoring cards{}",
        },
    },
    config = { extra = {} },
    rarity = 3,
    cost = 9,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "neutronium.png",
    negative_sprite = "neutronium_negative.png",
    calculate = function(self, card, context)
        if context.repetition and context.cardarea == G.play
            and context.scoring_name == "Flush Five" then
            return { repetitions = 1 }
        end
    end,
    in_pool = function(self, args)
        if G and G.handlist and G.hand_play_counts then
            for i, name in ipairs(G.handlist) do
                if name == "Flush Five" then
                    return (G.hand_play_counts[i] or 0) > 0
                end
            end
        end
        return false
    end,
}

--------------------------------------------------------------------------------
-- Nevernamed (credits Joker): no calculate, never in pool.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "nevernamed_credits_joker",
    loc_txt = {
        name = "Nevernamed",
        text = {
            "This space intentionally",
            "{C:inactive}left blank",
        },
    },
    config = { extra = {} },
    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = false,
    perishable_compat = true,
    sprite = "nevernamed_credits_joker.png",
    negative_sprite = "nevernamed_credits_joker_negative.png",
    calculate = function(self, card, context) end,
    in_pool = function(self, args) return false end,
}

--------------------------------------------------------------------------------
-- Nichola: when the round begins, add a random Queen to hand with a
-- random Enhancement, Edition and Seal (one SMODS.add_card call;
-- PC's enhancement poll exclusion of Stone is not expressible in the
-- fork poll -- see census).
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "nichola",
    loc_txt = {
        name = "Nichola",
        text = {
            "When round begins, add",
            "one random {C:attention}Queen",
            "to your hand with a",
            "random {C:attention}Enhancement{},",
            "{C:dark_edition}Edition{} and {C:attention}Seal{}",
        },
    },
    config = { extra = {} },
    rarity = 4,
    cost = 20,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "nichola.png",
    negative_sprite = "nichola_negative.png",
    soul_sprite = "nichola_soul.png",
    calculate = function(self, card, context)
        if context.first_hand_drawn then
            local suits = { "Spades", "Hearts", "Diamonds", "Clubs" }
            local suit = pseudorandom_element(suits, "nichola_suit")
            local enh = SMODS.poll_enhancement({ guaranteed = true })
            local seal = SMODS.poll_seal({ guaranteed = true })
            local edition = jest4_roll_edition("nichola_edition", true)
            SMODS.add_card {
                set = "Playing",
                rank = 12,
                suit = suit,
                enhancement = enh,
                seal = seal,
                edition = edition,
                bypass_limit = true,
            }
        end
    end,
}

--------------------------------------------------------------------------------
-- NotSoAI (credits Joker): no calculate, never in pool.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "notsoai_credits_joker",
    loc_txt = {
        name = "NotSoAI",
        text = { "Skibby Dee" },
    },
    config = { extra = {} },
    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = false,
    perishable_compat = true,
    sprite = "notsoai_credits_joker.png",
    negative_sprite = "notsoai_credits_joker_negative.png",
    calculate = function(self, card, context) end,
    in_pool = function(self, args) return false end,
}

--------------------------------------------------------------------------------
-- Null Joker: sets all odds to zero (fix_probability seat; the fork
-- return is absolute, so the current denominator is passed back).
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "null_joker",
    loc_txt = {
        name = "Null Joker",
        text = {
            "Sets all {C:green}odds{}",
            "to {C:attention}zero{}",
            "{C:inactive,s:0.8}(ex: {C:green,s:0.8}1 in 3{C:inactive,s:0.8} -> {C:green,s:0.8}0 in 3{C:inactive,s:0.8})",
        },
    },
    config = { extra = {} },
    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "null_joker.png",
    negative_sprite = "null_joker_negative.png",
    calculate = function(self, card, context)
        if context.fix_probability then
            return { numerator = 0, denominator = context.denominator or 1 }
        end
    end,
}

--------------------------------------------------------------------------------
-- Odd Rod: retrigger all played cards with odd rank.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "odd_rod",
    loc_txt = {
        name = "Odd Rod",
        text = {
            "{C:attention}Retrigger{} all played",
            "cards with {C:attention}odd{} rank",
        },
    },
    config = { extra = {} },
    rarity = 2,
    cost = 7,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "odd_rod.png",
    negative_sprite = "odd_rod_negative.png",
    calculate = function(self, card, context)
        if context.repetition and context.cardarea == G.play and context.other_card then
            local id = context.other_card:get_id()
            if (id <= 10 and id >= 0 and id % 2 == 1) or id == 14 then
                return { repetitions = 1 }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Oklo Reactor: retrigger all played Gold Cards twice.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "oklo_reactor",
    loc_txt = {
        name = "Oklo Reactor",
        text = {
            "{C:attention}Retrigger{} all played {C:attention}Gold",
            "{C:attention}Cards twice{}",
        },
    },
    config = { extra = { retriggers = 2 } },
    rarity = 2,
    cost = 7,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "oklo_reactor.png",
    negative_sprite = "oklo_reactor_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.retriggers } }
    end,
    calculate = function(self, card, context)
        if context.repetition and context.cardarea == G.play
            and context.other_card and context.other_card.enhancement == "gold" then
            return { repetitions = card.ability.extra.retriggers }
        end
    end,
}

--------------------------------------------------------------------------------
-- Old Joker: always Eternal (set_ability writes the held Joker's
-- eternal flag); gains +25 Chips and +5 Mult when Boss Blind is
-- defeated.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "old_joker",
    loc_txt = {
        name = "Old Joker",
        text = {
            "This Joker gains {C:chips}+#2#{} Chips",
            "and {C:mult}+#4#{} Mult when {C:attention}Boss",
            "{C:attention}Blind{} is defeated",
            "{C:inactive,s:0.8}(Currently {C:chips,s:0.8}+#1#{}{C:inactive,s:0.8} Chips, {C:mult,s:0.8}+#3#{}{C:inactive,s:0.8} Mult)",
            "{C:inactive,s:0.8}(Always Eternal)",
        },
    },
    config = { extra = { chips = 0, chips_mod = 25, mult = 0, mult_mod = 5 } },
    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    sprite = "old_joker.png",
    negative_sprite = "old_joker_negative.png",
    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                card.ability.extra.chips,
                card.ability.extra.chips_mod,
                card.ability.extra.mult,
                card.ability.extra.mult_mod,
            },
        }
    end,
    set_ability = function(self, card, initial)
        if card then card.eternal = true end
    end,
    calculate = function(self, card, context)
        if context.end_of_round and not context.game_over
            and jest4_is_boss(context) and not context.blueprint then
            card.ability.extra.chips = card.ability.extra.chips
                + card.ability.extra.chips_mod
            card.ability.extra.mult = card.ability.extra.mult
                + card.ability.extra.mult_mod
            return { message = localize("k_upgrade_ex") }
        end
        if context.joker_main then
            return {
                chips = card.ability.extra.chips,
                mult = card.ability.extra.mult,
            }
        end
    end,
}

--------------------------------------------------------------------------------
-- Omelette: gains $3 of sell value when a hand or discard is used.
-- (Sell growth writes the held Joker's sell_cost directly, the
-- Paperback precedent; PC's in_pool egg-appearance gate rides a
-- Card:start_dissolve override and is dropped -- see census.)
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "omlette",
    loc_txt = {
        name = "Omelette",
        text = {
            "Gains {C:money}$#1#{} of sell value when",
            "a {C:blue}hand{} or {C:red}discard{} is used",
        },
    },
    config = { extra = { sell_gain = 3 } },
    rarity = 2,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "omlette.png",
    negative_sprite = "omlette_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.sell_gain } }
    end,
    calculate = function(self, card, context)
        if context.pre_discard and not context.blueprint then
            card.sell_cost = (tonumber(card.sell_cost) or 0) + card.ability.extra.sell_gain
            return { message = "Value Up!" }
        end
        if context.before and context.scoring_hand and not context.blueprint then
            card.sell_cost = (tonumber(card.sell_cost) or 0) + card.ability.extra.sell_gain
        end
    end,
}

--------------------------------------------------------------------------------
-- One Little Duck: gains +2 Mult for each played-but-unscored 2.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "one_little_duck",
    loc_txt = {
        name = "One Little Duck",
        text = {
            "This Joker gains {C:mult}+#2#{} Mult",
            "for each {C:attention}2{} that is {C:attention}played",
            "but not{} {C:attention}scored{}",
            "{C:inactive}(Currently {C:mult}+#1#{} {C:inactive}Mult)",
        },
    },
    config = { extra = { mult = 0, mult_gain = 2 } },
    rarity = 1,
    cost = 5,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    sprite = "one_little_duck.png",
    negative_sprite = "one_little_duck_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult, card.ability.extra.mult_gain } }
    end,
    calculate = function(self, card, context)
        if context.before and not context.blueprint then
            local scoring = {}
            for _, scoring_card in ipairs(context.scoring_hand or {}) do
                scoring[scoring_card] = true
            end
            local twos_unscored = 0
            for _, played_card in ipairs(context.full_hand or {}) do
                if not scoring[played_card] and played_card:get_id() == 2 then
                    twos_unscored = twos_unscored + 1
                end
            end
            if twos_unscored > 0 then
                card.ability.extra.mult = card.ability.extra.mult
                    + card.ability.extra.mult_gain * twos_unscored
                return { message = localize("k_upgrade_ex") }
            end
        end
        if context.joker_main then
            return { mult = card.ability.extra.mult }
        end
    end,
}

--------------------------------------------------------------------------------
-- Orphic Joker: create a random Joker when Blind is skipped.
-- (PC code rolls rarity 1 via SMODS.add_card; its text says Rare --
-- the code is followed verbatim, see census.)
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "orphic_joker",
    loc_txt = {
        name = "Orphic Joker",
        text = {
            "Create {C:attention}#1#{} random",
            "{C:rare}Rare{} {C:attention}Joker{} when",
            "Blind is {C:attention}skipped",
            "{C:inactive}(Must have room){}",
        },
    },
    config = { extra = { jokers = 1 } },
    rarity = 3,
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "orphic_joker.png",
    negative_sprite = "orphic_joker_negative.png",
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.jokers } }
    end,
    calculate = function(self, card, context)
        if context.skip_blind and not card.debuff then
            for _ = 1, card.ability.extra.jokers do
                if jest4_create_random_joker(1, "orphic") then
                    return { message = "+Joker" }
                end
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Overdesigned Joker: scored cards matching the current suit give
-- that suit's bonus; suit and effect rotate per scored card.
-- DEVIATION (see census): PC's dynamic dictionary text (localize
-- suits_plural + extra_joker_dictionary prefixes, {V}/{B} markup)
-- has no fork equivalent, so the text below is a static rewrite;
-- the mechanic and numbers are PC's exactly.
--------------------------------------------------------------------------------

local jest4_overdesigned_amounts = {
    Hearts = 1.5,
    Clubs = 14,
    Diamonds = 2,
    Spades = 100,
}

local function jest4_overdesigned_cycle(suit)
    if suit == "Hearts" then return "Clubs" end
    if suit == "Clubs" then return "Diamonds" end
    if suit == "Diamonds" then return "Spades" end
    if suit == "Spades" then return "Hearts" end
    return "Clubs"
end

local function jest4_round_hundredth(x)
    if x >= 0 then return math.floor(x * 100 + 0.5) / 100 end
    return math.ceil(x * 100 - 0.5) / 100
end

SMODS.Joker {
    key = "overdesigned_joker",
    loc_txt = {
        name = "Overdesigned Joker",
        text = {
            "Scored {C:attention}#1#{} cards give",
            "{C:attention}Hearts{}: {X:mult,C:white}X1.5{} Mult, {C:attention}Clubs{}: {C:mult}+14{} Mult,",
            "{C:attention}Diamonds{}: {C:money}$2{}, {C:attention}Spades{}: {C:chips}+100{} Chips",
            "Suit and effect {C:attention}rotate{} when a card is {C:attention}scored",
            "{C:inactive}(Currently {C:attention}#1#{C:inactive}, bonus {C:attention}#2#{C:inactive}){}",
        },
    },
    config = { suit = "Hearts", silver_multiplier_buff = 100 },
    rarity = 2,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "overdesigned_joker.png",
    negative_sprite = "overdesigned_joker_negative.png",
    loc_vars = function(self, info_queue, card)
        local amount = jest4_overdesigned_amounts[card.ability.suit] or 0
        return {
            vars = {
                card.ability.suit,
                jest4_round_hundredth(amount * (card.ability.silver_multiplier_buff / 100)),
            },
        }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play
            and not context.end_of_round and context.other_card then
            local orig_suit = card.ability.suit
            local amount = jest4_round_hundredth(
                (jest4_overdesigned_amounts[orig_suit] or 0)
                * (card.ability.silver_multiplier_buff / 100))
            if not context.blueprint then
                card.ability.suit = jest4_overdesigned_cycle(card.ability.suit)
            end
            if context.other_card:is_suit(orig_suit) then
                local ret = { extra = { message = card.ability.suit } }
                if orig_suit == "Clubs" then
                    ret.mult = amount
                elseif orig_suit == "Diamonds" then
                    ret.dollars = amount
                elseif orig_suit == "Spades" then
                    ret.chips = amount
                elseif orig_suit == "Hearts" then
                    ret.xmult = amount
                end
                return ret
            else
                return { extra = { message = card.ability.suit } }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Pangram: X0.2 Mult per unique rank held in hand.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "pangram",
    loc_txt = {
        name = "Pangram",
        text = {
            "Gives {X:mult,C:white}X#1#{} Mult per {C:attention}unique{}",
            "rank {C:attention}held in hand{}",
            "{C:inactive}(Currently {X:mult,C:white}X#2#{C:inactive} Mult)",
        },
    },
    config = { extra = { xmult_gain = 0.2, xmult_base = 1 } },
    rarity = 2,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    sprite = "pangram.png",
    negative_sprite = "pangram_negative.png",
    loc_vars = function(self, info_queue, card)
        local ranks = {}
        local unique_ranks = 0
        for _, c in ipairs((G and G.hand and G.hand.card_nodes) or {}) do
            if not c.debuff then
                local id = c:get_id()
                if id and not ranks[id] then
                    ranks[id] = true
                    unique_ranks = unique_ranks + 1
                end
            end
        end
        return {
            vars = {
                card.ability.extra.xmult_gain,
                card.ability.extra.xmult_base
                    + card.ability.extra.xmult_gain * unique_ranks,
            },
        }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            local ranks = {}
            local unique_ranks = 0
            for _, c in ipairs((G and G.hand and G.hand.card_nodes) or {}) do
                if not c.debuff then
                    local id = c:get_id()
                    if id and not ranks[id] then
                        ranks[id] = true
                        unique_ranks = unique_ranks + 1
                    end
                end
            end
            local xmult = card.ability.extra.xmult_base
                + card.ability.extra.xmult_gain * unique_ranks
            if xmult > 1 then
                return { xmult = xmult }
            end
        end
    end,
}

-- JestPack Wave 4, chunk 05 — PORTABLE Jokers (All in Jest → Balatro3DS fork)
-- Fragment only: the integrator assembles the pack file + header.

-- pantomimus: gains +2 Chips per card held in hand at end of round.
-- SMODS.scale_card inlined; #G.hand.cards -> #G.hand.card_nodes.
SMODS.Joker {
    key = "pantomimus",
    sprite = "pantomimus.png",
    negative_sprite = "pantomimus_negative.png",
    rarity = 1,
    cost = 4,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    config = { extra = { chips = 0, chip_mod = 2 } },
    loc_txt = {
        name = "Pantomimus",
        text = {
            "This Joker gains {C:chips}+#2#{}",
            "Chips per card {C:attention}held in",
            "{C:attention}hand{} at end of {C:attention}round",
            "{C:inactive}(Currently {C:chips}+#1#{C:inactive} Chips)",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chips, card.ability.extra.chip_mod } }
    end,
    calculate = function(self, card, context)
        if context.end_of_round and not context.blueprint then
            local held = (G and G.hand and G.hand.card_nodes) and #G.hand.card_nodes or 0
            card.ability.extra.chips = card.ability.extra.chips
                + held * card.ability.extra.chip_mod
        end
        if context.joker_main then
            return { chips = card.ability.extra.chips }
        end
    end,
}

-- papermoon_credits_joker: credits Joker, never in pool (cosmetic badge drops).
SMODS.Joker {
    key = "papermoon_credits_joker",
    sprite = "papermoon_credits_joker.png",
    negative_sprite = "papermoon_credits_joker_negative.png",
    rarity = 1,
    cost = 4,
    blueprint_compat = false,
    eternal_compat = false,
    config = {},
    loc_txt = {
        name = "Papermoon",
        text = {
            "{C:inactive}\"We're invited to a lifelong",
            "{C:inactive}party, it's rude to overstay.\"",
        },
    },
    in_pool = function(self, args)
        return false
    end,
}

-- paracosm: level up most played hand by 2 when a Blind is skipped.
-- G.GAME.hands -> G.handlist + G.hand_play_counts + G:is_hand_stats_visible;
-- level_up_hand -> G:upgrade_hand_level_at_index.
SMODS.Joker {
    key = "paracosm",
    sprite = "paracosm.png",
    negative_sprite = "paracosm_negative.png",
    rarity = 2,
    cost = 6,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    config = { extra = { hand = "[Most played hand]", levels = 2 } },
    loc_txt = {
        name = "Paracosm",
        text = {
            "Upgrade {C:attention}most played",
            "poker hand by {C:attention}#1#{} levels",
            "when Blind is {C:attention}skipped",
            "{C:inactive}(Currently #2#)",
        },
    },
    loc_vars = function(self, info_queue, card)
        local most_played_hand = nil
        local val = 1
        if G and G.handlist and G.hand_play_counts then
            for i, name in ipairs(G.handlist) do
                local visible = not G.is_hand_stats_visible
                    or G:is_hand_stats_visible(i)
                local played = tonumber(G.hand_play_counts[i]) or 0
                if visible and played >= val then
                    val = played
                    most_played_hand = name
                end
            end
        end
        card.ability.extra.hand = most_played_hand or "None"
        return { vars = { card.ability.extra.levels, card.ability.extra.hand } }
    end,
    calculate = function(self, card, context)
        if context.skip_blind then
            local most_idx, val = nil, 1
            if G and G.handlist and G.hand_play_counts then
                for i, name in ipairs(G.handlist) do
                    local visible = not G.is_hand_stats_visible
                        or G:is_hand_stats_visible(i)
                    local played = tonumber(G.hand_play_counts[i]) or 0
                    if visible and played >= val then
                        val = played
                        most_idx = i
                    end
                end
            end
            if most_idx and G and G.upgrade_hand_level_at_index then
                for _ = 1, card.ability.extra.levels do
                    G:upgrade_hand_level_at_index(most_idx)
                end
                return { message = localize("k_upgrade_ex") }
            end
        end
    end,
}

-- parking_space: X2 Mult while sitting in its target Joker slot;
-- slot re-rolled at end of round (held-Joker list is slot-ordered).
SMODS.Joker {
    key = "parking_space",
    sprite = "parking_space.png",
    negative_sprite = "parking_space_negative.png",
    rarity = 2,
    cost = 7,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    config = { extra = { xmult = 2, target_slot = 1 } },
    loc_txt = {
        name = "Parking Space",
        text = {
            "{X:mult,C:white}X#1#{} Mult if this Joker",
            "is in {C:attention}Joker Slot #2#{}",
            "{C:inactive,s:0.8}(Slot changes at end of round)",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.xmult, card.ability.extra.target_slot } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            local me = context.blueprint_card or card
            local my_pos = nil
            for i, j in ipairs(G.jokers or {}) do
                if j == me then
                    my_pos = i
                    break
                end
            end
            if my_pos and my_pos == card.ability.extra.target_slot then
                return { xmult = card.ability.extra.xmult }
            end
        end
        if context.end_of_round and not context.blueprint then
            local limit = #(G.jokers or {}) or 5
            if limit < 1 then limit = 1 end
            card.ability.extra.target_slot =
                math.ceil(pseudorandom("parking_space") * limit)
            return { message = localize("k_reset") }
        end
    end,
}

-- party_streamers: first hand of round, a single scored card with no
-- Seal gains a random Red/Blue/Gold Seal (node set_seal setter).
SMODS.Joker {
    key = "party_streamers",
    sprite = "party_streamers.png",
    negative_sprite = "party_streamers_negative.png",
    rarity = 3,
    cost = 8,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    config = {},
    loc_txt = {
        name = "Party Streamers",
        text = {
            "If {C:attention}first hand{} of round",
            "is exactly {C:attention}1{} card with no",
            "{C:attention}Seal{}, it gets a {C:red}Red{}, {C:blue}Blue{},",
            "or {C:money}Gold{} {C:attention}Seal{}",
        },
    },
    calculate = function(self, card, context)
        if context.after and not context.blueprint
            and G and G.get_round_hands_played
            and G:get_round_hands_played() == 0
            and context.full_hand and #context.full_hand == 1
            and context.scoring_hand then
            for _, v in ipairs(context.scoring_hand) do
                if not v.seal and not v.debuff then
                    local roll = pseudorandom(pseudoseed("party"))
                    local seal_key, seal_name
                    if roll > 0.66 then
                        seal_key, seal_name = "Blue Seal", "blue"
                    elseif roll > 0.33 then
                        seal_key, seal_name = "Gold Seal", "gold"
                    else
                        seal_key, seal_name = "Red Seal", "red"
                    end
                    if v.set_seal then
                        v:set_seal(seal_name)
                    elseif v.card_data then
                        v.card_data.seal = seal_name
                    end
                    return { message = seal_key }
                end
            end
        end
    end,
}

-- peanut_brittle: gains X0.5 Mult when a card is enhanced to Glass,
-- loses X0.5 when a Glass card is destroyed; creates Justice on obtain.
-- setting_ability port event carries old/new in context.port;
-- remove_playing_cards destroyed list is context.port.destroyed_cards.
SMODS.Joker {
    key = "peanut_brittle",
    sprite = "peanut_brittle.png",
    negative_sprite = "peanut_brittle_negative.png",
    rarity = 3,
    cost = 8,
    blueprint_compat = true,
    eternal_compat = false,
    perishable_compat = false,
    config = {
        extra = {
            xmult_minus_mod = 0.5,
            xmult_mod = 0.5,
            xmult = 0,
            enhancement = "m_glass",
            tarot = "c_justice",
        },
    },
    loc_txt = {
        name = "Peanut Brittle",
        text = {
            "This {C:attention}Joker{} gains {X:mult,C:white}X#1#{} Mult",
            "when a card is enhanced to",
            "{C:attention}Glass{}, loses {X:mult,C:white}X#2#{} Mult when",
            "when a Glass Card {C:attention}breaks{}",
            "{C:inactive}(Currently {X:mult,C:white}X#3#{} {C:inactive}Mult){}",
            "Creates {C:tarot}Justice{}",
            "when {C:attention}obtained{}",
            "{C:inactive}(Must have room){}",
        },
    },
    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                card.ability.extra.xmult_mod,
                card.ability.extra.xmult_minus_mod,
                1 + card.ability.extra.xmult,
            },
        }
    end,
    add_to_deck = function(self, card, from_debuff)
        if not from_debuff then
            SMODS.add_card { set = "Tarot", key = card.ability.extra.tarot }
        end
    end,
    calculate = function(self, card, context)
        if context.setting_ability and not context.unchanged
            and not context.blueprint then
            local kind = context.port and context.port.ability_kind
            local new_val = context.port and context.port.new
            if kind == "enhancement" and new_val == "glass" then
                card.ability.extra.xmult = card.ability.extra.xmult
                    + card.ability.extra.xmult_mod
            end
        end
        if context.remove_playing_cards and not context.blueprint then
            local destroyed = context.port and context.port.destroyed_cards
            if type(destroyed) == "table" then
                for _, v in ipairs(destroyed) do
                    local enh = v.enhancement
                    if enh == "glass" or enh == "m_glass" then
                        if ((1 + card.ability.extra.xmult)
                            - card.ability.extra.xmult_minus_mod) < 1 then
                            SMODS.destroy_joker(card)
                            return { message = localize("k_eaten_ex") }
                        else
                            card.ability.extra.xmult = card.ability.extra.xmult
                                - card.ability.extra.xmult_minus_mod
                        end
                    end
                end
            end
        end
        if context.joker_main then
            return { xmult = 1 + card.ability.extra.xmult }
        end
    end,
}

-- pedestrian: retrigger a scored card whose rank is lower than the
-- previous scoring card.
SMODS.Joker {
    key = "pedestrian",
    sprite = "pedestrian.png",
    negative_sprite = "pedestrian_negative.png",
    rarity = 2,
    cost = 5,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    config = { extra = {} },
    loc_txt = {
        name = "Pedestrian",
        text = {
            "{C:attention}Retrigger{} scoring card if its ",
            "{C:attention}rank{} is {C:attention}lower{} than the",
            "{C:attention}previous{} scoring card",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = {} }
    end,
    calculate = function(self, card, context)
        if context.repetition and context.cardarea == G.play
            and context.scoring_hand and context.other_card then
            local current_index = nil
            for i, v in ipairs(context.scoring_hand) do
                if v == context.other_card then
                    current_index = i
                    break
                end
            end
            if current_index and current_index > 1 then
                local previous_card = context.scoring_hand[current_index - 1]
                if context.other_card:get_id() < previous_card:get_id() then
                    return { repetitions = 1 }
                end
            end
        end
    end,
}

-- pedrolino: sell this Joker to cut the current Blind's target by 90%.
-- All_in_Jest.ease_blind_requirement -> SMODS.adjust_blind_target.
SMODS.Joker {
    key = "pedrolino",
    sprite = "pedrolino.png",
    negative_sprite = "pedrolino_negative.png",
    rarity = 2,
    cost = 6,
    blueprint_compat = false,
    eternal_compat = false,
    perishable_compat = true,
    config = { extra = { blind_reduction = 90 } },
    loc_txt = {
        name = "Pedrolino",
        text = {
            "{C:money}Sell{} this card to reduce",
            "the {C:attention}score requirement{} of",
            "the current {C:attention}Blind{} by {C:attention}#1#%",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.blind_reduction } }
    end,
    calculate = function(self, card, context)
        if context.selling_self and not context.blueprint
            and G and G.current_blind_target then
            local target = tonumber(G.current_blind_target) or 0
            if target > 0 then
                SMODS.adjust_blind_target(
                    -1 * math.ceil(target * card.ability.extra.blind_reduction * 0.01))
            end
        end
    end,
}

-- pell_mel: XMult = 1 + 0.4 per unique suit in the played hand.
-- jest_get_unique_suits inlined as a base-suit set over full_hand.
SMODS.Joker {
    key = "pell_mel",
    sprite = "pell_mel.png",
    negative_sprite = "pell_mel_negative.png",
    rarity = 2,
    cost = 6,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    config = { extra = { xmult_mod = 0.4, xmult = 1 } },
    loc_txt = {
        name = "Pell Mel",
        text = {
            "Gives {X:mult,C:white}X#1#{} Mult",
            "per {C:attention}unique{} suit",
            "in {C:attention}played hand",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.xmult_mod, card.ability.extra.xmult } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            local suits = {}
            local unique = 0
            for _, c in ipairs(context.full_hand or {}) do
                local suit = c.base and c.base.suit
                if suit and not suits[suit] then
                    suits[suit] = true
                    unique = unique + 1
                end
            end
            card.ability.extra.xmult = 1 + unique * card.ability.extra.xmult_mod
            return { xmult = card.ability.extra.xmult }
        end
        if context.after then
            card.ability.extra.xmult = 1
        end
    end,
}

-- pellucid_joker: when an Editioned Joker is sold or destroyed, add a
-- random playing card with the same Edition to the deck.
-- Jest's aij_after_destroying_cards -> fork joker_type_destroyed.
SMODS.Joker {
    key = "pellucid_joker",
    sprite = "pellucid_joker.png",
    negative_sprite = "pellucid_joker_negative.png",
    rarity = 2,
    cost = 6,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    config = {},
    loc_txt = {
        name = "Pellucid Joker",
        text = {
            "When a {C:attention}Joker{} with an {C:dark_edition}Edition{} is",
            "{C:money}sold{} or {C:red}destroyed{}, add a",
            "random playing card with the",
            "same {C:dark_edition}Edition{} to deck",
        },
    },
    calculate = function(self, card, context)
        local function spawn(edition)
            local ranks = { 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14 }
            local suits = { "Hearts", "Diamonds", "Clubs", "Spades" }
            SMODS.add_card {
                set = "Playing",
                rank = ranks[SMODS.pseudorandom("pellucid_joker", 1, #ranks)],
                suit = suits[SMODS.pseudorandom("pellucid_joker", 1, #suits)],
                edition = edition,
                area = "deck",
            }
        end
        if context.selling_card and context.port and context.port.joker then
            local sold = context.card
            if sold and sold.edition then
                spawn(sold.edition)
                return { message = "Test!" }
            end
        end
        if context.joker_type_destroyed and context.card then
            local victim = context.card
            if victim.edition then
                spawn(victim.edition)
                return { message = "Test!" }
            end
        end
    end,
}

-- pengelding (Legendary): cards held in hand give XMult based on the
-- total sell value of all owned Jokers.
SMODS.Joker {
    key = "pengelding",
    sprite = "pengelding.png",
    negative_sprite = "pengelding_negative.png",
    soul_sprite = "pengelding_soul.png",
    rarity = 4,
    cost = 20,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    config = { extra = { threshold = 10, xmult_gain = 0.25 } },
    loc_txt = {
        name = "Pengelding",
        text = {
            "Cards held in hand give {X:mult,C:white}X#3#{}",
            "Mult, increases by {X:mult,C:white}X#1#{} per",
            "{C:money}$#2#{} of {C:money}sell value{} in all",
            "owned Jokers",
        },
    },
    loc_vars = function(self, info_queue, card)
        local total_sell = 0
        for _, j in ipairs(G.jokers or {}) do
            total_sell = total_sell + (j.sell_cost or 0)
        end
        local current_xmult = 1
            + math.floor(total_sell / card.ability.extra.threshold)
            * card.ability.extra.xmult_gain
        return {
            vars = {
                card.ability.extra.xmult_gain,
                card.ability.extra.threshold,
                current_xmult,
            },
        }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.hand
            and not context.end_of_round then
            local total_sell = 0
            for _, j in ipairs(G.jokers or {}) do
                total_sell = total_sell + (j.sell_cost or 0)
            end
            local xmult_val = 1
                + math.floor(total_sell / card.ability.extra.threshold)
                * card.ability.extra.xmult_gain
            if xmult_val > 1 then
                return { x_mult = xmult_val }
            end
        end
    end,
}

-- penny: Gold Seal cards have a 1 in 2 chance to retrigger.
-- in_pool Gold-Seal-in-deck gate dropped (availability nuance).
SMODS.Joker {
    key = "penny",
    sprite = "penny.png",
    negative_sprite = "penny_negative.png",
    rarity = 1,
    cost = 4,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    config = { extra = { odds = 2 } },
    loc_txt = {
        name = "Penny",
        text = {
            "Cards with {C:money}Gold Seal{} have a",
            "{C:green}#1# in #2#{} chance to {C:attention}retrigger",
        },
    },
    loc_vars = function(self, info_queue, card)
        local numerator, denominator =
            SMODS.get_probability_vars(card, 1, card.ability.extra.odds)
        return { vars = { numerator, denominator } }
    end,
    calculate = function(self, card, context)
        if context.repetition and context.other_card
            and context.other_card.seal == "gold" then
            local hit = SMODS.pseudorandom_probability(
                card, "penny", 1, card.ability.extra.odds)
            if hit then
                return { message = localize("k_again_ex"), repetitions = 1 }
            end
        end
    end,
}

-- petrushka: +Mult equal to the summed ranks of all scored cards.
SMODS.Joker {
    key = "petrushka",
    sprite = "petrushka.png",
    negative_sprite = "petrushka_negative.png",
    rarity = 3,
    cost = 8,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    config = {},
    loc_txt = {
        name = "Petrushka",
        text = {
            "Gives {C:mult}+Mult{} equal to",
            "the total {C:attention}rank{} of",
            "all {C:attention}scored cards{}",
            "{C:inactive,s:0.8}(A=14, K=13, Q=12, J=11)",
        },
    },
    calculate = function(self, card, context)
        if context.joker_main and context.scoring_hand then
            local rank_sum = 0
            for _, scoring_card in ipairs(context.scoring_hand) do
                local rank_value = scoring_card:get_id()
                if rank_value > 0 then
                    rank_sum = rank_sum + rank_value
                end
            end
            if rank_sum > 0 then
                return { mult = math.floor(rank_sum) }
            end
        end
    end,
}

-- pierrot: numbered cards held in hand give their Chip value.
-- get_chip_bonus has no view reader: PokermonPack card_chip_value pattern.
SMODS.Joker {
    key = "pierrot",
    sprite = "pierrot.png",
    negative_sprite = "pierrot_negative.png",
    rarity = 1,
    cost = 4,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    config = {},
    loc_txt = {
        name = "Pierrot",
        text = {
            "{C:attention}Numbered{} cards held in",
            "hand give their {C:chips}Chip{} value",
        },
    },
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.hand
            and not context.end_of_round and context.other_card then
            local view = context.other_card
            local data = view.card_data or {}
            local id = view.get_id and view:get_id() or tonumber(data.rank)
            if id and id >= 2 and id <= 10 then
                local val
                if data.enhancement == "stone" then
                    val = 50
                else
                    val = id
                end
                if data.enhancement == "bonus" then val = val + 30 end
                if data.modifier and data.modifier.edition == "foil" then
                    val = val + 50
                end
                val = val + (tonumber(data.Bonus) or tonumber(data.bonus)
                    or tonumber(data.chip_bonus) or 0)
                if val > 0 then
                    return { h_chips = val }
                end
            end
        end
    end,
}

-- pigpen: Chips = times the played hand was played this run x its level.
-- G.GAME.hands -> G.hand_play_counts / G.hand_stats via G.handlist index.
SMODS.Joker {
    key = "pigpen",
    sprite = "pigpen.png",
    negative_sprite = "pigpen_negative.png",
    rarity = 2,
    cost = 6,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    config = {},
    loc_txt = {
        name = "Pigpen",
        text = {
            "Gives {C:chips}Chips{} equal to the number",
            "of times {C:attention}poker hand{} has been",
            "played, multiplied by its {C:attention}level",
        },
    },
    calculate = function(self, card, context)
        if context.joker_main and context.scoring_name
            and G and G.handlist then
            for i, name in ipairs(G.handlist) do
                if name == context.scoring_name then
                    local played = tonumber(G.hand_play_counts
                        and G.hand_play_counts[i]) or 0
                    local level = tonumber(G.hand_stats
                        and G.hand_stats[i] and G.hand_stats[i].level) or 1
                    return { chips = played * level }
                end
            end
        end
    end,
}

-- pinhead: earn $8 if the Blind is beaten in a single hand
-- (calc_dollar_bonus; hands played read via G:get_round_hands_played).
SMODS.Joker {
    key = "pinhead",
    sprite = "pinhead.png",
    negative_sprite = "pinhead_negative.png",
    rarity = 2,
    cost = 8,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    config = { extra = { money = 8 } },
    loc_txt = {
        name = "Pinhead",
        text = {
            "Earn {C:money}$#1#{} if {C:attention}Blind{} is",
            "beaten in a {C:attention}single hand{}",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.money } }
    end,
    calc_dollar_bonus = function(self, card)
        if G and G.get_round_hands_played
            and G:get_round_hands_played() == 1 then
            return card.ability.extra.money
        end
    end,
}

-- pipine (Legendary): +5 discards per round while held.
-- round_resets.discards / ease_discard -> direct G.discards writes
-- (immediate on pickup/removal, topped up at each setting_blind).
SMODS.Joker {
    key = "pipine",
    sprite = "pipine.png",
    negative_sprite = "pipine_negative.png",
    soul_sprite = "pipine_soul.png",
    rarity = 4,
    cost = 20,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    config = { discards = 5 },
    loc_txt = {
        name = "Pipine",
        text = {
            "{C:red}+#1#{} discards per round",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.discards } }
    end,
    add_to_deck = function(self, card, from_debuff)
        if G then
            G.discards = (tonumber(G.discards) or 0) + card.ability.discards
        end
    end,
    remove_from_deck = function(self, card, from_debuff)
        if G then
            G.discards = math.max(0,
                (tonumber(G.discards) or 0) - card.ability.discards)
        end
    end,
    calculate = function(self, card, context)
        if context.setting_blind and G then
            G.discards = (tonumber(G.discards) or 0) + card.ability.discards
        end
    end,
}

-- plain_jane: scored unenhanced cards give +5 Mult.
-- in_pool enhanced-card tally gate dropped (availability nuance).
SMODS.Joker {
    key = "plain_jane",
    sprite = "plain_jane.png",
    negative_sprite = "plain_jane_negative.png",
    rarity = 1,
    cost = 5,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    config = { extra = { mult = 5 } },
    loc_txt = {
        name = "Plain Jane",
        text = {
            "Scored {C:attention}unenhanced{}",
            "cards give {C:mult}+#1#{} Mult",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult } }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play
            and context.other_card then
            local enh = context.other_card.enhancement
            if not enh or enh == "base" then
                return { mult = card.ability.extra.mult }
            end
        end
    end,
}

-- plain_packaging: +20 Mult, -5 Mult whenever a Joker is sold or
-- destroyed; self-destructs instead of dropping to 0.
-- Jest's aij_after_destroying_cards -> fork joker_type_destroyed;
-- SMODS.scale_card / destroy_cards inlined.
SMODS.Joker {
    key = "plain_packaging",
    sprite = "plain_packaging.png",
    negative_sprite = "plain_packaging_negative.png",
    rarity = 1,
    cost = 5,
    blueprint_compat = true,
    eternal_compat = false,
    perishable_compat = true,
    config = { extra = { mult = 20, mult_decrease = 5 } },
    loc_txt = {
        name = "Plain Packaging",
        text = {
            "{C:mult}+#1#{} Mult, {C:mult}-#2#{} Mult when",
            "a {C:attention}Joker{} is {C:money}sold{}",
            "or {C:red}destroyed{}",
        },
    },
    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                card.ability.extra.mult,
                card.ability.extra.mult_decrease,
            },
        }
    end,
    calculate = function(self, card, context)
        if not context.blueprint then
            local times = 0
            if context.selling_card and context.port
                and context.port.joker then
                times = 1
            elseif context.joker_type_destroyed then
                times = 1
            end
            for _ = 1, times do
                if (card.ability.extra.mult
                    - card.ability.extra.mult_decrease) <= 0 then
                    SMODS.destroy_joker(card)
                    return { message = "Empty!" }
                else
                    card.ability.extra.mult = card.ability.extra.mult
                        - card.ability.extra.mult_decrease
                end
            end
            if times > 0 then return { message = "-5 Mult" } end
        end
        if context.joker_main then
            return { mult = card.ability.extra.mult }
        end
    end,
}

-- plutonium: if the played hand is High Card, retrigger all
-- scoring cards 2 times.
SMODS.Joker {
    key = "plutonium",
    sprite = "plutonium.png",
    negative_sprite = "plutonium_negative.png",
    rarity = 1,
    cost = 4,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    config = { extra = { retriggers = 2 } },
    loc_txt = {
        name = "Plutonium",
        text = {
            "If played hand is {C:attention}High Card{},",
            "retrigger all scoring cards{}",
            "{C:attention}#1#{} times",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.retriggers } }
    end,
    calculate = function(self, card, context)
        if context.repetition and context.cardarea == G.play
            and context.scoring_name == "High Card" then
            return { repetitions = card.ability.extra.retriggers }
        end
    end,
}

-- polybius: gives the Chips and Mult of every other hand type
-- contained within the played hand, at their current levels.
-- G.GAME.hands[k].chips/mult -> G:get_hand_display_stats(index).
SMODS.Joker {
    key = "polybius",
    sprite = "polybius.png",
    negative_sprite = "polybius_negative.png",
    rarity = 3,
    cost = 8,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    config = {},
    loc_txt = {
        name = "Polybius",
        text = {
            "Gives the {C:mult}Mult{} and {C:chips}Chips{} of",
            "all hand types {C:attention}contained{}",
            "{C:attention}within{} played hand",
        },
    },
    calculate = function(self, card, context)
        if context.joker_main and context.scoring_name
            and context.poker_hands and G and G.handlist
            and G.get_hand_display_stats then
            local chip_total = 0
            local mult_total = 0
            for k, v in pairs(context.poker_hands) do
                if k ~= context.scoring_name and next(v) then
                    for i, name in ipairs(G.handlist) do
                        if name == k then
                            local _, c, m = G:get_hand_display_stats(i)
                            chip_total = chip_total + (tonumber(c) or 0)
                            mult_total = mult_total + (tonumber(m) or 0)
                            break
                        end
                    end
                end
            end
            if chip_total > 0 and mult_total > 0 then
                return { chips = chip_total, mult = mult_total }
            elseif chip_total > 0 then
                return { chips = chip_total }
            elseif mult_total > 0 then
                return { mult = mult_total }
            end
        end
    end,
}

-- pompey (Legendary): X1.5 Mult per Joker to the right, itself included.
SMODS.Joker {
    key = "pompey",
    sprite = "pompey.png",
    negative_sprite = "pompey_negative.png",
    soul_sprite = "pompey_soul.png",
    rarity = 4,
    cost = 20,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    config = { extra = { xmult = 1.5 } },
    loc_txt = {
        name = "Pompey",
        text = {
            "{X:mult,C:white}X#1#{} Mult per {C:attention}Joker{}",
            "to the {C:attention}right{},",
            "Pompey included",
            "{C:inactive}(Currently{} {X:mult,C:white}X#2#{}{C:inactive} Mult){}",
        },
    },
    loc_vars = function(self, info_queue, card)
        local jokers_to_right = 0
        local me = card
        for i, j in ipairs(G.jokers or {}) do
            if j == me then
                jokers_to_right = #G.jokers - i + 1
                break
            end
        end
        return {
            vars = {
                card.ability.extra.xmult,
                math.max(card.ability.extra.xmult,
                    jokers_to_right * card.ability.extra.xmult),
            },
        }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            local me = context.blueprint_card or card
            local jokers_to_right = 0
            for i, j in ipairs(G.jokers or {}) do
                if j == me then
                    jokers_to_right = #G.jokers - i + 1
                    break
                end
            end
            local final_xmult = math.max(card.ability.extra.xmult,
                jokers_to_right * card.ability.extra.xmult)
            if final_xmult > 1 then
                return { xmult = final_xmult }
            end
        end
    end,
}

-- poppins: earn $1 per unique poker hand contained within the
-- played hand (dollar_buffer boilerplate dropped, dollars return).
SMODS.Joker {
    key = "poppins",
    sprite = "poppins.png",
    negative_sprite = "poppins_negative.png",
    rarity = 1,
    cost = 5,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    config = { extra = { dollars = 1 } },
    loc_txt = {
        name = "Poppins",
        text = {
            "Earn {C:money}$#1#{} per {C:attention}unique{}",
            "poker hand {C:attention}contained{}",
            "{C:attention}within{} played hand",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.dollars } }
    end,
    calculate = function(self, card, context)
        if context.before and context.poker_hands then
            local count = 0
            for _, contained_hands in pairs(context.poker_hands) do
                if next(contained_hands) then
                    count = count + 1
                end
            end
            if count > 0 then
                return { dollars = count * card.ability.extra.dollars }
            end
        end
    end,
}

-- postcard_from_perdition_trail: scoring cards with Seals lose the
-- Seal and permanently gain X0.5 Mult (fork perma field on the card).
-- in_pool seal-in-deck gate dropped (availability nuance).
SMODS.Joker {
    key = "postcard_from_perdition_trail",
    sprite = "postcard_from_perdition_trail.png",
    negative_sprite = "postcard_from_perdition_trail_negative.png",
    rarity = 3,
    cost = 8,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    config = { extra = { perma_mult = 0.5 } },
    loc_txt = {
        name = "Postcard from Perdition Trail",
        text = {
            "Scoring cards with {C:attention}seals{} have",
            "their seals {C:red}removed{}, then",
            "{C:attention}permanently{} gain {X:mult,C:white}X#1#{} Mult",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.perma_mult } }
    end,
    calculate = function(self, card, context)
        if context.before and not context.blueprint
            and context.scoring_hand then
            for _, v in ipairs(context.scoring_hand) do
                if v.seal ~= nil then
                    if v.set_seal then
                        v:set_seal(nil)
                    elseif v.card_data then
                        v.card_data.seal = nil
                    end
                    local current = SMODS.get_perma(v, "perma_x_mult") or 0
                    SMODS.set_perma(v, "perma_x_mult",
                        current + card.ability.extra.perma_mult)
                end
            end
        end
    end,
}

-- pour_one_out: create a random consumable every 15 discarded cards.
-- Fork rolls per kind (CryptidPack pattern): Tarot/Planet/Spectral.
SMODS.Joker {
    key = "pour_one_out",
    sprite = "pour_one_out.png",
    negative_sprite = "pour_one_out_negative.png",
    rarity = 2,
    cost = 6,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    config = { extra = { discards = 15, discards_remaining = 15 } },
    loc_txt = {
        name = "Pour One Out",
        text = {
            "Create a random {C:attention}consumable{} every",
            "{C:attention}#1#{} {C:inactive}[#2#]{} discarded cards",
        },
    },
    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                card.ability.extra.discards,
                card.ability.extra.discards_remaining,
            },
        }
    end,
    calculate = function(self, card, context)
        if context.discard and not context.blueprint then
            if card.ability.extra.discards_remaining <= 1 then
                card.ability.extra.discards_remaining =
                    card.ability.extra.discards
                if G and G.random_consumable_id_of_kind
                    and G:can_add_consumable() then
                    local kinds = { "tarot", "planet", "spectral" }
                    local set_for_kind = {
                        tarot = "Tarot", planet = "Planet",
                        spectral = "Spectral",
                    }
                    local start = SMODS.pseudorandom("pour_one_out", 1, #kinds)
                    for n = 0, #kinds - 1 do
                        local kind = kinds[((start - 1 + n) % #kinds) + 1]
                        local id = G:random_consumable_id_of_kind(kind)
                        if id then
                            SMODS.add_card { set = set_for_kind[kind], key = id }
                            break
                        end
                    end
                end
                return { message = "+Consumable!" }
            else
                card.ability.extra.discards_remaining =
                    card.ability.extra.discards_remaining - 1
            end
        end
    end,
}

-- profile: scoring cards adjacent to a face card give +5 Mult.
SMODS.Joker {
    key = "profile",
    sprite = "profile.png",
    negative_sprite = "profile_negative.png",
    rarity = 1,
    cost = 4,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    config = { extra = { mult = 5 } },
    loc_txt = {
        name = "Profile",
        text = {
            "Scoring cards {C:attention}adjacent{} to",
            "{C:attention}face cards{} give {C:mult}+#1#{} Mult",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult } }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play
            and context.scoring_hand and context.other_card then
            for i = 1, #context.scoring_hand do
                if context.scoring_hand[i] == context.other_card then
                    local left_card = context.scoring_hand[i - 1]
                    local right_card = context.scoring_hand[i + 1]
                    local left_is_face = left_card and left_card:is_face()
                    local right_is_face = right_card and right_card:is_face()
                    if left_is_face or right_is_face then
                        return { mult = card.ability.extra.mult }
                    end
                end
            end
        end
    end,
}

-- propaganda: cards of the most common suit in the full deck give
-- +5 Mult when scored (live tally via G:count_cards_in_full_deck).
SMODS.Joker {
    key = "propaganda",
    sprite = "propaganda.png",
    negative_sprite = "propaganda_negative.png",
    rarity = 2,
    cost = 5,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    config = { extra = { mult = 5 } },
    loc_txt = {
        name = "Propaganda",
        text = {
            "Cards of the {C:attention}most",
            "{C:attention}common{} suit in your {C:attention}deck{}",
            "give {C:mult}+#2#{} Mult when scored",
            "{C:inactive}(Currently: {C:attention}#1#{C:inactive})",
        },
    },
    loc_vars = function(self, info_queue, card)
        local target_suit = "None"
        if G and G.count_cards_in_full_deck then
            local max_count = 0
            for _, suit in ipairs({ "Spades", "Hearts", "Clubs", "Diamonds" }) do
                local count = G:count_cards_in_full_deck(function(c)
                    return c.suit == suit
                end)
                if count > max_count then
                    max_count = count
                    target_suit = suit
                end
            end
        end
        return { vars = { target_suit, card.ability.extra.mult } }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play
            and context.other_card and G and G.count_cards_in_full_deck then
            local max_count = 0
            local target_suit = ""
            for _, suit in ipairs({ "Spades", "Hearts", "Clubs", "Diamonds" }) do
                local count = G:count_cards_in_full_deck(function(c)
                    return c.suit == suit
                end)
                if count > max_count then
                    max_count = count
                    target_suit = suit
                end
            end
            if target_suit ~= ""
                and context.other_card:is_suit(target_suit) then
                return { mult = card.ability.extra.mult }
            end
        end
    end,
}

-- protophanes: played cards sharing the rank of the last (bottom)
-- card of the deck give X1.5 Mult. Deck-peek preview UI dropped;
-- the rank read is G.deck.cards[1] as on PC.
SMODS.Joker {
    key = "protophanes",
    sprite = "protophanes.png",
    negative_sprite = "protophanes_negative.png",
    soul_sprite = "protophanes_soul.png",
    rarity = 2,
    cost = 6,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    config = { extra = { xmult = 1.5 }, future_sense = "1" },
    loc_txt = {
        name = "Protophanes",
        text = {
            "{C:attention}Reveal{} the last card in",
            "your {C:attention}deck",
            "{C:attention}Cards{} that share its {C:attention}rank",
            "give {X:mult,C:white}X#1#{} Mult",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.xmult } }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play
            and context.other_card and G and G.deck
            and G.deck.cards and #G.deck.cards > 0 then
            local next_card = G.deck.cards[1]
            if next_card and next_card.rank
                and context.other_card:get_id() == next_card.rank then
                return { xmult = card.ability.extra.xmult }
            end
        end
    end,
}

-- prototype_credits_joker: credits Joker, never in pool (badge drops).
SMODS.Joker {
    key = "prototype_credits_joker",
    sprite = "prototype_credits_joker.png",
    negative_sprite = "prototype_credits_joker_negative.png",
    rarity = 1,
    cost = 4,
    blueprint_compat = false,
    eternal_compat = false,
    perishable_compat = true,
    config = {},
    loc_txt = {
        name = "Prototype",
        text = {
            "{C:inactive}\"Skibby Dee\"",
        },
    },
    in_pool = function(self, args)
        return false
    end,
}

-- public_bathroom: gains +2 Mult per scored 2 in a Flush.
SMODS.Joker {
    key = "public_bathroom",
    sprite = "public_bathroom.png",
    negative_sprite = "public_bathroom_negative.png",
    rarity = 1,
    cost = 4,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    config = { extra = { mult = 0, mult_mod = 2 } },
    loc_txt = {
        name = "Public Bathroom",
        text = {
            "This Joker gains {C:mult}+#1#{} Mult",
            "per scored {C:attention}2{} in a {C:attention}Flush{}",
            "{C:inactive}(Currently {C:mult}+#2#{C:inactive} Mult)",
        },
    },
    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                card.ability.extra.mult_mod,
                card.ability.extra.mult,
            },
        }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play
            and not context.blueprint and context.other_card then
            if context.poker_hands and next(context.poker_hands["Flush"])
                and context.other_card:get_id() == 2 then
                card.ability.extra.mult = card.ability.extra.mult
                    + card.ability.extra.mult_mod
                return { message = localize("k_upgrade_ex") }
            end
        end
        if context.joker_main then
            if card.ability.extra.mult > 0 then
                return { mult = card.ability.extra.mult }
            end
        end
    end,
}

-- punk_joker: if the hand scores a Wild Card, turn a random
-- unenhanced scored card into a Wild Card (node set_enhancement).
-- in_pool Wild-in-deck gate dropped (availability nuance).
SMODS.Joker {
    key = "punk_joker",
    sprite = "punk_joker.png",
    negative_sprite = "punk_joker_negative.png",
    rarity = 1,
    cost = 5,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    config = {},
    loc_txt = {
        name = "Punk Joker",
        text = {
            "If hand scores a",
            "{C:attention}Wild Card{}, turn a random",
            "unenhanced scored card",
            "into a {C:attention}Wild Card{}",
        },
    },
    calculate = function(self, card, context)
        if context.before and context.scoring_hand then
            local has_wild = false
            for _, scoring_card in ipairs(context.scoring_hand) do
                if scoring_card.enhancement == "wild" then
                    has_wild = true
                    break
                end
            end
            if has_wild then
                local eligible_targets = {}
                for _, card_in_hand in ipairs(context.scoring_hand) do
                    local enh = card_in_hand.enhancement
                    if not enh or enh == "base" then
                        eligible_targets[#eligible_targets + 1] = card_in_hand
                    end
                end
                if #eligible_targets > 0 then
                    local target_card = pseudorandom_element(
                        eligible_targets, pseudoseed("punk"))
                    if target_card then
                        if target_card.set_enhancement then
                            target_card:set_enhancement("wild")
                        elseif target_card.card_data then
                            target_card.card_data.enhancement = "wild"
                        end
                    end
                    return { message = "Wild!" }
                end
            end
        end
    end,
}

-- quadrangled_joker: adds the Chips and Mult of Four of a Kind
-- (at its current level) if the played hand has exactly 4 cards.
SMODS.Joker {
    key = "quadrangled_joker",
    sprite = "quadrangled_joker.png",
    negative_sprite = "quadrangled_joker_negative.png",
    rarity = 2,
    cost = 8,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    config = { extra = {} },
    loc_txt = {
        name = "Quadrangled Joker",
        text = {
            "Adds the {C:chips}Chips{} and {C:mult}Mult{} of",
            "{C:attention}Four of a Kind{} if played hand",
            "has exactly {C:attention}4{} cards",
            "{C:inactive,s:0.8}(Currently {C:chips,s:0.8}+#1#{}{C:inactive,s:0.8} Chips, {C:mult,s:0.8}+#2#{}{C:inactive,s:0.8} Mult)",
        },
    },
    loc_vars = function(self, info_queue, card)
        local chips, mult = 0, 0
        if G and G.handlist and G.get_hand_display_stats then
            for i, name in ipairs(G.handlist) do
                if name == "Four of a Kind" then
                    local _, c, m = G:get_hand_display_stats(i)
                    chips = tonumber(c) or 0
                    mult = tonumber(m) or 0
                    break
                end
            end
        end
        return { vars = { chips, mult } }
    end,
    calculate = function(self, card, context)
        if context.joker_main and context.full_hand
            and #context.full_hand == 4
            and G and G.handlist and G.get_hand_display_stats then
            for i, name in ipairs(G.handlist) do
                if name == "Four of a Kind" then
                    local _, c, m = G:get_hand_display_stats(i)
                    return {
                        chips = tonumber(c) or 0,
                        mult = tonumber(m) or 0,
                    }
                end
            end
        end
    end,
}

-- quantum_foam: unenhanced cards have a 1 in 2 chance to retrigger.
SMODS.Joker {
    key = "quantum_foam",
    sprite = "quantum_foam.png",
    negative_sprite = "quantum_foam_negative.png",
    rarity = 1,
    cost = 4,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    config = { extra = { odds = 2 } },
    loc_txt = {
        name = "Quantum Foam",
        text = {
            "{C:attention}Unenhanced{} cards have a",
            "{C:green}#1# in #2#{} chance to {C:attention}retrigger",
        },
    },
    loc_vars = function(self, info_queue, card)
        local numerator, denominator = SMODS.get_probability_vars(
            card, 1, card.ability.extra.odds, "quantum_foam")
        return { vars = { numerator, denominator } }
    end,
    calculate = function(self, card, context)
        if context.repetition and context.cardarea == G.play
            and context.other_card then
            local enh = context.other_card.enhancement
            if not enh or enh == "base" then
                local hit = SMODS.pseudorandom_probability(
                    card, "quantum", 1, card.ability.extra.odds)
                if hit then
                    return { repetitions = 1 }
                end
            end
        end
    end,
}

-- quark: level up Three of a Kind when the scored hand is exactly
-- three cards of one rank in three different suits.
SMODS.Joker {
    key = "quark",
    sprite = "quark.png",
    negative_sprite = "quark_negative.png",
    rarity = 2,
    cost = 7,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    config = {},
    loc_txt = {
        name = "Quark",
        text = {
            "Level up {C:attention}Three of a Kind{} if",
            "scored hand is exactly {C:attention}three{}",
            "cards of the {C:attention}same rank",
            "but {C:attention}different suits{}",
        },
    },
    calculate = function(self, card, context)
        if context.before and context.scoring_hand
            and context.poker_hands
            and next(context.poker_hands["Three of a Kind"])
            and #context.scoring_hand == 3 then
            local suits_present = {}
            local all_different_suits = true
            for _, scoring_card in ipairs(context.scoring_hand) do
                if scoring_card.base.suit then
                    if suits_present[scoring_card.base.suit] then
                        all_different_suits = false
                        break
                    else
                        suits_present[scoring_card.base.suit] = true
                    end
                else
                    all_different_suits = false
                    break
                end
            end
            if all_different_suits and G and G.handlist
                and G.upgrade_hand_level_at_index then
                for i, name in ipairs(G.handlist) do
                    if name == "Three of a Kind" then
                        G:upgrade_hand_level_at_index(i)
                        break
                    end
                end
                return { message = localize("k_upgrade_ex") }
            end
        end
    end,
}

-- queen_bee: scoring Queens give XMult per 6 held in hand.
SMODS.Joker {
    key = "queen_bee",
    sprite = "queen_bee.png",
    negative_sprite = "queen_bee_negative.png",
    rarity = 2,
    cost = 6,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    config = { extra = { xmult_mod = 0.1 } },
    loc_txt = {
        name = "Queen Bee",
        text = {
            "Scoring {C:attention}Queens{} give {X:mult,C:white}X#1#{}",
            "Mult per {C:attention}6{} held in hand",
            "{C:inactive}(Will give {X:mult,C:white}X#2#{} {C:inactive}Mult)",
        },
    },
    loc_vars = function(self, info_queue, card)
        local sixes = 0
        if G and G.hand and G.hand.card_nodes then
            for _, held_card in ipairs(G.hand.card_nodes) do
                if held_card:get_id() == 6 and not held_card.debuff then
                    sixes = sixes + 1
                end
            end
        end
        local current_xmult = 1 + (sixes * card.ability.extra.xmult_mod)
        return {
            vars = {
                card.ability.extra.xmult_mod,
                current_xmult,
            },
        }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play
            and context.other_card
            and context.other_card:get_id() == 12 then
            local sixes = 0
            if G and G.hand and G.hand.card_nodes then
                for _, held_card in ipairs(G.hand.card_nodes) do
                    if held_card:get_id() == 6 and not held_card.debuff then
                        sixes = sixes + 1
                    end
                end
            end
            local total = 1 + (sixes * card.ability.extra.xmult_mod)
            if total > 1 then
                return { x_mult = total }
            end
        end
    end,
}

-- quicksilver: if the played hand is a Pair, retrigger all
-- scoring cards once.
SMODS.Joker {
    key = "quicksilver",
    sprite = "quicksilver.png",
    negative_sprite = "quicksilver_negative.png",
    rarity = 1,
    cost = 4,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    config = { extra = {} },
    loc_txt = {
        name = "Quicksilver",
        text = {
            "If played hand is {C:attention}Pair{},",
            "retrigger all scoring cards{}",
        },
    },
    calculate = function(self, card, context)
        if context.repetition and context.cardarea == G.play
            and context.scoring_name == "Pair" then
            return { repetitions = 1 }
        end
    end,
}

-- rattling_snow_credits_joker: credits Joker, never in pool (badge drops).
SMODS.Joker {
    key = "rattling_snow_credits_joker",
    sprite = "rattling_snow_credits_joker.png",
    negative_sprite = "rattling_snow_credits_joker_negative.png",
    rarity = 1,
    cost = 4,
    blueprint_compat = false,
    eternal_compat = false,
    config = {},
    loc_txt = {
        name = "RattlingSnow353",
        text = {
            "{C:inactive}\"Jack of all trades, master of",
            "{C:inactive}none, though oftentimes better",
            "{C:inactive}than a master of one.\"",
        },
    },
    in_pool = function(self, args)
        return false
    end,
}

-- realty_sign: playing a Full House raises this Joker's sell
-- value by $3 (instance sell_cost write, CryptidPack idiom).
SMODS.Joker {
    key = "realty_sign",
    sprite = "realty_sign.png",
    negative_sprite = "realty_sign_negative.png",
    rarity = 1,
    cost = 5,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    config = { extra = { sell_increase = 3 } },
    loc_txt = {
        name = "Realty Sign",
        text = {
            "Playing a {C:attention}Full House{}",
            "increases the {C:money}sell value{}",
            "of this Joker by {C:money}$#1#{}",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.sell_increase } }
    end,
    calculate = function(self, card, context)
        if context.before and context.scoring_name == "Full House"
            and not context.blueprint then
            card.sell_cost = (tonumber(card.sell_cost) or 0)
                + card.ability.extra.sell_increase
            return { message = "Value Up!" }
        end
    end,
}

-- red_joker: gains +1 Mult per card scored; resets when a card
-- that was previously scored is scored again. Scored-card history
-- is kept as a set of card_data tables on this Joker's ability
-- (PC marks the cards themselves, keyed by this Joker's sort_id).
SMODS.Joker {
    key = "red_joker",
    sprite = "red_joker.png",
    negative_sprite = "red_joker_negative.png",
    rarity = 1,
    cost = 4,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    config = { extra = { mult = 0, mult_mod = 1 } },
    loc_txt = {
        name = "Red Joker",
        text = {
            "Gains {C:mult}+#2#{} Mult per card scored,",
            "{C:attention}resets{} when playing a card",
            "that was previously scored",
            "{C:inactive}(Card history clears on reset){}",
            "{C:inactive}(Currently {C:mult}+#1#{C:inactive} Mult)",
        },
    },
    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                card.ability.extra.mult,
                card.ability.extra.mult_mod,
            },
        }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play
            and not context.blueprint and context.other_card then
            card.ability.extra.seen =
                card.ability.extra.seen or {}
            local seen = card.ability.extra.seen
            local data = context.other_card.card_data
                or context.other_card
            if not seen[data] then
                seen[data] = true
                card.ability.extra.mult = card.ability.extra.mult
                    + card.ability.extra.mult_mod
            else
                card.ability.extra.seen = {}
                card.ability.extra.mult = 0
                return { message = localize("k_reset") }
            end
        end
        if context.joker_main then
            if card.ability.extra.mult > 0 then
                return { mult = card.ability.extra.mult }
            end
        end
    end,
}

-- remina: when a Small or Big Blind is selected, destroy all held
-- Planet cards and gain their hands' level-up Chips/Mult
-- (Chips/Mult-type Planets pay double, as on PC).
SMODS.Joker {
    key = "remina",
    sprite = "remina.png",
    negative_sprite = "remina_negative.png",
    rarity = 3,
    cost = 8,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    config = { extra = { mult = 0, chips = 0 } },
    loc_txt = {
        name = "Remina",
        text = {
            "When {C:attention}Small Blind{} or {C:attention}Big Blind",
            "is selected, this Joker",
            "{C:red}destroys{} all {C:planet}Planet Cards{}",
            "in your {C:attention}consumable{} area and",
            "gains their {C:chips}Chips{} and {C:mult}Mult{}",
            "{C:inactive,s:0.8}(Currently {C:chips,s:0.8}+#2#{} {C:inactive,s:0.8}Chips, {C:mult,s:0.8}+#1#{C:inactive,s:0.8} Mult)",
        },
    },
    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                card.ability.extra.mult,
                card.ability.extra.chips,
            },
        }
    end,
    calculate = function(self, card, context)
        if context.setting_blind and not context.blueprint
            and G and G.current_blind_index ~= 3 then
            local list = G.consumables or G.consumeables or {}
            for i = #list, 1, -1 do
                local cons = list[i]
                if cons and tostring(cons.kind or ""):lower() == "planet" then
                    local hand = cons.hand
                        or (cons.config and cons.config.hand_type)
                    if G.remove_consumable_at then
                        G:remove_consumable_at(i)
                    end
                    if hand and G.handlist and G.hand_stats then
                        for hi, name in ipairs(G.handlist) do
                            if name == hand then
                                local stats = G.hand_stats[hi] or {}
                                local l_chips = tonumber(
                                    stats.chips_per_level) or 0
                                local l_mult = tonumber(
                                    stats.mult_per_level) or 0
                                local cfg = cons.config or {}
                                if cfg.mult then
                                    card.ability.extra.mult =
                                        card.ability.extra.mult + l_mult * 2
                                elseif cfg.chips then
                                    card.ability.extra.chips =
                                        card.ability.extra.chips + l_chips * 2
                                else
                                    card.ability.extra.mult =
                                        card.ability.extra.mult + l_mult
                                    card.ability.extra.chips =
                                        card.ability.extra.chips + l_chips
                                end
                                break
                            end
                        end
                    end
                end
            end
        end
        if context.joker_main then
            return {
                mult = card.ability.extra.mult,
                chips = card.ability.extra.chips,
            }
        end
    end,
}

-- richie_rich: gain 10% of current money at end of round
-- (dollar_buffer boilerplate dropped, dollars return).
SMODS.Joker {
    key = "richie_rich",
    sprite = "richie_rich.png",
    negative_sprite = "richie_rich_negative.png",
    rarity = 2,
    cost = 8,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    config = { extra = { dollars = 0, xdollars = 0.1 } },
    loc_txt = {
        name = "Richie Rich",
        text = {
            "{X:money,C:white}X#1#{} to your {C:money}money{}",
            "at end of round",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.xdollars + 1 } }
    end,
    calculate = function(self, card, context)
        if context.end_of_round then
            card.ability.extra.dollars = math.floor(
                (tonumber(G.money) or 0) * card.ability.extra.xdollars)
            if card.ability.extra.dollars > 0 then
                return {
                    dollars = card.ability.extra.dollars,
                    message = "X1.1",
                }
            end
        end
    end,
}

-- rising_sun: retrigger the first and last scored cards on the
-- first and last hand of the round. The fork decrements its
-- counters after scoring, so during scoring the last hand reads
-- G.hands == 1 and the first hand reads 0 hands played.
SMODS.Joker {
    key = "rising_sun",
    sprite = "rising_sun.png",
    negative_sprite = "rising_sun_negative.png",
    rarity = 1,
    cost = 4,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    config = { extra = { retriggers = 1 } },
    loc_txt = {
        name = "Rising Sun",
        text = {
            "Retrigger {C:attention}first{} and {C:attention}last{}",
            "scored cards on {C:attention}first{} and",
            "{C:attention}last hand{} of round",
        },
    },
    calculate = function(self, card, context)
        if context.repetition and context.cardarea == G.play
            and context.scoring_hand and context.other_card then
            local first_hand = G and G.get_round_hands_played
                and G:get_round_hands_played() == 0
            local last_hand = (tonumber(G.hands) or 99) <= 1
            if first_hand or last_hand then
                if context.other_card == context.scoring_hand[1]
                    or context.other_card
                        == context.scoring_hand[#context.scoring_hand] then
                    return {
                        message = localize("k_again_ex"),
                        repetitions = card.ability.extra.retriggers,
                    }
                end
            end
        end
    end,
}

-- rock_n_roll_clown: scoring cards give +1 Chips per combined
-- level of all visible poker hands.
SMODS.Joker {
    key = "rock_n_roll_clown",
    sprite = "rock_n_roll_clown.png",
    negative_sprite = "rock_n_roll_clown_negative.png",
    rarity = 1,
    cost = 5,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    config = { extra = { chips_per_level = 1 } },
    loc_txt = {
        name = "Rock n' Roll Clown",
        text = {
            "Scoring cards give {C:chips}+#1#{} Chips",
            "per {C:attention}level{} of {C:attention}all{} poker",
            "hands {C:attention}combined",
            "{C:inactive}(Currently {C:chips}+#2#{C:inactive} Chips)",
        },
    },
    loc_vars = function(self, info_queue, card)
        local total_level = 0
        if G and G.handlist and G.hand_stats then
            for i in ipairs(G.handlist) do
                local visible = not G.is_hand_stats_visible
                    or G:is_hand_stats_visible(i)
                if visible then
                    total_level = total_level
                        + (tonumber(G.hand_stats[i]
                            and G.hand_stats[i].level) or 1)
                end
            end
        end
        return {
            vars = {
                card.ability.extra.chips_per_level,
                total_level * card.ability.extra.chips_per_level,
            },
        }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            local total_level = 0
            if G and G.handlist and G.hand_stats then
                for i in ipairs(G.handlist) do
                    local visible = not G.is_hand_stats_visible
                        or G:is_hand_stats_visible(i)
                    if visible then
                        total_level = total_level
                            + (tonumber(G.hand_stats[i]
                                and G.hand_stats[i].level) or 1)
                    end
                end
            end
            if total_level > 0 then
                return {
                    chips = total_level * card.ability.extra.chips_per_level,
                }
            end
        end
    end,
}

-- rodeo_clown: gains +5 Mult if the Blind is defeated on the
-- final hand of the round.
SMODS.Joker {
    key = "rodeo_clown",
    sprite = "rodeo_clown.png",
    negative_sprite = "rodeo_clown_negative.png",
    rarity = 1,
    cost = 5,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    config = { extra = { mult = 0, mult_mod = 5 } },
    loc_txt = {
        name = "Rodeo Clown",
        text = {
            "This Joker gains {C:mult}+#1#{} Mult",
            "if {C:attention}Blind{} is defeated on",
            "{C:attention}final hand{} of round",
            "{C:inactive}(Currently {C:mult}+#2#{C:inactive} Mult)",
        },
    },
    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                card.ability.extra.mult_mod,
                card.ability.extra.mult,
            },
        }
    end,
    calculate = function(self, card, context)
        if context.end_of_round and context.game_over == false
            and not context.blueprint then
            if (tonumber(G.hands) or 1) <= 0 then
                card.ability.extra.mult = card.ability.extra.mult
                    + card.ability.extra.mult_mod
            end
        end
        if context.joker_main then
            return { mult = card.ability.extra.mult }
        end
    end,
}

-- rubberhose: +10 Mult if the played hand contains only dark
-- suits or only light suits.
SMODS.Joker {
    key = "rubberhose",
    sprite = "rubberhose.png",
    negative_sprite = "rubberhose_negative.png",
    rarity = 1,
    cost = 5,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    config = { extra = { mult = 10 } },
    loc_txt = {
        name = "Rubberhose",
        text = {
            "{C:mult}+#1#{} Mult if {C:attention}played hand{}",
            "contains only {C:spades}Dark Suits{} or",
            "only {C:hearts}Light Suits",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult } }
    end,
    calculate = function(self, card, context)
        if context.joker_main and context.full_hand then
            local dark, light = 0, 0
            for _, v in ipairs(context.full_hand) do
                if v:is_suit("Spades") or v:is_suit("Clubs") then
                    dark = dark + 1
                end
                if v:is_suit("Hearts") or v:is_suit("Diamonds") then
                    light = light + 1
                end
            end
            if (dark > 0 and light == 0) or (light > 0 and dark == 0) then
                return { mult = card.ability.extra.mult }
            end
        end
    end,
}

-- rudolph: if the first scored card has a Red Seal, retrigger
-- all other scored cards. in_pool Red-Seal gate dropped.
SMODS.Joker {
    key = "rudolph",
    sprite = "rudolph.png",
    negative_sprite = "rudolph_negative.png",
    rarity = 2,
    cost = 6,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    config = {},
    loc_txt = {
        name = "Rudolph",
        text = {
            "If {C:attention}first{} scored card",
            "in hand has a {C:attention}Red Seal{},",
            "retrigger {C:attention}all{} other cards",
        },
    },
    calculate = function(self, card, context)
        if context.repetition and context.cardarea == G.play then
            if context.scoring_hand and context.scoring_hand[1]
                and context.scoring_hand[1].seal == "red"
                and context.other_card ~= context.scoring_hand[1] then
                return { repetitions = 1 }
            end
        end
    end,
}

-- sam_mcgee: X1 Mult per card past 5 in the played hand.
-- in_pool Jest Ice gate dropped (availability nuance).
SMODS.Joker {
    key = "sam_mcgee",
    sprite = "sam_mcgee.png",
    negative_sprite = "sam_mcgee_negative.png",
    rarity = 2,
    cost = 6,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    config = { extra = { threshold = 5, gain = 1 } },
    loc_txt = {
        name = "Sam McGee",
        text = {
            "Gives {X:mult,C:white}X#2#{} Mult for each card",
            "past {C:attention}#1#{} in {C:attention}played hand",
        },
    },
    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                card.ability.extra.threshold,
                card.ability.extra.gain,
            },
        }
    end,
    calculate = function(self, card, context)
        if context.joker_main and context.full_hand then
            if #context.full_hand > card.ability.extra.threshold then
                local extra_cards = #context.full_hand
                    - card.ability.extra.threshold
                return {
                    xmult = 1 + (extra_cards * card.ability.extra.gain),
                }
            end
        end
    end,
}

-- sanguine_joker: scored Hearts have a 1 in 13 chance to
-- create a random Tag (pool via SMODS.TagByType, CryptidPack pattern).
SMODS.Joker {
    key = "sanguine_joker",
    sprite = "sanguine_joker.png",
    negative_sprite = "sanguine_joker_negative.png",
    rarity = 3,
    cost = 8,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    config = { extra = { odds = 13 } },
    loc_txt = {
        name = "Sanguine Joker",
        text = {
            "Played cards with {C:hearts}Heart",
            "suit have a {C:green}#1# in #2#{} chance",
            "to create a random {C:attention}Tag{}",
            "when scored",
        },
    },
    loc_vars = function(self, info_queue, card)
        local numerator, denominator =
            SMODS.get_probability_vars(card, 1, card.ability.extra.odds)
        return { vars = { numerator, denominator } }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play
            and context.other_card then
            if context.other_card:is_suit("Hearts")
                and SMODS.pseudorandom_probability(
                    card, "sanguine_joker", 1, card.ability.extra.odds) then
                if G and G.addTag and SMODS.TagByType then
                    local pool = {}
                    for typ, entry in pairs(SMODS.TagByType) do
                        if (tonumber(entry.weight) or 0) > 0 then
                            local ok = true
                            if type(entry.in_pool) == "function" then
                                local okc, res =
                                    pcall(entry.in_pool, entry, G)
                                ok = okc and res ~= false
                            end
                            if ok then pool[#pool + 1] = typ end
                        end
                    end
                    if #pool > 0 then
                        local typ = pool[SMODS.pseudorandom(
                            "sanguine_joker", 1, #pool)]
                        if typ == "orbital" and G.roll_orbital_hand_index then
                            G:addTag(typ, {
                                orbital_hand_index =
                                    G:roll_orbital_hand_index(),
                            })
                        else
                            G:addTag(typ)
                        end
                    end
                end
                return { message = "+Tag!" }
            end
        end
    end,
}

-- JestPack Wave 4 fragment: Jokers chunk 6 (sapphic_joker .. scurra + semaphore .. silent_sam).
-- Ported per .jobs/wave4/CONVENTIONS.md; see census_jokers_6.md for verdicts and notes.

SMODS.Joker {
    key = "sapphic_joker",
    sprite = "sapphic_joker.png",
    negative_sprite = "sapphic_joker_negative.png",
    loc_txt = {
        name = "Sapphic Joker",
        text = {
            "Scoring {C:attention}Queens{} give {C:chips}+#2#{} Chips",
            "and {C:mult}+#1#{} Mult per {C:attention}Queen{} in",
            "{C:attention}full deck{}",
            "{C:inactive,s:0.8}(Currently {C:chips,s:0.8}+#4#{}{C:inactive,s:0.8} Chips, {C:mult,s:0.8}+#3#{}{C:inactive,s:0.8} Mult)",
        },
    },
    loc_vars = function(self, info_queue, card)
        local queen_count = 0
        if G and G.count_cards_in_full_deck then
            queen_count = G:count_cards_in_full_deck(function(c)
                return c:get_id() == 12
            end) or 0
        end
        return { vars = {
            card.ability.extra.mult,
            card.ability.extra.chips,
            card.ability.extra.mult * queen_count,
            card.ability.extra.chips * queen_count,
        } }
    end,
    rarity = 1,
    cost = 4,
    config = { extra = { chips = 3, mult = 1 } },
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play
            and context.other_card and context.other_card:get_id() == 12 then
            local queen_count = 0
            if G and G.count_cards_in_full_deck then
                queen_count = G:count_cards_in_full_deck(function(c)
                    return c:get_id() == 12
                end) or 0
            end
            if queen_count > 0 then
                return {
                    mult = card.ability.extra.mult * queen_count,
                    chips = card.ability.extra.chips * queen_count,
                }
            end
        end
    end,
}

SMODS.Joker {
    key = "saucy_jacky",
    sprite = "saucy_jacky.png",
    negative_sprite = "saucy_jacky_negative.png",
    loc_txt = {
        name = "Saucy Jacky",
        text = {
            "{C:red}Destroy{} all scored {C:attention}Queens{}",
            "Scored {C:attention}Jacks{} give {C:mult}+#2#{} Mult",
            "per {C:attention}Queen{} {C:red}destroyed{} this way",
            "{C:inactive}(Currently {C:mult}+#1#{} {C:inactive}Mult){}",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = {
            card.ability.extra.curr_mult,
            card.ability.extra.mult_per_queen,
        } }
    end,
    rarity = 3,
    cost = 8,
    config = { extra = { curr_mult = 0, mult_per_queen = 5 } },
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    calculate = function(self, card, context)
        if context.after and context.scoring_hand and not context.blueprint then
            local queens = {}
            for i = 1, #context.scoring_hand do
                if context.scoring_hand[i]:get_id() == 12 then
                    queens[#queens + 1] = context.scoring_hand[i]
                end
            end
            if #queens > 0 then
                for _, q in ipairs(queens) do
                    if SMODS.destroy_card then SMODS.destroy_card(q) end
                end
                card.ability.extra.curr_mult = card.ability.extra.curr_mult
                    + card.ability.extra.mult_per_queen * #queens
                return { message = "Upgrade!" }
            end
        end
        if context.individual and context.cardarea == G.play
            and context.other_card and context.other_card:get_id() == 11
            and card.ability.extra.curr_mult > 0 then
            return { mult = card.ability.extra.curr_mult }
        end
    end,
}

SMODS.Joker {
    key = "saveloy",
    sprite = "saveloy.png",
    negative_sprite = "saveloy_negative.png",
    loc_txt = {
        name = "Saveloy",
        text = {
            "{C:mult}+#1#{} Mult, {C:mult}-#2#{} Mult for",
            "every {C:green}reroll{} in the",
            "{C:money}shop",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = {
            card.ability.extra.mult,
            card.ability.extra.mult_loss,
        } }
    end,
    rarity = 1,
    cost = 4,
    config = { extra = { mult = 20, mult_loss = 1 } },
    blueprint_compat = true,
    eternal_compat = false,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.reroll_shop and not context.blueprint then
            card.ability.extra.mult = card.ability.extra.mult
                - card.ability.extra.mult_loss
            if card.ability.extra.mult <= 0 then
                if SMODS.destroy_joker then SMODS.destroy_joker(card) end
                return { message = "Eaten!" }
            end
            return { message = "-" .. card.ability.extra.mult_loss .. " Mult" }
        end
        if context.joker_main then
            return { mult = card.ability.extra.mult }
        end
    end,
}

SMODS.Joker {
    key = "scorecard",
    sprite = "scorecard.png",
    negative_sprite = "scorecard_negative.png",
    loc_txt = {
        name = "Scorecard",
        text = {
            "When {C:attention}Blind{} is selected,",
            "level up a {C:attention}random",
            "{C:attention}poker hand{} by {C:attention}#1#",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.levels } }
    end,
    rarity = 1,
    cost = 5,
    config = { extra = { levels = 2 } },
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.setting_blind then
            if G and G.handlist and G.upgrade_hand_level_at_index
                and #G.handlist > 0 then
                local hand = pseudorandom_element(G.handlist, "scorecard")
                for i, name in ipairs(G.handlist) do
                    if name == hand then
                        for _ = 1, card.ability.extra.levels do
                            G:upgrade_hand_level_at_index(i)
                        end
                        break
                    end
                end
                return { message = "Level Up!" }
            end
        end
    end,
}

SMODS.Joker {
    key = "scott_free",
    sprite = "scott_free.png",
    negative_sprite = "scott_free_negative.png",
    loc_txt = {
        name = "Scott Free",
        text = {
            "{C:attention}Un-enhanced{} cards held in hand",
            "at {C:attention}end of round{} earn {C:money}$#1#",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.dollars } }
    end,
    rarity = 2,
    cost = 7,
    config = { extra = { dollars = 2 } },
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.hand
            and context.end_of_round and context.other_card then
            local oc = context.other_card
            if not oc.enhancement or oc.enhancement == "base" then
                if oc.debuff then
                    return { message = "Debuffed!" }
                end
                return { dollars = card.ability.extra.dollars }
            end
        end
    end,
}

SMODS.Joker {
    key = "scroggin",
    sprite = "scroggin.png",
    negative_sprite = "scroggin_negative.png",
    loc_txt = {
        name = "Scroggin",
        text = {
            "This {C:attention}Joker{} gains {X:mult,C:white}X#1#{} Mult",
            "when a card is enhanced to",
            "{C:attention}Wild{}, loses {X:mult,C:white}X#2#{} Mult when",
            "hand contains a {C:attention}Flush",
            "{C:inactive}(Currently {X:mult,C:white}X#3#{} {C:inactive}Mult){}",
            "Creates {C:tarot}The Lovers{}",
            "when {C:attention}obtained{}",
            "{C:inactive}(Must have room){}",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = {
            card.ability.extra.xmult_mod,
            card.ability.extra.xmult_minus_mod,
            1 + card.ability.extra.xmult,
        } }
    end,
    rarity = 3,
    cost = 8,
    config = { extra = {
        xmult_minus_mod = 0.25,
        xmult_mod = 0.5,
        xmult = 0,
    } },
    blueprint_compat = true,
    eternal_compat = false,
    perishable_compat = false,
    add_to_deck = function(self, card, from_debuff)
        if not from_debuff then
            SMODS.add_card { set = "Tarot", key = "c_lovers" }
        end
    end,
    calculate = function(self, card, context)
        if context.setting_ability and not context.blueprint
            and context.port and context.port.ability_kind == "enhancement"
            and context.port.new == "wild" then
            card.ability.extra.xmult = card.ability.extra.xmult
                + card.ability.extra.xmult_mod
            return { message = "Upgrade!" }
        end
        if context.before and not context.blueprint then
            if context.poker_hands and next(context.poker_hands["Flush"]) then
                if (1 + card.ability.extra.xmult)
                    - card.ability.extra.xmult_minus_mod <= 1 then
                    if SMODS.destroy_joker then SMODS.destroy_joker(card) end
                    return { message = "Eaten!" }
                end
                card.ability.extra.xmult = card.ability.extra.xmult
                    - card.ability.extra.xmult_minus_mod
                return { message = "-X" .. card.ability.extra.xmult_minus_mod .. " Mult" }
            end
        end
        if context.joker_main then
            return { xmult = 1 + card.ability.extra.xmult }
        end
    end,
}

SMODS.Joker {
    key = "scrunched_joker",
    sprite = "scrunched_joker.png",
    negative_sprite = "scrunched_joker_negative.png",
    loc_txt = {
        name = "Scrunched Joker",
        text = {
            "{C:chips}+#1#{} Chips and {C:mult}+#2#{} Mult on",
            "{C:attention}first{} and {C:attention}last{} hand of round",
            "{C:chips}+#3#{} Chips and {C:mult}+#4#{} Mult",
            "otherwise",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = {
            card.ability.extra.chips_big,
            card.ability.extra.mult_big,
            card.ability.extra.chips_small,
            card.ability.extra.mult_small,
        } }
    end,
    rarity = 1,
    cost = 4,
    config = { extra = {
        chips_big = 60,
        mult_big = 8,
        chips_small = 15,
        mult_small = 2,
    } },
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.joker_main then
            local played = (G and G.get_round_hands_played
                and G:get_round_hands_played()) or 0
            local left = tonumber(G and G.hands) or 1
            if played <= 1 or left <= 0 then
                return {
                    chips = card.ability.extra.chips_big,
                    mult = card.ability.extra.mult_big,
                }
            end
            return {
                chips = card.ability.extra.chips_small,
                mult = card.ability.extra.mult_small,
            }
        end
    end,
}

SMODS.Joker {
    key = "scurra",
    sprite = "scurra.png",
    negative_sprite = "scurra_negative.png",
    loc_txt = {
        name = "Scurra",
        text = {
            "Retrigger all played cards",
            "with a {C:red}Red Seal",
            "{C:attention}#1#{} additional time",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.retriggers } }
    end,
    rarity = 2,
    cost = 6,
    config = { extra = { retriggers = 1 } },
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.repetition and context.cardarea == G.play then
            if context.other_card and context.other_card.seal == "red"
                and not context.other_card.debuff then
                return {
                    message = "Again!",
                    repetitions = card.ability.extra.retriggers,
                }
            end
        end
    end,
}

SMODS.Joker {
    key = "semaphore",
    sprite = "semaphore.png",
    negative_sprite = "semaphore_negative.png",
    loc_txt = {
        name = "Semaphore",
        text = {
            "Scored cards give {C:mult}+#1#{} Mult",
            "for each {C:red}discard{} remaining",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult } }
    end,
    rarity = 1,
    cost = 4,
    config = { extra = { mult = 1 } },
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            local left = tonumber(G and G.discards) or 0
            if left > 0 then
                return { mult = card.ability.extra.mult * left }
            end
        end
    end,
}

SMODS.Joker {
    key = "servillus",
    sprite = "servillus.png",
    negative_sprite = "servillus_negative.png",
    soul_sprite = "servillus_soul.png",
    loc_txt = {
        name = "Servilius",
        text = {
            "Create a {C:attention}Nonstandard Tag{} when",
            "{C:attention}Boss Blind{} is defeated",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = {} }
    end,
    rarity = 4,
    cost = 20,
    config = { extra = {} },
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.end_of_round and not context.blueprint
            and context.port and context.port.is_boss_blind then
            if G and G.addTag then G:addTag("tag_aij_nonstandard") end
            return { message = "+Nonstandard Tag" }
        end
    end,
}

SMODS.Joker {
    key = "sherrif",
    sprite = "sherrif.png",
    negative_sprite = "sherrif_negative.png",
    loc_txt = {
        name = "Sheriff",
        text = {
            "First scored {C:attention}Wild Card{}",
            "each hand earns {C:money}$#1#{}",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.dollars } }
    end,
    rarity = 1,
    cost = 6,
    config = { extra = { dollars = 5 } },
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play
            and context.other_card
            and context.other_card.enhancement == "wild" then
            local is_first_wild = false
            for i = 1, #context.scoring_hand do
                if context.scoring_hand[i].enhancement == "wild" then
                    is_first_wild = context.scoring_hand[i] == context.other_card
                    break
                end
            end
            if is_first_wild then
                return { dollars = card.ability.extra.dollars }
            end
        end
    end,
}

SMODS.Joker {
    key = "shredded_joker",
    sprite = "shredded_joker.png",
    negative_sprite = "shredded_joker_negative.png",
    loc_txt = {
        name = "Shredded Joker",
        text = {
            "{C:mult}+#1#{} Mult per card",
            "{C:red}discarded{} this {C:attention}round",
            "{C:inactive}(Currently {C:mult}+#2#{C:inactive} Mult)",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = {
            card.ability.extra.mult_gain,
            card.ability.extra.mult,
        } }
    end,
    rarity = 1,
    cost = 4,
    config = { extra = { mult = 0, mult_gain = 1 } },
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.discard and not context.blueprint
            and context.other_card and not context.other_card.debuff then
            card.ability.extra.mult = card.ability.extra.mult
                + card.ability.extra.mult_gain
            return { message = "+" .. card.ability.extra.mult_gain .. " Mult" }
        end
        if context.end_of_round and not context.blueprint
            and card.ability.extra.mult > 0 then
            card.ability.extra.mult = 0
            return { message = "Reset!" }
        end
        if context.joker_main then
            return { mult = card.ability.extra.mult }
        end
    end,
}

SMODS.Joker {
    key = "silent_sam",
    sprite = "silent_sam.png",
    negative_sprite = "silent_sam_negative.png",
    loc_txt = {
        name = "Silent Sam",
        text = {
            "Each {C:attention}card{} held in",
            "hand gives {X:mult,C:white}X#1#{} Mult",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { 1 + card.ability.extra.xmult } }
    end,
    rarity = 2,
    cost = 7,
    config = { extra = { xmult = 0.2 } },
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.hand
            and not context.end_of_round and context.other_card then
            if context.other_card.debuff then
                return { message = "Debuffed!" }
            end
            return { xmult = 1 + card.ability.extra.xmult }
        end
    end,
}

SMODS.Joker {
    key = "silly_billy",
    sprite = "silly_billy.png",
    negative_sprite = "silly_billy_negative.png",
    loc_txt = {
        name = "Silly Billy",
        text = {
            "{C:mult}+#1#{} Mult for each",
            "{C:attention}enhancement{}, {C:attention}seal{}, and",
            "{C:attention}edition{} in played hand",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult } }
    end,
    rarity = 1,
    cost = 4,
    config = { extra = { mult = 3 } },
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.joker_main and context.full_hand then
            local count = 0
            for _, playing_card in ipairs(context.full_hand) do
                if playing_card.edition then count = count + 1 end
                if playing_card.seal then count = count + 1 end
                if playing_card.enhancement
                    and playing_card.enhancement ~= "base" then
                    count = count + 1
                end
            end
            if count > 0 then
                return { mult = count * card.ability.extra.mult }
            end
        end
    end,
}

SMODS.Joker {
    key = "silver",
    sprite = "silver.png",
    negative_sprite = "silver_negative.png",
    loc_txt = {
        name = "Silver",
        text = {
            "If played hand is {C:attention}Full House{},",
            "retrigger all scoring cards{}",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = {} }
    end,
    rarity = 2,
    cost = 7,
    config = {},
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.repetition and context.cardarea == G.play
            and context.scoring_name == "Full House" then
            return { repetitions = 1 }
        end
    end,
}

SMODS.Joker {
    key = "silver_screen",
    sprite = "silver_screen.png",
    negative_sprite = "silver_screen_negative.png",
    loc_txt = {
        name = "Silver Screen",
        text = {
            "When a {C:attention}face{} card is",
            "{C:red}destroyed{}, add {C:aij_silver}Silver{} to",
            "a random card in {C:attention}hand",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = {} }
    end,
    rarity = 2,
    cost = 6,
    config = {},
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.remove_playing_cards and context.port
            and context.port.destroyed_cards then
            local destroyed_ids = {}
            local faces = 0
            for _, d in ipairs(context.port.destroyed_cards) do
                local data = d.card_data or d
                if type(data) == "table" then
                    if data.uid ~= nil then destroyed_ids[data.uid] = true end
                    local r = data.rank
                    local is_face = (tonumber(r) and tonumber(r) >= 11
                        and tonumber(r) <= 13)
                        or r == "Jack" or r == "Queen" or r == "King"
                    if is_face and data.enhancement ~= "stone" then
                        faces = faces + 1
                    end
                end
            end
            if faces == 0 then return end
            local candidates = {}
            if G and G.hand and G.hand.card_nodes then
                for _, node in ipairs(G.hand.card_nodes) do
                    local nd = node.card_data
                    if nd and not node.edition
                        and not destroyed_ids[nd.uid] then
                        candidates[#candidates + 1] = node
                    end
                end
            end
            local applied = 0
            for _ = 1, faces do
                if #candidates == 0 then break end
                local pick = pseudorandom_element(candidates,
                    "jest_silver_screen")
                if pick then
                    for i, n in ipairs(candidates) do
                        if n == pick then
                            table.remove(candidates, i)
                            break
                        end
                    end
                    if pick.card_data then
                        pick.card_data.modifier = pick.card_data.modifier or {}
                        pick.card_data.modifier.edition = "silver"
                        if pick.sync_visual_from_card_data then
                            pick:sync_visual_from_card_data()
                        end
                        applied = applied + 1
                    end
                end
            end
            if applied > 0 then
                return { message = "Silver!" }
            end
        end
    end,
}

SMODS.Joker {
    key = "silvio",
    sprite = "silvio.png",
    negative_sprite = "silvio_negative.png",
    soul_sprite = "silvio_soul.png",
    loc_txt = {
        name = "Silvio",
        text = {
            "Retrigger all {C:attention}Kings{}",
            "once for each {C:attention}Queen{}",
            "held in hand",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = {} }
    end,
    rarity = 4,
    cost = 20,
    config = { extra = {} },
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.repetition and context.other_card
            and context.other_card:get_id() == 13 then
            local queen_count = 0
            if G and G.hand and G.hand.card_nodes then
                for _, hand_card in ipairs(G.hand.card_nodes) do
                    if hand_card:get_id() == 12 then
                        queen_count = queen_count + 1
                    end
                end
            end
            if queen_count > 0 then
                return {
                    message = "Again!",
                    repetitions = queen_count,
                }
            end
        end
    end,
}

SMODS.Joker {
    key = "simple_simon",
    sprite = "simple_simon.png",
    negative_sprite = "simple_simon_negative.png",
    loc_txt = {
        name = "Simple Simon",
        text = {
            "{C:chips}+#1#{} Chips",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chips } }
    end,
    rarity = 1,
    cost = 2,
    config = { extra = { chips = 30 } },
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.joker_main then
            return { chips = card.ability.extra.chips }
        end
    end,
}

SMODS.Joker {
    key = "single_cell",
    sprite = "single_cell.png",
    negative_sprite = "single_cell_negative.png",
    loc_txt = {
        name = "Single Cell",
        text = {
            "First scored {C:attention}numbered{}",
            "card each hand gives",
            "{C:chips}+#1#{} Chips",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chips } }
    end,
    rarity = 2,
    cost = 6,
    config = { extra = { chips = 100 } },
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            local first_num
            for _, v in ipairs(context.scoring_hand) do
                if v:get_id() >= 2 and v:get_id() <= 10 then
                    first_num = v
                    break
                end
            end
            if context.other_card == first_num then
                return { chips = card.ability.extra.chips }
            end
        end
    end,
}

SMODS.Joker {
    key = "skomorokh",
    sprite = "skomorokh.png",
    negative_sprite = "skomorokh_negative.png",
    loc_txt = {
        name = "Skomorokh",
        text = {
            "Gives {X:mult,C:white}X#1#{} Mult for each",
            "{C:attention}Editioned{} card in your {C:attention}full deck",
            "{C:inactive}(Currently {X:mult,C:white}X#2#{} {C:inactive}Mult)",
        },
    },
    loc_vars = function(self, info_queue, card)
        local edition_tally = 0
        if G and G.count_cards_in_full_deck then
            edition_tally = G:count_cards_in_full_deck(function(c)
                return c.edition ~= nil
            end) or 0
        end
        return { vars = {
            card.ability.extra.xmult_mod,
            card.ability.extra.xmult
                + edition_tally * card.ability.extra.xmult_mod,
        } }
    end,
    rarity = 2,
    cost = 5,
    config = { extra = { xmult = 1, xmult_mod = 0.2 } },
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.joker_main then
            local edition_tally = 0
            if G and G.count_cards_in_full_deck then
                edition_tally = G:count_cards_in_full_deck(function(c)
                    return c.edition ~= nil
                end) or 0
            end
            return {
                xmult = card.ability.extra.xmult
                    + edition_tally * card.ability.extra.xmult_mod,
            }
        end
    end,
}

SMODS.Joker {
    key = "scopaesthesia",
    sprite = "scopaesthesia.png",
    negative_sprite = "scopaesthesia_negative.png",
    loc_txt = {
        name = "Scopaesthesia",
        text = {
            "{C:attention}Reveal{} the next card in",
            "your {C:attention}deck",
            "{C:attention}Cards{} that share its {C:attention}rank",
            "give {X:mult,C:white}X#1#{} Mult",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.xmult } }
    end,
    rarity = 2,
    cost = 6,
    config = { extra = { xmult = 1.5 } },
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play
            and context.other_card then
            local cards = G and G.deck and G.deck.cards
            if cards and #cards > 0 then
                local top = cards[#cards]
                local top_rank = top and (tonumber(top.rank)
                    or (top.get_id and top:get_id()))
                if top_rank and context.other_card:get_id() == top_rank then
                    return { xmult = card.ability.extra.xmult }
                end
            end
        end
    end,
}

SMODS.Joker {
    key = "scaramouche",
    sprite = "scaramouche.png",
    negative_sprite = "scaramouche_negative.png",
    loc_txt = {
        name = "Scaramouche",
        text = {
            "{C:attention}Retrigger{} all scored",
            "cards if {C:attention}played hand{} is",
            "a {C:attention}#1#{}",
            "{C:inactive}(Hand changes at",
            "{C:inactive}end of round){}",
        },
    },
    loc_vars = function(self, info_queue, card)
        if not card.ability.extra.scaramouche_poker_hand
            and G and G.handlist then
            local pool = {}
            for _, name in ipairs(G.handlist) do
                pool[#pool + 1] = name
            end
            if #pool > 0 then
                card.ability.extra.scaramouche_poker_hand =
                    pseudorandom_element(pool, "scaramouche")
            end
        end
        return { vars = { card.ability.extra.scaramouche_poker_hand } }
    end,
    rarity = 2,
    cost = 6,
    config = { extra = { repetitions = 1 } },
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.end_of_round and not context.blueprint then
            if G and G.handlist then
                local pool = {}
                for _, name in ipairs(G.handlist) do
                    if name ~= card.ability.extra.scaramouche_poker_hand then
                        pool[#pool + 1] = name
                    end
                end
                if #pool > 0 then
                    card.ability.extra.scaramouche_poker_hand =
                        pseudorandom_element(pool, "scaramouche")
                    return { message = "Reset!" }
                end
            end
        end
        if context.repetition and context.cardarea == G.play then
            if context.scoring_name
                and context.scoring_name
                    == card.ability.extra.scaramouche_poker_hand then
                return {
                    message = "Again!",
                    repetitions = card.ability.extra.repetitions,
                }
            end
        end
    end,
}

SMODS.Joker {
    key = "second_tier_meme",
    sprite = "second_tier_meme.png",
    negative_sprite = "second_tier_meme_negative.png",
    loc_txt = {
        name = "Second Tier Meme",
        text = {
            "If hand is your {C:attention}second",
            "{C:attention}most{} played poker hand,",
            "{C:attention}retrigger{} all {C:attention}scoring{} cards",
            "{C:inactive}(Currently: {C:attention}#1#{C:inactive})",
        },
    },
    loc_vars = function(self, info_queue, card)
        local second_most = nil
        if G and G.handlist and G.hand_play_counts then
            local most, val = nil, 1
            for i, name in ipairs(G.handlist) do
                local played = tonumber(G.hand_play_counts[i]) or 0
                if played >= val then
                    val = played
                    most = name
                end
            end
            val = 1
            for i, name in ipairs(G.handlist) do
                local played = tonumber(G.hand_play_counts[i]) or 0
                if played >= val and name ~= most then
                    val = played
                    second_most = name
                end
            end
        end
        return { vars = { second_most or "None" } }
    end,
    rarity = 2,
    cost = 6,
    config = {},
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.repetition and context.cardarea == G.play then
            if G and G.handlist and G.hand_play_counts then
                local most, val = nil, 1
                for i, name in ipairs(G.handlist) do
                    local played = tonumber(G.hand_play_counts[i]) or 0
                    if name == context.scoring_name then
                        played = played - 1
                    end
                    if played >= val then
                        val = played
                        most = name
                    end
                end
                local second_most = nil
                val = 1
                for i, name in ipairs(G.handlist) do
                    local played = tonumber(G.hand_play_counts[i]) or 0
                    if name == context.scoring_name then
                        played = played - 1
                    end
                    if played >= val and name ~= most then
                        val = played
                        second_most = name
                    end
                end
                if context.scoring_name == second_most then
                    return {
                        message = "Again!",
                        repetitions = 1,
                    }
                end
            end
        end
    end,
}

SMODS.Joker {
    key = "sleepy_joker",
    sprite = "sleepy_joker.png",
    negative_sprite = "sleepy_joker_negative.png",
    loc_txt = {
        name = "Sleepy Joker",
        text = {
            "{X:mult,C:white}X#1#{} Mult if played hand",
            "contains only {C:spades}Spades{} and {C:clubs}Clubs",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.xmult } }
    end,
    rarity = 2,
    cost = 7,
    config = { extra = { xmult = 2 } },
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.joker_main then
            if context.full_hand and #context.full_hand > 0 then
                local all_dark_suits = true
                for _, played_card in ipairs(context.full_hand) do
                    if not (played_card:is_suit("Spades")
                        or played_card:is_suit("Clubs")) then
                        all_dark_suits = false
                        break
                    end
                end
                if all_dark_suits then
                    return { xmult = card.ability.extra.xmult }
                end
            end
        end
    end,
}

SMODS.Joker {
    key = "slim_joker",
    sprite = "slim_joker.png",
    negative_sprite = "slim_joker_negative.png",
    loc_txt = {
        name = "Slim Joker",
        text = {
            "{C:mult}+#1#{} Mult",
            "{C:mult}-#2#{} Mult per card",
            "in played hand",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = {
            card.ability.extra.initial_mult,
            card.ability.extra.mult_mod,
        } }
    end,
    rarity = 1,
    cost = 4,
    config = { extra = { initial_mult = 24, mult_mod = 4 } },
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.joker_main and context.full_hand then
            local _mult = card.ability.extra.initial_mult
                - card.ability.extra.mult_mod * #context.full_hand
            if _mult > 0 then
                return { mult = _mult }
            end
        end
    end,
}

SMODS.Joker {
    key = "slippery_when_wet",
    sprite = "slippery_when_wet.png",
    negative_sprite = "slippery_when_wet_negative.png",
    loc_txt = {
        name = "Slippery When Wet",
        text = {
            "Scoring cards give {C:chips}Chips{}",
            "equal to the combined {C:attention}rank{}",
            "of {C:attention}adjacent{} cards",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = {} }
    end,
    rarity = 1,
    cost = 5,
    config = {},
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play
            and context.full_hand then
            local pos = nil
            for i = 1, #context.full_hand do
                if context.full_hand[i] == context.other_card then
                    pos = i
                    break
                end
            end
            if not pos then return end
            local left_card = context.full_hand[pos - 1]
            local right_card = context.full_hand[pos + 1]
            if left_card or right_card then
                local left_rank = 0
                local right_rank = 0
                if left_card and left_card.enhancement ~= "stone" then
                    left_rank = math.max(left_card:get_id(), 0)
                end
                if right_card and right_card.enhancement ~= "stone" then
                    right_rank = math.max(right_card:get_id(), 0)
                end
                if left_rank + right_rank > 0 then
                    return { chips = left_rank + right_rank }
                end
            end
        end
    end,
}

SMODS.Joker {
    key = "slubberdegullion",
    sprite = "slubberdegullion.png",
    negative_sprite = "slubberdegullion_negative.png",
    loc_txt = {
        name = "Slubberdegullion",
        text = {
            "{C:red}+#1# Discard{} this round if",
            "{C:attention}played hand{} contains at",
            "least {C:attention}3{} unscoring cards",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.discards } }
    end,
    rarity = 2,
    cost = 5,
    config = { extra = { discards = 1 } },
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.before and context.full_hand and context.scoring_hand then
            if #context.full_hand - #context.scoring_hand >= 3 then
                if G then
                    G.discards = (tonumber(G.discards) or 0)
                        + card.ability.extra.discards
                end
                return {
                    message = "+" .. card.ability.extra.discards .. " Discard",
                }
            end
        end
    end,
}

SMODS.Joker {
    key = "smide",
    sprite = "smide.png",
    negative_sprite = "smide_negative.png",
    loc_txt = {
        name = "Smide",
        text = {
            "{C:chips}+#1#{} Chips per {C:attention}face{} card",
            "in your {C:attention}full deck",
            "{C:inactive}(Currently {C:chips}+#2#{} {C:inactive}Chips){}",
        },
    },
    loc_vars = function(self, info_queue, card)
        local faces = 0
        if G and G.count_cards_in_full_deck then
            faces = G:count_cards_in_full_deck(function(c)
                return c:is_face()
            end) or 0
        end
        return { vars = {
            card.ability.extra.chips,
            faces * card.ability.extra.chips,
        } }
    end,
    rarity = 1,
    cost = 5,
    config = { extra = { chips = 7 } },
    blueprint_compat = true,
    eternal_compat = false,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.joker_main then
            local faces = 0
            if G and G.count_cards_in_full_deck then
                faces = G:count_cards_in_full_deck(function(c)
                    return c:is_face()
                end) or 0
            end
            return { chips = faces * card.ability.extra.chips }
        end
    end,
}

SMODS.Joker {
    key = "sneaky_pete",
    sprite = "sneaky_pete.png",
    negative_sprite = "sneaky_pete_negative.png",
    loc_txt = {
        name = "Sneaky Pete",
        text = {
            "Earn {C:money}$#2#{} at end of round",
            "for every {C:money}Gold Seal{}",
            "in your {C:attention}full deck",
            "{C:inactive}(Currently {C:money}$#1#{C:inactive})",
        },
    },
    loc_vars = function(self, info_queue, card)
        local seal_count = 0
        if G and G.count_cards_in_full_deck then
            seal_count = G:count_cards_in_full_deck(function(c)
                return c.seal == "gold"
            end) or 0
        end
        return { vars = {
            seal_count * card.ability.extra.money_per_seal,
            card.ability.extra.money_per_seal,
        } }
    end,
    rarity = 2,
    cost = 7,
    config = { extra = { money_per_seal = 2 } },
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context) end,
    calc_dollar_bonus = function(self, card)
        local seal_count = 0
        if G and G.count_cards_in_full_deck then
            seal_count = G:count_cards_in_full_deck(function(c)
                return c.seal == "gold"
            end) or 0
        end
        if seal_count > 0 then
            return seal_count * card.ability.extra.money_per_seal
        end
    end,
}

SMODS.Joker {
    key = "sommers",
    sprite = "sommers.png",
    negative_sprite = "sommers_negative.png",
    soul_sprite = "sommers_soul.png",
    loc_txt = {
        name = "Sommers",
        text = {
            "{C:attention}Levels up{} all",
            "played hands",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = {} }
    end,
    rarity = 4,
    cost = 20,
    config = { extra = { levels = 2 } },
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.joker_main then
            return { level_up = true, message = "Level Up!" }
        end
    end,
}

SMODS.Joker {
    key = "soviet",
    sprite = "soviet.png",
    negative_sprite = "soviet_negative.png",
    loc_txt = {
        name = "Soviet",
        text = {
            "{C:mult}+#1#{} Mult if {C:attention}played hand{}",
            "contains no {C:attention}Kings{} or {C:attention}Queens{}",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult } }
    end,
    rarity = 2,
    cost = 6,
    config = { extra = { mult = 20 } },
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.joker_main then
            local contains_king_or_queen = false
            if context.full_hand then
                for _, p_card in ipairs(context.full_hand) do
                    if p_card:get_id() == 13 or p_card:get_id() == 12 then
                        contains_king_or_queen = true
                        break
                    end
                end
            end
            if not contains_king_or_queen then
                return { mult = card.ability.extra.mult }
            end
        end
    end,
}

SMODS.Joker {
    key = "splat",
    sprite = "splat.png",
    negative_sprite = "splat_negative.png",
    loc_txt = {
        name = "Splat!",
        text = {
            "{C:green}#1# in #2#{} chance for each",
            "{C:attention}scoring{} card to gain a",
            "{C:jest_melted}Melted{} {C:attention}Seal",
        },
    },
    loc_vars = function(self, info_queue, card)
        local numerator, denominator = SMODS.get_probability_vars(
            card, 1, card.ability.extra.odds, "splat")
        return { vars = { numerator, denominator } }
    end,
    rarity = 2,
    cost = 6,
    config = { extra = { odds = 6 } },
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play
            and not context.end_of_round and context.other_card then
            if SMODS.pseudorandom_probability(
                card, "splat", 1, card.ability.extra.odds, "splat") then
                local oc = context.other_card
                if oc.set_seal then
                    oc:set_seal("melted")
                elseif oc.card_data then
                    oc.card_data.seal = "melted"
                end
                return { message = "Splat!" }
            end
        end
    end,
}

SMODS.Joker {
    key = "square_eyes",
    sprite = "square_eyes.png",
    negative_sprite = "square_eyes_negative.png",
    loc_txt = {
        name = "Square Eyes",
        text = {
            "Scored {C:attention}4s{} give {C:mult}+#1#{} Mult",
            "per {C:attention}4{} in played hand",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult_per_four } }
    end,
    rarity = 2,
    cost = 6,
    config = { extra = { mult_per_four = 4 } },
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play
            and context.other_card
            and context.other_card:get_id() == 4 then
            local fours_in_played_hand = 0
            if context.full_hand then
                for _, p_card in ipairs(context.full_hand) do
                    if p_card:get_id() == 4 then
                        fours_in_played_hand = fours_in_played_hand + 1
                    end
                end
            end
            if fours_in_played_hand > 0 then
                return {
                    mult = fours_in_played_hand
                        * card.ability.extra.mult_per_four,
                }
            end
        end
    end,
}

SMODS.Joker {
    key = "squeezy_pete",
    sprite = "squeezy_pete.png",
    negative_sprite = "squeezy_pete_negative.png",
    loc_txt = {
        name = "Squeezy Pete",
        text = {
            "Gains {X:mult,C:white}X#1#{} Mult per",
            "{C:attention}consecutive{} played hand",
            "containing a {C:attention}Full House{}",
            "{C:inactive}(Currently{} {X:mult,C:white}X#2#{}{C:inactive} Mult){}",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = {
            card.ability.extra.bonus,
            card.ability.extra.xmult,
        } }
    end,
    rarity = 2,
    cost = 6,
    config = { extra = { bonus = 0.25, xmult = 1 } },
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    calculate = function(self, card, context)
        if context.before and context.scoring_name
            and not context.blueprint then
            if context.poker_hands
                and next(context.poker_hands["Full House"]) then
                card.ability.extra.xmult = card.ability.extra.xmult
                    + card.ability.extra.bonus
                return { message = "Upgrade!" }
            end
            if card.ability.extra.xmult > 1 then
                card.ability.extra.xmult = 1
                return { message = "Reset!" }
            end
        end
        if context.joker_main and card.ability.extra.xmult > 1 then
            return { xmult = card.ability.extra.xmult }
        end
    end,
}

SMODS.Joker {
    key = "stagehand",
    sprite = "stagehand.png",
    negative_sprite = "stagehand_negative.png",
    loc_txt = {
        name = "Stagehand",
        text = {
            "Gives {X:mult,C:white}X#1#{} Mult",
            "per held {C:attention}Joker",
            "{C:inactive}(Currently {X:mult,C:white}X#2#{C:inactive} Mult)",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = {
            card.ability.extra.xmult,
            1 + card.ability.extra.xmult
                * ((G and G.jokers and #G.jokers) or 0),
        } }
    end,
    rarity = 1,
    cost = 4,
    config = { extra = { xmult = 0.1 } },
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.joker_main then
            return {
                xmult = 1 + card.ability.extra.xmult
                    * ((G and G.jokers and #G.jokers) or 0),
            }
        end
    end,
}

SMODS.Joker {
    key = "stracciatella",
    sprite = "stracciatella.png",
    negative_sprite = "stracciatella_negative.png",
    loc_txt = {
        name = "Stracciatella",
        text = {
            "After each hand, {C:green}#1# in #2#{}",
            "chance for each {C:attention}scoring{} card",
            "to {C:attention}permanently{} earn {C:money}$#3#{}",
            "when scored",
            "{C:red}Self-destructs{} after triggering",
        },
    },
    loc_vars = function(self, info_queue, card)
        local numerator, denominator = SMODS.get_probability_vars(
            card, 1, card.ability.extra.odds, "stracciatella")
        return { vars = {
            numerator,
            denominator,
            card.ability.extra.dollars,
        } }
    end,
    rarity = 1,
    cost = 5,
    config = { extra = { dollars = 2, odds = 10 } },
    blueprint_compat = true,
    eternal_compat = false,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.before and not context.blueprint
            and context.scoring_hand then
            if SMODS.pseudorandom_probability(
                card, "stracciatella", 1, card.ability.extra.odds,
                "stracciatella") then
                for _, scored_card in ipairs(context.scoring_hand) do
                    local cur = SMODS.get_perma(scored_card,
                        "perma_p_dollars") or 0
                    SMODS.set_perma(scored_card, "perma_p_dollars",
                        cur + card.ability.extra.dollars)
                end
                if SMODS.destroy_joker then SMODS.destroy_joker(card) end
                return { message = "Melted!" }
            end
        end
    end,
}

SMODS.Joker {
    key = "sudoku",
    sprite = "sudoku.png",
    negative_sprite = "sudoku_negative.png",
    loc_txt = {
        name = "Sudoku",
        text = {
            "This Joker gains {X:mult,C:white}X#1#{} Mult",
            "per consecutive played hand",
            "containing a {C:attention}Straight{}",
            "{C:inactive}(Currently {X:mult,C:white}X#2#{C:inactive} Mult)",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = {
            card.ability.extra.bonus,
            card.ability.extra.xmult,
        } }
    end,
    rarity = 2,
    cost = 6,
    config = { extra = { xmult = 1, bonus = 0.3 } },
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    calculate = function(self, card, context)
        if context.before and context.scoring_name
            and not context.blueprint then
            if context.poker_hands
                and next(context.poker_hands["Straight"]) then
                card.ability.extra.xmult = card.ability.extra.xmult
                    + card.ability.extra.bonus
                return { message = "Upgrade!" }
            end
            if card.ability.extra.xmult > 1 then
                card.ability.extra.xmult = 1
                return { message = "Reset!" }
            end
        end
        if context.joker_main and card.ability.extra.xmult > 1 then
            return { xmult = card.ability.extra.xmult }
        end
    end,
}

SMODS.Joker {
    key = "suibhne",
    sprite = "suibhne.png",
    negative_sprite = "suibhne_negative.png",
    loc_txt = {
        name = "Suibhne",
        text = {
            "This Joker gains {X:chips,C:white}X#1#{} Chips per",
            "card in the {C:attention}played hand{} if hand",
            "contains only {C:paperback_stars}Star{} {C:attention}Kings{}",
            "{C:inactive}(Currently{} {X:chips,C:white}X#2#{C:inactive} Chips){}",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = {
            card.ability.extra.xchips_mod,
            card.ability.extra.xchips + 1,
        } }
    end,
    rarity = 3,
    cost = 8,
    config = { extra = { xchips = 0, xchips_mod = 0.1 } },
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    calculate = function(self, card, context)
        if context.before and context.full_hand then
            local star_kings, all_cards = 0, 0
            for _, v in ipairs(context.full_hand) do
                all_cards = all_cards + 1
                if v:get_id() == 13 and v:is_suit("Stars") then
                    star_kings = star_kings + 1
                end
            end
            if star_kings == all_cards and not context.blueprint then
                for _ in ipairs(context.full_hand) do
                    card.ability.extra.xchips = card.ability.extra.xchips
                        + card.ability.extra.xchips_mod
                end
            end
        end
        if context.joker_main then
            return { x_chips = card.ability.extra.xchips + 1 }
        end
    end,
}

SMODS.Joker {
    key = "sundae_1",
    sprite = "sundae_1.png",
    negative_sprite = "sundae_1_negative.png",
    loc_txt = {
        name = "Sundae",
        text = {
            "{C:chips}+#1#{} Chips",
            "{C:attention}Consumed{} after {C:attention}#2#",
            "Rounds",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = {
            card.ability.extra.chips,
            card.ability.extra.rounds,
        } }
    end,
    rarity = 1,
    cost = 4,
    config = { extra = { chips = 150, rounds = 3, total_rounds = 3 } },
    blueprint_compat = true,
    eternal_compat = false,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.joker_main then
            return { chips = card.ability.extra.chips }
        end
        if context.end_of_round and not context.blueprint then
            card.ability.extra.rounds = card.ability.extra.rounds - 1
            if card.ability.extra.rounds <= 0 then
                if SMODS.destroy_joker then SMODS.destroy_joker(card) end
                return { message = "Eaten!" }
            end
            return {
                message = card.ability.extra.rounds .. "/"
                    .. card.ability.extra.total_rounds,
            }
        end
    end,
    in_pool = function(self, args)
        return false
    end,
}

SMODS.Joker {
    key = "sundae_2",
    sprite = "sundae_2.png",
    negative_sprite = "sundae_2_negative.png",
    loc_txt = {
        name = "Sundae",
        text = {
            "{C:mult}+#1#{} Mult",
            "{C:attention}Consumed{} after {C:attention}#2#",
            "Rounds",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = {
            card.ability.extra.mult,
            card.ability.extra.rounds,
        } }
    end,
    rarity = 1,
    cost = 4,
    config = { extra = { mult = 30, rounds = 3, total_rounds = 3 } },
    blueprint_compat = true,
    eternal_compat = false,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.joker_main then
            return { mult = card.ability.extra.mult }
        end
        if context.end_of_round and not context.blueprint then
            card.ability.extra.rounds = card.ability.extra.rounds - 1
            if card.ability.extra.rounds <= 0 then
                if SMODS.destroy_joker then SMODS.destroy_joker(card) end
                return { message = "Eaten!" }
            end
            return {
                message = card.ability.extra.rounds .. "/"
                    .. card.ability.extra.total_rounds,
            }
        end
    end,
    in_pool = function(self, args)
        return false
    end,
}

SMODS.Joker {
    key = "sundae_3",
    sprite = "sundae_3.png",
    negative_sprite = "sundae_3_negative.png",
    loc_txt = {
        name = "Sundae",
        text = {
            "Earn {C:money}$#1#{} at end of {C:attention}round",
            "{C:attention}Consumed{} after {C:attention}#2#",
            "Rounds",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = {
            card.ability.extra.dollars,
            card.ability.extra.rounds,
        } }
    end,
    rarity = 1,
    cost = 4,
    config = { extra = { dollars = 10, rounds = 3, total_rounds = 3 } },
    blueprint_compat = true,
    eternal_compat = false,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.end_of_round and not context.blueprint then
            ease_dollars(card.ability.extra.dollars)
            card.ability.extra.rounds = card.ability.extra.rounds - 1
            if card.ability.extra.rounds <= 0 then
                if SMODS.destroy_joker then SMODS.destroy_joker(card) end
                return { message = "Eaten!" }
            end
            return {
                message = card.ability.extra.rounds .. "/"
                    .. card.ability.extra.total_rounds,
            }
        end
    end,
    in_pool = function(self, args)
        return false
    end,
}

SMODS.Joker {
    key = "sunny_joker",
    sprite = "sunny_joker.png",
    negative_sprite = "sunny_joker_negative.png",
    loc_txt = {
        name = "Sunny Joker",
        text = {
            "If played hand {C:attention}contains{} a",
            "{C:attention}Royal Flush{}, all scoring",
            "cards gain {X:mult,C:white}X#1#{} Mult",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.perma_mult } }
    end,
    rarity = 2,
    cost = 6,
    config = { extra = { perma_mult = 0.2 } },
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play
            and context.other_card then
            if context.poker_hands
                and next(context.poker_hands["aij_Royal Flush"]) then
                local cur = SMODS.get_perma(context.other_card,
                    "perma_x_mult") or 0
                SMODS.set_perma(context.other_card, "perma_x_mult",
                    cur + card.ability.extra.perma_mult)
                return { message = "Upgrade!" }
            end
        end
    end,
}

SMODS.Joker {
    key = "sunny_side",
    sprite = "sunny_side.png",
    negative_sprite = "sunny_side_negative.png",
    loc_txt = {
        name = "Sunny Side",
        text = {
            "When any {C:money}money{} is",
            "earned, this {C:attention}Joker{} gains",
            "{C:attention}double{} that {C:money}money{} as sell",
            "value, and {C:red}subtracts",
            "{C:money}money{} earned",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = {} }
    end,
    rarity = 3,
    cost = 10,
    config = {},
    blueprint_compat = false,
    eternal_compat = false,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.money_altered and context.amount
            and context.amount >= 1 and not context.blueprint
            and not context.selling_self then
            ease_dollars(-context.amount)
            card.sell_cost = (tonumber(card.sell_cost) or 0)
                + context.amount * 2
            return { message = "Value Up!" }
        end
    end,
}

SMODS.Joker {
    key = "survivalaren_credits_joker",
    sprite = "survivalaren_credits_joker.png",
    negative_sprite = "survivalaren_credits_joker_negative.png",
    loc_txt = {
        name = "Survivalaren",
        text = {
            '{C:inactive}"Take it sleazy"',
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = {} }
    end,
    rarity = 1,
    cost = 4,
    config = {},
    blueprint_compat = false,
    eternal_compat = false,
    perishable_compat = true,
    calculate = function(self, card, context) end,
    in_pool = function(self, args)
        return false
    end,
}

local jest6_taggart_busy = false

SMODS.Joker {
    key = "taggart",
    sprite = "taggart.png",
    negative_sprite = "taggart_negative.png",
    loc_txt = {
        name = "Taggart",
        text = {
            "Create {C:attention}#1# copy{} of",
            "each {C:attention}Tag{} acquired",
            "{C:inactive}(Except Double Tag)",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.tags } }
    end,
    rarity = 3,
    cost = 8,
    config = { extra = { tags = 1 } },
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.tag_added and context.tag_added
            and not jest6_taggart_busy then
            local src = context.tag_added
            if src.type and src.type ~= "double" then
                jest6_taggart_busy = true
                for _ = 1, card.ability.extra.tags do
                    if G and G.addTag then
                        if src.orbital_hand_index then
                            G:addTag(src.type, {
                                orbital_hand_index = src.orbital_hand_index,
                            })
                        else
                            G:addTag(src.type)
                        end
                    end
                end
                jest6_taggart_busy = false
                return { message = "Double!" }
            end
        end
    end,
}

SMODS.Joker {
    key = "taikomochi",
    sprite = "taikomochi.png",
    negative_sprite = "taikomochi_negative.png",
    loc_txt = {
        name = "Taikomochi",
        text = {
            "{C:attention}Jacks{} held in hand",
            "give {C:chips}+#1#{} Chips",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chips } }
    end,
    rarity = 3,
    cost = 8,
    config = { extra = { chips = 100 } },
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.hand
            and not context.end_of_round and context.other_card then
            if context.other_card:get_id() == 11 then
                if context.other_card.debuff then
                    return { message = "Debuffed!" }
                end
                return { chips = card.ability.extra.chips }
            end
        end
    end,
}

SMODS.Joker {
    key = "taillefer",
    sprite = "taillefer.png",
    negative_sprite = "taillefer_negative.png",
    soul_sprite = "taillefer_soul.png",
    loc_txt = {
        name = "Taillefer",
        text = {
            "This Joker gains {X:mult,C:white}X#2#{} Mult",
            "per hand played,",
            "{C:red}self-destructs{} after",
            "defeating {C:attention}#3#{} {C:attention}Boss Blinds{}",
            "{C:inactive}(Currently {X:mult,C:white}X#1#{} {C:inactive}Mult, {C:attention}#4#{C:inactive}/{C:attention}#3#{C:inactive}){}",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = {
            card.ability.extra.xmult,
            card.ability.extra.xmult_mod,
            card.ability.extra.boss_blinds,
            card.ability.extra.current_boss_blinds,
        } }
    end,
    rarity = 4,
    cost = 20,
    config = { extra = {
        xmult = 1,
        xmult_mod = 0.5,
        boss_blinds = 4,
        current_boss_blinds = 0,
    } },
    blueprint_compat = true,
    eternal_compat = false,
    perishable_compat = false,
    calculate = function(self, card, context)
        if context.before and not context.blueprint then
            card.ability.extra.xmult = card.ability.extra.xmult
                + card.ability.extra.xmult_mod
            return { message = "Upgrade!" }
        end
        if context.joker_main then
            return { xmult = card.ability.extra.xmult }
        end
        if context.end_of_round and not context.blueprint
            and context.port and context.port.is_boss_blind then
            card.ability.extra.current_boss_blinds =
                card.ability.extra.current_boss_blinds + 1
            if card.ability.extra.current_boss_blinds
                >= card.ability.extra.boss_blinds then
                if SMODS.destroy_joker then SMODS.destroy_joker(card) end
                return { message = "Killed" }
            end
            return {
                message = card.ability.extra.current_boss_blinds .. "/"
                    .. card.ability.extra.boss_blinds,
            }
        end
    end,
}

SMODS.Joker {
    key = "tangled_joker",
    sprite = "tangled_joker.png",
    negative_sprite = "tangled_joker_negative.png",
    loc_txt = {
        name = "Tangled Joker",
        text = {
            "{C:chips}+#1#{} Chips for each {C:attention}Joker{} held",
            "{C:mult}+#2#{} Mult per empty {C:attention}Joker slot",
            "{C:inactive,s:0.8}(Currently {C:chips,s:0.8}+#3#{}{C:inactive,s:0.8} Chips, {C:mult,s:0.8}+#4#{}{C:inactive,s:0.8} Mult)",
        },
    },
    loc_vars = function(self, info_queue, card)
        local jokers_held = (G and G.jokers and #G.jokers) or 0
        local capacity = tonumber(G and G.joker_capacity) or jokers_held
        local empty_slots = math.max(0, capacity - jokers_held)
        return { vars = {
            card.ability.extra.chips,
            card.ability.extra.mult,
            card.ability.extra.chips * jokers_held,
            card.ability.extra.mult * empty_slots,
        } }
    end,
    rarity = 1,
    cost = 4,
    config = { extra = { chips = 20, mult = 4 } },
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.joker_main then
            local jokers_held = (G and G.jokers and #G.jokers) or 0
            local capacity = tonumber(G and G.joker_capacity)
                or jokers_held
            local empty_slots = math.max(0, capacity - jokers_held)
            return {
                chips = card.ability.extra.chips * jokers_held,
                mult = card.ability.extra.mult * empty_slots,
            }
        end
    end,
}

SMODS.Joker {
    key = "taylor_credits_joker",
    sprite = "taylor_credits_joker.png",
    negative_sprite = "taylor_credits_joker_negative.png",
    loc_txt = {
        name = "Taylor",
        text = {
            '{C:inactive}"Skibby Dee"',
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = {} }
    end,
    rarity = 1,
    cost = 4,
    config = {},
    blueprint_compat = false,
    eternal_compat = false,
    perishable_compat = true,
    calculate = function(self, card, context) end,
    in_pool = function(self, args)
        return false
    end,
}

SMODS.Joker {
    key = "teeny_joker",
    sprite = "teeny_joker.png",
    negative_sprite = "teeny_joker_negative.png",
    loc_txt = {
        name = "Teeny Joker",
        text = {
            "{C:chips}+#1#{} Chips if played hand",
            "contains only {C:attention}2s{}",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chips } }
    end,
    rarity = 1,
    cost = 4,
    config = { extra = { chips = 150 } },
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.joker_main and context.full_hand then
            local twos, all_cards = 0, 0
            for _, v in ipairs(context.full_hand) do
                all_cards = all_cards + 1
                if v:get_id() == 2 then
                    twos = twos + 1
                end
            end
            if twos == all_cards then
                return { chips = card.ability.extra.chips }
            end
        end
    end,
}

SMODS.Joker {
    key = "ten_sharp",
    sprite = "ten_sharp.png",
    negative_sprite = "ten_sharp_negative.png",
    loc_txt = {
        name = "Ten Sharp",
        text = {
            "{C:attention}Retriggers{} all scored",
            "cards {C:attention}adjacent{} to {C:attention}10s",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = {} }
    end,
    rarity = 1,
    cost = 5,
    config = { extra = {} },
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.repetition and context.cardarea == G.play
            and context.scoring_hand and context.other_card then
            local idx = 0
            for i, v in ipairs(context.scoring_hand) do
                if v == context.other_card then
                    idx = i
                    break
                end
            end
            local triggers = false
            if idx > 1
                and context.scoring_hand[idx - 1]:get_id() == 10 then
                triggers = true
            end
            if idx < #context.scoring_hand
                and context.scoring_hand[idx + 1]:get_id() == 10 then
                triggers = true
            end
            if triggers then
                return { repetitions = 1 }
            end
        end
    end,
}

SMODS.Joker {
    key = "tetraphobia",
    sprite = "tetraphobia.png",
    negative_sprite = "tetraphobia_negative.png",
    loc_txt = {
        name = "Tetraphobia",
        text = {
            "This Joker gains {C:mult}+#2#{} Mult",
            "per {C:attention}4{} discarded, resets",
            "when a {C:attention}4{} is scored",
            "{C:inactive}(Currently {C:mult}+#1#{C:inactive} Mult)",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = {
            card.ability.extra.mult or 0,
            card.ability.extra.mult_mod,
        } }
    end,
    rarity = 1,
    cost = 5,
    config = { extra = { mult = 0, mult_mod = 1 } },
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    calculate = function(self, card, context)
        if not context.blueprint then
            if context.discard and context.other_card
                and context.other_card:get_id() == 4
                and not context.other_card.debuff then
                card.ability.extra.mult =
                    (card.ability.extra.mult or 0)
                    + card.ability.extra.mult_mod
                return {
                    message = "+" .. card.ability.extra.mult_mod .. " Mult",
                }
            end
            if context.individual and context.cardarea == G.play
                and context.other_card
                and context.other_card:get_id() == 4 then
                if (card.ability.extra.mult or 0) > 0 then
                    card.ability.extra.mult = 0
                    return { message = "Reset!" }
                end
            end
        end
        if context.joker_main and (card.ability.extra.mult or 0) > 0 then
            return { mult = card.ability.extra.mult }
        end
    end,
}

SMODS.Joker {
    key = "tetrominoker",
    sprite = "tetrominoker.png",
    negative_sprite = "tetrominoker_negative.png",
    loc_txt = {
        name = "Tetrominoker",
        text = {
            "Scoring {C:attention}4s{} have a {C:green}#1# in #2#{}",
            "chance to create a {C:attention}copy{} of",
            "themselves",
        },
    },
    loc_vars = function(self, info_queue, card)
        local numerator, denominator = SMODS.get_probability_vars(
            card, 1, card.ability.extra.odds, "tetrominoker")
        return { vars = { numerator, denominator } }
    end,
    rarity = 2,
    cost = 6,
    config = { extra = { odds = 4 } },
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play
            and context.other_card
            and context.other_card:get_id() == 4 then
            if SMODS.pseudorandom_probability(
                card, "tetrominoker", 1, card.ability.extra.odds,
                "tetrominoker") then
                local oc = context.other_card
                local params = {
                    set = "Playing",
                    rank = oc:get_id(),
                    suit = oc.base and oc.base.suit,
                    bypass_limit = true,
                }
                if oc.enhancement and oc.enhancement ~= "base" then
                    params.enhancement = oc.enhancement
                end
                if oc.seal then params.seal = oc.seal end
                if oc.edition then params.edition = oc.edition end
                if SMODS.add_card(params) then
                    return { message = "Copied!" }
                end
            end
        end
    end,
}

SMODS.Joker {
    key = "stave",
    sprite = "stave.png",
    negative_sprite = "stave_negative.png",
    loc_txt = {
        name = "Stave",
        text = {
            "When a Joker with an {C:dark_edition}Edition{}",
            "is {C:money}sold{}, apply its {C:dark_edition}Edition{} to",
            "a random {C:attention}uneditioned{} Joker",
            "{C:inactive}(If possible)",
            "{C:inactive}(Excluding Negative)",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = {} }
    end,
    rarity = 2,
    cost = 7,
    config = {},
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.selling_card and not context.blueprint then
            local sold = context.port and context.port.joker
            if sold and sold.edition and sold.edition ~= "negative" then
                local targets = {}
                for _, j in ipairs((G and G.jokers) or {}) do
                    if j ~= sold and not j.edition then
                        targets[#targets + 1] = j
                    end
                end
                if #targets > 0 then
                    local target = pseudorandom_element(targets, "stave")
                    if target then
                        target.edition = sold.edition
                        return { message = "Editioned!" }
                    end
                end
            end
        end
    end,
}

-- JestPack Wave 4 chunk 7: PORTABLE Jokers (the_* .. zerco slice).
-- Ported per .jobs/wave4/CONVENTIONS.md. Deviations are named in
-- census_jokers_7.md.

--------------------------------------------------------------------------------
-- The House that Jack Built: scored Jacks give Chips and Mult equal to
-- the level of Full House (read live via G.handlist / G.hand_stats, the
-- sibling packs' hand-level pattern).
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "the_house_that_jack_built",
    sprite = "the_house_that_jack_built.png",
    negative_sprite = "the_house_that_jack_built_negative.png",
    loc_txt = {
        name = "The House that Jack Built",
        text = {
            "Scored {C:attention}Jacks{} give {C:chips}Chips{} and {C:mult}Mult{}",
            "equal to the {C:attention}level{} of {C:attention}Full House{}",
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
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play and context.other_card then
            if context.other_card:get_id() == 11 then
                local level = 1
                if G and G.handlist and G.hand_stats then
                    for i, name in ipairs(G.handlist) do
                        if name == "Full House" then
                            level = tonumber(G.hand_stats[i] and G.hand_stats[i].level) or 1
                            break
                        end
                    end
                end
                return {
                    mult = level,
                    chips = level,
                }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- The Jester: the first Joker sold each round creates The Fool.
-- (PC's juice_card_until pulse in add_to_deck is visual only and drops.)
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "the_jester",
    sprite = "the_jester.png",
    negative_sprite = "the_jester_negative.png",
    loc_txt = {
        name = "The Jester",
        text = {
            "The first {C:attention}Joker{}",
            "sold each round",
            "creates {C:tarot}The Fool{}",
            "{C:inactive}#1#{}",
        },
    },
    config = { extra = { active = true } },
    rarity = 2,
    cost = 7,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                card.ability.extra.active and "(Active)" or "(Inactive)",
            },
        }
    end,
    calculate = function(self, card, context)
        if context.selling_card and not context.selling_self then
            local sold = context.card
            if sold and sold ~= card and sold.def and sold.def.id
                and card.ability.extra.active then
                card.ability.extra.active = false
                SMODS.add_card { set = "Tarot", key = "c_fool" }
                return {
                    message = "The Fool",
                }
            end
        end
        if context.end_of_round and not card.ability.extra.active
            and not context.blueprint then
            card.ability.extra.active = true
        end
    end,
}

--------------------------------------------------------------------------------
-- The Ludovico Technique: level up the first hand of the round when
-- playing the final hand of the round. The arbitrary-hand level-up
-- goes through G:upgrade_hand_level_at_index (the sibling packs'
-- route); hands played/left read the fork's live counters.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "the_ludovico_technique",
    sprite = "the_ludovico_technique.png",
    negative_sprite = "the_ludovico_technique_negative.png",
    loc_txt = {
        name = "The Ludovico Technique",
        text = {
            "Level up the {C:attention}first hand{}",
            "of each round when playing",
            "the {C:attention}final hand{} of the round",
            "{C:inactive}(Currently {C:attention}#1#{C:inactive})",
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
    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                card.ability.extra.first_hand or "None",
            },
        }
    end,
    calculate = function(self, card, context)
        if context.before then
            if G and G.get_round_hands_played
                and G:get_round_hands_played() == 0 then
                card.ability.extra.first_hand = context.scoring_name
            end
            if (tonumber(G and G.hands) or 1) <= 0
                and card.ability.extra.first_hand then
                if G and G.handlist and G.upgrade_hand_level_at_index then
                    for i, name in ipairs(G.handlist) do
                        if name == card.ability.extra.first_hand then
                            G:upgrade_hand_level_at_index(i)
                            break
                        end
                    end
                end
                return {
                    message = "Level Up!",
                }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- They're Laughing at You...: when the Boss Blind is defeated, apply
-- Negative to a random Common Joker. Boss check is the sibling packs'
-- pattern (context.port.is_boss_blind, fallback blind index 3); the
-- edition is written on the held-Joker instance, as sibling ports do.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "theyre_laughing_at_you",
    sprite = "theyre_laughing_at_you.png",
    negative_sprite = "theyre_laughing_at_you_negative.png",
    loc_txt = {
        name = "They're Laughing at You...",
        text = {
            "When {C:attention}Boss Blind{} is defeated, apply",
            "{C:dark_edition}Negative{} to a random {C:common}Common{} Joker",
        },
    },
    config = {},
    rarity = 3,
    cost = 10,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.end_of_round and not context.game_over then
            local boss = (context.port and context.port.is_boss_blind)
                or (G and G.current_blind_index == 3)
            if boss then
                local common_jokers = {}
                for _, j in ipairs(G.jokers or {}) do
                    if j.rarity == 1 and not j.edition then
                        common_jokers[#common_jokers + 1] = j
                    end
                end
                if #common_jokers > 0 then
                    local chosen = pseudorandom_element(common_jokers, "laughing")
                    if chosen then
                        chosen.edition = "negative"
                        return {
                            message = "Editioned!",
                        }
                    end
                end
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Thomazina: scored numbered cards give +Chips, scaling per numbered
-- card scored. SMODS.scale_card inlined; the no-rank check is the
-- fork's Stone-card guard (enhancement == "stone").
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "thomazina",
    sprite = "thomazina.png",
    negative_sprite = "thomazina_negative.png",
    soul_sprite = "thomazina_soul.png",
    loc_txt = {
        name = "Thomazina",
        text = {
            "Scored {C:attention}numbered{} cards",
            "give {C:chips}+#1#{} Chips. Increases by",
            "{C:chips}+#2#{} Chips when a {C:attention}numbered{}",
            "card is scored",
        },
    },
    config = { chips = 0, chip_mod = 2 },
    rarity = 4,
    cost = 20,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                card.ability.chips,
                card.ability.chip_mod,
            },
        }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play and context.other_card then
            if not context.other_card:is_face()
                and context.other_card.enhancement ~= "stone" then
                if not context.blueprint then
                    card.ability.chips = card.ability.chips
                        + card.ability.chip_mod
                end
                return {
                    chips = card.ability.chips,
                }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Tin: retrigger all scoring cards if the played hand is a Flush.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "tin",
    sprite = "tin.png",
    negative_sprite = "tin_negative.png",
    loc_txt = {
        name = "Tin",
        text = {
            "If played hand is {C:attention}Flush{},",
            "retrigger all scoring cards{}",
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
    calculate = function(self, card, context)
        if context.repetition and context.cardarea == G.play
            and context.scoring_name == "Flush" then
            return {
                repetitions = 1,
            }
        end
    end,
}

--------------------------------------------------------------------------------
-- Tin Man: at end of round, all unenhanced Heart cards held in hand
-- become Steel (direct card_data.enhancement rewrite, the sibling
-- packs' pattern; PC's juice event drops).
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "tin_man",
    sprite = "tin_man.png",
    negative_sprite = "tin_man_negative.png",
    loc_txt = {
        name = "Tin Man",
        text = {
            "Apply {C:attention}Steel{} to all unenhanced",
            "{C:hearts}Heart{} suit cards {C:attention}held in{}",
            "{C:attention}hand{} at end of round",
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
    calculate = function(self, card, context)
        if context.end_of_round then
            local enhanced_a_card = false
            local nodes = G and G.hand and G.hand.card_nodes
            if nodes then
                for _, v in ipairs(nodes) do
                    if v:is_suit("Hearts")
                        and (v.enhancement == nil or v.enhancement == "base")
                        and not v.debuff and v.card_data then
                        v.card_data.enhancement = "steel"
                        if v.sync_visual_from_card_data then
                            v:sync_visual_from_card_data()
                        end
                        enhanced_a_card = true
                    end
                end
            end
            if enhanced_a_card then
                return {
                    message = "Steel!",
                }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Tipteerer: calc_dollar_bonus pays 25% of the other held Jokers'
-- sell value, rounded up (held list is the fork's G.jokers).
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "tipteerer",
    sprite = "tipteerer.png",
    negative_sprite = "tipteerer_negative.png",
    loc_txt = {
        name = "Tipteerer",
        text = {
            "Earn {C:attention}#2#%{} of the {C:money}sell value{}",
            "of other {C:attention}Jokers{}, rounded up,",
            "at end of {C:attention}round{}",
            "{C:inactive}(Currently{} {C:money}$#1#{}{C:inactive}){}",
        },
    },
    config = { extra = { percent = 25 } },
    rarity = 2,
    cost = 7,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    loc_vars = function(self, info_queue, card)
        local sell_cost = 0
        local list = G and G.jokers
        if type(list) == "table" and type(list.cards) == "table" then
            list = list.cards
        end
        if type(list) == "table" then
            for _, j in ipairs(list) do
                if j ~= card then
                    sell_cost = sell_cost + (tonumber(j.sell_cost) or 0)
                end
            end
        end
        return {
            vars = {
                math.ceil(sell_cost * card.ability.extra.percent / 100),
                card.ability.extra.percent,
            },
        }
    end,
    calc_dollar_bonus = function(self, card)
        local sell_cost = 0
        local list = G and G.jokers
        if type(list) == "table" and type(list.cards) == "table" then
            list = list.cards
        end
        if type(list) == "table" then
            for _, j in ipairs(list) do
                if j ~= card then
                    sell_cost = sell_cost + (tonumber(j.sell_cost) or 0)
                end
            end
        end
        local money = math.ceil(sell_cost * card.ability.extra.percent / 100)
        if money > 0 then
            return money
        end
    end,
}

--------------------------------------------------------------------------------
-- Tonpraten: +15 Mult at the final scoring step (always triggers last).
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "tonpraten",
    sprite = "tonpraten.png",
    negative_sprite = "tonpraten_negative.png",
    loc_txt = {
        name = "Tonpraten",
        text = {
            "{C:mult}+#1#{} Mult, {C:attention}always",
            "{C:attention}triggers last",
        },
    },
    config = { extra = { mult = 15 } },
    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                card.ability.extra.mult,
            },
        }
    end,
    calculate = function(self, card, context)
        if context.final_scoring_step then
            return {
                mult = card.ability.extra.mult,
            }
        end
    end,
}

--------------------------------------------------------------------------------
-- Tornado: gains X0.5 Mult after every rank has been scored at least
-- once. SMODS.Ranks enumeration becomes a static 2-14 rank table;
-- SMODS.scale_card inlined.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "tornado",
    sprite = "tornado.png",
    negative_sprite = "tornado_negative.png",
    loc_txt = {
        name = "Tornado",
        text = {
            "This Joker gains {X:mult,C:white}X#1#{} Mult",
            "after all {C:attention}ranks{} have been",
            "scored at least once",
            "{C:inactive}(Currently {X:mult,C:white}X#2#{} {C:inactive}Mult){}",
            "{C:inactive}(Remaining: #3#",
            "{C:inactive}#4#",
        },
    },
    config = { extra = { x_mult_mod = 0.5, cur_x_mult = 1, to_play_ranks = {} } },
    rarity = 2,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    loc_vars = function(self, info_queue, card)
        local rank_keys = { [2] = "2", [3] = "3", [4] = "4", [5] = "5",
            [6] = "6", [7] = "7", [8] = "8", [9] = "9", [10] = "T",
            [11] = "J", [12] = "Q", [13] = "K", [14] = "A" }
        local temp_list = {}
        if next(card.ability.extra.to_play_ranks) == nil then
            for id = 2, 14 do temp_list[id] = rank_keys[id] end
        else
            temp_list = card.ability.extra.to_play_ranks
        end
        local ranks = ""
        local ranks2 = ""
        local index = 0
        for k, v in pairs(temp_list) do
            index = index + 1
            if ranks == "" then
                ranks = v
            else
                if index > 5 then
                    if ranks2 == "" then
                        ranks2 = v
                    else
                        ranks2 = ranks2 .. ", " .. v
                    end
                else
                    ranks = ranks .. ", " .. v
                end
            end
        end
        if ranks2 ~= "" then
            ranks2 = ranks2 .. ")"
        else
            ranks = ranks .. ")"
        end
        return {
            vars = {
                card.ability.extra.x_mult_mod,
                card.ability.extra.cur_x_mult,
                ranks,
                ranks2,
            },
        }
    end,
    add_to_deck = function(self, card, from_debuff)
        local rank_keys = { [2] = "2", [3] = "3", [4] = "4", [5] = "5",
            [6] = "6", [7] = "7", [8] = "8", [9] = "9", [10] = "T",
            [11] = "J", [12] = "Q", [13] = "K", [14] = "A" }
        for id = 2, 14 do
            card.ability.extra.to_play_ranks[id] = rank_keys[id]
        end
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play
            and context.other_card then
            local id = context.other_card:get_id()
            if id and card.ability.extra.to_play_ranks[id] then
                card.ability.extra.to_play_ranks[id] = nil
            end
            if next(card.ability.extra.to_play_ranks) == nil then
                local rank_keys = { [2] = "2", [3] = "3", [4] = "4",
                    [5] = "5", [6] = "6", [7] = "7", [8] = "8", [9] = "9",
                    [10] = "T", [11] = "J", [12] = "Q", [13] = "K",
                    [14] = "A" }
                for rid = 2, 14 do
                    card.ability.extra.to_play_ranks[rid] = rank_keys[rid]
                end
                card.ability.extra.cur_x_mult = card.ability.extra.cur_x_mult
                    + card.ability.extra.x_mult_mod
                return {
                    message = localize("k_upgrade_ex"),
                }
            end
        end
        if context.joker_main then
            if card.ability.extra.cur_x_mult > 1 then
                return {
                    xmult = card.ability.extra.cur_x_mult,
                }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Toto: create 2 copies of each Tag acquired (except Double Tag).
-- PC flags its copies so they do not re-trigger; the fork raises
-- tag_added from inside G:addTag, so a file-local busy flag does the
-- same job (the Energia pattern). Copies keep the source Tag's
-- ability / Orbital hand, as PC's copy does.
--------------------------------------------------------------------------------

local jest7_toto_busy = false

SMODS.Joker {
    key = "toto",
    sprite = "toto.png",
    negative_sprite = "toto_negative.png",
    soul_sprite = "toto_soul.png",
    loc_txt = {
        name = "Toto",
        text = {
            "Create {C:attention}#1#{} copies of",
            "each {C:attention}Tag{} acquired",
            "{C:inactive}(Except Double Tag)",
        },
    },
    config = { extra = { tags = 2 } },
    rarity = 4,
    cost = 20,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                card.ability.extra.tags,
            },
        }
    end,
    calculate = function(self, card, context)
        if context.tag_added and context.tag_added and not jest7_toto_busy then
            local src = context.tag_added
            local ttype = src.type or src.key
            if ttype ~= "double" and ttype ~= "tag_double" then
                if G and G.addTag then
                    jest7_toto_busy = true
                    for _ = 1, card.ability.extra.tags do
                        if src.orbital_hand_index then
                            G:addTag(ttype, {
                                orbital_hand_index = src.orbital_hand_index,
                            })
                        else
                            G:addTag(ttype)
                        end
                        local newest = G.tags and G.tags[#G.tags]
                        if newest and src.ability then
                            local copied = {}
                            for k, v in pairs(src.ability) do
                                copied[k] = v
                            end
                            newest.ability = copied
                        end
                    end
                    jest7_toto_busy = false
                end
                return {
                    message = "Tripled!",
                }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Tract: +50 Chips per Voucher owned (live count is #(G.vouchers),
-- the sibling packs' pattern). PC's buying-card status text becomes
-- a plain message on buying a Voucher.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "tract",
    sprite = "tract.png",
    negative_sprite = "tract_negative.png",
    loc_txt = {
        name = "Tract",
        text = {
            "{C:chips}+#1#{} Chips per",
            "{C:attention}Voucher{} owned",
            "{C:inactive}(Currently {C:chips}+#2#{} {C:inactive}Chips){}",
        },
    },
    config = { extra = { chips = 0, chip_mod = 50 } },
    rarity = 3,
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    loc_vars = function(self, info_queue, card)
        local n = (G and G.vouchers and #G.vouchers) or 0
        return {
            vars = {
                card.ability.extra.chip_mod,
                n * card.ability.extra.chip_mod,
            },
        }
    end,
    calculate = function(self, card, context)
        if context.buying_card and context.card and context.card.def
            and context.card.def.id
            and context.card.def.id:sub(1, 2) == "v_" then
            local n = (G and G.vouchers and #G.vouchers) or 0
            return {
                message = "+" .. (n * card.ability.extra.chip_mod) .. " Chips",
            }
        end
        if context.joker_main then
            local n = (G and G.vouchers and #G.vouchers) or 0
            local chips = n * card.ability.extra.chip_mod
            if chips > 0 then
                return {
                    chips = chips,
                }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Triple Gooberberry Sunrise: +2 to all listed probabilities
-- (mod_probability returns absolute numerator/denominator, per the
-- fork's dialect); consumed after 3 Boss Blinds (sibling boss-check
-- pattern; self-destruct via SMODS.destroy_joker).
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "triple_gooberberry_sunrise",
    sprite = "triple_gooberberry_sunrise.png",
    negative_sprite = "triple_gooberberry_sunrise_negative.png",
    loc_txt = {
        name = "Triple Gooberberry Sunrise",
        text = {
            "{C:green}+#1#{} to all {C:attention}listed{} {C:green}probabilities{}",
            "{C:attention}consumed{} after {C:attention}#2#{} Antes",
        },
    },
    config = { extra = { odds_mod = 2, antes_remaining = 3 } },
    rarity = 2,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = false,
    perishable_compat = true,
    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                card.ability.extra.odds_mod,
                card.ability.extra.antes_remaining,
            },
        }
    end,
    calculate = function(self, card, context)
        if context.mod_probability and not context.blueprint then
            return {
                numerator = (context.numerator or 1)
                    + card.ability.extra.odds_mod,
                denominator = context.denominator,
            }
        end
        if context.end_of_round and not context.game_over
            and not context.blueprint then
            local boss = (context.port and context.port.is_boss_blind)
                or (G and G.current_blind_index == 3)
            if boss then
                if card.ability.extra.antes_remaining - 1 <= 0 then
                    SMODS.destroy_joker(card)
                    return {
                        message = "Eaten!",
                    }
                else
                    card.ability.extra.antes_remaining =
                        card.ability.extra.antes_remaining - 1
                    return {
                        message = card.ability.extra.antes_remaining .. "",
                    }
                end
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Trophy Kill: X3 Mult after a chosen rank/suit card has been
-- destroyed. The target is picked at add_to_deck from the full deck
-- (deck + discard + hand card_data, the sibling packs' pattern) and
-- stored as a rank id + suit; destroyed cards arrive via
-- remove_playing_cards' context.port.destroyed_cards. PC's soul_pos
-- carries a custom shader draw function, which drops (static soul).
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "trophy_kill",
    sprite = "trophy_kill.png",
    negative_sprite = "trophy_kill_negative.png",
    soul_sprite = "trophy_kill_soul.png",
    loc_txt = {
        name = "Trophy Kill",
        text = {
            "{X:mult,C:white}X#1#{} Mult after a {C:attention}#2# of",
            "{C:attention}#3#{} has been {C:red}destroyed",
            "{C:inactive}#4#",
        },
    },
    config = { extra = { xmult = 3.0, triggered = false, rank = "", suit = "" } },
    rarity = 3,
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    loc_vars = function(self, info_queue, card)
        local rank_names = { [11] = "Jack", [12] = "Queen", [13] = "King",
            [14] = "Ace" }
        local rank = card.ability.extra.rank
        if rank == "" and card.ability.extra.rank_id then
            rank = rank_names[card.ability.extra.rank_id]
                or tostring(card.ability.extra.rank_id)
        end
        return {
            vars = {
                card.ability.extra.xmult,
                (rank ~= "" and rank) or "[rank]",
                (card.ability.extra.suit ~= "" and card.ability.extra.suit)
                    or "[suit]",
                card.ability.extra.triggered and "(Active)" or "(Inactive)",
            },
        }
    end,
    add_to_deck = function(self, card, from_debuff)
        card.ability.extra.triggered = false
        local pool = {}
        local function add_data(data)
            if type(data) == "table" and tonumber(data.rank) and data.suit then
                pool[#pool + 1] = data
            end
        end
        if G and G.deck then
            for _, d in ipairs(G.deck.cards or {}) do add_data(d) end
            for _, d in ipairs(G.deck.discard_pile or {}) do add_data(d) end
        end
        if G and G.hand then
            if type(G.hand.cards) == "table" then
                for _, d in ipairs(G.hand.cards) do add_data(d) end
            end
            if type(G.hand.card_nodes) == "table" then
                for _, node in ipairs(G.hand.card_nodes) do
                    if node.card_data then add_data(node.card_data) end
                end
            end
        end
        if #pool > 0 then
            local pick = pseudorandom_element(pool, "trophy_kill")
            if pick then
                local rank_names = { [11] = "Jack", [12] = "Queen",
                    [13] = "King", [14] = "Ace" }
                card.ability.extra.rank_id = tonumber(pick.rank)
                card.ability.extra.rank = rank_names[tonumber(pick.rank)]
                    or tostring(pick.rank)
                card.ability.extra.suit = pick.suit
            end
        end
    end,
    calculate = function(self, card, context)
        if context.remove_playing_cards and not context.blueprint
            and not card.ability.extra.triggered then
            local removed = context.port and context.port.destroyed_cards
            if removed and card.ability.extra.rank_id then
                for _, v in ipairs(removed) do
                    if v.get_id and v:get_id() == card.ability.extra.rank_id
                        and v.is_suit
                        and v:is_suit(card.ability.extra.suit) then
                        card.ability.extra.triggered = true
                        return {
                            message = "Hunted!",
                        }
                    end
                end
            end
        end
        if context.joker_main and card.ability.extra.triggered then
            if card.ability.extra.xmult > 1 then
                return {
                    xmult = card.ability.extra.xmult,
                }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Trypophobia: +20 Mult if the scored hand contains only 8s.
-- (PC's pos is config-dependent; alter_trypophobia defaults false
-- upstream, so the {15, 0} art is the shipped one.)
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "trypophobia",
    sprite = "trypophobia.png",
    negative_sprite = "trypophobia_negative.png",
    loc_txt = {
        name = "Trypophobia",
        text = {
            "{C:mult}+#1#{} Mult if scored hand",
            "contains only {C:attention}8s{}",
        },
    },
    config = { extra = { mult = 20 } },
    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                card.ability.extra.mult,
            },
        }
    end,
    calculate = function(self, card, context)
        if context.joker_main and context.scoring_hand then
            local eights, all_cards = 0, 0
            for _, v in ipairs(context.scoring_hand) do
                all_cards = all_cards + 1
                if v:get_id() == 8 then
                    eights = eights + 1
                end
            end
            if all_cards > 0 and eights == all_cards then
                return {
                    mult = card.ability.extra.mult,
                }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Tussaud: X0.5 Mult per unique Seal in the full deck, read live
-- from the full-deck card_data (deck + discard + hand).
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "tussaud",
    sprite = "tussaud.png",
    negative_sprite = "tussaud_negative.png",
    loc_txt = {
        name = "Tussaud",
        text = {
            "Gives {X:mult,C:white}X#1#{} Mult per unique",
            "{C:attention}Seal{} in your {C:attention}full deck",
            "{C:inactive}(Currently {X:mult,C:white}X#2#{} {C:inactive}Mult){}",
        },
    },
    config = { extra = { xmult_gain = 0.5 } },
    rarity = 2,
    cost = 7,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    loc_vars = function(self, info_queue, card)
        local count = 0
        local seen = {}
        local function visit(data)
            if type(data) == "table" and data.seal and not seen[data.seal] then
                seen[data.seal] = true
                count = count + 1
            end
        end
        if G and G.deck then
            for _, d in ipairs(G.deck.cards or {}) do visit(d) end
            for _, d in ipairs(G.deck.discard_pile or {}) do visit(d) end
        end
        if G and G.hand then
            if type(G.hand.cards) == "table" then
                for _, d in ipairs(G.hand.cards) do visit(d) end
            end
            if type(G.hand.card_nodes) == "table" then
                for _, node in ipairs(G.hand.card_nodes) do
                    if node.card_data then visit(node.card_data) end
                end
            end
        end
        return {
            vars = {
                card.ability.extra.xmult_gain,
                1 + (count * card.ability.extra.xmult_gain),
            },
        }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            local count = 0
            local seen = {}
            local function visit(data)
                if type(data) == "table" and data.seal
                    and not seen[data.seal] then
                    seen[data.seal] = true
                    count = count + 1
                end
            end
            if G and G.deck then
                for _, d in ipairs(G.deck.cards or {}) do visit(d) end
                for _, d in ipairs(G.deck.discard_pile or {}) do visit(d) end
            end
            if G and G.hand then
                if type(G.hand.cards) == "table" then
                    for _, d in ipairs(G.hand.cards) do visit(d) end
                end
                if type(G.hand.card_nodes) == "table" then
                    for _, node in ipairs(G.hand.card_nodes) do
                        if node.card_data then visit(node.card_data) end
                    end
                end
            end
            if count > 0 then
                return {
                    xmult = 1 + (count * card.ability.extra.xmult_gain),
                }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Unobtanium: retrigger all scoring cards if the played hand is a
-- Five of a Kind. (PC's in_pool gate -- Five of a Kind played this
-- run -- drops per the pack conventions on in_pool gates.)
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "unobtanium",
    sprite = "unobtanium.png",
    negative_sprite = "unobtanium_negative.png",
    loc_txt = {
        name = "Unobtanium",
        text = {
            "If played hand is {C:attention}Five of a Kind{},",
            "retrigger all scoring cards{}",
        },
    },
    config = {},
    rarity = 2,
    cost = 7,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.repetition and context.cardarea == G.play
            and context.scoring_name == "Five of a Kind" then
            return {
                repetitions = 1,
            }
        end
    end,
}

--------------------------------------------------------------------------------
-- Uranium: retrigger all scoring cards if the played hand is a
-- Two Pair.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "uranium",
    sprite = "uranium.png",
    negative_sprite = "uranium_negative.png",
    loc_txt = {
        name = "Uranium",
        text = {
            "If played hand is {C:attention}Two Pair{},",
            "retrigger all scoring cards{}",
        },
    },
    config = { extra = {} },
    rarity = 2,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.repetition and context.cardarea == G.play
            and context.scoring_name == "Two Pair" then
            return {
                repetitions = 1,
            }
        end
    end,
}

--------------------------------------------------------------------------------
-- Valentine: X1.5 Mult per unique pair in the played hand (PC's
-- returned xmult is the product, kept verbatim). Stone cards are
-- skipped, matching PC's get_id() <= 0 for them.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "valentine",
    sprite = "valentine.png",
    negative_sprite = "valentine_negative.png",
    loc_txt = {
        name = "Valentine",
        text = {
            "{X:mult,C:white}X#1#{} Mult per {C:attention}unique pair{}",
            "in {C:attention}scored hand{}",
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
    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                card.ability.extra.x_mult,
            },
        }
    end,
    calculate = function(self, card, context)
        if context.joker_main and context.full_hand then
            local ranks = {}
            for _, played_card in ipairs(context.full_hand) do
                local id = played_card:get_id()
                if id and id > 0 and played_card.enhancement ~= "stone" then
                    ranks[id] = (ranks[id] or 0) + 1
                end
            end
            local unique_pairs = 0
            for _, count in pairs(ranks) do
                if count >= 2 then
                    unique_pairs = unique_pairs + 1
                end
            end
            if unique_pairs > 0 then
                return {
                    xmult = card.ability.extra.x_mult * unique_pairs,
                }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Veggie Joker: gains triple a destroyed numbered card's rank as
-- Chips. Destroyed cards arrive via remove_playing_cards'
-- context.port.destroyed_cards (PC's context.removed);
-- SMODS.scale_card inlined.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "veggie_joker",
    sprite = "veggie_joker.png",
    negative_sprite = "veggie_joker_negative.png",
    loc_txt = {
        name = "Veggie Joker",
        text = {
            "When any {C:attention}numbered card{} is",
            "{C:red}destroyed{}, this Joker gains",
            "{C:attention}triple{} its rank as {C:chips}Chips",
            "{C:inactive}(Currently {C:chips}+#1#{} {C:inactive}Chips){}",
        },
    },
    config = { extra = { chips = 0 } },
    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                card.ability.extra.chips,
            },
        }
    end,
    calculate = function(self, card, context)
        if context.remove_playing_cards and not context.blueprint then
            local removed = context.port and context.port.destroyed_cards
            local total_ranks = 0
            if removed then
                for _, v in ipairs(removed) do
                    local id = v.get_id and v:get_id()
                    if id and id >= 2 and id <= 10 then
                        total_ranks = total_ranks + id
                    end
                end
            end
            if total_ranks > 0 then
                card.ability.extra.chips = card.ability.extra.chips
                    + total_ranks * 3
                return {
                    message = "+" .. (total_ranks * 3) .. " Chips",
                }
            end
        end
        if context.joker_main then
            return {
                chips = card.ability.extra.chips,
            }
        end
    end,
}

--------------------------------------------------------------------------------
-- Vesti la Giubba: after a hand containing a Straight, create a
-- random Common or Uncommon Joker (50/50). The random-by-rarity
-- creation is the sibling packs' G:random_joker_def_id_by_rarity
-- route; SMODS.add_card itself reports no room.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "vesti_la_guibba",
    sprite = "vesti_la_guibba.png",
    negative_sprite = "vesti_la_guibba_negative.png",
    loc_txt = {
        name = "Vesti la Giubba",
        text = {
            "If {C:attention}played hand{} contains",
            "a {C:attention}Straight{}, create a random",
            "{C:common}Common{} or {C:uncommon}Uncommon{} Joker",
            "{C:inactive}(Must have room)",
        },
    },
    config = {},
    rarity = 2,
    cost = 7,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.after and context.poker_hands
            and next(context.poker_hands["Straight"]) then
            local rarity = 1
            if pseudorandom("vesti_la_guibba") > 0.5 then
                rarity = 2
            end
            local id = G and G.random_joker_def_id_by_rarity
                and G:random_joker_def_id_by_rarity(rarity, "vesti_la_guibba")
                or nil
            if id then
                local made = SMODS.add_card { set = "Joker", key = id }
                if made then
                    return {
                        message = "+ Joker",
                    }
                end
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Vitellary: credits Joker. No calculate at all; in_pool always
-- false. PC's set_card_type_badge creator badge and no_collection
-- flag have no fork seat and drop.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "vitellary_credits_joker",
    sprite = "vitellary_credits_joker.png",
    negative_sprite = "vitellary_credits_joker_negative.png",
    loc_txt = {
        name = "Vitellary",
        text = {
            "{C:inactive}\"Learning everything all the time\"",
        },
    },
    config = {},
    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = false,
    perishable_compat = true,
    in_pool = function(self, args)
        return false
    end,
}

--------------------------------------------------------------------------------
-- Vitruvian Clown: X2 Mult if exactly 5 Jokers are owned (the held
-- list is the fork's G.jokers).
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "vitruvian_joker",
    sprite = "vitruvian_joker.png",
    negative_sprite = "vitruvian_joker_negative.png",
    loc_txt = {
        name = "Vitruvian Clown",
        text = {
            "{X:mult,C:white}X#1#{} Mult if exactly {C:attention}5{}",
            "Jokers are owned",
        },
    },
    config = { extra = { xmult = 2 } },
    rarity = 2,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                card.ability.extra.xmult,
            },
        }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            local list = G and G.jokers
            if type(list) == "table" and type(list.cards) == "table" then
                list = list.cards
            end
            if type(list) == "table" and #list == 5 then
                return {
                    xmult = card.ability.extra.xmult,
                }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Whiteface Grotesque: gains +1 Chips for each face card held in
-- hand when a hand is played; SMODS.scale_card inlined.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "whiteface_grotesque",
    sprite = "whiteface_grotesque.png",
    negative_sprite = "whiteface_grotesque_negative.png",
    loc_txt = {
        name = "Whiteface Grotesque",
        text = {
            "This Joker gains {C:chips}+#1#{} Chips",
            "for each {C:attention}face{} card {C:attention}held in",
            "{C:attention}hand{} when hand is played",
            "{C:inactive}(Currently {C:chips}+#2#{C:inactive} Chips)",
        },
    },
    config = { extra = { chip_mod = 1, cur_chips = 0 } },
    rarity = 1,
    cost = 4,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                card.ability.extra.chip_mod,
                card.ability.extra.cur_chips,
            },
        }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.hand
            and not context.end_of_round and not context.blueprint
            and context.other_card then
            if context.other_card:is_face() then
                card.ability.extra.cur_chips = card.ability.extra.cur_chips
                    + card.ability.extra.chip_mod
                return {
                    message = localize("k_upgrade_ex"),
                }
            end
        end
        if context.joker_main then
            if card.ability.extra.cur_chips > 0 then
                return {
                    chips = card.ability.extra.cur_chips,
                }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Windswept Joker: if the played hand contains a Straight Flush,
-- level up Straight Flush by 2. The scored hand IS the Straight
-- Flush, so the fork's level_up return at joker_main does PC's
-- level_up_hand work (totals gain the level delta, as on PC).
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "windswept_joker",
    sprite = "windswept_joker.png",
    negative_sprite = "windswept_joker_negative.png",
    loc_txt = {
        name = "Windswept Joker",
        text = {
            "If played hand contains a",
            "{C:attention}Straight Flush{}, level up",
            "{C:attention}Straight Flush{} by {C:attention}#1#{} levels",
        },
    },
    config = { extra = { levels = 2 } },
    rarity = 3,
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                card.ability.extra.levels,
            },
        }
    end,
    calculate = function(self, card, context)
        if context.joker_main and context.poker_hands
            and next(context.poker_hands["Straight Flush"]) then
            return {
                message = localize("k_upgrade_ex"),
                level_up = card.ability.extra.levels,
            }
        end
    end,
}

--------------------------------------------------------------------------------
-- Wire Joker: scored Queens give $4 and X0.5 Mult. PC's
-- G.GAME.dollar_buffer bookkeeping drops (a dollars return pays
-- directly, per the conventions).
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "wire_joker",
    sprite = "wire_joker.png",
    negative_sprite = "wire_joker_negative.png",
    loc_txt = {
        name = "Wire Joker",
        text = {
            "{C:attention}Queens{} give {X:mult,C:white}X#2#{} Mult",
            "and {C:money}$#1#{} when scored",
        },
    },
    config = { extra = { xmult = 0.5, dollars = 4 } },
    rarity = 3,
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                card.ability.extra.dollars,
                card.ability.extra.xmult,
            },
        }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play
            and context.other_card then
            if context.other_card:get_id() == 12 then
                return {
                    dollars = card.ability.extra.dollars,
                    xmult = card.ability.extra.xmult,
                }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Wizard: each scoring non-enhanced card has a 1 in 4 chance to
-- become a Mult, Bonus or Lucky card (equal thirds, PC's roll
-- order). The enhancement is written directly on card_data, the
-- sibling packs' pattern; PC's juice event drops.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "wizard",
    sprite = "wizard.png",
    negative_sprite = "wizard_negative.png",
    loc_txt = {
        name = "Wizard",
        text = {
            "{C:green}#1# in #2#{} chance for each",
            "scoring {C:attention}non-enhanced{} card",
            "to become a {C:attention}Mult Card{}",
            "{C:attention}Bonus Card{}, or {C:attention}Lucky Card",
        },
    },
    config = { extra = { odds = 4 } },
    rarity = 3,
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    loc_vars = function(self, info_queue, card)
        local numerator, denominator = SMODS.get_probability_vars(
            card, 1, card.ability.extra.odds, "wizard")
        return {
            vars = {
                numerator,
                denominator,
            },
        }
    end,
    calculate = function(self, card, context)
        if context.before and not context.blueprint and context.scoring_hand then
            local upgraded = {}
            for _, v in ipairs(context.scoring_hand) do
                if (v.enhancement == nil or v.enhancement == "base")
                    and SMODS.pseudorandom_probability(
                        card, "wizard", 1, card.ability.extra.odds) then
                    upgraded[#upgraded + 1] = v
                end
            end
            if #upgraded > 0 then
                for _, v in ipairs(upgraded) do
                    local type_roll = pseudorandom("wizard_type")
                    local new_enhancement = "mult"
                    if type_roll > 0.66 then
                        new_enhancement = "bonus"
                    elseif type_roll > 0.33 then
                        new_enhancement = "lucky"
                    end
                    if v.card_data then
                        v.card_data.enhancement = new_enhancement
                        if v.sync_visual_from_card_data then
                            v:sync_visual_from_card_data()
                        end
                    end
                end
                return {
                    message = "Change!",
                }
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Word Art: X0.5 Mult per Ace, King, Queen or Jack in the played
-- hand (returned as 1 + 0.5 per card, PC's shape).
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "word_art",
    sprite = "word_art.png",
    negative_sprite = "word_art_negative.png",
    loc_txt = {
        name = "Word Art",
        text = {
            "Gives {X:mult,C:white}X#1#{} Mult per",
            "{C:attention}Ace{}, {C:attention}King{}, {C:attention}Queen{}, or",
            "{C:attention}Jack{} in played hand",
        },
    },
    config = { extra = { xmult_per_card = 0.5 } },
    rarity = 3,
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                card.ability.extra.xmult_per_card,
            },
        }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            local cards = 0
            for _, p_card in ipairs(context.full_hand or {}) do
                local id = p_card:get_id()
                if id == 11 or id == 12 or id == 13 or id == 14 then
                    cards = cards + 1
                end
            end
            return {
                xmult = 1 + card.ability.extra.xmult_per_card * cards,
            }
        end
    end,
}

--------------------------------------------------------------------------------
-- Yang: scoring Light-suit (Hearts/Diamonds) cards give Mult per
-- unique Light Suit in the scored hand.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "yang",
    sprite = "yang.png",
    negative_sprite = "yang_negative.png",
    loc_txt = {
        name = "Yang",
        text = {
            "Scoring {C:hearts}Light Suits{} give {C:mult}+#1#{}",
            "Mult per {C:attention}unique{} {C:hearts}Light Suit{}",
            "in {C:attention}scored hand{}",
        },
    },
    config = { extra = { mult = 5 } },
    rarity = 2,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                card.ability.extra.mult,
            },
        }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play
            and context.other_card then
            if context.other_card:is_suit("Hearts")
                or context.other_card:is_suit("Diamonds") then
                local light_suits = { Hearts = 0, Diamonds = 0 }
                for _, played_card in ipairs(context.scoring_hand or {}) do
                    if played_card:is_suit("Hearts") then
                        light_suits.Hearts = 1
                    end
                    if played_card:is_suit("Diamonds") then
                        light_suits.Diamonds = 1
                    end
                end
                local unique_count = light_suits.Hearts + light_suits.Diamonds
                if unique_count > 0 then
                    return {
                        mult = unique_count * card.ability.extra.mult,
                    }
                end
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Yin: scoring Dark-suit (Spades/Clubs) cards give Mult per unique
-- Dark Suit in the scored hand.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "yin",
    sprite = "yin.png",
    negative_sprite = "yin_negative.png",
    loc_txt = {
        name = "Yin",
        text = {
            "Scoring {C:spades}Dark Suits{} give {C:mult}+#1#{}",
            "Mult per {C:attention}unique{} {C:spades}Dark Suit{}",
            "in {C:attention}scored hand{}",
        },
    },
    config = { extra = { mult = 5 } },
    rarity = 2,
    cost = 6,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                card.ability.extra.mult,
            },
        }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play
            and context.other_card then
            if context.other_card:is_suit("Spades")
                or context.other_card:is_suit("Clubs") then
                local dark_suits = { Spades = 0, Clubs = 0 }
                for _, played_card in ipairs(context.scoring_hand or {}) do
                    if played_card:is_suit("Spades") then
                        dark_suits.Spades = 1
                    end
                    if played_card:is_suit("Clubs") then
                        dark_suits.Clubs = 1
                    end
                end
                local unique_count = dark_suits.Spades + dark_suits.Clubs
                if unique_count > 0 then
                    return {
                        mult = unique_count * card.ability.extra.mult,
                    }
                end
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- You've Got Mail: on Blind select, a non-Negative copy creates a
-- Negative copy of itself with a random effect and $0 sell value
-- (the effect and sell_cost are written on the created instance,
-- the sibling packs' pattern). PC's two SMODS.Sound cues and the
-- loc colour table drop; the dynamic loc strings are computed in
-- loc_vars exactly as PC computes them.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "youve_got_mail",
    sprite = "youve_got_mail.png",
    negative_sprite = "youve_got_mail_negative.png",
    loc_txt = {
        name = "You've Got Mail",
        text = {
            "If {C:red}Not{} {C:dark_edition}Negative{}, when",
            "{C:attention}Blind{} is selected, create a",
            "{C:dark_edition}Negative {C:attention}copy{} of this Joker",
            "with {C:money}$0{} sell value",
            "{V:1}{B:3,V:2}#1##2#{}{V:1}#3#",
        },
    },
    config = { extra = { mult = 4, chips = 20, dollars = 1, xmult = 0.25,
        effect = "none", prefix = "", text = "Does nothing..." } },
    rarity = 3,
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    loc_vars = function(self, info_queue, card)
        local e = card.ability.extra
        local prefix, num, text = "", "", e.text
        if e.effect == "mult" then
            prefix = "+"
            num = e.mult
            text = " Mult"
        elseif e.effect == "chips" then
            prefix = "+"
            num = e.chips
            text = " Chips"
        elseif e.effect == "dollars" then
            prefix = "+"
            num = e.dollars .. "$"
            text = " each hand played"
        elseif e.effect == "xmult" then
            prefix = "X"
            num = e.xmult + 1
            text = " Mult"
        else
            text = "Does nothing..."
        end
        return {
            vars = {
                prefix,
                num,
                text,
            },
        }
    end,
    calculate = function(self, card, context)
        if context.setting_blind and not context.blueprint
            and card.edition ~= "negative" then
            local made = SMODS.add_card {
                set = "Joker",
                key = "j_aij_youve_got_mail",
                edition = "negative",
            }
            if made then
                local effects = { "mult", "chips", "none", "dollars", "xmult" }
                made.ability.extra.effect =
                    effects[SMODS.pseudorandom("aij_youve_got_mail", 1, #effects)]
                made.sell_cost = 0
                return {
                    message = "You've Got Mail!",
                }
            end
        end
        if context.joker_main then
            if card.ability.extra.effect == "mult" then
                return {
                    mult = card.ability.extra.mult,
                }
            elseif card.ability.extra.effect == "chips" then
                return {
                    chips = card.ability.extra.chips,
                }
            elseif card.ability.extra.effect == "dollars" then
                return {
                    dollars = card.ability.extra.dollars,
                }
            elseif card.ability.extra.effect == "xmult" then
                return {
                    xmult = card.ability.extra.xmult + 1,
                }
            end
        end
        if context.selling_self then
            return {
                message = "Goodbye",
            }
        end
    end,
}

--------------------------------------------------------------------------------
-- Yu Zhan: Jokers without Editions give X2 Mult. PC's other_joker
-- context seats on the fork's post_trigger (other_card /
-- other_context.joker_main); self is excluded, as other_joker
-- excludes it on PC.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "yu_sze",
    sprite = "yu_sze.png",
    negative_sprite = "yu_sze_negative.png",
    soul_sprite = "yu_sze_soul.png",
    loc_txt = {
        name = "Yu Zhan",
        text = {
            "Jokers without {C:dark_edition}Editions{}",
            "give {X:mult,C:white}X#1#{} Mult",
        },
    },
    config = { xmult = 2 },
    rarity = 4,
    cost = 20,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                card.ability.xmult,
            },
        }
    end,
    calculate = function(self, card, context)
        if context.post_trigger and context.other_card
            and context.other_card ~= card
            and context.other_context and context.other_context.joker_main
            and (context.other_card.edition == nil
                or context.other_card.edition == "base") then
            return {
                xmult = card.ability.xmult,
            }
        end
    end,
}

--------------------------------------------------------------------------------
-- Zanni: scored numbered cards have a 1 in 10 chance to create a
-- Tarot card (random Tarot via the sibling packs'
-- random_consumable_id_of_kind route; SMODS.add_card itself
-- reports no room). The no-rank check is the Stone guard.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "zanni",
    sprite = "zanni.png",
    negative_sprite = "zanni_negative.png",
    loc_txt = {
        name = "Zanni",
        text = {
            "{C:attention}Numbered{} cards have a {C:green}#1# in #2#{}",
            "chance to create a {C:tarot}Tarot{} card",
            "when {C:attention}scored",
        },
    },
    config = { extra = { odds = 10 } },
    rarity = 2,
    cost = 7,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    loc_vars = function(self, info_queue, card)
        local numerator, denominator = SMODS.get_probability_vars(
            card, 1, card.ability.extra.odds, "zanni")
        return {
            vars = {
                numerator,
                denominator,
            },
        }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play
            and context.other_card then
            if not context.other_card:is_face()
                and context.other_card.enhancement ~= "stone" then
                if SMODS.pseudorandom_probability(
                    card, "zanni", 1, card.ability.extra.odds) then
                    local id = G and G.random_consumable_id_of_kind
                        and G:random_consumable_id_of_kind(
                            "tarot", nil, "zanni") or nil
                    if id then
                        local made = SMODS.add_card {
                            set = "Tarot",
                            key = id,
                        }
                        if made then
                            return {
                                message = "+ Tarot",
                            }
                        end
                    end
                end
            end
        end
    end,
}

--------------------------------------------------------------------------------
-- Zenzizenzizenzic: with exactly 4 scoring cards, gains Chips on
-- trigger and its scaling grows. Both SMODS.scale_card calls
-- inlined, in PC's order (scaling grows first, then Chips gain by
-- the new scaling).
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "zenzizenzizenzic",
    sprite = "zenzizenzizenzic.png",
    negative_sprite = "zenzizenzizenzic_negative.png",
    loc_txt = {
        name = "Zenzizenzizenzic",
        text = {
            "{C:chips}+#1#{} Chips if scoring hand ",
            "contains exactly {C:attention}4{} cards",
            "Gains {C:chips}+#2#{} Chips on trigger, and",
            "increase {C:attention}scaling{} by {C:attention}+#3#{}",
        },
    },
    config = { extra = { chips = 0, mod = 0, mod_mod = 2 } },
    rarity = 3,
    cost = 8,
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = false,
    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                card.ability.extra.chips,
                card.ability.extra.mod,
                card.ability.extra.mod_mod,
            },
        }
    end,
    calculate = function(self, card, context)
        if context.before and context.scoring_hand
            and #context.scoring_hand == 4 and not context.blueprint then
            card.ability.extra.mod = card.ability.extra.mod
                + card.ability.extra.mod_mod
            card.ability.extra.chips = card.ability.extra.chips
                + card.ability.extra.mod
            return {
                message = localize("k_upgrade_ex"),
            }
        end
        if context.joker_main and context.scoring_hand
            and #context.scoring_hand == 4 then
            return {
                chips = card.ability.extra.chips,
            }
        end
    end,
}

--------------------------------------------------------------------------------
-- Zerco: applies Negative to the first scored card each round (if
-- it has no Edition). The playing-card edition is written on
-- card_data.modifier.edition, the sibling packs' Aura pattern;
-- PC's delayed event becomes a direct write in `after`, gated on
-- the fork's round-hands-played counter, as PC gates on
-- current_round.hands_played.
--------------------------------------------------------------------------------

SMODS.Joker {
    key = "zerco",
    sprite = "zerco.png",
    negative_sprite = "zerco_negative.png",
    soul_sprite = "zerco_soul.png",
    loc_txt = {
        name = "Zerco",
        text = {
            "Applies {C:dark_edition}Negative{} to {C:attention}first{}",
            "scored {C:attention}card{} each {C:attention}round{}",
            "{C:inactive}(if it has no existing Edition)",
        },
    },
    config = {},
    rarity = 4,
    cost = 20,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.after and context.scoring_hand
            and context.scoring_hand[1] and not context.blueprint
            and G and G.get_round_hands_played
            and G:get_round_hands_played() == 0 then
            local target = context.scoring_hand[1]
            local data = target.card_data
            if data and not data.edition
                and not (data.modifier and data.modifier.edition) then
                data.modifier = data.modifier or {}
                data.modifier.edition = "negative"
                if target.sync_visual_from_card_data then
                    target:sync_visual_from_card_data()
                end
            end
        end
    end,
}
