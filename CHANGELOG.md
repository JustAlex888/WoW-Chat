# Changelog

## v1.0.1

- Fixed long-history selection drift/truncation caused by inline `|T...|t` texture escapes in Legion 7.3.5 multiline EditBox content.
- The copy window now omits inline texture/icon escapes while preserving message colors and hyperlinks; saved history itself is unchanged.
- Reduced the supported saved-history range to 200–2000 lines after runtime performance testing.
- Changed the default and recommended history size to 1000 lines.
- Older saved settings above 2000 are capped to 2000.

## v1.0.0

- First stable release for Legion 7.3.5 (Interface 70300).
- Stabilized long-history copy-window layout and opened it at newest messages.
- Added the saved-history Current value indicator.
- Improved English backup-description layout.

## v0.9.1

- Renamed the addon folder to `WoW_Chat`.
- Added full Russian and English localization.
- Added language override commands for localization testing.
- Added compact version and developer information to the settings panel.
- Improved long-text selection and copy-window interaction.
- Restricted selection auto-scroll to left-button drag started inside the text area.
- Added per-character Blizzard Chat settings backup and restore.
- Prepared the project for public GitHub pre-release testing.

## v0.9.0

- First full pre-release testing build.
- Persistent chat history.
- Colored copy window.
- Clean text mode.
- Character-specific history storage.
- Blizzard Chat settings backup foundation.

