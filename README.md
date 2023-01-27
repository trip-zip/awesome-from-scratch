###### Table of Contents
* [Section 0 - Default Config](https://github.com/trip-zip/awesome-from-scratch/tree/00-default)
* [Section 1 - Theme](https://github.com/trip-zip/awesome-from-scratch/tree/01-theme)
* [Section 2 - Keybindings](https://github.com/trip-zip/awesome-from-scratch/tree/02-keybindings)
* [Section 3 - Wibar](https://github.com/trip-zip/awesome-from-scratch/tree/03-wibar)
* [Section 4 - Notifications](https://github.com/trip-zip/awesome-from-scratch/tree/04-notifications)
* Section 5 - Titlebars
* Section 6 - Logout Screen
* ??



## Wibar
* Let's try to make this wibar something worth having at the top of the screen permanently.
* I think the polybar themes that [adi1090x made](https://github.com/adi1090x/polybar-themes) are really great looking, I'll try (and fail) to copy one of those more or less.
* They use the [IcoMoon icons](https://github.com/Keyamoon/IcoMoon-Free).  I recommend you grab the free pack and download those.  Otherwise use your favorite icon set.
* Side note: I've found that in terms of centering and aligning icons in awesomewm, I nearly always prefer to use svgs over nerd fonts.  The svgs have more consistent height/width and I know exactly what I'm resizing and getting into.
* You CAN hypothetically do all this with nerd font icons and textboxes...but circle back to this setup when you spend 10 hours trying to halign a textbox but the right side never quite has the margin you want...I'm here for you.  Shhh.  The glyphs can't hurt you anymore...it's OK.

### Theme Variables
* First, let's just take a look at the wibar theme variables.
```
theme.wibar_align = nil
theme.wibar_bg = nil
theme.wibar_bgimage = nil
theme.wibar_border_color = nil
theme.wibar_border_width = nil
theme.wibar_cursor = nil
theme.wibar_favor_vertical = nil
theme.wibar_fg = nil
theme.wibar_height = nil
theme.wibar_margins = nil
theme.wibar_ontop = nil
theme.wibar_opacity = nil
theme.wibar_shape = nil
theme.wibar_stretch = nil
theme.wibar_type = nil
theme.wibar_width = nil
```
* We get some pretty easy controls out of the box.
* I'm going to tweak just a few and set the rest as their default so it's clear what the value is, not just `nil`.  I mean, some default are actually `nil`, but it can be useful to know which ones are actually `nil` vs which ones have real values associated with them hidden behind the scenes.  I'll comment which ones are the default values.
* These are the only variables I want to set for now.  I like a little bit larger wibar.
```
theme.wibar_bg = color.bg
theme.wibar_fg = color.fg
theme.wibar_height = theme.useless_gap * 5 or dpi(32)
theme.wibar_margins = theme.useless_gap * 2
theme.wibar_shape = gears.shape.rectangle
```
* Typically I like using a factor of my useless_gap as the basis for lots of these margin/size/position settings because it looks more intentional in my opinion.  That kind of breaks down if you want to mess with your gaps TOO much...so it might make sense to set your wibar_height to something sensible and unchanging.  But for me, I usually only switch between gaps of 6, 8, or 10px, which all look acceptable on my screen.  Just be aware of what you want there.
* Multiplying the useless_gap by 2 makes sure the left and right margin of the wibar come out to the same as the gap between clients and the outside borders of the screen.
* The downside is that there is too large of a gap between the wibar and the clients.  So it doesn't look identical from a gap perspective.
* So if you REALLY want it to feel precise, you can set the wibar_margins like this:

```
theme.wibar_margins = {
    top = theme.useless_gap * 2,
    left = theme.useless_gap * 2,
    right = theme.useless_gap * 2,
}
```

### Refactoring the layout

* I'll to move all the wibar stuff out to its own file to stop cluttering the main rc.lua
* Let's remove all the widgets from the wibar so we can add each piece as we want it.
* Pro Tip: If you're working with new widgets and layouts, it can sometimes be very useful to add borders so you can see how the layout will go.


### I want a widget container that I can add icons/text into so each widget in the bar looks identical
* I think a simple setup like:
wibox.container.background -- For coloring a background shape easily
-> wibox.container.margin  -- For fitting the image/text 
  -> wibox.widget.imagebox -- The final image
should be enough for now.
* We can shape and set colors.
* Maybe even pass in the widget and the background color as a function, then it'll return the widget styled and ready to place in the Wibar
* But basically, this is a quick mockup of what I want it to do.  Just a real simple wibar that contains some squares with icons
```
  local wibar = awful.wibar({
    expand = "none",
    position = "top",
    screen = s,
    widget = {
      {
        {
          {
            {
              {
                image = recolor(theme_path .. "/launcher.svg", beautiful.bg_normal),
                widget = wibox.widget.imagebox,
                halign = "center",
                valign = "center",
              },
              bg = beautiful.bg_normal,
              widget = wibox.container.background,
            },
            margins = beautiful.wibar_height / 4,
            widget = wibox.container.margin,
          },
          bg = beautiful.bg_normal,
          fg = beautiful.fg_normal,
          shape = gears.shape.rectangle,
          widget = wibox.container.background,
        },
        layout = wibox.layout.align.horizontal,
      },
      {
        {
          {
            {
              image = recolor(theme_path .. "/volume.svg", beautiful.bg_normal),
              widget = wibox.widget.imagebox,
              halign = "center",
              valign = "center",
            },
            bg = ,
            widget = wibox.container.background,
          },
          margins = beautiful.wibar_height / 4,
          widget = wibox.container.margin,
        },
        bg = beautiful.bg_normal,
        fg = beautiful.fg_normal,
        shape = gears.shape.rectangle,
        widget = wibox.container.background,
      },
      {
        {
          {
            {
              {
                image = recolor(theme_path .. "/power.svg", beautiful.bg_normal),
                widget = wibox.widget.imagebox,
                halign = "center",
                valign = "center",
              },
              bg = ,
              widget = wibox.container.background,
            },
            margins = beautiful.wibar_height / 4,
            widget = wibox.container.margin,
          },
          bg = beautiful.bg_normal,
          fg = beautiful.fg_normal,
          shape = gears.shape.rectangle,
          widget = wibox.container.background,
        },
        layout = wibox.layout.align.horizontal,
      },
      layout = wibox.layout.align.horizontal,
    },
  })
```
* We can add more of them to whichever side looks good and abstract the margin and imagebox widgets out so we can just reuse it everywhere we need.

### Quick Refactor
#### Widget
* This is kind of the core widget right here.  This layout is what I want my wibar widgets to really be.  A bunch of simple icons fit neatly into a margin so it's spaced evenly, then wrapped in a background so they can have their own colors.
```
{
  {
    {
      image = recolor(theme_path .. "/volume.svg", beautiful.fg_normal),
      widget = wibox.widget.imagebox,
      halign = "center",
      valign = "center",
    },
    margins = beautiful.wibar_height / 4,
    widget = wibox.container.margin,
  },
  bg = beautiful.bg_normal,
  fg = beautiful.fg_normal,
  shape = gears.shape.rectangle,
  widget = wibox.container.background,
},
```

* I will create each widget as the imagebox, then set its value based on a simple shell script. EZ PZ
* First, let's make a little function that returns a background widget.  This one will be the launcher, tag icons, and power menu button, and probably volume/wifi/etc.
```
local square_icon = function(w, color)
  return wibox.widget({
      {
        w,
        margins = beautiful.wibar_height / 4,
        widget = wibox.container.margin,
      },
      bg = color,
      fg = beautiful.fg_normal,
      shape = gears.shape.rectangle,
      widget = wibox.container.background,
  })
end
```
* It accepts a widget of any kind, but I'm leaning towards the imagebox widgets for this first layout.
```
local image_widget = function(image, color)
  return wibox.widget({
    image = recolor(icon_dir .. image, color),
    widget = wibox.widget.imagebox,
    halign = "center",
    valign = "center",
  })
end
```
* Now we can create a new file for each widget type to keep the implementation separate for each one.  But in its more simple form, creating a clean looking wibar widget just looks like this:
```
local volume = image_widget("/grid.svg", beautiful.bg_normal)
local volume_widget = square_icon(launcher, beautiful.highlight)
```
* Then you add the volume_widget to the wibar.  Any functionality we want to affix to the launcher widget will be easily applied.

#### Let's finish up the widget
* We need to get the real volume value, of course.  I just want a simple icon that shows roughly the intensity of volume.
* The icons I have just have a mute, low volume, medium volume, and high volume variants.  So, we'll get close enough.
* For all these widgets, I just want to use a normal boring cli tool that gets output.  If you don't use pamixer, substitute the command that you DO like to get a simple volume percentage.
* awful.spawn.easy_async_with_shell is the function I pretty much always go to unless I specifically need a different spawn command.
```
  awful.spawn.easy_async_with_shell("pamixer --get-volume", function(vol)
    -- INFO: This stdout contains a \n character that messes up how the tooltip looks.
    volume_widget.tooltip.text = string.gsub(vol, "\n", "") .. "%"
    --INFO: The way pamixer works, if you increase volume, it does not break `mute`.  So I want to update the tooltip, but not the icon, that's why I have it nested instead of a separate function.
    awful.spawn.easy_async_with_shell("pamixer --get-mute", function(mute)
      if string.find(mute, "true") then
        volume.image = recolor(icon_dir .. "/volume-x.svg", beautiful.bg_normal)
      else
      local volume_level = tonumber(vol)
        if volume_level == 0 then
          volume.image = recolor(icon_dir .. "/volume-x.svg", beautiful.bg_normal)
        elseif volume_level <= 25 then
          volume.image = recolor(icon_dir .. "/volume.svg", beautiful.bg_normal)
        elseif volume_level <= 75 then
          volume.image = recolor(icon_dir .. "/volume-1.svg", beautiful.bg_normal)
        else
          volume.image = recolor(icon_dir .. "/volume-2.svg", beautiful.bg_normal)
        end
      end
    end)
  end)
```
* Basically, we need to make sure that
a) We have the volume and
b) We know if it's muted or not.
* When we get the value, it's as simple as just setting the image to whichever breakdown we want.
* Also, I want a little hover tooltip.  Thankfully, awesome has an awful.toolip widget that it super easy to attach.  We just add 1 little step to our call getting the volumes to format the string and set the tooltip.
* Now, when we press the keybindings for volume up and down, we want the icon to show reflect the real volume.
* We can do that with `awesome.emit_signal` and `awesome.connect_signal`.
* Update the keybindings to now only set the volume, but also emit a signal that volume was updated.
```
local media_helpers = {
  raise_volume = function()
    awful.spawn("pamixer -i 3")
    awesome.emit_signal("volume::update")
  end,
  lower_volume = function()
    awful.spawn("pamixer -d 3")
    awesome.emit_signal("volume::update")
  end,
  toggle_mute = function()
    awful.spawn("pamixer -t")
    awesome.emit_signal("volume::update")
  end,
}
```
* You could separate the mute one to its own signal and handle the mute logic separately, I might even do that in the future.  But pamixer doesn't turn mute to false when you increase/decrease volume, so I'm just planning on always checking both (at least for now).
* Now, we just need to `awesome.connect_signal` and update our volume icon widget.
* I'll wrap the easy_async_with_shell() call in a little function named `update_volume` and we're done.

```
awesome.connect_signal("volume::update", function()
  update_volume()
end)
```
* Now as you press the volume up/down keys, the tooltip stays accurate, and when you cross a threshold, the icon changes.
#### Repeat for the rest of the widgets.
* It's always the same steps for me.
    1. Create a simple widget.
    2. Place it where you want it.
    3. Set the real value on the first load.
    4. Use signals (or a watch widget if applicable) to KEEP it up to date.
    5. Style it (Optional)
* So, I'll just find the cli commands that will get me wifi data, battery life, and brightness.  Add that logic to each of those widgets, and we're done with the simple widget logic.

#### Wifi
* It's going to be the same story.  Instead of volume and mute, it's SSID and connected.  Instead of emitting signals on button clicks, I'll set a little timer to check every minute or so.
```
local function update()
  awful.spawn.easy_async_with_shell("iwgetid -r", function(stdout)
    wifi_widget.tooltip.text = stdout
    if string.find(stdout, "Not connected") then
      wifi.image = beautiful.icon_dir .. "/wifi-off.svg"
    else
      wifi.image = beautiful.icon_dir .. "/wifi.svg"
    end
  end)
end

gears.timer({
  timeout = 10,
  autostart = true,
  call_now = true,
  callback = update,
})
```

#### Battery, exacly the same.  We can make the tooltip prettier one day, but it's good enough for me.

#### Launcher might be the easiest.
* Just add a button that toggles the menu widget.

#### Taglist
* Stuff to work through
1. You can't really get just an icon based taglist to work how I want.  There aren't even beautiful theme values for taglist icons in the first place.
2. You can't just slap widgets as the icons or identifiers.  It's string or bust.
  I wish this would work...
```
  awful.tag.add("", {
    icon = icon_dir .. "/terminal.svg",
    layout = awful.layout.layouts[1],
    screen = s,
    selected = true,
  })
  awful.tag.add("", {
    icon = icon_dir .. "/chrome.svg",
    layout = awful.layout.layouts[1],
    screen = s,
    selected = false,
  })
  awful.tag.add("", {
    icon = icon_dir .. "/slack.svg",
    layout = awful.layout.layouts[1],
    screen = s,
    selected = false,
  })
  awful.tag.add("", {
    icon = icon_dir .. "/server.svg",
    layout = awful.layout.layouts[1],
    screen = s,
    selected = false,
  })
  awful.tag.add("", {
    icon = icon_dir .. "/play.svg",
    layout = awful.layout.layouts[1],
    screen = s,
    selected = false,
  })

```
  but it won't...

3. So it's a widget_template, which is a whole thing.  At the bottom of the widget system part of the docs has a small explanation of what a widget_template is.  https://awesomewm.org/apidoc/documentation/03-declarative-layout.md.html
```
However, there is a case where this isn't enough and another abstract widget has to be used. This concept is called the widget_template and is an optional property of many widgets such as the awful.widget.taglist, awful.widget.tasklist and naughty.layout.box. These templates are a table using the exact same syntax as the declarative widgets, but without the wibox.widget prefix in front of the curly braces. These templates represent future widgets that will be created by their parent widget. This is necessary for three reasons:

The widget must create many instances of the template at different points in time.
The widget data is only partially available and other fields must be set at a later time (by the parent widget).
The code is highly redundant and some of the logic is delegated to the parent widget to simplify everything.
```

  * Short story.  
  * A `widget_template` is basically a widget constructor
  ```
    widget_template = {
      {
        id = "indicator",
        wibox.widget.base.make_widget(),
        forced_height = 2,
        bg = beautiful.bg_normal,
        widget = wibox.container.background,
      },
      nil,
      {
        {
          id = "icon_role",
          widget = wibox.widget.imagebox,
        },
        margins = beautiful.wibar_height * 0.25,
        widget = wibox.container.margin,
      },
      layout = wibox.layout.fixed.vertical,
      create_callback = update_tag,
      update_callback = update_tag,
    },
  ```
  * One piece of hackery going on is that instead of just a single imagebox or even a margin wrapping an imagebox.  I am using a vertical layout with a small (mostly empty) background widget to act as an "active" indicator.
  * The base.make_widget() is used to make sure the background isn't actually empty.  If it's truly empty, it won't render anything.
  * The create_callback is called once the widget is created.  In the case of the taglist, it's called once for each tag that will be set up.  If you have 5 tags registered and 2 screens, it will be called 10 times total on awesome start.
  * The update_callback is called every time the "data is refreshed".  This effectively means that it will be called those same 10 times on awesome start AND every time there is a change to the taglist.  Client opened/closed, focus on a new tag, sending client to another tag.  The update_callback will be executed for each tag every time one of those events occurs.
  ```
  local update_tag = function(widget, tag, index, taglist)
    local w = widget:get_children_by_id("icon_role")[1]
    local indicator = widget:get_children_by_id("indicator")[1]
    local icon_name = tag_to_image_map[tag.name]
    local color

    if tag.selected then
      color = beautiful.primary_color
      indicator.bg = beautiful.primary_color
    elseif tag.urgent then
      color = beautiful.bg_urgent
      indicator.bg = beautiful.bg_normal
    elseif #tag:clients() > 0 then
      color = beautiful.active_hover
      indicator.bg = beautiful.bg_normal
    else
      color = beautiful.fg_normal
      indicator.bg = beautiful.bg_normal
    end

    w.image = gears.color.recolor_image(beautiful.icon_dir .. icon_name, color)
  end
  ```
  * In my case here, I am fine using the same function as the callback for create AND udpate.  I just want the taglist icons updated to their proper color.
  * The buttons are still the same as the default buttons, just moved for readability
