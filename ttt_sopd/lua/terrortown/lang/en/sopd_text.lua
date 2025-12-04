local L = LANG.GetLanguageTableReference("en")

L["sopd_instruction_targeted"] = "Defeat target"
L["sopd_instruction_for_target"] = "Defeat yourself"
L["sopd_instruction_for_jester"] = "Pretend to swing"
L["sopd_instruction_targetless"] = "Defeat any player"
L["sopd_instruction_stab"] = "Stab target's corpse"
L["sopd_instruction_stab_coverup"] = "Stab target's corpse & destroy evidence"
L["sopd_instruction_pap_lmb"] = "Inhale enemy"
L["sopd_instruction_pap_lmb_what"] = "Inhale enemy... again?"
L["sopd_instruction_pap_lmb_self"] = "Inhale yourself?"
L["sopd_instruction_pap_lmb_no_ammo"] = "Swing fruitlessly (out of ammo)"
L["sopd_instruction_pap_lmb2"] = "Swing triumphantly"
L["sopd_instruction_pap_rmb"] = "Toggle copy ability (disguise)"
L["sopd_instruction_useless"] = "Swing fruitlessly (your enemy has vanished)"

L["sopd_target_notif1"] = "The Sword seeks you."
L["sopd_target_notif2"] = "You've been selected by the Sword."
L["sopd_target_notif3"] = "Someone with a Sword may come looking for you."
L["sopd_target_notif4"] = "The Sword deems you worthy... of defeat."
L["sopd_target_notif5"] = "A bell tolls for you."

L["sopd_instantkill"] = "DEFEAT"
L["sopd_instanteat"] = "INHALE"

L["label_sopd_targets_form"] = "Target Selection"
L["label_sopd_target_disconnect_mode_desc"] = [[
The Sword is meant to have a target picked randomly among non-Traitors at round start, but in certain cases may not (deathmatch mode or a target could not be selected, see below). The Sword will work on the target even if they disconnect.
You can specify the behavior of a "refund" mechanic for when the Sword has a target player but they disconnect mid-round.

Note that it is not recommended to allow the Sword to be re-buyable if your settings make it likely for the Sword to become targetless. If a Sword is targetless, it can be used to kill anybody (without target-specific effects).]]
L["label_sopd_target_disconnect_mode"] = "Behavior when target player disconnects mid-round"
L["label_sopd_tgtdcm_no_op"] = "Do nothing"
L["label_sopd_tgtdcm_pick_new"] = "Always pick new target"
L["label_sopd_tgtdcm_pick_new_cond"] = "Pick new target unless a Sword was used"
L["label_sopd_tgtdcm_untarget"] = "Always make Sword targetless"
L["label_sopd_tgtdcm_untarget_cond"] = "Make Sword targetless unless one was used"
L["label_sopd_can_target_dead_desc"] = "Only relevant if the above behavior allows drawing a new target mid-round (players cannot be dead at round start)."
L["label_sopd_can_target_dead"] = "Dead players with a valid ragdoll can be selected as the target"
L["label_sopd_can_target_jesters"] = "Jesters can be selected as the target"
L["label_sopd_notify_target"] = "Notify target players when they are selected"
L["label_sopd_target_min_poolsize_desc"] = "If the number of possible targets is lower than this value when it's time to pick a new one, the Sword will become targetless."
L["label_sopd_target_min_poolsize"] = "Minimum pool size for Sword to pick targets"

L["label_sopd_sword_form"] = "Sword Properties"
L["label_sopd_range_buff_desc"] = "Multiplier of the base TTT2 knife's range (1 = same range as knife)"
L["label_sopd_range_buff"] = "Sword range buff"
L["label_sopd_speedup"] = "Speed multiplier while holding Sword"
L["label_sopd_dna_destruction_desc"] = "Note that Swords grabbed from bodies cannot further remove DNA time."
L["label_sopd_dna_destruction"] = "Time removed from DNA sample on stab"
L["label_sopd_destroy_evidence"] = "Stabbing the target's ragdoll covers up their true death cause (reducing DNA as described above)"
L["label_sopd_grab_stuck_swords"] = "Swords stuck in bodies can be grabbed again"
L["label_sopd_target_glow"] = "Target glows through walls while holding Sword"
L["label_sopd_dmg_block_desc"] = "For the below two: 100% = fully block damage from player(s), 0% = no block. Affects shop description."
L["label_sopd_target_dmg_block"] = "Damage resist. from target player while holding Sword (%)"
L["label_sopd_others_dmg_block"] = "Damage resist. from other players while holding Sword (%)"

L["label_sopd_pap_form"] = "Pack a Punch"
L["label_sopd_pap_heal"] = "Heal from inhaling an enemy"
L["label_sopd_pap_dmg_block_desc"] = "Similar to (and adds to) the two damage resist. options in General Gameplay, but from any player and only if PaP'd."
L["label_sopd_pap_dmg_block"] = "Damage resist. from players while holding Sword (%)"

L["label_sopd_sfx_form"] = "Sound & Volume"
L["label_sopd_sfx_deploy_soundlevel_desc"] = "Determines how far players can be & still hear the Sword deploy song (100 or more covers most of any map)."
L["label_sopd_sfx_deploy_soundlevel"] = "Sword deploy song audible range (dB)"
L["label_sopd_sfx_volume_desc"] = "Base volume for both sound effect types before any stealth-related reductions."
L["label_sopd_sfx_deploy_volume"] = "Base Sword deploy song volume (%)"
L["label_sopd_sfx_kill_volume"] = "Base Sword kill sound volume (%)"
L["label_sopd_sfx_special_swing_chance"] = "Chance for special SFX when swinging Sword in the air (%)"
L["label_sopd_sfx_oatmeal_for_last"] = "Sword plays \"1, 2, Oatmeal\" when deployed with only one opponent left"
L["label_sopd_sfx_stealth_desc"] = [[
Stealth: If there are n or more opponents (inno/side team members) left alive, the Sword's sound effect volumes are reduced by v. For less than n opponents, this effect gets proportionally weaker, going away completely at 1 opponent left.
  - If v = 0%, no reduction occurs.
  - If v = 100%, the Sword is silent at n or more opponents alive.
  - For stab noises, v is multiplied by k, which reduces it and thus makes stabs louder (unless k = 100%).
  - Formula: adjVol = vol * (1 - v * k * min(1, (oppCnt - 1) / (n - 1)))]]
L["label_sopd_sfx_stealth_vol_reduction"] = "[Stealth] v = Max volume reduction (%)"
L["label_sopd_sfx_stealth_max_opps"] = "[Stealth] n = Max reduction minimum opponent count"
L["label_sopd_sfx_stealth_stab_factor"] = "[Stealth] k = Effect strength for stabbing noises (%)"

L["label_sopd_misc_form"] = "Debugging & Miscellaneous"
L["label_sopd_give_guy_access"] = "Allow author to change Sword of Player Defeat convars"
L["label_sopd_debug"] = "Enable debug prints"