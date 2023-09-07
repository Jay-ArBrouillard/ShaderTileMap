extends Node2D
class_name GameManager

var Instance: GameManager
const TEXTURE_SIZE: int = 1024
const TILE_SIZE: int = 64

# Texture passed to tilemap shader containing all ground textures
var MegaTexture: ImageTexture = null
# Texture used in tilemap shader for tile blending 
var TileBlendTexture: Texture2D = null
var MapNoise: NoiseTexture2D = null

# Called when the node enters the scene tree for the first time.
func _ready():
	Instance = self
	createMegaTexture()
	createTileBlendTexture()
	initMapNoise()
#	PlayerCamera.Init(this);

# Using a seamless noise map to let it go infinite
func initMapNoise(seed: int = 1337) -> void:
	var noise = NoiseTexture2D.new()
	noise.seamless = true
	noise.width = 128
	noise.height = 128
	var oNoise = FastNoiseLite.new()
	noise.noise = oNoise
	MapNoise = noise

func getGroundTextures() -> Array[Texture2D]:
	var textureList: Array[Texture2D] = []
	textureList.append(load("res://assets/textures/free_water.png") as Texture2D)
	textureList.append(load("res://assets/textures/free_grass.png") as Texture2D)
	textureList.append(load("res://assets/textures/free_sand.png") as Texture2D)
	textureList.append(load("res://assets/textures/free_rock.png") as Texture2D)

	return textureList;

func getNoiseGen(seed: int = 1337) -> NoiseTexture2D:
	var noise = NoiseTexture2D.new()
	noise.seamless = true
	noise.width = 1024
	noise.height = 1024
	var oNoise = FastNoiseLite.new()
	oNoise.seed = 4
#		oNoise.period = 56
#		//oNoise.persistence = 0
	oNoise.fractal_lacunarity = 0.1
	noise.noise = oNoise
	
	return noise;

func createTileBlendTexture(smoothEdge: float = 24, smoothCorner: float = 16,
							edgePercentage: float = 50, cornerPercentage: float = 25,
							textureSize: int = 16, debug: bool = true) -> void:
	if TileBlendTexture != null:
		return;

	# Noise (Same seed always to get same result always)
	var noiseX: NoiseTexture2D = getNoiseGen(1234)
	var noiseY: NoiseTexture2D = getNoiseGen(4321)
	var noiseC: NoiseTexture2D = getNoiseGen(1243)

	# TileBlendTexture
	var halfTile: int = TILE_SIZE / 2

	var blendImage: Image = Image.create(TILE_SIZE * textureSize, TILE_SIZE * textureSize, false, Image.FORMAT_RGBAF)

	var testImageR: Image = null;
	var testImageG: Image = null;
	var testImageB: Image = null;
	var testImageA: Image = null;

	if debug:
		testImageR = Image.create(TILE_SIZE * textureSize, TILE_SIZE * textureSize, false, Image.FORMAT_RGBAF)
		testImageG = Image.create(TILE_SIZE * textureSize, TILE_SIZE * textureSize, false, Image.FORMAT_RGBAF)
		testImageB = Image.create(TILE_SIZE * textureSize, TILE_SIZE * textureSize, false, Image.FORMAT_RGBAF)
		testImageA = Image.create(TILE_SIZE * textureSize, TILE_SIZE * textureSize, false, Image.FORMAT_RGBAF)

	# Loop through all pixels in the image and create colors
	# We make 10 rows and columns
	for row in range(textureSize):
		for column in range(textureSize):
			for x in range(TILE_SIZE):
				for y in range(TILE_SIZE):
					var imageXPos: int = x + (column * TILE_SIZE)
					var imageYPos: int = y + (row * TILE_SIZE)

					# Find closest edges
					var xEdge: float = 0 if x < halfTile else TILE_SIZE - 1
					var yEdge: float = 0 if y < halfTile else TILE_SIZE - 1

					# Get distance to closest edges
					var xDist: float = Vector2(x, 0).distance_to(Vector2(xEdge, 0))
					var yDist: float = Vector2(0, y).distance_to(Vector2(0, yEdge))
					var cornerDist: float = Vector2(x, y).distance_to(Vector2(xEdge, yEdge))

					# Calculate smoothing percentages to all edges (rounded)
					var xSmooth: float = round((1.0 - smoothstep(0, smoothEdge, min(xDist, smoothEdge))) * edgePercentage)
					var ySmooth: float = round((1.0 - smoothstep(0, smoothEdge, min(yDist, smoothEdge))) * edgePercentage)
					var cornerSmooth: float = round((1.0 - smoothstep(0, smoothCorner, min(cornerDist, smoothCorner))) * cornerPercentage)

					# Add noise based on distance from edge
					# Noise count more closer to the center
					var noiseValX: float = noiseX.noise.get_noise_2d(imageXPos, imageYPos) * ((xDist / smoothEdge))
					var noiseValY: float = noiseY.noise.get_noise_2d(imageXPos, imageYPos) * ((yDist / smoothEdge))
					var noiseValC: float = noiseC.noise.get_noise_2d(imageXPos, imageYPos) * ((cornerDist / smoothCorner))

					xSmooth = min(xSmooth * (1.0 - noiseValX), edgePercentage)
					ySmooth = min(ySmooth * (1.0 - noiseValY), edgePercentage)
					cornerSmooth = min(cornerSmooth * (1.0 - noiseValC), cornerPercentage)

					# Subtract corner input from both X / Y and clamp to 
					xSmooth = max(0, xSmooth - cornerSmooth);
					ySmooth = max(0, ySmooth - cornerSmooth)

					# Calculate remainder for main texture
					var selfPercentage: float = 100 - xSmooth - ySmooth - cornerSmooth

					# Now we got a percentage that will add up to 100%
					# xSmooth = effect of horizontal texture
					# ySmooth = effect of vertical texture
					# cornerSmooth = effect of corner texture
					# selfPercentage = effect of primary texture
					# Write to rgba
					var col: Color = Color(xSmooth / 255.0, ySmooth / 255.0, cornerSmooth / 255.0, selfPercentage / 255.0);
					blendImage.set_pixel(imageXPos, imageYPos, col);

					if debug:
						col = Color(xSmooth / 255.0, xSmooth / 255.0, xSmooth / 255.0, 1);
						testImageR.set_pixel(imageXPos, imageYPos, col);

						col = Color(ySmooth / 255.0, ySmooth / 255.0, ySmooth / 255.0, 1);
						testImageG.set_pixel(imageXPos, imageYPos, col);

						col = Color(cornerSmooth / 255.0, cornerSmooth / 255.0, cornerSmooth / 255.0, 1);
						testImageB.set_pixel(imageXPos, imageYPos, col)

						col = Color(selfPercentage / 255.0, selfPercentage / 255.0, selfPercentage / 255.0, 1)
						testImageA.set_pixel(imageXPos, imageYPos, col)

	# Create debug sprite
	TileBlendTexture = ImageTexture.create_from_image(blendImage); #, (uint)Texture2D.FlagsEnum.Repeat);

	if debug:
		blendImage.save_png("user://blendTest.png");
		testImageR.save_png("user://blendTestR.png");
		testImageG.save_png("user://blendTestG.png");
		testImageB.save_png("user://blendTestB.png");
		testImageA.save_png("user://blendTestA.png");

# Simple method to create a mega texture
func createMegaTexture() -> void:
	# Hardcoded for now
	# a full 16384 x 16384 texture takes 768 mb of vram (roughly 3 mb per 1024x1024 texture)

	# Get tiles
	var tileList: Array[Texture2D] = getGroundTextures()
	var count: float = tileList.size()

	# Calculate width / height of mega texture and create it
	var height: int = TEXTURE_SIZE * ceili(count / 16.0)
	var width: int = TEXTURE_SIZE * mini(count, 16.0)
	var megaImg: Image = Image.create(width, height, false, Image.FORMAT_RGBAF)
	var posX: int = 0
	var posY: int = 0

	# Copy image data to mega texture
	for n in range(count):
		var img: Image = tileList[n].get_image()
		var targetPos: Vector2i = Vector2i(posX * TEXTURE_SIZE, posY * TEXTURE_SIZE)
		megaImg.blend_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), targetPos)

		# Ensure we only get 16 per row
		posX += 1;
		if posX > 15:
			posX = 0
			posY += 1

	# Create debug sprite
	var MegaTexture = ImageTexture.create_from_image(megaImg) # //, (uint)Texture2D.FlagsEnum.Mipmaps);
