local audio = require "audio" 
local buffer = require "audio.buffer"
local samplerate = 44100

-- generate random number in (-1,1) range:
function srandom()
	return math.random()*2-1
end

-- construct a noise burst generator:
function noiseburst(period)
	-- number of samples to play for:
	local dur = period * samplerate
	-- samples played so far:
	local count = 0
	return function()
		-- update samples played so far:
		count = count + 1
		-- if we haven't played enough yet:
		if count < dur then
			-- generate & return a random value
			return srandom()
		end
	end
end

-- construct a noise burst generator 
-- of duration 0.1 seconds
local mynoise = noiseburst(0.1)

-- play it
--audio.play(mynoise)

local delay = {
	-- create a 1 second block of sample memory:
	data = buffer(441),
	-- set the initial position to zero:
	pos = 0,
}

for i = 0, delay.data.frames-1 do
	delay.data.samples[i] = srandom()
end

-- previous value of s
local s0 = 0

audio.play(function()
	-- move read head on:
	delay.pos = delay.pos + 1
	-- wrap at end:
	if delay.pos >= delay.data.frames then
		delay.pos = 0
	end
	-- get sample at this position:
	local s = delay.data.samples[ delay.pos ]
	
	-- take the average:
	s = s + 0.3 * (s0 - s)
	  --s * 0.9 + s0 * 0.1
	  
	-- overall decay
	s = s * 0.99
	
	-- scale down & write back in:
	delay.data.samples[delay.pos] = s
	
	-- update s0:
	s0 = s
	
	-- hear it:
	return s
end)

















