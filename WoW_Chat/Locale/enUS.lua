local ADDON_NAME, ns = ...

ns.Locales.enUS = {
    ADDON_TITLE = "WoW Chat",
    DESCRIPTION = "Persistent history, copying and Blizzard Chat settings backup.",
    META_FORMAT = "v%s • Developed by JustAlex888",

    ENABLE_HISTORY = "Enable history",
    MAX_LINES = "Saved lines:",
    CURRENT_VALUE = "Current value: %d",
    RANGE_RECOMMENDED = "Range: 200–5000. Recommended value: 2000.",
    SHOW_COPY_BUTTON = "Show copy button",
    CLEAR_CURRENT = "Clear current window",
    CLEAR_CHARACTER = "Clear character history",

    BACKUP_HEADER = "Chat settings backup",
    BACKUP_HELP = "The addon keeps a separate backup for each character.\nIf a suspicious reset is detected, it will offer restoration\nand will not overwrite a good backup with empty settings.",
    BACKUP_STATUS_NONE = "Chat settings backup: not created yet",
    BACKUP_STATUS_FORMAT = "Chat settings backup: %s",
    SAVE_CURRENT_CONFIG = "Save current configuration",
    RESTORE_CONFIG = "Restore configuration",

    POPUP_CLEAR_CURRENT = "Clear the saved history of the current chat window?",
    POPUP_CLEAR_CHARACTER = "Delete all saved history for the current character?",
    POPUP_RESET_DETECTED = "WoW Chat detected a possible Blizzard Chat settings reset.\n\nRestore the last saved configuration?",
    POPUP_CONFIRM_RESTORE = "Restore the saved chat settings?\n\nA normal /reload will be required after restoration.",
    POPUP_RESTORE_RELOAD = "Chat settings have been restored.\n\nReload the interface now?",
    RESTORE = "Restore",
    NOT_NOW = "Not now",
    YES = "Yes",
    CANCEL = "Cancel",
    RELOAD_UI = "Reload interface",
    LATER = "Later",

    COPY_TITLE = "WoW Chat — Copy",
    SELECT_ALL = "Select All",
    CLOSE = "Close",
    CLEAN_TEXT = "Clean text",
    COPY_BUTTON_LABEL = "C",
    COPY_TOOLTIP = "Copy chat history",

    SERVICE_BACKUP_SAVED = "chat settings backup saved.",
    SERVICE_NO_BACKUP = "chat settings backup has not been created yet.",
    SERVICE_FIRST_BACKUP = "initial chat settings backup created.",

    RESET_REASON_WINDOWS = "additional chat windows disappeared",
    RESET_REASON_TABS = "saved chat tabs disappeared",
    RESET_REASON_FILTERS = "message filters were reset",
    RESET_REASON_CHANNELS = "custom channels disappeared",

    LANG_CHANGED = "language mode set to %s. Use /reload to rebuild the interface.",
    LANG_CURRENT = "language mode: %s; active locale: %s.",
    LANG_USAGE = "Usage: /wowchat lang auto | ruRU | enUS",
    HELP_HEADER = "commands:",
    HELP_OPEN = "/wowchat — open settings",
    HELP_LANG = "/wowchat lang auto|ruRU|enUS — set interface language",
}
