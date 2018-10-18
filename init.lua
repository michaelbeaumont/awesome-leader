local print, tostring = print, tostring
local ipairs, pairs = ipairs, pairs
local setmetatable = setmetatable
local table = table
local math = math
local awful = require "awful"
local wibox = require "wibox"
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

function leader.leader(config)
  return config(function(x) return x end)
end

function leader.repeat_count(f)
  return function(args_stack)
    local g = f(args_stack)
    local this_args = table.remove(args_stack)
    local real_count = this_args and this_args.count and math.max(this_args.count,1) or 1
    for i=1,real_count do
      g()
    end
  end
end

--create a new grabber
function leader.make_leadergrabber(map, base_args, finish, ignore_args)
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
      function(mod, key, event)
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

function str_to_arr(keys)
  local out = {}
  for i=1,string.len(keys) do
    table.insert(out, string.sub(keys, i, i))
  end
  return out
end

function leader.pure(f, desc)
  return function(c)
    local wrapped_f =
      function(args)
        local this_args = table.remove(args)
        return function()
          return f(this_args)
        end
      end
    return {
      f = c(wrapped_f),
      desc = desc
    }
  end
end

function leader.compose(g, f)
  return function(x)
    return g(f(x))
  end
end

function leader.sequence(key_binds)
  return function(contA)
    local map = {}
    local descs = {}
    for _, bind in ipairs(key_binds) do
      local bound = bind[2](contA)
      local internal_bind = {
        key=bind[1],
        f=bound.f
      }
      local key = {[bind[1]] = bound.desc}
      table.insert(
        descs,
        {keys=key, modifiers={}}
      )
      map[internal_bind.key] = internal_bind
    end
    hotkeys_popup:add_hotkeys(
      {[key_binds.desc] = descs}
    )
    return {
      f = function(args)
        local widget =
          hotkeys_popup:_create_wibox(
            mouse.screen,
            {key_binds.desc}
          )
        widget:show()
        leader.make_leadergrabber(
          map,
          args,
          function() widget:hide() end
        )
      end,
      desc=key_binds.desc
    }
  end
end

function leader.basic_sequence(key_binds)
  for _, bind in ipairs(key_binds) do
    bind[2] = leader.pure(bind[2], bind[3])
    bind[3] = nil
  end
  return leader.sequence(key_binds)
end

function leader.wrap(f, cont)
  return function(c)
    return cont(leader.compose(f, c))
  end
end

local function wrap_naked_f(f)
  return function(args)
    return function()
      return f(args)
    end
  end
end

--add function for key combination
--Note: Overwrites functions for prefixes
function leader.add_key(keys, f, sticky)
  if type(keys) == "string" then
    keys = str_to_arr(keys)
  end
  local prefix = ""
  for i=1,#keys do
    local init_prefix = prefix
    local this_key = keys[i]
    if i == 1 then
      prefix = keys[i]
    else
      prefix = prefix .. " " .. keys[i]
    end
    local this_prefix = prefix
    local new_continuation =
      i == #keys and {f=wrap_naked_f(f), sticky=sticky}
      or { f =
             wrap_naked_f(
               function(args)
                 leader.make_leadergrabber(access_map(this_prefix), args)
             end)
      }
    if not access_map(init_prefix) then
      local map = {[this_key] = new_continuation}
      access_map(init_prefix, map)
    else
      access_map(init_prefix)[this_key] = new_continuation
    end
  end
end

--a function to get a function to start grabbing keys, leave blank to get root
function leader.get_leader(word)
  local word = word or ""
  return function() leader.make_leadergrabber(access_map(word)) end
end

function leader.set_timeout(timeout)
  leader.timeout = timeout
end

function leader.disable_timeout()
  leader.timeout = -1
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
