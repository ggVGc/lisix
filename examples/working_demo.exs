# Working Lisix demonstration with practical examples

defmodule LisixDemo do
  import Lisix.Sigil
  
  def process_numbers(numbers) do
    IO.puts("Processing list: #{inspect(numbers)}")
    
    # Sum all numbers using Enum.sum
    sum = Enum.sum(numbers)
    IO.puts("  Sum: #{sum}")
    
    # Count numbers
    count = length(numbers)
    IO.puts("  Count: #{count}")
    
    # Average
    avg = if count > 0, do: sum / count, else: 0
    IO.puts("  Average: #{Float.round(avg, 2)}")
    
    # Double each number
    doubled = Enum.map(numbers, fn n -> 
      ~L"(* 2 ~{n})" 
    end)
    IO.puts("  Doubled: #{inspect(doubled)}")
    
    # Filter even numbers using Lisix
    evens = Enum.filter(numbers, fn n ->
      ~L"(== (rem ~{n} 2) 0)"
    end)
    IO.puts("  Even numbers: #{inspect(evens)}")
    
    # Square each number using lambda
    square_lambda = ~L"(lambda [x] (* x x))"
    squares = Enum.map(numbers, square_lambda)
    IO.puts("  Squares: #{inspect(squares)}")
    
    IO.puts("")
  end
  
  def string_processing() do
    IO.puts("String processing with Lisix:")
    
    # String operations
    greeting = ~L|(str "Hello" " " "Lisix" " " "World!")|
    IO.puts("  Concatenated: #{greeting}")
    
    # String with variables
    name = "Alice"
    age = 30
    message = ~L|(str "Hello " ~{name} ", you are " ~{age} " years old")|
    IO.puts("  Personalized: #{message}")
    
    IO.puts("")
  end
  
  def conditional_logic() do
    IO.puts("Conditional logic examples:")
    
    # Test different numbers
    test_numbers = [-5, 0, 3, -2, 10]
    
    Enum.each(test_numbers, fn n ->
      # Sign determination
      sign = ~L"""
      (if (< ~{n} 0)
        "negative"
        (if (> ~{n} 0)
          "positive" 
          "zero"))
      """
      
      # Even/odd check
      parity = ~L|(if (== (rem ~{n} 2) 0) "even" "odd")|
      
      IO.puts("  #{n} is #{sign} and #{parity}")
    end)
    
    IO.puts("")
  end
  
  def nested_calculations() do
    IO.puts("Complex nested calculations:")
    
    # Financial calculation
    principal = 1000
    rate = 0.05
    time = 3
    
    # Compound interest: A = P(1 + r)^t
    # Using let binding for intermediate values
    amount = ~L"""
    (let [base (+ 1 ~{rate})
          power (* base (* base base))
          result (* ~{principal} power)]
      result)
    """
    
    IO.puts("  Investment calculation:")
    IO.puts("    Principal: $#{principal}")
    IO.puts("    Rate: #{rate * 100}%") 
    IO.puts("    Time: #{time} years")
    IO.puts("    Amount: $#{Float.round(amount, 2)}")
    
    # Area and volume calculations
    radius = 5
    
    area = ~L"(* 3.14159 (* ~{radius} ~{radius}))"
    volume = ~L"(* ~{area} ~{radius})"
    
    IO.puts("\n  Circle calculations (radius = #{radius}):")
    IO.puts("    Area: #{Float.round(area, 2)}")
    IO.puts("    Volume (cylinder height = radius): #{Float.round(volume, 2)}")
    
    IO.puts("")
  end
  
  def lambda_functions() do
    IO.puts("Lambda function examples:")
    
    # Create various lambda functions
    add_5 = ~L"(lambda [x] (+ x 5))"
    multiply_by_3 = ~L"(lambda [x] (* x 3))"
    is_positive = ~L"(lambda [x] (> x 0))"
    
    # Test data
    numbers = [1, -2, 8, 0, -5, 12]
    
    IO.puts("  Test numbers: #{inspect(numbers)}")
    
    # Apply add_5 to each
    added = Enum.map(numbers, add_5)
    IO.puts("  Add 5: #{inspect(added)}")
    
    # Apply multiply_by_3 to each
    multiplied = Enum.map(numbers, multiply_by_3)
    IO.puts("  Multiply by 3: #{inspect(multiplied)}")
    
    # Filter positive numbers
    positives = Enum.filter(numbers, is_positive)
    IO.puts("  Positive numbers: #{inspect(positives)}")
    
    # Composition example
    IO.puts("\n  Function composition:")
    composed_result = numbers
                     |> Enum.map(add_5)
                     |> Enum.map(multiply_by_3)
                     |> Enum.filter(is_positive)
    
    IO.puts("  (add 5) -> (multiply by 3) -> (filter positive): #{inspect(composed_result)}")
    
    IO.puts("")
  end
end

# Run all demonstrations
IO.puts("🚀 Comprehensive Lisix Demonstration")
IO.puts("=====================================\n")

# Demo 1: Number processing
LisixDemo.process_numbers([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
LisixDemo.process_numbers([15, 22, 8, 31, 7, 44])

# Demo 2: String processing
LisixDemo.string_processing()

# Demo 3: Conditional logic
LisixDemo.conditional_logic()

# Demo 4: Complex calculations
LisixDemo.nested_calculations()

# Demo 5: Lambda functions
LisixDemo.lambda_functions()

# Final demonstration: Real-world scenario
IO.puts("Real-world scenario: Order processing")
IO.puts("=====================================")

import Lisix.Sigil

orders = [
  %{item: "laptop", price: 999, quantity: 1},
  %{item: "mouse", price: 25, quantity: 2}, 
  %{item: "keyboard", price: 75, quantity: 1},
  %{item: "monitor", price: 300, quantity: 2}
]

total_cost = Enum.reduce(orders, 0, fn order, acc ->
  price = order.price
  quantity = order.quantity
  item_total = ~L"(* ~{price} ~{quantity})"
  acc + item_total
end)

discount_rate = 0.1
discount_amount = ~L"(* ~{total_cost} ~{discount_rate})"
final_cost = ~L"(- ~{total_cost} ~{discount_amount})"

IO.puts("Order Summary:")
Enum.each(orders, fn order ->
  price = order.price
  quantity = order.quantity
  item_cost = ~L"(* ~{price} ~{quantity})"
  IO.puts("  #{order.item}: #{quantity} × $#{price} = $#{item_cost}")
end)

IO.puts("\nSubtotal: $#{total_cost}")
IO.puts("Discount (10%): -$#{Float.round(discount_amount, 2)}")
IO.puts("Total: $#{Float.round(final_cost, 2)}")

IO.puts("\n🎯 All demonstrations completed successfully!")
IO.puts("Lisix proves to be a powerful Lisp dialect running on the BEAM!")