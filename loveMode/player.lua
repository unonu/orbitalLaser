do
require("love.timer")
require("love.audio")

cuePipe 	= love.thread.getChannel("cues")
patPipe 	= love.thread.getChannel("patterns")
bindings 	= {}
cues 		= {}
patterns 	= {}

BPM 		= cuePipe:demand()
T_SIGNATURE = cuePipe:demand()
BASE_KEY 	= cuePipe:demand()
SHUTDOWN 	= cuePipe:demand()
RECORD 		= cuePipe:demand()
BEATTIME 	= cuePipe:demand()
RESOLUTION 	= cuePipe:demand()

while true do
	local p = cuePipe:pop()
	if p then cues = {} end
	while p do
		if p.bpm then
			BPM = p.bpm
			BEATTIME = 60 / BPM
		else
			cues[#cues+1] = p
		end
		p = cuePipe:pop()
	end
	p = patPipe:pop()
	if p then patterns = {} end
	while p do
		patterns[#patterns+1] = p
		p = patPipe:pop()
	end

	-- loop a measure --
	local time
	for beat=1, T_SIGNATURE[1] * RESOLUTION do
		time = love.timer.getTime()

		-- play recorded notes for this beat --
		-- for i=1,#cues do
		-- 	local target = cues[i]
		-- 	for _=1, #target do
		--
		-- 	end
		-- end

		-- play pattern notes for this beat --
		for i=1, #patterns do
			local target = patterns[i]
			if target[target.marker] then
				target[target[target.marker]]:rewind()
				target[target[target.marker]]:play()
			end
			target.marker = (target.marker % target.len) + 1
		end

		-- rest --
		while love.timer.getTime() - time < BEATTIME / RESOLUTION do end
	end
end

end