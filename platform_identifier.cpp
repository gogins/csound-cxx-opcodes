#include <string>
#include <cstdio>

/**
 * Returns a stringified list of any compiler macros that identify the 
 * operating system, plus a generic name for the operating system in the sense 
 * of the application binary interface, one of 
 * Linux, BSD, Unix, macOS, iOS, Android, or Windows.
 */
int main()
{
    std::string platform = "Unidentified operating system.";
    std::string macros;
#ifdef _WIN32
    macros += "_WIN32 ";
    platform = "Windows";
#endif
#ifdef __APPLE__
    macros += "__APPLE__ ";
    platform = "macOS";
#endif
#ifdef __linux__
    macros += "__linux__ ";
    platform = "Linux";
#endif
#ifdef TARGET_OS_EMBEDDED
    macros += "TARGET_OS_EMBEDDED ";
    platform = "iOS";
#endif
#ifdef TARGET_IPHONE_SIMULATOR
    macros += "TARGET_IPHONE_SIMULATOR ";
    platform = "iOS";
#endif
#ifdef TARGET_OS_IPHONE
    macros += "TARGET_OS_IPHONE ";
    platform = "iOS";
#endif
#ifdef TARGET_OS_MAC
    macros += "TARGET_OS_MAC ";
    platform = "macOS";
#endif
#ifdef __ANDROID__
    macros += "__ANDROID__ ";
    platform = "Android";
#endif
#ifdef __unix__
    macros += "__unix__ ";
    //platform = "Unix";
#endif
#ifdef _POSIX_VERSION
    macros += "_POSIX_VERSION ";
    //platform = "POSIX";
#endif
#ifdef __sun
    macros += "__sun ";
    platform = "Solaris";
#endif
#ifdef __hpux
    macros += "__hpux ";
    platform = "HP_UX";
#endif
#ifdef BSD
    macros += "BSD ";
    platform = "BSD";
#endif
#ifdef __DragonFly__
    macros += "__DragonFly__ ";
    platform = "BSD";
#endif
#ifdef __FreeBSD__
    macros += "__FreeBSD__ ";
    platform = "BSD";
#endif
#ifdef __NetBSD__
    macros += "__NetBSD__ ";
    platform = "BSD";
#endif
#ifdef __OpenBSD__
    macros += "__OpenBSD__ ";
    platform = "BSD";
#endif
    std::fprintf(stderr, "Macros defined are: \"%s\"\n", macros.c_str());
    std::fprintf(stderr, "Platform ABI is: \"%s\"\n", platform.c_str());
	return 0;
}
