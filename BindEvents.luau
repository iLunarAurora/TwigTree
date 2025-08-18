local BindEvents = {
	-- Mouse Events
	MouseButton1Click = 1,
	MouseButton2Click = 2,
	MouseButton1Down = 3,
	MouseButton1Up = 4,
	MouseButton2Down = 5,
	MouseButton2Up = 6,
	MouseEnter = 7,
	MouseLeave = 8,
	MouseMoved = 9,
	MouseWheelForward = 10,
	MouseWheelBackward = 11,

	-- Touch Events
	TouchTap = 12,
	TouchLongPress = 13,
	TouchPinch = 14,
	TouchRotate = 15,
	TouchSwipe = 16,
	TouchPan = 17,

	-- Focus Events
	FocusLost = 18,
	FocusGained = 19,

	-- Text/Input Events
	Changed = 20,
	Focused = 21,
	ReturnPressed = 22,
	SelectionChanged = 23,

	-- Tweening Events
	TweenStarted = 24,
	TweenCompleted = 25,

	-- Scrolling Events
	Scrolled = 26,

	-- Custom UI Events
	Activated = 27,
	Deactivated = 28,
	InputBegan = 29,
	InputChanged = 30,
	InputEnded = 31,

	-- Event Name Mappings
	EventNames = {
		[1] = "MouseButton1Click",
		[2] = "MouseButton2Click",
		[3] = "MouseButton1Down",
		[4] = "MouseButton1Up",
		[5] = "MouseButton2Down",
		[6] = "MouseButton2Up",
		[7] = "MouseEnter",
		[8] = "MouseLeave",
		[9] = "MouseMoved",
		[10] = "MouseWheelForward",
		[11] = "MouseWheelBackward",
		[12] = "TouchTap",
		[13] = "TouchLongPress",
		[14] = "TouchPinch",
		[15] = "TouchRotate",
		[16] = "TouchSwipe",
		[17] = "TouchPan",
		[18] = "FocusLost",
		[19] = "FocusGained",
		[20] = "Changed",
		[21] = "Focused",
		[22] = "ReturnPressed",
		[23] = "SelectionChanged",
		[24] = "TweenStarted",
		[25] = "TweenCompleted",
		[26] = "Scrolled",
		[27] = "Activated",
		[28] = "Deactivated",
		[29] = "InputBegan",
		[30] = "InputChanged",
		[31] = "InputEnded"
	},
}

function BindEvents:getNameFromInt(int: number)
	for name, value in pairs(self) do
		if value == int and type(value) == "number" then
			return name
		end
	end
end

function BindEvents:getFunctionFromInt(int: number)
	return self.EventNames[int]
end

return BindEvents
