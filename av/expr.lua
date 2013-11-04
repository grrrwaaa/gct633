--- create lazily-evaluated expression objects
-- @module expr

local format = string.format
local concat = table.concat

local expr = {
	_isexpr = true,
}
expr.__index = expr

local function new(t) return setmetatable(t, expr) end

local function isexpr(t) return type(t) == "table" and t._isexpr end

local function coerce(t)
	if type(t) == "table" then
		if isexpr(t) then return t 
		elseif t.op then return new(t)
		end
	end
	return new{ op=type(t), t }
end

function expr:__tostring()
	local elems = {}
	for i, v in ipairs(self) do elems[i] = tostring(v) end
	return format("%s(%s)", self.op, concat(elems, ","))
end

-- add a bunch of math lib:
local prefix_un_ops = { "neg" }
local infix_bin_ops = { "add", "sub", "mul", "div", "pow", "mod" }
local math_var_ops = { "max", "min", "random" }
local math_un_ops = { "sin", "cos", "tan" }
local math_bin_ops = { "atan2" }

for _, k in ipairs(math_var_ops) do
	expr[k] = function(...) return new{ op=k, ... } end
end

for _, k in ipairs(prefix_un_ops) do
	expr[k] = function(a) return new{ op=k, a } end
end
expr.__unm = expr.neg

for _, k in ipairs(math_un_ops) do
	expr[k] = function(a) return new{ op=k, a } end
end

for _, k in ipairs(infix_bin_ops) do
	expr[k] = function(a, b) return new{ op=k, a, b } end
	expr["__"..k] = expr[k]
end

for _, k in ipairs(math_bin_ops) do
	expr[k] = function(a, b) return new{ op=k, a, b } end
end

setmetatable(expr, {
	__call = function(s, t) return coerce(t) end,
})

--------------------------------------------------------------------------------
-- utility to convert expr to Lua code:
local tolua = {}

for _, k in ipairs{ "max", "min", "random" } do
	tolua[k] = function(self, args) return format("math.%s(%s)", k, concat(args, ", ")) end
end

for k, v in pairs{ add="+", sub="-", mul="*", div="/", mod="%", pow="^" } do
	tolua[k] = function(self, args) return format("(%s %s %s)", args[1], v, args[2]) end
end

tolua.number = function(self, args) return tostring(args[1]) end

function expr:tolua()
	if isexpr(self) then
		local c = tolua[self.op]
		local elems = {}
		for i, v in ipairs(self) do elems[i] = expr.tolua(v) end
		if c then 
			return c(self, elems) 
		else 
			return format("%s(%s)", self.op, concat(elems, ","))
		end
	else
		return tostring(self)
	end
end

function expr:toluafunction()
	local f, err = loadstring("return " .. self:tolua())
	assert(f, err)
	return f
end

math.randomseed(os.time())
local e = expr
print(e(1))
local x = (e.random(e(3)) + e(2)):max(e(4)) + e.random(10)
print(x)
print(x:tolua())
print(x:toluafunction()())






return expr