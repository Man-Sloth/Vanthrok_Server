extends NavigationRegion2D

var bake: bool = false
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _physics_process(_delta):
	if bake:
		bake_navigation_polygon()
		bake = false
