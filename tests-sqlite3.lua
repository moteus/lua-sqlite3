
--[[--------------------------------------------------------------------------

    Author: Michael Roth <mroth@nessie.de>

    Copyright (c) 2004, 2005 Michael Roth <mroth@nessie.de>

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


local sqlite3 = require "sqlite3"

local os = os

local lunit = require "lunit"
local TEST_CASE = lunit.TEST_CASE

local getn = table.getn or function(t) return #t end

local unpack = unpack or table.unpack

-------------------------------
-- Basic open and close test --
-------------------------------
local _ENV = TEST_CASE'tests-sqlite3' do

local db, filename

function setup()
  filename, db = "./__lua-sqlite3-20040906135849." .. os.time()
end

function teardown()
  if db then db:close() end
  os.remove(filename)
end

function test_open_memory()
  db = assert_table( sqlite3.open_memory() )
end

function test_open()
  db = assert_table( sqlite3.open(filename) )
end

function test_open_uri()
  db = assert_table( sqlite3.open_uri("file:"..filename) )
end

function test_open_uri_with_mode()
  db = assert_table( sqlite3.open_uri("file:"..filename.."?mode=rwc") )
end

function test_fail_open_uri_create()
  -- no create flag
  db = assert_nil( sqlite3.open_uri("file:"..filename.."?mode=rw") )
end

end

-------------------------------------
-- Presence of db member functions --
-------------------------------------
local _ENV = TEST_CASE"Database Member Functions" do

local db

function setup()
  db = assert( sqlite3.open_memory() )
end

function teardown()
  assert( db:close() )
end

function test()
  assert_function( db.close )
  assert_function( db.exec )
  assert_function( db.irows )
  assert_function( db.rows )
  assert_function( db.cols )
  assert_function( db.first_irow )
  assert_function( db.first_row )
  assert_function( db.first_cols )
  assert_function( db.prepare )
  assert_function( db.interrupt )
  assert_function( db.last_insert_rowid )
  assert_function( db.changes )
  assert_function( db.total_changes )
end

end

---------------------------------------
-- Presence of stmt member functions --
---------------------------------------
local _ENV = TEST_CASE"Statement Member Functions" do
local db, stmt

function setup()
  db = assert( sqlite3.open_memory() )
  stmt = assert( db:prepare("CREATE TABLE test (id, content)") )
end

function teardown()
  assert( stmt:close() )
  assert( db:close() )
end

function test()
  assert_function( stmt.close )
  assert_function( stmt.reset )
  assert_function( stmt.exec )
  assert_function( stmt.bind )
  assert_function( stmt.irows )
  assert_function( stmt.rows )
  assert_function( stmt.cols )
  assert_function( stmt.first_irow )
  assert_function( stmt.first_row )
  assert_function( stmt.first_cols )
  assert_function( stmt.column_names )
  assert_function( stmt.column_decltypes )
  assert_function( stmt.column_count )
end

end

------------------
-- Tests basics --
------------------
local _ENV = TEST_CASE"Basics" do
local db, stmt

function setup()
  db = assert_table( sqlite3.open_memory() )
end

function teardown()
  assert_table( db:close() )
end

local function create_table()
  assert_table( db:exec("CREATE TABLE test (id, name)") )
end

local function drop_table()
  assert_table( db:exec("DROP TABLE test") )
end

local function insert(id, name)
  assert_table( db:exec("INSERT INTO test VALUES ("..id..", '"..name.."')") )
end

local function update(id, name)
  assert_table( db:exec("UPDATE test SET name = '"..name.."' WHERE id = "..id) )
end

function test_create_drop()
  create_table()
  drop_table()
end

function test_multi_create_drop()
  create_table()
  drop_table()
  create_table()
  drop_table()
end

function test_insert()
  create_table()
  insert(1, "Hello World")
  insert(2, "Hello Lua")
  insert(3, "Hello sqlite3")
end

function test_update()
  create_table()
  insert(1, "Hello Home")
  insert(2, "Hello Lua")
  update(1, "Hello World")
end

end

---------------------------------
-- Statement Column Info Tests --
---------------------------------
local _ENV = TEST_CASE"Column Info Test" do

function test()
  local db = assert_table( sqlite3.open_memory() )
  assert_table( db:exec("CREATE TABLE test (id INTEGER, name TEXT)") )
  local stmt = assert_table( db:prepare("SELECT * FROM test") )
  
  assert_equal(2, stmt:column_count(), "Wrong number of columns." )
  
  local names = assert_table( stmt:column_names() )
  assert_equal(2, getn(names), "Wrong number of names.")
  assert_equal("id", names[1] )
  assert_equal("name", names[2] )
  
  local types = assert_table( stmt:column_decltypes() )
  assert_equal(2, getn(types), "Wrong number of declaration types.")
  assert_equal("INTEGER", types[1] )
  assert_equal("TEXT", types[2] )
  
  assert_table( stmt:close() )
  assert_table( db:close() )
end

end

---------------------
-- Statement Tests --
---------------------
local _ENV = TEST_CASE"Statement Tests" do

local db

function setup()
  db = assert( sqlite3.open_memory() )
  assert_table( db:exec("CREATE TABLE test (id, name)") )
  assert_table( db:exec("INSERT INTO test VALUES (1, 'Hello World')") )
  assert_table( db:exec("INSERT INTO test VALUES (2, 'Hello Lua')") )
  assert_table( db:exec("INSERT INTO test VALUES (3, 'Hello sqlite3')") )
end

function teardown()
  assert_table( db:close() )
end

local function check_content(expected)
  local stmt = assert( db:prepare("SELECT * FROM test ORDER BY id") )
  local i = 0
  for row in stmt:irows() do
    i = i + 1
    assert( i <= getn(expected), "To much rows." )
    assert_equal(2, getn(row), "Two result column expected.")
    assert_equal(i, row[1], "Wrong 'id'.")
    assert_equal(expected[i], row[2], "Wrong 'name'.")
  end
  assert_equal( getn(expected), i, "To few rows." )
  assert_table( stmt:close() )
end

function test_setup()
  assert_pass(function()  check_content{ "Hello World", "Hello Lua", "Hello sqlite3" } end)
  assert_error(function() check_content{ "Hello World", "Hello Lua" } end)
  assert_error(function() check_content{ "Hello World", "Hello Lua", "Hello sqlite3", "To much" } end)
  assert_error(function() check_content{ "Hello World", "Hello Lua", "Wrong" } end)
  assert_error(function() check_content{ "Hello World", "Wrong", "Hello sqlite3" } end)
  assert_error(function() check_content{ "Wrong", "Hello Lua", "Hello sqlite3" } end)
end

function test_questionmark_args()
  local stmt = assert_table( db:prepare("INSERT INTO test VALUES (?, ?)")  )
  assert_table( stmt:bind(0, "Test") )
  assert_error(function() stmt:bind("To few") end)
  assert_error(function() stmt:bind(0, "Test", "To many") end)
end

function test_questionmark()
  local stmt = assert_table( db:prepare("INSERT INTO test VALUES (?, ?)")  )
  assert_table( stmt:bind(4, "Good morning") )
  assert_table( stmt:exec() )
  check_content{ "Hello World", "Hello Lua", "Hello sqlite3", "Good morning" }
  assert_table( stmt:bind(5, "Foo Bar") )
  assert_table( stmt:exec() )
  check_content{ "Hello World", "Hello Lua", "Hello sqlite3", "Good morning", "Foo Bar" }
end

function test_questionmark_multi()
  local stmt = assert_table( db:prepare([[
    INSERT INTO test VALUES (?, ?); INSERT INTO test VALUES (?, ?) ]]))
  assert( stmt:bind(5, "Foo Bar", 4, "Good morning") )
  assert( stmt:exec() )
  check_content{ "Hello World", "Hello Lua", "Hello sqlite3", "Good morning", "Foo Bar" }
end

function test_identifiers()
  local stmt = assert_table( db:prepare("INSERT INTO test VALUES (:id, :name)")  )
  assert_table( stmt:bind(4, "Good morning") )
  assert_table( stmt:exec() )
  check_content{ "Hello World", "Hello Lua", "Hello sqlite3", "Good morning" }
  assert_table( stmt:bind(5, "Foo Bar") )
  assert_table( stmt:exec() )
  check_content{ "Hello World", "Hello Lua", "Hello sqlite3", "Good morning", "Foo Bar" }
end

function test_identifiers_multi()
  local stmt = assert_table( db:prepare([[
    INSERT INTO test VALUES (:id1, :name1); INSERT INTO test VALUES (:id2, :name2) ]]))
  assert( stmt:bind(5, "Foo Bar", 4, "Good morning") )
  assert( stmt:exec() )
  check_content{ "Hello World", "Hello Lua", "Hello sqlite3", "Good morning", "Foo Bar" }
end

function test_identifiers_names()
  local stmt = assert_table( db:prepare({"name", "id"}, "INSERT INTO test VALUES (:id, $name)")  )
  assert_table( stmt:bind("Good morning", 4) )
  assert_table( stmt:exec() )
  check_content{ "Hello World", "Hello Lua", "Hello sqlite3", "Good morning" }
  assert_table( stmt:bind("Foo Bar", 5) )
  assert_table( stmt:exec() )
  check_content{ "Hello World", "Hello Lua", "Hello sqlite3", "Good morning", "Foo Bar" }
end

function test_identifiers_multi_names()
  local stmt = assert_table( db:prepare( {"name", "id1", "id2"},[[
    INSERT INTO test VALUES (:id1, $name); INSERT INTO test VALUES ($id2, :name) ]]))
  assert( stmt:bind("Hoho", 4, 5) )
  assert( stmt:exec() )
  check_content{ "Hello World", "Hello Lua", "Hello sqlite3", "Hoho", "Hoho" }
end

function test_colon_identifiers_names()
  local stmt = assert_table( db:prepare({":name", ":id"}, "INSERT INTO test VALUES (:id, $name)")  )
  assert_table( stmt:bind("Good morning", 4) )
  assert_table( stmt:exec() )
  check_content{ "Hello World", "Hello Lua", "Hello sqlite3", "Good morning" }
  assert_table( stmt:bind("Foo Bar", 5) )
  assert_table( stmt:exec() )
  check_content{ "Hello World", "Hello Lua", "Hello sqlite3", "Good morning", "Foo Bar" }
end

function test_colon_identifiers_multi_names()
  local stmt = assert_table( db:prepare( {":name", ":id1", ":id2"},[[
    INSERT INTO test VALUES (:id1, $name); INSERT INTO test VALUES ($id2, :name) ]]))
  assert( stmt:bind("Hoho", 4, 5) )
  assert( stmt:exec() )
  check_content{ "Hello World", "Hello Lua", "Hello sqlite3", "Hoho", "Hoho" }
end

function test_dollar_identifiers_names()
  local stmt = assert_table( db:prepare({"$name", "$id"}, "INSERT INTO test VALUES (:id, $name)")  )
  assert_table( stmt:bind("Good morning", 4) )
  assert_table( stmt:exec() )
  check_content{ "Hello World", "Hello Lua", "Hello sqlite3", "Good morning" }
  assert_table( stmt:bind("Foo Bar", 5) )
  assert_table( stmt:exec() )
  check_content{ "Hello World", "Hello Lua", "Hello sqlite3", "Good morning", "Foo Bar" }
end

function test_dollar_identifiers_multi_names()
  local stmt = assert_table( db:prepare( {"$name", "$id1", "$id2"},[[
    INSERT INTO test VALUES (:id1, $name); INSERT INTO test VALUES ($id2, :name) ]]))
  assert( stmt:bind("Hoho", 4, 5) )
  assert( stmt:exec() )
  check_content{ "Hello World", "Hello Lua", "Hello sqlite3", "Hoho", "Hoho" }
end

function test_bind_by_names()
  local stmt = assert_table( db:prepare("INSERT INTO test VALUES (:id, :name)")  )
  local args = { }
  args.id = 5
  args.name = "Hello girls"
  assert( stmt:bind(args) )
  assert( stmt:exec() )
  args.id = 4
  args.name = "Hello boys"
  assert( stmt:bind(args) )
  assert( stmt:exec() )
  check_content{ "Hello World", "Hello Lua", "Hello sqlite3",  "Hello boys", "Hello girls" }
end

end

--------------------------------
-- Tests binding of arguments --
--------------------------------
local _ENV = TEST_CASE"Binding Tests" do

local db

function setup()
  db = assert( sqlite3.open_memory() )
  assert_table( db:exec("CREATE TABLE test (id, name)") )
end

function teardown()
  assert_table( db:close() )
end

function test_auto_parameter_names()
  local stmt = assert_table( db:prepare([[ 
    INSERT INTO test VALUES(:a, $b);
    INSERT INTO test VALUES(:a2, :b2);
    INSERT INTO test VALUES($a, :b);
    INSERT INTO test VALUES($a3, $b3)
  ]]))
  local parameters = assert_table( stmt:parameter_names() )
  assert_equal( 6, getn(parameters) )
  assert_equal( "a", parameters[1] )
  assert_equal( "b", parameters[2] )
  assert_equal( "a2", parameters[3] )
  assert_equal( "b2", parameters[4] )
  assert_equal( "a3", parameters[5] )
  assert_equal( "b3", parameters[6] )
end

function test_no_parameter_names_1()
  local stmt = assert_table( db:prepare([[ SELECT * FROM test ]]))
  local parameters = assert_table( stmt:parameter_names() )
  assert_equal( 0, getn(parameters) )
end

function test_no_parameter_names_2()
  local stmt = assert_table( db:prepare([[ INSERT INTO test VALUES(?, ?) ]]))
  local parameters = assert_table( stmt:parameter_names() )
  assert_equal( 0, getn(parameters) )
end

end

--------------------------------------------
-- Tests loop break and statement reusage --
--------------------------------------------

----------------------------
-- Test for bugs reported --
----------------------------
local _ENV = TEST_CASE"Bug-Report Tests" do

local db

function setup()
  db = assert( sqlite3.open_memory() )
end

function teardown()
  assert_table( db:close() )
end

function test_1()
  db:exec("CREATE TABLE test (id INTEGER PRIMARY KEY, value TEXT)")
  
  local query = assert_table( db:prepare("SELECT id FROM test WHERE value=?") )
  
  assert_table ( query:bind("1") )
  assert_nil   ( query:first_cols() )
  assert_table ( query:bind("2") )
  assert_nil   ( query:first_cols() )
end

function test_nils()   -- appeared in lua-5.1 (holes in arrays)
  local function check(arg1, arg2, arg3, arg4, arg5)
    assert_equal(1, arg1)
    assert_equal(2, arg2)
    assert_nil(arg3)
    assert_equal(4, arg4)
    assert_nil(arg5)
  end
  
  db:set_function("test_nils", 5, function(arg1, arg2, arg3, arg4, arg5)
    check(arg1, arg2, arg3, arg4, arg5)
  end)
  
  assert_table( db:exec([[ SELECT test_nils(1, 2, NULL, 4, NULL) ]]) )
  
  local arg1, arg2, arg3, arg4, arg5 = db:first_cols([[ SELECT 1, 2, NULL, 4, NULL ]])
  check(arg1, arg2, arg3, arg4, arg5)
  
  local row = assert_table( db:first_irow([[ SELECT 1, 2, NULL, 4, NULL ]]) )
  check(row[1], row[2], row[3], row[4], row[5])
end

end

