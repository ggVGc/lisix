import Lisix.Sigil

IO.puts("Testing module definition")

~L"""
(defmodule TestModule
  (defn hello [] "Hello World"))
"""M

result = TestModule.hello()
IO.puts("Result: #{result}")