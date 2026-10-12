#include <windows.h>
#include <stdio.h>
#include <stdint.h>
static DWORD gui;static unsigned calls;
static unsigned char root[0x700]{},tags[3][0x500]{};
static void __fastcall Caption(void* c,const void*) {
    if(GetCurrentThreadId()!=gui)ExitProcess(90);
    void* r=reinterpret_cast<void**>(c)[1];size_t i=reinterpret_cast<size_t*>(c)[2];
    void* t=*reinterpret_cast<void**>(reinterpret_cast<unsigned char*>(r)+0x498+i*16);
    reinterpret_cast<unsigned char*>(t)[0x4c8]=0;++calls;
}
static LRESULT CALLBACK Proc(HWND h,UINT m,WPARAM w,LPARAM l){return DefWindowProcW(h,m,w,l);}
static void Pump(){DWORD s=GetTickCount();MSG m;while(GetTickCount()-s<100){while(PeekMessageW(&m,nullptr,0,0,PM_REMOVE)){TranslateMessage(&m);DispatchMessageW(&m);}Sleep(1);}}
int wmain(){
    gui=GetCurrentThreadId();WNDCLASSW wc{};wc.hInstance=GetModuleHandleW(nullptr);wc.lpfnWndProc=Proc;wc.lpszClassName=L"NativeBridgeTest";RegisterClassW(&wc);
    HWND h=CreateWindowW(wc.lpszClassName,L"",0,0,0,0,0,HWND_MESSAGE,nullptr,wc.hInstance,nullptr);
    HMODULE d=LoadLibraryW(L"bridge-native-test.dll");if(!d)return 1;
    auto init=reinterpret_cast<bool(*)(HWND)>(GetProcAddress(d,"BridgeInitializeTest"));
    auto bind=reinterpret_cast<void(*)(void*,uintptr_t,uintptr_t,decltype(&Caption))>(GetProcAddress(d,"BridgeBindNativeTest"));
    auto forget=reinterpret_cast<void(*)(void*)>(GetProcAddress(d,"BridgeForgetNativeTest"));
    auto type=reinterpret_cast<int(*)(void*)>(GetProcAddress(d,"BridgeRequestTypes"));
    auto character=reinterpret_cast<int(*)(void*)>(GetProcAddress(d,"BridgeRequestCharacters"));
    if(!init||!bind||!forget||!type||!character||!init(h))return 2;
    *reinterpret_cast<uintptr_t*>(root)=0x1111;
    for(unsigned i=0;i<3;++i){*reinterpret_cast<uintptr_t*>(tags[i])=0x2222;*reinterpret_cast<unsigned*>(tags[i]+0x470)=i;*reinterpret_cast<void**>(tags[i]+0x488)=tags[i];*reinterpret_cast<void**>(root+0x498+i*16)=tags[i];tags[i][0x4c8]=1;}
    bind(root,0x1111,0x2222,Caption);
    type(nullptr);Pump();if(calls!=1||tags[0][0x4c8])return 3;
    type(nullptr);Pump();if(calls!=1)return 4;
    character(nullptr);Pump();if(calls!=2||tags[2][0x4c8])return 5;
    forget(root);type(nullptr);Pump();if(calls!=2)return 6;
    DestroyWindow(h);puts("PASS GUI native adapter, single expansion, already-expanded no-op, Characters and destroyed-owner rejection");return 0;
}
