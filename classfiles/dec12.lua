window = require "window"
window.width = 300
window.height = 300
window:create()

local vec2 = require "vec2"
local draw2D = require "draw2D"
local audio = require "audio"
local buffer = require "audio.buffer"
local samplerate = 44100

local sin = math.sin
local pi = math.pi

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

function sound_bounce(speed, ub)	
	local spd = speed * 50
	local dur = 20000
	local t = 0
	local phase = 0
	local amp = (ub - 0.5)
	local boing = function()
		t = t + 1
		if t < dur then
			local x = t / dur
			local mod = sin(2 * pi * x * spd)
			local env = (1-x)^3 * (1 + 0.5*mod)
			local freq = spd * (300 + x*1200) + mod * 300
			phase = phase + freq/samplerate
			return amp * env * sin(pi * 2 * phase)
		end
	end
	
	audio.play(boing)
end

----------------------------------------------------
-- Simulation / Interaction
----------------------------------------------------

-- initialize the game:
function reset()
	balls = {}
	lines = {}
	selected = nil
	ballsource.pos = vec2(0, 0.8)
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
			
			-- friendly terminology:
			local x1, y1 = ball.pos.x, ball.pos.y
			local x2, y2 = pos.x, pos.y
			local x3, y3 = line.p1.x, line.p1.y
			local x4, y4 = line.p2.x, line.p2.y
			
			-- see http://grrrwaaa.github.io/gct633/interaction.html
			local denom = 
			(y4-y3) * (x2-x1) - (x4-x3) * (y2-y1)
			
			-- if denom == 0 lines are parallel (or coincident)
			if denom ~= 0 then
				local numera = (x4-x3)*(y1-y3)-(y4-y3)*(x1-x3)
				local numerb = (x2-x1) * (y1-y3) - (y2-y1) * (x1-x3)
				
				local ua = numera / denom
				local ub = numerb / denom
				
				-- if ua in [0,1] and if ub in [0,1] then segments intersect:
				if ua >= 0 and ua <= 1 
				and ub >= 0 and ub <= 1 then
					
					-- intesection point:
					local I = ball.pos + ua*ball.vel
					-- remaining distance to move:
					local speed = #ball.vel
					local remain = speed * (1-ua)
					
					-- get normal:
					local N = line.normal
					-- get R1:
					local Ri = ball.vel:normalizenew()
					
					-- get reflection:
					local Rr = Ri - 2*N*(Ri:dot(N))
					
					-- new position:
					pos = I + Rr * remain
					-- new velocity
					ball.vel = Rr * speed
					
					-- make sound
					sound_bounce(speed, ub)
				end
			end
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
		
		local m = vec2(x, y)
		-- check ballgenerator:
		local rel = m - ballsource.pos
		if #rel < ballsource.radius then
			print("ballsource!")
			-- if hit, mark selected
			selected = ballsource
			
		else
			-- check all lines
			for line in pairs(lines) do	
				local rel = m - line.p2
				-- if hit, mark selected
				if #rel < lineradius then
					selected = line
				else
					rel = m - line.p1
					if #rel < lineradius then
						line.p1, line.p2 = line.p2, line.p1
						-- Also recalculate normal
						selected = line
					end
				end
			end
			
			if selected == nil then
				-- start new line
				local line = {
					p1 = vec2(x, y),
					p2 = vec2(x, y),
				}
				lines[line] = true
				-- mark selected:
				selected = line
			end
		end
	-- if drag / up:
	elseif event == "drag" or event == "up" then
		-- modify selected line OR ballgenerator
		if selected.isballsource then
			-- ballsource
			selected.pos:set(x, y)
		else
			-- line
			local line = selected
			line.p2:set(x, y)
			-- calculate normal:
			local slope = (line.p2 - line.p1)
			local n = vec2(slope.y, -slope.x)
			n:normalize()
			-- store it:
			line.normal = n
		end
	end
	
	if event == "up" then
		selected = nil
	end
end

-- TODO: delete a line

function keydown(k)
	-- TODO: delete all lines / balls
	reset()
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
	draw2D.color(1, 1, 1)
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















