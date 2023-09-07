extends Node2D
class_name MapShaderChunk

const SHADER_PARAM_TEXTURE_ATLAS = "textureAtlas"
const SHADER_PARAM_BLEND_TEXTURE = "blendTexture"
const SHADER_PARAM_MAP_DATA = "mapData"
const SHADER_PARAM_MAP_TILES_COUNT_X = "mapTilesCountX"
const SHADER_PARAM_MAP_TILES_COUNT_Y = "mapTilesCountY"
const SHADER_PARAM_TILE_SIZE_PIXELS = "tileSizeInPixels"
const SHADER_PARAM_HALF_TILE_SIZE_PIXELS = "halfTileSizeInPixels"

var Segment: Vector2 = Vector2.INF
var DataProvider: MapShaderDataProvider
var MapRenderer: Sprite2D

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func setShaderParameter(name: String, value: Variant) -> void:
	var mat: ShaderMaterial = MapRenderer.material;
	mat.setShaderParameter(name, value);

func setActive(provider: MapShaderDataProvider, segment: Vector2) -> void:
	Segment = segment
	DataProvider = provider
	DataProvider.onVisibleSegmentsChanged += onVisibleSegmentsChanged
	call_deferred("performInitialRender")

func onVisibleSegmentsChanged(segmentArea: Rect2i) -> void:
	if Segment == Vector2.INF || MapRenderer == null:
		return

	# We do our own check since the Size of segmentArea is actually the bottom right corner not the size
	if segmentArea.position.x > Segment.x || segmentArea.size.x < Segment.x || segmentArea.position.y > Segment.y || segmentArea.size.y < Segment.y:
		# GD.Print($"SegmentArea: {segmentArea} does not contain segment: {Segment}");
		# Time to go inactive
		DataProvider.onVisibleSegmentsChanged -= onVisibleSegmentsChanged
		DataProvider.setInactive(Segment, self)
		DataProvider = null
		MapRenderer.visible = false

# Does the initial rendering of this segment
func performInitialRender() -> void:
	var area: Rect2i = getRectFromSegment(Segment)

	# Position ourselves, area has -1 / +1 on it's size
	global_position = Vector2((area.position.x + 1) * GameManager.TILE_SIZE, (area.position.y + 1) * GameManager.TILE_SIZE);

	# Vector2 topLeft = new Vector2(area.Position.X * GameWorldManager.TILE_SIZE, area.Position.Y * GameWorldManager.TILE_SIZE);
	# TODO: Calculate start offset

	generateMapTexture(area);

func generateMapTexture(area: Rect2i) -> void:
	# Setup dimensions
	var start = area.position
	var size = area.size - area.position
	var dataArray = PackedByteArray(size.x * size.y)
	# Draw image
	var index = 0;
	for y in range(size.y):
		for x in range(size.x):
			var cell = DataProvider.getTile(int(start.x) + x, int(start.y) + y)
			dataArray[index] = cell;
	var img = Image.create_from_data(int(size.x), int(size.Y), false, Image.FORMAT_R8, dataArray)
	var texture = ImageTexture.create_from_image(img);

	# Set to shader
	MapRenderer.material.setShaderParameter(SHADER_PARAM_MAP_DATA, texture);
	MapRenderer.visible = true;

func getRectFromSegment(segment: Vector2) -> Rect2i:
	# Render 1 extra cell in each direction so shading gets ok
	var topLeft = Vector2i(int(segment.x * MapShaderDisplay.WORLD_SEGMENT_SIZE) - 1, int(segment.y * MapShaderDisplay.WORLD_SEGMENT_SIZE) - 1)
	var bottomRight = Vector2i(int(segment.x * MapShaderDisplay.WORLD_SEGMENT_SIZE) + MapShaderDisplay.WORLD_SEGMENT_SIZE + 1, int(segment.y * MapShaderDisplay.WORLD_SEGMENT_SIZE) + MapShaderDisplay.WORLD_SEGMENT_SIZE + 1)
	return Rect2i(topLeft, bottomRight)
