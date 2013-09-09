local ffi = require "ffi"
local sndfile = require "sndfile"

local s = sndfile("test.wav", "w")
print(s)

local dim = 100000
local buf = ffi.new("float[?]", dim)

for i = 0, dim-1 do
	buf[i] = math.random()
end

s:write(buf, dim)
s:close()

io.popen("start test.wav")