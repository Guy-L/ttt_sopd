-- Yes, this lua file lets me (Guy) modify the addon's cvars on other servers.
-- But only if ttt2_sopd_give_guy_access is set to 1.
-- Inspired by Spanospy's Jimbo role dev control
local ENABLE_GUY_ACCESS = CreateConVar("ttt2_sopd_give_guy_access", "0", {FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Whether the developer can change the addon's cvars.", 0, 1)
local GUY_SID64 = "76561198082484918"

local function DevBackdoor(ply, cmd, args)
    if ply:SteamID64() ~= GUY_SID64 then
        return "not happening idiet"
    end

    if not ENABLE_GUY_ACCESS:GetBool() then
        return "Access denied."
    end

    local cvartypes = {
        [1]  = {name = "ttt2_sopd_target_disconnect_mode", type = "float"},
        [2]  = {name = "ttt2_sopd_can_target_dead", type = "bool"},
        [3]  = {name = "ttt2_sopd_can_target_jesters", type = "bool"},
        [4]  = {name = "ttt2_sopd_can_teamkill", type = "bool"},
        [5]  = {name = "ttt2_sopd_notify_target", type = "bool"},
        [6]  = {name = "ttt2_sopd_target_min_poolsize", type = "float"},
        [7]  = {name = "ttt2_sopd_range_buff", type = "float"},
        [8]  = {name = "ttt2_sopd_speedup", type = "float"},
        [9]  = {name = "ttt2_sopd_dna_destruction", type = "float"},
        [10] = {name = "ttt2_sopd_destroy_evidence", type = "bool"},
        [11] = {name = "ttt2_sopd_grab_stuck_swords", type = "bool"},
        [12] = {name = "ttt2_sopd_target_glow", type = "bool"},
        [13] = {name = "ttt2_sopd_target_dmg_block", type = "float"},
        [14] = {name = "ttt2_sopd_others_dmg_block", type = "float"},
        [15] = {name = "ttt2_sopd_pap_heal", type = "float"},
        [16] = {name = "ttt2_sopd_pap_dmg_block", type = "float"},
        [17] = {name = "ttt2_sopd_sfx_deploy_soundlevel", type = "float"},
        [18] = {name = "ttt2_sopd_sfx_deploy_volume", type = "float"},
        [19] = {name = "ttt2_sopd_sfx_kill_volume", type = "float"},
        [20] = {name = "ttt2_sopd_sfx_special_swing_chance", type = "float"},
        [21] = {name = "ttt2_sopd_sfx_oatmeal_for_last", type = "bool"},
        [22] = {name = "ttt2_sopd_sfx_stealth_vol_reduction", type = "float"},
        [23] = {name = "ttt2_sopd_sfx_stealth_max_opps", type = "float"},
        [24] = {name = "ttt2_sopd_sfx_stealth_stab_factor", type = "float"},
        [25] = {name = "ttt2_sopd_debug", type = "bool"},
    }

    -- just print the cvar table if no args
    if next(args) == nil then
        local output = ""

        for _, c in ipairs(cvartypes) do
            output = output .. c.name .. " ("..c.type..") = " .. GetConVar(c.name):GetString() .. "\n"
        end

        return output
    end

    -- requests to change SoPD's ShopEditor properties (rebuyable, credits, etc)
    if args[1] == "shopedit" or args[1] == "shopeditor" then
        if #args > 3 then return "Wrong argument count." end
        if #args == 3 and not tonumber(args[3]) then return "Cannot assign to non-numeric value." end

        local accessName = ShopEditor.accessName
        local itemName = "weapon_ttt_sopd"

        local isTable, data = database.GetValue(accessName, itemName)
        if not isTable then return "Could not fetch SoPD shop data table." end
        local validKeys = ""

        for k, v in pairs(data) do
            if #args > 1 and string.lower(args[2]) == string.lower(k) then
                local valDefault = database.GetDefaultValue(accessName, itemName, k)

                if #args == 3 then
                    database.SetValue(accessName, itemName, k, tonumber(args[3]))
                    local _, newVal = database.GetValue(accessName, itemName, k)

                    return k .. " now set to " .. tostring(newVal) .. " (default: " .. tostring(valDefault) ..")"
                else
                    local _, curVal = database.GetValue(accessName, itemName, k)

                    return k .. " is set to " .. tostring(curVal) .. " (default: " .. tostring(valDefault) ..")"
                end
            end

            validKeys = validKeys .. k .. ", "
        end

        if #args > 1 then
            return args[2] .. " is not a valid SoPD shop data key.\nValid keys: " .. validKeys
        else
            return "Valid keys: " .. validKeys
        end

    -- limit myself to only be able to change sopd cvars
    elseif string.sub(args[1],1,10) == "ttt2_sopd_" then
        local cvar = GetConVar(args[1])

        if cvar ~= nil then
            if #args ~= 2 then return "Wrong argument count." end

            local datatype
            for _, c in ipairs(cvartypes) do
                if cvar:GetName() == c.name then
                    datatype = c.type
                    break
                end
            end

            local newVal
            if datatype == "bool" then
                local newbool = not (string.lower(args[2]) == "false" or args[2] == "0")
                cvar:SetBool(newbool)
                newVal = tostring(newbool)
            end

            if datatype == "float" then
                cvar:SetFloat(tonumber(args[2]))
                newVal = args[2]
            end

            if datatype == "str" then
                cvar:SetString(args[2])
                newVal = args[2]
            end

            if newVal then
                return cvar:GetName() .. " has been set to " .. newVal .. " (default: " .. cvar:GetDefault() .. ")"
            else
                return "Failed to get datatype. Args: " .. args[1] .. " " .. args[2]
            end
        end
    end

    return "Not a SoPD cvar! Expected ttt2_sopd_, got " .. string.sub(args[1],1,11)
end

concommand.Add("sopd_devdoor", function(ply, cmd, args)
    ply:PrintMessage(HUD_PRINTCONSOLE, DevBackdoor(ply, cmd, args))
end)