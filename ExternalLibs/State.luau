local State = {}
State._Server = game:GetService("RunService"):IsServer()
State._Players = game:GetService("Players")
State.__index = State

local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

function State:_IsState()
	return self._listeners ~= nil and typeof(self.listeners) == "table" and self.changed
end

function State:NewState(currentValue)
	return State.new(currentValue)
end

function State.new(currentValue)
	local self = setmetatable({}, State)
	self._listeners = {}
	self._value = currentValue
	return self
end

function State:_Update()
	for _, callback in ipairs(self._listeners) do
		if typeof(callback) == "function" then
			callback(self._value)
		end
	end
end

function State:changed(callback: (...any) -> ())
	table.insert(self._listeners, callback)
end
State.Changed = State.changed
State.onChanged = State.changed

function State:set(value: any)
	self._value = value
	self:_Update()
end
State.Set = State.set

function State:get()
	return self._value
end
State.Get = State.get

function State:Destroy()
	for idx, callback in pairs(self._listeners) do
		table.remove(self._listeners, table.find(self._listeners, callback))
	end
	
	self._listeners = {}
	self._value = nil
end

function State:Disconnect()
	return self:Destroy()
end

return State
