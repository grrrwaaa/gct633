
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

local sndfile = require "audio.sndfile"
local mysound = sndfile("mysound.wav", "w")
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

-- define my instrument:
local u1 = makesine(const(10), const(50))
local u2 = adder(const(440), u1)
local u4 = makesine(u2, const(1))

function the_problem()
	return u4()
end

------------------------------------------

for i = 0, duration do 
	mysound:write(the_problem())
end
mysound:close()
--]]