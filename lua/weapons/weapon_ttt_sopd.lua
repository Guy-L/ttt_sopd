----------------------------------
------- CONSTANTS & CVARS --------
----------------------------------
local TryT  = LANG.TryTranslation
local utils = SoPD_Utils
local dbg   = SoPD_DBG
local snd   = SoPD_Sounds
local CLASS_NAME   = "weapon_ttt_sopd"
local DEFAULT_NAME = "Sword of Player Defeat"
local SWORD_VIEWMODEL  = "models/ttt/sopd/v_sopd.mdl"
local SWORD_WORLDMODEL = "models/ttt/sopd/w_sopd.mdl"
local SWORD_ICON       = "vgui/ttt/icon_sopd"

local SWORD_TARGET_MSG = "TTT_SoPD_SwordTargetMsg"
local SWORD_KILLED_MSG = "TTT_SoPD_SwordKilledMsg"
local SWORD_PICKUP_MSG = "TTT_SoPD_SwordPickUpMsg"
local CVAR_UPDATE_MSG  = "TTT_SoPD_ConvarUpdateMsg"

local HOOK_BEGIN_ROUND       = "TTT_SoPD_ChooseTarget"
local HOOK_PRE_GLOW          = "TTT_SoPD_TargetGlow"
local HOOK_RENDER_ENTINFO    = "TTT_SoPD_TargetKillInfo"
local HOOK_TAKE_DAMAGE       = "TTT_SoPD_DamageImmunity"
local HOOK_PLAYER_DEATH      = "TTT_SoPD_ProcessDeaths"
local HOOK_PLAYER_SPAWN      = "TTT_SoPD_ProcessSpawns"
local HOOK_PLAYER_STABBED    = "TTT_SoPD_PlaySwordKillSound"
local HOOK_PLAYER_CONNECT    = "TTT_SoPD_PlayerConnect"
local HOOK_TARGET_DISCONNECT = "TTT_SoPD_TargetDisconnect"
local HOOK_TARGET_REMOVED    = "TTT_SoPD_TargetRemoved"
local HOOK_SWORD_PICKUP      = "TTT_SoPD_PickUpSword"
local HOOK_SWORD_UNSTICK     = "TTT_SoPD_PickUpStuckSword"
local HOOK_SPEEDMOD          = "TTT_SoPD_HolderSpeedup"
local HOOK_DRAW_SHOP         = "TTT_SoPD_DrawShopIcon"
local HOOK_DRAW_IEM          = "TTT_SoPD_DrawImprovedShopIcon"

local CVAR_FLAGS = {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}
local TARGET_DISCONNECT_MODE = CreateConVar("ttt2_sopd_target_disconnect_mode", 2, CVAR_FLAGS, "Behavior when the target player disconnects midround (0 = do nothing, 1 = pick new target, 3 = make sword targetless, 2/4 = same as 1/3 but do not trigger if the Sword had been used on the target).", 0, 4)
local TGTDC_NO_OP = 0
local TGTDC_PICK_NEW = 1
local TGTDC_PICK_NEW_IF_UNUSED = 2
local TGTDC_UNTARGET = 3
local TGTDC_UNTARGET_IF_UNUSED = 4
local CAN_TARGET_DEAD = CreateConVar("ttt2_sopd_can_target_dead", 1, CVAR_FLAGS, "Whether dead players can be selected as the target.", 0, 1)
local CAN_TARGET_JESTERS = CreateConVar("ttt2_sopd_can_target_jesters", 1, CVAR_FLAGS, "Whether Jesters can be selected as the target.", 0, 1)
local CAN_TEAMKILL = CreateConVar("ttt2_sopd_can_teamkill", 0, CVAR_FLAGS, "Whether players on the same side of the Sword target pool boundary can kill each other with the Sword.", 0, 1)
local NOTIFY_TARGET_PLAYER = CreateConVar("ttt2_sopd_notify_target", 0, CVAR_FLAGS, "Whether to notify target players when they are selected.", 0, 1)
local TARGET_MIN_POOLSIZE = CreateConVar("ttt2_sopd_target_min_poolsize", 2, CVAR_FLAGS, "Minimum possible target pool size for the Sword to be allowed to pick one.", 1, 6)

local RANGE_BUFF = CreateConVar("ttt2_sopd_range_buff", 1.5, CVAR_FLAGS, "Multiplier for the original TTT knife's range.", 0.01, 5)
local HOLDER_SPEEDUP = CreateConVar("ttt2_sopd_speedup", 1.3, CVAR_FLAGS, "Player speed multiplier while holding the Sword.", 1, 5)
local DNA_DESTRUCTION = CreateConVar("ttt2_sopd_dna_destruction", 60, CVAR_FLAGS, "Time subtracted from victim's DNA timer on kill or corpse stab (per unique Sword, in seconds).", 0, 120)
local RAGDOLL_STAB_COVERUP = CreateConVar("ttt2_sopd_destroy_evidence", 1, CVAR_FLAGS, "Whether stabbing a dead target with the Sword makes it seem like the Sword killed them (reducing DNA if relevant convar is disabled).", 0, 1)
local CAN_REGRAB_SWORD = CreateConVar("ttt2_sopd_grab_stuck_swords", 1, CVAR_FLAGS, "Whether targeted Swords that are stuck in bodies can be grabbed again.", 0, 1)
local ENABLE_TARGET_GLOW = CreateConVar("ttt2_sopd_target_glow", 1, CVAR_FLAGS, "Whether the target player glows for a player holding the Sword.", 0, 1)
local TARGET_DMG_BLOCK = CreateConVar("ttt2_sopd_target_dmg_block", 100, CVAR_FLAGS, "Percent of damage the Sword holder blocks from the target (0 = take full damage, 100 = take no damage).", 0, 100)
local OTHERS_DMG_BLOCK = CreateConVar("ttt2_sopd_others_dmg_block", 0, CVAR_FLAGS, "Percent of damage the Sword holder blocks from non-targets (0 = take full damage, 100 = take no damage).", 0, 100)

-- used in PaP lua but may be referred to here
PAP_HEAL = CreateConVar("ttt2_sopd_pap_heal", 80, CVAR_FLAGS, "How much health is gained from inhaling an enemy with the Sword of Player Def-Eat.", 0, 200)
PAP_DMG_BLOCK = CreateConVar("ttt2_sopd_pap_dmg_block", 0, CVAR_FLAGS, "Percent of damage the Sword holder blocks from everyone if packed (0 = take full damage, 100 = take no damage).", 0, 100)

local DEPLOY_SND_SOUNDLEVEL = CreateConVar("ttt2_sopd_sfx_deploy_soundlevel", 100, CVAR_FLAGS, "The Sword deploy song's soundlevel (how far it can be heard).", 0, 300)
local DEPLOY_SND_VOLUME = CreateConVar("ttt2_sopd_sfx_deploy_volume", 100, CVAR_FLAGS, "The Sword deploy song's volume, before any stealth-related reductions.", 0, 100)
local KILL_SND_VOLUME = CreateConVar("ttt2_sopd_sfx_kill_volume", 100, CVAR_FLAGS, "The Sword kill sound's volume, before any stealth-related reductions.", 0, 100)
local SPECIAL_SWING_CHANCE = CreateConVar("ttt2_sopd_sfx_special_swing_chance", 10, CVAR_FLAGS, "Chance for a special sound effect to play when swinging a Sword in the air.", 0, 100)
local OATMEAL_FOR_LAST = CreateConVar("ttt2_sopd_sfx_oatmeal_for_last", 1, CVAR_FLAGS, "Whether \"1, 2, Oatmeal\" plays as the deploy song when the target is the last opponent alive.", 0, 1)
local STEALTH_VOL_REDUCTION = CreateConVar("ttt2_sopd_sfx_stealth_vol_reduction", 50, CVAR_FLAGS, "The volume of Sword sounds is reduced by this factor when many opponents (inno/side teams) are alive.", 0, 100)
local STEALTH_MAX_OPPS = CreateConVar("ttt2_sopd_sfx_stealth_max_opps", 10, CVAR_FLAGS, "The stealth volume reduction on Sword sound effects is fully applied when this many opponents (inno/side teams) or more are alive, then goes down linearly with the number of remaining opponents (to zero effect when only one opponent left).", 2, 24)
local STEALTH_STAB_FACTOR = CreateConVar("ttt2_sopd_sfx_stealth_stab_factor", 50, CVAR_FLAGS, "Multiplier to the stealth volume reduction factor for stabbing noises.", 0, 100)

----------------------------------
---------- SHARED STATE ----------
----------------------------------
swordTarget = swordTarget or {} -- target data, synchronized for server & client
--.player: player ref, may become invalid if target disconnects
--.name: player's name (always valid)
--.SID64: player's Steam ID (64bit)

----------------------------------
---------- SHARED UTILS ----------
----------------------------------
function IsSwordTargeted()
    -- note: swordTarget.player isn't safe to check for this
    --       as it may be translated as nil despite sword
    --       being targeted when connecting to the server
    return swordTarget.name ~= nil
end

function CanBeStabbed(ply)
    return IsPlayer(ply) and (ply == swordTarget.player or not IsSwordTargeted())
end

function HoldsSword(ply, swordNeedsAmmo)
    if utils.IsLivingPlayer(ply) then
        local wep = ply:GetActiveWeapon()

        return IsValid(wep) and wep:GetClass() == CLASS_NAME and (not swordNeedsAmmo or wep:HasSwordAmmo())
    end

    return false
end

--same as target drawing pool but without jesters (unless they are the target)
function IsOpponent(ply, canBeDead, ignoreTarget)
    if not ignoreTarget and ply == swordTarget.player then return true end

    return (utils.IsLivingPlayer(ply) or canBeDead)
       and ply:GetTeam() ~= TEAM_TRAITOR and ply:GetTeam() ~= TEAM_JACKAL
       and ply:GetTeam() ~= TEAM_INFECTED and ply:GetTeam() ~= TEAM_JESTER
end

function GetOpponentCount()
    local opponentCnt = 0

    for _, ply in ipairs(player.GetAll()) do
        if IsOpponent(ply) then
            opponentCnt = opponentCnt + 1
        end
    end

    return opponentCnt
end

-- stealth volume reduction effect adjustment
function AdjustVolume(isStab)
    local maxReduction = STEALTH_VOL_REDUCTION:GetFloat() / 100
    local maxOpps      = STEALTH_MAX_OPPS:GetInt()
    local baseVol

    -- make effect half as strong for stabbing noises
    if isStab then
        baseVol = KILL_SND_VOLUME:GetFloat() / 100
        maxReduction = maxReduction * (STEALTH_STAB_FACTOR:GetFloat() / 100)
    else
        baseVol = DEPLOY_SND_VOLUME:GetFloat() / 100
    end

    -- we remove 1 from count/max so that 1 opp = 0 reduction & max opp or more = full reduction
    local oppCount = GetOpponentCount()
    local reductionStrength = math.min((oppCount - 1) / (maxOpps - 1), 1)
    local finalVolume = math.max((1 - reductionStrength * maxReduction) * baseVol, 0)

    dbg.Print("[SoPD SFX] base volume", baseVol, "max reduction", maxReduction, "is stab", isStab,
            "\n[SoPD SFX] max opps", maxOpps, "opp count", oppCount,
            "\n[SoPD SFX] -> reduction strength", reductionStrength,
            "\n[SoPD SFX] -> adjusted volume", finalVolume)

    return finalVolume
end

function GetAllRealSwords()
    -- note: UI updates that only impact tooltips should use GetLocalInventorySword
    local swords = {}

    for _, ent in ipairs(ents.GetAll()) do
        if IsValid(ent) and ent:GetClass() == CLASS_NAME then
            table.insert(swords, ent)
        end
    end

    return swords
end

----------------------------------
--- SERVER REALM SETUP / HOOKS ---
----------------------------------
if SERVER then
    dbg.Print("[SoPD Server] Initializing....")

    AddCSLuaFile("weapon_ttt_sopd.lua")
    util.AddNetworkString(SWORD_TARGET_MSG)
    util.AddNetworkString(SWORD_KILLED_MSG)
    util.AddNetworkString(SWORD_PICKUP_MSG)
    util.AddNetworkString(CVAR_UPDATE_MSG)

    --resource.AddWorkshop("3607870957")
    resource.AddFile("materials/vgui/ttt/icon_sopd.vmt")

    function GetPossibleTargetPool(ignorePly)
        local possibleTargetPool = {}

        for _, ply in ipairs(player.GetAll()) do
            if ply:GetRole() ~= ROLE_NONE -- spectator mode
              and ply ~= ignorePly -- disconnecting player
              and ply:GetTeam() ~= TEAM_TRAITOR
              and ply:GetTeam() ~= TEAM_JACKAL
              and ply:GetTeam() ~= TEAM_INFECTED
              and (ply:GetTeam() ~= TEAM_JESTER or CAN_TARGET_JESTERS:GetBool())
              and (utils.IsLivingPlayer(ply) or (CAN_TARGET_DEAD:GetBool() and IsValid(ply.server_ragdoll))) then

                table.insert(possibleTargetPool, ply)
            end
        end

        return possibleTargetPool
    end

    function SendTargetData(to, isPlayerChange)
        net.Start(SWORD_TARGET_MSG)
        net.WriteBool(isPlayerChange ~= false)
        net.WritePlayer(swordTarget.player  or NULL)
        net.WriteString(swordTarget.name    or "")
        net.WriteString(swordTarget.SID64   or "")
        net.WriteEntity(swordTarget.ragdoll or NULL)

        if IsPlayer(to) then
            net.Send(to)
            dbg.Print("[SoPD Server] Sent target data to "..to:Nick().." (target: "..tostring(swordTarget.name).." / "..tostring(swordTarget.player)..")")
        else
            net.Broadcast()
            dbg.Print("[SoPD Server] Broadcast target data (target: "..tostring(swordTarget.name).." / "..tostring(swordTarget.player)..")")
        end
    end

    function DrawTarget(ignorePly)
        local possibleTargetPool = GetPossibleTargetPool(ignorePly)
        dbg.Print("[SoPD Server] Drawing target; possible target pool size: "..tostring(#possibleTargetPool))

        if #possibleTargetPool >= TARGET_MIN_POOLSIZE:GetInt() then
            -- select target player
            newTarget = possibleTargetPool[math.random(1, #possibleTargetPool)]

            -- retry once to make it less likely to pick the same target twice
            if newTarget == swordTarget.player then
                dbg.Print("[SoPD Server] Let's try not to pick the same target twice...")
                newTarget = possibleTargetPool[math.random(1, #possibleTargetPool)]
            end

            -- update stored target data
            swordTarget.player  = newTarget
            swordTarget.name    = newTarget:Nick()
            swordTarget.SID64   = newTarget:SteamID64()
            swordTarget.ragdoll = nil

            local newTargetAlive = utils.IsLivingPlayer(newTarget)
            if not newTargetAlive then
                -- note: server_ragdoll must be valid here due to check
                --       in GetPossibleTargetPool
                swordTarget.ragdoll = newTarget.server_ragdoll
            end

            -- notify the target player if enabled (& they're alive)
            if NOTIFY_TARGET_PLAYER:GetBool() and newTargetAlive then
                LANG.Msg(newTarget, "sopd_target_notif" .. tostring(math.random(5)), nil, MSG_MSTACK_PLAIN)
            end

            -- start/stop sword deploy songs where relevant
            for _, sword in ipairs(GetAllRealSwords()) do
                if newTargetAlive then
                    sword:StartDeploySound("living new target")
                else
                    sword:StopDeploySound("dead new target")
                end
            end

            dbg.Print("[SoPD Server] Chosen sword target: " .. swordTarget.name .. " (team: " .. swordTarget.player:GetTeam() .. ")")
        else
            dbg.Print("[SoPD Server] No suitable target; SoPD will target anyone (without preventing damage).")
            RemoveTarget(false)
        end

        -- Broadcast chosen player
        SendTargetData()
    end

    function RemoveTarget(doBroadcast)
        swordTarget.player   = nil
        swordTarget.name     = nil
        swordTarget.SID64    = nil
        swordTarget.ragdoll  = nil

        for _, sword in ipairs(GetAllRealSwords()) do
            sword:UpdateAmmo() -- cf. comment on that function
        end

        if doBroadcast then
            SendTargetData()
        end
    end

    -- Find the target player for this round!
    hook.Add("TTTBeginRound", HOOK_BEGIN_ROUND, DrawTarget)

    -- Damage resistance hook
    hook.Add("EntityTakeDamage", HOOK_TAKE_DAMAGE, function (dmgTarget, dmgInfo)
        local attacker = dmgInfo:GetAttacker()

        if HoldsSword(dmgTarget, false) and utils.IsLivingPlayer(attacker) then
            local dmgBlock = OTHERS_DMG_BLOCK:GetFloat() / 100

            if attacker == swordTarget.player then
                dmgBlock = TARGET_DMG_BLOCK:GetFloat() / 100
            end

            if dmgTarget:GetActiveWeapon():GetPacked() then
                dmgBlock = dmgBlock + (PAP_DMG_BLOCK:GetFloat() / 100)
            end

            dmgInfo:SetDamage(dmgInfo:GetDamage() * (1 - math.min(1, dmgBlock)))
        end
    end)

    -- Communicate target death, adjust/end deploy songs, ragdoll setup
    hook.Add("PlayerDeath", HOOK_PLAYER_DEATH, function(ply, inflictor, attacker)
        local targetDied = (IsValid(ply) and ply == swordTarget.player)

        if targetDied then
            dbg.Print("[SoPD Server] Target died")
            swordTarget.ragdoll = ply.server_ragdoll
            SendTargetData(nil, false)
        end

        -- Find any held swords & adjust or end (if target died) their deploy songs
        for _, p in ipairs(player.GetAll()) do
            local wep = p:GetActiveWeapon()
            if IsValid(wep) and wep:GetClass() == CLASS_NAME then
                if targetDied then
                    wep:StopDeploySound("target death")

                elseif wep.DeploySound and wep.DeploySound:IsPlaying() then
                    if not wep:GetPacked() and OATMEAL_FOR_LAST:GetBool()
                      and GetOpponentCount() == 1 and IsOpponent(ply, true) then
                        -- restart song to match situation (target is last opp alive)
                        dbg.Print("[SoPD SFX] Changing deploy song as target is now last opponent alive | Died: ", ply:Nick())
                        wep:StopDeploySound("target is last alive (change to oatmeal)")

                        timer.Simple(0.2, function()
                            wep:StartDeploySound("target is last alive (change to oatmeal)")
                        end)

                    else -- common case, just adjust volume
                        dbg.Print("[SoPD SFX] Actualizing sword deploy volume due to nontarget death | Died: ", ply:Nick())
                        wep.DeploySound:ChangeVolume(AdjustVolume(false))
                    end
                end
            end
        end
    end)

    -- Communicate target respawn, adjust/start deploy songs
    hook.Add("PlayerSpawn", HOOK_PLAYER_SPAWN, function(ply)
        local targetSpawned = (utils.IsLivingPlayer(swordTarget.player) and ply == swordTarget.player)

        if targetSpawned then
            dbg.Print("[SoPD Server] Target spawned")
            swordTarget.ragdoll = nil
            SendTargetData(nil, false)
        end

        -- Find any held swords & adjust or start (if target respawned) their deploy songs
        for _, p in ipairs(player.GetAll()) do
            local wep = p:GetActiveWeapon()
            if IsValid(wep) and wep:GetClass() == CLASS_NAME then
                if targetSpawned then
                    wep:StartDeploySound("target respawn")

                elseif wep.DeploySound and wep.DeploySound:IsPlaying() then
                    if not wep:GetPacked() and OATMEAL_FOR_LAST:GetBool()
                      and GetOpponentCount() == 2 and IsOpponent(ply) then
                        -- restart song to match situation (target no longer last opp alive)
                        dbg.Print("[SoPD SFX] Changing deploy song as target is no longer last alive | Respawned: ", ply:Nick())
                        wep:StopDeploySound("target not last alive (change to gourmet)")

                        timer.Simple(0.2, function()
                            wep:StartDeploySound("target not last alive (change to gourmet)")
                        end)

                    else -- common case, just adjust volume
                        dbg.Print("[SoPD SFX] Actualizing sword deploy volume due to non-target respawn | Respawned: ", ply:Nick())
                        wep.DeploySound:ChangeVolume(AdjustVolume(false))
                    end
                end
            end
        end
    end)

    -- Send target data to new clients
    hook.Add("PlayerInitialSpawn", HOOK_PLAYER_CONNECT, function(ply)
        timer.Simple(5, function() -- safety sync wait for pfp load
            SendTargetData(ply, true)
        end)
    end)

    local function IsStuckSword(ent)
        return ent:GetClass() == "prop_physics" and ent:GetModel() == SWORD_WORLDMODEL
    end

    -- Update target if no sword was used this round
    hook.Add("PlayerDisconnected", HOOK_TARGET_DISCONNECT, function(ply)
        if ply == swordTarget.player then
            local mode = TARGET_DISCONNECT_MODE:GetInt()

            -- mode 0: no operation
            if mode <= TGTDC_NO_OP or mode > 4 then
                dbg.Print("[SoPD Server] Target disconnected; no action necessary.")
                return
            end

            -- mode 2/4: do not proceed if any sword was used
            if mode == TGTDC_PICK_NEW_IF_UNUSED or mode == TGTDC_UNTARGET_IF_UNUSED then
                local swordWasUsed = false

                for _, ent in ipairs(ents.GetAll()) do
                    if IsValid(ent) and IsStuckSword(ent) or
                      (ent:GetClass() == CLASS_NAME and ent:GetStabbedTarget()) then
                        swordWasUsed = true
                        break
                    end
                end

                if swordWasUsed then
                    dbg.Print("[SoPD Server] Target disconnected but Sword was used (no refund).")
                    return
                else
                    dbg.Print("[SoPD Server] Target disconnect Sword usage check passed.")
                end
            end

            -- mode 1/3: draw new target or untarget sword
            if mode == TGTDC_PICK_NEW or mode == TGTDC_PICK_NEW_IF_UNUSED then
                dbg.Print("[SoPD Server] Target disconnected; drawing new target.")
                DrawTarget(ply)

            elseif mode == TGTDC_UNTARGET or mode == TGTDC_UNTARGET_IF_UNUSED then
                dbg.Print("[SoPD Server] Target disconnected; un-targeting Swords.")
                RemoveTarget(true)
            end
        end
    end)

    -- Tell clients to update sword UI when it enters their inventory (no reliable clientside hook)
    hook.Add("AllowPlayerPickup", HOOK_SWORD_PICKUP, function(ply, ent)
        if IsValid(ent) and ent:GetClass() == CLASS_NAME then
            net.Start(SWORD_PICKUP_MSG)
            net.Send(ply)
        end
    end)

    -- Allow clients to pick up targeted swords stuck in bodies
    hook.Add("PlayerUse", HOOK_SWORD_UNSTICK, function(ply, ent)
        if utils.IsLivingPlayer(ply) and CAN_REGRAB_SWORD:GetBool()
          and IsSwordTargeted() and IsStuckSword(ent) then
            -- don't allow grab if player already has one
            for _, wep in ipairs(ply:GetWeapons()) do
                if wep:GetClass() == CLASS_NAME then return end
            end

            local newSword = ents.Create(CLASS_NAME)

            if IsValid(newSword) then
                newSword:SetClip1(-1)
                newSword:SetGrabbedFromCorpse(true)
                newSword:SetStabbedTarget(IsSwordTargeted())
                ply:PickupWeapon(newSword)
                ply:SelectWeapon(CLASS_NAME)
                ent:Remove()
            end
        end
    end)

    -- Tell clients to update shop description on cvar change
    function descVarChange(name, oldVal, newVal)
        net.Start(CVAR_UPDATE_MSG)
        net.Broadcast()
    end

    local descCvars = {HOLDER_SPEEDUP, DNA_DESTRUCTION, RAGDOLL_STAB_COVERUP, CAN_REGRAB_SWORD, ENABLE_TARGET_GLOW, TARGET_DMG_BLOCK, OTHERS_DMG_BLOCK, RANGE_BUFF}
    for _, cvar in ipairs(descCvars) do
        cvars.RemoveChangeCallback(cvar:GetName(), cvar:GetName())
        cvars.AddChangeCallback(cvar:GetName(), descVarChange, cvar:GetName())
    end

----------------------------------
--- CLIENT REALM SETUP / HOOKS ---
----------------------------------
elseif CLIENT then
    dbg.Print("[SoPD Client] Initializing....")

    regMetaSWEP = regMetaSWEP or SWEP --meta instance made at registration (map load)
    curMetaSWEP = SWEP --meta instance made at initialization
    -- (may not point to the same object when debugging / hot-reloading)

    curMetaSWEP.Icon = SWORD_ICON
    curMetaSWEP.iconMaterial = SWORD_ICON
    curMetaSWEP.PrintName = DEFAULT_NAME
    curMetaSWEP.Author = "Guy"
    curMetaSWEP.Instructions = LANG.TryTranslation("sopd_instruction")
    curMetaSWEP.EquipMenuData = {type = "Melee Weapon"}
    curMetaSWEP.Slot = 6

    curMetaSWEP.ViewModelFlip = false
    curMetaSWEP.ViewModelFOV  = 80
    curMetaSWEP.DrawCrosshair = false
    curMetaSWEP.UseHands      = true

    net.Receive(SWORD_TARGET_MSG, function()
        local isTargetChange   = net.ReadBool()
        local netTargetPlayer  = net.ReadPlayer()
        local netTargetName    = net.ReadString()
        local netTargetSID64   = net.ReadString()
        local netTargetRagdoll = net.ReadEntity()

        if isTargetChange then
            -- prevent wrongly making sword targetless if target disconnects
            swordTarget.player = (IsValid(netTargetPlayer))  and netTargetPlayer  or nil
        end
        swordTarget.name    = (netTargetName ~= "")          and netTargetName    or nil
        swordTarget.SID64   = (netTargetSID64  ~= "")        and netTargetSID64   or nil
        swordTarget.ragdoll = (IsValid(netTargetRagdoll))    and netTargetRagdoll or nil

        if isTargetChange then
            if IsSwordTargeted() then
                dbg.Print("[SoPD Client] Known sword target: ".. swordTarget.name)
            else
                dbg.Print("[SoPD Client] No sword target")
            end

            -- notify player if they own one
            local localPlayer = LocalPlayer()

            if localPlayer.HasWeapon and localPlayer:HasWeapon(CLASS_NAME) then
                local targetChangeNotif = "[Sword of Player Defeat] Target disconnected"

                local discoMode = TARGET_DISCONNECT_MODE:GetInt()
                if discoMode == TGTDC_PICK_NEW_IF_UNUSED or discoMode == TGTDC_UNTARGET_IF_UNUSED then
                    targetChangeNotif = targetChangeNotif .. " and no Sword was used"
                end

                if IsSwordTargeted() then
                    targetChangeNotif = targetChangeNotif .. ". Target for this round is now ".. swordTarget.name .. "."
                else
                    targetChangeNotif = targetChangeNotif .. ". Could not pick new target; Swords can now be used against anyone with no target-specific effects."
                end

                localPlayer:ChatPrint(targetChangeNotif)
            end

            -- update sword UI & material
            UpdateSwordMeta("target change")
            UpdateSwordCrystal()
        end

        for _, sword in ipairs(GetAllRealSwords()) do
            if isTargetChange then
                sword:UpdateAmmo() --cf. comment on that function
                sword:UpdateUI("target change")

            -- prevent early mid-inhale update (target death + has victim)
            elseif not (swordTarget.ragdoll and IsValid(sword:GetPackVictim())) then
                sword:UpdateUI("target died/revived")
            end
        end
    end)

    function GetLocalInventorySword()
        --hopefully safe assumption that a player can only have one sword
        for _, wep in ipairs(LocalPlayer():GetWeapons()) do
            if wep:GetClass() == CLASS_NAME then
                return wep
            end
        end

        return nil
    end

    function UpdateLocalInventorySword(reason)
        local invSword = GetLocalInventorySword()

        if invSword then
            invSword:UpdateUI(reason)
        end
    end

    -- update sword UI if the target's ragdoll disappears from the world
    hook.Add("EntityRemoved", HOOK_TARGET_REMOVED, function(ent)
        if ent == swordTarget.ragdoll then
            timer.Simple(0.1, function() -- wait for deletion
                local invSword = GetLocalInventorySword()

                -- dont update UI mid-inhale
                if invSword and not IsValid(invSword:GetPackVictim()) then
                    invSword:UpdateUI("target body destroyed")
                end
            end)
        end
    end)

    function InPlayerStabRange(ply)
        if not (utils.IsLivingPlayer(ply)) then return false end
        local tr = ply:GetEyeTrace(MASK_SHOT)
        if not (tr.HitNonWorld and IsValid(tr.Entity)) then return false end

        return ply:GetShootPos():Distance(tr.HitPos) <= 110 * RANGE_BUFF:GetFloat() and CanBeStabbed(tr.Entity)
    end

    -- display halo (through walls if convar is enabled & always if able to kill)
    hook.Add("PreDrawHalos", HOOK_PRE_GLOW, function()
        local localPlayer = LocalPlayer()

        if HoldsSword(localPlayer, true) then
            local inRange = InPlayerStabRange(localPlayer)
            local glowStrength = 1 + (inRange and 1 or 0) --increase strength for kill range
            local glowTarget = {}

            if IsSwordTargeted() then
                if utils.IsLivingPlayer(swordTarget.player) then
                    glowTarget = {swordTarget.player}

                elseif RAGDOLL_STAB_COVERUP:GetBool() and IsValid(swordTarget.ragdoll) then
                    glowTarget = {swordTarget.ragdoll}
                end

            elseif inRange then
                glowTarget = {localPlayer:GetEyeTrace(MASK_SHOT).Entity}
            end

            if inRange or ENABLE_TARGET_GLOW:GetBool() then
                halo.Add(glowTarget, Color(254,215,0), glowStrength, glowStrength, glowStrength, true, true)
            end
        end
    end)

    --notify instakill in target's info if InPlayerStabRange
    hook.Add("TTTRenderEntityInfo", HOOK_RENDER_ENTINFO, function(tData)
        local localPlayer = LocalPlayer()
        local lookEnt = tData:GetEntity()

        if CanBeStabbed(lookEnt) and InPlayerStabRange(localPlayer) and HoldsSword(localPlayer, true) then
            local role_color = localPlayer:GetRoleColor()
            local insta_label = "sopd_instantkill"

            if IsOpponent(lookEnt, false, true) == IsOpponent(localPlayer, false, true) then
                insta_label = "sopd_noteamkill"
            elseif localPlayer:GetActiveWeapon():GetPacked() then
                insta_label = "sopd_instanteat"
            end

            tData:AddDescriptionLine(LANG.TryTranslation(insta_label), role_color)

            -- draw instant-kill maker
            local x = ScrW() * 0.5
            local y = ScrH() * 0.5
            local outer = 20
            local inner = 10

            surface.SetDrawColor(clr(role_color))
            surface.DrawLine(x - outer, y - outer, x - inner, y - inner)
            surface.DrawLine(x + outer, y + outer, x + inner, y + inner)
            surface.DrawLine(x - outer, y + outer, x - inner, y + inner)
            surface.DrawLine(x + outer, y - outer, x + inner, y - inner)
        end
    end)

    -- ensure the sword's kill noise plays if the server considers it killed a player
    net.Receive(SWORD_KILLED_MSG, function()
        local isPapped = net.ReadBool()
        local swordEnt = net.ReadEntity()
        dbg.Print("[SoPD Client] Received kill msg;", swordEnt, IsValid(swordEnt), isPapped)

        if not isPapped and IsValid(swordEnt) then
            local choice
            local roll = math.random()
            local best_sfx_prob = 0.8

            if roll <= best_sfx_prob then
                choice = "triumph_best"
            elseif roll <= best_sfx_prob + (1 - best_sfx_prob)/2 then
                choice = "triumph_nobgm"
            else
                choice = "triumph_other"
            end

            dbg.Print("[SoPD SFX] Playing on-kill triumph sound", choice)
            swordEnt:EmitSound(snd[choice], SNDLVL_150dB, 100, AdjustVolume(true), CHAN_BODY)
        end
    end)

    -- update sword's shop Icon (inspired by PaP code)
    -- requires callback-based recursion to work with spectator shop's role select
    function UpdateShopIconOverlay(dsheet, specCallback)
        local equipTabPanel

        for _, tab in ipairs(dsheet:GetItems()) do
            if tab.Name == "Order Equipment" then
                equipTabPanel = tab.Panel
                break
            end
        end

        if equipTabPanel then
            -- note: condition for spec dropdown is shown copied from
            --       TTT2/gamemodes/terrortown/client/cl_equip.lua
            local client = LocalPlayer()

            if not specCallback and (not client:Alive() or not client:IsActive()) then
                -- find spectator shop's role selector
                local roleSel = equipTabPanel:GetChildren()

                for i = 1, 2 do
                    if not roleSel or table.IsEmpty(roleSel) then return end
                    -- note: icon collection is 2nd child of EquipSelect,
                    --       which is 1st child of the tab panel
                    roleSel = roleSel[2]
                    if not roleSel then return end
                    if i < 2 then roleSel = roleSel:GetChildren() end
                end

                -- overwrite callback to update buy menu icons on role selection
                dbg.Print("[SoPD Client] Found & overwrote spec shop role selection callback")
                local roleSelOnSelect = roleSel.OnSelect
                roleSel.OnSelect = function(panel, index, value)
                    roleSelOnSelect(panel, index, value)
                    UpdateShopIconOverlay(dsheet, true)
                end

            elseif IsSwordTargeted() then
                -- extracting buy menu icon collection from equipment tab
                local buyMenuIcons = equipTabPanel:GetChildren()

                for i = 1, 2 do
                    if not buyMenuIcons or table.IsEmpty(buyMenuIcons) then return end
                    -- note: icon collection is 1st child of EquipSelect,
                    --       which is 1st child of the tab panel
                    buyMenuIcons = buyMenuIcons[1]
                    if not buyMenuIcons then return end
                    buyMenuIcons = buyMenuIcons:GetChildren()
                end

                -- finding the sword's entry to update
                if buyMenuIcons and not table.IsEmpty(buyMenuIcons) then
                    dbg.Print("[SoPD Client] Finding & updating SoPD icon...")

                    for _, panel in ipairs(buyMenuIcons) do
                        if panel.item and panel.item.id == CLASS_NAME then
                            local avatar = utils.GetAvatar(swordTarget.SID64)

                            if avatar then
                                tgtIcon = vgui.Create("DImage")

                                -- setup pfp icon
                                tgtIcon:SetMaterial(avatar)
                                tgtIcon:SetTooltip(swordTarget.name)
                                tgtIcon:SetImageColor(panel.Icon:GetImageColor())
                                tgtIcon.PerformLayout = function(s)
                                    s:AlignBottom(4); s:AlignRight(4); s:SetSize(16, 16)
                                end

                                -- add pfp layer
                                panel:AddLayer(tgtIcon)
                                panel:EnableMousePassthrough(tgtIcon)
                            end
                        end
                    end
                end
            end
        end
    end
    hook.Add("TTTEquipmentTabs", HOOK_DRAW_SHOP, UpdateShopIconOverlay)

    -- hook to make the shop icon compatible with Layton's Improved Equipment Menu addon
    hook.Add("TTT2IEMMakeEquipmentIcon", HOOK_DRAW_IEM, function(dButton)
        local oldPaint = dButton.Paint

        dButton.Paint = function(panel, w, h)
            oldPaint(panel, w, h)

            if dButton.item.id == "weapon_ttt_sopd" and IsSwordTargeted() then
                local avatar = utils.GetAvatar(swordTarget.SID64)

                surface.SetMaterial(avatar)
                surface.SetDrawColor(color_white)
                surface.DrawTexturedRect(w - 16 - 4, h - 16 - 4, 16, 16)
            end
        end
    end)

    -- update sword's crystal material to blend in target pfp
    local crystalMat = Material("models/ttt/sopd/sopd_crystal")
    function UpdateSwordCrystal()
        if IsSwordTargeted() then
            local avaMat, avaTex = utils.GetAvatar(swordTarget.SID64)

            if avaMat and avaTex then
                crystalMat:SetTexture("$detail", avaTex)
                crystalMat:Recompute()
                return
            end
        end

        crystalMat:SetUndefined("$detail")
        crystalMat:Recompute()
    end

    -- update sword's shop & initialization info
    function UpdateSwordMeta(reason)
        dbg.Print("[SoPD Client] Updating sword meta... ("..reason..")")

        -- update description (text-building logic yippie)
        local desc = ""

        if IsSwordTargeted() then
            local dmgReductionDesc = ""
            local targetDmgBlock = TARGET_DMG_BLOCK:GetFloat()
            if targetDmgBlock == 100 then
                dmgReductionDesc = "While you hold it, they cannot damage you"
            elseif targetDmgBlock > 0 then
                dmgReductionDesc = "While you hold it, they deal reduced damage to you"
            end

            local othersDmgBlock = OTHERS_DMG_BLOCK:GetFloat()
            if othersDmgBlock > 0 then
                if dmgReductionDesc == "" then
                    dmgReductionDesc = "While you hold it, players "
                else
                    dmgReductionDesc = dmgReductionDesc .. ", and others "
                end

                if othersDmgBlock == 100 then
                    dmgReductionDesc = dmgReductionDesc .. "cannot damage you"
                    if targetDmgBlock == 100 then
                        dmgReductionDesc = dmgReductionDesc .. " either"
                    end
                else
                    dmgReductionDesc = dmgReductionDesc .. "deal reduced damage"
                    if targetDmgBlock > 0 and targetDmgBlock < 100 then
                        dmgReductionDesc = dmgReductionDesc .. " as well"
                    else
                        dmgReductionDesc = dmgReductionDesc .. " to you"
                    end
                end
            end

            if dmgReductionDesc ~= "" then
                dmgReductionDesc = dmgReductionDesc .. ". "
            end

            desc = "Swing to instantly and loudly defeat " .. swordTarget.name .. ". " .. dmgReductionDesc .. "What a triumph is that!\n\n"

        else
            desc = "The Sword failed to pick a target, but it'll still loudly defeat a player. What a triumph is that!\n\n"
        end

        desc = desc .. "While held:\n"

        if HOLDER_SPEEDUP:GetFloat() > 1 then
            local speedStr = string.format("%.1f", HOLDER_SPEEDUP:GetFloat()):gsub("%.0$", "")
            desc = desc .. "• ".. speedStr .. "x speed multiplier\n"
        end
        if IsSwordTargeted() and ENABLE_TARGET_GLOW:GetBool() then
            desc = desc .. "• Can see " .. swordTarget.name .. "'s outline through walls\n"
        end

        if IsSwordTargeted() and TARGET_DMG_BLOCK:GetFloat() > 0 then
            local tgtBlockStr = string.format("%.0f", TARGET_DMG_BLOCK:GetFloat())
            desc = desc .. "• Block " .. tgtBlockStr .. "% of damage from " .. swordTarget.name .. "\n"
        end

        if OTHERS_DMG_BLOCK:GetFloat() > 0 then
            local allBlockStr = string.format("%.0f", OTHERS_DMG_BLOCK:GetFloat())
            desc = desc .. "• Block " .. allBlockStr .. "% of "
            if IsSwordTargeted() then
                if TARGET_DMG_BLOCK:GetFloat() > 0 then
                    desc = desc .. "damage from others\n"
                else
                    desc = desc .. "damage from non-targets\n"
                end
            else
                desc = desc .. "player damage\n"
            end
        end
        desc = desc .. "• You are very noticeable\n"

        local dnaDestruction = DNA_DESTRUCTION:GetFloat()
        if dnaDestruction >= 100 then
            desc = desc .. "Leaves no DNA. "
        elseif dnaDestruction >= 60 then
            desc = desc .. "Doesn't leave much DNA. "
        elseif dnaDestruction > 0 then
            desc = desc .. "Leaves reduced DNA. "
        else
            desc = desc .. "Leaves DNA. "
        end

        if IsSwordTargeted() and RAGDOLL_STAB_COVERUP:GetBool() then
            desc = desc .. "If " .. swordTarget.name .. " is dead, you can stab their corpse to falsify"
            if dnaDestruction >= 100 then
                desc = desc .. " evidence and destroy DNA"
            elseif dnaDestruction >= 60 then
                desc = desc .. " evidence and remove DNA"
            elseif dnaDestruction > 0 then
                desc = desc .. " evidence and reduce DNA"
            else
                desc = desc .. " other evidence"
            end
            desc = desc .. ".\n"
        end

        -- (undocumented magic attributes ftw)
        regMetaSWEP.desc = desc
        curMetaSWEP.EquipMenuData.desc = desc

        --update SWEP's name
        local name = ""

        if IsSwordTargeted() then
            name = "Sword of ".. swordTarget.name .. " Defeat"

            local lowerName = string.lower(swordTarget.name)
            if lowerName == "king dedede" or lowerName == "dedede" then
                name = name .. "!"
            end
        else
            name = DEFAULT_NAME
        end

        regMetaSWEP.PrintName = name --update shop name
        curMetaSWEP.PrintName = name --init new swords with right name
    end

    net.Receive(SWORD_PICKUP_MSG, function()
        timer.Simple(0.01, function() -- safety sync wait
            dbg.Print("[SoPD Client] Received pickup notif")
            UpdateLocalInventorySword("pickup")
        end)
    end)

    net.Receive(CVAR_UPDATE_MSG, function()
        UpdateSwordMeta("cvar change")
    end)

    --harmless; helps w/ hot-reloading
    UpdateSwordMeta("lua load")
    UpdateSwordCrystal()
end

----------------------------------
---------- SHARED HOOKS ----------
----------------------------------
hook.Add("TTTPlayerSpeedModifier", HOOK_SPEEDMOD, function(ply, _, _, noLag )
    if not utils.IsLivingPlayer(ply) then return end
    local wep = ply:GetActiveWeapon()

    -- note: not sure why GetGrabbedFromCorpse is sometimes nil
    --       for a frame or two when grabbing Sword from a
    --       corpse outside of local testing
    if IsValid(wep) and wep:GetClass() == CLASS_NAME and wep.GetGrabbedFromCorpse and not wep:GetGrabbedFromCorpse() then
        if TTT2 then
            noLag[1] = noLag[1] * HOLDER_SPEEDUP:GetFloat()
        else
            return HOLDER_SPEEDUP:GetFloat()
        end
    end
end)

----------------------------------
---- SHARED SWEP INIT & DEFS -----
----------------------------------
SWEP.Base         = "weapon_tttbase"
SWEP.HoldType     = "melee"
SWEP.ViewModel    = SWORD_VIEWMODEL
SWEP.WorldModel   = SWORD_WORLDMODEL
SWEP.idleResetFix = true

SWEP.Primary.Damage      = 100
SWEP.Primary.ClipSize    = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic   = true
SWEP.Primary.Delay       = 0.5
SWEP.Primary.Ammo        = "none"

SWEP.Kind        = WEAPON_EQUIP
SWEP.CanBuy      = {ROLE_TRAITOR, ROLE_JACKAL}
SWEP.IsSilent    = true --(negated by the noises we add lol)
SWEP.AllowDrop   = true
SWEP.DeploySpeed = 2

local noTeamkillLines = {
    "No teamkilling!",
    "No teamkilling!",
    "No teamkilling!",
    "No teamkilling!",
    "No! Bad!",
    "nuh uh",
    "They're on your side!",
    "Defeating them just feels wrong.",
    "You wouldn't defeat an ally.",
    "You wouldn't!",
    "You think better of it.",
    "That would be no triumph."
}

function SWEP:SetupDataTables()
    -- note: could check for self.PAPUpgrade ~= nil to not store this,
    --       but it's not properly networked & false for client during Apply
    self:NetworkVar("Bool", 0, "Packed")
    self:NetworkVar("Bool", 1, "PackVerb")
    self:NetworkVar("Bool", 2, "StabbedTarget")
    self:NetworkVar("Bool", 3, "GrabbedFromCorpse")
    self:NetworkVar("Entity", 0, "PackVictim")
end

function SWEP:UpdateTransmitState()
    return TRANSMIT_ALWAYS -- update state for all clients
end

function SWEP:HasSwordAmmo()
    return self.Primary.ClipSize == -1 or self:Clip1() > 0
end

function SWEP:PrimaryAttack()
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    owner:LagCompensation(true)

    local spos = owner:GetShootPos()
    local sdest = spos + (owner:GetAimVector() * 100 * RANGE_BUFF:GetFloat())

    local kmins = Vector(1,1,1) * -10
    local kmaxs = Vector(1,1,1) * 10

    -- raycast to get entity hit by sword, ignoring owner & other swords
    local function SwordTraceFilter(ent)
        return ent:GetModel() ~= SWORD_WORLDMODEL and (ent ~= owner or owner == swordTarget.player)
    end

    local tr = util.TraceHull({start=spos, endpos=sdest, filter=SwordTraceFilter, mask=MASK_SHOT_HULL, mins=kmins, maxs=kmaxs})

    -- Hull might hit environment stuff that line does not hit
    if not IsValid(tr.Entity) then
        tr = util.TraceLine({start=spos, endpos=sdest, filter=SwordTraceFilter, mask=MASK_SHOT_HULL})
    end

    local hitEnt = tr.Entity
    local isPacked = self:GetPacked()
    dbg.Print("SoPD Primary hit entity:", hitEnt, isPacked and "(packed)" or "")

    if not CAN_TEAMKILL:GetBool() and CanBeStabbed(hitEnt)
      and IsSwordTargeted() and not isPacked and hitEnt != owner
      and IsOpponent(hitEnt, false, true) == IsOpponent(owner, false, true) then
        utils.NonSpamMessage(owner, "teamkill_attempt", noTeamkillLines[math.random(#noTeamkillLines)], true)
        owner:LagCompensation(false)
        return
    end

    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
    self:EmitSound(snd["swing" .. tostring(math.random(3))], 75, math.random(90, 110))

    -- effects
    if IsValid(hitEnt) then
        self:SendWeaponAnim(ACT_VM_HITCENTER)

        local edata = EffectData()
        edata:SetStart(spos)
        edata:SetOrigin(tr.HitPos)
        edata:SetNormal(tr.Normal)
        edata:SetEntity(hitEnt)

        if CanBeStabbed(hitEnt) or hitEnt:GetClass() == "prop_ragdoll" then
            util.Effect("BloodImpact", edata)
        end
    else
        self:SendWeaponAnim(ACT_VM_MISSCENTER)
        if math.random() < (SPECIAL_SWING_CHANCE:GetFloat() / 100) then
            self:EmitSound(snd["swing_spc" .. tostring(math.random(2))], 75, math.random(95, 105))
        end
    end

    if SERVER then
        owner:SetAnimation(PLAYER_ATTACK1)

        --to make debug code more readable
        local HAS_AMMO      = self:HasSwordAmmo()
        local IS_HIT        = tr.Hit
        local HIT_NOT_WORLD = tr.HitNonWorld
        local HIT_ENT_VALID = IsValid(hitEnt)
        local preReqs = HAS_AMMO and IS_HIT and HIT_NOT_WORLD and HIT_ENT_VALID

        dbg.Print("SoPD Primary Attack Checks:\n"
            .."• PREREQS - "          .. tostring(preReqs)
            .. " -> sword has ammo: " .. tostring(HAS_AMMO)
            .. " & trace hit: "       .. tostring(IS_HIT)
            .. " & non-world: "       .. tostring(HIT_NOT_WORLD)
            .. " & valid entity: "    .. tostring(HIT_ENT_VALID))

        if preReqs then
            local CAN_STAB_ENT     = CanBeStabbed(hitEnt)
            local OWNER_NOT_JESTER = owner:GetTeam() ~= TEAM_JESTER
            local NO_MARK_IMMUNITY = CAN_STAB_ENT and not (
              hitEnt:GetTeam() == TEAM_MARKER and MARKER_DATA
              and MARKER_DATA.marked_players[owner:SteamID64()])

            local isKill = CAN_STAB_ENT and OWNER_NOT_JESTER and NO_MARK_IMMUNITY

            dbg.Print("• KILL - "                .. tostring(isKill)
                .. " -> can stab ent: "           .. tostring(CAN_STAB_ENT)
                .. " & owner is not jest: "       .. tostring(OWNER_NOT_JESTER)
                .. " & owner not marked by ent: " .. tostring(NO_MARK_IMMUNITY))

            if isKill then
                self:StabKill(tr, spos, sdest)

            else
                local IS_RAG        = hitEnt:GetClass() == "prop_ragdoll"
                local IS_PLAYER_RAG = hitEnt:IsPlayerRagdoll()
                local TARGET_MATCH  = hitEnt == swordTarget.ragdoll or hitEnt.sid64 == swordTarget.SID64
                local UNTARGET_PAP  = swordTarget.name == nil and isPacked
                local isRagStab = IS_RAG and IS_PLAYER_RAG and (TARGET_MATCH or UNTARGET_PAP)

                dbg.Print("• RAGSTAB - "    .. tostring(isRagStab)
                    .. " -> is ragdoll: "    .. tostring(IS_RAG)
                    .. " & is of player: "   .. tostring(IS_PLAYER_RAG)
                    .. " & target match: "   .. tostring(TARGET_MATCH)
                    .. " | targetless pap: " .. tostring(UNTARGET_PAP)
                    .. " (targeted: "        .. tostring(IsSwordTargeted()) .. ")")

                if isRagStab then
                    self:StabRagdoll(tr, spos, sdest)
                end
            end
        end
    end

    owner:LagCompensation(false)
end

function SWEP:OnRemove()
    if CLIENT and IsValid(self:GetOwner())
      and self:GetOwner() == LocalPlayer()
      and utils.IsLivingPlayer(self:GetOwner()) then
        RunConsoleCommand("lastinv")
    end
end

function SWEP:Deploy()
    self.Weapon:SendWeaponAnim(ACT_VM_DRAW)

    if SERVER then
        self:StartDeploySound("deploy")
    end
    return true
end

function SWEP:Holster()
    if SERVER then
        self:StopDeploySound("holster")
    end
    return true
end

function SWEP:UpdateAmmo()
    -- Existing PaP'd swords needs to have ammo updated if sword becomes targetless
    -- Note: Not needed the other way around since a round without a target will never "gain" a target (no need to call after setting/changing target or to make the sword ammo-less again)
    if self:GetPacked() and not IsSwordTargeted() then
        self.Primary.ClipSize = 1
        self:SetClip1(not self:GetStabbedTarget() and 1 or 0)
    end
end

----------------------------------
----- SERVER REALM SWEP DEFS -----
----------------------------------
if SERVER then
    function SWEP:Equip(newOwner)
        self:SetNextPrimaryFire(CurTime() + (self.Primary.Delay * 1.5))
    end

    function SWEP:PreDrop()
        --below probably not needed, holster should handle all cases
        self:StopDeploySound("item drop")
        self.fingerprints = {}
    end

    local function adjStuckSwordAngle(norm)
        local ang = norm:Angle()
        ang:RotateAroundAxis(ang:Up(), 180)
        return ang
    end

    local function adjStuckSwordPos(retr, ang)
        return retr.HitPos + (ang:Forward() * 10)
    end

    local function AlterCrimeScene(rag, sword)
        rag.was_headshot = false
        rag.dmgwep       = CLASS_NAME
        rag.dmgtype      = DMG_SLASH

        if rag.scene then
            rag.scene.lastDamage = 12047
            rag.scene.hit_trace  = util.TraceHull({start=Vector(1,1,1), endpos=Vector(1,1,1)}) --pointblank attack
            rag.scene.waterLevel = 0
        end

        if rag.killer_sample and not (sword and sword:GetGrabbedFromCorpse()) then
            rag.killer_sample.t = rag.killer_sample.t - DNA_DESTRUCTION:GetFloat()
        end
    end

    local function StickSwordIn(rag, pos, ang, bone)
        local stuckSword = ents.Create("prop_physics")
        stuckSword:SetModel(SWORD_WORLDMODEL)
        stuckSword:SetPos(pos)
        stuckSword:SetAngles(ang)
        stuckSword:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
        stuckSword:Spawn()

        local phys = stuckSword:GetPhysicsObject()
        if IsValid(phys) then phys:EnableCollisions(true) end
        constraint.Weld(rag, stuckSword, bone or 0, 0, 0, true)

        -- note: sword can't be deleted as it would interfere with the "swords were used"
        --       check on target disconnect. yes that could be reworked I agree.
        --[[rag:CallOnRemove("ttt_sword_cleanup", function()
            SafeRemoveEntity(stuckSword)
        end)]]

        -- note: this approach doesn't quite work either because the Sword falling in the void
        --       is eventually deleted by the server (and not teleporting it allows regrab/moving
        --       it with magneto stick). so let's just let it drop normally
        --[[rag:CallOnRemove("ttt_sword_cleanup", function()
            --stuckSword:SetRenderMode(RENDERMODE_NONE) -- invisible
            --stuckSword:SetPos(Vector(0, 0, -5000)) -- in the backrooms
        end)]]

        return stuckSword
    end

    function SWEP:StabKill(tr, spos, sdest)
        --arg2/3 = shooting origin/dest world positions
        local target = tr.Entity
        local owner  = self:GetOwner()

        --wish I knew how to make this not ugly (TODO?)
        local packEffect = self.PackEffect

        -- damage to killma player
        local dmg = DamageInfo()
        dmg:SetDamage(12047)
        dmg:SetAttacker(owner)
        dmg:SetInflictor(self)
        dmg:SetDamageForce(owner:GetAimVector())
        dmg:SetDamagePosition(owner:GetPos())
        dmg:SetDamageType(DMG_SLASH)

        -- raycast to get entity hit by sword (which should be a player's limb)
        local retr = util.TraceLine({start=spos, endpos=sdest, filter=owner, mask=MASK_SHOT_HULL})
        if retr.Entity ~= target then
            local center = target:LocalToWorld(target:OBBCenter())
            retr = util.TraceLine({start=spos, endpos=center, filter=owner, mask=MASK_SHOT_HULL})
        end

        -- create knife effect creation fn
        local bone = retr.PhysicsBone
        local norm = tr.Normal
        local ang = adjStuckSwordAngle(norm)
        local pos = adjStuckSwordPos(retr, ang)

        target.effect_fn = function(rag)
            local stuckSword = nil

            if not packEffect then
                -- redo raycast from previously hit point (we might find a better location)
                local rtr = util.TraceLine({start=pos, endpos=pos + norm * 40, filter=owner, mask=MASK_SHOT_HULL})

                if IsValid(rtr.Entity) and rtr.Entity == rag then
                    bone = rtr.PhysicsBone
                    ang = adjStuckSwordAngle(rtr.Normal)
                    pos = adjStuckSwordPos(rtr, ang)
                end

                stuckSword = StickSwordIn(rag, pos, ang, bone)
                AlterCrimeScene(rag, nil)
            end

            -- play slay noise from stuck sword
            net.Start(SWORD_KILLED_MSG)
            net.WriteBool(packEffect)
            net.WriteEntity(stuckSword)
            net.Broadcast()
            if packEffect then packEffect(self, rag, owner) end
            dbg.Print("[SoPD Server] Sent kill msg")
        end

        --dispatch killing attack, trigger sword sticking function & clean up
        target:DispatchTraceAttack(dmg, spos + (owner:GetAimVector() * 3), sdest)
        if utils.IsLivingPlayer(target) then
            dbg.Print("[SoPD Server] Sword victim didn't die on stab; correcting...")
            target:Kill()
        end
        self:Consume(false)
    end

    function SWEP:StabRagdoll(tr, spos, sdest)
        local hitRagdoll = tr.Entity

        if not self:GetPacked() then
            local stabVol = 0.2
            local ang = adjStuckSwordAngle(tr.Normal)
            local pos = adjStuckSwordPos(tr, ang)
            local stuckSword = StickSwordIn(hitRagdoll, pos, ang, tr.PhysicsBone)

            -- concealing death cause here if enabled
            if RAGDOLL_STAB_COVERUP:GetBool() then
                -- gameplay relevant mechanic should have SOME risk
                stabVol = math.max(stabVol, AdjustVolume(true))
                AlterCrimeScene(hitRagdoll, self)
            end

            local stabSnd = "rag_stab1"
            if math.random() > 0.8 then stabSnd = "rag_stab2" end

            dbg.Print("[SoPD SFX] Playing ragdoll stab sound", stabSnd, "vol", stabVol)
            stuckSword:EmitSound(snd[stabSnd], SNDLVL_90dB, 100, stabVol, CHAN_BODY)
        end

        self:Consume(true, hitRagdoll)
    end

    function SWEP:Consume(doPap, rag)
        self:StopDeploySound("consumption")

        if IsSwordTargeted() then
            self:SetStabbedTarget(true)
        end

        if self:GetPacked() then
            if self.Primary.ClipSize ~= -1 then
                self:SetClip1(0)
            end

            if doPap and rag and not IsValid(self:GetPackVictim()) then
                self:PackEffect(rag, self:GetOwner())
            end
        else
            self:Remove()
        end
    end

    function SWEP:StartDeploySound(reason)
        if self.DeploySound and self.DeploySound:IsPlaying() then
            dbg.Print("[SoPD SFX] Not starting deploy sound caused by "..reason.." - song already playing.")
            return
        end

        local owner = self:GetOwner()
        if not IsValid(owner) then
            dbg.Print("[SoPD SFX] Not starting deploy sound caused by "..reason.." - no current owner.")
            return
        end

        if not HoldsSword(owner, true) then
            dbg.Print("[SoPD SFX] Not starting deploy sound caused by "..reason.." - owner is not holding sword, or it is out of ammo.")
            return
        end

        if IsSwordTargeted() and not utils.IsLivingPlayer(swordTarget.player) then
            dbg.Print("[SoPD SFX] Not starting deploy sound caused by "..reason.." - target is dead.")
            return
        end

        dbg.Print("[SoPD SFX] Starting deploy sound due to "..reason)
        local deploySnd = "gourmet"
        if self:GetPacked() or (GetOpponentCount() == 1 and OATMEAL_FOR_LAST:GetBool()) then
            deploySnd = "oatmeal"
        end

        self.DeploySound = CreateSound(owner, snd[deploySnd])
        self.DeploySound:SetSoundLevel(DEPLOY_SND_SOUNDLEVEL:GetInt())
        self.DeploySound:PlayEx(AdjustVolume(false), 100)
    end

    function SWEP:StopDeploySound(reason)
        if self.DeploySound and self.DeploySound:IsPlaying() then
            dbg.Print("[SoPD SFX] Stopping deploy sound due to "..reason)
            self.DeploySound:Stop()
            self.DeploySound = nil

        else
            dbg.Print("[SoPD SFX] Not stopping deploy caused by "..reason.." - song not playing.")
        end
    end


----------------------------------
----- CLIENT REALM SWEP DEFS -----
----------------------------------
elseif CLIENT then

    function SWEP:Initialize() --on buy
        self:UpdateUI("initialize")
        return self.BaseClass.Initialize(self)
    end

    function SWEP:UpdateUI(reason)
        dbg.Print("[SoPD Client] Updating sword UI... ("..reason..")")

        -- update name
        local isPacked = self:GetPacked()
        if isPacked then
            local packVerb = self:GetPackVerb() and "Delete" or "Def-Eat"
            self.PrintName = string.gsub(curMetaSWEP.PrintName, "Defeat", packVerb)
        else
            self.PrintName = curMetaSWEP.PrintName
        end

        -- no need to update tooltips if the sword is not in someone's inventory
        local owner = self:GetOwner()
        if not IsValid(owner) then return end

        -- regular alive check may be wrong due to client/server sync delay
        local targetAlive = (swordTarget.ragdoll == nil)

        -- update tooltip instructions
        self:ClearHUDHelp()

        if not IsValid(self:GetPackVictim()) then  -- sword doesn't have valid disguise
            if owner:GetTeam() ~= TEAM_JESTER then -- owner is not jester
                if self:HasSwordAmmo() then        -- sword has ammo
                    if IsSwordTargeted() then      -- sword is targeted
                        if targetAlive or IsValid(swordTarget.ragdoll) then -- target is interactable
                            if not isPacked then                            -- sword is not packed
                                if targetAlive then                         -- target is alive
                                    if owner ~= swordTarget.player then     -- owner is not target
                                        self:AddTTT2HUDHelp("sopd_instruction_targeted") -- "Defeat target"

                                    else -- owner is target
                                        self:AddTTT2HUDHelp("sopd_instruction_for_target") -- "Defeat yourself"
                                    end

                                else -- target is dead
                                    if RAGDOLL_STAB_COVERUP:GetBool() and not self:GetGrabbedFromCorpse() then
                                        -- "Stab target's corpse & destroy evidence"
                                        self:AddTTT2HUDHelp("sopd_instruction_stab_coverup")
                                    else
                                        -- "Stab target's corpse"
                                        self:AddTTT2HUDHelp("sopd_instruction_stab")
                                    end
                                end

                            else -- packed sword
                                if owner ~= swordTarget.player then
                                    self:AddTTT2HUDHelp("sopd_instruction_pap_lmb") -- "Inhale enemy"
                                else
                                    self:AddTTT2HUDHelp("sopd_instruction_pap_lmb_self") -- "Inhale yourself?"
                                end
                            end

                        else -- target can't be stabbed
                            -- "Swing fruitlessly (your enemy has vanished)"
                            self:AddTTT2HUDHelp("sopd_instruction_useless")
                        end

                    else -- targetless sword
                        if isPacked then
                            self:AddTTT2HUDHelp("sopd_instruction_pap_lmb") -- "Inhale enemy"
                        else
                            self:AddTTT2HUDHelp("sopd_instruction_targetless") -- "Defeat any player"
                        end
                    end

                else -- packed sword without disguise or ammo (quite rare)
                    -- "Swing fruitlessly (out of ammo)"
                    self:AddTTT2HUDHelp("sopd_instruction_pap_lmb_no_ammo")
                end

            else -- owner is jester
                self:AddTTT2HUDHelp("sopd_instruction_for_jester") -- "Pretend to swing"
            end

        else -- packed sword with disguise
            local disguiseLMBInstruction = "sopd_instruction_pap_lmb2" -- "Swing triumphantly"

            if IsSwordTargeted() and targetAlive then -- likely impossible (easter egg)
                disguiseLMBInstruction = "sopd_instruction_pap_lmb_what"
            end

                                                  --  + "Toggle copy ability (disguise)"
            self:AddTTT2HUDHelp(disguiseLMBInstruction, "sopd_instruction_pap_rmb")
        end
    end

    function SWEP:AddToSettingsMenu(parent)
        local formTargets = vgui.CreateTTT2Form(parent, "label_sopd_targets_form")
        formTargets:MakeHelp({
            label = "label_sopd_target_disconnect_mode_desc"
        })
        formTargets:MakeComboBox({
            serverConvar = "ttt2_sopd_target_disconnect_mode",
            label = "label_sopd_target_disconnect_mode",
            choices = {
                [1] = {title = TryT("label_sopd_tgtdcm_no_op"), value = TGTDC_NO_OP},
                [2] = {title = TryT("label_sopd_tgtdcm_pick_new"), value = TGTDC_PICK_NEW},
                [3] = {title = TryT("label_sopd_tgtdcm_pick_new_cond"), value = TGTDC_PICK_NEW_IF_UNUSED},
                [4] = {title = TryT("label_sopd_tgtdcm_untarget"), value = TGTDC_UNTARGET},
                [5] = {title = TryT("label_sopd_tgtdcm_untarget_cond"), value = TGTDC_UNTARGET_IF_UNUSED}
            }
        }):SetSortItems(false) -- disabled alphabetization
        formTargets:MakeHelp({
            label = "label_sopd_can_target_dead_desc"
        })
        formTargets:MakeCheckBox({
            serverConvar = "ttt2_sopd_can_target_dead",
            label = "label_sopd_can_target_dead"
        })
        formTargets:MakeCheckBox({
            serverConvar = "ttt2_sopd_can_target_jesters",
            label = "label_sopd_can_target_jesters"
        })
        formTargets:MakeCheckBox({
            serverConvar = "ttt2_sopd_notify_target",
            label = "label_sopd_notify_target"
        })
        formTargets:MakeHelp({
            label = "label_sopd_target_min_poolsize_desc"
        })
        formTargets:MakeSlider({
            serverConvar = "ttt2_sopd_target_min_poolsize",
            label = "label_sopd_target_min_poolsize",
            min = 1, max = 6, decimal = 0
        })

        local formSword = vgui.CreateTTT2Form(parent, "label_sopd_sword_form")
        formSword:MakeHelp({
            label = "label_sopd_range_buff_desc"
        })
        formSword:MakeSlider({
            serverConvar = "ttt2_sopd_range_buff",
            label = "label_sopd_range_buff",
            min = 0.1, max = 5, decimal = 1
        })
        formSword:MakeHelp({
            label = "label_sopd_regrab_properties_desc"
        })
        formSword:MakeSlider({
            serverConvar = "ttt2_sopd_speedup",
            label = "label_sopd_speedup",
            min = 1, max = 5, decimal = 1
        })
        formSword:MakeSlider({
            serverConvar = "ttt2_sopd_dna_destruction",
            label = "label_sopd_dna_destruction",
            min = 0, max = 120, decimal = 0
        })
        formSword:MakeCheckBox({
            serverConvar = "ttt2_sopd_destroy_evidence",
            label = "label_sopd_destroy_evidence"
        })
        formSword:MakeCheckBox({
            serverConvar = "ttt2_sopd_grab_stuck_swords",
            label = "label_sopd_grab_stuck_swords"
        })
        formSword:MakeCheckBox({
            serverConvar = "ttt2_sopd_target_glow",
            label = "label_sopd_target_glow"
        })
        formSword:MakeHelp({
            label = "label_sopd_dmg_block_desc"
        })
        formSword:MakeSlider({
            serverConvar = "ttt2_sopd_target_dmg_block",
            label = "label_sopd_target_dmg_block",
            min = 0, max = 100, decimal = 0
        })
        formSword:MakeSlider({
            serverConvar = "ttt2_sopd_others_dmg_block",
            label = "label_sopd_others_dmg_block",
            min = 0, max = 100, decimal = 0
        })
        formSword:MakeHelp({
            label = "label_sopd_can_teamkill_desc"
        })
        formSword:MakeCheckBox({
            serverConvar = "ttt2_sopd_can_teamkill",
            label = "label_sopd_can_teamkill"
        })

        local formPaP = vgui.CreateTTT2Form(parent, "label_sopd_pap_form")
        formPaP:MakeSlider({
            serverConvar = "ttt2_sopd_pap_heal",
            label = "label_sopd_pap_heal",
            min = 0, max = 200, decimal = 0
        })
        formPaP:MakeHelp({
            label = "label_sopd_pap_dmg_block_desc"
        })
        formPaP:MakeSlider({
            serverConvar = "ttt2_sopd_pap_dmg_block",
            label = "label_sopd_pap_dmg_block",
            min = 0, max = 100, decimal = 0
        })

        local formSFX = vgui.CreateTTT2Form(parent, "label_sopd_sfx_form")
        formSFX:MakeHelp({
            label = "label_sopd_sfx_deploy_soundlevel_desc"
        })
        formSFX:MakeSlider({
            serverConvar = "ttt2_sopd_sfx_deploy_soundlevel",
            label = "label_sopd_sfx_deploy_soundlevel",
            min = 0, max = 300, decimal = 0
        })
        formSFX:MakeHelp({
            label = "label_sopd_sfx_volume_desc"
        })
        formSFX:MakeSlider({
            serverConvar = "ttt2_sopd_sfx_deploy_volume",
            label = "label_sopd_sfx_deploy_volume",
            min = 0, max = 100, decimal = 0
        })
        formSFX:MakeSlider({
            serverConvar = "ttt2_sopd_sfx_kill_volume",
            label = "label_sopd_sfx_kill_volume",
            min = 0, max = 100, decimal = 0
        })
        formSFX:MakeSlider({
            serverConvar = "ttt2_sopd_sfx_special_swing_chance",
            label = "label_sopd_sfx_special_swing_chance",
            min = 0, max = 100, decimal = 0
        })
        formSFX:MakeCheckBox({
            serverConvar = "ttt2_sopd_sfx_oatmeal_for_last",
            label = "label_sopd_sfx_oatmeal_for_last"
        })
        formSFX:MakeHelp({
            label = "label_sopd_sfx_stealth_desc"
        })
        formSFX:MakeSlider({
            serverConvar = "ttt2_sopd_sfx_stealth_vol_reduction",
            label = "label_sopd_sfx_stealth_vol_reduction",
            min = 0, max = 100, decimal = 0
        })
        formSFX:MakeSlider({
            serverConvar = "ttt2_sopd_sfx_stealth_max_opps",
            label = "label_sopd_sfx_stealth_max_opps",
            min = 2, max = 24, decimal = 0
        })
        formSFX:MakeSlider({
            serverConvar = "ttt2_sopd_sfx_stealth_stab_factor",
            label = "label_sopd_sfx_stealth_stab_factor",
            min = 0, max = 100, decimal = 0
        })

        local formMisc = vgui.CreateTTT2Form(parent, "label_sopd_misc_form")
        formMisc:MakeCheckBox({
            serverConvar = "ttt2_sopd_give_guy_access",
            label = "label_sopd_give_guy_access"
        })
        formMisc:MakeCheckBox({
            serverConvar = "ttt2_sopd_debug",
            label = "label_sopd_debug"
        })
    end
end