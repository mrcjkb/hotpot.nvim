package.preload["test.utils"] = package.preload["test.utils"] or function(...)
  local function read_file(path)
    return table.concat(vim.fn.readfile(path), "\\n")
  end
  local function write_file(path, lines)
    vim.fn.mkdir(vim.fs.dirname(path), "p")
    local fh = assert(io.open(path, "w"), ("fs.write-file! io.open failed:" .. path))
    local function close_handlers_10_auto(ok_11_auto, ...)
      fh:close()
      if ok_11_auto then
        return ...
      else
        return error(..., 0)
      end
    end
    local function _3_()
      return fh:write(lines)
    end
    return close_handlers_10_auto(_G.xpcall(_3_, (package.loaded.fennel or debug).traceback))
  end
  local results = {passes = 0, fails = 0}
  local function OK(message)
    results.passes = (1 + results.passes)
    return print("OK", message)
  end
  local function FAIL(message)
    results.fails = (1 + results.fails)
    return print("FAIL", message)
  end
  local function exit()
    print("\n")
    return os.exit(results.fails)
  end
  do end (vim.opt.runtimepath):prepend(vim.loop.cwd())
  require("hotpot")
  return {["write-file"] = write_file, ["read-file"] = read_file, OK = OK, FAIL = FAIL, exit = exit, NVIM_APPNAME = vim.env.NVIM_APPNAME}
end
local _local_1_ = require("test.utils")
local FAIL = _local_1_["FAIL"]
local NVIM_APPNAME = _local_1_["NVIM_APPNAME"]
local OK = _local_1_["OK"]
local exit = _local_1_["exit"]
local read_file = _local_1_["read-file"]
local write_file = _local_1_["write-file"]
local function test_path(modname, path)
  local fnl_path = (vim.fn.stdpath("config") .. "/fnl/" .. path .. ".fnl")
  local lua_path = (vim.fn.stdpath("cache") .. "/hotpot/compiled/" .. NVIM_APPNAME .. "/lua/" .. path .. ".lua")
  write_file(fnl_path, "{:works true}")
  local function _4_(...)
    local _5_ = ...
    if (_5_ == true) then
      local function _6_(...)
        local _7_ = ...
        if (_7_ == true) then
          local function _8_(...)
            local _9_ = ...
            if (_9_ == true) then
              return true
            elseif true then
              local __75_auto = _9_
              return ...
            else
              return nil
            end
          end
          local function _12_(...)
            local _11_ = read_file(lua_path)
            if (_11_ == "return {works = true}") then
              OK(string.format(("Outputs correct lua code" or "")))
              return true
            elseif true then
              local __1_auto = _11_
              FAIL(string.format(("Outputs correct lua code" or "")))
              return false
            else
              return nil
            end
          end
          return _8_(_12_(...))
        elseif true then
          local __75_auto = _7_
          return ...
        else
          return nil
        end
      end
      local function _16_(...)
        local _15_ = vim.loop.fs_access(lua_path, "R")
        if (_15_ == true) then
          OK(string.format(("Creates a lua file at %s" or ""), lua_path))
          return true
        elseif true then
          local __1_auto = _15_
          FAIL(string.format(("Creates a lua file at %s" or ""), lua_path))
          return false
        else
          return nil
        end
      end
      return _6_(_16_(...))
    elseif true then
      local __75_auto = _5_
      return ...
    else
      return nil
    end
  end
  local function _21_()
    local _19_, _20_ = pcall(require, modname)
    if ((_19_ == true) and ((_G.type(_20_) == "table") and ((_20_).works == true))) then
      OK(string.format(("Can require module %s %s" or ""), modname, fnl_path))
      return true
    elseif true then
      local __1_auto = _19_
      FAIL(string.format(("Can require module %s %s" or ""), modname, fnl_path))
      return false
    else
      return nil
    end
  end
  return _4_(_21_())
end
test_path("abc", "abc")
test_path("def", "def/init")
test_path("xyz.init", "xyz/init")
test_path("abc.xyz.p-q-r", "abc/xyz/p-q-r")
test_path("xc-init", "xc-init")
return exit()