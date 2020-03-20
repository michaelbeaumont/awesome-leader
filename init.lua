local print = print
local ipairs = ipairs
local table = table
local math = math
local mouse = mouse -- luacheck: no global
local awful = require "awful"
local gears = require "gears"
local minilog = require "lua-minilog"
local logger = minilog.logger('off')


local leader = {timeout = 4, global_map = {}}

local hotkeys_popup = require("awful.hotkeys_popup").widget.new()
hotkeys_popup:_load_widget_settings()

local function access_map(word, new_map)
    if new_map then leader.global_map[word] = new_map end
    return leader.global_map[word]
end

--create a new grabber
local function make_leadergrabber(map, base_args, finish, ignore_args)
    base_args = base_args or {}
    finish = finish or function() end
    local args = { keys = {}, mods = {}, count = nil, digits = 0 }
    local collect
    local timer = gears.timer({ timeout=leader.timeout })
    timer:connect_signal(
      "timeout",
      function()
        awful.keygrabber.stop(collect)
        finish()
      end
    )
    timer:start()
    collect = awful.keygrabber.run(
      function(_, key, event)
        if key:find('Shift')
          or key:find('Control')
          or key:find('Alt')
          or key:find('Super')
        then
          args.mods[key] = not args.mods[key]
          return
        end
        if event == "release" then
          return true
        end
        logger.print("fine", "Got key: " .. key)
        if map[key] then
          table.insert(args.keys, key)
          logger.print("fine", "Found callback")
          if not ignore_args then
            table.insert(base_args, args)
          end
          map[key].f(base_args)
          if map[key].sticky then
            timer:again()
            return true
          end
        elseif tonumber(key) then
          local count = args.count or 0
          args.count = count*10+tonumber(key)
          args.digits = args.digits+1
          return true
        else
          logger.print("fine", "Found no callback")
        end
        finish()
        awful.keygrabber.stop(collect)
    end)
end

local function compose(g, f)
  return function(x)
    return g(f(x))
  end
end


-- Functions for building configs
function leader.action(f)
  return function(c)
    local wrapped_f =
      function(args)
        local this_args = table.remove(args)
        return function()
          return f(this_args)
        end
      end
    return {
      f = function() return c(wrapped_f) end,
    }
  end
end

leader.pure = leader.action

function leader.sequence(key_binds)
  return function(contA)
    local map = {}
    local descs = {}
    for _, bind in ipairs(key_binds) do
      local bound = bind[2](contA)
      local internal_bind = {
        key=bind[1],
        f=bound.f(bind[3])
      }
      local key = {[bind[1]] = bind[3]}
      table.insert(
        descs,
        {keys=key, modifiers={}}
      )
      if bound.desc then
        hotkeys_popup:add_hotkeys(
          {[bind[3]] = bound.desc}
        )
      end
      map[internal_bind.key] = internal_bind
    end
    return {
      f = function (name) return function(args)
        local widget =
          hotkeys_popup:_create_wibox(
            mouse.screen,
            {name}
          )
        widget:show()
        make_leadergrabber(
          map,
          args,
          function() widget:hide() end
        )
    end
      end,
      desc = descs
    }
  end
end

leader.bind = leader.sequence

function leader.bind_actions(key_binds)
  for _, bind in ipairs(key_binds) do
    bind[2] = leader.action(bind[2])
  end
  return leader.bind(key_binds)
end

leader.pure_sequence = leader.pure_sequence

function leader.repeat_count(f)
  return function(args_stack)
    local g = f(args_stack)
    local this_args = table.remove(args_stack)
    local real_count = this_args and this_args.count and math.max(this_args.count,1) or 1
    for _ = 1, real_count do
      g()
    end
  end
end

function leader.wrap(f, cont)
  return function(c)
    return cont(compose(f, c))
  end
end

--a function to get a function to start grabbing keys, leave blank to get root
function leader.get_leader(word)
  word = word or ""
  return function() make_leadergrabber(access_map(word)) end
end

function leader.set_timeout(timeout)
  leader.timeout = timeout
end

function leader.disable_timeout()
  leader.timeout = -1
end

function leader.leader(config, title)
  title = title or "Leader"
  local root = config(function(x) return x end)
  hotkeys_popup:add_hotkeys(
    {[title] = root.desc}
  )
  return root.f(title)
end

--simple test function
function leader.setup_test_grabber()
  leader.add_key("a", function() print("a expected") end)
  leader.add_key("ab", function(args)
                   print(table.concat(args.keys) .. "," .. args.count)
                   print("ab expected") end)
  leader.add_key("ac", function(args)
                   print(table.concat(args.keys) .. "," .. args.count)
                   print("ac expected") end)
end

return leader
