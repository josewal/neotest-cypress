---@diagnostic disable: undefined-global
local adapter = require("neotest-cypress.init")

describe("init adapter", function()
  it("identifies test files", function()
    assert.is_true(adapter.is_test_file("example.cy.ts"))
    assert.is_true(adapter.is_test_file("example.cy.js"))
    assert.is_false(adapter.is_test_file("example.ts"))
  end)

  it("filters directories", function()
    assert.is_false(adapter.filter_dir("node_modules"))
    assert.is_true(adapter.filter_dir("src"))
  end)

  it("discovers positions returns a table", function()
    local ok, positions = pcall(adapter.discover_positions, "tests/fixtures/basic.cy.ts")
    assert.is_true(ok)
    assert.is_table(positions)
  end)

  it("builds a run spec for a file with --spec only", function()
    local mock_tree = {
      data = function()
        return { 
          path = "tests/fixtures/basic.cy.ts", 
          id = "tests/fixtures/basic.cy.ts",
          type = "file",
          name = "basic.cy.ts"
        }
      end
    }
    local spec = adapter.build_spec({ tree = mock_tree })
    assert.is_table(spec)
    assert.is_table(spec.command)  -- command should be a string array
    assert.equals("sh", spec.command[1])
    assert.equals("-c", spec.command[2])
    assert.is_string(spec.cwd)  -- cwd should be set to project root
    assert.is_table(spec.context)
    assert.equals("tests/fixtures/basic.cy.ts", spec.context.file)
    -- File runs: should contain --spec, NOT grep
    local cmd_str = spec.command[3]
    assert.is_truthy(string.find(cmd_str, "--spec"))
    assert.is_nil(string.find(cmd_str, "--env grep"))
  end)

  it("builds a run spec with grep only for a specific test", function()
    local mock_tree = {
      data = function()
        return { 
          path = "tests/fixtures/basic.cy.ts", 
          id = "tests/fixtures/basic.cy.ts::basic test suite::should pass",
          type = "test",
          name = "should pass"
        }
      end
    }
    local spec = adapter.build_spec({ tree = mock_tree })
    assert.is_table(spec)
    assert.is_table(spec.command)
    assert.equals("sh", spec.command[1])
    assert.equals("-c", spec.command[2])
    -- Test runs: should contain grep, NOT --spec
    local cmd_str = spec.command[3]
    assert.is_truthy(string.find(cmd_str, '--env grep="should pass"'))
    assert.is_truthy(string.find(cmd_str, "grepFilterSpecs=true"))
    assert.is_nil(string.find(cmd_str, "--spec"))
  end)

  it("builds a run spec with grep only for a namespace", function()
     local mock_tree = {
       data = function()
         return { 
           path = "tests/fixtures/basic.cy.ts", 
           id = "tests/fixtures/basic.cy.ts::basic test suite",
           type = "namespace",
           name = "basic test suite"
         }
       end
     }
     local spec = adapter.build_spec({ tree = mock_tree })
     local cmd_str = spec.command[3]
     -- Namespace runs: should contain grep, NOT --spec
     assert.is_truthy(string.find(cmd_str, '--env grep="basic test suite"'))
     assert.is_truthy(string.find(cmd_str, "grepFilterSpecs=true"))
     assert.is_nil(string.find(cmd_str, "--spec"))
   end)


 end)


