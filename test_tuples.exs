import Lisix.Sigil

IO.puts("Testing tuple creation...")
result = ~L"{:reply 42 42}"
IO.puts("Tuple result: #{inspect(result)}")
IO.puts("Done!")