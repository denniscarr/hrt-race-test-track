## Manages collision between horses & makes sure to report only one instance of the same clash
## per-tick.
class_name ClashManager
extends Node

## Array of tupples containing the names of the horses that have already touched this frame
var _clash_pairs_this_tick: Array[PackedStringArray] = []


func _physics_process(delta: float) -> void:
	_clash_pairs_this_tick.clear()


func report_clash(me: Horse, them: Horse):
	if _has_clash_already_occurred(me, them):
		return

	BetEventBus.horse_collision.emit(me, them)
	_clash_pairs_this_tick.push_back([me.horse_data.name_abrev, them.horse_data.name_abrev])


func _has_clash_already_occurred(horse_a: Horse, horse_b: Horse) -> bool:
	var horse_a_name = horse_a.horse_data.name_abrev
	var horse_b_name = horse_b.horse_data.name_abrev
	for clash_pair: PackedStringArray in _clash_pairs_this_tick:
		if (
			(horse_a_name == clash_pair[0] and horse_b_name == clash_pair[1])
			or (horse_a_name == clash_pair[1] and horse_a_name == clash_pair[0])
		):
			return true
	return false
