local audio = require "audio" 
local buffer = require "audio.buffer"
local samplerate = 44100

-- generate random number in (-1,1) range:
function srandom()
	return math.random()*2-1
end

function make_string(freq)

	local self = {
		-- create a 1 second block of sample memory:
		data = buffer(44100),
		-- set the initial position to zero:
		pos = 0,
		-- set the delay freq:
		freq = freq,
		
		filter = 0.1,
		
		decay = 0.999,
		
		-- pluck input:
		pluck = 1,
	}
	
	local s0 = 0
	audio.play(function()

		-- move write head on:
		self.pos = self.pos + 1
		-- wrap at end:
		if self.pos >= self.data.frames then
			self.pos = 0
		end
	
		-- get read point:
		local wavelength = (samplerate / self.freq)
		local idx = self.pos - wavelength
		if idx < 0 then
			idx = idx + self.data.frames
		end
	
		-- linear interpolation:
	
		local idx0 = math.floor(idx)
		-- local idx1 = (idx0 % delay.data.frames) + 1
		local idx1 = idx0 + 1
		if idx1 >= self.data.frames then
			idx1 = 0
		end
		local v0 = self.data.samples[idx0]
		local v1 = self.data.samples[idx1]
		local w1 = idx - idx0
	
		-- local s = v0 + w1*(v1 - v0)
	
		local w0 = 1 - w1
		local s = v0 * w0 + v1 * w1
	
		-- the filter section:
		-- take the average:
		s = s + self.filter * (s0 - s)
		  --s * 0.9 + s0 * 0.1
	  
		-- overall decay
		s = s * self.decay
	
		-- bowing:
		--s = s + 0.01 * math.random() - 0.5)
		
		-- add noise input:
		s = s + srandom() * self.pluck * 0.1
		self.pluck = self.pluck * 0.99
	
		-- scale down & write back in:
		self.data.samples[self.pos] = s
	
		-- update s0:
		s0 = s
	
	
	
		-- hear it:
		return s
	end)
	
	return self
end


local harp = {}
for i = 1, 16 do
	harp[i] = make_string(100 * i)
end

local count = 0
local which = 1
audio.play(function()
	
	count = count + 1
	if count > samplerate/16 then
		count = 0
		
		local h = harp[which]
		
		h.pluck = 1
		h.filter = 0.5 --(1-math.random())*(1-math.random())
		
		h.freq = h.freq * 2^(1/12)
		if h.freq > 1000 then
			h.freq = h.freq / 4
		end
		
		which = (which % #harp) + 1
	end
	
	
	return 0
end)















