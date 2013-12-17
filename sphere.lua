local window = require "window"
window.width, window.height = 400, 400
window:create()

local gl = require "gl"
local glu = require "glu"
local vec3 = require "vec3"
local mat4 = require "mat4"
local displaylist = require "displaylist"

local sin, cos, pi = math.sin, math.cos, math.pi


local t = 0

-- a function to generate a sphere:
function sphere()
	local stepsize = 0.05
	for j = 0, 1, stepsize do
		gl.Begin(gl.QUAD_STRIP)
		for i = -1, 1+stepsize, stepsize do
			local a = sin(j * pi)
			local b = cos(j * pi)
			
			local x = a * sin(i * pi)
			local y = a * cos(i * pi)
			local z = b
			local n = vec3(x, y, z):normalize()
			gl.Color(n.x, n.y, n.z)
			gl.Normal(n.x, n.y, n.z)
			gl.Vertex(x, y, z)
			
			local j1 = j + stepsize
			
			local a = sin(j1 * pi)
			local b = cos(j1 * pi)
			
			local x = a * sin(i * pi)
			local y = a * cos(i * pi)
			local z = b
			local n = vec3(x, y, z):normalize()
			gl.Color(n.x, n.y, n.z)
			gl.Normal(n.x, n.y, n.z)
			gl.Vertex(x, y, z)
		end
		gl.End()
	end
end

-- create a re-usable function to draw a sphere
-- (this happens on the GPU, much faster)
local spherelist = displaylist(sphere)

function draw()
	-- time moves on:
	t = t + 1
	
	-- set up the camera projection properties:
	gl.MatrixMode(gl.PROJECTION)
	gl.LoadIdentity()
	glu.Perspective(80, window.width/window.height, 0.1, 10)
	
	-- set up the camera position & orientation:
	gl.MatrixMode(gl.MODELVIEW)
	gl.LoadIdentity()
	glu.LookAt( 
		-- eye position:
		0, 0, 2, 
		-- look at position:
		0, 0, 0, 
		-- up direction:
		0, 1, 0
	)
	
	-- set up GL state:
	gl.Enable(gl.DEPTH_TEST)
	
	for id = 1, 10 do
		-- draw our object:
		gl.PushMatrix()
			
			-- position, rotation & scale of the object:
			gl.Translate(
				sin(id + t*0.02), 
				cos(id + t*0.02),
				cos(id - t*0.02)*sin(id + t*0.02)
			)
			gl.Rotate(id*90 + t * 0.5, 1, 1, 0)	
			gl.Scale(0.2, 0.5, 0.1)
		
			-- draw it:
			--sphere()
			spherelist:draw()
		
		gl.PopMatrix()
	end
end