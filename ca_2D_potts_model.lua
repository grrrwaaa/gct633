-- load in the "greys2D" library module (from /modules/greys2D.lua):
local field2D = require "field2D"


local random = math.random
local exp = math.exp

--[[

Each site (cell) can belong to a particular cell-class, with a unique ID.

Energy differentials/potentials exist between cells of different classes. Between cells of the same class, there is no energy difference.

Monte Carlo: At each step, choose a site at random, and choose a neighbor at random.
The deltaH is calculated for the case where the cell changes to the type of the neighbor.
The site will turn into the neigbor if:
	deltaH <= 0
or
	e^(-deltaH/kT)
where deltaH is the change in energy if the copying were to occur.
--]]

-- choose the size of the greys
local dimx = 400
local dimy = dimx * 3/4 -- (with a 4:3 aspect ratio)

-- at higher temperatures, the cells are more likely to change *against* the entropy gradient
-- at lower temperatures the world is more stable
local temperature = 0.001
local inverse_temperature = 1/temperature 	-- for speed

-- allocate a greys to store the colors
local greys = field2D.new(dimx, dimy)

-- allocate another greys to store cell-class IDs:
local IDs = field2D.new(dimx, dimy)

-- number of initial cell classes
local IDmax = 10

function initialize()
	for x = 0, greys.width-1 do
		for y = 0, greys.height-1 do
			local id = math.random(IDmax)
			greys:set(id/IDmax, x, y)
			IDs:set(id, x, y)
		end
	end
end

initialize()

-- how to render the scene (toggle fullscreen with the Esc key):
function draw()	
	-- draw the greys:
	greys:draw()
end

-- compute the H differential between two cell types:
function getH(id, nid)
	-- the modulo here creates a cyclic reaction set
	return (id - nid) % IDmax
end

-- compute the H for a given cell:
local range = 1
function computeH(x, y, id)
	local H = 0
	for i = x-range, x+range do
		for j = y-range, y+range do
			-- (skip testing self)
			if x ~= 0 and y ~= 0 then
				-- add to entropy if the IDs are different
				local nid = IDs:get(i, j)
				H = H + getH(id, nid)
			end
		end
	end
	return H
end

-- update the state of the scene (toggle this on and off with spacebar):
function update(dt)
	
	-- a lot of iterations:
	for i = 1, 100000 do
		-- choose a random site:
		local x, y = random(greys.width), random(greys.height)
		-- choose random neighbor:
		local nx, ny = x, y
		local choice = math.random(4)
		if choice == 1 then
			nx = nx + 1
		elseif choice == 2 then
			nx = nx - 1
		elseif choice == 3 then
			ny = ny + 1
		elseif choice == 4 then
			ny = ny - 1
		end
		-- get the IDs:
		local id = IDs:get(x, y)
		local nid = IDs:get(nx, ny)
		if id ~= nid then
			-- possible transition:
			-- get current H:
			local H0 = computeH(x, y, id)
			-- get speculative H:
			local H1 = computeH(x, y, nid)
			-- calculate H change
			local dH = H1 - H0
			if dH <= 0 or random() < dH*temperature then
				-- make this change:
				IDs:set(nid, x, y)
				greys:set(nid/IDmax, x, y)
			end
		end
	end
end

-- handle keypress events:
function keydown(k)
	if k == "r" then
		initialize()
	elseif k == "c" then
		greys:set(0)
	end
end

-- handle mouse events:
function mouse(event, btn, x, y)
	-- clicking & dragging should draw trees into the greys:
	if event == "down" or event == "drag" then
		IDs:set(0, x * greys.width, y * greys.height)
		greys:set(0, x * greys.width, y * greys.height)
	end
end