local ADDON_NAME, ns = ...

ns.ADDON_NAME = ADDON_NAME
ns.DB_VERSION = 4
ns.VERSION = (GetAddOnMetadata and GetAddOnMetadata(ADDON_NAME, "Version")) or "0.9.1"

local defaults = {
    enabled = true,
    maxLines = 2000,
    copyButton = true,
    language = "auto",
}

local function ApplyDefaults(target, source)
    for key, value in pairs(source) do
        if target[key] == nil then
            target[key] = value
        end
    end
end

local function PrepareDatabase()
    if type(UWoWChatDB) ~= "table" then
        UWoWChatDB = {}
    end

    UWoWChatDB.version = ns.DB_VERSION

    if type(UWoWChatDB.settings) ~= "table" then
        UWoWChatDB.settings = {}
    end

    if type(UWoWChatDB.profiles) ~= "table" then
        UWoWChatDB.profiles = {}
    end

    ApplyDefaults(UWoWChatDB.settings, defaults)

    -- Retired 0.1.x/0.2.x option. Clean text is temporary in the copy window.
    UWoWChatDB.settings.cleanText = nil

    ns.db = UWoWChatDB
end

local function GetProfileKey()
    local realm = GetRealmName and GetRealmName() or "UnknownRealm"
    local player = UnitName and UnitName("player") or "UnknownPlayer"

    if not realm or realm == "" then
        realm = "UnknownRealm"
    end

    if not player or player == "" then
        player = "UnknownPlayer"
    end

    return realm .. "|" .. player
end

function ns.Core_SelectProfile()
    local key = GetProfileKey()

    if type(ns.db.profiles) ~= "table" then
        ns.db.profiles = {}
    end

    if type(ns.db.profiles[key]) ~= "table" then
        ns.db.profiles[key] = {
            frames = {},
        }
    end

    local profile = ns.db.profiles[key]

    if type(profile.frames) ~= "table" then
        profile.frames = {}
    end

    -- Migration from 0.1.x: old versions stored one global history table.
    if type(ns.db.frames) == "table" and not ns.db.legacyFramesMigrated then
        local hasLegacyData = next(ns.db.frames) ~= nil

        if hasLegacyData and next(profile.frames) == nil then
            profile.frames = ns.db.frames
        end

        ns.db.frames = nil
        ns.db.legacyFramesMigrated = true
    end

    ns.profileKey = key
    ns.profile = profile

    return profile
end

function ns.Print(message)
    ns.suppressHistoryCapture = true

    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage(message)
    else
        print(message)
    end

    ns.suppressHistoryCapture = false
end

function ns.PrintService(message, color)
    color = color or "|cff66ff66"
    ns.Print(color .. "WoW Chat:|r " .. tostring(message or ""))
end

local function OpenOptions()
    if ns.Options_Open then
        ns.Options_Open()
    end
end

local function RegisterSlashCommands()
    SLASH_WOWCHAT1 = "/wowchat"
    SLASH_WOWCHAT2 = "/uwowchat"
    SLASH_WOWCHAT3 = "/wchat"

    SlashCmdList["WOWCHAT"] = function(message)
        message = tostring(message or "")

        local command, argument = message:match("^%s*(%S*)%s*(.-)%s*$")
        command = string.lower(command or "")

        if command == "" then
            OpenOptions()
            return
        end

        if command == "lang" or command == "language" then
            argument = argument or ""

            if argument == "" then
                ns.PrintService(string.format(ns.L.LANG_CURRENT, ns.db.settings.language or "auto", ns.activeLocale or "enUS"), "|cff66ccff")
                ns.PrintService(ns.L.LANG_USAGE, "|cff66ccff")
                return
            end

            local normalized = argument
            local lower = string.lower(argument)

            if lower == "auto" then
                normalized = "auto"
            elseif lower == "ruru" or lower == "ru" then
                normalized = "ruRU"
            elseif lower == "enus" or lower == "en" then
                normalized = "enUS"
            end

            if not ns.Locale_Set(normalized) then
                ns.PrintService(ns.L.LANG_USAGE, "|cffff5555")
                return
            end

            ns.PrintService(string.format(ns.L.LANG_CHANGED, normalized), "|cff66ccff")
            return
        end

        if command == "help" then
            ns.PrintService(ns.L.HELP_HEADER, "|cff66ccff")
            ns.PrintService(ns.L.HELP_OPEN, "|cff66ccff")
            ns.PrintService(ns.L.HELP_LANG, "|cff66ccff")
            return
        end

        OpenOptions()
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 ~= ADDON_NAME then
            return
        end

        PrepareDatabase()

        if ns.Locale_Refresh then
            ns.Locale_Refresh()
        end

        if ns.Options_Init then
            ns.Options_Init()
        end

        RegisterSlashCommands()

    elseif event == "PLAYER_LOGIN" then
        ns.Core_SelectProfile()

        if ns.History_Init then
            ns.History_Init()
        end

        if ns.Copy_Init then
            ns.Copy_Init()
        end

        if ns.ChatBackup_Init then
            ns.ChatBackup_Init()
        end

        if ns.Options_Refresh then
            ns.Options_Refresh()
        end
    end
end)
