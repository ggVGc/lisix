# Calculator Module Example in Lisix
# Demonstrates module definition, GenServer integration, and state management

import Lisix.Sigil

# Define a calculator module with state management
defmodule Calculator do
  use GenServer
  import Lisix.Sigil
  
  # Client API using Lisix
  
  ~L"(defn start-link [] (GenServer.start_link Calculator [] [name: Calculator]))"
  
  ~L"(defn add [n] (GenServer.call Calculator [:add n]))"
  ~L"(defn subtract [n] (GenServer.call Calculator [:subtract n]))"
  ~L"(defn multiply [n] (GenServer.call Calculator [:multiply n]))"
  ~L"(defn divide [n] (GenServer.call Calculator [:divide n]))"
  ~L"(defn clear [] (GenServer.call Calculator :clear))"
  ~L"(defn get-value [] (GenServer.call Calculator :get))"
  ~L"(defn get-history [] (GenServer.call Calculator :history))"
  
  # Server callbacks
  
  def init([]) do
    {:ok, %{value: 0, history: []}}
  end
  
  def handle_call([:add, n], _from, state) do
    new_value = state.value + n
    new_state = state
                |> Map.put(:value, new_value)
                |> Map.update(:history, [], &[{:add, n, new_value} | &1])
    {:reply, new_value, new_state}
  end
  
  def handle_call([:subtract, n], _from, state) do
    new_value = state.value - n
    new_state = state
                |> Map.put(:value, new_value)
                |> Map.update(:history, [], &[{:subtract, n, new_value} | &1])
    {:reply, new_value, new_state}
  end
  
  def handle_call([:multiply, n], _from, state) do
    new_value = state.value * n
    new_state = state
                |> Map.put(:value, new_value)
                |> Map.update(:history, [], &[{:multiply, n, new_value} | &1])
    {:reply, new_value, new_state}
  end
  
  def handle_call([:divide, n], _from, state) when n != 0 do
    new_value = state.value / n
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

# Additional Lisix functions for calculations
~L"""
(defn factorial [n]
  (if (<= n 1)
    1
    (* n (factorial (- n 1)))))
"""

~L"""
(defn fibonacci [n]
  (cond
    [(== n 0) 0]
    [(== n 1) 1]
    [true (+ (fibonacci (- n 1))
             (fibonacci (- n 2)))]))
"""

~L"""
(defn power [base exp]
  (cond
    [(== exp 0) 1]
    [(< exp 0) (/ 1.0 (power base (- exp)))]
    [true (* base (power base (- exp 1)))]))
"""

~L"""
(defn gcd [a b]
  (if (zero? b)
    a
    (gcd b (rem a b))))
"""

~L"""
(defn lcm [a b]
  (/ (* a b) (gcd a b)))
"""

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
IO.puts("factorial(5)    = #{factorial(5)}")
IO.puts("factorial(10)   = #{factorial(10)}")
IO.puts("fibonacci(7)    = #{fibonacci(7)}")
IO.puts("fibonacci(10)   = #{fibonacci(10)}")
IO.puts("power(2, 8)     = #{power(2, 8)}")
IO.puts("power(3, 4)     = #{power(3, 4)}")
IO.puts("gcd(48, 18)     = #{gcd(48, 18)}")
IO.puts("lcm(12, 15)     = #{lcm(12, 15)}")

# Complex calculation using Lisix
IO.puts("\n\nComplex Calculation in Lisix")
IO.puts("=============================")

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