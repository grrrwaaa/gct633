--- interact with the audio system
-- @module audio

local ffi = require "ffi"
local C = ffi.C

ffi.cdef [[

double av_time();
void av_sleep(double seconds);

typedef struct av_Audio {
	unsigned int blocksize;
	unsigned int frames;	
	unsigned int indevice, outdevice;
	unsigned int inchannels, outchannels;		
	
	double time;		// in seconds
	double samplerate;
	double lag;			// in seconds
	
	// a big buffer for main-thread audio generation
	float * buffer;
	// the buffer alternates between channels at blocksize periods:
	int blocks, blockread, blockwrite, blockstep;
	
	// only access from audio thread:
	float * input;
	float * output;	
	void (*onframes)(struct av_Audio * self, double sampletime, float * inputs, float * outputs, int frames);
	
} av_Audio;

av_Audio * av_audio_get();

// only use from main thread:
void av_audio_start(); 
]]

local lib = ffi.C

local driver = lib.av_audio_get()
assert(driver ~= nil, "problem acquiring audio driver")

local buffer = require "audio.buffer"

local audio = {
	driver = driver,
	
	outbuffer = buffer(driver.blocks * driver.blocksize, driver.outchannels, driver.buffer),
	
	latency = 16, -- 16 blocks of 256 at 44.1kHz is about 100ms.
}

-- to get a lower latency we would need to update() more frequently.
print("audio script latency (seconds)", audio.latency * driver.blocksize / driver.samplerate)

function audio.start()
	if not pcall(lib.av_audio_start) then
		print("unable to start audio")
	end
end
audio.start()

function audio.run(generate)
	if generate then
		local blocksize = driver.blocksize
		local w = driver.blockwrite
		local r = driver.blockread
		local s = driver.blocks
		local t = (r + audio.latency) % driver.blocks
		local done = 0 -- how many blocks produced on this update
	
		if w > t then
			-- fill up & wrap around:
			while w < s do
				local out = driver.buffer + w * driver.blockstep
				for i = 0, blocksize-1 do
					local l, r = generate()
					out[i*2] = l or 0
					out[i*2+1] = r or l or 0
				end
				done = done + 1
				driver.blockwrite = w
				w = w + 1
			end
			w = 0
			driver.blockwrite = w
		end
		while w < t do
			local out = driver.buffer + w * driver.blockstep
			for i = 0, blocksize-1 do
				local l, r = generate()
				out[i*2] = l or 0
				out[i*2+1] = r or l or 0
			end
			done = done + 1
			w = w + 1
			driver.blockwrite = w
		end
		--print(done)
	end
end



local is_audio_runloop_running = false
local voices = {}

local function addvoice(func, dur)

	local voice = {
		dur = dur or math.huge,
	}
	
	function voice:blockfunc(blocksize, out)
		for i = 0, blocksize-1 do
			local l, r = func()
			if l == nil and r == nil then 
				return nil
			end
			out[i*2] = out[i*2] + (l or 0)
			out[i*2+1] = out[i*2+1] + (r or l or 0)
		end
		self.dur = self.dur - blocksize
		return self.dur > 0 or nil
	end
	
	voices[voice] = true
end

local function start_audio_runloop()
	audio.outbuffer.samples = driver.buffer

	local runloop = require "runloop"
	
	runloop.insert(function()
		local blocksize = driver.blocksize
		local w = driver.blockwrite
		local r = driver.blockread
		local s = driver.blocks
		local t = (r + audio.latency) % driver.blocks
		if w > t then
			-- fill up & wrap around:
			while w < s do
				local out = driver.buffer + w * driver.blockstep
				for i = 0, blocksize-1 do
					out[i*2] = 0
					out[i*2+1] = 0
				end		
				for v in pairs(voices) do
					voices[v] = v:blockfunc(blocksize, out)
				end
				driver.blockwrite = w
				w = w + 1
			end
			w = 0
			driver.blockwrite = w
		end
		while w < t do
			local out = driver.buffer + w * driver.blockstep
			for i = 0, blocksize-1 do
				out[i*2] = 0
				out[i*2+1] = 0
			end		
			for v in pairs(voices) do
				voices[v] = v:blockfunc(blocksize, out)
			end
			w = w + 1
			driver.blockwrite = w
		end
	end)
	is_audio_runloop_running = true
end

function audio.start()
	if not is_audio_runloop_running then
		start_audio_runloop()
	end
end

--- Play a function or audio_buffer.
-- @param content The buffer or function to play
-- @param duration seconds to play
function audio.play(content, duration)
	local buffer = require "audio.buffer"
	
	if not is_audio_runloop_running then
		start_audio_runloop()
	end
	
	if type(content) == "number" then
		error("cannot play a number")
	elseif type(content) == "function" then
		
		addvoice(content, duration and driver.samplerate * duration)
		
	elseif buffer.isbuffer(content) then
		
		local count = 0	
		local buf = content
		local chans = buf.channels
		local frames = tonumber(buf.frames)
		if duration then
			frames = math.min(frames, driver.samplerate * duration)
		end
		
		addvoice(function()
			if count < frames then
				local l = buf.samples[count*chans]
				local r = chans > 1 and buf.samples[count*chans+1] or l
				count = count + 1
				return l, r
			end
		end, frames)
	else
		error("bad type for audio.play")
	end
end

-- render the contents of the audio buffer
function audio.scope()
	local gl = require "gl"
	local window = require "window"
	window.width = 400
	window.height = 200
	window.create()
	
	local buf = audio.outbuffer
	local blocks = driver.blocks
	local frames = buf.frames
	local channels = buf.channels
	
	draw = function()
	
		local w = window.width
		local iw = 1/w
		local playphase = audio.driver.blockwrite / blocks
	
		-- set the positions of the vertices:
		gl.Begin(gl.TRIANGLE_STRIP)
		for i = 0, w-1 do
			-- phase (0..1) through sound:
			local phase = i / w
			-- convert to X coordinate (-1..1)
			local x = phase*2-1
		
			-- get start point:
			local first = math.floor(phase * buf.frames)
			-- get number of samples per vertex:
			local count = math.floor(frames * iw)
		
			-- get highest & lowest sample in this period:
			local lo, hi = 1, -1
			for j = first, first+count-1 do
				lo = math.min(lo, buf.samples[j*channels])
				hi = math.max(hi, buf.samples[j*channels])
			end
		
			local g = (playphase - phase) % 1
			g = 0.2 + 0.8*(1-g)*(1-g)
		
			gl.Color(0.2, g, 0.2)
		
			gl.Vertex(x, lo*0.5-0.5, 0)
			gl.Vertex(x, hi*0.5-0.5, 0)
		end
		gl.End()
		
		-- set the positions of the vertices:
		gl.Begin(gl.TRIANGLE_STRIP)
		for i = 0, w-1 do
			-- phase (0..1) through sound:
			local phase = i / w
			-- convert to X coordinate (-1..1)
			local x = phase*2-1
		
			-- get start point:
			local first = math.floor(phase * buf.frames)
			-- get number of samples per vertex:
			local count = math.floor(frames * iw)
		
			-- get highest & lowest sample in this period:
			local lo, hi = 1, -1
			for j = first, first+count-1 do
				lo = math.min(lo, buf.samples[j*channels+1])
				hi = math.max(hi, buf.samples[j*channels+1])
			end
		
			local g = (playphase - phase) % 1
			g = 0.2 + 0.8*(1-g)*(1-g)
		
			gl.Color(0.2, g, 0.2)
		
			gl.Vertex(x, lo*0.5+0.5, 0)
			gl.Vertex(x, hi*0.5+0.5, 0)
		end
		gl.End()
	
		--[[
		gl.Enable(gl.BLEND)
		gl.BlendFunc(gl.SRC_ALPHA, gl.ONE)
	
		gl.Begin(gl.LINE_STRIP)
		local dim = driver.blocksize * driver.blocks * driver.outchannels - 1
		for i = 0, dim, 10 do
			local x = (i / dim)*2-1
			local y = 0.5 + 0.5 * buffer[i]
			gl.Vertex(x, y, 0)
		end
		gl.End()
		--]]
	end
end

return audio