const PatternManager = require("./PatternManager")
const BulletManager = require("./BulletManager")
const EnemyManager = require("./EnemyManager")
const LaserManager = require("./LaserManager")
const Constants = require("./Constants")
const Typedefs = require("./Typedefs")

const kFps = Constants.fps

type Sequence = {
	thread: thread,
	frames: number,
	condition: (() -> boolean)?
}

const Stage = {}
Stage.sequences = {}:: {Sequence}

function Stage.run(callback: () -> ())
	table.insert(Stage.sequences, {
		thread = coroutine.create(callback),
		frames = 0
	})
end

function Stage.wait(seconds: number)
	coroutine.yield(math.max(math.round(seconds * kFps), 1))
end

function Stage.waitUntil(condition: () -> boolean)
	coroutine.yield(0, condition)
end

function Stage.pattern(name: string, params: {[string]: any}?): Typedefs.PatternState
	const state = PatternManager.create(name, params)
	
	Stage.waitUntil(function()
		return state.finished
	end)
	
	return state
end

function Stage.clear()
	for _, state in PatternManager.patterns do
		state.finished = true
	end
	
	BulletManager.clear(nil, true)
	LaserManager.clear()
	
	const enemies = EnemyManager.enemies
	for index = #enemies, 1, -1 do
		const enemy = enemies[index]
		if enemy and not enemy.boss then
			enemy:kill()
		end
	end
end

function Stage.simulate()
	const sequences = Stage.sequences
	for index = #sequences, 1, -1 do
		const sequence = sequences[index]
		
		if sequence.condition then
			if not sequence.condition() then
				continue
			end
		elseif sequence.frames > 1 then
			sequence.frames -= 1
			continue
		end
		
		const success, frames, condition = coroutine.resume(sequence.thread)
		if not success then
			warn(debug.traceback(sequence.thread, tostring(frames)))
		end
		
		if coroutine.status(sequence.thread) == "dead" then
			table.remove(sequences, index)
			continue
		end
		
		sequence.frames = frames
		sequence.condition = condition
	end
end

return Stage