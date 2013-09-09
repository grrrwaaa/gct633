#!/usr/bin/env luajit

--[[

Build the audio core lib

--]]

local ffi = require "ffi"

-- invoke a one-line shell command:
local function cmda(fmt, ...) 
	local str = string.format(fmt, ...)
	print(str) 
	return io.popen(str):read("*a")
end

if ffi.os == "OSX" then

	print(cmda("clang++ -fno-stack-protector -O3 -Wall -fPIC -DEV_MULTIPLICITY=1 -DHAVE_GETTIMEOFDAY -D__MACOSX_CORE__ av_audio.cpp RtAudio.cpp /usr/local/lib/libsndfile.a -framework CoreFoundation -framework CoreAudio -shared -o libaudio.dylib"))
	
elseif ffi.os == "Windows" then
	
	
else

	error("TODO audio.make.lua")
end