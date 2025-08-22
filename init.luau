--[[
	TwigTree by @00ztrix on Discord (Github User: iLunarAurora)
		- Roact but with less braindead and more Lua-like readability
		- No need to learn a new templating language
		- Possibly best beginner-friendly framework there is
	To review supported events, check the BindEvents module
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

-- Base TwigTree Class
--@TwigTree
-- TwigTree.create is a function that creates a blueprint for TwigTree.mount to use.
--[[ Example
	_G.TWIG_STRICT_MODE = true
	_G.TWIG_DEBUG_MODE = true

	local Players = game:GetService("Players")
	local LocalPlayer = Players.LocalPlayer
	local PlayerGui = LocalPlayer.PlayerGui

	local CountState = TwigTree:NewState(0)
	local MainGui = TwigTree.mount(TwigTree.create("ScreenGui", {
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
	}), PlayerGui)()
--]]
function TwigTree.create(ClassName: string, Properties: {[string|number]: any}?, Children: {Twig}?, Name: string?): Twig
	local twig = setmetatable({
		ClassName = ClassName,
		Properties = Properties or {},
		Children = Children or {},
		_stateConnections = {},
		_childHandles = {},
		
		OnMount = function() end,
		OnUnMount = function() end
	}, TwigTree)

	if _G.TWIG_STRICT_MODE then
		validateTwig(twig)
	end
	
	if _G.TWIG_DEBUG_MODE then
		print("[Twig] [" .. (Name or ClassName) .. "]: Creating a new TwigTree within the properties of", Properties, "and children of", Children)
	end

	return twig
end

-- TwigTree.mount is a function, that exports Twig into an Instance object, then parents it to the destined location (or set the parent to nil to just create it)
--[[ Examples:
	ScreenGui:mount(nil)()
	TwigTree.mount(ScreenGui, nil)()
	TwigTree.mount(TwigTree.create("ScreenGui", { IgnoreGuiInset = true }), nil)()
--]]
function TwigTree.mount(self: Twig, Parent: Instance): MountedHandle
	if not (self) then
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
		end,
		__call = function()
			return instance
		end,
	})
	
	self.OnMount(handle(), self)

	return handle
end

-- TwigTree.Unmount is a function which completely removes the mounted object.
function TwigTree:Unmount()
	if not self._unmounted then
		self._unmounted = true
		self.OnUnMount(self)
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

-- TwigTree._isTwigClass is a function that returns true/false if the given argument is a Twig object.
function TwigTree:_isTwigClass(twig: Twig)
	if typeof(twig) == "table" and twig.ClassName ~= nil and twig.Properties ~= nil then
		return true
	end
end

-- TwigTree.instance is a function which converts TwigTree.create or Component(s) into instances.
function TwigTree:instance()
	if self.instance then return self.instance end
	if self:_isTwigClass(self) then return self:mount(nil)() end
	if self.mountedHandle and self.mountedHandle.instance then return self.mountedHandle.instance end
end

--@Component Definition
-- TwigTree.Component is a function, which creates a new TwigStyle (aka Component) object to enhance readability and increase modularity.
--[[ Example:
	local TextInput = TwigTree.Component("TextInput", function(props)
		local textState = TwigTree:NewState(props.value or "")
		local isFocused = TwigTree:NewState(false)

		return TwigTree.create("Frame", {
			Size = props.size or UDim2.fromScale(0.3, 0.05),
			BackgroundColor3 = Color3.fromRGB(160, 160, 160),
			BorderSizePixel = 1,
			BorderColor3 = Color3.fromRGB(100, 100, 100)
		}, {
			Input = TwigTree.create("TextBox", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Text = textState,
				PlaceholderText = props.placeholder or "Enter text...",
				TextXAlignment = Enum.TextXAlignment.Left,
				ClearTextOnFocus = false,

				[TwigTree.Events.Focused] = function()
					isFocused:set(true)
				end,

				[TwigTree.Events.FocusLost] = function(enterPressed)
					isFocused:set(false)
					if props.onSubmit and enterPressed then
						props.onSubmit(textState:get())
					end
					if props.onChange then
						props.onChange(textState:get())
					end
				end
			})
		})
	end)
--]]
function TwigTree.Component(name: string, renderFunc: (Properties: {}?, Children: {}?) -> ()): TwigComponent
	local component = {
		name = name,
		render = renderFunc,
		_isComponent = true
	}

	setmetatable(component, {
		__call = function(self, props: {}?, children: {}?)
			return self.render(props, children)
		end,
	})

	function component:map(transformFunction: (twig: Twig, props: {}?) -> Twig): TwigComponent
		return TwigTree.Component(self.name .. "_Mapped", function(props: {}?)
			local originalRendering = self:render(props)
			return transformFunction(originalRendering, props)
		end)
	end

	return component
end

-- Types
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

export type TwigComponent = typeof(TwigTree.Component())
return setmetatable(TwigTree, {
	__index = function(_, key)
		if (key == "new") then
			error('[TwigTree]: Gotten `TwigTree.new` instead of `TwigTree.create`, if you are attempting to use the State constructor, please make sure to use `TwigTree.State.new()`.')
		end
		
		return TwigTree.Events[key]
			or TwigTree.Spr[key]
			or TwigTree.State[key]
	end
})
