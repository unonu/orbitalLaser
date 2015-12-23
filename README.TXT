*NOTE* This project was made using Löve 9.x.
It will likely NOT WORK with the newly
released Löve 10.x, so check your versions
first. Literally five days later? C'mon...

Orbital Laser is a live coding engine devoloped by
me - ウノヌ - for a class. It doesn't quite follow
conventional live coding paradigms, but I think it
has some potential worth a little more polish. It
relies pretty heavily on Löve, but what doesn't?

	:Links:

http://viremo.eludi.net/proteaAudio/index.html
https://love2d.org/

	:Features:

proAudio version:
	-- Samples
	  -- Various loaders
	  -- Bind to key
	-- Groups
	  -- Group samples/generators
	  -- Bind to key
	-- Patterns
	  -- Sequence samples/generators
	  -- Variable resolution (default quarter note)
	-- Generators
	  -- Mathematically driven (defined by functions)
	  -- Bind to key

Löve version:
	-- Samples
	  -- Various loaders
	  -- Bind to key
	  -- Pitch bend
	  -- Cloneable
	-- Songs
	  -- Various loaders
	  -- Streaming
	  -- Slicing
	  -- Bind to key
	  -- Pitch bend
	  -- Cloneable
	-- Groups
	  -- Group samples/generators
	  -- Bind to key
	  -- Cloneable
	-- Patterns
	  -- Sequence samples/generators
	  -- Variable resolution (default quarter note)
	  -- Cloneable
	-- Generators
	  -- Mathematically driven (defined by functions)
	  -- Bind to key
	  -- Cloneable
	-- Pitch Bending

	:To Run:

1 - make sure you have Löve2D installed.
2 - navigate to your desired version (love or proAudio.)

	-proAudio-
3 - have a version of the proteaaudio library
    complied for your platform (linux-64 included)
4 - place the proteaaudio library proAudioRt.so in
    the same folder as the main.lua file.
5 - run 'love ./ <file-name>' where <file-name> is
    the name of the script you will be working
    from.

    -Löve2D-
3 - run 'love ./ <file-name>' where <file-name> is
    the name of the script you will be working
    from.

X - now place your sample library in 'samples/'
    and your songs in 'songs/' and you're ready!

    :Notes:

For full documentation on the actual language,
contact me at unonuorea at gmail dot com.
Otherwise take a look at the example script or the
listener routine to see usage.

For pitch bending, any gamepad with analogue
sticks should work. Note that when you bind a song
or sample to a key, then bind that key to an axis
for bending, then any pattern or group that the
sound is a part of will be affected by the pitch
bend. This may be desireable. Because patterns
cannot be bound to a key, they cannot be directly
bent, however if you create a group with all the
sounds you want for a pattern then add them to the
pattern, then bind the group to a key then bind an
axis to that key, you can bend the sounds in a
pattern.

Note that in the proAudio version, sounds in
groups only honour the /group's/ playback
parameters (that is pitch, volumeL etc.) Also note
that in the Löve version, although these values
were not removed, it does not affect the playback.

You probably won't find this too easily in the
source, but pressing [shift]+[key] stops whatever
audio is bound to that key. Pressing [alt]+[key]
will place a marker at that point in the audio.
Then when [key] is pressed again, it will rewind
to that poing. Pressing [shift]+[key] or altering
the script will remove the marker. Markers also
work for groups. Markers cannot be added from the
script.

Clicking on the main (Löve) window will make the
program try to guess the BPM you're clicking. It's
not super precise, but it's relatively accurate.

	:Major Issues:

Low timing resolution (you can hear the latency)
Keybinding playback latency
BPM detector is iffy
High CPU usage (199% on a Haswell i7 (4700MQ))

	-proAudio-
Too many sounds causes playback glitches
Samples can't be too long
Altering sound properties (pitch or disparity) can
  cause undesired effects
