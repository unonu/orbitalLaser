do
require("love.timer")
require("proAudioRt")

love.timer.sleep(2)

samples 	= './samples/'
stage 		= love.thread.getChannel("stage")
SCRIPT 		= stage:demand()
BPM 		= stage:demand()
T_SIGNATURE = stage:demand()
BASE_KEY 	= stage:demand()
SHUTDOWN 	= stage:demand()
RECORD 		= stage:demand()
BEATTIME 	= stage:demand()
RESOLUTION 	= stage:demand()
notes 		= require("noteLookup")
bindings 	= {}
groups 		= {}
patterns 	= {}
generators 	= {}

function fModifyTime(file)
	local f = io.popen("stat "..file)
	if not f then return false end
	return f:read("*a") : match("Modify: ([-:%.%d ]+) %-%d+\n")
end

-- samples --
Sample = {}
Sample.__index = Sample

function makeSample( sample )
	local s =
		{name 		= sample,
		 pitch 		= 1,
		 disparity 	= 0,
		 volumeL 	= 1,
		 volumeR 	= 1,}
	setmetatable(s, Sample)
	s[1] = proAudio.sampleFromFile(samples..sample)
	proAudio.soundUpdate( s[1], s.volumeL, s.volumeR, s.disparity, s.pitch )
	return s
end

function Sample:bind( key )
	print("binding sample "..self.name.." to "..key)
	self.bind = key
	bindings[#bindings+1] = self
end

-- groups --
Group = {}
Group.__index = Group

function makeGroup(name)
	local g =
		{name 		= name,
		 pitch 		= 1,
		 disparity 	= 0,
		 volumeL 	= 1,
		 volumeR 	= 1,}
	setmetatable(g, Group)
	groups[#groups+1] = g

	return g
end

function Group:bind( key )
	print("binding group "..self.name.." to "..key)
	self.bind = key
	bindings[#bindings+1] = self
end

function Group:add(sample)
	if type(sample) == "string" then
		self[#self+1] = proAudio.sampleFromFile(samples..sample)
	elseif type(sample) == "table" then
		self[#self+1] = sample[1]
		proAudio.soundUpdate( self[#self], sample.volumeL, sample.volumeR, sample.disparity, sample.pitch )
	else
		self[#self+1] = sample
	end
end

-- patterns --
Pattern = {}
Pattern.__index = Pattern

function makePattern(name, resolution)
	local p =
		{name 		= name,
		 pitch		= 1,
		 disparity 	= 0,
		 volumeL	= 1,
		 volumeR	= 1,
		 pattern 	= '',
		 resolution = resolution or 4,
		 marker 	= 1,
		 len 		= 0}
	setmetatable(p, Pattern)
	patterns[#patterns+1] = p
	return p
end

function Pattern:add( symbol, sample )
	if symbol ~= '.' then
		if type(sample) == "string" then
			self[symbol] = proAudio.sampleFromFile(samples..sample)
		elseif type(sample) == "table" then
			self[symbol] = sample[1]
			proAudio.soundUpdate( self[symbol], sample.volumeL, sample.volumeR, sample.disparity, sample.pitch )
		else
			self[symbol] = sample
		end
	end
end

function Pattern:set( pattern )
	self.pattern = pattern
	local mul = RESOLUTION / self.resolution
	for i=1, #pattern do
		local s = self.pattern:sub(i,i)
		self[((i-1)*mul)+1] = self[s] and s or nil
	end
	self.len = ( RESOLUTION / self.resolution ) * #self.pattern
end

-- generator --
Generator = {}
Generator.__index = Generator

function makeGenerator(name)
	local g =
		{name = name,
		 pitch		= 1,
		 disparity 	= 0,
		 volumeL	= 1,
		 volumeR	= 0,
		 sr 		= 44100,
		 foo 		= true,
		 attack		= 0,
		 release	= 0,}
	setmetatable(g, Generator)
	generators[#generators+1] = g
	return g
end

function Generator:setFunction( func )
	local data = func()
	local at = math.floor(#data * self.attack)
	local re = math.floor(#data * self.release)
	for i=1, at do
		data[i] = data[i] * (i-1) / (at-1)
	end
	for i=0, re do
		data[#data-i] = data[#data-i] * (i) / (re)
	end
	self[1] = proAudio.sampleFromMemory( data, self.sr )
	proAudio.soundUpdate( self[1], self.volumeL, self.volumeR, self.disparity, self.pitch )
end

function Generator:bind( key )
	print("binding gen "..self.name.." to "..key)
	self.bind = key
	bindings[#bindings+1] = self
end

local lastModified = "0"
while true do
	local m = nil
	while not m do m = fModifyTime(SCRIPT) end
	if m > lastModified then
		print("script was modified")
		lastModified = m
		groups		= {}
		bindings	= {}
		patterns	= {}
		local s, e = pcall(loadfile(SCRIPT))
		if not s then
			print(e)
		else
			-- push the samples to the server --
			stage:push({reset=true, bpm = BPM})
			BEATTIME = 60 / BPM
			for _=1, #bindings do
				print(_, bindings[_])
				stage:push(bindings[_])
				print("LISTENER", "pushed to server")
			end
			for _=1, #patterns do
				stage:push(patterns[_])
				print("LISTENER", "pushed pattern to server", _)
			end
		end
	end
	love.timer.sleep(0.2)
end

end