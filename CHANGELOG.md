# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [0.3.0] - 2026-10-12

Navigate tags, plug-ins and channel settings with the Mikro's encoder.

### Added

- Tag navigation: Shift-click from results opens Characters or the deepest available Type level. Turn to select a tag, click to continue, and Shift-click to go back.
- Left / Right switches file types from anywhere in Browse, including tag navigation. Shift + Left / Right switches products. Either action leaves the tag menu and returns to results.
- Automatic expansion of desktop Types and Characters through a native GUI bridge, with C++ source, a build script and the compiled DLL included.
- Encoder selection of Master, Group and Sound in Plug-in mode, with Shift-click to go back from parameters and slot lists.
- Encoder navigation through Channel properties: Master, Group and Sound, then Input, Output, Groove and Macro. Shift-click returns from each section, including Groove opened with Variation.
- The encoder and arrows choose items at the same level in the new navigation menus. Choices update the software view; arrow lights show the available directions.
- Versioned runtime installation, SHA-256 checks for the installed Lua files and DLL, and runtime repair by reinstalling.

### Changed

- Keeping FX while replacing a source or appending an effect now uses Shift + Lock + encoder click. Shift-click in Browse opens tags or moves back through them.

## [0.2.0] - 2026-10-11

Choose an action in the save prompt directly from the Mikro.

### Added

- Save-prompt controls: turn the encoder to choose Cancel, Discard or Save on the Mikro display, then press and release to confirm. Cancel is selected by default.
- Upgrade support for 0.1.0 and the listed save-dialog prototypes.
- Developer tests for installation, restore, upgrades, rejected files, save-prompt controls and the plug-in removal shortcut.

### Changed

- Removing a plug-in now requires Shift + Erase + encoder click.
- Reorganised the English README around requirements, installation and controls, and removed the Russian README.

### Fixed

- The installer rechecks the EXE under an exclusive lock before writing, and verifies a new backup before changing the original.

## [0.1.0] - 2026-10-10

### Added

- Initial release. See the [README](README.md) for features, installation and controls.

## Future development

Planned work is listed below.

### VST support

- **Support Maschine running as a VST in a DAW.** Check the plug-in's Lua resources and adapt the native bridge to its browser window and host process. Test navigation and loading in the hosted configuration.

### Playback and event navigation

- **Move the playhead with the encoder (needle jump).** Seek to a position in the current pattern or song from the controller. Decide the scope, step size and controls during implementation.
- **Select individual events with the encoder.** Move between events in the focused Sound's pattern and select a specific event for editing. Decide the event order and controls during implementation.

### Installation and recovery

- **Recover interrupted installs.** Add a separate recovery command for a damaged EXE when a verified original backup is available. Normal restore should continue to reject unknown files.
- **Replace the EXE through a temporary file.** Build and check it beside the installed EXE, then use a Windows file-replacement operation. Keep the original backup and allow recovery if installation or restore fails.

### Runtime reliability

- **Handle failed sample loads.** Check the sample before replacing the source or clearing zones. Catch Lua errors and show an error on the controller. Investigate undoing source changes through NI's APIs after a failed load.
- **Track pending loads by file path.** Store and recheck the selected file's path. A result-list refresh must not cause a pending click to load a different preset at the same list position.

### Verification

- **Expand the tests.** Add recovery and failed-load checks, and record controller tests separately from Lua models. Check native bridge compatibility when Maschine updates.
