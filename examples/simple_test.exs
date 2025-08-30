# Simple Lisix test examples

import Lisix.Sigil
import Lisix

IO.puts("Lisix Examples")
IO.puts("==============\n")

# Example 1: Simple arithmetic
IO.puts("1. Simple arithmetic:")
result1 = ~L"(+ 1 2 3 4 5)"
IO.puts("  (+ 1 2 3 4 5) = #{result1}")

# Example 2: Nested expressions
IO.puts("\n2. Nested expressions:")
result2 = ~L"(* (+ 2 3) (- 10 6))"
IO.puts("  (* (+ 2 3) (- 10 6)) = #{result2}")

# Example 3: Let bindings
IO.puts("\n3. Let bindings:")
result3 = ~L"""
(let [x 10
      y 20
      z (+ x y)]
  (* z 2))
"""
IO.puts("  (let [x 10, y 20, z (+ x y)] (* z 2)) = #{result3}")

# Example 4: Conditional expressions
IO.puts("\n4. Conditional expressions:")
result4a = ~L"(if (> 5 3) \"bigger\" \"smaller\")"
result4b = ~L"(if (< 5 3) \"bigger\" \"smaller\")"
IO.puts("  (if (> 5 3) \"bigger\" \"smaller\") = #{result4a}")
IO.puts("  (if (< 5 3) \"bigger\" \"smaller\") = #{result4b}")

# Example 5: Cond expressions
IO.puts("\n5. Cond expressions:")
test_cond = fn n ->
  ~L"""
  (cond
    [(< ~{n} 0) "negative"]
    [(> ~{n} 0) "positive"]
    [true "zero"])
  """
end

IO.puts("  Testing cond with different numbers:")
[-5, 0, 7].each(fn n ->
  result = test_cond.(n)
  IO.puts("    #{n} is #{result}")
end)

# Example 6: Lambda expressions
IO.puts("\n6. Lambda expressions:")
add5 = ~L"(lambda [x] (+ x 5))"
double = ~L"(lambda [x] (* x 2))"
IO.puts("  add5(10) = #{add5.(10)}")
IO.puts("  double(7) = #{double.(7)}")

# Example 7: List operations
IO.puts("\n7. List operations:")
list_result = ~L"(list 1 2 3 4 5)"
IO.puts("  Created list: #{inspect(list_result)}")

# Example 8: String operations
IO.puts("\n8. String operations:")
str_result = ~L"(str \"Hello \" \"Lisix \" \"World!\")"
IO.puts("  String concatenation: #{str_result}")

# Example 9: Comparison operations
IO.puts("\n9. Comparisons:")
comparisons = [
  {~L"(< 3 5)", "(< 3 5)"},
  {~L"(> 10 2)", "(> 10 2)"},
  {~L"(== 4 4)", "(== 4 4)"},
  {~L"(<= 5 5)", "(<= 5 5)"}
]

comparisons.each(fn {result, expr} ->
  IO.puts("  #{expr} = #{result}")
end)

# Example 10: Quote expression
IO.puts("\n10. Quote expressions:")
quoted = ~L"(list 1 2 3 4)"q
IO.puts("  Quoted expression: #{inspect(quoted)}")

# Example 11: Using Lisix eval directly
IO.puts("\n11. Using Lisix.eval:")
eval_result = Lisix.eval("(+ (* 2 3) (/ 8 2))")
IO.puts("  Lisix.eval(\"(+ (* 2 3) (/ 8 2))\") = #{eval_result}")

# Example 12: Complex nested calculation
IO.puts("\n12. Complex calculation:")
complex = ~L"""
(let [a 5
      b 10
      c (* a b)
      d (+ a b)
      e (- c d)]
  (/ e (+ a 1)))
"""
IO.puts("  Complex calculation result: #{complex}")

IO.puts("\nAll examples completed successfully!")