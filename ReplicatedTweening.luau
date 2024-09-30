--// Author: 8ch99
--// Client replicated implementation of TweenService

local HttpService = game:GetService("HttpService")

local Event = script:WaitForChild("RemoteEvent")
local MockSignal = require(script.Parent:WaitForChild("MockSignal"))

local function FuzzyEqual(Table0, Table1)
	for Index, Value in Table0 do
		if type(Value) == "table" then
			if not FuzzyEqual(Table1[Index], Value) then return false end
		end
		if Table1[Index] ~= Value then return false end
	end
	return true
end

--// @class Tween

local Tween = {}
Tween.__index = Tween

function Tween.new(Instance, TweenInfo, Properties)
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
	return { TweenInfo.Time, TweenInfo.EasingStyle, TweenInfo.EasingDirection, TweenInfo.RepeatCount, TweenInfo.Reverses, TweenInfo.DelayTime }
end

function ReplicatedTweening:ArrayToTweenInfo(Array)
	return TweenInfo.new(table.unpack(Array))
end

function ReplicatedTweening:Create(Instance, TweenInfo, Properties)
	TweenInfo = self:TweenInfoToArray(TweenInfo)
	--// look for any identical tweens (prevents memory leaks)
	for _, Tween in self.TweenCache do
		if Tween.Instance == Instance then
			if FuzzyEqual(Tween.Properties, Properties) then
				if FuzzyEqual(Tween.TweenInfo, TweenInfo) then
					return Tween
				end
			end
		end
	end
	--// no duplicate found? create it
	local NewTween = Tween.new(Instance, TweenInfo, Properties)
	self.TweenCache[NewTween.ID] = NewTween
	return NewTween
end

return ReplicatedTweening
