#!/usr/bin/env luajit

-- assert required LuaJIT:
assert(_VERSION == "Lua 5.1", "please use LuaJIT 2.0")
assert(jit.version_num and jit.version_num > 20000, "please use LuaJIT 2.0")
-- it's useful to print this out to acknowledge the source and for the sake of debug reports
print(jit.version, jit.os, jit.arch)

-- av.lua can be used as a regular Lua module, or as a launcher script
-- (if it is used as a module, the main script must explicitly call av.run() at the end)
-- To know whether av.lua is executed as a module or as a launcher script:
-- if executed by require(), ... has length of 1 and contains the module name
local argc = select("#", ...)
local modulename = ...
local is_module = argc == 1 and modulename == "av"

-- some utilities:
local ffi = require "ffi"

-- invoke a one-line shell command:
local function cmd(fmt, ...) 
	local str = string.format(fmt, ...)
	--print(str) 
	return io.popen(str):read("*l")
end

-- derive the folder (directory) from a full filepath
local path_from_filename
if ffi.os == "Windows" then
	path_from_filename = function(filename)
		-- use a C routine instead?
		return filename:match("(.*\\)") or ""
	end
else
	path_from_filename = function(filename)
		-- use a C routine instead, so we can handle things like ~ etc.?
		return filename:match("(.*/)") or "./"
	end
end

-- add a new path for Lua to search for binary modules:
local function add_module_cpath(path)
	if ffi.os == "Windows" then
		package.cpath = string.format("%s?.dll;%s", path, package.cpath)
	else
		package.cpath = string.format("%s?.so;%s", path, package.cpath)
	end
end

-- add a new path for Lua to search for modules:
local function add_module_path(path, also_binary)
	package.path = string.format("%s?.lua;%s?/init.lua;%s", path, path, package.path)
	if also_binary then add_module_cpath(path) end
end

--------------------------------------------------------------------------------
-- define the main module:
local av = {
	config = {
		maxtimercallbacks = 500,
	},
	script = {
	
	},
}

-- local reference for speed
local config = av.config

--------------------------------------------------------------------------------
-- rationalize various paths
local script_filename = arg[is_moduele and 0 or 1]
local pwd = io.popen("pwd"):read("*l")
-- where is av.lua?
if is_module then
	-- we have to assume av was found in package.path
	-- that implies av modules are also in package.path, so we don't need to modify it
	-- but the question is: how will we know where to ffi.load the core functions from?
	-- (can we require av.core and use ffi.C?)
	
	-- script filename could be nil, e.g. embedded case
	if script_filename then
		-- extract path from filename
		av.script.path = path_from_filename(script_filename)
	else
		-- assume pwd
		av.script.path = pwd
	end
else
	-- av.lua must be in arg[0]
	local av_filename = arg[0]
	assert(av_filename)
	
	-- extract path from filename
	av.path = path_from_filename(av_filename)
	-- and add this to package path:
	add_module_path(av.path .. "av/")
	add_module_path(av.path .. "av/" .. ffi.os .. "/")
	
	-- modify the global arg table to trim off av.lua
	-- (so that launching a script via luajit av.lua or ./av.lua or via hashbang is consistent)
	for i = 0, argc do arg[i] = arg[i+1] end
	
	-- now extract path from filename
	assert(script_filename, "missing argument (path of script to run)")
	-- extract path from filename
	av.script.path = path_from_filename(script_filename)
	-- also add this to package path:
	add_module_path(av.script.path, true)
end
--print(cmd("echo $HOME")) print(os.getenv("HOME"))

-- load in the essential binary library:
-- (TODO: if we are embedded, do this from ffi.C instead)
local libname = ({
	OSX = "av/libav_core.dylib",
	Linux = "av/libav_core.so",
	Windows = "av/libav_core.dll",
})[ffi.os]

--------------------------------------------------------------------------------
-- mainloop / scheduler
local scheduler = require "scheduler"
local schedule = scheduler.create()
now, go, wait, event = schedule.now, schedule.go, schedule.wait, schedule.event

-- TODO: remove this once we have core in place:
ffi.cdef[[
	void Sleep(int ms);
	int poll(struct pollfd *fds, unsigned long nfds, int timeout);
]]
local sleep
if ffi.os == "Windows" then
  function sleep(s)
    ffi.C.Sleep(s*1000)
  end
else
  function sleep(s)
    ffi.C.poll(nil, 0, s*1000)
  end
end

-- the main loop:
local t = 0
function av.run()
	-- avoid multiple invocations:
	av.run = function() end
	while true do
		t = t + 1
		schedule.update(t, config.maxtimercallbacks)
		sleep(1)
	end
end

--------------------------------------------------------------------------------
-- launch: return control to user script / schedule script & start running
if is_module then
	--print("call av.run() to start")
	-- we're loaded as a module
	-- so just return it:
	return av
else
	--print("running as launcher script")
	-- indicate that av is already loaded
	-- so that require "av" now simply returns the local av:
	package.loaded.av = av
	-- parse the script into a function:
	local scriptfunc, err = loadfile(script_filename)
	if not scriptfunc then
		-- print any parse error and exit with failure:
		print(err)
		os.exit(-1)
	end
	-- schedule this script to run as a coroutine, as soon as av.run() begins:
	-- (passing arg as ... is strictly speaking redundant; should it be removed?)
	go(scriptfunc, unpack(arg))
	-- now start the main loop!
	av.run()
end
