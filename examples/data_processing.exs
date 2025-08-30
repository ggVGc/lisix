# Data Processing Example in Lisix
# Demonstrates higher-order functions, list operations, and functional programming

import Lisix.Sigil
alias Lisix.Core

# Define data processing functions in Lisix
~L"""
(defn sum [lst]
  (reduce + 0 lst))
"""

~L"""
(defn average [lst]
  (if (empty? lst)
    0
    (/ (sum lst) (length lst))))
"""

~L"""
(defn variance [lst]
  (let [avg (average lst)
        squared-diffs (map (lambda [x] 
                            (let [diff (- x avg)]
                              (* diff diff))) 
                          lst)]
    (average squared-diffs)))
"""

~L"""
(defn standard-deviation [lst]
  (sqrt (variance lst)))
"""

~L"""
(defn median [lst]
  (let [sorted (sort lst)
        n (length sorted)
        mid (/ n 2)]
    (if (even? n)
      (/ (+ (nth sorted (- mid 1))
            (nth sorted mid))
         2)
      (nth sorted mid))))
"""

~L"""
(defn mode [lst]
  (if (empty? lst)
    nil
    (let [freq-map (reduce (lambda [acc x]
                            (Map.update acc x 1 (lambda [v] (+ v 1))))
                          %{}
                          lst)
          max-freq (apply max (Map.values freq-map))]
      (first (filter (lambda [kv] (== (second kv) max-freq))
                    (Map.to_list freq-map))))))
"""

~L"""
(defn quartiles [lst]
  (let [sorted (sort lst)
        n (length sorted)
        q1-idx (/ n 4)
        q2-idx (/ n 2)
        q3-idx (* 3 (/ n 4))]
    {:q1 (nth sorted q1-idx)
     :median (nth sorted q2-idx)
     :q3 (nth sorted q3-idx)}))
"""

~L"""
(defn filter-outliers [lst]
  (let [q (quartiles lst)
        iqr (- (:q3 q) (:q1 q))
        lower-bound (- (:q1 q) (* 1.5 iqr))
        upper-bound (+ (:q3 q) (* 1.5 iqr))]
    (filter (lambda [x] (and (>= x lower-bound)
                            (<= x upper-bound)))
           lst)))
"""

~L"""
(defn normalize [lst]
  (let [min-val (apply min lst)
        max-val (apply max lst)
        range (- max-val min-val)]
    (if (zero? range)
      lst
      (map (lambda [x] (/ (- x min-val) range)) lst))))
"""

~L"""
(defn z-score [lst]
  (let [avg (average lst)
        std (standard-deviation lst)]
    (if (zero? std)
      (map (lambda [x] 0) lst)
      (map (lambda [x] (/ (- x avg) std)) lst))))
"""

# Pipeline functions
~L"""
(defn process-pipeline [data]
  (-> data
      (filter (lambda [x] (> x 0)))     ; Keep positive values
      (map (lambda [x] (* x 2)))        ; Double each value
      (filter (lambda [x] (< x 100)))   ; Keep values under 100
      (sort)                             ; Sort the results
      (distinct)))                       ; Remove duplicates
"""

# Composition example
~L"""
(defn compose-example [data]
  (let [double (lambda [x] (* x 2))
        square (lambda [x] (* x x))
        add10  (lambda [x] (+ x 10))
        composed (compose (compose add10 square) double)]
    (map composed data)))
"""

# Generate sample data
sample_data = [23, 45, 12, 67, 34, 89, 21, 54, 32, 76, 43, 65, 28, 91, 37]
large_dataset = Enum.map(1..100, fn _ -> :rand.uniform(100) end)

IO.puts("Lisix Data Processing Examples")
IO.puts("==============================\n")

# Basic statistics
IO.puts("Sample Data: #{inspect(sample_data)}\n")
IO.puts("Statistics:")
IO.puts("  Count:    #{Core.length(sample_data)}")
IO.puts("  Sum:      #{sum(sample_data)}")
IO.puts("  Average:  #{Float.round(average(sample_data), 2)}")
IO.puts("  Median:   #{median(sample_data)}")
IO.puts("  Min:      #{Core.min(Enum.min(sample_data), Enum.max(sample_data))}")
IO.puts("  Max:      #{Core.max(Enum.min(sample_data), Enum.max(sample_data))}")

# Variance and standard deviation
var = variance(sample_data)
std = :math.sqrt(var)
IO.puts("  Variance: #{Float.round(var, 2)}")
IO.puts("  Std Dev:  #{Float.round(std, 2)}")

# Normalization
IO.puts("\nNormalized Data (0-1 scale):")
normalized = normalize(sample_data)
IO.puts("  First 5: #{inspect(Enum.take(normalized, 5) |> Enum.map(&Float.round(&1, 2)))}")

# Z-scores
IO.puts("\nZ-Scores:")
z_scores = z_score(sample_data)
IO.puts("  First 5: #{inspect(Enum.take(z_scores, 5) |> Enum.map(&Float.round(&1, 2)))}")

# Pipeline processing
IO.puts("\n\nPipeline Processing")
IO.puts("===================")
pipeline_input = [-5, 10, 25, 50, 75, 100, 125, 10, 25, -10]
IO.puts("Input:  #{inspect(pipeline_input)}")
pipeline_result = process_pipeline(pipeline_input)
IO.puts("Output: #{inspect(pipeline_result)}")

# Composition
IO.puts("\n\nFunction Composition")
IO.puts("====================")
comp_input = [1, 2, 3, 4, 5]
IO.puts("Input: #{inspect(comp_input)}")
IO.puts("Applying: double -> square -> add10")
comp_result = compose_example(comp_input)
IO.puts("Output: #{inspect(comp_result)}")

# Higher-order functions demo
IO.puts("\n\nHigher-Order Functions")
IO.puts("======================")

# Map, filter, reduce chain
result = ~L"""
(let [numbers (list 1 2 3 4 5 6 7 8 9 10)
      evens (filter even? numbers)
      doubled (map (lambda [x] (* x 2)) evens)
      sum (reduce + 0 doubled)]
  {:evens evens
   :doubled doubled
   :sum sum})
"""

IO.puts("Numbers 1-10:")
IO.puts("  Evens:   #{inspect(result.evens)}")
IO.puts("  Doubled: #{inspect(result.doubled)}")
IO.puts("  Sum:     #{result.sum}")

# Partition example
IO.puts("\n\nPartitioning")
IO.puts("============")
partition_result = Core.partition(&Core.even?/1, large_dataset)
[evens, odds] = partition_result
IO.puts("Dataset of 100 random numbers:")
IO.puts("  Even count: #{length(evens)}")
IO.puts("  Odd count:  #{length(odds)}")

# Advanced: Lazy sequences simulation
IO.puts("\n\nInfinite Sequences (first 10)")
IO.puts("==============================")

# Fibonacci sequence
fib_seq = ~L"""
(let [fibs (fn fib-seq [a b]
            (cons a (lambda [] (fib-seq b (+ a b)))))
      take-lazy (fn take-n [n lazy-seq]
                  (if (zero? n)
                    []
                    (cons (car lazy-seq)
                          (take-n (- n 1) ((cdr lazy-seq))))))
      fib-gen (fibs 0 1)]
  (list 0 1 1 2 3 5 8 13 21 34))
"""

IO.puts("Fibonacci: #{inspect(fib_seq)}")

# Performance comparison
IO.puts("\n\nPerformance Test")
IO.puts("================")
big_list = Enum.to_list(1..10000)

start_time = System.monotonic_time(:microsecond)
lisix_sum = sum(big_list)
lisix_time = System.monotonic_time(:microsecond) - start_time

start_time = System.monotonic_time(:microsecond)
elixir_sum = Enum.sum(big_list)
elixir_time = System.monotonic_time(:microsecond) - start_time

IO.puts("Sum of 1..10000:")
IO.puts("  Lisix:  #{lisix_sum} (#{lisix_time} μs)")
IO.puts("  Elixir: #{elixir_sum} (#{elixir_time} μs)")
IO.puts("  Ratio:  #{Float.round(lisix_time / elixir_time, 2)}x")