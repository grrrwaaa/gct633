-- create the window first (important on Windows):
local window = require "window"
window:create()

print("created window")

-- load in the OpenGL library:
local gl = require "gl"

print("found gl")

-- and two helper modules to make working with OpenGL easier:
local shader = require "shader"
local vbo = require "vbo"

-- here is some GLSL vertex shader code:
local vertex_code = [[
attribute vec4 position;
attribute vec4 color;
varying vec4 fragcolor;

void main() {
	gl_Position = vec4(position.x, position.y, 0., 1.);
	fragcolor = color;
}
]]

-- here is some GLSL fragment shader code:
local fragment_code = [[
varying vec4 fragcolor;

void main() {
	gl_FragColor = fragcolor;
}
]]

-- here we bind the two shader code chunks into a shader program:
local shader_program = shader(vertex_code, fragment_code)

-- create a VBO object to store vertex position and color data
-- this vbo contains 15 vertices (5 triangles):
local vertices = vbo(15)
for i = 0, vertices.count-1 do
	vertices[i].position:set(
		(i/vertices.count)*2-1, 	-- X
		math.random()*2-1, 			-- Y
		math.random()*2-1)			-- Z
	vertices[i].color:set(
		math.random(), 				-- red
		math.random(), 				-- green
		math.random()				-- blue
	)
end

function draw()
	-- from time to time, modify the VBO data:
	if math.random() < 0.1 then
		vertices[math.random(vertices.count)-1].position:set(math.random(), math.random(), math.random())
		-- mark the object as modified, so that it will be submitted to the GPU:
		vertices.dirty = true
	end
	
	-- start using the shader_program:
	shader_program:bind()
	
	-- tell the shader_program where to find the 
	-- 'position' and 'color' attributes 
	-- when looking in the vertices VBO:
	-- (also sends the data to GPU if marked as dirty)
	vertices:enable_position_attribute(shader_program)
	vertices:enable_color_attribute(shader_program)
	
	-- render using the data in the VBO:
	-- (using gl.TRIANGLES by default)
	vertices:draw()
	
	-- detach the shader_program attributes:
	vertices:disable_position_attribute(shader_program)
	vertices:disable_color_attribute(shader_program)
	
	-- detach the shader:
	shader_program:unbind()
end
