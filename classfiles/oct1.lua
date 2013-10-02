local audio = require "audio"
local ffi = require "ffi"
local samplerate = 44100
function s2samples(s) return s * samplerate end

-- decaying envelope
function decaying_env(dur_seconds)
	local e = 1
	local decay = 1/s2samples(dur_seconds)
	return function()
		if e > 0 then 
			e = e - decay 		
			return e
		end
	end
end

-- hihat
function hihat(amp)
	local env = decaying_env(0.2)
	return function()
		local e = env()
		if e then
			return math.random() * e * amp
		end
	end
end
--audio.play(hihat(1), 1)

local sound = hihat(1)

-- make a 1 second chunk of sample memory:
local samplememory = ffi.new("double[?]", 44100)

local head = 0
function writer()
	return function()
		head = head + 1
		if head >= 44100 then
			head = 0
		end
		-- get the next sample to add:
		local s = sound()
		if s == nil then
			samplememory[head] = 0
			-- small probability of restarting sound:
			if math.random() < 0.00001 then
				sound = hihat(1)
			end
		else
			samplememory[head] = s
		end
	end
end

function player(delaytime, decayfactor)
	local i = -s2samples(delaytime) % 44100
	return function()
		i = i + 1
		if i >= 44100 then
			i = 0
		end
		local s = samplememory[i]
		
		-- write back with decay:
		samplememory[head] = samplememory[head] 
						+ s * decayfactor
		
		return s
	end
end

local playback = function()
	local w = writer()
	local p1 = player(0.25, 0.2)
	local p2 = player(0.005, 0.4)
	local p3 = player(0.25, 0.2)
	return function()
		w()
		return p1() --+ p2() + p3()
	end
end

audio.play(playback(), 10)































