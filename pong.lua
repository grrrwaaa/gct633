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
-- Game State:
--------------------------------------------------------------------------------

local initial_ball_speed = 0.02
local paddlespeed = initial_ball_speed * 2
local ball_speedup = 1.1

local player1 = {
	location = vec3(-0.9, 0, 0),
	scale = vec3(0.02, 0.2, 0.2),
	velocity = vec3(),
	score = 0,
	auto = true,
}

local player2 = {
	location = vec3(0.9, 0, 0),
	scale = vec3(0.02, 0.2, 0.2),
	velocity = vec3(),
	score = 0,
	auto = true,
}

local ball = {
	location = vec3(0, 0, 0),
	scale = vec3(0.02, 0.02, 0.02),
	velocity = vec3(initial_ball_speed, initial_ball_speed * (math.random() - 0.5)),
}

--------------------------------------------------------------------------------
-- Sounds:
--------------------------------------------------------------------------------

local paddle1 = buffer.load("paddle1.wav")
local paddle2 = buffer.load("paddle2.wav")
local bounce = buffer.load("bounce.wav")

local sin = math.sin
local pi = math.pi

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

function make_phasor(phase)
	local phase = phase or 0
	local freq2rps = pi * 2 / samplerate
	return function(freq)
		phase = phase + freq * freq2rps
		return phase
	end
end

-- pos is 0..1:
function pan(s, pos)
	return s*(1-pos), s*pos
end

function noise() return math.random()*2-1 end

function serve()
	local env = make_env(4)
	local phasor1 = make_phasor()
	local phasor2 = make_phasor()
	local step = 44100 / 8
	local freq = 150
	
	local pattern = { 
		50 * math.random(10),
		50 * math.random(10),
		50 * math.random(10),
	}
	
	return function()
		local e = env()
		if e then
			
			local idx = math.floor(phasor2(2)) % #pattern
			freq = pattern[idx+1]
			
			local s = sin(phasor1(freq))
			return e * (1-e) * s
		end
	end
end

function goal1()
	local phasor1 = make_phasor()
	local phasor2 = make_phasor()
	local phasor3 = make_phasor()
	local x = math.abs(ball.velocity.x) / initial_ball_speed
	local y = math.abs(ball.velocity.y) / initial_ball_speed
	local env = make_env(1 + x + y)
	return function()
		local e = env()
		if e then
			local m = y + sin(phasor2(25 * x * x))*e
			local s = sin(phasor1((x+y)*300 + 300 * m))
			return s * e * 0.5, 0
		end
	end
end

function goal2()
	local phasor1 = make_phasor()
	local phasor2 = make_phasor()
	local phasor3 = make_phasor()
	local y = math.abs(ball.velocity.y) / initial_ball_speed
	local x = math.abs(ball.velocity.x) / initial_ball_speed
	local env = make_env(1 + x + y)
	return function()
		local e = env()
		if e then
			local m = y + sin(phasor2(25 * x * x))*e
			local s = sin(phasor1((x+y)*300 + 300 * m))
			return 0, s * e * 0.5
		end
	end
end

audio.play(serve())

--------------------------------------------------------------------------------
-- Game logic:
--------------------------------------------------------------------------------

function player_update(player)
	-- AI?
	if player.auto then
		if math.random() < 0.1 then
			player.velocity.y = 0
		elseif math.random() < 0.5 then
			if player.location.y < ball.location.y - player.scale.y/2 + 0.5*(math.random() - 0.5) then
				player.velocity.y = paddlespeed
			elseif player.location.y > ball.location.y + player.scale.y/2 + 0.5*(math.random() - 0.5) then
				player.velocity.y = -paddlespeed
			else
				player.velocity.y = 0
			end
		end
	end
		
	-- update paddle position
	player.location:add(player.velocity)
	-- clip at edges:
	player.location:min(1):max(-1)
end

-- update state of game:
function update_game()

	-- update players:
	player_update(player1)
	player_update(player2)
	
	-- calculate next location of ball:
	local next_ball_location = ball.location + ball.velocity
	
	-- test collisions with ball:
	
	-- case 1. vertical edges (bounce)
	if next_ball_location.y < -1 or next_ball_location.y > 1 then
		ball.velocity.y = -ball.velocity.y
		
		next_ball_location.y = next_ball_location.y + ball.velocity.y*2
		
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
		
		audio.play(goal1())
		audio.play(serve())
		
	elseif next_ball_location.x < -1 then
		-- player 2 scores:
		player2.score = player2.score + 1
		print("PLAYER 2 WINS!", player1.score, player2.score)
		-- reset game:
		next_ball_location:set(0, 0, 0)
		ball.velocity:set(initial_ball_speed, initial_ball_speed*(math.random()-0.5), 0)
		
		audio.play(goal2())
		audio.play(serve())
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


-- respond to key press events:
function keydown(k)
	if k == 97 then	-- "a"
		player1.velocity.y = paddlespeed
		player1.auto = false
	elseif k == 122 then -- "z"
		player1.velocity.y = -paddlespeed
		player1.auto = false
	elseif k == 107 then -- "k"
		player2.velocity.y = paddlespeed
		player2.auto = false
	elseif k == 109 then -- "m"
		player2.velocity.y = -paddlespeed
		player2.auto = false
	end
end

-- respond to key release events:
function keyup(k)
	if k == 97 then	-- "a"
		player1.velocity.y = 0
		player1.auto = false
	elseif k == 122 then -- "z"
		player1.velocity.y = 0
		player1.auto = false
	elseif k == 107 then -- "k"
		player2.velocity.y = 0	
		player2.auto = false
	elseif k == 109 then -- "m"
		player2.velocity.y = 0	
		player2.auto = false
	end
end

local usemouse = false

function mouse(event, b, x, y)
	if usemouse then
		player1.velocity.y = 0
		player1.location.y = y*2-1
	elseif event == "down" then 
		usemouse = true
		player1.auto = false
	end
end

--------------------------------------------------------------------------------
-- Graphics:
--------------------------------------------------------------------------------

-- create a buffer of vertices:
local square = vbo(6)
-- set the positions of the vertices:
square[0].position:set(-1, -1, 0)
square[1].position:set( 1, -1, 0)
square[2].position:set(-1,  1, 0)
square[3].position:set( 1,  1, 0)
square[4].position:set( 1, -1, 0)
square[5].position:set(-1,  1, 0)


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
	myshader:uniform("scale", ball.scale.x/2, 1, ball.scale.z)
	myshader:uniform("location", 0, 0, 0)
	square:draw()
	
	myshader:uniform("scale", player1.scale.x, player1.scale.y, player1.scale.z)
	myshader:uniform("location", player1.location.x, player1.location.y, player1.location.z)
	square:draw()
	
	myshader:uniform("scale", player2.scale.x, player2.scale.y, player2.scale.z)
	myshader:uniform("location", player2.location.x, player2.location.y, player2.location.z)
	square:draw()
	
	myshader:uniform("scale", ball.scale.x, ball.scale.y, ball.scale.z)
	myshader:uniform("location", ball.location.x, ball.location.y, ball.location.z)
	square:draw()
	
	-- done:
	myshader:unbind()
end