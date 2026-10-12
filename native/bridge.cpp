#include <windows.h>
#include <stdio.h>
#include <atomic>

static HMODULE moduleHandle;
static HHOOK guiHook;
static HWND mainWindow;
static DWORD guiThread;
static UINT requestMessage;
static std::atomic<unsigned> sequence{0};
static std::atomic<bool> ready{false};
static std::atomic<unsigned> probeCount{0};
static SRWLOCK logLock=SRWLOCK_INIT;
static wchar_t logPath[MAX_PATH];
#ifdef NATIVE_EXPAND
static bool InstallNativeHooks();
static void ExpandRequested(unsigned op);
#endif

static void Log(const char* event,unsigned seq=0,unsigned op=0) {
    AcquireSRWLockExclusive(&logLock);
    HANDLE f=CreateFileW(logPath,FILE_APPEND_DATA,FILE_SHARE_READ|FILE_SHARE_WRITE,nullptr,OPEN_ALWAYS,FILE_ATTRIBUTE_NORMAL,nullptr);
    if(f!=INVALID_HANDLE_VALUE) {
        LARGE_INTEGER size;
        if(GetFileSizeEx(f,&size)&&size.QuadPart>262144) {CloseHandle(f);f=CreateFileW(logPath,GENERIC_WRITE,FILE_SHARE_READ,nullptr,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,nullptr);}
        if(f!=INVALID_HANDLE_VALUE) {
            char line[240];int n=sprintf_s(line,"%s pid=%lu tid=%lu gui=%lu seq=%u op=%u\r\n",event,GetCurrentProcessId(),GetCurrentThreadId(),guiThread,seq,op);
            DWORD written;WriteFile(f,line,n,&written,nullptr);CloseHandle(f);
        }
    }
    ReleaseSRWLockExclusive(&logLock);
}
static bool ValidWindow() {
    DWORD pid=0;
    return IsWindow(mainWindow)&&GetWindowThreadProcessId(mainWindow,&pid)==guiThread&&pid==GetCurrentProcessId();
}
static LRESULT CALLBACK OnGuiMessage(int code,WPARAM w,LPARAM l) {
    if(code>=0&&w==PM_REMOVE&&ready.load(std::memory_order_acquire)) {
        MSG* m=reinterpret_cast<MSG*>(l);
        if(m->message==requestMessage&&m->hwnd==mainWindow) {
            const unsigned seq=static_cast<unsigned>(m->wParam),op=static_cast<unsigned>(m->lParam);
            bool valid=ValidWindow()&&GetCurrentThreadId()==guiThread;
            if(valid)++probeCount;
            Log(valid?"GUI_PROBE":"GUI_REJECT",seq,op);
#ifdef NATIVE_EXPAND
            if(valid&&op)ExpandRequested(op);
#endif
            // Consume only this bridge command; normal window messages continue unchanged.
            m->message=WM_NULL;m->wParam=0;m->lParam=0;
        }
    }
    return CallNextHookEx(nullptr,code,w,l);
}
static bool PrepareLogPath() {
    wchar_t local[MAX_PATH];
    DWORD n=GetEnvironmentVariableW(L"LOCALAPPDATA",local,MAX_PATH);
    if(!n||n>=MAX_PATH)return false;
    if(swprintf_s(logPath,L"%ls\\MaschineMikroBrowser",local)<0)return false;
    CreateDirectoryW(logPath,nullptr);
    return wcscat_s(logPath,L"\\bridge.log")==0;
}
static bool Initialize(HWND window) {
    if(guiHook)return ValidWindow();
    if(!PrepareLogPath())return false;
    DWORD pid=0;guiThread=GetWindowThreadProcessId(window,&pid);
    if(!guiThread||pid!=GetCurrentProcessId())return false;
    mainWindow=window;requestMessage=RegisterWindowMessageW(L"MaschineMikroBrowser.GuiBridge.Probe.1");
    if(!requestMessage)return false;
    HMODULE pinned;
    if(!GetModuleHandleExW(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS|GET_MODULE_HANDLE_EX_FLAG_PIN,reinterpret_cast<LPCWSTR>(&Initialize),&pinned))return false;
    guiHook=SetWindowsHookExW(WH_GETMESSAGE,OnGuiMessage,moduleHandle,guiThread);
    ready.store(guiHook!=nullptr,std::memory_order_release);
#ifdef NATIVE_EXPAND
    if(guiHook)InstallNativeHooks();
#endif
    Log(guiHook?"INITIALIZED":"HOOK_FAILED");return guiHook!=nullptr;
}
static BOOL CALLBACK FindWindow(HWND h,LPARAM data) {
    DWORD pid=0;GetWindowThreadProcessId(h,&pid);
    if(pid==GetCurrentProcessId()&&IsWindowVisible(h)&&!GetWindow(h,GW_OWNER)&&(GetWindowLongPtrW(h,GWL_STYLE)&WS_CAPTION)) {
        HWND* found=reinterpret_cast<HWND*>(data);
        if(*found){*found=reinterpret_cast<HWND>(-1);return FALSE;}
        *found=h;
    }
    return TRUE;
}
static void Request(unsigned op) {
    if(!ready.load(std::memory_order_acquire)||!ValidWindow()){Log("REQUEST_REJECT",0,op);return;}
    const unsigned seq=++sequence;
    Log("REQUEST",seq,op);
    if(!PostMessageW(mainWindow,requestMessage,seq,op))Log("POST_FAILED",seq,op);
}
// Lua C-function ABI; these functions return no Lua values and never use Lua internals.
extern "C" __declspec(dllexport) int BridgeInitialize(void*) {
    if(!PrepareLogPath())return 0;
    HWND found=nullptr;EnumWindows(FindWindow,reinterpret_cast<LPARAM>(&found));
    if(found&&found!=reinterpret_cast<HWND>(-1)&&Initialize(found))Request(0);
    else Log("WINDOW_OR_INIT_REJECT");
    return 0;
}
extern "C" __declspec(dllexport) int BridgeRequestTypes(void*) {Request(1);return 0;}
extern "C" __declspec(dllexport) int BridgeRequestCharacters(void*) {Request(2);return 0;}
#ifdef NATIVE_EXPAND
extern "C" __declspec(dllexport) int BridgeEnableExpansion(void*) {Request(100);return 0;}
extern "C" __declspec(dllexport) LRESULT CALLBACK BridgeBootstrapHook(int code,WPARAM w,LPARAM l) {
    if(code>=0&&!ready.load(std::memory_order_acquire))BridgeInitialize(nullptr);
    return CallNextHookEx(nullptr,code,w,l);
}
#endif
#ifdef BRIDGE_TESTS
extern "C" __declspec(dllexport) bool BridgeInitializeTest(HWND h){return Initialize(h);}
extern "C" __declspec(dllexport) unsigned BridgeProbeCountTest(){return probeCount.load();}
#endif
BOOL WINAPI DllMain(HINSTANCE h,DWORD reason,LPVOID) {
    if(reason==DLL_PROCESS_ATTACH){moduleHandle=h;DisableThreadLibraryCalls(h);}
    return TRUE;
}
#ifdef NATIVE_EXPAND
#include "native.cpp"
#endif
