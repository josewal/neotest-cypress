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

   it("returns no-op spec for non-final marked tests", function()
     local neotest = require("neotest")
     -- Set up marked tests: test A and test B
     neotest.summary._set_marked({
       ["neotest-cypress"] = {
         "tests/fixtures/basic.cy.ts::basic test suite::test A",
         "tests/fixtures/basic.cy.ts::basic test suite::test B",
       }
     })

     local mock_tree_A = {
       data = function()
         return { 
           path = "tests/fixtures/basic.cy.ts", 
           id = "tests/fixtures/basic.cy.ts::basic test suite::test A",
           type = "test",
           name = "test A"
         }
       end
     }
     
     -- First marked test should return a no-op spec
     local spec_A = adapter.build_spec({ tree = mock_tree_A })
     assert.is_table(spec_A)
     assert.is_table(spec_A.command)
     -- Should be a no-op: echo '{}'
     assert.equals("sh", spec_A.command[1])
     assert.equals("-c", spec_A.command[2])
     assert.is_truthy(string.find(spec_A.command[3], "echo"))
     -- Check for skipped_for_batch flag
     assert.is_true(spec_A.context.skipped_for_batch)
   end)

   it("combines grep patterns for multiple marked tests", function()
     local neotest = require("neotest")
     -- Set up marked tests: test A and test B
     neotest.summary._set_marked({
       ["neotest-cypress"] = {
         "tests/fixtures/basic.cy.ts::basic test suite::test A",
         "tests/fixtures/basic.cy.ts::basic test suite::test B",
       }
     })

     local mock_tree_B = {
       data = function()
         return { 
           path = "tests/fixtures/basic.cy.ts", 
           id = "tests/fixtures/basic.cy.ts::basic test suite::test B",
           type = "test",
           name = "test B"
         }
       end
     }
     
     -- Second (last) marked test should return a spec with combined pattern
     local spec_B = adapter.build_spec({ tree = mock_tree_B })
     assert.is_table(spec_B)
     assert.is_table(spec_B.command)
     
     local cmd_str = spec_B.command[3]
     -- Should contain combined pattern with OR operator
     assert.is_truthy(string.find(cmd_str, '--env grep='))
     assert.is_truthy(string.find(cmd_str, 'test A'))
     assert.is_truthy(string.find(cmd_str, 'test B'))
     -- Should contain the OR operator
     assert.is_truthy(string.find(cmd_str, '|'))
   end)

   it("clears marked tests after handling them", function()
     local neotest = require("neotest")
     -- Clear any previous marked tests
     neotest.summary._set_marked({})
     
     local mock_tree = {
       data = function()
         return { 
           path = "tests/fixtures/basic.cy.ts", 
           id = "tests/fixtures/basic.cy.ts::basic test suite::single test",
           type = "test",
           name = "single test"
         }
       end
     }
     
     -- With no marked tests, should behave like a normal single test
     local spec = adapter.build_spec({ tree = mock_tree })
     assert.is_table(spec)
     local cmd_str = spec.command[3]
     -- Should use normal grep without combining
     assert.is_truthy(string.find(cmd_str, '--env grep="single test"'))
   end)
 end)

 describe("results parser", function()
   it("returns running status for skipped batch tests", function()
     local mock_spec = {
       context = {
         pos_id = "tests/fixtures/basic.cy.ts::suite::test A",
         file = "tests/fixtures/basic.cy.ts",
         skipped_for_batch = true,
       }
     }
     
     local mock_result = {
       output = nil,
       code = 0
     }
     
     local mock_tree = {
       data = function()
         return { path = "tests/fixtures/basic.cy.ts" }
       end
     }
     
     -- Call results() with skipped batch test
     local results = adapter.results(mock_spec, mock_result, mock_tree)
     
     -- Should return running status for the skipped position
     assert.is_table(results)
     local pos_id = "tests/fixtures/basic.cy.ts::suite::test A"
     assert.is_table(results[pos_id])
     assert.equals("running", results[pos_id].status)
     assert.is_truthy(results[pos_id].short)
   end)
 end)
