local ADDON_NAME, ns = ...

local panel
local enabledCheck
local copyButtonCheck
local maxLinesEdit
local backupStatus

local function CreateCheckBox(parent, text, x, y)
    local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    check:SetPoint("TOPLEFT", x, y)
    check:SetSize(24, 24)

    local label = check:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("LEFT", check, "RIGHT", 4, 1)
    label:SetText(text)

    check.label = label

    return check
end

local function FormatBackupTime(timestamp)
    if not timestamp then
        return ns.L.BACKUP_STATUS_NONE
    end

    return string.format(ns.L.BACKUP_STATUS_FORMAT, date("%d.%m.%Y %H:%M:%S", timestamp))
end

local function Refresh()
    if not panel or not ns.db then
        return
    end

    enabledCheck:SetChecked(ns.db.settings.enabled and true or false)
    copyButtonCheck:SetChecked(ns.db.settings.copyButton and true or false)
    maxLinesEdit:SetText(tostring(ns.db.settings.maxLines or 2000))

    if backupStatus then
        local savedAt = ns.ChatBackup_GetSavedAt and ns.ChatBackup_GetSavedAt() or nil
        backupStatus:SetText(FormatBackupTime(savedAt))
    end
end

function ns.Options_Refresh()
    Refresh()
end

local function ApplyMaxLines()
    local value = tonumber(maxLinesEdit:GetText()) or 2000

    value = ns.History_SetMaxLines(value)

    maxLinesEdit:SetText(tostring(value))
    maxLinesEdit:ClearFocus()
end

function ns.Options_Open()
    if not panel then
        return
    end

    InterfaceOptionsFrame_OpenToCategory(panel)
    InterfaceOptionsFrame_OpenToCategory(panel)
end

function ns.Options_Init()
    if panel then
        return
    end

    panel = CreateFrame("Frame", "WoWChatOptionsPanel")
    panel.name = ns.L.ADDON_TITLE

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText(ns.L.ADDON_TITLE)

    local meta = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    meta:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -2)
    meta:SetText(string.format(ns.L.META_FORMAT, ns.VERSION))

    local description = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    description:SetPoint("TOPLEFT", meta, "BOTTOMLEFT", 0, -7)
    description:SetText(ns.L.DESCRIPTION)

    enabledCheck = CreateCheckBox(panel, ns.L.ENABLE_HISTORY, 16, -86)

    enabledCheck:SetScript("OnClick", function(self)
        ns.db.settings.enabled = self:GetChecked() and true or false
    end)

    local maxLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    maxLabel:SetPoint("TOPLEFT", 20, -132)
    maxLabel:SetText(ns.L.MAX_LINES)

    maxLinesEdit = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    maxLinesEdit:SetSize(80, 22)
    maxLinesEdit:SetPoint("LEFT", maxLabel, "RIGHT", 12, 0)
    maxLinesEdit:SetAutoFocus(false)
    maxLinesEdit:SetNumeric(true)
    maxLinesEdit:SetMaxLetters(4)

    maxLinesEdit:SetScript("OnEnterPressed", function()
        ApplyMaxLines()
    end)

    maxLinesEdit:SetScript("OnEditFocusLost", function()
        ApplyMaxLines()
    end)

    local recommendation = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    recommendation:SetPoint("TOPLEFT", maxLabel, "BOTTOMLEFT", 0, -8)
    recommendation:SetText(ns.L.RANGE_RECOMMENDED)

    copyButtonCheck = CreateCheckBox(panel, ns.L.SHOW_COPY_BUTTON, 16, -186)

    copyButtonCheck:SetScript("OnClick", function(self)
        ns.db.settings.copyButton = self:GetChecked() and true or false

        if ns.Copy_RefreshButtons then
            ns.Copy_RefreshButtons()
        end
    end)

    local clearCurrent = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    clearCurrent:SetSize(220, 24)
    clearCurrent:SetPoint("TOPLEFT", 20, -236)
    clearCurrent:SetText(ns.L.CLEAR_CURRENT)

    local clearAll = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    clearAll:SetSize(220, 24)
    clearAll:SetPoint("LEFT", clearCurrent, "RIGHT", 12, 0)
    clearAll:SetText(ns.L.CLEAR_CHARACTER)

    local backupHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    backupHeader:SetPoint("TOPLEFT", 20, -301)
    backupHeader:SetText(ns.L.BACKUP_HEADER)

    local backupHelp = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    backupHelp:SetPoint("TOPLEFT", backupHeader, "BOTTOMLEFT", 0, -8)
    backupHelp:SetWidth(620)
    backupHelp:SetJustifyH("LEFT")
    backupHelp:SetText(ns.L.BACKUP_HELP)

    backupStatus = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    backupStatus:SetPoint("TOPLEFT", backupHelp, "BOTTOMLEFT", 0, -14)
    backupStatus:SetText(ns.L.BACKUP_STATUS_NONE)

    local saveBackup = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    saveBackup:SetSize(240, 24)
    saveBackup:SetPoint("TOPLEFT", backupStatus, "BOTTOMLEFT", 0, -14)
    saveBackup:SetText(ns.L.SAVE_CURRENT_CONFIG)

    local restoreBackup = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    restoreBackup:SetSize(220, 24)
    restoreBackup:SetPoint("LEFT", saveBackup, "RIGHT", 12, 0)
    restoreBackup:SetText(ns.L.RESTORE_CONFIG)

    StaticPopupDialogs["WOWCHAT_CLEAR_CURRENT"] = {
        text = ns.L.POPUP_CLEAR_CURRENT,
        button1 = ns.L.YES,
        button2 = ns.L.CANCEL,
        OnAccept = function()
            local frame = SELECTED_CHAT_FRAME or DEFAULT_CHAT_FRAME

            if frame then
                ns.History_ClearFrame(frame)
            end
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    StaticPopupDialogs["WOWCHAT_CLEAR_ALL"] = {
        text = ns.L.POPUP_CLEAR_CHARACTER,
        button1 = ns.L.YES,
        button2 = ns.L.CANCEL,
        OnAccept = function()
            ns.History_ClearAll()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    clearCurrent:SetScript("OnClick", function()
        StaticPopup_Show("WOWCHAT_CLEAR_CURRENT")
    end)

    clearAll:SetScript("OnClick", function()
        StaticPopup_Show("WOWCHAT_CLEAR_ALL")
    end)

    saveBackup:SetScript("OnClick", function()
        if ns.ChatBackup_SaveManual then
            ns.ChatBackup_SaveManual()
        end
    end)

    restoreBackup:SetScript("OnClick", function()
        if ns.ChatBackup_RequestRestore then
            ns.ChatBackup_RequestRestore()
        end
    end)

    panel:SetScript("OnShow", Refresh)
    InterfaceOptions_AddCategory(panel)
end
