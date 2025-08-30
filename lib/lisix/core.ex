defmodule Lisix.Core do
  @moduledoc """
  Core library functions for Lisix.
  Provides Lisp-style functions that can be used in Lisix code.
  """

  # List operations

  @doc "Get the first element of a list (car)"
  def car([]), do: nil
  def car([head | _tail]), do: head

  @doc "Get the tail of a list (cdr)"
  def cdr([]), do: []
  def cdr([_head | tail]), do: tail

  @doc "Construct a list (cons)"
  def cons(elem, list) when is_list(list), do: [elem | list]
  def cons(elem, nil), do: [elem]

  @doc "Get the first element (alias for car)"
  def first(list), do: car(list)

  @doc "Get the rest of the list (alias for cdr)"
  def rest(list), do: cdr(list)

  @doc "Get the head (alias for car)"
  def head(list), do: car(list)

  @doc "Get the tail (alias for cdr)"
  def tail(list), do: cdr(list)

  @doc "Get the second element"
  def second(list), do: car(cdr(list))

  @doc "Get the third element"
  def third(list), do: car(cdr(cdr(list)))

  @doc "Get the nth element (0-indexed)"
  def nth(list, n) when is_list(list) and is_integer(n) and n >= 0 do
    Enum.at(list, n)
  end

  @doc "Take n elements from a list"
  def take(list, n) when is_list(list) and is_integer(n) do
    Enum.take(list, n)
  end

  @doc "Drop n elements from a list"
  def drop(list, n) when is_list(list) and is_integer(n) do
    Enum.drop(list, n)
  end

  @doc "Get the last element"
  def last([]), do: nil
  def last([elem]), do: elem
  def last([_head | tail]), do: last(tail)

  @doc "Reverse a list"
  def reverse(list) when is_list(list), do: Enum.reverse(list)

  @doc "Append lists"
  def append(list1, list2) when is_list(list1) and is_list(list2) do
    list1 ++ list2
  end

  @doc "Get the length of a list"
  def length(list) when is_list(list), do: Kernel.length(list)

  # Higher-order functions

  @doc "Map a function over a list"
  def map(func, list) when is_function(func) and is_list(list) do
    Enum.map(list, func)
  end

  @doc "Filter a list"
  def filter(pred, list) when is_function(pred) and is_list(list) do
    Enum.filter(list, pred)
  end

  @doc "Reduce/fold a list"
  def reduce(func, acc, list) when is_function(func) and is_list(list) do
    Enum.reduce(list, acc, func)
  end

  @doc "Fold left (alias for reduce)"
  def foldl(func, acc, list), do: reduce(func, acc, list)

  @doc "Fold right"
  def foldr(func, acc, list) when is_function(func) and is_list(list) do
    Enum.reduce(Enum.reverse(list), acc, func)
  end

  @doc "Apply a function to arguments"
  def apply_fn(func, args) when is_function(func) and is_list(args) do
    Kernel.apply(func, args)
  end

  @doc "Compose two functions"
  def compose(f, g) when is_function(f) and is_function(g) do
    fn x -> f.(g.(x)) end
  end

  @doc "Partial application"
  def partial(func, arg) when is_function(func) do
    fn x -> func.(arg, x) end
  end

  # Predicates

  @doc "Check if value is nil"
  def nil?(value), do: is_nil(value)

  @doc "Check if list is empty"
  def empty?([]), do: true
  def empty?(_), do: false

  @doc "Check if value is a list"
  def list?(value), do: is_list(value)

  @doc "Check if value is an atom"
  def atom?(value), do: is_atom(value)

  @doc "Check if value is a number"
  def number?(value), do: is_number(value)

  @doc "Check if value is a string"
  def string?(value), do: is_binary(value)

  @doc "Check if value is a function"
  def function?(value), do: is_function(value)

  @doc "Check if number is even"
  def even?(n) when is_integer(n), do: rem(n, 2) == 0

  @doc "Check if number is odd"
  def odd?(n) when is_integer(n), do: rem(n, 2) != 0

  @doc "Check if number is zero"
  def zero?(n) when is_number(n), do: n == 0

  @doc "Check if number is positive"
  def positive?(n) when is_number(n), do: n > 0

  @doc "Check if number is negative"
  def negative?(n) when is_number(n), do: n < 0

  # Math functions

  @doc "Absolute value"
  def abs(n) when is_number(n), do: Kernel.abs(n)

  @doc "Maximum of two values"
  def max(a, b), do: Kernel.max(a, b)

  @doc "Minimum of two values"
  def min(a, b), do: Kernel.min(a, b)

  @doc "Sum a list of numbers"
  def sum(list) when is_list(list), do: Enum.sum(list)

  @doc "Product of a list of numbers"
  def product(list) when is_list(list) do
    Enum.reduce(list, 1, &*/2)
  end

  @doc "Increment"
  def inc(n) when is_number(n), do: n + 1

  @doc "Decrement"
  def dec(n) when is_number(n), do: n - 1

  @doc "Square a number"
  def square(n) when is_number(n), do: n * n

  @doc "Cube a number"
  def cube(n) when is_number(n), do: n * n * n

  @doc "Power function"
  def pow(base, exp) when is_number(base) and is_number(exp) do
    :math.pow(base, exp)
  end

  @doc "Square root"
  def sqrt(n) when is_number(n) and n >= 0 do
    :math.sqrt(n)
  end

  # String operations

  @doc "Concatenate strings"
  def str_concat(strings) when is_list(strings) do
    Enum.join(strings, "")
  end

  @doc "String length"
  def str_length(str) when is_binary(str) do
    String.length(str)
  end

  @doc "Convert to string"
  def to_string(value), do: Kernel.to_string(value)

  @doc "Convert string to atom"
  def to_atom(str) when is_binary(str), do: String.to_atom(str)

  @doc "Convert to integer"
  def to_integer(str) when is_binary(str), do: String.to_integer(str)
  def to_integer(n) when is_float(n), do: trunc(n)
  def to_integer(n) when is_integer(n), do: n

  @doc "Convert to float"
  def to_float(str) when is_binary(str), do: String.to_float(str)
  def to_float(n) when is_number(n), do: n * 1.0

  # Utility functions

  @doc "Identity function"
  def identity(x), do: x

  @doc "Constantly return a value"
  def constantly(value) do
    fn _args -> value end
  end

  @doc "Print and return value (for debugging)"
  def tap(value, func \\ &IO.inspect/1) do
    func.(value)
    value
  end

  @doc "Range of numbers"
  def range(start, stop) when is_integer(start) and is_integer(stop) do
    Enum.to_list(start..stop)
  end

  @doc "Repeat a value n times"
  def repeat(value, n) when is_integer(n) and n >= 0 do
    List.duplicate(value, n)
  end

  @doc "Zip two lists"
  def zip(list1, list2) when is_list(list1) and is_list(list2) do
    Enum.zip(list1, list2)
  end

  @doc "Unzip a list of tuples"
  def unzip(list) when is_list(list) do
    Enum.unzip(list)
  end

  @doc "Flatten a nested list"
  def flatten(list) when is_list(list) do
    List.flatten(list)
  end

  @doc "Remove duplicates from a list"
  def distinct(list) when is_list(list) do
    Enum.uniq(list)
  end

  @doc "Sort a list"
  def sort(list) when is_list(list) do
    Enum.sort(list)
  end

  @doc "Check if all elements satisfy a predicate"
  def all?(pred, list) when is_function(pred) and is_list(list) do
    Enum.all?(list, pred)
  end

  @doc "Check if any element satisfies a predicate"
  def any?(pred, list) when is_function(pred) and is_list(list) do
    Enum.any?(list, pred)
  end

  @doc "Find first element that satisfies a predicate"
  def find(pred, list) when is_function(pred) and is_list(list) do
    Enum.find(list, pred)
  end

  @doc "Partition a list based on a predicate"
  def partition(pred, list) when is_function(pred) and is_list(list) do
    {true_list, false_list} = Enum.split_with(list, pred)
    [true_list, false_list]
  end

  @doc "Interleave two lists"
  def interleave(list1, list2) when is_list(list1) and is_list(list2) do
    do_interleave(list1, list2, [])
  end

  defp do_interleave([], [], acc), do: Enum.reverse(acc)
  defp do_interleave([h1 | t1], [], acc), do: Enum.reverse([h1 | acc]) ++ t1
  defp do_interleave([], [h2 | t2], acc), do: Enum.reverse([h2 | acc]) ++ t2
  defp do_interleave([h1 | t1], [h2 | t2], acc) do
    do_interleave(t1, t2, [h2, h1 | acc])
  end

  @doc "Thread-first macro equivalent"
  def thread_first(value, functions) when is_list(functions) do
    Enum.reduce(functions, value, fn func, acc ->
      func.(acc)
    end)
  end

  @doc "Thread-last macro equivalent"
  def thread_last(value, functions) when is_list(functions) do
    Enum.reduce(functions, value, fn func, acc ->
      if is_function(func, 1) do
        func.(acc)
      else
        apply(func, [acc])
      end
    end)
  end
end