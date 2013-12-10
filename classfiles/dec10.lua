window = require "window"
window.width = 500
window.height = 500
window:create()

local vec2 = require "vec2"
local draw2D = require "draw2D"
local audio = require "audio"
local buffer = require "audio.buffer"

----------------------------------------------------
-- State
----------------------------------------------------

local balls = {}

local ballsource = {
	pos = vec2(0, 0),
	radius = 0.04,
	isballsource = true,
}

local lines = {}

local selected = nil

-- constant:
local ballradius = 0.03
local lineradius = 0.02
local gravity = vec2(0, -0.001)

----------------------------------------------------
-- Sound
----------------------------------------------------

function sound_bounce(speed)	
	-- TODO: audio.play(something)
end

----------------------------------------------------
-- Simulation / Interaction
----------------------------------------------------

-- initialize the game:
function reset()
	balls = {}
	surfaces = {}
	selected = nil
	ballsource.pos = vec2(0, 0)
end

local frame = 0

function update()
	frame = frame + 1

	-- for each ball:
	for ball in pairs(balls) do
		-- update forces
		ball.vel:add(gravity)
		
		-- compute position
		local pos = ball.pos + ball.vel
		
		-- check for collisions for each line
		for line in pairs(lines) do
			-- if hit
				-- make sound
				-- recompute position
		end
		
		-- check for leaving world
		if ball.pos.y < -1
		or ball.pos.x < -1
		or ball.pos.x > 1 then
			-- remove from balls set:
			balls[ball] = nil
		end
		
		ball.pos = pos
	end
	
	-- check for new ball generation
	if frame % 30 == 0 then
		local ball = {
			pos = vec2(ballsource.pos.x, ballsource.pos.y),
			vel = vec2(),
		}
		-- add to the "bag" of balls:
		balls[ball] = true		
	end
end

function mouse(event, button, x, y)
	x = x * 2 - 1
	y = y * 2 - 1
	
	-- if down:
	if event == "down" then
		-- collision test:
			-- check all lines
				-- if hit, mark selected
			-- check ballgenerator
				-- if hit, mark selected
		-- else:
			-- start new line
			local line = {
				p1 = vec2(x, y),
				p2 = vec2(x, y),
			}
			lines[line] = true
			-- mark selected:
			selected = line
	-- if drag / up:
	elseif event == "drag" or event == "up" then
		-- modify selected line OR ballgenerator
		if selected.isballsource then
			-- ballsource
			selected.pos:set(x, y)
		else
			-- line
			selected.p2:set(x, y)
		end
	end
end

-- TODO: delete a line

function key(k)
	-- TODO: delete all lines / balls
end

----------------------------------------------------
-- Rendering
----------------------------------------------------

function draw()
	-- update the game:
	update()

	-- draw generator:
		-- draw hollow circle
	draw2D.push()
		draw2D.translate(ballsource.pos.x, ballsource.pos.y)
		draw2D.color(1, 1, 1)
		draw2D.circle(0, 0, ballsource.radius)
		draw2D.color(0, 0, 0)
		draw2D.circle(0, 0, ballsource.radius * 0.75)
	draw2D.pop()

	-- for each ball:
	for ball in pairs(balls) do
		-- draw circle
		draw2D.push()
			draw2D.translate(ball.pos.x, ball.pos.y)
			draw2D.color(1,1,1)
			draw2D.circle(0, 0, ballradius)
		draw2D.pop()
	end
	
	-- for each line:
	for line in pairs(lines) do
		-- draw line
		draw2D.line(
			line.p1.x, line.p1.y,
			line.p2.x, line.p2.y
		)
		-- draw endpoint circles
		draw2D.circle(line.p1.x, line.p1.y, lineradius)
		draw2D.circle(line.p2.x, line.p2.y, lineradius)
	end
end

----------------------------------------------------
-- Boot sequence:
----------------------------------------------------

-- start the game:
reset()















