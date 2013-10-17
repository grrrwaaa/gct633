local ffi = require "ffi"
local lib = ffi.C

ffi.cdef [[

	void av_use_glut();
	void av_glut_timerfunc(int id);
]]

local debug_traceback = debug.traceback

local runloop = require "runloop"
local gl = require "gl"
local glu = require "glu"
local glut = require "glut"

local window= {
	width = 800, height = 600, fps = 60 
}

local firstdraw = true
frame = 0

--[[

void av_window_settitle(av_Window * self, const char * name) {
	glutSetWindowTitle(name);
}

void av_window_setfullscreen(av_Window * self, int b) {
	window.reload = true;
	window.is_fullscreen = b;
	if (b) {
		glutFullScreen();
		glutSetCursor(GLUT_CURSOR_NONE);
	} else {
		glutReshapeWindow(window.non_fullscreen_width, window.non_fullscreen_height);
		glutSetCursor(GLUT_CURSOR_INHERIT);
	}
}


void av_window_setdim(av_Window * self, int x, int y) {
	glutReshapeWindow(x, y);
	glutPostRedisplay();
}

av_Window * av_window_create() {
	return &win;
}

void av_state_reset(void * self) {
	window.reset();
}
void getmodifiers() {
	int mod = glutGetModifiers();
	window.shift = mod & GLUT_ACTIVE_SHIFT;
	window.alt = mod & GLUT_ACTIVE_ALT;
	window.ctrl = mod & GLUT_ACTIVE_CTRL;
}

void onkeydown(unsigned char k, int x, int y) {
	getmodifiers();
	
	switch(k) {
		case 3: 	// ctrl-C
		case 17:	// ctrl-Q
			exit(0);
			return;
		//case 18:	// ctrl-R
		//	av_reload();
		//	return;
		default: {
			//printf("k %d s %d a %d c %d\n", k, window.shift, window.alt, window.ctrl);
			if (window.onkey) {
				(window.onkey)(&win, 1, k);
			}
		}
	}
}

void onkeyup(unsigned char k, int x, int y) {
	getmodifiers();
	if (window.onkey) {
		(window.onkey)(&win, 2, k);
	}
}
--]]

local function getmodifiers() 
	local mod = glut.glutGetModifiers()
	window.shift = bit.band(mod, glut.GLUT_ACTIVE_SHIFT)
	window.alt = bit.band(mod, glut.GLUT_ACTIVE_ALT)
	window.ctrl = bit.band(mod, glut.GLUT_ACTIVE_CTRL)
end

local function onkeydown(k, x, y)
	getmodifiers() 

	if k == 3 or k == 17 then	-- ctrl-C, ctrl-Q
		if close then 
			local ok, err = pcall(close)
			if not ok then print(err) end
		end
		os.exit(0)
	elseif k == 27 then
		-- toggle fullscreen:
		window.fullscreen = not window.fullscreen
		changefullscreen()
	elseif keydown then
		local ok, err = pcall(keydown, k)
		if not ok then print("keydown:", err) end
	else
		print("keydown", k)
	end
end

local function onkeyup(k, x, y)
	getmodifiers() 

	if keyup then
		local ok, err = pcall(keyup, k)
		if not ok then print("keyup:", err) end
	else
		print("keyup", k)
	end
end

local specials = {
	[glut.GLUT_KEY_LEFT] = "left",
	[glut.GLUT_KEY_RIGHT] = "right",
	[glut.GLUT_KEY_UP] = "up",
	[glut.GLUT_KEY_DOWN] = "down",
	
	[glut.GLUT_KEY_PAGE_UP] = "page_up",
	[glut.GLUT_KEY_PAGE_DOWN] = "page_down",
	[glut.GLUT_KEY_HOME] = "home",
	[glut.GLUT_KEY_END] = "end",
	[glut.GLUT_KEY_INSERT] = "insert",
}

for i = 1,12 do
	specials[ glut["GLUT_KEY_F"..i] ] = "F"..i
end

local function onspecialkeydown(k, x, y)
	getmodifiers() 

	--[[
	// GLUT_KEY_LEFT
	#define CS(k) case GLUT_KEY_##k: key = AV_KEY_##k; break;
	switch(key){
		CS(LEFT) CS(UP) CS(RIGHT) CS(DOWN)
		CS(PAGE_UP) CS(PAGE_DOWN)
		CS(HOME) CS(END) CS(INSERT)

		CS(F1) CS(F2) CS(F3) CS(F4)
		CS(F5) CS(F6) CS(F7) CS(F8)
		CS(F9) CS(F10)	CS(F11) CS(F12)
	}
	#undef CS
	
	if (window.onkey) {
		(window.onkey)(&win, 1, key);
	}
	--]]
	if keydown then
		local ok, err = pcall(keydown, k, specials[k])
		if not ok then print("keydown:", err) end
	else
		print("specialdown", k, specials[k])
	end
end



local function onspecialkeyup(k, x, y)
	getmodifiers() 

	--[[
	// GLUT_KEY_LEFT
	#define CS(k) case GLUT_KEY_##k: key = AV_KEY_##k; break;
	switch(key){
		CS(LEFT) CS(UP) CS(RIGHT) CS(DOWN)
		CS(PAGE_UP) CS(PAGE_DOWN)
		CS(HOME) CS(END) CS(INSERT)

		CS(F1) CS(F2) CS(F3) CS(F4)
		CS(F5) CS(F6) CS(F7) CS(F8)
		CS(F9) CS(F10)	CS(F11) CS(F12)
	}
	#undef CS
	
	if (window.onkey) {
		(window.onkey)(&win, 1, key);
	}
	--]]
	
	if keyup then
		local ok, err = pcall(keyup, k, specials[k])
		if not ok then print("keyup:", err) end
	else
		print("specialup", k, specials[k])
	end
	
end

function onmouse(button, state, x, y)
	getmodifiers()
	window.button = button
	if mouse then
		local ok, err = pcall(mouse, state == 0 and "down" or "up", window.button, x / window.width, 1 - y / window.height)
		if not ok then print(debug_traceback(err)) end
	end
end

function onmotion(x, y)
	if mouse then
		local ok, err = pcall(mouse, "drag", window.button, x / window.width, 1 - y / window.height)
		if not ok then print(debug_traceback(err)) end
	end
end

function onpassivemotion(x, y)
	if mouse then
		local ok, err = pcall(mouse, "move", window.button, x / window.width, 1 - y / window.height)
		if not ok then print(debug_traceback(err)) end
	end
end

--[[

void onvisibility(int state) {
	if (window.onvisible) (window.onvisible)(&win, state);
}
--]]

local function ondisplay() end

local function onreshape(w, h)
	window.width = w
	window.height = h
	--[[
	if (!window.is_fullscreen) {
		window.non_fullscreen_width = window.width;
		window.non_fullscreen_height = window.height;
	}
	if (window.onresize) {
		(window.onresize)(&win, w, h);
	}
	--]]
	glut.glutPostRedisplay()
end

local function onidle() end

local function registerCallbacks()
	glut.glutKeyboardFunc(onkeydown);
	glut.glutKeyboardUpFunc(onkeyup);
	glut.glutSpecialFunc(onspecialkeydown);
	glut.glutSpecialUpFunc(onspecialkeyup);
	
	glut.glutMouseFunc(onmouse);
	glut.glutMotionFunc(onmotion);
	glut.glutPassiveMotionFunc(onpassivemotion);
	--[[
	glut.glutVisibilityFunc(onvisibility)
	
	--]]
	
	-- enable idle for silly frame rates
	--glut.glutIdleFunc(onidle)
	glut.glutReshapeFunc(onreshape)
	glut.glutDisplayFunc(ondisplay)
	
	glut.glutTimerFunc(1000/window.fps, ffi.C.av_glut_timerfunc, window.id)
end

local windowed_width, windowed_height
function enter_fullscreen()
	print("enter fullscreen")
	windowed_width = window.width
	windowed_height = window.height
	if ffi.os == "OSX" then
		glut.glutFullScreen()
	else
		-- destroy current context:
		if window.id and ondestroy then ondestroy() end
		-- go game mode
		local sw, sh = glut.glutGet(glut.GLUT_SCREEN_WIDTH), glut.glutGet(glut.GLUT_SCREEN_HEIGHT)
		print("full res", sw, sh)
		if sw == 0 or sh == 0 then sw, sh = 1024, 768 end
		glut.glutGameModeString(string.format("%dx%d:24", sw, sh))
		--print("refresh", glut.glutGameModeGet(glut.GLUT_GAME_MODE_REFRESH_RATE))
		
		window.id = glut.glutEnterGameMode()
		print("new id", window.id)
		glut.glutSetWindow(window.id)
		registerCallbacks()
		print("registered callbacks")
		firstdraw = true
		
		--if window.oncreate then window:oncreate() end
		--onreshape(w, h)?
		-- hide/show to get focus for key callbacks:
		glut.glutHideWindow()
		glut.glutShowWindow()
	end
	glut.glutSetCursor(glut.GLUT_CURSOR_NONE)
	print("entered fullscreen")
end

function exit_fullscreen()
	print("exit fullscreen")
	if ffi.os == "OSX" then
		glut.glutReshapeWindow(windowed_width, windowed_height)
	else
		-- destroy current context:
		if window.id and ondestroy then ondestroy() end
		
		glut.glutLeaveGameMode()
		window.id = glut.glutCreateWindow("")
		glut.glutSetWindow(window.id)
		registerCallbacks()
		firstdraw = truec
		
		-- refresh:
		if oncreate then window:oncreate() end
		-- get new dimensions & call reshape?
		--onreshape(w, h)?
		
	end
	glut.glutSetCursor(glut.GLUT_CURSOR_NONE)
end

function changefullscreen()
	if window.fullscreen  then enter_fullscreen() else exit_fullscreen() end
end

function window:redisplay()
	frame = frame + 1
	
	---[[
	if firstdraw then	
		print("OpenGL VERSION", gl.GetString(gl.VERSION))
		print("OpenGL VENDOR", gl.GetString(gl.VENDOR))
		print("OpenGL RENDERER", gl.GetString(gl.RENDERER))
		print("OpenGL SHADING_LANGUAGE_VERSION", gl.GetString(gl.SHADING_LANGUAGE_VERSION))
		gl.Enable(gl.MULTISAMPLE)	
		gl.Enable(gl.POLYGON_SMOOTH)
		gl.Hint(gl.POLYGON_SMOOTH_HINT, gl.NICEST)
		gl.Enable(gl.LINE_SMOOTH)
		gl.Hint(gl.LINE_SMOOTH_HINT, gl.NICEST)
		gl.Enable(gl.POINT_SMOOTH)
		gl.Hint(gl.POINT_SMOOTH_HINT, gl.NICEST)
		glu.assert("hints")
		if window.oncreate then window:oncreate() end
		firstdraw = false
	end
	
	gl.Viewport(0, 0, window.width, window.height)
	glu.assert("viewport")
	
	if window.stereo  then
		window.eye = 1
		gl.DrawBuffer(gl.BACK_RIGHT)
		gl.Clear()
		if draw then 
			local ok, err = xpcall(draw, debug_traceback)
			if not ok then
				print(err)
				draw = nil
			end
		end
		window.eye = -1
		gl.DrawBuffer(gl.BACK_LEFT)
		gl.Clear()
		if draw then 
			local ok, err = xpcall(draw, debug_traceback)
			if not ok then
				print(err)
				draw = nil
			end
		end
		window.eye = 0
		gl.DrawBuffer(gl.BACK)
	else	
		gl.Clear()
		if draw then 
			local ok, err = xpcall(draw, debug_traceback)
			if not ok then
				print(err)
				draw = nil
			end
		end
	end
	--]]
	
	glut.glutSwapBuffers()
	glut.glutPostRedisplay()
	
	
	return 1
end



function window:create()
	
	if (window.stereo) then
		glut.glutInitDisplayString("rgb double depth>=16 alpha samples<=4 stereo")
	else
		glut.glutInitDisplayString("rgb double depth>=16 alpha samples<=4")
	end
	
	--glut.glutInitDisplayMode(GLUT_RGBA | GLUT_DOUBLE | GLUT_DEPTH); // | GLUT_MULTISAMPLE);
	glut.glutInitWindowSize(window.width, window.height);
	glut.glutInitWindowPosition(0, 0);
	
	if window.fullscreen  then
		enter_fullscreen()
	else
		window.id = glut.glutCreateWindow("")
	end
	
	gl.init()
		
	glut.glutSetWindow(window.id)
	registerCallbacks()
	
	runloop.insert(function() window:redisplay() end)
	
	
	--[[
	
	//	glut.glutIgnoreKeyRepeat(1);
//	glut.glutSetCursor(GLUT_CURSOR_NONE);

	--]]
	
	--core.av_glut_timerfunc(0)
	--glut.glutMainLoop()
	
	ffi.C.av_use_glut()
end

return window
