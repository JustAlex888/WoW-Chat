local ADDON_NAME, ns = ...

ns.Locales.ruRU = {
    ADDON_TITLE = "WoW Chat",
    DESCRIPTION = "Постоянная история, копирование и резерв настроек Blizzard Chat.",
    META_FORMAT = "v%s • Developed by JustAlex888",

    ENABLE_HISTORY = "Включить историю",
    MAX_LINES = "Количество сохраняемых строк:",
    RANGE_RECOMMENDED = "Диапазон: 200–5000. Рекомендуемое значение: 2000.",
    SHOW_COPY_BUTTON = "Показывать кнопку копирования",
    CLEAR_CURRENT = "Очистить текущее окно",
    CLEAR_CHARACTER = "Очистить историю персонажа",

    BACKUP_HEADER = "Резерв настроек чата",
    BACKUP_HELP = "Аддон хранит отдельный резерв для каждого персонажа. При подозрительном сбросе он предложит восстановление и не перезапишет хороший резерв пустыми настройками.",
    BACKUP_STATUS_NONE = "Резерв настроек чата: ещё не создан",
    BACKUP_STATUS_FORMAT = "Резерв настроек чата: %s",
    SAVE_CURRENT_CONFIG = "Сохранить текущую конфигурацию",
    RESTORE_CONFIG = "Восстановить конфигурацию",

    POPUP_CLEAR_CURRENT = "Очистить сохранённую историю текущего окна чата?",
    POPUP_CLEAR_CHARACTER = "Полностью удалить сохранённую историю текущего персонажа?",
    POPUP_RESET_DETECTED = "WoW Chat обнаружил возможный сброс настроек Blizzard Chat.\n\nВосстановить последнюю сохранённую конфигурацию?",
    POPUP_CONFIRM_RESTORE = "Восстановить сохранённые настройки чата?\n\nПосле восстановления понадобится обычный /reload.",
    POPUP_RESTORE_RELOAD = "Настройки чата восстановлены.\n\nПерезагрузить интерфейс сейчас?",
    RESTORE = "Восстановить",
    NOT_NOW = "Не сейчас",
    YES = "Да",
    CANCEL = "Отмена",
    RELOAD_UI = "Перезагрузить интерфейс",
    LATER = "Позже",

    COPY_TITLE = "WoW Chat — копирование",
    SELECT_ALL = "Выделить всё",
    CLOSE = "Закрыть",
    CLEAN_TEXT = "Чистый текст",
    COPY_BUTTON_LABEL = "К",
    COPY_TOOLTIP = "Копировать историю чата",

    SERVICE_BACKUP_SAVED = "резервная копия настроек чата сохранена.",
    SERVICE_NO_BACKUP = "резервная копия настроек чата ещё не создана.",
    SERVICE_FIRST_BACKUP = "создана первая резервная копия настроек чата.",

    RESET_REASON_WINDOWS = "исчезли дополнительные окна чата",
    RESET_REASON_TABS = "исчезли сохранённые вкладки чата",
    RESET_REASON_FILTERS = "сбросились фильтры сообщений",
    RESET_REASON_CHANNELS = "исчезли пользовательские каналы",

    LANG_CHANGED = "режим языка установлен: %s. Выполните /reload для полной перезагрузки интерфейса.",
    LANG_CURRENT = "режим языка: %s; активная локализация: %s.",
    LANG_USAGE = "Использование: /wowchat lang auto | ruRU | enUS",
    HELP_HEADER = "команды:",
    HELP_OPEN = "/wowchat — открыть настройки",
    HELP_LANG = "/wowchat lang auto|ruRU|enUS — выбрать язык интерфейса",
}
