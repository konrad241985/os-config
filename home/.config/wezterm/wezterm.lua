local wezterm = require("wezterm")

local config = wezterm.config_builder()

-- Keep terminal clicks, dragging, and scrolling available. Applications receive
-- normal mouse events when they request them; Shift-drag selects terminal text.
config.disable_default_mouse_bindings = false
config.bypass_mouse_reporting_modifiers = "SHIFT"

config.color_scheme = "rose-pine-moon"
config.font = wezterm.font("Hack Nerd Font")
config.font_size = 16.0
config.window_background_opacity = 0.8
config.macos_window_background_blur = 50
config.hide_tab_bar_if_only_one_tab = true
config.window_decorations = "RESIZE"

-- Forward Command+Option shortcuts to local Herdr using Kitty key encoding.
local function herdr_tab_action(sequence, fallback)
	return wezterm.action_callback(function(window, pane)
		local process = (pane:get_foreground_process_name() or ""):match("([^/]+)$")
		local action = process == "herdr" and wezterm.action.SendString(sequence) or fallback
		window:perform_action(action, pane)
	end)
end

-- Command+arrows switch terminal tabs regardless of the program inside them.
config.keys = {
	{ key = "t", mods = "SUPER|ALT", action = herdr_tab_action("\x1b[116;11u", wezterm.action.SpawnTab("CurrentPaneDomain")) },
	{ key = "w", mods = "SUPER|ALT", action = herdr_tab_action("\x1b[119;11u", wezterm.action.CloseCurrentTab({ confirm = true })) },
	-- System clipboard; use Shift-drag when an application captures the mouse.
	{
		key = "c",
		mods = "SUPER",
		action = wezterm.action_callback(function(window, pane)
			local selection = window:get_selection_text_for_pane(pane)
			local process = (pane:get_foreground_process_name() or ""):match("([^/]+)$")
			if selection ~= "" then
				window:perform_action(wezterm.action.CopyTo("Clipboard"), pane)
			elseif process == "herdr" then
				-- Kitty encoding of Command+C: Herdr copies its retained mouse selection.
				-- Unlike Ctrl+C, this does not interrupt a shell when nothing is selected.
				window:perform_action(wezterm.action.SendString("\x1b[99;9u"), pane)
			end
		end),
	},
	{ key = "v", mods = "SUPER", action = wezterm.action.PasteFrom("Clipboard") },
	{ key = "LeftArrow", mods = "SUPER", action = wezterm.action.ActivateTabRelative(-1) },
	{ key = "RightArrow", mods = "SUPER", action = wezterm.action.ActivateTabRelative(1) },
}

-- Dim unfocused windows so the focused one is obvious at a glance.
local UNFOCUSED_FOREGROUND_TEXT_HSB = { hue = 1.0, saturation = 0.25, brightness = 0.45 }
local UNFOCUSED_WINDOW_BACKGROUND_OPACITY = 0.62

-- get_config_overrides() hands back a copy, so the current value is never the
-- same table we last stored; compare the fields instead of the identity.
local function same_text_hsb(actual, expected)
	if actual == nil or expected == nil then
		return actual == expected
	end
	return actual.hue == expected.hue
		and actual.saturation == expected.saturation
		and actual.brightness == expected.brightness
end

wezterm.on("window-focus-changed", function(window)
	local overrides = window:get_config_overrides() or {}
	local text_hsb, opacity
	if not window:is_focused() then
		text_hsb = UNFOCUSED_FOREGROUND_TEXT_HSB
		opacity = UNFOCUSED_WINDOW_BACKGROUND_OPACITY
	end

	-- Only write when one of the two values we own actually changes; a redundant
	-- set_config_overrides() call would trigger another config reload.
	if same_text_hsb(overrides.foreground_text_hsb, text_hsb) and overrides.window_background_opacity == opacity then
		return
	end

	overrides.foreground_text_hsb = text_hsb
	overrides.window_background_opacity = opacity
	window:set_config_overrides(overrides)
end)

return config
