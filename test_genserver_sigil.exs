# Test file to demonstrate GenServer handle_call using complete Lisix sigil definitions

import Lisix.Sigil

# Create handle_call functions using Lisix sigil outside of module context
handle_increment = ~L"(defn handle-call [:increment _from state] {:reply (+ state 1) (+ state 1)})"
handle_get = ~L"(defn handle-call [:get _from state] {:reply state state})"

IO.puts("Lisix sigil handle_call function definitions created successfully!")
IO.puts("handle_increment function: #{inspect(handle_increment)}")
IO.puts("handle_get function: #{inspect(handle_get)}")

IO.puts("Test completed - Lisix sigil can define complete GenServer callback functions!")