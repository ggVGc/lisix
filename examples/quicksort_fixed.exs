# Working Quicksort implementation using Lisix

defmodule LisixSort do
  import Lisix.Sigil
  
  # Quicksort implementation using Elixir pattern matching with Lisix operations
  def quicksort([]), do: []
  def quicksort([pivot | rest]) do
    # Use Lisix for comparisons and list operations
    less_than_pivot = Enum.filter(rest, fn x -> 
      ~L"(< ~{x} ~{pivot})" 
    end)
    
    greater_equal_pivot = Enum.filter(rest, fn x -> 
      ~L"(>= ~{x} ~{pivot})" 
    end)
    
    # Recursively sort and combine
    quicksort(less_than_pivot) ++ [pivot] ++ quicksort(greater_equal_pivot)
  end
  
  # Bubble sort for comparison
  def bubble_sort(list) when length(list) <= 1, do: list
  def bubble_sort(list) do
    {sorted, swapped} = bubble_pass(list, [])
    if swapped do
      bubble_sort(sorted)
    else
      sorted
    end
  end
  
  defp bubble_pass([], acc), do: {Enum.reverse(acc), false}
  defp bubble_pass([x], acc), do: {Enum.reverse([x | acc]), false}
  defp bubble_pass([a, b | rest], acc) do
    should_swap = ~L"(> ~{a} ~{b})"
    if should_swap do
      bubble_pass([a | rest], [b | acc])
      |> then(fn {list, _} -> {list, true} end)
    else
      bubble_pass([b | rest], [a | acc])
    end
  end
  
  # Merge sort
  def merge_sort([]), do: []
  def merge_sort([x]), do: [x]
  def merge_sort(list) do
    mid = div(length(list), 2)
    {left, right} = Enum.split(list, mid)
    
    merge(merge_sort(left), merge_sort(right))
  end
  
  defp merge([], right), do: right
  defp merge(left, []), do: left
  defp merge([h1 | t1], [h2 | t2]) do
    is_smaller = ~L"(<= ~{h1} ~{h2})"
    if is_smaller do
      [h1 | merge(t1, [h2 | t2])]
    else
      [h2 | merge([h1 | t1], t2)]
    end
  end
  
  # Utility functions using Lisix
  def is_sorted?([]), do: true
  def is_sorted?([_]), do: true
  def is_sorted?([a, b | rest]) do
    ordered = ~L"(<= ~{a} ~{b})"
    if ordered do
      is_sorted?([b | rest])
    else
      false
    end
  end
  
  def sum_list(list) do
    Enum.reduce(list, 0, fn x, acc ->
      ~L"(+ ~{acc} ~{x})"
    end)
  end
  
  def find_min([]), do: nil
  def find_min([h | t]) do
    Enum.reduce(t, h, fn x, min ->
      is_smaller = ~L"(< ~{x} ~{min})"
      if is_smaller, do: x, else: min
    end)
  end
  
  def find_max([]), do: nil
  def find_max([h | t]) do
    Enum.reduce(t, h, fn x, max ->
      is_larger = ~L"(> ~{x} ~{max})"
      if is_larger, do: x, else: max
    end)
  end
  
  # Generate test data
  def generate_random_list(size, max_value \\ 100) do
    1..size
    |> Enum.map(fn _ -> :rand.uniform(max_value) end)
  end
  
  def generate_sorted_list(size) do
    1..size |> Enum.to_list()
  end
  
  def generate_reverse_sorted_list(size) do
    size..1 |> Enum.to_list()
  end
end

# Demonstration
IO.puts("Lisix Sorting Algorithms Demo")
IO.puts("=============================\n")

# Test different sorting algorithms
test_lists = [
  {[5, 2, 8, 1, 9, 3, 7], "Random small list"},
  {[1, 2, 3, 4, 5], "Already sorted"},
  {[9, 7, 5, 3, 1], "Reverse sorted"},
  {[3, 1, 4, 1, 5, 9, 2, 6, 5, 3], "With duplicates"},
  {[], "Empty list"},
  {[42], "Single element"},
  {LisixSort.generate_random_list(15), "Random medium list"}
]

test_lists
|> Enum.with_index(1)
|> Enum.each(fn {{list, description}, index} ->
  IO.puts("#{index}. #{description}")
  IO.puts("   Original: #{inspect(list)}")
  
  if length(list) > 0 do
    # Test all sorting algorithms
    quick_sorted = LisixSort.quicksort(list)
    bubble_sorted = LisixSort.bubble_sort(list)
    merge_sorted = LisixSort.merge_sort(list)
    
    IO.puts("   Quicksort: #{inspect(quick_sorted)}")
    IO.puts("   Bubblesort: #{inspect(bubble_sorted)}")
    IO.puts("   Mergesort: #{inspect(merge_sorted)}")
    
    # Verify they're all correctly sorted
    all_correct = [quick_sorted, bubble_sorted, merge_sorted]
                  |> Enum.all?(&LisixSort.is_sorted?/1)
    
    IO.puts("   All correctly sorted: #{all_correct}")
    
    # Show some statistics using Lisix
    sum = LisixSort.sum_list(list)
    min_val = LisixSort.find_min(list)
    max_val = LisixSort.find_max(list)
    
    IO.puts("   Sum: #{sum}, Min: #{min_val}, Max: #{max_val}")
  else
    quick_sorted = LisixSort.quicksort(list)
    IO.puts("   Quicksort: #{inspect(quick_sorted)}")
    IO.puts("   Correctly sorted: #{LisixSort.is_sorted?(quick_sorted)}")
  end
  
  IO.puts("")
end)

# Performance comparison
IO.puts("Performance Comparison")
IO.puts("======================")

performance_sizes = [10, 50, 100]

performance_sizes
|> Enum.each(fn size ->
  IO.puts("Testing with #{size} elements:")
  
  test_data = LisixSort.generate_random_list(size)
  
  # Time quicksort
  start_time = System.monotonic_time(:microsecond)
  _quick_result = LisixSort.quicksort(test_data)
  quick_time = System.monotonic_time(:microsecond) - start_time
  
  # Time bubble sort (only for smaller lists)
  bubble_time = if size <= 50 do
    start_time = System.monotonic_time(:microsecond)
    _bubble_result = LisixSort.bubble_sort(test_data)
    System.monotonic_time(:microsecond) - start_time
  else
    "skipped (too slow)"
  end
  
  # Time merge sort
  start_time = System.monotonic_time(:microsecond)
  _merge_result = LisixSort.merge_sort(test_data)
  merge_time = System.monotonic_time(:microsecond) - start_time
  
  # Time Elixir's built-in sort for comparison
  start_time = System.monotonic_time(:microsecond)
  _elixir_result = Enum.sort(test_data)
  elixir_time = System.monotonic_time(:microsecond) - start_time
  
  IO.puts("  Quicksort: #{quick_time}μs")
  IO.puts("  Bubblesort: #{bubble_time}")
  IO.puts("  Mergesort: #{merge_time}μs")
  IO.puts("  Elixir Enum.sort: #{elixir_time}μs")
  IO.puts("")
end)

# Special test cases
IO.puts("Special Test Cases")
IO.puts("==================")

special_cases = [
  {[1, 1, 1, 1, 1], "All same elements"},
  {[1, 2], "Two elements"},
  {[2, 1], "Two elements reverse"},
  {Enum.to_list(1..20), "Long sorted sequence"},
  {Enum.to_list(20..1), "Long reverse sequence"}
]

special_cases
|> Enum.each(fn {list, description} ->
  IO.puts("#{description}:")
  
  sorted = LisixSort.quicksort(list)
  is_correct = LisixSort.is_sorted?(sorted)
  
  IO.puts("  Input: #{inspect(list |> Enum.take(10))}#{if length(list) > 10, do: "...", else: ""}")
  IO.puts("  Sorted: #{inspect(sorted |> Enum.take(10))}#{if length(sorted) > 10, do: "...", else: ""}")
  IO.puts("  Correct: #{is_correct}")
  IO.puts("")
end)

IO.puts("🎯 All sorting demonstrations completed successfully!")
IO.puts("Lisix enables elegant implementation of classic algorithms!")