---------------------------
-- Default awesome theme --
---------------------------
local gears = require("gears")
local theme_assets = require("beautiful.theme_assets")
local xresources = require("beautiful.xresources")
local rnotification = require("ruled.notification")
local dpi = xresources.apply_dpi
local recolor = require("gears").color.recolor_image

local theme_path = string.format("%s/.config/awesome/theme", os.getenv("HOME"))

local theme = {}

local colors = {
  gruvbox = {
    bg = "#282828", -- bg(0) in palette
    fg = "#ebdbb2", -- fg(15) in palette
    grey1 = "#928374", -- gray in palette
    grey2 = "#3c3836", -- bg1 in palette
    red = "#cc241d", -- red(0) in palette
    soft_red = "#fb4934", -- red(9) in palette
    green = "#98971a", -- green(2) in palette
    soft_green = "#b8bb26", -- green(10) in palette
    yellow = "#d79921", -- yellow(3) in palette
    soft_yellow = "#fabd2f", -- yellow(11) in palette
    blue = "#458588", -- blue(4) in palette
    soft_blue = "#83a598", -- blue(12) in palette
    soft_blue2 = "#8ec07c", -- aqua(14) in palette
    purple = "#b16286", -- purple(5) in palette
    softpurple = "#d3869b", -- purplepurple(13) in palette
    aqua = "#689d6a", -- aqua(6) in palette
    white = "#ebdbb2", -- fg(15) in palette
    white2 = "#fbf1c7", -- fg0 in palette
    orange = "#d65d0e", -- orange in palette
    soft_orange = "#fe8019", -- orange in palette
  },
  nord = {
    bg = "#2E3440", -- Polarnight1
    fg = "#D8DEE9", -- Snowstorm1
    grey1 = "#3B4252", -- polarnight2
    grey2 = "#434C5E", -- polarnight3
    red = "#BF616A", -- aurora1 in palette
    soft_red = "#BF616A", --  in palette
    green = "#A3BE8C", -- aurora4 in palette
    soft_green = "#A3BE8C", -- aurora4 in palette
    yellow = "#EBCB8B", --  in palette
    soft_yellow = "#EBCB8B", --  in palette
    blue = "#8FBCBB", -- frost1 in palette
    soft_blue = "#88C0D0", -- frost2 in palette
    soft_blue2 = "#81A1C1", -- frost3 in palette
    purple = "#B48EAD", --  in palette
    softpurple = "#5E81AC", --  in palette
    pink = "#4C566A", -- polarnight4 in palette
    white = "#E5E9F0", -- snowstorm2 in palette
    white2 = "#ECEFF4", -- snowstorm3 in palette
    orange = "#D08770", -- aurora2 in palette
    soft_orange = "#D08770", -- aurora2 in palette
  },
}

local color_scheme = "gruvbox"
local color = colors[color_scheme]

theme.font = "JetBrainsMono Nerd Font, 10"
theme.primary_color = color.orange

theme.bg_normal = color.bg
theme.bg_focus = color.grey2
theme.bg_urgent = color.soft_red
theme.bg_minimize = color.grey1
theme.bg_systray = color.bg

theme.fg_normal = color.fg
theme.fg_focus = color.white
theme.fg_urgent = color.white
theme.fg_minimize = color.white

theme.useless_gap = dpi(8)
theme.border_width = dpi(1)
theme.border_color_normal = color.bg
theme.border_color_active = color.soft_green
theme.border_color_marked = color.red

-- There are other variable sets
-- overriding the default one when
-- defined, the sets are:
-- taglist_[bg|fg]_[focus|urgent|occupied|empty|volatile]
-- tasklist_[bg|fg]_[focus|urgent]
-- titlebar_[bg|fg]_[normal|focus]
-- tooltip_[font|opacity|fg_color|bg_color|border_width|border_color]
-- prompt_[fg|bg|fg_cursor|bg_cursor|font]
-- hotkeys_[bg|fg|border_width|border_color|shape|opacity|modifiers_fg|label_bg|label_fg|group_margin|font|description_font]
-- Example:
--theme.taglist_bg_focus = "#ff0000"

-- Variables set for theming notifications:
-- notification_font
-- notification_[bg|fg]
-- notification_[width|height|margin]
-- notification_[border_color|border_width|shape|opacity]

-- Variables set for theming the menu:
-- menu_[bg|fg]_[normal|focus]
-- menu_[border_color|border_width]
theme.menu_submenu_icon = recolor(theme_path .. "/submenu.png", color.orange)
theme.menu_height = dpi(15)
theme.menu_width = dpi(100)

-- You can add as many variables as
-- you wish and access them by using
-- beautiful.variable in your rc.lua
--theme.bg_widget = "#cc0000"

--Titlebars
theme.titlebar_close_button_normal = recolor(theme_path .. "/titlebar/square.svg", color.soft_red)
theme.titlebar_close_button_focus = recolor(theme_path .. "/titlebar/square.svg", color.soft_red)

theme.titlebar_minimize_button_normal = nil
theme.titlebar_minimize_button_focus = nil

theme.titlebar_ontop_button_normal_inactive = nil
theme.titlebar_ontop_button_focus_inactive = nil
theme.titlebar_ontop_button_normal_active = nil
theme.titlebar_ontop_button_focus_active = nil

theme.titlebar_sticky_button_normal_inactive = nil
theme.titlebar_sticky_button_focus_inactive = nil
theme.titlebar_sticky_button_normal_active = nil
theme.titlebar_sticky_button_focus_active = nil

theme.titlebar_floating_button_normal_inactive = recolor(theme_path .. "/titlebar/square.svg", color.soft_yellow)
theme.titlebar_floating_button_focus_inactive = recolor(theme_path .. "/titlebar/square.svg", color.soft_yellow)
theme.titlebar_floating_button_normal_active = recolor(theme_path .. "/titlebar/square.svg", color.soft_orange)
theme.titlebar_floating_button_focus_active = recolor(theme_path .. "/titlebar/square.svg", color.soft_orange)

theme.titlebar_maximized_button_normal_inactive = recolor(theme_path .. "/titlebar/square.svg", color.soft_green)
theme.titlebar_maximized_button_focus_inactive = recolor(theme_path .. "/titlebar/square.svg", color.soft_green)
theme.titlebar_maximized_button_normal_active = recolor(theme_path .. "/titlebar/square.svg", color.soft_green)
theme.titlebar_maximized_button_focus_active = recolor(theme_path .. "/titlebar/square.svg", color.soft_green)

theme.wallpaper = theme_path .. "/spaceman.jpg"

-- Layouts
theme.layout_fairh = recolor(theme_path .. "/layouts/fairhw.png", color.fg)
theme.layout_fairv = recolor(theme_path .. "/layouts/fairvw.png", color.fg)
theme.layout_floating = recolor(theme_path .. "/layouts/floatingw.png", color.fg)
theme.layout_magnifier = recolor(theme_path .. "/layouts/magnifierw.png", color.fg)
theme.layout_max = recolor(theme_path .. "/layouts/maxw.png", color.fg)
theme.layout_fullscreen = recolor(theme_path .. "/layouts/fullscreenw.png", color.fg)
theme.layout_tilebottom = recolor(theme_path .. "/layouts/tilebottomw.png", color.fg)
theme.layout_tileleft = recolor(theme_path .. "/layouts/tileleftw.png", color.fg)
theme.layout_tile = recolor(theme_path .. "/layouts/tilew.png", color.fg)
theme.layout_tiletop = recolor(theme_path .. "/layouts/tiletopw.png", color.fg)
theme.layout_spiral = recolor(theme_path .. "/layouts/spiralw.png", color.fg)
theme.layout_dwindle = recolor(theme_path .. "/layouts/dwindlew.png", color.fg)
theme.layout_cornernw = recolor(theme_path .. "/layouts/cornernww.png", color.fg)
theme.layout_cornerne = recolor(theme_path .. "/layouts/cornernew.png", color.fg)
theme.layout_cornersw = recolor(theme_path .. "/layouts/cornersww.png", color.fg)
theme.layout_cornerse = recolor(theme_path .. "/layouts/cornersew.png", color.fg)

--Tasklist
theme.tasklist_disable_icon = true

-- Generate Awesome icon:
theme.awesome_icon = theme_assets.awesome_icon(theme.menu_height, theme.bg_focus, theme.fg_focus)

-- Define the icon theme for application icons. If not set then the icons
-- from /usr/share/icons and /usr/share/icons/hicolor will be used.
theme.icon_theme = nil

-- Set different colors for urgent notifications.
rnotification.connect_signal("request::rules", function()
  rnotification.append_rule({
    rule = { urgency = "critical" },
    properties = { bg = "#ff0000", fg = "#ffffff" },
  })
end)

--[[
INFO: EVERYTHING BELOW THIS IS USING THE DEFAULT AWESOME THEME VALUES (https://awesomewm.org/apidoc/documentation/06-appearance.md.html)
I JUST COPIED THEM HERE FOR REFERENCE AND TO MAKE IT MORE CLEAR WHAT VARIABLES ARE READILY AVAILABLE TO BE ALTERED.
YOU CAN ALSO SET ANY VARIABLE YOU WANT IN HERE AS `theme.foo` AND YOU CAN REFERENCE IT IN THE REST OF YOUR CODE AS
`beautiful.foo`.  THESE ONES ARE JUST THE BUILT INS
]]
theme.arcchart_bg = nil
theme.arcchart_border_color = nil
theme.arcchart_border_width = nil
theme.arcchart_color = nil
theme.arcchart_paddings = nil
theme.arcchart_rounded_edge = nil
theme.arcchart_start_angle = nil
theme.arcchart_thickness = nil
theme.border_color_floating = nil
theme.border_color_floating_active = nil
theme.border_color_floating_new = nil
theme.border_color_floating_normal = nil
theme.border_color_floating_urgent = nil
theme.border_color_fullscreen = nil
theme.border_color_fullscreen_active = nil
theme.border_color_fullscreen_new = nil
theme.border_color_fullscreen_normal = nil
theme.border_color_fullscreen_urgent = nil
theme.border_color_maximized = nil
theme.border_color_maximized_active = nil
theme.border_color_maximized_new = nil
theme.border_color_maximized_normal = nil
theme.border_color_maximized_urgent = nil
theme.border_color_new = nil
theme.border_color_urgent = nil
theme.border_width_active = nil
theme.border_width_floating = nil
theme.border_width_floating_active = nil
theme.border_width_floating_new = nil
theme.border_width_floating_normal = nil
theme.border_width_floating_urgent = nil
theme.border_width_fullscreen = nil
theme.border_width_fullscreen_active = nil
theme.border_width_fullscreen_new = nil
theme.border_width_fullscreen_normal = nil
theme.border_width_fullscreen_urgent = nil
theme.border_width_maximized = nil
theme.border_width_maximized_active = nil
theme.border_width_maximized_new = nil
theme.border_width_maximized_normal = nil
theme.border_width_maximized_urgent = nil
theme.border_width_new = nil
theme.border_width_normal = nil
theme.border_width_urgent = nil
theme.calendar_font = nil
theme.calendar_long_weekdays = nil
theme.calendar_spacing = nil
theme.calendar_start_sunday = nil
theme.calendar_style = nil
theme.calendar_week_numbers = nil
theme.checkbox_bg = nil
theme.checkbox_border_color = nil
theme.checkbox_border_width = nil
theme.checkbox_check_border_color = nil
theme.checkbox_check_border_width = nil
theme.checkbox_check_color = nil
theme.checkbox_check_shape = nil
theme.checkbox_color = nil
theme.checkbox_paddings = nil
theme.checkbox_shape = nil
theme.column_count = nil
theme.cursor_mouse_move = nil
theme.cursor_mouse_resize = nil
theme.enable_spawn_cursor = nil

theme.flex_height = nil

theme.fullscreen_hide_border = nil

theme.gap_single_client = nil

theme.graph_bg = nil
theme.graph_border_color = nil
theme.graph_fg = nil

theme.hotkeys_bg = nil
theme.hotkeys_border_color = nil
theme.hotkeys_border_width = nil
theme.hotkeys_description_font = nil
theme.hotkeys_fg = nil
theme.hotkeys_font = nil
theme.hotkeys_group_margin = nil
theme.hotkeys_label_bg = nil
theme.hotkeys_label_fg = nil
theme.hotkeys_modifiers_fg = nil
theme.hotkeys_shape = nil

theme.icon_theme = nil

theme.layout_cornerne = nil
theme.layoutlist_align = nil
theme.layoutlist_bg_normal = nil
theme.layoutlist_bg_selected = nil
theme.layoutlist_disable_icon = nil
theme.layoutlist_disable_name = nil
theme.layoutlist_fg_normal = nil
theme.layoutlist_fg_selected = nil
theme.layoutlist_font = nil
theme.layoutlist_font_selected = nil
theme.layoutlist_shape = nil
theme.layoutlist_shape_border_color = nil
theme.layoutlist_shape_border_color_selected = nil
theme.layoutlist_shape_border_width = nil
theme.layoutlist_shape_border_width_selected = nil
theme.layoutlist_shape_selected = nil
theme.layoutlist_spacing = nil
theme.master_count = nil
theme.master_fill_policy = nil
theme.master_width_factor = nil
theme.maximized_hide_border = nil
theme.maximized_honor_padding = nil

theme.menu_bg_focus = nil
theme.menu_bg_normal = nil
theme.menu_border_color = nil
theme.menu_border_width = nil
theme.menu_fg_focus = nil
theme.menu_fg_normal = nil
theme.menu_font = nil
theme.menu_submenu = nil

theme.menubar_bg_focus = nil
theme.menubar_bg_normal = nil
theme.menubar_border_color = nil
theme.menubar_border_width = nil
theme.menubar_fg_focus = nil
theme.menubar_fg_normal = nil
theme.menubar_font = nil

theme.notification_action_bg_normal = nil
theme.notification_action_bg_selected = nil
theme.notification_action_bgimage_normal = nil
theme.notification_action_bgimage_selected = nil
theme.notification_action_fg_normal = nil
theme.notification_action_fg_selected = nil
theme.notification_action_icon_only = nil
theme.notification_action_icon_size_normal = nil
theme.notification_action_icon_size_selected = nil
theme.notification_action_label_only = nil
theme.notification_action_shape_border_color_normal = nil
theme.notification_action_shape_border_color_selected = nil
theme.notification_action_shape_border_width_normal = nil
theme.notification_action_shape_border_width_selected = nil
theme.notification_action_shape_normal = nil
theme.notification_action_shape_selected = nil
theme.notification_action_underline_normal = nil
theme.notification_action_underline_selected = nil
theme.notification_bg = nil
theme.notification_bg_normal = nil
theme.notification_bg_selected = nil
theme.notification_bgimage_normal = nil
theme.notification_bgimage_selected = nil
theme.notification_border_color = nil
theme.notification_border_width = nil
theme.notification_fg = nil
theme.notification_fg_normal = nil
theme.notification_fg_selected = nil
theme.notification_font = nil
theme.notification_height = nil
theme.notification_icon_resize_strategy = nil
theme.notification_icon_size = nil
theme.notification_icon_size_normal = nil
theme.notification_icon_size_selected = nil
theme.notification_margin = nil
theme.notification_max_width = nil
theme.notification_opacity = nil
theme.notification_position = nil
theme.notification_shape = nil
theme.notification_shape_border_color_normal = nil
theme.notification_shape_border_color_selected = nil
theme.notification_shape_border_width_normal = nil
theme.notification_shape_border_width_selected = nil
theme.notification_shape_normal = nil
theme.notification_shape_selected = nil
theme.notification_spacing = nil
theme.notification_width = nil

theme.opacity_active = nil
theme.opacity_floating = nil
theme.opacity_floating_active = nil
theme.opacity_floating_new = nil
theme.opacity_floating_normal = nil
theme.opacity_floating_urgent = nil
theme.opacity_fullscreen = nil
theme.opacity_fullscreen_active = nil
theme.opacity_fullscreen_new = nil
theme.opacity_fullscreen_normal = nil
theme.opacity_fullscreen_urgent = nil
theme.opacity_maximized = nil
theme.opacity_maximized_active = nil
theme.opacity_maximized_new = nil
theme.opacity_maximized_normal = nil
theme.opacity_maximized_urgent = nil
theme.opacity_new = nil
theme.opacity_normal = nil
theme.opacity_urgent = nil

theme.piechart_border_color = nil
theme.piechart_border_width = nil
theme.piechart_colors = nil

theme.progressbar_bar_border_color = nil
theme.progressbar_bar_border_width = nil
theme.progressbar_bar_shape = nil
theme.progressbar_bg = nil
theme.progressbar_border_color = nil
theme.progressbar_border_width = nil
theme.progressbar_fg = nil
theme.progressbar_margins = nil
theme.progressbar_paddings = nil
theme.progressbar_shape = nil

theme.prompt_bg = nil
theme.prompt_bg_cursor = nil
theme.prompt_fg = nil
theme.prompt_fg_cursor = nil
theme.prompt_font = nil

theme.radialprogressbar_border_color = nil
theme.radialprogressbar_border_width = nil
theme.radialprogressbar_color = nil
theme.radialprogressbar_paddings = nil

theme.screenshot_frame_color = nil
theme.screenshot_frame_shape = nil

theme.separator_border_color = nil
theme.separator_border_width = nil
theme.separator_color = nil
theme.separator_shape = nil
theme.separator_span_ratio = nil
theme.separator_thickness = nil

theme.slider_bar_active_color = nil
theme.slider_bar_border_color = nil
theme.slider_bar_border_width = nil
theme.slider_bar_color = nil
theme.slider_bar_height = nil
theme.slider_bar_margins = nil
theme.slider_bar_shape = nil
theme.slider_handle_border_color = nil
theme.slider_handle_border_width = nil
theme.slider_handle_color = nil
theme.slider_handle_cursor = nil
theme.slider_handle_margins = nil
theme.slider_handle_shape = nil
theme.slider_handle_width = nil

theme.snap_bg = nil
theme.snap_border_width = nil
theme.snap_shape = nil
theme.snapper_gap = nil

theme.systray_icon_spacing = dpi(2)
theme.systray_max_rows = nil

theme.taglist_bg_empty = color.bg
theme.taglist_bg_focus = color.grey1
theme.taglist_bg_occupied = nil
theme.taglist_bg_urgent = color.soft_red
theme.taglist_bg_volatile = nil
theme.taglist_disable_icon = nil
theme.taglist_fg_empty = color.fg
theme.taglist_fg_focus = color.soft_yellow
theme.taglist_fg_occupied = color.orange
theme.taglist_fg_urgent = color.fg
theme.taglist_fg_volatile = nil
theme.taglist_font = nil
theme.taglist_shape = nil
theme.taglist_shape_border_color = nil
theme.taglist_shape_border_color_empty = nil
theme.taglist_shape_border_color_focus = nil
theme.taglist_shape_border_color_urgent = nil
theme.taglist_shape_border_color_volatile = nil
theme.taglist_shape_border_width = nil
theme.taglist_shape_border_width_empty = nil
theme.taglist_shape_border_width_focus = nil
theme.taglist_shape_border_width_urgent = nil
theme.taglist_shape_border_width_volatile = nil
theme.taglist_shape_empty = nil
theme.taglist_shape_focus = nil
theme.taglist_shape_urgent = nil
theme.taglist_shape_volatile = nil
theme.taglist_spacing = nil
theme.taglist_squares_resize = nil
theme.taglist_squares_sel = nil
theme.taglist_squares_sel_empty = nil
theme.taglist_squares_unsel = nil
theme.taglist_squares_unsel_empty = nil

theme.tasklist_above = nil
theme.tasklist_align = nil
theme.tasklist_below = nil
theme.tasklist_bg_focus = nil
theme.tasklist_bg_image_focus = nil
theme.tasklist_bg_image_minimize = nil
theme.tasklist_bg_image_normal = nil
theme.tasklist_bg_image_urgent = nil
theme.tasklist_bg_minimize = nil
theme.tasklist_bg_normal = nil
theme.tasklist_bg_urgent = nil
theme.tasklist_disable_task_name = nil
theme.tasklist_fg_focus = nil
theme.tasklist_fg_minimize = nil
theme.tasklist_fg_normal = nil
theme.tasklist_fg_urgent = nil
theme.tasklist_floating = nil
theme.tasklist_font = nil
theme.tasklist_font_focus = nil
theme.tasklist_font_minimized = nil
theme.tasklist_font_urgent = nil
theme.tasklist_icon_size = nil
theme.tasklist_maximized = nil
theme.tasklist_maximized_horizontal = nil
theme.tasklist_maximized_vertical = nil
theme.tasklist_minimized = nil
theme.tasklist_ontop = nil
theme.tasklist_plain_task_name = nil
theme.tasklist_shape = nil
theme.tasklist_shape_border_color = nil
theme.tasklist_shape_border_color_focus = nil
theme.tasklist_shape_border_color_minimized = nil
theme.tasklist_shape_border_color_urgent = nil
theme.tasklist_shape_border_width = nil
theme.tasklist_shape_border_width_focus = nil
theme.tasklist_shape_border_width_minimized = nil
theme.tasklist_shape_border_width_urgent = nil
theme.tasklist_shape_focus = nil
theme.tasklist_shape_minimized = nil
theme.tasklist_shape_urgent = nil
theme.tasklist_spacing = nil
theme.tasklist_sticky = nil

theme.titlebar_bg = nil
theme.titlebar_bg_focus = nil
theme.titlebar_bg_normal = nil
theme.titlebar_bg_urgent = nil
theme.titlebar_bgimage = nil
theme.titlebar_bgimage_focus = nil
theme.titlebar_bgimage_normal = nil
theme.titlebar_bgimage_urgent = nil
theme.titlebar_close_button_focus_hover = nil
theme.titlebar_close_button_focus_press = nil
theme.titlebar_close_button_normal_hover = nil
theme.titlebar_close_button_normal_press = nil
theme.titlebar_fg = nil
theme.titlebar_fg_focus = nil
theme.titlebar_fg_normal = nil
theme.titlebar_fg_urgent = nil
theme.titlebar_floating_button_focus = nil
theme.titlebar_floating_button_focus_active_hover = nil
theme.titlebar_floating_button_focus_active_press = nil
theme.titlebar_floating_button_focus_inactive_hover = nil
theme.titlebar_floating_button_focus_inactive_press = nil
theme.titlebar_floating_button_normal = nil
theme.titlebar_floating_button_normal_active_hover = nil
theme.titlebar_floating_button_normal_active_press = nil
theme.titlebar_floating_button_normal_inactive_hover = nil
theme.titlebar_floating_button_normal_inactive_press = nil
theme.titlebar_maximized_button_focus = nil
theme.titlebar_maximized_button_focus_active_hover = nil
theme.titlebar_maximized_button_focus_active_press = nil
theme.titlebar_maximized_button_focus_inactive_hover = nil
theme.titlebar_maximized_button_focus_inactive_press = nil
theme.titlebar_maximized_button_normal = nil
theme.titlebar_maximized_button_normal_active_hover = nil
theme.titlebar_maximized_button_normal_active_press = nil
theme.titlebar_maximized_button_normal_inactive_hover = nil
theme.titlebar_maximized_button_normal_inactive_press = nil
theme.titlebar_minimize_button_focus_hover = nil
theme.titlebar_minimize_button_focus_press = nil
theme.titlebar_minimize_button_normal_hover = nil
theme.titlebar_minimize_button_normal_press = nil
theme.titlebar_ontop_button_focus = nil
theme.titlebar_ontop_button_focus_active_hover = nil
theme.titlebar_ontop_button_focus_active_press = nil
theme.titlebar_ontop_button_focus_inactive_hover = nil
theme.titlebar_ontop_button_focus_inactive_press = nil
theme.titlebar_ontop_button_normal = nil
theme.titlebar_ontop_button_normal_active_hover = nil
theme.titlebar_ontop_button_normal_active_press = nil
theme.titlebar_ontop_button_normal_inactive_hover = nil
theme.titlebar_ontop_button_normal_inactive_press = nil
theme.titlebar_sticky_button_focus = nil
theme.titlebar_sticky_button_focus_active_hover = nil
theme.titlebar_sticky_button_focus_active_press = nil
theme.titlebar_sticky_button_focus_inactive_hover = nil
theme.titlebar_sticky_button_focus_inactive_press = nil
theme.titlebar_sticky_button_normal = nil
theme.titlebar_sticky_button_normal_active_hover = nil
theme.titlebar_sticky_button_normal_active_press = nil
theme.titlebar_sticky_button_normal_inactive_hover = nil
theme.titlebar_sticky_button_normal_inactive_press = nil
theme.titlebar_tooltip_align = nil
theme.titlebar_tooltip_delay_show = nil
theme.titlebar_tooltip_margins_leftright = nil
theme.titlebar_tooltip_margins_topbottom = nil
theme.titlebar_tooltip_messages_close = nil
theme.titlebar_tooltip_messages_floating_active = nil
theme.titlebar_tooltip_messages_floating_inactive = nil
theme.titlebar_tooltip_messages_maximized_active = nil
theme.titlebar_tooltip_messages_maximized_inactive = nil
theme.titlebar_tooltip_messages_minimize = nil
theme.titlebar_tooltip_messages_ontop_active = nil
theme.titlebar_tooltip_messages_ontop_inactive = nil
theme.titlebar_tooltip_messages_sticky_active = nil
theme.titlebar_tooltip_messages_sticky_inactive = nil
theme.titlebar_tooltip_timeout = nil

theme.tooltip_align = nil
theme.tooltip_bg = nil
theme.tooltip_border_color = nil
theme.tooltip_border_width = nil
theme.tooltip_fg = nil
theme.tooltip_font = nil
theme.tooltip_gaps = nil
theme.tooltip_opacity = nil
theme.tooltip_shape = nil

theme.wallpaper_bg = nil
theme.wallpaper_fg = nil

theme.wibar_align = nil
theme.wibar_bg = color.bg
theme.wibar_bgimage = nil
theme.wibar_border_color = nil
theme.wibar_border_width = nil
theme.wibar_cursor = nil
theme.wibar_favor_vertical = false
theme.wibar_fg = color.fg
theme.wibar_height = theme.useless_gap * 5
theme.wibar_margins = {
  top = theme.useless_gap * 2,
  left = theme.useless_gap * 2,
  right = theme.useless_gap * 2,
}
theme.wibar_ontop = false
theme.wibar_opacity = nil
theme.wibar_shape = gears.shape.rectangle
theme.wibar_stretch = nil
theme.wibar_type = nil
theme.wibar_width = nil

return theme

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
