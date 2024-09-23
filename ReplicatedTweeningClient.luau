--// Author: 8ch99
--// Client replicated implementation of TweenService

local HttpService = game:GetService("HttpService")

local Event = script:WaitForChild("RemoteEvent")
local MockSignal = require(script.Parent:WaitForChild("MockSignal"))

local function FuzzyEqual(Table0, Table1)
	for Index, Value in Table0 do
		if type(Value) == "table" then return FuzzyEqual(Table1[Index], Value) end
		if Table1[Index] ~= Value then return false end
	end
	return true
end

--// @class Tween

local Tween = {}
Tween.__index = Tween

function Tween.new(Instance, TweenInfo, Properties)
	--// look for an identical tween (no memory leaks on my watch)
	local self = setmetatable({}, Tween)
	self.Thread = nil
	self.Instance = Instance
	self.TweenInfo = TweenInfo
	self.Properties = Properties
	self.Completed = MockSignal.new("Tween.Completed")	
	self.ID = HttpService:GenerateGUID(false)
	return self 
end

function Tween:Play()
	Event:FireAllClients("Play", self.ID, self.Instance, self.TweenInfo, self.Properties)
	if self.Thread then
		task.cancel(self.Thread)
	end
	local TweenInfo = self.TweenInfo
	self.StartTime = os.clock()
	self.Thread = task.delay((TweenInfo[1] + TweenInfo[6]) * (TweenInfo[4] + 1), function()
		self.Completed:Fire(os.clock())
		local Instance = self.Instance
		for Property, Value in self.Properties do
			Instance[Property] = Value
		end
		self.Thread = nil
	end)
end

function Tween:Cancel()
	if self.Thread then
		task.cancel(self.Thread)
		Event:FireAllClients("Cancel", self.ID)
	end
	self.Thread = nil
end

function Tween:Destroy()
	self:Cancel()
	self.Completed:Destroy()
	table.clear(self)
	setmetatable(self, nil)
end

--// @module ReplicatedTweening

local ReplicatedTweening = {}
ReplicatedTweening.Event = Event
ReplicatedTweening.TweenCache = {}

function ReplicatedTweening:TweenInfoToArray(TweenInfo)
	--// the extra indexes are for the custom tween infos
	return {
		if TweenInfo.Time then TweenInfo.Time elseif TweenInfo.Duration then TweenInfo.Duration else Enum.EasingStyle.Quad,
		if TweenInfo.EasingStyle then TweenInfo.EasingStyle else Enum.EasingStyle.Quad,
		if TweenInfo.EasingDirection then TweenInfo.EasingDirection else Enum.EasingDirection.Out,
		if TweenInfo.RepeatCount then TweenInfo.RepeatCount else 0,
		if TweenInfo.Reverses ~= nil then TweenInfo.Reverses elseif TweenInfo.Reverse then TweenInfo.Reverse else false,
		if TweenInfo.DelayTime then TweenInfo.DelayTime elseif TweenInfo.DelayDuration then TweenInfo.DelayDuration else 0,
	}
end

function ReplicatedTweening:ArrayToTweenInfo(Array)
	return TweenInfo.new(
		Array[1] or 1,
		Array[2] or Enum.EasingStyle.Quad,
		Array[3] or Enum.EasingDirection.Out,
		Array[4] or 0,
		Array[5] or false,
		Array[6] or 0
	)
end

function ReplicatedTweening:Create(Instance, TweenInfo, Properties)
	TweenInfo = self:TweenInfoToArray(TweenInfo)
	--// look for any identical tweens (so someone doesnt accidently create a memory leak)
	for _, Tween in self.TweenCache do
		if Tween.Instance ~= Instance then continue end
		if FuzzyEqual(Tween.Properties, Properties) then
			if FuzzyEqual(Tween.TweenInfo, TweenInfo) then
				return Tween
			end
		end
	end
	--// no duplicate found? create it
	local NewTween = Tween.new(Instance, TweenInfo, Properties)
	self.TweenCache[NewTween.ID] = NewTween
	return NewTween
end

return ReplicatedTweening
