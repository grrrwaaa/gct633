
-- Drum Machine 0.001
-- features:
	-- polyphony
	-- variable tempo
	-- instrument-controlled duration

local audio = require "audio"
local samplerate = 44100
local tempo = 90	-- bpm

function s2samples(s) return s * samplerate end

-- linked list:
function makelist()
	local list = {
		list_next = nil
	}
	return list
end
-- add to start of list
function list_insert(list, object)
	object.list_next = list.list_next
	list.list_next = object
end
-- prev could be the list itself
function list_remove(list, prev, object)
	prev.list_next = object.list_next
end

--[[
local l = makelist()
list_insert(l, { face="happy" })
list_insert(l, { face="sad" })
list_insert(l, { face="shocked" })
list_insert(l, { face="alien" })

local prev = l
local obj = l.list_next
while obj do
	-- do stuff with obj:
	print(obj.face)
	if obj.face == "happy" then
		list_remove(l, prev, obj)
	end
	prev = obj
	obj = obj.list_next
end

print("--- again")

local prev = l
local obj = l.list_next
while obj do
	-- do stuff with obj:
	print(obj.face)
	if obj.face == "happy" then
		list_remove(l, prev, obj)
	end
	prev = obj
	obj = obj.list_next
end
--]]

-- instruments:
-- (functions return sample-making functions)

function sine_osc()
	local phase = 0
	return function(freq)
		phase = phase + freq/samplerate
		return math.sin(math.pi * 2 * phase)
	end
end

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
--audio.play(hihat(0.5), 1)

-- bass: sine low freq (decaying freq) decaying amp
function bass(amp)
	local env = decaying_env(0.2)
	local osc = sine_osc()
	return function()
		local e = env()	-- from 1 to 0
		if e then
			local f = e * 100 + 50	-- from 150 to 50
			return osc(f) * e * amp
		end
	end
end
--audio.play(bass(0.5), 1)


-- snare?

-- pattern:
local pattern = {
	{ start = 0/4,  instr=bass,  amp=0.5, },
	{ start = 3/4,  instr=bass,  amp=0.5, },
	{ start = 6/4,  instr=bass,  amp=0.5, },
	{ start = 12/4, instr=hihat, amp=0.5, },
}
local pattern_length = 4	-- beats


local active_voices = makelist()
--[[
for i = #pattern, 1, -1 do
	local note = pattern[i]
	local voice = { 
		start = note.start,
		sound = note.instr(note.amp),
	}
	list_insert(active_voices, voice)
end
--]]

function drum_machine()
	local output_sample = 0
	
	-- add a new sound?
	if math.random() < 0.0001 then
		local note = pattern[math.random(#pattern)]
		local voice = {
			sound = note.instr(note.amp)
		}
		list_insert(active_voices, voice)
	end

	-- for every playing note
	local prev = active_voices
	local voice = active_voices.list_next
	while voice do
		-- do stuff with voice
		local s = voice.sound()
		if s then
			-- add results to output_sample
			output_sample = output_sample + s
		else
			-- note is finished; remove it
			list_remove(active_voices, prev, voice)
		end
		-- next voice:
		prev = voice
		voice = voice.list_next
	end
	
	return output_sample
end


-- play it forever (or near enough)
audio.play(drum_machine, 1000000000)

















