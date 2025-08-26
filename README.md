# 🌱 TwigTree: A Story of Simplicity and Power
> "What if Roact was simpler, felt easier to understand and would be readable to beginners?"

Firstly, let's understand that **TwigTree** is a Framework which enhances and makes sure your workspace is more organized.

This is a module inspired by Roact, which is made to ease the pain of learning.

Also, no hate to Roact, I think it's a great module aswell but I often get too lazy to learn complex modules.

> [!WARNING]
> TwigTree uses a module by Fractality titled `Spr`.
> 
> Check it out [here](https://github.com/Fraktality/spr)

```lua
local TwigTree = require(game.ReplicatedStorage.TwigTree)
TwigTree.create("ScreenGui", {}, {
    TwigTree.create("TextLabel", {
        Text = "Hello TwigTree!",
        Size = UDim2.fromScale(1, 1)
    })
}):mount(player.PlayerGui)
```

# ⚡ Why TwigTree is nice and elegant
- Cleaner than `Instance.new` spam.
- Easy to **re-use UI components**.
- Plugins make this module **super modular**.
- Events & properties are **built-in and simple**.
- Beginner-friendly compared to **Roact**.

# 📝 TwigTree API
## Defining the module
Firtly, let's begin by defining the module. This is the easiest and shortest step.
```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TwigTree = require(ReplicatedStorage.TwigTree)
```

## Creating & mounting new Twig(s)
Creating new Twig(s) is like making more blueprints for `.mount()` to render, which is why both `.create()` and `.mount()` are the main foundation of **TwigTree**.
```lua
-- TwigTree.create(<string> ClassName, <table> Properties, <table:{Twig}> Children)
local newFrame = TwigTree.create("Frame", {
    Position = UDim2.fromScale(0.5, 0.5),
    AnchorPoint = Vector2.one/2,
    Size = UDim.fromOffset(100, 100)
}, {
    TwigTree.create("TextLabel", {
        TextColor3 = Color3.fromRGB(0, 0, 0)
    })
})
```
The snippet above creates a blueprint that renders the Frame later on (that's usable for `.mount()`).

To mount a **TwigBase**, you call ``newFrame:mount(parent)``. (``newFrame:mount(game.Players.LocalPlayer.PlayerGui)``)
> [!TIP]
> Did you know that you can use `newFrame:mount(parent)()` to get the Instance?
> This is because `.mount()` returns the mount handle, with a `__call` metatable which returns it.
> Same with `.mount().GetRef` or `.mount().instance`
>
> To get the **TwigBase**(s) property, you can do ``local bg = mountHandle.BackgroundColor3``
> ```lua
> local Frame = TwigTree.create("Frame", {}, {})
> local FrameHandle = Frame:mount()
> local bg = FrameHandle.BackgroundColor3
> print("Frame's current background color is", bg)
> ```

To grab an event for **TwigBase** elements, inside properties you can do:
```lua
{
    [TwigTree.Events.MouseEnter] = function(self, x, y)
        print("Interacted with", self, "at XY:", x, y)
    end
}
```
There are also **Twig Plugins**, however we will get to that later.

## ❓ Mounting Explained
When you **create** a new **Twig**, you are just creating an idea (blueprint) of the UI design.

When you **mount** the **Twig**, only **then** you are creating the blueprint into an actual Instance.
```lua
-- Creation (blueprint)
local buttonBlueprint = TwigTree.create("TextButton", {
    Text = "Click me!"
})

-- Mounting (creating actual instances)
local buttonHandle = buttonBlueprint:mount(player.PlayerGui)
local actualButton = buttonHandle() -- Get the actual Instance
```

## Creating new Component(s)
**Components** are a different kind of blueprints, however are more reusable and can handle tasks during its creation.
```lua
-- TwigTree.Component(<string> Title, <function> Callback)
local titleComponent = TwigTree.Component("newTitlebar", function(opts)
    local title = (opts and opts.title) or "New TextLabel!"
    local isDraggable = (opts and opts.draggable) or false
    return TwigTree.create("TextLabel", {
        Text = title,
        Active = isDraggable,
        Draggable = isDraggable
    })
end)

-- Possibly inside of TwigTree children, or use cases whenever.
local newTitle = titleComponent{ title = "This is a new title!", draggable = true }
```
**TwigTree Component**(s) can be called like functions, as they are tables with a `__call` metamethod too, hence its creation and argument passage.
Here's a small example of how **Component**(s) can be written:
<details>
<summary>Small store written using TwigTree</summary>
⚠️ This is a tiny demonstration with the intended purpose of being readable, so the GUI will look really basic.
  
```lua
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local playerGui = LocalPlayer:WaitForChild("PlayerGui")

local TwigTree = require(game.ReplicatedStorage.TwigTree)
local Gamepasses = {
	{ id = 12345, title = "VIP Access", priceText = "99" },
	{ id = 67890, title = "2x Coins", priceText = "199" },
	{ id = 11121, title = "Mega Sword", priceText = "399" },
}

local GamepassCard = TwigTree.Component("GamepassCard", function(props)
	return TwigTree.create("Frame", {
		Size = props.size or UDim2.fromScale(0.25, 0.25),
		BackgroundColor3 = Color3.fromRGB(50, 50, 50),
		BorderSizePixel = 0
	}, {
		Title = TwigTree.create("TextLabel", {
			Text = props.title or "Gamepass",
			Size = UDim2.fromScale(1, 0.2),
			TextScaled = true,
			BackgroundTransparency = 1,
			TextColor3 = Color3.fromRGB(255, 255, 255)
		}),

		BuyButton = TwigTree.create("TextButton", {
			Text = "Buy for " .. (props.priceText or "?") .. " R$",
			Size = UDim2.fromScale(1, 0.3),
			Position = UDim2.fromScale(0, 0.7),
			TextScaled = true,
			BackgroundColor3 = Color3.fromRGB(0, 170, 0),
			TextColor3 = Color3.fromRGB(255, 255, 255),

			[TwigTree.Events.MouseButton1Click] = function()
				MarketplaceService:PromptGamePassPurchase(LocalPlayer, props.id)
			end
		})
	})
end)


local StoreUI = TwigTree.mount(TwigTree.create("ScreenGui", {}, {
	StoreFrame = TwigTree.create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1
	}, {
		GridLayout = TwigTree.create("UIGridLayout", {
			CellSize = UDim2.fromScale(0.3, 0.3),
			CellPadding = UDim2.fromScale(0.05, 0.05),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Top,
		}),

		table.unpack((function()
			local cards = {}

			for _, pass in ipairs(Gamepasses) do
				table.insert(cards, GamepassCard(pass))
			end

			return cards
		end)())
	})
}), playerGui)()

```
</details>

## 🧩 Understanding Plugin(s)
**Plugins** are objects which you can think of properties inside of a `TwigTree.create`'s `Properties` field. To add plugins to a Twig, you can add `installments = {[PluginDataHere] = {DataConfig = true}}`.
> [!TIP]
> You don't have to include `installments` inside the `Properties` field, you can just add plugins exactly like this aswell:
> ```lua
> local dataPlugin = TwigTree.createPlugin({
>    onMount = function(instance, config)
>         for name, value in pairs(config) do
>             instance[name] = value
>         end
>     end
> })
> 
> TwigTree.create("Frame", {
>    [dataPlugin] = {Visible = true},
>    Position = UDim2.fromScale(0.5, 0.5)
> })
> ```

Plugins can be used for many great features, such as making a highly modular plugin container module, which can enhance UI design in pure Luau.
```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayersService = game:GetService("Players")
local PlayerGui = PlayersService.LocalPlayer:WaitForChild("PlayerGui")
local TwigTree = require(ReplicatedStorage.TwigTree)
local DragPlugin = TwigTree.createPlugin({
	onMount = function(self: Frame, config)
		self.Draggable = config.enabled
		self.Active = config.enabled
	end
})

local guiBlueprint = TwigTree:newUserInterface(true, false, {
	-- plugins inside GUI
}, {
	TwigTree.create("Frame", {
		installments = {
			[DragPlugin] = {
				enabled = true
			}
		},
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.one/2,
		Size = UDim2.fromOffset(100, 100)
	})
}):mount(PlayerGui)
```

## ❓ Troubleshooting
### My UI isn't appearing!
- Did you remember to call `:mount()` with a parent?
- Is the parent instance valid and visible? Is the objects' size correct?
- Does it appear in the `PlayerGui` `Instance` of your `LocalPlayer`?

### Events aren't firing!
- Make sure you're using `TwigTree.Events.EventName` as the key
- Check that the event is supported by the Roblox class

## 📦 Installation

1. Get TwigTree from [The Official TwigTree Repository](https://github.com/iLunarAurora/TwigTree) (Click the Releases tab bottom right)
2. Place it in ReplicatedStorage or anywhere
3. Require it in your scripts, then enjoy!

# ☀️ The End
This is the end of the documentary written by [iLunarAurora](https://github.com/iLunarAurora), I hope you'll have fun using TwigTree!
**More features are coming**
