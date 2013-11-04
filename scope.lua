local window = require "window"
window:create()

local audio = require "audio"
audio.start()

local shader = require "shader"
local vbo = require "vbo"
local gl = require "gl"

-- create a buffer of vertices:
local myvbo = vbo(4000)


local vertexcode = [[

// input attribute:
attribute vec3 position;
attribute vec4 color;

varying vec4 C;

void main() {
	vec4 p = vec4(position, 1.);
	gl_Position = p;
	
	C = color;
}

]]

local fragmentcode = [[
varying vec4 C;

void main() {
	gl_FragColor = C;
}

]]

-- create a shader program based on the GLSL above:
local myshader = shader(vertexcode, fragmentcode)


function testsound()
	local p = 0
	return function()
		p = p + math.pi * 2 * 3 / 44100-- + (math.random()-0.5)*10 / 44100
		local s = math.sin(p)
		return s * math.sin(s * p * p), s * math.sin(s * p * (p-1))
	end
end

audio.play(testsound())

local buf = audio.outbuffer

-- rendering callback:
function draw()

	gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE)

	-- number of frames in buf:
	local frames = buf.frames
	local channels = buf.channels
	local w = 1000 --window.width
	
	local playphase = audio.driver.blockwrite / audio.driver.blocks
	
	-- set the positions of the vertices:
	for i = 0, w-1 do
		-- phase (0..1) through sound:
		local phase = i / w
		-- convert to X coordinate (-1..1)
		local x = phase*2-1
		
		-- get start point:
		local first = math.floor(phase * buf.frames)
		-- get number of samples per vertex:
		local count = math.floor(frames / w)
		
		-- get highest & lowest sample in this period:
		local lo, hi = 1, -1
		for j = first, first+count-1 do
			lo = math.min(lo, buf.samples[j*channels])
			hi = math.max(hi, buf.samples[j*channels])
		end
		
		
		myvbo[i*2  ].position:set(x, lo, 0)
		myvbo[i*2+1].position:set(x, hi, 0)
		
		local g = (playphase - phase) % 1
		g = 0.2 + 0.8*(1-g)*(1-g)
		
		myvbo[i*2  ].color:set(0.2, g, 0.2, 1)
		myvbo[i*2+1].color:set(0.2, g, 0.2, 1)
	end
	myvbo.dirty = true

	-- start using the shaderprogram
	--myshader.bind(myshader)
	myshader:bind()
	
	-- bind vertex position to shader attribute:
	myvbo:enable_position_attribute(myshader)
	myvbo:enable_color_attribute(myshader)
	
	-- let's render!
	myvbo:draw(gl.TRIANGLE_STRIP, 0, w*2)
	
	-- done:
	myshader:unbind()
end





