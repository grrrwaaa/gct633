local audio = require "audio"
-- adjust this to set the IO latency (in seconds)
audio.latency(0.03)

-- this may cause feedback!!
function route_input(l, r)
	return l, r
end


audio.play(route_input)

-- show it:
audio.scope()
