# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [0.2.0] - 2026-10-11

Choose an action in the save prompt directly from the Mikro.

### Added

- Turn the encoder to choose Cancel, Discard or Save. The selected action appears on the Mikro display.
- Press and release the encoder to confirm through Maschine's built-in save command.
- The save prompt starts on Cancel. Scrolling stops at either end, and a click confirms only once. Closing the prompt with the mouse also clears it on the controller.
- Install all changes at once on the supported original EXE, or upgrade from a supported 0.1.0 or save-dialog prototype build.
- Developer tests for installation, restore, upgrades, rejected files, save-prompt controls and the plug-in removal shortcut.

### Changed

- Removing a plug-in now requires Shift + Erase + encoder click.
- Reorganised the English README around requirements, installation and controls, and removed the Russian README.

### Fixed

- Turning or clicking the encoder in the save prompt no longer scrolls or loads items in the browser behind it.
- The installer locks and rechecks the EXE before writing, and verifies a new backup before changing the original.

Cancel, Discard and Save were tested on a Mikro MK3. Save may open a Windows filename dialog; use the computer for that step. Missing Library and missing-sample prompts still require the computer.

## [0.1.0] - 2026-10-10

### Added

- Browse file-type navigation with Left / Right.
- Browse product navigation with Shift + Left / Right.
- Arrow buttons light up when there is another item in that direction.
- Shift + encoder click to append an FX preset to the current plug-in chain.
- Shift + encoder click to load an Instrument, One-shot, or Loop while retaining FX.
- Erase + encoder click in Plug-in mode to remove only the selected plug-in.
- Encoder rotation to select plug-in slots when parameter editing is closed.
- The display briefly shows ADD FX, KEEP FX or REMOVE after these actions.
- One PowerShell script installs all changes on the supported original Maschine 3.7.1 x64 EXE.
- Installation, compatibility checking, and restoration launchers.
- SHA-256 checks for the original executable, generated patch, installed file, and restoration backup.
- Backup reuse and detection of an already installed patch.
- Support for custom executable paths through the `-Target` parameter.
- English and Russian installation instructions.
- Documentation of native One-shot loading into Sampler: ordinary loading can retain FX, while Shift-loading explicitly retains FX across source types.
- The package contains custom Lua handlers, but no Maschine EXE or original NI scripts.

### Fixed

- Product selection now runs the browser cache timer needed to apply the change.
- Restored native fast result scrolling with Shift + encoder rotation after an early prototype assigned that combination to product selection.
- Shift-loading a One-shot now replaces the source through Sampler-specific operations, preserving FX when replacing sources such as Bass Synth.
- Loop loading now prepares a Sampler before native loop insertion, preserving FX when replacing sources such as Bass Synth.
- Installation no longer rejects unrelated drivers or services merely because their process names contain "Maschine".
- Installation and restoration ignore exited Maschine processes that remain visible in the Windows process list.

## Future development

Planned work; no release dates are set. Finished changes will be listed under Unreleased.

### Encoder navigation in Plug-in mode

- **Navigate the control sections with the encoder.** Start with the two icons on the left: Channel properties or Plug-ins. Proposed order:
  - Channel properties / Plug-ins.
  - Master / Group / Sound.
  - Input / Output / Groove / Macro, or the selected channel's plug-in slots.
  - Parameters of the selected section or plug-in.
- Turn to choose an item and click to enter it. In parameters, keep the usual encoder adjustment and arrow navigation; editing a value should not require another click.
- Shift + encoder click goes back one level. Keep the PLUG-IN button and arrows working as they do now, along with Shift + Erase + encoder click for removal.
- Channel properties / Plug-ins and Master / Group / Sound are independent selections in the software. This proposed sequence adds a way to navigate them; it is not an existing Maschine or Komplete convention.
- Check the available transitions and current Shift-click assignments first. Mouse and button changes must also update the encoder's navigation level.

### Installation and recovery

- **Recover interrupted installs.** Add a separate recovery command for a damaged EXE when a verified original backup is available. Normal restore should continue to reject unknown files.
- **Replace the EXE through a temporary file.** Build and check it beside the installed EXE, then use a Windows file-replacement operation. Keep the original backup and allow recovery if installation or restore fails.

### Runtime reliability

- **Handle failed sample loads.** Check the sample before replacing the source or clearing zones. Catch Lua errors and show an error on the controller. Check whether NI's APIs can undo source changes after a failed load; the patch does not currently guarantee that.
- **Track pending loads by file path.** Store and recheck the selected file's path. A result-list refresh must not cause a pending click to load a different preset at the same list position.

### Verification

- **Expand the tests.** 0.2.0 includes basic installer, restore, upgrade, rejection, save-prompt and removal-shortcut tests. Add recovery tests and Lua tests for context changes, keeping FX and slot navigation. Record model tests separately from real controller and loader tests.
