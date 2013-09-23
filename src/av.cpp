
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "av.hpp"
#include "RtAudio.h"

lua_State * L = 0;
// the path from where it was invoked:
char launchpath[AV_PATH_MAX+1];
// the path where the binary actually resides, e.g. with modules:
char apppath[AV_PATH_MAX+1];
// the path of the start file, e.g. user script / workspace:
char workpath[AV_PATH_MAX+1];
// filename of the main script:
char mainfile[AV_PATH_MAX+1];


#define DEBUG_PRINTF()
//#define DEBUG_PRINTF(args ...) fprintf(stderr, args)

void getpaths(int argc, char ** argv) {
	#ifdef AV_WINDOWS
		{
			char tmppath[AV_PATH_MAX];
			GetCurrentDirectory(MAX_PATH, tmppath);
			AV_SNPRINTF(launchpath, AV_PATH_MAX, "%s\\", tmppath);
		}
		
		HMODULE hModule = GetModuleHandle(NULL);
		char path[MAX_PATH];
		GetModuleFileName(hModule, path, MAX_PATH);
		_splitpath(path, NULL, apppath, NULL, NULL);
		
		if (argc > 1) {
			char tmppath[AV_PATH_MAX];
			DWORD retval = GetFullPathName(argv[1],
					 AV_PATH_MAX,
					 tmppath,
					 NULL);
			_splitpath(tmppath, NULL, workpath, mainfile, NULL);
		} else {
			// use same as app path:
			AV_SNPRINTF(workpath, AV_PATH_MAX, "%s", apppath);
		}
	#else
		
		
		char wd[AV_PATH_MAX];
		if (AV_GETCWD(wd, AV_PATH_MAX) == 0) {
			printf("could not derive working path\n");
			exit(0);
		}
		
		// get binary path:
		char tmppath[AV_PATH_MAX];
		#ifdef AV_OSX
			AV_SNPRINTF(launchpath, AV_PATH_MAX, "%s/", wd);
			#ifdef AV_OSXAPP
				// launched as a .app:
				AV_SNPRINTF(apppath, AV_PATH_MAX, "%s", launchpath);
			#else
				// launched as a console app:
				if (argc > 0) {
					realpath(argv[0], tmppath);
				}
				AV_SNPRINTF(apppath, AV_PATH_MAX, "%s/", dirname(tmppath));
			#endif
			
			
		#elif defined(AV_WINDOWS)
			// Windows only:
			{
			_splitpath(wd, NULL, wd, NULL, NULL);
			AV_SNPRINTF(launchpath, AV_PATH_MAX, "%s", wd);
			DWORD retval = GetFullPathName(argv[0],
					 AV_PATH_MAX,
					 tmppath,
					 NULL);
			_splitpath(tmppath, NULL, tmppath, NULL, NULL);
			AV_SNPRINTF(apppath, AV_PATH_MAX, "%s", (tmppath));
			}
		#else
			AV_SNPRINTF(launchpath, AV_PATH_MAX, "%s/", wd);
			// Linux only?
			int count = readlink("/proc/self/exe", tmppath, AV_PATH_MAX);
			if (count > 0) {
				tmppath[count] = '\0';
			} else if (argc > 0) {
				realpath(argv[0], tmppath);
			}
			AV_SNPRINTF(apppath, AV_PATH_MAX, "%s/", dirname(tmppath));
		#endif
		
		char apath[AV_PATH_MAX];
		#if defined(AV_WINDOWS)
			{
			DWORD retval = GetFullPathName(argv[1],
					 AV_PATH_MAX,
					 tmppath,
					 NULL);
			_splitpath(tmppath, NULL, workpath, mainfile, NULL);
			AV_SNPRINTF(apppath, AV_PATH_MAX, "%s", (tmppath));
			}
		#else
		if (argc > 1) {
			realpath(argv[1], apath);
			
			AV_SNPRINTF(mainfile, AV_PATH_MAX, "%s", basename(apath));
			AV_SNPRINTF(workpath, AV_PATH_MAX, "%s/", dirname(apath));
		} else {
			// just copy the current path:
			AV_SNPRINTF(workpath, AV_PATH_MAX, "%s", launchpath);
			AV_SNPRINTF(mainfile, AV_PATH_MAX, "%s", "main.lua");
		}
		#endif
	#endif
	DEBUG_PRINTF("launchpath %s\n", launchpath);
	DEBUG_PRINTF("apppath %s\n", apppath);
	DEBUG_PRINTF("workpath %s\n", workpath);
	DEBUG_PRINTF("mainfile %s\n", mainfile);
}

int traceback(lua_State * L) {
	if (!lua_isstring(L, 1)) {
		if (lua_isnoneornil(L, 1) ||
			!luaL_callmeta(L, 1, "__tostring") ||
			!lua_isstring(L, -1)) {
			return 1;
		}
		lua_remove(L, 1);
	}
	luaL_traceback(L, L, lua_tostring(L, 1), 1);
	return 1;
}

int docall(lua_State * L, int narg=0, int clear=1) {
	int status, base = lua_gettop(L) - narg;
	lua_pushcfunction(L, traceback);
	lua_insert(L, base);
	status = lua_pcall(L, narg, (clear ? 0 : LUA_MULTRET), base);
	lua_remove(L, base);
	if (status != 0) lua_gc(L, LUA_GCCOLLECT, 0);
	return status;
}

void postdo(int status, const char * name) {
	if (status && !lua_isnil(L, -1)) {
		const char * msg = lua_tostring(L, -1);
		if (msg == NULL) msg = "(error object is not a string)";
		fprintf(stderr, "%s: %s\n", name, msg);
		fflush(stderr);
		lua_pop(L, 1);
	}
}

int dofile(const char * name) {
	if (name) {
		int status = luaL_loadfile(L, name) || docall(L);
		postdo(status, name);
		return status;
	}
	return -1;
}

int dostring(const char * code, const char * name = "<anonymous>") {
	if (name) {
		int status = luaL_loadstring(L, code) || docall(L);
		postdo(status, name);
		return status;
	}
	return -1;
}

#ifdef AV_WINDOWS
HMODULE dll(const char * name) {
	char dllpath[MAX_PATH];
	sprintf(dllpath, "%s\\av\\win32\\%s.dll", apppath, name);
	HMODULE mod = LoadLibrary(dllpath);
	if (mod == NULL) printf("failed to load %s\n", dllpath);
	return mod;
}
#endif

int initlua(int argc, char * argv[]) {
	L = lua_open();
	DEBUG_PRINTF("L %p\n", L);
	if (!L) return -1;
	luaL_openlibs(L);
	
	lua_getglobal(L, "package");
    lua_getfield(L, -1, "preload");
    //lua_pushcfunction(L, luaopen_pack); lua_setfield(L, -2, "pack");
    lua_pop(L, 2);
	
	DEBUG_PRINTF("opened libs\n");
	
	lua_createtable(L, argc, 0);
	for (int i=0; i<argc; i++) {
		lua_pushstring(L, argv[i]); lua_rawseti(L, -2, i);
	}
	lua_setglobal(L, "arg");
	
	DEBUG_PRINTF("set arg\n");
	
	#define initscriptsize 100000
	char initscript[initscriptsize];
	#ifdef AV_WINDOWS 
		AV_SNPRINTF(initscript, initscriptsize, "package.path = [[%sav\\?.lua;%sav\\?\\init.lua;]] .. package.path; package.cpath = [[%sav\\?.dll;]] .. package.cpath", apppath, apppath, apppath);
	#else
		AV_SNPRINTF(initscript, initscriptsize, "package.path = [[%sav/?.lua;%sav/?/init.lua;]] .. package.path; package.cpath = [[%sav/?.so;]] .. package.cpath", apppath, apppath, apppath);
	#endif
	DEBUG_PRINTF("initscript %s\n", initscript);
	return dostring(initscript);
}


#ifdef AV_WINDOWS
	#include < time.h >
	#if defined(_MSC_VER) || defined(_MSC_EXTENSIONS)
	  #define DELTA_EPOCH_IN_MICROSECS  11644473600000000Ui64
	#else
	  #define DELTA_EPOCH_IN_MICROSECS  11644473600000000ULL
	#endif
	 
	struct timezone 
	{
	  int  tz_minuteswest; /* minutes W of Greenwich */
	  int  tz_dsttime;     /* type of dst correction */
	};
	 
	int gettimeofday(struct timeval *tv, struct timezone *tz)
	{
	  FILETIME ft;
	  unsigned __int64 tmpres = 0;
	  static int tzflag;
	 
	  if (NULL != tv)
	  {
		GetSystemTimeAsFileTime(&ft);
	 
		tmpres |= ft.dwHighDateTime;
		tmpres <<= 32;
		tmpres |= ft.dwLowDateTime;
	 
		/*converting file time to unix epoch*/
		tmpres -= DELTA_EPOCH_IN_MICROSECS; 
		tmpres /= 10;  /*convert into microseconds*/
		tv->tv_sec = (long)(tmpres / 1000000UL);
		tv->tv_usec = (long)(tmpres % 1000000UL);
	  }
	 
	  if (NULL != tz)
	  {
		if (!tzflag)
		{
		  _tzset();
		  tzflag++;
		}
		tz->tz_minuteswest = _timezone / 60;
		tz->tz_dsttime = _daylight;
	  }
	 
	  return 0;
	}
#endif

AV_EXPORT double av_time() {
		timeval t;
		gettimeofday(&t, NULL);
		return (double)t.tv_sec + (((double)t.tv_usec) * 1.0e-6);
}	

AV_EXPORT void av_sleep(double seconds) {
	#ifdef AV_WINDOWS
		Sleep((DWORD)(seconds * 1.0e3));
	#else
		time_t sec = (time_t)seconds;
		long long int nsec = 1.0e9 * (seconds - (double)sec);
		timespec tspec = { sec, nsec };
		while (nanosleep(&tspec, &tspec) == -1) {
			continue;
		}
	#endif
}
							
int main(int argc, char * argv[]) {

	getpaths(argc, argv);
	
	#ifdef AV_WINDOWS
		dll("lua51");
		dll("libsndfile-1");
		//dll("glut32"); // trick didn't seem to work for GLUT
	#endif
	// configure GLUT:
	//glutInit(&argc, argv);
	
	initlua(argc, argv);
	printf("------------------------------------------------------------\n");
	
	if (argc > 1) {
		dofile(argv[1]);
	} else {
		dofile("main.lua");
	}
	
	lua_close(L);
	printf("bye\n");
	getchar();
	return 0;
}