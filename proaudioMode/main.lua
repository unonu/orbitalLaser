require("proAudioRt")
if not proAudio.create( 32, 44100, 2048 ) then os.exit(1) end

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

qwertyImage = love.graphics.newImage("Qwerty.png")

function love.load()
	love.window.setMode(1280,720,{vsync = false, resizable = true})
	local joysticks = love.joystick.getJoysticks()
	controller = joysticks[1]
	-- print(controller:getName())

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
			print("SERVER",s[1].." bound to "..s.bind)
		elseif s.pattern then
			patterns[#patterns+1] = s
		elseif s.cue then
			cues[s.cue][#cues[s.cue]+1] = s
		elseif s.reset then
			-- proAudio.soundStop()
			BPM = s.bpm
			BEATTIME = 60 / BPM
			cuePipe:push(s)
			bindings = {}
			cues = {}
			patterns = {}
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

end

function love.draw()
	love.graphics.setColor(255,255,255)
	love.graphics.print("Listener status: ",0,4)
	love.graphics.print("Player status: ",0,20)
	love.graphics.print(love.timer.getFPS(),500,0)

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

	if RECORD then
		love.graphics.setColor(255,0,0)
		love.graphics.print("RECORDING",4,708)
		love.graphics.setLineWidth(4)
		love.graphics.rectangle("line", 0,0,1280,720)
		love.graphics.setLineWidth(1)
	end
end

function love.keypressed( k )
	if bindings[k] then
		local target = bindings[k]
		for _=1, #target do
			proAudio.soundPlay(target[_], 	target.volumeL,
											target.volumeR,
											target.disparity,
											target.pitch)
		end
	end
	if k == 'escape' then
		love.event.quit()
	elseif k == 'backspace' then
		proAudio.soundStop()
		bindings = {}
		cues = {}
		patterns = {}
	elseif k == ' ' then
		RECORD = not RECORD
	end
end

function love.threaderror(thread, errorstr)
	print("Thread error!\n"..errorstr)
end

function love.quit()
	-- shutdown --
	proAudio.destroy()

	return false
end
