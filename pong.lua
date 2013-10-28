local window = require "window"
window.width = 400
window.height = 400
window:create()

local audio = require "audio"
local buffer = require "audio.buffer"
local samplerate = 44100
audio.start()

local shader = require "shader"
local vbo = require "vbo"
local gl = require "gl"
local vec3 = require "vec3"

--------------------------------------------------------------------------------
-- Sounds:
--------------------------------------------------------------------------------

local cheer1 = buffer.load("cheer1.wav")
local cheer2 = buffer.load("cheer2.wav")
local paddle1 = buffer.load("paddle1.wav")
local paddle2 = buffer.load("paddle2.wav")
local bounce = buffer.load("bounce.wav")

function make_env(dur)
	local decay = 1 / (dur * samplerate)
	local env = 1
	return function(x)
		env = env - decay
		if env > 0 then
			return (x or 1) * env
		end
	end
end

function noise() return math.random()*2-1 end

function paddle_sound1()
	local e = make_env(0.2)
	audio.play(function()
		return e(noise()), 0 
	end)
end

function paddle_sound2()
	local e = make_env(0.2)
	audio.play(function()
		return 0, e(noise())
	end)
end

--------------------------------------------------------------------------------
-- Game logic:
--------------------------------------------------------------------------------

local initial_ball_speed = 0.01
local ball_speedup = 1.1

local player1 = {
	location = vec3(-0.9, 0, 0),
	scale = vec3(0.02, 0.2, 0.2),
	velocity = vec3(),
	score = 0,
}

local player2 = {
	location = vec3(0.9, 0, 0),
	scale = vec3(0.02, 0.2, 0.2),
	velocity = vec3(),
	score = 0,
}

local ball = {
	location = vec3(0, 0, 0),
	scale = vec3(0.02, 0.02, 0.02),
	velocity = vec3(initial_ball_speed, 0.),
}

-- update state of game:
function update_game()
	-- update paddles:
	player1.location:add(player1.velocity)
	player2.location:add(player2.velocity)
	-- clip at edges:
	player1.location:min(1):max(-1)
	player2.location:min(1):max(-1)
	
	-- calculate next location of ball:
	local next_ball_location = ball.location + ball.velocity
	
	-- test collisions with ball:
	
	-- case 1. vertical edges (bounce)
	if next_ball_location.y < -1 or next_ball_location.y > 1 then
		ball.velocity.y = -ball.velocity.y
		
		audio.play(bounce)
	end
	
	-- case 2. horizontal edges (score a goal!)
	if next_ball_location.x > 1 then
		-- player 1 scores:
		player1.score = player1.score + 1
		print("PLAYER 1 WINS!", player1.score, player2.score)
		-- reset game:
		next_ball_location:set(0, 0, 0)
		ball.velocity:set(-initial_ball_speed, initial_ball_speed*(math.random()-0.5), 0)
		
		audio.play(cheer1)
		
	elseif next_ball_location.x < -1 then
		-- player 2 scores:
		player2.score = player2.score + 1
		print("PLAYER 2 WINS!", player1.score, player2.score)
		-- reset game:
		next_ball_location:set(0, 0, 0)
		ball.velocity:set(initial_ball_speed, initial_ball_speed*(math.random()-0.5), 0)
		
		audio.play(cheer2)
	end
	
	-- case 3. ball hits a paddle (bounce)
	if next_ball_location.x > player2.location.x 
	and ball.location.x < player2.location.x 
	and next_ball_location.y < (player2.location.y + player2.scale.y)
	and next_ball_location.y > (player2.location.y - player2.scale.y) then
		-- bounce off paddle:
		ball.velocity.x = -ball.velocity.x * ball_speedup
		-- change y velocity according to where it hit:
        ball.velocity.y = -2 * ball.velocity.x * (next_ball_location.y - player2.location.y) / player2.scale.y
		
		audio.play(paddle2)
		
	elseif next_ball_location.x < player1.location.x 
	and ball.location.x > player1.location.x
	and next_ball_location.y < (player1.location.y + player1.scale.y)
	and next_ball_location.y > (player1.location.y - player1.scale.y) then
		-- bounce off paddle:
		ball.velocity.x = -ball.velocity.x * ball_speedup
		-- change y velocity according to where it hit:
        ball.velocity.y = 2 * ball.velocity.x * (next_ball_location.y - player1.location.y) / player1.scale.y
		
		audio.play(paddle1)
	end
	
	-- update new position:
	ball.location = next_ball_location
end

--------------------------------------------------------------------------------
-- Interaction:
--------------------------------------------------------------------------------

local paddlespeed = 0.02

-- respond to key press events:
function keydown(k)
	if k == 97 then	-- "a"
		player1.velocity.y = paddlespeed
	elseif k == 122 then -- "z"
		player1.velocity.y = -paddlespeed
	elseif k == 107 then -- "k"
		player2.velocity.y = paddlespeed
	elseif k == 109 then -- "m"
		player2.velocity.y = -paddlespeed
	end
end

-- respond to key release events:
function keyup(k)
	if k == 97 then	-- "a"
		player1.velocity.y = 0
	elseif k == 122 then -- "z"
		player1.velocity.y = 0
	elseif k == 107 then -- "k"
		player2.velocity.y = 0	
	elseif k == 109 then -- "m"
		player2.velocity.y = 0	
	end
end

--------------------------------------------------------------------------------
-- Graphics:
--------------------------------------------------------------------------------

-- create a buffer of vertices:
local square = vbo(4)
-- set the positions of the vertices:
square[0].position:set(-1, -1, 0)
square[1].position:set( 1, -1, 0)
square[2].position:set(-1,  1, 0)
square[3].position:set( 1,  1, 0)


local vertexcode = [[
// input uniforms:
uniform vec3 scale;
uniform vec3 location;

// input attribute:
attribute vec3 position;

void main() {
	vec3 p = location + position * scale;
	gl_Position = vec4(p, 1.);
	
}

]]

local fragmentcode = [[

void main() {
	gl_FragColor = vec4(1, 1, 1, 1);
}

]]

-- create a shader program based on the GLSL above:
local myshader = shader(vertexcode, fragmentcode)

-- rendering callback:
function draw()
	-- simulate game at same speed as rendering:
	update_game()

	-- start using the shaderprogram
	--myshader.bind(myshader)
	myshader:bind()
	
	-- bind vertex position to shader attribute:
	square:enable_position_attribute(myshader)
	
	-- let's render!
	myshader:uniform("scale", player1.scale.x, player1.scale.y, player1.scale.z)
	myshader:uniform("location", player1.location.x, player1.location.y, player1.location.z)
	square:draw(gl.TRIANGLE_STRIP)
	
	myshader:uniform("scale", player2.scale.x, player2.scale.y, player2.scale.z)
	myshader:uniform("location", player2.location.x, player2.location.y, player2.location.z)
	square:draw(gl.TRIANGLE_STRIP)
	
	myshader:uniform("scale", ball.scale.x, ball.scale.y, ball.scale.z)
	myshader:uniform("location", ball.location.x, ball.location.y, ball.location.z)
	square:draw(gl.TRIANGLE_STRIP)
	
	-- done:
	myshader:unbind()
end