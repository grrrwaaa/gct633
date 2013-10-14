#!/usr/bin/env luajit

--[[

Build the audio core lib

--]]

local ffi = require "ffi"

-- invoke a one-line shell command:
local function cmda(fmt, ...) 
	if type(fmt) == "table" then fmt = table.concat(fmt, " ") end
	local str = string.format(fmt, ...)
	print(str) 
	return io.popen(str):read("*a")
end

if ffi.os == "OSX" then

	-- build 32:
	local CC = "g++ "
	local CFLAGS = "-fno-stack-protector -O3 -Wall -fPIC " 
				.. "-mmacosx-version-min=10.6 "
				.. "-DEV_MULTIPLICITY=1 -DHAVE_GETTIMEOFDAY -D__MACOSX_CORE__ "
				.. "-Iosx/include"
	local SRC = "av.cpp av_audio.cpp RtAudio.cpp "
	local LDFLAGS = "-w -keep_private_externs "
				.. "-mmacosx-version-min=10.6 "
				.. "-Losx/lib "
	local LIBS = "osx/lib/libluajit.a -framework CoreFoundation -framework Carbon -framework Cocoa -framework CoreAudio -framework GLUT -framework OpenGL -framework IOKit -force_load osx/lib/libsndfile.a"
	local OUT = "-o av_osx"
	
	local build32 = { CC, "-arch i386 ", CFLAGS, SRC, LDFLAGS, LIBS, "-o av32" }
	local build64 = { CC, "-arch x86_64 ", CFLAGS, SRC, "-pagezero_size 10000 -image_base 100000000 ", LDFLAGS, LIBS, "-o av64" }
		
	print(cmda(build32))
	print(cmda(build64))
	
	print(cmda("lipo -create av32 av64 -output av_osx && rm av32 && rm av64 && mv av_osx ../ "))
	print("running")
	print(cmda("../av_osx ../graphics_test.lua"))
	
	
	--print(cmda("clang++ -arch i386 -arch x86_64 -I/usr/local/include -I/usr/local/include/luajit-2.0 av.cpp av_audio.cpp RtAudio.cpp  -pagezero_size 10000 -image_base 100000000 /usr/local/lib/libluajit-5.1.a -framework CoreFoundation -framework CoreAudio -force_load /usr/local/lib/libsndfile.a  -o av_osx"))
	
	--print(cmda("mv av_osx .."))
	
elseif ffi.os == "Windows" then
	
	
else

	error("TODO audio.make.lua")
end