BPM = 40

s1 = makeSample("house/000_BD.wav")
s1:bind("s")

g = makeGroup("group")
g:add("hit/bandpass-blart.wav")
g:add("hit/laser-powered-sword.wav")

g:bind("g")

bindAxis(1,"g")

gen = makeGenerator("gen1")
gen.attack = .4
gen.release = .2
gen:setFunction(
	function ()
		local dat = {}

		for i=1, math.floor(1*BEATTIME*gen.sr) do
			dat[i] = math.abs(math.sin( (i*notes.D2 / gen.sr) * math.pi * 2 ))
		end

		return dat
	end
	)

pat = makePattern("pattern?")
pat : add("x", "hit/bandpass-blart.wav")
pat : add("y", "hit/laser-powered-sword.wav")
pat : add("g", gen[1])
pat : set("x...y...g...g...")

hotline = loadSong("Flatline.ogg")
hotline : bind("m")
bindAxis(3,"m")