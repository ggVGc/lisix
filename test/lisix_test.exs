defmodule LisixTest do
  use ExUnit.Case
  alias Lisix.{Tokenizer, Parser, Transformer}
  import Lisix.Sigil

  describe "Tokenizer" do
    test "tokenizes basic expressions" do
      assert Tokenizer.tokenize("(+ 1 2)") == [
        {:lparen}, {:symbol, :+}, {:number, 1}, {:number, 2}, {:rparen}
      ]
    end

    test "tokenizes nested expressions" do
      assert Tokenizer.tokenize("(* (+ 1 2) 3)") == [
        {:lparen}, {:symbol, :*}, 
        {:lparen}, {:symbol, :+}, {:number, 1}, {:number, 2}, {:rparen},
        {:number, 3}, {:rparen}
      ]
    end

    test "tokenizes strings" do
      assert Tokenizer.tokenize("(print \"hello world\")") == [
        {:lparen}, {:symbol, :print}, {:string, "hello world"}, {:rparen}
      ]
    end

    test "tokenizes keywords" do
      assert Tokenizer.tokenize("(:name :age)") == [
        {:lparen}, {:keyword, :name}, {:keyword, :age}, {:rparen}
      ]
    end

    test "tokenizes vectors" do
      assert Tokenizer.tokenize("[1 2 3]") == [
        {:lbracket}, {:number, 1}, {:number, 2}, {:number, 3}, {:rbracket}
      ]
    end

    test "handles comments" do
      assert Tokenizer.tokenize("(+ 1 ; comment\n 2)") == [
        {:lparen}, {:symbol, :+}, {:number, 1}, {:number, 2}, {:rparen}
      ]
    end

    test "tokenizes special literals" do
      assert Tokenizer.tokenize("(if true false nil)") == [
        {:lparen}, {:symbol, :if}, {:boolean, true}, {:boolean, false}, {:nil}, {:rparen}
      ]
    end

    test "tokenizes quote forms" do
      assert Tokenizer.tokenize("'(a b)") == [
        {:quote}, {:lparen}, {:symbol, :a}, {:symbol, :b}, {:rparen}
      ]
    end

    test "tokenizes floating point numbers" do
      assert Tokenizer.tokenize("(+ 3.14 -2.5)") == [
        {:lparen}, {:symbol, :+}, {:number, 3.14}, {:number, -2.5}, {:rparen}
      ]
    end
  end

  describe "Parser" do
    test "parses simple expressions" do
      tokens = [{:lparen}, {:symbol, :+}, {:number, 1}, {:number, 2}, {:rparen}]
      assert Parser.parse(tokens) == [:+, 1, 2]
    end

    test "parses nested expressions" do
      result = Parser.parse_string("(* (+ 1 2) 3)")
      assert result == [:*, [:+, 1, 2], 3]
    end

    test "parses let bindings" do
      result = Parser.parse_string("(let [x 10 y 20] (+ x y))")
      assert result == [:let, {:vector, [:x, 10, :y, 20]}, [:+, :x, :y]]
    end

    test "parses function definitions" do
      result = Parser.parse_string("(defn square [x] (* x x))")
      assert result == [:defn, :square, {:vector, [:x]}, [:*, :x, :x]]
    end

    test "parses quoted expressions" do
      result = Parser.parse_string("'(a b c)")
      assert result == {:quote, [:a, :b, :c]}
    end

    test "parses keywords in maps" do
      result = Parser.parse_string("{:name \"John\" :age 30}")
      assert result == [:":", :name, "John", :":", :age, 30]
    end

    test "parses empty list" do
      result = Parser.parse_string("()")
      assert result == []
    end

    test "parses multiple expressions" do
      result = Parser.parse_string("(+ 1 2) (* 3 4)")
      assert result == [[:+, 1, 2], [:*, 3, 4]]
    end
  end

  describe "Transformer" do
    test "transforms arithmetic" do
      sexpr = [:+, 1, 2, 3]
      ast = Transformer.transform(sexpr)
      assert Macro.to_string(ast) == "1 + 2 + 3"
    end

    test "transforms nested arithmetic" do
      sexpr = [:*, [:+, 1, 2], 3]
      ast = Transformer.transform(sexpr)
      assert Macro.to_string(ast) == "(1 + 2) * 3"
    end

    test "transforms if expression" do
      sexpr = [:if, [:>, :x, 0], "positive", "non-positive"]
      ast = Transformer.transform(sexpr)
      code = Macro.to_string(ast)
      assert code =~ "if"
      assert code =~ "positive"
    end

    test "transforms let bindings" do
      sexpr = [:let, {:vector, [:x, 10, :y, 20]}, [:+, :x, :y]]
      ast = Transformer.transform(sexpr)
      {result, _} = Code.eval_quoted(ast)
      assert result == 30
    end

    test "transforms lambda" do
      sexpr = [:lambda, [:x], [:*, :x, 2]]
      ast = Transformer.transform(sexpr)
      {func, _} = Code.eval_quoted(ast)
      assert is_function(func)
      assert func.(5) == 10
    end

    test "transforms function calls" do
      sexpr = [:print, "hello"]
      ast = Transformer.transform(sexpr)
      assert Macro.to_string(ast) == "print(\"hello\")"
    end

    test "transforms list operations" do
      sexpr = [:car, [:list, 1, 2, 3]]
      ast = Transformer.transform(sexpr)
      {result, _} = Code.eval_quoted(ast)
      assert result == 1
    end

    test "transforms comparison operators" do
      sexpr = [:<, 1, 2]
      ast = Transformer.transform(sexpr)
      {result, _} = Code.eval_quoted(ast)
      assert result == true
    end

    test "transforms boolean operators" do
      sexpr = [:and, true, false]
      ast = Transformer.transform(sexpr)
      {result, _} = Code.eval_quoted(ast)
      assert result == false
    end
  end

  describe "Sigil integration" do
    test "evaluates simple expressions" do
      result = ~L"(+ 1 2 3)"
      assert result == 6
    end

    test "defines and calls functions" do
      ~L"(defn double [x] (* x 2))"
      assert double(5) == 10
    end

    test "handles let bindings" do
      result = ~L"(let [x 10 y 20] (+ x y))"
      assert result == 30
    end

    test "creates lambdas" do
      add5 = ~L"(lambda [x] (+ x 5))"
      assert add5.(10) == 15
    end

    test "quote mode returns S-expression" do
      sexpr = ~L"(+ 1 2)"q
      assert sexpr == [:+, 1, 2]
    end
  end

  describe "Core functions via Lisix" do
    test "factorial function" do
      ~L"""
      (defn factorial [n]
        (if (<= n 1)
          1
          (* n (factorial (- n 1)))))
      """
      
      assert factorial(0) == 1
      assert factorial(1) == 1
      assert factorial(5) == 120
    end

    test "fibonacci function" do
      ~L"""
      (defn fib [n]
        (cond
          [(== n 0) 0]
          [(== n 1) 1]
          [true (+ (fib (- n 1)) (fib (- n 2)))]))
      """
      
      assert fib(0) == 0
      assert fib(1) == 1
      assert fib(5) == 5
      assert fib(10) == 55
    end

    test "map function" do
      result = ~L"(list 1 2 3)"
               |> Enum.map(fn x -> x * 2 end)
      assert result == [2, 4, 6]
    end

    test "nested let bindings" do
      result = ~L"""
      (let [x 10
            y (* x 2)
            z (+ x y)]
        (* z 3))
      """
      assert result == 90
    end

    test "cond expression" do
      check_sign = fn n ->
        ~L"""
        (cond
          [(< ~{n} 0) "negative"]
          [(> ~{n} 0) "positive"]
          [true "zero"])
        """
      end
      
      assert check_sign.(-5) == "negative"
      assert check_sign.(5) == "positive"
      assert check_sign.(0) == "zero"
    end
  end

  describe "Full Lisix evaluation" do
    test "eval function works" do
      assert Lisix.eval("(+ 1 2 3)") == 6
    end

    test "parse function returns S-expression" do
      assert Lisix.parse("(+ 1 2)") == [:+, 1, 2]
    end

    test "compile function returns Elixir code" do
      code = Lisix.compile("(+ 1 2)")
      assert code == "1 + 2"
    end
  end
end
