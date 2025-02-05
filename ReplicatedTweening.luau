--// Author: 8ch99
--// Client replicated implementation of TweenService

--!native
--!optimize 2

--// Dependencies

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local Event = script:WaitForChild("RemoteEvent")

local BitBuffer = require(script.Parent:WaitForChild("BitBuffer"))
local Signal = require(script.Parent:WaitForChild("Signal"))

local function AreTweenInfosEquivalent(TI0: TweenInfo, TI1: TweenInfo)
	return TI0.Time == TI1.Time
		and TI0.EasingStyle == TI1.EasingStyle
		and TI0.EasingDirection == TI1.EasingDirection
		and TI0.RepeatCount == TI1.RepeatCount
		and TI0.Reverses == TI1.Reverses
		and TI0.DelayTime == TI1.DelayTime
end

local function ArePropertiesEquivalent(P0: { [string]: any }, P1: { [string]: any })
	for Property, Value in P0 do
		if not rawequal(P1[Property], Value) then
			local IsTable = type(Value) == "table"
			if not IsTable then
				return false
			end
			if not ArePropertiesEquivalent(P1[Property], Value) then
				return false
			end
		end
	end
	return true
end

--// @module ReplicatedTweening

local ReplicatedTweening = {}
ReplicatedTweening.Event = Event
ReplicatedTweening.Cache = {}

function ReplicatedTweening:SerializeTweenInfo(TweenInfo: TweenInfo)
	local Buffer = BitBuffer.new(27)
	Buffer:WriteTweenInfo(TweenInfo, true)
	return Buffer:GetBuffer()
end

function ReplicatedTweening:DeserializeTweenInfo(Buffer: buffer)
	return BitBuffer.fromBuffer(Buffer):ReadTweenInfo(0)
end

function ReplicatedTweening:SerializeProperties(Properties: { [string]: any })
	local Data = {}
	for Property, Value in Properties do
		table.insert(Data, Property)
		table.insert(Data, Value)
	end
	return BitBuffer.fromDataSet(Data, 1024):GetBuffer()
end

function ReplicatedTweening:DeserializeProperties(Buffer: buffer)
	local Properties = {}
	local Data = BitBuffer.fromBuffer(Buffer):Deserialize(true)
	for Index = 1, #Data, 2 do
		Properties[Data[Index]] = Data[Index + 1]
	end
	return Properties
end

--// @class Tween

local Tween = {}
Tween.__index = Tween

function Tween.new(Instance: Object, TweenInfo: TweenInfo, Properties: { [string]: any })
	local self = setmetatable({}, Tween)

	self.Thread = nil
	self.ID = HttpService:GenerateGUID(false)
	self.Completed = Signal.new()

	self.Instance = Instance
	self.TweenInfo = TweenInfo
	self.Properties = Properties

	self.TweenInfoBuffer = ReplicatedTweening:SerializeTweenInfo(TweenInfo)
	self.PropertiesBuffer = ReplicatedTweening:SerializeProperties(Properties)

	return self 
end

function Tween:Play()
	local Instance = self.Instance
	local TweenInfo = self.TweenInfo

	if self.Thread then
		task.cancel(self.Thread)
	end

	Event:FireAllClients("Play", self.ID, Instance, self.TweenInfoBuffer, self.PropertiesBuffer)

	self.Thread = task.delay((TweenInfo.Time + TweenInfo.DelayTime) * (TweenInfo.RepeatCount + 1), function()
		local Instance = self.Instance

		for Property, Value in self.Properties do
			Instance[Property] = Value
		end

		self.Completed:Fire()
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

--// continue ReplicatedTweening

function ReplicatedTweening:Create(Instance, TweenInfo: TweenInfo, Properties: { [string]: any })
	--// look for any identical tweens
	for _, Tween in self.Cache do
		if Tween.Instance == Instance and AreTweenInfosEquivalent(Tween.TweenInfo, TweenInfo) and ArePropertiesEquivalent(Tween.Properties, Properties) then
			return Tween
		end
	end
	--// no duplicate found? create a new one
	local NewTween = Tween.new(Instance, TweenInfo, Properties)
	self.Cache[NewTween.ID] = NewTween
	return NewTween
end

function ReplicatedTweening:Get(ID: string)
	return self.Cache[ID]
end

return ReplicatedTweening
