local M = {}

-- Generate a position ID from file path and test path
-- Format: file_path::describe_name::nested_describe::test_name
function M.create_position_id(file_path, names)
  local parts = { file_path }
  for _, name in ipairs(names) do
    table.insert(parts, name)
  end
  return table.concat(parts, "::")
end

-- Extract the test name from a position ID
function M.get_test_name_from_id(pos_id)
  local parts = vim.split(pos_id, "::", { plain = true })
  return parts[#parts]
end

-- Get the parent namespace names from a position ID
function M.get_namespace_path(pos_id)
  local parts = vim.split(pos_id, "::", { plain = true })
  local namespaces = {}
  for i = 2, #parts - 1 do
    table.insert(namespaces, parts[i])
  end
  return namespaces
end

return M
