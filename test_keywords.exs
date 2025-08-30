import Lisix.Sigil

IO.puts("Testing keyword...")
result = ~L":increment"
IO.puts("Keyword result: #{inspect(result)}")

IO.puts("Testing vector with keyword...")
result2 = ~L"[:increment]"
IO.puts("Vector result: #{inspect(result2)}")

IO.puts("Done!")