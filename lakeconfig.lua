J = J or path.join

IF = IF or lake.choose or choose

function run(file, cwd)
  print()
  print("run " .. file)
  if not TESTING then
    if cwd then lake.chdir(cwd) end
    os.execute( LUA_RUNNER .. ' ' .. file )
    if cwd then lake.chdir("<") end
    print()
  end
end

function as_bool(v,d)
  if v == nil then return not not d end
  local n = tonumber(v)
  if n == 0 then return false end
  if n then return true end
  return false
end

lake.define_need('lua52', function()
  return {
    incdir = J(ENV.LUA_DIR_5_2, 'include');
    libdir = J(ENV.LUA_DIR_5_2, 'lib');
    libs   = {'lua52'};
  }
end)

lake.define_need('lua51', function()
  return {
    incdir = J(ENV.LUA_DIR, 'include');
    libdir = J(ENV.LUA_DIR, 'lib');
    libs   = {'lua5.1'};
  }
end)

local SQLITE3_DIR = J(ENV.CPPLIB_DIR, 'sqlite', '3.7.15.2')

lake.define_need('sqlite3', function()
  return {
    incdir = J(SQLITE3_DIR, 'include');
    libdir = J(SQLITE3_DIR, 'lib');
    libs   = {'sqlite3'};
  }
end)

lake.define_need('sqlite3-static', function()
  return {
    incdir = J(SQLITE3_DIR, 'include');
    libdir = J(SQLITE3_DIR, 'static');
    libs   = {'libsqlite3'};
  }
end)

lake.define_need('sqlite3-static-md', function()
  return {
    incdir = J(SQLITE3_DIR, 'include');
    libdir = J(SQLITE3_DIR, 'static');
    libs   = {'sqlite3_vc10_md'};
  }
end)

lake.define_need('sqlite3-static-mt', function()
  return {
    incdir = J(SQLITE3_DIR, 'include');
    libdir = J(SQLITE3_DIR, 'static');
    libs   = {'sqlite3_vc10_mt'};
  }
end)

