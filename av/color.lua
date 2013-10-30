--- A collection of types and utilities for color spaces.
-- @module color

local format = string.format
local floor, ceil = math.floor, math.ceil
local min, max = math.min, math.max
local sin, cos = math.sin, math.cos
local asin, acos = math.asin, math.acos
local pow = math.pow
local sqrt, atan2 = math.sqrt, math.atan2
local random = math.random

local clip = function(x, lo, hi) return min(hi, max(lo, x)) end
local clipu = function(x) return min(1, max(0, x)) end

local PITHIRD = math.pi/3
local TWOPI = math.pi * 2
local INV_TWOPI = 1/TWOPI

-- this is the value chosen to indicate a null, e.g. the hue of grey
-- (rather use this than NaN)
local undefined = -1 

local color = {}

--------------------------------------------------------------------------------
--- Conversions & utilities
--------------------------------------------------------------------------------

-- x in 0,1
local function luminance_x(x)
    if (x <= 0.03928) then
    	return x / 12.92
    else
    	return pow((x + 0.055) / 1.055, 2.4)
    end
end

function color.rgb_luminance(r, g, b)
	r = luminance_x(r)
    g = luminance_x(g)
    b = luminance_x(b)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b
end
local rgb_luminance = color.rgb_luminance


local hex6 = "^#?([%dABCDEFabcdef][%dABCDEFabcdef])([%dABCDEFabcdef][%dABCDEFabcdef])([%dABCDEFabcdef][%dABCDEFabcdef])"
local hex3 = "^#?([%dABCDEFabcdef])([%dABCDEFabcdef])([%dABCDEFabcdef])"
local c16tof = 1/255



function color.rgb2hex(r, g, b)
	return format("%02X%02X%02X", clip(r*255, 0, 255), clip(g*255, 0, 255), clip(b*255, 0, 255))
end
local rgb2hex = color.rgb2hex

function color.hex2rgb(str)
	local l = #str
	local r, g, b 
	if l >= 6 then
		r, g, b = str:match(hex6)
		assert(r, g, b, "failed to parse hex color")
		r = tonumber(r, 16) * c16tof
		g = tonumber(g, 16) * c16tof
		b = tonumber(b, 16) * c16tof
	elseif l >= 3 then
		-- short hand version:
		r, g, b = str:match(hex3)
		assert(r, g, b, "failed to parse hex color")
		r = tonumber(r, 16) * 17 * c16tof
		g = tonumber(g, 16) * 17 * c16tof
		b = tonumber(b, 16) * 17 * c16tof
	end
	return r, g, b
end
local hex2rgb = color.hex2rgb


function color.hsi2rgb(h, s, i)
	local r, g, b
	--[[
	http:--//hummer.stanford.edu/museinfo/doc/examples/humdrum/keyscape2/hsi2rgb.cpp
	--]]
	if (h < 1 / 3) then
	  b = (1 - s) / 3;
	  r = (1 + s * cos(TWOPI * h) / cos(PITHIRD - TWOPI * h)) / 3;
	  g = 1 - (b + r);
	elseif (h < 2 / 3) then
	  h = h - 1 / 3;
	  r = (1 - s) / 3;
	  g = (1 + s * cos(TWOPI * h) / cos(PITHIRD - TWOPI * h)) / 3;
	  b = 1 - (r + g);
	else
	  h = h - 2 / 3;
	  g = (1 - s) / 3;
	  b = (1 + s * cos(TWOPI * h) / cos(PITHIRD - TWOPI * h)) / 3;
	  r = 1 - (g + b);
	end
	r = clipu(i * r * 3);
	g = clipu(i * g * 3);
	b = clipu(i * b * 3);
	return r, g, b
end
local hsi2rgb = color.hsi2rgb

function color.rgb2hsi(r, g, b)
    --http:--//hummer.stanford.edu/museinfo/doc/examples/humdrum/keyscape2/rgb2hsi.cpp
	local h
    local least = min(r, g, b);
    local i = (r + g + b) / 3;
    local s = 1 - least / i;
    if (s == 0) then
      	h = 0
   	else
      	h = ((r - g) + (r - b)) / 2;
		h = h / sqrt((r - g) * (r - g) + (r - b) * (g - b));
		h = acos(h);
		if (b > g) then
			h = TWOPI - h
		end
     	h = h / TWOPI
    end
    return h, s, i
end
local rgb2hsi = color.rgb2hsi

-- h in 0, 1 
function color.hsl2rgb(h, s, l)
	local r, g, b
  	if (s == 0) then
    	r = l
    	g = l
    	b = l
	else
		local t2
		if l < 0.5 then
			t2 = l * (1 + s) 
		else
			t2 = l + s - l * s
		end
		local t1 = 2 * l - t2;
		
		local tr = h + 1 / 3
		local tg = h
		local tb = h - 1 / 3
		if tr < 0 then tr = tr + 1 elseif tr > 1 then tr = tr - 1 end
		if tb < 0 then tb = tb + 1 elseif tb > 1 then tb = tb - 1 end
		
		if tr * 6 < 1 then
			r = t1 + (t2 - t1) * (tr * 6)
		elseif tr * 2 < 1 then
			r = t2
		elseif tr * 3 < 2 then
			r = t1 + (t2 - t1) * ((2/3) - tr) * 6
		else
			r = t1
		end
		
		if tg * 6 < 1 then
			g = t1 + (t2 - t1) * (tg * 6)
		elseif tg * 2 < 1 then
			g = t2
		elseif tg * 3 < 2 then
			g = t1 + (t2 - t1) * ((2/3) - tg) * 6
		else
			g = t1
		end
		
		if tb * 6 < 1 then
			b = t1 + (t2 - t1) * (tb * 6)
		elseif tb * 2 < 1 then
			b = t2
		elseif tb * 3 < 2 then
			b = t1 + (t2 - t1) * ((2/3) - tb) * 6
		else
			b = t1
		end
    end
    return r, g, b
end
local hsl2rgb = color.hsl2rgb

function color.rgb2hsl(r, g, b)
   	local h, s, l
    local least = min(r, g, b);
    local most = max(r, g, b);
    local range = most - least
    l = (least + most) / 2
    if (least == most) then
    	s = 0;
   		h = undefined --Number.NaN;
    else
    	s = (l < 0.5) and (range / (most + least)) or (range / (2 - most - least))
    end
    if (r == most) then
    	h = (g - b) / range
    elseif (g == max) then
      	h = 2 + (b - r) / range
	elseif (b == max) then
      	h = 4 + (r - g) / range
    end
    h = (h / 60) % 1
    return h, s, l
end
local rgb2hsl = color.rgb2hsl


function color.hsv2rgb(h, s, v)
    if (s == 0) then
		return v, v, v
	else
		h = (h % 1) * 6
		
	  	local i = floor(h)
	  	local f = h - i
	  	local p = v * (1 - s);
	 	local q = v * (1 - s * f);
	  	local t = v * (1 - s * (1 - f));
	  	
	  	if i == 1 then
	  		return q, v, p
	  	elseif i == 2 then
	  		return p, v, t
	  	elseif i == 3 then
	  		return p, q, v
	  	elseif i == 4 then
	  		return t, p, v
	  	elseif i == 5 then
	  		return v, p, q
	  	else
	  		return v, t, p
	  	end
	end
end
local hsv2rgb = color.hsv2rgb

function color.rgb2hsv(r, g, b)
    local h, s, v
    local least = Math.min(r, g, b);
    local most = Math.max(r, g, b);
    local delta = most - least
    v = max / 255.0;
    if (max == 0) then
      h = undefined
      s = 0
    else
      s = delta / max;
      if (r == max) then
        h = (g - b) / delta;
      elseif (g == max) then
        h = 2 + (b - r) / delta;
      elseif (b == max) then
        h = 4 + (r - g) / delta;
      end
      h = (h / 6) % 1
    end
    return h, s, v
end
local rgb2hsv = color.rgb2hsv

local K = 18;
local X = 0.950470;
local Y = 1;
local Z = 1.088830;

local function xyz2rgb_correct(cl)
	if (cl <= 0.0031308) then
		return 12.92 * cl
	else
		return (1.055) * pow(cl, 1 / 2.4) - 1.055
	end
end

-- units of xyz are probably 0..1, but maybe overflow it
-- returns 0,1 range rgb
function color.xyz2rgb(x, y, z) 
    -- http://en.wikipedia.org/wiki/Srgb
    local rl = 3.2406 * x - 1.5372 * y - 0.4986 * z;
    local gl = -0.9689 * x + 1.8758 * y + 0.0415 * z;
   	local bl = 0.0557 * x - 0.2040 * y + 1.0570 * z;
   	return xyz2rgb_correct(clipu(rl)), xyz2rgb_correct(clipu(gl)), xyz2rgb_correct(clipu(bl))
end
local xyz2rgb = color.xyz2rgb

local function rgb2xyz_correct(c)
	if (c <= 0.04045) then
        return c / 12.92;
    else
        return pow((c + 0.055) / (1.055), 2.4);
    end
end

-- rgb in 0,1
-- xyz in approx 0,1
function color.rgb2xyz(r, g, b) 
    local rl = rgb2xyz_correct(r);
    local gl = rgb2xyz_correct(g);
    local bl = rgb2xyz_correct(b);
    local x = 0.4124 * rl + 0.3576 * gl + 0.1805 * bl;
    local y = 0.2126 * rl + 0.7152 * gl + 0.0722 * bl;
    local z = 0.0193 * rl + 0.1192 * gl + 0.9505 * bl;
    return x, y, z
end
local rgb2xyz = color.rgb2xyz
    
local ill = { x=0.96421, y=1.00000, z=0.82519 }
local iill = { x=1/0.96421, y=1.00000, z=1/0.82519 }
local tmax = 0.00885645167904 --pow(6.0 / 29.0, 3)
local t1 = 7.78703703703703 --(1 / 3) * (29 / 6) * (29 / 6)
local t2 = 0.13793103448276 --4.0 / 29.0

local function xyz2lab_correct(t)
	if (t > tmax) then
		return pow(t, 1 / 3)
	else
		return t1 * t + t2
	end
end

-- l, a, b are in approx 0,1 range, but may overflow it
function color.xyz2lab(x, y, z) 
	l = 1.16 * xyz2lab_correct(y * iill.y) - 0.16
	a = 5 * (xyz2lab_correct(x * iill.x) - xyz2lab_correct(y * iill.y))
	b = 2 * (xyz2lab_correct(y * iill.y) - xyz2lab_correct(z * iill.z))
	return l, a, b
end
local xyz2lab = color.xyz2lab

local tmax = 0.20689655172414 -- 6/29
local t1 = 3 * (6.0 / 29.0) * (6.0 / 29.0)
local t2 = 4.0 / 29.0

local function lab2xyz_correct(t)
    if (t > tmax) then
        return t * t * t
	else
        return t1 * (t - t2)
	end
end

function color.lab2xyz(l, a, b)
    --http://en.wikipedia.org/wiki/Lab_color_spaces
    local sl = (l + 0.16) / 1.16
    local y = ill.y * lab2xyz_correct(sl);
    local x = ill.x * lab2xyz_correct(sl + (a / 5.0));
    local z = ill.z * lab2xyz_correct(sl - (b / 2.0));
    return x, y, z
end
local lab2xyz = color.lab2xyz

-- hcl appears to be a cylindrical projeciton of Lab, with a bit of scaling and rotation

-- iwanthue offers this version of color.js
function color.lab2hcl(L, a, b)
	local l = (L - 0.09) / 0.61
	-- to cylindrical:
    local r = sqrt(a * a + b * b);
    local c = r / (l * 0.311 + 0.125);
    local angle = atan2(a, b)
    local h = ((PITHIRD - angle) * INV_TWOPI) % 1
    return h, c, l
end
local lab2hcl = color.lab2hcl

function color.hcl2lab(h, c, l)
    local L = l * 0.61 + 0.09;
    local angle = PITHIRD - h * TWOPI
    -- from cylindrical:
    local r = (l * 0.311 + 0.125) * c
    local a = sin(angle) * r
    local b = cos(angle) * r
    return L, a, b
end
local hcl2lab = color.hcl2lab

-- the more recent color.js has these simpler versions:
function color.lab2lch(l, a, b) 
    local c = sqrt(a * a + b * b)
    local h = atan2(b, a) * INV_TWOPI
    return l, c, h
end
local lab2lch = color.lab2lch

function color.lch2lab(l, c, h)
	-- convert to radians:
	local h = h * TWOPI
	-- evidently the Lab "ab" values are in the same range as the HCL "C" value
	return l, cos(h)*c, sin(h)*c
end
local lch2lab = color.lch2lab

--------------------------------------------------------------------------------
-- RGBA
--------------------------------------------------------------------------------

local rgb = {}
rgb.__index = rgb

local function new(r, g, b, a) return setmetatable({ r=r, g=g, b=b, a=a }, rgb) end

--- Generate an rgba color.
-- This function takes many different forms:
-- rgb(1, 0, 0, 0.2) generates red at 20% alpha
-- rgb(1, 0, 0) generates red
-- rgb(0.5, 0.2) generates 50% greyscale at 20% alpha
-- rgb(0.5) generates 50% greyscale
-- rgb("#FF0000"), rgb("#f00"), rgb("red") generate red
-- rgb("#FF0000", 0.2), rgb("#f00", 0.2), rgb("red", 0.2) generate red at 20% alpha
function color.rgb(r, g, b, a)
	if type(r) == "string" then
		a = g or 1
		local pre = color[r]
		if pre then
			r, g, b = pre.r, pre.g, pre.b
		else
			r, g, b = hex2rgb(r)	-- may throw error
		end 
	elseif r == nil then
		r, g, b, a = 0, 0, 0, 1
	elseif g == nil then
		-- one component given: greyscale:
		g, b, a = r, r, 1
	elseif b == nil then
		-- two components given; greyscale + alpha:
		g, b, a = r, r, g
	elseif a == nil then
		a = 1
	end
	return new(r, g, b, a)
end

-- alias
local rgb = color.rgb

--- A color expressed as red, green, blue and alpha components.
-- @type rgb

function rgb:__tostring()
	return format("rgb(%f, %f, %f, %f)", self.r, self.g, self.b, self.a)
end

--- Create a duplicate of this color object
-- @return rgba
function rgb:copy()
	return new(self.r, self.g, self.b, self.a)
end

--- Set or return this color expressed as a hexadecimal string.
-- e.g. c:hex() -> "FF0000"
-- e.g. c:hex("FF0000")
-- @param? str hex string
-- @param? a alpha value
function rgb:hex(str, a)
	if str then
		self.r, self.g, self.b = hex2rgb(str)
		self.a = a or self.a
		return self
	end
	return rgb2hex(self.r, self.g, self.b)
end


--- Set or return this color expressed as HSV.
-- also accepts optional alpha argument
-- @param? h hue
-- @param? s saturation
-- @param? v value
-- @param? a alpha value
function rgb:hsv(h, s, v, a)
	if h then
		self.r, self.g, self.b = hsv2rgb(h, s, v)
		self.a = a or self.a
		return self
	end
	return rgb2hsv(self.r, self.g, self.b)
end

--- Set or return this color expressed as HSL.
-- also accepts optional alpha argument
-- @param? h hue
-- @param? s saturation
-- @param? l luminance
-- @param? a alpha value
function rgb:hsl(h, s, l, a)
	if h then
		self.r, self.g, self.b = hsl2rgb(h, s, l)
		self.a = a or self.a
		return self
	end
	return rgb2hsl(self.r, self.g, self.b)
end

--- Set or return this color expressed as HSI.
-- also accepts optional alpha argument
-- @param? h hue
-- @param? s saturation
-- @param? i intensity
-- @param? a alpha value
function rgb:hsi(h, s, i, a)
	if h then
		self.r, self.g, self.b = hsi2rgb(h, s, i)
		self.a = a or self.a
		return self
	end
	return rgb2hsi(self.r, self.g, self.b)
end

--- Set or return this color expressed as CIE XYZ.
-- also accepts optional alpha argument
-- @param? x 
-- @param? y 
-- @param? z 
-- @param? a alpha value
function rgb:xyz(x, y, z, a)
	if x then
		self.r, self.g, self.b = xyz2rgb(x, y, z)
		self.a = a or self.a
		return self
	end
	return rgb2xyz(self.r, self.g, self.b)
end

--- Set or return this color expressed as L*a*b.
-- also accepts optional alpha argument
-- @param? l
-- @param? a 
-- @param? b 
-- @param? alpha alpha value
function rgb:lab(l, a, b, alpha)
	if l then
		self.r, self.g, self.b = xyz2rgb(lab2xyz(l, a, b))
		self.a = alpha or self.a
		return self
	end
	return xyz2lab(rgb2xyz(self.r, self.g, self.b))
end

--- Set or return this color expressed as Lch.
-- also accepts optional alpha argument
-- @param? l luminance 
-- @param? c chroma 
-- @param? h hue 
-- @param? a alpha value
function rgb:lch(l, c, h, a)
	-- TODO: can this be reduced?
	if l then
		self.r, self.g, self.b = xyz2rgb(lab2xyz(lch2lab(l, c, h)))
		self.a = a or self.a
		return self
	end
	return lab2lch(xyz2lab(rgb2xyz(self.r, self.g, self.b)))
end

--- Return the perceptual luminance of this color.
-- (does not take into account alpha value)
function rgb:luminance()
	return rgb_luminance(self.r, self.g, self.b)
end

-- http://www.w3.org/TR/css3-color/#svg-color
local predefined = {
	indigo = "#4b0082",
    gold = "#ffd700",
    hotpink = "#ff69b4",
    firebrick = "#b22222",
    indianred = "#cd5c5c",
    yellow = "#ffff00",
    mistyrose = "#ffe4e1",
    darkolivegreen = "#556b2f",
    olive = "#808000",
    darkseagreen = "#8fbc8f",
    pink = "#ffc0cb",
    tomato = "#ff6347",
    lightcoral = "#f08080",
    orangered = "#ff4500",
    navajowhite = "#ffdead",
    lime = "#00ff00",
    palegreen = "#98fb98",
    darkslategrey = "#2f4f4f",
    greenyellow = "#adff2f",
    burlywood = "#deb887",
    seashell = "#fff5ee",
    mediumspringgreen = "#00fa9a",
    fuchsia = "#ff00ff",
    papayawhip = "#ffefd5",
    blanchedalmond = "#ffebcd",
    chartreuse = "#7fff00",
    dimgray = "#696969",
    black = "#000000",
    peachpuff = "#ffdab9",
    springgreen = "#00ff7f",
    aquamarine = "#7fffd4",
    white = "#ffffff",
    orange = "#ffa500",
    lightsalmon = "#ffa07a",
    darkslategray = "#2f4f4f",
    brown = "#a52a2a",
    ivory = "#fffff0",
    dodgerblue = "#1e90ff",
    peru = "#cd853f",
    lawngreen = "#7cfc00",
    chocolate = "#d2691e",
    crimson = "#dc143c",
    forestgreen = "#228b22",
    darkgrey = "#a9a9a9",
    lightseagreen = "#20b2aa",
    cyan = "#00ffff",
    mintcream = "#f5fffa",
    silver = "#c0c0c0",
    antiquewhite = "#faebd7",
    mediumorchid = "#ba55d3",
    skyblue = "#87ceeb",
    gray = "#808080",
    darkturquoise = "#00ced1",
    goldenrod = "#daa520",
    darkgreen = "#006400",
    floralwhite = "#fffaf0",
    darkviolet = "#9400d3",
    darkgray = "#a9a9a9",
    moccasin = "#ffe4b5",
    saddlebrown = "#8b4513",
    grey = "#808080",
    darkslateblue = "#483d8b",
    lightskyblue = "#87cefa",
    lightpink = "#ffb6c1",
    mediumvioletred = "#c71585",
    slategrey = "#708090",
    red = "#ff0000",
    deeppink = "#ff1493",
    limegreen = "#32cd32",
    darkmagenta = "#8b008b",
    palegoldenrod = "#eee8aa",
    plum = "#dda0dd",
    turquoise = "#40e0d0",
    lightgrey = "#d3d3d3",
    lightgoldenrodyellow = "#fafad2",
    darkgoldenrod = "#b8860b",
    lavender = "#e6e6fa",
    maroon = "#800000",
    yellowgreen = "#9acd32",
    sandybrown = "#f4a460",
    thistle = "#d8bfd8",
    violet = "#ee82ee",
    navy = "#000080",
    magenta = "#ff00ff",
    dimgrey = "#696969",
    tan = "#d2b48c",
    rosybrown = "#bc8f8f",
    olivedrab = "#6b8e23",
    blue = "#0000ff",
    lightblue = "#add8e6",
    ghostwhite = "#f8f8ff",
    honeydew = "#f0fff0",
    cornflowerblue = "#6495ed",
    slateblue = "#6a5acd",
    linen = "#faf0e6",
    darkblue = "#00008b",
    powderblue = "#b0e0e6",
    seagreen = "#2e8b57",
    darkkhaki = "#bdb76b",
    snow = "#fffafa",
    sienna = "#a0522d",
    mediumblue = "#0000cd",
    royalblue = "#4169e1",
    lightcyan = "#e0ffff",
    green = "#008000",
    mediumpurple = "#9370db",
    midnightblue = "#191970",
    cornsilk = "#fff8dc",
    paleturquoise = "#afeeee",
    bisque = "#ffe4c4",
    slategray = "#708090",
    darkcyan = "#008b8b",
    khaki = "#f0e68c",
    wheat = "#f5deb3",
    teal = "#008080",
    darkorchid = "#9932cc",
    deepskyblue = "#00bfff",
    salmon = "#fa8072",
    darkred = "#8b0000",
    steelblue = "#4682b4",
    palevioletred = "#db7093",
    lightslategray = "#778899",
    aliceblue = "#f0f8ff",
    lightslategrey = "#778899",
    lightgreen = "#90ee90",
    orchid = "#da70d6",
    gainsboro = "#dcdcdc",
    mediumseagreen = "#3cb371",
    lightgray = "#d3d3d3",
    mediumturquoise = "#48d1cc",
    lemonchiffon = "#fffacd",
    cadetblue = "#5f9ea0",
    lightyellow = "#ffffe0",
    lavenderblush = "#fff0f5",
    coral = "#ff7f50",
    purple = "#800080",
    aqua = "#00ffff",
    whitesmoke = "#f5f5f5",
    mediumslateblue = "#7b68ee",
    darkorange = "#ff8c00",
    mediumaquamarine = "#66cdaa",
    darksalmon = "#e9967a",
    beige = "#f5f5dc",
    blueviolet = "#8a2be2",
    azure = "#f0ffff",
    lightsteelblue = "#b0c4de",
    oldlace = "#fdf5e6"
}

for k, v in pairs(predefined) do
	color[k] = rgb(v)
end

return color

--[[

  color.interpolate = function(a, b, f, m) {
    if ((a == null) || (b == null)) {
      return '#000';
    }
    if (type(a) == 'string') {
      a = new Color(a);
    }
    if (type(b) == 'string') {
      b = new Color(b);
    }
    return a.interpolate(f, b, m);
  };

  color.mix = color.interpolate;

  color.contrast = function(a, b) {
    var l1, l2;

    if (type(a) == 'string') {
      a = new Color(a);
    }
    if (type(b) == 'string') {
      b = new Color(b);
    }
    l1 = a.luminance();
    l2 = b.luminance();
    if (l1 > l2) {
      return (l1 + 0.05) / (l2 + 0.05);
    } else {
      return (l2 + 0.05) / (l1 + 0.05);
    }
  };

  Color = (function() {
    function Color() {
      var a, arg, args, m, me, me_rgb, x, y, z, _i, _len, _ref, _ref1, _ref2, _ref3;

      me = this;
      args = [];
      for (_i = 0, _len = arguments.length; _i < _len; _i++) {
        arg = arguments[_i];
        if (arg != null) {
          args.push(arg);
        }
      }
      if (args.length == 0) {
        _ref = [255, 0, 255, 1, 'rgb'], x = _ref[0], y = _ref[1], z = _ref[2], a = _ref[3], m = _ref[4];
      } else if (type(args[0]) == "array") {
        if (args[0].length == 3) {
          _ref1 = args[0], x = _ref1[0], y = _ref1[1], z = _ref1[2];
          a = 1;
        } else if (args[0].length == 4) {
          _ref2 = args[0], x = _ref2[0], y = _ref2[1], z = _ref2[2], a = _ref2[3];
        } else {
          throw 'unknown input argument';
        }
        m = args[1];
      } else if (type(args[0]) == "string") {
        x = args[0];
        m = 'hex';
      } else if (type(args[0]) == "object") {
        _ref3 = args[0]._rgb, x = _ref3[0], y = _ref3[1], z = _ref3[2], a = _ref3[3];
        m = 'rgb';
      } else if (args.length >= 3) {
        x = args[0];
        y = args[1];
        z = args[2];
      }
      if (args.length == 3) {
        m = 'rgb';
        a = 1;
      } else if (args.length == 4) {
        if (type(args[3]) == "string") {
          m = args[3];
          a = 1;
        } else if (type(args[3]) == "number") {
          m = 'rgb';
          a = args[3];
        }
      } else if (args.length == 5) {
        a = args[3];
        m = args[4];
      }
      if (a == null) {
        a = 1;
      }
      if (m == 'rgb') {
        me._rgb = [x, y, z, a];
      } else if (m == 'hsl') {
        me._rgb = hsl2rgb(x, y, z);
        me._rgb[3] = a;
      } else if (m == 'hsv') {
        me._rgb = hsv2rgb(x, y, z);
        me._rgb[3] = a;
      } else if (m == 'hex') {
        me._rgb = hex2rgb(x);
      } else if (m == 'lab') {
        me._rgb = lab2rgb(x, y, z);
        me._rgb[3] = a;
      } else if (m == 'lch') {
        me._rgb = lch2rgb(x, y, z);
        me._rgb[3] = a;
      } else if (m == 'hsi') {
        me._rgb = hsi2rgb(x, y, z);
        me._rgb[3] = a;
      }
      me_rgb = clip_rgb(me._rgb);
    }

    Color.prototype.rgb = function() {
      return this._rgb.slice(0, 3);
    };

    Color.prototype.rgba = function() {
      return this._rgb;
    };

    Color.prototype.hex = function() {
      return rgb2hex(this._rgb);
    };

    Color.prototype.toString = function() {
      return this.hex();
    };

    Color.prototype.hsl = function() {
      return rgb2hsl(this._rgb);
    };

    Color.prototype.hsv = function() {
      return rgb2hsv(this._rgb);
    };

    Color.prototype.lab = function() {
      return rgb2lab(this._rgb);
    };

    Color.prototype.lch = function() {
      return rgb2lch(this._rgb);
    };

    Color.prototype.hsi = function() {
      return rgb2hsi(this._rgb);
    };

    Color.prototype.name = function() {
      var h, k;

      h = this.hex();
      for (k in color.colors) {
        if (h == color.colors[k]) {
          return k;
        }
      }
      return h;
    };

    Color.prototype.alpha = function(alpha) {
      if (arguments.length) {
        this._rgb[3] = alpha;
        return this;
      }
      return this._rgb[3];
    };

    Color.prototype.css = function() {
      if (this._rgb[3] < 1) {
        return 'rgba(' + this._rgb.join(',') + ')';
      } else {
        return 'rgb(' + this._rgb.slice(0, 3).join(',') + ')';
      }
    };

    Color.prototype.interpolate = function(f, col, m) {
      /*
      interpolates between colors
      f = 0 --> me
      f = 1 --> col
      */

      var dh, hue, hue0, hue1, lbv, lbv0, lbv1, me, res, sat, sat0, sat1, xyz0, xyz1;

      me = this;
      if (m == null) {
        m = 'rgb';
      }
      if (type(col) == "string") {
        col = new Color(col);
      }
      if (m == 'hsl' || m == 'hsv' || m == 'lch' || m == 'hsi') {
        if (m == 'hsl') {
          xyz0 = me.hsl();
          xyz1 = col.hsl();
        } else if (m == 'hsv') {
          xyz0 = me.hsv();
          xyz1 = col.hsv();
        } else if (m == 'hsi') {
          xyz0 = me.hsi();
          xyz1 = col.hsi();
        } else if (m == 'lch') {
          xyz0 = me.lch();
          xyz1 = col.lch();
        }
        if (m.substr(0, 1) == 'h') {
          hue0 = xyz0[0], sat0 = xyz0[1], lbv0 = xyz0[2];
          hue1 = xyz1[0], sat1 = xyz1[1], lbv1 = xyz1[2];
        } else {
          lbv0 = xyz0[0], sat0 = xyz0[1], hue0 = xyz0[2];
          lbv1 = xyz1[0], sat1 = xyz1[1], hue1 = xyz1[2];
        }
        if (!isNaN(hue0) && !isNaN(hue1)) {
          if (hue1 > hue0 && hue1 - hue0 > 180) {
            dh = hue1 - (hue0 + 360);
          } else if (hue1 < hue0 && hue0 - hue1 > 180) {
            dh = hue1 + 360 - hue0;
          } else {
            dh = hue1 - hue0;
          }
          hue = hue0 + f * dh;
        } else if (!isNaN(hue0)) {
          hue = hue0;
          if (lbv1 == 1 || lbv1 == 0) {
            sat = sat0;
          }
        } else if (!isNaN(hue1)) {
          hue = hue1;
          if (lbv0 == 1 || lbv0 == 0) {
            sat = sat1;
          }
        } else {
          hue = Number.NaN;
        }
        if (sat == null) {
          sat = sat0 + f * (sat1 - sat0);
        }
        lbv = lbv0 + f * (lbv1 - lbv0);
        if (m.substr(0, 1) == 'h') {
          res = new Color(hue, sat, lbv, m);
        } else {
          res = new Color(lbv, sat, hue, m);
        }
      } else if (m == 'rgb') {
        xyz0 = me._rgb;
        xyz1 = col._rgb;
        res = new Color(xyz0[0] + f * (xyz1[0] - xyz0[0]), xyz0[1] + f * (xyz1[1] - xyz0[1]), xyz0[2] + f * (xyz1[2] - xyz0[2]), m);
      } else if (m == 'lab') {
        xyz0 = me.lab();
        xyz1 = col.lab();
        res = new Color(xyz0[0] + f * (xyz1[0] - xyz0[0]), xyz0[1] + f * (xyz1[1] - xyz0[1]), xyz0[2] + f * (xyz1[2] - xyz0[2]), m);
      } else {
        throw "color mode " + m + " is not supported";
      }
      res.alpha(me.alpha() + f * (col.alpha() - me.alpha()));
      return res;
    };

    Color.prototype.darken = function(amount) {
      var lch, me;

      if (amount == null) {
        amount = 20;
      }
      me = this;
      lch = me.lch();
      lch[0] -= amount;
      return color.lch(lch).alpha(me.alpha());
    };

    Color.prototype.darker = function(amount) {
      return this.darken(amount);
    };

    Color.prototype.brighten = function(amount) {
      if (amount == null) {
        amount = 20;
      }
      return this.darken(-amount);
    };

    Color.prototype.brighter = function(amount) {
      return this.brighten(amount);
    };

    Color.prototype.saturate = function(amount) {
      var lch, me;

      if (amount == null) {
        amount = 20;
      }
      me = this;
      lch = me.lch();
      lch[1] += amount;
      return color.lch(lch).alpha(me.alpha());
    };

    Color.prototype.desaturate = function(amount) {
      if (amount == null) {
        amount = 20;
      }
      return this.saturate(-amount);
    };

    return Color;

  })();

  css2rgb = function(css) {
    var hsl, i, m, rgb, _i, _j, _k, _l;

    if ((color.colors != null) && color.colors[css]) {
      return hex2rgb(color.colors[css]);
    }
    if (m = css.match(/rgb\(\s*(\-?\d+),\s*(\-?\d+)\s*,\s*(\-?\d+)\s*\)/)) {
      rgb = m.slice(1, 4);
      for (i = _i = 0; _i <= 2; i = ++_i) {
        rgb[i] = +rgb[i];
      }
      rgb[3] = 1;
    } else if (m = css.match(/rgba\(\s*(\-?\d+),\s*(\-?\d+)\s*,\s*(\-?\d+)\s*,\s*([01]|[01]?\.\d+)\)/)) {
      rgb = m.slice(1, 5);
      for (i = _j = 0; _j <= 3; i = ++_j) {
        rgb[i] = +rgb[i];
      }
    } else if (m = css.match(/rgb\(\s*(\-?\d+)%,\s*(\-?\d+)%\s*,\s*(\-?\d+)%\s*\)/)) {
      rgb = m.slice(1, 4);
      for (i = _k = 0; _k <= 2; i = ++_k) {
        rgb[i] = Math.round(rgb[i] * 2.55);
      }
      rgb[3] = 1;
    } else if (m = css.match(/rgba\(\s*(\-?\d+)%,\s*(\-?\d+)%\s*,\s*(\-?\d+)%\s*,\s*([01]|[01]?\.\d+)\)/)) {
      rgb = m.slice(1, 5);
      for (i = _l = 0; _l <= 2; i = ++_l) {
        rgb[i] = Math.round(rgb[i] * 2.55);
      }
      rgb[3] = +rgb[3];
    } else if (m = css.match(/hsl\(\s*(\-?\d+),\s*(\-?\d+)%\s*,\s*(\-?\d+)%\s*\)/)) {
      hsl = m.slice(1, 4);
      hsl[1] *= 0.01;
      hsl[2] *= 0.01;
      rgb = hsl2rgb(hsl);
      rgb[3] = 1;
    } else if (m = css.match(/hsla\(\s*(\-?\d+),\s*(\-?\d+)%\s*,\s*(\-?\d+)%\s*,\s*([01]|[01]?\.\d+)\)/)) {
      hsl = m.slice(1, 4);
      hsl[1] *= 0.01;
      hsl[2] *= 0.01;
      rgb = hsl2rgb(hsl);
      rgb[3] = +m[4];
    }
    return rgb;
  };

  

  






  color.scale = function(colors, positions) {
    var classifyValue, f, getClass, getColor, setColors, setDomain, tmap, _colors, _correctLightness, _domain, _fixed, _max, _min, _mode, _nacol, _numClasses, _out, _pos, _spread;

    _mode = 'rgb';
    _nacol = color('#ccc');
    _spread = 0;
    _fixed = false;
    _domain = [0, 1];
    _colors = [];
    _out = false;
    _pos = [];
    _min = 0;
    _max = 1;
    _correctLightness = false;
    _numClasses = 0;
    setColors = function(colors, positions) {
      var c, col, _i, _j, _ref, _ref1, _ref2;

      if (colors == null) {
        colors = ['#ddd', '#222'];
      }
      if ((colors != null) && type(colors) == 'string' && (((_ref = color.brewer) != null ? _ref[colors] : void 0) != null)) {
        colors = color.brewer[colors];
      }
      if (type(colors) == 'array') {
        colors = colors.slice(0);
        for (c = _i = 0, _ref1 = colors.length - 1; 0 <= _ref1 ? _i <= _ref1 : _i >= _ref1; c = 0 <= _ref1 ? ++_i : --_i) {
          col = colors[c];
          if (type(col) == "string") {
            colors[c] = color(col);
          }
        }
        if (positions != null) {
          _pos = positions;
        } else {
          _pos = [];
          for (c = _j = 0, _ref2 = colors.length - 1; 0 <= _ref2 ? _j <= _ref2 : _j >= _ref2; c = 0 <= _ref2 ? ++_j : --_j) {
            _pos.push(c / (colors.length - 1));
          }
        }
      }
      return _colors = colors;
    };
    setDomain = function(domain) {
      if (domain == null) {
        domain = [];
      }
      /*
      # use this if you want to display a limited number of data classes
      # possible methods are "equalinterval", "quantiles", "custom"
      */

      _domain = domain;
      _min = domain[0];
      _max = domain[domain.length - 1];
      if (domain.length == 2) {
        return _numClasses = 0;
      } else {
        return _numClasses = domain.length - 1;
      }
    };
    getClass = function(value) {
      var i, n;

      if (_domain != null) {
        n = _domain.length - 1;
        i = 0;
        while (i < n && value >= _domain[i]) {
          i++;
        }
        return i - 1;
      }
      return 0;
    };
    tmap = function(t) {
      return t;
    };
    classifyValue = function(value) {
      var i, maxc, minc, n, val;

      val = value;
      if (_domain.length > 2) {
        n = _domain.length - 1;
        i = getClass(value);
        minc = _domain[0] + (_domain[1] - _domain[0]) * (0 + _spread * 0.5);
        maxc = _domain[n - 1] + (_domain[n] - _domain[n - 1]) * (1 - _spread * 0.5);
        val = _min + ((_domain[i] + (_domain[i + 1] - _domain[i]) * 0.5 - minc) / (maxc - minc)) * (_max - _min);
      }
      return val;
    };
    getColor = function(val, bypassMap) {
      var c, col, f0, i, p, t, _i, _ref;

      if (bypassMap == null) {
        bypassMap = false;
      }
      if (isNaN(val)) {
        return _nacol;
      }
      if (!bypassMap) {
        if (_domain.length > 2) {
          c = getClass(val);
          t = c / (_numClasses - 1);
        } else {
          t = f0 = (val - _min) / (_max - _min);
          t = Math.min(1, Math.max(0, t));
        }
      } else {
        t = val;
      }
      if (!bypassMap) {
        t = tmap(t);
      }
      if (type(_colors) == 'array') {
        for (i = _i = 0, _ref = _pos.length - 1; 0 <= _ref ? _i <= _ref : _i >= _ref; i = 0 <= _ref ? ++_i : --_i) {
          p = _pos[i];
          if (t <= p) {
            col = _colors[i];
            break;
          }
          if (t >= p && i == _pos.length - 1) {
            col = _colors[i];
            break;
          }
          if (t > p && t < _pos[i + 1]) {
            t = (t - p) / (_pos[i + 1] - p);
            col = color.interpolate(_colors[i], _colors[i + 1], t, _mode);
            break;
          }
        }
      } else if (type(_colors) == 'function') {
        col = _colors(t);
      }
      return col;
    };
    setColors(colors, positions);
    f = function(v) {
      var c;

      c = getColor(v);
      if (_out && c[_out]) {
        return c[_out]();
      } else {
        return c;
      }
    };
    f.domain = function(domain, classes, mode, key) {
      var d;

      if (mode == null) {
        mode = 'e';
      }
      if (!arguments.length) {
        return _domain;
      }
      if (classes != null) {
        d = color.analyze(domain, key);
        if (classes == 0) {
          domain = [d.min, d.max];
        } else {
          domain = color.limits(d, mode, classes);
        }
      }
      setDomain(domain);
      return f;
    };
    f.mode = function(_m) {
      if (!arguments.length) {
        return _mode;
      }
      _mode = _m;
      return f;
    };
    f.range = function(colors, _pos) {
      setColors(colors, _pos);
      return f;
    };
    f.out = function(_o) {
      _out = _o;
      return f;
    };
    f.spread = function(val) {
      if (!arguments.length) {
        return _spread;
      }
      _spread = val;
      return f;
    };
    f.correctLightness = function(v) {
      if (!arguments.length) {
        return _correctLightness;
      }
      _correctLightness = v;
      if (_correctLightness) {
        tmap = function(t) {
          var L0, L1, L_actual, L_diff, L_ideal, max_iter, pol, t0, t1;

          L0 = getColor(0, true).lab()[0];
          L1 = getColor(1, true).lab()[0];
          pol = L0 > L1;
          L_actual = getColor(t, true).lab()[0];
          L_ideal = L0 + (L1 - L0) * t;
          L_diff = L_actual - L_ideal;
          t0 = 0;
          t1 = 1;
          max_iter = 20;
          while (Math.abs(L_diff) > 1e-2 && max_iter-- > 0) {
            (function() {
              if (pol) {
                L_diff *= -1;
              }
              if (L_diff < 0) {
                t0 = t;
                t += (t1 - t) * 0.5;
              } else {
                t1 = t;
                t += (t0 - t) * 0.5;
              }
              L_actual = getColor(t, true).lab()[0];
              return L_diff = L_actual - L_ideal;
            })();
          }
          return t;
        };
      } else {
        tmap = function(t) {
          return t;
        };
      }
      return f;
    };
    return f;
  };

  if ((_ref = color.scales) == null) {
    color.scales = {};
  }

  color.scales.cool = function() {
    return color.scale([color.hsl(180, 1, .9), color.hsl(250, .7, .4)]);
  };

  color.scales.hot = function() {
    return color.scale(['#000', '#f00', '#ff0', '#fff'], [0, .25, .75, 1]).mode('rgb');
  };



  color.analyze = function(data, key, filter) {
    var add, k, r, val, visit, _i, _len;

    r = {
      min: Number.MAX_VALUE,
      max: Number.MAX_VALUE * -1,
      sum: 0,
      values: [],
      count: 0
    };
    if (filter == null) {
      filter = function() {
        return true;
      };
    }
    add = function(val) {
      if ((val != null) && !isNaN(val)) {
        r.values.push(val);
        r.sum += val;
        if (val < r.min) {
          r.min = val;
        }
        if (val > r.max) {
          r.max = val;
        }
        r.count += 1;
      }
    };
    visit = function(val, k) {
      if (filter(val, k)) {
        if ((key != null) && type(key) == 'function') {
          return add(key(val));
        } else if ((key != null) && type(key) == 'string' || type(key) == 'number') {
          return add(val[key]);
        } else {
          return add(val);
        }
      }
    };
    if (type(data) == 'array') {
      for (_i = 0, _len = data.length; _i < _len; _i++) {
        val = data[_i];
        visit(val);
      }
    } else {
      for (k in data) {
        val = data[k];
        visit(val, k);
      }
    }
    r.domain = [r.min, r.max];
    r.limits = function(mode, num) {
      return color.limits(r, mode, num);
    };
    return r;
  };

  color.limits = function(data, mode, num) {
    var assignments, best, centroids, cluster, clusterSizes, dist, i, j, kClusters, limits, max, max_log, min, min_log, mindist, n, nb_iters, newCentroids, p, pb, pr, repeat, sum, tmpKMeansBreaks, value, values, _i, _j, _k, _l, _m, _n, _o, _p, _q, _r, _ref1, _ref10, _ref11, _ref12, _ref13, _ref14, _ref15, _ref2, _ref3, _ref4, _ref5, _ref6, _ref7, _ref8, _ref9, _s, _t, _u, _v, _w;

    if (mode == null) {
      mode = 'equal';
    }
    if (num == null) {
      num = 7;
    }
    if (data.values == null) {
      data = color.analyze(data);
    }
    min = data.min;
    max = data.max;
    sum = data.sum;
    values = data.values.sort(function(a, b) {
      return a - b;
    });
    limits = [];
    if (mode.substr(0, 1) == 'c') {
      limits.push(min);
      limits.push(max);
    }
    if (mode.substr(0, 1) == 'e') {
      limits.push(min);
      for (i = _i = 1, _ref1 = num - 1; 1 <= _ref1 ? _i <= _ref1 : _i >= _ref1; i = 1 <= _ref1 ? ++_i : --_i) {
        limits.push(min + (i / num) * (max - min));
      }
      limits.push(max);
    } else if (mode.substr(0, 1) == 'l') {
      if (min <= 0) {
        throw 'Logarithmic scales are only possible for values > 0';
      }
      min_log = Math.LOG10E * Math.log(min);
      max_log = Math.LOG10E * Math.log(max);
      limits.push(min);
      for (i = _j = 1, _ref2 = num - 1; 1 <= _ref2 ? _j <= _ref2 : _j >= _ref2; i = 1 <= _ref2 ? ++_j : --_j) {
        limits.push(Math.pow(10, min_log + (i / num) * (max_log - min_log)));
      }
      limits.push(max);
    } else if (mode.substr(0, 1) == 'q') {
      limits.push(min);
      for (i = _k = 1, _ref3 = num - 1; 1 <= _ref3 ? _k <= _ref3 : _k >= _ref3; i = 1 <= _ref3 ? ++_k : --_k) {
        p = values.length * i / num;
        pb = Math.floor(p);
        if (pb == p) {
          limits.push(values[pb]);
        } else {
          pr = p - pb;
          limits.push(values[pb] * pr + values[pb + 1] * (1 - pr));
        }
      }
      limits.push(max);
    } else if (mode.substr(0, 1) == 'k') {
      /*
      implementation based on
      http:--//code.google.com/p/figue/source/browse/trunk/figue.js#336
      simplified for 1-d input values
      */

      n = values.length;
      assignments = new Array(n);
      clusterSizes = new Array(num);
      repeat = true;
      nb_iters = 0;
      centroids = null;
      centroids = [];
      centroids.push(min);
      for (i = _l = 1, _ref4 = num - 1; 1 <= _ref4 ? _l <= _ref4 : _l >= _ref4; i = 1 <= _ref4 ? ++_l : --_l) {
        centroids.push(min + (i / num) * (max - min));
      }
      centroids.push(max);
      while (repeat) {
        for (j = _m = 0, _ref5 = num - 1; 0 <= _ref5 ? _m <= _ref5 : _m >= _ref5; j = 0 <= _ref5 ? ++_m : --_m) {
          clusterSizes[j] = 0;
        }
        for (i = _n = 0, _ref6 = n - 1; 0 <= _ref6 ? _n <= _ref6 : _n >= _ref6; i = 0 <= _ref6 ? ++_n : --_n) {
          value = values[i];
          mindist = Number.MAX_VALUE;
          for (j = _o = 0, _ref7 = num - 1; 0 <= _ref7 ? _o <= _ref7 : _o >= _ref7; j = 0 <= _ref7 ? ++_o : --_o) {
            dist = Math.abs(centroids[j] - value);
            if (dist < mindist) {
              mindist = dist;
              best = j;
            }
          }
          clusterSizes[best]++;
          assignments[i] = best;
        }
        newCentroids = new Array(num);
        for (j = _p = 0, _ref8 = num - 1; 0 <= _ref8 ? _p <= _ref8 : _p >= _ref8; j = 0 <= _ref8 ? ++_p : --_p) {
          newCentroids[j] = null;
        }
        for (i = _q = 0, _ref9 = n - 1; 0 <= _ref9 ? _q <= _ref9 : _q >= _ref9; i = 0 <= _ref9 ? ++_q : --_q) {
          cluster = assignments[i];
          if (newCentroids[cluster] == null) {
            newCentroids[cluster] = values[i];
          } else {
            newCentroids[cluster] += values[i];
          }
        }
        for (j = _r = 0, _ref10 = num - 1; 0 <= _ref10 ? _r <= _ref10 : _r >= _ref10; j = 0 <= _ref10 ? ++_r : --_r) {
          newCentroids[j] *= 1 / clusterSizes[j];
        }
        repeat = false;
        for (j = _s = 0, _ref11 = num - 1; 0 <= _ref11 ? _s <= _ref11 : _s >= _ref11; j = 0 <= _ref11 ? ++_s : --_s) {
          if (newCentroids[j] !== centroids[i]) {
            repeat = true;
            break;
          }
        }
        centroids = newCentroids;
        nb_iters++;
        if (nb_iters > 200) {
          repeat = false;
        }
      }
      kClusters = {};
      for (j = _t = 0, _ref12 = num - 1; 0 <= _ref12 ? _t <= _ref12 : _t >= _ref12; j = 0 <= _ref12 ? ++_t : --_t) {
        kClusters[j] = [];
      }
      for (i = _u = 0, _ref13 = n - 1; 0 <= _ref13 ? _u <= _ref13 : _u >= _ref13; i = 0 <= _ref13 ? ++_u : --_u) {
        cluster = assignments[i];
        kClusters[cluster].push(values[i]);
      }
      tmpKMeansBreaks = [];
      for (j = _v = 0, _ref14 = num - 1; 0 <= _ref14 ? _v <= _ref14 : _v >= _ref14; j = 0 <= _ref14 ? ++_v : --_v) {
        tmpKMeansBreaks.push(kClusters[j][0]);
        tmpKMeansBreaks.push(kClusters[j][kClusters[j].length - 1]);
      }
      tmpKMeansBreaks = tmpKMeansBreaks.sort(function(a, b) {
        return a - b;
      });
      limits.push(tmpKMeansBreaks[0]);
      for (i = _w = 1, _ref15 = tmpKMeansBreaks.length - 1; _w <= _ref15; i = _w += 2) {
        if (!isNaN(tmpKMeansBreaks[i])) {
          limits.push(tmpKMeansBreaks[i]);
        }
      }
    }
    return limits;
  };


  color.brewer = brewer = {
    OrRd: ['#fff7ec', '#fee8c8', '#fdd49e', '#fdbb84', '#fc8d59', '#ef6548', '#d7301f', '#b30000', '#7f0000'],
    PuBu: ['#fff7fb', '#ece7f2', '#d0d1e6', '#a6bddb', '#74a9cf', '#3690c0', '#0570b0', '#045a8d', '#023858'],
    BuPu: ['#f7fcfd', '#e0ecf4', '#bfd3e6', '#9ebcda', '#8c96c6', '#8c6bb1', '#88419d', '#810f7c', '#4d004b'],
    Oranges: ['#fff5eb', '#fee6ce', '#fdd0a2', '#fdae6b', '#fd8d3c', '#f16913', '#d94801', '#a63603', '#7f2704'],
    BuGn: ['#f7fcfd', '#e5f5f9', '#ccece6', '#99d8c9', '#66c2a4', '#41ae76', '#238b45', '#006d2c', '#00441b'],
    YlOrBr: ['#ffffe5', '#fff7bc', '#fee391', '#fec44f', '#fe9929', '#ec7014', '#cc4c02', '#993404', '#662506'],
    YlGn: ['#ffffe5', '#f7fcb9', '#d9f0a3', '#addd8e', '#78c679', '#41ab5d', '#238443', '#006837', '#004529'],
    Reds: ['#fff5f0', '#fee0d2', '#fcbba1', '#fc9272', '#fb6a4a', '#ef3b2c', '#cb181d', '#a50f15', '#67000d'],
    RdPu: ['#fff7f3', '#fde0dd', '#fcc5c0', '#fa9fb5', '#f768a1', '#dd3497', '#ae017e', '#7a0177', '#49006a'],
    Greens: ['#f7fcf5', '#e5f5e0', '#c7e9c0', '#a1d99b', '#74c476', '#41ab5d', '#238b45', '#006d2c', '#00441b'],
    YlGnBu: ['#ffffd9', '#edf8b1', '#c7e9b4', '#7fcdbb', '#41b6c4', '#1d91c0', '#225ea8', '#253494', '#081d58'],
    Purples: ['#fcfbfd', '#efedf5', '#dadaeb', '#bcbddc', '#9e9ac8', '#807dba', '#6a51a3', '#54278f', '#3f007d'],
    GnBu: ['#f7fcf0', '#e0f3db', '#ccebc5', '#a8ddb5', '#7bccc4', '#4eb3d3', '#2b8cbe', '#0868ac', '#084081'],
    Greys: ['#ffffff', '#f0f0f0', '#d9d9d9', '#bdbdbd', '#969696', '#737373', '#525252', '#252525', '#000000'],
    YlOrRd: ['#ffffcc', '#ffeda0', '#fed976', '#feb24c', '#fd8d3c', '#fc4e2a', '#e31a1c', '#bd0026', '#800026'],
    PuRd: ['#f7f4f9', '#e7e1ef', '#d4b9da', '#c994c7', '#df65b0', '#e7298a', '#ce1256', '#980043', '#67001f'],
    Blues: ['#f7fbff', '#deebf7', '#c6dbef', '#9ecae1', '#6baed6', '#4292c6', '#2171b5', '#08519c', '#08306b'],
    PuBuGn: ['#fff7fb', '#ece2f0', '#d0d1e6', '#a6bddb', '#67a9cf', '#3690c0', '#02818a', '#016c59', '#014636'],
    Spectral: ['#9e0142', '#d53e4f', '#f46d43', '#fdae61', '#fee08b', '#ffffbf', '#e6f598', '#abdda4', '#66c2a5', '#3288bd', '#5e4fa2'],
    RdYlGn: ['#a50026', '#d73027', '#f46d43', '#fdae61', '#fee08b', '#ffffbf', '#d9ef8b', '#a6d96a', '#66bd63', '#1a9850', '#006837'],
    RdBu: ['#67001f', '#b2182b', '#d6604d', '#f4a582', '#fddbc7', '#f7f7f7', '#d1e5f0', '#92c5de', '#4393c3', '#2166ac', '#053061'],
    PiYG: ['#8e0152', '#c51b7d', '#de77ae', '#f1b6da', '#fde0ef', '#f7f7f7', '#e6f5d0', '#b8e186', '#7fbc41', '#4d9221', '#276419'],
    PRGn: ['#40004b', '#762a83', '#9970ab', '#c2a5cf', '#e7d4e8', '#f7f7f7', '#d9f0d3', '#a6dba0', '#5aae61', '#1b7837', '#00441b'],
    RdYlBu: ['#a50026', '#d73027', '#f46d43', '#fdae61', '#fee090', '#ffffbf', '#e0f3f8', '#abd9e9', '#74add1', '#4575b4', '#313695'],
    BrBG: ['#543005', '#8c510a', '#bf812d', '#dfc27d', '#f6e8c3', '#f5f5f5', '#c7eae5', '#80cdc1', '#35978f', '#01665e', '#003c30'],
    RdGy: ['#67001f', '#b2182b', '#d6604d', '#f4a582', '#fddbc7', '#ffffff', '#e0e0e0', '#bababa', '#878787', '#4d4d4d', '#1a1a1a'],
    PuOr: ['#7f3b08', '#b35806', '#e08214', '#fdb863', '#fee0b6', '#f7f7f7', '#d8daeb', '#b2abd2', '#8073ac', '#542788', '#2d004b'],
    Set2: ['#66c2a5', '#fc8d62', '#8da0cb', '#e78ac3', '#a6d854', '#ffd92f', '#e5c494', '#b3b3b3'],
    Accent: ['#7fc97f', '#beaed4', '#fdc086', '#ffff99', '#386cb0', '#f0027f', '#bf5b17', '#666666'],
    Set1: ['#e41a1c', '#377eb8', '#4daf4a', '#984ea3', '#ff7f00', '#ffff33', '#a65628', '#f781bf', '#999999'],
    Set3: ['#8dd3c7', '#ffffb3', '#bebada', '#fb8072', '#80b1d3', '#fdb462', '#b3de69', '#fccde5', '#d9d9d9', '#bc80bd', '#ccebc5', '#ffed6f'],
    Dark2: ['#1b9e77', '#d95f02', '#7570b3', '#e7298a', '#66a61e', '#e6ab02', '#a6761d', '#666666'],
    Paired: ['#a6cee3', '#1f78b4', '#b2df8a', '#33a02c', '#fb9a99', '#e31a1c', '#fdbf6f', '#ff7f00', '#cab2d6', '#6a3d9a', '#ffff99', '#b15928'],
    Pastel2: ['#b3e2cd', '#fdcdac', '#cbd5e8', '#f4cae4', '#e6f5c9', '#fff2ae', '#f1e2cc', '#cccccc'],
    Pastel1: ['#fbb4ae', '#b3cde3', '#ccebc5', '#decbe4', '#fed9a6', '#ffffcc', '#e5d8bd', '#fddaec', '#f2f2f2']
  };


  /*
  interpolates between a set of colors uzing a bezier spline
  */


  bezier = function(colors) {
    var I, I0, I1, c, lab0, lab1, lab2, lab3, _ref1, _ref2, _ref3;

    colors = (function() {
      var _i, _len, _results;

      _results = [];
      for (_i = 0, _len = colors.length; _i < _len; _i++) {
        c = colors[_i];
        _results.push(color(c));
      }
      return _results;
    })();
    if (colors.length == 2) {
      _ref1 = (function() {
        var _i, _len, _results;

        _results = [];
        for (_i = 0, _len = colors.length; _i < _len; _i++) {
          c = colors[_i];
          _results.push(c.lab());
        }
        return _results;
      })(), lab0 = _ref1[0], lab1 = _ref1[1];
      I = function(t) {
        var i, lab;

        lab = (function() {
          var _i, _results;

          _results = [];
          for (i = _i = 0; _i <= 2; i = ++_i) {
            _results.push(lab0[i] + t * (lab1[i] - lab0[i]));
          }
          return _results;
        })();
        return color.lab.apply(color, lab);
      };
    } else if (colors.length == 3) {
      _ref2 = (function() {
        var _i, _len, _results;

        _results = [];
        for (_i = 0, _len = colors.length; _i < _len; _i++) {
          c = colors[_i];
          _results.push(c.lab());
        }
        return _results;
      })(), lab0 = _ref2[0], lab1 = _ref2[1], lab2 = _ref2[2];
      I = function(t) {
        var i, lab;

        lab = (function() {
          var _i, _results;

          _results = [];
          for (i = _i = 0; _i <= 2; i = ++_i) {
            _results.push((1 - t) * (1 - t) * lab0[i] + 2 * (1 - t) * t * lab1[i] + t * t * lab2[i]);
          }
          return _results;
        })();
        return color.lab.apply(color, lab);
      };
    } else if (colors.length == 4) {
      _ref3 = (function() {
        var _i, _len, _results;

        _results = [];
        for (_i = 0, _len = colors.length; _i < _len; _i++) {
          c = colors[_i];
          _results.push(c.lab());
        }
        return _results;
      })(), lab0 = _ref3[0], lab1 = _ref3[1], lab2 = _ref3[2], lab3 = _ref3[3];
      I = function(t) {
        var i, lab;

        lab = (function() {
          var _i, _results;

          _results = [];
          for (i = _i = 0; _i <= 2; i = ++_i) {
            _results.push((1 - t) * (1 - t) * (1 - t) * lab0[i] + 3 * (1 - t) * (1 - t) * t * lab1[i] + 3 * (1 - t) * t * t * lab2[i] + t * t * t * lab3[i]);
          }
          return _results;
        })();
        return color.lab.apply(color, lab);
      };
    } else if (colors.length == 5) {
      I0 = bezier(colors.slice(0, 3));
      I1 = bezier(colors.slice(2, 5));
      I = function(t) {
        if (t < 0.5) {
          return I0(t * 2);
        } else {
          return I1((t - 0.5) * 2);
        }
      };
    }
    return I;
  };

  color.interpolate.bezier = bezier;

--]]
