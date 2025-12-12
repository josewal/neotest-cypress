# neotest-cypress

> ⚠️ **UNDER ACTIVE DEVELOPMENT** - This project is in early stages of development and may contain bugs. Use with caution in production environments. Your feedback and bug reports are welcome!

A [NeoTest](https://github.com/nvim-neotest/neotest) adapter for [Cypress](https://www.cypress.io/) v10+ end-to-end testing.

## Features

- Run Cypress E2E tests directly from Neovim
- Support for TypeScript and JavaScript test files
- Test discovery using treesitter queries
- Support for `describe`, `context`, `it`, and `specify` blocks
- Support for `.skip` and `.only` modifiers
- Real-time test results with error messages and stack traces

## Requirements

- Neovim >= 0.9.0
- [nvim-neotest/neotest](https://github.com/nvim-neotest/neotest)
- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) with JavaScript/TypeScript parsers
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)
- Cypress >= 10.0.0

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "nvim-neotest/neotest",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
    "nvim-neotest/nvim-nio",
    "josewal/neotest-cypress",
  },
  config = function()
    require("neotest").setup({
      adapters = {
        require("neotest-cypress"),
      },
    })
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "nvim-neotest/neotest",
  requires = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
    "nvim-neotest/nvim-nio",
    "josewal/neotest-cypress",
  },
  config = function()
    require("neotest").setup({
      adapters = {
        require("neotest-cypress"),
      },
    })
  end,
}
```

## Configuration

The adapter comes with sensible defaults, but you can customize it:

```lua
require("neotest").setup({
  adapters = {
    require("neotest-cypress")({
      cypress_config_path = "cypress.config.ts", -- or "cypress.config.js"
      cypress_cmd = "npx cypress",
      args = { "--headless" },
    }),
  },
})
```

## Usage

Once installed, you can use NeoTest commands to run your Cypress tests:

- `:lua require("neotest").run.run()` - Run the nearest test
- `:lua require("neotest").run.run(vim.fn.expand("%"))` - Run the current file
- `:lua require("neotest").summary.toggle()` - Toggle the test summary window
- `:lua require("neotest").output.open()` - Open the test output window

For more NeoTest commands, see the [NeoTest documentation](https://github.com/nvim-neotest/neotest).

## Supported Test Patterns

The adapter recognizes Cypress test files with the following extensions:
- `*.cy.ts`
- `*.cy.tsx`
- `*.cy.js`
- `*.cy.jsx`

And supports the following test structures:
- `describe()`, `context()` - Test suites/namespaces
- `it()`, `specify()` - Individual tests
- `.skip` and `.only` modifiers

## Known Limitations & Status

### Current Status
- **MVP Phase:** Core functionality implemented but not yet fully tested in real-world scenarios
- **Test Coverage:** 19 unit tests passing, but integration testing with actual Cypress projects is ongoing

### Limitations
- **Cypress v10+ only** - No support for legacy Cypress versions
- **E2E tests only** - Component testing is not supported in the MVP
- Tests must follow the pattern `*.cy.{ts,tsx,js,jsx}`
- **Integration testing pending** - Not yet validated against real Cypress projects

### Known Issues & Bugs
This adapter is under active development. Potential issues include:
- Edge cases in test discovery for complex nested structures
- Possible compatibility issues with non-standard Cypress configurations
- JSON reporter output parsing may fail with custom reporters
- Error message extraction may be incomplete for certain error types

If you encounter bugs, please [open an issue](https://github.com/your-username/neotest-cypress/issues) with details about your setup and the problematic test file.

## Development

### Running Tests

This project uses **vusted**, a Lua testing framework, for unit tests.

**Install vusted (if not already installed):**
```bash
luarocks --lua-version=5.1 install vusted
```

**Run all tests:**
```bash
LUA_PATH="./tests/mock/?.lua;./tests/mock/?/init.lua;${LUA_PATH}" vusted tests/unit/
```

**Run a single test file:**
```bash
LUA_PATH="./tests/mock/?.lua;./tests/mock/?/init.lua;${LUA_PATH}" vusted tests/unit/config_spec.lua
```

**Run with verbose output:**
```bash
LUA_PATH="./tests/mock/?.lua;./tests/mock/?/init.lua;${LUA_PATH}" vusted tests/unit/ --verbose
```

For convenience, you can create an alias:
```bash
alias test-neocy='LUA_PATH="./tests/mock/?.lua;./tests/mock/?/init.lua;${LUA_PATH}" vusted tests/unit/'
test-neocy
```

**Current test coverage:** 19 unit tests covering configuration, test discovery, test execution, and utility functions.

## License

MIT

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
