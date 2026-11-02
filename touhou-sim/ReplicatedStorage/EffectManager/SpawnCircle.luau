const kSegments = 48
const kTau = math.pi * 2
const kBlend = Enum.ImageCombineType.BlendSourceOver
const kDefaultColor = Color3.new(1, 0.321569, 0.333333)

const SpawnCircle = {}
SpawnCircle.duration = 60

function SpawnCircle.create(effect)
	const params = effect.params
	effect.startRadius = params.radius or 100
	effect.duration = params.duration or SpawnCircle.duration
	effect.radius = effect.startRadius
	effect.color = params.color or kDefaultColor
	effect.thickness = params.thickness or 3
	effect.transparency = 1
	effect.rotation = 0
end

function SpawnCircle.onSimulate(effect)
	const progress = math.min(effect.age / effect.duration, 1)
	effect.radius = effect.startRadius * (1 - progress)
	effect.transparency = 1 - math.min(progress * 3, 1) * 0.8
	effect.rotation = progress * math.pi
end

function SpawnCircle.draw(effect, canvas: EditableImage)
	const radius = effect.radius
	if radius < 1 then
		return
	end
	
	const location = effect.location
	const center = Vector2.new(location.x, location.y)
	const color = effect.color
	const transparency = effect.transparency
	const rotation = effect.rotation
	
	canvas:DrawCircle(center, radius, color, 1 - (1 - transparency) * 0.25, kBlend)
	
	for layer = 0, effect.thickness - 1 do
		const ringRadius = radius - layer
		if ringRadius <= 0 then
			break
		end
		
		local previous = center + Vector2.new(math.cos(rotation), math.sin(rotation)) * ringRadius
		for index = 1, kSegments do
			pcall(function()
				const angle = rotation + index / kSegments * kTau
				const point = center + Vector2.new(math.cos(angle), math.sin(angle)) * ringRadius
				canvas:DrawLine(previous, point, color, transparency, kBlend)
				previous = point
			end)
		end
	end
end

return SpawnCircle