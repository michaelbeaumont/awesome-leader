package = "leader"
version = "0.1.0-1"
source = {
  url = "git://github.com/michaelbeaumont/awesome-leader",
  tag = "v0.1.0"
}
description = {
  summary = "String together key combinations in Awesome with a leader key.",
  detailed = [[
    This module lets you string together key combinations in awesome triggered by pressing a leader key.
    It should roughly emulate vim's behavior here. Count arguments before combinations are also supported.
  ]],
  homepage = "https://github.com/michaelbeaumont/awesome-leader",
  license = "MIT"
}
dependencies = {
  "lua >= 5.1",
}
supported_platforms = {
  "linux"
}
build = {
  type = "builtin",
  modules = {
     leader = "init.lua",
  }
}
