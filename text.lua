local window = require "window"
window.width = 400
window.height = 400
window:create()

local draw2D = require "draw2D"
local font = require "font"

local font_light = font("Roboto-Light")

local t = 0

function draw()
	t = t + 1

	draw2D.color(1, 0, 0.5)
	font:dump()

	draw2D.color(1, 1, 1)
	draw2D.line(-1, 0, 1, 0)
	
	draw2D.color(0.5, 1, 1)
	font:draw("hello world", 0.3, -1, 0.5)
	
	draw2D.push()
		draw2D.rotate(t * 0.01)
		font_light:draw("the quick brown fox...", 0.2)	
	draw2D.pop()
end