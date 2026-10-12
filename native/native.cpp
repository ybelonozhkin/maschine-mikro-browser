#include "minhook/include/MinHook.h"
#include "native-fingerprints.h"

static uintptr_t imageBase,browserVtable,tagVtable;
static std::atomic<bool> nativeReady{false};
static bool expansionEnabled=false;
static void* owners[8]{};
static ULONGLONG ownerTicks[8]{};
static SRWLOCK ownerLock=SRWLOCK_INIT;
using TimerFn=uintptr_t(__fastcall*)(void*);
using DestructorFn=void*(__fastcall*)(void*,unsigned);
using CaptionFn=void(__fastcall*)(void*,const void*);
static TimerFn originalTimer;
static DestructorFn originalDestructor;
static CaptionFn caption;

static bool Readable(const void* p,size_t bytes) {
    MEMORY_BASIC_INFORMATION info{};
    if(!p||!VirtualQuery(p,&info,sizeof(info))||info.State!=MEM_COMMIT||info.Protect&(PAGE_GUARD|PAGE_NOACCESS))return false;
    uintptr_t start=reinterpret_cast<uintptr_t>(p),end=start+bytes;
    return end>=start&&end<=reinterpret_cast<uintptr_t>(info.BaseAddress)+info.RegionSize;
}
static bool IsOwner(void* p) {
    if(!Readable(p,0x4c0))return false;
    __try {return *reinterpret_cast<uintptr_t*>(p)==browserVtable;}
    __except(EXCEPTION_EXECUTE_HANDLER){return false;}
}
static void Observe(void* p) {
    if(GetCurrentThreadId()!=guiThread||!IsOwner(p))return;
    AcquireSRWLockExclusive(&ownerLock);
    int freeSlot=-1;
    for(int i=0;i<8;++i) {
        if(owners[i]==p){ownerTicks[i]=GetTickCount64();ReleaseSRWLockExclusive(&ownerLock);return;}
        if(!owners[i])freeSlot=i;
    }
    if(freeSlot>=0){owners[freeSlot]=p;ownerTicks[freeSlot]=GetTickCount64();Log("OWNER_CAPTURED");}
    ReleaseSRWLockExclusive(&ownerLock);
}
static uintptr_t __fastcall OnTimer(void* p) {Observe(p);return originalTimer(p);}
static void* __fastcall OnDestructor(void* p,unsigned flags) {
    AcquireSRWLockExclusive(&ownerLock);
    for(int i=0;i<8;++i)if(owners[i]==p){owners[i]=nullptr;ownerTicks[i]=0;Log("OWNER_DESTROYED");}
    ReleaseSRWLockExclusive(&ownerLock);
    return originalDestructor(p,flags);
}
static void* FindOwner() {
    void* candidate=nullptr;bool ambiguous=false;ULONGLONG now=GetTickCount64();
    AcquireSRWLockShared(&ownerLock);
    for(int i=0;i<8;++i)if(owners[i]&&now-ownerTicks[i]<2000&&IsOwner(owners[i])) {
        if(candidate){ambiguous=true;break;}candidate=owners[i];
    }
    ReleaseSRWLockShared(&ownerLock);
    return ambiguous?nullptr:candidate;
}
static bool InstallNativeHooks() {
#ifdef BRIDGE_TESTS
    return false;
#else
    if(nativeReady)return true;
    imageBase=reinterpret_cast<uintptr_t>(GetModuleHandleW(nullptr));
    if(!Readable(reinterpret_cast<void*>(imageBase+0x02081ad0),sizeof(FingerprintCaption)))return false;
    if(memcmp(reinterpret_cast<void*>(imageBase+0x02081ad0),FingerprintCaption,sizeof(FingerprintCaption))||
       memcmp(reinterpret_cast<void*>(imageBase+0x02095f90),FingerprintTimer,sizeof(FingerprintTimer))||
       memcmp(reinterpret_cast<void*>(imageBase+0x0207e0b0),FingerprintDestructor,sizeof(FingerprintDestructor))) {
        Log("NATIVE_FINGERPRINT_REJECT");return false;
    }
    browserVtable=imageBase+0x0c0692b8;tagVtable=imageBase+0x0c065040;
    caption=reinterpret_cast<CaptionFn>(imageBase+0x02081ad0);
    if(MH_Initialize()!=MH_OK){Log("HOOK_LIBRARY_REJECT");return false;}
    void* timer=reinterpret_cast<void*>(imageBase+0x02095f90);
    void* destructor=reinterpret_cast<void*>(imageBase+0x0207e0b0);
    if(MH_CreateHook(timer,OnTimer,reinterpret_cast<void**>(&originalTimer))!=MH_OK||
       MH_CreateHook(destructor,OnDestructor,reinterpret_cast<void**>(&originalDestructor))!=MH_OK) {
        Log("NATIVE_HOOK_CREATE_FAILED");return false;
    }
    MH_QueueEnableHook(timer);MH_QueueEnableHook(destructor);
    if(MH_ApplyQueued()!=MH_OK){Log("NATIVE_HOOK_ENABLE_FAILED");return false;}
    nativeReady=true;Log("NATIVE_HOOKS_READY");return true;
#endif
}
static void ExpandRequested(unsigned op) {
    if(op==100){expansionEnabled=true;Log("EXPANSION_ENABLED");return;}
    if(op==101){expansionEnabled=false;Log("EXPANSION_DISABLED");return;}
    if(!nativeReady||GetCurrentThreadId()!=guiThread||!ValidWindow())return;
    void* owner=FindOwner();if(!owner){Log("EXPAND_NO_UNIQUE_OWNER",0,op);return;}
    size_t index=op==2?2:0;
    struct Capture {void* unusedVtable;void* owner;size_t column;} capture{nullptr,owner,index};
    __try {
        auto bytes=reinterpret_cast<unsigned char*>(owner);
        void* tag=*reinterpret_cast<void**>(bytes+0x498+16*index);
        if(!Readable(tag,0x4cb)||*reinterpret_cast<uintptr_t*>(tag)!=tagVtable||
           *reinterpret_cast<unsigned*>(reinterpret_cast<unsigned char*>(tag)+0x470)!=index) {Log("EXPAND_TAG_REJECT",0,op);return;}
        if(!*(reinterpret_cast<unsigned char*>(tag)+0x4c8)) {Log("ALREADY_EXPANDED",0,op);return;}
        if(!*reinterpret_cast<void**>(reinterpret_cast<unsigned char*>(tag)+0x488)) {Log("NO_CAPTION",0,op);return;}
        if(!expansionEnabled){Log("CAPTURE_VALIDATED_NO_ACTION",0,op);return;}
#ifdef CAPTURE_ONLY
        Log("CAPTURE_VALIDATED_NO_ACTION",0,op);return;
#endif
        // Same GUI-thread callback as the native caption, including subtype/layout updates.
        caption(&capture,nullptr);
        Log(!*(reinterpret_cast<unsigned char*>(tag)+0x4c8)?"EXPANDED":"EXPAND_NOT_APPLICABLE",0,op);
    } __except(EXCEPTION_EXECUTE_HANDLER) {
        nativeReady=false;Log("NATIVE_ACCESS_FAULT_DISABLED",0,op);
    }
}
#ifdef BRIDGE_TESTS
extern "C" __declspec(dllexport) void BridgeBindNativeTest(void* root,uintptr_t bv,uintptr_t tv,CaptionFn fn) {
    browserVtable=bv;tagVtable=tv;caption=fn;nativeReady=true;expansionEnabled=true;Observe(root);
}
extern "C" __declspec(dllexport) void BridgeForgetNativeTest(void* root) {
    AcquireSRWLockExclusive(&ownerLock);
    for(int i=0;i<8;++i)if(owners[i]==root){owners[i]=nullptr;ownerTicks[i]=0;}
    ReleaseSRWLockExclusive(&ownerLock);
}
#endif
