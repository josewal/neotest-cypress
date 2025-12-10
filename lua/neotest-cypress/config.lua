local M = {}

-- Default configuration for the Cypress adapter
M.defaults = {
  cypress_config_path = "cypress.config.ts",
  cypress_cmd = "npx cypress",
  args = { "--headless" },
  -- Include patterns for test files
  include = {
    "**/*.cy.ts",
    "**/*.cy.tsx", 
    "**/*.cy.js",
    "**/*.cy.jsx"
  },
  -- Exclude patterns for directories and files
  exclude = {
    "**/node_modules/**",
    "**/.git/**",
    "**/dist/**",
    "**/build/**"
  },
  -- Log level: "OFF", "ERROR", "WARN", "INFO", "DEBUG"
  log_level = "INFO"
}

-- Merge user config with defaults
function M.setup(user_config)
  return vim.tbl_deep_extend("force", M.defaults, user_config or {})
end

return M