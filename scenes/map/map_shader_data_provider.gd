class_name MapShaderDataProvider

#var OnChunkInactive = delegate
#
#func notifyVisibleSegmentsChanged(segmentArea: Rect2i) -> void:
#	onVisibleSegmentsChanged(segmentArea)
#
#func setInactive(segment: Vector2, chunk: MapShaderChunk) -> void:
#	onChunkInactive(segment, chunk);

func GetTile(x: int, y: int) -> int:
	# Very simple noise gen
	var noise: float = GameManager.Instance.MapNoise.noise.get_noise_2d(x, y)
	if noise < 0.01:
		return 0
	elif noise < 0.2:
		return 1
	elif noise < 0.4:
		return 2
	else:
		return 3
