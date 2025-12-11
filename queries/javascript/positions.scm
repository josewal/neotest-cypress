;; Capture plain namespace blocks: describe(), context()
((call_expression
  function: (identifier) @func_name
  arguments: (arguments
    (string (string_fragment) @namespace.name)
    [
      (arrow_function)
      (function_expression)
    ] @namespace.definition))
  (#any-of? @func_name "describe" "context")) @namespace.definition

;; Capture focused namespace blocks: describe.only(), context.only()
((call_expression
  function: (member_expression
    object: (identifier) @func_name
    property: (property_identifier) @modifier)
  arguments: (arguments
    (string (string_fragment) @namespace.name)
    [
      (arrow_function)
      (function_expression)
    ] @namespace.definition))
  (#any-of? @func_name "describe" "context")
  (#eq? @modifier "only")) @namespace.definition

;; Capture plain test blocks: it(), test(), specify()
((call_expression
  function: (identifier) @func_name
  arguments: (arguments
    (string (string_fragment) @test.name)
    [
      (arrow_function)
      (function_expression)
    ] @test.definition))
  (#any-of? @func_name "it" "test" "specify")) @test.definition

;; Capture focused test blocks: it.only(), test.only(), specify.only()
((call_expression
  function: (member_expression
    object: (identifier) @func_name
    property: (property_identifier) @modifier)
  arguments: (arguments
    (string (string_fragment) @test.name)
    [
      (arrow_function)
      (function_expression)
    ] @test.definition))
  (#any-of? @func_name "it" "test" "specify")
  (#eq? @modifier "only")) @test.definition
