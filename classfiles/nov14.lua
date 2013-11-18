local audio = require "audio" 
local buffer = require "audio.buffer"
local samplerate = 44100

-- generate random number in (-1,1) range:
function srandom()
	return math.random()*2-1
end

-- linear interpolate between x0 and x1 by factor w:
function lerp(x0, x1, w)
	return x0 + w * (x1 - x0)
end

-- lerp from a buffer:
function buffer_lerp(buffer, idx)
	-- convert to nearest integer indices:
	local idx0 = math.floor(idx)
	local idx1 = (idx0 + 1) % buffer.frames
	-- get values of buffer at these indices:
	local v0 = buffer.samples[idx0]
	local v1 = buffer.samples[idx1]
	-- compute weight:
	local w1 = idx - idx0
	-- interpolate:
	return lerp(v0, v1, w1)
end

function make_averager()
	local s0 = 0
	return function(s, filter)
		local s = lerp(s, s0, filter)
		s0 = s
		return s
	end
end

function make_sineosc()
	local phase = 0
	return function(freq)
		phase = phase + freq / samplerate
		return math.sin(math.pi * 2 * phase)
	end
end

function make_string(freq)

	local self = {
		-- create a 1 second block of sample memory:
		data = buffer(44100),
		-- set the initial position to zero:
		pos = 0,
		-- set the delay period:
		period = samplerate / freq,
		
		filter = 0.1,
		
		decay = 0.999,
		
		averager = make_averager(),
		
		-- vibrato:
		vibrato = make_sineosc(),
		vib_freq = 4,
		vib_depth = 0.5,
		
		-- tremelo:
		tremelo = make_sineosc(),
		trem_freq = 6,
		trem_depth = 0.5,
		
		-- pluck input:
		pluck = 0,
		
		pan = math.random(),
	}
	
	audio.play(function()
		-- move write head on:
		self.pos = (self.pos + 1) % self.data.frames
		
		local period = self.period
		
		-- vibrato:
		period = period + self.vib_depth * self.vibrato(self.vib_freq)
		
		-- get read point:
		local idx = (self.pos - period) % self.data.frames
		
		-- read from buffer:
		local s = buffer_lerp(self.data, idx)
	
		-- the filter section:
		s = self.averager(s, self.filter)
		
		-- overall decay
		s = s * self.decay
	
		-- add noise input:
		s = s + srandom() * self.pluck * 0.5
		self.pluck = self.pluck * 0.99
	
		-- write back in:
		self.data.samples[self.pos] = s
		
		-- tremelo:
		s = s + s * self.trem_depth * self.tremelo(self.trem_freq)
		
	
		-- hear it:
		return s * self.pan, s * (1-self.pan)
	end)
	
	return self
end


local harp = {}
for i = 1, 50 do
	harp[i] = make_string(25 * (i + srandom() * 0.01))
end

function strum()
	local id = math.random(#harp)
	
	local strength = math.random()
	local vf = math.random(10)
	local tf = math.random(10)
	
	local count = 10
	for i = 1, count, math.random(3) do
		
		local h = harp[id + i]
		if h ~= nil then
			h.pluck = strength
			h.filter = math.random()
		
			h.vib_freq = vf
			h.trem_freq = tf
		
			audio.wait(1/(5*math.random(5)))	
		end	
	end	
end	

function player()
	while true do
		audio.go(strum)
		
		audio.wait(1/2 * math.random(4))
	end
end

audio.go(player)
audio.go(player)


audio.scope()












