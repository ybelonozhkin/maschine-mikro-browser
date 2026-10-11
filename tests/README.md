# Developer checks

Close Maschine before running integration checks. Supply your own supported original EXE; the tests work on copies in a separate directory.

```powershell
.\tests\Test-Patcher.ps1 -OriginalExe 'D:\private\Maschine 3.original.exe'
```

Optionally supply `-PreviousExe` with a supported 0.1.0 or save-dialog prototype to test upgrading. `-WorkDirectory` must name a new directory. Copies are retained there for inspection. Checks cover installation, checking, repeated installation, restoration, upgrades, invalid backup rejection and unsupported EXE rejection.

Lua development checks use Python and `lupa`:

```powershell
python -m pip install lupa
python tests\test_controls.py
```

These model checks validate routing and guards. Physical Save/Cancel/Discard behavior was tested separately on Mikro MK3.
