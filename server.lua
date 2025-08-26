-- Dead Discord Tag / Headtag System (Client-Side)

local playerDiscordNames = {}
local formatDisplayedName = "[{SERVER_ID}]"
local ignorePlayerNameDistance = false
local playerNamesDist = 15
local displayIDHeight = 1.5

-- Default colors
local red, green, blue = 255, 255, 255

-- Draw 3D text above player heads
function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    local dist = GetDistanceBetweenCoords(px, py, pz, x, y, z, true)
    local scale = (1 / dist) * 2 * (1 / GetGameplayCamFov()) * 100

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

-- Draw simple 2D text (HUD)
function Draw2DText(x, y, text, scale, center)
    SetTextFont(4)
    SetTextProportional(7)
    SetTextScale(scale, scale)
    SetTextColour(255, 255, 255, 255)
    SetTextDropShadow(0, 0, 0, 0, 255)
    SetTextEdge(4, 0, 0, 0, 255)
    SetTextOutline()
    if center then SetTextJustification(0) end
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x, y)
end

-- Utility
local function has_value(tab, val)
    for _, v in ipairs(tab) do
        if v == val then return true end
    end
    return false
end

-- Config tracking
local prefixes = {}
local activeTagTracker = {}
local hidePrefix = {}
local hideTags = {}
local hideAll = false
local prefixStr = ""

-- Receive Discord names from server
RegisterNetEvent("DiscordTag:Server:GetDiscordName:Return")
AddEventHandler("DiscordTag:Server:GetDiscordName:Return", function(serverId, discordUsername, format, useDiscordName)
    if useDiscordName then
        playerDiscordNames[serverId] = discordUsername
    end
    formatDisplayedName = format
end)

-- Receive Headtag info from server
RegisterNetEvent("GetStaffID:StaffStr:Return")
AddEventHandler("GetStaffID:StaffStr:Return", function(arr, activeTagTrack)
    prefixes = arr
    activeTagTracker = activeTagTrack
end)

-- Trigger player tag update
local colorIndex = 1
local colors = {"~g~", "~b~", "~y~", "~o~", "~r~", "~p~", "~w~"}
local timer = 500

function triggerTagUpdate()
    if hideAll then return end
    for _, id in ipairs(GetActivePlayers()) do
        local ped = GetPlayerPed(id)
        if NetworkIsPlayerActive(id) and (ped ~= PlayerPedId() or Config.ShowOwnTag) then
            local x1, y1, z1 = table.unpack(GetEntityCoords(PlayerPedId()))
            local x2, y2, z2 = table.unpack(GetEntityCoords(ped))
            local distance = GetDistanceBetweenCoords(x1, y1, z1, x2, y2, z2, true)
            if distance <= playerNamesDist or ignorePlayerNameDistance then
                local displayName = formatDisplayedName
                local name = playerDiscordNames[GetPlayerServerId(id)] or GetPlayerName(id)
                displayName = displayName:gsub("{PLAYER_NAME}", name):gsub("{SERVER_ID}", GetPlayerServerId(id))

                if Config.RequiresLineOfSight and not HasEntityClearLosToEntity(PlayerPedId(), ped, 17) then
                    goto continue
                end

                local activeTag = activeTagTracker[GetPlayerServerId(id)] or ""
                local showTag = true
                if has_value(hideTags, GetPlayerName(id)) then showTag = false end
                local showPrefix = not has_value(hidePrefix, GetPlayerName(id))

                if showTag then
                    if NetworkIsPlayerTalking(id) then
                        red, green, blue = 0, 0, 255
                    else
                        red, green, blue = 255, 255, 255
                    end

                    local tagText = ""
                    if showPrefix then
                        if activeTag:find("~RGB~") then
                            tagText = activeTag:gsub("~RGB~", colors[colorIndex])
                            if timer <= 0 then
                                colorIndex = colorIndex + 1
                                if colorIndex > #colors then colorIndex = 1 end
                                timer = 3000
                            end
                        else
                            tagText = activeTag
                        end
                    end

                    DrawText3D(x2, y2, z2 + displayIDHeight, tagText .. "~w~" .. displayName)
                end
            end
        end
        ::continue::
    end
end

-- Initial requests
Citizen.CreateThread(function()
    Wait(1000)
    TriggerServerEvent('DiscordTag:Server:GetTag')
    TriggerServerEvent('DiscordTag:Server:GetDiscordName')
end)

-- HUD Display
if Config.HUD.Display then
    Citizen.CreateThread(function()
        while true do
            Wait(0)
            local headtag = activeTagTracker[GetPlayerServerId(PlayerId())] or Config.roleList[1][2] or 'N/A'
            Draw2DText(Config.HUD.x, Config.HUD.y, Config.HUD.Format:gsub("{HEADTAG}", headtag), Config.HUD.Scale, true)
        end
    end)
end

-- Keybind toggle
local showTags = Config.KeyBindToggleDefaultShow
Citizen.CreateThread(function()
    while true do
        for i = 0, 99 do
            N_0x31698aa80e0223f8(i)
        end

        if Config.UseKeyBind then
            if not Config.UseKeyBindToggle and IsControlPressed(0, Config.KeyBind) then
                triggerTagUpdate()
            elseif Config.UseKeyBindToggle and IsControlJustReleased(0, Config.KeyBind) then
                showTags = not showTags
            end

            if showTags then triggerTagUpdate() end
        else
            triggerTagUpdate()
        end

        Citizen.Wait(0)
    end
end)
