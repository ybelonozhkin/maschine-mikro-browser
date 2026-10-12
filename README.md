# Maschine Mikro MK3 browser improvements

A Windows patch for **Maschine 3.7.1 x64 + Maschine Mikro MK3**.

Pick an instrument, narrow it down with tags, load a preset, then get straight into its plug-ins and settings. All from the Mikro. Swap a sample without losing your FX, add another effect, or move between Sound, Group and Master with the encoder.

Use the encoder to choose and enter items, and Shift-click to go back. The Mikro shows your current selection, and the computer view updates as you turn.

Pair it with [Maschine Companion](https://github.com/ybelonozhkin/maschine-companion) to launch and close Maschine from the controller too.

Version **0.3.0** adds encoder navigation through tags, channel levels and Channel properties. See the [changelog](CHANGELOG.md).

## Controls

| Mode | Control | Action |
|---|---|---|
| Browse, results or tags | Left / Right | Previous / next file type; returns to results |
| Browse, results or tags | Shift + Left / Right | Previous / next product; returns to results |
| Browse, results | Shift + encoder click | Open Characters, or the deepest available Type level |
| Browse, tags | Turn encoder | Select a tag and update the software filter |
| Browse, tags | Encoder click | Confirm the tag and move to the next level; Characters returns to results |
| Browse, tags | Shift + encoder click | Go back toward Types |
| Browse, FX results | Shift + Lock + encoder click | Append an effect to the selected channel's chain |
| Browse, Instrument / One-shot / Loop results | Shift + Lock + encoder click | Replace the Sound's source while keeping FX |
| Plug-in navigation menus | Turn encoder or Left / Right | Choose an item at the current level |
| Plug-in navigation menus | Encoder click | Enter the selected item |
| Plug-in / Channel properties | Shift + encoder click | Go back one level |
| Plug-in | Shift + Erase + encoder click | Remove the selected plug-in |
| Save-changes prompt | Turn encoder | Select Cancel / Discard / Save |
| Save-changes prompt | Encoder click | Confirm on release |

In Browse and the navigation menus, arrows light up when you can move in that direction. The load and remove shortcuts take effect when you release the encoder. The display briefly shows `ADD FX`, `KEEP FX` or `REMOVE`.

### Tags

Press Browse to reach the results, then Shift-click the encoder to enter the tags. The Mikro shows the section and tag name. Turning the encoder selects a tag and updates the filter and results on the computer.

Shift-click goes back through the available Type levels. Click a Type to move into its subtypes, then Characters where available. Click a Character to return to the results. To clear your selected Character, return to Characters and click that entry again.

Projects, Groups and Sounds have up to three Type levels. Instrument and effect presets, Loops and One-shots use Types, subtypes and a separate Characters section. Entering Types or Characters from the controller opens its list on the computer.

`All` is the first entry, before the tags. It appears only on the Mikro display, not in the computer interface. Turn to `All` to clear the filter for that level, then click to continue. At the last level, clicking returns to results.

Left / Right switches file types from both results and tags. Shift + Left / Right switches products. Either action leaves the tag menu and returns to the results for the new selection.

### Plug-ins and Channel properties

Press Plug-in, then Shift-click the encoder to move up from the current screen. The navigation levels are:

- **Plug-ins:** Master / Group / Sound → plug-in slots → parameters.
- **Channel properties:** Master / Group / Sound → Input / Output / Groove / Macro → parameters.

At the top, choose between Plug-ins and Channel properties. Turn or use the arrows to choose an item, click to enter, and Shift-click to go back. The computer view follows your menu selection. In parameter screens, use the arrows to select a parameter and turn the encoder to adjust its value.

After opening Groove with Variation, Shift-click returns to the Channel properties navigation.

### Loading while keeping FX

Hold **Shift + Lock**, then press and release the encoder. An FX preset goes at the end of the selected Sound, Group or Master chain. An Instrument, One-shot or Loop replaces the Sound's source and keeps its effects. One-shots and loops load into a Sampler.

An ordinary encoder click uses NI's normal loading behavior, just like loading with the mouse. If the first slot is a Sampler, another One-shot replaces the sample and keeps the FX. Loading a One-shot over an instrument such as Bass Synth replaces the chain.

The loaded source plays through your Sound's existing FX, so it can sound different from the browser preview.

### Save-changes prompt

When Maschine asks whether to save changes, the Mikro shows `Save project?` and starts on Cancel. Turn to choose Cancel, Discard or Save, then press and release the encoder.

For an unnamed project, Save may open a Windows filename dialog. Use the computer for that step. Missing Library, sample relocation and other message dialogs require the computer.

## Requirements

- Windows with PowerShell 5.1 or newer.
- The supported Maschine 3.7.1 x64 build running standalone, and a Maschine Mikro MK3.
- Administrator access for installation and restore.

## Installation

1. Download this repository or clone it. Keep `patches` and `runtime` beside the scripts.
2. Close Maschine and any DAW hosting Maschine.
3. Double-click **Install.cmd** and approve Windows administrator access.
4. Wait for **All Mikro browser patches installed**, then reopen Maschine.

The package includes the compiled DLL. The installer copies the Lua files and DLL to `%PROGRAMDATA%\MaschineMikroBrowser\0.3.0` and patches the EXE. Once installation succeeds, you can move or remove the downloaded repository.

Run **Check.cmd** to verify the EXE and installed runtime files. Running **Install.cmd** again restores the release's runtime files. **Restore.cmd** puts back the original EXE; keep its backup beside `Maschine 3.exe`.

The default location is `C:\Program Files\Native Instruments\Maschine 3\Maschine 3.exe`. For a custom installation, open PowerShell as administrator and run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Patch.ps1 -Target 'D:\Native Instruments\Maschine 3\Maschine 3.exe'
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Patch.ps1 -Target 'D:\Native Instruments\Maschine 3\Maschine 3.exe' -Check
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Patch.ps1 -Target 'D:\Native Instruments\Maschine 3\Maschine 3.exe' -Restore
```

### Compatibility and backup

The installer checks file hashes against `patches/compatibility.json`. It supports the verified original Maschine 3.7.1 build and upgrades from the listed previous patches using a matching original backup. Each Maschine build needs its own compatibility check.

The original is saved as `Maschine 3.exe.browser-original-3.7.1.bak`. The installer reuses a matching backup. Restore.cmd restores that original; the versioned runtime folder remains available for reinstalling. A Maschine update may overwrite the patch.

## How it works

The installer updates the controller's Lua scripts stored inside `Maschine 3.exe` and adds a loader for the Lua files installed in ProgramData. The scripts use Maschine's own search, filtering and loading functions.

The modified EXE no longer passes verification of Native Instruments’ digital signature. Restoring the original EXE restores its signature.

The DLL uses NI's own interface code to open Types and Characters on the computer. It runs those calls on Maschine's interface thread and checks the code and browser objects it uses. The bridge is built for the supported Maschine 3.7.1 build.

Logs are stored in `%LOCALAPPDATA%\MaschineMikroBrowser`. This is an unofficial community patch.

## For developers

### Building the DLL

The release includes a ready-to-use DLL. If you want to inspect or change the bridge, its C++ source is in `native` and you can build your own copy. MinHook v1.3.4 and its license are included.

Install Visual Studio Build Tools with the C++ x64 compiler and Windows SDK, then run:

```cmd
Build-Bridge.cmd
```

This builds `runtime\maschine-browser-bridge.dll`. A rebuilt binary may have a different hash; update `runtime_files` in `patches/compatibility.json` when preparing your own package.

### Licenses

The bridge and our scripts use the project's [MIT license](LICENSE). MinHook and its HDE components use BSD licenses. When distributing the DLL, include the project's LICENSE and [THIRD-PARTY-NOTICES.txt](runtime/THIRD-PARTY-NOTICES.txt). Source is included so you can inspect, modify and rebuild the bridge.

### Verification

Controller navigation was tested with a Mikro MK3 on Maschine 3.7.1 standalone. The release package was installed and checked in Maschine. Installer tests cover installation, file checks, reinstalling, runtime repair, restore, upgrades and rejected files. Lua tests check syntax and control routing. Native test hosts check GUI message delivery and the expansion adapter using mock browser objects. See [tests/README.md](tests/README.md) to run the checks.
