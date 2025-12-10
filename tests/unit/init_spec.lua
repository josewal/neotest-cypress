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

  it("builds a run spec for a simple tree", function()
    local mock_tree = {
      data = function()
        return { path = "tests/fixtures/basic.cy.ts", id = "pos1" }
      end
    }
    local spec = adapter.build_spec({ tree = mock_tree })
    assert.is_table(spec)
    assert.is_string(spec.command)
    assert.is_table(spec.args)
    assert.is_table(spec.context)
    assert.equals("tests/fixtures/basic.cy.ts", spec.context.file)
  end)
end)
