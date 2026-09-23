local ADDON_NAME, ns = ...

ns.Locales = ns.Locales or {}
ns.L = ns.L or {}

local function ClearTable(t)
    for key in pairs(t) do
        t[key] = nil
    end
end

local function ResolveLocale()
    local requested = "auto"

    if ns.db and ns.db.settings and ns.db.settings.language then
        requested = ns.db.settings.language
    end

    local locale = requested

    if locale == "auto" or locale == "" or not locale then
        locale = GetLocale and GetLocale() or "enUS"
    end

    if locale ~= "ruRU" and locale ~= "enUS" then
        locale = "enUS"
    end

    return locale, requested
end

function ns.Locale_Refresh()
    local locale, requested = ResolveLocale()
    local fallback = ns.Locales.enUS or {}
    local selected = ns.Locales[locale] or fallback

    ClearTable(ns.L)

    for key, value in pairs(fallback) do
        ns.L[key] = value
    end

    for key, value in pairs(selected) do
        ns.L[key] = value
    end

    ns.activeLocale = locale
    ns.requestedLocale = requested

    return locale
end

function ns.Locale_Set(mode)
    if not ns.db or not ns.db.settings then
        return false
    end

    if mode ~= "auto" and mode ~= "ruRU" and mode ~= "enUS" then
        return false
    end

    ns.db.settings.language = mode
    ns.Locale_Refresh()
    return true
end
