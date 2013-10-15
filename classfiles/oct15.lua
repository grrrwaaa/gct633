local window = require "window"
window:create()
local shader = require "shader"
local vbo = require "vbo"

-- create a buffer of vertices:
local myvbo = vbo(3)
-- set the positions of the vertices:
myvbo[0].position:set(-1, -1, 0)
myvbo[1].position:set( 1, -1, 0)
myvbo[2].position:set( 0,  1, 0)


local vertexcode = [[

// input attribute:
attribute vec3 position;

varying vec2 xy;

void main() {
	gl_Position = vec4(position.x, position.y, 0., 1.);
	
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

-- rendering callback:
function draw()
	-- start using the shaderprogram
	--myshader.bind(myshader)
	myshader:bind()
	
	-- bind vertex position to shader attribute:
	myvbo:enable_position_attribute(myshader)
	
	-- let's render!
	myvbo:draw()
	
	-- done:
	myshader:unbind()
end





