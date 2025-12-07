local DEBUG = CreateConVar("ttt2_sopd_debug", 0, {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Enables addon debug prints for client & server (should not be enabled for real play).", 0, 1)
SoPD_DBG = {}
SoPD_Utils = {}

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
        DebugPrint(indS.."Panel "..el:GetName().." (#"..#el:GetChildren().." elements)", el)
        for _, c in ipairs(el:GetChildren()) do
            DebugInspectUI(c, ind + 1)
        end

    elseif class == "Label" then
        DebugPrint(indS.."Label "..el:GetName()..": \""..el:GetText().."\"", el)
        for _, c in ipairs(el:GetChildren()) do
            DebugInspectUI(c, ind + 1)
        end

    else
        DebugPrint(indS.."Element "..el:GetName(), el)
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

SoPD_DBG.Print("[SoPD] Utils initialized")