# WoW Chat v1.0.1

Maintenance release for World of Warcraft Legion 7.3.5 (Interface 70300).

## Changes

- Fixed long-history selection drift/truncation in the copy window. Runtime isolation showed that inline texture escapes (`|T...|t`) trigger the Legion 7.3.5 multiline EditBox selection failure.
- The copy window now omits inline texture/icon escapes while preserving colors and hyperlinks. Saved history remains unchanged.
- Supported history range is now **200–2000 lines**.
- Default and recommended history size is now **1000 lines**.
- Older saved values above 2000 are capped to 2000.

## Validation

- Plain, color-only, nested color/reset and hyperlink-only 2000-line controls passed.
- Texture-rich 2000-line controls reproduced the selection failure.
- Texture-stripped 2000-line control passed through the final row.
- A production-path 1000-line test with colored text and a real inline texture every 10th line passed: icons remained in the normal chat, were omitted from the copy window, colors were preserved, and Ctrl+A remained aligned through row 1000.
- A 5000-line texture-stripped stress test made the Legion client non-responsive for more than two minutes, so 5000 is no longer supported.

## Installation

Extract the `WoW_Chat` folder from `WoW_Chat_v1.0.1.zip` into `World of Warcraft/Interface/AddOns/`. Do not delete WTF or SavedVariables when updating.

---

# WoW Chat v1.0.1

Техническое обновление для World of Warcraft Legion 7.3.5 (Interface 70300).

## Изменения

- Исправлен накопительный сдвиг и обрыв выделения длинной истории в окне копирования. Игровая изоляция показала, что сбой multiline EditBox в Legion 7.3.5 вызывают inline-текстуры (`|T...|t`).
- Окно копирования теперь убирает inline-текстуры/иконки, сохраняя цвета и гиперссылки. Сама сохранённая история не переписывается.
- Допустимый диапазон истории теперь **200–2000 строк**.
- Значение по умолчанию и рекомендация теперь **1000 строк**.
- Старые сохранённые значения выше 2000 ограничиваются до 2000.

## Проверка

- PLAIN, COLOR, RESET и LINKS на 2000 строк прошли.
- TEXTURE/FULL на 2000 строк воспроизвели обрыв выделения.
- FIXED без texture-тегов на 2000 строк прошёл до последней строки.
- Production-проверка на 1000 цветных строк с реальной inline-текстурой в каждой десятой строке прошла: иконки остались в обычном чате, исчезли только в окне копирования, цвет сохранился, Ctrl+A дошёл до строки 1000.
- Stress-тест на 5000 строк без texture-тегов сделал клиент Legion неотзывчивым более чем на две минуты, поэтому 5000 больше не поддерживается.

## Установка

Распакуйте папку `WoW_Chat` из `WoW_Chat_v1.0.1.zip` в `World of Warcraft/Interface/AddOns/`. При обновлении не удаляйте WTF или SavedVariables.

