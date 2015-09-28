
--[[--------------------------------------------------------------------------

    Author: Michael Roth <mroth@nessie.de>

    Copyright (c) 2004 Michael Roth <mroth@nessie.de>

    Permission is hereby granted, free of charge, to any person 
    obtaining a copy of this software and associated documentation
    files (the "Software"), to deal in the Software without restriction,
    including without limitation the rights to use, copy, modify, merge,
    publish, distribute, sublicense, and/or sell copies of the Software,
    and to permit persons to whom the Software is furnished to do so,
    subject to the following conditions:

    The above copyright notice and this permission notice shall be 
    included in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

--]]--------------------------------------------------------------------------



local luasql = require "sqlite3.luasql"

local os = os

local lunit = require "lunit"
local TEST_CASE = lunit.TEST_CASE

local getn = table.getn or function(t) return #t end

-------------------------------------------------
-- This is the luaSql compatible sqlite driver --
-------------------------------------------------
local _ENV = TEST_CASE"Driver Interface" do

function test()
  assert_table( luasql )
  assert_function( luasql.sqlite3 )
  local env = assert_table( luasql.sqlite3() )
  assert_function( env.connect )
  assert_function( env.connect_memory )	-- sqlite3 extension
  assert_function( env.close )
  assert_true( env:close(),  "Closing an unused environment must return 'true'" )
  assert_nil( env:close(), "Closing a closed environment must return 'nil'" )
end

end

local _ENV = TEST_CASE"Connection Interface" do

function test()
  local env = assert_table( luasql.sqlite3() )
  local con = assert_table( env:connect_memory() )
  assert_function( con.close )
  assert_function( con.execute )
  assert_function( con.rollback )
  assert_function( con.commit )
  assert_function( con.setautocommit )
  assert_true( con:close(), "Closing an open connection must return 'true'" )
  assert_nil( con:close(), "Closing a closed connection must return 'nil'" )
  assert_true( env:close() )
end

end

local _ENV = TEST_CASE"Simple connection usage" do

function test()
  local env = assert_table( luasql.sqlite3() )
  local con = assert_table( env:connect_memory() )
  assert_equal( 0, con:execute("CREATE TABLE test (id, name)") )
  assert_equal( 1, con:execute("INSERT INTO test VALUES (1, 'Hello World')") )
  assert_true( con:close() )
  assert_true( env:close() )
end

end

local _ENV = TEST_CASE"Cursor Interface" do

function test()
  local env = assert_table( luasql.sqlite3() )
  local con = assert_table( env:connect_memory() )
  assert_equal( 0, con:execute("CREATE TABLE test (id, name)") )
  local cur = assert_table( con:execute("SELECT * FROM test") )
  assert_function( cur.close )
  assert_function( cur.fetch )
  assert_function( cur.getcolnames )
  assert_function( cur.getcoltypes )
  assert_true( cur:close(), "Closing an open cursor must return 'true'" )
  assert_nil( cur:close(), "Closing a closed cursor must return 'nil'" )
  assert_true( con:close() )
  assert_true( env:close() )
end

end

local _ENV = TEST_CASE"Simple cursor usage" do

local env, con, cur

function setup()
  -- open database
  env = assert_table( luasql.sqlite3() )
  con = assert_table( env:connect_memory() )

  -- prepare database
  assert_equal( 0, con:execute("CREATE TABLE test (id INTEGER, item TEXT)") )
  assert_equal( 1, con:execute("INSERT INTO test VALUES (1, 'Hello World')") )
  assert_equal( 1, con:execute("INSERT INTO test VALUES (2, 'Hello Lua')") )
  assert_equal( 1, con:execute("INSERT INTO test VALUES (3, 'Hello sqlite3')") )
  
  -- open cursor
  cur = assert_table( con:execute("SELECT * FROM test ORDER BY id") )
end

function teardown()
  assert_true( cur:close() )
  assert_true( con:close() )
  assert_true( env:close() )
end

function test_fetch_direct()
  local id, item
  id, item = cur:fetch(); assert_equal(1, id); assert_equal("Hello World", item)
  id, item = cur:fetch(); assert_equal(2, id); assert_equal("Hello Lua", item)
  id, item = cur:fetch(); assert_equal(3, id); assert_equal("Hello sqlite3", item)
  assert_nil( cur:fetch() )
end

local function check(key_id, id, key_item, item, row)
  assert_table(row)
  assert_equal(id, row[key_id])
  assert_equal(item, row[key_item])
end

function test_fetch_default()
  check(1, 1, 2, "Hello World",   cur:fetch({}) )
  check(1, 2, 2, "Hello Lua",     cur:fetch({}) )
  check(1, 3, 2, "Hello sqlite3", cur:fetch({}) )
  assert_nil( cur:fetch({}) )
end
  
function test_fetch_numeric()
  check(1, 1, 2, "Hello World",   cur:fetch({}, "n") )
  check(1, 2, 2, "Hello Lua",     cur:fetch({}, "n") )
  check(1, 3, 2, "Hello sqlite3", cur:fetch({}, "n") )
  assert_nil( cur:fetch({}, "n") )
end

function test_fetch_alphanumeric()
  check("id", 1, "item", "Hello World",   cur:fetch({}, "a"))
  check("id", 2, "item", "Hello Lua",     cur:fetch({}, "a"))
  check("id", 3, "item", "Hello sqlite3", cur:fetch({}, "a"))
  assert_nil( cur:fetch({}, "a") )
end

function test_getcolnames()
  local names = assert_table( cur:getcolnames() )
  assert_equal(2, getn(names) )
  assert_equal("id", names[1])
  assert_equal("item", names[2])
end

function test_getcoltypes()
  local types = assert_table( cur:getcoltypes() )
  assert_equal(2, getn(types) )
  assert_equal("INTEGER", types[1])
  assert_equal("TEXT", types[2])
end

end

local _ENV = TEST_CASE"Transaction Tests" do

local env, con, cur

function setup()
  -- open database
  env = assert_table( luasql.sqlite3() )
  con = assert_table( env:connect_memory() )

  -- prepare database
  assert_equal( 0, con:execute("CREATE TABLE test (id INTEGER, item TEXT)") )
  assert_equal( 1, con:execute("INSERT INTO test VALUES (1, 'Hello World')") )
  assert_equal( 1, con:execute("INSERT INTO test VALUES (2, 'Hello Lua')") )
  assert_equal( 1, con:execute("INSERT INTO test VALUES (3, 'Hello sqlite3')") )
  
  -- switch to manual transaction controll
  assert_true( con:setautocommit(false) )
end

function teardown()
  assert_true( con:close() )
  assert_true( env:close() )
end

function insert(id, item)
  assert_equal(1, con:execute("INSERT INTO test VALUES ("..id..", '"..item.."')") )
end

function update(id, item)
  assert_equal(1, con:execute("UPDATE test SET item = '"..item.."' WHERE id = "..id) )
end

local function check(expected)
  assert_table(expected)
  
  local cur = assert_table( con:execute("SELECT * FROM test ORDER BY id") )
  local id = 0
  local row = cur:fetch({}, "a")
  while row do
    assert_table(row)
    id = id + 1
    assert_equal(id, row.id, "Unexpected 'id' read (wrong row?)")
    assert( id <= getn(expected), "'Id' read to large (to many rows?)")
    assert_equal(expected[id], row.item, "Invalid content in row")
    row = cur:fetch({}, "a")
  end
  assert_equal(id,  getn(expected), "To less rows read")
  assert_true( cur:close() )
end

function test_prepared_content()
  check { "Hello World", "Hello Lua", "Hello sqlite3" }
end

function test_transactions()
  insert(4, "Hello again")
  insert(5, "Goodbye")
  check { "Hello World", "Hello Lua", "Hello sqlite3", "Hello again", "Goodbye" }
  assert_true( con:commit() )
  update(1, "Good morning")
  insert(6, "Foobar")
  check { "Good morning", "Hello Lua", "Hello sqlite3", "Hello again", "Goodbye", "Foobar" }
  assert_true( con:rollback() )
  check { "Hello World", "Hello Lua", "Hello sqlite3", "Hello again", "Goodbye" }
end

end
