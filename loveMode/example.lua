BPM = 50

-- s2 = makeSample("drum/004_drum5.wav")
s1 = loadSong("Flatline.ogg")
s1:bind("c")
bindAxis(1,"c")
-- s2:bind("b")
g = makeGroup("group")
-- g2 = makeGroup("group2")
-- g:add("drum/000_drum1.wav")
g:add("pluck/BS D4 PI.wav")
-- g2:add("amencutup/007_AMENCUT_008.wav")
-- g2:add("can/000_1.wav")
g:bind("g")
-- g2:bind("h")

p = makePattern('test', 4)
p : add('X', "house/004_OH.wav")
p : set('....X.......X.X.')

gen = makeGenerator( 'Dsin' )
gen.attack = .4
gen.release = .2
gen.volumeL = 0
gen:setFunction(
	function ()
		local dat = {}

		for i=1, math.floor(1.2*BEATTIME*gen.sr) do
			dat[i] = math.abs(math.sin( (i*notes.D2 / gen.sr) * math.pi * 2 ))
		end

		return dat
	end
	)

gen2 = makeGenerator( 'Esin' )
gen2.attack = .4
gen2.release = .2
gen2.volumeR = 0
gen2:setFunction(
	function ()
		local dat = {}

		for i=1, math.floor(1.2*BEATTIME*gen2.sr) do
			dat[i] = math.abs(math.sin( (i*notes.E2 / gen2.sr) * math.pi * 2 ))
		end

		return dat
	end
	)

gen3 = makeGenerator( 'Asin' )
gen3.attack = .4
gen3.release = .2
gen3.volumeL = 0
gen3:setFunction(
	function ()
		local dat = {}

		for i=1, math.floor(1.2*BEATTIME*gen3.sr) do
			dat[i] = math.abs(math.sin( (i*notes.A2 / gen3.sr) * math.pi * 2 ))
		end

		return dat
	end
	)

gen4 = makeGenerator( 'Bsin' )
gen4.attack = .4
gen4.release = .2
gen4.volumeR = 0
gen4:setFunction(
	function ()
		local dat = {}

		for i=1, math.floor(1.2*BEATTIME*gen4.sr) do
			dat[i] = math.abs(math.sin( (i*notes.B2 / gen4.sr) * math.pi * 2 ))
		end

		return dat
	end
	)

p2 = makePattern('other', 2)
p3 = makePattern('third', 2)
p2 : add('d',gen)
p2 : add('e',gen2)
p2 : add('a',gen3)
p2 : add('b',gen4)
p3 : add('d',gen)
p3 : add('e',gen2)
p3 : add('a',gen3)
p3 : add('b',gen4)
-- p2.volumeL = 0
-- p3.volumeR = 0

genGroup = makeGroup("genGroup")
genGroup:add(gen)
genGroup:add(gen2)
genGroup:add(gen3)
genGroup:add(gen4)
genGroup:bind('r')
bindAxis(3,'r')

p2 : set('e.......a.......b.......e.......')
p3 : set('....e.......a.......b.......e...')

drums = makePattern('drums', 4)
drums : add("H","drum/004_drum5.wav")
drums : add("B","drum/005_drum6.wav")
drums : add('x', "drum/001_drum2.wav")
drums : add("C","drumtraks/001_DT Claps.wav")
drums : set('B...x...B...x...B...x...B...x.x.')

drums2 = makePattern('drums2', 8)
drums2 : add("1", "drumtraks/009_DT Snare.wav")
drums2 : add("2", "drumtraks/009_DT Snare.wav")
-- drums2 : add("c", "drumtraks/000_DT Cabasa.wav")
drums2 : set('1.2.1.2.1.2.1.2.')

noise = makeGenerator('noise')
noise.attack = 0.9
noise.release = 0.1
noise:setFunction(
	function ( )
		local dat = {}

		for i=1, math.floor(2*BEATTIME * noise.sr) do
			dat[i] = (math.random()/4 + 0.5) --* math.sin( (i*notes.B2 / gen4.sr) * math.pi * 2 )
		end

		return dat
	end
	)
noise:bind('n')

pluck = makePattern('pluck')
-- pluck : add("pluck/")