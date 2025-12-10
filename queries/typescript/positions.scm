; Capture describe blocks as namespaces (arrow functions)
(call_expression
  function: (identifier) @func_name (#match? @func_name "^(describe|context)$")
  arguments: (arguments
    . (string
        (string_fragment) @namespace.name)
    . (arrow_function) @namespace.definition))

; Capture describe blocks as namespaces (function expressions)  
(call_expression
  function: (identifier) @func_name (#match? @func_name "^(describe|context)$")
  arguments: (arguments
    . (string
        (string_fragment) @namespace.name)
    . (function_expression) @namespace.definition))

; Capture describe blocks with async functions
(call_expression
  function: (identifier) @func_name (#match? @func_name "^(describe|context)$")
  arguments: (arguments
    . (string
        (string_fragment) @namespace.name)
    . (function_declaration
        name: (identifier) @async_name
        body: (statement_block) @namespace.definition)))

; Capture describe.skip and describe.only as namespaces (arrow functions)
(call_expression
  function: (member_expression
    object: (identifier) @func_name (#match? @func_name "^(describe|context)$")
    property: (property_identifier) @modifier (#match? @modifier "^(skip|only)$"))
  arguments: (arguments
    . (string
        (string_fragment) @namespace.name)
    . (arrow_function) @namespace.definition))

; Capture describe.skip and describe.only as namespaces (function expressions)
(call_expression
  function: (member_expression
    object: (identifier) @func_name (#match? @func_name "^(describe|context)$")
    property: (property_identifier) @modifier (#match? @modifier "^(skip|only)$"))
  arguments: (arguments
    . (string
        (string_fragment) @namespace.name)
    . (function_expression) @namespace.definition))

; Capture it/specify blocks as tests (arrow functions)
(call_expression
  function: (identifier) @func_name (#match? @func_name "^(it|specify)$")
  arguments: (arguments
    . (string
        (string_fragment) @test.name)
    . (arrow_function) @test.definition))

; Capture it/specify blocks as tests (function expressions)
(call_expression
  function: (identifier) @func_name (#match? @func_name "^(it|specify)$")
  arguments: (arguments
    . (string
        (string_fragment) @test.name)
    . (function_expression) @test.definition))

; Capture it/specify blocks with async functions
(call_expression
  function: (identifier) @func_name (#match? @func_name "^(it|specify)$")
  arguments: (arguments
    . (string
        (string_fragment) @test.name)
    . (function_declaration
        name: (identifier) @async_name
        body: (statement_block) @test.definition)))

; Capture it.skip and it.only as tests (arrow functions)
(call_expression
  function: (member_expression
    object: (identifier) @func_name (#match? @func_name "^(it|specify)$")
    property: (property_identifier) @modifier (#match? @modifier "^(skip|only)$"))
  arguments: (arguments
    . (string
        (string_fragment) @test.name)
    . (arrow_function) @test.definition))

; Capture it.skip and it.only as tests (function expressions)
(call_expression
  function: (member_expression
    object: (identifier) @func_name (#match? @func_name "^(it|specify)$")
    property: (property_identifier) @modifier (#match? @modifier "^(skip|only)$"))
  arguments: (arguments
    . (string
        (string_fragment) @test.name)
    . (function_expression) @test.definition))

; Capture template literals for describe
(call_expression
  function: (identifier) @func_name (#match? @func_name "^(describe|context)$")
  arguments: (arguments
    . (template_string
        (string_fragment) @namespace.name)
    . (arrow_function) @namespace.definition))

; Capture template literals for it/specify
(call_expression
  function: (identifier) @func_name (#match? @func_name "^(it|specify)$")
  arguments: (arguments
    . (template_string
        (string_fragment) @test.name)
    . (arrow_function) @test.definition))

; Additional patterns for template literals with member expressions
(call_expression
  function: (member_expression
    object: (identifier) @func_name (#match? @func_name "^(describe|context|it|specify)$")
    property: (property_identifier) @modifier (#match? @modifier "^(skip|only)$"))
  arguments: (arguments
    . (template_string
        (string_fragment) @test.name)
    . (arrow_function) @test.definition))
