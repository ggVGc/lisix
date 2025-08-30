import Lisix.Sigil

IO.puts("Testing module definition and function call")

~L"""
(defmodule SimpleTest
  (defn greet [] "Hello from Lisix!"))
"""M

try do
  result = SimpleTest.greet()
  IO.puts("Result: #{result}")
rescue
  e -> IO.puts("Error calling function: #{inspect(e)}")
end

IO.puts("Module info: #{inspect(SimpleTest.module_info())}")