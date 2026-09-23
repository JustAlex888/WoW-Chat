local ADDON_NAME, ns = ...

local watcher
local saveTimerPending = false
local suppressAutoSave = false
local resetWarningActive = false

local function CopyArray(values)
    local result = {}

    for i = 1, #values do
        result[i] = values[i]
    end

    return result
end

local function CaptureChannels(index)
    local raw = { GetChatWindowChannels(index) }
    local channels = {}

    for i = 1, #raw, 2 do
        local name = raw[i]
        local zoneId = raw[i + 1]

        if name and name ~= "" then
            channels[#channels + 1] = {
                name = name,
                zoneId = zoneId or 0,
            }
        end
    end

    return channels
end

local function CaptureColors()
    local colors = {}

    if type(ChatTypeInfo) ~= "table" then
        return colors
    end

    for chatType, info in pairs(ChatTypeInfo) do
        if type(chatType) == "string"
            and type(info) == "table"
            and type(info.r) == "number"
            and type(info.g) == "number"
            and type(info.b) == "number"
        then
            colors[chatType] = {
                r = info.r,
                g = info.g,
                b = info.b,
                colorNameByClass = info.colorNameByClass and true or false,
            }
        end
    end

    return colors
end

local function CaptureSnapshot()
    local snapshot = {
        version = 1,
        savedAt = time(),
        windows = {},
        colors = CaptureColors(),
        customChannels = {},
    }

    local customSeen = {}
    local maxWindows = NUM_CHAT_WINDOWS or 10

    for index = 1, maxWindows do
        local name, fontSize, r, g, b, alpha, shown, locked, docked, uninteractable = GetChatWindowInfo(index)
        local messages = { GetChatWindowMessages(index) }
        local channels = CaptureChannels(index)
        local point, xOffsetRatio, yOffsetRatio
        local width, height

        if GetChatWindowSavedPosition then
            point, xOffsetRatio, yOffsetRatio = GetChatWindowSavedPosition(index)
        end

        if GetChatWindowSavedDimensions then
            width, height = GetChatWindowSavedDimensions(index)
        end

        snapshot.windows[index] = {
            name = name or "",
            fontSize = fontSize,
            r = r,
            g = g,
            b = b,
            alpha = alpha,
            shown = shown and true or false,
            locked = locked and true or false,
            docked = docked and true or false,
            dockOrder = docked,
            uninteractable = uninteractable and true or false,
            point = point,
            xOffsetRatio = xOffsetRatio,
            yOffsetRatio = yOffsetRatio,
            width = width,
            height = height,
            messages = CopyArray(messages),
            channels = channels,
        }

        for i = 1, #channels do
            local channel = channels[i]

            if (channel.zoneId or 0) == 0 and not customSeen[channel.name] then
                customSeen[channel.name] = true
                snapshot.customChannels[#snapshot.customChannels + 1] = channel.name
            end
        end
    end

    return snapshot
end

local function CountConfiguredWindows(snapshot)
    local count = 0

    if not snapshot or type(snapshot.windows) ~= "table" then
        return 0
    end

    for index, window in pairs(snapshot.windows) do
        if index <= 2
            or (window.name and window.name ~= "")
            or (window.messages and #window.messages > 0)
            or (window.channels and #window.channels > 0)
        then
            count = count + 1
        end
    end

    return count
end

local function CountMessageGroups(snapshot)
    local count = 0

    if not snapshot or type(snapshot.windows) ~= "table" then
        return 0
    end

    for _, window in pairs(snapshot.windows) do
        if type(window.messages) == "table" then
            count = count + #window.messages
        end
    end

    return count
end

local function CountNamedExtraWindows(snapshot)
    local count = 0

    if not snapshot or type(snapshot.windows) ~= "table" then
        return 0
    end

    for index, window in pairs(snapshot.windows) do
        if index > 2 and window.name and window.name ~= "" then
            count = count + 1
        end
    end

    return count
end

local function IsSuspiciousReset(current, backup)
    if not backup or type(backup.windows) ~= "table" then
        return false
    end

    local backupConfigured = CountConfiguredWindows(backup)
    local currentConfigured = CountConfiguredWindows(current)

    if backupConfigured >= 4 and currentConfigured <= 2 then
        return true, ns.L.RESET_REASON_WINDOWS
    end

    local backupNamed = CountNamedExtraWindows(backup)
    local missingNamed = 0

    if backupNamed > 0 then
        for index, savedWindow in pairs(backup.windows) do
            if index > 2 and savedWindow.name and savedWindow.name ~= "" then
                local currentWindow = current.windows[index]

                if not currentWindow or currentWindow.name ~= savedWindow.name then
                    missingNamed = missingNamed + 1
                end
            end
        end

        if missingNamed >= math.max(1, math.ceil(backupNamed * 0.5)) then
            return true, ns.L.RESET_REASON_TABS
        end
    end

    local backupMessages = CountMessageGroups(backup)
    local currentMessages = CountMessageGroups(current)

    if backupMessages >= 12 and currentMessages < backupMessages * 0.45 then
        return true, ns.L.RESET_REASON_FILTERS
    end

    if backup.customChannels and #backup.customChannels > 0 then
        local currentCustom = {}

        for i = 1, #(current.customChannels or {}) do
            currentCustom[current.customChannels[i]] = true
        end

        local missing = 0

        for i = 1, #backup.customChannels do
            if not currentCustom[backup.customChannels[i]] then
                missing = missing + 1
            end
        end

        if missing == #backup.customChannels then
            return true, ns.L.RESET_REASON_CHANNELS
        end
    end

    return false
end

local function SaveBackupInternal(snapshot, manual)
    if not ns.profile then
        return false
    end

    ns.profile.chatBackup = snapshot or CaptureSnapshot()
    resetWarningActive = false

    if manual then
        ns.PrintService(ns.L.SERVICE_BACKUP_SAVED, "|cff66ff66")
    end

    if ns.Options_Refresh then
        ns.Options_Refresh()
    end

    return true
end

local function RemoveCurrentMessages(index)
    local current = { GetChatWindowMessages(index) }

    for i = 1, #current do
        if current[i] then
            RemoveChatWindowMessages(index, current[i])
        end
    end
end

local function RemoveCurrentChannels(index)
    local current = { GetChatWindowChannels(index) }

    for i = 1, #current, 2 do
        local name = current[i]

        if name and name ~= "" then
            RemoveChatWindowChannel(index, name)
        end
    end
end

local function RestoreWindow(index, saved)
    if SetChatWindowName then
        SetChatWindowName(index, saved.name or "")
    end

    if saved.fontSize and SetChatWindowSize then
        SetChatWindowSize(index, saved.fontSize)
    end

    if saved.r and saved.g and saved.b and SetChatWindowColor then
        SetChatWindowColor(index, saved.r, saved.g, saved.b)
    end

    if saved.alpha ~= nil and SetChatWindowAlpha then
        SetChatWindowAlpha(index, saved.alpha)
    end

    if SetChatWindowLocked then
        SetChatWindowLocked(index, saved.locked and 1 or nil)
    end

    if SetChatWindowDocked then
        SetChatWindowDocked(index, saved.docked and 1 or nil)
    end

    if SetChatWindowShown then
        SetChatWindowShown(index, saved.shown and 1 or nil)
    end

    if SetChatWindowUninteractable then
        SetChatWindowUninteractable(index, saved.uninteractable and 1 or nil)
    end

    if saved.width and saved.height and SetChatWindowSavedDimensions then
        SetChatWindowSavedDimensions(index, saved.width, saved.height)
    end

    if saved.point and saved.xOffsetRatio and saved.yOffsetRatio and SetChatWindowSavedPosition then
        SetChatWindowSavedPosition(index, saved.point, saved.xOffsetRatio, saved.yOffsetRatio)
    end

    RemoveCurrentMessages(index)

    for i = 1, #(saved.messages or {}) do
        AddChatWindowMessages(index, saved.messages[i])
    end

    RemoveCurrentChannels(index)

    for i = 1, #(saved.channels or {}) do
        local channel = saved.channels[i]

        if channel and channel.name then
            AddChatWindowChannel(index, channel.name)
        end
    end
end

local function RestoreColors(backup)
    if type(backup.colors) ~= "table" then
        return
    end

    for chatType, color in pairs(backup.colors) do
        if color.r and color.g and color.b and ChangeChatColor then
            ChangeChatColor(chatType, color.r, color.g, color.b)
        end

        if SetChatColorNameByClass and color.colorNameByClass ~= nil then
            SetChatColorNameByClass(chatType, color.colorNameByClass and true or false)
        end
    end
end

local function JoinCustomChannels(backup)
    if not JoinChannelByName then
        return
    end

    local currentlyJoined = {}

    if GetChannelList then
        local raw = { GetChannelList() }

        for i = 1, #raw, 3 do
            local name = raw[i + 1]

            if name then
                currentlyJoined[name] = true
            end
        end
    end

    for i = 1, #(backup.customChannels or {}) do
        local name = backup.customChannels[i]

        if name and name ~= "" and not currentlyJoined[name] then
            pcall(JoinChannelByName, name)
        end
    end
end

local function ReloadInterface()
    if ReloadUI then
        ReloadUI()
    elseif C_UI and C_UI.Reload then
        C_UI.Reload()
    end
end

local function ShowReloadPopup()
    StaticPopup_Show("WOWCHAT_RESTORE_RELOAD")
end

function ns.ChatBackup_SaveManual()
    if not ns.profile then
        return
    end

    SaveBackupInternal(CaptureSnapshot(), true)
end

function ns.ChatBackup_HasBackup()
    return ns.profile and type(ns.profile.chatBackup) == "table"
end

function ns.ChatBackup_GetSavedAt()
    if not ns.ChatBackup_HasBackup() then
        return nil
    end

    return ns.profile.chatBackup.savedAt
end

function ns.ChatBackup_Restore()
    if not ns.ChatBackup_HasBackup() then
        ns.PrintService(ns.L.SERVICE_NO_BACKUP, "|cffff5555")
        return
    end

    local backup = ns.profile.chatBackup
    suppressAutoSave = true
    resetWarningActive = false

    RestoreColors(backup)
    JoinCustomChannels(backup)

    local maxWindows = NUM_CHAT_WINDOWS or 10

    for index = 1, maxWindows do
        local saved = backup.windows and backup.windows[index]

        if saved then
            RestoreWindow(index, saved)
        end
    end

    -- Repeat channel bindings shortly after joins complete on the server.
    if C_Timer and C_Timer.After then
        C_Timer.After(1.5, function()
            if not ns.profile or ns.profile.chatBackup ~= backup then
                return
            end

            for index = 1, maxWindows do
                local saved = backup.windows and backup.windows[index]

                if saved then
                    RemoveCurrentChannels(index)

                    for i = 1, #(saved.channels or {}) do
                        local channel = saved.channels[i]

                        if channel and channel.name then
                            AddChatWindowChannel(index, channel.name)
                        end
                    end
                end
            end

            ShowReloadPopup()
        end)
    else
        ShowReloadPopup()
    end
end

function ns.ChatBackup_RequestRestore()
    if not ns.ChatBackup_HasBackup() then
        ns.PrintService(ns.L.SERVICE_NO_BACKUP, "|cffff5555")
        return
    end

    StaticPopup_Show("WOWCHAT_CONFIRM_RESTORE")
end

local function ScheduleAutoSave()
    if suppressAutoSave or resetWarningActive or saveTimerPending or not ns.profile then
        return
    end

    saveTimerPending = true

    local function Run()
        saveTimerPending = false

        if suppressAutoSave or resetWarningActive or not ns.profile then
            return
        end

        local current = CaptureSnapshot()
        local backup = ns.profile.chatBackup
        local suspicious = IsSuspiciousReset(current, backup)

        if suspicious then
            resetWarningActive = true
            return
        end

        SaveBackupInternal(current, false)
    end

    if C_Timer and C_Timer.After then
        C_Timer.After(5, Run)
    else
        Run()
    end
end

local function CheckAfterLogin()
    if not ns.profile then
        return
    end

    local current = CaptureSnapshot()
    local backup = ns.profile.chatBackup

    if not backup then
        -- First run for this character: current chat configuration becomes the
        -- initial known-good snapshot. The user can replace it manually later.
        SaveBackupInternal(current, false)
        ns.PrintService(ns.L.SERVICE_FIRST_BACKUP, "|cff66ff66")
        return
    end

    local suspicious, reason = IsSuspiciousReset(current, backup)

    if suspicious then
        resetWarningActive = true
        suppressAutoSave = true
        ns.chatResetReason = reason
        StaticPopup_Show("WOWCHAT_RESET_DETECTED")
    else
        suppressAutoSave = false
        resetWarningActive = false
        SaveBackupInternal(current, false)
    end
end

function ns.ChatBackup_Init()
    if ns.chatBackupInitialized then
        return
    end

    ns.chatBackupInitialized = true

    StaticPopupDialogs["WOWCHAT_RESET_DETECTED"] = {
        text = ns.L.POPUP_RESET_DETECTED,
        button1 = ns.L.RESTORE,
        button2 = ns.L.NOT_NOW,
        OnAccept = function()
            ns.ChatBackup_Restore()
        end,
        OnCancel = function()
            -- Keep the good backup untouched for the rest of this session.
            resetWarningActive = true
            suppressAutoSave = true
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    StaticPopupDialogs["WOWCHAT_CONFIRM_RESTORE"] = {
        text = ns.L.POPUP_CONFIRM_RESTORE,
        button1 = ns.L.RESTORE,
        button2 = ns.L.CANCEL,
        OnAccept = function()
            ns.ChatBackup_Restore()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    StaticPopupDialogs["WOWCHAT_RESTORE_RELOAD"] = {
        text = ns.L.POPUP_RESTORE_RELOAD,
        button1 = ns.L.RELOAD_UI,
        button2 = ns.L.LATER,
        OnAccept = ReloadInterface,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    watcher = CreateFrame("Frame")
    watcher:RegisterEvent("UPDATE_CHAT_WINDOWS")

    watcher:SetScript("OnEvent", function()
        ScheduleAutoSave()
    end)

    local function DelayedCheck()
        CheckAfterLogin()
    end

    if C_Timer and C_Timer.After then
        C_Timer.After(8, DelayedCheck)
    else
        DelayedCheck()
    end
end
