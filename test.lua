print("started")


local ffi = require "ffi"
local len = 44100 * 3
local buf = ffi.new("float[?]", len)

for i = 0, len-1 do buf[i] = math.sin(i*0.1) * math.sin(i * 0.0001) end

local sndfile = require "audio.sndfile"
local s = sndfile("tmp.wav", "w")
s:write(buf, len)
s:close()

--io.popen("start tmp.wav")
--os.exit()