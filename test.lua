local sndfile = require "audio.sndfile"

local s = sndfile("tmp.wav", "w")

local len = 44100 * 3
for i = 1, len do 
	s:write(math.random())
end
s:close()

