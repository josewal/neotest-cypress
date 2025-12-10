local M = {}

-- Default configuration for the Cypress adapter
M.defaults = {
  cypress_config_path = "cypress.config.ts",
  cypress_cmd = "npx cypress",
  args = { "--headless" },
}

-- Merge user config with defaults
function M.setup(user_config)
  return vim.tbl_deep_extend("force", M.defaults, user_config or {})
end

return M
