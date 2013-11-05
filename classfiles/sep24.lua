local audio = require "audio"
local samplerate = 44100

local make_hihat = function(note)
	-- start with envelope amplitude at 1
	local e = 1
	-- convert duration to samples:
	local dur_samples = note.dur * samplerate
	-- reciprocal: step per sample
	local de = 1 / dur_samples
	-- sample function:
	return function()
		-- only decrease if we are above zero:
		if e > 0 then
			-- decrease envelope amplitude:
			e = e - de
		end
		-- noise scaled by envelope
		return math.random() * e * note.amp
	end
end

--local note = { dur=0.9 }
--local hihat = make_hihat(note)
--audio.play(hihat, 1)

local score = {
	-- three notes:
	{ start=0, dur=0.5, amp=0.5, freq=400, instr=make_hihat },
	{ start=0.4, dur=0.5, amp=0.25, freq=500, instr=make_hihat },
	{ start=0.5, dur=0.01, amp=0.25, freq=600, instr=make_hihat },
	{ start=0.6, dur=0.03, amp=0.25, freq=600, instr=make_hihat },
	{ start=0.7, dur=0.05, amp=0.25, freq=600, instr=make_hihat },
	{ start=0.8, dur=0.07, amp=0.25, freq=600, instr=make_hihat },
	{ start=0.9, dur=0.09, amp=0.25, freq=600, instr=make_hihat },
}

local sequencer = function(score)
	-- pre-process the score:
	-- create instruments:
	for key, note in ipairs(score) do
		-- construct the note instruments:
		note.sound = note.instr(note)
	end	
	-- current sample:
	local count = 0
	local out = function()
		-- output sample:
		local output_sample = 0
		-- time in seconds:
		local s = count / samplerate
		-- find out which notes are playing
		for key, note in ipairs(score) do
			-- are we in the bounds of this note?
			if s >= note.start and s < (note.start + note.dur) then
				-- play this notes 
				local note_sample = note.sound()
				-- (mixing into the output):
				output_sample = output_sample + note_sample
			end
		end
		-- time is passing:
		count = count + 1
		-- return the sample value (sum of all notes)
		return output_sample
	end
	local duration = 1
	
	-- finally render it:
	audio.play(out, duration)
end

-- run it!
sequencer(score)