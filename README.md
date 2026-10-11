# Maschine Mikro MK3 browser improvements

Spend less time reaching for the mouse. Switch browser categories and products, add effects, replace instruments or samples while keeping your FX, and answer the save prompt—all from your Mikro.

A Windows patch for **Maschine 3.7.1 x64 + Maschine Mikro MK3**. One install applies all changes.

Version **0.2.0** adds encoder control of the save prompt.

See the [changelog](CHANGELOG.md) and [planned work](CHANGELOG.md#future-development).

## Controls

| Mode | Control | Action |
|---|---|---|
| Browse | Left / Right | Previous / next file type |
| Browse | Shift + Left / Right | Previous / next product |
| Browse | Turn encoder | Scroll results |
| Browse | Shift + turn encoder | Original fast result scrolling |
| Browse, FX | Shift + encoder click | Append effect to the chain |
| Browse, Instrument / One-shot / Loop | Shift + encoder click | Load the source while retaining FX |
| Plug-in, slot selection | Turn encoder | Previous / next plug-in slot |
| Plug-in | Shift + Erase + encoder click | Remove the selected plug-in only |
| Save-changes prompt | Turn encoder | Select Cancel / Discard / Save |
| Save-changes prompt | Encoder click | Confirm the selected action on release |

The browser arrows light up when there is another item in that direction. Press Plug-in to return from parameters. Loading and removal happen when you release the encoder; the display briefly shows `ADD FX`, `KEEP FX` or `REMOVE`.

Shift-loading works with Instrument, One-shot and Loop results. One-shots and loops load into a Sampler. Browser previews play the source on its own; the loaded source plays through the Sound's FX chain.

### Native loading versus Shift-loading

An ordinary encoder click uses NI's normal loading behavior, just like loading with the mouse. If the first slot is a Sampler, another One-shot replaces the sample and keeps the FX. Loading a One-shot over an instrument such as Bass Synth replaces the chain.

Use **Shift + encoder click** to keep the FX when replacing an Instrument, One-shot or Loop, including when switching source types.

### Save-changes prompt

When Maschine asks whether to save changes, the Mikro shows `Save project?` and starts on Cancel. Turn the encoder to choose Cancel, Discard or Save, then press and release it.

For an unnamed project, Save may open a Windows filename dialog. Use the computer for that step. Missing Library, sample relocation and other message dialogs still require the computer.

## Requirements

- Windows with PowerShell 5.1 or newer.
- The supported Maschine 3.7.1 x64 build and a Maschine Mikro MK3.
- Administrator access for installation and restore.

## Installation

1. Download this repository or clone it. Keep the `patches` folder beside the scripts.
2. Close Maschine and any DAW hosting Maschine.
3. Double-click **Install.cmd** and approve Windows administrator access.
4. Wait for **All Mikro browser patches installed**, then reopen Maschine.

Run **Check.cmd** to check the installed version. **Restore.cmd** puts back the original EXE. Keep the backup beside `Maschine 3.exe`.

The default location is `C:\Program Files\Native Instruments\Maschine 3\Maschine 3.exe`. For a custom installation location, open PowerShell as administrator and run:

```powershell
.\Patch.ps1 -Target 'D:\Native Instruments\Maschine 3\Maschine 3.exe'
.\Patch.ps1 -Target 'D:\Native Instruments\Maschine 3\Maschine 3.exe' -Check
.\Patch.ps1 -Target 'D:\Native Instruments\Maschine 3\Maschine 3.exe' -Restore
```

## Compatibility and backup

The installer checks file hashes against `patches/compatibility.json`. Install directly on the supported original Maschine 3.7.1 build, or upgrade from a listed previous patch using its matching original backup. Check.cmd identifies the installed build. Other builds and third-party patches are rejected.

The original is saved as `Maschine 3.exe.browser-original-3.7.1.bak`. The installer reuses a matching backup and recognises an already installed patch. Restore.cmd restores the original EXE. A Maschine update may overwrite the patch, and each new build needs a compatibility check.

## Verification

The complete package was installed on Maschine 3.7.1 and checked with a Mikro MK3. Installer tests cover installation, checking, repeated installation, restore, upgrades and rejection of unsupported files or invalid backups. Lua tests cover save-prompt controls and the removal shortcut.

## How it works

The `patches` folder contains the custom Lua handlers. The installer reads the embedded NI code from your installed EXE and changes four Lua resources locally, preserving the file size and all other bytes. It checks the original file's SHA-256, builds and checks the result in memory, then verifies the backup and installed file. Modifying the EXE invalidates its original digital signature.

This is an unofficial community patch.

Reproducible developer checks are described in [tests/README.md](tests/README.md).

## Related project

[Maschine Companion](https://github.com/ybelonozhkin/maschine-companion) launches and closes the configured application from the controller, adds standby lighting and pauses while a configured DAW is running.
