local vim = vim
---@type neotest.Position, neotest.Tree, neotest.RunSpec
local lib = require("neotest.lib")
local results_parser = require("neotest-cypress.results")
local util = require("neotest-cypress.util")
require("neotest-cypress.types")

local M = {}

M.name = "neotest-cypress"

-- Find the project root by locating cypress.config.ts/js or package.json
---@param dir string
---@return string|nil
function M.root(dir)
  return util.safe_call(function()
    util.log("Searching for project root in: " .. tostring(dir), "DEBUG")
    local root_path = lib.files.match_root_pattern("cypress.config.ts", "cypress.config.js", "package.json")(dir)
    util.log("Found project root: " .. tostring(root_path), "DEBUG")
    return root_path
  end)
end

-- Identify Cypress test files by pattern *.cy.{ts,tsx,js,jsx}
---@param file_path string
---@return boolean
function M.is_test_file(file_path)
  return util.safe_call(function()
    if not file_path then
      util.log("File path is nil", "DEBUG")
      return false
    end
    
    local is_cypress_test = 
      vim.endswith(file_path, ".cy.ts") or
      vim.endswith(file_path, ".cy.tsx") or
      vim.endswith(file_path, ".cy.js") or
      vim.endswith(file_path, ".cy.jsx")
    
    util.log({file_path = file_path, is_cypress_test = is_cypress_test}, "DEBUG")
    return is_cypress_test
  end)
end

-- Filter out directories that should not be searched
---@param name string
---@return boolean
function M.filter_dir(name)
  return util.safe_call(function()
    local filtered = name ~= "node_modules" and 
                     name ~= ".git" and 
                     name ~= "dist" and 
                     name ~= "build"
    
    util.log({dir = name, filtered = filtered}, "DEBUG")
    return filtered
  end)
end

-- Discover test positions using treesitter
---@param file_path string
---@return neotest.Position[]
function M.discover_positions(file_path)
  return util.safe_call(function()
    util.log("Discovering positions for: " .. tostring(file_path), "DEBUG")
    
    local query = lib.treesitter.parse_positions(file_path, {
      nested_namespaces = true,
      require_namespaces = false,
      position_id = function(file, names)
        return require('neotest-cypress.util').create_position_id(file, names)
      end,
    })
    
    if not query then
      util.log("Falling back to default position parsing", "WARN")
      query = lib.positions.parse_tree(lib.files.read(file_path))
    end
    
    util.log("Discovered positions", "DEBUG")
    return query or {}
  end)
end

-- Build the Cypress command to execute tests
---@param args {tree: neotest.Tree}
---@return neotest.RunSpec
function M.build_spec(args)
  return util.safe_call(function()
    local position = args.tree:data()
    local results_path = vim.fn.tempname() .. ".json"
    
    util.log({
      position_path = position.path,
      results_path = results_path,
      position_id = position.id
    }, "DEBUG")
    
    return {
      command = "npx",
      args = {
        "cypress",
        "run",
        "--spec",
        position.path,
        "--reporter",
        "json",
        "--reporter-options",
        "output=" .. results_path,
        "--headless",
      },
      context = {
        results_path = results_path,
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
    local results_path = spec.context.results_path
    local file_path = spec.context.file or tree:data().path

    -- Use the 'result' parameter for future debugging if needed
    util.log({result = result}, "DEBUG")

    if not results_path then
      util.log("No results path provided", "WARN")
      return {}
    end

    local parsed_results = results_parser.parse(results_path, file_path)
    util.log({
      results_path = results_path,
      file_path = file_path, 
      parsed_results_count = parsed_results and vim.tbl_count(parsed_results) or 0
    }, "DEBUG")

    return parsed_results or {}
  end)
end

-- Optional: Add a debug mode toggle
---@param opts? {debug: boolean}
function M.setup(opts)
  opts = opts or {}
  util.set_debug_mode(opts.debug or false)
end

return M