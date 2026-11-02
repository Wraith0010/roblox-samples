const Constants = require("./Constants")
const Frame = require("./Frame")

export type Self = {
	kind: string,
	location: vector,
	frame: number,
	age: number,
	duration: number,
	params: {[string]: any},
	[string]: any
}

export type Info = {
	duration: number,
	create: ((effect: Self) -> ())?,
	onSimulate: ((effect: Self) -> ())?,
	draw: ((effect: Self, canvas: EditableImage) -> ())?
}

const EffectManager = {}
EffectManager.effects = {}:: {Self}
EffectManager.kinds = {}:: {[string]: Info}

for _, module in script:GetChildren() do
	if module:IsA("ModuleScript") then
		EffectManager.kinds[module.Name] = require(module)
	end
end

function EffectManager.create(kind: string, location: vector, params: {[string]: any}?): Self?
	if not Constants.isClient then
		return nil
	end
	
	const info = EffectManager.kinds[kind]
	assert(info, "unknown effect")
	
	const effectParams = params or {}
	const effect: Self = {
		kind = kind,
		location = location,
		frame = Frame.get(),
		age = 0,
		duration = effectParams.duration or info.duration,
		params = effectParams
	}
	
	if info.create then
		info.create(effect)
	end
	
	table.insert(EffectManager.effects, effect)
	return effect
end

function EffectManager.simulate()
	const effects = EffectManager.effects
	for index = #effects, 1, -1 do
		const effect = effects[index]
		const info = EffectManager.kinds[effect.kind]
		
		if info.onSimulate then
			info.onSimulate(effect)
		end
		
		effect.age += 1
		if effect.age > effect.duration then
			table.remove(effects, index)
		end
	end
end

function EffectManager.draw(canvas: EditableImage)
	for _, effect in EffectManager.effects do
		const info = EffectManager.kinds[effect.kind]
		if info.draw then
			info.draw(effect, canvas)
		end
	end
end

return EffectManager