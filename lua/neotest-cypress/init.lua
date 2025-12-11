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

-- Get all marked test positions from NeoTest
-- Returns a table of {position_id, test_name} pairs for marked tests
local function get_marked_tests()
  local neotest = require("neotest")
  if not neotest or not neotest.summary or not neotest.summary.marked then
    return {}
  end
  
  -- marked() returns table<adapter_id, string[]> where string[] are position IDs
  local marked = neotest.summary.marked()
  local marked_tests = {}
  
  for adapter_id, position_ids in pairs(marked) do
    for _, pos_id in ipairs(position_ids) do
      table.insert(marked_tests, pos_id)
    end
  end
  
  return marked_tests
end

-- Check if the current position is the last marked test
-- Returns true if this is the last one, so we should execute the combined command
local function is_last_marked_test(current_pos_id, marked_tests)
  if #marked_tests == 0 then
    return false
  end
  
  -- Find current position in marked tests list
  for i, pos_id in ipairs(marked_tests) do
    if pos_id == current_pos_id then
      -- Check if this is the last one (or if all remaining are the same position)
      return i == #marked_tests
    end
  end
  
  return false
end

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

    pp("build_spec", {
      spec = position.path,
      position_id = position.id,
      position_type = position.type,
      position_name = position.name,
      cwd = cwd
    })

    -- Use json reporter which outputs to stdout
    -- NeoTest captures stdout to result.output which we parse in results()
    -- Use --config to override reporter settings from cypress.config.ts
    -- Disable video to suppress video output messages
    --
    -- Wrap the command in a shell that ensures we always get SOME output
    -- This prevents NeoTest from having an empty result.output

    local cypress_cmd
    
    -- Check for marked tests to run them in a single process
    if position.type == "test" or position.type == "namespace" then
      local marked_tests = get_marked_tests()
      
      if #marked_tests > 1 then
        -- Multiple marked tests: check if this is the last one
        if is_last_marked_test(position.id, marked_tests) then
          -- Build a combined grep pattern for all marked tests
          -- Extract test names from position IDs (last component after ::)
          local test_patterns = {}
          
          for _, pos_id in ipairs(marked_tests) do
            -- Position ID format: file_path::namespace1::namespace2::test_name
            -- Extract the last part (test name)
            local test_name = util.get_test_name_from_id(pos_id)
            if test_name then
              table.insert(test_patterns, util.escape_grep_pattern(test_name))
            end
          end
          
          -- Combine patterns with semicolon separator (cypress-grep syntax)
          local combined_pattern = table.concat(test_patterns, ";")
          
          pp("build_spec: combined marked tests", {
            count = #marked_tests,
            pattern = combined_pattern
          })
          
          cypress_cmd = string.format(
            "npx --silent cypress run --env grep=\"%s\",grepFilterSpecs=true,grepOmitFiltered=true --reporter json --config reporter=json,reporterOptions={},video=false --headless --quiet 2>&1",
            combined_pattern
          )
        else
          -- Not the last marked test, return no-op spec
          -- The actual execution will happen when the final marked test runs
          pp("build_spec: returning no-op for non-final marked test", position.id)
          
          return {
            command = { "sh", "-c", "echo '{}'" },
            cwd = cwd,
            context = {
              pos_id = position.id,
              file = position.path,
              skipped_for_batch = true,  -- Flag for results() to detect
            },
          }
        end
      else
        -- Single test: use grep as normal
        local grep_pattern = util.escape_grep_pattern(position.name)
        cypress_cmd = string.format(
          "npx --silent cypress run --env grep=\"%s\",grepFilterSpecs=true,grepOmitFiltered=true --reporter json --config reporter=json,reporterOptions={},video=false --headless --quiet 2>&1",
          grep_pattern
        )
      end
    else
      -- File-level run: use --spec to run entire file
      cypress_cmd = string.format(
        "npx --silent cypress run --spec %s --reporter json --config reporter=json,reporterOptions={},video=false --headless --quiet 2>&1",
        vim.fn.shellescape(position.path)
      )
    end
    
    pp("build_spec: command", cypress_cmd)

    -- For combined grep runs, set file to root since grep searches all specs
    local context_file = position.path
    if position.type == "test" or position.type == "namespace" then
      local marked_tests = get_marked_tests()
      if #marked_tests > 1 and is_last_marked_test(position.id, marked_tests) then
        context_file = cwd  -- Use root for combined grep
      end
    end

    return {
      command = { "sh", "-c", cypress_cmd },
      cwd = cwd,
      context = {
        pos_id = position.id,
        file = context_file,
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
    -- Check if this was a skipped batch test (no-op for combined marked test execution)
    if spec.context and spec.context.skipped_for_batch then
      pp("results: skipped batch test, returning running status", spec.context.pos_id)
      return {
        [spec.context.pos_id] = {
          status = "running",
          short = "Waiting for combined batch execution",
        }
      }
    end

    local file_path = spec.context.file or tree:data().path
    
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
      output_file = result.output,
      exit_code = result.code
    })

    -- NeoTest captures stdout to a file at result.output
    -- Check if output is nil, empty, or just whitespace
    if not result.output or result.output == "" or result.output:match("^%s*$") then
      pp("results: no output file from neotest", {
        output_value = result.output,
        output_type = type(result.output)
      })
      -- Return a result for the file even when output is missing
      return {
        [file_path] = {
          status = "failed",
          short = "No output file from NeoTest",
          errors = {{
            message = "NeoTest did not capture any output. This might be a configuration issue."
          }}
        }
      }
    end

    -- Check if the output file exists before trying to read it
    local file_exists = vim.fn.filereadable(result.output) == 1
    if not file_exists then
      pp("results: output file does not exist", {
        output_path = result.output,
        cwd = vim.fn.getcwd()
      })
      -- Return failed status for the file if output file doesn't exist
      return {
        [file_path] = {
          status = "failed",
          short = "Cypress output file not found",
          errors = {{
            message = string.format("Cypress failed to run or did not create output file.\nOutput path: %s\nExit code: %s", 
              result.output, (result.code or "unknown"))
          }}
        }
      }
    end

    -- Read stdout from the output file that NeoTest created
    local output_content = lib.files.read(result.output)
    if not output_content or output_content == "" then
      pp("results: output file empty", result.output)
      -- Return failed status for the file if Cypress didn't produce output
      return {
        [file_path] = {
          status = "failed",
          short = "Cypress did not produce any output",
          errors = {{
            message = "Cypress failed to run. Exit code: " .. (result.code or "unknown")
          }}
        }
      }
    end

    local parsed_results = results_parser.parse_from_output(output_content, file_path, tree)
    pp("results: parsed", {
      file_path = file_path,
      result_count = parsed_results and vim.tbl_count(parsed_results) or 0
    })

    -- NeoTest requires an output field pointing to a file that contains the raw output
    -- Set this on all results so the output panel can display it
    if parsed_results then
      for pos_id, test_result in pairs(parsed_results) do
        test_result.output = result.output
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
