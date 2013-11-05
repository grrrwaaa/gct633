local audio = require "audio"
local samplerate = 44100

local random = math.random
local pi = math.pi
local twopi = pi * 2
local min, max = math.min, math.max
local sin, cos = math.sin, math.cos
local atan, atan2 = math.atan, math.atan2
local exp, pow = math.exp, math.pow
local floor, ceil = math.floor, math.ceil
local log, exp = math.log, math.exp

function decay(t60)
	return exp(-6.91/(t60*freq))
end

local one_over_log_2 = 1 / log(2)
function ftom(f)
	return 69 + 12 * math.log(f / 440) * one_over_log_2
end	

function mtof(m)
	return pow(2, (m-69)/12) * 440
end

function clip(x, lo, hi) return min(max(x, lo), hi) end
function mix(x, y, a) return x + a*(y-x) end

function dcblock()
	local x1, y1 = 0, 0
	return function(input)
		local y = input - x1 + y1*0.9997
		x1 = input
		y1 = y
		return y
	end
end

function counter(init)
	local count = init or 0
	return function(incr, reset, limit)
		if reset and reset ~= 0 then count = 0 end
		count = count + incr
		if limit then count = count % limit end
		return count
	end
end

function latch(init)
	local value = init or 0
	return function(input, control)
		value = (control ~= 0) and input or value
		return value
	end
end

-- generators:
function noise()
	return function()
		return random()*2-1
	end
end

function phasor(initphase)
	local phase = initphase or 0
	return function(freq)
		phase = (phase + freq/samplerate) % 1
		return phase
	end
end

function blsaw()
	-- @see http:--musicdsp.org/archive.php?classid=1#90
	-- DSF parameters:
	local num_partials = 1
	local rolloff, partial_rolloff = 0.25, 0.25
	-- amplitude at Nyquist:
	local amp_at_nyquist = 0.5 -- min=0, max=0.9999
	-- oscillator state:
	local cps, period, phase = 0, 0, 0
	-- lowpass filter state:
	local lpa, lpb = 0, 0
	local lpx1, lpy1 = 0, 0
	local smoothing = 0.0001	
	
	return function(freq)
		-- only update wave parameters at cycle boundaries:
		if phase >= 1 or cps == 0 then
			phase = phase - 1
			-- new cycle, update freq etc.
			-- valid only above zero and below Nyquist:
			cps = clip(freq/samplerate, 0.0001, 0.5)
			period = 1/cps
			local P2 = period/2
			-- number of partials including DC:
			num_partials = 1 + floor(P2) 
			-- roll-off paramters:
			rolloff = pow(amp_at_nyquist, 1/P2)
			partial_rolloff = pow(rolloff, num_partials)
		end

		-- DSF section:
		local beta = twopi * phase
		local beta_n = num_partials * beta
		local cosbeta = cos(beta)
		-- The DSF BLIT is scaled by 1 / period 
		-- to give approximately the same peak-to-peak 
		-- over a wide range of frequencies.
		local n = 1 - 
				  partial_rolloff * cos(beta_n) - 
				  rolloff * (cosbeta - partial_rolloff * cos(beta_n - beta))
		local d = period * (1 + rolloff * (-2 * cosbeta + rolloff))
		-- division can fail only if |a| == 1
		-- subtracting fundamental freq gets rid of DC
		local x = n / d - cps
		-- lowpass filter:
		local omega = atan(pi * smoothing)
		lpa = -(1-omega)/(1+omega)
		lpb = (1-lpb)/2
		local y = lpb * (x + lpx1) - lpa * lpy1
		lpx1 = x
		lpy1 = y
		-- update phase
		phase = phase + cps
		-- post-scale to -0.5..0.5:
		return y * -pi
	end
end

function blsaw1()
	-- @see http://scp.web.elte.hu/papers/synthesis1.pdf
	local avg = 0
	local p = phasor()
	local dc = dcblock()
	return function(freq, feedback)
		feedback = feedback and clip(feedback, 0, 1) or 1
		local phase = p(freq)
		local sphase = phase*2-1
		
		local fn = freq / samplerate	-- normalized freq
		local fb = 54*pow(0.5-fn,6)	-- self oscillation. alt: 13*pow(0.5-fn,4)
		fb = feedback * fb * avg
		
		local x = sin(pi * (sphase + fb))
		local avg1 = mix(x, avg, 0.5)
		
		-- HF boost:
		x = avg1*2.5 - avg*1.5
		avg = avg1
		-- freq-dependent amp compensation:
		x = x*(1 - fn*2)
		x = dc(x)
		return x
	end
end

function blsqr()
	-- @see http://scp.web.elte.hu/papers/synthesis1.pdf
	local avg = 0
	local p = phasor()
	local dc = dcblock()
	return function(freq, feedback)
		feedback = feedback and clip(feedback, 0, 1) or 1
		local phase = p(freq)
		local sphase = phase*2-1
		
		local fn = freq / samplerate	-- normalized freq
		local fb = 54*pow(0.5-fn,6)	-- self oscillation. alt: 13*pow(0.5-fn,4)
		fb = feedback * fb * (-avg*avg)
		
		local x = sin(pi * (sphase + fb))
		local avg1 = mix(x, avg, 0.55)
		
		-- HF boost:
		x = avg1*1.9 - avg*0.9
		avg = avg1
		-- freq-dependent amp compensation:
		x = x*(1 - fn*2)
		x = dc(x)
		return x
	end
end

-- some filters:

function onepole()
	local y0 = 0
	return function(input, cutoff)
		local rps = cutoff * twopi / samplerate
		local a = clip(sin(rps), 0.0000001, 0.99999)
		local y = mix(y0, input, a)
		y0 = y
		return y
	end
end

function lores()
	local y1, y2 = 0, 0
	return function(input, cutoff, res)
		local rps = cutoff * twopi / samplerate
		local a = cos(rps)
		local r = 0.882497*exp(0.125*clip(res, 0, 0.99999))
		local a2 = r*r		
		local a1 = (-2 * a * r)
		local in1 = input * (1 + a1 + a2)
		local out = in1 - ((a1 * y1) + (a2 * y2))
		y2 = y1
		y1 = out
		return out
	end	
end

function svf()
	local d1, d2 = 0, 0
	return function(input, freq, q)
		freq = clip(freq, 1, 20000)
		q = clip(q, 0.5, 100)
		-- parameter conversion:
		local q1 = 1 / q
		local f1 = 2*sin(pi*freq/samplerate)
		-- low, high, band & notch
		local L = d2 + f1*d1
		local H = input - L - q1*d1
		local B = f1 * H + d1
		local N = H+L
		-- store delay:
		d1, d2 = B, L
		-- return lopass, highpass, bandpass, notch:
		return L, H, B, N
	end
end

function biquad(a0, a1, a2, b1, b2)
	a0 = a0 or 0.095
	a1 = a1 or 0
	a2 = a2 or -0.095
	b1 = b1 or -1.8
	b2 = b2 or 0.810
	local x1, x2, y1, y2 = 0, 0, 0, 0
	return function(input)
		local out = ((x2 * a2 + x1 * a1) + input * a0) - (y1 * b1 + y2 * b2)
		y2 = y1
		x2 = x1
		x1 = input
		y1 = out
		return out
	end
end

function crush()
	return function(input, resolution)
		return (floor(input * resolution + 0.5) - 0.5) / resolution
	end
end

function downsample()
	local c = counter()
	local l = latch()
	return function(input, factor)
		return l(input, c(1, 0, factor))
	end
end

function test()
	local n = noise()
	local f = blsqr()
	return function()
		return f(200)
	end
end

audio.play(test(), 1)