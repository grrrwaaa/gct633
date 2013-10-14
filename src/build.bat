
@rem /MT avoids CRT dependency
@rem Delayimp.lib + /DELAYLOAD:lua51.dll allows us to use Lua symbols even though the DLL is not actually loaded until during main()
cl /MT /EHsc /O2 /D__WINDOWS_DS__ /I win32/include av.cpp av_audio.cpp RtAudio.cpp lua51.lib glut32.lib Dsound.lib ole32.lib user32.lib Delayimp.lib /link /LIBPATH:win32/lib /DELAYLOAD:lua51.dll /DELAYLOAD:glut32.dll /out:av.exe

move /Y av.exe ..

cd ..
av.exe test.lua
cd src

@echo ok