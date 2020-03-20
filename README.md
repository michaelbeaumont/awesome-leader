# awesome-leader

This module lets you string together key combinations in awesome triggered by pressing a leader key. It should roughly emulate vim's behavior here. Count arguments before combinations are also supported.

Note: This version needs the latest awesome-git

## Instructions

```
local leader = require "awesome-leader"


local tab_keys = leader.bind_actions({
    {"t",
     function(args)
       awful.tag.add("new", {index=args.count})
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

The `wrap` and second `bind` call are just examples, we can leave them out and directly call
`leader.leader(tab_keys)`.
