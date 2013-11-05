local window = require "window"
window.width = 400
window.height = 400
window:create()
local shader = require "shader"
local vbo = require "vbo"
local gl = require "gl"

local vec2 = require "vec2"

local audio = require "audio"
local buffer = require "audio.buffer"

math.randomseed(os.time())

---------------------------------------------------
-- Game State
---------------------------------------------------

-- TODO: put all this inside a single object!

-- Configuration
local config = {
	initial_ball_speed = 0.03,
	ball_speedup = 1.1,
	player_speed = 0.04,
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
	sound 		= buffer.load("paddle1.wav"),
	-- color?
}
local player2 = {
	position 	= vec2( 0.9, 0),
	velocity 	= vec2(0, 0),
	size 		= vec2(0.04, 0.2),
	score		= 0,
	sound 		= buffer.load("paddle2.wav"),
	-- color?
}

local bounce = buffer.load("bounce.wav")

---------------------------------------------------
-- Game sound
---------------------------------------------------

function sound_bounce()
	-- TODO
	audio.play(bounce)
end

function sound_hit(player)
	-- TODO
	audio.play(player.sound)
end

function goal()
	local a = 1
	local decay = 1 / 44100
	return function()
		a = a - decay
		local phase = a * 100 * (1-a)
		local saw = phase % 1
		if a > 0 then
			return saw * a * 0.2
		end
	end
end

function sound_goal(player)
	-- TODO
	
	audio.play(goal())
	
end


---------------------------------------------------
-- Game logic
---------------------------------------------------

function new_round()
	print("SCORES", player1.score, player2.score)
	
	-- serve ball: from center of screen
	ball.position:set(0, 0)
	
	-- with random velocity:	
	if math.random(2) == 1 then
		ball.velocity.x = config.initial_ball_speed
	else
		ball.velocity.x = -config.initial_ball_speed
	end
	ball.velocity.y = config.initial_ball_speed * ((math.random()*2)-1)
	
	-- hack:
	--ball.velocity.y = 0
end

-- gets called every frame:
function update_game()

	-- accumulate (integrate) player velocity to position
	player2.position = player2.position + player2.velocity

	-- accumulate (integrate) ball velocity to position
	local new_position = ball.position + ball.velocity
	
	-- collision detection:
	if new_position.y > 1 then
		ball.velocity.y = -ball.velocity.y
		sound_bounce()
		
	elseif new_position.y < -1 then
		ball.velocity.y = -ball.velocity.y
		sound_bounce()
	
	-- TODO: proper line/rect intersection
	elseif ball.position.x < player2.position.x 
	   and new_position.x > player2.position.x 
	   and ball.position.y > player2.position.y - player2.size.y
	   and ball.position.y < player2.position.y + player2.size.y then
		
		sound_hit(player2)
		
		ball.velocity.x = -ball.velocity.x
		
		ball.velocity.y = ball.velocity.y - (ball.position.y - player2.position.y)*(ball.velocity.x / player2.size.y)
		
		ball.velocity = ball.velocity * config.ball_speedup
		new_position = ball.position + ball.velocity
		
	elseif ball.position.x > player1.position.x 
	   and new_position.x < player1.position.x 
	   and ball.position.y > player1.position.y - player1.size.y
	   and ball.position.y < player1.position.y + player1.size.y then
		
		sound_hit(player1)
		
		ball.velocity.x = -ball.velocity.x
		
		ball.velocity.y = ball.velocity.y + (ball.position.y - player1.position.y)*(ball.velocity.x / player1.size.y)
		
		ball.velocity = ball.velocity * config.ball_speedup
		new_position = ball.position + ball.velocity
		
	elseif ball.position.x > 1 then
		player1.score = player1.score + 1
		sound_goal(player1)
		
		new_round()
		return
		
	elseif ball.position.x < -1 then
		player2.score = player2.score + 1
		sound_goal(player2)
		
		new_round()
		return
	end
	
	ball.position = new_position
end

---------------------------------------------------
-- Interaction
---------------------------------------------------

function mouse(event, button, x, y)
	x = x*2-1
	y = y*2-1
	
	if event == "drag" then
		
		-- constrain:
		x = math.min(math.max(x, -1), 0)
		
		player1.position.x = x
		player1.position.y = y
	end
	
	print(event, x, y)
end

function keydown(k)
	if k == 97 then
		-- move up
		player2.velocity.y = config.player_speed
	elseif k == 122 then
		-- move down
		player2.velocity.y = -config.player_speed
	end
	print("keydown", k, string.char(k))
end

function keyup(k)
	if k == 97 then
		-- move up
		player2.velocity.y = 0
	elseif k == 122 then
		-- move down
		player2.velocity.y = 0
	end
	print("keyup", k, string.char(k))
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





