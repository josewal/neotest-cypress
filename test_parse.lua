-- Simple test script to verify JSON parsing
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

local results = require('neotest-cypress.results')

-- Sample output from Cypress
local sample_output = [[
DevTools listening on ws://127.0.0.1:63447/devtools/browser/2627d8db-f50f-4b05-a18f-3998a585c6db
[dotenv@17.2.3] injecting env (6) from ../.env.local -- tip: ✅ audit secrets and track compliance: https://dotenvx.com/ops
{
  "stats": {
    "suites": 1,
    "tests": 2,
    "passes": 2,
    "pending": 0,
    "failures": 0,
    "start": "2025-12-11T00:22:59.161Z",
    "end": "2025-12-11T00:22:59.816Z",
    "duration": 655
  },
  "tests": [
    {
      "title": "DE1: Document \"type\" property is marked as enum",
      "fullTitle": "Document Enums DE1: Document \"type\" property is marked as enum",
      "file": null,
      "duration": 392,
      "currentRetry": 0,
      "err": {}
    },
    {
      "title": "DE1: Document \"nextedySheetConfig\" property is marked as enum",
      "fullTitle": "Document Enums DE1: Document \"nextedySheetConfig\" property is marked as enum",
      "file": null,
      "duration": 248,
      "currentRetry": 0,
      "err": {}
    }
  ],
  "pending": [],
  "failures": [],
  "passes": [
    {
      "title": "DE1: Document \"type\" property is marked as enum",
      "fullTitle": "Document Enums DE1: Document \"type\" property is marked as enum",
      "file": null,
      "duration": 392,
      "currentRetry": 0,
      "err": {}
    },
    {
      "title": "DE1: Document \"nextedySheetConfig\" property is marked as enum",
      "fullTitle": "Document Enums DE1: Document \"nextedySheetConfig\" property is marked as enum",
      "file": null,
      "duration": 248,
      "currentRetry": 0,
      "err": {}
    }
  ]
}
]]

local file_path = "/test/path/document-enums.cy.ts"
local parsed_results = results.parse_from_output(sample_output, file_path)

print("Parsed results:")
for pos_id, result in pairs(parsed_results) do
  print(string.format("  Position ID: %s", pos_id))
  print(string.format("  Status: %s", result.status))
  print("")
end
