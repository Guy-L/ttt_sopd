----------------------------------
---- CONSTANTS & UPGRADE INIT ----
----------------------------------
local HOOK_DISGUISE_DISCONNECT = "TTT_SoPD_DisguiseTargetDisconnect"
local GOT_DISGUISE_MSG         = "TTT_SoPD_GainedDisguiseMsg"
local DISGUISE_DISCONNECT_MSG  = "TTT_SoPD_DisguiseDisconnectMsg"

local UPGRADE = {}
UPGRADE.id    = "sword_of_player_def_eat"
UPGRADE.class = "weapon_ttt_sopd"
--Note: ID disguise functionality requires Identity Disguiser addon to work

----------------------------------
---- PAP SERVER/CLIENT SETUP -----
----------------------------------
if CLIENT then
    net.Receive(GOT_DISGUISE_MSG, function()
        local packVictim = net.ReadPlayer()
        local invSword = GetLocalInventorySword()

        if invSword then
            invSword.PackVictim = packVictim
            invSword:UpdateUI("received disguise")
        end
    end)

    net.Receive(DISGUISE_DISCONNECT_MSG, function()
        local invSword = GetLocalInventorySword()

        if invSword and invSword.PackVictim and not IsValid(invSword.PackVictim) then
            invSword:UpdateUI("disguise disconnected")
        end
    end)

elseif SERVER then
    util.AddNetworkString(GOT_DISGUISE_MSG)
    util.AddNetworkString(DISGUISE_DISCONNECT_MSG)

    hook.Add("PlayerDisconnected", HOOK_DISGUISE_DISCONNECT, function()
        net.Start(DISGUISE_DISCONNECT_MSG)
        net.Broadcast()
    end)
end

----------------------------------
----- PAP UPGRADE DEFINITION -----
----------------------------------
function UPGRADE:Apply(SWEP)
    --targetless PaP swords have limited ammo for reasons that should be obvious
    if not swordTarget.player then self:SetClip(SWEP, 1) end
    SWEP.Packed = true

    ----------------------------------
    ------ CLIENT REALM UPDATES ------
    ----------------------------------
    if CLIENT then
        SWEP.DeleteVerb = (math.random() > 0.5)
        SWEP:UpdateUI("packed")

        -- only needed to it doesn't prepend "PAP" to the name
        UPGRADE.name = SWEP.PrintName

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

        UPGRADE.desc = "Inhale your enemy and make it later! (" .. customPerks .. "identity disguise on stab, even if the target is already dead)"

    ----------------------------------
    ----- SERVER REALM SWEP DEFS -----
    ----------------------------------
    elseif SERVER then
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
            owner:EmitSound(sounds["inhale"], SNDLVL_150dB, 100, AdjustVolume(KILL_SND_VOLUME:GetFloat()/100), CHAN_VOICE)

            -- delay eating to line up with suck sfx
            timer.Simple(2, function()
                if IsValid(rag) then
                    rag:Remove()
                end
            end)

            -- make it later :)
            self.PackVictim = GetRagdollOwner(rag)
            timer.Simple(3, function()
                if not IsValid(owner) then return end
                owner:SetHealth(owner:Health() + PAP_HEAL:GetInt())

                if IsValid(self.PackVictim) and owner.ActivateDisguiserTarget then
                    owner:UpdateStoredDisguiserTarget(self.PackVictim, self.PackVictim:GetModel(), self.PackVictim:GetSkin())
                    owner:ActivateDisguiserTarget()

                    net.Start(GOT_DISGUISE_MSG)
                    net.WritePlayer(self.PackVictim)
                    net.Send(owner)
                end
            end)
        end

        function SWEP:SecondaryAttack()
            local owner = self:GetOwner()

            if IsValid(owner) and owner.ToggleDisguiserTarget and IsValid(self.PackVictim)
              and owner.storedDisguiserTarget == self.PackVictim then
                owner:ToggleDisguiserTarget()
            end
        end
    end
end

TTTPAP:Register(UPGRADE)