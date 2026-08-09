#!/usr/bin/env python3
"""Regenerate the derived variant files in variants/ from main.

Most variants are main's file with later-chapter material subtracted; the
rc.lua chain additionally starts from the pre-simplification chapter trees
pinned by the archive/2026-08-old-ladder tag and applies every change the
simplification pass made to rc.lua.

Run from the ladder-build worktree after changing code on main:
    ./derive.py && stylua variants/ (see note) && ./build.sh && ./verify.sh
stylua note: variants have an @ in their names; format via a temp copy or
`stylua --config-path .stylua.toml` on each file (build.sh does not format).

Static variants NOT produced here (edit by hand):
    clock.lua@03, widgets-init.lua@{03,04,07,08}
"""

import re
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
VAR = HERE / "variants"
REPO = subprocess.run(
    ["git", "rev-parse", "--path-format=absolute", "--git-common-dir"],
    cwd=HERE, capture_output=True, text=True, check=True,
).stdout.strip().removesuffix("/.git")


def git_show(ref: str, path: str) -> str:
    return subprocess.run(
        ["git", "show", f"{ref}:{path}"],
        cwd=REPO, capture_output=True, text=True, check=True,
    ).stdout


def must_sub(s: str, old: str, new: str, what: str) -> str:
    if old not in s:
        sys.exit(f"FAIL: pattern for {what!r} not found")
    return s.replace(old, new)


def main_file(path: str) -> str:
    return git_show("main", path)


# --------------------------------------------------------------------------
# keybindings.lua@NN: main's file minus the modules that don't exist yet
# --------------------------------------------------------------------------
def derive_keybindings():
    src = main_file("keybindings.lua")

    req = {
        "dashboard": 'local dashboard = require("dashboard")\n',
        "launcher": 'local launcher = require("launcher")\n',
        "exitscreen": 'local exitscreen = require("exitscreen")\n',
        "notifications": 'local notifications = require("notifications")\n',
        "mainmenu": 'local mainmenu = require("widgets.mainmenu")\n',
        "windowswitcher": 'local windowswitcher = require("widgets.windowswitcher")\n',
    }

    def find_line(pattern):
        m = re.search(pattern, src, re.M)
        assert m, pattern
        return m.group(0) + "\n"

    bind = {
        "dashboard": find_line(r"^.*dashboard\.toggle\(\).*$"),
        "notifications": find_line(r"^.*toggle_notification_center\(\).*$"),
        "launcher": find_line(r"^.*launcher\.toggle\(\).*$"),
        "mainmenu": find_line(r"^.*mainmenu\.toggle\(\).*$"),
        "windowswitcher": find_line(r"^.*windowswitcher\.show.*$"),
        "exitscreen": find_line(r"^.*exitscreen\.toggle\(\).*$"),
    }

    def strip(names):
        s = src
        for n in names:
            s = must_sub(s, req[n], "", f"require {n}")
            s = must_sub(s, bind[n], "", f"binding {n}")
        return s

    variants = {
        "02": ["dashboard", "launcher", "exitscreen", "notifications", "mainmenu", "windowswitcher"],
        "06": ["dashboard", "launcher", "exitscreen", "mainmenu", "windowswitcher"],
        "07": ["dashboard", "launcher", "mainmenu", "windowswitcher"],
        "08": ["dashboard", "launcher", "windowswitcher"],
        "09": ["dashboard", "launcher"],
        "10": ["dashboard"],
    }
    for nn, removed in variants.items():
        v = strip(removed)
        if nn == "02":
            v = v.replace("\n-- Load our custom modules\n", "\n")
        (VAR / f"keybindings.lua@{nn}").write_text(v)
        print(f"keybindings.lua@{nn}")


# --------------------------------------------------------------------------
# rc.lua@NN: pre-simplification chapter file + every simplification change
# --------------------------------------------------------------------------
OLD = "archive/2026-08-old-ladder"
OLD_DEPTH = {"00": 12, "01": 11, "02": 10, "03": 9, "04": 8, "05": 7, "06": 6, "08": 4}

WALLPAPER_COMMENT = """  -- awful.wallpaper({
  --   screen = s,
  --   widget = {
  --     {
  --       image = beautiful.wallpaper,
  --       upscale = true,
  --       downscale = true,
  --       widget = wibox.widget.imagebox,
  --     },
  --     valign = "center",
  --     halign = "center",
  --     tiled = false,
  --     widget = wibox.container.tile,
  --   },
  -- })
"""

SPOTIFY_RULE = """
  -- Spotify: Force to "db" tag (closest to media)
  ruled.client.append_rule({
    id = "spotify",
    rule = { class = "Spotify" },
    properties = { tag = "db" },
  })
"""

FADE_COMMENT = """      -- Uncomment to fade every window slightly. It looks nice over a wallpaper and it
      -- is confusing the first time a screenshot comes out washed out, so it is off by
      -- default.
"""


def derive_rc():
    main_rc = main_file("rc.lua")
    tags_block = re.search(r"\n-- The workspaces, defined once.*?^}\n", main_rc, re.S | re.M).group(0)
    tag_create = re.search(
        r"  -- Create this screen's tags from the table defined at the top\n.*?  end\n\n", main_rc, re.S
    ).group(0)

    for nn, depth in OLD_DEPTH.items():
        n = int(nn)
        s = git_show(f"{OLD}~{depth}", "rc.lua")

        if n >= 1:
            s = s.replace('config_dir .. "theme/spaceman.jpg"', 'config_dir .. "wallpapers/spaceman.jpg"')
            s = s.replace(WALLPAPER_COMMENT, "")
        if n >= 2:
            # keybindings.lua owns bindings now, and it dropped the menubar
            # binding, so the require and config lines are vestigial
            s = s.replace('local menubar = require("menubar")\n', "")
            s = s.replace(
                "\n-- Menubar configuration\nmenubar.utils.terminal = terminal"
                " -- Set the terminal for applications that require it\n", "\n")
            s = s.replace(
                "menubar.utils.terminal = terminal -- Set the terminal for applications that require it\n", "")
        if n == 3:
            s = must_sub(s, "widgets.battery,", "widgets.battery.widget,", "battery widget @03")
        if n >= 4:
            anchor = 'modkey = "Mod4"\n'
            s = must_sub(s, anchor, anchor + tags_block, "tags table")
            dd = 'screen.connect_signal("request::desktop_decoration", function(s)\n'
            s = must_sub(s, dd, dd + tag_create, "tag creation")
            # the custom wibar replaced the stock bar; the tasklist would be
            # built and never displayed
            m = re.search(
                r"\n  -- @TASKLIST_BUTTON@\n  -- Create a tasklist widget\n"
                r"  s\.mytasklist = awful\.widget\.tasklist\(\{.*?\n  \}\)\n", s, re.S)
            assert m, f"tasklist block @{nn}"
            s = s.replace(m.group(0), "\n")
        if n >= 5:
            s = s.replace(
                "  -- DEMO RULES: Showcasing AwesomeWM capabilities\n"
                "  -- ==========================================",
                "  -- Example rules: routing and shaping specific apps. Each one demonstrates a\n"
                "  -- different piece of ruled.client - swap the class names for your own apps.")
            s = s.replace("      -- opacity = 0.85,\n", "")
            s = s.replace(SPOTIFY_RULE, "")
            s = s.replace(FADE_COMMENT, "")
        if n >= 8:
            s = s.replace("mymainmenu:toggle()", "mymainmenu.toggle()")

        (VAR / f"rc.lua@{nn}").write_text(s)
        print(f"rc.lua@{nn}")


# --------------------------------------------------------------------------
# wibar.lua@04 / @07: main's bar minus menubutton (@04, @07) and power (@04)
# --------------------------------------------------------------------------
def derive_wibar():
    src = main_file("wibar.lua")
    no_menubutton = must_sub(
        src,
        """        widgets.menubutton,
        widgets.wrappers.vertical_separator(beautiful.wibar_height * 0.5),
        widgets.taglist(s),""",
        """        widgets.wrappers.vertical_separator(beautiful.wibar_height * 0.5),
        widgets.taglist(s),""",
        "wibar menubutton")
    (VAR / "wibar.lua@07").write_text(no_menubutton)
    print("wibar.lua@07")

    no_power = must_sub(
        no_menubutton,
        """        widgets.wrappers.vertical_separator(beautiful.wibar_height * 0.5),
        widgets.power,
        layout = wibox.layout.fixed.horizontal,""",
        """        layout = wibox.layout.fixed.horizontal,""",
        "wibar power")
    (VAR / "wibar.lua@04").write_text(no_power)
    print("wibar.lua@04")


# --------------------------------------------------------------------------
# mainmenu.lua@08 / @10 and exitscreen-init.lua@07: strip Lock / launcher
# --------------------------------------------------------------------------
def derive_menus():
    src = main_file("widgets/mainmenu.lua")
    apps_item = (
        '  { type = "item", icon = "\U000F003B", label = "Apps", action = "launcher" },\n'
        '  { type = "separator" },\n')
    lock_item = '  { type = "item", icon = "\U000F033E", label = "Lock", action = "lock" },\n'
    lock_exec = '  elseif item.action == "lock" then\n    awesome.lock()\n'
    launcher_exec = '  elseif item.action == "launcher" then\n    require("launcher").show()\n'

    v10 = must_sub(src, lock_item, "", "mainmenu lock item")
    v10 = must_sub(v10, lock_exec, "", "mainmenu lock exec")
    (VAR / "mainmenu.lua@10").write_text(v10)
    print("mainmenu.lua@10")

    v08 = must_sub(v10, apps_item, "", "mainmenu apps item")
    v08 = must_sub(v08, launcher_exec, "", "mainmenu launcher exec")
    (VAR / "mainmenu.lua@08").write_text(v08)
    print("mainmenu.lua@08")

    exi = main_file("exitscreen/init.lua")
    lock_option = (
        "  {\n"
        '    name = "Lock",\n'
        '    icon = "\U000F033E",\n'
        '    key = "l",\n'
        "    command = function()\n"
        "      awesome.lock()\n"
        "    end,\n"
        "  },\n")
    (VAR / "exitscreen-init.lua@07").write_text(must_sub(exi, lock_option, "", "exitscreen lock option"))
    print("exitscreen-init.lua@07")


# --------------------------------------------------------------------------
# notifications.lua@06: main's file with the modal controllers hand-rolled
# --------------------------------------------------------------------------
def derive_notifications():
    src = main_file("notifications.lua")
    src = must_sub(src, 'local modal = require("modal")\n', "", "modal require")

    src = must_sub(
        src,
        '-- Snooze duration picker: a small modal anchored near the mouse. The modal\n'
        '-- controller supplies click-outside dismissal, so the old "connect a one-shot\n'
        '-- button::press handler after a 0.1s delay" workaround is gone.\n'
        "local picker_notif_data = nil\n",
        "-- Snooze duration picker: a small popup anchored near the mouse\n"
        "local picker_notif_data = nil\n"
        "local snooze_picker_popup = nil\n",
        "picker header")

    old_picker = re.search(
        r"M\.snooze_picker = modal\.new\(\{.*?\n\}\)\n\n"
        r"local function show_snooze_picker\(notif_data\)\n.*?\nend\n",
        src, re.S)
    assert old_picker, "picker modal block"
    new_picker = """M.hide_snooze_picker = function()
  if snooze_picker_popup then
    snooze_picker_popup.visible = false
    snooze_picker_popup = nil
  end
end

local function show_snooze_picker(notif_data)
  picker_notif_data = notif_data
  M.hide_snooze_picker()

  local s = awful.screen.focused()
  snooze_picker_popup = awful.popup({
    widget = build_picker_widget(),
    screen = s,
    ontop = true,
    visible = true,
    bg = "#00000000",
    border_width = beautiful.border_width or 1,
    border_color = beautiful.primary_color,
    shape = beautiful.shape or gears.shape.rectangle,
  })

  -- Position near mouse
  local coords = mouse.coords()
  snooze_picker_popup.x = coords.x - 80
  snooze_picker_popup.y = coords.y + 10

  -- Keep on screen
  if snooze_picker_popup.x + 200 > s.geometry.x + s.geometry.width then
    snooze_picker_popup.x = s.geometry.x + s.geometry.width - 210
  end
  if snooze_picker_popup.x < s.geometry.x then
    snooze_picker_popup.x = s.geometry.x + 10
  end

  -- Close on click outside. The handler has to be connected *after* this
  -- click finishes (hence the timer), and has to disconnect itself - an
  -- awkward dance every popup in this config ends up re-inventing.
  gears.timer.start_new(0.1, function()
    local close_handler
    close_handler = function()
      M.hide_snooze_picker()
      client.disconnect_signal("button::press", close_handler)
    end
    client.connect_signal("button::press", close_handler)
    return false
  end)
end
"""
    src = src.replace(old_picker.group(0), new_picker)

    src = must_sub(
        src,
        """    btn:add_button(awful.button({}, 1, function()
      M.snooze_picker.hide()
      snooze_notification(picker_notif_data, duration.seconds, duration.label)
    end))""",
        """    btn:add_button(awful.button({}, 1, function()
      M.hide_snooze_picker()
      snooze_notification(picker_notif_data, duration.seconds, duration.label)
    end))""",
        "picker button hide")

    start = src.index("-- The notification center is a modal like")
    end_ = src.index("-- Setup notification rules")
    new_center = """-- The notification center popup: show/hide/toggle, plus dismissal when you
-- click a client or switch tags. The same lifecycle the dashboard hand-rolls;
-- keep an eye on how similar this shape is.
local notification_popup = nil
local popup_visible = false

function M.show_notification_center()
  if popup_visible then
    return
  end

  local s = awful.screen.focused()

  if not notification_popup then
    notification_popup = awful.popup({
      widget = create_popup_widget(),
      screen = s,
      ontop = true,
      visible = false,
      bg = "#00000000",
      border_width = beautiful.border_width or 1,
      border_color = beautiful.primary_color,
      shape = beautiful.shape or gears.shape.rounded_rect,
    })
  end

  notification_popup.screen = s
  notification_popup.widget = create_popup_widget()

  -- Position centered under the click point (use mouse coords for
  -- multi-monitor reliability)
  local coords = mouse.coords()
  local popup_x = coords.x - (nc_config.width / 2)
  local popup_y = (beautiful.wibar_height or 30) + (beautiful.useless_gap or 4)

  -- Keep popup on screen
  if popup_x < s.geometry.x then
    popup_x = s.geometry.x + (beautiful.useless_gap or 4)
  elseif popup_x + nc_config.width > s.geometry.x + s.geometry.width then
    popup_x = s.geometry.x + s.geometry.width - nc_config.width - (beautiful.useless_gap or 4)
  end

  notification_popup.x = popup_x
  notification_popup.y = s.geometry.y + popup_y

  notification_popup.visible = true
  popup_visible = true
  awesome.emit_signal("notification_center::visible", true)
end

function M.hide_notification_center()
  if not popup_visible then
    return
  end

  if notification_popup then
    notification_popup.visible = false
  end
  popup_visible = false
  awesome.emit_signal("notification_center::visible", false)
end

function M.toggle_notification_center()
  if popup_visible then
    M.hide_notification_center()
  else
    M.show_notification_center()
  end
end

-- Refresh popup content (safe to call any time; does nothing while hidden)
refresh_popup = function()
  if notification_popup and popup_visible then
    notification_popup.widget = create_popup_widget()
  end
end

-- Close on click outside (the dashboard does the same dance)
client.connect_signal("button::press", function()
  if popup_visible then
    M.hide_notification_center()
  end
end)

tag.connect_signal("property::selected", function()
  if popup_visible then
    M.hide_notification_center()
  end
end)

"""
    src = src[:start] + new_center + src[end_:]
    (VAR / "notifications.lua@06").write_text(src)
    print("notifications.lua@06")


derive_keybindings()
derive_rc()
derive_wibar()
derive_menus()
derive_notifications()
print("done")
