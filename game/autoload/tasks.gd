extends Node
## The Goose-style to-do list. Everything except the detector is optional mischief.

signal task_completed(task: Dictionary)

const DEFS := [
	{"id": "tickle_aurora", "layer": 0, "text": "surf an aurora's electric field"},
	{"id": "bonk_satellite", "layer": 0, "text": "high-five a satellite"},
	{"id": "overclock", "layer": 0, "text": "go faster than you were born"},
	{"id": "photobomb_star", "layer": 1, "text": "photobomb a shooting star"},
	{"id": "zap_noctilucent", "layer": 1, "text": "zap a night-glowing cloud"},
	{"id": "startle_balloon", "layer": 2, "text": "startle a weather balloon"},
	{"id": "ozone_circle", "layer": 2, "text": "draw a circle in the ozone"},
	{"id": "scatter_birds", "layer": 3, "text": "scatter a flock of birds"},
	{"id": "thread_airplane", "layer": 3, "text": "fly through an airplane"},
	{"id": "make_rain", "layer": 3, "text": "make a cloud rain"},
	{"id": "get_detected", "layer": 4, "text": "get counted by the detector"},
]

var done := {}


func reset() -> void:
	done.clear()


func is_done(id: String) -> bool:
	return done.get(id, false)


func complete(id: String) -> void:
	if done.get(id, false):
		return
	done[id] = true
	for d in DEFS:
		if d["id"] == id:
			task_completed.emit(d)
			return


func optional_done_count() -> int:
	var count := 0
	for d in DEFS:
		if d["id"] != "get_detected" and done.get(d["id"], false):
			count += 1
	return count


func optional_total() -> int:
	return DEFS.size() - 1


func all_optional_done() -> bool:
	return optional_done_count() >= optional_total()
