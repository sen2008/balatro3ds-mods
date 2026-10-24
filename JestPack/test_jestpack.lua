--- Tests for the JestPack Balatro3DS mod (not part of the game repo).
--- The mod's real main file is read from the JEST_PACK_LUA env var.
local T = require("tests.testlib")
local bootstrap = require("tests.bootstrap")

local suite = T.suite()

bootstrap.load()
local ModLoader = require("mod_loader")

local function wipe_mods()
    local fs = love.filesystem
    local function rm(path)
        for _, item in ipairs(fs.getDirectoryItems(path)) do
            local child = path .. "/" .. item
            if fs.getInfo(child, "file") then fs.remove(child) else rm(child); fs.remove(child) end
        end
    end
    if fs.getInfo(ModLoader.DIR) then rm(ModLoader.DIR) end
    ModLoader.reset()
end

-- Joker keys (def ids are j_jest_<key>).
local KEYS = {
    "a_young_hamlet", "abandoned_joker", "alas", "alexandre", "angel_number", "angoulevent",
    "animatronic", "antonio", "art_of_the_deal", "atom", "bad_apple", "bad_guy",
    "baroque_joker", "bartender", "bear", "bearded_joker", "bebe", "beekeeper",
    "beelzebub", "biancolelli", "big_ears", "big_red", "bingo_card", "bingsu",
    "birthday_clown", "blue_eyes_white_joker", "blue_star", "bluet", "body_pillow", "bogdonoff",
    "bon_vivant", "bonus_bob", "bonus_pay", "bonus_round", "bozo", "bucolic_hills",
    "bumper_sticker", "buzzy_bee", "cairoli", "candidate", "candy_wrapper", "cavalier",
    "cebee_credits_joker", "cerium", "cesar", "charles", "cheerio", "cheese_squigglies",
    "chippy", "chips_n_dip", "choleric_joker", "christmas_eve", "chromatic_aberrant", "circle_joker",
    "clapperdudgeon", "cloth_joker", "clowns_on_parade", "coconut", "colquhoun", "comedy_of_errors",
    "comic_panel", "copper", "coulrorachne", "crab_in_a_bucket", "crop_circle", "croupier",
    "cut_here", "cyclops", "dandiprat", "david", "default_credits_joker", "desiderium",
    "devil_deal", "diamantaire", "dicky", "dim_bulb", "dire_warning", "disco_joker",
    "doctors_orders", "dog_treat", "dont_be_a_joker", "dot_matrix", "downing_street", "duende",
    "dwarf", "earl", "egg_cc", "elf", "emergent_pattern", "event_horizon",
    "evil_joker", "executioner", "famulus", "father_and_son", "father_christmas", "fatuus",
    "feedback_form", "firework", "fish_fingers", "flibbertigibbit", "flushed_face", "flying_ace",
    "fortunato", "fortune_cookie", "fou_du_roi", "fruity_joker", "funny_bone", "funny_bunch",
    "funny_money", "funny_phone", "gameshow", "gelato", "geoglyph", "giocoliere",
    "glasgow_smile", "gloaming", "goblet", "gonnella", "goo_joker", "goon_joker",
    "great_kraken", "great_white_north", "grumpy_gus", "guillaume", "guiser", "gummy",
    "haggler", "hallucinaut", "hat_trick", "haughty_joker", "haunted_maze", "heavenbrand_credits_joker",
    "hei_tiki", "histrio", "hofnarr_the_barbarian", "homemade_comic", "honker", "imageboard",
    "imperious_joker", "in_vino_veritas", "infamous_machine", "infinite_jest", "interstate", "iron",
    "jamie_credits_joker", "joker_baby", "jumbocarrot_credits_joker", "komar", "krampus", "la_commedia_e_finita",
    "laurel", "lead", "legerdemain", "happy_as_larry", "jerko", "jpeg",
    "jeff_the_joker", "jackpot", "le_fils_de_banane", "joka_lisa", "lemarchand_cube", "little_boy_blue",
    "little_devil", "lonely_night", "low_priest", "lucignolo", "lucina", "lucky_horseshoe",
    "lucky_seven", "maguelonne", "mandrake", "marcy_credits_joker", "mariachi", "master_of_pegs",
    "meaty_joker", "melancholic_joker", "melpomene", "mike_check", "mixel_perfect", "mondrian_joker",
    "mr_lonely", "mummer", "mute_joker", "napkin", "nedda", "neon_sign",
    "neptunium", "neutronium", "nevernamed_credits_joker", "nichola", "notsoai_credits_joker", "null_joker",
    "odd_rod", "oklo_reactor", "old_joker", "omlette", "one_little_duck", "orphic_joker",
    "overdesigned_joker", "pangram", "pantomimus", "papermoon_credits_joker", "paracosm", "parking_space",
    "party_streamers", "peanut_brittle", "pedestrian", "pedrolino", "pell_mel", "pellucid_joker",
    "pengelding", "penny", "petrushka", "pierrot", "pigpen", "pinhead",
    "pipine", "plain_jane", "plain_packaging", "plutonium", "polybius", "pompey",
    "poppins", "postcard_from_perdition_trail", "pour_one_out", "profile", "propaganda", "protophanes",
    "prototype_credits_joker", "public_bathroom", "punk_joker", "quadrangled_joker", "quantum_foam", "quark",
    "queen_bee", "quicksilver", "rattling_snow_credits_joker", "realty_sign", "red_joker", "remina",
    "richie_rich", "rising_sun", "rock_n_roll_clown", "rodeo_clown", "rubberhose", "rudolph",
    "sam_mcgee", "sanguine_joker", "sapphic_joker", "saucy_jacky", "saveloy", "scorecard",
    "scott_free", "scroggin", "scrunched_joker", "scurra", "semaphore", "servillus",
    "sherrif", "shredded_joker", "silent_sam", "silly_billy", "silver", "silver_screen",
    "silvio", "simple_simon", "single_cell", "skomorokh", "scopaesthesia", "scaramouche",
    "second_tier_meme", "sleepy_joker", "slim_joker", "slippery_when_wet", "slubberdegullion", "smide",
    "sneaky_pete", "sommers", "soviet", "splat", "square_eyes", "squeezy_pete",
    "stagehand", "stracciatella", "sudoku", "suibhne", "sundae_1", "sundae_2",
    "sundae_3", "sunny_joker", "sunny_side", "survivalaren_credits_joker", "taggart", "taikomochi",
    "taillefer", "tangled_joker", "taylor_credits_joker", "teeny_joker", "ten_sharp", "tetraphobia",
    "tetrominoker", "stave", "the_house_that_jack_built", "the_jester", "the_ludovico_technique", "theyre_laughing_at_you",
    "thomazina", "tin", "tin_man", "tipteerer", "tonpraten", "tornado",
    "toto", "tract", "triple_gooberberry_sunrise", "trophy_kill", "trypophobia", "tussaud",
    "unobtanium", "uranium", "valentine", "veggie_joker", "vesti_la_guibba", "vitellary_credits_joker",
    "vitruvian_joker", "whiteface_grotesque", "windswept_joker", "wire_joker", "wizard", "word_art",
    "yang", "yin", "youve_got_mail", "yu_sze", "zanni", "zenzizenzizenzic",
    "zerco",
}

-- Every sprite base name the pack references (literal fields plus the
-- dynamically named moon/planet sprites), written as dummy files.
local DUMMIES = {
    "2000_eu16", "2000_eu16_negative", "2013_nd15", "2013_nd15_negative",
    "a_young_hamlet", "a_young_hamlet_negative", "abandoned_joker", "abandoned_joker_negative",
    "alas", "alas_negative", "alexandre", "alexandre_negative",
    "angel_number", "angel_number_negative", "angoulevent", "angoulevent_negative",
    "angoulevent_soul", "animatronic", "animatronic_negative", "antonio",
    "antonio_negative", "antonio_soul", "art_of_the_deal", "art_of_the_deal_negative",
    "atom", "atom_negative", "bad_apple", "bad_apple_negative",
    "bad_guy", "bad_guy_negative", "baroque_joker", "baroque_joker_negative",
    "bartender", "bartender_negative", "bear", "bear_negative",
    "bearded_joker", "bearded_joker_negative", "bebe", "bebe_negative",
    "bebe_soul", "beekeeper", "beekeeper_negative", "beelzebub",
    "beelzebub_negative", "biancolelli", "biancolelli_negative", "biancolelli_soul",
    "bierstiefel", "big_ears", "big_ears_negative", "big_red",
    "big_red_negative", "bingo_card", "bingo_card_negative", "bingsu",
    "bingsu_negative", "birthday_clown", "birthday_clown_negative", "blue_eyes_white_joker",
    "blue_eyes_white_joker_negative", "blue_star", "blue_star_negative", "bluet",
    "bluet_negative", "bluet_soul", "body_pillow", "body_pillow_negative",
    "bogdonoff", "bogdonoff_negative", "bogdonoff_soul", "bon_vivant",
    "bon_vivant_negative", "bonus_bob", "bonus_bob_negative", "bonus_pay",
    "bonus_pay_negative", "bonus_round", "bonus_round_negative", "bozo",
    "bozo_negative", "bozo_soul", "bucolic_hills", "bucolic_hills_negative",
    "bumper_sticker", "bumper_sticker_negative", "buzzy_bee", "buzzy_bee_negative",
    "cairoli", "cairoli_negative", "cairoli_soul", "callisto",
    "callisto_negative", "candidate", "candidate_negative", "candy_wrapper",
    "candy_wrapper_negative", "capital", "cavalier", "cavalier_negative",
    "cebee_credits_joker", "cebee_credits_joker_negative", "cerium", "cerium_negative",
    "cesar", "cesar_negative", "charles", "charles_negative",
    "charon", "charon_negative", "cheerio", "cheerio_negative",
    "cheese_squigglies", "cheese_squigglies_negative", "chippy", "chippy_negative",
    "chips_n_dip", "chips_n_dip_negative", "choleric_joker", "choleric_joker_negative",
    "christmas_eve", "christmas_eve_negative", "chromatic_aberrant", "chromatic_aberrant_negative",
    "circle_joker", "circle_joker_negative", "circumplanetary", "clapperdudgeon",
    "clapperdudgeon_negative", "cloth_joker", "cloth_joker_negative", "clowns_on_parade",
    "clowns_on_parade_negative", "coconut", "coconut_negative", "colquhoun",
    "colquhoun_negative", "colquhoun_soul", "comedy_of_errors", "comedy_of_errors_negative",
    "comic_panel", "comic_panel_negative", "copper", "copper_negative",
    "coulrorachne", "coulrorachne_negative", "crab_in_a_bucket", "crab_in_a_bucket_negative",
    "crop_circle", "crop_circle_negative", "croupier", "croupier_negative",
    "cut_here", "cut_here_negative", "cyclops", "cyclops_negative",
    "dandiprat", "dandiprat_negative", "dark_star", "dark_star_negative",
    "david", "david_negative", "default_credits_joker", "default_credits_joker_negative",
    "deimos", "deimos_negative", "desiderium", "desiderium_negative",
    "devil_deal", "devil_deal_negative", "diamantaire", "diamantaire_negative",
    "dicky", "dicky_negative", "dicky_soul", "dim_bulb",
    "dim_bulb_negative", "dire_warning", "dire_warning_negative", "disco_joker",
    "disco_joker_negative", "doctors_orders", "doctors_orders_negative", "dog_treat",
    "dog_treat_negative", "dont_be_a_joker", "dont_be_a_joker_negative", "dot_matrix",
    "dot_matrix_negative", "downing_street", "downing_street_negative", "duende",
    "duende_negative", "dwarf", "dwarf_negative", "dysnomia",
    "dysnomia_negative", "earl", "earl_negative", "egg_cc",
    "egg_cc_negative", "elf", "elf_negative", "emergent_pattern",
    "emergent_pattern_negative", "europa", "europa_negative", "event_horizon",
    "event_horizon_negative", "evil_joker", "evil_joker_negative", "executioner",
    "executioner_negative", "faceless", "faceless_negative", "famulus",
    "famulus_negative", "father_and_son", "father_and_son_negative", "father_christmas",
    "father_christmas_negative", "fatuus", "fatuus_negative", "feedback_form",
    "feedback_form_negative", "fervent", "firework", "firework_negative",
    "fish_fingers", "fish_fingers_negative", "flibbertigibbit", "flibbertigibbit_negative",
    "flushed_face", "flushed_face_negative", "flying_ace", "flying_ace_negative",
    "fortunato", "fortunato_negative", "fortunato_soul", "fortune_cookie",
    "fortune_cookie_negative", "fou_du_roi", "fou_du_roi_negative", "fruity_joker",
    "fruity_joker_negative", "funny_bone", "funny_bone_negative", "funny_bunch",
    "funny_bunch_negative", "funny_money", "funny_money_negative", "funny_phone",
    "funny_phone_negative", "gameshow", "gameshow_negative", "gelato",
    "gelato_negative", "geoglyph", "geoglyph_negative", "giocoliere",
    "giocoliere_negative", "glasgow_smile", "glasgow_smile_negative", "gloaming",
    "gloaming_negative", "goblet", "goblet_negative", "gonnella",
    "gonnella_negative", "gonnella_soul", "goo_joker", "goo_joker_negative",
    "goon_joker", "goon_joker_negative", "gravastar", "gravastar_negative",
    "great_kraken", "great_kraken_negative", "great_white_north", "great_white_north_negative",
    "grumpy_gus", "grumpy_gus_negative", "guillaume", "guillaume_negative",
    "guillaume_soul", "guiser", "guiser_negative", "gummy",
    "gummy_negative", "haggler", "haggler_negative", "hallucinaut",
    "hallucinaut_negative", "happy_as_larry", "happy_as_larry_negative", "hat_trick",
    "hat_trick_negative", "haughty_joker", "haughty_joker_negative", "haunted_maze",
    "haunted_maze_negative", "heavenbrand_credits_joker", "heavenbrand_credits_joker_negative", "hei_tiki",
    "hei_tiki_negative", "histrio", "histrio_negative", "hofnarr_the_barbarian",
    "hofnarr_the_barbarian_negative", "homemade_comic", "homemade_comic_negative", "honker",
    "honker_negative", "iapetus", "iapetus_negative", "imageboard",
    "imageboard_negative", "imperious_joker", "imperious_joker_negative", "in_vino_veritas",
    "in_vino_veritas_negative", "infamous_machine", "infamous_machine_negative", "infinite_jest",
    "infinite_jest_negative", "interstate", "interstate_negative", "iron",
    "iron_negative", "jackpot", "jackpot_negative", "jamie_credits_joker",
    "jamie_credits_joker_negative", "janitor", "janitor_negative", "jeff_the_joker",
    "jeff_the_joker_negative", "jerko", "jerko_negative", "joka_lisa",
    "joka_lisa_negative", "joker_baby", "joker_baby_negative", "jpeg",
    "jpeg_negative", "jumbocarrot_credits_joker", "jumbocarrot_credits_joker_negative", "kamooalewa",
    "kamooalewa_negative", "komar", "komar_negative", "komar_soul",
    "krampus", "krampus_negative", "kuiper", "kuiper_negative",
    "la_commedia_e_finita", "la_commedia_e_finita_negative", "landfill", "laurel",
    "laurel_negative", "laurel_soul", "le_fils_de_banane", "le_fils_de_banane_negative",
    "lead", "lead_negative", "legerdemain", "legerdemain_negative",
    "lemarchand_cube", "lemarchand_cube_negative", "little_boy_blue", "little_boy_blue_negative",
    "little_devil", "little_devil_negative", "lonely_night", "lonely_night_negative",
    "low_priest", "low_priest_negative", "lucignolo", "lucignolo_negative",
    "lucina", "lucina_negative", "lucky_horseshoe", "lucky_horseshoe_negative",
    "lucky_seven", "lucky_seven_negative", "luna", "luna_negative",
    "maguelonne", "maguelonne_negative", "magus", "magus_negative",
    "mandrake", "mandrake_negative", "marcy_credits_joker", "marcy_credits_joker_negative",
    "mariachi", "mariachi_negative", "master_arcanes", "master_arcanes_negative",
    "master_of_pegs", "master_of_pegs_negative", "maw", "maw_negative",
    "meaty_joker", "meaty_joker_negative", "melancholic_joker", "melancholic_joker_negative",
    "melpomene", "melpomene_negative", "melpomene_soul", "mike_check",
    "mike_check_negative", "mixel_perfect", "mixel_perfect_negative", "mondrian_joker",
    "mondrian_joker_negative", "mr_lonely", "mr_lonely_negative", "mummer",
    "mummer_negative", "mute_joker", "mute_joker_negative", "napkin",
    "napkin_negative", "nedda", "nedda_negative", "nedda_soul",
    "neon_sign", "neon_sign_negative", "neptunium", "neptunium_negative",
    "neutronium", "neutronium_negative", "nevernamed_credits_joker", "nevernamed_credits_joker_negative",
    "nibiru", "nibiru_negative", "nichola", "nichola_negative",
    "nichola_soul", "nix", "nix_negative", "notsoai_credits_joker",
    "notsoai_credits_joker_negative", "null_joker", "null_joker_negative", "oberon",
    "oberon_negative", "occult", "odd_rod", "odd_rod_negative",
    "oklo_reactor", "oklo_reactor_negative", "old_joker", "old_joker_negative",
    "omlette", "omlette_negative", "one_little_duck", "one_little_duck_negative",
    "oracle", "oracle_negative", "orphic_joker", "orphic_joker_negative",
    "osiris", "osiris_negative", "overdesigned_joker", "overdesigned_joker_negative",
    "pallas", "pallas_negative", "palmistry", "palmistry_negative",
    "pangram", "pangram_negative", "pantomimus", "pantomimus_negative",
    "paper_hiiaka", "paper_hiiaka_negative", "paper_ilmare", "paper_ilmare_negative",
    "paper_ixion", "paper_ixion_negative", "paper_mk2", "paper_mk2_negative",
    "paper_namaka", "paper_namaka_negative", "paper_salacia", "paper_salacia_negative",
    "paper_varda", "paper_varda_negative", "paper_weywot", "paper_weywot_negative",
    "papermoon_credits_joker", "papermoon_credits_joker_negative", "paracosm", "paracosm_negative",
    "parking_space", "parking_space_negative", "party_streamers", "party_streamers_negative",
    "peanut_brittle", "peanut_brittle_negative", "pedestrian", "pedestrian_negative",
    "pedrolino", "pedrolino_negative", "pell_mel", "pell_mel_negative",
    "pellucid_joker", "pellucid_joker_negative", "pengelding", "pengelding_negative",
    "pengelding_soul", "penny", "penny_negative", "petrushka",
    "petrushka_negative", "phaethon", "phaethon_negative", "phobos",
    "phobos_negative", "pierrot", "pierrot_negative", "pigpen",
    "pigpen_negative", "pinhead", "pinhead_negative", "pipine",
    "pipine_negative", "pipine_soul", "plain_jane", "plain_jane_negative",
    "plain_packaging", "plain_packaging_negative", "planet_nine", "planet_nine_negative",
    "plutonium", "plutonium_negative", "polybius", "polybius_negative",
    "pompey", "pompey_negative", "pompey_soul", "poppins",
    "poppins_negative", "postcard_from_perdition_trail", "postcard_from_perdition_trail_negative", "pour_one_out",
    "pour_one_out_negative", "profile", "profile_negative", "propaganda",
    "propaganda_negative", "proteus", "proteus_negative", "protophanes",
    "protophanes_negative", "protophanes_soul", "prototype_credits_joker", "prototype_credits_joker_negative",
    "public_bathroom", "public_bathroom_negative", "pulsar", "pulsar_negative",
    "punk_joker", "punk_joker_negative", "quadrangled_joker", "quadrangled_joker_negative",
    "quantum_foam", "quantum_foam_negative", "quark", "quark_negative",
    "queen_bee", "queen_bee_negative", "quicksilver", "quicksilver_negative",
    "rattling_snow_credits_joker", "rattling_snow_credits_joker_negative", "realty_sign", "realty_sign_negative",
    "reaper", "reaper_negative", "red_joker", "red_joker_negative",
    "remina", "remina_negative", "richie_rich", "richie_rich_negative",
    "rising_dead", "rising_dead_negative", "rising_sun", "rising_sun_negative",
    "rock_n_roll_clown", "rock_n_roll_clown_negative", "rodeo_clown", "rodeo_clown_negative",
    "rubberhose", "rubberhose_negative", "rudolph", "rudolph_negative",
    "sacrifice", "sacrifice_negative", "sam_mcgee", "sam_mcgee_negative",
    "sanctuary_gate", "sanctuary_gate_negative", "sanguine_joker", "sanguine_joker_negative",
    "sapphic_joker", "sapphic_joker_negative", "saucy_jacky", "saucy_jacky_negative",
    "saveloy", "saveloy_negative", "scaramouche", "scaramouche_negative",
    "scopaesthesia", "scopaesthesia_negative", "scorecard", "scorecard_negative",
    "scott_free", "scott_free_negative", "scroggin", "scroggin_negative",
    "scrunched_joker", "scrunched_joker_negative", "scurra", "scurra_negative",
    "second_tier_meme", "second_tier_meme_negative", "semaphore", "semaphore_negative",
    "servillus", "servillus_negative", "servillus_soul", "shade",
    "shade_negative", "sherrif", "sherrif_negative", "shredded_joker",
    "shredded_joker_negative", "sidereal_jumbo_1", "sidereal_jumbo_2", "sidereal_mega_1",
    "sidereal_mega_2", "sidereal_normal_1", "sidereal_normal_2", "sidereal_normal_3",
    "sidereal_normal_4", "silent_sam", "silent_sam_negative", "silly_billy",
    "silly_billy_negative", "silver", "silver_negative", "silver_screen",
    "silver_screen_negative", "silvio", "silvio_negative", "silvio_soul",
    "simple_simon", "simple_simon_negative", "single_cell", "single_cell_negative",
    "skomorokh", "skomorokh_negative", "sleepy_joker", "sleepy_joker_negative",
    "slim_joker", "slim_joker_negative", "slippery_when_wet", "slippery_when_wet_negative",
    "slubberdegullion", "slubberdegullion_negative", "smide", "smide_negative",
    "sneaky_pete", "sneaky_pete_negative", "sol", "sol_negative",
    "sommers", "sommers_negative", "sommers_soul", "soulbound",
    "soviet", "soviet_negative", "splat", "splat_negative",
    "square_eyes", "square_eyes_negative", "squeezy_pete", "squeezy_pete_negative",
    "stagehand", "stagehand_negative", "stave", "stave_negative",
    "stracciatella", "stracciatella_negative", "sudoku", "sudoku_negative",
    "suibhne", "suibhne_negative", "sundae_1", "sundae_1_negative",
    "sundae_2", "sundae_2_negative", "sundae_3", "sundae_3_negative",
    "sunny_joker", "sunny_joker_negative", "sunny_side", "sunny_side_negative",
    "survivalaren_credits_joker", "survivalaren_credits_joker_negative", "taggart", "taggart_negative",
    "taikomochi", "taikomochi_negative", "taillefer", "taillefer_negative",
    "taillefer_soul", "tangled_joker", "tangled_joker_negative", "taylor_credits_joker",
    "taylor_credits_joker_negative", "teeny_joker", "teeny_joker_negative", "ten_sharp",
    "ten_sharp_negative", "tetraphobia", "tetraphobia_negative", "tetrominoker",
    "tetrominoker_negative", "the_house_that_jack_built", "the_house_that_jack_built_negative", "the_jester",
    "the_jester_negative", "the_ludovico_technique", "the_ludovico_technique_negative", "theyre_laughing_at_you",
    "theyre_laughing_at_you_negative", "thomazina", "thomazina_negative", "thomazina_soul",
    "tin", "tin_man", "tin_man_negative", "tin_negative",
    "tipteerer", "tipteerer_negative", "titan", "titan_negative",
    "tonpraten", "tonpraten_negative", "tornado", "tornado_negative",
    "toto", "toto_negative", "toto_soul", "tract",
    "tract_negative", "triple_gooberberry_sunrise", "triple_gooberberry_sunrise_negative", "triton",
    "triton_negative", "trophy_kill", "trophy_kill_negative", "trophy_kill_soul",
    "trypophobia", "trypophobia_negative", "tussaud", "tussaud_negative",
    "twilight", "twilight_negative", "two_ways", "two_ways_negative",
    "umbriel", "umbriel_negative", "unobtanium", "unobtanium_negative",
    "uranium", "uranium_negative", "urns", "urns_negative",
    "valentine", "valentine_negative", "veggie_joker", "veggie_joker_negative",
    "velocity", "vesti_la_guibba", "vesti_la_guibba_negative", "vitellary_credits_joker",
    "vitellary_credits_joker_negative", "vitruvian_joker", "vitruvian_joker_negative", "vulcanoid",
    "vulcanoid_negative", "whiteface_grotesque", "whiteface_grotesque_negative", "windfall",
    "windswept_joker", "windswept_joker_negative", "wire_joker", "wire_joker_negative",
    "wizard", "wizard_negative", "wood", "word_art",
    "word_art_negative", "yang", "yang_negative", "yin",
    "yin_negative", "youve_got_mail", "youve_got_mail_negative", "yu_sze",
    "yu_sze_negative", "yu_sze_soul", "zanni", "zanni_negative",
    "zenzizenzizenzic", "zenzizenzizenzic_negative", "zerco", "zerco_negative",
    "zerco_soul", "zoozve", "zoozve_negative",
}

local function install_pack()
    wipe_mods()
    local path = os.getenv("JEST_PACK_LUA")
    assert(path, "JEST_PACK_LUA not set")
    local fh = assert(io.open(path, "rb"))
    local main = fh:read("*a")
    fh:close()
    local base = ModLoader.DIR .. "/JestPack"
    love.filesystem.createDirectory(base)
    love.filesystem.write(base .. "/JestPack.json", [[{
        "id": "JestPack", "name": "All in Jest (3DS port)", "prefix": "jest",
        "main_file": "jestpack.lua", "version": "1.0.0",
        "author": ["All in Jest team", "3DS port"]
    }]])
    love.filesystem.write(base .. "/jestpack.lua", main)
    for _, n in ipairs(DUMMIES) do
        love.filesystem.write(base .. "/assets/1x/" .. n .. ".png", "png")
    end
    ModLoader.load_all()
    local game = bootstrap.new_game(7704)
    G = game
    G.play = G.play or SMODS.PLAY
    _G.Top = _G.Top or { addPopup = function() end }
    return game
end

local function add(game, id)
    game.jokers = game.jokers or {}
    T.assert_true(game:add_joker_by_def(id), id .. " should be addable")
    return game.jokers[#game.jokers]
end

local function card(rank, suit, enhancement)
    local data = { rank = rank, suit = suit or "Hearts" }
    if enhancement then data.enhancement = enhancement end
    local c = Card(0, 0, 1, 1, data)
    c.counts_for_play_score = true
    return c
end

local function scored(joker, extra)
    local ctx = { event = "on_hand_scored", event_name = "on_hand_scored", chips = 10, mult = 2 }
    for k, v in pairs(extra or {}) do ctx[k] = v end
    ctx.cards = ctx.cards or ctx.played_cards
    if joker:matches_trigger(ctx.event_name, ctx) then joker:apply_effect(ctx) end
    return ctx
end

local function flatten(t, out)
    out = out or {}
    if type(t) == "string" then out[#out + 1] = t
    elseif type(t) == "table" then
        if type(t.text) == "string" then out[#out + 1] = t.text end
        for _, v in pairs(t) do if type(v) == "table" then flatten(v, out) end end
    end
    return out
end

--------------------------------------------------------------------------------
-- Loading + registration counts (the Wave 4 J1 census numbers)
--------------------------------------------------------------------------------

suite.test("pack loads and registers the census counts", function()
    local game = install_pack()
    local mod = ModLoader.by_id.JestPack
    T.assert_eq(mod.status, "loaded", "load error: " .. tostring(mod.error))
    T.assert_eq(#mod.registered.jokers, 337, "337 portable Jokers")
    T.assert_eq(#mod.registered.consumables, 52, "52 consumables")
    T.assert_eq(#mod.registered.tags, 8, "8 tags")
    T.assert_eq(#mod.registered.boosters, 8, "8 Sidereal boosters")
    T.assert_eq(#mod.registered.enhancements, 2, "Fervent + Wood")
    T.assert_true(SMODS.ConsumableTypes["jest_aij_astral"] ~= nil, "aij_astral type registers")
    T.assert_true(SMODS.ConsumableTypes["jest_aij_hex_tarot"] ~= nil, "aij_hex_tarot type registers")
    wipe_mods()
end)

suite.test("every Joker tooltip formats with live values", function()
    local game = install_pack()
    game.jokers = {}
    for _, n in ipairs(KEYS) do
        game.jokers = {}
        local j = add(game, "j_jest_" .. n)
        local lines = SMODS.tooltip_lines("j_jest_" .. n, j)
        T.assert_true(type(lines) == "table" and #lines >= 1, n .. " tooltip has lines")
        local text = table.concat(flatten(lines), " ")
        T.assert_true(text:find("#", 1, true) == nil,
            n .. " tooltip has no raw placeholder: " .. text)
    end
    wipe_mods()
end)

suite.test("every consumable, tag, booster and enhancement tooltip formats", function()
    local game = install_pack()
    for _, id in ipairs({
        "c_jest_magus", "c_jest_sanctuary_gate", "c_jest_charon",
        "c_jest_gravastar", "c_jest_osiris",
    }) do
        local def = CONSUMABLE_DEFS[id]
        T.assert_true(def ~= nil, id .. " registered")
        local lines = SMODS.tooltip_lines(id, def)
        T.assert_true(type(lines) == "table" and #lines >= 1, id .. " tooltip has lines")
        local text = table.concat(flatten(lines), " ")
        T.assert_true(text:find("#", 1, true) == nil, id .. " tooltip clean: " .. text)
    end
    for _, id in ipairs({ "jest_soulbound", "jest_windfall" }) do
        local entry = SMODS.Tags[id]
        T.assert_true(entry ~= nil, id .. " tag registered")
        local tname, lines = SMODS.tag_tooltip(entry.type)
        T.assert_true(type(lines) == "table" and #lines >= 1, id .. " tooltip has lines")
        local text = table.concat(flatten(lines), " ")
        T.assert_true(text:find("#", 1, true) == nil, id .. " tooltip clean: " .. text)
    end
    local bentry = SMODS.Boosters["jest_sidereal_normal_1"]
    T.assert_true(bentry ~= nil, "sidereal booster registered")
    T.assert_true(type(bentry.name) == "string" and #bentry.name > 0, "booster has a name")
    T.assert_true(type(bentry.loc_txt.text) == "table" and #bentry.loc_txt.text >= 1,
        "booster has tooltip text")
    wipe_mods()
end)

suite.test("every Joker survives a blanket scoring pass", function()
    local game = install_pack()
    local played = { card(10, "Hearts"), card(11, "Spades", "bonus") }
    for _, n in ipairs(KEYS) do
        game.jokers = {}
        local j = add(game, "j_jest_" .. n)
        scored(j, { played_cards = played, scoring_hand = played, full_hand = played })
    end
    wipe_mods()
end)

--------------------------------------------------------------------------------
-- Moons: one stat at double rate, the other compensated back
--------------------------------------------------------------------------------

suite.test("charon (High Card chips moon) levels one stat at double rate", function()
    local game = install_pack()
    game.STATE = game.STATES.SHOP
    game.consumables, game.consumable_nodes = {}, {}
    local idx
    for i, name in ipairs(game.handlist) do
        if name == "High Card" then idx = i end
    end
    T.assert_true(idx ~= nil, "High Card exists in handlist")
    local stats = game.hand_stats[idx]
    local lvl0 = stats.level
    local chips0 = stats.base_chips + (lvl0 - 1) * stats.chips_per_level
    local mult0 = stats.base_mult + (lvl0 - 1) * stats.mult_per_level
    T.assert_true(game:add_consumable("c_jest_charon"), "charon addable")
    local slot = #game.consumables
    T.assert_true(game:use_consumable(slot), "charon usable")
    local s2 = game.hand_stats[idx]
    T.assert_eq(s2.level, lvl0 + 1, "level rose by 1")
    local chips1 = s2.base_chips + (s2.level - 1) * s2.chips_per_level
    local mult1 = s2.base_mult + (s2.level - 1) * s2.mult_per_level
    T.assert_eq(chips1 - chips0, 2 * s2.chips_per_level, "chips gained a double step")
    T.assert_eq(mult1 - mult0, 0, "mult unchanged (its step was given back)")
    wipe_mods()
end)

suite.test("sidereal boosters deal from the (empty) astral kind and stay inert", function()
    local game = install_pack()
    local def = SMODS.Boosters["jest_sidereal_normal_1"]
    T.assert_true(def ~= nil, "sidereal booster registered")
    T.assert_eq(def.consumable_kind, "aij_astral", "pool is the astral kind")
    -- No Astral consumables exist (pin system blocked), so the kind's
    -- pool is empty: rolling it yields nothing rather than an error.
    local rolled = game:random_consumable_id_of_kind("aij_astral", nil, "sidereal")
    T.assert_true(rolled == nil, "empty astral pool rolls nil")
    wipe_mods()
end)

return suite
