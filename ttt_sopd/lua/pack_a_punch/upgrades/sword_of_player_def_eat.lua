----------------------------------
---- CONSTANTS & UPGRADE INIT ----
----------------------------------
local HOOK_UPGRADER_DEATH      = "TTT_SoPD_MidUpgradeDeath"
local HOOK_PAP_BEGIN_ROUND     = "TTT_SoPD_ClearNetVarCache"
local HOOK_DISGUISE_DISCONNECT = "TTT_SoPD_DisguiseTargetDisconnect"
local GOT_DISGUISE_MSG         = "TTT_SoPD_GainedDisguiseMsg"
local DISGUISE_DISCONNECT_MSG  = "TTT_SoPD_DisguiseDisconnectMsg"

local UPGRADE = {}
UPGRADE.id    = "sword_of_player_def_eat"
UPGRADE.class = "weapon_ttt_sopd"
--Note: ID disguise functionality requires Identity Disguiser addon to work

----------------------------------
----- PAP SERVER/CLIENT DEFS -----
----------------------------------
if CLIENT then
    net.Receive(GOT_DISGUISE_MSG, function()
        DebugPrint("[SoPD Client] Received disguise notif")
        UpdateLocalInventorySword("received disguise")
    end)

    net.Receive(DISGUISE_DISCONNECT_MSG, function()
        DebugPrint("[SoPD Client] Received disguise disconnect notif")
        UpdateLocalInventorySword("disguise disconnected")
    end)

elseif SERVER then
    util.AddNetworkString(GOT_DISGUISE_MSG)
    util.AddNetworkString(DISGUISE_DISCONNECT_MSG)

    hook.Add("PlayerDisconnected", HOOK_DISGUISE_DISCONNECT, function(leavingPly)
        for _, ply in ipairs(player.GetAll()) do
            if ply.storedDisguiserTarget == leavingPly then
                -- note: also affects regular ID disguise which is probably for the best
                ply:ChatPrint("Disguise broke (player disconnected).")
            end

            -- if you own a sword that has leavingPly as PackVictim, update UI
            for _, wep in ipairs(ply:GetWeapons()) do
                if wep:GetClass() == UPGRADE.class and wep:GetPackVictim() == leavingPly then
                    net.Start(DISGUISE_DISCONNECT_MSG)
                    net.Send(ply)
                    break
                end
            end
        end
    end)

    -- jank to smuggle networked vars during the upgrade
    UPGRADE.netVars = {}

    function UPGRADE:Condition(SWEP)
        SWEP:StopDeploySound("packing")

        local owner = SWEP:GetOwner()
        if not IsValid(owner) then return false end

        local ownerID = owner:SteamID64()
        if not self.netVars[ownerID] then
            self.netVars[ownerID] = {}
            local s = ""

            for k, v in pairs(SWEP:GetNetworkVars()) do
                s = s .. k .. ": " .. tostring(v) .. ", "
                self.netVars[ownerID][k] = v
            end

            DebugPrint("[SoPD Server] Smuggled variables for " .. owner:Nick() .. " in upgrade: ", s)
        end

        return true
    end

    -- for the rare cases where a player dies while upgrading the item,
    -- which interrupts upgrade & messes with variable smuggling
    hook.Add("PlayerDeath", HOOK_UPGRADER_DEATH, function(ply)
        if IsValid(ply) then
            local plyID = ply:SteamID64()

            if UPGRADE.netVars[plyID] then
                DebugPrint("[SoPD Server] Cleared smuggled variables for " .. ply:Nick() .. " (player died).")
                UPGRADE.netVars[plyID] = nil
            end
        end
    end)

    -- for safety
    hook.Add("TTTBeginRound", HOOK_PAP_BEGIN_ROUND, function()
        DebugPrint("[SoPD Server] Cleared PaP variable smuggling cache.")
        UPGRADE.netVars = {}
    end)
end

----------------------------------
----- PAP UPGRADE DEFINITION -----
----------------------------------
function UPGRADE:Apply(SWEP)
    --targetless PaP swords have limited ammo for reasons that should be obvious
    if not IsSwordTargeted() then self:SetClip(SWEP, 1) end

    ----------------------------------
    ------ CLIENT REALM UPDATES ------
    ----------------------------------
    if CLIENT then
        SWEP:UpdateUI("packed")

        -- only needed to it doesn't prepend "PAP" to the name
        self.name = SWEP.PrintName

        -- description (cvar-dependent)
        local customPerks = ""

        if PAP_HEAL:GetFloat() > 0 then
            customPerks = "cannibalism + "
        else
            customPerks = "corpse removal + "
        end

        local papDmgBlock = PAP_DMG_BLOCK:GetFloat()
        if papDmgBlock == 100 then
            customPerks = customPerks .. "player damage immunity + "
        elseif papDmgBlock > 0 then
            customPerks = customPerks .. "player damage resistance + "
        end

        self.desc = "Inhale your enemy and make it later! (" .. customPerks .. "identity disguise on stab, even if the target is already dead)"

    ----------------------------------
    ----- SERVER REALM SWEP DEFS -----
    ----------------------------------
    elseif SERVER then
        SWEP:SetPacked(true) --cf. note in SetupDataTables
        SWEP:SetPackVerb(math.random() > 0.5)
        SWEP:StartDeploySound("packed")

        -- apply & clear smuggled network vars
        local upgradeOwner = SWEP:GetOwner() -- do not re-use past Apply init
        if IsValid(upgradeOwner) then
            local upgradeOwnerID = upgradeOwner:SteamID64()

            if self.netVars[upgradeOwnerID] then
                local s = ""

                for k, v in pairs(self.netVars[upgradeOwnerID]) do
                    s = s .. k .. ": " .. tostring(v) .. ", "
                    SWEP["Set"..k](SWEP, v)
                end

                DebugPrint("[SoPD Server] Applied & cleared smuggled variables for " .. upgradeOwner:Nick() .. ": ", s)
                self.netVars[upgradeOwnerID] = nil
            end
        end

        -- API method for this doesn't appear to work lol
        local function GetRagdollOwner(rag)
            for _, ply in ipairs(player.GetAll()) do
                if ply:SteamID64() == rag.sid64 then
                    return ply
                end
            end

            return nil
        end

        function SWEP:PackEffect(rag, owner)
            -- play kirby inhale noise
            owner:EmitSound(sounds["inhale"], SNDLVL_150dB, 100, AdjustVolume(true), CHAN_VOICE)

            -- delay eating to line up with suck sfx
            timer.Simple(2, function()
                if IsValid(rag) then
                    rag:Remove()
                end
            end)

            -- make it later :)
            self:SetPackVictim(GetRagdollOwner(rag))
            timer.Simple(3, function()
                if not IsValid(owner) then return end
                owner:SetHealth(owner:Health() + PAP_HEAL:GetInt())

                local packVictim = self:GetPackVictim()
                if IsValid(packVictim) and owner.ActivateDisguiserTarget then
                    owner:UpdateStoredDisguiserTarget(packVictim, packVictim:GetModel(), packVictim:GetSkin())
                    owner:ActivateDisguiserTarget()

                    net.Start(GOT_DISGUISE_MSG)
                    net.Send(owner)

                elseif owner.ActivateDisguiserTarget then
                    owner:ChatPrint("Disguise failed (player disconnected).")
                    net.Start(DISGUISE_DISCONNECT_MSG)
                    net.Send(owner)

                else
                    owner:ChatPrint("Disguise failed (ID disguise addon missing).")
                end
            end)
        end

        function SWEP:SecondaryAttack()
            local owner = self:GetOwner()
            if not owner.ToggleDisguiserTarget then return end --addon missing
            local packVictim = self:GetPackVictim()

            if IsValid(owner) and IsValid(packVictim) then
                if owner.storedDisguiserTarget == packVictim then
                    owner:ToggleDisguiserTarget()
                else
                    owner:UpdateStoredDisguiserTarget(packVictim, packVictim:GetModel(), packVictim:GetSkin())
                    owner:ActivateDisguiserTarget()
                end
            end
        end
    end
end

TTTPAP:Register(UPGRADE)