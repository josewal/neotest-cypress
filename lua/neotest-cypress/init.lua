local vim = vim
---@type neotest.lib
local lib = require("neotest.lib")
local results_parser = require("neotest-cypress.results")
local util = require("neotest-cypress.util")
local config = require("neotest-cypress.config")
require("neotest.types")

-- Debug logging utility using util.log
local function pp(label, value)
  if type(value) == "table" then
    util.log({[label] = value}, "DEBUG")
  else
    util.log(string.format("%s: %s", label, tostring(value)), "DEBUG")
  end
end

local M = {}

M.name = "neotest-cypress"

-- Configuration
local current_config = config.defaults

-- Find the project root by locating cypress.config.ts/js or package.json
---@param dir string
---@return string|nil
function M.root(dir)
  -- Set log level from config on first call
  if current_config.log_level then
    util.log_level = current_config.log_level
  end

  pp("root: searching", dir)

  -- First, try to find the project root by searching up the directory tree
  local root_path = lib.files.match_root_pattern(
    "cypress.config.ts",
    "cypress.config.js",
    "package.json"
  )(dir)

  -- If not found by searching up, try searching down for cypress.config files
  if not root_path then
    pp("root: not found upward, searching downward", dir)
    
    -- Search for cypress.config.ts/js in subdirectories (max 3 levels deep)
    local handle = vim.loop.fs_scandir(dir)
    if handle then
      while true do
        local name, type = vim.loop.fs_scandir_next(handle)
        if not name then break end
        
        if type == "directory" and name ~= "node_modules" and name ~= ".git" then
          local subdir = dir .. "/" .. name
          -- Check if this subdirectory contains a cypress config
          local cypress_config_ts = subdir .. "/cypress.config.ts"
          local cypress_config_js = subdir .. "/cypress.config.js"
          
          if vim.loop.fs_stat(cypress_config_ts) then
            root_path = subdir
            pp("root: found downward (cypress.config.ts)", root_path)
            break
          elseif vim.loop.fs_stat(cypress_config_js) then
            root_path = subdir
            pp("root: found downward (cypress.config.js)", root_path)
            break
          end
        end
      end
    end
  end

  pp("root: found", root_path)
  return root_path
end

-- Identify Cypress test files by pattern *.cy.{ts,tsx,js,jsx}
---@param file_path string
---@return boolean
function M.is_test_file(file_path)
  if not file_path then
    return false
  end

  -- Check if file matches Cypress test patterns
  local is_cypress_test =
    vim.endswith(file_path, ".cy.ts") or
    vim.endswith(file_path, ".cy.tsx") or
    vim.endswith(file_path, ".cy.js") or
    vim.endswith(file_path, ".cy.jsx")

  -- Only print when it's actually a test file to reduce noise
  if is_cypress_test then
    pp("is_test_file", file_path)
  end

  return is_cypress_test
end

-- Filter out directories that should not be searched
---@param name string
---@return boolean
function M.filter_dir(name)
  local filtered = name ~= "node_modules" and
                   name ~= ".git" and
                   name ~= "dist" and
                   name ~= "build"

  -- Reduce printing verbosity - only print when filtering out directories
  if not filtered then
    pp("filter_dir: excluding", name)
  end

  return filtered
end

-- Discover test positions using treesitter
---@param file_path string
---@return neotest.Tree | nil
function M.discover_positions(file_path)
  pp("discover_positions: parsing", file_path)

  -- Get the plugin directory
  local plugin_dir = vim.fn.fnamemodify(debug.getinfo(1).source:sub(2), ":h:h:h")

  -- Determine file type to select appropriate query
  local query_file = "queries/javascript/positions.scm"
  local query_path = plugin_dir .. "/" .. query_file

  -- Load the query from the positions.scm file
  local query_content = lib.files.read(query_path)
  if not query_content then
    pp("discover_positions: failed to load query", query_path)
    return {}
  end

  -- Try to parse positions with treesitter using the loaded query
  -- Use default position_id (path::parent1::parent2::name format)
---@diagnostic disable-next-line: missing-fields
  local positions = lib.treesitter.parse_positions(file_path, query_content, {
    nested_namespaces = true,
    require_namespaces = true,
  })

  if positions then
    pp("discover_positions: treesitter parsed", file_path)
  else
    pp("discover_positions: no positions found", file_path)
  end

  return positions
end

-- Build the Cypress command to execute tests
---@param args {tree: neotest.Tree}
---@return nil | neotest.RunSpec | neotest.RunSpec[]
function M.build_spec(args)
  return util.safe_call(function()
    local position = args.tree:data()

    -- Find the project root directory
    local cwd = M.root(position.path)
    
    -- Create a temporary file for Cypress JSON output
    -- NOTE: Unlike JUnit/Mochawesome reporters, Mocha's JSON reporter does NOT support
    -- --reporter-options output=file.json. We must use stdout redirection instead.
    local results_file = os.tmpname() .. "_cypress.json"

    pp("build_spec", {
      spec = position.path,
      position_id = position.id,
      position_type = position.type,
      position_name = position.name,
      cwd = cwd,
      results_file = results_file
    })

    local cypress_cmd

    -- Build appropriate command based on position type
    -- NOTE: JSON reporter doesn't support file output directly, so we use stdout redirection
    if position.type == "file" then
      -- File-level run: use --spec to run entire file with JSON output redirected to file
      cypress_cmd = string.format(
        "npx --silent cypress run --spec %s --reporter json --config video=false --headless > %s",
        util.shell_escape(position.path),
        util.shell_escape(results_file)
      )
    else
      -- Test or namespace: use grep to filter with JSON output redirected to file
      local grep_pattern = position.name
      cypress_cmd = string.format(
        "npx --silent cypress run --env grep='%s',grepFilterSpecs=true,grepOmitFiltered=true --reporter json --config video=false --headless > %s",
        grep_pattern,
        util.shell_escape(results_file)
      )
    end

    pp("build_spec: command", cypress_cmd)

    return {
      command = { "sh", "-c", cypress_cmd },
      cwd = cwd,
      context = {
        pos_id = position.id,
        file = position.path,
        results_file = results_file,
      },
    }
  end)
end

-- Parse Cypress JSON output and map to NeoTest format
---@param spec neotest.RunSpec
---@param result table
---@param tree neotest.Tree
---@return neotest.Result[]
function M.results(spec, result, tree)
  return util.safe_call(function()
    local file_path = spec.context.file or tree:data().path
    local results_file = spec.context.results_file
    
    -- Ensure file_path is valid
    if not file_path or file_path == "" then
      pp("results: invalid file_path", {
        spec_context_file = spec.context.file,
        tree_data_path = tree:data().path
      })
      return {}
    end

    pp("results: parsing output", {
      file_path = file_path,
      results_file = results_file,
      neotest_output_file = result.output,
      exit_code = result.code
    })

    -- First, try to read from the dedicated Cypress JSON results file
    local json_content = nil
    local output_file_for_panel = nil
    
    if results_file and lib.files.exists(results_file) then
      pp("results: reading from dedicated results file", results_file)
      json_content = lib.files.read(results_file)
      -- Keep the clean results file for the output panel - don't delete it yet
      output_file_for_panel = results_file
    end

    -- If no dedicated results file or it's empty, fall back to NeoTest's output capture
    if not json_content or json_content == "" then
      pp("results: falling back to neotest output", {
        results_file_exists = results_file and lib.files.exists(results_file),
        results_file_empty = json_content == "",
        neotest_output = result.output
      })
      
      if not result.output or result.output == "" then
        pp("results: no output available", {
          results_file = results_file,
          neotest_output = result.output
        })
        return {
          [file_path] = {
            status = "failed",
            short = "No output from Cypress",
            errors = {{
              message = string.format("Cypress failed to produce output.\nExit code: %s\nResults file: %s", 
                (result.code or "unknown"), (results_file or "none"))
            }},
            output = result.output or ""
          }
        }
      end
      
      -- Check if the NeoTest output file exists
      local neotest_file_exists = lib.files.exists(result.output)
      if not neotest_file_exists then
        pp("results: neotest output file does not exist", result.output)
        return {
          [file_path] = {
            status = "failed",
            short = "Output file not found",
            errors = {{
              message = string.format("Neither Cypress results file nor NeoTest output file found.\nCypress file: %s\nNeoTest file: %s\nExit code: %s", 
                (results_file or "none"), result.output, (result.code or "unknown"))
            }},
            output = result.output or ""
          }
        }
      end
      
      -- Read from NeoTest's output file and try to extract JSON
      json_content = lib.files.read(result.output)
      if not json_content or json_content == "" then
        pp("results: neotest output file empty", result.output)
        return {
          [file_path] = {
            status = "failed",
            short = "Empty output file",
            errors = {{
              message = "Cypress produced no output. Exit code: " .. (result.code or "unknown")
            }},
            output = result.output or ""
          }
        }
      end
    end

    -- Parse the JSON content
    local parsed_results = results_parser.parse_from_output(json_content, file_path, tree)
    pp("results: parsed", {
      file_path = file_path,
      result_count = parsed_results and vim.tbl_count(parsed_results) or 0
    })

    -- NeoTest requires an output field pointing to a file that contains the raw output
    -- Set this on all results so the output panel can display it
    if parsed_results then
      for pos_id, test_result in pairs(parsed_results) do
        -- Use the clean JSON results file if available, otherwise fall back to NeoTest's output
        test_result.output = output_file_for_panel or result.output or ""
      end
    end

    return parsed_results or {}
  end)
end

-- Setup function to configure the adapter
---@param opts? table
function M.setup(opts)
  opts = opts or {}
  current_config = config.setup(opts)

  -- Set log level from config
  if current_config.log_level then
    util.log_level = current_config.log_level
  end

  pp("setup: configured", {
    log_level = current_config.log_level
  })
end

return M
