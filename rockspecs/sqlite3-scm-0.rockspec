package = "sqlite3"
version = "scm-0"

source = {
  url = "https://github.com/moteus/lua-sqlite3/archive/master.zip",
  dir = "lua-sqlite3-master"
}

description = {
  summary = "Lua-Sqlite3 is a SQLite3 wrapper for Lua",
  -- detailed = [[]],
  license = "MIT/X11",
  homepage = "http://www.mroth.net/lua-sqlite3"
}

dependencies = {
  "lua >= 5.1, < 5.4"
}

external_dependencies = {
  SQLITE = {
    header = "sqlite3.h"
  }
}

build = {
  type = "builtin",
  copy_directories = { 'examples' },
  modules = {
    ["sqlite3.core"] = {
      sources   = { "libluasqlite3.c"  },
      libraries = { "sqlite3"          },
      incdirs   = { "$(SQLITE_INCDIR)" },
      libdirs   = { "$(SQLITE_LIBDIR)" }
    },
    ["sqlite3.luasql"] = "luasql-sqlite3.lua",
    ["sqlite3"]        = "sqlite3.lua",
  },
}