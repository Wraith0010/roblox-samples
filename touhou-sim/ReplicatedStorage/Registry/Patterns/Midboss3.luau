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

const kSpearSprite = "Arrowhead/Turquoise"
const kSpearLength = 64
const kSpearWidth = 8
const kSpearCount = 8

const kRingRadius = 190
const kMinRadius = 90
const kEdgeMargin = 12

const kTelegraph = 30
const kThrust = 36
const kDrain = 8

const kStartInterval = 48
const kMinInterval = 35

export type Params = {
	boss: EnemyManager.Self,
	started: boolean,
	interval: number,
	cooldown: number,
}

const function reach(target: vector, direction: vector): number
	local distance = kRingRadius
	
	if direction.x > 0 then
		distance = math.min(distance, (target.x - kEdgeMargin) / direction.x)
	elseif direction.x < 0 then
		distance = math.min(distance, (kArenaSizeX - kEdgeMargin - target.x) / -direction.x)
	end
	
	if direction.y > 0 then
		distance = math.min(distance, (target.y - kEdgeMargin) / direction.y)
	elseif direction.y < 0 then
		distance = math.min(distance, (kArenaSizeY - kEdgeMargin - target.y) / -direction.y)
	end
	
	return distance
end

const function spear(target: vector, angle: number, radius: number, loud: boolean)
	const direction = vector.create(math.cos(angle), math.sin(angle))
	const start = target - direction * radius
	
	const bullet = BulletManager.create(kBulletCaster.enemy, start, direction, nil, nil, kSpearSprite, kTelegraph)
	bullet.transparency = 1
	
	EffectManager.create("SpawnCircle", start, {
		color = kLaserColor,
		duration = kTelegraph,
		radius = 20,
		thickness = 1
	})
	
	LaserManager.straight(kBulletCaster.enemy, start, angle + math.pi, kSpearLength, kSpearWidth, {
		color = kLaserColor,
		delay = kTelegraph,
		frameUpdate = function(laser)
			const frame = laser.frame - kTelegraph
			if frame < 0 or laser.ending then
				return
			end
			
			if frame == 0 and loud then
				SoundController.playSound(sounds.se_tan01, false, {Volume = 0.35})
			end
			
			if frame < kThrust then
				const progress = (frame + 1) / kThrust
				laser.origin = target - direction * (radius * (1 - progress * progress))
				bullet.transparency = math.max(1 - (frame + 1) / LaserManager.fadeFrames, 0)
			else
				laser.origin = target
				laser.length = kSpearLength * math.max(1 - (frame - kThrust + 1) / kDrain, 0)
				laser.maxLength = laser.length
				bullet.transparency = 1 - laser.length / kSpearLength
				
				if laser.length <= 0 then
					BulletManager.destroy(table.find(BulletManager.bullets, bullet), true)
					LaserManager.remove(laser)
					
					if loud then
						EffectManager.create("SpawnCircle", target, {
							color = kLaserColor,
							duration = 15,
							radius = 50,
							thickness = 5
						})
						for angle = 0, math.tau, math.pi / 4 do
							const bullet, bulletIndex = BulletManager.create(kBulletCaster.enemy, target, vector.create(math.cos(angle), math.sin(angle)) * 180, 70, nil, "Pellet/DarkBlue", 15)
							bullet.maxDeceleration = 0
							bullet.maxAcceleration = 0
							
							bullet.frameUpdate = function()
								if vector.magnitude(bullet.velocity) <= 0.2 then
									EffectManager.create("SpawnBulletTemp", bullet.location, {
										color = Color3.new(1, 1, 1),
										duration = 10,
										startRadius = 8,
										maxRadius = 25,
										thickness = 8
									})

									BulletManager.destroy(table.find(BulletManager.bullets, bullet))
								end
							end
						end
					end
				end
			end
			
			bullet.location = laser.origin
		end,
	})
end

const function ring(state: Typedefs.PatternState<Params>)
	const target = PlayerManager.location
	const offset = state.rng:NextNumber() * math.pi * 2
	local loud = true
	
	for index = 0, kSpearCount - 1 do
		const angle = offset + index / kSpearCount * math.pi * 2
		const radius = reach(target, vector.create(math.cos(angle), math.sin(angle)))
		
		if radius >= kMinRadius then
			spear(target, angle, radius, loud)
			loud = false
		end
	end
	
	SoundController.playSound(sounds.se_kira00, false, {Volume = 0.35})
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
			state.params.interval = kStartInterval
			state.params.cooldown = 0
			state.frame = 0
		end
	end
	
	if state.params.started then
		if state.params.cooldown <= 0 then
			SoundController.playSound(sounds.se_boon00, false)
			ring(state)
			state.params.interval = math.max(state.params.interval - 1, kMinInterval)
			state.params.cooldown = state.params.interval
		end
		
		state.params.cooldown -= 1
	end
end

return Test