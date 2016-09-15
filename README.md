# Lua-Sqlite3 is a sqlite3 wrapper for Lua

[![Build Status](https://travis-ci.org/moteus/lua-sqlite3.svg?branch=master)](https://travis-ci.org/moteus/lua-sqlite3)
[![Coverage Status](https://coveralls.io/repos/moteus/lua-sqlite3/badge.svg?branch=master&service=github)](https://coveralls.io/github/moteus/lua-sqlite3?branch=master)

This is changed version of Lua-Sqlite3 release 0.4.1.

### Changes since 0.4.1
 * Support Lua 5.2 and 5.3
 * Impruve error message string
 * Use `sqlite3_open_v2`
 * Use `sqlite3_prepare_v2`
 * Add `open_uri` method

To learn more about lua-sqlite3 take a look in documentation.html.

Edit Makefile.cfg to match your environment.

Please note that this release is still alpha software. This mean that 
there exists a chance that function signatures and behavour will change
in the future.

If you have suggestions, questions or feature request please
feel free to contact me.


Michael Roth <mroth@nessie.de>

