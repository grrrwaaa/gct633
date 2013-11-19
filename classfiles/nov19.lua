local audio = require "audio"
local buffer = require "audio.buffer"
audio.start()

local go = audio.go
local wait = audio.wait
local now = audio.now
local play = audio.play

local clap1 = buffer.load("paddle1.wav")
local clap2 = buffer.load("paddle2.wav")
local qn = 1/8

function clap(sound)
	wait(math.random() * 0.015)
	play(sound)
end

function nlet(sound, n, r)
	for i = 1, n do
		go(clap, sound)
		wait(qn)		
	end
	for i = 1, r do
		wait(qn)
	end
end

function clapper(sound, shifter)
	while true do
		for i = 1, 4 do
			nlet(sound, 3, 1)
			nlet(sound, 2, 1)
			nlet(sound, 1, 1)
			nlet(sound, 2, 1)
		end		
		if shifter then
			wait(qn)
		end	
	end
end

go(clapper, clap1, false)
go(clapper, clap2, true)

audio.scope()



