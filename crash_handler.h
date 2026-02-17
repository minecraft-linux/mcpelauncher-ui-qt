#pragma once

class CrashHandler {

private:
    static bool hasCrashed;
    static int argc;
    static char**argv;

    static void handleSignal(int signal, void* aptr);
public:
    static void registerCrashHandler(int argc, char**argv);

};