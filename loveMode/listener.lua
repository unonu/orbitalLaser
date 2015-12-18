do
require("love.timer")
require("love.audio")
require("love.sound")

love.timer.sleep(2)

library 	= 'songs/'--(os.getenv("HOME") or '').."/Music/"
samples 	= 'samples/'
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
axisBindings= {}

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
	s[1] = love.audio.newSource(samples..sample,"static")
	return s
end

function loadSong( song )
	local s =
		{name 		= song,
		 pitch 		= 1,
		 disparity 	= 0,
		 volumeL 	= 1,
		 volumeR 	= 1,}
	setmetatable(s, Sample)
	s[1] = love.audio.newSource(library..song,"stream")
	return s
end

function Sample:bind( key )
	print("binding sample "..self.name.." to "..key)
	self.bind = key
	bindings[#bindings+1] = self
end

function Sample:copy( name )
	local s =
		{name = name,
		 pitch = self.pitch,
		 disparity = self.disparity,
		 volumeL = self.volumeL,
		 volumeR = self.volumeR,}
	setmetatable(s, Sample)
	s[1] = self[1]:clone()
	return s
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
	-- Please don't add songs to groups
	if type(sample) == "string" then
		self[#self+1] = love.audio.newSource(samples..sample,"static")
	elseif type(sample) == "table" then
		self[#self+1] = sample[1]
	else
		self[#self+1] = sample
	end
end

function Group:copy( name )
	local g =
		{name = name,
		 pitch = self.pitch,
		 disparity = self.disparity,
		 volumeL = self.volumeL,
		 volumeR = self.volumeR,}
	setmetatable(g, Group)
	for _=1, #self do
		g[_] = self[_]:clone()
	end
	groupsp[#groups+1] = g
	return g
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
			self[symbol] = love.audio.newSource(samples..sample,"static")
		elseif type(sample) == "table" then
			self[symbol] = sample[1]
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

function Pattern:copy( name )
	local p =
		{name = name,
		 pitch		= self.pitch,
		 disparity 	= self.disparity,
		 volumeL	= self.volumeL,
		 volumeR	= self.volumeR,
		 pattern 	= self.pattern,
		 resolution = self.resolution,
		 marker 	= self.marker,
		 len 		= self.len}
	setmetatable(p, Pattern)
	for _,v in pairs(self) do
		if type(v) == "Source" then
			p[_] = v:clone()
		else
			p[_] = v
		end
	end
	patterns[#patterns+1] = p
	return p
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
		 release	= 0,
		 data 		= nil,}
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
	self.data = love.sound.newSoundData( #data, self.sr, 16, 1)
	for i=1, #data do
		self.data:setSample(i-1, data[i])
	end
	self[1] = love.audio.newSource( self.data )
	print(tostring(self[1]), tostring(self.data), #data )
end

function Generator:bind( key )
	print("binding gen "..self.name.." to "..key)
	self.bind = key
	bindings[#bindings+1] = self
end

function Generator:copy( name )
	local g =
		{name = name,
		 pitch		= self.pitch,
		 disparity 	= self.disparity,
		 volumeL	= self.volumeL,
		 volumeR	= self.volumeR,
		 sr 		= self.sr,
		 foo 		= self.foo,
		 attack		= self.attack,
		 release	= self.release,
		 data 		= self.data,}
	setmetatable(g, Generator)
	g[1] = self[1]:clone()
	groupsp[#generators+1] = g
	return g
end

function bindAxis( num, key )
	axisBindings[num] = key
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
			stage:push({reset=true, bpm = BPM, js1 = axisBindings[1],
						js2 = axisBindings[2], js3 = axisBindings[3], js4 = axisBindings[4]})
			axisBindings = {}
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