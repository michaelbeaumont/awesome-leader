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

local leader = {timeout = 1, global_map = {}}

local function access_map(word, new_map)
    if new_map then leader.global_map[word] = new_map end
    return leader.global_map[word]
end

--create a new grabber
function leader.make_leadergrabber(map, args)
    local args = args or { keys = {}, mods = {}, count = 0, digits = 0 }
    local collect
    local timer = gears.timer({timeout=leader.timeout})
    timer:connect_signal("timeout",
                         function() awful.keygrabber.stop(collect) end)
    timer:start()
    collect = awful.keygrabber.run(function(mod, key, event)
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
                map[key].f(args)
                if map[key].sticky then
                    timer:again()
                    return true
                end
            elseif tonumber(key) then
                args.count = args.count*10+tonumber(key)
                args.digits = args.digits+1
                return true
            else
                logger.print("fine", "Found no callback")
            end
            awful.keygrabber.stop(collect)
            if map.cleanup then map.cleanup() end
    end)
end


--add function for key combination
--Note: Overwrites functions for prefixes
function leader.add_key(word, f, sticky)
    local word_len = string.len(word)
    for i=1,word_len do
        local prefix = string.sub(word,1,i)
        local init_prefix = string.sub(word,1,i-1)
        local last_prefix = string.sub(word,i,i)
        local new_continuation = i == word_len and {f=f, sticky=sticky}
            or {f=function(args) leader.make_leadergrabber(access_map(prefix), args) end}
        if not access_map(init_prefix) then
            local map = {[last_prefix] = new_continuation}
            access_map(init_prefix, map)
        else
            access_map(init_prefix)[last_prefix] = new_continuation
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
