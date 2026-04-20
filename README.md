See [the addon's workshop page](https://steamcommunity.com/sharedfiles/filedetails/?id=3607870957) and [this](https://www.youtube.com/watch?v=0Dpw0VvH4m0) for more information.<br>The addon's changelog can be found [here](https://steamcommunity.com/sharedfiles/filedetails/changelog/3607870957).<br>For any issues with the item (that I don't already know about), please report them here in the Issues tracker.

*What a triumph is that...*

# Convars

All of this information can be found in the item's F1 → Edit Equipment menu.

## Target Selection

The Sword is meant to have a target picked randomly among non-Traitors at round start, but in certain cases may not (deathmatch mode or a target could not be selected, see below). The Sword will work on the target even if they disconnect.
You can specify the behavior of a "refund" mechanic for when the Sword has a target player but they disconnect mid-round.

Note that it is not recommended to allow the Sword to be re-buyable if your settings make it likely for the Sword to become targetless. If a Sword is targetless, it can be used to kill anybody (without target-specific effects).

| ttt2_sopd_... | Description | Default |
| ------------- | ----------- | ------- |
| **target_disconnect_mode** | Specifies the behavior when the target player disconnects mid-round.<br> • 0 = Do nothing.<br> • 1 = Always pick new target.<br> • 2 = Pick new target unless a Sword was used.<br> • 3 = Always make Sword targetless.<br> • 4 = Make Sword targetless unless one was used. | 2 |
| **can_target_dead** | Whether dead players can be selected as the target.<br>*Note*: Only relevant if the above behavior allows drawing a new target mid-round (players cannot be dead at round start). | true |
| **can_target_jesters** | Whether Jesters can be selected as the target. | true |
| **notify_target** | Whether to notify target players when they are selected. | false |
| **target_min_poolsize** | Minimum pool size for Sword to pick targets (if the number of possible targets is lower than this value when it's time to pick a new one, the Sword will become targetless). | 2 |

## Sword Properties

Note that changing most of these updates the item's shop description to reflect the new properties.

| ttt2_sopd_... | Description | Default |
| ------------- | ----------- | ------- |
| **range_buff** | Multiplier of the base TTT2 knife's range (1 = same range as knife). | 1.5 |
| **speedup** | Player speed multiplier while holding the Sword.<br>*Note*: Does not apply to Swords that were retrieved from bodies. | 1.3 |
| **dna_destruction** | Time removed from DNA sample on stab, in seconds.<br>*Note*: Does not apply to Swords that were retrieved from bodies. | 60 |
| **destroy_evidence** | Whether stabbing a dead target with the Sword makes it seem like the Sword killed them (reducing DNA as described above). | true |
| **grab_stuck_swords** | Whether targeted Swords that are stuck in bodies can be retrieved. | true |
| **target_glow** | Whether the target player glows for a player holding the Sword. | true |
| **target_dmg_block** | Percent of damage the Sword holder blocks from the target (0 = take full damage, 100 = take no damage) | 100 |
| **others_dmg_block** | Percent of damage the Sword holder blocks from non-targets (same as above) | 0 |
| **can_teamkill** | Whether players on the same side of the Sword target pool boundary can swing the Sword at each other. Jesters are considered evil aligned for this. | false |

## Pack-a-Punch

| ttt2_sopd_... | Description | Default |
| ------------- | ----------- | ------- |
| **pap_heal** | How much health is gained from inhaling an enemy with the Sword of Player Def-Eat. | 80 |
| **pap_dmg_block** | Percent of damage the Sword holder blocks from everyone if packed.<br>Added on top of the non-PaP damage blocks. | 0 |

## Sound & Volume

**Stealth mechanic**: If there are n or more opponents (inno/side team members) left alive, the Sword's sound effect volumes are reduced by v. For less than n opponents, this effect gets proportionally weaker, going away completely at 1 opponent left.
* If v = 0%, no reduction occurs.
* If v = 100%, the Sword is silent at n or more opponents alive.
* For stab noises, v is multiplied by k, which reduces it and thus makes stabs louder (unless k = 100%).
* **Formula:** `adjVol = vol * (1 - v * k * min(1, (oppCnt - 1) / (n - 1)))`

| ttt2_sopd_... | Description | Default |
| ------------- | ----------- | ------- |
| **sfx_deploy_soundlevel** | Determines how far players can be & still hear the Sword deploy song (100 or more covers most of any map). | 100 |
| **sfx_deploy_volume** | The Sword deploy song's volume, before any stealth-related reductions. | 100 |
| **sfx_kill_volume** | The Sword kill sound's volume, before any stealth-related reductions. | 100 |
| **sfx_special_swing_chance** | Percent chance for a special sound effect to play when swinging a Sword in the air. | 10 |
| **sfx_oatmeal_for_last** | Whether "1, 2, Oatmeal" plays as the deploy song when the target is the last opponent alive. | true |
| **sfx_stealth_vol_reduction** | (v) The volume of Sword sounds is reduced by this factor when many opponents (inno/side teams) are alive. | 50 |
| **sfx_stealth_max_opps** | (n) The stealth volume reduction on Sword sound effects is fully applied when this many opponents (inno/side teams) or more are alive. | 10 |
| **sfx_stealth_stab_factor** | (k) Multiplier to the stealth volume reduction factor for stabbing noises. | 50 |

## Debugging & Miscellaneous

| ttt2_sopd_... | Description | Default |
| ------------- | ----------- | ------- |
| **give_guy_access** | Whether the developer can change the addon's convars (inspired by Spanospy's [Jimbo](https://steamcommunity.com/sharedfiles/filedetails/?id=3494499094) addon). | false |
| **debug** | Enables addon debug prints for client & server (should not be enabled for real play). | false |
