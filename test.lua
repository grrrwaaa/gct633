local sndfile = require "audio.sndfile"
local audio = require "audio"

local s = sndfile("tmp.wav", "w")

local len = 44100 * 3
for i = 1, len do 
	s:write(math.sin(i * 0.1))
end
s:close()

