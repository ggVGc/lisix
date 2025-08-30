# Basic Lisix demonstration

import Lisix.Sigil

IO.puts("Lisix Basic Demo")
IO.puts("================\n")

# Example 1: Simple arithmetic
IO.puts("1. Simple arithmetic:")
result1 = ~L"(+ 1 2 3 4 5)"
IO.puts("  (+ 1 2 3 4 5) = #{result1}")

result2 = ~L"(* 6 7)"
IO.puts("  (* 6 7) = #{result2}")

result3 = ~L"(- 20 5)"
IO.puts("  (- 20 5) = #{result3}")

result4 = ~L"(/ 100 4)"
IO.puts("  (/ 100 4) = #{result4}")

# Example 2: Nested expressions
IO.puts("\n2. Nested expressions:")
result5 = ~L"(+ (* 2 3) (* 4 5))"
IO.puts("  (+ (* 2 3) (* 4 5)) = #{result5}")

result6 = ~L"(* (+ 1 2) (+ 3 4))"
IO.puts("  (* (+ 1 2) (+ 3 4)) = #{result6}")

# Example 3: Let bindings
IO.puts("\n3. Let bindings:")
result7 = ~L"""
(let [x 10
      y 20]
  (+ x y))
"""
IO.puts("  Let binding result: #{result7}")

result8 = ~L"""
(let [a 5
      b (* a 2)
      c (+ a b)]
  c)
"""
IO.puts("  Nested let binding: #{result8}")

# Example 4: Simple conditionals
IO.puts("\n4. Conditional expressions:")
result9 = ~L|(if (> 5 3) "five is bigger" "three is bigger")|
IO.puts("  Simple if: #{result9}")

result10 = ~L|(if (< 2 1) "impossible" "correct")|
IO.puts("  Another if: #{result10}")

# Example 5: Lambda expressions
IO.puts("\n5. Lambda expressions:")
add_ten = ~L"(lambda [x] (+ x 10))"
IO.puts("  Created add_ten lambda")
IO.puts("  add_ten(5) = #{add_ten.(5)}")

multiply_by_3 = ~L"(lambda [x] (* x 3))"
IO.puts("  multiply_by_3(7) = #{multiply_by_3.(7)}")

# Example 6: List operations  
IO.puts("\n6. List operations:")
my_list = ~L"(list 1 2 3 4 5)"
IO.puts("  Created list: #{inspect(my_list)}")

# Example 7: Comparisons
IO.puts("\n7. Comparison operations:")
IO.puts("  (< 3 5) = #{~L"(< 3 5)"}")
IO.puts("  (> 10 8) = #{~L"(> 10 8)"}")
IO.puts("  (== 4 4) = #{~L"(== 4 4)"}")
IO.puts("  (<= 5 5) = #{~L"(<= 5 5)"}")

# Example 8: Boolean operations
IO.puts("\n8. Boolean operations:")
IO.puts("  (and true false) = #{~L"(and true false)"}")
IO.puts("  (or true false) = #{~L"(or true false)"}")
IO.puts("  (not false) = #{~L"(not false)"}")

# Example 9: String operations
IO.puts("\n9. String operations:")
str_concat = ~L|(str "Hello " "Lisix " "World!")|
IO.puts("  String concatenation: #{str_concat}")

# Example 10: Using variables in expressions
IO.puts("\n10. Variable interpolation:")
number = 42
result_with_var = ~L"(+ ~{number} 8)"
IO.puts("  Adding Elixir variable: #{number} + 8 = #{result_with_var}")

# Example 11: Quote expressions (return S-expression as data)
IO.puts("\n11. Quote expressions:")
quoted_expr = ~L"(+ 1 2 3)"q
IO.puts("  Quoted expression: #{inspect(quoted_expr)}")

# Example 12: Direct Lisix evaluation
IO.puts("\n12. Direct evaluation:")
direct_result = Lisix.eval("(* (+ 2 3) (+ 4 1))")
IO.puts("  Lisix.eval result: #{direct_result}")

# Example 13: Parsing to S-expressions
IO.puts("\n13. Parsing:")
parsed = Lisix.parse("(defn square [x] (* x x))")
IO.puts("  Parsed S-expression: #{inspect(parsed)}")

# Example 14: Complex nested calculation
IO.puts("\n14. Complex calculation:")
complex_calc = ~L"""
(let [base 10
      multiplier 3
      addition 5]
  (+ (* base multiplier) addition))
"""
IO.puts("  Result: #{complex_calc}")

IO.puts("\n🎉 All basic examples completed successfully!")
IO.puts("Lisix is working and can execute Lisp code within Elixir!")