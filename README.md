awesome-leader
==============

This module lets you string together key combinations in awesome triggered by pressing a leader key. It should roughly emulate vim's behavior here. Count arguments before combinations are also supported.

Instructions
------------

Require the module at the top of `rc.lua`, bind the root leader to a key, and add key combinations:

    local leader = require "awesome-leader"
    awful.key({ modkey }, "\\", leader.get_leader())

    leader.add_key("ab", function(args)
                       print(table.concat(args.keys) .. "," .. args.count)
                       print("ab expected") end)

Optionally, you can get a link directly to a word:

    awful.key({ modkey }, "a", leader.get_leader("a"))

or change the timeout (default is 1 second):

    leader.set_timeout(2)

The table passed to every function includes the count argument as a number, and all keys pressed so far as an array.
So after adding the above and typing `<modkey-\>11ab`, the function will print "ab,11".
A direct link to "a" allows us to type `<modkey-a>11b`, which will print "b,11"


Note that adding a key combination "abc" will overwrite the functions set for "a", "ab" and the mappings for any words with the prefix "abc".
