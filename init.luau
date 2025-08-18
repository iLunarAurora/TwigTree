--[[
	TwigTree by @00ztrix on Discord (Github User: iLunarAurora)
		- Inspired by Roact but for higher readability for Luau newbs
	To review supported events, check the BindEvents module
	
	Example for creating a textbox, which if clicked increments gradually:
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local TwigTree = require(ReplicatedStorage.TwigTree)
	_G.TWIG_STRICT_MODE = true
	_G.TWIG_DEBUG_MODE = true

	local Players = game:GetService("Players")
	local LocalPlayer = Players.LocalPlayer

	local CountState = TwigTree:NewState(0)
	local MainGui = TwigTree.create("ScreenGui", {
		IgnoreGuiInset = true,
		ResetOnSpawn = false
	}, {
		TwigTree.create("TextButton", {
			Text = CountState,
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromScale(0.2, 0.2),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			TextColor3 = Color3.fromRGB(0, 0, 0),
			[TwigTree.Events.MouseButton1Click] = function()
				CountState:set(CountState:get() + 1)
			end
		})
	})

	MainGui:mount(LocalPlayer.PlayerGui)
--]]
--!optimize 2
--!native

local TwigTree = {}
TwigTree.__index = TwigTree
TwigTree.Events = require(script.BindEvents)
TwigTree.Spr = require(script.ExternalLibs.Spring)
TwigTree.State = require(script.ExternalLibs.State)
if (not _G.TWIG_STRICT_MODE) then
	_G.TWIG_STRICT_MODE = false
end

local function validateTwig(twig)
	assert(typeof(twig.ClassName) == "string", "Invalid ClassName")
	assert(not twig.Properties or typeof(twig.Properties) == "table", "Properties must be table")
	assert(not twig.Children or typeof(twig.Children) == "table", "Children must be table")
end

function TwigTree.create(ClassName: string, Properties: {[string|number]: any}?, Children: {Twig}?, Name: string?): Twig
	local twig = setmetatable({
		ClassName = ClassName,
		Properties = Properties or {},
		Children = Children or {},
		_stateConnections = {},
		_childHandles = {}
	}, TwigTree)

	if _G.TWIG_STRICT_MODE then
		validateTwig(twig)
	end
	
	if _G.TWIG_DEBUG_MODE then
		print("[Twig] [" .. (Name or ClassName) .. "]: Creating a new TwigTree within the properties of", Properties, "and children of", Children)
	end

	return twig
end

function TwigTree.mount(self: Twig, Parent: Instance): MountedHandle
	if not (self and Parent) then
		return {
			instance = game,
			Cleanup = {},
			GetRef = function() end
		} :: any
	end

	local handle = {
		instance = nil :: Instance?,
		Cleanup = {},
		_ref = nil
	}
	
	local instance = Instance.new(self.ClassName)
	handle.instance = instance
	instance.Parent = Parent
	print(instance)

	for propertyName, propertyValue in pairs(self.Properties) do
		local propType = typeof(propertyValue)

		if typeof(propertyName) == "number" then
			local eventName = TwigTree.Events:getFunctionFromInt(propertyName)
			if eventName then
				local conn = instance[eventName]:Connect(function(...)
					propertyValue(instance, ...)
				end)
				
				table.insert(handle.Cleanup, function() conn:Disconnect() end)
			end

		elseif propertyName == "Ref" then
			if type(propertyValue) == "function" then
				propertyValue(instance)
				table.insert(handle.Cleanup, function() propertyValue(nil) end)
			elseif propertyValue and propertyValue._IsState then
				propertyValue:set(instance)
				table.insert(handle.Cleanup, function() propertyValue:set(nil) end)
			end
			
		elseif propType == "table" and propertyValue._IsState then
			instance[propertyName] = propertyValue:get()
			local conn = propertyValue:onChanged(function(v)
				instance[propertyName] = v
			end)
			
			table.insert(self._stateConnections, conn)
		else
			instance[propertyName] = propertyValue
		end
	end

	for childKey, childTwig in pairs(self.Children) do
		if type(childKey) == "string" then
			childTwig.Properties = childTwig.Properties or {}
			childTwig.Properties.Name = childKey
		end

		local childHandle = TwigTree.mount(childTwig, instance)
		table.insert(self._childHandles, childHandle)
	end

	setmetatable(handle, {
		__index = function(_, key)
			if key == "GetRef" then
				return function() return instance end
			end
			return instance[key]
		end
	})

	if self.Init then
		self:Init(instance)
	end

	return handle
end

function TwigTree:Unmount()
	if not self._unmounted then
		self._unmounted = true
		for i = #self._childHandles, 1, -1 do
			self._childHandles[i]._parentTwig:Unmount()
		end

		for _, conn in ipairs(self._stateConnections) do
			conn:Disconnect()
		end

		if self.mountedHandle then
			for i = #self.mountedHandle.Cleanup, 1, -1 do
				self.mountedHandle.Cleanup[i]()
			end

			if self.mountedHandle.instance then
				self.mountedHandle.instance:Destroy()
			end
		end

		for k in pairs(self) do
			rawset(self, k, nil)
		end
		setmetatable(self, nil)
	end
end

export type State<T> = {
	get: (self: State<T>) -> T,
	set: (self: State<T>, T) -> (),
	onChanged: (self: State<T>, (T) -> ()) -> RBXScriptConnection,
	_IsState: (self: State<T>) -> boolean
}

export type MountedHandle = {
	instance: Instance,
	Cleanup: {() -> ()},
	GetRef: (self: MountedHandle) -> Instance
}

export type Twig = {
	ClassName: string,
	Properties: {[string | number]: any},
	Children: {[any]: Twig},
	Init: (self: Twig, Instance) -> (),
	mount: (self: Twig, Instance) -> MountedHandle,
	Unmount: (self: Twig) -> (),
	_stateConnections: {RBXScriptConnection},
	_childHandles: {MountedHandle},
	_unmounted: boolean?
}

return setmetatable(TwigTree, {
	__index = function(_, key)
		task.spawn(print, key)
		if (key == "new") then
			error('[TwigTree]: Gotten `TwigTree.new` instead of `TwigTree.create`, if you are attempting to use the State constructor, please make sure to use `TwigTree.State.new()`.')
		end
		
		return TwigTree.Events[key]
			or TwigTree.Spr[key]
			or TwigTree.State[key]
	end
})
