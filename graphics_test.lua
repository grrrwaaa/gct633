local gl = require "gl"
local window = require "window"
local shader = require "shader"

local vertex_code = [[

void main() {
	gl_Position = vec4(gl_Vertex.x, gl_Vertex.y, 0., 1.);
}
]]

local fragment_code = [[

void main() {
	gl_FragColor = vec4(1, 0, 0, 1);
}
]]

local example_shader = shader(vertex_code, fragment_code)

function draw()
	gl.Clear()
	
	example_shader:bind()
	
	gl.Begin(gl.TRIANGLES)
	for i = 1, 12 do
		gl.Vertex(math.random(), math.random(), math.random())
	end
	gl.End()
	
	example_shader:unbind()
end

window:create()