-- Player ID & Discord Tag Display Script (Cleaned & Fixed)

local playerDiscordNames = {}
local activeTagTracker = {}
local hideTags = {}
local hidePrefix = {}
local formatDisplayedName = "[{SERVER_ID}]"

local ignorePlayerNameDistance = false
local playerNamesDist = 15
local displayIDHeight = 1.5 -- Height above head

-- Default colors
local red, green, blue = 255, 255, 255

-- Draw 3D Text
function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    local dist = GetDistanceBetweenCoords(px, py, pz, x, y, z, true)

    local scale = (1 / dist) * 2
    local fov = (1 / GetGameplayCamFov()) * 100
    scale = scale * fov

    if onScreen then
        SetTextScale(0.0 * scale, 0.55 * scale)
        SetTextFont(0)
        SetTextProportional(1)
        SetTextColour(red, green, blue, 255)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

-- Draw 2D Text
function Draw2DText(x, y, text, scale, center)
    SetTextFont(4)
    SetTextProportional(7)
    SetTextScale(scale, scale)
    SetTextColour(255, 255, 255, 255)
    SetTextDropShadow(0, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextEdge(4, 0, 0, 0, 255)
    SetTextOutline()
    if center then SetTextJustification(1) end
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x, y)
end

-- Server state
local function toSet(list)
    local set = {}
    for _, v in ipairs(list or {}) do
        set[tostring(v)] = true
    end
    return set
end

RegisterNetEvent('GetStaffID:StaffStr:Return')
AddEventHandler('GetStaffID:StaffStr:Return', function(tags, hiddenTags, hiddenPrefixes)
    activeTagTracker = tags or {}
    hideTags = toSet(hiddenTags)
    hidePrefix = toSet(hiddenPrefixes)
end)

RegisterNetEvent('DiscordTag:Server:GetDiscordName:Return')
AddEventHandler('DiscordTag:Server:GetDiscordName:Return', function(serverId, discordUsername, format, useDiscordName)
    if useDiscordName and discordUsername then
        playerDiscordNames[tostring(serverId)] = discordUsername
    end
    if format then
        formatDisplayedName = format
    end
end)

-- Update player tags
local colors = {"~g~", "~b~", "~y~", "~o~", "~r~", "~p~", "~w~"}
local colorIndex = 1
local timer = 500

function triggerTagUpdate()
    for _, id in ipairs(GetActivePlayers()) do
        local ped = GetPlayerPed(id)
        if ped == GetPlayerPed(-1) and not Config.ShowOwnTag then goto continue end

        local serverId = tostring(GetPlayerServerId(id))
        local activeTag = activeTagTracker[serverId] or ""
        local x1, y1, z1 = table.unpack(GetEntityCoords(PlayerPedId()))
        local x2, y2, z2 = table.unpack(GetEntityCoords(ped))
        local distance = math.floor(GetDistanceBetweenCoords(x1, y1, z1, x2, y2, z2, true))

        if distance > playerNamesDist and not ignorePlayerNameDistance then goto continue end
        if Config.RequiresLineOfSight and not HasEntityClearLosToEntity(PlayerPedId(), ped, 17) then goto continue end

        local name = playerDiscordNames[serverId] or GetPlayerName(id)
        local displayName = formatDisplayedName:gsub("{PLAYER_NAME}", name):gsub("{SERVER_ID}", GetPlayerServerId(id))

        if NetworkIsPlayerTalking(id) then
            red, green, blue = 0, 0, 255
        else
            red, green, blue = 255, 255, 255
        end

        if not hideTags[serverId] then
            if not hidePrefix[serverId] then
                -- Rainbow tag handling
                if activeTag:find("~RGB~") then
                    local tag = activeTag:gsub("~RGB~", colors[colorIndex])
                    timer = timer - 10
                    if timer <= 0 then
                        colorIndex = colorIndex + 1
                        if colorIndex > #colors then colorIndex = 1 end
                        timer = 3000
                    end
                    DrawText3D(x2, y2, z2 + displayIDHeight, tag .. "~w~" .. displayName)
                else
                    DrawText3D(x2, y2, z2 + displayIDHeight, activeTag .. "~w~" .. displayName)
                end
            else
                DrawText3D(x2, y2, z2 + displayIDHeight, "~w~" .. displayName)
            end
        end

        ::continue::
    end
end

-- Fetch tags after spawn
Citizen.CreateThread(function()
    Wait(1000)
    TriggerServerEvent('DiscordTag:Server:GetTag')
    TriggerServerEvent('DiscordTag:Server:GetDiscordName')
end)

-- HUD display
if Config.HUD.Display then
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(0)
            local headtag = activeTagTracker[tostring(GetPlayerServerId(PlayerId()))] or "N/A"
            Draw2DText(Config.HUD.x, Config.HUD.y, Config.HUD.Format:gsub("{HEADTAG}", headtag), Config.HUD.Scale, true)
        end
    end)
end

-- Keybind toggle
local showTags = Config.KeyBindToggleDefaultShow
Citizen.CreateThread(function()
    while true do
        for i=0,99 do N_0x31698aa80e0223f8(i) end
        if Config.UseKeyBind then
            if Config.UseKeyBindToggle then
                if IsControlJustReleased(0, Config.KeyBind) then showTags = not showTags end
                if showTags then triggerTagUpdate() end
            else
                if IsControlPressed(0, Config.KeyBind) then triggerTagUpdate() end
            end
        else
            triggerTagUpdate()
        end
        Citizen.Wait(0)
    end
end)
