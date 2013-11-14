local audio = require "audio" 
local buffer = require "audio.buffer"
local samplerate = 44100

math.randomseed(os.time())

-- generate random number in (-1,1) range:
function srandom()
	return math.random()*2-1
end

-- linear interpolator for buffer:
function buffer_lerp(buf, idx)
	-- make sure it is in range:
	local idx = idx % buf.frames	
	-- get integer position before
	local idx0 = math.floor(idx)
	-- get integer position after (and ensure it is in range)
	local idx1 = (idx0 % buf.frames) + 1
	-- read buffer at these locations:
	local v0 = buf.samples[idx0]
	local v1 = buf.samples[idx1]
	-- get interpolation weights:
	local w1 = idx - idx0
	local w0 = 1 - w1
	-- return weighted average:
	return v0 * w0 + v1 * w1
end

-- simple linear stereo pan:
function pan(pos, val)
	-- looks similar to interp...
	return pos*val, (1-pos)*val
end

-- simple running average filter (one pole):
function make_running_averager()
	local y0 = 0
	return function(w, x)
		-- take the average:
		local y = x + w * (y0 - x)
		y0 = y
		return y
	end
end

-- simple sine oscillator:
function make_sinosc(phase)
	local phase = phase or 0
	local twopi = math.pi * 2
	return function(freq)
		phase = phase + freq/samplerate
		return math.sin(phase * twopi)
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
		
		-- vibrato section:
		vibrato_osc = make_sinosc(math.random()),
		vibrato_depth = 0.1,
		vibrato_freq = 1,
		
		-- excitation section:
		pluck = 0,
		pluck_decay = 0.995,
		bow = 0,
		
		-- filter section:
		filter = 0.1,
		avg_filter = make_running_averager(),		
		-- global decay:
		decay = 0.999,
		
		-- tremelo section:
		tremelo_osc = make_sinosc(),
		tremelo_depth = 0.8,
		tremelo_freq = 8,
		
		-- spatial position:
		pan = math.random(),
	}
	
	-- the string sample-making function:
	audio.play(function()

		-- move write head on:
		self.pos = (self.pos + 1) % self.data.frames
		
		-- vibrato effect:
		local vib = self.vibrato_depth * self.vibrato_osc(self.vibrato_freq)
		
		-- get read point:
		local idx = self.pos - self.period * (1 + vib)
		
		-- linear interpolation:
		local s = buffer_lerp(self.data, idx)
	  
		-- frequency-independent decay:
		s = s * self.decay
	
		-- bowing:
		s = s + self.bow * (math.random() - 0.5)
		
		-- add noise input:
		s = s + srandom() * self.pluck * 0.1
		self.pluck = self.pluck * self.pluck_decay
	
		-- the filter section:
		s = self.avg_filter(self.filter, s)
	
		-- write back in:
		self.data.samples[self.pos] = s
		
		local trem = 1 + self.tremelo_depth * self.tremelo_osc(self.tremelo_freq)
	
		-- hear it:
		return pan(self.pan, s * trem)
	end)
	
	-- return the string object:
	return self
end

-- create a harp (a collection of strings):
local harp = {}
for i = 1, 20 do	
	-- a bit of realism... the tuning of strings isn't perfect:
	local detune = 1 + srandom() * 0.01	
	-- base frequency:
	local freq = 150 * 2^(i/12) * detune
	-- create ith string:
	harp[i] = make_string(freq)
end

-- play a sequence of notes with a short delay between:
function strum(player, bunch)
	local filter = math.random()
	local vibrato_freq = math.random(4)*math.random(4)
	local vibrato_depth = 0.1*math.random()^10
	local tremelo_freq = math.random(8)
	local bow = 0.01 * math.random()^100
	
	local dur = 1 / (math.random(4)*math.random(4)*math.random(4))
	
	local first = math.random(#harp/2)
	local step = math.random(4)*math.random(3)
	
	local amp = 0.5 + math.random()
	
	for i = 1, bunch do

		local h = harp[first + i * step]
		if h then
			print("player strum", player, i)
			h.pluck = 4 * amp * (1 + 0.1*srandom())
			h.filter = filter
			h.vibrato_freq = vibrato_freq
			h.vibrato_depth = vibrato_depth
			h.tremelo_freq = tremelo_freq
			h.bow = bow
		
			-- strum:
			audio.wait(dur)
		end
	end
end

function pick(player, period)
	while true do	
		audio.wait(period * math.random(4) / 2)
		
		audio.go(strum, player, period)
	end
end

-- run several parallel processes:
audio.go(pick, "a", 2)
audio.go(pick, "b", 4)
audio.go(pick, "c", 16)

audio.scope()














