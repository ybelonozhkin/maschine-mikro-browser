# Developer checks

Supply the supported original EXE. The installer tests use copies of it and an isolated ProgramData directory; close Maschine before running them.

```powershell
.\tests\Test-Patcher.ps1 -OriginalExe 'D:\private\Maschine 3.original.exe'
```

Supply `-PreviousExe` with a listed earlier patch to check upgrades. `-WorkDirectory` must name a new directory. The tests retain their copies for inspection. They cover installation, checking, repeated installation, damaged-runtime detection and repair, restoration, upgrades, invalid backups and unsupported EXEs.

Lua model tests use Python and `lupa` with Lua 5.1:

```powershell
python -m pip install lupa
python tests\test_controls.py
python tests\test_navigation.py
python tests\test_load_gesture.py
python tests\test_package.py
```

The navigation models cover tag selection and back/forward routes, subtype transitions, toggle-off, resource-arrow aliases, product navigation and LED boundaries. Their fixtures contain mocked NI interfaces. Hardware tests are recorded separately from these models.

Build the production DLL and run the native test hosts with MSVC x64 and the Windows SDK:

```cmd
Build-Bridge.cmd test
```

The hosts check worker-to-GUI message delivery, consumption of private commands, target destruction, native-adapter expansion, repeated requests and owner invalidation. The fake objects verify the adapter's contract; actual NI object behavior is checked in Maschine.

Rebuilding changes the DLL's release hash. Update its entry in `patches/compatibility.json` before testing the installer with that binary. Keep the current manifest matched to the packaged files.
