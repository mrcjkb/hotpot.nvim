local uv = vim.loop
local plugin_dir = string.gsub(uv.fs_realpath((vim.api.nvim_get_runtime_file("lua/hotpot.lua", false))[1]), "/lua/hotpot.lua$", "")
local fnl_dir = (plugin_dir .. "/fnl")
local cache_dir = (vim.fn.stdpath("cache") .. "/hotpot/")
local function canary_link_path(cache_dir0)
  return (cache_dir0 .. "canary")
end
local function check_canary(cache_dir0)
  local _0_, _1_ = uv.fs_realpath(canary_link_path(cache_dir0))
  if ((_0_ == nil) and (nil ~= _1_)) then
    local error = _1_
    return false
  elseif (nil ~= _0_) then
    local path = _0_
    return true
  end
end
local function make_canary(cache_dir0, fnl_dir0)
  local canary_file
  do
    local dir = uv.fs_opendir((fnl_dir0 .. "/../canary/"), nil, 1)
    local content = uv.fs_readdir(dir)
    local _ = uv.fs_closedir(dir)
    canary_file = content[1].name
  end
  uv.fs_unlink(canary_link_path(cache_dir0))
  return uv.fs_symlink((fnl_dir0 .. "/../canary/" .. canary_file), canary_link_path(cache_dir0))
end
local function load_from_cache(cache_dir0, fnl_dir0)
  local old_package_path = package.path
  local hotpot_path = (cache_dir0 .. fnl_dir0 .. "/?.lua;" .. package.path)
  package.path = hotpot_path
  local hotpot = require("hotpot.hotterpot")
  hotpot.install()
  hotpot["install"] = nil
  hotpot["uninstall"] = nil
  return hotpot
end
local function clear_cache(cache_dir0)
  local scanner = uv.fs_scandir(cache_dir0)
  local function _0_()
    return uv.fs_scandir_next(scanner)
  end
  for name, type in _0_ do
    local _1_ = type
    if (_1_ == "directory") then
      local child = (cache_dir0 .. "/" .. name)
      clear_cache(child)
      uv.fs_rmdir(child)
    elseif (_1_ == "file") then
      uv.fs_unlink((cache_dir0 .. "/" .. name))
    end
  end
  return nil
end
local function compile_fresh(cache_dir0, fnl_dir0)
  local fennel = require("hotpot.fennel")
  local saved_fennel_path = fennel.path
  fennel.path = (fnl_dir0 .. "/?.fnl;" .. fennel.path)
  table.insert(package.loaders, fennel.searcher)
  local hotpot = require("hotpot.hotterpot")
  hotpot.install()
  local function path_to_modname(path)
    return string.gsub(string.gsub(string.gsub(path, "^/", ""), ".fnl", ""), "/", ".")
  end
  local function compile_dir(fennel0, in_dir, out_dir, local_path)
    local scanner = uv.fs_scandir(in_dir)
    local ok = true
    local function _0_()
      return uv.fs_scandir_next(scanner)
    end
    for name, type in _0_ do
      if not ok then break end
      local _1_ = type
      if (_1_ == "directory") then
        local out_down = (cache_dir0 .. "/" .. in_dir .. "/" .. name)
        local in_down = (in_dir .. "/" .. name)
        local local_down = (local_path .. "/" .. name)
        vim.fn.mkdir(out_down, "p")
        compile_dir(fennel0, in_down, out_down, local_down)
      elseif (_1_ == "file") then
        local out_file = (out_dir .. "/" .. string.gsub(name, ".fnl$", ".lua"))
        local in_file = (in_dir .. "/" .. name)
        if not (name == "macros.fnl") then
          local modname = path_to_modname((local_path .. "/" .. name))
          local loader = hotpot.search(modname)
          loader()
        end
      end
    end
    return nil
  end
  compile_dir(fennel, fnl_dir0, cache_dir0, "")
  fennel.path = saved_fennel_path
  local target = nil
  for i, check in ipairs(package.loaders) do
    if target then break end
    if (check == fennel.searcher) then
      target = i
    end
  end
  table.remove(package.loaders, target)
  make_canary(cache_dir0, fnl_dir0)
  hotpot["install"] = nil
  hotpot["uninstall"] = nil
  return hotpot
end
if check_canary(cache_dir) then
  return load_from_cache(cache_dir, fnl_dir)
else
  return compile_fresh(cache_dir, fnl_dir)
end
