local ffi = require "ffi"
local gl = require "gl"
local vec3 = require "vec3"
local vec4 = require "vec4"

ffi.cdef [[
typedef struct vertex {
	vec3f position;
	vec3f normal;
	vec2f texcoord;
	vec4f color;
} vertex;
]]

local buffer = {}
function buffer:__index(k)
	if type(k) == "number" then
		return self.data[k]
	else
		return buffer[k]
	end
end

function buffer.new(n)
	local self = {
		id = 0,
		dirty = false,
		count = n,
		usage = gl.DYNAMIC_DRAW,
		
		data = ffi.new("vertex[?]", n)
	}
	return setmetatable(self, buffer)
end

function buffer:bind()
	if self.id == 0 then
		self.id = gl.GenBuffers(1)
		self.dirty = true
	end
	gl.BindBuffer(gl.ARRAY_BUFFER, self.id)
	if self.dirty then
		gl.BufferData(gl.ARRAY_BUFFER, ffi.sizeof(self.data), self.data, self.usage)
		self.dirty = false
	end
end

function buffer:unbind()
	gl.BindBuffer(gl.ARRAY_BUFFER, 0)
end

function buffer:enable_position_attribute(shader, name)
	local attr = shader:GetAttribLocation(name or "position")
	self:bind()
	gl.VertexAttribPointer(
        attr,  	 
		3,                                --/* size */
        gl.FLOAT,                         --/* type */
        gl.FALSE,                         --/* normalized? */
        ffi.sizeof("vertex"),            --/* stride */
		ffi.cast("void *", ffi.offsetof("vertex", "position"))
    );
	gl.EnableVertexAttribArray(attr);
	self:unbind()
end
function buffer:disable_position_attribute(shader, name)
	local attr = shader:GetAttribLocation(name or "position")
	gl.DisableVertexAttribArray(attr);
end

function buffer:enable_normal_attribute(shader, name)
	local attr = shader:GetAttribLocation(name or "normal")
	self:bind()
	gl.VertexAttribPointer(
        attr,  	 
		3,                                --/* size */
        gl.FLOAT,                         --/* type */
        gl.FALSE,                         --/* normalized? */
        ffi.sizeof("vertex"),            --/* stride */
		ffi.cast("void *", ffi.offsetof("vertex", "normal"))
    );
	gl.EnableVertexAttribArray(attr);
	self:unbind()
end
function buffer:disable_normal_attribute(shader, name)
	local attr = shader:GetAttribLocation(name or "normal")
	gl.DisableVertexAttribArray(attr);
end

function buffer:enable_color_attribute(shader, name)
	local attr = shader:GetAttribLocation(name or "color")
	self:bind()
	gl.VertexAttribPointer(
        attr,  	 
		4,                                --/* size */
        gl.FLOAT,                         --/* type */
        gl.FALSE,                         --/* normalized? */
        ffi.sizeof("vertex"),            --/* stride */
		ffi.cast("void *", ffi.offsetof("vertex", "color"))
    );
	gl.EnableVertexAttribArray(attr);
	self:unbind()
end

function buffer:disable_color_attribute(shader, name)
	local attr = shader:GetAttribLocation(name or "color")
	gl.DisableVertexAttribArray(attr);
end

function buffer:enable_texcoord_attribute(shader, name)
	local attr = shader:GetAttribLocation(name or "texcoord")
	self:bind()
	gl.VertexAttribPointer(
        attr,  	 
		4,                                --/* size */
        gl.FLOAT,                         --/* type */
        gl.FALSE,                         --/* normalized? */
        ffi.sizeof("vertex"),            --/* stride */
		ffi.cast("void *", ffi.offsetof("vertex", "texcoord"))
    );
	gl.EnableVertexAttribArray(attr);
	self:unbind()
end

function buffer:disable_texcoord_attribute(shader, name)
	local attr = shader:GetAttribLocation(name or "texcoord")
	gl.DisableVertexAttribArray(attr);
end

function buffer:draw(primitive, first, count)
	gl.DrawArrays(primitive or gl.TRIANGLES, first or 0, count or self.count)
end

setmetatable(buffer, {
	__call = function(t, ...)
		return buffer.new(...)
	end,
})

return buffer