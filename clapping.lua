--[[
An attempt to implement Steve Reich's "Clapping Music"
--]]

local audio = require "audio"
local buffer = require "audio.buffer"

local go, wait, now, event = audio.go, audio.wait, audio.now, audio.event

-- load up some clap sounds:
local p1 = buffer.load("paddle1.wav")
local p2 = buffer.load("paddle2.wav")

local dur = 1/8

-- clap N times:
function claps(sound, n)
	for i = 1, n do
		-- humanize:
		local jitter = math.random() * 0.01
		-- run the clap sound as another sub-process independent of main time:
		go(jitter, audio.play, sound)
		-- note length:
		wait(dur)
	end
end

function rest()
	wait(dur)
end

-- this is the main pattern that is repeated over and over by each player:
function pattern(sound)
	claps(sound, 3)
	rest()
	claps(sound, 2)
	rest()
	claps(sound, 1)
	rest()
	claps(sound, 2)
	rest()
end

-- the process of each player:
function clapper(sound, shift)
	while true do
		for i = 1, 4 do
			pattern(sound)
		end
		if shift then rest() end
	end
end

-- player 1 does not shift:
go(clapper, p1, false)
-- player 2 shifts:
go(clapper, p2, true)

-- turn audio on:
audio.start()
