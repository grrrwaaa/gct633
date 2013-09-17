--- Generic container for audio signal data.
-- The module can also be called directly as a function, e.g.: mybuf = audio.buffer(1024, 2)
-- @module audio.buffer

--[[
A generic audio buffer object, whose length is fixed from birth.
Stores a sequence of frames of samples. Each frame has 1 or more channels.
	i.e. multi-channel audio is interleaved. 
64-bit currently.

Uses: 
	- writing audio data to disk.
	- reading audio data from disk.
	- simplifying RtAudio handling
	- passing between ugens
	- generating wavetables
	- using in delay lines

A fancier buffer class would use arr2, then it can support arbitary interleave steps.

Check out ByteArray for ideas. 

--]]

local min, max = math.min, math.max
local format = string.format

local ffi = require "ffi"
ffi.cdef [[

typedef struct audio_buffer {
	int frames, channels;
	double samples [?];
} audio_buffer;

]]


local buffer = {}
buffer.__index = buffer

--- Create a new audio_buffer
-- @tparam int frames The number of frames (sample length) of the buffer
-- @tparam ?int channels The number of channels per frame
function buffer.create(frames, channels) 
	assert(frames and frames > 0, "buffer length (frames) required")
	channels = channels and (max(channels, 1)) or 1
	local buf = ffi.new("audio_buffer", frames*channels, frames, channels)
	return buf
end

local new = buffer.create


--- A sound file class.
-- @type audio_buffer

function buffer:__tostring()
	return format("audio_buffer(%dx%d, %p)", self.frames, self.channels, self)
end

--- Write values into a buffer
-- @tparam function func A function that will be called to set each frame of the buffer.
-- @tparam ?int start The starting index to write data (default 0)
-- @tparam ?int dur The number of frames to write (default all frames of the buffer)
-- @treturn audio_buffer self
function buffer:write(func, start, dur)
	local start = start or 0
	local dur = dur or self.frames
	local chans = self.channels
	-- this is not optimized at all.
	for i = start, dur-1 do
		local idx = i * chans
		local frame = { func() }
		for c = 0, chans-1 do
			self.samples[idx + c] = frame[(c % #frame) + 1]
		end
	end	
	return self
end

--[[
-- TODO buffer methods:

buffer:apply(func)
(plus some standard ones built in:
buffer:zero
buffer:normalize(amp)
buffer:fadeout|in?

buffer.fill(func)
buffer.fill(standard table name)
or buffer[standard table name] lazy constructor?

-- buffer provides only minimal indexing functions;
-- use a sampler (wrapper) for fancier stuff.
buffer:at
buffer:read (interp)

buffer.resample
buffer.setchannels

function buffer:save(filename) end
function buffer.load(filename) end

--]]


ffi.metatype("audio_buffer", buffer)

setmetatable(buffer, {
	__call = function(s, frames, channels)
		return new(frames, channels)
	end,
})


return buffer

