
--[[
function make_counter()
	local i = 0
	local counter = function()
		i = i + 1
		return i
	end
	return counter
end

counter1 = make_counter()
counter2 = make_counter()

print(counter1, counter2)
print(counter1())
print(counter2())
print(counter1())
print(counter2())
print(counter2())
print(counter1())
--]]

local audio = require "audio"
local duration = 44100
local samplerate = 44100

-- define the unit generators:
-- a sine oscillator:
function makesine(freq, mul)
	local angle = 0
	return function()
		angle = angle + freq()/samplerate
		return mul() * 
				math.sin(math.pi * 2 * angle)
	end
end

-- a signal adder:
function adder(a, b)
	return function()
		return a() + b()
	end
end

-- a constant:
function const(n)
	return function()
		return n
	end
end

------------------------------------------

-- define my instrument:
local u1 = makesine(const(5), const(50))
local u2 = adder(const(440), u1)
local out = makesine(u2, const(1))

-- play one second of 
audio.play(out, 1)

------------------------------------------
--[[
local sndfile = require "audio.sndfile"
local mysound = sndfile("mysound.wav", "w")
for i = 0, duration do 
	mysound:write(out())
end
mysound:close()
--]]