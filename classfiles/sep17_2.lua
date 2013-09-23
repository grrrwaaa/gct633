local samplerate = 44100

-- define the unit generators:
-- a sine oscillator:
function makesine(freq, mul)
	local angle = 0
	return function(env)
		angle = angle + freq(env)/samplerate
		return mul(env) * 
				math.sin(math.pi * 2 * angle)
	end
end

-- a signal adder:
function adder(a, b)
	return function(env)
		return a(env) + b(env)
	end
end

-- a constant:
function const(n)
	return function()
		return n
	end
end

-- a parameter:
function param(name)
	return function(env)
		return env[name]
	end
end

------------------------------------------
local audio = require "audio"

-- define my soundument:
function beep()
	local u1 = makesine(const(10), const(50))
	local u2 = adder(param("freq"), u1)
	return makesine(u2, param("amp"))
end

-- define my score:
local score = {
	{ at=0, 	dur=1, 		sound=beep(),	freq=440, amp=0.5 },
	{ at=0.2, 	dur=0.5, 	sound=beep(), 	freq=660, amp=0.3 },
	{ at=0.5, 	dur=1, 		sound=beep(),	freq=880, amp=0.3 },
	{ at=0.7, 	dur=0.5, 	sound=beep(), 	freq=770, amp=0.2 },
}

function sequencer(score)
	-- figure out how long our score is:
	local lastnote = score[#score]
	local dur = lastnote.at + lastnote.dur
	local dur_samples = dur * samplerate
	
	-- s is the current score time in seconds:
	local s = 0
	-- it increases by this amount per sample:
	local samples_per_second = 1 / samplerate
	-- a function to pass to audio.play:
	local play = function()
		-- sum all outputs to one result:
		local result = 0
		-- for each note
		for i, note in ipairs(score) do
			-- are we in this note's window of time?
			if note.at <= s and note.at + note.dur > s then
				-- then add the note output:
				result = result + note:sound()
			end
		end
		-- time moves on
		s = s + samples_per_second
		-- return the overlap-added total for this sample:
		return result
	end
	-- now play it:
	audio.play(play, dur_samples)
end

sequencer(score)

------------------------------------------
--[[
local sndfile = require "audio.sndfile"
local duration = 44100
local mysound = sndfile("mysound.wav", "w")
for i = 0, duration do 
	mysound:write(out())
end
mysound:close()
--]]