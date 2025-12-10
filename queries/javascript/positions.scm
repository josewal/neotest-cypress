; Capture describe blocks as namespaces
(call_expression
  function: (identifier) @func_name (#match? @func_name "^(describe|context)$")
  arguments: (arguments
    . (string
        (string_fragment) @namespace.name)
    . (arrow_function) @namespace.definition))

; Capture describe with function expressions
(call_expression
  function: (identifier) @func_name (#match? @func_name "^(describe|context)$")
  arguments: (arguments
    . (string
        (string_fragment) @namespace.name)
    . (function_expression) @namespace.definition))

; Capture describe.skip and describe.only as namespaces
(call_expression
  function: (member_expression
    object: (identifier) @func_name (#match? @func_name "^(describe|context)$")
    property: (property_identifier) @modifier (#match? @modifier "^(skip|only)$"))
  arguments: (arguments
    . (string
        (string_fragment) @namespace.name)
    . (arrow_function) @namespace.definition))

; Capture it/specify blocks as tests
(call_expression
  function: (identifier) @func_name (#match? @func_name "^(it|specify)$")
  arguments: (arguments
    . (string
        (string_fragment) @test.name)
    . (arrow_function) @test.definition))

; Capture it/specify with function expressions
(call_expression
  function: (identifier) @func_name (#match? @func_name "^(it|specify)$")
  arguments: (arguments
    . (string
        (string_fragment) @test.name)
    . (function_expression) @test.definition))

; Capture it.skip and it.only as tests
(call_expression
  function: (member_expression
    object: (identifier) @func_name (#match? @func_name "^(it|specify)$")
    property: (property_identifier) @modifier (#match? @modifier "^(skip|only)$"))
  arguments: (arguments
    . (string
        (string_fragment) @test.name)
    . (arrow_function) @test.definition))
