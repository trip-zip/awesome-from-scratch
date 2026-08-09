-- The one pattern behind every overlay UI in this config: exit screen, main
-- menu, launcher, dashboard, notification center. A "modal" is an awful.popup
-- plus the fiddly lifecycle around it: a visibility flag, a keygrabber that
-- closes on Escape, click-outside and tag-change dismissal, and a
-- "<name>::visible" signal other widgets can react to.
--
-- The subtle part every hand-rolled copy of this pattern got wrong at least
-- once: grabber:stop() synchronously fires stop_callback, and stop_callback
-- wants to hide the modal - which stops the grabber. The controller breaks
-- that loop in one place (see the comments in show/hide) so the modules using
-- it never have to think about it.

local awful = require("awful")

local modal = {}

-- modal.new(args) -> controller with show/hide/toggle/is_visible and .popup
--
-- args:
--   name        (required) signal prefix; the controller emits "<name>::visible"
--   build_popup (required) function returning the awful.popup; called once,
--               on first show
--   on_show     optional function(popup): refresh content and place the popup
--   on_hide     optional function(popup): extra cleanup
--   keypressed  optional function(mods, key): keys while open (Escape is
--               already taken; it closes the modal)
function modal.new(args)
  local self = { popup = nil }
  local visible = false
  local grabber = nil

  function self.is_visible()
    return visible
  end

  function self.show()
    if visible then
      return
    end

    if not self.popup then
      self.popup = args.build_popup()
    end

    -- Every modal opens on the screen the user is looking at
    self.popup.screen = awful.screen.focused()

    if args.on_show then
      args.on_show(self.popup)
    end

    self.popup.visible = true
    visible = true

    grabber = awful.keygrabber({
      autostart = true,
      stop_key = "Escape",
      stop_callback = function()
        -- The grabber is already stopped when this fires (Escape, or an
        -- explicit stop from hide()). Clearing the reference first and
        -- routing through hide() gives both paths one cleanup; hide()'s
        -- visibility guard ends the re-entry.
        grabber = nil
        self.hide()
      end,
      keypressed_callback = function(_, mods, key, _)
        if args.keypressed then
          args.keypressed(mods, key)
        end
      end,
    })

    awesome.emit_signal(args.name .. "::visible", true)
  end

  function self.hide()
    if not visible then
      return
    end

    -- Flip the flag before stopping the grabber: stop() re-enters hide() via
    -- stop_callback, and this guard ends that second call immediately.
    visible = false

    local kg = grabber
    grabber = nil
    if kg then
      kg:stop()
    end

    self.popup.visible = false

    if args.on_hide then
      args.on_hide(self.popup)
    end

    awesome.emit_signal(args.name .. "::visible", false)
  end

  function self.toggle()
    if visible then
      self.hide()
    else
      self.show()
    end
  end

  -- Clicking a client or switching tags while the modal is open dismisses it
  client.connect_signal("button::press", function()
    if visible then
      self.hide()
    end
  end)

  tag.connect_signal("property::selected", function()
    if visible then
      self.hide()
    end
  end)

  return self
end

return modal
