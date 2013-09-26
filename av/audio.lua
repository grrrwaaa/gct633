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


local audio = {
	driver = driver,
	
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
				w = w + 1
			end
			w = 0
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
		end
		driver.blockwrite = w
		--print(done)
	end
end

--- Play a function or audio_buffer.
-- @param content The buffer or function to play
-- @param duration seconds to play
function audio.play(content, duration)
	local buffer = require "audio.buffer"
	if type(content) == "number" then
		error("cannot play a number")
	elseif type(content) == "function" then
		local f = content
		local count = 0
		if duration then
			local frames = driver.samplerate * duration
			content = function()
				if count < frames then
					count = count + 1
					return f()
				end
			end
			while count < frames do	
				audio.run(content)
				lib.av_sleep(0.01)
			end
		else	
			-- just run forever:
			while true do
				audio.run(f)
				lib.av_sleep(0.01)
			end
		end
	elseif type(content) == "cdata" and buffer.isbuffer(content) then
		local count = 0	
		local buf = content
		local chans = buf.channels
		local frames = buf.frames
		if duration then
			frames = math.min(frames, driver.samplerate * duration)
		end

		content = function()
			if count < frames then
				local l = buf.samples[count*chans]
				local r = chans > 1 and buf.samples[count*chans+1] or l
				count = count + 1
				return l, r
			else
				return 0
			end
		end
		while count < frames do	
			audio.run(content)
			lib.av_sleep(0.01)
		end
	else
		error("bad type for audio.play")
	end
end

-- render the contents of the audio buffer
function audio.draw()
	local gl = require "gl"
	local buffer = driver.buffer
	
	gl.Enable(gl.BLEND)
	gl.BlendFunc(gl.SRC_ALPHA, gl.ONE)
	
	gl.Begin(gl.LINE_STRIP)
	local dim = driver.blocksize * driver.blocks * driver.outchannels - 1
	for i = 0, dim, 10 do
		local x = i / dim
		local y = 0.5 + 0.5 * buffer[i]
		gl.Vertex(x, y, 0)
	end
	gl.End()
end

return audio