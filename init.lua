local print, tostring = print, tostring
local ipairs, pairs = ipairs, pairs
local setmetatable = setmetatable
local table = table
local math = math
local awful = require "awful"
local wibox = require "wibox"
local capi =
{
    client = client,
    screen = screen,
    mouse = mouse,
    button = button
}

local minilog = require "lua-minilog"
local logger = minilog.logger('off')

local leader = {global_map = {}}

local function access_map(word, new_map)
    if new_map then leader.global_map[word] = new_map end
    return leader.global_map[word]
end


--create a new grabber
function leader.make_leadergrabber(map, args)
    local args = args or { keys = {}, count = 0, digits = 0 }
    local collect
    collect = awful.keygrabber.run(function(mod, key, event)
        if event == "release" then return end
        logger.print("fine", "Got key: " .. key)
        if map[key] then
            table.insert(args.keys, key) 
            logger.print("fine", "Found callback")
            map[key](args)
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
--an alternative would be to wait for a timeout and then use the old function
function leader.add_key(word, f)
    local word_len = string.len(word)
    for i=1,word_len do
        local prefix = string.sub(word,1,i)
        local init_prefix = string.sub(word,1,i-1)
        local last_prefix = string.sub(word,i,i)
        local new_continuation = i == word_len and f
            or function(args) leader.make_leadergrabber(access_map(prefix), args) end
        if not access_map(init_prefix) then
            local map = {}
            map[last_prefix] = new_continuation
            access_map(init_prefix, map)
        else
            access_map(init_prefix)[last_prefix] = new_continuation
        end
    end
end


--a function to start grabbing at the root of our map
function leader.root_leader()
    leader.make_leadergrabber(access_map(""))
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
