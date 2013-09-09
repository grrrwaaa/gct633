
dofile("make.lua")

local audio = require "init"
local ffi = require "ffi"
local buffer = audio.buffer

function test()
	local b = buffer(32, 1)
	for i = 0, b.frames-1 do
		b.samples[i] = math.random()
	end
	for i = 0, b.frames-1 do
		print(b.samples[i])
	end
end
test()



local len = 100000
local buf = ffi.new("double[?]", len)
for i = 0, len/2-1 do
	buf[i*2] = math.sin(i * 0.1)
	buf[i*2+1] = buf[i*2]
end

-- open a soundfile for writing
-- note that sound files are always interleaved
local sf = audio.sndfile("test.wav", "w", { channels = 2 })
print(sf:write(buf, len))
print(sf)

collectgarbage()
collectgarbage()

