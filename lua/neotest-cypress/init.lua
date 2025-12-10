local lib = require("neotest.lib")

local M = {}

M.name = "neotest-cypress"

-- Find the project root by locating cypress.config.ts/js or package.json
function M.root(dir)
  return lib.files.match_root_pattern("cypress.config.ts", "cypress.config.js", "package.json")(dir)
end

-- Identify Cypress test files by pattern *.cy.{ts,tsx,js,jsx}
function M.is_test_file(file_path)
  if not file_path then
    return false
  end
  return vim.endswith(file_path, ".cy.ts")
    or vim.endswith(file_path, ".cy.tsx")
    or vim.endswith(file_path, ".cy.js")
    or vim.endswith(file_path, ".cy.jsx")
end

-- Filter out directories that should not be searched
function M.filter_dir(name)
  return name ~= "node_modules" and name ~= ".git" and name ~= "dist" and name ~= "build"
end

-- Discover test positions using treesitter
function M.discover_positions(file_path)
  -- TODO: Implement in Phase 2
  return {}
end

-- Build the Cypress command to execute tests
function M.build_spec(args)
  local position = args.tree:data()
  local results_path = vim.fn.tempname() .. ".json"
  
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
    },
  }
end

-- Parse Cypress JSON output and map to NeoTest format
function M.results(spec, result, tree)
  -- TODO: Implement in Phase 3
  return {}
end

return M
