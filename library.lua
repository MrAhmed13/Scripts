--[[
	Vertex UI Library
	A lightweight, animated UI library for Roblox executors.
	Original design, built from scratch. See README.md for usage.
]]

local Library = {}
Library.Version = "1.0.0"
Library.Unloaded = false
Library.Toggled = true

-- // Services
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- // State
Library.Flags = {}
Library.Toggles = {}
Library.Options = {}
Library.Connections = {}
Library.ThemeMap = {}
Library.Windows = {}
Library.OpenPopups = {}
Library.Popups = {}

-- // Default theme
Library.Scheme = {
	Accent = Color3.fromRGB(140, 130, 255),
	Background = Color3.fromRGB(17, 17, 23),
	Topbar = Color3.fromRGB(23, 23, 31),
	Surface = Color3.fromRGB(25, 25, 33),
	Element = Color3.fromRGB(33, 33, 43),
	ElementHover = Color3.fromRGB(41, 41, 53),
	Outline = Color3.fromRGB(44, 44, 57),
	Text = Color3.fromRGB(236, 236, 245),
	SubText = Color3.fromRGB(148, 148, 164),
	Placeholder = Color3.fromRGB(104, 104, 120),
	Danger = Color3.fromRGB(255, 92, 102),
}
Library.Font = Enum.Font.Gotham
Library.FontBold = Enum.Font.GothamBold
Library.ToggleKey = Enum.KeyCode.RightControl

-- // Helpers
local function New(class, props, children)
	local inst = Instance.new(class)
	if props then
		for k, v in pairs(props) do
			if k ~= "Parent" then
				inst[k] = v
			end
		end
	end
	if children then
		for _, c in ipairs(children) do
			c.Parent = inst
		end
	end
	if props and props.Parent then
		inst.Parent = props.Parent
	end
	return inst
end

local function Corner(radius, parent)
	return New("UICorner", { CornerRadius = UDim.new(0, radius or 6), Parent = parent })
end

local function Stroke(parent, color, thickness, transparency)
	return New("UIStroke", {
		Color = color or Library.Scheme.Outline,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
end

local function Pad(parent, all)
	return New("UIPadding", {
		PaddingTop = UDim.new(0, all),
		PaddingBottom = UDim.new(0, all),
		PaddingLeft = UDim.new(0, all),
		PaddingRight = UDim.new(0, all),
		Parent = parent,
	})
end

local function Tween(obj, dur, goal, style, dir)
	local info = TweenInfo.new(dur, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out)
	local t = TweenService:Create(obj, info, goal)
	t:Play()
	return t
end

local function Connect(signal, fn)
	local c = signal:Connect(fn)
	table.insert(Library.Connections, c)
	return c
end

local function Darken(c, f)
	return Color3.new(c.R * (1 - f), c.G * (1 - f), c.B * (1 - f))
end

local function Lighten(c, f)
	return Color3.new(c.R + (1 - c.R) * f, c.G + (1 - c.G) * f, c.B + (1 - c.B) * f)
end

-- // Theme registration: objects re-color live when the scheme changes
function Library:Register(obj, prop, key, mod)
	table.insert(Library.ThemeMap, { Obj = obj, Prop = prop, Key = key, Mod = mod })
	local val = Library.Scheme[key]
	if mod then
		val = mod(val)
	end
	pcall(function()
		obj[prop] = val
	end)
	return obj
end

function Library:Refresh()
	for _, e in ipairs(Library.ThemeMap) do
		local val = Library.Scheme[e.Key]
		if val ~= nil then
			if e.Mod then
				val = e.Mod(val)
			end
			pcall(function()
				e.Obj[e.Prop] = val
			end)
		end
	end
end

-- // GUI host
local function GetGuiParent()
	local ok, hui = pcall(function()
		return gethui()
	end)
	if ok and typeof(hui) == "Instance" then
		return hui
	end
	local ok2, cg = pcall(function()
		return game:GetService("CoreGui")
	end)
	if ok2 and cg then
		return cg
	end
	return LocalPlayer:WaitForChild("PlayerGui")
end

local function Protect(gui)
	pcall(function()
		if syn and syn.protect_gui then
			syn.protect_gui(gui)
		elseif protect_gui then
			protect_gui(gui)
		end
	end)
end

-- // Root ScreenGui
local ScreenGui = New("ScreenGui", {
	Name = "VertexUI_" .. tostring(math.random(10000, 99999)),
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	IgnoreGuiInset = true,
	DisplayOrder = 999,
})
Protect(ScreenGui)
ScreenGui.Parent = GetGuiParent()
Library.ScreenGui = ScreenGui

-- // Notification container
local NotifHolder = New("Frame", {
	Name = "Notifications",
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -16, 1, -16),
	Size = UDim2.new(0, 300, 1, -32),
	BackgroundTransparency = 1,
	Parent = ScreenGui,
})
New("UIListLayout", {
	FillDirection = Enum.FillDirection.Vertical,
	VerticalAlignment = Enum.VerticalAlignment.Bottom,
	HorizontalAlignment = Enum.HorizontalAlignment.Right,
	SortOrder = Enum.SortOrder.LayoutOrder,
	Padding = UDim.new(0, 8),
	Parent = NotifHolder,
})

function Library:Notify(opts)
	if typeof(opts) == "string" then
		opts = { Text = opts }
	end
	opts = opts or {}
	local title = opts.Title or "Vertex"
	local text = opts.Text or ""
	local duration = opts.Duration or 4

	local card = New("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Library.Scheme.Surface,
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = NotifHolder,
	})
	Corner(8, card)
	Library:Register(card, "BackgroundColor3", "Surface")
	local cStroke = Stroke(card, Library.Scheme.Outline, 1, 1)
	Library:Register(cStroke, "Color", "Outline")

	local bar = New("Frame", {
		Size = UDim2.new(0, 3, 1, 0),
		BackgroundColor3 = Library.Scheme.Accent,
		BorderSizePixel = 0,
		Parent = card,
	})
	Corner(4, bar)
	Library:Register(bar, "BackgroundColor3", "Accent")

	local body = New("Frame", {
		Size = UDim2.new(1, -12, 1, 0),
		Position = UDim2.new(0, 12, 0, 0),
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = card,
	})
	Pad(body, 10)
	New("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 3),
		Parent = body,
	})

	local titleLabel = New("TextLabel", {
		Size = UDim2.new(1, 0, 0, 16),
		BackgroundTransparency = 1,
		Font = Library.FontBold,
		Text = title,
		TextColor3 = Library.Scheme.Text,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTransparency = 1,
		Parent = body,
	})
	Library:Register(titleLabel, "TextColor3", "Text")

	local textLabel = New("TextLabel", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Font = Library.Font,
		Text = text,
		TextColor3 = Library.Scheme.SubText,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		TextTransparency = 1,
		Parent = body,
	})
	Library:Register(textLabel, "TextColor3", "SubText")

	Tween(card, 0.3, { BackgroundTransparency = 0 })
	Tween(cStroke, 0.3, { Transparency = 0 })
	Tween(titleLabel, 0.35, { TextTransparency = 0 })
	Tween(textLabel, 0.35, { TextTransparency = 0 })

	task.delay(duration, function()
		if card and card.Parent then
			Tween(card, 0.3, { BackgroundTransparency = 1 })
			Tween(cStroke, 0.3, { Transparency = 1 })
			Tween(titleLabel, 0.25, { TextTransparency = 1 })
			Tween(textLabel, 0.25, { TextTransparency = 1 })
			task.wait(0.32)
			card:Destroy()
		end
	end)
	return card
end

-- // Watermark
local Watermark = New("Frame", {
	Name = "Watermark",
	Position = UDim2.new(0, 16, 0, 16),
	Size = UDim2.new(0, 180, 0, 30),
	AutomaticSize = Enum.AutomaticSize.X,
	BackgroundColor3 = Library.Scheme.Topbar,
	Visible = false,
	Parent = ScreenGui,
})
Corner(6, Watermark)
Library:Register(Watermark, "BackgroundColor3", "Topbar")
local wmStroke = Stroke(Watermark, Library.Scheme.Outline, 1, 0)
Library:Register(wmStroke, "Color", "Outline")
local wmAccent = New("Frame", {
	Size = UDim2.new(1, 0, 0, 2),
	Position = UDim2.new(0, 0, 0, 0),
	BackgroundColor3 = Library.Scheme.Accent,
	BorderSizePixel = 0,
	Parent = Watermark,
})
Library:Register(wmAccent, "BackgroundColor3", "Accent")
local wmLabel = New("TextLabel", {
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundTransparency = 1,
	Font = Library.FontBold,
	Text = "Vertex",
	TextColor3 = Library.Scheme.Text,
	TextSize = 14,
	Parent = Watermark,
})
Pad(wmLabel, 10)
Library:Register(wmLabel, "TextColor3", "Text")

function Library:SetWatermark(text)
	wmLabel.Text = text
	Watermark.Visible = true
end
function Library:SetWatermarkVisibility(state)
	Watermark.Visible = state
end

-- // Draggable helper
local function MakeDraggable(handle, target)
	local dragging = false
	local dragStart, startPos
	Connect(handle.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = target.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	Connect(UserInputService.InputChanged, function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			target.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end)
end

function Library:CreateWindow(opts)
	opts = opts or {}
	local title = opts.Title or "Vertex"
	local subtitle = opts.Subtitle or "UI Library"
	local size = opts.Size or UDim2.new(0, 620, 0, 460)

	local Window = {}
	Window.Tabs = {}
	Window.ActiveTab = nil

	-- Root frame
	local Root = New("Frame", {
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = size,
		BackgroundColor3 = Library.Scheme.Background,
		ClipsDescendants = true,
		Parent = ScreenGui,
	})
	Corner(10, Root)
	Library:Register(Root, "BackgroundColor3", "Background")
	local rootStroke = Stroke(Root, Library.Scheme.Outline, 1, 0)
	Library:Register(rootStroke, "Color", "Outline")
	Window.Root = Root

	-- Open animation
	Root.Size = UDim2.new(0, 0, 0, 0)
	Tween(Root, 0.4, { Size = size }, Enum.EasingStyle.Back)

	-- Topbar
	local Topbar = New("Frame", {
		Name = "Topbar",
		Size = UDim2.new(1, 0, 0, 42),
		BackgroundColor3 = Library.Scheme.Topbar,
		BorderSizePixel = 0,
		Parent = Root,
	})
	Library:Register(Topbar, "BackgroundColor3", "Topbar")
	New("Frame", {
		Size = UDim2.new(1, 0, 0, 10),
		Position = UDim2.new(0, 0, 1, -10),
		BackgroundColor3 = Library.Scheme.Topbar,
		BorderSizePixel = 0,
		Parent = Topbar,
	})
	MakeDraggable(Topbar, Root)

	local titleHolder = New("Frame", {
		Size = UDim2.new(1, -120, 1, 0),
		Position = UDim2.new(0, 14, 0, 0),
		BackgroundTransparency = 1,
		Parent = Topbar,
	})
	local titleLabel = New("TextLabel", {
		Size = UDim2.new(1, 0, 0, 16),
		Position = UDim2.new(0, 0, 0, 6),
		BackgroundTransparency = 1,
		Font = Library.FontBold,
		Text = title,
		TextColor3 = Library.Scheme.Text,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = titleHolder,
	})
	Library:Register(titleLabel, "TextColor3", "Text")
	local subLabel = New("TextLabel", {
		Size = UDim2.new(1, 0, 0, 12),
		Position = UDim2.new(0, 0, 0, 22),
		BackgroundTransparency = 1,
		Font = Library.Font,
		Text = subtitle,
		TextColor3 = Library.Scheme.SubText,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = titleHolder,
	})
	Library:Register(subLabel, "TextColor3", "SubText")

	-- Close + minimize buttons
	local function MakeTopBtn(offset, glyph, color)
		local b = New("TextButton", {
			Size = UDim2.new(0, 24, 0, 24),
			Position = UDim2.new(1, offset, 0, 9),
			BackgroundColor3 = Library.Scheme.Element,
			Text = glyph,
			Font = Library.FontBold,
			TextSize = 14,
			TextColor3 = color or Library.Scheme.SubText,
			AutoButtonColor = false,
			Parent = Topbar,
		})
		Corner(6, b)
		Connect(b.MouseEnter, function()
			Tween(b, 0.15, { BackgroundColor3 = Library.Scheme.ElementHover })
		end)
		Connect(b.MouseLeave, function()
			Tween(b, 0.15, { BackgroundColor3 = Library.Scheme.Element })
		end)
		return b
	end

	local closeBtn = MakeTopBtn(-32, "✕", Library.Scheme.Danger)
	local minBtn = MakeTopBtn(-62, "—")

	Connect(closeBtn.MouseButton1Click, function()
		Library:Unload()
	end)
	Connect(minBtn.MouseButton1Click, function()
		Library:Toggle()
	end)

	-- Sidebar (tab list)
	local Sidebar = New("Frame", {
		Name = "Sidebar",
		Position = UDim2.new(0, 0, 0, 42),
		Size = UDim2.new(0, 150, 1, -42),
		BackgroundColor3 = Library.Scheme.Surface,
		BorderSizePixel = 0,
		Parent = Root,
	})
	Library:Register(Sidebar, "BackgroundColor3", "Surface")
	local TabList = New("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Parent = Sidebar,
	})
	Pad(TabList, 8)
	New("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 4),
		Parent = TabList,
	})
	Window.TabList = TabList

	-- Content container
	local Container = New("Frame", {
		Name = "Container",
		Position = UDim2.new(0, 150, 0, 42),
		Size = UDim2.new(1, -150, 1, -42),
		BackgroundTransparency = 1,
		Parent = Root,
	})
	Window.Container = Container

	function Window:AddTab(name, icon)
		local Tab = {}
		Tab.Name = name
		Tab.Groupboxes = {}

		-- Tab button
		local btn = New("TextButton", {
			Size = UDim2.new(1, 0, 0, 34),
			BackgroundColor3 = Library.Scheme.Element,
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			Parent = TabList,
		})
		Corner(6, btn)
		local indicator = New("Frame", {
			Size = UDim2.new(0, 3, 0, 0),
			Position = UDim2.new(0, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = Library.Scheme.Accent,
			BorderSizePixel = 0,
			Parent = btn,
		})
		Corner(4, indicator)
		Library:Register(indicator, "BackgroundColor3", "Accent")
		local label = New("TextLabel", {
			Size = UDim2.new(1, -16, 1, 0),
			Position = UDim2.new(0, 14, 0, 0),
			BackgroundTransparency = 1,
			Font = Library.Font,
			Text = (icon and (icon .. "  ") or "") .. name,
			TextColor3 = Library.Scheme.SubText,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = btn,
		})

		-- Page: two scrolling columns
		local page = New("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Visible = false,
			Parent = Container,
		})
		Pad(page, 10)

		local function MakeColumn(xScale, xOff, wOff)
			local col = New("ScrollingFrame", {
				Size = UDim2.new(0.5, wOff, 1, 0),
				Position = UDim2.new(xScale, xOff, 0, 0),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ScrollBarThickness = 3,
				ScrollBarImageColor3 = Library.Scheme.Accent,
				CanvasSize = UDim2.new(0, 0, 0, 0),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				ScrollingDirection = Enum.ScrollingDirection.Y,
				Parent = page,
			})
			New("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 10),
				Parent = col,
			})
			Library:Register(col, "ScrollBarImageColor3", "Accent")
			return col
		end

		local left = MakeColumn(0, 0, -5)
		local right = MakeColumn(0.5, 5, -5)
		Tab.Left = left
		Tab.Right = right
		Tab.Page = btn

		function Tab:Select()
			for _, t in ipairs(Window.Tabs) do
				t.Content.Visible = false
				Tween(t.Button, 0.15, { BackgroundTransparency = 1 })
				Tween(t.Label, 0.15, { TextColor3 = Library.Scheme.SubText })
				Tween(t.Indicator, 0.2, { Size = UDim2.new(0, 3, 0, 0) })
			end
			page.Visible = true
			Tween(btn, 0.15, { BackgroundTransparency = 0, BackgroundColor3 = Library.Scheme.Element })
			Tween(label, 0.15, { TextColor3 = Library.Scheme.Text })
			Tween(indicator, 0.2, { Size = UDim2.new(0, 3, 0, 18) })
			Window.ActiveTab = Tab
		end

		Tab.Button = btn
		Tab.Label = label
		Tab.Indicator = indicator
		Tab.Content = page

		Connect(btn.MouseEnter, function()
			if Window.ActiveTab ~= Tab then
				Tween(btn, 0.15, { BackgroundTransparency = 0.5, BackgroundColor3 = Library.Scheme.Element })
			end
		end)
		Connect(btn.MouseLeave, function()
			if Window.ActiveTab ~= Tab then
				Tween(btn, 0.15, { BackgroundTransparency = 1 })
			end
		end)
		Connect(btn.MouseButton1Click, function()
			Tab:Select()
		end)

		table.insert(Window.Tabs, Tab)
		if #Window.Tabs == 1 then
			Tab:Select()
		end

		function Tab:AddLeftGroupbox(gbTitle)
			return Library:_CreateGroupbox(left, gbTitle)
		end
		function Tab:AddRightGroupbox(gbTitle)
			return Library:_CreateGroupbox(right, gbTitle)
		end
		-- aliases
		Tab.AddGroupbox = Tab.AddLeftGroupbox

		return Tab
	end

	function Window:SelectTab(i)
		if Window.Tabs[i] then
			Window.Tabs[i]:Select()
		end
	end

	table.insert(Library.Windows, Window)
	return Window
end

-- // Small signal helper for element :OnChanged callbacks
local function MakeSignal()
	local list = {}
	return {
		Connect = function(_, fn)
			table.insert(list, fn)
		end,
		Fire = function(_, ...)
			for _, fn in ipairs(list) do
				task.spawn(fn, ...)
			end
		end,
	}
end

-- // Groupbox factory
function Library:_CreateGroupbox(column, title)
	local Groupbox = {}

	local frame = New("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Library.Scheme.Surface,
		Parent = column,
	})
	Corner(8, frame)
	Library:Register(frame, "BackgroundColor3", "Surface")
	local gbStroke = Stroke(frame, Library.Scheme.Outline, 1, 0)
	Library:Register(gbStroke, "Color", "Outline")

	local header = New("TextLabel", {
		Size = UDim2.new(1, -24, 0, 18),
		Position = UDim2.new(0, 12, 0, 10),
		BackgroundTransparency = 1,
		Font = Library.FontBold,
		Text = title or "Groupbox",
		TextColor3 = Library.Scheme.Text,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = frame,
	})
	Library:Register(header, "TextColor3", "Text")
	local headLine = New("Frame", {
		Size = UDim2.new(0, 22, 0, 2),
		Position = UDim2.new(0, 12, 0, 30),
		BackgroundColor3 = Library.Scheme.Accent,
		BorderSizePixel = 0,
		Parent = frame,
	})
	Corner(2, headLine)
	Library:Register(headLine, "BackgroundColor3", "Accent")

	local container = New("Frame", {
		Size = UDim2.new(1, -20, 0, 0),
		Position = UDim2.new(0, 10, 0, 40),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = frame,
	})
	New("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 6),
		Parent = container,
	})
	New("UIPadding", { PaddingBottom = UDim.new(0, 12), Parent = container })
	Groupbox.Container = container
	Groupbox.Frame = frame

	-- Row builder: base frame for one element
	local function Row(height)
		return New("Frame", {
			Size = UDim2.new(1, 0, 0, height),
			BackgroundTransparency = 1,
			Parent = container,
		})
	end

	-- ---- Label ----
	function Groupbox:AddLabel(text, wrap)
		local lbl = New("TextLabel", {
			Size = UDim2.new(1, 0, 0, 16),
			AutomaticSize = wrap and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
			BackgroundTransparency = 1,
			Font = Library.Font,
			Text = text or "",
			TextColor3 = Library.Scheme.Text,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = wrap or false,
			Parent = container,
		})
		Library:Register(lbl, "TextColor3", "Text")
		local obj = {}
		function obj:SetText(t)
			lbl.Text = t
		end
		return obj
	end

	-- ---- Divider ----
	function Groupbox:AddDivider()
		local holder = Row(8)
		local line = New("Frame", {
			Size = UDim2.new(1, 0, 0, 1),
			Position = UDim2.new(0, 0, 0.5, 0),
			BackgroundColor3 = Library.Scheme.Outline,
			BorderSizePixel = 0,
			Parent = holder,
		})
		Library:Register(line, "BackgroundColor3", "Outline")
		return {}
	end

	-- ---- Button ----
	function Groupbox:AddButton(a, b)
		local text, callback
		if typeof(a) == "table" then
			text = a.Text
			callback = a.Func or a.Callback
		else
			text = a
			callback = b
		end
		callback = callback or function() end

		local btn = New("TextButton", {
			Size = UDim2.new(1, 0, 0, 32),
			BackgroundColor3 = Library.Scheme.Element,
			Text = text or "Button",
			Font = Library.Font,
			TextSize = 13,
			TextColor3 = Library.Scheme.Text,
			AutoButtonColor = false,
			Parent = container,
		})
		Corner(6, btn)
		Library:Register(btn, "BackgroundColor3", "Element")
		Library:Register(btn, "TextColor3", "Text")
		local bStroke = Stroke(btn, Library.Scheme.Outline, 1, 0)
		Library:Register(bStroke, "Color", "Outline")

		Connect(btn.MouseEnter, function()
			Tween(btn, 0.15, { BackgroundColor3 = Library.Scheme.ElementHover })
		end)
		Connect(btn.MouseLeave, function()
			Tween(btn, 0.15, { BackgroundColor3 = Library.Scheme.Element })
		end)
		Connect(btn.MouseButton1Down, function()
			Tween(btn, 0.1, { BackgroundColor3 = Darken(Library.Scheme.Accent, 0.2) })
		end)
		Connect(btn.MouseButton1Up, function()
			Tween(btn, 0.15, { BackgroundColor3 = Library.Scheme.ElementHover })
		end)
		Connect(btn.MouseButton1Click, function()
			task.spawn(callback)
		end)

		local obj = {}
		function obj:SetText(t)
			btn.Text = t
		end
		return obj
	end

	-- ---- Toggle ----
	function Groupbox:AddToggle(flag, opts)
		opts = opts or {}
		local text = opts.Text or flag
		local value = opts.Default or false
		local callback = opts.Callback or function() end
		Library.Flags[flag] = value

		local row = Row(22)
		local click = New("TextButton", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Text = "",
			Parent = row,
		})
		local label = New("TextLabel", {
			Size = UDim2.new(1, -50, 1, 0),
			BackgroundTransparency = 1,
			Font = Library.Font,
			Text = text,
			TextColor3 = Library.Scheme.SubText,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = row,
		})
		Library:Register(label, "TextColor3", "SubText")

		local rightHolder = New("Frame", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, 0, 0.5, 0),
			Size = UDim2.new(0, 0, 1, 0),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			Parent = row,
		})
		New("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 6),
			Parent = rightHolder,
		})

		local track = New("Frame", {
			Size = UDim2.new(0, 38, 0, 18),
			BackgroundColor3 = value and Library.Scheme.Accent or Library.Scheme.Element,
			LayoutOrder = 100,
			Parent = rightHolder,
		})
		Corner(9, track)
		local knob = New("Frame", {
			Size = UDim2.new(0, 14, 0, 14),
			Position = value and UDim2.new(0, 22, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BorderSizePixel = 0,
			Parent = track,
		})
		Corner(7, knob)

		local changed = MakeSignal()
		local toggleObj = { Value = value, Type = "Toggle" }

		local function apply(v, fire)
			toggleObj.Value = v
			Library.Flags[flag] = v
			if v then
				Tween(track, 0.2, { BackgroundColor3 = Library.Scheme.Accent })
				Tween(knob, 0.2, { Position = UDim2.new(0, 22, 0.5, 0) }, Enum.EasingStyle.Back)
			else
				Tween(track, 0.2, { BackgroundColor3 = Library.Scheme.Element })
				Tween(knob, 0.2, { Position = UDim2.new(0, 2, 0.5, 0) }, Enum.EasingStyle.Back)
			end
			if fire ~= false then
				task.spawn(callback, v)
				changed:Fire(v)
			end
		end

		Connect(click.MouseButton1Click, function()
			apply(not toggleObj.Value)
		end)
		Connect(click.MouseEnter, function()
			Tween(label, 0.15, { TextColor3 = Library.Scheme.Text })
		end)
		Connect(click.MouseLeave, function()
			Tween(label, 0.15, { TextColor3 = Library.Scheme.SubText })
		end)

		function toggleObj:SetValue(v)
			apply(v and true or false)
		end
		function toggleObj:OnChanged(fn)
			changed:Connect(fn)
			task.spawn(fn, toggleObj.Value)
			return toggleObj
		end
		-- attach a colorpicker / keybind inline (Obsidian-style)
		function toggleObj:AddColorPicker(cpFlag, cpOpts)
			return Library:_ColorPicker(rightHolder, cpFlag, cpOpts, 1)
		end
		function toggleObj:AddKeyPicker(kpFlag, kpOpts)
			return Library:_KeyPicker(rightHolder, kpFlag, kpOpts, 2)
		end

		Library.Toggles[flag] = toggleObj
		return toggleObj
	end

	-- ---- Slider ----
	function Groupbox:AddSlider(flag, opts)
		opts = opts or {}
		local text = opts.Text or flag
		local min = opts.Min or 0
		local max = opts.Max or 100
		local decimals = opts.Decimals or 0
		local suffix = opts.Suffix or ""
		local value = opts.Default or min
		local callback = opts.Callback or function() end

		local step = 1
		local d = 0
		while d < decimals do
			step = step / 10
			d = d + 1
		end
		local function round(v)
			if decimals <= 0 then
				return math.floor(v + 0.5)
			end
			local m = 1
			local i = 0
			while i < decimals do
				m = m * 10
				i = i + 1
			end
			return math.floor(v * m + 0.5) / m
		end

		Library.Flags[flag] = value

		local row = Row(38)
		local label = New("TextLabel", {
			Size = UDim2.new(1, -60, 0, 16),
			BackgroundTransparency = 1,
			Font = Library.Font,
			Text = text,
			TextColor3 = Library.Scheme.SubText,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = row,
		})
		Library:Register(label, "TextColor3", "SubText")
		local valueLabel = New("TextLabel", {
			Size = UDim2.new(0, 60, 0, 16),
			Position = UDim2.new(1, -60, 0, 0),
			BackgroundTransparency = 1,
			Font = Library.FontBold,
			Text = tostring(value) .. suffix,
			TextColor3 = Library.Scheme.Text,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Right,
			Parent = row,
		})
		Library:Register(valueLabel, "TextColor3", "Text")

		local track = New("Frame", {
			Size = UDim2.new(1, 0, 0, 8),
			Position = UDim2.new(0, 0, 0, 24),
			BackgroundColor3 = Library.Scheme.Element,
			Parent = row,
		})
		Corner(4, track)
		Library:Register(track, "BackgroundColor3", "Element")
		local fill = New("Frame", {
			Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
			BackgroundColor3 = Library.Scheme.Accent,
			BorderSizePixel = 0,
			Parent = track,
		})
		Corner(4, fill)
		Library:Register(fill, "BackgroundColor3", "Accent")

		local sliderObj = { Value = value, Type = "Slider" }
		local changed = MakeSignal()

		local function set(v, fire, instant)
			v = math.clamp(round(v), min, max)
			sliderObj.Value = v
			Library.Flags[flag] = v
			valueLabel.Text = tostring(v) .. suffix
			local ratio = (v - min) / (max - min)
			if instant then
				fill.Size = UDim2.new(ratio, 0, 1, 0)
			else
				Tween(fill, 0.12, { Size = UDim2.new(ratio, 0, 1, 0) })
			end
			if fire ~= false then
				task.spawn(callback, v)
				changed:Fire(v)
			end
		end

		local dragging = false
		local function update()
			local ratio = math.clamp((Mouse.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
			set(min + (max - min) * ratio, true, true)
		end
		Connect(track.InputBegan, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				update()
			end
		end)
		Connect(UserInputService.InputEnded, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)
		Connect(RunService.RenderStepped, function()
			if dragging then
				update()
			end
		end)

		function sliderObj:SetValue(v)
			set(v)
		end
		function sliderObj:OnChanged(fn)
			changed:Connect(fn)
			task.spawn(fn, sliderObj.Value)
			return sliderObj
		end

		Library.Options[flag] = sliderObj
		return sliderObj
	end

	-- ---- Dropdown ----
	function Groupbox:AddDropdown(flag, opts)
		opts = opts or {}
		local text = opts.Text or flag
		local values = opts.Values or {}
		local multi = opts.Multi or false
		local callback = opts.Callback or function() end

		local value
		if multi then
			value = {}
			if typeof(opts.Default) == "table" then
				for _, v in ipairs(opts.Default) do
					value[v] = true
				end
			end
		else
			value = opts.Default
		end
		Library.Flags[flag] = value

		local row = Row(40)
		local label = New("TextLabel", {
			Size = UDim2.new(1, 0, 0, 14),
			BackgroundTransparency = 1,
			Font = Library.Font,
			Text = text,
			TextColor3 = Library.Scheme.SubText,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = row,
		})
		Library:Register(label, "TextColor3", "SubText")

		local button = New("TextButton", {
			Size = UDim2.new(1, 0, 0, 22),
			Position = UDim2.new(0, 0, 0, 16),
			BackgroundColor3 = Library.Scheme.Element,
			Text = "",
			AutoButtonColor = false,
			Parent = row,
		})
		Corner(6, button)
		Library:Register(button, "BackgroundColor3", "Element")
		local dStroke = Stroke(button, Library.Scheme.Outline, 1, 0)
		Library:Register(dStroke, "Color", "Outline")
		local selLabel = New("TextLabel", {
			Size = UDim2.new(1, -30, 1, 0),
			Position = UDim2.new(0, 8, 0, 0),
			BackgroundTransparency = 1,
			Font = Library.Font,
			Text = "...",
			TextColor3 = Library.Scheme.Text,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = button,
		})
		Library:Register(selLabel, "TextColor3", "Text")
		local arrow = New("TextLabel", {
			Size = UDim2.new(0, 20, 1, 0),
			Position = UDim2.new(1, -22, 0, 0),
			BackgroundTransparency = 1,
			Font = Library.FontBold,
			Text = "▼",
			TextColor3 = Library.Scheme.SubText,
			TextSize = 10,
			Parent = button,
		})
		Library:Register(arrow, "TextColor3", "SubText")

		local dropObj = { Value = value, Type = "Dropdown" }
		local changed = MakeSignal()

		local function display()
			if multi then
				local parts = {}
				for _, v in ipairs(values) do
					if dropObj.Value[v] then
						table.insert(parts, v)
					end
				end
				if #parts == 0 then
					selLabel.Text = "None"
				else
					selLabel.Text = table.concat(parts, ", ")
				end
			else
				selLabel.Text = dropObj.Value ~= nil and tostring(dropObj.Value) or "..."
			end
		end
		display()

		-- Popup
		local popup = New("Frame", {
			Size = UDim2.new(0, 100, 0, 0),
			BackgroundColor3 = Library.Scheme.Surface,
			BorderSizePixel = 0,
			Visible = false,
			ZIndex = 60,
			ClipsDescendants = true,
			Parent = ScreenGui,
		})
		Corner(6, popup)
		local pStroke = Stroke(popup, Library.Scheme.Accent, 1, 0)
		pStroke.ZIndex = 61
		local listFrame = New("ScrollingFrame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 3,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ZIndex = 61,
			Parent = popup,
		})
		New("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = listFrame })
		Pad(listFrame, 4)

		local optButtons = {}
		local function rebuild()
			for _, b in ipairs(optButtons) do
				b:Destroy()
			end
			optButtons = {}
			for _, v in ipairs(values) do
				local ob = New("TextButton", {
					Size = UDim2.new(1, 0, 0, 24),
					BackgroundColor3 = Library.Scheme.Element,
					BackgroundTransparency = 1,
					Text = tostring(v),
					Font = Library.Font,
					TextSize = 13,
					TextColor3 = Library.Scheme.SubText,
					AutoButtonColor = false,
					ZIndex = 62,
					Parent = listFrame,
				})
				Corner(4, ob)
				local function paint()
					local on = false
					if multi then
						on = dropObj.Value[v] == true
					else
						on = dropObj.Value == v
					end
					if on then
						Tween(ob, 0.15, { BackgroundTransparency = 0, BackgroundColor3 = Library.Scheme.Accent })
						ob.TextColor3 = Color3.fromRGB(255, 255, 255)
					else
						Tween(ob, 0.15, { BackgroundTransparency = 1 })
						ob.TextColor3 = Library.Scheme.SubText
					end
				end
				paint()
				Connect(ob.MouseButton1Click, function()
					if multi then
						dropObj.Value[v] = not dropObj.Value[v] or nil
					else
						dropObj.Value = v
					end
					Library.Flags[flag] = dropObj.Value
					display()
					for _, other in ipairs(optButtons) do
						other._paint()
					end
					task.spawn(callback, dropObj.Value)
					changed:Fire(dropObj.Value)
					if not multi then
						dropObj._close()
					end
				end)
				ob._paint = paint
				table.insert(optButtons, ob)
			end
		end
		rebuild()

		local open = false
		function dropObj._close()
			if not open then
				return
			end
			open = false
			Tween(arrow, 0.2, { Rotation = 0 })
			Tween(popup, 0.18, { Size = UDim2.new(0, popup.AbsoluteSize.X, 0, 0) })
			task.delay(0.18, function()
				if not open then
					popup.Visible = false
				end
			end)
		end
		local function openPopup()
			for _, closer in ipairs(Library.Popups) do
				closer()
			end
			open = true
			popup.Visible = true
			local w = button.AbsoluteSize.X
			local count = #values
			local h = count * 26 + 8
			if h > 170 then
				h = 170
			end
			popup.Position = UDim2.fromOffset(button.AbsolutePosition.X, button.AbsolutePosition.Y + button.AbsoluteSize.Y + 4)
			popup.Size = UDim2.new(0, w, 0, 0)
			Tween(popup, 0.2, { Size = UDim2.new(0, w, 0, h) })
			Tween(arrow, 0.2, { Rotation = 180 })
		end
		table.insert(Library.Popups, dropObj._close)

		Connect(button.MouseButton1Click, function()
			if open then
				dropObj._close()
			else
				openPopup()
			end
		end)
		Connect(button.MouseEnter, function()
			Tween(button, 0.15, { BackgroundColor3 = Library.Scheme.ElementHover })
		end)
		Connect(button.MouseLeave, function()
			Tween(button, 0.15, { BackgroundColor3 = Library.Scheme.Element })
		end)
		Connect(UserInputService.InputBegan, function(input)
			if open and input.UserInputType == Enum.UserInputType.MouseButton1 then
				local mp = UserInputService:GetMouseLocation()
				local pp, ps = popup.AbsolutePosition, popup.AbsoluteSize
				local bp, bs = button.AbsolutePosition, button.AbsoluteSize
				local inPopup = mp.X >= pp.X and mp.X <= pp.X + ps.X and mp.Y >= pp.Y and mp.Y <= pp.Y + ps.Y
				local inBtn = mp.X >= bp.X and mp.X <= bp.X + bs.X and mp.Y >= bp.Y and mp.Y <= bp.Y + bs.Y
				if not inPopup and not inBtn then
					dropObj._close()
				end
			end
		end)

		function dropObj:SetValue(v)
			dropObj.Value = v
			Library.Flags[flag] = v
			display()
			for _, ob in ipairs(optButtons) do
				ob._paint()
			end
		end
		function dropObj:SetValues(newValues)
			values = newValues
			rebuild()
			display()
		end
		function dropObj:OnChanged(fn)
			changed:Connect(fn)
			task.spawn(fn, dropObj.Value)
			return dropObj
		end

		Library.Options[flag] = dropObj
		return dropObj
	end

	-- ---- Input ----
	function Groupbox:AddInput(flag, opts)
		opts = opts or {}
		local text = opts.Text or flag
		local numeric = opts.Numeric or false
		local callback = opts.Callback or function() end
		local value = opts.Default or ""
		Library.Flags[flag] = value

		local row = Row(42)
		local label = New("TextLabel", {
			Size = UDim2.new(1, 0, 0, 14),
			BackgroundTransparency = 1,
			Font = Library.Font,
			Text = text,
			TextColor3 = Library.Scheme.SubText,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = row,
		})
		Library:Register(label, "TextColor3", "SubText")

		local box = New("TextBox", {
			Size = UDim2.new(1, 0, 0, 24),
			Position = UDim2.new(0, 0, 0, 16),
			BackgroundColor3 = Library.Scheme.Element,
			Text = value,
			PlaceholderText = opts.Placeholder or "",
			PlaceholderColor3 = Library.Scheme.Placeholder,
			Font = Library.Font,
			TextSize = 13,
			TextColor3 = Library.Scheme.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			ClearTextOnFocus = false,
			Parent = row,
		})
		Corner(6, box)
		Pad(box, 8)
		Library:Register(box, "BackgroundColor3", "Element")
		Library:Register(box, "TextColor3", "Text")
		Library:Register(box, "PlaceholderColor3", "Placeholder")
		local iStroke = Stroke(box, Library.Scheme.Outline, 1, 0)
		Library:Register(iStroke, "Color", "Outline")

		local inputObj = { Value = value, Type = "Input" }
		local changed = MakeSignal()

		Connect(box.Focused, function()
			Tween(iStroke, 0.15, { Color = Library.Scheme.Accent })
		end)
		Connect(box.FocusLost, function()
			Tween(iStroke, 0.15, { Color = Library.Scheme.Outline })
			local t = box.Text
			if numeric then
				t = t:gsub("[^%-%.%d]", "")
				box.Text = t
			end
			inputObj.Value = t
			Library.Flags[flag] = t
			task.spawn(callback, t)
			changed:Fire(t)
		end)

		function inputObj:SetValue(v)
			box.Text = tostring(v)
			inputObj.Value = box.Text
			Library.Flags[flag] = box.Text
		end
		function inputObj:OnChanged(fn)
			changed:Connect(fn)
			return inputObj
		end

		Library.Options[flag] = inputObj
		return inputObj
	end

	-- ---- ColorPicker (standalone row) ----
	function Groupbox:AddColorPicker(flag, opts)
		opts = opts or {}
		local row = Row(22)
		New("TextLabel", {
			Size = UDim2.new(1, -30, 1, 0),
			BackgroundTransparency = 1,
			Font = Library.Font,
			Text = opts.Text or flag,
			TextColor3 = Library.Scheme.SubText,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = row,
		})
		return Library:_ColorPicker(row, flag, opts, 1)
	end

	-- ---- KeyPicker (standalone row) ----
	function Groupbox:AddKeybind(flag, opts)
		opts = opts or {}
		local row = Row(22)
		New("TextLabel", {
			Size = UDim2.new(1, -80, 1, 0),
			BackgroundTransparency = 1,
			Font = Library.Font,
			Text = opts.Text or flag,
			TextColor3 = Library.Scheme.SubText,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = row,
		})
		return Library:_KeyPicker(row, flag, opts, 1)
	end

	return Groupbox
end

-- // Internal KeyPicker builder
function Library:_KeyPicker(parent, flag, opts, order)
	opts = opts or {}
	local key = opts.Default or Enum.KeyCode.E
	local callback = opts.Callback or function() end
	Library.Flags[flag] = key

	local btn = New("TextButton", {
		Size = UDim2.new(0, 46, 0, 18),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		BackgroundColor3 = Library.Scheme.Element,
		Text = tostring(key.Name),
		Font = Library.Font,
		TextSize = 12,
		TextColor3 = Library.Scheme.Text,
		AutoButtonColor = false,
		LayoutOrder = order or 1,
		Parent = parent,
	})
	Corner(4, btn)
	Library:Register(btn, "BackgroundColor3", "Element")
	Library:Register(btn, "TextColor3", "Text")

	local keyObj = { Value = key, Type = "KeyPicker" }
	local changed = MakeSignal()
	local listening = false

	local function setKey(k, fire)
		keyObj.Value = k
		Library.Flags[flag] = k
		btn.Text = tostring(k.Name)
		if fire ~= false then
			task.spawn(callback, k)
			changed:Fire(k)
		end
	end

	Connect(btn.MouseButton1Click, function()
		listening = true
		btn.Text = "..."
		Tween(btn, 0.15, { BackgroundColor3 = Library.Scheme.Accent })
	end)
	Connect(UserInputService.InputBegan, function(input, gpe)
		if listening and input.UserInputType == Enum.UserInputType.Keyboard then
			listening = false
			Tween(btn, 0.15, { BackgroundColor3 = Library.Scheme.Element })
			setKey(input.KeyCode)
		end
	end)

	function keyObj:SetValue(k)
		setKey(k, false)
	end
	function keyObj:OnChanged(fn)
		changed:Connect(fn)
		return keyObj
	end
	function keyObj:OnClick(fn)
		Connect(UserInputService.InputBegan, function(input, gpe)
			if not gpe and input.KeyCode == keyObj.Value then
				task.spawn(fn)
			end
		end)
		return keyObj
	end

	Library.Options[flag] = keyObj
	return keyObj
end

-- // Internal ColorPicker builder
function Library:_ColorPicker(parent, flag, opts, order)
	opts = opts or {}
	local color = opts.Default or Color3.fromRGB(140, 130, 255)
	local callback = opts.Callback or function() end
	Library.Flags[flag] = color

	local swatch = New("TextButton", {
		Size = UDim2.new(0, 26, 0, 16),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		BackgroundColor3 = color,
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = order or 1,
		Parent = parent,
	})
	Corner(4, swatch)
	Stroke(swatch, Library.Scheme.Outline, 1, 0)

	local cpObj = { Value = color, Type = "ColorPicker" }
	local changed = MakeSignal()
	local h, s, v = color:ToHSV()

	local popup = New("Frame", {
		Size = UDim2.new(0, 190, 0, 160),
		BackgroundColor3 = Library.Scheme.Surface,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 70,
		Parent = ScreenGui,
	})
	Corner(6, popup)
	local cpStroke = Stroke(popup, Library.Scheme.Accent, 1, 0)
	cpStroke.ZIndex = 71
	Pad(popup, 8)

	local svBox = New("Frame", {
		Size = UDim2.new(1, 0, 0, 110),
		BackgroundColor3 = Color3.fromHSV(h, 1, 1),
		BorderSizePixel = 0,
		ZIndex = 72,
		Parent = popup,
	})
	Corner(4, svBox)
	local whiteGrad = New("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		ZIndex = 72,
		Parent = svBox,
	})
	Corner(4, whiteGrad)
	New("UIGradient", {
		Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255)),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = whiteGrad,
	})
	local blackGrad = New("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		ZIndex = 73,
		Parent = svBox,
	})
	Corner(4, blackGrad)
	New("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new(Color3.fromRGB(0, 0, 0), Color3.fromRGB(0, 0, 0)),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(1, 0),
		}),
		Parent = blackGrad,
	})
	local svDot = New("Frame", {
		Size = UDim2.new(0, 8, 0, 8),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		ZIndex = 74,
		Parent = svBox,
	})
	Corner(4, svDot)
	Stroke(svDot, Color3.fromRGB(0, 0, 0), 1, 0.5)

	local hueBar = New("Frame", {
		Size = UDim2.new(1, 0, 0, 14),
		Position = UDim2.new(0, 0, 0, 118),
		BorderSizePixel = 0,
		ZIndex = 72,
		Parent = popup,
	})
	Corner(4, hueBar)
	New("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
			ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
			ColorSequenceKeypoint.new(0.34, Color3.fromRGB(0, 255, 0)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
			ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
			ColorSequenceKeypoint.new(0.84, Color3.fromRGB(255, 0, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
		}),
		Parent = hueBar,
	})
	local hueDot = New("Frame", {
		Size = UDim2.new(0, 3, 1, 2),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(h, 0, 0.5, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		ZIndex = 73,
		Parent = hueBar,
	})
	Corner(2, hueDot)

	local hexBox = New("TextBox", {
		Size = UDim2.new(1, 0, 0, 20),
		Position = UDim2.new(0, 0, 0, 138),
		BackgroundColor3 = Library.Scheme.Element,
		Text = "#FFFFFF",
		Font = Library.Font,
		TextSize = 12,
		TextColor3 = Library.Scheme.Text,
		ClearTextOnFocus = false,
		ZIndex = 72,
		Parent = popup,
	})
	Corner(4, hexBox)

	local function toHex(c)
		return string.format("#%02X%02X%02X", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
	end

	local function refresh(fire)
		color = Color3.fromHSV(h, s, v)
		swatch.BackgroundColor3 = color
		svBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
		svDot.Position = UDim2.new(s, 0, 1 - v, 0)
		hueDot.Position = UDim2.new(h, 0, 0.5, 0)
		hexBox.Text = toHex(color)
		cpObj.Value = color
		Library.Flags[flag] = color
		if fire ~= false then
			task.spawn(callback, color)
			changed:Fire(color)
		end
	end
	refresh(false)

	local dragSV, dragHue = false, false
	Connect(svBox.InputBegan, function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			dragSV = true
		end
	end)
	Connect(hueBar.InputBegan, function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			dragHue = true
		end
	end)
	Connect(UserInputService.InputEnded, function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			dragSV = false
			dragHue = false
		end
	end)
	Connect(RunService.RenderStepped, function()
		if dragSV then
			local sx = math.clamp((Mouse.X - svBox.AbsolutePosition.X) / svBox.AbsoluteSize.X, 0, 1)
			local sy = math.clamp((Mouse.Y - svBox.AbsolutePosition.Y) / svBox.AbsoluteSize.Y, 0, 1)
			s = sx
			v = 1 - sy
			refresh()
		elseif dragHue then
			h = math.clamp((Mouse.X - hueBar.AbsolutePosition.X) / hueBar.AbsoluteSize.X, 0, 1)
			refresh()
		end
	end)

	Connect(hexBox.FocusLost, function()
		local ok, c = pcall(function()
			return Color3.fromHex(hexBox.Text)
		end)
		if ok and c then
			h, s, v = c:ToHSV()
			refresh()
		else
			hexBox.Text = toHex(color)
		end
	end)

	local open = false
	local function close()
		if not open then
			return
		end
		open = false
		Tween(popup, 0.15, { Size = UDim2.new(0, 190, 0, 0) })
		task.delay(0.15, function()
			if not open then
				popup.Visible = false
			end
		end)
	end
	Connect(swatch.MouseButton1Click, function()
		if open then
			close()
		else
			open = true
			popup.Visible = true
			popup.Position = UDim2.fromOffset(
				swatch.AbsolutePosition.X - 164,
				swatch.AbsolutePosition.Y + swatch.AbsoluteSize.Y + 6
			)
			popup.Size = UDim2.new(0, 190, 0, 0)
			Tween(popup, 0.2, { Size = UDim2.new(0, 190, 0, 172) })
		end
	end)
	Connect(UserInputService.InputBegan, function(input)
		if open and input.UserInputType == Enum.UserInputType.MouseButton1 then
			local mp = UserInputService:GetMouseLocation()
			local pp, ps = popup.AbsolutePosition, popup.AbsoluteSize
			local sp, ss = swatch.AbsolutePosition, swatch.AbsoluteSize
			local inPopup = mp.X >= pp.X and mp.X <= pp.X + ps.X and mp.Y >= pp.Y and mp.Y <= pp.Y + ps.Y
			local inSwatch = mp.X >= sp.X and mp.X <= sp.X + ss.X and mp.Y >= sp.Y and mp.Y <= sp.Y + ss.Y
			if not inPopup and not inSwatch then
				close()
			end
		end
	end)
	cpObj._close = close

	function cpObj:SetValueRGB(c)
		h, s, v = c:ToHSV()
		refresh(false)
	end
	function cpObj:OnChanged(fn)
		changed:Connect(fn)
		return cpObj
	end

	Library.Options[flag] = cpObj
	return cpObj
end

-- // Minimize / restore the window (animated collapse to topbar)
function Library:Toggle(state)
	for _, w in ipairs(Library.Windows) do
		if w._minimized == nil then
			w._minimized = false
			w._fullSize = w.Root.Size
		end
		local target = state
		if target == nil then
			target = not w._minimized
		end
		w._minimized = target
		if target then
			Tween(w.Root, 0.3, { Size = UDim2.new(w._fullSize.X.Scale, w._fullSize.X.Offset, 0, 42) }, Enum.EasingStyle.Quart)
		else
			Tween(w.Root, 0.3, { Size = w._fullSize }, Enum.EasingStyle.Quart)
		end
	end
end

-- simpler, reliable toggle: fade container visibility
function Library:SetVisible(state)
	Library.Toggled = state
	for _, w in ipairs(Library.Windows) do
		w.Root.Visible = state
	end
end

function Library:Unload()
	Library.Unloaded = true
	for _, c in ipairs(Library.Connections) do
		pcall(function()
			c:Disconnect()
		end)
	end
	Library.Connections = {}
	if Library.OnUnload then
		pcall(Library.OnUnload)
	end
	pcall(function()
		ScreenGui:Destroy()
	end)
end

Connect(UserInputService.InputBegan, function(input, gpe)
	if gpe then
		return
	end
	if input.KeyCode == Library.ToggleKey then
		Library:SetVisible(not Library.Toggled)
	end
end)

-- // Theme control
function Library:SetAccent(color)
	Library.Scheme.Accent = color
	Library:Refresh()
end

function Library:SetThemeKey(key, color)
	if Library.Scheme[key] ~= nil then
		Library.Scheme[key] = color
		Library:Refresh()
	end
end

function Library:SetTheme(tbl)
	for k, v in pairs(tbl) do
		if Library.Scheme[k] ~= nil then
			Library.Scheme[k] = v
		end
	end
	Library:Refresh()
end

-- // Config (save / load flags to disk)
Library.Folder = "VertexUI"

local function ensureFolder()
	pcall(function()
		if isfolder and not isfolder(Library.Folder) then
			makefolder(Library.Folder)
		end
		if isfolder and not isfolder(Library.Folder .. "/configs") then
			makefolder(Library.Folder .. "/configs")
		end
	end)
end

local function serialize(v)
	local t = typeof(v)
	if t == "Color3" then
		return { __t = "c", r = v.R, g = v.G, b = v.B }
	elseif t == "EnumItem" then
		return { __t = "k", n = v.Name }
	elseif t == "table" then
		local out = {}
		for k, val in pairs(v) do
			out[tostring(k)] = serialize(val)
		end
		return { __t = "t", v = out }
	end
	return v
end

local function deserialize(v)
	if typeof(v) == "table" then
		if v.__t == "c" then
			return Color3.new(v.r, v.g, v.b)
		elseif v.__t == "k" then
			return Enum.KeyCode[v.n]
		elseif v.__t == "t" then
			local out = {}
			for k, val in pairs(v.v) do
				out[k] = deserialize(val)
			end
			return out
		end
	end
	return v
end

function Library:SaveConfig(name)
	if not (writefile and isfolder) then
		Library:Notify({ Title = "Config", Text = "File system not supported by executor." })
		return false
	end
	ensureFolder()
	local data = {}
	for flag, val in pairs(Library.Flags) do
		data[flag] = serialize(val)
	end
	local ok, json = pcall(function()
		return HttpService:JSONEncode(data)
	end)
	if not ok then
		return false
	end
	pcall(function()
		writefile(Library.Folder .. "/configs/" .. name .. ".json", json)
	end)
	Library:Notify({ Title = "Config", Text = "Saved config '" .. name .. "'." })
	return true
end

local function applyFlag(flag, val)
	if Library.Toggles[flag] then
		Library.Toggles[flag]:SetValue(val)
	elseif Library.Options[flag] then
		local o = Library.Options[flag]
		if o.Type == "ColorPicker" then
			o:SetValueRGB(val)
		else
			o:SetValue(val)
		end
	else
		Library.Flags[flag] = val
	end
end

function Library:LoadConfig(name)
	if not (readfile and isfile) then
		return false
	end
	local path = Library.Folder .. "/configs/" .. name .. ".json"
	if not isfile(path) then
		Library:Notify({ Title = "Config", Text = "Config '" .. name .. "' not found." })
		return false
	end
	local ok, raw = pcall(function()
		return readfile(path)
	end)
	if not ok then
		return false
	end
	local ok2, data = pcall(function()
		return HttpService:JSONDecode(raw)
	end)
	if not ok2 then
		return false
	end
	for flag, val in pairs(data) do
		pcall(function()
			applyFlag(flag, deserialize(val))
		end)
	end
	Library:Notify({ Title = "Config", Text = "Loaded config '" .. name .. "'." })
	return true
end

function Library:GetConfigs()
	local out = {}
	pcall(function()
		if listfiles and isfolder and isfolder(Library.Folder .. "/configs") then
			for _, f in ipairs(listfiles(Library.Folder .. "/configs")) do
				local nm = f:match("([^/\\]+)%.json$")
				if nm then
					table.insert(out, nm)
				end
			end
		end
	end)
	return out
end

function Library:DeleteConfig(name)
	pcall(function()
		local path = Library.Folder .. "/configs/" .. name .. ".json"
		if delfile and isfile and isfile(path) then
			delfile(path)
		end
	end)
end

-- // Built-in settings tab: theme + config manager + keybind
function Library:AddSettingsTab(window, tabName)
	local tab = window:AddTab(tabName or "Settings", "⚙")

	local themeBox = tab:AddLeftGroupbox("Theme")
	themeBox:AddColorPicker("_ui_accent", {
		Text = "Accent color",
		Default = Library.Scheme.Accent,
		Callback = function(c)
			Library:SetAccent(c)
		end,
	})
	themeBox:AddColorPicker("_ui_bg", {
		Text = "Background",
		Default = Library.Scheme.Background,
		Callback = function(c)
			Library:SetThemeKey("Background", c)
		end,
	})
	themeBox:AddColorPicker("_ui_surface", {
		Text = "Surface",
		Default = Library.Scheme.Surface,
		Callback = function(c)
			Library:SetThemeKey("Surface", c)
		end,
	})
	themeBox:AddColorPicker("_ui_element", {
		Text = "Element",
		Default = Library.Scheme.Element,
		Callback = function(c)
			Library:SetThemeKey("Element", c)
		end,
	})

	local presetBox = themeBox
	presetBox:AddDivider()
	presetBox:AddDropdown("_ui_preset", {
		Text = "Preset",
		Values = { "Vertex", "Midnight", "Crimson", "Emerald", "Mono" },
		Default = "Vertex",
		Callback = function(p)
			Library:ApplyPreset(p)
		end,
	})

	local cfgBox = tab:AddRightGroupbox("Configuration")
	local nameInput = cfgBox:AddInput("_ui_cfgname", { Text = "Config name", Placeholder = "my config" })
	local listDrop = cfgBox:AddDropdown("_ui_cfglist", {
		Text = "Saved configs",
		Values = Library:GetConfigs(),
		Default = nil,
	})
	local function refreshList()
		listDrop:SetValues(Library:GetConfigs())
	end
	cfgBox:AddButton("Create / Save", function()
		local nm = Library.Flags["_ui_cfgname"]
		if nm and nm ~= "" then
			Library:SaveConfig(nm)
			refreshList()
		else
			Library:Notify({ Title = "Config", Text = "Enter a config name first." })
		end
	end)
	cfgBox:AddButton("Load selected", function()
		local sel = Library.Flags["_ui_cfglist"]
		if sel then
			Library:LoadConfig(sel)
		end
	end)
	cfgBox:AddButton("Delete selected", function()
		local sel = Library.Flags["_ui_cfglist"]
		if sel then
			Library:DeleteConfig(sel)
			refreshList()
		end
	end)
	cfgBox:AddButton("Refresh list", refreshList)

	local uiBox = tab:AddRightGroupbox("Interface")
	uiBox:AddKeybind("_ui_togglekey", {
		Text = "Toggle UI key",
		Default = Library.ToggleKey,
		Callback = function(k)
			Library.ToggleKey = k
		end,
	})
	uiBox:AddToggle("_ui_watermark", {
		Text = "Show watermark",
		Default = false,
		Callback = function(state)
			Library:SetWatermarkVisibility(state)
		end,
	})
	uiBox:AddButton("Unload UI", function()
		Library:Unload()
	end)

	return tab
end

-- // Color presets
local Presets = {
	Vertex = { Accent = Color3.fromRGB(140, 130, 255), Background = Color3.fromRGB(17, 17, 23), Surface = Color3.fromRGB(25, 25, 33), Element = Color3.fromRGB(33, 33, 43) },
	Midnight = { Accent = Color3.fromRGB(90, 150, 255), Background = Color3.fromRGB(13, 16, 24), Surface = Color3.fromRGB(19, 23, 33), Element = Color3.fromRGB(27, 32, 45) },
	Crimson = { Accent = Color3.fromRGB(255, 85, 95), Background = Color3.fromRGB(22, 15, 16), Surface = Color3.fromRGB(30, 21, 22), Element = Color3.fromRGB(40, 28, 30) },
	Emerald = { Accent = Color3.fromRGB(70, 220, 150), Background = Color3.fromRGB(14, 20, 17), Surface = Color3.fromRGB(20, 28, 24), Element = Color3.fromRGB(28, 38, 32) },
	Mono = { Accent = Color3.fromRGB(220, 220, 225), Background = Color3.fromRGB(16, 16, 18), Surface = Color3.fromRGB(24, 24, 27), Element = Color3.fromRGB(34, 34, 38) },
}

function Library:ApplyPreset(name)
	local p = Presets[name]
	if p then
		Library:SetTheme(p)
	end
end

return Library
