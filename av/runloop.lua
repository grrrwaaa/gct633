local ffi = require "ffi"
local lib = ffi.C

--[[
A low-level API to the av runtime

E.g. for adding callbacks to the main loop
--]]

ffi.cdef [[
	typedef void (*av_run_callback)();

	typedef struct av_run_callback_node {
		struct av_run_callback_node * next;
		av_run_callback run;
	} av_run_callback_node;

	void av_run_insert(av_run_callback cb);
	void av_run_once();

	double av_time();
	void av_sleep(double s);
]]

local cache = {}

local runloop = {}

function runloop.insert(cb)
	cache[cb] = true	-- prevent garbage collection
	lib.av_run_insert(cb)
end

function runloop.run_once()
	lib.av_run_once()
end

return runloop