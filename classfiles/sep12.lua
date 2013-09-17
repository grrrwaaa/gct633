
-- load in the sndfile module
-- (wrapper of libsndfile)
local sndfile = require("audio.sndfile")

local samplerate = 44100

-- create a new soundfile to write to
local s = sndfile("mysound.wav", "w")

makeharmonic = function(t, harmonic)
	local freq = 440 * harmonic
	local angle = freq * t
	local v = math.sin(math.pi * 2 * angle)
	return v
end

-- loop for each sample
-- n is the current sample number
for n = 0, samplerate-1 do
	
	-- t is the current time in seconds:
	local t = n / samplerate
	
	local v1 = makeharmonic(t, 1)
	local v2 = makeharmonic(t, 2.1)
	local v3 = makeharmonic(t, 1)
	local v4 = makeharmonic(t, 10)
	local v5 = makeharmonic(t, 7)
	local v6 = makeharmonic(t, 15.5)
	
	local v = t * v4 * 0.1 * (v1 + v2 + v3 + v4 + v5 + v6)
	
	-- write the sample value to the file
	s.write(s, v)
end

-- close the sound file
s.close(s)



