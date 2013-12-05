local window = require "window"
window.width = 400
window.height = 400
window:create()

local vec2 = require "vec2"
local draw2D = require "draw2D"

local gravity = vec2(0, -0.001)

local wind = function(pos)
	return vec2(0.01 * -pos.x, 0) + vec2.random(0.001)
end

local agent = {}

agent.update = function(self)
	
	self.acc:add(gravity)
	
	-- air friction:
	local speed = #self.vel
	local drag = (-self.vel):normalize()
			   * 2 * speed * speed
	self.acc:add(drag)
	
	-- self:add( wind(self.pos) )

	self.vel:add(self.acc)
	self.pos:add(self.vel)
	-- done with forces:
	self.acc:set(0, 0)
	
	-- constraint:
	if self.pos.y < -1 then
		self.pos.y = -1
		
		local bounce = vec2(0, 1) 
					 * 2 * -self.vel.y
		self.acc:add(bounce)	
	
	elseif self.pos.x > 1 
	or self.pos.x < -1 then
		self.vel:set(0, 0)
		self.pos:set(self.initialpos.x, self.initialpos.y)
	end
end

agent.draw = function(self)
 	draw2D.circle(self.pos.x, self.pos.y, 0.1)
end

local agents = {}
for i = 1, 1 do
	local x = -1 + i/5
	agents[i] = {
		pos = vec2(x, 0),
		vel = vec2(),
		acc = vec2(),
		mass = 0.1,
		
		update = agent.update,
		draw = agent.draw,
	}
	
	agents[i].initialpos = vec2(agents[i].pos)
end

function mouse(event, button, x, y)
	--print(event, button, x, y)
	if event == "down" then
		local jump = vec2(0, 0.1)
		agents[1].acc:add(jump)
	end
end

function draw()
	for i = 1, #agents do
		--agent.update(agent)	
		agents[i]:update()
		--agent.draw(agent)
		agents[i]:draw()
	end
end




























