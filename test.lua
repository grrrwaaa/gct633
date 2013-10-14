local runloop = require "runloop"

local ffi = require "ffi"
local C = ffi.C

t = C.av_time()
runloop.insert(function()
	local t1 = C.av_time()
	print("hello", t1 - t )
	t = t1
end)