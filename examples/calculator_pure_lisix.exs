# Enhanced Lisix Calculator Module Example
# Demonstrates extensive Lisix usage for function definitions within Elixir modules
# Features: tuple pattern matching, map destructuring, complex GenServer callbacks,
# mathematical algorithms, and history tracking - all in authentic Lisp syntax

import Lisix.Sigil

defmodule Calculator do
  use GenServer
  import Lisix.Sigil

  ~L"""
  ;; Client API functions in pure Lisp syntax
  (defn start_link []
    (GenServer.start_link __MODULE__ {:value 0 :history []} [{:name __MODULE__}]))

  (defn add [n]
    (GenServer.call __MODULE__ {:add n}))

  (defn subtract [n]
    (GenServer.call __MODULE__ {:subtract n}))

  (defn multiply [n]
    (GenServer.call __MODULE__ {:multiply n}))

  (defn divide [n]
    (GenServer.call __MODULE__ {:divide n}))

  (defn clear []
    (GenServer.call __MODULE__ :clear))

  (defn get_value []
    (GenServer.call __MODULE__ :get))

  (defn get_history []
    (GenServer.call __MODULE__ :history))

  ;; GenServer callbacks with complex pattern matching
  (defn init [state]
    {:ok state})

  ;; Handle add operation
  (defn handle_call [{:add n} _from {:value current :history history}]
    (let [new_value (+ current n)
          operation {:add n :result new_value}
          new_history (cons operation history)
          new_state {:value new_value :history new_history}]
      {:reply new_value new_state}))

  ;; Handle subtract operation
  (defn handle_call [{:subtract n} _from {:value current :history history}]
    (let [new_value (- current n)
          operation {:subtract n :result new_value}
          new_history (cons operation history)
          new_state {:value new_value :history new_history}]
      {:reply new_value new_state}))

  ;; Handle multiply operation
  (defn handle_call [{:multiply n} _from {:value current :history history}]
    (let [new_value (* current n)
          operation {:multiply n :result new_value}
          new_history (cons operation history)
          new_state {:value new_value :history new_history}]
      {:reply new_value new_state}))

  ;; Handle divide operation with zero check
  (defn handle_call [{:divide n} _from {:value current :history history}]
    (if (== n 0)
      {:reply {:error "Division by zero"} {:value current :history history}}
      (let [new_value (/ current n)
            operation {:divide n :result new_value}
            new_history (cons operation history)
            new_state {:value new_value :history new_history}]
        {:reply new_value new_state})))

  ;; Handle clear operation
  (defn handle_call [:clear _from {:value _current :history history}]
    (let [new_state {:value 0 :history (cons {:clear :result 0} history)}]
      {:reply 0 new_state}))

  ;; Handle get current value
  (defn handle_call [:get _from {:value current :history history}]
    {:reply current {:value current :history history}})

  ;; Handle get history (history is stored newest-first, return as-is for recent first)
  (defn handle_call [:history _from {:value current :history history}]
    {:reply history {:value current :history history}})
  """
end

# Mathematical functions module using Lisix

defmodule LisixMath do
  import Lisix.Sigil

  ~L"""
  ;; Factorial with pattern matching and guards
  (defn factorial [0] 1)
  (defn factorial [1] 1)
  (defn factorial [n] :when (> n 1)
    (* n (factorial (- n 1))))

  ;; Fibonacci with pattern matching
  (defn fibonacci [0] 0)
  (defn fibonacci [1] 1)
  (defn fibonacci [n] :when (> n 1)
    (+ (fibonacci (- n 1))
       (fibonacci (- n 2))))

  ;; Power function with pattern matching
  (defn power [_base 0] 1)
  (defn power [base exp] :when (> exp 0)
    (* base (power base (- exp 1))))
  (defn power [base exp] :when (< exp 0)
    (/ 1.0 (power base (- 0 exp))))

  ;; Greatest Common Divisor with pattern matching
  (defn gcd [a 0] a)
  (defn gcd [a b] :when (> b 0)
    (gcd b (rem a b)))

  ;; Least Common Multiple
  (defn lcm [a b]
    (/ (* a b) (gcd a b)))

  ;; Prime number check with pattern matching and guards
  (defn is_prime [n] :when (<= n 1)
    false)

  (defn is_prime [2]
    true)

  (defn is_prime [n] :when (== (rem n 2) 0)
    false)

  (defn is_prime [n]
    (not (has_divisor n 3)))

  ;; Helper for prime checking with guards
  (defn has_divisor [n divisor] :when (> (* divisor divisor) n)
    false)

  (defn has_divisor [n divisor] :when (== (rem n divisor) 0)
    true)

  (defn has_divisor [n divisor]
    (has_divisor n (+ divisor 2)))

  ;; Additional math functions showcasing Lisix capabilities
  (defn abs [n]
    (if (< n 0)
      (- 0 n)
      n))

  (defn max [a b]
    (if (> a b) a b))

  (defn min [a b]
    (if (< a b) a b))
  """
end

# Demo the pure Lisix calculator
IO.puts("Pure Lisix Calculator Demo")
IO.puts("==========================\n")

# Start the calculator
{:ok, _pid} = Calculator.start_link()

IO.puts("Calculator started with value: #{Calculator.get_value()}")

# Perform calculations using the pure Lisix functions
IO.puts("\nPerforming calculations:")
IO.puts("Add 15:      #{Calculator.add(15)}")
IO.puts("Multiply 4:  #{Calculator.multiply(4)}")
IO.puts("Subtract 20: #{Calculator.subtract(20)}")
IO.puts("Divide by 8: #{Calculator.divide(8)}")

IO.puts("\nCurrent value: #{Calculator.get_value()}")

# Show operation history
IO.puts("\nOperation History:")
Calculator.get_history()
|> Enum.each(fn operation ->
  case operation do
    %{add: n, result: result} -> IO.puts("  add #{n} = #{result}")
    %{subtract: n, result: result} -> IO.puts("  subtract #{n} = #{result}")
    %{multiply: n, result: result} -> IO.puts("  multiply #{n} = #{result}")
    %{divide: n, result: result} -> IO.puts("  divide #{n} = #{result}")
    %{clear: _, result: result} -> IO.puts("  clear = #{result}")
    other -> IO.puts("  #{inspect(other)}")
  end
end)

# Test error handling
IO.puts("\nTesting Error Handling:")
IO.puts("Divide by 0: #{inspect(Calculator.divide(0))}")

# Test mathematical functions
IO.puts("\n\nPure Lisix Math Functions")
IO.puts("=========================")

# Test factorial
IO.puts("Factorials:")
[0, 1, 5, 7, 10]
|> Enum.each(fn n ->
  result = LisixMath.factorial(n)
  IO.puts("  #{n}! = #{result}")
end)

# Test fibonacci
IO.puts("\nFibonacci sequence:")
0..12
|> Enum.each(fn n ->
  result = LisixMath.fibonacci(n)
  IO.puts("  F(#{n}) = #{result}")
end)

# Test other functions
IO.puts("\nOther mathematical functions:")
IO.puts("power(2, 8)     = #{LisixMath.power(2, 8)}")
IO.puts("power(3, 4)     = #{LisixMath.power(3, 4)}")
IO.puts("power(2, -3)    = #{LisixMath.power(2, -3)}")
IO.puts("gcd(48, 18)     = #{LisixMath.gcd(48, 18)}")
IO.puts("lcm(12, 15)     = #{LisixMath.lcm(12, 15)}")
IO.puts("abs(-42)        = #{LisixMath.abs(-42)}")
IO.puts("max(15, 23)     = #{LisixMath.max(15, 23)}")
IO.puts("min(15, 23)     = #{LisixMath.min(15, 23)}")

# Test prime numbers
IO.puts("\nPrime number tests:")
1..20
|> Enum.filter(&LisixMath.is_prime/1)
|> then(fn primes ->
  IO.puts("Primes 1-20: #{inspect(primes)}")
end)

# Complex calculation chain
IO.puts("\nComplex Calculation Chain:")
Calculator.clear()

result = Calculator.add(100)
         |> then(fn _ -> Calculator.multiply(2) end)
         |> then(fn _ -> Calculator.subtract(50) end)
         |> then(fn _ -> Calculator.divide(5) end)

IO.puts("((((0 + 100) * 2) - 50) / 5) = #{result}")

IO.puts("\n🎉 Enhanced Lisix Calculator completed successfully!")
IO.puts("✅ All client API functions defined in authentic Lisp syntax!")
IO.puts("✅ GenServer callbacks with complex tuple pattern matching!")
IO.puts("✅ Map destructuring in function parameters!")
IO.puts("✅ Multiple function clauses with guard conditions!")
IO.puts("✅ Pattern matching with literal values (0, 1, 2)!")
IO.puts("✅ Sophisticated guard expressions with :when!")
IO.puts("✅ Conditional logic and comparison operators working!")
IO.puts("✅ Mathematical functions with recursive algorithms!")
IO.puts("✅ History tracking with immutable data structures!")
IO.puts("✅ Error handling for edge cases like division by zero!")
