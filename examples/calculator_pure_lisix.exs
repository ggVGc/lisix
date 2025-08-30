# Pure Lisix Calculator Module Example
# Demonstrates complete module definition in authentic Lisp syntax

import Lisix.Sigil

~L"""
(defmodule Calculator
  (use GenServer)
  (import Lisix.Sigil)
  
  ;; Client API functions in pure Lisp syntax
  (defn start-link []
    (GenServer.start_link __MODULE__ [] [name: __MODULE__]))
  
  (defn add [n]
    (GenServer.call __MODULE__ [:add n]))
  
  (defn subtract [n]
    (GenServer.call __MODULE__ [:subtract n]))
  
  (defn multiply [n]
    (GenServer.call __MODULE__ [:multiply n]))
  
  (defn divide [n]
    (GenServer.call __MODULE__ [:divide n]))
  
  (defn clear []
    (GenServer.call __MODULE__ :clear))
  
  (defn get-value []
    (GenServer.call __MODULE__ :get))
  
  (defn get-history []
    (GenServer.call __MODULE__ :history))
  
  ;; GenServer callbacks
  (def init [args]
    {:ok {:value 0 :history []}})
  
  ;; Handle add operation
  (def handle-call [[:add n] _from state]
    (let [current (:value state)
          new-value (+ current n)
          new-state (-> state
                       (assoc :value new-value)
                       (update :history conj {:add n new-value}))]
      {:reply new-value new-state}))
  
  ;; Handle subtract operation
  (def handle-call [[:subtract n] _from state]
    (let [current (:value state)
          new-value (- current n)
          new-state (-> state
                       (assoc :value new-value)
                       (update :history conj {:subtract n new-value}))]
      {:reply new-value new-state}))
  
  ;; Handle multiply operation
  (def handle-call [[:multiply n] _from state]
    (let [current (:value state)
          new-value (* current n)
          new-state (-> state
                       (assoc :value new-value)
                       (update :history conj {:multiply n new-value}))]
      {:reply new-value new-state}))
  
  ;; Handle divide operation with guard
  (def handle-call [[:divide n] _from state] :when (!= n 0)
    (let [current (:value state)
          new-value (/ current n)
          new-state (-> state
                       (assoc :value new-value)
                       (update :history conj {:divide n new-value}))]
      {:reply new-value new-state}))
  
  ;; Handle divide by zero
  (def handle-call [[:divide 0] _from state]
    {:reply {:error "Division by zero"} state})
  
  ;; Handle clear operation
  (def handle-call [:clear _from state]
    (let [new-state {:value 0 :history (cons {:clear nil 0} (:history state))}]
      {:reply 0 new-state}))
  
  ;; Handle get current value
  (def handle-call [:get _from state]
    {:reply (:value state) state})
  
  ;; Handle get history
  (def handle-call [:history _from state]
    {:reply (reverse (:history state)) state}))
"""M

# Mathematical functions module in pure Lisix

~L"""
(defmodule LisixMath
  (import Lisix.Sigil)
  
  ;; Factorial with pattern matching
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
  
  ;; Power function
  (defn power [_base 0] 1)
  (defn power [base exp] :when (> exp 0)
    (* base (power base (- exp 1))))
  (defn power [base exp] :when (< exp 0)
    (/ 1.0 (power base (- exp))))
  
  ;; Greatest Common Divisor
  (defn gcd [a 0] a)
  (defn gcd [a b] :when (> b 0)
    (gcd b (rem a b)))
  
  ;; Least Common Multiple
  (defn lcm [a b]
    (/ (* a b) (gcd a b)))
  
  ;; Prime number check
  (defn is-prime? [n] :when (<= n 1)
    false)
  (defn is-prime? [2] true)
  (defn is-prime? [n] :when (> n 2)
    (not (has-divisor? n 2)))
  
  ;; Helper for prime checking
  (defp has-divisor? [n divisor] :when (> (* divisor divisor) n)
    false)
  (defp has-divisor? [n divisor] :when (== (rem n divisor) 0)
    true)
  (defp has-divisor? [n divisor]
    (has-divisor? n (+ divisor 1))))
"""M

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
    %{add: n, value: result} -> IO.puts("  add #{n} = #{result}")
    %{subtract: n, value: result} -> IO.puts("  subtract #{n} = #{result}")
    %{multiply: n, value: result} -> IO.puts("  multiply #{n} = #{result}")
    %{divide: n, value: result} -> IO.puts("  divide #{n} = #{result}")
    %{clear: _, value: result} -> IO.puts("  clear = #{result}")
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

# Test prime numbers
IO.puts("\nPrime number tests:")
1..20
|> Enum.filter(&LisixMath.is_prime?/1)
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

IO.puts("\n🎉 Pure Lisix Calculator completed successfully!")
IO.puts("Every function and module is defined in authentic Lisp syntax!")