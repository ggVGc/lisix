# Quicksort implementation in Lisix

# Load the Lisix modules
Code.require_file("../lib/lisix.ex", __DIR__)
Code.require_file("../lib/lisix/tokenizer.ex", __DIR__)
Code.require_file("../lib/lisix/parser.ex", __DIR__)
Code.require_file("../lib/lisix/transformer.ex", __DIR__)
Code.require_file("../lib/lisix/sigil.ex", __DIR__)
Code.require_file("../lib/lisix/core.ex", __DIR__)

import Lisix.Sigil
alias Lisix.Core

# Define quicksort function using Lisix
~L"""
(defn quicksort [lst]
  (if (empty? lst)
    []
    (let [pivot (car lst)
          rest  (cdr lst)
          less  (filter (lambda [x] (< x pivot)) rest)
          greater (filter (lambda [x] (>= x pivot)) rest)]
      (++ (quicksort less)
          (cons pivot (quicksort greater))))))
"""

# Define a helper to generate random lists
~L"""
(defn random-list [n max]
  (if (zero? n)
    []
    (cons (:rand.uniform max) (random-list (dec n) max))))
"""

# Test the implementation
IO.puts("Quicksort Example in Lisix")
IO.puts("==========================\n")

# Example 1: Simple list
simple = [5, 2, 8, 1, 9, 3, 7]
IO.puts("Original: #{inspect(simple)}")
IO.puts("Sorted:   #{inspect(quicksort(simple))}\n")

# Example 2: Already sorted
sorted = [1, 2, 3, 4, 5]
IO.puts("Original: #{inspect(sorted)}")
IO.puts("Sorted:   #{inspect(quicksort(sorted))}\n")

# Example 3: Reverse sorted
reverse = [9, 7, 5, 3, 1]
IO.puts("Original: #{inspect(reverse)}")
IO.puts("Sorted:   #{inspect(quicksort(reverse))}\n")

# Example 4: With duplicates
duplicates = [3, 1, 4, 1, 5, 9, 2, 6, 5, 3]
IO.puts("Original: #{inspect(duplicates)}")
IO.puts("Sorted:   #{inspect(quicksort(duplicates))}\n")

# Example 5: Empty list
empty = []
IO.puts("Original: #{inspect(empty)}")
IO.puts("Sorted:   #{inspect(quicksort(empty))}\n")

# Example 6: Single element
single = [42]
IO.puts("Original: #{inspect(single)}")
IO.puts("Sorted:   #{inspect(quicksort(single))}\n")

# Performance test
IO.puts("Performance Test")
IO.puts("----------------")
large_list = Enum.shuffle(1..100)
IO.puts("Sorting 100 elements...")
start_time = System.monotonic_time(:microsecond)
result = quicksort(large_list)
end_time = System.monotonic_time(:microsecond)
time_taken = (end_time - start_time) / 1000.0

IO.puts("Time taken: #{time_taken} ms")
IO.puts("First 10 elements: #{inspect(Enum.take(result, 10))}")
IO.puts("Last 10 elements:  #{inspect(Enum.take(result, -10))}")
IO.puts("Correctly sorted: #{result == Enum.sort(large_list)}")