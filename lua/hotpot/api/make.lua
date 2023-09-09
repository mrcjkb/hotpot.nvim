local _local_1_ = require("hotpot.common")
local table_3f = _local_1_["table?"]
local function_3f = _local_1_["function?"]
local boolean_3f = _local_1_["boolean?"]
local string_3f = _local_1_["string?"]
local nil_3f = _local_1_["nil?"]
local map = _local_1_["map"]
local filter = _local_1_["filter"]
local any_3f = _local_1_["any?"]
local none_3f = _local_1_["none?"]
local uv = vim.loop
local M = {}
local automake_memo = {augroup = nil, ["attached-buffers"] = {}}
local function merge_with_default_options(opts)
  _G.assert((nil ~= opts), "Missing argument opts on fnl/hotpot/api/make.fnl:11")
  local _let_2_ = require("hotpot.runtime")
  local default_config = _let_2_["default-config"]
  local compiler_options = vim.tbl_extend("keep", (opts.compiler or {}), default_config().compiler)
  local opts0 = vim.tbl_extend("keep", opts, {atomic = false, dryrun = false, force = false, verbose = false})
  do end (opts0)["compiler"] = compiler_options
  if opts0.dryrun then
    opts0.verbose = true
  else
  end
  return opts0
end
local function validate_spec(kind, spec)
  local _4_
  do
    local ok = true
    for _, s in ipairs(spec) do
      if not (true == ok) then break end
      local function _5_()
        local pat = s[1]
        local act = s[2]
        return (string_3f(pat) and (boolean_3f(act) or function_3f(act)))
      end
      if (((_G.type(s) == "table") and (nil ~= s[1]) and (nil ~= s[2])) and _5_()) then
        local pat = s[1]
        local act = s[2]
        ok = true
      elseif true then
        local _0 = s
        ok = {false, string.format("Invalid pattern for %s: %s", kind, vim.inspect(s))}
      else
        ok = nil
      end
    end
    _4_ = ok
  end
  if (_4_ == true) then
    return true
  elseif ((_G.type(_4_) == "table") and ((_4_)[1] == false) and (nil ~= (_4_)[2])) then
    local e = (_4_)[2]
    return nil, e
  else
    return nil
  end
end
local function needs_compile_3f(src, dest)
  local _let_8_ = require("hotpot.fs")
  local file_missing_3f = _let_8_["file-missing?"]
  local file_stat = _let_8_["file-stat"]
  local function _11_()
    local _let_9_ = file_stat(src)
    local smtime = _let_9_["mtime"]
    local _let_10_ = file_stat(dest)
    local dmtime = _let_10_["mtime"]
    return (dmtime.sec < smtime.sec)
  end
  return (file_missing_3f(dest) or _11_())
end
local function find_compile_targets(root_dir, spec)
  local files = {}
  local split = {build = {}, ignore = {}}
  for _, _12_ in ipairs(spec) do
    local _each_13_ = _12_
    local glob = _each_13_[1]
    local action = _each_13_[2]
    assert(string.match(glob, "%.fnl$"), string.format("build glob patterns must end in .fnl, got %s", glob))
    for _0, path in ipairs(vim.fn.globpath(root_dir, glob, true, true)) do
      local path0 = vim.fs.normalize(path)
      if (nil == files[path0]) then
        local _14_ = {string.find(glob, "fnl/"), action}
        local function _15_()
          local _1 = (_14_)[1]
          local f = (_14_)[2]
          return function_3f(f)
        end
        if (((_G.type(_14_) == "table") and true and (nil ~= (_14_)[2])) and _15_()) then
          local _1 = (_14_)[1]
          local f = (_14_)[2]
          local _16_ = f(path0)
          if (_16_ == false) then
            files[path0] = false
          else
            local function _17_()
              local dest_path = _16_
              return string_3f(dest_path)
            end
            if ((nil ~= _16_) and _17_()) then
              local dest_path = _16_
              files[path0] = string.gsub(vim.fs.normalize(dest_path), "%.fnl$", ".lua")
            elseif true then
              local _3fsome = _16_
              error(string.format("Invalid return value from build function: %s => %s", path0, type(_3fsome)))
            else
            end
          end
        elseif ((_G.type(_14_) == "table") and true and ((_14_)[2] == false)) then
          local _1 = (_14_)[1]
          files[path0] = false
        elseif ((_G.type(_14_) == "table") and ((_14_)[1] == 1) and ((_14_)[2] == true)) then
          files[path0] = (root_dir .. "/lua/" .. string.sub(path0, (#root_dir + 6), -4) .. "lua")
        elseif ((_G.type(_14_) == "table") and true and ((_14_)[2] == true)) then
          local _1 = (_14_)[1]
          files[path0] = (string.sub(path0, 1, -4) .. "lua")
        else
        end
      else
      end
    end
  end
  for path, action in pairs(files) do
    if action then
      table.insert(split.build, {src = path, dest = vim.fs.normalize(action)})
    else
      table.insert(split.ignore, {src = path})
    end
  end
  return split
end
local function find_clean_targets(root_dir, spec, compile_targets)
  local files = {}
  for _, _22_ in ipairs(spec) do
    local _each_23_ = _22_
    local glob = _each_23_[1]
    local action = _each_23_[2]
    assert(string.match(glob, "%.lua$"), string.format("clean glob patterns must end in .lua, got %s", glob))
    for _0, path in ipairs(vim.fn.globpath(root_dir, glob, true, true)) do
      if (nil == files[path]) then
        files[vim.fs.normalize(path)] = action
      else
      end
    end
  end
  for _, _25_ in ipairs(compile_targets) do
    local _each_26_ = _25_
    local dest = _each_26_["dest"]
    files[dest] = false
  end
  local tbl_17_auto = {}
  local i_18_auto = #tbl_17_auto
  for path, action in pairs(files) do
    local val_19_auto
    if action then
      val_19_auto = path
    else
      val_19_auto = nil
    end
    if (nil ~= val_19_auto) then
      i_18_auto = (i_18_auto + 1)
      do end (tbl_17_auto)[i_18_auto] = val_19_auto
    else
    end
  end
  return tbl_17_auto
end
local function do_compile(compile_targets, compiler_options, root_dir)
  local _let_29_ = require("hotpot.lang.fennel.compiler")
  local compile_file = _let_29_["compile-file"]
  do
    local _30_ = package.loaded
    if ((_G.type(_30_) == "table") and (nil ~= (_30_)["hotpot.fennel"])) then
      local fennel = (_30_)["hotpot.fennel"]
      for k, _ in pairs(fennel["macro-loaded"]) do
        fennel["macro-loaded"][k] = nil
      end
    else
    end
  end
  local function _34_(_32_)
    local _arg_33_ = _32_
    local src = _arg_33_["src"]
    local dest = _arg_33_["dest"]
    local tmp_path = (vim.fn.tempname() .. ".lua")
    local relative_filename = string.sub(src, (2 + #root_dir))
    local _35_, _36_ = nil, nil
    local _38_
    do
      local _37_ = compiler_options.modules
      _37_["filename"] = relative_filename
      _38_ = _37_
    end
    _35_, _36_ = compile_file(src, tmp_path, _38_, compiler_options.macros, compiler_options.preprocessor)
    if (_35_ == true) then
      return {src = src, dest = dest, ["tmp-path"] = tmp_path, ["compiled?"] = true}
    elseif ((_35_ == false) and (nil ~= _36_)) then
      local e = _36_
      return {src = src, dest = dest, err = e, ["compiled?"] = false}
    else
      return nil
    end
  end
  return map(_34_, compile_targets)
end
local function report_compile_results(compile_results, _40_)
  local _arg_41_ = _40_
  local any_errors_3f = _arg_41_["any-errors?"]
  local verbose_3f = _arg_41_["verbose?"]
  local atomic_3f = _arg_41_["atomic?"]
  local dry_run_3f = _arg_41_["dry-run?"]
  local report = {}
  if dry_run_3f then
    table.insert(report, {"No changes were written to disk! Compiled with dryrun = true!\n", "DiagnosticWarn"})
  else
  end
  if (any_errors_3f and atomic_3f) then
    table.insert(report, {"No changes were written to disk! Compiled with atomic = true and some files had compilation errors!\n", "DiagnosticWarn"})
  else
  end
  local function _44_(_241)
    local _let_45_ = _241
    local compiled_3f = _let_45_["compiled?"]
    local src = _let_45_["src"]
    local dest = _let_45_["dest"]
    local function _47_()
      if (_241)["compiled?"] then
        return {"\226\152\145  ", "DiagnosticOK"}
      else
        return {"\226\152\146  ", "DiagnosticWarn"}
      end
    end
    local _let_46_ = _47_()
    local char = _let_46_[1]
    local level = _let_46_[2]
    table.insert(report, {string.format("%s%s\n", char, src), level})
    return table.insert(report, {string.format("-> %s\n", dest), level})
  end
  local function _50_(_48_)
    local _arg_49_ = _48_
    local compiled_3f = _arg_49_["compiled?"]
    return (verbose_3f or not compiled_3f)
  end
  map(_44_, filter(_50_, compile_results))
  local function _51_(_241)
    if ((_G.type(_241) == "table") and (nil ~= (_241).err)) then
      local err = (_241).err
      return table.insert(report, {err, "DiagnosticError"})
    else
      return nil
    end
  end
  map(_51_, compile_results)
  if (0 < #report) then
    vim.api.nvim_echo(report, true, {})
  else
  end
  return nil
end
local function do_build(opts, root_dir, build_spec)
  assert(validate_spec("build", build_spec))
  local root_dir0 = vim.fs.normalize(root_dir)
  local _let_54_ = opts
  local force_3f = _let_54_["force"]
  local verbose_3f = _let_54_["verbose"]
  local dry_run_3f = _let_54_["dryrun"]
  local atomic_3f = _let_54_["atomic"]
  local _let_55_ = require("hotpot.fs")
  local rm_file = _let_55_["rm-file"]
  local copy_file = _let_55_["copy-file"]
  local compiler_options = opts.compiler
  local _let_56_ = find_compile_targets(root_dir0, build_spec)
  local all_compile_targets = _let_56_["build"]
  local all_ignore_targets = _let_56_["ignore"]
  local force_3f0
  local function _57_()
    local _58_ = opts["infer-force-for-file"]
    if (nil ~= _58_) then
      local file = _58_
      local function _59_(_241)
        return (_241.src == file)
      end
      return any_3f(_59_, all_ignore_targets)
    elseif true then
      local _ = _58_
      return false
    else
      return nil
    end
  end
  force_3f0 = (force_3f or _57_())
  local focused_compile_target
  local function _63_(_61_)
    local _arg_62_ = _61_
    local src = _arg_62_["src"]
    local dest = _arg_62_["dest"]
    return (force_3f0 or needs_compile_3f(src, dest))
  end
  focused_compile_target = filter(_63_, all_compile_targets)
  local compile_results = do_compile(focused_compile_target, compiler_options, root_dir0)
  local any_errors_3f
  local function _64_(_241)
    return not _241["compiled?"]
  end
  any_errors_3f = any_3f(_64_, compile_results)
  local function _67_(_65_)
    local _arg_66_ = _65_
    local tmp_path = _arg_66_["tmp-path"]
    local dest = _arg_66_["dest"]
    if tmp_path then
      if (not dry_run_3f and (not atomic_3f or not any_errors_3f)) then
        copy_file(tmp_path, dest)
      else
      end
      return rm_file(tmp_path)
    else
      return nil
    end
  end
  map(_67_, compile_results)
  report_compile_results(compile_results, {["any-errors?"] = any_errors_3f, ["dry-run?"] = dry_run_3f, ["verbose?"] = verbose_3f, ["atomic?"] = atomic_3f})
  local _return
  do
    local tbl_14_auto = {}
    for _, _70_ in ipairs(all_compile_targets) do
      local _each_71_ = _70_
      local src = _each_71_["src"]
      local dest = _each_71_["dest"]
      local k_15_auto, v_16_auto = src, {src = src, dest = dest}
      if ((k_15_auto ~= nil) and (v_16_auto ~= nil)) then
        tbl_14_auto[k_15_auto] = v_16_auto
      else
      end
    end
    _return = tbl_14_auto
  end
  local _return0
  do
    local tbl_14_auto = _return
    for _, _73_ in ipairs(compile_results) do
      local _each_74_ = _73_
      local src = _each_74_["src"]
      local compiled_3f = _each_74_["compiled?"]
      local err = _each_74_["err"]
      local k_15_auto, v_16_auto = nil, nil
      local function _76_()
        local _75_ = _return[src]
        _75_["compiled?"] = compiled_3f
        _75_["err"] = err
        return _75_
      end
      k_15_auto, v_16_auto = src, _76_()
      if ((k_15_auto ~= nil) and (v_16_auto ~= nil)) then
        tbl_14_auto[k_15_auto] = v_16_auto
      else
      end
    end
    _return0 = tbl_14_auto
  end
  local tbl_17_auto = {}
  local i_18_auto = #tbl_17_auto
  for _, v in pairs(_return0) do
    local val_19_auto = v
    if (nil ~= val_19_auto) then
      i_18_auto = (i_18_auto + 1)
      do end (tbl_17_auto)[i_18_auto] = val_19_auto
    else
    end
  end
  return tbl_17_auto
end
local function do_clean(clean_targets, opts)
  local _let_79_ = require("hotpot.fs")
  local rm_file = _let_79_["rm-file"]
  for _, file in ipairs(clean_targets) do
    local _80_, _81_ = rm_file(file)
    if (_80_ == true) then
      vim.notify(string.format("rm %s", file), vim.log.levels.WARN)
    elseif ((_80_ == false) and (nil ~= _81_)) then
      local e = _81_
      vim.notify(string.format("Could not clean file %s, %s", file, e), vim.log.levels.ERROR)
    else
    end
  end
  return nil
end
M.build = function(...)
  local _83_ = {...}
  local function _84_(...)
    local root = (_83_)[1]
    local build_specs = (_83_)[2]
    return (string_3f(root) and table_3f(build_specs))
  end
  if (((_G.type(_83_) == "table") and (nil ~= (_83_)[1]) and (nil ~= (_83_)[2]) and ((_83_)[3] == nil)) and _84_(...)) then
    local root = (_83_)[1]
    local build_specs = (_83_)[2]
    return do_build(merge_with_default_options({}), root, build_specs)
  else
    local function _85_(...)
      local root = (_83_)[1]
      local opts = (_83_)[2]
      local build_specs = (_83_)[3]
      return (string_3f(root) and table_3f(opts) and table_3f(build_specs))
    end
    if (((_G.type(_83_) == "table") and (nil ~= (_83_)[1]) and (nil ~= (_83_)[2]) and (nil ~= (_83_)[3]) and ((_83_)[4] == nil)) and _85_(...)) then
      local root = (_83_)[1]
      local opts = (_83_)[2]
      local build_specs = (_83_)[3]
      return do_build(merge_with_default_options(opts), root, build_specs)
    elseif true then
      local _ = _83_
      return vim.notify(("The hotpot.api.make usage has changed, please see\n" .. ":h hotpot-cookbook-using-dot-hotpot\n" .. ":h hotpot.api.make\n" .. "Unfortunately it was not possible to support both options simultaneously :( sorry."), vim.log.levels.WARN)
    else
      return nil
    end
  end
end
M.check = function(...)
  return vim.notify(("The hotpot.api.make usage has changed, please see\n" .. ":h hotpot-cookbook-using-dot-hotpot\n" .. ":h hotpot.api.make\n" .. "Unfortunately it was not possible to support both options simultaneously :( sorry."), vim.log.levels.WARN)
end
do
  local function build_spec_or_default(given_spec)
    local default_spec = {{"fnl/**/*macro*.fnl", false}, {"fnl/**/*.fnl", true}}
    local function _88_()
      if (given_spec == true) then
        return {default_spec, {}}
      elseif ((_G.type(given_spec) == "table") and ((_G.type(given_spec[1]) == "table") and ((given_spec[1])[1] == nil)) and (given_spec[2] == nil)) then
        local opts = given_spec[1]
        return {default_spec, opts}
      elseif ((_G.type(given_spec) == "table") and ((_G.type(given_spec[1]) == "table") and ((given_spec[1])[1] == nil))) then
        local opts = given_spec[1]
        local spec = {select(2, (table.unpack or _G.unpack)(given_spec))}
        return {spec, opts}
      elseif (nil ~= given_spec) then
        local spec = given_spec
        return {spec, {}}
      else
        return nil
      end
    end
    local _let_87_ = _88_()
    local spec = _let_87_[1]
    local opts = _let_87_[2]
    return {["build-spec"] = spec, ["build-options"] = opts}
  end
  local function clean_spec_or_default(clean_spec)
    if (clean_spec == true) then
      return {{"lua/**/*.lua", true}}
    else
      local function _89_()
        local t = clean_spec
        return table_3f(t)
      end
      if ((nil ~= clean_spec) and _89_()) then
        local t = clean_spec
        return t
      else
        return nil
      end
    end
  end
  local function handle_config(config, current_file, root_dir, _3fmanual_opts)
    if config.build then
      local function _91_(...)
        local _92_, _93_ = ...
        if ((_G.type(_92_) == "table") and (nil ~= (_92_)["build-spec"]) and (nil ~= (_92_)["build-options"])) then
          local build_spec = (_92_)["build-spec"]
          local build_options = (_92_)["build-options"]
          local function _94_(...)
            local _95_, _96_ = ...
            if (nil ~= _95_) then
              local build_options0 = _95_
              local function _97_(...)
                local _98_, _99_ = ...
                if (_98_ == true) then
                  local function _100_(...)
                    local _101_, _102_ = ...
                    if true then
                      local _ = _101_
                      local function _103_(...)
                        local _104_, _105_ = ...
                        if true then
                          local _0 = _104_
                          local function _106_(...)
                            local _107_, _108_ = ...
                            if (nil ~= _107_) then
                              local compile_results = _107_
                              local function _109_(...)
                                local _110_, _111_ = ...
                                if (nil ~= _110_) then
                                  local any_errors_3f = _110_
                                  if (config.clean and not build_options0.dryrun and (not build_options0.atomic or (build_options0.atomic and not any_errors_3f))) then
                                    local function _112_(...)
                                      local _113_, _114_ = ...
                                      if (nil ~= _113_) then
                                        local clean_spec = _113_
                                        local function _115_(...)
                                          local _116_, _117_ = ...
                                          if (_116_ == true) then
                                            local function _118_(...)
                                              local _119_, _120_ = ...
                                              if (nil ~= _119_) then
                                                local clean_targets = _119_
                                                local function _121_(...)
                                                  local _122_, _123_ = ...
                                                  if true then
                                                    local _1 = _122_
                                                    return compile_results
                                                  elseif ((_122_ == nil) and (nil ~= _123_)) then
                                                    local e = _123_
                                                    return vim.notify(e, vim.log.levels.ERROR)
                                                  else
                                                    return nil
                                                  end
                                                end
                                                return _121_(do_clean(clean_targets, build_options0))
                                              elseif ((_119_ == nil) and (nil ~= _120_)) then
                                                local e = _120_
                                                return vim.notify(e, vim.log.levels.ERROR)
                                              else
                                                return nil
                                              end
                                            end
                                            return _118_(find_clean_targets(root_dir, clean_spec, compile_results))
                                          elseif ((_116_ == nil) and (nil ~= _117_)) then
                                            local e = _117_
                                            return vim.notify(e, vim.log.levels.ERROR)
                                          else
                                            return nil
                                          end
                                        end
                                        return _115_(validate_spec("clean", clean_spec))
                                      elseif ((_113_ == nil) and (nil ~= _114_)) then
                                        local e = _114_
                                        return vim.notify(e, vim.log.levels.ERROR)
                                      else
                                        return nil
                                      end
                                    end
                                    return _112_(clean_spec_or_default(config.clean))
                                  else
                                    return compile_results
                                  end
                                elseif ((_110_ == nil) and (nil ~= _111_)) then
                                  local e = _111_
                                  return vim.notify(e, vim.log.levels.ERROR)
                                else
                                  return nil
                                end
                              end
                              local function _130_(_241)
                                return _241["err?"]
                              end
                              return _109_(any_3f(_130_, compile_results))
                            elseif ((_107_ == nil) and (nil ~= _108_)) then
                              local e = _108_
                              return vim.notify(e, vim.log.levels.ERROR)
                            else
                              return nil
                            end
                          end
                          return _106_(M.build(root_dir, build_options0, build_spec))
                        elseif ((_104_ == nil) and (nil ~= _105_)) then
                          local e = _105_
                          return vim.notify(e, vim.log.levels.ERROR)
                        else
                          return nil
                        end
                      end
                      build_options0.compiler = config.compiler
                      return _103_(nil)
                    elseif ((_101_ == nil) and (nil ~= _102_)) then
                      local e = _102_
                      return vim.notify(e, vim.log.levels.ERROR)
                    else
                      return nil
                    end
                  end
                  build_options0["infer-force-for-file"] = current_file
                  return _100_(nil)
                elseif ((_98_ == nil) and (nil ~= _99_)) then
                  local e = _99_
                  return vim.notify(e, vim.log.levels.ERROR)
                else
                  return nil
                end
              end
              return _97_(validate_spec("build", build_spec))
            elseif ((_95_ == nil) and (nil ~= _96_)) then
              local e = _96_
              return vim.notify(e, vim.log.levels.ERROR)
            else
              return nil
            end
          end
          local function _136_(...)
            if _3fmanual_opts then
              return vim.tbl_extend("force", build_options, _3fmanual_opts)
            else
              return build_options
            end
          end
          return _94_(_136_(...))
        elseif ((_92_ == nil) and (nil ~= _93_)) then
          local e = _93_
          return vim.notify(e, vim.log.levels.ERROR)
        else
          return nil
        end
      end
      return _91_(build_spec_or_default(config.build))
    else
      return nil
    end
  end
  local function build(file_dir_or_dot_hotpot, _3fopts)
    local _let_139_ = require("hotpot.runtime")
    local lookup_local_config = _let_139_["lookup-local-config"]
    local loadfile_local_config = _let_139_["loadfile-local-config"]
    local query_path = vim.loop.fs_realpath(vim.fn.expand(vim.fs.normalize(file_dir_or_dot_hotpot)))
    local opts = vim.tbl_extend("keep", (_3fopts or {}), {force = true, verbose = true})
    if query_path then
      local _140_ = lookup_local_config(query_path)
      if (nil ~= _140_) then
        local config_path = _140_
        local function _141_(...)
          local _142_ = ...
          if (nil ~= _142_) then
            local config = _142_
            local function _143_(...)
              local _144_ = ...
              if true then
                local _ = _144_
                return handle_config(config, query_path, vim.fs.dirname(config_path), opts)
              elseif true then
                local __75_auto = _144_
                return ...
              else
                return nil
              end
            end
            local function _146_(...)
              if not config.build then
                config.build = true
                return nil
              else
                return nil
              end
            end
            return _143_(_146_(...))
          elseif true then
            local __75_auto = _142_
            return ...
          else
            return nil
          end
        end
        return _141_(loadfile_local_config(config_path))
      elseif (_140_ == nil) then
        return vim.notify(string.format("No .hotpot.lua file found near %s", query_path), vim.log.levels.ERROR)
      else
        return nil
      end
    else
      return vim.notify(string.format("Unable to build, no file or directory found at %s.", file_dir_or_dot_hotpot), vim.log.levels.ERROR)
    end
  end
  local function attach(buf)
    if not (automake_memo["attached-buffers"])[buf] then
      automake_memo["attached-buffers"][buf] = true
      local function _150_()
        local _let_151_ = require("hotpot.runtime")
        local lookup_local_config = _let_151_["lookup-local-config"]
        local loadfile_local_config = _let_151_["loadfile-local-config"]
        local full_path_current_file = vim.fs.normalize(vim.fn.expand("<afile>:p"))
        local function _152_(...)
          local _153_ = ...
          if (nil ~= _153_) then
            local config_path = _153_
            local function _154_(...)
              local _155_ = ...
              if (nil ~= _155_) then
                local config = _155_
                return handle_config(config, full_path_current_file, vim.fs.dirname(config_path))
              elseif true then
                local __75_auto = _155_
                return ...
              else
                return nil
              end
            end
            return _154_(loadfile_local_config(config_path))
          elseif true then
            local __75_auto = _153_
            return ...
          else
            return nil
          end
        end
        _152_(lookup_local_config(full_path_current_file))
        return nil
      end
      return vim.api.nvim_create_autocmd("BufWritePost", {buffer = buf, desc = ("hotpot-check-dot-hotpot-dot-lua-for-" .. buf), callback = _150_})
    else
      return nil
    end
  end
  local function enable()
    if not automake_memo.augroup then
      automake_memo.augroup = vim.api.nvim_create_augroup("hotpot-automake-enabled", {clear = true})
      local function _159_(event)
        if ((_G.type(event) == "table") and (event.match == "fennel") and (nil ~= event.buf)) then
          local buf = event.buf
          attach(buf)
        else
        end
        return nil
      end
      return vim.api.nvim_create_autocmd("FileType", {group = automake_memo.augroup, pattern = "fennel", desc = "Hotpot automake auto-attach", callback = _159_})
    else
      return nil
    end
  end
  M.automake = {enable = enable, build = build}
end
return M