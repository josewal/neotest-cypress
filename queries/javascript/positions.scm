;; Capture describe/context blocks
((call_expression
  function: (identifier) @func_name
  arguments: (arguments
    (string (string_fragment) @namespace.name)
    (arrow_function) @namespace.definition))
  (#any-of? @func_name "describe" "context")) @namespace.definition

((call_expression
  function: (identifier) @func_name
  arguments: (arguments
    (string (string_fragment) @namespace.name)
    (function_expression) @namespace.definition))
  (#any-of? @func_name "describe" "context")) @namespace.definition

;; Capture it/test blocks
((call_expression
  function: (identifier) @func_name
  arguments: (arguments
    (string (string_fragment) @test.name)
    (arrow_function) @test.definition))
  (#any-of? @func_name "it" "test" "specify")) @test.definition

((call_expression
  function: (identifier) @func_name
  arguments: (arguments
    (string (string_fragment) @test.name)
    (function_expression) @test.definition))
  (#any-of? @func_name "it" "test" "specify")) @test.definition

;; Capture it.skip/only blocks
((call_expression
  function: (member_expression
    object: (identifier) @func_name
    property: (property_identifier) @modifier)
  arguments: (arguments
    (string (string_fragment) @test.name)
    (arrow_function) @test.definition))
  (#any-of? @func_name "it" "test" "specify")
  (#any-of? @modifier "skip" "only")) @test.definition

((call_expression
  function: (member_expression
    object: (identifier) @func_name
    property: (property_identifier) @modifier)
  arguments: (arguments
    (string (string_fragment) @test.name)
    (function_expression) @test.definition))
  (#any-of? @func_name "it" "test" "specify")
  (#any-of? @modifier "skip" "only")) @test.definition

;; Capture describe.skip/only blocks
((call_expression
  function: (member_expression
    object: (identifier) @func_name
    property: (property_identifier) @modifier)
  arguments: (arguments
    (string (string_fragment) @namespace.name)
    (arrow_function) @namespace.definition))
  (#any-of? @func_name "describe" "context")
  (#any-of? @modifier "skip" "only")) @namespace.definition

((call_expression
  function: (member_expression
    object: (identifier) @func_name
    property: (property_identifier) @modifier)
  arguments: (arguments
    (string (string_fragment) @namespace.name)
    (function_expression) @namespace.definition))
  (#any-of? @func_name "describe" "context")
  (#any-of? @modifier "skip" "only")) @namespace.definition
