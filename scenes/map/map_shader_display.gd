extends Node2D
class_name MapShaderDisplay

	# For debugging only, if you got more than one display this will not work
var Instance: MapShaderDisplay

const SCENE_SHADER_CHUNK = "res://scenes/map/map_shader_display.tscn"

# The size of each chunk, they are square by default
# Should be a power of 2
const WORLD_SEGMENT_SIZE: int = 128

# How many extra chunks to load
const SEGMENTS_OUTSIDE_VIEW_TO_LOAD: int = 2

# How often should we update
const UPDATE_INTERVAL: float = 0.3

# Used for the queue, set higher than update interval to trigger immediate update
var _updateCounter: float = UPDATE_INTERVAL + 1

# Active map segments
var ActiveMapSegments: Dictionary = {} # Dictionary<Vector2, MapShaderChunk>

var InactiveChunks: Array[MapShaderChunk] = []

var DataProvider: MapShaderDataProvider

var SegmentCounter: int = 0

var InactiveParent: Node2D

var LastSegmentArea: Rect2

# Called when the node enters the scene tree for the first time.
func _ready():
	Instance = self
	DataProvider = MapShaderDataProvider.new()
	DataProvider.onChunkInactive += onChunkInactive

	InactiveParent = Node2D.new()
	InactiveParent.name = "InactiveSegments"
	add_child(InactiveParent)

func _physics_process(delta) -> void:
	# Add anything that needs to be rendered to queue
	_updateCounter += float(delta)
	if _updateCounter > UPDATE_INTERVAL:
		_updateCounter = 0
		updateShaderMap();

# Check if we need to update the map
func updateShaderMap() -> void:
	# Get segments to process
	var segmentArea: Rect2i = getSegmentArea()

	# Go through from top left to bottom right
	for x in range(int(segmentArea.position.x), int(segmentArea.size.x)):
		for y in range(int(segmentArea.position.y), int(segmentArea.size.y)): 
			draw_segment(Vector2(x, y))

	# Tell all existing segments that we changed area
	if LastSegmentArea != segmentArea:
		LastSegmentArea = segmentArea
		DataProvider.notifyVisibleSegmentsChanged(segmentArea)
