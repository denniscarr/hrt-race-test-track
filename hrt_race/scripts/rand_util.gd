## Static util functions to help with randomization
class_name RandUtil
extends Object


## Returns a shuffled duplicate of [array]
static func shuffle_with_rng(array: Array, rng: RandomNumberGenerator) -> Array:
	var a = array.duplicate()
	for i in range(array.size() - 1, 0, -1):
		var j = rng.randi_range(0, i)
		var temp = a[i]
		a[i] = a[j]
		a[j] = temp

	return a


## Returns a random element from [array]
static func pick_random_with_rng(array: Array, rng: RandomNumberGenerator):
	var i := rng.randi_range(0, array.size() - 1)
	return array[i]
