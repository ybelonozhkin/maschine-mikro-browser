#include <windows.h>
#include <stdio.h>
static int received=0;
static LRESULT CALLBACK WndProc(HWND h,UINT msg,WPARAM w,LPARAM l) {
    if(msg==RegisterWindowMessageW(L"MaschineMikroBrowser.GuiBridge.Probe.1"))++received;
    return DefWindowProcW(h,msg,w,l);
}
int wmain() {
    WNDCLASSW c{};c.lpfnWndProc=WndProc;c.hInstance=GetModuleHandleW(nullptr);c.lpszClassName=L"BridgeTestHost";
    RegisterClassW(&c);HWND h=CreateWindowW(c.lpszClassName,L"",0,0,0,0,0,HWND_MESSAGE,nullptr,c.hInstance,nullptr);
    HMODULE dll=LoadLibraryW(L"bridge-test.dll");if(!dll||!h)return 1;
    auto init=reinterpret_cast<bool(*)(HWND)>(GetProcAddress(dll,"BridgeInitializeTest"));
    auto request=reinterpret_cast<int(*)(void*)>(GetProcAddress(dll,"BridgeRequestTypes"));
    auto count=reinterpret_cast<unsigned(*)()>(GetProcAddress(dll,"BridgeProbeCountTest"));
    if(!init||!request||!count||!init(h))return 2;
    HANDLE worker=CreateThread(nullptr,0,[](void* p)->DWORD {reinterpret_cast<int(*)(void*)>(p)(nullptr);return 0;},reinterpret_cast<void*>(request),0,nullptr);
    WaitForSingleObject(worker,5000);CloseHandle(worker);
    DWORD start=GetTickCount();MSG m;
    while(GetTickCount()-start<1000) {while(PeekMessageW(&m,nullptr,0,0,PM_REMOVE)){TranslateMessage(&m);DispatchMessageW(&m);}Sleep(1);}
    if(received||count()!=1)return 3; // Hook must handle exactly one request.
    DestroyWindow(h);request(nullptr); // Rejected after target destruction.
    if(count()!=1)return 4;
    puts("Probe completed; inspect bridge.log for worker/GUI thread IDs and rejection.");return 0;
}
