# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

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

Finished changes will be listed under Unreleased.

### Encoder navigation in Plug-in mode

- **Navigate the control sections with the encoder.** Start with the two icons on the left: Channel properties or Plug-ins. Proposed order:
  - Channel properties / Plug-ins.
  - Master / Group / Sound.
  - Input / Output / Groove / Macro, or the selected channel's plug-in slots.
  - Parameters of the selected section or plug-in.
- Turn to choose an item and click to enter it. In parameters, keep the usual encoder adjustment and arrow navigation; editing a value should not require another click.
- Shift + encoder click goes back one level. Keep the PLUG-IN button and arrows working as they do now, along with Shift + Erase + encoder click for removal.
- Channel properties / Plug-ins and Master / Group / Sound are independent selections in the software. The proposed sequence connects them for encoder navigation.
- Check the available transitions and current Shift-click assignments first. Mouse and button changes must also update the encoder's navigation level.

### Installation and recovery

- **Recover interrupted installs.** Add a separate recovery command for a damaged EXE when a verified original backup is available. Normal restore should continue to reject unknown files.
- **Replace the EXE through a temporary file.** Build and check it beside the installed EXE, then use a Windows file-replacement operation. Keep the original backup and allow recovery if installation or restore fails.

### Runtime reliability

- **Handle failed sample loads.** Check the sample before replacing the source or clearing zones. Catch Lua errors and show an error on the controller. Investigate undoing source changes through NI's APIs after a failed load.
- **Track pending loads by file path.** Store and recheck the selected file's path. A result-list refresh must not cause a pending click to load a different preset at the same list position.

### Verification

- **Expand the tests.** 0.2.0 includes basic installer, restore, upgrade, rejection, save-prompt and removal-shortcut tests. Add recovery tests and Lua tests for context changes, keeping FX and slot navigation. Record model tests separately from real controller and loader tests.
