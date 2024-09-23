--// Author: 8ch99
--// Client replicated implementation of TweenService

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ReplicatedTweening = require(ReplicatedStorage:WaitForChild("ReplicatedTweening"))

--// @module TweeningClient

local TweeningClient = {}
TweeningClient.Tweens = {}
TweeningClient.RunningTweens = {}

function TweeningClient:LoadTween(ID, Instance, TweenInfo, Properties)
	local Tween = TweenService:Create(Instance, TweenInfo, Properties)
	self.Tweens[ID] = Tween
	return Tween
end

function TweeningClient:RunTween(ID)
	if self.RunningTweens[ID] then
		task.cancel(self.RunningTweens[ID])
	end
	local Tween = self.Tweens[ID]
	if not Tween then return end
	Tween:Play()
	local Info = Tween.TweenInfo
	self.RunningTweens[ID] = task.delay((Info.Time + Info.DelayTime) * (Info.RepeatCount + 1), function()
		self.RunningTweens[ID] = nil
	end)
end

function TweeningClient:StopTween(ID)
	if not self.RunningTweens[ID] then return end
	task.cancel(self.RunningTweens[ID])
	self.RunningTweens[ID] = nil
end

--// remote handling

local Actions = {
	Play = function(ID, Instance, TweenInfo, Properties)
		if not TweeningClient.Tweens[ID] then
			TweenInfo = ReplicatedTweening:ArrayToTweenInfo(TweenInfo)
			TweeningClient:LoadTween(ID, Instance, TweenInfo, Properties)
		end
		TweeningClient:RunTween(ID)
	end,
	Cancel = function(ID)
		if not TweeningClient.Tweens[ID] then return end
		TweeningClient:StopTween(ID)
	end,
}

ReplicatedTweening.Event.OnClientEvent:Connect(function(Action, ...)
	Action = Actions[Action]
	if Action then return Action(...) end
end)
