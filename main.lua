--[[
	Lasers UI Library
	Claude is goated
	Complete Edition — Rayfield Gen2 Feature Parity
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local TextService = game:GetService("TextService")
local Stats = game:GetService("Stats")

-- Executor globals
local setClipboard = setclipboard or toclipboard or writeclipboard or write_clipboard
	or (syn and syn.write_clipboard) or (Clipboard and Clipboard.set)
local getClipboard = getclipboard or (syn and syn.get_clipboard) or (Clipboard and Clipboard.get)
local httpRequest = (syn and syn.request) or (http and http.request) or http_request or request

local HAS_FILE_IO = (type(writefile) == "function") and (type(readfile) == "function")
	and (type(isfile) == "function") and (type(isfolder) == "function")
	and (type(makefolder) == "function") and (type(listfiles) == "function")
	and (type(delfile) == "function")

local SECURE = false
if getgenv then SECURE = getgenv().RAYFIELD_SECURE == true end

-- ===================================================================
-- Theme
-- ===================================================================
local Theme = {
	Background = Color3.fromRGB(16, 16, 16),
	Secondary  = Color3.fromRGB(27, 27, 27),
	Element    = Color3.fromRGB(34, 34, 34),
	ElementHover = Color3.fromRGB(42, 42, 42),
	Off        = Color3.fromRGB(55, 55, 55),
	Stroke     = Color3.fromRGB(171, 171, 171),
	Text       = Color3.fromRGB(255, 255, 255),
	SubText    = Color3.fromRGB(175, 175, 175),
	Warning    = Color3.fromRGB(255, 190, 70),
	Accent     = Color3.fromRGB(100, 160, 255),
	Success    = Color3.fromRGB(90, 210, 130),
	Error      = Color3.fromRGB(255, 95, 95),
}

local THEME_PRESETS = {
	default = {},
	cobalt = {
		Accent = Color3.fromRGB(50,138,220),
		Background = Color3.fromRGB(16,16,16),
		Secondary = Color3.fromRGB(27,27,27),
		Element = Color3.fromRGB(34,34,34),
		ElementHover = Color3.fromRGB(42,42,42),
	},
	ember = {
		Accent = Color3.fromRGB(240,120,50),
		Background = Color3.fromRGB(20,14,10),
		Secondary = Color3.fromRGB(32,22,16),
		Element = Color3.fromRGB(40,28,20),
		ElementHover = Color3.fromRGB(50,36,26),
	},
	amethyst = {
		Accent = Color3.fromRGB(180,120,255),
		Background = Color3.fromRGB(18,12,26),
		Secondary = Color3.fromRGB(28,20,40),
		Element = Color3.fromRGB(36,26,50),
		ElementHover = Color3.fromRGB(46,34,62),
	},
	frost = {
		Accent = Color3.fromRGB(100,200,255),
		Background = Color3.fromRGB(12,18,28),
		Secondary = Color3.fromRGB(20,30,45),
		Element = Color3.fromRGB(26,40,58),
		ElementHover = Color3.fromRGB(34,52,72),
	},
	rose = {
		Accent = Color3.fromRGB(240,100,150),
		Background = Color3.fromRGB(22,12,18),
		Secondary = Color3.fromRGB(34,20,28),
		Element = Color3.fromRGB(44,26,36),
		ElementHover = Color3.fromRGB(56,34,46),
	},
}

local function applyTheme(t)
	for k, v in t do Theme[k] = v end
end

local BUILDER_ICONS = "rbxasset://LuaPackages/Packages/_Index/BuilderIcons/BuilderIcons/BuilderIcons.json"
local FONT_TITLE = Font.new("rbxasset://fonts/families/Jura.json", Enum.FontWeight.Bold)
local FONT_MAIN  = Font.new("rbxasset://fonts/families/Jura.json", Enum.FontWeight.Medium)
local TI    = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TI_S  = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local STROKE_T = 0.83

-- ===================================================================
-- Helpers
-- ===================================================================
local function create(class, props, children)
	local inst = Instance.new(class)
	for k, v in props do
		if k ~= "Parent" then inst[k] = v end
	end
	if children then
		for _, c in children do c.Parent = inst end
	end
	if props.Parent then inst.Parent = props.Parent end
	return inst
end

local function corner(parent, r)
	return create("UICorner", { CornerRadius = UDim.new(0, r or 6), Parent = parent })
end

local function stroke(parent, color, trans, thick)
	return create("UIStroke", {
		Color = color or Theme.Stroke,
		Transparency = trans or 0.5,
		Thickness = thick or 1,
		Parent = parent,
	})
end

local function addShadow(parent, blur, trans)
	local ok, shadow = pcall(function()
		return create("UIShadow", {
			BlurRadius = UDim.new(0, blur or 16),
			Transparency = trans or 0.5,
			Parent = parent,
		})
	end)
	return ok and shadow or nil
end

local function tween(obj, info, props)
	local t = TweenService:Create(obj, info or TI, props)
	t:Play()
	return t
end

local function icon(name, size, filled, color)
	return create("TextLabel", {
		BackgroundTransparency = 1,
		Text = name or "",
		FontFace = Font.new(BUILDER_ICONS, filled and Enum.FontWeight.Bold or Enum.FontWeight.Regular),
		TextColor3 = color or Theme.Text,
		TextScaled = true,
		Size = UDim2.fromOffset(size or 18, size or 18),
	})
end

local function makeDraggable(frame, handle)
	local dragging, dragInput, startPos, startFramePos
	handle.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			startPos = inp.Position
			startFramePos = frame.Position
			inp.Changed:Connect(function()
				if inp.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	handle.InputChanged:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
			dragInput = inp
		end
	end)
	UserInputService.InputChanged:Connect(function(inp)
		if inp == dragInput and dragging then
			local delta = inp.Position - startPos
			frame.Position = UDim2.new(
				startFramePos.X.Scale, startFramePos.X.Offset + delta.X,
				startFramePos.Y.Scale, startFramePos.Y.Offset + delta.Y)
		end
	end)
end

local function bindDrag(region, onUpdate)
	local dragging = false
	local function upd(inp)
		local ap, sz = region.AbsolutePosition, region.AbsoluteSize
		local ax = math.clamp((inp.Position.X - ap.X) / sz.X, 0, 1)
		local ay = math.clamp((inp.Position.Y - ap.Y) / sz.Y, 0, 1)
		onUpdate(ax, ay)
	end
	region.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			dragging = true; upd(inp)
		end
	end)
	region.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	UserInputService.InputChanged:Connect(function(inp)
		if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
			upd(inp)
		end
	end)
end

local function getGuiParent()
	if gethui then return gethui() end
	local ok, cg = pcall(function()
		return (cloneref and cloneref(game:GetService("CoreGui"))) or game:GetService("CoreGui")
	end)
	return ok and cg or game:GetService("CoreGui")
end

local function copyToClipboard(str)
	if not setClipboard then return false end
	return pcall(setClipboard, str)
end

local function openDiscordInvite(code)
	if not httpRequest then return false end
	return pcall(function()
		httpRequest({
			Url = "http://127.0.0.1:6463/rpc?v=1",
			Method = "POST",
			Headers = { ["Content-Type"] = "application/json", Origin = "https://discord.com" },
			Body = HttpService:JSONEncode({
				cmd = "INVITE_BROWSER",
				nonce = HttpService:GenerateGUID(false),
				args = { code = code },
			}),
		})
	end)
end

-- Accepts camelCase and PascalCase keys
local function pick(t, ...)
	for _, k in {...} do
		if t[k] ~= nil then return t[k] end
	end
	return nil
end

-- ===================================================================
-- Tooltip system
-- ===================================================================
local ActiveTooltip = nil

local function showTooltip(target, text)
	if ActiveTooltip then ActiveTooltip:Destroy(); ActiveTooltip = nil end
	if not text or text == "" then return end

	local tip = create("TextLabel", {
		Name = "Tooltip",
		BackgroundColor3 = Theme.Secondary,
		Text = text,
		FontFace = FONT_MAIN,
		TextColor3 = Theme.Text,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.new(0, 0, 0, 0),
		TextTransparency = 1,
		BackgroundTransparency = 1,
		ZIndex = 10000,
		Parent = ScreenGui,
	}, {
		create("UIPadding", {
			PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8),
			PaddingTop = UDim.new(0, 5),  PaddingBottom = UDim.new(0, 5),
		}),
		create("UISizeConstraint", { MaxSize = Vector2.new(220, math.huge) }),
	})
	corner(tip, 5)
	local ts = stroke(tip, Theme.Stroke, 1)

	task.defer(function()
		local ap, sz = target.AbsolutePosition, target.AbsoluteSize
		tip.Position = UDim2.fromOffset(
			math.clamp(ap.X, 4, workspace.CurrentCamera.ViewportSize.X - tip.AbsoluteSize.X - 4),
			ap.Y + sz.Y + 6
		)
		tween(tip, TI, { BackgroundTransparency = 0.05, TextTransparency = 0 })
		tween(ts, TI, { Transparency = STROKE_T })
	end)

	ActiveTooltip = tip
end

local function attachTooltip(target, text)
	if not text or text == "" then return end
	target.MouseEnter:Connect(function() showTooltip(target, text) end)
	target.MouseLeave:Connect(function()
		if ActiveTooltip then
			local tip = ActiveTooltip
			ActiveTooltip = nil
			tween(tip, TI, { BackgroundTransparency = 1, TextTransparency = 1 })
			task.delay(0.2, function() tip:Destroy() end)
		end
	end)
end

-- ===================================================================
-- Serialization
-- ===================================================================
local function serialize(v)
	local t = type(v)
	if t == "Color3" then
		return { __type = "Color3", r = v.R, g = v.G, b = v.B }
	elseif t == "EnumItem" then
		return { __type = "EnumItem", enumType = tostring(v.EnumType), name = v.Name }
	elseif t == "table" then
		local out = {}
		for k, vv in v do out[k] = serialize(vv) end
		return out
	else
		return v
	end
end

local function deserialize(v)
	if type(v) == "table" then
		if v.__type == "Color3" then
			return Color3.new(v.r, v.g, v.b)
		elseif v.__type == "EnumItem" then
			local ok, item = pcall(function()
				local enum = Enum[v.enumType]
				return enum and enum[v.name] or nil
			end)
			return ok and item or nil
		else
			local out = {}
			for k, vv in v do out[k] = deserialize(vv) end
			return out
		end
	else
		return v
	end
end

-- Base64 for export/import
local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local function b64encode(s)
	return ((s:gsub('.', function(c)
		local r, k = "", c:byte()
		for i = 8, 1, -1 do r = r .. (k % 2^i - k % 2^(i-1) > 0 and "1" or "0") end
		return r
	end) .. "0000"):gsub("%d%d%d?%d?%d?%d?", function(x)
		if #x < 6 then return "" end
		local c = 0
		for i = 1, 6 do c = c + (x:sub(i, i) == "1" and 2^(6 - i) or 0) end
		return B64:sub(c + 1, c + 1)
	end) .. ({ "", "==", "=" })[#s % 3 + 1])
end

local function b64decode(s)
	s = s:gsub("[^" .. B64:gsub("%p", "%%%0") .. "=]", "")
	return (s:gsub('.', function(c)
		if c == "=" then return "" end
		local r, k = "", (B64:find(c, 1, true) or 1) - 1
		for i = 6, 1, -1 do r = r .. (k % 2^i - k % 2^(i-1) > 0 and "1" or "0") end
		return r
	end):gsub("%d%d%d?%d?%d?%d?%d?%d?", function(x)
		if #x < 8 then return "" end
		local c = 0
		for i = 1, 8 do c = c + (x:sub(i, i) == "1" and 2^(8 - i) or 0) end
		return string.char(c)
	end))
end

-- ===================================================================
-- Library root
-- ===================================================================
local Library = {}
Library.__index = Library
Library.Flags = {}
Library._registry = {}
Library._theme = "default"
Library._logs = {}
Library._console = nil
Library._watermark = nil
Library._fab = nil
Library._window = nil

local ScreenGui = create("ScreenGui", {
	Name = "LasersUI",
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 999,
})
pcall(function() if syn and syn.protect_gui then syn.protect_gui(ScreenGui) end end)
ScreenGui.Parent = getGuiParent()

function Library:_register(flag, api)
	if not flag then return end
	Library._registry[flag] = api
	local ok, v = pcall(function() return api:Get() end)
	if ok then Library.Flags[flag] = v end
end

-- ===================================================================
-- Localization
-- ===================================================================
local Locale = {
	translations = {},
	locale = nil,
	translator = nil,
}
function Locale:setLocale(id) self.locale = id end
function Locale:t(source)
	if not source or source == "" then return source end
	if self.translator then
		local ok, r = pcall(self.translator, source, self.locale)
		if ok and r ~= nil then return r end
	end
	if self.locale then
		local tbl = self.translations[self.locale]
		if tbl and tbl[source] then return tbl[source] end
		local base = self.locale:match("^(%a+)")
		if base and self.translations[base] and self.translations[base][source] then
			return self.translations[base][source]
		end
	end
	return source
end
function Locale:register(tbl)
	for k, v in tbl do self.translations[k] = v end
end
local function L(s) return Locale:t(s) end

-- ===================================================================
-- Notifications (rich, hover-pauses, click-dismiss)
-- ===================================================================
local NotifHolder = create("Frame", {
	Name = "Notifications",
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -16, 1, -16),
	Size = UDim2.new(0, 300, 1, -32),
	Parent = ScreenGui,
}, {
	create("UIListLayout", {
		Padding = UDim.new(0, 8),
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
})

local NOTIF_TYPES = {
	info    = { color = Theme.Accent,  glyph = "circle-info" },
	success = { color = Theme.Success, glyph = "circle-check" },
	warning = { color = Theme.Warning, glyph = "triangle-exclamation" },
	error   = { color = Theme.Error,   glyph = "circle-xmark" },
}

local notifCount = 0

function Library:Notify(cfg)
	cfg = cfg or {}
	local dur = cfg.Duration or cfg.duration
	if not dur then
		local total = #(cfg.Content or cfg.content or "") + #(cfg.Title or cfg.title or "")
		dur = math.clamp(3 + total / 40, 3, 9)
	end
	local kind = NOTIF_TYPES[cfg.Type or cfg.type or "info"] or NOTIF_TYPES.info

	notifCount += 1
	if notifCount > 6 then
		local oldest = NotifHolder:FindFirstChildWhichIsA("Frame")
		if oldest then oldest:Destroy(); notifCount -= 1 end
	end

	local card = create("Frame", {
		BackgroundColor3 = Theme.Secondary,
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 300, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		ClipsDescendants = true,
		Parent = NotifHolder,
	})
	corner(card, 8)
	local st = stroke(card, Theme.Stroke, 1)

	local accent = create("Frame", {
		BackgroundColor3 = kind.color, BackgroundTransparency = 1,
		Size = UDim2.new(0, 3, 1, 0), BorderSizePixel = 0, Parent = card,
	})

	local content = create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 14, 0, 0), Size = UDim2.new(1, -24, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y, Parent = card,
	}, {
		create("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }),
		create("UIPadding", { PaddingTop = UDim.new(0, 11), PaddingBottom = UDim.new(0, 11) }),
	})

	local header = create("Frame", {
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 16),
		AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 1, Parent = content,
	}, {
		create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 8),
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	local ico = icon(kind.glyph, 14, false, kind.color)
	ico.LayoutOrder = 1; ico.Parent = header; ico.TextTransparency = 1

	local titleLbl = create("TextLabel", {
		BackgroundTransparency = 1, Text = cfg.Title or cfg.title or "Notification", TextTransparency = 1,
		FontFace = FONT_TITLE, TextColor3 = Theme.Text, TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
		Size = UDim2.new(0, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.XY,
		LayoutOrder = 2, Parent = header,
	})
	local body = cfg.Content or cfg.content
	local bodyLbl
	if body then
		bodyLbl = create("TextLabel", {
			BackgroundTransparency = 1, Text = body, TextTransparency = 1,
			FontFace = FONT_MAIN, TextColor3 = Theme.SubText, TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
			Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = 2, Parent = content,
		})
	end

	card.Position = UDim2.new(0, 26, 0, 0)
	tween(card, TI_S, { BackgroundTransparency = 0, Position = UDim2.new(0, 0, 0, 0) })
	tween(st, TI_S, { Transparency = STROKE_T })
	tween(accent, TI_S, { BackgroundTransparency = 0 })
	tween(titleLbl, TI_S, { TextTransparency = 0 })
	tween(ico, TI_S, { TextTransparency = 0 })
	if bodyLbl then tween(bodyLbl, TI_S, { TextTransparency = 0 }) end

	local paused = false
	card.MouseEnter:Connect(function() paused = true end)
	card.MouseLeave:Connect(function() paused = false end)

	local elapsed = 0
	task.spawn(function()
		while elapsed < dur do
			task.wait(0.1)
			if not paused then elapsed += 0.1 end
			if not card.Parent then return end
		end
		tween(card, TI, { BackgroundTransparency = 1, Position = UDim2.new(0, 26, 0, 0) })
		tween(st, TI, { Transparency = 1 })
		tween(accent, TI, { BackgroundTransparency = 1 })
		tween(titleLbl, TI, { TextTransparency = 1 })
		tween(ico, TI, { TextTransparency = 1 })
		if bodyLbl then tween(bodyLbl, TI, { TextTransparency = 1 }) end
		task.wait(0.2)
		card:Destroy()
		notifCount -= 1
	end)

	create("TextButton", {
		Text = "", BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0), ZIndex = 5, Parent = card,
	}).Activated:Connect(function()
		if card.Parent then card:Destroy(); notifCount -= 1 end
	end)

	return card
end

for kind in NOTIF_TYPES do
	Library["Notify" .. kind:sub(1,1):upper() .. kind:sub(2)] = function(_, title, content, duration)
		Library:Notify({ Type = kind, Title = title, Content = content, Duration = duration })
	end
end

-- ===================================================================
-- Toasts (pill notifications, top or bottom)
-- ===================================================================
local ToastTop = create("Frame", {
	Name = "ToastsTop", BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 16),
	Size = UDim2.new(0, 340, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
	Parent = ScreenGui,
}, {
	create("UIListLayout", {
		Padding = UDim.new(0, 8),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
})

local ToastBottom = create("Frame", {
	Name = "ToastsBottom", BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -16),
	Size = UDim2.new(0, 340, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
	Parent = ScreenGui,
}, {
	create("UIListLayout", {
		Padding = UDim.new(0, 8),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
})

function Library:Toast(cfg)
	cfg = cfg or {}
	local pos = cfg.Position or cfg.position or "Top"
	local holder = pos == "Bottom" and ToastBottom or ToastTop
	local dur = cfg.Duration or cfg.duration
	if not dur then
		local total = #(cfg.Title or cfg.title or "") + #(cfg.Subtitle or cfg.subtitle or "")
		dur = math.clamp(3 + total / 40, 3, 9)
	end
	local minW = cfg.MinWidth or cfg.minWidth or 0
	local avatarId = cfg.Avatar or cfg.avatar

	local pill = create("Frame", {
		BackgroundColor3 = Theme.Secondary, BackgroundTransparency = 0.05,
		Size = UDim2.new(0, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.XY,
		BorderSizePixel = 0, Parent = holder,
	}, {
		create("UIPadding", {
			PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 14),
			PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8),
		}),
	})
	corner(pill, 20)
	stroke(pill, Theme.Stroke, STROKE_T)
	addShadow(pill, 12, 0.5)
	create("UISizeConstraint", { MinSize = Vector2.new(minW, 0), MaxSize = Vector2.new(320, math.huge), Parent = pill })
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 8),
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = pill,
	})

	if avatarId then
		create("ImageLabel", {
			BackgroundColor3 = Theme.Element, Size = UDim2.fromOffset(20, 20),
			Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(avatarId) .. "&w=48&h=48",
			BorderSizePixel = 0, LayoutOrder = 1, Parent = pill,
		}, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	elseif cfg.Icon or cfg.icon then
		local i = icon(cfg.Icon or cfg.icon, 16, false, Theme.Accent)
		i.LayoutOrder = 1; i.Parent = pill
	end

	local textCol = create("Frame", {
		BackgroundTransparency = 1, Size = UDim2.new(0, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.XY, LayoutOrder = 2, Parent = pill,
	}, {
		create("UIListLayout", { Padding = UDim.new(0, 1), SortOrder = Enum.SortOrder.LayoutOrder }),
	})

	local title = cfg.Title or cfg.title
	local subtitle = cfg.Subtitle or cfg.subtitle
	local swap = cfg.SubtitleAboveTitle or cfg.subtitleAboveTitle

	if swap and subtitle then
		create("TextLabel", { BackgroundTransparency = 1, Text = subtitle, FontFace = FONT_MAIN, TextColor3 = Theme.SubText, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 0, 14), LayoutOrder = 1, Parent = textCol })
		create("TextLabel", { BackgroundTransparency = 1, Text = title, FontFace = FONT_TITLE, TextColor3 = Theme.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 0, 15), LayoutOrder = 2, Parent = textCol })
	else
		create("TextLabel", { BackgroundTransparency = 1, Text = title, FontFace = FONT_TITLE, TextColor3 = Theme.Text, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 0, 15), LayoutOrder = 1, Parent = textCol })
		if subtitle then
			create("TextLabel", { BackgroundTransparency = 1, Text = subtitle, FontFace = FONT_MAIN, TextColor3 = Theme.SubText, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 0, 14), LayoutOrder = 2, Parent = textCol })
		end
	end

	local fromY = pos == "Bottom" and 20 or -20
	pill.Position = UDim2.new(0, 0, 0, fromY)
	tween(pill, TI_S, { Position = UDim2.new(0, 0, 0, 0) })

	task.delay(dur, function()
		if not pill.Parent then return end
		tween(pill, TI, { BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, fromY) })
		task.wait(0.2)
		pill:Destroy()
	end)

	return pill
end

-- ===================================================================
-- Popups (modal dialogs)
-- ===================================================================
function Library:Popup(cfg)
	cfg = cfg or {}
	local overlay = create("CanvasGroup", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.55,
		BorderSizePixel = 0,
		GroupTransparency = 1,
		ZIndex = 700,
		Parent = ScreenGui,
	})
	tween(overlay, TI_S, { GroupTransparency = 0 })

	local dismissible = cfg.Dismissible ~= false
	local card = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.fromOffset(400, 0), AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Theme.Background, BackgroundTransparency = 0.05,
		BorderSizePixel = 0, ZIndex = 1, Parent = overlay,
	})
	corner(card, 8); stroke(card, Theme.Stroke, 0.5); addShadow(card, 22, 0.45)

	local content = create("Frame", {
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 2, Parent = card,
	}, {
		create("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
		create("UIPadding", {
			PaddingTop = UDim.new(0, 20), PaddingBottom = UDim.new(0, 18),
			PaddingLeft = UDim.new(0, 20), PaddingRight = UDim.new(0, 20),
		}),
	})

	-- Header
	local hdr = create("Frame", {
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 1, Parent = content,
	})
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 8),
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = hdr,
	})
	if cfg.Icon or cfg.icon then
		local i = icon(cfg.Icon or cfg.icon, 20, false, Theme.Accent)
		i.LayoutOrder = 1; i.Parent = hdr
	end
	create("TextLabel", {
		BackgroundTransparency = 1, Text = cfg.Title or cfg.title or "Popup",
		FontFace = FONT_TITLE, TextColor3 = Theme.Text, TextSize = 17,
		TextXAlignment = Enum.TextXAlignment.Left,
		AutomaticSize = Enum.AutomaticSize.XY, LayoutOrder = 2, Parent = hdr,
	})

	if cfg.Subtitle or cfg.subtitle then
		create("TextLabel", {
			BackgroundTransparency = 1, Text = cfg.Subtitle or cfg.subtitle,
			FontFace = FONT_MAIN, TextColor3 = Theme.SubText, TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
			AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0),
			LayoutOrder = 2, Parent = content,
		})
	end

	local body = cfg.Content or cfg.content
	if body then
		create("TextLabel", {
			BackgroundTransparency = 1, Text = body,
			FontFace = FONT_MAIN, TextColor3 = Theme.SubText, TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
			AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0),
			LayoutOrder = 3, Parent = content,
		})
	end

	local boxes = cfg.Boxes or cfg.boxes
	if boxes then
		local boxList = create("Frame", {
			BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 3, Parent = content,
		}, { create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }) })

		for idx, box in boxes do
			local b = create("Frame", {
				BackgroundColor3 = Theme.Element, Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y, BorderSizePixel = 0,
				LayoutOrder = idx, Parent = boxList,
			})
			corner(b, 6); stroke(b, Theme.Stroke, STROKE_T)
			create("UIPadding", {
				PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8),
				PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10),
				Parent = b,
			})
			create("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder, Parent = b })

			local boxHdr = create("Frame", {
				BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 1, Parent = b,
			})
			create("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 6),
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder, Parent = boxHdr,
			})
			if box.icon then
				local i = icon(box.icon, 14, false, Theme.Accent)
				i.LayoutOrder = 1; i.Parent = boxHdr
			end
			create("TextLabel", {
				BackgroundTransparency = 1, Text = box.title or "",
				FontFace = FONT_TITLE, TextColor3 = Theme.Text, TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				AutomaticSize = Enum.AutomaticSize.XY, LayoutOrder = 2, Parent = boxHdr,
			})
			if box.description then
				create("TextLabel", {
					BackgroundTransparency = 1, Text = box.description,
					FontFace = FONT_MAIN, TextColor3 = Theme.SubText, TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
					AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0),
					LayoutOrder = 2, Parent = b,
				})
			end
		end
	end

	-- Footer buttons
	local options = cfg.Options or cfg.options or { { Text = "OK", Style = "primary" } }
	local btnRow = create("Frame", {
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 34),
		LayoutOrder = 4, Parent = content,
	}, {
		create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	local function close()
		tween(overlay, TI, { GroupTransparency = 1 })
		task.wait(0.16)
		overlay:Destroy()
	end

	for _, opt in options do
		local style = opt.Style or opt.style
		local text = opt.Text or opt.text
		local bg = Theme.Element
		if style == "primary" then bg = Theme.Accent
		elseif style == "danger" then bg = Theme.Error end

		local b = create("TextButton", {
			Text = "", AutoButtonColor = false, BackgroundColor3 = bg,
			Size = UDim2.fromOffset(0, 34), AutomaticSize = Enum.AutomaticSize.X,
			BorderSizePixel = 0, Parent = btnRow,
		}, { create("UIPadding", { PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16) }) })
		corner(b, 6)
		stroke(b, style == "primary" and Theme.Accent or (style == "danger" and Theme.Error or Theme.Stroke),
			style and 0.7 or STROKE_T)
		create("TextLabel", {
			BackgroundTransparency = 1, Text = text or "OK",
			FontFace = FONT_MAIN, TextColor3 = Theme.Text, TextSize = 13,
			Size = UDim2.new(1, 0, 1, 0), Parent = b,
		})
		b.Activated:Connect(function()
			local cb = opt.Callback or opt.callback
			if cb then task.spawn(cb) end
			close()
		end)
	end

	local api = {}
	function api:Close() close() end
	api.Instance = overlay

	if dismissible then
		create("TextButton", {
			Text = "", BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0), ZIndex = 0, Parent = overlay,
		}).Activated:Connect(close)
		UserInputService.InputBegan:Connect(function(inp, gp)
			if not gp and inp.KeyCode == Enum.KeyCode.Escape then close() end
		end)
	end

	return api
end

-- Blocking yes/no wrapper
function Library:Confirm(cfg)
	cfg = cfg or {}
	local done, result = false, false
	Library:Popup({
		Title = cfg.Title,
		Content = cfg.Description,
		Icon = cfg.Icon,
		Options = {
			{ Text = cfg.CancelText or "Cancel", Style = "neutral", Callback = function() done = true; result = false end },
			{ Text = cfg.ConfirmText or "Confirm", Style = cfg.Danger and "danger" or "primary", Callback = function() done = true; result = true end },
		},
		Dismissible = true,
	})
	repeat task.wait(0.05) until done
	return result
end

-- ===================================================================
-- Theme / Config dirs
-- ===================================================================
local CONFIG_DIR = "LasersUI/Configs/"
local function ensureConfigDir(folder)
	if not HAS_FILE_IO then return end
	pcall(function()
		if not isfolder("LasersUI") then makefolder("LasersUI") end
		if not isfolder("LasersUI/Configs") then makefolder("LasersUI/Configs") end
		if folder and folder ~= "" and not isfolder(CONFIG_DIR .. folder) then
			makefolder(CONFIG_DIR .. folder)
		end
	end)
end

function Library:SetTheme(name)
	if type(name) == "table" then
		applyTheme(name); Library._theme = "custom"
		return true
	end
	local preset = THEME_PRESETS[name]
	if not preset then
		Library:Notify({ Type = "error", Title = "Theme", Content = "Unknown theme: " .. tostring(name) })
		return false
	end
	applyTheme(THEME_PRESETS["default"])
	applyTheme(preset)
	Library._theme = name
	Library:Notify({ Type = "success", Title = "Theme", Content = "Switched to '" .. name .. "'." })
	return true
end
function Library:GetTheme() return Library._theme end

-- ===================================================================
-- Console / Logging
-- ===================================================================
local LOG_KINDS = {
	info = Theme.Accent, success = Theme.Success,
	warning = Theme.Warning, error = Theme.Error, debug = Theme.SubText,
}

function Library:Log(msg, kind)
	kind = kind or "info"
	local entry = { text = tostring(msg), kind = kind, time = os.date("%H:%M:%S") }
	table.insert(Library._logs, entry)
	if #Library._logs > 500 then table.remove(Library._logs, 1) end
	if Library._console then Library._console:_append(entry) end
	if not SECURE then print(("[LasersUI][%s] %s"):format(kind:upper(), entry.text)) end
end
function Library:ClearLogs()
	Library._logs = {}
	if Library._console then Library._console:_clear() end
end

function Library:OpenConsole()
	if Library._console then Library._console.Instance.Visible = true; return Library._console end

	local win = {}
	local frame = create("CanvasGroup", {
		Name = "Console", AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -16, 1, -400), Size = UDim2.fromOffset(420, 260),
		BackgroundColor3 = Theme.Background, BackgroundTransparency = 0.05,
		BorderSizePixel = 0, ZIndex = 400, Parent = ScreenGui,
	})
	corner(frame, 6); stroke(frame, Theme.Stroke, 0.5); addShadow(frame, 18, 0.5)

	local top = create("Frame", {
		BackgroundColor3 = Theme.Secondary, BackgroundTransparency = 0.05,
		Size = UDim2.new(1, 0, 0, 30), BorderSizePixel = 0, ZIndex = 2, Parent = frame,
	})
	stroke(top, Theme.Stroke, STROKE_T)

	create("TextLabel", {
		BackgroundTransparency = 1, Text = "Console",
		FontFace = FONT_TITLE, TextColor3 = Theme.Text, TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0),
		Size = UDim2.new(0.5, 0, 1, 0), Parent = top,
	})

	local clearBtn = create("TextButton", {
		Text = "", AutoButtonColor = false, BackgroundColor3 = Theme.Element,
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -36, 0.5, 0),
		Size = UDim2.fromOffset(24, 22), BorderSizePixel = 0, Parent = top,
	})
	corner(clearBtn, 5)
	local ci = icon("broom", 12, false, Theme.SubText)
	ci.AnchorPoint = Vector2.new(0.5, 0.5); ci.Position = UDim2.new(0.5, 0, 0.5, 0); ci.Parent = clearBtn

	local closeBtn = create("TextButton", {
		Text = "", AutoButtonColor = false, BackgroundColor3 = Theme.Element,
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.fromOffset(24, 22), BorderSizePixel = 0, Parent = top,
	})
	corner(closeBtn, 5)
	local xi = icon("x", 12, false, Theme.SubText)
	xi.AnchorPoint = Vector2.new(0.5, 0.5); xi.Position = UDim2.new(0.5, 0, 0.5, 0); xi.Parent = closeBtn

	local logScroll = create("ScrollingFrame", {
		BackgroundTransparency = 1, BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 30), Size = UDim2.new(1, 0, 1, -30),
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.Stroke,
		ScrollBarImageTransparency = 0.5, ZIndex = 1, Parent = frame,
	}, {
		create("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }),
		create("UIPadding", {
			PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8),
			PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10),
		}),
	})

	local order = 0
	function win:_append(entry)
		order += 1
		local color = LOG_KINDS[entry.kind] or Theme.Text
		local line = create("Frame", {
			BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = order, Parent = logScroll,
		}, {
			create("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		})
		create("TextLabel", {
			BackgroundTransparency = 1, Text = entry.time,
			FontFace = FONT_MAIN, TextColor3 = Theme.SubText, TextSize = 11,
			Size = UDim2.fromOffset(56, 14), LayoutOrder = 1, Parent = line,
		})
		create("TextLabel", {
			BackgroundTransparency = 1, Text = entry.kind:upper(),
			FontFace = FONT_TITLE, TextColor3 = color, TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.fromOffset(60, 14), LayoutOrder = 2, Parent = line,
		})
		create("TextLabel", {
			BackgroundTransparency = 1, Text = entry.text,
			FontFace = FONT_MAIN, TextColor3 = Theme.Text, TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, -136, 0, 14), LayoutOrder = 3, Parent = line,
		})
		task.defer(function() logScroll.CanvasPosition = Vector2.new(0, logScroll.AbsoluteCanvasSize.Y) end)
	end
	function win:_clear()
		for _, c in logScroll:GetChildren() do
			if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then c:Destroy() end
		end
		order = 0
	end

	local dragging, dragStart, posStart
	top.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true; dragStart = inp.Position; posStart = frame.Position
		end
	end)
	UserInputService.InputChanged:Connect(function(inp)
		if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
			local d = inp.Position - dragStart
			frame.Position = UDim2.new(posStart.X.Scale, posStart.X.Offset + d.X,
				posStart.Y.Scale, posStart.Y.Offset + d.Y)
		end
	end)
	UserInputService.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
	end)

	clearBtn.Activated:Connect(function() Library:ClearLogs() end)
	closeBtn.Activated:Connect(function() frame.Visible = false end)

	win.Instance = frame
	Library._console = win

	for _, e in Library._logs do win:_append(e) end
	return win
end

function Library:CloseConsole()
	if Library._console then Library._console.Instance.Visible = false end
end
function Library:ToggleConsole()
	if Library._console and Library._console.Instance.Visible then
		Library:CloseConsole()
	else
		Library:OpenConsole()
	end
end

-- ===================================================================
-- Config export / import
-- ===================================================================
function Library:ExportConfig()
	local data = {}
	for flag, api in Library._registry do
		local ok, v = pcall(function() return api:Get() end)
		if ok then data[flag] = serialize(v) end
	end
	local ok, encoded = pcall(function() return HttpService:JSONEncode(data) end)
	if not ok then
		Library:Notify({ Type = "error", Title = "Export", Content = "Failed to encode." })
		return nil
	end
	local b64 = b64encode(encoded)
	local copied = copyToClipboard(b64)
	Library:Notify({
		Type = copied and "success" or "warning",
		Title = "Config Export",
		Content = copied and ("Config copied to clipboard (" .. #b64 .. " chars)") or "Clipboard unavailable.",
	})
	return b64
end

function Library:ImportConfig(str)
	if not str or str == "" then
		Library:Notify({ Type = "warning", Title = "Import", Content = "No data provided." })
		return false
	end
	local ok, raw = pcall(b64decode, str)
	if not ok or not raw or raw == "" then
		Library:Notify({ Type = "error", Title = "Import", Content = "Invalid base64." })
		return false
	end
	local ok2, data = pcall(function() return HttpService:JSONDecode(raw) end)
	if not ok2 or type(data) ~= "table" then
		Library:Notify({ Type = "error", Title = "Import", Content = "Corrupt payload." })
		return false
	end
	local applied = 0
	for flag, val in data do
		local api = Library._registry[flag]
		if api and api.Set then
			local decoded = deserialize(val)
			local ok3 = pcall(function() api:Set(decoded) end)
			if ok3 then
				applied += 1
				Library.Flags[flag] = decoded
			end
		end
	end
	Library:Notify({ Type = "success", Title = "Import", Content = "Applied " .. applied .. " values." })
	return true
end

function Library:ImportConfigFromClipboard()
	if not getClipboard then
		Library:Notify({ Type = "error", Title = "Import", Content = "No clipboard getter available." })
		return false
	end
	local ok, data = pcall(getClipboard)
	if not ok or not data or data == "" then
		Library:Notify({ Type = "warning", Title = "Import", Content = "Clipboard empty." })
		return false
	end
	return Library:ImportConfig(data)
end

-- ===================================================================
-- Watermark
-- ===================================================================
function Library:SetWatermark(cfg)
	cfg = cfg or {}
	if Library._watermark then Library._watermark:Destroy(); Library._watermark = nil end
	if cfg.Enabled == false then return end

	local bar = create("Frame", {
		Name = "Watermark", BackgroundColor3 = Theme.Secondary, BackgroundTransparency = 0.1,
		Position = UDim2.new(0, 16, 0, 16), Size = UDim2.new(0, 0, 0, 26),
		AutomaticSize = Enum.AutomaticSize.X, BorderSizePixel = 0, Parent = ScreenGui,
	}, { create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }) })
	corner(bar, 6); stroke(bar, Theme.Stroke, STROKE_T)

	local lbl = create("TextLabel", {
		BackgroundTransparency = 1, Text = cfg.Text or "",
		FontFace = FONT_MAIN, TextColor3 = Theme.Text, TextSize = 13,
		Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, Parent = bar,
	})

	makeDraggable(bar, bar)

	local fps, lastT, frames = 0, os.clock(), 0
	local conn
	if cfg.ShowFPS ~= false then
		conn = RunService.Heartbeat:Connect(function()
			frames += 1
			local now = os.clock()
			if now - lastT >= 1 then fps = frames; frames = 0; lastT = now end
			local parts = { fps .. " fps" }
			if cfg.ShowPing ~= false then
				local ping = 0
				pcall(function()
					ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
				end)
				table.insert(parts, ping .. " ms")
			end
			if cfg.Text and cfg.Text ~= "" then table.insert(parts, cfg.Text) end
			lbl.Text = table.concat(parts, "  |  ")
		end)
	else
		lbl.Text = cfg.Text or ""
	end

	local api = {}
	function api:SetText(t) cfg.Text = t; if not conn then lbl.Text = t end end
	function api:Destroy()
		if conn then conn:Disconnect() end
		bar:Destroy()
		Library._watermark = nil
	end
	api.Instance = bar
	Library._watermark = api
	return api
end

-- ===================================================================
-- Key System
-- ===================================================================
function Library:KeySystem(cfg)
	cfg = cfg or {}

	local plainKey = cfg.Key or cfg.key
	local keyURL = cfg.URL or cfg.url
	local getKeyURL = cfg.GetKeyURL or cfg.getKeyURL
	local saveKey = cfg.SaveKey ~= false
	local fileName = cfg.FileName or cfg.fileName or "lasers_key.txt"
	local title = cfg.Title or cfg.title or "Authentication Required"
	local desc = cfg.Description or cfg.description or "Enter your key to unlock the interface."
	local placeholder = cfg.Placeholder or cfg.placeholder or "Enter key..."
	local submitText = cfg.SubmitText or cfg.submitText or "Submit"
	local onSuccess = cfg.OnSuccess or cfg.onSuccess
	local onFail = cfg.OnFail or cfg.onFail

	if not plainKey and not keyURL then
		if not SECURE then warn("[LasersUI] KeySystem requires a 'Key' or 'URL'") end
		return nil
	end

	Library._key = nil

	local function trim(s) return (tostring(s):gsub("^%s+", ""):gsub("%s+$", "")) end

	local function fetchExpected()
		if plainKey then return plainKey end
		local ok, res = pcall(function()
			if httpRequest then
				local r = httpRequest({ Url = keyURL, Method = "GET" })
				return r and (r.Body or r.body)
			end
			return game:HttpGet(keyURL)
		end)
		if ok and type(res) == "string" and res ~= "" then return trim(res) end
		return nil
	end

	local function validate(input)
		if not input or input == "" then return false, "Please enter a key." end
		local expected = fetchExpected()
		if not expected then return false, "Could not fetch the valid key." end
		if trim(input) == expected then return true end
		return false, "Invalid key. Please try again."
	end

	local function loadSaved()
		if not saveKey or not HAS_FILE_IO then return nil end
		local ok, data = pcall(function()
			if isfile(fileName) then return readfile(fileName) end
		end)
		if ok and type(data) == "string" and data ~= "" then return data end
		return nil
	end
	local function saveValue(v)
		if not saveKey or not HAS_FILE_IO then return end
		pcall(function() writefile(fileName, v) end)
	end

	local saved = loadSaved()
	if saved and validate(saved) then
		Library._key = saved
		if onSuccess then task.spawn(onSuccess, saved) end
		return saved
	end

	local overlay = create("CanvasGroup", {
		Name = "KeySystem", Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.5,
		BorderSizePixel = 0, GroupTransparency = 1, ZIndex = 500, Parent = ScreenGui,
	})
	tween(overlay, TI_S, { GroupTransparency = 0 })
	create("TextButton", {
		Text = "", AutoButtonColor = false,
		Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, ZIndex = 0, Parent = overlay,
	})

	local card = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.fromOffset(380, 0), AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Theme.Background, BackgroundTransparency = 0.05,
		BorderSizePixel = 0, ZIndex = 1, Parent = overlay,
	})
	corner(card, 8); stroke(card, Theme.Stroke, 0.5); addShadow(card, 24, 0.4)

	local content = create("Frame", {
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 2, Parent = card,
	}, {
		create("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
		create("UIPadding", {
			PaddingTop = UDim.new(0, 22), PaddingBottom = UDim.new(0, 22),
			PaddingLeft = UDim.new(0, 22), PaddingRight = UDim.new(0, 22),
		}),
	})

	local header = create("Frame", {
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 26),
		LayoutOrder = 1, Parent = content,
	})
	local lockIcon = icon("lock", 20, false, Theme.Accent)
	lockIcon.AnchorPoint = Vector2.new(0, 0.5)
	lockIcon.Position = UDim2.new(0, 0, 0.5, 0)
	lockIcon.Parent = header
	create("TextLabel", {
		BackgroundTransparency = 1, Text = title,
		FontFace = FONT_TITLE, TextColor3 = Theme.Text, TextSize = 17,
		TextXAlignment = Enum.TextXAlignment.Left,
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 30, 0.5, 0),
		Size = UDim2.new(1, -30, 1, 0), Parent = header,
	})

	create("TextLabel", {
		BackgroundTransparency = 1, Text = desc,
		FontFace = FONT_MAIN, TextColor3 = Theme.SubText, TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
		AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0),
		LayoutOrder = 2, Parent = content,
	})

	local boxWrap = create("Frame", {
		BackgroundColor3 = Theme.Secondary, Size = UDim2.new(1, 0, 0, 36),
		BorderSizePixel = 0, LayoutOrder = 3, Parent = content,
	}, { create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }) })
	corner(boxWrap, 6)
	local boxStroke = stroke(boxWrap, Theme.Stroke, STROKE_T)

	local tb = create("TextBox", {
		BackgroundTransparency = 1, Text = "",
		PlaceholderText = placeholder, PlaceholderColor3 = Theme.SubText,
		FontFace = FONT_MAIN, TextColor3 = Theme.Text, TextSize = 14,
		ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.new(1, 0, 1, 0), Parent = boxWrap,
	})

	local status = create("TextLabel", {
		BackgroundTransparency = 1, Text = "",
		FontFace = FONT_MAIN, TextColor3 = Theme.SubText, TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
		AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0),
		LayoutOrder = 4, Parent = content,
	})

	local btnRow = create("Frame", {
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 36),
		LayoutOrder = 5, Parent = content,
	}, {
		create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	local function actionBtn(text, primary, order)
		local btn = create("TextButton", {
			Text = "", AutoButtonColor = false,
			BackgroundColor3 = primary and Theme.Accent or Theme.Element,
			Size = UDim2.fromOffset(0, 36), AutomaticSize = Enum.AutomaticSize.X,
			LayoutOrder = order, BorderSizePixel = 0, Parent = btnRow,
		}, { create("UIPadding", { PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16) }) })
		corner(btn, 6)
		stroke(btn, primary and Theme.Accent or Theme.Stroke, primary and 0.7 or STROKE_T)
		local lbl = create("TextLabel", {
			BackgroundTransparency = 1, Text = text,
			FontFace = FONT_MAIN, TextColor3 = Theme.Text, TextSize = 13,
			Size = UDim2.new(1, 0, 1, 0), Parent = btn,
		})
		if not primary then
			btn.MouseEnter:Connect(function() tween(btn, TI, { BackgroundColor3 = Theme.ElementHover }) end)
			btn.MouseLeave:Connect(function() tween(btn, TI, { BackgroundColor3 = Theme.Element }) end)
		end
		return btn, lbl
	end

	if getKeyURL then
		local getBtn = actionBtn("Get Key", false, 1)
		getBtn.Activated:Connect(function()
			local copied = copyToClipboard(getKeyURL)
			Library:Notify({
				Type = "info", Title = "Get Key",
				Content = copied and "Link copied to clipboard" or ("Clipboard unavailable: " .. getKeyURL),
				Duration = 3,
			})
		end)
	end

	local submitBtn, submitLbl = actionBtn(submitText, true, 2)

	tb.Focused:Connect(function() tween(boxStroke, TI, { Color = Theme.Accent, Transparency = 0.2 }) end)
	tb.FocusLost:Connect(function() tween(boxStroke, TI, { Color = Theme.Stroke, Transparency = STROKE_T }) end)

	local validating = false
	local function attemptSubmit()
		if validating then return end
		local input = tb.Text
		if not input or input == "" then
			status.Text = "Please enter a key."
			status.TextColor3 = Theme.Warning
			return
		end
		validating = true
		status.Text = "Validating..."
		status.TextColor3 = Theme.SubText
		submitLbl.Text = "Checking..."

		task.spawn(function()
			local ok, err = validate(input)
			if ok then
				status.Text = "Success! Loading..."
				status.TextColor3 = Theme.Success
				saveValue(trim(input))
				Library._key = trim(input)
				task.wait(0.35)
				if onSuccess then task.spawn(onSuccess, Library._key) end
				tween(overlay, TI, { GroupTransparency = 1 })
				task.wait(0.18)
				overlay:Destroy()
			else
				validating = false
				submitLbl.Text = submitText
				status.Text = err or "Invalid key."
				status.TextColor3 = Theme.Error
				tween(boxStroke, TI, { Color = Theme.Error, Transparency = 0.2 })
				if onFail then task.spawn(onFail, input) end
			end
		end)
	end

	submitBtn.Activated:Connect(attemptSubmit)
	tb.FocusLost:Connect(function(enterPressed)
		if enterPressed then attemptSubmit() end
	end)

	repeat task.wait(0.05) until Library._key ~= nil
	return Library._key
end

-- ===================================================================
-- Window
-- ===================================================================
function Library:CreateWindow(cfg)
	cfg = cfg or {}

	local wName = pick(cfg, "name", "Name") or "Lib Name"
	local wSubtitle = pick(cfg, "subtitle", "Subtitle")
	local wIcon = pick(cfg, "icon", "Icon")
	local wTheme = pick(cfg, "theme", "Theme")
	local wSidebar = pick(cfg, "sidebarLayout", "SidebarLayout") or false
	local wPlayerName = pick(cfg, "playerName", "PlayerName")
	local wConfig = pick(cfg, "configuration", "Configuration")
	local wLocale = pick(cfg, "locale", "Locale")
	local wTranslations = pick(cfg, "translations", "Translations")
	local wTranslator = pick(cfg, "translator", "Translator")
	local wToggleKey = pick(cfg, "toggleKey", "ToggleKey") or Enum.KeyCode.RightShift
	local wShowUserInfo = pick(cfg, "showUserInfo", "ShowUserInfo") ~= false

	if wTheme then
		if type(wTheme) == "table" then
			applyTheme(wTheme); Library._theme = "custom"
		elseif THEME_PRESETS[wTheme] then
			applyTheme(THEME_PRESETS["default"]); applyTheme(THEME_PRESETS[wTheme]); Library._theme = wTheme
		end
	end
	if wLocale then Locale:setLocale(wLocale) end
	if wTranslations then Locale:register(wTranslations) end
	if wTranslator then Locale.translator = wTranslator end

	local configCfg = wConfig or {}
	local configAutoSave = pick(configCfg, "autoSave", "AutoSave") or false
	local configAutoLoad = pick(configCfg, "autoLoad", "AutoLoad") or false
	local configFileName = pick(configCfg, "fileName", "FileName") or "default"
	local configFolder = pick(configCfg, "customFolder", "CustomFolder")
	local configEnabled = wConfig and true or false

	local Window = {
		Tabs = {}, _current = nil, Flags = Library.Flags,
		_configFolder = configFolder, _configFileName = configFileName,
		_configEnabled = configEnabled,
	}
	Library._window = Window

	local wW, wH = wSidebar and 640 or 532, wSidebar and 420 or 410

	local BG = create("CanvasGroup", {
		Name = "Window", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.fromOffset(wW, wH), BackgroundColor3 = Theme.Background,
		BackgroundTransparency = 0.05, BorderSizePixel = 0, Parent = ScreenGui,
	})
	corner(BG, 6); stroke(BG, Theme.Stroke, 0.5); addShadow(BG, 20, 0.5)

	local TopBar = create("Frame", {
		Name = "TopBar", BackgroundColor3 = Theme.Secondary, BackgroundTransparency = 0.05,
		Size = UDim2.new(1, 0, 0, 45), BorderSizePixel = 0, ZIndex = 5, Parent = BG,
	})
	stroke(TopBar, Theme.Stroke, STROKE_T); addShadow(TopBar, 10, 0.86)

	-- Title group
	local titleGroup = create("Frame", {
		BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 14, 0.5, 0), Size = UDim2.new(1, -260, 1, 0), Parent = TopBar,
	})
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 8),
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder, Parent = titleGroup,
	})
	if wIcon then
		local i = icon(tostring(wIcon), 18, false, Theme.Text)
		i.LayoutOrder = 1; i.Parent = titleGroup
	end
	local textCol = create("Frame", {
		BackgroundTransparency = 1, Size = UDim2.new(0, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.XY, LayoutOrder = 2, Parent = titleGroup,
	})
	create("UIListLayout", { Padding = UDim.new(0, 0), SortOrder = Enum.SortOrder.LayoutOrder, Parent = textCol })

	local TitleLbl = create("TextLabel", {
		Name = "Title", BackgroundTransparency = 1, Text = wName,
		FontFace = FONT_TITLE, TextColor3 = Theme.Text, TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 0, 20),
		LayoutOrder = 1, Parent = textCol,
	})
	local SubLbl
	if wSubtitle then
		SubLbl = create("TextLabel", {
			BackgroundTransparency = 1, Text = wSubtitle,
			FontFace = FONT_MAIN, TextColor3 = Theme.SubText, TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
			AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 0, 14),
			LayoutOrder = 2, Parent = textCol,
		})
	end

	-- User info panel
	if wShowUserInfo then
		local lp = Players.LocalPlayer
		if lp then
			local info = create("Frame", {
				Name = "UserInfo", BackgroundColor3 = Theme.Element, BackgroundTransparency = 0.4,
				AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 220, 0.5, 0),
				Size = UDim2.fromOffset(0, 26), AutomaticSize = Enum.AutomaticSize.X,
				BorderSizePixel = 0, ZIndex = 6, Parent = TopBar,
			}, { create("UIPadding", { PaddingLeft = UDim.new(0, 3), PaddingRight = UDim.new(0, 10) }) })
			corner(info, 13); stroke(info, Theme.Stroke, STROKE_T)

			local av = create("ImageLabel", {
				BackgroundColor3 = Theme.Secondary, BackgroundTransparency = 0.3,
				AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
				Size = UDim2.fromOffset(20, 20),
				Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(lp.UserId) .. "&w=48&h=48",
				BorderSizePixel = 0, ZIndex = 7, Parent = info,
			})
			corner(av, 10)

			create("TextLabel", {
				BackgroundTransparency = 1, Text = lp.DisplayName or lp.Name,
				FontFace = FONT_MAIN, TextColor3 = Theme.Text, TextSize = 11,
				TextXAlignment = Enum.TextXAlignment.Left,
				AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 26, 0.5, 0),
				Size = UDim2.fromOffset(0, 14), AutomaticSize = Enum.AutomaticSize.X,
				Parent = info,
			})
		end
	end

	local function ctrlBtn(iconName, offsetX, hoverColor)
		local b = create("TextButton", {
			Text = "", AutoButtonColor = false, BackgroundColor3 = Theme.Element,
			BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, offsetX, 0.5, 0), Size = UDim2.fromOffset(26, 26),
			Parent = TopBar,
		})
		corner(b, 6)
		local ic = icon(iconName, 16, false, Theme.SubText)
		ic.AnchorPoint = Vector2.new(0.5, 0.5); ic.Position = UDim2.new(0.5, 0, 0.5, 0); ic.Parent = b
		b.MouseEnter:Connect(function()
			tween(b, TI, { BackgroundTransparency = 0 })
			tween(ic, TI, { TextColor3 = hoverColor or Theme.Text })
		end)
		b.MouseLeave:Connect(function()
			tween(b, TI, { BackgroundTransparency = 1 })
			tween(ic, TI, { TextColor3 = Theme.SubText })
		end)
		return b
	end

	local CloseBtn = ctrlBtn("x", -10, Theme.Error)
	local MinBtn   = ctrlBtn("minus", -42, Theme.Text)
	local YtBtn    = ctrlBtn("youtube", -74, Color3.fromRGB(255, 60, 60))
	local DcBtn    = ctrlBtn("discord", -106, Color3.fromRGB(88, 101, 242))

	local YT_LINK = "https://youtube.com/@lasers"
	local DC_LINK = "https://discord.gg/lasers"
	local DC_CODE = "lasers"

	YtBtn.Activated:Connect(function()
		local copied = copyToClipboard(YT_LINK)
		Library:Notify({
			Type = "info", Title = "YouTube",
			Content = copied and "Channel link copied to clipboard" or "Clipboard unavailable: " .. YT_LINK,
			Duration = 3,
		})
	end)

	DcBtn.Activated:Connect(function()
		local copied = copyToClipboard(DC_LINK)
		local opened = openDiscordInvite(DC_CODE)
		local msg
		if opened and copied then msg = "Opening invite - link also copied"
		elseif opened then msg = "Opening invite in Discord"
		elseif copied then msg = "Invite link copied to clipboard"
		else msg = "Clipboard unavailable: " .. DC_LINK end
		Library:Notify({ Type = "info", Title = "Discord", Content = msg, Duration = 3 })
	end)

	-- Body
	local Body = create("Frame", {
		Name = "Body", BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 45), Size = UDim2.new(1, 0, 1, -45),
		Parent = BG,
	})

	-- Tab strip
	local TabList, Content
	if wSidebar then
		TabList = create("ScrollingFrame", {
			Name = "TabList", BackgroundColor3 = Theme.Secondary, BackgroundTransparency = 0.2,
			BorderSizePixel = 0, Size = UDim2.new(0, 170, 1, 0), CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 3,
			ScrollBarImageColor3 = Theme.Stroke, ScrollBarImageTransparency = 0.5, Parent = Body,
		}, {
			create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
			create("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }),
		})
		Content = create("Frame", {
			Name = "Content", BackgroundTransparency = 1,
			Position = UDim2.new(0, 171, 0, 0), Size = UDim2.new(1, -171, 1, 0), Parent = Body,
		})
		create("Frame", {
			Name = "SideDivider", BackgroundColor3 = Theme.Stroke, BackgroundTransparency = STROKE_T,
			BorderSizePixel = 0, Position = UDim2.new(0, 170, 0, 0), Size = UDim2.new(0, 1, 1, 0),
			ZIndex = 2, Parent = Body,
		})
		if wPlayerName then
			create("TextLabel", {
				Name = "PlayerLine", BackgroundTransparency = 1, Text = wPlayerName,
				FontFace = FONT_MAIN, TextColor3 = Theme.SubText, TextSize = 11,
				TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
				AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 10, 1, -6),
				Size = UDim2.new(0, 150, 0, 14), Parent = TabList,
			})
		end
	else
		TabList = create("Frame", {
			Name = "TabList", BackgroundColor3 = Theme.Secondary, BackgroundTransparency = 0.2,
			BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 34), Parent = Body,
		}, {
			create("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 4),
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }),
		})
		Content = create("Frame", {
			Name = "Content", BackgroundTransparency = 1,
			Position = UDim2.new(0, 0, 0, 35), Size = UDim2.new(1, 0, 1, -35), Parent = Body,
		})
	end

	-- Tags holder
	local TagHolder = create("Frame", {
		Name = "Tags", BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -140, 0.5, 0),
		Size = UDim2.new(0, 120, 0, 24), Parent = TopBar,
	}, {
		create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 4),
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	makeDraggable(BG, TopBar)

	-- Resize handle
	local resize = create("TextButton", {
		Name = "ResizeHandle", Text = "", AutoButtonColor = false,
		BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -2, 1, -2), Size = UDim2.fromOffset(16, 16),
		ZIndex = 20, Parent = BG,
	})
	local resizeIcon = icon("up-right-and-down-left-from-center", 11, false, Theme.Stroke)
	resizeIcon.AnchorPoint = Vector2.new(0.5, 0.5); resizeIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
	resizeIcon.TextTransparency = 0.4; resizeIcon.Parent = resize

	local resizing, resizeStart, sizeStart
	resize.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then
			resizing = true; resizeStart = inp.Position; sizeStart = BG.AbsoluteSize
		end
	end)
	UserInputService.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then resizing = false end
	end)
	UserInputService.InputChanged:Connect(function(inp)
		if resizing and inp.UserInputType == Enum.UserInputType.MouseMovement then
			local d = inp.Position - resizeStart
			local w = math.clamp(sizeStart.X + d.X, 420, 1200)
			local h = math.clamp(sizeStart.Y + d.Y, 260, 900)
			BG.Size = UDim2.fromOffset(w, h)
		end
	end)
	resize.MouseEnter:Connect(function() tween(resizeIcon, TI, { TextTransparency = 0 }) end)
	resize.MouseLeave:Connect(function() tween(resizeIcon, TI, { TextTransparency = 0.4 }) end)

	-- Close/minimize
	local function closeWindow()
		tween(BG, TI, { GroupTransparency = 1, Size = UDim2.fromOffset(BG.AbsoluteSize.X, 0) })
		task.wait(0.18)
		ScreenGui:Destroy()
	end
	CloseBtn.Activated:Connect(closeWindow)
	function Window:Destroy() closeWindow() end
	function Window:Unload() closeWindow() end

	local minimized = false
	MinBtn.Activated:Connect(function()
		minimized = not minimized
		if minimized then
			Body.Visible = false
			tween(BG, TI_S, { Size = UDim2.fromOffset(BG.AbsoluteSize.X, 45) })
		else
			tween(BG, TI_S, { Size = UDim2.fromOffset(BG.AbsoluteSize.X, BG.AbsoluteSize.Y) })
			task.wait(0.12)
			Body.Visible = true
		end
	end)

	local hidden = false
	UserInputService.InputBegan:Connect(function(inp, gp)
		if gp then return end
		if inp.KeyCode == wToggleKey then
			hidden = not hidden
			BG.Visible = not hidden
		end
	end)

	-- Title/subtitle/icon updates
	function Window:SetTitle(t) TitleLbl.Text = t end
	function Window:SetSubtitle(t)
		if SubLbl then SubLbl.Text = t
		else SubLbl = create("TextLabel", {
			BackgroundTransparency = 1, Text = t,
			FontFace = FONT_MAIN, TextColor3 = Theme.SubText, TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
			AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 0, 14),
			LayoutOrder = 2, Parent = textCol,
		}) end
	end
	function Window:SetPlayerName(t)
		local p = TabList:FindFirstChild("PlayerLine")
		if p then p.Text = t end
	end

	-- Visibility
	function Window:Show() BG.Visible = true end
	function Window:Hide() BG.Visible = false end
	function Window:Toggle() BG.Visible = not BG.Visible; return BG.Visible end
	function Window:Collapse()
		Body.Visible = false
		tween(BG, TI_S, { Size = UDim2.fromOffset(BG.AbsoluteSize.X, 45) })
	end
	function Window:Expand()
		tween(BG, TI_S, { Size = UDim2.fromOffset(BG.AbsoluteSize.X, BG.AbsoluteSize.Y) })
		task.wait(0.12)
		Body.Visible = true
	end
	function Window:Resize(w, h) tween(BG, TI_S, { Size = UDim2.fromOffset(w, h) }) end
	function Window:SetVisibility(v) BG.Visible = v and true or false end
	function Window:SelectTab(t)
		if type(t) == "string" then
			for _, tab in Window.Tabs do
				if tab.Name == t then tab:Select(); return end
			end
		elseif t then
			t:Select()
		end
	end

	-- Theme / Locale
	function Window:ChangeTheme(t)
		if type(t) == "table" then
			applyTheme(t); Library._theme = "custom"
		elseif THEME_PRESETS[t] then
			applyTheme(THEME_PRESETS["default"]); applyTheme(THEME_PRESETS[t]); Library._theme = t
		end
	end
	function Window:SetLocale(id) Locale:setLocale(id) end
	function Window:RegisterTranslations(tbl) Locale:register(tbl) end
	function Window:SetTranslator(fn) Locale.translator = fn end

	-- Tags
	function Window:CreateTag(tcfg)
		tcfg = tcfg or {}
		local text = pick(tcfg, "text", "Text", "title", "Title") or ""
		local color = pick(tcfg, "color", "Color") or Theme.Accent
		local ic = pick(tcfg, "icon", "Icon")
		local order = pick(tcfg, "order", "Order") or 1

		local pill = create("Frame", {
			BackgroundColor3 = color, Size = UDim2.new(0, 0, 0, 20),
			AutomaticSize = Enum.AutomaticSize.X, BorderSizePixel = 0,
			LayoutOrder = order, Parent = TagHolder,
		}, { create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }) })
		corner(pill, 10)
		create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 4),
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder, Parent = pill,
		})
		local iconEl
		if ic then
			iconEl = icon(tostring(ic), 12, false, Theme.Text)
			iconEl.LayoutOrder = 1; iconEl.Parent = pill
		end
		local lbl = create("TextLabel", {
			BackgroundTransparency = 1, Text = text,
			FontFace = FONT_MAIN, TextColor3 = Theme.Text, TextSize = 11,
			AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 1, 0),
			LayoutOrder = 2, Parent = pill,
		})

		local api = {}
		function api:Set(props)
			props = props or {}
			local t = pick(props, "text", "Text", "title", "Title")
			local c = pick(props, "color", "Color")
			local i = pick(props, "icon", "Icon")
			if t then lbl.Text = t end
			if c then tween(pill, TI, { BackgroundColor3 = c }) end
			if i and iconEl then iconEl.Text = tostring(i) end
		end
		api.Instance = pill
		return api
	end

	-- Window-level sections (sidebar headings)
	function Window:CreateSection(scfg)
		scfg = scfg or {}
		if not wSidebar then return { Instance = nil } end
		local row = create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 20), Parent = TabList })
		local lbl = create("TextLabel", {
			BackgroundTransparency = 1,
			Text = string.upper(L(pick(scfg, "name", "Name") or "Section")),
			FontFace = FONT_TITLE, TextColor3 = Theme.SubText, TextSize = 10,
			TextXAlignment = Enum.TextXAlignment.Left,
			AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 2, 1, -2),
			Size = UDim2.new(1, -4, 0, 12), Parent = row,
		})
		local api = {}
		function api:Remove() row:Destroy() end
		api.Instance = row
		return api
	end

	-- ===============================================================
	-- Tabs
	-- ===============================================================
	function Window:CreateTab(tcfg)
		tcfg = tcfg or {}
		local tName = pick(tcfg, "name", "Name") or "Tab"
		local tIcon = pick(tcfg, "icon", "Icon")
		local Tab = { _order = 0, _badge = 0, Name = tName }

		local btn, ic, nameLbl
		if wSidebar then
			btn = create("TextButton", {
				Text = "", AutoButtonColor = false, BackgroundColor3 = Theme.Element,
				BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 34), Parent = TabList,
			})
			corner(btn, 6)
			ic = icon(tIcon and tostring(tIcon) or "circle", 18, false, Theme.SubText)
			ic.AnchorPoint = Vector2.new(0, 0.5); ic.Position = UDim2.new(0, 8, 0.5, 0); ic.Parent = btn
			nameLbl = create("TextLabel", {
				BackgroundTransparency = 1, Text = L(tName),
				FontFace = FONT_MAIN, TextColor3 = Theme.SubText, TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
				AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 34, 0.5, 0),
				Size = UDim2.new(1, -66, 1, 0), Parent = btn,
			})
		else
			btn = create("TextButton", {
				Text = "", AutoButtonColor = false, BackgroundColor3 = Theme.Element,
				BackgroundTransparency = 1, Size = UDim2.fromOffset(0, 26),
				AutomaticSize = Enum.AutomaticSize.X, Parent = TabList,
			}, { create("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }) })
			corner(btn, 13)
			create("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 6),
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder, Parent = btn,
			})
			ic = icon(tIcon and tostring(tIcon) or "circle", 14, false, Theme.SubText)
			ic.LayoutOrder = 1; ic.Parent = btn
			nameLbl = create("TextLabel", {
				BackgroundTransparency = 1, Text = L(tName),
				FontFace = FONT_MAIN, TextColor3 = Theme.SubText, TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 1, 0),
				LayoutOrder = 2, Parent = btn,
			})
		end

		-- Badge
		local badge = create("Frame", {
			BackgroundColor3 = Theme.Error, AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(0, 18),
			AutomaticSize = Enum.AutomaticSize.X, BorderSizePixel = 0,
			Visible = false, ZIndex = 3, Parent = btn,
		}, { create("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }) })
		corner(badge, 9)
		local badgeLbl = create("TextLabel", {
			BackgroundTransparency = 1, Text = "0",
			FontFace = FONT_MAIN, TextColor3 = Theme.Text, TextSize = 11,
			Size = UDim2.new(1, 0, 1, 0), Parent = badge,
		})
		function Tab:SetBadge(n)
			Tab._badge = tonumber(n) or 0
			if Tab._badge <= 0 then badge.Visible = false
			else badgeLbl.Text = tostring(Tab._badge); badge.Visible = true end
		end
		function Tab:ClearBadge() Tab:SetBadge(0) end
		function Tab:GetBadge() return Tab._badge end

		local pageWrap = create("CanvasGroup", {
			Name = "Page", BackgroundTransparency = 1, BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 1, 0), Visible = false,
			GroupTransparency = 0, Parent = Content,
		})
		local page = create("ScrollingFrame", {
			BackgroundTransparency = 1, BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 1, 0), CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 3,
			ScrollBarImageColor3 = Theme.Stroke, ScrollBarImageTransparency = 0.5,
			Parent = pageWrap,
		}, {
			create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
			create("UIPadding", {
				PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12),
				PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12),
			}),
		})

		local function select()
			if Window._current == Tab then return end
			for _, t in Window.Tabs do
				if t ~= Tab then t._wrap.Visible = false end
				tween(t._btn, TI, { BackgroundTransparency = 1 })
				tween(t._icon, TI, { TextColor3 = Theme.SubText })
				tween(t._name, TI, { TextColor3 = Theme.SubText })
			end
			Window._current = Tab
			pageWrap.Visible = true
			pageWrap.GroupTransparency = 1
			pageWrap.Position = UDim2.new(0.04, 0, 0, 0)
			tween(pageWrap, TI_S, { GroupTransparency = 0, Position = UDim2.new(0, 0, 0, 0) })
			tween(btn, TI, { BackgroundTransparency = 0 })
			tween(ic, TI, { TextColor3 = Theme.Accent })
			tween(nameLbl, TI, { TextColor3 = Theme.Text })
		end

		btn.MouseEnter:Connect(function()
			if not pageWrap.Visible then tween(btn, TI, { BackgroundTransparency = 0.6 }) end
		end)
		btn.MouseLeave:Connect(function()
			if not pageWrap.Visible then tween(btn, TI, { BackgroundTransparency = 1 }) end
		end)
		btn.Activated:Connect(select)

		Tab._btn, Tab._icon, Tab._name, Tab._page, Tab._wrap, Tab._select = btn, ic, nameLbl, page, pageWrap, select
		table.insert(Window.Tabs, Tab)
		if #Window.Tabs == 1 then select() end

		function Tab:Select(noAnim)
			if noAnim then
				pageWrap.GroupTransparency = 0
				pageWrap.Position = UDim2.new(0, 0, 0, 0)
				pageWrap.Visible = true
			end
			select()
		end
		function Tab:Deselect()
			pageWrap.Visible = false
			tween(btn, TI, { BackgroundTransparency = 1 })
			tween(ic, TI, { TextColor3 = Theme.SubText })
			tween(nameLbl, TI, { TextColor3 = Theme.SubText })
		end
		function Tab:Remove()
			btn:Destroy(); pageWrap:Destroy()
			for i, t in Window.Tabs do if t == Tab then table.remove(Window.Tabs, i); break end end
		end

		-- Row factory
		local function newRow(height)
			Tab._order += 1
			local row = create("Frame", {
				BackgroundColor3 = Theme.Element, Size = UDim2.new(1, 0, 0, height or 34),
				LayoutOrder = Tab._order, BorderSizePixel = 0, Parent = page,
			})
			corner(row, 6); stroke(row, Theme.Stroke, STROKE_T)
			return row
		end

		-- Common wrapper: description, lock, reorder
		local function attachCommon(api, row, elemCfg, interactive)
			if elemCfg then
				local desc = pick(elemCfg, "description", "Description")
				if desc then
					local descLbl = create("TextLabel", {
						BackgroundTransparency = 1, Text = desc,
						FontFace = FONT_MAIN, TextColor3 = Theme.SubText, TextSize = 11,
						TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
						AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, -20, 0, 0),
						Position = UDim2.new(0, 10, 1, 2), Parent = row,
					})
					row.Size = UDim2.new(1, 0, 0, row.AbsoluteSize.Y + 14)
					api._descLbl = descLbl
					api._descText = desc
				end
			end
			if interactive then
				local locked = false
				function api:Lock(reason)
					locked = true
					if api._dim then api._dim:Destroy() end
					api._dim = create("Frame", {
						BackgroundColor3 = Color3.new(0,0,0), BackgroundTransparency = 0.55,
						Size = UDim2.new(1,0,1,0), BorderSizePixel = 0, ZIndex = 10, Parent = row,
					})
					corner(api._dim, 6)
					api._dim.Active = true
					if reason and api._descLbl then api._descLbl.Text = reason end
				end
				function api:Unlock()
					locked = false
					if api._dim then api._dim:Destroy(); api._dim = nil end
					if api._descLbl then api._descLbl.Text = api._descText or "" end
				end
				function api:IsLocked() return locked end
				api._locked = function() return locked end
			end
			function api:MoveTo(index)
				local ordered = {}
				for _, c in page:GetChildren() do
					if c:IsA("GuiObject") and c.LayoutOrder > 0 then table.insert(ordered, c) end
				end
				table.sort(ordered, function(a, b) return a.LayoutOrder < b.LayoutOrder end)
				for i, c in ordered do c.LayoutOrder = i end
				row.LayoutOrder = index
				local ordered2 = {}
				for _, c in page:GetChildren() do
					if c:IsA("GuiObject") and c.LayoutOrder > 0 then table.insert(ordered2, c) end
				end
				table.sort(ordered2, function(a, b) return a.LayoutOrder < b.LayoutOrder end)
				for i, c in ordered2 do c.LayoutOrder = i end
			end
			function api:MoveToTop() api:MoveTo(1) end
			function api:MoveToBottom()
				local max = 0
				for _, c in page:GetChildren() do
					if c:IsA("GuiObject") then max = math.max(max, c.LayoutOrder) end
				end
				api:MoveTo(max)
			end
			function api:MoveUp() row.LayoutOrder = math.max(1, row.LayoutOrder - 1) end
			function api:MoveDown() row.LayoutOrder = row.LayoutOrder + 1 end
			return api
		end

		-- 1. Label --------------------------------------------------
		function Tab:CreateLabel(text)
			Tab._order += 1
			local row = create("Frame", {
				BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = Tab._order,
				BorderSizePixel = 0, Parent = page,
			})
			local lbl = create("TextLabel", {
				BackgroundTransparency = 1, Text = text or "Label",
				FontFace = FONT_MAIN, TextColor3 = Theme.SubText, TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
				AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, -8, 0, 0),
				Position = UDim2.new(0, 4, 0, 0), Parent = row,
			})
			create("UIPadding", { PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 3), Parent = row })
			local api = { Set = function(_, t) lbl.Text = t end, Instance = row }
			attachCommon(api, row, nil, false)
			return api
		end

		-- 2. Warning ------------------------------------------------
		function Tab:CreateWarning(text)
			local row = newRow(0)
			row.AutomaticSize = Enum.AutomaticSize.Y
			row.BackgroundColor3 = Color3.fromRGB(40, 34, 20)
			for _, s in row:GetChildren() do
				if s:IsA("UIStroke") then s.Color = Theme.Warning; s.Transparency = 0.5 end
			end
			create("UIPadding", {
				PaddingTop = UDim.new(0, 9), PaddingBottom = UDim.new(0, 9),
				PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = row,
			})
			local ico = icon("triangle-exclamation", 18, false, Theme.Warning)
			ico.AnchorPoint = Vector2.new(0, 0.5); ico.Position = UDim2.new(0, 0, 0.5, 0); ico.Parent = row
			local lbl = create("TextLabel", {
				BackgroundTransparency = 1, Text = text or "Warning",
				FontFace = FONT_MAIN, TextColor3 = Theme.Warning, TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center,
				TextWrapped = true, AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.new(1, -28, 0, 0), Position = UDim2.new(0, 28, 0, 0), Parent = row,
			})
			local api = { Set = function(_, t) lbl.Text = t end, Instance = row }
			attachCommon(api, row, nil, false)
			return api
		end

		-- 3. Button -------------------------------------------------
		function Tab:CreateButton(bcfg)
			bcfg = bcfg or {}
			Tab._order += 1
			local row = create("TextButton", {
				Text = "", AutoButtonColor = false, BackgroundColor3 = Theme.Element,
				Size = UDim2.new(1, 0, 0, 36), LayoutOrder = Tab._order,
				BorderSizePixel = 0, Parent = page,
			})
			corner(row, 6); stroke(row, Theme.Stroke, STROKE_T)
			create("TextLabel", {
				BackgroundTransparency = 1, Text = L(pick(bcfg, "name", "Name") or "Button"),
				FontFace = FONT_MAIN, TextColor3 = Theme.Text, TextSize = 14,
				Size = UDim2.new(1, 0, 1, 0), Parent = row,
			})
			row.MouseEnter:Connect(function() tween(row, TI, { BackgroundColor3 = Theme.ElementHover }) end)
			row.MouseLeave:Connect(function() tween(row, TI, { BackgroundColor3 = Theme.Element }) end)
			local api = { Instance = row }
			attachCommon(api, row, bcfg, true)
			row.Activated:Connect(function()
				if api._locked and api._locked() then return end
				tween(row, TI, { BackgroundColor3 = Theme.Accent })
				task.wait(0.12)
				tween(row, TI, { BackgroundColor3 = Theme.Element })
				local cb = pick(bcfg, "callback", "Callback")
				if cb then task.spawn(cb) end
			end)
			local tip = pick(bcfg, "description", "Description")
			if tip then attachTooltip(row, tip) end
			return api
		end

		-- 4. Toggle -------------------------------------------------
		function Tab:CreateToggle(tocfg)
			tocfg = tocfg or {}
			local state = pick(tocfg, "value", "Value", "default", "Default") or false
			local row = newRow(36)
			local btnEl = create("TextButton", {
				Text = "", BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 1, 0), Parent = row,
			})
			create("TextLabel", {
				BackgroundTransparency = 1, Text = L(pick(tocfg, "name", "Name") or "Toggle"),
				FontFace = FONT_MAIN, TextColor3 = Theme.Text, TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left, AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.new(1, -70, 1, 0), Parent = btnEl,
			})
			local track = create("Frame", {
				BackgroundColor3 = state and Theme.Accent or Theme.Off,
				AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0),
				Size = UDim2.fromOffset(40, 20), BorderSizePixel = 0, Parent = btnEl,
			})
			corner(track, 10)
			local knob = create("Frame", {
				BackgroundColor3 = Theme.Text, AnchorPoint = Vector2.new(0, 0.5),
				Position = state and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
				Size = UDim2.fromOffset(16, 16), BorderSizePixel = 0, Parent = track,
			})
			corner(knob, 8)

			local api = {}
			function api:Set(v, silent)
				state = v and true or false
				tween(track, TI, { BackgroundColor3 = state and Theme.Accent or Theme.Off })
				tween(knob, TI, { Position = state and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0) })
				if not silent then
					local cb = pick(tocfg, "callback", "Callback")
					if cb then task.spawn(cb, state) end
				end
				local flag = pick(tocfg, "flag", "Flag")
				if flag then Library.Flags[flag] = state end
			end
			function api:Get() return state end
			btnEl.Activated:Connect(function()
				if api._locked and api._locked() then return end
				api:Set(not state)
			end)
			local flag = pick(tocfg, "flag", "Flag")
			local cb = pick(tocfg, "callback", "Callback")
			if state and cb and not pick(tocfg, "forgetState", "ForgetState") then task.spawn(cb, true) end
			api.Instance = row
			attachCommon(api, row, tocfg, true)
			if not pick(tocfg, "forgetState", "ForgetState") then
				Library:_register(flag or pick(tocfg, "name", "Name"), api)
			end
			return api
		end
		Tab.CreateSwitch = Tab.CreateToggle

		-- 5. Slider -------------------------------------------------
		function Tab:CreateSlider(slcfg)
			slcfg = slcfg or {}
			local range = pick(slcfg, "range", "Range") or { pick(slcfg, "min", "Min") or 0, pick(slcfg, "max", "Max") or 100 }
			local min, max = range[1], range[2]
			local inc = pick(slcfg, "increment", "Increment") or 1
			local value = math.clamp(pick(slcfg, "value", "Value", "default", "Default") or min, min, max)
			local suffix = pick(slcfg, "suffix", "Suffix") or ""
			local hideLabel = pick(slcfg, "hideLabel", "HideLabel") or false
			local row = newRow(hideLabel and 24 or 50)

			if not hideLabel then
				create("TextLabel", {
					BackgroundTransparency = 1, Text = L(pick(slcfg, "name", "Name") or "Slider"),
					FontFace = FONT_MAIN, TextColor3 = Theme.Text, TextSize = 14,
					TextXAlignment = Enum.TextXAlignment.Left,
					Position = UDim2.new(0, 10, 0, 6), Size = UDim2.new(1, -70, 0, 16), Parent = row,
				})
			end
			local valLbl = create("TextLabel", {
				BackgroundTransparency = 1, Text = tostring(value) .. suffix,
				FontFace = FONT_TITLE, TextColor3 = Theme.Accent, TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -10, 0, 6), Size = UDim2.new(0, 60, 0, 16), Parent = row,
			})
			local trackY = hideLabel and UDim2.new(0, 10, 0.5, 0) or UDim2.new(0, 10, 1, -14)
			local track = create("Frame", {
				BackgroundColor3 = Theme.Off, AnchorPoint = Vector2.new(0, 0.5),
				Position = trackY, Size = UDim2.new(1, -20, 0, 6),
				BorderSizePixel = 0, Parent = row,
			})
			corner(track, 3)
			local fill = create("Frame", {
				BackgroundColor3 = Theme.Accent,
				Size = UDim2.new((value - min) / math.max(max - min, 1e-6), 0, 1, 0),
				BorderSizePixel = 0, Parent = track,
			})
			corner(fill, 3)
			local knob = create("Frame", {
				BackgroundColor3 = Theme.Text, AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new((value - min) / math.max(max - min, 1e-6), 0, 0.5, 0),
				Size = UDim2.fromOffset(14, 14), BorderSizePixel = 0, ZIndex = 2, Parent = track,
			})
			corner(knob, 7)

			local api = {}
			local cb = pick(slcfg, "callback", "Callback")
			local function apply(alpha, fire, dragging)
				local raw = min + (max - min) * alpha
				value = math.clamp(math.floor(raw / inc + 0.5) * inc, min, max)
				local a = (max - min) == 0 and 0 or (value - min) / (max - min)
				fill.Size = UDim2.new(a, 0, 1, 0)
				knob.Position = UDim2.new(a, 0, 0.5, 0)
				valLbl.Text = tostring(value) .. suffix
				if fire and cb then task.spawn(cb, value, dragging) end
				local flag = pick(slcfg, "flag", "Flag")
				if flag then Library.Flags[flag] = value end
			end
			local wasDragging = false
			bindDrag(track, function(ax) wasDragging = true; apply(ax, true, true) end)
			UserInputService.InputEnded:Connect(function(inp)
				if inp.UserInputType == Enum.UserInputType.MouseButton1 and wasDragging then
					wasDragging = false
					apply((value - min) / math.max(max - min, 1e-6), true, false)
				end
			end)
			function api:Set(v, silent)
				apply((math.clamp(v, min, max) - min) / math.max(max - min, 1e-6), not silent)
			end
			function api:Get() return value end
			api.Instance = row
			attachCommon(api, row, slcfg, true)
			local flag = pick(slcfg, "flag", "Flag")
			if not pick(slcfg, "forgetState", "ForgetState") then
				Library:_register(flag or pick(slcfg, "name", "Name"), api)
			end
			return api
		end

		-- 6. Dropdown ----------------------------------------------
		function Tab:CreateDropdown(dcfg)
			dcfg = dcfg or {}
			local options = pick(dcfg, "options", "Options") or {}
			local multi = pick(dcfg, "multiSelect", "MultiSelect", "multi", "Multi") or false
			local placeholder = pick(dcfg, "placeholder", "Placeholder") or "None"
			local selected = {}
			local default = pick(dcfg, "value", "Value", "default", "Default")
			if default then
				if type(default) == "table" then
					for _, d in default do selected[d] = true end
				else selected[default] = true end
			end

			local row = newRow(36)
			row.ClipsDescendants = true
			local header = create("TextButton", {
				Text = "", BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 36), Parent = row,
			})
			create("TextLabel", {
				BackgroundTransparency = 1, Text = L(pick(dcfg, "name", "Name") or "Dropdown"),
				FontFace = FONT_MAIN, TextColor3 = Theme.Text, TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left, AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.new(0.5, 0, 1, 0), Parent = header,
			})
			local valLbl = create("TextLabel", {
				BackgroundTransparency = 1, Text = "",
				FontFace = FONT_MAIN, TextColor3 = Theme.SubText, TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd,
				AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -32, 0.5, 0),
				Size = UDim2.new(0.5, -8, 1, 0), Parent = header,
			})
			local chev = icon("chevron-down", 16, false, Theme.SubText)
			chev.AnchorPoint = Vector2.new(1, 0.5)
			chev.Position = UDim2.new(1, -10, 0.5, 0)
			chev.Parent = header

			local list = create("Frame", {
				BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 36),
				Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
				Visible = false, Parent = row,
			}, {
				create("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }),
				create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8) }),
			})

			-- Filter box
			local searchWrap = create("Frame", {
				BackgroundColor3 = Theme.Secondary,
				Size = UDim2.new(1, -16, 0, 26), Position = UDim2.new(0, 8, 0, 36),
				BorderSizePixel = 0, Visible = false, Parent = row,
			}, { create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }) })
			corner(searchWrap, 5); stroke(searchWrap, Theme.Stroke, STROKE_T)
			local searchBox = create("TextBox", {
				BackgroundTransparency = 1, Text = "", PlaceholderText = "Filter...",
				PlaceholderColor3 = Theme.SubText, FontFace = FONT_MAIN, TextColor3 = Theme.Text,
				TextSize = 12, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left,
				Size = UDim2.new(1, 0, 1, 0), Parent = searchWrap,
			})

			local function updateValLabel()
				local picked = {}
				for _, o in options do if selected[o] then table.insert(picked, o) end end
				valLbl.Text = #picked == 0 and placeholder or table.concat(picked, ", ")
			end

			local api = {}
			local optionBtns = {}
			local function rebuild(filter)
				for _, b in optionBtns do b.btn:Destroy() end
				table.clear(optionBtns)
				local filterText = filter and filter:lower() or ""
				for i, opt in options do
					if filterText == "" or tostring(opt):lower():find(filterText, 1, true) then
						local ob = create("TextButton", {
							Text = "", AutoButtonColor = false, BackgroundColor3 = Theme.Secondary,
							Size = UDim2.new(1, 0, 0, 28), LayoutOrder = i,
							BorderSizePixel = 0, Parent = list,
						})
						corner(ob, 5)
						local txt = create("TextLabel", {
							BackgroundTransparency = 1, Text = tostring(opt), FontFace = FONT_MAIN,
							TextColor3 = selected[opt] and Theme.Accent or Theme.SubText, TextSize = 13,
							TextXAlignment = Enum.TextXAlignment.Left,
							Position = UDim2.new(0, 8, 0, 0), Size = UDim2.new(1, -30, 1, 0), Parent = ob,
						})
						local check = icon("check", 14, false, Theme.Accent)
						check.AnchorPoint = Vector2.new(1, 0.5)
						check.Position = UDim2.new(1, -8, 0.5, 0)
						check.Visible = selected[opt] == true
						check.Parent = ob

						ob.MouseEnter:Connect(function() tween(ob, TI, { BackgroundColor3 = Theme.ElementHover }) end)
						ob.MouseLeave:Connect(function() tween(ob, TI, { BackgroundColor3 = Theme.Secondary }) end)
						ob.Activated:Connect(function()
							if multi then selected[opt] = not selected[opt]
							else table.clear(selected); selected[opt] = true end
							for _, b in optionBtns do
								local on = selected[b.opt] == true
								b.check.Visible = on
								tween(b.txt, TI, { TextColor3 = on and Theme.Accent or Theme.SubText })
							end
							updateValLabel()
							local fireVal
							if multi then
								fireVal = {}
								for _, o in options do if selected[o] then table.insert(fireVal, o) end end
							else fireVal = opt end
							local flag = pick(dcfg, "flag", "Flag")
							if flag then Library.Flags[flag] = fireVal end
							local cb = pick(dcfg, "callback", "Callback")
							if cb then task.spawn(cb, fireVal) end
							if not multi then task.wait(0.05); api._toggle(false) end
						end)
						table.insert(optionBtns, { btn = ob, opt = opt, txt = txt, check = check })
					end
				end
				updateValLabel()
			end

			local function openHeight()
				local n = #optionBtns
				if n == 0 then return 44 end
				return 36 + 30 + (n * 28) + ((n - 1) * 2) + 8
			end

			local open = false
			function api._toggle(force)
				if force ~= nil then open = force else open = not open end
				if open then
					list.Visible = true; searchWrap.Visible = true
					searchBox.Text = ""; rebuild()
				end
				tween(row, TI_S, { Size = UDim2.new(1, 0, 0, open and openHeight() or 36) })
				tween(chev, TI, { Rotation = open and 180 or 0 })
				if not open then
					task.delay(0.12, function()
						if not open then list.Visible = false; searchWrap.Visible = false end
					end)
				end
			end
			header.Activated:Connect(function()
				if api._locked and api._locked() then return end
				api._toggle()
			end)
			searchBox:GetPropertyChangedSignal("Text"):Connect(function() rebuild(searchBox.Text) end)

			function api:Refresh(newOpts) options = newOpts or options; rebuild(); if open then api._toggle(true) end end
			function api:Add(opt) table.insert(options, opt); rebuild() end
			function api:Remove(opt)
				for i, o in options do if o == opt then table.remove(options, i); break end end
				selected[opt] = nil
				rebuild()
			end
			function api:Set(val, silent)
				table.clear(selected)
				if type(val) == "table" then
					for _, x in val do selected[x] = true end
				elseif val ~= nil then selected[val] = true end
				rebuild()
				local flag = pick(dcfg, "flag", "Flag")
				if flag then Library.Flags[flag] = val end
				if not silent then
					local cb = pick(dcfg, "callback", "Callback")
					if cb then task.spawn(cb, val) end
				end
			end
			function api:Get()
				local out = {}
				for _, o in options do if selected[o] then table.insert(out, o) end end
				return multi and out or out[1]
			end
			api.Instance = row
			rebuild()
			attachCommon(api, row, dcfg, true)
			local flag = pick(dcfg, "flag", "Flag")
			if not pick(dcfg, "forgetState", "ForgetState") then
				Library:_register(flag or pick(dcfg, "name", "Name"), api)
			end
			return api
		end

		-- 7. Input -------------------------------------------------
		function Tab:CreateInput(txcfg)
			txcfg = txcfg or {}
			local numeric = pick(txcfg, "numeric", "Numeric") or false
			local clearOnFocus = pick(txcfg, "clearOnFocus", "ClearOnFocus") or false
			local row = newRow(36)
			create("TextLabel", {
				BackgroundTransparency = 1, Text = L(pick(txcfg, "name", "Name") or "Input"),
				FontFace = FONT_MAIN, TextColor3 = Theme.Text, TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left, AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.new(0.4, -10, 1, 0), Parent = row,
			})
			local boxWrap = create("Frame", {
				BackgroundColor3 = Theme.Secondary, AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.new(0, 0, 0, 24),
				AutomaticSize = Enum.AutomaticSize.X, ClipsDescendants = true,
				BorderSizePixel = 0, Parent = row,
			}, { create("UIPadding", { PaddingLeft = UDim.new(0, 7), PaddingRight = UDim.new(0, 7) }) })
			corner(boxWrap, 5)
			local tbStroke = stroke(boxWrap, Theme.Stroke, STROKE_T)
			local tb = create("TextBox", {
				BackgroundTransparency = 1,
				Text = pick(txcfg, "value", "Value", "default", "Default") or "",
				PlaceholderText = pick(txcfg, "placeholder", "Placeholder") or "...",
				PlaceholderColor3 = Theme.SubText,
				FontFace = FONT_MAIN, TextColor3 = Theme.Text, TextSize = 13,
				ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left,
				AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 1, 0), Parent = boxWrap,
			}, {
				create("UISizeConstraint", {
					MinSize = Vector2.new(pick(txcfg, "minWidth", "MinWidth") or 56, 0),
					MaxSize = Vector2.new(pick(txcfg, "maxWidth", "MaxWidth") or 180, math.huge),
				}),
			})
			tb.Focused:Connect(function()
				if clearOnFocus then tb.Text = "" end
				tween(tbStroke, TI, { Color = Theme.Accent, Transparency = 0.2 })
			end)
			local lastGood = tb.Text
			tb.FocusLost:Connect(function()
				tween(tbStroke, TI, { Color = Theme.Stroke, Transparency = STROKE_T })
				if numeric then
					local n = tonumber(tb.Text)
					if n then tb.Text = tostring(n); lastGood = tb.Text
					else tb.Text = lastGood end
				end
				local cb = pick(txcfg, "callback", "Callback")
				if cb then task.spawn(cb, tb.Text) end
				local flag = pick(txcfg, "flag", "Flag")
				if flag then Library.Flags[flag] = tb.Text end
			end)
			local api = {}
			function api:Set(t, silent)
				tb.Text = tostring(t)
				if not silent then
					local cb = pick(txcfg, "callback", "Callback")
					if cb then task.spawn(cb, tb.Text) end
				end
				local flag = pick(txcfg, "flag", "Flag")
				if flag then Library.Flags[flag] = tb.Text end
			end
			function api:Get() return tb.Text end
			api.Instance = row
			attachCommon(api, row, txcfg, true)
			local flag = pick(txcfg, "flag", "Flag")
			if not pick(txcfg, "forgetState", "ForgetState") then
				Library:_register(flag or pick(txcfg, "name", "Name"), api)
			end
			return api
		end
		Tab.CreateTextbox = Tab.CreateInput

		-- 8. Keybind ------------------------------------------------
		function Tab:CreateKeybind(kcfg)
			kcfg = kcfg or {}
			local bind = pick(kcfg, "value", "Value", "default", "Default") or Enum.KeyCode.Unknown
			local holdMode = pick(kcfg, "hold", "Hold") or false
			local holdDuration = pick(kcfg, "holdDuration", "HoldDuration") or 0.5
			local listening = false
			local row = newRow(36)

			create("TextLabel", {
				BackgroundTransparency = 1, Text = L(pick(kcfg, "name", "Name") or "Keybind"),
				FontFace = FONT_MAIN, TextColor3 = Theme.Text, TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left, AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.new(1, -110, 1, 0), Parent = row,
			})
			local keyBtn = create("TextButton", {
				Text = "", AutoButtonColor = false, BackgroundColor3 = Theme.Secondary,
				AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0),
				Size = UDim2.fromOffset(90, 24), BorderSizePixel = 0, Parent = row,
			})
			corner(keyBtn, 5)
			local kStroke = stroke(keyBtn, Theme.Stroke, STROKE_T)
			local keyLbl = create("TextLabel", {
				BackgroundTransparency = 1,
				Text = bind == Enum.KeyCode.Unknown and "None" or bind.Name,
				FontFace = FONT_MAIN, TextColor3 = Theme.SubText, TextSize = 13,
				Size = UDim2.new(1, 0, 1, 0), Parent = keyBtn,
			})

			local api = {}
			local rebindConn
			local holdActive = false

			local function stopListening()
				listening = false
				tween(kStroke, TI, { Color = Theme.Stroke, Transparency = STROKE_T })
				if rebindConn then rebindConn:Disconnect(); rebindConn = nil end
			end
			function api:Set(kc, silent)
				bind = kc or Enum.KeyCode.Unknown
				keyLbl.Text = bind == Enum.KeyCode.Unknown and "None" or bind.Name
				if not silent then
					local cb = pick(kcfg, "onChanged", "OnChanged", "callback", "Callback")
					if cb then task.spawn(cb, bind) end
				end
				local flag = pick(kcfg, "flag", "Flag")
				if flag then Library.Flags[flag] = bind end
			end
			function api:Get() return bind end

			keyBtn.Activated:Connect(function()
				if api._locked and api._locked() then return end
				if listening then stopListening(); return end
				listening = true
				keyLbl.Text = "..."
				tween(kStroke, TI, { Color = Theme.Accent, Transparency = 0.2 })
				rebindConn = UserInputService.InputBegan:Connect(function(inp, gp)
					if gp then return end
					if inp.UserInputType == Enum.UserInputType.Keyboard then
						if inp.KeyCode == Enum.KeyCode.Backspace then
							api:Set(Enum.KeyCode.Unknown); stopListening()
						elseif inp.KeyCode == Enum.KeyCode.Escape then
							stopListening()
						else
							api:Set(inp.KeyCode); stopListening()
						end
					elseif inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.MouseButton2 then
						api:Set(inp.UserInputType); stopListening()
					end
				end)
			end)

			UserInputService.InputBegan:Connect(function(inp, gp)
				if gp or listening then return end
				local press = pick(kcfg, "callback", "Callback") or pick(kcfg, "onPress", "OnPress")
				if not press then return end
				if bind ~= Enum.KeyCode.Unknown and inp.KeyCode == bind then
					if holdMode then
						if not holdActive then
							holdActive = true
							task.spawn(function()
								task.wait(holdDuration)
								if holdActive then task.spawn(press, true) end
							end)
						end
					else
						task.spawn(press, bind)
					end
				end
			end)
			UserInputService.InputEnded:Connect(function(inp)
				if holdMode and holdActive and bind ~= Enum.KeyCode.Unknown and inp.KeyCode == bind then
					holdActive = false
					local press = pick(kcfg, "callback", "Callback") or pick(kcfg, "onPress", "OnPress")
					if press then task.spawn(press, false) end
				end
			end)

			api.Instance = row
			attachCommon(api, row, kcfg, true)
			local flag = pick(kcfg, "flag", "Flag")
			if not pick(kcfg, "forgetState", "ForgetState") then
				Library:_register(flag or pick(kcfg, "name", "Name"), api)
			end
			return api
		end

		-- 9. Color Picker (with alpha) -----------------------------
		function Tab:CreateColorPicker(ccfg)
			ccfg = ccfg or {}
			local color = pick(ccfg, "color", "Color", "default", "Default") or Color3.fromRGB(255, 0, 0)
			local alpha = pick(ccfg, "alpha", "Alpha") or 1
			local h, s, v = color:ToHSV()

			local row = newRow(36)
			row.ClipsDescendants = true
			local header = create("TextButton", {
				Text = "", BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 36), Parent = row,
			})
			create("TextLabel", {
				BackgroundTransparency = 1, Text = L(pick(ccfg, "name", "Name") or "Color"),
				FontFace = FONT_MAIN, TextColor3 = Theme.Text, TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left, AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.new(1, -60, 1, 0), Parent = header,
			})
			local swatch = create("Frame", {
				BackgroundColor3 = color, AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(34, 18),
				BorderSizePixel = 0, Parent = header,
			})
			corner(swatch, 4); stroke(swatch, Theme.Stroke, 0.4)

			local body = create("Frame", {
				BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 36),
				Size = UDim2.new(1, 0, 0, 160), Visible = false, Parent = row,
			})
			create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), Parent = body })

			local sv = create("Frame", {
				BackgroundColor3 = Color3.fromHSV(h, 1, 1),
				Size = UDim2.new(1, -34, 1, -20), BorderSizePixel = 0, Parent = body,
			})
			corner(sv, 4)
			create("Frame", { BackgroundColor3 = Color3.new(1,1,1), Size = UDim2.new(1,0,1,0), BorderSizePixel = 0, Parent = sv }, {
				create("UIGradient", { Color = ColorSequence.new(Color3.new(1,1,1)), Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0,0), NumberSequenceKeypoint.new(1,1) }) }),
				create("UICorner", { CornerRadius = UDim.new(0,4) }),
			})
			create("Frame", { BackgroundColor3 = Color3.new(0,0,0), Size = UDim2.new(1,0,1,0), BorderSizePixel = 0, Parent = sv }, {
				create("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.new(0,0,0)), Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0,1), NumberSequenceKeypoint.new(1,0) }) }),
				create("UICorner", { CornerRadius = UDim.new(0,4) }),
			})
			local svCursor = create("Frame", {
				BackgroundColor3 = Color3.new(1,1,1), AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(s, 0, 1 - v, 0), Size = UDim2.fromOffset(8, 8),
				BorderSizePixel = 0, ZIndex = 5, Parent = sv,
			})
			corner(svCursor, 4); stroke(svCursor, Color3.new(0,0,0), 0.2)

			local hue = create("Frame", {
				AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0),
				Size = UDim2.new(0, 22, 1, -20), BorderSizePixel = 0, Parent = body,
			})
			corner(hue, 4)
			create("UIGradient", {
				Rotation = 90,
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255,0,0)),
					ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255,255,0)),
					ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0,255,0)),
					ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0,255,255)),
					ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0,0,255)),
					ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255,0,255)),
					ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255,0,0)),
				}),
				Parent = hue,
			})
			local hueCursor = create("Frame", {
				BackgroundColor3 = Color3.new(1,1,1), AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, h, 0), Size = UDim2.new(1, 4, 0, 4),
				BorderSizePixel = 0, ZIndex = 5, Parent = hue,
			})
			corner(hueCursor, 2); stroke(hueCursor, Color3.new(0,0,0), 0.2)

			-- Alpha
			local alphaBar = create("Frame", {
				BackgroundColor3 = Theme.Off, AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 12),
				BorderSizePixel = 0, Parent = body,
			})
			corner(alphaBar, 3)
			local alphaFill = create("Frame", {
				BackgroundColor3 = Theme.Accent, Size = UDim2.new(alpha, 0, 1, 0),
				BorderSizePixel = 0, Parent = alphaBar,
			})
			corner(alphaFill, 3)
			local alphaCursor = create("Frame", {
				BackgroundColor3 = Theme.Text, AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(alpha, 0, 0.5, 0), Size = UDim2.fromOffset(10, 14),
				BorderSizePixel = 0, ZIndex = 5, Parent = alphaBar,
			})
			corner(alphaCursor, 3)

			local api = {}
			local cb = pick(ccfg, "callback", "Callback")
			local function refresh(fire)
				color = Color3.fromHSV(h, s, v)
				sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
				svCursor.Position = UDim2.new(s, 0, 1 - v, 0)
				hueCursor.Position = UDim2.new(0.5, 0, h, 0)
				swatch.BackgroundColor3 = color
				alphaFill.Size = UDim2.new(alpha, 0, 1, 0)
				alphaCursor.Position = UDim2.new(alpha, 0, 0.5, 0)
				if fire and cb then task.spawn(cb, color, alpha) end
				local flag = pick(ccfg, "flag", "Flag")
				if flag then Library.Flags[flag] = color end
			end
			bindDrag(sv, function(ax, ay) s = ax; v = 1 - ay; refresh(true) end)
			bindDrag(hue, function(_, ay) h = ay; refresh(true) end)
			bindDrag(alphaBar, function(ax) alpha = ax; refresh(true) end)

			local open = false
			header.Activated:Connect(function()
				if api._locked and api._locked() then return end
				open = not open
				if open then body.Visible = true end
				tween(row, TI_S, { Size = UDim2.new(1, 0, 0, open and 202 or 36) })
				if not open then
					task.delay(0.12, function() if not open then body.Visible = false end end)
				end
			end)

			function api:Set(c, silent) h, s, v = c:ToHSV(); refresh(not silent) end
			function api:SetAlpha(a, silent) alpha = math.clamp(a, 0, 1); refresh(not silent) end
			function api:Get() return color end
			function api:GetAlpha() return alpha end
			api.Instance = row
			attachCommon(api, row, ccfg, true)
			local flag = pick(ccfg, "flag", "Flag")
			if not pick(ccfg, "forgetState", "ForgetState") then
				Library:_register(flag or pick(ccfg, "name", "Name"), api)
			end
			return api
		end

		-- 10. Stat -------------------------------------------------
		function Tab:CreateStat(scfg)
			scfg = scfg or {}
			local prefix = pick(scfg, "prefix", "Prefix") or ""
			local suffix = pick(scfg, "suffix", "Suffix") or ""
			local compact = pick(scfg, "compact", "Compact") or false
			local doRoll = pick(scfg, "roll", "Roll") or false
			local row = newRow(compact and 34 or 44)

			create("TextLabel", {
				BackgroundTransparency = 1, Text = L(pick(scfg, "name", "Name") or "Stat"),
				FontFace = FONT_MAIN, TextColor3 = Theme.SubText, TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left, AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.new(0.5, -10, 1, 0), Parent = row,
			})
			local value = pick(scfg, "value", "Value") or 0
			local valLbl = create("TextLabel", {
				BackgroundTransparency = 1, Text = prefix .. tostring(value) .. suffix,
				FontFace = FONT_TITLE, TextColor3 = Theme.Accent, TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd,
				AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0),
				Size = UDim2.new(0.5, -10, 1, 0), Parent = row,
			})
			local deltaLbl = create("TextLabel", {
				BackgroundTransparency = 1, Text = "",
				FontFace = FONT_MAIN, TextColor3 = Theme.Success, TextSize = 11,
				TextXAlignment = Enum.TextXAlignment.Right,
				AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 2),
				Size = UDim2.new(0.5, -10, 0, 12), Parent = row,
			})

			local function render() valLbl.Text = prefix .. tostring(value) .. suffix end
			local api = {}
			function api:Set(v, silent)
				local old = value
				value = v
				if doRoll then
					local steps = 8
					local delta = (v - old) / steps
					task.spawn(function()
						for i = 1, steps do
							valLbl.Text = prefix .. tostring(math.floor(old + delta * i)) .. suffix
							task.wait(0.02)
						end
						render()
					end)
				else render() end
				if v ~= old then
					local delta = v - old
					deltaLbl.Text = (delta >= 0 and "+" or "") .. tostring(delta)
					deltaLbl.TextColor3 = delta >= 0 and Theme.Success or Theme.Error
				end
			end
			function api:Get() return value end
			function api:ZeroChange() deltaLbl.Text = "" end
			api.Instance = row
			attachCommon(api, row, scfg, false)
			return api
		end

		-- 11. Progress ---------------------------------------------
		function Tab:CreateProgress(pcfg)
			pcfg = pcfg or {}
			local steps = pick(pcfg, "steps", "Steps")
			local range = pick(pcfg, "range", "Range") or (steps and { 0, steps } or { 0, 100 })
			local min, max = range[1], range[2]
			local value = math.clamp(pick(pcfg, "value", "Value", "default", "Default") or min, min, max)
			local indeterminate = pick(pcfg, "indeterminate", "Indeterminate") or false
			local formatter = pick(pcfg, "formatter", "Formatter")
			local fixedText = pick(pcfg, "text", "Text")
			local showReadout = pick(pcfg, "showReadout", "ShowReadout") ~= false

			local row = newRow(40)
			create("TextLabel", {
				BackgroundTransparency = 1, Text = L(pick(pcfg, "name", "Name") or "Progress"),
				FontFace = FONT_MAIN, TextColor3 = Theme.Text, TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				Position = UDim2.new(0, 10, 0, 5), Size = UDim2.new(0.6, 0, 0, 16), Parent = row,
			})
			local valLbl = create("TextLabel", {
				BackgroundTransparency = 1, Text = "",
				FontFace = FONT_TITLE, TextColor3 = Theme.Accent, TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -10, 0, 5), Size = UDim2.new(0.4, 0, 0, 16), Parent = row,
			})
			if not showReadout then valLbl.Visible = false end

			local track = create("Frame", {
				BackgroundColor3 = Theme.Off, AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.new(0, 10, 1, -8), Size = UDim2.new(1, -20, 0, 6),
				BorderSizePixel = 0, Parent = row,
			})
			corner(track, 3)
			local fill = create("Frame", {
				BackgroundColor3 = Theme.Accent,
				Size = UDim2.new((value - min) / math.max(max - min, 1e-6), 0, 1, 0),
				BorderSizePixel = 0, Parent = track,
			})
			corner(fill, 3)

			local function updateReadout()
				if fixedText then valLbl.Text = fixedText
				elseif formatter then
					local ok, s = pcall(formatter, value, min, max)
					valLbl.Text = ok and s or ""
				elseif steps then valLbl.Text = tostring(value) .. "/" .. tostring(max)
				else valLbl.Text = math.floor(((value - min) / math.max(max - min, 1e-6)) * 100) .. "%" end
			end
			local function render()
				local a = (max - min) == 0 and 0 or (value - min) / (max - min)
				tween(fill, TI, { Size = UDim2.new(a, 0, 1, 0) })
				updateReadout()
			end
			render()

			local sweeping = false
			local function startSweep()
				if sweeping then return end
				sweeping = true
				task.spawn(function()
					while sweeping do
						tween(fill, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Size = UDim2.new(1, 0, 1, 0) })
						task.wait(0.8)
						tween(fill, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Size = UDim2.new(0.05, 0, 1, 0) })
						task.wait(0.8)
					end
				end)
			end
			if indeterminate then startSweep() end

			local api = {}
			function api:Set(v) sweeping = false; value = math.clamp(v, min, max); render() end
			function api:Get() return value end
			function api:GetProgress() return (value - min) / math.max(max - min, 1e-6) end
			function api:SetRange(newMin, newMax) min, max = newMin, newMax; value = math.clamp(value, min, max); render() end
			function api:SetText(t) fixedText = t; updateReadout() end
			function api:SetIndeterminate(v)
				indeterminate = v
				if v then startSweep() else sweeping = false end
			end
			api.Instance = row
			attachCommon(api, row, pcfg, false)
			return api
		end
		Tab.CreateProgressBar = Tab.CreateProgress

		-- 12. Console -----------------------------------------------
		function Tab:CreateConsole(ccfg)
			ccfg = ccfg or {}
			local height = math.max(pick(ccfg, "height", "Height") or 130, 48)
			local follow = pick(ccfg, "follow", "Follow") or false
			local maxLines = pick(ccfg, "maxLines", "MaxLines") or 200
			local initial = pick(ccfg, "text", "Text", "code", "Code") or ""

			local row = newRow(0)
			row.AutomaticSize = nil
			row.Size = UDim2.new(1, 0, 0, height + 30)
			row.ClipsDescendants = true

			local nameLbl = pick(ccfg, "name", "Name")
			if nameLbl then
				create("TextLabel", {
					BackgroundTransparency = 1, Text = L(nameLbl),
					FontFace = FONT_TITLE, TextColor3 = Theme.Text, TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Left,
					Position = UDim2.new(0, 10, 0, 6), Size = UDim2.new(1, -20, 0, 16), Parent = row,
				})
			end

			local panel = create("Frame", {
				BackgroundColor3 = Theme.Secondary,
				Position = UDim2.new(0, 10, 0, nameLbl and 26 or 8),
				Size = UDim2.new(1, -20, 0, height), BorderSizePixel = 0, Parent = row,
			})
			corner(panel, 5); stroke(panel, Theme.Stroke, STROKE_T)

			local scroll = create("ScrollingFrame", {
				BackgroundTransparency = 1, BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 1, 0), CanvasSize = UDim2.new(),
				AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 3,
				ScrollBarImageColor3 = Theme.Stroke, ScrollBarImageTransparency = 0.5, Parent = panel,
			}, {
				create("UIPadding", {
					PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6),
					PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8),
				}),
				create("UIListLayout", { Padding = UDim.new(0, 1), SortOrder = Enum.SortOrder.LayoutOrder }),
			})

			local lines = {}
			local order = 0
			local function addLine(text)
				for _, sub in tostring(text):split("\n") do
					order += 1
					table.insert(lines, sub)
					create("TextLabel", {
						BackgroundTransparency = 1, Text = sub,
						Font = Enum.Font.Code, TextColor3 = Theme.Text, TextSize = 12,
						TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = false,
						AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 0, 14),
						LayoutOrder = order, Parent = scroll,
					})
					while #lines > maxLines do
						table.remove(lines, 1)
						local first = scroll:FindFirstChildWhichIsA("TextLabel")
						if first then first:Destroy() end
					end
				end
				if follow then
					task.defer(function() scroll.CanvasPosition = Vector2.new(0, scroll.AbsoluteCanvasSize.Y) end)
				end
			end
			if initial ~= "" then addLine(initial) end

			local api = {}
			function api:Set(t)
				for _, c in scroll:GetChildren() do
					if c:IsA("TextLabel") then c:Destroy() end
				end
				lines = {}; order = 0
				addLine(t)
			end
			function api:Append(t) addLine(t) end
			function api:Clear() api:Set("") end
			function api:Get() return table.concat(lines, "\n") end
			function api:Copy() return copyToClipboard(table.concat(lines, "\n")) end
			function api:SetHeight(h)
				height = math.max(h, 48)
				row.Size = UDim2.new(1, 0, 0, height + 30)
				panel.Size = UDim2.new(1, -20, 0, height)
			end
			api.Instance = row
			attachCommon(api, row, ccfg, false)
			return api
		end

		-- 13. Text / Paragraph -------------------------------------
		function Tab:CreateText(tcfg)
			tcfg = tcfg or {}
			local row = newRow(0)
			row.AutomaticSize = Enum.AutomaticSize.Y
			create("UIPadding", {
				PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8),
				PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = row,
			})
			create("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = row })

			local title = pick(tcfg, "name", "Name", "title", "Title")
			local body = pick(tcfg, "text", "Text", "body", "Body")
			local titleLbl, bodyLbl
			if title then
				titleLbl = create("TextLabel", {
					BackgroundTransparency = 1, Text = L(title),
					FontFace = FONT_TITLE, TextColor3 = Theme.Text, TextSize = 16,
					TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
					AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0),
					LayoutOrder = 1, Parent = row,
				})
			end
			if body then
				bodyLbl = create("TextLabel", {
					BackgroundTransparency = 1, Text = body,
					FontFace = FONT_MAIN, TextColor3 = Theme.SubText, TextSize = 14,
					TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
					AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0),
					LayoutOrder = 2, Parent = row,
				})
			end
			local api = {}
			function api:Set(t) if bodyLbl then bodyLbl.Text = t end end
			function api:SetTitle(t) if titleLbl then titleLbl.Text = t end end
			function api:Get() return bodyLbl and bodyLbl.Text or "" end
			api.Instance = row
			attachCommon(api, row, tcfg, false)
			return api
		end
		Tab.CreateParagraph = Tab.CreateText

		-- 14. Divider -----------------------------------------------
		function Tab:CreateDivider(dcfg)
			dcfg = dcfg or {}
			local text = pick(dcfg, "text", "Text") or ""
			local spacing = pick(dcfg, "spacing", "Spacing") or 8
			local showLine = pick(dcfg, "line", "Line") ~= false
			Tab._order += 1
			local row = create("Frame", {
				BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, spacing * 2),
				LayoutOrder = Tab._order, Parent = page,
			})
			create("Frame", {
				BackgroundColor3 = Theme.Stroke, BackgroundTransparency = STROKE_T,
				AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
				Size = UDim2.new(1, 0, 0, 1), BorderSizePixel = 0,
				Visible = showLine, Parent = row,
			})
			local textLbl
			if text ~= "" then
				textLbl = create("TextLabel", {
					BackgroundTransparency = 1, Text = text,
					FontFace = FONT_MAIN, TextColor3 = Theme.SubText, TextSize = 11,
					AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
					Size = UDim2.new(0, 0, 0, 14), AutomaticSize = Enum.AutomaticSize.X, Parent = row,
				})
			end
			local api = {}
			function api:Set(t) if textLbl then textLbl.Text = t end end
			api.Instance = row
			attachCommon(api, row, dcfg, false)
			return api
		end

		-- 15. Section -----------------------------------------------
		function Tab:CreateSection(scfg)
			if type(scfg) == "string" then scfg = { name = scfg } end
			scfg = scfg or {}
			Tab._order += 1
			local row = create("Frame", {
				BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 22),
				LayoutOrder = Tab._order, Parent = page,
			})
			local lbl = create("TextLabel", {
				BackgroundTransparency = 1,
				Text = string.upper(L(pick(scfg, "name", "Name") or "Section")),
				FontFace = FONT_TITLE, TextColor3 = Theme.SubText, TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left, AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.new(0, 2, 1, -4), Size = UDim2.new(1, -4, 0, 14), Parent = row,
			})
			local api = { Set = function(_, t) lbl.Text = string.upper(t) end, Instance = row }
			attachCommon(api, row, nil, false)
			return api
		end

		-- 16. Group ------------------------------------------------
		function Tab:CreateGroup(gcfg)
			gcfg = gcfg or {}
			local dir = pick(gcfg, "direction", "Direction") or "row"
			if dir == "horizontal" then dir = "row" elseif dir == "vertical" then dir = "column" end
			Tab._order += 1
			local group = create("Frame", {
				BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = Tab._order, Parent = page,
			})
			create("UIListLayout", {
				FillDirection = dir == "row" and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical,
				Padding = UDim.new(0, 6),
				SortOrder = Enum.SortOrder.LayoutOrder, Parent = group,
			})
			local api = {}
			local childOrder = 0
			function api:CreateSection(sname)
				childOrder += 1
				local s = create("TextLabel", {
					BackgroundTransparency = 1,
					Text = string.upper(L(type(sname) == "string" and sname or sname.name or "Section")),
					FontFace = FONT_TITLE, TextColor3 = Theme.SubText, TextSize = 11,
					TextXAlignment = Enum.TextXAlignment.Left,
					AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 0, 16),
					LayoutOrder = childOrder, Parent = group,
				})
				return { Instance = s }
			end
			function api:CreateGroup(sub) return Tab:CreateGroup(sub) end
			api.Instance = group
			return api
		end

		-- 17. Image -------------------------------------------------
		function Tab:CreateImage(icfg)
			icfg = icfg or {}
			Tab._order += 1
			local row = create("Frame", {
				BackgroundColor3 = Theme.Element,
				Size = UDim2.new(1, 0, 0, pick(icfg, "height", "Height") or 140),
				LayoutOrder = Tab._order, BorderSizePixel = 0, Parent = page,
			})
			corner(row, 6); stroke(row, Theme.Stroke, STROKE_T)
			local img = create("ImageLabel", {
				BackgroundTransparency = 1, Image = pick(icfg, "image", "Image") or "",
				ScaleType = Enum.ScaleType.Fit,
				Size = UDim2.new(1, -12, 1, -12),
				Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5),
				Parent = row,
			})
			local api = { Set = function(_, id) img.Image = id end, Instance = row }
			attachCommon(api, row, nil, false)
			return api
		end

		-- 18. Button Group -----------------------------------------
		function Tab:CreateButtonGroup(bgcfg)
			bgcfg = bgcfg or {}
			local buttons = pick(bgcfg, "buttons", "Buttons") or {}
			local row = newRow(36)
			row.BackgroundTransparency = 1
			for _, s in row:GetChildren() do if s:IsA("UIStroke") then s:Destroy() end end
			create("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = row,
			})
			local api = { Buttons = {} }
			for i, bcfg in buttons do
				local btnEl = create("TextButton", {
					Text = "", AutoButtonColor = false, BackgroundColor3 = Theme.Element,
					Size = UDim2.new(1 / #buttons, -4, 1, 0), LayoutOrder = i,
					BorderSizePixel = 0, Parent = row,
				})
				corner(btnEl, 5); stroke(btnEl, Theme.Stroke, STROKE_T)
				create("TextLabel", {
					BackgroundTransparency = 1, Text = bcfg.name or bcfg.Name or ("Button " .. i),
					FontFace = FONT_MAIN, TextColor3 = Theme.Text, TextSize = 13,
					TextTruncate = Enum.TextTruncate.AtEnd,
					Size = UDim2.new(1, 0, 1, 0), Parent = btnEl,
				})
				btnEl.MouseEnter:Connect(function() tween(btnEl, TI, { BackgroundColor3 = Theme.ElementHover }) end)
				btnEl.MouseLeave:Connect(function() tween(btnEl, TI, { BackgroundColor3 = Theme.Element }) end)
				btnEl.Activated:Connect(function()
					tween(btnEl, TI, { BackgroundColor3 = Theme.Accent })
					task.wait(0.12)
					tween(btnEl, TI, { BackgroundColor3 = Theme.Element })
					local cb = bcfg.callback or bcfg.Callback
					if cb then task.spawn(cb) end
				end)
				table.insert(api.Buttons, btnEl)
			end
			api.Instance = row
			attachCommon(api, row, nil, true)
			return api
		end

		-- 19. Selector ---------------------------------------------
		function Tab:CreateSelector(secfg)
			secfg = secfg or {}
			local options = pick(secfg, "options", "Options") or {}
			local idx = 1
			local default = pick(secfg, "default", "Default")
			for i, o in options do if o == default then idx = i; break end end

			local row = newRow(36)
			create("TextLabel", {
				BackgroundTransparency = 1, Text = L(pick(secfg, "name", "Name") or "Selector"),
				FontFace = FONT_MAIN, TextColor3 = Theme.Text, TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left, AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.new(0.45, 0, 1, 0), Parent = row,
			})
			local leftBtn = create("TextButton", {
				Text = "", AutoButtonColor = false, BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -96, 0.5, 0),
				Size = UDim2.fromOffset(22, 22), Parent = row,
			})
			local leftIcon = icon("chevron-left", 14, false, Theme.SubText)
			leftIcon.AnchorPoint = Vector2.new(0.5, 0.5); leftIcon.Position = UDim2.new(0.5, 0, 0.5, 0); leftIcon.Parent = leftBtn
			local valLbl = create("TextLabel", {
				BackgroundTransparency = 1, Text = tostring(options[idx] or "-"),
				FontFace = FONT_TITLE, TextColor3 = Theme.Accent, TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd,
				AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -50, 0.5, 0),
				Size = UDim2.new(0, 60, 1, 0), Parent = row,
			})
			local rightBtn = create("TextButton", {
				Text = "", AutoButtonColor = false, BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0),
				Size = UDim2.fromOffset(22, 22), Parent = row,
			})
			local rightIcon = icon("chevron-right", 14, false, Theme.SubText)
			rightIcon.AnchorPoint = Vector2.new(0.5, 0.5); rightIcon.Position = UDim2.new(0.5, 0, 0.5, 0); rightIcon.Parent = rightBtn

			local api = {}
			local function set(newIdx, fire)
				if #options == 0 then return end
				idx = ((newIdx - 1) % #options) + 1
				valLbl.Text = tostring(options[idx])
				local flag = pick(secfg, "flag", "Flag")
				if flag then Library.Flags[flag] = options[idx] end
				if fire then
					local cb = pick(secfg, "callback", "Callback")
					if cb then task.spawn(cb, options[idx]) end
				end
			end
			leftBtn.Activated:Connect(function()
				if api._locked and api._locked() then return end
				set(idx - 1, true)
			end)
			rightBtn.Activated:Connect(function()
				if api._locked and api._locked() then return end
				set(idx + 1, true)
			end)
			function api:Set(v, silent)
				for i, o in options do if o == v then set(i, not silent); return end end
			end
			function api:Get() return options[idx] end
			function api:Refresh(newOpts) options = newOpts or options; set(1, false) end
			api.Instance = row
			attachCommon(api, row, secfg, true)
			local flag = pick(secfg, "flag", "Flag")
			if not pick(secfg, "forgetState", "ForgetState") then
				Library:_register(flag or pick(secfg, "name", "Name"), api)
			end
			return api
		end

		-- 20. Hyperlink --------------------------------------------
		function Tab:CreateHyperlink(hcfg)
			hcfg = hcfg or {}
			local row = newRow(36)
			local btnEl = create("TextButton", {
				Text = "", BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 1, 0), Parent = row,
			})
			create("TextLabel", {
				BackgroundTransparency = 1, Text = L(pick(hcfg, "name", "Name") or "Link"),
				FontFace = FONT_MAIN, TextColor3 = Theme.Text, TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left, AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.new(1, -60, 1, 0), Parent = btnEl,
			})
			local ic = icon("link", 16, false, Theme.SubText)
			ic.AnchorPoint = Vector2.new(1, 0.5)
			ic.Position = UDim2.new(1, -10, 0.5, 0)
			ic.Parent = btnEl

			btnEl.MouseEnter:Connect(function() tween(ic, TI, { TextColor3 = Theme.Accent }) end)
			btnEl.MouseLeave:Connect(function() tween(ic, TI, { TextColor3 = Theme.SubText }) end)
			btnEl.Activated:Connect(function()
				local url = pick(hcfg, "url", "URL") or ""
				local copied = copyToClipboard(url)
				Library:Notify({
					Type = "info", Title = pick(hcfg, "name", "Name") or "Link",
					Content = copied and "Link copied to clipboard" or ("Clipboard unavailable: " .. url),
					Duration = 3,
				})
				local cb = pick(hcfg, "callback", "Callback")
				if cb then task.spawn(cb) end
			end)
			local api = { Instance = row }
			attachCommon(api, row, hcfg, true)
			return api
		end

		-- 21. Stepper ----------------------------------------------
		function Tab:CreateStepper(stcfg)
			stcfg = stcfg or {}
			local min, max = pick(stcfg, "min", "Min") or 0, pick(stcfg, "max", "Max") or 100
			local inc = pick(stcfg, "increment", "Increment") or 1
			local value = math.clamp(pick(stcfg, "default", "Default", "value", "Value") or min, min, max)
			local row = newRow(36)

			create("TextLabel", {
				BackgroundTransparency = 1, Text = L(pick(stcfg, "name", "Name") or "Stepper"),
				FontFace = FONT_MAIN, TextColor3 = Theme.Text, TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left, AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.new(0.5, -10, 1, 0), Parent = row,
			})
			local cluster = create("Frame", {
				BackgroundColor3 = Theme.Secondary, AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(110, 24),
				BorderSizePixel = 0, Parent = row,
			})
			corner(cluster, 5); stroke(cluster, Theme.Stroke, STROKE_T)

			local function stepperBtn(glyphName, anchor, pos)
				local b = create("TextButton", {
					Text = "", AutoButtonColor = false, BackgroundTransparency = 1,
					AnchorPoint = anchor, Position = pos,
					Size = UDim2.fromOffset(24, 24), Parent = cluster,
				})
				local g = icon(glyphName, 12, false, Theme.SubText)
				g.AnchorPoint = Vector2.new(0.5, 0.5); g.Position = UDim2.new(0.5, 0, 0.5, 0); g.Parent = b
				b.MouseEnter:Connect(function() tween(g, TI, { TextColor3 = Theme.Accent }) end)
				b.MouseLeave:Connect(function() tween(g, TI, { TextColor3 = Theme.SubText }) end)
				return b
			end

			local minusBtn = stepperBtn("minus", Vector2.new(0, 0.5), UDim2.new(0, 0, 0.5, 0))
			local plusBtn = stepperBtn("plus", Vector2.new(1, 0.5), UDim2.new(1, 0, 0.5, 0))
			local valBtn = create("TextButton", {
				Text = "", AutoButtonColor = false, BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
				Size = UDim2.new(1, -50, 1, 0), Parent = cluster,
			})
			local valLbl = create("TextLabel", {
				BackgroundTransparency = 1, Text = tostring(value),
				FontFace = FONT_TITLE, TextColor3 = Theme.Accent, TextSize = 13,
				Size = UDim2.new(1, 0, 1, 0), Parent = valBtn,
			})

			local api = {}
			local cb = pick(stcfg, "callback", "Callback")
			local function apply(newVal, silent)
				value = math.clamp(math.floor(newVal / inc + 0.5) * inc, min, max)
				valLbl.Text = tostring(value)
				if not silent and cb then task.spawn(cb, value) end
				local flag = pick(stcfg, "flag", "Flag")
				if flag then Library.Flags[flag] = value end
			end
			minusBtn.Activated:Connect(function()
				if api._locked and api._locked() then return end
				apply(value - inc)
			end)
			plusBtn.Activated:Connect(function()
				if api._locked and api._locked() then return end
				apply(value + inc)
			end)
			function api:Set(v, silent) apply(v, silent) end
			function api:Get() return value end
			api.Instance = row
			attachCommon(api, row, stcfg, true)
			local flag = pick(stcfg, "flag", "Flag")
			if not pick(stcfg, "forgetState", "ForgetState") then
				Library:_register(flag or pick(stcfg, "name", "Name"), api)
			end
			return api
		end

		-- 22. Tag --------------------------------------------------
		function Tab:CreateTag(tgcfg)
			tgcfg = tgcfg or {}
			local row = newRow(32)
			create("TextLabel", {
				BackgroundTransparency = 1, Text = L(pick(tgcfg, "name", "Name") or "Tag"),
				FontFace = FONT_MAIN, TextColor3 = Theme.Text, TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left, AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.new(0.5, 0, 1, 0), Parent = row,
			})
			local pill = create("Frame", {
				BackgroundColor3 = pick(tgcfg, "color", "Color") or Theme.Accent,
				AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0),
				Size = UDim2.fromOffset(0, 20), AutomaticSize = Enum.AutomaticSize.X,
				BorderSizePixel = 0, Parent = row,
			}, { create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }) })
			corner(pill, 10)
			local lbl = create("TextLabel", {
				BackgroundTransparency = 1, Text = pick(tgcfg, "text", "Text") or "Ready",
				FontFace = FONT_MAIN, TextColor3 = Theme.Text, TextSize = 12,
				Size = UDim2.new(1, 0, 1, 0), Parent = pill,
			})
			local api = {
				Set = function(_, txt, col)
					if txt then lbl.Text = txt end
					if col then tween(pill, TI, { BackgroundColor3 = col }) end
				end,
				Instance = row,
			}
			attachCommon(api, row, nil, false)
			return api
		end

		function Tab:Save() return Window:Save() end
		function Tab:Load() return Window:Load() end

		return Tab
	end

	-- ===============================================================
	-- Saving system
	-- ===============================================================
	local function configPath(fname)
		fname = fname or Window._configFileName
		local base = CONFIG_DIR
		if Window._configFolder and Window._configFolder ~= "" then
			base = CONFIG_DIR .. Window._configFolder .. "/"
		end
		return base .. fname .. ".json"
	end

	function Window:Save(name)
		if not Window._configEnabled or not HAS_FILE_IO then
			if name then Library:Notify({ Type = "error", Title = "Config", Content = "Saving not enabled." }) end
			return false
		end
		ensureConfigDir(Window._configFolder)
		local data = {}
		for flag, api in Library._registry do
			local ok, v = pcall(function() return api:Get() end)
			if ok then data[flag] = serialize(v) end
		end
		local ok, encoded = pcall(function() return HttpService:JSONEncode(data) end)
		if not ok then return false end
		local ok2 = pcall(function() writefile(configPath(name), encoded) end)
		if ok2 then
			Library:Notify({ Type = "success", Title = "Config", Content = "Saved '" .. (name or Window._configFileName) .. "'." })
			return true
		end
		return false
	end

	function Window:Load(name)
		if not Window._configEnabled or not HAS_FILE_IO then return false end
		local path = configPath(name)
		if not isfile(path) then return false end
		local ok, raw = pcall(function() return readfile(path) end)
		if not ok then return false end
		local ok2, data = pcall(function() return HttpService:JSONDecode(raw) end)
		if not ok2 or type(data) ~= "table" then return false end
		for flag, val in data do
			local api = Library._registry[flag]
			if api and api.Set then
				pcall(function() api:Set(deserialize(val), true) end)
				Library.Flags[flag] = deserialize(val)
			end
		end
		return true
	end

	function Window:ListConfigs()
		if not HAS_FILE_IO then return {} end
		local base = CONFIG_DIR
		if Window._configFolder and Window._configFolder ~= "" then
			base = CONFIG_DIR .. Window._configFolder .. "/"
		end
		local out = {}
		local ok, files = pcall(function() return listfiles(base) end)
		if not ok then return out end
		for _, f in files do
			local n = f:match("([^/\\]+)%.json$")
			if n then table.insert(out, n) end
		end
		return out
	end

	function Window:DeleteConfig(name)
		if not HAS_FILE_IO then return false end
		local path = configPath(name)
		if isfile(path) then
			pcall(function() delfile(path) end)
			return true
		end
		return false
	end

	function Window:Get(flag)
		local api = Library._registry[flag]
		if api and api.Get then return api:Get() end
		return Library.Flags[flag]
	end

	function Window:Set(flag, value)
		local api = Library._registry[flag]
		if api and api.Set then
			api:Set(value)
			Library.Flags[flag] = value
			return true
		end
		return false
	end

	if Window._configEnabled and configAutoLoad and HAS_FILE_IO then
		task.defer(function() Window:Load() end)
	end
	if Window._configEnabled and configAutoSave then
		local lastSave = 0
		RunService.Heartbeat:Connect(function()
			local now = os.clock()
			if now - lastSave > 2 then
				lastSave = now
				pcall(function() Window:Save() end)
			end
		end)
	end

	Window.Instance = BG
	return Window
end

-- ===================================================================
-- Floating action button
-- ===================================================================
function Library:CreateFloatingButton(cfg)
	cfg = cfg or {}
	if Library._fab then Library._fab:Destroy() end

	local size = cfg.Size or cfg.size or 46
	local fab = create("TextButton", {
		Name = "FloatingButton", Text = "", AutoButtonColor = false,
		BackgroundColor3 = cfg.Color or cfg.color or Theme.Accent, BackgroundTransparency = 0.05,
		Position = cfg.Position or cfg.position or UDim2.new(0, 20, 0.5, -size / 2),
		Size = UDim2.fromOffset(size, size), BorderSizePixel = 0, ZIndex = 350, Parent = ScreenGui,
	})
	corner(fab, size / 2)
	local st = stroke(fab, Theme.Stroke, STROKE_T)
	addShadow(fab, 14, 0.5)

	local ic = icon(cfg.Icon or cfg.icon or "bolt", size * 0.5, true, Theme.Text)
	ic.AnchorPoint = Vector2.new(0.5, 0.5); ic.Position = UDim2.new(0.5, 0, 0.5, 0); ic.Parent = fab

	local dragging, dragStart, posStart, moved
	fab.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			dragging = true; moved = false
			dragStart = inp.Position; posStart = fab.Position
		end
	end)
	UserInputService.InputChanged:Connect(function(inp)
		if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
			local d = inp.Position - dragStart
			if math.abs(d.X) > 3 or math.abs(d.Y) > 3 then moved = true end
			fab.Position = UDim2.new(posStart.X.Scale, posStart.X.Offset + d.X, posStart.Y.Scale, posStart.Y.Offset + d.Y)
		end
	end)
	UserInputService.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	fab.Activated:Connect(function()
		if moved then return end
		tween(fab, TI, { BackgroundTransparency = 0.3 })
		task.wait(0.12)
		tween(fab, TI, { BackgroundTransparency = 0.05 })
		local cb = cfg.Callback or cfg.callback
		if cb then task.spawn(cb) end
	end)

	fab.MouseEnter:Connect(function() tween(st, TI, { Transparency = 0.5 }) end)
	fab.MouseLeave:Connect(function() tween(st, TI, { Transparency = STROKE_T }) end)

	local api = {}
	function api:SetIcon(name) ic.Text = name end
	function api:SetColor(c) tween(fab, TI, { BackgroundColor3 = c }) end
	function api:Destroy() fab:Destroy(); Library._fab = nil end
	api.Instance = fab
	Library._fab = api
	return api
end

return Library
