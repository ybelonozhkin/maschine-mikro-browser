# Maschine Mikro MK3 browser improvements

An independent Windows patch for **Maschine 3.7.1 x64 + Maschine Mikro MK3**. One installation applies all improvements. No Maschine executable, firmware or original NI scripts are included.

See the [changelog](CHANGELOG.md) for current changes and
[future development](CHANGELOG.md#future-development) for planned reliability improvements.

## Installation

1. Download this repository or clone it. Keep the `patches` folder beside the scripts.
2. Close Maschine and any DAW hosting Maschine.
3. Double-click **Install.cmd** and approve Windows administrator access.
4. Wait for **All Mikro browser patches installed**, then reopen Maschine.

**Check.cmd** verifies whether the supported original or the complete patch is installed. **Restore.cmd** restores the original executable. Keep the backup created beside `Maschine 3.exe`.

The default location is `C:\Program Files\Native Instruments\Maschine 3\Maschine 3.exe`. For a custom installation location, open PowerShell as administrator and run:

```powershell
.\Patch.ps1 -Target 'D:\Native Instruments\Maschine 3\Maschine 3.exe'
.\Patch.ps1 -Target 'D:\Native Instruments\Maschine 3\Maschine 3.exe' -Check
.\Patch.ps1 -Target 'D:\Native Instruments\Maschine 3\Maschine 3.exe' -Restore
```

Requires Windows PowerShell 5.1 or newer. Python and additional downloads are not required.

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
| Plug-in | Erase + encoder click | Remove the selected plug-in only |

Browser arrows light up when navigation is available. The native Plug-in screen, icons, parameter editing and arrow navigation remain. Press Plug-in to return from parameter editing. Shift + Favorites retains its native behavior. Modified load/remove commands execute after releasing the encoder and briefly show `ADD FX`, `KEEP FX`, or `REMOVE`.

Whole Sound, Group and Project presets do not receive a custom Shift-load operation. One-shots replace the source with a Sampler. Loops first prepare a Sampler and then use NI's native loop insertion. Preview playback does not include the existing FX chain.

### Native loading versus Shift-loading

An encoder click **without Shift** keeps NI's native loading behavior; it does
not guarantee that the FX chain will be cleared. On a reinstalled, unpatched
Maschine, loading a One-shot into a multi-slot Sound whose first plug-in is
Sampler was confirmed to replace the sample in the first slot while retaining
the effects. Replacing another source, such as Bass Synth, can behave differently.
Native mouse loading follows the same distinction.

**Shift + encoder click** is the patch's explicit retain-FX operation for
Instrument, One-shot and Loop results. It also supports replacing other source
types while keeping the effects. To remove an individual effect, select its slot
in Plug-in mode and use Erase + encoder click.

## Compatibility and backup

This prototype accepts only the exact original Maschine 3.7.1 build listed in `patches/compatibility.json`, or the complete patch for checking/restoration. Unknown builds and third-party modifications are rejected. Install directly on the supported original; earlier test versions are not needed. The final executable is byte-for-byte identical to the v8 prototype build.

The backup is `Maschine 3.exe.browser-original-3.7.1.bak`. An existing matching backup is reused. Re-running installation is safe. The patch changes three embedded Lua resources without changing executable size or other bytes. Modifying the executable invalidates its original digital signature. Maschine updates may overwrite the patch; new builds need separate compatibility verification.

No firmware, library content, project files or activation data are modified. Test new workflows on a spare Sound first.

## Verification

The patcher verifies the original SHA-256, constructs the result in memory, verifies its expected SHA-256, backs up the original and verifies the installed file. Install/check/reinstall/restore were tested on a local copy of the original executable. The complete package was also installed directly over a reinstalled original Maschine 3.7.1, and the user confirmed operation with a Mikro MK3. Model tests do not replace native-loader and hardware testing across other setups.

The `patches` directory contains only our custom Lua handlers. Existing NI code is read and transformed locally during installation. This is an independent community modification, not an official Native Instruments update.
