const ReplicatedStorage = game:GetService("ReplicatedStorage")

const PlayerManager = require("../../PlayerManager")
const BulletManager = require("../../BulletManager")
const EnemyManager = require("../../EnemyManager")
const LaserManager = require("../../LaserManager")
const Constants = require("../../Constants")
const Typedefs = require("../../Typedefs")
const Frames = require("../../Frame")
const Utilities = require("@game/ReplicatedStorage/Modules/Utilities")

const EffectManager = require("../../EffectManager")

const SoundController = require("@game/ReplicatedStorage/Client/SoundController")
const sounds = ReplicatedStorage.Resources.Sounds

const kBulletSpeed = 600

const kBulletCaster = Constants.bulletCaster
const kArenaSizeX = Constants.arenaSizeX
const kArenaSizeY = Constants.arenaSizeY

const kLaserColor = Color3.new(0, 0.764706, 1)
const kLaserWidth = 20
const kLaserLength = 150
const kBulletSpeed = 450

const kTimeLimit = 60 * 70

const kBulletAmplitude = 35
const kBulletFrequency = math.pi * 2 / 320

const kWaveSpeed = 95
const kWaveSpacing = 80
const kWaveRows = kArenaSizeY // kWaveSpacing

const kHelixRadius = 45
const kHelixPitch = 100
const kHelixSpeed = 120

export type Params = {
	boss: EnemyManager.Self,
	started: boolean,
	interval: number,
	spearCounter: number,
}

const function helix()
	const bullets = {}
	local released = false
	
	return function(laser: LaserManager.Laser)
		if laser.frame == 0 then
			for spreadAngle = laser.angle - math.pi / 2, laser.angle + math.pi / 2, math.pi / 16 do
				BulletManager.create(kBulletCaster.enemy, laser.origin, vector.create(math.cos(spreadAngle), math.sin(spreadAngle)) * 120, nil, nil, "Sphere/Blue")
			end
			
			for i = -1, 1 do
				LaserManager.curve(kBulletCaster.enemy, laser.origin, laser.angle, 1000, laser.duration * 2, 25, {
					duration = laser.duration,
					color = laser.color,
					frameUpdate = function(curveLaser)
						curveLaser.angle = laser.angle + math.cos(laser.frame * math.pi / 10) * i --math.cos(math.pi/2 * curveLaser.frame / laser.duration)
					end,
				})
			end
			
		end
		
		if laser.frame < laser.delay then
			return
		end

		const s = laser.length
		const dir = vector.create(math.cos(laser.angle), math.sin(laser.angle))
		const side = vector.create(math.cos(laser.angle + math.pi / 2), math.sin(laser.angle + math.pi / 2))
		
		for strand = 0, 1 do
			const phase = s / kHelixPitch * math.tau + strand * math.pi
			const offset = math.sin(phase)
			const position = laser.origin + dir * s + side * (kHelixRadius * offset)
			
			if position.x < 0 or position.x > kArenaSizeX or position.y < 0 or position.y > kArenaSizeY then
				continue
			end
			
			const vel = side * (if offset < 0 then -1 else 1)
			const bullet = BulletManager.create(kBulletCaster.enemy, position, vel * 50, nil, nil, "Drop/LightBlue", 15)
			table.insert(bullets, {
				bullet = bullet,
				out = vel
			})
			
			EffectManager.create("SpawnCircle", bullet.location, {
				color = kLaserColor,
				duration = 15,
				startRadius = 15
			})
			
			if Constants.isClient then
				SoundController.playSound(sounds.se_kira00)
			end
		end
	end
end

const Test = {}
Test.duration = 50000
Test.interval = 1

function Test.run(state: Typedefs.PatternState<Params>)
	const frame = state.frame
	const enemy = state.params.boss
	
	if not state.params.started then
		if frame == 0 then
			SoundController.playSound(sounds.se_cat00, true, {Volume = 0.75})
			enemy:startPhase(1200, kTimeLimit)
			enemy:moveTo(vector.create(kArenaSizeX / 2, kArenaSizeY * 0.15))
			
			enemy.killCallback = function()
				enemy:endPhase()
				state.finished = true
			end
		elseif frame == 60 then
			SoundController.playSound(sounds.se_ch01, false, {Volume = 0.5})
		elseif frame == 120 then
			SoundController.playSound(sounds.se_enep02, false, {Volume = 0.5})

			state.params.started = true
			state.params.interval = 55
			state.frame = 0
			state.params.spearCounter = 300
		end
	end
	
	if state.params.started then
		const frame = state.frame
		if frame % state.params.interval == 0 then
			
			for row = 0, kWaveRows - 1 do
				const base = (row + 0.5) * kWaveSpacing
				
				const left = BulletManager.create(kBulletCaster.enemy, vector.create(-6, base - kBulletAmplitude), vector.create(kWaveSpeed, 0), nil, nil, "NeonSphere/Blue")
				left.frameUpdate = function(bullet)
					const x = bullet.location.x
					bullet.location = vector.create(x, base - kBulletAmplitude * math.cos(x * kBulletFrequency))
				end
				
				const right = BulletManager.create(kBulletCaster.enemy, vector.create(kArenaSizeX + 6, base - kBulletAmplitude), vector.create(-kWaveSpeed, 0), nil, nil, "NeonSphere/Blue")
				right.frameUpdate = function(bullet)
					const x = bullet.location.x
					bullet.location = vector.create(x, base - kBulletAmplitude * math.cos((kArenaSizeX - x) * kBulletFrequency))
				end
			end
		end
		
		if frame > 0 then
			if state.params.spearCounter == 60 then
				SoundController.playSound(sounds.se_ch01)
			elseif state.params.spearCounter == 0 then
				const playerDir = Utilities.getDirection(enemy.location, PlayerManager.location)
				const vel = vector.normalize(playerDir) * 600
				
				const bullet = BulletManager.create(kBulletCaster.enemy, enemy.location, vel, nil, nil, "Arrowhead/Turquoise")
				bullet.persistent = true
				const laser = LaserManager.curve(kBulletCaster.enemy, enemy.location, math.atan2(vel.y, vel.x), 600, 120, 12, {
					color = kLaserColor
				})
				
				bullet.frameUpdate = function()
					const x = bullet.location.x
					const y = bullet.location.y
					
					const outOfBounds = x < 0 or x > kArenaSizeX or y < 0 or y > kArenaSizeY
					
					if outOfBounds then
						BulletManager.destroy(table.find(BulletManager.bullets, bullet), true)
						if x < 0 or x > kArenaSizeX then
							LaserManager.straight(kBulletCaster.enemy, bullet.location, math.rad(x < 0 and 0 or 180), 3000, 60, {
								delay = 10,
								duration = 60 * 2,
								extendSpeed = 1200,
								color = kLaserColor,
								frameUpdate = helix(),
							})
						elseif y < 0 or y > kArenaSizeY then
							LaserManager.straight(kBulletCaster.enemy, bullet.location, math.rad(y < 0 and 90 or 270), 3000, 60, {
								delay = 10,
								duration = 60 * 2,
								extendSpeed = 1200,
								color = kLaserColor,
								frameUpdate = helix(),
							})
						end
						SoundController.playSound(sounds.se_lazer00)
					end
				end
				state.params.spearCounter = 360
			end
		end
		state.params.spearCounter -= 1
	end
	
end

return Test