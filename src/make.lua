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

	print(cmda("clang++ -fno-stack-protector -O3 -Wall -fPIC -DEV_MULTIPLICITY=1 -DHAVE_GETTIMEOFDAY -D__MACOSX_CORE__ -I/usr/local/include -I/usr/local/include/luajit-2.0 av.cpp av_audio.cpp RtAudio.cpp  -pagezero_size 10000 -image_base 100000000 -force_load /usr/local/lib/libsndfile.a /usr/local/lib/libluajit-5.1.a -framework CoreFoundation -framework CoreAudio -o av_osx"))
	
	print(cmda("mv av_osx .."))
	
elseif ffi.os == "Windows" then
	
	
else

	error("TODO audio.make.lua")
end