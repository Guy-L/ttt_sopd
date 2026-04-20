local DEBUG = CreateConVar("ttt2_sopd_debug", 0, {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Enables addon debug prints for client & server (should not be enabled for real play).", 0, 1)
SoPD_DBG   = {}
SoPD_Utils = {}

SoPD_Sounds = {
    swing_base    = Sound("Weapon_Crowbar.Single"),
    swing1        = Sound("sopd/sopd_swing1.mp3"),
    swing2        = Sound("sopd/sopd_swing2.mp3"),
    swing3        = Sound("sopd/sopd_swing3.mp3"),
    swing_spc1    = Sound("sopd/sopd_swing_special1.mp3"),
    swing_spc2    = Sound("sopd/sopd_swing_special2.mp3"),
    triumph_best  = Sound("sopd/sopd_triumph_best.mp3"),
    triumph_nobgm = Sound("sopd/sopd_triumph_nobgm.mp3"),
    triumph_other = Sound("sopd/sopd_triumph_other.mp3"),
    oatmeal       = Sound("sopd/sopd_oatmeal.mp3"),
    gourmet       = Sound("sopd/sopd_gourmet.mp3"),
    inhale        = Sound("sopd/sopd_inhale.mp3"),
    rag_stab1     = Sound("sopd/sopd_rag_stab1.mp3"),
    rag_stab2     = Sound("sopd/sopd_rag_stab2.mp3"),
}

function SoPD_DBG.Inspect(obj)
    if not DEBUG:GetBool() then return end
    print(obj, type(obj))

    if type(obj) == "table" then
        PrintTable(obj)

    elseif obj.GetTable and obj:GetTable() then
        PrintTable(obj:GetTable())
    end
end

function SoPD_DBG.InspectUI(el, ind)
    if not ind then ind = 0 end
    local indS = string.rep("  ", ind)
    local class = el:GetClassName()

    if class == "Panel" then
        SoPD_DBG.Print(indS.."Panel "..el:GetName().." (#"..#el:GetChildren().." elements)", el)
        for _, c in ipairs(el:GetChildren()) do
            DebugInspectUI(c, ind + 1)
        end

    elseif class == "Label" then
        SoPD_DBG.Print(indS.."Label "..el:GetName()..": \""..el:GetText().."\"", el)
        for _, c in ipairs(el:GetChildren()) do
            DebugInspectUI(c, ind + 1)
        end

    else
        SoPD_DBG.Print(indS.."Element "..el:GetName(), el)
    end
end

function SoPD_DBG.Print(...)
    if not DEBUG:GetBool() then return end

    --reconstruct string for server relay
    local parts = {}
    for i = 1, select("#", ...) do
        parts[i] = tostring(select(i, ...))
    end
    local msg = table.concat(parts, "\t")

    -- local print
    print(msg)

    --server relay to all clients except host
    if SERVER then
        for _, ply in ipairs(player.GetAll()) do
            if not ply:IsListenServerHost() then
                ply:PrintMessage(HUD_PRINTCONSOLE, "[Server Relay] " .. msg)
            end
        end
    end
end

function SoPD_Utils.IsLivingPlayer(ply)
    return IsPlayer(ply) and ply:Alive() and not ply:IsSpec()
end

function SoPD_Utils.GetAvatar(sid, size)
    if not size then size = "small" end
    local avatarMat = draw.GetAvatarMaterial(swordTarget.SID64, size)
    local avatarTex = avatarMat:GetTexture("$basetexture")

    if avatarMat and avatarTex -- only return valid avatars
      and avatarMat:GetName() ~= "vgui/ttt/b-draw/icon_avatar_default"
      and avatarMat:GetName() ~= "vgui/ttt/b-draw/icon_avatar_bot"
      and not avatarTex:IsError()
      and not avatarTex:IsErrorTexture() then
        return avatarMat, avatarTex
    end
end

function SoPD_Utils.NonSpamMessage(ply, id, msg, serverOnly)
    if CLIENT and serverOnly then return end

    if not ply["Last"..id] or CurTime() > ply["Last"..id] + 1 then
        ply:ChatPrint(msg)
        ply["Last"..id] = CurTime()
    end
end

SoPD_DBG.Print("[SoPD] Utils initialized")