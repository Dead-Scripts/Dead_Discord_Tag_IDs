-- Dead Discord Tag / Headtag System (Server-Side)

local activeTags = {}          -- [serverId] = tag string
local discordNames = {}        -- [serverId] = discord username
local hiddenTags = {}          -- [serverId] = true, hides the whole tag + name
local hiddenPrefixes = {}      -- [serverId] = true, hides only the tag prefix

local function debugPrint(msg)
    print(Config.Prefix .. msg .. "^7")
end

local function hasApi()
    return GetResourceState("Dead_Discord_API") == "started"
end

local function keysOf(tbl)
    local list = {}
    for id in pairs(tbl) do
        list[#list + 1] = id
    end
    return list
end

local function broadcastTags(target)
    TriggerClientEvent('GetStaffID:StaffStr:Return', target or -1, activeTags, keysOf(hiddenTags), keysOf(hiddenPrefixes))
end

-- Resolves the highest matching tag from Config.roleList for a player.
-- roleList is ordered lowest -> highest priority, so the last match wins.
local function resolveTag(src)
    if Config.TagsForStaffOnly and not IsPlayerAceAllowed(src, "DiscordTagIDs.Use.Tag-Toggle") then
        return nil
    end
    if not hasApi() then
        debugPrint("^1Dead_Discord_API is not running, tags cannot be resolved.")
        return nil
    end

    local roleIDs = exports.Dead_Discord_API:GetDiscordRoles(src)
    if not roleIDs or roleIDs == false then
        return nil
    end

    local tag = nil
    for i = 1, #Config.roleList do
        local configuredRole = Config.roleList[i][1]
        for j = 1, #roleIDs do
            if exports.Dead_Discord_API:CheckEqual(configuredRole, roleIDs[j]) then
                tag = Config.roleList[i][2]
                break
            end
        end
    end
    return tag
end

local function refreshTag(src)
    local serverId = tostring(src)
    local tag = resolveTag(src)
    if tag then
        activeTags[serverId] = tag
    else
        activeTags[serverId] = nil
    end
    return activeTags[serverId]
end

local function refreshName(src)
    local serverId = tostring(src)
    if not Config.UseDiscordName then
        discordNames[serverId] = nil
        return nil
    end
    if not hasApi() then return nil end

    local username, discriminator = exports.Dead_Discord_API:GetDiscordName(src)
    if not username then return nil end
    if Config.ShowDiscordDescrim and discriminator then
        username = username .. "#" .. discriminator
    end
    discordNames[serverId] = username
    return username
end

RegisterNetEvent('DiscordTag:Server:GetTag')
AddEventHandler('DiscordTag:Server:GetTag', function()
    local src = source
    refreshTag(src)
    broadcastTags(-1)
end)

RegisterNetEvent('DiscordTag:Server:GetDiscordName')
AddEventHandler('DiscordTag:Server:GetDiscordName', function()
    local src = source
    local username = refreshName(src)
    TriggerClientEvent('DiscordTag:Server:GetDiscordName:Return', -1, tostring(src), username, Config.FormatDisplayName, Config.UseDiscordName)
    -- Send the names already known to the joining player
    for serverId, name in pairs(discordNames) do
        TriggerClientEvent('DiscordTag:Server:GetDiscordName:Return', src, serverId, name, Config.FormatDisplayName, Config.UseDiscordName)
    end
end)

AddEventHandler('playerDropped', function()
    local serverId = tostring(source)
    activeTags[serverId] = nil
    discordNames[serverId] = nil
    hiddenTags[serverId] = nil
    hiddenPrefixes[serverId] = nil
    broadcastTags(-1)
end)

-- Exports declared in fxmanifest.lua

function HideUserTag(serverId, prefixOnly)
    serverId = tostring(serverId)
    if prefixOnly then
        hiddenPrefixes[serverId] = true
    else
        hiddenTags[serverId] = true
    end
    broadcastTags(-1)
end

function ShowUserTag(serverId, prefixOnly)
    serverId = tostring(serverId)
    if prefixOnly then
        hiddenPrefixes[serverId] = nil
    else
        hiddenTags[serverId] = nil
    end
    broadcastTags(-1)
end

function GetActiveUserTag(serverId)
    return activeTags[tostring(serverId)]
end

function GetUserTags()
    return activeTags
end

function SetUserTag(serverId, tag)
    serverId = tostring(serverId)
    if tag == nil or tag == "" then
        activeTags[serverId] = nil
    else
        activeTags[serverId] = tag
    end
    broadcastTags(-1)
end
