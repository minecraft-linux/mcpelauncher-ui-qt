#include "crash_handler.h"

#include <cstdlib>
#include <cstdio>
#include <cstring>
#include <csignal>
#include <cxxabi.h>
#include <execinfo.h>
#include <thread>
#include <dlfcn.h>
#include <unistd.h>
#include <EnvPathUtil.h>
#include <spawn.h>

bool CrashHandler::hasCrashed = false;
int CrashHandler::argc = 0;
char** CrashHandler::argv = nullptr;

void CrashHandler::handleSignal(int signal, void *aptr) {
    printf("Signal %i received\n", signal);

    struct sigaction act;
    act.sa_handler = nullptr;
    sigemptyset(&act.sa_mask);
    act.sa_flags = 0;
    sigaction(SIGSEGV, &act, 0);
    sigaction(SIGABRT, &act, 0);
    sigaction(SIGFPE, &act, 0);
    sigaction(SIGBUS, &act, 0);
    sigaction(SIGILL, &act, 0);

    if (hasCrashed)
        return;
    hasCrashed = true;

    // Workaround against application freeze while dumping stacktrace
    // stop app from bouncing more than one sec. on crash macOS x86_64
    std::thread([signal](){
        std::this_thread::sleep_for(std::chrono::milliseconds(1000));
        printf("Backtrace or dumping stack hung up, aborting\n");
        printf("Signal Number %d\n", signal);
        fflush(stdout);
        _Exit(signal);
    }).detach();

    void** ptr = &aptr;
    void *array[25];
    int count = backtrace(array, 25);
    char **symbols = backtrace_symbols(array, count);
    char *nameBuf = (char*) malloc(256);
    size_t nameBufLen = 256;
    printf("Backtrace elements: %i\n", count);
    for (int i = 0; i < count; i++) {
        if (symbols[i] == nullptr) {
            printf("# %i unk [%4p]\n", i, array[i]);
            continue;
        }
        if (symbols[i][0] == '[') { // unknown symbol
            Dl_info symInfo;
            if (dladdr(array[i], &symInfo)) {
                int status = 0;
                nameBuf = abi::__cxa_demangle(symInfo.dli_sname, nameBuf, &nameBufLen, &status);
                printf("\\# %i NATIVE %s+%p in %s+0x%4p [0x%4p]\n", i, nameBuf, (void *) ((size_t) array[i] - (size_t) symInfo.dli_saddr), symInfo.dli_fname, (void *) ((size_t) array[i] - (size_t) symInfo.dli_fbase), array[i]);
                continue;
            }
        }
        printf("# %i %s\n", i, symbols[i]);
    }
    printf("Dumping stack...\n");
    for (int i = 0; i < 1000; i++) {
        void* pptr = *ptr;
        Dl_info symInfo;
        if (pptr && dladdr(pptr, &symInfo)) {
            int status = 0;
            nameBuf = abi::__cxa_demangle(symInfo.dli_sname, nameBuf, &nameBufLen, &status);
            printf("\\# %i NATIVE %s+%p in %s+%4p [%4p]\n", i, nameBuf, (void *) ((size_t) pptr - (size_t) symInfo.dli_saddr), symInfo.dli_fname, (void *) ((size_t) pptr - (size_t) symInfo.dli_fbase), pptr);
        }
        ptr++;
    }
    printf("program failed with unix signal number: %d\n", signal);
    fflush(stdout);

    // Disable google login webview and v1.6.x code
    pid_t pid;
    char* envp[] = { (char*)"SAFE_MODE=1", (char*)"USE_WEBENGINE=0", nullptr };

    posix_spawn(&pid,
                (EnvPathUtil::getAppDir() + "/mcpelauncher-ui-qt").c_str(),
                nullptr, nullptr,
                argv, envp);
    _exit(127);
}

void CrashHandler::registerCrashHandler(int argc, char**argv) {
    printf("SAFE_MODE before exec: %s\n", getenv("SAFE_MODE"));
    CrashHandler::argc = argc;
    CrashHandler::argv = argv;

    struct sigaction act;
    sigemptyset(&act.sa_mask);
    act.sa_handler = (void (*)(int)) handleSignal;
    act.sa_flags = 0;
    sigaction(SIGSEGV, &act, 0);
    sigaction(SIGABRT, &act, 0);
    sigaction(SIGFPE, &act, 0);
    sigaction(SIGBUS, &act, 0);
    sigaction(SIGILL, &act, 0);
}
