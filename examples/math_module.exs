# Math functions module using Lisix

defmodule LisixMath do
  import Lisix.Sigil
  
  # Define mathematical functions using Lisix syntax inside the module
  
  def factorial(n) do
    ~L"""
    (if (<= ~{n} 1)
      1
      (* ~{n} (factorial (- ~{n} 1))))
    """
  end
  
  def fibonacci(n) do
    ~L"""
    (if (== ~{n} 0)
      0
      (if (== ~{n} 1)
        1
        (+ (fibonacci (- ~{n} 1)) (fibonacci (- ~{n} 2)))))
    """
  end
  
  def power(base, exp) do
    ~L"""
    (if (<= ~{exp} 0)
      1
      (* ~{base} (power ~{base} (- ~{exp} 1))))
    """
  end
  
  def sum_range(start, stop) do
    ~L"""
    (if (> ~{start} ~{stop})
      0
      (+ ~{start} (sum_range (+ ~{start} 1) ~{stop})))
    """
  end
  
  def square(n) do
    ~L"(* ~{n} ~{n})"
  end
  
  def cube(n) do
    ~L"(* ~{n} (* ~{n} ~{n}))"
  end
  
  def is_even(n) do
    ~L"(== (rem ~{n} 2) 0)"
  end
  
  def abs_value(n) do
    ~L"(if (< ~{n} 0) (- ~{n}) ~{n})"
  end
  
  def max_of_two(a, b) do
    ~L"(if (> ~{a} ~{b}) ~{a} ~{b})"
  end
  
  def min_of_two(a, b) do
    ~L"(if (< ~{a} ~{b}) ~{a} ~{b})"
  end
end

# Demo the math functions
IO.puts("Lisix Math Module Demo")
IO.puts("======================\n")

# Test factorial
IO.puts("Factorial tests:")
IO.puts("  factorial(0) = #{LisixMath.factorial(0)}")
IO.puts("  factorial(1) = #{LisixMath.factorial(1)}")
IO.puts("  factorial(5) = #{LisixMath.factorial(5)}")
IO.puts("  factorial(7) = #{LisixMath.factorial(7)}")

# Test fibonacci
IO.puts("\nFibonacci tests:")
for i <- 0..10 do
  IO.puts("  fib(#{i}) = #{LisixMath.fibonacci(i)}")
end

# Test power
IO.puts("\nPower tests:")
IO.puts("  power(2, 0) = #{LisixMath.power(2, 0)}")
IO.puts("  power(2, 3) = #{LisixMath.power(2, 3)}")
IO.puts("  power(3, 4) = #{LisixMath.power(3, 4)}")
IO.puts("  power(5, 2) = #{LisixMath.power(5, 2)}")

# Test sum_range
IO.puts("\nSum range tests:")
IO.puts("  sum_range(1, 5) = #{LisixMath.sum_range(1, 5)}")
IO.puts("  sum_range(1, 10) = #{LisixMath.sum_range(1, 10)}")
IO.puts("  sum_range(5, 15) = #{LisixMath.sum_range(5, 15)}")

# Test basic operations
IO.puts("\nBasic operations:")
IO.puts("  square(8) = #{LisixMath.square(8)}")
IO.puts("  cube(4) = #{LisixMath.cube(4)}")
IO.puts("  abs_value(-15) = #{LisixMath.abs_value(-15)}")
IO.puts("  abs_value(15) = #{LisixMath.abs_value(15)}")

# Test comparisons
IO.puts("\nComparison operations:")
IO.puts("  max_of_two(10, 7) = #{LisixMath.max_of_two(10, 7)}")
IO.puts("  min_of_two(10, 7) = #{LisixMath.min_of_two(10, 7)}")

# Test even/odd
IO.puts("\nEven number tests:")
Enum.each([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], fn n ->
  result = if LisixMath.is_even(n), do: "even", else: "odd"
  IO.puts("  #{n} is #{result}")
end)

# Performance comparison
IO.puts("\nPerformance comparison (factorial 10):")

# Lisix version
start_time = System.monotonic_time(:microsecond)
lisix_result = LisixMath.factorial(10)
lisix_time = System.monotonic_time(:microsecond) - start_time

# Pure Elixir version
elixir_factorial = fn
  0 -> 1
  1 -> 1
  n -> n * (fn f, x -> f.(f, x-1) end).(fn f, x -> if x <= 1, do: 1, else: x * f.(f, x-1) end, n)
end

start_time = System.monotonic_time(:microsecond)
elixir_result = elixir_factorial.(10)
elixir_time = System.monotonic_time(:microsecond) - start_time

IO.puts("  Lisix factorial(10):  #{lisix_result} (#{lisix_time}μs)")
IO.puts("  Elixir factorial(10): #{elixir_result} (#{elixir_time}μs)")

# Complex calculation using multiple functions
IO.puts("\nComplex calculation:")
IO.puts("Computing: sum of squares of first 5 numbers")

result = Enum.reduce(1..5, 0, fn n, acc ->
  acc + LisixMath.square(n)
end)

IO.puts("  1² + 2² + 3² + 4² + 5² = #{result}")

IO.puts("\n✨ All math examples completed successfully!")
IO.puts("Lisix can handle complex mathematical computations!")