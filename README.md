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
- Cypress >= 10.0.0

### Cypress Project Dependencies

This adapter requires the `@cypress/grep` plugin to be installed in your Cypress project for test filtering support.

**Install with npm:**
```bash
npm install --save-dev @cypress/grep
```

**Or with yarn:**
```bash
yarn add --dev @cypress/grep
```

**Note:** The adapter uses Cypress's built-in JSON reporter for test results, so no additional reporter packages are needed.

For complete installation and configuration details, see the [cypress-grep documentation](https://github.com/cypress-io/cypress/tree/develop/npm/grep#readme).

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
    {
        "josewal/neotest-cypress",
    },
    {
        "nvim-neotest/neotest",
        opts = {
            adapters = {
                ["neotest-cypress"] = {}
            }
        },
    },
}

```

## Configuration

### Cypress Configuration

Your `cypress.config.ts` (or `cypress.config.js`) must include the cypress-grep plugin configuration:

```typescript
import { defineConfig } from 'cypress';

export default defineConfig({
  e2e: {
    setupNodeEvents(on, config) {
      // Required: cypress-grep plugin for test filtering
      const { plugin: cypressGrepPlugin } = require('@cypress/grep/plugin');
      cypressGrepPlugin(config);
      
      return config;
    },
  },
});
```

**Important:** Without cypress-grep properly configured, the adapter will likely still work but will only be able to run entire test files, not individual tests or describe blocks.

For complete installation and configuration details, see the [cypress-grep documentation](https://github.com/cypress-io/cypress/tree/develop/npm/grep#readme).

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

## License

MIT

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
