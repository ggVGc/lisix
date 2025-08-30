import Lisix.Sigil

IO.puts("Inspecting generated code")

# Use quote mode to see what AST is being generated
quoted = ~L"""
(defmodule InspectTest
  (defn test [] "test result"))
"""q

IO.puts("Generated AST:")
IO.puts(inspect(quoted, pretty: true, limit: :infinity))