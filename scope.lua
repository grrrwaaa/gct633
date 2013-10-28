local window = require "window"
window:create()

local audio = require "audio"
audio.start()

local shader = require "shader"
local vbo = require "vbo"
local gl = require "gl"

-- create a buffer of vertices:
local myvbo = vbo(2000)


local vertexcode = [[

// input attribute:
attribute vec3 position;

varying vec2 xy;

void main() {
	vec4 p = vec4(position, 1.);
	gl_Position = p;
	
	// pos in [-1,1] -> color in [0,1]
	xy = (gl_Position.xy + 1.)*0.5;
	
}

]]

local fragmentcode = [[

varying vec2 xy;

void main() {
	gl_FragColor = vec4(1., xy, 1.);
}

]]

-- create a shader program based on the GLSL above:
local myshader = shader(vertexcode, fragmentcode)


function testsound()
	local p = 0
	return function()
		p = p + math.pi * 2 * 20 / 44100
		return math.sin(p)
	end
end

audio.play(testsound())

local buf = audio.outbuffer

-- rendering callback:
function draw()

	-- number of frames in buf:
	local frames = buf.frames
	local s = 0
	
	-- set the positions of the vertices:
	for i = 0, myvbo.count-1, 2 do
		-- phase (0..1) through sound:
		local phase = i / myvbo.count
		
		local nextphase = (i+1) / myvbo.count
		
		-- get start point:
		local first = math.floor(phase * buf.frames)
		-- get number of samples per vertex:
		local count = math.floor(buf.frames / myvbo.count)
		
		local lo, hi = 1, -1
		for j = first, first+count-1 do
			lo = math.min(lo, buf.samples[j])
			hi = math.max(hi, buf.samples[j])
		end
		
		myvbo[i  ].position:set(phase*2-1, lo, 0)
		myvbo[i+1].position:set(phase*2-1, hi, 0)
	end
	myvbo.dirty = true

	-- start using the shaderprogram
	--myshader.bind(myshader)
	myshader:bind()
	
	-- bind vertex position to shader attribute:
	myvbo:enable_position_attribute(myshader)
	
	-- let's render!
	myvbo:draw(gl.LINES)
	
	-- done:
	myshader:unbind()
end





