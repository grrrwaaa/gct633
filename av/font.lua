local gl = require "gl"
local GL = gl
local shader = require "shader"

local freeimage = require "freeimage"
local texture = require "texture"

local ffi = require "ffi"
local C = ffi.C

local textshader = shader([[

varying vec4 color;
varying vec2 texCoord;

void main() {  
	vec4 vertex = gl_Vertex;
	texCoord = gl_MultiTexCoord0.xy;
	color = gl_Color;

	gl_Position = gl_ModelViewProjectionMatrix * vertex; 
} 

]], [[

uniform sampler2D tex0;
varying vec4 color;
varying vec2 texCoord;

void main(){
	gl_FragColor = texture2D(tex0, texCoord).r * color;
	
	//gl_FragColor *= vec4(texCoord, 0.5, 1);
}

]])


local font = {}
font.__index = font

-- load font:
function font:load(name)
	local fnt = {}
	
	name = name or "Roboto-Regular"
	
	fnt.texture = texture.load("fonts/" .. name .. ".png")
	fnt.texture.clamp = gl.CLAMP_TO_BORDER
	
	local f = io.open("fonts/" .. name .. ".fnt")
	for l in f:lines() do
		local t = fnt
		local cmd, l = l:match("([^%s]+)%s(.+)")
		if cmd == "char" then
			t = {}
		end
		
		for k, v in l:gmatch("%s*([^=]+)=([^%s]+)") do
			--print(k, v)
			if v:sub(1, 1) == '"' then
				t[k] = v:sub(2, -2)
			elseif tonumber(v) then
				t[k] = tonumber(v)
			else
				local p = {}
				for v1 in v:gmatch("(%d+)") do
					p[#p+1] = tonumber(v1)
				end
				t[k] = p
			end
		end
		
		if cmd == "char" then
		
			-- t is a new glyph
			-- precalculate a few things here
			
			t.s0 = t.x / fnt.scaleW
			t.s1 = (t.x + t.width) / fnt.scaleW
			
			t.t0 = 1 - ((t.y - t.height) / fnt.scaleH)
			t.t1 = 1 - (t.y / fnt.scaleH)
			
			fnt[t.id] = t
		end
	end
	
	fnt.scale = 1/fnt.size
	
	return setmetatable(fnt, font)
end

font.__call = font.load

-- the really expensive way (one-shot)
function font:draw(str, scale, x, y, kern)	
	local scale = self.scale * (scale or 1)
	local kern = kern or 0
	local x = x or 0
	local y = y or 0
	
	textshader:bind()
	self.texture:bind()
	gl.Begin(GL.QUADS)
	for i = 1, #str do
		local id = str:byte(i) or 32
    	local g = self[id] or self[32]
    	
		local x1 = x  + scale * (g.xoffset)
		local x2 = x1 + scale * (g.width)
		local y1 = y  + scale * (g.yoffset) 
		local y2 = y1 + scale * (-g.height)
		
		local s1 = g.s0
		local s2 = g.s1
		local t1 = g.t0
		local t2 = g.t1
		
		gl.TexCoord(s1, t1)
		gl.Vertex2d(x1, y1)
		gl.TexCoord(s2, t1)
		gl.Vertex2d(x2, y1)
		gl.TexCoord(s2, t2)
		gl.Vertex2d(x2, y2)
		gl.TexCoord(s1, t2)
		gl.Vertex2d(x1, y2)
		
		x = x + scale * (g.xadvance + kern)
	end	
	gl.End()
	self.texture:unbind()
	textshader:unbind()
	
	return x
end

function font:dump()
	textshader:bind()
	self.texture:bind()
	
	gl.Begin(GL.QUADS)
	
		local x1, y1, x2, y2 = -1, -1, 1, 1
		local s1, t1, s2, t2 = 0, 0, 1, 1
		
		gl.TexCoord(s1, t1)
		gl.Vertex2d(x1, y1)
		gl.TexCoord(s2, t1)
		gl.Vertex2d(x2, y1)
		gl.TexCoord(s2, t2)
		gl.Vertex2d(x2, y2)
		gl.TexCoord(s1, t2)
		gl.Vertex2d(x1, y2)
	
	gl.End()
	self.texture:unbind()
	textshader:unbind()
end

return font.load("Roboto-Regular")
