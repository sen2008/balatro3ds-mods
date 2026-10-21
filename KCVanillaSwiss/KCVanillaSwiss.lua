-- KCVanilla: Swiss Cheese -- 3DS port
--
-- Original: "Swiss Cheese" from KCVanilla (PC, Steamodded) by krackocloud
--   https://github.com/kcgidw/kcvanilla  (jokers/swiss.lua, v3.8.1)
-- Ported to Balatro3DS (idkhan/Balatro3DS) for Lucas, 2026-10-20.
--
-- What changed from the PC version, and why:
--   * SMODS.Atlas + pos removed -- Balatro3DS has no atlases. The Joker names
--     its own image with sprite = "swiss.png" (assets/1x/swiss.t3x on the 3DS),
--     cropped from the PC atlas cell (71x95 -> 70x94, the border is transparent).
--   * negative_sprite added -- the 3DS cannot run the PC Negative shader, so a
--     pre-made Negative image ships beside the normal one (made with the
--     Balatro3DS dev tool dev/make_negative.py).
--   * loc_txt inlined from KCVanilla's localization/en-us.lua (the 3DS port
--     reads name/text from the Joker definition itself).
--   * The effect code is the original, unchanged: it only uses
--     context.joker_main, context.scoring_hand and card:get_id(), which
--     Balatro3DS's SMODS layer supports exactly (see its MODDING.md).
--     scoring_hand there is the scoring subset, same as on PC.

local function kcv_count_unique_gaps(cards)
    local ranks_in_hand = {}
    for _, card in ipairs(cards) do
        local id = card:get_id()
        ranks_in_hand[id] = true
    end
    local count = 0
    for n = 3, 13 do
        if ranks_in_hand[n - 1] and ranks_in_hand[n + 1] and not ranks_in_hand[n] then
            count = count + 1
        end
    end
    -- A 2 3
    if ranks_in_hand[14] and ranks_in_hand[3] and not ranks_in_hand[2] then
        count = count + 1
    end
    return count
end

SMODS.Joker {
    key = "swiss",
    loc_txt = {
        name = "Swiss Cheese",
        text = {
            "{X:mult,C:white} X1 {} Mult for each",
            "{C:attention}gap of 1 rank{} ",
            "between the ranks in",
            "played poker hand",
            "{C:inactive}(ex: {C:attention}2s{C:inactive} and {C:attention}4s{C:inactive}, but no {C:attention}3{C:inactive})",
        },
    },
    config = {
        extra = {
            xmult = 1
        }
    },
    rarity = 3,
    cost = 8,
    unlocked = true,
    discovered = true,
    eternal_compat = true,
    perishable_compat = true,
    blueprint_compat = true,
    sprite = "swiss.png",
    negative_sprite = "swiss_negative.png",
    loc_vars = function(self, info_queue, card)
        return {}
    end,
    calculate = function(self, card, context)
        if context.joker_main and context.scoring_hand then
            local count = kcv_count_unique_gaps(context.scoring_hand)
            if count > 0 then
                return {
                    xmult = (count * card.ability.extra.xmult) + 1
                }
            end
        end
    end
}
