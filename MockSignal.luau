--// Author: 8ch99

--!native
--!optimize 2

local Signal = {}
Signal.__index = Signal

local table_clear = table.clear
local task_spawn = task.spawn
local coroutine_running = coroutine.running
local coroutine_yield = coroutine.yield

function Signal.new(Name)
	return setmetatable({ Name = `{Name}`, TopConnection = nil }, Signal)
end

function Signal:Fire(...)
	local Current = self.TopConnection
	while Current do
		task_spawn(Current.Function, ...)
		Current = Current.Next
	end
end

function Signal:Connect(Function)
	local Connection = {}
	Connection.Function = Function
	--// set Next as previous top node and set top node to this connection
	Connection.Next = self.TopConnection
	self.TopConnection = Connection
	Connection.Function = Function
	
	function Connection.Disconnect()
		local Current = self.TopConnection
		if Current == Connection then
			self.TopConnection = Current.Next
		else
			while Current do
				local Next = Current.Next
				if Next and Next == Connection then
					Current.Next = Next.Next
					break
				end
				Current = Next
			end
		end
		table_clear(Connection)
	end
	
	return Connection
end

function Signal:Once(Function)
	local Connection = nil
	Connection = self:Connect(function(...)
		Connection:Disconnect()
		return Function(...)
	end)
end

function Signal:Wait()
	local CurrentThread = coroutine_running()
	local YieldConnection = self:Once(function(...) task_spawn(CurrentThread, ...) end)
	return coroutine_yield()
end

function Signal:DisconnectAll()
	self.TopConnection = nil
end

function Signal:Destroy()
	self.TopConnection = nil
	self.Name = nil
	setmetatable(self, nil)
end

return Signal
