# ReplicatedTweening
A roblox luau system that allows for replicated creation and playback of tweens from server-sided contexts.
### SETUP:
Download Package.rbxm and open it in studio
Parent each item to where it belongs
Example Usage:
```lua
local TweenService = require(game.ReplicatedStorage.ReplicatedTweening)

local Tween = TweenService:Create(workspace.ExampleTweenPart, TweenInfo.new(0.5, Enum.EasingStyle.Sine), { Transparency = 0 })
Tween:Play()```
