
cl /c /EHsc /O2 /D__WINDOWS_DS__ /I ../win32/include av_audio.cpp 
lib av_audio.obj

@rem link /DLL /LIBPATH:../win32/lib libsndfile-1.lib /out:libaudio.dll

@echo ok