awesome-leader
==============

This module lets you string together key combinations in awesome triggered by pressing a leader key. It should roughly emulate vim's behavior here. Count arguments before combinations are also supported.

Note: This version needs the latest awesome-git and https://github.com/awesomeWM/awesome/pull/2443

Instructions
------------

```
local tab_keys = leader.bind_actions({
    {"t",
     function(args)
       local word = "new"
       awful.tag.add(word, {index=args.count})
     end,
     "New tag!"
    },
})

local rec_leader =
  leader.wrap(
    leader.repeat_count,
    leader.bind({
        {"t", tab_keys, "Tags"},
  }))

local root_leader = leader.leader(rec_leader)

awful.key({ modkey }, "z", root_leader)
```

Use `bind_actions` to bind a list of simple Lua functions, keys and
descriptions. To build up more complicated bindings (in this example, to put
`tab_keys` behind the `t` key) use `bind`.

With this config, we can press combinations like `<modkey-z>2t2` to add 2 new tabs at index 2.
We also get nifty popups at each stage telling us what keys are available.

### Legacy

Require the module at the top of `rc.lua`, bind the root leader to a key, and add key combinations:

    local leader = require "awesome-leader"
    awful.key({ modkey }, "\\", leader.get_leader())

    leader.add_key("ab", function(args)
                       print(table.concat(args.keys) .. "," .. args.count)
                       print("ab expected") end)

Strings of keys can be specific as either tables `{'a', 'Return'}` or as strings `'ab'`.

Optionally, you can get a link directly to a word:

    awful.key({ modkey }, "a", leader.get_leader("a"))

or change the timeout (default is 1 second):

    leader.set_timeout(2)

The table passed to every function includes the count argument as a number, and all keys pressed so far as an array.
So after adding the above and typing `<modkey-\>11ab`, the function will print "ab,11".
A direct link to "a" allows us to type `<modkey-a>11b`, which will print "b,11"


Note that adding a key combination "abc" will overwrite the functions set for "a", "ab" and the mappings for any words with the prefix "abc".
