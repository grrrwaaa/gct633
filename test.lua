for i = 0, #arg do
	print(i, arg[i])
end
print("...", ...)


local ffi = require "ffi"
ffi.cdef [[
typedef struct av_Audio {
	unsigned int blocksize;
	unsigned int indevice, outdevice;
	unsigned int inchannels, outchannels;	
	
	double time, lag;		// in seconds
	double samplerate;
	
	// a big buffer for main-thread audio generation
	float * buffer;
	// the buffer alternates between channels at blocksize periods:
	int blocks, blockread, blockwrite, blockstep;	
} av_Audio;


av_Audio * av_audio_get();
void av_audio_start();
]]


local C = ffi.C
A = C.av_audio_get()
C.av_audio_start()

--[[
for i = 0, 1000 do
	A.buffer[i] = math.random()
end
--]]
