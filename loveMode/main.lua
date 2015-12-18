-- constants --

BPM = 100
T_SIGNATURE = {4,4}
BASE_KEY = {"C4"}
SHUTDOWN = false
RECORD = false
BEATTIME = 60 / BPM
RESOLUTION = 32

-- backend --

stage = love.thread.getChannel("stage")
cuePipe = love.thread.getChannel("cues")
patPipe = love.thread.getChannel("patterns")

listener = love.thread.newThread("listener.lua")
player = love.thread.newThread("player.lua")

bindings 	= {}
cues 		= {}
patterns 	= {}

jsBindings = {}

bpmTracker = {0,0,0}

qwertyImage = love.graphics.newImage("Qwerty.png")

function love.load()
	love.window.setMode(1280,720,{vsync = false, resizable = true})
	local joysticks = love.joystick.getJoysticks()
	controller = joysticks[1]
	if controller then
		print(controller:getName(), controller:getAxes())
	end

	-- start the listener --
	listener:start()
	-- should double check if the listener is running
	stage:supply(BPM)
	stage:supply(T_SIGNATURE)
	stage:supply(BASE_KEY)
	stage:supply(SHUTDOWN)
	stage:supply(RECORD)
	stage:supply(BEATTIME)
	stage:supply(RESOLUTION)

	--start the player --
	player:start()
	cuePipe:supply(BPM)
	cuePipe:supply(T_SIGNATURE)
	cuePipe:supply(BASE_KEY)
	cuePipe:supply(SHUTDOWN)
	cuePipe:supply(RECORD)
	cuePipe:supply(BEATTIME)
	cuePipe:supply(RESOLUTION)
end

function love.update(dt)
	-- load from stage --
	local s = stage:pop()
	while s do
		if s.bind then
			bindings[s.bind] = s
			print("SERVER",tostring(s[1]).." bound to "..s.bind)
		elseif s.pattern then
			patterns[#patterns+1] = s
		elseif s.cue then
			cues[s.cue][#cues[s.cue]+1] = s
		elseif s.reset then
			BPM = s.bpm
			BEATTIME = 60 / BPM
			cuePipe:push(s)
			for k,v in pairs(bindings) do
				for _=1, #v do
					v[_]:stop()
					v[_]:rewind()
				end
			end
			bindings = {}
			cues = {}
			patterns = {}
			jsBindings[1] = s.js1
			jsBindings[2] = s.js2
			jsBindings[3] = s.js3
			jsBindings[4] = s.js4
		end
		s = stage:pop()
	end

	-- send to player --
	if #cues > 0 then
		for _=1, #cues do
			cuePipe:push(cues[_])
		end
		cues = {}
	end
	if #patterns > 0 then
		for _=1, #patterns do
			patPipe:push(patterns[_])
		end
		patterns = {}
	end

	-- bend it like Aang ;P --
	if controller then
	for i=1, 4 do
		if jsBindings[i] then
			local target = bindings[jsBindings[i]]
			local shift = controller:getAxis(i)
			for _=1, #target do
				target[_]:setPitch(math.max( 1 + 1*shift, 0.00001))
			end
		end
	end
	end
	-- or maybe Zuko, since this is straight fire XD --

	-- keep track of beats --
	local elapse = love.timer.getTime() - bpmTracker[1]
	if elapse > 20 then
		bpmTracker[1] = love.timer.getTime()
		bpmTracker[2] = 0
	end
	bpmTracker[3] = (bpmTracker[2]/elapse) * 60

end

function love.draw()
	love.graphics.setColor(255,255,255)
	love.graphics.print("Listener status: ",0,4)
	love.graphics.print("Player status: ",0,20)
	love.graphics.print("FPS: "..love.timer.getFPS(),0,36)
	love.graphics.print("Detected BPM: "..bpmTracker[3],0,48)

	love.graphics.draw(qwertyImage,0,330)

	if listener:isRunning() then
		love.graphics.setColor(0,255,0)
	else
		love.graphics.setColor(255,0,0)
	end
	love.graphics.circle("fill",112,12,6,16)
	if player:isRunning() then
		love.graphics.setColor(0,255,0)
	else
		love.graphics.setColor(255,0,0)
	end
	love.graphics.circle("fill",98,26,6,16)

	-- if RECORD then
	-- 	love.graphics.setColor(255,0,0)
	-- 	love.graphics.print("RECORDING",4,708)
	-- 	love.graphics.setLineWidth(4)
	-- 	love.graphics.rectangle("line", 0,0,1280,720)
	-- 	love.graphics.setLineWidth(1)
	-- end
end

function love.keypressed( k )
	if bindings[k] then
		local target = bindings[k]
		if not target.slices then target.slices = {} end
		for _=1, #target do
			if love.keyboard.isDown('lshift','rshift') then
				target[_]:rewind()
				target[_]:stop()
				target.slices = {}
			-- I added markers to make slicing easy
			elseif love.keyboard.isDown('lalt','ralt') then
				target.slices[_] = target[_]:tell("samples")
				print("set slice for ",k, target.slices[_])
			else
				target[_]:seek(target.slices[_] or 0, "samples")
				target[_]:play()
			end
		end
	end
	if k == 'escape' then
		love.event.quit()
	elseif k == 'backspace' then
		love.audio.stop()
		bindings = {}
		cues = {}
		patterns = {}
	-- elseif k == ' ' then
	-- 	RECORD = not RECORD
	end
end

function love.mousepressed( x,y,button )
	bpmTracker[2] = bpmTracker[2] + 1
end

function love.threaderror(thread, errorstr)
	print("Thread error!\n"..errorstr)
end

function love.quit()
	-- shutdown --
	return false
end
