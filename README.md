# Roblox Samples

## Touhou bullet hell (client project)

Systems I built for a client's touhou-style bullet hell on Roblox. The engine (bullets, lasers, player, rendering) is the client's and isn't included here. This code was written with AI assistance (Claude), and the client has edited parts of it since.

The game runs in lockstep: the server steps one simulation frame for every client input, so both sides run the same code frame by frame. Because of that, everything here counts time in sim frames instead of seconds.

| File | What it does |
| --- | --- |
| [EffectManager](touhou-sim/ReplicatedStorage/EffectManager/init.luau) | Visual effects split in two: `onSimulate` runs every sim frame, `draw` paints onto the EditableImage canvas during render (drawing isn't allowed inside the sim step). Each effect kind is a child module. |
| [SpawnCircle](touhou-sim/ReplicatedStorage/EffectManager/SpawnCircle.luau) | Shrinking ring that telegraphs where something is about to spawn. |
| [Stage](touhou-sim/ReplicatedStorage/Stage.luau) | Coroutine sequencer for the stage timeline. `wait`, `waitUntil` and `pattern` resume on sim frames, so the timeline stays identical on client and server. |
| [Midboss2](touhou-sim/ReplicatedStorage/Registry/Patterns/Midboss2.luau) | Rows of bullets that flow along fixed sine paths from both sides, mirrored. A spear flies at the player and turns into a laser at the wall that sheds a helix of bullets. |
| [Midboss3](touhou-sim/ReplicatedStorage/Registry/Patterns/Midboss3.luau) | Rings of spears around the player that telegraph, thrust in together and drain into the point. |

Both Midboss files start from the client's pattern template.

Roblox: meanliest
