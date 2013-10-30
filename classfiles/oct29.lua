local window = require "window"
window.width = 400
window.height = 400
window:create()
local shader = require "shader"
local vbo = require "vbo"
local gl = require "gl"

local vec2 = require "vec2"

math.randomseed(os.time())

---------------------------------------------------
-- Game State
---------------------------------------------------

-- TODO: put all this inside a single object!

-- Configuration
local config = {
	initial_ball_speed = 0.03,
}

-- One ball
local ball = {
	position 	= vec2(0, 0),
	velocity 	= vec2(0, 0),
	size 		= vec2(0.04, 0.04),
	-- color?
	-- spin?
}

-- Two players
local player1 = {
	position 	= vec2(-0.9, 0),
	velocity 	= vec2(0, 0),
	size 		= vec2(0.04, 0.2),
	score		= 0,
	-- color?
}
local player2 = {
	position 	= vec2( 0.9, 0),
	velocity 	= vec2(0, 0),
	size 		= vec2(0.04, 0.2),
	score		= 0,
	-- color?
}

---------------------------------------------------
-- Game logic
---------------------------------------------------

function new_round()
	print("SCORES", player1.score, player2.score)
	
	-- serve ball: from center of screen
	ball.position:set(0, 0)
	-- with random velocity:
	
	-- TODO: fix bug of low horizontal speed!!!
	ball.velocity:randomize(config.initial_ball_speed)
end

-- gets called every frame:
function update_game()
	-- accumulate (integrate) velocity to position
	ball.position = ball.position + ball.velocity
	
	-- collision detection:
	if ball.position.y > 1 then
		ball.velocity.y = -ball.velocity.y
	elseif ball.position.y < -1 then
		ball.velocity.y = -ball.velocity.y
	elseif ball.position.x > 1 then
		player1.score = player1.score + 1
		
		new_round()
		
	elseif ball.position.x < -1 then
		player2.score = player2.score + 1
		
		new_round()
	
	-- TODO: handle cases of hitting paddles!	
	
	end
end




-- start of the game:
new_round()

---------------------------------------------------
-- Rendering
---------------------------------------------------

-- create a buffer of vertices:
local myvbo = vbo(4)
-- set the positions of the vertices:
myvbo[0].position:set(-1, -1, 0)
myvbo[1].position:set( 1, -1, 0)
myvbo[2].position:set( 1,  1, 0)
myvbo[3].position:set(-1,  1, 0)


local vertexcode = [[

uniform vec2 location;
uniform vec2 scale;

// input attribute:
attribute vec3 position;

varying vec2 xy;

void main() {
	
	vec2 p = location + position.xy * scale;
	
	gl_Position = vec4(p, 0., 1.);
	
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
	
	update_game()

	-- start using the shaderprogram
	--myshader.bind(myshader)
	myshader:bind()
	
	-- bind vertex position to shader attribute:
	myvbo:enable_position_attribute(myshader)
	
	myshader:uniform("scale", 0.01, 1)
	myshader:uniform("location", 0, 0)
	myvbo:draw(gl.QUADS)
	
	myshader:uniform("scale", ball.size.x, ball.size.y)
	myshader:uniform("location", ball.position.x, ball.position.y)
	myvbo:draw(gl.QUADS)
	
	
	myshader:uniform("scale", player1.size.x, player1.size.y)
	myshader:uniform("location", player1.position.x, player1.position.y)
	myvbo:draw(gl.QUADS)
	
	
	myshader:uniform("scale", player2.size.x, player2.size.y)
	myshader:uniform("location", player2.position.x, player2.position.y)
	myvbo:draw(gl.QUADS)
	
	
	-- done:
	myshader:unbind()
end





