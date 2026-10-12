# Native tag expansion bridge

The Lua loader loads the packaged x64 DLL into Maschine and submits Types/Characters expansion requests. The DLL posts a private window message to the unique visible unowned captioned window in its own process. A WH_GETMESSAGE hook handles and consumes that message on the window's GUI thread.

For the verified Maschine 3.7.1 build, MinHook observes BrowserWidget's timer and scalar deleting destructor. The timer captures the GUI-owned object; destruction removes it. A request requires a unique recently observed owner, the expected vtables, column and caption. Function fingerprints are checked before installing the hooks. The native caption callback performs the complete transition, including dependent subtype layout. AttributesTagView+0x4c8 is the collapsed flag: 1 closed, 0 open. An already expanded section stays open.

The DLL remains loaded until process exit. Requests without a valid unique owner are skipped. Other Maschine versions and hosted or multiple-window configurations need separate validation. Logs are written to the user's LocalAppData directory.

Run `Build-Bridge.cmd` from the repository root to build the production DLL, or `Build-Bridge.cmd test` to also build and run the mock native hosts. The compiler target is x64, with the CRT linked statically. Test-only exports are enabled by BRIDGE_TESTS.

MinHook v1.3.4 is vendored from https://github.com/TsudaKageyu/minhook at commit c3fcafdc10146beb5919319d0683e44e3c30d537. Its full license, including HDE notices, is in minhook/LICENSE.txt and the installed THIRD-PARTY-NOTICES.txt. Project-owned source is covered by the root MIT LICENSE.
