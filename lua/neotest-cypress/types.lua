---@meta neotest

---@class neotest.PositionType
---| '"test"'
---| '"namespace"'
---| '"file"'

---@class neotest.Position
---@field id string Unique identifier for the position
---@field name string Display name of the test or namespace
---@field type neotest.PositionType Type of the position (test, namespace, file)
---@field path string Full path to the file containing the position
---@field range? {[1]: integer, [2]: integer, [3]: integer, [4]: integer} Optional source code range

---@class neotest.Tree
---@field data fun(): neotest.Position Function to retrieve the position data
---@field children? neotest.Tree[] Optional child trees
---@field parent? neotest.Tree Optional parent tree

---@class neotest.RunSpecContext
---@field results_path string Path to the test results file
---@field pos_id string Position identifier
---@field file string Path to the test file

---@class neotest.RunSpec
---@field command string Command to execute the test
---@field args string[] Arguments for the test command
---@field context neotest.RunSpecContext Additional context for the test run

---@class neotest.ResultStatus
---| '"passed"'
---| '"failed"'
---| '"skipped"'

---@class neotest.TestError
---@field message string Error message
---@field stack? string Optional stack trace

---@class neotest.TestResult
---@field status neotest.ResultStatus Test execution status
---@field errors? neotest.TestError[] Optional list of errors
---@field output? string Optional output from the test
---@field short? string Short description or summary of the result

---@alias neotest.Results table<string, neotest.TestResult>

return {
  Position = {},
  Tree = {},
  RunSpec = {},
  ResultStatus = {},
  TestError = {},
  TestResult = {},
  Results = {}
}