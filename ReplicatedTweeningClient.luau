--// Author: 8ch99
--// Client replicated implementation of TweenService

--!native
--!optimize 2

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BitBuffer = require(ReplicatedStorage:WaitForChild("BitBuffer"))
local ReplicatedTweening = require(ReplicatedStorage:WaitForChild("ReplicatedTweening"))

local Tweens = {}
local RunningTweens = {}

local Actions = {}

function Actions.Play(ID: string, Instance: Instance?, TweenInfo: buffer, Properties: buffer)
	local Tween = Tweens[ID]

	if Instance and not Tweens[ID] then
		warn(ReplicatedTweening:DeserializeTweenInfo(TweenInfo))
		Tween = TweenService:Create(Instance, ReplicatedTweening:DeserializeTweenInfo(TweenInfo), ReplicatedTweening:DeserializeProperties(Properties))
		Tweens[ID] = Tween
	end

	if Tween then
		if RunningTweens[ID] then
			task.cancel(RunningTweens[ID])
		end

		local Info = Tween.TweenInfo

		Tween:Play()

		RunningTweens[ID] = task.delay((Info.Time + Info.DelayTime) * (Info.RepeatCount + 1), function()
			RunningTweens[ID] = nil
		end)
	end
end

function Actions.Cancel(ID: string)
	local Thread = RunningTweens[ID]

	if Thread then
		task.cancel(Thread)
		RunningTweens[ID] = nil
	end

	Tweens[ID]:Cancel()
end

ReplicatedTweening.Event.OnClientEvent:Connect(function(Action, ...)
	Action = Actions[Action]
	if Action then
		return Action(...)
	end
end)
