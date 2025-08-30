# Calculator Module Example in Lisix
# Demonstrates module definition, GenServer integration, and state management

# Define a calculator module with state management using pure Lisix style
defmodule Calculator do
  use GenServer
  import Lisix.Sigil
  
  # Client API using pure Lisix syntax - define at compile time
  def start_link do
    # Using Lisix for the actual call 
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end
  
  def add(n) do
    # Use Lisix for the call structure but proper module reference
    GenServer.call(__MODULE__, ~L"[:add ~{n}]")
  end
  
  def subtract(n) do
    GenServer.call(__MODULE__, ~L"[:subtract ~{n}]")
  end
  
  def multiply(n) do  
    GenServer.call(__MODULE__, ~L"[:multiply ~{n}]")
  end
  
  def divide(n) do
    GenServer.call(__MODULE__, ~L"[:divide ~{n}]")
  end
  
  def clear do
    GenServer.call(__MODULE__, :clear)
  end
  
  def get_value do
    GenServer.call(__MODULE__, :get)
  end
  
  def get_history do
    GenServer.call(__MODULE__, :history)
  end
  
  # Server callbacks
  
  def init([]) do
    {:ok, %{value: 0, history: []}}
  end
  
  def handle_call([:add, n], _from, state) do
    # Use Lisix for the calculation
    current = state.value
    new_value = ~L"(+ ~{current} ~{n})"
    new_state = state
                |> Map.put(:value, new_value)
                |> Map.update(:history, [], &[{:add, n, new_value} | &1])
    {:reply, new_value, new_state}
  end
  
  def handle_call([:subtract, n], _from, state) do
    current = state.value  
    new_value = ~L"(- ~{current} ~{n})"
    new_state = state
                |> Map.put(:value, new_value)
                |> Map.update(:history, [], &[{:subtract, n, new_value} | &1])
    {:reply, new_value, new_state}
  end
  
  def handle_call([:multiply, n], _from, state) do
    current = state.value
    new_value = ~L"(* ~{current} ~{n})"
    new_state = state
                |> Map.put(:value, new_value)
                |> Map.update(:history, [], &[{:multiply, n, new_value} | &1])
    {:reply, new_value, new_state}
  end
  
  def handle_call([:divide, n], _from, state) when n != 0 do
    current = state.value
    new_value = ~L"(/ ~{current} ~{n})"
    new_state = state
                |> Map.put(:value, new_value)
                |> Map.update(:history, [], &[{:divide, n, new_value} | &1])
    {:reply, new_value, new_state}
  end
  
  def handle_call([:divide, 0], _from, state) do
    {:reply, {:error, "Division by zero"}, state}
  end
  
  def handle_call(:clear, _from, state) do
    new_state = %{value: 0, history: [{:clear, 0, 0} | state.history]}
    {:reply, 0, new_state}
  end
  
  def handle_call(:get, _from, state) do
    {:reply, state.value, state}
  end
  
  def handle_call(:history, _from, state) do
    {:reply, Enum.reverse(state.history), state}
  end
end

# Mathematical functions using Lisix for computation but Elixir for recursion
defmodule LisixMathFunctions do
  import Lisix.Sigil
  
  # Factorial using Lisix arithmetic  
  def factorial(0), do: 1
  def factorial(1), do: 1
  def factorial(n) when n > 1 do
    prev = factorial(n - 1)
    ~L"(* ~{n} ~{prev})"
  end
  
  # Fibonacci using Lisix arithmetic
  def fibonacci(0), do: 0
  def fibonacci(1), do: 1
  def fibonacci(n) when n > 1 do
    fib1 = fibonacci(n - 1)
    fib2 = fibonacci(n - 2)
    ~L"(+ ~{fib1} ~{fib2})"
  end
  
  # Power using Lisix arithmetic
  def power(_base, 0), do: 1
  def power(base, exp) when exp > 0 do
    prev = power(base, exp - 1)
    ~L"(* ~{base} ~{prev})"
  end
  def power(base, exp) when exp < 0 do
    pos_power = power(base, -exp)
    ~L"(/ 1.0 ~{pos_power})"
  end
  
  # GCD using Lisix arithmetic
  def gcd(a, 0), do: a
  def gcd(a, b) when b > 0 do
    remainder = ~L"(rem ~{a} ~{b})"
    gcd(b, remainder)
  end
  
  # LCM using Lisix arithmetic
  def lcm(a, b) do
    gcd_val = gcd(a, b)
    product = ~L"(* ~{a} ~{b})"
    ~L"(/ ~{product} ~{gcd_val})"
  end
end

# Demo the calculator
IO.puts("Lisix Calculator Demo")
IO.puts("=====================\n")

# Start the calculator
{:ok, _pid} = Calculator.start_link()

IO.puts("Starting with: #{Calculator.get_value()}")

# Perform calculations
IO.puts("\nPerforming calculations:")
IO.puts("Add 10:      #{Calculator.add(10)}")
IO.puts("Multiply 3:  #{Calculator.multiply(3)}")
IO.puts("Subtract 5:  #{Calculator.subtract(5)}")
IO.puts("Divide by 5: #{Calculator.divide(5)}")

IO.puts("\nCurrent value: #{Calculator.get_value()}")

# Show history
IO.puts("\nOperation history:")
Calculator.get_history()
|> Enum.each(fn {op, n, result} ->
  IO.puts("  #{op} #{n} = #{result}")
end)

# Clear and start over
IO.puts("\nClearing calculator...")
Calculator.clear()
IO.puts("Value after clear: #{Calculator.get_value()}")

# Test Lisix math functions
IO.puts("\n\nLisix Math Functions")
IO.puts("====================")
IO.puts("factorial(5)    = #{LisixMathFunctions.factorial(5)}")
IO.puts("factorial(10)   = #{LisixMathFunctions.factorial(10)}")
IO.puts("fibonacci(7)    = #{LisixMathFunctions.fibonacci(7)}")
IO.puts("fibonacci(10)   = #{LisixMathFunctions.fibonacci(10)}")
IO.puts("power(2, 8)     = #{LisixMathFunctions.power(2, 8)}")
IO.puts("power(3, 4)     = #{LisixMathFunctions.power(3, 4)}")
IO.puts("gcd(48, 18)     = #{LisixMathFunctions.gcd(48, 18)}")
IO.puts("lcm(12, 15)     = #{LisixMathFunctions.lcm(12, 15)}")

# Complex calculation using Lisix
IO.puts("\n\nComplex Calculation in Lisix")
IO.puts("=============================")

import Lisix.Sigil

result = ~L"""
(let [a 10
      b 20
      c (+ a b)
      d (* c 2)
      e (- d a)]
  (/ e b))
"""

IO.puts("(let [a 10, b 20, c (+ a b), d (* c 2), e (- d a)] (/ e b))")
IO.puts("Result: #{result}")