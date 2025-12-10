local vim = vim
---@type neotest.lib
local lib = require("neotest.lib")
local results_parser = require("neotest-cypress.results")
local util = require("neotest-cypress.util")
local config = require("neotest-cypress.config")
require("neotest-cypress.types")

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

  -- Try to find the project root by searching up the directory tree
  local root_path = lib.files.match_root_pattern(
    "cypress.config.ts",
    "cypress.config.js",
    "package.json"
  )(dir)

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
  local positions = lib.treesitter.parse_positions(file_path, query_content, {
    nested_namespaces = true,
    nested_tests = false,
    require_namespaces = false,
    position_id = util.create_position_id,
  })

  if positions and #positions > 0 then
    pp("discover_positions: treesitter found", #positions .. " positions")
  else
    pp("discover_positions: no positions found", file_path)
    return
  end

  return positions
end

-- Build the Cypress command to execute tests
---@param args {tree: neotest.Tree}
---@return nil | neotest.RunSpec | neotest.RunSpec[]
function M.build_spec(args)
  return util.safe_call(function()
    local position = args.tree:data()

    pp("build_spec", {
      spec = position.path,
      position_id = position.id
    })

    -- Use json reporter which outputs to stdout
    -- NeoTest captures stdout to result.output which we parse in results()
    return {
      command = "npx",
      args = {
        "cypress",
        "run",
        "--spec",
        position.path,
        "--reporter",
        "json",
        "--headless",
      },
      context = {
        pos_id = position.id,
        file = position.path,
      },
    }
  end)
end

-- Parse Cypress JSON output and map to NeoTest format
---@param spec neotest.RunSpec
---@param result table
---@param tree neotest.Tree
---@return table
function M.results(spec, result, tree)
  return util.safe_call(function()
    local file_path = spec.context.file or tree:data().path

    pp("results: parsing output", {
      output_file = result.output,
      exit_code = result.code
    })

    -- NeoTest captures stdout to a file at result.output
    if not result.output then
      pp("results: no output file from neotest", "missing")
      return {}
    end

    -- Read stdout from the output file that NeoTest created
    local output_content = lib.files.read(result.output)
    if not output_content or output_content == "" then
      pp("results: output file empty or missing", result.output)
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

    local parsed_results = results_parser.parse_from_output(output_content, file_path)
    pp("results: parsed", {
      file_path = file_path,
      result_count = parsed_results and vim.tbl_count(parsed_results) or 0
    })

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
