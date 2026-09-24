# WoW Chat v1.0.0

First stable release for World of Warcraft Legion 7.3.5 (Interface 70300).

## Changes since v0.9.1

- Stabilized copy-window layout before it becomes visible, fixing intermittent selection misalignment with long histories.
- The copy window opens at the newest saved messages.
- Added a Current value indicator for saved-history size and preserved it after `/reload`.
- Improved the English Chat settings backup description layout.

History range: 200–5000 lines; default and recommended value: 2000.

Tested on the UWoW 7.3.5 client. Extract `WoW_Chat` from `WoW_Chat_v1.0.0.zip` into `World of Warcraft/Interface/AddOns/`; do not delete WTF or SavedVariables when updating.

---

Первая стабильная версия для World of Warcraft Legion 7.3.5 (Interface 70300).

## Изменения относительно v0.9.1

- Стабилизирована геометрия окна копирования до показа, что исправляет редкий визуальный сдвиг выделения при длинной истории.
- Окно копирования открывается на самых новых сообщениях.
- Добавлен индикатор текущего значения сохраняемой истории, работающий после `/reload`.
- Исправлена компоновка английского описания резервирования настроек.

Диапазон истории: 200–5000 строк; значение по умолчанию и рекомендация: 2000.
